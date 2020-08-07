create or replace 
PROCEDURE xx_ap_supp_real_out_rms_xml(errbuf OUT VARCHAR2,   retcode OUT VARCHAR2, xml_output OUT CLOB) AS
/*********************************************************************************************************
*******************************************************************************************************************/
 /* Define constants */ c_file_path constant VARCHAR2(15) := 'XXFIN_OUTBOUND';
c_blank constant VARCHAR2(1) := ' ';
c_when constant DATE := sysdate;
c_separator constant VARCHAR2(1) := ';';
c_fileext constant VARCHAR2(10) := '.txt';
c_who constant fnd_user.user_id%TYPE := fnd_load_util.owner_id('INTERFACE');
/* Define variables */ v_system VARCHAR2(32);
v_last_update_date DATE;
v_gss_last_update DATE;
v_rms_last_update DATE;
v_psft_last_update DATE;
v_extract_time DATE;
v_date_diff INTERVAL DAY(4) TO SECOND(0); --Defect #13002
v_vendor_last_update po_vendor_sites_all.last_update_date%TYPE;
v_site_last_update po_vendor_sites_all.last_update_date%TYPE;
v_site_contact_last_update po_vendor_contacts.last_update_date%TYPE;
v_bpel_run_flag VARCHAR2(1) := 'N';
v_exit_flag VARCHAR2(1) := 'N';
v_gss_flag VARCHAR2(1) := 'N';
v_rms_flag VARCHAR2(1) := 'N';
v_psft_flag VARCHAR2(1) := 'N';
v_timestamp VARCHAR2(30) := to_char(c_when,   'DDMONYY_HHMISS');
v_gssfileid utl_file.file_type;
v_rmsfileid utl_file.file_type;
v_psftfileid utl_file.file_type;
v_opengssfile VARCHAR2(1) := 'N';
v_openrmsfile VARCHAR2(1) := 'N';
v_openpsftfile VARCHAR2(1) := 'N';
v_name VARCHAR2(100);
v_parent_name VARCHAR2(100);
v_vendor_number VARCHAR2(30);
v_vendor_id NUMBER;
v_parent_id NUMBER;
v_vendor_type VARCHAR2(64);
v_category VARCHAR2(64);
v_type_att9 VARCHAR2(64);
v_gss_data po_vendor_sites_all.attribute15%TYPE;
v_reccnt NUMBER := 0;
v_file_data1 VARCHAR2(1000);
v_file_data2 VARCHAR2(1000);
v_file_data3 VARCHAR2(1000);
v_file_data4 VARCHAR2(1000);
v_file_data5 VARCHAR2(1000);
v_file_data6 VARCHAR2(1000);
v_file_data7 VARCHAR2(1000);
v_gss_mfg_id VARCHAR2(64) := NULL;
v_gss_buying_agent_id VARCHAR2(64) := NULL;
v_gss_freight_id VARCHAR2(64) := NULL;
v_gss_ship_id VARCHAR2(64) := NULL;
v_addr_flag NUMBER;
v_site_phone VARCHAR2(100);
v_site_fax VARCHAR2(100);
v_site_contact_name VARCHAR2(100);
v_globalvendor_id po_vendor_sites_all.attribute9%TYPE;
v_gssglobalvendor_id po_vendor_sites_all.attribute9%TYPE;
v_primary_paysite_flag po_vendor_sites_all.primary_pay_site_flag%TYPE;
v_purchasing_site_flag po_vendor_sites_all.purchasing_site_flag%TYPE;
v_pay_site_flag po_vendor_sites_all.pay_site_flag%TYPE;
v_area_code po_vendor_sites_all.area_code%TYPE;
v_phone po_vendor_sites_all.phone%TYPE;
v_province po_vendor_sites_all.province%TYPE;
v_parent_vendor_id po_vendors.parent_vendor_id%TYPE;
v_attribute10 VARCHAR2(500);
--po_vendor_sites_all.attribute10%TYPE;
v_attribute11 VARCHAR2(500);
--po_vendor_sites_all.attribute11%TYPE;
v_attribute12 VARCHAR2(500);
--po_vendor_sites_all.attribute12%TYPE;
v_attribute13 VARCHAR2(500);
--po_vendor_sites_all.attribute13%TYPE;
v_attribute15 VARCHAR2(500);
v_attribute16 VARCHAR2(500);
--business classification
 v_mbe   VARCHAR2(500);
 v_nmsdc VARCHAR2(500);
 v_wbe   VARCHAR2(500);
 v_wbenc VARCHAR2(500);
 v_vob   VARCHAR2(500);
 v_dodva VARCHAR2(500);
 v_doe   VARCHAR2(500);
 v_usbln VARCHAR2(500);
 v_lgbt  VARCHAR2(500);
 v_nglcc VARCHAR2(500);
 v_nibnishablty VARCHAR2(500);
 v_fob   VARCHAR2(500);
 v_sb    VARCHAR2(500);
 v_samgov VARCHAR2(500);
 v_sba   VARCHAR2(500);
 v_sbc   VARCHAR2(500);
 v_sdbe  VARCHAR2(500);
 v_sba8a VARCHAR2(500);
 v_hubzone VARCHAR2(500);
 v_wosb  VARCHAR2(500);
 v_wsbe  VARCHAR2(500);
 v_edwosb VARCHAR2(500);
 v_vosb  VARCHAR2(500);
 v_sdvosb VARCHAR2(500);
 v_hbcumi VARCHAR2(500);
 v_anc  VARCHAR2(500);
 v_ind  VARCHAR2(500);
 v_minority_owned VARCHAR2(500);
--Added by Sunil
--po_vendor_sites_all.attribute15%TYPE;
v_attribute8 po_vendor_sites_all.attribute8%TYPE;
v_supp_attribute7 po_vendors.attribute7%TYPE;
v_supp_attribute8 po_vendors.attribute8%TYPE;
v_supp_attribute9 po_vendors.attribute9%TYPE;
v_supp_attribute10 po_vendors.attribute10%TYPE;
v_supp_attribute11 po_vendors.attribute10%TYPE;
v_vendor_site_id po_vendor_sites_all.vendor_site_id%TYPE;
g_vendor_site_id po_vendor_sites_all.vendor_site_id%TYPE;
v_vendor_site_code po_vendor_sites_all.vendor_site_code%TYPE;
v_bank_account_name po_vendor_sites_all.bank_account_name%TYPE;
v_bank_account_num po_vendor_sites_all.bank_account_num%TYPE;
v_address_line1 po_vendor_sites_all.address_line1%TYPE;
v_address_line2 po_vendor_sites_all.address_line2%TYPE;
v_address_line3 po_vendor_sites_all.address_line3%TYPE;
v_city po_vendor_sites_all.city%TYPE;
v_state po_vendor_sites_all.state%TYPE;
v_zip po_vendor_sites_all.zip%TYPE;
v_country po_vendor_sites_all.country%TYPE;
v_orgcountry po_vendor_sites_all.country%TYPE;
v_site_contact_rtvname VARCHAR2(100);
v_site_rtvaddr1 po_vendor_sites_all.address_line1%TYPE;
v_site_rtvaddr2 po_vendor_sites_all.address_line2%TYPE;
v_site_rtvaddr3 po_vendor_sites_all.address_line2%TYPE;
v_site_rtvcity po_vendor_sites_all.city%TYPE;
v_site_rtvstate po_vendor_sites_all.state%TYPE;
v_site_rtvzip po_vendor_sites_all.zip%TYPE;
v_site_rtvcountry po_vendor_sites_all.country%TYPE;
v_site_contact_payname VARCHAR2(100);
v_site_payaddr1 po_vendor_sites_all.address_line1%TYPE;
v_site_payaddr2 po_vendor_sites_all.address_line2%TYPE;
v_site_payaddr3 po_vendor_sites_all.address_line2%TYPE;
v_site_paycity po_vendor_sites_all.city%TYPE;
v_site_paystate po_vendor_sites_all.state%TYPE;
v_site_payzip po_vendor_sites_all.zip%TYPE;
v_site_paycountry po_vendor_sites_all.country%TYPE;
v_site_contact_purchname VARCHAR2(100);
v_site_purchaddr1 po_vendor_sites_all.address_line1%TYPE;
v_site_purchaddr2 po_vendor_sites_all.address_line2%TYPE;
v_site_purchaddr3 po_vendor_sites_all.address_line2%TYPE;
v_site_purchcity po_vendor_sites_all.city%TYPE;
v_site_purchstate po_vendor_sites_all.state%TYPE;
v_site_purchzip po_vendor_sites_all.zip%TYPE;
v_site_purchcountry po_vendor_sites_all.country%TYPE;
v_site_contact_ppname VARCHAR2(100);
v_site_ppaddr1 po_vendor_sites_all.address_line1%TYPE;
v_site_ppaddr2 po_vendor_sites_all.address_line2%TYPE;
v_site_ppaddr3 po_vendor_sites_all.address_line2%TYPE;
v_site_ppcity po_vendor_sites_all.city%TYPE;
v_site_ppstate po_vendor_sites_all.state%TYPE;
v_site_ppzip po_vendor_sites_all.zip%TYPE;
v_site_ppcountry po_vendor_sites_all.country%TYPE;
v_inactive_date xx_po_vendor_sites_kff_v.blank99%TYPE;
--po_vendor_sites_all.inactive_date%TYPE;
v_invc_curr po_vendors.invoice_currency_code%TYPE;
v_payment_currency_code po_vendors.payment_currency_code%TYPE;
v_site_lang NUMBER;
v_site_orgid po_vendor_sites_all.org_id%TYPE;
v_site_language po_vendor_sites_all.LANGUAGE %TYPE;
v_site_terms po_vendor_sites_all.terms_id%TYPE;
v_site_terms_date_basis po_vendor_sites_all.terms_date_basis%TYPE;
v_terms_date_basis po_vendors.terms_date_basis%TYPE;
v_site_freightterms po_vendor_sites_all.freight_terms_lookup_code%TYPE;
v_site_contact_id po_vendor_contacts.vendor_contact_id%TYPE;
v_site_contact_fname po_vendor_contacts.first_name%TYPE;
v_site_contact_lname po_vendor_contacts.last_name%TYPE;
v_site_contact_areacode po_vendor_contacts.area_code%TYPE;
v_site_contact_phone po_vendor_contacts.phone%TYPE;
v_site_contact_fareacode po_vendor_contacts.fax_area_code%TYPE;
v_site_contact_fphone po_vendor_contacts.phone%TYPE;
v_site_contact_payemail po_vendor_contacts.email_address%TYPE;
v_site_contact_purchemail po_vendor_contacts.email_address%TYPE;
v_site_contact_ppemail po_vendor_contacts.email_address%TYPE;
v_site_contact_rtvemail po_vendor_contacts.email_address%TYPE;
v_site_contact_email po_vendor_contacts.email_address%TYPE;
v_site_contact_payphone VARCHAR2(100);
v_site_contact_purchphone VARCHAR2(100);
v_site_contact_ppphone VARCHAR2(100);
v_site_contact_rtvphone VARCHAR2(100);
v_site_contact_payfax VARCHAR2(100);
v_site_contact_purchfax VARCHAR2(100);
v_site_contact_ppfax VARCHAR2(100);
v_site_contact_rtvfax VARCHAR2(100);
v_tax_reg_num po_vendors.num_1099%TYPE;
v_duns_num po_vendor_sites_all.duns_number%TYPE;
-- or DUNS_NUMBER
v_po_vendor_vat_registration po_vendor_sites_all.vat_registration_num%TYPE;
v_po_site_vat_registration po_vendor_sites_all.vat_registration_num%TYPE;
v_debit_memo_flag po_vendor_sites_all.create_debit_memo_flag%TYPE;
v_pay_group_lookup_code po_vendors.pay_group_lookup_code%TYPE;
v_payment_method_lookup_code ap_suppliers.payment_method_lookup_code%TYPE; -- V4.0 po_vendors.payment_method_lookup_code%TYPE;
v_vendor_type_lookup_code po_vendors.vendor_type_lookup_code%TYPE;
v_minority_cd po_vendors.minority_group_lookup_code%TYPE;
v_minority_class VARCHAR2(30);
--Variables for Business Classification Descriptions
v_minority_cd_desc fnd_lookup_values_vl.meaning%TYPE;
v_mbe_desc fnd_lookup_values_vl.meaning%TYPE;
v_nmsdc_desc fnd_lookup_values_vl.meaning%TYPE;
v_wbe_desc fnd_lookup_values_vl.meaning%TYPE;
v_wbenc_desc fnd_lookup_values_vl.meaning%TYPE;
v_vob_desc fnd_lookup_values_vl.meaning%TYPE;
v_dodva_desc fnd_lookup_values_vl.meaning%TYPE;
v_doe_desc fnd_lookup_values_vl.meaning%TYPE;
v_usbln_desc fnd_lookup_values_vl.meaning%TYPE;
v_lgbt_desc fnd_lookup_values_vl.meaning%TYPE;
v_nglcc_desc fnd_lookup_values_vl.meaning%TYPE;
v_nibnishablty_desc fnd_lookup_values_vl.meaning%TYPE;
v_fob_desc fnd_lookup_values_vl.meaning%TYPE;
v_sb_desc fnd_lookup_values_vl.meaning%TYPE;
v_samgov_desc fnd_lookup_values_vl.meaning%TYPE;
v_sba_desc fnd_lookup_values_vl.meaning%TYPE;
v_sbc_desc fnd_lookup_values_vl.meaning%TYPE;
v_sdbe_desc fnd_lookup_values_vl.meaning%TYPE;
v_sba8a_desc fnd_lookup_values_vl.meaning%TYPE;
v_hubzone_desc fnd_lookup_values_vl.meaning%TYPE;
v_wosb_desc fnd_lookup_values_vl.meaning%TYPE;
v_wsbe_desc fnd_lookup_values_vl.meaning%TYPE;
v_edwosb_desc fnd_lookup_values_vl.meaning%TYPE;
v_vosb_desc fnd_lookup_values_vl.meaning%TYPE;
v_sdvosb_desc fnd_lookup_values_vl.meaning%TYPE;
v_hbcumi_desc fnd_lookup_values_vl.meaning%TYPE;
v_anc_desc fnd_lookup_values_vl.meaning%TYPE;
v_ind_desc fnd_lookup_values_vl.meaning%TYPE;
v_minority_owned_desc fnd_lookup_values_vl.meaning%TYPE;
--
--    DEFINE KFF variables
v_lead_time xx_po_vendor_sites_kff_v.blank99%TYPE;
v_back_order_flag xx_po_vendor_sites_kff_v.blank99%TYPE;
v_delivery_policy xx_po_vendor_sites_kff_v.blank99%TYPE;
v_min_prepaid_code xx_po_vendor_sites_kff_v.blank99%TYPE;
v_vendor_min_amount xx_po_vendor_sites_kff_v.blank99%TYPE;
v_supplier_ship_to xx_po_vendor_sites_kff_v.blank99%TYPE;
v_inventory_type_code xx_po_vendor_sites_kff_v.blank99%TYPE;
v_vertical_market_indicator xx_po_vendor_sites_kff_v.blank99%TYPE;
v_handling xx_po_vendor_sites_kff_v.blank99%TYPE;
v_allow_auto_receipt xx_po_vendor_sites_kff_v.blank99%TYPE;
v_eft_settle_days xx_po_vendor_sites_kff_v.blank99%TYPE;
v_split_file_flag xx_po_vendor_sites_kff_v.blank99%TYPE;
v_master_vendor_id xx_po_vendor_sites_kff_v.blank99%TYPE;
v_pi_pack_year xx_po_vendor_sites_kff_v.blank99%TYPE;
v_od_date_signed xx_po_vendor_sites_kff_v.blank99%TYPE;
v_vendor_date_signed xx_po_vendor_sites_kff_v.blank99%TYPE;
v_deduct_from_invoice_flag xx_po_vendor_sites_kff_v.blank99%TYPE;
v_min_bus_category xx_po_vendor_sites_kff_v.blank99%TYPE;
v_new_store_flag xx_po_vendor_sites_kff_v.blank99%TYPE;
v_new_store_terms xx_po_vendor_sites_kff_v.blank99%TYPE;
v_seasonal_flag xx_po_vendor_sites_kff_v.blank99%TYPE;
v_start_date xx_po_vendor_sites_kff_v.blank99%TYPE;
v_end_date xx_po_vendor_sites_kff_v.blank99%TYPE;
v_seasonal_terms xx_po_vendor_sites_kff_v.blank99%TYPE;
v_late_ship_flag xx_po_vendor_sites_kff_v.blank99%TYPE;
v_edi_distribution_code xx_po_vendor_sites_kff_v.blank99%TYPE;
v_od_cont_sig xx_po_vendor_sites_kff_v.blank99%TYPE;
v_od_cont_title xx_po_vendor_sites_kff_v.blank99%TYPE;
v_rtv_option xx_po_vendor_sites_kff_v.blank99%TYPE;
v_rtv_freight_payment_method xx_po_vendor_sites_kff_v.blank99%TYPE;
v_permanent_rga xx_po_vendor_sites_kff_v.blank99%TYPE;
v_destroy_allow_amount xx_po_vendor_sites_kff_v.blank99%TYPE;
v_payment_frequency xx_po_vendor_sites_kff_v.blank99%TYPE;
v_min_return_qty xx_po_vendor_sites_kff_v.blank99%TYPE;
v_min_return_amount xx_po_vendor_sites_kff_v.blank99%TYPE;
v_damage_destroy_limit xx_po_vendor_sites_kff_v.blank99%TYPE;
v_rtv_instructions xx_po_vendor_sites_kff_v.blank99%TYPE;
v_addl_rtv_instructions xx_po_vendor_sites_kff_v.blank99%TYPE;
v_rga_marked_flag xx_po_vendor_sites_kff_v.blank99%TYPE;
v_remove_price_sticker_flag xx_po_vendor_sites_kff_v.blank99%TYPE;
v_contact_supplier_rga_flag xx_po_vendor_sites_kff_v.blank99%TYPE;
v_destroy_flag xx_po_vendor_sites_kff_v.blank99%TYPE;
v_serial_num_required_flag xx_po_vendor_sites_kff_v.blank99%TYPE;
v_obsolete_item xx_po_vendor_sites_kff_v.blank99%TYPE;
v_obsolete_allowance_pct xx_po_vendor_sites_kff_v.blank99%TYPE;
v_obsolete_allowance_days xx_po_vendor_sites_kff_v.blank99%TYPE;
v_850_po xx_po_vendor_sites_kff_v.blank99%TYPE;
v_860_po_change xx_po_vendor_sites_kff_v.blank99%TYPE;
v_855_confirm_po xx_po_vendor_sites_kff_v.blank99%TYPE;
v_856_asn xx_po_vendor_sites_kff_v.blank99%TYPE;
v_846_availability xx_po_vendor_sites_kff_v.blank99%TYPE;
v_810_invoice xx_po_vendor_sites_kff_v.blank99%TYPE;
v_832_price_sales_cat xx_po_vendor_sites_kff_v.blank99%TYPE;
v_820_eft xx_po_vendor_sites_kff_v.blank99%TYPE;
v_861_damage_shortage xx_po_vendor_sites_kff_v.blank99%TYPE;
v_852_sales xx_po_vendor_sites_kff_v.blank99%TYPE;
v_rtv_related_siteid xx_po_vendor_sites_kff_v.blank99%TYPE;
v_od_ven_sig_name xx_po_vendor_sites_kff_v.blank99%TYPE;
v_od_ven_sig_title xx_po_vendor_sites_kff_v.blank99%TYPE;
v_rms_count NUMBER := 0;
v_gss_count NUMBER := 0;
v_psft_count NUMBER := 0;
x_target_value1 VARCHAR2(200);
x_error_message VARCHAR2(2000);
x_target_value2 VARCHAR2(200);
x_target_value3 VARCHAR2(200);
x_target_value4 VARCHAR2(200);
x_target_value5 VARCHAR2(200);
x_target_value6 VARCHAR2(200);
x_target_value7 VARCHAR2(200);
x_target_value8 VARCHAR2(200);
x_target_value9 VARCHAR2(200);
x_target_value10 VARCHAR2(200);
x_target_value11 VARCHAR2(200);
x_target_value12 VARCHAR2(200);
x_target_value13 VARCHAR2(200);
x_target_value14 VARCHAR2(200);
x_target_value15 VARCHAR2(200);
x_target_value16 VARCHAR2(200);
x_target_value17 VARCHAR2(200);
x_target_value18 VARCHAR2(200);
x_target_value19 VARCHAR2(200);
x_target_value20 VARCHAR2(200);
v_gss_outfilename VARCHAR2(60) := 'SyncSupplierGSS_' || v_timestamp || c_fileext;
v_psft_outfilename VARCHAR2(60) := 'SyncSupplierPSFT_' || v_timestamp || c_fileext;
v_rms_outfilename VARCHAR2(60) := 'SyncSupplierRMS_' || v_timestamp || c_fileext;
-- variables for file copy
ln_req_id NUMBER;
lc_sourcepath VARCHAR2(1000);
lc_destpath VARCHAR2(1000);
lb_result boolean;
lc_phase VARCHAR2(1000);
lc_status VARCHAR2(1000);
lc_dev_phase VARCHAR2(1000);
lc_dev_status VARCHAR2(1000);
lc_message VARCHAR2(1000);
lc_err_status VARCHAR2(10);
lc_err_mesg VARCHAR2(1000);
lc_err_flag VARCHAR2(10) := 'N';
v_terms_name VARCHAR2(100);
v_site_terms_name VARCHAR2(100);
v_site_terms_name_desc VARCHAR2(250);
v_site_exists_flag VARCHAR2(1) := 'Y';
v_telex ap_supplier_sites_all.telex%TYPE; --V4.0
/*-- Cursor to read the custom table
CURSOR extsupplupdate_cur IS
SELECT v.ext_system,
  v.last_update_date,
  v.extract_time,
  v.bpel_running_flag
FROM xx_ap_supp_extract v;*/--sunil
-- Main Cursor to read all the data ;
CURSOR mainsupplupdate_cur IS
SELECT a.vendor_site_id,
  a.attribute8,
  a.attribute13,
  a.vendor_site_code,
  a.last_update_date,
  a.purchasing_site_flag,
  a.pay_site_flag,
  a.address_line1,
  a.address_line2,
  a.address_line3,
  a.city,
  UPPER(a.state),
  a.zip,
  nvl(a.country,   'US'),
  a.area_code,
  a.phone,
  a.inactive_date,
  a.pay_group_lookup_code,
  --nvl(ieppm.payment_method_code,a.payment_method_lookup_code),--commented for defect 33188
  nvl(ieppm.payment_method_code,'CHECK'),--added for defect 33188
  a.payment_currency_code,
  a.primary_pay_site_flag,
  nvl(a.freight_terms_lookup_code,   'CC'),
  a.vat_registration_num,
  a.LANGUAGE,
  a.bank_account_num,
  a.bank_account_name,
  a.duns_number,
  -- DUNNS number
b.vendor_contact_id,
  b.first_name,
  b.last_name,
  b.area_code,
  b.phone,
  b.email_address,
  b.fax_area_code,
  b.fax,
  b.last_update_date,
  c.vendor_name,
  c.last_update_date,
  c.vat_registration_num,
  a.terms_date_basis,
  c.vendor_type_lookup_code,
  -- identify Garnishment suppliers
c.parent_vendor_id,
  c.num_1099,
  -- TIN
c.minority_group_lookup_code,
  c.attribute7,
  c.attribute8,
  c.attribute9,
  c.attribute10,
  c.attribute11,
  nvl(a.create_debit_memo_flag,   'N'),
  a.province,
  a.terms_id,
  a.org_id,
  a.telex -- V4.0
FROM AP_SUPPLIER_SITES_ALL a, -- V4.00 po_vendor_sites_all a,
  po_vendor_contacts b,
  AP_SUPPLIERS c, -- V4.00 po_vendors c
  iby_external_payees_all iepa,  --V4.0
  iby_ext_party_pmt_mthds ieppm  --V4.0
WHERE a.vendor_site_id = b.vendor_site_id(+)
 AND a.vendor_id = c.vendor_id(+)
-- Defect 28126 Begin
-- AND(a.last_update_date BETWEEN v_last_update_date
-- AND v_extract_time OR b.last_update_date BETWEEN v_last_update_date
-- AND v_extract_time OR c.last_update_date BETWEEN v_last_update_date
-- AND v_extract_time)
-- Defect 28126 End
 AND a.org_id IN(xx_fin_country_defaults_pkg.f_org_id('CA'),   xx_fin_country_defaults_pkg.f_org_id('US')) --= ou.organization_id
 -- V4.0
 AND a.vendor_site_id = iepa.supplier_site_id
 AND iepa.ext_payee_id = ieppm.ext_pmt_party_id(+)
 AND( (ieppm.inactive_date IS NULL)or (ieppm.inactive_date > sysdate))
 AND a.telex IS NOT NULL  -- Defect 28126
  AND SUBSTR(NVL(telex,'XXXXXX'),-6)<> 'INTFCD'  --(a.telex IS NOT NULL AND a.telex NOT LIKE '%INTFCD')  -- V4.0, Added Telex Condition
AND a.vendor_site_id IN (816190)--(1219991)--816190)--,816191,816192)
 AND C.VENDOR_ID=2149831--5847240--5847239--2149831
ORDER BY a.vendor_site_id;

-- Site Names beginning with ?EXP-IMP?, ?TR?, ?EXP-IMP-PAY? etc and I will use
-- those value and Site Category as EXPENSE/TRADE/GARNISHMENT to identify suppliers
-- for outbound interface to GSS/PSFT/Peoplesoft.  But for garnishments,  they
-- will have a classification of  ?Garnishment? and a site category that starts with EXP.
-- Garnishments: po_vendor.vendor_type_lookup_code =  'VENDORS'
PROCEDURE init_variables IS
BEGIN
  v_globalvendor_id := NULL;
  v_name := NULL;
  v_vendor_site_id := 0;
  v_vendor_site_code := NULL;
  v_addr_flag := 0;
  v_inactive_date := NULL;
  v_invc_curr := NULL;
  v_site_lang := 1;
  v_site_terms := NULL;
  v_site_terms_name := NULL;
  v_site_terms_name_desc := NULL;
  v_site_freightterms := NULL;
  v_debit_memo_flag := NULL;
  v_duns_num := NULL;
  v_parent_name := NULL;
  v_parent_id := NULL;
  v_tax_reg_num := 0;
  v_attribute8 := NULL;
  v_attribute10 := NULL;
  v_attribute11 := NULL;
  v_attribute12 := NULL;
  v_attribute13 := NULL;
  v_attribute15 := NULL;
  v_attribute16 := NULL;
  v_site_contact_name := NULL;
  v_site_contact_payphone := NULL;
  v_site_contact_purchphone := NULL;
  v_site_contact_ppphone := NULL;
  v_site_contact_rtvphone := NULL;
  v_site_contact_payfax := NULL;
  v_site_contact_purchfax := NULL;
  v_site_contact_ppfax := NULL;
  v_site_contact_rtvfax := NULL;
  v_site_phone := NULL;
  v_site_fax := NULL;
  v_site_contact_payemail := NULL;
  v_site_contact_purchemail := NULL;
  v_site_contact_ppemail := NULL;
  v_site_contact_rtvemail := NULL;
  v_site_contact_payname := NULL;
  v_site_payaddr1 := NULL;
  v_site_payaddr2 := NULL;
  v_site_payaddr3 := NULL;
  v_site_paycity := NULL;
  v_site_paystate := NULL;
  v_site_payzip := NULL;
  v_site_paycountry := NULL;
  v_site_contact_rtvname := NULL;
  v_site_rtvaddr1 := NULL;
  v_site_rtvaddr2 := NULL;
  v_site_rtvaddr3 := NULL;
  v_site_rtvcity := NULL;
  v_site_rtvstate := NULL;
  v_site_rtvzip := NULL;
  v_site_rtvcountry := NULL;
  v_site_contact_purchname := NULL;
  v_site_purchaddr1 := NULL;
  v_site_purchaddr2 := NULL;
  v_site_purchaddr3 := NULL;
  v_site_purchcity := NULL;
  v_site_purchstate := NULL;
  v_site_purchzip := NULL;
  v_site_purchcountry := NULL;
  v_site_contact_ppname := NULL;
  v_site_ppaddr1 := NULL;
  v_site_ppaddr2 := NULL;
  v_site_ppaddr3 := NULL;
  v_site_ppcity := NULL;
  v_site_ppstate := NULL;
  v_site_ppzip := NULL;
  v_site_ppcountry := NULL;
  v_attribute15 := NULL;
  v_supp_attribute7 := NULL;
  v_supp_attribute8 := NULL;
  v_supp_attribute9 := NULL;
  v_supp_attribute10 := NULL;
  v_supp_attribute11 := NULL;
  v_primary_paysite_flag := NULL;
  v_attribute8 := NULL;
  v_bank_account_name := NULL;
  v_bank_account_num := NULL;
  v_minority_cd := NULL;
  v_file_data1 := NULL;
  v_file_data2 := NULL;
  v_file_data3 := NULL;
  v_file_data4 := NULL;
  v_file_data5 := NULL;
  v_file_data6 := NULL;
  v_minority_class := NULL;
  v_minority_cd_desc := NULL;
--Variables for Business Classification Descriptions.
  v_mbe_desc := NULL;
  v_nmsdc_desc := NULL; 
  v_wbe_desc := NULL;
  v_wbenc_desc := NULL;
  v_vob_desc := NULL;
  v_dodva_desc := NULL;
  v_doe_desc := NULL;
  v_usbln_desc := NULL;
  v_lgbt_desc := NULL;
  v_nglcc_desc := NULL;
  v_nibnishablty_desc := NULL;
  v_fob_desc := NULL;
  v_sb_desc := NULL;
  v_samgov_desc := NULL;
  v_sba_desc := NULL;
  v_sbc_desc := NULL;
  v_sdbe_desc := NULL;
  v_sba8a_desc := NULL;
  v_hubzone_desc := NULL;
  v_wosb_desc := NULL;
  v_wsbe_desc := NULL;
  v_edwosb_desc := NULL;
  v_vosb_desc := NULL;
  v_sdvosb_desc := NULL;
  v_hbcumi_desc := NULL;
  v_anc_desc := NULL;
  v_ind_desc := NULL;
  v_minority_owned_desc := NULL;
--
  v_payment_currency_code := NULL;
  v_site_orgid := NULL;
  v_site_exists_flag := 'Y';
  v_orgcountry := null;
END init_variables;
PROCEDURE init_kffvariables IS
BEGIN
  -- KFF variables;
  v_lead_time := NULL;
  v_back_order_flag := NULL;
  v_delivery_policy := NULL;
  v_min_prepaid_code := NULL;
  v_vendor_min_amount := NULL;
  v_supplier_ship_to := NULL;
  v_inventory_type_code := NULL;
  v_vertical_market_indicator := NULL;
  v_allow_auto_receipt := NULL;
  v_handling := NULL;
  v_eft_settle_days := NULL;
  v_split_file_flag := NULL;
  v_master_vendor_id := NULL;
  v_pi_pack_year := NULL;
  v_od_date_signed := NULL;
  v_vendor_date_signed := NULL;
  v_deduct_from_invoice_flag := NULL;
  v_min_bus_category := NULL;
  v_new_store_flag := NULL;
  v_new_store_terms := NULL;
  v_seasonal_flag := NULL;
  v_start_date := NULL;
  v_end_date := NULL;
  v_seasonal_terms := NULL;
  v_late_ship_flag := NULL;
  v_edi_distribution_code := NULL;
  v_od_cont_sig:= NULL;
  v_od_cont_title:= NULL;
  v_rtv_option := NULL;
  v_rtv_freight_payment_method := NULL;
  v_permanent_rga := NULL;
  v_destroy_allow_amount := NULL;
  v_payment_frequency := NULL;
  v_min_return_qty := NULL;
  v_min_return_amount := NULL;
  v_damage_destroy_limit := NULL;
  v_rtv_instructions := NULL;
  v_addl_rtv_instructions := NULL;
  v_rga_marked_flag := NULL;
  v_remove_price_sticker_flag := NULL;
  v_contact_supplier_rga_flag := NULL;
  v_destroy_flag := NULL;
  v_serial_num_required_flag := NULL;
  v_obsolete_item := NULL;
  v_obsolete_allowance_pct := NULL;
  v_obsolete_allowance_days := NULL;
  v_850_po := NULL;
  v_860_po_change := NULL;
  v_855_confirm_po := NULL;
  v_856_asn := NULL;
  v_846_availability := NULL;
  v_810_invoice := NULL;
  v_832_price_sales_cat := NULL;
  v_820_eft := NULL;
  v_861_damage_shortage := NULL;
  v_852_sales := NULL;
  v_od_ven_sig_name:= NULL;
  v_od_ven_sig_title:= NULL;
  v_gss_mfg_id := NULL;
  v_gss_buying_agent_id:= NULL;
  v_gss_freight_id:= NULL;
  v_gss_ship_id := NULL;
END init_kffvariables;
PROCEDURE create_data_line IS
l_domdoc dbms_xmldom.DOMDocument;

   l_xmltype XMLTYPE;
--  i number :=0;
   l_root_node dbms_xmldom.DOMNode;
   l_supplier_list_node dbms_xmldom.DOMNode;
   l_supplier_node dbms_xmldom.DOMNode;
  
   l_bus_class_node dbms_xmldom.DOMNode;
   l_supp_header_node dbms_xmldom.DOMNode;   
   l_cust_attributes_node dbms_xmldom.DOMNode;
   l_edi_attributes_node dbms_xmldom.DOMNode;

   l_supplier_traits_node dbms_xmldom.DOMNode;
   
   l_supplier_trait_node dbms_xmldom.DOMNode;

   l_sup_trait_action_type_n dbms_xmldom.DOMNode;
   l_sup_trait_action_type_tn dbms_xmldom.DOMNode;
 
   l_sup_trait_node dbms_xmldom.DOMNode;
   l_sup_trait_textnode dbms_xmldom.DOMNode;

   l_sup_trait_desc_node dbms_xmldom.DOMNode;
   l_sup_trait_desc_textnode dbms_xmldom.DOMNode;

   l_sup_master_sup_ind_node dbms_xmldom.DOMNode;
   l_sup_master_sup_ind_textnode dbms_xmldom.DOMNode;

--   l_supp_element dbms_xmldom.DOMElement;
  -- l_supp_node dbms_xmldom.DOMNode;


   l_trans_id_node dbms_xmldom.DOMNode;
   l_trans_id_textnode dbms_xmldom.DOMNode;
   
   l_globalvendor_id_n dbms_xmldom.DOMNode;
   l_globalvendor_id_tn dbms_xmldom.DOMNode;

     
   l_name_node dbms_xmldom.DOMNode;
   l_name_textnode dbms_xmldom.DOMNode;


