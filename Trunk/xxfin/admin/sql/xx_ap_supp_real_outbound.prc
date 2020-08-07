SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

create or replace 
PROCEDURE xx_ap_supp_real_outbound(errbuf OUT VARCHAR2,   retcode OUT VARCHAR2) AS
/*********************************************************************************************************
   NAME:       XX_AP_SUPP_REAL_OUTBOUND
   PURPOSE:    This procedure will read the Supplier base tables for any changes and write
               it to outputfile for GSS/PSFT.
   RICE ID :   I0380
   REVISIONS:
   Ver        Date        Author                Description
   ---------  ----------  ---------------       ------------------------------------
   1.0        5/30/2007   Sandeep Pandhare      Created this procedure.
   2.0        9/11/2007   Sandeep Pandhare      Add GSS changes: 10 digit Vendor Id,
                                                Vendor Site ID, PPD for Bank Account Num.
                                                Remove Site Code starting with "EX" so all
                                                Sites with site Category of 'EX-IMP' will be selected.
   3.0        10/09/2007  Sandeep Pandhare      Defect 2192 Translate Values for RMS.
   3.1        10/24/2007  Sandeep Pandhare      Change Date format for KFF fields.
   3.2        11/07/2007  Sandeep Pandhare      Phone#=11chars, some not null KFF values.
   3.3        12/26/2007  Sandeep Pandhare      Add the RMS terms translation for NEW_STORE_TERMS
   3.4        01/02/2008  Sandeep Pandhare      Modify the Language to "1" for RMS.
   3.5        01/07/2008  Sandeep Pandhare      Add the RMS terms translation for SEASONAL_TERM
   3.6        01/09/2008  Sandeep Pandhare      Do not create zero byte file.
   3.7        01/15/2008  Sandeep Pandhare      Default for DEBIT_MEMO (ret_allow_ind) and delivery_policy.
   3.8        01/21/2008  Sandeep Pandhare      Change the field for TAX ID to NUM_1099 and Payment terms.
   3.9        01/24/2008  Sandeep Pandhare      Payment Currency Code.
                                                Change New Store Terms and Seasonal Terms to use Terms Date Basis.
   3.10        01/24/2008  Sandeep Pandhare      Reverse the positions of Minority Class and Minority Category.
   3.11        02/05/2008  Sandeep Pandhare      CR# 328, defect 4179
   3.12        02/05/2008  Sandeep Pandhare      Defect 4514
   3.13        05/01/2008  Sandeep Pandhare      Defect 6547
   3.14        05/15/2008  Sandeep Pandhare      Defect 7007  CR395
   3.15        06/25/2008  Sandeep Pandhare      Defect 8507  - Add Org_id to Country code
   3.15        07/15/2008  Sandeep Pandhare      Defect 6517  - Remove default
   3.16        08/11/2008  Sandeep Pandhare      Defect 8507  - Fix GSS Country Code
   3.17        08/28/2008  Sandeep Pandhare      Defect 10345 - Update Address fields for Peoplesoft
   3.18        04/23/2009  Peter Marco           Defect 14433 - Modified code to use ORG_ID as source to
                                                                translation table lookup
   3.19        01/09/2010  Jude Felix Antony.A   Defect 7600 -  Added Commit in the Code to release the
                                                                lock on xx_ap_supp_extract table
   3.20        02/07/2011  Sachin R Patil        Defect 13002 - Increased the interval Day precision from 3 to 4
   4.00        27/12/2013  Jay Gupta             Defect#27165 - R12 Retrofit and Telex Changes
   4.01        11-Feb-14   Santosh Gopal         Defect 28126
   4.02        18-Feb-2014 Jay Gupta             Defect# 28331 - Resending for Canada
   5.0         26-Dec-2014 Amodium               Defect# 29479 - Adding additional attributes to RMS file type
   5.1         26-Jan-2015 Paddy Sanjeevi	      Defect 29479  - Removed the fnd_file call in the function buss_class_attr_func
   6.0         27-Jan-2015 Dhanishya Raman		 Defect#33188 --Default payment method 'CHECK' to be interfaced to RMS
   6.1         04-Nov-2015 Harvinder Rakhra      Retroffit R12.2
   6.2         05-Mar-2018 Sunil Kalal          Removing RMS related code as new integration is developed with XML output for RMS.
*******************************************************************************************************************/
 /* Define constants */ c_file_path constant VARCHAR2(15) := 'XXFIN_OUTBOUND';
