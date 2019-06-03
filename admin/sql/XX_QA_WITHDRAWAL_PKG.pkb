SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_WITHDRAWAL_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_WITHDRAWAL_PKG.pkb      	   	       |
-- | Description :  OD QA WITHDRAWAL Processing Pkg                    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       08-Jul-2011 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS


PROCEDURE XX_QA_WITHDRAWAL_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS



 v_email_list    	VARCHAR2(3000);
 v_cc_email_list	VARCHAR2(3000):=NULL;
 v_text			VARCHAR2(32000);
 v_sku_info		VARCHAR2(32000);
 v_subject		VARCHAR2(3000);
 v_errbuf     		VARCHAR2(2000);
 v_retcode    		VARCHAR2(50);
 v_qa_esc     		VARCHAR2(50);
 v_instance		VARCHAR2(10);

 v_lsdate		DATE;
 v_sdate		DATE;
 v_cpid	 		NUMBER;
 v_cpaid	 	NUMBER;


 CURSOR C_wd IS
 SELECT *
   FROM apps.Q_OD_OB_WITHDRAWAL_V
  WHERE OD_OB_WITHDRAWAL_STATUS IS NOT NULL;


 CURSOR C_wd_sku(p_wd_id VARCHAR2) IS
 SELECT *
   FROM apps.q_od_ob_wd_sku_V
  WHERE OD_OB_REF_WD_ID=p_wd_id;

 BEGIN

   SELECT name INTO v_instance from v$database;

   FOR cur IN C_wd LOOP

       v_text		:=NULL;
       v_sku_info	:=NULL;	

       FOR c IN C_wd_sku(cur.od_ob_withdrawal_id) LOOP

	v_sku_info:=v_sku_info||TO_CHAR(c.od_ob_sku)||'/'||c.od_pb_item_desc||chr(10);

       END LOOP;


       v_text   :=v_text || 'Withdrawal Id        :'||cur.OD_OB_WITHDRAWAL_ID||chr(10);
       v_text   :=v_text || 'Vendor Name          :'||cur.OD_OB_VENDOR_NAME||chr(10);
       v_text   :=v_text || 'Factory Name         :'||cur.OD_OB_FACTORY_NAME||chr(10);
       v_text   :=v_text || 'Region               :'||cur.OD_SC_REGION||chr(10);
       v_text   :=v_text || 'Withdrawal Type      :'||cur.OD_OB_WITHDRAWAL_TYPE||chr(10);
       v_text   :=v_text || 'Summary              :'||cur.OD_PB_DEFECT_SUM||chr(10);
       v_text   :=v_text || 'Paid By              :'||cur.OD_PB_ENTITY||chr(10);
       v_text   :=v_text || 'FOB Cost             :'||TO_CHAR(cur.OD_PB_COST_ASSOCIATED)||chr(10);
       v_text   :=v_text || 'Total Cost           :'||TO_CHAR(cur.OD_SC_PAY_AMOUNT)||chr(10);
       v_text   :=v_text || 'No of Units          :'||TO_CHAR(cur.OD_SC_NUM_WORKERS)||chr(10);
       v_text   :=v_text || 'Withdrawal Status    :'||cur.OD_OB_WITHDRAWAL_STATUS||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text || v_sku_info||chr(10);


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_AUDITOR_NAME||':'||cur.OD_PB_QA_ENGR_EMAIL;
	  v_cc_email_list:=NULL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

       IF cur.OD_OB_WITHDRAWAL_STATUS='PREAPPROVED' THEN	
  
           v_subject:=cur.OD_OB_WITHDRAWAL_ID||'/'||cur.OD_OB_FACTORY_NAME||' has been Preapproved';

           IF v_instance<>'GSIPRDGB' THEN
 
  	      v_subject:='Please Ignore this mail :'||v_subject;

           END IF;

	   IF NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'PY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character14='PY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

 	   END IF;

       ELSIF cur.OD_OB_WITHDRAWAL_STATUS='APPROVED' THEN	
  
           v_subject:=cur.OD_OB_WITHDRAWAL_ID||'/'||cur.OD_OB_FACTORY_NAME||' has been Approved';

           IF v_instance<>'GSIPRDGB' THEN
 
  	      v_subject:='Please Ignore this mail :'||v_subject;

           END IF;

	   IF NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'AY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character14='AY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

 	   END IF;

       ELSIF cur.OD_OB_WITHDRAWAL_STATUS='SUBMITTED' THEN	
  
           v_subject:=cur.OD_OB_WITHDRAWAL_ID||'/'||cur.OD_OB_FACTORY_NAME||' has been Submitted';

           IF v_instance<>'GSIPRDGB' THEN
 
  	      v_subject:='Please Ignore this mail :'||v_subject;

           END IF;

	   IF NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'SY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character14='SY'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

 	   END IF;

       ELSIF cur.OD_OB_WITHDRAWAL_STATUS='REJECTED' THEN	
  
           v_subject:=cur.OD_OB_WITHDRAWAL_ID||'/'||cur.OD_OB_FACTORY_NAME||' has been Rejected';

           IF v_instance<>'GSIPRDGB' THEN
 
  	      v_subject:='Please Ignore this mail :'||v_subject;

           END IF;

	   IF NVL(cur.OD_OB_APRSTS_NTFY,'X')<>'RY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character14='RY'
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
END XX_QA_WITHDRAWAL_PROCESS;
END XX_QA_WITHDRAWAL_PKG;
/