l_Supplier_site_node  dbms_xmldom.DOMNode;

   l_address_node  dbms_xmldom.DOMNode;

  l_addr_list_element dbms_xmldom.DOMElement;
  l_addr_element dbms_xmldom.DOMElement;

  l_addr_list_node dbms_xmldom.DOMNode;
  l_addr_node dbms_xmldom.DOMNode;
  
  l_site_addr_node dbms_xmldom.DOMNode;

  l_site_purch_addr_node  dbms_xmldom.DOMNode;
  l_site_pay_addr_node  dbms_xmldom.DOMNode;
  l_site_pp_addr_node  dbms_xmldom.DOMNode;
  l_site_rtv_addr_node  dbms_xmldom.DOMNode;

  l_site_addr_contact_node dbms_xmldom.DOMNode;
  l_site_addr_cont_list_node dbms_xmldom.DOMNode;
  l_site_addr_contact_pname_node  dbms_xmldom.DOMNode;
  l_site_addr_cont_ptitle_node  dbms_xmldom.DOMNode;
  l_site_addr_cont_ptitle_tn  dbms_xmldom.DOMNode;
  l_v_addr_con_salutation_n dbms_xmldom.DOMNode;
  l_v_addr_con_salutation_tn dbms_xmldom.DOMNode;
  l_v_addr_con_jobtitle_n dbms_xmldom.DOMNode;
  l_v_addr_con_jobtitle_tn dbms_xmldom.DOMNode;
  
    l_site_addr_cont_ph_node dbms_xmldom.DOMNode; 
  l_site_addr_cont_phasso_node  dbms_xmldom.DOMNode;
  l_v_site_con_addrphtype_n  dbms_xmldom.DOMNode;
  l_v_site_con_addrphtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_addrphone_n dbms_xmldom.DOMNode;
  l_v_site_con_addrphareacode_n dbms_xmldom.DOMNode;
  l_v_site_con_addrphareacode_tn dbms_xmldom.DOMNode;
  l_v_site_con_addrphcntrycd_n dbms_xmldom.DOMNode;
  l_v_site_con_addrphcntrycd_tn dbms_xmldom.DOMNode;
  l_v_site_con_addrphext_n dbms_xmldom.DOMNode;
  l_v_site_con_addrphext_tn dbms_xmldom.DOMNode;
  l_v_site_con_addrphpri_n dbms_xmldom.DOMNode;
  l_v_site_con_addrphpri_tn dbms_xmldom.DOMNode; 

  l_site_addr_cont_fax_node dbms_xmldom.DOMNode;
  l_site_addr_cont_faxasso_node dbms_xmldom.DOMNode;
  l_v_site_con_addrfaxtype_n dbms_xmldom.DOMNode;
  l_v_site_con_addrfaxtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_addrfax_n dbms_xmldom.DOMNode;
  l_v_site_con_addrfaxareacd_n dbms_xmldom.DOMNode;
  l_v_site_con_addrfaxareacd_tn dbms_xmldom.DOMNode;
  l_v_site_con_addrfxcntrycd_n dbms_xmldom.DOMNode;
  l_v_site_con_addrfxcntrycd_tn dbms_xmldom.DOMNode;
  l_v_site_con_addrfaxext_n dbms_xmldom.DOMNode;
  l_v_site_con_addrfaxext_tn dbms_xmldom.DOMNode;
  l_v_site_con_addrfaxpri_n dbms_xmldom.DOMNode;
  l_v_site_con_addrfaxpri_tn dbms_xmldom.DOMNode;

  l_site_addr_cont_email_node dbms_xmldom.DOMNode; 
  l_site_addr_cont_emailasso_n  dbms_xmldom.DOMNode;
  l_v_site_con_addremailtype_n dbms_xmldom.DOMNode;
  l_v_site_con_addremailtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_addremailpri_n dbms_xmldom.DOMNode;
  l_v_site_con_addremailpri_tn dbms_xmldom.DOMNode;

  l_v_addrareacode NUMBER;
  l_v_addrph NUMBER;
  l_v_addrfaxareacode NUMBER;
  l_v_addrfax NUMBER;
  

  l_site_purch_cont_list_node dbms_xmldom.DOMNode;
  l_site_purch_contact_node dbms_xmldom.DOMNode;
  l_site_pur_contact_pname_node  dbms_xmldom.DOMNode;
  l_site_pur_cont_ptitle_node  dbms_xmldom.DOMNode;
  l_site_pur_cont_ptitle_tn  dbms_xmldom.DOMNode;
  l_v_pur_con_salutation_n dbms_xmldom.DOMNode;
  l_v_pur_con_salutation_tn dbms_xmldom.DOMNode;
  l_v_pur_con_jobtitle_n dbms_xmldom.DOMNode;
  l_v_pur_con_jobtitle_tn dbms_xmldom.DOMNode;
  l_site_pur_cont_ph_node dbms_xmldom.DOMNode;
  l_site_pur_cont_phasso_node dbms_xmldom.DOMNode;
  l_v_site_con_purchphtype_n dbms_xmldom.DOMNode;
  l_v_site_con_purchphtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_purchphone_n dbms_xmldom.DOMNode;
  l_v_site_con_purphareacode_n dbms_xmldom.DOMNode;
  l_v_site_con_purphareacode_tn dbms_xmldom.DOMNode;
  l_v_site_con_purphcntrycode_n dbms_xmldom.DOMNode;
  l_v_site_con_purphcntrycode_tn dbms_xmldom.DOMNode;
  l_v_site_con_purchphext_n dbms_xmldom.DOMNode;
  l_v_site_con_purchphext_tn dbms_xmldom.DOMNode;
  l_v_site_con_purchphpri_n dbms_xmldom.DOMNode;
  l_v_site_con_purchphpri_tn dbms_xmldom.DOMNode;
 
  l_v_purareacode NUMBER;
  l_v_purph NUMBER;
  
--  FAX
  l_site_pur_cont_fax_node dbms_xmldom.DOMNode;
  l_site_pur_cont_faxasso_node dbms_xmldom.DOMNode;
  l_v_site_con_purchfaxtype_n dbms_xmldom.DOMNode;
  l_v_site_con_purchfaxtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_purchfax_n dbms_xmldom.DOMNode;
  l_v_site_con_purfaxareacode_n dbms_xmldom.DOMNode;
  l_v_site_con_purfaxareacode_tn dbms_xmldom.DOMNode;
  l_v_site_con_purfxcntrycode_n dbms_xmldom.DOMNode;
  l_v_site_con_purfxcntrycode_tn dbms_xmldom.DOMNode;
  l_v_site_con_purchfaxext_n dbms_xmldom.DOMNode;
  l_v_site_con_purchfaxext_tn dbms_xmldom.DOMNode;
  l_v_site_con_purchfaxpri_n dbms_xmldom.DOMNode;
  l_v_site_con_purchfaxpri_tn dbms_xmldom.DOMNode;
 
  l_v_purfaxareacode NUMBER;
  l_v_purfax NUMBER;
  --FAX
--Email
l_site_pur_cont_email_node dbms_xmldom.DOMNode; 
l_site_pur_cont_emailasso_node dbms_xmldom.DOMNode;
l_v_site_con_puremailtype_n  dbms_xmldom.DOMNode;
l_v_site_con_puremailtype_tn  dbms_xmldom.DOMNode;
l_v_site_con_puremailpri_n  dbms_xmldom.DOMNode;
l_v_site_con_puremailpri_tn  dbms_xmldom.DOMNode;
--Email


  l_site_pay_cont_list_node dbms_xmldom.DOMNode;
  l_site_pay_contact_node dbms_xmldom.DOMNode;
  l_site_pay_contact_pname_node  dbms_xmldom.DOMNode;
  l_site_pay_cont_ptitle_node  dbms_xmldom.DOMNode;
  l_site_pay_cont_ptitle_tn  dbms_xmldom.DOMNode;
  l_v_pay_con_salutation_n dbms_xmldom.DOMNode;
  l_v_pay_con_salutation_tn dbms_xmldom.DOMNode;
  l_v_pay_con_jobtitle_n dbms_xmldom.DOMNode;
  l_v_pay_con_jobtitle_tn dbms_xmldom.DOMNode;
  l_site_pay_cont_ph_node dbms_xmldom.DOMNode;
  l_site_pay_cont_phasso_node dbms_xmldom.DOMNode;
  l_v_site_con_payphtype_n dbms_xmldom.DOMNode;
  l_v_site_con_payphtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_payphone_n  dbms_xmldom.DOMNode;
  l_v_site_con_payphareacode_n dbms_xmldom.DOMNode;
  l_v_site_con_payphareacode_tn dbms_xmldom.DOMNode;
  l_v_site_con_payphcntrycode_n dbms_xmldom.DOMNode;
  l_v_site_con_payphcntrycode_tn dbms_xmldom.DOMNode;

  l_v_site_con_payfxcntrycode_n dbms_xmldom.DOMNode;
  l_v_site_con_payfxcntrycode_tn dbms_xmldom.DOMNode;
  l_v_site_con_payphext_n dbms_xmldom.DOMNode;
  l_v_site_con_payphext_tn dbms_xmldom.DOMNode;
  l_v_site_con_payphpri_n dbms_xmldom.DOMNode;
  l_v_site_con_payphpri_tn dbms_xmldom.DOMNode;
  l_site_pay_cont_fax_node dbms_xmldom.DOMNode;
  l_site_pay_cont_faxasso_node dbms_xmldom.DOMNode;
  l_v_site_con_payfaxtype_n dbms_xmldom.DOMNode;
  l_v_site_con_payfaxtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_payfax_n dbms_xmldom.DOMNode;
  l_v_site_con_payfaxareacode_n dbms_xmldom.DOMNode;
  l_v_site_con_payfaxareacode_tn dbms_xmldom.DOMNode;
  l_v_site_con_payfaxext_n dbms_xmldom.DOMNode;
  l_v_site_con_payfaxext_tn dbms_xmldom.DOMNode;
  l_v_site_con_payfaxpri_n dbms_xmldom.DOMNode;
  l_v_site_con_payfaxpri_tn dbms_xmldom.DOMNode;
  l_site_pay_cont_email_node dbms_xmldom.DOMNode; 
  l_site_pay_cont_emailasso_node dbms_xmldom.DOMNode;
  l_v_site_con_payemailtype_n dbms_xmldom.DOMNode;
  l_v_site_con_payemailtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_payemailpri_n dbms_xmldom.DOMNode;
  l_v_site_con_payemailpri_tn dbms_xmldom.DOMNode;

  l_v_payareacode NUMBER;
  l_v_payph NUMBER;
  l_v_payfaxareacode NUMBER;
  l_v_payfax NUMBER;


  l_site_pp_cont_list_node dbms_xmldom.DOMNode;
  l_site_pp_contact_node dbms_xmldom.DOMNode;
  l_site_pp_contact_pname_node  dbms_xmldom.DOMNode;
  l_site_pp_cont_ptitle_node  dbms_xmldom.DOMNode;
  l_site_pp_cont_ptitle_tn  dbms_xmldom.DOMNode;
  l_v_pp_con_salutation_n dbms_xmldom.DOMNode;
  l_v_pp_con_salutation_tn dbms_xmldom.DOMNode;
  l_v_pp_con_jobtitle_n dbms_xmldom.DOMNode;
  l_v_pp_con_jobtitle_tn dbms_xmldom.DOMNode;
  l_site_pp_cont_ph_node  dbms_xmldom.DOMNode;
  l_site_pp_cont_phasso_node  dbms_xmldom.DOMNode;
  l_v_site_con_ppphtype_n  dbms_xmldom.DOMNode;
  l_v_site_con_ppphtype_tn  dbms_xmldom.DOMNode;
  l_v_site_con_ppphone_n  dbms_xmldom.DOMNode;
  l_v_site_con_ppphareacode_n dbms_xmldom.DOMNode;
  l_v_site_con_ppphareacode_tn dbms_xmldom.DOMNode;
  l_v_site_con_ppphcntrycode_n dbms_xmldom.DOMNode;
  l_v_site_con_ppphcntrycode_tn dbms_xmldom.DOMNode;
  l_v_site_con_ppphext_n dbms_xmldom.DOMNode;
  l_v_site_con_ppphext_tn dbms_xmldom.DOMNode;
  l_v_site_con_ppphpri_n dbms_xmldom.DOMNode;
  l_v_site_con_ppphpri_tn dbms_xmldom.DOMNode;

  l_site_pp_cont_fax_node dbms_xmldom.DOMNode;
  l_site_pp_cont_faxasso_node dbms_xmldom.DOMNode;
  l_v_site_con_ppfaxtype_n dbms_xmldom.DOMNode;
  l_v_site_con_ppfaxtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_ppfax_n dbms_xmldom.DOMNode;
  l_v_site_con_ppfaxareacode_n dbms_xmldom.DOMNode;
  l_v_site_con_ppfaxareacode_tn dbms_xmldom.DOMNode;
  l_v_site_con_ppfxcntrycode_n dbms_xmldom.DOMNode;
  l_v_site_con_ppfxcntrycode_tn dbms_xmldom.DOMNode;
  l_v_site_con_ppfaxext_n dbms_xmldom.DOMNode;
  l_v_site_con_ppfaxext_tn dbms_xmldom.DOMNode;
  l_v_site_con_ppfaxpri_n dbms_xmldom.DOMNode;
  l_v_site_con_ppfaxpri_tn dbms_xmldom.DOMNode;

  l_v_ppareacode NUMBER;
  l_v_ppph NUMBER;
  l_v_ppfaxareacode NUMBER;
  l_v_ppfax NUMBER;

  l_site_pp_cont_email_node dbms_xmldom.DOMNode; 
  l_site_pp_cont_emailasso_node dbms_xmldom.DOMNode;
  l_v_site_con_ppemailtype_n dbms_xmldom.DOMNode;
  l_v_site_con_ppemailtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_ppemailpri_n dbms_xmldom.DOMNode;
  l_v_site_con_ppemailpri_tn dbms_xmldom.DOMNode;
  

  l_site_rtv_cont_list_node dbms_xmldom.DOMNode;
  l_site_rtv_contact_node dbms_xmldom.DOMNode;
  l_site_rtv_contact_pname_node  dbms_xmldom.DOMNode;
  l_site_rtv_cont_ptitle_node  dbms_xmldom.DOMNode;
  l_site_rtv_cont_ptitle_tn  dbms_xmldom.DOMNode;
  l_v_rtv_con_salutation_n dbms_xmldom.DOMNode;
  l_v_rtv_con_salutation_tn dbms_xmldom.DOMNode;
  l_v_rtv_con_jobtitle_n dbms_xmldom.DOMNode;
  l_v_rtv_con_jobtitle_tn dbms_xmldom.DOMNode;
  
  l_site_rtv_cont_ph_node dbms_xmldom.DOMNode; 
  l_site_rtv_cont_phasso_node  dbms_xmldom.DOMNode;
  l_v_site_con_rtvphtype_n  dbms_xmldom.DOMNode;
  l_v_site_con_rtvphtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_rtvphone_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvphareacode_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvphareacode_tn dbms_xmldom.DOMNode;
  l_v_site_con_rtvphcntrycode_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvphcntrycode_tn dbms_xmldom.DOMNode;
  l_v_site_con_rtvphext_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvphext_tn dbms_xmldom.DOMNode;
  l_v_site_con_rtvphpri_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvphpri_tn dbms_xmldom.DOMNode; 

  l_site_rtv_cont_fax_node dbms_xmldom.DOMNode;
  l_site_rtv_cont_faxasso_node dbms_xmldom.DOMNode;
  l_v_site_con_rtvfaxtype_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvfaxtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_rtvfax_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvfaxareacode_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvfaxareacode_tn dbms_xmldom.DOMNode;
  l_v_site_con_rtvfxcntrycode_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvfxcntrycode_tn dbms_xmldom.DOMNode;
  l_v_site_con_rtvfaxext_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvfaxext_tn dbms_xmldom.DOMNode;
  l_v_site_con_rtvfaxpri_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvfaxpri_tn dbms_xmldom.DOMNode;

  l_site_rtv_cont_email_node dbms_xmldom.DOMNode; 
  l_site_rtv_cont_emailasso_node  dbms_xmldom.DOMNode;
  l_v_site_con_rtvemailtype_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvemailtype_tn dbms_xmldom.DOMNode;
  l_v_site_con_rtvemailpri_n dbms_xmldom.DOMNode;
  l_v_site_con_rtvemailpri_tn dbms_xmldom.DOMNode;

  l_v_rtvareacode NUMBER;
  l_v_rtvph NUMBER;
  l_v_rtvfaxareacode NUMBER;
  l_v_rtvfax NUMBER;


   l_site_element  dbms_xmldom.DOMElement;
   l_site_node  dbms_xmldom.DOMNode;

   l_Vendor_site_id_node dbms_xmldom.DOMNode;
   l_Vendor_site_id_textnode dbms_xmldom.DOMNode;

   l_Vendor_site_code_node dbms_xmldom.DOMNode;
   l_Vendor_site_code_textnode dbms_xmldom.DOMNode;

   
   l_Vendor_Address_Flag_node dbms_xmldom.DOMNode;
   l_Vendor_Address_Flag_textnode dbms_xmldom.DOMNode;

   l_v_inactive_date_n dbms_xmldom.DOMNode;
   l_v_inactive_date_tn dbms_xmldom.DOMNode;



   l_v_pay_cur_code_node dbms_xmldom.DOMNode;
   l_v_pay_cur_code_textnode dbms_xmldom.DOMNode;


   l_v_site_lang_node dbms_xmldom.DOMNode;
   l_v_site_lang_textnode dbms_xmldom.DOMNode;


   l_v_pay_site_flag_node dbms_xmldom.DOMNode;
   l_v_pay_site_flag_textnode dbms_xmldom.DOMNode;
--   

   l_v_purch_site_flag_node dbms_xmldom.DOMNode;
   l_v_purch_site_flag_textnode dbms_xmldom.DOMNode;

   l_v_site_terms_name_n dbms_xmldom.DOMNode;
   l_v_site_terms_name_tn dbms_xmldom.DOMNode;

   l_v_site_terms_name_desc_n dbms_xmldom.DOMNode;
   l_v_site_terms_name_desc_tn dbms_xmldom.DOMNode;

   l_v_site_freightterms_n dbms_xmldom.DOMNode;
   l_v_site_freightterms_tn dbms_xmldom.DOMNode;

   l_v_debit_memo_flag_n dbms_xmldom.DOMNode;
   l_v_debit_memo_flag_tn dbms_xmldom.DOMNode;

   l_v_duns_num_n dbms_xmldom.DOMNode;
   l_v_duns_num_tn dbms_xmldom.DOMNode;

   l_v_tax_reg_num_n dbms_xmldom.DOMNode;
   l_v_tax_reg_num_tn dbms_xmldom.DOMNode;

   l_v_minority_class_n dbms_xmldom.DOMNode;
   l_v_minority_class_tn dbms_xmldom.DOMNode;

   l_v_minority_cd_n dbms_xmldom.DOMNode;
   l_v_minority_cd_tn dbms_xmldom.DOMNode;

   l_v_minority_cd_desc_n dbms_xmldom.DOMNode;
   l_v_minority_cd_desc_tn dbms_xmldom.DOMNode;

   l_v_mbe_n dbms_xmldom.DOMNode;
   l_v_mbe_tn dbms_xmldom.DOMNode;

   l_v_mbe_desc_n dbms_xmldom.DOMNode;
   l_v_mbe_desc_tn dbms_xmldom.DOMNode;

   l_v_nmsdc_n dbms_xmldom.DOMNode;
   l_v_nmsdc_tn dbms_xmldom.DOMNode;

   l_v_nmsdc_desc_n dbms_xmldom.DOMNode;
   l_v_nmsdc_desc_tn dbms_xmldom.DOMNode;

   l_v_wbe_n dbms_xmldom.DOMNode;
   l_v_wbe_tn dbms_xmldom.DOMNode;

   l_v_wbe_desc_n dbms_xmldom.DOMNode;
   l_v_wbe_desc_tn dbms_xmldom.DOMNode;

   l_v_wbenc_n dbms_xmldom.DOMNode;
   l_v_wbenc_tn dbms_xmldom.DOMNode;

   l_v_wbenc_desc_n dbms_xmldom.DOMNode;
   l_v_wbenc_desc_tn dbms_xmldom.DOMNode;
   
   l_v_vob_n dbms_xmldom.DOMNode;
   l_v_vob_tn dbms_xmldom.DOMNode;
   
   l_v_vob_desc_n dbms_xmldom.DOMNode;
   l_v_vob_desc_tn dbms_xmldom.DOMNode;
   
   l_v_dodva_n dbms_xmldom.DOMNode;
   l_v_dodva_tn dbms_xmldom.DOMNode;

   l_v_dodva_desc_n dbms_xmldom.DOMNode;
   l_v_dodva_desc_tn dbms_xmldom.DOMNode;
   
   l_v_doe_n dbms_xmldom.DOMNode;
   l_v_doe_tn dbms_xmldom.DOMNode;

   l_v_doe_desc_n dbms_xmldom.DOMNode;
   l_v_doe_desc_tn dbms_xmldom.DOMNode;
 
   l_v_usbln_n dbms_xmldom.DOMNode;
   l_v_usbln_tn dbms_xmldom.DOMNode;

   l_v_usbln_desc_n dbms_xmldom.DOMNode;
   l_v_usbln_desc_tn dbms_xmldom.DOMNode;
 
   l_v_lgbt_n dbms_xmldom.DOMNode;
   l_v_lgbt_tn dbms_xmldom.DOMNode;

   l_v_lgbt_desc_n dbms_xmldom.DOMNode;
   l_v_lgbt_desc_tn dbms_xmldom.DOMNode;

   l_v_nglcc_n dbms_xmldom.DOMNode;
   l_v_nglcc_tn dbms_xmldom.DOMNode;

   l_v_nglcc_desc_n dbms_xmldom.DOMNode;
   l_v_nglcc_desc_tn dbms_xmldom.DOMNode;

   l_v_nibnishablty_n dbms_xmldom.DOMNode;
   l_v_nibnishablty_tn dbms_xmldom.DOMNode;

   l_v_nibnishablty_desc_n dbms_xmldom.DOMNode;
   l_v_nibnishablty_desc_tn dbms_xmldom.DOMNode;

   l_v_fob_n dbms_xmldom.DOMNode;
   l_v_fob_tn dbms_xmldom.DOMNode;

   l_v_fob_desc_n dbms_xmldom.DOMNode;
   l_v_fob_desc_tn dbms_xmldom.DOMNode;

   l_v_sb_n dbms_xmldom.DOMNode;
   l_v_sb_tn dbms_xmldom.DOMNode;

   l_v_sb_desc_n dbms_xmldom.DOMNode;
   l_v_sb_desc_tn dbms_xmldom.DOMNode;

   l_v_samgov_n dbms_xmldom.DOMNode;
   l_v_samgov_tn dbms_xmldom.DOMNode;

   l_v_samgov_desc_n dbms_xmldom.DOMNode;
   l_v_samgov_desc_tn dbms_xmldom.DOMNode;

   l_v_sba_n dbms_xmldom.DOMNode;
   l_v_sba_tn dbms_xmldom.DOMNode;

   l_v_sba_desc_n dbms_xmldom.DOMNode;
   l_v_sba_desc_tn dbms_xmldom.DOMNode;

   l_v_sbc_n dbms_xmldom.DOMNode;
   l_v_sbc_tn dbms_xmldom.DOMNode;

   l_v_sbc_desc_n dbms_xmldom.DOMNode;
   l_v_sbc_desc_tn dbms_xmldom.DOMNode;

   l_v_sdbe_n dbms_xmldom.DOMNode;
   l_v_sdbe_tn dbms_xmldom.DOMNode;

   l_v_sdbe_desc_n dbms_xmldom.DOMNode;
   l_v_sdbe_desc_tn dbms_xmldom.DOMNode;

   l_v_sba8a_n dbms_xmldom.DOMNode;
   l_v_sba8a_tn dbms_xmldom.DOMNode;

   l_v_sba8a_desc_n dbms_xmldom.DOMNode;
   l_v_sba8a_desc_tn dbms_xmldom.DOMNode;

   l_v_hubzone_n dbms_xmldom.DOMNode;
   l_v_hubzone_tn dbms_xmldom.DOMNode;

   l_v_hubzone_desc_n dbms_xmldom.DOMNode;
   l_v_hubzone_desc_tn dbms_xmldom.DOMNode;

   l_v_wosb_n dbms_xmldom.DOMNode;
   l_v_wosb_tn dbms_xmldom.DOMNode;

   l_v_wosb_desc_n dbms_xmldom.DOMNode;
   l_v_wosb_desc_tn dbms_xmldom.DOMNode;
  
   l_v_wsbe_n dbms_xmldom.DOMNode;
   l_v_wsbe_tn dbms_xmldom.DOMNode;

   l_v_wsbe_desc_n dbms_xmldom.DOMNode;
   l_v_wsbe_desc_tn dbms_xmldom.DOMNode;
 
   l_v_edwosb_n dbms_xmldom.DOMNode;
   l_v_edwosb_tn dbms_xmldom.DOMNode;

   l_v_edwosb_desc_n dbms_xmldom.DOMNode;
   l_v_edwosb_desc_tn dbms_xmldom.DOMNode;

   l_v_vosb_n dbms_xmldom.DOMNode;
   l_v_vosb_tn dbms_xmldom.DOMNode;

   l_v_vosb_desc_n dbms_xmldom.DOMNode;
   l_v_vosb_desc_tn dbms_xmldom.DOMNode;

   l_v_sdvosb_n dbms_xmldom.DOMNode;
   l_v_sdvosb_tn dbms_xmldom.DOMNode;

   l_v_sdvosb_desc_n dbms_xmldom.DOMNode;
   l_v_sdvosb_desc_tn dbms_xmldom.DOMNode;

   l_v_hbcumi_n dbms_xmldom.DOMNode;
   l_v_hbcumi_tn dbms_xmldom.DOMNode;

   l_v_hbcumi_desc_n dbms_xmldom.DOMNode;
   l_v_hbcumi_desc_tn dbms_xmldom.DOMNode;

   l_v_anc_n dbms_xmldom.DOMNode;
   l_v_anc_tn dbms_xmldom.DOMNode;

   l_v_anc_desc_n dbms_xmldom.DOMNode;
   l_v_anc_desc_tn dbms_xmldom.DOMNode;

   l_v_ind_n dbms_xmldom.DOMNode;
   l_v_ind_tn dbms_xmldom.DOMNode;

   l_v_ind_desc_n dbms_xmldom.DOMNode;
   l_v_ind_desc_tn dbms_xmldom.DOMNode;

   l_v_minority_owned_n dbms_xmldom.DOMNode;
   l_v_minority_owned_tn dbms_xmldom.DOMNode;

   l_v_minority_owned_desc_n dbms_xmldom.DOMNode;
   l_v_minority_owned_desc_tn dbms_xmldom.DOMNode;
--
   l_v_primary_paysite_flag_n dbms_xmldom.DOMNode;
   l_v_primary_paysite_flag_tn dbms_xmldom.DOMNode;

   l_v_site_category_n dbms_xmldom.DOMNode;
   l_v_site_category_tn dbms_xmldom.DOMNode;

   l_v_bank_account_num_n dbms_xmldom.DOMNode;
   l_v_bank_account_num_tn dbms_xmldom.DOMNode;

   l_v_bank_account_name_n dbms_xmldom.DOMNode;
   l_v_bank_account_name_tn dbms_xmldom.DOMNode;

   l_v_related_pay_site_n dbms_xmldom.DOMNode;
   l_v_related_pay_site_tn dbms_xmldom.DOMNode;
   
   ----
   l_v_site_puraddr_type_n dbms_xmldom.DOMNode;
   l_v_site_puraddr_type_tn dbms_xmldom.DOMNode;
   
   l_v_site_purseqnum_n dbms_xmldom.DOMNode;
   l_v_site_purseqnum_tn dbms_xmldom.DOMNode;
  
   l_v_site_puraction_type_n dbms_xmldom.DOMNode;
   l_v_site_puraction_type_tn dbms_xmldom.DOMNode;
   
   l_v_site_pur_isprimaryaddr_n   dbms_xmldom.DOMNode;
   l_v_site_pur_isprimaryaddr_tn   dbms_xmldom.DOMNode;

   l_v_site_purchaddr1_node dbms_xmldom.DOMNode; 
   l_v_site_purchaddr1_textnode dbms_xmldom.DOMNode;

   l_v_site_purchaddr2_node dbms_xmldom.DOMNode; 
   l_v_site_purchaddr2_textnode dbms_xmldom.DOMNode;

   l_v_site_purchaddr3_node dbms_xmldom.DOMNode; 
   l_v_site_purchaddr3_textnode dbms_xmldom.DOMNode;

   l_v_site_purchcity_node dbms_xmldom.DOMNode; 
   l_v_site_purchcity_textnode dbms_xmldom.DOMNode;

   l_v_site_purchstate_node dbms_xmldom.DOMNode; 
   l_v_site_purchstate_textnode dbms_xmldom.DOMNode;

   l_v_pur_add_state_abbre_n dbms_xmldom.DOMNode;
   l_v_pur_add_state_abbre_tn dbms_xmldom.DOMNode;

   l_v_site_purchzip_node dbms_xmldom.DOMNode; 
   l_v_site_purchzip_textnode dbms_xmldom.DOMNode;

   l_v_site_purchcountry_node dbms_xmldom.DOMNode; 
   l_v_site_purchcountry_textnode dbms_xmldom.DOMNode;

   l_v_orgcountry_node dbms_xmldom.DOMNode; --1
   l_v_orgcountry_textnode dbms_xmldom.DOMNode;

   l_v_site_pur_add_latitude_n dbms_xmldom.DOMNode;
   l_v_site_pur_add_latitude_tn dbms_xmldom.DOMNode;
   
   l_v_site_pur_add_longitude_n dbms_xmldom.DOMNode;
   l_v_site_pur_add_longitude_tn dbms_xmldom.DOMNode;

   l_v_site_pur_add_county_n dbms_xmldom.DOMNode;
   l_v_site_pur_add_county_tn dbms_xmldom.DOMNode;

   l_v_site_pur_add_district_n dbms_xmldom.DOMNode;
   l_v_site_pur_add_district_tn dbms_xmldom.DOMNode;

   l_v_site_pur_add_spe_notes_n dbms_xmldom.DOMNode;
   l_v_site_pur_add_spe_notes_tn dbms_xmldom.DOMNode;

   l_v_site_con_purfname_n dbms_xmldom.DOMNode;
   l_v_site_con_purfname_tn dbms_xmldom.DOMNode;

   l_v_site_con_purmname_n dbms_xmldom.DOMNode;
   l_v_site_con_purmname_tn dbms_xmldom.DOMNode;

   l_v_site_con_purlname_n dbms_xmldom.DOMNode;
   l_v_site_con_purlname_tn dbms_xmldom.DOMNode;

 
   l_v_site_con_purname_n dbms_xmldom.DOMNode; 
   l_v_site_con_purname_tn dbms_xmldom.DOMNode;

   l_v_site_con_purchph_n dbms_xmldom.DOMNode; 
   l_v_site_con_purchph_tn dbms_xmldom.DOMNode;

   l_v_site_con_purchfx_n dbms_xmldom.DOMNode; 
   l_v_site_con_purchfx_tn dbms_xmldom.DOMNode;

   l_v_site_con_purchemail_n dbms_xmldom.DOMNode; 
   l_v_site_con_purchemail_tn dbms_xmldom.DOMNode;

--
   l_v_site_payaddr_type_n  dbms_xmldom.DOMNode;
   l_v_site_payaddr_type_tn dbms_xmldom.DOMNode;
   
   l_v_site_payseqnum_n dbms_xmldom.DOMNode;
   l_v_site_payseqnum_tn dbms_xmldom.DOMNode;
   l_v_site_payaction_type_n dbms_xmldom.DOMNode;
   l_v_site_payaction_type_tn dbms_xmldom.DOMNode;


   l_v_site_pay_isprimaryaddr_n   dbms_xmldom.DOMNode;
   l_v_site_pay_isprimaryaddr_tn   dbms_xmldom.DOMNode;

   l_v_site_payaddr1_node dbms_xmldom.DOMNode; 
   l_v_site_payaddr1_textnode dbms_xmldom.DOMNode;

   l_v_site_payaddr2_node dbms_xmldom.DOMNode; 
   l_v_site_payaddr2_textnode dbms_xmldom.DOMNode;

   l_v_site_payaddr3_node dbms_xmldom.DOMNode; 
   l_v_site_payaddr3_textnode dbms_xmldom.DOMNode;

   l_v_site_paycity_node dbms_xmldom.DOMNode; 
   l_v_site_paycity_textnode dbms_xmldom.DOMNode;

   l_v_site_paystate_node dbms_xmldom.DOMNode; 
   l_v_site_paystate_textnode dbms_xmldom.DOMNode;

   l_v_pay_add_state_abbre_n dbms_xmldom.DOMNode;
   l_v_pay_add_state_abbre_tn dbms_xmldom.DOMNode;

   l_v_site_payzip_node dbms_xmldom.DOMNode; 
   l_v_site_payzip_textnode dbms_xmldom.DOMNode;

   l_v_site_paycountry_node dbms_xmldom.DOMNode; 
   l_v_site_paycountry_textnode dbms_xmldom.DOMNode;

--   l_v_orgcountry_node dbms_xmldom.DOMNode; --1
  -- l_v_orgcountry_textnode dbms_xmldom.DOMNode;

   l_v_site_pay_add_latitude_n dbms_xmldom.DOMNode;
   l_v_site_pay_add_latitude_tn dbms_xmldom.DOMNode;
   
   l_v_site_pay_add_longitude_n dbms_xmldom.DOMNode;
   l_v_site_pay_add_longitude_tn dbms_xmldom.DOMNode;

   l_v_site_pay_add_county_n dbms_xmldom.DOMNode;
   l_v_site_pay_add_county_tn dbms_xmldom.DOMNode;

   l_v_site_pay_add_district_n dbms_xmldom.DOMNode;
   l_v_site_pay_add_district_tn dbms_xmldom.DOMNode;

   l_v_site_pay_add_spe_notes_n dbms_xmldom.DOMNode;
   l_v_site_pay_add_spe_notes_tn dbms_xmldom.DOMNode;

   l_v_site_con_payfname_n dbms_xmldom.DOMNode;
   l_v_site_con_payfname_tn dbms_xmldom.DOMNode;

   l_v_site_con_paymname_n dbms_xmldom.DOMNode;
   l_v_site_con_paymname_tn dbms_xmldom.DOMNode;

   l_v_site_con_paylname_n dbms_xmldom.DOMNode;
   l_v_site_con_paylname_tn dbms_xmldom.DOMNode;


   l_v_site_con_payname_n dbms_xmldom.DOMNode; 
   l_v_site_con_payname_tn dbms_xmldom.DOMNode;

   l_v_site_con_payph_n dbms_xmldom.DOMNode; 
   l_v_site_con_payph_tn dbms_xmldom.DOMNode;

   l_v_site_con_payfx_n dbms_xmldom.DOMNode; 
   l_v_site_con_payfx_tn dbms_xmldom.DOMNode;

   l_v_site_con_payemail_n dbms_xmldom.DOMNode; 
   l_v_site_con_payemail_tn dbms_xmldom.DOMNode;

