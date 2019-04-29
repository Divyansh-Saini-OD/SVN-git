create or replace 
PACKAGE BODY XX_PA_BULK_CREATE_PROJECT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name:  XX_PA_BULK_CREATE_PROJECT_PKG                                                      |
  -- |  Description:  PA Mass Upload Tool to create projects in oracle.                           |
  -- |  Rice ID : E3067                                                                           |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         26-Aug-2013   Archana N.        Initial version                                |
  -- | 1.1         11-Sep-2013   Archana N.        Added check for length for project_name        |
  -- | 1.2         13-Sep-2013   Archana N.        Added check NULL project_name,long_name,       |
  -- |                                             description.                                   |
  -- | 1.3         17-Nov-2015   Harvinder Rakhra  Retrofit R12.2                                 |
  -- | 1.4         16-Oct-2018   Jitendra A.       Added FETCH_DATA procedure for NAIT-65619/72698|
  -- | 1.5         19-OCT-2018   Priyam P          Added remove_spcl_char for NAIT 65621  
 -- |  1.6         29-APR-2019    Faiyaz Ahmad      comented hr_employees for performance issue
  -- +============================================================================================+
  --global declarations
  g_api_version_number NUMBER                                                   := 1.0;
  g_pm_product_code FND_LOOKUP_VALUES_VL.lookup_code%TYPE                       :=NULL;
  g_budget_type PA_BUDGET_TYPES.budget_type_code%TYPE                           :=NULL;
  g_budget_entry_mth_code PA_BUDGET_ENTRY_METHODS.budget_entry_method_code%TYPE :=NULL;
  g_resource_list_id PA_RESOURCE_LISTS.resource_list_id%TYPE                    :=NULL;
  g_budget_version_name   VARCHAR2(20)                                            :=NULL;
  gn_request_id           NUMBER                                                  :=0;
  gn_success              NUMBER                                                  :=0;
  gn_failure              NUMBER                                                  :=0;
  gn_incomplete           NUMBER                                                  :=0;
  load_tasks_exception    EXCEPTION;
  assign_assets_exception EXCEPTION;
  create_budget_exception EXCEPTION;
PROCEDURE LOAD_TASKS(
    p_project_in         IN XX_PA_BULK_CREATE_PRJ_STG%ROWTYPE ,
    p_parent_task_id     IN NUMBER ,
    p_parent_task_number IN VARCHAR2 ,
    pt_tasks_in          IN OUT NOCOPY pa_project_pub.task_in_tbl_type ,
    p_template_id        IN NUMBER ,
    p_proj_org_id        IN NUMBER )
AS
  l_tasks_in_rec pa_project_pub.task_in_rec_type;
  lc_parent_task_number pa_tasks.TASK_NUMBER%TYPE;
  CURSOR mcsr_tasks(p_project_id NUMBER, p_parent_task_id NUMBER)
  IS
    SELECT T.*,
      P.carrying_out_organization_id template_projorgid
    FROM pa_tasks T
    JOIN pa_projects_all P
    ON P.project_id       = T.project_id
    WHERE T.project_id    = p_project_id
    AND ((parent_task_id  = p_parent_task_id)
    OR (p_parent_task_id IS NULL
    AND parent_task_id   IS NULL))
    ORDER BY task_number;
BEGIN
  FOR lcsr_task IN mcsr_tasks(p_template_id, p_parent_task_id)
  LOOP
    l_tasks_in_rec.pm_task_reference              := lcsr_task.task_number;
    l_tasks_in_rec.task_name                      := lcsr_task.task_name;
    l_tasks_in_rec.long_task_name                 := lcsr_task.long_task_name;
    l_tasks_in_rec.pa_task_number                 := lcsr_task.task_number;
    l_tasks_in_rec.task_description               := lcsr_task.description;
    l_tasks_in_rec.task_start_date                := p_project_in.project_start_date;
    l_tasks_in_rec.task_completion_date           := p_project_in.project_end_date;
    l_tasks_in_rec.service_type_code              := lcsr_task.service_type_code;
    l_tasks_in_rec.billable_flag                  := lcsr_task.billable_flag;
    l_tasks_in_rec.chargeable_flag                := lcsr_task.chargeable_flag;
    IF (lcsr_task.template_projorgid              != lcsr_task.carrying_out_organization_id) THEN
      l_tasks_in_rec.carrying_out_organization_id := lcsr_task.carrying_out_organization_id;
    ELSE
      l_tasks_in_rec.carrying_out_organization_id := p_proj_org_id;
    END IF;
    l_tasks_in_rec.task_manager_person_id     := lcsr_task.task_manager_person_id;
    l_tasks_in_rec.work_type_id               := lcsr_task.work_type_id;
    l_tasks_in_rec.attribute1                 := lcsr_task.attribute1;
    IF (p_parent_task_id                      IS NOT NULL) THEN
      l_tasks_in_rec.pm_parent_task_reference := p_parent_task_number;
    END IF;
    pt_tasks_in(pt_tasks_in.count+1) := l_tasks_in_rec;
    LOAD_TASKS(p_project_in,lcsr_task.task_id, lcsr_task.task_number , pt_tasks_in,p_template_id,p_proj_org_id);
  END LOOP;
  IF pt_tasks_in.count = 0 THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Template does not contain any tasks.');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  RAISE load_tasks_exception;
END LOAD_TASKS;
PROCEDURE ASSIGN_ASSETS(
    p_project_in  IN XX_PA_BULK_CREATE_PRJ_STG%ROWTYPE ,
    p_project_id  IN NUMBER ,
    p_template_id IN NUMBER )
