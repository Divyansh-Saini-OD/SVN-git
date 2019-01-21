CREATE OR REPLACE VIEW XXOD_ICM_RISK_CONTROL_MATRIX_V
-- +===================================================================+
-- | Name  :  XXOD_ICM_RISK_CONTROL_MATRIX_V                        |
-- | Description: This View is Created for the Risk and Control Report |
-- |              for the ICM team.                                    |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |
-- |1.0      14-SEP-2006  Rahul Kundavaram   Created The View          |
-- |2.0      22-SEP-2006  Rahul Kundavaram   Changes the Control Condition
-- |3.0      10-OCT-2006  Rahul Kundavaram   Change in Buisness Process to handle opinions|
-- |4.0      12-OCT-2006  Rahul Kundavaram   Adding a New Column Opinion |
--| 4.1      07-FEB-2007 M.Gautier   Modifed view name per naming conventions|
--|4.2       19-FEB-2007 M.Gautier  added NVL to opiniont component code column in the select statement|
--|4.3       9-APR-2007  M.Gautier  Added condition to select only 'Key' Controls|
--|5.0       10-MAY-2007  Rahul Kundavaram   Modified view per req# 5756 |
--|                       to Add Asertion Columns to the report, and req# 5446 |
--|                       to include Control Change historical record.
-- +===================================================================+
(ENGAGEMENT_NAME, ORGANIZATION, PARENT_PROCESS, PROCESS_NAME, PROCESS_OBJECTIVE_NAME, 
 PROCESS_OBJECTIVE_DESCRIPTION, RISK_NAME, RISK_DESCRIPTION, CONTROL_NAME, CONTROL_DESCRIPTION, 
 CONTROL_CODE, "Control Type", CONTROL_FREQUENCY_CODE, "Control Frequency", PREVENTIVE_CONTROL, 
 DETECTIVE_CONTROL, "Vice President", "Key User", "Control Owner", AUDIT_PROCEDURE, 
 AUDIT_PROCEDURE_DESCRIPTION, AUDIT_WORK_DESCRIPTION, AUDIT_STATUS_CODE, "Testing Status", AUDIT_OPINION, 
 OPINION_COMPONENT_CODE, CONTROL_AAPPROVAL_FLAG, EVALUATED_BY, CONTROL_ASSERTIONS)
