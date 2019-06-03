SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_QMR_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_QMR_PKG.pkb      	   	               |
-- | Description :  OD QA QMR Processing Pkg                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       12-Jul-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       19-Oct-2011 Paddy Sanjeevi     Modified for Defect 14566 |
-- +===================================================================+
AS

PROCEDURE process_cognos
IS
CURSOR c_cognos
IS
SELECT rowid arowid,a.*
  FROM  apps.xx_qa_cognos_stg a
 WHERE  process_Flag=1;

  v_errbuf     		VARCHAR2(2000);
  v_retcode    		VARCHAR2(50);
  v_error_message	varchar2(2000);


  v_request_id 		NUMBER;
  v_crequest_id 	NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
  i			NUMBER:=0;

  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;
  
  v_vendor_name		varchar2(150);

  v_record_id		NUMBER;

 BEGIN

   DELETE 
     FROM xx_qa_cognos_stg
    WHERE process_Flag=7;
   COMMIT;

   UPDATE xx_qa_cognos_stg a
      SET process_flag=7
    WHERE process_flag=1
      AND EXISTS (SELECT 'x'
		    FROM apps.q_od_ob_qmr_cognos_v
		   WHERE od_sc_num_workers=a.load_batch_id);

   COMMIT;

   UPDATE xx_qa_cognos_stg a
      SET process_flag=7
    WHERE process_flag=1
      AND EXISTS (SELECT 'x'
		    FROM apps.qa_results_interface
		   WHERE plan_name like 'OD_OB_QMR_COGNOS%'
		     AND character27=a.load_batch_id);

   COMMIT;

   FOR cur IN c_cognos LOOP

       SELECT apps.xx_qa_qmr_seq_s.nextval INTO v_record_id FROM DUAL;

       UPDATE xx_qa_cognos_stg
	  SET load_batch_id=v_record_id      
	WHERE rowid=cur.arowid
	  AND load_batch_id IS NULL;

   END LOOP;
   COMMIT;   

   FOR cur IN c_cognos LOOP

        i:=i+1;

	v_vendor_name:=NULL;

	BEGIN
	  SELECT od_sc_vendor_name
	    INTO v_vendor_name
	    FROM apps.q_od_pb_sc_vendor_master_v	  
           WHERE od_sc_vendor_number=cur.od_ob_vendor_name
	     AND ROWNUM<2;
	EXCEPTION
	  WHEN others THEN
	    v_vendor_name:=NULL;
	END;

        BEGIN
          INSERT INTO apps.Q_OD_OB_QMR_COGNOS_IV
          (       process_status, 
                  organization_code ,
                  plan_name,
                  insert_type,
	          matching_elements,
		OD_SC_ENTRY_DATE,
		OD_OB_SKU,
		OD_PB_ITEM_DESC,
		OD_OB_PB_YN,
		OD_OB_DI_YN,
		OD_OB_DIVISION_ID,
		OD_PB_DIVISION,
		OD_OB_DEPT_ID,
		OD_PB_SC_DEPT_NAME,
		OD_OB_CLASS_ID,
		OD_OB_CLASS,
		OD_OB_SUBCLASS_ID,
		OD_OB_SUBCLASS,
		OD_OB_VENDOR_NUMBER,
		OD_OB_REPLEN_STATUS,
		OD_OB_ONHAND_UNITS,
		OD_OB_SALE_AMT,
		OD_OB_RETURN_AMT,
		OD_OB_DNC_AMT,
		OD_OB_SALE_UNITS,
		OD_OB_RETURN_UNITS,
		OD_OB_DNC_UNITS,
		OD_OB_RR_PCT,
		OD_OB_DNC_PCT,
		OD_OB_RRPCT_UNITS,
		OD_OB_DNCPCT_UNITS,
		OD_SC_NUM_WORKERS,
  	        qa_created_by_name,
                qa_last_updated_by_name
          )
         VALUES
	  (
 	       '1',
               'PRJ',
               'OD_OB_QMR_COGNOS',
               '1', --1 for INSERT
               'OD_SC_ENTRY_DATE,OD_OB_SKU,OD_OB_VENDOR_NAME',
		TO_CHAR(cur.OD_SC_ENTRY_DATE,'DD-MON-YYYY'),
		cur.OD_OB_SKU,
		cur.OD_PB_ITEM_DESC,
		cur.OD_OB_PB_YN,
		cur.OD_OB_DI_YN,
		cur.OD_OB_DIVISION_ID,
		cur.OD_PB_DIVISION,
		cur.OD_OB_DEPT_ID,
		cur.OD_PB_SC_DEPT_NAME,
		cur.OD_OB_CLASS_ID,
		cur.OD_OB_CLASS,
		cur.OD_OB_SUBCLASS_ID,
		cur.OD_OB_SUBCLASS,
		NVL(v_vendor_name,cur.OD_OB_VENDOR_NAME),
		cur.OD_OB_REPLEN_STATUS,
		cur.OD_OB_ONHAND_UNITS,
		cur.OD_OB_SALE_AMT,
		cur.OD_OB_RETURN_AMT,
		cur.OD_OB_DNC_AMT,
		cur.OD_OB_SALE_UNITS,
		cur.OD_OB_RETURN_UNITS,
		cur.OD_OB_DNC_UNITS,
		NULL,
		NULL,
		NULL,
		NULL,
		cur.load_batch_id,
		fnd_global.user_name,
     	        fnd_global.user_name
	  );
       EXCEPTION
         WHEN others THEN
	   v_error_message:=sqlerrm;
   	   update xx_qa_cognos_stg
	      set error_flag='Y',error_message=v_error_message,
		  last_update_date=TRUNC(SYSDATE),
		  process_flag=7
	    where rowid=cur.arowid;
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
  COMMIT;
