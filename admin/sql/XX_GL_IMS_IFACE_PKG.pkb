CREATE OR REPLACE PACKAGE BODY XX_GL_IMS_IFACE_PKG
AS
  -- +==================================================================================================|
  -- |  Office Depot                                                                              		|
  -- +==================================================================================================|
  -- |  Name:  XX_GL_IMS_IFACE_PKG                                                       		  		|
  -- |                                                                                            		|
  -- |  Description	:  This package body is load IMS Inventory Journals file into EBS Staging,			|
  -- |				   Validate and load into NA_STG Table.                                       		|
  -- |  RICE ID   	:  I3131-GL Inventory Journals IMS to EBS                 					  		|
  -- |  Description	:  load IMS Inventory journals file into EBS Staging,Validate 				  		|
  -- |					and load into NA_STG Table.                                               		|
  -- |  Change Record:                                                                            		|
  -- +==================================================================================================|
  -- | Version     Date(DD/MM/YYYY)    Author               Remarks                                     |
  -- | =========   ================  =============       ===============================================|
  -- | 1.0         01/02/2021   	 Amit Kumar			 I3131-GL Inventory Journals IMS to EBS		  	|
  -- | 1.1         07/04/2021   	 Amit Kumar			 Split Debit and Credit Lines in Staging	  	|
  -- | 1.2		   24/05/2021		 Amit Kumar			 Added new variable ln_je_iface_exists to check |
  -- |													if record already exist in interface table for 	|
  -- |													transaction date in the new file loaded in stg.	|
  -- +==================================================================================================+
  gc_package_name      CONSTANT all_objects.object_name%TYPE := 'XX_GL_IMS_IFACE_PKG';
  gc_max_log_size      CONSTANT NUMBER                       := 2000;
  gc_max_err_buf_size  CONSTANT NUMBER                       := 250;

  gn_org_id                     NUMBER                       := fnd_profile.VALUE ('ORG_ID');
  gn_set_of_bks_id              NUMBER                       := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
  gn_chart_of_accounts_id 		NUMBER;


  --=================================================================
  -- Declaring Global variables
  --=================================================================

  gn_request_id               	NUMBER						:=fnd_global.conc_request_id;
  gn_error_count				NUMBER :=0;
  gc_error_status_flag  		VARCHAR2(1);
  gc_debug						VARCHAR2(1):='N';
  gc_errbuf                   	VARCHAR2(2000) :=NULL;
  gn_retcode                  	NUMBER         :=0;
  gc_error_msg 					VARCHAR2(4000);
  gn_user_id             		NUMBER                            := fnd_global.user_id;
  gn_login_id            		NUMBER                            := FND_GLOBAL.LOGIN_ID;
  gc_journal_source_name		VARCHAR2(100) ;


TYPE gt_input_parameters
IS
  TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(255);

  gt_rec_counter NUMBER:=0;
  lt_translation_info xx_fin_translatevalues%ROWTYPE;

  /*********************************************************************
  * Procedure used to log based on gc_debug value or if p_force is TRUE.
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
  * Procedure send_email is used to send email using smtp mail utility
  *	by calling xx_pa_pb_mail package.
 ******************************************************************** */
PROCEDURE send_email (
p_subject		IN VARCHAR2,
p_msg          	IN VARCHAR2,
p_recipients 	IN VARCHAR2,
p_recipients_cc	IN VARCHAR2,
p_file_data    BLOB,
p_file_name		IN VARCHAR2
)
IS
  l_conn 				 utl_smtp.connection;
  l_recipients			 VARCHAR2(1000);
  l_cc_recipients		 VARCHAR2(1000);
 BEGIN


	l_recipients := p_recipients;
	l_cc_recipients := p_recipients_cc;

	l_conn := xx_pa_pb_mail.begin_mail( sender 		=> 'no-reply@officedepot.com',
										recipients 	=> l_recipients,
										cc_recipients=> l_cc_recipients,
										subject 	=> p_subject,
										mime_type 	=> xx_pa_pb_mail.multipart_mime_type);

    xx_pa_pb_mail.attach_text ( conn => l_conn,
                                data => p_msg,
                                mime_type =>'text/html'
							  );
    xx_pa_pb_mail.xx_attch_doc (l_conn,
								p_file_name,
                                p_file_data,
                                'text/plain; charset=UTF-8'
                               );

    xx_pa_pb_mail.end_attachment (conn => l_conn);

    xx_pa_pb_mail.end_mail( conn => l_conn );
EXCEPTION
WHEN OTHERS
THEN
  fnd_file.put_line(fnd_file.log,'Error occured in sending Email. SQLERRM-'||sqlerrm );
END send_email;
--/**********************************************************************
--* Procedure to automatically purge data in staging tables after 60 days
--***********************************************************************/
PROCEDURE XX_PURGE_STAGING
IS
l_purge_days NUMBER;
BEGIN

  SELECT XFTV.TARGET_VALUE1
  INTO l_purge_days
  FROM XX_FIN_TRANSLATEDEFINITION XFTD,
  XX_FIN_TRANSLATEVALUES XFTV
  WHERE XFTD.TRANSLATION_NAME ='XX_GL_IMS_INTERFACE'
  AND XFTV.SOURCE_VALUE1      ='PURGE_DAYS'
  AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
  AND XFTD.ENABLED_FLAG       ='Y'
  AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);

/*Delete all records older than Purge Days derived*/
  DELETE
  FROM XX_GL_INTERFACE_NA_STG
  WHERE USER_JE_SOURCE_NAME  = gc_journal_source_name
  and DATE_CREATED < sysdate-l_purge_days ;
  COMMIT;

EXCEPTION
WHEN OTHERS THEN
  print_debug_msg(p_message => 'error in xx_purge_staging procedure '||sqlerrm , p_force => true);
END XX_PURGE_STAGING;
/*********************************************************************
  * Procedure email_error_html_msg is used create HTML body for File Load Errors
  *
 ******************************************************************** */
FUNCTION email_error_html_msg (
p_file_name				IN VARCHAR2
) RETURN VARCHAR2
IS
l_mail_msg VARCHAR2(2000);
BEGIN
  l_mail_msg :=
				' <html>
					<body>
					  <p><font size=4
						  color="red"> ERROR!! </font> </p>
					  <p> Issue with GL IMS File being processed with file name <b>'|| p_file_name ||'</b> <i>on staging table XX_GL_INTERFACE_NA_STG</i>.
					  <br>
					  <br><b> Please refer attachment for error details.</b>
					  <br>
					  <br>
					  <p><font size=2
						  color="LightGray">
					   ---------------------------------------------------------------------
					  <br><i>This is a system generated mail. Please do not reply.<i><br>
					   --------------------------------------------------------------------- </font></p>
					  <br>
					</body>
				  </html>';

RETURN l_mail_msg;

EXCEPTION
WHEN OTHERS
THEN
  fnd_file.put_line(fnd_file.log,'Error occured in sending Email. SQLERRM-'||sqlerrm );
END email_error_html_msg;

/*********************************************************************
* Procedure used to log based on gc_debug := 'Y' value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE logit(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2(2000) := NULL;
BEGIN
  --if debug is on (defaults to true)

  IF (gc_debug='Y' OR p_force) THEN
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
  IF gc_debug = 'Y' THEN
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
*  Setter procedure for gc_debug global variable
*  used for controlling debugging
***********************************************/
PROCEDURE set_debug(
    p_debug_flag IN VARCHAR2)
IS
BEGIN
  IF (UPPER(p_debug_flag) IN('Y', 'YES', 'T', 'TRUE')) THEN
    gc_debug := 'Y';
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
  IF gc_debug = 'Y' THEN
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

/**********************************************************************
* Helper procedure to log the sub procedure/function name that has been
* called and logs the input parameters passed to it.
***********************************************************************/
PROCEDURE update_file_load_error(
    p_error_code	IN VARCHAR2,
	p_source_name	IN VARCHAR2,
    P_ERROR_MSG     IN VARCHAR2,
    P_FILE_NAME     IN VARCHAR2,
	p_sql_Error		IN VARCHAR2,
	P_GROUP_ID		IN NUMBER)
AS
BEGIN
   print_debug_msg(p_message =>'Updating XX_GL_INTERFACE_NA_ERROR:  '||P_ERROR_MSG, p_force => true);

   INSERT INTO XX_GL_INTERFACE_NA_ERROR
    (
     fnd_error_code
    ,source_name
    ,details
    ,type
    ,value
    ,group_id
    ,set_of_books_id
    ,creation_date
     )
	VALUES
	(
	 p_error_code
	,p_source_name
	,P_ERROR_MSG
	,P_FILE_NAME
	,SUBSTR (p_sql_Error, 0, 249)
	,p_group_id
	,gn_set_of_bks_id
	,sysdate
	);

	UPDATE XX_GL_INTERFACE_NA_STG
	SET status='ERROR'
	WHERE GROUP_ID=P_GROUP_ID;

  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  print_debug_msg(p_message => 'error in updating XX_GL_INTERFACE_NA_STG '||sqlerrm , p_force => true);
