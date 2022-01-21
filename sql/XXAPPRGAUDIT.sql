REM     ___________________________________________________________________________________________________
REM
REM     TITLE                   :  XXPRGAUDITRX.sql
REM     USED BY APPLICATION     :  AP
REM     PURPOSE                 :  Generates AP outbound audit files for Audit firm
REM     LIMITATIONS             :
REM     CREATED BY              :  ANAMITRA BANERJEE, Lead Developer - Oracle Financials, Office Depot Inc.
REM     INPUTS                  :
REM     OUTPUTS                 :
REM     HISTORY                 :  WHO -        WHAT -          DATE -
REM     NOTES                   :  Subbu		Defect 6278    05/01/2008   Added the Country in the Filename
REM                             :  Subbu        Defect 6282    05/01/2008   Added the Invoice Num in Check File
REM                             :  Sandeep      Defect 6369    05/28/2008   GL Code combination missing data
REM                             :  Madhu Bolli  Defect#36305   05-Nov-2015  I1142 - R122 Retrofit Table Schema Removal
REM     ___________________________________________________________________________________________________

set concat .
set echo off
set feed off
set head off
set linesize 32767
set pagesize 0
set trimspool on
set verify off

prompt
prompt *** Starting program OD: AP outbound Audit interface ***
prompt

column dir_path new_value p_dataout noprint
column sys_date new_value p_datestamp noprint
column resp_name new_value p_resp_name noprint
column org_id new_value p_org_id noprint

SELECT directory_path
       ||'/' dir_path,
       '_'
       ||to_char(SYSDATE,'YYYYMMDD_HH24MISS') sys_date
FROM   dba_directories
WHERE  directory_name = 'XXFIN_OUTBOUND';

SELECT '_'||substr(FND_PROFILE.value('RESP_NAME'),5,2)||'.' resp_name FROM dual;

SELECT FND_PROFILE.value('ORG_ID') org_id FROM dual;

prompt Extracting AP Outbound Data ...
prompt

spool &p_dataout.PRG_AP_INVOICES&p_datestamp&p_resp_name.dat

prompt INVOICE_ID|VENDOR_ID|INVOICE_NUM|ORG_ID|AMOUNT_PAID|APPROVAL_STATUS|BATCH_ID|CANCELLED_DATE|DISCOUNT_AMOUNT_TAKEN|DOC_CATEGORY_CODE|DOC_SEQUENCE_ID|DOC_SEQUENCE_VALUE|FREIGHT_AMOUNT|INVOICE_AMOUNT|INVOICE_CURRENCY_CODE|INVOICE_DATE|INVOICE_TYPE_LOOKUP_CODE|PAY_GROUP_LOOKUP_CODE|PAYMENT_METHOD_LOOKUP_CODE|PAYMENT_STATUS_FLAG|SOURCE|TAX_AMOUNT|TERMS_ID|VENDOR_SITE_ID

SELECT i.invoice_id
       ||'|'
       ||i.vendor_id
       ||'|'
       ||i.invoice_num
       ||'|'
       ||i.org_id
       ||'|'
       ||i.amount_paid
       ||'|'
       ||i.approval_status
       ||'|'
       ||i.batch_id
       ||'|'
       ||i.cancelled_date
       ||'|'
       ||i.discount_amount_taken
       ||'|'
       ||i.doc_category_code
       ||'|'
       ||i.doc_sequence_id
       ||'|'
       ||i.doc_sequence_value
       ||'|'
       ||i.freight_amount
       ||'|'
       ||i.invoice_amount
       ||'|'
       ||i.invoice_currency_code
       ||'|'
       ||i.invoice_date
       ||'|'
       ||i.invoice_type_lookup_code
       ||'|'
       ||i.pay_group_lookup_code
       ||'|'
       ||i.payment_method_lookup_code
       ||'|'
       ||i.payment_status_flag
       ||'|'
       ||i.source
       ||'|'
       ||i.tax_amount
       ||'|'
       ||i.terms_id
       ||'|'
       ||i.vendor_site_id
