CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_PB_TSKFLOW_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_PB_TSKFLOW_PKG                               |
-- | Description :  OD Private Brand Reports                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-Aug-2009 Paddy Sanjeevi     Initial version           |
-- |1.1       23-Dec-2009 Paddy Sanjeevi     Modified not initiate wf for parent task|
-- |1.2       08-Apr-2010 Paddy Sanjeevi     Replaced attribute1 with 9|
-- +===================================================================+
AS

PROCEDURE ABORT_XXPATNOT(  x_errbuf               OUT NOCOPY VARCHAR2
		                ,x_retcode              OUT NOCOPY VARCHAR2
      			   	,p_project_no	        IN  VARCHAR2
				,p_recreate     IN VARCHAR2
			      )
IS

 CURSOR C1 IS
 SELECT distinct a.item_key,c.project_id,c.segment1
   FROM apps.pa_wf_processes a,
	apps.pa_tasks b,
	apps.pa_projects_all c
  WHERE c.segment1=NVL(p_project_no,c.segment1)
    AND b.project_id=c.project_id
    AND a.entity_key2=to_char(b.task_id)
    AND a.item_type='XXPATNOT'
    AND a.entity_key1=to_char(b.project_id)
    AND EXISTS (SELECT 'x'
		  FROM apps.wf_item_activity_statuses
		 WHERE item_type=a.item_type
		   AND item_key=a.item_key
		   AND activity_status<>'COMPLETE');

 CURSOR C2 IS
 SELECT distinct a.project_id,a.segment1
   FROM apps.pa_project_statuses d, apps.pa_projects_all a 
  where a.template_flag='N'
    and d.project_status_code=a.project_status_code
    and d.project_status_name<>'Cancelled';

v_project_no varchar2(30);

BEGIN

  IF p_recreate='N' THEN
     FOR cur IN C1 LOOP
       v_project_no:=cur.segment1;
       -- now abort the process: dont specify the process so it defaults to the root
       Wf_Engine.AbortProcess(itemtype => 'XXPATNOT', itemkey=>cur.item_key);

       DELETE 
	 FROM apps.pa_wf_processes
	where item_type='XXPATNOT'
	  AND item_key=cur.item_key;

     END LOOP;
     COMMIT;
  ELSE
  
    FOR cur IN C2 LOOP

     APPS.XX_PA_PB_TSKFLOW_PKG.start_xxpatnot(cur.project_id);

    END LOOP;
  END IF;
EXCEPTION
  WHEN others THEN
    x_errbuf  := 'Unexpected error in Aborting XXPATNOT - '||SQLERRM||' ,'||v_project_no;
    x_retcode := 2;
END ABORT_XXPATNOT;

FUNCTION get_party_id(p_emp IN VARCHAR2) RETURN NUMBER
IS
v_party_id NUMBER;
BEGIN
 SELECT party_id
   INTO v_party_id
   FROM apps.per_all_people_f
  WHERE employee_number=p_emp;
  RETURN(v_party_id);
EXCEPTION
  WHEN others THEN
    RETURN(-1);
END get_party_id;


FUNCTION get_role(p_emp IN VARCHAR2,p_party_id IN NUMBER) RETURN VARCHAR2
IS

v_party_name varchar2(360);
v_email      varchar2(2000);
display_name                    VARCHAR2(2000);
email_address                   VARCHAR2(2000);
notification_preference         VARCHAR2(2000);
language                        VARCHAR2(2000);
territory                       VARCHAR2(2000);
v_emp				varchar2(60);

BEGIN
  v_emp:=p_emp;
  BEGIN
    select hp.party_name, hp.email_address
      INTO v_party_name,v_email
      from apps.fnd_user fu,
           apps.hz_parties hp
     where hp.party_id=p_party_id
       and fu.user_name=p_emp
        and fu.employee_id = Substr(hp.orig_system_reference, 5, Length(hp.orig_system_reference))
        AND 'PER:' = Substr(hp.orig_system_reference,1,4);
  EXCEPTION
    WHEN others THEN
       v_party_name:=NULL;
       v_email:=NULL;
  END;

  IF v_party_name IS NULL THEN
     BEGIN
       SELECT full_name,email_address
         INTO v_party_name,v_email
         FROM apps.per_all_people_f
        WHERE employee_number=p_emp;
     EXCEPTION
       WHEN others THEN
	 v_party_name:=NULL;
	 v_email:=NULL;
     END;
  END IF;

  wf_directory.getroleinfo(p_emp,
                              display_name,
                              email_address,
                              notification_preference,
                              language,
                              territory);
  IF display_name IS NULL THEN

     BEGIN	
     WF_DIRECTORY.CreateAdHocUser(  name => v_emp
                                  , display_name   => v_party_name
                                  , EMAIL_ADDRESS  => v_email);
     EXCEPTION
       WHEN others THEN
	RETURN('X');
     END;
  END IF;
  RETURN(p_emp);
