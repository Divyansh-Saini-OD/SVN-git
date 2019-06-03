INSERT INTO apps.q_OD_PB_APPROVAL_PLAN_IV 
	(	  process_status
         	, organization_code
                , plan_name
                , insert_type
                , matching_elements
                , od_pb_comments 
                , od_pb_approval_status 
                , od_pb_comments_verified 
                , od_pb_sku 
                , od_pb_change_desc 
                , od_pb_qa_engineer 
                , od_pb_supplier 
                , od_pb_audit_grade 
                , od_pb_record_id 
                , od_pb_qa_approver,
        	  qa_created_by_name,
	          qa_last_updated_by_name
        )
SELECT           '1'
                , 'PRJ'
                , 'OD_PB_APPROVAL_PLAN'
                , '1' --1 for INSERT
	        , 'OD_PB_SKU,OD_PB_SUPPLIER'
                , od_pb_comments 
                , od_pb_approval_status 
                , od_pb_comments_verified 
                , od_pb_sku 
                , od_pb_change_desc 
                , od_pb_qa_engineer 
                , od_pb_supplier 
                , od_pb_audit_grade 
                , od_pb_record_id 
                , od_pb_qa_approver,
	          d.user_name,
        	  e.user_name
FROM apps.fnd_user e,
     apps.fnd_user d,
     apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
     apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_APPROVAL_PLAN_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
commit;
