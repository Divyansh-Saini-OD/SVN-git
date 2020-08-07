create or replace 
PACKAGE BODY XX_PA_MASS_ADJST_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name:  XX_PA_MASS_ADJST_PKG                                                               |
  -- |  Description:  PA Mass Upload Tool to mass-update projects in oracle.                      |
  -- |  Rice ID : E3072                                                                           |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         27-Sep-2013   Archana N.        Initial version                                |
  -- | 1.1         16-Oct-2013   Archana N.        Added org_id check while extracting as well as |
  -- |                                             uploading.                                     |
  -- | 1.2         31-Oct-2013   Archana N.        Added check to restrict project approval using |
  -- |                                             authorized responsibilties only.               |
  -- | 1.3         26-Nov-2013   Archana N.        Added pa_task_id parameter to be passed while  |
  -- |                                             populating tasks details.                      |
  -- | 1.4         12-Dec-2013	 Paddy Sanjeevi    Removed org_id condition (Defect  27169 )      |
  -- | 1.5         17-Nov-2015	 Harvinder Rakhra  Retrofit R12.2                                 |
  -- | 1.6         17- May-2016  Punita kumari     Replaced view HR_EMPLOYEES with table          |
  -- |                                             PER_ALL_PEOPLE_F for defect#37458              |
  -- +============================================================================================+
  --global declarations
  gn_request_id               NUMBER      :=0; --request_id of the upload program request
  gn_success                  NUMBER      :=0; --count of records processed successfully
  gn_failure                  NUMBER      :=0; --count of records failed for update
  gc_exception_flag           VARCHAR2(2) :='N'; --exception flag set for Mass Adjustments
  gc_project_reference PA_PROJECTS_ALL.pm_project_reference%TYPE;
  gc_resp_name                FND_RESPONSIBILITY_TL.RESPONSIBILITY_NAME%TYPE;

PROCEDURE LOAD_KEYM_FOR_UPDATE(p_project_number VARCHAR2,
    p_project_id IN NUMBER ,
    p_keym_in    IN OUT NOCOPY pa_project_pub.project_role_tbl_type)
IS
  --cursor to fetch keymember details provided for a given project
  CURSOR cur_keym_list
  IS
    SELECT DISTINCT employee_id,
      employee_number,
      role,
      role_start_date,
      role_end_date
    FROM XX_PA_MASS_ADJUST_UPLD_STG
    WHERE project_id=p_project_id
    AND employee_id IS NOT NULL --if valid employee id is not passed, keymembers are not populated to the composite variable
    AND status='I';
  lc_keym_rec cur_keym_list%ROWTYPE;
TYPE tbl_type_keym
IS
  TABLE OF cur_keym_list%ROWTYPE INDEX BY BINARY_INTEGER;
  tbl_keym tbl_type_keym;
  ln_keym_count NUMBER:=0;
  ln_person_id  NUMBER;
  ln_start_date DATE;
  ln_end_date DATE;
  ln_role VARCHAR2(30);
  i NUMBER:=0;
BEGIN
  OPEN cur_keym_list;
  FETCH cur_keym_list BULK COLLECT INTO tbl_keym;
  ln_keym_count:=cur_keym_list%ROWCOUNT;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Number of key members : '||ln_keym_count);
  FOR i IN tbl_keym.FIRST..tbl_keym.LAST --populate each keymember details to the composite variable
  LOOP
    p_keym_in(i).person_id        :=tbl_keym(i).employee_id;
    p_keym_in(i).start_date       :=tbl_keym(i).role_start_date;
    p_keym_in(i).end_date         :=tbl_keym(i).role_end_date;
    --Fetching role_type for the role provided.
    SELECT DISTINCT UPPER(TRIM(ppp.project_role_type))
    INTO p_keym_in(i).project_role_type
    FROM PA_PROJECT_PLAYERS ppp,
    PA_PROJECT_ROLE_TYPES_TL pprt,
    PA_PROJECT_ROLE_TYPES_B pprb
    WHERE ppp.project_role_type=pprb.project_role_type
    AND pprt.project_role_id=pprb.project_role_id
    AND UPPER(pprt.meaning)=UPPER(TRIM(tbl_keym(i).role))
    AND ppp.project_id=p_project_id;
  END LOOP;
CLOSE cur_keym_list;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL; --do nothing, pass Null values to the API
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception while loading key member details - '||SUBSTR (SQLERRM, 1, 225)||p_project_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Encountered exception while loading key member details.',
        conc_req_id        = gn_request_id
      WHERE project_id = p_project_id
      AND employee_id  = tbl_keym(i).employee_id;
      COMMIT;
      gc_exception_flag:='Y';
      RETURN;
END LOAD_KEYM_FOR_UPDATE;
PROCEDURE ASSIGN_ASSETS_FOR_UPDATE(
    p_project_number VARCHAR2,
    p_project_id     NUMBER)
IS
  --cursor to fetch task and asset details provided for a given project
  CURSOR cur_get_info
  IS
    SELECT DISTINCT task_number,
      task_id,
      assign_assets,
      project_asset_id
    FROM XX_PA_MASS_ADJUST_UPLD_STG
    WHERE project_id=p_project_id
    AND task_id    IS NOT NULL
    AND project_asset_id IS NOT NULL;
  ln_msg_count        NUMBER;
  lc_msg_data         VARCHAR2(8000);
  lc_return_status    VARCHAR2(1);
  ln_task_id          NUMBER;
  ln_project_asset_id_out NUMBER;
  lc_data            VARCHAR2(4000);
  ln_msg_index       NUMBER := 1;
  ln_msg_index_out   NUMBER;
  lc_sub_tasks_flag   VARCHAR2(2);
  lc_task_reference   PA_TASKS.PM_TASK_REFERENCE%TYPE;