END update_file_load_error;
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
  IF gc_debug = 'Y' THEN
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
    p_delim IN VARCHAR2 DEFAULT chr(44) ,
    p_error_msg OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2)
IS
  l_string VARCHAR2(32767) := p_delimstring;
  l_nfields pls_integer    := 1;
  l_table varchar2_table;
  l_delimpos pls_integer := instr(p_delimstring, p_delim);
  l_delimlen pls_integer := LENGTH(p_delim);
  lc_procedure_name	VARCHAR2(100):= 'PARSE_DATAFILE_LINE';
BEGIN

  WHILE l_delimpos > 0
  LOOP
    l_table(l_nfields) := SUBSTR(l_string,1,l_delimpos-1);
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
  p_error_msg := 'Error in XX_GL_IMS_IFACE_PKG.parse_line - record:'||SUBSTR(p_delimstring,150)||SUBSTR(sqlerrm,1,150);
  logit(p_message => 'Backtrace => '||dbms_utility.format_error_backtrace);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
END parse_datafile_line;


--/*********************************************************************
--* Procedure used to read data from XX_GL_INTERFACE_NA_ERROR and call send_Email proc
--* to notify users with file load errors
--* This procedure is called each time for all the files that needs to be processed.
--*********************************************************************/
PROCEDURE LOAD_FILE_ERROR_NOTIFY(
    p_group_id NUMBER, p_file_name IN VARCHAR2)
IS
CURSOR cur_load_file_error
IS
SELECT  fnd_error_code error_Code,
		source_name,
		details error_message,
		type  FILE_NAME,
		value  SQL_ERRM,
		group_id,
		set_of_books_id,
		creation_date
FROM
    XX_GL_INTERFACE_NA_ERROR
WHERE GROUP_ID=P_GROUP_ID
AND TYPE=P_FILE_NAME;

l_error_cnt				NUMBER:=0;
l_file_data 			BLOB;
l_src_data 				BLOB;
l_recipients 			VARCHAR2(1000);
l_recipients_cc 		VARCHAR2(1000);
l_err_msg         		VARCHAR2(1000);
l_mail_msg				VARCHAR2(1000);
l_attachfile_name		VARCHAR2(100);
l_error_subject			VARCHAR2(50) 		:='Oracle GL IMS File Load Error';
lc_procedure_name	VARCHAR2(100):= 'LOAD_FILE_ERROR_NOTIFY';

BEGIN

  SELECT  trim(both ',' from regexp_replace(
     ( XFTV.TARGET_VALUE1  ||','||XFTV.TARGET_VALUE2  ||','
	   ||XFTV.TARGET_VALUE3  ||','||XFTV.TARGET_VALUE4  ||','
     ||XFTV.TARGET_VALUE5  ||','||XFTV.TARGET_VALUE6  ||','
     ||XFTV.TARGET_VALUE7  ||','||XFTV.TARGET_VALUE8  ||','
     ||XFTV.TARGET_VALUE9  ||','||XFTV.TARGET_VALUE10 ||','
     ||XFTV.TARGET_VALUE11 ||','||XFTV.TARGET_VALUE12 ||','
     ||XFTV.TARGET_VALUE13 ||','||XFTV.TARGET_VALUE14 ||','
     ||XFTV.TARGET_VALUE15),
     '(,)+', '\1')) l_recipients
	INTO l_recipients
	FROM XX_FIN_TRANSLATEDEFINITION XFTD,
	  XX_FIN_TRANSLATEVALUES XFTV
	WHERE XFTD.TRANSLATION_NAME ='XX_GL_IMS_INTERFACE'
	AND XFTV.SOURCE_VALUE1      ='FILE_ERROR_EMAIL_TO'
	AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
	AND XFTD.ENABLED_FLAG       ='Y'
	AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);

	SELECT  trim(both ',' from regexp_replace(
     ( XFTV.TARGET_VALUE1  ||','||XFTV.TARGET_VALUE2  ||','
	   ||XFTV.TARGET_VALUE3  ||','||XFTV.TARGET_VALUE4  ||','
     ||XFTV.TARGET_VALUE5  ||','||XFTV.TARGET_VALUE6  ||','
     ||XFTV.TARGET_VALUE7  ||','||XFTV.TARGET_VALUE8  ||','
     ||XFTV.TARGET_VALUE9  ||','||XFTV.TARGET_VALUE10 ||','
     ||XFTV.TARGET_VALUE11 ||','||XFTV.TARGET_VALUE12 ||','
     ||XFTV.TARGET_VALUE13 ||','||XFTV.TARGET_VALUE14 ||','
     ||XFTV.TARGET_VALUE15),
     '(,)+', '\1')) l_recipients_cc
	INTO l_recipients_cc
	FROM XX_FIN_TRANSLATEDEFINITION XFTD,
	  XX_FIN_TRANSLATEVALUES XFTV
	WHERE XFTD.TRANSLATION_NAME ='XX_GL_IMS_INTERFACE'
	AND XFTV.SOURCE_VALUE1      ='FILE_ERROR_EMAIL_CC'
	AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
	AND XFTD.ENABLED_FLAG       ='Y'
	AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);

	l_mail_msg			:= email_error_html_msg (p_file_name );
	l_attachfile_name	:= 'IMS-Oracle_GL_File_Load_Error_'||to_char(sysdate,'DD_MON_YYYY')||'.txt';


	dbms_lob.createtemporary(l_file_data, TRUE);

		l_err_msg :=l_err_msg||'SOURCE_NAME           '||'GROUP_ID     '||'ERROR_MESSAGE	'||chr(13)||chr(10);
		l_err_msg :=l_err_msg||'-------------------------------------------------------------------------------------'||chr(13)||chr(10);
		l_src_data:=   utl_raw.cast_to_raw(l_err_msg);
		DBMS_LOB.APPEND(l_file_data,l_src_data);

		FOR rec_load_file_error in cur_load_file_error
		loop
			l_src_data := utl_raw.cast_to_raw(rpad(rec_load_file_error.source_name,22,' ')||rpad(rec_load_file_error.GROUP_ID,13,' ')||rec_load_file_error.ERROR_MESSAGE ||chr(13)||chr(10));
			DBMS_LOB.APPEND(l_file_data,l_src_data);

		end loop;

		 send_email (
					l_error_subject	,
					l_mail_msg      ,
					l_recipients 	,
					l_recipients_cc	,
					l_file_data     ,
					l_attachfile_name
					);
exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => FALSE);

EXCEPTION
WHEN OTHERS THEN
  logit(p_message => 'Backtrace => '||dbms_utility.format_error_backtrace);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
END LOAD_FILE_ERROR_NOTIFY;

--+=================================================================================+
--| Name          : DERIVE_CCID			                                   		 	|
--| Description   : This procedure will derive CCID's for records in staging table  |
--|                                                                               	|
--| Parameters    : x_ret_code OUT NUMBER ,                                			|
--|                 x_err_buf OUT VARCHAR2                                        	|
--+=================================================================================+
PROCEDURE DERIVE_CCID
(   p_group_id	   IN NUMBER,
	p_errbuf  OUT nocopy  VARCHAR2 ,
    p_retcode OUT nocopy NUMBER
)
IS
  l_ret_code      NUMBER;
  l_err_buff      VARCHAR2 (4000);
  l_error_message VARCHAR2(4000) := '';
  lc_ccid_acct varchar2(100);
  lv_derived_ccid number;
  lc_procedure_name	VARCHAR2(100):= 'DERIVE_CCID';
  --==========================================================================================
  -- Cursor to derive Code Combination Id
  --==========================================================================================
  cursor cur_derive_ccid is
  select rowid,stg.* from
  XX_GL_INTERFACE_NA_STG stg
  where 1=1
  and group_id=p_group_id
  and STATUS ='NEW';

  TYPE lv_derive_ccid_tab IS TABLE OF cur_derive_ccid%ROWTYPE
         INDEX BY BINARY_INTEGER;
  lv_derive_ccid_data       lv_derive_ccid_tab;
  lv_record 				number;
  lv_error_message 			varchar2(2000);
  x_err_buf 				varchar2(1000);
  x_ret_code 				number:=0;


