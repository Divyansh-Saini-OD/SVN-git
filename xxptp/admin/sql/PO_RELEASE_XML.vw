-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : PO_RELEASE_XML.sql                                                   |
-- | Description      : SQL Script to replace view PO_RELEASE_XML                            |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   23-APR-2007       Sarah Justina    Initial draft version                      |
-- |1.0        30-APR-2007       Sarah Justina    Baseline                                   |
-- |1.1        18-FEB-2008       P.Suresh         Defect  4772. Moved the bill to and ship to|
-- |                                              columns to the correct positions and       |
-- |                                              modified the logic for tax calculation.    |
-- |1.2        16-Mar-2009       Rama Dwibhashyam Changed the amount minus tax column logic  |
-- |                                              and commented the Drop ship logic          |
-- |                                              DB upgrade issue defect # 13702)           |
-- |1.3        14-Jun-2012       Adithya          defect#16630- Minimum Baseline patch-retrofit|
-- |1.4        11-Oct-2013       Darshini         E0408 - Modified for R12 Upgrade Retrofit  |
-- |1.5        14-Dec-2013       Darshini         E0407 - Defect#26317- Modified the query to|
-- |                                              pick the tax amount from po_distributions_all|
-- |1.6        26-Feb-2014       Veronica         E0407 - Changes for defect 28201.          |
-- |1.7        27-May-2015       Harvinder Rakhra Defect 34469 Incorporated ceded changes    | 
-- |                                              12.0.3 version                             | 
-- |1.8        29-JUN-2017       Tanmoy Bhattacharjee New profile Concatenation Added for Defect#42494|
-- +=========================================================================================+
SET VERIFY OFF
SET TERM ON
SET FEEDBACK OFF
SET SHOW OFF
SET ECHO OFF
SET TAB OFF

WHENEVER SQLERROR CONTINUE
-- ************************************************
-- Replacing view PO_RELEASE_XML
-- ************************************************

WHENEVER SQLERROR CONTINUE
SET TERM ON
PROMPT
PROMPT Replacing view PO_RELEASE_XML
PROMPT
SET TERM OFF

--exec  dbms_application_info.set_client_info('404');