AS
  -- parameter init
  ln_msg_count        NUMBER;
  lc_msg_data         VARCHAR2(8000);
  lc_return_status    VARCHAR2(1);
  ln_task_id          NUMBER;
  ln_project_asset_id NUMBER;
  lc_concat_msg_out   VARCHAR2(10000);
  CURSOR mcsr_asset_assignments(p_template_id NUMBER, p_project_new NUMBER)
  IS
    SELECT NVL(N.project_asset_id, A.project_asset_id) project_asset_id,
      A.task_id,
      T.task_number,
      A.attribute_category,
      A.attribute1,
      A.attribute2,
      A.attribute3,
      A.attribute4,
      A.attribute5,
      A.attribute6,
      A.attribute7,
      A.attribute8,
      A.attribute9,
      A.attribute10,
      A.attribute11,
      A.attribute12,
      A.attribute13,
      A.attribute14,
      A.attribute15
    FROM pa_project_asset_assignments A
    LEFT JOIN pa_project_assets_all O
    ON O.project_id        = A.project_id
    AND O.project_asset_id = A.project_asset_id
    LEFT JOIN pa_tasks T
    ON T.project_id = A.project_id
    AND T.task_id   = A.task_id
    LEFT JOIN pa_project_assets_all N
    ON N.project_id    = p_project_new
    AND N.asset_name   = O.asset_name
    WHERE A.project_id = p_template_id;
BEGIN
  FOR lcsr_aa IN mcsr_asset_assignments(p_template_id, p_project_id)
  LOOP
    PA_PROJECT_ASSETS_PUB.add_asset_assignment( p_api_version_number => '1.0' ,p_commit => 'F' ,p_init_msg_list => 'T' ,p_msg_count => ln_msg_count ,p_msg_data => lc_msg_data ,p_return_status => lc_return_status ,p_pm_product_code => 'EJM' ,p_pa_project_id => p_project_id ,p_pm_task_reference => lcsr_aa.task_number ,p_pa_project_asset_id => lcsr_aa.project_asset_id ,p_attribute_category => lcsr_aa.attribute_category ,p_attribute1 => lcsr_aa.attribute1 ,p_attribute2 => lcsr_aa.attribute2 ,p_attribute3 => lcsr_aa.attribute3 ,p_attribute4 => lcsr_aa.attribute4 ,p_attribute5 => lcsr_aa.attribute5 ,p_attribute6 => lcsr_aa.attribute6 ,p_attribute7 => lcsr_aa.attribute7 ,p_attribute8 => lcsr_aa.attribute8 ,p_attribute9 => lcsr_aa.attribute9 ,p_attribute10 => lcsr_aa.attribute10 ,p_attribute11 => lcsr_aa.attribute11 ,p_attribute12 => lcsr_aa.attribute12 ,p_attribute13 => lcsr_aa.attribute13 ,p_attribute14 => lcsr_aa.attribute14 ,p_attribute15 => lcsr_aa.attribute15 ,p_pa_task_id_out =>
    ln_task_id ,p_pa_project_asset_id_out => ln_project_asset_id );
  END LOOP;
  IF lc_return_status = 'S' THEN
    UPDATE XX_PA_BULK_CREATE_PRJ_STG
    SET status_mesg = status_mesg
      ||'-'
      ||'Asset assignment successful',
      conc_req_id         = gn_request_id
    WHERE pan             = p_project_in.pan
    AND project_extension = p_project_in.project_extension;
    COMMIT;
  ELSE
    gn_success   :=gn_success   -1;
    gn_incomplete:=gn_incomplete+1;
    UPDATE XX_PA_BULK_CREATE_PRJ_STG
    SET status_mesg = status_mesg
      ||'-'
      ||'Asset assignment failed',
      status              = 'IC',
      status_code         = 'Incomplete',
      conc_req_id         = gn_request_id
    WHERE pan             = p_project_in.pan
    AND project_extension = p_project_in.project_extension;
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'PA_PROJECT_ASSETS_PUB.add_asset_assignment failed: '|| lc_msg_data);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  RAISE assign_assets_exception;
END ASSIGN_ASSETS;
PROCEDURE CREATE_BUDGET(
    p_project_id IN NUMBER ,
    p_project_in IN XX_PA_BULK_CREATE_PRJ_STG%ROWTYPE )
AS
  -- parameter init
  PROCESS_ERROR1   EXCEPTION;
  ln_msg_count     NUMBER;
  lc_msg_data      VARCHAR2(8000);
  lc_return_status VARCHAR2(1);
  lt_budget_lines_in pa_budget_pub.budget_line_in_tbl_type;
  lr_budget_lines_in_rec pa_budget_pub.budget_line_in_rec_type;
  lt_budget_lines_out pa_budget_pub.budget_line_out_tbl_type;
  lc_workflow_started VARCHAR2(1);
  lc_str_data         VARCHAR2(2000);
  ln_msg_index_out    NUMBER;
  lc_concat_msg_out   VARCHAR2(10000);
  -- top tasks for a given project
  CURSOR lcsr_tasks(p_project_id PA_TASKS.project_id%type)
  IS
    SELECT task_id,
      task_number,
      start_date,
      completion_date,
      meaning
    FROM PA_TASKS T
    JOIN FND_LOOKUP_VALUES_VL M
    ON M.lookup_code   = T.task_number
    AND M.lookup_type  = 'PA_TASK_NUMBER'
    AND M.enabled_flag = 'Y'
    WHERE T.project_id = p_project_id
    ORDER BY M.meaning;
