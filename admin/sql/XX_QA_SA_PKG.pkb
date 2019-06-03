SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_SA_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_SA_PKG.pkb      	   	               |
-- | Description :  OD QA SA  Processing Pkg                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       12-Aug-2011 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

PROCEDURE XX_SA_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS

 v_email_list    	VARCHAR2(3000);
 v_cc_email_list	VARCHAR2(3000):=NULL;
 v_text			VARCHAR2(32000);
 v_subject		VARCHAR2(3000);
 v_errbuf     		VARCHAR2(2000);
 v_retcode    		VARCHAR2(50);
 v_instance		VARCHAR2(10);


  -- Cursor to get sample approval records whose sample stage is not null

 CURSOR C_sa_status IS
 SELECT *
   FROM apps.Q_OD_OB_SAMPLE_APPROVAL_V
  WHERE OD_OB_SAMPLE_STAGE IS NOT NULL;

 BEGIN

   SELECT name INTO v_instance from v$database;

 
   FOR cur IN C_sa_status LOOP

       v_text:=NULL;

       v_text   :=v_text || 'Sample Approval ID  :'||cur.OD_OB_SA_ID||chr(10);
       v_text   :=v_text || 'Region              :'||cur.OD_SC_REGION||chr(10);
       v_text   :=v_text || 'Sourcing Agent      :'||cur.OD_SC_AUDIT_AGENT||chr(10);
       v_text   :=v_text || 'Merchant            :'||cur.OD_SC_MERCHANT||chr(10);
       v_text   :=v_text || 'Vendor Name         :'||cur.OD_OB_VENDOR_NAME||chr(10);
       v_text   :=v_text || 'Factory Name        :'||cur.OD_OB_FACTORY_NAME||chr(10);
       v_text   :=v_text || 'SKU                 :'||TO_CHAR(cur.OD_OB_SKU)||chr(10);
       v_text   :=v_text || 'SKU Description     :'||cur.OD_PB_ITEM_DESC||chr(10);
       v_text   :=v_text || 'Department Name     :'||cur.OD_PB_SC_DEPT_NAME||chr(10);
       v_text   :=v_text || 'Sample Stage        :'||cur.OD_OB_SAMPLE_STAGE||chr(10);
       v_text   :=v_text || 'Sample Sent Date    :'||TO_CHAR(cur.OD_PB_DATE_SAMPLE_SENT)||chr(10);
       v_text   :=v_text || 'Sample Status       :'||cur.OD_OB_SAMPLE_STATUS||chr(10);

       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_AUDITOR_NAME||':'||cur.OD_PB_QA_ENGR_EMAIL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

       IF cur.od_ob_sample_stage LIKE 'Initial%' THEN
	  
	  v_subject:=cur.od_ob_sa_id||' Sample is in Initial Stage';

          IF v_instance<>'GSIPRDGB' THEN
 
   	     v_subject:='Please Ignore this mail :'||v_subject;

          END IF;

	  IF NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'IY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character15='IY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

	  END IF;

       ELSIF cur.od_ob_sample_stage LIKE 'Development%' THEN

	  v_subject:=cur.od_ob_sa_id||' Sample is in Development Stage';

          IF v_instance<>'GSIPRDGB' THEN
 
 	     v_subject:='Please Ignore this mail :'||v_subject;
 
          END IF;

	  IF NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'DY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character15='DY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

	  END IF;


       ELSIF cur.od_ob_sample_stage LIKE 'Approved%' THEN

	  v_subject:=cur.od_ob_sa_id||' Sample is in Approved Stage';

          IF v_instance<>'GSIPRDGB' THEN
 
	     v_subject:='Please Ignore this mail :'||v_subject;

          END IF;

	  IF NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'AY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character15='AY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

	  END IF;


       ELSIF cur.od_ob_sample_stage LIKE 'Mass%' THEN

	  v_subject:=cur.od_ob_sa_id||' Sample is in Mass Production Stage';


          IF v_instance<>'GSIPRDGB' THEN

   	     v_subject:='Please Ignore this mail :'||v_subject;

          END IF;

	  IF NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'MY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character15='MY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

	  END IF;

       END IF;
   END LOOP;
   COMMIT;
EXCEPTION
  WHEN others THEN
    COMMIT;
    v_errbuf:='Error in When others :'||SQLERRM;
    v_retcode:=SQLCODE;
END XX_SA_PROCESS;
END XX_QA_SA_PKG;
/
