SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_FAI_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_FAI_PKG.pkb      	   	               |
-- | Description :  OD QA FAI Processing Pkg                           |
-- | RICE ID	 :  E2097		                               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-May-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       10-OCT-2013 Kiran Maddala	     Modified for Defect# 21229|
-- +===================================================================+
AS



PROCEDURE xx_create_fai_cap 
IS

CURSOR c_fai_to_cap 
IS
SELECT *
  FROM  apps.q_od_ob_fai_v a 
 WHERE  a.od_pb_cap_yn='Y'
   AND  a.OD_OB_REF_CAPID IS NULL
   AND  NOT EXISTS (SELECT 'x'
		      FROM apps.q_od_ob_cap_v
		     WHERE OD_OB_QA_ACT='FAI'
	               AND od_ob_qa_id=a.od_ob_fai_id
		       AND OD_PB_ITEM_DESC='CAP FOR MASTER FAI');

CURSOR c_faisku_to_cap 
IS
SELECT  a.od_ob_fai_id,
	a.od_ob_vendor_name,
	a.od_ob_factory_name,
	a.od_sc_factory_email,
	a.od_sc_region,
	a.od_sc_audit_agent,
	a.od_pb_auditor_name,
	a.od_pb_qa_engr_email,	
	b.OD_OB_SKU,
	b.OD_PB_ITEM_DESC,
	b.OD_PB_SC_DEPT_NAME
  FROM  apps.q_od_ob_fai_v a ,
	apps.Q_OD_OB_FAI_SKU_V b
 WHERE  b.od_pb_cap_yn='Y'
   AND  b.OD_OB_REF_CAPID IS NULL
   AND  a.OD_OB_FAI_ID=b.OD_OB_REF_REC_ID
   AND  NOT EXISTS (SELECT 'x'
		      FROM apps.q_od_ob_cap_v
		     WHERE OD_OB_QA_ACT='FAI'
	               AND od_ob_qa_id=b.od_ob_ref_rec_id
		       AND OD_OB_SKU=b.od_ob_sku);

CURSOR c_cap_upd
IS
SELECT  a.plan_id,
   	a.collection_id,
	a.occurrence,
	a.organization_id,
	b.od_pb_car_id,
	a.od_ob_fai_id,
	a.OD_PB_QA_ENGR_EMAIL,
	a.OD_PB_AUDITOR_NAME
  FROM  apps.q_od_ob_cap_v b,
	apps.q_od_ob_fai_v a
 WHERE  a.od_pb_cap_yn='Y'
   AND  a.OD_OB_REF_CAPID IS NULL
   AND  b.od_ob_qa_act='FAI'
   AND  b.od_ob_qa_id=a.od_ob_fai_id
   AND  b.OD_PB_ITEM_DESC='CAP FOR MASTER FAI';


CURSOR c_cap_updsku
IS
SELECT  a.plan_id,
   	a.collection_id,
	a.occurrence,
	a.organization_id,
	b.od_pb_car_id,
	c.od_ob_fai_id,
	c.OD_PB_QA_ENGR_EMAIL,
	c.OD_PB_AUDITOR_NAME,
	a.od_ob_sku,
	a.od_pb_item_desc
  FROM  apps.q_od_ob_cap_v b,
	apps.q_od_ob_fai_v c,
	apps.q_od_ob_fai_sku_v a
 WHERE  a.od_pb_cap_yn='Y'
   AND  a.OD_OB_REF_CAPID IS NULL
   AND  c.od_ob_fai_id=a.od_ob_ref_rec_id
   AND  b.od_ob_qa_act='FAI'
   AND  b.od_ob_qa_id=a.od_ob_ref_rec_id
   AND  b.OD_OB_SKU=a.od_ob_sku;


  v_request_id 		NUMBER;
  v_crequest_id 	NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
  i			NUMBER:=0;
  
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;
  v_text		VARCHAR2(6000);
  v_email_list    	VARCHAR2(3000);
  v_cc_email_list	VARCHAR2(3000);
  v_subject		VARCHAR2(3000);
  v_instance		VARCHAR2(10);
