create or replace PACKAGE BODY XXAR_GRACE_DAYS_WRRAPER
AS
-- +============================================================================================+
-- |  Office Depot - Grace days report                                                       |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XXAR_GRACE_DAYS_WRRAPER                                                           |
-- |  Description:  Plsql Package to run the OD:AR Discount Grace Days Report         		      |
-- |                and send report output over email                                           |
-- |  RICE ID : R1399                                                                           |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author             Remarks                                        |
-- | =========   ===========  =============      =============================================  |
-- | 1.0         29-July-2021  Ankit Handa    Initial version                                |
-- +============================================================================================+
-- +============================================================================================+
-- |  Name: SUBMIT_REPORT                                                                       |
-- |  Description: This procedure will run the OD:AR Discount Grace Days Report                 |
-- |               and email the output                                                         |
-- =============================================================================================|
PROCEDURE SUBMIT_REPORT(errbuff     OUT  VARCHAR2
                       ,retcode     OUT  VARCHAR2                      
                       )
IS
i		            	NUMBER:=0;
conn            	UTL_SMTP.connection;
v_file_name     	VARCHAR2 (100);
v_dfile_name    	VARCHAR2 (100);
v_efile_name		VARCHAR2 (100);
v_request_id 		NUMBER;
vc_request_id   	NUMBER;
v_user_id		NUMBER:=fnd_global.user_id;
V_resp_id NUMBER;
v_phase		varchar2(100)   ;
v_status		varchar2(100)   ;
v_dphase		varchar2(100)	;
v_dstatus		varchar2(100)	;
x_dummy		varchar2(2000) 	;
v_error		VARCHAR2(2000)	;
v_addlayout 		boolean;
x_cdummy        	VARCHAR2 (2000);
v_cdphase       	VARCHAR2 (100);
v_cdstatus      	VARCHAR2 (100);
v_cphase        	VARCHAR2 (100);
v_cstatus       	VARCHAR2 (100);
lc_boolean            BOOLEAN;
lc_boolean1           BOOLEAN;
v_rpt_date		VARCHAR2(10):=TO_CHAR(SYSDATE,'RRRRMMDD');
Type TYPE_TAB_EMAIL  IS TABLE OF XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX BY BINARY_INTEGER ;
EMAIL_TBL TYPE_TAB_EMAIL;
lc_first_rec  varchar(1);
lc_temp_email varchar2(2000);

  l_responsibility_id NUMBER;
  l_application_id    NUMBER;
  l_user_id           NUMBER;
  l_request_id        NUMBER;

 BEGIN

  
  l_user_id := fnd_global.user_id;
  l_responsibility_id  := NULL;
  l_application_id		:= NULL;
  
 
  ------------------------------------
 lc_temp_email:='ARFinancialControlDept@officedepot.com'; --'it_erp_systems@officedepot.com';
 --lc_temp_email:= p_recipients_id;
 /**IF l_user_id is not NULL and l_responsibility_id is not NULL and  l_application_id is not NULL THEN
 
 fnd_global.apps_initialize (l_user_id,l_responsibility_id,l_application_id);
 
	 v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
										 template_code 		=> 'XXARCOMBAGING',
										 template_language 	=> 'en',
										 template_territory => 'US',
										 output_format 		=> 'EXCEL'
										 );
	IF (v_addlayout) THEN
	 fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
	ELSE
	 fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
	END IF; **/
	
	v_request_id:=FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
											 ,'XX_AR_DISGRACE_REPORT'
											 ,'OD:AR Discount Grace Days Report'
											 ,SYSDATE --NULL
											 ,FALSE											
										   );
	IF v_request_id >0 THEN
	 dbms_output.put_line('Request id :'||to_char(v_request_id));
	 COMMIT;
	END IF;
	
	IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
										v_status,v_dphase,
										v_dstatus,x_dummy
									   )
	   )  THEN
	 IF v_dphase = 'COMPLETE' THEN
		v_file_name := 'o' || TO_CHAR (v_request_id) || '.out';
		--v_dfile_name :='$XXFIN_DATA/outbound/' ||v_file_name;
		v_dfile_name :='$XXFIN_DATA/outbound/' ||'o' || TO_CHAR (v_request_id) || '.out';
		v_efile_name:= v_file_name;
		v_file_name   := '$APPLCSF/$APPLOUT/' ||v_file_name;
		vc_request_id :=fnd_request.submit_request('XXFIN',
												   'XXCOMFILCOPY',
												   'OD: Common File Copy',
												  sysdate,-- NULL,
												   FALSE,
												   v_file_name,
												   v_dfile_name,
												   NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
												   NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
												   NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
												   NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
												   NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
												   NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
												   NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
												   NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
												   NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
												   NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
												  );
		IF vc_request_id > 0  THEN
		   COMMIT;
		END IF;
		
		IF (fnd_concurrent.wait_for_request (vc_request_id,
												 1,
												 60000,
												 v_cphase,
												 v_cstatus,
												 v_cdphase,
												 v_cdstatus,
												 x_cdummy
											 )
			 )  THEN
			 IF v_cdphase = 'COMPLETE' THEN
       
				conn :=xx_pa_pb_mail.begin_mail
											  (sender             => 'noreply@officedepot.com',
											   recipients         => lc_temp_email,
											   cc_recipients      => null,
											   subject            => 'Grace Days report for'||sysdate,
											   mime_type          => xx_pa_pb_mail.multipart_mime_type
											  );
				xx_pa_pb_mail.xx_email_excel(conn			=>conn,
											 p_directory	=>'XXFIN_OUTBOUND',
											 p_filename		=>v_efile_name
											 );
                       
                 
				xx_pa_pb_mail.end_attachment (conn => conn);
				xx_pa_pb_mail.end_mail (conn => conn);
		     END IF;
		 END IF;   --------IF (fnd_concurrent.wait_for_request (vc_request_id,
	 END IF;   --     IF v_dphase = 'COMPLETE' THEN
	END IF;
 COMMIT;
 EXCEPTION
 WHEN OTHERS THEN
	dbms_output.put_line('ERROR');
 END SUBMIT_REPORT;
END XXAR_GRACE_DAYS_WRRAPER;
/