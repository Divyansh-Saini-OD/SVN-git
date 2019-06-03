INSERT INTO apps.Q_OD_PB_FQA_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
                  od_pb_supplier,
                  od_pb_factory_name,
                  od_pb_category,
                  od_pb_factory_address,
                  od_pb_factory_contact,
                  od_pb_fqa_assigned_date,
                  od_pb_audit_date,
                  od_pb_date_reported,
                  od_pb_auditor_name,
                  od_pb_audit_type,
                  od_pb_vendor_id,
                  od_pb_sku,
                  od_pb_department,
                  od_pb_design_control_score,
                  od_pb_purchase_control_score,
                  od_pb_storage_management_score,
                  od_pb_incoming_inspect_score,
                  od_pb_production_control_score,
                  od_pb_continuous_improve_score,
                  od_pb_audit_grade,
                  od_pb_approval_status,
                  od_pb_comments,
          qa_created_by_name,
          qa_last_updated_by_name
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_FQA',
                  '1', --1 for INSERT
              'OD_PB_FQA_ID_ODC,OD_PB_SKU',
                  od_pb_supplier,
                  od_pb_factory_name,
                  od_pb_category,
                  od_pb_factory_address,
                  od_pb_factory_contact,
                  od_pb_fqa_assigned_date,
                  od_pb_audit_date,
                  od_pb_date_reported,
                  od_pb_auditor_name,
                  od_pb_audit_type,
                  od_pb_vendor_id,
                  od_pb_sku,
                  od_pb_department,
                  od_pb_design_control_score,
                  od_pb_purchase_control_score,
                  od_pb_storage_management_score,
                  od_pb_incoming_inspect_score,
                  od_pb_production_control_score,
                  od_pb_continuous_improve_score,
                  od_pb_audit_grade,
                  od_pb_approval_status,
                  od_pb_comments,
          d.user_name,
          e.user_name
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_FQA_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
commit;

   
   