CREATE OR REPLACE VIEW apps.po_release_xml (segment1,
                                       revision_num,
                                       print_count,
                                       creation_date,
                                       printed_date,
                                       revised_date,
                                       document_buyer_first_name,
                                       document_buyer_last_name,
                                       document_buyer_title,
                                       document_buyer_agent_id,
                                       archive_buyer_agent_id,
                                       archive_buyer_first_name,
                                       archive_buyer_last_name,
                                       archive_buyer_title,
                                       cancel_flag,
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
                                       vendor_fax,
                                       supplier_notif_method,
                                       vendor_email,
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
                                       po_release_id,
                                       approved_flag,
                                       LANGUAGE,
                                       vendor_id,
                                       consigned_consumption_flag,
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
                                       ship_to_stateporrovince,
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
                                       -- end
                                       authorization_status,
                                       ussgl_transaction_code,
                                       government_context,
                                       request_id,
                                       program_application_id,
                                       program_id,
                                       program_update_date,
                                       closed_code,
                                       frozen_flag,
                                       release_type,
                                       note_to_vendor,
                                       org_id,
                                       last_update_date,
                                       last_updated_by,
                                       release_num,
                                       agent_id,
                                       release_date,
                                       last_update_login,
                                       created_by,
                                       approved_date,
                                       hold_by,
                                       hold_date,
                                       hold_reason,
                                       hold_flag,
                                       cancelled_by,
                                       cancel_date,
                                       cancel_reason,
                                       firm_status_lookup_code,
                                       firm_date,
                                       attribute_category,
                                       edi_processed_flag,
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
                                       wf_item_type,
                                       wf_item_key,
                                       pcard_id,
                                       pay_on_code,
                                       xml_flag,
                                       xml_send_date,
                                       xml_change_send_date,
                                       cbc_accounting_date,
                                       change_requested_by,
                                       shipping_control,
                                       ou_name,
                                       ou_addr1,
                                       ou_addr2,
                                       ou_addr3,
                                       ou_town_city,
                                       ou_region2,
                                       ou_postalcode,
                                       ou_country,
                                       rel_buyer_location_id,
                                       rel_buyer_address_line1,
                                       rel_buyer_address_line2,
                                       rel_buyer_address_line3,
                                       rel_buyer_address_line4,
                                       rel_buyer_city_state_zip,
                                       rel_buyer_contact_phone,
                                       rel_buyer_contact_email,
                                       rel_buyer_contact_fax,
                                       rel_buyer_country,
                                       total_amount,
                                       vendor_address_line4,
                                       vendor_area_code,
                                       vendor_contact_area_code,
                                       vendor_contact_phone,
                                       le_name,
                                       le_addr1,
                                       le_addr2,
                                       le_addr3,
                                       le_town_city,
                                       le_stae_province,
                                       le_postalcode,
                                       le_country,
                                       start_date,
                                       end_date,
                                       amount_agreed,
                                       change_summary,
                                       document_creation_method,
                                       vendor_order_num,
                                       --Added for R12 Upgrade Retrofit
                                       planner,
                                       planner_email,
                                       planner_phone,
                                       revised_by,
                                       revised_by_email,                                     
                                       revised_by_phone_number,
                                       po_type,
                                       drop_ship_address1,
                                       drop_ship_address2,
                                       drop_ship_address3,
                                       drop_ship_address4,
                                       drop_ship_address5,
                                       drop_ship_location,
                                       total_amount_minus_tax,
                                       total_tax,
                                       total_amount_with_tax,
                                       bpa_revision_num,
                                       terms_conditions,
                                       -- Added to fix defect # 5933
                                       total_tax_release
                                       --end
                                      )
				AS
				SELECT ph.segment1, pr.revision_num, pr.print_count,
					   TO_CHAR (pr.creation_date, 'DD-MON-YYYY HH24:MI:SS') creation_date,
					   TO_CHAR (pr.printed_date, 'DD-MON-YYYY HH24:MI:SS') printed_date,
					   TO_CHAR (pr.revised_date, 'DD-MON-YYYY HH24:MI:SS') revised_date,
					   hre.first_name document_buyer_first_name,
					   hre.last_name document_buyer_last_name, hre.title document_buyer_title,
					   pr.agent_id document_buyer_agent_id,
					   DECODE
						  (NVL (pr.revision_num, 0),
						   0, NULL,
						   po_communication_pvt.getarcbuyeragentid (pr.po_header_id)
						  ) archive_buyer_agent_id,
					   DECODE
						   (NVL (pr.revision_num, 0),
							0, NULL,
							po_communication_pvt.getarcbuyerfname ()
						   ) archive_buyer_first_name,
					   DECODE
							(NVL (pr.revision_num, 0),
							 0, NULL,
							 po_communication_pvt.getarcbuyerlname ()
							) archive_buyer_last_name,
					   DECODE (NVL (pr.revision_num, 0),
							   0, NULL,
							   po_communication_pvt.getarcbuyertitle ()
							  ) archive_buyer_title,
					   pr.cancel_flag, NVL (pr.acceptance_required_flag, 'N'),
					   TO_CHAR (pr.acceptance_due_date,
								'DD-MON-YYYY HH24:MI:SS'
							   ) acceptance_due_date,
					   fcc.currency_code, fcc.NAME currency_name,
					   TO_CHAR (ph.rate, po_communication_pvt.getformatmask) rate,
					   NVL (ofc.freight_code_tl, ph.ship_via_lookup_code) ship_via,
					   plc1.meaning fob, plc2.meaning freight_terms, t.NAME payment_terms,
					   NVL (pvs.customer_num, vn.customer_num) customer_num,
					   vn.segment1 vendor_num, vn.vendor_name,
					   pvs.address_line1 vendor_address_line1,
					   pvs.address_line2 vendor_address_line2,
					   pvs.address_line3 vendor_address_line3, pvs.city vendor_city,
					   DECODE (pvs.state,
							   NULL, DECODE (pvs.province, NULL, pvs.county, pvs.province),
							   pvs.state
							  ) vendor_state,
					   pvs.zip vendor_postal_code, fte3.territory_short_name vendor_country,
					   pvs.phone vendor_phone, pvc.first_name vendor_contact_first_name,
					   pvc.last_name vendor_contact_last_name, pvc.title vendor_contact_title,
					   pvs.fax vendor_fax, pvs.supplier_notif_method supplier_notif_method,
					   pvs.email_address vendor_email,
                       pr.attribute1,
					   --pr.attribute2,  --commented and added for defect#26317
					   (SELECT   SUM (NVL (pda.nonrecoverable_tax, 0))
							   + SUM (NVL (pda.recoverable_tax, 0))
						  FROM po_distributions_all pda
						 WHERE pr.po_release_id = pda.po_release_id) attribute2,
					   pr.attribute3, pr.attribute4, pr.attribute5, pr.attribute6,
					   pr.attribute7, pr.attribute8, pr.attribute9, pr.attribute10,
					   pr.attribute11, pr.attribute12, pr.attribute13, pr.attribute14,
					   pr.attribute15, ph.vendor_site_id, ph.po_header_id, pr.po_release_id,
					   DECODE (pr.approved_flag, 'Y', 'Y', 'N') approved_flag, pvs.LANGUAGE,
					   ph.vendor_id, pr.consigned_consumption_flag,
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
					   --added for r12 upgrade retrofit
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
					   DECODE (NVL (ph.bill_to_location_id, -1),
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
					   --added for r12 upgrade retrofit
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
					   pr.authorization_status, pr.ussgl_transaction_code,
					   pr.government_context, pr.request_id, pr.program_application_id,
					   pr.program_id, pr.program_update_date, pr.closed_code, pr.frozen_flag,
					   pr.release_type, pr.note_to_vendor, pr.org_id,
					   TO_CHAR (pr.last_update_date,
								'DD-MON-YYYY HH24:MI:SS'
							   ) last_update_date,
					   pr.last_updated_by, pr.release_num, pr.agent_id,
					   TO_CHAR (pr.release_date, 'DD-MON-YYYY HH24:MI:SS') release_date,
					   pr.last_update_login, pr.created_by,
					   TO_CHAR (pr.approved_date, 'DD-MON-YYYY HH24:MI:SS') approved_date,
					   pr.hold_by, TO_CHAR (pr.hold_date, 'DD-MON-YYYY HH24:MI:SS') hold_date,
					   pr.hold_reason, pr.hold_flag, pr.cancelled_by,
					   TO_CHAR (pr.cancel_date, 'DD-MON-YYYY HH24:MI:SS') cancel_date,
					   pr.cancel_reason, pr.firm_status_lookup_code,
					   TO_CHAR (pr.firm_date, 'DD-MON-YYYY HH24:MI:SS') firm_date,
					   pr.attribute_category, pr.edi_processed_flag,
					   pr.global_attribute_category, pr.global_attribute1,
					   pr.global_attribute2, pr.global_attribute3, pr.global_attribute4,
					   pr.global_attribute5, pr.global_attribute6, pr.global_attribute7,
					   pr.global_attribute8, pr.global_attribute9, pr.global_attribute10,
					   pr.global_attribute11, pr.global_attribute12, pr.global_attribute13,
					   pr.global_attribute14, pr.global_attribute15, pr.global_attribute16,
					   pr.global_attribute17, pr.global_attribute18, pr.global_attribute19,
					   pr.global_attribute20, pr.wf_item_type, pr.wf_item_key, pr.pcard_id,
					   pr.pay_on_code, pr.xml_flag,
					   TO_CHAR (pr.xml_send_date, 'DD-MON-YYYY HH24:MI:SS') xml_send_date,
					   TO_CHAR (pr.xml_change_send_date,
								'DD-MON-YYYY HH24:MI:SS'
							   ) xml_change_send_date,
					   TO_CHAR (pr.cbc_accounting_date,
								'DD-MON-YYYY HH24:MI:SS'
							   ) cbc_accounting_date,
					   pr.change_requested_by, plc3.meaning shipping_control,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getoperationinfo (pr.org_id)
							  ) ou_name,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getouaddressline1 ()
							  ) ou_addr1,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getouaddressline2 ()
							  ) ou_addr2,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getouaddressline3 ()
							  ) ou_addr3,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getoutowncity ()
							  ) ou_town_city,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getouregion2 ()
							  ) ou_region2,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getoupostalcode ()
							  ) ou_postalcode,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getoucountry ()
							  ) ou_country,
					   po_communication_pvt.getlocationinfo
														(pa.location_id)
																		rel_buyer_location_id,
					   po_communication_pvt.getaddressline1 () rel_buyer_address_line1,
					   po_communication_pvt.getaddressline2 () rel_buyer_address_line2,
					   po_communication_pvt.getaddressline3 () rel_buyer_address_line3,
					   po_communication_pvt.getaddressline4 () rel_buyer_address_line4,
					   po_communication_pvt.getaddressinfo () rel_buyer_city_state_zip,
					   po_communication_pvt.getphone (pa.agent_id) rel_buyer_contact_phone,
					   po_communication_pvt.getemail () rel_buyer_contact_email,
					   po_communication_pvt.getfax () rel_buyer_contact_fax,
					   po_communication_pvt.getterritoryshortname () rel_buyer_country,
					   TO_CHAR (po_core_s.get_total ('R', pr.po_release_id),
								po_communication_pvt.getformatmask
							   ) total_amount,
					   pvs.address_line4 vendor_address_line4, pvs.area_code vendor_area_code,
					   pvc.area_code vendor_contact_area_code, pvc.phone vendor_contact_phone,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getlegalentitydetails (pr.org_id)
							  ) le_name,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getleaddressline1 ()
							  ) le_addr1,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getleaddressline2 ()
							  ) le_addr2,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getleaddressline3 ()
							  ) le_addr3,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getletownorcity ()
							  ) le_town_city,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getlestateorprovince ()
							  ) le_stae_province,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getlepostalcode ()
							  ) le_postalcode,
					   DECODE (NVL (pr.org_id, -1),
							   -1, NULL,
							   po_communication_pvt.getlecountry ()
							  ) le_country,
					   TO_CHAR (ph.start_date, 'DD-MON-YYYY HH24:MI:SS') start_date,
					   TO_CHAR (ph.end_date, 'DD-MON-YYYY HH24:MI:SS') end_date,
					   TO_CHAR (NVL (ph.blanket_total_amount, ''),
								po_communication_pvt.getformatmask
							   ) amount_agreed,
					   pr.change_summary, pr.document_creation_method, pr.vendor_order_num,
					   --added for r12 upgrade retrofit
					   hre.full_name AS planner, hre.email_address AS planner_email,
					   (SELECT phone_number
						  FROM per_phones
						 WHERE parent_id = hre.person_id
						   AND parent_table = 'PER_ALL_PEOPLE_F'
						   AND SYSDATE BETWEEN date_from AND NVL
															   (date_to, SYSDATE + 1)
						   AND phone_type = 'W1'                  -- included for defect 28201
						   AND ROWNUM = 1                         -- included for defect 28201
										 ) AS planner_phone,
					   -- added check effective date to avoid multiple records for an employee
					   (SELECT revised_hre.full_name
						  FROM per_all_people_f revised_hre, fnd_user u
						 WHERE ph.last_updated_by = u.user_id
						   AND u.employee_id = revised_hre.person_id
						   AND SYSDATE BETWEEN revised_hre.effective_start_date
										   AND revised_hre.effective_end_date) AS revised_by,
					   -- added check effective date to avoid multiple records for an employee
					   (SELECT revised_hre.email_address
						  FROM per_all_people_f revised_hre, fnd_user u
						 WHERE ph.last_updated_by = u.user_id
						   AND u.employee_id = revised_hre.person_id
						   AND SYSDATE BETWEEN revised_hre.effective_start_date
										   AND revised_hre.effective_end_date)
																		  AS revised_by_email,
					   -- added check effective date to avoid multiple records for an employee
					   (SELECT revised_pph.phone_number
						  FROM per_all_people_f revised_hre,
							   per_phones revised_pph,
							   fnd_user u
						 WHERE revised_hre.person_id = revised_pph.parent_id
						   AND ph.last_updated_by = u.user_id
						   AND u.employee_id = revised_hre.person_id
						   AND revised_pph.parent_table = 'PER_ALL_PEOPLE_F'
						   AND SYSDATE BETWEEN revised_hre.effective_start_date
										   AND revised_hre.effective_end_date
						   AND SYSDATE BETWEEN revised_pph.date_from
										   AND NVL
												 (revised_pph.date_to, SYSDATE + 1)
						   AND revised_pph.phone_type = 'W1'      -- included for defect 28201
						   AND ROWNUM = 1                         -- included for defect 28201
										 ) AS revised_by_phone_number,
					   ph.attribute_category AS po_type, NULL AS drop_ship_address1,
					   NULL AS drop_ship_address2, NULL AS drop_ship_address3,
					   NULL AS drop_ship_address4, NULL AS drop_ship_address5,
					   NULL AS drop_ship_location,
					   NVL
						  (po_releases_sv2.get_rel_total (pr.po_release_id),
						   0
						  ) AS total_amount_minus_tax,
					   --nvl (ph.attribute2, 0) as total_tax, --commented and added for defect# 26317
					   NVL ((SELECT   SUM (NVL (pda.nonrecoverable_tax, 0))
									+ SUM (NVL (pda.recoverable_tax, 0))
							   FROM po_distributions_all pda
							  WHERE ph.po_header_id = pda.po_header_id),
							0
						   ) AS total_tax,
						 NVL
							(po_releases_sv2.get_rel_total (pr.po_release_id),
							 0
							)
					   --+ nvl (ph.attribute2, 0) as total_amount_with_tax, --commented and added for defect# 26317
					   + NVL ((SELECT   SUM (NVL (pda.nonrecoverable_tax, 0))
									  + SUM (NVL (pda.recoverable_tax, 0))
								 FROM po_distributions_all pda
								WHERE ph.po_header_id = pda.po_header_id),
							  0
							 ) AS total_amount_with_tax,
					   ph.revision_num AS bpa_revision,
					   fnd_profile.VALUE ('XX_PO_RPT_TERMS_CONDITIONS')||' '||fnd_profile.VALUE ('XX_PO_RPT_TERMS_CONDITIONS_CONCATINATION') AS terms_conditions,-- Added for Defect#42494
					   --commented and added for defect# 26317
					   /*-- added to fix defect # 5933
					   (select sum (nvl (attribute2, 0))
					   from po_line_locations_all
					   where po_release_id = pr.po_release_id) total_tax_release
					   --end*/
					   (SELECT   SUM (NVL (pda.nonrecoverable_tax, 0))
							   + SUM (NVL (pda.recoverable_tax, 0))
						  FROM po_distributions_all pda
						 WHERE pda.po_release_id = pr.po_release_id) total_tax_release
				  FROM fnd_lookup_values plc1,
					   fnd_lookup_values plc2,
					   fnd_currencies_tl fcc,
					   po_vendors vn,
					   po_vendor_sites_all pvs,
					   po_vendor_contacts pvc,
					   per_all_people_f hre,
					   ap_terms t,
					   po_releases_all pr,
					   po_agents pa,
					   po_headers_all ph,
					   fnd_territories_tl fte3,
					   fnd_lookup_values plc3,
					   org_freight ofc
				 WHERE ph.type_lookup_code = 'BLANKET'
				   AND ph.po_header_id = pr.po_header_id
				   AND vn.vendor_id(+) = ph.vendor_id
				   AND pvs.vendor_site_id(+) = ph.vendor_site_id
				   AND ph.vendor_contact_id = pvc.vendor_contact_id(+)
				   AND (ph.vendor_contact_id IS NULL OR ph.vendor_site_id = pvc.vendor_site_id
					   )
				   AND hre.person_id = pr.agent_id
				   AND TRUNC (SYSDATE) BETWEEN hre.effective_start_date AND hre.effective_end_date
				   AND ph.terms_id = t.term_id(+)
				   AND fcc.currency_code = ph.currency_code
				   AND fcc.LANGUAGE = USERENV ('LANG')
				   AND plc1.lookup_code(+) = ph.fob_lookup_code
				   AND plc1.lookup_type(+) = 'FOB'
				   AND plc1.view_application_id(+) = 201
				   AND plc1.LANGUAGE(+) = USERENV ('LANG')
				   AND DECODE (plc1.lookup_code, NULL, 1, plc1.security_group_id) =
						  DECODE (plc1.lookup_code,
								  NULL, 1,
								  fnd_global.lookup_security_group (plc1.lookup_type,
																	plc1.view_application_id
																   )
								 )
				   AND plc2.lookup_code(+) = ph.freight_terms_lookup_code
				   AND plc2.lookup_type(+) = 'FREIGHT TERMS'
				   AND plc2.view_application_id(+) = 201
				   AND plc2.LANGUAGE(+) = USERENV ('LANG')
				   AND DECODE (plc2.lookup_code, NULL, 1, plc2.security_group_id) =
						  DECODE (plc2.lookup_code,
								  NULL, 1,
								  fnd_global.lookup_security_group (plc2.lookup_type,
																	plc2.view_application_id
																   )
								 )
				   AND pvs.country = fte3.territory_code(+)
				   AND DECODE (fte3.territory_code, NULL, '1', fte3.LANGUAGE) =
									 DECODE (fte3.territory_code,
											 NULL, '1',
											 USERENV ('LANG')
											)
				   AND plc3.lookup_code(+) = pr.shipping_control
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
				   AND ofc.freight_code(+) = ph.ship_via_lookup_code
				   AND ofc.organization_id(+) = ph.org_id
				   AND pa.agent_id = pr.agent_id;
/
SHOW ERRORS;

EXIT;

-- ************************************
-- *          END OF SCRIPT           *
-- ************************************