BEGIN
  FOR tbl_stg_data IN cur_get_info LOOP
  BEGIN --inner block
    --check if the task has any sub-tasks, if yes do not call API for asset-assignment
    lc_sub_tasks_flag:='';
    SELECT DISTINCT 'N'
    INTO lc_sub_tasks_flag
    FROM pa_tasks
    WHERE NOT EXISTS (SELECT 1 FROM pa_tasks WHERE parent_task_id=tbl_stg_data.task_id);
    IF (lc_sub_tasks_flag='N') THEN --call API to assign asset to the task if the task does not have any sub-tasks.
    BEGIN --inner block4 --to fetch task_reference
    SELECT pm_task_reference
    INTO lc_task_reference
    FROM PA_TASKS
    WHERE task_id=tbl_stg_data.task_id
    AND project_id=p_project_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    NULL; --do nothing
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the task reference block- '||SUBSTR (SQLERRM, 1, 225)||p_project_number||'-'||tbl_stg_data.task_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Encountered exception while fetching task reference.',
        conc_req_id        = gn_request_id
      WHERE project_id = p_project_id
      AND task_id = tbl_stg_data.task_id
      AND project_asset_id=tbl_stg_data.project_asset_id;
      COMMIT;
      gc_exception_flag:='Y';
      END; --inner block4
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling ADD_ASSET_ASSIGNMENT API for project : '||p_project_number||' task :'||tbl_stg_data.task_number||' asset :'||tbl_stg_data.assign_assets);
    PA_PROJECT_ASSETS_PUB.add_asset_assignment( p_api_version_number => '1.0'
    ,p_commit => 'F'
    ,p_init_msg_list => 'T'
    ,p_msg_count => ln_msg_count
    ,p_msg_data => lc_msg_data
    ,p_return_status => lc_return_status
    ,p_pm_product_code => 'EJM'
    ,p_pa_project_id => p_project_id
    ,p_pa_task_id => tbl_stg_data.task_id
    ,p_pm_task_reference => lc_task_reference
    ,p_pa_project_asset_id => tbl_stg_data.project_asset_id
    ,p_pa_task_id_out =>ln_task_id
    ,p_pa_project_asset_id_out => ln_project_asset_id_out );
    IF lc_return_status = 'S' THEN
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status_mesg = status_mesg||'-'||'Asset assignment successful',
        conc_req_id        = gn_request_id
      WHERE project_id = p_project_id
      AND task_id      = tbl_stg_data.task_id
      AND project_asset_id = tbl_stg_data.project_asset_id;
      COMMIT;
    ELSE
      IF ln_msg_count>0 THEN
        FOR I       IN 1..LN_MSG_COUNT
        LOOP
          PA_INTERFACE_UTILS_PUB.GET_MESSAGES( P_MSG_DATA => LC_MSG_DATA,
          P_ENCODED => 'F',
          P_DATA => LC_DATA,
          P_MSG_COUNT => LN_MSG_COUNT,
          P_MSG_INDEX => LN_MSG_INDEX,
          P_MSG_INDEX_OUT => LN_MSG_INDEX_OUT);
        END LOOP;
      END IF;
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
      status_code        = 'Error',
      conc_req_id        = gn_request_id,
      status_mesg = status_mesg||'-'||'Asset assignment failed'||'-'||LC_DATA
      WHERE project_id = p_project_id
      AND task_id      = tbl_stg_data.task_id
      AND project_asset_id = tbl_stg_data.project_asset_id;
      COMMIT;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'PA_PROJECT_ASSETS_PUB.add_asset_assignment failed for task : '||tbl_stg_data.task_number||'-'|| lc_data);
    END IF;
  END IF; --closing loop for is-parent-task-check
EXCEPTION
WHEN NO_DATA_FOUND THEN --add message saying the task is not the lowest-level task
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Task provided is not the lowest level task , project : '||p_project_number||' task :'||tbl_stg_data.task_number);
  UPDATE XX_PA_MASS_ADJUST_UPLD_STG
    SET status_mesg=status_mesg||'-'||'Task provided is not the lowest level task'
    WHERE project_id = p_project_id
      AND task_id      = tbl_stg_data.task_id
      AND project_asset_id = tbl_stg_data.project_asset_id;
    COMMIT;
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception while assigning assets - '||SUBSTR (SQLERRM, 1, 225)||p_project_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Encountered exception while assigning assets.',
        conc_req_id        = gn_request_id
      WHERE project_id = p_project_id
      AND project_asset_id=ln_project_asset_id_out;
      COMMIT;
      gc_exception_flag:='Y';
      RETURN;
END; --inner block
END LOOP;
END ASSIGN_ASSETS_FOR_UPDATE;

PROCEDURE POPULATE_IDS(
    errbuff OUT NOCOPY VARCHAR2,
    retcode OUT NOCOPY NUMBER)
IS
  --cursor and variables for fetching project_id
  CURSOR cur_proj_count
  IS
    SELECT DISTINCT UPPER(TRIM(project_number)) project_number
    FROM XX_PA_MASS_ADJUST_UPLD_STG
    WHERE TRIM(project_number) IS NOT NULL
    AND status            ='I';
TYPE tbl_typ_proj_num
IS
  TABLE OF cur_proj_count%ROWTYPE INDEX BY BINARY_INTEGER;
  tbl_proj_num tbl_typ_proj_num;
  ln_project_id NUMBER(15):=0;
  ln_proj_count NUMBER    :=0;
  i             NUMBER    :=0;
  --cursor and variables for fetching task_id for each task in a given project
  CURSOR cur_tasks(proj_id NUMBER)
  IS
    SELECT task_number
    FROM XX_PA_MASS_ADJUST_UPLD_STG
    WHERE project_id=proj_id
    AND status          ='I'
    AND task_number    IS NOT NULL;
TYPE tbl_typ_tasks
IS
  TABLE OF cur_tasks%ROWTYPE INDEX BY BINARY_INTEGER;
  tbl_tasks tbl_typ_tasks;
  ln_task_id NUMBER(15):=0;
  j          NUMBER    :=0;
  ln_wbs_level PA_TASKS.wbs_level%TYPE:=0;
  --cursor and variables for fetching project_asset_id for each asset in a given project
  CURSOR cur_assets(proj_id NUMBER)
  IS
    SELECT DISTINCT assign_assets
    FROM XX_PA_MASS_ADJUST_UPLD_STG
    WHERE project_id=proj_id
    AND status          ='I'
    AND assign_assets  IS NOT NULL;
TYPE tbl_typ_assets
IS
  TABLE OF cur_assets%ROWTYPE INDEX BY BINARY_INTEGER;
  tbl_assets tbl_typ_assets;
  ln_proj_asset_id NUMBER(15):=0;
  k                NUMBER    :=0;
  --cursor and variables for fetching employee_id for each keymember in a given project
  CURSOR cur_keym(proj_id NUMBER)
  IS
    SELECT DISTINCT employee_number
    FROM XX_PA_MASS_ADJUST_UPLD_STG
    WHERE project_id =proj_id
    AND status           ='I'
    AND employee_number IS NOT NULL;
TYPE tbl_typ_keym
IS
  TABLE OF cur_keym%ROWTYPE INDEX BY BINARY_INTEGER;
  tbl_keym tbl_typ_keym;
  ln_employee_id NUMBER(15):=0;
  m              NUMBER    :=0;
  ln_org_id     NUMBER:=0;
