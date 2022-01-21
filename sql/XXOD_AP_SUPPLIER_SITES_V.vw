CREATE OR REPLACE VIEW XXOD_AP_SUPPLIER_SITES_V AS 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                            Office Depot                           |
-- +===================================================================+
-- | Name  : XXOD_AP_SUPPLIER_SITES_V                                 |
-- | Description: Custom view for the Discoverer Folder OD Supplier   |
-- |              site within OD AP Superuser custom business area    |                
-- |              to create various Discoverer Plus reports.          |
-- |              QC Defect ID 6805                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author            Remarks                   |
-- |=======   ==========   =============     ==========================|
-- |1.0       09-MAY-2008  Michelle Gautier  Initial version           |
--| 1.1       24-JUN-2008 M.Gautier added AFF segments                                              |
-- +===================================================================+|
SELECT --Header
pvs.vendor_site_code site_name,
  pvs.country,
  pvs.address_line1,
  pvs.address_line2,
  pvs.address_line3,
  pvs.address_line4,
  pvs.city,
  pvs.county,
  pvs.state,
  pvs.zip,
  pvs.province,
  pvs.LANGUAGE,
  pvs.inactive_date inactive_on,
  pvs.vendor_site_code_alt alternate_name,
  pvs.address_lines_alt alternate_address,
  pvs.vendor_site_id,
  pvs.vendor_id,
  pvs.last_update_date,
  pvs.last_updated_by,
  pvs.created_by,
  pvs.creation_date,
  pvs.last_update_login,
  --DFF DETAIL
pvs.attribute_category,
  pvs.attribute1,
  pvs.attribute2,
  pvs.attribute3,
  pvs.attribute4,
  pvs.attribute5,
  pvs.attribute6,
  pvs.attribute7 dff_supplier_site_id,
  pvs.attribute8 dff_site_category,
  pvs.attribute9 dff_legacy_supplier_number,
  pvs.attribute10 dff_rms_pi_pack,
  pvs.attribute11 dff_rms_special_terms,
  pvs.attribute12 dff_rms_rtv_obsolete,
  pvs.attribute13 dff_related_pay_site,
  pvs.attribute14 dff_taxware_geo_code,
  pvs.attribute15 dff_gss_data,
  --General Tab
pvs.purchasing_site_flag,
  pvs.pay_site_flag,
  pvs.rfq_only_site_flag,
  pvs.customer_num,
  pvs.supplier_notif_method,
  pvs.email_address,
  pvs.duns_number,
  pvs.area_code,
  pvs.phone,
  pvs.telex,
  pvs.fax_area_code,
  pvs.fax,
  --Contacts Tab
pvc.last_name,
  pvc.first_name,
  pvc.title,
  pvc.department,
  pvc.mail_stop,
  pvc.inactive_date contact_inactive_on,
  pvc.area_code || '-' || pvc.phone contact_phone,
  pvc.fax_area_code || '-' || pvc.fax contact_fax,
  pvc.email_address contact_email,
  -- Accounting Tab
pvs.accts_pay_code_combination_id,
  pvs.prepay_code_combination_id,
  pvs.future_dated_payment_ccid,
  gcc.segment1 Company,
  gcc.segment2 Cost_center,
   gcc.segment3 liability_gl_account,
   gcc.segment4 Location,
   gcc.segment5 Intercompany,
   gcc.segment6 LineOfBusiness,
   gcc.segment7 Future,
  --Control Tab
pvs.tolerance_id,
  att.tolerance_name goods_tolerance,
  att.description tolerance_description,
  pvs.services_tolerance_id,
  decode(pvs.match_option,   'P',   'Purchase Order',   'R',   'Receipt',   NULL) invoice_match_option,
  pvs.hold_all_payments_flag,
  pvs.hold_unmatched_invoices_flag,
  pvs.hold_future_payments_flag hold_unvalidated_invoices,
  pvs.hold_reason payment_hold_reason,
  -- Payment Tab
pvs.terms_id,
  AT.name terms,
  --  lc_terms.displayed_field,
pvs.pay_group_lookup_code pay_group,
  pvs.payment_priority,
  lc_group.displayed_field,
  pvs.remittance_email,
  pvs.terms_date_basis,
  pvs.pay_date_basis_lookup_code pay_date_basis,
  pvs.payment_method_lookup_code payment_method,
  pvs.always_take_disc_flag,
  pvs.exclude_freight_from_discount,
  pvs.exclusive_payment_flag pay_alone_flag,
  pvs.attention_ar_flag,
  pvs.invoice_currency_code invoice_currency,
  pvs.payment_currency_code payment_currency,
  --Bank Accounts Tab
