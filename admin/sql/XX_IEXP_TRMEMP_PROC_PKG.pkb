SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;

CREATE OR REPLACE PACKAGE BODY XX_IEXP_TRMEMP_PROC_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_IEXP_TRMEMP_PROC_PKG.pkb		                     |
-- | Description :  Plsql package for Iexpenses Terminated Employees Process |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       12-Nov-2014 Paddy Sanjeevi     Initial version                 |
-- |1.1       05-Feb-2015 Paddy Sanjeevi     Defect 655                      |
-- |1.2       11-Feb-2015 Paddy Sanjeevi     Defect 658                      |
-- |1.3       25-Mar-2015 Paddy Sanjeevi     Defect 33870, Translation for Followup notification
-- |1.4       05-May-2015 Paddy Sanjeevi     Added trim in followup procedure|
-- |1.5       07-Jul-2015 Paddy Sanjeevi     Defect 505                      |
-- |1.6       05-Nov-2015 Madhu Bolli    	 E3108 - R122 Retrofit Table Schema Removal(defect#36305))|
-- |1.7       11-JAN-2016 Shereen Colaco     Defect 36364: Updating the category of transactions as NULL |
-- |1.8       12-SEP-2016 Praveen Vanga      Defect 39264 .EXCEL file fomat change to .xls | 
-- |1.9       05-JUN-2017 Uday Jadhav        Defect 42198: Updating the category of CC Trxns having report_header_id as null|
-- +=========================================================================+
AS

-- +======================================================================+
-- | Name        :  xx_attch_rpt                                          |
-- | Description :  This procedure attaching a document to the mail       |
-- |                                                                      |
-- | Parameters  :  conn, p_filename                                      |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
	
PROCEDURE xx_attch_rpt(conn    	  IN OUT NOCOPY utl_smtp.connection,
		       p_filename IN VARCHAR2)
IS
  fil 			BFILE;
  file_len 		PLS_INTEGER;
  buf 			RAW(2100);
  amt 			BINARY_INTEGER := 672 * 3;  /* ensures proper format;  2016 */
  pos 			PLS_INTEGER := 1; /* pointer for each piece */
  filepos 		PLS_INTEGER := 1; /* pointer for the file */
  v_directory_name 	VARCHAR2(100) := 'XXMER_OUTBOUND';
  v_line 		VARCHAR2(1000);
  mesg 			VARCHAR2(32767);
  mesg_len 		NUMBER;
  crlf 			VARCHAR2(2) := chr(13) || chr(10);
  data 			RAW(2100);
  chunks 		PLS_INTEGER;
  len 			PLS_INTEGER := 1;
  modulo 		PLS_INTEGER;
  pieces 		PLS_INTEGER;
  err_num 		NUMBER;
  err_msg 		VARCHAR2(100);
  v_mime_type_bin 	varchar2(30) := 'application/pdf';

BEGIN

  xx_pa_pb_mail.begin_attachment(
  		  conn => conn,
		  mime_type => 'application/pdf',
	          inline => TRUE,
        	  filename => p_filename,
	          transfer_enc => 'base64');

  fil := BFILENAME(v_directory_name,p_filename);
  file_len := dbms_lob.getlength(fil);
  modulo := mod(file_len, amt);
  pieces := trunc(file_len / amt);
  if (modulo <> 0) then
       pieces := pieces + 1;
  end if;
  dbms_lob.fileopen(fil, dbms_lob.file_readonly);
  dbms_lob.read(fil, amt, filepos, buf);
  data := NULL;
  FOR i IN 1..pieces LOOP

    BEGIN
      filepos := i * amt + 1;
      file_len := file_len - amt;
      data := utl_raw.concat(data, buf);
      chunks := trunc(utl_raw.length(data) / xx_pa_pb_mail.MAX_BASE64_LINE_WIDTH);
      IF (i <> pieces) THEN
         chunks := chunks - 1;
      END IF;
      xx_pa_pb_mail.write_raw( conn    => conn,
                               message => utl_encode.base64_encode(data )
  	                     );
      data := NULL;
      if (file_len < amt and file_len > 0) then
          amt := file_len;
      end if;
      dbms_lob.read(fil, amt, filepos, buf);
    EXCEPTION
      WHEN others THEN
        NULL;
    END;
  END LOOP;
  dbms_lob.fileclose(fil);
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in xx_attch_rpt :'||SQLERRM);
END xx_attch_rpt;

-- +======================================================================+
-- | Name        :  get_distribution_list                                 |
-- | Description :  This function gets email distribution list from       |
-- |                the translation                                       |
-- |                                                                      |
-- | Parameters  :  N/A                                                   |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+

FUNCTION get_distribution_list 
RETURN VARCHAR2
IS

  lc_first_rec  	VARCHAR2(1);
  lc_temp_email 	VARCHAR2(2000);
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;

  Type TYPE_TAB_EMAIL IS TABLE OF XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX BY BINARY_INTEGER ;
  EMAIL_TBL 		TYPE_TAB_EMAIL;

BEGIN

     BEGIN
       ------------------------------------------
       -- Selecting emails from translation table
       ------------------------------------------
       SELECT TV.target_value1
             ,TV.target_value2
             ,TV.target_value3
             ,TV.target_value4
             ,TV.target_value5
             ,TV.target_value6
             ,TV.target_value7
             ,TV.target_value8
             ,TV.target_value9
             ,TV.target_value10
       INTO
              EMAIL_TBL(1)
             ,EMAIL_TBL(2)
             ,EMAIL_TBL(3)
             ,EMAIL_TBL(4)
             ,EMAIL_TBL(5)
             ,EMAIL_TBL(6)
             ,EMAIL_TBL(7)
             ,EMAIL_TBL(8)
             ,EMAIL_TBL(9)
             ,EMAIL_TBL(10)
       FROM   XX_FIN_TRANSLATEVALUES TV
             ,XX_FIN_TRANSLATEDEFINITION TD
       WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
       AND   TRANSLATION_NAME = 'XX_IEXP_EMAIL_LIST'
       AND   source_value1    = 'DELETE_ER';
       ------------------------------------
       --Building string of email addresses
       ------------------------------------
       lc_first_rec  := 'Y';
       For ln_cnt in 1..10 Loop
            IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN
                 IF lc_first_rec = 'Y' THEN
                     lc_temp_email := EMAIL_TBL(ln_cnt);
                     lc_first_rec := 'N';
                 ELSE
                     lc_temp_email :=  lc_temp_email ||' ; ' || EMAIL_TBL(ln_cnt);
                 END IF;
            END IF;
       End loop ;
	
       IF lc_temp_email IS NULL THEN

	  lc_temp_email:='iexpense-admin@officedepot.com';

       END IF;

       RETURN(lc_temp_email);
     EXCEPTION
       WHEN others then
         lc_temp_email:='iexpense-admin@officedepot.com';
         RETURN(lc_temp_email);
     END;
END get_distribution_list;




PROCEDURE xx_personal_send_rpt(p_request_id NUMBER)
IS

  v_addlayout 		boolean;
  v_wait 		BOOLEAN;
  v_request_id 		NUMBER;
  vc_request_id 	NUMBER;
  v_file_name 		varchar2(200);
  v_dfile_name		varchar2(200);
  v_sfile_name 		varchar2(200);
  x_dummy		varchar2(2000) 	;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  x_cdummy		varchar2(2000) 	;
  v_cdphase		varchar2(100)	;
  v_cdstatus		varchar2(100)	;
  v_cphase		varchar2(100)   ;
  v_cstatus		varchar2(100)   ;
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;

  conn 			utl_smtp.connection;

  lc_temp_email 	VARCHAR2(2000);

BEGIN

  lc_temp_email:=get_distribution_list;

  v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	                template_code => 'XXIEPEXP',
				template_language => 'en',
				template_territory => 'US',
			        output_format => 'EXCEL');  -- Defect 655

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;

  lc_boolean := fnd_submit.set_print_options(printer=>'XPTR',copies=>1);
  lc_boolean1:= fnd_request.add_printer (printer=>'XPTR',copies=> 1);

  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXIEPEXP','OD: Personal Expenses Submitted in Iexpenses Report',NULL,FALSE,
		p_request_id,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

  IF v_request_id>0 THEN
     COMMIT;
     v_file_name:='XXIEPEXP_'||to_char(v_request_id)||'_1.xls';
     v_sfile_name:='OD_Personal_Expenses_Report'||'_'||TO_CHAR(SYSDATE,'MMDDYYHH24MI')||'.xls';
     v_dfile_name:='$XXMER_DATA/outbound/'||v_sfile_name;
     v_file_name:='$APPLCSF/$APPLOUT/'||v_file_name;
  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
			v_status,v_dphase,v_dstatus,x_dummy))  THEN
     IF v_dphase = 'COMPLETE' THEN

        vc_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY','OD: Common File Copy',NULL,FALSE,
 			  v_file_name,v_dfile_name,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

	IF vc_request_id>0 THEN
	   COMMIT;
        END IF;

        IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,
			v_cstatus,v_cdphase,v_cdstatus,x_cdummy))  THEN

	   IF v_cdphase = 'COMPLETE' THEN  -- child


	        FND_FILE.PUT_LINE(FND_FILE.LOG,'Personal Expenses sent to :'||lc_temp_email);

  	        conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'ODIexpenses@officedepot.com',
	  	        recipients => lc_temp_email,
			cc_recipients=>NULL,
		        subject => 'OD: Personal Expenses Submitted in Iexpenses Report',
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

             --xx_attch_rpt(conn,v_sfile_name);
             xx_pa_pb_mail.xx_attach_excel(conn,v_sfile_name);
             xx_pa_pb_mail.end_attachment(conn => conn);
             xx_pa_pb_mail.attach_text( conn => conn,
  		                        data => 'Please find the attached report for the details' 
				      );

             xx_pa_pb_mail.end_mail( conn => conn );

	     COMMIT;

	   END IF; --IF v_cdphase = 'COMPLETE' THEN -- child
        END IF; 

     END IF; -- IF v_dphase = 'COMPLETE' THEN  -- Main

  END IF; -- IF (FND_CONCURRENT.WAIT_FOR_REQUEST -- Main
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_personal_send_rpt :'||SQLERRM);
END xx_personal_send_rpt;



-- +======================================================================+
-- | Name        :  submit_purge_er_report                                |
-- | Description :  This procedure submits custom report and sends the    |
-- |                report output to the iexpense distribution list       |
-- |                                                                      |
-- | Parameters  :  p_request_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+

PROCEDURE submit_purge_er_report(p_request_id NUMBER)
IS

  v_addlayout 		boolean;
  v_wait 		BOOLEAN;
  v_request_id 		NUMBER;
  vc_request_id 	NUMBER;
  v_file_name 		varchar2(50);
  v_dfile_name		varchar2(50);
  v_sfile_name 		varchar2(50);
  x_dummy		varchar2(2000) 	;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  x_cdummy		varchar2(2000) 	;
  v_cdphase		varchar2(100)	;
  v_cdstatus		varchar2(100)	;
  v_cphase		varchar2(100)   ;
  v_cstatus		varchar2(100)   ;

  conn 			utl_smtp.connection;

  v_recipient		VARCHAR2(100);
  lc_first_rec  	VARCHAR2(1);
  lc_temp_email 	VARCHAR2(2000);
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;

  Type TYPE_TAB_EMAIL IS TABLE OF XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX BY BINARY_INTEGER ;
  EMAIL_TBL 		TYPE_TAB_EMAIL;

BEGIN

     BEGIN
       ------------------------------------------
       -- Selecting emails from translation table
       ------------------------------------------
       SELECT TV.target_value1
             ,TV.target_value2
             ,TV.target_value3
             ,TV.target_value4
             ,TV.target_value5
             ,TV.target_value6
             ,TV.target_value7
             ,TV.target_value8
             ,TV.target_value9
             ,TV.target_value10
       INTO
              EMAIL_TBL(1)
             ,EMAIL_TBL(2)
             ,EMAIL_TBL(3)
             ,EMAIL_TBL(4)
             ,EMAIL_TBL(5)
             ,EMAIL_TBL(6)
             ,EMAIL_TBL(7)
             ,EMAIL_TBL(8)
             ,EMAIL_TBL(9)
             ,EMAIL_TBL(10)
       FROM   XX_FIN_TRANSLATEVALUES TV
             ,XX_FIN_TRANSLATEDEFINITION TD
       WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
       AND   TRANSLATION_NAME = 'XX_IEXP_EMAIL_LIST'
       AND   source_value1    = 'DELETE_ER';
       ------------------------------------
       --Building string of email addresses
       ------------------------------------
       lc_first_rec  := 'Y';
       For ln_cnt in 1..10 Loop
            IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN
                 IF lc_first_rec = 'Y' THEN
                     lc_temp_email := EMAIL_TBL(ln_cnt);
                     lc_first_rec := 'N';
                 ELSE
                     lc_temp_email :=  lc_temp_email ||' ; ' || EMAIL_TBL(ln_cnt);
                 END IF;
            END IF;
       End loop ;
	
       IF lc_temp_email IS NULL THEN

	  lc_temp_email:='iexpense-admin@officedepot.com';

       END IF;
	
     EXCEPTION
       WHEN others then
         lc_temp_email:='iexpense-admin@officedepot.com';
     END;

   v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	                template_code => 'XXIEPRGT',
				template_language => 'en',
				template_territory => 'US',
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;

  lc_boolean := fnd_submit.set_print_options(printer=>'XPTR',copies=>1);
  lc_boolean1:= fnd_request.add_printer (printer=>'XPTR',copies=> 1);

  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXIEPRGT','OD: Purged Un-submitted ER for Terminated Employees',NULL,FALSE,
		p_request_id,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

  IF v_request_id>0 THEN
     COMMIT;
     v_file_name:='XXIEPRGT_'||to_char(v_request_id)||'_1.xls';
     v_sfile_name:='OD_Purged_Txns'||'_'||TO_CHAR(SYSDATE,'MMDDYYHH24MI')||'.xls';
     v_dfile_name:='$XXMER_DATA/outbound/'||v_sfile_name;


  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
			v_status,v_dphase,v_dstatus,x_dummy))  THEN
     IF v_dphase = 'COMPLETE' THEN

        v_file_name:='$APPLCSF/$APPLOUT/'||v_file_name;


        vc_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY','OD: Common File Copy',NULL,FALSE,
 			  v_file_name,v_dfile_name,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

	IF vc_request_id>0 THEN
	   COMMIT;
        END IF;

 	IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,
			v_cstatus,v_cdphase,v_cdstatus,x_cdummy))  THEN

	   IF v_cdphase = 'COMPLETE' THEN  -- child


	      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Email List :'||lc_temp_email);

  	        conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'ODIexpenses@officedepot.com',
	  	        recipients => lc_temp_email,
			cc_recipients=>NULL,
		        subject => 'OD: Purged Un-submitted ER for Terminated Employees Report',
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);


             xx_pa_pb_mail.xx_attach_excel(conn,v_sfile_name);
             xx_pa_pb_mail.end_attachment(conn => conn);
             xx_pa_pb_mail.attach_text( conn => conn,
  		                        data => 'Please find the attached report for the details' 
				      );

             xx_pa_pb_mail.end_mail( conn => conn );

	     COMMIT;

	   END IF; --IF v_cdphase = 'COMPLETE' THEN -- child

 	END IF; --IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,


     END IF; -- IF v_dphase = 'COMPLETE' THEN  -- Main

  END IF; -- IF (FND_CONCURRENT.WAIT_FOR_REQUEST -- Main
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in submit_purge_er_report :'||SQLERRM);

END submit_purge_er_report;

-- +======================================================================+
-- | Name        :  purge_exp_report                                      |
-- | Description :  This procedure deletes the expense report             |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_report_id                                           |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+

PROCEDURE purge_exp_report(p_report_id NUMBER)
IS

  l_TempReportHeaderID   	NUMBER;
  l_TempReportLineID     	NUMBER; 
  l_childItemKeySeq      	NUMBER;
  l_wf_active			BOOLEAN := FALSE;
  l_wf_exist			BOOLEAN := FALSE;
  l_end_date			wf_items.end_date%TYPE;
  l_child_item_key		varchar2(2000);

  CURSOR ReportLines IS
  SELECT report_header_id,
	 report_line_id
    FROM ap_expense_report_lines_all
   WHERE report_header_id=p_report_id;
 
BEGIN 

  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Deleting Report ' || p_report_id);

  --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Delete Distributions - ');

  DELETE 
    FROM AP_EXP_REPORT_DISTS_ALL 
   WHERE report_header_id=p_report_id;
 
  --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Delete Attendees - ');

  DELETE 
    FROM OIE_ATTENDEES_ALL oat 
   WHERE oat.REPORT_LINE_ID IN ( SELECT REPORT_LINE_ID 
				   FROM ap_expense_report_lines_all 
				  WHERE report_header_id = p_report_id);

  --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Delete Add on Mileage Rates - ');

  DELETE 
    FROM OIE_ADDON_MILEAGE_RATES addon 
   WHERE addon.REPORT_LINE_ID IN ( SELECT REPORT_LINE_ID 
				     FROM ap_expense_report_lines_all 
				    WHERE report_header_id = p_report_id);

  --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Delete Perdiem Daily Breakup - ');

  DELETE 
    FROM OIE_PDM_DAILY_BREAKUPS db 
   WHERE db.REPORT_LINE_ID IN ( SELECT REPORT_LINE_ID 
			          FROM ap_expense_report_lines_all 
				 WHERE report_header_id = p_report_id);


  --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Delete Perdiem Destinations - ');

  DELETE 
    FROM OIE_PDM_DESTINATIONS db 
   WHERE db.REPORT_LINE_ID IN ( SELECT REPORT_LINE_ID 
				  FROM ap_expense_report_lines_all 
				 WHERE report_header_id = p_report_id);


  --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Delete Policy Violations - ');

  DELETE 
    FROM AP_POL_VIOLATIONS_ALL 
   WHERE REPORT_HEADER_ID = p_report_id;
  
  --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Update CC transactions, make them available for future reports - ');

  UPDATE AP_CREDIT_CARD_TRXNS_ALL 
     SET REPORT_HEADER_ID = NULL, 
	 CATEGORY = NULL,  -- Defect 36364
	 EXPENSED_AMOUNT = 0
   WHERE REPORT_HEADER_ID  = p_report_id;

  --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Delete Attachments');

  OPEN ReportLines;
  LOOP

    FETCH ReportLines INTO l_TempReportHeaderID, l_TempReportLineID;
    EXIT WHEN ReportLines%NOTFOUND;
    
    /* Delete attachments assocated with the line */

    fnd_attached_documents2_pkg.delete_attachments( X_entity_name => 'OIE_LINE_ATTACHMENTS',
					            X_pk1_value => l_TempReportLineID,
						    X_delete_document_flag => 'Y'
						  );  
  END LOOP;  
  CLOSE ReportLines;

  --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Delete Report Lines');

  DELETE 
    FROM ap_expense_report_lines_all 
   WHERE report_header_id = p_report_id;

  AP_WEB_NOTES_PKG.DeleteERNotes (p_src_report_header_id => p_report_id);

  fnd_attached_documents2_pkg.delete_attachments( X_entity_name => 'OIE_HEADER_ATTACHMENTS',
					          X_pk1_value => p_report_id, 
				 		  X_delete_document_flag => 'Y'
						);
  
  --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Delete Report ');

  DELETE
    FROM ap_expense_report_headers_all 
   WHERE  report_header_id = p_report_id;

  
  --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Stop and purge all workflows');
  
  BEGIN
    SELECT end_date
      INTO l_end_date
      FROM wf_items 
     WHERE item_type = 'APEXP'
       AND item_key  = to_char(p_report_id);
	
    IF l_end_date IS NULL THEN
       l_wf_active := TRUE;
    ELSE
       l_wf_active := FALSE;
    END IF;
    l_wf_exist  := TRUE;
  EXCEPTION
    WHEN no_data_found THEN
     l_wf_active := FALSE;
     l_wf_exist  := FALSE;
  END;

  IF l_wf_exist THEN

       IF l_wf_active THEN

  	  wf_engine.AbortProcess (itemtype => 'APEXP',
	 	 		  itemkey  => to_char(p_report_id),
				  cascade  => TRUE
                                 );
       END IF;

       BEGIN
         l_childItemKeySeq := WF_ENGINE.GetItemAttrNumber('APEXP',p_report_id,'AME_CHILD_ITEM_KEY_SEQ');
       EXCEPTION
	 WHEN others THEN
	   IF (wf_core.error_name = 'WFENG_ITEM_ATTR') THEN
		l_childItemKeySeq := 0;
	   ELSE
	     RAISE;
	   END IF;
       END;

       IF (l_childItemKeySeq IS NOT NULL AND l_childItemKeySeq > 0) THEN

  	  FOR i in 1 .. l_childItemKeySeq 
          LOOP
	
  	    l_child_item_key := to_char(p_report_id) || '-' || to_char(i);

	    BEGIN
   	      SELECT end_date
		INTO l_end_date
		FROM wf_items
	       WHERE item_type = 'APEXP'
	  	 AND item_key  = l_child_item_key;

	      IF l_end_date IS NULL THEN
  	         l_wf_active := TRUE;
	      ELSE
		 l_wf_active := FALSE;
	      END IF;
	      l_wf_exist  := TRUE;
	    EXCEPTION
	      WHEN no_data_found then
	 	l_wf_active := FALSE;
		l_wf_exist  := FALSE;
	    END;
	
 	    IF (l_wf_exist) THEN

		IF l_wf_active THEN
		   wf_engine.AbortProcess (itemtype => 'APEXP',itemkey  => l_child_item_key,cascade  => TRUE);
   	        END IF;
		wf_purge.Items(itemtype => 'APEXP',itemkey  => l_child_item_key);
		wf_purge.TotalPerm(itemtype => 'APEXP',itemkey  => l_child_item_key,runtimeonly => TRUE);
	    END IF;
	  END LOOP;
	END IF;

	wf_purge.Items(itemtype => 'APEXP',
			itemkey  => to_char(p_report_id));

	wf_purge.TotalPerm(itemtype => 'APEXP',
			itemkey  => to_char(p_report_id),
			runtimeonly => TRUE);
  END IF;

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Completed purging of the Report ' || p_report_id);
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while purging report '||TO_CHAR(p_report_id)||' in when others '|| SQLERRM);
    COMMIT;
END purge_exp_report;

-- +======================================================================+
-- | Name        :  get_rpt_status_name                                   |
-- | Description :  This function is to get expense reprot status name    |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_status_code, p_wf_aprvd_flg                         |
-- |                                                                      |
-- | Returns     :  v_status_name                                         |
-- |                                                                      |
-- +======================================================================+

FUNCTION get_rpt_status_name(p_status_code IN VARCHAR2,p_wf_aprvd_flg IN VARCHAR2)
RETURN VARCHAR2
IS

v_status_name VARCHAR2(80);

BEGIN

  IF p_status_code IS NULL AND p_wf_aprvd_flg IN ('S','I') THEN
	
     BEGIN
       SELECT displayed_field
         INTO v_status_name
         FROM ap_lookup_codes
        WHERE lookup_type='EXPENSE REPORT STATUS'
          AND lookup_code=DECODE(p_wf_aprvd_flg,'S','SAVED','I','INPROGRESS');
     EXCEPTION
       WHEN others THEN
	 v_status_name:=NULL;
     END;

  ELSIF p_status_code IS NOT NULL THEN  

    BEGIN
      SELECT displayed_field
        INTO v_status_name
        FROM ap_lookup_codes
       WHERE lookup_type='EXPENSE REPORT STATUS'
         AND lookup_code=p_status_code;
    EXCEPTION
      WHEN others THEN
	v_status_name:=NULL;
    END;
  END IF;
  RETURN(v_status_name);
EXCEPTION
  WHEN others THEN
    v_status_name:=NULL;
    RETURN(v_status_name);
END get_rpt_status_name;

-- +======================================================================+
-- | Name        :  xx_purge_unsub_er                                     |
-- | Description :  This procedure will be called from the concurrent prog|
-- |                "OD: Purged Un-submitted ER for Terminated Employees" |
-- |                to purge unsubmitted expense report and submit report |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :  x_errbuf, x_retcode                                   |
-- |                                                                      |
-- +======================================================================+

PROCEDURE xx_purge_unsub_er  ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
  		             )
