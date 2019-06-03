INSERT INTO apps.Q_OD_PB_WITHDRAW_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_SKU                    ,  
		OD_PB_ITEM_DESC              ,  
		OD_PB_SUPPLIER               ,  
		OD_PB_FACTORY_NAME           ,  
		OD_PB_DEFECT_SUM             ,  
		OD_PB_INVESTIGATION_ID       ,  
		OD_PB_WITHDRAWAL_DATE        ,  
		OD_PB_STORE_NOTICE           ,  
		OD_PB_COST_ASSOCIATED        ,  
		OD_PB_ATTACHMENT             ,  
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_WITHDRAW',
                  '1', --1 for INSERT
              'OD_PB_SKU,OD_PB_SUPPLIER,OD_PB_FACTORY_NAME',
		OD_PB_SKU                    ,  
		OD_PB_ITEM_DESC              ,  
		OD_PB_SUPPLIER               ,  
		OD_PB_FACTORY_NAME           ,  
		OD_PB_DEFECT_SUM             ,  
		OD_PB_INVESTIGATION_ID       ,  
		OD_PB_WITHDRAWAL_DATE        ,  
		OD_PB_STORE_NOTICE           ,  
		OD_PB_COST_ASSOCIATED        ,  
		OD_PB_ATTACHMENT             ,  
		d.user_name,
	          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_WITHDRAW_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
commit;

   
   
