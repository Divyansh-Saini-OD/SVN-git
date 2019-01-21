CREATE OR REPLACE PACKAGE BODY XX_IBY_CHECK_PAYMENT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |           Office Depot Organization                               |
-- +===================================================================+
-- | Name  : XX_IBY_CHECK_PAYMENT_PKG                                  |
-- | Description      :  Package contains program units which will be  |
-- |                     used in check payment process                 |
-- | RICE ID : I1207 Check Printing                                    |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========   =============    ===========================|
-- |1.0       17-Sep-2013   Satyajeet M     I1207-Initial draft version|
-- |1.1       08-Oct-2013   Satyajeet M      Added code for calling    |
-- |                                        Custom Program for positive|
-- |                                        Pay                        |
-- |1.2       18-Nov-2013   Satyajeet M     Added wait for Record Print|
-- |                                        Status program completion  |
-- |1.3       23-Dec-2013   Satyajeet M     Modification for overflow  |
-- |1.4       22-Jan-2014   Satyajeet M     Modified the code to only  |
-- |                                        trigger the programs when  |
-- |                                        the payment type is check  |
-- |                                        (Defect 27712)             |
-- |1.5       12-Feb-2014   Veronica M      Added procedure to submit  |
-- |                                        record print for defect 27993|
-- |1.6       17-Feb-2014   Satyajeet M     Added logic to restrict the |
-- |                                        Overflow print if there are |
-- |                                        no overflow pages to be printed|
-- |                                        defect 28224               |
-- |1.7       19-Feb-2014   Paddy Sanjeevi  Defect  28312              |
-- |1.8       26-Feb-2014   Paddy Sanjeevi  Defect 28602               |
-- |1.9       02-Jun-2014   Paddy Sanjeevi  Defect 30031               |
-- |1.10      12-Jun-2014   Paddy Sanjeevi  Defect 29874               |
-- |1.11      26-Jun-2014   Paddy Sanjeevi  Defect 29874               |
-- +===================================================================+
AS




PROCEDURE   get_format_request_id ( p_request_id 	  IN  NUMBER
	 	 		   ,p_pay_instr_id 	  OUT NUMBER
			 	)
IS

 v_pay_request_id	NUMBER;
 v_bld_request_id	NUMBER;
 v_for_request_id	NUMBER;
 v_pay_instr_id		NUMBER;

BEGIN

  p_pay_instr_id :=NULL;

  BEGIN
  SELECT b.request_id
    INTO v_pay_request_id
    FROM  fnd_concurrent_programs_vl a
         ,fnd_concurrent_requests b
   WHERE b.parent_request_id=p_request_id
     AND b.concurrent_program_id=a.concurrent_program_id
     AND a.concurrent_program_name='APXPBASL';
  EXCEPTION
    WHEN others THEN
      v_pay_request_id:=-1;
  END;

  IF v_pay_request_id>0 THEN

    BEGIN
      SELECT b.request_id
        INTO v_bld_request_id
        FROM  fnd_concurrent_programs_vl a
             ,fnd_concurrent_requests b
       WHERE b.parent_request_id=v_pay_request_id
         AND b.concurrent_program_id=a.concurrent_program_id
         AND   a.concurrent_program_name='IBYBUILD';
    EXCEPTION
      WHEN others THEN
        v_bld_request_id:=-1;
    END;

  END IF;

  IF v_bld_request_id>0 THEN

    BEGIN
      SELECT b.request_id,argument1
        INTO v_for_request_id,v_pay_instr_id
        FROM  fnd_concurrent_programs_vl a
             ,fnd_concurrent_requests b
       WHERE b.parent_request_id=v_bld_request_id
         AND b.concurrent_program_id=a.concurrent_program_id
         AND   a.concurrent_program_name='IBY_FD_PAYMENT_FORMAT';

	p_pay_instr_id:=v_pay_instr_id;

    EXCEPTION
      WHEN others THEN
        v_for_request_id:=-1;
    END;

  END IF;

  fnd_file.PUT_LINE(fnd_file.LOG, 'Format Request  id :' ||to_char(v_for_request_id));
  fnd_file.PUT_LINE(fnd_file.LOG, 'Pay Instruction id :' ||to_char(v_pay_instr_id));

EXCEPTION
  WHEN others THEN
   p_pay_instr_id:=NULL;
END;



