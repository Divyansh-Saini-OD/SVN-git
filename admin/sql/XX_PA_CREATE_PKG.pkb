	create or replace
	PACKAGE BODY XX_PA_CREATE_PKG
	AS
	-- +===================================================================+
	-- |                  Office Depot - Project Simplify                  |
	-- |                       WIPRO Technologies                          |
	-- +===================================================================+
	-- | Name :OD:PA Projects Interface                                    |
	-- | Description : To get the Projects detail from                     |
	-- |                legacy system(EJM) to Oracle Project Accounting.   |
	-- |                                                                   |
	-- |                                                                   |
	-- | Change Record:                                                    |
	-- | ===============                                                   |
	-- | Version   Date          Author              Remarks               |
	-- | =======   ==========   =============        ======================|
	-- | 1.0       26-MAR-2007  Raj Patel            Initial version       |
	-- | 2.0       02-JUL-2007  Raj Patel                                  |
	-- | 2.1       03-NOV-2007  Raghu                added code to trap API|
	-- |                                             error.		           |
	-- | 2.2       04-JAN-2008  KK		               Added to code to    |
	-- |                                             handle defect 3152    |
	-- | 3.0       04-JAN-2008  Daniel Ligas         Re-arranged order     |
	-- |                                             for readability       |
	-- | 3.1       24-FEB-2009  Daniel Ligas         Improve Error handling|
	-- |                                             for readability       |
	-- | 3.2       09-MAR-2009  Daniel Ligas         Add task              |
	-- |                                             asset assignment      |
	-- | 3.0       22-MAR-2012  P.Marco              EJM Rewrite for SOA   |
	-- |                                             PR000370              | 
	-- | 3.1       28-JUN-2012 P.Marco              Defect 19010           |
	-- |                                             Fix Error handling    |
	-- |                                             Format Email notifica-|
	-- |                                              tion                 |
	-- | 3.2       03-JUL-2013  Veronica             Added for R12 Retrofit|
	-- |                                             Upgrade               |
	-- | 3.3       17-NOV-2015  Harvinder Rakhra     Retrofit R12.2        |
	-- +===================================================================+
	-- +===================================================================+
	-- | Name  : XX_PA_GET_PROJECT_DATA                                    |
	-- | Description      : This Procedure will be used to fetch Proejct   |
	-- |                    data from source system(SQL SERVER) and        |
	-- |                    if successfully then update with "S"           |
	-- |                    otherwise update with "E" and send error       |
	-- |                    notification.                                  |
	-- |                                                                   |
	-- | Parameters :       p_pm_product_code,p_budget_type,               |
	-- |                    p_budget_entry_mth_code,                       |
	-- |                    p_resource_list_id,p_email_addr                |
	-- | Returns    :       x_error_code,x_error_buff                      |
	-- +===================================================================+

	  ex_pa_create_error      EXCEPTION;
	  PRAGMA EXCEPTION_INIT(ex_pa_create_error, -20000);
	  
	  
	  mf_output_errors_exists BOOLEAN := false;
	  ms_dump_msgdata         VARCHAR2(10000);
	  mn_pj_id                NUMBER;
	  
	  g_FileHandle           UTL_FILE.FILE_TYPE;  -- PJM Added
	  gc_debug_text          VARCHAR2(500);
	  g_msg_data             VARCHAR2(11000);
	  g_status_code          VARCHAR2(1);
	  g_email_status_code    VARCHAR2(1);
	  g_email_message        Varchar2(8000);
	  g_api_version_number   NUMBER := 1.0;

	  g_pm_product_code        FND_LOOKUP_VALUES_VL.lookup_code%TYPE;
	  g_budget_type            PA_BUDGET_TYPES.budget_type_code%TYPE;
	  g_budget_entry_mth_code  PA_BUDGET_ENTRY_METHODS.budget_entry_method_code%TYPE;
	  g_resource_list_id       PA_RESOURCE_LISTS.resource_list_id%TYPE;
	  g_budget_version_name    VARCHAR2(20);
	  
	  g_debug_flag             VARCHAR2(1) := 'C';

	  PROCEDURE SET_RESPONSE_MESSAGE (p_panex IN VARCHAR2 ,
									  p_project_num  IN NUMBER,
									  p_status_code  IN VARCHAR2,
									  p_message_out  IN VARCHAR2) AS
	  
	  
	  BEGIN
	  
		 gc_debug_text  := 'Calling SET_RESPONSE_MESSAGE ';
	  
	  END SET_RESPONSE_MESSAGE;  
	 
	  PROCEDURE LOG_ERROR(
		p_procedure_name          IN  VARCHAR2
		,p_error_message_code     IN  VARCHAR2
		,p_error_message          IN  VARCHAR2
		,p_error_message_severity IN  VARCHAR2
		,p_object_type            IN  VARCHAR2
		,p_object_id              IN  VARCHAR2
	  ) AS
	  BEGIN 
	   -- LOG_ERROR
		XX_COM_ERROR_LOG_PUB.LOG_ERROR (
		p_program_type            => 'CONCURRENT PROGRAM'
		,p_program_name            => 'OD: PA Projects Interface'
		,p_program_id              => FND_GLOBAL.conc_request_id
		,p_module_name             => 'PA'
		,p_error_location          => p_procedure_name
		,p_error_message_count     => 1
		,p_error_message_code      => p_error_message_code
		,p_error_message           => p_error_message
		,p_error_message_severity  => p_error_message_severity
		,p_notify_flag             => 'N'
		,p_object_type             => p_object_type
		,p_object_id               => p_object_id
		,p_attribute1              => 'FIN'
		,p_attribute2              => 'PA');
		--COMMIT;
	  END LOG_ERROR;

	  PROCEDURE DUMP_MSG(
	   p_debug_level     IN  VARCHAR2
	   ,p_procedure_name IN  VARCHAR2
	   ,p_msg            IN  VARCHAR2
	  ) AS
		l_line VARCHAR2(61) := '------------------------------------------------------------' || CHR(13);
		l_indent VARCHAR2(6) := '-    -';
		l_msg VARCHAR2(1000);

	  BEGIN --DUMP_MSG
		-- 1 - error
		-- 2 - warning
		-- 3 - info
		IF p_msg = '+' THEN
		  l_msg := CHR(13) || l_line
				   || '>>START procedure ' || p_procedure_name || CHR(13)
				   || l_line;
		ELSIF p_msg = '-' THEN
		  l_msg := l_line
				   || '<<<<END procedure ' || p_procedure_name || CHR(13)
				   || l_line;
		ELSIF p_msg = '.' THEN
		  l_msg := l_line || CHR(10) || CHR(10);
		ELSE
		  l_msg := '(' || p_debug_level || ') {' || p_procedure_name || '} ' || p_msg;
		  l_msg := REPLACE(l_msg, CHR(13), CHR(13) || l_indent);
		  l_msg := REPLACE(l_msg, CHR(10), CHR(10) || l_indent);
		END IF;
		
		------------------------------------------------------------
		-- Setting g_debug_flag = to Y will log details to log file 
		-- Flag can be set on OD_PA_CREAT_PRJ_INTERFACE transaltion 
		-- table.(PR000370)
		------------------------------------------------------------    
		IF g_debug_flag = 'Y' THEN

		  UTL_FILE.PUT_LINE(g_FileHandle, l_msg);   
		  
		END IF;    
		
		IF g_debug_flag = 'C' THEN
			DBMS_OUTPUT.PUT_LINE(l_msg);
		END IF;
		
		
		IF p_debug_level = '1' THEN
		  mf_output_errors_exists := true;
		  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, l_msg);
		  IF g_debug_flag = 'C' THEN
			DBMS_OUTPUT.PUT_LINE(l_msg);
		  END IF;
		  LOG_ERROR(
			p_procedure_name          => p_procedure_name
			,p_error_message_code     => 'E'
			,p_error_message          => l_msg
			,p_error_message_severity => 'FAIL'
			,p_object_type            => NULL
			,p_object_id              => NULL);
		 -- ms_dump_msgdata := ms_dump_msgdata || p_msg || chr(13);           -- removed casusing duplicates per defect 19010 
		END IF;

	  END DUMP_MSG;

	  PROCEDURE DUMP_MSGDATA(
	   p_procedure_name IN  VARCHAR2
	   ,p_return_status IN  VARCHAR2
	   ,p_msg_count     IN  NUMBER
	   ,p_msg_data      IN  VARCHAR2
	   ,x_msg_data_out  OUT VARCHAR2                                                 -- Added per defect 19010
	  ) AS
		ln_msg_index      NUMBER := 1;
		lc_str_data       VARCHAR2(2000);
		ln_msg_index_out  NUMBER;

	  BEGIN -- DUMP_MSGDATA
		DUMP_MSG(3, p_procedure_name, 'p_return_status:' || p_return_status);
		DUMP_MSG(3, p_procedure_name, 'p_msg_count    :' || p_msg_count);

		FOR i IN 1..NVL(p_msg_count,0)
		LOOP
		   pa_interface_utils_pub.get_messages(
				  p_msg_data       => p_msg_data
				  ,p_encoded       => 'F'
				  ,p_data          => lc_str_data
				  ,p_msg_count     => p_msg_count
				  ,p_msg_index     => ln_msg_index
				  ,p_msg_index_out => ln_msg_index_out);
		   DUMP_MSG(1, p_procedure_name, 'Error message:'|| lc_str_data || chr(13));
		   ms_dump_msgdata := ms_dump_msgdata || lc_str_data || chr(13);
		   ln_msg_index := ln_msg_index_out;
		END LOOP;
			x_msg_data_out    := ms_dump_msgdata;                                    -- Added per defect 19010
	  END DUMP_MSGDATA;

	  FUNCTION GET_PROJECT_ID_FROM_PANEX(p_panex VARCHAR2)
	  RETURN NUMBER
	  IS
		ln_panex_count NUMBER;
		ln_project_id  NUMBER;
	  BEGIN
		SELECT COUNT(*)
		  INTO ln_panex_count
		  FROM PA_PROJECTS_ALL
		 WHERE SEGMENT1 = p_panex;

		IF ln_panex_count = 1 THEN
		  SELECT project_id
			INTO ln_project_id
			FROM PA_PROJECTS_ALL
		   WHERE SEGMENT1 = p_panex;
		  RETURN ln_project_id;
		ELSE
		  RETURN null;
		END IF;
	  END GET_PROJECT_ID_FROM_PANEX;

	  PROCEDURE LOAD_KEYM(
		  p_proj_rec     IN         XX_PA_EJM_PROJ_INT_REC    --added PR000370
		 ,p_project_data IN         XX_PA_EJM_PROJ_INT_TBL    --added PR000370
		,p_key_members   OUT NOCOPY  pa_project_pub.project_role_tbl_type
	  ) AS
	  
		 ln_cnt NUMBER;
		 ln_person_id  NUMBER;
	  BEGIN
	  --    FOR lcsr_keym IN mcsr_keym(p_panex)
		 ln_cnt := 0;
		 gc_debug_text := 'Procedure- LOAD_KEYM';

		 FOR i in p_project_data.first .. p_project_data.last LOOP
	 
		  -------------------------------------------------
		  -- Only load member records for the current panex
		  -------------------------------------------------
		  IF p_proj_rec.panex =  p_project_data(i).panex  THEN

				 FOR j IN p_project_data(i).MEMBER_REC.first .. p_project_data(i).MEMBER_REC.last LOOP 
				 
				   IF p_project_data(i).MEMBER_REC(j).EMPLOYEEID IS NULL THEN
					   DUMP_MSG(1, 'LOAD_KEYM', 'employee_id: NULL'
										   || ', role: ' || p_project_data(i).MEMBER_REC(j).role);
				  
					   
					   g_msg_data := g_msg_data || 'Error: employee_id IS NULL'||'For Panex '||p_project_data(i).panex;
					   g_status_code  :=  'E';
				   END IF;
				 
				BEGIN  
				
				 SELECT employee_id
				   INTO ln_person_id
				   FROM HR_EMPLOYEES 
				  WHERE employee_num = p_project_data(i).MEMBER_REC(j).EMPLOYEEID;
				
				EXCEPTION  
				 WHEN NO_DATA_FOUND THEN                                                 -- Added no datat found per defect 19010 
					   DUMP_MSG(1, 'LOAD_KEYM', 'Error deriving person_id '
										   || ', EMPLOYEEID: ' || p_project_data(i).MEMBER_REC(j).EMPLOYEEID);
				  
					   
					   g_msg_data := g_msg_data || 'Error: person_id was not found '||'For Panex '||p_project_data(i).panex
										 || ', EMPLOYEEID: ' || p_project_data(i).MEMBER_REC(j).EMPLOYEEID;
					   g_status_code  :=  'E';  
				
				  WHEN OTHERS THEN
					   DUMP_MSG(1, 'LOAD_KEYM', 'Error deriving person_id -When Others '
										   || ', EMPLOYEEID: ' || p_project_data(i).MEMBER_REC(j).EMPLOYEEID);
				  
					   
					   g_msg_data := g_msg_data || 'Error: Getting person_id  '||'For Panex '||p_project_data(i).panex
										 || ', EMPLOYEEID: ' || p_project_data(i).MEMBER_REC(j).EMPLOYEEID ||
										 ': '||substr(sqlerrm,1,400) ;
					   g_status_code  :=  'E';                                
				  
				END; 
				 
				   p_key_members(j).person_id := ln_person_id; 
				   p_key_members(j).project_role_type := p_project_data(i).MEMBER_REC(j).role;
				   
				   ln_cnt := ln_cnt + 1;
				   
				   DUMP_MSG(3, 'LOAD_KEYM', 'employee_id'||'('||i||'): '|| p_project_data(i).MEMBER_REC(j).EMPLOYEEID
										 || ', role'||'('||i||'): ' || p_project_data(i).MEMBER_REC(j).role);             
				END Loop;   
	 
		  END IF;
		  
		END LOOP;

	  END LOAD_KEYM;

	  PROCEDURE LOAD_TASKS(
		 p_parent_task_id     IN NUMBER
		,p_parent_task_number IN VARCHAR2
		,p_project_in         IN XX_PA_EJM_PROJ_INT_REC                     -- Added PR000370
		,pt_tasks_in          IN OUT NOCOPY pa_project_pub.task_in_tbl_type -- Added PR000370
		,p_template_id        IN NUMBER                                     -- Added PR000370
		,p_proj_org_id        IN NUMBER                                     -- Added PR000370
	  ) AS
		lr_tasks_in_rec          pa_project_pub.task_in_rec_type;
		lc_parent_task_number    pa_tasks.TASK_NUMBER%TYPE;
						  
		 CURSOR mcsr_tasks(p_project_id NUMBER,
						  p_parent_task_id NUMBER) IS
							
		  SELECT T.*, P.carrying_out_organization_id template_projorgid
			FROM pa_tasks T
				 JOIN pa_projects_all P
					  ON P.project_id = T.project_id
		   WHERE T.project_id = p_project_id
				 AND ((parent_task_id = p_parent_task_id) OR
				  (p_parent_task_id is null AND parent_task_id IS null))
		   ORDER BY task_number;
	  BEGIN

		FOR lcsr_task IN mcsr_tasks(p_template_id, p_parent_task_id)    
		LOOP

		  DUMP_MSG(3, 'LOAD_TASKS', ' task_number:' || lcsr_task.task_number);
		  
		  lr_tasks_in_rec.pm_task_reference := lcsr_task.task_number;

		  lr_tasks_in_rec.task_name := lcsr_task.task_name;
		  lr_tasks_in_rec.long_task_name := lcsr_task.long_task_name;
		  lr_tasks_in_rec.pa_task_number := lcsr_task.task_number;
		  lr_tasks_in_rec.task_description := lcsr_task.description;
		  lr_tasks_in_rec.task_start_date := p_project_in.StartDate;
		  lr_tasks_in_rec.task_completion_date := p_project_in.CompletionDate;
		  lr_tasks_in_rec.service_type_code := lcsr_task.service_type_code;
		  lr_tasks_in_rec.billable_flag := lcsr_task.billable_flag;
		  lr_tasks_in_rec.chargeable_flag := lcsr_task.chargeable_flag;
		  
		  -- defect #13470
		  IF (lcsr_task.template_projorgid != lcsr_task.carrying_out_organization_id) THEN
			lr_tasks_in_rec.carrying_out_organization_id := lcsr_task.carrying_out_organization_id;
		  ELSE
			lr_tasks_in_rec.carrying_out_organization_id := p_proj_org_id; --p_project_in.projorg;
		  END IF;
		  lr_tasks_in_rec.task_manager_person_id := lcsr_task.task_manager_person_id;
		  lr_tasks_in_rec.work_type_id := lcsr_task.work_type_id;
		  lr_tasks_in_rec.attribute1 := lcsr_task.attribute1;

		  IF (p_parent_task_id is not null) THEN
			DUMP_MSG(3, 'LOAD_TASKS', ' |parent_task_number:' || p_parent_task_number);
			lr_tasks_in_rec.pm_parent_task_reference := p_parent_task_number;
		  END IF;

		  pt_tasks_in(pt_tasks_in.count+1) := lr_tasks_in_rec;

		  LOAD_TASKS(lcsr_task.task_id, lcsr_task.task_number
					 , p_project_in, pt_tasks_in,p_template_id,p_proj_org_id);

		END LOOP;
		
		IF pt_tasks_in.count = 0 THEN
			DUMP_MSG(1, 'LOAD_TASKS', 'Template does not contain any tasks.');      
		 
			g_msg_data := 'Template does not contain any tasks. '||
						   'parent_task_number:' || p_parent_task_number;            
			g_status_code :=  'E'; 
			
		End IF;
		
		DUMP_MSG(3, 'LOAD_TASKS', '-');

	  END LOAD_TASKS;

	  PROCEDURE CREATE_PROJECT(
		p_status               OUT NOCOPY VARCHAR2
		,p_project_out         OUT NOCOPY pa_project_pub.project_out_rec_type
		,p_project_in          IN XX_PA_EJM_PROJ_INT_REC    -- Added PR000370
		,p_project_data        IN XX_PA_EJM_PROJ_INT_TBL    -- Added PR000370
		,p_template_id         IN NUMBER                    -- Added PR000370
		,p_proj_org_id         IN NUMBER                    -- Added PR000370
		 ) AS
		-- parameter init
		
		PROCESS_ERROR            EXCEPTION;                 -- Added PR000370
		LOAD_KEYM_ERROR          EXCEPTION;                 -- Added PR000370
		LOAD_TASK_ERROR          EXCEPTION;                 -- Added PR000370
		
		ln_msg_count             NUMBER;
		lc_msg_data              VARCHAR2(8000);
		lc_return_status         VARCHAR2(1);
		lc_workflow_started      VARCHAR2(1);

		lr_project_in            pa_project_pub.project_in_rec_type;
		lt_key_members           pa_project_pub.project_role_tbl_type;
		lt_class_categories      pa_project_pub.class_category_tbl_type;
		lt_tasks_in              pa_project_pub.task_in_tbl_type;
		lr_tasks_out_rec         pa_project_pub.task_out_rec_type;
		lt_tasks_out             pa_project_pub.task_out_tbl_type;

		lc_str_data              VARCHAR2(2000);
		ln_msg_index_out         NUMBER;
		lc_concat_msg_out        VARCHAR2(10000);
		-- Start Adding for R12 Retrofit Upgrade by Veronica on 3rd July 2013
		l_customers_in_tbl       pa_project_pub.customer_tbl_type;   
		l_org_roles              pa_project_pub.project_role_tbl_type ;  
		l_structure_in           pa_project_pub.structure_in_rec_type ;
		l_ext_attr_tbl_in        pa_project_pub.pa_ext_attr_table_type  ;
		l_deliverables_in        pa_project_pub.deliverable_in_tbl_type ;
		l_deliverable_actions_in pa_project_pub.action_in_tbl_type;
		-- End Adding for R12 Retrofit Upgrade by Veronica on 3rd July 2013

	  BEGIN
		DUMP_MSG(3, 'CREATE_PROJECT', '+');
		p_status := 'E';

		IF p_project_in.template IS NULL THEN
			DUMP_MSG(1, 'CREATE_PROJECT', 'template_id IS NULL (' || p_project_in.template || ')');
			g_msg_data := 'template_id IS NULL ' || p_project_in.template;            
			RAISE PROCESS_ERROR;
			
		END IF;


		IF p_project_in.projorg IS NULL THEN    
			DUMP_MSG(1, 'CREATE_PROJECT', 'projorgid IS NULL (' || p_project_in.projorg || ')');
			g_msg_data := 'projorgid IS NULL ' || p_project_in.projorg;            
			RAISE PROCESS_ERROR; 
		 
		END IF;

		lr_project_in.completion_date              := p_project_in.completiondate;
		lr_project_in.long_name                    := p_project_in.projlongname;
		lr_project_in.project_name                 := p_project_in.projname;
		lr_project_in.carrying_out_organization_id := p_proj_org_id;          -- Added PR000370;
		lr_project_in.pm_project_reference         := p_project_in.panex;
		lr_project_in.start_date                   := p_project_in.startDate;
		lr_project_in.created_from_project_id      := p_template_id ;         -- Added PR000370
		lr_project_in.pa_project_number            := p_project_in.panex;
		lr_project_in.description                  := p_project_in.projdesc;
		lr_project_in.country_code                 := ltrim(rtrim(p_project_in.countryid));
		lr_project_in.project_status_code          := 'UNAPPROVED';

		gc_debug_text :='Calling LOAD_KEYM';    
		LOAD_KEYM (p_project_in ,p_project_data, lt_key_members);
		
		IF  g_status_code = 'E'  THEN    
			RAISE LOAD_KEYM_ERROR;
			
		END IF;    

		gc_debug_text :='Calling pa_project_pub.init_project';  
		pa_project_pub.init_project;
		
		gc_debug_text :='Calling LOAD_TASKS';     
		LOAD_TASKS(null, null, p_project_in, lt_tasks_in, p_template_id, p_proj_org_id);
		
		IF  g_status_code = 'E'  THEN    
			RAISE LOAD_TASK_ERROR;
			
		END IF;   
		
		gc_debug_text :='Calling pa_project_pub.create_project'; 
		
		pa_project_pub.create_project(
		  p_api_version_number  => g_api_version_number
		  ,p_commit             => 'F'
		  ,p_init_msg_list      => 'T'
		  ,p_msg_count          => ln_msg_count
		  ,p_msg_data           => lc_msg_data
		  ,p_return_status      => lc_return_status
		  ,p_workflow_started   => lc_workflow_started
		  ,p_pm_product_code    => g_pm_product_code
		  ,p_op_validate_flag   => 'Y'                                   -- Added for R12 Retrofit Upgrade by Veronica on 3rd July 2013
		  ,p_project_in         => lr_project_in
		  ,p_project_out        => p_project_out
		  ,p_customers_in       => l_customers_in_tbl
		  ,p_key_members        => lt_key_members
		  ,p_class_categories   => lt_class_categories -- TODO:Comment out
		  ,p_tasks_in           => lt_tasks_in
		  ,p_tasks_out          => lt_tasks_out
		  ,p_org_roles          =>l_org_roles                            -- Start Adding for R12 Retrofit Upgrade by Veronica on 3rd July 2013
		  ,p_structure_in       =>l_structure_in
		  ,p_ext_attr_tbl_in    =>l_ext_attr_tbl_in
		  ,p_deliverables_in    =>l_deliverables_in
		  ,p_deliverable_actions_in    =>l_deliverable_actions_in);      -- End Adding for R12 Retrofit Upgrade by Veronica on 3rd July 2013
		  
		DUMP_MSGDATA(
		  p_procedure_name => 'pa_project_pub.create_project'
		  ,p_return_status => lc_return_status
		  ,p_msg_count     => ln_msg_count
		  ,p_msg_data      => lc_msg_data
		  ,x_msg_data_out  => lc_concat_msg_out);

		p_status := lc_return_status;
		
		IF lc_return_status != 'S' THEN
			  RAISE PROCESS_ERROR; 
		  
		END IF;

	  EXCEPTION 
		WHEN PROCESS_ERROR  THEN
				  g_status_code :=  'E';
				  g_email_status_code :=  'E'; 
				  g_msg_data := lc_concat_msg_out;
				  g_email_message :=  g_email_message ||'<tr><td>'||'Error creating PANEX number '||
									   p_project_in.panex||'-'||lc_concat_msg_out||'</td></tr>';  
		 
		 WHEN LOAD_KEYM_ERROR  THEN
				  g_status_code :=  'E';
				  g_email_status_code :=  'E'; 
				  g_email_message :=  g_email_message ||'<tr><td>'||'Error Load Key Member for PANEX number '||
									  p_project_in.panex||' '||g_msg_data||': '||substr(sqlerrm,1,400)||'</td></tr>';  
									  
		 WHEN LOAD_TASK_ERROR  THEN
				  g_status_code :=  'E';
				  g_email_status_code :=  'E'; 
				  g_email_message :=  g_email_message ||'<tr><td>'||'Error Load Task for PANEX number '||
									  p_project_in.panex|| ': '||g_msg_data||'</td></tr>';
					   
		
	  END CREATE_PROJECT;

	  PROCEDURE ASSIGN_ASSETS(
		p_project_in           IN XX_PA_EJM_PROJ_INT_REC       --- Added PR000370
		,p_project_id          IN  NUMBER
		,p_template_id         IN NUMBER
	  ) AS
		-- parameter init
		ln_msg_count             NUMBER;
		lc_msg_data              VARCHAR2(8000);
		lc_return_status         VARCHAR2(1);

		ln_task_id          NUMBER;
		ln_project_asset_id NUMBER;
		lc_concat_msg_out         VARCHAR2(10000);

		CURSOR mcsr_asset_assignments(p_template_id NUMBER,      --p_project_template Added PR000370
									  p_project_new NUMBER) IS
		  SELECT NVL(N.project_asset_id, A.project_asset_id) project_asset_id, A.task_id, T.task_number,
				 A.attribute_category,
				 A.attribute1, A.attribute2, A.attribute3, A.attribute4, A.attribute5,
				 A.attribute6, A.attribute7, A.attribute8, A.attribute9, A.attribute10,
				 A.attribute11, A.attribute12, A.attribute13, A.attribute14, A.attribute15
			FROM pa_project_asset_assignments A
				 LEFT JOIN pa_project_assets_all O
					  ON O.project_id = A.project_id
						 AND O.project_asset_id = A.project_asset_id
				 LEFT JOIN pa_tasks T
					  ON T.project_id = A.project_id
						 AND T.task_id = A.task_id
				 LEFT JOIN pa_project_assets_all N
					  ON N.project_id = p_project_new
						 AND N.asset_name = O.asset_name
			WHERE A.project_id = p_template_id;


	  BEGIN

		FOR lcsr_aa IN mcsr_asset_assignments(p_template_id, p_project_id)
		LOOP
		  PA_PROJECT_ASSETS_PUB.add_asset_assignment(
			p_api_version_number      => g_api_version_number
			,p_commit                 => 'F'
			,p_init_msg_list          => 'T'
			,p_msg_count              => ln_msg_count
			,p_msg_data               => lc_msg_data
			,p_return_status          => lc_return_status
			,p_pm_product_code        => g_pm_product_code
			,p_pa_project_id          => p_project_id
			,p_pm_task_reference      => lcsr_aa.task_number
			,p_pa_project_asset_id    => lcsr_aa.project_asset_id
			,p_attribute_category     => lcsr_aa.attribute_category
			,p_attribute1             => lcsr_aa.attribute1
			,p_attribute2             => lcsr_aa.attribute2
			,p_attribute3             => lcsr_aa.attribute3
			,p_attribute4             => lcsr_aa.attribute4
			,p_attribute5             => lcsr_aa.attribute5
			,p_attribute6             => lcsr_aa.attribute6
			,p_attribute7             => lcsr_aa.attribute7
			,p_attribute8             => lcsr_aa.attribute8
			,p_attribute9             => lcsr_aa.attribute9
			,p_attribute10            => lcsr_aa.attribute10
			,p_attribute11            => lcsr_aa.attribute11
			,p_attribute12            => lcsr_aa.attribute12
			,p_attribute13            => lcsr_aa.attribute13
			,p_attribute14            => lcsr_aa.attribute14
			,p_attribute15            => lcsr_aa.attribute15
			,p_pa_task_id_out         => ln_task_id
			,p_pa_project_asset_id_out => ln_project_asset_id
		  );
		  DUMP_MSG(3, 'ASSIGN_ASSETS', 'p_pa_task_id_out(' || ln_task_id
					  || ') p_pa_project_asset_id_out(' || ln_project_asset_id || ')');
		  -- Return Status
		  DUMP_MSGDATA(
			p_procedure_name => 'PA_PROJECT_ASSETS_PUB.add_asset_assignment'
			,p_return_status => lc_return_status
			,p_msg_count     => ln_msg_count
			,p_msg_data      => lc_msg_data
			,x_msg_data_out  => lc_concat_msg_out);
			
		  IF lc_return_status != 'S' THEN     
			 g_msg_data :=  'PA_PROJECT_ASSETS_PUB.add_asset_assignment failed: '||  lc_msg_data;         
			 g_status_code := 'E';         
			 g_email_status_code :=  'E'; 
			 g_email_message :=  g_email_message ||'<tr><td>'||'PA_PROJECT_ASSETS_PUB.add_asset_assignment failed: '
												 || lc_concat_msg_out||'</td></tr>';           
			 

		  END IF;
		END LOOP;
	  END ASSIGN_ASSETS;


	  PROCEDURE CREATE_BUDGET(
		p_status               OUT NOCOPY VARCHAR2
		,p_project_id          IN  NUMBER
		,p_project_in          IN XX_PA_EJM_PROJ_INT_REC                            -- Added PR000370
	  ) AS
		-- parameter init
		PROCESS_ERROR1           EXCEPTION;
		ln_msg_count             NUMBER;
		lc_msg_data              VARCHAR2(8000);
		lc_return_status         VARCHAR2(1);

		lt_budget_lines_in           pa_budget_pub.budget_line_in_tbl_type;
		lr_budget_lines_in_rec       pa_budget_pub.budget_line_in_rec_type;
		lt_budget_lines_out          pa_budget_pub.budget_line_out_tbl_type;
		lc_workflow_started      VARCHAR2(1);

		lc_str_data              VARCHAR2(2000);
		ln_msg_index_out         NUMBER;
		lc_concat_msg_out         VARCHAR2(10000);
		

		-- top tasks for a given project
		CURSOR lcsr_tasks(p_project_id PA_TASKS.project_id%type) IS
		SELECT task_id, task_number, start_date, completion_date, meaning
		  FROM PA_TASKS T
			   JOIN FND_LOOKUP_VALUES_VL M
					ON M.lookup_code = T.task_number
					   AND M.lookup_type = 'PA_TASK_NUMBER'
					   AND M.enabled_flag = 'Y'
		 WHERE T.project_id = p_project_id
		 ORDER BY M.meaning;

	  BEGIN
		DUMP_MSG(3, 'CREATE_BUDGET', '+');
		FOR lcsr_task IN lcsr_tasks(p_project_id)
		LOOP
		  lr_budget_lines_in_rec.pa_task_id := lcsr_task.task_id;
		  lr_budget_lines_in_rec.quantity := 1;
		  IF lcsr_task.meaning = 1 THEN
			lr_budget_lines_in_rec.raw_cost := p_project_in.expense;
		  ELSE
			lr_budget_lines_in_rec.raw_cost := p_project_in.capital;
		  END IF;

		  lt_budget_lines_in(lcsr_task.meaning) := lr_budget_lines_in_rec;
		END LOOP;

		--Initialize Budget API
		PA_BUDGET_PUB.init_budget;
		-- Call Budget API
		PA_BUDGET_PUB.create_draft_budget(
		  p_api_version_number      => g_api_version_number
		  ,p_commit                 => 'F'
		  ,p_init_msg_list          => 'T'
		  ,p_msg_count              => ln_msg_count
		  ,p_msg_data               => lc_msg_data
		  ,p_return_status          => lc_return_status
		  ,p_pm_product_code        => g_pm_product_code
		  ,p_pa_project_id          => p_project_id
		  ,p_budget_type_code       => g_budget_type
		  ,p_budget_version_name    => g_budget_version_name
		  ,p_description            => g_budget_version_name
		  ,p_entry_method_code      => g_budget_entry_mth_code
		  ,p_budget_lines_in        => lt_budget_lines_in
		  ,p_budget_lines_out       => lt_budget_lines_out );
		-- Return Status
		DUMP_MSGDATA(
		  p_procedure_name => 'PA_BUDGET_PUB.CREATE_DRAFT_BUDGET'
		  ,p_return_status => lc_return_status
		  ,p_msg_count     => ln_msg_count
		  ,p_msg_data      => lc_msg_data     
		  ,x_msg_data_out  => lc_concat_msg_out);
		  
		  
		  
		IF lc_return_status != 'S' THEN
		  g_msg_data := 'PA_BUDGET_PUB.create_draft_budget failed.'||   lc_concat_msg_out; 
		  g_email_status_code :=  'E'; 
		  g_email_message :=  g_email_message ||'<tr><td>'||'PA_BUDGET_PUB.create_draft_budget failed.'
												   ||   lc_concat_msg_out||'</td></tr>';      
												   
													 
												   
		  RAISE  PROCESS_ERROR1;

		  
		END IF;

		PA_BUDGET_PUB.baseline_budget(
		  p_api_version_number    => g_api_version_number
		  ,p_commit               => 'F'
		  ,p_init_msg_list        => 'T'
		  ,p_msg_count            => ln_msg_count
		  ,p_msg_data             => lc_msg_data
		  ,p_return_status        => lc_return_status
		  ,p_workflow_started     => lc_workflow_started
		  ,p_pm_product_code      => g_pm_product_code
		  ,p_pa_project_id        => p_project_id
		  ,p_budget_type_code     => g_budget_type
		  ,p_mark_as_original     => g_budget_type);
		  
		-- Return Status
		DUMP_MSGDATA(
		  p_procedure_name => 'PA_BUDGET_PUB.BASELINE_BUDGET'
		  ,p_return_status => lc_return_status
		  ,p_msg_count     => ln_msg_count
		  ,p_msg_data      => lc_msg_data
		  ,x_msg_data_out  => lc_concat_msg_out);

		--Clear Budget variable
		PA_BUDGET_PUB.CLEAR_BUDGET;
		
		IF lc_return_status != 'S' THEN
		  g_msg_data := 'PA_BUDGET_PUB.baseline_budget  failed.'||   substr(lc_concat_msg_out,7000);    
		  g_email_status_code :=  'E'; 
		  g_email_message :=  g_email_message ||'<tr><td>'||'PA_BUDGET_PUB.baseline_budget  failed.'
								 ||   substr(lc_concat_msg_out,999)||'</td></tr>'; 
								 
							 
		  RAISE PROCESS_ERROR1; 
		  
		END IF;

		DUMP_MSG(3, 'CREATE_BUDGET', '-');
		
	  EXCEPTION 
		  WHEN PROCESS_ERROR1 THEN
					g_status_code := 'E';  
					
	  END CREATE_BUDGET;


	  PROCEDURE SERVICE_EJM_QUEUE(
		 p_proj_rec                IN  XX_PA_EJM_PROJ_INT_TBL                       -- Added PR000370
	  --  ,p_pm_product_code         IN  FND_LOOKUP_VALUES_VL.lookup_code%TYPE      -- Removed per defect 19010  
	 --   ,p_budget_type             IN  PA_BUDGET_TYPES.budget_type_code%TYPE      -- Removed per defect 19010   
	  --  ,p_budget_entry_mth_code   IN  PA_BUDGET_ENTRY_METHODS.budget_entry_method_code%TYPE -- Removed per defect 19010  
	  --  ,p_resource_list_id        IN  PA_RESOURCE_LISTS.resource_list_id%TYPE    -- Removed per defect 19010      
	  --  ,p_email_addr              IN  VARCHAR2                                   -- Removed per defect 19010 
		,p_debug_flag              IN  VARCHAR2                                     -- Added PR000370
		,x_email_status            OUT VARCHAR2                                     -- Added PR000370
		,x_email_message           OUT VARCHAR2                                     -- Added PR000370
		,x_proj_out_tbl            OUT nocopy XX_PA_EJM_PROJ_OUT_TBL                -- Added PR000370
	  ) AS

		PRE_PROCESS_ERROR         EXCEPTION; 
		-- parameter init
		ln_msg_count              NUMBER;
		lc_msg_data               VARCHAR2(2000);
		lc_return_status          VARCHAR2(1);
		lr_project_out            pa_project_pub.project_out_rec_type;

		ln_request_id             NUMBER := FND_GLOBAL.conc_request_id;
		ln_proj_count             NUMBER := 0; -- # of projects processed
		ln_pa_project_id          NUMBER;
		x_user_id                 NUMBER;                                           -- Added PR000370 
		ln_application_id         NUMBER;
		ln_responsibility_id      NUMBER;
		ln_org_id                 NUMBER;
		ln_projorgid              NUMBER;  
		ln_templateid             NUMBER;
		lc_display_panex          VARCHAR2(50);
		lc_open_file              VARCHAR2(1);
		ln_proj_err_count         NUMBER;
		lc_timestamp              VARCHAR2(25);
		lc_concat_msg_out         VARCHAR2(10000);
		ln_temp_proj_id           NUMBER;
		lc_database_name          VARCHAR2(10);
		lc_database_name_dis      VARCHAR2(20);
	  BEGIN
		  g_pm_product_code        := NULL;                                         -- added NULLS defaults per defect 19010 
		  g_budget_type            := NULL;                 
		  g_budget_entry_mth_code  := NULL;
		  g_resource_list_id       := NULL;
		  g_budget_version_name    := NULL;      
		  g_status_code            := NULL;
		  g_email_status_code      := NULL;
		  g_email_message          := NULL; 
	  
	  
		  x_proj_out_tbl := XX_PA_EJM_PROJ_OUT_TBL();                                -- Added PR000370 
		  
		  gc_debug_text  := '  Getting Database Name from V$DAtabase ';             -- added Database values per defect 19010 
		  
		  BEGIN      
			  SELECT NAME
			   INTO lc_database_name
			   FROM v$database
			   WHERE NAME <> 'GSIPRDGB';
			   
			   lc_database_name_dis := '('||lc_database_name||')';
			   
			   
		  EXCEPTION
			 WHEN NO_DATA_FOUND THEN 
				 lc_database_name := ' ';   
			 WHEN OTHERS THEN
				 lc_database_name := ' ';
		  END;   

		  gc_debug_text  := '  Getting SVC_ESP_FIN user ID ';                        -- Added PR000370 
		  
		  SELECT user_id
			INTO x_user_id
			FROM FND_USER
		   WHERE user_name = 'SVC_ESP_FIN' ;
	 
		-- Variable to only open debug file once     
		lc_open_file := 'Y';
		ln_proj_err_count := 0;
		g_email_status_code := 'S';

		FOR i in p_proj_rec.first .. p_proj_rec.last LOOP  

			g_msg_data       := NULL;
			lc_display_panex := p_proj_rec(i).PANEX;
			g_status_code := 'S';  
			
			gc_debug_text  := ' Selecting Application Details ';        
			---------------------------------------------------------   
			--Select organization and template details Added PR000370 
			----------------------------------------------------------
			BEGIN 
					SELECT T.project_id templateid, 
						   O.organization_id projorgid, 
						   OU.organization_id org_id,
						   R.application_id,
						   R.responsibility_id
					  INTO
						   ln_templateid,  
						   ln_projorgid,               
						   ln_org_id,              
						   ln_application_id,
						   ln_responsibility_id               
					  FROM PA_PROJECTS_ALL T
					  LEFT JOIN hr_all_organization_units O
							ON O.name = p_proj_rec(i).PROJORG                                    
					  LEFT JOIN xx_fin_translatevalues V
							ON V.source_value1 =  'US'                                          
					  JOIN xx_fin_translatedefinition D
							ON D.translate_id = V.translate_id
							   AND D.translation_name = 'OD_COUNTRY_DEFAULTS'
					  JOIN hr_operating_units OU
							ON OU.name = V.target_value2
					 JOIN fnd_lookup_values_vl L
							ON L.lookup_code = OU.name
							   AND L.lookup_type = 'PA_RESPONSBILITY_ID'
							   AND (L.end_date_active >= sysdate or L.end_date_active IS NULL)
							   AND L.enabled_flag = 'Y'
					   LEFT JOIN FND_RESPONSIBILITY_TL R
							ON R.responsibility_name = L.meaning     
				  WHERE
					   T.segment1 = p_proj_rec(i).TEMPLATE                                       
				   AND template_flag = 'Y';       
			
				   gc_debug_text  := ' Calling FND_GLOBAL.APPS_INITIALIZE ';    
				   FND_GLOBAL.APPS_INITIALIZE(x_user_id, ln_responsibility_id, ln_application_id);
				   commit;  
			
			EXCEPTION                                                               -- added exception per defect 19010 
				WHEN OTHERS THEN 
				
					  RAISE PRE_PROCESS_ERROR; 
			END;
			
			
			gc_debug_text  := ' Selecting Translation Values '; 
			---------------------------------------------------------
			-- SELECT TRANSLATION VALUES
			---------------------------------------------------------
			BEGIN
				  SELECT b.target_value1, 
						 b.target_value2,
						 b.target_value3,
						 b.target_value4,
						 b.target_value5 ,               
						 TO_NUMBER(b.target_value8,'9.9'),
						 b.target_value9 
					INTO
						g_pm_product_code,       
						g_budget_type,           
						g_budget_entry_mth_code, 
						g_resource_list_id, 
						g_budget_version_name,
						g_api_version_number,
						g_debug_flag
					FROM    XX_FIN_TRANSLATEDEFINITION a,
						 XX_FIN_TRANSLATEVALUES b
				   WHERE a.Translation_name = 'OD_PA_CREAT_PRJ_INTERFACE'
					 AND a.translate_id = b.translate_id
					 AND b.source_value1 = 'EJM';        
			EXCEPTION                                                               -- added exception per defect 19010 
				WHEN OTHERS THEN 
				
					  RAISE PRE_PROCESS_ERROR; 
			END;   

		   ----------------------------------------------
		   -- Initialize debug file if flag is set to 'Y'
		   ----------------------------------------------
		   IF g_debug_flag = 'Y' THEN
				IF lc_open_file = 'Y' THEN
			   
				  SELECT to_char(sysdate,'YYDDMMHH24MISS')
					INTO lc_timestamp
					FROM dual;
			   
				  gc_debug_text  := 'UTL_FILE.FOPEN'||'EJM_log.txt';           
				  g_FileHandle := UTL_FILE.FOPEN('XXFIN_OUTBOUND','EJM_log_'||lc_timestamp||'.txt','w');  
				  lc_open_file := 'N';   
				  
				END IF;
				
			END IF;      


		BEGIN

		ms_dump_msgdata := '';

		DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '           PL/SQL Package: ' || 'XX_PA_CREATE_PKG');
		DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '         g_pm_product_code:' || g_pm_product_code);
		DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '             g_budget_type:' || g_budget_type);
		DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '   g_budget_entry_mth_code:' || g_budget_entry_mth_code);
		DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '        g_resource_list_id:' || g_resource_list_id);
		DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '              g_debug_flag:' || g_debug_flag);
		DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '                   user id:' || x_user_id);
		DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '                   resp id:' || ln_responsibility_id);
		DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '                    app id:' || ln_application_id);
		DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '       p_proj_rec(i).PANEX:' || p_proj_rec(i).PANEX ||', i='||i);

	 
		gc_debug_text  := ' Calling set_global_info '; 
		
		pa_interface_utils_pub.set_global_info(
			p_api_version_number  => g_api_version_number
			,p_responsibility_id  => ln_responsibility_id                           
			,p_user_id            => x_user_id
			,p_operating_unit_id  => ln_org_id		       -- Added for R12 Retrofit Upgrade by Veronica on 3rd July 2013
			,p_msg_count          => ln_msg_count
			,p_msg_data           => lc_msg_data
			,p_return_status      => lc_return_status);

		  gc_debug_text  := ' Calling DUMP_MSGDATA ';    
		  
		  DUMP_MSGDATA(
			p_procedure_name => 'pa_interface_utils_pub.set_global_info'
			,p_return_status => lc_return_status
			,p_msg_count     => ln_msg_count
			,p_msg_data      => lc_msg_data     
			,x_msg_data_out  => lc_concat_msg_out);
			
		  IF  ln_msg_count != 0  THEN
				g_msg_data    :=  'pa_interface_utils_pub.set_global_info ERROR'||substr(lc_concat_msg_out,1,10000);
				g_status_code :=  'E';
				g_email_status_code :=  'E'; 
				g_email_message :=  g_email_message ||'<tr><td>'||'pa_interface_utils_pub.set_global_info ERROR'
											 ||substr(lc_concat_msg_out,1,999)||'</td></tr>';              
	 
				  
		  END IF;
		  
		  IF g_status_code =  'S' THEN       
			  gc_debug_text  := ' Calling CREATE_PROJECT ';         
			  CREATE_PROJECT(
				p_status      => lc_return_status,
				p_project_out => lr_project_out,
				p_project_in  => p_proj_rec(i),
				p_project_data => p_proj_rec,
				p_template_id  => ln_templateid,
				p_proj_org_id  => ln_projorgid);
		  
		  END IF;

		  IF g_status_code =  'S' THEN  
		  
			  gc_debug_text  := ' Calling ASSIGN_ASSETS ';                 
			  ASSIGN_ASSETS(
				p_project_in  => p_proj_rec(i),   --lt_project_in,
				p_project_id  => lr_project_out.pa_project_id,
				p_template_id => ln_templateid);
				
		  END IF;  

		  IF g_status_code =  'S' THEN 
			  gc_debug_text  := ' Calling CREATE_BUDGET ';         
			  CREATE_BUDGET(
				p_status      => lc_return_status,
				p_project_id  => lr_project_out.pa_project_id,
				p_project_in  => p_proj_rec(i));    -- lt_project_in);
		
			   COMMIT;
		   END IF;
		   
		  IF g_status_code =  'S' THEN  
		  
			   DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '       p_proj_rec(i).PANEX:' || p_proj_rec(i).PANEX ||', i='||i);
			   DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '       p_proj_rec(i).projectid:' || p_proj_rec(i).projectid ||', i='||i);
			   
			   x_proj_out_tbl.extend;
			   x_proj_out_tbl(i) := XX_PA_EJM_PROJ_OUT_REC(lr_project_out.pa_project_id,
								   lr_project_out.pa_project_number,
								   'S',
								   NULL);

			   ln_proj_count := ln_proj_count + 1;
		  ELSE
			   DUMP_MSG(3, 'SERVICE_EJM_QUEUE', ' Error: p_proj_rec(i).PANEX:' || p_proj_rec(i).PANEX ||', i='||i);
			   DUMP_MSG(3, 'SERVICE_EJM_QUEUE', ' Error: p_proj_rec(i).projectid:' || p_proj_rec(i).projectid ||', i='||i);
			   
			   ---------------------------------------------------------------------------
				-- Added per defect 19010 Fix INT size limitation in EJM SQL SERVER. Oracle 
				-- API will sometime return 170000000000000000000 for project ID. Project ID 
				-- will be defaulted to 0 if number is to larger then 2147483646 .
			   -----------------------------------------------------------------------------
			   ln_temp_proj_id  :=   p_proj_rec(i).projectid;
			  
			   IF   ln_temp_proj_id  > 2147483646 AND g_pm_product_code = 'EJM' THEN
			   
					 g_msg_data := 'Project ID: '||ln_temp_proj_id ||' supplied is to large the max (INT) value for '
								   || 'SQL SERVER can handle is 2147483646 '; 
								   
					 ln_temp_proj_id  := 0;
								   
			   END IF;

			   x_proj_out_tbl.extend;     
		  --   x_proj_out_tbl(i) := XX_PA_EJM_PROJ_OUT_REC(p_proj_rec(i).projectid,   -- removed per defect 19010
			   x_proj_out_tbl(i) := XX_PA_EJM_PROJ_OUT_REC( ln_temp_proj_id,
									  p_proj_rec(i).PANEX,
								   'E',
								   'Project Error: '||substr(g_msg_data,1,999));           
	  
			   ln_proj_err_count := ln_proj_err_count + 1;
			   
			   DUMP_MSG(3, 'SERVICE_EJM_QUEUE', 'Return project id ' || x_proj_out_tbl(i).pa_project_id);
			   DUMP_MSG(3, 'SERVICE_EJM_QUEUE', 'Return project number ' || x_proj_out_tbl(i).pa_project_number);
			   DUMP_MSG(3, 'SERVICE_EJM_QUEUE', 'Return Status ' || x_proj_out_tbl(i).return_status);
			   
		  END IF;

		  EXCEPTION
		  WHEN OTHERS THEN
			ROLLBACK;
			   x_proj_out_tbl.extend;   
			   x_proj_out_tbl(i) := XX_PA_EJM_PROJ_OUT_REC(lr_project_out.pa_project_id,
								   lr_project_out.pa_project_number,
								   'E',
								   'OTHERS EXCEPTION: '||substr(g_msg_data,1,999));            
	 
			ln_proj_err_count := ln_proj_err_count + 1;
			
			DUMP_MSG(1, 'SERVICE_EJM_QUEUE(loop)', 'When Others Exception');
			DUMP_MSG(1, 'SERVICE_EJM_QUEUE(loop)', CHR(13) || DBMS_UTILITY.FORMAT_ERROR_STACK);
			DUMP_MSG(1, 'SERVICE_EJM_QUEUE(loop)', CHR(13) || DBMS_UTILITY.FORMAT_CALL_STACK);
			DUMP_MSG(1, 'SERVICE_EJM_QUEUE(loop)', '   An error occured, sqlcode: ' || sqlerrm);
			DUMP_MSG(1, 'SERVICE_EJM_QUEUE(loop)', '         p_proj_rec(i).PANEX: ' || lc_display_panex);
			DUMP_MSG(1, 'SERVICE_EJM_QUEUE(loop)', '            lc_return_status: ' || lc_return_status);
			DUMP_MSG(1, 'SERVICE_EJM_QUEUE(loop)', 'lr_project_out.pa_project_id: ' || lr_project_out.pa_project_id);
			DUMP_MSG(1, 'SERVICE_EJM_QUEUE(loop)', '.');
			
		  END;
	   
		  END LOOP;               
		  
		IF ln_proj_count = 0 THEN
		  DUMP_MSG(1, 'SERVICE_EJM_QUEUE', '** NO projects processed **');
		ELSE
		  DUMP_MSG(1, 'SERVICE_EJM_QUEUE', '# of projects processed:' || ln_proj_count);
		END IF;
	  
		IF ln_proj_err_count != 0 THEN
		  DUMP_MSG(1, 'SERVICE_EJM_QUEUE', '# of projects with errors:' || ln_proj_err_count);
		  x_email_status   :=  g_email_status_code;
		  x_email_message  :=  '<table border="1">' 
							   ||'<tr> <th>The following errors have occured when importing '||
							   g_pm_product_code ||' records to Oracle Projects '|| lc_database_name_dis|| '</th> </tr>'
							   ||g_email_message 
							   ||'</table>';
		END  IF;

	 
		IF g_debug_flag = 'Y' THEN      

			UTL_FILE.FFLUSH(g_FileHandle); 
			UTL_FILE.FCLOSE(g_FileHandle); 
	 
		END IF;
			
	  EXCEPTION
		WHEN  PRE_PROCESS_ERROR  THEN                                             -- Added Pre_Process_Error per defect 19010
		
		   IF g_debug_flag = 'Y' THEN
		  
			   SELECT to_char(sysdate,'YYDDMMHH24MISS')
				 INTO lc_timestamp
				 FROM dual;
			   
				gc_debug_text  := 'UTL_FILE.FOPEN'||'EJM_log.txt';           
				g_FileHandle := UTL_FILE.FOPEN('XXFIN_OUTBOUND','EJM_log_'||lc_timestamp||'.txt','w');  
				  
					DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '           PL/SQL Package: ' || 'XX_PA_CREATE_PKG');
					DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '         g_pm_product_code:' || g_pm_product_code);
					DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '             g_budget_type:' || g_budget_type);
					DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '   g_budget_entry_mth_code:' || g_budget_entry_mth_code);
					DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '        g_resource_list_id:' || g_resource_list_id);
					DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '              g_debug_flag:' || g_debug_flag);
					DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '                   user id:' || x_user_id);
					DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '                   resp id:' || ln_responsibility_id);
					DUMP_MSG(3, 'SERVICE_EJM_QUEUE', '                    app id:' || ln_application_id);
					DUMP_MSG(1, 'SERVICE_EJM_QUEUE', 'An error occured, sqlcode = ' || sqlerrm
													||'Error Location: '||gc_debug_text); 
					 
				UTL_FILE.FFLUSH(g_FileHandle); 
				UTL_FILE.FCLOSE(g_FileHandle);

			END IF;      
		
			RAISE_APPLICATION_ERROR(-20001, ' PRE_PROCESS_ERROR error occurred: '|| gc_debug_text || sqlerrm , true);
	  
		WHEN OTHERS THEN
					 
			IF g_debug_flag = 'Y' THEN

			   DUMP_MSG(1, 'SERVICE_EJM_QUEUE', 'An error occured, sqlcode = ' || sqlerrm
					 ||'Error Location: '||gc_debug_text);    
				UTL_FILE.FFLUSH(g_FileHandle); 
				UTL_FILE.FCLOSE(g_FileHandle); 
			 
			END IF;
		
			RAISE_APPLICATION_ERROR(-20001, ' WHEN OTHERS error occurred: '|| gc_debug_text || sqlerrm , true);

	  END SERVICE_EJM_QUEUE;

	END XX_PA_CREATE_PKG; 

	/