AS 
SELECT   aapbtl.NAME engagement_name
          , aauv.NAME ORGANIZATION
          , aptl2.display_name parent_process
          , aptl.display_name process_name
          , apvl.NAME process_objective_name
          , apvl.description process_objective_description
          , artl.NAME risk_name
          , artl.description risk_description
          , actl.NAME control_name
          , actl.description control_description
          , acav.control_type control_code
          , ctyp.meaning "Control Type"
          , acav.uom_code control_frequency_code
          , ctyp1.meaning "Control Frequency"
          , acav.preventive_control preventive_control
          , acav.detective_control detective_control
          , actl.verification_instruction "Vice President"
          , actl.verification_source_name "Key User"
          , actl.physical_evidence "Control Owner"
          , apptl.NAME audit_procedure
          , apptl.description audit_procedure_description
          , ape.work_desc audit_work_description
          , ape.status audit_status_code
          , NVL (ctyp2.meaning, 'Not Tested') "Testing Status"
          , valuestable.opinion_value_name audit_opinion
          , compb.opinion_component_code opinion_component_code
          , acav.curr_approved_flag control_aapproval_flag
          , papf.full_name evaluated_by
          , xxod_disco_pkg.amw_icm_get_assertions (acav.control_rev_id)
                                                           control_assertions
       FROM amw_audit_projects aapb
          , amw_audit_projects_tl aapbtl
          , amw_audit_scope_organizations aaso
          , amw_audit_scope_processes aasp
          , AMW_AUDIT_UNITS_V aauv
          , amw_process ap
          , amw_process_names_tl aptl
          , amw_proc_hierarchy_denorm aphd
          , amw_process ap2
          , amw_process_names_tl aptl2
          , amw_risk_associations ara
          , amw_risks_b arav
          , amw_risks_tl artl
          , amw_control_associations aca
          , amw_controls_b acav
          , amw_controls_tl actl
          , AMW_LOOKUPS ctyp
          , AMW_LOOKUPS ctyp1
          , AMW_LOOKUPS ctyp2
          , amw_ap_associations apss
          , amw_audit_procedures_b apa
          , amw_audit_procedures_tl apptl
          , amw_objective_associations aao
          , amw_process_objectives_tl apvl
          , amw_ap_executions ape
          , amw_opinions ao
          , amw_opinion_details details
          , amw_opinion_componts_b compb
          , amw_opinion_values_tl valuestable
          , fnd_user fu
          , per_all_people_f papf
      WHERE aapb.audit_project_id = aapbtl.audit_project_id
        AND aapbtl.LANGUAGE = USERENV ('LANG')
        AND aapb.audit_project_id = aaso.audit_project_id
        AND aaso.audit_project_id = aasp.audit_project_id
        AND aaso.organization_id = aasp.organization_id
        AND aaso.organization_id = aauv.organization_id
        AND aauv.date_to IS NULL
        AND aasp.process_id = ap.process_id
        AND ap.approval_status = 'A'
        AND ap.approval_date IS NOT NULL
        AND ap.approval_end_date IS NULL
        AND aptl.process_rev_id = ap.process_rev_id
        AND aptl.LANGUAGE = USERENV ('LANG')
        AND ap.process_id = aphd.parent_child_id
        AND aphd.up_down_ind = 'D'
        AND aphd.hierarchy_type = 'A'
        AND aphd.process_id != -1
        AND aphd.process_id = ap2.process_id
        AND ap2.approval_status = 'A'
        AND ap2.approval_date IS NOT NULL
        AND ap2.approval_end_date IS NULL
        AND aptl2.process_rev_id = ap2.process_rev_id
        AND aptl2.LANGUAGE = USERENV ('LANG')
        AND ap.process_id = ara.pk1
        AND arav.risk_id = ara.risk_id
        AND arav.risk_rev_id = artl.risk_rev_id
        AND artl.LANGUAGE = USERENV ('LANG')
        AND ara.approval_date IS NOT NULL
        AND ara.deletion_date IS NULL
        AND arav.curr_approved_flag = 'Y'
        AND aca.pk1 = aapb.audit_project_id
        AND aca.pk2 = aauv.organization_id
        AND aca.pk3 = ap.process_id
        AND aca.pk4 = arav.risk_id
        AND aca.deletion_approval_date IS NULL
        AND aca.control_rev_id = acav.control_rev_id
        AND acav.control_rev_id = actl.control_rev_id
        --       AND acav.curr_approved_flag = 'Y'
        AND acav.key_mitigating = 'Y'
        AND actl.LANGUAGE = USERENV ('LANG')
        AND acav.control_type = ctyp.lookup_code
        AND ctyp.lookup_type = 'AMW_CONTROL_TYPE'
        AND acav.uom_code = ctyp1.lookup_code(+)
        AND ctyp1.lookup_type(+) = 'AMW_CONTROL_FREQUENCY'
        AND apss.object_type = 'PROJECT'
        AND apss.pk3 = aca.control_id
        AND apss.pk1 = aca.pk1
        AND apss.pk2 = aca.pk2
        AND apa.audit_procedure_rev_id = apss.audit_procedure_rev_id
        AND apa.approval_status = 'A'
        AND apa.approval_date IS NOT NULL
        --       AND apa.end_date IS NULL
        AND apa.audit_procedure_rev_id = apptl.audit_procedure_rev_id
        AND apptl.LANGUAGE = USERENV ('LANG')
        AND aao.object_type = 'CONTROL'
        AND aao.pk1 = aca.pk3
        AND aao.pk2 = aca.pk4
        AND aao.pk3 = aca.control_id
        AND aao.deletion_date IS NULL
        AND aao.process_objective_id = apvl.process_objective_id
        AND apvl.LANGUAGE = USERENV ('LANG')
        AND apss.audit_procedure_rev_id = ape.audit_procedure_rev_id(+)
        AND apss.pk1 = ape.pk1(+)
        AND apss.pk2 = ape.pk2(+)
        AND apss.pk4 = ape.pk3(+)
        AND ape.execution_type(+) = 'AP'
        AND ape.status = ctyp2.lookup_code(+)
        AND ctyp2.lookup_type(+) = 'AMW_PROCEDURE_STATUS'
        AND ao.pk1_value(+) = apss.pk3
        AND ao.pk2_value(+) = apss.pk1
        AND ao.pk3_value(+) = apss.pk2
        AND ao.pk4_value(+) = apss.audit_procedure_id
        AND ao.opinion_id = details.opinion_id(+)
        AND details.opinion_component_id = compb.opinion_component_id(+)
        AND valuestable.LANGUAGE(+) = USERENV ('LANG')
        AND details.opinion_value_id = valuestable.opinion_value_id(+)
        AND fu.user_id(+) = ao.last_updated_by
        AND fu.employee_id = papf.person_id(+)
        AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date(+) AND papf.effective_end_date(+)
        AND papf.employee_number(+) IS NOT NULL
        AND NVL (compb.opinion_component_code, 0) IN ('OVERALL', '0')
   ORDER BY control_name, apptl.NAME
/


