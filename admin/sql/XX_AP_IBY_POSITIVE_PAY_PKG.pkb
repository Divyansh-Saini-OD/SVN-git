CREATE OR REPLACE PACKAGE BODY APPS.XX_AP_IBY_POSITIVE_PAY_PKG
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                            Providge                                      |
-- +==========================================================================+
-- | Name             :    XX_AP_IBY_POSITIVE_PAY_PKG                         |
-- | Description      :    Package for AP Positive Pay                        |
-- | RICE ID          :    I0228                                              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      03-Oct-2013  Paddy Sanjeevi      Initial                        |
-- | 1.1      03-Dec-2013  Veronica Mairembam  Changes for defect# 26497:     |
-- |                                           Changed to use the format name |
-- |                                           OD WF POSITIVE PAY.            |
-- | 1.2      10-Dec-2013  Paddy Sanjeevi      Defect 27074 Changed v_file_prefix|
-- | 1.3      03-Feb-2014  Paddy Sanjeevi      Defect 27901 WF Filename Chnge |
-- | 1.4      02-Jun-2014  Paddy Sanjeevi      Defect 30031                   |
-- | 1.5      16-Sep-2014  Kirubha Samuel      Defect 31197                   |
-- +==========================================================================+


PROCEDURE submit_pos_pay_process  ( p_errbuf   		IN OUT  VARCHAR2
                                   ,p_retcode  		IN OUT  NUMBER
				   ,p_bank_name		IN 	VARCHAR2
				   ,p_format		IN      VARCHAR2
				   ,p_payment_status    IN 	VARCHAR2
				   ,p_payment_to_date IN   VARCHAR2 --added for 31197
                              )
IS


 ln_org_id		NUMBER;
 v_request_id 		NUMBER;
 v_crequest_id 		NUMBER;
 v_user_id		NUMBER:=fnd_global.user_id;
 v_phase		varchar2(100)   ;
 v_status		varchar2(100)   ;
 v_dphase		varchar2(100)	;
 v_dstatus		varchar2(100)	;
 x_dummy		varchar2(2000) 	;
 v_fmt_request_id	NUMBER;
 v_template_id		NUMBER;
 v_timestamp		VARCHAR2(25);
 v_file_name		VARCHAR2(200);
 v_sfile_name		VARCHAR2(200);
 v_dfile_name		VARCHAR2(200);
 v_child_requests	NUMBER;
 lc_err_msg 		VARCHAR2(250);
 lc_error_loc 		VARCHAR2(2000) := NULL;
 v_child_status		VARCHAR2(1);
 v_checkrun_name	VARCHAR2(255);
 v_file_prefix		VARCHAR2(255);

 v_pos_format_code	VARCHAR2(100);
 v_pos_pay_format	VARCHAR2(300);
 
 