Procedure submit_overflow(p_instruction_id in NUMBER)
--+=====================================================================================================+
--|Function    :  submit_overflow                                                                       |
--|Description :  This procedure will submit the custom program for overflow print                      |
--|Parameters  :                                                                                        |
--|    p_instruction_id  input parameter .                                                              |
--+=====================================================================================================+
AS
  ln_request_id NUMBER;
   lc_phase               VARCHAR2 (50);
   lc_status              VARCHAR2 (50);
   lc_dev_phase           VARCHAR2 (50);
   lc_dev_status          VARCHAR2 (50);
   lc_message             VARCHAR2 (1000);
   lb_result              BOOLEAN;
   lc_result               BOOLEAN;
   lc_ovflw_printer       XX_FIN_TRANSLATEVALUES.source_value9%TYPE;
   lb_add_layout          BOOLEAN;
   lc_style_sheet         VARCHAR2(100);
   ln_rec_count           NUMBER; -- Added for 28224
   ln_lfp                 NUMBER; -- Added for 28224
BEGIN
   ln_rec_count := 0;
   lc_style_sheet := 'PDF Publisher Evergreen';

   BEGIN
     SELECT count(1)
	   INTO ln_rec_count
       FROM iby_docs_payable_all idp,
            iby_payments_all ipa
      WHERE IPA.PAYMENT_INSTRUCTION_ID = p_instruction_id
        AND ipa.payment_id = idp.payment_id
        AND IPA.PAYMENT_METHOD_CODE = 'CHECK'
        AND IDP.DOCUMENT_STATUS  LIKE 'PAYMENT_CREATED';
   EXCEPTION
     WHEN others THEN
	  ln_rec_count := 0;
   END;

   -- -----------------------------------
   -- get the Overflow printer name
   -- -----------------------------------
   BEGIN
      SELECT val.source_value9-- Overflow printer
	       , val.source_value4 -- Added 28224 Number of lines for first page.
        INTO lc_ovflw_printer
	       , ln_lfp
        FROM iby_pay_instructions_all ipia
           , ce_bank_accounts cba
           , xx_fin_translatedefinition def
           , xx_fin_translatevalues val
       WHERE ipia.payment_instruction_id = p_instruction_id
         AND cba.bank_account_id = ipia.internal_bank_account_id
         AND def.translate_id = val.translate_id
         AND def.translation_name = 'AP_CHECK_PRINT_BANK_DTLS'
         AND val.source_value1 = CBA.bank_account_name
         AND def.enabled_flag = 'Y'
         AND val.enabled_flag = 'Y';
   EXCEPTION
     WHEN OTHERS THEN
       lc_ovflw_printer := 'noprint';
	   lc_style_sheet := NULL;
   END;

   IF ln_rec_count >  ln_lfp  THEN
	   -- --------------------------------------------------------------------------------------------
	   -- Set the printer
	   -- --------------------------------------------------------------------------------------------
	   IF lc_ovflw_printer IS NOT NULL THEN
		 lc_result := FND_REQUEST.SET_PRINT_OPTIONS(lc_ovflw_printer  --printer name
														--,'PDF Publisher Evergreen'   --style
														,lc_style_sheet --style
														,1
														,TRUE
														,'N'
														);
		  lb_add_layout:=
				   fnd_request.add_layout (
								template_appl_name   => 'XXFIN',
								template_code        => 'XXAPODOVERFLOW',
								template_language    => 'en', --Use language from template definition
								template_territory   => 'US', --Use territory from template definition
								output_format        => 'PDF' --Use output format from template definition
										);
	   END IF;

	   -- --------------------------------------------------------------------------------------------
	   -- Submit request to Overflow
	   -- --------------------------------------------------------------------------------------------
	   ln_request_id :=
		  fnd_request.submit_request (application  => 'XXFIN'
					     ,program     => 'XXAPODOVERFLOW'
					     ,start_time  => TO_CHAR(SYSDATE, 'DD-MON-YY HH24:MI:SS')
			   		     ,SUB_REQUEST => TRUE     -- Defect 29874
					     ,argument1   => p_instruction_id
					     );
	   COMMIT;

	   FND_FILE.PUT_LINE(FND_FILE.LOG , 'Overflow Request Submitted. Request Id : ' || ln_request_id);
           fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data =>'1');  -- Defect 29874
	   --
	   --
	   /*
	   IF ln_request_id <> 0 THEN
		 WHILE (NVL(lc_dev_phase,'XXX') <> 'COMPLETE') -- Added loop to call wait for request till the request is not completed
		 LOOP
		   lb_result :=
			fnd_concurrent.wait_for_request (ln_request_id,
										   10,
										   200,
										   lc_phase,
										   lc_status,
										   lc_dev_phase,
										   lc_dev_status,
										   lc_message
										  );

		 END LOOP;
	   END IF;
	   */
   END IF ; -- Added for 28224  End of if condition.