BEGIN

  SELECT name INTO v_instance from v$database;

  FOR cur IN c_fai_to_cap LOOP
	
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
	        OD_PB_ITEM_DESC,
		OD_SC_REGION,
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
		cur.od_ob_fai_id,
		'FAI',
		cur.od_ob_vendor_name,
		cur.od_ob_factory_name,
		cur.od_sc_factory_email,
		cur.od_sc_audit_agent,
		cur.od_pb_auditor_name,
		cur.od_pb_qa_engr_email,				
		'CAP FOR MASTER FAI',
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


  FOR cur IN c_faisku_to_cap LOOP
	
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
		cur.od_ob_fai_id,
		'FAI',
		cur.od_ob_vendor_name,
		cur.od_ob_factory_name,
		cur.od_sc_factory_email,
		cur.od_sc_audit_agent,
		cur.od_pb_auditor_name,
		cur.od_pb_qa_engr_email,				
		cur.od_ob_sku,
		cur.od_pb_item_desc,
		cur.od_pb_sc_dept_name,
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


  FOR cur IN c_cap_upd LOOP

    UPDATE qa_results
       SET character21=cur.od_pb_car_id
     WHERE plan_id=cur.plan_id
       AND collection_id=cur.collection_id
       AND occurrence=cur.occurrence;	

    IF SQL%FOUND THEN
       v_subject :='CAP Creation Notification for '||cur.od_ob_fai_id;
       v_text:='A CAP is created for the FAI. Please see the details below'||chr(10);
       v_text:=v_text||chr(10);
       v_text:=v_text||'FAI ID :'||cur.od_ob_fai_id ||chr(10);
       v_text:=v_text||'CAP ID :'||cur.od_pb_car_id||chr(10);
       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
  	  v_cc_email_list:=cur.OD_PB_AUDITOR_NAME;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com';
  	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;
       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
    END IF;
  END LOOP;
  COMMIT;



  FOR cur IN c_cap_updsku LOOP

    UPDATE qa_results
       SET character8=cur.od_pb_car_id
     WHERE plan_id=cur.plan_id
       AND collection_id=cur.collection_id
       AND occurrence=cur.occurrence;	

    IF SQL%FOUND THEN
       v_subject :='CAP Creation Notification for '||cur.od_ob_fai_id;
       v_text:='A CAP is created for the FAI/SKU. Please see the details below'||chr(10);
       v_text:=v_text||chr(10);
       v_text:=v_text||'CAP ID          :'||cur.od_pb_car_id||chr(10);
       v_text:=v_text||'FAI ID          :'||cur.od_ob_fai_id ||chr(10);
       v_text:=v_text||'SKU             :'||TO_CHAR(cur.od_ob_sku)||chr(10);
       v_text:=v_text||'SKU Description :'||cur.od_pb_item_desc||chr(10);

       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
  	  v_cc_email_list:=cur.OD_PB_AUDITOR_NAME;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com';
  	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;
       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
    END IF;
  END LOOP;
  COMMIT;

END xx_create_fai_cap;

