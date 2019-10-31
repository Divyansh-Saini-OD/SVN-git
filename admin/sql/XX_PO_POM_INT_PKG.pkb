create or replace PACKAGE BODY XX_PO_POM_INT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_PO_POM_INT_PKG                                                            	  |
  -- |  RICE ID   :  I2193_PO to EBS Interface                                   				  |
  -- |  Description:  Load PO Interface Data from file to Staging Tables                          |
  -- |                                                                          				  |
  -- |                          																  |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         04/10/2017   Avinash Baddam   Initial version                                  |
  -- |            07/14 update terms															  |
  -- | 1.1         10/03/2017   Suresh Ponnambalam Added po line procedure                        |
  -- | 1.2         01/08/2018   Havish Kasina      Modified the add_po_line procedure             |
  -- | 1.3         04/18/2018   Madhu Bolli        add_po_line : max line number should start from 9001|
  -- |											   NAIT-37481 and corrected receipt required flag |
  -- | 1.4         04/20/2018   Madhu Bolli        Skip CLOSE_API if line already closed.         |
  -- | 1.5         01/24/2019   BIAS               INSTANCE_NAME is replaced with DB_NAME for OCI   |
  -- |                                             Migration Project
  -- | 1.6         10/23/2019 Venkateshwar Panduga NAIT-22174 - PROD P99: Phase 2: P34 TM - Interface  |
  -- |                        - Purge exceptions from the Purchase Order_Interface_Output after 90 days  |  
  -- +============================================================================================+
  -- +============================================================================================+
  -- |  Name  : Log Exception                                                              		  |
  -- |  Description: The log_exception procedure logs all exceptions         					  |
  -- =============================================================================================|
  gc_debug VARCHAR2(2);
  gn_request_id fnd_concurrent_requests.request_id%TYPE;
  gn_user_id fnd_concurrent_requests.requested_by%TYPE;
  gn_login_id NUMBER;
  gn_resp_id fnd_responsibility.responsibility_id%TYPE;
  gn_resp_appl_id fnd_responsibility.application_id%TYPE;
  -- Read the profile option that enables/disables the debug log
  g_po_wf_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_SET_DEBUG_WORKFLOW_ON'),'N');


PROCEDURE log_exception(
    p_program_name   IN VARCHAR2 ,
    p_error_location IN VARCHAR2 ,
    p_error_msg      IN VARCHAR2)
