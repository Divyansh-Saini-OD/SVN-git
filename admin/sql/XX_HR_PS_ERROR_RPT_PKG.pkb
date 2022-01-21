CREATE OR REPLACE PACKAGE BODY XX_HR_PS_ERROR_RPT_PKG 
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_HR_PS_ERROR_RPT_PKG                                                             |
-- |  Description:  Plsql Package to run the OD: HR PER Employees from Peoplesoft Error Report  |
-- |                and send email the output                                                   |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         08/21/2012   Paddy Sanjeevi   Initial version                                  |
-- | 1.1         12/30/2015   Harvinder Rakhra Retrofit R12.2                                   |
-- | 1.2         13-SEP-2016 Praveen Vanga      Defect 39264 .EXCEL file format change to .xls | 
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: XX_ERROR_RPT                                                                        |
-- |  Description: This procedure will run the OD: HR PER Employees from Peoplesoft Error Report|
-- |               and email the output                                                         |
-- =============================================================================================|

PROCEDURE XX_ERROR_RPT(errbuff     OUT VARCHAR2
                      ,retcode     OUT VARCHAR2
		      ,p_days	   IN  NUMBER
		      )
IS

  i			NUMBER:=0;
  conn            	UTL_SMTP.connection;
  v_file_name     	VARCHAR2 (100);
  v_dfile_name    	VARCHAR2 (100);
  v_efile_name		VARCHAR2 (100);
  v_defile_name		VARCHAR2 (100);
  v_sou_dir         VARCHAR2(50);
  v_sou_file        VARCHAR2(50);
  v_tar_dir         VARCHAR2(50);
  v_tar_zip         VARCHAR2(50);
  v_del_fil         VARCHAR2(50);
  v_request_id 		NUMBER;
  vc_request_id   	NUMBER;
  vd_request_id   	NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
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
  v_dzphase          VARCHAR2 (100);
  v_dzstatus         VARCHAR2 (100);
  v_ddphase         VARCHAR2 (100);
  v_ddstatus        VARCHAR2 (100);
  x_ddummy          VARCHAR2 (100);
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;
  v_rpt_date		VARCHAR2(10):=TO_CHAR(SYSDATE,'RRRRMMDD');
  Type TYPE_TAB_EMAIL  IS TABLE OF XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX BY BINARY_INTEGER ;
  EMAIL_TBL TYPE_TAB_EMAIL;
  lc_first_rec  varchar(1);
  lc_temp_email varchar2(2000);

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
       AND   TRANSLATION_NAME = 'OD_HR_ERROR_REPORT'
       AND   source_value1    = 'OUTBOUND_EMAILS';
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

lc_temp_email:='susan.vanmetre@officedepot.com;wes.innocent@officedepot.com;jacqueline.koivula@officedepot.com;FinancialSystems@officedepot.com;colette.reid@officedepot.com;armando.villasana@officedepot.com;hrim.global@officedepot.com';

       END IF;
	
     EXCEPTION
       WHEN others then
         lc_temp_email:='susan.vanmetre@officedepot.com;wes.innocent@officedepot.com;jacqueline.koivula@officedepot.com;FinancialSystems@officedepot.com;colette.reid@officedepot.com;armando.villasana@officedepot.com;hrim.global@officedepot.com';
     END;


   v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	                template_code => 'XXHRPSERPT', 
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

  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXHRPSERPT',
					   'OD: HR PER Employees from Peoplesoft Error Report',NULL,FALSE,
					    p_days
					  );
  IF v_request_id>0 THEN
     dbms_output.put_line('Request id :'||to_char(v_request_id));
     COMMIT;
  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

     IF v_dphase = 'COMPLETE' THEN
  
        v_file_name := 'XXHRPSERPT_' || TO_CHAR (v_request_id) || '_1.xls';
        v_dfile_name :='$XXFIN_DATA/outbound/' || 'Peoplesoft_HR_Error_Report_'||v_rpt_date||'_'||TO_CHAR (v_request_id)|| '.XLS';
	  v_efile_name:='Peoplesoft_HR_Error_Report_'||v_rpt_date||'_'||TO_CHAR (v_request_id)|| '.XLS';

        v_file_name   := '$APPLCSF/$APPLOUT/' || v_file_name;
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
			 --Added for defect 43838
			    v_sou_dir := '$XXFIN_DATA/outbound/';
				v_sou_file := v_efile_name;
                v_tar_dir := '$XXFIN_DATA/outbound/';
                v_tar_zip := v_efile_name;
                v_del_fil := 'No';
				v_defile_name:=v_efile_name||'_'||v_rpt_date||'.zip';
                vd_request_id :=fnd_request.submit_request ('XXCOMN',
                                           'XX_COMN_CREATE_ZIP_MULTI',
                                           'OD: Common Create Zip from Multiple Files',
                                            NULL,
                                            FALSE,
                                            v_sou_dir,
                                            v_sou_file,
                                            v_tar_dir,
                                            v_tar_zip,
                                            v_del_fil,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL
                                          );
									  
				IF vd_request_id > 0  THEN
                    COMMIT;
                END IF;
				IF (fnd_concurrent.wait_for_request (vd_request_id,
                                                 1,
                                                 60000,
                                                 v_dzphase,
                                                 v_dzstatus,
                                                 v_ddphase,
                                                 v_ddstatus,
                                                 x_ddummy
                                             )
             )  THEN		 
			      IF v_ddphase = 'COMPLETE' THEN
                conn :=xx_pa_pb_mail.begin_mail
                              (sender             => 'OracleEBS@officedepot.com',
                               recipients         => lc_temp_email,
                               cc_recipients      => NULL,
                               subject            => 'Peoplesoft HR Error Report',
                               mime_type          => xx_pa_pb_mail.multipart_mime_type
                              );
                   fnd_file.put_line(fnd_file.LOG, 'After mail');							  
            /*xx_pa_pb_mail.xx_email_excel(conn=>conn,
						         p_directory=>'XXFIN_OUTBOUND',
							   p_filename=>v_efile_name);
                xx_pa_pb_mail.end_attachment (conn => conn);
                xx_pa_pb_mail.end_mail (conn => conn);*/
				---Added for defect 43838
				fnd_file.put_line(fnd_file.LOG, 'Before zip');
		    xx_pa_pb_mail.xx_email_zip(conn=>conn,
						         p_directory=>'XXFIN_OUTBOUND',
							   p_filename=>v_defile_name);
                xx_pa_pb_mail.end_attachment (conn => conn);
                xx_pa_pb_mail.end_mail (conn => conn);
	       END IF;

        END IF;   --------IF (fnd_concurrent.wait_for_request (vc_request_id,

     END IF;   --     IF v_dphase = 'COMPLETE' THEN
  END IF;
  END IF;
  END IF;
  COMMIT;
EXCEPTION
   WHEN others THEN
    errbuff:=sqlerrm;
    retcode:='2';
END XX_ERROR_RPT;

END XX_HR_PS_ERROR_RPT_PKG;

/