c_blank constant VARCHAR2(1) := ' ';
c_when constant DATE := sysdate;
c_separator constant VARCHAR2(1) := ';';
c_fileext constant VARCHAR2(10) := '.txt';
c_who constant fnd_user.user_id%TYPE := fnd_load_util.owner_id('INTERFACE');
/* Define variables */ v_system VARCHAR2(32);
v_last_update_date DATE;
v_gss_last_update date;
--v_rms_last_update DATE;
v_psft_last_update DATE;
v_extract_time DATE;
v_date_diff INTERVAL DAY(4) TO SECOND(0); --Defect #13002
v_vendor_last_update po_vendor_sites_all.last_update_date%TYPE;
v_site_last_update po_vendor_sites_all.last_update_date%TYPE;
v_site_contact_last_update po_vendor_contacts.last_update_date%TYPE;
v_bpel_run_flag VARCHAR2(1) := 'N';
v_exit_flag varchar2(1) := 'N';
v_gss_flag varchar2(1) := 'N';
--v_rms_flag VARCHAR2(1) := 'N';
v_psft_flag VARCHAR2(1) := 'N';
v_timestamp VARCHAR2(30) := to_char(c_when,   'DDMONYY_HHMISS');
v_gssfileid utl_file.file_type;
--v_rmsfileid utl_file.file_type;
v_psftfileid utl_file.file_type;
v_opengssfile varchar2(1) := 'N';
--v_openrmsfile VARCHAR2(1) := 'N';
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
v_rtv_related_siteid xx_po_vendor_sites_kff_v.blank99%type;
--v_rms_count NUMBER := 0;
v_gss_count NUMBER := 0;
v_psft_count number := 0;
/*x_target_value1 VARCHAR2(200);--Commented by Sunil Line No.275 to 295
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
x_target_value20 VARCHAR2(200);*/
v_gss_outfilename varchar2(60) := 'SyncSupplierGSS_' || v_timestamp || c_fileext;
v_psft_outfilename varchar2(60) := 'SyncSupplierPSFT_' || v_timestamp || c_fileext;--
--v_rms_outfilename VARCHAR2(60) := 'SyncSupplierRMS_' || v_timestamp || c_fileext;
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
v_site_exists_flag VARCHAR2(1) := 'Y';
v_telex ap_supplier_sites_all.telex%TYPE; --V4.0
-- Cursor to read the custom table
CURSOR extsupplupdate_cur IS
SELECT v.ext_system,
  v.last_update_date,
  v.extract_time,
  v.bpel_running_flag
from xx_ap_supp_extract v
where ext_system <> 'RMS';
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
END init_kffvariables;
PROCEDURE create_data_line IS
BEGIN
  if v_site_orgid = 403 then
     v_orgcountry := 'CA';
  end if;
  if v_site_orgid = 404 then
     v_orgcountry := 'US';
  end if;
  --fnd_file.put_line (fnd_file.LOG, 'Start of create_data_line' );
  v_file_data1 := v_globalvendor_id || c_separator || v_name || c_separator || v_vendor_site_id || c_separator || v_vendor_site_code || c_separator || v_addr_flag || c_separator || v_inactive_date || c_separator || v_payment_currency_code || c_separator || v_site_lang || c_separator || v_pay_site_flag || c_separator || v_purchasing_site_flag || c_separator;
  --          fnd_file.put_line (fnd_file.LOG, 'Data1:' || v_file_data1 );
  v_file_data2 := v_site_terms_name -- Translation of v_site_terms
  || c_separator || v_site_freightterms || c_separator || v_debit_memo_flag || c_separator || v_duns_num || c_separator || v_parent_name || c_separator || v_parent_id || c_separator || v_tax_reg_num || c_separator;
  --         fnd_file.put_line (fnd_file.LOG, 'Data2:' || v_file_data2 );
  v_file_data3 := v_site_contact_payname || c_separator || v_site_contact_purchname || c_separator || v_site_contact_ppname || c_separator || v_site_contact_rtvname || c_separator || v_site_contact_payphone || c_separator || v_site_contact_purchphone || c_separator || v_site_contact_ppphone || c_separator || v_site_contact_rtvphone || c_separator || v_site_contact_payfax || c_separator || v_site_contact_purchfax || c_separator || v_site_contact_ppfax || c_separator || v_site_contact_rtvfax || c_separator;
  --         fnd_file.put_line (fnd_file.LOG, 'Data3:' || v_file_data3 );
