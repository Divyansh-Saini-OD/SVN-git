CREATE OR REPLACE VIEW XXOD_ICM_FIND_TRACK_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                      Oracle/Office Depot                          |
-- +===================================================================+
-- | Name  : XXOD_ICM_FIND_TRACK_V                                       |
-- | Description: Custom view used by Oracle ICM Discoverer Findings   |
-- |              Tracking Report.                                     |
-- |                                                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ===========================|
-- |1.0       13-SEP-2006  M.Gautier        Initial version            |
-- |1.1       28-SEP-2006  M.Gautier        Modified view per Test Director Def#21. |
-- |                                        Changed Column Heading and Data Source  |
-- |                                        for the Finding Name and Description.   |
-- |1.2       10-OCT-2006  M.Gautier        Added new column 'Finding Priority |
-- |                                        per TD Def#21 new requirement      |
-- | 2.0       07-FEB-2007 M.Gautier        Modifed view name per naming conventions|
-- +===================================================================+       |
("Engagement", "Organization", "Parent Process", "Process Name", "Control Objective Description ", 
 "Risk Name", "Risk Description", "Control Name", "Control Description", "Finding Name", 
 "Finding Description", "Finding Status", "Finding Priority", "Vice President", "Control Owner", 
 "Key User", "Finding Date", "Need By Date", "Reason", "Requestor", 
 "Assigned To")
