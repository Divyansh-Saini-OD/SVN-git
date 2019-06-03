INSERT INTO apps.Q_OD_PB_CUSTOMER_COMPLAINTS_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_CUSTOMER_COMPLAINT_ID       ,             
		OD_PB_CA_TYPE                     ,             
		OD_PB_QA_ENGR_EMAIL               ,             
		OD_PB_DATE_REPORTED               ,             
		OD_PB_DATE_OPENED                 ,             
		OD_PB_SKU                         ,             
		OD_PB_DEPARTMENT                  ,             
		OD_PB_ITEM_DESC                   ,             
		OD_PB_SUPPLIER                    ,             
		OD_PB_DEFECT_SUM                  ,             
		OD_PB_PRODUCT_ALERT               ,             
		OD_PB_SAMPLE_AVAILABLE            ,             
		OD_PB_DATE_SAMPLE_RECEIVED        ,             
		OD_PB_CA_NEEDED                   ,             
		OD_PB_CORRECTIVE_ACTION_ID        ,             
		OD_PB_ROOT_CAUSE_TYPE             ,             
		OD_PB_COMMENTS  	          ,                     
		OD_PB_DATE_CLOSED                 ,             
		OD_PB_POPT_CANDIDATE              ,             
	        qa_created_by_name	,
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id	
        )
SELECT          collection_id,
		occurrence,  
		'1000',
                'PRJ',
                'OD_PB_CUSTOMER_COMPLAINTS_HIST',
                '1000', 
		OD_PB_CUSTOMER_COMPLAINT_ID       ,             
		OD_PB_CA_TYPE                     ,             
		OD_PB_QA_ENGR_EMAIL               ,             
		TO_CHAR(OD_PB_DATE_REPORTED,'YYYY/MM/DD')               ,             
		TO_CHAR(OD_PB_DATE_OPENED,'YYYY/MM/DD')                 ,             
		OD_PB_SKU                         ,             
		OD_PB_DEPARTMENT                  ,             
		OD_PB_ITEM_DESC                   ,             
		OD_PB_SUPPLIER                    ,             
		OD_PB_DEFECT_SUM                  ,             
		OD_PB_PRODUCT_ALERT               ,             
		OD_PB_SAMPLE_AVAILABLE            ,             
		TO_CHAR(OD_PB_DATE_SAMPLE_RECEIVED,'YYYY/MM/DD')        ,             
		OD_PB_CA_NEEDED                   ,             
		OD_PB_CORRECTIVE_ACTION_ID        ,             
		OD_PB_ROOT_CAUSE_TYPE             ,             
		OD_PB_COMMENTS  	          ,                     
		OD_PB_DATE_CLOSED                 ,             
		OD_PB_POPT_CANDIDATE              ,             
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence,
		a.OD_PB_CUSTOMER_COMPLAINT_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_CUSTOMER_COMPLAINTS__V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name
   AND  a.OD_PB_CUSTOMER_COMPLAINT_ID NOT LIKE '%EU%';
commit;