/*IF (v_rms_flag = 'Y') THEN  -- defect 8507--Commented by Sunil
  v_file_data4 := v_site_contact_payemail || c_separator || v_site_contact_purchemail || c_separator || v_site_contact_ppemail || c_separator || v_site_contact_rtvemail || c_separator || v_site_payaddr1 || c_separator || v_site_payaddr2 || c_separator || v_site_payaddr3 || c_separator || v_site_paycity || c_separator || v_site_paystate || c_separator || v_site_payzip || c_separator || v_site_paycountry || '?' || v_orgcountry || c_separator; -- defect 8507
  --                   fnd_file.put_line (fnd_file.LOG, 'Data4:' || v_file_data4 );
  v_file_data5 := v_site_purchaddr1 || c_separator || v_site_purchaddr2 || c_separator || v_site_purchaddr3 || c_separator || v_site_purchcity || c_separator || v_site_purchstate || c_separator || v_site_purchzip || c_separator || v_site_purchcountry || '?' || v_orgcountry || c_separator || v_site_ppaddr1 || c_separator || v_site_ppaddr2 || c_separator || v_site_ppaddr3 || c_separator || v_site_ppcity || c_separator || v_site_ppstate || c_separator || v_site_ppzip || c_separator || v_site_ppcountry || '?' || v_orgcountry || c_separator || v_site_rtvaddr1 || c_separator || v_site_rtvaddr2 || c_separator || v_site_rtvaddr3 || c_separator || v_site_rtvcity || c_separator || v_site_rtvstate || c_separator || v_site_rtvzip || c_separator || v_site_rtvcountry || '?' || v_orgcountry || c_separator;  -- defect 8507
  --                   fnd_file.put_line (fnd_file.LOG, 'Data5:' || v_file_data5 );
*/
--else
  v_file_data4 := v_site_contact_payemail || c_separator || v_site_contact_purchemail || c_separator || v_site_contact_ppemail || c_separator || v_site_contact_rtvemail || c_separator || v_site_payaddr1 || c_separator || v_site_payaddr2 || c_separator || v_site_payaddr3 || c_separator || v_site_paycity || c_separator || v_site_paystate || c_separator || v_site_payzip || c_separator || v_site_paycountry || c_separator; -- defect 8507
  v_file_data5 := v_site_purchaddr1 || c_separator || v_site_purchaddr2 || c_separator || v_site_purchaddr3 || c_separator || v_site_purchcity || c_separator || v_site_purchstate || c_separator || v_site_purchzip || c_separator || v_site_purchcountry ||  c_separator || v_site_ppaddr1 || c_separator || v_site_ppaddr2 || c_separator || v_site_ppaddr3 || c_separator || v_site_ppcity || c_separator || v_site_ppstate || c_separator || v_site_ppzip || c_separator || v_site_ppcountry ||  c_separator || v_site_rtvaddr1 || c_separator || v_site_rtvaddr2 || c_separator || v_site_rtvaddr3 || c_separator || v_site_rtvcity || c_separator || v_site_rtvstate || c_separator || v_site_rtvzip || c_separator || v_site_rtvcountry ||  c_separator;  -- defect 8507
