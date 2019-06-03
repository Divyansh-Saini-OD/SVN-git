OPTIONS(SKIP=1)
LOAD DATA
APPEND
INTO TABLE xxmer.xx_gso_po_bv_stg
FIELDS TERMINATED BY "|"
OPTIONALLY ENCLOSED BY '"'
trailing nullcols
  ( 	po_number,
   	sku,
      final_book_entry_date  "to_date(:final_book_entry_date,'YYYY-MM-DD')",
      client_request_date  "to_date(:client_request_date,'YYYY-MM-DD')",
      inspection_date "to_date(:inspection_date,'YYYY-MM-DD')",  
      actual_qty,	      	
      inspection_no,
	inspection_result,	
	bv_status,
      vendor_name		,
	announced,		
      factory_name		,
	factory_address,	
	bv_book_date		"to_date(:bv_book_date,'YYYY-MM-DD')",
	bv_confirm_date		"to_date(:bv_confirm_date,'YYYY-MM-DD')",
	bv_service_date		"to_date(:bv_service_date,'YYYY-MM-DD')",
	invoice_date		"to_date(:invoice_date,'YYYY-MM-DD')",		
	invoice_no,			
	operation_office,
	OPRN_OFFICE_CNTRY,	
	INSP_SERV_TYPE,
	invoice_company,
	invoice_contact,
      creation_date "SYSDATE",
      process_flag "1"
)