BEGIN

  ln_org_id:=FND_GLOBAL.ORG_ID;

  --***populate project ids ***
  OPEN cur_proj_count;
  FETCH cur_proj_count BULK COLLECT INTO tbl_proj_num;
  IF (cur_proj_count%ROWCOUNT=0) THEN
    RETURN; --return back to main procedure
  END IF;

  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of distinct project numbers in staging table : '||cur_proj_count%ROWCOUNT);

  FOR indx IN tbl_proj_num.FIRST..tbl_proj_num.LAST
  LOOP    --for-each project_number loop
    BEGIN --inner block1 - populate project_id
      ln_proj_count:=cur_proj_count%ROWCOUNT;
      --fetch project id for each project number
      ln_project_id:=0;
      SELECT project_id
      INTO ln_project_id
      FROM PA_PROJECTS_ALL
      WHERE UPPER(segment1)=tbl_proj_num(indx).project_number;
      --AND org_id=ln_org_id;
      --populate the project_id column in the upload staging table
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET project_id      =ln_project_id
      WHERE UPPER(TRIM(project_number))=tbl_proj_num(indx).project_number;
      COMMIT;
      --***populate task ids***
      OPEN cur_tasks(ln_project_id);
      FETCH cur_tasks BULK COLLECT INTO tbl_tasks;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'count of tasks for project : '||tbl_proj_num(indx).project_number||' is : '||cur_tasks%ROWCOUNT);
      IF (cur_tasks%ROWCOUNT <> 0) THEN
        FOR j                IN 1..cur_tasks%ROWCOUNT
        LOOP    --for-each-task-within-project loop
          BEGIN --inner block3 - populate task_id
            ln_task_id:=0;
            ln_wbs_level:=0;
            SELECT task_id,wbs_level
            INTO ln_task_id,ln_wbs_level
            FROM PA_TASKS
            WHERE UPPER(task_number)=UPPER(TRIM(tbl_tasks(j).task_number))
            AND project_id   =ln_project_id;
            --populate the task_id column in the upload staging table
            UPDATE XX_PA_MASS_ADJUST_UPLD_STG
            SET task_id         =ln_task_id,
            attribute1  = ln_wbs_level
            WHERE project_id=ln_project_id
            AND UPPER(task_number)     =UPPER(tbl_tasks(j).task_number);
            COMMIT;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Task number provided is invalid :'||tbl_tasks(j).task_number||', project : '||tbl_proj_num(indx).project_number);
            UPDATE XX_PA_MASS_ADJUST_UPLD_STG
            SET status_mesg        = status_mesg||'-'||'Task number provided is invalid.',
              conc_req_id        = gn_request_id
            WHERE project_id = ln_project_id
            AND task_number      =tbl_tasks(j).task_number;
            COMMIT;
          END; --inner block3
        END LOOP;
        CLOSE cur_tasks;
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'No task updates for project - '||tbl_proj_num(indx).project_number);
        CLOSE cur_tasks;
      END IF; --closing IF loop for zero-tasks check in a project
      --***populate project_asset_ids***
      OPEN cur_assets(ln_project_id);
      FETCH cur_assets BULK COLLECT INTO tbl_assets;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'count of assets for project : '||tbl_proj_num(indx).project_number||' is : '||cur_assets%ROWCOUNT);
      IF (cur_assets%ROWCOUNT <> 0) THEN
        FOR k                 IN 1..cur_assets%ROWCOUNT
        LOOP    --for-each-asset-within-project loop
          BEGIN --inner block4 - populate project_asset_id
            ln_proj_asset_id:=0;
            SELECT project_asset_id
            INTO ln_proj_asset_id
            FROM PA_PROJECT_ASSETS_ALL
            WHERE UPPER(asset_name)=UPPER(TRIM(tbl_assets(k).assign_assets))
            AND project_id         =ln_project_id;
            --populate the project_asset_id column in the upload staging table
            UPDATE XX_PA_MASS_ADJUST_UPLD_STG
            SET project_asset_id    =ln_proj_asset_id
            WHERE project_id    =ln_project_id
            AND UPPER(assign_assets)=UPPER(TRIM(tbl_assets(k).assign_assets));
            COMMIT;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Asset name provided is invalid : '||tbl_assets(k).assign_assets||', project : '||tbl_proj_num(indx).project_number);
            UPDATE XX_PA_MASS_ADJUST_UPLD_STG
            SET status_mesg           = status_mesg||'-'||'Asset name provided is invalid',
              conc_req_id           = gn_request_id
            WHERE project_id    = ln_project_id
            AND UPPER(assign_assets)=UPPER(TRIM(tbl_assets(k).assign_assets));
            COMMIT;
          END; --inner block4
        END LOOP;
      CLOSE cur_assets;
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'No assets for project - '||tbl_proj_num(indx).project_number);
        CLOSE cur_assets;
      END IF; --closing IF loop for zero-assets check in a project
      --***populate employee ids***
      OPEN cur_keym(ln_project_id);
      FETCH cur_keym BULK COLLECT INTO tbl_keym;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'count of keym for project : '||tbl_proj_num(indx).project_number||' is : '||cur_keym%ROWCOUNT);
      IF (cur_keym%ROWCOUNT <> 0) THEN
        FOR m               IN 1..cur_keym%ROWCOUNT
        LOOP    --for-each-keymember-within-project loop
          BEGIN --inner block2 - populate employee_id
            LN_EMPLOYEE_ID:=0;
			/*
			SELECT employee_id
            INTO ln_employee_id
            FROM HR_EMPLOYEES
            WHERE employee_num=TRIM(tbl_keym(m).employee_number); */ -- Commented out for defect#37458
            SELECT ppf.person_id
            into LN_EMPLOYEE_ID
            from PER_ALL_PEOPLE_F PPF
            where PPF.EMPLOYEE_NUMBER=TRIM(TBL_KEYM(M).EMPLOYEE_NUMBER)
            and sysdate between ppf.effective_start_date and nvl(ppf.effective_end_date,sysdate); -- Added for the defect#37458
            --populate the employee_id column in the upload staging table
            UPDATE XX_PA_MASS_ADJUST_UPLD_STG
            SET employee_id     =ln_employee_id
            WHERE project_id=ln_project_id
            AND TRIM(employee_number) =TRIM(tbl_keym(m).employee_number);
            COMMIT;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Employee number provided is invalid : '||tbl_keym(m).employee_number||', project : '||tbl_proj_num(indx).project_number);
            UPDATE XX_PA_MASS_ADJUST_UPLD_STG
            SET status_mesg        = status_mesg||'-'||'Employee number provided is invalid.',
              conc_req_id        = gn_request_id
            WHERE project_id = ln_project_id
            AND UPPER(employee_number)  =UPPER(TRIM(tbl_keym(m).employee_number));
            COMMIT;
          END;    --inner block2
        END LOOP; --for-each-keymember-within-project loop
       CLOSE cur_keym;
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'No key member updates for project - '||tbl_proj_num(indx).project_number);
        CLOSE cur_keym;
      END IF; --closing IF loop for zero-keymembers check in a project

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Project number provided is invalid : '||tbl_proj_num(indx).project_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'Project number provided is invalid.',
        conc_req_id        = gn_request_id
      WHERE TRIM(UPPER(project_number)) = tbl_proj_num(indx).project_number;
      COMMIT;
    END;    --inner block1
  END LOOP; --closing for-each-project loop
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception while populating ids in  - POPULATE_IDS'||SUBSTR (SQLERRM, 1, 225)||tbl_proj_num(i).project_number);
  --RAISE populate_ids_exception;
  UPDATE XX_PA_MASS_ADJUST_UPLD_STG
  SET status                = 'E',
    status_code             = 'Error',
    status_mesg             = status_mesg||'Encountered exception while fetching ids.',
    conc_req_id             = gn_request_id
  WHERE TRIM(UPPER(project_number))      = tbl_proj_num(i).project_number;
  COMMIT;
  RETURN;