EXCEPTION
  WHEN OTHERS THEN
    ln_request_id:=0;
END submit_overflow;
--+=====================================================================================================+
--|Function    :  record_printer_status                                                                 |
--|Description :  Function which will be used in the business event subscription . This function will   |
--|               submit standard program record print status after the successfull completion of Format|
--|               Payment instructions program                                                          |
--|Parameters  :                                                                                        |
--|    p_sub_guid  input parameter .                                                                    |
--|    p_event     input parameter to get the event details.                                            |
--+=====================================================================================================+
 FUNCTION record_printer_status (p_sub_guid IN RAW, p_event IN OUT wf_event_t)
   RETURN VARCHAR2
IS
   l_event_data           CLOB;
   ln_request_id          NUMBER;
   ln_request_id2         NUMBER;
   ln_request_id3         NUMBER;
   lc_event_name          VARCHAR2 (100);
   --lc_status              VARCHAR2 (100)  := 'SUCCESS';
   lc_err_msg             VARCHAR2 (1000);
   lc_out_file_name       VARCHAR2 (1000);
   lc_short_nm            VARCHAR2 (1000);
   ln_user_id             NUMBER;
   ln_resp_id             NUMBER;
   ln_resp_appl_id        NUMBER;
   lc_output_file_dest    VARCHAR2 (1000);
   lc_phase               VARCHAR2 (50);
   lc_status              VARCHAR2 (50);
   lc_dev_phase           VARCHAR2 (50);
   lc_dev_status          VARCHAR2 (50);
   lc_message             VARCHAR2 (1000);
   lb_result              BOOLEAN;
   lc_instruction_id      FND_CONCURRENT_REQUESTS.ARGUMENT1%TYPE;
   ln_doc_id              IBY_PAY_INSTRUCTIONS_ALL.PAYMENT_DOCUMENT_ID%TYPE;
   ln_post_pay_req_id     FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE;
   lc_ovr_flow            VARCHAR2(10);

   -- ------------------------------------------------
   -- Cursor to get output file name
   -- ------------------------------------------------
   CURSOR c_req_info (cp_request_id NUMBER)
   IS
      SELECT fcr.requested_by, fcr.responsibility_id,
             fcr.responsibility_application_id, fcr.argument1
        FROM fnd_concurrent_requests fcr,
             fnd_concurrent_programs fcp
       WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
         AND fcr.program_application_id = fcp.application_id
         AND fcp.concurrent_program_name = 'IBY_FD_PAYMENT_FORMAT'
         AND fcr.request_id = cp_request_id
         AND EXISTS (
                SELECT 1
                  FROM iby_payments_all ipa
                 WHERE ipa.payment_instruction_id = fcr.argument1
                   AND UPPER (ipa.payment_method_code) = 'CHECK'
                   AND ipa.payment_status = 'SUBMITTED_FOR_PRINTING');


    CURSOR c_pay_instr_info(p_instruction_id NUMBER)
	IS
	  SELECT ipia.payment_document_id
	    FROM iby_pay_instructions_all ipia
	   WHERE ipia.payment_instruction_id = p_instruction_id;
BEGIN

   l_event_data      := p_event.geteventdata ();
   lc_event_name     := p_event.geteventname ();
   lc_instruction_id := NULL;
   lc_status         := NULL;

