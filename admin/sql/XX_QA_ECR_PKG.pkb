SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_ECR_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_ECR_PKG.pkb      	   	               |
-- | Description :  OD QA ECR Processing Pkg                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       14-May-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       21-Jul-2011 Paddy Sanjeevi     Removed email from CC     |
-- |1.2       15-Feb-2012 Paddy Sanjeevi     Modified for defect 16978 |
-- |1.3       12-OCT-2013 Kiran Maddala      Modified for defect 21229 |
-- +===================================================================+
AS


PROCEDURE XX_ECR_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS



 v_email_list    	VARCHAR2(3000);
 v_cc_email_list	VARCHAR2(3000):=NULL;
 v_director		VARCHAR2(150);
 v_text			VARCHAR2(32000);
 v_sku_info		VARCHAR2(32000);
 v_subject		VARCHAR2(3000);
 v_errbuf     		VARCHAR2(2000);
 v_retcode    		VARCHAR2(50);
 v_qa_esc     		VARCHAR2(50);
 v_instance		VARCHAR2(10);
 l_char22		VARCHAR2(150);         -- As per Ver 1.3
 l_char21		VARCHAR2(150);           -- As per Ver 1.3
 
 CURSOR C_ecr IS
 SELECT *
   FROM apps.q_od_ob_ecr_V
  WHERE last_update_date>sysdate-25;


 CURSOR C_ecr_sku(p_ecr_id VARCHAR2) IS
 SELECT *
   FROM apps.q_od_ob_ecr_sku_V
  WHERE od_ob_ref_ecr=p_ecr_id;


 CURSOR C_erstatus IS
 SELECT *
   FROM apps.q_od_ob_ecr_V
  WHERE od_pb_approval_status='Engineer Review'
    AND (SYSDATE-od_sc_req_audit_date)>1;
  --  AND NVL(od_ob_engr_ntfy,'N')='N';                 -- As per Ver 1.3

 CURSOR C_derstatus IS                               -- Cursor declared as per Ver 1.3                
 SELECT *
   FROM apps.q_od_ob_ecr_V
  WHERE od_pb_approval_status='Director Review'
    AND (SYSDATE-od_sc_req_audit_date)>1;

 BEGIN

   SELECT name INTO v_instance from v$database;

   BEGIN
   SELECT description
     INTO v_director
     FROM apps.fnd_flex_values_vl
    WHERE flex_value_set_id IN (SELECT flex_value_set_id
				  FROM apps.fnd_flex_value_sets
			         WHERE flex_value_set_name='XX_QA_RECIPIENTS') 
      AND flex_value='DIRECTOR'
      AND sysdate between nvl(start_date_active,sysdate) and nvl(end_date_active,sysdate);   
   EXCEPTION
     WHEN others THEN
       v_director:='Fritz.Lutzy@officedepot.com';
   END;


   FOR cur IN C_ecr LOOP

       v_sku_info:=NULL;	
       v_text:=NULL;

       FOR c IN C_ecr_sku(cur.od_pb_ecr_id) LOOP

	v_sku_info:=v_sku_info||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc;
        v_sku_info:=v_sku_info||chr(10);
        v_sku_info:=v_sku_info||chr(10);

       END LOOP;

       v_text   :=v_text || 'ECR ID             :'||cur.OD_PB_ECR_ID||chr(10);
       v_text   :=v_text || 'Vendor Name        :'||cur.OD_OB_VENDOR_NAME||chr(10);
       v_text   :=v_text || 'Factory Name       :'||cur.OD_SC_FACTORY_NAME||chr(10);
       v_text   :=v_text || 'Change Description :'||cur.OD_PB_CHANGE_DESC||chr(10);
       v_text   :=v_text || 'Approval Status    :'||cur.OD_PB_APPROVAL_STATUS||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || 'Department Name/SKU/SKU Description'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);

       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGINEER||':'||cur.OD_PB_QA_ENGR_EMAIL;
          v_cc_email_list:=NULL;  -- Added by kmaddala as part of QC 21229
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

       IF cur.od_pb_approval_status LIKE 'Engineer%' THEN
	  
	  v_subject:=cur.od_pb_ecr_id||' has been completed and uploaded to Oracle for your review';

          IF v_instance<>'GSIPRDGB' THEN
 
   	     v_subject:='Please Ignore this mail :'||v_subject;

          END IF;

	  IF NVL(cur.OD_OB_REQNAPR_NTFY,'X')<>'EY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character21='EY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

	  END IF;

       ELSIF cur.od_pb_approval_status LIKE 'In Test%' THEN

	  v_subject:=cur.od_pb_ecr_id||' is currently in testing';

          IF v_instance<>'GSIPRDGB' THEN
 
 	     v_subject:='Please Ignore this mail :'||v_subject;
 
          END IF;

	  IF NVL(cur.OD_OB_REQNAPR_NTFY,'X')<>'IY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character21='IY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

	  END IF;


       ELSIF cur.od_pb_approval_status LIKE 'Director%' THEN

	  v_subject:=cur.od_pb_ecr_id||' has been sent for QA Director Approval';

          IF lc_send_mail='Y' THEN
     	     v_cc_email_list:=v_director;
          END IF;

          IF v_instance<>'GSIPRDGB' THEN
 
	     v_subject:='Please Ignore this mail :'||v_subject;

          END IF;

	  IF NVL(cur.OD_OB_REQNAPR_NTFY,'X')<>'DY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character21='DY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

	  END IF;


       ELSIF cur.od_pb_approval_status LIKE 'APPROVED%' THEN

	  v_subject:=cur.od_pb_ecr_id||' has been Approved';

          IF lc_send_mail='Y' THEN
     	     v_cc_email_list:=v_director;
          END IF;

          IF v_instance<>'GSIPRDGB' THEN

   	     v_subject:='Please Ignore this mail :'||v_subject;

          END IF;

	  IF NVL(cur.OD_OB_REQNAPR_NTFY,'X')<>'AY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character21='AY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

	  END IF;


       ELSIF cur.od_pb_approval_status LIKE 'REJECTED%' THEN

	  v_subject:=cur.od_pb_ecr_id||' has been Rejected';

          IF v_instance<>'GSIPRDGB' THEN

	     v_subject:='Please Ignore this mail :'||v_subject;

          END IF;

          IF lc_send_mail='Y' THEN
     	     v_cc_email_list:=NULL;
          END IF;

	  IF NVL(cur.OD_OB_REQNAPR_NTFY,'X')<>'RY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character21='RY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

	  END IF;

       END IF;
   END LOOP;
   COMMIT;

   v_cc_email_list:=NULL;

   FOR cur IN C_erstatus LOOP

       v_sku_info:=NULL;	
       v_text:=NULL;

       FOR c IN C_ecr_sku(cur.od_pb_ecr_id) LOOP

	v_sku_info:=v_sku_info||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc||chr(10);

       END LOOP;

       v_text   :=v_text || 'ECR ID               :'||cur.OD_PB_ECR_ID||chr(10);
       v_text   :=v_text || 'Vendor Name          :'||cur.OD_OB_VENDOR_NAME||chr(10);
       v_text   :=v_text || 'Factory Name         :'||cur.OD_SC_FACTORY_NAME||chr(10);
       v_text   :=v_text || 'Change Description   :'||cur.OD_PB_CHANGE_DESC||chr(10);
       v_text   :=v_text || 'Approval Status      :'||cur.OD_PB_APPROVAL_STATUS||chr(10);
       v_text   :=v_text || 'Engineer Review Date :'||TO_CHAR(cur.od_sc_req_audit_date)||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || 'Department Name/SKU/SKU Description'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || 'Response is needed within 1 day or an escalation email will be sent';

       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

       v_subject:=cur.od_pb_ecr_id||' is in Engineer Review and has been pending for Approval';

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;
	
       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
       
       BEGIN      				-- As per Ver 1.3
          SELECT character22 INTO l_char22      -- As per Ver 1.3
            FROM  apps.qa_results  
           WHERE plan_id=cur.plan_id
       	     AND occurrence=cur.occurrence
   	     AND organization_id=cur.organization_id;
   	     
   	    IF  NVL(l_char22,'N') <> 'Y' THEN

       UPDATE apps.qa_results  
          SET character22='Y'
        WHERE plan_id=cur.plan_id
          AND occurrence=cur.occurrence
	  AND organization_id=cur.organization_id;
	  
	    END IF;	     	             -- As per Ver 1.3
       EXCEPTION                             -- As per Ver 1.3                  
          WHEN OTHERS THEN
	  NULL;
	END;

   END LOOP;
   COMMIT;
   
   -- Begin as per Ver 1.3
   
     FOR cur IN C_derstatus LOOP
   
          v_sku_info:=NULL;	
          v_text:=NULL;
   
          FOR c IN C_ecr_sku(cur.od_pb_ecr_id) LOOP
   
   	v_sku_info:=v_sku_info||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc||chr(10);
   
          END LOOP;
   
          v_text   :=v_text || 'ECR ID               :'||cur.OD_PB_ECR_ID||chr(10);
          v_text   :=v_text || 'Vendor Name          :'||cur.OD_OB_VENDOR_NAME||chr(10);
          v_text   :=v_text || 'Factory Name         :'||cur.OD_SC_FACTORY_NAME||chr(10);
          v_text   :=v_text || 'Change Description   :'||cur.OD_PB_CHANGE_DESC||chr(10);
          v_text   :=v_text || 'Approval Status      :'||cur.OD_PB_APPROVAL_STATUS||chr(10);
          v_text   :=v_text || 'Director Review Date :'||TO_CHAR(cur.od_sc_req_audit_date)||chr(10);
          v_text   :=v_text || chr(10);
          v_text   :=v_text || 'Department Name/SKU/SKU Description'||chr(10);
          v_text   :=v_text || chr(10);
          v_text   :=v_text || v_sku_info||chr(10);
          v_text   :=v_text || chr(10);
          v_text   :=v_text || chr(10);
          v_text   :=v_text || 'Response is needed within 1 day or an escalation email will be sent';
            
          IF lc_send_mail='Y' THEN
             v_email_list:=v_director;
          ELSE
             v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
          END IF;
   			
          v_subject:=cur.od_pb_ecr_id||' is in Director Review and has been pending for Approval';
   
          IF v_instance<>'GSIPRDGB' THEN
   
   	  v_subject:='Please Ignore this mail :'||v_subject;
   
          END IF;
   	
          xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
          
          BEGIN
           
            SELECT character21 INTO l_char21
             FROM  apps.qa_results  
             WHERE plan_id=cur.plan_id
	       AND occurrence=cur.occurrence
   	       AND organization_id=cur.organization_id;
          
          IF NVL(l_char21,'N') <> 'DY' THEN
   
          UPDATE apps.qa_results  
             SET character21='DY'
           WHERE plan_id=cur.plan_id
             AND occurrence=cur.occurrence
   	  AND organization_id=cur.organization_id;
   	  
   	  END IF;
   	  
   	EXCEPTION                                    
	  WHEN OTHERS THEN
	  NULL;
	END;
   
      END LOOP;
   COMMIT;
   -- End as per Ver 1.3
   
EXCEPTION
  WHEN others THEN
    COMMIT;
    v_errbuf:='Error in When others :'||SQLERRM;
    v_retcode:=SQLCODE;
END XX_ECR_PROCESS;
END XX_QA_ECR_PKG;
/
