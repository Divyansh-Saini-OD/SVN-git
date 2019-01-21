CREATE OR REPLACE FORCE VIEW APPS.PO_HEADERS_XML ("TYPE_LOOKUP_CODE", "SEGMENT1", "REVISION_NUM", "PRINT_COUNT", "CREATION_DATE", "PRINTED_DATE", "REVISED_DATE", "START_DATE", "END_DATE", "NOTE_TO_VENDOR", "DOCUMENT_BUYER_FIRST_NAME", "DOCUMENT_BUYER_LAST_NAME", "DOCUMENT_BUYER_TITLE", "DOCUMENT_BUYER_AGENT_ID", "ARCHIVE_BUYER_AGENT_ID", "ARCHIVE_BUYER_FIRST_NAME", "ARCHIVE_BUYER_LAST_NAME", "ARCHIVE_BUYER_TITLE", "AMOUNT_AGREED", "CANCEL_FLAG", "CONFIRMING_ORDER_FLAG", "ACCEPTANCE_REQUIRED_FLAG", "ACCEPTANCE_DUE_DATE", "CURRENCY_CODE", "CURRENCY_NAME", "RATE", "SHIP_VIA", "FOB", "FREIGHT_TERMS", "PAYMENT_TERMS", "CUSTOMER_NUM", "VENDOR_NUM", "VENDOR_NAME", "VENDOR_ADDRESS_LINE1", "VENDOR_ADDRESS_LINE2", "VENDOR_ADDRESS_LINE3", "VENDOR_CITY", "VENDOR_STATE", "VENDOR_POSTAL_CODE", "VENDOR_COUNTRY", "VENDOR_PHONE", "VENDOR_CONTACT_FIRST_NAME", "VENDOR_CONTACT_LAST_NAME", "VENDOR_CONTACT_TITLE", "VENDOR_CONTACT_PHONE", "SHIP_TO_LOCATION_ID", "SHIP_TO_LOCATION_NAME",
  "SHIP_TO_ADDRESS_LINE1", "SHIP_TO_ADDRESS_LINE2", "SHIP_TO_ADDRESS_LINE3", "SHIP_TO_ADDRESS_LINE4", "SHIP_TO_ADDRESS_INFO", "SHIP_TO_COUNTRY", "SHIP_TO_TOWNORCITY", "SHIP_TO_STATEORPROVINCE", "SHIP_TO_POSTALCODE", "BILL_TO_LOCATION_ID", "BILL_TO_LOCATION_NAME", "BILL_TO_ADDRESS_LINE1", "BILL_TO_ADDRESS_LINE2", "BILL_TO_ADDRESS_LINE3", "BILL_TO_ADDRESS_LINE4", "BILL_TO_ADDRESS_INFO", "BILL_TO_COUNTRY", "BILL_TO_TOWNORCITY", "BILL_TO_STATEORPROVINCE", "BILL_TO_POSTALCODE", "ATTRIBUTE1", "ATTRIBUTE2", "ATTRIBUTE3", "ATTRIBUTE4", "ATTRIBUTE5", "ATTRIBUTE6", "ATTRIBUTE7", "ATTRIBUTE8", "ATTRIBUTE9", "ATTRIBUTE10", "ATTRIBUTE11", "ATTRIBUTE12", "ATTRIBUTE13", "ATTRIBUTE14", "ATTRIBUTE15", "VENDOR_SITE_ID", "PO_HEADER_ID", "APPROVED_FLAG", "LANGUAGE", "VENDOR_ID", "CLOSED_CODE", "USSGL_TRANSACTION_CODE", "GOVERNMENT_CONTEXT", "REQUEST_ID", "PROGRAM_APPLICATION_ID", "PROGRAM_ID", "PROGRAM_UPDATE_DATE", "ORG_ID", "COMMENTS", "REPLY_DATE", "REPLY_METHOD_LOOKUP_CODE", "RFQ_CLOSE_DATE",
  "QUOTE_TYPE_LOOKUP_CODE", "QUOTATION_CLASS_CODE", "QUOTE_WARNING_DELAY_UNIT", "QUOTE_WARNING_DELAY", "QUOTE_VENDOR_QUOTE_NUMBER", "CLOSED_DATE", "USER_HOLD_FLAG", "APPROVAL_REQUIRED_FLAG", "FIRM_STATUS_LOOKUP_CODE", "FIRM_DATE", "FROZEN_FLAG", "EDI_PROCESSED_FLAG", "EDI_PROCESSED_STATUS", "ATTRIBUTE_CATEGORY", "CREATED_BY", "VENDOR_CONTACT_ID", "TERMS_ID", "FOB_LOOKUP_CODE", "FREIGHT_TERMS_LOOKUP_CODE", "STATUS_LOOKUP_CODE", "RATE_TYPE", "RATE_DATE", "FROM_HEADER_ID", "FROM_TYPE_LOOKUP_CODE", "AUTHORIZATION_STATUS", "APPROVED_DATE", "AMOUNT_LIMIT", "MIN_RELEASE_AMOUNT", "NOTE_TO_AUTHORIZER", "NOTE_TO_RECEIVER", "VENDOR_ORDER_NUM", "LAST_UPDATE_DATE", "LAST_UPDATED_BY", "SUMMARY_FLAG", "ENABLED_FLAG", "SEGMENT2", "SEGMENT3", "SEGMENT4", "SEGMENT5", "START_DATE_ACTIVE", "END_DATE_ACTIVE", "LAST_UPDATE_LOGIN", "SUPPLY_AGREEMENT_FLAG", "GLOBAL_ATTRIBUTE_CATEGORY", "GLOBAL_ATTRIBUTE1", "GLOBAL_ATTRIBUTE2", "GLOBAL_ATTRIBUTE3", "GLOBAL_ATTRIBUTE4", "GLOBAL_ATTRIBUTE5",
  "GLOBAL_ATTRIBUTE6", "GLOBAL_ATTRIBUTE7", "GLOBAL_ATTRIBUTE8", "GLOBAL_ATTRIBUTE9", "GLOBAL_ATTRIBUTE10", "GLOBAL_ATTRIBUTE11", "GLOBAL_ATTRIBUTE12", "GLOBAL_ATTRIBUTE13", "GLOBAL_ATTRIBUTE14", "GLOBAL_ATTRIBUTE15", "GLOBAL_ATTRIBUTE16", "GLOBAL_ATTRIBUTE17", "GLOBAL_ATTRIBUTE18", "GLOBAL_ATTRIBUTE19", "GLOBAL_ATTRIBUTE20", "INTERFACE_SOURCE_CODE", "REFERENCE_NUM", "WF_ITEM_TYPE", "WF_ITEM_KEY", "PCARD_ID", "PRICE_UPDATE_TOLERANCE", "MRC_RATE_TYPE", "MRC_RATE_DATE", "MRC_RATE", "PAY_ON_CODE", "XML_FLAG", "XML_SEND_DATE", "XML_CHANGE_SEND_DATE", "GLOBAL_AGREEMENT_FLAG", "CONSIGNED_CONSUMPTION_FLAG", "CBC_ACCOUNTING_DATE", "CONSUME_REQ_DEMAND_FLAG", "CHANGE_REQUESTED_BY", "SHIPPING_CONTROL", "CONTERMS_EXIST_FLAG", "CONTERMS_ARTICLES_UPD_DATE", "CONTERMS_DELIV_UPD_DATE", "PENDING_SIGNATURE_FLAG", "OU_NAME", "OU_ADDR1", "OU_ADDR2", "OU_ADDR3", "OU_TOWN_CITY", "OU_REGION2", "OU_POSTALCODE", "OU_COUNTRY", "BUYER_LOCATION_ID", "BUYER_ADDRESS_LINE1", "BUYER_ADDRESS_LINE2",
  "BUYER_ADDRESS_LINE3", "BUYER_ADDRESS_LINE4", "BUYER_CITY_STATE_ZIP", "BUYER_CONTACT_PHONE", "BUYER_CONTACT_EMAIL", "BUYER_CONTACT_FAX", "VENDOR_FAX", "SUPPLIER_NOTIF_METHOD", "VENDOR_EMAIL", "TOTAL_AMOUNT", "BUYER_COUNTRY", "VENDOR_ADDRESS_LINE4", "VENDOR_AREA_CODE", "VENDOR_CONTACT_AREA_CODE", "LE_NAME", "LE_ADDR1", "LE_ADDR2", "LE_ADDR3", "LE_TOWN_CITY", "LE_STAE_PROVINCE", "LE_POSTALCODE", "LE_COUNTRY", "CANCEL_DATE", "CHANGE_SUMMARY", "DOCUMENT_CREATION_METHOD", "ENCUMBRANCE_REQUIRED_FLAG", "STYLE_DISPLAY_NAME", "VENDOR_FAX_AREA_CODE", "PLANNER", "PLANNER_EMAIL", "PLANNER_PHONE", "REVISED_BY", "REVISED_BY_EMAIL", "REVISED_BY_PHONE_NUMBER", "SUPPLIER_SITE_NAME", "MFG_NAME", "MFG_ADDRESS_LINE1", "MFG_ADDRESS_LINE2", "MFG_ADDRESS_LINE3", "MFG_CITY", "MFG_STATE", "MFG_POSTAL_CODE", "MFG_COUNTRY", "SHIP_VIA_LOOKUP_CODE", "PO_TYPE", "TOTAL_AMOUNT_MINUS_TAX", "TOTAL_TAX", "TOTAL_AMOUNT_WITH_TAX", "TERMS_CONDITIONS", "DROP_SHIP_ADDRESS1", "DROP_SHIP_ADDRESS2", "DROP_SHIP_ADDRESS3",
  "DROP_SHIP_ADDRESS4", "DROP_SHIP_ADDRESS5", "DROP_SHIP_LOCATION", "HEADER_SHORT_TEXT", "RELEASED_AMOUNT", "SHIP_FROM_PORT", "LEGACY_SUPPLIER_NUM", "SHIP_SEE_BELOW")