AS 
SELECT apt.NAME "Engagement"
        , NULL "Organization"
        , NULL "Parent Process"
        , NULL "Process Name"
        , NULL "Control Objective Description "
        , NULL "Risk Name"
        , NULL "Risk Description"
        , NULL "Control Name"
        , NULL "Control Description"
        ,
          --eec.change_notice  , 09/28/2008 MGautier Removed as a wrong date source for the Finding Name see TD Def#21
          eec.change_name "Finding Name"
        , eec.description "Finding Description"
        ,                            --09/28/2008 MGautier added per TD Def#21
          cst.status_name "Finding Status"
        ,     -- changed form Testing Status 09/28/2008 MGautier see TD Def#21
          eec.priority_code "Finding Priority"
        ,            --10/03/2006 MGautier added per TD Def#21 new requirement
          NULL "Vice President"
        , NULL "Control Owner"
        , NULL "Key User"
        , eec.creation_date "Finding Date"
        , TO_CHAR (eec.need_by_date, 'DD-MON-YYYY') "Need By Date"
        , eec.reason_code "Reason"
        , hzp1.party_name "Requestor"
        , hzp2.party_name "Assigned To"
     FROM amw.amw_audit_projects_tl apt
        , amw.amw_audit_projects apr
        , eng.eng_engineering_changes eec
        , eng.eng_change_subjects esb
        , eng.eng_change_statuses ecs
        , eng.eng_change_statuses_tl cst
        , ar.hz_parties hzp1
        , ar.hz_parties hzp2
    WHERE apt.audit_project_id = apr.audit_project_id
      AND NVL (apr.template_flag, 'N') = 'N'
      AND SUBSTR (apr.audit_project_status, 1, 1) = 'A'
      AND TO_CHAR (apr.audit_project_id) = esb.pk1_value
      --findings
      AND esb.change_id = eec.change_id
      AND esb.entity_name = 'PROJECT'
      AND eec.change_mgmt_type_code = 'AMW_PROJ_FINDING'
      AND eec.status_code = ecs.status_code
      AND esb.subject_level = 1
      AND eec.organization_id = -1
      AND cst.status_code = ecs.status_code
      AND eec.requestor_id = hzp1.party_id
      AND eec.assignee_id = hzp2.party_id
      AND cst.LANGUAGE = USERENV ('LANG')
   UNION --audit procedure level
   SELECT apt.NAME "Engagement"
        , org2.NAME "Organization"
        , apn1.display_name "Parent Process Name"
        , apn2.display_name "Process Name"
        , abt.description "Process Objectvie Description"
        , rtl.NAME "Risk Name"
        , rtl.description "Risk Description"
        , act.NAME "Control Name"
        , act.description "Constrol Description"
        ,
          --eec.change_notice  , 09/28/2008 MGautier Removed as a wrong date source for the Finding Name TD Def#21
          eec.change_name "Finding Name"
        , eec.description "Finding Descirption"
        ,                            --09/28/2008 MGautier added per TD Def#21
          cst.status_name "Finding Status"
        ,                    --09/28/2008 MGautier changed form Testing Status
          eec.priority_code "Finding Priority"
        ,            --10/03/2006 MGautier added per TD Def#21 new requirement
          act.verification_instruction "Vice President"
        , act.physical_evidence "Control Owner"
        , act.verification_source_name "Key User"
        , eec.creation_date "Finding Date"
        , TO_CHAR (eec.need_by_date, 'DD-MON-YYYY') "Need By Date"
        , eec.reason_code "Reason"
        , hzp1.party_name "Requestor"
        , hzp2.party_name "Assigned To"
     FROM amw.amw_audit_projects_tl apt
        , amw.amw_audit_projects apr
        , amw.amw_audit_scope_organizations org1
        , apps.AMW_AUDIT_UNITS_V org2
        , amw.amw_audit_scope_processes asp
        , amw.amw_approved_hierarchies aah
        , amw.amw_process amp1
        , amw.amw_process_names_tl apn1
        , amw.amw_process amp2
        , amw.amw_process_names_tl apn2
        , amw.amw_risk_associations ars
        , amw.amw_process_objectives_tl abt
        , amw.amw_objective_associations oba
        , amw.amw_risks_b arb
        , amw.amw_risks_tl rtl
        , amw.amw_control_associations aca
        , amw.amw_controls_b acb
        , amw.amw_controls_tl act
        , amw.amw_audit_procedures_b aap
        , amw.amw_audit_procedures_tl ptl
        , amw.amw_ap_associations aaa
        , eng.eng_change_subjects esb
        , eng.eng_engineering_changes eec
        , eng.eng_change_statuses ecs
        , eng.eng_change_statuses_tl cst
        , ar.hz_parties hzp1
        , ar.hz_parties hzp2
    WHERE apt.audit_project_id = apr.audit_project_id
      AND NVL (apr.template_flag, 'N') = 'N'
      AND SUBSTR (apr.audit_project_status, 1, 1) = 'A'
      AND apr.audit_project_id = org1.audit_project_id
      AND org1.organization_id = org2.organization_id
      AND asp.audit_project_id = apr.audit_project_id
      AND asp.organization_id = org1.organization_id
      --process
      AND amp1.process_id = aah.parent_id
      AND amp2.process_id = aah.child_id
      AND amp1.process_rev_id = apn1.process_rev_id
      AND amp2.process_rev_id = apn2.process_rev_id
      AND aah.end_date IS NULL
      AND amp1.end_date IS NULL
      AND amp1.approval_status = 'A'
      AND amp2.end_date IS NULL
      AND amp2.approval_status = 'A'
      AND apn1.LANGUAGE = USERENV ('LANG')
      AND apn2.LANGUAGE = USERENV ('LANG')
      AND aah.organization_id = asp.organization_id
      AND amp2.process_id = asp.process_id
      --process objective
      AND oba.object_type = 'CONTROL'
      AND oba.pk1 = aca.pk3
      AND oba.pk2 = aca.pk4
      AND oba.pk3 = aca.control_id
      AND oba.deletion_date IS NULL
      AND oba.process_objective_id = abt.process_objective_id
      AND abt.LANGUAGE = USERENV ('LANG')
--risks
      AND ars.risk_id = arb.risk_id
      AND arb.end_date IS NULL
      AND arb.latest_revision_flag = 'Y'
      AND arb.curr_approved_flag = 'Y'
      AND ars.pk1 = apr.audit_project_id
      AND ars.pk2 = TO_CHAR (asp.organization_id)
      AND ars.pk3 = TO_CHAR (asp.process_id)
      AND ars.risk_rev_id = rtl.risk_rev_id
      AND rtl.risk_id = arb.risk_id
      AND rtl.risk_rev_id = arb.risk_rev_id
      AND rtl.LANGUAGE = USERENV ('LANG')
--controls
      AND acb.control_id = aca.control_id
      AND acb.control_rev_id = aca.control_rev_id
      AND act.control_rev_id = acb.control_rev_id
      AND act.LANGUAGE = USERENV ('LANG')
      AND acb.latest_revision_flag = 'Y'
      AND acb.curr_approved_flag = 'Y'
      AND acb.end_date IS NULL
      AND aca.pk1 = ars.pk1   --project_id
      AND aca.pk2 = ars.pk2   --org_id
      AND aca.pk3 = ars.pk3   --process_id
      AND aca.pk4 = TO_CHAR (ars.risk_id)