--
   l_v_site_ppaddr_type_n dbms_xmldom.DOMNode;
   l_v_site_ppaddr_type_tn dbms_xmldom.DOMNode;

   l_v_site_ppseqnum_n dbms_xmldom.DOMNode;
   l_v_site_ppseqnum_tn dbms_xmldom.DOMNode;
   l_v_site_ppaction_type_n dbms_xmldom.DOMNode;
   l_v_site_ppaction_type_tn dbms_xmldom.DOMNode;

   l_v_site_pp_isprimaryaddr_n   dbms_xmldom.DOMNode;
   l_v_site_pp_isprimaryaddr_tn   dbms_xmldom.DOMNode;

   l_v_site_ppaddr1_node dbms_xmldom.DOMNode; 
   l_v_site_ppaddr1_textnode dbms_xmldom.DOMNode;

   l_v_site_ppaddr2_node dbms_xmldom.DOMNode; 
   l_v_site_ppaddr2_textnode dbms_xmldom.DOMNode;

   l_v_site_ppaddr3_node dbms_xmldom.DOMNode; 
   l_v_site_ppaddr3_textnode dbms_xmldom.DOMNode;

   l_v_site_ppcity_node dbms_xmldom.DOMNode; 
   l_v_site_ppcity_textnode dbms_xmldom.DOMNode;

   l_v_site_ppstate_node dbms_xmldom.DOMNode; 
   l_v_site_ppstate_textnode dbms_xmldom.DOMNode;

   l_v_pp_add_state_abbre_n dbms_xmldom.DOMNode;
   l_v_pp_add_state_abbre_tn dbms_xmldom.DOMNode;

   l_v_site_ppzip_node dbms_xmldom.DOMNode; 
   l_v_site_ppzip_textnode dbms_xmldom.DOMNode;

   l_v_site_ppcountry_node dbms_xmldom.DOMNode; 
   l_v_site_ppcountry_textnode dbms_xmldom.DOMNode;

--   l_v_orgcountry_node dbms_xmldom.DOMNode; --1
  -- l_v_orgcountry_textnode dbms_xmldom.DOMNode;

   l_v_site_pp_add_latitude_n dbms_xmldom.DOMNode;
   l_v_site_pp_add_latitude_tn dbms_xmldom.DOMNode;
   
   l_v_site_pp_add_longitude_n dbms_xmldom.DOMNode;
   l_v_site_pp_add_longitude_tn dbms_xmldom.DOMNode;

   l_v_site_pp_add_county_n dbms_xmldom.DOMNode;
   l_v_site_pp_add_county_tn dbms_xmldom.DOMNode;

   l_v_site_pp_add_district_n dbms_xmldom.DOMNode;
   l_v_site_pp_add_district_tn dbms_xmldom.DOMNode;

   l_v_site_pp_add_spe_notes_n dbms_xmldom.DOMNode;
   l_v_site_pp_add_spe_notes_tn dbms_xmldom.DOMNode;

   l_v_site_con_ppfname_n dbms_xmldom.DOMNode;
   l_v_site_con_ppfname_tn dbms_xmldom.DOMNode;

   l_v_site_con_ppmname_n dbms_xmldom.DOMNode;
   l_v_site_con_ppmname_tn dbms_xmldom.DOMNode;

   l_v_site_con_pplname_n dbms_xmldom.DOMNode;
   l_v_site_con_pplname_tn dbms_xmldom.DOMNode;

   l_v_site_con_ppname_n dbms_xmldom.DOMNode; 
   l_v_site_con_ppname_tn dbms_xmldom.DOMNode;

   l_v_site_con_ppph_n dbms_xmldom.DOMNode; 
   l_v_site_con_ppph_tn dbms_xmldom.DOMNode;

   l_v_site_con_ppfx_n dbms_xmldom.DOMNode; 
   l_v_site_con_ppfx_tn dbms_xmldom.DOMNode;

   l_v_site_con_ppemail_n dbms_xmldom.DOMNode; 
   l_v_site_con_ppemail_tn dbms_xmldom.DOMNode;
--
   l_v_site_rtvaddr_type_n  dbms_xmldom.DOMNode; 
   l_v_site_rtvaddr_type_tn  dbms_xmldom.DOMNode;

   l_v_site_rtvseqnum_n  dbms_xmldom.DOMNode;
   l_v_site_rtvseqnum_tn  dbms_xmldom.DOMNode;
   
   l_v_site_rtvaction_type_n  dbms_xmldom.DOMNode;
   l_v_site_rtvaction_type_tn dbms_xmldom.DOMNode;

   l_v_site_rtv_isprimaryaddr_n   dbms_xmldom.DOMNode;
   l_v_site_rtv_isprimaryaddr_tn   dbms_xmldom.DOMNode;

   l_v_site_rtvaddr1_node dbms_xmldom.DOMNode; 
   l_v_site_rtvaddr1_textnode dbms_xmldom.DOMNode;

   l_v_site_rtvaddr2_node dbms_xmldom.DOMNode; 
   l_v_site_rtvaddr2_textnode dbms_xmldom.DOMNode;

   l_v_site_rtvaddr3_node dbms_xmldom.DOMNode; 
   l_v_site_rtvaddr3_textnode dbms_xmldom.DOMNode;

   l_v_site_rtvcity_node dbms_xmldom.DOMNode; 
   l_v_site_rtvcity_textnode dbms_xmldom.DOMNode;

   l_v_site_rtvstate_node dbms_xmldom.DOMNode; 
   l_v_site_rtvstate_textnode dbms_xmldom.DOMNode;

   l_v_rtv_add_state_abbre_n dbms_xmldom.DOMNode;
   l_v_rtv_add_state_abbre_tn dbms_xmldom.DOMNode;

   l_v_site_rtvzip_node dbms_xmldom.DOMNode; 
   l_v_site_rtvzip_textnode dbms_xmldom.DOMNode;

   l_v_site_rtvcountry_node dbms_xmldom.DOMNode; 
   l_v_site_rtvcountry_textnode dbms_xmldom.DOMNode;

--   l_v_orgcountry_node dbms_xmldom.DOMNode; --1
  -- l_v_orgcountry_textnode dbms_xmldom.DOMNode;

   l_v_site_rtv_add_latitude_n dbms_xmldom.DOMNode;
   l_v_site_rtv_add_latitude_tn dbms_xmldom.DOMNode;
   
   l_v_site_rtv_add_longitude_n dbms_xmldom.DOMNode;
   l_v_site_rtv_add_longitude_tn dbms_xmldom.DOMNode;

   l_v_site_rtv_add_county_n dbms_xmldom.DOMNode;
   l_v_site_rtv_add_county_tn dbms_xmldom.DOMNode;

   l_v_site_rtv_add_district_n dbms_xmldom.DOMNode;
   l_v_site_rtv_add_district_tn dbms_xmldom.DOMNode;

   l_v_site_rtv_add_spe_notes_n dbms_xmldom.DOMNode;
   l_v_site_rtv_add_spe_notes_tn dbms_xmldom.DOMNode;

   l_v_site_con_rtvfname_n dbms_xmldom.DOMNode;
   l_v_site_con_rtvfname_tn dbms_xmldom.DOMNode;

   l_v_site_con_rtvmname_n dbms_xmldom.DOMNode;
   l_v_site_con_rtvmname_tn dbms_xmldom.DOMNode;

   l_v_site_con_rtvlname_n dbms_xmldom.DOMNode;
   l_v_site_con_rtvlname_tn dbms_xmldom.DOMNode;


   l_v_site_con_rtvname_n dbms_xmldom.DOMNode; 
   l_v_site_con_rtvname_tn dbms_xmldom.DOMNode;

   l_v_site_con_rtvph_n dbms_xmldom.DOMNode; 
   l_v_site_con_rtvph_tn dbms_xmldom.DOMNode;

   l_v_site_con_rtvfx_n dbms_xmldom.DOMNode; 
   l_v_site_con_rtvfx_tn dbms_xmldom.DOMNode;

   l_v_site_con_rtvemail_n dbms_xmldom.DOMNode; 
   l_v_site_con_rtvemail_tn dbms_xmldom.DOMNode;

--Custom address
   l_v_addr_01_addr_type_node dbms_xmldom.DOMNode; 
   l_v_addr_01_addr_type_textnode dbms_xmldom.DOMNode;

   l_v_site_addr_01_seqnum_n dbms_xmldom.DOMNode;
   l_v_site_addr_01_seqnum_tn dbms_xmldom.DOMNode;
   l_v_site_addr_action_type_n dbms_xmldom.DOMNode;
   l_v_site_addr_action_type_tn dbms_xmldom.DOMNode;

   l_v_cust_add_isprimaryaddr_n dbms_xmldom.DOMNode;
   l_v_cust_add_isprimaryaddr_tn dbms_xmldom.DOMNode;

---------------------

   -- l_v_addr_01_addr_type_node dbms_xmldom.DOMNode; 
    --l_v_addr_01_addr_type_textnode dbms_xmldom.DOMNode;

    l_v_addr1_node dbms_xmldom.DOMNode; 
    l_v_addr1_textnode dbms_xmldom.DOMNode;

    l_v_addr2_node dbms_xmldom.DOMNode; 
    l_v_addr2_textnode dbms_xmldom.DOMNode;

    l_v_addr3_node dbms_xmldom.DOMNode; 
    l_v_addr3_textnode dbms_xmldom.DOMNode;

 
    l_v_addr_city_node dbms_xmldom.DOMNode; 
    l_v_addr_city_textnode dbms_xmldom.DOMNode;

    l_v_addr_state_node dbms_xmldom.DOMNode; 
    l_v_addr_state_textnode dbms_xmldom.DOMNode;
   
    l_v_add_state_abbre_n dbms_xmldom.DOMNode;
    l_v_add_state_abbre_tn dbms_xmldom.DOMNode;
 
    l_v_addr_zip_node dbms_xmldom.DOMNode; 
    l_v_addr_zip_textnode dbms_xmldom.DOMNode;

    l_v_addr_country_node dbms_xmldom.DOMNode; 
    l_v_addr_country_textnode dbms_xmldom.DOMNode;
    
    l_v_add_latitude_n dbms_xmldom.DOMNode;
    l_v_add_latitude_tn dbms_xmldom.DOMNode;

    l_v_add_longitude_n dbms_xmldom.DOMNode;
    l_v_add_longitude_tn dbms_xmldom.DOMNode;

    l_v_add_county_n dbms_xmldom.DOMNode;
    l_v_add_county_tn dbms_xmldom.DOMNode;

    l_v_add_district_n dbms_xmldom.DOMNode;
    l_v_add_district_tn dbms_xmldom.DOMNode;

    l_v_add_spe_notes_n dbms_xmldom.DOMNode;
    l_v_add_spe_notes_tn dbms_xmldom.DOMNode;

    l_v_site_con_addfname_n dbms_xmldom.DOMNode;
    l_v_site_con_addfname_tn dbms_xmldom.DOMNode;

    l_v_site_con_addmname_n dbms_xmldom.DOMNode;
    l_v_site_con_addmname_tn dbms_xmldom.DOMNode;

    l_v_site_con_addlname_n dbms_xmldom.DOMNode;
    l_v_site_con_addlname_tn dbms_xmldom.DOMNode;

    l_v_addr_con_name_node dbms_xmldom.DOMNode; 
    l_v_addr_con_name_textnode dbms_xmldom.DOMNode;

    l_v_addr_con_ph_node dbms_xmldom.DOMNode; 
    l_v_addr_con_ph_textnode dbms_xmldom.DOMNode;
   
    l_v_addr_con_fax_node dbms_xmldom.DOMNode; 
    l_v_addr_con_fax_textnode dbms_xmldom.DOMNode;

    l_v_addr_con_email_node dbms_xmldom.DOMNode; 
    l_v_addr_con_email_textnode dbms_xmldom.DOMNode;

--------------------
--Custom Address

  
---kff
   
    l_v_lead_time_node dbms_xmldom.DOMNode; 
    l_v_lead_time_textnode dbms_xmldom.DOMNode;

   l_v_back_order_flag_node dbms_xmldom.DOMNode; 
   l_v_back_order_flag_textnode dbms_xmldom.DOMNode;

  
   l_v_delivery_policy_node dbms_xmldom.DOMNode; 
   l_v_delivery_policy_textnode dbms_xmldom.DOMNode;

   l_v_min_prepaid_code_node dbms_xmldom.DOMNode; 
   l_v_min_prepaid_code_textnode dbms_xmldom.DOMNode;

   l_v_vendor_min_amount_node dbms_xmldom.DOMNode; 
   l_v_vendor_min_amount_textnode dbms_xmldom.DOMNode;

   l_v_supplier_ship_to_node dbms_xmldom.DOMNode; 
   l_v_supplier_ship_to_textnode dbms_xmldom.DOMNode;

   l_v_inventory_type_code_n dbms_xmldom.DOMNode; 
   l_v_inventory_type_code_tn dbms_xmldom.DOMNode;

   l_v_ver_market_indicator_n dbms_xmldom.DOMNode; 
   l_v_ver_market_indicator_tn dbms_xmldom.DOMNode;

   l_v_allow_auto_receipt_n dbms_xmldom.DOMNode; 
   l_v_allow_auto_receipt_tn dbms_xmldom.DOMNode;

   l_v_handling_node dbms_xmldom.DOMNode; 
   l_v_handling_textnode dbms_xmldom.DOMNode;

   l_v_eft_settle_days_node dbms_xmldom.DOMNode; 
   l_v_eft_settle_days_textnode dbms_xmldom.DOMNode;
   
   l_v_split_file_flag_node dbms_xmldom.DOMNode; 
   l_v_split_file_flag_textnode dbms_xmldom.DOMNode;

   l_v_master_vendor_id_node dbms_xmldom.DOMNode; 
   l_v_master_vendor_id_textnode dbms_xmldom.DOMNode;

   l_v_pi_pack_year_node dbms_xmldom.DOMNode; 
   l_v_pi_pack_year_textnode dbms_xmldom.DOMNode;

   l_v_od_date_signed_n dbms_xmldom.DOMNode; 
   l_v_od_date_signed_tn dbms_xmldom.DOMNode;

   l_v_ven_date_signed_n dbms_xmldom.DOMNode; 
   l_v_ven_date_signed_tn dbms_xmldom.DOMNode;

   l_v_deduct_from_inv_flag_n dbms_xmldom.DOMNode; 
   l_v_deduct_from_inv_flag_tn dbms_xmldom.DOMNode;

   l_v_new_store_flag_node dbms_xmldom.DOMNode; 
   l_v_new_store_flag_textnode dbms_xmldom.DOMNode;

   l_v_new_store_terms_node dbms_xmldom.DOMNode; 
   l_v_new_store_terms_textnode dbms_xmldom.DOMNode;
   
   l_v_seasonal_flag_node dbms_xmldom.DOMNode; 
   l_v_seasonal_flag_textnode dbms_xmldom.DOMNode;

   l_v_start_date_node dbms_xmldom.DOMNode; 
   l_v_start_date_textnode dbms_xmldom.DOMNode;

   l_v_end_date_node dbms_xmldom.DOMNode; 
   l_v_end_date_textnode dbms_xmldom.DOMNode;

   l_v_seasonal_terms_node dbms_xmldom.DOMNode; 
   l_v_seasonal_terms_textnode dbms_xmldom.DOMNode;

   l_v_late_ship_flag_node dbms_xmldom.DOMNode; 
   l_v_late_ship_flag_textnode dbms_xmldom.DOMNode;

   l_v_edi_distri_code_n dbms_xmldom.DOMNode; 
   l_v_edi_distri_code_tn dbms_xmldom.DOMNode;

   l_v_850_po_node dbms_xmldom.DOMNode; 
   l_v_850_po_textnode dbms_xmldom.DOMNode;

   l_v_860_po_change_n dbms_xmldom.DOMNode; 
   l_v_860_po_change_tn dbms_xmldom.DOMNode;

   l_v_855_confirm_po_n dbms_xmldom.DOMNode; 
   l_v_855_confirm_po_tn dbms_xmldom.DOMNode;

   l_v_856_asn_node dbms_xmldom.DOMNode; 
   l_v_856_asn_textnode dbms_xmldom.DOMNode;

   l_v_846_availability_node dbms_xmldom.DOMNode; 
   l_v_846_availability_textnode dbms_xmldom.DOMNode;

   l_v_810_invoice_node dbms_xmldom.DOMNode; 
   l_v_810_invoice_textnode dbms_xmldom.DOMNode;
  
   l_v_832_price_sales_cat_n dbms_xmldom.DOMNode; 
   l_v_832_price_sales_cat_tn dbms_xmldom.DOMNode;

   l_v_820_eft_node dbms_xmldom.DOMNode; 
   l_v_820_eft_textnode dbms_xmldom.DOMNode;

   l_v_861_damage_shortage_n dbms_xmldom.DOMNode; 
   l_v_861_damage_shortage_tn dbms_xmldom.DOMNode;

   l_v_852_sales_node dbms_xmldom.DOMNode; 
   l_v_852_sales_textnode dbms_xmldom.DOMNode;

   l_v_rtv_option_node dbms_xmldom.DOMNode; 
   l_v_rtv_option_textnode dbms_xmldom.DOMNode;

   l_v_rtv_freight_pay_method_n dbms_xmldom.DOMNode; 
   l_v_rtv_freight_pay_method_tn dbms_xmldom.DOMNode;

   l_v_permanent_rga_node dbms_xmldom.DOMNode; 
   l_v_permanent_rga_textnode dbms_xmldom.DOMNode;

   l_v_destroy_allow_amt_n dbms_xmldom.DOMNode; 
   l_v_destroy_allow_amt_tn dbms_xmldom.DOMNode;

   l_v_payment_freq_n dbms_xmldom.DOMNode; 
   l_v_payment_freq_tn dbms_xmldom.DOMNode;

   l_v_min_return_qty_node dbms_xmldom.DOMNode; 
   l_v_min_return_qty_textnode dbms_xmldom.DOMNode;

   l_v_min_return_amount_node dbms_xmldom.DOMNode; 
   l_v_min_return_amount_textnode dbms_xmldom.DOMNode;

   l_v_damage_dest_limit_n dbms_xmldom.DOMNode; 
   l_v_damage_dest_limit_tn dbms_xmldom.DOMNode;

   l_v_rtv_instr_n dbms_xmldom.DOMNode; 
   l_v_rtv_instr_tn dbms_xmldom.DOMNode;

   l_v_addl_rtv_instr_n dbms_xmldom.DOMNode; 
   l_v_addl_rtv_instr_tn dbms_xmldom.DOMNode;

   l_v_rga_marked_flag_n dbms_xmldom.DOMNode; 
   l_v_rga_marked_flag_tn dbms_xmldom.DOMNode;

   l_v_rmv_price_sticker_flag_n dbms_xmldom.DOMNode; 
   l_v_rmv_price_sticker_flag_tn dbms_xmldom.DOMNode;

   l_v_con_supp_rga_flag_n dbms_xmldom.DOMNode; 
   l_v_con_supp_rga_flag_tn dbms_xmldom.DOMNode;

   l_v_destroy_flag_node dbms_xmldom.DOMNode; 
   l_v_destroy_flag_textnode dbms_xmldom.DOMNode;

   l_v_ser_num_req_flag_n dbms_xmldom.DOMNode; 
   l_v_ser_num_req_flag_tn dbms_xmldom.DOMNode;

   l_v_obsolete_item_n dbms_xmldom.DOMNode; 
   l_v_obsolete_item_tn dbms_xmldom.DOMNode;

   l_v_obso_allow_pct_n dbms_xmldom.DOMNode; 
   l_v_obso_allow_pct_tn dbms_xmldom.DOMNode;

   l_v_obso_allow_days_n dbms_xmldom.DOMNode; 
   l_v_obso_allow_days_tn dbms_xmldom.DOMNode;

   l_v_od_cont_sig_n dbms_xmldom.DOMNode; 
   l_v_od_cont_sig_tn dbms_xmldom.DOMNode;

   l_v_od_cont_title_n dbms_xmldom.DOMNode; 
   l_v_od_cont_title_tn dbms_xmldom.DOMNode;

   l_v_od_ven_sig_name_n dbms_xmldom.DOMNode; 
   l_v_od_ven_sig_name_tn dbms_xmldom.DOMNode;

   l_v_od_ven_sig_title_n dbms_xmldom.DOMNode; 
   l_v_od_ven_sig_title_tn dbms_xmldom.DOMNode;

   l_v_gss_mfg_id_n dbms_xmldom.DOMNode; 
   l_v_gss_mfg_id_tn dbms_xmldom.DOMNode;

   l_v_gss_buying_agent_id_n dbms_xmldom.DOMNode; 
   l_v_gss_buying_agent_id_tn dbms_xmldom.DOMNode;

   l_v_gss_freight_id_n dbms_xmldom.DOMNode; 
   l_v_gss_freight_id_tn dbms_xmldom.DOMNode;

   l_v_gss_ship_id_n dbms_xmldom.DOMNode; 
   l_v_gss_ship_id_tn dbms_xmldom.DOMNode;

  v_transaction_id number;
  sup_trait_rows  number :=0;

 --Cursor for custom address details
CURSOR c_address_data IS
SELECT addr_type,seq_no,add_1, add_2,add_3,city, state, post ,country_id,contact_name, contact_phone,contact_fax,contact_email from xx_ap_sup_vendor_contact
WHERE key_value_1=v_vendor_site_id--816190
ORDER BY addr_type;-- and addr_type IN ('01','03');
--
--Cursor for Business Classification codes and meaning.

CURSOR c_bus_class IS 
    SELECT attribute1,meaning
FROM fnd_lookup_values_vl
WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
ORDER BY to_number(ATTRIBUTE1);

--
--Cursor for Supplier Traits and descriptions
CURSOR c_sup_traits IS
SELECT matrix.sup_trait sup_trait, traits.description description, traits.master_sup_ind master_sup_ind
FROM xx_ap_sup_traits  traits ,xx_ap_sup_traits_matrix matrix
WHERE traits.sup_trait=matrix.sup_trait
AND traits.enable_flag='Y'
AND matrix.enable_flag='Y'
 AND matrix.supplier=v_vendor_site_id;

BEGIN
--Generate unique transaction id for every transaction
-- DBMS_OUTPUT.PUT_LINE('LINE 1756 RMS count'||v_rms_count);
SELECT supplier_seq.nextval INTO v_transaction_id FROM dual;

--Insert into custom table for tracking purpose

INSERT INTO XX_AP_SUP_OUTBOUND_TRACK VALUES (v_transaction_id,v_globalvendor_id,v_name,v_vendor_site_id,v_vendor_site_code,v_site_orgid,sysdate);

  if v_site_orgid = 403 then
     v_orgcountry := 'CA';
  end if;
  if v_site_orgid = 404 then 
     v_orgcountry := 'US';
  end if;
  
     -- Create an empty XML document
   l_domdoc := dbms_xmldom.newDomDocument;

   -- Create a root node
   l_root_node := dbms_xmldom.makeNode(l_domdoc);


   -- Create a new node Supplier and add it to the root node
   l_supplier_list_node := dbms_xmldom.appendChild( l_root_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SupplierList' ))
                                               );
--
   -- Create a new node Business class and add it to the supplier node
   l_supplier_node := dbms_xmldom.appendChild( l_supplier_list_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'supplier' ))
                                                );


--
   -- Create a new node supplier header and add it to the supplier node
   l_supp_header_node := dbms_xmldom.appendChild( l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'supplierHeader' ))
                                                );

   -- Each Supp node will get a Name node which contains the Supplier name as text
      l_trans_id_node := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'transactionId' ))
                                            );
      l_trans_id_textnode := dbms_xmldom.appendChild( l_trans_id_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_transaction_id ))
                                                );
   
   -- Each Supp node will get a globalvendorid
      l_globalvendor_id_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'globalVendorId' ))
                                            );
      l_globalvendor_id_tn := dbms_xmldom.appendChild( l_globalvendor_id_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_globalvendor_id ))
                                                );

      -- Each Supp node will get a Name node which contains the Supplier name as text
      l_name_node := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'vendorName' ))
                                            );
      l_name_textnode := dbms_xmldom.appendChild( l_name_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_name ))
                                                );
                                                
      -- Each Site node will get a Vendor Site Id
      l_Vendor_site_id_node := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'vendorSiteId' ))
                                                );
      l_Vendor_site_id_textnode := dbms_xmldom.appendChild( l_Vendor_site_id_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_vendor_site_id)) 
                                                    );

      -- Each site node will get a Vendor Site Code
      l_Vendor_site_code_node := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'vendorSiteCode' ))
                                                );
      l_Vendor_site_code_textnode := dbms_xmldom.appendChild( l_Vendor_site_code_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_vendor_site_code)) 
                                                    );
   -- Each Site node will get a Vendor Address Flag
   --   l_Vendor_Address_Flag_node := dbms_xmldom.appendChild( l_supplier_node
     ---                                           , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addr_flag' ))
        --                                        );
     -- l_Vendor_Address_Flag_textnode := dbms_xmldom.appendChild( l_Vendor_Address_Flag_node
       --                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_addr_flag)) 
         --                                           );
                                          
   -- Each Site node will get a Inactive date
      l_v_inactive_date_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'inactiveDate' ))
                                                );
      l_v_inactive_date_tn := dbms_xmldom.appendChild( l_v_inactive_date_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_inactive_date)) 
                                                    );
    -- Each Site node will get a Payment_Currency Code
     l_v_pay_cur_code_node := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'paymentCurrencyCode' ))
                                                );
      l_v_pay_cur_code_textnode := dbms_xmldom.appendChild( l_v_pay_cur_code_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_payment_currency_code)) 
);

-- Each Site node will get a Site Language
      l_v_site_lang_node := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'siteLanguage' ))
                                                );
      l_v_site_lang_textnode := dbms_xmldom.appendChild( l_v_site_lang_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_lang)) 
);


-- Each Site node will get a Pay Site Flag
      l_v_pay_site_flag_node := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'paySiteFlag' ))
                                                );
      l_v_pay_site_flag_textnode := dbms_xmldom.appendChild( l_v_pay_site_flag_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_pay_site_flag)) 
);


-- Each Site node will get a Purchasing Site Flag
      l_v_purch_site_flag_node := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'purchasingSiteFlag' ))
                                                );
      l_v_purch_site_flag_textnode := dbms_xmldom.appendChild( l_v_purch_site_flag_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_purchasing_site_flag)) 
);

-- Each Site node will get a site Terms Name
      l_v_site_terms_name_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'siteTermsName' ))
                                                );
      l_v_site_terms_name_tn := dbms_xmldom.appendChild( l_v_site_terms_name_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_terms_name)) 
);

-- Each Site node will get a site Terms Name Desc
      l_v_site_terms_name_desc_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'siteTermsNameDescription' ))
                                                );
      l_v_site_terms_name_desc_tn := dbms_xmldom.appendChild( l_v_site_terms_name_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_terms_name_desc)) 
);

-- Each Site node will get a site Freight Terms
      l_v_site_freightterms_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'siteFreightTerms' ))
                                                );
      l_v_site_freightterms_tn := dbms_xmldom.appendChild( l_v_site_freightterms_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_freightterms)) 
);

-- Each Site node will get a Debit Memo Flag
      l_v_debit_memo_flag_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'debitMemoFlag' ))
                                                );
      l_v_debit_memo_flag_tn := dbms_xmldom.appendChild( l_v_debit_memo_flag_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_debit_memo_flag)) 
);



-- Each Site node will get a DUNS Num
      l_v_duns_num_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'dunsNum' ))
                                                );
      l_v_duns_num_tn := dbms_xmldom.appendChild( l_v_duns_num_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_duns_num)) 
);

-- Each Site node will get a  Tax Reg Num
      l_v_tax_reg_num_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'taxRegNum' ))
                                                );
      l_v_tax_reg_num_tn := dbms_xmldom.appendChild( l_v_tax_reg_num_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_tax_reg_num)) 
);

--


-- Each Site node will get a  Primary Paysite Flag
      l_v_primary_paysite_flag_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'primaryPaySiteFlag' ))
                                                );
      l_v_primary_paysite_flag_tn := dbms_xmldom.appendChild( l_v_primary_paysite_flag_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_primary_paysite_flag)) 
);

-- Each Site node will get a site category
      l_v_site_category_n := dbms_xmldom.appendChild(l_supp_header_node-- l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'siteCategory' ))
                                                );
      l_v_site_category_tn := dbms_xmldom.appendChild( l_v_site_category_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_attribute8)) 
);


-- Each Site node will get a Bank Acc Num
      l_v_bank_account_num_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'bankAccountNumber' ))
                                                );
      l_v_bank_account_num_tn := dbms_xmldom.appendChild( l_v_bank_account_num_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_bank_account_num)) 
);

-- Each Site node will get a Bank Acc Name
      l_v_bank_account_name_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'bankAccountName' ))
                                                );
      l_v_bank_account_name_tn := dbms_xmldom.appendChild( l_v_bank_account_name_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_bank_account_name)) 
);

-- Each Site node will get a Bank Acc Name
      l_v_related_pay_site_n := dbms_xmldom.appendChild( l_supp_header_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'relatedPaySite' ))
                                                );
      l_v_related_pay_site_tn := dbms_xmldom.appendChild( l_v_related_pay_site_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_attribute13)) 
);

--
   -- Create a new node Business class and add it to the supplier node
   l_bus_class_node := dbms_xmldom.appendChild( l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'businessClass' ))
                                                );
-- Each business class node will get a  Minority Class
      l_v_minority_class_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'minorityClass' ))
                                                );
      l_v_minority_class_tn := dbms_xmldom.appendChild( l_v_minority_class_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_minority_class)) 
);

-- Each business class node will get a  Minority Code
      l_v_minority_cd_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'minorityCode' ))
                                                );
      l_v_minority_cd_tn := dbms_xmldom.appendChild( l_v_minority_cd_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_minority_cd)) 
);

--dbms_output.put_line('v_minority_cd'||v_minority_cd);
--dbms_output.put_line('v_minority_class'||v_minority_class);
--dbms_output.put_line('attribute16'||v_attribute16);

--
BEGIN
   IF v_minority_cd IS NOT NULL
   THEN
   SELECT meaning INTO v_minority_cd_desc--,DESCRIPTION--*
        FROM FND_LOOKUP_VALUES_VL
   WHERE Lookup_type = 'MINORITY GROUP'
   AND attribute_category = 'MINORITY GROUP'
   AND lookup_code=v_minority_cd;
   END IF;
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting minority_cd_desc'||SQLERRM);
  dbms_output.put_line('Error getting minority_cd_desc');
END;
-- Each business class node will get a  Minority Code desc
      l_v_minority_cd_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'minorityCodeDescription' ))
                                                );
      l_v_minority_cd_desc_tn := dbms_xmldom.appendChild( l_v_minority_cd_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_minority_cd_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16, ';',1,1)+1, 
        INSTR(v_attribute16, ';',1,2)-(INSTR(v_attribute16, ';',1,1)+1)) into v_mbe
 FROM dual;

-- Each business class node will get a  MBE
      l_v_mbe_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'mbe' ))
                                                );
      l_v_mbe_tn := dbms_xmldom.appendChild( l_v_mbe_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_mbe)) 
);

BEGIN
    SELECT    meaning INTO v_mbe_desc
    FROM fnd_lookup_values_vl
    WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code='MBE';
EXCEPTION
    WHEN OTHERS THEN
    fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_mbe_desc'||SQLERRM);
    dbms_output.put_line('Error getting v_mbe_desc');
END;
-- Each business class node will get a  MBE desc
      l_v_mbe_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'mbeDescription' ))
                                               );
      l_v_mbe_desc_tn := dbms_xmldom.appendChild( l_v_mbe_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_mbe_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16, ';',1,2)+1, 
 INSTR(v_attribute16, ';',1,3)-(INSTR(v_attribute16, ';',1,2)+1)) into v_nmsdc
 FROM dual;

-- Each business class node will get a nmsdc 
      l_v_nmsdc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'nmsdc' ))
                                                );
      l_v_nmsdc_tn := dbms_xmldom.appendChild( l_v_nmsdc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_nmsdc)) 
);

 BEGIN
    SELECT    meaning INTO v_nmsdc_desc
    FROM fnd_lookup_values_vl
    WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code='NMSDC';
EXCEPTION
    WHEN OTHERS THEN
    fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_nmsdc_desc'||SQLERRM);
    dbms_output.put_line('Error getting v_nmsdc_desc');
END;
-- Each business class node will get a nmsdc desc
      l_v_nmsdc_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'nmsdcDescription' ))
                                              );
      l_v_nmsdc_desc_tn := dbms_xmldom.appendChild( l_v_nmsdc_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_nmsdc_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16, ';',1,3)+1, 
 INSTR(v_attribute16, ';',1,4)-(INSTR(v_attribute16, ';',1,3)+1)) into v_wbe
 FROM dual;

-- Each business class node will get a wbe
      l_v_wbe_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'wbe' ))
                                                );
      l_v_wbe_tn := dbms_xmldom.appendChild( l_v_wbe_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_wbe)) 
);

BEGIN
   SELECT    meaning INTO v_wbe_desc
   FROM fnd_lookup_values_vl
   WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
   AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
   AND lookup_code='WBE';
EXCEPTION
   WHEN OTHERS THEN
   fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_wbe_desc'||SQLERRM);
   dbms_output.put_line('Error getting v_wbe_desc');
END;
-- Each business class node will get a wbe desc
      l_v_wbe_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'wbeDescription' ))
                                                );
      l_v_wbe_desc_tn := dbms_xmldom.appendChild( l_v_wbe_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_wbe_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16, ';',1,4)+1, 
 INSTR(v_attribute16, ';',1,5)-(INSTR(v_attribute16, ';',1,4)+1)) into v_wbenc
 FROM dual;

