SET VERIFY OFF
SET ECHO OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating PACKAGE  BODY XX_GL_MTHCAL_RATE_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_GL_MTHCAL_RATE_PKG
AS
	  -- +============================================================================================|
	  -- |  Office Depot                                                                              |
	  -- +============================================================================================|
	  -- |  Name:  XX_GL_MTHCAL_RATE_PKG                                                              |
	  -- |                                                                                            |
	  -- |  Description: This package body is to creates rates for CC Period End/Average and send     |
	  -- |               rates to ERP Financial Cloud and EPM Cloud for FISCAL and CALENDAR Month     |
	  -- |  RICE ID   :  I2122_Exchange Rates                                                         |
	  -- |                                                                                            |
	  -- |  Change Record:                                                                            |
	  -- +============================================================================================|
	  -- | Version     Date         Author               Remarks                                      |
	  -- | =========   ===========  =============        =============================================|
	  -- | 1.0         01/20/2019   Paddy Sanjeevi       Initial version                              |
	  -- | 1.1         02/04/2019   M K Pramod Kumar     Code Changes to generate Files               |
	  -- | 1.2         03/12/2019   Paddy Sanjeevi       Modified to add CC Averate and Month End     |
	  -- +============================================================================================+
	  lc_Saturday        VARCHAR2(1)   := TO_CHAR(to_date('20000101','RRRRMMDD'),'D');
	  lc_Sunday          VARCHAR2(1)   := TO_CHAR(to_date('20000102','RRRRMMDD'),'D');
	  gc_file_path       VARCHAR2(500) := 'XXFIN_OUTBOUND';

	  lc_source_dir_path VARCHAR2(200);
	  gb_debug             BOOLEAN                               := TRUE;
	  gc_max_log_size      CONSTANT NUMBER                       := 2000;

	  gc_retcode Number;
	  gc_errbuf varchar2(2000);

	  -- +===================================================================+
	  -- | Name :  SUBMIT_CONCURRENT                                         |
	  -- | Description : Submits the standard concurrent program             |
	  -- |               to load the daily rates into GL_DAILY_RATES         |
	  -- | Returns :  Number                                                 |
	  -- +===================================================================+

	/*********************************************************************
	* Procedure used to log based on gb_debug value or if p_force is TRUE.
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
	  IF (gb_debug OR p_force) THEN
		lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF') || ' => ' || p_message, 1, gc_max_log_size);
		IF (fnd_global.conc_request_id > 0) THEN
		  fnd_file.put_line(fnd_file.LOG, lc_message);
		ELSE
		  DBMS_OUTPUT.put_line(lc_message);
		END IF;
	  END IF;
	EXCEPTION
	WHEN OTHERS THEN
	  NULL;
	END logit;
	/**********************************************************************************
	* Function to trigger General Ledger Daily Rates Import and Calculation Concurrent Program.
	* This procedure is called by xx_calendar_extract.
	***********************************************************************************/
	FUNCTION SUBMIT_GLDRICCP
	  RETURN NUMBER
	AS
	  lc_phase        VARCHAR2(50);
	  lc_status       VARCHAR2(50);
	  lc_devphase     VARCHAR2(50);
	  lc_devstatus    VARCHAR2(50);
	  lc_message      VARCHAR2(250);
	  lb_req_status   BOOLEAN;
	  ln_user_id      NUMBER := NVL(fnd_global.user_id,-1);
	  ln_resp_id      NUMBER := NVL(fnd_global.resp_id,20434);
	  ln_resp_appl_id NUMBER := NVL(fnd_global.resp_appl_id,101);
	  ln_request_id fnd_concurrent_requests.request_id%TYPE;
	BEGIN
	  FND_GLOBAL.APPS_INITIALIZE (ln_user_id, ln_resp_id, ln_resp_appl_id);
	  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(application => 'SQLGL' ,program => 'GLDRICCP' ,description => 'General Ledger Daily Rates Import and Calculation Concurrent Program' ,start_time => NULL ,sub_request => FALSE);
	  COMMIT;
	  IF ln_request_id = 0 THEN
		logit(p_message => 'Error : Unable to submit Standard Daily Rates Import and Calculation Program ', p_force => TRUE);

	  ELSE

		logit(p_message => 'Submitted request '|| TO_CHAR (ln_request_id)||' for Daily Rates Import', p_force => TRUE);	

		lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST (request_id => ln_request_id ,interval => '10' ,max_wait => '' ,phase => lc_phase ,status => lc_status ,dev_phase => lc_devphase ,dev_status => lc_devstatus ,MESSAGE => lc_message);
		IF lc_devstatus='NORMAL' AND lc_devphase='COMPLETE' THEN

		  logit(p_message =>' Daily Rates Import and Calculation Program completed normally', p_force => TRUE);
		  RETURN 0;
		ELSIF lc_devstatus='WARNING' AND lc_devphase='COMPLETE' THEN

		  logit(p_message =>' Daily Rates Import and Calculation Program completed with Warning', p_force => TRUE);
		  RETURN 1;
		ELSIF lc_devstatus='ERROR' AND lc_devphase='COMPLETE' THEN

		  logit(p_message =>' Daily Rates Import and Calculation Program completed with Error', p_force => TRUE);
		  RETURN 2;
		END IF;
	  END IF;
	EXCEPTION
	WHEN OTHERS THEN
	   logit(p_message =>'When Others Exception Raised in SUBMIT_GLDRICCP Function that calls the Daily Rates Standard Program' || SQLERRM, p_force => TRUE);
	END SUBMIT_GLDRICCP;