--procedures
      AND aaa.object_type = 'PROJECT'
      AND aaa.pk3 = aca.control_id
      AND aaa.pk1 = aca.pk1
      AND aaa.pk2 = aca.pk2
      AND aap.audit_procedure_rev_id = aaa.audit_procedure_rev_id
      AND aap.approval_status = 'A'
      AND aap.approval_date IS NOT NULL
      AND aap.end_date IS NULL
      AND aap.audit_procedure_rev_id = ptl.audit_procedure_rev_id
      AND ptl.LANGUAGE = USERENV ('LANG')
      -- Findings
      AND esb.pk1_value = TO_CHAR (aap.audit_procedure_id)
      AND esb.subject_level = 1
      AND esb.change_id = eec.change_id
      AND esb.entity_name = 'PROJ_ORG_AP'
      AND eec.change_mgmt_type_code = 'AMW_PROJ_FINDING'
      AND eec.status_code = ecs.status_code
      AND esb.subject_level = 1
      AND eec.organization_id = -1
      AND cst.status_code = ecs.status_code
      AND cst.LANGUAGE = USERENV ('LANG')
      AND eec.requestor_id = hzp1.party_id
      AND eec.assignee_id = hzp2.party_id
   UNION
--steps
   SELECT apt.NAME "Engagement"
        , org2.NAME "Organization"
        , apn1.display_name "Parent Process Name"
        , apn2.display_name "Process Name"
        , abt.description "Process Objectvie Description"
        , rtl.NAME "Risk Name"
        , rtl.description "Risk Description"
        , act.NAME "Control Name"
        , act.description "Constrol Description"
        ,
          --eec.change_notice  ,  09/28/2008 MGautier Removed as a wrong date source for hte Finding Name TD Def#21
          eec.change_name "Finding Name"
        , eec.description "Finding Descirption"
        ,                            --09/28/2008 MGautier added per TD Def#21
          cst.status_name "Finding Status"
        ,                   -- changed form Testing Status 09/28/2008 MGautier
          eec.priority_code "Finding Priority"
        ,            --10/03/2006 MGautier added per TD Def#21 new requirement
          act.verification_instruction "Vice President"
        , act.physical_evidence "Control Owner"
        , act.verification_source_name "Key User"
        , eec.creation_date "Finding Date"
        , TO_CHAR (eec.need_by_date, 'DD-MON-YYYY') "Need By Date"
        , eec.reason_code "Reason"
        , hzp1.party_name "Requestor"
        , hzp2.party_name "Assigned To"
     FROM amw.amw_audit_projects_tl apt
        , amw.amw_audit_projects apr
        , amw.amw_audit_scope_organizations org1
        , apps.AMW_AUDIT_UNITS_V org2
        , amw.amw_audit_scope_processes asp
        , amw.amw_approved_hierarchies aah
        , amw.amw_process amp1
        , amw.amw_process_names_tl apn1
        , amw.amw_process amp2
        , amw.amw_process_names_tl apn2
        , amw.amw_risk_associations ars
        , amw.amw_process_objectives_tl abt
        , amw.amw_objective_associations oba
        , amw.amw_risks_b arb
        , amw.amw_risks_tl rtl
        , amw.amw_control_associations aca
        , amw.amw_controls_b acb
        , amw.amw_controls_tl act
        , amw.amw_audit_procedures_b aap
        , amw.amw_audit_procedures_tl ptl
        , amw.amw_ap_associations aaa
        , eng.eng_change_subjects esb
        , eng.eng_engineering_changes eec
        , eng.eng_change_statuses ecs
        , eng.eng_change_statuses_tl cst
        , ar.hz_parties hzp1
        , ar.hz_parties hzp2
        , amw.amw_ap_steps_b aps
        , amw.amw_ap_steps_tl pst
        , amw.amw_ap_executions ape
    WHERE apt.audit_project_id = apr.audit_project_id
      AND NVL (apr.template_flag, 'N') = 'N'
      AND SUBSTR (apr.audit_project_status, 1, 1) = 'A'
      AND apr.audit_project_id = org1.audit_project_id
      AND org1.organization_id = org2.organization_id
      AND asp.audit_project_id = apr.audit_project_id
      AND asp.organization_id = org1.organization_id
      --process
      AND amp1.process_id = aah.parent_id
      AND amp2.process_id = aah.child_id
      AND amp1.process_rev_id = apn1.process_rev_id
      AND amp2.process_rev_id = apn2.process_rev_id
      AND aah.end_date IS NULL
      AND amp1.end_date IS NULL
      AND amp1.approval_status = 'A'
      AND amp2.end_date IS NULL
      AND amp2.approval_status = 'A'
      AND apn1.LANGUAGE = USERENV ('LANG')
      AND apn2.LANGUAGE = USERENV ('LANG')
      AND aah.organization_id = asp.organization_id
      AND amp2.process_id = asp.process_id
      --process objective
      AND oba.object_type = 'CONTROL'
      AND oba.pk1 = aca.pk3
      AND oba.pk2 = aca.pk4
      AND oba.pk3 = aca.control_id
      AND oba.deletion_date IS NULL
      AND oba.process_objective_id = abt.process_objective_id
      AND abt.LANGUAGE = USERENV ('LANG')