PROCEDURE XX_FAI_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS


   CURSOR c_fai_mpsd IS
   SELECT *
     FROM apps.Q_OD_OB_FAI_V a
    WHERE OD_PB_DATE_PROPOSED_PRODUCTION IS NOT NULL
      AND NVL(OD_OB_MPSD_NTFY,'N')='N';

   CURSOR c_sku(p_fai_id VARCHAR2) IS
   SELECT *
     FROM apps.Q_OD_OB_FAI_SKU_V
    WHERE OD_OB_REF_REC_ID=p_fai_id
    ORDER BY od_ob_sku;
 

 CURSOR c_fai_pfd IS
   SELECT *
     FROM apps.Q_OD_OB_FAI_V a
    WHERE OD_SC_SCHEDULED_DATE IS NOT NULL
      AND NVL(OD_OB_PFD_NTFY,'N')='N';

   CURSOR c_fai_aprsts IS
   SELECT *
     FROM apps.Q_OD_OB_FAI_V a
    WHERE OD_PB_APPROVAL_STATUS IS NOT NULL;

   CURSOR c_noaprstatus IS
   SELECT *
     FROM apps.Q_OD_OB_FAI_V a
    WHERE OD_PB_APPROVAL_STATUS='REQUEST'
      --AND NVL(OD_OB_REQNAPR_NTFY,'N')='N'   -- As Per Ver 1.1 
      AND (SYSDATE-OD_SC_REQ_AUDIT_DATE)>1;

   CURSOR c_aprqfpd IS
   SELECT *
     FROM apps.Q_OD_OB_FAI_V a
    WHERE OD_PB_APPROVAL_STATUS IS NULL
      AND OD_SC_SCHEDULED_DATE IS NOT NULL
     -- AND NVL(OD_OB_APRQPFD_NTFY,'N')='N'  -- As Per Ver 1.1 
      AND (SYSDATE-OD_SC_SCHEDULED_DATE)>1;


 v_email_list    	VARCHAR2(3000);
 v_cc_email_list	VARCHAR2(3000);
 v_text			VARCHAR2(3000);
 v_subject		VARCHAR2(3000);
 v_errbuf     		VARCHAR2(2000);
 v_retcode    		VARCHAR2(50);
 v_instance   		VARCHAR2(10);
 v_sku_info		VARCHAR2(32000);
 l_character28          VARCHAR2(150);         -- As Per Ver 1.1 
 l_character29	        VARCHAR2(150);	       -- As Per Ver 1.1 	
 


 BEGIN

   SELECT name INTO v_instance FROM v$database;

   FOR cur IN c_fai_mpsd LOOP

       v_sku_info:=NULL;	

       FOR c IN C_sku(cur.od_ob_fai_id) LOOP
			v_sku_info:=v_sku_info||c.OD_PB_PROJ_NUM||'/'||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc;
	v_sku_info:=v_sku_info||chr(10);

       END LOOP;

       v_text   :=cur.OD_OB_FAI_ID||' has been scheduled'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Below is the summary'||chr(10);
       v_text   :=v_text || 'Project #   	 : '||cur.OD_PB_PROJ_NUM||chr(10);
       v_text   :=v_text || 'Vendor Name	 : '||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Name        : '||cur.od_ob_factory_name||chr(10);
       v_text   :=v_text || 'Mass Production Date: '||to_char(cur.OD_PB_DATE_PROPOSED_PRODUCTION)||chr(10);
       v_text   :=v_text || 'Comments            : '||cur.od_pb_comments||chr(10);

       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Sub Project #/Department Name/SKU/SKU Description'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);

       v_subject :='Mass Production has been scheduled for '||cur.od_ob_fai_id;


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_AUDITOR_NAME||':'||cur.OD_PB_QA_ENGR_EMAIL;
--	  v_cc_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
	  v_cc_email_list:= null;-- added by kmaddala as part of QC # 21229
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
--	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
	  v_cc_email_list:= null;-- added by kmaddala as part of QC # 21229
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

  	   UPDATE apps.qa_results  
              SET character25='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
   END LOOP;
   commit;



   FOR cur IN c_fai_pfd LOOP

       v_sku_info:=NULL;	

       FOR c IN C_sku(cur.od_ob_fai_id) LOOP
			v_sku_info:=v_sku_info||c.OD_PB_PROJ_NUM||'/'||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc;
	v_sku_info:=v_sku_info||chr(10);

       END LOOP;

       v_text   :=cur.OD_OB_FAI_ID||' has been scheduled'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || 'Below is the summary'||chr(10);
       v_text   :=v_text || 'Project #   	 : '||cur.OD_PB_PROJ_NUM||chr(10);
       v_text   :=v_text || 'Vendor Name	 : '||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Name        : '||cur.od_ob_factory_name||chr(10);
       v_text   :=v_text || 'Planned FAI Date    : '||to_char(cur.OD_SC_SCHEDULED_DATE)||chr(10);
       v_text   :=v_text || 'Comments            : '||cur.od_pb_comments||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || 'Sub Project #/Department Name/SKU/SKU Description'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);

       v_subject :='Planned FAI Date has been scheduled for '||cur.od_ob_fai_id;


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_AUDITOR_NAME||':'||cur.OD_PB_QA_ENGR_EMAIL;
--	  v_cc_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
	  v_cc_email_list:= null;-- added by kmaddala as part of QC # 21229
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
--	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
	  v_cc_email_list:= null;-- added by kmaddala as part of QC # 21229
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

  	   UPDATE apps.qa_results  
              SET character26='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
   END LOOP;
   commit;


   FOR cur IN c_fai_aprsts LOOP

       v_sku_info:=NULL;	

       FOR c IN C_sku(cur.od_ob_fai_id) LOOP
			v_sku_info:=v_sku_info||c.OD_PB_PROJ_NUM||'/'||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc;
	v_sku_info:=v_sku_info||chr(10);

       END LOOP;


       IF cur.od_pb_approval_status='REQUEST' THEN
       
       	  v_text   :=cur.OD_OB_FAI_ID||' has been submitted for Request'||chr(10);
          v_subject :=cur.od_ob_fai_id||' has been submitted for Request'; 
        
          
       ELSIF cur.od_pb_approval_status='APPROVED' THEN

          v_text   :=cur.OD_OB_FAI_ID||' has been Approved'||chr(10);
          v_subject :=cur.od_ob_fai_id||' has been Approved';
     
       ELSIF cur.od_pb_approval_status='REJECTED' THEN

          v_text   :=cur.OD_OB_FAI_ID||' has been Rejected'||chr(10);
          v_subject :=cur.od_ob_fai_id||' has been Rejected';
       END IF;


       v_text   :=v_text || chr(10);
       v_text   :=v_text || 'Below is the summary'||chr(10);
       v_text   :=v_text || 'Project #   	 : '||cur.OD_PB_PROJ_NUM||chr(10);
       v_text   :=v_text || 'Vendor Name	 : '||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Name        : '||cur.od_ob_factory_name||chr(10);
       v_text   :=v_text || 'Mass Production Date: '||to_char(cur.OD_PB_DATE_PROPOSED_PRODUCTION)||chr(10);
       v_text   :=v_text || 'Overall Audit Grade : '||cur.od_ob_audit_result||chr(10);
       v_text   :=v_text || 'Approval Status     : '||cur.od_pb_approval_status||chr(10);
       v_text   :=v_text || 'Comments            : '||cur.od_pb_comments||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || 'Sub Project #/Department Name/SKU/SKU Description'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);

       IF cur.od_pb_approval_status='REQUEST' THEN
          v_text   :=v_text ||chr(10);	
          v_text   :=v_text ||chr(10);	
          v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';
       END IF;



       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_AUDITOR_NAME||':'||cur.OD_PB_QA_ENGR_EMAIL;
