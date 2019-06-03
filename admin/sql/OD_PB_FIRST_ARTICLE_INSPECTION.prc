INSERT INTO apps.Q_OD_PB_FIRST_ARTICLE_INSPE_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_SUPPLIER              ,   
		OD_PB_FACTORY_NAME          ,   
		OD_PB_SKU                   ,   
		OD_PB_DEPARTMENT            ,   
		OD_PB_PO_NUM                ,   
		OD_PB_DATE_OF_INSPECTON     ,   
		OD_PB_RESULTS               ,   
		OD_PB_APPROVAL_STATUS       ,   
		OD_PB_QA_ENGR_EMAIL         ,   
		OD_PB_ATTACHMENT            ,   
		OD_PB_COMMENTS              ,   
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_FIRST_ARTICLE_INSPECTION',
                  '1', --1 for INSERT
               'OD_PB_RECORD_ID,OD_PB_SKU',
		OD_PB_SUPPLIER              ,   
		OD_PB_FACTORY_NAME          ,   
		OD_PB_SKU                   ,   
		OD_PB_DEPARTMENT            ,   
		OD_PB_PO_NUM                ,   
		OD_PB_DATE_OF_INSPECTON     ,   
		OD_PB_RESULTS               ,   
		OD_PB_APPROVAL_STATUS       ,   
		OD_PB_QA_ENGR_EMAIL         ,   
		OD_PB_ATTACHMENT            ,   
		OD_PB_COMMENTS              ,   
		d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_RECORD_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_FIRST_ARTICLE_INSPEC_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
commit;

   
   