--end if;
  v_file_data6 := v_primary_paysite_flag || c_separator || v_attribute8 || c_separator || v_bank_account_name || c_separator || v_bank_account_num || c_separator;
  --                   fnd_file.put_line (fnd_file.LOG, 'Data6:' || v_file_data6 );
  -- Concatenate all the fields to create the value of Attribute fields
  v_attribute10 := v_lead_time || c_separator || v_back_order_flag || c_separator || v_delivery_policy || c_separator || v_min_prepaid_code || c_separator || v_vendor_min_amount || c_separator || v_supplier_ship_to || c_separator || v_inventory_type_code || c_separator || v_vertical_market_indicator || c_separator || v_allow_auto_receipt || c_separator || v_handling || c_separator || v_eft_settle_days || c_separator || v_split_file_flag || c_separator || v_master_vendor_id || c_separator || v_pi_pack_year || c_separator || v_od_date_signed || c_separator || v_vendor_date_signed || c_separator || v_deduct_from_invoice_flag || c_separator;
  --                   fnd_file.put_line (fnd_file.LOG, 'Attr10:' || v_attribute10 );
  v_attribute11 := v_new_store_flag || c_separator || v_new_store_terms || c_separator || v_seasonal_flag || c_separator || v_start_date || c_separator || v_end_date || c_separator || v_seasonal_terms || c_separator || v_late_ship_flag || c_separator || v_edi_distribution_code || c_separator || v_850_po || c_separator || v_860_po_change || c_separator || v_855_confirm_po || c_separator || v_856_asn || c_separator || v_846_availability || c_separator || v_810_invoice || c_separator || v_832_price_sales_cat || c_separator || v_820_eft || c_separator || v_861_damage_shortage || c_separator || v_852_sales || c_separator;
  --                  fnd_file.put_line (fnd_file.LOG, 'Attr11:' || v_attribute11 );
  v_attribute12 := v_rtv_option || c_separator || v_rtv_freight_payment_method || c_separator || v_permanent_rga || c_separator || v_destroy_allow_amount || c_separator || v_payment_frequency || c_separator || v_min_return_qty || c_separator || v_min_return_amount || c_separator || v_damage_destroy_limit || c_separator || v_rtv_instructions || c_separator || v_addl_rtv_instructions || c_separator || v_rga_marked_flag || c_separator || v_remove_price_sticker_flag || c_separator || v_contact_supplier_rga_flag || c_separator || v_destroy_flag || c_separator || v_serial_num_required_flag || c_separator || v_obsolete_item || c_separator || v_obsolete_allowance_pct || c_separator || v_obsolete_allowance_days || c_separator;
  --                            fnd_file.put_line (fnd_file.LOG, 'Attr12:' || v_attribute12 );
  -- Concatenate all the fields to create the value of Attribute15 field
  v_attribute15 := v_gss_mfg_id || c_separator || v_gss_buying_agent_id || c_separator || v_gss_freight_id || c_separator || v_gss_ship_id;
  --         fnd_file.put_line (fnd_file.LOG, 'Attr15:' || v_attribute15 );
  -- fnd_file.put_line (fnd_file.LOG, 'end of create_data_line' );
END create_data_line;
/*Defect# 29479 Added for BUSS_CLASS_ATTR_FUNC for RMS type*/
--Function Commented by Sunil Line No 605 to 659
/*FUNCTION buss_class_attr_func(p_vendor_site_id IN NUMBER)
RETURN VARCHAR2
IS
lv_attribute16 varchar2(4000);
lv_vend_id number;
lv_attr   varchar2(10);
lv_ext_attr_1 varchar2(10);
lv_separator varchar2(10) := ';';

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
          FROM pos_bus_class_attr
         WHERE vendor_id = lv_vend_id
           AND lookup_code= r_buss_attr.lookup_code
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
          --fnd_file.PUT_LINE(fnd_file.LOG,'IN EXCEPTION 1:'||SQLERRM);
        END;
END LOOP;
return lv_attribute16;
EXCEPTION
WHEN OTHERS THEN
 fnd_file.put_line(fnd_file.log,'MAIN EXCEPTION :'||sqlerrm);
END buss_class_attr_func;*/

BEGIN
  v_extract_time := sysdate;
  --cast(systimestamp as timestamp); --to_char(c_when, 'DD-MON-YY HH:Mi:SS');
  --    v_extract_time := to_char(sysdate, 'DD-MON-YY HH24:Mi:SS');
  -- Add code for File open
  DBMS_OUTPUT.PUT_LINE('Current Extract Time:' || to_char(v_extract_time,   'DD-MON-YY HH24:Mi:SS'));
  ---+===============================================================================================
  ---|  Select the directory path for XXFIN_OUTBOUND directory
  ---+===============================================================================================
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
  -- Update Extract time
  UPDATE xx_ap_supp_extract
  SET extract_time = v_extract_time;
  -- Fetch the rows for the 3 external systems ;
  OPEN extsupplupdate_cur;
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
/*WHEN 'RMS' THEN--Commented by Sunil
  --v_rms_last_update := v_last_update_date;*/
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
END LOOP;
fnd_file.PUT_LINE(fnd_file.LOG,   '****************************************************************************');
fnd_file.PUT_LINE(fnd_file.LOG,   '          ');
-- Get Minimum Extract time
SELECT MIN(last_update_date)
INTO v_last_update_date
FROM xx_ap_supp_extract;
fnd_file.PUT_LINE(fnd_file.LOG,   'Minimum Last Update Time:' || to_char(v_last_update_date,   'DD-MON-YY HH24:Mi:SS'));
IF v_exit_flag = 'N' THEN
--+************************************************************************************+
--+ Added commit for the Defect 7600 to Release lock on table xx_ap_supp_extract +
 --+************************************************************************************+
