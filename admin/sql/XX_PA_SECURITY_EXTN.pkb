CREATE OR REPLACE PACKAGE BODY APPS.pa_security_extn AS
/* $Header: PAPSECXB.pls 115.11 2003/05/07 11:33:04 rajkumar ship $ */

  PROCEDURE check_project_access ( X_project_id            IN NUMBER
                                 , X_person_id             IN NUMBER
                                 , X_cross_project_user    IN VARCHAR2
                                 , X_calling_module        IN VARCHAR2
                                 , X_event                 IN VARCHAR2
                                 , X_value                 OUT VARCHAR2
                                 , X_cross_project_view    IN VARCHAR2 := 'Y' )
  IS
    -- Declare local variables

    X_project_num 	VARCHAR2(25);
    X_tmp           CHAR;
    v_proj_class_code VARCHAR2(100);
    v_resp_id      NUMBER;
    v_resp_appl_id NUMBER;
    v_user_id      NUMBER;

  BEGIN

/*** Calling Modules *********************************************************

    The pa_security_extn will be invoked from the following modules.
    You can use the module name in this extension to control project access in
    a specific module. The calling module parameter X_calling_module has the
    following values.

    FORMS:

    Module Name      User Name      		Description
    ---------        -----------      		-----------
    PAXBUEBU         Budgets          		Enter Budgets
    PAXCARVW         Capital Projects   	Manage Capital project asset
 						capitalization
    PAXINEAG         Agreements         	Enter Agreements and Funding
    PAXINEVT         Events Maintenance 	Events Inquiry
    PAXINRVW         Invoices           	Review Invoices
    PAXINVPF         Project Funding    	Inquire on Project funding
		     Inquiry
    PAXPREPR         Projects 			Enter projects
    PAXRVRVW         Review Revenue     	Review Revenue
    PAXTRAPE         Expenditure Inquiry        Inquire, Adjust Expenditure
    PAXURDDC         Project Status Display     Define Project status display
		     Columns			columns
    PAXURVPS         Project Status Inquiry     Inquire on project status

    Open Integration Toolkit :

    OIT Budget creation and maintenance

    Module Name
    ------------
    PA_PM_CREATE_DRAFT_BUDGET
    PA_PM_ADD_BUDGET_LINE
    PA_PM_BASELINE_BUDGET
    PA_PM_DELETE_DRAFT_BUDGET
    PA_PM_DELETE_BUDGET_LINE
    PA_PM_UPDATE_BUDGET
    PA_PM_UPDATE_BUDGET_LINE

    OIT Project Maintenance

    Module Name
    ------------
    PA_PM_ADD_TASK
    PA_PM_UPDATE_PROJECT
    PA_PM_UPDATE_TASK
    PA_PM_DELETE_PROJECT

    OIT Maintain Progess Data

    Module Name
    ------------
    PA_PM_UPDATE_PROJ_PROGRESS
    PA_PM_UPDATE_EARNED_VALUE

*******************************************************************************/

/****************** Example Security Code Begins *******************************

--  To use the following example code, please uncomment the code.
--
--  The example allows only users assigned to the same organization as the
--  project organization to have access to the project.
--
--  If required, the security check can be only for specific modules.
--  You change the IF condition to include or remove the module names.
--   Changed for the Private Brand conversion security CR 816 



 IF X_calling_module = 'Module Name' THEN

    BEGIN
       IF (x_project_id IS NOT NULL) THEN       -- Added the condition for bug 2853458
	SELECT 'x'
	INTO   x_tmp
	FROM   pa_projects_all ppa , per_assignments_f paf
	WHERE  ppa.project_id = X_project_id
	AND    ppa.carrying_out_organization_id = paf.organization_id
	AND    paf.person_id = X_person_id
	AND    paf.assignment_type = 'E'
        AND    paf.primary_flag='Y' --Added for bug 291451
	AND    trunc(SYSDATE)
	       BETWEEN paf.effective_start_date AND paf.effective_end_date;
       END IF;
    EXCEPTION
	WHEN NO_DATA_FOUND THEN
	     X_value := 'N';
             RETURN;

    END;

    X_value := 'Y';
    RETURN;

END IF;
********* Example Code Ends Here ************************************************/


---
-- IF X_calling_module IN ('PAXTRAPE_GL_DRILLDOWN','PAXRVRVW_GL_DRILLDOWN',
--                        'GL_DRILLDOWN_PA_COST', 'GL_DRILLDOWN_PA_REVENUE',
--                        'PAXPREPR','PAXBUEBU','PAXCARVW','PAXINEAG','PAXINEVT',         
--                        'PAXINRVW','PAXINVPF','PAXPREPR','PAXRVRVW','PAXTRAPE',         
--                        'PAXURDDC','PAXURVPS') THEN

--    BEGIN
--       IF (x_project_id IS NOT NULL) THEN       -- Added the condition for bug 2853458
--        SELECT 'x' 
--          INTO x_tmp
--          FROM pa_projects_all ppa,
--               pa_project_types_all ppt,
--               pa_project_parties ppp
--         WHERE ppa.project_type = ppt.project_type
--           AND ppt.direct_flag = 'Y'
--           AND ppa.project_id = ppp.project_id
--           AND ppa.project_id = X_project_id
--           AND ppp.resource_source_id = X_person_id ;
--       END IF;
--    EXCEPTION
--	WHEN NO_DATA_FOUND THEN
--	     X_value := 'N';
--             RETURN;

--    END;

--    X_value := 'Y';
--    RETURN;