EXCEPTION
  WHEN others THEN
    RETURN('X');
END get_role;

PROCEDURE start_xxpatnot(p_project_id IN NUMBER) 
IS

l_item_key      NUMBER;
l_err_code   	NUMBER;
l_err_stage  	VARCHAR2(30);
l_err_stack  	VARCHAR2(240);

CURSOR c_get_all_tasks IS
SELECT a.proj_element_id
  FROM apps.pa_proj_elements a,
       apps.pa_tasks b
 WHERE b.project_id=p_project_id
   AND a.project_id=b.project_id
   AND a.proj_element_id=b.task_id
   AND a.enable_wf_flag='Y'
   AND a.object_type='PA_TASKS'
   AND b.parent_task_id IS NOT NULL
   AND NOT EXISTS (SELECT 'x'
		     FROM apps.pa_wf_processes
		    WHERE item_type='XXPATNOT'
		      AND entity_key2=to_char(b.task_id)
		      AND entity_key1=to_char(b.project_id));
BEGIN
  FOR cur IN c_get_all_tasks LOOP

    l_item_key := null ;

    SELECT pa_workflow_itemkey_s.nextval
      INTO l_item_key
      FROM dual;

    wf_engine.createprocess(itemtype  => 'XXPATNOT',
                            itemkey   => to_char(l_item_key),
                            process   => 'XX_PA_PB_TASK_EXEC_FLOW'
                           );

    --update pa_wf_process_table

    PA_WORKFLOW_UTILS.INSERT_WF_PROCESSES
                       (  p_wf_type_code =>  'TASK_EXECUTION'
                         ,p_item_type    =>  'XXPATNOT'
                         ,p_item_key     =>  to_char(l_item_key)
                         ,p_entity_key1  =>  to_char(p_project_id)
                         ,p_entity_key2  =>  to_char(cur.proj_element_id)
                         ,p_description  =>  NULL
                         ,p_err_code     =>  l_err_code
                         ,p_err_stage    =>  l_err_stage
                         ,p_err_stack    =>  l_err_stack
                       );
  commit;
  wf_engine.startprocess('XXPATNOT',to_char(l_item_key));
  END LOOP;
  COMMIT;
END start_xxpatnot;

FUNCTION get_user_name(p_user_ID IN NUMBER) RETURN VARCHAR2
IS
V_user_name varchar2(30);
BEGIN
  SELECT employee_number
    INTO v_user_name
    FROM apps.per_all_people_f
   WHERE person_id=p_user_id;
  RETURN(v_user_name);
EXCEPTION
  WHEN others THEN
    v_user_name:=NULL;
    RETURN(v_user_name);
END get_user_name;


FUNCTION get_notify_user(p_proj_id IN NUMBER,p_task_id IN NUMBER,p_task_manager_id IN NUMBER) RETURN VARCHAR2
IS

l_role                          varchar2(30) := NULL;
l_role_display_name             per_all_people_f.full_name%TYPE; 
l_role_users                    varchar2(30000) := NULL;

v_emp			VARCHAR2(30);
v_prod_user        	VARCHAR2(30);
v_qa_user        	VARCHAR2(30);
v_compl_user        	VARCHAR2(30);
v_creat_user        	VARCHAR2(30);
v_vendr_user        	VARCHAR2(30);
v_dim_user		VARCHAR2(30);
v_ssvisor_user		VARCHAR2(30);
v_svisor_user		VARCHAR2(30);
v_task_manager		VARCHAR2(30);

v_prod_user_id        	NUMBER;
v_qa_user_id        	NUMBER;
v_compl_user_id        	NUMBER;
v_creat_user_id        	NUMBER;
v_vendr_user_id        	NUMBER;
v_dim_user_id		NUMBER;
v_ssvisor_user_id	NUMBER;
v_svisor_user_id	NUMBER;

