SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_CAP_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_FQA_PKG.pkb      	   	               |
-- | Description :  OD QA FQA Processing Pkg                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       25-Apr-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       14-Jun-2011 Paddy Sanjeevi     Defect 12079              |
-- |1.2       21-Jul-2011 Paddy Sanjeevi     Modified email message    |
-- |1.3       25-Sep-2012 Paddy Sanjeevi     Defect 20454              |
-- |1.4       10-OCT-2013 Kiran Maddala      Modified for defect 21229 |
-- +===================================================================+
AS



FUNCTION xx_cap_response( p_act IN VARCHAR2
			 ,p_act_ID IN VARCHAR2) 
RETURN NUMBER
IS
v_days VARCHAR2(150);
v_act  VARCHAR2(150);
BEGIN

-- Defect 20464  Added Customer Complaints logic 

  v_act:=p_act;

  IF p_act='CC' THEN

     BEGIN
       SELECT 'CC'||UPPER(od_pb_defect_code)
         INTO v_act
         FROM q_od_ob_customer_complaints_v
        WHERE od_pb_customer_complaint_id=p_act_id;
     EXCEPTION
       WHEN others THEN
	 v_act:='CCMINOR';
     END;

  END IF;

  SELECT c.description
    INTO v_days
    FROM apps.fnd_flex_values_vl c,  
         apps.fnd_flex_value_sets b
   WHERE b.flex_value_set_name='XX_QA_CAP_ESC_DAYS'
     AND c.flex_value_set_id=b.flex_value_set_id
     AND c.flex_value=v_act;
   RETURN(TO_NUMBER(v_days));
EXCEPTION
 WHEN others THEN
   RETURN(0);
END xx_cap_response;

PROCEDURE cap_ds_upd
IS

CURSOR C1 IS
SELECT a.rowid arowid,
       a.*
  FROM xx_qa_cap_ds_int a
 WHERE process_Flag=4;

BEGIN
  UPDATE xx_qa_cap_ds_int
     SET process_flag=1
   WHERE process_flag=6;
  COMMIT;

  UPDATE xx_qa_cap_ds_int a
     SET (plan_id,organization_id,occurrence,process_Flag)=(SELECT plan_id,
						      organization_id,	
						      occurrence,4
						 FROM apps.Q_OD_OB_CAP_DEFECTS_V
						WHERE od_ob_ref_capid=a.capid
						  AND od_ob_ds_id=a.ds_id)
   WHERE process_Flag=1;
  COMMIT;

  UPDATE xx_qa_cap_ds_int
     SET process_flag=6
   WHERE process_flag=1;
  COMMIT;

  FOR cur IN C1 LOOP
     
      UPDATE qa_results
	 SET comment2=cur.rootcause,
	     comment4=cur.corrective_action,
	     comment5=cur.preventive_action,
	     character4=TO_CHAR(cur.ca_impl_date,'YYYYMMDD')		
       WHERE plan_id=cur.plan_id
	 AND organization_id=cur.organization_id
	 AND occurrence=cur.occurrence;	

      IF SQL%FOUND THEN	
	
         UPDATE xx_qa_cap_ds_int
  	    SET process_flag=7
          WHERE rowid=cur.arowid;

      ELSE

         UPDATE xx_qa_cap_ds_int
  	    SET process_flag=6
          WHERE rowid=cur.arowid;

      END IF;

  END LOOP;
  COMMIT;
END cap_ds_upd;

PROCEDURE send_capds_rpt(p_car_id IN VARCHAR2,
			 p_subject IN VARCHAR2,
			 p_mail_list IN VARCHAR2,
			 p_cc_email  IN VARCHAR2,
			 p_text	     IN VARCHAR2,
			 p_plan_id   IN NUMBER,
			 p_occurrence IN NUMBER,
			 p_org_id     IN NUMBER)

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

  v_recipient		varchar2(100);