--END IF;


 IF X_calling_module IN ('PAXTRAPE_GL_DRILLDOWN','PAXRVRVW_GL_DRILLDOWN',
                        'GL_DRILLDOWN_PA_COST', 'GL_DRILLDOWN_PA_REVENUE',
                        'PAXPREPR','PAXBUEBU','PAXCARVW','PAXINEAG','PAXINEVT',         
                        'PAXINRVW','PAXINVPF','PAXPREPR','PAXRVRVW','PAXTRAPE',         
                        'PAXURDDC','PAXURVPS','PAXTRAPE.PROJECT','APXINWKB','PAXPREPC') THEN
    v_resp_id := fnd_global.resp_id;
    v_resp_appl_id := fnd_global.resp_appl_id;
    v_user_id := fnd_global.user_id ;
    
    BEGIN
       IF (x_project_id IS NOT NULL) THEN       -- Added the condition for bug 2853458
        SELECT project_type_class_code 
          INTO v_proj_class_code
          FROM pa_projects_all ppa,
               pa_project_types_all ppt
         WHERE ppa.project_type = ppt.project_type
           --AND ppt.direct_flag = 'Y'
           AND ppa.project_id = X_project_id;
       ELSE
         v_proj_class_code := 'CONTRACT';
       END IF;
    EXCEPTION
	WHEN NO_DATA_FOUND THEN
	     X_value := 'N';
             RETURN;

    END;

    IF fnd_profile.value_specific('XX_PA_PB_PROJ_ACCESS',v_user_id, v_resp_id, v_resp_appl_id) = 'N' 
       AND v_proj_class_code = 'CONTRACT'
    THEN
      X_value  := 'N';
    ELSE
      X_value  := 'Y';
    END IF;
    
     RETURN;
 END IF ;
---
    IF x_calling_module IN ('PAXTRAPE_GL_DRILLDOWN','PAXRVRVW_GL_DRILLDOWN',
                        'GL_DRILLDOWN_PA_COST', 'GL_DRILLDOWN_PA_REVENUE')
    AND x_event IN  ('ALLOW_QUERY' , 'VIEW_LABOR_COSTS')
    THEN
          X_value := 'Y';
          RETURN;
    END IF;

    IF ( X_event = 'ALLOW_QUERY' ) THEN

      -- Default processing is to only grant ALLOW_QUERY access to cross
      -- project update users (done at beginning of procedure), cross project
      -- view users, project authorities for the encompassing organization, and
      -- active key members defined for the project.

      -- PA provides an API to determine whether or not a given person is a
      -- project authority on a specified project.  This function,
      -- CHECK_PROJECT_AUTHORITY is defined in the PA_SECURITY package.  It takes
      -- two input parameters, person_id and project_id, and returns as
      -- output:
      --   'Y' if the person is a project authority for the project,
      --   'N' if the person is not.

      -- Note, if NULL values are passed for either parameter, person or
      -- project, then the function returns NULL.

      -- PA provides an API to determine whether or not a given person is an
      -- active key member on a specified project.  This function,
      -- CHECK_KEY_MEMBER is defined in the PA_SECURITY package.  It takes
      -- two input parameters, person_id and project_id, and returns as
      -- output:
      --   'Y' if the person is an active key member for the project,
      --   'N' if the person is not.

      -- Note, if NULL values are passed for either parameter, person or
      -- project, then the function returns NULL.

      -- You can change the default processing by adding your own rules
      -- based on the project and user attributes passed into this procedure.

      IF X_cross_project_view = 'Y' THEN
        X_value := 'Y';
        RETURN;
      END IF;

      IF X_calling_module = 'PA_FORECASTING' THEN
        IF pa_security.check_key_member( X_person_id, X_project_id ) = 'Y' THEN
          X_value := 'Y';
          RETURN;
        END IF;

         X_value := pa_security.check_forecast_authority( X_person_id, X_project_id );
      ELSE

        IF pa_security.check_key_member_no_dates( X_person_id, X_project_id ) = 'Y' THEN
          X_value := 'Y';
          RETURN;
        END IF;

        X_value :=  pa_security.check_project_authority( X_person_id, X_project_id );
      END IF;

      RETURN;

    ELSIF ( X_event = 'ALLOW_UPDATE' ) THEN


      -- Default processing is to only grant ALLOW_QUERY access to cross
      -- project update users (done at beginning of procedure), project authorities
      -- for the encompassing organization, and active key members defined for the
      -- project.

      IF X_cross_project_user = 'Y' THEN
        X_value := 'Y';
        RETURN;
      END IF;

      IF pa_security.check_key_member( X_person_id, X_project_id ) = 'Y' THEN
        X_value := 'Y';
        RETURN;
      END IF;

      X_value := pa_security.check_project_authority( X_person_id, X_project_id );
      RETURN;

RETURN;

    ELSIF ( X_event = 'VIEW_LABOR_COSTS' ) THEN

      -- Default validation in PA to determine if a user has privileges to
      -- view labor cost amounts for expenditure item details is to ensure
      -- that the person is an active key member for the project, and that
      -- the user's project role type for that assignment is one that allows
      -- query access to labor cost amounts.

      -- PA provides an API to determine whether or not a given person
      -- has VIEW_LABOR_COSTS access for a given project based on the above
      -- criteria.  This function, CHECK_LABOR_COST_ACCESS is defined in
      -- the PA_SECURITY package.  It takes two input parameters, person_id
      -- and project_id, and returns as output:
      --    'Y' if the person has access to view labor costs
      --    'N' if the person does not.

      -- Note, if NULL values are passed for either parameter, person or
      -- project, then the function returns NULL.

      IF X_cross_project_user = 'Y' THEN
        X_value := 'Y';
        RETURN;
      END IF;

      X_value := pa_security.check_labor_cost_access( X_person_id
                                                    , X_project_id );
      RETURN;

    END IF;

  END check_project_access;

END pa_security_extn;
/