BEGIN
  FOR lcsr_task IN lcsr_tasks(p_project_id)
  LOOP
    lr_budget_lines_in_rec.pa_task_id := lcsr_task.task_id;
    lr_budget_lines_in_rec.quantity   := 1;
    IF lcsr_task.meaning               = 1 THEN
      lr_budget_lines_in_rec.raw_cost := p_project_in.expense_budget;
    ELSE
      lr_budget_lines_in_rec.raw_cost := p_project_in.capital_budget;
    END IF;
    lt_budget_lines_in(lcsr_task.meaning) := lr_budget_lines_in_rec;
  END LOOP;
  --Initialize Budget API
  PA_BUDGET_PUB.init_budget;
  -- Call Budget API
  PA_BUDGET_PUB.create_draft_budget( p_api_version_number => '1.0' ,p_commit => 'F' ,p_init_msg_list => 'T' ,p_msg_count => ln_msg_count ,p_msg_data => lc_msg_data ,p_return_status => lc_return_status ,p_pm_product_code => 'EJM' ,p_pa_project_id => p_project_id ,p_budget_type_code => g_budget_type ,p_budget_version_name => g_budget_version_name ,p_description => g_budget_version_name ,p_entry_method_code => g_budget_entry_mth_code ,p_budget_lines_in => lt_budget_lines_in ,p_budget_lines_out => lt_budget_lines_out );
  IF lc_return_status != 'S' THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'PA_BUDGET_PUB.create_draft_budget failed.'|| lc_concat_msg_out);
  END IF;
  PA_BUDGET_PUB.baseline_budget( p_api_version_number => '1.0' ,p_commit => 'F' ,p_init_msg_list => 'T' ,p_msg_count => ln_msg_count ,p_msg_data => lc_msg_data ,p_return_status => lc_return_status ,p_workflow_started => lc_workflow_started ,p_pm_product_code => 'EJM' ,p_pa_project_id => p_project_id ,p_budget_type_code => g_budget_type ,p_mark_as_original => g_budget_type);
  --Clear Budget variable
  PA_BUDGET_PUB.CLEAR_BUDGET;
  IF lc_return_status = 'S' THEN
    UPDATE XX_PA_BULK_CREATE_PRJ_STG
    SET status_mesg = status_mesg
      ||'-'
      ||'Budget creation successful',
      conc_req_id         = gn_request_id
    WHERE pan             = p_project_in.pan
    AND project_extension = p_project_in.project_extension;
    COMMIT;
  ELSE
    gn_success   :=gn_success   -1;
    gn_incomplete:=gn_incomplete+1;
    UPDATE XX_PA_BULK_CREATE_PRJ_STG
    SET status_mesg = status_mesg
      ||'-'
      ||'Budget creation failed',
      status              = 'IC',
      status_code         = 'Incomplete',
      conc_req_id         = gn_request_id
    WHERE pan             = p_project_in.pan
    AND project_extension = p_project_in.project_extension;
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'PA_BUDGET_PUB.baseline_budget  failed.'|| SUBSTR(lc_concat_msg_out,7000));
  END IF;
EXCEPTION
WHEN OTHERS THEN
  RAISE create_budget_exception;
END CREATE_BUDGET;
PROCEDURE PUBLISH_REPORT
IS
  -- Local Variable declaration
  lc_rpt_rid      NUMBER(15):=0;
  lb_layout       BOOLEAN;
  lb_req_status   BOOLEAN;
  lc_status_code  VARCHAR2(100);
  lc_phase        VARCHAR2(100);
  lc_status       VARCHAR2(100);
  lc_devphase     VARCHAR2(100);
  lc_devstatus    VARCHAR2(100);
  lc_message      VARCHAR2(1000);
  lb_print_option BOOLEAN;
  lc_exc_flag     BOOLEAN := FALSE;
  x_user_id       NUMBER;
BEGIN
  x_user_id  :=fnd_global.user_id();
  lb_layout  := fnd_request.add_layout(template_appl_name =>'XXFIN' , template_code => 'XXPABULKPRJKTRPT' , template_language => 'en' , template_territory => 'US' , output_format => 'EXCEL');
  lc_rpt_rid := FND_REQUEST.SUBMIT_REQUEST(application => 'XXFIN' , program => 'XXPABULKPRJKTRPT' , description => NULL , start_time => NULL , sub_request => FALSE);
  COMMIT;
  lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => lc_rpt_rid , interval => '2' , max_wait => '' , phase => lc_phase , status => lc_status , dev_phase => lc_devphase , dev_status => lc_devstatus , MESSAGE => lc_message);
  IF lc_rpt_rid <> 0 THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The report has been submitted and the request id is: '||lc_rpt_rid);
  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error submitting the report publisher request.');
    lc_exc_flag:=fnd_concurrent.set_completion_status('WARNING','Encountered an error while publishing the report.');
  END IF;
END PUBLISH_REPORT;
-- +============================================================================================+
-- |  Name: XX_PA_BULK_CREATE_PROJECT_PKG.FIND_SPCL_CHAR                                            |
-- |  Description: This pkg.procedure will remove special characters          - |
-- |               XX_PA_BULK_CREATE_PRJ_STG.                                                   |
-- =============================================================================================|
FUNCTION FIND_SPCL_CHAR(
    p_data_element IN VARCHAR2)
  RETURN NUMBER
IS
  ln_splchar_count NUMBER :=0;
BEGIN
  SELECT COUNT (1)
  INTO ln_splchar_count
  FROM
    (SELECT SUBSTR(p_data_element, REGEXP_INSTR(p_data_element,'[^a-z|A-Z|0-9 ]'),1) special_char
    FROM Dual
    WHERE (REGEXP_LIKE(p_data_element, '[[:space:]]{2}')
    OR REGEXP_LIKE (p_data_element, '[^A-Z|a-z|0-9| ]', 'i'))
    ) Temp
  GROUP BY Special_Char;
  RETURN ln_splchar_count;
EXCEPTION
WHEN OTHERS THEN
  RETURN 0;