vc_ssvisor_user_id	VARCHAR2(150);
vc_svisor_user_id	VARCHAR2(150);
vc_compl_user_id	VARCHAR2(150);
vc_creat_user_id	VARCHAR2(150);
vc_prod_user_id		VARCHAR2(150);
vc_qa_user_id		VARCHAR2(150);
vc_vendr_user_id	VARCHAR2(150);



V_prod_YN        	VARCHAR2(1);
v_qa_YN            	VARCHAR2(1);
v_compl_YN        	VARCHAR2(1);
v_creat_YN        	VARCHAR2(1);
v_vendr_YN        	VARCHAR2(1);
v_dim_YN		VARCHAR2(1);
v_ssvisor_YN		VARCHAR2(1);
v_svisor_YN		VARCHAR2(1);

v_task_receiver        VARCHAR2(300);
v_dependents	       VARCHAR2(50);
v_adhoc_user	       VARCHAR2(50);

v_party_id	       NUMBER;

v_wf_prod_user        	VARCHAR2(30);
v_wf_qa_user        	VARCHAR2(30);
v_wf_compl_user        	VARCHAR2(30);
v_wf_creat_user        	VARCHAR2(30);
v_wf_vendr_user        	VARCHAR2(30);
v_wf_dim_user		VARCHAR2(30);
v_wf_ssvisor_user		VARCHAR2(30);
v_wf_svisor_user		VARCHAR2(30);

v_role_cnt		NUMBER;

CURSOR C0 IS
SELECT c.employee_number,
       c.party_id
  FROM apps.per_all_people_f c,
       apps.pa_dependencies_v a ,
       apps.pa_proj_elements b
 WHERE b.project_id=p_proj_id
   and b.proj_element_id=p_task_id
   and a.dependency_type_code='SUC'
   and a.source_task_id=b.proj_element_id
   and c.person_id=a.task_manager_id;


CURSOR C1 IS
SELECT DISTINCT pb_wf_user 
  FROM (
SELECT c.employee_number pb_wf_user
  FROM apps.per_all_people_f c,
       apps.pa_dependencies_v a ,
       apps.pa_proj_elements b
 WHERE b.project_id=p_proj_id
   and b.proj_element_id=p_task_id
   and a.dependency_type_code='SUC'
   and a.source_task_id=b.proj_element_id
   and c.person_id=a.task_manager_id
UNION
SELECT v_wf_prod_user pb_wf_user from dual
UNION
SELECT v_wf_qa_user pb_wf_user from dual
UNION
SELECT v_wf_compl_user pb_wf_user from dual       	
UNION
SELECT v_wf_creat_user pb_wf_user from dual
UNION
SELECT v_wf_vendr_user pb_wf_user from dual
UNION
SELECT v_wf_dim_user pb_wf_user	from dual
UNION
SELECT v_wf_ssvisor_user pb_wf_user from dual
UNION
SELECT v_wf_svisor_user pb_wf_user from dual);

