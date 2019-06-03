create or replace
PACKAGE BODY      XX_QA_VN_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_VN_PKG.pkb      	   	               |
-- | Description :  OD QA VN Processing Pkg                            |
-- | Rice id     :  E3002                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       03-AUG-2011 Bapuji Nanapaneni  Initial version           |
-- |1.1       15-Feb-2012 Paddy Sanjeevi     Modified for defect 16978 |
-- |1.2       25-feb-2013 Saritha Mummaneni  Modified for Defect# 21229|
-- |1.3       20-Jun-2013 Paddy Sanjeevi     Modified for R12          |
-- +===================================================================+
AS

PROCEDURE xx_vn_process( x_errbuf      OUT NOCOPY VARCHAR2
                       , x_retcode     OUT NOCOPY VARCHAR2
		       ) IS

CURSOR c_vn_status IS
   SELECT *
     FROM apps.q_od_ob_vn_v a
    WHERE od_pb_approval_status IS NOT NULL;

CURSOR c_engr_status IS
   SELECT *
     FROM apps.q_od_ob_vn_v a
    WHERE od_pb_approval_status LIKE 'Eng%'
      AND (SYSDATE - od_ob_fd_date) > 1;

CURSOR c_dir_status IS
   SELECT *
     FROM apps.q_od_ob_vn_v a
    WHERE od_pb_approval_status like 'Dire%'
      AND (SYSDATE - od_pb_date_opened) > 1;
         
CURSOR c_verify_date IS
   SELECT *
     FROM apps.q_od_ob_vn_v a
    WHERE od_pb_approval_status like 'Approved%'
      AND (SYSDATE-od_pb_date_approved) > 14
      AND od_pb_date_verified IS NULL;