END FIND_SPCL_CHAR;
-- +============================================================================================+
-- |  Name: XX_PA_BULK_CREATE_PROJECT_PKG.FETCH_DATA                                            |
-- |  Description: This pkg.procedure will insert the excel data in to staging table          - |
-- |               XX_PA_BULK_CREATE_PRJ_STG.                                                   |
-- =============================================================================================|
PROCEDURE FETCH_DATA(
    P_PAN                 VARCHAR2,
    P_PROJECT_EXTENSION   VARCHAR2,
    P_PROJECT_START_DATE  DATE,
    P_PROJECT_END_DATE    DATE,
    P_PROJECT_NAME        VARCHAR2,
    P_PROJECT_LONG_NAME   VARCHAR2,
    P_PROJECT_DESCRIPTION VARCHAR2,
    P_ADD_TO_DESC         VARCHAR2,
    P_PROJECT_MANAGER     VARCHAR2,
    P_TEMPLATE_NAME       VARCHAR2,
    P_PROJECT_LOCATION    VARCHAR2,
    P_PROJECT_ORG         VARCHAR2,
    P_CAPITAL_BUDGET      NUMBER,
    P_EXPENSE_BUDGET      NUMBER,
    P_Country             VARCHAR2,
    P_CURRENCY_CODE       VARCHAR2 DEFAULT 'USD',
    P_Project_Number      VARCHAR2 DEFAULT NULL,
    P_STATUS              VARCHAR2 DEFAULT 'I',
    P_STATUS_CODE         VARCHAR2 DEFAULT NULL,
    P_CONC_REQ_ID         NUMBER DEFAULT NULL,
    P_STATUS_MESG         VARCHAR2 DEFAULT NULL,
    P_ATTRIBUTE1          VARCHAR2 DEFAULT NULL,
    P_ATTRIBUTE2          VARCHAR2 DEFAULT NULL,
    P_ATTRIBUTE3          VARCHAR2 DEFAULT NULL,
    P_ATTRIBUTE4          VARCHAR2 DEFAULT NULL,
    P_ATTRIBUTE5          VARCHAR2 DEFAULT NULL,
    P_CREATION_DATE       DATE DEFAULT SYSDATE,
    P_CREATED_BY          NUMBER DEFAULT fnd_global.user_id,
    P_LAST_UPDATE_DATE    DATE DEFAULT SYSDATE,
    P_LAST_UPDATED_BY     NUMBER DEFAULT fnd_global.user_id,
    P_LAST_UPDATE_LOGIN   NUMBER DEFAULT fnd_global.user_id,
    P_error_mesg OUT VARCHAR2 ,
    P_flag OUT NUMBER)
AS
  lv_err_msg1 VARCHAR2(500) :=NULL;
  lv_err_msg2 VARCHAR2(500) :=NULL;
  lv_err_msg3 VARCHAR2(500) :=NULL;
  lv_err_msg4 VARCHAR2(500) :=NULL;
  ln_status   NUMBER        :=0;
BEGIN
  IF LENGTH(P_PROJECT_EXTENSION) != 8 THEN
    lv_err_msg1                  := 'Invalid Project Extension. Must be eight characters.';
  END IF;
  IF XX_PA_BULK_CREATE_PROJECT_PKG.FIND_SPCL_CHAR(P_PROJECT_NAME) > 0 THEN
    lv_err_msg2                                                  := 'PROJECT_NAME column contains extra spaces or special characters.';
  END IF;
  IF XX_PA_BULK_CREATE_PROJECT_PKG.FIND_SPCL_CHAR(P_PROJECT_LONG_NAME) > 0 THEN
    lv_err_msg3                                                       := 'PROJECT_LONG_NAME column contains extra spaces or special characters.';
  END IF;
  IF XX_PA_BULK_CREATE_PROJECT_PKG.FIND_SPCL_CHAR(P_PROJECT_DESCRIPTION) > 0 THEN
    lv_err_msg4                                                         := 'PROJECT_DESCRIPTION column contains extra spaces or special characters.';
  END IF;
  IF (lv_err_msg1 IS NOT NULL OR lv_err_msg2 IS NOT NULL OR lv_err_msg3 IS NOT NULL OR lv_err_msg4 IS NOT NULL) THEN
    fnd_message.CLEAR;
    fnd_message.set_name('XXFIN','XXFIN_PA_PRJ_VAL_ERROR1');
    FND_MESSAGE.SET_TOKEN('ERR1',lv_err_msg1);
    FND_MESSAGE.SET_TOKEN('ERR2',lv_err_msg2);
    FND_MESSAGE.SET_TOKEN('ERR3',lv_err_msg3);
    FND_MESSAGE.SET_TOKEN('ERR4',lv_err_msg4);
    ln_status := 1;
  ELSE
    FND_MESSAGE.SET_TOKEN('ERR1',' ');
    FND_MESSAGE.SET_TOKEN('ERR2',' ');
    FND_MESSAGE.SET_TOKEN('ERR3',' ');
    FND_MESSAGE.SET_TOKEN('ERR4',' ');
  END IF;
  IF ln_status = 0 THEN
    fnd_message.CLEAR;
    INSERT
    INTO XX_PA_BULK_CREATE_PRJ_STG
      (
        PAN,
        PROJECT_EXTENSION,
        PROJECT_START_DATE,
        PROJECT_END_DATE,
        PROJECT_NAME,
        PROJECT_LONG_NAME,
        PROJECT_DESCRIPTION,
        ADD_TO_DESC,
        PROJECT_MANAGER,
        TEMPLATE_NAME,
        PROJECT_LOCATION,
        PROJECT_ORG,
        CAPITAL_BUDGET,
        EXPENSE_BUDGET,
        COUNTRY ,
        CURRENCY_CODE,
        PROJECT_NUMBER,
        STATUS,
        STATUS_CODE,
        CONC_REQ_ID,
        STATUS_MESG,
        ATTRIBUTE1,
        ATTRIBUTE2,
        ATTRIBUTE3,
        ATTRIBUTE4,
        ATTRIBUTE5,
        CREATION_DATE,
        CREATED_BY,
        LAST_UPDATE_DATE,
        LAST_UPDATED_BY,
        LAST_UPDATE_LOGIN
      )
      VALUES
      (
        P_PAN,
        P_PROJECT_EXTENSION,
        P_PROJECT_START_DATE,
        P_PROJECT_END_DATE,
        P_PROJECT_NAME,
        P_PROJECT_LONG_NAME,
        P_PROJECT_DESCRIPTION,
        P_ADD_TO_DESC,
        P_PROJECT_MANAGER,
        P_TEMPLATE_NAME,
        P_PROJECT_LOCATION,
        P_PROJECT_ORG,
        P_CAPITAL_BUDGET,
        P_EXPENSE_BUDGET,
        P_COUNTRY,
        P_CURRENCY_CODE,
        p_project_number,
        'I',
        P_STATUS_CODE,
        P_CONC_REQ_ID,
        P_STATUS_MESG,
        P_ATTRIBUTE1,
        P_ATTRIBUTE2,
        P_ATTRIBUTE3,
        P_ATTRIBUTE4,
        P_Attribute5,
        Sysdate,
        fnd_global.user_id,
        sysdate,
        Fnd_Global.User_Id,
        fnd_global.login_id
      );
    IF SQL%rowcount > 0 THEN
      P_flag       := 0;
      P_error_mesg := NULL;
    END IF;
    COMMIT;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  P_error_mesg := sqlerrm;
  P_Flag       := 1;
