SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_CC_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_CC_PKG.pkb      	   	               |
-- | Description :  OD QA Customer Complaints Processing Pkg           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       14-May-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       27-Sep-2012 Paddy Sanjeevi     Defect 20454              |
-- +===================================================================+
AS


PROCEDURE XX_QA_CC_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS


 v_errbuf     		VARCHAR2(2000);
 v_retcode    		VARCHAR2(50);
 v_email_list    	VARCHAR2(3000);
 v_cc_email_list	VARCHAR2(3000):=NULL;
 v_text			VARCHAR2(32000);
 v_subject		VARCHAR2(3000);
 v_instance		VARCHAR2(10);
 v_request_id 		NUMBER;
 v_crequest_id 		NUMBER;
 v_user_id		NUMBER:=fnd_global.user_id;
 v_phase		varchar2(100)   ;
 v_status		varchar2(100)   ;
 v_dphase		varchar2(100)	;
 v_dstatus		varchar2(100)	;
 x_dummy		varchar2(2000) 	;
 i			NUMBER:=0;
 v_error		VARCHAR2(2000);
 CURSOR c_get_cap IS
 SELECT a.plan_id,
   	a.collection_id,
	a.occurrence,
	a.organization_id,
	b.od_pb_car_id,
	a.OD_PB_CUSTOMER_COMPLAINT_ID,
	a.OD_PB_QA_ENGR_EMAIL,
	a.OD_PB_AUDITOR_NAME
  FROM  apps.q_od_ob_cap_v b,
	apps.Q_OD_OB_CUSTOMER_COMPLAINTS_V a
 WHERE  a.OD_PB_ROOT_CAUSE_TYPE='CAP'
   AND  a.OD_OB_REF_CAPID IS NULL
   AND  b.od_ob_qa_act='CC'
   AND  b.od_ob_qa_id=a.OD_PB_CUSTOMER_COMPLAINT_ID;

 CURSOR C_findings IS
 SELECT *
   FROM apps.Q_OD_OB_CUSTOMER_COMPLAINTS_V
  WHERE OD_PB_ROOT_CAUSE_TYPE='CAP'
    AND OD_OB_REF_CAPID IS NULL;

-- Added for following for defect 20454