-- Commented as the record print status will be submitted through concurrent program and not business event subscription
/*
   IF (p_event.geteventname () =
                                'oracle.apps.fnd.concurrent.request.completed'
      )
   THEN
      ln_request_id :=
                      TO_NUMBER (p_event.getvalueforparameter ('REQUEST_ID'));
   END IF;

   -- ------------------------------------------------------------
   -- Get the details of the Format Payment Instruction program
   -- ------------------------------------------------------------
   OPEN c_req_info (ln_request_id);
   FETCH c_req_info
    INTO ln_user_id, ln_resp_id,ln_resp_appl_id,lc_instruction_id;
   CLOSE c_req_info;

   -- Start: The process should only be triggered incase of check -- Defect 27712
   IF lc_instruction_id IS NOT NULL
   THEN
	   -- ------------------------------------------------------------
	   -- Get the details for the document
	   -- ------------------------------------------------------------
	   OPEN c_pay_instr_info (lc_instruction_id);
	   FETCH c_pay_instr_info
		INTO ln_doc_id;
	   CLOSE c_pay_instr_info;

	   -- ------------------------------------------------------------
	   -- Initialize the environment
	   -- ------------------------------------------------------------
	   fnd_global.apps_initialize (ln_user_id, ln_resp_id, ln_resp_appl_id);

	   submit_overflow(lc_instruction_id);

	   -- --------------------------------------------------------------------------------------------
	   -- If it was submitted for Check, then get the default values for Check FTP program
	   -- --------------------------------------------------------------------------------------------
	   ln_request_id2 :=
		  fnd_request.submit_request (application => 'IBY'
									  ,program     => 'IBY_FD_RECORD_PRINT_STATUS'
									  ,argument1   => lc_instruction_id                                                     -- Payment Instruction id
									  ,argument2   => ln_doc_id           -- Payment Document id
									  ,argument3   => NULL
									  ,argument4   => NULL
									  ,argument5   => 'FALSE'
									  );
	   COMMIT;


	   WHILE (NVL(lc_dev_phase,'XXX') <> 'COMPLETE') -- Added loop to call wait for request till the request is not completed
	   LOOP
		 lb_result :=
			fnd_concurrent.wait_for_request (ln_request_id2,
										   10,
										   200,
										   lc_phase,
										   lc_status,
										   lc_dev_phase,
										   lc_dev_status,
										   lc_message
										  );

	   END LOOP;

	   IF lc_status = 'Normal'
	   THEN
		 -- -------------------------------------------------------
		 -- Added code to submit the custom Positive Pay program
		 -- -------------------------------------------------------
		 ln_post_pay_req_id := fnd_request.submit_request
								   (application      => 'XXFIN',
									program          => 'XXPOSPAY',
									argument1        => lc_instruction_id
								   );

		 COMMIT;

		 IF ln_post_pay_req_id != 0 THEN
				   lb_result :=
					  fnd_concurrent.wait_for_request (ln_post_pay_req_id,
													   10,
													   200,
													   lc_phase,
													   lc_status,
													   lc_dev_phase,
													   lc_dev_status,
													   lc_message
													  );
		 END IF;

	   END IF;

   END IF; -- END If the payment type is Check -- Defect 27712
*/
   RETURN (lc_status);
EXCEPTION
   WHEN OTHERS
   THEN
      lc_err_msg := SUBSTR (SQLERRM, 1, 2000);
      lc_status := 'ERROR||lc_err_msg';
      RETURN (lc_status||lc_err_msg);
END record_printer_status;

-- V1.5 Added procedure submit_print_status for defect 27993 START
--+=====================================================================================================+
--|Procedure   :  submit_print_status                                                                   |
--|Description :  Procedure that will be called from the wrapper concurrent program. This will          |
--|               submit standard program record print status after the successfull completion of Format|
--|               Payment instructions program                                                          |
--|Parameters  :                                                                                        |
--|    p_request_id  input parameter. The request id of the payment format program                      |
--|                                                                                                     |
--+=====================================================================================================+

PROCEDURE submit_print_status ( x_error_buff         OUT VARCHAR2
                               ,x_ret_code           OUT NUMBER
                               ,p_request_id         IN NUMBER)
IS
   --l_event_data           CLOB;
   ln_request_id          NUMBER;
   ln_request_id2         NUMBER;
   ln_request_id3         NUMBER;
   lc_event_name          VARCHAR2 (100);
   --lc_status              VARCHAR2 (100)  := 'SUCCESS';
   lc_err_msg             VARCHAR2 (1000);
   lc_out_file_name       VARCHAR2 (1000);
   lc_short_nm            VARCHAR2 (1000);
   ln_user_id             NUMBER;
   ln_resp_id             NUMBER;
   ln_resp_appl_id        NUMBER;
   lc_output_file_dest    VARCHAR2 (1000);
   lc_phase               VARCHAR2 (50);
   lc_status              VARCHAR2 (50);
   lc_dev_phase           VARCHAR2 (50);
   lc_dev_status          VARCHAR2 (50);
   lc_message             VARCHAR2 (1000);
   lb_result              BOOLEAN;
   lc_instruction_id      FND_CONCURRENT_REQUESTS.ARGUMENT1%TYPE;
   ln_doc_id              IBY_PAY_INSTRUCTIONS_ALL.PAYMENT_DOCUMENT_ID%TYPE;
   ln_post_pay_req_id     FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE;
   lc_ovr_flow            VARCHAR2(10);

   req_data VARCHAR2(240) := NULL;
   i 			  NUMBER;
   ln_rec_count           NUMBER; -- Added for 28224
   ln_lfp                 NUMBER; -- Added for 28224
   v_current_req_id	  NUMBER;
   v_creq_cnt		  NUMBER;


   -- ------------------------------------------------
   -- Cursor to get output file name
   -- ------------------------------------------------
   CURSOR c_req_info (cp_request_id NUMBER)
   IS
      SELECT fcr.requested_by, fcr.responsibility_id,
             fcr.responsibility_application_id
        FROM fnd_concurrent_requests fcr,
             fnd_concurrent_programs fcp
       WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
         AND fcr.program_application_id = fcp.application_id
         AND fcr.request_id = cp_request_id;


    CURSOR c_pay_instr_info(p_instruction_id NUMBER)
	IS
	  SELECT ipia.payment_document_id
	    FROM iby_pay_instructions_all ipia
	   WHERE ipia.payment_instruction_id = p_instruction_id;

