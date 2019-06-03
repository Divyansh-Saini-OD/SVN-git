SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_RGA_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_RGA_PKG.pkb      	   	               |
-- | Description :  OD QA RGA Processing Pkg                           |
-- | Rice id     :  E3005                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       03-AUG-2011 Bapuji Nanapaneni  Initial version           |
-- |1.1       03-Feb-2012 Paddy Sanjeevi     Modified                  |
-- |1.2       25-Mar-2013 Saritha M          Modified for defect 21229 | 
-- |1.3       20-Jun-2013 Paddy Sanjeevi     Modified for R12          |
-- +===================================================================+
AS

--PROCEDURE xx_create_cap( x_errbuf      OUT NOCOPY VARCHAR2
--                       , x_retcode     OUT NOCOPY VARCHAR2
--                       );

PROCEDURE xx_create_cap IS

CURSOR c_rga_to_cap IS
SELECT a.plan_id
     , a.collection_id
     , a.occurrence
     , a.organization_id
     , a.od_ob_rga_id
     , a.od_sc_region
     , a.od_ob_sku
     , a.od_pb_item_desc
     , a.od_pb_sc_dept_name
     , a.od_ob_vendor_name
     , a.od_sc_audit_agent
     , a.od_pb_auditor_name
     , a.od_pb_qa_engr_email
  FROM apps.q_od_ob_rga_v a 
 WHERE a.od_pb_cap_yn = 'Y'
   AND a.od_ob_ref_capid IS NULL
   AND NOT EXISTS ( SELECT 'x'
		      FROM apps.q_od_ob_cap_v
		     WHERE OD_OB_QA_ACT = 'RGA'
	               AND od_ob_qa_id  = a.od_ob_rga_id);

CURSOR c_cap_upd IS
SELECT  a.plan_id
     ,	a.collection_id
     ,	a.occurrence
     ,	a.organization_id
     ,	b.od_pb_car_id
     ,	a.od_ob_rga_id
     ,	a.od_pb_qa_engr_email
     ,	a.od_pb_auditor_name
  FROM  apps.q_od_ob_cap_v b
     ,  apps.q_od_ob_rga_v a
 WHERE  a.od_pb_cap_yn = 'Y'
   AND  a.od_ob_ref_capid IS NULL
   AND  b.od_ob_qa_act = 'RGA'
   AND  b.od_ob_qa_id  = a.od_ob_rga_id;


  v_request_id 		NUMBER;
  v_crequest_id 	NUMBER;
  v_user_id		NUMBER := fnd_global.user_id;
  i			NUMBER := 0;
  
  v_phase		VARCHAR2(100);
  v_status		VARCHAR2(100);
  v_dphase		VARCHAR2(100);
  v_dstatus		VARCHAR2(100);
  x_dummy		VARCHAR2(2000);
  v_text		VARCHAR2(6000);
  v_email_list    	VARCHAR2(3000);
  v_cc_email_list	VARCHAR2(3000);
  v_subject		VARCHAR2(3000);
  v_instance		VARCHAR2(10);

