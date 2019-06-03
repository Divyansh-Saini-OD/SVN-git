SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_PS_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_PS_PKG.pkb      	   	               |
-- | Description :  OD QA PS  Processing Pkg                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-May-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       25-Mar-2013 Saritha M          Modified for defect 21229 |
-- +===================================================================+
AS



PROCEDURE XX_PS_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS


   CURSOR c_ps_psrd IS
   SELECT *
     FROM apps.Q_OD_OB_PS_V a
    WHERE OD_PB_DATE_REQUESTED IS NOT NULL
      AND NVL(OD_OB_PSRD_NTFY,'N')='N';


   CURSOR c_sku(p_ps_id VARCHAR2) IS
   SELECT *
     FROM apps.Q_OD_OB_PS_SKU_V
    WHERE OD_OB_REF_PS_ID=p_ps_id
    ORDER BY od_ob_sku;


   CURSOR c_ps_naspsrd IS
   SELECT *
     FROM apps.Q_OD_OB_PS_V a
    WHERE OD_PB_DATE_REQUESTED IS NOT NULL
      AND OD_PB_APPROVAL_STATUS IS NULL
     -- AND NVL(OD_OB_NASPSRD_NTFY,'N')='N'     --Commented as per Ver 1.1
      AND (SYSDATE-OD_PB_DATE_REQUESTED)>7;

   CURSOR c_ps_aprsts IS
   SELECT *
     FROM apps.Q_OD_OB_PS_V a
    WHERE OD_PB_APPROVAL_STATUS IS NOT NULL;


   CURSOR c_ps_reqnapr IS
   SELECT *
     FROM apps.Q_OD_OB_PS_V a
    WHERE OD_PB_APPROVAL_STATUS='REQUEST'
      AND (SYSDATE-OD_SC_REQ_AUDIT_DATE)>1;
      --AND NVL(OD_OB_REQNAPR_NTFY,'N')='N';  --Commented as per Ver 1.1


   CURSOR c_ps_aprmpssd IS
   SELECT *
     FROM apps.Q_OD_OB_PS_V a
    WHERE OD_PB_APPROVAL_STATUS='APPROVED'
      AND (SYSDATE-OD_PB_DATE_APPROVED)>1
      AND OD_PB_DATE_REPORTED IS NULL;       
      --AND NVL(OD_OB_APRNPSSD_NTFY,'N')='N';    --Commented as per Ver 1.1

   CURSOR c_ps_pssd IS
   SELECT *
     FROM apps.Q_OD_OB_PS_V a
    WHERE OD_PB_DATE_REPORTED IS NOT NULL
      AND NVL(OD_OB_PSSD_NTFY,'N')='N';


 v_email_list    	VARCHAR2(3000);
 v_cc_email_list	VARCHAR2(3000);
 v_text			VARCHAR2(3000);
 v_subject		VARCHAR2(3000);
 v_errbuf     		VARCHAR2(2000);
 v_retcode    		VARCHAR2(50);
 v_instance   		VARCHAR2(10);
 v_sku_info		VARCHAR2(32000);
 l_char17		VARCHAR2(150);     -- As per Ver 1.1
 l_char19               VARCHAR2(150);     -- As per Ver 1.1
 l_char21		VARCHAR2(150);     -- As per Ver 1.1



 BEGIN

   SELECT name INTO v_instance FROM v$database;

   FOR cur IN c_ps_psrd LOOP

       v_sku_info:=NULL;	

       FOR c IN C_sku(cur.od_ob_ps_id) LOOP
			v_sku_info:=v_sku_info||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc||'/'||c.od_pb_vendor_vpc;
	v_sku_info:=v_sku_info||chr(10);

       END LOOP;

       v_text   :='PS ID :'||cur.OD_OB_PS_ID||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Below is the summary'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'PS Request Date     : '||to_char(cur.OD_PB_DATE_REQUESTED)||chr(10);
       v_text   :=v_text || 'Vendor Name	 : '||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Name        : '||cur.od_ob_factory_name||chr(10);
       v_text   :=v_text || 'Comments            : '||cur.od_pb_comments||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Department Name/SKU/SKU Description/VPC'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);

       v_subject :=cur.od_ob_ps_id||' has been requested to be completed and submitted';


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_AUDITOR_NAME||':'||cur.OD_PB_QA_ENGR_EMAIL;
--	  v_cc_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
--	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
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
   commit;

  FOR cur IN c_ps_naspsrd LOOP

       v_sku_info:=NULL;	

       FOR c IN C_sku(cur.od_ob_ps_id) LOOP
			v_sku_info:=v_sku_info||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc||'/'||c.od_pb_vendor_vpc;
	v_sku_info:=v_sku_info||chr(10);

       END LOOP;

       v_text   :='PS ID :'||cur.OD_OB_PS_ID||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Below is the summary'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'PS Request Date     : '||to_char(cur.OD_PB_DATE_REQUESTED)||chr(10);
       v_text   :=v_text || 'Vendor Name	 : '||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Name        : '||cur.od_ob_factory_name||chr(10);
       v_text   :=v_text || 'Approval Status     : '||cur.od_pb_approval_status||chr(10);
       v_text   :=v_text || 'Comments            : '||cur.od_pb_comments||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Department Name/SKU/SKU Description/VPC'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';

       v_subject :=cur.od_ob_ps_id||' Approval has been pending for more than 7 days';


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_AUDITOR_NAME; --||':'||cur.OD_PB_QA_ENGR_EMAIL; -- Commented as escalation mail should be received by submitter as per Ver 1.1
--	  v_cc_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
       
       BEGIN                                                  -- As per Ver 1.1
        SELECT  character17 INTO l_char17
          FROM  apps.qa_results
         WHERE   plan_id=cur.plan_id
           AND occurrence=cur.occurrence
	   AND organization_id=cur.organization_id;
	   
	   
	   IF  NVL(l_char17,'N') <> 'Y' THEN                           -- As per Ver 1.1
	   
  	   UPDATE apps.qa_results  
              SET character17='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
	    
	   END IF;
	  EXCEPTION                                           -- As per Ver 1.1
	  WHEN OTHERS THEN	  
	  NULL;
	  END;	      
   END LOOP;
   commit;

   FOR cur IN c_ps_aprsts LOOP

       v_sku_info:=NULL;	

       FOR c IN C_sku(cur.od_ob_ps_id) LOOP
			v_sku_info:=v_sku_info||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc||'/'||c.od_pb_vendor_vpc;

	v_sku_info:=v_sku_info||chr(10);

       END LOOP;

       IF cur.od_pb_approval_status='REQUEST' THEN

          v_text   :=cur.OD_OB_PS_ID||' has been submitted for Request'||chr(10);
	  v_subject:=cur.OD_OB_PS_ID||' has been submitted for Request';
   
       ELSIF cur.od_pb_approval_status='APPROVED' THEN

          v_text   :=cur.OD_OB_PS_ID||' has been Approved'||chr(10);
	  v_subject:=cur.OD_OB_PS_ID||' has been Approved';

       ELSIF cur.od_pb_approval_status='REJECTED' THEN

          v_text   :=cur.OD_OB_PS_ID||' has been Rejected'||chr(10);
	  v_subject:=cur.OD_OB_PS_ID||' has been Rejected'; 

       END IF;

       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Below is the summary'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'PS Request Date     : '||to_char(cur.OD_PB_DATE_REQUESTED)||chr(10);
       v_text   :=v_text || 'Vendor Name	 : '||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Name        : '||cur.od_ob_factory_name||chr(10);
       v_text   :=v_text || 'Approval Status     : '||cur.od_pb_approval_status||chr(10);
       v_text   :=v_text || 'Comments            : '||cur.od_pb_comments||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Department Name/SKU/SKU Description/VPC'||chr(10);
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
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
--	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       IF cur.od_pb_approval_status='REQUEST' AND  NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'QY' THEN

          xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

	  UPDATE apps.qa_results  
             SET character18='QY'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;

       END IF;

       IF cur.od_pb_approval_status='APPROVED' AND  NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'AY' THEN

          xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

	  UPDATE apps.qa_results  
             SET character18='AY'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;

       END IF;

       IF cur.od_pb_approval_status='REJECTED' AND  NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'RY' THEN

          xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

	  UPDATE apps.qa_results  
             SET character18='RY'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;

       END IF;

  END LOOP;
  COMMIT;


   FOR cur IN c_ps_reqnapr LOOP

       v_sku_info:=NULL;	

       FOR c IN C_sku(cur.od_ob_ps_id) LOOP
			v_sku_info:=v_sku_info||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc||'/'||c.od_pb_vendor_vpc;
	v_sku_info:=v_sku_info||chr(10);

       END LOOP;

       v_text   :='PS ID :'||cur.OD_OB_PS_ID||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Below is the summary'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'PS Request Date     : '||to_char(cur.OD_PB_DATE_REQUESTED)||chr(10);
       v_text   :=v_text || 'Vendor Name	 : '||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Name        : '||cur.od_ob_factory_name||chr(10);
       v_text   :=v_text || 'Approval Status     : '||cur.od_pb_approval_status||chr(10);
       v_text   :=v_text || 'Approval Requested  : '||to_char(cur.OD_SC_REQ_AUDIT_DATE)||chr(10);
       v_text   :=v_text || 'Comments            : '||cur.od_pb_comments||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Department Name/SKU/SKU Description/VPC'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';

       v_subject :=cur.od_ob_ps_id||' has been in Request Status for more than a day';


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGR_EMAIL ;--||':'||cur.OD_PB_AUDITOR_NAME; -- Commented as escalation mail should be received by Approver as per Ver 1.1
	--  v_cc_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
