SET VERIFY OFF; 
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_POS_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_QMR_PKG.pkb      	   	               |
-- | Description :  OD QA QMR Processing Pkg                           |
-- | Rice id     :  E3004                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       12-Jul-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       25-Jun-2013 Paddy Sanjeevi     Modified for R12          |
-- +===================================================================+
AS

FUNCTION  xx_get_dept(p_dept_id IN NUMBER) RETURN VARCHAR2  IS
v_dept VARCHAR2(150);
BEGIN
  SELECT c.description   
    INTO v_dept  
    FROM apps.fnd_flex_values_vl c,	 
         apps.fnd_flex_value_sets b  
   WHERE b.flex_value_set_name='XX_GI_DEPARTMENT_VS'     
     AND c.flex_value_set_id=b.flex_value_set_id    
     AND c.flex_value=TO_CHAR(p_dept_id)     
     AND sysdate between nvl(c.start_date_active,sysdate) and nvl(c.end_date_active,sysdate);
   RETURN(v_dept);
EXCEPTION
  WHEN others THEN
     v_dept:=NULL;
     RETURN(v_dept);
END xx_get_dept;



PROCEDURE XX_POS_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS

CURSOR c_pos
IS
SELECT rowid arowid,a.*
  FROM  apps.xx_qa_pos_stg a
 WHERE  process_Flag=1;

  v_errbuf     		VARCHAR2(2000);
  v_retcode    		VARCHAR2(50);


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
     FROM xx_qa_pos_stg
    WHERE process_Flag=7
      AND creation_date<sysdate-45;
   COMMIT;

   UPDATE xx_qa_pos_stg a
      SET process_flag=7
    WHERE process_flag=1
      AND EXISTS (SELECT 'x'
		    FROM apps.q_od_ob_pos_v
		   WHERE od_sc_num_workers=a.load_batch_id);

   COMMIT;

   -- Modified for R12 (Increment transaction date to date+1 to care of the spreadsheet upload date bug)
 
   UPDATE xx_qa_pos_stg
      SET transaction_date=transaction_date+1
    WHERE process_Flag=1;
   COMMIT;

   -- Modified for R12

   FOR cur IN c_pos LOOP

       SELECT apps.xx_qa_qmr_seq_s.nextval INTO v_record_id FROM DUAL;

       UPDATE xx_qa_pos_stg
	  SET load_batch_id=v_record_id      
	WHERE rowid=cur.arowid;

   END LOOP;
   COMMIT;   

   FOR cur IN c_pos LOOP

        i:=i+1;
        BEGIN
          INSERT INTO apps.Q_OD_OB_POS_IV
          (       process_status, 
                  organization_code ,
                  plan_name,
                  insert_type,
	          matching_elements,
  	 	  OD_OB_SKU,
		  OD_PB_ITEM_DESC,
		  OD_OB_DEPT_ID,
		  OD_PB_RESOURCE_NUMBER,
		  OD_PB_STORE_NUMBER,
		  OD_OB_REG_DATE,
		  OD_PB_COMMENTS,
		  OD_SC_NUM_WORKERS,
                  qa_created_by_name,
                  qa_last_updated_by_name
          )
         VALUES
	  (
 	       '1',
               'PRJ',
               'OD_OB_POS',
               '1', --1 for INSERT
               'OD_OB_SKU,OD_PB_STORE_NUMBER,OD_OB_REG_DATE,OD_PB_RESOURCE_NUMBER',
  	 	cur.sku,
  	        cur.sku_description,
	  	cur.dept_id,
		cur.associate_id,
		cur.store_number,
		TO_CHAR(cur.transaction_date,'DD-MON-YYYY'),
		cur.return_comments,
		cur.load_batch_id,
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
  COMMIT;
EXCEPTION
  WHEN others THEN
  v_errbuf:='Error in When others :'||SQLERRM;
  v_retcode:=SQLCODE;
END XX_POS_PROCESS;

END XX_QA_POS_PKG;
/