BEGIN

   v_current_req_id:=fnd_global.conc_request_id;

   FND_FILE.PUT_LINE(FND_FILE.LOG , 'Begin of the Check Record Print Status Submission Program');
   lc_instruction_id := NULL;
   lc_status         := NULL;


      ln_request_id := p_request_id;

      get_format_request_id ( p_request_id,lc_instruction_id);

   -- ------------------------------------------------------------
   -- Get the details of the Format Payment Instruction program
   -- ------------------------------------------------------------
   OPEN c_req_info (ln_request_id);
   FETCH c_req_info
    INTO ln_user_id, ln_resp_id,ln_resp_appl_id;
   CLOSE c_req_info;

   FND_FILE.PUT_LINE(FND_FILE.LOG , 'Payment Instruction Id : ' || lc_instruction_id);

   -- Start: The process should only be triggered incase of check -- Defect 27712
   IF lc_instruction_id IS NOT NULL
   THEN

	-- ------------------------------------------------------------
	-- Get the details for the document
	-- ------------------------------------------------------------
	OPEN c_pay_instr_info (lc_instruction_id);
	FETCH c_pay_instr_info
	 INTO ln_doc_id;
        CLOSE c_pay_instr_info;

       BEGIN
          SELECT count(1)
	    INTO ln_rec_count
            FROM iby_docs_payable_all idp,
                 iby_payments_all ipa
           WHERE IPA.PAYMENT_INSTRUCTION_ID = lc_instruction_id
             AND ipa.payment_id = idp.payment_id
             AND IPA.PAYMENT_METHOD_CODE = 'CHECK'
             AND IDP.DOCUMENT_STATUS  LIKE 'PAYMENT_CREATED';
       EXCEPTION
         WHEN others THEN
	  ln_rec_count := 0;
       END;

      -- -----------------------------------
      -- get the Overflow printer name
      -- -----------------------------------
      BEGIN
        SELECT val.source_value4 -- Added 28224 Number of lines for first page.
          INTO ln_lfp
          FROM iby_pay_instructions_all ipia
             , ce_bank_accounts cba
             , xx_fin_translatedefinition def
             , xx_fin_translatevalues val
         WHERE ipia.payment_instruction_id = lc_instruction_id
           AND cba.bank_account_id = ipia.internal_bank_account_id
           AND def.translate_id = val.translate_id
           AND def.translation_name = 'AP_CHECK_PRINT_BANK_DTLS'
           AND val.source_value1 = CBA.bank_account_name
           AND def.enabled_flag = 'Y'
           AND val.enabled_flag = 'Y';
     EXCEPTION
       WHEN OTHERS THEN
         ln_lfp:=NULL;
     END;

     /* Defect 29874, added logic to submit as child request */

     req_data := fnd_conc_global.request_data;

     IF (req_data IS NULL) THEN

        FND_FILE.PUT_LINE(FND_FILE.LOG , 'Payment Document Id : ' || ln_doc_id);

        IF ln_rec_count >  ln_lfp  THEN
	   -- ------------------------------------------------------------
	   -- Initialize the environment
	   -- ------------------------------------------------------------
	   --fnd_global.apps_initialize (ln_user_id, ln_resp_id, ln_resp_appl_id);  -- Defect 29874

           FND_FILE.PUT_LINE(FND_FILE.LOG , 'Submitting Overflow for Instruction Id : ' || lc_instruction_id);
	   submit_overflow(lc_instruction_id);

	ELSE

	   -- --------------------------------------------------------------------------------------------
	   -- If it was submitted for Check, then get the default values for Check FTP program
	   -- --------------------------------------------------------------------------------------------
	   ln_request_id2 :=
		  fnd_request.submit_request (application => 'IBY'
					     ,program     => 'IBY_FD_RECORD_PRINT_STATUS'
    		 	       	             ,start_time  => SYSDATE
				    	     ,sub_request => TRUE
					     ,argument1   => lc_instruction_id                                                     -- Payment Instruction id
					     ,argument2   => ln_doc_id           -- Payment Document id
					     ,argument3   => NULL
					     ,argument4   => NULL
					     ,argument5   => 'FALSE'
					     );
	   COMMIT;

           fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data =>'1');
           FND_FILE.PUT_LINE(FND_FILE.LOG , 'Record Print Status Submitted. Request Id : ' || ln_request_id2);

	END IF; --ELSE

     ELSE    -- IF (req_data IS NULL) THEN

       i := to_number(req_data);

       Select count(1)
  	 INTO v_creq_cnt
         from fnd_concurrent_requests
        where concurrent_program_id IN (select concurrent_program_id
                                  from fnd_concurrent_programs
                                 where concurrent_program_name='IBY_FD_RECORD_PRINT_STATUS'
                               )
          and parent_request_id=v_current_req_id;

       IF v_creq_cnt<>0 THEN
          x_error_buff :=NULL;
          x_ret_code:=0;
          RETURN;
       END IF;

       i := i + 1;

  	 -- --------------------------------------------------------------------------------------------
	 -- If it was submitted for Check, then get the default values for Check FTP program
  	 -- --------------------------------------------------------------------------------------------
	 ln_request_id2 :=
		  fnd_request.submit_request ( application => 'IBY'
					      ,program     => 'IBY_FD_RECORD_PRINT_STATUS'
				    	      ,start_time  => SYSDATE
				    	      ,sub_request => TRUE
					      ,argument1   => lc_instruction_id   -- Payment Instruction id
					      ,argument2   => ln_doc_id           -- Payment Document id
					      ,argument3   => NULL
					      ,argument4   => NULL
					      ,argument5   => 'FALSE'
				   	     );
  	 COMMIT;
         fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data =>TO_CHAR(i));

         FND_FILE.PUT_LINE(FND_FILE.LOG , 'Record Print Status Submitted. Request Id : ' || ln_request_id2);

     END IF; --IF (req_data IS NULL) THEN

	   -- Removed calling of Positive Pay, Defect 30031

	  /*

	   IF lc_status = 'Normal'
	   THEN
		 -- -------------------------------------------------------
		 -- Added code to submit the custom Positive Pay program
		 -- -------------------------------------------------------
		 ln_post_pay_req_id := fnd_request.submit_request
								   (application      => 'XXFIN',
									program          => 'XXPOSPAY',
									argument1        => lc_instruction_id
								   );

		 COMMIT;

                 FND_FILE.PUT_LINE(FND_FILE.LOG , 'Custom Positive Pay Submitted. Request Id : ' || ln_post_pay_req_id);

		 IF ln_post_pay_req_id != 0 THEN
				   lb_result :=
					  fnd_concurrent.wait_for_request (ln_post_pay_req_id,
													   10,
													   200,
													   lc_phase,
													   lc_status,
													   lc_dev_phase,
													   lc_dev_status,
													   lc_message
													  );
		 END IF;

	   END IF;

	   */

   END IF; -- END If the payment type is Check -- Defect 27712

   FND_FILE.PUT_LINE(FND_FILE.LOG , 'End of the Check Record Print Status Submission Program');