CURSOR c_pen_status IS                                 -- Added the cursor as per Ver 1.2
   SELECT *
     FROM apps.q_od_ob_vn_v a
    WHERE od_pb_approval_status like 'Pen%'
       AND (SYSDATE - od_pb_date_approved) > 14;
      


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
 v_director		VARCHAR2(150); 
 l_char25		VARCHAR2(150);     -- As per Ver 1.2
 l_char24		VARCHAR2(150);     -- As per Ver 1.2
 l_char26		VARCHAR2(150);     -- As per Ver 1.2
 l_char29		VARCHAR2(150);     -- As per Ver 1.2
 
 BEGIN
 
   SELECT name INTO v_instance FROM v$database;

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

   FOR cur IN c_verify_date LOOP
       v_text := NULL;
   
       v_text   :=v_text ||'VN ID               : '||cur.od_ob_vnid                   || chr(10);       
       v_text   :=v_text ||'QA Activity ID      : '||TO_CHAR(cur.od_ob_activity_id)   || chr(10);
       v_text   :=v_text || 'Vendor Name        : '||cur.od_ob_vendor_name            || chr(10);  
       v_text   :=v_text || 'Factory Name       : '||cur.od_ob_factory_name           || chr(10);
       v_text   :=v_text || 'SKU                : '||TO_CHAR(cur.od_ob_sku)           || chr(10);		
       v_text   :=v_text || 'Description        : '||TO_CHAR(cur.OD_ob_sku)           || chr(10);
       v_text   :=v_text || 'Defect Summary     : '||cur.od_pb_defect_sum             || chr(10);
       v_text   :=v_text || 'Reason for VN      : '||cur.od_ob_reason                 || chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||'This is an escalation email';
       v_text   :=v_text ||chr(10);

   
      -- IF  NVL(cur.od_ob_mpsd_ntfy,'X') <> 'VY' THEN           -- Commented as per Ver 1.2    
           IF lc_send_mail = 'Y' THEN    
               v_email_list:= cur.od_pb_qa_engr_email ;--||':'||cur.od_pb_auditor_name;   -- Commented as escalation mail should be received by approver as per Ver 1.2        
           ELSE       
               v_email_list    := 'padmanaban.sanjeevi@officedepot.com';  -- Modified for R12
	       v_cc_email_list := 'Fritz.Lutzy@officedepot.com';	  
           END IF;
           
           v_subject := 'VN ID '||cur.od_ob_vnid ||'Verification has not been completed!';
              
           IF v_instance<>'GSIPRDGB' THEN
               v_subject:='Please Ignore this mail :'||v_subject;
           END IF;
              
           -- Calling Notifaction proc    
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
	                                  , p_email_list    => v_email_list
	                                  , p_cc_email_list => v_cc_email_list
	                                  , p_text          => v_text
                                          );
           BEGIN                                              -- As per Ver 1.2
           
             SELECT  character26 INTO l_char26             -- As per Ver 1.2
               FROM apps.qa_results
              WHERE plan_id         = cur.plan_id
                AND occurrence      = cur.occurrence
   	        AND organization_id = cur.organization_id;
   	        
   	   IF  NVL(l_char26,'X') <> 'VY' THEN             -- As per Ver 1.2
   	       
   	       
     	   UPDATE apps.qa_results  
              SET character26     = 'VY'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
   	      AND organization_id = cur.organization_id;
          END IF; 
	  EXCEPTION                                           -- As per Ver 1.2
	   WHEN OTHERS THEN	  
	   NULL;
	  END;	  
   	      
     --  END IF;                                   -- Commented as per Ver 1.2    
   
   END LOOP;


   FOR cur IN c_dir_status LOOP

       v_text := NULL;
   
       v_text   :=v_text ||'VN ID               : '||cur.od_ob_vnid                   || chr(10);       
       v_text   :=v_text ||'QA Activity ID      : '||TO_CHAR(cur.od_ob_activity_id)   || chr(10);
       v_text   :=v_text || 'Vendor Name        : '||cur.od_ob_vendor_name            || chr(10);  
       v_text   :=v_text || 'Factory Name       : '||cur.od_ob_factory_name           || chr(10);
       v_text   :=v_text || 'SKU                : '||TO_CHAR(cur.od_ob_sku)           || chr(10);		
       v_text   :=v_text || 'Description        : '||TO_CHAR(cur.OD_ob_sku)           || chr(10);
       v_text   :=v_text || 'Defect Summary     : '||cur.od_pb_defect_sum             || chr(10);
       v_text   :=v_text || 'Reason for VN      : '||cur.od_ob_reason                 || chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||chr(10);

       v_text   :=v_text ||'This is an escalation mail'|| chr(10);

   
      -- IF  NVL(cur.od_ob_reqnapr_ntfy,'X') <> 'DY' THEN      -- Commented as per Ver 1.2      

           IF lc_send_mail = 'Y' THEN    

               v_email_list    :=v_director;
	      -- v_cc_email_list :=cur.od_pb_qa_engr_email||':'||cur.od_pb_auditor_name;    -- Commented as per Ver 1.2      

           ELSE       
               v_email_list    := 'padmanaban.sanjeevi@officedepot.com'; -- Modified for R12
	       v_cc_email_list := 'Fritz.Lutzy@officedepot.com';	  
           END IF;   
           v_subject := 'VN ID '||cur.od_ob_VNid ||'has been sent for QA Director Approval';
              
           IF v_instance<>'GSIPRDGB' THEN
               v_subject:='Please Ignore this mail :'||v_subject;
           END IF;
              
           -- Calling Notifaction proc    
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
	                                  , p_email_list    => v_email_list
	                                  , p_cc_email_list => v_cc_email_list
	                                  , p_text          => v_text
                                          );

          BEGIN                                          -- As per Ver 1.2
            
           SELECT character29 INTO l_char29                -- As per Ver 1.2
             FROM apps.qa_results
            WHERE plan_id     = cur.plan_id
	      AND occurrence      = cur.occurrence
   	      AND organization_id = cur.organization_id;
   	     
   	   IF    NVL(l_char29,'X') <> 'DY' THEN             -- As per Ver 1.2
            
   
     	   UPDATE apps.qa_results  
              SET character29     = 'DY'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
   	      AND organization_id = cur.organization_id;
           END IF; 
   	  EXCEPTION                                           -- As per Ver 1.2
	  WHEN OTHERS THEN	  
	  NULL;
	  END;	     	      
  --     END IF;                      -- Commented as per Ver 1.2 
   
   END LOOP;

   FOR cur IN c_engr_status LOOP
   
       v_text := NULL;
   
       v_text   :=v_text ||'VN ID               : '||cur.od_ob_vnid                   || chr(10);       
       v_text   :=v_text ||'QA Activity ID      : '||TO_CHAR(cur.od_ob_activity_id)   || chr(10);
       v_text   :=v_text || 'Vendor Name        : '||cur.od_ob_vendor_name            || chr(10);  
       v_text   :=v_text || 'Factory Name       : '||cur.od_ob_factory_name           || chr(10);
       v_text   :=v_text || 'SKU                : '||TO_CHAR(cur.od_ob_sku)           || chr(10);		
       v_text   :=v_text || 'Description        : '||TO_CHAR(cur.OD_ob_sku)           || chr(10);
       v_text   :=v_text || 'Defect Summary     : '||cur.od_pb_defect_sum             || chr(10);
       v_text   :=v_text || 'Reason for VN      : '||cur.od_ob_reason                 || chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||chr(10);
       v_text   :=v_text ||chr(10);
              
       v_text   :=v_text ||'This is an escalation mail'|| chr(10);

      -- IF  NVL(cur.od_ob_engr_ntfy,'X') <> 'EY' THEN        -- Commented as per Ver 1.2   
           IF lc_send_mail = 'Y' THEN    
               v_email_list:= cur.od_pb_qa_engr_email;--||':'||cur.od_pb_auditor_name;        -- Commented as escalation mail should be received by approver as per Ver 1.2 
           ELSE       
               v_email_list    := 'padmanaban.sanjeevi@officedepot.com';  -- Modified for R12
	       v_cc_email_list := 'Fritz.Lutzy@officedepot.com';	  
           END IF;   
           v_subject := 'VN ID '||cur.od_ob_vnid ||'has been completed and uploaded to Oracle for your review.';
              
           IF v_instance<>'GSIPRDGB' THEN
               v_subject:='Please Ignore this mail :'||v_subject;
           END IF;
              
           -- Calling Notifaction proc    
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
	                                  , p_email_list    => v_email_list
	                                  , p_cc_email_list => v_cc_email_list
	                                  , p_text          => v_text
                                          );

          BEGIN                                       -- As per Ver 1.2
          
            SELECT  character25  INTO l_char25          -- Added as per Ver 1.2
              FROM  apps.qa_results
             WHERE plan_id         = cur.plan_id
               AND occurrence      = cur.occurrence
   	       AND organization_id = cur.organization_id;
   	      
   	      IF NVL(l_char25,'X') <> 'EY' THEN              -- As per Ver 1.2
              
   
     	   UPDATE apps.qa_results  
              SET character25     = 'EY'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
   	      AND organization_id = cur.organization_id;
   	      
   	    END IF; 
   	  EXCEPTION                                           -- As per Ver 1.2
	  WHEN OTHERS THEN	  
	  NULL;
	  END;	  
    --   END IF;                    -- Commented as per Ver 1.2 
   
   END LOOP;

