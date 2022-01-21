---+================================================================================+
---|                      Office Depot - Project Simplify                           |
---|                                Oracle                                          |
---+================================================================================+
---|    Application             :       OM                                          |
---|    Name                    :       XX_OM_ORDER_ERRORS_V.vw                     |
---|    Description             :                                                   |
---|                                                                                |
---|    Version         DATE              AUTHOR             DESCRIPTION            |
---|    ------------    ----------------- ---------------    ---------------------  |
---|    1.0             14-Aug-2020       Atul K             Initial Version        |
---+================================================================================+
create or replace view XX_OM_ORDER_ERRORS_V
as
(SELECT ORIG_SYS_DOCUMENT_REF 				ORIG_SYS_DOCUMENT_REF,
		WEEK_OF_MONTH							WEEK_OF_MONTH,
		CREATION_DATE 							CREATION_DATE,
		ORDER_TOTAL 							ORDER_TOTAL,
		NVL(SOLD_TO_ORG,
		(SELECT orig_system_reference
		FROM apps.hz_cust_accounts hca
		WHERE sold_to_org_id = hca.cust_account_id
		)) 										SOLD_TO_ORG ,
		SOLD_TO_ORG_ID 							SOLD_TO_ORG_ID,
		NVL(SHIP_TO_ORG,
		(SELECT orig_system_reference
		FROM APPS.HZ_CUST_SITE_USES_ALL hcsu
		WHERE SHIP_to_org_id = HCSU.SITE_USE_ID
		)) 										SHIP_TO_ORG ,
		SHIP_TO_ORG_ID 							SHIP_TO_ORG_ID,
		NVL(INVOICE_TO_ORG,
		(SELECT orig_system_reference
		FROM APPS.HZ_CUST_SITE_USES_ALL hcsu
		WHERE INVOICE_to_org_id = HCSU.SITE_USE_ID
		)) 										INVOICE_TO_ORG ,
		INVOICE_TO_ORG_ID						INVOICE_TO_ORG_ID,
		SOLD_TO_CONTACT							SOLD_TO_CONTACT,
		SOLD_TO_CONTACT_ID						SOLD_TO_CONTACT_ID,
		SUM(Account_not_created) 				Account_not_created,
		SUM(Account_Inactive) 					Account_Inactive,
		SUM(ship_to_not_created) 				ship_to_not_created,
		SUM(ship_to_Inactive) 					ship_to_Inactive,
		SUM(Bill_to_not_created) 				Bill_to_not_created,
		SUM(Bill_to_Inactive) 					Bill_to_Inactive,
		SUM(sold_to_contact_not_created)		sold_to_contact_not_created,
		SUM(SOLD_TO_CONTACT_INACTIVE) 			SOLD_TO_CONTACT_INACTIVE,
		SUM(Order_type_error)               	Order_type_error,
		SUM(deposit_prepayment_issue) 			deposit_prepayment_issue,
		SUM(Invalid_UOM) 						Invalid_UOM,
		SUM(RAC_REASON_MISSING) 				RAC_REASON_MISSING,
		SUM(Customer_ref_missing_SPC) 			Customer_ref_missing_SPC,
		SUM(Item_not_created)               	Item_not_created,
		SUM(Item_not_assigned) 					Item_not_assigned,
		SUM(Amount_not_matching) 				Amount_not_matching,
		SUM(Failed_for_receipt_meth) 			Failed_for_receipt_meth,
		SUM(Shipping_method_issue) 				Shipping_method_issue,
		SUM(Other_errors)                   	Other_errors,
		SUM(no_error_msg_record) 				no_error_msg_record,
			(SUM(Account_not_created)+
			SUM(Account_Inactive)+
			SUM(ship_to_not_created)+
			SUM(ship_to_Inactive)+
			SUM(Bill_to_not_created)+
			SUM(Bill_to_Inactive)+
			SUM(sold_to_contact_not_created)+
			SUM(SOLD_TO_CONTACT_INACTIVE)+
			SUM(Order_type_error)+
			SUM(deposit_prepayment_issue)+
			SUM(Invalid_UOM)+
			SUM(RAC_REASON_MISSING)+
			SUM(Customer_ref_missing_SPC)+
			SUM(Item_not_created)+
			SUM(Item_not_assigned)+
			SUM(Amount_not_matching)+
			SUM(Failed_for_receipt_meth)+
			SUM(Shipping_method_issue)+
			SUM(Other_errors)+
			SUM(no_error_msg_record)) 			TOTAL_ERRORS
	FROM
		(SELECT DISTINCT orig_sys_document_ref,
			TO_CHAR(creation_date, 'W-MON') Week_of_Month,
			creation_date,
			order_total,
			imp_file_name,
			error_flag,
			order_source_id,
			payment_term_id,
			payment_term,
			sold_to_org,
			sold_to_org_id,
			ship_to_org,
			ship_to_org_id,
			invoice_to_org,
			invoice_to_org_id,
			sold_to_contact,
			sold_to_contact_id,
			(
			CASE
			WHEN MESSAGE_TEXT LIKE '10000010: Failed to Derive Customer Account%'
			OR MESSAGE_TEXT LIKE 'Invalid Customer ID %CUSTOMER_ID .'
			OR MESSAGE_TEXT = 'Cannot get valid ID for - sold_to_org_id'
			THEN 1
			ELSE 0
			END) account_not_created,
			(
			CASE
			WHEN MESSAGE_TEXT LIKE 'Validation failed for the field%Customer'
			THEN 1
			ELSE 0
			END) Account_Inactive,
			(
			CASE
			WHEN MESSAGE_TEXT LIKE '10000016: Failed to Derive Ship to%'
			OR MESSAGE_TEXT = 'Cannot get valid ID for - ship_to_org_id'
			THEN 1
			ELSE 0
			END) ship_to_not_created,
			(
			CASE
			WHEN MESSAGE_TEXT = 'Validation failed for the field - Ship To'
			THEN 1
			ELSE 0
			END) ship_to_Inactive,
			(
			CASE
			WHEN MESSAGE_TEXT LIKE '10000021: No BillTo Address  found%'
			THEN 1
			ELSE 0
			END) Bill_to_not_created,
			(
			CASE
			WHEN MESSAGE_TEXT = 'Validation failed for the field - Bill To'
			THEN 1
			ELSE 0
			END) Bill_to_Inactive,
			(
			CASE
			WHEN MESSAGE_TEXT = 'Cannot get valid ID for - sold_to_contact_id'
			THEN 1
			ELSE 0
			END) sold_to_contact_not_created,
			(
			CASE
			WHEN MESSAGE_TEXT = 'Validation failed for the field - Contact'
			THEN 1
			ELSE 0
			END) SOLD_TO_CONTACT_INACTIVE,
			(
			CASE
			WHEN MESSAGE_TEXT = 'Validation failed for the field - Order Type'
			THEN 1
			ELSE 0
			END) Order_type_error,        
			(
			CASE
			WHEN MESSAGE_TEXT LIKE '10000030: reapply_deposit_prepayment did not return Payment set id%'
			THEN 1
			ELSE 0
			END) deposit_prepayment_issue,
			(
			CASE
			WHEN MESSAGE_TEXT = 'Invalid unit of measure for this item.'
			THEN 1
			ELSE 0
			END) Invalid_UOM,
			(
			CASE
			WHEN MESSAGE_TEXT = '10000030: Return Action Category Reason is a required attribute. Please specify a value.'
			THEN 1
			ELSE 0
			END) RAC_REASON_MISSING,
			(
			CASE
			WHEN MESSAGE_TEXT = '10000002: Customer reference is missing for SPC card or PRO card order.'
			THEN 1
			ELSE 0
			END) Customer_ref_missing_SPC,
			(
			CASE
			WHEN MESSAGE_TEXT LIKE '10000017: Failed to Derive SKU for%Create Item in EBS%'
		THEN 1
			ELSE 0
			END) Item_not_created,
			(
			CASE
			WHEN MESSAGE_TEXT LIKE '10000018: Item%not Assigned to Warehouse%Assign Item to Warehouse%'
			THEN 1
			ELSE 0
			END) Item_not_assigned,
			(
			CASE
			WHEN MESSAGE_TEXT LIKE '10000026: Payment Amount Total Payment Amount%Match Order Total Total Order Amount%'
			THEN 1
			ELSE 0
			END) Amount_not_matching,
			(
			CASE
			WHEN MESSAGE_TEXT LIKE '10000024: Failed to Derive Receipt Method%Assign right Receipt Method%'
			THEN 1
			ELSE 0
			END) Failed_for_receipt_meth,
			(
			CASE
			WHEN MESSAGE_TEXT LIKE '10000025: No shipping method is setup for this delivery method%'
			THEN 1
			ELSE 0
			END) Shipping_method_issue,
			(
			CASE
			WHEN MESSAGE_TEXT LIKE 'ORA-%'
			THEN 1
			ELSE 0
			END) Other_errors,
			(
			CASE
			WHEN MESSAGE_TEXT = 'ERROR RECORD DOES NOT EXIST'
			THEN 1
			ELSE 0
			END) no_error_msg_record
		FROM
			(SELECT DISTINCT iface.orig_sys_document_ref,
				iface.creation_date,
				hai.order_total,
				nvl(hai.imp_file_name,nvl(hai.orig_sys_document_ref,'RECORD DOES NOT EXIST IN HEADER ATTR IFACE')) imp_file_name,
				iface.error_flag,
				iface.order_source_id,
				iface.payment_term_id,
				iface.payment_term,
				iface.sold_to_org,
				iface.sold_to_org_id,
				iface.ship_to_org,
				iface.ship_to_org_id,
				iface.invoice_to_org,
				iface.invoice_to_org_id,
				iface.sold_to_contact,
				iface.sold_to_contact_id,
				nvl(msg.message_text,nvl(tl.message_text,'ERROR RECORD DOES NOT EXIST')) message_text
			FROM apps.oe_headers_iface_all iface,
				apps.oe_processing_msgs msg,
				apps.oe_processing_msgs_tl tl,
				APPS.XX_OM_HEADERS_ATTR_IFACE_ALL hai
			WHERE 1                         = 1
			AND iface.orig_sys_document_ref = msg.original_sys_document_ref(+)
			AND iface.orig_sys_document_ref = hai.orig_sys_document_ref
			AND iface.order_source_id       = msg.order_source_id(+)
			and msg.transaction_id 		    = tl.transaction_id(+)
			--AND TRUNC(IFACE.CREATION_DATE) <= sysdate
		) main
	)
	GROUP BY ORIG_SYS_DOCUMENT_REF ,
		WEEK_OF_MONTH,
		CREATION_DATE,
		ORDER_TOTAL ,
		SOLD_TO_ORG ,
		SOLD_TO_ORG_ID,
		SHIP_TO_ORG,
		SHIP_TO_ORG_ID,
		INVOICE_TO_ORG,
		INVOICE_TO_ORG_ID,
		SOLD_TO_CONTACT,
		SOLD_TO_CONTACT_ID);