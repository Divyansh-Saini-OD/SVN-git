CREATE OR REPLACE PACKAGE BODY XX_DBA_WFROLE_ASSIGN_PKG AS
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                            Providge                                      |
-- +==========================================================================+
-- | Name             :    XX_DBA_WFROLE_ASSIGN_PKG                           |
-- | Description      :    Package for assign roles                           |
-- | RICE             :    E3078                                              |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      3-Nov-2013   Paddy Sanjeevi      Initial                        |
-- | 1.1     13-May-2014   Paddy Sanjeevi      Defect 29910                   |
-- | 1.4     30-Oct-2015   Madhu Bolli         122 Retrofit - Remove schema   |
-- +==========================================================================+

PROCEDURE assign_roles        ( p_errbuf   		IN OUT    VARCHAR2
                               ,p_retcode  		IN OUT    NUMBER	
                               ,p_role_name 		IN 	  VARCHAR2
	                       ,p_email_list           	IN 	  VARCHAR2
			       ,p_cc_mail		IN        VARCHAR2
                              )
IS

v_role_name	VARCHAR2(320):=NVL(p_role_name,'UMX|OD_VIEW_REQUEST_ROLE');

CURSOR C1(p_role VARCHAR2) IS
SELECT  user_name
  FROM  fnd_user a
 WHERE length(user_name)<10 
   and end_date IS NULL
   AND NOT EXISTS (SELECT 'x'
		     FROM wf_user_role_assignments
		    WHERE user_name=a.user_name
		      AND role_name=p_role
		  );


CURSOR c_reprocess(p_role VARCHAR2) IS
SELECT user_name
  FROM xx_dba_wf_role_assign a
 WHERE process_flag='P'
   AND NOT EXISTS (SELECT 'x'
		     FROM wf_user_role_assignments
		    WHERE user_name=a.user_name
		      AND role_name=p_role
		  );

CURSOR c_error IS
SELECT user_name||' '||error_message usererror
  FROM xx_dba_wf_role_assign
 WHERE process_Flag='N';


v_failed_count 		NUMBER:=0;
v_success_count 	NUMBER:=0;
v_total_count  		NUMBER:=0;
conn                  	utl_smtp.connection;
v_text			VARCHAR2(4000);
v_cnt			NUMBER:=0;
v_role_exception 	EXCEPTION;
v_error			VARCHAR2(2000);
BEGIN

  SELECT COUNT(1)
    INTO v_cnt
    FROM wf_roles
   WHERE name=v_role_name;

  IF v_cnt=0 THEN
  
     RAISE v_role_exception;
  
  END IF;

  UPDATE xx_dba_wf_role_assign
     SET process_flag='P';
  COMMIT;

  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Begin Reprocess failed Role assignments for :' ||v_role_name);

  FOR cur IN C_reprocess(v_role_name) LOOP

    v_error:=NULL;

    BEGIN
      wf_local_synch.PropagateUserRole(p_user_name => cur.user_name,
					    p_role_name => v_role_name,
					    p_start_date=>TRUNC(SYSDATE)
					   ); 
    EXCEPTION
      WHEN others THEN
	v_error:=SUBSTR(SQLERRM,1,360);
	INSERT 
	  INTO XX_DBA_WF_ROLE_ASSIGN
	       (user_name,
	        role_name,
		error_message,
	        creation_date,
		last_update_date,
		created_by,
		last_updated_by,
	        process_flag
	       )
        vALUES 
	       (cur.user_name,
	        v_role_name,
		v_error,
		sysdate,
		sysdate,
		fnd_global.user_id,
		fnd_global.user_id,
		'N'
	       );
    END;
  END LOOP;
  COMMIT;

  DELETE 
    FROM xx_dba_wf_role_assign
   WHERE process_flag='P';
  COMMIT;

  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Completed Reprocess failed Role assignments for :' ||v_role_name);

  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Begin Role assignments for :' ||v_role_name);

  FOR cur IN C1(v_role_name) LOOP

    v_error:=NULL;

    v_total_count:=v_total_count+1;

    BEGIN
      wf_local_synch.PropagateUserRole(p_user_name => cur.user_name,
					    p_role_name => v_role_name,
					    p_start_date=>TRUNC(SYSDATE)
					   ); 
      v_success_count:=v_success_count+1;
    EXCEPTION
      WHEN others THEN

        v_failed_count:=v_failed_count+1;
	v_error:=SUBSTR(SQLERRM,1,360);

	INSERT 
	  INTO XX_DBA_WF_ROLE_ASSIGN
	       (user_name,
	        role_name,
		error_message,
	        creation_date,
		last_update_date,
		created_by,
		last_updated_by,
	        process_flag
	       )
        vALUES 
	       (cur.user_name,
	        v_role_name,
		v_error,
		sysdate,
		sysdate,
		fnd_global.user_id,
		fnd_global.user_id,
		'N'
	       );
    END;
    COMMIT;

  END LOOP;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Completed Role assignments for :' ||v_role_name);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Total User Role Assignments :' ||TO_CHAR(v_total_count));
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Total User Success Role Assignments :' ||TO_CHAR(v_success_count));
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Total User Failed Role Assignments :' ||TO_CHAR(v_failed_count));

  v_failed_count:=0;

  IF p_email_list IS NOT NULL THEN


     v_text:='Success User Role Assignments :'||TO_CHAR(v_success_count);
     v_text:=v_text||CHR(10);

     v_text:=v_text||'Failed Role Assignments for the users Below';
     v_text:=v_text||CHR(10);


     FOR c IN c_error LOOP

	v_failed_count:=v_failed_count+1;

	v_text:=v_text||c.usererror||chr(10);

     END LOOP;

     v_text:=v_text||chr(10);
     v_text:=v_text||chr(10);
     v_text:=v_text||'No Action needed, system will resubmit the errors in the next run, this is for FYI notification';

     -- Defect 29910 Sending mail only if error occurs
	
     IF v_failed_count>0 THEN

        conn := xx_pa_pb_mail.begin_mail( sender 	=> 'wfroleassignments@officedepot.com'
                                        , recipients    => p_email_list
                                        , cc_recipients => p_cc_mail
                                        , subject       => 'List of Failed User Role Assignments'
                                        , mime_type     => xx_pa_pb_mail.MULTIPART_MIME_TYPE
                                        );

        xx_pa_pb_mail.attach_text( conn      => conn
                                  ,data      => v_text
                                  ,mime_type => 'multipart/html'
                                 );

        xx_pa_pb_mail.end_mail( conn => conn );

     END IF;

  END IF;

EXCEPTION
  WHEN v_role_exception THEN
    p_errbuf:='Role was not setup :'||p_role_name;
    p_retcode:=2;
   WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while Processing Role Assignments');
    FND_FILE.PUT_LINE(FND_FILE.LOG, SQLERRM);
END assign_roles;

END XX_DBA_WFROLE_ASSIGN_PKG;
/