--risks
      AND ars.risk_id = arb.risk_id
      AND arb.end_date IS NULL
      AND arb.latest_revision_flag = 'Y'
      AND arb.curr_approved_flag = 'Y'
      AND ars.pk1 = apr.audit_project_id
      AND ars.pk2 = TO_CHAR (asp.organization_id)
      AND ars.pk3 = TO_CHAR (asp.process_id)
      AND ars.risk_rev_id = rtl.risk_rev_id
      AND rtl.risk_id = arb.risk_id
      AND rtl.risk_rev_id = arb.risk_rev_id
      AND rtl.LANGUAGE = USERENV ('LANG')
--controls
      AND acb.control_id = aca.control_id
      AND acb.control_rev_id = aca.control_rev_id
      AND act.control_rev_id = acb.control_rev_id
      AND act.LANGUAGE = USERENV ('LANG')
      AND acb.latest_revision_flag = 'Y'
      AND acb.curr_approved_flag = 'Y'
      AND acb.end_date IS NULL
      AND aca.pk1 = ars.pk1     --project_id
      AND aca.pk2 = ars.pk2     --org_id
      AND aca.pk3 = ars.pk3     --process_id
      AND aca.pk4 = TO_CHAR (ars.risk_id)
--procedures
      AND aaa.object_type = 'PROJECT'
      AND aaa.pk1 = aca.pk1
      AND aaa.pk2 = aca.pk2
      AND aaa.pk3 = aca.control_id
      AND aap.audit_procedure_rev_id = aaa.audit_procedure_rev_id
      AND aap.approval_status = 'A'
      AND aap.approval_date IS NOT NULL
      AND aap.end_date IS NULL
      AND aap.audit_procedure_rev_id = ptl.audit_procedure_rev_id
      AND ptl.LANGUAGE = USERENV ('LANG')
      -- Findings
      AND esb.pk1_value = TO_CHAR (aps.ap_step_id)
      AND esb.subject_level = 1
      AND esb.change_id = eec.change_id
      AND esb.entity_name = 'PROJ_ORG_AP_STEP'
      AND eec.change_mgmt_type_code = 'AMW_PROJ_FINDING'
      AND eec.status_code = ecs.status_code
      AND eec.organization_id = -1
      AND cst.status_code = ecs.status_code
      AND cst.LANGUAGE = USERENV ('LANG')
      AND eec.requestor_id = hzp1.party_id
      AND eec.assignee_id = hzp2.party_id
      --steps
      AND aps.audit_procedure_id = aap.audit_procedure_id
      AND pst.ap_step_id = aps.ap_step_id
      AND pst.LANGUAGE = USERENV ('LANG')
      AND ape.execution_type = 'STEP'
      AND ape.ap_step_id = aps.ap_step_id
      AND ape.audit_procedure_rev_id = aap.audit_procedure_rev_id
      AND ape.pk1 = aca.pk1
      AND ape.pk2 = aca.pk2
      AND ape.pk3 = TO_CHAR (eec.organization_id)
/