BEGIN

   v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXMER',
	 	                template_code => 'XXQACAPD', 
				template_language => 'en', 
				template_territory => 'US', 
			        output_format => 'EXCEL');

  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;

  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQACAPD','OD QA CAP DS Report',NULL,FALSE,
		p_car_id,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

  IF v_request_id>0 THEN
     COMMIT;
     v_file_name:='XXQACAPD_'||to_char(v_request_id)||'_1.EXCEL';
     v_sfile_name:=p_car_id||'_'||TO_CHAR(SYSDATE,'MMDDYY')||'.xls';
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
	 

  	        conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'OD-OB-QualityTeam@officedepot.com',
	  	        recipients => p_mail_list,
			cc_recipients=>p_cc_email,
		        subject => p_subject,
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);


             xx_pa_pb_mail.xx_attach_excel(conn,v_sfile_name);
             xx_pa_pb_mail.end_attachment(conn => conn);
             xx_pa_pb_mail.attach_text(conn => conn,
  		                      data => p_text,
		                      mime_type => 'multipart/html');

             xx_pa_pb_mail.end_mail( conn => conn );

     	     UPDATE apps.qa_results  
                SET character21='Y'
              WHERE plan_id=p_plan_id
                AND occurrence=p_occurrence
	        AND organization_id=p_org_id;
	
	     COMMIT;

	   END IF; --IF v_cdphase = 'COMPLETE' THEN -- child

 	END IF; --IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,


     END IF; -- IF v_dphase = 'COMPLETE' THEN  -- Main

  END IF; -- IF (FND_CONCURRENT.WAIT_FOR_REQUEST -- Main

END send_capds_rpt;


PROCEDURE xx_status_upd
IS
CURSOR C1 IS
SELECT DISTINCT od_ob_ref_capid,OD_PB_LEGACY_OCR_ID,OD_PB_LEGACY_COL_ID
  FROM apps.q_od_ob_cap_defects_V
 WHERE last_update_date>sysdate-.5
   AND od_pb_legacy_ocr_id IS NOT NULL
   AND od_pb_legacy_col_id IS NOT NULL;

CURSOR C2(p_cap_id IN VARCHAR2) 
IS
SELECT DISTINCT od_pb_approval_status
  FROM apps.q_od_ob_cap_defects_v
 WHERE od_ob_ref_capid=p_cap_id;


v_lsdate	DATE;
v_sdate		DATE;
v_cpid	 	NUMBER;
v_cpaid	 	NUMBER;
v_request_id 	NUMBER;
v_req 		VARCHAR2(1):='N';
v_apr 		VARCHAR2(1):='N';
v_rej 		VARCHAR2(1):='N';
v_plan_id 	NUMBER;

BEGIN

  SELECT plan_id
    INTO v_plan_id
    FROM apps.qa_plans
   WHERE name='OD_OB_CAP';

/*
  BEGIN
    SELECT actual_start_date,
  	   concurrent_program_id,
	   program_application_id
      INTO v_sdate,
           v_cpid,
	   v_cpaid
      FROM apps.fnd_concurrent_requests
     WHERE request_id=fnd_global.conc_request_id;
  EXCEPTION
     WHEN others THEN
       v_sdate:=NULL;
       v_cpid:=NULL;
       v_cpaid:=NULL;
  END;

   BEGIN
    SELECT actual_start_date
      INTO v_lsdate
      FROM apps.fnd_concurrent_requests
     WHERE concurrent_program_id=v_cpid
	 AND program_application_id=v_cpaid
	 AND actual_completion_date=(SELECT MAX(actual_completion_date)
						   FROM apps.fnd_concurrent_requests
						  WHERE concurrent_program_id=v_cpid
						    AND program_application_id=v_cpaid
						    AND actual_start_date IS NOT NULL	
						    AND actual_start_date<v_sdate)
       AND actual_start_date IS NOT NULL
       AND ROWNUM<2;
   EXCEPTION
     WHEN others THEN
	v_lsdate:=SYSDATE-1;
   END;
*/

  FOR cur IN C1 LOOP

    v_req :='N';
    v_apr :='N';
    v_rej :='N';

    FOR c IN C2(cur.od_ob_ref_capid) LOOP
      
        IF c.od_pb_approval_status='REQUEST' THEN

	   v_req:='Y';

        ELSIF c.od_pb_approval_status='APPROVED' THEN

	   v_apr:='Y';

        ELSIF c.od_pb_approval_status='REJECTED' THEN

	   v_rej:='Y';
	
	END IF;
	
    END LOOP;
   
    IF (v_req='Y' AND v_apr='N' AND v_rej='N') THEN

	UPDATE qa_results
 	   SET character18='REQUEST'
	 WHERE plan_id=v_plan_id
	   AND occurrence=cur.od_pb_legacy_ocr_id
	   AND collection_id=cur.od_pb_legacy_col_id;

	UPDATE qa_results
 	   SET character17=TO_CHAR(SYSDATE,'YYYY/MM/DD')
	 WHERE plan_id=v_plan_id
	   AND occurrence=cur.od_pb_legacy_ocr_id
	   AND collection_id=cur.od_pb_legacy_col_id
           AND character17 IS NULL;

    END IF;

    IF (v_req='Y' AND v_apr='Y' AND v_rej='N') THEN

	UPDATE qa_results
 	   SET character18='REQUEST'
	 WHERE plan_id=v_plan_id
	   AND occurrence=cur.od_pb_legacy_ocr_id
	   AND collection_id=cur.od_pb_legacy_col_id;

	UPDATE qa_results
 	   SET character17=TO_CHAR(SYSDATE,'YYYY/MM/DD')
	 WHERE plan_id=v_plan_id
	   AND occurrence=cur.od_pb_legacy_ocr_id
	   AND collection_id=cur.od_pb_legacy_col_id
           AND character17 IS NULL;

    END IF;

    IF v_rej='Y' THEN

	UPDATE qa_results
 	   SET character18='REJECTED'
	 WHERE plan_id=v_plan_id
	   AND occurrence=cur.od_pb_legacy_ocr_id
	   AND collection_id=cur.od_pb_legacy_col_id;

    END IF;

    IF (v_req='N' AND v_apr='Y' AND v_rej='N') THEN

	UPDATE qa_results
 	   SET character18='APPROVED'
	 WHERE plan_id=v_plan_id
	   AND occurrence=cur.od_pb_legacy_ocr_id
	   AND collection_id=cur.od_pb_legacy_col_id;

	UPDATE qa_results
 	   SET character19=TO_CHAR(SYSDATE,'YYYY/MM/DD')
	 WHERE plan_id=v_plan_id
	   AND occurrence=cur.od_pb_legacy_ocr_id
	   AND collection_id=cur.od_pb_legacy_col_id
	   AND character19 IS NULL;

    END IF;

  END LOOP;
  COMMIT;
END xx_status_upd;

PROCEDURE XX_CAP_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS

   CURSOR c_cap_sent IS                        
   SELECT *
     FROM apps.Q_OD_OB_CAP_V a
    WHERE OD_PB_DATE_CAPA_SENT IS NOT NULL
      AND NVL(OD_OB_CAPSENT_NOTIFY,'N')='N';

   CURSOR c_nocapqa IS
   SELECT *
     FROM apps.Q_OD_OB_CAP_V a
    WHERE OD_PB_DATE_CAPA_SENT IS NOT NULL
      AND OD_PB_DATE_CAPA_RECEIVED IS NULL;
     -- AND NVL(OD_OB_NOCAPQA_NOTIFY,'N')='N';    ---  As per Ver 1.4  

   CURSOR c_noaprstatus IS
   SELECT *
     FROM apps.Q_OD_OB_CAP_DEFECTS_V a
    WHERE OD_PB_APPROVAL_STATUS='REQUEST'
   --   AND NVL(OD_OB_REQNAPR_NTFY,'N')='N'     ---  As per Ver 1.4  
      AND (SYSDATE-OD_SC_REQ_AUDIT_DATE)>1;

   CURSOR c_capfnvd IS
   SELECT *
     FROM apps.Q_OD_OB_CAP_DEFECTS_V a
    WHERE OD_PB_DATE_CORR_IMPL IS NOT NULL
      AND OD_PB_DATE_VERIFIED IS NULL
     -- AND NVL(OD_OB_CAPFNVD_NOTIFY,'N')='N'     ---  As per Ver 1.4  
      AND (SYSDATE-OD_PB_DATE_CORR_IMPL)>30;

   CURSOR c_capinvd IS                    
   SELECT *
     FROM apps.Q_OD_OB_CAP_DEFECTS_V a
    WHERE OD_PB_DATE_CORR_IMPL IS NOT NULL
      AND OD_PB_DATE_VERIFIED IS NULL
      AND NVL(OD_OB_CAPINVD_NOTIFY,'N')='N'
      AND (SYSDATE-OD_PB_DATE_CORR_IMPL)>14;


 conn 			utl_smtp.connection;
 v_email_list    	VARCHAR2(3000);
 v_cc_email_list	VARCHAR2(3000);
 v_text			VARCHAR2(8000);
 v_subject		VARCHAR2(3000);
 v_region_contact  	varchar2(250);
 v_region		varchar2(50);
 v_nextaudit_date	date;
 v_errbuf     		VARCHAR2(2000);
 v_retcode    		VARCHAR2(50);
 v_qa_esc     		VARCHAR2(50);
 v_instance		VARCHAR2(10);
 v_cnt			NUMBER;
 v_cap_message		VARCHAR2(2000);
 l_char18		VARCHAR2(150);	       -- As per Ver 1.4 	
 l_char19		VARCHAR2(150);         -- As per Ver 1.4 
 l_char22		VARCHAR2(150);        -- As per Ver 1.4 
 BEGIN

   SELECT name INTO v_instance FROM v$database;
   
   xx_status_upd;

   cap_ds_upd;    

   FOR cur IN c_cap_sent LOOP

       v_text	:='Please see the details below '||chr(10);
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text || 'CAP ID         : '||cur.OD_PB_cAR_ID||chr(10);
       v_text   :=v_text || 'QA Activity    : '||cur.OD_OB_QA_ID||chr(10);
       v_text   :=v_text || 'Vendor Name    : '||cur.OD_OB_VENDOR_NAME||chr(10);
       v_text   :=v_text || 'Factory Name   : '||cur.OD_SC_FACTORY_NAME||chr(10);
       v_text   :=v_text || 'Date CAP Sent  : '||TO_CHAR(cur.OD_PB_DATE_CAPA_SENT)||chr(10);
		
       v_subject :=cur.OD_PB_CAR_ID||' CAP has been submitted';
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||'Email back completed excel file with Corrective Action Plan details by '||TO_CHAR(cur.OD_OB_CAP_RESPOND_BY);


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_AUDITOR_NAME;
	  v_cc_email_list:=cur.OD_SC_FACTORY_EMAIL||';'||cur.OD_PB_QA_ENGR_EMAIL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com';
	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       SELECT COUNT(1)
	 INTO v_cnt
	 FROM apps.q_od_ob_cap_defects_v
	WHERE od_ob_ref_capid=cur.od_pb_car_id;

       IF v_cnt>0 THEN

	  IF     cur.od_pb_auditor_name IS NOT NULL 
	     AND cur.od_sc_factory_email IS NOT NULL
	     AND cur.od_pb_qa_engr_email IS NOT NULL  THEN

   	     send_capds_rpt( cur.od_pb_car_id,
	  	  	     v_subject,v_email_list,v_cc_email_list,v_text,
			     cur.plan_id,cur.occurrence,cur.organization_id
	  	           );
          ELSE
	    v_cap_message   :=v_cap_message || 'CAP ID         : '||cur.OD_PB_cAR_ID||chr(10);
            v_cap_message   :=v_cap_message || 'Factory/Approver/Submitter Email is missing to send CAP report to Vendor';

            xx_qa_fqa_pkg.SEND_NOTIFICATION('CAP Emails are missing','Fritz.Lutzy@officedepot.com',NULL,v_cap_message);
         
	  END IF;
       END IF;	

   END LOOP;
   commit;

   FOR cur IN c_nocapqa LOOP

     BEGIN	
       SELECT description
         INTO v_qa_esc
         FROM apps.fnd_flex_values_vl
        WHERE flex_value_set_id IN (SELECT flex_value_set_id
  		 	 	    FROM apps.fnd_flex_value_sets
			           WHERE flex_value_set_name='XX_QA_CAP_ESC_DAYS') 
          AND flex_value=cur.OD_OB_QA_ACT
          AND sysdate between nvl(start_date_active,sysdate) and nvl(end_date_active,sysdate);     
     EXCEPTION
       WHEN others THEN
	 v_qa_esc:='3';
     END;

     IF (SYSDATE-cur.OD_PB_DATE_CAPA_SENT)>TO_NUMBER(v_qa_esc) THEN 
     
        v_text	:='Please see the details below '||chr(10);
        v_text   :=v_text ||chr(10);	
        v_text   :=v_text || 'CAP ID         : '||cur.OD_PB_cAR_ID||chr(10);
        v_text   :=v_text || 'QA Activity    : '||cur.OD_OB_QA_ID||chr(10);
        v_text   :=v_text || 'Vendor Name    : '||cur.OD_OB_VENDOR_NAME||chr(10);
        v_text   :=v_text || 'Factory Name   : '||cur.OD_SC_FACTORY_NAME||chr(10);
        v_text   :=v_text || 'Date CAP Sent  : '||TO_CHAR(cur.OD_PB_DATE_CAPA_SENT)||chr(10);
        v_text   :=v_text ||chr(10);	
        v_text   :=v_text ||chr(10);	
        v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';
		
        v_subject :=cur.OD_PB_CAR_ID||' has not been Submitted for Request';
 
        IF lc_send_mail='Y' THEN
           v_email_list:=cur.OD_PB_AUDITOR_NAME;    --||':'||cur.OD_PB_QA_ENGR_EMAIL ;  -- Commented Approver mail as per Ver 1.4  
           v_cc_email_list:= null; -- Added by Kmaddala as part of QC # 21229
        ELSE
           v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
           v_cc_email_list:= null; -- Added by Kmaddala as part of QC # 21229
        END IF;
               
        IF v_instance<>'GSIPRDGB' THEN

 	   v_subject:='Please Ignore this mail :'||v_subject;

        END IF;          
  
        xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);          
        
         BEGIN  					 -- As per Ver 1.4 
	   SELECT character22 INTO l_char22     -- As per Ver 1.4 
	     FROM apps.qa_results
	    WHERE plan_id=cur.plan_id
	      AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;	
		 	      
            IF NVL(l_char22,'N') <> 'Y' THEN			 -- As per Ver 1.4 

        UPDATE apps.qa_results  
           SET character22='Y'
         WHERE plan_id=cur.plan_id
           AND occurrence=cur.occurrence
	   AND organization_id=cur.organization_id;
	   
	    END IF;
	  EXCEPTION                                      -- As per Ver 1.4 
	     WHEN OTHERS THEN
	     NULL;
	  END;
	
     END IF;
   END LOOP;
   commit;

   FOR cur IN c_noaprstatus LOOP

       v_text	:='Please see the details below '||chr(10);
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text || 'DS ID          : '||cur.OD_OB_DS_ID||chr(10);
       v_text   :=v_text || 'CAP ID         : '||cur.OD_OB_REF_cAPID||chr(10);
       v_text   :=v_text || 'QA Activity    : '||cur.OD_OB_QA_ID||chr(10);
       v_text   :=v_text || 'Vendor Name    : '||cur.OD_OB_VENDOR_NAME||chr(10);
       v_text   :=v_text || 'Factory Name   : '||cur.OD_SC_FACTORY_NAME||chr(10);
       v_text   :=v_text || 'Approval Status: '||cur.OD_PB_APPROVAL_STATUS||chr(10);
       v_text   :=v_text || 'Request Date   : '||(cur.OD_SC_REQ_AUDIT_DATE)||chr(10);
		
       v_subject :=cur.OD_OB_REF_cAPID||' has not been updated from Request';
        v_text   :=v_text ||chr(10);	
        v_text   :=v_text ||chr(10);	
        v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';

       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGR_EMAIL; --||':'||cur.OD_PB_AUDITOR_NAME;    -- Commented Submitter mail as per Ver 1.4    
          v_cc_email_list:=null;-- Added by kmaddala as part of QC # 21229
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
          v_cc_email_list:=null; -- Added by kmaddala as part of QC # 21229
       END IF;            

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
       
 
       BEGIN  					 -- As per Ver 1.4 
            SELECT character18 INTO l_char18     -- As per Ver 1.4 
             FROM apps.qa_results
       	    WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;	
	      
	      IF NVL(l_char18,'N') <> 'Y' THEN			 -- As per Ver 1.4 
         

  	   UPDATE apps.qa_results  
              SET character18='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
	      
	      END IF;
	      EXCEPTION                                      -- As per Ver 1.4 
	        WHEN OTHERS THEN
	    	NULL;
	    END;
	      
		      
   END LOOP;
   commit;

   FOR cur IN c_capfnvd LOOP

       v_text	:='Please see the details below '||chr(10);
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text || 'DS ID             : '||cur.OD_OB_DS_ID||chr(10);
       v_text   :=v_text || 'CAP ID            : '||cur.OD_OB_REF_cAPID||chr(10);
       v_text   :=v_text || 'QA Activity       : '||cur.OD_OB_QA_ID||chr(10);
       v_text   :=v_text || 'Vendor Name       : '||cur.OD_OB_VENDOR_NAME||chr(10);
       v_text   :=v_text || 'Factory Name      : '||cur.OD_SC_FACTORY_NAME||chr(10);
       v_text   :=v_text || 'Defect Summary    : '||cur.OD_PB_DEFECT_SUM||chr(10);
       v_text   :=v_text || 'Root Cause        : '||cur.OD_PB_ROOT_CAUSE||chr(10);
       v_text   :=v_text || 'Corrective Action : '||cur.OD_PB_CORR_ACTION||chr(10);
       v_text   :=v_text || 'Preventive Action : '||cur.OD_PB_PREVENTIVE_ACTION||chr(10);
       v_text   :=v_text || 'Approval Status   : '||cur.OD_PB_APPROVAL_STATUS||chr(10);
       v_text   :=v_text || 'Date Approved     : '||TO_CHAR(cur.OD_PB_DATE_APPROVED)||chr(10);
       v_text   :=v_text || 'Date Implemented  : '||TO_CHAR(cur.OD_PB_DATE_CORR_IMPL)||chr(10);
       v_text   :=v_text || 'Comments          : '||cur.OD_PB_COMMENTS||chr(10);

       v_subject :='CAP/DS ID : '||cur.OD_OB_REF_CAPID||'/'||cur.OD_OB_DS_ID||' is Pending Verification more than a month';

       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';

       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGR_EMAIL; --||':'||cur.OD_PB_AUDITOR_NAME;    -- Commented Submitter mail as per Ver 1.4      
          v_cc_email_list:=null; -- Added by kmaddala as part of QC # 21229
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
          v_cc_email_list:=null; -- Added by Kmaddala as part of QC # 21229
       END IF;
       
       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;      
      
       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);       
       
         BEGIN  					 -- As per Ver 1.4 
	   SELECT character19 INTO l_char19     -- As per Ver 1.4 
	     FROM apps.qa_results
	    WHERE plan_id=cur.plan_id
	      AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;	
	 	      
            IF NVL(l_char19,'N') <> 'Y' THEN			 -- As per Ver 1.4 
         

  	   UPDATE apps.qa_results  
              SET character19='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
	      
	     END IF;
	   EXCEPTION                                      -- As per Ver 1.4 
	     WHEN OTHERS THEN
	     NULL;
	   END;      
	
   END LOOP;
   commit;

   FOR cur IN c_capinvd LOOP

       v_text	:='Please see the details below '||chr(10);
       v_text   :=v_text||chr(10);
       v_text   :=v_text || 'DS ID             : '||cur.OD_OB_DS_ID||chr(10);
       v_text   :=v_text || 'CAP ID            : '||cur.OD_OB_REF_cAPID||chr(10);
       v_text   :=v_text || 'QA Activity       : '||cur.OD_OB_QA_ID||chr(10);
       v_text   :=v_text || 'Vendor Name       : '||cur.OD_OB_VENDOR_NAME||chr(10);
       v_text   :=v_text || 'Factory Name      : '||cur.OD_SC_FACTORY_NAME||chr(10);
       v_text   :=v_text || 'Defect Summary    : '||cur.OD_PB_DEFECT_SUM||chr(10);
       v_text   :=v_text || 'Root Cause        : '||cur.OD_PB_ROOT_CAUSE||chr(10);
       v_text   :=v_text || 'Corrective Action : '||cur.OD_PB_CORR_ACTION||chr(10);
       v_text   :=v_text || 'Preventive Action : '||cur.OD_PB_PREVENTIVE_ACTION||chr(10);
       v_text   :=v_text || 'Approval Status   : '||cur.OD_PB_APPROVAL_STATUS||chr(10);
       v_text   :=v_text || 'Date Approved     : '||TO_CHAR(cur.OD_PB_DATE_APPROVED)||chr(10);
       v_text   :=v_text || 'Date Implemented  : '||TO_CHAR(cur.OD_PB_DATE_CORR_IMPL)||chr(10);
       v_text   :=v_text || 'Comments          : '||cur.OD_PB_COMMENTS||chr(10);
       v_text   :=v_text ||chr(10);	
        v_text   :=v_text ||chr(10);	
        v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';

       v_subject :='CAP/DS ID : '||cur.OD_OB_REF_CAPID||'/'||cur.OD_OB_DS_ID||' is Pending Verification';

       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_AUDITOR_NAME||':'||cur.OD_PB_QA_ENGR_EMAIL;
          v_cc_email_list:=null; -- Added by Kmaddala as part of QC # 21229
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
          v_cc_email_list:=null; -- Added by Kmaddala as part of QC # 21229
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

  	   UPDATE apps.qa_results  
              SET character16='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
   END LOOP;
   COMMIT;
   /* Calling below call to created a VN for a cap defect */
   xx_qa_vn_pkg.create_vn_from_def( x_errbuf  => v_errbuf
                                  , x_retcode => v_retcode
                                  ); 
								  
EXCEPTION
  WHEN OTHERS THEN
  COMMIT;
  v_errbuf:='Error in When others :'||SQLERRM;
  v_retcode:=SQLCODE;
END XX_CAP_PROCESS;
END XX_QA_CAP_PKG;
/