END FETCH_DATA;
  -- +============================================================================================+
  -- |  Name: XX_PA_BULK_CREATE_PROJECT_PKG.XX_MAIN                                               |
  -- |  Description: This procedure will invoke the create_project API and create projects in     |
  -- |  Oracle.                                                                                   |
  -- =============================================================================================|
PROCEDURE XX_MAIN
  (
    errbuff OUT NOCOPY VARCHAR2,
    retcode OUT NOCOPY NUMBER
  )
IS
  --declarations
  ln_msg_count         NUMBER := 0;
  lc_msg_data          VARCHAR2(4000);
  lc_return_status     VARCHAR2(30);
  l_workflow_started   VARCHAR2(30) ;
  lc_data              VARCHAR2(4000);
  ln_msg_index         NUMBER := 1;
  ln_msg_index_out     NUMBER;
  ln_org_id            NUMBER;
  ln_projorgid         NUMBER;
  ln_templateid        NUMBER;
  ln_application_id    NUMBER;
  ln_responsibility_id NUMBER;
  lc_currency_code     VARCHAR2(30);
  lc_country_code      VARCHAR2(30);
  l_string             VARCHAR2(100);
  x_user_id            NUMBER;
  i                    NUMBER     :=0;
  k                    NUMBER     :=0;
  lc_exc_flag          BOOLEAN    := FALSE;
  lc_exception_flag    VARCHAR2(3):='N';
  lc_location_flag     VARCHAR2(3):='N';
  l_project_in PA_PROJECT_PUB.PROJECT_IN_REC_TYPE;
  l_project_out PA_PROJECT_PUB.PROJECT_OUT_REC_TYPE;
  l_key_members PA_PROJECT_PUB.PROJECT_ROLE_TBL_TYPE;
  l_class_categories PA_PROJECT_PUB.CLASS_CATEGORY_TBL_TYPE;
  l_tasks_in_rec PA_PROJECT_PUB.TASK_IN_REC_TYPE;
  l_tasks_in PA_PROJECT_PUB.TASK_IN_TBL_TYPE;
  l_tasks_out_rec PA_PROJECT_PUB.TASK_OUT_REC_TYPE;
  l_tasks_out PA_PROJECT_PUB.TASK_OUT_TBL_TYPE;
  l_rec_stg_data XX_PA_BULK_CREATE_PRJ_STG%ROWTYPE;
  CURSOR cur_stg_data(pan VARCHAR2,project_extension VARCHAR2)
  IS
    SELECT *
    FROM XX_PA_BULK_CREATE_PRJ_STG
    WHERE STATUS           ='I'
    AND pan               IS NOT NULL
    AND project_extension IS NOT NULL;
  CURSOR cur_stg_data_count
  IS
    SELECT pan,
      project_extension
    FROM XX_PA_BULK_CREATE_PRJ_STG
    WHERE STATUS           ='I'
    AND pan               IS NOT NULL
    AND project_extension IS NOT NULL;
  ln_count NUMBER         :=0;
TYPE rec_proj_details
IS
  RECORD
  (
    pan               VARCHAR2(25),
    project_extension VARCHAR2(50));
TYPE tbl_type_proj_details
IS
  TABLE OF rec_proj_details INDEX BY BINARY_INTEGER;
  tbl_proj_details tbl_type_proj_details;