IS

CURSOR c_emp_info
IS
sELECT employee_number, rowid drowid
  FROM xx_iexp_trmtd_emp
 WHERE process_Flag='N';
 

CURSOR c_employee
IS
SELECT a.employee_id,a.rowid drowid,a.employee_number
  FROM xx_iexp_trmtd_emp a
 WHERE a.process_Flag='N';

CURSOR c_unsub_rpt(p_employee_id NUMBER)
IS
SELECT DISTINCT a.report_header_id,a.invoice_num,b.full_name,b.employee_number,
       a.override_approver_name,a.expense_status_code,a.workflow_approved_flag
  FROM ap_expense_report_headers_all a ,
       per_all_people_f b
 WHERE b.person_id=p_employee_id
   AND a.employee_id=b.person_id
   AND (a.expense_status_code IN ('EMPAPPR','INPROGRESS','WITHDRAWN','SAVED','REJECTED','ERROR') OR a.expense_status_code IS NULL)
UNION
SELECT rpt.report_header_id,rpt.invoice_num,per.full_name,per.employee_number,
       rpt.override_approver_name,rpt.expense_status_code,rpt.workflow_approved_flag
  FROM per_all_people_f per,
       ap_expense_report_headers_all rpt,  
       wf_notifications b,
       wf_items a 
 WHERE a.item_type='APEXP'
   AND a.begin_date>SYSDATE-60
   AND b.message_type=a.item_type
   AND b.more_info_role is not null
   AND substr(b.item_key,1,length(b.item_key)-2)=a.item_key
   AND rpt.invoice_num=b.user_key
   AND per.person_id=rpt.employee_id
   AND per.person_id=p_employee_id
   AND sysdate between per.effective_start_date AND per.effective_end_date
   AND b.more_info_role=per.employee_number
   AND rpt.expense_status_code='PENDMGR'
 ORDER BY 1;   