EXCEPTION
  WHEN others THEN
  v_errbuf:='Error in When others :'||SQLERRM;
  v_retcode:=SQLCODE;
END process_cognos;


PROCEDURE process_bazaar
IS
CURSOR c_bazaar
IS
SELECT rowid arowid,a.*
  FROM  apps.xx_qa_bazaar_stg a
 WHERE  process_Flag=1;

  v_errbuf     		VARCHAR2(2000);
  v_retcode    		VARCHAR2(50);
  v_error_message	VARCHAR2(2000);

  v_request_id 		NUMBER;
  v_crequest_id 	NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
  i			NUMBER:=0;

  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;

  v_record_id		NUMBER;

 BEGIN

   DELETE 
     FROM xx_qa_bazaar_stg
    WHERE process_Flag=7;
   COMMIT;

   UPDATE xx_qa_bazaar_stg a
      SET process_flag=7
    WHERE process_flag=1
      AND EXISTS (SELECT 'x'
		    FROM apps.q_od_ob_qmr_bazaar_v
		   WHERE od_sc_num_workers=a.load_batch_id);

   COMMIT;

   UPDATE xx_qa_bazaar_stg a
      SET process_flag=7
    WHERE process_flag=1
      AND EXISTS (SELECT 'x'
		    FROM apps.qa_results_interface
		   WHERE plan_name like 'OD_OB_QMR_BAZAAR%'
		     AND character9=a.load_batch_id);

   COMMIT;

   FOR cur IN c_bazaar LOOP

       SELECT apps.xx_qa_qmr_seq_s.nextval INTO v_record_id FROM DUAL;

       UPDATE xx_qa_bazaar_stg
	  SET load_batch_id=v_record_id      
	WHERE rowid=cur.arowid
	  AND load_batch_id IS NULL;

   END LOOP;
   COMMIT;   

   FOR cur IN c_bazaar LOOP

        i:=i+1;
        BEGIN
          INSERT INTO apps.Q_OD_OB_QMR_BAZAAR_IV
          (       process_status, 
                  organization_code ,
                  plan_name,
                  insert_type,
	          matching_elements,
		OD_OB_REVIEW_ID,
		OD_SC_ENTRY_DATE,
		OD_OB_SKU,
		OD_OB_OVERALL_RAT,
		OD_OB_MEET_EXPECT,
		OD_OB_QUALITY_RAT,
		OD_OB_REC_FRND,
		OD_OB_PROS,
		OD_OB_CONS,
		OD_PB_COMMENTS,
		od_sc_num_workers,
  	          qa_created_by_name,
                  qa_last_updated_by_name
          )
         VALUES
	  (
 	       '1',
               'PRJ',
               'OD_OB_QMR_BAZAAR',
               '1', --1 for INSERT
               'OD_OB_REVIEW_ID,OD_SC_ENTRY_DATE,OD_OB_SKU',
		cur.OD_OB_REVIEW_ID,
		TO_CHAR(cur.OD_SC_ENTRY_DATE,'DD-MON-YYYY'),
		cur.OD_OB_SKU,
		cur.OD_OB_OVERALL_RAT,
		cur.OD_OB_MEET_EXPECT,
		cur.OD_OB_QUALITY_RAT,
		cur.OD_OB_REC_FRND,
		cur.OD_OB_PROS,
		cur.OD_OB_CONS,
		cur.OD_PB_COMMENTS,
		cur.load_batch_id,
		fnd_global.user_name,
     	        fnd_global.user_name
	  );
       EXCEPTION
         WHEN others THEN
      	   v_error_message:=sqlerrm;
   	   update xx_qa_bazaar_stg
	      set error_flag='Y',error_message=v_error_message,
		  last_update_date=TRUNC(SYSDATE),process_flag=7
	    where rowid=cur.arowid;
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
  COMMIT;
