CREATE OR REPLACE PACKAGE BODY XX_COMN_CONC_REQ_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_COMN_CONC_REQ_PKG                                                               |
-- |  Description:  Plsql Package to run the   OD: Concurrent Requests Report   		     |
-- |                and send email the output                                                   |
-- |  RICE ID : R1399                                                                           |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author             Remarks                                        |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         06/22/2012   Radhika Patnala    Initial version                                |
-- | 1.1       13-SEP-2016 Praveen Vanga      Defect 39264 .EXCEL file fomat change to .xls | 
-- +============================================================================================+
-- +============================================================================================+
-- |  Name: SUBMIT_REPORT                                                                       |
-- |  Description: This procedure will run the OD: Concurrent Requests Report			|
-- |               and email the output                                                         |
-- =============================================================================================|
PROCEDURE SUBMIT_REPORT(errbuff     OUT  VARCHAR2
				   ,retcode     OUT  VARCHAR2
					   ,P_job_type   IN  VARCHAR2
				   ,P_app_id   IN  VARCHAR2
				   ,P_prg_id   IN  VARCHAR2
				   ,P_resp_name  IN  VARCHAR2
				   ,P_status     IN  VARCHAR2
				   ,P_start_time IN  VARCHAR2
				   ,P_end_time   IN  VARCHAR2
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
BEGIN

BEGIN
Select Responsibility_id into v_resp_id from fnd_responsibility_tl where responsibility_name=P_resp_name;
fnd_file.put_line(fnd_file.LOG,'The responsibility ID is'||v_resp_id);
Exception 
When others then 
fnd_file.put_line(fnd_file.LOG,'The responsibility not found');
END;
 BEGIN
   ------------------------------------------
   -- Selecting emails from translation table
   ------------------------------------------
  SELECT TV.target_value3,TV.target_value4,TV.target_value5
	INTO
		  EMAIL_TBL(3),EMAIL_TBL(4),EMAIL_TBL(5)
   FROM   XX_FIN_TRANSLATEVALUES TV
		 ,XX_FIN_TRANSLATEDEFINITION TD
   WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
   AND   TRANSLATION_NAME = 'EBS_NOTIFICATIONS'
   AND   Source_value1    = P_job_type;
   ------------------------------------
   --Building string of email addresses
   ------------------------------------
   lc_first_rec  := 'Y';
   For ln_cnt in 3..5 Loop
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
lc_temp_email:='ebs_test_notifications@officedepot.com'; --'it_erp_systems@officedepot.com';
   END IF;
 EXCEPTION
   WHEN others then
	 lc_temp_email:='ebs_test_notifications@officedepot.com'; --'it_erp_systems@officedepot.com';
 END;
v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
					template_code => 'XXCMCRQR',
			template_language => 'en',
			template_territory => 'US',
				output_format => 'EXCEL');
IF (v_addlayout) THEN
 fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
ELSE
 fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
END IF;
v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCMCRQR',
												 'OD: Concurrent Requests Report'
									   ,NULL
									   ,FALSE
									   ,P_app_id
                     ,P_prg_id
									   ,v_resp_id
									   ,P_status
									   ,P_start_time
									   ,P_end_time
								   );
IF v_request_id>0 THEN
 dbms_output.put_line('Request id :'||to_char(v_request_id));
 COMMIT;
END IF;
IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
		v_status,v_dphase,v_dstatus,x_dummy))  THEN
 IF v_dphase = 'COMPLETE' THEN
	v_file_name := 'XXCMCRQR_' || TO_CHAR (v_request_id) || '_1.xls';
	v_dfile_name :='$XXFIN_DATA/outbound/' || 'OD_Conc_Request_Report_'||v_rpt_date||'_'||TO_CHAR(v_request_id)|| '.XLS';
  v_efile_name:='OD_Conc_Request_Report_'||v_rpt_date||'_'||TO_CHAR(v_request_id)|| '.XLS';
	v_file_name   := '$APPLCSF/$APPLOUT/' ||v_file_name;
	vc_request_id :=fnd_request.submit_request ('XXFIN',
									   'XXCOMFILCOPY',
									   'OD: Common File Copy',
									   NULL,
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
						  (sender             => 'OracleEBS@officedepot.com',
						   recipients         => lc_temp_email,
						   cc_recipients      => NULL,
						   subject            => 'OD: Concurrent Request Report',
						   mime_type          => xx_pa_pb_mail.multipart_mime_type
						  );
		xx_pa_pb_mail.xx_email_excel(conn=>conn,
							 p_directory=>'XXFIN_OUTBOUND',
						   p_filename=>v_efile_name);
			xx_pa_pb_mail.end_attachment (conn => conn);
			xx_pa_pb_mail.end_mail (conn => conn);
	   END IF;
	END IF;   --------IF (fnd_concurrent.wait_for_request (vc_request_id,
 END IF;   --     IF v_dphase = 'COMPLETE' THEN
END IF;
COMMIT;
EXCEPTION
WHEN others THEN
errbuff:=sqlerrm;
retcode:='2';
END SUBMIT_REPORT;
END XX_COMN_CONC_REQ_PKG;
/