BEGIN

   l_role := 'NOTFY_XXPATNOT'||p_task_id;

   if l_role_display_name is null then
      l_role_display_name := l_role;
   end if;


   SELECT COUNT(1)
     INTO v_role_cnt
     FROM apps.wf_local_roles
    WHERE name=l_role;

   IF v_role_cnt=0 THEN
      WF_DIRECTORY.CreateAdHocRole( role_name         => l_role
                                 , role_display_name => l_role_display_name 
                                 , expiration_date   => null);
   END IF;


   FOR cur IN C0 LOOP

     v_emp:=XX_PA_PB_TSKFLOW_PKG.get_role(cur.employee_number,cur.party_id);

   END LOOP;

     BEGIN
       SELECT
	      attribute9  -- modified to replace attribute1 with attribute9
	     ,attribute2		
	     ,attribute4
	     ,attribute5
             ,attribute6
             ,attribute7
             ,attribute8
        INTO  vc_ssvisor_user_id
	     ,vc_svisor_user_id
	     ,vc_compl_user_id
             ,vc_creat_user_id
             ,vc_prod_user_id
             ,vc_qa_user_id
             ,vc_vendr_user_id
        FROM  apps.fnd_flex_values_vl fvl
             ,apps.fnd_flex_value_sets fv
       WHERE fv.flex_value_set_name='OD_PA_TASK_RESOURCE_ALLOCATION'
         AND fvl.flex_value_set_id=fv.flex_value_set_id
         AND fvl.description IN ( SELECT d.full_name
         		            FROM apps.fnd_user e,
                        		 apps.per_all_people_f d,
		                         apps.pa_project_role_types_vl c,
                		         apps.pa_project_parties b,
		                         apps.pa_projects_all a
                		   WHERE a.project_id=p_proj_id
		                     AND b.project_id=a.project_id
                      		     AND c.project_role_id=b.project_role_id
		                     AND c.project_role_type='PROJECT MANAGER'
                		     AND d.person_id=b.resource_source_id
              			     AND e.employee_id=d.person_id);
     EXCEPTION
    WHEN others THEN
      vc_compl_user_id:=NULL;
      vc_creat_user_id:=NULL;
      vc_prod_user_id:=NULL;
      vc_qa_user_id:=NULL;
      vc_vendr_user_id:=NULL;
      vc_ssvisor_user_id:=NULL;
      vc_svisor_user_id:=NULL;
     END;

	v_ssvisor_user_id:=TO_NUMBER(vc_ssvisor_user_id);
	v_svisor_user_id:=TO_NUMBER(vc_svisor_user_id);
	v_compl_user_id:=TO_NUMBER(vc_compl_user_id);
	v_creat_user_id:=TO_NUMBER(vc_creat_user_id);
	v_prod_user_id:=TO_NUMBER(vc_prod_user_id);
	v_qa_user_id:=	TO_NUMBER(vc_qa_user_id);
	v_vendr_user_id:=TO_NUMBER(vc_vendr_user_id);

    BEGIN
       SELECT d.person_id
         INTO v_dim_user_id
         FROM apps.fnd_user e,
              apps.per_all_people_f d,
              apps.pa_project_role_types_vl c,
              apps.pa_project_parties b,
              apps.pa_projects_all a
        WHERE a.project_id=p_proj_id
          AND b.project_id=a.project_id
          AND c.project_role_id=b.project_role_id
          AND c.project_role_type='PROJECT MANAGER'
          AND d.person_id=b.resource_source_id
          AND e.employee_id=d.person_id;
    EXCEPTION
      WHEN others THEN
        v_dim_user_id:=NULL;
    END;


     SELECT APPS.XX_PA_PB_TSKFLOW_PKG.get_user_name(v_ssvisor_user_id),
	    APPS.XX_PA_PB_TSKFLOW_PKG.get_user_name(v_svisor_user_id),
	    APPS.XX_PA_PB_TSKFLOW_PKG.get_user_name(v_dim_user_id),
	    APPS.XX_PA_PB_TSKFLOW_PKG.get_user_name(v_prod_user_id),
            APPS.XX_PA_PB_TSKFLOW_PKG.get_user_name(v_qa_user_id),
            APPS.XX_PA_PB_TSKFLOW_PKG.get_user_name(v_compl_user_id),
            APPS.XX_PA_PB_TSKFLOW_PKG.get_user_name(v_creat_user_id),
            APPS.XX_PA_PB_TSKFLOW_PKG.get_user_name(v_vendr_user_id),
            APPS.XX_PA_PB_TSKFLOW_PKG.get_user_name(p_task_manager_id)
       INTO v_ssvisor_user,v_svisor_user,v_dim_user,
	    v_prod_user,v_qa_user,v_compl_user,
	    v_creat_user,v_vendr_user,v_task_manager
       FROM dual;

     BEGIN
       SELECT NVL(attribute9,'N'),NVL(attribute2,'N'),NVL(attribute3,'N'),
	      NVL(attribute4,'N'),NVL(attribute5,'N'),NVL(attribute6,'N'),
	      NVL(attribute7,'N'),NVL(attribute8,'N')    
	 INTO v_ssvisor_YN,v_svisor_YN,v_dim_YN,v_prod_YN,v_qa_YN,v_vendr_YN,v_compl_YN,v_creat_YN
         FROM pa_tasks
        WHERE task_id=p_task_id;
     EXCEPTION
       WHEN others THEN
         v_prod_YN:=NULL;
         v_qa_YN:=NULL;
         v_compl_YN:=NULL;
         v_creat_YN:=NULL;
         v_vendr_YN:=NULL;    
	 v_ssvisor_YN:=NULL;
	 v_svisor_YN:=NULL;
	 v_dim_YN:=NULL;
     END;

     IF v_prod_YN='Y' THEN

        v_party_id:=apps.XX_PA_PB_TSKFLOW_PKG.get_party_id(v_prod_user);

        v_wf_prod_user:=APPS.XX_PA_PB_TSKFLOW_PKG.get_role(v_prod_user,v_party_id);

     END IF;

     IF v_qa_YN='Y' THEN

        v_party_id:=apps.XX_PA_PB_TSKFLOW_PKG.get_party_id(v_qa_user);

        v_wf_qa_user:=APPS.XX_PA_PB_TSKFLOW_PKG.get_role(v_qa_user,v_party_id);

     END IF;

     IF v_vendr_YN='Y' THEN

        v_party_id:=apps.XX_PA_PB_TSKFLOW_PKG.get_party_id(v_vendr_user);

        v_wf_vendr_user:=APPS.XX_PA_PB_TSKFLOW_PKG.get_role(v_vendr_user,v_party_id);

     END IF;

     IF v_compl_YN='Y' THEN

        v_party_id:=apps.XX_PA_PB_TSKFLOW_PKG.get_party_id(v_compl_user);

        v_wf_compl_user:=APPS.XX_PA_PB_TSKFLOW_PKG.get_role(v_compl_user,v_party_id);

     END IF;

     IF v_creat_YN='Y' THEN

        v_party_id:=apps.XX_PA_PB_TSKFLOW_PKG.get_party_id(v_creat_user);

        v_wf_creat_user:=APPS.XX_PA_PB_TSKFLOW_PKG.get_role(v_creat_user,v_party_id);

     END IF;

     IF v_ssvisor_YN='Y' THEN

        v_party_id:=apps.XX_PA_PB_TSKFLOW_PKG.get_party_id(v_ssvisor_user);

        v_wf_ssvisor_user:=APPS.XX_PA_PB_TSKFLOW_PKG.get_role(v_ssvisor_user,v_party_id);

     END IF;

     IF v_svisor_YN='Y' THEN

        v_party_id:=apps.XX_PA_PB_TSKFLOW_PKG.get_party_id(v_svisor_user);


        v_wf_svisor_user:=APPS.XX_PA_PB_TSKFLOW_PKG.get_role(v_svisor_user,v_party_id);

     END IF;

     IF v_dim_YN='Y' THEN
        v_party_id:=apps.XX_PA_PB_TSKFLOW_PKG.get_party_id(v_dim_user);

        v_wf_dim_user:=APPS.XX_PA_PB_TSKFLOW_PKG.get_role(v_dim_user,v_party_id);

     END IF;

     FOR CUR IN C1 LOOP

        if (l_role_users is not null) then
            l_role_users := l_role_users || ',';
        end if;

        v_adhoc_user:=cur.pb_wf_user;

        IF v_adhoc_user<>'X' THEN
           l_role_users:=l_role_users ||v_adhoc_user;
        ELSE
           l_role_users:=SUBSTR(l_role_users,1,length(l_role_users)-1);
        END IF;
     END LOOP;

	-- If there is not set up, then Task manager will get the notifications

     IF l_role_users IS NULL THEN
  	l_role_users:=v_task_manager;
     END IF;
     WF_DIRECTORY.AddUsersToAdHocRole( l_role, l_role_users);
     RETURN(l_role);
