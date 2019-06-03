SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_FQA_PKG
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
-- |1.0       11-May-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       21-Jul-2011 Paddy Sanjeevi     Modified email message    | 
-- |1.2       25-Feb-2013 Saritha Mummaneni  Modified for Defect 21229 |
-- +===================================================================+
AS


PROCEDURE SEND_NOTIFICATION( p_subject IN VARCHAR2
                ,p_email_list IN VARCHAR2
                ,p_cc_email_list IN VARCHAR2
                ,p_text IN VARCHAR2 )
IS
  lc_mailhost    VARCHAR2(64) := FND_PROFILE.VALUE('XX_PA_PB_MAIL_HOST');
  lc_from        VARCHAR2(64) := 'OD-OB-QualityTeam@officedepot.com';
  l_mail_conn    UTL_SMTP.connection;
  lc_to          VARCHAR2(2000);
  lc_cc          VARCHAR2(2000);
  lc_to_all      VARCHAR2(2000) := p_email_list ;
  lc_cc_all      VARCHAR2(2000) := p_cc_email_list ;
  i              BINARY_INTEGER;
  j              BINARY_INTEGER;
  TYPE T_V100 IS TABLE OF VARCHAR2(100)  INDEX BY BINARY_INTEGER;
  lc_to_tbl      T_V100;
  lc_cc_tbl      T_V100;
  
  
  crlf VARCHAR2 (10) := UTL_TCP.crlf; 
BEGIN
  -- If setup data is missing then return

  IF lc_mailhost IS NULL OR lc_to_all IS NULL THEN
      RETURN;
  END IF;

  l_mail_conn := UTL_SMTP.open_connection(lc_mailhost, 25);
  UTL_SMTP.helo(l_mail_conn, lc_mailhost);
  UTL_SMTP.mail(l_mail_conn, lc_from);

  -- Check how many recipients are present in lc_to_all

  i := 1;
  LOOP
      lc_to := SUBSTR(lc_to_all,1,INSTR(lc_to_all,':') - 1);
      IF lc_to IS NULL OR i = 20 THEN
          lc_to_tbl(i) := lc_to_all;
          UTL_SMTP.rcpt(l_mail_conn, lc_to_all);
          EXIT;
      END IF;
      lc_to_tbl(i) := lc_to;
      UTL_SMTP.rcpt(l_mail_conn, lc_to);
      lc_to_all := SUBSTR(lc_to_all,INSTR(lc_to_all,':') + 1);
      i := i + 1;
  END LOOP;

 IF lc_cc_all IS NOT NULL
 THEN
 
  j := 1;
  LOOP
      lc_cc := SUBSTR(lc_cc_all,1,INSTR(lc_cc_all,':') - 1);
      IF lc_cc IS NULL OR j = 20 THEN
          lc_cc_tbl(j) := lc_cc_all;
          UTL_SMTP.rcpt(l_mail_conn, lc_cc_all);
          EXIT;
      END IF;
      lc_cc_tbl(j) := lc_cc;
      UTL_SMTP.rcpt(l_mail_conn, lc_cc);
      lc_cc_all := SUBSTR(lc_cc_all,INSTR(lc_cc_all,':') + 1);
      j := j + 1;
  END LOOP;

 END IF;


  UTL_SMTP.open_data(l_mail_conn);

  UTL_SMTP.write_data(l_mail_conn, 'Date: '    || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'From: '    || lc_from || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || p_subject || Chr(13));

  --UTL_SMTP.write_data(l_mail_conn, Chr(13));

  -- Checl all recipients

  FOR i IN 1..lc_to_tbl.COUNT LOOP

      UTL_SMTP.write_data(l_mail_conn, 'To: '      || lc_to_tbl(i) || Chr(13));

  END LOOP;
  
 IF lc_cc_all IS NOT NULL
 THEN
  FOR j IN 1..lc_cc_tbl.COUNT LOOP

      UTL_SMTP.write_data(l_mail_conn, 'Cc: '      || lc_cc_tbl(j) || Chr(13));

  END LOOP;
 END IF;
  UTL_SMTP.write_data (l_mail_conn, ' ' || crlf); 
  UTL_SMTP.write_data(l_mail_conn, p_text||crlf);
  UTL_SMTP.write_data (l_mail_conn, ' ' || crlf); 
  UTL_SMTP.close_data(l_mail_conn);
  UTL_SMTP.quit(l_mail_conn);