EXCEPTION
   WHEN OTHERS
   THEN
      lc_err_msg := SUBSTR (SQLERRM, 1, 2000);
      lc_status := 'ERROR||lc_err_msg';
   FND_FILE.PUT_LINE(FND_FILE.LOG , lc_status);
END submit_print_status;
-- Added procedure submit_print_status for defect 27993 END


PROCEDURE submit_manual_print_status ( x_error_buff         OUT VARCHAR2
                                      ,x_ret_code           OUT NUMBER
				      ,p_payment_type	     IN VARCHAR2
                                      ,p_pay_instruc_id      IN NUMBER)

IS


   --l_event_data           CLOB;
   ln_request_id          NUMBER;
   ln_request_id2         NUMBER;
   ln_request_id3         NUMBER;
   lc_event_name          VARCHAR2 (100);
   --lc_status              VARCHAR2 (100)  := 'SUCCESS';
   lc_err_msg             VARCHAR2 (1000);
   lc_out_file_name       VARCHAR2 (1000);
   lc_short_nm            VARCHAR2 (1000);
   ln_user_id             NUMBER;
   ln_resp_id             NUMBER;
   ln_resp_appl_id        NUMBER;
   lc_output_file_dest    VARCHAR2 (1000);
   lc_phase               VARCHAR2 (50);
   lc_status              VARCHAR2 (50);
   lc_dev_phase           VARCHAR2 (50);
   lc_dev_status          VARCHAR2 (50);
   lc_message             VARCHAR2 (1000);
   lb_result              BOOLEAN;
   lc_instruction_id      FND_CONCURRENT_REQUESTS.ARGUMENT1%TYPE;
   ln_doc_id              IBY_PAY_INSTRUCTIONS_ALL.PAYMENT_DOCUMENT_ID%TYPE;
   ln_post_pay_req_id     FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE;
   lc_ovr_flow            VARCHAR2(10);
   req_data VARCHAR2(240) := NULL;
   i 			  NUMBER;
   ln_rec_count           NUMBER; -- Added for 28224
   ln_lfp                 NUMBER; -- Added for 28224
   v_current_req_id	  NUMBER;
   v_creq_cnt		  NUMBER;


   -- ------------------------------------------------
   -- Cursor to get document_id
   -- ------------------------------------------------

    CURSOR c_pay_instr_info(p_pay_instruc_id NUMBER)
	IS
    SELECT  distinct ipia.payment_document_id
      FROM  iby_pay_instructions_all ipia
     WHERE  ipia.payment_instruction_id=p_pay_instruc_id;