BEGIN
  --fetching the request ID for the current concurrent request.
  gn_request_id := FND_GLOBAL.CONC_REQUEST_ID;
  --Delete older records from the staging table.
  DELETE
  FROM XX_PA_BULK_CREATE_PRJ_STG
  WHERE status IN ('P','E','IC');
  --Delete any blank rows from the table
  DELETE
  FROM XX_PA_BULK_CREATE_PRJ_STG
  WHERE (pan              IS NULL
  AND project_extension   IS NULL
  AND project_start_date  IS NULL
  AND project_end_date    IS NULL
  AND project_name        IS NULL
  AND project_long_name   IS NULL
  AND project_description IS NULL
  AND add_to_desc         IS NULL
  AND project_manager     IS NULL
  AND template_name       IS NULL
  AND project_location    IS NULL
  AND project_org         IS NULL
  AND capital_budget      IS NULL
  AND expense_budget      IS NULL
  AND country             IS NULL
  AND currency_code       IS NULL);
  --Update status to E if either PAN or new project extension details is NULL
  UPDATE XX_PA_BULK_CREATE_PRJ_STG
  SET status            = 'E',
    status_code         = 'Error',
    status_mesg         = 'The PAN or new project extension details are NULL',
    conc_req_id         = gn_request_id
  WHERE pan            IS NULL
  OR project_extension IS NULL;
  COMMIT;
  OPEN cur_stg_data_count;
  FETCH cur_stg_data_count BULK COLLECT INTO tbl_proj_details;
  ln_count:=cur_stg_data_count%ROWCOUNT;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of eligible projects in staging table : '||ln_count);
  IF ln_count=0 THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'There are no projects eligible in the staging table.');
    --publish report in excel
    PUBLISH_REPORT();
    RETURN;
  END IF;
  FOR i IN 1..ln_count
  LOOP --LOOP for processing each record in the staging table
    OPEN cur_stg_data(tbl_proj_details(i).pan,tbl_proj_details(i).project_extension);
    FETCH cur_stg_data INTO l_rec_stg_data;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening the cursor for - '||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
    --clearing data in composite datatypes at begining of iteration
    l_key_members.DELETE;
    l_class_categories.DELETE;
    l_tasks_in.DELETE;
    l_tasks_out.DELETE;
    BEGIN --inner block1
      --fetching country code based on country name given
      SELECT territory_code
      INTO lc_country_code
      FROM fnd_territories_tl
      WHERE UPPER(TRIM(territory_short_name))=UPPER(TRIM(l_rec_stg_data.country))
      AND LANGUAGE                           = USERENV('LANG');
      --fetch template and org details
      SELECT T.project_id templateid,
        O.organization_id projorgid,
        OU.organization_id org_id,
        R.application_id,
        R.responsibility_id
      INTO ln_templateid,
        ln_projorgid,
        ln_org_id,
        ln_application_id,
        ln_responsibility_id
      FROM PA_PROJECTS_ALL T
      LEFT JOIN hr_all_organization_units O
      ON UPPER(O.name) = UPPER(l_rec_stg_data.project_org)
      LEFT JOIN xx_fin_translatevalues V
      ON UPPER(V.source_value1) = UPPER(lc_country_code)
      JOIN xx_fin_translatedefinition D
      ON D.translate_id      = V.translate_id
      AND D.translation_name = 'OD_COUNTRY_DEFAULTS'
      JOIN hr_operating_units OU
      ON OU.name = V.target_value2
      JOIN fnd_lookup_values_vl L
      ON L.lookup_code        = OU.name
      AND L.lookup_type       = 'PA_RESPONSBILITY_ID'
      AND (L.end_date_active >= sysdate
      OR L.end_date_active   IS NULL)
      AND L.enabled_flag      = 'Y'
      LEFT JOIN FND_RESPONSIBILITY_TL R
      ON R.responsibility_name = L.meaning
      WHERE UPPER(T.name)      = UPPER(l_rec_stg_data.template_name)
      AND template_flag        = 'Y';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered error while fetching org and template details: '||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'E',
        status_code         = 'Error',
        status_mesg         = 'Error fetching org and template details.',
        conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      gn_failure:=gn_failure+1;
      GOTO loop_to_continue;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception while fetching org and template details- '||SUBSTR (SQLERRM, 1, 225)||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'E',
        status_code         = 'Error',
        status_mesg         = 'Encountered exception while fetching org and template details.',
        conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      gn_failure       :=gn_failure+1;
      lc_exception_flag:='Y';
      GOTO loop_to_continue;
    END; --inner block1
    --fetching translation values
    BEGIN --inner block2
      SELECT b.target_value1,
        b.target_value2,
        b.target_value3,
        b.target_value4,
        b.target_value5 ,
        TO_NUMBER(b.target_value8,'9.9')
      INTO g_pm_product_code,
        g_budget_type,
        g_budget_entry_mth_code,
        g_resource_list_id,
        g_budget_version_name,
        g_api_version_number
      FROM XX_FIN_TRANSLATEDEFINITION a,
        XX_FIN_TRANSLATEVALUES b
      WHERE a.Translation_name = 'OD_PA_CREAT_PRJ_INTERFACE'
      AND a.translate_id       = b.translate_id
      AND b.source_value1      = 'EJM';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered error while fetching translation values'||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'E',
        status_code         = 'Error',
        status_mesg         = 'Error fetching translation values.',
        conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      gn_failure:=gn_failure+1;
      GOTO loop_to_continue;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception while fetching translation values- '||SUBSTR (SQLERRM, 1, 225)||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'E',
        status_code         = 'Error',
        status_mesg         = 'Encountered exception while fetching translation values.',
        conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      gn_failure       :=gn_failure+1;
      lc_exception_flag:='Y';
      GOTO loop_to_continue;
    END; --inner block2
    -- SET GLOBAL VALUES, This is not required as the application would itself set the context.The solution is integrated with Oracle Apps using Function-responsibility security
    /* pa_interface_utils_pub.set_global_info( p_api_version_number => 1.0,
    p_responsibility_id => ln_responsibility_id,
    p_user_id => x_user_id,
    p_msg_count => ln_msg_count,
    p_msg_data => lc_msg_data,
    p_return_status => lc_return_status);*/
    --load values to project_in composite datatype.
    IF(LENGTH(TRIM(l_rec_stg_data.project_name))>30) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Length of project name exceeds allowed limit - '||l_rec_stg_data.project_name);
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'E',
        status_code         = 'Error',
        status_mesg         = 'Error: Length of project name exceeds allowed limit.',
        conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      gn_failure:=gn_failure+1;
      GOTO loop_to_continue;
    END IF;
    IF (TRIM(l_rec_stg_data.project_long_name) IS NULL) THEN
      l_project_in.long_name                   :=NULL;
    ELSE
      l_project_in.long_name:=l_rec_stg_data.project_long_name||'-'||l_rec_stg_data.add_to_desc;
    END IF;
    IF (TRIM(l_rec_stg_data.project_description) IS NULL) THEN
      l_project_in.description                   :=l_rec_stg_data.add_to_desc;
    ELSE
      l_project_in.description:=l_rec_stg_data.project_description||'-'||l_rec_stg_data.add_to_desc;
    END IF;
    IF (TRIM(l_rec_stg_data.project_name)                                                     IS NULL) THEN
      l_project_in.project_name                                                               :=NULL;
    ELSIF (LENGTH(TRIM(l_rec_stg_data.project_name))+ LENGTH(TRIM(l_rec_stg_data.add_to_desc)) > 30) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'The combined Length of project_name and add_to_desc fields exceed allowed limit.');
      l_project_in.project_name             :=l_rec_stg_data.project_name;
    ELSIF (TRIM(l_rec_stg_data.add_to_desc) IS NULL) THEN
      l_project_in.project_name             :=l_rec_stg_data.project_name;
      l_project_in.description              :=l_rec_stg_data.project_description;
      l_project_in.long_name                :=l_rec_stg_data.project_long_name;
    ELSE
      l_project_in.project_name:=l_rec_stg_data.project_name||'-'||l_rec_stg_data.add_to_desc;
    END IF;
    l_project_in.created_from_project_id     :=ln_templateid;
    l_project_in.project_status_code         :='UNAPPROVED';
    l_project_in.carrying_out_organization_id:=ln_projorgid;
    l_project_in.pm_project_reference        :=l_rec_stg_data.pan||'-'||l_rec_stg_data.project_extension;
    l_project_in.start_date                  :=l_rec_stg_data.project_start_date;
    l_project_in.completion_date             :=l_rec_stg_data.project_end_date;
    l_project_in.country_code                :=lc_country_code;
    l_project_in.project_currency_code       :=UPPER(l_rec_stg_data.currency_code);
    --loading key member details
    BEGIN--inner block3
      k :=1;
	  --NAIT-92099 --- COMMENTED FOR PERFORMANCE ISSUE
      /*SELECT employee_id
      INTO l_key_members(k).person_id
      FROM hr_employees
      WHERE employee_num                 =l_rec_stg_data.project_manager;*/
	  SELECT person_id
      INTO l_key_members(k).person_id
      FROM per_all_people_f
	  where  TRUNC(SYSDATE) 
     BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE and 
       nvl(employee_number,npw_number)     =l_rec_stg_data.project_manager;
      l_key_members(k).project_role_type:='PROJECT MANAGER';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unable to fetch key member details for - '||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'E',
        status_code         = 'Error',
        status_mesg         = 'Unable to fetch key member details.',
        conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      gn_failure:=gn_failure+1;
      GOTO loop_to_continue;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception while fetching key member details - '||SUBSTR (SQLERRM, 1, 225)||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'E',
        status_code         = 'Error',
        status_mesg         = 'Encountered exception while fetching key member details.',
        conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      gn_failure       :=gn_failure+1;
      lc_exception_flag:='Y';
      GOTO loop_to_continue;
    END;--inner block3
    --Calling pa_project_pub.init_project
    pa_project_pub.init_project;
    BEGIN--inner block4
      --loading task details
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling LOAD_TASKS procedure..'||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
      LOAD_TASKS(l_rec_stg_data,NULL,NULL,l_tasks_in,ln_templateid,ln_projorgid);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Completed LOAD_TASKS procedure..'||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
    EXCEPTION
    WHEN load_tasks_exception THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the LOAD_TASKS block..'||SUBSTR (SQLERRM, 1, 225)||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'E',
        status_code         = 'Error',
        status_mesg         = 'Error loading tasks.',
        conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      gn_failure       :=gn_failure+1;
      lc_exception_flag:='Y';
      GOTO loop_to_continue;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the LOAD_TASKS block..'||SUBSTR (SQLERRM, 1, 225)||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'E',
        status_code         = 'Error',
        status_mesg         = 'Encountered exception while loading tasks.',
        conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      gn_failure       :=gn_failure+1;
      lc_exception_flag:='Y';
      GOTO loop_to_continue;
    END;  --inner block4
    BEGIN --inner block5
      --resetting variables
      l_project_in.attribute1        :=NULL;
      l_project_in.attribute_category:=NULL;
      SELECT 'Y'
      INTO lc_location_flag
      FROM FND_FLEX_VALUES FFV,
        FND_FLEX_VALUE_SETS FFVS
      WHERE FFV.flex_value_set_id        =FFVS.flex_value_set_id
      AND FFVS.flex_value_set_name       = 'OD_GL_GLOBAL_LOCATION'
      AND FFV.flex_value                 =TRIM(l_rec_stg_data.project_location);
      IF (lc_location_flag               ='Y') THEN
        l_project_in.attribute_category :='GLOBAL DATA ELEMENTS';
        l_project_in.attribute1         :=TRIM(l_rec_stg_data.project_location);
      END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL; --do nothing, pass NULL location to API
      /*FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unable to fetch location details for - '||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'E',
      status_code         = 'Error',
      status_mesg         = 'Unable to fetch location details.',
      conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      gn_failure:=gn_failure+1;
      GOTO loop_to_continue;*/
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the project location block- '||SUBSTR (SQLERRM, 1, 225)||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'E',
        status_code         = 'Error',
        status_mesg         = 'Encountered exception while fetching project location details.',
        conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      gn_failure       :=gn_failure+1;
      lc_exception_flag:='Y';
      GOTO loop_to_continue;
    END; --inner block5
    --Initialize the message stack
    FND_MSG_PUB.initialize;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoking the create_project API..');
    --invoke the API..
    pa_project_pub.create_project(p_api_version_number => 1.0, p_commit => FND_API.G_FALSE, p_init_msg_list => FND_API.G_TRUE, p_msg_count => ln_msg_count, p_msg_data => lc_msg_data, p_return_status => lc_return_status, p_workflow_started => l_workflow_started, p_pm_product_code => 'EJM', p_project_in => l_project_in, p_project_out => l_project_out, p_key_members => l_key_members, p_class_categories => l_class_categories, p_tasks_in => l_tasks_in, p_tasks_out => l_tasks_out);
    IF lc_return_status = 'S' THEN --status check loop
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Project Creation successful!');
      gn_success:=gn_success+1;
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status            = 'P',
        status_code         = 'Processed',
        status_mesg         = 'Project Creation successful',
        conc_req_id         = gn_request_id,
        project_number      = l_project_out.pa_project_number
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
      BEGIN--inner block6
        --assigning assets to the project created..
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling ASSIGN_ASSETS procedure for project created, Project ID : '||l_project_out.pa_project_id||' Project Number : '||l_project_out.pa_project_number);
        ASSIGN_ASSETS(l_rec_stg_data,l_project_out.pa_project_id,ln_templateid);
      EXCEPTION
      WHEN assign_assets_exception THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the ASSIGN_ASSETS block..'||SUBSTR (SQLERRM, 1, 225)||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
        gn_success   :=gn_success   -1;
        gn_incomplete:=gn_incomplete+1;
        UPDATE XX_PA_BULK_CREATE_PRJ_STG
        SET status    = 'IC',
          status_code = 'Incomplete',
          status_mesg = status_mesg
          ||'-'
          ||'Error assigning assets.',
          conc_req_id         = gn_request_id
        WHERE pan             = tbl_proj_details(i).pan
        AND project_extension = tbl_proj_details(i).project_extension;
        COMMIT;
        lc_exception_flag:='Y';
        GOTO loop_to_continue;
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the ASSIGN_ASSETS block- '||SUBSTR (SQLERRM, 1, 225)||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
        gn_success   :=gn_success   -1;
        gn_incomplete:=gn_incomplete+1;
        UPDATE XX_PA_BULK_CREATE_PRJ_STG
        SET status    = 'IC',
          status_code = 'Incomplete',
          status_mesg = status_mesg
          ||'-'
          ||'Error assigning assets.',
          conc_req_id         = gn_request_id
        WHERE pan             = tbl_proj_details(i).pan
        AND project_extension = tbl_proj_details(i).project_extension;
        COMMIT;
        lc_exception_flag:='Y';
        GOTO loop_to_continue;
      END; --inner block6
      BEGIN--inner block7
        --creating budget for the project created..
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling CREATE_BUDGET procedure for project created, Project ID : '||l_project_out.pa_project_id||' Project Number : '||l_project_out.pa_project_number);
        CREATE_BUDGET(l_project_out.pa_project_id,l_rec_stg_data);
      EXCEPTION
      WHEN create_budget_exception THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the CREATE_BUDGET block- '||SUBSTR (SQLERRM, 1, 225)||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
        gn_success   :=gn_success   -1;
        gn_incomplete:=gn_incomplete+1;
        UPDATE XX_PA_BULK_CREATE_PRJ_STG
        SET status    = 'IC',
          status_code = 'Incomplete',
          status_mesg = status_mesg
          ||'-'
          ||'Error creating budget.',
          conc_req_id         = gn_request_id
        WHERE pan             = tbl_proj_details(i).pan
        AND project_extension = tbl_proj_details(i).project_extension;
        COMMIT;
        lc_exception_flag:='Y';
        GOTO loop_to_continue;
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered exception in the CREATE_BUDGET block- '||SUBSTR (SQLERRM, 1, 225)||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
        gn_success   :=gn_success   -1;
        gn_incomplete:=gn_incomplete+1;
        UPDATE XX_PA_BULK_CREATE_PRJ_STG
        SET status    = 'IC',
          status_code = 'Incomplete',
          status_mesg = status_mesg
          ||'-'
          ||'Error creating budget.',
          conc_req_id         = gn_request_id
        WHERE pan             = tbl_proj_details(i).pan
        AND project_extension = tbl_proj_details(i).project_extension;
        COMMIT;
        lc_exception_flag:='Y';
        GOTO loop_to_continue;
      END;--inner block7
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Project creation failed.');
      IF ln_msg_count>0 THEN
        FOR I IN 1..LN_MSG_COUNT
        LOOP
          PA_INTERFACE_UTILS_PUB.GET_MESSAGES( P_MSG_DATA => LC_MSG_DATA, P_ENCODED => 'F', P_DATA => LC_DATA, P_MSG_COUNT => LN_MSG_COUNT, P_MSG_INDEX => LN_MSG_INDEX, P_MSG_INDEX_OUT => LN_MSG_INDEX_OUT);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error ' || ln_msg_index || ': ' ||lc_data);
        END LOOP;
      END IF;
      gn_failure:=gn_failure+1;
      UPDATE XX_PA_BULK_CREATE_PRJ_STG
      SET status    = 'E',
        status_code = 'Error',
        status_mesg = 'Error : '
        ||lc_data,
        conc_req_id         = gn_request_id
      WHERE pan             = tbl_proj_details(i).pan
      AND project_extension = tbl_proj_details(i).project_extension;
      COMMIT;
    END IF; --closing status check loop
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'COMPLETED processing - '||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension);
    <<loop_to_continue>> --label to enable continue processing rest of the records in case of exception encountered
    CLOSE cur_stg_data;  --closing the cursor for a particular project
  END LOOP;              --closing the FOR loop
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'COMPLETED processing all eligible records in the staging table.');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of projects successfully loaded along with asset and budget assignments:'||gn_success);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of incomplete projects loaded without asset and budget assignments:'||gn_incomplete);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of failures :'||gn_failure);
  --publish report in excel
  PUBLISH_REPORT();
  --in case of any exceptions encountered, setting concurrent request status to WARNING
  IF lc_exception_flag='Y' THEN
    lc_exc_flag      :=fnd_concurrent.set_completion_status('WARNING','Concurrent request encountered an error.Please refer to log file for details.');
    COMMIT;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered the exception while processing the record : '||tbl_proj_details(i).pan||' - '||tbl_proj_details(i).project_extension||' -> ' ||SUBSTR (SQLERRM, 1, 225));
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'End Time: ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH:MI:SS AM') );
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'The PA Bulk Create Projects completed in error. Please refer to log file for details');
  UPDATE XX_PA_BULK_CREATE_PRJ_STG
  SET status            = 'E',
    status_code         = 'Error',
    conc_req_id         = gn_request_id,
    status_mesg         = 'Encountered an exception.'
  WHERE pan             = tbl_proj_details(i).pan
  AND project_extension = tbl_proj_details(i).project_extension;
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Request : '||gn_request_id||' completed in error. Please refer to log file for more details.');
  lc_exc_flag:=fnd_concurrent.set_completion_status('ERROR','Concurrent request encountered an error.Please refer to log file for details.');
  --publish report in excel
  PUBLISH_REPORT();
  COMMIT;
END XX_MAIN;
END XX_PA_BULK_CREATE_PROJECT_PKG;
/
SHOW ERRORS;
EXIT;