EXCEPTION
    WHEN OTHERS THEN
    NULL;
END SEND_NOTIFICATION;

FUNCTION IS_APPROVER_VALID(p_plan IN VARCHAR2) 
RETURN VARCHAR2
IS
v_cnt NUMBER:=0;
v_return VARCHAR2(1):='Y';

BEGIN
 SELECT COUNT(1)
   INTO v_cnt           
   FROM apps.qa_chars f,                
        apps.qa_plan_char_value_lookups a    ,        
	apps.qa_plans b        
  WHERE b.name=p_plan
    AND a.plan_id=b.plan_id        
    AND f.name='OD_PB_QA_ENGR_EMAIL'        
    AND f.char_id=a.char_id     
    AND a.description=fnd_global.user_name;
  IF v_cnt=0 THEN
     v_return:='N';
  ELSE
     v_return:='Y';
  END IF;
  RETURN v_return;
EXCEPTION
  WHEN others THEN
    RETURN v_return;
END IS_APPROVER_VALID;

PROCEDURE xx_create_cap 
IS

CURSOR c_fqa_to_cap 
IS
SELECT  a.plan_id,
   	a.collection_id,
	a.occurrence,
	a.organization_id,
	a.od_fqa_id,
	a.od_sc_vendor_number,
	a.od_sc_region,
	a.od_ob_vendor_name,
	a.od_ob_factory_number,
	a.od_sc_factory_name,
	a.od_sc_factory_email,
	a.od_sc_audit_agent,
	a.od_pb_auditor_name,
	a.od_pb_qa_engr_email
  FROM  apps.q_od_ob_fqa_v a 
 WHERE  a.od_pb_cap_yn='Y'
   AND  a.od_fqa_cap_id IS NULL
   AND  NOT EXISTS (SELECT 'x'
		      FROM apps.q_od_ob_cap_v
		     WHERE OD_OB_QA_ACT='FQA'
	               AND od_ob_qa_id=a.od_fqa_id);

CURSOR c_cap_upd
IS
SELECT  a.plan_id,
   	a.collection_id,
	a.occurrence,
	a.organization_id,
	b.od_pb_car_id,
	a.od_fqa_id,
	a.OD_PB_QA_ENGR_EMAIL,
	a.OD_PB_AUDITOR_NAME
  FROM  apps.q_od_ob_cap_v b,
	apps.q_od_ob_fqa_v a
 WHERE  a.od_pb_cap_yn='Y'
   AND  a.od_fqa_cap_id IS NULL
   AND  b.od_ob_qa_act='FQA'
   AND  b.od_ob_qa_id=a.od_fqa_id;


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

  FOR cur IN c_fqa_to_cap LOOP
	
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
		OD_SC_VENDOR_NUMBER,
		od_sc_region,
		OD_OB_VENDOR_NAME,
		OD_OB_FACTORY_NUMBER,
		OD_SC_FACTORY_NAME,
		OD_SC_FACTORY_EMAIL,
		OD_SC_AUDIT_AGENT,
		OD_PB_AUDITOR_NAME,
		OD_PB_QA_ENGR_EMAIL,
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
		cur.od_fqa_id,
		'FQA',
		cur.od_sc_vendor_number,
		cur.od_sc_region,
		cur.od_ob_vendor_name,
		cur.od_ob_factory_number,
		cur.od_sc_factory_name,
		cur.od_sc_factory_email,
		cur.od_sc_audit_agent,
		cur.od_pb_auditor_name,
		cur.od_pb_qa_engr_email,				
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
       SET character28=cur.od_pb_car_id
     WHERE plan_id=cur.plan_id
       AND collection_id=cur.collection_id
       AND occurrence=cur.occurrence;	

    IF SQL%FOUND THEN
       v_subject :='CAP Creation Notification for '||cur.od_fqa_id;
       v_text:='A CAP is created for the FQA. Please see the details below'||chr(10);
       v_text:=v_text||chr(10);
       v_text:=v_text||'FQA ID :'||cur.od_fqa_id ||chr(10);
       v_text:=v_text||'CAP ID :'||cur.od_pb_car_id||chr(10);
       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGR_EMAIL||':'||cur.OD_PB_AUDITOR_NAME;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;
       SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
    END IF;
  END LOOP;
  COMMIT;
