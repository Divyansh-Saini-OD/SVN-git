CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_XXPAPRJI_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_XXAPAPRJI_PKG                                |
-- | Description :  OD Private Brand Reports                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-Aug-2009 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

FUNCTION get_curr_forecast(p_project_id IN NUMBER) return NUMBER
IS
v_curr_fcst NUMBER;
BEGIN
  SELECT NVL(SUM(pbl.revenue),0)
    INTO v_curr_fcst
    FROM apps.pa_budget_lines pbl,
         apps.pa_resource_assignments pra,
         apps.pa_budget_versions pbv
   WHERE pbl.resource_assignment_id =pra.resource_assignment_id
     AND pra.budget_version_id = pbv.budget_version_id
     AND pbv.budget_status_code = 'B'
     AND pbv.current_flag = 'Y'
     AND pra.project_id=p_project_id;
  RETURN(v_curr_fcst);
EXCEPTION
  WHEN others THEN
    RETURN(v_curr_fcst);
END get_curr_forecast;


FUNCTION get_orig_forecast(p_project_id IN NUMBER) return NUMBER
IS
v_org_fcst NUMBER;
BEGIN
  SELECT NVL(SUM(pbl.revenue),0)
    INTO v_org_fcst
    FROM apps.pa_budget_lines pbl,
         apps.pa_resource_assignments pra,
         apps.pa_budget_versions pbv
   WHERE pbl.resource_assignment_id =pra.resource_assignment_id
     AND pra.budget_version_id = pbv.budget_version_id
     AND pbv.budget_status_code = 'B'
     AND pbv.original_flag = 'Y'
     AND pra.project_id=p_project_id;
   RETURN(v_org_fcst);
EXCEPTION
  WHEN others THEN
    RETURN(v_org_fcst);
END get_orig_forecast;

FUNCTION get_rev_forecast(p_project_id IN NUMBER) return NUMBER
IS
v_rev_fcst NUMBER;
BEGIN
  SELECT NVL(SUM(pbl.revenue),0) 
    INTO v_rev_fcst
    FROM apps.pa_budget_lines pbl,
         apps.pa_resource_assignments pra,
         apps.pa_budget_versions pbv
   WHERE pbl.resource_assignment_id =pra.resource_assignment_id
     AND pra.budget_version_id = pbv.budget_version_id
     AND pbv.budget_status_code = 'B'
     AND pbv.original_flag = 'N'
     AND pbv.current_original_flag = 'N'
     AND pbv.current_flag='Y'
     AND pra.project_id=p_project_id;
   RETURN(v_rev_fcst);
EXCEPTION
  WHEN others THEN
    RETURN(v_rev_fcst);
END get_rev_forecast;


FUNCTION get_task_member(p_user_id IN VARCHAR2) return varchar2
IS
v_member_name varchar2(50);
BEGIN
  SELECT SUBSTR(full_name,1,35)
    INTO v_member_name
    FROM apps.per_all_people_f
   WHERE person_id=TO_NUMBER(p_user_id);
  RETURN(v_member_name);
 EXCEPTION
   WHEN others THEN
     v_member_name:=NULL;
     return(v_member_name);
END get_task_membeR;

 FUNCTION get_proj_progress_status(p_proj_status IN VARCHAR2) return varchar2
 IS
 v_status_name varchar2(50);
 BEGIN
   SELECT SUBSTR(fvsv.description,1,50)
     INTO v_status_name
     FROM apps.fnd_flex_value_sets fvs,
      apps.fnd_flex_values_vl fvsv
    WHERE fvs.flex_value_set_name='OD_PB_PROJ_PROG_STATUS'
      AND fvsv.flex_value_set_id=fvs.flex_value_set_id
      AND fvsv.flex_value=p_proj_status;
   RETURN(v_status_name);
 EXCEPTION
   WHEN others THEN
     v_status_name:=NULL;
     return(v_status_name);
 END get_proj_progress_status;


 FUNCTION get_issue_status(p_issue_status IN VARCHAR2) return varchar2
 IS
 v_issue_status VARCHAR2(50);
 BEGIN
   SELECT SUBSTR(project_status_name,1,50)
     INTO v_issue_status
     FROM apps.pa_project_statuses 
    WHERE status_type='CONTROL_ITEM'
      AND project_status_code=p_issue_status;
    RETURN(v_issue_status);
 EXCEPTION
   WHEN others THEN
     v_issue_status:=NULL;
     return(v_issue_status);
 END get_issue_status;

 FUNCTION  get_issue_progress_status(p_issue_progress_status IN VARCHAR2) return varchar2
 IS
 v_issue_prog_status VARCHAR2(50);
 BEGIN
   SELECT SUBSTR(project_status_name,1,50)
     INTO v_issue_prog_status
     FROM apps.pa_project_statuses 
    WHERE status_type='PROGRESS'
      AND project_status_code=p_issue_progress_status;
    RETURN(v_issue_prog_status);
 EXCEPTION
   WHEN others THEN
     v_issue_prog_status:=NULL;
     return(v_issue_prog_status);
 END get_issue_progress_status;

END XX_PA_XXPAPRJI_PKG;
/
