CREATE OR REPLACE VIEW XXOD_ICM_APPL_CTRL_MONITOR_V 
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
--  2.0      07-FEB-2007  Mkichelle Gautier  Changed view name         |
--                        per naming conventions.                      |
-- +===================================================================+
(INSTANCE, "Reporting Group", "Setup Group", "Setup Parameter", "Organization Name", 
 "Organization Type", "Prior Value", "Recommended Value", "Current Value", "Last Updated By", 
 "Last Update Date", "User Name")
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
        , hist.last_updated_by "Last Updated By"
        , TO_DATE (hist.last_update_date, 'MON-YYYY') "Last Update Date"
        , fnd.user_name "User Name"
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
        , apps.fnd_user fnd
        , ita.ita_setup_instances_b ib
        , ita.ita_setup_instances_tl itl
    WHERE rb.instance_code = rtl.instance_code
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
      AND sp.parameter_code = rv.parameter_code(+)
      AND rv.parameter_code = rvtl.parameter_code(+)
      AND rv.context_org_name = rvtl.context_org_name(+)
      AND rvtl.LANGUAGE(+) = USERENV ('LANG')
      AND sp.parameter_code = hist.parameter_code(+)
      AND sb.hierarchy_level = sh.hierarchy_level_code(+)
      AND sh.hierarchy_level_code = shtl.hierarchy_level_code(+)
      AND shtl.LANGUAGE(+) = USERENV ('LANG')
      AND hist.last_updated_by = fnd.user_id(+)
      AND rb.instance_code = ib.instance_code
      AND ib.instance_code = itl.instance_code
      AND itl.LANGUAGE = USERENV ('LANG')
      AND ib.current_flag = 'Y'
      AND rb.end_date > = SYSDATE
/