EXCEPTION
  WHEN others THEN
  v_errbuf:='Error in When others :'||SQLERRM;
  v_retcode:=SQLCODE;
END process_bazaar;


PROCEDURE process_CC
IS
CURSOR c_CC
IS
SELECT rowid arowid,a.*
  FROM  apps.xx_qa_CC_stg a
 WHERE  process_Flag=1;

  v_errbuf     		VARCHAR2(2000);
  v_retcode    		VARCHAR2(50);
  v_error_message	VARCHAR2(2000);

  v_request_id 		NUMBER;
  v_crequest_id 	NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
  i			NUMBER:=0;

  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;

  v_record_id		NUMBER;

 BEGIN

   DELETE 
     FROM xx_qa_cc_stg
    WHERE process_Flag=7;
   COMMIT;

   UPDATE xx_qa_CC_stg a
      SET process_flag=7
    WHERE process_flag=1
      AND EXISTS (SELECT 'x'
		    FROM apps.q_od_ob_qmr_CC_v
		   WHERE od_sc_num_workers=a.load_batch_id);

   COMMIT;

   UPDATE xx_qa_cc_stg a
      SET process_flag=7
    WHERE process_flag=1
      AND EXISTS (SELECT 'x'
		    FROM apps.qa_results_interface
		   WHERE plan_name like 'OD_OB_QMR_CC%'
		     AND character10=a.load_batch_id);

   COMMIT;

   FOR cur IN c_CC LOOP

       SELECT apps.xx_qa_qmr_seq_s.nextval INTO v_record_id FROM DUAL;

       UPDATE xx_qa_CC_stg
	  SET load_batch_id=v_record_id      
	WHERE rowid=cur.arowid
	  AND load_batch_id IS NULL;

   END LOOP;
   COMMIT;   

   FOR cur IN c_CC LOOP

        i:=i+1;
        BEGIN
          INSERT INTO apps.Q_OD_OB_QMR_CC_IV
          (       process_status, 
                  organization_code ,
                  plan_name,
                  insert_type,
	          matching_elements,
  	 	  OD_PB_CASE_NUMBER,
		  OD_OB_SAFETY,
	  	  OD_OB_SOURCE,
		  OD_SC_ENTRY_DATE,
		  OD_OB_SKU,
		  OD_OB_MFG_DATE,
		  OD_OB_PUR_DATE,
		  OD_OB_ISSUE_TYPE,
		  OD_OB_REASON,
		  OD_PB_COMMENTS,
		  OD_OB_STATE,
		  od_sc_num_workers,
                  qa_created_by_name,
                  qa_last_updated_by_name
          )
         VALUES
	  (
 	       '1',
               'PRJ',
               'OD_OB_QMR_CC',
               '1', --1 for INSERT
               'OD_OB_CASE_NUMBER,OD_SC_ENTRY_DATE,OD_OB_SKU',
  	 	cur.OD_PB_CASE_NUMBER,
  	        cur.OD_OB_SAFETY,
	  	cur.OD_OB_SOURCE,
		TO_CHAR(cur.OD_SC_ENTRY_DATE,'DD-MON-YYYY'),
		cur.OD_OB_SKU,
		cur.OD_OB_MFG_DATE,
		cur.OD_OB_PUR_DATE,
		cur.OD_OB_ISSUE_TYPE,
		cur.OD_OB_REASON,
		cur.OD_PB_COMMENTS,
		cur.OD_OB_STATE,
		cur.load_batch_id,
		fnd_global.user_name,
     	        fnd_global.user_name
	  );
       EXCEPTION
         WHEN others THEN
	   v_error_message:=sqlerrm;
   	   update xx_qa_cc_stg
	      set error_flag='Y',error_message=v_error_message,
		  last_update_date=TRUNC(SYSDATE),process_flag=7
	    where rowid=cur.arowid;
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
  COMMIT;