/**********************************************************************************
	* Procedure to Archive the File extracted
	* This procedure is called by xx_daily_extract, xx_calendar_extract,xx_fiscal_extract procedure
***********************************************************************************/

PROCEDURE xx_archive_file(p_request_type IN VARCHAR2, p_file IN VARCHAR2)
IS
	  lc_dest_file_name   VARCHAR2(200);
	  lc_source_file_name VARCHAR2(200);
	  lc_source_dir_path  VARCHAR2(4000);
	  lc_target_dir_path  VARCHAR2(4000);
	  lb_complete         BOOLEAN;
	  lc_phase            VARCHAR2(100);
	  lc_status           VARCHAR2(100);
	  lc_dev_phase        VARCHAR2(100);
	  lc_dev_status       VARCHAR2(100);
	  lc_message          VARCHAR2(100);
	  ln_request_id       NUMBER;
BEGIN
  BEGIN
	SELECT directory_path
	  INTO lc_target_dir_path
	  FROM dba_directories
	 WHERE directory_name = 'XXFIN_OUTBOUND_ARCH';
  EXCEPTION
	WHEN OTHERS THEN    
	  logit(p_message =>'Exception raised while getting Archive directory path '|| SQLERRM, p_force => TRUE);
  END;
  BEGIN
	SELECT directory_path
  	  INTO lc_source_dir_path
	  FROM dba_directories
	 WHERE directory_name = 'XXFIN_OUT';
  EXCEPTION
    WHEN OTHERS THEN
 	  logit(p_message =>'Exception raised while getting Source directory path '|| SQLERRM, p_force => TRUE);
  END;
  IF p_request_type<>'DAILY' THEN
	 lc_source_file_name := lc_source_dir_path||'/hyperion/'||p_file;
  	 lc_dest_file_name   := lc_target_dir_path||'/'||p_file;
  ELSE
	 lc_source_file_name := lc_source_dir_path||'/rates/'||p_file||'.zip';
  	 lc_dest_file_name   := lc_target_dir_path||'/'||p_file ||'.zip';
  END IF;
  ln_request_id       := fnd_request.submit_request('XXFIN', 'XXCOMFILCOPY', '', '', FALSE, lc_source_file_name, lc_dest_file_name, '', '', 'N' );
  IF ln_request_id     > 0 THEN
  	 COMMIT;
	 logit(p_message => 'Submitted request '|| TO_CHAR (ln_request_id)||' to Archive File Generated', p_force => TRUE);	

	 lb_complete := fnd_concurrent.wait_for_request(request_id => ln_request_id,
												    interval => 10, 
													max_wait => 0, 
													phase => lc_phase, 
													status => lc_status, 
													dev_phase => lc_dev_phase, 
													dev_status => lc_dev_status, 
													MESSAGE => lc_message
												   );
  END IF;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
	logit(p_message =>'When Others Exception Raised in xx_archive_file procedure that Archives the Exchange Rates File' || SQLERRM, p_force => TRUE);
