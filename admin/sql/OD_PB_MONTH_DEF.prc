INSERT INTO apps.Q_OD_PB_MONTHLY_DEFECT_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_TECH_RPT_NUM         ,    
		OD_PB_SKU                  ,    
		OD_PB_DATE_OF_INSPECTION   ,    
		OD_PB_FACTORY_NAME         ,    
		OD_PB_FAILURE              ,    
		SEVERITY_CODE              ,    
		OD_PB_SAMPLE_SIZE          ,    
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_MONTHLY_DEFECT',
                  '1', --1 for INSERT
              'OD_PB_TECH_RPT_NUM,OD_PB_SKU',
		OD_PB_TECH_RPT_NUM         ,    
		OD_PB_SKU                  ,    
		OD_PB_DATE_OF_INSPECTION   ,    
		OD_PB_FACTORY_NAME         ,    
		OD_PB_FAILURE              ,    
		SEVERITY_CODE              ,    
		OD_PB_SAMPLE_SIZE          ,    
	          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_MONTHLY_DEFECT_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
commit;