CURSOR C_cc_txns(P_report_id NUMBER) 
IS
SELECT  NVL(SUM(expensed_amount),0) amount
       ,category
  FROM ap_credit_card_trxns_all
 WHERE report_header_id=p_report_id
 GROUP BY category;

v_cash_amount			NUMBER:=0;
v_report_status 		VARCHAR2(80);
v_pers_cc_amt			NUMBER:=0;
v_request_id			NUMBER;

BEGIN

  DELETE
    FROM xx_iexp_trmtd_emp
   WHERE creation_date<TRUNC(SYSDATE-45);
  COMMIT;

  DELETE
    FROM xx_iexp_purge_txns
   WHERE creation_date<TRUNC(SYSDATE-3);
  COMMIT;

  FOR emp IN c_emp_info LOOP

    UPDATE xx_iexp_trmtd_emp
       SET (employee_id,employee_name,trmd_mgr_actemp_ntfy_flag)=(SELECT person_id,full_name,'N'
                                          FROM per_all_people_f
                                         WHERE employee_number=emp.employee_number
                                           AND rownum<2)
     WHERE rowid=emp.drowid;

  END LOOP;
  COMMIT;

  v_request_id:=FND_GLOBAL.conc_request_id;

  FOR c IN c_employee LOOP

   FND_FILE.PUT_LINE(FND_FILE.LOG,'Employee # :'||c.employee_number);

    FOR cur IN c_unsub_rpt(c.employee_id) LOOP

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside c_unsub_rpt :||cur.invoice_num');

       v_report_status:=get_rpt_status_name(cur.expense_status_code,cur.workflow_approved_flag);

	FOR cr IN c_cc_txns(cur.report_header_id) LOOP

	  IF cr.category='BUSINESS' THEN

	    BEGIN
              INSERT
	      INTO xx_iexp_purge_txns
		   ( 	 request_id
	  		,employee_name
			,approver_name
			,report_no
			,report_status
			,personal_txn_amt
			,business_txn_amt
			,cash_txn_amt
			,creation_date
			,created_by
			,last_update_date
			,last_updated_by
		    )
	      VALUES
		   (	 v_request_id
			,cur.full_name
			,cur.override_approver_name
			,cur.invoice_num
			,v_report_status
			,NULL
			,cr.amount
			,NULL
			,SYSDATE,fnd_global.user_id,
			SYSDATE,fnd_global.user_id
		   );
	    EXCEPTION
	      WHEN others THEN
	       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while inserting xx_iexp_purge_txns for the report : '|| cur.invoice_num||', '||SQLERRM);
 	    END;
	  ELSIF cr.category='PERSONAL' THEN
	    BEGIN
              INSERT
	      INTO xx_iexp_purge_txns
		   ( 	 request_id
	  		,employee_name
			,approver_name
			,report_no
			,report_status
			,personal_txn_amt
			,business_txn_amt
			,cash_txn_amt
			,creation_date
			,created_by
			,last_update_date
			,last_updated_by
		    )
	      VALUES
		   (	 v_request_id
			,cur.full_name
			,cur.override_approver_name
			,cur.invoice_num
			,v_report_status
			,cr.amount
			,NULL
			,NULL
			,SYSDATE,fnd_global.user_id,
			 SYSDATE,fnd_global.user_id
		   );
	    EXCEPTION
	      WHEN others THEN
        	FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while inserting xx_iexp_purge_txns for the report : '|| cur.invoice_num||', '||SQLERRM);
 	    END;
	  END IF;
	END LOOP;

	SELECT NVL(SUM(amount),0)
	  INTO v_cash_amount
          FROM ap_expense_report_lines_all
         WHERE report_header_id=cur.report_header_id
           AND credit_card_trx_id is null;
	   --category_code IN ('MISC','PER_DIEM','MILEAGE');
	
	IF v_cash_amount<>0 THEN

	    BEGIN
              INSERT
	      INTO xx_iexp_purge_txns
		   ( 	 request_id
	  		,employee_name
			,approver_name
			,report_no
			,report_status
			,personal_txn_amt
			,business_txn_amt
			,cash_txn_amt
			,creation_date
			,created_by
			,last_update_date
			,last_updated_by
		    )
	      VALUES
		   (	 v_request_id
			,cur.full_name
			,cur.override_approver_name
			,cur.invoice_num
			,v_report_status
			,NULL
			,NULL
			,v_cash_amount
			,SYSDATE,fnd_global.user_id,
		         SYSDATE,fnd_global.user_id
		   );
	    EXCEPTION
	      WHEN others THEN
	       	FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while inserting xx_iexp_purge_txns for the report : '|| cur.invoice_num||', '||SQLERRM);
 	    END;
	END IF;

	SELECT NVL(SUM(billed_amount-expensed_amount),0)
	  INTO v_pers_cc_amt
	  FROM ap_credit_card_trxns_all
 	 WHERE report_header_id=cur.report_header_id
   	   AND billed_amount-expensed_amount<>0;

	IF v_pers_cc_amt<>0 THEN

	    BEGIN
              INSERT
	      INTO xx_iexp_purge_txns
		   ( 	 request_id
	  		,employee_name
			,approver_name
			,report_no
			,report_status
			,personal_txn_amt
			,business_txn_amt
			,cash_txn_amt
			,creation_date
			,created_by
			,last_update_date
			,last_updated_by
		    )
	      VALUES
		   (	 v_request_id
			,cur.full_name
			,cur.override_approver_name
			,cur.invoice_num
			,v_report_status
			,v_pers_cc_amt
			,NULL
			,NULL
			,SYSDATE,fnd_global.user_id,
			 SYSDATE,fnd_global.user_id
		   );
	    EXCEPTION
	      WHEN others THEN
	        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while inserting xx_iexp_purge_txns for the report : '|| cur.invoice_num||', '||SQLERRM);
 	    END;

	END IF;

	v_cash_amount:=0;
        v_pers_cc_amt:=0;
	COMMIT;

        purge_exp_report(cur.report_header_id);

    END LOOP;
    UPDATE xx_iexp_trmtd_emp
       SET reports_delete_flag='Y',
	   process_flag='I'
     WHERE rowid=c.drowid;
	
	-- Start  defect #42198
    UPDATE ap_credit_card_trxns_all acct
       SET CATEGORY = NULL 
    WHERE acct.report_header_id  is NULL
      AND acct.category is NOT NULL
      AND EXISTS (SELECT 1 FROM ap_cards_all aca 
                  WHERE aca.card_id = acct.card_id
                    AND aca.employee_id=c.employee_id
                  );
    -- End
  END LOOP;
  COMMIT;
  submit_purge_er_report(v_request_id);