END xx_archive_file;



/**********************************************************************************
	* Procedure to File Copy 
	* This procedure is called by xx_daily_extract, xx_calendar_extract,xx_fiscal_extract procedure
***********************************************************************************/
PROCEDURE xx_file_copy(p_request_type IN VARCHAR2, p_copy_file IN VARCHAR2)
IS
	  lc_dest_file_name   VARCHAR2(200);
	  lc_source_file_name VARCHAR2(200);
	  lc_source_dir_path  VARCHAR2(4000);
	  lc_instance_name    VARCHAR2(30);
	  lb_complete         BOOLEAN;
	  lc_phase            VARCHAR2(100);
	  lc_status           VARCHAR2(100);
	  lc_dev_phase        VARCHAR2(100);
	  lc_dev_status       VARCHAR2(100);
	  lc_message          VARCHAR2(100);
	  ln_request_id       NUMBER;
BEGIN
  SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV', 'INSTANCE_NAME') ), 1, 8)
    INTO lc_instance_name
	FROM DUAL;
  BEGIN
	SELECT directory_path
	  INTO lc_source_dir_path
	  FROM dba_directories
	 WHERE directory_name = gc_file_path;
  EXCEPTION
    WHEN OTHERS THEN
	  logit(p_message =>'Exception raised while getting directory path '|| SQLERRM, p_force => TRUE);
  END;
  lc_source_file_name := lc_source_dir_path||'/'||p_copy_file;
  IF p_request_type<>'DAILY' THEN
     lc_dest_file_name   := '/app/ebs/ct' || lc_instance_name || '/xxfin/ftp/out/hyperion/' || p_copy_file;
  ELSE
     lc_dest_file_name   := '/app/ebs/ct' || lc_instance_name || '/xxfin/ftp/out/rates/ratex/' || p_copy_file;
  END IF;
  ln_request_id       := fnd_request.submit_request('XXFIN', 'XXCOMFILCOPY', '', '', FALSE, lc_source_file_name, lc_dest_file_name, '', '', 'N' );
  IF ln_request_id     > 0 THEN
  	 COMMIT;
	 logit(p_message => 'Submitted request '|| TO_CHAR (ln_request_id)||' to Copy File Generated', p_force => TRUE);	
	 lb_complete := fnd_concurrent.wait_for_request(request_id => ln_request_id, 
													interval => 10, 
													max_wait => 0, 
													phase => lc_phase, 
													status => lc_status, 
													dev_phase => lc_dev_phase, 
													dev_status => lc_dev_status, 
													MESSAGE => lc_message
												   );
  END IF;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    logit(p_message =>'When Others Exception Raised in xx_file_copy procedure that Copy the Exchange Rates File' || SQLERRM, p_force => TRUE);
END xx_file_copy;

/**********************************************************************************
	* Procedure to Zip the file
	* This procedure is called by xx_daily_extract, xx_calendar_extract,xx_fiscal_extract procedure
***********************************************************************************/
PROCEDURE zip_file(p_file varchar2)
IS
	  ln_request_id          NUMBER;
	  lc_zip_destination_dir VARCHAR2(4000);
	  lc_source_file_name    VARCHAR2(200);
	  lc_instance_name       VARCHAR2(30);
	  lc_source_dir_path     VARCHAR2(4000);
	  lb_complete            BOOLEAN;
	  lc_phase               VARCHAR2(100);
	  lc_status              VARCHAR2(100);
	  lc_dev_phase           VARCHAR2(100);
	  lc_dev_status          VARCHAR2(100);
	  lc_message             VARCHAR2(100);
 	  lc_file                VARCHAR2(100):=p_file;
