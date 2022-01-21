CREATE OR REPLACE
PACKAGE BODY           XX_PA_CREATE_PRJ  IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        OD:Project Simpilfy                                 |
-- | Description : To get the Approved Projects detail from            |
-- |                legacy system(EJM) to Oracle Project Accounting.   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       06-MAR-2007  Raj Patel            Initial version        |
-- |                                                                   |
-- +===================================================================+
-- +===================================================================+
-- | Name : XX_PA_GEN_PROJECT_DATA                                     |
-- | Description : This Procedure will pull data from SQL Server       |
-- |               If project data pull out successfully then          |
-- |               update the flag with 'R' if not then 'E' .          |
-- |                                                                   |
-- |                                                                   |
-- | Parameters : x_error_code : Successfully = 0. if not then         |
-- |             SQLCODE or 1                                          |
-- |             x_error_buff : Error Message                          |
-- +===================================================================+
       PROCEDURE XX_PA_GEN_PROJECT_DATA (
        x_error_code OUT NOCOPY NUMBER
       ,x_error_buff OUT NOCOPY VARCHAR2 ) AS
       
        ln_panex                         xxfin.XX_PA_PROJ_DATA_STG.panex%TYPE;
        lc_error_loc                     VARCHAR2(2000);
        lc_error_debug                   VARCHAR2(2000);
        lc_proejct_in                    xxfin.XX_PA_PROJ_DATA_STG%ROWTYPE;
        lc_keymembers_in                 xxfin.XX_PA_KEYPROJ_MEM_STG%ROWTYPE;
        ln_counter                       NUMBER := 0;

        x_status                         VARCHAR2(100) := '0';
        ex_pull_data_error               EXCEPTION;
        ex_paex_not_found                EXCEPTION;
        
       CURSOR c_pa_proj_hdr_stg IS
       ( 
        SELECT * 
        FROM xxfin.xx_pa_proj_hdr_stg_SQL 
        WHERE EBSPA_SentFlag <> 'R' OR EBSPA_SentFlag IS NULL
        );
       CURSOR c_pa_proj_data_stg ( p_panex NUMBER ) IS
       ( 
        SELECT * 
        FROM xxfin.xx_pa_proj_data_stg_SQL 
        WHERE PANEx = p_panex
       );
      BEGIN
        fnd_file.put_line(fnd_file.log,'Start : XX_PA_GEN_PROJECT_DATA');
        
            FOR lcu_pa_proj_hdr_stg IN c_pa_proj_hdr_stg 
            LOOP
                ln_panex  := lcu_pa_proj_hdr_stg.PANEx; 
                --To Check if the PANEx is not NULL
                lc_error_loc := 'Check if the PANEx is not NULL';
                lc_error_debug := 'PANEx: '||lcu_pa_proj_hdr_stg.PANEx;
                IF lcu_pa_proj_hdr_stg.PANEx IS NOT NULL THEN
                    --Inserting into the Interface table mtl_system_items_interface
                    lc_error_loc   := 'During Inserting into the Staging table xxfin.xx_pa_proj_hdr_stg';
                    lc_error_debug := 'PANEx: '||lcu_pa_proj_hdr_stg.PANEx;
                    fnd_file.put_line(fnd_file.log,'Insert Record into xxfin.xx_pa_proj_hdr_stg' );
                    INSERT INTO  xxfin.xx_pa_proj_hdr_stg
                    (
                     PANEx
                    ,ProjectID
                    ,EBSPA_ProjectId
                    ,EBSPA_SentFlag
                    ,EBSPA_SentDate
                    ,EBSPA_AckdDate                    
                    )
                    VALUES
                    (
                     lcu_pa_proj_hdr_stg.PANEx
                    ,lcu_pa_proj_hdr_stg.ProjectID
                    ,NULL
                    ,lcu_pa_proj_hdr_stg.EBSPA_SentFlag
                    ,lcu_pa_proj_hdr_stg.EBSPA_SentDate
                    ,NULL
                    );
                    
                    lc_error_loc   := 'During Inserting into the Staging table xxfin.xx_pa_proj_data_stg';
                    lc_error_debug := 'PANEx: '||lcu_pa_proj_hdr_stg.PANEx;
                    fnd_file.put_line(fnd_file.log,'Insert Record into xxfin.xx_pa_proj_data_stg' );
                    FOR lcu_pa_proj_data_stg IN c_pa_proj_data_stg (lcu_pa_proj_hdr_stg.PANEx)
                    LOOP
                         
                         INSERT INTO xxfin.xx_pa_proj_data_stg
                          (
                           Capital
                          ,CompletionDate
                          ,CountryID
                          ,Expenses
                          ,PANEx
                          ,ProjDescr
                          ,ProjName
                          ,ProjOrgID
                          ,ProjectID
                          ,StartDate
                          ,TempletID
                          )
                          VALUES
                          (
                           lcu_pa_proj_data_stg.Capital
                          ,lcu_pa_proj_data_stg.CompletionDate
                          ,lcu_pa_proj_data_stg.CountryID
                          ,lcu_pa_proj_data_stg.Expenses
                          ,lcu_pa_proj_data_stg.PANEx
                          ,lcu_pa_proj_data_stg.ProjDescr
                          ,lcu_pa_proj_data_stg.ProjName
                          ,lcu_pa_proj_data_stg.ProjOrgID
                          ,lcu_pa_proj_data_stg.ProjectID
                          ,lcu_pa_proj_data_stg.StartDate
                          ,lcu_pa_proj_data_stg.TempletID
                          ); 
                        END LOOP;
                          fnd_file.put_line(fnd_file.log,'Check data inside xxfin.xx_pa_proj_data_stg' );
                          --
                          --Update flag with 'R' that Recrod read sucessfully
                          --
                          SELECT COUNT(*) INTO ln_counter
                          FROM xxfin.xx_pa_proj_data_stg
                          WHERE panex = lcu_pa_proj_hdr_stg.PANEx;
                          --
                          --
                          fnd_file.put_line(fnd_file.log,'Counter :'|| ln_counter );
                          lc_error_loc   := 'Counting PANEx into xxfin.xx_pa_proj_data_stg';
                          lc_error_debug := 'PANEx: '||ln_panex;
                          IF ln_counter = 1 THEN
                              --Update with 'R' Flag 
                              UPDATE xxfin.xx_pa_proj_hdr_stg_SQL
                              SET EBSPA_SentFlag = 'R'
                              WHERE PANEx = ln_panex ;
                              --
                              --
                             COMMIT;
                          ELSE
                             Rollback;
                             RAISE ex_paex_not_found;
                          END IF;

                ELSE
                  RAISE ex_pull_data_error;
                END IF;
                
            END LOOP;
            x_error_buff  := 0;
            x_error_buff  := NULL;
           fnd_file.put_line(fnd_file.log,'End : XX_PA_GEN_PROJECT_DATA');
           --
           --
           SELECT * INTO lc_proejct_in
           FROM xxfin.XX_PA_PROJ_DATA_STG
           WHERE PANEx = ln_panex ;
           --
           --
           /* SELECT * INTO lc_keymembers_in
           FROM xxfin.XX_PA_KEYPROJ_MEM_STG
           WHERE PANEx = ln_panex ;
           */
           --
           --
           XX_PA_CREATE_PRJ.XX_PA_CREATE_PROJECT( x_status,'MSPROJECT',lc_proejct_in,lc_keymembers_in);
           
       EXCEPTION  
            WHEN ex_paex_not_found  THEN
              fnd_file.put_line(fnd_file.log,'Error Location: '||lc_error_loc);
              fnd_file.put_line(fnd_file.log,'Error Debug: '   ||lc_error_debug);
              x_error_buff  := 1;
              x_error_buff  :=  'Child Tble xxfin.XX_PA_PROJ_DATA_STG_SQL Not found PANEx ';
              fnd_file.put_line(fnd_file.log,x_error_buff);
            WHEN ex_pull_data_error THEN
              fnd_file.put_line(fnd_file.log,'Error Location: '||lc_error_loc);
              fnd_file.put_line(fnd_file.log,'Error Debug: '   ||lc_error_debug);
              x_error_buff  := 1;
              x_error_buff  := 'PANEx is NULL';
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Error Location: '||lc_error_loc);
              fnd_file.put_line(fnd_file.log,'Error Debug: '   ||lc_error_debug);
              fnd_file.put_line(fnd_file.log,'Oracle Error: '  ||SQLERRM);
              ROLLBACK;
                  BEGIN
                    lc_error_loc   := 'Updateing into the Remore SQL table xxfin.xx_pa_proj_hdr_stg_SQL.EBSPA_SentFlag with E ';
                    lc_error_debug := 'PANEx ; '|| ln_panex;
                    --
                    --Update with 'E' Flag 
                    UPDATE xxfin.xx_pa_proj_hdr_stg_SQL
                    SET EBSPA_SentFlag = 'E'
                    WHERE PANEx = ln_panex ;
                    --
                    --
                    COMMIT;
                  EXCEPTION
                  WHEN OTHERS THEN    
                    fnd_file.put_line(fnd_file.log,'Error Location: '||lc_error_loc);
                    fnd_file.put_line(fnd_file.log,'Error Debug: '   ||lc_error_debug);
                    fnd_file.put_line(fnd_file.log,'Oracle Error: '  ||SQLERRM);
                  END;
                  x_error_buff  := SQLCODE;
                  x_error_buff  := SQLERRM;

       END XX_PA_GEN_PROJECT_DATA;
       --
       --End of Gen Project Data
       --
       PROCEDURE XX_PA_CREATE_PROJECT(
        x_status             OUT NOCOPY VARCHAR2
       ,p_pm_product_code    IN  VARCHAR2
       ,p_project_in         IN  xxfin.XX_PA_PROJ_DATA_STG%ROWTYPE
       ,p_key_memebers       IN  xxfin.XX_PA_KEYPROJ_MEM_STG%ROWTYPE       )       
       AS
       -- Variables needed to create task hierachy
       ln_level1                        NUMBER;
       ln_level2                        NUMBER;
       ln_level3                        NUMBER;
       ln_a                             NUMBER;
       ln_m                             NUMBER;
       l_parent_level1		  	VARCHAR2(30);
       l_parent_level2                  VARCHAR2(30);
       l_parent_level3                  VARCHAR2(30);

       -- Variables needed for API standard parameters
       ln_api_version_number            NUMBER := 1.0;
       l_commit                         VARCHAR2(1) := 'F';
       l_return_status                  VARCHAR2(1);
       l_init_msg_list                  VARCHAR2(1) := 'F';
       ln_msg_count                     NUMBER;
       ln_msg_index_out                 NUMBER;
       l_msg_data                       VARCHAR2(2000);
       l_data                           VARCHAR2(2000);
       l_workflow_started               VARCHAR2(1) := 'Y';
       l_pm_product_code                VARCHAR2(10);
       l_user_id                        pa_user_resp_v.user_id%TYPE;
       l_responsibility_id	        pa_user_resp_v.responsibility_id%TYPE;

       -- Predefined Composit data types
       l_project_in                     PA_PROJECT_PUB.PROJECT_IN_REC_TYPE;
       l_project_out                    PA_PROJECT_PUB.PROJECT_OUT_REC_TYPE;
       l_key_members                    PA_PROJECT_PUB.PROJECT_ROLE_TBL_TYPE;
       l_class_categories               PA_PROJECT_PUB.CLASS_CATEGORY_TBL_TYPE;
       l_tasks_in_rec		        PA_PROJECT_PUB.TASK_IN_REC_TYPE;
       l_tasks_in			PA_PROJECT_PUB.TASK_IN_TBL_TYPE;
       l_tasks_out_rec		        PA_PROJECT_PUB.TASK_OUT_REC_TYPE;
       l_tasks_out			PA_PROJECT_PUB.TASK_OUT_TBL_TYPE;


       ln_person_id                     NUMBER;
       l_project_role_type		VARCHAR2(20);
       API_ERROR			EXCEPTION;
       --
    BEGIN
             -- GET GLOBAL VALUES
	     SELECT user_id, responsibility_id
    			into l_user_id, l_responsibility_id
             FROM apps.pa_user_resp_v
             WHERE user_id = 1404 and  responsibility_id =  50302;		-- need to get from Apps
        
             --user_id = fnd_profile.value('USER_ID') and  responsibility_id = fnd_profile.value('RESP_ID'); --responsibility_id= 50302;		-- need to get from Apps
	     -- SET GLOBAL VALUES
             pa_interface_utils_pub.set_global_info(
	      p_api_version_number=> 1.0,
	      p_responsibility_id	=> l_responsibility_id,
	      p_user_id		        => l_user_id,
	      p_msg_count		=> ln_msg_count,
	      p_msg_data		=> l_msg_data,
	      p_return_status		=> l_return_status);
	      -- PRODUCT DATA
	      -- Start : PROJECT_IN_REC_TYPE
	      --
             fnd_file.put_line(fnd_file.log,' p_project_in.ProjectID > ' || p_project_in.ProjName);
             l_pm_product_code := 'MSPROJECT' ; 
             
             l_project_in.completion_date              := p_project_in.CompletionDate;
             l_project_in.long_name                    := p_project_in.ProjDescr;
             l_project_in.project_name                 := p_project_in.ProjName;
             l_project_in.carrying_out_organization_id := p_project_in.ProjOrgID;
             l_project_in.pm_project_reference         := p_project_in.ProjectID;
             l_project_in.start_date                   := p_project_in.StartDate;               -- can override default from template
             l_project_in.created_from_project_id      := p_project_in.TempletID;  -- Project id from template
             --
             --
             l_project_in.pa_project_number            := p_project_in.ProjName;
             l_project_in.description                  := p_project_in.ProjDescr;
             l_project_in.country_code                 := p_project_in.CountryID;
             -- l_project_in.project_relationship_code:= 'Raj7 Project Long Name';
            
       
             
             l_project_in.project_status_code := 'UNAPPROVED';
	      --
	      -- End  : PROJECT_IN_REC_TYPE
	      --

	      -- KEY MEMBERS DATA
	      -- Start : PROJECT_ROLE_TBL_TYPE
	      --
            /*  FOR i IN 1..ln_a
                  LOOP
                  l_key_members(1).person_id := 1327;
                  l_key_members(1).project_role_type := 'PROJECT MANAGER';
                  l_key_members(1).start_date := '01-Jan-2007';
                  l_key_members(1).end_date := null;
                  END LOOP;*/
                  
	      --
	      -- End : PROJECT_ROLE_TBL_TYPE
	      --

	      -- CLASS CATEGORIES DATA
	      -- Start:CLASS_CATEGORY_TBL_TYPE
	      --

	      	-- l_class_categories from p_class_categories

	      --
	      -- End : CLASS_CATEGORY_TBL_TYPE
	      --

	      --INIT_CREATE_PROJECT
        	pa_project_pub.init_project;
            
    
  		--CREATE_PROJECT
                fnd_file.put_line(fnd_file.log,'Start: pa_project_pub.create_project');
  		pa_project_pub.create_project(
                                  ln_api_version_number,
                                  p_commit                   => l_commit,
                                  p_init_msg_list            => l_init_msg_list,
                                  p_msg_count                => ln_msg_count,
                                  p_msg_data                 => l_msg_data,
                                  p_return_status            => l_return_status,
                                  p_workflow_started         => l_workflow_started,
                                  p_pm_product_code          => l_pm_product_code,
                                  p_project_in               => l_project_in,
                                  p_project_out              => l_project_out,
                                  p_key_members              => l_key_members,
                                  p_class_categories         => l_class_categories,
                                  p_tasks_in                 => l_tasks_in,
                                  p_tasks_out                => l_tasks_out);
		 -- Check for errors
  		 IF l_return_status != 'S'	THEN
  		    x_status	:=	'F'; -- Fail
                    RAISE API_ERROR;
                 ELSE
  		    x_status	:=	'S'; -- Success
  		 END IF;
  			--
                 fnd_file.put_line(fnd_file.log,'l_project_out.pa_project_id :' ||l_project_out.pa_project_id);
                 fnd_file.put_line(fnd_file.log,'l_project_out.pa_project_number:'||l_project_out.pa_project_number);
                        

        Commit;
        

  	-- HANDLE EXCEPTIONS
    -- Get the error message that were returned if it did not complete sucessfully
    EXCEPTION
          WHEN API_ERROR THEN
          		fnd_file.put_line(fnd_file.log,'An API_ERROR occurred' || ln_msg_count);
    					IF ln_msg_count >= 1 THEN
      						FOR i in 1..ln_msg_count
      						LOOP
                                                     pa_interface_utils_pub.get_messages(
                                                          p_msg_data=> l_msg_data,
                                                          p_encoded=> 'F',
                                                          p_data=>l_data,
                                                          p_msg_count=> ln_msg_count,
                                                          p_msg_index=>1,
                                                          p_msg_index_out => ln_msg_index_out);
                                                          fnd_file.put_line(fnd_file.log,'Error message: ' || l_data);
      						END LOOP;
      						ROLLBACK;
    					END IF;
  				WHEN OTHERS THEN
    					fnd_file.put_line(fnd_file.log,'An error occured, sqlcode = ' || sqlerrm);
    					IF ln_msg_count >= 1     then
      						FOR i IN 1..ln_msg_count
      							LOOP
                                                     pa_interface_utils_pub.get_messages(
                                                          p_msg_count=> ln_msg_count,
                                                          p_encoded=> 'F',
                                                          p_msg_data=> l_msg_data,
                                                          p_data => l_data,
                                                          p_msg_index=>1,
                                                          p_msg_index_out => ln_msg_index_out);
                                                          fnd_file.put_line(fnd_file.log,'Error message: ' || l_data);
      							END LOOP;
      						ROLLBACK;
    					END IF;
    END XX_PA_CREATE_PROJECT;
    --
    --End of Create Project Procedure
    --
-- +===================================================================+
-- | Name : XX_PA_CREATE_BUDGET                                             |
-- | Description : This Wrapper Procedure call API PA_BUDGET_PUB.       |
-- |               create_draft_budget                                  |
-- |                                                                   |
-- |                                                                   |
-- | Parameters : x_status											                       |
-- +===================================================================+
    PROCEDURE XX_PA_CREATE_BUDGET(
        x_status   OUT NOCOPY VARCHAR2
        ) AS
        
    BEGIN
        NULL;
    END XX_PA_CREATE_BUDGET;

END XX_PA_CREATE_PRJ;
/