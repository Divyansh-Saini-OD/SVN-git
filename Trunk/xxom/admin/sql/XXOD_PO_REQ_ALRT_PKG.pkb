create or replace
PACKAGE BODY XXOD_PO_REQ_ALRT_PKG
AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XXOD_PO_REQ_ALRT_PKG                                            |
-- | Rice ID:                                                                |
-- | Description      : This Program will send email alert for requisition   |
-- |                    having no distribution                               |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |1.0        21-AUG-2017   Neeraj Kr         Initial draft version         |
-- +=========================================================================+
    PROCEDURE main(retcode OUT  NUMBER
                  ,errbuf OUT VARCHAR2
				          ,p_date_from IN VARCHAR2
				          ,p_date_to IN VARCHAR2
				          ,p_email_to IN VARCHAR2
                  ,p_num_days IN NUMBER)
	IS
       --------------------------------------------------------------------
	   --
	   -- procedure Name:  main
	   -- Date Written:   21-AUG-2017
	   -- Author's name:  Neeraj Kumar (IBM)
	   -- Description:    Called from Concurrent program to send email alert 
	   --                 for requisition without distribution line
	   --
	   -- Change History:
	   --
	   -- Date        Name             Change
	   -- ----------- --------         --------------------------------------------
	   -- 21-AUG-2017 Neeraj Kumar     Initial Draft.
	   ----------------------------------------------------------------------------
	   
	--
    -- Cursor declaration section
    --	
	CURSOR c_req_cur (cp_date_from IN DATE,
	                  cp_date_to IN DATE,
					  cp_org_id IN NUMBER)
	IS
	  SELECT  prha.segment1 Requisition_No
            , prla.line_num     Requisition_Line_number
            , ppx.full_name requestor_name
            , prha.authorization_status  Status
            , prla.creation_date  Creation_date
            , NVL(prla.cancel_flag,'N') cancel_flag
            , prla.item_description
            , prla.source_type_code
			, hl.location_code ship_to_location 
            ,(SELECT organization_name 
			  FROM apps.org_organization_definitions
			  WHERE organization_id = prla.destination_organization_id) destination_organization
	FROM       po_requisition_headers_all prha
              ,po_requisition_lines_all prla
              ,per_people_x ppx
			  ,hr_locations_all hl
     WHERE prha.requisition_header_id = prla.requisition_header_id 
	 AND prla.org_id = prha.org_id 
	 AND prla.cancel_flag IS NULL
	 AND prla.deliver_to_location_id  =hl.location_id
     AND  prha.authorization_status <> 'SYSTEM_SAVED'
    AND NOT EXISTS 
	(SELECT 1
	FROM apps.po_req_distributions_all prda
	WHERE prda.requisition_line_id = prla.requisition_line_id
	AND prda.org_id = prla.org_id
	)
	AND prha.org_id = cp_org_id 
	AND ppx.person_id = prha.preparer_id
	AND TRUNC(prla.creation_date) BETWEEN TRUNC(cp_date_from) AND TRUNC(cp_date_to)
	ORDER BY prla.creation_date DESC;
	--
	-- Local Variable declaration section
	--
	x_req_rec c_req_cur%ROWTYPE;
	l_date_from DATE:= NVL(fnd_conc_date.string_to_date (p_date_from),(SYSDATE-p_num_days)); --Updated by Arun,Elangovan
	l_date_to DATE:=   NVL(fnd_conc_date.string_to_date (p_date_to),SYSDATE);
	lv_email_to VARCHAR2(500):=p_email_to;
	lv_email_cc VARCHAR2(500):=NULL;
	lv_email_body_path   VARCHAR2 (2000);
	ln_req_id            NUMBER;
	lv_attachment_file   VARCHAR2 (2000) := NULL;
	lv_subject VARCHAR2(500);
	ln_user_id NUMBER:=fnd_profile.value('USER_ID');
	ln_org_id NUMBER:= fnd_profile.value('ORG_ID');
	lv_instance_name v$instance.instance_name%TYPE;
	ln_ctr    NUMBER:=0;
	lv_return_status VARCHAR2(1);
	lv_req_phase        VARCHAR2(50);
	lv_req_status           VARCHAR2(50);
	lv_req_dev_phase        VARCHAR2(50);
	lv_req_dev_status       VARCHAR2(50);
	lv_req_message          VARCHAR2(50);
	lv_req_return_status BOOLEAN;
	--UTL File
    l_fp                   UTL_FILE.FILE_TYPE;
	l_fp_b                 UTL_FILE.FILE_TYPE;
    lv_mode                 VARCHAR2(1)   := 'W'; --mode of File
    lv_location             VARCHAR2(500) ; --:= 'XXOD_PO_REQ_ALRT_LOC'; /*Location of file On Server */
    lv_file                VARCHAR2(200) := 'REQ_NO_DIST_'||fnd_global.conc_request_id||'_'||TO_CHAR(SYSDATE,'DDMMRRRRHH24MISS')||'.csv';
	lv_body_file            VARCHAR2(200):= 'REQ_NO_DIST_EMAIL_BODY.txt';
	lv_file_msg            VARCHAR2(2000);
	BEGIN
	 print_log('|------------Start of procedure main -------------|');
	 print_log('parameters: Date From:'||l_date_from);
	 print_log('parameters: Date To:'||l_date_to);
	 print_log('parameters: Email To:'||lv_email_to);
	 print_log('parameters: Org Id:'||ln_org_id);
   
   IF p_num_days IS NULL AND p_date_from IS NULL  
   THEN
     print_log(' Pass Either Number days or FROM Date parameter value ..');  
     RAISE fnd_api.g_exc_error;
   END IF;
	 
	 IF lv_email_to IS NULL
	 THEN
	     -- Drive email address from user profile
		 BEGIN
		   SELECT email_address
		   INTO lv_email_to
		   FROM fnd_user
		   WHERE user_id=ln_user_id;
		   
		   print_log('Derived Email To:'||lv_email_to);
		 EXCEPTION
		 WHEN OTHERS THEN
		    lv_email_to:=NULL;
		 END;
	 END IF;
	 
	 BEGIN
	     SELECT DECODE (INSTR (VALUE, ',', 1),
                        0, VALUE,
                        SUBSTR (VALUE, 1, INSTR (VALUE, ',', 1) - 1)
                       )
           INTO lv_location
           FROM v$parameter
          WHERE NAME = 'utl_file_dir';
          --lv_location:='/app/ebs/ctgsipth02/utl_file_out';
	 EXCEPTION
	 WHEN OTHERS THEN
	   lv_location:='/usr/tmp';
	 END;
	  
	  print_log('lv_location :'||lv_location);
	 
	 -- Open UTL File to write the output
	 BEGIN
	    l_fp := UTL_FILE.FOPEN(lv_location,lv_file,lv_mode);
		l_fp_b := UTL_FILE.FOPEN(lv_location,lv_body_file,lv_mode);
		lv_email_body_path := lv_location || '/' || lv_body_file;
		lv_attachment_file:= lv_location || '/' || lv_file;
     EXCEPTION
      WHEN UTL_FILE.invalid_path
      THEN
          print_log('Invalid file Path: '|| SQLERRM);
          RAISE fnd_api.g_exc_error;
	  WHEN UTL_FILE.invalid_mode
	  THEN
		print_log( 'Invalid Mode: '|| SQLERRM);
		RAISE fnd_api.g_exc_error;
	  WHEN UTL_FILE.invalid_filehandle
	  THEN
			print_log( 'Invalid File Handle: '|| SQLERRM);
			RAISE fnd_api.g_exc_error;
	   WHEN UTL_FILE.invalid_operation
	   THEN
			print_log( 'Invalid Mode: '|| SQLERRM);
			RAISE fnd_api.g_exc_error;
		WHEN UTL_FILE.internal_error
		THEN
		  print_log( 'Invalid Error: '|| SQLERRM);
		RAISE fnd_api.g_exc_error;
		WHEN NO_DATA_FOUND
		THEN
			print_log( 'No data found : '|| SQLERRM);
		RAISE fnd_api.g_exc_error;
		WHEN VALUE_ERROR
		THEN
		   print_log( 'value Error: '|| SQLERRM);
		RAISE fnd_api.g_exc_error;
		WHEN OTHERS
		THEN
			 print_log( 'Other Error: '|| SQLERRM);
			RAISE fnd_api.g_exc_error;
		END;
		------------------------------------
		-- Perform message write operation
		-----------------------------------
		--
		-- Write Report Header
		--
		lv_file_msg:='Requisition#,Requisition Line#,Requestor,Requisition Status,Creation Date,Cancel Flag,Item Description, Type, Ship To Location';
		UTL_FILE.PUT_LINE(l_fp,lv_file_msg);
		print_out(lv_file_msg);
		
		--
		-- Write Alert Content
		--
     OPEN c_req_cur(l_date_from,l_date_to,ln_org_id);
     LOOP
         FETCH c_req_cur INTO x_req_rec; 
		 EXIT WHEN c_req_cur%NOTFOUND;
		 lv_file_msg:=x_req_rec.Requisition_No
		              ||','||
					  x_req_rec.Requisition_Line_number
					  ||',"'||
					  x_req_rec.requestor_name
					  ||'","'||
					  x_req_rec.Status
					  ||'","'||
					  TO_CHAR(x_req_rec.Creation_date,'DD-MON-RRRR')
					  ||'","'||
					  x_req_rec.cancel_flag
					  ||'","'||
					  REPLACE(x_req_rec.item_description,',',' ')
					  ||'","'||
					  x_req_rec.source_type_code
					  ||'","'||
					  x_req_rec.ship_to_location
					  ||'"';
					  
		UTL_FILE.PUT_LINE(l_fp,lv_file_msg);
		print_out(lv_file_msg);
		ln_ctr:=ln_ctr+1;
		END LOOP;
	    CLOSE c_req_cur;
		
		IF ln_ctr=0
		THEN
		   lv_file_msg:='NO REQUISITIONS WITH MISSING DISTRIBUTION LINES ARE FOUND';
		   UTL_FILE.PUT_LINE(l_fp,lv_file_msg);
		   print_out(lv_file_msg);
		END IF;
		lv_file_msg:='  ---------------     End of Report     -----------------';
		UTL_FILE.PUT_LINE(l_fp,lv_file_msg);
		print_out(lv_file_msg);
	    -- Close the file pointer at the end of write operation
	    UTL_FILE.FCLOSE(l_fp);
	
	   --
	   -- Write email subject
	   --
	   BEGIN
	    SELECT instance_name
		INTO lv_instance_name
		FROM v$instance;
	   EXCEPTION
	   WHEN OTHERS THEN
	     lv_instance_name:=NULL;
	   END;
	   
	   lv_subject:= 'Requisition without distribution - ('||lv_instance_name||')';
	   --
	   -- Write Email Body Section
	   --
	   fnd_message.set_name ('XXOM', 'XX_OM_REQ_EMAIL_MSG');
	   lv_file_msg:=fnd_message.get;
	   UTL_FILE.PUT_LINE(l_fp_b,lv_file_msg);
	   print_log(lv_file_msg);
	   UTL_FILE.FCLOSE(l_fp_b);
	  --
	  -- Email sending section
	  --
	  IF lv_email_to IS NOT NULL
	  THEN
	      print_log('Sending email to :'||lv_email_to );
		  --Call email sending program
	     print_log('Calling procedure to submit email program ...');
         submit_email_program (p_email_to         => lv_email_to,
                               p_email_cc         => lv_email_cc,
                               p_subject          => lv_subject,
                               p_email_body       => lv_email_body_path,
                               p_attchment_file   => lv_attachment_file,
                               p_file_name        => '',
                               p_request_id       => ln_req_id,
                               p_return_status    => lv_return_status);
        print_log(
               'Email Progra Request Id:'
            || ln_req_id
            || ' returned with status :'
            || lv_return_status);
		-------------------------------------
		-- Wait for Request to complete
		------------------------------------
		
		IF ln_req_id > 0
		THEN
				LOOP
				 lv_req_return_status :=
					fnd_concurrent.wait_for_request (ln_req_id,
													 5,
													 60,
													 lv_req_phase,
													 lv_req_status,
													 lv_req_dev_phase,
													 lv_req_dev_status,
													 lv_req_message);
				 EXIT WHEN UPPER (lv_req_phase) = 'COMPLETED'
						   OR UPPER (lv_req_status) IN
								 ('CANCELLED', 'ERROR', 'TERMINATED');
				END LOOP;	
			    print_log('Email Program completed with status -'||lv_req_phase||'-'||lv_req_status);
		ELSE
		    print_log('Warming!!!Email Program failed to send email.');
		END IF;
     END IF;
	 
	 --
	 -- Clean up files generated
	 --
	 BEGIN
	     utl_file.fremove(lv_location,lv_file);
		 utl_file.fremove(lv_location,lv_body_file);
	 EXCEPTION
	 WHEN OTHERS THEN
	   print_log('Exception while removing temp files from server due to '||SUBSTR(SQLERRM,1,200));
	 END;
	 
	 print_log('|------------End of procedure main----------------|');
	EXCEPTION 
	WHEN OTHERS THEN
	    IF c_req_cur%ISOPEN
		THEN
		  CLOSE c_req_cur;
		END IF;
		UTL_FILE.FCLOSE(l_fp);
		UTL_FILE.FCLOSE(l_fp_b);
		utl_file.fremove(lv_location,lv_file);
		utl_file.fremove(lv_location,lv_body_file);
	    print_log('Exception occured in main due to '||SUBSTR(SQLERRM,1,200));
	END main;
	
	PROCEDURE print_log(p_message IN VARCHAR2)
	IS
	   --------------------------------------------------------------------
	   --
	   -- procedure Name:  print_log
	   -- Date Written:   21-AUG-2017
	   -- Author's name:  Neeraj Kumar (IBM)
	   -- Description:    Used to write information to CP log
	   --
	   -- Change History:
	   --
	   -- Date        Name             Change
	   -- ----------- --------         --------------------------------------------
	   -- 21-AUG-2017 Neeraj Kumar     Initial Draft.
	   ----------------------------------------------------------------------------
	BEGIN
	    fnd_file.put_line(fnd_file.log,'----->'||p_message);
	EXCEPTION
	WHEN OTHERS THEN
	    fnd_file.put_line(fnd_file.log,'Exception occured in print_log due to '||SUBSTR(SQLERRM,1,200));
	END print_log;
  
	PROCEDURE print_out(p_message IN VARCHAR2)
	IS
	   --------------------------------------------------------------------
	   --
	   -- procedure Name:  print_out
	   -- Date Written:   21-AUG-2017
	   -- Author's name:  Neeraj Kumar (IBM)
	   -- Description:    Used to write information to CP Output
	   --
	   -- Change History:
	   --
	   -- Date        Name             Change
	   -- ----------- --------         --------------------------------------------
	   -- 21-AUG-2017 Neeraj Kumar     Initial Draft.
	   ----------------------------------------------------------------------------
	BEGIN
	   fnd_file.put_line(fnd_file.output,p_message);
	EXCEPTION
	WHEN OTHERS THEN
	    fnd_file.put_line(fnd_file.log,'Exception occured in print_out due to '||SUBSTR(SQLERRM,1,200));
	END print_out;
	
	PROCEDURE submit_email_program (p_email_to         IN     VARCHAR2,
                                   p_email_cc         IN     VARCHAR2,
                                   p_subject          IN     VARCHAR2,
                                   p_email_body       IN     VARCHAR2,
                                   p_attchment_file   IN     VARCHAR2,
                                   p_file_name        IN     VARCHAR2,
                                   p_request_id          OUT NUMBER,
                                   p_return_status       OUT VARCHAR2)
   IS
      --------------------------------------------------------------------------
      -- Procedure Name:  submit_email_program
      -- Date Written:   15-Sep-2017
      -- Author's name:  Neeraj Kumar (IBM)
      -- Description:    Calls common email sending program
      --
      -- Change History:
      --
      -- Date        Name             Change
      -- ----------- --------         -------------------------------------------
      -- 15-Sep-2017 Neeraj Kumar  Initial development.
      ---------------------------------------------------------------------------
      --Local Variables
      x_user_id            fnd_user.user_id%TYPE := fnd_profile.VALUE ('USER_ID');
      x_resp_id            NUMBER := fnd_profile.VALUE ('RESP_ID');
      x_resp_appl_id       NUMBER := fnd_profile.VALUE ('RESP_APPL_ID');
      x_req_id             NUMBER;
      x_wait_for_request   BOOLEAN;
      x_phase              VARCHAR2 (100);
      x_status             VARCHAR2 (100);
      x_dev_phase          VARCHAR2 (100);
      x_dev_status         VARCHAR2 (100);
      x_message            VARCHAR2 (100);
      x_return_status      VARCHAR2 (1);
      x_email_to           VARCHAR2 (2000) := p_email_to;
      x_email_cc           VARCHAR2 (2000) := p_email_cc;
      x_subject            VARCHAR2 (2000) := p_subject;
      x_email_body         VARCHAR2 (2000) := p_email_body;
      x_attchment_file     VARCHAR2 (2000) := p_attchment_file;
      x_file_name          VARCHAR2 (500) := p_file_name;
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      print_log('Start of Procedure submit_email_program ');
      print_log( 'Parameters:');
      print_log( 'p_email_to=>' || p_email_to);
      print_log( 'p_email_cc=>' || p_email_cc);
      print_log( 'p_subject=>' || p_subject);
      print_log( 'p_email_body=>' || p_email_body);
      print_log( 'p_attchment_file=>' || p_attchment_file);
      print_log( 'p_file_name=>' || p_file_name);
      -----------------------------------
      --Initialize application context
      -----------------------------------
      print_log(
            'Initializing APPS Environment with userId: '
         || x_user_id
         || ' , RespId: '
         || x_resp_id
         || ' and RespApplId: '
         || x_resp_appl_id);
		 
      fnd_global.apps_initialize (user_id        => x_user_id,
                                  resp_id        => x_resp_id,
                                  resp_appl_id   => x_resp_appl_id);
      -----------------------------------------
      --Submit Import Items Program.
      -----------------------------------------
      x_req_id :=
         fnd_request.submit_request (
            application   => 'XXOM',
            program       => 'XXODGENSENDEMAIL',
            description   => 'OD: Common Email Sending Program',
            argument1     => x_email_to,                            --EMAIL TO
            argument2     => x_email_cc,                            --EMAIL CC
            argument3     => x_subject,                              --SUBJECT
            argument4     => x_email_body,                   --EMAIL BODY PATH
            argument5     => x_attchment_file,
            --ATTACH_FILE_WITH_PATH
            argument6     => x_file_name);
      COMMIT;
      print_log(
            'Program  XXODGENSENDEMAIL Submitted with Request Id:'
         || x_req_id
         || ' at '
         || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));

      ---------------------------------------------
      -- Check if program is submitted successfully
      -- If yes, wait for completion of Import Items
      ----------------------------------------------
      IF x_req_id > 0
      THEN
       print_log(
               'Program  XXODGENSENDEMAIL completed with status '
            || x_dev_phase
            || ' - '
            || x_dev_status
            || 'at '
            || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));
      ELSE
         x_return_status := fnd_api.g_ret_sts_error;
         print_log(
            'Warning!!! Program XXODGENSENDEMAIL not submitted <<<<<');
      END IF;

      p_return_status := x_return_status;
      p_request_id := x_req_id;
      print_log(
            'procedure Submit_Email_Program return status=> '
         || p_return_status
         || ' request out=>'
         || x_req_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_return_status := fnd_api.g_ret_sts_error;
         p_request_id := -1;
        print_log(
               'Exception occured in procedure Submit_Email_Program due to '
            || SUBSTR (SQLERRM, 1, 200));
   END submit_email_program;
   
END XXOD_PO_REQ_ALRT_PKG;
/