FROM   ap_invoices i
WHERE  trunc(i.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                         AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
        OR EXISTS (SELECT p.invoice_id
                   FROM   ap_invoice_payments p
                   WHERE  p.invoice_id = i.invoice_id
                          AND trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                                AND to_date('&&1','YYYY/MM/DD HH24:MI:SS'));
spool off

prompt Extracting AP Invoice Payments ...
prompt

spool &p_dataout.PRG_AP_INVOICE_PAYMENTS&p_datestamp&p_resp_name.dat

prompt INVOICE_PAYMENT_ID|INVOICE_ID|PAYMENT_NUM|ORG_ID|AMOUNT|CEHCK_ID|DISCOUNT_LOST|DISCOUNT_TAKEN|POSTED_FLAG|REVERSAL_INV_PMT_ID

SELECT p.invoice_payment_id
       ||'|'
       ||p.invoice_id
       ||'|'
       ||p.payment_num
       ||'|'
	   ||p.org_id
	   ||'|'
       ||p.amount
       ||'|'
       ||p.check_id
       ||'|'
       ||p.discount_lost
       ||'|'
       ||p.discount_taken
       ||'|'
       ||p.posted_flag
       ||'|'
       ||p.reversal_inv_pmt_id
FROM   ap_invoice_payments p,
       ap_invoices i
WHERE  i.invoice_id = p.invoice_id
       AND (trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                              AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
             OR trunc(i.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                  AND to_date('&&1','YYYY/MM/DD HH24:MI:SS'));
spool off

prompt Extracting AP Checks ...
prompt

spool &p_dataout.PRG_AP_CHECKS&p_datestamp&p_resp_name.dat

prompt INVOICE_NUM|ORG_ID|CHECK_ID|CHECK_STOCK_ID|CHECK_NUMBER|AMOUNT|BANK_ACCOUNT_ID|BANK_ACCOUNT_NAME|CHECK_DATE|CHECKRUN_NAME|CLEARED_DATE|CURRENCY_CODE|DOC_CATEGORY_CODE|DOC_SEQUENCE_ID|DOC_SEQUENCE_VALUE|PAYMENT_METHOD_LOOKUP_CODE|PAYMENT_TYPE_FLAG|STATUS_LOOKUP_CODE|VENDOR_ID|VENDOR_NAME|VENDOR_SITE_ID|VOID_DATE

SELECT i.invoice_num
	   ||'|'
	   ||i.org_id
	   ||'|'
	   ||c.check_id
       ||'|'
       ||c.check_stock_id
       ||'|'
       ||c.check_number
       ||'|'
       ||c.amount
       ||'|'
       ||c.bank_account_id
       ||'|'
       ||c.bank_account_name
       ||'|'
       ||c.check_date
       ||'|'
       ||c.checkrun_name
       ||'|'
       ||c.cleared_date
       ||'|'
       ||c.currency_code
       ||'|'
       ||c.doc_category_code
       ||'|'
       ||c.doc_sequence_id
       ||'|'
       ||c.doc_sequence_value
       ||'|'
       ||c.payment_method_lookup_code
       ||'|'
       ||c.payment_type_flag
       ||'|'
       ||c.status_lookup_code
       ||'|'
       ||c.vendor_id
       ||'|'
       ||c.vendor_name
       ||'|'
       ||c.vendor_site_id
       ||'|'
       ||c.void_date
FROM   ap_checks c,
       ap_invoice_payments p,
       ap_invoices i
WHERE  p.check_id = c.check_id
       AND i.invoice_id = p.invoice_id
       AND (trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                              AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
             OR trunc(i.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                  AND to_date('&&1','YYYY/MM/DD HH24:MI:SS'));
spool off

prompt Extracting AP Invoice Distributions ...
prompt

spool &p_dataout.PRG_AP_INVOICE_DISTRIBUTIONS&p_datestamp&p_resp_name.dat

prompt ORG_ID|INVOICE_DISTRIBUTION_ID|INVOICE_ID|DISTRIBUTION_LINE_NUMBER|AMOUNT|BASE_INVOICE_PRICE_VARIANCE|DESCRIPTION|DIST_CODE_COMBINATION_ID|LINE_TYPE_LOOKUP_CODE|PO_DISTRIBUTION_ID|POSTED_FLAG|QUANTITY_INVOICED|REVERSAL_FLAG|UNIT_PRICE

SELECT d.org_id
       ||'|'
	   ||d.invoice_distribution_id
       ||'|'
       ||d.invoice_id
       ||'|'
       ||d.distribution_line_number
       ||'|'
       ||d.amount
       ||'|'
       ||d.base_invoice_price_variance
       ||'|'
       ||d.description
       ||'|'
       ||d.dist_code_combination_id
       ||'|'
       ||d.line_type_lookup_code
       ||'|'
       ||d.po_distribution_id
       ||'|'
       ||d.posted_flag
       ||'|'
       ||d.quantity_invoiced
       ||'|'
       ||d.reversal_flag
       ||'|'
       ||d.unit_price
FROM   ap_invoice_distributions d,
       ap_invoices i
WHERE  i.invoice_id = d.invoice_id
       AND ((trunc(i.last_update_date)) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
             OR EXISTS (SELECT p.invoice_id
                        FROM   ap_invoice_payments p
                        WHERE  p.invoice_id = i.invoice_id
                               AND trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                                     AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')));
spool off
/*
prompt Extracting AP Invoice Batches ...
prompt

spool &p_dataout.PRG_AP_BATCHES&p_datestamp.dat

SELECT DISTINCT b.batch_id,
                b.batch_name,
                b.batch_date,
                b.org_id
FROM   ap_invoices i,
       ap_batches b
WHERE  i.batch_id = b.batch_id
       AND ((trunc(i.last_update_date)) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
             OR EXISTS (SELECT p.invoice_id
                        FROM   ap_invoice_payments p
                        WHERE  p.invoice_id = i.invoice_id
                               AND trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                                     AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')));
spool off
*/
prompt Extracting AP Check Stocks ...
prompt

spool &p_dataout.PRG_AP_CHECK_STOCKS&p_datestamp&p_resp_name.dat

prompt ORG_ID|CHECK_STOCK_ID|BANK_ACCOUNT_ID|NAME

SELECT DISTINCT s.org_id
                ||'|'
				||s.check_stock_id
                ||'|'
                ||s.bank_account_id
                ||'|'
                ||s.NAME
FROM   ap_checks c,
       ap_invoice_payments p,
       ap_invoices i,
       ap_check_stocks s
WHERE  c.check_stock_id = s.check_stock_id
       AND p.check_id = c.check_id
       AND i.invoice_id = p.invoice_id
       AND (trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                              AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
             OR trunc(i.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                  AND to_date('&&1','YYYY/MM/DD HH24:MI:SS'));
spool off

prompt Extracting PO Distributions ...
prompt

spool &p_dataout.PRG_PO_DISTRIBUTIONS&p_datestamp&p_resp_name.dat

prompt ORG_ID|PO_DISTRIBUTION_ID|AMOUNT_BILLED|AMOUNT_CANCELLED|AMOUNT_DELIVERED|AMOUNT_ORDERED|CODE_COMBINATION_ID|DELIVER_TO_LOCATION_ID|DESTINATION_ORGANIZATION_ID|DESTINATION_TYPE_CODE|LINE_LOCATION_ID|PO_HEADER_ID|PO_LINE_ID|QUANTITY_BILLED|QUANTITY_CANCELLED|QUANTITY_DELIVERED|QUANTITY_ORDERED

SELECT DISTINCT pd.org_id
                ||'|'
				||pd.po_distribution_id
                ||'|'
                ||pd.amount_billed
                ||'|'
                ||pd.amount_cancelled
                ||'|'
                ||pd.amount_delivered
                ||'|'
                ||pd.amount_ordered
                ||'|'
                ||pd.code_combination_id
                ||'|'
                ||pd.deliver_to_location_id
                ||'|'
                ||pd.destination_organization_id
                ||'|'
                ||pd.destination_type_code
                ||'|'
                ||pd.line_location_id
                ||'|'
                ||pd.po_header_id
                ||'|'
                ||pd.po_line_id
                ||'|'
                ||pd.quantity_billed
                ||'|'
                ||pd.quantity_cancelled
                ||'|'
                ||pd.quantity_delivered
                ||'|'
                ||pd.quantity_ordered
FROM   ap_invoice_distributions id,
       po_distributions pd,
       ap_invoices i
WHERE  ((trunc(i.last_update_date)) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                            AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
         OR EXISTS (SELECT p.invoice_id
                    FROM   ap_invoice_payments p
                    WHERE  p.invoice_id = i.invoice_id
                           AND trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                                 AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')))
       AND id.invoice_id = i.invoice_id
       AND pd.po_distribution_id = id.po_distribution_id;
spool off

prompt Extracting PO Headers ...
prompt

spool &p_dataout.PRG_PO_HEADERS&p_datestamp&p_resp_name.dat

prompt ORG_ID|PO_HEADER_ID|AGENT_ID|APPROVED_DATE|BILL_TO_LOCATION_ID|CLOSED_CODE|CLOSED_DATE|CREATION_DATE|END_DATE_ACTIVE|FOB_LOOKUP_CODE|FREIGHT_TERMS_LOOKUP_CODE|LAST_UPDATE_DATE|PRINTED_DATE|REVISED_DATE|SEGMENT1|SHIP_TO_LOCATION_ID|SHIP_VIA_LOOKUP_CODE|START_DATE_ACTIVE|TERMS_ID|VENDOR_CONTACT_ID|VENDOR_ID|VENDOR_SITE_ID

SELECT DISTINCT h.org_id
                ||'|'
				||h.po_header_id
                ||'|'
                ||h.agent_id
                ||'|'
                ||h.approved_date
                ||'|'
                ||h.bill_to_location_id
                ||'|'
                ||h.closed_code
                ||'|'
                ||h.closed_date
                ||'|'
                ||h.creation_date
                ||'|'
                ||h.end_date_active
                ||'|'
                ||h.fob_lookup_code
                ||'|'
                ||h.freight_terms_lookup_code
                ||'|'
                ||h.last_update_date
                ||'|'
                ||h.printed_date
                ||'|'
                ||h.revised_date
                ||'|'
                ||h.segment1
                ||'|'
                ||h.ship_to_location_id
                ||'|'
                ||h.ship_via_lookup_code
                ||'|'
                ||h.start_date_active
                ||'|'
                ||h.terms_id
                ||'|'
                ||h.vendor_contact_id
                ||'|'
                ||h.vendor_id
                ||'|'
                ||h.vendor_site_id
FROM   ap_invoice_distributions id,
       po_distributions pd,
       ap_invoices i,
       po_headers h
WHERE  pd.po_header_id = h.po_header_id
       AND ((trunc(i.last_update_date)) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
             OR EXISTS (SELECT p.invoice_id
                        FROM   ap_invoice_payments p
                        WHERE  p.invoice_id = i.invoice_id
                               AND trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                                     AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')))
       AND id.invoice_id = i.invoice_id
       AND pd.po_distribution_id = id.po_distribution_id;
spool off

prompt Extracting PO Vendors ...
prompt

spool &p_dataout.PRG_PO_VENDORS&p_datestamp&p_resp_name.dat

prompt VENDOR_ID|CUSTOMER_NUM|EMPLOYEE_ID|END_DATE_ACTIVE|FOB_LOOKUP_CODE|LAST_UPDATE_DATE|NUM_1099|ORGANIZATION_TYPE_LOOKUP_CODE|PAY_GROUP_LOOKUP_CODE|SEGMENT1|SHIP_VIA_LOOKUP_CODE|STANDARD_INDUSTRY_CLASS|TERMS_ID|VENDOR_NAME|VENDOR_TYPE_LOOKUP_CODE

SELECT DISTINCT v.vendor_id
                ||'|'
                ||v.customer_num
                ||'|'
                ||v.employee_id
                ||'|'
                ||v.end_date_active
                ||'|'
                ||v.fob_lookup_code
                ||'|'
                ||v.last_update_date
                ||'|'
                ||v.num_1099
                ||'|'
                ||v.organization_type_lookup_code
                ||'|'
                ||v.pay_group_lookup_code
                ||'|'
                ||v.segment1
                ||'|'
                ||v.ship_via_lookup_code
                ||'|'
                ||v.standard_industry_class
                ||'|'
                ||v.terms_id
                ||'|'
                ||v.vendor_name
                ||'|'
                ||v.vendor_type_lookup_code
FROM   ap_invoices i,
       po_vendors v
WHERE  i.vendor_id = v.vendor_id
       AND ((trunc(i.last_update_date)) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
             OR EXISTS (SELECT p.invoice_id
                        FROM   ap_invoice_payments p
                        WHERE  p.invoice_id = i.invoice_id
                               AND trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                                     AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')));
spool off

prompt Extracting PO Vendor Sites ...
prompt

spool &p_dataout.PRG_PO_VENDOR_SITES&p_datestamp&p_resp_name.dat

prompt ORG_ID|VENDOR_SITE_ID|VENDOR_ID|ADDRESS_LINE1|ADDRESS_LINE2|ADDRESS_LINE3|ADDRESS_LINES_ALT|AREA_CODE|CITY|COUNTRY|FAX|FAX_AREA_CODE|PAYMENT_CURRENCY_CODE|PHONE|STATE|TERMS_ID|VENDOR_SITE_CODE|ZIP

SELECT DISTINCT s.org_id
                ||'|'
				||s.vendor_site_id
                ||'|'
                ||s.vendor_id
                ||'|'
                ||REPLACE(s.address_line1,chr(13),NULL)
                ||'|'
                ||REPLACE(s.address_line2,chr(13),NULL)
                ||'|'
                ||REPLACE(s.address_line3,chr(13),NULL)
                ||'|'
                ||REPLACE(s.address_lines_alt,chr(13),NULL)
                ||'|'
                ||s.area_code
                ||'|'
                ||s.city
                ||'|'
                ||s.country
                ||'|'
                ||s.fax
                ||'|'
                ||s.fax_area_code
                ||'|'
                ||s.payment_currency_code
                ||'|'
                ||s.phone
                ||'|'
                ||s.state
                ||'|'
                ||s.terms_id
                ||'|'
                ||s.vendor_site_code
                ||'|'
                ||s.zip
FROM   ap_invoices i,
       po_vendor_sites s
WHERE  i.vendor_site_id = s.vendor_site_id
       AND ((trunc(i.last_update_date)) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
             OR EXISTS (SELECT p.invoice_id
                        FROM   ap_invoice_payments p
                        WHERE  p.invoice_id = i.invoice_id
                               AND trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                                     AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')));
spool off

prompt Extracting PO Vendor Contacts ...
prompt

spool &p_dataout.PRG_PO_VENDOR_CONTACTS&p_datestamp&p_resp_name.dat

prompt VENDOR_CONTACT_ID|VENDOR_SITE_ID|AREA_CODE|FIRST_NAME|LAST_NAME|MIDDLE_NAME|PHONE|PREFIX|TITLE

SELECT DISTINCT c.vendor_contact_id
                ||'|'
                ||c.vendor_site_id
                ||'|'
                ||c.area_code
                ||'|'
                ||c.first_name
                ||'|'
                ||c.last_name
                ||'|'
                ||c.middle_name
                ||'|'
                ||c.phone
                ||'|'
                ||c.prefix
                ||'|'
                ||c.title
FROM   ap_invoices i,
       po_vendor_contacts c
WHERE  i.vendor_site_id = c.vendor_site_id
       AND ((trunc(i.last_update_date)) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
             OR EXISTS (SELECT p.invoice_id
                        FROM   ap_invoice_payments p
                        WHERE  p.invoice_id = i.invoice_id
                               AND trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                                     AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')));
spool off

prompt Extracting AP Payment Terms ...
prompt

spool &p_dataout.PRG_AP_PAYMENT_TERMS&p_datestamp&p_resp_name.dat

prompt TERM_ID|LANGUAGE|DESCRIPTION|NAME|SOURCE_LANG

SELECT DISTINCT t.term_id
                ||'|'
                ||t.language
                ||'|'
                ||t.description
                ||'|'
                ||t.NAME
                ||'|'
                ||t.source_lang
FROM   ap_invoices i,
       ap_terms_tl t
WHERE  i.terms_id = t.term_id
       AND ((trunc(i.last_update_date)) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')
             OR EXISTS (SELECT p.invoice_id
                        FROM   ap_invoice_payments p
                        WHERE  p.invoice_id = i.invoice_id
                               AND trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                                     AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')));
spool off

prompt Extracting GL Code Combinations ...
prompt


spool &p_dataout.PRG_GL_CODE_COMBINATIONS&p_datestamp&p_resp_name.dat

prompt CODE_COMBINATION_ID|CHART_OF_ACCOUNTS_ID|SEGMENT1|SEGMENT2|SEGMENT3|SEGMENT4|SEGMENT5|SEGMENT6|SEGMENT7

SELECT DISTINCT code_combination_id
                ||'|'
                ||chart_of_accounts_id
                ||'|'
                ||segment1
                ||'|'
                ||segment2
                ||'|'
                ||segment3
                ||'|'
                ||segment4
                ||'|'
                ||segment5
                ||'|'
                ||segment6
                ||'|'
                ||segment7
FROM   gl_code_combinations g,
       ap_invoice_distributions d,
       ap_invoices i , ap_invoice_payments p
WHERE  d.dist_code_combination_id = g.code_combination_id
       AND i.invoice_id = d.invoice_id
       and i.invoice_id = p.invoice_id(+)
       AND ((trunc(i.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                AND to_date('&&1','YYYY/MM/DD HH24:MI:SS'))
			      OR                                                
						(trunc(p.last_update_date) BETWEEN to_date('&&1','YYYY/MM/DD HH24:MI:SS') - &&2
                                                AND to_date('&&1','YYYY/MM/DD HH24:MI:SS')));
                                  
spool off

host mv &p_dataout.PRG_*&p_datestamp&p_resp_name.dat $XXFIN_DATA/ftp/out/prg
host cp $XXFIN_DATA/ftp/out/prg/PRG_*&p_datestamp&p_resp_name.dat $XXFIN_ARCHIVE/outbound/

prompt *** End of program ***
prompt
