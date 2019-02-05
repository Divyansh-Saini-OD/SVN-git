-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : PO_HEADERS_XML.sql                                                   |
-- | Description      : SQL Script to replace view PO_HEADERS_XML                            |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   23-APR-2007       Sarah Justina    Initial draft version                      |              
-- |1.0        30-APR-2007       Sarah Justina    Baseline                                   |                
-- |2.0        28-MAR-2008       Antonio Morales  Include column ship_one_time               |
-- |                                              Defects # 4861 - 4929 - 4930               |
-- |2.0        22-Apr-2008       Antonio Morales  Included nvl for quantity (defect# 5933)   |
-- |3.0        27-MAY-2009       Rama Dwibhashyam Unit Price Decimal fixed (defect# 15456)   |
-- |4.0        14-Jun-2012       Adithya          defect#16630- Minimum Baseline patch-retrofit|
-- |5.0        10-Oct-2013       Darshini         E0407  - Modified for R12 Upgrade Retrofit |
-- |6.0        14-Dec-2013       Darshini         E0407 - Defect#26317- Modified the query to|
-- |                                              pick the tax amount from po_distributions_all| 
-- |6.1        26-Feb-2014       Veronica         E0407 - Changes for defect 28201.          |
-- |6.2        27-May-2015       Harvinder Rakhra Defect 34469 Incorporated ceded changes 12.0.3 version  | 
-- |6.3        24-Jul-2015       Himanshu K       Defect 35127 Corrected the reqd condition. |
-- |6.4        29-JUN-2017       Tanmoy Bhattacharjee Profile Concatenation Added for Defect#42494 |
-- +=========================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR CONTINUE
-- ************************************************
-- Replacing view PO_HEADERS_XML
-- ************************************************

WHENEVER SQLERROR CONTINUE
SET TERM ON
PROMPT
PROMPT Replacing view PO_HEADERS_XML
PROMPT
SET TERM OFF

CREATE OR REPLACE VIEW apps.po_headers_xml (type_lookup_code,
                                       segment1,
                                       revision_num,
                                       print_count,
                                       creation_date,
                                       printed_date,
                                       revised_date,
                                       start_date,
                                       end_date,
                                       note_to_vendor,
                                       document_buyer_first_name,
                                       document_buyer_last_name,
                                       document_buyer_title,
                                       document_buyer_agent_id,
                                       archive_buyer_agent_id,
                                       archive_buyer_first_name,
                                       archive_buyer_last_name,
                                       archive_buyer_title,
                                       amount_agreed,
                                       cancel_flag,
                                       confirming_order_flag,
                                       acceptance_required_flag,
                                       acceptance_due_date,
                                       currency_code,
                                       currency_name,
                                       rate,
                                       ship_via,
                                       fob,
                                       freight_terms,
                                       payment_terms,
                                       customer_num,
                                       vendor_num,
                                       vendor_name,
                                       vendor_address_line1,
                                       vendor_address_line2,
                                       vendor_address_line3,
                                       vendor_city,
                                       vendor_state,
                                       vendor_postal_code,
                                       vendor_country,
                                       vendor_phone,
                                       vendor_contact_first_name,
                                       vendor_contact_last_name,
                                       vendor_contact_title,
                                       vendor_contact_phone,
                                       ship_to_location_id,
                                       ship_to_location_name,
                                       ship_to_address_line1,
                                       ship_to_address_line2,
                                       ship_to_address_line3,
                                       ship_to_address_line4,
                                       ship_to_address_info,
                                       ship_to_country,
                                       --Added for R12 Upgrade Retrofit
                                       ship_to_townorcity, 
                                       ship_to_stateorprovince,
                                       ship_to_postalcode,
                                       --end
                                       bill_to_location_id,
                                       bill_to_location_name,
                                       bill_to_address_line1,
                                       bill_to_address_line2,
                                       bill_to_address_line3,
                                       bill_to_address_line4,
                                       bill_to_address_info,
                                       bill_to_country,
                                       --Added for R12 Upgrade Retrofit
                                       bill_to_townorcity,
                                       bill_to_stateorprovince,
                                       bill_to_postalcode,
                                       --end
                                       attribute1,
                                       attribute2,
                                       attribute3,
                                       attribute4,
                                       attribute5,
                                       attribute6,
                                       attribute7,
                                       attribute8,
                                       attribute9,
                                       attribute10,
                                       attribute11,
                                       attribute12,
                                       attribute13,
                                       attribute14,
                                       attribute15,
                                       vendor_site_id,
                                       po_header_id,
                                       approved_flag,
                                       LANGUAGE,
                                       vendor_id,
                                       closed_code,
                                       ussgl_transaction_code,
                                       government_context,
                                       request_id,
                                       program_application_id,
                                       program_id,
                                       program_update_date,
                                       org_id,
                                       comments,
                                       reply_date,
                                       reply_method_lookup_code,
                                       rfq_close_date,
                                       quote_type_lookup_code,
                                       quotation_class_code,
                                       quote_warning_delay_unit,
                                       quote_warning_delay,
                                       quote_vendor_quote_number,
                                       closed_date,
                                       user_hold_flag,
                                       approval_required_flag,
                                       firm_status_lookup_code,
                                       firm_date,
                                       frozen_flag,
                                       edi_processed_flag,
                                       edi_processed_status,
                                       attribute_category,
                                       created_by,
                                       vendor_contact_id,
                                       terms_id,
                                       fob_lookup_code,
                                       freight_terms_lookup_code,
                                       status_lookup_code,
                                       rate_type,
                                       rate_date,
                                       from_header_id,
                                       from_type_lookup_code,
                                       authorization_status,
                                       approved_date,
                                       amount_limit,
                                       min_release_amount,
                                       note_to_authorizer,
                                       note_to_receiver,
                                       vendor_order_num,
                                       last_update_date,
                                       last_updated_by,
                                       summary_flag,
                                       enabled_flag,
                                       segment2,
                                       segment3,
                                       segment4,
                                       segment5,
                                       start_date_active,
                                       end_date_active,
                                       last_update_login,
                                       supply_agreement_flag,
                                       global_attribute_category,
                                       global_attribute1,
                                       global_attribute2,
                                       global_attribute3,
                                       global_attribute4,
                                       global_attribute5,
                                       global_attribute6,
                                       global_attribute7,
                                       global_attribute8,
                                       global_attribute9,
                                       global_attribute10,
                                       global_attribute11,
                                       global_attribute12,
                                       global_attribute13,
                                       global_attribute14,
                                       global_attribute15,
                                       global_attribute16,
                                       global_attribute17,
                                       global_attribute18,
                                       global_attribute19,
                                       global_attribute20,
                                       interface_source_code,
                                       reference_num,
                                       wf_item_type,
                                       wf_item_key,
                                       pcard_id,
                                       price_update_tolerance,
                                       mrc_rate_type,
                                       mrc_rate_date,
                                       mrc_rate,
                                       pay_on_code,
                                       xml_flag,
                                       xml_send_date,
                                       xml_change_send_date,
                                       global_agreement_flag,
                                       consigned_consumption_flag,
                                       cbc_accounting_date,
                                       consume_req_demand_flag,
                                       change_requested_by,
                                       shipping_control,
                                       conterms_exist_flag,
                                       conterms_articles_upd_date,
                                       conterms_deliv_upd_date,
                                       pending_signature_flag,
                                       ou_name,
                                       ou_addr1,
                                       ou_addr2,
                                       ou_addr3,
                                       ou_town_city,
                                       ou_region2,
                                       ou_postalcode,
                                       ou_country,
                                       buyer_location_id,
                                       buyer_address_line1,
                                       buyer_address_line2,
                                       buyer_address_line3,
                                       buyer_address_line4,
                                       buyer_city_state_zip,
                                       buyer_contact_phone,
                                       buyer_contact_email,
                                       buyer_contact_fax,
                                       vendor_fax,
                                       --Added for R12 Upgrade Retrofit
                                       supplier_notif_method,
                                       vendor_email,
                                       --end
                                       total_amount,
                                       buyer_country,
                                       vendor_address_line4,
                                       vendor_area_code,
                                       vendor_contact_area_code,
                                       le_name,
                                       le_addr1,
                                       le_addr2,
                                       le_addr3,
                                       le_town_city,
                                       le_stae_province,
                                       le_postalcode,
                                       le_country,
                                       cancel_date,
                                       change_summary,
                                       document_creation_method,
                                       encumbrance_required_flag,
                                       style_display_name,
                                       vendor_fax_area_code,
                                       --Added for R12 Upgrade Retrofit
                                       planner,
                                       planner_email,
                                       planner_phone,
                                       revised_by,
                                       revised_by_email,
                                       revised_by_phone_number,
                                       supplier_site_name,
                                       mfg_name,
                                       mfg_address_line1,
                                       mfg_address_line2,
                                       mfg_address_line3,
                                       mfg_city,
                                       mfg_state,
                                       mfg_postal_code,
                                       mfg_country,
                                       ship_via_lookup_code,
                                       po_type,
                                       total_amount_minus_tax,
                                       total_tax,
                                       total_amount_with_tax,
                                       terms_conditions,
                                       drop_ship_address1,
                                       drop_ship_address2,
                                       drop_ship_address3,
                                       drop_ship_address4,
                                       drop_ship_address5,
                                       drop_ship_location,
                                       header_short_text,
                                       released_amount,
                                       ship_from_port,
                                       legacy_supplier_num,
                                       ship_see_below
                                      --end
									  )
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
			   fnd_profile.VALUE ('XX_PO_RPT_TERMS_CONDITIONS') ||' '|| fnd_profile.VALUE ('XX_PO_RPT_TERMS_CONDITIONS_CONCATINATION') AS terms_conditions, -- Added for Defect#42494
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
				OR ph.vendor_contact_id = asca.vendor_contact_id    --QC 35127
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
/
SHOW ERRORS;

EXIT;

-- ************************************
-- *          END OF SCRIPT           *
-- ************************************