END get_notify_user;

PROCEDURE IS_TASK_STARTED (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
                	  )
IS

v_task_name         	varchar2(250);
v_task_no        	varchar2(100);
v_status              	varchar2(50);
v_ssdate                date;
v_sfdate		date;
v_task_manager_id	NUMBER;
v_project_id		NUMBER;
v_task_id		NUMBER;
v_key2			VARCHAR2(80);
v_project_name		VARCHAR2(30);
v_project_no		VARCHAR2(30);
BEGIN
  BEGIN
    SELECT entity_key2
      INTO v_key2
      FROM apps.pa_wf_processes
     WHERE wf_type_code='TASK_EXECUTION'
       AND item_type='XXPATNOT'
       AND item_key=p_itemkey;
  EXCEPTION
    WHEN others THEN
      v_key2:=NULL;
  END;
  IF v_key2 IS NOT NULL THEN
     BEGIN
       SELECT element_number,element_name,task_status_meaning,TRUNC(scheduled_start_date),
	      TRUNC(scheduled_finish_date),task_manager_id,project_id,proj_element_id,
	      project_name,project_number
         INTO v_task_no,v_task_name,v_status,v_ssdate,v_sfdate,v_task_manager_id,v_project_id,v_task_id,
	      v_project_name,v_project_no
         FROM apps.PA_STRUCTURES_TASKS_V
        WHERE proj_element_id=TO_NUMBER(v_key2)
          AND latest_eff_published_flag='Y'
          AND object_type = 'PA_TASKS';

      WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'PROJECT_NUMBER'
                                   ,avalue   => v_project_no);

      WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'PROJECT_NAME'
                                   ,avalue   => v_project_name);


      WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'TASK_NUMBER'
                                   ,avalue   => v_task_no);

 
      WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'TASK_NAME'
                                   ,avalue   => v_task_name);

      WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'TASK_STATUS'
                                   ,avalue   => v_status);

      WF_ENGINE.SetItemAttrDate(itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'START_DATE'
                                   ,avalue   => v_ssdate);

      WF_ENGINE.SetItemAttrDate(itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'FINISH_DATE'
                                   ,avalue   => v_sfdate);

      WF_ENGINE.SETITEMATTRNUMBER ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'TASK_MANAGER_ID'
                                   ,avalue   => v_task_manager_id);
      WF_ENGINE.SETITEMATTRNUMBER ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'PROJECT_ID'
                                   ,avalue   => v_project_id);

      WF_ENGINE.SETITEMATTRNUMBER ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'TASK_ID'
                                  ,avalue   => v_task_id);
     EXCEPTION
       WHEN others THEN
        v_status:='Not Started';
        v_ssdate:=SYSDATE+1;
     END;
  END IF;
  IF (v_status<>'Not Started' OR (v_status='Not Started' AND TRUNC(v_ssdate)<=TRUNC(SYSDATE))) THEN
       p_resultout:='Y';
  ELSE
       p_resultout:='N';
  END IF;