EXCEPTION
  WHEN others THEN
    x_errbuf:=SUBSTR(SQLERRM,1,150);
    x_retcode:='2';
END xx_purge_unsub_er;


-- +======================================================================+
-- | Name        :  submit_cctxn_trmemp_report                            |
-- | Description :  This procedure submits seeded report and sends the    |
-- |                report output to the iexpense distribution list       |
-- |                                                                      |
-- | Parameters  :  N/A                                                   |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE submit_cctxn_trmemp_report
IS

  v_wait 		BOOLEAN;
  v_request_id 		NUMBER;
  vc_request_id 	NUMBER;
  v_file_name 		varchar2(100);
  v_dfile_name		varchar2(200);
  v_sfile_name 		varchar2(100);
  x_dummy		varchar2(2000) 	;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  x_cdummy		varchar2(2000) 	;
  v_cdphase		varchar2(100)	;
  v_cdstatus		varchar2(100)	;
  v_cphase		varchar2(100)   ;
  v_cstatus		varchar2(100)   ;

  conn 			utl_smtp.connection;
  v_email_list		VARCHAR2(2000);
  v_start_date		VARCHAR2(30);
  v_end_date		VARCHAR2(30);
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;


BEGIN

  v_email_list:=get_distribution_list;

  v_start_date:='2000/01/01 00:00:00';
  v_end_date:=TO_CHAR(TRUNC(SYSDATE),'YYYY/MM/DD HH24:MI:SS');

  lc_boolean := fnd_submit.set_print_options(printer=>'XPTR',copies=>1);
  lc_boolean1:= fnd_request.add_printer (printer=>'XPTR',copies=> 1);

  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('SQLAP','APXCCOUT_INACT_PROC','Credit Card Transactions Inactive Employees Process',NULL,FALSE,
		'CC_INACT_EMPL_REPORT','10000','T',v_start_date,v_end_date,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

  IF v_request_id>0 THEN
     COMMIT;
     v_file_name:='o'||to_char(v_request_id)||'.out';
     v_sfile_name:='OD_CCTxns_Inactive_Employees'||'_'||TO_CHAR(SYSDATE,'MMDDYYHH24MI')||'.PDF';
     v_dfile_name:='$XXMER_DATA/outbound/'||v_sfile_name;


  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
			v_status,v_dphase,v_dstatus,x_dummy))  THEN
     IF v_dphase = 'COMPLETE' THEN

        v_file_name:='$APPLCSF/$APPLOUT/'||v_file_name;


        vc_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY','OD: Common File Copy',NULL,FALSE,
 			  v_file_name,v_dfile_name,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

	IF vc_request_id>0 THEN
	   COMMIT;
        END IF;

 	IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,
			v_cstatus,v_cdphase,v_cdstatus,x_cdummy))  THEN

	   IF v_cdphase = 'COMPLETE' THEN  -- child

		FND_FILE.PUT_LINE(FND_FILE.LOG, 'Email Address :'||v_email_list);

  	        conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'ODIexpenses@officedepot.com',
	  	        recipients => v_email_list,
			cc_recipients=>NULL,
		        subject => 'Credit Card Transactions Inactive Employees Process Report',
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

		FND_FILE.PUT_LINE(FND_FILE.LOG, 'before attch ');

              xx_attch_rpt(conn,v_sfile_name);
             xx_pa_pb_mail.end_attachment(conn => conn);
             xx_pa_pb_mail.attach_text( conn => conn,
  		                        data => 'Please find the attached Credit Card Transactions Inactive Employees Process Report' 
				      );


             xx_pa_pb_mail.end_mail( conn => conn );

	     COMMIT;

	   END IF; --IF v_cdphase = 'COMPLETE' THEN -- child

 	END IF; --IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,


     END IF; -- IF v_dphase = 'COMPLETE' THEN  -- Main

  END IF; -- IF (FND_CONCURRENT.WAIT_FOR_REQUEST -- Main
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in submit_cctxn_trmemp_report :'||SQLERRM);

END submit_cctxn_trmemp_report;


-- +=========================================================================+
-- | Name        :  termd_emp_mgr                                            |
-- | Description :  This procedure will be called from xx_iexp_inact_ccproc  |
-- |                to send notifications to iexpenses team, if both employee|
-- |                and manager are terminated                               |
-- |                                                                         |
-- | Parameters  :  N/A                                                      |
-- |                                                                         |
-- | Returns     :                                                           |
-- |                                                                         |
-- +=========================================================================+

PROCEDURE termd_emp_mgr
IS

CURSOR C_trm_emp_mgr
IS
SELECT  a.employee_id
       ,a.employee_number
       ,a.employee_name	
       ,a.rowid drowid
  FROM xx_iexp_trmtd_emp a
  WHERE process_flag='I'
    AND TRUNC(creation_date)<=TRUNC(SYSDATE-1)  
    AND NVL(term_mgr_emp_ntfy_flag,'N')='N'
    AND EXISTS (SELECT 'x'
		 FROM per_all_assignments_f
                WHERE person_id=a.employee_id
		  AND SYSDATE between effective_start_date and effective_end_date
		  AND assignment_status_type_id=3);


CURSOR C_empl(p_person_id NUMBER)
IS
select a.person_id employee_id,a.employee_number,a.full_name,b.supervisor_id
  from per_all_people_f a,
       per_all_assignments_f b
 where a.person_id=p_person_id
   and sysdate between b.effective_start_date and b.effective_end_date
   and a.person_id=b.person_id
   and sysdate between a.effective_start_date and a.effective_end_date
   AND b.assignment_status_type_id=3;

CURSOR c_mgr(p_mgr_id NUMBER)
IS
select a.employee_number,a.full_name,a.person_type_id,b.assignment_status_type_id
  from per_all_people_f a,
       per_all_assignments_f b
 where a.person_id=p_mgr_id
   and sysdate between b.effective_start_date and b.effective_end_date
   and a.person_id=b.person_id
   and sysdate between a.effective_start_date and a.effective_end_date;

v_total_rpt 		NUMBER:=0;
v_total_amt 		NUMBER:=0;
v_unused_amt 		NUMBER:=0;
v_dtotal_amt		VARCHAR2(50);
v_dunused_amt		VARCHAR2(50);

v_email_list    	VARCHAR2(2000);
v_subject		VARCHAR2(500);
conn 			utl_smtp.connection;
v_text			VARCHAR2(2000);
v_instance		VARCHAR2(10);
BEGIN

  v_email_list:=get_distribution_list;

  SELECT name INTO v_instance FROM v$database;

  v_subject   :='Action Required for Terminated Employee with outstanding Credit Card transaction(s) with Terminated Manager';

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail:'||v_subject;  --- Defect 658

       END IF;


  FOR c IN c_trm_emp_mgr LOOP

      FOR cur IN c_empl(c.employee_id) LOOP

	FOR cmgr IN c_mgr(cur.supervisor_id) LOOP

	    IF cmgr.assignment_status_type_id=3 THEN

	       SELECT COUNT(1),NVL(SUM(total),0)
		 INTO v_total_rpt,v_total_amt
	 	 FROM ap_expense_report_headers_all
		WHERE employee_id=cur.employee_id
		  AND expense_status_code='PENDMGR';


	       SELECT NVL(sum(txn.transaction_amount),0)
	         INTO v_unused_amt
	         FROM ap_credit_card_trxns_all txn,
                      ap_cards_all crd
                WHERE crd.employee_id=cur.employee_id
                  AND txn.validate_code = 'Y'
                  AND txn.payment_flag <> 'Y'
                  AND txn.billed_amount IS NOT NULL
                  AND txn.card_id=crd.card_id
                  AND txn.card_program_id = crd.card_program_id
                  AND txn.card_id = crd.card_id
                  AND (NVL (txn.CATEGORY, 'BUSINESS') NOT IN ('DISPUTED', 'CREDIT', 'MATCHED', 'DEACTIVATED'))
                  AND TRUNC (NVL (txn.trx_available_date,TO_DATE ('01-01-1952 00:00:00','DD-MM-YYYY HH24:MI:SS'))) <= TRUNC (SYSDATE)
                  AND report_header_id IS NULL;

 	       v_dtotal_amt  :=TRIM(TO_CHAR(v_total_amt, '$999G999G999D99'));
	       v_dunused_amt :=TRIM(TO_CHAR(v_unused_amt, '$999G999G999D99'));



       	       v_text	:=         'Terminated Employee            : '||cur.full_name ||chr(10);
	       v_text   :=v_text ||'Terminated ID                  : '||cur.employee_number||chr(10);
	       v_text   :=v_text ||'Terminated Employee Manager    : '||cmgr.full_name||chr(10);
	       v_text   :=v_text ||'Terminated Employee Manager ID : '||cmgr.employee_number||chr(10);
	       v_text   :=v_text ||chr(10);
	       v_text   :=v_text ||chr(10);
	       v_text   :=v_text ||'You are receiving this email because the terminated employee mentioned above has outstanding Credit Card';
	       v_text   :=v_text ||' transaction(s) that require your attention.'||chr(10);
	       v_text   :=v_text ||chr(10);
	       v_text   :=v_text ||'Please request Non Single Sign On access for terminated employee mentioned above and take action on the pending report(s).';
	       v_text   :=v_text ||' Once completed move the terminated credit card to the next active approver.'||chr(10);
	       v_text   :=v_text ||chr(10);
	       v_text   :=v_text ||chr(10);
	       v_text   :=v_text ||'For the terminated employee mentioned above '||chr(10);
	       v_text   :=v_text ||chr(10);
	       v_text   :=v_text ||'ER report with status of Pending Manager Approval          : '||TO_CHAR(v_total_rpt)||CHR(10);
	       v_text   :=v_text ||'Amount for the ER with status of "Pending Manager Approval": '||v_dtotal_amt||chr(10);
	       v_text   :=v_text ||'Amount of unused Credit Card Transactions                  : '||v_dunused_amt||chr(10);


	      FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Address :'||v_email_list);

	       conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'ODIexpenses@officedepot.com',
	  	        recipients => v_email_list,
			cc_recipients=>NULL,
		        subject => v_subject,
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

               xx_pa_pb_mail.attach_text( conn => conn,
  		                          data => v_text
				        );

               xx_pa_pb_mail.end_mail( conn => conn );

	       UPDATE xx_iexp_trmtd_emp
	          SET term_mgr_emp_ntfy_flag='Y'
	        WHERE rowid=c.drowid;
	       COMMIT;
	
	    ELSE

	       UPDATE xx_iexp_trmtd_emp
	          SET term_mgr_emp_ntfy_flag='P'
	        WHERE rowid=c.drowid;
	       COMMIT;

	    END IF;	

	END LOOP;

      END LOOP;

  END LOOP;

EXCEPTION
  WHEN others THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'When others in the procedure termd_emp_mgr ' || SQLERRM);    