commit;
OPEN mainsupplupdate_cur;
--      DBMS_OUTPUT.put_line ('Open Cursor for Main Supplier');
fnd_file.PUT_LINE(fnd_file.LOG,   ' Supplier Data Read from ' || to_char(v_last_update_date,   'DD-MON-YY HH24:Mi:SS') || ' to ' || to_char(v_extract_time,   'DD-MON-YY HH24:Mi:SS'));
fnd_file.PUT_LINE(fnd_file.LOG,   'Supplier Site ID ' || '*' || 'Site Code ' || '*' || 'Name ');
-- Main Cursor to read all the data ;
LOOP
  v_gss_flag := 'N';
--  v_rms_flag := 'N';--Commented by Sunil
  v_psft_flag := 'N';
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
  EXIT
WHEN NOT mainsupplupdate_cur % FOUND;
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

  g_vendor_site_id:=NULL;
  /*Defect# 29479 calling BUSS_CLASS_ATTR_FUNC for RMS type*/
--  v_attribute16 := buss_class_attr_func(v_vendor_site_id);--Commented by Sunil

 v_site_phone := v_site_contact_areacode || v_site_contact_phone;
v_site_phone := SUBSTR(REPLACE(v_site_phone,   '-',   ''),   1,   11);
v_site_fax := v_site_contact_fareacode || v_site_contact_fphone;
v_site_fax := SUBSTR(REPLACE(v_site_fax,   '-',   ''),   1,   11);
IF((v_country <> 'US')
 AND v_state IS NULL) THEN
  v_state := v_province;
