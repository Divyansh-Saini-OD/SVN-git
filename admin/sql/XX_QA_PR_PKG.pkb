SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_PR_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_PR_PKG.pkb      	   	               |
-- | Description :  OD QA PR Processing Pkg                            |
-- | Rice id     :  E3047                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       03-AUG-2011 Bapuji Nanapaneni  Initial version           |
-- |1.1       20-Jun-2013 Paddy Sanjeevi     Modified for R12          |
-- +===================================================================+
AS

PROCEDURE xx_create_pr IS

CURSOR c_create_pr IS
SELECT a.plan_id
     , a.collection_id
     , a.occurrence
     , a.organization_id
     , a.od_ob_prid
     , TO_CHAR(a.od_pb_date_verified,'DD-MON-YYYY') od_pb_date_verified
     , a.od_ob_pr_no
     , a.od_pb_protocol_name
     , a.od_pb_protocol_activity_type
     , a.od_pb_category
     , a.od_pb_company
     , a.od_sc_region
     , a.od_pb_auditor_name
     , a.od_pb_qa_engr_email
  FROM apps.q_od_ob_protocol_review_v a
 WHERE od_pb_date_renew IS NOT NULL
   AND SYSDATE > od_pb_date_renew
   AND NOT EXISTS (SELECT 'x'
		     FROM apps.q_od_ob_protocol_review_v
		    WHERE od_ob_ref_prid = a.od_ob_prid);

CURSOR c_pr_ntfy IS
SELECT *
  FROM apps.q_od_ob_protocol_review_v a
 WHERE NVL(OD_OB_PFD_NTFY,'X')<>'Y'
   AND EXISTS (SELECT 'x'
   		 FROM apps.q_od_ob_protocol_review_v
   		WHERE od_ob_ref_prid = a.od_ob_prid);