END IS_TASK_STARTED;

PROCEDURE IS_TASK_DUE (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
                )
IS

v_sfdate                date;
v_task_receiver         VARCHAR2(300);
v_task_manager_id	NUMBER;
v_status              	varchar2(50);
v_task_due_notified	varchar2(1);

BEGIN

  v_task_due_notified:= WF_ENGINE.GETITEMATTRTEXT ( itemtype => p_itemtype
                                        ,itemkey  => p_itemkey
                                        ,aname    => 'TASK_DUE_NOTIFIED');

  v_sfdate:=WF_ENGINE.GetItemAttrDate( itemtype => p_itemtype
            	                      ,itemkey  => p_itemkey
                	              ,aname    => 'FINISH_DATE');

  v_task_manager_id:=WF_ENGINE.GetItemAttrNumber( itemtype => p_itemtype
            	                      ,itemkey  => p_itemkey
                	              ,aname    => 'TASK_MANAGER_ID');

  v_status:= WF_ENGINE.GETITEMATTRTEXT ( itemtype => p_itemtype
                                        ,itemkey  => p_itemkey
                                        ,aname    => 'TASK_STATUS');


  IF (v_status<>'Completed' AND  TRUNC(SYSDATE)=TRUNC(v_sfdate)) THEN

--     IF NVL(v_task_due_notified,'N')='N' THEN

        V_task_receiver:=APPS.XX_PA_PB_TSKFLOW_PKG.get_user_name(v_task_manager_id);

        WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'TASK_INFO_RECEIVER'
                                   ,avalue   => v_task_receiver);

        WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'TASK_DUE_NOTIFIED'
                                   ,avalue   => 'Y');
        p_resultout:='Y';
  ELSE
    p_resultout:='N';
  END IF;
END IS_TASK_DUE;


PROCEDURE IS_NOTIFY_EMAIL (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
                )
IS

v_notify	varchar2(1);

BEGIN

  v_notify  := FND_PROFILE.VALUE('XX_PA_PB_SEND_EMAIL');  

  IF v_notify='Y' THEN

     p_resultout:='Y';

  ELSE

     p_resultout:='N';

  END IF;
END IS_NOTIFY_EMAIL;


PROCEDURE IS_MGR_TO_BE_NOTIFIED (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
                )
IS

v_ssdate                date;
v_task_receiver         VARCHAR2(300);
v_task_manager_id	NUMBER;
v_status              	varchar2(50);