aba.bank_account_name bank_account_name,
  aba.bank_account_num bank_account_num,
  aba.bank_account_type bank_account_type,
  aba.account_type account_type,
  aba.currency_code currency,
  abau.primary_flag primary_flag,
  abau.start_date start_date,
  abau.end_date end_date,
  abb.bank_name bank_name,
  abb.bank_number bank_number,
  abb.bank_branch_name bank_branch_name,
  abb.bank_num branch_num,
  --Tax Reporting Tab
pvs.vat_code,
  pvs.vat_registration_num tax_registration_num,
  pvs.tax_reporting_site_flag income_tax_reporting_site_flag,
  --Purchasing Flag
pvs.ship_to_location_id,
  pvs.bill_to_location_id,
  hr_shipto.location_code ship_to_location,
  hr_billto.location_code bill_to_location,
  pvs.ship_via_lookup_code ship_via,
  pvs.fob_lookup_code fob,
  lc_terms.displayed_field freight_terms,
  ft.territory_short_name,
  lc_ers_pay.displayed_field pay_on,
  pvs.default_pay_site_id,
  pvs2.vendor_site_code alternate_pay_site,
  pvs.pay_on_receipt_summary_code,
  pvs.tp_header_id,
  -- pvs.ece_tp_location_code,
pvs.pcard_site_flag,
  pvs.country_of_origin_code,
  lc_ers.displayed_field invoice_summary_level,
  ft2.territory_short_name country_of_origin_short_name,
  pla.location_id shipping_location_id,
  pvs.org_id,
  pvs.shipping_control,
  pvs.create_debit_memo_flag create_debit_memo_rts,
  pvs.gapless_inv_num_flag gapless_invoice_numbering,
  pvs.selling_company_identifier
FROM po_vendor_sites pvs,
  po_vendor_sites_all pvs2,
  po_lookup_codes lc_terms,
  po_lookup_codes lc_fob,
  po_lookup_codes lc_group,
  ap_distribution_sets_all ad,
  hr_locations_all hr_shipto,
  hr_locations_all hr_billto,
  org_freight ogf,
  fnd_territories_vl ft,
  fnd_territories_vl ft2,
  fnd_languages_vl fl,
  ap_terms AT,
  ap_awt_groups awt,
  financials_system_params_all fin,
  po_lookup_codes lc_ers_pay,
  po_lookup_codes lc_ers,
  po_location_associations_all pla,
  ap_tolerance_templates att,
  po_vendor_contacts pvc,
  gl_code_combinations gcc,
  ap_bank_account_uses abau,
  ap_bank_accounts_all aba,
  ap_bank_branches abb
WHERE lc_terms.lookup_code(+) = pvs.freight_terms_lookup_code
 AND nvl(pvs.org_id,   -99) = nvl(fin.org_id,   -99)
 AND lc_terms.lookup_type(+) = 'FREIGHT TERMS'
 AND lc_fob.lookup_code(+) = pvs.fob_lookup_code
 AND lc_fob.lookup_type(+) = 'FOB'
 AND lc_group.lookup_code(+) = pvs.pay_group_lookup_code
 AND lc_group.lookup_type(+) = 'PAY GROUP'
 AND AT.term_id(+) = pvs.terms_id
 AND ft.territory_code(+) = pvs.country
 AND ft2.territory_code(+) = pvs.country_of_origin_code
 AND fl.nls_language(+) = pvs.LANGUAGE
 AND ad.distribution_set_id(+) = pvs.distribution_set_id
 AND hr_shipto.location_id(+) = pvs.ship_to_location_id
 AND hr_billto.location_id(+) = pvs.bill_to_location_id
 AND awt.group_id(+) = pvs.awt_group_id
 AND ogf.organization_id(+) = ap_utilities_pkg.get_inventory_org(pvs.org_id)
 AND ogf.freight_code(+) = pvs.ship_via_lookup_code
 AND lc_ers_pay.lookup_code(+) = pvs.pay_on_code
 AND lc_ers_pay.lookup_type(+) = 'ERS PAY_ON_CODE'
 AND lc_ers.lookup_code(+) = pvs.pay_on_receipt_summary_code
 AND lc_ers.lookup_type(+) = 'ERS INVOICE_SUMMARY'
 AND pvs2.vendor_site_id(+) = pvs.default_pay_site_id
 AND pvs.vendor_site_id = pla.vendor_site_id(+)
 AND pvs.vendor_id = pla.vendor_id(+)
 AND pvs.tolerance_id = att.tolerance_id(+)
 AND pvs.vendor_site_id = pvc.vendor_site_id(+)
 AND pvs.accts_pay_code_combination_id = gcc.code_combination_id
 AND att.tolerance_type = 'GOODS'
 AND pvs.org_id = fnd_profile.VALUE('ORG_ID')
 AND abau.external_bank_account_id = aba.bank_account_id(+)
 AND aba.bank_branch_id = abb.bank_branch_id(+)
 AND abau.vendor_id(+) = pvs.vendor_id
 AND abau.vendor_site_id(+) = pvs.vendor_site_id
ORDER BY 1
/