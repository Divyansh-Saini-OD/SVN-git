INSERT INTO apps.Q_OD_PB_RETURNED_GOODS_ANAL_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_DATE_REPORTED     ,               
		OD_PB_STORE_NUMBER       ,              
		OD_PB_SKU                 ,             
		OD_PB_DEPARTMENT          ,             
		OD_PB_QA_ENGINEER         ,             
		OD_PB_COMMENTS            ,             
		OD_PB_ENGINEER_FINDINGS   ,             
		OD_PB_SAMPLE_DISPOSITION  ,             
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_RETURNED_GOODS_ANALYSIS',
                  '1', --1 for INSERT
              'OD_PB_SAMPLE_NUMBER,OD_PB_SKU',
		OD_PB_DATE_REPORTED     ,               
		OD_PB_STORE_NUMBER       ,              
		OD_PB_SKU                 ,             
		OD_PB_DEPARTMENT          ,             
		OD_PB_QA_ENGINEER         ,             
		OD_PB_COMMENTS            ,             
		OD_PB_ENGINEER_FINDINGS   ,             
		OD_PB_SAMPLE_DISPOSITION  ,             
		d.user_name,
	          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_SAMPLE_NUMBER    
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_RETURNED_GOODS_ANALY_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
commit;

   
   