BEGIN

  SELECT name INTO v_instance from v$database;

  FOR cur IN c_rga_to_cap LOOP
	
    i:=i+1;
    
    BEGIN
    
        INSERT INTO apps.q_od_ob_cap_iv
              ( process_status
              , organization_code
              , plan_name
              , insert_type
              , matching_elements
              , od_ob_qa_id
              , od_ob_qa_act
              , od_ob_vendor_name
              , od_sc_audit_agent
              , od_pb_auditor_name
              , od_pb_qa_engr_emaiL
              , od_sc_region
              , od_ob_sku
              , od_pb_item_desc
              , od_pb_sc_dept_name
              , qa_created_by_name
              , qa_last_updated_by_name
              )
               VALUES
              (
 	        '1'
 	      , 'PRJ'
 	      , 'OD_OB_CAP'
 	      , '1' --1 for INSERT
              , 'OD_PB_CAR_ID,OD_OB_QA_ID,OD_OB_QA_ACT'
              , cur.od_ob_rga_id
              , 'RGA'
              , cur.od_ob_vendor_name
              , cur.od_sc_audit_agent
              , cur.od_pb_auditor_name
              , cur.od_pb_qa_engr_email
              , cur.od_sc_region
              , cur.od_ob_sku
              , cur.od_pb_item_desc
              , cur.od_pb_sc_dept_name
              , fnd_global.user_name
              , fnd_global.user_name
              );

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others raised While Inserting into q_od_ob_cap_iv ');
	    NULL;
    END;
    
  END LOOP;
  COMMIT;
  
  IF i > 0 THEN
      v_request_id:= fnd_request.submit_request( application  => 'QA'
                                               , program      =>'QLTTRAMB'
                                               , description  => 'Collection Import Manager'
                                               , start_time   => NULL
                                               , sub_request  => FALSE
                                               , argument1    => '200'
                                               , argument2    => '1'
                                               , argument3    => TO_CHAR(v_user_id)
                                               , argument4    => 'No'
                                               );
       IF v_request_id > 0 THEN
          COMMIT;
       END IF;

       IF (fnd_concurrent.wait_for_request( request_id   => v_request_id
                                          , interval     => 1
                                          , max_wait     => 60000
                                          , phase        => v_phase
                                          , status       => v_status
                                          , dev_phase    => v_dphase
                                          , dev_status   => v_dstatus
                                          , message      => x_dummy
                                          )
          )  THEN
           IF v_dphase = 'COMPLETE' THEN
	       dbms_output.put_line('success');
           END IF;
       END IF;

       BEGIN
         SELECT request_id
           INTO v_crequest_id
	   FROM apps.fnd_concurrent_requests
  	  WHERE parent_request_id = v_request_id;
       
       EXCEPTION
           WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'When others while getting v_crequest_id ');
	       v_crequest_id:=NULL;
       END;

       IF v_crequest_id IS NOT NULL THEN
	
          IF (fnd_concurrent.wait_for_request( request_id   => v_crequest_id
                                             , interval     => 1
                                             , max_wait     => 60000
                                             , phase        => v_phase
                                             , status       => v_status
                                             , dev_phase    => v_dphase
                                             , dev_status   => v_dstatus
                                             , message      => x_dummy
                                             )
             )  THEN

             IF v_dphase = 'COMPLETE' THEN
  
  	        dbms_output.put_line('success');

             END IF;
          END IF;

       END IF;

  END IF;

  FOR cur IN c_cap_upd LOOP

    UPDATE qa_results
       SET character18   = cur.od_pb_car_id
     WHERE plan_id       = cur.plan_id
       AND collection_id = cur.collection_id
       AND occurrence    =cur.occurrence;	

    IF SQL%FOUND THEN
       v_subject := 'CAP Creation Notification for '||cur.od_ob_rga_id;
       v_text := 'A CAP is created for the RGA. Please see the details below'||chr(10);
       v_text := v_text||chr(10);
       v_text := v_text||'RGA ID :'||cur.od_ob_rga_id ||chr(10);
       v_text := v_text||'CAP ID :'||cur.od_pb_car_id ||chr(10);
       
       IF lc_send_mail='Y' THEN
          v_email_list    := cur.od_pb_qa_engr_email;
  	  v_cc_email_list := cur.od_pb_auditor_name;
       
       ELSE
          v_email_list    :='padmanaban.sanjeevi@officedepot.com';  -- Modified for R12
  	  v_cc_email_list :='Fritz.Lutzy@officedepot.com';
       
       END IF;

       IF v_instance <> 'GSIPRDGB' THEN

	  v_subject := 'Please Ignore this mail :'||v_subject;

       END IF;
       
       xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
                                      , p_email_list    => v_email_list
                                      , p_cc_email_list => v_cc_email_list
                                      , p_text          => v_text
                                      );
    END IF;
    
  END LOOP;
  COMMIT;
  
EXCEPTION
    WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data Found in xx_create_cap ');
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Raised in xx_create_cap:::'|| SQLERRM);
        
END xx_create_cap;

PROCEDURE cap_defects IS