END termd_emp_mgr;


-- +================================================================================+
-- | Name        :  xx_iexp_inact_ccproc                                            |
-- | Description :  This procedure will be called from the concurrent program       |
-- |                "OD: Credit Card Transactions Inactive Employees Process"       |
-- |                to submit "Credit Card Transactions Inactive Employees Process" |
-- |                and send initial notification to the terminated employee manager|
-- |                                                                                |
-- |                                                                                |
-- | Parameters  :  N/A                                                             |
-- |                                                                                |
-- | Returns     :  x_errbuf, x_retcode                                             |
-- |                                                                                |
-- +================================================================================+

PROCEDURE xx_iexp_inact_ccproc ( x_errbuf      	OUT NOCOPY VARCHAR2
                                ,x_retcode     	OUT NOCOPY VARCHAR2
			       )
IS

CURSOR c_notification
IS
SELECT a.employee_id,
       a.employee_number,
       a.employee_name,
       a.final_process_date,
       a.rowid drowid
  FROM xx_iexp_trmtd_emp a
  WHERE process_flag='I'
   AND TRUNC(creation_date)<=TRUNC(SYSDATE-1)
   AND TRUNC(SYSDATE) <= TRUNC(final_process_date-9)
   AND NVL(initial_notify_flag,'N')='N';
   --AND TRUNC(final_process_date-SYSDATE)>=9