IS
  ln_login   NUMBER := FND_GLOBAL.LOGIN_ID;
  ln_user_id NUMBER := FND_GLOBAL.USER_ID;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error( p_return_code => FND_API.G_RET_STS_ERROR ,p_msg_count => 1 ,p_application_name => 'XXFIN' ,p_program_type => 'Custom Messages' ,p_program_name => p_program_name ,p_attribute15 => p_program_name ,p_program_id => NULL ,p_module_name => 'PO' ,p_error_location => p_error_location ,p_error_message_code => NULL ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
END log_exception;
/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE print_debug_msg(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  IF (gc_debug  = 'Y' OR p_force) THEN
    lc_Message := P_Message;
    fnd_file.put_line (fnd_file.log, lc_Message);
    IF ( fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
      dbms_output.put_line (lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_debug_msg;
/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE print_out_msg(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  lc_message := p_message;
  fnd_file.put_line (fnd_file.output, lc_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    dbms_output.put_line (lc_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_out_msg;


-- +============================================================================================+
-- |  Name  : send_output_email                                                                 |
-- |  Description: Sends the CP Request output as attachment in email			                |
-- =============================================================================================|
PROCEDURE send_output_email(l_request_id NUMBER, l_ret_code NUMBER)
AS
l_email_addr	VARCHAR2(4000);
ln_request_id NUMBER;
l_instance_name	VARCHAR2(30);
BEGIN
	print_debug_msg ('Begin - Sending email',TRUE);

	SELECT sys_context('userenv','DB_NAME')
	  INTO l_instance_name
	FROM dual;

  BEGIN
		SELECT target_value2||','||target_value3 INTO l_email_addr
                 FROM  xx_fin_translatedefinition xtd
					   ,xx_fin_translatevalues xtv
                WHERE xtd.translation_name = 'XX_AP_TRADE_INV_EMAIL'
                AND xtd.translate_id       = xtv.translate_id
                AND xtv.source_value1 = 'PURCHASEORDER';
	EXCEPTION
		WHEN OTHERS THEN
			l_email_addr := NULL;
			print_debug_msg ('Email Translation XX_AP_TRADE_INV_EMAIL not setup correctly for source_value1 PURCHASEORDER.'||substr(SQLERRM, 1, 500),TRUE);

	END;

	BEGIN
		ln_request_id :=
			fnd_request.submit_request
			('XXFIN'
				, 'XXODROEMAILER'
				, NULL
				, TO_CHAR (SYSDATE + 1 / (24 * 60)
                          , 'YYYY/MM/DD HH24:MI:SS'
                           )
                 -- schedule 1 minute from now
				, FALSE
				, NULL
				, l_email_addr
				, l_instance_name||':'||to_char(sysdate,'DD-MON-YY')||':PurchaseOrder Interface Output'   -- Email subject
				, 'Please review the attached program output for details and action items...'       -- email body
				, 'Y'      -- attachment
				, l_request_id
			);
	   COMMIT;

	EXCEPTION
		WHEN OTHERS THEN
			print_debug_msg ('Failed in execution of XXODROEMAILER with error as '||substr(SQLERRM, 1, 500),TRUE);
	END;

	print_debug_msg ('End - Sent email for the output of the request_id '||ln_request_id,TRUE);

	EXCEPTION
		WHEN OTHERS THEN
			print_debug_msg ('Error in send_output_email: '||substr(SQLERRM, 1, 500),TRUE);
END send_output_email;

------- Below procedure added for V1.6
/*********************************************************************
* Procedure used to purge error records from purchase order report.
* instead of deleting records we are updating record_status flag.
*********************************************************************/
PROCEDURE purge_report_records
IS
ln_days number :=90;
ln_header_cnt number :=0;
ln_lines_cnt number :=0;
BEGIN

UPDATE xx_po_pom_hdr_int_Stg
SET record_Status ='NAIT-22174'
-- ,error_description = 'Updated record status because these records will not pick and dispaly in the PO interface reprot on user request'
 WHERE record_status in ('E','IE')
 AND creation_DAte <= SYSDATE-ln_days ;
 
 ln_header_cnt := sql%rowcount; 
 
 UPDATE xx_po_pom_lines_int_Stg
SET record_Status ='NAIT-22174'
-- ,error_description = 'Updated record status because these records will not pick and dispaly in the PO interface reprot on user request'
 WHERE record_status in ('E','IE')
 AND creation_DAte <=SYSDATE-ln_days;
 
ln_lines_cnt := sql%rowcount; 

print_debug_msg ('No. of header reocrd purged : '||ln_header_cnt,TRUE);
print_debug_msg ('No. of lines reocrd purged : '||ln_lines_cnt,TRUE);

COMMIT;

	EXCEPTION
		WHEN OTHERS THEN
			print_debug_msg ('Error while purging records: '||substr(SQLERRM, 1, 500),TRUE);
END purge_report_records;


------ End V1.6
/**************************************************************************
 *									  									  *
 *  Validate the PO in the PO interface staging xx_po_pom_lines_int_stg   *
 *  and if it doesn't exist then insert into custom table 		          *
 * 									                                      *
 **************************************************************************/

PROCEDURE valid_and_mark_missed_po_int(p_source IN VARCHAR2
		   		,p_source_record_id  IN VARCHAR2
		   		,p_po_number    IN VARCHAR2
		   		,p_po_line_num  IN VARCHAR2
		   		,p_result       OUT NOCOPY VARCHAR2)
IS
	CURSOR c_po_line_exists_in_int(c_po_number VARCHAR2, c_po_line_num VARCHAR2)
	IS
		SELECT count(1)
		FROM xx_po_pom_lines_int_stg ls
		WHERE ls.po_number = c_po_number
		  AND (c_po_line_num IS NULL or ls.line_num  = c_po_line_num)
		  AND ls.process_code = 'I';

	CURSOR c_po_line_exists_in_missed(c_po_number VARCHAR2, c_po_line_num VARCHAR2)
	IS
		SELECT count(1)
		FROM xx_po_pom_missed_in_int pmi
		WHERE pmi.po_number 	= c_po_number
          AND (c_po_line_num IS NULL or pmi.po_line_num  = c_po_line_num)
		  AND pmi.record_status = 'NEW';



	ln_count					NUMBER;
	ln_count1					NUMBER;
	ln_missed_po_rec_id			NUMBER;


BEGIN
		-- Validate PO and line number
		ln_count := 0;
		OPEN c_po_line_exists_in_int(p_po_number,p_po_line_num);
		FETCH c_po_line_exists_in_int INTO ln_count;
		CLOSE c_po_line_exists_in_int;

		print_debug_msg ('valid_and_mark_missed_po_int - Count of exists in xx_po_pom_hdr_int_stg '||ln_count, FALSE);

		IF ln_count > 0 THEN
			-- PO exists in POM Staging table
			p_result   := 'S';
			return;
		ELSE
			-- Check If PO and line number exist in the table XX_PO_POM_MISSED_IN_INT

			ln_count1 := 0;
			OPEN c_po_line_exists_in_missed(p_po_number,p_po_line_num);
			FETCH c_po_line_exists_in_missed INTO ln_count1;
			CLOSE c_po_line_exists_in_missed;

			print_debug_msg ('valid_and_mark_missed_po_int - Count of exists in xx_po_pom_missed_in_int '||ln_count1, FALSE);

			IF ln_count1 >0 THEN
				p_result   := 'S';
				return;
			ELSE

				-- Insert XX_PO_POM_MISSED_IN_INT --

				SELECT xx_po_pom_missed_in_int_s.NEXTVAL
                INTO ln_missed_po_rec_id
                FROM dual;

                INSERT
                INTO xx_po_pom_missed_in_int
                  (
					record_id
                    ,po_number
                    ,po_line_num
                    ,source
                    ,source_record_id
                    ,record_status
                    ,request_id
                    ,created_by
                    ,creation_date
                    ,last_updated_by
                    ,last_update_date
                    ,last_update_login
                  )
                  VALUES
                  (
                    ln_missed_po_rec_id
					,p_po_number
					,p_po_line_num
					,p_source
					,p_source_record_id
					,'NEW'
					,FND_GLOBAL.CONC_REQUEST_ID
                    ,FND_GLOBAL.USER_ID
                    ,SYSDATE
                    ,FND_GLOBAL.USER_ID
                    ,SYSDATE
                    ,FND_GLOBAL.LOGIN_ID
                  );
				COMMIT;
			END IF;

		END IF;  -- IF ln_count > 0 THEN

		p_result   := 'S';
EXCEPTION
WHEN OTHERS THEN
  print_debug_msg ('valid_and_mark_missed_po_int - Exception is '||substr(SQLERRM, 1, 500), TRUE);
  p_result   := 'F';
END valid_and_mark_missed_po_int;

-- +============================================================================================+
-- |  Name  : send_output_email                                                                 |
-- |  Description: Sends the CP Request output in email			                				|
-- =============================================================================================|
PROCEDURE send_missing_po_output_email(l_request_id NUMBER, l_ret_code NUMBER)
AS
l_email_addr	VARCHAR2(4000);
ln_request_id NUMBER;
l_instance_name	VARCHAR2(30);
BEGIN
	print_debug_msg ('Begin - Sending email',TRUE);

	SELECT sys_context('userenv','DB_NAME')
	  INTO l_instance_name
	FROM dual;

	 BEGIN
		SELECT target_value2||','||target_value3 INTO l_email_addr
                 FROM  xx_fin_translatedefinition xtd
					   ,xx_fin_translatevalues xtv
                WHERE xtd.translation_name = 'XX_AP_TRADE_INV_EMAIL'
                AND xtd.translate_id       = xtv.translate_id
                AND xtv.source_value1 = 'MISSINGPOS';


		ln_request_id :=
			fnd_request.submit_request
			('XXFIN'
				, 'XXODROEMAILER'
				, NULL
				, TO_CHAR (SYSDATE + 1 / (24 * 60)
                          , 'YYYY/MM/DD HH24:MI:SS'
                           )
                 -- schedule 60 seconds from now
				, FALSE
				, NULL
				, l_email_addr
				, l_instance_name||':'||to_char(sysdate,'DD-MON-YY')||':Missing PO Output'
				, 'Please review the attached program output for details and action items...'
				, 'Y'  -- attachment
				, l_request_id
			);

	   COMMIT;

	 EXCEPTION
	 WHEN OTHERS THEN
			print_debug_msg ('Missing PO - Failed in Email translation or execution of XXODROEMAILER with error as '||substr(SQLERRM, 1, 500),TRUE);
	END;

	print_debug_msg ('End - Sent email for the missing PO the request_id '||ln_request_id,TRUE);
EXCEPTION
		WHEN OTHERS THEN
			print_debug_msg ('Error in send_missing_po_output_email: '||substr(SQLERRM, 1, 500),TRUE);
END send_missing_po_output_email;
-- +============================================================================================+
-- |  Name  : Validate Missing PO                                                                 |
-- |  Description: Procedure to Validate Missing PO                                            |
-- =============================================================================================|
PROCEDURE validate_missing_po(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2)
IS

  CURSOR po_dtl_cr
  IS
		SELECT po_number,
		  po_line_num,
		  creation_date,
		  request_id,
		  DECODE(source, 'NA-RCVADJINTR', 'RCV Adjustment', 'NA-POINTR', 'PO Interface', 'NA-RCVINTR', 'RCV Interface', 'INVOICE-EDI', 'Invoice Interface') out_source
		FROM xx_po_pom_missed_in_int
		WHERE RECORD_STATUS='NEW';
TYPE po_dtl
IS
  TABLE OF po_dtl_cr%ROWTYPE INDEX BY PLS_INTEGER;
  l_po_dtl_tab po_dtl;
  ln_count NUMBER;
  lc_err_msg VARCHAR2(2000);
  ln_missing_po_cnt NUMBER :=0;
BEGIN
print_out_msg(' ');
print_out_msg(RPAD('Created On',15)||' '||RPAD('Source',23)||' '||RPAD('Request Id #',20)||' '||RPAD('PO Number',20)||' '||RPAD('PO Line #',12));
print_out_msg(RPAD('=',15,'=')||' '||RPAD('=',23,'=')||' '||RPAD('=',20,'=')||' '||RPAD('=',20,'=')||' '||RPAD('=',12,'='));
  OPEN po_dtl_cr;
  FETCH po_dtl_cr BULK COLLECT INTO l_po_dtl_tab;
  IF l_po_dtl_tab.count>0 THEN
    FOR i IN l_po_dtl_tab.FIRST .. l_po_dtl_tab.LAST
    LOOP
      SELECT COUNT(1)
      INTO ln_count
      FROM xx_po_pom_lines_int_stg xpl
      WHERE xpl.po_number=l_po_dtl_tab(i).po_number
	    AND xpl.line_num = NVL(l_po_dtl_tab(i).po_line_num,xpl.line_num)
	    AND xpl.record_status = 'I';
      IF ln_count>0 THEN
        UPDATE xx_po_pom_missed_in_int
        SET record_status='PROCESSED'
        WHERE po_number  =l_po_dtl_tab(i).po_number
		  AND po_line_num = l_po_dtl_tab(i).po_line_num;
      ELSE
        print_out_msg(	RPAD(l_po_dtl_tab(i).creation_date,15)||' '||
						RPAD(NVL(l_po_dtl_tab(i).out_source,'   '),23)||' '||
						RPAD(l_po_dtl_tab(i).request_id,20)||' '||
						RPAD(l_po_dtl_tab(i).po_number,20)||' '||
						RPAD(l_po_dtl_tab(i).po_line_num,12));
        ln_missing_po_cnt :=ln_missing_po_cnt+1;
      END IF;
      END LOOP;
    COMMIT;
	IF ln_missing_po_cnt>0 THEN
	send_missing_po_output_email(fnd_global.conc_request_id, p_retcode);
	END IF;
    END IF;
    CLOSE po_dtl_cr;

    EXCEPTION
  WHEN OTHERS THEN
    lc_err_msg :=SQLCODE||SQLERRM;
	print_debug_msg (lc_err_msg);
  END;
-- +============================================================================================+
-- |  Name  : parse                                                                 |
-- |  Description: Procedure to parse delimited string and load them into table                 |
-- =============================================================================================|
PROCEDURE parse(
    p_delimstring IN VARCHAR2 ,
    p_table OUT varchar2_table ,
    p_nfields OUT INTEGER ,
    p_delim IN VARCHAR2 DEFAULT '|' ,
    p_error_msg OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2)
IS
  l_string VARCHAR2(32767) := p_delimstring;
  l_nfields PLS_INTEGER    := 1;
  l_table varchar2_table;
  l_delimpos PLS_INTEGER := INSTR(p_delimstring, p_delim);
  l_delimlen PLS_INTEGER := LENGTH(p_delim);
BEGIN
  WHILE l_delimpos > 0
  LOOP
    l_table(l_nfields) := TRIM(SUBSTR(l_string,1,l_delimpos-1));
    l_string           := SUBSTR(l_string,l_delimpos       +l_delimlen);
    l_nfields          := l_nfields                        +1;
    l_delimpos         := INSTR(l_string, p_delim);
  END LOOP;
  l_table(l_nfields) := TRIM(l_string);
  p_table            := l_table;
  p_nfields          := l_nfields;
EXCEPTION
WHEN OTHERS THEN
  p_retcode   := '2';
  p_error_msg := 'Error in XX_PO_POM_INT_PKG.parse - record:'||SUBSTR(sqlerrm,1,150);
END parse;
-- +============================================================================================+
-- |  Name  : insert_header                                                                |
-- |  Description: Procedure to insert data into header staging table                           |
-- =============================================================================================|
PROCEDURE insert_header(
    p_table   IN varchar2_table ,
    p_nfields IN INTEGER ,
    p_error_msg OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2)
IS
  l_table varchar2_table;
BEGIN
  l_table := p_table;
  INSERT
  INTO xx_po_pom_hdr_int_stg
    (
      record_id ,
      process_code ,
      po_number ,
      currency_code ,
      vendor_site_code ,
      loc_id ,
      fob_code ,
      freight_code ,
      note_to_vendor ,
      note_to_receiver ,
      status_code ,
      import_manual_po ,
      date_entered ,
      date_changed ,
      rate_type ,
      distribution_code ,
      po_type ,
      num_lines ,
      cost ,
      units_ord_rec_shpd ,
      lbs ,
      net_po_total_cost ,
      drop_ship_flag ,
      ship_via ,
      back_orders ,
      order_dt ,
      ship_dt ,
      arrival_dt ,
      cancel_dt ,
      release_date ,
      revision_flag ,
      last_ship_dt ,
      last_receipt_dt ,
      disc_pct ,
      disc_days ,
      net_days ,
      allowance_basis ,
      allowance_dollars ,
      allowance_percent ,
      pom_created_by ,
      time_entered ,
      program_entered_by ,
      pom_changed_by ,
      changed_time ,
      program_changed_by ,
      cust_id ,
      cust_order_nbr ,
      cust_order_sub_nbr ,
      vendor_doc_num ,
      record_status ,
      error_description ,
      request_id ,
      created_by ,
      creation_date ,
      last_updated_by ,
      last_update_date ,
      last_update_login ,
	  attribute2
    )
    VALUES
    (
      po_headers_interface_s.NEXTVAL --changed to sync with std interface xx_po_pom_hdr_int_stg_s.nextval --record_id
      ,
      l_table(2) --process_code
      ,
      ltrim(l_table(3),'0')
      ||'-'
      ||lpad(ltrim(l_table(6), '0'),4,'0') --po_number + loc_id
      ,
      l_table(4) --currency_code
      ,
      l_table(5) --vendor_id
      ,
      l_table(6) --loc_id
      ,
      l_table(7) --fob_code
      ,
      l_table(8) --freight_code
      ,
      l_table(9) --note_to_vendor
      ,
      l_table(10) --note_to_receiver
      ,
      l_table(11) --status_code
      ,
      l_table(12) --import_manual_po
      ,
      DECODE(l_table(13),NULL,NULL,TO_DATE(l_table(13)
      ||NVL(l_table(44),'00.00.00'),'mm/dd/yyyyhh24.mi.ss')) --date_entered
      ,
      DECODE(l_table(14),NULL,NULL,TO_DATE(l_table(14)
      ||NVL(l_table(47),'00.00.00'),'mm/dd/yyyyhh24.mi.ss')) --date_changed
      ,
      l_table(15) --rate_type
      ,
      l_table(18) --distribution_code
      ,
      l_table(19) --po_type
      ,
      l_table(20) --num_lines
      ,
      l_table(21) --cost
      ,
      l_table(22) --units_ord_rec_shpd
      ,
      l_table(23) --lbs
      ,
      l_table(24) --net_po_total_cost
      ,
      l_table(25) --drop_ship_flag
      ,
      l_table(27) --ship_via
      ,
      l_table(28) --back_orders
      ,
      DECODE(l_table(29),NULL,NULL,to_date(l_table(29),'mm/dd/yyyy')) --order_dt
      ,
      DECODE(l_table(30),NULL,NULL,to_date(l_table(30),'mm/dd/yyyy')) --ship_dt
      ,
      DECODE(l_table(31),NULL,NULL,to_date(l_table(31),'mm/dd/yyyy')) --arrival_dt
      ,
      DECODE(l_table(32),NULL,NULL,to_date(l_table(32),'mm/dd/yyyy')) --cancel_dt
      ,
      DECODE(l_table(33),NULL,NULL,to_date(l_table(33),'mm/dd/yyyy')) --release_date
      ,
      l_table(34) --revision_flag
      ,
      DECODE(l_table(35),NULL,NULL,to_date(l_table(35),'mm/dd/yyyy')) --last_ship_dt
      ,
      DECODE(l_table(36),NULL,NULL,to_date(l_table(36),'mm/dd/yyyy')) --last_receipt_dt
      ,
      l_table(37) --disc_pct
      ,
      l_table(38) --disc_days
      ,
      l_table(39) --net_days
      ,
      l_table(40) --allowance_basis
      ,
      l_table(41) --allowance_dollars
      ,
      l_table(42) --allowance_percent
      ,
      l_table(43) --pom_created_by
      ,
      l_table(44) --time_entered
      ,
      l_table(45) --pgm_entered_by
      ,
      l_table(46) --pom_changed_by
      ,
      l_table(47) --changed_time
      ,
      l_table(48) --pgm_changed_by
      ,
      l_table(49) --cust_id
      ,
      l_table(50) --cust_order_nbr
      ,
      l_table(51) --cust_order_sub_nbr
      ,
      l_table(3) --po_number
      ,
      '' --record_status
      ,
      '' --error_description
      ,
      gn_request_id ,
      gn_user_id ,
      sysdate ,
      gn_user_id ,
      sysdate ,
      gn_login_id ,
	  'NEW'   -- Used for report_master_program_stats to report for latest records
    );
EXCEPTION
WHEN OTHERS THEN
  p_retcode   := '2';
  p_error_msg := 'Error in XX_PO_POM_INT_PKG.insert_header '||SUBSTR(sqlerrm,1,150);
END insert_header;
-- +============================================================================================+
-- |  Name  : insert_line                                                                |
-- |  Description: Procedure to insert line data into line staging table                        |
-- =============================================================================================|
PROCEDURE insert_line
  (
    p_table   IN varchar2_table ,
    p_nfields IN INTEGER ,
    p_error_msg OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2
  )
IS
  l_table varchar2_table;
BEGIN
  l_table := p_table;
  INSERT
  INTO xx_po_pom_lines_int_stg
    (
      record_line_id ,
      process_code ,
      po_number ,
      line_num ,
      item ,
      quantity ,
      ship_to_location ,
      need_by_date ,
      promised_date ,
      line_reference_num ,
      uom_code ,
      unit_price ,
      shipmentnumber ,
      dept ,
      class ,
      vendor_product_code ,
      extended_cost ,
      qty_shipped ,
      qty_received ,
      seasonal_large_order ,
      record_status ,
      error_description ,
      request_id ,
      created_by ,
      creation_date ,
      last_updated_by ,
      last_update_date ,
      last_update_login
    )
    VALUES
    (
      po_lines_interface_s.NEXTVAL --changed to sync with std interface xx_po_pom_lines_int_stg_s.NEXTVAL
      ,
      l_table(2) --process_code
      ,
      ltrim(l_table(3),'0')
      ||'-'
      ||lpad(ltrim(l_table(7),'0'),4,'0') --po_number + loc -discuss
      ,
      l_table(4) --line_num
      ,
      l_table(5) --item
      ,
      l_table(6) --quantity
      ,
      l_table(7) --ship_to_location
      ,
      DECODE(l_table(8),NULL,NULL,to_date(l_table(8),'mm/dd/yyyy')) --need_by_date
      ,
      DECODE(l_table(9),NULL,NULL,to_date(l_table(9),'mm/dd/yyyy')) --promised_date
      ,
      l_table(10) --line_reference_num
      ,
      l_table(11) --uom_code
      ,
      l_table(12) --unit_price
      ,
      l_table(13) --shipmentnumber
      ,
      l_table(14) --dept
      ,
      l_table(15) --class
      ,
      l_table(16) --vendor_product_code
      ,
      l_table(17) --extended_cost
      ,
      l_table(18) --qty_shipped
      ,
      l_table(19) --qty_received
      ,
      l_table(20) --seasonal_large_order
      ,
      '' --record_status
      ,
      '' --error_description
      ,
      gn_request_id ,
      gn_user_id ,
      sysdate ,
      gn_user_id ,
      sysdate ,
      gn_login_id
    );
EXCEPTION
WHEN OTHERS THEN
  p_retcode   := '2';
  p_error_msg := 'Error in XX_PO_POM_INT_PKG.insert_line '||SUBSTR(sqlerrm,1,150);
END insert_line;
-- +============================================================================================+
-- |  Name  : load_staging                                                             |
-- |  Description: This procedure reads data from the file and inserts into staging tables      |
-- =============================================================================================|
PROCEDURE load_staging
  (
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_filepath  VARCHAR2 ,
    p_file_name VARCHAR2 ,
    p_debug     VARCHAR2
  )
AS
  l_filehandle UTL_FILE.FILE_TYPE;
  lc_filedir    VARCHAR2(200) := p_filepath;
  lc_filename   VARCHAR2(200) := p_file_name;
  lc_dirpath    VARCHAR2(500);
  lb_file_exist BOOLEAN;
  ln_size       NUMBER;
  ln_block_size NUMBER;
  lc_newline    VARCHAR2(4000); -- Input line
  ln_max_linesize BINARY_INTEGER := 32767;
  ln_rec_cnt NUMBER              := 0;
  l_table varchar2_table;
  l_nfields                    INTEGER;
  lc_error_msg                 VARCHAR2(1000) := NULL;
  lc_error_loc                 VARCHAR2(2000) := 'XX_PO_POM_INT_PKG.LOAD_STAGING';
  lc_retcode                   VARCHAR2(3)    := NULL;
  lc_rec_type                  VARCHAR2(1)    := NULL;
  ln_count_hdr                 NUMBER         := 0;
  ln_count_lin                 NUMBER         := 0;
  ln_count_err                 NUMBER         := 0;
  ln_count_tot                 NUMBER         := 0;
  ln_conc_file_copy_request_id NUMBER;
  lc_dest_file_name            VARCHAR2(200);
  nofile                       EXCEPTION;
  data_exception               EXCEPTION;
  lc_instance_name			   VARCHAR2(30);
  lb_complete        		   BOOLEAN;
  lc_phase           		   VARCHAR2(100);
  lc_status          		   VARCHAR2(100);
  lc_dev_phase       		   VARCHAR2(100);
  lc_dev_status      		   VARCHAR2(100);
  lc_message         		   VARCHAR2(100);
  CURSOR get_dir_path
  IS
    SELECT directory_path FROM all_directories WHERE directory_name = p_filepath;
BEGIN
  gc_debug      := p_debug;
  gn_request_id := fnd_global.conc_request_id;
  gn_user_id    := fnd_global.user_id;
  gn_login_id   := fnd_global.login_id;

  SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV','DB_NAME')),1,8)
      INTO lc_instance_name
      FROM dual;

  print_debug_msg ('Start load_staging from File:'||p_file_name||' Path:'||p_filepath,TRUE);
  UTL_FILE.FGETATTR(lc_filedir,lc_filename,lb_file_exist,ln_size,ln_block_size);
  IF NOT lb_file_exist THEN
    RAISE nofile;
  END IF;
  l_filehandle := UTL_FILE.FOPEN(lc_filedir,lc_filename,'r',ln_max_linesize);
  print_debug_msg ('File open successfull',TRUE);
  LOOP
    BEGIN
      UTL_FILE.GET_LINE(l_filehandle,lc_newline);
      IF lc_newline IS NULL THEN
        EXIT;
      END IF;
      print_debug_msg ('Processing Line:'||lc_newline,FALSE);
      --parse the line
      parse(lc_newline,l_table,l_nfields,'|',lc_error_msg,lc_retcode);
      IF lc_retcode = '2' THEN
        RAISE data_exception;
      END IF;
      lc_rec_type   := l_table(1);
      IF lc_rec_type = 'H' THEN
        print_debug_msg ('Insert Header',FALSE);
        insert_header(l_table,l_nfields,lc_error_msg,lc_retcode);
        IF lc_retcode = '2' THEN
          RAISE data_exception;
        END IF;
        ln_count_hdr   := ln_count_hdr + 1;
      ELSIF lc_rec_type = 'L' THEN
        print_debug_msg ('Insert Line',FALSE);
        insert_line(l_table,l_nfields,lc_error_msg,lc_retcode);
        IF lc_retcode = '2' THEN
          RAISE data_exception;
        END IF;
        ln_count_lin := ln_count_lin + 1;
      ELSE
        print_debug_msg ('Invalid Record Type',TRUE);
        lc_retcode   := '2';
        lc_error_msg := 'ERROR - Invalid record type :'||lc_rec_type;
        RAISE data_exception;
      END IF;
      ln_count_tot := ln_count_tot + 1;
    EXCEPTION
    WHEN no_data_found THEN
      EXIT;
    END;
  END LOOP;
  UTL_FILE.FCLOSE(l_filehandle);
  UPDATE xx_po_pom_lines_int_stg l
  SET l.record_id =
    (SELECT record_id
    FROM xx_po_pom_hdr_int_stg h
    WHERE h.po_number = l.po_number
    AND h.request_id  = l.request_id
    )
  WHERE l.request_id = gn_request_id;
  COMMIT;
  print_debug_msg(TO_CHAR(ln_count_tot)||' records successfully loaded into staging',TRUE);
  print_out_msg('OD: PO Purchase Order Interface Staging Program');
  print_out_msg('================================================ ');
  print_out_msg('No. of header records loaded:'||TO_CHAR(ln_count_hdr));
  print_out_msg('No. of line records loaded  :'||TO_CHAR(ln_count_lin));
  print_out_msg(' ');
  print_out_msg('Total No. of records loaded :'||TO_CHAR(ln_count_tot));
  dbms_lock.sleep(5);

  OPEN get_dir_path;
  FETCH get_dir_path INTO lc_dirpath;
  CLOSE get_dir_path;

  print_debug_msg('Calling the Common File Copy to move the Inbound file to AP Invoice folder',TRUE);
  lc_dest_file_name := '/app/ebs/ebsfinance/'||lc_instance_name||'/apinvoice/'
											 || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)
											 || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.TXT';

  ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
															 'XXCOMFILCOPY',
															 '',
															 '',
															 FALSE,
															 lc_dirpath||'/'||lc_filename, --Source File Name
															 lc_dest_file_name,            --Dest File Name
															 '', '', 'N'                   --Deleting the Source File
															);

	IF ln_conc_file_copy_request_id > 0
		THEN
	        COMMIT;
   print_debug_msg('While Waiting Import Standard Purchase Order Request to Finish');
		 -- wait for request to finish
			lb_complete :=fnd_concurrent.wait_for_request (
							                               request_id   => ln_conc_file_copy_request_id,
							                               interval     => 10,
							                               max_wait     => 0,
							                               phase        => lc_phase,
							                               status       => lc_status,
							                               dev_phase    => lc_dev_phase,
							                               dev_status   => lc_dev_status,
							                               message      => lc_message
														  );

	        print_debug_msg('Status :'||lc_status);
			print_debug_msg('dev_phase :'||lc_dev_phase);
			print_debug_msg('dev_status :'||lc_dev_status);
			print_debug_msg('message :'||lc_message);
		END IF;

  print_debug_msg('Calling the Common File Copy to move the Inbound file to Archive folder',TRUE);

  lc_dest_file_name            := '$XXFIN_ARCHIVE/inbound/' || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4) || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.TXT';
  ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN', 'XXCOMFILCOPY', '', '', FALSE, lc_dirpath||'/'||lc_filename, --Source File Name
  lc_dest_file_name,                                                                                                               --Dest File Name
  '', '', 'Y'                                                                                                                      --Deleting the Source File
  );
  COMMIT;
EXCEPTION
WHEN nofile THEN
  print_debug_msg ('ERROR - File not exists',TRUE);
  p_retcode := 2;
WHEN data_exception THEN
  ROLLBACK;
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg('Error at line:'||lc_newline,TRUE);
  p_errbuf  := lc_error_msg;
  p_retcode := lc_retcode;
WHEN UTL_FILE.INVALID_OPERATION THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('ERROR - Invalid Operation',TRUE);
  p_retcode:=2;
WHEN UTL_FILE.INVALID_FILEHANDLE THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('ERROR - Invalid File Handle',TRUE);
  p_retcode := 2;
WHEN UTL_FILE.READ_ERROR THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('ERROR - Read Error',TRUE);
  p_retcode := 2;
WHEN UTL_FILE.INVALID_PATH THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('ERROR - Invalid Path',TRUE);
  p_retcode := 2;
WHEN UTL_FILE.INVALID_MODE THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('ERROR - Invalid Mode',TRUE);
  p_retcode := 2;
WHEN UTL_FILE.INTERNAL_ERROR THEN
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('ERROR - Internal Error',TRUE);
  p_retcode := 2;
WHEN OTHERS THEN
  ROLLBACK;
  UTL_FILE.FCLOSE(l_filehandle);
  print_debug_msg ('ERROR - '||SUBSTR(sqlerrm,1,250),TRUE);
  p_retcode := 2;
END load_staging;
-- +============================================================================================+
-- |  Name   : report_master_program_stats                                                   |
-- |  Description: This procedure print stats of master program                                 |
-- =============================================================================================|
PROCEDURE report_master_program_stats
AS

-- NAIT-37088 seperate POM request_id via attribute3.
  CURSOR c_staging_requests IS
    SELECT DISTINCT request_id, TO_CHAR(creation_date, 'DD-MON-YY')
    FROM xx_po_pom_hdr_int_stg
    WHERE attribute2 = 'NEW'
	AND (REQUEST_ID IS NOT NULL OR attribute3 NOT IN ('SCM'));

  CURSOR req_stats_cur(c_request_id NUMBER)
  IS
    SELECT
         hdr.attribute5
        ,hdr.process_code
        ,DECODE(hdr.record_status,'E','Error','IE','Error','D','Error',hdr.record_status) record_status
        ,COUNT(1) COUNT
    FROM xx_po_pom_hdr_int_stg hdr
    WHERE hdr.request_id = c_request_id
    GROUP BY hdr.attribute5, hdr.process_code, DECODE(hdr.record_status,'E','Error','IE','Error','D','Error',hdr.record_status);

-- NAIT-37088 grab all scm po via process code, attribute5 and attribute3.
  CURSOR scm_stats_cur IS
  SELECT
      hdr.attribute5
	  ,hdr.attribute3
      ,hdr.process_code
      ,DECODE(hdr.record_status,'E','Error','IE','Error','D','Error',hdr.record_status) record_status
	  ,COUNT(1) COUNT
    FROM xx_po_pom_hdr_int_stg hdr
    WHERE hdr.attribute2 = 'NEW'
	AND hdr.attribute3 = 'SCM'
    GROUP BY hdr.attribute5, hdr.attribute3, hdr.process_code, DECODE(hdr.record_status,'E','Error','IE','Error','D','Error',hdr.record_status);

-- cursor to collect error details for POM by batch_id and request_id
  CURSOR err_details_cur
  IS
    WITH batchTbl AS
    (SELECT to_number(req.argument1) batch_id
      FROM fnd_concurrent_requests req
      WHERE req.parent_request_id  = gn_request_id
    )
    SELECT
      hdr.creation_date,
      hdr.batch_id batch_id,
      hdr.record_id,
      hdr.po_number,
      '' line_num,
      0 n_line_num,
	  hdr.attribute3, -- NAIT-37088 SCM PO Indentifer
      hdr.error_column,
      hdr.error_value,
      hdr.error_description
    FROM xx_po_pom_hdr_int_stg hdr
        ,batchTbl
    WHERE 1=1
      AND (hdr.record_status = 'E' OR hdr.record_status ='D' OR hdr.record_status ='IE')
      AND hdr.batch_id = batchTbl.batch_id
       AND (hdr.error_column IS NOT NULL)
     UNION ALL
    SELECT
      ln.creation_date,
      NVL(ln.batch_id, hdr.batch_id) batch_id,
      ln.record_id,
      ln.po_number,
      ln.line_num||'' line_num,
      ln.line_num n_line_num,
      ln.attribute3,
      ln.error_column,
      ln.error_value,
      ln.error_description
    FROM xx_po_pom_hdr_int_stg hdr
      ,xx_po_pom_lines_int_stg ln
        ,batchTbl
    WHERE hdr.record_id    = ln.record_id
      AND (hdr.record_status = 'E' OR hdr.record_status ='D' OR hdr.record_status ='IE')
      AND (ln.record_status = 'E' OR ln.record_status ='D' OR ln.record_status ='IE')
      AND ((hdr.batch_id = batchTbl.batch_id AND ln.error_column IS NOT NULL)
        OR (ln.batch_id = batchTbl.batch_id))
  ORDER BY creation_date DESC, batch_id ASC, record_id ASC, n_line_num ASC;


TYPE stats
IS
	TABLE OF err_details_cur%ROWTYPE INDEX BY PLS_INTEGER;
	stats_tab STATS;

	TYPE l_num_tab IS TABLE OF NUMBER;
	l_stage_requests            l_num_tab;

	TYPE l_var_tab IS TABLE OF VARCHAR2(10);
	l_stage_reqs_date 	        l_var_tab;

	lc_error_message   VARCHAR2(200);
	lc_error_column    VARCHAR2(150);
	lc_error_value     VARCHAR2(100);

    -- variable for loop count
    indx                        NUMBER;

    -- for POM PO count
	ln_i_skip_cnt				NUMBER;
	ln_u_skip_cnt				NUMBER;
	ln_new_po_success_cnt		NUMBER;
	ln_new_po_fail_cnt			NUMBER;
	ln_new_po_other_status_cnt	NUMBER;
	ln_upd_po_success_cnt		NUMBER;
	ln_upd_po_fail_cnt			NUMBER;
	ln_upd_po_other_status_cnt	NUMBER;
	ln_total_po					NUMBER;
	ln_total_new_po				NUMBER;
	ln_total_update_po			NUMBER;
	ln_new_req_cnt				NUMBER;

	--NAIT-37088 variables for SCM PO count
	scm_ln_i_skip_cnt               NUMBER;
	scm_ln_u_skip_cnt               NUMBER;
	scm_ln_new_po_success_cnt       NUMBER;
	scm_ln_new_po_fail_cnt       	NUMBER;
	scm_ln_new_po_other_status_cnt  NUMBER;
	scm_ln_upd_po_success_cnt       NUMBER;
	scm_ln_upd_po_fail_cnt          NUMBER;
	scm_ln_upd_po_other_status_cnt  NUMBER;
	scm_ln_total_po                 NUMBER;
	scm_ln_total_new_po             NUMBER;
    scm_ln_total_update_po          NUMBER;
	scm_ln_new_req_cnt				NUMBER;

-- take each request and generate a count for POM
BEGIN
  print_debug_msg ('Report Master Program Stats',FALSE);

  print_out_msg('OD PO POM Inbound Interface');
  print_out_msg('==============================');

  -- get the list of request_id's of staging program to use it in report_master_program_stats()
  OPEN c_staging_requests;
  FETCH c_staging_requests BULK COLLECT INTO l_stage_requests,l_stage_reqs_date;
  CLOSE c_staging_requests;

  ln_new_req_cnt := l_stage_requests.COUNT;

  -- probably needs to wrap around loop to short circuit if no POM POs exists
  IF ln_new_req_cnt = 0 THEN
	print_out_msg('No PO data from POM was loaded recently.');
  END IF;

  FOR i IN 1.. ln_new_req_cnt
  LOOP
	  print_debug_msg ('Report for request_id '||l_stage_requests(i),TRUE);

	-- generally, only one new load request exists. For Exception cases, we will display the request_id to differentiate
	  IF ln_new_req_cnt > 1 THEN
		print_out_msg ('');
		print_out_msg ('OD PO POM Summary Report for the oracle load request '||l_stage_requests(i)||' loaded on '||l_stage_reqs_date(i));
	  END IF;

	ln_i_skip_cnt				:= 0;
	ln_u_skip_cnt				:= 0;
	ln_new_po_success_cnt		:= 0;
	ln_new_po_fail_cnt			:= 0;
	ln_new_po_other_status_cnt	:= 0;
	ln_upd_po_success_cnt		:= 0;
	ln_upd_po_fail_cnt			:= 0;
	ln_upd_po_other_status_cnt	:= 0;
	ln_total_po					:= 0;
	ln_total_new_po				:= 0;
	ln_total_update_po			:= 0;

	  FOR l_po_stats IN req_stats_cur(l_stage_requests(i))
	  LOOP
		IF l_po_stats.process_code = 'I' THEN

			ln_total_new_po := ln_total_new_po + l_po_stats.count;

			IF l_po_stats.attribute5 like '%skip PO processing' THEN
				ln_i_skip_cnt := ln_i_skip_cnt + l_po_stats.count;
			ELSE
				IF l_po_stats.record_status = 'I' THEN
					ln_new_po_success_cnt := ln_new_po_success_cnt + l_po_stats.count;
				ELSIF l_po_stats.record_status = 'Error' THEN
					ln_new_po_fail_cnt := ln_new_po_fail_cnt + l_po_stats.count;
				ELSE
					print_debug_msg('For process_code - '||l_po_stats.process_code||', extra record_status is '||l_po_stats.record_status, TRUE);
					ln_new_po_other_status_cnt := ln_new_po_other_status_cnt + l_po_stats.count;
				END IF;
			END IF;
		ELSIF l_po_stats.process_code = 'U' THEN

			ln_total_update_po := ln_total_update_po + l_po_stats.count;

					--IF l_po_stats.attribute5 = 'Internal Vendor - skip PO processing' THEN
			-- Add in skip count if it is 'Internal Vendor - skip PO processing' or 'No Changes - skip PO processing'
			IF l_po_stats.attribute5 like '%skip PO processing' THEN
				ln_u_skip_cnt := ln_u_skip_cnt + l_po_stats.count;
			ELSE
				IF l_po_stats.record_status = 'I' THEN
					ln_upd_po_success_cnt := ln_upd_po_success_cnt + l_po_stats.count;
				ELSIF l_po_stats.record_status = 'Error' THEN
					ln_upd_po_fail_cnt := ln_upd_po_fail_cnt + l_po_stats.count;
				ELSE
					print_debug_msg('For process_code - '||l_po_stats.process_code||', extra record_status is '||l_po_stats.record_status, TRUE);
					ln_upd_po_other_status_cnt := ln_upd_po_other_status_cnt + l_po_stats.count;
				END IF;
			END IF;
		END IF;
	  END LOOP;

	    ln_total_po := ln_total_new_po + ln_total_update_po;

	    print_out_msg('Total No of POs(new and update) from POM :'||TO_CHAR(ln_total_po));
	    print_out_msg(' ');
	    print_out_msg('Total No of new POs from POM :'||TO_CHAR(ln_total_new_po));
	    print_out_msg('    Total No of POs Successfully Imported :'||TO_CHAR(ln_new_po_success_cnt));
	    print_out_msg('    Total No of POs failed to Import :'||TO_CHAR(ln_new_po_fail_cnt));
	    print_out_msg('    Total No of new POs skipped :'||TO_CHAR(ln_i_skip_cnt));
	    IF ln_new_po_other_status_cnt > 0 THEN
	  	print_out_msg('    Total No of new POs processed and with different status :'||TO_CHAR(ln_new_po_other_status_cnt));
	    END IF;
	    print_out_msg(' ');
	    print_out_msg('Total No of POs to update from POM :'||TO_CHAR(ln_total_update_po));
	    print_out_msg('    Total No of POs Successfully update :'||TO_CHAR(ln_upd_po_success_cnt));
	    print_out_msg('    Total No of POs failed to update :'||TO_CHAR(ln_upd_po_fail_cnt));
	    print_out_msg('    Total No of POs to be updated and skipped :'||TO_CHAR(ln_u_skip_cnt));
	    IF ln_upd_po_other_status_cnt > 0 THEN
	  	print_out_msg('    Total No of POs to update are processed and with different status :'||TO_CHAR(ln_upd_po_other_status_cnt));
	    END IF;

	    print_out_msg(' ');
  END LOOP;

    -- NAIT-37088 -- include SCM Purchase Orders count
    print_out_msg(' ');
    print_out_msg('OD PO SCM Inbound Interface');
    print_out_msg('==============================');

	scm_ln_i_skip_cnt					:= 0;
	scm_ln_u_skip_cnt					:= 0;
	scm_ln_new_po_success_cnt			:= 0;
	scm_ln_new_po_fail_cnt			    := 0;
	scm_ln_new_po_other_status_cnt	    := 0;
	scm_ln_upd_po_success_cnt		    := 0;
	scm_ln_upd_po_fail_cnt			    := 0;
	scm_ln_upd_po_other_status_cnt	    := 0;
	scm_ln_total_po					    := 0;
	scm_ln_total_new_po				    := 0;
	scm_ln_total_update_po			    := 0;

	FOR scm_po_stats IN scm_stats_cur
	LOOP
		--count SCM inserts
	  	IF scm_po_stats.process_code = 'I' THEN
		scm_ln_total_new_po := scm_ln_total_new_po + scm_po_stats.count;
			IF scm_po_stats.attribute5 like '%skip PO processing' THEN
	  			scm_ln_i_skip_cnt := scm_ln_i_skip_cnt + scm_po_stats.count;
	  		ELSE
				-- count successful SCM inserts
	  			IF scm_po_stats.record_status = 'I' THEN
	  				scm_ln_new_po_success_cnt := scm_ln_new_po_success_cnt + scm_po_stats.count;
				-- count failed SCM inserts
	  			ELSIF scm_po_stats.record_status = 'Error' THEN
	  				scm_ln_new_po_fail_cnt := scm_ln_new_po_fail_cnt + scm_po_stats.count;
	  			ELSE
				-- count other status SCM inserts
	  				print_debug_msg('For process_code - '||scm_po_stats.process_code||', extra record_status is '||scm_po_stats.record_status, TRUE);
	  				scm_ln_new_po_other_status_cnt := scm_ln_new_po_other_status_cnt + scm_po_stats.count;
	  			END IF;
	  		END IF;
		-- count SCM updates
	  	ELSIF scm_po_stats.process_code = 'U' THEN
			-- count number of SCM PO updates
	  		scm_ln_total_update_po := scm_ln_total_update_po + scm_po_stats.count;
	  		-- Add in skip count if it is 'Internal Vendor - skip PO processing' or 'No Changes - skip PO processing'
	  		IF scm_po_stats.attribute5 like '%skip PO processing' THEN
	  			scm_ln_u_skip_cnt := scm_ln_u_skip_cnt + scm_po_stats.count;
	  		ELSE
				-- count successful SCM updates
	  			IF scm_po_stats.record_status = 'I' THEN
	  				scm_ln_upd_po_success_cnt := scm_ln_upd_po_success_cnt + scm_po_stats.count;
				-- count failed SCM updates
	  			ELSIF scm_po_stats.record_status = 'Error' THEN
	  				scm_ln_upd_po_fail_cnt := scm_ln_upd_po_fail_cnt + scm_po_stats.count;
	  			ELSE
				-- count other status SCM pdates
	  				print_debug_msg('For process_code - '||scm_po_stats.process_code||', extra record_status is '||scm_po_stats.record_status, TRUE);
	  				scm_ln_upd_po_other_status_cnt := scm_ln_upd_po_other_status_cnt + scm_po_stats.count;
	  			END IF;
	  		END IF;
        END IF;
	END LOOP;

	-- count total inserted and updated SCM POs
	scm_ln_total_po := scm_ln_total_new_po + scm_ln_total_update_po;

	IF scm_ln_total_po + scm_ln_upd_po_fail_cnt + scm_ln_new_po_fail_cnt + scm_ln_new_po_other_status_cnt= 0 THEN
		print_out_msg('No PO data from SCM was loaded recently.');

	ELSE
		print_out_msg('Total No of POs(new and update) from SCM :'||TO_CHAR(scm_ln_total_po));
		print_out_msg(' ');
		print_out_msg('Total No of new POs from SCM :'||TO_CHAR(scm_ln_total_new_po));
		print_out_msg('    Total No of POs Successfully Imported :'||TO_CHAR(scm_ln_new_po_success_cnt));
		print_out_msg('    Total No of POs failed to Import :'||TO_CHAR(scm_ln_new_po_fail_cnt));
		print_out_msg('    Total No of new POs skipped :'||TO_CHAR(scm_ln_i_skip_cnt));
		IF scm_ln_new_po_other_status_cnt > 0 THEN
		print_out_msg('    Total No of new POs processed and with different status :'||TO_CHAR(scm_ln_new_po_other_status_cnt));
		END IF;
		print_out_msg(' ');
		print_out_msg('Total No of POs to update from SCM :'||TO_CHAR(scm_ln_total_update_po));
		print_out_msg('    Total No of POs Successfully update :'||TO_CHAR(scm_ln_upd_po_success_cnt));
		print_out_msg('    Total No of POs failed to update :'||TO_CHAR(scm_ln_upd_po_fail_cnt));
		print_out_msg('    Total No of POs to be updated and skipped :'||TO_CHAR(scm_ln_u_skip_cnt));
		IF scm_ln_new_po_other_status_cnt > 0 THEN
		print_out_msg('    Total No of POs to update are processed and with different status :'||TO_CHAR(scm_ln_upd_po_other_status_cnt));
		END IF;

		print_out_msg(' ');
	END IF;

  OPEN err_details_cur;
  FETCH err_details_cur BULK COLLECT INTO stats_tab;
  CLOSE err_details_cur;

-- Template
  print_out_msg(' ');
  print_out_msg(RPAD('Created On',10)||' '||RPAD('Record_ID',10)||' '||RPAD('PO Number',15)||' '||RPAD('Line #',6)||' '||RPAD('Source',10)||' '||RPAD('Error Column',20)||' '||RPAD('Error Value',20)||' '||RPAD('Error Details',100));
  print_out_msg(RPAD('=',10,'=')||' '||RPAD('=',10,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',6,'=')||' '||RPAD('=',10,'=')||' '||RPAD('=',20,'=')||' '||RPAD('=',20,'=')||' '||RPAD('=',100,'='));

-- Call err_details_cur for all errors
  FOR indx IN 1..stats_tab.COUNT
  LOOP
    print_out_msg(RPAD(stats_tab(indx).creation_date,10)||' '||RPAD(stats_tab(indx).record_id,10)||' '||RPAD(stats_tab(indx).po_number,15)||' '||RPAD(NVL(stats_tab(indx).line_num,' '),6, ' ')||' '||RPAD(NVL(stats_tab(indx).attribute3,' '),10)||RPAD(NVL(stats_tab(indx).error_column,' '),20, ' ')||' '||RPAD(NVL(stats_tab(indx).error_value,' '),20, ' ')||' '||RPAD(stats_tab(indx).error_description,100));
  END LOOP;

  -- Reset to NULL means these records are touched atleast once and these doesn't include in the Summary Report section count.
  UPDATE xx_po_pom_hdr_int_stg
  SET attribute2 = NULL
  WHERE attribute2 = 'NEW'
  AND record_status IS NOT NULL;

  print_debug_msg ('Total no of header records to set attribute2 to NULL are '||SQL%ROWCOUNT, TRUE);
  COMMIT;

EXCEPTION
WHEN OTHERS THEN
  print_out_msg ('Report Master Program Stats failed'||SUBSTR(sqlerrm,1,150));
END report_master_program_stats;
-- +============================================================================================+
-- |  Name   : update_staging_record_status                                                 |
-- |  Description: This procedure updates record_status in staging per po interface status.     |
-- =============================================================================================|
PROCEDURE update_staging_record_status(
    p_batch_id NUMBER)
AS
  ln_count NUMBER;
BEGIN
	print_debug_msg ('Update record_status in staging incase of error in PO Standard Interface for batch_id '||p_batch_id,FALSE);

	UPDATE xx_po_pom_hdr_int_stg hs
	SET (hs.record_status, hs.error_description, hs.error_column) =
       ( select * from
			(SELECT 'IE', NVL(MIN('Error in PO Interface '
			  ||SUBSTR(poe.error_message,1,1000)), 'Interface Line Failed.')
				, MIN(poe.column_value)
			FROM po_interface_errors poe
			WHERE poe.interface_header_id = hs.record_id
			  AND poe.table_name     = 'PO_HEADERS_INTERFACE'
			  AND poe.batch_id = p_batch_id
			  order by   poe.interface_header_id
			) t where rownum  =1
		)
	WHERE hs.batch_id = p_batch_id
	  AND EXISTS
		(SELECT 'x'
		FROM PO_HEADERS_INTERFACE poi
		WHERE poi.interface_header_id = hs.record_id
		  AND poi.process_code <> 'ACCEPTED'
		)
	  AND EXISTS
		(SELECT 'x'
		FROM po_lines_interface poi
		WHERE poi.interface_header_id = hs.record_id
		  AND poi.process_code <> 'ACCEPTED'
		);
	ln_count:= SQL%ROWCOUNT;
	print_debug_msg(TO_CHAR(ln_count)|| ' header record(s) updated with error status IE for batch_id '||p_batch_id, TRUE);

	UPDATE xx_po_pom_lines_int_stg ls
	SET (ls.record_status, ls.error_description, ls.error_column) =
       ( select * from
			(SELECT 'IE', NVL(MIN('Error in PO Interface '
			  ||SUBSTR(poe.error_message,1,1000)), 'Interface Header Failed.')
				, MIN(poe.column_value)
			FROM po_interface_errors poe
			WHERE poe.interface_line_id = ls.record_line_id
			  AND poe.batch_id = p_batch_id
			  order by   poe.interface_line_id
			) t where rownum  =1
		)
	WHERE EXISTS
		(SELECT 'x'
		FROM xx_po_pom_hdr_int_stg hs
		WHERE hs.record_id = ls.record_id
		  AND hs.batch_id = p_batch_id
		)
	  AND EXISTS
		(SELECT 'x'
		FROM PO_HEADERS_INTERFACE poi
		WHERE poi.interface_header_id = ls.record_id
		  AND poi.process_code <> 'ACCEPTED'
		)
	  AND EXISTS
		(SELECT 'x'
		FROM po_lines_interface poi
		WHERE poi.interface_line_id = ls.record_line_id
		  AND poi.process_code <> 'ACCEPTED'
		);
	ln_count:= SQL%ROWCOUNT;
	print_debug_msg(TO_CHAR(ln_count)|| ' line record(s) updated with error status IE for batch_id '||p_batch_id, TRUE);

	UPDATE xx_po_pom_lines_int_stg ls
	SET ls.record_status    = 'IE',
	ls.error_description  = 'Other lines in the PO failed during import'
	WHERE ls.process_code = 'I'
	  AND ls.record_status = 'I'
	  AND EXISTS
			(SELECT 'x'
			FROM xx_po_pom_hdr_int_stg hs
			WHERE hs.record_id = ls.record_id
			AND hs.record_status = 'IE'
			AND hs.batch_id = p_batch_id
			);
	ln_count:= SQL%ROWCOUNT;
	print_debug_msg(TO_CHAR(ln_count)|| ' line record(s)(with code U) updated with error status IE for batch_id '||p_batch_id, TRUE);

	COMMIT;

END update_staging_record_status;

-- +============================================================================================+
-- |  Name    : child_request_status                                                        |
-- |  Description : This function is used to return the status of the child requests            |
-- =============================================================================================|
FUNCTION child_request_status
  RETURN VARCHAR2
IS
  CURSOR get_conc_status
  IS
    SELECT status_code
    FROM fnd_concurrent_requests
    WHERE parent_request_id    = gn_request_id
    AND status_code           IN('E','G');
  lc_status_code VARCHAR2(15) := NULL;
BEGIN
  print_debug_msg ('Checking child_request_status',FALSE);
  lc_status_code := NULL;
  OPEN get_conc_status;
  FETCH get_conc_status INTO lc_status_code;
  CLOSE get_conc_status;
  IF lc_status_code IS NOT NULL THEN
    print_debug_msg('One or more child program completed in error or warning.',TRUE);
    RETURN 'G'; -- Warning
  ELSE
    RETURN 'C'; -- Normal
  END IF;
END child_request_status;

-- +============================================================================================+
-- |  Name   : print_child_program_stats                                                    |
-- |  Description: This procedure print stats of child program                                  |
-- =============================================================================================|
PROCEDURE report_child_program_stats(
    p_batch_id NUMBER)
AS
  CURSOR hdr_count_cur
  IS
    SELECT COUNT(*) COUNT ,
      DECODE(record_status,'E','Error','I','Interfaced','IE','Error in PO Interface',record_status) record_status
    FROM xx_po_pom_hdr_int_stg
    WHERE batch_id = p_batch_id
    GROUP BY record_status;
  CURSOR line_count_cur
  IS
    SELECT COUNT(*) COUNT ,
      DECODE(l.record_status,'E','Error','I','Interfaced','IE','Error in PO Interface',l.record_status) record_status
    FROM xx_po_pom_lines_int_stg l
    WHERE EXISTS
      (SELECT 'x'
      FROM xx_po_pom_hdr_int_stg h
      WHERE h.record_id = l.record_id
      AND h.po_number   = l.po_number
      AND h.batch_id    = p_batch_id
      )
  AND (l.process_code = 'I' or l.process_code = 'M')
  GROUP BY l.record_status;
TYPE stats
IS
  TABLE OF hdr_count_cur%ROWTYPE INDEX BY PLS_INTEGER;
  stats_tab STATS;
  indx NUMBER;
BEGIN
  print_debug_msg ('Report Child Program Stats',FALSE);
  print_out_msg('OD PO POM Inbound Interface(Child) for Batch '||TO_CHAR(p_batch_id));
  print_out_msg('========================================================== ');
  print_out_msg(RPAD('Record Type',12)||' '||RPAD('Record Status',15)||' '||RPAD('Count',10));
  print_out_msg(RPAD('=',12,'=')||' '||RPAD('=',15,'=')||' '||rpad('=',10,'='));
  OPEN hdr_count_cur;
  FETCH hdr_count_cur BULK COLLECT INTO stats_tab;
  CLOSE hdr_count_cur;
  FOR indx IN 1..stats_tab.COUNT
  LOOP
    print_out_msg(RPAD('PO Headers',12)||' '||RPAD(stats_tab(indx).record_status,15)||' '||RPAD(stats_tab(indx).count,10));
  END LOOP;
  OPEN line_count_cur;
  FETCH line_count_cur BULK COLLECT INTO stats_tab;
  CLOSE line_count_cur;
  FOR indx IN 1..stats_tab.COUNT
  LOOP
    print_out_msg(RPAD('Lines',12)||' '||RPAD(stats_tab(indx).record_status,15)||' '||RPAD(stats_tab(indx).count,10));
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  print_debug_msg ('Report Child Program Stats failed'||SUBSTR(sqlerrm,1,150),TRUE);
END report_child_program_stats;
-- +============================================================================================+
-- |  Name   : update_child                                                                 |
-- |  Description: This procedure reads data from the staging and loads into PO interface       |
-- |      OD PO POM Inbound Update(Child)        |
-- =============================================================================================|
PROCEDURE update_child(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_batch_id NUMBER ,
    p_debug    VARCHAR2)
AS
  CURSOR upd_lines_cur
  IS
    SELECT stg.record_line_id ,
      stg.record_id ,
      stg.process_code ,
      stg.po_number ,
      stg.line_num ,
      stg.item ,
      stg.quantity ,
      stg.line_reference_num ,
      stg.unit_price ,
      stg.record_status ,
      stg.error_description,
	  stg.error_column,
	  stg.error_value,
      stg.attribute5
    FROM xx_po_pom_lines_int_stg stg
    WHERE stg.batch_id     = p_batch_id
    AND stg.record_status IS NULL
    AND stg.process_code  IN('U','D');
TYPE upd_lines
IS
  TABLE OF upd_lines_cur%ROWTYPE INDEX BY PLS_INTEGER;
  CURSOR get_org_cur(p_po_number VARCHAR2, p_line_number VARCHAR2)
  IS
    SELECT poh.po_header_id,
	  poh.org_id,
      poh.revision_num,
	  pol.po_line_id,
      pol.quantity,
      pol.unit_price,
	  pol.item_id,
	  pol.closed_code,
	  pol.closed_date,
	  poh.closed_code,
	  poh.closed_date
    FROM po_headers_all poh,
      po_lines_all pol
    WHERE poh.segment1   = p_po_number
    AND poh.po_header_id = pol.po_header_id
    AND pol.line_num     = p_line_number;

  CURSOR reconcile_po_line_item_cur(c_inv_item_id NUMBER)
  IS
	SELECT msi.segment1
	FROM mtl_system_items_b msi
	WHERE msi.inventory_item_id = c_inv_item_id
	  ANd msi.organization_id = 441;

  CURSOR chk_po_status_cur(p_po_number VARCHAR2)
  IS
    SELECT poh.authorization_status
    FROM po_headers_all poh
    WHERE 1          =1
    AND poh.segment1 = p_po_number;
  l_upd_lines_tab UPD_LINES;
  indx            NUMBER;
  ln_batch_size   NUMBER := 1000;
  ln_result       NUMBER;
  lc_po_status    VARCHAR2(100);
  ln_org_id       NUMBER;
  ln_revision_num NUMBER;
  ln_quantity     NUMBER;
  ln_unit_price   NUMBER;
  ln_item_id      NUMBER;
  l_api_errors PO_API_ERRORS_REC_TYPE;
  lc_error_loc        VARCHAR2(100) := 'XX_PO_POM_INT_PKG.UPDATE_CHILD';
  ln_error_idx        NUMBER;
  ln_err_count        NUMBER;
  ln_count            NUMBER;
  ln_upd_count        NUMBER := 0;
  ln_nochanges_count  NUMBER := 0;
  ln_upd_err_count    NUMBER := 0;
  ln_cancel_count     NUMBER := 0;
  ln_cancel_err_count NUMBER := 0;
  ln_tot_count        NUMBER := 0;
  lc_return_status    VARCHAR2(1);
  lc_error_msg        VARCHAR2(2000);
  data_exception      EXCEPTION;
  lc_ebs_item         VARCHAR2(150);

  l_result			  VARCHAR2(30);
  ln_po_header_id	  po_headers_all.po_header_id%TYPE;
  ln_po_line_id  	  po_lines_all.po_line_id%TYPE;
  lv_result_code    VARCHAR2(1000);
  lc_close_status   BOOLEAN;
  lc_hdr_closedc	po_headers_all.closed_code%TYPE;
  lc_hdr_closedd	po_headers_all.closed_date%TYPE;
  lc_line_closedc	po_lines_all.closed_code%TYPE;
  lc_line_closedd	po_lines_all.closed_date%TYPE;


BEGIN
  gc_debug      := p_debug;
  gn_request_id := fnd_global.conc_request_id;
  gn_user_id    := fnd_global.user_id;
  gn_login_id   := fnd_global.login_id;
  gn_resp_id	:= fnd_global.resp_id;
  gn_resp_appl_id := fnd_global.resp_appl_id;
  print_debug_msg ('Start Update child' ,TRUE);
  OPEN upd_lines_cur;
  LOOP
    FETCH upd_lines_cur BULK COLLECT INTO l_upd_lines_tab LIMIT ln_batch_size;
    EXIT
  WHEN l_upd_lines_tab.COUNT = 0;
    FOR indx IN l_upd_lines_tab.FIRST..l_upd_lines_tab.LAST
    LOOP
      BEGIN
        print_debug_msg ('Processing Record_Line_id=['||l_upd_lines_tab(indx).record_line_id||'], PO=['||l_upd_lines_tab(indx).po_number||']' ,FALSE);
        ln_org_id := NULL;
		ln_quantity := 0;
		ln_unit_price := 0;
		ln_item_id := NULL;
        OPEN get_org_cur(l_upd_lines_tab(indx).po_number,l_upd_lines_tab(indx).line_num);
        FETCH get_org_cur INTO ln_po_header_id, ln_org_id,ln_revision_num, ln_po_line_id, ln_quantity,ln_unit_price, ln_item_id, lc_line_closedc, lc_line_closedd,lc_hdr_closedc, lc_hdr_closedd;
        CLOSE get_org_cur;
        IF ln_org_id IS NULL THEN
          print_debug_msg ('PO Line Number does not exists PO=['||l_upd_lines_tab(indx).po_number||'], Line_number=['||l_upd_lines_tab(indx).line_num||']',FALSE);
          l_upd_lines_tab(indx).record_status     := 'E';
          l_upd_lines_tab(indx).error_description := 'PO Line Number does not exists PO=['||l_upd_lines_tab(indx).po_number||'], Line_number=['||l_upd_lines_tab(indx).line_num||']';
		  l_upd_lines_tab(indx).error_column      := 'LINE_NUM';
		  l_upd_lines_tab(indx).error_value       := l_upd_lines_tab(indx).line_num;
		  ln_upd_err_count := ln_upd_err_count + 1;

			l_result := NULL;
		    XX_PO_POM_INT_PKG. valid_and_mark_missed_po_int(p_source => 'NA-POINTR'
		   		,p_source_record_id => l_upd_lines_tab(indx).record_line_id
		   		,p_po_number => l_upd_lines_tab(indx).po_number
		   		,p_po_line_num => l_upd_lines_tab(indx).line_num
		   		,p_result  => l_result);

			IF (l_result IS NULL OR l_result <> 'S') THEN
					print_debug_msg ('XX_PO_POM_INT_PKG. valid_and_mark_missed_po_int() failed for PO Line Number : PO=['||l_upd_lines_tab(indx).po_number||'], Line_number=['||l_upd_lines_tab(indx).line_num||']',TRUE);
			END IF;
          raise data_exception;
        END IF;

        lc_po_status := NULL;
        OPEN chk_po_status_cur(l_upd_lines_tab(indx).po_number);
        FETCH chk_po_status_cur INTO lc_po_status;
        CLOSE chk_po_status_cur;
        IF l_upd_lines_tab(indx).process_code = 'U' AND lc_po_status IN ('IN PROCESS','PRE-APPROVED','CANCELLED') THEN
          print_debug_msg ('PO status may be Pre-approved,  In-Process,  Frozen, Cancelled or Finally closed. PO=['||l_upd_lines_tab(indx).po_number||'], Line_number=['||l_upd_lines_tab(indx).line_num||']',FALSE);
          l_upd_lines_tab(indx).record_status     := 'E';
          l_upd_lines_tab(indx).error_description := 'PO status may be Pre-approved,  In-Process,  Frozen, Cancelled or Finally closed. PO=['||l_upd_lines_tab(indx).po_number||'], Line_number=['||l_upd_lines_tab(indx).line_num||']';
		  l_upd_lines_tab(indx).error_column      := 'PO_NUMBER';
		  l_upd_lines_tab(indx).error_value       := l_upd_lines_tab(indx).po_number;
          raise data_exception;
        END IF;

        lc_ebs_item := NULL;
        OPEN reconcile_po_line_item_cur(ln_item_id);
        FETCH reconcile_po_line_item_cur INTO lc_ebs_item;
        CLOSE reconcile_po_line_item_cur;

		IF (
			(lc_ebs_item IS NULL)
				OR
			(ltrim(lc_ebs_item, '0') <> ltrim(l_upd_lines_tab(indx).item ,'0') )
		    ) THEN
          print_debug_msg ('Item '||l_upd_lines_tab(indx).item||' of po line number '||l_upd_lines_tab(indx).line_num||' does not match with existed EBS PO line item '||lc_ebs_item||'.', TRUE);
          l_upd_lines_tab(indx).record_status     := 'E';
          l_upd_lines_tab(indx).error_description := 'Item '||l_upd_lines_tab(indx).item||' does not match with existed EBS po line item '||lc_ebs_item;
		  l_upd_lines_tab(indx).error_column      := 'ITEM';
		  l_upd_lines_tab(indx).error_value       := l_upd_lines_tab(indx).item;
          raise data_exception;
		END IF;

        IF l_upd_lines_tab(indx).quantity = 0 THEN
			l_upd_lines_tab(indx).quantity := 0.0000000001;
		END IF;

        IF l_upd_lines_tab(indx).process_code = 'U' THEN
          print_debug_msg ('Check if quantity or price is different for line num =['||l_upd_lines_tab(indx).line_num||']' ,FALSE);
          IF (ln_quantity                            = l_upd_lines_tab(indx).quantity) AND (ln_unit_price = l_upd_lines_tab(indx).unit_price) THEN
            l_upd_lines_tab(indx).record_status     := 'I';
            --l_upd_lines_tab(indx).error_description := 'No Changes';
			l_upd_lines_tab(indx).attribute5		:= l_upd_lines_tab(indx).attribute5||':No Changes - skip PO processing';
            ln_nochanges_count                      := ln_nochanges_count + 1;
          ELSE
            print_debug_msg ('Update Line Num =['||l_upd_lines_tab(indx).line_num||']' ,FALSE);
            --user_id SVC_ESP_FIN 90102
            --resp_id Purchasing Super User 20707
			--          OD (US) PO Trade Batch Jobs  53148
            --resp_app_id po - 201
			--fnd_global.apps_initialize (90102, 53148, 201);
            fnd_global.apps_initialize (gn_user_id, gn_resp_id, gn_resp_appl_id);

            mo_global.init('PO');
            mo_global.set_policy_context('S',ln_org_id);
            ln_result := PO_CHANGE_API1_S.update_po ( x_po_number => l_upd_lines_tab(indx).po_number, x_release_number => NULL, x_revision_number => ln_revision_num, x_line_number => l_upd_lines_tab(indx).line_num, x_shipment_number => NULL, new_quantity => l_upd_lines_tab(indx).quantity, new_price => l_upd_lines_tab(indx).unit_price, new_promised_date => NULL, new_need_by_date => NULL, launch_approvals_flag => 'Y', --'N',
            update_source => 'API', version => '1.0', x_override_date => NULL, x_api_errors => l_api_errors, p_buyer_name => NULL, p_secondary_quantity => NULL, p_preferred_grade => NULL, p_org_id => ln_org_id);
            print_debug_msg ('Result=['||TO_CHAR(ln_result)||']' ,FALSE);
            IF (ln_result <> 1) THEN
              --Display the errors
              l_upd_lines_tab(indx).record_status := 'E';
              print_debug_msg ('Display Errors' ,FALSE);
              FOR i IN 1..l_api_errors.message_text.COUNT
              LOOP
                print_debug_msg (l_api_errors.message_text(i) ,FALSE);
                l_upd_lines_tab(indx).error_description := SUBSTR((l_upd_lines_tab(indx).error_description || l_api_errors.message_text(i)),1,2000);
				l_upd_lines_tab(indx).error_column      := 'UPDATE_API';
				--l_upd_lines_tab(indx).error_value       := ;
              END LOOP;
              ln_upd_err_count := ln_upd_err_count + 1;
            ELSE
              l_upd_lines_tab(indx).record_status     := 'I';
              l_upd_lines_tab(indx).error_description := '';
              ln_upd_count                            := ln_upd_count + 1;
            END IF;
          END IF;
        END IF;
        IF l_upd_lines_tab(indx).process_code = 'D' THEN
          print_debug_msg ('Cancel Line Num =['||l_upd_lines_tab(indx).line_num||']' ,FALSE);
          --user_id SVC_ESP_FIN 90102
          --resp_id Purchasing Super User 20707
		  --        OD (US) PO Trade Batch Jobs  53148
          --resp_app_id po - 201
		  -- fnd_global.apps_initialize (90102, 53148, 201);

          fnd_global.apps_initialize (gn_user_id, gn_resp_id, gn_resp_appl_id);

          mo_global.init('PO');
          mo_global.set_policy_context('S',ln_org_id);
          --Call the Cancel API for PO number

		 -- 1.4
		 lv_result_code := NULL;

		 print_debug_msg ('Closed line details '||ln_po_line_id||':'||lc_hdr_closedc||':'||lc_hdr_closedd||':'||lc_line_closedc||':'||lc_line_closedd , TRUE);
		 -- IF po line is already closed then skip the call to CLOSE API and mark the record as 'I' and update attribute

		 IF lc_line_closedc = 'CLOSED' THEN
			l_upd_lines_tab(indx).record_status     := 'I';
			l_upd_lines_tab(indx).attribute5		:= l_upd_lines_tab(indx).attribute5||':Line already closed - skip PO processing';
            ln_nochanges_count                      := ln_nochanges_count + 1;
		 ELSE
			 lc_close_status := PO_ACTIONS.CLOSE_PO(p_docid        => ln_po_header_id,
									   p_doctyp       => 'PO',
									   p_docsubtyp    => 'STANDARD',
									   p_lineid       => ln_po_line_id,
									   p_shipid       => NULL,
									   p_action       => 'CLOSE',
									   p_reason       => 'PO Line Canceled in POM',
									   p_calling_mode => 'PO',
									   p_conc_flag    => 'N',
									   p_return_code  => lv_result_code,
									   p_auto_close   => 'N'
									  );

			  -- Check the return status

			  print_debug_msg ('lv_result_code is  :'||lv_result_code ,TRUE);
			  IF (lc_close_status and lv_result_code IS NULL) THEN
				l_upd_lines_tab(indx).record_status     := 'I';
				l_upd_lines_tab(indx).error_description := '';
				ln_cancel_count                         := ln_cancel_count + 1;
			  ELSE
				print_debug_msg ('Cannot close the po because of lv_result_code is  :'||lv_result_code , TRUE);

				l_upd_lines_tab(indx).record_status     := 'E';
				l_upd_lines_tab(indx).error_description := 'Cannot close the po because : '||lv_result_code;
				l_upd_lines_tab(indx).error_column      := 'CLOSE_API';
				ln_cancel_err_count                     := ln_cancel_err_count + 1;
			  END IF;

			  COMMIT;
		 END IF;  -- IF c_line_closedc = 'CLOSED' THEN
        END IF;  -- IF l_upd_lines_tab(indx).process_code = 'D'
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg ('ERROR Record_Line_id=['||l_upd_lines_tab(indx).record_line_id||'], '||SUBSTR(sqlerrm,1,250),TRUE);
        l_upd_lines_tab(indx).record_status     := 'E';
        l_upd_lines_tab(indx).error_description := l_upd_lines_tab(indx).error_description || SUBSTR(sqlerrm,1,250);
      END;
      ln_tot_count := ln_tot_count + 1;
    END LOOP;
    BEGIN
      print_debug_msg('Starting update of xx_po_pom_lines_int_stg #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
      FORALL i IN l_upd_lines_tab.FIRST..l_upd_lines_tab.LAST
      SAVE EXCEPTIONS
      UPDATE xx_po_pom_lines_int_stg
      SET record_status    = l_upd_lines_tab(i).record_status ,
        error_description  = REPLACE(REPLACE(l_upd_lines_tab(i).error_description, CHR(13)), CHR(10)) ,
		attribute5         = l_upd_lines_tab(i).attribute5,
				error_column       = l_upd_lines_tab(i).error_column ,
				error_value        = l_upd_lines_tab(i).error_value ,
        last_update_date   = sysdate ,
        last_updated_by    = gn_user_id ,
        last_update_login  = gn_login_id
      WHERE record_line_id = l_upd_lines_tab(i).record_line_id;
    EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg('Bulk Exception raised',TRUE);
      ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
      FOR i IN 1..ln_err_count
      LOOP
        ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
        lc_error_msg := SUBSTR('Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
        log_exception ('OD PO POM Inbound Update(Child)',lc_error_loc,lc_error_msg);
        print_debug_msg('Record_Line_id=['||TO_CHAR(l_upd_lines_tab(ln_error_idx).record_line_id)||'], Error msg=['||lc_error_msg||']',TRUE);
      END LOOP; -- bulk_err_loop FOR UPDATE
    END;
    COMMIT;
  END LOOP;
  CLOSE upd_lines_cur;
  print_debug_msg('Updating status of headers with update only records(process code=U records only)',FALSE);
  --Update header records with update/cancel lines and has errors.
  UPDATE xx_po_pom_hdr_int_stg h
  SET h.record_status   = 'E' ,
    h.error_description = 'Line Update/Close Failed' ,
    last_update_date    = sysdate ,
    last_updated_by     = gn_user_id ,
    last_update_login   = gn_login_id
  WHERE h.process_code IN('U','T')
  AND EXISTS
    (SELECT 'x'
    FROM xx_po_pom_lines_int_stg l
    WHERE l.record_id   = h.record_id
    AND l.po_number     = h.po_number
    AND l.batch_id      = p_batch_id
    AND l.process_code IN('U','D')
    AND l.record_status = 'E'
    );
  ln_count := SQL%ROWCOUNT;
  print_debug_msg(TO_CHAR(ln_count)|| ' header record(s) updated with error status',FALSE);
  --Update headers records with only update/close lines and processed.
  UPDATE xx_po_pom_hdr_int_stg h
  SET h.record_status   = 'I' ,
    h.error_description = '' ,
    last_update_date    = sysdate ,
    last_updated_by     = gn_user_id ,
    last_update_login   = gn_login_id
  WHERE h.process_code IN('U','T')
  AND h.record_status  IS NULL
  AND EXISTS
    (SELECT 'x'
    FROM xx_po_pom_lines_int_stg l
    WHERE l.record_id   = h.record_id
    AND l.po_number     = h.po_number
    AND l.batch_id      = p_batch_id
    AND l.record_status = 'I'
    )
  AND NOT EXISTS
    (SELECT 'x'
    FROM xx_po_pom_lines_int_stg l
    WHERE l.po_number   = h.po_number
    AND l.record_id     = h.record_id
    AND l.record_status = 'E'
    );
  ln_count := SQL%ROWCOUNT;
  print_debug_msg(TO_CHAR(ln_count)|| ' header record(s) updated with interfaced status',FALSE);
  COMMIT;
  print_out_msg(TO_CHAR(ln_upd_count)||' line record(s) updated');
  print_out_msg(TO_CHAR(ln_cancel_count)||' line record(s) cancelled');
  print_out_msg(TO_CHAR(ln_upd_err_count)||' line record(s) completed in error during update');
  print_out_msg(TO_CHAR(ln_cancel_err_count)||' line record(s) completed in error during cancel');
  print_out_msg(TO_CHAR(ln_nochanges_count)||' update line record(s) did not have any changes');
  print_out_msg(TO_CHAR(ln_tot_count)||' total line record(s) processed');
EXCEPTION
WHEN OTHERS THEN
  lc_error_msg := SUBSTR(sqlerrm,1,250);
  print_debug_msg ('ERROR Upd Child- '||lc_error_msg,TRUE);
  log_exception ('OD PO POM Inbound Update(Child)', lc_error_loc, lc_error_msg);
  p_retcode := 2;
  p_errbuf  := lc_error_msg;
END update_child;
-- +============================================================================================+
-- |  Name   : interface_child                                                              |
-- |  Description: This procedure reads data from the staging and loads into PO interface       |
-- |      OD PO POM Inbound Interface(Child)        |
-- =============================================================================================|
PROCEDURE interface_child(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_batch_id NUMBER ,
    p_debug    VARCHAR2)
AS
  CURSOR header_cur
  IS
    SELECT stg.record_id ,
      stg.batch_id ,
      stg.process_code ,
      stg.po_number ,
      stg.currency_code ,
      stg.vendor_site_code ,
      stg.loc_id ,
      stg.fob_code ,
      stg.freight_code ,
      stg.note_to_vendor ,
      stg.note_to_receiver ,
      stg.status_code ,
      stg.import_manual_po ,
      stg.date_entered ,
      stg.date_changed ,
      stg.rate_type ,
      stg.distribution_code ,
      stg.po_type ,
      stg.num_lines ,
      stg.cost ,
      stg.units_ord_rec_shpd ,
      stg.lbs ,
      stg.net_po_total_cost ,
      stg.drop_ship_flag ,
      stg.ship_via ,
      stg.back_orders ,
      stg.order_dt ,
      stg.ship_dt ,
      stg.arrival_dt ,
      stg.cancel_dt ,
      stg.release_date ,
      stg.revision_flag ,
      stg.last_ship_dt ,
      stg.last_receipt_dt ,
      stg.disc_pct ,
      stg.disc_days ,
      stg.net_days ,
      stg.allowance_basis ,
      stg.allowance_dollars ,
      stg.allowance_percent ,
      stg.pom_created_by ,
      stg.time_entered ,
      stg.program_entered_by ,
      stg.pom_changed_by ,
      stg.changed_time ,
      stg.program_changed_by ,
      stg.cust_id ,
      stg.cust_order_nbr ,
      stg.cust_order_sub_nbr ,
      stg.vendor_doc_num ,
      stg.record_status ,
      stg.error_description ,
	  stg.error_column ,
	  stg.error_value ,
      hru.location_id ,
      hru.organization_id
    FROM xx_po_pom_hdr_int_stg stg,
      hr_all_organization_units hru
    WHERE stg.batch_id                = p_batch_id
    AND hru.attribute1(+)             = to_number(stg.loc_id)
    AND hru.date_from(+)             <= sysdate
    AND NVL(hru.date_to(+),sysdate+1) > sysdate
    AND stg.record_status            IS NULL;
TYPE header
IS
  TABLE OF header_cur%ROWTYPE INDEX BY PLS_INTEGER;
  CURSOR lines_cur (p_record_id NUMBER,p_po_number VARCHAR2)
  IS
    SELECT stg.record_line_id ,
      stg.record_id ,
      stg.process_code ,
      stg.po_number ,
      stg.line_num ,
      stg.item ,
      stg.quantity ,
      stg.ship_to_location ,
      stg.need_by_date ,
      stg.promised_date ,
      stg.line_reference_num ,
      stg.uom_code ,
      stg.unit_price ,
      stg.shipmentnumber ,
      stg.dept ,
      stg.class ,
      stg.vendor_product_code ,
      stg.extended_cost ,
      stg.qty_shipped ,
      stg.qty_received ,
      stg.seasonal_large_order ,
      stg.record_status ,
      stg.error_description ,
	  stg.error_column ,
	  stg.error_value ,
      hru.location_id ,
      hru.organization_id
    FROM xx_po_pom_lines_int_stg stg ,
      hr_all_organization_units hru
    WHERE stg.record_id               = p_record_id
    AND stg.po_number                 = p_po_number
    AND hru.attribute1(+)             = to_number(stg.ship_to_location)
    AND stg.process_code             IN('I','M')
    AND hru.date_from(+)             <= sysdate
    AND NVL(hru.date_to(+),sysdate+1) > sysdate
    AND stg.record_status            IS NULL;
TYPE lines
IS
  TABLE OF lines_cur%ROWTYPE INDEX BY PLS_INTEGER;
  CURSOR check_po_cur(p_po_number VARCHAR2)
  IS
    SELECT poh.po_header_id,
      poh.segment1,
      poh.revision_num,
      poh.authorization_status,
      poh.org_id,
      poh.closed_code,
      poh.terms_id
    FROM po_headers_all poh
    WHERE poh.segment1       = p_po_number
    AND poh.type_lookup_code = 'STANDARD';
  check_po_rec check_po_cur%ROWTYPE;
  CURSOR check_po_int_cur(p_po_number VARCHAR2)
  IS
    SELECT poi.document_num
    FROM po_headers_interface poi
    WHERE poi.document_num = p_po_number;
  CURSOR check_vendor_cur(p_vendor_site_code VARCHAR2)
  IS
    SELECT supa.vendor_id,
      supa.vendor_site_id,
      supa.org_id,
      supa.attribute8 vendor_site_category
    FROM ap_supplier_sites_all supa
    WHERE ltrim(supa.vendor_site_code_alt,'0') = ltrim(p_vendor_site_code,'0')
    AND supa.purchasing_site_flag              = 'Y'
    AND NVL(supa.inactive_date,sysdate)       >= TRUNC(sysdate);
  CURSOR uom_cur(p_uom VARCHAR2)
  IS
    SELECT target_value1
    FROM xx_fin_translatedefinition xtd,
      xx_fin_translatevalues xtv
    WHERE xtd.translation_name = 'PO_POM_UOM'
    AND xtd.translate_id       = xtv.translate_id
    AND source_value1          = p_uom;
  CURSOR check_item_cur(p_item VARCHAR2,p_organization_id NUMBER)
  IS
    SELECT inventory_item_id,
      primary_uom_code
    FROM mtl_system_items_b
    WHERE segment1      = p_item
    AND organization_id = p_organization_id;
  CURSOR org_cur
  IS
    SELECT DISTINCT org_id
    FROM po_headers_interface
    WHERE batch_id            = p_batch_id
    AND interface_source_code = 'NA-POINTR'
    AND org_id               IS NOT NULL;
TYPE org
IS
  TABLE OF org_cur%ROWTYPE INDEX BY PLS_INTEGER;
  CURSOR chk_po_status_cur(p_po_number VARCHAR2)
  IS
    SELECT poh.authorization_status
    FROM po_headers_all poh
    WHERE 1          =1
    AND poh.segment1 = p_po_number;
  CURSOR check_item_cat_cur(p_item VARCHAR2,p_organization_id NUMBER)
  IS
    SELECT mic.category_id
    FROM mtl_categories_b mcb ,
      mtl_item_categories mic ,
      mtl_system_items_b msi
    WHERE 1                   =1
    AND msi.organization_id   =p_organization_id
    AND msi.segment1          =p_item
    AND mic.organization_id   =msi.organization_id
    AND mic.inventory_item_id =msi.inventory_item_id
    AND mcb.category_id       =mic.category_id
    AND mcb.structure_id      =201
    AND mcb.enabled_flag      = 'Y'
    AND (mcb.disable_date    IS NULL
    OR mcb.disable_date      >= sysdate)
    AND (mcb.end_date_active IS NULL
    OR mcb.end_date_active   >= sysdate);
  CURSOR check_po_line_cur(p_po_number VARCHAR2,p_line_num NUMBER)
  IS
    SELECT pol.line_num
    FROM po_headers_all poh,
      po_lines_all pol
    WHERE poh.segment1       = p_po_number
    AND poh.type_lookup_code = 'STANDARD'
    AND Poh.po_header_id     =pol.po_header_id
    AND pol.line_num         =p_line_num;
  l_header_tab HEADER;
  l_lines_tab LINES;
  l_org_tab ORG;
  indx                NUMBER;
  l_indx              NUMBER;
  o_indx              NUMBER;
  ln_batch_size       NUMBER := 250;
  lc_po_status        VARCHAR2(100);
  lc_return_code      VARCHAR2(100);
  lc_document_num     VARCHAR2(30);
  lb_poclose_result   BOOLEAN;
  lc_lines_validation VARCHAR2(30);
  lc_uom_code mtl_system_items_b.primary_uom_code%TYPE;
  lc_item_uom_code mtl_system_items_b.primary_uom_code%TYPE;
  lc_line_num                    NUMBER;
  ln_item_id                     NUMBER;
  lc_error_msg                   VARCHAR2(1000);
  lc_error_loc                   VARCHAR2(100) := 'XX_PO_POM_INT_PKG.INTERFACE_CHILD';
  lc_hdr_action                  VARCHAR2(25);
  ln_category_id                 NUMBER;
  ln_ship_to_location_id         NUMBER;
  lc_ship_to_location            VARCHAR2(200);
  lc_req_data                    VARCHAR2(30);
  ln_job_id                      NUMBER;
  ln_interface_line_id           NUMBER;
  ln_interface_header_id         NUMBER;
  ln_distributions_interface_id  NUMBER;
  ln_line_locations_interface_id NUMBER;
  ln_child_request_status        VARCHAR2(1) := NULL;
  lc_attribute_category          VARCHAR2(50);
  ln_vendor_id                   NUMBER;
  ln_vendor_site_id              NUMBER;
  ln_terms_id                    NUMBER;
  ln_org_id                      NUMBER;
  lc_vendor_site_category        VARCHAR2(150);
  lc_receipt_required_flag       VARCHAR2(10);
  lc_lob                         VARCHAR2(50);
  ln_count                       NUMBER;
  ln_err_count                   NUMBER;
  ln_error_idx                   NUMBER;
  data_exception                 EXCEPTION;
BEGIN
  gc_debug      := p_debug;
  gn_request_id := fnd_global.conc_request_id;
  gn_user_id    := fnd_global.user_id;
  gn_login_id   := fnd_global.login_id;
  print_debug_msg ('Start interface_child' ,TRUE);
  --Get value of global variable. It is null initially.
  lc_req_data := fnd_conc_global.request_data;
  -- req_date will be null for first time parent scan by concurrent manager.
  IF (lc_req_data IS NULL) THEN
    OPEN header_cur;
    LOOP
      FETCH header_cur BULK COLLECT INTO l_header_tab LIMIT ln_batch_size;
      EXIT
    WHEN l_header_tab.COUNT = 0;
      FOR indx IN l_header_tab.FIRST..l_header_tab.LAST
      LOOP
        BEGIN
          print_debug_msg ('Start Validation - RecordId=['||l_header_tab(indx).record_id|| '], PO=['||l_header_tab(indx).po_number||']',TRUE);
          print_debug_msg ('Check PO Status - RecordId=['||l_header_tab(indx).record_id||']',FALSE);
          lc_po_status := NULL;
          OPEN chk_po_status_cur(l_header_tab(indx).po_number);
          FETCH chk_po_status_cur INTO lc_po_status;
          CLOSE chk_po_status_cur;
          print_debug_msg ('Check if PO exists - RecordId=['||l_header_tab(indx).record_id||']',FALSE);
          check_po_rec.po_header_id := NULL;
          OPEN check_po_cur(l_header_tab(indx).po_number);
          FETCH check_po_cur INTO check_po_rec;
          CLOSE check_po_cur;
          IF check_po_rec.po_header_id IS NOT NULL AND l_header_tab(indx).process_code = 'I' THEN
            print_debug_msg ('Duplicate PO -  RecordId=['||l_header_tab(indx).record_id||']',FALSE);
            l_header_tab(indx).record_status     := 'D';
            l_header_tab(indx).error_description := 'Duplicate PO';
			l_header_tab(indx).error_column := 'PO_NUMBER';
			l_header_tab(indx).error_value  := l_header_tab(indx).po_number;
            RAISE data_exception;
          ELSIF check_po_rec.po_header_id IS NULL AND l_header_tab(indx).process_code IN('U','T') THEN
            print_debug_msg ('PO does not exists to add line/update terms - RecordId=['||l_header_tab(indx).record_id||']',FALSE);
            l_header_tab(indx).record_status     := 'E';
            l_header_tab(indx).error_description := 'PO does not exists';
			l_header_tab(indx).error_column := 'PO_NUMBER';
			l_header_tab(indx).error_value  := l_header_tab(indx).po_number;
            RAISE data_exception;
          ELSIF check_po_rec.po_header_id IS NOT NULL AND l_header_tab(indx).process_code = 'T' THEN
            /*Check if its terms update*/
            -- validate/derive terms
            ln_terms_id := NULL;
            BEGIN
              SELECT atl.term_id
              INTO ln_terms_id
              FROM ap_terms_lines atl
              WHERE NVL(atl.discount_percent,0) = l_header_tab(indx).disc_pct*100
              AND NVL(atl.discount_days,0)      = l_header_tab(indx).disc_days
              AND NVL(atl.due_days,0)           = l_header_tab(indx).net_days
              AND EXISTS
                (SELECT '1'
                FROM ap_terms at
                WHERE at.term_id                     = atl.term_id
                AND at.enabled_flag                  = 'Y'
                AND NVL(start_date_active, sysdate) <= sysdate
                AND NVL(end_date_active, sysdate)   >= sysdate
                );
            EXCEPTION
            WHEN no_data_found THEN
              l_header_tab(indx).record_status     := 'E';
              l_header_tab(indx).error_description := l_header_tab(indx).error_description|| 'Term Validation : Invalid terms in hdr=['||l_header_tab(indx).disc_pct*100||'/'|| l_header_tab(indx).disc_days||'N'|| l_header_tab(indx).net_days||']';
			  l_header_tab(indx).error_column := l_header_tab(indx).error_column||'/DISC_PCT-DISC_DAYS-NET_DAYS';
			  l_header_tab(indx).error_value  := l_header_tab(indx).error_value||'/'||l_header_tab(indx).disc_pct||'-'||l_header_tab(indx).disc_days||'-'||l_header_tab(indx).net_days;
              print_debug_msg ('Record_id=['||TO_CHAR(l_header_tab(indx).record_id)||'],
Invalid terms in hdr=['||l_header_tab(indx).disc_pct               *100||'/'|| l_header_tab(indx).disc_days||'N'||l_header_tab(indx).net_days||']',FALSE);
              RAISE data_exception;
            WHEN TOO_MANY_ROWS THEN
              l_header_tab(indx).record_status     := 'E';
              l_header_tab(indx).error_description := l_header_tab(indx).error_description|| 'Term Validation : Many terms in EBS for hdr=['||l_header_tab(indx).disc_pct*100||'/'|| l_header_tab(indx).disc_days||'N'|| l_header_tab(indx).net_days||']';
			  l_header_tab(indx).error_column := l_header_tab(indx).error_column||'/DISC_PCT-DISC_DAYS-NET_DAYS';
			  l_header_tab(indx).error_value  := l_header_tab(indx).error_value||'/'||l_header_tab(indx).disc_pct||'-'||l_header_tab(indx).disc_days||'-'||l_header_tab(indx).net_days;
              print_debug_msg ('Record_id=['||TO_CHAR(l_header_tab(indx).record_id)||'],
Many terms in EBS for hdr=['||l_header_tab(indx).disc_pct               *100||'/'|| l_header_tab(indx).disc_days||'N'||l_header_tab(indx).net_days||']',FALSE);
              RAISE data_exception;
            WHEN OTHERS THEN
              l_header_tab(indx).record_status     := 'E';
              l_header_tab(indx).error_description := l_header_tab(indx).error_description|| 'Term Validation : Terms Valdation exception for hdr=['||l_header_tab(indx).disc_pct*100||'/'|| l_header_tab(indx).disc_days||'N'|| l_header_tab(indx).net_days||'] is '||SUBSTR(SQLERRM, 1, 100);
			  l_header_tab(indx).error_column := l_header_tab(indx).error_column||'/DISC_PCT-DISC_DAYS-NET_DAYS';
			  l_header_tab(indx).error_value  := l_header_tab(indx).error_value||'/'||l_header_tab(indx).disc_pct||'-'||l_header_tab(indx).disc_days||'-'||l_header_tab(indx).net_days;
              print_debug_msg ('Record_id=['||TO_CHAR(l_header_tab(indx).record_id)||'],
Terms Valdation exception for hdr=['||l_header_tab(indx).disc_pct           *100||'/'|| l_header_tab(indx).disc_days||'N'||l_header_tab(indx).net_days||'] is '||SUBSTR(SQLERRM, 1, 100),FALSE);
              RAISE data_exception;
            END;
            IF check_po_rec.po_header_id IS NOT NULL AND check_po_rec.closed_code <> 'OPEN' THEN
              print_debug_msg ('PO not Open',FALSE);
              l_header_tab(indx).record_status     := 'E';
              l_header_tab(indx).error_description := 'PO is not in OPEN status for terms update';
			  l_header_tab(indx).error_column := 'PO_NUMBER';
			  l_header_tab(indx).error_value  := l_header_tab(indx).po_number;
              raise data_exception;
            ELSIF check_po_rec.po_header_id IS NOT NULL AND check_po_rec.closed_code = 'OPEN' THEN
              IF check_po_rec.terms_id      <> ln_terms_id THEN
                print_debug_msg ('Updating terms on PO',FALSE);
                UPDATE po_headers
                SET terms_id        = ln_terms_id ,
                  last_update_date  = sysdate ,
                  last_updated_by   = gn_user_id ,
                  last_update_login = gn_login_id
                WHERE po_header_id  = check_po_rec.po_header_id;
              END IF;
              --Check if the PO has any new lines.
              ln_count := NULL;
              SELECT COUNT(1)
              INTO ln_count
              FROM xx_po_pom_lines_int_stg
              WHERE record_id  = l_header_tab(indx).record_id
              AND process_code = 'I';
              IF ln_count      = 0 THEN
                UPDATE xx_po_pom_hdr_int_stg
                SET record_status   = 'I' ,
                  error_description = '' ,
                  last_update_date  = sysdate ,
                  last_updated_by   = gn_user_id ,
                  last_update_login = gn_login_id
                WHERE record_id     = l_header_tab(indx).record_id;
                COMMIT;
                CONTINUE;
              END IF;
            END IF;
          END IF; --process_code = 'T'
					/**  As we are Retrying the Interface errors(reset the record_status),
					we can skip this validation so that we retry from here.

          print_debug_msg ('Check if PO exists in PO Interface',FALSE);
          lc_document_num := NULL;
          OPEN check_po_int_cur(l_header_tab(indx).po_number);
          FETCH check_po_int_cur INTO lc_document_num;
          CLOSE check_po_int_cur;
          IF lc_document_num IS NOT NULL AND l_header_tab(indx).process_code = 'I' THEN
            print_debug_msg ('Duplicate PO exists in PO Interface -  RecordId=['||l_header_tab(indx).record_id||']',FALSE);
            l_header_tab(indx).record_status     := 'E';
            l_header_tab(indx).error_description := 'Duplicate PO exists in PO Interface';
						l_header_tab(indx).error_column := 'PO_NUMBER';
						l_header_tab(indx).error_value  := l_header_tab(indx).po_number;
            RAISE data_exception;
          END IF;
					**/
          IF l_header_tab(indx).process_code = 'I' THEN
            lc_hdr_action                   := 'ORIGINAL';
          ELSIF l_header_tab(indx).process_code IN('U','T') THEN
            lc_hdr_action := 'UPDATE';
          END IF;
          ---Validate/Derive vendor information
          ln_vendor_id            := NULL;
          ln_vendor_site_id       := NULL;
          ln_org_id               := NULL;
          lc_vendor_site_category := NULL;
          OPEN check_vendor_cur(l_header_tab(indx).vendor_site_code);
          FETCH check_vendor_cur
          INTO ln_vendor_id,
            ln_vendor_site_id,
            ln_org_id,
            lc_vendor_site_category;
          CLOSE check_vendor_cur;
          IF ln_vendor_id IS NULL THEN
            print_debug_msg ('Record_id=['||TO_CHAR(l_header_tab(indx).record_id)||'] Invalid Vendor=['||l_header_tab(indx).vendor_site_code||']',FALSE);
            l_header_tab(indx).record_status     := 'E';
            l_header_tab(indx).error_description := 'Invalid Vendor=['||l_header_tab(indx).vendor_site_code||']';
			l_header_tab(indx).error_column := 'VENDOR_SITE_CODE';
			l_header_tab(indx).error_value  := l_header_tab(indx).vendor_site_code;
          END IF;
          -- validate/derive ship to location
          IF l_header_tab(indx).location_id IS NULL THEN
            print_debug_msg ('Record_id=['||TO_CHAR(l_header_tab(indx).record_id)||'] Invalid Location=['||l_header_tab(indx).loc_id||']',FALSE);
            l_header_tab(indx).record_status     := 'E';
            l_header_tab(indx).error_description := l_header_tab(indx).error_description||', Invalid Location=['||l_header_tab(indx).loc_id||']';
			l_header_tab(indx).error_column := l_header_tab(indx).error_column||'/SHIP_TO_LOCATION';
			l_header_tab(indx).error_value  := l_header_tab(indx).error_value||'/NULL';
          ELSE
            ln_ship_to_location_id := l_header_tab(indx).location_id;
          END IF;
          -- validate/derive terms
          ln_terms_id := NULL;
          BEGIN
            SELECT atl.term_id
            INTO ln_terms_id
            FROM ap_terms_lines atl
            WHERE NVL(atl.discount_percent,0) = l_header_tab(indx).disc_pct*100
            AND NVL(atl.discount_days,0)      = l_header_tab(indx).disc_days
            AND NVL(atl.due_days,0)           = l_header_tab(indx).net_days
            AND EXISTS
              (SELECT '1'
              FROM ap_terms at
              WHERE at.term_id                     = atl.term_id
              AND at.enabled_flag                  = 'Y'
              AND NVL(start_date_active, sysdate) <= sysdate
              AND NVL(end_date_active, sysdate)   >= sysdate
              );
          EXCEPTION
          WHEN no_data_found THEN
				l_header_tab(indx).record_status     := 'E';
				l_header_tab(indx).error_description := l_header_tab(indx).error_description|| 'Hdr Validation : Invalid terms in hdr=['||l_header_tab(indx).disc_pct*100||'/'|| l_header_tab(indx).disc_days||'N'|| l_header_tab(indx).net_days||']';
				l_header_tab(indx).error_column := l_header_tab(indx).error_column||'/DISC_PCT-DISC_DAYS-NET_DAYS';
				l_header_tab(indx).error_value  := l_header_tab(indx).error_value||'/'||l_header_tab(indx).disc_pct||'-'||l_header_tab(indx).disc_days||'-'||l_header_tab(indx).net_days;

				print_debug_msg ('Record_id=['||TO_CHAR(l_header_tab(indx).record_id)||'],
	Invalid terms in hdr=['||l_header_tab(indx).disc_pct                *100||'/'|| l_header_tab(indx).disc_days||'N'||l_header_tab(indx).net_days||']',FALSE);
				RAISE data_exception;
          WHEN TOO_MANY_ROWS THEN
            l_header_tab(indx).record_status     := 'E';
            l_header_tab(indx).error_description := l_header_tab(indx).error_description|| 'Hdr Validation : Many terms in EBS for hdr=['||l_header_tab(indx).disc_pct*100||'/'|| l_header_tab(indx).disc_days||'N'|| l_header_tab(indx).net_days||']';
			l_header_tab(indx).error_column := l_header_tab(indx).error_column||'/DISC_PCT-DISC_DAYS-NET_DAYS';
			l_header_tab(indx).error_value  := l_header_tab(indx).error_value||'/'||l_header_tab(indx).disc_pct||'-'||l_header_tab(indx).disc_days||'-'||l_header_tab(indx).net_days;

            print_debug_msg ('Record_id=['||TO_CHAR(l_header_tab(indx).record_id)||'],
Many terms in EBS for hdr=['||l_header_tab(indx).disc_pct                *100||'/'|| l_header_tab(indx).disc_days||'N'||l_header_tab(indx).net_days||']',FALSE);
            RAISE data_exception;
          WHEN OTHERS THEN
            l_header_tab(indx).record_status     := 'E';
            l_header_tab(indx).error_description := l_header_tab(indx).error_description|| 'Hdr Validation : Terms Valdation exception for hdr=['||l_header_tab(indx).disc_pct*100||'/'|| l_header_tab(indx).disc_days||'N'|| l_header_tab(indx).net_days||'] is '||SUBSTR(SQLERRM, 1, 100);
			l_header_tab(indx).error_column := l_header_tab(indx).error_column||'/DISC_PCT-DISC_DAYS-NET_DAYS';
			l_header_tab(indx).error_value  := l_header_tab(indx).error_value||'/'||l_header_tab(indx).disc_pct||'-'||l_header_tab(indx).disc_days||'-'||l_header_tab(indx).net_days;
            print_debug_msg ('Record_id=['||TO_CHAR(l_header_tab(indx).record_id)||'],
Terms Valdation exception for hdr=['||l_header_tab(indx).disc_pct                *100||'/'|| l_header_tab(indx).disc_days||'N'||l_header_tab(indx).net_days||'] is '||SUBSTR(SQLERRM, 1, 100),FALSE);
            RAISE data_exception;
          END;
          IF l_header_tab(indx).record_status IS NULL THEN
            print_debug_msg ('Derive attribute_category and matching option',FALSE);
            --derive attribute_category and matching option - receipt required flag
            lc_attribute_category    := NULL;
            lc_receipt_required_flag := 'N';
            --Check if Front Door, Consignment
            IF lc_vendor_site_category    = 'TR-CON' THEN
              lc_attribute_category      := 'Consignment';
              lc_receipt_required_flag   := 'N';
            ELSIF lc_vendor_site_category = 'TR-IMP' THEN
              lc_attribute_category      := 'Direct Import';
              lc_receipt_required_flag   := 'N';
            ELSIF lc_vendor_site_category = 'TR-FRONTDOOR' THEN
              BEGIN
                SELECT a.segment6
                INTO lc_lob
                FROM mtl_parameters p ,
                  hr_locations l ,
                  gl_Code_combinations a
                WHERE l.inventory_organization_id = p.organization_id
                AND l.location_id                 = l_header_tab(indx).location_id
                AND a.code_Combination_id         = p.material_Account;
              EXCEPTION
              WHEN OTHERS THEN
                lc_lob := '10';
              END;
              IF lc_lob                   = '10' THEN
                lc_receipt_required_flag := 'N';
                lc_attribute_category    := 'FrontDoor Retail';
              ELSE
                lc_receipt_required_flag := 'Y';
                lc_attribute_category    := 'FrontDoor DC';
              END IF;
            ELSIF l_header_tab(indx).po_type = 'NC' AND l_header_tab(indx).drop_ship_flag = 'Y' THEN
              lc_attribute_category         := 'DropShip NonCode-SPL Order';
              lc_receipt_required_flag      := 'N';
            ELSIF l_header_tab(indx).po_type = 'NC' AND l_header_tab(indx).drop_ship_flag = 'N' THEN
              lc_attribute_category         := 'Non-Code';
              lc_receipt_required_flag      := 'Y';
            ELSIF l_header_tab(indx).po_type = 'NS' THEN
              lc_attribute_category         := 'New Store';
              lc_receipt_required_flag      := 'Y';
            ELSIF l_header_tab(indx).po_type = 'RE' THEN
              lc_attribute_category         := 'Replenishment';
              lc_receipt_required_flag      := 'Y';
            ELSIF l_header_tab(indx).po_type = 'SO' THEN
              lc_attribute_category         := 'DropShip NonCode-SPL Order';
              lc_receipt_required_flag      := 'N';
            ELSIF l_header_tab(indx).po_type = 'VW' THEN
              lc_attribute_category         := 'DropShip VW';
              lc_receipt_required_flag      := 'N';
            ELSE --default attribute_category and receipt required flag
              lc_attribute_category    := 'Trade';
              lc_receipt_required_flag := 'N';
            END IF;
            ln_interface_header_id := l_header_tab(indx).record_id;
            print_debug_msg ('Insert into po_headers_interface- interface_header_id=['||TO_CHAR(ln_interface_header_id)||']',FALSE);
            INSERT
            INTO po_headers_interface
              (
                interface_header_id ,
                batch_id ,
                document_num ,
                currency_code ,
                ship_to_location_id ,
                fob ,
                freight_terms ,
                note_to_vendor ,
                note_to_receiver ,
                approval_status ,
                closed_code ,
                vendor_doc_num ,
                attribute10 ,
                reference_num ,
                interface_source_code ,
                attribute1 ,
                process_code ,
                action ,
                document_type_code ,
                org_id ,
                rate_type ,
                vendor_id ,
                agent_id ,
                vendor_site_id ,
                terms_id ,
                attribute_category ,
                attribute15 -- saved legacy po number
                ,
                creation_date ,
                created_by ,
                last_update_date ,
                last_updated_by ,
                last_update_login
              )
              VALUES
              (
                ln_interface_header_id ,
                l_header_tab(indx).batch_id ,
                l_header_tab(indx).po_number ,
                DECODE(l_header_tab(indx).currency_code,'USA','USD','CAN','CAD',l_header_tab(indx).currency_code) ,
                ln_ship_to_location_id ,
                DECODE(l_header_tab(indx).fob_code,'D','RECEIVING' ,'B','SHIPPING' ,'O','SHIPPING',SUBSTR(l_header_tab(indx).fob_code,1,2)) ,
                l_header_tab(indx).freight_code ,
                l_header_tab(indx).note_to_vendor ,
                l_header_tab(indx).note_to_receiver ,
                DECODE(l_header_tab(indx).status_code,'PD','INCOMPLETE','APPROVED') ,
                DECODE(l_header_tab(indx).status_code,'PD','INCOMPLETE','OPEN') ,
                l_header_tab(indx).vendor_doc_num ,
                l_header_tab(indx).import_manual_po ,
                '' ,
                'NA-POINTR' ,
                'NA-POINTR' ,
                'PENDING' ,
                lc_hdr_action ,
                'STANDARD' ,
                ln_org_id ,
                l_header_tab(indx).rate_type ,
                ln_vendor_id ,
                63974 --15335 --1100 is not getting approved
                ,
                ln_vendor_site_id ,
                ln_terms_id ,
                lc_attribute_category ,
                l_header_tab(indx).vendor_doc_num -- legacy po number
                ,
                l_header_tab(indx).date_entered ,
                gn_user_id ,
                sysdate ,
                gn_user_id ,
                gn_login_id
              );
            IF l_header_tab(indx).process_code = 'I' THEN
              BEGIN
                INSERT
                INTO xx_po_header_attributes
                  (
                    po_number ,
                    cust_order_nbr ,
                    cust_order_sub_nbr ,
                    cust_id ,
                    created_by ,
                    creation_date ,
                    last_updated_by ,
                    last_update_date ,
                    last_update_login
                  )
                  VALUES
                  (
                    l_header_tab(indx).po_number ,
                    l_header_tab(indx).cust_order_nbr ,
                    l_header_tab(indx).cust_order_sub_nbr ,
                    l_header_tab(indx).cust_id ,
                    gn_user_id ,
                    sysdate ,
                    gn_user_id ,
                    sysdate ,
                    gn_login_id
                  );
              EXCEPTION
              WHEN dup_val_on_index THEN
                print_debug_msg ('dup values - attribute already exists for PO=['||l_header_tab(indx).po_number||']',FALSE);
              END;
            END IF;
          END IF;
          --Validate Lines
          lc_lines_validation := NULL;
          OPEN lines_cur(l_header_tab(indx).record_id,l_header_tab(indx).po_number);
          FETCH lines_cur BULK COLLECT INTO l_lines_tab;
          CLOSE lines_cur;
          FOR l_indx IN 1..l_lines_tab.COUNT
          LOOP
            BEGIN
              print_debug_msg ('Record_line_id='||TO_CHAR(l_lines_tab(l_indx).record_line_id)||', Validate Item',FALSE);
              ln_item_id       := NULL;
              lc_item_uom_code := NULL;
              OPEN check_item_cur(ltrim(l_lines_tab(l_indx).item,'0'),l_lines_tab(l_indx).organization_id);
              FETCH check_item_cur INTO ln_item_id, lc_item_uom_code;
              CLOSE check_item_cur;
              IF ln_item_id                           IS NULL THEN
                l_lines_tab(l_indx).record_status     := 'E';
                l_lines_tab(l_indx).error_description := 'Invalid item=['||l_lines_tab(l_indx).item|| '], location=['||TO_CHAR(l_lines_tab(l_indx).location_id)||']';
				l_lines_tab(l_indx).error_column      := 'ITEM-LOCATION_ID';
				l_lines_tab(l_indx).error_value       := ltrim(l_lines_tab(l_indx).item,'0')||'-'||TO_CHAR(l_lines_tab(l_indx).location_id);
                print_debug_msg ('Record_line_id=['||TO_CHAR(l_lines_tab(l_indx).record_line_id)|| '] Invalid item=['||l_lines_tab(l_indx).item|| '], location=['||TO_CHAR(l_lines_tab(l_indx).location_id)||']',FALSE);
              END IF;
              print_debug_msg ('Record_line_id='||TO_CHAR(l_lines_tab(l_indx).record_line_id)||', Validate Item Category',FALSE);
              ln_category_id := NULL;
              OPEN check_item_cat_cur(ltrim(l_lines_tab(l_indx).item,'0'),l_lines_tab(l_indx).organization_id);
              FETCH check_item_cat_cur INTO ln_category_id;
              CLOSE check_item_cat_cur;
              IF ln_category_id                       IS NULL THEN
                l_lines_tab(l_indx).record_status     := 'E';
                l_lines_tab(l_indx).error_description := l_lines_tab(l_indx).error_description||'Invalid item Category=['||l_lines_tab(l_indx).item|| '], location=['||TO_CHAR(l_lines_tab(l_indx).location_id)||']';
				l_lines_tab(l_indx).error_column      := l_lines_tab(l_indx).error_column||'/ITEM-LOCATION_ID';
				l_lines_tab(l_indx).error_value       := l_lines_tab(l_indx).error_value||'/'||ltrim(l_lines_tab(l_indx).item,'0')||'-'||TO_CHAR(l_lines_tab(l_indx).location_id);
                print_debug_msg ('Record_line_id=['||TO_CHAR(l_lines_tab(l_indx).record_line_id)|| '] Invalid item Category=['||l_lines_tab(l_indx).item|| '], location=['||TO_CHAR(l_lines_tab(l_indx).location_id)||']',FALSE);
              END IF;
              print_debug_msg ('Record_line_id='||TO_CHAR(l_lines_tab(l_indx).record_line_id)||', Validate PO Status',FALSE);
              IF lc_po_status IN ('IN PROCESS','PRE-APPROVED','CANCELLED') AND lc_hdr_action = 'UPDATE' THEN
                l_lines_tab(l_indx).record_status                                           := 'E';
                l_lines_tab(l_indx).error_description                                         := 'PO status may be Pre-approved,  In-Process,  Frozen, Cancelled or Finally closed. PO=['||l_lines_tab(l_indx).po_number||']';
                print_debug_msg ('PO status may be Pre-approved,  In-Process,  Frozen, Cancelled or Finally closed. PO=['||l_lines_tab(l_indx).po_number||']',FALSE);
              END IF;
              --
              print_debug_msg ('Record_line_id='||TO_CHAR(l_lines_tab(l_indx).record_line_id)||', Check for Mis-Ship(warehouse) Transaction',FALSE);
              IF l_lines_tab(l_indx).quantity          = 0 AND (l_lines_tab(l_indx).process_code = 'M' OR l_lines_tab(l_indx).process_code = 'I') THEN
                l_lines_tab(l_indx).quantity          := 0.0000000001;
             -- ELSIF l_lines_tab(l_indx).quantity       = 0 AND l_lines_tab(l_indx).process_code = 'I' THEN
                --l_lines_tab(l_indx).record_status     := 'E';
              --  l_lines_tab(l_indx).error_description := l_lines_tab(l_indx).error_description||' Invalid Quantity=['||l_lines_tab(l_indx).quantity||']';
				--l_lines_tab(l_indx).error_column      := l_lines_tab(l_indx).error_column||'/QUANTITY';
			--	l_lines_tab(l_indx).error_value       := l_lines_tab(l_indx).error_value||'/'||l_lines_tab(l_indx).quantity;

       --         print_debug_msg ('Record_line_id='||TO_CHAR(l_lines_tab(l_indx).record_line_id)||', Invalid Quantity=['||l_lines_tab(l_indx).quantity||']',FALSE);
              END IF;
              print_debug_msg ('Record_line_id='||TO_CHAR(l_lines_tab(l_indx).record_line_id)||', Validate UOM',FALSE);
              lc_uom_code                     := NULL;
              IF l_lines_tab(l_indx).uom_code IS NULL THEN
                lc_uom_code                   := lc_item_uom_code;
              ELSE
                OPEN uom_cur(l_lines_tab(l_indx).uom_code);
                FETCH uom_cur INTO lc_uom_code;
                CLOSE uom_cur;
              END IF;
              IF lc_uom_code                          IS NULL THEN
                l_lines_tab(l_indx).record_status     := 'E';
                l_lines_tab(l_indx).error_description := l_lines_tab(l_indx).error_description||' UOM code not found legacy_uom=['||l_lines_tab(l_indx).uom_code||']';
				l_lines_tab(l_indx).error_column      := l_lines_tab(l_indx).error_column||'/UOM_CODE';
				l_lines_tab(l_indx).error_value       := l_lines_tab(l_indx).error_value||'/'||l_lines_tab(l_indx).uom_code;
                print_debug_msg ('Record_line_id='||TO_CHAR(l_lines_tab(l_indx).record_line_id)||', UOM code not found legacy_uom=['||l_lines_tab(l_indx).uom_code||']',FALSE);
              END IF;
              IF lc_hdr_action = 'UPDATE' AND (l_lines_tab(l_indx).process_code = 'I' or l_lines_tab(l_indx).process_code = 'M') THEN
                print_debug_msg ('Record_line_id='||TO_CHAR(l_lines_tab(l_indx).record_line_id)||', Validate Line Number',FALSE);
                lc_line_num := NULL;
                OPEN check_po_line_cur(l_lines_tab(l_indx).po_number,l_lines_tab(l_indx).line_num);
                FETCH check_po_line_cur INTO lc_line_num;
                CLOSE check_po_line_cur;
                IF lc_line_num                          IS NOT NULL THEN
                  l_lines_tab(l_indx).record_status     := 'E';
                  l_lines_tab(l_indx).error_description := l_lines_tab(l_indx).error_description||' Line Number Already Exists=['||l_lines_tab(l_indx).line_num||']';
				  l_lines_tab(l_indx).error_column      := l_lines_tab(l_indx).error_column||'/LINE_NUM';
				  l_lines_tab(l_indx).error_value       := l_lines_tab(l_indx).error_value||'/'||l_lines_tab(l_indx).line_num;
                  print_debug_msg ('Record_line_id='||TO_CHAR(l_lines_tab(l_indx).record_line_id)||', Line Number Already Exists=['||l_lines_tab(l_indx).line_num||']',FALSE);
                END IF;
              END IF;
              print_debug_msg ('Record_line_id='||TO_CHAR(l_lines_tab(l_indx).record_line_id)||', Validate location',FALSE);
              IF l_lines_tab(l_indx).location_id      IS NULL THEN
                l_lines_tab(l_indx).record_status     := 'E';
                l_lines_tab(l_indx).error_description := l_lines_tab(l_indx).error_description||' Invalid ship_to_location =['||l_lines_tab(l_indx).ship_to_location||']';
				l_lines_tab(l_indx).error_column      := l_lines_tab(l_indx).error_column||'/SHIP_TO_LOCATION';
				l_lines_tab(l_indx).error_value       := l_lines_tab(l_indx).error_value||'/'||l_lines_tab(l_indx).location_id;
                print_debug_msg ('Record_line_id=['||TO_CHAR(l_lines_tab(l_indx).record_line_id)||'], Invalid ship_to_location in lines=['||l_lines_tab(l_indx).ship_to_location||']',FALSE);
              ELSE
                ln_ship_to_location_id := l_lines_tab(l_indx).location_id;
              END IF;
              IF l_lines_tab(l_indx).record_status = 'E' THEN
                RAISE data_exception;
              END IF;
              IF l_header_tab(indx).record_status      = 'E' THEN
                l_lines_tab(l_indx).error_description := 'Header Validation Failed';
                RAISE data_exception;
              END IF;
              --Check if any of the lines have errors
              IF lc_lines_validation IS NULL THEN
                ln_interface_line_id := l_lines_tab(l_indx).record_line_id;
                print_debug_msg ('Insert PO Line-Interface_Line_Id='||TO_CHAR(ln_interface_line_id),FALSE);
                -- Insert in lines interface table --
                INSERT
                INTO po_lines_interface
                  (
                    interface_line_id ,
                    interface_header_id ,
                    line_num ,
                    item ,
                    item_id ,
                    vendor_product_num ,
                    quantity ,
                    line_attribute1 ,
                    ship_to_location_id ,
                    shipment_num ,
                    line_reference_num ,
                    uom_code ,
                    unit_price ,
                    line_attribute6 ,
                    need_by_date ,
                    promised_date ,
                    fob ,
                    freight_terms ,
                    creation_date ,
                    note_to_vendor ,
                    note_to_receiver ,
                    action ,
                    shipment_type ,
                    line_type ,
                    line_loc_populated_flag ,
                    organization_id ,
                    closed_code ,
                    inspection_required_flag ,
                    receipt_required_flag ,
                    created_by ,
                    last_update_date ,
                    last_updated_by ,
                    last_update_login
                  )
                  VALUES
                  (
                    ln_interface_line_id ,
                    ln_interface_header_id ,
                    l_lines_tab(l_indx).line_num ,
                    l_lines_tab(l_indx).item ,
                    ln_item_id ,
                    l_lines_tab(l_indx).vendor_product_code ,
                    l_lines_tab(l_indx).quantity ,
                    l_lines_tab(l_indx).qty_received ,
                    ln_ship_to_location_id ,
                    1 ,
                    l_lines_tab(l_indx).line_reference_num ,
                    lc_uom_code ,
                    l_lines_tab(l_indx).unit_price ,
                    l_lines_tab(l_indx).shipmentnumber ,
                    TRUNC(l_header_tab(indx).date_entered) ,
                    TRUNC(l_header_tab(indx).date_entered) ,
                    DECODE(l_header_tab(indx).fob_code,'D','RECEIVING' ,'B','SHIPPING' ,'O','SHIPPING',SUBSTR(l_header_tab(indx).fob_code,1,2)) ,
                    l_header_tab(indx).freight_code ,
                    l_header_tab(indx).date_entered ,
                    l_header_tab(indx).note_to_vendor ,
                    l_header_tab(indx).note_to_receiver ,
                    'ORIGINAL' ,
                    'STANDARD' ,
                    'Goods' ,
                    'Y' ,
                    ln_org_id ,
                    DECODE(l_header_tab(indx).status_code,'PD','INCOMPLETE','OPEN') ,
                    'N' ,
                    lc_receipt_required_flag ,
                    gn_user_id ,
                    sysdate ,
                    gn_user_id ,
                    gn_login_id
                  ); -- 'Y' =3 way matching 'N'=2 way matching
                IF l_lines_tab(l_indx).process_code = 'I' THEN
                  BEGIN
                    INSERT
                    INTO xx_po_line_attributes
                      (
                        po_number ,
                        line_number ,
                        created_by ,
                        creation_date ,
                        last_updated_by ,
                        last_update_date ,
                        last_update_login
                      )
                      VALUES
                      (
                        l_header_tab(indx).po_number ,
                        l_lines_tab(l_indx).line_num ,
                        gn_user_id ,
                        sysdate ,
                        gn_user_id ,
                        sysdate ,
                        gn_login_id
                      );
                  EXCEPTION
                  WHEN dup_val_on_index THEN
                    print_debug_msg ('dup values - attribute already exists for PO=['||l_header_tab(indx).po_number|| '] Line Number=['||l_lines_tab(l_indx).line_num||']',FALSE);
                  END;
                END IF;
                -- Insert line locations for Dropship --
                SELECT po_line_locations_interface_s.NEXTVAL
                INTO ln_line_locations_interface_id
                FROM dual;
                print_debug_msg ('Insert PO Line Locations-Interface_Line_Location_Id='||TO_CHAR(ln_line_locations_interface_id),FALSE);
                INSERT
                INTO po_line_locations_interface
                  (
                    interface_line_location_id ,
                    interface_header_id ,
                    interface_line_id ,
                    process_code ,
                    shipment_type ,
                    shipment_num ,
                    ship_to_location_id ,
                    fob ,
                    freight_terms ,
                    need_by_date ,
                    promised_date ,
                    quantity ,
                    creation_date ,
                    unit_of_measure ,
                    action
                    --,invoice_close_tolerance --testing
                    --,receive_close_tolerance --testing
                    ,
                    inspection_required_flag ,
                    receipt_required_flag ,
                    created_by ,
                    last_updated_by ,
                    last_update_date ,
                    last_update_login
                  )
                  VALUES
                  (
                    ln_line_locations_interface_id ,
                    ln_interface_header_id ,
                    ln_interface_line_id ,
                    'PENDING' ,
                    'STANDARD' ,
                    1 ,
                    ln_ship_to_location_id ,
                    DECODE(l_header_tab(indx).fob_code,'D','RECEIVING' ,'B','SHIPPING' ,'O','SHIPPING',SUBSTR(l_header_tab(indx).fob_code,1,2)) ,
                    l_header_tab(indx).freight_code ,
                    TRUNC(l_header_tab(indx).date_entered) ,
                    TRUNC(l_header_tab(indx).date_entered) ,
                    l_lines_tab(l_indx).quantity ,
                    l_header_tab(indx).date_entered ,
                    lc_uom_code ,
                    'ADD'
                    --,100
                    --,100
                    ,
                    'N' -- Combination to determine 2 or 3 way matching this is
                    ,
                    lc_receipt_required_flag -- 'Y' =3 way matching 'N'=2 way matching
                    ,
                    gn_user_id ,
                    gn_user_id ,
                    sysdate ,
                    gn_login_id
                  );
                -- Insert distributions --
                SELECT po_distributions_interface_s.NEXTVAL
                INTO ln_distributions_interface_id
                FROM dual;
                print_debug_msg ('Insert PO distribution-Interface_Distribution_Id='||TO_CHAR(ln_distributions_interface_id),FALSE);
                INSERT
                INTO po_distributions_interface
                  (
                    interface_header_id ,
                    interface_line_id ,
                    interface_distribution_id ,
                    interface_line_location_id ,
                    org_id ,
                    distribution_num ,
                    quantity_ordered ,
                    quantity_delivered ,
                    quantity_billed ,
                    destination_type_code ,
                    destination_subinventory ,
                    created_by ,
                    creation_date ,
                    last_updated_by ,
                    last_update_date ,
                    last_update_login
                  )
                  VALUES
                  (
                    ln_interface_header_id ,
                    ln_interface_line_id ,
                    ln_distributions_interface_id ,
                    ln_line_locations_interface_id ,
                    ln_org_id ,
                    1 ,
                    l_lines_tab(l_indx).quantity ,
                    l_lines_tab(l_indx).qty_received ,
                    l_lines_tab(l_indx).qty_shipped ,
                    'INVENTORY' ,
                    'STOCK' ,
                    gn_user_id ,
                    sysdate ,
                    gn_user_id ,
                    sysdate ,
                    gn_login_id
                  );
              END IF;
            EXCEPTION
            WHEN data_exception THEN
              ROLLBACK;
              print_debug_msg ('Record_line_id=['||TO_CHAR(l_lines_tab(l_indx).record_line_id)||'], RB, ',FALSE);
              lc_lines_validation                   := 'E';
              l_lines_tab(l_indx).record_status     := 'E';
              l_lines_tab(l_indx).error_description := l_lines_tab(l_indx).error_description;
			  l_lines_tab(l_indx).error_column      := l_lines_tab(l_indx).error_column;
			  l_lines_tab(l_indx).error_value       := l_lines_tab(l_indx).error_value;
            WHEN OTHERS THEN
              ROLLBACK;
              lc_error_msg := SUBSTR(sqlerrm,1,250);
              print_debug_msg ('Record_line_id=['||TO_CHAR(l_lines_tab(l_indx).record_line_id)||'], RB, '||lc_error_msg,FALSE);
              lc_lines_validation                   := 'E';
              l_lines_tab(l_indx).record_status     := 'E';
              l_lines_tab(l_indx).error_description := lc_error_msg;
			  l_lines_tab(l_indx).error_column      := 'LINE-OTH-EXCEPTION';
            END;
          END LOOP;
          --Check line validation flag to check if any of the lines have errors
          print_debug_msg ('lc_line_validation=['||lc_lines_validation||']',FALSE);
          IF lc_lines_validation                  = 'E' THEN
            l_header_tab(indx).record_status     := 'E';
            l_header_tab(indx).error_description := l_header_tab(indx).error_description || ' Line Validation Failed';
          END IF;
          print_debug_msg ('Update header Record_id=['||TO_CHAR(l_header_tab(indx).record_id)||'], Status=['||l_header_tab(indx).record_status||']',FALSE);
          UPDATE xx_po_pom_hdr_int_stg
          SET record_status   = DECODE(l_header_tab(indx).record_status,'E','E','I') ,
            error_description = l_header_tab(indx).error_description ,
			error_column      = l_header_tab(indx).error_column,
			error_value       = l_header_tab(indx).error_value,
            last_update_date  = sysdate ,
            last_updated_by   = gn_user_id ,
            last_update_login = gn_login_id
          WHERE record_id     = l_header_tab(indx).record_id;
          BEGIN
            print_debug_msg('Starting update of xx_po_pom_lines_int_stg #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
            FORALL i IN 1..l_lines_tab.COUNT
            SAVE EXCEPTIONS
            UPDATE xx_po_pom_lines_int_stg
            SET record_status    = DECODE(lc_lines_validation,'E','E','I') ,
              error_description  = DECODE(lc_lines_validation,'E',NVL(l_lines_tab(i).error_description,'Other lines in the PO are not valid'),'') ,
			  error_column       = l_lines_tab(i).error_column,
			  error_value        = l_lines_tab(i).error_value,
              last_update_date   = sysdate ,
              last_updated_by    = gn_user_id ,
              last_update_login  = gn_login_id
            WHERE record_line_id = l_lines_tab(i).record_line_id;
          EXCEPTION
          WHEN OTHERS THEN
            print_debug_msg('Bulk Exception raised',FALSE);
            ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
            FOR i IN 1..ln_err_count
            LOOP
              ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
              lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
              log_exception ('OD PO POM Inbound Interface(Child)',lc_error_loc,lc_error_msg);
              print_debug_msg('Record_Line_id=['||TO_CHAR(l_lines_tab(ln_error_idx).record_line_id)||'], Error msg=['||lc_error_msg||']',TRUE);
            END LOOP; -- bulk_err_loop FOR UPDATE
          END;
          print_debug_msg('Ending Update of xx_po_pom_lines_int_stg #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
          --header record has lines with process code 'I' which failed to load - updating other lines.
          IF l_header_tab(indx).process_code = 'U' AND l_header_tab(indx).record_status = 'E' THEN
            print_debug_msg('Updating status of PO lines with process code=U,D',TRUE);
            UPDATE xx_po_pom_lines_int_stg l
            SET l.record_status    = 'E',
              l.error_description  = 'Header or other lines in the PO have errors'
            WHERE l.record_status IS NULL
            AND l.process_code    IN('U','D')
            AND l.record_id        = l_header_tab(indx).record_id
            AND l.po_number        = l_header_tab(indx).po_number;
            ln_count              := SQL%ROWCOUNT;
            print_debug_msg(TO_CHAR(ln_count)|| 'lines record(s) updated with error status',FALSE);
          END IF;
        EXCEPTION
        WHEN data_exception THEN
          print_debug_msg('Update Record_id=['||TO_CHAR(l_header_tab(indx).record_id)||'] with error msg',FALSE);
          UPDATE xx_po_pom_hdr_int_stg
          SET record_status   = l_header_tab(indx).record_status ,
            error_description = l_header_tab(indx).error_description ,
			error_column      = l_header_tab(indx).error_column,
			error_value       = l_header_tab(indx).error_value,
            last_update_date  = sysdate ,
            last_updated_by   = gn_user_id ,
            last_update_login = gn_login_id
          WHERE record_id     = l_header_tab(indx).record_id;
          print_debug_msg('Update lines for PO=['||l_header_tab(indx).po_number||'] with error msg',FALSE);
          UPDATE xx_po_pom_lines_int_stg
          SET record_status   = DECODE(l_header_tab(indx).record_status,'D','D','E') ,
            --error_description = l_header_tab(indx).error_description ,
			error_description = 'Header Validation Failed' ,
			--error_column      = l_header_tab(indx).error_column,
			--error_value       = l_header_tab(indx).error_value,
            last_update_date  = sysdate ,
            last_updated_by   = gn_user_id ,
            last_update_login = gn_login_id
          WHERE po_number     = l_header_tab(indx).po_number
          AND record_id       = l_header_tab(indx).record_id;
        WHEN OTHERS THEN
          print_debug_msg('Other Exc-Update Record_id=['||TO_CHAR(l_header_tab(indx).record_id)||'] with error msg',FALSE);
          lc_error_msg := SUBSTR(sqlerrm,1,250);
          UPDATE xx_po_pom_hdr_int_stg
          SET record_status   = 'E' ,
            error_description = lc_error_msg ,
			--error_column      = 'OTH-HDR-EXCEPTION',
            last_update_date  = sysdate ,
            last_updated_by   = gn_user_id ,
            last_update_login = gn_login_id
          WHERE record_id     = l_header_tab(indx).record_id;
          print_debug_msg('Other Exc-Update lines for PO=['||l_header_tab(indx).po_number||'] with error msg',FALSE);
          UPDATE xx_po_pom_lines_int_stg
          SET record_status   = 'E' ,
            error_description = lc_error_msg ,
			error_column      = 'OTH-LINE-EXCEPTION',
            last_update_date  = sysdate ,
            last_updated_by   = gn_user_id ,
            last_update_login = gn_login_id
          WHERE po_number     = l_header_tab(indx).po_number
          AND record_id       = l_header_tab(indx).record_id;
        END;
        COMMIT;
        print_debug_msg('Commit Complete',FALSE);
      END LOOP; --l_header_tab
    END LOOP;   --header_cur
    CLOSE header_cur;
    print_debug_msg('Submitting Import Standard Purchase Orders',FALSE);
    OPEN org_cur;
    FETCH org_cur BULK COLLECT INTO l_org_tab;
    CLOSE org_cur;
    FOR o_indx IN 1..l_org_tab.COUNT
    LOOP
      print_debug_msg('Submitting Import Standard Purchase Orders for batchid=['||p_batch_id||'], Org_id=['||l_org_tab(o_indx).org_id||']',FALSE);
      --user_id SVC_ESP_FIN 90102
      --resp_id Purchasing Super User 20707
      --resp_app_id po - 201
      --fnd_global.apps_initialize (gn_user_id,20707,201);
      mo_global.set_policy_context('S',l_org_tab(o_indx).org_id);
      mo_global.init ('PO');
      ln_job_id := fnd_request.submit_request(application => 'PO' ,program => 'POXPOPDOI' ,sub_request => TRUE ,argument1 => '' -- Default Buyer
      ,argument2 => 'STANDARD'                                                                                                  -- Doc. Type
      ,argument3 => ''                                                                                                          -- Doc. Sub Type
      ,argument4 => 'N'                                                                                                         -- Create or Update Items
      ,argument5 => ''                                                                                                          -- Create sourcing Rules flag
      ,argument6 => 'APPROVED'                                                                                                  -- Approval Status
      ,argument7 => ''                                                                                                          -- Release Generation Method
      ,argument8 => p_batch_id                                                                                                  -- batch_id
      ,argument9 => l_org_tab(o_indx).org_id                                                                                    -- org_id
      );
      COMMIT;
      IF ln_job_id = 0 THEN
        p_retcode := '2';
        EXIT;
      END IF;
    END LOOP;
    IF p_retcode = 2 THEN
      p_errbuf  := 'Sub-Request Submission- Failed';
      RETURN;
    END IF;
    --Pause if child request exists
    IF l_org_tab.COUNT > 0 THEN
      -- Set parent program status as 'PAUSED' and set global variable value to 'END'
      print_debug_msg('Pausing Program......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
      fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data => 'END');
      print_debug_msg('Complete Pausing Program......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
    ELSE
      print_debug_msg('No Child Requests submitted...',TRUE);
      report_child_program_stats(p_batch_id);
      p_retcode := '0';
    END IF;
  END IF; --l_req_data IS NULL
  IF (lc_req_data = 'END') THEN
    update_staging_record_status(p_batch_id);
    ln_child_request_status   := child_request_status;
    IF ln_child_request_status = 'C' THEN
      report_child_program_stats(p_batch_id);
      p_retcode                  := '0';
    ELSIF ln_child_request_status = 'G' THEN
      p_retcode                  := '1'; --Warning
      p_errbuf                   := 'One or more child program completed in error or warning';
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  lc_error_msg := SUBSTR(sqlerrm,1,250);
  print_debug_msg ('ERROR Int Child- '||lc_error_msg,TRUE);
  log_exception ('OD PO POM Inbound Interface(Child)', lc_error_loc, lc_error_msg);
  p_retcode := 2;
  p_errbuf  := lc_error_msg;
END interface_child;
-- +============================================================================================+
-- |  Name   : submit_int_child_threads                                                     |
-- |  Description: This procedure splits PO into batches and submits child process.             |
-- |               OD PO POM Inbound Interface(Child)                                           |
-- =============================================================================================|
PROCEDURE submit_int_child_threads(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_child_threads NUMBER ,
    p_retry_errors  VARCHAR2 ,
    p_debug         VARCHAR2)
AS
  CURSOR threads_cur
  IS
	SELECT MIN(x.record_id) from_id ,
	  MAX(x.record_id) to_id ,
	  x.thread_num ,
	  COUNT(1)
	FROM
	  (SELECT TOT.record_id,
		NTILE(p_child_threads) OVER(ORDER BY TOT.record_id) thread_num
	  FROM
		(SELECT l.record_id,
		  l.record_line_id
		FROM xx_po_pom_lines_int_stg l,
		  xx_po_pom_hdr_int_stg h
		WHERE 1         =1
		AND h.record_id = l.record_id
		AND h.po_number = l.po_number
		AND h.record_status IS NULL
		AND l.record_status IS NULL
		AND l.process_code IN('I','M')

		UNION ALL

		SELECT hs.record_id,
		  rownum
		FROM xx_po_pom_hdr_int_stg hs
		WHERE 1=1
		  AND hs.record_status IS NULL
		  AND hs.process_code = 'T'
		) TOT
	  ) x
	GROUP BY x.thread_num
	ORDER BY x.thread_num;

	CURSOR batch_count_cur(c_min_batch_id NUMBER, c_max_batch_id NUMBER)
	IS
		SELECT
			hs.batch_id
			,count(1) batch_count
		FROM xx_po_pom_hdr_int_stg hs
		WHERE hs.batch_id >= c_min_batch_id
		  AND hs.batch_id <= c_max_batch_id
		GROUP BY hs.batch_id;

  TYPE threads
IS
  TABLE OF threads_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_threads_tab threads;

  TYPE l_number_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  l_batch_list l_number_tab;

  lc_error_msg   VARCHAR2(1000) := NULL;
  lc_error_loc   VARCHAR2(100)  := 'XX_PO_POM_INT_PKG.SUBMIT_INT_CHILD_THREADS';
  ln_batch_count NUMBER;
  ln_batch_id    NUMBER;
  ln_request_id  NUMBER;
BEGIN
  print_debug_msg('Preparing threads for new po/add line',TRUE);
  OPEN threads_cur;
  FETCH threads_cur BULK COLLECT INTO l_threads_tab;
  CLOSE threads_cur;
  print_debug_msg('Update BatchID in headers for import',TRUE);
  FOR indx IN 1..l_threads_tab.COUNT
  LOOP
    SELECT xx_po_pom_int_batch_s.nextval INTO ln_batch_id FROM dual;
    UPDATE xx_po_pom_hdr_int_stg h
    SET h.batch_id        = ln_batch_id ,
      h.last_update_date  = sysdate ,
      h.last_updated_by   = gn_user_id ,
      h.last_update_login = gn_login_id
    WHERE h.record_id BETWEEN l_threads_tab(indx).from_id AND l_threads_tab(indx).to_id
    AND h.record_status IS NULL
    AND ((EXISTS
      (SELECT 'x'
      FROM xx_po_pom_lines_int_stg l
      WHERE l.record_status IS NULL
      AND l.record_id        = h.record_id
      AND l.po_number        = h.po_number
      AND l.process_code    IN('I','M')
      ))
    OR h.process_code IN('T'));
    ln_batch_count    := SQL%ROWCOUNT;

	l_batch_list(indx) := ln_batch_id;

    print_debug_msg(TO_CHAR(ln_batch_count)||' hdr record(s) updated with batchid '||TO_CHAR(ln_batch_id),TRUE);
    COMMIT;
	END LOOP;

	IF l_batch_list.COUNT > 0 THEN

		FOR l_rec IN batch_count_cur(l_batch_list(1), l_batch_list(l_batch_list.COUNT))
		LOOP
			print_debug_msg(TO_CHAR(l_rec.batch_count)||' hdr record(s) going to submit with batchid '||TO_CHAR(l_rec.batch_id),TRUE);
		END LOOP;

	  FOR ind IN 1..l_batch_list.COUNT
	  LOOP
		ln_request_id := fnd_request.submit_request(application => 'XXFIN' ,program => 'XXPOPOMINTC' ,sub_request => TRUE ,argument1 => l_batch_list(ind) ,argument2 => p_debug);
		COMMIT;
		IF ln_request_id = 0 THEN
		  p_retcode     := '2';
		  EXIT;
		END IF;
	  END LOOP;
	END IF;
  IF p_retcode = 2 THEN
    p_errbuf  := 'Sub-Request Submission- Failed';
    RETURN;
  END IF;
  --Check if any child requests submitted.
  IF l_threads_tab.COUNT > 0 THEN
    p_retcode           := '0';
  ELSE
    p_retcode := '1';
  END IF;
EXCEPTION
WHEN OTHERS THEN
  lc_error_msg := SUBSTR(sqlerrm,1,250);
  print_debug_msg('ERROR in SUBMIT_INT_CHILD_TREADS'||lc_error_msg,TRUE);
  log_exception ('OD PO POM Inbound Interface(Master)',lc_error_loc,lc_error_msg);
  p_retcode := '2';
  p_errbuf  := SUBSTR(sqlerrm,1,250);
END submit_int_child_threads;
-- +============================================================================================+
-- |  Name   : submit_upd_child_threads                                                     |
-- |  Description: This procedure splits PO lines into batches and submits child process.       |
-- |               OD PO POM Inbound Update(Child)                                              |
-- =============================================================================================|
PROCEDURE submit_upd_child_threads(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_child_threads NUMBER ,
    p_retry_errors  VARCHAR2 ,
    p_debug         VARCHAR2)
AS
  CURSOR upd_threads_cur
  IS
    SELECT MIN(x.record_id) from_id ,
      MAX(x.record_id) to_id ,
      x.thread_num ,
      COUNT(1)
    FROM
      (SELECT l.record_id,
        ntile(p_child_threads) over(order by l.record_id) thread_num
      FROM xx_po_pom_lines_int_stg l
      WHERE l.record_status IS NULL
      AND l.process_code    IN('U','D')
      AND EXISTS
        (SELECT 'x'
        FROM xx_po_pom_hdr_int_stg h
        WHERE h.record_id            = l.record_id
        AND h.po_number              = l.po_number
        AND h.process_code          IN('U','T')
        AND NVL(h.record_status,'I') = 'I'
        )
      ) x
    GROUP BY x.thread_num
    ORDER BY x.thread_num;
  TYPE upd_threads
IS
  TABLE OF upd_threads_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_upd_threads_tab upd_threads;
  lc_error_msg   VARCHAR2(1000) := NULL;
  lc_error_loc   VARCHAR2(100)  := 'XX_PO_POM_INT_PKG.SUBMIT_UPD_CHILD_THREADS';
  ln_batch_count NUMBER;
  ln_batch_id    NUMBER;
  ln_request_id  NUMBER;
BEGIN
  print_debug_msg('Preparing threads for upd/close line',TRUE);
  OPEN upd_threads_cur;
  FETCH upd_threads_cur BULK COLLECT INTO l_upd_threads_tab;
  CLOSE upd_threads_cur;
  print_debug_msg('Update BatchID in lines for update',TRUE);
  FOR indx IN 1..l_upd_threads_tab.COUNT
  LOOP
    SELECT xx_po_pom_int_batch_s.nextval INTO ln_batch_id FROM dual;
    UPDATE xx_po_pom_lines_int_stg l
    SET l.batch_id        = ln_batch_id ,
      l.last_update_date  = sysdate ,
      l.last_updated_by   = gn_user_id ,
      l.last_update_login = gn_login_id
    WHERE l.record_id BETWEEN l_upd_threads_tab(indx).from_id AND l_upd_threads_tab(indx).to_id
    AND l.record_status IS NULL
    AND l.process_code  IN('U','D')
    AND EXISTS
      (SELECT 'x'
      FROM xx_po_pom_hdr_int_stg h
      WHERE h.record_id            = l.record_id
      AND h.po_number              = l.po_number
      AND h.process_code          IN('U','T')
      AND NVL(h.record_status,'I') = 'I'
      );
    ln_batch_count := SQL%ROWCOUNT;
    print_debug_msg(TO_CHAR(ln_batch_count)||' line record(s) updated with batchid '||TO_CHAR(ln_batch_id),TRUE);
    COMMIT;
    ln_request_id := fnd_request.submit_request(application => 'XXFIN' ,program => 'XXPOPOMUPDC' ,sub_request => TRUE ,argument1 => ln_batch_id ,argument2 => p_debug);
    COMMIT;
    IF ln_request_id = 0 THEN
      p_retcode     := '2';
      EXIT;
    END IF;
  END LOOP;
  IF p_retcode = 2 THEN
    p_errbuf  := 'Sub-Request Submission- Failed';
    RETURN;
  END IF;
  --Check if any child requests submitted.
  IF l_upd_threads_tab.COUNT > 0 THEN
    p_retcode               := '0';
  ELSE
    p_retcode := '1';
  END IF;
EXCEPTION
WHEN OTHERS THEN
  lc_error_msg := SUBSTR(sqlerrm,1,250);
  print_debug_msg('ERROR in SUBMIT_UPD_CHILD_THREADS'||lc_error_msg,TRUE);
  log_exception ('OD PO POM Inbound Interface(Master)',lc_error_loc,lc_error_msg);
  p_retcode := '2';
  p_errbuf  := SUBSTR(sqlerrm,1,250);
END submit_upd_child_threads;
-- +============================================================================================+
-- |  Name   : interface_master                                                             |
-- |  Description: This procedure reads data from the staging and loads into PO interface       |
-- |               OD PO POM Inbound Interface(Master)                                          |
-- =============================================================================================|
PROCEDURE interface_master(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_child_threads NUMBER ,
    p_retry_errors  VARCHAR2 ,
		p_retry_int_errors VARCHAR2 ,
    p_debug         VARCHAR2)
AS

	CURSOR c_int_err_rec IS
		SELECT record_id, po_headers_interface_s.NEXTVAL
		FROM xx_po_pom_hdr_int_stg
		WHERE record_status = 'IE';

	lc_error_msg            VARCHAR2(1000) := NULL;
	lc_error_loc            VARCHAR2(100)  := 'XX_PO_POM_INT_PKG.INTERFACE_MASTER';
	ln_retry_hdr_count      NUMBER;
	ln_retry_lin_count      NUMBER;
	ln_retry_int_hdr_count	NUMBER;
	LN_RETRY_INT_LIN_COUNT  NUMBER;
	lc_retcode              VARCHAR2(3) := NULL;
	lc_iretcode             VARCHAR2(3) := NULL;
	lc_uretcode             VARCHAR2(3) := NULL;
	lc_req_data             VARCHAR2(30);
	ln_child_request_status VARCHAR2(1) := NULL;
	ln_err_count						NUMBER;
	ln_error_idx						NUMBER;
	ln_upd_cnt              NUMBER;

	TYPE l_number_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

	l_old_recs l_number_tab;
	l_new_recs l_number_tab;

	TYPE l_num_tab IS TABLE OF NUMBER;
	l_upd_rec_list  l_num_tab;


BEGIN
  gc_debug      := p_debug;
  gn_request_id := fnd_global.conc_request_id;
  gn_user_id    := fnd_global.user_id;
  gn_login_id   := fnd_global.login_id;
  --Get value of global variable. It is null initially.
  lc_req_data := fnd_conc_global.request_data;
  print_debug_msg('Begin - lc_req_data is '||lc_req_data,FALSE);
  -- req_date will be null for first time parent scan by concurrent manager.
  IF (lc_req_data IS NULL) THEN

    print_debug_msg('Check Retry Errors',TRUE);
    IF p_retry_errors = 'Y' THEN
      --Retry will process only error records by using request_id
      print_debug_msg('Updating header records for retry',FALSE);

      UPDATE xx_po_pom_hdr_int_stg
      SET record_status   = NULL ,
        error_description = NULL ,
		error_column      = NULL ,
		error_value       = NULL ,
        last_update_date  = sysdate ,
        last_updated_by   = gn_user_id ,
        last_update_login = gn_login_id
      WHERE record_status = 'E';
      ln_retry_hdr_count := SQL%ROWCOUNT;
      print_debug_msg(TO_CHAR(ln_retry_hdr_count)||' header record(s) updated for retry',TRUE);
      print_debug_msg('Updating lines records for retry',FALSE);

      UPDATE xx_po_pom_lines_int_stg
      SET record_status   = NULL ,
        error_description = NULL ,
		error_column      = NULL ,
		error_value       = NULL ,
        last_update_date  = sysdate ,
        last_updated_by   = gn_user_id ,
        last_update_login = gn_login_id
      WHERE record_status = 'E';
      ln_retry_lin_count := SQL%ROWCOUNT;
      print_debug_msg(TO_CHAR(ln_retry_lin_count)||' line record(s) updated for retry',TRUE);
      COMMIT;
    END IF;

    IF p_retry_int_errors = 'Y' THEN
      --Retry will process only interface error records by using request_id
	  -- If any IE records(Of header process_code = 'I') and new records(other day) comes with
	  -- updated data 'U' then these are handled in Prepare package.
      print_debug_msg('Updating header records for retry',FALSE);

			OPEN c_int_err_rec;
			FETCH c_int_err_rec BULK COLLECT INTO l_old_recs, l_new_recs;
			CLOSE c_int_err_rec;

			BEGIN
				ln_err_count := 0;
				ln_retry_int_hdr_count := 0;
				FORALL i IN 1..l_old_recs.COUNT
			  SAVE EXCEPTIONS
				UPDATE xx_po_pom_hdr_int_stg
				SET record_id = l_new_recs(i) ,
					record_status   = NULL ,
					error_description = NULL ,
					error_column      = NULL ,
					error_value       = NULL ,
					attribute5   	  = substr(attribute5||':Retry IE', 1, 150),
					last_update_date  = sysdate ,
					last_updated_by   = gn_user_id ,
					last_update_login = gn_login_id
				WHERE record_id = l_old_recs(i);

       -- ln_retry_int_hdr_count := SQL%ROWCOUNT;
       --  print_debug_msg(TO_CHAR(ln_retry_int_hdr_count)||' header record(s) updated for retry interface errors',TRUE);
			EXCEPTION
      WHEN OTHERS THEN
				print_debug_msg('Bulk Exception raised',FALSE);
        ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
        FOR i IN 1..ln_err_count
        LOOP
					ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
					lc_error_msg := SUBSTR ( 'Interface Retry - Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
					log_exception ('OD PO POM Inbound Interface(Master)',lc_error_loc,lc_error_msg);
					print_debug_msg('Interface Retry - Record_id=['||TO_CHAR(l_old_recs(ln_error_idx))||'], Error msg=['||lc_error_msg||']',TRUE);
        END LOOP; -- bulk_err_loop FOR UPDATE
				raise;
      END;

			BEGIN
				ln_err_count := 0;
				ln_retry_int_hdr_count := 0;

				FORALL i IN 1..l_old_recs.COUNT
			  SAVE EXCEPTIONS
				UPDATE xx_po_pom_lines_int_stg
				SET record_id = l_new_recs(i)
				WHERE record_id = l_old_recs(i);

				--ln_retry_int_hdr_count := SQL%ROWCOUNT;
				--print_debug_msg(TO_CHAR(ln_retry_int_hdr_count)||' header record(s), of lines, updated for retry interface errors',TRUE);
			EXCEPTION
      WHEN OTHERS THEN
		print_debug_msg('Interface Retry Lines record_id - Bulk Exception raised',TRUE);
        ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
        FOR i IN 1..ln_err_count
        LOOP
					ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
					lc_error_msg := SUBSTR ( 'Interface Retry Lines - Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
					log_exception ('Interface Retry Lines - OD PO POM Inbound Interface(Master)',lc_error_loc,lc_error_msg);
					print_debug_msg('Record_id=['||TO_CHAR(l_old_recs(ln_error_idx))||'], Error msg=['||lc_error_msg||']',TRUE);
        END LOOP; -- bulk_err_loop FOR UPDATE
				raise;
      END;


      UPDATE xx_po_pom_lines_int_stg
      SET record_line_id = po_lines_interface_s.NEXTVAL ,
				record_status     = NULL ,
				error_description = NULL ,
				error_column      = NULL ,
				error_value       = NULL ,
				attribute5   	  = 'Retry IE' ,
        last_update_date  = sysdate ,
        last_updated_by   = gn_user_id ,
        last_update_login = gn_login_id
      WHERE record_status = 'IE';
      ln_retry_int_lin_count := SQL%ROWCOUNT;
      print_debug_msg(TO_CHAR(ln_retry_int_lin_count)||' line record(s) updated for retry interface errors',TRUE);
      COMMIT;
    END IF;    -- END of IF p_retry_int_errors = 'Y' THEN


	-- Skip the PO's if they belong to Internal Vendors.
	BEGIN

		UPDATE xx_po_pom_hdr_int_stg hs
		SET record_status = 'I'
			,attribute5 = 'Internal Vendor - skip PO processing'
			,last_update_date  = sysdate
			,last_updated_by   = gn_user_id
			,last_update_login = gn_login_id
		WHERE record_status IS NULL
		  AND EXISTS (
				 SELECT '1'
				 FROM  xx_fin_translatedefinition xtd
					 , xx_fin_translatevalues xtv
				WHERE xtd.translation_name = 'PO_POM_INT_VENDOR_EXCL'
				AND xtd.translate_id       = xtv.translate_id
				AND xtv.source_value1 = ltrim(hs.vendor_site_code, '0')
		)
		RETURNING record_id
		BULK COLLECT INTO l_upd_rec_list;

		ln_upd_cnt := l_upd_rec_list.count;
		print_debug_msg('Internal Vendor Updated Staged PO Headers are '||ln_upd_cnt,TRUE);


		FORALL i in 1..ln_upd_cnt
		UPDATE xx_po_pom_lines_int_stg hs
		SET record_status = 'I'
			,attribute5 = 'Internal Vendor - skip PO processing'
			,last_update_date  = sysdate
			,last_updated_by   = gn_user_id
			,last_update_login = gn_login_id
		WHERE record_id = l_upd_rec_list(i);

		-- print_debug_msg('Internal Vendor Updated Staged PO Lines are '||ln_upd_cnt,TRUE);
		COMMIT;

	END;



    lc_iretcode := NULL;
    submit_int_child_threads(lc_error_msg,lc_iretcode,p_child_threads,p_retry_errors,p_debug);
    IF lc_iretcode = '0' THEN
      --Pause if child request exists
      -- Set parent program status as 'PAUSED' and set global variable value to 'END'
      print_debug_msg('Pausing MASTER Program for interface......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
      fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data => 'IMPORT_END');
      print_debug_msg('Complete Pausing MASTER Program for interface......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
    ELSIF lc_iretcode = '2' THEN
      p_retcode      := '2';
      p_errbuf       := lc_error_msg;
    ELSIF lc_iretcode = '1' THEN
      print_debug_msg('No Interface Child Requests submitted...',TRUE);
      lc_uretcode  := NULL;
      lc_error_msg := NULL;
      submit_upd_child_threads(lc_error_msg,lc_uretcode,p_child_threads,p_retry_errors,p_debug);
      IF lc_uretcode = '0' THEN
        --Pause if child request exists
        -- Set parent program status as 'PAUSED' and set global variable value to 'END'
        print_debug_msg('Pausing MASTER Program for update......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
        fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data => 'END');
        print_debug_msg('Complete Pausing MASTER Program for update......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
      ELSIF lc_uretcode = '1' THEN
        print_debug_msg('No Update Child Requests submitted...',TRUE);
        p_retcode      := '0';
      ELSIF lc_uretcode = '2' THEN
        p_retcode      := '2';
        p_errbuf       := lc_error_msg;
      END IF;
    END IF;
  END IF; --l_req_data IS NULL
  IF (lc_req_data = 'IMPORT_END') THEN
    print_debug_msg('Restart program with lc_req_data as '||lc_req_data||' at '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
    lc_uretcode  := NULL;
    submit_upd_child_threads(lc_error_msg,lc_uretcode,p_child_threads,p_retry_errors,p_debug);
    IF lc_uretcode = '0' THEN
      --Pause if child request exists
      -- Set parent program status as 'PAUSED' and set global variable value to 'END'
      print_debug_msg('Pausing MASTER Program for update......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
      fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data => 'END');
      print_debug_msg('Complete Pausing MASTER Program for update......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
    ELSIF lc_uretcode = '1' THEN
      print_debug_msg('No Update Child Requests submitted...',TRUE);
      ln_child_request_status   := child_request_status;
      IF ln_child_request_status = 'C' THEN
        report_master_program_stats;
        p_retcode                  := '0';
      ELSIF ln_child_request_status = 'G' THEN
        report_master_program_stats;
        p_retcode := '1'; --Warning
        p_errbuf  := 'One or more child program completed in error or warning';
      END IF;
	  send_output_email(fnd_global.conc_request_id, lc_uretcode);
    ELSIF lc_uretcode = '2' THEN
      p_retcode      := '2';
      p_errbuf       := lc_error_msg;
    END IF;
  END IF;
  IF (lc_req_data = 'END') THEN
	print_debug_msg('Restart program with lc_req_data as '||lc_req_data||' at '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
    p_retcode                 := '0';
    ln_child_request_status   := child_request_status;
	print_debug_msg('ln_child_request_status as '||ln_child_request_status,FALSE);
    IF ln_child_request_status = 'C' THEN
	  print_debug_msg('Invoking report_master_program_stats',FALSE);
      report_master_program_stats;
	  print_debug_msg('Invoking completed for report_master_program_stats',FALSE);
      p_retcode := '0';
    ELSIF ln_child_request_status = 'G' THEN
	  print_debug_msg('Invoking report_master_program_stats',FALSE);
      report_master_program_stats;
	  print_debug_msg('Invoking completed for report_master_program_stats',FALSE);
      p_retcode := '1'; --Warning
      p_errbuf  := 'One or more child program completed in error or warning';
    END IF;

	-- Sennds the Master program output as attachment in email
	send_output_email(fnd_global.conc_request_id, p_retcode);
  ----Below code is added for V1.6
  purge_report_records;
  ----End V1.6

  END IF;
EXCEPTION
WHEN OTHERS THEN
  lc_error_msg := SUBSTR(sqlerrm,1,250);
  print_debug_msg ('ERROR Int Master - '||lc_error_msg,TRUE);
  log_exception ('OD PO POM Inbound Interface(Master)', lc_error_loc, lc_error_msg);
  p_retcode := 2;
END interface_master;


PROCEDURE add_po_line(
    p_batch_id         NUMBER ,
    p_po_number        VARCHAR2 ,
    p_item_id          NUMBER ,
    p_quantity         NUMBER ,
    p_price            NUMBER ,
    p_receipt_req_flag VARCHAR2 ,
	p_uom_code          VARCHAR2,
    p_line_num OUT NUMBER ,
    p_return_status OUT VARCHAR2 ,
    p_error_message OUT VARCHAR2)
AS
  ln_po_header_id po_headers_all.po_header_id%TYPE;
  lc_currency_code po_headers_all.currency_code%TYPE;
  ln_ship_to_location_id po_headers_all.ship_to_location_id%TYPE;
  lc_fob po_headers_all.fob_lookup_code%TYPE;
  lc_freight_terms po_headers_all.freight_terms_lookup_code%TYPE;
  ln_vendor_id po_headers_all.vendor_id%TYPE;
  ln_vendor_site_id po_headers_all.vendor_site_id%TYPE;
  ln_terms_id po_headers_all.terms_id%TYPE;
  ln_line_num po_lines_all.line_num%TYPE;
  ln_agent_id po_headers_all.agent_id%TYPE;
  lc_uom_code mtl_system_items_b.primary_uom_code%TYPE;
  ln_int_line_num po_lines_interface.line_num%TYPE;
  lc_receipt_req_flag po_line_locations_all.receipt_required_flag%TYPE;
BEGIN
  SELECT po_header_id,
    currency_code,
    ship_to_location_id,
    fob_lookup_code,
    freight_terms_lookup_code,
    vendor_id,
    vendor_site_id,
    terms_id,
    agent_id
  INTO ln_po_header_id ,
    lc_currency_code ,
    ln_ship_to_location_id ,
    lc_fob ,
    lc_freight_terms ,
    ln_vendor_id ,
    ln_vendor_site_id ,
    ln_terms_id ,
    ln_agent_id
  FROM po_headers_all pha
  WHERE segment1 = p_po_number;


  SELECT MAX(line_num) + 1
  INTO ln_line_num
  FROM po_lines_all pla
  WHERE po_header_id = ln_po_header_id;

  BEGIN
    SELECT MAX(l.line_num) + 1
    INTO ln_int_line_num
    FROM po_headers_interface h,
      po_lines_interface l
    WHERE h.document_num      = p_po_number
    AND h.interface_header_id = l.interface_header_id
    AND h.batch_id            = p_batch_id
    AND h.process_code        = 'PENDING';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  END;

  IF ln_int_line_num < 9001 THEN
	ln_int_line_num := 9001;
  END IF;

  IF ln_line_num < 9001 THEN
	ln_line_num := 9001;
  END IF;

  ln_line_num := NVL(ln_int_line_num,ln_line_num);
  p_line_num  := ln_line_num;

  lc_receipt_req_flag := NULL;

  -- All PO lines must have same receipt_require_flag
  -- so, inherit this value from other lines
  SELECT MIN(receipt_required_flag)
    INTO lc_receipt_req_flag
  FROM po_line_locations_all plla
  WHERE plla.po_header_id = ln_po_header_id
    AND plla.receipt_required_flag IS NOT NULL;

  IF lc_receipt_req_flag IS NULL THEN
	lc_receipt_req_flag := 'N';
  END IF;


  /*
  SELECT primary_uom_code
  INTO lc_uom_code
  FROM mtl_system_items_b
  WHERE inventory_item_id = p_item_id
  AND organization_id     = 441;
  */
  INSERT
  INTO po_headers_interface
    (
      interface_header_id ,
      batch_id ,
      document_num ,
      currency_code ,
      ship_to_location_id ,
      fob ,
      freight_terms ,
      approval_status ,
      closed_code
      --         ,interface_source_code
      --         ,attribute1
      ,
      process_code ,
      action ,
      document_type_code ,
      org_id ,
      vendor_id ,
      agent_id ,
      vendor_site_id ,
      terms_id ,
      creation_date ,
      created_by ,
      last_update_date ,
      last_updated_by ,
      last_update_login
    )
    VALUES
    (
      po_headers_interface_s.NEXTVAL ,
      p_batch_id ,
      p_po_number ,
      lc_currency_code ,
      ln_ship_to_location_id ,
      lc_fob ,
      lc_freight_terms ,
      'APPROVED' ,
      'OPEN'
      --,'NA-POINTR'
      --,'NA-POINTR'
      ,
      'PENDING' ,
      'UPDATE' ,
      'STANDARD' ,
      404 ,
      ln_vendor_id ,
      ln_agent_id ,
      ln_vendor_site_id ,
      ln_terms_id ,
      SYSDATE ,
      -1 ,
      sysdate ,
      -1 ,
      -1
    );
  INSERT
  INTO po_lines_interface
    (
      interface_line_id ,
      interface_header_id ,
      line_num ,
      item_id ,
      quantity ,
      ship_to_location_id ,
      shipment_num ,
      uom_code ,
      unit_price ,
      fob ,
      freight_terms ,
      creation_date ,
      action ,
      shipment_type ,
      line_type ,
      line_loc_populated_flag ,
      organization_id ,
      closed_code ,
      inspection_required_flag ,
      receipt_required_flag ,
      created_by ,
      last_update_date ,
      last_updated_by ,
      last_update_login
    )
    VALUES
    (
      po_lines_interface_s.NEXTVAL ,
      po_headers_interface_s.currval ,
      ln_line_num ,
      p_item_id ,
      p_quantity ,
      ln_ship_to_location_id ,
      1 ,
      p_uom_code, -- lc_uom_code ,
      p_price ,
      lc_fob ,
      lc_freight_terms ,
      SYSDATE ,
      'ADD' ,
      'STANDARD' ,
      'Goods' ,
      'N' ,
      404 ,
      'OPEN' ,
      'N' ,
      lc_receipt_req_flag ,
      -1 ,
      sysdate ,
      -1 ,
      -1
    );
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  p_line_num      := NULL;
  p_return_status := 'E';
  p_error_message := 'Unexpected Error - Unable to derive PO or PO Line or SKU ' || SQLERRM;
END;

/**************************************************************************
 *									  *
 * 	Is it Trade PO or Not             *
 *  This procedure will be used in Workflow  POAPPRV to skip the PO Approval *
 *  when updating the Trade POs
 * 									  *
 **************************************************************************/

PROCEDURE is_trade_po(itemtype IN VARCHAR2,
		   		itemkey  IN VARCHAR2,
		   		actid    IN NUMBER,
		   		FUNCMODE IN VARCHAR2,
		   		RESULT   OUT NOCOPY VARCHAR2)
IS

	CURSOR c_is_trade_po(c_po_header_id NUMBER) IS
	SELECT count(1)
	FROM po_headers_all pha
	WHERE pha.po_header_id = c_po_header_id
	  AND attribute1 in ('NA-POINTR', 'NA-POCONV');

  l_document_type        PO_DOCUMENT_TYPES_ALL.document_type_code%TYPE;
  l_document_subtype     PO_DOCUMENT_TYPES_ALL.document_subtype%TYPE;
  l_po_header_id         PO_HEADERS_ALL.po_header_id%TYPE;
	ln_trade_po_cnt		     NUMBER;

BEGIN

	IF (g_po_wf_debug = 'Y') THEN
   	PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,
   		'*** In Procedure: XX_PO_POM_INT_PKG.is_trade_po ***');
	END IF;

	IF funcmode <> 'RUN' THEN
		result := 'COMPLETE';
		return;
	END IF;

	ln_trade_po_cnt := 0;

	l_document_type := PO_WF_UTIL_PKG.GetItemAttrText(
                       itemtype => itemtype
                     , itemkey  => itemkey
                     , aname    => 'DOCUMENT_TYPE'
                     );

	l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText(
                       itemtype => itemtype
                     , itemkey  => itemkey
                     , aname    => 'DOCUMENT_SUBTYPE'
                     );

	IF ((l_document_type = 'PO') AND (l_document_subtype = 'STANDARD')) THEN

		l_po_header_id := PO_WF_UTIL_PKG.GetItemAttrText(
							 itemtype => itemtype
						   , itemkey  => itemkey
						   , aname    => 'DOCUMENT_ID'
						   );

		OPEN c_is_trade_po(l_po_header_id);
		FETCH c_is_trade_po INTO ln_trade_po_cnt;
		CLOSE c_is_trade_po;

	END IF;

	IF ln_trade_po_cnt > 0 THEN
		IF (g_po_wf_debug = 'Y') THEN
   		PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,
   		'$$$$$$$ IS TRADE PO =  Y $$$$$$');
		END IF;

		RESULT := 'Y';
	ELSE
		IF (g_po_wf_debug = 'Y') THEN
   		PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,
   		'$$$$$$$ IS TRADE PO =  N $$$$$$');
		END IF;

		RESULT := 'N';
	END IF;

	IF (g_po_wf_debug = 'Y') THEN
   	PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,
   		'*** Finish: XX_PO_POM_INT_PKG.is_trade_po ***');
	END IF;

	return;

EXCEPTION

 WHEN OTHERS THEN
  wf_core.context('POAPPRV', 'XX_PO_POM_INT_PKG.is_trade_po', 'others');
  RAISE;

END is_trade_po;

END XX_PO_POM_INT_PKG;
/
SHOW ERRORS;