-- Each business class node will get a wbenc
      l_v_wbenc_n := dbms_xmldom.appendChild( l_bus_class_node
                                               , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'wbenc' ))
                                                );
      l_v_wbenc_tn := dbms_xmldom.appendChild( l_v_wbenc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_wbenc)) 
);

BEGIN
   SELECT    meaning INTO v_wbenc_desc
   FROM fnd_lookup_values_vl
   WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
   AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
   AND lookup_code='WBENC';
EXCEPTION
   WHEN OTHERS THEN
   fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_wbenc_desc'||SQLERRM);
   dbms_output.put_line('Error getting v_wbenc_desc');
END;

-- Each business class node will get a wbenc desc
      l_v_wbenc_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'wbencDescription' ))
                                                );
      l_v_wbenc_desc_tn := dbms_xmldom.appendChild( l_v_wbenc_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_wbenc_desc)) 
);


 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16, ';',1,5)+1, 
 INSTR(v_attribute16, ';',1,6)-(INSTR(v_attribute16, ';',1,5)+1)) into v_vob
 FROM dual;

-- Each business class node will get a vob
      l_v_vob_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'vob' ))
                                                );
      l_v_vob_tn := dbms_xmldom.appendChild( l_v_vob_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_vob)) 
);

BEGIN
   SELECT    meaning INTO v_vob_desc
   FROM fnd_lookup_values_vl
   WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
   AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
   AND lookup_code='VOB';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_vob_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_vob_desc');
END;
-- Each business class node will get a vob desc
      l_v_vob_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'vobDescription' ))
                                                );
      l_v_vob_desc_tn := dbms_xmldom.appendChild( l_v_vob_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_vob_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16, ';',1,6)+1, 
 INSTR(v_attribute16, ';',1,7)-(INSTR(v_attribute16, ';',1,6)+1)) into v_dodva
 FROM dual;

-- Each business class node will get a dodva
      l_v_dodva_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'dodva' ))
                                                );
      l_v_dodva_tn := dbms_xmldom.appendChild( l_v_dodva_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_dodva)) 
);

BEGIN
   SELECT    meaning INTO v_dodva_desc
   FROM fnd_lookup_values_vl
   WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
   AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
   AND lookup_code='DODVA';
EXCEPTION
   WHEN OTHERS THEN
   fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_dodva_desc'||SQLERRM);
   dbms_output.put_line('Error getting v_dodva_desc');
END;
-- Each business class node will get a dodva desc
      l_v_dodva_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'dodvaDescription' ))
                                                );
      l_v_dodva_desc_tn := dbms_xmldom.appendChild( l_v_dodva_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_dodva_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16, ';',1,7)+1, 
 INSTR(v_attribute16, ';',1,8)-(INSTR(v_attribute16, ';',1,7)+1)) into v_doe
 FROM dual;


-- Each business class node will get a doe
      l_v_doe_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'doe' ))
                                                );
      l_v_doe_tn := dbms_xmldom.appendChild( l_v_doe_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_doe)) 
);

BEGIN
   SELECT    meaning INTO v_doe_desc
   FROM fnd_lookup_values_vl
   WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
   AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
   AND lookup_code='DOE';
EXCEPTION
   WHEN OTHERS THEN
   fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_doe_desc'||SQLERRM);
   dbms_output.put_line('Error getting v_doe_desc');
END;
-- Each business class node will get a doe desc
      l_v_doe_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'doeDescription' ))
                                                );
      l_v_doe_desc_tn := dbms_xmldom.appendChild( l_v_doe_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_doe_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16, ';',1,8)+1, 
 INSTR(v_attribute16, ';',1,9)-(INSTR(v_attribute16, ';',1,8)+1)) into v_usbln
 FROM dual;

-- Each business class node will get a usbln
      l_v_usbln_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'usbln' ))
                                                );
      l_v_usbln_tn := dbms_xmldom.appendChild( l_v_usbln_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_usbln)) 
);

BEGIN
  SELECT    meaning INTO v_usbln_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'  
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='USBLN';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_usbln_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_usbln_desc');
END;
-- Each business class node will get a usbln desc
      l_v_usbln_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'usblnDescription' ))
                                                );
      l_v_usbln_desc_tn := dbms_xmldom.appendChild( l_v_usbln_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_usbln_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16, ';',1,9)+1, 
 INSTR(v_attribute16, ';',1,10)-(INSTR(v_attribute16, ';',1,9)+1)) into v_lgbt
 FROM dual;

-- Each business class node will get a lgbt
      l_v_lgbt_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'lgbt' ))
                                                );
      l_v_lgbt_tn := dbms_xmldom.appendChild( l_v_lgbt_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_lgbt)) 
);
BEGIN
   SELECT    meaning INTO v_lgbt_desc
   FROM fnd_lookup_values_vl
   WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
   AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
   AND lookup_code='LGBT';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_lgbt_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_lgbt_desc');
END;
-- Each business class node will get a lgbt desc
      l_v_lgbt_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'lgbtDescription' ))
                                                );
      l_v_lgbt_desc_tn := dbms_xmldom.appendChild( l_v_lgbt_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_lgbt_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16, ';',1,10)+1, 
 INSTR(v_attribute16, ';',1,11)-(INSTR(v_attribute16, ';',1,10)+1)) into v_nglcc
 FROM dual;

-- Each business class node will get a nglcc
      l_v_nglcc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'nglcc' ))
                                                );
      l_v_nglcc_tn := dbms_xmldom.appendChild( l_v_nglcc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_nglcc)) 
);

BEGIN
  SELECT    meaning INTO v_nglcc_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='NGLCC';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_nglcc_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_nglcc_desc');
END;
-- Each business class node will get a nglcc desc
      l_v_nglcc_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'nglccDescription' ))
                                                );
      l_v_nglcc_desc_tn := dbms_xmldom.appendChild( l_v_nglcc_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_nglcc_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16, ';',1,11)+1, 
 INSTR(v_attribute16, ';',1,12)-(INSTR(v_attribute16, ';',1,11)+1)) into v_nibnishablty
 FROM dual;

-- Each business class node will get a nibnishablty
      l_v_nibnishablty_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'nibnishablty' ))
                                               );
      l_v_nibnishablty_tn := dbms_xmldom.appendChild( l_v_nibnishablty_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_nibnishablty)) 
);

BEGIN
   SELECT    meaning INTO v_nibnishablty_desc
   FROM fnd_lookup_values_vl
   WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
   AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
   AND lookup_code='NIBNISHABLTY';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_nibnishablty_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_nibnishablty_desc');
END;
-- Each business class node will get a nibnishablty desc
      l_v_nibnishablty_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'nibnishabltyDescription' ))
                                                );
      l_v_nibnishablty_desc_tn := dbms_xmldom.appendChild( l_v_nibnishablty_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_nibnishablty_desc)) 
);
--FOB

--dbms_output.put_line ('v_attribute16 FOB--'||v_attribute16);
 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,12)+1, INSTR(v_attribute16, ';',1,13)-(INSTR(v_attribute16, ';',1,12)+1))
 INTO  v_fob FROM dual;
--dbms_output.put_line ('v_fob'||v_fob);

-- Each business class node will get a fob
      l_v_fob_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fob' ))
                                                );
      l_v_fob_tn := dbms_xmldom.appendChild( l_v_fob_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_fob)) 
);
--dbms_output.put_line('v_fob'||v_fob);
BEGIN
  IF v_fob <> 'N'
  THEN
  SELECT meaning INTO v_fob_desc--,DESCRIPTION--*
  FROM FND_LOOKUP_VALUES_VL
  WHERE Lookup_type = 'FOREIGN_OWN_BUS'
  AND attribute_category = 'FOREIGN_OWN_BUS'
  AND lookup_code=v_fob;
ELSE
  SELECT    meaning INTO v_fob_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='FOB';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_fob_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_fob_desc');
END;
-- Each business class node will get a fob desc
      l_v_fob_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fobDescription' ))
                                                );
      l_v_fob_desc_tn := dbms_xmldom.appendChild( l_v_fob_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_fob_desc)) 
);
 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,13)+1, INSTR(v_attribute16, ';',1,14)-(INSTR(v_attribute16, ';',1,13)+1))
 INTO  v_sb FROM dual;

-- Each business class node will get a sb
      l_v_sb_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sb' ))
                                                );
      l_v_sb_tn := dbms_xmldom.appendChild( l_v_sb_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sb)) 
);

BEGIN
   SELECT    meaning INTO v_sb_desc
   FROM fnd_lookup_values_vl
   WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
   AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
   AND lookup_code='SB';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_sb_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_sb_desc');
END;
-- Each business class node will get a sb desc
      l_v_sb_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sbDescription' ))
                                                );
      l_v_sb_desc_tn := dbms_xmldom.appendChild( l_v_sb_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sb_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,14)+1, INSTR(v_attribute16, ';',1,15)-(INSTR(v_attribute16, ';',1,14)+1))
 INTO  v_samgov FROM dual;

-- Each business class node will get a samgov
      l_v_samgov_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'samgov' ))
                                                );
      l_v_samgov_tn := dbms_xmldom.appendChild( l_v_samgov_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_samgov)) 
);

BEGIN
  SELECT    meaning INTO v_samgov_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='SAMGOV';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_samgov_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_samgov_desc');
END;
-- Each business class node will get a samgov desc
      l_v_samgov_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                               , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'samgovDescription' ))
                                                );
      l_v_samgov_desc_tn := dbms_xmldom.appendChild( l_v_samgov_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_samgov_desc)) 
);

 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,15)+1, INSTR(v_attribute16, ';',1,16)-(INSTR(v_attribute16, ';',1,15)+1))
 INTO  v_sba FROM dual;

-- Each business class node will get a sba
      l_v_sba_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sba' ))
                                                );
      l_v_sba_tn := dbms_xmldom.appendChild( l_v_sba_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sba)) 
);
BEGIN
  SELECT    meaning INTO v_sba_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='SBA';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_sba_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_sba_desc');
END;
-- Each business class node will get a sba desc
      l_v_sba_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sbaDescription' ))
                                                );
      l_v_sba_desc_tn := dbms_xmldom.appendChild( l_v_sba_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sba_desc)) 
);


 SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,16)+1, INSTR(v_attribute16, ';',1,17)-(INSTR(v_attribute16, ';',1,16)+1))
 INTO  v_sbc FROM dual;


-- Each business class node will get a sbc
      l_v_sbc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sbc' ))
                                                );
      l_v_sbc_tn := dbms_xmldom.appendChild( l_v_sbc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sbc)) 
);

BEGIN
  SELECT    meaning INTO v_sbc_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='SBC';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_sbc_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_sbc_desc');
END;
-- Each business class node will get a sbc desc
      l_v_sbc_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sbcDescription' ))
                                                );
      l_v_sbc_desc_tn := dbms_xmldom.appendChild( l_v_sbc_desc_n
                                                   , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sbc_desc)) 
);

SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,17)+1, INSTR(v_attribute16, ';',1,18)-(INSTR(v_attribute16, ';',1,17)+1))
 INTO  v_sdbe FROM dual;

-- Each business class node will get a sdbe
      l_v_sdbe_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sdbe' ))
                                                );
      l_v_sdbe_tn := dbms_xmldom.appendChild( l_v_sdbe_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sdbe)) 
);

BEGIN
  SELECT    meaning INTO v_sdbe_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='SDBE';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_sdbe_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_sdbe_desc');
END;
-- Each business class node will get a sdbe desc
      l_v_sdbe_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sdbeDescription' ))
                                                );
      l_v_sdbe_desc_tn := dbms_xmldom.appendChild( l_v_sdbe_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sdbe_desc)) 
);

SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,18)+1, INSTR(v_attribute16, ';',1,19)-(INSTR(v_attribute16, ';',1,18)+1))
 INTO  v_sba8a FROM dual;


-- Each business class node will get a sba8a
      l_v_sba8a_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sba8a' ))
                                                );
      l_v_sba8a_tn := dbms_xmldom.appendChild( l_v_sba8a_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sba8a)) 
);

BEGIN
  SELECT    meaning INTO v_sba8a_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='SBA8A';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_sba8a_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_sba8a_desc');
END;
-- Each business class node will get a sba8a desc
      l_v_sba8a_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sba8aDescription' ))
                                                );
      l_v_sba8a_desc_tn := dbms_xmldom.appendChild( l_v_sba8a_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sba8a_desc)) 
);

SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,19)+1, INSTR(v_attribute16, ';',1,20)-(INSTR(v_attribute16, ';',1,19)+1))
 INTO  v_hubzone FROM dual;

-- Each business class node will get a hubzone
      l_v_hubzone_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'hubzone' ))
                                                );
      l_v_hubzone_tn := dbms_xmldom.appendChild( l_v_hubzone_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_hubzone)) 
);

BEGIN
  SELECT    meaning INTO v_hubzone_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='HUBZONE';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_hubzone_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_hubzone_desc');
END;
-- Each business class node will get a hubzone desc
     l_v_hubzone_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'hubzoneDescription' ))
                                                );
      l_v_hubzone_desc_tn := dbms_xmldom.appendChild( l_v_hubzone_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_hubzone_desc)) 
);
SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,20)+1, INSTR(v_attribute16, ';',1,21)-(INSTR(v_attribute16, ';',1,20)+1))
 INTO  v_wosb FROM dual;


-- Each business class node will get a wosb
      l_v_wosb_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'wosb' ))
                                                );
      l_v_wosb_tn := dbms_xmldom.appendChild( l_v_wosb_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_wosb)) 
);

BEGIN
  SELECT    meaning INTO v_wosb_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='WOSB';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_wosb_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_wosb_desc');
END;
-- Each business class node will get a wosb desc
      l_v_wosb_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                               , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'wosbDescription' ))
                                                );
      l_v_wosb_desc_tn := dbms_xmldom.appendChild( l_v_wosb_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_wosb_desc)) 
);


SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,21)+1, INSTR(v_attribute16, ';',1,22)-(INSTR(v_attribute16, ';',1,21)+1))
 INTO  v_wsbe FROM dual;

-- Each business class node will get a wsbe
     l_v_wsbe_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'wsbe' ))
                                                );
      l_v_wsbe_tn := dbms_xmldom.appendChild( l_v_wsbe_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_wsbe)) 
);

BEGIN
  SELECT    meaning INTO v_wsbe_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='WSBE';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_wsbe_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_wsbe_desc');
END;
-- Each business class node will get a wsbe desc
      l_v_wsbe_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'wsbeDescription' ))
                                                );
      l_v_wsbe_desc_tn := dbms_xmldom.appendChild( l_v_wsbe_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_wsbe_desc)) 
);

SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,22)+1, INSTR(v_attribute16, ';',1,23)-(INSTR(v_attribute16, ';',1,22)+1))
 INTO  v_edwosb FROM dual;

-- Each business class node will get a edwosb
      l_v_edwosb_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'edwosb' ))
                                                );
      l_v_edwosb_tn := dbms_xmldom.appendChild( l_v_edwosb_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_edwosb)) 
);

BEGIN
  SELECT    meaning INTO v_edwosb_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='EDWOSB';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_edwosb_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_edwosb_desc');
END;

-- Each business class node will get a edwosb desc
      l_v_edwosb_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'edwosbDescription' ))
                                                );
      l_v_edwosb_desc_tn := dbms_xmldom.appendChild( l_v_edwosb_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_edwosb_desc)) 
);


SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,23)+1, INSTR(v_attribute16, ';',1,24)-(INSTR(v_attribute16, ';',1,23)+1))
 INTO  v_vosb FROM dual;

-- Each business class node will get a vosb
      l_v_vosb_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'vosb' ))
                                                );
      l_v_vosb_tn := dbms_xmldom.appendChild( l_v_vosb_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_vosb)) 
);

BEGIN
  SELECT meaning INTO v_vosb_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='VOSB';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_vosb_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_vosb_desc');
END;

-- Each business class node will get a vosb desc
      l_v_vosb_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'vosbDescription' ))
                                                );
      l_v_vosb_desc_tn := dbms_xmldom.appendChild( l_v_vosb_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_vosb_desc)) 
);

SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,24)+1, INSTR(v_attribute16, ';',1,25)-(INSTR(v_attribute16, ';',1,24)+1))
 INTO  v_sdvosb FROM dual;


-- Each business class node will get a sdvosb
      l_v_sdvosb_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sdvosb' ))
                                                );
      l_v_sdvosb_tn := dbms_xmldom.appendChild( l_v_sdvosb_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sdvosb)) 
);

BEGIN
  SELECT meaning INTO v_sdvosb_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='SDVOSB';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_sdvosb_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_sdvosb_desc');
END;

-- Each business class node will get a sdvosb desc
      l_v_sdvosb_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sdvosbDescription' ))
                                                );
      l_v_sdvosb_desc_tn := dbms_xmldom.appendChild( l_v_sdvosb_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_sdvosb_desc)) 
);


SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,25)+1, INSTR(v_attribute16, ';',1,26)-(INSTR(v_attribute16, ';',1,25)+1))
 INTO  v_hbcumi FROM dual;

-- Each business class node will get a hbcumi
      l_v_hbcumi_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'hbcumi' ))
                                                );
      l_v_hbcumi_tn := dbms_xmldom.appendChild( l_v_hbcumi_n
                                                   , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_hbcumi)) 
);

BEGIN
  SELECT  meaning INTO v_hbcumi_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='HBCUMI';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_hbcumi_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_hbcumi_desc');
END;

-- Each business class node will get a hbcumi desc
      l_v_hbcumi_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'hbcumiDescription' ))
                                                );
      l_v_hbcumi_desc_tn := dbms_xmldom.appendChild( l_v_hbcumi_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_hbcumi_desc)) 
);

SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,26)+1, INSTR(v_attribute16, ';',1,27)-(INSTR(v_attribute16, ';',1,26)+1))
 INTO  v_anc FROM dual;

-- Each business class node will get a anc
      l_v_anc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'anc' ))
                                                );
      l_v_anc_tn := dbms_xmldom.appendChild( l_v_anc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_anc)) 
);

BEGIN
  SELECT meaning INTO v_anc_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='ANC';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_anc_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_anc_desc');
END;

-- Each business class node will get a anc desc
      l_v_anc_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ancDescription' ))
                                                );
      l_v_anc_desc_tn := dbms_xmldom.appendChild( l_v_anc_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_anc_desc)) 
);

SELECT SUBSTR(v_attribute16, INSTR(v_attribute16,';',1,27)+1, INSTR(v_attribute16, ';',1,28)-(INSTR(v_attribute16, ';',1,27)+1))
 INTO  v_ind FROM dual;


-- Each business class node will get a ind
      l_v_ind_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ind' ))
                                                );
      l_v_ind_tn := dbms_xmldom.appendChild( l_v_ind_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_ind)) 
);

BEGIN
  SELECT  meaning INTO v_ind_desc
  FROM fnd_lookup_values_vl
  WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  AND lookup_code='IND';
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_ind_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_ind_desc');
END;
-- Each business class node will get a ind desc
      l_v_ind_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'indDescription' ))
                                                );
      l_v_ind_desc_tn := dbms_xmldom.appendChild( l_v_ind_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_ind_desc)) 
);
--Minority_owned
SELECT SUBSTR(v_attribute16,INSTR(v_attribute16, ';',-1,1)+1,
(LENGTH (v_attribute16)- INSTR(v_attribute16, ';',-1,1))) 
INTO v_minority_owned FROM dual;

--dbms_output.put_line ('v_minority_owned'||v_minority_owned);


-- Each business class node will get a minority_owned
      l_v_minority_owned_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'minority_owned' ))
                                                );
      l_v_minority_owned_tn := dbms_xmldom.appendChild( l_v_minority_owned_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_minority_owned)) 
);

BEGIN
IF v_minority_owned <> 'N'
THEN
   SELECT meaning INTO v_minority_owned_desc--,DESCRIPTION--*
   FROM FND_LOOKUP_VALUES_VL
   WHERE Lookup_type = 'MINORITY GROUP'
   AND attribute_category = 'MINORITY GROUP'
   AND lookup_code=v_minority_owned;
ELSE
   SELECT  meaning INTO v_minority_owned_desc--,DESCRIPTION--*
   FROM fnd_lookup_values_vl
   WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'--,'FOREIGN_OWN_BUS', 'MINORITY GROUP')
   AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'--)--,'FOREIGN_OWN_BUS', 'MINORITY GROUP')
   AND lookup_code='MINORITY_OWNED';
END IF;
EXCEPTION
  WHEN OTHERS THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error getting v_minority_owned_desc'||SQLERRM);
  dbms_output.put_line('Error getting v_minority_owned_desc');
END;
-- Each business class node will get a minority_owned desc
      l_v_minority_owned_desc_n := dbms_xmldom.appendChild( l_bus_class_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'minorityOwnedDescription' ))
                                               );
      l_v_minority_owned_desc_tn := dbms_xmldom.appendChild( l_v_minority_owned_desc_n
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_minority_owned_desc)) 
);
--------------------
   
 l_addr_list_element:= dbms_xmldom.createElement(l_domdoc, 'addressList' ); 

 l_addr_list_node := dbms_xmldom.appendChild( l_supplier_node
                                            , dbms_xmldom.makeNode( l_addr_list_element)
                                            );

 l_addr_element:= dbms_xmldom.createElement(l_domdoc, 'address' );

 l_addr_node := dbms_xmldom.appendChild( l_addr_list_node--l_supplier_node
                                            , dbms_xmldom.makeNode( l_addr_element)
                                            );
---Purch Address

IF  v_site_purchaddr1 IS NOT NULL
THEN
--   l_site_purch_addr_node := dbms_xmldom.appendChild( l_addr_node 
  --                                               , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'pur_address' ))
    --                                             );

      l_v_site_puraddr_type_n := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressType' ))
                                            );
      l_v_site_puraddr_type_tn := dbms_xmldom.appendChild( l_v_site_puraddr_type_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '99' ))
                                                );
 --
       l_v_site_purseqnum_n := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sequenceNumber' ))
                                            );
      l_v_site_purseqnum_tn := dbms_xmldom.appendChild( l_v_site_purseqnum_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_addr_flag ))
                                                );
      l_v_site_puraction_type_n := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'actionType' ))
                                            );
      l_v_site_puraction_type_tn := dbms_xmldom.appendChild( l_v_site_puraction_type_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 --
   
      l_v_site_pur_isprimaryaddr_n := dbms_xmldom.appendChild(l_addr_node-- l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimaryAddress' ))
                                            );
      l_v_site_pur_isprimaryaddr_tn := dbms_xmldom.appendChild( l_v_site_pur_isprimaryaddr_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
 
      l_v_site_purchaddr1_node := dbms_xmldom.appendChild(l_addr_node-- l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine1' ))
                                            );
      l_v_site_purchaddr1_textnode := dbms_xmldom.appendChild( l_v_site_purchaddr1_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_purchaddr1 ))
                                                );
 
     l_v_site_purchaddr2_node := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine2' ))
                                            );
      l_v_site_purchaddr2_textnode := dbms_xmldom.appendChild( l_v_site_purchaddr2_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_purchaddr2 ))
                                                );
 
   l_v_site_purchaddr3_node := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine3' ))
                                            );
      l_v_site_purchaddr3_textnode := dbms_xmldom.appendChild( l_v_site_purchaddr3_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_purchaddr3 ))
                                                );

   l_v_site_purchcity_node := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'city' ))
                                            );
      l_v_site_purchcity_textnode := dbms_xmldom.appendChild( l_v_site_purchcity_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_purchcity ))
                                                );
 
  l_v_site_purchstate_node := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'state' ))
                                            );
 
   l_v_site_purchstate_textnode := dbms_xmldom.appendChild(l_v_site_purchstate_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_purchstate ))
                                                );
 
   l_v_pur_add_state_abbre_n := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'stateAbbreviation' ))
                                            );
      l_v_pur_add_state_abbre_tn := dbms_xmldom.appendChild( l_v_pur_add_state_abbre_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

   
    l_v_site_purchzip_node := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'postalCode' ))
                                            );
      l_v_site_purchzip_textnode := dbms_xmldom.appendChild( l_v_site_purchzip_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_purchzip ))
                                                );
  
  
    l_v_site_purchcountry_node := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'country' ))
                                            );
      l_v_site_purchcountry_textnode := dbms_xmldom.appendChild( l_v_site_purchcountry_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_purchcountry ))
                                                );
  
    l_v_orgcountry_node := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'orgCountry' ))
                                            );
      l_v_orgcountry_textnode := dbms_xmldom.appendChild( l_v_orgcountry_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_orgcountry ))
                                                );

      l_v_site_pur_add_latitude_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'latitude' ))
                                            );
     l_v_site_pur_add_latitude_tn := dbms_xmldom.appendChild( l_v_site_pur_add_latitude_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_v_site_pur_add_longitude_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'longitude' ))
                                            );
      l_v_site_pur_add_longitude_tn := dbms_xmldom.appendChild( l_v_site_pur_add_longitude_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

  l_v_site_pur_add_county_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'county' ))
                                            );
      l_v_site_pur_add_county_tn := dbms_xmldom.appendChild( l_v_site_pur_add_county_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 l_v_site_pur_add_district_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'district' ))
                                            );
      l_v_site_pur_add_district_tn := dbms_xmldom.appendChild( l_v_site_pur_add_district_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 l_v_site_pur_add_spe_notes_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'specialNote' ))
                                            );
      l_v_site_pur_add_spe_notes_tn := dbms_xmldom.appendChild( l_v_site_pur_add_spe_notes_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

--Contact Node  

   l_site_purch_cont_list_node := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contactList' ))
                                                 );

   l_site_purch_contact_node := dbms_xmldom.appendChild(l_site_purch_cont_list_node--l_site_purch_contact_node-- l_addr_node--l_site_purch_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contact' ))
                                                 );
l_site_pur_contact_pname_node := dbms_xmldom.appendChild( l_site_purch_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'name' ))
                                                 );

  ----

    l_v_site_con_purfname_n := dbms_xmldom.appendChild( l_site_pur_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'firstName' ))
                                            );
      l_v_site_con_purfname_tn := dbms_xmldom.appendChild( l_v_site_con_purfname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_purmname_n := dbms_xmldom.appendChild( l_site_pur_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'middleName' ))
                                            );
      l_v_site_con_purmname_tn := dbms_xmldom.appendChild( l_v_site_con_purmname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_purlname_n := dbms_xmldom.appendChild( l_site_pur_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'lastName' ))
                                            );
      l_v_site_con_purlname_tn := dbms_xmldom.appendChild( l_v_site_con_purlname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );


    l_v_site_con_purname_n := dbms_xmldom.appendChild( l_site_pur_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fullName' ))
                                            );
      l_v_site_con_purname_tn := dbms_xmldom.appendChild( l_v_site_con_purname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_contact_purchname ))
                                                );
  
     l_site_pur_cont_ptitle_node := dbms_xmldom.appendChild( l_site_purch_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'title' ))
                                                 );
   -- l_site_pur_cont_ptitle_tn := dbms_xmldom.appendChild( l_site_pur_cont_ptitle_node
     --                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
       --                                         );


---
     l_v_pur_con_salutation_n := dbms_xmldom.appendChild(l_site_pur_cont_ptitle_node--l_addr_node-- l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'salutation' ))
                                            );
     l_v_pur_con_salutation_tn := dbms_xmldom.appendChild( l_v_pur_con_salutation_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
                                                );

     l_v_pur_con_jobtitle_n := dbms_xmldom.appendChild(l_site_pur_cont_ptitle_node--l_addr_node-- l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'jobTitle' ))
                                            );
     l_v_pur_con_jobtitle_tn := dbms_xmldom.appendChild( l_v_pur_con_jobtitle_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
                                                );
 --
  l_site_pur_cont_ph_node := dbms_xmldom.appendChild( l_site_purch_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phones' ))
                                                 );
  l_site_pur_cont_phasso_node := dbms_xmldom.appendChild( l_site_pur_cont_ph_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneAssociation' ))
                                                 );

    l_v_site_con_purchphtype_n := dbms_xmldom.appendChild(l_site_pur_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneType' ))
                                            );
      l_v_site_con_purchphtype_tn := dbms_xmldom.appendChild( l_v_site_con_purchphtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'Phone' ))
                                                );
 l_v_site_con_purchphone_n := dbms_xmldom.appendChild(l_site_pur_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phone' ))
                                            );

  l_v_site_con_purphareacode_n := dbms_xmldom.appendChild(l_v_site_con_purchphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'areaCode' ))
                                            );
     IF v_site_contact_purchphone IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_purchphone,1,3) INTO l_v_purareacode FROM dual;
     ELSE
     l_v_purareacode := '';
     END IF;
      l_v_site_con_purphareacode_tn := dbms_xmldom.appendChild( l_v_site_con_purphareacode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_purareacode ))--
                                                );
                                                
       l_v_site_con_purphcntrycode_n := dbms_xmldom.appendChild(l_v_site_con_purchphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'countryCode' ))
                                            );
      l_v_site_con_purphcntrycode_tn := dbms_xmldom.appendChild( l_v_site_con_purphcntrycode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))--
                                                );

 -- 
    l_v_site_con_purchph_n := dbms_xmldom.appendChild(l_v_site_con_purchphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneNumber' ))
                                            );
                                            
     IF v_site_contact_purchphone IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_purchphone,4,10) INTO l_v_purph FROM dual;
     ELSE
     l_v_purph := '';
     END IF;
                                            
      l_v_site_con_purchph_tn := dbms_xmldom.appendChild( l_v_site_con_purchph_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_purph ))
                                                );
  
  l_v_site_con_purchphext_n := dbms_xmldom.appendChild(l_v_site_con_purchphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'extension' ))
                                            );
  
      l_v_site_con_purchphext_tn := dbms_xmldom.appendChild( l_v_site_con_purchphext_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_purchphpri_n := dbms_xmldom.appendChild(l_site_pur_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
      l_v_site_con_purchphpri_tn := dbms_xmldom.appendChild( l_v_site_con_purchphpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
  
  --
  l_site_pur_cont_fax_node := dbms_xmldom.appendChild( l_site_purch_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fax' ))
                                                 );
  l_site_pur_cont_faxasso_node := dbms_xmldom.appendChild( l_site_pur_cont_fax_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneAssociation' ))
                                                 );

 l_v_site_con_purchfaxtype_n := dbms_xmldom.appendChild(l_site_pur_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneType' ))
                                            );
      l_v_site_con_purchfaxtype_tn := dbms_xmldom.appendChild( l_v_site_con_purchfaxtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'fax' ))
                                                );

 l_v_site_con_purchfax_n := dbms_xmldom.appendChild(l_site_pur_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phone' ))
                                            );
  
  l_v_site_con_purfaxareacode_n := dbms_xmldom.appendChild(l_v_site_con_purchfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'areaCode' ))
                                            );
     IF v_site_contact_purchfax IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_purchfax,1,3) INTO l_v_purfaxareacode FROM dual;
     ELSE
     l_v_purfaxareacode := '';
     END IF;
      l_v_site_con_purfaxareacode_tn := dbms_xmldom.appendChild( l_v_site_con_purfaxareacode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_purfaxareacode ))--
                                                );

       l_v_site_con_purfxcntrycode_n := dbms_xmldom.appendChild(l_v_site_con_purchfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'countryCode' ))
                                            );
      l_v_site_con_purfxcntrycode_tn := dbms_xmldom.appendChild( l_v_site_con_purfxcntrycode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))--
                                                );

--

    l_v_site_con_purchfx_n := dbms_xmldom.appendChild(l_v_site_con_purchfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneNumber' ))
                                            );
                                            
     IF v_site_contact_purchfax IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_purchfax,4,10) INTO l_v_purfax FROM dual;
     ELSE
     l_v_purfax := '';
     END IF;
                                            
      l_v_site_con_purchfx_tn := dbms_xmldom.appendChild( l_v_site_con_purchfax_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_purfax ))
                                                );
--
     l_v_site_con_purchfaxext_n := dbms_xmldom.appendChild(l_v_site_con_purchfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'extension' ))
                                            );
  
      l_v_site_con_purchfaxext_tn := dbms_xmldom.appendChild( l_v_site_con_purchfaxext_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_purchfaxpri_n := dbms_xmldom.appendChild(l_site_pur_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
      l_v_site_con_purchfaxpri_tn := dbms_xmldom.appendChild( l_v_site_con_purchfaxpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
  --

--      l_v_site_con_purchfx_n := dbms_xmldom.appendChild( l_site_purch_contact_node
  --                                          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fax' ))
    --                                        );
  --    l_v_site_con_purchfx_tn := dbms_xmldom.appendChild( l_v_site_con_purchfx_n
    --                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_contact_purchfax ))
      --                                          );
  
  --
  l_site_pur_cont_email_node := dbms_xmldom.appendChild( l_site_purch_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emails' ))
                                                 );
  l_site_pur_cont_emailasso_node := dbms_xmldom.appendChild( l_site_pur_cont_email_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailAssociation' ))
                                                 );

 l_v_site_con_puremailtype_n := dbms_xmldom.appendChild(l_site_pur_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailType' ))
                                            );
      l_v_site_con_puremailtype_tn := dbms_xmldom.appendChild( l_v_site_con_puremailtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

   l_v_site_con_purchemail_n := dbms_xmldom.appendChild( l_site_pur_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailAddress' ))
                                            );
   l_v_site_con_purchemail_tn := dbms_xmldom.appendChild( l_v_site_con_purchemail_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_contact_purchemail ))
                                              );

   l_v_site_con_puremailpri_n := dbms_xmldom.appendChild( l_site_pur_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
   l_v_site_con_puremailpri_tn := dbms_xmldom.appendChild( l_v_site_con_puremailpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                              );

  END IF;
  ---Pay Address
  IF v_site_payaddr1 IS NOT NULL
  THEN
--   l_site_pay_addr_node := dbms_xmldom.appendChild( l_addr_node 
  --                                               , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'pay_address' ))
    --                                             );

      
      l_v_site_payaddr_type_n := dbms_xmldom.appendChild( l_addr_node--l_site_pay_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressType' ))
                                            );
      l_v_site_payaddr_type_tn := dbms_xmldom.appendChild( l_v_site_payaddr_type_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '99' ))
                                                );
