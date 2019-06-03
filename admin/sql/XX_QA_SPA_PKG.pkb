SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_SPA_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_SPA_PKG.pkb      	   	               |
-- | Description :  OD QA SPA Processing Pkg                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-May-2011 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

PROCEDURE XX_SPA_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS

CURSOR c_spa_to_cap 
IS
SELECT *
  FROM  apps.q_od_ob_spa_v a 
 WHERE  a.od_pb_cap_yn='Y'
   AND  a.OD_OB_REF_CAPID IS NULL
   AND  NOT EXISTS (SELECT 'x'
		      FROM apps.q_od_ob_cap_v
		     WHERE OD_OB_QA_ACT='SPA'
	               AND od_ob_qa_id=a.od_ob_spa_id);

CURSOR c_cap_upd
IS
SELECT  a.plan_id,
   	a.collection_id,
	a.occurrence,
	a.organization_id,
	a.od_ob_spa_id,
	a.OD_PB_QA_ENGR_EMAIL,
	a.OD_PB_AUDITOR_NAME,
	a.OD_OB_INSPECTOR,
	a.OD_PB_COMPANY,
	a.OD_PB_SERVICE_LOCATION,
	a.OD_PB_AUDIT_TYPE,
	a.OD_OB_VENDOR_NAME,
	a.OD_OB_FACTORY_NAME,
	a.OD_OB_SKU,
	a.OD_PB_ITEM_DESC,
	a.OD_PB_SC_DEPT_NAME,
	a.OD_PB_CASE_NUMBER,
	b.od_pb_car_id
  FROM  apps.q_od_ob_cap_v b,
	apps.q_od_ob_spa_v a
 WHERE  a.od_pb_cap_yn='Y'
   AND  a.OD_OB_REF_CAPID IS NULL
   AND  b.od_ob_qa_act='SPA'
   AND  b.od_ob_qa_id=a.od_ob_spa_id;


CURSOR c_cap_cmpl
IS
SELECT  a.plan_id,
   	a.collection_id,
	a.occurrence,
	a.organization_id,
	b.od_pb_date_approved
  FROM  apps.q_od_ob_cap_v b,
	apps.q_od_ob_spa_v a
 WHERE  a.od_pb_cap_yn='Y'
   AND  a.OD_OB_REF_CAPID IS NOT NULL
   AND  b.od_ob_qa_act='SPA'
   AND  b.od_ob_qa_id=a.od_ob_spa_id
   AND  b.OD_PB_DATE_APPROVED IS NOT NULL;


  v_email_list    	VARCHAR2(3000);
  v_cc_email_list	VARCHAR2(3000);
  v_text		VARCHAR2(6000);
  v_subject		VARCHAR2(3000);
  v_errbuf     		VARCHAR2(2000);
  v_retcode    		VARCHAR2(50);
  v_instance   		VARCHAR2(10);


  v_request_id 		NUMBER;
  v_crequest_id 	NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
  i			NUMBER:=0;
  
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;


 BEGIN

   SELECT name INTO v_instance FROM v$database;

   FOR cur IN c_spa_to_cap LOOP
	
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
		OD_OB_SKU,
	        OD_PB_ITEM_DESC,
		OD_SC_REGION,
		od_pb_tech_rpt_num,
		od_pb_sc_dept_name,
		od_pb_vendor_vpc,
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
		cur.od_ob_spa_id,
		'SPA',
		cur.od_ob_vendor_name,
		cur.od_ob_factory_name,
		cur.OD_PB_CONTACT_EMAIL,
		cur.OD_SC_AUDIT_AGENT,
		cur.od_pb_auditor_name,
		cur.od_pb_qa_engr_email,				
		cur.od_ob_sku,
		cur.od_pb_item_desc,
		cur.od_sc_region,
		cur.od_pb_case_number,
		cur.od_pb_sc_dept_name,
		cur.od_pb_vendor_vpc,
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


  FOR cur IN c_cap_upd LOOP

    UPDATE qa_results
       SET character27=cur.od_pb_car_id
     WHERE plan_id=cur.plan_id
       AND collection_id=cur.collection_id
       AND occurrence=cur.occurrence;	

    IF SQL%FOUND THEN

       v_subject :='CAP Creation Notification for '||cur.od_ob_spa_id;
       v_text:='A CAP is created for the SPA. Please see the details below'||chr(10);
       v_text:=v_text||chr(10);
       v_text:=v_text||'SPA ID          :'||cur.od_ob_spa_id ||chr(10);
       v_text:=v_text||'CAP ID          :'||cur.od_pb_car_id||chr(10);
       v_text:=v_text||chr(10);
       v_text:=v_text||'Audit Type      :'||cur.od_pb_audit_type||chr(10);
       v_text:=v_text||'SP Name         :'||cur.od_pb_company||chr(10);
       v_text:=v_text||'SP Location     :'||cur.od_pb_service_location||chr(10);
       v_text:=v_text||'Reference #     :'||cur.od_pb_case_number||chr(10);
       v_text:=v_text||'Inspector       :'||cur.od_ob_inspector||chr(10);
       v_text:=v_text||'Vendor Name     :'||cur.od_ob_vendor_name||chr(10);
       v_text:=v_text||'Factory Name    :'||cur.od_ob_factory_name||chr(10);
       v_text:=v_text||'SKU             :'||TO_CHAR(cur.od_ob_sku)||chr(10);
       v_text:=v_text||'SKU Description :'||cur.od_pb_item_desc||chr(10);
       v_text:=v_text||'Department Name :'||cur.od_pb_sc_dept_name||chr(10);

       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGR_EMAIL||':'||cur.OD_PB_AUDITOR_NAME;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;
       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
    END IF;
  END LOOP;
  COMMIT;

  FOR cur IN c_cap_cmpl LOOP

    UPDATE qa_results
       SET character28=TO_CHAR(cur.od_pb_date_approved,'YYYY/MM/DD')
     WHERE plan_id=cur.plan_id
       AND collection_id=cur.collection_id
       AND occurrence=cur.occurrence;	

  END LOOP;
  COMMIT; 	
EXCEPTION
  WHEN others THEN
  commit;
  v_errbuf:='Error in When others :'||SQLERRM;
  v_retcode:=SQLCODE;
END XX_SPA_PROCESS;
END XX_QA_SPA_PKG;
/
