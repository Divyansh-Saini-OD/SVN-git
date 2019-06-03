SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_FD_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_SPC_PKG.pkb                                |
-- | Description :  OD QA SPC Processing Pkg                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       12-Jul-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       25-FEB-2013 Saritha Mummaneni  Modified for Defect# 21229|  
-- +===================================================================+
AS

PROCEDURE XX_FD_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
               )
IS


CURSOR c_fd
IS
SELECT *
  FROM apps.q_od_ob_factory_data_v
 WHERE od_ob_fd_date IS NOT NULL
   AND NVL(od_ob_engr_ntfy,'X')<>'Y';

CURSOR c_fd_defects(p_fd_id VARCHAR2)
IS
SELECT *
  FROM apps.q_od_ob_fact_data_defects_v
 WHERE OD_OB_REF_FDID=p_fd_id;


CURSOR c_create_fd
IS
SELECT *
  FROM  apps.q_od_ob_factory_data_v a 
 WHERE  a.OD_ob_fd_date IS NOT NULL
   AND  a.OD_OB_FD_FREQUENCY IS NOT NULL
   AND  NOT EXISTS (SELECT 'x'
              FROM apps.q_od_ob_factory_data_v
             WHERE OD_OB_REF_FDID=a.od_ob_fd_id);


  v_email_list        VARCHAR2(3000);
  v_cc_email_list    VARCHAR2(3000);
  v_text        VARCHAR2(6000);
  v_defects        VARCHAR2(2000);
  v_subject        VARCHAR2(3000);
  v_errbuf             VARCHAR2(2000);
  v_retcode            VARCHAR2(50);
  v_instance           VARCHAR2(10);


  v_request_id         NUMBER;
  v_crequest_id     NUMBER;
  v_user_id        NUMBER:=fnd_global.user_id;
  i            NUMBER:=0;
  j            NUMBER:=0;
  v_fd_create        VARCHAR2(1):='N';  

  v_phase        varchar2(100)   ;
  v_status        varchar2(100)   ;
  v_dphase        varchar2(100)    ;
  v_dstatus        varchar2(100)    ;
  x_dummy        varchar2(2000)     ;


 BEGIN

   SELECT name INTO v_instance FROM v$database;

   FOR cur IN c_fd LOOP
    
       j:=0;    
       v_defects:=NULL;

       FOR c IN c_fd_defects(cur.od_ob_fd_id) LOOP
    
       j:=j+1;
    
           v_defects:=v_defects||c.od_ob_inspection_type||','||c.od_pb_defect_sum||','||to_char(c.od_ob_defect_pct)||chr(10);

       END LOOP;

       IF lc_send_mail='Y' THEN
           v_email_list:=cur.OD_PB_QA_ENGR_EMAIL||':'||cur.OD_PB_AUDITOR_NAME;
       ELSE
           v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';
       END IF;

       IF j>0 THEN

          v_subject :=cur.od_ob_fd_id||' is scheduled for update';

          v_text:=cur.od_ob_fd_id||' is scheduled for update. Please see the details below'||chr(10);
          v_text:=v_text||chr(10);
          v_text:=v_text||'FD Date          :'||TO_CHAR(cur.od_ob_fd_date)||chr(10);
          v_text:=v_text||'Vendor Name      :'||cur.od_ob_vendor_name||chr(10);
          v_text:=v_text||'Factory Name     :'||cur.od_ob_factory_name||chr(10);
          v_text:=v_text||'Factory Address  :'||cur.od_sc_factory_address||chr(10);
          v_text:=v_text||'Sourcing Agent   :'||cur.od_sc_audit_agent||chr(10);
          v_text:=v_text||'Primary Products :'||cur.od_ob_primary_products||chr(10);
      v_text:=v_text||chr(10);
      v_text:=v_text||chr(10);
      v_text:=v_text||'Inspection Type/Defect Classification/Defect %'||chr(10);
      v_text:=v_text||chr(10);
      v_text:=v_text||v_defects||chr(10);

          IF v_instance<>'GSIPRDGB' THEN

              v_subject:='Please Ignore this mail :'||v_subject;
 
          END IF;

        IF NVL(cur.od_ob_engr_ntfy,'X')<>'Y' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
 
             UPDATE apps.qa_results
                SET character23='Y'
              WHERE plan_id=cur.plan_id
                AND collection_id=cur.collection_id
                AND occurrence=cur.occurrence;    
          END IF;


       ELSE

      v_subject :='There is no factory data defects for '||cur.od_ob_fd_id;

          IF v_instance<>'GSIPRDGB' THEN

              v_subject:='Please Ignore this mail :'||v_subject;
 
          END IF;
    
      IF NVL(cur.od_ob_engr_ntfy,'X')<>'DY' THEN

             xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
 
             UPDATE apps.qa_results
                SET character23='DY'
              WHERE plan_id=cur.plan_id
                AND collection_id=cur.collection_id
                AND occurrence=cur.occurrence;    

      END IF;

       END IF;

   END LOOP;
   COMMIT;


   FOR cur IN c_create_fd LOOP

     v_fd_create:='N';
  
     IF cur.od_ob_fd_frequency='Weekly' AND SYSDATE>cur.od_ob_fd_date+7 THEN

        v_fd_create:='Y';

     ELSIF cur.od_ob_fd_frequency='Monthly' AND SYSDATE>cur.od_ob_fd_date+30 THEN

        v_fd_create:='Y';
      
     ELSIF cur.od_ob_fd_frequency='Quarterly' AND SYSDATE>cur.od_ob_fd_date+90 THEN

        v_fd_create:='Y';

     END IF;         
    
     IF v_fd_create='Y' THEN
        i:=i+1;
        BEGIN
          INSERT INTO apps.Q_OD_OB_FACTORY_DATA_IV
          (       process_status, 
                  organization_code ,
                  plan_name,
                  insert_type,
              matching_elements,
          od_ob_ref_fdid,
          od_sc_region,
          od_ob_vendor_name,
          od_ob_factory_name,
          od_sc_factory_address,
          od_sc_audit_agent,
          od_ob_primary_products,
          od_ob_fd_frequency,
          od_pb_auditor_name,
          OD_PB_QA_ENGR_EMAIL,
                qa_created_by_name,
                  qa_last_updated_by_name
          )
         VALUES
      (
            '1',
               'PRJ',
               'OD_OB_FACTORY_DATA',
               '1', --1 for INSERT
               'OD_OB_FD_ID,OD_OB_VENDOR_NAME',
        cur.od_ob_fd_id,
        cur.od_sc_region,
        cur.od_ob_vendor_name,        -- Vendor Name
        cur.od_ob_factory_name,    -- Factory Name
        cur.OD_sc_factory_address,
        cur.od_sc_audit_agent,
        cur.od_ob_primary_products,                
        cur.od_ob_fd_frequency,
        cur.od_pb_auditor_name,
        cur.od_pb_qa_engr_email,
        fnd_global.user_name,
                 fnd_global.user_name
      );
       

     -- Begin as per Ver 1.1
     
     IF lc_send_mail='Y' THEN
        v_email_list:=cur.OD_PB_AUDITOR_NAME;       
     ELSE
      v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.Lutzy@officedepot.com';      
     END IF;
       
     v_subject :=cur.od_ob_fd_id||' is Created and  is Due';
     
      v_text:=cur.od_ob_fd_id||' is Created and the information is Due. Please see the details below'||chr(10);
      v_text:=v_text||chr(10);
      v_text:=v_text||'FD Date          :'||TO_CHAR(cur.od_ob_fd_date)||chr(10);
      v_text:=v_text||'Vendor Name      :'||cur.od_ob_vendor_name||chr(10);
      v_text:=v_text||'Factory Name     :'||cur.od_ob_factory_name||chr(10);
      v_text:=v_text||'Factory Address  :'||cur.od_sc_factory_address||chr(10);
      v_text:=v_text||'Sourcing Agent   :'||cur.od_sc_audit_agent||chr(10);
      v_text:=v_text||'Primary Products :'||cur.od_ob_primary_products||chr(10);
      v_text:=v_text||chr(10);
      v_text:=v_text||chr(10);
      v_text:=v_text||'Inspection Type/Defect Classification/Defect %'||chr(10);
      v_text:=v_text||chr(10);
      v_text:=v_text||v_defects||chr(10);
     
       IF v_instance<>'GSIPRDGB' THEN
            v_subject:='Please Ignore this mail :'||v_subject;
       END IF;
 
        xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
        
     -- End as per Ver 1.1
     EXCEPTION
              WHEN others THEN
               NULL;
     END;
     END IF;   --IF v_fd_create='Y' THEN
     
     
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
END XX_FD_PROCESS;
END XX_QA_FD_PKG;
/