--

       l_v_site_payseqnum_n := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sequenceNumber' ))
                                            );
      l_v_site_payseqnum_tn := dbms_xmldom.appendChild( l_v_site_payseqnum_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_addr_flag ))
                                                );
      l_v_site_payaction_type_n := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'actionType' ))
                                            );
      l_v_site_payaction_type_tn := dbms_xmldom.appendChild( l_v_site_payaction_type_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
--
      l_v_site_pay_isprimaryaddr_n := dbms_xmldom.appendChild(l_addr_node-- l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimaryAddress' ))
                                            );
      l_v_site_pay_isprimaryaddr_tn := dbms_xmldom.appendChild( l_v_site_pay_isprimaryaddr_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    
      l_v_site_payaddr1_node := dbms_xmldom.appendChild( l_addr_node--l_site_pay_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine1' ))
                                            );
      l_v_site_payaddr1_textnode := dbms_xmldom.appendChild( l_v_site_payaddr1_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_payaddr1 ))
                                                );
 
     l_v_site_payaddr2_node := dbms_xmldom.appendChild( l_addr_node--l_site_pay_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine2' ))
                                            );
      l_v_site_payaddr2_textnode := dbms_xmldom.appendChild( l_v_site_payaddr2_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_payaddr2 ))
                                                );
 
   l_v_site_payaddr3_node := dbms_xmldom.appendChild( l_addr_node--l_site_pay_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine3' ))
                                            );
      l_v_site_payaddr3_textnode := dbms_xmldom.appendChild( l_v_site_payaddr3_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_payaddr3 ))
                                                );

   l_v_site_paycity_node := dbms_xmldom.appendChild(l_addr_node-- l_site_pay_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'city' ))
                                            );
      l_v_site_paycity_textnode := dbms_xmldom.appendChild( l_v_site_paycity_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_paycity ))
                                                );
 
      l_v_site_paystate_node := dbms_xmldom.appendChild(l_addr_node-- l_site_pay_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'state' ))
                                            );
 
      l_v_site_paystate_textnode := dbms_xmldom.appendChild( l_v_site_paystate_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_paystate ))
                                                );

      l_v_pay_add_state_abbre_n := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'stateAbbreviation' ))
                                            );
      l_v_pay_add_state_abbre_tn := dbms_xmldom.appendChild( l_v_pay_add_state_abbre_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 
    l_v_site_payzip_node := dbms_xmldom.appendChild( l_addr_node--l_site_pay_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'postalCode' ))
                                            );
      l_v_site_payzip_textnode := dbms_xmldom.appendChild( l_v_site_payzip_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_payzip ))
                                                );
  
  
    l_v_site_paycountry_node := dbms_xmldom.appendChild( l_addr_node--l_site_pay_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'country' ))
                                            );
      l_v_site_paycountry_textnode := dbms_xmldom.appendChild( l_v_site_paycountry_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_paycountry ))
                                                );
  
      l_v_orgcountry_node := dbms_xmldom.appendChild( l_addr_node--l_site_pay_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'orgCountry' ))
                                            );
      l_v_orgcountry_textnode := dbms_xmldom.appendChild( l_v_orgcountry_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_orgcountry ))
                                                );
                                                
     
      l_v_site_pay_add_latitude_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'latitude' ))
                                            );
      l_v_site_pay_add_latitude_tn := dbms_xmldom.appendChild( l_v_site_pay_add_latitude_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_v_site_pay_add_longitude_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'longitude' ))
                                            );
      l_v_site_pay_add_longitude_tn := dbms_xmldom.appendChild( l_v_site_pay_add_longitude_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_v_site_pay_add_county_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'county' ))
                                            );
      l_v_site_pay_add_county_tn := dbms_xmldom.appendChild( l_v_site_pay_add_county_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_v_site_pay_add_district_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'district' ))
                                            );
      l_v_site_pay_add_district_tn := dbms_xmldom.appendChild( l_v_site_pay_add_district_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_v_site_pay_add_spe_notes_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'specialNote' ))
                                            );
      l_v_site_pay_add_spe_notes_tn := dbms_xmldom.appendChild( l_v_site_pay_add_spe_notes_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
                                                
--Contact Node  
   l_site_pay_cont_list_node := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contactList' ))
                                                 );

   l_site_pay_contact_node := dbms_xmldom.appendChild(l_site_pay_cont_list_node-- l_addr_node--l_site_pay_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contact' ))
                                                 );
   l_site_pay_contact_pname_node := dbms_xmldom.appendChild( l_site_pay_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'name' ))
                                                 );
--
    l_v_site_con_payfname_n := dbms_xmldom.appendChild( l_site_pay_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'firstName' ))
                                            );
      l_v_site_con_payfname_tn := dbms_xmldom.appendChild( l_v_site_con_payfname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_paymname_n := dbms_xmldom.appendChild( l_site_pay_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'middleName' ))
                                            );
      l_v_site_con_paymname_tn := dbms_xmldom.appendChild( l_v_site_con_paymname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_paylname_n := dbms_xmldom.appendChild( l_site_pay_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'lastName' ))
                                            );
      l_v_site_con_paylname_tn := dbms_xmldom.appendChild( l_v_site_con_paylname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );


    l_v_site_con_payname_n := dbms_xmldom.appendChild( l_site_pay_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fullName' ))
                                            );
      l_v_site_con_payname_tn := dbms_xmldom.appendChild( l_v_site_con_payname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_contact_payname ))
                                                );
  
   l_site_pay_cont_ptitle_node := dbms_xmldom.appendChild( l_site_pay_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'title' ))
                                                 );

   --  l_site_pay_cont_ptitle_tn := dbms_xmldom.appendChild( l_site_pay_cont_ptitle_node
     --                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
       --                                         );

---
     l_v_pay_con_salutation_n := dbms_xmldom.appendChild(l_site_pay_cont_ptitle_node--l_addr_node-- l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'salutation' ))
                                            );
     l_v_pay_con_salutation_tn := dbms_xmldom.appendChild( l_v_pay_con_salutation_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
                                                );

     l_v_pay_con_jobtitle_n := dbms_xmldom.appendChild(l_site_pay_cont_ptitle_node--l_addr_node-- l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'jobTitle' ))
                                            );
     l_v_pay_con_jobtitle_tn := dbms_xmldom.appendChild( l_v_pay_con_jobtitle_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
                                                );
--
  l_site_pay_cont_ph_node := dbms_xmldom.appendChild( l_site_pay_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phones' ))
                                                 );
  l_site_pay_cont_phasso_node := dbms_xmldom.appendChild( l_site_pay_cont_ph_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneAssociation' ))
                                                 );

    l_v_site_con_payphtype_n := dbms_xmldom.appendChild(l_site_pay_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneType' ))
                                            );
      l_v_site_con_payphtype_tn := dbms_xmldom.appendChild( l_v_site_con_payphtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'Phone' ))
                                                );
--
l_v_site_con_payphone_n := dbms_xmldom.appendChild(l_site_pay_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phone' ))
                                            );

  l_v_site_con_payphareacode_n := dbms_xmldom.appendChild(l_v_site_con_payphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'areaCode' ))
                                            );
     IF v_site_contact_payphone IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_payphone,1,3) INTO l_v_payareacode FROM dual;
     ELSE
     l_v_payareacode := '';
     END IF;
      l_v_site_con_payphareacode_tn := dbms_xmldom.appendChild( l_v_site_con_payphareacode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_payareacode ))--
                                                );

     l_v_site_con_payphcntrycode_n := dbms_xmldom.appendChild(l_v_site_con_payphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'countryCode' ))
                                            );
      l_v_site_con_payphcntrycode_tn := dbms_xmldom.appendChild( l_v_site_con_payphcntrycode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))--
                                                );

    l_v_site_con_payph_n := dbms_xmldom.appendChild( l_v_site_con_payphone_n--l_site_pay_contact_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneNumber' ))
                                            );
 --                                           
      IF v_site_contact_payphone IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_payphone,4,10) INTO l_v_payph FROM dual;
     ELSE
     l_v_payph := '';
     END IF;

      l_v_site_con_payph_tn := dbms_xmldom.appendChild( l_v_site_con_payph_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_payph ))
                                                );
--

       l_v_site_con_payphext_n := dbms_xmldom.appendChild(l_v_site_con_payphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'extension' ))
                                            );
  
      l_v_site_con_payphext_tn := dbms_xmldom.appendChild( l_v_site_con_payphext_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_payphpri_n := dbms_xmldom.appendChild(l_site_pay_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
      l_v_site_con_payphpri_tn := dbms_xmldom.appendChild( l_v_site_con_payphpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

--
l_site_pay_cont_fax_node := dbms_xmldom.appendChild( l_site_pay_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fax' ))
                                                 );
  l_site_pay_cont_faxasso_node := dbms_xmldom.appendChild( l_site_pay_cont_fax_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneAssociation' ))
                                                 );

 l_v_site_con_payfaxtype_n := dbms_xmldom.appendChild(l_site_pay_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneType' ))
                                            );
      l_v_site_con_payfaxtype_tn := dbms_xmldom.appendChild( l_v_site_con_payfaxtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'fax' ))
                                                );
--
 l_v_site_con_payfax_n := dbms_xmldom.appendChild(l_site_pay_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phone' ))
                                            );
  
  l_v_site_con_payfaxareacode_n := dbms_xmldom.appendChild(l_v_site_con_payfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'areaCode' ))
                                            );
     IF v_site_contact_payfax IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_payfax,1,3) INTO l_v_payfaxareacode FROM dual;
     ELSE
     l_v_payfaxareacode := '';
     END IF;
      l_v_site_con_payfaxareacode_tn := dbms_xmldom.appendChild( l_v_site_con_payfaxareacode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_payfaxareacode ))--
                                                );

       l_v_site_con_payfxcntrycode_n := dbms_xmldom.appendChild(l_v_site_con_payfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'countryCode' ))
                                            );
      l_v_site_con_payfxcntrycode_tn := dbms_xmldom.appendChild( l_v_site_con_payfxcntrycode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))--
                                                );

    l_v_site_con_payfx_n := dbms_xmldom.appendChild(l_v_site_con_payfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneNumber' ))
                                            );
                                            
     IF v_site_contact_payfax IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_payfax,4,10) INTO l_v_payfax FROM dual;
     ELSE
     l_v_payfax := '';
     END IF;
                                            
      l_v_site_con_payfx_tn := dbms_xmldom.appendChild( l_v_site_con_payfx_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_payfax ))
                                                );

  
       l_v_site_con_payfaxext_n := dbms_xmldom.appendChild(l_v_site_con_payfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'extension' ))
                                            );
  
      l_v_site_con_payfaxext_tn := dbms_xmldom.appendChild( l_v_site_con_payfaxext_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_payfaxpri_n := dbms_xmldom.appendChild(l_site_pay_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
      l_v_site_con_payfaxpri_tn := dbms_xmldom.appendChild( l_v_site_con_payfaxpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

--
  l_site_pay_cont_email_node := dbms_xmldom.appendChild( l_site_pay_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emails' ))
                                                 );
  l_site_pay_cont_emailasso_node := dbms_xmldom.appendChild( l_site_pay_cont_email_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailAssociation' ))
                                                 );

 l_v_site_con_payemailtype_n := dbms_xmldom.appendChild(l_site_pay_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailType' ))
                                            );
      l_v_site_con_payemailtype_tn := dbms_xmldom.appendChild( l_v_site_con_payemailtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

   l_v_site_con_payemail_n := dbms_xmldom.appendChild( l_site_pay_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailAddress' ))
                                            );
   l_v_site_con_payemail_tn := dbms_xmldom.appendChild( l_v_site_con_payemail_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_contact_payemail ))
                                              );

   l_v_site_con_payemailpri_n := dbms_xmldom.appendChild( l_site_pay_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
   l_v_site_con_payemailpri_tn := dbms_xmldom.appendChild( l_v_site_con_payemailpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                              );

END IF;
  ----------
  --PP Address
  IF v_site_ppaddr1 IS NOT NULL
  THEN
--   l_site_pp_addr_node := dbms_xmldom.appendChild( l_addr_node 
  --                                               , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'pp_address' ))
    --                                             );

      l_v_site_ppaddr_type_n := dbms_xmldom.appendChild( l_addr_node--l_site_pp_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressType' ))
                                            );
      l_v_site_ppaddr_type_tn := dbms_xmldom.appendChild( l_v_site_ppaddr_type_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '99' ))
                                                );
     
       l_v_site_ppseqnum_n := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sequenceNumber' ))
                                            );
      l_v_site_ppseqnum_tn := dbms_xmldom.appendChild( l_v_site_ppseqnum_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_addr_flag ))
                                                );
      l_v_site_ppaction_type_n := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'actionType' ))
                                            );
      l_v_site_ppaction_type_tn := dbms_xmldom.appendChild( l_v_site_ppaction_type_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
     
      l_v_site_pp_isprimaryaddr_n := dbms_xmldom.appendChild(l_addr_node-- l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimaryAddress' ))
                                            );
      l_v_site_pp_isprimaryaddr_tn := dbms_xmldom.appendChild( l_v_site_pp_isprimaryaddr_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );


      l_v_site_ppaddr1_node := dbms_xmldom.appendChild( l_addr_node--l_site_pp_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine1' ))
                                            );
      l_v_site_ppaddr1_textnode := dbms_xmldom.appendChild( l_v_site_ppaddr1_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_ppaddr1 ))
                                                );
 
     l_v_site_ppaddr2_node := dbms_xmldom.appendChild( l_addr_node--l_site_pp_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine2' ))
                                            );
      l_v_site_ppaddr2_textnode := dbms_xmldom.appendChild( l_v_site_ppaddr2_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_ppaddr2 ))
                                                );
 
   l_v_site_ppaddr3_node := dbms_xmldom.appendChild( l_addr_node--l_site_pp_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine3' ))
                                            );
      l_v_site_ppaddr3_textnode := dbms_xmldom.appendChild( l_v_site_ppaddr3_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_ppaddr3 ))
                                                );

   l_v_site_ppcity_node := dbms_xmldom.appendChild( l_addr_node--l_site_pp_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'city' ))
                                            );
      l_v_site_ppcity_textnode := dbms_xmldom.appendChild( l_v_site_ppcity_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_ppcity ))
                                                );
 
      l_v_site_ppstate_node := dbms_xmldom.appendChild( l_addr_node--l_site_pp_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'state' ))
                                            );
      l_v_site_ppstate_textnode := dbms_xmldom.appendChild( l_v_site_ppstate_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_ppstate ))
                                                );
 
      l_v_pp_add_state_abbre_n := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'stateAbbreviation' ))
                                            );
      l_v_pp_add_state_abbre_tn := dbms_xmldom.appendChild( l_v_pp_add_state_abbre_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_v_site_ppzip_node := dbms_xmldom.appendChild( l_addr_node--l_site_pp_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'postalCode' ))
                                            );
      l_v_site_ppzip_textnode := dbms_xmldom.appendChild( l_v_site_ppzip_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_ppzip ))
                                                );
   
      l_v_site_ppcountry_node := dbms_xmldom.appendChild( l_addr_node--l_site_pp_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'country' ))
                                            );
      l_v_site_ppcountry_textnode := dbms_xmldom.appendChild( l_v_site_ppcountry_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_ppcountry ))
                                                );
  
      l_v_orgcountry_node := dbms_xmldom.appendChild( l_addr_node--l_site_pp_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'orgCountry' ))
                                            );
      l_v_orgcountry_textnode := dbms_xmldom.appendChild( l_v_orgcountry_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_orgcountry ))
                                                );
   
      l_v_site_pp_add_latitude_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'latitude' ))
                                            );
      l_v_site_pp_add_latitude_tn := dbms_xmldom.appendChild( l_v_site_pp_add_latitude_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_v_site_pp_add_longitude_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'longitude' ))
                                            );
      l_v_site_pp_add_longitude_tn := dbms_xmldom.appendChild( l_v_site_pp_add_longitude_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

     l_v_site_pp_add_county_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'county' ))
                                            );
      l_v_site_pp_add_county_tn := dbms_xmldom.appendChild( l_v_site_pp_add_county_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_v_site_pp_add_district_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'district' ))
                                            );
      l_v_site_pp_add_district_tn := dbms_xmldom.appendChild( l_v_site_pp_add_district_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_v_site_pp_add_spe_notes_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'specialNote' ))
                                            );
      l_v_site_pp_add_spe_notes_tn := dbms_xmldom.appendChild( l_v_site_pp_add_spe_notes_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
                                                 
                                                
                                                
--Contact Node  
   l_site_pp_cont_list_node := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contactList' ))
                                                 );

   l_site_pp_contact_node := dbms_xmldom.appendChild( l_site_pp_cont_list_node--l_addr_node--l_site_pp_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contact' ))
                                                 );

l_site_pp_contact_pname_node := dbms_xmldom.appendChild( l_site_pp_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'name' ))
                                                 );
--
    l_v_site_con_ppfname_n := dbms_xmldom.appendChild( l_site_pp_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'firstName' ))
                                            );
      l_v_site_con_ppfname_tn := dbms_xmldom.appendChild( l_v_site_con_ppfname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_ppmname_n := dbms_xmldom.appendChild( l_site_pp_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'middleName' ))
                                            );
      l_v_site_con_ppmname_tn := dbms_xmldom.appendChild( l_v_site_con_ppmname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_pplname_n := dbms_xmldom.appendChild( l_site_pp_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'lastName' ))
                                            );
      l_v_site_con_pplname_tn := dbms_xmldom.appendChild( l_v_site_con_pplname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
  
      l_v_site_con_ppname_n := dbms_xmldom.appendChild( l_site_pp_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fullName' ))
                                            );
      l_v_site_con_ppname_tn := dbms_xmldom.appendChild( l_v_site_con_ppname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_contact_ppname ))
                                                );

--
     l_site_pp_cont_ptitle_node := dbms_xmldom.appendChild( l_site_pp_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'title' ))
                                                 );

  --   l_site_pp_cont_ptitle_tn := dbms_xmldom.appendChild( l_site_pp_cont_ptitle_node
    --                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
      --                                          );

---
     l_v_pp_con_salutation_n := dbms_xmldom.appendChild(l_site_pp_cont_ptitle_node--l_addr_node-- l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'salutation' ))
                                            );
     l_v_pp_con_salutation_tn := dbms_xmldom.appendChild( l_v_pp_con_salutation_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
                                                );

     l_v_pp_con_jobtitle_n := dbms_xmldom.appendChild(l_site_pp_cont_ptitle_node--l_addr_node-- l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'jobTitle' ))
                                            );
     l_v_pp_con_jobtitle_tn := dbms_xmldom.appendChild( l_v_pp_con_jobtitle_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
                                                );

--  
 l_site_pp_cont_ph_node := dbms_xmldom.appendChild( l_site_pp_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phones' ))
                                                 );
  l_site_pp_cont_phasso_node := dbms_xmldom.appendChild( l_site_pp_cont_ph_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneAssociation' ))
                                                 );

    l_v_site_con_ppphtype_n := dbms_xmldom.appendChild(l_site_pp_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneType' ))
                                            );
      l_v_site_con_ppphtype_tn := dbms_xmldom.appendChild( l_v_site_con_ppphtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'Phone' ))
                                                );
--
l_v_site_con_ppphone_n := dbms_xmldom.appendChild(l_site_pp_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phone' ))
                                            );

  l_v_site_con_ppphareacode_n := dbms_xmldom.appendChild(l_v_site_con_ppphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'areaCode' ))
                                            );
     IF v_site_contact_ppphone IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_ppphone,1,3) INTO l_v_ppareacode FROM dual;
     ELSE
     l_v_ppareacode := '';
     END IF;
      l_v_site_con_ppphareacode_tn := dbms_xmldom.appendChild( l_v_site_con_ppphareacode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_ppareacode ))--
                                                );

     l_v_site_con_ppphcntrycode_n := dbms_xmldom.appendChild(l_v_site_con_ppphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'countryCode' ))
                                            );
      l_v_site_con_ppphcntrycode_tn := dbms_xmldom.appendChild( l_v_site_con_ppphcntrycode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))--
                                                );
--
 l_v_site_con_ppph_n := dbms_xmldom.appendChild( l_v_site_con_ppphone_n--l_site_pay_contact_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneNumber' ))
                                            );
 --                                           
      IF v_site_contact_ppphone IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_ppphone,4,10) INTO l_v_ppph FROM dual;
     ELSE
     l_v_ppph := '';
     END IF;

      l_v_site_con_ppph_tn := dbms_xmldom.appendChild( l_v_site_con_ppph_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_ppph ))
                                                );
--

       l_v_site_con_ppphext_n := dbms_xmldom.appendChild(l_v_site_con_ppphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'extension' ))
                                            );
  
      l_v_site_con_ppphext_tn := dbms_xmldom.appendChild( l_v_site_con_ppphext_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 l_v_site_con_ppphpri_n := dbms_xmldom.appendChild(l_site_pp_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
      l_v_site_con_ppphpri_tn := dbms_xmldom.appendChild( l_v_site_con_ppphpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

--
l_site_pp_cont_fax_node := dbms_xmldom.appendChild( l_site_pp_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fax' ))
                                                 );
  l_site_pp_cont_faxasso_node := dbms_xmldom.appendChild( l_site_pp_cont_fax_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneAssociation' ))
                                                 );

 l_v_site_con_ppfaxtype_n := dbms_xmldom.appendChild(l_site_pp_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneType' ))
                                            );
      l_v_site_con_ppfaxtype_tn := dbms_xmldom.appendChild( l_v_site_con_ppfaxtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'fax' ))
                                                );

--
 l_v_site_con_ppfax_n := dbms_xmldom.appendChild(l_site_pp_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phone' ))
                                            );
  
  l_v_site_con_ppfaxareacode_n := dbms_xmldom.appendChild(l_v_site_con_ppfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'areaCode' ))
                                            );
     IF v_site_contact_ppfax IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_ppfax,1,3) INTO l_v_ppfaxareacode FROM dual;
     ELSE
     l_v_ppfaxareacode := '';
     END IF;
      l_v_site_con_ppfaxareacode_tn := dbms_xmldom.appendChild( l_v_site_con_ppfaxareacode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_ppfaxareacode ))--
                                                );

    l_v_site_con_ppfxcntrycode_n := dbms_xmldom.appendChild(l_v_site_con_ppfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'countryCode' ))
                                            );
      l_v_site_con_ppfxcntrycode_tn := dbms_xmldom.appendChild( l_v_site_con_ppfxcntrycode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))--
                                                );
--
 l_v_site_con_ppfx_n := dbms_xmldom.appendChild(l_v_site_con_ppfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneNumber' ))
                                            );
                                            
     IF v_site_contact_ppfax IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_ppfax,4,10) INTO l_v_ppfax FROM dual;
     ELSE
     l_v_ppfax := '';
     END IF;
                                            
      l_v_site_con_ppfx_tn := dbms_xmldom.appendChild( l_v_site_con_ppfx_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_ppfax ))
                                                );

--
  l_v_site_con_ppfaxext_n := dbms_xmldom.appendChild(l_v_site_con_ppfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'extension' ))
                                            );
  
      l_v_site_con_ppfaxext_tn := dbms_xmldom.appendChild( l_v_site_con_ppfaxext_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_ppfaxpri_n := dbms_xmldom.appendChild(l_site_pp_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
      l_v_site_con_ppfaxpri_tn := dbms_xmldom.appendChild( l_v_site_con_ppfaxpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

--
     l_site_pp_cont_email_node := dbms_xmldom.appendChild( l_site_pp_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emails' ))
                                                 );
  l_site_pp_cont_emailasso_node := dbms_xmldom.appendChild( l_site_pp_cont_email_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailAssociation' ))
                                                 );

 l_v_site_con_ppemailtype_n := dbms_xmldom.appendChild(l_site_pp_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailType' ))
                                            );
      l_v_site_con_ppemailtype_tn := dbms_xmldom.appendChild( l_v_site_con_ppemailtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

   l_v_site_con_ppemail_n := dbms_xmldom.appendChild( l_site_pp_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailAddress' ))
                                            );
   l_v_site_con_ppemail_tn := dbms_xmldom.appendChild( l_v_site_con_ppemail_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_contact_ppemail ))
                                              );

   l_v_site_con_ppemailpri_n := dbms_xmldom.appendChild( l_site_pp_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
   l_v_site_con_ppemailpri_tn := dbms_xmldom.appendChild( l_v_site_con_ppemailpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                              );
  END IF;
 
--RTV Address
IF v_site_rtvaddr1 IS NOT NULL
THEN
--   l_site_rtv_addr_node := dbms_xmldom.appendChild( l_addr_node 
  --                                               , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'rtv_address' ))
     --                                            );

      l_v_site_rtvaddr_type_n := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressType' ))
                                            );
      l_v_site_rtvaddr_type_tn := dbms_xmldom.appendChild( l_v_site_rtvaddr_type_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '99' ))
                                                );
                                                
       l_v_site_rtvseqnum_n := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sequenceNumber' ))
                                            );
      l_v_site_rtvseqnum_tn := dbms_xmldom.appendChild( l_v_site_rtvseqnum_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_addr_flag ))
                                                );
      l_v_site_rtvaction_type_n := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'actionType' ))
                                            );
      l_v_site_rtvaction_type_tn := dbms_xmldom.appendChild( l_v_site_rtvaction_type_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
                                            
                                                
      l_v_site_rtv_isprimaryaddr_n := dbms_xmldom.appendChild(l_addr_node-- l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimaryAddress' ))
                                            );
      l_v_site_rtv_isprimaryaddr_tn := dbms_xmldom.appendChild( l_v_site_rtv_isprimaryaddr_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );


      l_v_site_rtvaddr1_node := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine1' ))
                                            );
      l_v_site_rtvaddr1_textnode := dbms_xmldom.appendChild( l_v_site_rtvaddr1_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_rtvaddr1 ))
                                                );
 
     l_v_site_rtvaddr2_node := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine2' ))
                                            );
      l_v_site_rtvaddr2_textnode := dbms_xmldom.appendChild( l_v_site_rtvaddr2_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_rtvaddr2 ))
                                                );
 
   l_v_site_rtvaddr3_node := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine3' ))
                                            );
      l_v_site_rtvaddr3_textnode := dbms_xmldom.appendChild( l_v_site_rtvaddr3_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_rtvaddr3 ))
                                                );

   l_v_site_rtvcity_node := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'city' ))
                                            );
      l_v_site_rtvcity_textnode := dbms_xmldom.appendChild( l_v_site_rtvcity_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_rtvcity ))
                                                );
 
  l_v_site_rtvstate_node := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'state' ))
                                            );
      l_v_site_rtvstate_textnode := dbms_xmldom.appendChild( l_v_site_rtvstate_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_rtvstate ))
                                                );
  
  l_v_rtv_add_state_abbre_n := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'stateAbbreviation' ))
                                            );
      l_v_rtv_add_state_abbre_tn := dbms_xmldom.appendChild( l_v_rtv_add_state_abbre_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_rtvzip_node := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'postalCode' ))
                                            );
      l_v_site_rtvzip_textnode := dbms_xmldom.appendChild( l_v_site_rtvzip_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_rtvzip ))
                                                );
  
  
    l_v_site_rtvcountry_node := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'country' ))
                                            );
      l_v_site_rtvcountry_textnode := dbms_xmldom.appendChild( l_v_site_rtvcountry_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_rtvcountry ))
                                                );
  
    l_v_orgcountry_node := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'orgCountry' ))
                                            );
      l_v_orgcountry_textnode := dbms_xmldom.appendChild( l_v_orgcountry_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_orgcountry ))
                                                );
    
       l_v_site_rtv_add_latitude_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'latitude' ))
                                            );
      l_v_site_rtv_add_latitude_tn := dbms_xmldom.appendChild( l_v_site_rtv_add_latitude_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_v_site_rtv_add_longitude_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'longitude' ))
                                            );
      l_v_site_rtv_add_longitude_tn := dbms_xmldom.appendChild( l_v_site_rtv_add_longitude_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

  l_v_site_rtv_add_county_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'county' ))
                                            );
      l_v_site_rtv_add_county_tn := dbms_xmldom.appendChild( l_v_site_rtv_add_county_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 l_v_site_rtv_add_district_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'district' ))
                                            );
      l_v_site_rtv_add_district_tn := dbms_xmldom.appendChild( l_v_site_rtv_add_district_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 l_v_site_rtv_add_spe_notes_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'specialNote' ))
                                            );
      l_v_site_rtv_add_spe_notes_tn := dbms_xmldom.appendChild( l_v_site_rtv_add_spe_notes_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
                                           
                                              
--Contact Node  

   l_site_rtv_cont_list_node := dbms_xmldom.appendChild(l_addr_node-- l_site_rtv_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contactList' ))
                                                 );


   l_site_rtv_contact_node := dbms_xmldom.appendChild(l_site_rtv_cont_list_node--l_addr_node-- l_site_rtv_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contact' ))
                                                 );


l_site_rtv_contact_pname_node := dbms_xmldom.appendChild( l_site_rtv_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'name' ))
                                                 );

  ----

     l_v_site_con_rtvfname_n := dbms_xmldom.appendChild( l_site_rtv_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'firstName' ))
                                            );
      l_v_site_con_rtvfname_tn := dbms_xmldom.appendChild( l_v_site_con_rtvfname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_rtvmname_n := dbms_xmldom.appendChild( l_site_rtv_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'middleName' ))
                                            );
      l_v_site_con_rtvmname_tn := dbms_xmldom.appendChild( l_v_site_con_rtvmname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_rtvlname_n := dbms_xmldom.appendChild( l_site_rtv_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'lastName' ))
                                            );
      l_v_site_con_rtvlname_tn := dbms_xmldom.appendChild( l_v_site_con_rtvlname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );


    l_v_site_con_rtvname_n := dbms_xmldom.appendChild( l_site_rtv_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fullName' ))
                                            );
      l_v_site_con_rtvname_tn := dbms_xmldom.appendChild( l_v_site_con_rtvname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_contact_rtvname ))
                                                );
  
   l_site_rtv_cont_ptitle_node := dbms_xmldom.appendChild( l_site_rtv_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'title' ))
                                                 );

  --  l_site_rtv_cont_ptitle_tn := dbms_xmldom.appendChild( l_site_rtv_cont_ptitle_node
    --                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
      --                                          );

---
     l_v_rtv_con_salutation_n := dbms_xmldom.appendChild(l_site_rtv_cont_ptitle_node--l_addr_node-- l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'salutation' ))
                                            );
     l_v_rtv_con_salutation_tn := dbms_xmldom.appendChild( l_v_rtv_con_salutation_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
                                                );

     l_v_rtv_con_jobtitle_n := dbms_xmldom.appendChild(l_site_rtv_cont_ptitle_node--l_addr_node-- l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'jobTitle' ))
                                            );
     l_v_rtv_con_jobtitle_tn := dbms_xmldom.appendChild( l_v_rtv_con_jobtitle_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
                                                );
    --
      
l_site_rtv_cont_ph_node := dbms_xmldom.appendChild( l_site_rtv_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phones' ))
                                                 );
  l_site_rtv_cont_phasso_node := dbms_xmldom.appendChild( l_site_rtv_cont_ph_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneAssociation' ))
                                                 );

    l_v_site_con_rtvphtype_n := dbms_xmldom.appendChild(l_site_rtv_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneType' ))
                                            );
      l_v_site_con_rtvphtype_tn := dbms_xmldom.appendChild( l_v_site_con_rtvphtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'Phone' ))
                                                );
--
l_v_site_con_rtvphone_n := dbms_xmldom.appendChild(l_site_rtv_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phone' ))
                                            );

  l_v_site_con_rtvphareacode_n := dbms_xmldom.appendChild(l_v_site_con_rtvphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'areaCode' ))
                                            );
     IF v_site_contact_rtvphone IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_rtvphone,1,3) INTO l_v_rtvareacode FROM dual;
     ELSE
     l_v_rtvareacode := '';
     END IF;
      l_v_site_con_rtvphareacode_tn := dbms_xmldom.appendChild( l_v_site_con_rtvphareacode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_rtvareacode ))--
                                                );

     l_v_site_con_rtvphcntrycode_n := dbms_xmldom.appendChild(l_v_site_con_rtvphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'countryCode' ))
                                            );
      l_v_site_con_rtvphcntrycode_tn := dbms_xmldom.appendChild( l_v_site_con_rtvphcntrycode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))--
                                                );
--
 l_v_site_con_rtvph_n := dbms_xmldom.appendChild( l_v_site_con_rtvphone_n--l_site_pay_contact_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneNumber' ))
                                            );
 --                                           
      IF v_site_contact_rtvphone IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_rtvphone,4,10) INTO l_v_rtvph FROM dual;
     ELSE
     l_v_rtvph := '';
     END IF;

      l_v_site_con_rtvph_tn := dbms_xmldom.appendChild( l_v_site_con_rtvph_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_rtvph ))
                                                );
--

       l_v_site_con_rtvphext_n := dbms_xmldom.appendChild(l_v_site_con_rtvphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'extension' ))
                                            );
  
      l_v_site_con_rtvphext_tn := dbms_xmldom.appendChild( l_v_site_con_rtvphext_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 l_v_site_con_rtvphpri_n := dbms_xmldom.appendChild(l_site_rtv_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
      l_v_site_con_rtvphpri_tn := dbms_xmldom.appendChild( l_v_site_con_rtvphpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
--

l_site_rtv_cont_fax_node := dbms_xmldom.appendChild( l_site_rtv_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fax' ))
                                                 );
  l_site_rtv_cont_faxasso_node := dbms_xmldom.appendChild( l_site_rtv_cont_fax_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneAssociation' ))
                                                 );

 l_v_site_con_rtvfaxtype_n := dbms_xmldom.appendChild(l_site_rtv_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneType' ))
                                            );
      l_v_site_con_rtvfaxtype_tn := dbms_xmldom.appendChild( l_v_site_con_rtvfaxtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'fax' ))
                                                );

--
 l_v_site_con_rtvfax_n := dbms_xmldom.appendChild(l_site_rtv_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phone' ))
                                            );
  
  l_v_site_con_rtvfaxareacode_n := dbms_xmldom.appendChild(l_v_site_con_rtvfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'areaCode' ))
                                            );
     IF v_site_contact_rtvfax IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_rtvfax,1,3) INTO l_v_rtvfaxareacode FROM dual;
     ELSE
     l_v_rtvfaxareacode := '';
     END IF;
      l_v_site_con_rtvfaxareacode_tn := dbms_xmldom.appendChild( l_v_site_con_rtvfaxareacode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_rtvfaxareacode ))--
                                                );

    l_v_site_con_rtvfxcntrycode_n := dbms_xmldom.appendChild(l_v_site_con_rtvfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'countryCode' ))
                                            );
      l_v_site_con_rtvfxcntrycode_tn := dbms_xmldom.appendChild( l_v_site_con_rtvfxcntrycode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))--
                                                );