BEGIN
--==========================================================================================
  -- Cursor to derive CCID validation
  --==========================================================================================

        gc_error_status_flag:='N';
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
						  lc_ccid_acct   :=lv_derive_ccid_data(idx).segment1||'.'||
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
													lv_error_message:='Code Combination ID not found for ' || lc_ccid_acct;
													logit(lv_error_message);

												    Update XX_GL_INTERFACE_NA_STG set
												    STATUS_DESCRIPTION=decode(STATUS_DESCRIPTION,null,lv_error_message,STATUS_DESCRIPTION||'~'||lv_error_message)
												    where rowid=lv_derive_ccid_data(idx).rowid;
											else
													Update XX_GL_INTERFACE_NA_STG set
												    CODE_COMBINATION_ID  = lv_derived_ccid
													,derived_val         = 'VALID'
												    where rowid=lv_derive_ccid_data(idx).rowid;
											end if;
						 Exception
							when others then
							lv_error_message:='Error to derive Code Combination Id-'||lc_ccid_acct||'. SQLERRM-'||sqlerrm;
						    gc_error_status_flag:='Y';
							logit(lv_error_message);
								Update XX_GL_INTERFACE_NA_STG set
								STATUS_DESCRIPTION=decode(STATUS_DESCRIPTION,null,lv_error_message,STATUS_DESCRIPTION||'~'||lv_error_message)
								where rowid=lv_derive_ccid_data(idx).rowid;
						 end;
					end loop;
			end loop;
	    print_debug_msg(p_message => 'Derive Code Combination ID validation completes' , p_force => False);
		close cur_derive_ccid;
		commit;
	exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => FALSE);
EXCEPTION
WHEN OTHERS THEN
  p_retcode   := '2';
  p_errbuf := 'Error in XX_GL_IMS_IFACE_PKG.DERIVE_CCID ' ;
  logit(p_message => 'Backtrace => '||dbms_utility.format_error_backtrace);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
END DERIVE_CCID;

--+=================================================================================+
--| Name          : VALIDATE_CURRENCY                                   		 	|
--| Description   : This procedure will validate  GL Journal records for currency_code in staging table|
--|                                                                               	|
--| Parameters    : x_ret_code OUT NUMBER ,                                			|
--|                 x_err_buf OUT VARCHAR2                                        	|
--+=================================================================================+
PROCEDURE VALIDATE_CURRENCY
	(
	p_group_id	   IN NUMBER,
	p_errbuf  OUT nocopy  VARCHAR2 ,
    p_retcode OUT nocopy NUMBER )

IS
  l_ret_code      NUMBER;
  l_err_buff      VARCHAR2 (4000);
  l_error_message VARCHAR2(4000) := '';
  lc_procedure_name	VARCHAR2(100):= 'VALIDATE_CURRENCY';

  --==========================================================================================
  -- Cursor Declarations for Currency Code Validation
  --==========================================================================================
  cursor cur_currency_code is

  select distinct currency_code from
  XX_GL_INTERFACE_NA_STG
  where 1=1
  and group_id=p_group_id
  and STATUS ='NEW';

  TYPE lv_currency_code_tab IS TABLE OF cur_currency_code%ROWTYPE
         INDEX BY BINARY_INTEGER;

  lv_currency_code_data                  lv_currency_code_tab;

  x_err_buf varchar2(1000);
  x_ret_code number:=0;
  lv_record	VARCHAR2(1);


BEGIN

 --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_status_flag := 'N';
  l_error_message      := NULL;
  l_ret_code           := 0;
  l_err_buff           := NULL;

  --==========================================================================================
  -- Cursor Declarations for Currency Code Validation
  --==========================================================================================
	 	gc_error_status_flag:='N';
		print_debug_msg(p_message => 'Currency Code Validation begins' , p_force => False);
			OPEN cur_currency_code;
			Loop
			FETCH cur_currency_code
				BULK COLLECT INTO lv_currency_code_data LIMIT 5000;
				EXIT WHEN lv_currency_code_data.COUNT = 0;

					FOR idx IN lv_currency_code_data.FIRST .. lv_currency_code_data.LAST
					LOOP

					l_error_message:=null;
			            Begin
						  select 1 into lv_record from fnd_currencies
						  where currency_code=lv_currency_code_data(idx).currency_code;

						 Exception
						 when no_data_found then
							 gc_error_status_flag:='Y';
							 l_error_message :='Currency Code '||lv_currency_code_data(idx).currency_code ||' not found';
							 logit(l_error_message);
						  when others then
						  l_error_message:='Validation error-Currency Code '||lv_currency_code_data(idx).currency_code||' not found. SQLERRM-'||sqlerrm||'.';
						  gc_error_status_flag:='Y';
						  logit(l_error_message);
						 end;

						  if gc_error_status_flag='Y' then

							    INSERT INTO XX_GL_INTERFACE_NA_ERROR
											(
											 fnd_error_code
											,source_name
											,details
											,type
											,value
											,group_id
											,set_of_books_id
											,creation_date
											 )
											VALUES
											(
											 'INVALID_CURRENCY_CODE'
											,gc_journal_source_name
											,l_error_message
											,NULL
											,NULL
											,p_group_id
											,gn_set_of_bks_id
											,sysdate
											);
								gc_error_status_flag:='N';
						end if;

					end loop;
			end loop;

          print_debug_msg(p_message => 'Currency Code Validation completed' , p_force => False);
		close cur_currency_code;
		commit;
exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => FALSE);
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in VALIDATE_CURRENCY().Error:'|| l_err_buff , p_force => true);
  logit('Error in VALIDATE_CURRENCY'||sqlerrm );
  p_retcode      := 2;
  p_errbuf       := l_err_buff;
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  logit(p_message => 'Backtrace => '||dbms_utility.format_error_backtrace);
END VALIDATE_CURRENCY;

--+=================================================================================+
--| Name          : BALANCE_JOURNALS                                   		 		|
--| Description   : This procedure will balance journals in staging table			|
--|                                                                               	|
--| Parameters    : x_ret_code OUT NUMBER ,                                			|
--|                 x_err_buf OUT VARCHAR2                                        	|
--+=================================================================================+
PROCEDURE BALANCE_JOURNALS(
    p_group_id IN NUMBER,
    p_errbuf OUT nocopy  VARCHAR2 ,
    p_retcode OUT nocopy NUMBER )
IS
  l_ret_code      NUMBER;
  l_err_buff      VARCHAR2 (4000);
  l_error_message VARCHAR2(4000) := '';
  lc_procedure_name	VARCHAR2(100):= 'BALANCE_JOURNALS';
  --==========================================================================================
  -- Cursor to add system auto balance lines
  --==========================================================================================
  CURSOR cur_gl_autobalance
  IS
    SELECT status ,
      XGINS.set_of_books_id,
      GL.currency_code sob_curr,
      date_created ,
      actual_flag ,
      group_id ,
      reference1 ,
      reference2 ,
      reference4 ,
      reference5 ,
      reference6 ,
      segment1,
      user_je_category_name ,
      user_je_source_name ,
      accounting_date ,
      XGINS.currency_code ,
      DECODE(SIGN(SUM(NVL(entered_dr,0))-SUM(NVL(entered_cr,0))),-1,-(SUM(NVL(entered_dr,0))-SUM(NVL(entered_cr,0))),NULL) debit ,
      DECODE(SIGN(SUM(NVL(entered_dr,0))-SUM(NVL(entered_cr,0))),1,SUM(NVL(entered_dr,0))-SUM(NVL(entered_cr,0)),NULL) credit ,
      reference24 ,
      target_Value2 ,
      target_Value3 ,
      target_Value4 ,
      target_Value5 ,
      target_Value6 ,
      target_Value7 ,
      'SYSTEM AUTO BALANCE' AS reference10
    FROM xx_gl_interface_na_stg XGINS ,
      gl_ledgers GL ,
      xx_fin_translatedefinition XFTD ,
      xx_fin_translatevalues XFTV
    WHERE user_je_source_name       = gc_journal_source_name
    AND XGINS.set_of_books_id       = GL.ledger_id(+)
    AND XFTD.translation_name       = 'XX_GL_IMS_DEFAULTS'
    AND XFTD.translate_id           = XFTV.translate_id
    AND XFTV.source_value1          = GL.currency_code
    AND group_id                    = p_group_id
    AND XGINS.set_of_books_id       = gn_set_of_bks_id
    AND (NVL(derived_val,'INVALID') = 'INVALID'
    OR NVL(derived_sob,'INVALID')   = 'VALID'
    OR NVL(balanced ,'UNBALANCED')  = 'UNBALANCED')
    GROUP BY status ,
      XGINS.set_of_books_id ,
      GL.currency_code ,
      date_created ,
      actual_flag ,
      group_id ,
      reference1 ,
      reference2 ,
      reference4 ,
      reference5 ,
      reference6 ,
      segment1,
      user_je_category_name ,
      user_je_source_name ,
      accounting_date ,
      XGINS.currency_code ,
      reference24 ,
      target_Value2 ,
      target_Value3 ,
      target_Value4 ,
      target_Value5 ,
      target_Value6 ,
      target_Value7
    HAVING SUM(NVL(entered_dr,0))-SUM(NVL(entered_cr,0)) <> 0;