BEGIN

  v_ssdate:=WF_ENGINE.GetItemAttrDate( itemtype => p_itemtype
            	                      ,itemkey  => p_itemkey
                	              ,aname    => 'START_DATE');

  v_task_manager_id:=WF_ENGINE.GetItemAttrNumber( itemtype => p_itemtype
            	                      ,itemkey  => p_itemkey
                	              ,aname    => 'TASK_MANAGER_ID');

  v_status:= WF_ENGINE.GETITEMATTRTEXT ( itemtype => p_itemtype
                                        ,itemkey  => p_itemkey
                                        ,aname    => 'TASK_STATUS');


  IF (v_status='Not Started' AND TRUNC(v_ssdate)<=TRUNC(SYSDATE)) THEN

    V_task_receiver:=APPS.XX_PA_PB_TSKFLOW_PKG.get_user_name(v_task_manager_id);

    WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'TASK_INFO_RECEIVER'
                                   ,avalue   => v_task_receiver);
    p_resultout:='Y';
  ELSE
    p_resultout:='N';
  END IF;

END IS_MGR_TO_BE_NOTIFIED;

PROCEDURE GET_TASK_STATUS  (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
                  )
IS

  v_task_name     	varchar2(250);
  v_task_no    		varchar2(100);
  v_status      	varchar2(50);
  v_edate    		date;
  v_key2		varchar2(80);

BEGIN

  BEGIN
    SELECT entity_key2
      INTO v_key2
      FROM apps.pa_wf_processes
     WHERE wf_type_code='TASK_EXECUTION'
       AND item_type='XXPATNOT'
       AND item_key=p_itemkey;
  EXCEPTION
    WHEN others THEN
      v_key2:=NULL;
  END;


  BEGIN
    SELECT element_number,element_name,task_status_meaning,actual_as_of_date
      INTO v_task_no,v_task_name,v_status,v_edate
      FROM apps.PA_STRUCTURES_TASKS_V
     WHERE proj_element_id=TO_NUMBER(v_key2)
       AND latest_eff_published_flag='Y'
       AND object_type = 'PA_TASKS';

      WF_ENGINE.SetItemAttrDate(itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'END_DATE'
                                   ,avalue   => v_edate);
  EXCEPTION
    WHEN others THEN
     v_status:=NULL;
  END;
  
  IF v_status='Completed' THEN
     p_resultout:='Y';
  ELSE
     p_resultout:='N';
  END IF;
END GET_TASK_STATUS;


PROCEDURE GET_TSK_FINISH_RECEIVER (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
                )
IS

v_task_receiver         VARCHAR2(300);
v_task_id        	NUMBER;
v_project_id        	NUMBER;
v_task_manager_id	NUMBER;
v_dep_tasks		VARCHAR2(2000);

CURSOR c1 IS
SELECT  element_name||' | '|| task_manager||';' dtask_owner
  FROM apps.pa_dependencies_v 
 WHERE source_task_id=v_task_id 
   AND dependency_type_code='SUC';


BEGIN

 v_project_id:=WF_ENGINE.GetItemAttrNumber( itemtype => p_itemtype
            	                      ,itemkey  => p_itemkey
                	              ,aname    => 'PROJECT_ID');


 v_task_id:=WF_ENGINE.GetItemAttrNumber( itemtype => p_itemtype
            	                      ,itemkey  => p_itemkey
                	              ,aname    => 'TASK_ID');

 v_task_manager_id:=WF_ENGINE.GetItemAttrNumber( itemtype => p_itemtype
            	                      ,itemkey  => p_itemkey
                	              ,aname    => 'TASK_MANAGER_ID');

 V_task_receiver:=APPS.XX_PA_PB_TSKFLOW_PKG.get_notify_user(v_project_id,v_task_id,v_task_manager_id);
    
 FOR cur IN C1 LOOP
    v_dep_tasks:=v_dep_tasks||cur.dtask_owner;
 END LOOP;

    WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'DEPENDENT_TASKS_OWNERS'
                                   ,avalue   => v_dep_tasks);

    WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'TASK_FINISH_INFO_RECEIVER'
                                   ,avalue   => v_task_receiver);
  p_resultout:='COMPLETE:';

END GET_TSK_FINISH_RECEIVER;
END XX_PA_PB_TSKFLOW_PKG;
/