AS
SELECT ph.type_lookup_code, ph.segment1, ph.revision_num, ph.print_count,
			   TO_CHAR (ph.creation_date, 'DD-MON-YYYY HH24:MI:SS') creation_date,
			   ph.printed_date,
			   TO_CHAR (ph.revised_date, 'DD-MON-YYYY HH24:MI:SS') revised_date,
			   TO_CHAR (ph.start_date, 'DD-MON-YYYY HH24:MI:SS') start_date,
			   TO_CHAR (ph.end_date, 'DD-MON-YYYY HH24:MI:SS') end_date,
			   ph.note_to_vendor, hre.first_name document_buyer_first_name,
			   hre.last_name document_buyer_last_name,
			  --hrl.meaning document_buyer_title,
			  hre.title document_buyer_title,
			   ph.agent_id document_buyer_agent_id,
			   DECODE
				  (NVL (ph.revision_num, 0),
				   0, NULL,
				   po_communication_pvt.getarcbuyeragentid (ph.po_header_id)
				  ) archive_buyer_agent_id,
			   DECODE
				   (NVL (ph.revision_num, 0),
					0, NULL,
					po_communication_pvt.getarcbuyerfname ()
				   ) archive_buyer_first_name,
			   DECODE
					(NVL (ph.revision_num, 0),
					 0, NULL,
					 po_communication_pvt.getarcbuyerlname ()
					) archive_buyer_last_name,
			   DECODE (NVL (ph.revision_num, 0),
					   0, NULL,
					   po_communication_pvt.getarcbuyertitle ()
					  ) archive_buyer_title,
			   TO_CHAR (NVL (ph.blanket_total_amount, ''),
						po_communication_pvt.getformatmask
					   ) amount_agreed,
			   NVL (ph.cancel_flag, 'N'), ph.confirming_order_flag,
			   NVL (ph.acceptance_required_flag, 'N'),
			   TO_CHAR (ph.acceptance_due_date,
						'DD-MON-YYYY HH24:MI:SS'
					   ) acceptance_due_date,
			   fcc.currency_code, fcc.NAME currency_name,
			   TO_CHAR (ph.rate, po_communication_pvt.getformatmask) rate,
			   NVL (ofc.freight_code_tl, ph.ship_via_lookup_code) ship_via,
			   plc1.meaning fob, plc2.meaning freight_terms, t.NAME payment_terms,
			   NVL (assa.customer_num, vn.customer_num) customer_num,
			   vn.segment1 vendor_num, vn.vendor_name,
			   hl.address1 vendor_address_line1, hl.address2 vendor_address_line2,
			   hl.address3 vendor_address_line3, hl.city vendor_city,
			   DECODE (hl.state,
					   NULL, DECODE (hl.province, NULL, hl.county, hl.province),
					   hl.state
					  ) vendor_state,
			   SUBSTR (hl.postal_code, 1, 20) vendor_postal_code,
			   fte3.territory_short_name vendor_country, assa.phone vendor_phone,
			   asca.first_name vendor_contact_first_name,
			   asca.last_name vendor_contact_last_name,
			   --plc4.meaning vendor_contact_title,
			   --pvc.phone vendor_contact_phone,
			   asca.prefix vendor_contact_title,
			   asca.phone vendor_contact_phone,
			   DECODE
				  (NVL (ph.ship_to_location_id, -1),
				   -1, NULL,
				   po_communication_pvt.getlocationinfo (ph.ship_to_location_id)
				  ) ship_to_location_id,
			   DECODE (NVL (ph.ship_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getlocationname ()
					  ) ship_to_location_name,
			   DECODE (NVL (ph.ship_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getaddressline1 ()
					  ) ship_to_address_line1,
			   DECODE (NVL (ph.ship_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getaddressline2 ()
					  ) ship_to_address_line2,
			   DECODE (NVL (ph.ship_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getaddressline3 ()
					  ) ship_to_address_line3,
			   DECODE (NVL (ph.ship_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getaddressline4 ()
					  ) ship_to_address_line4,
			   DECODE (NVL (ph.ship_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getaddressinfo ()
					  ) ship_to_address_info,
			   DECODE (NVL (ph.ship_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getterritoryshortname ()
					  ) ship_to_country,
			   --Added for R12 Upgrade Retrofit
			   DECODE (NVL (ph.ship_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.gettownorcity ()
					  ) ship_to_townorcity,
			   DECODE
				  (NVL (ph.ship_to_location_id, -1),
				   -1, NULL,
				   po_communication_pvt.getstateorprovince ()
				  ) ship_to_stateorprovince,
			   DECODE (NVL (ph.ship_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getpostalcode ()
					  ) ship_to_postalcode,
			   --end
			   DECODE
				  (NVL (ph.bill_to_location_id, -1),
				   -1, NULL,
				   po_communication_pvt.getlocationinfo (ph.bill_to_location_id)
				  ) bill_to_location_id,
			   DECODE (NVL (ph.ship_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getlocationname ()
					  ) bill_to_location_name,
			   DECODE (NVL (ph.bill_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getaddressline1 ()
					  ) bill_to_address_line1,
			   DECODE (NVL (ph.bill_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getaddressline2 ()
					  ) bill_to_address_line2,
			   DECODE (NVL (ph.bill_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getaddressline3 ()
					  ) bill_to_address_line3,
			   DECODE (NVL (ph.bill_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getaddressline4 ()
					  ) bill_to_address_line4,
			   DECODE (NVL (ph.bill_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getaddressinfo ()
					  ) bill_to_address_info,
			   DECODE (NVL (ph.bill_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getterritoryshortname ()
					  ) bill_to_country,
			   --Added for R12 Upgrade Retrofit
			   DECODE (NVL (ph.bill_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.gettownorcity ()
					  ) bill_to_townorcity,
			   DECODE
				  (NVL (ph.bill_to_location_id, -1),
				   -1, NULL,
				   po_communication_pvt.getstateorprovince ()
				  ) bill_to_stateorprovince,
			   DECODE (NVL (ph.bill_to_location_id, -1),
					   -1, NULL,
					   po_communication_pvt.getpostalcode ()
					  ) bill_to_postalcode,
			   --end
			   ph.attribute1,
			   --ph.attribute2,  --Commented and added for Defect#26317
			   (SELECT   SUM (NVL (pda.nonrecoverable_tax, 0))
					   + SUM (NVL (pda.recoverable_tax, 0))
				  FROM po_distributions_all pda
				 WHERE ph.po_header_id = pda.po_header_id) attribute2,
			   ph.attribute3, ph.attribute4, ph.attribute5, ph.attribute6,
			   ph.attribute7, ph.attribute8, ph.attribute9, ph.attribute10,
			   ph.attribute11, ph.attribute12, ph.attribute13, ph.attribute14,
			   ph.attribute15, ph.vendor_site_id, ph.po_header_id,
			   DECODE (ph.approved_flag, 'Y', 'Y', 'N') approved_flag, assa.LANGUAGE,
			   ph.vendor_id, ph.closed_code, ph.ussgl_transaction_code,
			   ph.government_context, ph.request_id, ph.program_application_id,
			   ph.program_id, ph.program_update_date, ph.org_id, ph.comments,
			   TO_CHAR (ph.reply_date, 'DD-MON-YYYY HH24:MI:SS') reply_date,
			   ph.reply_method_lookup_code,
			   TO_CHAR (ph.rfq_close_date, 'DD-MON-YYYY HH24:MI:SS') rfq_close_date,
			   ph.quote_type_lookup_code, ph.quotation_class_code,
			   ph.quote_warning_delay_unit, ph.quote_warning_delay,
			   ph.quote_vendor_quote_number,
			   TO_CHAR (ph.closed_date, 'DD-MON-YYYY HH24:MI:SS') closed_date,
			   ph.user_hold_flag, ph.approval_required_flag,
			   ph.firm_status_lookup_code,
			   TO_CHAR (ph.firm_date, 'DD-MON-YYYY HH24:MI:SS') firm_date,
			   ph.frozen_flag, ph.edi_processed_flag, ph.edi_processed_status,
			   ph.attribute_category, ph.created_by, ph.vendor_contact_id,
			   ph.terms_id, ph.fob_lookup_code, ph.freight_terms_lookup_code,
			   ph.status_lookup_code, ph.rate_type,
			   TO_CHAR (ph.rate_date, 'DD-MON-YYYY HH24:MI:SS') rate_date,
			   ph.from_header_id, ph.from_type_lookup_code,
			   NVL (ph.authorization_status, 'N') authorization_status,
			   TO_CHAR (ph.approved_date, 'DD-MON-YYYY HH24:MI:SS') approved_date,
			   TO_CHAR (ph.amount_limit,
						po_communication_pvt.getformatmask
					   ) amount_limit,
			   TO_CHAR (ph.min_release_amount,
						po_communication_pvt.getformatmask
					   ) min_release_amount,
			   ph.note_to_authorizer, ph.note_to_receiver, ph.vendor_order_num,
			   TO_CHAR (ph.last_update_date,
						'DD-MON-YYYY HH24:MI:SS'
					   ) last_update_date,
			   ph.last_updated_by, ph.summary_flag, ph.enabled_flag, ph.segment2,
			   ph.segment3, ph.segment4, ph.segment5,
			   TO_CHAR (ph.start_date_active,
						'DD-MON-YYYY HH24:MI:SS'
					   ) start_date_active,
			   TO_CHAR (ph.end_date_active, 'DD-MON-YYYY HH24:MI:SS') end_date_active,
			   ph.last_update_login, ph.supply_agreement_flag,
			   ph.global_attribute_category, ph.global_attribute1,
			   ph.global_attribute2, ph.global_attribute3, ph.global_attribute4,
			   ph.global_attribute5, ph.global_attribute6, ph.global_attribute7,
			   ph.global_attribute8, ph.global_attribute9, ph.global_attribute10,
			   ph.global_attribute11, ph.global_attribute12, ph.global_attribute13,
			   ph.global_attribute14, ph.global_attribute15, ph.global_attribute16,
			   ph.global_attribute17, ph.global_attribute18, ph.global_attribute19,
			   ph.global_attribute20, ph.interface_source_code, ph.reference_num,
			   ph.wf_item_type, ph.wf_item_key, ph.pcard_id,
			   ph.price_update_tolerance, ph.mrc_rate_type, ph.mrc_rate_date,
			   ph.mrc_rate, ph.pay_on_code, ph.xml_flag,
			   TO_CHAR (ph.xml_send_date, 'DD-MON-YYYY HH24:MI:SS') xml_send_date,
			   TO_CHAR (ph.xml_change_send_date,
						'DD-MON-YYYY HH24:MI:SS'
					   ) xml_change_send_date,
			   ph.global_agreement_flag, ph.consigned_consumption_flag,
			   TO_CHAR (ph.cbc_accounting_date,
						'DD-MON-YYYY HH24:MI:SS'
					   ) cbc_accounting_date,
			   ph.consume_req_demand_flag, ph.change_requested_by,
			   plc3.meaning shipping_control, ph.conterms_exist_flag,
			   TO_CHAR (ph.conterms_articles_upd_date,
						'DD-MON-YYYY HH24:MI:SS'
					   ) conterms_articles_upd_date,
			   TO_CHAR (ph.conterms_deliv_upd_date,
						'DD-MON-YYYY HH24:MI:SS'
					   ) conterms_deliv_upd_date,
			   NVL (ph.pending_signature_flag, 'N'),
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getoperationinfo (ph.org_id)
					  ) ou_name,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getouaddressline1 ()
					  ) ou_addr1,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getouaddressline2 ()
					  ) ou_addr2,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getouaddressline3 ()
					  ) ou_addr3,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getoutowncity ()
					  ) ou_town_city,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getouregion2 ()
					  ) ou_region2,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getoupostalcode ()
					  ) ou_postalcode,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getoucountry ()
					  ) ou_country,
			   po_communication_pvt.getlocationinfo (pa.location_id)
																	buyer_location_id,
			   po_communication_pvt.getaddressline1 () buyer_address_line1,
			   po_communication_pvt.getaddressline2 () buyer_address_line2,
			   po_communication_pvt.getaddressline3 () buyer_address_line3,
			   po_communication_pvt.getaddressline4 () buyer_address_line4,
			   po_communication_pvt.getaddressinfo () buyer_city_state_zip,
			   po_communication_pvt.getphone (pa.agent_id) buyer_contact_phone,
			   po_communication_pvt.getemail () buyer_contact_email,
			   po_communication_pvt.getfax () buyer_contact_fax, assa.fax vendor_fax,
			   assa.supplier_notif_method supplier_notif_method,
			   assa.email_address vendor_email,
			   TO_CHAR (DECODE (ph.type_lookup_code,
								'STANDARD', po_core_s.get_total ('H', ph.po_header_id),
								NULL
							   ),
						po_communication_pvt.getformatmask
					   ) total_amount,
			   po_communication_pvt.getterritoryshortname () buyer_country,
			   hl.address4 vendor_address_line4, assa.area_code vendor_area_code,
			   asca.area_code vendor_contact_area_code,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getlegalentitydetails (ph.org_id)
					  ) le_name,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getleaddressline1 ()
					  ) le_addr1,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getleaddressline2 ()
					  ) le_addr2,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getleaddressline3 ()
					  ) le_addr3,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getletownorcity ()
					  ) le_town_city,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getlestateorprovince ()
					  ) le_stae_province,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getlepostalcode ()
					  ) le_postalcode,
			   DECODE (NVL (ph.org_id, -1),
					   -1, NULL,
					   po_communication_pvt.getlecountry ()
					  ) le_country,
			   DECODE
				  (ph.cancel_flag,
				   'Y', po_communication_pvt.getpocanceldate (ph.po_header_id),
				   NULL
				  ) cancel_date,
			   ph.change_summary, ph.document_creation_method,
			   ph.encumbrance_required_flag, psl.display_name style_display_name,
			   assa.fax_area_code vendor_fax_area_code, hre.full_name AS planner,
			   hre.email_address AS planner_email,
			   (SELECT phone_number
				  FROM per_phones
				 WHERE parent_id = hre.person_id
				   AND parent_table = 'PER_ALL_PEOPLE_F'
				   AND SYSDATE BETWEEN date_from AND NVL
													   (date_to, SYSDATE + 1)
														  -- Included for defect 28201
				   AND phone_type = 'W1'                  -- Included for defect 28201
				   AND ROWNUM = 1                         -- Included for defect 28201
								 ) AS planner_phone,
			   DECODE
				  ((SELECT   COUNT (person_id) - 1
						FROM per_all_people_f revised_hre, fnd_user u
					   WHERE ph.last_updated_by = u.user_id
						 AND u.employee_id = revised_hre.person_id
					GROUP BY person_id),
				   0, (SELECT revised_hre.full_name
						 FROM per_all_people_f revised_hre, fnd_user u
						WHERE ph.last_updated_by = u.user_id
						  AND u.employee_id = revised_hre.person_id),
				   (SELECT revised_hre.full_name
					  FROM per_all_people_f revised_hre, fnd_user u
					 WHERE ph.last_updated_by = u.user_id
					   AND u.employee_id = revised_hre.person_id
					   AND SYSDATE BETWEEN revised_hre.effective_start_date
									   AND revised_hre.effective_end_date)
				  ) AS revised_by,
			   DECODE
				  ((SELECT   COUNT (person_id) - 1
						FROM per_all_people_f revised_hre, fnd_user u
					   WHERE ph.last_updated_by = u.user_id
						 AND u.employee_id = revised_hre.person_id
					GROUP BY person_id),
				   0, (SELECT revised_hre.email_address
						 FROM per_all_people_f revised_hre, fnd_user u
						WHERE ph.last_updated_by = u.user_id
						  AND u.employee_id = revised_hre.person_id),
				   (SELECT revised_hre.email_address
					  FROM per_all_people_f revised_hre, fnd_user u
					 WHERE ph.last_updated_by = u.user_id
					   AND u.employee_id = revised_hre.person_id
					   AND SYSDATE BETWEEN revised_hre.effective_start_date
									   AND revised_hre.effective_end_date)
				  ) AS revised_by_email,
			   (SELECT revised_pph.phone_number
				  FROM per_all_people_f revised_hre,
					   per_phones revised_pph,
					   fnd_user u
				 WHERE revised_hre.person_id = revised_pph.parent_id
				   AND ph.last_updated_by = u.user_id
				   AND u.employee_id = revised_hre.person_id
				   AND revised_pph.parent_table = 'PER_ALL_PEOPLE_F'
				   --Added for Defect 16219--Start
				   AND SYSDATE BETWEEN revised_hre.effective_start_date
								   AND revised_hre.effective_end_date
				   AND SYSDATE BETWEEN revised_pph.date_from
								   AND NVL
										 (revised_pph.date_to, SYSDATE + 1)
														  -- Included for defect 28201
				   AND revised_pph.phone_type = 'W1'      -- Included for defect 28201
				   AND ROWNUM = 1                         -- Included for defect 28201
								 --Added for defect 16219 -- End
			   ) AS revised_by_phone_number,
			   assa.vendor_site_code AS supplier_site_name, mfg.mfg_name,
			   mfg.mfg_address_line1, mfg.mfg_address_line2, mfg.mfg_address_line3,
			   mfg.mfg_city, mfg.mfg_state, mfg.mfg_postal_code, mfg.mfg_country,
			   ph.ship_via_lookup_code, ph.attribute_category AS po_type,
			   -- Add amount for services defect# 5933 and 13702
			   TO_CHAR
				  (DECODE (ph.type_lookup_code,
						   'STANDARD', po_core_s.get_total ('H', ph.po_header_id),
						   NULL
						  ),
				   po_communication_pvt.getformatmask
				  ) AS total_amount_minus_tax,
			   --Commented and added for Defect#26317
			   /*TO_CHAR (NVL (ph.attribute2, 0),
			   po_communication_pvt.getformatmask
			   ) AS total_tax,*/
			   TO_CHAR
					  (NVL ((SELECT   SUM (NVL (pda.nonrecoverable_tax, 0))
									+ SUM (NVL (pda.recoverable_tax, 0))
							   FROM po_distributions_all pda
							  WHERE ph.po_header_id = pda.po_header_id),
							0
						   ),
					   po_communication_pvt.getformatmask
					  ) AS total_tax,
			   -- Add amount for services defect# 5933 and 13702 )
			   TO_CHAR
				  (  DECODE (ph.type_lookup_code,
							 'STANDARD', po_core_s.get_total ('H', ph.po_header_id),
							 NULL
							)
				   --+ NVL (ph.attribute2, 0), --Commented and added for Defect#26317
				   + NVL ((SELECT   SUM (NVL (pda.nonrecoverable_tax, 0))
								  + SUM (NVL (pda.recoverable_tax, 0))
							 FROM po_distributions_all pda
							WHERE ph.po_header_id = pda.po_header_id),
						  0
						 ),
				   po_communication_pvt.getformatmask
				  ) AS total_amount_with_tax,
			   fnd_profile.VALUE ('XX_PO_RPT_TERMS_CONDITIONS') AS terms_conditions,
			   NULL AS drop_ship_address1, --drop_ship.ship_to_address1 AS drop_ship_address1,
			   NULL AS drop_ship_address2, --drop_ship.ship_to_address2 AS drop_ship_address2,
			   NULL AS drop_ship_address3, --drop_ship.ship_to_address3 AS drop_ship_address3,
			   NULL AS drop_ship_address4, --drop_ship.ship_to_address4 AS drop_ship_address4,
			   NULL AS drop_ship_address5, --drop_ship.ship_to_address5 AS drop_ship_address5,
			   NULL AS drop_ship_location, --drop_ship.ship_to_location AS drop_ship_location,
			   CAST
				  (MULTISET (SELECT fdst.short_text
							   FROM fnd_attached_documents fad,
									fnd_documents_short_text fdst,
									fnd_documents_tl fdt
							  WHERE fad.entity_name = 'PO_HEADERS'
								AND fdst.media_id = fdt.media_id
								AND fad.pk1_value = ph.po_header_id
								AND fdt.document_id = fad.document_id
							) AS xx_po_short_text_tab
				  ) line_rec,
			   TO_CHAR
				  ((SELECT SUM (po_releases_sv2.get_rel_total (po_release_id))
					  FROM po_releases_all
					 WHERE po_header_id = ph.po_header_id),
				   po_communication_pvt.getformatmask
				  ) AS released_amount,
			   (SELECT meaning
				  FROM fnd_lookup_values
				 WHERE lookup_type = 'XX_PO_SHIP_FROM_PORT'
				   AND lookup_code = ph.attribute9) AS ship_from_port,
			   assa.attribute9 AS legacy_supplier_num,
			   (SELECT DECODE (NVL (COUNT (*), 0), 0, 'X', 'See Below')
															  crow
				  FROM po_headers_all pa, po_line_locations_all pl
				 WHERE pa.po_header_id = ph.po_header_id
				   AND pl.po_header_id = ph.po_header_id
				   AND pa.ship_to_location_id <> pl.ship_to_location_id)
																	AS ship_see_below
		  --end
		FROM   fnd_lookup_values plc1,
			   fnd_lookup_values plc2,
			   fnd_currencies_tl fcc,
			   ap_suppliers vn,
			   ap_supplier_sites_all assa,
			   hz_locations hl,
			   --po_vendor_contacts pvc,
			   ap_supplier_contacts asca,
			   per_all_people_f hre,
			   ap_terms t,
			   po_headers_all ph,
			   fnd_territories_tl fte3,
			   org_freight_tl ofc,
			   po_agents pa,
			   fnd_lookup_values plc3,
			   po_doc_style_lines_tl psl,
			   fnd_lookup_values plc4,
			   hr_lookups hrl,
			   (SELECT assa.vendor_site_id, aps.vendor_name AS mfg_name,
					   assa.address_line1 mfg_address_line1,
					   assa.address_line2 mfg_address_line2,
					   assa.address_line3 mfg_address_line3, assa.city mfg_city,
					   DECODE (assa.state,
							   NULL, DECODE (assa.province,
											 NULL, assa.county,
											 assa.province
											),
							   assa.state
							  ) mfg_state,
					   assa.zip mfg_postal_code, assa.country AS mfg_country
				  FROM ap_suppliers aps, ap_supplier_sites_all assa
				 WHERE assa.vendor_id = aps.vendor_id) mfg
		 WHERE hrl.lookup_code(+) = hre.title
		   AND hrl.lookup_type(+) = 'TITLE'
		   AND vn.vendor_id(+) = ph.vendor_id
		   AND assa.vendor_site_id(+) = ph.vendor_site_id
		   AND assa.location_id = hl.location_id(+)
		   AND ph.vendor_contact_id = asca.vendor_contact_id(+)
		   AND (ph.vendor_contact_id IS NULL
				OR ph.vendor_contact_id = asca.vendor_contact_id --change 35127
			   )
		   AND hre.person_id = ph.agent_id
		   AND TRUNC (SYSDATE) BETWEEN hre.effective_start_date AND hre.effective_end_date
		   AND ph.terms_id = t.term_id(+)
		   AND ph.type_lookup_code IN ('STANDARD', 'BLANKET', 'CONTRACT')
		   AND fcc.currency_code = ph.currency_code
		   AND plc1.lookup_code(+) = ph.fob_lookup_code
		   AND plc1.lookup_type(+) = 'FOB'
		   AND plc1.LANGUAGE(+) = USERENV ('LANG')
		   AND plc1.view_application_id(+) = 201
		   AND DECODE (plc1.lookup_code, NULL, 1, plc1.security_group_id) =
				  DECODE (plc1.lookup_code,
						  NULL, 1,
						  fnd_global.lookup_security_group (plc1.lookup_type,
															plc1.view_application_id
														   )
						 )
		   AND plc2.lookup_code(+) = ph.freight_terms_lookup_code
		   AND plc2.lookup_type(+) = 'FREIGHT TERMS'
		   AND plc2.LANGUAGE(+) = USERENV ('LANG')
		   AND plc2.view_application_id(+) = 201
		   AND DECODE (plc2.lookup_code, NULL, 1, plc2.security_group_id) =
				  DECODE (plc2.lookup_code,
						  NULL, 1,
						  fnd_global.lookup_security_group (plc2.lookup_type,
															plc2.view_application_id
														   )
						 )
		   AND SUBSTR (hl.country, 1, 25) = fte3.territory_code(+)
		   AND DECODE (fte3.territory_code, NULL, '1', fte3.LANGUAGE) =
							 DECODE (fte3.territory_code,
									 NULL, '1',
									 USERENV ('LANG')
									)
		   AND ofc.freight_code(+) = ph.ship_via_lookup_code
		   AND ofc.organization_id(+) = ph.org_id
		   AND pa.agent_id = ph.agent_id
		   AND plc3.lookup_code(+) = ph.shipping_control
		   AND plc3.lookup_type(+) = 'SHIPPING CONTROL'
		   AND plc3.LANGUAGE(+) = USERENV ('LANG')
		   AND plc3.view_application_id(+) = 201
		   AND DECODE (plc3.lookup_code, NULL, 1, plc3.security_group_id) =
				  DECODE (plc3.lookup_code,
						  NULL, 1,
						  fnd_global.lookup_security_group (plc3.lookup_type,
															plc3.view_application_id
														   )
						 )
		   AND fcc.LANGUAGE = USERENV ('LANG')
		   AND ofc.LANGUAGE(+) = USERENV ('LANG')
		   AND ph.style_id = psl.style_id(+)
		   AND psl.LANGUAGE(+) = USERENV ('LANG')
		   AND psl.document_subtype(+) = ph.type_lookup_code
		   AND plc4.lookup_code(+) = asca.prefix
		   AND plc4.lookup_type(+) = 'CONTACT_TITLE'
		   AND plc4.LANGUAGE(+) = USERENV ('LANG')
		   AND plc4.view_application_id(+) = 222
		   AND DECODE (plc4.lookup_code, NULL, 1, plc4.security_group_id) =
				  DECODE (plc4.lookup_code,
						  NULL, 1,
						  fnd_global.lookup_security_group (plc4.lookup_type,
															plc4.view_application_id
														   )
						 )
		   AND mfg.vendor_site_id(+) = ph.attribute7;

