CREATE OR REPLACE PACKAGE BODY XXRPA_COMAGEING_REP_WRRAPER
AS
-- +============================================================================================+
-- |  Office Depot - RPA Project Simplify                                                       |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_COMAGEING_REP_WRRAPER                                                           |
-- |  Description:  Plsql Package to run the   OD: AR Combined Aging Views report      		      |
-- |                and send report output over email                                           |
-- |  RICE ID : R1399                                                                           |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author             Remarks                                        |
-- | =========   ===========  =============      =============================================  |
-- | 1.0         14-May-2021  Gitanjali Singh    Initial version                                |
-- +============================================================================================+
-- +============================================================================================+
-- |  Name: SUBMIT_REPORT                                                                       |
-- |  Description: This procedure will run the OD: AR Combined Aging Views report               |
-- |               and email the output                                                         |
-- =============================================================================================|
PROCEDURE SUBMIT_REPORT(/*errbuff     OUT  VARCHAR2
                       ,retcode     OUT  VARCHAR2                       
                       ,P_end_time   IN  VARCHAR2*/
                        p_customer 		IN NUMBER
                       ,p_recipients_id	IN VARCHAR2
                       ,p_cc_recipients	IN VARCHAR2	default NULL
                       ,p_user_name		IN VARCHAR2
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

 /* BEGIN
  Select Responsibility_id into v_resp_id from fnd_responsibility_tl 
  where LOWER (fr.responsibility_name) LIKE LOWER('OD (US) Credit Manager');
  fnd_file.put_line(fnd_file.LOG,'The responsibility ID is'||v_resp_id);
  Exception
  When others then
  fnd_file.put_line(fnd_file.LOG,'The responsibility not found');
  END;*/
  
  l_user_id := NULL;
  l_responsibility_id  := NULL;
  l_application_id		:= NULL;
  
  --
  BEGIN
  SELECT user_id INTO l_user_id FROM fnd_user WHERE user_name = p_user_name and END_DATE is null; --'GITANJALI_SINGH'
  EXCEPTION 
  WHEN OTHERS THEN
   dbms_output.put_line('User details is either incorrect or inactive user:');
  END;
  
  IF l_user_id is not null THEN
	   BEGIN
		SELECT usr.user_id, res.RESPONSIBILITY_ID, res.application_id
		  INTO l_user_id, l_responsibility_id, l_application_id
		  FROM FND_USER usr, FND_RESPONSIBILITY_TL res, FND_USER_RESP_GROUPS grp
		 WHERE 1=1 --upper(res.RESPONSIBILITY_NAME) like upper('%' || NVL('EnterRespName', 'INV')|| '%')
		   AND LOWER (res.responsibility_name) LIKE LOWER('OD (US) Credit Manager')
		   AND grp.responsibility_id = res.responsibility_id
		   AND grp.user_id = usr.user_id
		   AND user_name = p_user_name   --'GITANJALI_SINGH'
		   ;
	   EXCEPTION
	   WHEN OTHERS THEN
	   dbms_output.put_line('Unable to retrive responsibility details for given user');
	   END;
   END IF;
    
  ------------------------------------
 --lc_temp_email:='gitanjali.singh@officedepot.com'; --'it_erp_systems@officedepot.com';
 lc_temp_email:= p_recipients_id;
 IF l_user_id is not NULL and l_responsibility_id is not NULL and  l_application_id is not NULL THEN
 
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
	END IF;
	
	v_request_id:=FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
											 ,'XXARCOMBAGING'
											 ,'OD: AR Combined Aging Views'
											 ,SYSDATE --NULL
											 ,FALSE
											 ,p_customer --52850
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
		v_file_name := 'XXARCOMBAGING_' || TO_CHAR (v_request_id) || '_1.xls';
		--v_dfile_name :='$XXFIN_DATA/outbound/' ||v_file_name;
		v_dfile_name :='$XXFIN_DATA/outbound/' ||'XXARCOMBAGING_' || TO_CHAR (v_request_id) || '_1.xls';
		v_efile_name:= v_file_name;
		v_file_name   := '$APPLCSF/$APPLOUT/' ||v_file_name;
		vc_request_id :=fnd_request.submit_request('XXFIN',
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
											  (sender             => 'noreply@officedepot.com',
											   recipients         => lc_temp_email,
											   cc_recipients      => p_cc_recipients,
											   subject            => 'OD: Ageing Request Report',
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
 END IF;
 COMMIT;
 EXCEPTION
 WHEN OTHERS THEN
 --errbuff:=sqlerrm;
 --retcode:='2';
	dbms_output.put_line('ERROR');
 END SUBMIT_REPORT;
END XXRPA_COMAGEING_REP_WRRAPER;
/