END POPULATE_IDS;

PROCEDURE PUBLISH_REPORT
IS
  -- Local Variable declaration
  lc_rpt_rid      NUMBER(15);
  lb_layout       BOOLEAN;
  lb_req_status   BOOLEAN;
  lc_status_code  VARCHAR2(100);
  lc_phase        VARCHAR2(100);
  lc_status       VARCHAR2(100);
  lc_devphase     VARCHAR2(100);
  lc_devstatus    VARCHAR2(100);
  lc_message      VARCHAR2(1000);
  lb_print_option BOOLEAN;
  lc_exc_flag      BOOLEAN := FALSE;
BEGIN
  lb_layout  := fnd_request.add_layout('XXFIN' ,'XXPAMASSADJSTUPLD' ,'en' ,'US' ,'EXCEL');
  lc_rpt_rid := FND_REQUEST.SUBMIT_REQUEST('XXFIN' ,'XXPAMASSADJSTUPLD' ,NULL ,NULL ,FALSE);
  COMMIT;
  lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => lc_rpt_rid ,
                                                   interval => '2' ,
                                                   max_wait => '' ,
                                                   phase => lc_phase ,
                                                   status => lc_status ,
                                                   dev_phase => lc_devphase ,
                                                   dev_status => lc_devstatus ,
                                                   MESSAGE => lc_message);
  IF lc_rpt_rid <> 0 THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The report has been submitted and the request id is: '||lc_rpt_rid);
  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error submitting the report publisher request.');
    lc_exc_flag:=fnd_concurrent.set_completion_status('WARNING','Encountered an error while publishing the report.');
  END IF;
END PUBLISH_REPORT;

PROCEDURE LOAD_TASKS_FOR_UPDATE(p_project_number VARCHAR2,
    p_project_id IN NUMBER ,
    pt_tasks_in  IN OUT NOCOPY pa_project_pub.task_in_tbl_type )
AS
  l_tasks_in_rec pa_project_pub.task_in_rec_type;
  lc_location_flag VARCHAR2(2):='N';
  ln_task_org_id   NUMBER;
  lc_loc_enabled_flag VARCHAR2(2);
  lc_service_type_code VARCHAR2(50);
  lc_task_reference   PA_TASKS.PM_TASK_REFERENCE%TYPE;
  p_task_id PA_TASKS.TASK_ID%TYPE;
  ln_parent_task_id PA_TASKS.PARENT_TASK_ID%TYPE;
  --cursor to fetch all task details provided for a given project
  CURSOR cur_get_tasks
  IS
    SELECT DISTINCT task_number,
      task_id,
      task_name,
      task_start_date,
      task_end_date,
      task_location,
      task_org,
      allow_charges,
      service_type,
      attribute1
    FROM XX_PA_MASS_ADJUST_UPLD_STG
    WHERE project_id=p_project_id
    AND task_id IS NOT NULL
    ORDER BY attribute1 DESC; --if valid task number is not provided, task details are not populated to composite variables for the particular record
BEGIN
  FOR lcsr_task IN cur_get_tasks --for each task, fetch details and populate composite variable
  LOOP
    p_task_id:=lcsr_task.task_id;
    BEGIN --inner block1 --to fetch the task location
      --resetting variables
      l_tasks_in_rec.attribute1        :=NULL;
      l_tasks_in_rec.attribute_category:=NULL;
      lc_loc_enabled_flag:='N';
      SELECT FFV.flex_value,FFV.enabled_flag,'Global Data Elements'
      INTO l_tasks_in_rec.attribute1,lc_loc_enabled_flag,l_tasks_in_rec.attribute_category
      FROM FND_FLEX_VALUES FFV,
        FND_FLEX_VALUE_SETS FFVS
      WHERE FFV.flex_value_set_id  =FFVS.flex_value_set_id
      AND FFVS.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
      AND FFV.flex_value           =TRIM(lcsr_task.task_location)
      AND (FFV.end_date_active IS NULL OR FFV.end_date_active > SYSDATE);
      IF (lc_loc_enabled_flag='N') THEN
      l_tasks_in_rec.attribute1        :=NULL; --pass null for location since disabled locations are not allowed.
      l_tasks_in_rec.attribute_category:=NULL;
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status_mesg = status_mesg||'-'||'Task location provided is not enabled.'
      WHERE project_id = p_project_id
      AND task_id = lcsr_task.task_id;
      COMMIT;
      END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      IF (TRIM(lcsr_task.task_location) IS NULL) THEN
      NULL; --do nothing, pass null to API
      ELSE --task location provided is invalid
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status_mesg = status_mesg||'-'||'Task location provided is invalid.'
      WHERE project_id = p_project_id
      AND task_id = lcsr_task.task_id;
      COMMIT;
      END IF;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the task location block- '||SUBSTR (SQLERRM, 1, 225)||p_project_number||'-'||lcsr_task.task_number);
    END;  --inner block1
    BEGIN --inner block2 --to fetch the task org
      ln_task_org_id:=0;
      SELECT organization_id
      INTO ln_task_org_id
      FROM HR_ALL_ORGANIZATION_UNITS
      WHERE UPPER(name)=UPPER(TRIM(lcsr_task.task_org));
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      IF (lcsr_task.task_org IS NULL) THEN
    NULL; --do nothing, pass null to API
    ELSE
     UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status_mesg = status_mesg||'-'||'Task org provided is invalid.'
      WHERE project_id = p_project_id
      AND task_id = lcsr_task.task_id;
      COMMIT;
    END IF;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the task org block- '||SUBSTR (SQLERRM, 1, 225)||p_project_number||'-'||lcsr_task.task_number);
    END; --inner block2
    BEGIN --inner block3 --to fetch the service_type
      lc_service_type_code:='';
      SELECT lookup_code
      INTO lc_service_type_code
      FROM FND_LOOKUP_VALUES
      WHERE lookup_type='SERVICE TYPE'
      AND UPPER(meaning)=UPPER(TRIM(lcsr_task.service_type))
      AND (enabled_flag='Y' OR (end_date_active IS NULL OR end_date_active > SYSDATE))
      AND language=USERENV('LANG');
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
     UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status_mesg = status_mesg||'-'||'Task service type provided is invalid.'
      WHERE project_id = p_project_id
      AND task_id = lcsr_task.task_id;
      COMMIT;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the task service_type block- '||SUBSTR (SQLERRM, 1, 225)||p_project_number||'-'||lcsr_task.task_number);
    END; --inner block3
    BEGIN --inner block4 --to fetch task_reference
    SELECT pm_task_reference
    INTO lc_task_reference
    FROM PA_TASKS
    WHERE task_id=lcsr_task.task_id
    AND project_id=p_project_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    NULL; --do nothing
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the task reference block- '||SUBSTR (SQLERRM, 1, 225)||p_project_id||'-'||lcsr_task.task_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Encountered exception while fetching task reference.',
        conc_req_id        = gn_request_id
      WHERE project_id = p_project_id
      AND task_id = lcsr_task.task_id;
      COMMIT;
      gc_exception_flag:='Y';
      END; --inner block4
      BEGIN --inner block5 --to fetch parent_task_id
        SELECT parent_task_id
        INTO ln_parent_task_id
        FROM PA_TASKS
        WHERE task_id=lcsr_task.task_id
        AND project_id=p_project_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    NULL; --do nothing
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the parent task details block- '||SUBSTR (SQLERRM, 1, 225)||p_project_id||'-'||lcsr_task.task_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Encountered exception while fetching parent task details.',
        conc_req_id        = gn_request_id
      WHERE project_id = p_project_id
      AND task_id = lcsr_task.task_id;
      COMMIT;
      gc_exception_flag:='Y';
      END; --inner block5
    --populate composite variable with task details
    l_tasks_in_rec.pa_task_id                   := lcsr_task.task_id; --Added to fix the bug reported by users after migration to Prod.
    l_tasks_in_rec.pm_task_reference            := lc_task_reference;
    l_tasks_in_rec.pa_parent_task_id            := ln_parent_task_id;
    l_tasks_in_rec.task_name                    := lcsr_task.task_name;
    l_tasks_in_rec.pa_task_number               := lcsr_task.task_number;
    l_tasks_in_rec.task_start_date              := lcsr_task.task_start_date;
    l_tasks_in_rec.task_completion_date         := lcsr_task.task_end_date;
    l_tasks_in_rec.service_type_code            := lc_service_type_code;
    l_tasks_in_rec.carrying_out_organization_id := ln_task_org_id;
    l_tasks_in_rec.chargeable_flag              := lcsr_task.allow_charges;
    pt_tasks_in(pt_tasks_in.count+1)            := l_tasks_in_rec;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception while populating tasks - '||SUBSTR (SQLERRM, 1, 225)||p_project_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Encountered exception while populating tasks.',
        conc_req_id        = gn_request_id
      WHERE project_id = p_project_id
      AND task_id=p_task_id;
      COMMIT;
      gc_exception_flag:='Y';