CURSOR C_supervisor(p_employee_id NUMBER)
IS
SELECT per.employee_number,
       per.full_name,
       per.email_address,
       per.person_id
  FROM per_all_people_f per,
       WF_ITEM_ATTRIBUTE_VALUES b,
       WF_ITEM_ATTRIBUTE_VALUES ie, 
       wf_items a
 WHERE TRUNC(a.begin_date)>TRUNC(sysdate-2)
   AND a.item_type='APCCARD'
   AND ie.item_type=a.item_type
   AND ie.item_key=a.item_key
   AND ie.name='INACT_EMPLOYEE_ID'
   AND ie.number_value=p_employee_id
   AND b.item_type=a.item_type
   AND b.item_key=a.item_key
   AND b.name='PREPARER_EMPL_ID'
   AND per.person_id=b.number_value
   AND sysdate between per.effective_start_date and per.effective_end_date
   AND EXISTS (SELECT 'x'
                 FROM wf_notifications
                WHERE message_type=a.item_type
                  AND message_name='OIE_MSG_MGR_INACTIVE_EMPL_EX_1'
                  AND item_key=a.item_key
                  AND original_recipient=per.employee_number);

CURSOR c_sysadmin
IS
SELECT e.employee_id,
       e.employee_number,
       e.employee_name,
       e.final_process_date,
       e.rowid drowid
  FROM xx_iexp_trmtd_emp e
 WHERE process_flag='I'
   AND TRUNC(creation_date)<=TRUNC(SYSDATE-1)
   AND NVL(initial_notify_flag,'N')='N'
   AND EXISTS (SELECT 'x'
 		FROM wf_notifications c,			
		     WF_ITEM_ATTRIBUTE_VALUES ie, 			
       		     wf_items a		
	       WHERE a.item_type='APCCARD'			
		 AND a.begin_date>sysdate-5 			
		 AND ie.item_type=a.item_type			
   		 AND ie.item_key=a.item_key			
   		 AND ie.name='INACT_EMPLOYEE_ID'
		 AND ie.number_value=e.employee_id
		 AND c.message_type=ie.item_type
   		 AND c.message_name='OIE_MSG_MGR_INACTIVE_EMPL_EX_1'
   		 AND c.item_key=ie.item_key
   		 AND c.recipient_role='SYSADMIN');


CURSOR c_noexpense
IS
SELECT e.employee_id,
       e.employee_number,
       e.employee_name,
       e.final_process_date,
       e.rowid drowid
  FROM xx_iexp_trmtd_emp e
 WHERE process_flag='I'
   AND TRUNC(creation_date)<=TRUNC(SYSDATE-2)
   AND NVL(initial_notify_flag,'N')='N'
   AND NOT EXISTS (SELECT 'x'
 		FROM WF_ITEM_ATTRIBUTE_VALUES ie, 			
       		     wf_items a		
	       WHERE a.item_type='APCCARD'			
		 AND a.begin_date>sysdate-5 			
		 AND ie.item_type=a.item_type			
   		 AND ie.item_key=a.item_key			
   		 AND ie.name='INACT_EMPLOYEE_ID'
		 AND ie.number_value=e.employee_id);


v_sup_email_addr 	VARCHAR2(100);
v_text			VARCHAR2(8000);
v_subject		VARCHAR2(3000);
v_instance		VARCHAR2(10);
conn 			utl_smtp.connection;
v_email_list		VARCHAR2(2000);

BEGIN

  submit_cctxn_trmemp_report;

  v_email_list:=get_distribution_list;

  SELECT name INTO v_instance FROM v$database;

  FOR cur IN c_sysadmin LOOP

      UPDATE xx_iexp_trmtd_emp
  	 SET initial_notify_flag='Z'
       WHERE rowid=cur.drowid;
  END LOOP;
  COMMIT;

  FOR cur IN C_notification LOOP
	
       FOR c IN c_supervisor(cur.employee_id) LOOP

	  v_sup_email_addr:=NULL;

           v_sup_email_addr:=c.email_address;

       v_subject:='Action Required for Terminated Employee with outstanding Credit Card transaction(s)';
	

       v_text	:='Terminated Employee : '||cur.employee_name ||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Action Required Due Date: '||TO_CHAR(cur.final_process_date-7,'DD-MON-RR')||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'You are receiving this email because the terminated employee mentioned above has outstanding Credit Card transaction(s) that require your attention.'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Please log in to iExpense and follow the instructions below to submit a final Expense Report on behalf of this employee.'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Instructions:'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Log in to Oracle and Review your worklist for an item with a subject line related to '||cur.employee_name||', and click on the link'||chr(10);
       v_text   :=v_text ||'Click the "Accept" button to gain access to the terminated employee'||CHR(39)||'s credit card transactions'||chr(10);
       v_text   :=v_text ||'Select "OD IExpenses" Responsibility'||chr(10);
       v_text   :=v_text ||'Click Create Expense Report'||chr(10);
       v_text   :=v_text ||'Select the terminated employee'||CHR(39)||'s name from the drop down list of values in the "Name" field and complete the Expense Report'||chr(10);
       v_text   :=v_text ||'If you do not have any or all required receipts in order to submit the Expense Report, please attach a document that indicates the receipt(s) are not available for this terminated employee.'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||chr(10);       
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Expense Reports must be completed and approved prior to the "Action Required Due Date:" mentioned above.'||chr(10);
       v_text   :=v_text ||'Please note: You will receive a weekly notification every Monday until the pending credit card transaction(s) have been processed'||chr(10);
       v_text   :=v_text ||'If you have any questions, please contact iExpense-admin@officedepot.com for assistance'||chr(10);

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       IF v_sup_email_addr IS NULL THEN
          v_sup_email_addr:=v_email_list; 
       END IF;
    
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Address :'||v_sup_email_addr);

       conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'ODIexpenses@officedepot.com',
	  	        recipients => v_sup_email_addr,
			cc_recipients=>NULL,
		        subject => v_subject,
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);


        xx_pa_pb_mail.attach_text( conn => conn,
  		                        data => v_text 
				      );

        xx_pa_pb_mail.end_mail( conn => conn );

	UPDATE xx_iexp_trmtd_emp
	   SET initial_notify_flag='Y',
	       initial_notify_date=TRUNC(SYSDATE),
	       supervisor_id=c.person_id,
	       supervisor_name=c.full_name,
	       mgr_email_address=c.email_address
         WHERE rowid=cur.drowid;

	COMMIT;

       END LOOP;

  END LOOP;
  termd_emp_mgr;

  --FOR cur IN c_noexpense LOOP

  --    UPDATE xx_iexp_trmtd_emp
  --	 SET initial_notify_flag='Z'
  --     WHERE rowid=cur.drowid;
  --END LOOP;
  --COMMIT;

EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_iexp_inact_ccproc_pkg :'||SQLERRM);
    x_errbuf:=SUBSTR(SQLERRM,1,150);
    x_retcode:='2'; 
END xx_iexp_inact_ccproc;

-- +================================================================================+
-- | Name        :  xx_trdmgr_actemp_proc                                           |
-- | Description :  This procedure will be called from the concurrent program       |
-- |                "OD: Employee Notification for Terminated Manager"              |
-- |                to send notification to employees if the manager is terminated  |
-- |                                                                                |
-- |                                                                                |
-- | Parameters  :  N/A                                                             |
-- |                                                                                |
-- | Returns     :  x_errbuf, x_retcode                                             |
-- |                                                                                |
-- +================================================================================+

PROCEDURE xx_trdmgr_actemp_proc ( x_errbuf      	OUT NOCOPY VARCHAR2
                                 ,x_retcode     	OUT NOCOPY VARCHAR2
		 	        )
IS

CURSOR c_notification
IS
SELECT a.employee_id,
       a.employee_number,
       a.employee_name,
       a.final_process_date,
       NVL(a.trmd_mgr_actemp_ntfy_date,SYSDATE) trmd_mgr_actemp_ntfy_date,
       a.rowid drowid
  FROM xx_iexp_trmtd_emp a
 WHERE SYSDATE < final_process_date
   AND trmd_mgr_actemp_ntfy_flag='N'
   AND EXISTS (SELECT 'x'
		 FROM per_all_assignments_f
                WHERE person_id=a.employee_id
		  AND SYSDATE between effective_start_date and effective_end_date
		  AND assignment_status_type_id=3);


CURSOR C_empl(p_employee_id NUMBER)
IS
SELECT distinct emp.full_name,emp.employee_number tm_empno,emp.email_address
  FROM per_all_people_f emp,
       ap_expense_report_headers_all b
 WHERE b.override_approver_id=p_employee_id
   AND b.expense_status_code='PENDMGR'
   AND emp.person_id=b.employee_id
   AND SYSDATE BETWEEN emp.effective_start_date AND emp.effective_end_date;

v_text			VARCHAR2(8000);
v_subject		VARCHAR2(3000);
v_instance		VARCHAR2(10);
conn 			utl_smtp.connection;
v_email_address		VARCHAR2(100);
v_email_list		VARCHAR2(2000);

BEGIN

  v_subject :='Action Required:  Expense report Pending Manager Approval';

  v_email_list:=get_distribution_list;


  SELECT name INTO v_instance FROM v$database;

  FOR c IN c_notification LOOP

    FOR cur IN c_empl(c.employee_id) LOOP

      v_text:=NULL;
      v_email_address:=NULL;

         v_text	:='To: '||cur.full_name||chr(10);
         v_text :=v_text||'Terminated Manager: '||c.employee_name||chr(10);
         v_text   :=v_text ||chr(10);
         v_text   :=v_text ||'You are receiving this email because you have pending Expense Report(s) that require your attention.';
         v_text   :=v_text ||' Please log in to "OD iExpenses" responsibility, withdraw and delete only your Expense Report(s) with the status of ';
         v_text   :=v_text ||'"Pending Manger Approval" AND THE CURRENT APPROVER FIELD CONTAINS THE MANAGER MENTIONED ABOVE.'||chr(10);
         v_text   :=v_text ||'Please create a new Expense Report for these transactions and submit for approval.'||chr(10);
         v_text   :=v_text ||chr(10);
	 v_text   :=v_text ||'If you have any questions, please contact iExpense-admin@officedepot.com for assistance'||chr(10);

	 IF cur.email_address IS NOT NULL THEN
	    v_email_address:=cur.email_address;
         ELSE
	    v_email_address:=v_email_list;
	 END IF;
	

         IF v_instance<>'GSIPRDGB' THEN
 
 	    v_subject:='Please Ignore this mail :'||v_subject;

         END IF;

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Email Address :'||v_email_address);

         conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'ODIexpenses@officedepot.com',
	  	        recipients => v_email_address,
			cc_recipients=>v_email_address,
		        subject => v_subject,
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);

        xx_pa_pb_mail.attach_text( conn => conn,
  		                   data => v_text 
			         );

        xx_pa_pb_mail.end_mail( conn => conn );
	
    END LOOP;
    UPDATE xx_iexp_trmtd_emp
       SET trmd_mgr_actemp_ntfy_date=TRUNC(SYSDATE),
	   trmd_mgr_actemp_ntfy_flag='Y'
     WHERE rowid=c.drowid;
    COMMIT;
  END LOOP;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_trdmgr_actemp_proc :'||SQLERRM);
    x_errbuf:=SUBSTR(SQLERRM,1,150);
    x_retcode:='2'; 
END xx_trdmgr_actemp_proc;


-- +================================================================================+
-- | Name        :  xx_followup_txn                                                 |
-- | Description :  This procedure will be called from the concurrent program       |
-- |                "OD: IE Follow-up Unprocessed txns for Terminated Employee"     |
-- |                to send follow-up notification to manager if unsubmitted txns   |
-- |                exists for the terminated employee                              |
-- |                                                                                |
-- | Parameters  :  N/A                                                             |
-- |                                                                                |
-- | Returns     :  x_errbuf, x_retcode                                             |
-- |                                                                                |
-- +================================================================================+


PROCEDURE xx_followup_txn ( x_errbuf      	OUT NOCOPY VARCHAR2
                           ,x_retcode     	OUT NOCOPY VARCHAR2
		 	  )
IS

CURSOR C1 
IS
SELECT a.employee_id,
       a.rowid drowid
  FROM xx_iexp_trmtd_emp a
 WHERE process_flag='I'
   AND initial_notify_flag='Y';
 --  AND supervisor_id IS NULL;

CURSOR c_get_mgr(p_employee_id NUMBER) IS
SELECT mgr.full_name,mgr.person_id,mgr.email_address
  FROM per_all_people_f mgr,
       fnd_user fu,
       per_periods_of_service_v s,
       ak_web_user_sec_attr_values a
 WHERE a.attribute_code = 'ICX_HR_PERSON_ID'
   AND a.attribute_application_id=178
   AND a.number_value=p_employee_id
   AND s.person_id=a.number_value
   AND TRUNC (SYSDATE) <= TRUNC (NVL (s.final_process_date, SYSDATE))  
   AND a.creation_date>SYSDATE-45
   AND fu.user_id=a.web_user_id
   AND mgr.person_id=fu.employee_id
   AND SYSDATE BETWEEN mgr.effective_start_date and mgr.effective_end_date;

CURSOR c_followup(p_days NUMBER)
IS
SELECT a.employee_id,
       a.employee_name,
       a.final_process_date,
       a.supervisor_name,
       a.mgr_email_address,
       a.rowid drowid
  FROM xx_iexp_trmtd_emp a
 WHERE process_flag='I'
   AND initial_notify_flag='Y'
   AND supervisor_id IS NOT NULL
   AND TRUNC(SYSDATE) <= TRUNC(final_process_date-7)
   AND (TRUNC(SYSDATE)-initial_notify_date)>p_days;
--   AND TO_CHAR(SYSDATE,'DAY') LIKE 'MONDAY%';

v_unused_amt		NUMBER:=0;
v_sup_email_addr 	VARCHAR2(100);
v_text			VARCHAR2(8000);
v_subject		VARCHAR2(3000);
v_instance		VARCHAR2(10);
conn 			utl_smtp.connection;
v_email_list		VARCHAR2(2000);
v_ntfy_day		VARCHAR2(20);
v_days			VARCHAR2(3);	
v_day			NUMBER;