CURSOR c_cap_def IS
SELECT a.plan_id
     , a.organization_id
     , a.occurrence
     , a.od_ob_rga_id rga_id
     , a.od_pb_defect_code def_code
     , a.od_pb_comments comments
     , a.od_ob_ref_capid cap_id
     , b.OD_SC_FACTORY_NAME
     , b.OD_PB_AUDITOR_NAME
     , b.OD_PB_QA_ENGR_EMAIL
     , b.OD_OB_VENDOR_NAME
     , b.OCCURRENCE cap_occurrence
     , b.COLLECTION_ID    
  FROM apps.q_od_ob_cap_v b,
       apps.q_od_ob_rga_v a 
 WHERE a.od_ob_ref_capid IS NOT NULL
   AND b.od_pb_car_id=a.od_ob_ref_capid
   AND NOT EXISTS (SELECT 'x'
                     FROM apps.q_od_ob_cap_defects_v
                    WHERE od_ob_ref_capid =a.od_ob_ref_capid
                      AND od_ob_qa_id    =a.od_ob_rga_id
                      AND od_pb_defect_sum=a.od_pb_defect_code
                  );
i            NUMBER :=  0;	
v_request_id NUMBER;
V_user_id    NUMBER:=fnd_global.user_id;

BEGIN 

FOR r_cap_defects IN c_cap_def LOOP
    
    i:=i+1;
    BEGIN
        INSERT INTO apps.Q_OD_OB_CAP_DEFECTS_IV
                  ( process_status 
                  , organization_code
                  , plan_name
                  , insert_type
    	          , matching_elements
    		  , od_ob_ref_capid
    		  , od_ob_qa_id
    		  , od_pb_defect_sum
     	          , qa_created_by_name
                  , qa_last_updated_by_name
		  , OD_PB_LEGACY_OCR_ID
		  , OD_PB_LEGACY_COL_ID
		  , OD_SC_FACTORY_NAME
		  , OD_PB_AUDITOR_NAME
		  , OD_PB_QA_ENGR_EMAIL
		  , OD_OB_VENDOR_NAME
                  )
                  VALUES
    	          (
     	            '1'
                  ,'PRJ'
                  , 'OD_OB_CAP_DEFECTS'
                  , '1' --1 for INSERT
                  , 'OD_OB_REF_CAPID,OD_OB_QA_ID,OD_OB_DS_ID'
    		  , r_cap_defects.cap_id
    	          , r_cap_defects.rga_id
    		  , r_cap_defects.def_code
    		  , fnd_global.user_name
         	  , fnd_global.user_name
		  , r_cap_defects.cap_occurrence
		  , r_cap_defects.collection_id
		  , r_cap_defects.od_sc_factory_name
		  , r_cap_defects.od_pb_auditor_name
		  , r_cap_defects.od_pb_qa_engr_email
		  , r_cap_defects.od_ob_vendor_name
    	          );
    EXCEPTION
        WHEN OTHERS THEN
    	NULL;
    END;
END LOOP;
    
COMMIT;
      
    IF i>0 THEN
        v_request_id:=FND_REQUEST.SUBMIT_REQUEST('QA','QLTTRAMB','Collection Import Manager',NULL,FALSE,
    	                                         '200','1',TO_CHAR(V_user_id),'No');
        IF v_request_id > 0 THEN
            COMMIT;
        END IF;
    END IF; 
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data Found in cap_defects ');
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Raised IN cap_defects:::'|| SQLERRM);
END cap_defects;