RETURN;
END LOAD_TASKS_FOR_UPDATE;

PROCEDURE UPDATE_PROJECT(
    errbuff OUT NOCOPY VARCHAR2,
    retcode OUT NOCOPY NUMBER)
IS

  --composite datatype variables for use with update_project API

  lc_project_in PA_PROJECT_PUB.PROJECT_IN_REC_TYPE;
  lc_project_out PA_PROJECT_PUB.PROJECT_OUT_REC_TYPE;
  lc_key_members PA_PROJECT_PUB.PROJECT_ROLE_TBL_TYPE;
  lc_class_categories PA_PROJECT_PUB.CLASS_CATEGORY_TBL_TYPE;
  lc_tasks_in_rec PA_PROJECT_PUB.TASK_IN_REC_TYPE;
  lc_tasks_in PA_PROJECT_PUB.TASK_IN_TBL_TYPE;
  lc_tasks_out_rec PA_PROJECT_PUB.TASK_OUT_REC_TYPE;
  lc_tasks_out PA_PROJECT_PUB.TASK_OUT_TBL_TYPE;
  --variables for handling return status and messages from the API
  ln_rec_count       NUMBER :=0;
  ln_msg_count       NUMBER := 0;
  lc_msg_data        VARCHAR2(4000);
  lc_return_status   VARCHAR2(30);
  l_workflow_started VARCHAR2(30) ;
  lc_data            VARCHAR2(4000);
  ln_msg_index       NUMBER := 1;
  ln_msg_index_out   NUMBER;
  ln_project_id      NUMBER(15);
  lc_location_flag   VARCHAR2(2):='N';
  ln_prj_org         NUMBER;
  lc_task_id_out     NUMBER;
  lc_exc_flag      BOOLEAN := FALSE;
  lc_loc_enabled VARCHAR2(2);
  lc_project_status_code VARCHAR2(50);
  lc_from_status    PA_PROJECT_STATUSES.project_status_code%TYPE;
  lc_approval_allowed VARCHAR2(2);

  --cursor to fetch the eligible data from staging table

  CURSOR cur_upld_stg_data(proj_id NUMBER)
  IS
    SELECT DISTINCT UPPER(TRIM(project_number)) project_number,
    UPPER(TRIM(project_name)) project_name,
    UPPER(TRIM(project_long_name)) project_long_name,
    UPPER(TRIM(project_status)) project_status,
    project_start_date,
    project_end_date,
    TRIM(project_location) project_location,
    UPPER(TRIM(project_org)) project_org,
    project_id
    FROM XX_PA_MASS_ADJUST_UPLD_STG
    WHERE STATUS        ='I'
    AND project_id=proj_id;

  --cursor to fetch the list of distinct,eligible,valid projects from the staging table

  CURSOR cur_upld_stg_data_count
  IS
    SELECT DISTINCT project_id,UPPER(TRIM(project_number)) project_number
    FROM XX_PA_MASS_ADJUST_UPLD_STG
    WHERE STATUS        ='I'
    AND project_id IS NOT NULL;

    --Record to hold list of distinct,eligible,valid projects from the staging table

  TYPE rec_project_details IS RECORD(project_id NUMBER(15),project_number VARCHAR2(25));

  TYPE tbl_type_project_details IS  TABLE OF rec_project_details INDEX BY BINARY_INTEGER;

  tbl_project_details tbl_type_project_details;

  --Table of Records to hold each valid header record from the staging table.

  l_rec_upld_stg_data cur_upld_stg_data%ROWTYPE;

  TYPE tbl_typ_stg_data IS TABLE OF l_rec_upld_stg_data%TYPE INDEX BY BINARY_INTEGER;

  tbl_stg_data tbl_typ_stg_data;