--
 l_v_site_con_rtvfx_n := dbms_xmldom.appendChild(l_v_site_con_rtvfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneNumber' ))
                                            );
                                            
     IF v_site_contact_rtvfax IS NOT NULL
     THEN 
     SELECT SUBSTR(v_site_contact_rtvfax,4,10) INTO l_v_rtvfax FROM dual;
     ELSE
     l_v_rtvfax := '';
     END IF;
                                            
      l_v_site_con_rtvfx_tn := dbms_xmldom.appendChild( l_v_site_con_rtvfx_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_rtvfax ))
                                                );

--
  l_v_site_con_rtvfaxext_n := dbms_xmldom.appendChild(l_v_site_con_rtvfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'extension' ))
                                            );
  
      l_v_site_con_rtvfaxext_tn := dbms_xmldom.appendChild( l_v_site_con_rtvfaxext_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_rtvfaxpri_n := dbms_xmldom.appendChild(l_site_rtv_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
      l_v_site_con_rtvfaxpri_tn := dbms_xmldom.appendChild( l_v_site_con_rtvfaxpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
--  
   l_site_rtv_cont_email_node := dbms_xmldom.appendChild( l_site_rtv_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emails' ))
                                                 );
  l_site_rtv_cont_emailasso_node := dbms_xmldom.appendChild( l_site_rtv_cont_email_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailAssociation' ))
                                                 );

 l_v_site_con_rtvemailtype_n := dbms_xmldom.appendChild(l_site_rtv_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailType' ))
                                            );
      l_v_site_con_rtvemailtype_tn := dbms_xmldom.appendChild( l_v_site_con_rtvemailtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

   l_v_site_con_rtvemail_n := dbms_xmldom.appendChild( l_site_rtv_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailAddress' ))
                                            );
   l_v_site_con_rtvemail_tn := dbms_xmldom.appendChild( l_v_site_con_rtvemail_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_site_contact_rtvemail ))
                                              );

   l_v_site_con_rtvemailpri_n := dbms_xmldom.appendChild( l_site_rtv_cont_emailasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
   l_v_site_con_rtvemailpri_tn := dbms_xmldom.appendChild( l_v_site_con_rtvemailpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                              );

END IF;
   ---Address Type
BEGIN
   -- Create a new node address node  and add it to the busine node
--   l_address_node := dbms_xmldom.appendChild( l_supplier_node
  --                                              , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'Addresses' ))
    --                                            );
FOR r_address_data IN c_address_data

-- open cursor c_address_type
LOOP

    --   l_site_addr_node := dbms_xmldom.appendChild( l_addr_node 
      --                                           , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contact_type_'||r_address_data.addr_type ))
        --                                         );


--     l_v_addr_01_addr_type_node := dbms_xmldom.appendChild( l_addr_node--l_address_node
  --                                          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contact_type_'||r_address_data.addr_type ))
    --                                        );
  --    l_v_addr_01_addr_type_textnode := dbms_xmldom.appendChild( l_v_addr_01_addr_type_node
    --                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.addr_type ))
      --                                          );

   l_v_addr_01_addr_type_node := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressType' ))
                                            );
      l_v_addr_01_addr_type_textnode := dbms_xmldom.appendChild( l_v_addr_01_addr_type_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.addr_type ))
                                                );
 --
      l_v_site_addr_01_seqnum_n := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sequenceNumber' ))
                                            );
      l_v_site_addr_01_seqnum_tn := dbms_xmldom.appendChild( l_v_site_addr_01_seqnum_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.seq_no ))
                                                );
      l_v_site_addr_action_type_n := dbms_xmldom.appendChild( l_addr_node--l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'actionType' ))
                                            );
      l_v_site_addr_action_type_tn := dbms_xmldom.appendChild( l_v_site_addr_action_type_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
                                            
 --
 
        l_v_cust_add_isprimaryaddr_n := dbms_xmldom.appendChild(l_addr_node-- l_site_purch_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimaryAddress' ))
                                            );
      l_v_cust_add_isprimaryaddr_tn := dbms_xmldom.appendChild( l_v_cust_add_isprimaryaddr_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

  
   l_v_addr1_node := dbms_xmldom.appendChild(l_addr_node --l_site_addr_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine1' ))
                                            );
      l_v_addr1_textnode := dbms_xmldom.appendChild( l_v_addr1_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.add_1 ))
                                                );

   l_v_addr2_node := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine2' ))
                                            );
      l_v_addr2_textnode := dbms_xmldom.appendChild( l_v_addr2_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.add_2 ))
                                                );

   l_v_addr3_node := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'addressLine3' ))
                                            );
      l_v_addr3_textnode := dbms_xmldom.appendChild( l_v_addr3_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.add_3 ))
                                                );

   l_v_addr_city_node := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'city' ))
                                            );
      l_v_addr_city_textnode := dbms_xmldom.appendChild( l_v_addr_city_node--l_v_addr_city_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.city ))
                                                );

 l_v_addr_state_node := dbms_xmldom.appendChild(l_addr_node-- l_site_addr_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'state' ))
                                            );
      l_v_addr_state_textnode := dbms_xmldom.appendChild( l_v_addr_state_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.state ))
                                                );

   l_v_add_state_abbre_n := dbms_xmldom.appendChild( l_addr_node--l_site_rtv_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'stateAbbreviation' ))
                                            );
      l_v_add_state_abbre_tn := dbms_xmldom.appendChild( l_v_add_state_abbre_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 
 l_v_addr_zip_node := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'postalCode' ))
                                            );
      l_v_addr_zip_textnode := dbms_xmldom.appendChild( l_v_addr_zip_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.post ))
                                                );

 l_v_addr_country_node := dbms_xmldom.appendChild(l_addr_node--l_site_addr_node-- l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'country' ))
                                            );
      l_v_addr_country_textnode := dbms_xmldom.appendChild( l_v_addr_country_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.country_id ))
                                                );

  l_v_orgcountry_node := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'orgCountry' ))
                                            );
      l_v_orgcountry_textnode := dbms_xmldom.appendChild( l_v_orgcountry_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, v_orgcountry ))
                                                );

      l_v_add_latitude_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'latitude' ))
                                            );
      l_v_add_latitude_tn := dbms_xmldom.appendChild( l_v_add_latitude_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_v_add_longitude_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'longitude' ))
                                            );
      l_v_add_longitude_tn := dbms_xmldom.appendChild( l_v_add_longitude_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

  l_v_add_county_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'county' ))
                                            );
      l_v_add_county_tn := dbms_xmldom.appendChild( l_v_add_county_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 l_v_add_district_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'district' ))
                                            );
      l_v_add_district_tn := dbms_xmldom.appendChild( l_v_add_district_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 l_v_add_spe_notes_n := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'specialNote' ))
                                            );
      l_v_add_spe_notes_tn := dbms_xmldom.appendChild( l_v_add_spe_notes_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
                                                

--contact node

  l_site_addr_cont_list_node := dbms_xmldom.appendChild( l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contactList' ))
                                                 );


   l_site_addr_contact_node := dbms_xmldom.appendChild(l_site_addr_cont_list_node-- l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contact' ))
                                                 );

   l_site_addr_contact_pname_node := dbms_xmldom.appendChild( l_site_addr_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'name' ))
                                                 );

---
     l_v_site_con_addfname_n := dbms_xmldom.appendChild( l_site_addr_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'firstName' ))
                                            );
      l_v_site_con_addfname_tn := dbms_xmldom.appendChild( l_v_site_con_addfname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_addmname_n := dbms_xmldom.appendChild( l_site_addr_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'middleName' ))
                                            );
      l_v_site_con_addmname_tn := dbms_xmldom.appendChild( l_v_site_con_addmname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_addlname_n := dbms_xmldom.appendChild( l_site_addr_contact_pname_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'lastName' ))
                                            );
      l_v_site_con_addlname_tn := dbms_xmldom.appendChild( l_v_site_con_addlname_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

---
 l_v_addr_con_name_node := dbms_xmldom.appendChild(l_site_addr_contact_pname_node--l_addr_node-- l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fullName' ))
                                            );
      l_v_addr_con_name_textnode := dbms_xmldom.appendChild( l_v_addr_con_name_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.contact_name))
                                                );

    l_site_addr_cont_ptitle_node := dbms_xmldom.appendChild( l_site_addr_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'title' ))
                                                 );
   --  l_site_addr_cont_ptitle_tn := dbms_xmldom.appendChild( l_site_addr_cont_ptitle_node
     --                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
       --                                         );
                                              
                                                 
---
     l_v_addr_con_salutation_n := dbms_xmldom.appendChild(l_site_addr_cont_ptitle_node--l_addr_node-- l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'salutation' ))
                                            );
     l_v_addr_con_salutation_tn := dbms_xmldom.appendChild( l_v_addr_con_salutation_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
                                                );

     l_v_addr_con_jobtitle_n := dbms_xmldom.appendChild(l_site_addr_cont_ptitle_node--l_addr_node-- l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'jobTitle' ))
                                            );
     l_v_addr_con_jobtitle_tn := dbms_xmldom.appendChild( l_v_addr_con_jobtitle_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ''))
                                                );
--

      
l_site_addr_cont_ph_node := dbms_xmldom.appendChild( l_site_addr_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phones' ))
                                                 );
  l_site_addr_cont_phasso_node := dbms_xmldom.appendChild( l_site_addr_cont_ph_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneAssociation' ))
                                                 );

    l_v_site_con_addrphtype_n := dbms_xmldom.appendChild(l_site_addr_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneType' ))
                                            );
      l_v_site_con_addrphtype_tn := dbms_xmldom.appendChild( l_v_site_con_addrphtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'Phone' ))
                                                );
--
l_v_site_con_addrphone_n := dbms_xmldom.appendChild(l_site_addr_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phone' ))
                                            );

  l_v_site_con_addrphareacode_n := dbms_xmldom.appendChild(l_v_site_con_addrphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'areaCode' ))
                                            );
     IF r_address_data.contact_phone IS NOT NULL
     THEN 
     SELECT SUBSTR(r_address_data.contact_phone,1,3) INTO l_v_addrareacode FROM dual;
     ELSE
     l_v_addrareacode := '';
     END IF;
      l_v_site_con_addrphareacode_tn := dbms_xmldom.appendChild( l_v_site_con_addrphareacode_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_addrareacode ))--
                                                );

     l_v_site_con_addrphcntrycd_n := dbms_xmldom.appendChild(l_v_site_con_addrphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'countryCode' ))
                                            );
      l_v_site_con_addrphcntrycd_tn := dbms_xmldom.appendChild( l_v_site_con_addrphcntrycd_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))--
                                                );
--
 l_v_addr_con_ph_node := dbms_xmldom.appendChild( l_v_site_con_addrphone_n--l_site_pay_contact_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneNumber' ))
                                            );
 --                                           
      IF r_address_data.contact_phone IS NOT NULL
     THEN 
     SELECT SUBSTR(r_address_data.contact_phone,4,10) INTO l_v_addrph FROM dual;
     ELSE
     l_v_addrph := '';
     END IF;

      l_v_addr_con_ph_textnode := dbms_xmldom.appendChild( l_v_addr_con_ph_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_addrph ))
                                                );
--

       l_v_site_con_addrphext_n := dbms_xmldom.appendChild(l_v_site_con_addrphone_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'extension' ))
                                            );
  
      l_v_site_con_addrphext_tn := dbms_xmldom.appendChild( l_v_site_con_addrphext_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

 l_v_site_con_addrphpri_n := dbms_xmldom.appendChild(l_site_addr_cont_phasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
      l_v_site_con_addrphpri_tn := dbms_xmldom.appendChild( l_v_site_con_addrphpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
--

-- 
-- l_v_addr_con_ph_node := dbms_xmldom.appendChild( l_site_addr_contact_node--l_addr_node--l_address_node
  --                                          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phone' ))
    --                                        );
 --     l_v_addr_con_ph_textnode := dbms_xmldom.appendChild( l_v_addr_con_ph_node
   --                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.contact_phone))
     --                                           );


--

l_site_addr_cont_fax_node := dbms_xmldom.appendChild( l_site_addr_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fax' ))
                                                 );
  l_site_addr_cont_faxasso_node := dbms_xmldom.appendChild( l_site_addr_cont_fax_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneAssociation' ))
                                                 );

 l_v_site_con_addrfaxtype_n := dbms_xmldom.appendChild(l_site_addr_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneType' ))
                                            );
      l_v_site_con_addrfaxtype_tn := dbms_xmldom.appendChild( l_v_site_con_addrfaxtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'fax' ))
                                                );

--
 l_v_site_con_addrfax_n := dbms_xmldom.appendChild(l_site_addr_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phone' ))
                                            );
  
  l_v_site_con_addrfaxareacd_n := dbms_xmldom.appendChild(l_v_site_con_addrfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'areaCode' ))
                                            );
     IF r_address_data.contact_fax IS NOT NULL
     THEN 
     SELECT SUBSTR(r_address_data.contact_fax,1,3) INTO l_v_addrfaxareacode FROM dual;
     ELSE
     l_v_addrfaxareacode := '';
     END IF;
      l_v_site_con_addrfaxareacd_tn := dbms_xmldom.appendChild( l_v_site_con_addrfaxareacd_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_addrfaxareacode ))--
                                                );

    l_v_site_con_addrfxcntrycd_n := dbms_xmldom.appendChild(l_v_site_con_addrfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'countryCode' ))
                                            );
      l_v_site_con_addrfxcntrycd_tn := dbms_xmldom.appendChild( l_v_site_con_addrfxcntrycd_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))--
                                                );
--
 l_v_addr_con_fax_node := dbms_xmldom.appendChild(l_v_site_con_addrfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'phoneNumber' ))
                                            );
                                            
     IF r_address_data.contact_fax IS NOT NULL
     THEN 
     SELECT SUBSTR(r_address_data.contact_fax,4,10) INTO l_v_addrfax FROM dual;
     ELSE
     l_v_addrfax := '';
     END IF;
                                            
      l_v_addr_con_fax_textnode := dbms_xmldom.appendChild( l_v_addr_con_fax_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, l_v_addrfax ))
                                                );

--
  l_v_site_con_addrfaxext_n := dbms_xmldom.appendChild(l_v_site_con_addrfax_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'extension' ))
                                            );
  
      l_v_site_con_addrfaxext_tn := dbms_xmldom.appendChild( l_v_site_con_addrfaxext_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

    l_v_site_con_addrfaxpri_n := dbms_xmldom.appendChild(l_site_addr_cont_faxasso_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
      l_v_site_con_addrfaxpri_tn := dbms_xmldom.appendChild( l_v_site_con_addrfaxpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                             );
--
-- l_v_addr_con_fax_node := dbms_xmldom.appendChild(l_site_addr_contact_node-- l_addr_node--l_address_node
  --                                          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'fax' ))
    --                                        );
 --     l_v_addr_con_fax_textnode := dbms_xmldom.appendChild( l_v_addr_con_fax_node
   --                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.contact_fax))
     --                                           );


--
   l_site_addr_cont_email_node := dbms_xmldom.appendChild( l_site_addr_contact_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emails' ))
                                                 );
  l_site_addr_cont_emailasso_n := dbms_xmldom.appendChild( l_site_addr_cont_email_node--l_addr_node--l_site_addr_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailAssociation' ))
                                                 );

 l_v_site_con_addremailtype_n := dbms_xmldom.appendChild(l_site_addr_cont_emailasso_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailType' ))
                                            );
      l_v_site_con_addremailtype_tn := dbms_xmldom.appendChild( l_v_site_con_addremailtype_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

   l_v_addr_con_email_node := dbms_xmldom.appendChild( l_site_addr_cont_emailasso_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'emailAddress' ))
                                            );
   l_v_addr_con_email_textnode := dbms_xmldom.appendChild( l_v_addr_con_email_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.contact_email ))
                                              );

   l_v_site_con_addremailpri_n := dbms_xmldom.appendChild( l_site_addr_cont_emailasso_n
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'isPrimary' ))
                                            );
   l_v_site_con_addremailpri_tn := dbms_xmldom.appendChild( l_v_site_con_addremailpri_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                              );

--

-- l_v_addr_con_email_node := dbms_xmldom.appendChild(l_site_addr_contact_node--l_addr_node-- l_address_node
  --                                          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'email' ))
    --                                        );
--      l_v_addr_con_email_textnode := dbms_xmldom.appendChild( l_v_addr_con_email_node
  --                                              , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_address_data.contact_email))
    --                                            );

  END LOOP;

  END;


--Supplier Traits

BEGIN
   -- Create a new node supplier traits node  and add it to the supplier node
   l_supplier_traits_node := dbms_xmldom.appendChild( l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'supplierTraitList' ))
                                                );
                                                
FOR r_sup_traits IN c_sup_traits

LOOP

       l_supplier_trait_node := dbms_xmldom.appendChild( l_supplier_traits_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'supplierTrait'))
                                                 );
      l_sup_trait_action_type_n := dbms_xmldom.appendChild( l_supplier_trait_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'actionType' ))
                                            );
      l_sup_trait_action_type_tn := dbms_xmldom.appendChild( l_sup_trait_action_type_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

      l_sup_trait_node := dbms_xmldom.appendChild( l_supplier_trait_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'supplierTrait' ))
                                            );
      l_sup_trait_textnode := dbms_xmldom.appendChild( l_sup_trait_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_sup_traits.sup_trait ))
                                                );

   l_sup_trait_desc_node := dbms_xmldom.appendChild( l_supplier_trait_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'supplierTraitDescription' ))
                                            );
  l_sup_trait_desc_textnode := dbms_xmldom.appendChild( l_sup_trait_desc_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_sup_traits.description ))
                                                );
l_sup_master_sup_ind_node := dbms_xmldom.appendChild( l_supplier_trait_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'masterSuppIndicator' ))
                                            );
  l_sup_master_sup_ind_textnode := dbms_xmldom.appendChild( l_sup_master_sup_ind_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_sup_traits.master_sup_ind ))
                                                );
   sup_trait_rows := c_sup_traits %rowcount;
 END LOOP;

  IF  sup_trait_rows =0 
  THEN 
       l_supplier_trait_node := dbms_xmldom.appendChild( l_supplier_traits_node 
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'supplier_trait'))
                                                 );

      l_sup_trait_action_type_n := dbms_xmldom.appendChild( l_supplier_trait_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'actionType' ))
                                            );
      l_sup_trait_action_type_tn := dbms_xmldom.appendChild( l_sup_trait_action_type_n
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );

  
      l_sup_trait_node := dbms_xmldom.appendChild( l_supplier_trait_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'supplier_trait' ))
                                            );
      l_sup_trait_textnode := dbms_xmldom.appendChild( l_sup_trait_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,'' ))
                                                );

      l_sup_trait_desc_node := dbms_xmldom.appendChild( l_supplier_trait_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'supplier_trait_desc' ))
                                            );
      l_sup_trait_desc_textnode := dbms_xmldom.appendChild( l_sup_trait_desc_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
      l_sup_master_sup_ind_node := dbms_xmldom.appendChild( l_supplier_trait_node--l_addr_node--l_address_node
                                            , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'master_sup_ind' ))
                                            );
      l_sup_master_sup_ind_textnode := dbms_xmldom.appendChild( l_sup_master_sup_ind_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, '' ))
                                                );
END IF;
END;

--Custom Attributes
        -- Create a new node Custom Attributes  and add it to the supplier node
   l_cust_attributes_node := dbms_xmldom.appendChild( l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'customAttributes' ))
                                                );

--KFF
-- Each Site node will get Lead Time
      l_v_lead_time_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'leadTime' ))
                                                );
      l_v_lead_time_textnode := dbms_xmldom.appendChild( l_v_lead_time_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_lead_time)) 
);

-- Each Site node will get Back Order Flag
      l_v_back_order_flag_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'backOrderFlag' ))
                                                );
      l_v_back_order_flag_textnode := dbms_xmldom.appendChild( l_v_back_order_flag_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_back_order_flag)) 
);
     
     -- Each Site node will get Delivery Policy
      l_v_delivery_policy_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'deliveryPolicy' ))
                                                );
      l_v_delivery_policy_textnode := dbms_xmldom.appendChild( l_v_delivery_policy_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_delivery_policy)) 
);
-- Each Site node will get Min Prepaid Code
      l_v_min_prepaid_code_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'minPrepaidCode' ))
                                                );
      l_v_min_prepaid_code_textnode := dbms_xmldom.appendChild( l_v_min_prepaid_code_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_min_prepaid_code)) 

);
-- Each Site node will get Min  Amount
      l_v_vendor_min_amount_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'vendorMinAmount' ))
                                                );
      l_v_vendor_min_amount_textnode := dbms_xmldom.appendChild( l_v_vendor_min_amount_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_vendor_min_amount)) 
);

     -- Each Site node will get Supplier ship-to
      l_v_supplier_ship_to_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'supplierShipTo' ))
                                                );
      l_v_supplier_ship_to_textnode := dbms_xmldom.appendChild( l_v_supplier_ship_to_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_supplier_ship_to)) 

);
-- Each Site node will get Inventory Type Code
      l_v_inventory_type_code_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'inventoryTypeCode' ))
                                                );
      l_v_inventory_type_code_tn := dbms_xmldom.appendChild( l_v_inventory_type_code_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_inventory_type_code)) 
);
-- Each Site node will get Vertical Market Indicator
      l_v_ver_market_indicator_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'verticalMarketIndicator' ))
                                                );
      l_v_ver_market_indicator_tn := dbms_xmldom.appendChild( l_v_ver_market_indicator_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_vertical_market_indicator)) 
);
-- Each Site node will get Allow Auto-Receipt
      l_v_allow_auto_receipt_n:= dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'allowAutoReceipt' ))
                                                );
      l_v_allow_auto_receipt_tn := dbms_xmldom.appendChild( l_v_allow_auto_receipt_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_allow_auto_receipt)) 
);
-- Each Site node will get Handling
      l_v_handling_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'handling' ))
                                                );
      l_v_handling_textnode := dbms_xmldom.appendChild( l_v_handling_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_handling)) 
);
-- Each Site node will get Eft Settle Days
      l_v_eft_settle_days_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'effectiveSettleDays' ))
                                                );
      l_v_eft_settle_days_textnode := dbms_xmldom.appendChild( l_v_eft_settle_days_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_eft_settle_days)) 
);
-- Each Site node will get Split File Flag
      l_v_split_file_flag_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'splitFileFlag' ))
                                                );
      l_v_split_file_flag_textnode := dbms_xmldom.appendChild( l_v_split_file_flag_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_split_file_flag)) 
);
-- Each Site node will get Master Vendor Id
      l_v_master_vendor_id_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'masterVendorId' ))
                                                );
      l_v_master_vendor_id_textnode := dbms_xmldom.appendChild( l_v_master_vendor_id_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_master_vendor_id)) 
);

     -- Each Site node will get Pi Pack Year
      l_v_pi_pack_year_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'piPackYear' ))
                                                );
      l_v_pi_pack_year_textnode := dbms_xmldom.appendChild( l_v_pi_pack_year_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_pi_pack_year)) 
);
-- Each Site node will get OD Date Signed
      l_v_od_date_signed_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'odDateSigned' ))
                                                );
      l_v_od_date_signed_tn := dbms_xmldom.appendChild( l_v_od_date_signed_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_od_date_signed)) 

);
-- Each Site node will get Vendor Date Signed
      l_v_ven_date_signed_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'vendorDateSigned' ))
                                                );
      l_v_ven_date_signed_tn := dbms_xmldom.appendChild( l_v_ven_date_signed_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_vendor_date_signed)) 

);
-- Each Site node will get deduct from Invoice Flag
      l_v_deduct_from_inv_flag_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'deductFromInvoiceFlag' ))
                                                );
      l_v_deduct_from_inv_flag_tn := dbms_xmldom.appendChild( l_v_deduct_from_inv_flag_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_deduct_from_invoice_flag)) 
);
-- Each Site node will get New Store Flag
      l_v_new_store_flag_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'newStoreFlag' ))
                                                );
      l_v_new_store_flag_textnode := dbms_xmldom.appendChild( l_v_new_store_flag_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_new_store_flag)) 
);
-- Each Site node will get New Store Terms
      l_v_new_store_terms_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'newStoreTerms' ))
                                                );
      l_v_new_store_terms_textnode := dbms_xmldom.appendChild( l_v_new_store_terms_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_new_store_terms)) 
);
-- Each Site node will get Seasonal Flag
      l_v_seasonal_flag_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'seasonalFlag' ))
                                                );
      l_v_seasonal_flag_textnode := dbms_xmldom.appendChild( l_v_seasonal_flag_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_seasonal_flag)) 
);
-- Each Site node will get Start Date
      l_v_start_date_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'startDate' ))
                                                );
      l_v_start_date_textnode := dbms_xmldom.appendChild( l_v_start_date_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_start_date)) 
);
-- Each Site node will get End Date
      l_v_end_date_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'endDate' ))
                                                );
      l_v_end_date_textnode := dbms_xmldom.appendChild( l_v_end_date_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_end_date)) 
);


-- Each Site node will get Seasonal Terms
      l_v_seasonal_terms_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'seasonalTerms' ))
                                                );
      l_v_seasonal_terms_textnode := dbms_xmldom.appendChild( l_v_seasonal_terms_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_seasonal_terms)) 
);
-- Each Site node will get Late Ship Flag
      l_v_late_ship_flag_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'lateShipFlag' ))
                                                );
      l_v_late_ship_flag_textnode := dbms_xmldom.appendChild( l_v_late_ship_flag_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_late_ship_flag)) 
);


 l_edi_attributes_node := dbms_xmldom.appendChild( l_cust_attributes_node--l_supplier_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ediAttributes' ))
                                                );


-- Each Site node will get EDI Distribution Code
      l_v_edi_distri_code_n := dbms_xmldom.appendChild( l_edi_attributes_node--l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ediDistributionCode' ))
                                                );
      l_v_edi_distri_code_tn := dbms_xmldom.appendChild( l_v_edi_distri_code_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_edi_distribution_code)) 
);
-- Each Site node will get 850 PO
      l_v_850_po_node := dbms_xmldom.appendChild( l_edi_attributes_node--l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'po850Flag' ))
                                                );
      l_v_850_po_textnode := dbms_xmldom.appendChild( l_v_850_po_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_850_po)) 
);

-- Each Site node will get 846 Availability
      l_v_846_availability_node := dbms_xmldom.appendChild(l_edi_attributes_node-- l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'availability846Flag' ))
                                                );
      l_v_846_availability_textnode := dbms_xmldom.appendChild( l_v_846_availability_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_846_availability)) 
);


-- Each Site node will get 810 Invoice
      l_v_810_invoice_node := dbms_xmldom.appendChild( l_edi_attributes_node--l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'invoice810Flag' ))
                                                );
      l_v_810_invoice_textnode := dbms_xmldom.appendChild( l_v_810_invoice_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_810_invoice)) 
);


-- Each Site node will get 820 EFT
      l_v_820_eft_node := dbms_xmldom.appendChild( l_edi_attributes_node--l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'eft820' ))
                                                );
      l_v_820_eft_textnode := dbms_xmldom.appendChild( l_v_820_eft_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_820_eft)) 
);


-- Each Site node will get 852 Sales
      l_v_852_sales_node := dbms_xmldom.appendChild( l_edi_attributes_node--l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'sales852' ))
                                                );
      l_v_852_sales_textnode := dbms_xmldom.appendChild( l_v_852_sales_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_852_sales)) 
                                               );

-- Each Site node will get 855 Confirm PO
      l_v_855_confirm_po_n := dbms_xmldom.appendChild( l_edi_attributes_node--l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'poConfirm855Flag' ))
                                                );
      l_v_855_confirm_po_tn := dbms_xmldom.appendChild( l_v_855_confirm_po_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_855_confirm_po)) 
);

-- Each Site node will get 856 ASN
      l_v_856_asn_node := dbms_xmldom.appendChild( l_edi_attributes_node--l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'asn856Flag' ))
                                                );
      l_v_856_asn_textnode := dbms_xmldom.appendChild( l_v_856_asn_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_856_asn)) 
);

-- Each Site node will get 860 PO Change
      l_v_860_po_change_n := dbms_xmldom.appendChild( l_edi_attributes_node--l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'poChange860Flag' ))
                                                );
      l_v_860_po_change_tn := dbms_xmldom.appendChild( l_v_860_po_change_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_860_po_change)) 
  );                                         
                                      
-- Each Site node will get 861 Damage Shortage
      l_v_861_damage_shortage_n := dbms_xmldom.appendChild( l_edi_attributes_node--l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'damageShortage861Flag' ))
                                                );
      l_v_861_damage_shortage_tn := dbms_xmldom.appendChild( l_v_861_damage_shortage_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_861_damage_shortage)) 
       );

-- Each Site node will get 832 Price Sales Cat
      l_v_832_price_sales_cat_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'priceSalesCat832' ))
                                                );
      l_v_832_price_sales_cat_tn := dbms_xmldom.appendChild( l_v_832_price_sales_cat_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_832_price_sales_cat)) 
);

-- Each Site node will get RTV Option
      l_v_rtv_option_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'rtvOption' ))
                                                );
      l_v_rtv_option_textnode := dbms_xmldom.appendChild( l_v_rtv_option_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_rtv_option)) 
                                               );

-- Each Site node will get RTV Freight Payment Method
      l_v_rtv_freight_pay_method_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'rtvFreightPaymentMethod' ))
                                                );
      l_v_rtv_freight_pay_method_tn := dbms_xmldom.appendChild( l_v_rtv_freight_pay_method_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_rtv_freight_payment_method)) 
                                               );

-- Each Site node will get Permanent RGA
      l_v_permanent_rga_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'permanentRga' ))
                                                );
      l_v_permanent_rga_textnode := dbms_xmldom.appendChild( l_v_permanent_rga_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_permanent_rga)) 
                                               );
-- Each Site node will get Destroy Allow amount
      l_v_destroy_allow_amt_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'destroyAllowAmount' ))
                                                );
      l_v_destroy_allow_amt_tn := dbms_xmldom.appendChild( l_v_destroy_allow_amt_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_destroy_allow_amount)) 
                                               );

-- Each Site node will get Payment Frequency
      l_v_payment_freq_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'paymentFrequency' ))
                                                );
      l_v_payment_freq_tn := dbms_xmldom.appendChild( l_v_payment_freq_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_payment_frequency)) 
                                               );
                                               
-- Each Site node will get Min Return Qty
      l_v_min_return_qty_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'minimumReturnQuantity'))
                                                );
      l_v_min_return_qty_textnode := dbms_xmldom.appendChild( l_v_min_return_qty_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_min_return_qty)) 
                                               );

-- Each Site node will get Min Return Amt
      l_v_min_return_amount_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'minimumReturnAmount'))
                                                );
      l_v_min_return_amount_textnode := dbms_xmldom.appendChild( l_v_min_return_amount_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_min_return_amount)) 
                                               );

-- Each Site node will get Damage Destroy Limit
      l_v_damage_dest_limit_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'damageDestroyLimit'))
                                                );
      l_v_damage_dest_limit_tn := dbms_xmldom.appendChild( l_v_damage_dest_limit_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_damage_destroy_limit)) 
                                               );

-- Each Site node will get RTV Instructions
      l_v_rtv_instr_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'rtvInstructions'))
                                                );
      l_v_rtv_instr_tn := dbms_xmldom.appendChild( l_v_rtv_instr_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_rtv_instructions)) 
                                               );
                                               
-- Each Site node will get Addi.RTV Instructions
      l_v_addl_rtv_instr_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'additionalRtvInstructions'))
                                                );
      l_v_addl_rtv_instr_tn := dbms_xmldom.appendChild( l_v_addl_rtv_instr_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_addl_rtv_instructions)) 
                                               );

-- Each Site node will get RGA Marked Flag
      l_v_rga_marked_flag_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'rgaMarkedFlag'))
                                                );
      l_v_rga_marked_flag_tn := dbms_xmldom.appendChild( l_v_rga_marked_flag_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_rga_marked_flag)) 
                                               );

-- Each Site node will get Remove Price Sticker Flag
      l_v_rmv_price_sticker_flag_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'removePriceStickerFlag'))
                                                );
      l_v_rmv_price_sticker_flag_tn := dbms_xmldom.appendChild( l_v_rmv_price_sticker_flag_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_remove_price_sticker_flag)) 
                                               );

-- Each Site node will get Contact Supplier RGA Flag
      l_v_con_supp_rga_flag_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'contactSupplierRgaFlag'))
                                                );
      l_v_con_supp_rga_flag_tn := dbms_xmldom.appendChild( l_v_con_supp_rga_flag_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_contact_supplier_rga_flag)) 
                                               );

-- Each Site node will get Destroy Flag
      l_v_destroy_flag_node := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'destroyFlag'))
                                                );
      l_v_destroy_flag_textnode := dbms_xmldom.appendChild( l_v_destroy_flag_node
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_destroy_flag)) 
                                               );

-- Each Site node will get Serial Num reqd. Flag
      l_v_ser_num_req_flag_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'serialNumRequiredFlag'))
                                                );
      l_v_ser_num_req_flag_tn := dbms_xmldom.appendChild( l_v_ser_num_req_flag_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_serial_num_required_flag)) 
                                               );

-- Each Site node will get Obsolete item
      l_v_obsolete_item_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'obsoleteItem'))
                                                );
      l_v_obsolete_item_tn := dbms_xmldom.appendChild( l_v_obsolete_item_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_obsolete_item)) 
                                               );

-- Each Site node will get Obsolete item
      l_v_obso_allow_pct_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'obsoleteAllowancePercent'))
                                                );
      l_v_obso_allow_pct_tn := dbms_xmldom.appendChild( l_v_obso_allow_pct_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_obsolete_allowance_pct)) 
                                               );

-- Each Site node will get Obsolete item
      l_v_obso_allow_days_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'obsoleteAllowanceDays'))
                                                );
      l_v_obso_allow_days_tn := dbms_xmldom.appendChild( l_v_obso_allow_days_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_obsolete_allowance_days)) 
                                               );

-- Each Site node will get OD contractor signature
      l_v_od_cont_sig_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'odContSig'))
                                                );
      l_v_od_cont_sig_tn := dbms_xmldom.appendChild( l_v_od_cont_sig_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_od_cont_sig)) 
                                               );

-- Each Site node will get OD contractor title
      l_v_od_cont_title_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'odContTitle'))
                                                );
      l_v_od_cont_title_tn := dbms_xmldom.appendChild( l_v_od_cont_title_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_od_cont_title)) 
                                               );