PROCEDURE xx_rga_process( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       ) IS

  CURSOR c_rga_status IS
      SELECT *
        FROM apps.q_od_ob_rga_v a
       WHERE od_pb_approval_status = 'OPEN';


 conn 			utl_smtp.connection;
 v_email_list    	VARCHAR2(3000);
 v_cc_email_list	VARCHAR2(3000);
 v_text			VARCHAR2(3000);
 v_subject		VARCHAR2(3000);
 v_region_contact  	VARCHAR2(250);
 v_region		VARCHAR2(50);
 v_nextaudit_date	DATE;
 v_errbuf               VARCHAR2(2000);
 v_retcode              VARCHAR2(50);
 v_fqa_esc              VARCHAR2(150);
 v_instance             VARCHAR2(10);
 l_char21               VARCHAR2(150);         -- As per ver 1.2
 
 BEGIN
   SELECT name INTO v_instance FROM v$database;

   FOR cur IN c_rga_status LOOP
       v_text := NULL;

       v_text   :=v_text ||'RGA ID              : '||cur.od_ob_rga_id                 || chr(10);       
       v_text   :=v_text || 'SKU                : '||TO_CHAR(cur.od_ob_sku)           || chr(10);		
       v_text   :=v_text || 'Description        : '||TO_CHAR(cur.OD_ob_sku)           || chr(10);		
       v_text   :=v_text || 'Department         : '||TO_CHAR(cur.od_pb_item_desc)     || chr(10);		
       v_text   :=v_text || 'Vendor Name        : '||TO_CHAR(cur.od_ob_vendor_name)   || chr(10);       
       v_text   :=v_text || 'Sourcing Agent     : '||TO_CHAR(cur.od_sc_audit_agent)   || chr(10);		
       v_text   :=v_text || 'Sample Pickup Date : '||TO_CHAR(cur.od_sc_scheduled_date)|| chr(10);		
       v_text   :=v_text || 'Pickup Location    : '||TO_CHAR(cur.od_ob_pickup_location);		
       v_text   :=v_text ||chr(10);

       IF lc_send_mail = 'Y' THEN    
          v_email_list:= cur.od_pb_qa_engr_email;          
       ELSE       
          v_email_list    := 'padmanaban.sanjeevi@officedepot.com'; -- Modified for R12
	  v_cc_email_list := 'Fritz.Lutzy@officedepot.com';	  
       END IF;
  
       IF (SYSDATE - cur.od_pb_date_approved) > 30  AND NVL(cur.od_ob_engr_ntfy,'X') <> '30' THEN      -- Changed od_pb_date_approved logic to > 30 as per Ver 1.2       
           v_subject := 'RGA ID '||cur.od_ob_rga_id ||'Investigation is still open more than 30 days';
           
               IF v_instance<>'GSIPRDGB' THEN
                   v_subject:='Please Ignore this mail :'||v_subject;
               END IF;
           
           -- Calling Notifaction proc    
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
                                          , p_email_list    => v_email_list
                                          , p_cc_email_list => v_cc_email_list
                                          , p_text          => v_text
              				   );
              				   
           l_char21 := TRUNC(SYSDATE - cur.od_pb_date_approved);      --As per Ver  1.2
              

  	   UPDATE apps.qa_results  
              SET character21     = l_char21 --'30'        --As per Ver  1.2
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;
	      
-- Commneted as per  Ver 1.2 	      

      /* ELSIF (SYSDATE - cur.od_pb_date_approved) BETWEEN 45 AND 60
         AND NVL(cur.od_ob_engr_ntfy,'X') <> '45' THEN

           v_subject :='RGA ID '||cur.od_ob_rga_id ||'Investigation is still open more than 45 days';

           IF v_instance <> 'GSIPRDGB' THEN
	       v_subject:='Please Ignore this mail :'||v_subject;
           END IF;

           -- Calling Notifaction proc
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
                                          , p_email_list    => v_email_list
                                          , p_cc_email_list => v_cc_email_list
                                          , p_text          => v_text
                                          );


  	   UPDATE apps.qa_results  
              SET character21     = '45'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;

       ELSIF (SYSDATE - cur.od_pb_date_approved) > 60  
              AND NVL(cur.od_ob_engr_ntfy,'X') <> '60' THEN
           
           v_subject :='RGA ID '||cur.od_ob_rga_id ||'Investigation is still open more than 60 days';

           IF v_instance <>'GSIPRDGB' THEN
	      v_subject:= 'Please Ignore this mail :' || v_subject;
           END IF;
           
           -- Calling Notifaction proc
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
                                          , p_email_list    => v_email_list
                                          , p_cc_email_list => v_cc_email_list
                                          , p_text          => v_text
                                          );
                                          
  	   UPDATE apps.qa_results  
              SET character21     = '60'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;  */

       END IF;           

   END LOOP;
   COMMIT;
   -- Calling xx_create_cap proc
   xx_create_cap;
   cap_defects;
   COMMIT;
   
EXCEPTION
    WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data Found in xx_rga_process ');
  WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Raised IN xx_rga_process:::'|| SQLERRM);
  COMMIT;
  v_errbuf := 'Error in When others :'||SQLERRM;
  
  v_retcode := SQLCODE;
END XX_RGA_PROCESS;

END XX_QA_RGA_PKG;
/
SHOW ERRORS PACKAGE BODY XX_QA_RGA_PKG;
  
--EXIT;