END xx_create_cap;

PROCEDURE XX_FQA_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS


   CURSOR c_fqa_asgnd IS
   SELECT *
     FROM apps.Q_OD_OB_FQA_V a
    WHERE OD_PB_FQA_REQ_D IS NOT NULL
      AND OD_PB_FQA_ASSIGNED_DATE IS NULL
      --AND NVL(OD_FQA_ASSIGN_NTFY,'N')='N'  -- As per Ver 1.2
      AND (SYSDATE-OD_PB_FQA_REQ_D)>3;

   CURSOR c_reaudit IS
   SELECT *
     FROM apps.Q_OD_OB_FQA_V a
    WHERE OD_PB_FQA_REAUDIT_D IS NOT NULL
      AND NVL(OD_FQA_REAUDT_NTFY,'N')='N'
      AND (OD_PB_FQA_REAUDIT_D-SYSDATE)<7;

   CURSOR c_nostatus IS
   SELECT *
     FROM apps.Q_OD_OB_FQA_V a
    WHERE OD_PB_APPROVAL_STATUS IS NULL
      AND OD_PB_AUDIT_DATE IS NOT NULL
    --  AND NVL(OD_FQA_APRFAD_NTFY,'N')='N'   -- As per Ver 1.2
      AND (SYSDATE-OD_PB_AUDIT_DATE)>3;

   CURSOR c_noaprstatus IS
   SELECT *
     FROM apps.Q_OD_OB_FQA_V a
    WHERE OD_PB_APPROVAL_STATUS='REQUEST'
     -- AND NVL(OD_FQA_APRREQ_NTFY,'N')='N'  -- As per Ver 1.2
      AND (SYSDATE-OD_SC_REQ_AUDIT_DATE)>3;

 conn 			utl_smtp.connection;
 v_email_list    	VARCHAR2(3000);
 v_cc_email_list	VARCHAR2(3000);
 v_text			VARCHAR2(3000);
 v_subject		VARCHAR2(3000);
 v_region_contact  	varchar2(250);
 v_region		varchar2(50);
 v_nextaudit_date	date;
 v_errbuf     VARCHAR2(2000);
 v_retcode    VARCHAR2(50);
 v_fqa_esc    VARCHAR2(150);
 v_instance   VARCHAR2(10);
 l_character33  VARCHAR2(150);    --  As Per Ver 1.2
 l_character34  VARCHAR2(150);    --  As Per Ver 1.2
 l_character35  VARCHAR2(150);    --  As Per Ver 1.2
 BEGIN

   SELECT name INTO v_instance FROM v$database;

   SELECT description
     INTO v_fqa_esc
     FROM apps.fnd_flex_values_vl
    WHERE flex_value_set_id IN (SELECT flex_value_set_id
				  FROM apps.fnd_flex_value_sets
			         WHERE flex_value_set_name='XX_QA_RECIPIENTS') 
      AND flex_value='FQA'
      AND sysdate between nvl(start_date_active,sysdate) and nvl(end_date_active,sysdate);   


   FOR cur IN c_fqa_asgnd LOOP

       v_text	:='FQA Assignment Date is Pending for the vendor/Factory '||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Vendor Number/Name	 : '||cur.od_sc_vendor_number||'/'||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Number/Name : '||cur.OD_OB_FACTORY_NUMBER||'/'||cur.od_sc_factory_name||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Requested Date      : '||to_char(cur.OD_PB_FQA_REQ_D)||chr(10);
       v_text   :=v_text || 'FQA ID              : '||cur.OD_FQA_ID;		
       v_subject :='FQA Assignment Date is Pending for '||cur.od_ob_vendor_name||'/'||cur.od_sc_factory_name;
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';

       IF lc_send_mail='Y' THEN
          v_email_list:=v_fqa_esc;          
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

          BEGIN							 --  As Per Ver 1.2
          
          SELECT character33 INTO l_character33			  --  As Per Ver 1.2
            FROM apps.qa_results  
           WHERE plan_id=cur.plan_id
             AND occurrence=cur.occurrence
	     AND organization_id=cur.organization_id; 

           IF NVL(l_character33,'N') <> 'Y' THEN			 --  As Per Ver 1.2
  	   UPDATE apps.qa_results  
              SET character33='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
	   END IF;						 --  As Per Ver 1.2
	   
	   EXCEPTION						 --  As Per Ver 1.2
	   WHEN OTHERS THEN
	   NULL;
	   END;
	   
	   
   END LOOP;
   commit;


   FOR cur IN c_reaudit LOOP

       v_text	:='FQA Reaudit has been scheduled for the vendor/Factory '||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Vendor Number/Name	 :'||cur.od_sc_vendor_number||'/'||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Number/Name :'||cur.OD_OB_FACTORY_NUMBER||'/'||cur.od_sc_factory_name||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Reaudit Date        :'||to_char(cur.OD_PB_FQA_REAUDIT_D)||chr(10);
       v_text   :=v_text || 'FQA ID              : '||cur.OD_FQA_ID;				
       v_subject :='FQA Reaudit request for '||cur.od_ob_vendor_name||'/'||cur.od_sc_factory_name;


       IF lc_send_mail='Y' THEN
          v_email_list:=v_fqa_esc;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

  	   UPDATE apps.qa_results  
              SET character36='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
   END LOOP;
   COMMIT;


   FOR cur IN c_nostatus LOOP

       v_text	:='FQA Approval Status is pending for the vendor/Factory '||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Vendor Number/Name	 :'||cur.od_sc_vendor_number||'/'||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Number/Name :'||cur.OD_OB_FACTORY_NUMBER||'/'||cur.od_sc_factory_name||chr(10);
       v_text   :=v_text || 'FQA Audit Date      :'||to_char(cur.OD_PB_AUDIT_DATE) ||chr(10);
       v_text   :=v_text || 'FQA ID              : '||cur.OD_FQA_ID;				
		
       v_subject :='FQA Approval Status is Pending for '||cur.od_ob_vendor_name||'/'||cur.od_sc_factory_name;

       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_AUDITOR_NAME;          
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
           
         BEGIN							--  As Per Ver 1.2
           
           SELECT character34 INTO l_character34		--  As Per Ver 1.2
             FROM apps.qa_results  
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;    
           
           IF NVL(l_character34,'N') <> 'Y' THEN			--  As Per Ver 1.2
           
           
  	   UPDATE apps.qa_results  
              SET character34='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
	    END IF;						--  As Per Ver 1.2
	    
	    EXCEPTION						 --  As Per Ver 1.2
	     WHEN OTHERS THEN
	     NULL;
	  END;
	    
   END LOOP;
   commit;

   FOR cur IN c_noaprstatus LOOP

       v_text	:='FQA Approval is in REQUEST Status for the vendor/Factory '||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Vendor Number/Name	       :'||cur.od_sc_vendor_number||'/'||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Number/Name       :'||cur.OD_OB_FACTORY_NUMBER||'/'||cur.od_sc_factory_name||chr(10);
       v_text   :=v_text || 'FQA Approval Request Date :'||to_char(cur.OD_SC_REQ_AUDIT_DATE)||chr(10);
       v_text   :=v_text || 'FQA ID                    : '||cur.OD_FQA_ID;				
		
       v_subject :='FQA Approval is in REQUEST Status for '||cur.od_ob_vendor_name||'/'||cur.od_sc_factory_name;
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';


       IF lc_send_mail='Y' THEN
         v_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

        BEGIN							 --  As Per Ver 1.2
           
           SELECT character35 INTO l_character35		 --  As Per Ver 1.2	
             FROM apps.qa_results 
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id; 
	      
	   IF NVL(l_character35,'N')  <> 'Y' THEN                         --  As Per Ver 1.2
        
  	   UPDATE apps.qa_results  
              SET character35='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
	     
	   END IF;					         --  As Per Ver 1.2
	   
	 EXCEPTION						 --  As Per Ver 1.2
	     WHEN OTHERS THEN
	     NULL;
	 END;							  --  As Per Ver 1.2
   END LOOP;
   commit;
   xx_create_cap;
   commit;
EXCEPTION
  WHEN others THEN
  commit;
  v_errbuf:='Error in When others :'||SQLERRM;
  v_retcode:=SQLCODE;
END XX_FQA_PROCESS;
END XX_QA_FQA_PKG;
/
