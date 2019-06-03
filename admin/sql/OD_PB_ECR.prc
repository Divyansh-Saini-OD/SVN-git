INSERT INTO apps.q_od_pb_ecr_iv
	(	  process_status, 
         	  organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
                  source_reference_id,
                  od_pb_date_requested,
                  od_pb_vendor_id,
                  od_pb_supplier,
                  od_pb_contact,
                  od_pb_vendor_email,
                  od_pb_factory_id,
                  od_pb_factory_name,
                  od_pb_factory_contact,
                  od_pb_product_affected,
                  od_pb_sku,
                  od_pb_department,
                  od_pb_class,
                  od_pb_change_desc,
                  od_pb_date_proposed_production,
                  od_pb_chg_cat_aesthetics,
                  od_pb_chg_cat_design,
                  od_pb_chg_cat_location,
                  od_pb_chg_cat_packaging,
                  od_pb_chg_cat_performance,
                  od_pb_chg_cat_safety,
                  od_pb_chg_cat_software,
                  od_pb_chg_cat_substitution,
                  od_pb_qa_engineer,
                  od_pb_qa_approver,
                  od_pb_attachment,
                  od_pb_tech_rpt_num,
                  od_pb_comments,
                  od_pb_approval_status,
                  od_pb_date_qa_response,
                  od_pb_link,
		  qa_created_by_name,
		  qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id	
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_ECR',
                  '1', --1 for INSERT
	          'OD_PB_ECR_ID,OD_PB_SKU',
                  source_reference_id,
                  od_pb_date_requested,
                  od_pb_vendor_id,
                  od_pb_supplier,
                  od_pb_contact,
                  od_pb_vendor_email,
                  od_pb_factory_id,
                  od_pb_factory_name,
                  od_pb_factory_contact,
                  od_pb_product_affected,
                  od_pb_sku,
                  od_pb_department,
                  od_pb_class,
                  od_pb_change_desc,
                  od_pb_date_proposed_production,
                  od_pb_chg_cat_aesthetics,
                  od_pb_chg_cat_design,
                  od_pb_chg_cat_location,
                  od_pb_chg_cat_packaging,
                  od_pb_chg_cat_performance,
                  od_pb_chg_cat_safety,
                  od_pb_chg_cat_software,
                  od_pb_chg_cat_substitution,
                  od_pb_qa_engineer,
                  od_pb_qa_approver,
                  od_pb_attachment,
                  od_pb_tech_rpt_num,
                  od_pb_comments,
                  od_pb_approval_status,
                  od_pb_date_qa_response,
                  od_pb_link,
		  d.user_name,
		  e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_ECR_ID
 FROM 	
	apps.fnd_user e,
	apps.fnd_user d,
	apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
	apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_ECR_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
commit;