CURSOR c_cc_to_capds
IS
SELECT a.plan_id,
       a.organization_id,
       a.occurrence,
       a.od_pb_defect_code,
       a.od_pb_defect_sum,
       a.od_ob_ref_capid cap_id,
       a.od_pb_customer_complaint_id,
       b.OD_OB_VENDOR_NAME,
       b.OD_SC_FACTORY_NAME,
       b.OD_PB_AUDITOR_NAME,
       b.OD_PB_QA_ENGR_EMAIL,
       b.OCCURRENCE cap_occurrence,
       b.COLLECTION_ID    
  FROM apps.q_od_ob_cap_v b,
       apps.Q_OD_OB_CUSTOMER_COMPLAINTS_V a
 WHERE a.od_ob_ref_capid IS NOT NULL
   AND b.od_pb_car_id=a.od_ob_ref_capid
   AND NOT EXISTS (SELECT 'x'
                     FROM apps.q_od_ob_cap_defects_v
                    WHERE OD_OB_REF_CAPID=b.OD_PB_CAR_ID
                      AND od_ob_qa_id=b.od_ob_qa_id
              AND od_pb_defect_sum=a.od_pb_defect_sum);

 BEGIN

   SELECT name INTO v_instance from v$database;

   FOR cur IN c_findings LOOP

    i:=i+1;
    BEGIN
      INSERT INTO apps.Q_OD_OB_CAP_IV
        (       process_status, 
                organization_code ,
                plan_name,
                insert_type,
	        matching_elements,
		OD_OB_QA_ID,
		OD_OB_QA_ACT,
		OD_OB_VENDOR_NAME,
		OD_SC_FACTORY_NAME,
		OD_SC_FACTORY_EMAIL,
		OD_SC_AUDIT_AGENT,
		OD_PB_AUDITOR_NAME,
		OD_PB_QA_ENGR_EMAIL,
		od_ob_sku,
	        OD_PB_ITEM_DESC,
		od_pb_sc_dept_name,		
		od_sc_region,
 	        qa_created_by_name,
                qa_last_updated_by_name
        )
      VALUES
	(
 	       '1',
               'PRJ',
               'OD_OB_CAP',
               '1', --1 for INSERT
               'OD_PB_CAR_ID,OD_OB_QA_ID,OD_OB_QA_ACT',
		cur.OD_PB_CUSTOMER_COMPLAINT_ID,
		'CC',
		cur.od_ob_vendor_name,
		cur.od_ob_factory_name,
		cur.od_sc_factory_email,
		cur.od_sc_audit_agent,
		cur.od_pb_auditor_name,
		cur.od_pb_qa_engr_email,				
		cur.od_ob_sku,
		cur.od_pb_item_desc,
		cur.OD_PB_SC_DEPT_NAME,
		cur.od_sc_region,
		fnd_global.user_name,
     	        fnd_global.user_name
	);
    EXCEPTION
      WHEN others THEN
	NULL;
    END;
  END LOOP;
  COMMIT;

   IF i>0 THEN
      v_request_id:=FND_REQUEST.SUBMIT_REQUEST('QA','QLTTRAMB','Collection Import Manager',NULL,FALSE,
		'200','1',TO_CHAR(V_user_id),'No');
       IF v_request_id>0 THEN
          COMMIT;
       END IF;

       IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

         IF v_dphase = 'COMPLETE' THEN
  
	    dbms_output.put_line('success');

         END IF;
       END IF;

       BEGIN
         SELECT request_id
           INTO v_crequest_id
	   FROM apps.fnd_concurrent_requests
  	  WHERE parent_request_id=v_request_id;
       EXCEPTION
         WHEN others THEN
	   v_crequest_id:=NULL;
       END;

       IF v_crequest_ID IS NOT NULL THEN
	
          IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_crequest_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

             IF v_dphase = 'COMPLETE' THEN
  
  	        dbms_output.put_line('success');

             END IF;
          END IF;

       END IF;

   END IF;
   COMMIT;

   FOR cur IN C_get_cap LOOP

    UPDATE qa_results
       SET character20=cur.od_pb_car_id
     WHERE plan_id=cur.plan_id
       AND collection_id=cur.collection_id
       AND occurrence=cur.occurrence;	

    IF SQL%FOUND THEN
       v_subject :='CAP Creation Notification for Customer Complaint :'||cur.OD_PB_CUSTOMER_COMPLAINT_ID;
       v_text:='A CAP is created for a Customer Complaint. Please see the details below'||chr(10);
       v_text:=v_text||chr(10);
       v_text:=v_text||'Complaint ID :'||cur.OD_PB_CUSTOMER_COMPLAINT_ID ||chr(10);
       v_text:=v_text||'CAP ID       :'||cur.od_pb_car_id||chr(10);

       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGR_EMAIL||':'||cur.OD_PB_AUDITOR_NAME;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
  	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;
       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

       UPDATE qa_results
          SET character24='Y'
        WHERE plan_id=cur.plan_id
          AND collection_id=cur.collection_id
          AND occurrence=cur.occurrence;	

    END IF;
   END LOOP;
   COMMIT;

   i:=0;

   -- Added for following for defect 20454 

   FOR cur IN c_cc_to_capds LOOP

     i:=i+1;
     v_error:=NULL;
     BEGIN
       INSERT INTO apps.Q_OD_OB_CAP_DEFECTS_IV
        (       process_status, 
                organization_code ,
                plan_name,
                insert_type,
	        matching_elements,
		od_ob_ref_capid,
		od_ob_qa_id,
		od_pb_defect_sum,
		OD_PB_LEGACY_OCR_ID,
		OD_PB_LEGACY_COL_ID,
		OD_SC_FACTORY_NAME,
		OD_PB_AUDITOR_NAME,
		OD_PB_QA_ENGR_EMAIL,
		OD_OB_VENDOR_NAME,
 	        qa_created_by_name,
                qa_last_updated_by_name
        )
       VALUES
	(
 	       '1',
               'PRJ',
               'OD_OB_CAP_DEFECTS',
               '1', --1 for INSERT
               'OD_OB_REF_CAPID,OD_OB_QA_ID,OD_OB_DS_ID',
		cur.cap_id,
	        cur.od_pb_customer_complaint_id,
		cur.od_pb_defect_sum,
		cur.cap_occurrence,
		cur.collection_id,
		cur.od_sc_factory_name,
		cur.od_pb_auditor_name,
		cur.od_pb_qa_engr_email,
		cur.od_ob_vendor_name,
		fnd_global.user_name,
     	        fnd_global.user_name
	);
     EXCEPTION
       WHEN others THEN
	 v_error:=sqlerrm;
  	 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Q_OD_OB_CAP_DEFECTS_IV '||v_error);
     END;

   END LOOP;

   IF i>0 THEN
      v_request_id:=FND_REQUEST.SUBMIT_REQUEST('QA','QLTTRAMB','Collection Import Manager',NULL,FALSE,
		'200','1',TO_CHAR(V_user_id),'No');
       IF v_request_id>0 THEN
          COMMIT;
       END IF;

       IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

         IF v_dphase = 'COMPLETE' THEN
  
	    dbms_output.put_line('success');

         END IF;
       END IF;

   END IF;
   COMMIT;
EXCEPTION
  WHEN others THEN
    COMMIT;
    v_errbuf:='Error in When others :'||SQLERRM;
    v_retcode:=SQLCODE;
END XX_QA_CC_PROCESS;
END XX_QA_CC_PKG;
/