TYPE lv_gl_autobalance_tab
IS
  TABLE OF cur_gl_autobalance%ROWTYPE INDEX BY BINARY_INTEGER;
  lv_gl_autobalance_data lv_gl_autobalance_tab;
  x_err_buf  VARCHAR2(1000);
  x_ret_code NUMBER:=0;
BEGIN
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_status_flag := 'N';
  l_error_message      := NULL;
  l_ret_code           := 0;
  l_err_buff           := NULL;
  --==========================================================================================
  -- Cursor Declarations for Currency Code Validation
  --==========================================================================================
  gc_error_status_flag:='N';
  print_debug_msg(p_message => 'Journal System Auto Balance Validation' , p_force => TRUE);
  OPEN cur_gl_autobalance;
  LOOP
    FETCH cur_gl_autobalance BULK COLLECT INTO lv_gl_autobalance_data LIMIT 5000;
    EXIT
  WHEN lv_gl_autobalance_data.COUNT = 0;
    print_debug_msg(p_message => 'Jounral Lines Not Balanced. Adding System Auto Balance Lines' , p_force => TRUE);
    FOR idx IN lv_gl_autobalance_data.FIRST .. lv_gl_autobalance_data.LAST
    LOOP
      l_error_message:=NULL;
      /*Insert System Auto Balance Lines*/
      INSERT
      INTO XX_GL_INTERFACE_NA_STG
        (
          status ,
          set_of_books_id ,
          date_created ,
          created_by ,
          actual_flag ,
          group_id ,
          reference1 ,
          reference2 ,
          reference4 ,
          reference5 ,
          reference6 ,
          user_je_category_name ,
          user_je_source_name ,
          accounting_date ,
          currency_code ,
          entered_dr ,
          entered_cr ,
          reference10 ,
          reference24 ,
          segment1 ,
          segment2 ,
          segment3 ,
          segment4 ,
          segment5 ,
          segment6 ,
          segment7
        )
        VALUES
        (
          lv_gl_autobalance_data(idx).status ,
          lv_gl_autobalance_data(idx).set_of_books_id ,
          lv_gl_autobalance_data(idx).date_Created ,
          gn_user_id ,
          lv_gl_autobalance_data(idx).actual_flag ,
          lv_gl_autobalance_data(idx).group_id ,
          lv_gl_autobalance_data(idx).reference1 ,
          lv_gl_autobalance_data(idx).reference2 ,
          lv_gl_autobalance_data(idx).reference4 ,
          lv_gl_autobalance_data(idx).reference5 ,
          lv_gl_autobalance_data(idx).reference6 ,
          lv_gl_autobalance_data(idx).user_je_category_name ,
          lv_gl_autobalance_data(idx).user_je_source_name ,
          lv_gl_autobalance_data(idx).accounting_date ,
          lv_gl_autobalance_data(idx).currency_code ,
          lv_gl_autobalance_data(idx).debit ,
          lv_gl_autobalance_data(idx).credit ,
          lv_gl_autobalance_data(idx).reference10 ,
          lv_gl_autobalance_data(idx).reference24 ,
          lv_gl_autobalance_data(idx).segment1 ,
          lv_gl_autobalance_data(idx).target_value2 ,
          lv_gl_autobalance_data(idx).target_value3 ,
          lv_gl_autobalance_data(idx).target_value4 ,
          lv_gl_autobalance_data(idx).target_value5 ,
          lv_gl_autobalance_data(idx).target_value6 ,
          lv_gl_autobalance_data(idx).target_value7
        );
    END LOOP;
  END LOOP;
  --Update the journal lines to BALANCED in staging
  UPDATE XX_GL_INTERFACE_NA_STG
  SET BALANCED   = 'BALANCED'
  WHERE group_id = p_group_id;

  --If journals are already balanced then update the journal lines to BALANCED
  IF cur_gl_autobalance%ROWCOUNT=0 THEN
    print_debug_msg(p_message => 'Journal Lines already balanced for Group ID :'||p_group_id , p_force => TRUE);
    UPDATE XX_GL_INTERFACE_NA_STG
    SET BALANCED   = 'BALANCED'
    WHERE group_id = p_group_id;
  END IF;

  CLOSE CUR_GL_AUTOBALANCE;

  COMMIT;
 exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => FALSE);
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in BALANCE_JOURNALS() - Error:'|| l_err_buff , p_force => true);
  logit('Error in BALANCE_JOURNALS'||sqlerrm );
  p_retcode := 2;
  p_errbuf  := l_err_buff;
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  logit(p_message => 'Backtrace => '||dbms_utility.format_error_backtrace);
END BALANCE_JOURNALS;

-- +============================================================================================+
-- |  Name  : LOAD_UTL_FILE_STAGING                                                             |
-- |  Description: This procedure reads data from the file and inserts into staging table       |
-- =============================================================================================|
PROCEDURE LOAD_UTL_FILE_STAGING(
    p_file_name    VARCHAR2,
	p_file_dir	   VARCHAR2,
    p_debug_flag   VARCHAR2,
    p_request_id   NUMBER,
	p_user_id   number,
	p_errbuf  OUT nocopy  VARCHAR2 ,
    p_retcode OUT nocopy NUMBER )
AS
	l_filehandle 				utl_file.file_type;
	l_filedir 					VARCHAR2(20) 		:= 'XXFIN_IMS_GL_IN';
	l_dirpath 					VARCHAR2(500)		;
	l_new_line					VARCHAR2(32767)		;
	l_newline 					VARCHAR2(32767)		; -- Input line
	l_max_linesize 				BINARY_INTEGER 		:= 32767;
	l_rec_cnt    				NUMBER              := 0;
	l_table 					varchar2_table;
	l_nfields           		INTEGER;
	l_error_msg         		VARCHAR2(1000) 		:= NULL;
	l_mail_msg         			VARCHAR2(1000) 		:= NULL;
	l_error_loc         		VARCHAR2(2000) 		:= 'XX_GL_IMS_IFACE_PKG.load_utl_file_staging';
	lc_procedure_name 			CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'LOAD_UTL_FILE_STAGING';
	l_retcode           		VARCHAR2(3)    		:= NULL;
	parse_exception     		EXCEPTION;
	duplicate_file_exception    EXCEPTION;
	NULL_DATA_EXCEPTION   		EXCEPTION;
	l_dup_settlement_id 		NUMBER;
	lt_parameters 				gt_input_parameters;
	l_ignore_headerlines		NUMBER;
	l_delimeter 				VARCHAR2(10);
  /*staging table columns*/
	l_group_id					NUMBER;
	l_status                    XX_GL_INTERFACE_NA_STG.STATUS%TYPE:='NEW'				 ;
    LC_GL_INTERFACE_NA_STG 		XX_GL_INTERFACE_NA_STG%ROWTYPE;

	l_journal_category			VARCHAR2(100);
    l_filerec_count 			NUMBER:=0;
	l_datafile_rec_number 		NUMBER:=0;
	l_filerec_err_count			NUMBER:=0;
	l_file_err_cnt				NUMBER:=0;
	l_header_desc				VARCHAR2(100);
	ln_je_exists				NUMBER:=0;
	ln_je_iface_exists			NUMBER:=0;