BEGIN

  BEGIN
    SELECT  UPPER(TV.target_value1)
           ,TV.target_value2
      INTO  v_ntfy_day,v_days
      FROM  XX_FIN_TRANSLATEVALUES TV
           ,XX_FIN_TRANSLATEDEFINITION TD
     WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
       AND TRANSLATION_NAME = 'XX_IEXP_FOLLOWUP_NOTY';  
  EXCEPTION
    WHEN others THEN
      v_ntfy_day:=TO_CHAR(SYSDATE,'DAY');
      v_days:='0';
  END;

  v_day:=TO_NUMBER(v_days);

  v_email_list:=get_distribution_list;

  FOR c IN C1 LOOP

    FOR cur IN c_get_mgr(c.employee_id) LOOP

      UPDATE xx_iexp_trmtd_emp
	 SET supervisor_id=cur.person_id,
	     supervisor_name=cur.full_name,
	     mgr_email_address=cur.email_address
       WHERE rowid=c.drowid;

    END LOOP;

  END LOOP;
  COMMIT;

  FOR cur IN c_followup(v_day) LOOP

    v_unused_amt:=0;

    IF LTRIM(RTRIM(TO_CHAR(SYSDATE,'DAY')))=LTRIM(RTRIM(v_ntfy_day)) THEN

       SELECT NVL(sum(txn.transaction_amount),0)
         INTO v_unused_amt
         FROM ap_credit_card_trxns_all txn,
              ap_cards_all crd
        WHERE crd.employee_id=cur.employee_id
          AND txn.validate_code = 'Y'
          AND txn.payment_flag <> 'Y'
          AND txn.billed_amount IS NOT NULL
          AND txn.card_id=crd.card_id
          AND txn.card_program_id = crd.card_program_id
          AND txn.card_id = crd.card_id
          AND (NVL (txn.CATEGORY, 'BUSINESS') NOT IN ('DISPUTED', 'CREDIT', 'MATCHED', 'DEACTIVATED'))
          AND TRUNC (NVL (txn.trx_available_date,TO_DATE ('01-01-1952 00:00:00','DD-MM-YYYY HH24:MI:SS'))) <= TRUNC (SYSDATE)
          AND report_header_id IS NULL;

       IF v_unused_amt>0 THEN

         v_subject:='Action Required for Terminated Employee with outstanding Credit Card transaction(s)';
	
         v_text	:='Terminated Employee : '||cur.employee_name ||chr(10);
         v_text   :=v_text ||chr(10);
         v_text   :=v_text ||'Action Required Due Date: '||TO_CHAR(cur.final_process_date-7,'DD-MON-RR')||chr(10);
         v_text   :=v_text ||chr(10);
         v_text   :=v_text ||chr(10);
         v_text   :=v_text ||'You are receiving this email because the terminated employee mentioned above has outstanding Credit Card transaction(s) that require your attention.'||chr(10);
         v_text   :=v_text ||chr(10);
         v_text   :=v_text ||'Please log in to iExpense and follow the instructions below to submit a final Expense Report on behalf of this employee.'||chr(10);
         v_text   :=v_text ||chr(10);
         v_text   :=v_text ||chr(10);
         v_text   :=v_text ||'Instructions:'||chr(10);
         v_text   :=v_text ||chr(10);
         v_text   :=v_text ||'Log in to Oracle and Review your worklist for an item with a subject line related to '||cur.employee_name||', and click on the link'||chr(10);
         v_text   :=v_text ||'Click the "Accept" button to gain access to the terminated employee'||CHR(39)||'s credit card transactions'||chr(10);
         v_text   :=v_text ||'Select "OD IExpenses" Responsibility'||chr(10);
         v_text   :=v_text ||'Click Create Expense Report'||chr(10);
         v_text   :=v_text ||'Select the terminated employee'||CHR(39)||'s name from the drop down list of values in the "Name" field and complete the Expense Report'||chr(10);
         v_text   :=v_text ||'If you do not have any or all required receipts in order to submit the Expense Report, please attach a document that indicates the receipt(s) are not available for this terminated employee.'||chr(10);
         v_text   :=v_text ||chr(10);
         v_text   :=v_text ||chr(10);       
         v_text   :=v_text ||chr(10);
         v_text   :=v_text ||'Expense Reports must be completed and approved prior to the "Action Required Due Date:" mentioned above.'||chr(10);
         v_text   :=v_text ||'Please note: You will receive a weekly notification every Monday until the pending credit card transaction(s) have been processed'||chr(10);
         v_text   :=v_text ||'If you have any questions, please contact iExpense-admin@officedepot.com for assistance'||chr(10);

         IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

         END IF;

         IF cur.mgr_email_address IS NULL THEN
            v_sup_email_addr:=v_email_list; 
         ELSE
            v_sup_email_addr:=cur.mgr_email_address;
         END IF;

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Terminated Employee   :'||cur.employee_name);    
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Manager Email Address :'||v_sup_email_addr);

         conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'ODIexpenses@officedepot.com',
	  	        recipients => v_sup_email_addr,
			cc_recipients=>NULL,
		        subject => v_subject,
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);


         xx_pa_pb_mail.attach_text( conn => conn,
  		                        data => v_text 
				      );

         xx_pa_pb_mail.end_mail( conn => conn );

  	 UPDATE xx_iexp_trmtd_emp
	    SET followup_notify_flag='Y'
          WHERE rowid=cur.drowid;

 	 COMMIT;

      END IF;
   END IF;
  END LOOP;

EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_followup_txn procedure :'||SQLERRM);
    x_errbuf:=SUBSTR(SQLERRM,1,150);
    x_retcode:='2'; 
END xx_followup_txn;

-- +================================================================================+
-- | Name        :  xx_personal_expenses                                            |
-- | Description :  This procedure will be called from the concurrent program       |
-- |                "OD: Personal Expenses Submitted in Iexpenses Report" to insert |
-- |                personal expenses in the custom table xx_iexp_purge_txns for the|
-- |                report parameters                                               |
-- |                                                                                |
-- | Parameters  :  N/A                                                             |
-- |                                                                                |
-- | Returns     :  x_errbuf, x_retcode                                             |
-- |                                                                                |
-- +================================================================================+


PROCEDURE xx_personal_expenses ( x_errbuf      	OUT NOCOPY VARCHAR2
                              	,x_retcode     	OUT NOCOPY VARCHAR2
				,p_employee_id	IN  NUMBER
				,p_empname_id	IN  NUMBER
				,p_from_date	IN  VARCHAR2
				,p_to_date	IN  VARCHAR2
     		               )

IS

v_sdate DATE;
v_edate DATE;

CURSOR c_pertxn_rpt(p_fdate DATE,p_edate DATE) 
IS
SELECT DISTINCT a.report_header_id,a.invoice_num,b.full_name,b.employee_number
  FROM per_all_people_f b,
       ap_expense_report_headers_all a	
 WHERE a.expense_status_code='PAID'  
   AND TRUNC(a.expense_last_status_date) BETWEEN TRUNC(NVL(p_fdate,a.expense_last_status_date))
       AND TRUNC(NVL(p_edate,a.expense_last_status_date))
   AND b.person_id=a.employee_id
   AND b.person_id=NVL(p_employee_id,b.person_id)
   AND b.person_id=NVL(p_empname_id,b.person_id)
   AND SYSDATE BETWEEN b.effective_start_date AND b.effective_end_date;

CURSOR C_cc_txns(P_report_id NUMBER) 
IS
SELECT expensed_amount amount,
       transaction_date,
       merchant_name1,
       merchant_city||','||merchant_province_state||','||merchant_postal_code location
  FROM ap_credit_card_trxns_all
 WHERE report_header_id=p_report_id
   AND category='PERSONAL'
UNION ALL   -- Defect 505 Add UNINON ALL
SELECT NVL(billed_amount,0)-NVL(expensed_amount,0) amount,
       transaction_date,
       merchant_name1,
       merchant_city||','||merchant_province_state||','||merchant_postal_code location
  FROM ap_credit_card_trxns_all
 WHERE report_header_id=p_report_id
   AND billed_amount-expensed_amount<>0;

v_request_id			NUMBER;

BEGIN

  v_sdate:=fnd_conc_date.string_to_date(p_from_date);
  v_edate:=fnd_conc_date.string_to_date(p_to_date);

  v_request_id:=FND_GLOBAL.conc_request_id;

    FOR c IN c_pertxn_rpt(v_sdate,v_edate) LOOP

      FOR cur IN c_cc_txns(c.report_header_id) LOOP

        BEGIN
          INSERT
	  INTO xx_iexp_purge_txns
		   ( 	 request_id
	  		,employee_name
		        ,employee_number
			,report_no
			,personal_txn_amt
			,txn_date
			,merchant_name
			,location
			,creation_date
			,created_by
			,last_update_date
			,last_updated_by
	  	    )
	  VALUES
		   (	 v_request_id
			,c.full_name
			,c.employee_number
			,c.invoice_num
			,cur.amount
			,cur.transaction_date
			,cur.merchant_name1
			,cur.location
			,SYSDATE,fnd_global.user_id,SYSDATE,fnd_global.user_id
		   );
        EXCEPTION
	  WHEN others THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while inserting xx_iexp_purge_txns for the report : '|| c.invoice_num||', '||SQLERRM);
        END;	
      END LOOP;	
      COMMIT;
    END LOOP;
    xx_personal_send_rpt(v_request_id);
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in the procedure xx_personal_expenses: '||SQLERRM);
END xx_personal_expenses;

END XX_IEXP_TRMEMP_PROC_PKG;
/