--	  v_cc_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
	  v_cc_email_list:= null;-- added by kmaddala as part of QC # 21229
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
--	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
	  v_cc_email_list:= null;-- added by kmaddala as part of QC # 21229
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       IF cur.od_pb_approval_status='REQUEST' AND  NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'QY' THEN

          xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

	  UPDATE apps.qa_results  
             SET character27='QY'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;

       END IF;

       IF cur.od_pb_approval_status='APPROVED' AND  NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'AY' THEN

          xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

	  UPDATE apps.qa_results  
             SET character27='AY'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;

       END IF;

       IF cur.od_pb_approval_status='REJECTED' AND  NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'RY' THEN

          xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

	  UPDATE apps.qa_results  
             SET character27='RY'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;

       END IF;

  END LOOP;
  COMMIT;


  FOR cur IN c_noaprstatus LOOP

        v_sku_info:=NULL;	

       FOR c IN C_sku(cur.od_ob_fai_id) LOOP
			v_sku_info:=v_sku_info||c.OD_PB_PROJ_NUM||'/'||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc;
	v_sku_info:=v_sku_info||chr(10);

       END LOOP;

       v_text   :=cur.OD_OB_FAI_ID||' has been pending in Request for Approval'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Below is the summary'||chr(10);
       v_text   :=v_text || 'Project #   	   : '||cur.OD_PB_PROJ_NUM||chr(10);
       v_text   :=v_text || 'Vendor Name	   : '||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Name          : '||cur.od_ob_factory_name||chr(10);
       v_text   :=v_text || 'Mass Production Date  : '||to_char(cur.OD_PB_DATE_PROPOSED_PRODUCTION)||chr(10);
       v_text   :=v_text || 'Overall Audit Grade   : '||cur.od_ob_audit_result||chr(10);
       v_text   :=v_text || 'Approval Status       : '||cur.od_pb_approval_status||chr(10);
       v_text   :=v_text || 'Approval Request Date : '||TO_CHAR(cur.OD_SC_REQ_AUDIT_DATE)||chr(10);
       v_text   :=v_text || 'Comments              : '||cur.od_pb_comments||chr(10);

       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Sub Project #/Department Name/SKU/SKU Description'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';

       v_subject :=cur.od_ob_fai_id||' has been pending in Request for Approval';


       IF lc_send_mail='Y' THEN
        v_email_list:=cur.OD_PB_QA_ENGR_EMAIL;--cur.OD_PB_AUDITOR_NAME ; --||':'||cur.OD_PB_QA_ENGR_EMAIL;  -- Commented to send mail to Submitter as per Defect # 21229