EXCEPTION
  WHEN others THEN
  v_errbuf:='Error in When others :'||SQLERRM;
  v_retcode:=SQLCODE;
END process_CC;

PROCEDURE XX_QMR_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS

CURSOR C1 IS
SELECT TO_CHAR(od_sc_entry_date) cognos_date,
       od_ob_sku sku,
       error_message
  FROM xx_qa_cognos_stg
 WHERE process_flag=1
   AND error_flag='Y'
   AND last_update_date=TRUNC(SYSDATE);

CURSOR C2 IS
SELECT TO_CHAR(od_sc_entry_date) bz_date,
       od_ob_sku sku,
       error_message
  FROM xx_qa_bazaar_stg
 WHERE process_flag=1
   AND error_flag='Y'
   AND last_update_date=TRUNC(SYSDATE);

CURSOR C3 IS
SELECT TO_CHAR(od_sc_entry_date) cc_date,
       od_ob_sku sku,
       error_message
  FROM xx_qa_cc_stg
 WHERE process_flag=1
   AND error_flag='Y'
   AND last_update_date=TRUNC(SYSDATE);

 v_cc_text varchar2(32000);
 v_bz_text varchar2(32000);
 v_cg_text varchar2(32000);
 v_instance varchar2(50);
 v_email_list  varchar2(100);
 v_subject varchar2(150);
 v_error varchar2(1):='N';
BEGIN

  process_cognos;
  process_bazaar;
  process_cc;

  SELECT name INTO v_instance FROM v$database;
 
  v_email_list:='Fritz.Lutzy@officedepot.com';

  v_subject :='QMR Data Issues';

  IF v_instance<>'GSIPRDGB' THEN

     v_subject:='Please Ignore this mail :'||v_subject;

  END IF; 

  FOR cur IN C1 LOOP

      v_cg_text:=v_cg_text||cur.cognos_date||','||cur.sku||','||cur.error_message||chr(10);
      v_error:='Y';

  END LOOP;


  FOR cur IN C2 LOOP

      v_bz_text:=v_bz_text||cur.bz_date||','||cur.sku||','||cur.error_message||chr(10);
      v_error:='Y';
  END LOOP;

  FOR cur IN C3 LOOP

      v_cc_text:=v_cc_text||cur.cc_date||','||cur.sku||','||cur.error_message||chr(10);
      v_error:='Y';
  END LOOP;

  IF v_error='Y' THEN
     xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,NULL,v_cg_text||chr(10)||v_bz_text||chr(10)||v_cc_text);
  END IF;

END XX_QMR_PROCESS;

END XX_QA_QMR_PKG;
/