--	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
       
       BEGIN                                               -- As per Ver 1.1
        
         SELECT character19 INTO l_char19                   -- As per Ver 1.1
           FROM  apps.qa_results 
          WHERE  plan_id=cur.plan_id
            AND occurrence=cur.occurrence
	    AND organization_id=cur.organization_id;
	   
	 IF    NVL(l_char19,'N') <> 'Y' THEN                          -- As per Ver 1.1

  	   UPDATE apps.qa_results  
              SET character19='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
	  END IF;
	 
          EXCEPTION                                           -- As per Ver 1.1
 	  WHEN OTHERS THEN
 	  NULL;
	  END;	    
	  
	  
   END LOOP;
   commit;


   FOR cur IN c_ps_aprmpssd LOOP

       v_sku_info:=NULL;	

       FOR c IN C_sku(cur.od_ob_ps_id) LOOP
			v_sku_info:=v_sku_info||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc||'/'||c.od_pb_vendor_vpc;
	v_sku_info:=v_sku_info||chr(10);

       END LOOP;

       v_text   :='PS ID :'||cur.OD_OB_PS_ID||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Below is the summary'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'PS Request Date     : '||to_char(cur.OD_PB_DATE_REQUESTED)||chr(10);
       v_text   :=v_text || 'Vendor Name	 : '||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Name        : '||cur.od_ob_factory_name||chr(10);
       v_text   :=v_text || 'Approval Status     : '||cur.od_pb_approval_status||chr(10);
       v_text   :=v_text || 'Approval Date       : '||to_char(cur.OD_PB_DATE_APPROVED)||chr(10);
       v_text   :=v_text || 'Comments            : '||cur.od_pb_comments||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Department Name/SKU/SKU Description/VPC'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';


       v_subject :=cur.od_ob_ps_id||' has not been submitted for evaluation at 3rd Party ';


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGR_EMAIL ;--||':'||cur.OD_PB_AUDITOR_NAME; -- Commented as escalation mail should be received by Approver as per Ver 1.1
--	  v_cc_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
--	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
       
       BEGIN							 -- As per Ver 1.1								
          SELECT  character21 INTO l_char21                       -- As per Ver 1.1
            FROM  apps.qa_results
           WHERE plan_id=cur.plan_id
             AND occurrence=cur.occurrence
	     AND organization_id=cur.organization_id; 
	     
	  IF    NVL(l_char21,'N') <> 'Y' THEN                          -- As per Ver 1.1
  

  	   UPDATE apps.qa_results  
              SET character21='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
	   END IF;
	 
          EXCEPTION                                           -- As per Ver 1.1
 	  WHEN OTHERS THEN
 	  NULL;
	  END;	    
   END LOOP;
   commit;


   FOR cur IN c_ps_pssd LOOP

       v_sku_info:=NULL;	

       FOR c IN C_sku(cur.od_ob_ps_id) LOOP
			v_sku_info:=v_sku_info||c.od_pb_sc_dept_name||'/'||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc||'/'||c.od_pb_vendor_vpc;
	v_sku_info:=v_sku_info||chr(10);

       END LOOP;

       v_text   :='PS ID :'||cur.OD_OB_PS_ID||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'Below is the summary'||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'PS Request Date     : '||to_char(cur.OD_PB_DATE_REQUESTED)||chr(10);
       v_text   :=v_text || 'Vendor Name	 : '||cur.od_ob_vendor_name||chr(10);
       v_text   :=v_text || 'Factory Name        : '||cur.od_ob_factory_name||chr(10);
       v_text   :=v_text || 'Approval Status     : '||cur.od_pb_approval_status||chr(10);
       v_text   :=v_text || 'PS Submission Date  : '||to_char(cur.OD_PB_DATE_REPORTED)||chr(10);
       v_text   :=v_text || 'Comments            : '||cur.od_pb_comments||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text || 'Department Name/SKU/SKU Description/VPC'||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);

       v_subject :=cur.od_ob_ps_id||' has been submitted for evaluation at 3rd Party ';


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_AUDITOR_NAME||':'||cur.OD_PB_QA_ENGR_EMAIL;
--	  v_cc_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
--	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

  	   UPDATE apps.qa_results  
              SET character20='Y'
            WHERE plan_id=cur.plan_id
              AND occurrence=cur.occurrence
	      AND organization_id=cur.organization_id;
   END LOOP;
   commit;

EXCEPTION
  WHEN others THEN
  commit;
  v_errbuf:='Error in When others :'||SQLERRM;
  v_retcode:=SQLCODE;
END XX_PS_PROCESS;
END XX_QA_PS_PKG;
/
