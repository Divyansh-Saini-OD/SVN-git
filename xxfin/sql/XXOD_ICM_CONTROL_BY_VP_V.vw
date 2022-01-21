CREATE OR REPLACE VIEW XXOD_ICM_CONTROL_BY_VP_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |             Oracle Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :  XXOD_ICM_CONTROL_BY_VP_V                                                      |
-- | Description: This View is Created for the Controls By VP report   |                                                  |
-- |              for the ICM team.                                                    |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |
-- |1.0      14-SEP-2006  Rahul Kundavaram   Created The View          |
-- |2.0      22-SEP-2006  Rahul Kundavaarm   Changes a Control Condition|
--|2.1      07-FEB-2007 M.Gautier  Modifed view name per naming conventions|
--/2.2      09-APR-2007 M.Gautier  Added condition to selcet only 'Key' Controls|
-- +===================================================================+
 (ENGAGEMENT_NAME, ORGANIZATION, PARENT_PROCESS, PROCESS_NAME, RISK_NAME, 
 RISK_DESCRIPTION, CONTROL_NAME, CONTROL_DESCRIPTION, CONTROL_OBJECTIVE_NAME, CONTROL_OBJECTIVE_DESCRIPTION, 
 "Control Frequency", "Vice President", "Key User", "Control Owner", "Testing Status")
AS 
SELECT   aapbtl.NAME engagement_name
          , aauv.NAME ORGANIZATION
          , aptl2.display_name parent_process
          , aptl.display_name process_name
          , artl.NAME risk_name
          , artl.description risk_description
          , actl.NAME control_name
          , actl.description control_description
          , apvl.NAME control_objective_name
          , apvl.description control_objective_description
          , ctyp1.meaning "Control Frequency"
          , actl.verification_instruction "Vice President"
          , actl.verification_source_name "Key User"
          , actl.physical_evidence "Control Owner"
          , NVL (ctyp2.meaning, 'Not Tested') "Testing Status"
       FROM amw.amw_audit_projects aapb
          , amw.amw_audit_projects_tl aapbtl
          , amw.amw_audit_scope_organizations aaso
          , amw.amw_audit_scope_processes aasp
          , apps.AMW_AUDIT_UNITS_V aauv
          , amw.amw_process ap
          , amw.amw_process_names_tl aptl
          , amw.amw_risk_associations ara
          , amw.amw_risks_b arav
          , amw.amw_risks_tl artl
          , amw.amw_control_associations aca
          , amw.amw_controls_b acav
          , amw.amw_controls_tl actl
          , apps.AMW_LOOKUPS ctyp
          , apps.AMW_LOOKUPS ctyp1
          , apps.AMW_LOOKUPS ctyp2
          , amw.amw_ap_associations apss
          , amw.amw_audit_procedures_b apa
          , amw.amw_audit_procedures_tl apptl
          , amw.amw_objective_associations aao
          , amw.amw_process_objectives_tl apvl
          , amw.amw_ap_executions ape
          , amw.amw_proc_hierarchy_denorm aphd
          , amw.amw_process ap2
          , amw.amw_process_names_tl aptl2
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
   ORDER BY process_name
/


