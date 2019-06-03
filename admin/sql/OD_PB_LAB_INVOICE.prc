INSERT INTO apps.Q_OD_PB_LAB_INVOICING_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_PROGRAM_TEST_TYPE,
		OD_PB_TECH_RPT_NUM   ,                  
		OD_PB_DATE_INVOICED   ,                 
		OD_PB_AMOUNT           ,                
		OD_PB_PAID_BY           ,               
		OD_PB_COUNTRY_DESTINATION,              
		OD_PB_INVOICE_NUM        ,              
		OD_PB_PAYEE              ,              
		OD_PB_LAB_LOCATION       ,              
		OD_PB_SUPPLIER           ,              
		OD_PB_VENDOR_ID          ,              
		OD_PB_PO_NUM             ,              
		OD_PB_MAN_DAYS           ,              
		OD_PB_INSP_FEE           ,              
		OD_PB_ACCOM_EXPENSE      ,              
		OD_PB_TRAVEL_EXPENSE     ,              
		OD_PB_FLIGHT_EXPENSE     ,              
		OD_PB_EXTRA_EXPENSE      ,              
		OD_PB_COMMENTS           ,              
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_LAB_INVOICING',
                  '1', --1 for INSERT
              'OD_PB_PROGRAM_TEST_TYPE,OD_PB_TECH_RPT_NUM',
		OD_PB_PROGRAM_TEST_TYPE,
		OD_PB_TECH_RPT_NUM   ,                  
		OD_PB_DATE_INVOICED   ,                 
		OD_PB_AMOUNT           ,                
		OD_PB_PAID_BY           ,               
		OD_PB_COUNTRY_DESTINATION,              
		OD_PB_INVOICE_NUM        ,              
		OD_PB_PAYEE              ,              
		OD_PB_LAB_LOCATION       ,              
		OD_PB_SUPPLIER           ,              
		OD_PB_VENDOR_ID          ,              
		OD_PB_PO_NUM             ,              
		OD_PB_MAN_DAYS           ,              
		OD_PB_INSP_FEE           ,              
		OD_PB_ACCOM_EXPENSE      ,              
		OD_PB_TRAVEL_EXPENSE     ,              
		OD_PB_FLIGHT_EXPENSE     ,              
		OD_PB_EXTRA_EXPENSE      ,              
		OD_PB_COMMENTS           ,              
	          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_LAB_INVOICING_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
commit;

   
   