---- Added cursor Logic as per Ver 1.2
  FOR cur IN c_pen_status LOOP
  
         v_text := NULL;
     
         v_text   :=v_text ||'VN ID               : '||cur.od_ob_vnid                   || chr(10);       
         v_text   :=v_text ||'QA Activity ID      : '||TO_CHAR(cur.od_ob_activity_id)   || chr(10);
         v_text   :=v_text || 'Vendor Name        : '||cur.od_ob_vendor_name            || chr(10);  
         v_text   :=v_text || 'Factory Name       : '||cur.od_ob_factory_name           || chr(10);
         v_text   :=v_text || 'SKU                : '||TO_CHAR(cur.od_ob_sku)           || chr(10);		
         v_text   :=v_text || 'Description        : '||TO_CHAR(cur.OD_ob_sku)           || chr(10);
         v_text   :=v_text || 'Defect Summary     : '||cur.od_pb_defect_sum             || chr(10);
         v_text   :=v_text || 'Reason for VN      : '||cur.od_ob_reason                 || chr(10);
         v_text   :=v_text ||chr(10);
         v_text   :=v_text ||chr(10);
  
         v_text   :=v_text ||'This is an escalation mail'|| chr(10);   
  
             IF lc_send_mail = 'Y' THEN    
  
               v_email_list    := cur.od_pb_qa_engr_email;--||':'||cur.od_pb_auditor_name;        -- Commented as escalation mail should be received by approver as per Ver 1.2 
             ELSE       
                 v_email_list    := 'padmanaban.sanjeevi@officedepot.com'; -- Modified for R12
  	       v_cc_email_list := 'Fritz.Lutzy@officedepot.com';	  
             END IF;   
             v_subject := 'VN ID '||cur.od_ob_VNid ||'Is currently Pending Activity';
                
             IF v_instance<>'GSIPRDGB' THEN
                 v_subject:='Please Ignore this mail :'||v_subject;
             END IF;
                
             -- Calling Notifaction proc    
             xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
  	                                  , p_email_list    => v_email_list
  	                                  , p_cc_email_list => v_cc_email_list
  	                                  , p_text          => v_text
                                            );
  
            BEGIN                                          
              
             SELECT character24 INTO l_char24               
               FROM apps.qa_results
              WHERE plan_id     = cur.plan_id
  	      AND occurrence      = cur.occurrence
     	      AND organization_id = cur.organization_id;
     	     
     	   IF    NVL(l_char24,'X') <> 'PY' THEN             
              
     
       	   UPDATE apps.qa_results  
                SET character30     = 'PY'
              WHERE plan_id         = cur.plan_id
                AND occurrence      = cur.occurrence
     	      AND organization_id = cur.organization_id;
             END IF; 
     	  EXCEPTION                                           
  	  WHEN OTHERS THEN	  
  	  NULL;
  	  END;	     	      
     
   END LOOP;
   
   -- End of cursor logic as per Ver 1.2
   

   FOR cur IN c_vn_status LOOP
       v_text := NULL;

       v_text   :=v_text ||'VN ID               : '||cur.od_ob_vnid                   || chr(10);       
       v_text   :=v_text ||'QA Activity ID      : '||TO_CHAR(cur.od_ob_activity_id)   || chr(10);
       v_text   :=v_text || 'Vendor Name        : '||cur.od_ob_vendor_name            || chr(10);  
       v_text   :=v_text || 'Factory Name       : '||cur.od_ob_factory_name           || chr(10);
       v_text   :=v_text || 'SKU                : '||TO_CHAR(cur.od_ob_sku)           || chr(10);		
       v_text   :=v_text || 'Description        : '||TO_CHAR(cur.OD_ob_sku)           || chr(10);
       v_text   :=v_text || 'Defect Summary     : '||cur.od_pb_defect_sum             || chr(10);
       v_text   :=v_text || 'Reason for VN      : '||cur.od_ob_reason                 || chr(10);
       v_text   :=v_text ||chr(10);


       IF lc_send_mail = 'Y' THEN    
          v_email_list:= cur.od_pb_qa_engr_email||':'||cur.od_pb_auditor_name;           
       ELSE       
          v_email_list    := 'padmanaban.sanjeevi@officedepot.com'; -- Modified for R12
	  v_cc_email_list := 'Fritz.Lutzy@officedepot.com';	  
       END IF;


       IF  cur.od_pb_approval_status like 'Eng%'  
           AND NVL(cur.od_ob_aprsts_ntfy,'X') <> 'EY' THEN          
           v_subject := 'VN ID '||cur.od_ob_vnid ||'has been completed and uploaded to Oracle for your review.';
           v_text   :=v_text ||chr(10);
           v_text   :=v_text ||chr(10);
           v_text   :=v_text ||'Response is needed within 1 day or an escalation email will be sent';
           v_text   :=v_text ||chr(10);
           
           
           IF v_instance<>'GSIPRDGB' THEN
               v_subject:='Please Ignore this mail :'||v_subject;
           END IF;
           
           -- Calling Notifaction proc    
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
	                                  , p_email_list    => v_email_list
	                                  , p_cc_email_list => v_cc_email_list
	                                  , p_text          => v_text
                                          );

  	   UPDATE apps.qa_results  
              SET character24     = 'EY'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;

       ELSIF  cur.od_pb_approval_status like 'Pen%'  
              AND NVL(cur.od_ob_aprsts_ntfy,'X') <> 'PY' THEN          

           v_subject := 'VN ID '||cur.od_ob_vnid ||'Is currently Pending Activity ';
           
           IF v_instance<>'GSIPRDGB' THEN
               v_subject:='Please Ignore this mail :'||v_subject;
           END IF;
           
           -- Calling Notifaction proc    
            xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
 	                                  , p_email_list    => v_email_list
 	                                  , p_cc_email_list => v_cc_email_list
 	                                  , p_text          => v_text
                                           );

  	   UPDATE apps.qa_results  
              SET character24     = 'PY'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;
	      
       ELSIF  cur.od_pb_approval_status like 'Direc%'  
              AND NVL(cur.od_ob_aprsts_ntfy,'X') <> 'DY' THEN          


	       IF lc_send_mail = 'Y' THEN    
        	  v_email_list:= v_director;
        	  v_cc_email_list:= cur.od_pb_qa_engr_email||':'||cur.od_pb_auditor_name;           

	       ELSE       
        	  v_email_list    := 'padmanaban.sanjeevi@officedepot.com'; -- Modified for R12
		  v_cc_email_list := 'Fritz.Lutzy@officedepot.com';	  
	       END IF;

           v_subject := 'VN ID '||cur.od_ob_vnid ||'has been sent for QA Director Approval';

           v_text   :=v_text ||chr(10);
           v_text   :=v_text ||'Response is needed within 1 day or an escalation email will be sent';
           v_text   :=v_text ||chr(10);

           IF v_instance<>'GSIPRDGB' THEN
               v_subject:='Please Ignore this mail :'||v_subject;
           END IF;
           
           -- Calling Notifaction proc    
            xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
 	                                  , p_email_list    => v_email_list
 	                                  , p_cc_email_list => v_cc_email_list
 	                                  , p_text          => v_text
                                           );

  	   UPDATE apps.qa_results  
              SET character24     = 'DY'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;
	      
       ELSIF  cur.od_pb_approval_status like 'Approved%'  
              AND NVL(cur.od_ob_aprsts_ntfy,'X') <> 'AY' THEN          

           v_subject := 'VN ID '||cur.od_ob_vnid ||'Has been Approved';
           
           IF v_instance<>'GSIPRDGB' THEN
               v_subject:='Please Ignore this mail :'||v_subject;
           END IF;
           
           -- Calling Notifaction proc    
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
	                                  , p_email_list    => v_email_list
	                                  , p_cc_email_list => v_cc_email_list
	                                  , p_text          => v_text
                                          );

  	   UPDATE apps.qa_results  
              SET character24     = 'AY'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;
	      
       ELSIF  cur.od_pb_approval_status like 'Reject%'  
              AND NVL(cur.od_ob_aprsts_ntfy,'X') <> 'JY' THEN          

           v_subject := 'VN ID '||cur.od_ob_vnid ||'Has been Rejected ';
           
           IF v_instance<>'GSIPRDGB' THEN
               v_subject:='Please Ignore this mail :'||v_subject;
           END IF;
           
           -- Calling Notifaction proc    
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
	                                  , p_email_list    => v_email_list
	                                  , p_cc_email_list => v_cc_email_list
	                                  , p_text          => v_text
                                          );

  	   UPDATE apps.qa_results  
              SET character24     = 'JY'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;
	      
       END IF;           
   END LOOP;
   COMMIT;
   