-- Each Site node will get OD vendor sig name
      l_v_od_ven_sig_name_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'odVenSigName'))
                                                );
      l_v_od_ven_sig_name_tn := dbms_xmldom.appendChild( l_v_od_ven_sig_name_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_od_ven_sig_name)) 
                                               );

-- Each Site node will get OD vendor sig title
      l_v_od_ven_sig_title_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'odVenSigTitle'))
                                                );
      l_v_od_ven_sig_title_tn := dbms_xmldom.appendChild( l_v_od_ven_sig_title_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_od_ven_sig_title)) 
                                               );

-- Each Site node will get gss mfg id
      l_v_gss_mfg_id_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'gssMfgId'))
                                                );
      l_v_gss_mfg_id_tn := dbms_xmldom.appendChild( l_v_gss_mfg_id_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_gss_mfg_id)) 
                                               );

-- Each Site node will get gss buying agent id
      l_v_gss_buying_agent_id_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'gssBuyingAgentId'))
                                                );
      l_v_gss_buying_agent_id_tn := dbms_xmldom.appendChild( l_v_gss_buying_agent_id_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_gss_buying_agent_id)) 
                                               );

-- Each Site node will get gss_freight_id
      l_v_gss_freight_id_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'gssFreightId'))
                                                );
      l_v_gss_freight_id_tn := dbms_xmldom.appendChild( l_v_gss_freight_id_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_gss_freight_id)) 
                                               );



-- Each Site node will get gss_freight_id
      l_v_gss_ship_id_n := dbms_xmldom.appendChild( l_cust_attributes_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'gssShipId'))
                                                );
      l_v_gss_ship_id_tn := dbms_xmldom.appendChild( l_v_gss_ship_id_n
                                           , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,v_gss_ship_id)) 
                                               );

    --KFF end        
                                            
                                                
     l_xmltype := dbms_xmldom.getXmlType(l_domdoc);
   dbms_xmldom.freeDocument(l_domdoc);

   xml_output:=l_xmltype.getClobVal;

   dbms_output.put_line(xml_output);
--   dbms_output.put_line(l_xmltype.getClobVal);

  
  --fnd_file.put_line (fnd_file.LOG, 'Start of create_data_line' );
  v_file_data1 := v_globalvendor_id || c_separator || v_name || c_separator || v_vendor_site_id || c_separator || v_vendor_site_code || c_separator || 
  v_addr_flag || c_separator || v_inactive_date || c_separator || v_payment_currency_code || c_separator || v_site_lang || c_separator 
  || v_pay_site_flag || c_separator || v_purchasing_site_flag || c_separator;
  --          fnd_file.put_line (fnd_file.LOG, 'Data1:' || v_file_data1 );
  v_file_data2 := v_site_terms_name -- Translation of v_site_terms
  || c_separator || v_site_freightterms || c_separator || v_debit_memo_flag || c_separator || v_duns_num || c_separator || v_parent_name || 
  c_separator || v_parent_id || c_separator || v_tax_reg_num || c_separator;
  --         fnd_file.put_line (fnd_file.LOG, 'Data2:' || v_file_data2 );
  v_file_data3 := v_site_contact_payname || c_separator || v_site_contact_purchname || c_separator || v_site_contact_ppname || c_separator ||
  v_site_contact_rtvname || c_separator || v_site_contact_payphone || c_separator || v_site_contact_purchphone || c_separator || v_site_contact_ppphone 
  || c_separator || v_site_contact_rtvphone || c_separator || v_site_contact_payfax || c_separator || v_site_contact_purchfax || c_separator 
  || v_site_contact_ppfax || c_separator || v_site_contact_rtvfax || c_separator;
  --         fnd_file.put_line (fnd_file.LOG, 'Data3:' || v_file_data3 );
IF (v_rms_flag = 'Y') THEN  -- defect 8507
  v_file_data4 := v_site_contact_payemail || c_separator || v_site_contact_purchemail || c_separator || v_site_contact_ppemail || c_separator 
  || v_site_contact_rtvemail || c_separator || v_site_payaddr1 || c_separator || v_site_payaddr2 || c_separator || v_site_payaddr3 || c_separator 
  || v_site_paycity || c_separator || v_site_paystate || c_separator || v_site_payzip || c_separator || v_site_paycountry || '?' || v_orgcountry 
  || c_separator; -- defect 8507
  --                   fnd_file.put_line (fnd_file.LOG, 'Data4:' || v_file_data4 );
  v_file_data5 := v_site_purchaddr1 || c_separator || v_site_purchaddr2 || c_separator || v_site_purchaddr3 || c_separator || v_site_purchcity 
  || c_separator || v_site_purchstate || c_separator || v_site_purchzip || c_separator || v_site_purchcountry || '?' || v_orgcountry || c_separator 
  || v_site_ppaddr1 || c_separator || v_site_ppaddr2 || c_separator || v_site_ppaddr3 || c_separator || v_site_ppcity || c_separator || v_site_ppstate 
  || c_separator || v_site_ppzip || c_separator || v_site_ppcountry || '?' || v_orgcountry || c_separator || v_site_rtvaddr1 || c_separator 
  || v_site_rtvaddr2 || c_separator || v_site_rtvaddr3 || c_separator || v_site_rtvcity || c_separator || v_site_rtvstate || c_separator 
  || v_site_rtvzip || c_separator || v_site_rtvcountry || '?' || v_orgcountry || c_separator;  -- defect 8507
  --                   fnd_file.put_line (fnd_file.LOG, 'Data5:' || v_file_data5 );
else
  v_file_data4 := v_site_contact_payemail || c_separator || v_site_contact_purchemail || c_separator || v_site_contact_ppemail || c_separator || v_site_contact_rtvemail || c_separator || v_site_payaddr1 || c_separator || v_site_payaddr2 || c_separator || v_site_payaddr3 || c_separator || v_site_paycity || c_separator || v_site_paystate || c_separator || v_site_payzip || c_separator || v_site_paycountry || c_separator; -- defect 8507
  v_file_data5 := v_site_purchaddr1 || c_separator || v_site_purchaddr2 || c_separator || v_site_purchaddr3 || c_separator || v_site_purchcity || c_separator || v_site_purchstate || c_separator || v_site_purchzip || c_separator || v_site_purchcountry ||  c_separator || v_site_ppaddr1 || c_separator || v_site_ppaddr2 || c_separator || v_site_ppaddr3 || c_separator || v_site_ppcity || c_separator || v_site_ppstate || c_separator || v_site_ppzip || c_separator || v_site_ppcountry ||  c_separator || v_site_rtvaddr1 || c_separator || v_site_rtvaddr2 || c_separator || v_site_rtvaddr3 || c_separator || v_site_rtvcity || c_separator || v_site_rtvstate || c_separator || v_site_rtvzip || c_separator || v_site_rtvcountry ||  c_separator;  -- defect 8507
end if;


  v_file_data6 := v_primary_paysite_flag || c_separator || v_attribute8 || c_separator || v_bank_account_name || c_separator || v_bank_account_num || c_separator;
  --                   fnd_file.put_line (fnd_file.LOG, 'Data6:' || v_file_data6 );
  -- Concatenate all the fields to create the value of Attribute fields
  v_attribute10 := v_lead_time || c_separator || v_back_order_flag || c_separator || v_delivery_policy || c_separator || v_min_prepaid_code 
  || c_separator || v_vendor_min_amount || c_separator || v_supplier_ship_to || c_separator || v_inventory_type_code || c_separator 
  || v_vertical_market_indicator || c_separator || v_allow_auto_receipt || c_separator || v_handling || c_separator || v_eft_settle_days 
  || c_separator || v_split_file_flag || c_separator || v_master_vendor_id || c_separator || v_pi_pack_year || c_separator || v_od_date_signed 
  || c_separator || v_vendor_date_signed || c_separator || v_deduct_from_invoice_flag || c_separator;
  --                   fnd_file.put_line (fnd_file.LOG, 'Attr10:' || v_attribute10 );
  v_attribute11 := v_new_store_flag || c_separator || v_new_store_terms || c_separator || v_seasonal_flag || c_separator || v_start_date 
  || c_separator || v_end_date || c_separator || v_seasonal_terms || c_separator || v_late_ship_flag || c_separator || v_edi_distribution_code 
  || c_separator || v_850_po || c_separator || v_860_po_change || c_separator || v_855_confirm_po || c_separator || v_856_asn || c_separator 
  || v_846_availability || c_separator || v_810_invoice || c_separator || v_832_price_sales_cat || c_separator || v_820_eft || c_separator 
  || v_861_damage_shortage || c_separator || v_852_sales || c_separator;
  --                  fnd_file.put_line (fnd_file.LOG, 'Attr11:' || v_attribute11 );
  v_attribute12 := v_rtv_option || c_separator || v_rtv_freight_payment_method || c_separator || v_permanent_rga || c_separator 
  || v_destroy_allow_amount || c_separator || v_payment_frequency || c_separator || v_min_return_qty || c_separator || v_min_return_amount 
  || c_separator || v_damage_destroy_limit || c_separator || v_rtv_instructions || c_separator || v_addl_rtv_instructions || c_separator 
  || v_rga_marked_flag || c_separator || v_remove_price_sticker_flag || c_separator || v_contact_supplier_rga_flag || c_separator 
  || v_destroy_flag || c_separator || v_serial_num_required_flag || c_separator || v_obsolete_item || c_separator || v_obsolete_allowance_pct 
  || c_separator || v_obsolete_allowance_days || c_separator;
  --                            fnd_file.put_line (fnd_file.LOG, 'Attr12:' || v_attribute12 );
  -- Concatenate all the fields to create the value of Attribute15 field
  v_attribute15 := v_gss_mfg_id || c_separator || v_gss_buying_agent_id || c_separator || v_gss_freight_id || c_separator || v_gss_ship_id;
  --         fnd_file.put_line (fnd_file.LOG, 'Attr15:' || v_attribute15 );
  -- fnd_file.put_line (fnd_file.LOG, 'end of create_data_line' );
END create_data_line;
/*Defect# 29479 Added for BUSS_CLASS_ATTR_FUNC for RMS type*/
FUNCTION buss_class_attr_func(p_vendor_site_id IN NUMBER)
RETURN VARCHAR2
IS
lv_attribute16 varchar2(4000);
lv_vend_id number;
lv_attr   varchar2(10);
lv_ext_attr_1 varchar2(10);
lv_separator varchar2(10) := ';';
 /*lv_mbe   varchar2(500);
 lv_nmsdc varchar2(500);
 lv_wbe   varchar2(500);
 lv_wbenc varchar2(500);
 lv_vob   varchar2(500);
 lv_dodva varchar2(500);
 lv_doe   varchar2(500);
 lv_usbln varchar2(500);
 lv_lgbt  varchar2(500);
 lv_nglcc varchar2(500);
 lv_nibnishablty varchar2(500);
 lv_fob   varchar2(500);
 lv_sb    varchar2(500);
 lv_samgov varchar2(500);
 lv_sba   varchar2(500);
 lv_sbc   varchar2(500);
 lv_sdbe  varchar2(500);
 lv_sba8a varchar2(500);
 lv_hubzone varchar2(500);
 lv_wosb  varchar2(500);
 lv_wsbe  varchar2(500);
 lv_edwosb varchar2(500);
 lv_vosb  varchar2(500);
 lv_sdvosb varchar2(500);
 lv_hbcumi varchar2(500);
 lv_anc  varchar2(500);
 lv_ind  varchar2(500);
 lv_minority_owned varchar2(500);
 */
CURSOR c_buss_attr
IS
SELECT *
FROM FND_LOOKUP_VALUES_VL
WHERE Lookup_type ='POS_BUSINESS_CLASSIFICATIONS'
AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
order by to_number(attribute1);

BEGIN
--fnd_file.PUT_LINE(fnd_file.LOG,'Supplier Site ID :'||p_vendor_site_id);
SELECT vendor_id
  INTO lv_vend_id
  FROM ap_supplier_sites_all apss
 WHERE apss.vendor_site_id = p_vendor_site_id;
FOR r_buss_attr in c_buss_attr
LOOP
  --fnd_file.PUT_LINE(fnd_file.LOG,'r_buss_attr.lookup_code'||r_buss_attr.lookup_code);
       BEGIN
        SELECT 'Y',ext_attr_1
          INTO lv_attr,lv_ext_attr_1
          FROM pos_bus_class_attr pbca
         WHERE vendor_id = lv_vend_id
           AND lookup_code = r_buss_attr.lookup_code
           AND status = 'A'
           AND nvl(end_date_active,sysdate+1) > sysdate;

         IF r_buss_attr.lookup_code = 'FOB'
          THEN
           lv_attribute16 := lv_attribute16||lv_separator||lv_ext_attr_1;
          ELSIF r_buss_attr.lookup_code = 'MINORITY_OWNED'
          THEN
           lv_attribute16 := lv_attribute16||lv_separator||lv_ext_attr_1;
          ELSE
           lv_attribute16 := lv_attribute16||lv_separator||lv_attr;
          END IF;

        EXCEPTION
         WHEN OTHERS THEN
            lv_attribute16 := lv_attribute16||lv_separator||'N';
--            dbms_output.put_line('In when other lookup code'||r_buss_attr.lookup_code||'l_v_attr '||lv_attr ||'lv_ext_attr_1 '||lv_ext_attr_1);
          --fnd_file.PUT_LINE(fnd_file.LOG,'IN EXCEPTION 1:'||SQLERRM);
        END;
--dbms_output.put_line('lv_attribute16'||lv_attribute16);
--dbms_output.put_line('lookup code'||r_buss_attr.lookup_code||'l_v_attr '||lv_attr ||'lv_ext_attr_1 '||lv_ext_attr_1);

END LOOP;
return lv_attribute16;

EXCEPTION
WHEN OTHERS THEN
 fnd_file.PUT_LINE(fnd_file.LOG,'MAIN EXCEPTION :'||SQLERRM);
END buss_class_attr_func;
--=========
BEGIN
FND_GLOBAL.APPS_INITIALIZE(3817336,50660,20043);
  v_extract_time := sysdate;
  --cast(systimestamp as timestamp); --to_char(c_when, 'DD-MON-YY HH:Mi:SS');
  --    v_extract_time := to_char(sysdate, 'DD-MON-YY HH24:Mi:SS');
  -- Add code for File open
  DBMS_OUTPUT.PUT_LINE('Current Extract Time is:' || to_char(v_extract_time,   'DD-MON-YY HH24:Mi:SS'));
  ---+===============================================================================================
  ---|  Select the directory path for XXFIN_OUTBOUND directory
  ---+===============================================================================================

--DBMS_OUTPUT.PUT_LINE('653:');
  BEGIN
    SELECT directory_path
    INTO lc_sourcepath
    FROM dba_directories
    WHERE directory_name = c_file_path;
  EXCEPTION
  WHEN no_data_found THEN
    lc_err_status := 'Y';
    lc_err_mesg := 'DBA Directory : ' || c_file_path || ': Not Defined';
    fnd_file.PUT_LINE(fnd_file.LOG,   'Error : ' || lc_err_mesg);
    lc_err_flag := 'Y';
  END;
--DBMS_OUTPUT.PUT_LINE('666');
  -- Update Extract time
--  UPDATE xx_ap_supp_extract--sunil
 -- SET extract_time = v_extract_time;--sunil
  -- Fetch the rows for the 3 external systems ;
 /* OPEN extsupplupdate_cur;
  fnd_file.PUT_LINE(fnd_file.LOG,   '********************* BPEL INFORMATION *******************************************************');
  LOOP
    FETCH extsupplupdate_cur
    INTO v_system,
      v_last_update_date,
      v_extract_time,
      v_bpel_run_flag;
    EXIT
  WHEN NOT extsupplupdate_cur % FOUND;
  -- Process the rows in the table ;
  DBMS_OUTPUT.PUT_LINE('System:' || v_system || ' Last Update Time from Table:' || to_char(v_last_update_date,   'DD-MON-YY HH24:Mi:SS'));
  CASE v_system
WHEN 'GSS' THEN
  v_gss_last_update := v_last_update_date;
  --to_timestamp(v_last_update_date,   'DD-MON-YY HH:MM:SS');
WHEN 'RMS' THEN
  v_rms_last_update := v_last_update_date;
  --to_timestamp(v_last_update_date,   'DD-MON-YY HH:MM:SS');
WHEN 'PSFT' THEN
  v_psft_last_update := v_last_update_date;
  -- to_timestamp(v_last_update_date,  'DD-MON-YY HH:MM:SS');
ELSE
  DBMS_OUTPUT.PUT_LINE('Invalid System');
END
CASE;
fnd_file.PUT_LINE(fnd_file.LOG,   'System=' || v_system || ' Last Updated=' || to_char(v_last_update_date,   'DD-MON-YY HH24:Mi:SS') || ' BPEL status=' || v_bpel_run_flag);
-- If BPEL is running then exit this process.
IF v_bpel_run_flag = 'Y' THEN
  v_exit_flag := 'Y';
END IF;
END LOOP;*/--sunil
fnd_file.PUT_LINE(fnd_file.LOG,   '****************************************************************************');
fnd_file.PUT_LINE(fnd_file.LOG,   '          ');
-- Get Minimum Extract time
/*SELECT MIN(last_update_date)
INTO v_last_update_date
FROM xx_ap_supp_extract;*/--sunil
fnd_file.PUT_LINE(fnd_file.LOG,   'Minimum Last Update Time:' || to_char(v_last_update_date,   'DD-MON-YY HH24:Mi:SS'));
--DBMS_OUTPUT.PUT_LINE('710'||v_exit_flag);
IF v_exit_flag = 'N' THEN
--+************************************************************************************+
--+ Added commit for the Defect 7600 to Release lock on table xx_ap_supp_extract +
 --+************************************************************************************+
--commit;--sunil
--DBMS_OUTPUT.PUT_LINE('opening cursor');
OPEN mainsupplupdate_cur;
--      DBMS_OUTPUT.put_line ('Open Cursor for Main Supplier');
fnd_file.PUT_LINE(fnd_file.LOG,   ' Supplier Data Read from ' || to_char(v_last_update_date,   'DD-MON-YY HH24:Mi:SS') || ' to ' || to_char(v_extract_time,   'DD-MON-YY HH24:Mi:SS'));
fnd_file.PUT_LINE(fnd_file.LOG,   'Supplier Site ID ' || '*' || 'Site Code ' || '*' || 'Name ');
-- Main Cursor to read all the data ;
LOOP
 -- v_gss_flag := 'N';
  v_rms_flag := 'N';
 -- v_psft_flag := 'N';
  init_variables;
  init_kffvariables;
  FETCH mainsupplupdate_cur
  INTO v_vendor_site_id,
    v_attribute8,
    v_attribute13,
    v_vendor_site_code,
    v_site_last_update,
    v_purchasing_site_flag,
    v_pay_site_flag,
    v_address_line1,
    v_address_line2,
    v_address_line3,
    v_city,
    v_state,
    v_zip,
    v_country,
    v_area_code,
    v_phone,
    v_inactive_date,
    v_pay_group_lookup_code,
    v_payment_method_lookup_code,
    v_payment_currency_code,
    v_primary_paysite_flag,
    v_site_freightterms,
    v_po_site_vat_registration,
    v_site_language,
    v_bank_account_num,
    v_bank_account_name,
    v_duns_num,
    v_site_contact_id,
    v_site_contact_fname,
    v_site_contact_lname,
    v_site_contact_areacode,
    v_site_contact_phone,
    v_site_contact_email,
    v_site_contact_fareacode,
    v_site_contact_fphone,
    v_site_contact_last_update,
    v_name,
    v_vendor_last_update,
    v_po_vendor_vat_registration,
    v_terms_date_basis,
    v_vendor_type_lookup_code,
    v_parent_vendor_id,
    v_tax_reg_num,
    v_minority_cd,
    v_supp_attribute7,
    v_supp_attribute8,
    v_supp_attribute9,
    v_supp_attribute10,
    v_supp_attribute11,
    v_debit_memo_flag,
    v_province,
    v_site_terms,
    v_site_orgid,
        v_telex;  -- V4.0, added
  -- use vendor_type_lookup_code = 'GARNISHMENT' to identify Garnishment suppliers
--DBMS_OUTPUT.PUT_LINE('784 before exit'||v_vendor_site_id);
  EXIT
WHEN NOT mainsupplupdate_cur % FOUND;
--DBMS_OUTPUT.PUT_LINE('787 after exit');
-- Identify the System
-- GSS: Paysites for Expense Suppliers where the VENDOR_SITE_CODE starts with ?EX? and site category with 'EX'
-- RMS: Trade Suppliers with site code starting with TR and Expense Suppliers VENDOR_SITE_CODE like ?EXP-IMP%?
-- PSFT: Vendor_type_lookup_code = 'GARNISHMENT'
/*      fnd_file.put_line (fnd_file.LOG, v_rms_count );
      fnd_file.put_line(fnd_file.log, 'f=' || v_site_contact_fname ||
               ' L=' ||  v_site_contact_lname ||
               ' Area='|| v_site_contact_areacode ||
               ' Phone='|| v_site_contact_phone ||
               ' Email='|| v_site_contact_email ||
               ' FArea='|| v_site_contact_fareacode ||
               ' Fphone='|| v_site_contact_fphone);
*/

--  fnd_file.PUT_LINE(fnd_file.LOG,'Inside loop');
  fnd_file.PUT_LINE(fnd_file.LOG,'Vendor Site :'||v_vendor_site_code);
--DBMS_OUTPUT.PUT_LINE('vendor site id 805'||v_vendor_site_id);
  g_vendor_site_id:=NULL;
  /*Defect# 29479 calling BUSS_CLASS_ATTR_FUNC for RMS type*/
  v_attribute16 := buss_class_attr_func(v_vendor_site_id);

 v_site_phone := v_site_contact_areacode || v_site_contact_phone;
v_site_phone := SUBSTR(REPLACE(v_site_phone,   '-',   ''),   1,   11);
v_site_fax := v_site_contact_fareacode || v_site_contact_fphone;
v_site_fax := SUBSTR(REPLACE(v_site_fax,   '-',   ''),   1,   11);
IF((v_country <> 'US')
 AND v_state IS NULL) THEN
  v_state := v_province;
END IF;
--DBMS_OUTPUT.PUT_LINE('818'||v_vendor_site_id);
/*IF(((v_vendor_type_lookup_code = 'GARNISHMENT') OR(v_vendor_type_lookup_code = 'CONTINGENT WORKER'))
 AND(v_primary_paysite_flag = 'Y')) THEN
  -- check the last update time and if it valid then set the flag;

  v_psft_flag := 'Y';
  g_vendor_site_id:=v_vendor_site_id;

  v_date_diff := CAST(v_site_last_update AS
  TIMESTAMP) -CAST(v_psft_last_update AS
  TIMESTAMP);
--  IF(CAST(v_site_last_update AS
--  TIMESTAMP) > CAST(v_psft_last_update AS
--  TIMESTAMP)) THEN
--    v_psft_flag := 'Y';
--  END IF;
--  IF(CAST(v_vendor_last_update AS
--  TIMESTAMP) > CAST(v_psft_last_update AS
--  TIMESTAMP)) THEN
--    v_psft_flag := 'Y';
--  END IF;
END IF;*/--Sunil
-- All Expense vendors with Site Category of EX-IMP will be sent.
/*IF((SUBSTR(v_attribute8,   1,   6) = 'EX-IMP')
 AND v_pay_site_flag = 'Y') THEN
  -- check the last update time and if it valid then set the flag

  v_gss_flag := 'Y';
  g_vendor_site_id:=v_vendor_site_id;

--  IF(CAST(v_site_last_update AS
--  TIMESTAMP) > CAST(v_gss_last_update AS
--  TIMESTAMP)) THEN
--    v_gss_flag := 'Y';
--  END IF;
  v_date_diff := CAST(v_vendor_last_update AS
  TIMESTAMP) -CAST(v_gss_last_update AS
  TIMESTAMP);

--  IF(CAST(v_vendor_last_update AS
--  TIMESTAMP) > CAST(v_gss_last_update AS
--  TIMESTAMP)) THEN
--    v_gss_flag := 'Y';
--  END IF;
END IF;*/
--DBMS_OUTPUT.PUT_LINE('863'||v_attribute8);
IF((SUBSTR(v_attribute8,   1,   2) = 'TR')) -- Defect 6547             OR (SUBSTR (v_attribute8, 1, 6) = 'EX-IMP'))
THEN
    v_rms_flag := 'Y';
    g_vendor_site_id:=v_vendor_site_id;

-- check the last update time and if it valid then set the flag
--  IF(CAST(v_site_last_update AS
--  TIMESTAMP) > CAST(v_rms_last_update AS
--  TIMESTAMP)) THEN
--    v_rms_flag := 'Y';
--  END IF;
--  IF(CAST(v_site_contact_last_update AS
--  TIMESTAMP) > CAST(v_rms_last_update AS
--  TIMESTAMP)) THEN
--    v_rms_flag := 'Y';
--  END IF;
--  IF(CAST(v_vendor_last_update AS
--  TIMESTAMP) > CAST(v_rms_last_update AS
--  TIMESTAMP)) THEN
--    v_rms_flag := 'Y';
--  END IF;
  --   dbms_output.put_line('Vendor Timestamp:' || cast(v_vendor_last_update as timestamp) || 'RMS Timestamp:' || cast(v_rms_last_update as timestamp) ||' RMS flag:' || v_rms_flag);
END IF;
/*IF v_gss_flag = 'Y' THEN
  -- Get GSS attribute values from KFF;
  fnd_file.PUT_LINE(fnd_file.LOG,   'GSS Supplier selected:' || v_vendor_site_id || ' ' || v_vendor_site_code || ' ' || v_name);
  BEGIN
    SELECT manufacturing_site_id,
      buying_agent_site_id,
      freight_forwarder_site_id,
      ship_from_port_id
    INTO v_gss_mfg_id,
      v_gss_buying_agent_id,
      v_gss_freight_id,
      v_gss_ship_id
    FROM xx_po_vendor_sites_kff_v
    WHERE vendor_site_id = v_vendor_site_id;
  EXCEPTION
  WHEN no_data_found THEN
    v_gss_mfg_id := NULL;
    v_gss_buying_agent_id := NULL;
    v_gss_freight_id := NULL;
    v_gss_ship_id := NULL;
  END;
  --if ((v_purchasing_site_flag = 'N') and (v_pay_site_flag = 'Y'))  then
  IF(v_pay_site_flag = 'Y') THEN
    v_addr_flag := 3;
    v_site_payaddr1 := v_address_line1;
    v_site_payaddr2 := v_address_line2;
    v_site_payaddr3 := v_address_line3;
    v_site_paycity := v_city;
    v_site_paystate := v_state;
    v_site_payzip := v_zip;
    v_site_paycountry := v_country;
    v_site_contact_payphone := v_site_phone;
    v_site_contact_payfax := v_site_fax;
    v_site_contact_payemail := v_site_contact_email;
    v_site_contact_payname := v_site_contact_name;
  END IF;
  IF(v_payment_method_lookup_code = 'CLEARING' OR v_payment_method_lookup_code = 'WIRE') THEN
    v_bank_account_num := 'PPD';
  END IF;
END IF;*/--sunil
IF v_rms_flag = 'Y' THEN
  fnd_file.PUT_LINE(fnd_file.LOG,   'RMS Supplier selected:' || v_vendor_site_id || ' ' || v_vendor_site_code || ' ' || v_name);
--DBMS_OUTPUT.PUT_LINE( 'RMS Supplier selected:' || v_vendor_site_id || ' ' || v_vendor_site_code || ' ' || v_name);
-- Defect 7007 CR395

         BEGIN
         --------------------------------------------
         -- Per Defect 14433 added IF statement below
         --------------------------------------------
         IF v_site_orgid = 404 THEN
            v_country := 'US';
         ELSIF v_site_orgid = 403 THEN
            v_country := 'CA';
         ELSE
            fnd_file.PUT_LINE(fnd_file.LOG,   'Invalid ORG_ID:  ' || v_site_orgid || ' Country code may not be derived correctly '
                                               || 'from AP_RMS_TO_LEGACY_BANK translation table.');
         END IF;
         xx_fin_translate_pkg.xx_fin_translatevalue_proc
                                    (
                                     p_translation_name    => 'AP_RMS_TO_LEGACY_BANK'
                                     ,p_source_value1      => v_payment_method_lookup_code
                                     ,p_source_value2      => v_payment_currency_code
                                     ,p_source_value3      => v_country
                                     ,x_target_value1      => x_target_value1
                                     ,x_target_value2      => x_target_value2
                                     ,x_target_value3      => x_target_value3
                                     ,x_target_value4      => x_target_value4
                                     ,x_target_value5      => x_target_value5
                                     ,x_target_value6      => x_target_value6
                                     ,x_target_value7      => x_target_value7
                                     ,x_target_value8      => x_target_value8
                                     ,x_target_value9      => x_target_value9
                                     ,x_target_value10     => x_target_value10
                                     ,x_target_value11     => x_target_value11
                                     ,x_target_value12     => x_target_value12
                                     ,x_target_value13     => x_target_value13
                                     ,x_target_value14     => x_target_value14
                                     ,x_target_value15     => x_target_value15
                                     ,x_target_value16     => x_target_value16
                                     ,x_target_value17     => x_target_value17
                                     ,x_target_value18     => x_target_value18
                                     ,x_target_value19     => x_target_value19
                                     ,x_target_value20     => x_target_value20
                                     ,x_error_message      => x_error_message
                                    );
          v_bank_account_num := x_target_value1;
          v_bank_account_name := x_target_value1;
/*          fnd_file.PUT_LINE(fnd_file.LOG,   ' Bank Code for Site ID:' || v_vendor_site_id
               || ' ' || v_payment_method_lookup_code || ' ' || v_payment_currency_code
               || ' ' || v_country  || ' ' || x_target_value1);   */
         EXCEPTION
         WHEN OTHERS
            THEN
               fnd_file.PUT_LINE(fnd_file.LOG,   'Error retreiving Bank Code for Site ID:' || v_vendor_site_id
               || ' ' || v_payment_method_lookup_code || ' ' || v_payment_currency_code
               || v_country);
         END;
-- end of Defect 7007 CR395
  -- Purchase Site with Paysite specified.
  --check attribute13 for Purchase sites to get the Pay site
  v_site_exists_flag := 'Y';
  IF((v_attribute13 IS NOT NULL)
   AND(v_purchasing_site_flag = 'Y')
   AND(v_pay_site_flag = 'N')) THEN
    -- Assign the Pay site value from Purchase Site DFF
    v_vendor_site_id := to_number(v_attribute13);
    IF v_site_exists_flag = 'Y' THEN
      -- get the data from the Paysite other than Address and Contact information
      BEGIN
        SELECT a.inactive_date,
          a.pay_group_lookup_code,
          --ieppm.payment_method_code, -- V4.0 a.payment_method_lookup_code,--commented for defect 33188
		  nvl(ieppm.payment_method_code,'CHECK'),--Added for defect 33188
          a.payment_currency_code,
          a.primary_pay_site_flag,
          nvl(a.freight_terms_lookup_code,   'CC'),
          a.vat_registration_num,
          a.LANGUAGE,
--          a.bank_account_num,
--          a.bank_account_name,
          a.duns_number,
          -- DUNNS number
        nvl(a.create_debit_memo_flag,   'N'),
          a.province,
          a.terms_id,
          a.org_id
        INTO v_inactive_date,
          v_pay_group_lookup_code,
          v_payment_method_lookup_code,
          v_payment_currency_code,
          v_primary_paysite_flag,
          v_site_freightterms,
          v_po_site_vat_registration,
          v_site_language,