/* Local Variables Declaration */
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

   FOR cur IN c_create_pr LOOP

       i:=i+1;

       BEGIN

           INSERT INTO apps.q_od_ob_protocol_review_iv
               ( process_status
               , organization_code
               , plan_name
               , insert_type
	       , matching_elements
               , od_ob_ref_prid
               , od_pb_date_verified
               , od_ob_pr_no
               , od_pb_protocol_name
               , od_pb_protocol_activity_type
               , od_pb_category
               , od_pb_company
               , od_sc_region
               , od_pb_auditor_name
               , od_pb_qa_engr_email
               , qa_created_by_name
               , qa_last_updated_by_name
               )
               VALUES
               ( '1'
               , 'PRJ'
               , 'OD_OB_PROTOCOL_REVIEW'
               , '1' --1 for INSERT
               , 'OD_PB_PRID,OD_OB_PR_NO'
               , cur.OD_OB_PRID
               , cur.od_pb_date_verified
               , cur.od_ob_pr_no
               , cur.od_pb_protocol_name
               , cur.od_pb_protocol_activity_type
               , cur.od_pb_category
               , cur.od_pb_company
               , cur.od_sc_region
               , cur.od_pb_auditor_name
               , cur.od_pb_qa_engr_email
               , fnd_global.user_name
               , fnd_global.user_name
               );

       EXCEPTION
           WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others raised while inserting into q_od_ob_protocol_review_iv ');
	       NULL;
       END;

   END LOOP;
   COMMIT;
   IF i > 0 THEN
       v_request_id:= fnd_request.submit_request( application => 'QA'
                                                , program     => 'QLTTRAMB'
                                                , description => 'Collection Import Manager'
                                                , start_time  => NULL
                                                , sub_request => FALSE
                                                , argument1   => '200'
                                                , argument2   => '1'
                                                , argument3   => TO_CHAR(v_user_id)
                                                , argument4   => 'No'
                                                );
       IF v_request_id > 0 THEN
           COMMIT;
       END IF;

       IF (fnd_concurrent.wait_for_request( request_id  => v_request_id
                                          , interval    => 1
                                          , max_wait    => 60000
                                          , phase       => v_phase
                                          , status      => v_status
                                          , dev_phase   => v_dphase
                                          , dev_status  => v_dstatus
                                          , message     => x_dummy
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
	       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others raised while getting v_crequest_id :' ||SQLERRM);
	       v_crequest_id:=NULL;
       END;

       IF v_crequest_id IS NOT NULL THEN

           IF (fnd_concurrent.wait_for_request( request_id  => v_crequest_id
                                              , interval    => 1
                                              , max_wait    => 60000
                                              , phase       => v_phase
                                              , status      => v_status
                                              , dev_phase   => v_dphase
                                              , dev_status  => v_dstatus
                                              , message     => x_dummy
                                              )
                                              )  THEN

               IF v_dphase = 'COMPLETE' THEN
  	           dbms_output.put_line('success');
               END IF;
           END IF;

       END IF;

   END IF;

   FOR cur IN c_pr_ntfy LOOP

       v_subject := 'A Protocol Review has been created :'||cur.od_ob_prid;
       v_text    := 'A Protocol Review has been created :'||cur.od_ob_prid||'.'||' It has been 2 years since the last review. Please initiate review process'||chr(10);
       v_text    := v_text||chr(10);

       v_text    := v_text||'Region            :'||cur.od_sc_region                 ||chr(10);
       v_text    := v_text||'Start Date        :'||cur.od_pb_date_verified          ||chr(10);
       v_text    := v_text||'Approval Status   :'||cur.od_pb_approval_status        ||chr(10);
       v_text    := v_text||'Protocol ID       :'||cur.od_ob_pr_no                  ||chr(10);
       v_text    := v_text||'Protocol Name     :'||cur.od_pb_protocol_name          ||chr(10);
       v_text    := v_text||'Protocol Type     :'||cur.od_pb_protocol_activity_type ||chr(10);
       v_text    := v_text||'Product Category  :'||cur.od_pb_category               ||chr(10);
       v_text    := v_text||'SP Name           :'||cur.od_pb_company                ||chr(10);
     --  v_text    := v_text||'Submitter         :'||cur.od_pb_auditor_name           ||chr(10);
     --  v_text    := v_text||'Approver          :'||cur.od_pb_qa_engr_email          ||chr(10);
       v_text    := chr(10);

       IF lc_send_mail='Y' THEN
           v_email_list    := cur.od_pb_qa_engr_email||':'||cur.od_pb_auditor_name;
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

           UPDATE qa_results
              SET character20   = 'Y'
            WHERE plan_id       = cur.plan_id
              AND collection_id = cur.collection_id
              AND occurrence    = cur.occurrence;

   END LOOP;
   COMMIT;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data Found in xx_create_pr ');
   WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Raised xx_create_pr :::'|| SQLERRM);
END xx_create_pr;

PROCEDURE xx_pr_process( x_errbuf      OUT NOCOPY VARCHAR2
                       , x_retcode     OUT NOCOPY VARCHAR2
		       ) IS

   CURSOR c_pr_status IS  -- character16
       SELECT *
         FROM apps.q_od_ob_protocol_review_v a
        WHERE od_pb_approval_status IS NOT NULL;
          --AND NVL(od_ob_aprsts_ntfy,'X') NOT IN ('QY','AY','JY') ; --QY request, AY APPROVED, JY REJECT

   CURSOR c_pr_pending_request IS  -- character17
       SELECT *
         FROM q_od_ob_protocol_review_v a
        WHERE od_pb_approval_status = 'REQUEST'
          AND ( (sysdate-od_pb_date_requested) > 14
           OR   (sysdate-od_pb_date_requested) > 21
 	      );

   CURSOR c_new_pr IS
       SELECT *
         FROM apps.q_od_ob_protocol_review_v a
        WHERE OD_OB_PSSD_NTFY IS NULL;

/* Local Variables Declaration */
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

 BEGIN
   SELECT name INTO v_instance FROM v$database;

   FOR cur IN c_pr_status LOOP
       v_text := NULL;

       --v_text := 'A Protocol Review has been created :'||cur.od_ob_prid||chr(10);
       v_text := v_text||chr(10);

       v_text := v_text||'Region            :'||cur.od_sc_region                 ||chr(10);
       v_text := v_text||'Start Date        :'||cur.od_pb_date_verified          ||chr(10);
       v_text := v_text||'Approval Status   :'||cur.od_pb_approval_status        ||chr(10);
       v_text := v_text||'Protocol ID       :'||cur.od_ob_pr_no                  ||chr(10);
       v_text := v_text||'Protocol Name     :'||cur.od_pb_protocol_name          ||chr(10);
       v_text := v_text||'Protocol Type     :'||cur.od_pb_protocol_activity_type ||chr(10);
       v_text := v_text||'Product Category  :'||cur.od_pb_category               ||chr(10);
       v_text := v_text||'SP Name           :'||cur.od_pb_company                ||chr(10);

       IF lc_send_mail = 'Y' THEN
           v_email_list:= cur.od_pb_qa_engr_email;
       ELSE
           v_email_list    := 'padmanaban.sanjeevi@officedepot.com';  -- Modified for R12
	   v_cc_email_list := 'Fritz.Lutzy@officedepot.com';
       END IF;

       IF cur.od_pb_approval_status = 'APPROVED' AND NVL(cur.od_ob_aprsts_ntfy,'X') != 'AY' THEN

           IF v_instance<>'GSIPRDGB' THEN
	       v_subject:='Please Ignore this mail :'||v_subject;
           END IF;

           v_subject := 'Protocol Review ID '||cur.od_ob_prid ||' is Approved.';

           -- Calling Notifaction proc
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
                                          , p_email_list    => v_email_list
                                          , p_cc_email_list => v_cc_email_list
                                          , p_text          => v_text
                                          );
           UPDATE qa_results
              SET character16     = 'AY'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;

       ELSIF cur.od_pb_approval_status = 'REJECTED' AND NVL(cur.od_ob_aprsts_ntfy,'X') != 'JY' THEN

           IF v_instance <> 'GSIPRDGB' THEN
	       v_subject := 'Please Ignore this mail :'||v_subject;
           END IF;

           v_subject := 'Protocol Review ID '||cur.od_ob_prid ||' is Rejected.';

           -- Calling Notifaction proc
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
                                          , p_email_list    => v_email_list
                                          , p_cc_email_list => v_cc_email_list
                                          , p_text          => v_text
                                          );
           UPDATE qa_results
              SET character16     = 'JY'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;

       ELSIF cur.od_pb_approval_status = 'REQUEST' AND NVL(cur.od_ob_aprsts_ntfy,'X') != 'QY' THEN

           IF v_instance<>'GSIPRDGB' THEN
	       v_subject:='Please Ignore this mail :'||v_subject;
           END IF;

           v_subject := 'Protocol Review ID '||cur.od_ob_prid ||' is Requested.';

           v_text := v_text||chr(10);
           v_text := v_text||'Response is needed within 14 days or an escalation email will be sent';
           v_text := v_text||chr(10);

           -- Calling Notifaction proc
           xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
                                          , p_email_list    => v_email_list
                                          , p_cc_email_list => v_cc_email_list
                                          , p_text          => v_text
                                          );
           UPDATE qa_results
              SET character16     = 'QY'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;

       END IF;

   END LOOP;

   FOR cur IN c_pr_pending_request LOOP

       v_text := NULL;

       --v_text := 'A Protocol Review has been created :'||cur.od_ob_prid||chr(10);
       v_text := v_text||chr(10);

       v_text := v_text||'Region            :'||cur.od_sc_region                 ||chr(10);
       v_text := v_text||'Start Date        :'||cur.od_pb_date_verified          ||chr(10);
       v_text := v_text||'Approval Status   :'||cur.od_pb_approval_status        ||chr(10);
       v_text := v_text||'Protocol ID       :'||cur.od_ob_pr_no                  ||chr(10);
       v_text := v_text||'Protocol Name     :'||cur.od_pb_protocol_name          ||chr(10);
       v_text := v_text||'Protocol Type     :'||cur.od_pb_protocol_activity_type ||chr(10);
       v_text := v_text||'Product Category  :'||cur.od_pb_category               ||chr(10);
       v_text := v_text||'SP Name           :'||cur.od_pb_company                ||chr(10);

       IF lc_send_mail = 'Y' THEN
           v_email_list:= cur.od_pb_qa_engr_email;
       ELSE
           v_email_list    := 'padmanaban.sanjeevi@officedepot.com';  -- Modified for R12
	   v_cc_email_list := 'Fritz.Lutzy@officedepot.com';
       END IF;

       IF (SYSDATE - cur.od_pb_date_requested) BETWEEN 14 AND 21
       AND NVL(cur.od_ob_engr_ntfy,'X') <> '14' THEN

           v_subject := 'Protocol Review ID '||cur.od_ob_prid ||' is still open more than 14 days';

           v_text := v_text||chr(10);
           v_text := v_text||'A response has not been given this is an escalation email a response is needed within 7 days or an escalation email will be sent';
           v_text := v_text||chr(10);

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
              SET character15     = '14'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;

       ELSIF (SYSDATE - cur.od_pb_date_requested) > 21
         AND NVL(cur.OD_OB_REQNAPR_NTFY,'X') <> '21' THEN

           v_subject := 'Protocol Review ID '||cur.od_ob_prid ||' is still open more than 21 days';

           v_text := v_text||chr(10);
           v_text := v_text||'A response has not been given for 21 days, this is an escalation email.';
           v_text := v_text||chr(10);

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
              SET character17     = '21'
            WHERE plan_id         = cur.plan_id
              AND occurrence      = cur.occurrence
	      AND organization_id = cur.organization_id;

       END IF;

   END LOOP;
   FOR cur IN c_new_pr LOOP
       v_text := NULL;

       v_text := 'A Protocol Review has been created :'||cur.od_ob_prid||chr(10);
       v_text := v_text||chr(10);

       v_text := v_text||'Region            :'||cur.od_sc_region                 ||chr(10);
       v_text := v_text||'Start Date        :'||cur.od_pb_date_verified          ||chr(10);
       v_text := v_text||'Approval Status   :'||cur.od_pb_approval_status        ||chr(10);
       v_text := v_text||'Protocol ID       :'||cur.od_ob_pr_no                  ||chr(10);
       v_text := v_text||'Protocol Name     :'||cur.od_pb_protocol_name          ||chr(10);
       v_text := v_text||'Protocol Type     :'||cur.od_pb_protocol_activity_type ||chr(10);
       v_text := v_text||'Product Category  :'||cur.od_pb_category               ||chr(10);
       v_text := v_text||'SP Name           :'||cur.od_pb_company                ||chr(10);

       v_subject := 'A New Protocol Review has been created '|| cur.od_ob_prid||chr(10);

       IF lc_send_mail = 'Y' THEN
           v_email_list:= cur.od_pb_qa_engr_email;
       ELSE
           v_email_list    := 'padmanaban.sanjeevi@officedepot.com';  -- Modified for R12
	   v_cc_email_list := 'Fritz.Lutzy@officedepot.com';
       END IF;

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
         SET character19     = 'NEW'
       WHERE plan_id         = cur.plan_id
         AND occurrence      = cur.occurrence
         AND organization_id = cur.organization_id;


   END LOOP;

   xx_create_pr;
   COMMIT;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data Found in XX_PR_PROCESS ');
  WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others raised in XX_PR_PROCESS : '||SQLERRM);
  COMMIT;
  v_errbuf  := 'Error in When others :'||SQLERRM;
  v_retcode := SQLCODE;
END XX_PR_PROCESS;

END XX_QA_PR_PKG;
/
SHOW ERRORS PACKAGE BODY XX_QA_PR_PKG;
EXIT;
