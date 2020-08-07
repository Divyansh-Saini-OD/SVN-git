CREATE OR REPLACE VIEW apps.XXOD_ICM_APPL_CTRL_MONITOR_V 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |             Oracle Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :  xxod_icm_appl_ctrl_monitor_v                         |
-- | Description: This View is Created for the Controls By VP report   |                                                  |
-- |              for the ICM team.                                    |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |
-- |1.0      14-SEP-2006  Rahul Kundavaram   Created The View          |
--  2.0      07-FEB-2007  Michelle Gautier  Changed view name         |
--                        per naming conventions.                      |
--   2.1    23-SEP-2008  M.Gautier modifed to fix defect# 11313|
--   2.2    07-OCT-2008  M.Gautier changed source for Last Updated By |
--	 					 for defect# 11313 		  	  	   		   	  |
-- +===================================================================+
(INSTANCE, "Reporting Group", "Setup Group", "Setup Parameter", "Organization Name", 
 "Organization Type", "Prior Value", "Recommended Value", "Current Value", "Last Updated By", 
 "Last Update Date" , "User Name"
 )
AS 
SELECT itl.instance_name INSTANCE
        , rtl.reporting_group_name "Reporting Group"
        , stl.setup_group_name "Setup Group"
        , sptl.parameter_name "Setup Parameter"
        , NVL (hist.pk1_value, ' ') "Organization Name"
        , shtl.hierarchy_level_name "Organization Type"
        , hist.prior_value "Prior Value"
        , rvtl.recommended_value "Recommended Value"
        , hist.current_value "Current Value"
		-- 10/09/2008 M.Gautier modifed to fix defect# 11313
		, hist.change_author "Last Updated By"
      --  , hist.last_updated_by "Last Updated By"
		,  hist.change_date "Last Update Date"
        , ppf.first_name||' '||NVL(ppf.last_name, 'User Terminated') "User Name"
		--MG
     FROM ita.ita_setup_rpt_groups_b rb
        , ita.ita_setup_rpt_groups_tl rtl
        , ita.ita_setup_rpt_gp_details rgd
        , ita.ita_setup_groups_b sb
        , ita.ita_setup_groups_tl stl
        , ita.ita_setup_parameters_b sp
        , ita.ita_setup_parameters_tl sptl
        , ita.ita_setup_rec_values_b rv
        , ita.ita_setup_rec_values_tl rvtl
        , ita.ita_setup_change_history hist
        , ita.ita_setup_hierarchy_b sh
        , ita.ita_setup_hierarchy_tl shtl
		, apps.per_people_f  ppf
         --, apps.fnd_user fnd
       , ita.ita_setup_instances_b ib
        , ita.ita_setup_instances_tl itl
    WHERE ib.current_flag = 'Y'
	  AND rb.instance_code = rtl.instance_code
	  AND hist.INSTANCE_CODE  = ib.INSTANCE_CODE
      AND rb.reporting_group_id = rtl.reporting_group_id
      AND rtl.LANGUAGE = USERENV ('LANG')
      AND rb.reporting_group_id = rgd.reporting_group_id
      AND rb.instance_code = rgd.instance_code
      AND rgd.setup_group_code = sb.setup_group_code
      AND sb.setup_group_code = stl.setup_group_code
      AND stl.LANGUAGE = USERENV ('LANG')
      AND rgd.parameter_code = sp.parameter_code
      AND sp.parameter_code = sptl.parameter_code
      AND sptl.LANGUAGE = USERENV ('LANG')
	  and sp.AUDIT_ENABLED_FLAG  = 'Y'
      AND sp.parameter_code = rv.parameter_code (+)
      AND rv.parameter_code = rvtl.parameter_code(+)
      AND rv.context_org_name = rvtl.context_org_name(+)
      AND rvtl.LANGUAGE(+) = USERENV ('LANG')
      AND sp.parameter_code = hist.parameter_code--(+)
	  AND sb.hierarchy_level = sh.hierarchy_level_code(+)
      AND sh.hierarchy_level_code = shtl.hierarchy_level_code(+)
      AND shtl.LANGUAGE(+) = USERENV ('LANG')
      --AND hist.last_updated_by = fnd.user_id(+)
      AND rb.instance_code = ib.instance_code
      AND ib.instance_code = itl.instance_code
	  AND hist.CHANGE_AUTHOR  = ppf.EMPLOYEE_NUMBER(+)
      AND itl.LANGUAGE = USERENV ('LANG')
     -- 09/23/2008 M.Gautier modifed to fix defect# 11313
	  --AND rb.end_date > = SYSDATE
      AND NVL(rb.end_date, TRUNC(SYSDATE)) > = TRUNC(SYSDATE)
/


