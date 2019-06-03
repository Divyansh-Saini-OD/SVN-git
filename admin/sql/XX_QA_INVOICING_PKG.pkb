SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_INVOICING_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_INVOICING_PKG.pkb      	   	       |
-- | Description :  OD QA Invoicing Processing Pkg                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       14-May-2011 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS


PROCEDURE XX_QA_INVOICING_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
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

 v_lsdate		DATE;
 v_sdate		DATE;
 v_cpid	 		NUMBER;
 v_cpaid	 	NUMBER;


 CURSOR C_ent_status IS
 SELECT *
   FROM apps.Q_OD_OB_INVOICING_V
  WHERE OD_OB_PAYMENT_STATUS='ENTERED'
    AND (SYSDATE-OD_PB_DATE_OPENED)>28;

 CURSOR C_sub_status IS
 SELECT *
   FROM apps.Q_OD_OB_INVOICING_V
  WHERE OD_OB_PAYMENT_STATUS='SUBMITTED'
    AND (SYSDATE-OD_PB_DATE_REQUESTED)>28;

 BEGIN

   SELECT name INTO v_instance from v$database;

   FOR cur IN C_ent_status LOOP

       v_text:=NULL;

       v_text   :=v_text || 'Invoice #            :'||cur.OD_PB_INVOICE_NUM||chr(10);
       v_text   :=v_text || 'Invoice Date         :'||TO_CHAR(cur.OD_PB_DATE_INVOICED)||chr(10);
       v_text   :=v_text || 'Factory Name         :'||cur.OD_OB_FACTORY_NAME||chr(10);
       v_text   :=v_text || 'Service Provider     :'||cur.OD_PB_COMPANY||chr(10);
       v_text   :=v_text || 'Service Details      :'||cur.OD_OB_SERVICES||chr(10);
       v_text   :=v_text || 'Payment Status       :'||cur.OD_OB_PAYMENT_STATUS||chr(10);
       v_text   :=v_text || 'Status Date          :'||TO_CHAR(cur.OD_PB_DATE_OPENED)||chr(10);
       v_text   :=v_text || 'Invoice Amount US$   :'||TO_CHAR(cur.OD_OB_INVOICE_AMNT)||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_OB_INVOICE_OWNER;
	  v_cc_email_list:=NULL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com:Victor.Garcia@officedepot.com';
       END IF;

       v_subject:=cur.OD_PB_INVOICE_NUM||'/'||cur.OD_PB_COMPANY||' has been pending in Entered Status';

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       IF NVL(cur.OD_OB_APRSTS_NTFY,'NN')<>'EY' THEN
 	
          xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
 
          UPDATE apps.qa_results  
             SET character18='EY'
           WHERE plan_id=cur.plan_id
             AND occurrence=cur.occurrence
	     AND organization_id=cur.organization_id;
       END IF;

   END LOOP;
   COMMIT;


   FOR cur IN C_sub_status LOOP

       v_text:=NULL;

       v_text   :=v_text || 'Invoice #            :'||cur.OD_PB_INVOICE_NUM||chr(10);
       v_text   :=v_text || 'Invoice Date         :'||TO_CHAR(cur.OD_PB_DATE_INVOICED)||chr(10);
       v_text   :=v_text || 'Factory Name         :'||cur.OD_OB_FACTORY_NAME||chr(10);
       v_text   :=v_text || 'Service Provider     :'||cur.OD_PB_COMPANY||chr(10);
       v_text   :=v_text || 'Service Details      :'||cur.OD_OB_SERVICES||chr(10);
       v_text   :=v_text || 'Payment Status       :'||cur.OD_OB_PAYMENT_STATUS||chr(10);
       v_text   :=v_text || 'Status Date          :'||TO_CHAR(cur.OD_PB_DATE_REQUESTED)||chr(10);
       v_text   :=v_text || 'Invoice Amount US$   :'||TO_CHAR(cur.OD_OB_INVOICE_AMNT)||chr(10);
       v_text   :=v_text || chr(10);
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||chr(10);	
       v_text   :=v_text ||'Response is needed within 1 day or escalation mail will be sent';


       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_OB_INVOICE_OWNER;
	  v_cc_email_list:=NULL;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com:Victor.Garcia@officedepot.com';
--	  v_cc_email_list:='Fritz.Lutzy@officedepot.com';
       END IF;

       v_subject:=cur.OD_PB_INVOICE_NUM||'/'||cur.OD_PB_COMPANY||' has been pending in Submitted Status';

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;

       IF NVL(cur.OD_OB_APRSTS_NTFY,'NN')<>'SY' THEN
 	
          xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
 
          UPDATE apps.qa_results  
             SET character18='SY'
           WHERE plan_id=cur.plan_id
             AND occurrence=cur.occurrence
	     AND organization_id=cur.organization_id;
       END IF;

   END LOOP;
   COMMIT;

EXCEPTION
  WHEN others THEN
    COMMIT;
    v_errbuf:='Error in When others :'||SQLERRM;
    v_retcode:=SQLCODE;
END XX_QA_INVOICING_PROCESS;
END XX_QA_INVOICING_PKG;
/