BEGIN

  fnd_profile.put('AFLOG_ENABLED', 'Y');
  fnd_profile.put('AFLOG_LEVEL', 1);
  fnd_profile.put('AFLOG_MODULE','%');
  fnd_profile.put('PA_DEBUG_MODE', 'Y');
  fnd_log_repository.init();

  --fetching the request ID for the current concurrent request.
  gn_request_id := FND_GLOBAL.CONC_REQUEST_ID;

  --populating responsibility name for the current request.
  gc_resp_name := FND_GLOBAL.RESP_NAME;

  --Delete older records from the staging table.
  DELETE
  FROM XX_PA_MASS_ADJUST_UPLD_STG
  WHERE status IN ('P','E');

  --Delete any blank rows from the table
  DELETE
  FROM XX_PA_MASS_ADJUST_UPLD_STG
  WHERE (TRIM(project_number)  IS NULL
  AND TRIM(project_name)       IS NULL
  AND TRIM(project_long_name)  IS NULL
  AND TRIM(project_status)     IS NULL
  AND TRIM(project_start_date) IS NULL
  AND TRIM(project_end_date)   IS NULL
  AND TRIM(project_location)   IS NULL
  AND TRIM(project_org)        IS NULL
  AND TRIM(task_number)        IS NULL
  AND TRIM(task_name)          IS NULL
  AND TRIM(task_start_date)    IS NULL
  AND TRIM(task_end_date)      IS NULL
  AND TRIM(task_location)      IS NULL
  AND TRIM(task_org)           IS NULL
  AND TRIM(assign_assets)      IS NULL
  AND TRIM(allow_charges)      IS NULL
  AND TRIM(service_type)       IS NULL
  AND TRIM(employee_name)      IS NULL
  AND TRIM(employee_number)    IS NULL
  AND TRIM(role)               IS NULL
  AND TRIM(role_start_date)    IS NULL
  AND TRIM(role_end_date)      IS NULL);

  --Remove special characters in the fields
  UPDATE XX_PA_MASS_ADJUST_UPLD_STG
     SET PROJECT_LOCATION = REPLACE(REPLACE(REPLACE (PROJECT_LOCATION, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
         TASK_NUMBER       = REPLACE(REPLACE(REPLACE (TASK_NUMBER, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
         TASK_LOCATION    = REPLACE(REPLACE(REPLACE (TASK_LOCATION, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
         EMPLOYEE_NAME      = REPLACE(REPLACE(REPLACE (EMPLOYEE_NAME, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
         TASK_ORG    = REPLACE(REPLACE(REPLACE (TASK_ORG, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
         EMPLOYEE_NUMBER      = REPLACE(REPLACE(REPLACE (EMPLOYEE_NUMBER, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
         PROJECT_ORG    = REPLACE(REPLACE(REPLACE (PROJECT_ORG, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
         ASSIGN_ASSETS      = REPLACE(REPLACE(REPLACE (ASSIGN_ASSETS, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '')
   WHERE 1=1;
  COMMIT;

  --invoke POPULATE_HIST_TABLE to populate all records into history table
  POPULATE_HIST_TABLE();

  --Update status to E if PROJECT NUMBER is not provided
  UPDATE XX_PA_MASS_ADJUST_UPLD_STG
  SET status            = 'E',
    status_code         = 'Error',
    status_mesg         = status_mesg||'The project number is not provided.',
    conc_req_id         = gn_request_id
  WHERE TRIM(project_number) IS NULL;

  --If the length of project name exceeds allowed limit, set all rows of the project to E.
   UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status            = 'E',
          status_code         = 'Error',
          status_mesg         = status_mesg||'Error: Length of project name exceeds allowed limit.',
          conc_req_id         = gn_request_id
    WHERE LENGTH(TRIM(project_name)) > (SELECT char_length
                                          FROM DBA_TAB_COLUMNS
                                         WHERE table_name = 'PA_PROJECTS_ALL'
                                           AND column_name = 'NAME'
                                           AND owner='PA');
   COMMIT;

  --Populate project_id,task_id,project_asset_id,employee_id for each project in the staging table.
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoking POPULATE_IDS.');
  POPULATE_IDS(errbuff,retcode);
  OPEN cur_upld_stg_data_count;
  FETCH cur_upld_stg_data_count BULK COLLECT INTO tbl_project_details;
  ln_rec_count:=cur_upld_stg_data_count%ROWCOUNT;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of eligible projects in staging table : '||ln_rec_count);
  IF ln_rec_count=0 THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'There are no projects eligible in the staging table to be processed.');
    --publish report in excel
    PUBLISH_REPORT();
    RETURN;
  END IF;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Eligible projects in the staging table:-');
  FOR i IN tbl_project_details.FIRST..tbl_project_details.LAST
  LOOP
  FND_FILE.PUT_LINE(FND_FILE.LOG, tbl_project_details(i).project_number);
  END LOOP;
  FOR i IN tbl_project_details.FIRST..tbl_project_details.LAST LOOP --opening for-each-valid-project-in-staging-table loop
    OPEN cur_upld_stg_data(tbl_project_details(i).project_id);
    FETCH cur_upld_stg_data BULK COLLECT INTO tbl_stg_data;
    IF (cur_upld_stg_data%ROWCOUNT > 1) THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Different values of project header-level data provided for project - '||tbl_stg_data(1).project_number);
    UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status_mesg        = status_mesg||'-'||'Different values of project header-level data provided.'
      WHERE project_id = tbl_stg_data(1).project_id;
      COMMIT;
    END IF;
    CLOSE cur_upld_stg_data;
    OPEN cur_upld_stg_data(tbl_project_details(i).project_id);
    FETCH cur_upld_stg_data INTO l_rec_upld_stg_data;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening the cursor for - '||l_rec_upld_stg_data.project_number);
    --resetting project reference variable.
    gc_project_reference:=NULL;
     lc_approval_allowed := 'N';
    --clearing data in composite datatypes at begining of iteration
    lc_key_members.DELETE;
    lc_class_categories.DELETE;
    lc_tasks_in.DELETE;
    lc_tasks_out.DELETE;
    BEGIN --inner block3 --to fetch the project location
    --resetting variables
      lc_project_in.attribute1        :=NULL;
      lc_project_in.attribute_category:=NULL;
      lc_loc_enabled := 'N';
      SELECT FFV.flex_value,FFV.enabled_flag,'GLOBAL DATA ELEMENTS'
      INTO lc_project_in.attribute1,lc_loc_enabled,lc_project_in.attribute_category
      FROM FND_FLEX_VALUES FFV,
        FND_FLEX_VALUE_SETS FFVS
      WHERE FFV.flex_value_set_id        =FFVS.flex_value_set_id
      AND FFVS.flex_value_set_name       = 'OD_GL_GLOBAL_LOCATION'
      AND (FFV.end_date_active IS NULL OR FFV.end_date_active > SYSDATE)
      AND FFV.flex_value                 =TRIM(l_rec_upld_stg_data.project_location);
      IF (lc_loc_enabled= 'N') THEN --pass null for location since disabled locations are not allowed.
      lc_project_in.attribute1        :=NULL;
      lc_project_in.attribute_category:=NULL;
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status_mesg        = status_mesg||'-'||'Project location provided is not enabled.'
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
      END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status_mesg        = status_mesg||'-'||'Project location provided is invalid.'
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the project location block- '||SUBSTR (SQLERRM, 1, 225)||l_rec_upld_stg_data.project_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Encountered exception while fetching project location details.',
        conc_req_id        = gn_request_id
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
      gc_exception_flag:='Y';
    END;  --inner block3
    BEGIN --inner block4 --to fetch the project org
      SELECT organization_id
      INTO ln_prj_org
      FROM HR_ALL_ORGANIZATION_UNITS
      WHERE UPPER(name)=l_rec_upld_stg_data.project_org;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status_mesg        = status_mesg||'-'||'Project org provided is invalid.'
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the project org block- '||SUBSTR (SQLERRM, 1, 225)||l_rec_upld_stg_data.project_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Encountered exception while fetching project org details.',
        conc_req_id        = gn_request_id
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
      gc_exception_flag:='Y';
    END; --inner block4
    BEGIN --inner block5 --to fetch the project status
      SELECT UPPER(project_status_code)
      INTO lc_project_status_code
      FROM PA_PROJECT_STATUSES
      WHERE UPPER(project_status_name)=UPPER(TRIM(l_rec_upld_stg_data.project_status))
      AND status_type='PROJECT'
      AND (end_date_active IS NULL OR end_date_active > SYSDATE);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status_mesg        = status_mesg||'-'||'Project status provided is invalid.'
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the project status block- '||SUBSTR (SQLERRM, 1, 225)||l_rec_upld_stg_data.project_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Encountered exception while fetching project status details.',
        conc_req_id        = gn_request_id
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
      gc_exception_flag:='Y';
    END; --inner block5
    BEGIN --inner block6 --to fetch project_reference
    SELECT pm_project_reference
    INTO gc_project_reference
    FROM PA_PROJECTS_ALL
    WHERE UPPER(segment1)=l_rec_upld_stg_data.project_number;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    NULL; --do nothing
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the project reference block- '||SUBSTR (SQLERRM, 1, 225)||l_rec_upld_stg_data.project_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Encountered exception while fetching project reference.',
        conc_req_id        = gn_request_id
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
      gc_exception_flag:='Y';
      END; --inner block6
      --populating key member details to composite datatype, invoking LOAD_KEYM_FOR_UPDATE procedure.
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoking LOAD_KEYM_FOR_UPDATE for - '||l_rec_upld_stg_data.project_number);
      LOAD_KEYM_FOR_UPDATE(l_rec_upld_stg_data.project_number,l_rec_upld_stg_data.project_id,lc_key_members);
      -- calling LOAD_TASKS_FOR_UPDATE to load tasks to composite datatype
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoking LOAD_TASKS_FOR_UPDATE for - '||l_rec_upld_stg_data.project_number);
      LOAD_TASKS_FOR_UPDATE(l_rec_upld_stg_data.project_number,l_rec_upld_stg_data.project_id,lc_tasks_in);
      --fetch current project status for the project.
      BEGIN --inner block7
      SELECT UPPER(project_status_code)
      INTO lc_from_status
      FROM PA_PROJECTS_ALL
      WHERE project_id=l_rec_upld_stg_data.project_id;
      SELECT 'Y' INTO lc_approval_allowed
      FROM DUAL WHERE gc_resp_name IN (SELECT ftv.source_value1
                           FROM xx_fin_translatedefinition ftd,
                           xx_fin_translatevalues ftv
                           WHERE ftd.translate_id=ftv.translate_id
                           AND ftd.translation_name='XX_PA_APPROVE_PROJECTS'
                           AND ftv.enabled_flag='Y'
                           AND (ftv.end_date_active IS NULL OR ftv.end_date_active > SYSDATE)
                           AND (ftd.end_date_active IS NULL OR ftd.end_date_active > SYSDATE));
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
      NULL; --do nothing
      WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception while validating project approval permissions - '||SUBSTR (SQLERRM, 1, 225)||l_rec_upld_stg_data.project_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Encountered exception while validating project approval permissions.',
        conc_req_id        = gn_request_id
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
      gc_exception_flag:='Y';
      END; --inner block7
      IF (lc_from_status <> 'APPROVED' AND lc_project_status_code = 'APPROVED' AND lc_approval_allowed <> 'Y') THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error : '||l_rec_upld_stg_data.project_number||' - User does not have access to approve projects ');
        UPDATE XX_PA_MASS_ADJUST_UPLD_STG
        SET status           = 'E',
        status_code        = 'Error',
        status_mesg        = status_mesg||'-'||'Error : Project update failed , User does not have access to approve projects.',
        conc_req_id        = gn_request_id
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
      ELSE --allow project updates
    --populating project details to composite datatypes.
    lc_project_in.pm_project_reference        :=gc_project_reference;
    lc_project_in.pa_project_id               :=ln_project_id;
    lc_project_in.pa_project_number           :=l_rec_upld_stg_data.project_number;
    lc_project_in.carrying_out_organization_id:=ln_prj_org;
    lc_project_in.project_status_code         :=lc_project_status_code;
    lc_project_in.start_date                  :=l_rec_upld_stg_data.project_start_date;
    lc_project_in.completion_date             :=l_rec_upld_stg_data.project_end_date;
    lc_project_in.long_name                   :=l_rec_upld_stg_data.project_long_name;
    lc_project_in.project_name                :=l_rec_upld_stg_data.project_name;
    --Initialize the message stack
    FND_MSG_PUB.initialize;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling the UPDATE_PROJECT API for project : '||l_rec_upld_stg_data.project_number);
    --invoke the API..
    PA_PROJECT_PUB.UPDATE_PROJECT(p_api_version_number => 1.0,
    p_commit => FND_API.G_FALSE,
    p_init_msg_list => FND_API.G_TRUE,
    p_msg_count => ln_msg_count,
    p_msg_data => lc_msg_data,
    p_return_status => lc_return_status,
    p_workflow_started => l_workflow_started,
    p_pm_product_code => 'EJM',
    p_project_in => lc_project_in,
    p_project_out => lc_project_out,
    p_key_members => lc_key_members,
    p_class_categories => lc_class_categories,
    p_tasks_in => lc_tasks_in,
    p_tasks_out => lc_tasks_out);
    IF lc_return_status = 'S' THEN --status check loop
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'PROJECT UPDATE SUCCESSFUL FOR THE PROJECT : '||l_rec_upld_stg_data.project_number);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status           = 'P',
        status_code        = 'Processed',
        status_mesg        = status_mesg||'-'||'Project update successful',
        conc_req_id        = gn_request_id
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
    ELSE
      IF ln_msg_count>0 THEN
        FOR I       IN 1..LN_MSG_COUNT
        LOOP
          PA_INTERFACE_UTILS_PUB.GET_MESSAGES( P_MSG_DATA => LC_MSG_DATA,
          P_ENCODED => 'F',
          P_DATA => LC_DATA,
          P_MSG_COUNT => LN_MSG_COUNT,
          P_MSG_INDEX => LN_MSG_INDEX,
          P_MSG_INDEX_OUT => LN_MSG_INDEX_OUT);
        END LOOP;
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'PROJECT UPDATE FAILED FOR THE PROJECT : '||l_rec_upld_stg_data.project_number||' Error : '||lc_data);
      UPDATE XX_PA_MASS_ADJUST_UPLD_STG
      SET status    = 'E',
        status_code = 'Error',
        status_mesg = status_mesg||'Error : Project Update failed'||lc_data,
        conc_req_id        = gn_request_id
      WHERE project_id = l_rec_upld_stg_data.project_id;
      COMMIT;
    END IF; --closing status check loop
  END IF; --closing loop on project-approval-permission-check
    --calling ASSIGN_ASSETS_FOR_UPDATE to assign assets to tasks.
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoking ASSIGN_ASSETS_FOR_UPDATE for - '||l_rec_upld_stg_data.project_number);
    ASSIGN_ASSETS_FOR_UPDATE(l_rec_upld_stg_data.project_number,l_rec_upld_stg_data.project_id);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Completed processing - '||l_rec_upld_stg_data.project_number);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'************************************************************');
    CLOSE cur_upld_stg_data;
  END LOOP; --closing for-each-valid-project-in-staging-table loop
  SELECT COUNT(1)
  INTO gn_success
  FROM XX_PA_MASS_ADJUST_UPLD_STG
  WHERE status='P';
  SELECT COUNT(1)
  INTO gn_failure
  FROM XX_PA_MASS_ADJUST_UPLD_STG
  WHERE status='E';
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Completed processing all eligible records in the staging table');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Count of records successfully processed : '||gn_success);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Count of records failed : '||gn_failure);
  IF (gc_exception_flag='Y') THEN
  lc_exc_flag:=fnd_concurrent.set_completion_status('WARNING','Concurrent request encountered an exception.Please refer to log file for details.');
  COMMIT;
  END IF;
  --calling the report publisher procedure
  PUBLISH_REPORT();
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered the exception while processing the project : '||l_rec_upld_stg_data.project_number||' -> ' ||SUBSTR (SQLERRM, 1, 225) );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'End Time: ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH:MI:SS AM') );
  UPDATE XX_PA_MASS_ADJUST_UPLD_STG
    SET status         = 'E',
    status_code        = 'Error',
    conc_req_id        = gn_request_id,
    status_mesg       = 'Encountered an exception.'
    WHERE project_id                = l_rec_upld_stg_data.project_id;
  COMMIT;
  PUBLISH_REPORT();
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Request : '||gn_request_id||' completed in error. Please refer to log file for more details.');
  lc_exc_flag:=fnd_concurrent.set_completion_status('ERROR','Concurrent request encountered an error.Please refer to log file for details.');
  COMMIT;
END UPDATE_PROJECT;
PROCEDURE EXTRACT(
    errbuff OUT NOCOPY VARCHAR2,
    retcode OUT NOCOPY NUMBER)
IS
  ln_request_id      NUMBER(15);
  lb_layout          BOOLEAN;
  lb_req_status      BOOLEAN;
  lc_status_code     VARCHAR2(10);
  lc_phase           VARCHAR2(50);
  lc_status          VARCHAR2(50);
  lc_devphase        VARCHAR2(50);
  lc_devstatus       VARCHAR2(50);
  lc_message         VARCHAR2(50);
  lb_print_option    BOOLEAN;
  lc_boolean         BOOLEAN;
  ln_total_processed NUMBER :=0;
  ln_success_count   NUMBER :=0;
  ln_error_count     NUMBER :=0;
  project_id         NUMBER;
  lc_flag            BOOLEAN:=TRUE ;
  lc_rpt_rid         NUMBER(15);
  ln_org_id          NUMBER:=0;
  CURSOR cur_ext_stg_data
  IS
    SELECT UPPER(TRIM(project_number)) project_number
    FROM XX_PA_MASS_ADJUST_EXT_STG
    WHERE 1   =1
    AND status='E';
BEGIN

  ln_org_id:=FND_GLOBAL.ORG_ID;

  -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Org : '||FND_GLOBAL.ORG_NAME);

  --delete blank rows
  DELETE
  FROM XX_PA_MASS_ADJUST_EXT_STG
  WHERE TRIM(project_number)  IS NULL;

  -- delete old processed records
  DELETE FROM XX_PA_MASS_ADJUST_EXT_STG WHERE status IN ('P','E');
  COMMIT;

  UPDATE XX_PA_MASS_ADJUST_EXT_STG ds
     SET status ='E'
   WHERE NOT EXISTS  (SELECT 1
		        FROM pa_projects_all
		       WHERE UPPER(segment1)=UPPER(TRIM(ds.project_number))
		       --AND org_id=ln_org_id
		     );

  UPDATE XX_PA_MASS_ADJUST_EXT_STG ds
    SET status ='P'
  WHERE EXISTS  (SELECT 1
		   FROM pa_projects_all
		  WHERE UPPER(segment1)=UPPER(TRIM(ds.project_number))
		  --AND org_id=ln_org_id
	        );
  COMMIT;

  FOR c_stg_rec IN cur_ext_stg_data
  LOOP
    FND_FILE.PUT_LINE(FND_FILE.LOG, c_stg_rec.project_number || ', is an invalid Project Number' );
  END LOOP;

  SELECT COUNT(*) INTO ln_total_processed FROM XX_PA_MASS_ADJUST_EXT_STG;

  SELECT COUNT(*)
  INTO ln_success_count
  FROM XX_PA_MASS_ADJUST_EXT_STG
  WHERE status='P';

  SELECT COUNT(*)
  INTO ln_error_count
  FROM XX_PA_MASS_ADJUST_EXT_STG
  WHERE status='E';

  FND_FILE.PUT_LINE(FND_FILE.LOG,'-----------------------------------------------------------------------------');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Projects processed              :' || ln_total_processed);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Projects successfully Found   :' || ln_success_count);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Projects errored                :' || ln_error_count);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'------------------------------------------------------------------------------');

  BEGIN --inner block to invoke the extract.
    lb_layout  := fnd_request.add_layout('XXFIN' ,'XXPAMASSADJSTEXT' ,'en' ,'US' ,'EXCEL');
    lc_rpt_rid := FND_REQUEST.SUBMIT_REQUEST('XXFIN' ,'XXPAMASSADJSTEXT' ,NULL ,NULL ,FALSE);
    COMMIT;

    lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(	request_id => lc_rpt_rid ,
						     	interval => '2' ,
							max_wait => '' ,
							phase => lc_phase ,
							status => lc_status ,
							dev_phase => lc_devphase ,
							dev_status => lc_devstatus ,
							MESSAGE => lc_message);
    IF lc_rpt_rid <> 0 THEN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'The report has been submitted and the request id is: '||lc_rpt_rid);

    ELSE

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error submitting the report publisher request.');
      lc_boolean:=fnd_concurrent.set_completion_status('WARNING','Encountered an error while publishing the report.');
    END IF;
  END; --inner block
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered the exception:- ' ||SUBSTR (SQLERRM, 1, 225) );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'End Time: ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH:MI:SS AM') );
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Request : '||ln_request_id||' completed in error. Please refer to log file for more details.');
  lc_boolean:=fnd_concurrent.set_completion_status('ERROR','Concurrent request encountered an error.Please refer to log file for details.');
  COMMIT;
END EXTRACT;

PROCEDURE POPULATE_HIST_TABLE
IS
insert_sql VARCHAR2(4000);
BEGIN
insert_sql:='INSERT INTO XX_PA_MASS_ADJUST_UPLD_HIST SELECT stg.*,SYSDATE FROM XX_PA_MASS_ADJUST_UPLD_STG stg';
EXECUTE IMMEDIATE insert_sql;
FND_FILE.PUT_LINE(FND_FILE.LOG, 'Number of records inserted into history table: '||SQL%ROWCOUNT);
COMMIT;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered the exception while populating history table :- ' ||SUBSTR (SQLERRM, 1, 225) );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'End Time: ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH:MI:SS AM') );
END POPULATE_HIST_TABLE;
END XX_PA_MASS_ADJST_PKG;
/