BEGIN

    fnd_file.PUT_LINE(fnd_file.LOG,   'Parameters');
    fnd_file.PUT_LINE(fnd_file.LOG,   '--------------------------------------------------------');
    fnd_file.PUT_LINE(fnd_file.LOG,   '  Bank Name            : '||p_bank_name);
    fnd_file.PUT_LINE(fnd_file.LOG,   '  Format               : '||p_format);
    fnd_file.PUT_LINE(fnd_file.LOG,   '  Payment Status       : '||p_payment_status);
	fnd_file.PUT_LINE(fnd_file.LOG,    ' Payment Date         : '||p_payment_to_date); --added for 31197
	fnd_file.PUT_LINE(fnd_file.LOG,   '--------------------------------------------------------');

   /*  Defect 30031

    BEGIN
      select a.positive_pay_format_code
        INTO v_pos_format_code
        from apps.iby_payment_profiles a,
             apps.iby_pay_instructions_all b 
       where b.payment_instruction_id=p_pay_instr_id
         and a.payment_profile_id=b.payment_profile_id;
    EXCEPTION
      WHEN others THEN
        v_pos_format_code:=NULL;
    END;

    IF v_pos_format_code IS NOT NULL THEN

       BEGIN
	 SELECT format_name
	   INTO v_pos_pay_format
	   FROM apps.iby_formats_tl
          WHERE format_code=v_pos_format_code;
       EXCEPTION
	 WHEN others THEN
	   v_pos_pay_format:=NULL;
       END;

    END IF;

   */


    IF p_format IS NOT NULL THEN

       IF p_format = 'OD WF POSITIVE PAY' THEN

	  v_file_prefix :='pospay_wf';

       ELSIF p_format = 'OD SC USD POS PAY FORMAT' THEN

          v_file_prefix :='pospay_scotia';  -- Defect 27074

       ELSIF p_format = 'OD SC CAD POS PAY FORMAT' THEN

          v_file_prefix :='pospay_scotia'; -- Defect 27074

       END IF;

       v_request_id:=FND_REQUEST.SUBMIT_REQUEST( 'IBY'
					     ,'IBY_FD_POS_PAY_FORMAT_2'
					     ,'Positive Pay File with Additional Parameters'
					     ,NULL
					     ,FALSE
					     ,NULL
					     ,p_format
					     ,p_bank_name
					     ,NULL
					     ,p_payment_to_date --added for 31197
					     ,p_payment_status
					     ,'No' 	
					     ,NULL,NULL,NULL,NULL,NULL
					    );


       IF v_request_id>0 THEN

          COMMIT;
          dbms_output.put_line('Positive Pay Program Request id : '|| TO_CHAR(v_request_id));
          fnd_file.PUT_LINE(fnd_file.LOG,   'Positive Pay Program Request id for '||p_format|| ': '|| TO_CHAR(v_request_id));
 
          IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

             IF v_dphase = 'COMPLETE' THEN

     	        fnd_file.PUT_LINE(fnd_file.LOG, 'Positive Pay Program Completed');

             END IF;

          END IF;

	   v_file_name:='o'||to_char(v_request_id)||'.out';
           v_sfile_name:='$APPLCSF/$APPLOUT/'||v_file_name;
           v_dfile_name:='$XXFIN_DATA/ftp/out/positivepay/'||v_file_prefix||'_'||TO_CHAR(v_request_id)||'.txt';


	   fnd_file.PUT_LINE(fnd_file.LOG,'Source File      : '||v_sfile_name);
	   fnd_file.PUT_LINE(fnd_file.LOG,'Destination File : '||v_dfile_name);

	   v_crequest_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY','OD: Common File Copy',NULL,FALSE,
 			  v_sfile_name,v_dfile_name,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

           IF v_crequest_id>0 THEN
              COMMIT;
	      dbms_output.put_line('File Transfer request id : '||TO_CHAR(v_crequest_id));
              fnd_file.PUT_LINE(fnd_file.LOG,   'XXCOMFILCOPY Request id for Positive Pay File Copy : '|| TO_CHAR(v_crequest_id));

	   ELSE

	     fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for XXCOMFILCOPY for Positive Pay');
             lc_error_loc := 'Error submitting request for XXCOMFILCOPY for Positive Pay';
             lc_err_msg := 'Error submitting request for XXCOMFILCOPY for Positive Pay';
             fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);

             xx_com_error_log_pub.log_error(  p_program_type => 'CONCURRENT PROGRAM'
	   			             ,p_program_name => 'OD Positive Pay Process'
				             ,p_program_id => fnd_global.conc_program_id 
				             ,p_module_name => 'AP'
				             ,p_error_location => 'Error at ' || lc_error_loc
				             ,p_error_message_count => 1
				             ,p_error_message_code => 'E'
				             ,p_error_message => lc_err_msg
				             ,p_error_message_severity => 'Major'
				             ,p_notify_flag => 'N'
				             ,p_object_type => 'Payment Batch Automation');


	   END IF;
       ELSE

         fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for Positive Pay Program');
         lc_error_loc := 'Error submitting request for Positive Pay Program';
         lc_err_msg := 'Error submitting request for Positive Pay Program : '|| p_format;
         fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);

         xx_com_error_log_pub.log_error(   p_program_type => 'CONCURRENT PROGRAM'
				       ,p_program_name => 'OD Positive Pay Process'
				       ,p_program_id => fnd_global.conc_program_id 
				       ,p_module_name => 'AP'
				       ,p_error_location => 'Error at ' || lc_error_loc
				       ,p_error_message_count => 1
				       ,p_error_message_code => 'E'
				       ,p_error_message => lc_err_msg
				       ,p_error_message_severity => 'Major'
				       ,p_notify_flag => 'N'
				       ,p_object_type => 'Payment Batch Automation');

       END IF;
       COMMIT;
    ELSE 
	p_errbuf:='Unable to get the Payment Profile';
        p_retcode:=2;
    END IF;
EXCEPTION
  WHEN others THEN
    fnd_file.PUT_LINE(fnd_file.LOG, 'When others in submit_pos_pay process :'||SQLERRM);
    dbms_output.put_line('When others in submit_pos_pay_process :'||SQLERRM);
END submit_pos_pay_process;

END XX_AP_IBY_POSITIVE_PAY_PKG;
/