--	  v_cc_email_list:=cur.OD_PB_QA_ENGR_EMAIL; 
	  v_cc_email_list:= null;-- added by kmaddala as part of QC # 21229
       ELSE
         v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
--	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';      
	  v_cc_email_list:= null;-- added by kmaddala as part of QC # 21229
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

  	    BEGIN                                          	  -- As Per Ver 1.1 
	     	  
	      SELECT character28 INTO l_character28        	  -- As Per Ver 1.1 
	        FROM apps.qa_results
	       WHERE plan_id=cur.plan_id
	         AND occurrence=cur.occurrence
	         AND organization_id=cur.organization_id; 
	   	    
	   IF NVL(l_character28,'N') <>  'Y' THEN 			   -- As Per Ver 1.1 
  	   
  	   UPDATE apps.qa_results  
              SET character28='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
	      
	   END IF;					          -- As Per Ver 1.1 
	    
	    EXCEPTION           			          -- As Per Ver 1.1 
  	     WHEN others THEN  
  	     NULL;
	   END;   
	      
	      
   END LOOP;
   commit;

   FOR cur IN c_aprqfpd LOOP

        v_sku_info:=NULL;	

       FOR c IN C_sku(cur.od_ob_fai_id) LOOP
			v_sku_info:=v_sku_info||c.OD_PB_PROJ_NUM||'/'||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc;
	v_sku_info:=v_sku_info||chr(10);

       END LOOP;

       v_text   :=cur.OD_OB_FAI_ID||' has not been requested for Approval'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Below is the summary'||chr(10);
       v_text   :=v_text || 'Project #   	 : '||cur.OD_PB_PROJ_NUM||chr(10);
       v_text   :=v_text || 'Vendor Name	 : '||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Name        : '||cur.od_ob_factory_name||chr(10);
       v_text   :=v_text || 'Mass Production Date: '||to_char(cur.OD_PB_DATE_PROPOSED_PRODUCTION)||chr(10);
       v_text   :=v_text || 'Planned FAI Date    : '||to_char(cur.OD_SC_SCHEDULED_DATE)||chr(10);
       v_text   :=v_text || 'Overall Audit Grade : '||cur.od_ob_audit_result||chr(10);
       v_text   :=v_text || 'Approval Status     : '||cur.od_pb_approval_status||chr(10);
       v_text   :=v_text || 'Comments            : '||cur.od_pb_comments||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Sub Project #/Department Name/SKU/SKU Description'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';

       v_subject :=cur.od_ob_fai_id||' has not been requested for Approval';


       IF lc_send_mail='Y' THEN
         v_email_list:=cur.OD_PB_AUDITOR_NAME ;--cur.OD_PB_QA_ENGR_EMAIL ; --||':'||cur.OD_PB_AUDITOR_NAME;    -- Commented to send mail to Approver as per Defect # 21229
--	  v_cc_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
	  v_cc_email_list:= null;-- added by kmaddala as part of QC # 21229
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
--	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
	  v_cc_email_list:= null;-- added by kmaddala as part of QC # 21229

       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

  	  BEGIN							-- As Per Ver 1.1 
  	  
  	  SELECT character29 into l_character29			-- As Per Ver 1.1 
  	   FROM apps.qa_results
  	  WHERE plan_id=cur.plan_id
            AND occurrence=cur.occurrence
	    AND organization_id=cur.organization_id; 
	    
	   IF NVL(l_character29,'N') <> 'Y' THEN 			-- As Per Ver 1.1 
  	  
  	  UPDATE apps.qa_results  
              SET character29='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
	     
	    END IF;						-- As Per Ver 1.1 
	    
	    EXCEPTION           				-- As Per Ver 1.1 
  	     WHEN others THEN  
  	     NULL;
	   END;  
	    
	    
   END LOOP;
   commit;
   xx_create_fai_cap;
   commit;
EXCEPTION
  WHEN others THEN
  commit;
  v_errbuf:='Error in When others :'||SQLERRM;
  v_retcode:=SQLCODE;
END XX_FAI_PROCESS;
END XX_QA_FAI_PKG;
/
