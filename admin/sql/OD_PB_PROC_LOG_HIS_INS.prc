INSERT INTO apps.Q_OD_PB_PROCEDURES_LOG_HIST_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_COLLECTION_PLANS,
		OD_PB_ATTACHMENT               ,
		OD_PB_QA_APPROVER                  ,      
		ENTERED_BY_USER,
	        qa_created_by_name	,
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id	
        )
SELECT          collection_id,
		occurrence,  
		'1000',
                'PRJ',
                'OD_PB_PROCEDURES_LOG_HISTORY',
                '1000', 
		OD_PB_COLLECTION_PLANS,
		OD_PB_ATTACHMENT               ,
		OD_PB_QA_APPROVER                  ,      
		ENTERED_BY_USER,                          
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_PROCEDURES_LOG_HISTO_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
commit;