END IF;
IF(((v_vendor_type_lookup_code = 'GARNISHMENT') OR(v_vendor_type_lookup_code = 'CONTINGENT WORKER'))
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
END IF;
-- All Expense vendors with Site Category of EX-IMP will be sent.
IF((SUBSTR(v_attribute8,   1,   6) = 'EX-IMP')
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
end if;
--Commneted by Sunil Line No.872 to Line No 895
/*IF((SUBSTR(v_attribute8,   1,   2) = 'TR')) -- Defect 6547             OR (SUBSTR (v_attribute8, 1, 6) = 'EX-IMP'))
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
END IF;*/
IF v_gss_flag = 'Y' THEN
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
end if;
--COmmneted by SUnil Line No.936 to Line No.1438
/*IF v_rms_flag = 'Y' THEN
  fnd_file.PUT_LINE(fnd_file.LOG,   'RMS Supplier selected:' || v_vendor_site_id || ' ' || v_vendor_site_code || ' ' || v_name);
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
  /*       EXCEPTION
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
        SELECT name
        INTO v_site_terms_name
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
        k.rtv_related_site
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
        v_rtv_related_siteid
      FROM xx_po_vendor_sites_kff_v k
      WHERE k.vendor_site_id = v_vendor_site_id;
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
/*         xx_fin_translate_pkg.xx_fin_translatevalue_proc('AP_PAYMENT_TERMS_RMS' --translation_name
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
  /*  BEGIN
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
*/ /*xx_fin_translate_pkg.xx_fin_translatevalue_proc('AP_PAYMENT_TERMS_RMS' --translation_name
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
  end if;
END IF;*/--Commneted by Sunil Line No.937 to Line No.1438
-- Get the Global Vendor Id;
v_globalvendor_id := xx_po_global_vendor_pkg.f_get_outbound(v_vendor_site_id);
IF LENGTH(v_globalvendor_id) < 10 THEN
  v_gssglobalvendor_id := lpad(v_globalvendor_id,   10,   '0');
ELSE
  v_gssglobalvendor_id := v_globalvendor_id;
END IF;
create_data_line;
IF(v_gss_flag = 'Y') THEN
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
end if;
--Commneted by Sunil  Line No. 1463 to Line No. 1604
/*IF(v_rms_flag = 'Y') THEN
--  fnd_file.PUT_LINE(fnd_file.LOG,'RMS Flag :'||v_rms_flag);
--  fnd_file.PUT_LINE(fnd_file.LOG,'RMS Count :'||to_char(v_rms_count));
--  fnd_file.PUT_LINE(fnd_file.LOG,'RMS Flag :'||v_rms_flag);
  IF(v_openrmsfile = 'N') THEN
    fnd_file.PUT_LINE(fnd_file.LOG,   'Opening the RMS output file......');
    v_rmsfileid := utl_file.fopen(c_file_path,   v_rms_outfilename,   'W');
    v_openrmsfile := 'Y';
  END IF;
  v_rms_count := v_rms_count + 1;
--  fnd_file.PUT_LINE(fnd_file.LOG,'RMS Count :'||to_char(v_rms_count));
  v_system := 'RMS';
  utl_file.PUT_LINE(v_rmsfileid,   v_system || c_separator || v_file_data1 || v_file_data2 || v_file_data3 || v_file_data4 || v_file_data5 || v_file_data6 || v_attribute10 || v_attribute11 || v_attribute12 || v_attribute13 || c_separator || v_attribute15 || c_separator || v_minority_class --   3.10
  || c_separator || v_minority_cd || v_attribute16  -- 5.0
  );
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
    utl_file.PUT_LINE(v_rmsfileid,   v_system || c_separator || v_file_data1 || v_file_data2 || v_file_data3 || v_file_data4 || v_file_data5 || v_file_data6 || v_attribute10 || v_attribute11 || v_attribute12 || v_attribute13 || c_separator || v_attribute15 || c_separator || v_minority_class --   3.10
    || c_separator || v_minority_cd || v_attribute16  -- 5.0
    );
  END IF;
  v_rms_flag := 'N';
END IF;*/
IF(v_psft_flag = 'Y') THEN
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
END IF;
--     dbms_output.put_line( v_file_data1 || v_file_data2 || v_file_data3 || v_file_data4 || v_file_data5 || v_file_data6);
-- V4.0, Added below update for interfaced supplier site
BEGIN

--  fnd_file.PUT_LINE(fnd_file.LOG,'RMS Count :'||to_char(v_rms_count));
--  fnd_file.PUT_LINE(fnd_file.LOG,'GSS Count :'||to_char(v_gss_count));
--  fnd_file.PUT_LINE(fnd_file.LOG,'PSFT Count :'||to_char(v_psft_count));
--  fnd_file.PUT_LINE(fnd_file.LOG,'Vendor site id :'||to_char(v_vendor_site_id));
--  fnd_file.PUT_LINE(fnd_file.LOG,'Vendor site id :'||to_char(g_vendor_site_id));

  IF  
  --v_rms_count>0 or --Commented by Sunil
  v_gss_count>0 or v_psft_count>0 THEN
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
IF(v_opengssfile = 'Y') THEN
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
END IF;
-- Copy PSFT File
IF(v_openpsftfile = 'Y') THEN
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
end if;
-- Copy RMS File--Commented by Sunil Line No. 1699 to Line No.1712
/*IF(v_openrmsfile = 'Y') THEN
utl_file.fclose(v_rmsfileid);
ln_req_id := fnd_request.submit_request('XXFIN',   'XXCOMFILCOPY',   '',   '01-OCT-04 00:00:00',   FALSE,   lc_sourcepath || '/' || v_rms_outfilename,   '$XXFIN_DATA/ftp/out/supplier/' || v_rms_outfilename,   '',   '');
COMMIT;
IF ln_req_id > 0 THEN
lb_result := fnd_concurrent.wait_for_request(ln_req_id,   10,   0,   lc_phase,   lc_status,   lc_dev_phase,   lc_dev_status,   lc_message);
END IF;
IF TRIM(lc_status) = 'Error' THEN
lc_err_status := 'Y';
lc_err_mesg := 'File Copy of the RMS Supplier File Failed : ' || v_rms_outfilename || ': Please check the Log file for Request ID : ' || ln_req_id;
fnd_file.PUT_LINE(fnd_file.LOG,   'Error : ' || lc_err_mesg || ' : ' || SQLCODE || ' : ' || sqlerrm);
END IF;
END IF;*/
fnd_file.PUT_LINE(fnd_file.LOG,   '          ');
fnd_file.PUT_LINE(fnd_file.LOG,   '****************************************************************************');
fnd_file.PUT_LINE(fnd_file.LOG,   'Number of Records:  GSS=' || v_gss_count || ' PSFT=' || v_psft_count);
fnd_file.PUT_LINE(fnd_file.LOG,   '****************************************************************************');
dbms_output.put_line('End of Program');
END;

/

SHOW ERROR