BEGIN

  lt_parameters('p_file_name')   := p_file_name;
  lt_parameters('p_debug_flag')  := p_debug_flag;
  lt_parameters('p_RequestID')   := p_request_id;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);


  print_debug_msg('p_request_id :'||p_request_id, true);
  print_debug_msg('p_user_id :'||p_user_id, true);

  set_debug(p_debug_flag => p_debug_flag);
  /*Get the next Group ID from Sequence*/
  l_group_id:=gl_interface_control_s.NEXTVAL;

    SELECT gsob.chart_of_accounts_id
	into gn_chart_of_accounts_id
    FROM gl_sets_of_books gsob
    WHERE set_of_books_id = gn_set_of_bks_id;

	SELECT XFTV.TARGET_VALUE2
	INTO l_delimeter
      FROM XX_FIN_TRANSLATEDEFINITION XFTD,
      XX_FIN_TRANSLATEVALUES XFTV
    WHERE XFTD.TRANSLATION_NAME ='XX_GL_IMS_INTERFACE'
    AND XFTV.SOURCE_VALUE1      ='FILE_DELIMETER'
    AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
    AND XFTD.ENABLED_FLAG       ='Y'
    AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);

	SELECT XFTV.TARGET_VALUE1
	INTO gc_journal_source_name
      FROM XX_FIN_TRANSLATEDEFINITION XFTD,
      XX_FIN_TRANSLATEVALUES XFTV
    WHERE XFTD.TRANSLATION_NAME ='XX_GL_IMS_INTERFACE'
    AND XFTV.SOURCE_VALUE1      ='INVENTORY'
    AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
    AND XFTD.ENABLED_FLAG       ='Y'
    AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);


	/*Check for Duplicate File*/
		SELECT COUNT(1)
		INTO l_filerec_count
		FROM XX_GL_INTERFACE_NA_STG
		WHERE REFERENCE24=p_file_name;

		SELECT COUNT(1)
		INTO l_filerec_err_count
		FROM XX_GL_INTERFACE_NA_ERROR
		WHERE TYPE=p_file_name;


		IF l_filerec_count <> 0  or l_filerec_err_count<>0 THEN
			p_errbuf:='Duplicate File-This file is already processed.';
			p_retcode:=2;
			l_error_msg:='Duplicate File-This file is already processed.'||p_file_name;
			logit(p_message=>'Duplicate File-This file is already processed.'||p_file_name);
			RAISE duplicate_file_exception;
		END IF;

	    l_filedir 				:= NVL(p_file_dir, 'XXFIN_IMS_GL_IN');
		l_status 				:= 'NEW';

	    print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
	    print_debug_msg(p_message => 'Loading File:'||p_file_name , p_force => true);

	 /*Opening the file*/
	    l_filehandle := utl_file.fopen(l_filedir,p_file_name,'r',l_max_linesize);

	 /*Reading the File header in the file*/
	    UTL_FILE.get_line (l_filehandle, l_newline);
		print_debug_msg ('Header Line: '|| l_newline, true);
		logit(p_message =>'Header Line: '|| l_newline);

  LOOP
    /*Initialize Local Variables*/
    l_newline := NULL;
	l_new_line := NULL;
	l_journal_category:= NULL;
	l_error_msg :=NULL;

    BEGIN
      utl_file.get_line(l_filehandle,l_newline);
      IF l_newline IS NULL THEN
        EXIT;
      END IF;

	   l_datafile_rec_number:=l_datafile_rec_number+1;

	  /*Trimming extra whitespaces using regular exp between two commas*/
	  /*SELECT regexp_replace(
         l_newline  ,
         '[[:space:]]+,',
         ','
       ) regexp
	   INTO l_new_line
	   from DUAL;*/

      parse_datafile_line(l_newline,l_table,l_nfields,l_delimeter,l_error_msg,l_retcode);

      IF l_retcode = '2' THEN
        raise parse_exception;
      END IF;

	  IF l_table(1)='TRANSACTION DATE'
	  THEN EXIT;
	  END IF;

		LC_GL_INTERFACE_NA_STG.STATUS							:= l_STATUS							;
		LC_GL_INTERFACE_NA_STG.GROUP_ID                        	:= l_group_id                       ;
		LC_GL_INTERFACE_NA_STG.STATUS_DESCRIPTION				:= NULL								;
		LC_GL_INTERFACE_NA_STG.SET_OF_BOOKS_ID					:= gn_set_of_bks_id					;
		LC_GL_INTERFACE_NA_STG.chart_of_accounts_id				:= gn_chart_of_accounts_id			;
		LC_GL_INTERFACE_NA_STG.derived_sob						:= 'VALID'							;
		LC_GL_INTERFACE_NA_STG.derived_val						:= 'INVALID'						;
		LC_GL_INTERFACE_NA_STG.balanced							:= 'UNBALANCED'						;
		LC_GL_INTERFACE_NA_STG.TRANSACTION_DATE                	:= to_Date(l_table(1),'YYYYMMDD')   ;
		LC_GL_INTERFACE_NA_STG.ACCOUNTING_DATE                	:= to_Date(l_table(1),'YYYYMMDD')   ;
		LC_GL_INTERFACE_NA_STG.REFERENCE6                      	:= TRIM(l_table(2))                 ;  --VoucherID


		If ((TRIM(l_table(3) ) IS NOT NULL) AND ((TRIM(l_table(3) ) <> CHR(10)) OR (TRIM(l_table(3) ) <> CHR(13))))
			THEN
			LC_GL_INTERFACE_NA_STG.REFERENCE1                     := TRIM(l_table(3))||TRIM(l_table(2))           ;  --SOURCECODE
			LC_GL_INTERFACE_NA_STG.REFERENCE4                     := TRIM(l_table(3))||TRIM(l_table(2))           ;  --Journal Header
		ELSE
		    LC_GL_INTERFACE_NA_STG.REFERENCE1                     := TRIM(l_table(3))||TRIM(l_table(2))           ;	 --SOURCECODE
			LC_GL_INTERFACE_NA_STG.REFERENCE4                     := TRIM(l_table(3))||TRIM(l_table(2)) 		  ;  --Journal Header
			l_error_msg := 'SOURCE_CODE Value is NULL for a line in file at Line# ' ||l_datafile_rec_number;
			UPDATE_FILE_LOAD_ERROR('SOURCE_CODE_NULL',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,l_error_msg, l_group_id);
		END IF;

		If ((TRIM(l_table(4) ) IS NOT NULL) AND ((TRIM(l_table(4) ) <> CHR(10)) OR (TRIM(l_table(4) ) <> CHR(13))))
			THEN
			LC_GL_INTERFACE_NA_STG.SEGMENT1                       := l_table(4)                       ;  --COMPANY
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT1                := l_table(4)                       ;  --COMPANY
		ELSE
		    LC_GL_INTERFACE_NA_STG.SEGMENT1                       := l_table(4)                       ;  --COMPANY
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT1                := l_table(4)                       ;  --COMPANY
			l_error_msg := 'COMPANY Value is NULL for a line in file at Line# ' ||l_datafile_rec_number;
			UPDATE_FILE_LOAD_ERROR('GL_SEGMENT_NULL',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,l_error_msg, l_group_id);
		END IF;

		If ((TRIM(l_table(5) ) IS NOT NULL) AND ((TRIM(l_table(5) ) <> CHR(10)) OR (TRIM(l_table(5) ) <> CHR(13))))
			THEN
			LC_GL_INTERFACE_NA_STG.SEGMENT2                     := l_table(5)                      	    ; --COST_CENTER
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT2              := l_table(5)                       	; --COST_CENTER
		ELSE
		    LC_GL_INTERFACE_NA_STG.SEGMENT2                     := l_table(5)                       	; --COST_CENTER
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT2              := l_table(5)                       	; --COST_CENTER
			l_error_msg := 'COST_CENTER Value is NULL for a line in file at Line# ' ||l_datafile_rec_number;
			UPDATE_FILE_LOAD_ERROR('GL_SEGMENT_NULL',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,l_error_msg, l_group_id);
		END IF;

		If ((TRIM(l_table(6) ) IS NOT NULL) AND ((TRIM(l_table(6) ) <> CHR(10)) OR (TRIM(l_table(6) ) <> CHR(13))))
			THEN
			LC_GL_INTERFACE_NA_STG.SEGMENT3                     := l_table(6)                     		; --ACCOUNT
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT3              := l_table(6)                       	; --ACCOUNT
		ELSE
			LC_GL_INTERFACE_NA_STG.SEGMENT3                     := l_table(6)                      		; --ACCOUNT
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT3              := l_table(6)                       	; --ACCOUNT
			l_error_msg := 'ACCOUNT Value is NULL for a line in file at Line# ' ||l_datafile_rec_number;
			UPDATE_FILE_LOAD_ERROR('GL_SEGMENT_NULL',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,l_error_msg, l_group_id);
		END IF;

		If ((TRIM(l_table(7) ) IS NOT NULL) AND ((TRIM(l_table(7) ) <> CHR(10)) OR (TRIM(l_table(7) ) <> CHR(13))))
			THEN
			LC_GL_INTERFACE_NA_STG.SEGMENT4                     := l_table(7)                      		; --LOCATION
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT4              := l_table(7)                       	; --LOCATION
		ELSE
			LC_GL_INTERFACE_NA_STG.SEGMENT4                     := l_table(7)                      		; --LOCATION
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT4              := l_table(7)                       	; --LOCATION
			l_error_msg := 'LOCATION Value is NULL for a line in file at Line# ' ||l_datafile_rec_number;
			print_debug_msg(p_message =>l_error_msg, p_force => true);
			UPDATE_FILE_LOAD_ERROR('GL_SEGMENT_NULL',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,l_error_msg, l_group_id);
		END IF;

		If ((TRIM(l_table(8) ) IS NOT NULL) AND ((TRIM(l_table(8) ) <> CHR(10)) OR (TRIM(l_table(8) ) <> CHR(13))))
			THEN
			LC_GL_INTERFACE_NA_STG.SEGMENT5                     := l_table(8)                      		; --INTERCOMPANY
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT5              := l_table(8)                       	; --INTERCOMPANY
		ELSE
			LC_GL_INTERFACE_NA_STG.SEGMENT5                     := l_table(8)                      		; --INTERCOMPANY
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT5              := l_table(8)                       	; --INTERCOMPANY
			l_error_msg := 'INTERCOMPANY Value is NULL for a line in file at Line# ' ||l_datafile_rec_number;
			print_debug_msg(p_message =>l_error_msg, p_force => true);
			UPDATE_FILE_LOAD_ERROR('GL_SEGMENT_NULL',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,l_error_msg, l_group_id);
		END IF;

		If ((TRIM(l_table(9) ) IS NOT NULL) AND ((TRIM(l_table(9) ) <> CHR(10)) OR (TRIM(l_table(9) ) <> CHR(13))))
			THEN
			LC_GL_INTERFACE_NA_STG.SEGMENT6                     := l_table(9)                       	; --LOB_CHANNEL
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT6              := l_table(9)                       	; --LOB_CHANNEL
		ELSE
		    LC_GL_INTERFACE_NA_STG.SEGMENT6                     := l_table(9)                      		; --LOB_CHANNEL
			LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT6              := l_table(9)                       	; --LOB_CHANNEL
			l_error_msg := 'LOB Value is NULL for a line in file at Line# ' ||l_datafile_rec_number;
			print_debug_msg(p_message =>l_error_msg, p_force => true);
			UPDATE_FILE_LOAD_ERROR('GL_SEGMENT_NULL',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,l_error_msg, l_group_id);
		END IF;

		LC_GL_INTERFACE_NA_STG.SEGMENT7                 		:= NVL(TO_CHAR(l_table(10)),'000000')     ;  --FUTURE
		LC_GL_INTERFACE_NA_STG.LEGACY_SEGMENT7             		:= NVL(TO_CHAR(l_table(10)),'000000')     ;  --FUTURE
		LC_GL_INTERFACE_NA_STG.REFERENCE10                		:= TRIM(l_table(13))                ; --LINE_DESCRIPTION
		LC_GL_INTERFACE_NA_STG.CURRENCY_CODE                    := l_table(14)		                ; --CURRENCY_CODE
		LC_GL_INTERFACE_NA_STG.CURRENCY_CONVERSION_RATE         := TO_NUMBER(RTRIM(RTRIM(l_table(15),chr(10)),chr(13)))    ; --EXCHANGE_RATE
		LC_GL_INTERFACE_NA_STG.CREATED_BY                       := p_user_id                        ;
		LC_GL_INTERFACE_NA_STG.DATE_CREATED                     := SYSDATE                          ;
		LC_GL_INTERFACE_NA_STG.REQUEST_ID                       := p_request_id                     ;
		LC_GL_INTERFACE_NA_STG.USER_JE_SOURCE_NAME              := gc_journal_source_name           ;
		LC_GL_INTERFACE_NA_STG.REFERENCE24                      := p_file_name                      ;  --FILE_NAME
		LC_GL_INTERFACE_NA_STG.ACTUAL_FLAG                      := 'A'                              ;

		BEGIN
			SELECT  XFTV.target_value2 ,XFTV.target_value3
			INTO l_journal_category , l_header_desc
			FROM XX_FIN_TRANSLATEDEFINITION XFTD,
			XX_FIN_TRANSLATEVALUES XFTV
			WHERE XFTD.TRANSLATION_NAME = 'XX_GL_IMS_JOURNALS_SOURCE'
			AND XFTV.SOURCE_VALUE1      = TRIM(l_table(3))
			AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
			AND XFTD.ENABLED_FLAG       ='Y'
			AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);
		EXCEPTION
		WHEN Others THEN
		l_error_msg := 'Error Deriving Journal Category for Source "'||l_table(3)||'" at Line# ' ||l_datafile_rec_number;
		UPDATE_FILE_LOAD_ERROR('GL_CATEGORY_ERROR',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,l_error_msg, l_group_id);
		END;

		LC_GL_INTERFACE_NA_STG.USER_JE_CATEGORY_NAME:=l_journal_category;
		LC_GL_INTERFACE_NA_STG.REFERENCE5:=l_header_desc||' '||l_table(2);				 --Header_Description
		LC_GL_INTERFACE_NA_STG.REFERENCE2:=l_header_desc||' '||l_table(2);				 --Batch_Description

		/*Splitting Credit and Debit Lines*/
		FOR j IN 1..2
        LOOP
			IF j =1 THEN
                LC_GL_INTERFACE_NA_STG.ENTERED_DR		                := NVL(l_table(11),0)  ;
				LC_GL_INTERFACE_NA_STG.ENTERED_CR		                := NULL  			   ;
            END IF;
			IF j =2 THEN
                LC_GL_INTERFACE_NA_STG.ENTERED_DR		                := NULL  			   ;
				LC_GL_INTERFACE_NA_STG.ENTERED_CR		                := NVL(l_table(12),0)  ;
            END IF;
		/*Inserting the data into Staging Table.*/
		INSERT INTO XX_GL_INTERFACE_NA_STG VALUES LC_GL_INTERFACE_NA_STG;
		END LOOP;

      l_rec_cnt := l_rec_cnt + 1;
	EXCEPTION
    WHEN no_data_found THEN
	      EXIT;
    END;

  END LOOP;

  /*Close the file*/
  utl_file.fclose(l_filehandle);
  logit(p_message =>'UTL File Close');

  COMMIT;

   print_debug_msg(p_message =>TO_CHAR(l_rec_cnt)||' records successfully loaded into staging', p_force => true);
   print_debug_msg(p_message => 'File Processed Successfully:'||p_file_name , p_force => true);

   /*Check for Accounting Date from Staging if it already exists for any Journal in Oracle for same source*/
   BEGIN
    SELECT COUNT(1) INTO  ln_je_exists
	FROM gl_je_headers jeh,
	  GL_JE_SOURCES_TL jes
	WHERE jeh.je_source                =jes.je_source_name
	AND jes.user_je_source_name        =gc_journal_source_name
	AND TRUNC(DEFAULT_EFFECTIVE_DATE) IN
	  (SELECT DISTINCT TRUNC(accounting_date)
	  FROM XX_GL_INTERFACE_NA_STG
	  WHERE reference24=p_file_name
	  );
	--Ver#1.2 start
	SELECT COUNT(1) INTO ln_je_iface_exists
	FROM XX_GL_INTERFACE_NA
	WHERE USER_JE_SOURCE_NAME			=gc_journal_source_name
	AND TRUNC(accounting_Date)     IN
	  (SELECT DISTINCT TRUNC(accounting_date)
	  FROM XX_GL_INTERFACE_NA_STG
	  WHERE reference24=p_file_name
	  );	

	IF (ln_je_exists > 0 or ln_je_iface_exists > 0) --Ver#1.2 end
	THEN
	L_ERROR_MSG :='Oracle Journal already exists for Accounting Dates in the file  ' ||P_FILE_NAME;
	UPDATE_FILE_LOAD_ERROR('ACCOUNTING_DATE_ERROR',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,l_error_msg, l_group_id);
	END IF;
   END;

   /*Update Error to XX_GL_INTERFACE_NA_STG*/
   BEGIN
	   SELECT COUNT(1)
	   INTO l_file_err_cnt
		FROM XX_GL_INTERFACE_NA_ERROR
	   WHERE TYPE=p_file_name and group_id=l_group_id;

	   IF (l_file_err_cnt) >0
	   THEN
		UPDATE XX_GL_INTERFACE_NA_STG
		SET status='ERROR'
		WHERE GROUP_ID=l_GROUP_ID;
		COMMIT;

	   /*Send email notification for errors if any during file load*/
	   LOAD_FILE_ERROR_NOTIFY (l_group_id, p_file_name);
	   END IF;
   END;

exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => FALSE);
EXCEPTION
WHEN duplicate_file_exception THEN
  ROLLBACK;
  p_errbuf  := l_error_msg;
  p_retcode := 2;
  print_debug_msg(p_message =>l_error_msg, p_force => true);
  logit(p_message => 'duplicate_file_exception Backtrace => '||dbms_utility.format_error_backtrace);
  UPDATE_FILE_LOAD_ERROR('DUPLICATE_FILE_EXCEPTION',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,sqlerrm, l_group_id);
  LOAD_FILE_ERROR_NOTIFY (l_group_id, p_file_name);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
WHEN parse_exception THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='When parse_exception Exception at Processing Line Number-'||l_datafile_rec_number||' in datafile.SQLERRM-'||l_error_msg||'~'||sqlerrm;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := l_error_msg;
  p_retcode:= 2;
  logit(p_message => 'parse_exception Backtrace => '||dbms_utility.format_error_backtrace);
  UPDATE_FILE_LOAD_ERROR('PARSE_EXCEPTION',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,sqlerrm, l_group_id);
  LOAD_FILE_ERROR_NOTIFY (l_group_id, p_file_name);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
WHEN utl_file.invalid_operation THEN
   ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='When invalid_operation Exception at Processing Line Number-'||l_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := l_error_msg;
  p_retcode:= 2;
  logit(p_message => 'utl_file.invalid_operation Backtrace => '||dbms_utility.format_error_backtrace);
  UPDATE_FILE_LOAD_ERROR('UTL_FILE.INVALID_OPERATION',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,sqlerrm, l_group_id);
  LOAD_FILE_ERROR_NOTIFY (l_group_id, p_file_name);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
