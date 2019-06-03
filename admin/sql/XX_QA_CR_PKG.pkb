SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_CR_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_CR_PKG.pkb      	   	               |
-- | Description :  OD QA CR Processing Pkg                            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       12-Aug-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       17-Oct-2011 Paddy Sanjeevi     Modified for defect 14455 |
-- |1.2       10-JAN-2013 Saritha M          Modified for defect 21229 | 
-- +===================================================================+
AS

PROCEDURE XX_CR_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS


CURSOR c_reg
IS
SELECT *
  FROM apps.Q_OD_OB_REG_CERT_V a
 WHERE OD_OB_REG_DATE IS NOT NULL
   AND OD_OB_RENEW_YN='Y'
   AND OD_OB_RENEW_FREQUENCY IS NOT NULL
   AND NOT EXISTS (SELECT 'X'
		     FROM apps.Q_OD_OB_REG_CERT_V
 		    WHERE OD_REF_REG_ID=a.OD_OB_REG_ID);


CURSOR c_reg_due IS
SELECT *
  FROM apps.Q_OD_OB_REG_CERT_V a
 WHERE OD_OB_REG_DUE_DATE IS NOT NULL
   AND OD_OB_REG_DATE IS NULL;




  v_email_list    	VARCHAR2(3000);
  v_cc_email_list	VARCHAR2(3000);
  v_text		VARCHAR2(6000);
  v_defects		VARCHAR2(2000);
  v_subject		VARCHAR2(3000);
  v_errbuf     		VARCHAR2(2000);
  v_retcode    		VARCHAR2(50);
  v_instance   		VARCHAR2(10);
  v_renew_date		DATE;


  v_request_id 		NUMBER;
  v_crequest_id 	NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
  i			NUMBER:=0;
  j			NUMBER:=0;
  v_cr_create		VARCHAR2(1):='N';  

  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;
  l_character18         varchar2(100)   ;    ------ As per Ver 1.2
 BEGIN
 
    SELECT name INTO v_instance FROM v$database;

   FOR cur IN c_reg_due LOOP

       v_text:=NULL;

       v_text   :=v_text || 'Registration Type     :'||cur.OD_OB_REG_ID||chr(10);
       v_text   :=v_text || 'Registration #        :'||cur.OD_OB_REG_NO||chr(10);
       v_text   :=v_text || 'Region                :'||cur.OD_SC_REGION||chr(10);
       v_text   :=v_text || 'Vendor Name           :'||cur.OD_OB_VENDOR_NAME||chr(10);
       v_text   :=v_text || 'Sourcing Agent        :'||cur.OD_SC_AUDIT_AGENT||chr(10);
       v_text   :=v_text || 'Paid By               :'||cur.OD_PB_ENTITY||chr(10);
       v_text   :=v_text || 'SKU                   :'||TO_CHAR(cur.OD_OB_SKU)||chr(10);
       v_text   :=v_text || 'SKU Description       :'||cur.OD_PB_ITEM_DESC||chr(10);
       v_text   :=v_text || 'Registration Due Date :'||TO_CHAR(cur.OD_OB_REG_DUE_DATE)||chr(10);
       v_text   :=v_text || 'Registration Status   :'||cur.OD_OB_REG_STATUS||chr(10);

       IF lc_send_mail='Y' THEN
       
        v_email_list:=cur.OD_PB_QA_ENGR_EMAIL;
      ELSE
          v_email_list:= 'padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

      IF TRUNC(SYSDATE) >=TRUNC(cur.od_ob_reg_due_date) THEN   -- As per Ver 1.2
      
      	  v_subject:=cur.od_ob_reg_id||' is due for Renewal';

          IF v_instance<>'GSIPRDGB' THEN
 
   	     v_subject:='Please Ignore this mail :'||v_subject;

          END IF;
          
	 -- IF NVL(cur.OD_OB_ENGR_NTFY,'X')<>'CR' THEN   -- As per Ver 1.2 (commented by Oracle AMS SCM team)

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
             
                        
             BEGIN          ------ As per Ver 1.2
             
             SELECT character18 INTO l_character18   ------ As per Ver 1.2
              FROM  apps.qa_results 
             WHERE plan_id=cur.plan_id
	       AND occurrence=cur.occurrence
	       AND organization_id=cur.organization_id;
	       	                  
             IF l_character18 IS NULL THEN  ------ As per Ver 1.2
             UPDATE apps.qa_results  
                SET character18='CR'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;	        
	        
	     END IF;   
	     
	     EXCEPTION           ------ As per Ver 1.2
  	     WHEN others THEN  
  	     NULL;
	     END;
	     	         
          ----Commented  As per Ver 1.2
      /*ELSIF SYSDATE < cur.OD_OB_REG_DUE_DATE-90 THEN

 	  v_subject:=cur.od_ob_reg_id||' is scheduled for Renewal';

          IF v_instance<>'GSIPRDGB' THEN
 
   	     v_subject:='Please Ignore this mail :'||v_subject;

          END IF;

	  IF NVL(cur.OD_OB_ENGR_NTFY,'X')<>'PR' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character18='PR'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

	  END IF;

       ELSIF SYSDATE > cur.OD_OB_REG_DUE_DATE+30 THEN

 	  v_subject:=cur.od_ob_reg_id||' is Pastdue for Renewal';

          IF v_instance<>'GSIPRDGB' THEN
 
   	     v_subject:='Please Ignore this mail :'||v_subject;

          END IF;

	  IF NVL(cur.OD_OB_ENGR_NTFY,'X')<>'PS' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

             UPDATE apps.qa_results  
                SET character18='PS'
              WHERE plan_id=cur.plan_id
                AND occurrence=cur.occurrence
	        AND organization_id=cur.organization_id;

	  END IF;*/

       END IF;
   END LOOP;
   COMMIT;

   FOR cur IN c_reg LOOP

     v_cr_create:='N';
     v_renew_date:=NULL;
  
     IF cur.OD_OB_RENEW_FREQUENCY LIKE 'Bi%' THEN

	v_renew_date:=cur.od_ob_reg_date+730;

        v_cr_create:='Y';

     ELSIF cur.OD_OB_RENEW_FREQUENCY LIKE 'Annually%' THEN 

	v_renew_date:=cur.od_ob_reg_date+365;

        v_cr_create:='Y';
  	
     ELSIF cur.OD_OB_RENEW_FREQUENCY LIKE 'Semi%' THEN 

	v_renew_date:=cur.od_ob_reg_date+180;

        v_cr_create:='Y';

     ELSIF cur.OD_OB_RENEW_FREQUENCY LIKE 'Oth%' THEN 

	v_renew_date:=cur.od_pb_date_renew;

        v_cr_create:='Y';

     END IF;	 	
	
     IF v_cr_create='Y' THEN
        i:=i+1;
        BEGIN
          INSERT INTO apps.Q_OD_OB_REG_CERT_IV
          (       process_status, 
                  organization_code ,
                  plan_name,
                  insert_type,
	          matching_elements,
		  od_ref_reg_id,
		  od_sc_region,
		  OD_OB_REG_TYPE,
		  OD_OB_REG_NO,
		  OD_OB_VENDOR_NAME,
		  OD_SC_AUDIT_AGENT,
		  OD_OB_SKU,
		  OD_PB_ITEM_DESC,
		  OD_OB_REG_DUE_DATE,
		  OD_PB_QA_ENGR_EMAIL,
  	          qa_created_by_name,
                  qa_last_updated_by_name
          )
         VALUES
	  (
 	       '1',
               'PRJ',
               'OD_OB_REG_CERT',
               '1', --1 for INSERT
               'OD_OB_REG_ID,OD_OB_REG_TYPE,OD_OB_VENDOR_NAME',
		cur.od_ob_reg_id,
		cur.od_sc_region,
		cur.OD_OB_REG_TYPE,
		cur.OD_OB_REG_NO,
		cur.od_ob_vendor_name,		-- Vendor Name
		cur.OD_SC_AUDIT_AGENT,
		cur.OD_OB_SKU,
		cur.OD_PB_ITEM_DESC,
		TO_CHAR(v_renew_date,'DD-MON-YYYY'),
		cur.od_pb_qa_engr_email,
		fnd_global.user_name,
     	        fnd_global.user_name
	  );
       EXCEPTION
         WHEN others THEN
   	   NULL;
       END;

       UPDATE apps.qa_results
	  SET character16=TO_CHAR(v_renew_date,'YYYY/MM/DD')
        WHERE plan_id=cur.plan_id
          AND occurrence=cur.occurrence
	  AND organization_id=cur.organization_id;	

     END IF;   --IF v_cr_create='Y' THEN
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
EXCEPTION
  WHEN others THEN
  v_errbuf:='Error in When others :'||SQLERRM;
  v_retcode:=SQLCODE;
END XX_CR_PROCESS;
END XX_QA_CR_PKG;
/
