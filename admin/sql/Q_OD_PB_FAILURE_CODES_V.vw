/* Formatted on 2010/04/19 14:18 (Formatter Plus v4.8.8) */
CREATE OR REPLACE VIEW q_od_pb_failure_codes_v (row_id,
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
                                                od_pb_tech_rpt_num,
                                                od_pb_proj_num,
                                                od_pb_item_id,
                                                od_pb_failure_codes
                                               )
AS
   SELECT qr.ROWID row_id, qr.plan_id, qp.NAME plan_name, qr.organization_id,
          hou.NAME organization_name, qr.collection_id, qr.occurrence,
          qr.qa_last_update_date last_update_date,
          qr.qa_last_updated_by last_updated_by_id,
          fu2.user_name last_updated_by, qr.qa_creation_date creation_date,
          qr.qa_created_by created_by_id, fu.user_name created_by,
          qr.last_update_login, qr.character1 "OD_PB_TECH_RPT_NUM",
          qr.character2 "OD_PB_PROJ_NUM", qr.character3 "OD_PB_ITEM_ID",
          qr.character4 "OD_PB_FAILURE_CODES"
     FROM qa_results qr,
          qa_plans qp,
          fnd_user_view fu,
          fnd_user_view fu2,
          hr_organization_units hou
    WHERE qp.NAME='OD_PB_FAILURE_CODES'
      AND qp.plan_id = qr.plan_id
      AND qr.qa_created_by = fu.user_id
      AND qr.qa_last_updated_by = fu2.user_id
      AND qr.organization_id = hou.organization_id
      AND (qr.status IS NULL OR qr.status = 2)
/