WHEN utl_file.invalid_filehandle THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='When invalid_filehandle Exception at Processing Line Number-'||l_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := l_error_msg;
  p_retcode:= 2;
  logit(p_message => 'utl_file.invalid_filehandle Backtrace => '||dbms_utility.format_error_backtrace);
  UPDATE_FILE_LOAD_ERROR('UTL_FILE.INVALID_FILEHANDLE',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,sqlerrm, l_group_id);
  LOAD_FILE_ERROR_NOTIFY (l_group_id, p_file_name);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
WHEN utl_file.read_error THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='When read_error Exception at Processing Line Number-'||l_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := l_error_msg;
  p_retcode:= 2;
  logit(p_message => 'utl_file.read_error Backtrace => '||dbms_utility.format_error_backtrace);
  UPDATE_FILE_LOAD_ERROR('UTL_FILE.READ_ERROR',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,sqlerrm, l_group_id);
  LOAD_FILE_ERROR_NOTIFY (l_group_id, p_file_name);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
WHEN utl_file.invalid_path THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='When invalid_path Exception at Processing Line Number-'||l_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := l_error_msg;
  p_retcode:= 2;
  logit(p_message => 'utl_file.invalid_path Backtrace => '||dbms_utility.format_error_backtrace);
  UPDATE_FILE_LOAD_ERROR('UTL_FILE.INVALID_PATH',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,sqlerrm, l_group_id);
  LOAD_FILE_ERROR_NOTIFY (l_group_id, p_file_name);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
WHEN utl_file.invalid_mode THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='When invalid_mode Exception at Processing Line Number-'||l_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := l_error_msg;
  p_retcode:= 2;
  logit(p_message => 'utl_file.invalid_mode Backtrace => '||dbms_utility.format_error_backtrace);
  UPDATE_FILE_LOAD_ERROR('UTL_FILE.INVALID_MODE',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,sqlerrm, l_group_id);
  LOAD_FILE_ERROR_NOTIFY (l_group_id, p_file_name);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
WHEN utl_file.internal_error THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='When internal_error at Processing Line Number-'||l_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  logit(p_message => 'utl_file.internal_error Backtrace => '||dbms_utility.format_error_backtrace);
  p_errbuf := l_error_msg;
  p_retcode:= 2;
  UPDATE_FILE_LOAD_ERROR('UTL_FILE.INTERNAL_ERROR',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,sqlerrm, l_group_id);
  LOAD_FILE_ERROR_NOTIFY (l_group_id, p_file_name);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
WHEN value_error THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='When Value_Error at Processing Line Number-'||l_datafile_rec_number||'- in datafile.SQLERRM-'||sqlerrm;
  p_retcode:= 2;
  p_errbuf := l_error_msg;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  logit(p_message => 'value_error Backtrace => '||dbms_utility.format_error_backtrace);
  UPDATE_FILE_LOAD_ERROR('UTL_FILE.VALUE_ERROR',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,sqlerrm, l_group_id);
  LOAD_FILE_ERROR_NOTIFY (l_group_id, p_file_name);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
WHEN OTHERS THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  logit(p_message => 'Other Error Backtrace => '||dbms_utility.format_error_backtrace);
  l_error_msg:='When Others Exception at Processing Line Number-'||l_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  p_errbuf := l_error_msg;
  p_retcode:= 2;
  UPDATE_FILE_LOAD_ERROR('OTHER',gc_journal_source_name,L_ERROR_MSG,P_FILE_NAME,sqlerrm, l_group_id);
  LOAD_FILE_ERROR_NOTIFY (l_group_id, p_file_name);
END load_utl_file_staging;