EXCEPTION
    WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data Found in xx_vn_process ');
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others raised in xx_vn_process : '||SQLERRM);
    commit;
    v_errbuf := 'Error in When others :'||SQLERRM;
    v_retcode := SQLCODE;
END xx_vn_process;

PROCEDURE create_vn_from_def( x_errbuf      OUT NOCOPY VARCHAR2
                            , x_retcode     OUT NOCOPY VARCHAR2
		            ) IS
		            
CURSOR C_DEF is
SELECT a.od_ob_vn_id         vn_id
     , a.od_ob_ds_id         ds_id
     , a.od_ob_ref_capid     cap_id
     , c.od_sc_region        region
     , c.od_ob_qa_id         act_id
     , c.od_ob_qa_act        act
     , c.od_pb_vendor_vpc    vpn
     , c.od_ob_sku           item
     , c.od_pb_item_desc     item_desc
     , c.od_pb_sc_dept_name  dept
     , c.od_ob_vendor_name   vendor
     , c.od_sc_factory_name  factory
     , c.od_sc_audit_agent   agent_name
     , c.od_pb_tech_rpt_num  rep_id
     , a.od_pb_defect_sum    def_summ
     , a.od_pb_auditor_name  submitter
     , a.od_pb_qa_engr_email approver
     , a.od_pb_date_verified ver_date
  FROM q_od_ob_cap_defects_v a
     , q_od_ob_cap_v c
 WHERE a.od_pb_attachment = 'Y'
   AND a.od_ob_vn_id IS NULL
   AND a.od_ob_ref_capid = c.od_pb_car_id
   AND NOT EXISTS (SELECT 1 FROM Q_OD_OB_VN_V B 
                    WHERE a.od_ob_ds_id = b.od_ob_vn_ds_id
                  ); 
                  