BEGIN
  SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV', 'INSTANCE_NAME') ), 1, 8)
    INTO lc_instance_name
    FROM DUAL;
	  
  lc_source_file_name    :='/app/ebs/ct' || lc_instance_name || '/xxfin/ftp/out/rates/ratex/';
  lc_zip_destination_dir :='$XXFIN_DATA/ftp/out/rates';
  ln_request_id          :=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXODDIRZIP' ,'' ,'' ,FALSE, lc_source_file_name ,lc_zip_destination_dir||'/'||lc_file );
  IF ln_request_id        > 0 THEN
	 COMMIT;
	 logit(p_message => 'Submitted request '|| TO_CHAR (ln_request_id)||' to Zip the File', p_force => TRUE);	
	 lb_complete := fnd_concurrent.wait_for_request(request_id => ln_request_id, 
												   interval => 10, 
												   max_wait => 0,
												   phase => lc_phase, 
												   status => lc_status, 
												   dev_phase => lc_dev_phase, 
												   dev_status => lc_dev_status, 
												   MESSAGE => lc_message
												  );
  END IF;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
	logit(p_message =>'When Others Exception Raised in zip_file procedure that Zip the Generated File' || SQLERRM, p_force => TRUE);
END zip_file;

/**********************************************************************************
	* Procedure to generate Daily Exchange Rates File
	* This procedure is called by Extract_rates
***********************************************************************************/

PROCEDURE xx_daily_extract(p_request_type IN VARCHAR2,p_date IN Date)
IS

l_data 				VARCHAR2(4000);
ln_buffer 			BINARY_INTEGER := 32767;
l_filehandle 		utl_file.file_type;
lc_file_name1       VARCHAR2(100) :='GlDailyRates_';
lc_file_name       	VARCHAR2(100) ;
lc_filename_part1 	VARCHAR2(10);
lc_filename_part2 	VARCHAR2(10):='.txt';

BEGIN
  SELECT TO_CHAR(p_date,'YYYYMMDD') INTO lc_filename_part1 FROM dual;
  lc_file_name:=lc_file_name1||lc_filename_part1||lc_filename_part2;
  l_filehandle := UTL_FILE.fopen(gc_file_path,lc_file_name ,'w',ln_buffer);
  FOR r IN
	  (SELECT b.from_currency,
			  b.to_currency,
			  TO_CHAR(b.conversion_date,'YYYY/MM/DD') conversion_date,
			  DECODE(a.user_conversion_type,'Ending Rate','Corporate',a.user_conversion_type) conversion_type,
			  TO_CHAR(ROUND(b.conversion_rate,6)) conversion_rate
	     FROM gl_daily_rates b,
			  gl_daily_conversion_types a
	    WHERE a.user_conversion_type IN ('Ending Rate','CC Period End','CC Period Average')
		  AND b.conversion_type=a.conversion_type
		  AND b.conversion_date=TRUNC(p_date)
	      AND b.from_currency    ='USD'
		  AND b.to_currency<>'LTL'
	    ORDER BY 4,2
	  )
  LOOP
	l_data:=r.from_currency||','||r.to_currency||','||r.conversion_date||','||r.conversion_date||','|| r.conversion_type||','||r.conversion_rate;
	UTL_FILE.PUT_LINE(l_filehandle,l_data);
  END LOOP;
  UTL_FILE.fclose(l_filehandle);
  xx_file_copy(p_request_type,lc_file_name);
  zip_file(lc_file_name1||lc_filename_part1);
  xx_archive_file(p_request_type,lc_file_name1||lc_filename_part1);