--/*********************************************************************
--* Procedure used to Load Data File into Staging Table.
--* This Package procedure is called from Host Program
--* This procedure is called each time for all the files that needs to be processed.
--*********************************************************************/
PROCEDURE MAIN_LOAD_PROCESS(
    p_file_name    VARCHAR2,
	p_file_dir	   VARCHAR2,
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

  entering_main(p_procedure_name => lc_procedure_name, p_rice_identifier => 'I3131', p_debug_flag => p_debug_flag, p_parameters => lt_parameters);
  set_debug(p_debug_flag => p_debug_flag);
  lc_action := 'Load GL Load Main Process';

  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling LOAD_UTL_FILE_STAGING Procedure' , p_force => true);
  LOAD_UTL_FILE_STAGING( p_file_name => p_file_name, p_file_dir=>p_file_dir, p_debug_flag => p_debug_flag,p_request_id=>p_request_id,p_user_id=>p_user_id,p_errbuf=>x_err_buf,p_retcode=>x_ret_code) ;
  print_debug_msg(P_MESSAGE => 'Exiting LOAD_UTL_FILE_STAGING Procedure' , p_force => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  /*Purge junk data in staging that can never be imported due to errors*/
  XX_PURGE_STAGING;  --Specific to source OD Inventory (SIV).
    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => FALSE);
EXCEPTION
WHEN OTHERS THEN
  logit(p_message => 'Error Occured:'||lc_action||'~SQLCODE:'|| SQLCODE || '~SQLERRM: ' || SQLERRM, p_force => TRUE);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
END MAIN_LOAD_PROCESS;

--/**********************************************************************
--* Main Procedure GL Transactions and Import
--* this procedure calls individual procedures process GL records in Stg
--***********************************************************************/
PROCEDURE MAIN_PROCESS(p_debug_flag   VARCHAR2,
    errbuff OUT VARCHAR2,
    retcode OUT NUMBER
    )
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'MAIN_PROCESS';
  lt_parameters gt_input_parameters;
  lc_action VARCHAR2(1000);
  x_err_buf varchar2(1000);
  x_ret_code number:=0;
  lc_debug_msg	VARCHAR2(2000);

  lc_email_status varchar2(10);
  lc_email_err varchar2(300);
  ln_cnt NUMBER:=0;
  ln_error_cnt	NUMBER :=0;
  ln_error_count	NUMBER:=0;
  lc_purge_err_log  VARCHAR2(10);
  LC_MAIL_SUBJECT	VARCHAR2(2000);
  LN_CONC_ID		NUMBER;

  ------------------------------------------------
  -- Cursor to select all group ids from a source
  ------------------------------------------------
  CURSOR cur_je_process
  IS
  SELECT DISTINCT
          group_id
         ,user_je_source_name
         ,reference24
          FROM  XX_GL_INTERFACE_NA_STG
   WHERE user_je_source_name            = gc_journal_source_name
    AND  (NVL(derived_val,'INVALID')    = 'INVALID'
     OR   NVL(derived_sob,'INVALID')    = 'VALID'
     OR   NVL(balanced   ,'UNBALANCED') = 'UNBALANCED')
	 and status<>'ERROR';

 BEGIN

    SELECT XFTV.TARGET_VALUE1
	INTO gc_journal_source_name
    FROM XX_FIN_TRANSLATEDEFINITION XFTD,
      XX_FIN_TRANSLATEVALUES XFTV
    WHERE XFTD.TRANSLATION_NAME ='XX_GL_IMS_INTERFACE'
    AND XFTV.SOURCE_VALUE1      ='INVENTORY'
    AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
    AND XFTD.ENABLED_FLAG       ='Y'
    AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);
 --================================================================
  --Initializing Global variables
  --================================================================
  set_debug(p_debug_flag => p_debug_flag);
  print_debug_msg(p_message => 'Initializing Global Variables ' , p_force => true);

  lt_parameters('p_debug_flag')   := p_debug_flag;

  entering_main(p_procedure_name => lc_procedure_name, p_rice_identifier => 'I3131', p_debug_flag => gc_debug, p_parameters => lt_parameters);
  --================================================================
  --Adding parameters to the log file
  --================================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Input Parameters' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Debug Flag  :                  '|| p_debug_flag , p_force => true);
  print_debug_msg(p_message => 'Request Id  :                  '|| fnd_global.conc_request_id , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);



 FOR rec_je_process in cur_je_process
 LOOP
   -----------------------------------------------------------
   -- Determine if interface has been run previously for a group_id.
   -- If records exist on error tbl then interface was run already.
   ----------------------------------------------------------------
   lc_debug_msg     := '    Checking Error table for'
                     ||' previous run of Group ID: '|| rec_je_process.group_id;

   print_debug_msg  (lc_debug_msg,p_force=> true);

   SELECT count(1)
   INTO   ln_error_cnt
   FROM   XX_GL_INTERFACE_NA_ERROR
   WHERE  group_id = rec_je_process.group_id
   AND    rownum < 2;

   IF ln_error_cnt > 0 THEN

		lc_purge_err_log := 'Y';

		lc_debug_msg     := '    Previous errors found, '
							||'Purge error flag = '|| lc_purge_err_log;

		print_debug_msg  (lc_debug_msg,p_force=> true);

		-----------------------
		-- Write restart to log
		-----------------------
		XX_GL_INTERFACE_PKG.LOG_MESSAGE
				(p_grp_id      =>   rec_je_process.group_id
				,p_source_nm   =>   gc_journal_source_name
				,p_status      =>  'RESTARTED'
				,p_details     =>  'File Name: '  || rec_je_process.reference24
					);
		-------------------------------------------
		-- Delete previous records from error table
		-------------------------------------------
		BEGIN
			lc_debug_msg  := '    Deleting previous error records';
			print_debug_msg  (lc_debug_msg,p_force=> true);
			logit(p_message =>lc_debug_msg);
			DELETE FROM XX_GL_INTERFACE_NA_ERROR
			WHERE   group_id = rec_je_process.group_id;
			COMMIT;
		EXCEPTION
			WHEN OTHERS
			THEN
			fnd_message.clear();
			fnd_message.set_name('FND','FS-UNKNOWN');
			fnd_message.set_token('ERROR',SQLERRM);
			fnd_message.set_token('ROUTINE',lc_debug_msg);
		END;

		---------------------------------------------
		-- Update previous records from staging table
		---------------------------------------------
		BEGIN
			UPDATE XX_GL_INTERFACE_NA_STG
			SET DERIVED_VAL = 'INVALID'
				,BALANCED    = 'UNBALANCED'
			WHERE  group_id = rec_je_process.group_id;
			COMMIT;
		    lc_debug_msg  := '    updated previous error flags'||' on staging table ';
			print_debug_msg  (lc_debug_msg,p_force=> true);
			logit(p_message =>lc_debug_msg);

		EXCEPTION
			WHEN OTHERS THEN
			fnd_message.clear();
		    fnd_message.set_name('FND','FS-UNKNOWN');
		    fnd_message.set_token('ERROR',SQLERRM);
			fnd_message.set_token('ROUTINE',lc_debug_msg);
			lc_debug_msg := fnd_message.get();
			print_debug_msg  (lc_debug_msg,p_force=> true);
			FND_FILE.PUT_LINE(FND_FILE.LOG, lc_debug_msg );
		END;


	END IF;
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling VALIDATE_CURRENCY Procedure' , p_force => true);

  VALIDATE_CURRENCY( p_group_id => rec_je_process.group_id,p_errbuf=>x_err_buf,p_retcode=>x_ret_code) ;

  if x_err_buf is not null then
  print_debug_msg(P_MESSAGE => 'VALIDATE_CURRENCY, p_errbuf-' ||x_err_buf ||' ,p_retcode-'||x_ret_code, p_force => TRUE);
  end if;

  if x_ret_code <>0 then
   print_debug_msg(P_MESSAGE => 'VALIDATE_CURRENCY, Currency is not valid. ', p_force => TRUE);
   retcode:=1;
  end if;

  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling BALANCE_JOURNALS Procedure' , p_force => true);

  BALANCE_JOURNALS ( p_group_id => rec_je_process.group_id,p_errbuf=>x_err_buf,p_retcode=>x_ret_code);
  if x_err_buf is not null then
  print_debug_msg(P_MESSAGE => 'BALANCE_JOURNALS, p_errbuf-' ||x_err_buf ||' ,p_retcode-'||x_ret_code, p_force => TRUE);
  end if;

  if x_ret_code <>0 then
   print_debug_msg(P_MESSAGE => 'BALANCE_JOURNALS, Error while balancing journals. ', p_force => TRUE);
   retcode:=1;
  end if;

  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling DERIVE_CCID Procedure' , p_force => true);
  DERIVE_CCID( p_group_id => rec_je_process.group_id,p_errbuf=>x_err_buf,p_retcode=>x_ret_code) ;

  if x_err_buf is not null then
  print_debug_msg(P_MESSAGE => 'DERIVE_CCID, p_errbuf-' ||x_err_buf ||' ,p_retcode-'||x_ret_code, p_force => TRUE);
  end if;

  if x_ret_code <>0 then
   print_debug_msg(P_MESSAGE => 'DERIVE_CCID, CCID is not valid.', p_force => TRUE);
   retcode:=1;
  end if;

  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling   XX_GL_INTERFACE_PKG.PROCESS_JRNL_LINES Procedure' , p_force => true);

  ---------------------------------
  -- Create output file header info
  ---------------------------------

  XX_GL_INTERFACE_PKG.CREATE_OUTPUT_FILE(p_cntrl_flag   =>'HEADER',p_source_name  => gc_journal_source_name);

  ----------------------------
  --  PROCESS JOURNAL LINES
  ----------------------------
  XX_GL_INTERFACE_PKG.PROCESS_JRNL_LINES
								(p_grp_id       => rec_je_process.group_id
                                ,p_source_nm    => rec_je_process.user_je_source_name
                                ,p_file_name    => rec_je_process.reference24
                                ,p_err_cnt      => gn_error_count
                                ,p_debug_flag   => p_debug_flag
                                ,p_chk_bal_flg  => 'N'
                                ,p_chk_sob_flg  => 'N'
                                ,p_summary_flag => 'N'
                                ,p_bypass_flg   => 'Y'
                                );

    ln_error_count :=  ln_error_count + gn_error_count;
	lc_debug_msg   := 'Emailing output report: gn_request_id=> '
                    ||gn_request_id || ' gc_source_name=> ' ||rec_je_process.user_je_source_name
                    || ' lc_mail_subject=> ' || lc_mail_subject;
	 print_debug_msg (lc_debug_msg);
 END LOOP;

    lc_debug_msg := '!!!!!Total number of all errors: ' || ln_error_count;

    IF  ln_error_count <> 0 THEN
        lc_mail_subject := 'ERRORS: Found in '|| gc_journal_source_name|| ' GL Import!';
		print_debug_msg(P_MESSAGE => 'Error during GL Import', p_force => TRUE);
		retcode:=1;
    ELSE
            lc_mail_subject := gc_journal_source_name ||' Import completed!';
    END IF;


    ln_conc_id := fnd_request.submit_request( application => 'XXFIN'
											 ,program     => 'XXGLINTERFACEEMAIL'
											 ,description => NULL
											 ,start_time  => SYSDATE
											 ,sub_request => FALSE
											 ,argument1   => gn_request_id
											 ,argument2   => gc_journal_source_name
											 ,argument3   => lc_mail_subject
                                             );
    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => FALSE);
EXCEPTION
WHEN OTHERS THEN
  logit(p_message => 'ERROR-SQLCODE:'|| SQLCODE || ' SQLERRM: ' || SQLERRM, p_force => TRUE);
  logit(p_message => 'ERROR  Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM, p_force => TRUE);
  retcode := 2;
  errbuff := 'Error encountered. Please check logs';
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  logit(p_message => 'Backtrace => '||dbms_utility.format_error_backtrace);
END MAIN_PROCESS;


END XX_GL_IMS_IFACE_PKG;
/
SHOW ERROR;