CURSOR c_cap_upd IS
SELECT c.plan_id
     , c.collection_id
     , c.occurrence
     , c.organization_id     
     , c.od_ob_ref_capid     cap_id
     , a.od_ob_vnid          vn_id
  FROM q_od_ob_vn_v a
     , q_od_ob_cap_defects_v c
 WHERE a.od_ob_vn_ds_id = c.od_ob_ds_id
   AND c.od_ob_vn_id IS NULL
   AND c.od_pb_attachment = 'Y';                 
                  
lc_ver_req             VARCHAR2(30)     := 'No';
v_errbuf               VARCHAR2(2000);
v_retcode              VARCHAR2(50);
v_phase		       VARCHAR2(100);
v_request_id           NUMBER;
v_crequest_id 	       NUMBER;
v_user_id	       NUMBER := fnd_global.user_id;
v_status	       VARCHAR2(100);
v_dphase	       VARCHAR2(100);
v_dstatus	       VARCHAR2(100);
x_dummy		       VARCHAR2(2000);
i                      NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('BEGIN');
    
    FOR r_def IN c_def LOOP
        i:=i+1;
        IF r_def.ver_date IS NOT NULL THEN 
            lc_ver_req := 'Yes';
        END IF;
        
        INSERT INTO apps.q_od_ob_vn_iv
                  ( process_status
	          , organization_code
	          , plan_name
	          , insert_type
	          , matching_elements
	          , od_ob_vnid
	          , od_ob_vn_date
	          , od_sc_region
	          , od_ob_vn_cap_id
	          , od_ob_activity_id
	          , od_ob_activity
	          , od_ob_vpn
	          , od_ob_sku
	          , od_pb_item_desc
	          , od_pb_sc_dept_name
	          , od_ob_vendor_name
	          , od_ob_factory_name
	          , od_pb_sourcing_agent
	          , od_pb_report_number
	          , od_ob_vn_ds_id
	          , od_pb_date_verified
	          , od_pb_verification_required
	          , od_pb_defect_sum
	          , od_pb_auditor_name
	          , od_pb_qa_engr_email
	          , qa_created_by_name
	          , qa_last_updated_by_name
	          )
	           VALUES
	          (
	            '1'
	          , 'PRJ'
	          , 'OD_OB_VN'
	          , '1' --1 for INSERT
	          , 'OD_OB_VNID,OD_OB_VN_DSID'
	          , r_def.vn_id
	          , SYSDATE
	          , r_def.region
	          , r_def.cap_id
	          , r_def.act_id
	          , r_def.act
	          , r_def.vpn
	          , r_def.item
	          , r_def.item_desc
	          , r_def.dept
	          , r_def.vendor
	          , r_def.factory
	          , r_def.agent_name
	          , r_def.rep_id
	          , r_def.ds_id
	          , r_def.ver_date
	          , lc_ver_req
	          , r_def.def_summ
	          , r_def.submitter
	          , r_def.approver
	          , fnd_global.user_name
	          , fnd_global.user_name
	          );
	          
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
	       ) THEN
	    
	        IF v_dphase = 'COMPLETE' THEN
	            dbms_output.put_line('success');
	        END IF;
	    END IF;
	
        END IF;
       
    END IF;
    
    FOR r_cap_upd IN c_cap_upd LOOP
    
        UPDATE qa_results
           SET character9     = r_cap_upd.vn_id
         WHERE plan_id        = r_cap_upd.plan_id
           AND collection_id  = r_cap_upd.collection_id
           AND occurrence     = r_cap_upd.occurrence;
           
    END LOOP;
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data Found in create_vn_from_def ');
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others raised in create_vn_from_def : '||SQLERRM);
        v_errbuf := 'Error in When others :'||SQLERRM;
        v_retcode := SQLCODE;
END create_vn_from_def;
END XX_QA_VN_PKG;
/