BEGIN

   v_current_req_id:=fnd_global.conc_request_id;

   FND_FILE.PUT_LINE(FND_FILE.LOG , 'Begin of the Check Record Print Status Submission Program');
   lc_instruction_id := p_pay_instruc_id;
   lc_status         := NULL;


    -- ------------------------------------------------------------
    -- Get the details for the document
    -- ------------------------------------------------------------
    OPEN c_pay_instr_info (p_pay_instruc_id);
    FETCH c_pay_instr_info
     INTO ln_doc_id;
    CLOSE c_pay_instr_info;


   BEGIN
     SELECT count(1)
	   INTO ln_rec_count
       FROM iby_docs_payable_all idp,
            iby_payments_all ipa
      WHERE IPA.PAYMENT_INSTRUCTION_ID = lc_instruction_id
        AND ipa.payment_id = idp.payment_id
        AND IPA.PAYMENT_METHOD_CODE = 'CHECK'
        AND IDP.DOCUMENT_STATUS  LIKE 'PAYMENT_CREATED';
   EXCEPTION
     WHEN others THEN
	  ln_rec_count := 0;
   END;

   -- -----------------------------------
   -- get the Overflow printer name
   -- -----------------------------------
   BEGIN
      SELECT val.source_value4 -- Added 28224 Number of lines for first page.
        INTO ln_lfp
        FROM iby_pay_instructions_all ipia
           , ce_bank_accounts cba
           , xx_fin_translatedefinition def
           , xx_fin_translatevalues val
       WHERE ipia.payment_instruction_id = lc_instruction_id
         AND cba.bank_account_id = ipia.internal_bank_account_id
         AND def.translate_id = val.translate_id
         AND def.translation_name = 'AP_CHECK_PRINT_BANK_DTLS'
         AND val.source_value1 = CBA.bank_account_name
         AND def.enabled_flag = 'Y'
         AND val.enabled_flag = 'Y';
   EXCEPTION
     WHEN OTHERS THEN
       ln_lfp:=NULL;
   END;

     /* Defect 29874, added logic to submit as child request */

   req_data := fnd_conc_global.request_data;

   IF (req_data IS NULL) THEN

      FND_FILE.PUT_LINE(FND_FILE.LOG , 'Payment Document Id    : ' || TO_CHAR(ln_doc_id));
      FND_FILE.PUT_LINE(FND_FILE.LOG , 'Payment Instruction Id : ' || TO_CHAR(lc_instruction_id));


      IF ln_rec_count >  ln_lfp  THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG , 'Submitting Overflow for Instruction Id : ' || lc_instruction_id);
         submit_overflow(lc_instruction_id);

      ELSE

	 IF p_payment_type = 'Manual' THEN

             FND_FILE.PUT_LINE(FND_FILE.LOG , 'req data is null, inside paymenttype=manual');
	     -- --------------------------------------------------------------------------------------------
   	     -- If it was submitted for Check, then get the default values for Check FTP program
             -- --------------------------------------------------------------------------------------------
   	    ln_request_id2 :=
		  fnd_request.submit_request ( application => 'IBY'
					      ,program     => 'IBY_FD_RECORD_PRINT_STATUS'
				    	      ,start_time  => SYSDATE
				    	      ,sub_request => TRUE
					      ,argument1   => lc_instruction_id   -- Payment Instruction id
					      ,argument2   => ln_doc_id           -- Payment Document id
					      ,argument3   => NULL
					      ,argument4   => NULL
					      ,argument5   => 'FALSE'
				   	     );
  	    COMMIT;
            fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data =>'1');
            FND_FILE.PUT_LINE(FND_FILE.LOG , 'Record Print Status Submitted. Request Id : ' 	|| ln_request_id2);

	  END IF ; --IF p_payment_type = 'Manual' THEN

	END IF;  -- End if ln_rec_count

    ELSE

      i := to_number(req_data);

      Select count(1)
	INTO v_creq_cnt
        from fnd_concurrent_requests
        where concurrent_program_id IN (select concurrent_program_id
                                  from fnd_concurrent_programs
                                 where concurrent_program_name='IBY_FD_RECORD_PRINT_STATUS'
                               )
          and parent_request_id=v_current_req_id;

      IF v_creq_cnt<>0 THEN
         x_error_buff :=NULL;
         x_ret_code:=0;
         RETURN;
      END IF;

      i := i + 1;

      IF p_payment_type = 'Manual' THEN

 	 -- --------------------------------------------------------------------------------------------
	 -- If it was submitted for Check, then get the default values for Check FTP program
  	 -- --------------------------------------------------------------------------------------------
	 ln_request_id2 :=
		  fnd_request.submit_request ( application => 'IBY'
					      ,program     => 'IBY_FD_RECORD_PRINT_STATUS'
				    	      ,start_time  => SYSDATE
				    	      ,sub_request => TRUE
					      ,argument1   => lc_instruction_id   -- Payment Instruction id
					      ,argument2   => ln_doc_id           -- Payment Document id
					      ,argument3   => NULL
					      ,argument4   => NULL
					      ,argument5   => 'FALSE'
				   	     );
  	 COMMIT;
         fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data =>TO_CHAR(i));

         FND_FILE.PUT_LINE(FND_FILE.LOG , 'Record Print Status Submitted. Request Id : ' || ln_request_id2);


	    /*  Removed the following calling of Positive Pay, Defect 30031

 	    IF lc_status = 'Normal'
	    THEN
		 -- -------------------------------------------------------
		 -- Added code to submit the custom Positive Pay program
		 -- -------------------------------------------------------
		 ln_post_pay_req_id := fnd_request.submit_request
								   (application      => 'XXFIN',
									program          => 'XXPOSPAY',
									argument1        => lc_instruction_id
								   );

		 COMMIT;

                 FND_FILE.PUT_LINE(FND_FILE.LOG , 'Custom Positive Pay Submitted. Request Id : ' || ln_post_pay_req_id);

		 IF ln_post_pay_req_id != 0 THEN
				   lb_result :=
					  fnd_concurrent.wait_for_request (ln_post_pay_req_id,
													   10,
													   200,
													   lc_phase,
													   lc_status,
													   lc_dev_phase,
													   lc_dev_status,
													   lc_message
													  );
		 END IF;

	    END IF;

            */

	   ELSE -- IF p_payment_type = 'Manual' THEN

	      NULL;

	      /* Removed the calling of Positive Pay, Defect 30031

		 -- -------------------------------------------------------
		 -- Added code to submit the custom Positive Pay program
		 -- -------------------------------------------------------
		 ln_post_pay_req_id := fnd_request.submit_request
								   (application      => 'XXFIN',
									program          => 'XXPOSPAY',
									argument1        => lc_instruction_id
								   );

		 COMMIT;

                 FND_FILE.PUT_LINE(FND_FILE.LOG , 'Custom Positive Pay Submitted. Request Id : ' || ln_post_pay_req_id);

		 IF ln_post_pay_req_id != 0 THEN
				   lb_result :=
					  fnd_concurrent.wait_for_request (ln_post_pay_req_id,
													   10,
													   200,
													   lc_phase,
													   lc_status,
													   lc_dev_phase,
													   lc_dev_status,
													   lc_message
													  );
		 END IF;

	     */

	   END IF;

           FND_FILE.PUT_LINE(FND_FILE.LOG , 'End of the Check Record Print Status Submission Program');
    END IF; --IF (req_data IS NULL) THEN
EXCEPTION
   WHEN OTHERS
   THEN
      lc_err_msg := SUBSTR (SQLERRM, 1, 2000);
      lc_status := 'ERROR||lc_err_msg';
   FND_FILE.PUT_LINE(FND_FILE.LOG , lc_status);
END submit_manual_print_status;


END XX_IBY_CHECK_PAYMENT_PKG;
/