EXCEPTION
  WHEN utl_file.invalid_operation THEN
	utl_file.fclose(l_filehandle);
	logit(p_message =>'UTL File Error: Invalid Operation.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Invalid Operation.';
  WHEN utl_file.invalid_filehandle THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Invalid File Handle.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Invalid File Handle.';
  WHEN utl_file.read_error THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Read Error.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Read Error.';
  WHEN utl_file.invalid_path THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error:  Invalid Path.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error:  Invalid Path.';
  WHEN utl_file.invalid_mode THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Invalid Mode.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Invalid Mode.';
  WHEN utl_file.internal_error THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Internal Error.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Internal Error.';
  WHEN value_error THEN
	utl_file.fclose(l_filehandle);
    logit(p_message =>'UTL File Error: Value Error:'||SUBSTR(sqlerrm,1,250), p_force => TRUE);
    gc_retcode:= 1;
    gc_errbuf:='UTL File Error: Value Error:'||SUBSTR(sqlerrm,1,250);
  WHEN OTHERS THEN
	utl_file.fclose(l_filehandle);
	logit(p_message =>'UTL File Error:'||SUBSTR(sqlerrm,1,250), p_force => TRUE);
    gc_retcode:= 1;
    gc_errbuf:='UTL File Error:'||SUBSTR(sqlerrm,1,250);
END xx_daily_extract;

/**********************************************************************************
	* Procedure to generate Fiscal Exchange Rates File
	* This procedure is called by Extract_rates
***********************************************************************************/

PROCEDURE xx_fiscal_extract(p_request_type IN VARCHAR2,p_date IN DATE)
IS

l_data 			VARCHAR2(4000);
ln_buffer 		BINARY_INTEGER := 32767;
l_filehandle 	utl_file.file_type;

CURSOR cr_fiscal_rates(p_conversion_date DATE)
IS
SELECT from_currency||'4' from_currency ,
	   to_currency,
	   DECODE(conversion_type,'1001','Ending','1000','Average') ratetype,
	   TO_CHAR(ROUND(conversion_rate,6)) conversion_rate,
	   conversion_date
  FROM gl_daily_rates
 WHERE conversion_date  =TRUNC(p_conversion_date)
   AND conversion_type   IN ('1000','1001')
   AND to_currency        ='USD'
   AND from_currency<>'USD'
 ORDER BY from_currency,ratetype;
	  
lc_delimeter VARCHAR2(1):='|';
lc_file_name1       VARCHAR2(100) :='ODPEBSFX_FX445_';
lc_file_name        VARCHAR2(100) ;
lc_filename_part1   VARCHAR2(10);
lc_filename_part2   VARCHAR2(10);

BEGIN
  SELECT TO_CHAR(p_date,'Mon') INTO lc_filename_part1 FROM dual;
  SELECT TO_CHAR(p_date,'RR') INTO lc_filename_part2 FROM dual;
  lc_file_name:=lc_file_name1||lc_filename_part1||'_'||lc_filename_part1||'_'||lc_filename_part2||'.txt';
  logit(lc_file_name);
  l_filehandle := UTL_FILE.fopen(gc_file_path,lc_file_name ,'w',ln_buffer);

  FOR rec IN cr_fiscal_rates(p_date)
  LOOP
	l_data:=rec.from_currency||lc_delimeter||rec.to_currency||lc_delimeter||rec.ratetype||lc_delimeter||rec.conversion_rate;
    UTL_FILE.PUT_LINE(l_filehandle,l_data);
  END LOOP;
  UTL_FILE.fclose(l_filehandle);
  xx_file_copy(p_request_type,lc_file_name);
  xx_archive_file(p_request_type,lc_file_name);
EXCEPTION
  WHEN utl_file.invalid_operation THEN
	utl_file.fclose(l_filehandle);
	logit(p_message =>'UTL File Error: Invalid Operation.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Invalid Operation.';
  WHEN utl_file.invalid_filehandle THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Invalid File Handle.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Invalid File Handle.';
  WHEN utl_file.read_error THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Read Error.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Read Error.';
  WHEN utl_file.invalid_path THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error:  Invalid Path.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error:  Invalid Path.';
  WHEN utl_file.invalid_mode THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Invalid Mode.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Invalid Mode.';
  WHEN utl_file.internal_error THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Internal Error.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Internal Error.';
  WHEN value_error THEN
	utl_file.fclose(l_filehandle);
    logit(p_message =>'UTL File Error: Value Error:'||SUBSTR(sqlerrm,1,250), p_force => TRUE);
    gc_retcode:= 1;
    gc_errbuf:='UTL File Error: Value Error:'||SUBSTR(sqlerrm,1,250);
  WHEN OTHERS THEN
	utl_file.fclose(l_filehandle);
	logit(p_message =>'UTL File Error:'||SUBSTR(sqlerrm,1,250), p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error:'||SUBSTR(sqlerrm,1,250);
END xx_fiscal_extract;

-- +====================================================================+
-- | Name : xx_calendar_extract                                         |
-- | Description : The Procedure generates Calendar Rates               |
-- | Parameters :  x_error_buff, x_ret_code,p_rundate                   |
-- +====================================================================+
	
PROCEDURE xx_calendar_extract(p_request_type IN VARCHAR2,p_date IN DATE)
IS

l_data 				VARCHAR2(4000);
ln_buffer 			BINARY_INTEGER := 32767;
ld_from_date		DATE;
ld_to_date			DATE;
l_filehandle utl_file.file_type;
lc_file_name       VARCHAR2(100) ;
lc_filename_part1 varchar2(10);
lc_filename_part2 varchar2(10);
lc_file_name1       VARCHAR2(100) :='ODPEBSFX_FX_';

CURSOR cr_calendar_avg_rates(p_from_conversion_date DATE,p_to_conversion_date DATE)
IS
SELECT from_currency ,
	   to_currency ,
	   p_to_conversion_date from_conversion_date ,
	   p_to_conversion_date to_conversion_date ,
	   'CC Period Average' user_conversion_type ,
	   ROUND(SUM(conversion_rate)/COUNT(1),6) conversion_rate ,
	   ROUND(1/ROUND(SUM(conversion_rate)/COUNT(1),6),6) inverse_conversion_rate ,
	   'I' mode_flag
  FROM GL_DAILY_RATES 
 WHERE conversion_date BETWEEN p_from_conversion_date AND p_to_conversion_date
   AND conversion_type                   = '1001'
   AND from_currency                    <> 'USD'
   AND to_currency                       = 'USD'
   AND TO_CHAR(conversion_date,'D') NOT IN (lc_Saturday,lc_Sunday)
 GROUP BY from_currency,to_currency;

CURSOR cr_calendar_end_rates(p_conversion_date DATE)
IS
SELECT from_currency ,
	   to_currency ,
	   p_conversion_date from_conversion_date ,
	   p_conversion_date to_conversion_date ,
	   'CC Period End' user_conversion_type ,
	   conversion_rate,
	   ROUND(1/conversion_rate,6) inverse_conversion_rate ,
	   'I' mode_flag
  FROM GL_DAILY_RATES
 WHERE conversion_date  =p_conversion_date
   AND conversion_type    = '1001'
   AND from_currency     <> 'USD'
   AND to_currency        = 'USD';

CURSOR cr_calendar_rates(p_conversion_date DATE)
IS
SELECT * 
 FROM ( SELECT from_currency from_currency ,
		       to_currency,
		  	   (SELECT DECODE(user_conversion_type,'CC Period End','Ending','CC Period Average','Average') 
				  FROM gl_daily_conversion_types 
				 WHERE conversion_type=gdr.conversion_type
			   ) ratetype,
 	 	       conversion_rate,
		       conversion_date
	 	  FROM gl_daily_rates gdr
		 WHERE conversion_date =p_conversion_date
		   AND conversion_type IN (SELECT conversion_type 
								     FROM gl_daily_conversion_types 
									WHERE user_conversion_type IN ('CC Period End','CC Period Average')
								  )
		   AND to_currency        ='USD'
		UNION
		SELECT from_currency||'2'|| from_currency,
			   to_currency,
		 	   (SELECT DECODE(user_conversion_type,'CC Period End','Ending','CC Period Average','Average') 
			      FROM gl_daily_conversion_types 
				 WHERE conversion_type=gdr.conversion_type
			   ) ratetype,
		       conversion_rate,
		       conversion_date
		  FROM gl_daily_rates gdr
	 	 WHERE conversion_date  =p_conversion_date
		   AND conversion_type   IN  (SELECT conversion_type 
									    FROM gl_daily_conversion_types 
									   WHERE user_conversion_type IN ('CC Period End','CC Period Average')
									 )
		   AND to_currency        ='USD'
		   and from_currency='CAD')
  ORDER BY from_currency,ratetype;

lc_delimeter      VARCHAR2(1):='|';
ln_status         NUMBER;
EX_USER_EXCEPTION EXCEPTION;
BEGIN

  SELECT LAST_DAY(ADD_MONTHS(p_date,-1))+1 
    INTO ld_from_date
	FROM DUAL;

  SELECT LAST_DAY(p_date) 
    INTO ld_to_date  
	FROM DUAL;
	
  FOR rec IN cr_calendar_avg_rates(ld_from_date,ld_to_date) LOOP
    BEGIN
	  INSERT
		INTO GL_DAILY_RATES_INTERFACE
		  (
			from_currency ,
			to_currency ,
			from_conversion_date ,
			to_conversion_date ,
			user_conversion_type ,
			conversion_rate ,
			inverse_conversion_rate ,
			mode_flag ,
			user_id
		  )
		  VALUES
		  (
			rec.from_currency ,
			rec.to_currency ,
			rec.from_conversion_date ,
			rec.to_conversion_date ,
			rec.user_conversion_type ,
			rec.conversion_rate ,
			rec.inverse_conversion_rate ,
			rec.mode_flag ,
			NVL(fnd_global.user_id,-1)
		  );
    EXCEPTION
      WHEN others THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Inserting to GL Rates Interface for Avg :' ||SQLERRM);
    END;	  
  END LOOP;
  COMMIT;

  BEGIN
	FND_FILE.PUT_LINE (FND_FILE.LOG,'Submitting the request for standard daily rates import and calculation program for CC Period End rates');
	ln_status  := SUBMIT_GLDRICCP;
	IF ln_status=0 THEN
  	   FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily Calendar rates completed with normal status ');
	ELSIF ln_status=1 THEN
	   FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily Calendar rates completed with warning status ');
	   RAISE EX_USER_EXCEPTION;
	ELSIF ln_status=2 THEN
 	   FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily Calendar rates completed with error status ');
	   RAISE EX_USER_EXCEPTION;
	END IF;
  EXCEPTION
	WHEN EX_USER_EXCEPTION THEN
		gc_retcode := ln_status;
		RETURN;
    WHEN OTHERS THEN
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while submitting standard concurrent program: ' || SQLERRM);
		gc_retcode := 2;
		RETURN;
  END;
	  
  FOR rec IN cr_calendar_end_rates(ld_to_date) LOOP
	BEGIN
	  INSERT
		INTO GL_DAILY_RATES_INTERFACE
		  (
			from_currency ,
			to_currency ,
			from_conversion_date ,
			to_conversion_date ,
			user_conversion_type ,
			conversion_rate ,
			inverse_conversion_rate ,
			mode_flag ,
			user_id
		  )
		  VALUES
		  (
			rec.from_currency ,
			rec.to_currency ,
			rec.from_conversion_date ,
			rec.to_conversion_date ,
			rec.user_conversion_type ,
			rec.conversion_rate ,
			rec.inverse_conversion_rate ,
			rec.mode_flag ,
			NVL(fnd_global.user_id,-1)
		  );
    EXCEPTION
      WHEN others THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Inserting to GL Rates Interface for Ending Rate :' ||SQLERRM);
    END;	  		  
  END LOOP;
  COMMIT;

  BEGIN
	FND_FILE.PUT_LINE (FND_FILE.LOG,'Submitting the request for standard daily rates import and calculation program for CC Period End rates');
	ln_status  := SUBMIT_GLDRICCP;
	IF ln_status=0 THEN
  	   FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily Calendar rates completed with normal status ');
	ELSIF ln_status=1 THEN
  	   FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily Calendar rates completed with warning status ');
	   RAISE EX_USER_EXCEPTION;
	ELSIF ln_status=2 THEN
 	   FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily Calendar rates completed with error status ');
	   RAISE EX_USER_EXCEPTION;
	END IF;
  EXCEPTION
    WHEN EX_USER_EXCEPTION THEN
	  gc_retcode := ln_status;
	  RETURN;
	WHEN OTHERS THEN
	  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while submitting standard concurrent program: ' || SQLERRM);
	  gc_retcode := 2;
	  RETURN;
  END;

  SELECT TO_CHAR(ld_to_date,'Mon') INTO lc_filename_part1 FROM DUAL;
  SELECT TO_CHAR(ld_to_date,'RR') INTO lc_filename_part2 FROM DUAL;
  lc_file_name:=lc_file_name1||lc_filename_part1||'_'||lc_filename_part1||'_'||lc_filename_part2||'.txt';

   l_filehandle := UTL_FILE.fopen(gc_file_path,lc_file_name ,'w',ln_buffer);
   FOR rec IN cr_calendar_rates(ld_to_date)
   LOOP
	 l_data:=rec.from_currency||lc_delimeter||rec.to_currency||lc_delimeter||rec.ratetype||lc_delimeter||rec.conversion_rate;
	 UTL_FILE.PUT_LINE(l_filehandle,l_data);
   END LOOP;
   UTL_FILE.fclose(l_filehandle);
   xx_file_copy(p_request_type,lc_file_name);
   xx_archive_file(p_request_type,lc_file_name);
   
EXCEPTION
  WHEN utl_file.invalid_operation THEN
	utl_file.fclose(l_filehandle);
	logit(p_message =>'UTL File Error: Invalid Operation.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Invalid Operation.';
  WHEN utl_file.invalid_filehandle THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Invalid File Handle.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Invalid File Handle.';
  WHEN utl_file.read_error THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Read Error.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Read Error.';
  WHEN utl_file.invalid_path THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error:  Invalid Path.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error:  Invalid Path.';
  WHEN utl_file.invalid_mode THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Invalid Mode.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Invalid Mode.';
  WHEN utl_file.internal_error THEN
	utl_file.fclose(l_filehandle);  
	logit(p_message =>'UTL File Error: Internal Error.', p_force => TRUE);
	gc_retcode:= 1;
	gc_errbuf:='UTL File Error: Internal Error.';
  WHEN value_error THEN
	utl_file.fclose(l_filehandle);
    logit(p_message =>'UTL File Error: Value Error:'||SUBSTR(sqlerrm,1,250), p_force => TRUE);
    gc_retcode:= 1;
    gc_errbuf:='UTL File Error: Value Error:'||SUBSTR(sqlerrm,1,250);
  WHEN OTHERS THEN
	utl_file.fclose(l_filehandle);
	logit(p_message =>'UTL File Error:'||SUBSTR(sqlerrm,1,250), p_force => TRUE);
    gc_retcode:= 1;
    gc_errbuf:='UTL File Error:'||SUBSTR(sqlerrm,1,250);
END xx_calendar_extract;

/**********************************************************************
	* Main Procedure to Generate Daily, Fiscal and Calendar Rates.
	* this procedure calls individual procedures to process them.
***********************************************************************/
PROCEDURE Extract_rates
	  (
		p_errbuf OUT VARCHAR2,
		p_retcode OUT NUMBER,
		p_request_type IN VARCHAR2,
		p_date IN VARCHAR2
	  )
IS

v_errbuf  VARCHAR2(2000);
v_retcode NUMBER;

BEGIN

  /******************************
  * Call Daily Exchange Rates  Process.
  ******************************/
  logit(p_date,True);
  logit(to_date(p_date,'MM-DD-YYYY'),True);
  logit(to_char(to_date(p_date,'MM-DD-YYYY'),'YYYYMMDD'),True);

  IF p_request_type='DAILY' THEN
  	 xx_daily_extract(p_request_type,to_date(p_date,'MM-DD-YYYY'));

	 /******************************
	 * Call Fiscal Exchange Rates  Process.
	 ******************************/
  ELSIF p_request_type='FISCAL' THEN
 	 FND_FILE.PUT_LINE(FND_FILE.LOG,'Fiscal Extract');
 	 xx_fiscal_extract(p_request_type,to_date(p_date,'MM-DD-YYYY'));

	 /******************************
     * Call Calendar Exchange Rates  Process.
	 ******************************/
  ELSIF p_request_type='CALENDAR' THEN
 	 FND_FILE.PUT_LINE(FND_FILE.LOG,'Calendar Extract');
	 xx_calendar_extract(p_request_type,to_date(p_date,'MM-DD-YYYY'));
  END IF;

EXCEPTION
  WHEN OTHERS THEN
	logit(p_message => 'ERROR-SQLCODE:'|| SQLCODE || ' SQLERRM: ' || SQLERRM, p_force => TRUE);
	gc_retcode := 2;
	p_errbuf := 'Error encountered. Please check logs.';
END Extract_rates;
END XX_GL_MTHCAL_RATE_PKG;
/
SHOW ERRORS;