--          v_bank_account_num,
--          v_bank_account_name,
          v_duns_num,
          v_debit_memo_flag,
          v_province,
          v_site_terms,
          v_site_orgid
        FROM AP_SUPPLIER_SITES_ALL a, -- V4.0 po_vendor_sites_all a
             iby_external_payees_all iepa,  --V4.0
             iby_ext_party_pmt_mthds ieppm  --V4.0
        WHERE a.vendor_site_id = v_vendor_site_id
         -- V4.0
          AND a.vendor_site_id = iepa.supplier_site_id
          AND iepa.ext_payee_id = ieppm.ext_pmt_party_id(+)
          AND( (ieppm.inactive_date IS NULL)or (ieppm.inactive_date > sysdate));
      EXCEPTION
      WHEN others THEN
        fnd_file.PUT_LINE(fnd_file.LOG,   'Error retreiving Site data: for ' || v_vendor_site_id);
      END;
    END IF;
  END IF;
  v_site_lang := 1;
  -- for English from RMS table
  IF(v_inactive_date IS NOT NULL) THEN
    BEGIN
      v_inactive_date := to_char(to_date(v_inactive_date,   'DD-MON-YY'),   'YYYY-MM-DD');
    EXCEPTION
    WHEN others THEN
      fnd_file.PUT_LINE(fnd_file.LOG,   'Error Inactive Date:' || v_inactive_date);
      v_inactive_date := to_char(to_date(TRUNC(sysdate),   'DD-MON-YY'),   'YYYY-MM-DD');
    END;
    --                           fnd_file.put_line (fnd_file.LOG, 'Inactive Date:'||v_inactive_date);
  END IF;
  -- logic for Address Flag;
  -- 0 ? for Return To Vendor address (address type 03),1 ? for address type 01
  -- 2 ? for address types 01, 04 ,   3 -  for address types 01, 05
  -- 4 - for address types 01, 04, 05
  --01 :  Company Address
  --01,04: Purchase Site Flag has been set
  --03: None of the flags have been set (Purchase or Pay) and Site Category = TR-RTV-ADDR
  --05: Pay Site Flag has been set
  --01,04,05: Both Purchase and Pay Site flags have been set.
  v_site_contact_name := v_site_contact_fname || ' ' || v_site_contact_lname;
  IF v_site_contact_name = ' ' THEN
    v_site_contact_name := NULL;
  END IF;
  IF((v_purchasing_site_flag = 'N')
   AND(v_pay_site_flag = 'N')) THEN
    -- if RTV site is changed then don't send anything until the Paysite related to
    -- RTV is updated.
    v_rms_flag := 'Y'; -- V4.0 'N';
    -- RTV address (03: None of the flags have been set (Purchase or Pay))
    --V4.0, Commented out
                 v_addr_flag := 0;
               v_site_rtvaddr1 := v_address_line1;
               v_site_rtvaddr2 := v_address_line2;
               v_site_rtvaddr3 := v_address_line3;
               v_site_rtvcity := v_city;
               v_site_rtvstate := v_state;
               v_site_rtvzip := v_zip;
               v_site_rtvcountry := v_country;
               v_site_contact_rtvphone := v_site_phone;
               v_site_contact_rtvfax := v_site_fax;
               v_site_contact_rtvemail := v_site_contact_email;
               v_site_contact_rtvname := v_site_contact_name;

  END IF;
  IF((v_purchasing_site_flag = 'Y')
   AND(v_pay_site_flag = 'N')) THEN
    -- Purchasing address  (01,04: Purchase Site Flag has been set)
    v_addr_flag := 2;
    v_site_purchaddr1 := v_address_line1;
    v_site_purchaddr2 := v_address_line2;
    v_site_purchaddr3 := v_address_line3;
    v_site_purchcity := v_city;
    v_site_purchstate := v_state;
    v_site_purchzip := v_zip;
    v_site_purchcountry := v_country;
    v_site_contact_purchphone := v_site_phone;
    v_site_contact_purchfax := v_site_fax;
    v_site_contact_purchemail := v_site_contact_email;
    v_site_contact_purchname := v_site_contact_name;
  END IF;
  IF((v_purchasing_site_flag = 'N')
   AND(v_pay_site_flag = 'Y')) THEN
    -- Pay Site Flag  (05: Pay Site Flag has been set)
    v_addr_flag := 3;
    v_site_payaddr1 := v_address_line1;
    v_site_payaddr2 := v_address_line2;
    v_site_payaddr3 := v_address_line3;
    v_site_paycity := v_city;
    v_site_paystate := v_state;
    v_site_payzip := v_zip;
    v_site_paycountry := v_country;
    v_site_contact_payphone := v_site_phone;
    v_site_contact_payfax := v_site_fax;
    v_site_contact_payemail := v_site_contact_email;
    v_site_contact_payname := v_site_contact_name;
  END IF;
  IF((v_purchasing_site_flag = 'Y')
   AND(v_pay_site_flag = 'Y')) THEN
    -- Pay/Purchase address  (01,04,05: Both Purchase and Pay Site flags have been set.)
    v_addr_flag := 4;
    v_site_ppaddr1 := v_address_line1;
    v_site_ppaddr2 := v_address_line2;
    v_site_ppaddr3 := v_address_line3;
    v_site_ppcity := v_city;
    v_site_ppstate := v_state;
    v_site_ppzip := v_zip;
    v_site_ppcountry := v_country;
    v_site_contact_ppphone := v_site_phone;
    v_site_contact_ppfax := v_site_fax;
    v_site_contact_ppemail := v_site_contact_email;
    v_site_contact_ppname := v_site_contact_name;
  END IF;
  -- Translate Vendor Site Payment Terms
  BEGIN
    IF v_site_terms IS NOT NULL THEN
      --                     fnd_file.put_line (fnd_file.LOG, 'Site Terms:' || v_site_terms || ' ' || v_terms_date_basis);
      BEGIN
        v_site_terms_name := NULL;
        SELECT name,description
        INTO v_site_terms_name,v_site_terms_name_desc
        FROM ap_terms_tl
        WHERE term_id = v_site_terms
         AND enabled_flag = 'Y'
         AND(start_date_active <= sysdate
         AND(end_date_active >= sysdate OR end_date_active IS NULL));
      EXCEPTION
      WHEN others THEN
        v_site_terms_name := NULL;
      END;
      --                     fnd_file.put_line (fnd_file.LOG, 'Site Terms Name:' || v_site_terms_name );
      xx_fin_translate_pkg.xx_fin_translatevalue_proc('AP_PAYMENT_TERMS_RMS' --translation_name
      ,   sysdate,   v_site_terms_name --source_value1
      ,   v_terms_date_basis --'Invoice'  --source_value2
      ,   NULL --source_value3
      ,   NULL --source_value4
      ,   NULL --source_value5
      ,   NULL --source_value6
      ,   NULL --source_value7
      ,   NULL --source_value8
      ,   NULL --source_value9
      ,   NULL --source_value10
      ,   x_target_value1,   x_target_value2,   x_target_value3,   x_target_value4,   x_target_value5,   x_target_value6,   x_target_value7,   x_target_value8,   x_target_value9,   x_target_value10,   x_target_value11,   x_target_value12,   x_target_value13,   x_target_value14,   x_target_value15,   x_target_value16,   x_target_value17,   x_target_value18,   x_target_value19,   x_target_value20,   x_error_message);
      v_site_terms_name := x_target_value1;
      --                        fnd_file.put_line (fnd_file.LOG, 'Translation Site Terms:' || v_site_terms_name );
    END IF;
  EXCEPTION
  WHEN others THEN
    fnd_file.PUT_LINE(fnd_file.LOG,   'Error deriving the RMS Payment Terms for ' || v_site_terms || ' ' || x_error_message);
    v_site_terms_name := NULL;
  END;
  BEGIN
    BEGIN
      SELECT k.lead_time,
        nvl(k.back_order_flag,   'N'),
        decode(k.delivery_policy,   'NEXT DAY',   'NEXT',   'NEXT VALID DELIVERY DAY',   'NDD'),
        --defect 2192
      k.min_prepaid_code,
        k.vendor_min_amount,
        k.supplier_ship_to,
        k.inventory_type_code,
        k.vertical_market_indicator,
        nvl(k.allow_auto_receipt,   'N'),
        k.handling,
        k.eft_settle_days,
        nvl(k.split_file_flag,   'N'),
        k.master_vendor_id,
        k.pi_pack_year,
        k.od_date_signed,
        k.vendor_date_signed,
        nvl(k.deduct_from_invoice_flag,   'N'),
        k.min_bus_category,
        nvl(k.new_store_flag,   'N'),
        k.new_store_terms,
        nvl(k.seasonal_flag,   'N'),
        k.start_date,
        k.end_date,
        k.seasonal_terms,
        nvl(k.late_ship_flag,   'N'),
        k.edi_distribution_code,
        k.od_contract_signature,
        k.od_contract_title,
        nvl(k.rtv_option,   '1'),
        --
      decode(k.rtv_freight_payment_method,   'COLLECT',   'CC',   'PREPAID',   'PP',   'NEITHER',   'NN'),
        --defect 2192
      k.permanent_rga,
        k.destroy_allow_amount,
--        decode(k.payment_frequency,   'WEEKLY',   'W',   'DAILY',   'D',   'MONTHLY',   'M',   'QUARTERLY',   'Q',   'W'),
        decode(k.payment_frequency,   'WEEKLY',   'W',   'DAILY',   'D',   'MONTHLY',   'M',   'QUARTERLY',   'Q',   ''),  -- Defect 6517
        k.min_return_qty,
        k.min_return_amount,
        k.damage_destroy_limit,
        k.rtv_instructions,
        k.addl_rtv_instructions,
        nvl(k.rga_marked_flag,   'N'),
        nvl(k.remove_price_sticker_flag,   'N'),
        nvl(k.contact_supplier_for_rga_flag,   'N'),
        nvl(k.destroy_flag,   'N'),
        decode(k.serial_num_required_flag,   'N',   'N',   'Y',   'Y',   'N'),
        -- if field edit not created in EBS
      k.obsolete_item,
        k.obsolete_allowance_pct,
        k.obsolete_allowance_days,
        nvl(k."850_PO",   'N'),
        nvl(k."860_PO_CHANGE",   'N'),
        nvl(k."855_CONFIRM_PO",   'N'),
        nvl(k."856_ASN",   'N'),
        nvl(k."846_AVAILABILITY",   'N'),
        nvl(k."810_INVOICE",   'N'),
        nvl(k."832_PRICE_SALES_CAT",   'N'),
        nvl(k."820_EFT",   'N'),
        nvl(k."861_DAMAGE_SHORTAGE",   'N'),
        decode(k."852_SALES",   'WEEKLY',   'W',   'DAILY',   'D',   'MONTHLY',   'M',   'W'),
        k.rtv_related_site,
        k.od_vendor_signature_name,
        k.od_vendor_signature_title,
        k.manufacturing_site_id,
        k.buying_agent_site_id,
        k.freight_forwarder_site_id,
        k.ship_from_port_id 
      INTO v_lead_time,
        v_back_order_flag,
        v_delivery_policy,
        v_min_prepaid_code,
        v_vendor_min_amount,
        v_supplier_ship_to,
        v_inventory_type_code,
        v_vertical_market_indicator,
        v_allow_auto_receipt,
        v_handling,
        v_eft_settle_days,
        v_split_file_flag,
        v_master_vendor_id,
        v_pi_pack_year,
        v_od_date_signed,
        v_vendor_date_signed,
        v_deduct_from_invoice_flag,
        v_min_bus_category,
        v_new_store_flag,
        v_new_store_terms,
        v_seasonal_flag,
        v_start_date,
        v_end_date,
        v_seasonal_terms,
        v_late_ship_flag,
        v_edi_distribution_code,
        v_od_cont_sig,
        v_od_cont_title,
        v_rtv_option,
        v_rtv_freight_payment_method,
        v_permanent_rga,
        v_destroy_allow_amount,
        v_payment_frequency,
        v_min_return_qty,
        v_min_return_amount,
        v_damage_destroy_limit,
        v_rtv_instructions,
        v_addl_rtv_instructions,
        v_rga_marked_flag,
        v_remove_price_sticker_flag,
        v_contact_supplier_rga_flag,
        v_destroy_flag,
        v_serial_num_required_flag,
        v_obsolete_item,
        v_obsolete_allowance_pct,
        v_obsolete_allowance_days,
        v_850_po,
        v_860_po_change,
        v_855_confirm_po,
        v_856_asn,
        v_846_availability,
        v_810_invoice,
        v_832_price_sales_cat,
        v_820_eft,
        v_861_damage_shortage,
        v_852_sales,
        v_rtv_related_siteid,
        v_od_ven_sig_name,
        v_od_ven_sig_title,
        v_gss_mfg_id,
        v_gss_buying_agent_id,
        v_gss_freight_id,
        v_gss_ship_id
        FROM xx_po_vendor_sites_kff_v k
      WHERE k.vendor_site_id = v_vendor_site_id;
   --   DBMS_OUTPUT.PUT_LINE('line 1289 after KFF');
    EXCEPTION
    WHEN others THEN
      fnd_file.PUT_LINE(fnd_file.LOG,   'Error retreiving KFF Site data: for ' || v_vendor_site_id);
    END;
    -- Following is the default value for testing till we get Translation setup
    BEGIN
      IF v_delivery_policy IS NULL THEN
        v_delivery_policy := 'NEXT';
      END IF;
      IF v_rtv_freight_payment_method IS NULL THEN
        v_rtv_freight_payment_method := 'CC';
      END IF;
      IF v_new_store_terms IS NOT NULL THEN
        BEGIN
          v_terms_name := NULL;
          SELECT name
          INTO v_terms_name
          FROM ap_terms_tl
          WHERE term_id = v_new_store_terms
           AND enabled_flag = 'Y'
           AND(start_date_active <= sysdate
           AND(end_date_active >= sysdate OR end_date_active IS NULL));
        EXCEPTION
        WHEN others THEN
          v_terms_name := NULL;
        END;
        /*                     fnd_file.put_line (fnd_file.LOG,
                            'Store Terms: ' || v_new_store_terms || ' =' || v_terms_name
                        );
*/
         xx_fin_translate_pkg.xx_fin_translatevalue_proc('AP_PAYMENT_TERMS_RMS' --translation_name
        ,   sysdate,   v_terms_name --source_value1
        ,   v_terms_date_basis --source_value2
        ,   NULL --source_value3
        ,   NULL --source_value4
        ,   NULL --source_value5
        ,   NULL --source_value6
        ,   NULL --source_value7
        ,   NULL --source_value8
        ,   NULL --source_value9
        ,   NULL --source_value10
        ,   x_target_value1,   x_target_value2,   x_target_value3,   x_target_value4,   x_target_value5,   x_target_value6,   x_target_value7,   x_target_value8,   x_target_value9,   x_target_value10,   x_target_value11,   x_target_value12,   x_target_value13,   x_target_value14,   x_target_value15,   x_target_value16,   x_target_value17,   x_target_value18,   x_target_value19,   x_target_value20,   x_error_message);
        v_new_store_terms := x_target_value1;
      END IF;
    EXCEPTION
    WHEN others THEN
      fnd_file.PUT_LINE(fnd_file.LOG,   'Error deriving the RMS Payment Terms for ' || v_new_store_terms || ' ' || x_error_message);
    END;
    /*                     fnd_file.put_line (fnd_file.LOG,
                            'Translation: ' || v_new_store_terms
                        );
*/
    BEGIN
      IF v_seasonal_terms IS NOT NULL THEN
        BEGIN
          v_terms_name := NULL;
          SELECT name
          INTO v_terms_name
          FROM ap_terms_tl
          WHERE term_id = v_seasonal_terms
           AND enabled_flag = 'Y'
           AND(start_date_active <= sysdate
           AND(end_date_active >= sysdate OR end_date_active IS NULL));
        EXCEPTION
        WHEN others THEN
          v_terms_name := NULL;
        END;
        /*                     fnd_file.put_line (fnd_file.LOG,
                            'Store Terms: ' || v_seasonal_terms || ' =' || v_terms_name
                        );
*/ xx_fin_translate_pkg.xx_fin_translatevalue_proc('AP_PAYMENT_TERMS_RMS' --translation_name
        ,   sysdate,   v_terms_name --source_value1
        ,   v_terms_date_basis --source_value2
        ,   NULL --source_value3
        ,   NULL --source_value4
        ,   NULL --source_value5
        ,   NULL --source_value6
        ,   NULL --source_value7
        ,   NULL --source_value8
        ,   NULL --source_value9
        ,   NULL --source_value10
        ,   x_target_value1,   x_target_value2,   x_target_value3,   x_target_value4,   x_target_value5,   x_target_value6,   x_target_value7,   x_target_value8,   x_target_value9,   x_target_value10,   x_target_value11,   x_target_value12,   x_target_value13,   x_target_value14,   x_target_value15,   x_target_value16,   x_target_value17,   x_target_value18,   x_target_value19,   x_target_value20,   x_error_message);
        v_seasonal_terms := x_target_value1;
      END IF;
    EXCEPTION
    WHEN others THEN
      fnd_file.PUT_LINE(fnd_file.LOG,   'Error deriving the RMS Payment Terms for (Seasonal Terms) ' || v_seasonal_terms || ' ' || x_error_message);
    END;
    IF(v_od_date_signed IS NOT NULL) THEN
      BEGIN
        v_od_date_signed := to_char(to_date(SUBSTR(v_od_date_signed,   1,   10),   'YYYY/MM/DD'),   'YYYY-MM-DD');
      EXCEPTION
      WHEN others THEN
        v_od_date_signed := to_char(to_date(TRUNC(sysdate),   'DD-MON-YY'),   'YYYY-MM-DD');
      END;
    END IF;
    IF(v_vendor_date_signed IS NOT NULL) THEN
      BEGIN
        v_vendor_date_signed := to_char(to_date(v_vendor_date_signed,   'YYYY/MM/DD HH24:MI:SS'),   'YYYY-MM-DD');
      EXCEPTION
      WHEN others THEN
        v_vendor_date_signed := to_char(to_date(TRUNC(sysdate),   'DD-MON-YY'),   'YYYY-MM-DD');
      END;
    END IF;
    IF(v_start_date IS NOT NULL) THEN
      BEGIN
        v_start_date := to_char(to_date(v_start_date,   'YYYY/MM/DD HH24:MI:SS'),   'YYYY-MM-DD');
      EXCEPTION
      WHEN others THEN
        v_start_date := to_char(to_date(TRUNC(sysdate),   'DD-MON-YY'),   'YYYY-MM-DD');
      END;
    END IF;
    IF(v_end_date IS NOT NULL) THEN
      BEGIN
        v_end_date := to_char(to_date(v_end_date,   'YYYY/MM/DD HH24:MI:SS'),   'YYYY-MM-DD');
      EXCEPTION
      WHEN others THEN
        v_end_date := to_char(to_date(TRUNC(sysdate),   'DD-MON-YY'),   'YYYY-MM-DD');
      END;
    END IF;
  END;
  IF v_supp_attribute7 = 'Y' THEN
    v_minority_class := 'MBE';
  END IF;
  IF v_supp_attribute8 = 'Y' THEN
    v_minority_class := 'WBE';
  END IF;
  IF v_supp_attribute9 = 'Y' THEN
    v_minority_class := 'DVB';
  END IF;
  IF v_supp_attribute10 = 'Y' THEN
    v_minority_class := 'SBC';
  END IF;
  IF v_supp_attribute11 = 'Y' -- defect 2192
  THEN
    v_minority_class := 'BSD';
  END IF;
END IF;
-- Get the Global Vendor Id;
v_globalvendor_id := xx_po_global_vendor_pkg.f_get_outbound(v_vendor_site_id);
/*IF LENGTH(v_globalvendor_id) < 10 THEN
  v_gssglobalvendor_id := lpad(v_globalvendor_id,   10,   '0');
ELSE
  v_gssglobalvendor_id := v_globalvendor_id;
END IF;*/
create_data_line;
/*IF(v_gss_flag = 'Y') THEN
  IF(v_opengssfile = 'N') THEN
    fnd_file.PUT_LINE(fnd_file.LOG,   'Opening the GSS output file......');
    v_gssfileid := utl_file.fopen(c_file_path,   v_gss_outfilename,   'W');
    v_opengssfile := 'Y';
  END IF;
  v_gss_count := v_gss_count + 1;
  v_system := 'GSS';
  -- GSS need 10 char global vendor id always
  v_file_data1 := v_gssglobalvendor_id || c_separator || v_name || c_separator || v_vendor_site_id || c_separator || v_vendor_site_code || c_separator || v_addr_flag || c_separator || v_inactive_date || c_separator || v_payment_currency_code --v_invc_curr
  || c_separator || v_site_lang || c_separator || v_pay_site_flag || c_separator || v_purchasing_site_flag || c_separator;
  utl_file.PUT_LINE(v_gssfileid,   v_system || c_separator || v_file_data1 || v_file_data2 || v_file_data3 || v_file_data4 || v_file_data5 || v_file_data6 || v_attribute10 || v_attribute11 || v_attribute12 || v_attribute13 || c_separator || v_attribute15 || c_separator || v_minority_class --   3.10
  || c_separator || v_minority_cd --   3.10
  );
  v_gss_flag := 'N';
END IF;*/--sunil
IF(v_rms_flag = 'Y') THEN
--  fnd_file.PUT_LINE(fnd_file.LOG,'RMS Flag :'||v_rms_flag);
--  fnd_file.PUT_LINE(fnd_file.LOG,'RMS Count :'||to_char(v_rms_count));
--  fnd_file.PUT_LINE(fnd_file.LOG,'RMS Flag :'||v_rms_flag);
  IF(v_openrmsfile = 'N') THEN
    fnd_file.PUT_LINE(fnd_file.LOG,   'Opening the RMS output file......');
    v_rmsfileid := utl_file.fopen(c_file_path,   v_rms_outfilename,   'W');
    v_openrmsfile := 'Y';
  END IF;
--  DBMS_OUTPUT.PUT_LINE('LINE 1464'||v_rms_count||v_vendor_site_id);
  v_rms_count := v_rms_count + 1;
--  fnd_file.PUT_LINE(fnd_file.LOG,'RMS Count :'||to_char(v_rms_count));
  v_system := 'RMS';
  utl_file.PUT_LINE(v_rmsfileid,   v_system || c_separator || v_file_data1 || v_file_data2 || v_file_data3 || v_file_data4 || v_file_data5 || v_file_data6 || v_attribute10 || v_attribute11 || v_attribute12 || v_attribute13 || c_separator || v_attribute15 || c_separator || v_minority_class --   3.10
  || c_separator || v_minority_cd || v_attribute16  -- 5.0
  );
  DBMS_OUTPUT.PUT_LINE('RMS count '||v_rms_count);
  DBMS_OUTPUT.PUT_LINE(' RMS Data '||v_file_data1 || v_file_data2|| v_file_data3 || v_file_data4 || v_file_data5 
  || v_file_data6 || v_attribute10 || v_attribute11 || v_attribute12 || v_attribute13 || c_separator || v_attribute15 || c_separator || v_minority_class --   3.10
 || c_separator || v_minority_cd || v_attribute16); 
 -- DBMS_OUTPUT.PUT_LINE('v_attribute16' ||v_attribute16);
--    DBMS_OUTPUT.PUT_LINE('RMS Data' || '' || v_rmsfileid);-- ||   v_system || c_separator || v_file_data1 || v_file_data2 );
--    || v_file_data3 || v_file_data4 || v_file_data5 || v_file_data6 || v_attribute10 || v_attribute11 || v_attribute12 || v_attribute13 || c_separator || v_attribute15 || c_separator || v_minority_class --   3.10
 -- || c_separator || v_minority_cd || v_attribute16);
  -- fnd_file.put_line (fnd_file.LOG, 'Checking RTV Site for: '||v_vendor_site_id);
  IF((v_rtv_related_siteid IS NOT NULL)
   AND(v_pay_site_flag = 'Y')) THEN
    -- fnd_file.put_line (fnd_file.LOG, 'RTV Site address data for: '||to_number(v_rtv_related_siteid));
    BEGIN
      SELECT a.vendor_site_code,
        a.address_line1,
        a.address_line2,
        a.address_line3,
        a.city,
        UPPER(a.state),
        a.zip,
        nvl(a.country,   'US'),
        b.first_name,
        b.last_name,
        b.area_code,
        b.phone,
        b.email_address,
        b.fax_area_code,
        b.fax,
        a.province
      INTO v_vendor_site_code,
        v_address_line1,
        v_address_line2,
        v_address_line3,
        v_city,
        v_state,
        v_zip,
        v_country,
        v_site_contact_fname,
        v_site_contact_lname,
        v_site_contact_areacode,
        v_site_contact_phone,
        v_site_contact_email,
        v_site_contact_fareacode,
        v_site_contact_fphone,
        v_province
      FROM AP_SUPPLIER_SITES_ALL a, -- V4.0 po_vendor_sites_all a,
        po_vendor_contacts b
      WHERE a.vendor_site_id = to_number(v_rtv_related_siteid)
       AND a.vendor_site_id = b.vendor_site_id(+)
       AND a.org_id IN(xx_fin_country_defaults_pkg.f_org_id('CA'),   xx_fin_country_defaults_pkg.f_org_id('US')) --= ou.organization_id
      ORDER BY a.vendor_site_id;
    EXCEPTION
    WHEN others THEN
      fnd_file.PUT_LINE(fnd_file.LOG,   'Error retreiving RTV Site address data: for ' || to_number(v_rtv_related_siteid));
    END;
    v_site_contact_name := NULL;
    v_site_contact_payphone := NULL;
    v_site_contact_purchphone := NULL;
    v_site_contact_ppphone := NULL;
    v_site_contact_rtvphone := NULL;
    v_site_contact_payfax := NULL;
    v_site_contact_purchfax := NULL;
    v_site_contact_ppfax := NULL;
    v_site_contact_rtvfax := NULL;
    v_site_phone := NULL;
    v_site_fax := NULL;
    v_site_contact_payemail := NULL;
    v_site_contact_purchemail := NULL;
    v_site_contact_ppemail := NULL;
    v_site_contact_rtvemail := NULL;
    v_site_contact_payname := NULL;
    v_site_payaddr1 := NULL;
    v_site_payaddr2 := NULL;
    v_site_payaddr3 := NULL;
    v_site_paycity := NULL;
    v_site_paystate := NULL;
    v_site_payzip := NULL;
    v_site_paycountry := NULL;
    v_site_contact_rtvname := NULL;
    v_site_rtvaddr1 := NULL;
    v_site_rtvaddr2 := NULL;
    v_site_rtvaddr3 := NULL;
    v_site_rtvcity := NULL;
    v_site_rtvstate := NULL;
    v_site_rtvzip := NULL;
    v_site_rtvcountry := NULL;
    v_site_contact_purchname := NULL;
    v_site_purchaddr1 := NULL;
    v_site_purchaddr2 := NULL;
    v_site_purchaddr3 := NULL;
    v_site_purchcity := NULL;
    v_site_purchstate := NULL;
    v_site_purchzip := NULL;
    v_site_purchcountry := NULL;
    v_site_contact_ppname := NULL;
    v_site_ppaddr1 := NULL;
    v_site_ppaddr2 := NULL;
    v_site_ppaddr3 := NULL;
    v_site_ppcity := NULL;
    v_site_ppstate := NULL;
    v_site_ppzip := NULL;
    v_site_ppcountry := NULL;
    v_site_phone := v_site_contact_areacode || v_site_contact_phone;
    v_site_phone := SUBSTR(REPLACE(v_site_phone,   '-',   ''),   1,   11);
    v_site_fax := v_site_contact_fareacode || v_site_contact_fphone;
    v_site_fax := SUBSTR(REPLACE(v_site_fax,   '-',   ''),   1,   11);
    v_site_contact_name := v_site_contact_fname || ' ' || v_site_contact_lname;
    IF v_site_contact_name = ' ' THEN
      v_site_contact_name := NULL;
    END IF;
    IF((v_country <> 'US')
     AND v_state IS NULL) THEN
      v_state := v_province;
    END IF;
    v_addr_flag := 0;
    v_site_rtvaddr1 := v_address_line1;
    v_site_rtvaddr2 := v_address_line2;
    v_site_rtvaddr3 := v_address_line3;
    v_site_rtvcity := v_city;
    v_site_rtvstate := v_state;
    v_site_rtvzip := v_zip;
    v_site_rtvcountry := v_country;
    v_site_contact_rtvphone := v_site_phone;
    v_site_contact_rtvfax := v_site_fax;
    v_site_contact_rtvemail := v_site_contact_email;
    v_site_contact_rtvname := v_site_contact_name;
    create_data_line;
    v_rms_count := v_rms_count + 1;
   -- DBMS_OUTPUT.PUT_LINE('line 1591 vndor site id 1' ||v_vendor_site_id);
    utl_file.PUT_LINE(v_rmsfileid,   v_system || c_separator || v_file_data1 || v_file_data2 || v_file_data3 || v_file_data4 || v_file_data5 || v_file_data6 || v_attribute10 || v_attribute11 || v_attribute12 || v_attribute13 || c_separator || v_attribute15 || c_separator || v_minority_class --   3.10
    || c_separator || v_minority_cd || v_attribute16  -- 5.0
    );
      DBMS_OUTPUT.PUT_LINE('RMS Count ' ||v_rms_count);
 DBMS_OUTPUT.PUT_LINE('RMS Data '||v_file_data1 || v_file_data2|| v_file_data3 || v_file_data4 || v_file_data5 
  || v_file_data6 || v_attribute10 || v_attribute11 || v_attribute12 || v_attribute13 || c_separator || v_attribute15 || c_separator || v_minority_class --   3.10
 || c_separator || v_minority_cd || v_attribute16); 
  --  DBMS_OUTPUT.PUT_LINE('v_attribute16' ||v_attribute16);

  END IF;
  v_rms_flag := 'N';
END IF;
/*IF(v_psft_flag = 'Y') THEN
  IF(v_openpsftfile = 'N') THEN
    fnd_file.PUT_LINE(fnd_file.LOG,   'Opening the PSFT output file ......');
    v_psftfileid := utl_file.fopen(c_file_path,   v_psft_outfilename,   'W');
    v_openpsftfile := 'Y';
  END IF;
--  fnd_file.PUT_LINE(fnd_file.LOG,   'Peoplesoft Supplier selected.');
  v_psft_count := v_psft_count + 1;
  v_system := 'PSFT';
-- Defect 10345 Update Address information
  IF (v_pay_site_flag = 'Y') THEN
    v_addr_flag := 3;
    v_site_payaddr1 := v_address_line1;
    v_site_payaddr2 := v_address_line2;
    v_site_payaddr3 := v_address_line3;
    v_site_paycity := v_city;
    v_site_paystate := v_state;
    v_site_payzip := v_zip;
    v_site_paycountry := v_country;
    v_site_contact_payphone := v_site_phone;
    v_site_contact_payfax := v_site_fax;
    v_site_contact_payemail := v_site_contact_email;
    v_site_contact_payname := v_site_contact_name;
    v_globalvendor_id := lpad(v_globalvendor_id,   9,   '0');
  END IF;
  create_data_line;
--
  utl_file.PUT_LINE(v_psftfileid,   v_system || c_separator || v_file_data1 || v_file_data2 || v_file_data3 || v_file_data4 || v_file_data5 || v_file_data6 || v_attribute10 || v_attribute11 || v_attribute12 || v_attribute13 || c_separator || v_attribute15 || c_separator || v_minority_class --   3.10
  || c_separator || v_minority_cd --   3.10
  );
  fnd_file.PUT_LINE(fnd_file.LOG,   'PSFT Supplier selected:' || v_vendor_site_id || ' ' || v_vendor_site_code || ' ' || v_name);
  v_psft_flag := 'N';
END IF;*/--Sunil
--     dbms_output.put_line( v_file_data1 || v_file_data2 || v_file_data3 || v_file_data4 || v_file_data5 || v_file_data6);
-- V4.0, Added below update for interfaced supplier site
BEGIN

--  fnd_file.PUT_LINE(fnd_file.LOG,'RMS Count :'||to_char(v_rms_count));
--  fnd_file.PUT_LINE(fnd_file.LOG,'GSS Count :'||to_char(v_gss_count));
--  fnd_file.PUT_LINE(fnd_file.LOG,'PSFT Count :'||to_char(v_psft_count));
--  fnd_file.PUT_LINE(fnd_file.LOG,'Vendor site id :'||to_char(v_vendor_site_id));
--  fnd_file.PUT_LINE(fnd_file.LOG,'Vendor site id :'||to_char(g_vendor_site_id));
--DBMS_OUTPUT.PUT_LINE('line 1639   rms count' ||v_rms_count);
  IF  v_rms_count>0 or v_gss_count>0 or v_psft_count>0 THEN
   UPDATE ap_supplier_sites_all -- V4.01, added _all table
      SET telex = v_telex ||' '|| 'INTFCD'

    WHERE vendor_site_id = g_vendor_site_id ;
        commit;
  END IF;
EXCEPTION
   WHEN others THEN
     fnd_file.PUT_LINE(fnd_file.LOG,   'Error while updating Telex as INTFD for vendor_site_id = ' || v_vendor_site_id );
END;
-- V4.0, Ended
END LOOP;
CLOSE mainsupplupdate_cur;
-- Transfer the File to FTP directory
ELSE
DBMS_OUTPUT.PUT_LINE('Exit the Program, BPEL process is still running.');
fnd_file.PUT_LINE(fnd_file.LOG,   'Exit the Program, BPEL process is still running.');
END IF;
---+============================================================================================================
---|  Submit the Request to copy the TDM file from XXFIN_OUTBOUND directory to XXFIN_DATA/ftp/out
---+============================================================================================================
-- Copy GSS File
/*IF(v_opengssfile = 'Y') THEN
utl_file.fclose(v_gssfileid);
ln_req_id := fnd_request.submit_request('XXFIN',   'XXCOMFILCOPY',   '',   '01-OCT-04 00:00:00',   FALSE,   lc_sourcepath || '/' || v_gss_outfilename,   '$XXFIN_DATA/ftp/out/supplier/' || v_gss_outfilename,   '',   '');
COMMIT;
IF ln_req_id > 0 THEN
lb_result := fnd_concurrent.wait_for_request(ln_req_id,   10,   0,   lc_phase,   lc_status,   lc_dev_phase,   lc_dev_status,   lc_message);
END IF;
IF TRIM(lc_status) = 'Error' THEN
lc_err_status := 'Y';
lc_err_mesg := 'File Copy of the GSS Supplier File Failed : ' || v_gss_outfilename || ': Please check the Log file for Request ID : ' || ln_req_id;
fnd_file.PUT_LINE(fnd_file.LOG,   'Error : ' || lc_err_mesg || ' : ' || SQLCODE || ' : ' || sqlerrm);
END IF;
END IF;*/--sunil
/*IF(v_openpsftfile = 'Y') THEN
utl_file.fclose(v_psftfileid);
ln_req_id := fnd_request.submit_request('XXFIN',   'XXCOMFILCOPY',   '',   '01-OCT-04 00:00:00',   FALSE,   lc_sourcepath || '/' || v_psft_outfilename,   '$XXFIN_DATA/ftp/out/supplier/' || v_psft_outfilename,   '',   '');
COMMIT;
IF ln_req_id > 0 THEN
lb_result := fnd_concurrent.wait_for_request(ln_req_id,   10,   0,   lc_phase,   lc_status,   lc_dev_phase,   lc_dev_status,   lc_message);
END IF;
IF TRIM(lc_status) = 'Error' THEN
lc_err_status := 'Y';
lc_err_mesg := 'File Copy of the PSFT Supplier File Failed : ' || v_psft_outfilename || ': Please check the Log file for Request ID : ' || ln_req_id;
fnd_file.PUT_LINE(fnd_file.LOG,   'Error : ' || lc_err_mesg || ' : ' || SQLCODE || ' : ' || sqlerrm);
END IF;
END IF;*/--sunil
-- Copy RMS File
IF(v_openrmsfile = 'Y') THEN
utl_file.fclose(v_rmsfileid);
ln_req_id := fnd_request.submit_request('XXFIN',   'XXCOMFILCOPY',   '',   '01-OCT-04 00:00:00',   FALSE,   lc_sourcepath || '/' || v_rms_outfilename,   '$XXFIN_DATA/ftp/out/supplier/' || v_rms_outfilename,   '',   '');
COMMIT;
--DBMS_OUTPUT.PUT_LINE('req id '||ln_req_id);
--DBMS_OUTPUT.PUT_LINE('sourcepath '||lc_sourcepath);
IF ln_req_id > 0 THEN
lb_result := fnd_concurrent.wait_for_request(ln_req_id,   10,   0,   lc_phase,   lc_status,   lc_dev_phase,   lc_dev_status,   lc_message);
END IF;
IF TRIM(lc_status) = 'Error' THEN
lc_err_status := 'Y';
lc_err_mesg := 'File Copy of the RMS Supplier File Failed : ' || v_rms_outfilename || ': Please check the Log file for Request ID : ' || ln_req_id;
fnd_file.PUT_LINE(fnd_file.LOG,   'Error : ' || lc_err_mesg || ' : ' || SQLCODE || ' : ' || sqlerrm);
END IF;
END IF;
fnd_file.PUT_LINE(fnd_file.LOG,   '          ');
fnd_file.PUT_LINE(fnd_file.LOG,   '****************************************************************************');
fnd_file.PUT_LINE(fnd_file.LOG,   'Number of Records: RMS=' || v_rms_count || ' GSS=' || v_gss_count || ' PSFT=' || v_psft_count);
fnd_file.PUT_LINE(fnd_file.LOG,   '****************************************************************************');
DBMS_OUTPUT.PUT_LINE('End of Program');
END;