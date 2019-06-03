CREATE OR REPLACE VIEW q_od_pb_approval_plan_v (row_id,
                                                plan_id,
                                                plan_name,
                                                organization_id,
                                                organization_name,
                                                collection_id,
                                                occurrence,
                                                last_update_date,
                                                last_updated_by_id,
                                                last_updated_by,
                                                creation_date,
                                                created_by_id,
                                                created_by,
                                                last_update_login,
                                                od_pb_comments,
                                                od_pb_approval_status,
                                                od_pb_comments_verified,
                                                od_pb_sku,
                                                od_pb_change_desc,
                                                od_pb_qa_engineer,
                                                od_pb_supplier,
                                                od_pb_audit_grade,
                                                od_pb_record_id,
                                                od_pb_qa_approver
                                               )
AS
   SELECT qr.ROWID row_id, qr.plan_id, qp.NAME plan_name, qr.organization_id,
          hou.NAME organization_name, qr.collection_id, qr.occurrence,
          qr.qa_last_update_date last_update_date,
          qr.qa_last_updated_by last_updated_by_id,
          fu2.user_name last_updated_by, qr.qa_creation_date creation_date,
          qr.qa_created_by created_by_id, fu.user_name created_by,
          qr.last_update_login, qr.comment1 "OD_PB_COMMENTS",
          qr.character3 "OD_PB_APPROVAL_STATUS",
          qr.character5 "OD_PB_COMMENTS_VERIFIED", qr.character7 "OD_PB_SKU",
          qr.comment2 "OD_PB_CHANGE_DESC", qr.character10 "OD_PB_QA_ENGINEER",
          qr.character11 "OD_PB_SUPPLIER", qr.character12 "OD_PB_AUDIT_GRADE",
          qr.sequence8 "OD_PB_RECORD_ID", qr.character1 "OD_PB_QA_APPROVER"
     FROM qa_results qr,
          qa_plans qp,
          fnd_user_view fu,
          fnd_user_view fu2,
          hr_organization_units hou
    WHERE qp.NAME='OD_PB_APPROVAL_PLAN'
      AND qp.plan_id = qr.plan_id
      AND qr.qa_created_by = fu.user_id
      AND qr.qa_last_updated_by = fu2.user_id
      AND qr.organization_id = hou.organization_id
      AND (qr.status IS NULL OR qr.status = 2)
/
