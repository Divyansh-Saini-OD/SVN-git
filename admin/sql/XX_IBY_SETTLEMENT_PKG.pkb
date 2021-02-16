create or replace package body XX_IBY_SETTLEMENT_PKG
AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name        : Settlement and Payment Processing                           |
-- | RICE ID     : I0349 settlement                                            |
-- | Description : To populate the XX_IBY_BATCH_TRXNS 101, 201                 |
-- |               tables.                                                     |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date         Author              Remarks                        |
-- |=========  ===========  ==================  ===============================|
-- |1 to 11.5  30-AUG-2007  Various             Various - See previous         |
-- |                                            version of the code for        |
-- |                                            defect numbes                  |
-- |11.6                    R.Aldridge and      Defect 10836 (CR898)           |
-- |                        P.Marco             SDR changes                    |
-- |11.7                    R.Aldridge          Defect 12686                   |
-- |11.8                    P.Marco             Defect 12713                   |
-- |11.9                    B Nanapaneni        Defect 12724                   |
-- |11.10                   P.Marco             Defect 12544 and 13074         |
-- |11.11                   P.Marco             Defect 13110                   |
-- |11.12      10-AUG-2011  P.Marco             Defect 13248                   |
-- |11.13      17-AUG-2011  R.Aldridge          Defect 13321 - Remove          |
-- |                                            duplicate tangible id          |
-- |                                            check.  not required           |
-- |11.14      25-AUG-2011  R.Aldridge          Defect 13318 and 13433 - added |
-- |                                            hint to use correct index on   |
-- |                                            xx_ar_order_receipt_dtl        |
-- |                                            Removed coded added for 13248  |
-- |11.15      25-AUG-2011  R.Aldridge          Defect 13498 - ixinvoice is    |
-- |                                            missing for deposit refunds    |
-- |11.16      29-AUG-2011  R.Aldridge          Defect 13466 - Fix for AMEX CPC|
-- |                                            AOPS store to ship from        |
-- |                                            Defect 12840 - Fix null values |
-- |                                            for IREC and MISC              |
-- |11.17      16-SEP-2011  P.Marco             Defect 13812,13640,13837, 13814|
-- |11.18      01-DEC-2011  Aravind A.          Fixed defects 14579 and 14419  |
-- |12.01      02-FEB-2012  Bapuji  N.          FIxed defect 15454             |
-- |12.02      26-MAR-2012  Aravind A.          Fixed defects 17473            |
-- |13.01      01-JUL-2012  Rohit Ranjan        Fixed Defect# 13405            |
-- |13.02      24-MAY-2013  Bapuji N            Fix for PCI compliance for IREC|
-- |                                            Payments DEFECT# 23640         |
-- |14.0       16-AUG-2013  Edson Morales       Retrofited for R12 upgrade     |
-- |14.1       29-AUG-2013  Edson Morales       R12 Encryption Changes         |
-- |14.2       17-SEP-2013  Edson Morales       Added AJB encryption changes   |
-- |14.3       01-OCT-2013  Edson Morales       Fix query for capture          |
-- |14.4       02-OCT-2013  Edson Morales       Removed redundant encryption   |
-- |                                            and decryption                 |
-- |14.5       12-DEC-2013  Deepak V            Changes done for Defect 26781. |
-- |                                            ar_vat_tax_all replaced by     |
-- |                                            zx_rates_b.                    |
-- |14.6       13-DEC-2013  Edson Morales       Added by decryption for AMEX_CPC |
-- |14.7       18-DEC-2013  Edson Morales       Getting and passing org_id to
-- |                                            ar_system_parameters_all       |
-- |14.8       06-JAN-2013  Edson Morales       Fix for Defect 27469           |
-- |14.9       09-JAN-2013  Edson Morales       Fix for Defect 27466           |
-- |15.0       23-JAN-2014  Edson Morales       Fix for Defect 27744           |
-- |16.0       24-JAN-2014  Arun Gannarapu      Fix for Defect 27580           |
-- |17.0       13-Feb-2014  Lakshmi T           Changes for Defect 27883       |
-- |18.0       03-MAR-2014  Edson Morales       Changes for Defect 28663       |
-- |19.0       05-MAR-2014  Edson Morales       Changes for Defect 28761       |
-- |20.0       11-MAR-2014  Edson Morales       Changes for Defect 28688       |
-- |21.0       18-MAR-2014  Arun Gannarapu      changes for defect 29040       |
-- |22.0       07-JUL-2014  Manjusha Tangirala  Changes for defect 30047       |
-- |22.0       28-MAR-2014  Edson Morales       Changes to support manual      |
-- |                                            deposit cancelations.          |
-- |23.0       01-APR-2014  Edson               Changes for Defect 29243       |
-- |24.0       28-May-2014  Suresh Ponnambalam  Defect 29951. Raised exception |
-- |                                            in decrypt_credit_card.        |
-- |25.0       12-Aug-2014  Mark Schmit         Defect 31392. Perform CC       |
-- |                                            decrypt test prior to file     |
-- |                                            transfer routine.              |
-- |25.1       22-Sept-2014 Mark Schmit         Debug Statement remove         |
-- |26.0       09-OCT-2014  Kirubha Samuel      Modified 'xx_retrieve_receipt_info'|
-- |     select for refund transactions to include gn_cust_account_id for 31270|
-- |26.1       24-FEB-2015  Kirubha Samuel      Modified 'xx_insert_manual_receipt'|
-- |           to update the payment number for receipts created manually for 32588|
-- |26.2       25-MAR-2015 Suresh Ponnambalam   Module 4A Settlement Changes   |
-- |26.3       28-APR-2015 Harvinder Rakhra     Tokenization of Credit Card    |
-- |26.4       22-MAY-2015 Harvinder Rakhra     Tokenization of Credit Card    |
-- |26.5       29-MAY-2015 Suresh Ponnambalam   Mod 4A secondary soft header   |
-- |26.6       03-JUN-2015 Suresh Ponnambalam   Tokenization: Added token flag |
-- |                                            to xx_ar_invoice_ods           |
-- |26.7       18-JUN-2015 Harvinder Rakhra     Tokenization: Defect 34724     |
-- |26.8       24-JUN-2015 Rakesh Polepalli	Modified the procedure         |
-- |						'xx_set_post_trx_variables'    |
-- |						as part of the Defect# 34612   |
-- |26.9       08-JUL-2015 Harvinder Rakhra     Tokenization Changes           |
-- |27.0       27-JUL-2015 Harvinder Rakhra     Set Field21 and Field56 based  |
-- |                                            on EMV fields.                 |
-- |                                            Tokenization Changes. Defect#35087   |
-- |27.1       06-AUG-2015 Harvinder Rakhra     Space Delimiter added for EMV fields |
-- |27.2       11-AUG-2015 Harvinder Rakhra     gc_ixswipe value updated based |
-- |                                            on ixswipe value               |
-- |27.3       19-AUG-2015 Harvinder Rakhra     Defect in gc_ixoptions logic changed|
-- |28.0       27-AUG-2014 Suresh Ponnambalam   Defect 35495. Added exception  |
-- |                                            to xx_ar_invoice_ods.          |
-- |29.0       28-AUG-2015 Shubhashree R       Modified xx_set_post_trx_variables|
-- |                                           procedure for Defect# 35181     |
-- |30.0       18-SEP-2015 Rakesh Polepalli    Defect# 35780,Modified 'EACH' to 'EA' in the |
-- |					       procedure xx_create_201_settlement_rec |
-- |31.0       10-OCT-2015 rakesh Polepalli    Defect# 35839,Modified clbatch procedure |
-- |32.0       14-OCT-2015 Avinash Baddam      Changes for Defect#36003 and    |
-- |					       R12.2 Compliance Changes        |
-- |33.0       18-FEB-2016 Avinash Baddam      Defect#37204 - Masterpass       |
-- |34.0	   29-APR-2016 Rakesh Polepalli    Changes for the defect# 37763   |
-- |35.0	   23-JUN-2016 Rakesh Polepalli    Changes for the defect# 38244   |
-- |36.0       24-JUN-2016 Avinash Baddam      Defect#38215 - amex to vantiv conv   |
-- |37.0       23-AUG-2016 Suresh Ponnambalam  Defect 38243 - AMEX Instrsubtype|
-- |38.0       30-AUG-2016 Suresh Ponnambalam  Defect 39040 - Removed : from   |
-- |                                           ixcustcountrycode.              |
-- |39.0       16-SEP-2016 Suresh Ponnambalam  Defect 39341 - Remapped ixreleasenumber |
-- |                                           to ixothertaxamount3 and remove |
-- |                                           ixoriginalinvoiceno from file.  |
-- |40.0       17-OCT-2016 Suresh Ponnambalam  Amex to check ixunitcost instead |
-- |                                           of ixcustunitprice to create level 2|
-- |41.0	   03-NOV-2016 Rakesh Polepalli    Changes for defects# 37866,39910 |
-- |42.0	   03-NOV-2016 Rakesh Polepalli    Changes for defects# 38223,40149 |
-- |43.0       27-DEC-2016 Suresh Ponnambalam  Defect 40377 AMEX SKU order change|
-- |44.0     02-SEP-2017  Uday Jadhav         Changes done for BIZBOX Rollout to pass MPL_ORDER_ID to IXINVOICE|
-- |45.0       05-FEB-2018 Atul Khard  		   Defect 44326 Adding HINT /*+ index(OOH,OE_ORDER_HEADERS_U2) */|
-- |46.0       21-FEB-2018 Rohit Gupta         Modified code for defect #44299 |
-- |47.0       05-MAR-2018 M K Pramod Kumar    Modified code for defect NAIT-31107 |
-- |47.1       05-MAR-2018 M K Pramod Kumar    Code Change to process UnApplied Invoices for SERVICE-CONTRACTS |
-- |47.2       05-MAR-2018 M K Pramod Kumar    Modified to derive Invoice Num from ORDT |
-- |47.3       14-MAR-2018 M K Pramod Kumar    Modified to derive gc_ixreserved31 to default to *ECI for SERVICE-CONTRACTS  |
-- |48.0       21-FEB-2019 M K Pramod Kumar    Modified  code for COF changes per NAIT-83065 |
-- |48.1       10-MAY-2019 M K Pramod Kumar    Modified to to derive Instance Name for LNS
-- |48.2       12-SEP-2019 M K Pramod Kumar    Modified for Return Mandate per NAIT-106896
-- |48.3       07-JAN-2020 Sripal Reddy        Modified for sglpmt_multi_settlement refund issue NAIT-115171  |
-- |48.4       18-FEB-2020 Sripal reddy        Modified for POC: Customer PO line number NAIT 123195 by sripal  |
-- |48.5       13-JUL-2020 Atul Khard          Modified for NAIT-131811: POS Settlement Changes for Partial Reversal   |
-- |48.6       16-JUL-2020 Atul Khard          Modified for EMV Card changes   |
-- |48.7	   30-NOV-2020 Karan Varshney 	   Modified for AJBCredit - Settlement Issue (NAIT-161505)	|
-- |48.8	   06-JAN-2021 Karan Varshney	   Modiifed for OD EBS Field 50 in the settlement issue (NAIT-165607)  	|
-- +===========================================================================+

	g_package_name              CONSTANT all_objects.object_name%TYPE                        := 'xx_iby_settlement_pkg';
	g_return_success            CONSTANT VARCHAR2(20)                                              := 'SUCCESS';
	g_return_failure            CONSTANT VARCHAR2(20)                                              := 'FAILURE';
	g_return_too_many_rows      CONSTANT VARCHAR2(20)                                              := 'TOO_MANY_ROWS';
	g_return_no_data_found      CONSTANT VARCHAR2(20)                                              := 'NO_DATA_FOUND';
	g_max_error_message_length  CONSTANT NUMBER                                                    := 2000;
	g_debug                              BOOLEAN                                                   := FALSE;
	g_max_err_buf_size          CONSTANT NUMBER                                                    := 250;
	-------------------------------------
-- Global Constants
-------------------------------------
-- Sale Types
	g_sale                      CONSTANT xx_ar_order_receipt_dtl.sale_type%TYPE                    := 'SALE';
	g_refund                    CONSTANT xx_ar_order_receipt_dtl.sale_type%TYPE                    := 'REFUND';
	g_dep_sales                 CONSTANT xx_ar_order_receipt_dtl.sale_type%TYPE                    := 'DEPOSIT-SALE';
	g_dep_refund                CONSTANT xx_ar_order_receipt_dtl.sale_type%TYPE                    := 'DEPOSIT-REFUND';
	-- POS/POE Order Type
	g_poe                       CONSTANT xx_ar_order_receipt_dtl.order_type%TYPE                   := 'POE';
	-- Remittance Processing Types
	g_poe_int_store_cust        CONSTANT VARCHAR2(50)                                              := 'POE_INT_STORE_CUST';
	g_poe_single_pmt_multi_ord  CONSTANT VARCHAR2(50)                                              := 'POE_SINGLE_PMT_MULTI_ORDER';
	g_irec                      CONSTANT VARCHAR2(50)                                              := 'IREC';
	g_ccrefund                  CONSTANT VARCHAR2(50)                                              := 'CCREFUND';
	g_default                   CONSTANT VARCHAR2(50)                                              := 'DEFAULT_PROCESSING';
	g_service_contracts         CONSTANT VARCHAR2(50)                                              := 'SERVICE-CONTRACTS';--Added for V47.0 5/Mar/2018
	-- Credit Card Types
	g_visa_card_type            CONSTANT xx_fin_translatevalues.target_value1%TYPE                 := 'VISA';
	g_master_card_type          CONSTANT xx_fin_translatevalues.target_value1%TYPE                 := 'MASTERCARD';
	g_disc_card_type            CONSTANT xx_fin_translatevalues.target_value1%TYPE                 := 'DISCOVER';
	g_amex_card_type            CONSTANT xx_fin_translatevalues.target_value1%TYPE                 := 'AMEX';
	-- Settlement Record Types
	g_ixrecordtype_101          CONSTANT xx_iby_batch_trxns.ixrecordtype%TYPE                      := '101';
	g_ixrecordtype_201          CONSTANT xx_iby_batch_trxns.ixrecordtype%TYPE                      := '201';
	g_pre1                      CONSTANT xx_iby_batch_trxns.pre1%TYPE                              := '0 0 0 ';
	g_pre3                      CONSTANT xx_iby_batch_trxns.pre3%TYPE                              := ' ';
	g_ixactioncode              CONSTANT xx_iby_batch_trxns.ixactioncode%TYPE                      := '0';
	g_ixmessagetype             CONSTANT xx_iby_batch_trxns.ixmessagetype%TYPE                     := 'Credit';
	g_pre2_length               CONSTANT xx_iby_batch_trxns.pre2%TYPE                              := 6;
	-- Record Retrieval Status
	g_multi                     CONSTANT VARCHAR2(25)                                              := 'MULTI_RECORDS_FOUND';
	g_zero                      CONSTANT VARCHAR2(25)                                              := 'NO_RECORD_FOUND';
	g_single                    CONSTANT VARCHAR2(25)                                              := 'SINGLE_RECORD_FOUND';
	-- Other
	g_rpad_len_30               CONSTANT NUMBER                                                    := 30;
	g_loc                       CONSTANT VARCHAR2(10)                                              := 'LOCATION';
	g_log                       CONSTANT VARCHAR2(10)                                              := 'LOG_FILE';
	g_irec_store_number         CONSTANT xx_ar_order_receipt_dtl.store_number%TYPE                 := '001099';
	g_servc_contract_store_number         CONSTANT xx_ar_order_receipt_dtl.store_number%TYPE       := '001165';--Added for V47.0 5/Mar/2018--This is used only for exception
-----------------------------------------------------------------------------
-- Define Package Variables ONLY.  Must add to XX_INIT_PRIVATE_PKG_VARIABLES
-----------------------------------------------------------------------------
	gc_pre2                              xx_iby_batch_trxns.pre2%TYPE;
	gc_ixreserved7                       xx_iby_batch_trxns.ixreserved7%TYPE;
	gc_ixstorenumber                     xx_iby_batch_trxns.ixstorenumber%TYPE;
	gc_ixregisternumber                  xx_iby_batch_trxns.ixregisternumber%TYPE;
	gc_ixtransactiontype                 xx_iby_batch_trxns.ixtransactiontype%TYPE;
	gc_ixreserved31                      xx_iby_batch_trxns.ixreserved31%TYPE;
	gc_ixreserved32                      xx_iby_batch_trxns.ixreserved32%TYPE;
	gc_ixreserved33                      xx_iby_batch_trxns.ixreserved33%TYPE;  --Added new Column, Version 26.3
	gc_ixreserved39                      xx_iby_batch_trxns.ixreserved33%TYPE;  --Added new Column, Version 26.5
	gc_ixreserved43                      xx_iby_batch_trxns.ixreserved43%TYPE;
	gc_ixreserved53                      xx_iby_batch_trxns.ixreserved53%TYPE;
	gc_ixreserved56                      xx_iby_batch_trxns.ixreserved56%TYPE;  --Added new Column, Version 27.0
	gc_ixexpdate                         xx_iby_batch_trxns.ixexpdate%TYPE;
	gc_ixswipe                           xx_iby_batch_trxns.ixswipe%TYPE;
	gc_ixamount                          xx_iby_batch_trxns.ixamount%TYPE;
    gc_ixreserved20                      xx_iby_batch_trxns.ixreserved20%TYPE; --Addded for NAIT-131811
	gc_ixinvoice                         xx_iby_batch_trxns.ixinvoice%TYPE;
	gc_ixoptions                         xx_iby_batch_trxns.ixoptions%TYPE;
	gc_ixbankuserdata                    xx_iby_batch_trxns.ixbankuserdata%TYPE;
	gc_ixissuenumber                     xx_iby_batch_trxns.ixissuenumber%TYPE;
	gc_ixtotalsalestaxamount             xx_iby_batch_trxns.ixtotalsalestaxamount%TYPE;
	gc_ixtotalsalestaxcollind            xx_iby_batch_trxns.ixtotalsalestaxcollind%TYPE;
	gc_ixreceiptnumber                   xx_iby_batch_trxns.ixreceiptnumber%TYPE;
	gc_ixauthorizationnumber             xx_iby_batch_trxns.ixauthorizationnumber%TYPE;
	gc_ixps2000                          xx_iby_batch_trxns.ixps2000%TYPE;
	gc_ixreference                       xx_iby_batch_trxns.ixreference%TYPE;
	gc_ixdate                            xx_iby_batch_trxns.ixdate%TYPE;
	gc_ixtime                            xx_iby_batch_trxns.ixtime%TYPE;
	gc_ixcustomerreferenceid             xx_iby_batch_trxns.ixcustomerreferenceid%TYPE;
	gc_ixnationaltaxcollindicator        xx_iby_batch_trxns.ixnationaltaxcollindicator%TYPE;
	gc_ixnationaltaxamount               xx_iby_batch_trxns.ixnationaltaxamount%TYPE;
	gc_ixothertaxamount                  xx_iby_batch_trxns.ixothertaxamount%TYPE;
	gc_ixdiscountamount                  xx_iby_batch_trxns.ixdiscountamount%TYPE;
	gc_ixshippingamount                  xx_iby_batch_trxns.ixshippingamount%TYPE;
	gc_ixtaxableamount                   xx_iby_batch_trxns.ixtaxableamount%TYPE;
	gc_tot_order_amount                  xx_iby_batch_trxns.attribute5%TYPE;
	gc_ixdutyamount                      xx_iby_batch_trxns.ixdutyamount%TYPE;
	gc_ixshipfromzipcode                 xx_iby_batch_trxns.ixshipfromzipcode%TYPE;
	gc_ixshiptocompany                   xx_iby_batch_trxns.ixshiptocompany%TYPE;
	gc_ixshiptoname                      xx_iby_batch_trxns.ixshiptoname%TYPE;
	gc_ixshiptostreet                    xx_iby_batch_trxns.ixshiptostreet%TYPE;
	gc_ixshiptocity                      xx_iby_batch_trxns.ixshiptocity%TYPE;
	gc_ixshiptostate                     xx_iby_batch_trxns.ixshiptostate%TYPE;
	gc_ixshiptocountry                   xx_iby_batch_trxns.ixshiptocountry%TYPE;
	gc_ixshiptozipcode                   xx_iby_batch_trxns.ixshiptozipcode%TYPE;
	gc_ixpurchasername                   xx_iby_batch_trxns.ixpurchasername%TYPE;
	gc_ixcustaccountno                   xx_iby_batch_trxns.ixcustaccountno%TYPE;
	gc_ixorderdate                       xx_iby_batch_trxns.ixorderdate%TYPE;
	gc_ixmerchantvatnumber               xx_iby_batch_trxns.ixmerchantvatnumber%TYPE;
	gc_ixcustomervatnumber               xx_iby_batch_trxns.ixcustomervatnumber%TYPE;
	gc_ixvatamount                       xx_iby_batch_trxns.ixvatamount%TYPE;
	gc_ixmerchandiseshipped              xx_iby_batch_trxns.ixmerchandiseshipped%TYPE;
	gc_ixcustcountrycode                 xx_iby_batch_trxns.ixcustcountrycode%TYPE;
	gc_ixcostcenter                      xx_iby_batch_trxns.ixcostcenter%TYPE;
	gc_ixdesktoplocation                 xx_iby_batch_trxns.ixdesktoplocation%TYPE;
	gc_ixreleasenumber                   xx_iby_batch_trxns.ixreleasenumber%TYPE;
	gc_ixoriginalinvoiceno               xx_iby_batch_trxns.ixoriginalinvoiceno%TYPE;
	gc_orig_invoice_num                  xx_iby_batch_trxns.ixoriginalinvoiceno%TYPE;
	gc_ixothertaxamount2                 xx_iby_batch_trxns.ixothertaxamount2%TYPE;
	gc_ixothertaxamount3                 xx_iby_batch_trxns.ixothertaxamount3%TYPE;
	gc_ixmisccharge                      xx_iby_batch_trxns.ixmisccharge%TYPE;
	gc_ixaccount                         xx_iby_batch_trxns.ixaccount%TYPE;
	gc_ixccnumber                        xx_iby_batch_trxns.ixccnumber%TYPE;
	gc_ixtokenflag                       xx_ar_order_receipt_dtl.token_flag%TYPE;       --Added new Column, Version 26.4
	gc_ixcreditcardcode                  xx_ar_order_receipt_dtl.credit_card_code%TYPE; --Added new Column, Version 32.0
	gc_ixwallet_type                     xx_ar_order_receipt_dtl.wallet_type%TYPE;      --Added new column, Version 33.0
	gc_ixwallet_id                       xx_ar_order_receipt_dtl.wallet_id%type;	    --Added new column, Version 33.0
	gc_cc_auth_ps2000					 xx_ar_order_receipt_dtl.CC_AUTH_PS2000%Type;	--Version 35.0
	gc_oapforder_id                      VARCHAR2(50);
	gc_oapfstoreid                       VARCHAR2(50);
	gn_order_payment_id                  xx_ar_order_receipt_dtl.order_payment_id%TYPE;
	gc_bank_account_num                  iby_creditcard.ccnumber%TYPE;   --R12
	gc_identifier                        oe_payments.attribute5%TYPE;   --R12
	gc_bank_account_num_org              iby_creditcard.ccnumber%TYPE;
	gc_encrypted_cc_num                  VARCHAR2(1000);
	gc_trx_number                        ra_customer_trx_all.trx_number%TYPE;
	gc_cm_number                         ra_customer_trx_all.trx_number%TYPE;
	gn_order_number                      oe_order_headers_all.order_number%TYPE;
	gc_sales_order_trans_type            ra_customer_trx_all.interface_header_attribute2%TYPE;
	gc_sales_order_trans_type_desc       xx_fin_translatevalues.target_value1%TYPE;
	gc_receipt_number                    ar_cash_receipts_all.receipt_number%TYPE;
	gn_receipt_amount                    ar_cash_receipts_all.amount%TYPE;
	gc_receipt_currency                  ar_cash_receipts_all.currency_code%TYPE;
	gc_cc_exp_date                       iby_creditcard.inactive_date%TYPE;
	gc_recp_attr_category                ar_cash_receipts_all.attribute_category%TYPE;
	gc_voice_auth                        ar_cash_receipts_all.attribute3%TYPE;
	gc_approval_code                     iby_trxn_core.authcode%TYPE;
	gn_customer_trx_id                   ra_customer_trx_all.customer_trx_id%TYPE;
	gn_bill_to_customer_id               ra_customer_trx_all.bill_to_customer_id%TYPE;
	gn_ship_to_customer_id               ra_customer_trx_all.ship_to_customer_id%TYPE;
	gn_bill_to_contact_id                ra_customer_trx_all.bill_to_contact_id%TYPE;
	gn_ship_to_contact_id                ra_customer_trx_all.ship_to_contact_id%TYPE;
	gn_bill_to_site_use_id               ra_customer_trx_all.bill_to_site_use_id%TYPE;
	gn_ship_to_site_use_id               ra_customer_trx_all.ship_to_site_use_id%TYPE;
	gn_order_header_id                   oe_order_headers_all.header_id%TYPE;
	gc_customer_number                   hz_cust_accounts.account_number%TYPE;
	gc_cc_encrypt_error_message          VARCHAR2(4000);
	gn_org_id                            ra_customer_trx_all.org_id%TYPE;
	gc_org_name                          hr_all_organization_units.NAME%TYPE;
	gc_ou_us_desc                        xx_fin_translatevalues.source_value1%TYPE;
	gc_ou_ca_desc                        xx_fin_translatevalues.source_value1%TYPE;
	gc_source                            VARCHAR2(25);
	gn_master_org_id                     hr_all_organization_units.organization_id%TYPE;
	gn_ship_from_org_id                  hr_all_organization_units.organization_id%TYPE;
	gc_merchant_id                       ar_cash_receipts_all.attribute5%TYPE;
	gc_store                             ar_cash_receipts_all.attribute1%TYPE;
	gc_shiploc                           ar_cash_receipts_all.attribute2%TYPE;
	gc_sa_payment_source                 ar_cash_receipts_all.attribute11%TYPE;
	gn_ref_receipt_id                    ar_cash_receipts_all.cash_receipt_id%TYPE;
	gc_error_loc                         VARCHAR2(4000);
	gc_error_debug                       VARCHAR2(4000);
	gc_credit_card_vendor                VARCHAR2(500);
	gc_customer_name                     hz_parties.party_name%TYPE;
	gn_trxnmid                           iby_trxn_summaries_all.trxnmid%TYPE;
	gn_err_insert_flag                   NUMBER;
	gn_err_insert_det_flag               NUMBER;
	gc_net_data                          ar_cash_receipts_all.attribute4%TYPE;
	gc_payment_server_id                 ar_cash_receipts_all.payment_server_order_num%TYPE;
	gn_cash_receipt_id                   ar_cash_receipts_all.cash_receipt_id%TYPE;
	gc_cust_orig_system_ref              hz_cust_accounts.orig_system_reference%TYPE;
	gc_cust_po_number                    oe_order_headers_all.cust_po_number%TYPE;
	gn_insert_mult_inv                   NUMBER;
	gn_amex_except1                      NUMBER;
	gn_amex_except2                      NUMBER;
	gn_amex_except3                      NUMBER;
	gn_amex_except4                      NUMBER;
	gn_amex_except5                      NUMBER;
	gn_amex_except6                      NUMBER;
	gn_amex_except7                      NUMBER;
	gn_amex_except11                      NUMBER;
	gn_amex_except12                      NUMBER;
	gn_amex_except13                      NUMBER;
	gn_amex_except15		      NUMBER;
	gb_is_deposit_receipt                BOOLEAN;
	gc_is_deposit_return                 BOOLEAN;
	gc_transaction_number                xx_om_legacy_deposits.transaction_number%TYPE;
	gc_deposit_store_location            xx_om_legacy_deposits.store_location%TYPE;
	gc_application_ref_num               ar_receivable_applications_all.application_ref_num%TYPE;
	gc_inv_flag                          VARCHAR2(1);
	gc_orig_sys_document_ref             xx_om_legacy_deposits.orig_sys_document_ref%TYPE;
	gc_orig_sys_document_ref_dep         xx_om_legacy_deposits.orig_sys_document_ref%TYPE;
	gn_amex_cpc                          NUMBER;
	gc_ixinstrsubtype                    VARCHAR2(255);
	gc_cm_customer_trx_id                ar_receivable_applications_all.attribute12%TYPE;
	gc_cust_trx_type                     ra_cust_trx_types_all.TYPE%TYPE;
	gc_amex_cc                           xx_fin_translatevalues.target_value1%TYPE;
	gc_amex_merchant_number              xx_fin_translatevalues.source_value3%TYPE;
	gn_receipt_method_id                 ar_cash_receipts_all.receipt_method_id%TYPE;
	gc_recp_method_name                  ar_receipt_methods.NAME%TYPE;
	gc_pos_aops_storeid                  xx_fin_translatevalues.target_value1%TYPE;
	gc_pos_aops_recp_method              xx_fin_translatevalues.target_value1%TYPE;
	gc_pos_aops_register                 xx_fin_translatevalues.target_value1%TYPE;
	gn_pay_from_customer                 ar_cash_receipts_all.pay_from_customer%TYPE;
	gn_det_line_count                    NUMBER;
	gn_customer_site_use_id              ar_cash_receipts_all.customer_site_use_id%TYPE;
	gc_cvv_resp_code                     xx_ar_cash_receipts_ext.cvv_resp_code%TYPE;
	gc_avs_resp_code                     xx_ar_cash_receipts_ext.avs_resp_code%TYPE;
	gc_auth_entry_mode                   xx_ar_cash_receipts_ext.auth_entry_mode%TYPE;
	gc_cc_entry_mode                     xx_ar_cash_receipts_ext.cc_entry_mode%TYPE;
	gc_aops_auth_entry                   xx_fin_translatevalues.target_value1%TYPE;
	gc_pos_auth_entry                    xx_fin_translatevalues.target_value2%TYPE;
	gn_cc_entry_count                    NUMBER;
	gc_mo_value                          xx_fin_translatevalues.source_value1%TYPE;
	gc_cvv_resp_value                    xx_fin_translatevalues.source_value2%TYPE;
	gc_avs_resp_value                    xx_fin_translatevalues.source_value3%TYPE;
	gc_cardlevel_value                   xx_fin_translatevalues.source_value4%TYPE;
	gc_contactless_value                 xx_fin_translatevalues.source_value5%TYPE;
	gc_referral_value                    xx_fin_translatevalues.source_value6%TYPE;
	gc_auth_entry_val_c                  xx_fin_translatevalues.source_value3%TYPE;
	gc_credit_card_type                  ar_cash_receipts_all.attribute11%TYPE;
	gc_card_name                         xx_fin_translatevalues.target_value1%TYPE;
	gc_master_auth_source                xx_fin_translatevalues.source_value7%TYPE;
	gc_visa_auth_source                  xx_fin_translatevalues.source_value8%TYPE;
	gc_fiegd_sep                         VARCHAR(10);
	gc_aci_indicator                     VARCHAR2(1);
	gc_banknetdate                       VARCHAR2(4);
	gc_banknetreference                  VARCHAR2(9);
	gc_authorization_source              VARCHAR2(1);
	gc_transaction_identifier            VARCHAR2(15);
	gc_validation_code                   VARCHAR2(4);
	gc_visa_53                           xx_iby_batch_trxns.ixreserved53%TYPE;
	gc_ixtransnumber                     ra_customer_trx_all.trx_number%TYPE;
	gc_ixrecptnumber                     ar_cash_receipts_all.receipt_number%TYPE;
	gc_ixtotsalestaxamt_order            xx_iby_batch_trxns.ixtotalsalestaxamount%TYPE;
	gc_ixtotsalestaxamt_return           xx_iby_batch_trxns.ixtotalsalestaxamount%TYPE;
	gc_ixtaxableamount_order             xx_iby_batch_trxns.ixtaxableamount%TYPE;
	gc_ixtaxableamount_return            xx_iby_batch_trxns.ixtaxableamount%TYPE;
	gc_totsalestaxamount                 xx_iby_batch_trxns.ixtotalsalestaxamount%TYPE;
	gn_state_tax_amount_act              ra_customer_trx_lines_all.extended_amount%TYPE;
	gn_other_tax_amount_act              ra_customer_trx_lines_all.extended_amount%TYPE;
	gn_state_tax_amount                  ra_customer_trx_lines_all.extended_amount%TYPE;
	gn_other_tax_amount                  ra_customer_trx_lines_all.extended_amount%TYPE;
	gc_is_amex                           xx_iby_batch_trxns.is_amex%TYPE;
	gc_is_deposit                        xx_iby_batch_trxns.is_deposit%TYPE;
	gn_process_indicator                 xx_iby_batch_trxns.process_indicator%TYPE;
	gc_aops_dep_shipto_zipcode           xx_iby_deposit_aops_order_dtls.attribute1%TYPE;
	gc_aops_dep_shipto_state             xx_iby_deposit_aops_order_dtls.attribute2%TYPE;
	gn_cust_account_id                   hz_cust_accounts_all.cust_account_id%TYPE;
	gc_customernumber                    hz_cust_accounts.account_number%TYPE;
	gc_po_override_set                   xxcdh_cust_override_fl_v.po_override_settlements%TYPE;
	gc_cust_code_override                xxcdh_cust_override_fl_v.cust_code_override%TYPE;
	gc_sec_po_override                   xxcdh_cust_override_fl_v.secondary_po%TYPE; --26.5
	gn_mc_except9                        NUMBER;
	gn_other_cust_exp                    NUMBER;
	gc_other_cust                        xx_fin_translatevalues.source_value1%TYPE;
	gc_key_label                         xx_iby_batch_trxns.attribute8%TYPE;
	gc_order_type                        VARCHAR2(25);
	gc_invoice_type                      VARCHAR2(25);
	gc_sale_type                         xx_ar_order_receipt_dtl.sale_type%TYPE;
	gc_order_source                      xx_ar_order_receipt_dtl.order_source%TYPE;
	gc_additional_auth_codes             xx_ar_order_receipt_dtl.additional_auth_codes%TYPE;
	gc_debug                             xx_fin_translatevalues.target_value1%TYPE;
	gc_debug_file                        xx_fin_translatevalues.target_value1%TYPE;
	gc_ccrefund_flag                     xx_iby_batch_trxns.attribute2%TYPE;
	gc_single_pay_ind                    xx_ar_order_receipt_dtl.single_pay_ind%TYPE;
	gc_internal_cust_flag                VARCHAR2(1)                                               := 'N';
	gc_is_custom_refund                  xx_iby_batch_trxns.is_custom_refund%TYPE;
	-- Counters and Flags for Settlement Records Created
	gb_101_created                       BOOLEAN;
	gb_201_created                       BOOLEAN;
	-- Program Information
	gc_program_name                      xx_com_error_log.program_name%TYPE;
	gc_program_type                      xx_com_error_log.program_type%TYPE;
	gc_object_id                         xx_com_error_log.object_id%TYPE;
	gc_object_type                       xx_com_error_log.object_type%TYPE;
	gn_request_id                        fnd_concurrent_requests.request_id%TYPE;
	gn_user_id                           fnd_concurrent_requests.requested_by%TYPE;
	-- Retrieval Status
	gc_invoice_retrieval_status          VARCHAR2(25);
	gc_order_retrieval_status            VARCHAR2(25);
	gc_deposit_retrieval_status          VARCHAR2(25);
	gc_spmo_retrieval_status             VARCHAR2(25);
	gc_remit_processing_type             VARCHAR2(100);
	gn_seq_number                        NUMBER;   -- Added per Defect 13812
	gc_tokenization                      VARCHAR2(50) := '*Tokenization';
-------------------------------------
-- Global Exceptions
-------------------------------------
	ex_debug_setting                     EXCEPTION;
	ex_invalid_sale_type                 EXCEPTION;
	ex_receipt_type                      EXCEPTION;
	ex_cc_encrytpt                       EXCEPTION;
	ex_cc_decrytpt                       EXCEPTION;
	ex_raise_cc_decrytpt                 EXCEPTION;
	ex_pre2                              EXCEPTION;
	ex_no_cm                             EXCEPTION;
	ex_cm_null                           EXCEPTION;
	ex_no_receipt_info                   EXCEPTION;
	ex_no_order_info                     EXCEPTION;
	ex_no_deposit_info                   EXCEPTION;
	ex_too_many_receipts                 EXCEPTION;
	ex_too_many_invoices                 EXCEPTION;
	ex_too_many_orders                   EXCEPTION;
	ex_too_many_deposits                 EXCEPTION;
	ex_mandatory_fields                  EXCEPTION;
	ex_101_201_creation_error            EXCEPTION;
	ex_corrupt_intstore                  EXCEPTION;
	ex_receipt_remitted                  EXCEPTION;

	TYPE gt_input_parameters IS TABLE OF VARCHAR2(255)
		INDEX BY VARCHAR2(60);

	/***********************************************
	*  Setter procedure for gb_debug global variable
	*  used for controlling debugging
	***********************************************/
	PROCEDURE set_debug(
		p_debug_flag  IN  VARCHAR2)
	IS
	BEGIN
		IF (UPPER(p_debug_flag) IN('Y', 'YES', 'T', 'TRUE') )
		THEN
			g_debug := TRUE;
		END IF;
	END set_debug;

	/*********************************************************************
	* Procedure used to log based on gb_debug value or if p_force is TRUE.
	* Will log to dbms_output if request id is not set,
	* else will log to concurrent program log file.  Will prepend
	* timestamp to each message logged.  This is useful for determining
	* elapse times.
	*********************************************************************/
	PROCEDURE logit(
		p_message  IN  VARCHAR2,
		p_force    IN  BOOLEAN DEFAULT FALSE)
	IS
		lc_message  VARCHAR2(2000) := NULL;
	BEGIN
		--if debug is on (defaults to true)
		IF (   g_debug
			OR p_force)
		THEN
			lc_message :=
				SUBSTR(   TO_CHAR(SYSTIMESTAMP,
								  'MM/DD/YYYY HH24:MI:SS.FF')
					   || ' => '
					   || p_message,
					   1,
					   g_max_error_message_length);

			-- if in concurrent program, print to log file
			IF (fnd_global.conc_request_id > 0)
			THEN
				fnd_file.put_line(fnd_file.LOG,
								  lc_message);
			-- else print to DBMS_OUTPUT
			ELSE
				DBMS_OUTPUT.put_line(lc_message);
			END IF;
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			NULL;
	END logit;

	/**********************************************************************
	* Helper procedure to log the sub procedure/function name that has been
	* called and logs the input parameters passed to it.
	***********************************************************************/
	PROCEDURE entering_sub(
		p_procedure_name  IN  VARCHAR2,
		p_parameters      IN  gt_input_parameters)
	AS
		ln_counter            NUMBER        := 0;
		lc_current_parameter  VARCHAR2(255) := NULL;
	BEGIN
		IF g_debug
		THEN
			logit(p_message =>      '-----------------------------------------------');
			logit(p_message =>         'Entering: '
									|| p_procedure_name);
			lc_current_parameter := p_parameters.FIRST;

			IF p_parameters.COUNT > 0
			THEN
				logit(p_message =>      'Input parameters:');

				LOOP
					EXIT WHEN lc_current_parameter IS NULL;
					ln_counter :=   ln_counter
								  + 1;
					logit(p_message =>         ln_counter
											|| '. '
											|| lc_current_parameter
											|| ' => '
											|| p_parameters(lc_current_parameter) );
					lc_current_parameter := p_parameters.NEXT(lc_current_parameter);
				END LOOP;
			END IF;
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			NULL;
	END entering_sub;

	/******************************************************************
	* Helper procedure to log that the main procedure/function has been
	* called. Sets the debug flag and calls entering_sub so that
	* it logs the procedure name and the input parameters passed in.
	******************************************************************/
	PROCEDURE entering_main(
		p_procedure_name   IN  VARCHAR2,
		p_rice_identifier  IN  VARCHAR2,
		p_debug_flag       IN  VARCHAR2,
		p_parameters       IN  gt_input_parameters)
	AS
	BEGIN
		set_debug(p_debug_flag =>      p_debug_flag);

		IF g_debug
		THEN
			IF p_rice_identifier IS NOT NULL
			THEN
				logit(p_message =>      '-----------------------------------------------');
				logit(p_message =>      '-----------------------------------------------');
				logit(p_message =>         'RICE ID: '
										|| p_rice_identifier);
				logit(p_message =>      '-----------------------------------------------');
				logit(p_message =>      '-----------------------------------------------');
			END IF;

			entering_sub(p_procedure_name =>      p_procedure_name,
						 p_parameters =>          p_parameters);
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			NULL;
	END entering_main;

	/****************************************************************
	* Helper procedure to log the exiting of a subprocedure.
	* This is useful for debugging and for tracking how long a given
	* procedure is taking.
	****************************************************************/
	PROCEDURE exiting_sub(
		p_procedure_name  IN  VARCHAR2,
		p_exception_flag  IN  BOOLEAN DEFAULT FALSE)
	AS
	BEGIN
		IF g_debug
		THEN
			IF p_exception_flag
			THEN
				logit(p_message =>         'Exiting Exception: '
										|| p_procedure_name);
			ELSE
				logit(p_message =>         'Exiting: '
										|| p_procedure_name);
			END IF;

			logit(p_message =>      '-----------------------------------------------');
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			NULL;
	END exiting_sub;

-- +===================================================================+
-- | PROCEDURE  : XX_LOCATION_AND_LOG                                  |
-- |                                                                   |
-- | DESCRIPTION: Performs the following actions based on parameters   |
-- |              1. Sets gc_error_location                            |
-- |              2. Writes to log file using UTL_FILE to log messages |
-- |                 due to limitation of  Automatic Remittance        |
-- |                                                                   |
-- | PARAMETERS : p_action_type, p_debug_msg                           |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+
	PROCEDURE xx_location_and_log(
		p_action_type  IN  VARCHAR2,
		p_debug_msg    IN  VARCHAR2)
	IS
		lf_out_file    UTL_FILE.file_type;
		ln_chunk_size  BINARY_INTEGER     := 32767;
	BEGIN

		IF p_action_type = g_loc
		THEN
			gc_error_loc := p_debug_msg;   -- set error location
		END IF;

		-- Write Debug information for execution from concurrent request

	   -- Added by ag

	   /*lf_out_file := UTL_FILE.fopen('XXFIN_OUTBOUND',
									 gc_debug_file,
									'a',
									ln_chunk_size);

		UTL_FILE.put_line(lf_out_file,
							'     '
						  || p_debug_msg);

		UTL_FILE.fclose(lf_out_file);*/

		IF (gc_debug = 'Y')
		THEN
			IF gn_request_id = -1
			THEN
				-- Write Debug information for execution from ad-hoc SQL
				DBMS_OUTPUT.ENABLE;

				IF p_action_type = g_log
				THEN
					DBMS_OUTPUT.put_line(   '     '
										 || p_debug_msg);
				ELSE
					DBMS_OUTPUT.put_line(' ');
					DBMS_OUTPUT.put_line(p_debug_msg);
					DBMS_OUTPUT.put_line(' ');
				END IF;
			ELSE
				-- Write Debug information for execution from concurrent request
				lf_out_file := UTL_FILE.fopen('XXFIN_OUTBOUND',
											  gc_debug_file,
											  'a',
											  ln_chunk_size);

				IF p_action_type = g_log
				THEN
					UTL_FILE.put_line(lf_out_file,
										 '     '
									  || p_debug_msg);
				ELSE
					UTL_FILE.put_line(lf_out_file,
									  ' ');
					UTL_FILE.put_line(lf_out_file,
									  p_debug_msg);
					UTL_FILE.put_line(lf_out_file,
									  ' ');
				END IF;

				UTL_FILE.fclose(lf_out_file);
			END IF;
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			gc_error_loc := 'Entering WHEN OTHERS exception of XX_DISPLAY_LOG. ';
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
	END xx_location_and_log;

-- +===================================================================+
-- | FUNCTION   : XX_CHECK_DEBUG_SETTINGS                              |
-- |                                                                   |
-- | DESCRIPTION: Checks debug setting and enables based on setting    |
-- |                                                                   |
-- | PARAMETERS : NONE                                                 |
-- |                                                                   |
-- | RETURNS    : BOOLEAN (Success of checking/validating              |
-- +===================================================================+
	FUNCTION xx_check_debug_settings
		RETURN BOOLEAN
	IS
		lb_log_file_path_derived  BOOLEAN;
		lb_debug_flag_derived     BOOLEAN;
	BEGIN
		gc_error_loc := 'Set Program Type, Object ID, and Object Type for debug. ';

		IF gc_oapforder_id IS NOT NULL
		THEN
			gc_program_type := 'Settlement Staging from Automatic Remittance';
			gc_object_id := gc_oapforder_id;
			gc_object_type := 'oapforder_id';
		ELSIF gn_order_payment_id IS NOT NULL
		THEN
			gc_program_type := 'Settlement Staging from OM/HVOP or CCREFUND';
			gc_object_id := gn_order_payment_id;
			gc_object_type := 'order_payment_id';
		END IF;

		gc_error_loc := 'Derive Debug Flag from FTP_DETAILS_AJB Translation Definition. ';

		SELECT NVL(xftv.target_value1,
				   'N')
		INTO   gc_debug
		FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
		WHERE  xftd.translate_id = xftv.translate_id
		AND    xftd.translation_name = 'FTP_DETAILS_AJB'
		AND    xftv.source_value1 = 'Debug_Flag'
		AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																SYSDATE
															  + 1)
		AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																SYSDATE
															  + 1)
		AND    xftv.enabled_flag = 'Y'
		AND    xftd.enabled_flag = 'Y';

		lb_debug_flag_derived := TRUE;
		gc_error_loc := 'Checking Value of GC_DEBUG flag ';
		gc_error_debug :=    'GC_DEBUG: '
						  || gc_debug;

		IF (gc_debug = 'Y')
		THEN
			BEGIN
				gc_error_loc :=
							 'Selecting the Log File from Profile Option from FTP_DETAILS_AJB Translation Definition. ';

				SELECT LTRIM(SUBSTR(xftv.target_value1,
									INSTR(xftv.target_value1,
										  '/',
										  -1) ),
							 '/')
				INTO   gc_debug_file
				FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
				WHERE  xftd.translate_id = xftv.translate_id
				AND    xftd.translation_name = 'FTP_DETAILS_AJB'
				AND    xftv.source_value1 = 'Debug_Path'
				AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																		SYSDATE
																	  + 1)
				AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																		SYSDATE
																	  + 1)
				AND    xftv.enabled_flag = 'Y'
				AND    xftd.enabled_flag = 'Y';

				lb_log_file_path_derived := TRUE;
			EXCEPTION
				WHEN OTHERS
				THEN
					gc_error_loc := 'Entering WHEN OTHERS Exception in XX_CHECK_DEBUG_SETTINGS (GC_DEBUG = Y). ';
					lb_log_file_path_derived := FALSE;
					xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
												   p_program_name =>                gc_program_name,
												   p_program_id =>                  NULL,
												   p_module_name =>                 'IBY',
												   p_error_message_count =>         1,
												   p_error_message_code =>          'E',
												   p_error_message =>                  'Error at: '
																					|| gc_error_loc
																					|| 'Debug: '
																					|| gc_error_debug
																					|| ' - '
																					|| SQLERRM,
												   p_error_message_severity =>      'Minor',
												   p_notify_flag =>                 'N',
												   p_object_type =>                 gc_object_type,
												   p_object_id =>                   gc_object_id);
			END;
		ELSE
			lb_log_file_path_derived := TRUE;   -- since gc_debug <> 'Y'
		END IF;

		gc_error_loc := 'Checking Debug Flag and Log File Path were derived. ';

		IF NOT(    lb_debug_flag_derived
			   AND lb_log_file_path_derived)
		THEN
			RETURN FALSE;
		ELSE
			RETURN TRUE;
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			gc_error_loc := 'Entering WHEN OTHERS Exception in XX_CHECK_DEBUG_SETTINGS. ';
			RETURN FALSE;
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>                  'Error at: '
																			|| gc_error_loc
																			|| 'Debug: '
																			|| gc_error_debug
																			|| ' - '
																			|| SQLERRM,
										   p_error_message_severity =>      'Minor',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
	END xx_check_debug_settings;

-- +====================================================================+
-- | PROCEDURE  : XX_INIT_PRIVATE_PKG_VARIABLES                         |
-- |                                                                    |
-- | DESCRIPTION: Initializes all package (private) variables           |
   -- |                                                                 |
-- | PARAMETERS : None                                                  |
-- |                                                                    |
-- | RETURNS    : None                                                  |
-- +====================================================================+
	PROCEDURE xx_init_private_pkg_variables
	IS
	BEGIN
		gc_pre2 := NULL;
		gc_ixreserved7 := NULL;
		gc_ixstorenumber := NULL;
		gc_ixregisternumber := NULL;
		gc_ixtransactiontype := NULL;
		gc_ixreserved31 := NULL;
		gc_ixreserved32 := NULL;
		gc_ixreserved33 := NULL;   --Added, Version 26.3
		gc_ixreserved39 := NULL;   --Added, Version 26.5
		gc_ixreserved43 := NULL;
		gc_ixreserved53 := NULL;
		gc_ixreserved56 := NULL;   --Added, Version 27.0
		gc_ixexpdate := NULL;
		gc_ixswipe := NULL;
		gc_ixamount := NULL;
		gc_ixreserved20 := NULL; --Added for NAIT-131811
		gc_ixinvoice := NULL;
		gc_ixoptions := NULL;
		gc_ixbankuserdata := NULL;
		gc_ixissuenumber := NULL;
		gc_ixtotalsalestaxamount := '0';
		gc_ixtotalsalestaxcollind := '0';
		gc_ixreceiptnumber := NULL;
		gc_ixauthorizationnumber := NULL;
		gc_ixps2000 := NULL;
		gc_ixreference := NULL;
		gc_ixdate := NULL;
		gc_ixtime := '000000';
		gc_ixcustomerreferenceid := NULL;
		gc_ixnationaltaxcollindicator := NULL;
		gc_ixnationaltaxamount := '0';
		gc_ixothertaxamount := '0';
		gc_ixdiscountamount := '0';
		gc_ixshippingamount := '0';
		gc_ixtaxableamount := '0';
		gc_tot_order_amount := '0';
		gc_ixdutyamount := '0';
		gc_ixshipfromzipcode := NULL;
		gc_ixshiptocompany := NULL;
		gc_ixshiptoname := NULL;
		gc_ixshiptostreet := NULL;
		gc_ixshiptocity := NULL;
		gc_ixshiptostate := NULL;
		gc_ixshiptocountry := NULL;
		gc_ixshiptozipcode := NULL;
		gc_ixpurchasername := NULL;
		gc_ixcustaccountno := NULL;
		gc_ixorderdate := NULL;
		gc_ixmerchantvatnumber := NULL;
		gc_ixcustomervatnumber := NULL;
		gc_ixvatamount := '0';
		gc_ixmerchandiseshipped := 'N';
		gc_ixcustcountrycode := NULL;
		gc_ixcostcenter := NULL;
		gc_ixdesktoplocation := NULL;
		gc_ixreleasenumber := NULL;
		gc_ixoriginalinvoiceno := NULL;
		gc_orig_invoice_num := NULL;
		gc_ixothertaxamount2 := '0';
		gc_ixothertaxamount3 := '0';
		gc_ixmisccharge := NULL;
		gc_ixaccount := NULL;
		gc_ixccnumber := NULL;
		gc_ixtokenflag := NULL;         --Version 26.3
		gc_ixcreditcardcode := NULL;    --Version 32.0
		gc_ixwallet_type := NULL;       --Version 33.0
		gc_ixwallet_id 	 := NULL;       --Version 33.0
		gc_oapforder_id := NULL;
		gc_oapfstoreid := NULL;
		gn_order_payment_id := NULL;
		gc_cc_auth_ps2000 := NULL;		--Version 35.0
		gc_bank_account_num := NULL;
		gc_identifier := NULL;
		gc_bank_account_num_org := NULL;
		gc_encrypted_cc_num := NULL;
		gc_trx_number := NULL;
		gc_cm_number := NULL;
		gn_order_number := NULL;
		gc_sales_order_trans_type := NULL;
		gc_sales_order_trans_type_desc := NULL;
		gc_receipt_number := NULL;
		gn_receipt_amount := NULL;
		gc_receipt_currency := NULL;
		gc_cc_exp_date := NULL;
		gc_recp_attr_category := NULL;
		gc_voice_auth := NULL;
		gc_approval_code := NULL;
		gn_customer_trx_id := NULL;
		gn_bill_to_customer_id := NULL;
		gn_ship_to_customer_id := NULL;
		gn_bill_to_contact_id := NULL;
		gn_ship_to_contact_id := NULL;
		gn_bill_to_site_use_id := NULL;
		gn_ship_to_site_use_id := NULL;
		gn_order_header_id := NULL;
		gc_customer_number := NULL;
		gc_cc_encrypt_error_message := NULL;
		gn_org_id := NULL;
		gc_org_name := NULL;
		gc_ou_us_desc := NULL;
		gc_ou_ca_desc := NULL;
		gc_source := NULL;
		gn_master_org_id := NULL;
		gn_ship_from_org_id := NULL;
		gc_merchant_id := NULL;
		gc_store := NULL;
		gc_shiploc := NULL;
		gc_sa_payment_source := NULL;

		gn_ref_receipt_id := NULL;
		gc_error_loc := NULL;
		gc_error_debug := NULL;
		gc_credit_card_vendor := NULL;
		gc_customer_name := NULL;
		gn_trxnmid := NULL;
		gn_err_insert_flag := 0;
		gn_err_insert_det_flag := 0;
		gc_net_data := NULL;
		gc_payment_server_id := NULL;
		gn_cash_receipt_id := NULL;
		gc_cust_orig_system_ref := NULL;
		gc_cust_po_number := NULL;
		gn_insert_mult_inv := 0;
		gn_amex_except1 := 0;
		gn_amex_except2 := 0;
		gn_amex_except3 := 0;
		gn_amex_except4 := 0;
		gn_amex_except5 := 0;
		gn_amex_except6 := 0;
		gn_amex_except7 := 0;
		gn_amex_except11 := 0;
		gn_amex_except12 := 0;
		gn_amex_except13 := 0;
		gn_amex_except15 := 0;
		gb_is_deposit_receipt := FALSE;
		gc_is_deposit_return := FALSE;
		gc_transaction_number := NULL;
		gc_deposit_store_location := NULL;
		gc_application_ref_num := NULL;
		gc_inv_flag := NULL;
		gc_orig_sys_document_ref := NULL;
		gc_orig_sys_document_ref_dep := NULL;
		gn_amex_cpc := 0;
		gc_ixinstrsubtype := NULL;
		gc_cm_customer_trx_id := NULL;
		gc_cust_trx_type := NULL;
		gc_amex_cc := NULL;
		gc_amex_merchant_number := NULL;
		gn_receipt_method_id := NULL;
		gc_recp_method_name := NULL;
		gc_pos_aops_storeid := NULL;
		gc_pos_aops_recp_method := NULL;
		gc_pos_aops_register := NULL;
		gn_pay_from_customer := NULL;
		gn_det_line_count := 0;
		gn_customer_site_use_id := NULL;
		gc_cvv_resp_code := NULL;
		gc_avs_resp_code := NULL;
		gc_auth_entry_mode := NULL;
		gc_cc_entry_mode := NULL;
		gc_aops_auth_entry := NULL;
		gc_pos_auth_entry := NULL;
		gn_cc_entry_count := 0;
		gc_mo_value := NULL;
		gc_cvv_resp_value := NULL;
		gc_avs_resp_value := NULL;
		gc_cardlevel_value := NULL;
		gc_contactless_value := NULL;
		gc_referral_value := NULL;
		gc_auth_entry_val_c := NULL;
		gc_credit_card_type := NULL;
		gc_card_name := NULL;
		gc_master_auth_source := NULL;
		gc_visa_auth_source := NULL;
		gc_fiegd_sep := NULL;
		gc_aci_indicator := NULL;
		gc_banknetdate := NULL;
		gc_banknetreference := NULL;
		gc_authorization_source := NULL;
		gc_transaction_identifier := NULL;
		gc_validation_code := NULL;
		gc_visa_53 := NULL;
		gc_ixtransnumber := NULL;
		gc_ixrecptnumber := NULL;
		gc_ixtotsalestaxamt_order := '0';
		gc_ixtotsalestaxamt_return := '0';
		gc_ixtaxableamount_order := '0';
		gc_ixtaxableamount_return := '0';
		gc_totsalestaxamount := '0';
		gn_state_tax_amount_act := '0';
		gn_other_tax_amount_act := '0';
		gn_state_tax_amount := '0';
		gn_other_tax_amount := '0';
		gc_is_amex := 'N';
		gc_is_deposit := 'N';
		gn_process_indicator := NULL;
		gc_aops_dep_shipto_zipcode := NULL;
		gc_aops_dep_shipto_state := NULL;
		gn_cust_account_id := NULL;
		gc_customernumber := NULL;
		gc_po_override_set := NULL;
		gc_cust_code_override := NULL;
		gc_sec_po_override := NULL; --26.5
		gn_mc_except9 := 0;
		gn_other_cust_exp := 0;
		gc_other_cust := NULL;
		gc_key_label := NULL;
		gc_order_type := NULL;
		gc_invoice_type := NULL;
		gc_sale_type := NULL;
		gc_order_source := NULL;
		gc_additional_auth_codes := NULL;
		gc_ccrefund_flag := 'N';
		gc_single_pay_ind := 'N';
		gc_internal_cust_flag := 'N';
		gc_is_custom_refund := 'N';
		gb_101_created := FALSE;
		gb_201_created := FALSE;
		gc_program_name := 'XX_STG_RECEIPT_FOR_SETTLEMENT';
		gc_program_type := NULL;
		gc_object_id := NULL;
		gc_object_type := NULL;
		gc_invoice_retrieval_status := g_zero;
		gc_order_retrieval_status := g_zero;
		gc_deposit_retrieval_status := g_zero;
		gc_spmo_retrieval_status := g_zero;
		gc_remit_processing_type := NULL;
	END xx_init_private_pkg_variables;

-- +===================================================================+
-- | FUNCTION   : XX_EXPLODE_ADDL_AUTH_CODES                           |
-- |                                                                   |
-- | DESCRIPTION: Generic function that is used to separate a delimited|
-- |              string into an array of string values                |
-- |                                                                   |
-- | PARAMETERS : STRINGARRAY and delimiter                            |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+
	FUNCTION xx_explode_addl_auth_codes(
		p_string     IN  VARCHAR2,
		p_delimiter  IN  VARCHAR2)
		RETURN stringarray
	IS
		ln_index       NUMBER      DEFAULT 0;
		ln_pos         NUMBER      DEFAULT 0;
		ln_hold_pos    NUMBER      DEFAULT 1;
		la_return_tab  stringarray DEFAULT stringarray();
	BEGIN
		xx_location_and_log(g_loc,
							'***** Executing XX_EXPLODE_ADDL_AUTH_CODE ***** ');

		LOOP
			ln_pos := INSTR(p_string,
							p_delimiter,
							ln_hold_pos);

			IF ln_pos > 0
			THEN
				la_return_tab.EXTEND;
				ln_index :=   ln_index
							+ 1;
				la_return_tab(ln_index) := LTRIM(SUBSTR(p_string,
														ln_hold_pos,
														  ln_pos
														- ln_hold_pos) );
			ELSE
				la_return_tab.EXTEND;
				ln_index :=   ln_index
							+ 1;
				la_return_tab(ln_index) := LTRIM(SUBSTR(p_string,
														ln_hold_pos) );
				EXIT;
			END IF;

			ln_hold_pos :=   ln_pos
						   + 1;
		END LOOP;

		RETURN la_return_tab;
	END xx_explode_addl_auth_codes;

-- +===================================================================+
-- | PROCEDURE  : XX_SET_REMITTED_TO_ERROR                             |
-- |                                                                   |
-- | DESCRIPTION: Procedure sets REMITTED to 'E' for a given           |
-- |              settlement records in xx_ar_order_receipt_dtl table. |
-- |              This is performed via an Autonomous Transaction      |
-- |                                                                   |
-- | PARAMETERS : p_order_payment_id                                   |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+
	PROCEDURE xx_set_remitted_to_error(
		p_order_payment_id  IN  NUMBER,
		p_error_message     IN  VARCHAR2)
	IS
		PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
		IF p_order_payment_id IS NOT NULL
		THEN
			xx_location_and_log(g_loc,
								'Updating REMITTED to E');

			UPDATE xx_ar_order_receipt_dtl
			SET remitted = 'E',
				settlement_error_message = SUBSTR(p_error_message,
												  1,
												  2000)
			WHERE  order_payment_id = p_order_payment_id;

			COMMIT;
		ELSE
			xx_location_and_log(g_loc,
								'NULL was passed into XX_SET_REMITTED_TO_ERROR. ');
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			xx_location_and_log
				(g_loc,
				 'Entering WHEN OTHERS Exception - Unable to set remittance status to E (ERROR) using XX_SET_REMITTED_TO_ERROR. ');
			xx_location_and_log(g_loc,
								   'XX_SET_REMITTED_TO_ERROR Error at: '
								|| gc_error_loc
								|| 'Debug: '
								|| gc_error_debug
								|| ' - '
								|| SQLERRM);
	END xx_set_remitted_to_error;

-- +===================================================================+
-- | PROCEDURE  : decrypt_credit_card                                           |
-- |                                                                   |
-- | DESCRIPTION: Decrypt the credit card
-- |                                                                   |
-- | PARAMETERS : p_credit_card_number_enc                         |
-- ||             p_identifier                                         |
-- |              x_credit_card_number_dec                         |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+
	PROCEDURE decrypt_credit_card(
		p_credit_card_number_enc  IN             oe_payments.attribute4%TYPE,
		p_identifier              IN             oe_payments.attribute5%TYPE,
		x_credit_card_number_dec  OUT NOCOPY     iby_creditcard.ccnumber%TYPE)
	IS
		lc_decrypt_error_msg  VARCHAR2(2000);
	BEGIN
		xx_location_and_log(g_loc,
							'Decrypting Credit Card.. ');
		gc_error_debug :=    'Payment Order ID: '
						  || TO_CHAR(gn_order_payment_id);
		DBMS_SESSION.set_context(namespace =>      'XX_IBY_CONTEXT',
								 ATTRIBUTE =>      'TYPE',
								 VALUE =>          'EBS');
		xx_od_security_key_pkg.decrypt(x_decrypted_val =>      x_credit_card_number_dec,
									   x_error_message =>      lc_decrypt_error_msg,
									   p_module =>             'AJB',
									   p_key_label =>          p_identifier,
									   p_algorithm =>          '3DES',
									   p_encrypted_val =>      p_credit_card_number_enc,
									   p_format =>             'BASE64');

		IF lc_decrypt_error_msg IS NOT NULL
		THEN
			xx_location_and_log(g_loc,
								   'Error in xx_od_security_key_pkg.decrypt: '
								|| lc_decrypt_error_msg);
			gc_error_loc   := 'decrypt_credit_card';
			gc_error_debug := lc_decrypt_error_msg;
			RAISE ex_raise_cc_decrytpt;	--Defect 29951
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			xx_location_and_log(g_loc,
								   'Error decrypting: '
								|| SQLERRM);
			gc_error_loc   := 'decrypt_credit_card';
			gc_error_debug := SQLERRM;
			RAISE ex_raise_cc_decrytpt;   --Defect 29951
	END decrypt_credit_card;

-- +===================================================================+
-- | PROCEDURE  : AMEX_CPC                                             |
-- |                                                                   |
-- | DESCRIPTION: To check if the Credit Card is a AMEX CPC Card. This |
-- |              is used to compare bit by bit for each value of the  |
-- |              CC Number with the Translation Low and High Value    |
-- |                                                                   |
-- | PARAMETERS : p_credit_card_number                                 |
-- |              p_amex_cpc                                           |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+
	PROCEDURE amex_cpc(
		p_credit_card_number  IN      VARCHAR2,
		p_identifier          IN      VARCHAR2,
		p_amex_cpc            OUT     NUMBER)
	IS
		CURSOR c_amex_bin_ranges
		IS
			(SELECT xftv.source_value1,
					xftv.source_value2
			 FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			 WHERE  xftd.translate_id = xftv.translate_id
			 AND    xftd.translation_name = 'AMEX_CPC_BIN_RANGES'
			 AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	 SYSDATE
																   + 1)
			 AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	 SYSDATE
																   + 1)
			 AND    xftv.enabled_flag = 'Y'
			 AND    xftd.enabled_flag = 'Y');

		ln_str_length              NUMBER;
		ln_exists                  NUMBER                         := 1;
		lc_cc_from                 VARCHAR2(1);
		lc_cc_to                   VARCHAR2(1);
		lc_cc_amex                 VARCHAR2(1);
		lc_credit_card_number_dec  iby_creditcard.ccnumber%TYPE;
	BEGIN
		xx_location_and_log
			 (g_loc,
			  'Retrieving AMEX bin ranges from AMEX_CPC_BIN_RANGES translation definition (cursor c_amex_bin_ranges). ');
		gc_error_debug :=    'Payment Order ID: '
						  || TO_CHAR(gn_order_payment_id);
		decrypt_credit_card(p_credit_card_number_enc =>      p_credit_card_number,
							p_identifier =>                  p_identifier,
							x_credit_card_number_dec =>      lc_credit_card_number_dec);

		FOR lcu_amex_bin_ranges IN c_amex_bin_ranges
		LOOP
			ln_exists := 1;
			ln_str_length := LENGTH(lcu_amex_bin_ranges.source_value1);

			FOR i IN 1 .. ln_str_length
			LOOP
				lc_cc_amex := SUBSTR(lc_credit_card_number_dec,
									 i,
									 1);
				lc_cc_from := SUBSTR(lcu_amex_bin_ranges.source_value1,
									 i,
									 1);
				lc_cc_to := SUBSTR(NVL(lcu_amex_bin_ranges.source_value2,
									   lcu_amex_bin_ranges.source_value1),
								   i,
								   1);

				IF (    (lc_cc_from = 'X')
					OR (lc_cc_amex BETWEEN lc_cc_from AND lc_cc_to) )
				THEN
					NULL;
				ELSE
					ln_exists := 0;
					p_amex_cpc := ln_exists;
					EXIT;
				END IF;
			END LOOP;

			p_amex_cpc := ln_exists;

			IF (ln_exists = 1)
			THEN
				EXIT;
			END IF;
		END LOOP;
	END amex_cpc;

--Start changes for defect 38215
	-- +===================================================================+
-- | PROCEDURE  : PROCESS_AMEX_DATA                                    |
-- |                                                                   |
-- | DESCRIPTION: Retrieve data for AMEX CPC transactions              |
-- |              Procedure added for defect 38215  - Amex to Vantiv   |
-- | PARAMETERS : p_credit_card_number                                 |
-- |              p_amex_cpc                                           |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+
	  PROCEDURE process_amex_data
	  IS
	  BEGIN
		 xx_location_and_log(g_loc,'Processing AMEX');
	 gc_error_debug :=    'PROCESS_AMEX_DATA - Credit Card Type: '
					  || gc_credit_card_type;

	 xx_location_and_log(g_loc,'Processing Data for AMEX CPC CARD. ' || gc_error_debug);
	 xx_location_and_log(g_loc,'gc_credit_card_vendor: '||gc_credit_card_vendor);
	 xx_location_and_log(g_loc,'gc_is_amex: '||gc_is_amex);

	 xx_location_and_log(g_loc,'Mapping for AMEX and AMEX CPC ');

	 IF gc_ixinvoice IS NULL
	 THEN
		   xx_location_and_log(g_loc,'ixinvoice:Default Value');
		   gc_ixinvoice := '000000000000000';
	 END IF;

	 IF gc_ixauthorizationnumber IS NULL
	 THEN
		   xx_location_and_log(g_loc,'ixauthorizationnumber:Default Value');
		   gc_ixauthorizationnumber := '00000';
	 END IF;

	 IF gc_ixreserved43 IS NULL
	 THEN
		   xx_location_and_log(g_loc,'ixreserved43:Default Value');
		   gc_ixreserved43 := '000000000000';
	 END IF;

	 xx_location_and_log(g_loc,'gn_amex_cpc: '||to_char(gn_amex_cpc));


	 -- Defect 39341 commented and added below code gc_ixccnumber := gc_ixreleasenumber;
	 gc_ixothertaxamount3 := gc_ixreleasenumber;
	 xx_location_and_log(g_loc,'ixccnumber: '||gc_ixccnumber);

		 /* sample format for ixcustcountrycode defect#38723
			  <Requester>
			<Name> 006133:BOCA RATON FL </Name>
			<State> FL </State>
			<PostalCode> 33498 </PostalCode>
			<Country> US <Country>
		 <Requester>
		 */

	 /*gc_ixcustcountrycode :=  '<ShipTo><Addr><Name>'||gc_customer_name
								  ||'</Name><PostalAddress><State>'
								  || gc_ixshiptostate || '</State><PostalCode>'
								  || gc_ixshiptozipcode || '</PostalCode></PostalAddress><Contact><Name>'
								  || NVL(gc_ixpurchasername,gc_customer_name) || '</Name>'
								  || '<PhoneNumber><Number></Number></PhoneNumber></Contact></Addr></ShipTo>';*/

	 gc_ixcustcountrycode :=  '<Requester><Name>'||gc_customer_name
								  ||'</Name><State>'
								  || gc_ixshiptostate || '</State><PostalCode>'
								  || gc_ixshiptozipcode || '</PostalCode><Country>'
								  || gc_ixshiptocountry || '</Country></Requester>';


	 xx_location_and_log(g_loc,'gc_ixcustcountrycode: '||gc_ixcustcountrycode);

		SELECT COUNT(1)
		  INTO   gn_amex_except11
		  FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
		 WHERE  xftd.translate_id = xftv.translate_id
		   AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
		   AND    xftv.source_value1 = gc_cust_orig_system_ref
		   AND    xftv.target_value1 = 'EXCEPT11'
		   AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE + 1)
		   AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE + 1)
		   AND    xftv.enabled_flag = 'Y'
		   AND    xftd.enabled_flag = 'Y';

		 xx_location_and_log(g_log,'Amex Except11             : '|| gn_amex_except11);

		SELECT COUNT(1)
		  INTO   gn_amex_except12
		  FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
		 WHERE  xftd.translate_id = xftv.translate_id
		   AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
		   AND    xftv.source_value1 = gc_cust_orig_system_ref
		   AND    xftv.target_value1 = 'EXCEPT12'
		   AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE + 1)
		   AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE + 1)
		   AND    xftv.enabled_flag = 'Y'
		   AND    xftd.enabled_flag = 'Y';

		 xx_location_and_log(g_log,'Amex Except12             : '|| gn_amex_except12);

		SELECT COUNT(1)
		  INTO   gn_amex_except13
		  FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
		 WHERE  xftd.translate_id = xftv.translate_id
		   AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
		   AND    xftv.source_value1 = gc_cust_orig_system_ref
		   AND    xftv.target_value1 = 'EXCEPT13'
		   AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE + 1)
		   AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE + 1)
		   AND    xftv.enabled_flag = 'Y'
		   AND    xftd.enabled_flag = 'Y';

		 xx_location_and_log(g_log,'Amex Except13             : '|| gn_amex_except13);

		SELECT COUNT(1)
		  INTO   gn_amex_except15
		  FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
		 WHERE  xftd.translate_id = xftv.translate_id
		   AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
		   AND    xftv.source_value1 = gc_cust_orig_system_ref
		   AND    xftv.target_value1 = 'EXCEPT15'
		   AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE + 1)
		   AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE + 1)
		   AND    xftv.enabled_flag = 'Y'
		   AND    xftd.enabled_flag = 'Y';

		 xx_location_and_log(g_log,'Amex Except14             : '|| gn_amex_except15);
		 xx_location_and_log(g_loc,'Check AMEX Exception Counts and Set fields. ');

		IF (gn_amex_except11 > 0)
		THEN
		   gc_ixcustomerreferenceid := gc_ixcostcenter;
				   xx_location_and_log(g_loc,'gc_ixcustomerreferenceid-11: '||gc_ixcostcenter);
		END IF;

		IF (gn_amex_except12 > 0)
		THEN
				   gc_ixcustomerreferenceid := gc_ixreleasenumber;
				   xx_location_and_log(g_loc,'gc_ixcustomerreferenceid-12: '||gc_ixreleasenumber);
		END IF;

		IF (gn_amex_except13 > 0)
		THEN
				   gc_ixcustomerreferenceid := SUBSTR(gc_ixcostcenter,1,3) || SUBSTR(gc_ixcostcenter,18,2);
				   xx_location_and_log(g_loc,'gc_ixcustomerreferenceid-13: '||SUBSTR(gc_ixcostcenter,1,3) || SUBSTR(gc_ixcostcenter,18,2));
		END IF;

		IF (gn_amex_except15 > 0)
		THEN

			/* gc_ixcustcountrycode :=  '<ShipTo><Addr><Name>'||gc_customer_name
						  ||'</Name><PostalAddress><State>'
						  || gc_ixshiptostate || '</State><PostalCode>'
						  || gc_ixshiptozipcode || '</PostalCode></PostalAddress><Contact><Name>'
						  || gc_cust_po_number || '</Name>'
						  || '<PhoneNumber><Number></Number></PhoneNumber></Contact></Addr></ShipTo>';*/

			 gc_ixcustcountrycode :=  '<Requester><Name>'||gc_cust_po_number
								  ||'</Name><State>'
								  || gc_ixshiptostate || '</State><PostalCode>'
								  || gc_ixshiptozipcode || '</PostalCode><Country>'
								  || gc_ixshiptocountry || '</Country></Requester>';

		   xx_location_and_log(g_loc,'gc_ixcustcountrycode-2: '||gc_ixcustcountrycode);
		END IF;
	  END process_amex_data;

	-- +===================================================================+
-- | PROCEDURE  : PROCESS_AMEX_LINE_DATA                               |
-- |                                                                   |
-- | DESCRIPTION: Retrieve data for AMEX and AMEX CPC transactions     |
-- |              Procedure added for defect 38215  - Amex to Vantiv   |
-- | PARAMETERS : p_credit_card_number                                 |
-- |              p_amex_cpc                                           |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+
	  PROCEDURE process_amex_line_data(p_linenumber VARCHAR2,
									   p_ixunitmeasure 	IN OUT VARCHAR2,
									   p_ixitemquantity IN OUT VARCHAR2,
									   p_ixunitcost 	IN OUT VARCHAR2,
									   p_ixinvoicelinenum IN OUT VARCHAR2,
									   p_ixcustitemnum 	IN OUT VARCHAR2,
									   p_ixcustitemdesc	IN OUT VARCHAR2)
	  IS
		 lc_ixunitmeasure   xx_iby_batch_trxns_det.ixunitmeasure%TYPE;
		 lc_ixitemquantity  xx_iby_batch_trxns_det.ixitemquantity%TYPE;
		 lc_ixunitcost      xx_iby_batch_trxns_det.ixunitcost%TYPE;
		 lc_ixinvoicelinenum      xx_iby_batch_trxns_det.ixinvoicelinenum%TYPE;
	  BEGIN
		 xx_location_and_log(g_loc,'Processing AMEX Line');
	 gc_error_debug :=    'PROCESS_AMEX_LINE_DATA Credit Card Type: '
					  || gc_credit_card_type;

	 xx_location_and_log(g_loc,'Processing Line Data for AMEX CPC CARD. ' || gc_error_debug);
	 xx_location_and_log(g_loc,'gc_credit_card_vendor: '||gc_credit_card_vendor);
	 xx_location_and_log(g_loc,'gc_is_amex: '||gc_is_amex);

	 xx_location_and_log(g_loc,'Mapping for AMEX CPC Line Data');
	 lc_ixunitmeasure := p_ixunitmeasure;


	 xx_location_and_log(g_loc,'lc_ixunitmeasure: '||lc_ixunitmeasure);
	 IF lc_ixunitmeasure = '2-'
	 THEN
		lc_ixunitmeasure := 'OP';
	 ELSIF lc_ixunitmeasure = '3-'
	 THEN
		lc_ixunitmeasure := 'P3';
	 ELSIF lc_ixunitmeasure = '4-'
	 THEN
		lc_ixunitmeasure := 'P4';
	 ELSIF lc_ixunitmeasure = '6-'
	 THEN
		lc_ixunitmeasure := 'P6';
	 ELSIF lc_ixunitmeasure IS NULL
	 THEN
		lc_ixunitmeasure := 'EA';
	 END IF;

	 xx_location_and_log(g_loc,'lc_ixunitmeasure: '||lc_ixunitmeasure);
	 p_ixunitmeasure := lc_ixunitmeasure;

	 lc_ixitemquantity := p_ixitemquantity;
	 lc_ixunitcost     := p_ixunitcost;
	 IF SIGN(lc_ixitemquantity) < 0
	 THEN
		lc_ixitemquantity := ABS(lc_ixitemquantity);
		lc_ixunitcost     := (-1) * ABS(p_ixunitcost);
		 END IF;

		 lc_ixinvoicelinenum :=  p_ixinvoicelinenum;
		 IF lc_ixinvoicelinenum IS NULL AND p_linenumber > 0
		 THEN
			p_ixinvoicelinenum := '0000'||to_char(p_linenumber);
		 END IF;

	 IF (gn_amex_except13 > 0)
	 THEN
				   p_ixcustitemnum := SUBSTR(gc_ixcostcenter,14,4);
				   xx_location_and_log(g_loc,'ixcustitemnum-13: '||SUBSTR(gc_ixcostcenter,14,4));
				   p_ixcustitemdesc := SUBSTR(SUBSTR(gc_ixcostcenter,1,5)||'-'||SUBSTR(gc_ixcostcenter,6,3)
									   ||'-'||SUBSTR(gc_ixcostcenter,9,2)||'-'||SUBSTR(gc_ixcostcenter,11),4,13);
				   xx_location_and_log(g_loc,'ixcustitemdesc-13: '||SUBSTR(SUBSTR(gc_ixcostcenter,1,5)||'-'||SUBSTR(gc_ixcostcenter,6,3)
									   ||'-'||SUBSTR(gc_ixcostcenter,9,2)||'-'||SUBSTR(gc_ixcostcenter,11),4,13));
	 END IF;
	  END process_amex_line_data;
	--End changes for defect 38215


-- +===================================================================+
-- | PROCEDURE  : PROCESS_NET_DATA                                     |
-- |                                                                   |
-- | DESCRIPTION: Retrieve net data for AMEX CPC transactions          |
-- |              Defect 14579, moved the processing into a procedure  |
-- |              to process iRec transacitons paying multiple trx     |
-- |                                                                   |
-- | PARAMETERS : p_credit_card_number                                 |
-- |              p_amex_cpc                                           |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+
	PROCEDURE process_net_data
	IS
------------------------------------------------------
-- Process NET_DATA AMEX CPC CARD
------------------------------------------------------
-- Defect 13466 - Process NET_DATA AMEX CPC CARD moved from XX_SET_POST_RECEIPT_VARIABLES
-- Attribute14 (gc_credit_card_type) in cash receipts table is NULL for Irec Transactions Only,
	BEGIN
		xx_location_and_log(g_loc,
							'Processing Net Data for AMEX CPC CARD. ');

		gc_error_debug :=    'Credit Card Type: '
						  || gc_credit_card_type
						  || ' Net Data: '
						  || gc_net_data;

		-- Added by AG
		xx_location_and_log(g_loc,
							'Processing Net Data for AMEX CPC CARD. ' || gc_error_debug);
		xx_location_and_log(g_loc,'gc_credit_card_vendor: '||gc_credit_card_vendor);



		--Initialize the variable
		gn_amex_cpc := 0;

		IF    (SUBSTR(UPPER(TRIM(gc_credit_card_type) ),
					  1,
					  4) = 'AMEX')
		   OR (UPPER(gc_credit_card_vendor) = 'AMEX')
		THEN
			gc_is_amex := 'Y';
			amex_cpc(p_credit_card_number =>      gc_bank_account_num,
					 p_identifier =>              gc_identifier,
					 p_amex_cpc =>                gn_amex_cpc);

			xx_location_and_log(g_loc, 'gn_amex_cpc :'||gn_amex_cpc);

		END IF;

		IF (gn_amex_cpc > 0)
		THEN
			gc_ixinstrsubtype := 'AMEX';
			gc_ixps2000 := SUBSTR(gc_net_data,
								  1,
								  15);
			gc_ixreserved43 := SUBSTR(gc_net_data,
									  16,
									  12);
			xx_location_and_log(g_loc,
								'Retrieving AMEX_CC from FTP_DETAILS_AJB Translation Definition. ');
			gc_error_debug :=    'Credit Card Type: '
							  || gc_credit_card_type;

			SELECT xftv.target_value1
			INTO   gc_amex_cc
			FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			WHERE  xftd.translate_id = xftv.translate_id
			AND    xftd.translation_name = 'FTP_DETAILS_AJB'
			AND    xftv.source_value1 = 'AMEX_CC'
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';

			BEGIN
				-- Defect 13466 - removed NVL(gc_store,gc_shiploc) and replaced with gc_ixstorenumber
				xx_location_and_log
							  (g_loc,
							   'Retrieving AMEX MERCHANT NUMBER for AMEX_FIN_MERCHANT_NUMBERS Translation Definition. ');
				gc_error_debug :=    'Store Number: '
								  || NVL(gc_store,
										 gc_shiploc);

				SELECT xftv.source_value3
				INTO   gc_amex_merchant_number
				FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
				WHERE  xftd.translate_id = xftv.translate_id
				AND    xftd.translation_name = 'AMEX_FIN_MERCHANT_NUMBERS'
				AND    xftv.source_value1 = NVL(gc_ixstorenumber,
												gc_oapfstoreid)
				AND    xftv.source_value2 = gc_amex_cc
				AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																		SYSDATE
																	  + 1)
				AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																		SYSDATE
																	  + 1)
				AND    xftv.enabled_flag = 'Y'
				AND    xftd.enabled_flag = 'Y';
			EXCEPTION
				WHEN OTHERS
				THEN
					xx_location_and_log
						(g_loc,
						 'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Process NET_DATA AMEX CPC CARD. ');
					gc_amex_merchant_number := NULL;
					xx_location_and_log(g_log,
										   'AMEX Merchant Number     : '
										|| gc_amex_merchant_number);
			END;
		ELSE
			gc_ixinstrsubtype := NULL;

			xx_location_and_log(g_log,
								'gc_is_amex: '
							|| gc_is_amex);

			IF gc_is_amex = 'Y'
			THEN
				-- Amex Card Received from ireceivables.
				gc_ixps2000 := SUBSTR(gc_net_data,
									  1,
									  15);
				gc_ixreserved43 := SUBSTR(gc_net_data,
										  16,
										  12);
			END IF;
		END IF;


		xx_location_and_log(g_log,
							   'AMEX CPC                 : '
							|| gn_amex_cpc);
		xx_location_and_log(g_log,
							   'IXSTORENUMBER            : '
							|| gc_ixstorenumber);
		xx_location_and_log(g_log,
							   'Store Number             : '
							|| gc_store);
		xx_location_and_log(g_log,
							   'Ship Location            : '
							|| gc_shiploc);
		xx_location_and_log(g_log,
							   'Inst Sub Type            : '
							|| gc_ixinstrsubtype);
		xx_location_and_log(g_log,
							   'IXPS2000                 : '
							|| gc_ixps2000);
		xx_location_and_log(g_log,
							   'IXRESERVED43             : '
							|| gc_ixreserved43);
		xx_location_and_log(g_log,
							   'AMEX Merchant Number     : '
							|| gc_amex_merchant_number);
	EXCEPTION
		WHEN ex_raise_cc_decrytpt
		THEN
			xx_location_and_log
				(g_loc,
				 'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Process NET_DATA AMEX CPC CARD - ex_raise_cc_decrytpt');
			fnd_file.put_line(fnd_file.LOG, ' Error ex_raise_cc_decrytpt - Raise ex_cc_decrytpt for order payment id ' || gn_order_payment_id);
			RAISE ex_cc_decrytpt;
		WHEN OTHERS
		THEN
			xx_location_and_log
				(g_loc,
				 'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Process NET_DATA AMEX CPC CARD >0. ');
			gc_ixinstrsubtype := NULL;
			xx_location_and_log(g_log,
								   'Inst Sub Type            : '
								|| gc_ixinstrsubtype);
	END process_net_data;

-- +====================================================================+
-- | PROCEDURE  : XX_RETRIEVE_ORDER_PMT_ID                              |
-- |                                                                    |
-- | DESCRIPTION: Retrieves the Order Payment ID from Cash Receipt ID   |
-- |                                                                    |
-- | PARAMETERS : p_cash_receipt_id                                     |
-- |              x_order_payment_id                                    |
-- |              x_error_message                                       |
-- |                                                                    |
-- | RETURNS    : Order Payment Id and Error Message                    |
-- +====================================================================+
	PROCEDURE xx_retrieve_order_pmt_id(
		p_cash_receipt_id   IN      NUMBER,
		x_order_payment_id  OUT     NUMBER,
		x_error_message     OUT     VARCHAR2)
	IS
		lc_remitted_flag  xx_ar_order_receipt_dtl.remitted%TYPE;
	BEGIN
		x_order_payment_id := NULL;
		x_error_message := NULL;
		gn_order_payment_id := NULL;
		lc_remitted_flag := NULL;
		xx_location_and_log(g_loc,
							'Retrieving Order Payment ID. ');
		gc_error_debug :=    'Cash Receipt ID: '
						  || p_cash_receipt_id;

		SELECT xaord.order_payment_id,
			   xaord.remitted
		INTO   gn_order_payment_id,
			   lc_remitted_flag
		FROM   xx_ar_order_receipt_dtl xaord
		WHERE  xaord.cash_receipt_id = p_cash_receipt_id;

		IF lc_remitted_flag IN('Y', 'S')
		THEN
			RAISE ex_receipt_remitted;
		END IF;

		-- The above query statements sets the global variable.
		-- The global variable is being assigned to a OUT parameter for clarity
		x_order_payment_id := gn_order_payment_id;
		x_error_message := NULL;
	EXCEPTION
		WHEN TOO_MANY_ROWS
		THEN
			xx_location_and_log(g_loc,
								'Entering TOO_MANY_ROWS Exception in XX_RETRIEVE_ORDER_PMT_ID. ');
			x_order_payment_id := NULL;
			x_error_message :=    'More than 1 record found for cash receipt id: '
							   || p_cash_receipt_id;
		WHEN NO_DATA_FOUND
		THEN
			xx_location_and_log(g_loc,
								'Entering NO_DATA_FOUND Exception in XX_RETRIEVE_ORDER_PMT_ID. ');
			x_order_payment_id := NULL;
			x_error_message := NULL;
	END xx_retrieve_order_pmt_id;

		-- +====================================================================+
-- | PROCEDURE  : XX_UPDATE_COF_TRANS                              |
-- |                                                                    |
-- | DESCRIPTION: Changes made for COF Transactions as per V48.0 |
-- |                                                                    |
-- | PARAMETERS : NONE
-- |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***                   |
-- +====================================================================+
	PROCEDURE XX_UPDATE_COF_TRANS
	is
	BEGIN


			if gc_ixwallet_type='1' then

				if gc_ixoptions is not null then
					gc_ixoptions := gc_ixoptions||' '|| '*COF';
					gc_ixreserved32:='<COF><Schedule>N</Schedule><Reason>Initial</Reason></COF>';
				else
					gc_ixoptions := gc_ixoptions||'*COF';
					gc_ixreserved32:='<COF><Schedule>N</Schedule><Reason>Initial</Reason></COF>';
				end if;

			end if;

			if gc_ixwallet_type='2' then

				if gc_ixoptions is not null then
					gc_ixoptions := gc_ixoptions||' '|| '*COF';
					gc_ixreserved32:='<COF><Schedule>N</Schedule><Reason>Subsequent</Reason></COF>';
				else
					gc_ixoptions := gc_ixoptions||'*COF';
					gc_ixreserved32:='<COF><Schedule>N</Schedule><Reason>Subsequent</Reason></COF>';
				end if;
			end if;

			if gc_ixwallet_type='3' then
				if gc_ixoptions is not null then
					gc_ixoptions := gc_ixoptions||' '|| '*COF';
					gc_ixreserved32:='<COF><Schedule>N</Schedule><Reason>Reauth</Reason></COF>';
				else
					gc_ixoptions := gc_ixoptions||'*COF';
					gc_ixreserved32:='<COF><Schedule>N</Schedule><Reason>Reauth</Reason></COF>';
				end if;
			end if;

			if gc_ixwallet_type='4' then
				if gc_ixoptions is not null then
					gc_ixoptions := gc_ixoptions||' '|| '*COF *Recurring_Payment';
					gc_ixreserved32:='<COF><Schedule>Y</Schedule><Reason>Initial</Reason></COF>';
				else
					gc_ixoptions := gc_ixoptions||'*COF *Recurring_Payment';
					gc_ixreserved32:='<COF><Schedule>Y</Schedule><Reason>Initial</Reason></COF>';
				end if;
			end if;

			if gc_ixwallet_type='5' then
				if gc_ixoptions is not null then
					gc_ixoptions := gc_ixoptions||' '|| '*COF *Recurring_Payment';
					gc_ixreserved32:='<COF><Schedule>Y</Schedule><Reason>Subsequent</Reason></COF>';
				else
					gc_ixoptions := gc_ixoptions||'*COF *Recurring_Payment';
					gc_ixreserved32:='<COF><Schedule>Y</Schedule><Reason>Subsequent</Reason></COF>';
				end if;
			end if;

			if gc_ixwallet_type='6' then
				if gc_ixoptions is not null then
					gc_ixoptions := gc_ixoptions||' '|| '*COF *Recurring_Payment';
					gc_ixreserved32:='<COF><Schedule>Y</Schedule><Reason>Resubmit</Reason></COF>';
				else
					gc_ixoptions := gc_ixoptions||'*COF *Recurring_Payment';
					gc_ixreserved32:='<COF><Schedule>Y</Schedule><Reason>Resubmit</Reason></COF>';
				end if;
			end if;
			xx_location_and_log(g_log,
							   'ixoptions   : '
							|| gc_ixoptions);
			xx_location_and_log(g_log,
							   'ixreserved32: '
							|| gc_ixreserved32);


	EXCEPTION
		WHEN OTHERS
		THEN
		 xx_location_and_log(g_loc,
								'Entering OTHERS Exception in XX_UPDATE_COF_TRANS.' || ' '
							  || SQLERRM);
		gc_ixreserved32:=null;
	END XX_UPDATE_COF_TRANS;

-- +====================================================================+
-- | FUNCTION   : XX_VALIDATE_DEPOSIT_RECEIPT                           |
-- |                                                                    |
-- | DESCRIPTION: Determines if receipt is a deposit receipt            |
-- |                                                                    |
-- | PARAMETERS : p_cash_receipt_id                                     |
-- |                                                                    |
-- | RETURNS    : BOOLEAN                                               |
-- +====================================================================+
	FUNCTION xx_validate_deposit_receipt(
		p_cash_receipt_id  IN  NUMBER)
		RETURN BOOLEAN
	IS
		ln_deposit_receipt  NUMBER := 0;
	BEGIN
------------------------------------------------------
-- Check if Deposit Exists in AR cash receipts (SALE)
------------------------------------------------------
		xx_location_and_log(g_loc,
							'Checking if the Receipt is a Deposit Receipt. ');
		gc_error_debug :=    'Cash Receipt id: '
						  || gn_cash_receipt_id;

		-- IF there is No Invoice and also No Order  Information then it is Deposit Receipt
		SELECT COUNT(1)
		INTO   ln_deposit_receipt
		FROM   ar_cash_receipts_all acr, ar_receivable_applications_all ara
		WHERE  acr.cash_receipt_id = ara.cash_receipt_id
		AND    ara.application_ref_type = 'SA'
		AND    acr.attribute_category = 'SALES_ACCT'
		AND    acr.attribute11 = 'SA_DEPOSIT'
		AND    acr.cash_receipt_id = p_cash_receipt_id;

		IF ln_deposit_receipt > 0
		THEN
			xx_location_and_log(g_log,
								'Deposit Receipt ?        : YES');
			RETURN TRUE;
		ELSE
			xx_location_and_log(g_log,
								'Deposit Receipt ?        : NO');
			RETURN FALSE;
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			xx_location_and_log(g_loc,
								'Entering WHEN OTHERS Exception in XX_RETRIEVE_ORDER_PMT_ID. ');
			RETURN FALSE;
	END xx_validate_deposit_receipt;

-- +====================================================================+
-- | FUNCTION   : XX_GET_INVOICE_TYPE                                   |
-- |                                                                    |
-- | DESCRIPTION: Finds the Invoice Type                                |
-- |                                                                    |
-- | PARAMETERS : p_customer_trx_id                                     |
-- |                                                                    |
-- | RETURNS    : MIXED_ORDER,RETURN_ORDER,SALE_ORDER,NO_INVOICE        |
-- +====================================================================+
	FUNCTION xx_get_invoice_type(
		p_customer_trx_id  IN  NUMBER)
		RETURN VARCHAR
	IS
		lc_return_invoice_flag  VARCHAR2(1)  := 'N';
		lc_fwd_invoice_flag     VARCHAR2(1)  := 'N';
		lc_invoice_type         VARCHAR2(25) := NULL;

		CURSOR c_invoice_type
		IS
			SELECT line_type,
				   extended_amount
			FROM   ra_customer_trx_all rct, ra_customer_trx_lines_all rctl
			WHERE  rct.customer_trx_id = rctl.customer_trx_id
			AND    rct.customer_trx_id = p_customer_trx_id;
	BEGIN
		xx_location_and_log(g_loc,
							'XX_GET_INVOICE_TYPE - Fetch Invoice Type. ');

		FOR lcu_invoice_type IN c_invoice_type
		LOOP
			IF SIGN(lcu_invoice_type.extended_amount) = -1
			THEN
				lc_return_invoice_flag := 'R';
			ELSIF SIGN(lcu_invoice_type.extended_amount) = 1
			THEN
				lc_fwd_invoice_flag := 'F';
			END IF;
		END LOOP;

		xx_location_and_log(g_loc,
							'Checking Return Invoice Flag and Forward Invoice Flags. ');
		gc_error_debug :=
					'Return Invoice Flag: '
				 || lc_return_invoice_flag
				 || '. Forward Invoice Flags: '
				 || lc_fwd_invoice_flag;

		IF     lc_return_invoice_flag = 'R'
		   AND lc_fwd_invoice_flag = 'F'
		THEN
			lc_invoice_type := 'MIXED_ORDER';
		ELSIF     lc_return_invoice_flag = 'R'
			  AND lc_fwd_invoice_flag = 'N'
		THEN
			lc_invoice_type := 'CREDIT_MEMO';
		ELSIF     lc_return_invoice_flag = 'N'
			  AND lc_fwd_invoice_flag = 'F'
		THEN
			lc_invoice_type := 'INVOICE';
		ELSIF     lc_return_invoice_flag = 'N'
			  AND lc_fwd_invoice_flag = 'N'
		THEN
			lc_invoice_type := 'NO_INVOICE';
		END IF;

		RETURN lc_invoice_type;
	END xx_get_invoice_type;

-- +====================================================================+
-- | FUNCTION   : XX_GET_ORDER_TYPE                                     |
-- |                                                                    |
-- | DESCRIPTION: Finds the ORDER Type                                  |
-- |                                                                    |
-- | PARAMETERS : p_header_id                                           |
-- |                                                                    |
-- | RETURNS    : MIXED_ORDER,RETURN_ORDER,SALE_ORDER,NO_ORDER          |
-- +====================================================================+
	FUNCTION xx_get_order_type(
		p_header_id  IN  NUMBER)
		RETURN VARCHAR
	IS
		lc_return_order_flag  VARCHAR2(1)  := 'N';
		lc_fwd_order_flag     VARCHAR2(1)  := 'N';
		lc_order_type         VARCHAR2(25) := NULL;

		CURSOR c_order_type
		IS
			SELECT   COUNT(1) line_count,
					 ool.line_category_code
			FROM     oe_order_lines_all ool
			WHERE    ool.header_id = p_header_id
			GROUP BY ool.line_category_code;
	BEGIN
		xx_location_and_log(g_loc,
							'XX_GET_ORDER_TYPE - Fetch Order Type. ');

		FOR lcu_order_type IN c_order_type
		LOOP
			IF     lcu_order_type.line_category_code = 'RETURN'
			   AND lcu_order_type.line_count > 0
			THEN
				lc_return_order_flag := 'R';
			ELSIF     lcu_order_type.line_category_code = 'ORDER'
				  AND lcu_order_type.line_count > 0
			THEN
				lc_fwd_order_flag := 'F';
			END IF;
		END LOOP;

		xx_location_and_log(g_loc,
							'Checking Return Order Flag and Forward Order Flags. ');
		gc_error_debug :=
							'Return Order Flag: '
						 || lc_return_order_flag
						 || '. Forward Order Flags: '
						 || lc_fwd_order_flag;

		IF     lc_return_order_flag = 'R'
		   AND lc_fwd_order_flag = 'F'
		THEN
			lc_order_type := 'MIXED_ORDER';
		ELSIF     lc_return_order_flag = 'R'
			  AND lc_fwd_order_flag = 'N'
		THEN
			lc_order_type := 'RETURN_ORDER';
		ELSIF     lc_return_order_flag = 'N'
			  AND lc_fwd_order_flag = 'F'
		THEN
			lc_order_type := 'SALE_ORDER';
		ELSIF     lc_return_order_flag = 'N'
			  AND lc_fwd_order_flag = 'N'
		THEN
			lc_order_type := 'NO_ORDER';
		END IF;

		RETURN lc_order_type;
	END xx_get_order_type;

-- +====================================================================+
-- | PROCEDURE  : XX_SET_TAX_COLL_INDICATORS                            |
-- |                                                                    |
-- | DESCRIPTION: Determines/set variable to indicate if tax was        |
-- |              collected or not                                      |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_set_tax_coll_indicators
	IS
	BEGIN
------------------------------------------
-- Set IXTOTALSALESTAXCOLLIND
------------------------------------------
		IF (gc_ixtotalsalestaxamount <> 0)
		THEN
			gc_ixtotalsalestaxcollind := '1';
		ELSE
			gc_ixtotalsalestaxcollind := '2';
		END IF;

------------------------------------------
-- Set IXNATIONALTAXCOLLINDICATOR
------------------------------------------
		IF (     (gc_ixnationaltaxamount = 0)
			AND (gc_ixothertaxamount = 0) )
		THEN
			gc_ixnationaltaxcollindicator := '2';
		ELSIF(     (gc_ixnationaltaxamount <> 0)
			  AND (gc_ixothertaxamount = 0) )
		THEN
			gc_ixnationaltaxcollindicator := '1';
		ELSIF(     (gc_ixnationaltaxamount = 0)
			  AND (gc_ixothertaxamount <> 0) )
		THEN
			gc_ixnationaltaxcollindicator := '0';
		ELSE
			gc_ixnationaltaxcollindicator := '1';
		END IF;

		xx_location_and_log(g_log,
							   'ixtotalsalestaxcollind   : '
							|| gc_ixtotalsalestaxcollind);
		xx_location_and_log(g_log,
							   'ixnationaltaxcollindicatr: '
							|| gc_ixnationaltaxcollindicator);
	END xx_set_tax_coll_indicators;

-- +====================================================================+
-- | FUNCTION   : XX_IS_IREC_RECEIPT                                    |
-- |                                                                    |
-- | DESCRIPTION: This function will be called to check if given receipt|
-- |              is i-receivable receipt or not.  The function will be |
-- |              called only by the PRE_CAPTURE_CCRETUNRN procedure.   |
-- |                                                                    |
-- | PARAMETERS : p_cash_receipt_id                                     |
-- |                                                                    |
-- | RETURNS    : BOOLEAN (returns true if created else returns false)  |
-- +====================================================================+
	FUNCTION xx_is_irec_receipt(
		p_cash_receipt_id  IN  NUMBER)
		RETURN BOOLEAN
	IS
		lc_method_name  xx_fin_translatevalues.source_value1%TYPE;
		ln_rec_count    NUMBER;
	BEGIN
		xx_location_and_log(g_loc,
							'***** Executing XX_IS_IREC_RECEIPT ***** ');
		-- Defect 12840 - removed criteria for checking <> 'MISC'
		xx_location_and_log(g_loc,
							'Determining if cash receipt from iReceivables. ');

		SELECT NVL(COUNT(1),
				   0)
		INTO   ln_rec_count
		FROM   xx_fin_translatedefinition xtd,
			   xx_fin_translatevalues xtv,
			   ar_receipt_methods arm,
			   ar_cash_receipts_all acr
		WHERE  acr.cash_receipt_id = p_cash_receipt_id
		AND    arm.receipt_method_id = acr.receipt_method_id
		AND    arm.NAME = xtv.source_value1
		AND    xtd.translation_name = 'OD_AR_RECIEPT_METHOD_LKUP'
		AND    xtd.translate_id = xtv.translate_id;

		IF ln_rec_count <> 0
		THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			xx_location_and_log(g_loc,
								'Entering NO_DATA_FOUND Exception in XX_IS_IREC_RECEIPT. ');
			RETURN FALSE;
		WHEN OTHERS
		THEN
			xx_location_and_log(g_loc,
								'Entering WHEN OTHERS Exception in XX_IS_IREC_RECEIPT. ');
			gc_error_debug :=    'Error occured finding IREC for receipt id: '
							  || p_cash_receipt_id
							  || ' '
							  || SQLERRM;
			fnd_file.put_line(fnd_file.LOG,
								 'Error Msg XX_IS_IREC_RECEIPT '
							  || 'function: '
							  || SQLERRM);
			RETURN FALSE;
	END xx_is_irec_receipt;

	-- +====================================================================+
-- | FUNCTION   : xx_is_service_contract_receipt                                    |
-- |                                                                    |
-- | DESCRIPTION: This function will be called to check if given receipt|
-- |              is Service Contract receipt or not.  The function will be |
-- |              called only by the xx_retrieve_processing_type procedure.   |
-- |                                                                    |
-- | PARAMETERS : p_order_payment_id                                     |
-- |                                                                    |
-- | RETURNS    : BOOLEAN (returns true if created else returns false)  |
-- +====================================================================+
	FUNCTION xx_is_service_contract_receipt(       --Added this procedure for V47.0 5/Mar/2018
		p_order_payment_id  IN  NUMBER)
		RETURN BOOLEAN
	IS

		ln_rec_count    NUMBER;
	BEGIN
		xx_location_and_log(g_loc,
							'***** Executing XX_IS_SERVICE_CONTRACT_RECEIPT ***** ');
		xx_location_and_log(g_loc,
							'Determining if cash receipt from Service Contracts. ');

		SELECT count(1)
		INTO   ln_rec_count
		FROM   xx_ar_order_receipt_dtl ordt
		WHERE  ordt.order_payment_id = p_order_payment_id
		AND    ordt.process_code = g_service_contracts;

		IF ln_rec_count <> 0
		THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			xx_location_and_log(g_loc,
								'Entering NO_DATA_FOUND Exception in XX_IS_SERVICE_CONTRACT_RECEIPT. ');
			RETURN FALSE;
		WHEN OTHERS
		THEN
			xx_location_and_log(g_loc,
								'Entering WHEN OTHERS Exception in XX_IS_SERVICE_CONTRACT_RECEIPT. ');
			gc_error_debug :=    'Error occured finding SERVICE-CONTRACTS for receipt id: '
							  || p_order_payment_id
							  || ' '
							  || SQLERRM;
			fnd_file.put_line(fnd_file.LOG,
								 'Error Msg XX_IS_SERVICE_CONTRACT_RECEIPT '
							  || 'function: '
							  || SQLERRM);
			RETURN FALSE;
	END xx_is_service_contract_receipt;

-- +====================================================================+
-- | FUNCTION   : XX_IS_MISC_RECEIPT                                    |
-- |                                                                    |
-- | DESCRIPTION: This function will be called to check if given receipt|
-- |               is a MISC type or not.  The function will be called  |
-- |               only by the PRE_CAPTURE_CCRETUNRN procedure.         |
-- |                                                                    |
-- | PARAMETERS : p_cash_receipt_id                                     |
-- |                                                                    |
-- | RETURNS    : BOOLEAN (returns true if created else returns false)  |
-- +====================================================================+
	FUNCTION xx_is_misc_receipt(
		p_cash_receipt_id  IN  NUMBER)
		RETURN BOOLEAN
	IS
		lc_method_name  xx_fin_translatevalues.source_value1%TYPE;
		ln_rec_count    NUMBER;
	BEGIN
		xx_location_and_log(g_loc,
							'***** Executing XX_IS_MISC_RECEIPT ***** ');
		xx_location_and_log(g_loc,
							'Determine if cash receipt is Miscelleanous type (MISC). ');

		SELECT NVL(COUNT(1),
				   0)
		INTO   ln_rec_count
		FROM   xx_fin_translatedefinition xtd, xx_fin_translatevalues xtv, ar_cash_receipts_all acr, fnd_user fu
		WHERE  acr.cash_receipt_id = p_cash_receipt_id
		AND    acr.TYPE = 'MISC'
		AND    fu.user_name != xtv.source_value2
		AND    acr.created_by = fu.user_id
		AND    xtd.translation_name = 'OD_AR_RECIEPT_METHOD_LKUP'
		AND    xtd.translate_id = xtv.translate_id;

		IF ln_rec_count <> 0
		THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			xx_location_and_log(g_loc,
								'Entering NO_DATA_FOUND Exception in XX_IS_MISC_RECEIPT. ');
			RETURN FALSE;
		WHEN OTHERS
		THEN
			xx_location_and_log(g_loc,
								'Entering WHEN OTHERS Exception in XX_IS_MISC_RECEIPT. ');
			gc_error_debug :=    'Error occured finding MISC for receipt id: '
							  || p_cash_receipt_id
							  || ' '
							  || SQLERRM;
			fnd_file.put_line(fnd_file.LOG,
								 'Error Msg XX_IS_MISC_RECEIPT '
							  || 'function: '
							  || SQLERRM);
			RETURN FALSE;
	END xx_is_misc_receipt;

-- +====================================================================+
-- | PROCEDURE  : XX_RETRIEVE_PROCESSING_TYPE                           |
-- |                                                                    |
-- | DESCRIPTION: The following is performed by this procedure          |
-- |      1. Sets Remittance Processing Type to 1 of the following      |
-- |          G_POE_INT_STORE_CUST       - 'POE_INT_STORE_CUST'         |
-- |          G_POE_SINGLE_PMT_MULTI_ORD - 'POE_SINGLE_PMT_MULTI_ORDER' |
-- |          G_IREC                     - 'IREC'                       |
-- |          G_CCREFUND                 - 'CCREFUND'                   |
-- |          G_DEFAULT                  - 'DEFAULT_PROCESSING'         |
-- |                                                                    |
-- |      2. Retreives Order Source                                     |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_retrieve_processing_type
	IS
		lc_deposit_ind         VARCHAR2(1) := 'N';
		gc_internal_cust_flag  VARCHAR2(1) := 'N';
	BEGIN
------------------------------------------------------------
-- Retrieving Sale Type, Receipt Method ID, and Order Source
------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving Sale Type, Receipt Method ID, and Order Source. ');

			SELECT sale_type,
				   receipt_method_id,
				   order_source,
				   single_pay_ind,
				   /*DECODE(payment_amount,
						  0, 'Y',
						  'N')*/
				   DECODE(SIGN(payment_amount),
						  '-1', 'Y',
						  'N')
			INTO   gc_sale_type,
				   gn_receipt_method_id,
				   gc_order_source,
				   gc_single_pay_ind,
				   gc_ccrefund_flag
			FROM   xx_ar_order_receipt_dtl
			WHERE  order_payment_id = gn_order_payment_id;

			xx_location_and_log(g_log,
								   'Sale Type                : '
								|| gc_sale_type);
			xx_location_and_log(g_log,
								   'Receipt Method ID        : '
								|| gn_receipt_method_id);
			xx_location_and_log(g_log,
								   'Order Source             : '
								|| gc_order_source);
			xx_location_and_log(g_log,
								   'Order_payment_id         : '
								|| gn_order_payment_id);
			xx_location_and_log(g_log,
								   'CC Refund Flag           : '
								|| gc_ccrefund_flag);
			xx_location_and_log(g_loc,
								'Validating Sale Type. ');

			IF (gc_sale_type NOT IN(g_sale, g_dep_sales, g_refund, g_dep_refund) )
			THEN
				xx_location_and_log(g_loc,
									'Invalid Sale Type was found in EX_INVALID_SALE_TYPE. ');
				RAISE ex_invalid_sale_type;
			END IF;
		EXCEPTION
			WHEN TOO_MANY_ROWS
			THEN
				xx_location_and_log(g_loc,
									'Entering TOO_MANY_ROWS Exception in XX_RETRIEVE_PROCESSING_TYPE. ');
				RAISE ex_invalid_sale_type;
			WHEN NO_DATA_FOUND
			THEN
				xx_location_and_log(g_loc,
									'Entering NO_DATA_FOUND Exception in XX_RETRIEVE_PROCESSING_TYPE. ');
				RAISE ex_invalid_sale_type;
			WHEN OTHERS
			THEN
				xx_location_and_log(g_loc,
									   'Entering WHEN OTHERS Exception in XX_RETRIEVE_PROCESSING_TYPE. '
									|| ':'
									|| SQLERRM);
				RAISE ex_invalid_sale_type;
		END;

---------------------------------------------
-- Override for DEPOSIT-SALE or DEPOSIT-REFUND
---------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Override for DEPOSIT-SALE and DEPOSIT-REFUND. ');
			xx_location_and_log(g_log,
								   'Current Sale Type        : '
								|| gc_sale_type);

			IF gc_sale_type = g_dep_sales
			THEN
				gc_sale_type := g_sale;
				gb_is_deposit_receipt := TRUE;
			ELSIF gc_sale_type = g_dep_refund
			THEN
				gc_sale_type := g_refund;
				gc_is_deposit_return := TRUE;
			END IF;

			xx_location_and_log(g_log,
								   'SaleType post-Deposit chk: '
								|| gc_sale_type);
		END;

---------------------------------------------
-- Internal Store Customer Check
---------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Checking if internal store customer. ');

			SELECT 'Y'
			INTO   gc_internal_cust_flag
			FROM   xx_ar_order_receipt_dtl xaord, xx_ar_intstorecust_otc xaio
			WHERE  xaord.order_payment_id = gn_order_payment_id
			AND    xaord.order_source = g_poe
			AND    xaord.customer_id = xaio.cust_account_id;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				xx_location_and_log(g_loc,
									'Entering NO_DATA_FOUND Exception in XX_RETRIEVE_PROCESSING_TYPE. ');
				gc_internal_cust_flag := 'N';
			WHEN TOO_MANY_ROWS
			THEN
				xx_location_and_log(g_loc,
									'Entering TOO_MANY_ROWS Exception in XX_RETRIEVE_PROCESSING_TYPE. ');
				RAISE ex_corrupt_intstore;
		END;

-----------------------------------------------
-- Retrieve Receipt Method Name
-----------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving Receipt Method Name. ');
			gc_error_debug :=    'Receipt Method ID: '
							  || gn_receipt_method_id;

			SELECT arm.NAME
			INTO   gc_recp_method_name
			FROM   ar_receipt_methods arm
			WHERE  arm.receipt_method_id = gn_receipt_method_id;

			xx_location_and_log(g_log,
								   'Receipt Method Name      : '
								|| gc_recp_method_name);
		END;

-----------------------------------------------
-- Derive Remittance Processing Type
-----------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Derive Remittance Processing Type. ');

			IF (    gc_ccrefund_flag = 'Y'
				AND NOT(    gc_internal_cust_flag = 'Y'
						AND gc_order_source = g_poe) )
			THEN
				gc_remit_processing_type := g_ccrefund;
				gc_is_deposit := 'N';
				gc_is_custom_refund := 'Y';

				-- Validation added for defect 13248 due to I1025 inserting DEPOSIT SALE or SALE for $0.00
				IF gc_sale_type = g_sale
				THEN
					gc_sale_type := g_refund;
				END IF;

				xx_location_and_log(g_log,
									   'SaleType post-$0.00 check: '
									|| gc_sale_type);
			ELSIF(    gc_single_pay_ind = 'Y'
				  AND gc_sale_type = g_sale)
			THEN   -- per defect 13814 added gc_sale_type of Sale
				gc_remit_processing_type := g_poe_single_pmt_multi_ord;
				gc_is_deposit := 'Y';   --Modified by NB for DEFECT 15454
			ELSIF(    gc_order_source = g_poe
				  AND gb_is_deposit_receipt = FALSE
				  AND gc_is_deposit_return = FALSE
				  AND gc_internal_cust_flag = 'Y')
			THEN
				gc_remit_processing_type := g_poe_int_store_cust;
			ELSIF xx_is_irec_receipt(gn_cash_receipt_id)
			THEN
				gc_remit_processing_type := g_irec;
			ELSIF xx_is_service_contract_receipt(gn_order_payment_id)--Added for V47.0 5/Mar/2018
			THEN
				gc_remit_processing_type := g_service_contracts;
			ELSE
				gc_remit_processing_type := g_default;
			END IF;

			DBMS_OUTPUT.put_line(   ' remit_processing_type:'
								 || gc_remit_processing_type);
			DBMS_OUTPUT.put_line(   'gn_cash_receipt_id:'
								 || gn_cash_receipt_id);
			xx_location_and_log(g_log,
								   'Remit Processing Type    : '
								|| gc_remit_processing_type);
		END;
	END xx_retrieve_processing_type;

-- +====================================================================+
-- | PROCEDURE  : XX_SET_PRE_RECEIPT_VARIABLES                          |
-- |                                                                    |
-- | DESCRIPTION: Initializes various package variables which are not   |
-- |              required to have the receipt, order, etc. retrieved.  |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_set_pre_receipt_variables
	IS
	BEGIN
--------------------------------------------------------------------------
-- Set Transaction Type based on Sale Type
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Setting Transaction Type based on Sale Type. ');

			IF gc_sale_type = g_sale
			THEN
				gc_ixtransactiontype := 'Sale';
			ELSIF gc_sale_type = g_refund
			THEN
				gc_ixtransactiontype := 'Refund';
			END IF;

			xx_location_and_log(g_log,
								   'ixtransactiontype        : '
								|| gc_ixtransactiontype);
			DBMS_OUTPUT.put_line(   'ixtransactiontype        : '
								 || gc_ixtransactiontype);
		END;

--------------------------------------------------------------------------
-- Retrieve OD_IBY_AUTH_TRANSACTIONS Values
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log
							(g_loc,
							 'Retrieving auth transaction values from OD_IBY_AUTH_TRANSACTIONS Tanslation Definition. ');

			SELECT source_value1,
				   source_value2,
				   source_value3,
				   source_value4,
				   source_value5,
				   source_value6,
				   source_value7,
				   source_value8
			INTO   gc_mo_value,
				   gc_avs_resp_value,
				   gc_cvv_resp_value,
				   gc_cardlevel_value,
				   gc_contactless_value,
				   gc_referral_value,
				   gc_master_auth_source,
				   gc_visa_auth_source
			FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			WHERE  xftd.translate_id = xftv.translate_id
			AND    xftd.translation_name = 'OD_IBY_AUTH_TRANSACTIONS'
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';

			xx_location_and_log(g_log,
								   'MO Value                 : '
								|| gc_mo_value);
			xx_location_and_log(g_log,
								   'AVS Resp Value           : '
								|| gc_avs_resp_value);
			xx_location_and_log(g_log,
								   'CVV Resp Value           : '
								|| gc_cvv_resp_value);
			xx_location_and_log(g_log,
								   'Card Level Value         : '
								|| gc_cardlevel_value);
			xx_location_and_log(g_log,
								   'Contactless Value        : '
								|| gc_contactless_value);
			xx_location_and_log(g_log,
								   'Referral Value           : '
								|| gc_referral_value);
			xx_location_and_log(g_log,
								   'Mastercard Auth Source   : '
								|| gc_master_auth_source);
			xx_location_and_log(g_log,
								   'Visa Auth Source         : '
								|| gc_visa_auth_source);
		EXCEPTION
			WHEN OTHERS
			THEN
				xx_location_and_log
					(g_loc,
					 'Entering WHEN OTHERS Exception in XX_SET_PRE_RECEIPT_VARIABLES for Retrieve OD_IBY_AUTH_TRANSACTIONS Values. ');
				gc_mo_value := NULL;
				gc_avs_resp_value := NULL;
				gc_cvv_resp_value := NULL;
				gc_cardlevel_value := NULL;
				gc_contactless_value := NULL;
				gc_referral_value := NULL;
				gc_master_auth_source := NULL;
				gc_visa_auth_source := NULL;
		END;

--------------------------------------------------------------------------
-- Retrieve OD_IBY_AUTH_ENTRY_VALUES Values
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving Auth Entry Value from OD_IBY_AUTH_ENTRY_VALUES Tanslation Definition. ');

			SELECT source_value3
			INTO   gc_auth_entry_val_c
			FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			WHERE  xftd.translate_id = xftv.translate_id
			AND    xftd.translation_name = 'OD_IBY_AUTH_ENTRY_VALUES'
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';

			xx_location_and_log(g_log,
								   'Auth Entry Val C         : '
								|| gc_auth_entry_val_c);
		EXCEPTION
			WHEN OTHERS
			THEN
				xx_location_and_log
					(g_loc,
					 'Entering WHEN OTHERS Exception in XX_SET_PRE_RECEIPT_VARIABLES for Retrieve OD_IBY_AUTH_ENTRY_VALUES Values. ');
				gc_auth_entry_val_c := NULL;
		END;

--------------------------------------------------------------------------
-- Retrieve Merchant VAT Number from AR System Parameters
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving Mercant VAT Number. ');

			SELECT tax_registration_number
			INTO   gc_ixmerchantvatnumber
			FROM   ar_system_parameters_all
			WHERE  org_id = gn_org_id;

			xx_location_and_log(g_log,
								   'Merchnant Vat Number     : '
								|| gc_ixmerchantvatnumber);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				xx_location_and_log
					(g_loc,
					 'Entering WHEN OTHERS Exception in XX_SET_PRE_RECEIPT_VARIABLES for Retrieve Merchant VAT Number. ');
				gc_ixmerchantvatnumber := NULL;
				xx_location_and_log(g_log,
									   'Merchnant Vat Number     : '
									|| gc_ixmerchantvatnumber);
		END;

--------------------------------------------------------------------------
-- Retrieve Field Separator
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving Field Separator. ');

			SELECT CHR(31)
			INTO   gc_fiegd_sep
			FROM   DUAL;
		END;
	END xx_set_pre_receipt_variables;

-- +====================================================================+
-- | PROCEDURE  : XX_RETRIEVE_RECEIPT_INFO                              |
-- |                                                                    |
-- | DESCRIPTION: Retrieves Receipt Information based on remittance     |
-- |              processing type.                                      |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_retrieve_receipt_info
	IS

	 vn_Payment_Trxn_Extension_Id ar_cash_receipts_all.Payment_Trxn_Extension_Id%TYPE ;
	BEGIN
		xx_location_and_log(g_loc,
							'Retrieving the Receipt information Based on Remittance Processing Type. ');
		xx_location_and_log(g_log,
							   'Remit Processing Type    : '
							|| gc_remit_processing_type);
		xx_location_and_log(g_log,
							   'gn_cash_receipt_id    : '
							|| gn_cash_receipt_id);
		xx_location_and_log(g_log,
							   'gn_order_payment_id   : '
							|| gn_order_payment_id);

		IF gc_remit_processing_type = g_poe_int_store_cust
		THEN
			-- Receipt amount is retrieved in this query for POE_INT_STORE_CUST source
			xx_location_and_log
							  (g_loc,
							   'Retrieving the Receipt information for POE_INT_STORE_CUST Remittance Processing Type. ');

			SELECT xaord.credit_card_number bank_account_num,
				   xaord.IDENTIFIER,
				   xaord.credit_card_expiration_date cc_exp_date,
				   xaord.org_id org_id,
				   xaord.receipt_number receipt_number,
				   'POS' recp_attr_category   -- not used for POE_INT_STORE_CUST, but defaulting one for consistency now)
										   ,
				   DECODE(xaord.cc_auth_manual,
						  'Y', '1',
						  '1', '1',
						  '2') voice_auth   -- using same logic from xx_ar_prepayments
										 ,
				   xaord.credit_card_approval_code approval_code,
				   xaord.store_number "STORE",
				   xaord.ship_from shiploc,
				   xaord.cc_auth_ps2000 net_data,
				   xaord.merchant_number merchant_id,
				   NULL sa_payment_source   -- not used for POE_INT_STORE_CUST
										 ,
				   xaord.credit_card_code credit_card_type,
				   xaord.cash_receipt_id cash_receipt_id,
				   NULL ref_receipt_id   -- not used for POE_INT_STORE_CUST
									  ,
				   NULL payment_server_id   -- not used for POE_INT_STORE_CUST
										 ,
				   xaord.receipt_method_id receipt_method_id,
				   xaord.additional_auth_codes additional_auth_codes,
				   /*TO_CHAR(xaord.receipt_date,					-- Modified the code changes for version 48.8
						   'MMDDYYYY') ixdate,*/
					NVL(TO_CHAR(op.credit_card_approval_date,
								'MMDDYYYY'),
						TO_CHAR(xaord.receipt_date,
								'MMDDYYYY')) ixdate,		
				   '000000' ixtime,
				   xaord.customer_id pay_from_customer,
				   xaord.customer_site_billto_id customer_site_use_id,
				   ABS(xaord.payment_amount)
				   * 100 ixamount,
				   ABS(op.attribute1)* 100 ixreserved20, --Added for NAIT-131811
				   xaord.single_pay_ind single_pay_ind,
				   xaord.order_source order_source,
				   xaord.order_number order_number,
				   xaord.order_type sales_order_trans_type,
				   xaord.header_id order_header_id,
				   ooha.sold_to_org_id bill_to_customer_id,
				   ooha.sold_to_org_id ship_to_customer_id,
				   ooha.invoice_to_contact_id bill_to_contact_id,
				   ooha.ship_to_contact_id ship_to_contact_id,
				   ooha.invoice_to_org_id bill_to_site_use_id,
				   ooha.invoice_to_org_id ship_to_site_use_id,
				   hca.account_number customer_number,
				   hca.orig_system_reference cust_orig_system_ref,
				   DECODE(gc_sale_type,
						  'SALE', 'INV',
						  'REFUND', 'CM',
						  NULL) cust_trx_type,
				   hca.cust_account_id cust_account_id,
				   hca.account_number ixcustaccountno,
				   xaord.IDENTIFIER key_label
			INTO   gc_bank_account_num,
				   gc_identifier,
				   gc_cc_exp_date,
				   gn_org_id,
				   gc_receipt_number,
				   gc_recp_attr_category,
				   gc_voice_auth,
				   gc_approval_code,
				   gc_store,
				   gc_shiploc,
				   gc_net_data,
				   gc_merchant_id,
				   gc_sa_payment_source,
				   gc_credit_card_type,
				   gn_cash_receipt_id,
				   gn_ref_receipt_id,
				   gc_payment_server_id,
				   gn_receipt_method_id,
				   gc_additional_auth_codes,
				   gc_ixdate,
				   gc_ixtime,
				   gn_pay_from_customer,
				   gn_customer_site_use_id,
				   gc_ixamount,
				   gc_ixreserved20,--Added for NAIT-131811
				   gc_single_pay_ind,
				   gc_order_source,
				   gn_order_number,
				   gc_sales_order_trans_type,
				   gn_order_header_id,
				   gn_bill_to_customer_id,
				   gn_ship_to_customer_id,
				   gn_bill_to_contact_id,
				   gn_ship_to_contact_id,
				   gn_bill_to_site_use_id,
				   gn_ship_to_site_use_id,
				   gc_customer_number,
				   gc_cust_orig_system_ref,
				   gc_cust_trx_type,
				   gn_cust_account_id,
				   gc_ixcustaccountno,
				   gc_key_label
			FROM   xx_ar_order_receipt_dtl xaord, oe_order_headers_all ooha, hz_cust_accounts hca
			,oe_payments op --Added for NAIT-131811
			WHERE  xaord.order_payment_id = gn_order_payment_id
			AND    xaord.header_id = ooha.header_id
			AND    ooha.header_id = op.header_id(+) --Added for NAIT-131811
			AND    xaord.payment_number = op.payment_number(+) --Added for NAIT-131811
			AND    ooha.sold_to_org_id = hca.cust_account_id;
		ELSIF gc_remit_processing_type = g_ccrefund
		THEN
			-- Receipt amount for CCREFUND
			-- Modified for defect 13466 - revised query to eliminate join to order lines
			xx_location_and_log(g_loc,
								'Retrieving the Receipt information for CCREFUND Remittance Processing Type. ');

			SELECT xaord.credit_card_number bank_account_num,
				   xaord.IDENTIFIER,
				   xaord.credit_card_expiration_date cc_exp_date,
				   xaord.org_id org_id,
				   xaord.receipt_number receipt_number,
				   'CCREFUND' recp_attr_category   -- not used for CCREFUND, but defaulting one for consistency now)
												,
				   DECODE(xaord.cc_auth_manual,
						  'Y', '1',
						  '1', '1',
						  '2') voice_auth   -- using same logic from xx_ar_prepayments
										 ,
				   xaord.credit_card_approval_code approval_code,
				   xaord.store_number "STORE",
				   xaord.ship_from shiploc,
				   xaord.cc_auth_ps2000 net_data,
				   acr.attribute5 merchant_id,
				   acr.attribute11 sa_payment_source,
				   acr.attribute14 credit_card_type,
				   xaord.cash_receipt_id cash_receipt_id,
				   acr.reference_id ref_receipt_id,
				   acr.payment_server_order_num payment_server_id,
				   xaord.receipt_method_id receipt_method_id,
				   xaord.additional_auth_codes additional_auth_codes,
				   TO_CHAR(acr.receipt_date,
						   'MMDDYYYY') ixdate,
				   '000000' ixtime,
				   acr.pay_from_customer pay_from_customer,
				   acr.customer_site_use_id customer_site_use_id,
				   NVL(  ABS(ara.amount_applied)
					   * 100,
					   0) ixamount,
				   NVL(ABS(op.attribute1)* 100 ,0) ixreserved20, --Added for NAIT-131811
				   xaord.single_pay_ind single_pay_ind,
				   xaord.order_source order_source,
				   xaord.order_number order_number,
				   xaord.order_type sales_order_trans_type,
				   xaord.header_id order_header_id,
				   DECODE(gc_sale_type,
						  'SALE', 'INV',
						  'REFUND', 'CM',
						  NULL) cust_trx_type,
				   xaord.IDENTIFIER key_label,
				   xaord.customer_id --added for defect #31270
			INTO   gc_bank_account_num,
				   gc_identifier,
				   gc_cc_exp_date,
				   gn_org_id,
				   gc_receipt_number,
				   gc_recp_attr_category,
				   gc_voice_auth,
				   gc_approval_code,
				   gc_store,
				   gc_shiploc,
				   gc_net_data,
				   gc_merchant_id,
				   gc_sa_payment_source,
				   gc_credit_card_type,
				   gn_cash_receipt_id,
				   gn_ref_receipt_id,
				   gc_payment_server_id,
				   gn_receipt_method_id,
				   gc_additional_auth_codes,
				   gc_ixdate,
				   gc_ixtime,
				   gn_pay_from_customer,
				   gn_customer_site_use_id,
				   gc_ixamount,
				   gc_ixreserved20,--Added for NAIT-131811
				   gc_single_pay_ind,
				   gc_order_source,
				   gn_order_number,
				   gc_sales_order_trans_type,
				   gn_order_header_id,
				   gc_cust_trx_type,
				   gc_key_label,
				   gn_cust_account_id --added for defect #31270
			FROM   xx_ar_order_receipt_dtl xaord,
				   ar_cash_receipts_all acr,
				   ar_receipt_methods arm,
				   ar_receivable_applications_all ara,
				   oe_payments op --Added for NAIT-131811
			WHERE  xaord.order_payment_id = gn_order_payment_id
			AND    xaord.cash_receipt_id = acr.cash_receipt_id
			AND    acr.receipt_method_id = arm.receipt_method_id
			AND    ara.cash_receipt_id = acr.cash_receipt_id
			AND    xaord.header_id = op.header_id(+) --Added for NAIT-131811
			AND    xaord.payment_number = op.payment_number(+) --Added for NAIT-131811
			AND    ara.status = 'APP'
			AND    ara.amount_applied < 0
			AND    ara.display = 'Y';
		ELSIF gc_remit_processing_type=g_service_contracts then --Added for V47.0 5/Mar/2018

			xx_location_and_log
						  (g_loc,
						   'Retrieving the Receipt information for Service Contracts Remittance Processing Type. ');
			DBMS_OUTPUT.put_line(   'gc_remit_processing_type:'
								 || gc_remit_processing_type
								 || 'gn_cash_receipt_id'
								 || gn_cash_receipt_id);

			SELECT xaord.credit_card_number bank_account_num,
				   xaord.IDENTIFIER,
				   xaord.credit_card_expiration_date cc_exp_date,
				   acr.org_id org_id,
				   acr.receipt_number receipt_number,
				   acr.attribute_category recp_attr_category,
				   acr.attribute3 voice_auth,
				   xaord.credit_card_approval_code approval_code,
				   NVL(acr.attribute1,g_servc_contract_store_number) "STORE"
												 ,
				   acr.attribute2 shiploc,
				   acr.attribute4 net_data,
				   acr.attribute5 merchant_id,
				   acr.attribute11 sa_payment_source,
				   acr.attribute14 credit_card_type,
				   acr.cash_receipt_id cash_receipt_id,
				   acr.reference_id ref_receipt_id,
				   acr.payment_server_order_num payment_server_id,
				   acr.receipt_method_id receipt_method_id,
				   xaord.additional_auth_codes additional_auth_codes,
				   TO_CHAR(acr.receipt_date,
						   'MMDDYYYY') ixdate,
				   '000000' ixtime,
				   acr.pay_from_customer pay_from_customer,
				   acr.customer_site_use_id customer_site_use_id,
					 /*    ABS(gc_ixamount)
					   * 100 ixamount                                                       -- receipt amount from servlet*/
				   ABS(xaord.payment_amount)
				   * 100 ixamount,
				   ABS(op.attribute1)* 100 ixreserved20, --Added for NAIT-131811,
				   xaord.single_pay_ind single_pay_ind,
				   xaord.order_source order_source,
				   xaord.order_number order_number,
				   xaord.IDENTIFIER key_label,
				   acr.Payment_Trxn_Extension_Id
			INTO   gc_bank_account_num,
				   gc_identifier,
				   gc_cc_exp_date,
				   gn_org_id,
				   gc_receipt_number,
				   gc_recp_attr_category,
				   gc_voice_auth,
				   gc_approval_code,
				   gc_store,
				   gc_shiploc,
				   gc_net_data,
				   gc_merchant_id,
				   gc_sa_payment_source,
				   gc_credit_card_type,
				   gn_cash_receipt_id,
				   gn_ref_receipt_id,
				   gc_payment_server_id,
				   gn_receipt_method_id,
				   gc_additional_auth_codes,
				   gc_ixdate,
				   gc_ixtime,
				   gn_pay_from_customer,
				   gn_customer_site_use_id,
				   gc_ixamount,
				   gc_ixreserved20,--Added for NAIT-131811
				   gc_single_pay_ind,
				   gc_order_source,
				   gn_order_number,
				   gc_key_label,
				   vn_Payment_Trxn_Extension_Id
			FROM   ar_cash_receipts_all acr, xx_ar_order_receipt_dtl xaord
			,oe_payments op --Added for NAIT-131811
			WHERE  xaord.order_payment_id = gn_order_payment_id
			AND    xaord.header_id = op.header_id(+) --Added for NAIT-131811
			AND    xaord.payment_number = op.payment_number(+) --Added for NAIT-131811
			--acr.cash_receipt_id = gn_cash_receipt_id
			AND    acr.cash_receipt_id = xaord.cash_receipt_id;
		ELSE
			-- Receipt amount for non-POE_INT_STORE_CUST is being passed in by the custom servlet called during remittance
			xx_location_and_log
						  (g_loc,
						   'Retrieving the Receipt information for non-POE_INT_STORE_CUST Remittance Processing Type. ');
			DBMS_OUTPUT.put_line(   'gc_remit_processing_type:'
								 || gc_remit_processing_type
								 || 'gn_cash_receipt_id'
								 || gn_cash_receipt_id);

			SELECT xaord.credit_card_number bank_account_num,
				   xaord.IDENTIFIER,
				   xaord.credit_card_expiration_date cc_exp_date,
				   acr.org_id org_id,
				   acr.receipt_number receipt_number,
				   acr.attribute_category recp_attr_category,
				   acr.attribute3 voice_auth,
				   xaord.credit_card_approval_code approval_code,
				   DECODE(gc_remit_processing_type,
						  g_irec, g_irec_store_number,
						  acr.attribute1) "STORE"   --Defect 12713
												 ,
				   acr.attribute2 shiploc,
				   acr.attribute4 net_data,
				   acr.attribute5 merchant_id,
				   acr.attribute11 sa_payment_source,
				   acr.attribute14 credit_card_type,
				   acr.cash_receipt_id cash_receipt_id,
				   acr.reference_id ref_receipt_id,
				   acr.payment_server_order_num payment_server_id,
				   acr.receipt_method_id receipt_method_id,
				   xaord.additional_auth_codes additional_auth_codes,
				   /*TO_CHAR(acr.receipt_date,							-- Modified the code changes for version 48.8
						   'MMDDYYYY') ixdate,*/
					NVL(TO_CHAR(op.credit_card_approval_date,
								'MMDDYYYY'),
						TO_CHAR(acr.receipt_date,
								'MMDDYYYY')) ixdate,
				   '000000' ixtime,
				   acr.pay_from_customer pay_from_customer,
				   acr.customer_site_use_id customer_site_use_id,
					 /*    ABS(gc_ixamount)
					   * 100 ixamount                                                       -- receipt amount from servlet*/
				   ABS(xaord.payment_amount)
				   * 100 ixamount,
				   ABS(op.attribute1)* 100 ixreserved20, --Added for NAIT-131811
				   xaord.single_pay_ind single_pay_ind,
				   xaord.order_source order_source,
				   xaord.order_number order_number,
				   xaord.IDENTIFIER key_label,
				   acr.Payment_Trxn_Extension_Id
			INTO   gc_bank_account_num,
				   gc_identifier,
				   gc_cc_exp_date,
				   gn_org_id,
				   gc_receipt_number,
				   gc_recp_attr_category,
				   gc_voice_auth,
				   gc_approval_code,
				   gc_store,
				   gc_shiploc,
				   gc_net_data,
				   gc_merchant_id,
				   gc_sa_payment_source,
				   gc_credit_card_type,
				   gn_cash_receipt_id,
				   gn_ref_receipt_id,
				   gc_payment_server_id,
				   gn_receipt_method_id,
				   gc_additional_auth_codes,
				   gc_ixdate,
				   gc_ixtime,
				   gn_pay_from_customer,
				   gn_customer_site_use_id,
				   gc_ixamount,
				   gc_ixreserved20,--Added for NAIT-131811
				   gc_single_pay_ind,
				   gc_order_source,
				   gn_order_number,
				   gc_key_label,
				   vn_Payment_Trxn_Extension_Id
			FROM   ar_cash_receipts_all acr, xx_ar_order_receipt_dtl xaord
			,oe_payments op --Added for NAIT-131811
			WHERE  xaord.order_payment_id = gn_order_payment_id
			AND    xaord.header_id = op.header_id(+) --Added for NAIT-131811 
			AND    xaord.payment_number = op.payment_number(+) --Added for NAIT-131811
			--acr.cash_receipt_id = gn_cash_receipt_id
			AND    acr.cash_receipt_id = xaord.cash_receipt_id;
		END IF;

		-- Added by AG

		xx_location_and_log(g_log, 'gc_payment_server_id :'||gc_payment_server_id || 'vn_Payment_Trxn_Extension_Id :'||vn_Payment_Trxn_Extension_Id);

		IF gc_payment_server_id IS NULL AND vn_Payment_Trxn_Extension_Id IS NOT NULL
		THEN
		  BEGIN
			SELECT NVL(ifte.payment_system_order_number,
							   ifte.tangibleid)
			INTO gc_payment_server_id
			FROM Iby_Fndcpt_Tx_Extensions ifte
		   where trxn_extension_id = vn_Payment_Trxn_Extension_Id;
		  EXCEPTION
			WHEN OTHERS
			THEN
			  gc_payment_server_id  := NULL;
			  xx_location_and_log(g_log, ' No data found for gc_payment_server_id');
		  END;
		END IF;

		xx_location_and_log(g_log,
							   'Bank Account Number      : '
							|| SUBSTR(gc_bank_account_num,
									  1,
									  4)
							|| '*****************'
							|| SUBSTR(gc_bank_account_num,
									  -4) );
		xx_location_and_log(g_log,
							   'Credit Card Type         : '
							|| gc_credit_card_type);
		xx_location_and_log(g_log,
							   'Receipt Amount           : '
							|| gc_ixamount);
		xx_location_and_log(g_log,
							   'Original Amount          : '
							|| gc_ixreserved20);--Added for NAIT-131811
		xx_location_and_log(g_log,
							   'CC Exp Date              : '
							|| gc_cc_exp_date);
		xx_location_and_log(g_log,
							   'ORG ID                   : '
							|| gn_org_id);
		xx_location_and_log(g_log,
							   'Single Payment Indicator : '
							|| gc_single_pay_ind);
		xx_location_and_log(g_log,
							   'Receipt Number           : '
							|| gc_receipt_number);
		xx_location_and_log(g_log,
							   'Receipt Att Category     : '
							|| gc_recp_attr_category);
		xx_location_and_log(g_log,
							   'Voice Auth               : '
							|| gc_voice_auth);
		xx_location_and_log(g_log,
							   'Approval Code            : '
							|| gc_approval_code);
		xx_location_and_log(g_log,
							   'Additional Auth Codes    : '
							|| gc_additional_auth_codes);
		xx_location_and_log(g_log,
							   'Store                    : '
							|| gc_store);
		xx_location_and_log(g_log,
							   'Ship Location            : '
							|| gc_shiploc);
		xx_location_and_log(g_log,
							   'Net Data                 : '
							|| gc_net_data);
		xx_location_and_log(g_log,
							   'Merchant ID              : '
							|| gc_merchant_id);
		xx_location_and_log(g_log,
							   'SA Payment Source        : '
							|| gc_sa_payment_source);
		xx_location_and_log(g_log,
							   'Receipt ID               : '
							|| gn_cash_receipt_id);
		xx_location_and_log(g_log,
							   'Receipt Method ID        : '
							|| gn_receipt_method_id);
		xx_location_and_log(g_log,
							   'Receipt Reference ID     : '
							|| gn_ref_receipt_id);
		xx_location_and_log(g_log,
							   'Payment Server ID        : '
							|| gc_oapforder_id);
		xx_location_and_log(g_log,
							   'Date                     : '
							|| gc_ixdate);
		xx_location_and_log(g_log,
							   'Time                     : '
							|| gc_ixtime);
		xx_location_and_log(g_log,
							   'Derived TRX Type         : '
							|| gc_cust_trx_type);
		xx_location_and_log(g_log,
							   'Sales order Trans Type   : '
							|| gc_sales_order_trans_type);
		xx_location_and_log(g_log,
							   'Order Source             : '
							|| gc_order_source);
		xx_location_and_log(g_log,
							   'Order Header ID          : '
							|| gn_order_header_id);
		xx_location_and_log(g_log,
							   'Order Number             : '
							|| gn_order_number);
		xx_location_and_log(g_log,
							   'Customer Number          : '
							|| gc_customer_number);
		xx_location_and_log(g_log,
							   'Customer Account Number  : '
							|| gc_ixcustaccountno);
		xx_location_and_log(g_log,
							   'Customer Account ID      : '
							|| gn_cust_account_id);
		xx_location_and_log(g_log,
							   'Cust Orig System Ref     : '
							|| gc_cust_orig_system_ref);
		xx_location_and_log(g_log,
							   'Customer Site Use ID     : '
							|| gn_customer_site_use_id);
		xx_location_and_log(g_log,
							   'Pay From Customer        : '
							|| gn_pay_from_customer);
		xx_location_and_log(g_log,
							   'Bill To Customer ID      : '
							|| gn_bill_to_customer_id);
		xx_location_and_log(g_log,
							   'Ship To Customer ID      : '
							|| gn_ship_to_customer_id);
		xx_location_and_log(g_log,
							   'Bill To Contact ID       : '
							|| gn_bill_to_contact_id);
		xx_location_and_log(g_log,
							   'Ship To Contact ID       : '
							|| gn_ship_to_contact_id);
		xx_location_and_log(g_log,
							   'Bill To Site Use ID      : '
							|| gn_bill_to_site_use_id);
		xx_location_and_log(g_log,
							   'Ship To Site Use ID      : '
							|| gn_ship_to_site_use_id);
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			xx_location_and_log(g_loc,
								'Entering NO_DATA_FOUND Exception in XX_RETRIEVE_RECEIPT_INFO. ');
			RAISE ex_no_receipt_info;
		WHEN TOO_MANY_ROWS
		THEN
			xx_location_and_log(g_loc,
								'Entering TOO_MANY_ROWS Exception in XX_RETRIEVE_RECEIPT_INFO. ');
			RAISE ex_too_many_receipts;
	END xx_retrieve_receipt_info;

-- +====================================================================+
-- | PROCEDURE  : XX_SET_POST_RECEIPT_VARIABLES                         |
-- |                                                                    |
-- | DESCRIPTION: Sets various package variables after receipt has been |
-- |              retrieved.                                            |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_set_post_receipt_variables
	IS
		la_addl_auth_codes_tab  stringarray    DEFAULT stringarray();
		lc_err_msg              VARCHAR2(2000);
		--Version 27.0
		lc_emv_card             xx_ar_order_receipt_dtl.emv_card%TYPE;
		lc_emv_terminal         xx_ar_order_receipt_dtl.emv_terminal%TYPE;
		lc_emv_transaction      xx_ar_order_receipt_dtl.emv_transaction%TYPE;
		lc_emv_offline          xx_ar_order_receipt_dtl.emv_offline%TYPE;
		lc_emv_fallback         xx_ar_order_receipt_dtl.emv_fallback%TYPE;
		lc_emv_tvr              xx_ar_order_receipt_dtl.emv_tvr%TYPE;
	BEGIN
--------------------------------------------------------------------------
-- Decrypt Bank Account Number  Encrypt Credit Card Number
--------------------------------------------------------------------------
		BEGIN
--            xx_location_and_log(g_loc,
--                                'Decrypting Credit Card Number. ');
--            gc_error_debug :=
--                   'Decrypting Credit Card Number: '
--                || SUBSTR(gc_bank_account_num,
--                          1,
--                          4)
--                || '*****************'
--                || SUBSTR(gc_bank_account_num,
--                          -4);
			gc_bank_account_num_org := gc_bank_account_num;
			gc_encrypted_cc_num := gc_bank_account_num;
--            DBMS_SESSION.set_context(namespace      => 'XX_IBY_CONTEXT',
--                                     ATTRIBUTE      => 'TYPE',
--                                     VALUE          => 'EBS');
--            xx_od_security_key_pkg.decrypt(p_module             => 'AJB',
--                                           p_key_label          => gc_identifier,
--                                           p_encrypted_val      => gc_bank_account_num,
--                                           p_algorithm          => '3DES',
--                                           x_decrypted_val      => gc_bank_account_num,
--                                           x_error_message      => lc_err_msg);

			--            IF (gc_bank_account_num) IS NULL OR lc_err_msg IS NOT NULL
--            THEN
--                xx_location_and_log(g_log,
--                                       'Unable to decrypt bank acc:'
--                                    || gc_bank_account_num_org
--                                    || ' '
--                                    || lc_err_msg);
--                RAISE ex_cc_decrytpt;
--            END IF;

			--            xx_location_and_log(g_loc,
--                                'Encrypting the Credit Card Number. ');
--            gc_error_debug :=
--                   'Error in Encrpt Logic at: '
--                || gc_error_loc
--                || '. Credit Card Number: '
--                || SUBSTR(gc_bank_account_num,
--                          1,
--                          4)
--                || '*****************'
--                || SUBSTR(gc_bank_account_num,
--                          -4);
--            DBMS_SESSION.set_context(namespace      => 'XX_IBY_CONTEXT',
--                                     ATTRIBUTE      => 'TYPE',
--                                     VALUE          => 'EBS');
--            xx_od_security_key_pkg.encrypt_outlabel(p_module             => 'AJB',
--                                                    p_key_label          => NULL,
--                                                    p_algorithm          => '3DES',
--                                                    p_decrypted_val      => gc_bank_account_num,
--                                                    x_encrypted_val      => gc_encrypted_cc_num,
--                                                    x_error_message      => gc_cc_encrypt_error_message,
--                                                    x_key_label          => gc_key_label);
------------------------------------------------------
-- Set IXACCOUNT to Encrypted CC Number
------------------------------------------------------
			gc_ixaccount := gc_encrypted_cc_num;
			xx_location_and_log(g_log,
								   'After Encrypting CC      : '
								|| gc_encrypted_cc_num);
			xx_location_and_log(g_log,
								   'Encrypt Error Message    : '
								|| gc_cc_encrypt_error_message);

			IF    (gc_cc_encrypt_error_message IS NOT NULL)
			   OR (gc_encrypted_cc_num IS NULL)
			THEN
				gc_error_debug :=
					   'Error in Encryption Logic: '
					|| gc_cc_encrypt_error_message
					|| '. Encrypted Value: '
					|| gc_encrypted_cc_num;
				RAISE ex_cc_encrytpt;
			END IF;
		END;

--------------------------------------------------------------------------
-- Set/Format Expiration Date (IXEXPDATE)
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Set/Formation CC Expiration Date. ');
			gc_ixexpdate := TO_CHAR(gc_cc_exp_date,
									'YYMM');
			xx_location_and_log(g_log,
								   'IXEXPDATE                : '
								|| gc_ixexpdate);
		END;

		-- defect 13321 removed entire duplicate tangible id check

		--------------------------------------------------------------------------
-- Retrieve OU Information
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving the OU Name. ');
			gc_error_debug :=    'Org ID: '
							  || gn_org_id;

			SELECT NAME
			INTO   gc_org_name
			FROM   hr_all_organization_units haou
			WHERE  haou.organization_id = gn_org_id;

			xx_location_and_log(g_log,
								   'Organization Name        : '
								|| gc_org_name);
			xx_location_and_log(g_loc,
								'Retrieving the US OU Description from OD_COUNTRY_DEFAULTS Transalation Definition. ');
			gc_error_debug :=    'Org ID: '
							  || gn_org_id;

			SELECT target_value2
			INTO   gc_ou_us_desc
			FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			WHERE  translation_name = 'OD_COUNTRY_DEFAULTS'
			AND    xftv.translate_id = xftd.translate_id
			AND    xftv.source_value1 = 'US'
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';

			xx_location_and_log(g_log,
								   'OU Description - US      : '
								|| gc_ou_us_desc);
			xx_location_and_log(g_loc,
								'Retrieving the CA OU Description from OD_COUNTRY_DEFAULTS Transalation Definition. ');
			gc_error_debug :=    'Org ID: '
							  || gn_org_id;

			SELECT target_value2
			INTO   gc_ou_ca_desc
			FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			WHERE  translation_name = 'OD_COUNTRY_DEFAULTS'
			AND    xftv.translate_id = xftd.translate_id
			AND    xftv.source_value1 = 'CA'
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';

			xx_location_and_log(g_log,
								   'OU Description - CA      : '
								|| gc_ou_ca_desc);
		END;

--------------------------------------------------------------------------
-- Retrieve Master Organization ID
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving the Master Organization ID. ');
			gc_error_debug :=    'Org ID: '
							  || gn_org_id;

			SELECT mp.master_organization_id
			INTO   gn_master_org_id
			FROM   financials_system_params_all fsp, mtl_parameters mp
			WHERE  fsp.inventory_organization_id = mp.organization_id
			AND    fsp.org_id = gn_org_id;

			xx_location_and_log(g_log,
								   'Master Org ID            : '
								|| gn_master_org_id);
		END;

--------------------------------------------------------------------------
-- Initialize IXOPTION (for SALE only)
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Setting IXOPTION for Sale Type of SALE. ');

			IF gc_sale_type = g_sale
			THEN
				IF    (    gc_remit_processing_type = g_poe_int_store_cust
					   AND gc_voice_auth = '1')
				   OR (    gc_recp_attr_category = 'SALES_ACCT'
					   AND gc_voice_auth = '1')
				THEN
					gc_ixoptions := gc_referral_value;
				ELSE
					gc_ixoptions := NULL;
				END IF;
			END IF;

			xx_location_and_log(g_log,
								   'Receipt Attrib. Category : '
								|| gc_recp_attr_category);
			xx_location_and_log(g_log,
								   'Referral Value           : '
								|| gc_referral_value);
			xx_location_and_log(g_log,
								   'Voice Auth               : '
								|| gc_voice_auth);
			xx_location_and_log(g_log,
								   'IXOPTIONS                : '
								|| gc_ixoptions);
		END;

--------------------------------------------------------------------------
-- Retrieve CVV/AVS Code and Auth Entry Mode
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving CVV/AVS Code and Auth Entry Mode based on Remittance Processing Type. ');

			IF gc_remit_processing_type = g_poe_int_store_cust
			THEN
				xx_location_and_log
					(g_loc,
					 'Retrieving CVV/AVS Code and Auth Entry Mode based for POE_INT_STORE_CUST Remittance Processing Type. ');
				xx_location_and_log
						(g_loc,
						 '***** Executing XX_EXPLODE_ADDL_AUTH_CODES function from XX_SET_POST_RECEIPT_VARIABLES ***** ');
				la_addl_auth_codes_tab :=
									xx_explode_addl_auth_codes(p_string =>         gc_additional_auth_codes,
															   p_delimiter =>      ':');
				gc_error_debug :=    gc_error_debug
								  || '. Array Count = '
								  || la_addl_auth_codes_tab.COUNT;

				IF (la_addl_auth_codes_tab.COUNT >= 4)
				THEN
					gc_cc_entry_mode := la_addl_auth_codes_tab(1);
					gc_cvv_resp_code := la_addl_auth_codes_tab(2);
					gc_avs_resp_code := la_addl_auth_codes_tab(3);
					gc_auth_entry_mode := la_addl_auth_codes_tab(4);
				END IF;
			ELSE
				xx_location_and_log
					(g_loc,
					 'Retrieving CVV/AVS Code and Auth Entry Mode based for NON-POE_INT_STORE_CUST Remittance Processing Type. ');

				SELECT cvv_resp_code,
					   avs_resp_code,
					   auth_entry_mode
				INTO   gc_cvv_resp_code,
					   gc_avs_resp_code,
					   gc_auth_entry_mode
				FROM   xx_ar_cash_receipts_ext xacre
				WHERE  xacre.cash_receipt_id = gn_cash_receipt_id;
			END IF;

			IF (gc_cvv_resp_code IS NOT NULL)
			THEN
				gc_ixoptions :=    gc_ixoptions
								|| ' '
								|| gc_cvv_resp_value
								|| gc_cvv_resp_code;
			END IF;
		EXCEPTION
			WHEN OTHERS
			THEN
				xx_location_and_log
					(g_loc,
					 'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Retrieve CVV/AVS Code and Auth Entry Mode. ');
				gc_cvv_resp_code := NULL;
				gc_avs_resp_code := NULL;
				gc_auth_entry_mode := NULL;
		END;

		xx_location_and_log(g_log,
							   'CVV Resp Code            : '
							|| gc_cvv_resp_code);
		xx_location_and_log(g_log,
							   'AVS Resp Code            : '
							|| gc_avs_resp_code);
		xx_location_and_log(g_log,
							   'CC Entry Mode            : '
							|| gc_cc_entry_mode);
		xx_location_and_log(g_log,
							   'Auth Entry Mode          : '
							|| gc_auth_entry_mode);
		xx_location_and_log(g_log,
							   'IXOPTIONS                : '
							|| gc_ixoptions);

--------------------------------------------------------------------------
-- Retrieve CC Entry Count
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving CC Entry Count from OD_IBY_CC_ENTRY_MODE translation definition. ');

			SELECT COUNT(source_value1)
			INTO   gn_cc_entry_count
			FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			WHERE  translation_name = 'OD_IBY_CC_ENTRY_MODE'
			AND    xftv.translate_id = xftd.translate_id
			AND    xftv.source_value1 = gc_cc_entry_mode
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';
		EXCEPTION
			WHEN OTHERS
			THEN
				xx_location_and_log
					(g_loc,
					 'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Retrieve Retrieve CC Entry Count. ');
				gn_cc_entry_count := 0;
		END;

		xx_location_and_log(g_log,
							   'CC Entry Count           : '
							|| gn_cc_entry_count);

--------------------------------------------------------------------------
-- Retrieve AOPS and POS Auth Entry
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log
					(g_loc,
					 'Retrieving CVV/AVS Code and Auth Entry Mode from OD_IBY_AUTH_ENTRY_MODE translation definition. ');

			SELECT target_value1,
				   target_value2
			INTO   gc_aops_auth_entry,
				   gc_pos_auth_entry
			FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			WHERE  translation_name = 'OD_IBY_AUTH_ENTRY_MODE'
			AND    xftv.translate_id = xftd.translate_id
			AND    xftv.source_value1 = gc_auth_entry_mode
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';
		EXCEPTION
			WHEN OTHERS
			THEN
				xx_location_and_log
					(g_loc,
					 'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Retrieve AOPS and POS Auth Entry. ');
				gc_aops_auth_entry := NULL;
				gc_pos_auth_entry := NULL;
		END;

		xx_location_and_log(g_log,
							   'AOPS Auth Entry          : '
							|| gc_aops_auth_entry);
		xx_location_and_log(g_log,
							   'POS Auth Entry           : '
							|| gc_pos_auth_entry);

--------------------------------------------------------------------------
-- Retrieve Credit Card Name from OD_IBY_CREDIT_CARD_TYPE
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving the Card Name from OD_IBY_CREDIT_CARD_TYPE translation definition. ');
			gc_error_debug :=    'Credit Card Type: '
							  || gc_credit_card_type;

			SELECT target_value1
			INTO   gc_card_name
			FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			WHERE  translation_name = 'OD_IBY_CREDIT_CARD_TYPE'
			AND    xftv.translate_id = xftd.translate_id
			AND    xftv.source_value1 = gc_credit_card_type
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';

			xx_location_and_log(g_log,
								   'Credit Card Name         : '
								|| gc_card_name);
			gc_ixreserved43 := NULL;
			xx_location_and_log(g_loc,
								'Parse Net Data and Set IXOPTIONS. ');
			gc_error_debug :=    'Net Data: '
							  || gc_net_data;

			IF (    gc_net_data IS NOT NULL
				AND gc_credit_card_type IS NOT NULL)
			THEN
				IF (gc_card_name = g_master_card_type)
				THEN
					xx_location_and_log(g_loc,
										'Parsing Net Data for Master Card. ');
					gc_error_debug :=    gc_error_debug
									  || '. Card Type: '
									  || g_master_card_type;
					gc_aci_indicator := SUBSTR(gc_net_data,
											   30,
											   1);
					gc_banknetdate := SUBSTR(gc_net_data,
											 12,
											 4);
					gc_banknetreference := SUBSTR(gc_net_data,
												  3,
												  9);
					gc_authorization_source := SUBSTR(gc_net_data,
													  1,
													  1);
					gc_ixps2000 :=
						   gc_aci_indicator
						|| gc_banknetdate
						|| gc_banknetreference
						|| gc_fiegd_sep
						|| gc_master_auth_source
						|| gc_authorization_source;
				END IF;

				IF (gc_card_name = g_visa_card_type)
				THEN
					xx_location_and_log(g_loc,
										'Parsing Net Data for Visa. ');
					gc_error_debug :=    gc_error_debug
									  || '. Card Type: '
									  || g_visa_card_type;
					gc_aci_indicator := SUBSTR(gc_net_data,
											   7,
											   1);
					gc_transaction_identifier := SUBSTR(gc_net_data,
														8,
														15);
					gc_validation_code := SUBSTR(gc_net_data,
												 23,
												 4);
					gc_visa_53 := SUBSTR(gc_net_data,
										 5,
										 2);
					gc_ixreserved53 := gc_visa_53;
					gc_ixps2000 :=
						   gc_aci_indicator
						|| gc_transaction_identifier
						|| gc_validation_code
						|| gc_fiegd_sep
						|| gc_visa_auth_source;
					gc_ixoptions :=    gc_ixoptions
									|| ' '
									|| gc_cardlevel_value
									|| SUBSTR(gc_net_data,
											  2,
											  3);
				END IF;

				IF (gc_card_name = g_disc_card_type)
				THEN
					xx_location_and_log(g_loc,
										'Parsing Net Data for Discover. ');
					gc_error_debug :=    gc_error_debug
									  || '. Card Type: '
									  || g_disc_card_type;
					gc_ixps2000 := SUBSTR(gc_net_data,
										  8,
										  15);
				END IF;

				IF (gc_card_name = g_amex_card_type)
				THEN
					xx_location_and_log(g_loc,
										'Parsing Net Data for AMEX. ');
					gc_error_debug :=    gc_error_debug
									  || '. Card Type: '
									  || g_amex_card_type;
					gc_ixps2000 := SUBSTR(gc_net_data,
										  1,
										  15);
					gc_ixreserved43 := SUBSTR(gc_net_data,
											  16,
											  12);
				END IF;

				xx_location_and_log(g_log,
									   'Card Name                : '
									|| gc_card_name);
				xx_location_and_log(g_log,
									   'ACI Indicator            : '
									|| gc_aci_indicator);
				xx_location_and_log(g_log,
									   'Bank Net Date            : '
									|| gc_banknetdate);
				xx_location_and_log(g_log,
									   'Bank Net Reference       : '
									|| gc_banknetreference);
				xx_location_and_log(g_log,
									   'Authorization Source     : '
									|| gc_authorization_source);
				xx_location_and_log(g_log,
									   'ixps2000                 : '
									|| gc_ixps2000);
				xx_location_and_log(g_log,
									   'Transaction Identifier   : '
									|| gc_transaction_identifier);
				xx_location_and_log(g_log,
									   'Validation Code          : '
									|| gc_validation_code);
				xx_location_and_log(g_log,
									   'Visa 53                  : '
									|| gc_visa_53);
				xx_location_and_log(g_log,
									   'ixreserved53             : '
									|| gc_ixreserved53);
				xx_location_and_log(g_log,
									   'ixreserved43             : '
									|| gc_ixreserved43);
				xx_location_and_log(g_log,
									   'ixoptions                : '
									|| gc_ixoptions);
			END IF;
		EXCEPTION
			WHEN OTHERS
			THEN
				xx_location_and_log
					(g_loc,
					 'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Retrieve Credit Card Name from OD_IBY_CREDIT_CARD_TYPE. ');
				gc_master_auth_source := NULL;
				gc_visa_auth_source := NULL;
				gc_card_name := NULL;
				xx_location_and_log(g_log,
									   'Master Auth Source       : '
									|| gc_master_auth_source);
				xx_location_and_log(g_log,
									   'Visa Auth Source         : '
									|| gc_visa_auth_source);
				xx_location_and_log(g_log,
									   'Card Name                : '
									|| gc_card_name);
		END;

-------------------------------------------------------------------------------
-- Retrieve TRXNMID (non-POE_INT_STORE_CUST) and Credit Card Vendor (for all)
-------------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieve/Set TRXNMID and Credit Card Vendor based on Remittance Processing Type. ');

			IF gc_remit_processing_type = g_poe_int_store_cust
			THEN
				xx_location_and_log(g_loc,
									'Set Credit Card Vendor for POE_INT_STORE_CUST Remittance Processing Type. ');
				gc_credit_card_vendor := gc_card_name;

			Elsif 	gc_remit_processing_type = g_service_contracts--Added for V47.0 5/Mar/2018
			THEN

			xx_location_and_log(g_loc,
									'Set Credit Card Vendor for SERVICE-CONTRACTS Remittance Processing Type. ');
				gc_credit_card_vendor := gc_card_name;

			ELSE
				xx_location_and_log
					 (g_loc,
					  'Retrieve TRXNMID and Credit Card Vendor for NON-POE_INT_STORE_CUST Remittance Processing Type. ');

				BEGIN
					IF gc_sale_type = g_sale
					THEN
						xx_location_and_log
							(g_loc,
							 'Retrieve TRXNMID and Credit Card Vendor for NON-POE_INT_STORE_CUST Remittance Sale Type (SALE). ');

						xx_location_and_log
							(g_loc, 'Payment server id :'||gc_payment_server_id );

						SELECT its.trxnmid,
							   its.instrsubtype
						INTO   gn_trxnmid,
							   gc_credit_card_vendor
						FROM   iby_trxn_summaries_all its
						WHERE  its.tangibleid = gc_payment_server_id
						AND    its.reqtype = 'ORAPMTREQ'
						AND    its.status = '0';
					ELSIF gc_sale_type = g_refund
					THEN
						xx_location_and_log
							(g_loc,
							 'Retrieve TRXNMID and Credit Card Vendor for NON-POE_INT_STORE_CUST Sale Type (RETURN/REFUND). ');

						SELECT its.trxnmid,
							   its.instrsubtype
						INTO   gn_trxnmid,
							   gc_credit_card_vendor
						FROM   iby_trxn_summaries_all its
						WHERE  its.tangibleid = gc_payment_server_id
						AND    (    (its.reqtype = 'ORAPMTCREDIT')
								OR (its.reqtype = 'ORAPMTCAPTURE') )
						AND    its.status = '0';
					END IF;

					xx_location_and_log(g_log,
										   'Trxnmid                  : '
										|| gn_trxnmid);
					xx_location_and_log(g_log,
										   'Credit Card Vendor       : '
										|| gc_credit_card_vendor);
				EXCEPTION
					WHEN OTHERS
					THEN
						xx_location_and_log
							  (g_loc,
							   'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Retrieve TRXNMID. ');
						gn_trxnmid := NULL;
						gc_credit_card_vendor := gc_card_name;
						xx_location_and_log(g_log,
											   'Trxnmid                  : '
											|| gn_trxnmid);
						xx_location_and_log(g_log,
											   'Credit Card Vendor       : '
											|| gc_credit_card_vendor);
				END;
			END IF;
		END;

		-- Defect 13466 - moved Process NET_DATA AMEX CPC CARD code to XX_SET_POST_TRX_VARIABLES

--------------------------------------------------------------------------
-- Retrieve IXISSUENUMBER
--------------------------------------------------------------------------
/* 26.5 Mod 4A
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving IXISSUENUMBER based on Remittance Processing Type. ');

			-- MOD 4A
			IF gc_remit_processing_type = g_poe_int_store_cust
			THEN
				xx_location_and_log(g_loc,
									'Retrieving IXISSUENUMBER for POE_INT_STORE_CUST Remittance Processing Type. ');

				SELECT cc_auth_ps2000
				INTO   gc_ixissuenumber
				FROM   xx_ar_order_receipt_dtl
				WHERE  order_payment_id = gn_order_payment_id
				AND    gc_credit_card_type LIKE 'CITI%';
			ELSE
				xx_location_and_log
								   (g_loc,
									'Retrieving IXISSUENUMBER for NON-POE_INT_STORE_CUST ORemittance Processing Type. ');

				SELECT attribute4
				INTO   gc_ixissuenumber
				FROM   ar_cash_receipts_all
				WHERE  cash_receipt_id = gn_cash_receipt_id
				AND    attribute14 LIKE 'CITI%';
			END IF;
			MOD 4A --
			-- MOD 4A : Added below SQL to retrieve cust_po_number

			SELECT   cust_po_number
			  INTO   gc_ixissuenumber
			  FROM   oe_order_headers_all
			 WHERE   order_number      = gn_order_number
			  AND    rownum            = 1;

			xx_location_and_log(g_log,
								   'ixissuenumber            : '
								|| gc_ixissuenumber);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				xx_location_and_log
					(g_loc,
					 'Entering NO_DATA_FOUND Exception in XX_SET_POST_RECEIPT_VARIABLES for Process Retrieve IXISSUENUMBER.');
				gc_ixissuenumber := NULL;
				xx_location_and_log(g_log,
									   'ixissuenumber     :      '
									|| gc_ixissuenumber || ' - Order #   : ' || gn_order_number || ' - Site Id :' || gn_bill_to_site_use_id );
			WHEN OTHERS
			THEN
				xx_location_and_log
					(g_loc,
					 'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Process Retrieve IXISSUENUMBER.');
				gc_ixissuenumber := NULL;
				xx_location_and_log(g_log,
									   'ixissuenumber     :      '
									|| gc_ixissuenumber || ' - Order #   : ' || gn_order_number || ' - Site Id :' || gn_bill_to_site_use_id );

				xx_location_and_log(g_log,
									   'Error at: '
									|| gc_error_loc
									|| 'Error Message: '
									|| SQLERRM);
		END;
 26.5 Mod 4A*/
--------------------------------------------------------------------------
-- Set Process Indicator
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Setting Process Indicator. ');

			IF (TO_DATE(gc_ixdate,
						'MMDDYYYY') <= SYSDATE)
			THEN
				gn_process_indicator := 1;
			ELSE
				gn_process_indicator := 2;
			END IF;

			xx_location_and_log(g_log,
								   'Process Indicator        : '
								|| gn_process_indicator);
		END;

--------------------------------------------------------------------------
-- Set IXAUTHORIZATIONNUMBER
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Setting IXAUTHORIZATIONNUMBER. ');

			IF gc_sale_type = g_sale
			THEN
				gc_ixauthorizationnumber := gc_approval_code;
			ELSIF gc_sale_type = g_refund
			THEN
				--gc_ixauthorizationnumber := NULL;   -- Approval code is not specified for returns--Commented for V48.2
				gc_ixauthorizationnumber := gc_approval_code;   --Added for V48.2
			END IF;

			xx_location_and_log(g_log,
								   'ixauthorizationnumber    : '
								|| gc_ixauthorizationnumber);
		END;

--------------------------------------------------------------------------
-- Retrieve IXCUSTCOUNTRYCODE
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retieving the IXCUSTCOUNTRYCODE. ');
			gc_error_debug :=    'Customer Site Use ID: '
							  || gn_customer_site_use_id;

			SELECT hl.country
			INTO   gc_ixcustcountrycode
			FROM   hz_cust_site_uses_all hcsu, hz_cust_acct_sites_all hcas, hz_party_sites hps, hz_locations hl
			WHERE  hcsu.cust_acct_site_id = hcas.cust_acct_site_id
			AND    hcas.party_site_id = hps.party_site_id
			AND    hl.location_id = hps.location_id
			AND    hcsu.site_use_id = gn_customer_site_use_id;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				xx_location_and_log
					(g_loc,
					 'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Retrieve IXCUSTCOUNTRYCODE. ');
				gc_ixcustcountrycode := NULL;
		END;

		xx_location_and_log(g_log,
							   'Customer Cntry Code      : '
							|| gc_ixcustcountrycode);

--------------------------------------------------------------------------
-- Retrieve IXCUSTOMERVATNUMBER, IXCUSTACCOUNTNO, and IXBANKUSERDATA
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving the IXCUSTOMERVATNUMBER, IXCUSTACCOUNTNO, and IXBANKUSERDATA. ');
			gc_error_debug :=    'Pay From Customer ID: '
							  || gn_pay_from_customer;

			SELECT hca.account_number,
				   hp.tax_reference,
				   hca.account_number,
				   hp.party_name,
				   hca.orig_system_reference
			INTO   gc_ixcustaccountno,
				   gc_ixcustomervatnumber,
				   gc_ixbankuserdata,
				   gc_customer_name   -- may need to exclude for G_CCREFUND
								   ,
				   gc_cust_orig_system_ref
			FROM   hz_cust_accounts hca, hz_parties hp
			WHERE  hca.party_id = hp.party_id
			AND    hca.cust_account_id = gn_pay_from_customer;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				xx_location_and_log
					(g_loc,
					 'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Retrieve IXCUSTOMERVATNUMBER. ');
				gc_ixcustaccountno := NULL;
				gc_ixcustomervatnumber := NULL;
		END;

		xx_location_and_log(g_log,
							   'Customer Account #       : '
							|| gc_ixcustaccountno);
		xx_location_and_log(g_log,
							   'Customer Vat #           : '
							|| gc_ixcustomervatnumber);
		xx_location_and_log(g_log,
							   'Bank User Data           : '
							|| gc_ixbankuserdata);
		xx_location_and_log(g_log,
							   'Customer Name            : '
							|| gc_customer_name);

--------------------------------------------------------------------------
-- Retrieve Refund Information
--------------------------------------------------------------------------
		BEGIN
			IF (    gc_sale_type = g_refund
				AND gc_remit_processing_type <> g_ccrefund)
			THEN
--------------------------------------------------------
-- Retrieve POS_AOPS Receipt Method Name for REFUND
--------------------------------------------------------
				BEGIN
					BEGIN
						xx_location_and_log
									 (g_loc,
									  'Retrieving the Recp Method Name from the FTP_DETAILS_AJB Translation (REFUND). ');
						gc_error_debug :=    'Receipt Method Name: '
										  || gc_recp_method_name;

						SELECT xftv.target_value1
						INTO   gc_pos_aops_recp_method
						FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
						WHERE  xftd.translate_id = xftv.translate_id
						AND    xftd.translation_name = 'FTP_DETAILS_AJB'
						AND    xftv.source_value1 = gc_recp_method_name
						AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																				SYSDATE
																			  + 1)
						AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																				SYSDATE
																			  + 1)
						AND    xftv.enabled_flag = 'Y'
						AND    xftd.enabled_flag = 'Y';
					EXCEPTION
						WHEN NO_DATA_FOUND
						THEN
							-- iReceivable receipt methods are not in the translation definition
							xx_location_and_log
								(g_loc,
								 'Entering NO_DATA_FOUND Exception in XX_SET_POST_RECEIPT_VARIABLES for Retrieve POS_AOPS Receipt. ');
							gc_pos_aops_recp_method := NULL;
					END;

					xx_location_and_log(g_log,
										   'Receipt Method Refund     : '
										|| gc_pos_aops_recp_method);
				END;

-----------------------------------------------
-- Retrieve POS_AOPS Store ID for REFUND
-----------------------------------------------
				BEGIN
					xx_location_and_log(g_loc,
										'Retrieving the Store ID from the FTP_DETAILS_AJB Translation (REFUND). ');
					gc_error_debug := 'POS_AOPS_STORE';

					SELECT xftv.target_value1
					INTO   gc_pos_aops_storeid
					FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
					WHERE  xftd.translate_id = xftv.translate_id
					AND    xftd.translation_name = 'FTP_DETAILS_AJB'
					AND    xftv.source_value1 = 'POS_AOPS_STORE'
					AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																			SYSDATE
																		  + 1)
					AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																			SYSDATE
																		  + 1)
					AND    xftv.enabled_flag = 'Y'
					AND    xftd.enabled_flag = 'Y';

					xx_location_and_log(g_log,
										   'POS_AOPS_STORE ID        : '
										|| gc_pos_aops_storeid);
				END;

-----------------------------------------------------
-- Retrieve POS_AOPS Register Number - RETURN ONLY
-----------------------------------------------------
				BEGIN
					xx_location_and_log
									  (g_loc,
									   'Retrieving the Register Number from the FTP_DETAILS_AJB Translation (REFUND). ');
					gc_error_debug := 'POS_AOPS_REGISTER';

					SELECT xftv.target_value1
					INTO   gc_pos_aops_register
					FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
					WHERE  xftd.translate_id = xftv.translate_id
					AND    xftd.translation_name = 'FTP_DETAILS_AJB'
					AND    xftv.source_value1 = 'POS_AOPS_REGISTER'
					AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																			SYSDATE
																		  + 1)
					AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																			SYSDATE
																		  + 1)
					AND    xftv.enabled_flag = 'Y'
					AND    xftd.enabled_flag = 'Y';

					xx_location_and_log(g_log,
										   'Register Number Refund     : '
										|| gc_pos_aops_register);
				END;
			END IF;
		END;

--------------------------------------------------------------Version 26.4
	-- Set gc_ixreserved33 for CC information for AJB file
	-- Set variables gc_ixtokenflag
	-- Set variable gc_ixcreditcardcode --Version 32.0
	-- Set variable gc_ixwallet_type,gc_ixwallet_id --Version 33.0
	--------------------------------------------------------------
		BEGIN
			SELECT   DECODE (  NVL (xaord.token_flag, 'N'), 'Y'
							 , xaord.credit_card_number , NULL) credit_card_number,
					-- DECODE (  NVL (xaord.token_flag, 'N'), 'Y'      --Commented in version 26.9
					--         , gc_tokenization , NULL),
					 xaord.token_flag,
					 xaord.credit_card_code,  --Version 32.0
					 xaord.wallet_type,       --Version 33.0
					 xaord.wallet_id,         --Version 33.0
					 emv_card,
					 emv_terminal,
					 emv_transaction,
					 emv_offline,
					 emv_fallback,
					 emv_tvr
			INTO     gc_ixreserved33,
					-- gc_ixoptions,
					 gc_ixtokenflag,
					 gc_ixcreditcardcode,
					 gc_ixwallet_type,
					 gc_ixwallet_id,
					 lc_emv_card,
					 lc_emv_terminal,
					 lc_emv_transaction,
					 lc_emv_offline,
					 lc_emv_fallback,
					 lc_emv_tvr
			FROM     xx_ar_order_receipt_dtl xaord
			WHERE    xaord.order_payment_id = gn_order_payment_id;
		EXCEPTION
		WHEN OTHERS THEN
		   xx_location_and_log(g_loc,'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Retrieve tokenflag,creditcardcode information. ');
		   gc_ixreserved33 := NULL;
		   gc_ixtokenflag := NULL;
		   gc_ixcreditcardcode := NULL;
		END;

		-- 37.0
		IF gc_credit_card_vendor IS NULL THEN
		   gc_credit_card_vendor := gc_ixcreditcardcode;
		END IF;

		IF gc_ixtokenflag = 'Y' THEN  --Added in version 26.9
			IF NVL (gc_ixoptions , '-1') <> '-1' THEN  --Version 27.1, 27.3
				gc_ixoptions := gc_ixoptions||' '|| gc_tokenization;
			ELSE
				gc_ixoptions := gc_ixoptions||gc_tokenization;
			END IF;
		END IF;

	--Start changes for version 33.0
	IF gc_ixwallet_type = 'P' THEN
	   IF NVL (gc_ixoptions , '-1') <> '-1' THEN
			gc_ixoptions := gc_ixoptions||' '|| '*Masterpass_'||gc_ixwallet_id;
	   ELSE
			gc_ixoptions := gc_ixoptions||'*Masterpass_'||gc_ixwallet_id;
		   END IF;
	END IF;
	--End Version 33.0

--------------------------------------------------------------Version 27.0
	-- Set variables gc_ixtokenflag based on EMV columns of ORDT table
	--EMV Card - Do nothing
	--EMV Terminal - Put "DevCap="+ Field Value in Field 21
	--EMV Transaction - If Y, then put "*EMV" in Field 21
	--EMV Offline -  If Y, then put "Referral" in Field 21
	--EMV Fallback - If Y, then put *FALLBACK_EMV   in  field 21
	--EMV TVR - Put "<95>" + Field Value + "</95>" in Field 56
--------------------------------------------------------------
		IF NVL (lc_emv_terminal, 'N') <> 'N' THEN
			gc_ixoptions := '*DEVCAP='||lc_emv_terminal||' '||gc_ixoptions;
		END IF; --Moved up for Version 48.6
		
		IF NVL(lc_emv_card,'T') <> 'T' THEN --Added for Version 48.6
		
			IF NVL (lc_emv_fallback, 'N') = 'Y' THEN
	
				IF NVL (gc_ixswipe , '-1') <> '-1' THEN   --Version 27.1
				gc_ixoptions := '*CEM_Swiped *FALLBACK_EMV '||gc_ixoptions;
				ELSE
				gc_ixoptions := '*CEM_Manual *FALLBACK_EMV '||gc_ixoptions;
				END IF;
			END IF;
	
			IF NVL (lc_emv_offline, 'N') = 'Y' THEN
				gc_ixoptions := '*REFERRAL '||gc_ixoptions;
			END IF;
	
			IF NVL (lc_emv_transaction, 'N') = 'Y' THEN
				gc_ixoptions := '*CEM_Insert *EMV '||gc_ixoptions;   --Version 27.1
			END IF;
	
			IF NVL (lc_emv_tvr, 'N') <> 'N' THEN
				gc_ixreserved56 := '<95>'||lc_emv_tvr||'</95>';
			END IF;
		
		END IF;--Added for Version 48.6

		xx_location_and_log(g_loc, 'gc_ixoptions :: '||gc_ixoptions);
		xx_location_and_log(g_loc, 'gc_ixreserved56 :: '||gc_ixreserved56);

END xx_set_post_receipt_variables;

-- +====================================================================+
-- | PROCEDURE  : XX_SET_POST_TRX_VARIABLES                             |
-- |                                                                    |
-- | DESCRIPTION: Sets various package variables after order, AR inv, or|
-- |              order has been retrieved.                             |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_set_post_trx_variables
	IS
  l_MPL_ORDER_ID  xx_ar_order_receipt_dtl.mpl_order_id%Type;
  lc_emv_card  xx_ar_order_receipt_dtl.emv_card%Type;
  lc_auth_date 		xx_iby_batch_trxns.ixorderdate%TYPE	:= NULL;	-- Added for version 48.7
	BEGIN
------------------------------------------------------
-- Retrieve Sales Order Type
------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving the Sales Order Type from OD_SALES_ORDER_TYPE translation definition. ');
			gc_error_debug :=    'Sales Order Type: '
							  || gc_sales_order_trans_type;

			SELECT xftv.target_value1
			INTO   gc_sales_order_trans_type_desc
			FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			WHERE  xftd.translate_id = xftv.translate_id
			AND    xftd.translation_name = 'OD_SALES_ORDER_TYPE'
			AND    xftv.source_value1 = gc_sales_order_trans_type
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';

			xx_location_and_log(g_log,
								   'Sales ORD Trans Type Desc: '
								|| gc_sales_order_trans_type_desc);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				xx_location_and_log
					   (g_loc,
						'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve Sales Order Type. ');
				gc_sales_order_trans_type_desc := NULL;
		END;
		
		BEGIN  -- For Version 48.6 starts here
						
			xx_location_and_log(g_log,'EMV Card Check in ORDT');
			
			lc_emv_card := NULL;
						
			SELECT  nvl(emv_card,'N')
				INTO lc_emv_card
			FROM xx_ar_order_receipt_dtl
			WHERE order_payment_id = gn_order_payment_id; 
							
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				xx_location_and_log
					(g_loc,
					'NO_DATA_FOUND for order_payment_id '|| gn_order_payment_id ||' in xx_ar_order_receipt_dtl ');
				lc_emv_card :='N';
		END;  -- For Version 48.6 ends here
------------------------------------------------------
-- Retrieve Order Information
------------------------------------------------------
		BEGIN
			-- Order information is retrieved for single pmt in XX_POE_SGLPMT_MULTI_SETTLEMENT
			IF (gc_remit_processing_type <> g_poe_single_pmt_multi_ord)
			THEN
				BEGIN
					xx_location_and_log(g_loc,
										'Retrieving Customer PO Number, Order Date, Header ID, and Orig Sys Doc Ref. ');
					gc_error_debug :=
						   'Sales Order Type: '
						|| gc_sales_order_trans_type
						|| '. Application Reference Number: '
						|| gc_application_ref_num;

					SELECT cust_po_number,
						   TO_CHAR(ordered_date,
								   'MMDDYYYY'),
						   ship_from_org_id,
						   header_id,
						   orig_sys_document_ref
					INTO   gc_ixcustomerreferenceid,
						   gc_ixorderdate,
						   gn_ship_from_org_id,
						   gn_order_header_id,
						   gc_orig_sys_document_ref
					FROM   oe_order_headers_all
					WHERE  order_number = NVL(gn_order_number,
											  gc_application_ref_num)
					AND    invoice_to_org_id = gn_bill_to_site_use_id;

					gc_cust_po_number := gc_ixcustomerreferenceid;
					xx_location_and_log(g_log,
										   'Customer Reference Id    : '
										|| gc_ixcustomerreferenceid);
					xx_location_and_log(g_log,
										   'Order Date               : '
										|| gc_ixorderdate);
					xx_location_and_log(g_log,
										   'Ship From Org Id         : '
										|| gn_ship_from_org_id);
					xx_location_and_log(g_log,
										   'Order Header Id          : '
										|| gn_order_header_id);
					xx_location_and_log(g_log,
										   'Legacy Sales Order       : '
										|| gc_orig_sys_document_ref);
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve Order Information. ');
						gc_ixcustomerreferenceid := NULL;
						gn_ship_from_org_id := NULL;
						gc_ixorderdate := NULL;
				END;
				
				/* Version 48.7 - Retrieving credit_card_approval_date for ixorderdate */
				BEGIN
					xx_location_and_log(g_loc,
										'Retrieving ixorderdate from auth date of oe_payments. ');
					gc_error_debug :=
						   'order_payment_id: '
						|| gn_order_payment_id;

					SELECT TO_CHAR(op.CREDIT_CARD_APPROVAL_DATE,'MMDDYYYY') CREDIT_CARD_APPROVAL_DATE
					INTO lc_auth_date
					FROM oe_payments op,
						 xx_ar_order_receipt_dtl xaord
					WHERE 1=1
					AND op.header_id = xaord.header_id
					AND op.orig_sys_payment_ref = xaord.orig_sys_payment_ref
					AND xaord.order_payment_id = gn_order_payment_id;

					xx_location_and_log(g_log,
										   'Auth Date: '
										|| lc_auth_date);
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in lc_auth_date for Retrieve Auth Date. ');
						lc_auth_date := NULL;
				END;
				
				IF lc_auth_date IS NOT NULL
				THEN
				gc_ixorderdate := lc_auth_date;
				END IF;
				/* End version 48.7 */

	  --Start Changes for BIZBOX
		BEGIN
			IF gc_order_source = 'BBOX' THEN
			  SELECT  MPL_ORDER_ID
				INTO l_mpl_order_id
				FROM xx_ar_order_receipt_dtl
			   WHERE order_payment_id = gn_order_payment_id;

			  xx_location_and_log(g_log,
								  'BBOX MPL_ORDER_ID from Receipts          : '
								  || l_mpl_order_id);
			 END IF;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve MPL_ORDER_ID Information. ');
			l_mpl_order_id := NULL;
		END;
	--End Changes for BIZBOX

	  --Defect# 35181 - Order date for payment against single invoice should be retrieved from Receipt date. BEGIN
				--If the receipt is from iRec,populate the ixorderdate with receipt_date

				BEGIN
					IF (gc_remit_processing_type = g_irec) then
						--
						SELECT  TO_CHAR(receipt_date,
								   'MMDDYYYY')
						  INTO gc_ixorderdate
						  FROM xx_ar_order_receipt_dtl
						 WHERE order_payment_id = gn_order_payment_id;
						xx_location_and_log(g_log,
										   'Order Date from Receipts          : '
										|| gc_ixorderdate);
					END IF;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve Order Date Information. ');
						gc_ixorderdate := NULL;
				END;

				BEGIN
					IF  (gc_remit_processing_type = g_service_contracts) THEN  --Modified for V47.0 5/Mar/2018
						--
						gc_orig_sys_document_ref:=gc_trx_number;
						SELECT  TO_CHAR(receipt_date,
								   'MMDDYYYY')
						  INTO gc_ixorderdate
						  FROM xx_ar_order_receipt_dtl
						 WHERE order_payment_id = gn_order_payment_id;
						xx_location_and_log(g_log,
										   'Order Date from Receipts          : '
										|| gc_ixorderdate);

					END IF;

				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve Order Date Information. ');
						gc_ixorderdate := NULL;
				END;


	  --Defect# 35181 - Order date for payment against single invoice should be retrieved from Receipt date. END

				IF (gc_orig_sys_document_ref LIKE 'OE_ORDER_HEADERS_ALL%')
				THEN
					xx_location_and_log(g_loc,
										'Retrieving Sales Order Number. ');
					gc_error_debug :=    'Legacy Sales Order: '
									  || gc_orig_sys_document_ref;

					SELECT order_number
					INTO   gc_orig_sys_document_ref
					FROM   oe_order_headers_all
					WHERE  header_id = REPLACE(gc_orig_sys_document_ref,
											   'OE_ORDER_HEADERS_ALL');

					xx_location_and_log(g_log,
										   'Legacy Sales Order     : '
										|| gc_orig_sys_document_ref);
				END IF;
			END IF;
		END;

------------------------------------------------------
-- Set IXREGISTERNUMBER and other various variables
------------------------------------------------------
		BEGIN
			IF gc_remit_processing_type = g_ccrefund
			THEN
				xx_location_and_log(g_loc,
									'Setting register number, invoice, etc. for call from XX_IBY_CC_REFUNDS. ');

				BEGIN
					gc_ixinvoice := gc_trx_number;
					gc_ixregisternumber := '99';
					gc_ixstorenumber := NVL(gc_shiploc,
											gc_store);
					gc_pre2 := gc_ixstorenumber;

					IF (gc_sales_order_trans_type_desc = 'AOPS Order')
					THEN
						gc_source := 'AOPS';
						gc_ixregisternumber := '99';
						gc_ixinvoice :=    SUBSTR(gn_order_number,
												  1,
												  9)
										|| SUBSTR(gn_order_number,
												  -3);
					ELSIF(gc_sales_order_trans_type_desc = 'POS Order')
					THEN
						gc_source := 'POS';
						gc_ixregisternumber := SUBSTR(gn_order_number,
													  13,
													  3);

						IF (gn_cc_entry_count > 0) OR (lc_emv_card = 'T') -- Added for Version 48.6
						THEN
							gc_ixswipe := NULL;
						ELSE
							gc_ixswipe :=    gc_ixaccount
										  || '='
										  || gc_ixexpdate;
							gc_ixaccount := NULL;
							gc_ixexpdate := NULL;
						END IF;

						gc_ixinvoice := gn_order_number;

						IF (gc_pos_auth_entry IS NOT NULL)
						THEN
							gc_ixreserved31 := gc_pos_auth_entry;
						END IF;

						IF (gc_auth_entry_mode = gc_auth_entry_val_c)
						THEN
							gc_ixoptions :=    gc_ixoptions
											|| ' '
											|| gc_contactless_value;
						END IF;
					END IF;
				END;
			ELSIF gc_remit_processing_type = g_poe_int_store_cust
			THEN
				xx_location_and_log
								(g_loc,
								 'Setting register number, invoice, etc. for POS/POE Internal Store Customer receipt. ');

				BEGIN
					gc_ixregisternumber := SUBSTR(gc_orig_sys_document_ref,
												  13,
												  3);
					gc_source := 'POS';

					IF (gn_cc_entry_count > 0) OR (lc_emv_card = 'T') -- Added for Version 48.6
					THEN
						gc_ixswipe := NULL;
					ELSE
						gc_ixswipe :=    gc_ixaccount
									  || '='
									  || gc_ixexpdate;
						gc_ixaccount := NULL;
						gc_ixexpdate := NULL;
					END IF;

					-- POE Internal Store Customers (Not Single Payment) Only
					gc_ixinvoice := gc_orig_sys_document_ref;
					gc_ixstorenumber := gc_store;
					gc_pre2 := gc_ixstorenumber;

					IF (gc_pos_auth_entry IS NOT NULL)
					THEN
						gc_ixreserved31 := gc_pos_auth_entry;
					END IF;

					IF (gc_auth_entry_mode = gc_auth_entry_val_c)
					THEN
						gc_ixoptions :=    gc_ixoptions
										|| ' '
										|| gc_contactless_value;
					END IF;
				END;
			ELSIF gc_remit_processing_type = g_poe_single_pmt_multi_ord
			THEN
				xx_location_and_log(g_loc,
									'Setting register number, invoice, etc. for POE Single Payment Multi-Order. ');

				BEGIN
					gc_source := 'POS_SGL_PMT_MULT_ORD';
					gc_ixregisternumber := SUBSTR(gc_transaction_number,
												  13,
												  3);
					gc_ixinvoice := gc_transaction_number;
					gc_ixstorenumber := gc_store;
					gc_pre2 := gc_ixstorenumber;

					IF (gn_cc_entry_count > 0) OR (lc_emv_card = 'T') -- Added for Version 48.6
					THEN
						gc_ixswipe := NULL;
					ELSE
						gc_ixswipe :=    gc_ixaccount
									  || '='
									  || gc_ixexpdate;
						gc_ixaccount := NULL;
						gc_ixexpdate := NULL;
					END IF;

					IF (gc_pos_auth_entry IS NOT NULL)
					THEN
						gc_ixreserved31 := gc_pos_auth_entry;
					END IF;

					IF (gc_auth_entry_mode = gc_auth_entry_val_c)
					THEN
						gc_ixoptions :=    gc_ixoptions
										|| ' '
										|| gc_contactless_value;
					END IF;
				END;
			ELSIF(gc_receipt_number LIKE 'IEX%')
			THEN
				xx_location_and_log(g_loc,
									'Setting register number, invoice, etc. for Advanced Collection Receipt. ');

				BEGIN
					gc_source := 'AC';
					gc_ixregisternumber := '56';
					gc_ixps2000 := NULL;
					gc_ixstorenumber := gc_oapfstoreid;
					-- oapfstoreid will always have a value of 001099 for IEX receipts from Automatic Remittance
					gc_pre2 := gc_oapfstoreid;

					-- oapfstoreid will always have a value of 001099 for IEX receipts from Automatic Remittance
					IF gc_sale_type = g_sale
					THEN
						gc_ixmerchandiseshipped := 'Y';
					END IF;

					IF (gc_sales_order_trans_type_desc = 'AOPS Order')
					THEN
						-- For ADV Collections if is a APOS Order
						gc_ixinvoice := gc_orig_sys_document_ref;

						IF gc_sale_type = g_refund
						THEN
							gc_ixps2000 := gc_net_data;
						END IF;
					ELSIF(gc_sales_order_trans_type_desc = 'POS Order')
					THEN
						-- For ADV Collections if is a POS Order
						gc_ixinvoice :=
							   SUBSTR(gc_orig_sys_document_ref,
									  1,
									  4)
							|| '/'
							|| SUBSTR(gc_orig_sys_document_ref,
									  13,
									  3)
							|| '/'
							|| SUBSTR(gc_orig_sys_document_ref,
									  16);
						gc_ixswipe := NULL;
					ELSE
						-- Column17 (IXINVOICE)  For ADV Collections ONLY
						gc_ixinvoice := gc_customer_number;
					END IF;
				END;
			ELSIF(gc_oapforder_id LIKE 'ARI%')
			THEN
				xx_location_and_log(g_loc,
									'Setting register number, invoice, etc. for iReceivable receipt. ');

				BEGIN
					gc_source := 'AR';
					gc_ixregisternumber := '55';
					gc_ixreserved31 := gc_mo_value;
					gc_ixstorenumber := gc_oapfstoreid;
					-- oapfstoreid will always have a value of 001099 for IREC receipts from Automatic Remittance
					gc_pre2 := gc_oapfstoreid;

					-- oapfstoreid will always have a value of 001099 for IREC receipts from Automatic Remittance
					IF gc_sale_type = g_refund
					THEN
						gc_ixinvoice := gc_cm_number;
					ELSIF gc_sale_type = g_sale
					THEN
				  /* Commented out to send PAYMENT_SERVER_NUM to feild 17 for AJB requirements BY NB */
/*
				  IF (gc_sales_order_trans_type_desc = 'AOPS Order') THEN
					 -- For iReceivables if is a AOPS Order
					 gc_ixinvoice := gc_orig_sys_document_ref;
				  ELSIF (gc_sales_order_trans_type_desc = 'POS Order') THEN
					 -- For iReceivables if is a POS Order
					 gc_ixinvoice := SUBSTR(gc_orig_sys_document_ref,1,4)||'/'
									 ||SUBSTR(gc_orig_sys_document_ref,13,3)
									 ||'/'||SUBSTR(gc_orig_sys_document_ref,16);
					 gc_ixswipe := NULL;
				  ELSE
					 gc_ixinvoice := gc_trx_number;
				  END IF;
*/
						gc_ixinvoice := gc_oapforder_id;
					END IF;
				END;
			-- ELSIF(gc_oapforder_id LIKE 'AR%' AND gc_sale_type = g_sale AND gb_is_deposit_receipt = TRUE)
			ELSIF (gc_remit_processing_type = g_service_contracts)--Added for V47.0 5/Mar/2018
			THEN
				xx_location_and_log(g_loc,
									'Setting register number, invoice, etc. for SERVICE-CONTRACTS receipt. ');

				BEGIN
					gc_source := 'AR';
					gc_ixregisternumber := '56';
					--gc_ixreserved31 := gc_mo_value; Modified for V47.3 14/Mar/2018
					--------------------------------------------------------------------------
					-- Retrieve AOPS Auth Entry-Defaulted to *ECE for Service Contracts
					--------------------------------------------------------------------------
					BEGIN
						xx_location_and_log
						(g_loc,
							'Retrieving CVV/AVS Code and Auth Entry Mode from OD_IBY_AUTH_ENTRY_MODE translation definition. ');
						SELECT target_value1
						INTO   gc_aops_auth_entry
						FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
						WHERE  translation_name = 'OD_IBY_AUTH_ENTRY_MODE'
						AND    xftv.translate_id = xftd.translate_id
						AND    xftv.source_value1 ='E' --gc_auth_entry_mode
						AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																				SYSDATE
																			  + 1)
						AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																				SYSDATE
																			  + 1)
						AND    xftv.enabled_flag = 'Y'
						AND    xftd.enabled_flag = 'Y';
					EXCEPTION
						WHEN OTHERS
						THEN
							xx_location_and_log
								(g_loc,
								 'Entering WHEN OTHERS Exception in XX_SET_POST_RECEIPT_VARIABLES for Retrieve AOPS and POS Auth Entry for Service-Contracts.');
							gc_aops_auth_entry := NULL;

					END;

					xx_location_and_log(g_log,
										   'AOPS Auth Entry          : '
										|| gc_aops_auth_entry);

					gc_ixreserved31 := gc_aops_auth_entry;

					--Modified End for V47.3 14/Mar/2018


					gc_ixstorenumber :=  NVL(gc_oapfstoreid,NVL(gc_store,g_servc_contract_store_number));--gc_oapfstoreid;
					gc_pre2 :=  NVL(gc_oapfstoreid,NVL(gc_store,g_servc_contract_store_number));--gc_oapfstoreid;
					IF gc_sale_type = g_sale
					THEN
						gc_ixinvoice := gc_trx_number; -- Added for V47.0 5/Mar/2018
					END IF;
				END;

			ELSIF(    gc_remit_processing_type = g_default
				  AND gc_sale_type = g_sale
				  AND gb_is_deposit_receipt = TRUE)
			THEN
				xx_location_and_log(g_loc,
									'Setting register number, invoice, etc. for Deposit Receipt. ');

				BEGIN
					-- Defect 12724 and 13498 - Section added and moved to make sure transaction number is retrieved for deposit-sales receipts --
					BEGIN
						xx_location_and_log(g_loc,
											'Retrieving the Transaction_number for Deposit Receipt. ');
						gc_error_debug :=    'Cash Receipt ID: '
										  || gn_cash_receipt_id;

						-- Defect 13498 - Modified query
						SELECT xoldd.orig_sys_document_ref,
							   xold.store_location,
							   xoldd.transaction_number
						INTO   gc_orig_sys_document_ref,
							   gc_deposit_store_location,
							   gc_transaction_number
						FROM   xx_om_legacy_deposits xold, xx_om_legacy_dep_dtls xoldd
						WHERE  xold.cash_receipt_id = gn_cash_receipt_id
						AND    xold.payment_type_code = 'CREDIT_CARD'
						AND    xold.credit_card_approval_code = gc_approval_code
						AND    xold.transaction_number = xoldd.transaction_number;

						xx_location_and_log(g_log,
											   'Transaction Number Deposit Receipt: '
											|| gc_transaction_number);
					EXCEPTION
						WHEN NO_DATA_FOUND
						THEN
							xx_location_and_log
								(g_loc,
								 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Transaction Number Deposit Receipt. ');
							gc_transaction_number := NULL;
					END;

					gc_is_deposit := 'Y';
					gc_source := 'SA_DEPOSIT';
					gc_ixregisternumber := SUBSTR(gc_transaction_number,
												  13,
												  3);
					gc_ixstorenumber := NVL(gc_deposit_store_location,
											gc_store);
					gc_pre2 := gc_ixstorenumber;
					gc_ixinvoice := gc_transaction_number;

					IF (gn_cc_entry_count > 0) OR (lc_emv_card = 'T') -- Added for Version 48.6
					THEN
						gc_ixswipe := NULL;
					ELSE
						gc_ixswipe :=    gc_ixaccount
									  || '='
									  || gc_ixexpdate;
						gc_ixaccount := NULL;
						gc_ixexpdate := NULL;
					END IF;

					IF (gc_pos_auth_entry IS NOT NULL)
					THEN
						gc_ixreserved31 := gc_pos_auth_entry;
					END IF;

					IF (gc_auth_entry_mode = gc_auth_entry_val_c)
					THEN
						gc_ixoptions :=    gc_ixoptions
										|| ' '
										|| gc_contactless_value;
					END IF;
				END;
			ELSIF(    gc_remit_processing_type = g_default
				  AND gc_sale_type = g_sale
				  AND NVL(gb_is_deposit_receipt,
						  FALSE) = FALSE)
			THEN
				xx_location_and_log(g_loc,
									'Setting register number, invoice, etc. for SALE.');

				BEGIN
					IF (gc_sa_payment_source = 'SA_DEPOSIT')
					THEN
						BEGIN
							xx_location_and_log(g_loc,
												'Retrieving the Transaction_number for SA_DEPOSIT. ');
							gc_error_debug :=    'Cash Receipt ID: '
											  || gn_cash_receipt_id;

							-- Defect 13498 - Modified query
							SELECT xoldd.orig_sys_document_ref,
								   xold.store_location,
								   xoldd.transaction_number
							INTO   gc_orig_sys_document_ref,
								   gc_deposit_store_location,
								   gc_transaction_number
							FROM   xx_om_legacy_deposits xold, xx_om_legacy_dep_dtls xoldd
							WHERE  xold.cash_receipt_id = gn_cash_receipt_id
							AND    xold.payment_type_code = 'CREDIT_CARD'
							AND    xold.credit_card_approval_code = gc_approval_code
							AND    xold.transaction_number = xoldd.transaction_number;

							xx_location_and_log(g_log,
												   'Transaction Number SA_DEPOSIT - INV: '
												|| gc_transaction_number);
						EXCEPTION
							WHEN NO_DATA_FOUND
							THEN
								xx_location_and_log
									(g_loc,
									 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Transaction Number. ');
								gc_transaction_number := NULL;
						END;

						gc_is_deposit := 'Y';
						gc_source := 'SA_DEPOSIT';
						gc_ixregisternumber := SUBSTR(gc_transaction_number,
													  13,
													  3);
						gc_ixstorenumber := gc_store;
						gc_pre2 := gc_ixstorenumber;
						gc_ixinvoice := gc_transaction_number;   --DEFECT 12724 change BY NB

						IF (gn_cc_entry_count > 0) OR (lc_emv_card = 'T') -- Added for Version 48.6
						THEN
							gc_ixswipe := NULL;
						ELSE
							gc_ixswipe :=    gc_ixaccount
										  || '='
										  || gc_ixexpdate;
							gc_ixaccount := NULL;
							gc_ixexpdate := NULL;
						END IF;

						IF (gc_pos_auth_entry IS NOT NULL)
						THEN
							gc_ixreserved31 := gc_pos_auth_entry;
						END IF;

						IF (gc_auth_entry_mode = gc_auth_entry_val_c)
						THEN
							gc_ixoptions :=    gc_ixoptions
											|| ' '
											|| gc_contactless_value;
						END IF;
					ELSIF(gc_sales_order_trans_type_desc = 'AOPS Order')
					THEN
						gc_source := 'AOPS';
						gc_ixregisternumber := '99';
						gc_ixmerchandiseshipped := 'Y';
						-- For AOPS Order Only
		  gc_ixinvoice :=    SUBSTR(gc_orig_sys_document_ref,
									  1,
									  9)
									  || SUBSTR(gc_orig_sys_document_ref,
									  -3);
		  -- Start Changes for Bizbox order
		  IF (gc_order_source='BBOX')
		  THEN
			--gc_source := 'BBOX';
			gc_ixinvoice := l_mpl_order_id;
		  END IF;
		 --- End
						gc_ixstorenumber := gc_shiploc;
						gc_pre2 := gc_ixstorenumber;

						IF (gc_aops_auth_entry IS NOT NULL)
						THEN
							gc_ixreserved31 := gc_aops_auth_entry;
						END IF;

						IF (gc_avs_resp_code IS NOT NULL)
						THEN
							gc_ixoptions :=    gc_ixoptions
											|| ' '
											|| gc_avs_resp_value
											|| gc_avs_resp_code;
						END IF;
					-- Following condition added for Defect 12686 - Version 11.7 - 7/18/2011
					ELSIF(gc_sales_order_trans_type_desc = 'POS Order')
					THEN
						gc_ixregisternumber := SUBSTR(gc_orig_sys_document_ref,
													  13,
													  3);
						gc_source := 'POS';

						IF (gn_cc_entry_count > 0) OR (lc_emv_card = 'T') -- Added for Version 48.6
						THEN
							gc_ixswipe := NULL;
						ELSE
							gc_ixswipe :=    gc_ixaccount
										  || '='
										  || gc_ixexpdate;
							gc_ixaccount := NULL;
							gc_ixexpdate := NULL;
						END IF;

						gc_ixinvoice := gc_orig_sys_document_ref;
						gc_ixstorenumber := gc_store;
						gc_pre2 := gc_ixstorenumber;

						IF (gc_pos_auth_entry IS NOT NULL)
						THEN
							gc_ixreserved31 := gc_pos_auth_entry;
						END IF;

						IF (gc_auth_entry_mode = gc_auth_entry_val_c)
						THEN
							gc_ixoptions :=    gc_ixoptions
											|| ' '
											|| gc_contactless_value;
						END IF;
					END IF;
				END;
			ELSIF(    gc_is_deposit_return = TRUE
				  AND gc_sale_type = g_refund)
			THEN
				xx_location_and_log(g_loc,
									'Setting register number, invoice, etc. for store deposit return/refund.  ');

				BEGIN
					gc_is_deposit := 'Y';
					gc_sa_payment_source := 'SA_DEPOSIT';   -- Resetting the Payment source
					gc_source := 'SA_DEPOSIT';
					gc_ixregisternumber := '99';
					gc_ixstorenumber := NVL(gc_deposit_store_location,
											gc_store);
					gc_pre2 := gc_ixstorenumber;
					gc_ixinvoice := gc_transaction_number;   -- Defect 13498
					xx_location_and_log(g_log,
										   'Deposit Return?          : '
										|| 'YES');
					xx_location_and_log(g_log,
										   'Discount Amount          : '
										|| gc_ixdiscountamount);
				END;
			ELSIF(    gc_sales_order_trans_type_desc = 'AOPS Order'
				  AND gc_sale_type = g_refund)
			THEN
				gc_source := 'AOPS';
				gc_ixregisternumber := '99';
				gc_ixinvoice :=    SUBSTR(gc_orig_sys_document_ref,
										  1,
										  9)
								|| SUBSTR(gc_orig_sys_document_ref,
										  -3);
				gc_ixstorenumber := gc_shiploc;
				gc_pre2 := gc_ixstorenumber;

				IF (gc_aops_auth_entry IS NOT NULL)
				THEN
					gc_ixreserved31 := gc_aops_auth_entry;
				END IF;

				IF (gc_avs_resp_code IS NOT NULL)
				THEN
					gc_ixoptions :=    gc_ixoptions
									|| ' '
									|| gc_avs_resp_value
									|| gc_avs_resp_code;
				END IF;
			ELSIF(    gc_sales_order_trans_type_desc = 'POS Order'
				  AND gc_sale_type = g_refund)
			THEN
				gc_ixregisternumber := SUBSTR(gc_orig_sys_document_ref,
											  13,
											  3);
				gc_source := 'POS';

				IF (gn_cc_entry_count > 0) OR (lc_emv_card = 'T') -- Added for Version 48.6
				THEN
					gc_ixswipe := NULL;
				ELSE
					gc_ixswipe :=    gc_ixaccount
								  || '='
								  || gc_ixexpdate;
					gc_ixaccount := NULL;
					gc_ixexpdate := NULL;
				END IF;

				gc_ixinvoice := gc_orig_sys_document_ref;
				gc_ixstorenumber := gc_store;
				gc_pre2 := gc_ixstorenumber;

				IF (gc_pos_auth_entry IS NOT NULL)
				THEN
					gc_ixreserved31 := gc_pos_auth_entry;
				END IF;

				IF (gc_auth_entry_mode = gc_auth_entry_val_c)
				THEN
					gc_ixoptions :=    gc_ixoptions
									|| ' '
									|| gc_contactless_value;
				END IF;
			ELSIF(    gc_pos_aops_recp_method = 'POS_AOPS_REFUND'
				  AND gc_pos_aops_storeid = gc_oapfstoreid
				  AND gc_sale_type = g_refund)
			THEN
				xx_location_and_log(g_loc,
									'Setting register number, invoice, etc. for AOPS return/refund.  ');

				BEGIN
					xx_location_and_log(g_log,
										   'POS_AOPS_REFUND Orders  :'
										|| gc_pre2);
					gc_source := 'POS_AOPS_REFUND';   -- either POS or AOPS is ok here
					gc_ixregisternumber := gc_pos_aops_register;
					gc_ixstorenumber := NVL(gc_store,
											gc_shiploc);
					gc_pre2 := gc_ixstorenumber;
					gc_ixinvoice := gc_cm_number;
				END;
			END IF;

			xx_location_and_log(g_loc,
								'Setting IXRESERVED31 to NULL if sale type is REFUND.  ');

			IF gc_sale_type = g_refund
			THEN
				gc_ixreserved31 := NULL;
			END IF;

			xx_location_and_log(g_log,
								   'Sale Type                : '
								|| gc_sale_type);
			xx_location_and_log(g_log,
								   'Remit Processing Type    : '
								|| gc_remit_processing_type);
			xx_location_and_log(g_log,
								   'POS AOPS RECP Method     : '
								|| gc_pos_aops_recp_method);
			xx_location_and_log(g_log,
								   'POS AOPS Store ID        : '
								|| gc_pos_aops_storeid);
			xx_location_and_log(g_log,
								   'SA Payment Source        : '
								|| gc_sa_payment_source);
			xx_location_and_log(g_log,
								   'Sales Order Tran Type Dsc: '
								|| gc_sales_order_trans_type_desc);
			xx_location_and_log(g_log,
								   'Source                   : '
								|| gc_source);
			xx_location_and_log(g_log,
								   'Merchandise Shipped      : '
								|| gc_ixmerchandiseshipped);
			xx_location_and_log(g_log,
								   'Invoice                  : '
								|| gc_ixinvoice);
			xx_location_and_log(g_log,
								   'Order Number             : '
								|| gn_order_number);
			xx_location_and_log(g_log,
								   'Orig Sys Document Ref    : '
								|| gc_orig_sys_document_ref);
			xx_location_and_log(g_log,
								   'Register Number          : '
								|| gc_ixregisternumber);
			xx_location_and_log(g_log,
								   'IXSTORENUMBER            : '
								|| gc_ixstorenumber);
			xx_location_and_log(g_log,
								   'PRE2                     : '
								|| gc_pre2);
			xx_location_and_log(g_log,
								   'Store Number             : '
								|| gc_store);
			xx_location_and_log(g_log,
								   'Ship Location            : '
								|| gc_shiploc);
			xx_location_and_log(g_log,
								   'Swipe                    : '
								|| gc_ixswipe);
			xx_location_and_log(g_log,
								   'POS Auth Entry           : '
								|| gc_pos_auth_entry);
			xx_location_and_log(g_log,
								   'IXRESERVED31             : '
								|| gc_ixreserved31);
			xx_location_and_log(g_log,
								   'Auth Entry_Mode          : '
								|| gc_auth_entry_mode);
			xx_location_and_log(g_log,
								   'Auth Entry Val C         : '
								|| gc_auth_entry_val_c);
			xx_location_and_log(g_log,
								   'Contactless Value        : '
								|| gc_contactless_value);
			xx_location_and_log(g_log,
								   'Avs Resp Value           : '
								|| gc_avs_resp_value);
			xx_location_and_log(g_log,
								   'Avs Resp Code            : '
								|| gc_avs_resp_code);
			xx_location_and_log(g_log,
								   'IXOPTIONS                : '
								|| gc_ixoptions);
		END;

------------------------------------------------------
-- Verify Length of Pre2
------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Verifying length of PRE2.  ');

			IF    (gc_pre2 IS NULL)
			   OR (LENGTH(gc_pre2) <> g_pre2_length)
			THEN
				xx_location_and_log(g_log,
									   'Pre2 Field Length Check  : '
									|| gc_pre2);
				DBMS_OUTPUT.put_line(   'Pre2 Field Length Check  : '
									 || gc_pre2);
				gc_error_debug :=    'Pre2 should contain 6 characters.  gc_pre2 LENGTH: '
								  || LENGTH(gc_pre2);
				DBMS_OUTPUT.put_line(gc_error_debug);
				RAISE ex_pre2;
			END IF;
		END;

------------------------------------------------------
-- Retrieve Ship To Information
------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving Ship To Information.  ');

			IF gc_sale_type = g_sale
			THEN
------------------------------------------------------
-- Retrieve IXSHIPFROMZIPCODE for SALE
------------------------------------------------------
				BEGIN
					xx_location_and_log(g_loc,
										'Retrieving the IXSHIPFROMZIPCODE. ');
					gc_error_debug :=    'Ship From Org ID: '
									  || gn_ship_from_org_id;

					SELECT hl.postal_code
					INTO   gc_ixshipfromzipcode
					FROM   hr_all_organization_units haou, hr_locations hl
					WHERE  hl.location_id = haou.location_id
					AND    haou.organization_id = gn_ship_from_org_id;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve IXSHIPFROMZIPCODE. ');
						gc_ixshipfromzipcode := NULL;
				END;

				xx_location_and_log(g_log,
									   'Ship From Zipcode        : '
									|| gc_ixshipfromzipcode);

------------------------------------------------------
-- Retrieve IXSHIPTOCOMPANY for SALE
------------------------------------------------------
				BEGIN
					xx_location_and_log(g_loc,
										'Retrieving the IXSHIPTOCOMPANY. ');
					gc_error_debug :=    'Ship to Customer ID: '
									  || gn_ship_to_customer_id;

					SELECT hp.party_name
					INTO   gc_ixshiptocompany
					FROM   hz_cust_accounts hca, hz_parties hp
					WHERE  hca.party_id = hp.party_id
					AND    hca.cust_account_id = gn_ship_to_customer_id;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve IXSHIPTOCOMPANY. ');
						gc_ixshiptocompany := NULL;
				END;

				xx_location_and_log(g_log,
									   'Ship To Company          : '
									|| gc_ixshiptocompany);

------------------------------------------------------
-- Retrieve IXSHIPTONAME for SALE
------------------------------------------------------
				BEGIN
					xx_location_and_log(g_loc,
										'Retrieving the IXSHIPTONAME. ');
					gc_error_debug :=    'Ship to Contact ID: '
									  || gn_ship_to_contact_id;

--                    SELECT    rcs.first_name
--                           || ' '
--                           || rcs.last_name
--                    INTO   gc_ixshiptoname
--                    FROM   ra_contacts rcs
--                    WHERE  rcs.contact_id = gn_ship_to_contact_id;
					SELECT    SUBSTRB(party.person_first_name,
									  1,
									  50)
						   || ' '
						   || SUBSTRB(party.person_last_name,
									  1,
									  50)
					INTO   gc_ixshiptoname
					FROM   hz_cust_account_roles acct_role,
						   hz_parties party,
						   hz_relationships rel,
						   hz_org_contacts org_cont,
						   hz_parties rel_party,
						   hz_cust_accounts role_acct
					WHERE  acct_role.cust_account_role_id = gn_ship_to_contact_id
					AND    acct_role.party_id = rel.party_id
					AND    acct_role.role_type = 'CONTACT'
					AND    org_cont.party_relationship_id = rel.relationship_id
					AND    rel.subject_id = party.party_id
					AND    rel.party_id = rel_party.party_id
					AND    rel.subject_table_name = 'HZ_PARTIES'
					AND    rel.object_table_name = 'HZ_PARTIES'
					AND    acct_role.cust_account_id = role_acct.cust_account_id
					AND    role_acct.party_id = rel.object_id;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve IXSHIPTONAME from header attributes. ');

						BEGIN
							SELECT xoha.ship_to_name
							INTO   gc_ixshiptoname
							FROM   xx_om_header_attributes_all xoha
							WHERE  xoha.header_id = gn_order_header_id;

							xx_location_and_log(g_log,
												   'Ship To Name             : '
												|| gc_ixshiptoname);
						EXCEPTION
							WHEN NO_DATA_FOUND
							THEN
								xx_location_and_log
									(g_loc,
									 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve IXSHIPTONAME. ');
								gc_ixshiptoname := NULL;
						END;
				END;

				xx_location_and_log(g_log,
									   'Ship To Name             : '
									|| gc_ixshiptoname);

------------------------------------------------------
-- Retrieve Additional Ship To Info - SALE
------------------------------------------------------
				BEGIN
					xx_location_and_log(g_loc,
										'Retrieving the SHIP TO Addresses. ');
					gc_error_debug :=    'Ship to Site Use ID: '
									  || gn_ship_to_site_use_id;

					IF (gn_ship_to_site_use_id IS NOT NULL)
					THEN
						SELECT hl.address1,
							   hl.city,
							   NVL(hl.state,
								   hl.province),
							   hl.country,
							   hl.postal_code
						INTO   gc_ixshiptostreet,
							   gc_ixshiptocity,
							   gc_ixshiptostate,
							   gc_ixshiptocountry,
							   gc_ixshiptozipcode
						FROM   hz_cust_site_uses_all hcsu,
							   hz_cust_acct_sites_all hcas,
							   hz_party_sites hps,
							   hz_locations hl
						WHERE  hcsu.cust_acct_site_id = hcas.cust_acct_site_id
						AND    hcas.party_site_id = hps.party_site_id
						AND    hl.location_id = hps.location_id
						AND    hcsu.site_use_id = gn_ship_to_site_use_id;
					ELSE
						gc_ixshiptozipcode := gc_aops_dep_shipto_zipcode;
						gc_ixshiptostate := gc_aops_dep_shipto_state;
					END IF;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve Additional Ship To Info (Sale). ');
						gc_ixshiptostreet := NULL;
						gc_ixshiptocity := NULL;
						gc_ixshiptostate := NULL;
						gc_ixshiptocountry := NULL;
						gc_ixshiptozipcode := NULL;
				END;

				xx_location_and_log(g_log,
									   'Ship To Street           : '
									|| gc_ixshiptostreet);
				xx_location_and_log(g_log,
									   'Ship To City             : '
									|| gc_ixshiptocity);
				xx_location_and_log(g_log,
									   'Ship To State            : '
									|| gc_ixshiptostate);
				xx_location_and_log(g_log,
									   'Ship To Country          : '
									|| gc_ixshiptocountry);
				xx_location_and_log(g_log,
									   'Ship To Zipcode          : '
									|| gc_ixshiptozipcode);
			ELSIF gc_sale_type = g_refund
			THEN
------------------------------------------------------
-- Retrieve Additional Ship To Info for REFUND
------------------------------------------------------
				BEGIN
					xx_location_and_log(g_loc,
										'Retrieving the SHIP TO Addresses. ');
					gc_error_debug :=    'Ship to Site Use ID: '
									  || gn_ship_to_site_use_id;

					IF (gn_ship_to_site_use_id IS NOT NULL)
					THEN
						SELECT hl.postal_code,
							   NVL(hl.state,
								   hl.province)
						INTO   gc_ixshiptozipcode,
							   gc_ixshiptostate
						FROM   hz_cust_site_uses_all hcsu,
							   hz_cust_acct_sites_all hcas,
							   hz_party_sites hps,
							   hz_locations hl
						WHERE  hcsu.cust_acct_site_id = hcas.cust_acct_site_id
						AND    hcas.party_site_id = hps.party_site_id
						AND    hl.location_id = hps.location_id
						AND    hcsu.site_use_id = gn_ship_to_site_use_id;
					ELSE
						gc_ixshiptozipcode := gc_aops_dep_shipto_zipcode;
						gc_ixshiptostate := gc_aops_dep_shipto_state;
					END IF;

					--Start of changes of Defect# 34612

					BEGIN
						IF (gc_ixshiptozipcode  is null)
						then

							SELECT	attribute1 shiptozipcode,
									attribute2 shiptostate
							INTO 	gc_ixshiptozipcode,
									gc_ixshiptostate
							FROM 	xx_iby_deposit_aops_order_dtls
							WHERE 	aops_order_number =
											(SELECT ORIG_SYS_DOCUMENT_REF
											FROM xx_ar_order_receipt_dtl
											WHERE order_payment_id = gn_order_payment_id
											)
							GROUP BY attribute1, attribute2;

						END IF;

					EXCEPTION
						WHEN NO_DATA_FOUND
						THEN
							xx_location_and_log
								(g_loc,
								'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve Ship To Zip Code (refund). ');
							gc_ixshiptostate := NULL;
							gc_ixshiptozipcode := NULL;
						WHEN OTHERS
						THEN
							xx_location_and_log
								(g_loc,
								'Entering WHEN OTHERS Exception in XX_SET_POST_TRX_VARIABLES for Retrieve Ship To Zip Code (refund). ');
							gc_ixshiptostate := NULL;
							gc_ixshiptozipcode := NULL;
							xx_location_and_log(g_log,
												'Error at: Retrieving the SHIP TO Addresses for Refund. '
												|| 'Error Message: '
												|| SQLERRM);
					END;

					--End of changes of Defect# 34612
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve Additional Ship To Info (refund). ');
						gc_ixshiptostate := NULL;
						gc_ixshiptozipcode := NULL;
				END;

				xx_location_and_log(g_log,
									   'Ship To State            : '
									|| gc_ixshiptostate);
				xx_location_and_log(g_log,
									   'Ship To Zipcode          : '
									|| gc_ixshiptozipcode);
			END IF;   -- ship to information
		END;

------------------------------------------------------
-- Retrieve IXPURCHASERNAME
------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving the IXPURCHASERNAME. ');
			gc_error_debug :=    'Bill To Contact ID: '
							  || gn_bill_to_contact_id;

--            SELECT    rcb.first_name
--                   || ' '
--                   || rcb.last_name
--            INTO   gc_ixpurchasername
--            FROM   ra_contacts rcb
--            WHERE  rcb.contact_id = gn_bill_to_contact_id;
			SELECT    SUBSTRB(party.person_first_name,
							  1,
							  50)
				   || ' '
				   || SUBSTRB(party.person_last_name,
							  1,
							  50)
			INTO   gc_ixpurchasername
			FROM   hz_cust_account_roles acct_role,
				   hz_parties party,
				   hz_relationships rel,
				   hz_org_contacts org_cont,
				   hz_parties rel_party,
				   hz_cust_accounts role_acct
			WHERE  acct_role.cust_account_role_id = gn_bill_to_contact_id
			AND    acct_role.party_id = rel.party_id
			AND    acct_role.role_type = 'CONTACT'
			AND    org_cont.party_relationship_id = rel.relationship_id
			AND    rel.subject_id = party.party_id
			AND    rel.party_id = rel_party.party_id
			AND    rel.subject_table_name = 'HZ_PARTIES'
			AND    rel.object_table_name = 'HZ_PARTIES'
			AND    acct_role.cust_account_id = role_acct.cust_account_id
			AND    role_acct.party_id = rel.object_id;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				xx_location_and_log
						(g_loc,
						 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve IXPURCHASERNAME. ');

				BEGIN
					SELECT xoha.cust_contact_name
					INTO   gc_ixpurchasername
					FROM   xx_om_header_attributes_all xoha
					WHERE  xoha.header_id = gn_order_header_id;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve IXPURCHASERNAME(2). ');
						gc_ixpurchasername := NULL;
				END;
		END;

		xx_location_and_log(g_log,
							   'Purchaser Name           : '
							|| gc_ixpurchasername);

--------------------------------------------------------------
-- Retrieve IXCOSTCENTER, IXDESKTOPLOCATION, IXRELEASENUMBER
--------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Retrieving the IXCOSTCENTER, IXDESKTOPLOCATION, IXRELEASENUMBER. ');
			gc_error_debug :=    'Order Header ID: '
							  || gn_order_header_id;

			SELECT xoha.cost_center_dept,
				   xoha.desk_del_addr,
				   xoha.release_number
			INTO   gc_ixcostcenter,
				   gc_ixdesktoplocation,
				   gc_ixreleasenumber
			FROM   xx_om_header_attributes_all xoha
			WHERE  xoha.header_id = gn_order_header_id;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				xx_location_and_log
						  (g_loc,
						   'Entering NO_DATA_FOUND Exception in XX_SET_POST_TRX_VARIABLES for Retrieve IXCOSTCENTER,. ');
				gc_ixcostcenter := NULL;
				gc_ixdesktoplocation := NULL;
				gc_ixreleasenumber := NULL;
		END;

		xx_location_and_log(g_log,
							   'Cost Center              : '
							|| gc_ixcostcenter);
		xx_location_and_log(g_log,
							   'Desktop Application      : '
							|| gc_ixdesktoplocation);
		xx_location_and_log(g_log,
							   'Release Number           : '
							|| gc_ixreleasenumber);
		-- Defect 14579, moved NET DATA processing to a separate procedure to be called for
		-- iRec receipts paying more than one transaction
		process_net_data;

--------------------------------------------------------------------------
-- Set IXREFERENCE
--------------------------------------------------------------------------
-- Defect 13466 - IXREFERENCE moved from XX_SET_POST_RECEIPT_VARIABLES
		BEGIN
			xx_location_and_log(g_loc,
								'Set/Retrieve IXREFERENCE. ');
			gc_error_debug :=    'Order Number: '
							  || gn_order_number;

			IF gc_remit_processing_type = g_poe_int_store_cust
			THEN
				gc_ixreference :=    'OM'
								  || '#'
								  || gn_order_number
								  || '#'
								  || gn_order_payment_id;
			ELSIF    (gc_sale_type = g_sale)
				  OR (    gc_sale_type = g_refund
					  AND gc_ixreserved43 IS NULL)
			THEN
				BEGIN
					gc_error_debug :=    gc_error_debug
									  || '. TRXNMID: '
									  || gn_trxnmid;

					SELECT itc.referencecode
					INTO   gc_ixreference
					FROM   iby_trxn_core itc
					WHERE  itc.trxnmid = gn_trxnmid;
				EXCEPTION
					WHEN OTHERS
					THEN
						xx_location_and_log
							 (g_loc,
							  'Entering NO_DATA_FOUND Exception in XX_SET_POST_RECEIPT_VARIABLES for Set IXREFERENCE. ');
						gc_ixreference := NULL;
				END;

				xx_location_and_log(g_log,
									   'Reference Code           : '
									|| gc_ixreference);
			END IF;
		END;

--------------------------------------------------------------------------
-- Change Value of gc_ixoptions based on gc_ixswipe value
--------------------------------------------------------------------------Version 27.2
		IF NVL (gc_ixswipe ,'-1') <> '-1' THEN
		   gc_ixoptions := REPLACE ( gc_ixoptions , '*CEM_Manual', '*CEM_Swiped');
		END IF;

	END xx_set_post_trx_variables;

-- +====================================================================+
-- | PROCEDURE  : XX_CALC_TAX_DISC_SHIP_AMTS                            |
-- |                                                                    |
-- | DESCRIPTION: Calculates the sales tax, discount, shipping, and     |
-- |              miscellaneous charges amounts.                        |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_calc_tax_disc_ship_amts
	IS
	BEGIN
		xx_location_and_log(g_loc,
							'Calculating Tax, Discount, and Shipment Amounts. ');

------------------------------------------------------
-- Calculate US TAX
------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Calculating US sales tax amounts. ');

			IF (gc_ou_us_desc = gc_org_name)
			THEN   -- FOR US
				IF (gc_inv_flag = 'Y')
				THEN
					-- Retrieve Tax from Invoices since it exists
					xx_location_and_log(g_loc,
										'Retrieving the SALES TAX Information for US - AR. ');
					gc_error_debug :=    'Customer Trx ID: '
									  || gn_customer_trx_id;

					IF gc_sale_type = g_sale
					THEN
						SELECT   NVL(SUM(rctl.extended_amount),
									 0)
							   * 100
						INTO   gc_ixtotalsalestaxamount
						/* Commented for QC Defect 26781
										  FROM   ra_customer_trx_lines_all rctl,
												 ar_vat_tax_all avt
										  WHERE  rctl.line_type = 'TAX'
										  AND    rctl.vat_tax_id = avt.vat_tax_id
										  AND    rctl.customer_trx_id = gn_customer_trx_id
										  AND    avt.tax_type = 'SALES_TAX';
										  */
						-- Below query added for QC Defect 26781
						FROM   ra_customer_trx_lines_all rctl, zx_rates_b avt, zx_taxes_b ztb
						WHERE  rctl.line_type = 'TAX'
						AND    rctl.vat_tax_id = avt.tax_rate_id
						AND    rctl.customer_trx_id = gn_customer_trx_id
						AND    ztb.tax = avt.tax
						AND    ztb.tax_type_code = 'SALES_TAX';

						xx_location_and_log(g_log,
											   'Total Sales Tax Amount AR: '
											|| gc_ixtotalsalestaxamount);
					ELSIF gc_sale_type = g_refund
					THEN
						SELECT   NVL(SUM(rctl.extended_amount),
									 0)
							   * 100
						INTO   gc_totsalestaxamount
						/*Commented for QC Defect 26781
										  FROM   ra_customer_trx_lines_all rctl,
												 ar_vat_tax_all avt
										  WHERE  rctl.line_type = 'TAX'
										  AND    rctl.vat_tax_id = avt.vat_tax_id
										  AND    rctl.customer_trx_id = gn_customer_trx_id
										  AND    avt.tax_type = 'SALES_TAX';
						*/
						--Below query added for Qc Defect 26781
						FROM   ra_customer_trx_lines_all rctl, zx_rates_b avt, zx_taxes_b ztb
						WHERE  rctl.line_type = 'TAX'
						AND    rctl.vat_tax_id = avt.tax_rate_id
						AND    rctl.customer_trx_id = gn_customer_trx_id
						AND    ztb.tax = avt.tax
						AND    ztb.tax_type_code = 'SALES_TAX';

						xx_location_and_log(g_log,
											   'Total Sales Tax Amount AR: '
											|| gc_totsalestaxamount);

--------------------------------------------------------------
-- Tax Calculations for MIXED Orders (Invoices) for REFUNDS
--------------------------------------------------------------
						BEGIN
							gc_invoice_type := xx_get_invoice_type(gn_customer_trx_id);

							IF (gc_invoice_type = 'MIXED_ORDER')
							THEN
								gc_ixtotalsalestaxamount :=   gc_totsalestaxamount
															* -1;   -- To Have positive Tax on AJB
							ELSE
								gc_ixtotalsalestaxamount := ABS(gc_totsalestaxamount);
							END IF;

							xx_location_and_log(g_log,
												   'Invoice Type             : '
												|| gc_invoice_type);
							xx_location_and_log(g_log,
												   'Total Sale Tax Amt Actual: '
												|| gc_totsalestaxamount);
							xx_location_and_log(g_log,
												   'Total Sale Tax Amt       : '
												|| gc_ixtotalsalestaxamount);
						END;
					END IF;
				ELSIF(gc_inv_flag = 'N')
				THEN
					-- Retrieve Tax from Order since Invoice Does not Exist
					xx_location_and_log(g_loc,
										'Retrieving the SALES TAX Information for US - OM - ORDER. ');
					gc_error_debug :=    'Order Header ID: '
									  || gn_order_header_id;

					SELECT   NVL(SUM(tax_value),
								 0)
						   * 100
					INTO   gc_ixtotsalestaxamt_order
					FROM   oe_order_lines_all
					WHERE  header_id = gn_order_header_id
					AND    line_category_code = 'ORDER';

					-- Retrieve Tax from Order/Return since Invoice Does not Exist
					-- The Value will be positive,but since it is refund functional value will be negative
					xx_location_and_log(g_loc,
										'Retrieving the SALES TAX Information for US - OM - RETURN. ');
					gc_error_debug :=    'Order Header ID: '
									  || gn_order_header_id;

					SELECT   NVL(SUM(tax_value),
								 0)
						   * 100
					INTO   gc_ixtotsalestaxamt_return
					FROM   oe_order_lines_all
					WHERE  header_id = gn_order_header_id
					AND    line_category_code = 'RETURN';

					-- Total Sales Amount
					gc_ixtotalsalestaxamount :=   gc_ixtotsalestaxamt_order
												- gc_ixtotsalestaxamt_return;

					IF gc_sale_type = g_refund
					THEN
--------------------------------------------------------------
-- Tax Calculations for MIXED Orders for REFUNDS
--------------------------------------------------------------
						gc_order_type := xx_get_order_type(gn_order_header_id);

						IF (gc_order_type = 'MIXED_ORDER')
						THEN
							gc_ixtotalsalestaxamount :=   gc_ixtotalsalestaxamount
														* -1;
						ELSE
							gc_ixtotalsalestaxamount := ABS(gc_ixtotalsalestaxamount);
						END IF;
					END IF;

					xx_location_and_log(g_log,
										   'Order Type               : '
										|| gc_order_type);
					xx_location_and_log(g_log,
										   'Total Sales Tax OM ORDER : '
										|| gc_ixtotsalestaxamt_order);
					xx_location_and_log(g_log,
										   'Total Sales Tax OM RETURN: '
										|| gc_ixtotsalestaxamt_return);
					xx_location_and_log(g_log,
										   'Total Sales Tax Amt OM   : '
										|| gc_ixtotalsalestaxamount);
				END IF;
			END IF;   -- FOR US
		END;

------------------------------------------------------
-- Calculate CA TAX (GST and PST)
------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Calculating CA sales tax amounts. ');

			IF (gc_ou_ca_desc = gc_org_name)
			THEN   -- FOR CA
				IF (gc_inv_flag = 'Y')
				THEN
					-- IXOTHERTAXAMOUNT (PST)
					xx_location_and_log(g_loc,
										'Retrieving the COUNTY TAX Information for CA AR. ');
					gc_error_debug :=    'Customer Trx ID: '
									  || gn_customer_trx_id;

					IF gc_sale_type = g_sale
					THEN
						SELECT   NVL(SUM(rctl.extended_amount),
									 0)
							   * 100
						INTO   gn_other_tax_amount
						/* Commented for QC Defect 26781
										  FROM   ra_customer_trx_lines_all rctl,
												 ar_vat_tax_all avt
										  WHERE  rctl.customer_trx_id = gn_customer_trx_id
										  AND    rctl.line_type = 'TAX'
										  AND    rctl.vat_tax_id = avt.vat_tax_id
										  AND    avt.tax_code = 'COUNTY';
						*/

						--Below query added for QC Defect 26781
						FROM   ra_customer_trx_lines_all rctl, zx_rates_b avt, zx_taxes_b ztb
						WHERE  rctl.line_type = 'TAX'
						AND    rctl.vat_tax_id = avt.tax_rate_id
						AND    rctl.customer_trx_id = gn_customer_trx_id
						AND    ztb.tax = avt.tax
						AND    ztb.tax_type_code = 'COUNTY';

						xx_location_and_log(g_log,
											   'Other Tax Amount AR      : '
											|| gn_other_tax_amount);
						-- IXNATIONALTAXAMOUNT (GST)
						xx_location_and_log(g_loc,
											'Retrieving the STATE TAX Information for CA AR. ');
						gc_error_debug :=    'Customer Trx ID: '
										  || gn_customer_trx_id;

						SELECT   NVL(SUM(rctl.extended_amount),
									 0)
							   * 100
						INTO   gn_state_tax_amount
						/* Commented for QC Defect 26781
										  FROM   ra_customer_trx_lines_all rctl,
												 ar_vat_tax_all avt
										  WHERE  rctl.customer_trx_id = gn_customer_trx_id
										  AND    rctl.line_type = 'TAX'
										  AND    rctl.vat_tax_id = avt.vat_tax_id
										  AND    avt.tax_code = 'STATE';
						*/
						-- Below query added for QC Defect 26781
						FROM   ra_customer_trx_lines_all rctl, zx_rates_b avt, zx_taxes_b ztb
						WHERE  rctl.line_type = 'TAX'
						AND    rctl.vat_tax_id = avt.tax_rate_id
						AND    rctl.customer_trx_id = gn_customer_trx_id
						AND    ztb.tax = avt.tax
						AND    ztb.tax_type_code = 'STATE';

						xx_location_and_log(g_log,
											   'State Tax Amount CA AR   : '
											|| gn_state_tax_amount);
					ELSIF gc_sale_type = g_refund
					THEN
						-- IXOTHERTAXAMOUNT (PST)
						xx_location_and_log(g_loc,
											'Getting the COUNTY TAX Information for CA AR. ');
						gc_error_debug :=    'Customer Trx ID: '
										  || gn_customer_trx_id;

						SELECT   NVL(SUM(rctl.extended_amount),
									 0)
							   * 100
						INTO   gn_other_tax_amount_act
						/*Commented for QC Defect 26781
										  FROM   ra_customer_trx_lines_all rctl,
												 ar_vat_tax_all avt
										  WHERE  rctl.customer_trx_id = gn_customer_trx_id
										  AND    rctl.line_type = 'TAX'
										  AND    rctl.vat_tax_id = avt.vat_tax_id
										  AND    avt.tax_code = 'COUNTY';
						*/

						--Below query added for QC Defect 26781
						FROM   ra_customer_trx_lines_all rctl, zx_rates_b avt, zx_taxes_b ztb
						WHERE  rctl.line_type = 'TAX'
						AND    rctl.vat_tax_id = avt.tax_rate_id
						AND    rctl.customer_trx_id = gn_customer_trx_id
						AND    ztb.tax = avt.tax
						AND    ztb.tax_type_code = 'COUNTY';

						xx_location_and_log(g_log,
											   'Other Tax Amount AR      : '
											|| gn_other_tax_amount_act);
						-- IXNATIONALTAXAMOUNT (GST)
						xx_location_and_log(g_loc,
											'Getting the STATE TAX Information for CA AR. ');
						gc_error_debug :=    'Customer Trx ID: '
										  || gn_customer_trx_id;

						SELECT   NVL(SUM(rctl.extended_amount),
									 0)
							   * 100
						INTO   gn_state_tax_amount_act
										  /* Commented for QC Defect 26781
										  FROM   ra_customer_trx_lines_all rctl,
												 ar_vat_tax_all avt
										  WHERE  rctl.customer_trx_id = gn_customer_trx_id
										  AND    rctl.line_type = 'TAX'
										  AND    rctl.vat_tax_id = avt.vat_tax_id
										  AND    avt.tax_code = 'STATE';
						*/
						FROM   ra_customer_trx_lines_all rctl, zx_rates_b avt, zx_taxes_b ztb
						WHERE  rctl.line_type = 'TAX'
						AND    rctl.vat_tax_id = avt.tax_rate_id
						AND    rctl.customer_trx_id = gn_customer_trx_id
						AND    ztb.tax = avt.tax
						AND    ztb.tax_type_code = 'SALES';

						xx_location_and_log(g_log,
											   'State Tax Amount CA AR   : '
											|| gn_state_tax_amount_act);

--------------------------------------------------------------
-- Tax Calculations for MIXED Orders (Invoices) for REFUNDS
--------------------------------------------------------------
						BEGIN
							gc_invoice_type := xx_get_invoice_type(gn_customer_trx_id);

							IF (gc_invoice_type = 'MIXED_ORDER')
							THEN
								gn_state_tax_amount :=   gn_state_tax_amount_act
													   * -1;
								gn_other_tax_amount :=   gn_other_tax_amount_act
													   * -1;
							ELSE
								gn_state_tax_amount := ABS(gn_state_tax_amount_act);
								gn_other_tax_amount := ABS(gn_other_tax_amount_act);
							END IF;
						END;

						xx_location_and_log(g_log,
											   'Invoice Type             : '
											|| gc_invoice_type);
						xx_location_and_log(g_log,
											   'State Tax Amount - Actual: '
											|| gn_state_tax_amount_act);
						xx_location_and_log(g_log,
											   'Other Tax Amount - Actual: '
											|| gn_other_tax_amount_act);
						xx_location_and_log(g_log,
											   'State Tax Amount         : '
											|| gn_state_tax_amount);
						xx_location_and_log(g_log,
											   'Other Tax Amount         : '
											|| gn_other_tax_amount);
					END IF;
				ELSIF(gc_inv_flag = 'N')
				THEN
					-- IXOTHERTAXAMOUNT (PST)
					xx_location_and_log(g_loc,
										'Retrieving the COUNTY TAX Information for CA OM. ');
					gc_error_debug :=    'Order Header ID: '
									  || gn_order_header_id;

					SELECT   NVL(SUM(xoml.canada_pst_tax),
								 0)
						   * 100
					INTO   gn_other_tax_amount
					FROM   oe_order_lines_all ool, xx_om_line_attributes_all xoml
					WHERE  ool.line_id = xoml.line_id
					AND    ool.header_id = gn_order_header_id;

					xx_location_and_log(g_log,
										   'Other Tax Amount OM      : '
										|| gn_other_tax_amount);
					-- IXNATIONALTAXAMOUNT (GST)
					xx_location_and_log(g_loc,
										'Retrieving the ORDER TAX Information for CA OM. ');
					gc_error_debug :=    'Order Header ID: '
									  || gn_order_header_id;

					SELECT NVL(SUM(tax_value),
							   0)
					INTO   gc_ixtotsalestaxamt_order
					FROM   oe_order_lines_all
					WHERE  header_id = gn_order_header_id
					AND    line_category_code = 'ORDER';

					xx_location_and_log(g_loc,
										'Retrieving the RETURN TAX Information for CA OM. ');
					gc_error_debug :=    'Order Header ID: '
									  || gn_order_header_id;

					SELECT NVL(SUM(tax_value),
							   0)
					INTO   gc_ixtotsalestaxamt_return
					FROM   oe_order_lines_all
					WHERE  header_id = gn_order_header_id
					AND    line_category_code = 'RETURN';

					xx_location_and_log(g_loc,
										'Calculating GST Total for CA OM. ');
					gc_error_debug :=    'Order Header ID: '
									  || gn_order_header_id;
					gn_state_tax_amount :=
							  (   (  gc_ixtotsalestaxamt_order
								   - gc_ixtotsalestaxamt_return)
							   - (  gn_other_tax_amount
								  / 100) )
							* 100;
--------------------------------------------------------------
-- Tax Calculations for MIXED Orders for REFUNDS
--------------------------------------------------------------
					gc_order_type := xx_get_order_type(gn_order_header_id);

					IF (gc_order_type = 'MIXED_ORDER')
					THEN
						gn_state_tax_amount :=   gn_state_tax_amount
											   * -1;
						gn_other_tax_amount :=   gn_other_tax_amount
											   * -1;
					ELSE
						gn_state_tax_amount := ABS(gn_state_tax_amount);
						gn_other_tax_amount := ABS(gn_other_tax_amount);
					END IF;

					xx_location_and_log(g_log,
										   'Order Type               : '
										|| gc_order_type);
					xx_location_and_log(g_log,
										   'State Tax Amt OM - Order : '
										|| gc_ixtotsalestaxamt_order);
					xx_location_and_log(g_log,
										   'State Tax Amt OM - Return: '
										|| gc_ixtotsalestaxamt_return);
					xx_location_and_log(g_log,
										   'State Tax Amount OM      : '
										|| gn_state_tax_amount);
					xx_location_and_log(g_log,
										   'State Tax Amount OM other: '
										|| gn_other_tax_amount);
				END IF;

				-- County Tax is IXNATIONALTAXAMOUNT -- No County Tax
				gc_ixnationaltaxamount := gn_state_tax_amount;   -- GST
				gc_ixothertaxamount := gn_other_tax_amount;   -- PST
				gc_ixtotalsalestaxamount :=   gn_state_tax_amount
											+ gn_other_tax_amount;
			ELSE
				gc_ixnationaltaxamount := '0';
				gc_ixothertaxamount := '0';
			END IF;   -- FOR CA
		END;

------------------------------------------------------------
-- Set IXTOTALSALESTAXCOLLIND and IXNATIONALTAXCOLLINDICATOR
------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'***** Executing XX_SET_TAX_COLL_INDICATORS from XX_CALC_TAX_DISC_SHIP_AMTS ***** ');
			xx_set_tax_coll_indicators;
		END;

------------------------------------------------------
-- Calculate IXTAXABLEAMOUNT
------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Calculating Taxable Amount. ');

			IF (gc_inv_flag = 'Y')
			THEN
				xx_location_and_log(g_loc,
									'Retrieving the Taxable Amount AR. ');
				gc_error_debug :=    'Customer Trx ID: '
								  || gn_customer_trx_id;

				SELECT   ABS(NVL(SUM(taxable.extended_amount),
								 0) )
					   * 100
				INTO   gc_ixtaxableamount
				FROM   ra_customer_trx_lines_all taxable
				WHERE  taxable.customer_trx_id = gn_customer_trx_id
				AND    EXISTS(SELECT 1
							  FROM   ra_customer_trx_lines_all tax
							  WHERE  tax.link_to_cust_trx_line_id = taxable.customer_trx_line_id);

				xx_location_and_log(g_log,
									   'Taxable Amount AR        : '
									|| gc_ixtaxableamount);
			ELSIF(gc_inv_flag = 'N')
			THEN
				xx_location_and_log(g_loc,
									'Retrieving the Taxable Amount OM for US - OM - ORDER. ');
				gc_error_debug :=    'Order Header ID: '
								  || gn_order_header_id
								  || '. Sale Type: '
								  || gc_sale_type;

				IF gc_sale_type = g_sale
				THEN
					SELECT   ROUND(NVL(SUM(  shipped_quantity
										   * unit_selling_price),
									   0),
								   2)
						   * 100
					INTO   gc_ixtaxableamount_order
					FROM   oe_order_lines_all
					WHERE  header_id = gn_order_header_id
					AND    line_category_code = 'ORDER';

					xx_location_and_log(g_loc,
										'Retrieving the Taxable Amount OM for US - OM- RETURN. ');
					gc_error_debug :=    'Order Header ID: '
									  || gn_order_header_id;

					-- The Value will be positive,but since it is refund functional value will be negative
					SELECT   ROUND(NVL(SUM(  shipped_quantity
										   * unit_selling_price),
									   0),
								   2)
						   * 100
					INTO   gc_ixtaxableamount_return
					FROM   oe_order_lines_all
					WHERE  header_id = gn_order_header_id
					AND    line_category_code = 'RETURN';

					-- Total Taxable Amount
					gc_ixtaxableamount := ABS(  gc_ixtaxableamount_order
											  - gc_ixtaxableamount_return);
					xx_location_and_log(g_log,
										   'Taxable Amount OM Order  : '
										|| gc_ixtaxableamount_order);
					xx_location_and_log(g_log,
										   'Taxable Amount OM Return : '
										|| gc_ixtaxableamount_return);
					xx_location_and_log(g_log,
										   'Taxable Amount OM        : '
										|| gc_ixtaxableamount);
				ELSIF gc_sale_type = g_refund
				THEN
					SELECT   ABS(ROUND(NVL(SUM(  shipped_quantity
											   * unit_selling_price),
										   0),
									   2) )
						   * 100
					INTO   gc_ixtaxableamount
					FROM   oe_order_lines_all
					WHERE  header_id = gn_order_header_id;

					xx_location_and_log(g_log,
										   'Taxable Amount OM        : '
										|| gc_ixtaxableamount);
				END IF;
			END IF;
		END;

------------------------------------------------------
-- Calculate IXDISCOUNTAMOUNT
------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Calculating Discount Amount. ');

			IF (gc_inv_flag = 'Y')
			THEN
				xx_location_and_log(g_loc,
									'Retrieving the Discount Amount AR. ');
				gc_error_debug :=    'Customer Trx ID: '
								  || gn_customer_trx_id;

				SELECT   ABS(NVL(SUM(rctl.extended_amount),
								 0) )
					   * 100
				INTO   gc_ixdiscountamount
				FROM   ra_customer_trx_lines_all rctl
				WHERE  rctl.customer_trx_id = gn_customer_trx_id
				AND    rctl.interface_line_attribute11 <> '0'
				AND    rctl.interface_line_attribute8 = '0';

				xx_location_and_log(g_log,
									   'Discount Amount AR       : '
									|| gc_ixdiscountamount);
			ELSIF(gc_inv_flag = 'N')
			THEN
				xx_location_and_log(g_loc,
									'Retrieving the Discount Amount OM. ');
				gc_error_debug :=    'Order Header ID: '
								  || gn_order_header_id;

				-- Added decodes to select below for defect 12468
				SELECT   ABS(ROUND(  NVL(SUM(  shipped_quantity
											 * DECODE(line_category_code,
													  'RETURN', unit_list_price
													   * -1,
													  unit_list_price) ),
										 0)
								   - NVL(SUM(  shipped_quantity
											 * DECODE(line_category_code,
													  'RETURN', unit_selling_price
													   * -1,
													  unit_selling_price) ),
										 0),
								   2) )
					   * 100
				INTO   gc_ixdiscountamount
				FROM   oe_order_lines_all
				WHERE  header_id = gn_order_header_id;

				xx_location_and_log(g_log,
									   'Discount Amount OM       : '
									|| gc_ixdiscountamount);
			END IF;
		END;

------------------------------------------------------
-- Calculate IXSHIPPINGAMOUNT
------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Calculating the IX Shipping Amount. ');

			IF gc_sale_type = g_sale
			THEN
				SELECT   ABS(ROUND(NVL(SUM(  shipped_quantity
										   * unit_selling_price),
									   0),
								   2) )
					   * 100
				INTO   gc_tot_order_amount
				FROM   oe_order_lines_all
				WHERE  header_id = gn_order_header_id;
			ELSIF gc_sale_type = g_refund
			THEN
				SELECT   ABS(ROUND(NVL(SUM(  invoiced_quantity
										   * unit_selling_price),
									   0),
								   2) )
					   * 100
				INTO   gc_tot_order_amount
				FROM   oe_order_lines_all
				WHERE  header_id = gn_order_header_id;
			END IF;
		EXCEPTION
			WHEN OTHERS
			THEN
				xx_location_and_log
					 (g_loc,
					  'Entering NO_DATA_FOUND Exception in XX_CALC_TAX_DISC_SHIP_AMTS for Calculate IXSHIPPINGAMOUNT. ');
				gc_tot_order_amount := NULL;
		END;

		xx_location_and_log(g_log,
							   'Total Shipping Amt-Order : '
							|| gc_tot_order_amount);

------------------------------------------------------
-- Calculate IXMISCCHARGE
------------------------------------------------------
		BEGIN
			IF (gc_inv_flag = 'Y')
			THEN
				xx_location_and_log(g_loc,
									'Calculating the ixmisccharge - AR. ');
				gc_error_debug :=    'Customer Trx ID: '
								  || gn_customer_trx_id;

				SELECT   ABS(NVL(SUM(rctl.extended_amount),
								 0) )
					   * 100
				INTO   gc_ixmisccharge
				FROM   ra_customer_trx_lines_all rctl, mtl_system_items_b msi
				WHERE  rctl.customer_trx_id = gn_customer_trx_id
				AND    rctl.inventory_item_id = msi.inventory_item_id
				AND    msi.organization_id = gn_master_org_id
				AND    msi.segment1 = 'AC';



				xx_location_and_log(g_log,
									   'Misc Charge - AR         : '
									|| gc_ixmisccharge);
			ELSE
				xx_location_and_log(g_loc,
									'Calculating the ixmisccharge - OM. ');
				gc_error_debug :=    'Order Header ID: '
								  || gn_order_header_id;

				SELECT   ROUND(NVL(SUM(  oola.shipped_quantity
									   * oola.unit_selling_price),
								   0),
							   2)
					   * 100
				INTO   gc_ixmisccharge
				FROM   oe_order_lines_all oola, mtl_system_items_b msi
				WHERE  oola.header_id = gn_order_header_id
				AND    oola.inventory_item_id = msi.inventory_item_id
				AND    msi.organization_id = gn_master_org_id
				AND    msi.segment1 = 'AC';

				xx_location_and_log(g_log,
									   'Misc Charge - OM         : '
									|| gc_ixmisccharge);
			END IF;
		END;
	END xx_calc_tax_disc_ship_amts;

-- +====================================================================+
-- | PROCEDURE  : XX_SET_RECEIPT_TRANS_RECPT_NUM                        |
-- |                                                                    |
-- | DESCRIPTION: Sets IXRECEIPT_NUMBER, IXTRANSNUMBER, IXRECPTNUMBER,  |
-- |              IXORIGINALINVOICENO, and ORIG_INVOICE_NUM             |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_set_receipt_trans_recpt_num
	IS
	BEGIN
		xx_location_and_log
				 (g_loc,
				  'Setting Receipt, Trans, and Recpt Number based on Sale Type and Remittance Processing Type (SALE). ');

		IF gc_sale_type = g_sale
		THEN
			xx_location_and_log(g_loc,
								'Setting Receipt, Trans, and Recpt Number for Sale Type of SALE. ');

			IF (gc_remit_processing_type = g_poe_int_store_cust)
			THEN
				xx_location_and_log
					(g_loc,
					 'Setting Receipt, Trans, and Recpt Number for Remit Processing type of POE_INT_STORE_CUST (SALE). ');
				gc_ixreceiptnumber :=    'OM'
									  || '#'
									  || gn_order_number
									  || '#'
									  || gn_order_payment_id;
				gc_ixtransnumber := gn_order_number;
				gc_ixrecptnumber :=    'OM'
									|| gn_order_payment_id;
			ELSIF(gc_remit_processing_type = g_poe_single_pmt_multi_ord)
			THEN
				xx_location_and_log
					(g_loc,
					 'Setting Receipt, Trans, and Recpt Number for Remit Processing type of POE_SINGLE_PMT_MULTI_ORDER (SALE). ');
				gc_ixreceiptnumber :=    gc_receipt_number
									  || '#'
									  || gc_transaction_number
									  || '#'
									  || gn_order_payment_id;
				gc_ixtransnumber := gc_orig_sys_document_ref;
				gc_ixrecptnumber := gc_receipt_number;
			ELSIF(    gc_remit_processing_type = g_irec
				  AND gc_invoice_retrieval_status = g_single)
			THEN
				xx_location_and_log
					(g_loc,
					 'Setting Receipt, Trans, and Recpt Number for Remit Processing type of IREC - Single Inv (SALE). ');
				gc_ixreceiptnumber :=    gc_receipt_number
									  || '#'
									  || gn_order_number
									  || '#'
									  || gn_order_payment_id;
				gc_ixtransnumber := gn_order_number;
				gc_ixrecptnumber := gc_receipt_number;
			ELSIF(    gc_remit_processing_type = g_service_contracts--Added for V47.0 5/Mar/2018
				  AND gc_invoice_retrieval_status = g_single)
			THEN
				xx_location_and_log
					(g_loc,
					 'Setting Receipt, Trans, and Recpt Number for Remit Processing type of SERVICE-CONTRACTS - Single Inv (SALE). ');
				gc_ixreceiptnumber :=    gc_receipt_number
									  || '#'
									  || gn_order_number
									  || '#'
									  || gn_order_payment_id;
				gc_ixtransnumber := gc_trx_number;
				gc_ixrecptnumber := gc_receipt_number;
			ELSIF(    gc_oapforder_id LIKE 'AR%'
				  AND (   gb_is_deposit_receipt = TRUE
					   OR gc_is_deposit = 'Y') )
			THEN   -- Defect 13498
				xx_location_and_log(g_loc,
									'Setting Receipt, Trans, and Recpt Number for Deposit (SALE). ');
				gc_ixreceiptnumber :=    gc_receipt_number
									  || '#'
									  || gc_orig_sys_document_ref
									  || '#'
									  || gn_order_payment_id;   -- Defect 13498
				gc_ixtransnumber := gc_orig_sys_document_ref;
				gc_ixrecptnumber := gc_receipt_number;
			ELSE
				xx_location_and_log
					(g_loc,
					 'Setting Receipt, Trans, and Recpt Number for Remit Processing type for NON-POE_INT_STORE_CUST (SALE). ');
				gc_ixreceiptnumber :=    gc_receipt_number
									  || '#'
									  || gn_order_number
									  || '#'
									  || gn_order_payment_id;
				gc_ixtransnumber := NVL(gc_trx_number,
										gn_order_number);
				gc_ixrecptnumber := gc_receipt_number;
			END IF;
		ELSIF gc_sale_type = g_refund
		THEN
			xx_location_and_log(g_loc,
								'Setting Receipt, Trans, and Recpt Number for Sale Type of REFUND. ');

			IF (gc_remit_processing_type = g_poe_int_store_cust)
			THEN
				xx_location_and_log
					(g_loc,
					 'Setting Receipt, Trans, and Recpt Number for Remit Processing type of POE_INT_STORE_CUST (REFUND). ');
				gc_ixreceiptnumber :=    'OM'
									  || '#'
									  || gn_order_number
									  || '#'
									  || gn_order_payment_id;
				gc_ixtransnumber := gn_order_number;
				gc_ixrecptnumber :=    'OM'
									|| gn_order_payment_id;
			ELSIF(gc_remit_processing_type = g_poe_single_pmt_multi_ord)
			THEN
				xx_location_and_log
					(g_loc,
					 'Setting Receipt, Trans, and Recpt Number for Remit Processing type of POE_SINGLE_PMT_MULTI_ORDER (REFUND). ');
				gc_ixreceiptnumber :=    gc_receipt_number
									  || '#'
									  || gc_transaction_number
									  || '#'
									  || gn_order_payment_id;
				gc_ixtransnumber := gc_orig_sys_document_ref;
				gc_ixrecptnumber := gc_receipt_number;
			ELSIF(gc_remit_processing_type = g_ccrefund)
			THEN
				xx_location_and_log
						   (g_loc,
							'Setting Receipt, Trans, and Recpt Number for Remit Processing type of CCREFUND (REFUND). ');
				gc_ixreceiptnumber :=    gc_receipt_number
									  || '#'
									  || gc_trx_number
									  || '#'
									  || gn_order_payment_id;
				gc_ixtransnumber := gc_trx_number;
				gc_ixrecptnumber := gc_receipt_number;
			ELSIF(   gc_is_deposit_return = TRUE
				  OR gc_inv_flag = 'R')
			THEN   -- Defect 13498
				xx_location_and_log(g_loc,
									'Setting Receipt, Trans, and Recpt Number for Deposit (REFUND). ');
				gc_ixreceiptnumber :=
									 gc_receipt_number
								  || '#'
								  || gc_orig_sys_document_ref_dep
								  || '#'
								  || gn_order_payment_id;   -- Defect 13498
				gc_ixtransnumber := gc_orig_sys_document_ref_dep;   -- Defect 13498
				gc_ixrecptnumber := gc_receipt_number;
			ELSE
				xx_location_and_log
					(g_loc,
					 'Setting Receipt, Trans, and Recpt Number for Remit Processing type for NON-POE_INT_STORE_CUST (REFUND). ');
				gc_ixreceiptnumber :=    gc_receipt_number
									  || '#'
									  || gc_cm_number
									  || '#'
									  || gn_order_payment_id;
				gc_ixtransnumber := gc_cm_number;
				gc_ixrecptnumber := gc_receipt_number;
			END IF;

			xx_location_and_log(g_log,
								   'IXRECEIPTNUMBER          : '
								|| gc_ixreceiptnumber);
			xx_location_and_log(g_log,
								   'IXTRANSNUMBER            : '
								|| gc_ixtransnumber);
			xx_location_and_log(g_log,
								   'IXRECPTNUMBER            : '
								|| gc_ixrecptnumber);
		END IF;

------------------------------------------------------
-- Set IXORIGINALINVOICENO
------------------------------------------------------
		xx_location_and_log(g_loc,
							'Setting Original Invoice Number. ');

		IF (gc_sale_type = g_sale)
		THEN
			gc_ixoriginalinvoiceno := COALESCE(gc_trx_number,
											   gc_orig_sys_document_ref);   --,gc_orig_sys_document_ref);
		ELSIF(    gc_sale_type = g_refund
			  AND gc_remit_processing_type = g_poe_int_store_cust)
		THEN
			gc_ixoriginalinvoiceno := gc_trx_number;   -- gc_cm_number is not used for POE_INT_STORE_CUST
			gc_orig_invoice_num := gc_trx_number;
		ELSIF(    gc_sale_type = g_refund
			  AND gc_remit_processing_type = g_ccrefund)
		THEN
			gc_ixoriginalinvoiceno := gc_trx_number;
		ELSIF(gc_sale_type = g_refund)
		THEN
			gc_ixoriginalinvoiceno := gc_cm_number;
			gc_orig_invoice_num := gc_trx_number;
		END IF;

		xx_location_and_log(g_log,
							   'IXORIGINALINVOICENO      : '
							|| gc_ixoriginalinvoiceno);
		xx_location_and_log(g_log,
							   'Original Invoice Number  : '
							|| gc_orig_invoice_num);
	END xx_set_receipt_trans_recpt_num;

-- +====================================================================+
-- | PROCEDURE  : XX_PROCESS_CUST_EXCEPTIONS                            |
-- |                                                                    |
-- | DESCRIPTION:                                                       |
-- |                                                                    |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_process_cust_exceptions
	IS
	BEGIN
------------------------------------------------------
-- Process Specific Customer Exceptions #1
------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Processing Specific Customer Exceptions #1. ');
			gc_error_debug :=    'Customer Trx ID: '
							  || gn_customer_trx_id;

			IF (gc_customer_name = 'Fairfax County Government')
			THEN
				gc_ixbankuserdata :=    SUBSTR(gc_orig_sys_document_ref,
											   1,
											   9)
									 || SUBSTR(gc_orig_sys_document_ref,
											   -3);
			END IF;

			IF (    gc_customer_name = 'Anderson'
				AND gc_credit_card_vendor = 'AMEX')
			THEN
				gc_ixcustomerreferenceid :=    SUBSTR(gc_cust_po_number,
													  1,
													  6)
											|| SUBSTR(gc_ixdesktoplocation,
													  1,
													  4);
			END IF;

			IF (    gc_customer_name = 'Beckman'
				AND gc_credit_card_vendor = 'AMEX')
			THEN
				gc_ixcustomerreferenceid := gc_cust_po_number;
			END IF;

			IF (    gc_customer_name = 'Disney'
				AND gc_credit_card_vendor = 'AMEX')
			THEN
				gc_ixcustomerreferenceid := gc_ixdesktoplocation;
			END IF;

			xx_location_and_log(g_log,
								   'Customer TRX ID          : '
								|| gn_customer_trx_id);
			xx_location_and_log(g_log,
								   'Customer Name            : '
								|| gc_customer_name);
			xx_location_and_log(g_log,
								   'Bank User Data           : '
								|| gc_ixbankuserdata);
			xx_location_and_log(g_log,
								   'Customer Reference ID    : '
								|| gc_ixcustomerreferenceid);
			xx_location_and_log(g_log,
								   'Credit Card Vendor       : '
								|| gc_credit_card_vendor);
			xx_location_and_log(g_log,
								   'Customer Orig System Ref : '
								|| gc_cust_orig_system_ref);

			IF (gc_credit_card_vendor = 'AMEX')
			THEN
				xx_location_and_log(g_loc,
									'Retrieve AMEX Customer Exception - EXCEPT1. ');

				SELECT COUNT(1)
				INTO   gn_amex_except1
				FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
				WHERE  xftd.translate_id = xftv.translate_id
				AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
				AND    xftv.source_value1 = gc_cust_orig_system_ref
				AND    xftv.target_value1 = 'EXCEPT1'
				AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																		SYSDATE
																	  + 1)
				AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																		SYSDATE
																	  + 1)
				AND    xftv.enabled_flag = 'Y'
				AND    xftd.enabled_flag = 'Y';

				xx_location_and_log(g_log,
									   'Amex Except1             : '
									|| gn_amex_except1);
				xx_location_and_log(g_loc,
									'Retrieve AMEX Customer Exception - EXCEPT2. ');

				SELECT COUNT(1)
				INTO   gn_amex_except2
				FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
				WHERE  xftd.translate_id = xftv.translate_id
				AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
				AND    xftv.source_value1 = gc_cust_orig_system_ref
				AND    xftv.target_value1 = 'EXCEPT2'
				AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																		SYSDATE
																	  + 1)
				AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																		SYSDATE
																	  + 1)
				AND    xftv.enabled_flag = 'Y'
				AND    xftd.enabled_flag = 'Y';

				xx_location_and_log(g_log,
									   'Amex Except2             : '
									|| gn_amex_except2);
				xx_location_and_log(g_loc,
									'Retrieve AMEX Customer Exception - EXCEPT3. ');

				SELECT COUNT(1)
				INTO   gn_amex_except3
				FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
				WHERE  xftd.translate_id = xftv.translate_id
				AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
				AND    xftv.source_value1 = gc_cust_orig_system_ref
				AND    xftv.target_value1 = 'EXCEPT3'
				AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																		SYSDATE
																	  + 1)
				AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																		SYSDATE
																	  + 1)
				AND    xftv.enabled_flag = 'Y'
				AND    xftd.enabled_flag = 'Y';

				xx_location_and_log(g_log,
									   'Amex Except3             : '
									|| gn_amex_except3);
				xx_location_and_log(g_loc,
									'Retrieve AMEX Customer Exception - EXCEPT4. ');

				SELECT COUNT(1)
				INTO   gn_amex_except4
				FROM   DUAL
				WHERE  NOT EXISTS(
						   SELECT 1
						   FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
						   WHERE  xftd.translate_id = xftv.translate_id
						   AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
						   AND    xftv.source_value1 = gc_cust_orig_system_ref
						   AND    xftv.target_value1 = 'EXCEPT4'
						   AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																				   SYSDATE
																				 + 1)
						   AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																				   SYSDATE
																				 + 1)
						   AND    xftv.enabled_flag = 'Y'
						   AND    xftd.enabled_flag = 'Y');

				xx_location_and_log(g_log,
									   'Amex Except4             : '
									|| gn_amex_except4);
				xx_location_and_log(g_loc,
									'Retrieve AMEX Customer Exception - EXCEPT5. ');

				SELECT COUNT(1)
				INTO   gn_amex_except5
				FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
				WHERE  xftd.translate_id = xftv.translate_id
				AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
				AND    xftv.source_value1 = gc_cust_orig_system_ref
				AND    xftv.target_value1 = 'EXCEPT5'
				AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																		SYSDATE
																	  + 1)
				AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																		SYSDATE
																	  + 1)
				AND    xftv.enabled_flag = 'Y'
				AND    xftd.enabled_flag = 'Y';

				xx_location_and_log(g_log,
									   'Amex Except5             : '
									|| gn_amex_except5);
				xx_location_and_log(g_loc,
									'Retrieve AMEX Customer Exception - EXCEPT6. ');

				SELECT COUNT(1)
				INTO   gn_amex_except6
				FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
				WHERE  xftd.translate_id = xftv.translate_id
				AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
				AND    xftv.source_value1 = gc_cust_orig_system_ref
				AND    xftv.target_value1 = 'EXCEPT6'
				AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																		SYSDATE
																	  + 1)
				AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																		SYSDATE
																	  + 1)
				AND    xftv.enabled_flag = 'Y'
				AND    xftd.enabled_flag = 'Y';

				xx_location_and_log(g_log,
									   'Amex Except6             : '
									|| gn_amex_except6);
				xx_location_and_log(g_loc,
									'Retrieve AMEX Customer Exception - EXCEPT7. ');

				SELECT COUNT(1)
				INTO   gn_amex_except7
				FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
				WHERE  xftd.translate_id = xftv.translate_id
				AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
				AND    xftv.source_value1 = gc_cust_orig_system_ref
				AND    xftv.target_value1 = 'EXCEPT7'
				AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																		SYSDATE
																	  + 1)
				AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																		SYSDATE
																	  + 1)
				AND    xftv.enabled_flag = 'Y'
				AND    xftd.enabled_flag = 'Y';

				xx_location_and_log(g_log,
									   'Amex Except7             : '
									|| gn_amex_except7);
				xx_location_and_log(g_loc,
									'Check AMEX Exception Counts and Set fields. ');

				BEGIN
					IF (gn_amex_except1 > 0)
					THEN
						gc_ixcustomerreferenceid := gc_ixdesktoplocation;
					ELSIF(gn_amex_except2 > 0)
					THEN
						gc_ixcustomerreferenceid := gc_ixreleasenumber;
					ELSE
						gc_ixcustomerreferenceid := gc_cust_po_number;
					END IF;

					IF (gn_amex_except3 > 0)
					THEN
						gc_ixpurchasername := gc_ixreleasenumber;
					END IF;

					IF (gn_amex_except4 > 0)
					THEN
						gc_ixpurchasername := gc_ixshiptoname;
					END IF;

					IF (gn_amex_except5 > 0)
					THEN
						gc_ixbankuserdata :=    SUBSTR(gc_ixcostcenter,
													   1,
													   5)
											 || ' '
											 || SUBSTR(gc_cust_po_number,
													   1,
													   9);
					END IF;

					IF (gn_amex_except6 > 0)
					THEN
						gc_ixbankuserdata := gc_ixcostcenter;
					ELSIF(gn_amex_except7 > 0)
					THEN
						gc_ixbankuserdata := gc_ixreleasenumber;
					ELSE
						gc_ixbankuserdata := SUBSTR(gc_cust_po_number,
													1,
													17);
					END IF;

					xx_location_and_log(g_log,
										   'Bank User Data           : '
										|| gc_ixbankuserdata);
					xx_location_and_log(g_log,
										   'Purchaser Name           : '
										|| gc_ixpurchasername);
					xx_location_and_log(g_log,
										   'Customer Reference ID    : '
										|| gc_ixcustomerreferenceid);
				END;
			END IF;
		END;

------------------------------------------------------------------
-- Set IXCUSTOMERREFERENCEID Based on PO and Cust Code Overrides
------------------------------------------------------------------
		BEGIN
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieve PO and Cust Code Overrides. ');

				SELECT UPPER(po_override_settlements),
					   UPPER(cust_code_override),
					   UPPER(secondary_po)
				INTO   gc_po_override_set,
					   gc_cust_code_override,
					   gc_sec_po_override --26.5
				FROM   xxcdh_cust_override_fl_v
				WHERE  cust_account_id = gn_cust_account_id;
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					xx_location_and_log
						(g_loc,
						 'Entering NO_DATA_FOUND Exception in XX_PROCESS_CUST_EXCEPTIONS for Set IXCUSTOMERREFERENCEID. ');
					gc_po_override_set := NULL;
					gc_cust_code_override := NULL;
					gc_sec_po_override := NULL; --26.5
			END;

			xx_location_and_log(g_log,
								   'PO Override Set          : '
								|| gc_po_override_set);
			xx_location_and_log(g_log,
								   'Cust Code Override       : '
								|| gc_cust_code_override);
			xx_location_and_log(g_log,
								   'Secondary PO Override       : '
								|| gc_sec_po_override);

			xx_location_and_log(g_loc,
								'Check PO Overrides. ');

			IF (gc_po_override_set = 'D')
			THEN
				gc_ixcustomerreferenceid := gc_ixcostcenter;
			ELSIF(gc_po_override_set = 'T')
			THEN
				gc_ixcustomerreferenceid := gc_ixdesktoplocation;
			ELSIF(gc_po_override_set = 'R')
			THEN
				gc_ixcustomerreferenceid := gc_ixreleasenumber;
			ELSIF(gc_po_override_set = 'P')
			THEN
				gc_ixcustomerreferenceid := gc_cust_po_number;
			END IF;

			xx_location_and_log(g_log,
								   'Customer Reference ID    : '
								|| gc_ixcustomerreferenceid);
			xx_location_and_log(g_loc,
								'Check Cust Override of 0. ');


			IF (gc_cust_code_override = 'O')
			THEN
				gc_ixcustomerreferenceid := gc_ixinvoice;
				xx_location_and_log(g_log,
									   'Customer Reference ID    : '
									|| gc_ixcustomerreferenceid);
			END IF;

			--START 35.0
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieve cc_auth_ps2000 from ORDT. ');

				IF gc_remit_processing_type = g_poe_int_store_cust
				THEN
					xx_location_and_log(g_loc,
										'Retrieving IXISSUENUMBER for POE_INT_STORE_CUST Remittance Processing Type. ');

					SELECT cc_auth_ps2000
					INTO   gc_cc_auth_ps2000
					FROM   xx_ar_order_receipt_dtl
					WHERE  order_payment_id = gn_order_payment_id
					AND    gc_credit_card_type LIKE 'CITI%';
				ELSE
					xx_location_and_log
									(g_loc,
										'Retrieving IXISSUENUMBER for NON-POE_INT_STORE_CUST ORemittance Processing Type. ');

					SELECT attribute4
					INTO   gc_cc_auth_ps2000
					FROM   ar_cash_receipts_all
					WHERE  cash_receipt_id = gn_cash_receipt_id
					AND    attribute14 LIKE 'CITI%';
				END IF;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							'Entering NO_DATA_FOUND Exception in XX_PROCESS_CUST_EXCEPTIONS for Set gc_cc_auth_ps2000. ');
							gc_cc_auth_ps2000 := NULL;
			END;

			IF(gc_cc_auth_ps2000 IS NOT NULL)
			THEN
					gc_ixissuenumber := gc_cc_auth_ps2000;
			ELSE

				IF (gc_sec_po_override = 'D')
				THEN
					gc_ixissuenumber := gc_ixcostcenter;
				ELSIF(gc_sec_po_override = 'T')
				THEN
					gc_ixissuenumber := gc_ixdesktoplocation;
				ELSIF(gc_sec_po_override = 'R')
				THEN
					gc_ixissuenumber := gc_ixreleasenumber;
				ELSIF(gc_sec_po_override = 'P')
				THEN
					gc_ixissuenumber := gc_cust_po_number;
				END IF;
				xx_location_and_log(g_log,
										'Field 25 Issue Number gc_ixissuenumber : '
										|| gc_ixissuenumber);

				xx_location_and_log(g_loc,
									'Check Customer Override. ' || gc_cust_code_override);
			END IF;	--END 35.0

				IF gc_sec_po_override IS NOT NULL
				THEN
					-- gc_ixreserved39 := gc_ixissuenumber || '/' || gc_ixinvoice;  --Commented in version 26.9
					gc_ixreserved39 := gc_ixinvoice || '/' || gc_ixissuenumber;
				END IF;
-- End 26.5

			IF    (UPPER(gc_credit_card_vendor) = 'MASTERCARD')
			   OR (UPPER(gc_credit_card_type) = 'MASTERCARD')
			THEN
				IF (gc_ixstorenumber = g_irec_store_number)
				THEN
					gc_ixcustomerreferenceid := 'OFF DEP INV PAYMT';
				ELSIF(     (     (gc_ixcustomerreferenceid IS NULL)
							AND (gc_ixinvoice IS NOT NULL) )
					  AND gc_sale_type <> g_refund)
				-- Added for defect 12126
				THEN
					gc_ixcustomerreferenceid := SUBSTR(gc_ixinvoice,
													   1,
													   9);
				END IF;

				xx_location_and_log(g_log,
									   'Customer Reference ID    : '
									|| gc_ixcustomerreferenceid);
			END IF;
		END;

------------------------------------------------------
-- Process Specific Customer Exceptions #2
------------------------------------------------------
		BEGIN
			xx_location_and_log
							  (g_loc,
							   'Retrieving Customer Exceptions from OD_AR_SETTLE_CUST_EXCEPT2 translation definition. ');
			gc_error_debug :=    'Cust Orig System Ref: '
							  || gc_cust_orig_system_ref;

			SELECT   COUNT(1),
					 xftv.source_value1
			INTO     gn_other_cust_exp,
					 gc_other_cust
			FROM     xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			WHERE    xftd.translate_id = xftv.translate_id
			AND      xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT2'
			AND      (SUBSTR(gc_cust_orig_system_ref,
							 1,
							 8) BETWEEN xftv.target_value1 AND xftv.target_value2)
			AND      SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	  SYSDATE
																	+ 1)
			AND      SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	  SYSDATE
																	+ 1)
			AND      xftv.enabled_flag = 'Y'
			AND      xftd.enabled_flag = 'Y'
			GROUP BY xftv.source_value1;

			xx_location_and_log(g_loc,
								'Check OD_AR_SETTLE_CUST_EXCEPT2 customer exceptions. ');

			IF (    gn_other_cust_exp > 0
				AND gc_other_cust = 'DISNEY'
				AND gc_ixcostcenter IS NOT NULL)
			THEN
				gc_ixshiptoname := gc_ixcostcenter;
			ELSIF(    gn_other_cust_exp > 0
				  AND gc_other_cust = 'BECKMAN'
				  AND gc_cust_po_number IS NOT NULL)
			THEN
				gc_ixshiptoname := gc_cust_po_number;
			ELSIF(    gn_other_cust_exp > 0
				  AND gc_other_cust = 'OTHER_SPECIAL'
				  AND gc_cust_po_number IS NOT NULL)
			THEN
				gc_ixshiptoname := gc_cust_po_number;
			--Start of changes for defect #44299
			ELSIF(    gn_other_cust_exp > 0
				   AND gc_other_cust = 'SWIFT TRANSPORTATION')
			THEN
				gc_ixcustomerreferenceid := gc_cust_po_number || gc_ixcostcenter;
			--End of changes for defect #44299
			END IF;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				xx_location_and_log
						  (g_loc,
						   'Entering NO_DATA_FOUND Exception in XX_PROCESS_CUST_EXCEPTIONS for Customer Exceptions 2. ');
				gn_other_cust_exp := 0;
				gc_other_cust := NULL;
		END;

		xx_location_and_log(g_log,
							   'Ship to Name             : '
							|| gc_ixshiptoname);
		xx_location_and_log(g_log,
							   'Other Cust Exp           : '
							|| gn_other_cust_exp);
		xx_location_and_log(g_log,
							   'Other Cust               : '
							|| gc_other_cust);
	END xx_process_cust_exceptions;

-- +====================================================================+
-- | FUNCTION   : XX_CHECK_MANDATORY_FIELDS                             |
-- |                                                                    |
-- | DESCRIPTION: Function is used to make sure mandatory fields are    |
-- |              not null.  If so, program will complete in error      |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : BOOLEAN                                               |
-- +====================================================================+
	FUNCTION xx_check_mandatory_fields
		RETURN BOOLEAN
	IS
	BEGIN
		xx_location_and_log(g_loc,
							'XX_CHECK_MANDATORY_FIELDS. ');
------------------------------------------------------
-- Debug for Mandatory Fields and Source
------------------------------------------------------
		xx_location_and_log(g_log,
							   'Mandatory fields'
							|| CHR(10)
							|| '     ----------------------------------------'
							|| ' '
							|| CHR(10)
							|| '     Pre2                             : '
							|| gc_pre2
							|| CHR(10)
							|| '     Ixstorenumber                    : '
							|| gc_ixstorenumber
							|| CHR(10)
							|| '     Ixregisternumber                 : '
							|| gc_ixregisternumber
							|| CHR(10)
							|| '     Ixamount                         : '
							|| gc_ixamount
							|| CHR(10)
							|| '     Ixreceiptnumber                  : '
							|| gc_ixreceiptnumber
							|| CHR(10)
							|| '     Ixauthorizationnumber (SALE only): '
							|| gc_ixauthorizationnumber
							|| CHR(10)
							|| '     Ixdate                           : '
							|| gc_ixdate
							|| CHR(10)
							|| '     Ixtime                           : '
							|| gc_ixtime
							|| CHR(10)
							|| '     Ixinvoice                        : '
							|| gc_ixinvoice);
		xx_location_and_log(g_log,
							   'Receipt Source                   : '
							|| gc_source);

------------------------------------------------------
-- Check Mandatory Fields
------------------------------------------------------
		IF (     (gc_pre2 IS NULL)
			AND (gc_ixstorenumber IS NULL)
			AND (gc_ixregisternumber IS NULL)
			AND (gc_ixamount IS NULL)
			AND (gc_ixreceiptnumber IS NULL)
			AND (    gc_ixauthorizationnumber IS NULL
				 AND gc_sale_type = g_sale)
			AND (gc_ixdate IS NULL)
			AND (gc_ixtime IS NULL)
			AND (gc_ixinvoice IS NULL) )
		THEN   -- Added check for Defect 13498
			xx_location_and_log(g_loc,
								'Mandatory Fields are NULL for the Table XX_IBY_BATCH_TRXNS. ');

			IF (gc_pre2 IS NULL)
			THEN
				gc_error_debug :=    gc_error_debug
								  || ' Pre2 ';
			END IF;

			IF (gc_ixstorenumber IS NULL)
			THEN
				gc_error_debug :=    gc_error_debug
								  || ' StoreNo ';
			END IF;

			IF (gc_ixregisternumber IS NULL)
			THEN
				gc_error_debug :=    gc_error_debug
								  || ' RegisterNo ';
			END IF;

			IF (gc_ixamount IS NULL)
			THEN
				gc_error_debug :=    gc_error_debug
								  || ' Amt ';
			END IF;

			IF (    gc_ixreceiptnumber IS NULL
				AND gc_sale_type = g_sale)
			THEN
				gc_error_debug :=    gc_error_debug
								  || ' ReceiptNo ';
			END IF;

			IF (gc_ixdate IS NULL)
			THEN
				gc_error_debug :=    gc_error_debug
								  || ' Date ';
			END IF;

			IF (gc_ixtime IS NULL)
			THEN
				gc_error_debug :=    gc_error_debug
								  || ' Time ';
			END IF;

			IF (gc_ixauthorizationnumber IS NULL)
			THEN
				gc_error_debug :=    gc_error_debug
								  || ' AuthorizationNo ';
			END IF;

			IF (gc_ixinvoice IS NULL)
			THEN   -- Added check for Defect 13498
				gc_error_debug :=    gc_error_debug
								  || ' Invoice ';
			END IF;

			RETURN FALSE;   -- Mandatory fields are NULL
		ELSE
			RETURN TRUE;   -- Mandatory fields are NOT NULL
		END IF;
	END xx_check_mandatory_fields;

-- +====================================================================+
-- | PROCEDURE  : XX_CREATE_101_SETTLEMENT_REC                          |
-- |                                                                    |
-- | DESCRIPTION:                                                       |
-- |                                                                    |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_create_101_settlement_rec
	IS
		ln_insert_count        NUMBER;
		ln_inserted_101_count  NUMBER;
	BEGIN
		xx_location_and_log(g_loc,
							'Calling XX_CHECK_MANDATORY_FIELDS from XX_CREATE_101_SETTLEMENT_REC. ');

		IF NOT xx_check_mandatory_fields
		THEN
			RAISE ex_mandatory_fields;
		END IF;



		xx_location_and_log(g_loc,
							'Inserting into XX_IBY_BATCH_TRXNS (101). ');
		gc_error_debug :=
			   'Order Header_id: '
			|| gn_order_header_id
			|| '.  Cash Receipt ID: '
			|| gn_cash_receipt_id
			|| '.  Payment Order ID: '
			|| gn_order_payment_id;
			
	-- NAIT-131811 change starts
	
	xx_location_and_log(g_loc,
							'Original Amount, Field20 - '||gc_ixreserved20);
	
    IF to_number(gc_ixreserved20) = 0
    THEN
      gc_ixreserved20 := NULL;
    END IF;
    --NAIT-131811 change ends
	
		INSERT INTO xx_iby_batch_trxns
					(pre1,
					 pre2,
					 pre3,
					 ixrecordtype,
					 ixactioncode,
					 ixmessagetype,
					 ixreserved7,
					 ixstorenumber,
					 ixregisternumber,
					 ixtransactiontype,
					 ixaccount,
					 ixexpdate,
					 ixswipe,
					 ixamount,
					 ixreserved20,
					 ixinvoice,
					 ixoptions,
					 ixbankuserdata,
					 ixissuenumber,
					 ixtotalsalestaxamount,
					 ixtotalsalestaxcollind,
					 ixreserved31,
					 ixreceiptnumber,
					 ixauthorizationnumber,
					 ixreserved43,
					 ixps2000,
					 ixreference,
					 ixdate,
					 ixtime,
					 ixreserved53,
					 ixcustomerreferenceid,
					 ixnationaltaxcollindicator,
					 ixnationaltaxamount,
					 ixothertaxamount,
					 ixdiscountamount,
					 ixshippingamount,
					 ixtaxableamount,
					 ixdutyamount,
					 ixshipfromzipcode,
					 ixshiptocompany,
					 ixshiptoname,
					 ixshiptostreet,
					 ixshiptocity,
					 ixshiptostate,
					 ixshiptocountry,
					 ixshiptozipcode,
					 ixpurchasername,
					 ixorderdate,
					 ixmerchantvatnumber,
					 ixcustomervatnumber,
					 ixvatamount,
					 ixmerchandiseshipped,
					 ixcustcountrycode,
					 ixcustaccountno,
					 ixcostcenter,
					 ixdesktoplocation,
					 ixreleasenumber,
					 ixoriginalinvoiceno,
					 ixothertaxamount2,
					 ixothertaxamount3,
					 ixmisccharge,
					 ixccnumber,
					 last_update_date,
					 last_updated_by,
					 creation_date,
					 created_by,
					 last_update_login,
					 ixinstrsubtype,
					 ixmerchantnumber,
					 attribute2,
					 attribute3,
					 attribute4,
					 attribute5,
					 attribute6,
					 attribute7,
					 ixtransnumber,
					 ixrecptnumber,
					 org_id,
					 is_deposit,
					 is_custom_refund,
					 is_amex,
					 process_indicator,
					 attribute8,
					 order_payment_id,
					 ixreserved33,       --Added new column, Version 26.3
					 ixreserved39,       --Added new column, Version 26.5
					 ixreserved56,       --Added new column, Version 27.0
					 ixtokenflag,        --Added new column, Version 32.0
					 ixcreditcardcode,    --Added new column, Version 32.0
					 ixreserved32         --Added new column, Version 48.0
					)
		VALUES      (g_pre1,
						'F'
					 || gc_pre2,
					 g_pre3,
					 g_ixrecordtype_101,
					 g_ixactioncode,
					 g_ixmessagetype,
					 gc_ixreserved7,
					 gc_ixstorenumber,
					 gc_ixregisternumber,
					 gc_ixtransactiontype,
					 gc_ixaccount,
					 gc_ixexpdate,
					 gc_ixswipe,
					 gc_ixamount,
					 gc_ixreserved20,--Added for NAIT-131811
					 gc_ixinvoice,
					 gc_ixoptions,
					 gc_ixbankuserdata,
					 gc_ixissuenumber,
					 gc_ixtotalsalestaxamount,
					 gc_ixtotalsalestaxcollind,
					 gc_ixreserved31,
					 gc_ixreceiptnumber,
					 gc_ixauthorizationnumber,
					 gc_ixreserved43,
					 gc_ixps2000,
					 gc_ixreference,
					 gc_ixdate,
					 gc_ixtime,
					 gc_ixreserved53,
					 gc_ixcustomerreferenceid,
					 gc_ixnationaltaxcollindicator,
					 gc_ixnationaltaxamount,
					 gc_ixothertaxamount,
					 gc_ixdiscountamount,
					 gc_ixshippingamount,
					 gc_ixtaxableamount,
					 gc_ixdutyamount,
					 gc_ixshipfromzipcode,
					 gc_ixshiptocompany,
					 gc_ixshiptoname,
					 gc_ixshiptostreet,
					 gc_ixshiptocity,
					 gc_ixshiptostate,
					 gc_ixshiptocountry,
					 gc_ixshiptozipcode,
					 gc_ixpurchasername,
					 NVL(gc_ixorderdate,
						 gc_ixdate),
					 gc_ixmerchantvatnumber,
					 gc_ixcustomervatnumber,
					 gc_ixvatamount,
					 gc_ixmerchandiseshipped,
					 gc_ixcustcountrycode,
					 gc_ixcustaccountno,
					 gc_ixcostcenter,
					 gc_ixdesktoplocation,
					 gc_ixreleasenumber,
					 gc_ixoriginalinvoiceno,
					 gc_ixothertaxamount2,
					 gc_ixothertaxamount3,
					 gc_ixmisccharge,
					 gc_ixccnumber,
					 SYSDATE,
					 -1,
					 SYSDATE,
					 -1,
					 -1,
					 gc_ixinstrsubtype,
					 gc_amex_merchant_number,
					 gc_ccrefund_flag,
					 gc_cust_po_number,
					 gc_orig_invoice_num,
					 gc_tot_order_amount,
					 gc_cust_orig_system_ref,
					 gn_cash_receipt_id,
					 gc_ixtransnumber,
					 gc_ixrecptnumber,
					 gn_org_id,
					 gc_is_deposit,
					 gc_is_custom_refund,
					 gc_is_amex,
					 gn_process_indicator,
					 gc_key_label,
					 gn_order_payment_id,
					 gc_ixreserved33,    --Version 26.4
					 gc_ixreserved39,    --Version 26.5
					 gc_ixreserved56,    --Version 27.0
					 gc_ixtokenflag,     --Version 32.0
					 gc_ixcreditcardcode, --Version 32.0
					 gc_ixreserved32     --Version 48.0
					 );

		ln_inserted_101_count := SQL%ROWCOUNT;
		xx_location_and_log(g_log,
							   '101 Records Created      : '
							|| ln_inserted_101_count);

		IF ln_inserted_101_count = 1
		THEN
			gb_101_created := TRUE;
		ELSE
			gb_101_created := FALSE;
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			xx_location_and_log(g_loc,
								'Entering WHEN OTHERS exception of XX_CREATE_101_SETTLEMENT_REC. ');
			gc_error_debug :=    'Error at: '
							  || gc_error_loc
							  || 'Error Message: '
							  || SQLERRM;
			ROLLBACK;
			gb_101_created := FALSE;
			RAISE ex_101_201_creation_error;
	END xx_create_101_settlement_rec;

-- +===================================================================+
-- | PROCEDURE   : XX_CREATE_201_SETTLEMENT_REC                        |
-- |                                                                   |
-- | DESCRIPTION: Insert into the 201 table xx_iby_batch_trxns_det     |
-- |                                                                   |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +===================================================================+
	PROCEDURE xx_create_201_settlement_rec
	IS
		lc_ixproductcode          xx_iby_batch_trxns_det.ixproductcode%TYPE;
		lc_ixskunumber            xx_iby_batch_trxns_det.ixskunumber%TYPE;
		lc_ixitemdescription      xx_iby_batch_trxns_det.ixitemdescription%TYPE;
		lc_ixitemquantity         xx_iby_batch_trxns_det.ixitemquantity%TYPE;
		lc_ixunitcost             xx_iby_batch_trxns_det.ixunitcost%TYPE;
		lc_ixunitmeasure          xx_iby_batch_trxns_det.ixunitmeasure%TYPE          := NULL;
		lc_ixunitvatamount        xx_iby_batch_trxns_det.ixunitvatamount%TYPE        := 0;
		lc_ixunitvatrate          xx_iby_batch_trxns_det.ixunitvatrate%TYPE;
		lc_ixunitdiscount         xx_iby_batch_trxns_det.ixunitdiscount%TYPE         := '0';
		lc_ixunitdepartmentcode   xx_iby_batch_trxns_det.ixunitdepartmentcode%TYPE;
		lc_ixinvoicelinenum       xx_iby_batch_trxns_det.ixinvoicelinenum%TYPE;
		lc_ixcustpolinenum        xx_iby_batch_trxns_det.ixcustpolinenum%TYPE;
		lc_ixcustitemnum          xx_iby_batch_trxns_det.ixcustitemnum%TYPE;
		lc_ixcustitemdesc         xx_iby_batch_trxns_det.ixcustitemdesc%TYPE;
		lc_ixcustunitprice        xx_iby_batch_trxns_det.ixcustunitprice%TYPE;
		lc_ixcustuom              xx_iby_batch_trxns_det.ixcustuom%TYPE;
		ln_ixtotalskurecords      NUMBER                                             := 0;
		ln_seq_number             NUMBER                                             := 0;
		lc_error_flag             VARCHAR2(1)                                        := 'N';
		lc_actual_qty             xx_iby_batch_trxns_det.ixitemquantity%TYPE         := '0';
		lc_line_category          oe_order_lines_all.line_category_code%TYPE;
		lc_deposits               VARCHAR2(1)                                        := NULL;
		lc_insert_201             VARCHAR2(1)                                        := 'N';
		ln_inserted_201_count     NUMBER                                             := 0;
		ln_inserted_201_count_gt  NUMBER                                             := 0;
		ln_line_number            NUMBER					     := 0;
		lc_ixinvoice_temp       xx_iby_batch_trxns_det.ixinvoicelinenum%TYPE;    -- added by sripal for NAIT 123195

		CURSOR c_invoice_line
		IS
			SELECT   MIN(rctl.customer_trx_line_id) min_customer_trx_line_id,
					 rctl.inventory_item_id inventory_item_id,
					 NVL(rctl.unit_standard_price,
						 rctl.unit_selling_price) unit_standard_price,
					 rctl.uom_code uom_code,
					 NVL(rctl.quantity_invoiced,
						 rctl.quantity_credited) quantity_invoiced,
					 rctl.tax_rate tax_rate,
					 NULL line_category_code,
					 MIN(rctl.line_number) line_number
			FROM     ra_customer_trx_lines_all rctl
			WHERE    rctl.customer_trx_id = gn_customer_trx_id
			AND      NVL(rctl.interface_line_attribute11,
						 '0') = '0'
			AND      rctl.line_type <> 'TAX'
			AND      gc_inv_flag = 'Y'
			GROUP BY rctl.inventory_item_id,
					 rctl.unit_standard_price,
					 rctl.unit_selling_price,
					 rctl.uom_code,
					 rctl.quantity_invoiced,
					 rctl.quantity_credited,
					 rctl.tax_rate
			UNION ALL
			SELECT   MIN(ool.line_id) min_customer_trx_line_id,
					 ool.inventory_item_id inventory_item_id,
					 ool.unit_list_price unit_standard_price,
					 ool.order_quantity_uom uom_code,
					 ool.ordered_quantity quantity_invoiced,
					 ool.tax_rate tax_rate,
					 ool.line_category_code,
					 MIN(ool.line_number) line_number
			FROM     oe_order_lines_all ool
			WHERE    ool.header_id = gn_order_header_id
			AND      gc_inv_flag = 'N'
			GROUP BY ool.inventory_item_id,
					 ool.unit_list_price,
					 ool.order_quantity_uom,
					 ool.ordered_quantity,
					 ool.tax_rate,
					 ool.line_category_code
			ORDER BY line_number; -- Defect 40377 inventory_item_id;

		CURSOR c_deposits
		IS
			SELECT ws_sku,
				   ws_sku_desc,
				   NVL(ws_sku_qty,
					   0) ws_sku_qty,
				   ws_price_retail,
				   RTRIM(ws_merch_dept) ws_merch_dept,
				   ws_sku_uom,
				   ws_seq_number,
				   ABS(  NVL(ws_discount_amount,
							 0)
					   * 100) tot_disc
			FROM   xx_iby_deposit_aops_order_dtls
			WHERE  receipt_number = gc_receipt_number;
	BEGIN
		ln_inserted_201_count := 0;
		ln_inserted_201_count_gt := 0;

		IF gc_sale_type = g_refund
		THEN
			gn_customer_trx_id := gc_cm_customer_trx_id;
		END IF;

		xx_location_and_log(g_log,
							'*********************** 201 START ***********************');
		xx_location_and_log(g_log,
							   'G_PRE1                   : '
							|| g_pre1);
		xx_location_and_log(g_log,
							   'G_PRE2                   : '
							|| gc_pre2);
		xx_location_and_log(g_log,
							   'G_PRE3                   : '
							|| g_pre3);
		xx_location_and_log(g_log,
							   'G_IXACTIONCODE           : '
							|| g_ixactioncode);
		xx_location_and_log(g_log,
							   'G_IXMESSAGETYPE          : '
							|| g_ixmessagetype);
		xx_location_and_log(g_log,
							   'gc_ixstorenumber         : '
							|| gc_ixstorenumber);
		xx_location_and_log(g_log,
							   'gc_ixregisternumber      : '
							|| gc_ixregisternumber);
		xx_location_and_log(g_log,
							   'gc_ixtransactiontype     : '
							|| gc_ixtransactiontype);
		xx_location_and_log(g_log,
							   'gc_ixinvoice             : '
							|| gc_ixinvoice);
		xx_location_and_log(g_log,
							   'gc_ixreceiptnumber       : '
							|| gc_ixreceiptnumber);
		xx_location_and_log(g_log,
							   'gn_customer_trx_id       : '
							|| gn_customer_trx_id);
		xx_location_and_log(g_log,
							   'gc_sa_payment_source     : '
							|| gc_sa_payment_source);
		xx_location_and_log(g_log,
							   'gc_receipt_number        : '
							|| gc_receipt_number);
		xx_location_and_log(g_log,
							   'gc_credit_card_vendor    : '
							|| gc_credit_card_vendor);
		xx_location_and_log(g_log,
							   'gn_master_org_id         : '
							|| gn_master_org_id);
		xx_location_and_log(g_log,
							   'gn_order_header_id       : '
							|| gn_order_header_id);
		xx_location_and_log(g_log,
							   'gc_inv_flag              : '
							|| gc_inv_flag);
		xx_location_and_log(g_log,
							   'gc_cust_trx_type         : '
							|| gc_cust_trx_type);
		xx_location_and_log(g_log,
							   'gn_cash_receipt_id       : '
							|| gn_cash_receipt_id);
		xx_location_and_log(g_log,
							   'gn_process_indicator     : '
							|| gn_process_indicator);

		IF (    gc_remit_processing_type = g_irec
			AND gc_invoice_retrieval_status = g_multi)
		THEN
			BEGIN
				xx_location_and_log(g_loc,
									'Inserting XX_IBY_BATCH_TRXNS_DET table for IREC Multi Invoice Pmt. ');

				--Defect#38215
				lc_ixcustitemnum := '1';
				lc_ixcustitemdesc := NULL;
								IF gn_amex_cpc > 0 and NVL(gc_ixtokenflag,'N') = 'Y'
							THEN
							   xx_location_and_log(g_loc,
							'***** Executing PROCESS_AMEX_LINE_DATA from XX_CREATE_201_SETTLEMENT_REC ***** ');
				   ln_line_number := 0;
									   process_amex_line_data(ln_line_number,lc_ixunitmeasure,lc_ixitemquantity,
									   lc_ixunitcost,lc_ixinvoicelinenum,lc_ixcustitemnum,lc_ixcustitemdesc);
									END IF;

				INSERT INTO xx_iby_batch_trxns_det
							(pre1,
							 pre2,
							 pre3,
							 ixrecordtype,
							 ixrecseqnumber,
							 ixtotalskurecords,
							 ixactioncode,
							 ixmessagetype,
							 ixreserved7,
							 ixstorenumber,
							 ixregisternumber,
							 ixtransactiontype,
							 ixinvoice,
							 ixreceiptnumber,
							 ixproductcode,
							 ixskunumber,
							 ixitemdescription,
							 ixitemquantity,
							 ixunitcost,
							 ixunitmeasure,
							 ixunitvatamount,
							 ixunitvatrate,
							 ixunitdiscount,
							 ixunitdepartmentcode,
							 ixinvoicelinenum,
							 ixcustpolinenum,
							 ixcustitemnum,
							 ixcustitemdesc,
							 ixcustunitprice,
							 last_update_date,
							 last_updated_by,
							 creation_date,
							 created_by,
							 last_update_login,
							 ixrecptnumber,
							 process_indicator,
							 order_payment_id)
				VALUES      (g_pre1   -- pre1
								   ,
								'F'
							 || gc_pre2   -- pre2
									   ,
							 g_pre3   -- pre3
								   ,
							 g_ixrecordtype_201   -- ixrecordtype
											   ,
							 '1'   -- ixrecseqnumber
								,
							 '1'   -- ixtotalskurecords
								,
							 g_ixactioncode   -- ixactioncode
										   ,
							 g_ixmessagetype   -- ixmessagetype
											,
							 NULL   -- ixreserved7
								 ,
							 gc_ixstorenumber   -- ixstorenumber
											 ,
							 gc_ixregisternumber   -- ixregisternumber
												,
							 gc_ixtransactiontype   -- ixtransactiontype
												 ,
							 gc_ixinvoice   -- ixinvoice
										 ,
							 gc_ixreceiptnumber   -- ixreceiptnumber
											   ,
							 '9999999'   -- ixproductcode
									  ,
							 '9999999'   -- ixskunumber
									  ,
								'AR PAYMENT '
							 || gc_ixcustaccountno   -- ixitemdescription
												  ,
							 '1'   -- ixitemquantity
								,
							 gc_ixamount   -- ixunitcost
										,
							 lc_ixunitmeasure   --Defect#38215
								 ,
							 '0'   -- ixunitvatamount
								,
							 NULL   -- ixunitvatrate
								 ,
							 '0'   -- ixunitdiscount
								,
							 NULL   -- ixunitdepartmentcode
								 ,
							 '1'   -- ixinvoicelinenum
								,
							 '1'   -- ixcustpolinenum
								,
							 lc_ixcustitemnum
								,
							 lc_ixcustitemdesc  --Defect#38215
								 ,
							 '0'   -- ixcustunitprice
								,
							 SYSDATE   -- last_update_date
									,
							 -1   -- last_updated_by
							   ,
							 SYSDATE   -- creation_date
									,
							 -1   -- created_by
							   ,
							 -1   -- last_update_login
							   ,
							 gc_ixrecptnumber   -- ixrecptnumber
											 ,
							 gn_process_indicator   -- process_indicator
												 ,
							 gn_order_payment_id);

				ln_inserted_201_count_gt := SQL%ROWCOUNT;

				IF ln_inserted_201_count_gt = 1
				THEN
					lc_error_flag := 'N';
				ELSE
					lc_error_flag := 'Y';
				END IF;
			END;
		ELSIF(    (gc_sa_payment_source IS NULL)
			  OR (gc_sa_payment_source <> 'SA_DEPOSIT')
			  OR (    gc_sa_payment_source = 'SA_DEPOSIT'
				  AND gc_inv_flag IN('Y', 'N') ) )
		THEN
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieve 201 Information from c_invoice_line cursor. ');
				gc_error_debug :=
								   'Customer Trx ID: '
								|| gn_customer_trx_id
								|| '. Order Header ID: '
								|| gn_order_header_id;

				FOR lcu_invoice_line IN c_invoice_line
				LOOP
					ln_seq_number :=   ln_seq_number
									 + 1;
					gn_seq_number :=   gn_seq_number
									 + 1;   --Added per Defect 13812
					lc_ixproductcode := NULL;
					lc_ixskunumber := NULL;
					lc_ixitemdescription := NULL;
					lc_ixitemquantity := '0';
					lc_ixunitcost := '0';
					lc_ixunitmeasure := NULL;
					lc_ixunitdepartmentcode := NULL;
					lc_ixinvoicelinenum := NULL;
					lc_ixcustpolinenum := NULL;
					lc_ixcustitemnum := NULL;
					lc_ixcustitemdesc := NULL;
					lc_ixcustunitprice := '0';
					lc_ixcustuom := NULL;
					lc_ixunitdiscount := '0';
					xx_location_and_log(g_log,
										'********************** Next Record **********************');
					xx_location_and_log(g_log,
										   'Current inventory item id: '
										|| lcu_invoice_line.inventory_item_id);
					xx_location_and_log(g_log,
										   'Current UOM              : '
										|| lcu_invoice_line.uom_code);

					IF gc_inv_flag = 'Y'
					THEN
						-- There is an AR Invoice in EBS
						BEGIN
							xx_location_and_log
									 (g_loc,
									  'Checking value of gc_cust_trx_type and get Total Item Quantity for AR Invoice. ');
							gc_error_debug :=
								   'Customer Trx Line ID: '
								|| lcu_invoice_line.min_customer_trx_line_id
								|| '. AR Invoice in EBS: '
								|| gc_inv_flag;

							-- To check if it is CM or INV for calculating the Item Quantity
							IF gc_cust_trx_type = 'CM'
							THEN
								xx_location_and_log(g_loc,
													'Retrieving Quantity Invoice for AR Credit Memo. ');
								gc_error_debug :=
									   'Customer Trx ID: '
									|| gn_customer_trx_id
									|| '. Inventory Item Id: '
									|| lcu_invoice_line.inventory_item_id
									|| '. Quantity Invoiced: '
									|| lcu_invoice_line.quantity_invoiced
									|| '. Unit Standard Price: '
									|| lcu_invoice_line.unit_standard_price
									|| '. Cust TRX Type: '
									|| gc_cust_trx_type;

								SELECT NVL(SUM(rctl.quantity_credited),
										   0)
								INTO   lc_actual_qty
								FROM   ra_customer_trx_lines_all rctl
								WHERE  rctl.customer_trx_id = gn_customer_trx_id
								AND    rctl.inventory_item_id = lcu_invoice_line.inventory_item_id
								AND    NVL(rctl.unit_standard_price,
										   rctl.unit_selling_price) = lcu_invoice_line.unit_standard_price
								AND    NVL(rctl.tax_rate,
										   '0') = NVL(lcu_invoice_line.tax_rate,
													  '0')
								AND    rctl.quantity_credited = lcu_invoice_line.quantity_invoiced
								AND    NVL(rctl.uom_code,
										   'X') = NVL(lcu_invoice_line.uom_code,
													  'X');

								lc_ixitemquantity := ABS(lc_actual_qty);
							ELSE
								xx_location_and_log(g_loc,
													'Retrieving Quantity Invoice for AR Invoice. ');
								gc_error_debug :=
									   'Customer Trx ID: '
									|| gn_customer_trx_id
									|| '. Inventory Item Id: '
									|| lcu_invoice_line.inventory_item_id
									|| '. Quantity Invoiced: '
									|| lcu_invoice_line.quantity_invoiced
									|| '. Unit Standard Price: '
									|| lcu_invoice_line.unit_standard_price
									|| '. Cust TRX Type: '
									|| gc_cust_trx_type;

								SELECT NVL(SUM(rctl.quantity_invoiced),
										   0)
								INTO   lc_actual_qty
								FROM   ra_customer_trx_lines_all rctl
								WHERE  rctl.customer_trx_id = gn_customer_trx_id
								AND    rctl.inventory_item_id = lcu_invoice_line.inventory_item_id
								AND    NVL(rctl.unit_standard_price,
										   rctl.unit_selling_price) = lcu_invoice_line.unit_standard_price
								AND    rctl.quantity_invoiced = lcu_invoice_line.quantity_invoiced
								AND    NVL(rctl.tax_rate,
										   '0') = NVL(lcu_invoice_line.tax_rate,
													  '0')
								AND    NVL(rctl.interface_line_attribute11,
										   '0') = '0'
								AND    NVL(rctl.uom_code,
										   'X') = NVL(lcu_invoice_line.uom_code,
													  'X');

								lc_ixitemquantity := ABS(lc_actual_qty);
							END IF;

							xx_location_and_log(g_log,
												   'Item Quantity            : '
												|| lc_ixitemquantity);
							xx_location_and_log(g_log,
												   'Actual Quantity          : '
												|| lc_actual_qty);
							xx_location_and_log(g_loc,
												'Retrieving Order Related Information for AR Invoice. ');
							gc_error_debug :=    'Customer Trx Line ID: '
											  || lcu_invoice_line.min_customer_trx_line_id;

							SELECT xola.vendor_product_code,
								   msi.segment1,
								   rctl.description,
									 NVL(rctl.unit_standard_price,
										 rctl.unit_selling_price)
								   * 100,
								   rctl.uom_code,
								   xola.sku_dept,
								   rctl.line_number,
								   ool.customer_line_number,
								   xola.cust_item_number,
								   xola.cust_comments,
								   ABS(  xola.cust_price
									   * 100),
								   xola.cust_uom
							INTO   lc_ixproductcode,
								   lc_ixskunumber,
								   lc_ixitemdescription,
								   lc_ixunitcost,
								   lc_ixunitmeasure,
								   lc_ixunitdepartmentcode,
								   lc_ixinvoicelinenum,
								   lc_ixcustpolinenum,
								   lc_ixcustitemnum,
								   lc_ixcustitemdesc,
								   lc_ixcustunitprice,
								   lc_ixcustuom
							FROM   ra_customer_trx_all rct,
								   ra_customer_trx_lines_all rctl,
								   oe_order_lines_all ool,
								   xx_om_line_attributes_all xola,
								   mtl_system_items_b msi
							WHERE  rctl.customer_trx_line_id = lcu_invoice_line.min_customer_trx_line_id
							AND    rct.customer_trx_id = rctl.customer_trx_id
							AND    ool.line_id = rctl.interface_line_attribute6
							AND    ool.line_id = xola.line_id(+)
							AND    msi.inventory_item_id = rctl.inventory_item_id
							AND    msi.organization_id = gn_master_org_id;

							xx_location_and_log(g_log,
												   'Product Code             : '
												|| lc_ixproductcode);
							xx_location_and_log(g_log,
												   'SKU Number               : '
												|| lc_ixskunumber);
							xx_location_and_log(g_log,
												   'Item Description         : '
												|| lc_ixitemdescription);
							xx_location_and_log(g_log,
												   'Unit Cost                : '
												|| lc_ixunitcost);
							xx_location_and_log(g_log,
												   'Unit Measure             : '
												|| lc_ixunitmeasure);
							xx_location_and_log(g_log,
												   'Unit Department Code     : '
												|| lc_ixunitdepartmentcode);
							xx_location_and_log(g_log,
												   'Invoice Line Number      : '
												|| lc_ixinvoicelinenum);
							xx_location_and_log(g_log,
												   'Customer PO Line Number  : '
												|| lc_ixcustpolinenum);
							xx_location_and_log(g_log,
												   'Custome Item Number      : '
												|| lc_ixcustitemnum);
							xx_location_and_log(g_log,
												   'Customer Item Description: '
												|| lc_ixcustitemdesc);
							xx_location_and_log(g_log,
												   'Customer Unit Price      : '
												|| lc_ixcustunitprice);
							xx_location_and_log(g_log,
												   'Customer UOM             : '
												|| lc_ixcustuom);
						EXCEPTION
							WHEN NO_DATA_FOUND
							THEN
								xx_location_and_log
									(g_loc,
									 'Entering NO_DATA_FOUND Exception in XX_CREATE_201_SETTLEMENT_REC for inv retrieve. ');

								-- For Manual Credit Memos to pick the 201 Data
								BEGIN
									xx_location_and_log(g_loc,
														'Retrieving the Invoice Related information - Invoice. ');
									gc_error_debug :=
													  'Customer Trx Line ID: '
												   || lcu_invoice_line.min_customer_trx_line_id;

									SELECT msi.segment1,
										   rctl.description,
											 NVL(rctl.unit_standard_price,
												 rctl.unit_selling_price)
										   * 100,
										   rctl.uom_code,
										   rctl.line_number
									INTO   lc_ixskunumber,
										   lc_ixitemdescription,
										   lc_ixunitcost,
										   lc_ixunitmeasure,
										   lc_ixinvoicelinenum
									FROM   ra_customer_trx_all rct,
										   ra_customer_trx_lines_all rctl,
										   mtl_system_items_b msi
									WHERE  rctl.customer_trx_line_id = lcu_invoice_line.min_customer_trx_line_id
									AND    rct.customer_trx_id = rctl.customer_trx_id
									AND    msi.inventory_item_id = rctl.inventory_item_id
									AND    msi.organization_id = gn_master_org_id;

									xx_location_and_log(g_log,
														'Manual Invoice -- CM     ');
									xx_location_and_log(g_log,
														   'SKU Number               : '
														|| lc_ixskunumber);
									xx_location_and_log(g_log,
														   'Item Description         : '
														|| lc_ixitemdescription);
									xx_location_and_log(g_log,
														   'Unit Cost                : '
														|| lc_ixunitcost);
									xx_location_and_log(g_log,
														   'Unit Measure             : '
														|| lc_ixunitmeasure);
									xx_location_and_log(g_log,
														   'Invoice Line Number      : '
														|| lc_ixinvoicelinenum);
									lc_ixproductcode := NULL;
									lc_ixunitdepartmentcode := NULL;
									lc_ixcustpolinenum := NULL;
									lc_ixcustitemnum := NULL;
									lc_ixcustitemdesc := NULL;
									lc_ixcustunitprice := '0';
									lc_ixcustuom := NULL;
									lc_ixunitdiscount := '0';
								EXCEPTION
									WHEN NO_DATA_FOUND
									THEN
										xx_location_and_log
											(g_loc,
											 'Entering NO_DATA_FOUND Exception in XX_CREATE_201_SETTLEMENT_REC for sku retrieve. ');
										--Defect 14419, manual CM does not have line level details
										lc_ixproductcode := '9999999';
										lc_ixskunumber := '9999999';
										lc_ixitemdescription := 'OFFICE SUPPLY';
										lc_ixunitcost := '1';
										lc_ixunitmeasure := 'EA'; ---- Modified 'EACH' to 'EA' for the defect# 35780
										lc_ixunitdepartmentcode := NULL;
										lc_ixinvoicelinenum := '1';
										lc_ixcustpolinenum := NULL;
										lc_ixcustitemnum := NULL;
										lc_ixcustitemdesc := NULL;
										lc_ixcustunitprice := '0';
										lc_ixcustuom := NULL;
										lc_ixunitdiscount := '0';
								END;
						END;
					ELSIF gc_inv_flag = 'N'
					THEN
						-- There is no AR invoice in EBS
						BEGIN
							xx_location_and_log(g_loc,
												'Retrieving the SUM of the Item Quantity - Order. ');
							gc_error_debug :=
								   'Order Header ID: '
								|| gn_order_header_id
								|| '. Inventory Item ID: '
								|| lcu_invoice_line.inventory_item_id
								|| '. AR Invoice in EBS: '
								|| gc_inv_flag;

							SELECT ABS(NVL(SUM(ool.shipped_quantity),
										   0) )
							INTO   lc_ixitemquantity
							FROM   oe_order_lines_all ool
							WHERE  ool.header_id = gn_order_header_id
							AND    ool.inventory_item_id = lcu_invoice_line.inventory_item_id
							AND    ool.unit_list_price = lcu_invoice_line.unit_standard_price
							AND    ool.ordered_quantity = lcu_invoice_line.quantity_invoiced
							AND    ool.order_quantity_uom = lcu_invoice_line.uom_code
							AND    NVL(ool.tax_rate,
									   '0') = NVL(lcu_invoice_line.tax_rate,
												  '0')
							AND    ool.line_category_code = lcu_invoice_line.line_category_code;

							-- Added for defect 12066 and 12264
							lc_line_category := lcu_invoice_line.line_category_code;
							xx_location_and_log(g_log,
												   'Item Quantity - Shipped  : '
												|| lc_ixitemquantity);

							IF (lc_ixitemquantity = 0)
							THEN
								-- Pick the value from ordered_quantity if the item is Non Shippable Item
								xx_location_and_log
											(g_loc,
											 'Retrieving tordered_quantity if the item is Non Shippable Item - Order. ');
								gc_error_debug :=
									   'Order Header ID: '
									|| gn_order_header_id
									|| '. Inventory Item ID: '
									|| lcu_invoice_line.inventory_item_id;

								SELECT ABS(NVL(SUM(ool.ordered_quantity),
											   0) )
								INTO   lc_ixitemquantity
								FROM   oe_order_lines_all ool, mtl_system_items_b msi
								WHERE  ool.header_id = gn_order_header_id
								AND    ool.inventory_item_id = lcu_invoice_line.inventory_item_id
								AND    ool.unit_list_price = lcu_invoice_line.unit_standard_price
								AND    ool.ordered_quantity = lcu_invoice_line.quantity_invoiced
								AND    ool.order_quantity_uom = lcu_invoice_line.uom_code
								AND    ool.line_category_code = lcu_invoice_line.line_category_code
								-- Added for defect 12066 and 12264
								AND    NVL(ool.tax_rate,
										   '0') = NVL(lcu_invoice_line.tax_rate,
													  '0')
								AND    msi.shippable_item_flag = 'N'
								AND    msi.inventory_item_id = ool.inventory_item_id
								AND    msi.organization_id = gn_master_org_id;

								xx_location_and_log(g_log,
													   'Item Quantity - Ordered  : '
													|| lc_ixitemquantity);
							END IF;

							xx_location_and_log(g_log,
												   'Line Category            : '
												|| lc_line_category);
							xx_location_and_log(g_loc,
												'Retrieving Order related information - Order. ');
							gc_error_debug :=
								   'Order Header ID: '
								|| gn_order_header_id
								|| '. Order Line ID: '
								|| lcu_invoice_line.min_customer_trx_line_id;

							SELECT xola.vendor_product_code,
								   msi.segment1,
								   msi.description,
								   ABS(  ool.unit_list_price
									   * 100),
								   ool.pricing_quantity_uom,
								   xola.sku_dept,
								   ool.line_number,
								   ool.customer_line_number,
								   xola.cust_item_number,
								   xola.cust_comments,
								   ABS(  xola.cust_price
									   * 100),
								   xola.cust_uom
							INTO   lc_ixproductcode,
								   lc_ixskunumber,
								   lc_ixitemdescription,
								   lc_ixunitcost,
								   lc_ixunitmeasure,
								   lc_ixunitdepartmentcode,
								   lc_ixinvoicelinenum,
								   lc_ixcustpolinenum,
								   lc_ixcustitemnum,
								   lc_ixcustitemdesc,
								   lc_ixcustunitprice,
								   lc_ixcustuom
							FROM   oe_order_headers_all ooh,
								   oe_order_lines_all ool,
								   xx_om_line_attributes_all xola,
								   mtl_system_items_b msi
							WHERE  msi.inventory_item_id = ool.inventory_item_id
							AND    msi.organization_id = gn_master_org_id
							AND    ool.header_id = ooh.header_id
							AND    ool.line_id = xola.line_id(+)
							AND    ooh.header_id = gn_order_header_id
							AND    ool.line_id = lcu_invoice_line.min_customer_trx_line_id;

							xx_location_and_log(g_log,
												   'Product Code             : '
												|| lc_ixproductcode);
							xx_location_and_log(g_log,
												   'SKU Number               : '
												|| lc_ixskunumber);
							xx_location_and_log(g_log,
												   'Item Description         : '
												|| lc_ixitemdescription);
							xx_location_and_log(g_log,
												   'Unit Cost                : '
												|| lc_ixunitcost);
							xx_location_and_log(g_log,
												   'Unit Measure             : '
												|| lc_ixunitmeasure);
							xx_location_and_log(g_log,
												   'Unit Department Code     : '
												|| lc_ixunitdepartmentcode);
							xx_location_and_log(g_log,
												   'Invoice Line Number      : '
												|| lc_ixinvoicelinenum);
							xx_location_and_log(g_log,
												   'Customer PO Line Number  : '
												|| lc_ixcustpolinenum);
							xx_location_and_log(g_log,
												   'Custome Item Number      : '
												|| lc_ixcustitemnum);
							xx_location_and_log(g_log,
												   'Customer Item Description: '
												|| lc_ixcustitemdesc);
							xx_location_and_log(g_log,
												   'Customer Unit Price      : '
												|| lc_ixcustunitprice);
							xx_location_and_log(g_log,
												   'Customer UOM             : '
												|| lc_ixcustuom);
						EXCEPTION
							WHEN NO_DATA_FOUND
							THEN
								xx_location_and_log
									(g_loc,
									 'Entering NO_DATA_FOUND Exception in XX_CREATE_201_SETTLEMENT_REC for sku retrieve(2). ');
								lc_ixproductcode := NULL;
								lc_ixskunumber := NULL;
								lc_ixitemdescription := NULL;
								lc_ixunitcost := '0';
								lc_ixunitmeasure := NULL;
								lc_ixunitdepartmentcode := NULL;
								lc_ixinvoicelinenum := NULL;
								lc_ixcustpolinenum := NULL;
								lc_ixcustitemnum := NULL;
								lc_ixcustitemdesc := NULL;
								lc_ixcustunitprice := '0';
								lc_ixcustuom := NULL;
						END;
					END IF;   -- gc_inv_flag check


					--Start of Customer Exception
					IF gc_credit_card_vendor = 'AMEX'
					THEN
						IF lc_ixinvoicelinenum IS NULL
						THEN
							lc_ixinvoicelinenum := '00001';
						END IF;

						IF lc_ixunitmeasure = '2-'
						THEN
							lc_ixunitmeasure := 'OP';
						ELSIF lc_ixunitmeasure = '3-'
						THEN
							lc_ixunitmeasure := 'P3';
						ELSIF lc_ixunitmeasure = '4-'
						THEN
							lc_ixunitmeasure := 'P4';
						ELSIF lc_ixunitmeasure = '6-'
						THEN
							lc_ixunitmeasure := 'P6';
						ELSIF lc_ixunitmeasure IS NULL
						THEN
							lc_ixunitmeasure := 'EA'; -- Modified 'EACH' to 'EA' for the defect# 35780
						END IF;

						IF lc_ixskunumber IS NULL
						THEN
							lc_ixskunumber := '9999999';
						END IF;

						IF lc_ixitemdescription IS NULL
						THEN
							lc_ixitemdescription := 'OFFICE SUPPLY';
						END IF;
					END IF;
					--End of Customer Exception


					IF (    (    lc_line_category = 'RETURN'
							 AND gc_inv_flag = 'N')
						OR (    SIGN(lc_actual_qty) = -1
							AND gc_inv_flag = 'Y') )
					THEN
						gc_ixtransactiontype := 'Refund';
					ELSE
						gc_ixtransactiontype := 'Sale';
					END IF;

					IF lc_ixproductcode IS NULL
					THEN
						lc_ixproductcode := lc_ixskunumber;
					END IF;

					-- The below changes is to populate the Transaction type to "Refund" and to
					-- Populate the lc_ixitemdescription same as the Line description of the CM
					-- that was created during the Multi Tender receipt process
					BEGIN
						xx_location_and_log(g_loc,
											'Line Description and Transaction Type for Refund. ');
						gc_error_debug :=
							   'Order Header_id: '
							|| gn_order_header_id
							|| '.  Cash Receipt ID: '
							|| gn_cash_receipt_id
							|| '.  Payment Order ID: '
							|| gn_order_payment_id
							|| '. Customer Trx ID: '
							|| gn_customer_trx_id;

						SELECT rctl.description,
							   'Refund'
						INTO   lc_ixitemdescription,
							   gc_ixtransactiontype
						FROM   ra_customer_trx_all rct,
							   ra_customer_trx_lines_all rctl,
							   ra_batch_sources_all rbs,
							   xx_fin_translatedefinition xft,
							   xx_fin_translatevalues xftv
						WHERE  rct.customer_trx_id = gn_customer_trx_id
						AND    rct.customer_trx_id = rctl.customer_trx_id
						AND    rct.batch_source_id = rbs.batch_source_id
						AND    rbs.NAME = xftv.source_value2
						AND    xftv.translate_id = xft.translate_id
						AND    xft.translation_name = 'XX_AR_I1025_MULTI_DEPOSIT'
						AND    ROWNUM < 2;
					EXCEPTION
						WHEN NO_DATA_FOUND
						THEN
							xx_location_and_log
								(g_loc,
								 'Entering NO_DATA_FOUND Exception in XX_CREATE_201_SETTLEMENT_REC for XX_AR_I1025_MULTI_DEPOSIT. ');
							NULL;
					END;

					IF lc_ixskunumber IS NULL
					THEN
						lc_ixskunumber := lc_ixitemdescription;
					END IF;

						--Defect#38215
						lc_ixunitcost := ABS(ROUND(lc_ixunitcost,5));
						IF gn_amex_cpc > 0 and NVL(gc_ixtokenflag,'N') = 'Y'
						THEN
									   xx_location_and_log(g_loc,
							'***** Executing PROCESS_AMEX_LINE_DATA from XX_CREATE_201_SETTLEMENT_REC ***** ');
					   IF lc_ixinvoicelinenum IS NULL
					   THEN
						  ln_line_number := c_invoice_line%ROWCOUNT;
					   END IF;
											   process_amex_line_data(ln_line_number,lc_ixunitmeasure,lc_ixitemquantity,
											   lc_ixunitcost,lc_ixinvoicelinenum,lc_ixcustitemnum,lc_ixcustitemdesc);
						END IF;

							BEGIN     --- Code added for NAIT 123195 by sripal ----
								 xx_location_and_log
								 (g_loc,'Retrieving Customer Exceptions from OD_AR_SETTLE_CUST_EXCEPT2 translation definition. ');
								  gc_error_debug :=    'Cust Orig System Ref: '
								 || gc_cust_orig_system_ref;

								 SELECT COUNT(1),
										xftv.source_value1
								 INTO   gn_other_cust_exp,
										gc_other_cust
								 FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
								 WHERE  xftd.translate_id = xftv.translate_id
								 AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT2'
								 AND    (SUBSTR(gc_cust_orig_system_ref, 1,8) BETWEEN xftv.target_value1 AND xftv.target_value2)
								 AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, SYSDATE + 1)
								 AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, SYSDATE + 1)
								 AND    xftv.enabled_flag = 'Y'
								 AND    xftd.enabled_flag = 'Y'
								 GROUP BY xftv.source_value1;
								 xx_location_and_log(g_loc,'Check OD_AR_SETTLE_CUST_EXCEPT2 customer exceptions3. ');

								IF ( gn_other_cust_exp > 0 AND gc_other_cust = 'NESTLE')
								THEN
								 lc_ixinvoice_temp   :=lc_ixinvoicelinenum ;
								 lc_ixinvoicelinenum :=lc_ixcustpolinenum ;
								 lc_ixcustpolinenum  := lc_ixinvoice_temp;
								END IF;

							EXCEPTION
								WHEN NO_DATA_FOUND
								THEN
								xx_location_and_log
								(g_loc,'Entering NO_DATA_FOUND Exception in XX_PROCESS_CUST_EXCEPTIONS for Customer Exceptions3. ');
								gn_other_cust_exp := 0;
							END;       ---  end of code changes for NAIT 123195

						BEGIN
						xx_location_and_log(g_loc,
											'Inserting into XX_IBY_BATCH_TRXNS_DET (201) for Invoice/Order. ');
						gc_error_debug :=
							   'Order Header_id: '
							|| gn_order_header_id
							|| '.  Cash Receipt ID: '
							|| gn_cash_receipt_id
							|| '.  Payment Order ID: '
							|| gn_order_payment_id
							|| 'SKU Number: '
							|| lc_ixskunumber;

						INSERT INTO xx_iby_batch_trxns_det
									(pre1,
									 pre2,
									 pre3,
									 ixrecordtype,
									 ixrecseqnumber,
									 ixtotalskurecords,
									 ixactioncode,
									 ixmessagetype,
									 ixreserved7,
									 ixstorenumber,
									 ixregisternumber,
									 ixtransactiontype,
									 ixinvoice,
									 ixreceiptnumber,
									 ixproductcode,
									 ixskunumber,
									 ixitemdescription,
									 ixitemquantity,
									 ixunitcost,
									 ixunitmeasure,
									 ixunitvatamount,
									 ixunitvatrate,
									 ixunitdiscount,
									 ixunitdepartmentcode,
									 ixinvoicelinenum,
									 ixcustpolinenum,
									 ixcustitemnum,
									 ixcustitemdesc,
									 ixcustunitprice,
									 ixcustuom,
									 last_update_date,
									 last_updated_by,
									 creation_date,
									 created_by,
									 last_update_login,
									 attribute7,
									 ixtransnumber,
									 ixrecptnumber,
									 process_indicator,
									 order_payment_id)
						VALUES      (g_pre1   -- pre1
										   ,
										'F'
									 || gc_pre2   -- pre2
											   ,
									 g_pre3   -- pre3
										   ,
									 g_ixrecordtype_201   -- ixrecordtype
													   ,
									 DECODE(gc_remit_processing_type,
											g_poe_single_pmt_multi_ord, gn_seq_number,
											ln_seq_number)   -- ixrecseqnumber  added per Defect 13812
														  ,
									 ln_ixtotalskurecords   -- ixtotalskurecords
														 ,
									 g_ixactioncode   -- ixactioncode
												   ,
									 g_ixmessagetype   -- ixmessagetype
													,
									 NULL   -- ixreserved7
										 ,
									 gc_ixstorenumber   -- ixstorenumber
													 ,
									 gc_ixregisternumber   -- ixregisternumber
														,
									 gc_ixtransactiontype   -- ixtransactiontype
														 ,
									 gc_ixinvoice   -- ixinvoice
												 ,
									 gc_ixreceiptnumber   -- ixreceiptnumber
													   ,
									 lc_ixproductcode   -- ixproductcode
													 ,
									 lc_ixskunumber   -- ixskunumber
												   ,
									 lc_ixitemdescription   -- ixitemdescription
														 ,
									 lc_ixitemquantity   -- ixitemquantity
													  ,
									 lc_ixunitcost    -- ixunitcost
												   ,
									 lc_ixunitmeasure   -- ixunitmeasure
													 ,
									 lc_ixunitvatamount   -- ixunitvatamount
													   ,
									 lc_ixunitvatrate   -- ixunitvatrate
													 ,
									 lc_ixunitdiscount   -- ixunitdiscount
													  ,
									 lc_ixunitdepartmentcode   -- ixunitdepartmentcode
															,
									 lc_ixinvoicelinenum   -- ixinvoicelinenum
														,
									 lc_ixcustpolinenum   -- ixcustpolinenum
													   ,
									 lc_ixcustitemnum   -- ixcustitemnum
													 ,
									 lc_ixcustitemdesc   -- ixcustitemdesc
													  ,
									 NVL(lc_ixcustunitprice,
										 0)   -- ixcustunitprice
										   ,
									 lc_ixcustuom   -- ixcustuom
												 ,
									 SYSDATE   -- last_update_date
											,
									 -1   -- last_update_by
									   ,
									 SYSDATE   -- creation_date
											,
									 -1   -- created_by
									   ,
									 -1   -- last_update_login
									   ,
									 gn_cash_receipt_id   -- attribute7
													   ,
									 gc_ixtransnumber   -- ixtransnumber
													 ,
									 gc_ixrecptnumber   -- ixrecptnumber
													 ,
									 gn_process_indicator   -- process_indicator
														 ,
									 gn_order_payment_id);

						ln_inserted_201_count := SQL%ROWCOUNT;
						ln_inserted_201_count_gt :=   ln_inserted_201_count_gt
													+ ln_inserted_201_count;
					EXCEPTION
						WHEN OTHERS
						THEN
							xx_location_and_log
									   (g_loc,
										'Entering NO_DATA_FOUND Exception in XX_CREATE_201_SETTLEMENT_REC for insert. ');
							lc_error_flag := 'Y';
					END;
				END LOOP;

				IF ln_inserted_201_count_gt > 0
				THEN
					lc_error_flag := 'N';
				ELSE
					lc_error_flag := 'Y';
				END IF;
			END;
		-- For SA Deposit Orders which have NO Order/Invoice in EBS
		-- There are no deposits for POE_INT_STORE_CUST.  gc_sa_payment_source is NULL when remittance processing type is POE_INT_STORE_CUST
		-- Pick the 201 data from Order Dtls Table -- E1325
		ELSIF(gc_sa_payment_source = 'SA_DEPOSIT')
		THEN
			BEGIN
				lc_deposits := 'Y';
				xx_location_and_log(g_loc,
									'Retrieving SKU information for deposit. ');
				gc_error_debug :=
					   'Order Header_id: '
					|| gn_order_header_id
					|| '.  Cash Receipt ID: '
					|| gn_cash_receipt_id
					|| '.  Payment Order ID: '
					|| gn_order_payment_id
					|| 'SKU Number: '
					|| lc_ixskunumber;

				FOR lcu_deposits IN c_deposits
				LOOP
					ln_seq_number :=   ln_seq_number
									 + 1;
					gn_seq_number :=   gn_seq_number
									 + 1;   -- added per Defect 13812
					lc_ixskunumber := lcu_deposits.ws_sku;
					lc_ixitemdescription := lcu_deposits.ws_sku_desc;
					lc_ixitemquantity := lcu_deposits.ws_sku_qty;
					lc_ixunitcost :=   lcu_deposits.ws_price_retail
									 * 100;
					lc_ixunitdepartmentcode := lcu_deposits.ws_merch_dept;
					lc_ixunitmeasure := lcu_deposits.ws_sku_uom;
					lc_ixunitdiscount := '0';
					lc_ixinvoicelinenum := lcu_deposits.ws_seq_number;
					lc_insert_201 := 'Y';
					xx_location_and_log(g_log,
										   'Ixskunumber              : '
										|| lc_ixskunumber);

					--Start of Customer Exception
					IF gc_credit_card_vendor = 'AMEX'
					THEN
						IF lc_ixskunumber IS NULL
						THEN
							lc_ixskunumber := '9999999';
						END IF;

						IF lc_ixitemdescription IS NULL
						THEN
							lc_ixitemdescription := 'OFFICE SUPPLY';
						END IF;
					END IF;

					--End of Customer Exception
					IF lc_ixproductcode IS NULL
					THEN
						lc_ixproductcode := lc_ixskunumber;
					END IF;

					--Defect#38215
					lc_ixunitcost := ABS(ROUND(lc_ixunitcost,5));
					IF gn_amex_cpc > 0 and NVL(gc_ixtokenflag,'N') = 'Y'
									THEN
										xx_location_and_log(g_loc,
							'***** Executing PROCESS_AMEX_LINE_DATA from XX_CREATE_201_SETTLEMENT_REC ***** ');
						IF lc_ixinvoicelinenum IS NULL
						THEN
						  ln_line_number := c_invoice_line%ROWCOUNT;
						END IF;
												process_amex_line_data(ln_line_number,lc_ixunitmeasure,lc_ixitemquantity,
												lc_ixunitcost,lc_ixinvoicelinenum,lc_ixcustitemnum,lc_ixcustitemdesc);
											END IF;

					BEGIN
						xx_location_and_log(g_loc,
											'Inserting into XX_IBY_BATCH_TRXNS_DET (201) for Deposit. ');
						gc_error_debug :=
							   'Order Header_id: '
							|| gn_order_header_id
							|| '.  Cash Receipt ID: '
							|| gn_cash_receipt_id
							|| '.  Payment Order ID: '
							|| gn_order_payment_id
							|| 'SKU Number: '
							|| lc_ixskunumber;

						INSERT INTO xx_iby_batch_trxns_det
									(pre1,
									 pre2,
									 pre3,
									 ixrecordtype,
									 ixrecseqnumber,
									 ixtotalskurecords,
									 ixactioncode,
									 ixmessagetype,
									 ixreserved7,
									 ixstorenumber,
									 ixregisternumber,
									 ixtransactiontype,
									 ixinvoice,
									 ixreceiptnumber,
									 ixproductcode,
									 ixskunumber,
									 ixitemdescription,
									 ixitemquantity,
									 ixunitcost,
									 ixunitmeasure,
									 ixunitvatamount,
									 ixunitvatrate,
									 ixunitdiscount,
									 ixunitdepartmentcode,
									 ixinvoicelinenum,
									 ixcustpolinenum,
									 ixcustitemnum,
									 ixcustitemdesc,
									 ixcustunitprice,
									 ixcustuom,
									 last_update_date,
									 last_updated_by,
									 creation_date,
									 created_by,
									 last_update_login,
									 attribute7,
									 ixtransnumber,
									 ixrecptnumber,
									 process_indicator,
									 order_payment_id)
						VALUES      (g_pre1   -- pre1
										   ,
										'F'
									 || gc_pre2   -- pre2
											   ,
									 g_pre3   -- pre3
										   ,
									 g_ixrecordtype_201   -- ixrecordtype
													   ,
									 DECODE(gc_remit_processing_type,
											g_poe_single_pmt_multi_ord, gn_seq_number,
											ln_seq_number)   -- ixrecseqnumber  added per Defect 13812
														  ,
									 ln_ixtotalskurecords   -- ixtotalskurecords
														 ,
									 g_ixactioncode   -- ixactioncode
												   ,
									 g_ixmessagetype   -- ixmessagetype
													,
									 NULL   -- ixreserved7
										 ,
									 gc_ixstorenumber   -- ixstorenumber
													 ,
									 gc_ixregisternumber   -- ixregisternumber
														,
									 gc_ixtransactiontype   -- ixtransactiontype
														 ,
									 gc_ixinvoice   -- ixinvoice
												 ,
									 gc_ixreceiptnumber   -- ixreceiptnumber
													   ,
									 lc_ixproductcode   -- ixproductcode
													 ,
									 lc_ixskunumber   -- ixskunumber
												   ,
									 lc_ixitemdescription   -- ixitemdescription
														 ,
									 lc_ixitemquantity   -- ixitemquantity
													  ,
									 lc_ixunitcost   -- ixunitcost
												   ,
									 lc_ixunitmeasure   -- ixunitmeasure
													 ,
									 NULL   -- ixunitvatamount
										 ,
									 NULL   -- ixunitvatrate
										 ,
									 lc_ixunitdiscount   -- ixunitdiscount
													  ,
									 lc_ixunitdepartmentcode   -- ixunitdepartmentcode
															,
									 lc_ixinvoicelinenum   -- ixinvoicelinenum
														,
									 lc_ixcustpolinenum   -- ixcustpolinenum
													   ,
									 lc_ixcustitemnum   -- ixcustitemnum
													 ,
									 lc_ixcustitemdesc   -- ixcustitemdesc
													  ,
									 NVL(lc_ixcustunitprice,
										 0)   -- ixcustunitprice
										   ,
									 lc_ixcustuom   -- ixcustuom
												 ,
									 SYSDATE   -- last_update_date
											,
									 -1   -- last_updated_by
									   ,
									 SYSDATE   -- creation_date
											,
									 -1   -- created_by
									   ,
									 -1   -- last_update_login
									   ,
									 gn_cash_receipt_id   -- attribute7
													   ,
									 gc_ixtransnumber   -- ixtransnumber
													 ,
									 gc_ixrecptnumber   -- ixrecptnumber
													 ,
									 gn_process_indicator   -- process_indicator
														 ,
									 gn_order_payment_id);

						ln_inserted_201_count := SQL%ROWCOUNT;
						ln_inserted_201_count_gt :=   ln_inserted_201_count_gt
													+ ln_inserted_201_count;
					EXCEPTION
						WHEN OTHERS
						THEN
							xx_location_and_log
									(g_loc,
									 'Entering NO_DATA_FOUND Exception in XX_CREATE_201_SETTLEMENT_REC for insert(2). ');
							lc_error_flag := 'Y';
					END;
				END LOOP;

				IF ln_inserted_201_count_gt > 0
				THEN
					lc_error_flag := 'N';
				ELSE
					lc_error_flag := 'Y';
				END IF;
			END;
		END IF;   -- Checks for 201 record creation requirement

		IF (lc_deposits = 'Y')
		THEN
			IF     (lc_insert_201 = 'Y')
			   AND (lc_error_flag = 'N')
			THEN
				gb_201_created := TRUE;   -- Data successfully inserted into 201 table
			ELSE
				gb_201_created := FALSE;   -- Data was not successfully inserted into 201 table
			END IF;
		ELSIF lc_error_flag = 'N'
		THEN
			gb_201_created := TRUE;   -- Data successfully inserted into 201 table
		ELSE
			gb_201_created := FALSE;   -- Data successfully inserted into 201 table
		END IF;

		xx_location_and_log(g_log,
							'*********************************************************');
		xx_location_and_log(g_log,
							   '201 Records Created      : '
							|| ln_inserted_201_count_gt);
		xx_location_and_log(g_log,
							   'Error Flag               : '
							|| lc_error_flag);
		xx_location_and_log(g_log,
							'************************ 201 END ************************');
	EXCEPTION
		WHEN OTHERS
		THEN
			xx_location_and_log(g_loc,
								'Entering WHEN OTHERS exception of XX_CREATE_201_SETTLEMENT_REC. ');
			gc_error_debug :=    'Error at: '
							  || gc_error_loc
							  || 'Error Message: '
							  || SQLERRM;
			ROLLBACK;
			gb_201_created := FALSE;
			RAISE ex_101_201_creation_error;
	END xx_create_201_settlement_rec;

-- +====================================================================+
-- | FUNCTION   : XX_VALIDATE_101_201_CREATION                          |
-- |                                                                    |
-- | DESCRIPTION: Verifies gb_101_created and gb_201_created variables  |
-- |              to determine if 101 and 201 records were inserted or  |
-- |              not                                                   |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : BOOLEAN (returns true if created else returns false)  |
-- +====================================================================+
	FUNCTION xx_validate_101_201_creation
		RETURN BOOLEAN
	IS
		x_error_msg  VARCHAR2(2500);
	BEGIN
		xx_location_and_log(g_loc,
							'Checking if 101 record was successfully inserted. ');

		IF gb_101_created
		THEN
			xx_location_and_log(g_loc,
								'101 successfully created.  Now checking if 201 record was successfully inserted. ');

			IF gb_201_created
			THEN
				BEGIN
					xx_location_and_log
						(g_loc,
						 '101 and 201 successfully created.  Retrieving Count of 201 Records for updating total sku records column. ');
					gc_error_debug :=    'Receipt Number: '
									  || gc_ixreceiptnumber;

					SELECT COUNT(1)
					INTO   gn_det_line_count
					FROM   xx_iby_batch_trxns_det xibtd
					WHERE  xibtd.ixreceiptnumber = gc_ixreceiptnumber;

					xx_location_and_log(g_loc,
										'Updating 201 Records for Total SKUs. ');
					gc_error_debug :=
						   'Receipt Number '
						|| gc_ixreceiptnumber
						|| '. Count to set for ixtotalskurecords: '
						|| gn_det_line_count;

					UPDATE xx_iby_batch_trxns_det xibtd
					SET ixtotalskurecords = gn_det_line_count
					WHERE  xibtd.ixreceiptnumber = gc_ixreceiptnumber;
				END;

-----------------------------------------------------------------
-- Processing for successful 101 and 201 for G_IREC, G_POE, etc.
-----------------------------------------------------------------
				BEGIN
					xx_location_and_log(g_loc,
										'Update process flag to S (STAGED). ');

					UPDATE xx_ar_order_receipt_dtl
					SET remitted = 'S',
						settlement_error_message =
							SUBSTR(DECODE(settlement_error_message,
										  NULL, NULL,
											 'CORRECTED '
										  || settlement_error_message),
								   1,
								   2000)
					WHERE  order_payment_id = gn_order_payment_id;

					COMMIT;
					RETURN TRUE;
				EXCEPTION
					WHEN OTHERS
					THEN
						xx_location_and_log(g_loc,
											   'ERROR: Updating remitted flag to S (staged) on '
											|| 'XX_AR_ORDER_RECEIPT_DTL for 201 NON CCREFUND: '
											|| SQLERRM);
						x_error_msg :=
							   'ERROR: Updating remitted flag to S (staged) on
											XX_AR_ORDER_RECEIPT_DTL for 201 NON CCREFUND:'
							|| gn_order_payment_id
							|| SQLERRM;
						ROLLBACK;
						xx_set_remitted_to_error(gn_order_payment_id,
												 x_error_msg);
						RETURN FALSE;
				END;
			ELSE
--------------------------------------------------------------------
-- Processing for 201 creation ERROR
--------------------------------------------------------------------
				BEGIN
					xx_location_and_log(g_loc,
										'Failed to insert 201. ');
					gc_error_debug :=
						   'Failed to insert 201 for Receipt: '
						|| gc_ixreceiptnumber
						|| ' . Reprocess transaction by '
						|| 're-setting the error flag, if called from Automatic Remittance. ';
					ROLLBACK;
					xx_location_and_log
						  (g_loc,
						   'Failed to insert 201.  Raising EX_101_201_CREATION_ERROR to setting REMITTED to E (ERROR). ');
					RAISE ex_101_201_creation_error;
					RETURN FALSE;
				END;
			END IF;
		ELSE
--------------------------------------------------------------------
-- Processing for 101 creation ERROR
--------------------------------------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Failed to insert 101. ');
				gc_error_debug :=
					   'No 101 Records Inserted.  Reprocess transaction by re-setting the error flag '
					|| 'if called from Automatic Remittance. ';
				ROLLBACK;
				xx_location_and_log
						   (g_loc,
							'Failed to insert 101. Raising EX_101_201_CREATION_ERROR to setting REMITTED to E (ERROR). ');
				RAISE ex_101_201_creation_error;
				RETURN FALSE;
			END;
		END IF;
	END xx_validate_101_201_creation;

-- +====================================================================+
-- | PROCEDURE  : XX_SINGLE_TRX_SETTLEMENT                              |
-- |                                                                    |
-- | DESCRIPTION: This performs the main settlement processing if the   |
-- |              receipt is for a single invoice/order/deposit         |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_single_trx_settlement
	IS
	BEGIN
--------------------------------------------------------------------------
-- Step #1 - Set POST Invoice/Order/Deposit Variables
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'***** Executing XX_SET_POST_TRX_VARIABLES from XX_SINGLE_TRX_SETTLEMENT ***** ');
		xx_set_post_trx_variables;
--------------------------------------------------------------------------
-- Step #2 - Retrieve Tax, Discount, Shipping, and Misc Charge Amounts
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'***** Executing XX_CALC_TAX_DISC_SHIP_AMTS from XX_SINGLE_TRX_SETTLEMENT ***** ');
		xx_calc_tax_disc_ship_amts;
--------------------------------------------------------------------------
-- Step #3 - Set Receipt, transaction, recpt, and original numbers
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'***** Executing XX_SET_RECEIPT_TRANS_RECPT_NUM from XX_SINGLE_TRX_SETTLEMENT ***** ');
		xx_set_receipt_trans_recpt_num;
--------------------------------------------------------------------------
-- Step #4 - Process Customer Exceptions
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'***** Executing XX_PROCESS_CUST_EXCEPTIONS from XX_SINGLE_TRX_SETTLEMENT ***** ');
		xx_process_cust_exceptions;
--------------------------------------------------------------------------
-- Step #5 - Create Settlement records
--------------------------------------------------------------------------
				--START Defect#38215 - amex to vantiv conv
		xx_location_and_log(g_log,
							   'AMEX CPC                 : '
							|| gn_amex_cpc);
				IF gn_amex_cpc > 0 and NVL(gc_ixtokenflag,'N') = 'Y'
			THEN
		   xx_location_and_log(g_loc,
							'***** Executing PROCESS_AMEX_DATA from XX_SINGLE_TRX_SETTLEMENT ***** ');
				   process_amex_data;
				END IF;
				--END Defect#38215 - amex to vantiv conv

					--Start code Changes for V48.0
		xx_location_and_log(g_log,
							   'COF Transactions Update for Wallet Type            : '
							|| gc_ixwallet_type);
				IF gc_ixwallet_type is not null
			THEN
		   xx_location_and_log(g_loc,
							'***** Executing XX_UPDATE_COF_TRANS from XX_SINGLE_TRX_SETTLEMENT ***** ');
				   XX_UPDATE_COF_TRANS;
				END IF;
				--End code Changes for V48.0

		xx_location_and_log(g_loc,
							'***** Executing XX_CREATE_101_SETTLEMENT_REC from XX_SINGLE_TRX_SETTLEMENT ***** ');
		xx_create_101_settlement_rec;
		xx_location_and_log(g_loc,
							'***** Executing XX_CREATE_201_SETTLEMENT_REC from XX_SINGLE_TRX_SETTLEMENT ***** ');
		xx_create_201_settlement_rec;
	END xx_single_trx_settlement;

-- +====================================================================+
-- | PROCEDURE  : XX_IREC_MULTI_TRX_SETTLEMENT                          |
-- |                                                                    |
-- | DESCRIPTION: This performs the maing settlement processing if the  |
-- |              remit processing type is for G_IREC and the receipt is|
-- |              paying multiple AR invoices.                          |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_irec_multi_trx_settlement
	IS
		ln_cust_acct_site_id  hz_cust_site_uses_all.cust_acct_site_id%TYPE;
	BEGIN
--------------------------------------------------------------------
-- Step #1 - Process net data for AMEX CPC cards, defect 14579
--------------------------------------------------------------------
		process_net_data;

--------------------------------------------------------------------
-- Step #2 - Set IREC Variables for Multiple Inv Payment
--------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Derive Receipt Number and Invoice Number for IREC Multi Invoice Payment. ');
			gc_ixreceiptnumber :=    gc_receipt_number
								  || '##'
								  || gn_order_payment_id;
			/* Commented out to send PAYMENT_SERVER_NUM to feild 17 for AJB requirements BY NB */
			--gc_ixinvoice       := SUBSTR(gc_oapfstoreid,3)||'55'||gc_receipt_number;  -- oapfstoreid will always be 001099 for IREC receipts
			gc_ixinvoice := gc_payment_server_id;
			xx_location_and_log(g_loc,
								'Settings for Custom Refund and Deposit. ');
			gc_is_custom_refund := 'N';
			gc_is_deposit := 'N';
		END;

--------------------------------------------------------------------
-- Step #3 - Retrieve IREC Specific Variables for Multi Inv Payment
--------------------------------------------------------------------
		BEGIN
------------------------------------
-- Retrieve IXTIME for IREC
------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieve IXTIME for IREC Multiple Inv Payment. ');

				SELECT TO_CHAR(its.reqdate,
							   'HH24MISS')
				INTO   gc_ixtime
				FROM   iby_trxn_summaries_all its
				WHERE  its.tangibleid = gc_payment_server_id
				AND    its.reqtype = 'ORAPMTREQ'
				AND    its.status = '0';
			EXCEPTION
				WHEN OTHERS
				THEN
					xx_location_and_log
							  (g_loc,
							   'Entering NO_DATA_FOUND Exception in XX_IREC_MULTI_TRX_SETTLEMENT for Retrieve IXTIME. ');
					gc_ixtime := NULL;
			END;

------------------------------------
-- Retrieve Bill To Customer ID
------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieve Bill To Customer ID for IREC Multiple Inv Payment. ');

				SELECT rct.bill_to_customer_id
				INTO   gn_bill_to_customer_id
				FROM   ar_receivable_applications_all araa, ra_customer_trx_all rct
				WHERE  araa.cash_receipt_id = gn_cash_receipt_id
				AND    rct.customer_trx_id = araa.applied_customer_trx_id
				AND    ROWNUM = 1;
			EXCEPTION
				WHEN OTHERS
				THEN
					xx_location_and_log
						(g_loc,
						 'Entering NO_DATA_FOUND Exception in XX_IREC_MULTI_TRX_SETTLEMENT for Retrieve Bill To Customer ID. ');
					gn_bill_to_customer_id := NULL;
			END;

------------------------------------
-- Retrieve Bill To Customer Info
------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieve Bill To Customer Information for IREC Multiple Inv Payment. ');
				gc_error_debug :=    'Bill To Customer Account ID: '
								  || gn_bill_to_customer_id;

				SELECT hp.party_name,
					   hl.postal_code,
					   hl.country,
					   hcsua.cust_acct_site_id,
					   hca.orig_system_reference
				INTO   gc_ixshiptocompany,
					   gc_ixshiptozipcode,
					   gc_ixcustcountrycode,
					   ln_cust_acct_site_id,
					   gc_cust_orig_system_ref
				FROM   hz_cust_accounts hca,
					   hz_cust_acct_sites_all hcasa,
					   hz_cust_site_uses_all hcsua,
					   hz_party_sites hps,
					   hz_locations hl,
					   hz_parties hp
				WHERE  hca.cust_account_id = gn_bill_to_customer_id
				AND    hca.cust_account_id = hcasa.cust_account_id
				AND    hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
				AND    hcsua.site_use_code = 'BILL_TO'
				AND    hcsua.primary_flag = 'Y'
				AND    hcsua.status = 'A'
				AND    hcasa.status = 'A'
				AND    hcasa.party_site_id = hps.party_site_id
				AND    hps.location_id = hl.location_id
				AND    hps.party_id = hp.party_id
				AND    ROWNUM = 1;
			EXCEPTION
				WHEN OTHERS
				THEN
					xx_location_and_log
						(g_loc,
						 'Entering NO_DATA_FOUND Exception in XX_IREC_MULTI_TRX_SETTLEMENT for Retrieve Bill To Customer Info. ');
					gc_ixshiptocompany := NULL;
					gc_ixcustcountrycode := NULL;
					ln_cust_acct_site_id := NULL;
					gc_ixshiptozipcode := NULL;
					gc_cust_orig_system_ref := NULL;
			END;

------------------------------------
-- Retrieve Contact Name
------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieve Contact Name for IREC Multiple Inv Payment. ');
				gc_error_debug :=    'Customer Account Site ID: '
								  || ln_cust_acct_site_id;

--                SELECT    rcs.first_name
--                       || ' '
--                       || rcs.last_name
--                INTO   gc_ixshiptoname
--                FROM   ra_contacts rcs,
--                       hz_cust_account_roles hcar
--                WHERE  rcs.contact_id = hcar.cust_account_role_id
--                AND    hcar.cust_acct_site_id = ln_cust_acct_site_id
--                AND    hcar.status = 'A'
--                AND    rcs.status = 'A'
--                AND    ROWNUM = 1;                    -- Added to bring single contact when there are multiple contacts.
				SELECT    SUBSTRB(party.person_first_name,
								  1,
								  50)
					   || ' '
					   || SUBSTRB(party.person_last_name,
								  1,
								  50)
				INTO   gc_ixshiptoname
				FROM   hz_cust_account_roles acct_role,
					   hz_parties party,
					   hz_relationships rel,
					   hz_org_contacts org_cont,
					   hz_parties rel_party,
					   hz_cust_accounts role_acct
				WHERE  acct_role.cust_account_role_id = gn_ship_to_contact_id
				AND    acct_role.cust_acct_site_id = ln_cust_acct_site_id
				AND    acct_role.status = 'A'
				AND    acct_role.party_id = rel.party_id
				AND    acct_role.role_type = 'CONTACT'
				AND    org_cont.party_relationship_id = rel.relationship_id
				AND    rel.subject_id = party.party_id
				AND    rel.party_id = rel_party.party_id
				AND    rel.subject_table_name = 'HZ_PARTIES'
				AND    rel.object_table_name = 'HZ_PARTIES'
				AND    acct_role.cust_account_id = role_acct.cust_account_id
				AND    role_acct.party_id = rel.object_id
				AND    ROWNUM = 1;
			EXCEPTION
				WHEN OTHERS
				THEN
					xx_location_and_log
						(g_loc,
						 'Entering NO_DATA_FOUND Exception in XX_IREC_MULTI_TRX_SETTLEMENT for Retrieve Contact Name. ');
					gc_ixshiptoname := NULL;
			END;

------------------------------------
-- Write to Debug File
------------------------------------
			xx_location_and_log(g_log,
								   'Bill To Customer Id      : '
								|| gn_bill_to_customer_id);
			xx_location_and_log(g_log,
								   'Party Name               : '
								|| gc_ixshiptocompany);
			xx_location_and_log(g_log,
								   'Ship To Zipcode          : '
								|| gc_ixshiptozipcode);
			xx_location_and_log(g_log,
								   'Country Code             : '
								|| gc_ixcustcountrycode);
			xx_location_and_log(g_log,
								   'Cust Account Site        : '
								|| ln_cust_acct_site_id);
			xx_location_and_log(g_log,
								   'Cust Orig System Ref     : '
								|| gc_cust_orig_system_ref);
			xx_location_and_log(g_log,
								   'Ship to Name             : '
								|| gc_ixshiptoname);
		END;

--------------------------------------------------------------------
-- Step #4 - Set/Reset Global Variables for 101 IREC Multi Inv Pmt
--------------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Set/Reset Global Variables for 101 IREC Multi Inv Pmt. ');
			gc_ixstorenumber := gc_oapfstoreid;
			-- oapfstoreid will always be 001099 for IREC receipts from Automatic remittance
			gc_pre2 := gc_oapfstoreid;   -- oapfstoreid will always be 001099 for IREC receipts from Automatic remittance
			gc_ixreserved7 := NULL;
			gc_ixregisternumber := '55';
			gc_ixswipe := NULL;
			gc_ixbankuserdata := gc_ixcustaccountno;
			gc_ixissuenumber := NULL;
			gc_ixtotalsalestaxamount := '0';
			gc_ixtotalsalestaxcollind := '0';
			gc_ixreserved31 := gc_mo_value;
			gc_ixauthorizationnumber := gc_approval_code;
			gc_ixreserved53 := NULL;
			gc_ixcustomerreferenceid := NULL;
			gc_ixnationaltaxcollindicator := '0';
			gc_ixnationaltaxamount := '0';
			gc_ixothertaxamount := '0';
			gc_ixdiscountamount := '0';
			gc_ixshippingamount := '0';
			gc_ixtaxableamount := '0';
			gc_ixdutyamount := '0';
			gc_ixshipfromzipcode := NULL;
			gc_ixshiptostreet := NULL;
			gc_ixshiptocity := NULL;
			gc_ixshiptostate := NULL;
			gc_ixshiptocountry := NULL;
			gc_ixpurchasername := NULL;
			gc_ixcustomervatnumber := NULL;
			gc_ixvatamount := '0';
			gc_ixmerchandiseshipped := 'N';
			gc_ixcostcenter := NULL;
			gc_ixdesktoplocation := NULL;
			gc_ixreleasenumber := NULL;
			gc_ixoriginalinvoiceno := NULL;
			gc_ixothertaxamount2 := '0';
			gc_ixothertaxamount3 := '0';
			gc_ixmisccharge := '0';
			gc_ixccnumber := NULL;
			gc_cust_po_number := NULL;
			gc_orig_invoice_num := NULL;
			gc_tot_order_amount := gc_ixamount;
			gc_ixtransnumber := NULL;
			gc_ixrecptnumber := gc_receipt_number;
		END;

--------------------------------------------------------------------
-- Step #5 - Create Settlement Records for IREC Multi Inv Payment
--------------------------------------------------------------------
			--START Defect#38215 - amex to vantiv conv
				IF gn_amex_cpc > 0 and NVL(gc_ixtokenflag,'N') = 'Y'
			THEN
		   xx_location_and_log(g_loc,
							'***** Executing PROCESS_AMEX_DATA from XX_IREC_MULTI_TRX_SETTLEMENT ***** ');
				   process_amex_data;
				END IF;
				--END Defect#38215 - amex to vantiv conv

				  --Start code Changes for V48.0
		xx_location_and_log(g_log,
							   'COF Transactions Update for Wallet Type            : '
							|| gc_ixwallet_type);
				IF gc_ixwallet_type is not null
			THEN
		   xx_location_and_log(g_loc,
							'***** Executing XX_UPDATE_COF_TRANS from xx_irec_multi_trx_settlement ***** ');
				   XX_UPDATE_COF_TRANS;
				END IF;
				--End code Changes for V48.0

		xx_location_and_log(g_loc,
							'***** Executing XX_CREATE_101_SETTLEMENT_REC from XX_IREC_MULTI_TRX_SETTLEMENT ***** ');
		xx_create_101_settlement_rec;
		xx_location_and_log(g_loc,
							'***** Executing XX_CREATE_201_SETTLEMENT_REC from XX_IREC_MULTI_TRX_SETTLEMENT ***** ');
		xx_create_201_settlement_rec;
	END xx_irec_multi_trx_settlement;

-- +====================================================================+
-- | PROCEDURE  : XX_RETRIEVE_INVOICE_INFO                              |
-- |                                                                    |
-- | DESCRIPTION: Procedure is used to retrieve information from a      |
-- |              single AR invoices, if it exists.                     |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : x_inv_retrieval_status                                |
-- +====================================================================+
	PROCEDURE xx_retrieve_invoice_info(
		x_inv_retrieval_status  OUT  VARCHAR2)
	IS
	lv_invoice_num varchar2(100):=null;
	BEGIN
		IF (gc_remit_processing_type = g_poe_single_pmt_multi_ord)
		THEN
			BEGIN
				-- Below query is used for retrieving invoices and credit memos for POE_SINGLE_PMT_MULTI_ORD
				xx_location_and_log(g_loc,
									'Retrieving AR Invoice information (POE_SINGLE_PMT_MULTI_ORD). ');

				SELECT rct.trx_number,
					   DECODE(rct.interface_header_context,
							  'ORDER ENTRY', rct.interface_header_attribute2,
							  NULL) sales_order_trans_type,
					   rct.customer_trx_id,
					   rct.bill_to_customer_id,
					   rct.ship_to_customer_id,
					   rct.bill_to_contact_id,
					   rct.ship_to_contact_id,
					   rct.bill_to_site_use_id,
					   rct.ship_to_site_use_id,
					   hca.account_number customer_number,
					   hca.orig_system_reference cust_orig_system_ref,
					   rctt.TYPE cust_trx_type,
					   hca.cust_account_id,
					   hca.account_number ixcustaccountno
				INTO   gc_trx_number,
					   gc_sales_order_trans_type,
					   gn_customer_trx_id,
					   gn_bill_to_customer_id,
					   gn_ship_to_customer_id,
					   gn_bill_to_contact_id,
					   gn_ship_to_contact_id,
					   gn_bill_to_site_use_id,
					   gn_ship_to_site_use_id,
					   gc_customer_number,
					   gc_cust_orig_system_ref,
					   gc_cust_trx_type,
					   gn_cust_account_id,
					   gc_ixcustaccountno
				FROM   ra_customer_trx_all rct, ra_cust_trx_types_all rctt, hz_cust_accounts hca
				WHERE  rct.trx_number = TO_CHAR(gn_order_number)
				AND    rct.cust_trx_type_id = rctt.cust_trx_type_id
				AND    rct.bill_to_customer_id = hca.cust_account_id;

				gc_inv_flag := 'Y';
				x_inv_retrieval_status := g_single;

				IF gc_sale_type = g_refund
				THEN
					-- Assign retrieved TRX number and ID to credit memo variables and null inv variables
					gc_cm_number := gc_trx_number;
					gc_trx_number := NULL;
					gc_cm_customer_trx_id := gn_customer_trx_id;
					gn_customer_trx_id := NULL;
				END IF;
			EXCEPTION
				WHEN TOO_MANY_ROWS
				THEN
					xx_location_and_log
								(g_loc,
								 'Encountered TOO_MANY_ROWS in XX_RETRIEVE_INVOICE_INFO (G_POE_SINGLE_PMT_MULTI_ORD). ');
					x_inv_retrieval_status := g_multi;
				WHEN NO_DATA_FOUND
				THEN
					xx_location_and_log
								(g_loc,
								 'Encountered NO_DATA_FOUND in XX_RETRIEVE_INVOICE_INFO (G_POE_SINGLE_PMT_MULTI_ORD). ');
					x_inv_retrieval_status := g_zero;
			END;
		ELSE
			xx_location_and_log(g_loc,
								'Retrieving Invoice Information based on Sale Type. ');

			IF (gc_sale_type = g_sale)
			THEN


				IF (gc_remit_processing_type = g_irec)
				THEN   -- IF statement added for defect 13110
----------------------------------------------------------
-- Retrieve Invoice Information (SALE) for iRec
----------------------------------------------------------
					BEGIN
						xx_location_and_log
										  (g_loc,
										   'Retrieving AR Invoice information (NON-POE_SINGLE_PMT_MULTI_ORD -> SALE). ');

						SELECT rct.trx_number,
							   DECODE(rct.interface_header_context,
									  'ORDER ENTRY', rct.interface_header_attribute1,
									  NULL) sales_order,
							   DECODE(rct.interface_header_context,
									  'ORDER ENTRY', rct.interface_header_attribute2,
									  NULL) sales_order_trans_type,
							   rct.customer_trx_id,
							   rct.bill_to_customer_id,
							   rct.ship_to_customer_id,
							   rct.bill_to_contact_id,
							   rct.ship_to_contact_id,
							   rct.bill_to_site_use_id,
							   rct.ship_to_site_use_id,
							   hca.account_number customer_number,
							   hca.orig_system_reference cust_orig_system_ref,
							   rctt.TYPE cust_trx_type,
							   hca.cust_account_id,
							   hca.account_number ixcustaccountno
						INTO   gc_trx_number,
							   gn_order_number,
							   gc_sales_order_trans_type,
							   gn_customer_trx_id,
							   gn_bill_to_customer_id,
							   gn_ship_to_customer_id,
							   gn_bill_to_contact_id,
							   gn_ship_to_contact_id,
							   gn_bill_to_site_use_id,
							   gn_ship_to_site_use_id,
							   gc_customer_number,
							   gc_cust_orig_system_ref,
							   gc_cust_trx_type,
							   gn_cust_account_id,
							   gc_ixcustaccountno
						FROM   ar_receivable_applications_all ara,
							   ra_customer_trx_all rct,
							   ra_cust_trx_types_all rctt,
							   hz_cust_accounts hca
						WHERE  ara.cash_receipt_id = gn_cash_receipt_id
						AND    ara.applied_customer_trx_id = rct.customer_trx_id
						AND    rct.cust_trx_type_id = rctt.cust_trx_type_id
						AND    hca.cust_account_id = rct.bill_to_customer_id
						AND    ara.status = 'APP'
						AND    ara.display = 'Y';

						gc_inv_flag := 'Y';
						x_inv_retrieval_status := g_single;
					EXCEPTION
						WHEN TOO_MANY_ROWS
						THEN
							xx_location_and_log(g_loc,
												'Encountered TOO_MANY_ROWS in XX_RETRIEVE_INVOICE_INFO (SALE). ');
							x_inv_retrieval_status := g_multi;
						WHEN NO_DATA_FOUND
						THEN
							xx_location_and_log(g_loc,
												'Encountered NO_DATA_FOUND in XX_RETRIEVE_INVOICE_INFO (SALE). ');
							x_inv_retrieval_status := g_zero;
					END;   -- Retrieve Invoice Information (SALE) for iRec

				ELSIF(gc_remit_processing_type = g_service_contracts)  ----Added for V47.0/47.1 9/Mar/2018 to Fix UnApplied Invoices Scenario
				THEN
----------------------------------------------------------
-- Retrieve Invoice Information (SALE) for SERVICE-CONTRACTS
----------------------------------------------------------
					BEGIN
						xx_location_and_log
										  (g_loc,
										   'Retrieving AR Invoice information (NON-POE_SINGLE_PMT_MULTI_ORD -> SALE and SERVICE-CONTRACTS). ');
										   --Modified for V47.0/V47.2 10/Mar/2018
									Begin
									select  customer_receipt_reference into lv_invoice_num
									from xx_ar_order_receipt_dtl where order_payment_id=gn_order_payment_id;
									Exception
									WHEN TOO_MANY_ROWS
									THEN
									lv_invoice_num:=null;
									xx_location_and_log(g_loc,
												'Encountered TOO_MANY_ROWS in XX_RETRIEVE_INVOICE_INFO (SALE-SERVICE-CONTRACTS) to derive Invoice Num# from ORDT.');
									WHEN OTHERS
									THEN
									lv_invoice_num:=null;
									xx_location_and_log(g_loc,
												'Encountered OTHERS in XX_RETRIEVE_INVOICE_INFO (SALE-SERVICE-CONTRACTS) to derive Invoice Num# from ORDT.');
									end;

						SELECT rct.trx_number,
							   DECODE(rct.interface_header_context,
									  'ORDER ENTRY', rct.interface_header_attribute1,
									  NULL) sales_order,
							   DECODE(rct.interface_header_context,
									  'ORDER ENTRY', rct.interface_header_attribute2,
									  NULL) sales_order_trans_type,
							   rct.customer_trx_id,
							   rct.bill_to_customer_id,
							   rct.ship_to_customer_id,
							   rct.bill_to_contact_id,
							   rct.ship_to_contact_id,
							   rct.bill_to_site_use_id,
							   rct.ship_to_site_use_id,
							   hca.account_number customer_number,
							   hca.orig_system_reference cust_orig_system_ref,
							   rctt.TYPE cust_trx_type,
							   hca.cust_account_id,
							   hca.account_number ixcustaccountno
						INTO   gc_trx_number,
							   gn_order_number,
							   gc_sales_order_trans_type,
							   gn_customer_trx_id,
							   gn_bill_to_customer_id,
							   gn_ship_to_customer_id,
							   gn_bill_to_contact_id,
							   gn_ship_to_contact_id,
							   gn_bill_to_site_use_id,
							   gn_ship_to_site_use_id,
							   gc_customer_number,
							   gc_cust_orig_system_ref,
							   gc_cust_trx_type,
							   gn_cust_account_id,
							   gc_ixcustaccountno
						FROM   ra_customer_trx_all rct, ra_cust_trx_types_all rctt, hz_cust_accounts hca
						WHERE  rct.trx_number = to_char(lv_invoice_num)
						AND    rct.cust_trx_type_id = rctt.cust_trx_type_id
						AND    rct.bill_to_customer_id = hca.cust_account_id;

						gc_inv_flag := 'Y';
						x_inv_retrieval_status := g_single;
					EXCEPTION
						WHEN TOO_MANY_ROWS
						THEN
							xx_location_and_log(g_loc,
												'Encountered TOO_MANY_ROWS in XX_RETRIEVE_INVOICE_INFO (SALE-SERVICE-CONTRACTS). ');
							x_inv_retrieval_status := g_multi;
						WHEN NO_DATA_FOUND
						THEN
							xx_location_and_log(g_loc,
												'Encountered NO_DATA_FOUND in XX_RETRIEVE_INVOICE_INFO (SALE-SERVICE-CONTRACTS). ');
							x_inv_retrieval_status := g_zero;
					END;   -- Retrieve Invoice Information (SALE) for SERVICE-CONTRACTS




				ELSE   -- else statement added for defect 13110
----------------------------------------------------------
-- Retrieve Invoice Information (SALE) for non-iRec
----------------------------------------------------------
					BEGIN
						xx_location_and_log
										  (g_loc,
										   'Retrieving AR Invoice information (NON-POE_SINGLE_PMT_MULTI_ORD -> SALE). ');

						SELECT rct.trx_number,
							   DECODE(rct.interface_header_context,
									  'ORDER ENTRY', rct.interface_header_attribute1,
									  NULL) sales_order,
							   DECODE(rct.interface_header_context,
									  'ORDER ENTRY', rct.interface_header_attribute2,
									  NULL) sales_order_trans_type,
							   rct.customer_trx_id,
							   rct.bill_to_customer_id,
							   rct.ship_to_customer_id,
							   rct.bill_to_contact_id,
							   rct.ship_to_contact_id,
							   rct.bill_to_site_use_id,
							   rct.ship_to_site_use_id,
							   hca.account_number customer_number,
							   hca.orig_system_reference cust_orig_system_ref,
							   rctt.TYPE cust_trx_type,
							   hca.cust_account_id,
							   hca.account_number ixcustaccountno
						INTO   gc_trx_number,
							   gn_order_number,
							   gc_sales_order_trans_type,
							   gn_customer_trx_id,
							   gn_bill_to_customer_id,
							   gn_ship_to_customer_id,
							   gn_bill_to_contact_id,
							   gn_ship_to_contact_id,
							   gn_bill_to_site_use_id,
							   gn_ship_to_site_use_id,
							   gc_customer_number,
							   gc_cust_orig_system_ref,
							   gc_cust_trx_type,
							   gn_cust_account_id,
							   gc_ixcustaccountno
						FROM   ar_receivable_applications_all ara,
							   ra_customer_trx_all rct,
							   ra_cust_trx_types_all rctt,
							   hz_cust_accounts hca
						WHERE  ara.cash_receipt_id = gn_cash_receipt_id
						AND    ara.applied_customer_trx_id = rct.customer_trx_id
						AND    rct.cust_trx_type_id = rctt.cust_trx_type_id
						AND    hca.cust_account_id = rct.bill_to_customer_id
						AND    ara.status = 'APP'
						AND    ara.display = 'Y'
						AND    ROWNUM = 1;

						gc_inv_flag := 'Y';
						x_inv_retrieval_status := g_single;
					EXCEPTION
						WHEN NO_DATA_FOUND
						THEN
							xx_location_and_log(g_loc,
												'Encountered NO_DATA_FOUND in XX_RETRIEVE_INVOICE_INFO (SALE). ');
							x_inv_retrieval_status := g_zero;
					END;   -- Retrieve Invoice Information (SALE) for non-iRec
				END IF;
			ELSIF(    gc_sale_type = g_refund
				  AND gc_remit_processing_type = g_ccrefund)
			THEN
				xx_location_and_log(g_loc,
									'Retrieving Invoice Information for CCREFUND.');

--------------------------------------------------------------------
-- Retrieve AR Invoice TRX Number and Cust Acct ID
--------------------------------------------------------------------
				BEGIN
					xx_location_and_log
							  (g_loc,
							   'Retrieving AR Invoice information - Orginal Invoice No Credit Memo for Amex Settlement');
					gc_error_debug :=    'Receipt id: '
									  || gn_ref_receipt_id;

					SELECT rct.trx_number,
						   hca.cust_account_id
					INTO   gc_orig_invoice_num,
						   gn_cust_account_id
					FROM   ar_cash_receipts_all acr,
						   ar_receivable_applications_all ara,
						   ra_customer_trx_all rct,
						   hz_cust_accounts hca
					WHERE  ara.cash_receipt_id = acr.cash_receipt_id
					AND    ara.applied_customer_trx_id = rct.customer_trx_id
					AND    hca.cust_account_id = rct.bill_to_customer_id
					AND    ara.status = 'APP'
					AND    acr.cash_receipt_id = gn_ref_receipt_id
					AND    ara.amount_applied > 0
					AND    ara.display = 'Y';
				EXCEPTION
					WHEN OTHERS
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_IBY_BATCH_TRXNS_CCREFUND for Retrieve AR Invoice TRX. ');
						gc_orig_invoice_num := NULL;
				END;

				xx_location_and_log(g_log,
									   'Original AR Invoice #    : '
									|| gc_orig_invoice_num);
				xx_location_and_log(g_log,
									   'Customer Account ID      : '
									|| gn_cust_account_id);

--------------------------------------------------------------------
-- Retrieve AR Invoice Bill To and Ship To Information
--------------------------------------------------------------------
				BEGIN
					xx_location_and_log(g_loc,
										'Retrieving AR Invoice Bill To and Ship To Information');
					gc_error_debug :=    'Cash Receipt Id: '
									  || gn_cash_receipt_id;

					SELECT rct.trx_number,
						   DECODE(rct.interface_header_context,
								  'ORDER ENTRY', rct.interface_header_attribute2,
								  NULL),
						   rct.customer_trx_id,
						   rct.bill_to_customer_id,
						   rct.ship_to_customer_id,
						   rct.bill_to_contact_id,
						   rct.ship_to_contact_id,
						   rct.bill_to_site_use_id,
						   rct.ship_to_site_use_id,
						   hca.account_number,
						   hca.orig_system_reference,
						   rctt.TYPE
					INTO   gc_trx_number,
						   gc_sales_order_trans_type,
						   gn_customer_trx_id,
						   gn_bill_to_customer_id,
						   gn_ship_to_customer_id,
						   gn_bill_to_contact_id,
						   gn_ship_to_contact_id,
						   gn_bill_to_site_use_id,
						   gn_ship_to_site_use_id,
						   gc_customer_number,
						   gc_cust_orig_system_ref,
						   gc_cust_trx_type
					FROM   ar_cash_receipts_all acr,
						   ar_receivable_applications_all ara,
						   ra_customer_trx_all rct,
						   ra_cust_trx_types_all rctt,
						   hz_cust_accounts hca
					WHERE  ara.cash_receipt_id = acr.cash_receipt_id
					AND    ara.applied_customer_trx_id = rct.customer_trx_id
					AND    rct.cust_trx_type_id = rctt.cust_trx_type_id
					AND    hca.cust_account_id = rct.bill_to_customer_id
					AND    ara.status = 'APP'
					AND    ara.amount_applied < 0
					AND    acr.cash_receipt_id = gn_cash_receipt_id
					AND    ara.display = 'Y';

					gc_inv_flag := 'Y';
					x_inv_retrieval_status := g_single;
					gc_cm_number := gc_trx_number;
					gc_cm_customer_trx_id := gn_customer_trx_id;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log
							(g_loc,
							 'Entering NO_DATA_FOUND Exception in XX_IBY_BATCH_TRXNS_CCREFUND for Retrieve AR Invoice Bill To. ');
						RAISE ex_no_cm;
				END;
			ELSIF(    gc_sale_type = g_refund
				  AND gc_remit_processing_type <> g_ccrefund)
			THEN
-------------------------------------------------------
-- Retrieve Invoice Information (RETURN)
--------------------------------------------------------
				xx_location_and_log(g_loc,
									'Retrieve Invoice Information (RETURN). ');

				BEGIN
--------------------------------------------------
-- Retrieve Original Invoice Information (RETURN)
-------------------------------------------------
					BEGIN
						xx_location_and_log(g_loc,
											'Retrieving Original Invoice Information (RETURN). ');

						SELECT rct.trx_number,
							   hca.cust_account_id
						INTO   gc_trx_number,
							   gn_cust_account_id
						FROM   ar_cash_receipts_all acr,
							   ar_receivable_applications_all ara,
							   ra_customer_trx_all rct,
							   hz_cust_accounts hca
						WHERE  ara.cash_receipt_id = acr.cash_receipt_id
						AND    ara.applied_customer_trx_id = rct.customer_trx_id
						AND    hca.cust_account_id = rct.bill_to_customer_id
						AND    ara.status = 'APP'
						AND    acr.cash_receipt_id = gn_ref_receipt_id
						AND    ara.amount_applied > 0
						AND    ara.display = 'Y';
					EXCEPTION
						WHEN OTHERS
						THEN
							xx_location_and_log
								(g_loc,
								 'Entering NO_DATA_FOUND Exception in XX_RETRIEVE_INVOICE_INFO for Retrieve Orig Inv Info (RET). ');
							gc_trx_number := NULL;
					END;

--------------------------------------------
-- Retrieve Credit Memo TRX ID (RETURN)
--------------------------------------------
					BEGIN
						xx_location_and_log(g_loc,
											'Retrieving the Credit Memo (RETURN). ');
						gc_error_debug :=    'MISC Cash Receipt id: '
										  || gn_cash_receipt_id;

						SELECT ara.attribute12
						INTO   gc_cm_customer_trx_id
						FROM   ar_receivable_applications_all ara
						WHERE  ara.cash_receipt_id = gn_ref_receipt_id
						AND    ara.application_ref_type = 'MISC_RECEIPT'
						AND    ara.application_ref_id = gn_cash_receipt_id
						AND    ara.display = 'Y';

						xx_location_and_log(g_log,
											   'CM Transaction ID        : '
											|| gc_cm_customer_trx_id);
					EXCEPTION
						WHEN NO_DATA_FOUND
						THEN
							xx_location_and_log
								(g_loc,
								 'Entering NO_DATA_FOUND Exception in XX_RETRIEVE_INVOICE_INFO for Retrieve CM TRX ID (RETURN). ');
							RAISE ex_cm_null;
					END;

					IF (gc_remit_processing_type = g_irec)
					THEN   -- IF statement added for defect 13110
------------------------------------------------------------
-- Retrieve Information for AR Credit Memo (RETURN) for iRec
------------------------------------------------------------
						BEGIN
							xx_location_and_log(g_loc,
												'Getting the AR Trx Number - CM. ');
							gc_error_debug :=    'CM Customer Trx Id: '
											  || gc_cm_customer_trx_id;

							SELECT rct.trx_number,
								   DECODE(rct.interface_header_context,
										  'ORDER ENTRY', rct.interface_header_attribute1,
										  NULL),
								   DECODE(rct.interface_header_context,
										  'ORDER ENTRY', rct.interface_header_attribute2,
										  NULL),
								   rct.customer_trx_id,
								   rct.bill_to_customer_id,
								   rct.ship_to_customer_id,
								   rct.bill_to_contact_id,
								   rct.ship_to_contact_id,
								   rct.bill_to_site_use_id,
								   rct.ship_to_site_use_id,
								   hca.account_number,
								   hca.orig_system_reference,
								   rctt.TYPE
							INTO   gc_cm_number,
								   gn_order_number,
								   gc_sales_order_trans_type,
								   gn_customer_trx_id,
								   gn_bill_to_customer_id,
								   gn_ship_to_customer_id,
								   gn_bill_to_contact_id,
								   gn_ship_to_contact_id,
								   gn_bill_to_site_use_id,
								   gn_ship_to_site_use_id,
								   gc_customer_number,
								   gc_cust_orig_system_ref,
								   gc_cust_trx_type
							FROM   ra_customer_trx_all rct, ra_cust_trx_types_all rctt, hz_cust_accounts hca
							WHERE  hca.cust_account_id = rct.bill_to_customer_id
							AND    rct.cust_trx_type_id = rctt.cust_trx_type_id
							AND    rct.customer_trx_id = gc_cm_customer_trx_id;

							gc_inv_flag := 'Y';
							x_inv_retrieval_status := g_single;
						EXCEPTION
							WHEN TOO_MANY_ROWS
							THEN
								xx_location_and_log
										  (g_loc,
										   'Encountered TOO_MANY_ROWS exception in XX_RETRIEVE_INVOICE_INFO (RETURN). ');
								x_inv_retrieval_status := g_multi;
							WHEN NO_DATA_FOUND
							THEN
								xx_location_and_log
										  (g_loc,
										   'Encountered NO_DATA_FOUND exception in XX_RETRIEVE_INVOICE_INFO (RETURN). ');
								x_inv_retrieval_status := g_zero;
						END;   -- Retrieve Information for AR Credit Memo (RETURN) for iRec
					ELSE   -- IF statement added for defect 13110
------------------------------------------------------------
-- Retrieve Information for AR Credit Memo (RETURN) non-iRec
------------------------------------------------------------
						BEGIN
							xx_location_and_log(g_loc,
												'Getting the AR Trx Number - CM. ');
							gc_error_debug :=    'CM Customer Trx Id: '
											  || gc_cm_customer_trx_id;

							SELECT rct.trx_number,
								   DECODE(rct.interface_header_context,
										  'ORDER ENTRY', rct.interface_header_attribute1,
										  NULL),
								   DECODE(rct.interface_header_context,
										  'ORDER ENTRY', rct.interface_header_attribute2,
										  NULL),
								   rct.customer_trx_id,
								   rct.bill_to_customer_id,
								   rct.ship_to_customer_id,
								   rct.bill_to_contact_id,
								   rct.ship_to_contact_id,
								   rct.bill_to_site_use_id,
								   rct.ship_to_site_use_id,
								   hca.account_number,
								   hca.orig_system_reference,
								   rctt.TYPE
							INTO   gc_cm_number,
								   gn_order_number,
								   gc_sales_order_trans_type,
								   gn_customer_trx_id,
								   gn_bill_to_customer_id,
								   gn_ship_to_customer_id,
								   gn_bill_to_contact_id,
								   gn_ship_to_contact_id,
								   gn_bill_to_site_use_id,
								   gn_ship_to_site_use_id,
								   gc_customer_number,
								   gc_cust_orig_system_ref,
								   gc_cust_trx_type
							FROM   ra_customer_trx_all rct, ra_cust_trx_types_all rctt, hz_cust_accounts hca
							WHERE  hca.cust_account_id = rct.bill_to_customer_id
							AND    rct.cust_trx_type_id = rctt.cust_trx_type_id
							AND    rct.customer_trx_id = gc_cm_customer_trx_id
							AND    ROWNUM = 1;

							gc_inv_flag := 'Y';
							x_inv_retrieval_status := g_single;
						EXCEPTION
							WHEN NO_DATA_FOUND
							THEN
								xx_location_and_log
										  (g_loc,
										   'Encountered NO_DATA_FOUND exception in XX_RETRIEVE_INVOICE_INFO (RETURN). ');
								x_inv_retrieval_status := g_zero;
						END;   -- Retrieve Information for AR Credit Memo (RETURN) non-iRec
					END IF;
				END;   -- End RETURN Processing
			END IF;   -- End Check for gc_sale_type
		END IF;   -- End of remit processing check

----------------------------------------------------
-- Print Debug Information
----------------------------------------------------
		IF gc_sale_type = g_sale
		THEN
			xx_location_and_log(g_log,
								   'Transaction Number       : '
								|| gc_trx_number);
			xx_location_and_log(g_log,
								   'Customer TRX ID          : '
								|| gn_customer_trx_id);
		ELSE
			xx_location_and_log(g_log,
								   'CM Transaction Number    : '
								|| gc_cm_number);
			xx_location_and_log(g_log,
								   'CM Customer TRX ID       : '
								|| gc_cm_customer_trx_id);
			xx_location_and_log(g_log,
								   'Original Invoice Number  : '
								|| gc_orig_invoice_num);
		END IF;

		xx_location_and_log(g_log,
							   'Invoice Exists?          : '
							|| gc_inv_flag);
		xx_location_and_log(g_log,
							   'Invoice Retrieval Status : '
							|| x_inv_retrieval_status);
		xx_location_and_log(g_log,
							   'Customer TRX Type        : '
							|| gc_cust_trx_type);
		xx_location_and_log(g_log,
							   'Sales Order Number       : '
							|| gn_order_number);
		xx_location_and_log(g_log,
							   'Sales Order Trans Type   : '
							|| gc_sales_order_trans_type);
		xx_location_and_log(g_log,
							   'Customer Account ID      : '
							|| gn_cust_account_id);
		xx_location_and_log(g_log,
							   'Customer Number          : '
							|| gc_customer_number);
		xx_location_and_log(g_log,
							   'Customer Orig Sys Ref    : '
							|| gc_cust_orig_system_ref);
		xx_location_and_log(g_log,
							   'Bill To Customer Id      : '
							|| gn_bill_to_customer_id);
		xx_location_and_log(g_log,
							   'Ship To Customer Td      : '
							|| gn_ship_to_customer_id);
		xx_location_and_log(g_log,
							   'Bill To Contact Id       : '
							|| gn_bill_to_contact_id);
		xx_location_and_log(g_log,
							   'Ship To Contact Id       : '
							|| gn_ship_to_contact_id);
		xx_location_and_log(g_log,
							   'Bill To Site Use Id      : '
							|| gn_bill_to_site_use_id);
		xx_location_and_log(g_log,
							   'Ship To Site Id          : '
							|| gn_ship_to_site_use_id);
	END xx_retrieve_invoice_info;

-- +====================================================================+
-- | PROCEDURE  : XX_RETRIEVE_ORDER_INFO                                |
-- |                                                                    |
-- | DESCRIPTION: Procedure is used to retrieve information from a      |
-- |              single order, if it exists.                           |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : x_order_retrieval_status                              |
-- +====================================================================+
	PROCEDURE xx_retrieve_order_info(
		x_order_retrieval_status  OUT  VARCHAR2)
	IS
	BEGIN
		IF (gc_remit_processing_type = g_poe_single_pmt_multi_ord)
		THEN
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieving Order Information due to no EBS Invoice (POE_SINGLE_PMT_MULTI_ORD). ');

				SELECT ott.NAME,
					   ooh.sold_to_org_id,
					   ooh.sold_to_org_id,
					   ooh.invoice_to_contact_id,
					   ooh.ship_to_contact_id,
					   ooh.ship_to_org_id,
					   hca.account_number,
					   hca.orig_system_reference,
					   hca.cust_account_id
				INTO   gc_sales_order_trans_type,
					   gn_bill_to_customer_id,
					   gn_ship_to_customer_id,
					   gn_bill_to_contact_id,
					   gn_ship_to_contact_id,
					   gn_ship_to_site_use_id,
					   gc_customer_number,
					   gc_cust_orig_system_ref,
					   gn_cust_account_id
				FROM   oe_order_headers_all ooh, oe_transaction_types_tl ott, hz_cust_accounts hca
				WHERE  ooh.order_type_id = ott.transaction_type_id
				AND    hca.cust_account_id = ooh.sold_to_org_id
				--  AND OOH.invoice_to_org_id = gn_bill_to_site_use_id  --removed per 13640,13837
				AND    ooh.order_number = gn_order_number;

				x_order_retrieval_status := g_single;
				gc_inv_flag := 'N';
			EXCEPTION
				WHEN TOO_MANY_ROWS
				THEN
					xx_location_and_log
									(g_loc,
									 'Encountered TOO_MANY_ROWS in XX_RETRIEVE_ORDER_INFO (POE_SINGLE_PMT_MULTI_ORD). ');
					x_order_retrieval_status := g_multi;
				WHEN NO_DATA_FOUND
				THEN
					xx_location_and_log
									(g_loc,
									 'Encountered NO_DATA_FOUND in XX_RETRIEVE_ORDER_INFO (POE_SINGLE_PMT_MULTI_ORD). ');
					x_order_retrieval_status := g_zero;
			END;
		ELSE
			IF (gc_sale_type = g_sale)
			THEN
------------------------------------------------------
-- Retrieve Receipt/Order Information for PREPAYMENT
------------------------------------------------------
				BEGIN
					xx_location_and_log
						(g_loc,
						 'Retrieving Order number from the AR Receipt Application due to no EBS Invoice (Prepayment Type). ');

					SELECT ara.application_ref_num,
						   acr.customer_site_use_id
					INTO   gc_application_ref_num,
						   gn_bill_to_site_use_id
					FROM   ar_cash_receipts_all acr, ar_receivable_applications_all ara
					WHERE  acr.cash_receipt_id = ara.cash_receipt_id
					AND    ara.application_ref_type = 'OM'
					AND    acr.status = 'APP'
					AND    ara.amount_applied > 0
					AND    acr.cash_receipt_id = gn_cash_receipt_id
					AND    ara.display = 'Y';

					xx_location_and_log
								  (g_loc,
								   'Retrieving Order Information due to no EBS Invoice (using Prepayment information). ');
					gc_error_debug :=    'Application Ref Num: '
									  || gc_application_ref_num;

					SELECT /*+ index(OOH,OE_ORDER_HEADERS_U2) */  --Added for Defect 44326
						   ott.NAME,
						   ooh.sold_to_org_id,
						   ooh.sold_to_org_id,
						   ooh.invoice_to_contact_id,
						   ooh.ship_to_contact_id,
						   ooh.ship_to_org_id,
						   hca.account_number,
						   hca.orig_system_reference,
						   ooh.order_number,
						   hca.cust_account_id
					INTO   gc_sales_order_trans_type,
						   gn_bill_to_customer_id,
						   gn_ship_to_customer_id,
						   gn_bill_to_contact_id,
						   gn_ship_to_contact_id,
						   gn_ship_to_site_use_id,
						   gc_customer_number,
						   gc_cust_orig_system_ref,
						   gn_order_number,
						   gn_cust_account_id
					FROM   oe_order_headers_all ooh, oe_transaction_types_tl ott, hz_cust_accounts hca
					WHERE  ooh.order_type_id = ott.transaction_type_id
					AND    hca.cust_account_id = ooh.sold_to_org_id
					AND    ooh.invoice_to_org_id = gn_bill_to_site_use_id
					AND    ooh.order_number = gc_application_ref_num;

					x_order_retrieval_status := g_single;
					gc_inv_flag := 'N';
				EXCEPTION
					WHEN TOO_MANY_ROWS
					THEN
						xx_location_and_log(g_loc,
											'Encountered TOO_MANY_ROWS in XX_RETRIEVE_ORDER_INFO (SALE). ');
						x_order_retrieval_status := g_multi;
					WHEN NO_DATA_FOUND
					THEN
						xx_location_and_log(g_loc,
											'Encountered NO_DATA_FOUND in XX_RETRIEVE_ORDER_INFO (SALE). ');
						x_order_retrieval_status := g_zero;
				END;
			ELSIF(gc_sale_type = g_refund)
			THEN
				-- Returns do not go to the order to retrieve information if invoice not found.
				-- Deposit information should be retrieved if invoice and order is not found.
				xx_location_and_log(g_loc,
									'Returns do not attempt the retrieval of an order (invoice or deposit only). ');
				x_order_retrieval_status := g_zero;
			END IF;
		END IF;

----------------------------------------------------
-- Print Debug Information
----------------------------------------------------
		IF gc_sale_type = g_sale
		THEN
			xx_location_and_log(g_log,
								   'Transaction Number       : '
								|| gc_trx_number);
			xx_location_and_log(g_log,
								   'Customer TRX ID          : '
								|| gn_customer_trx_id);
		ELSE
			xx_location_and_log(g_log,
								   'CM Transaction Number    : '
								|| gc_cm_number);
			xx_location_and_log(g_log,
								   'CM Customer TRX ID       : '
								|| gc_cm_customer_trx_id);
		END IF;

		xx_location_and_log(g_log,
							   'Invoice Exists?          : '
							|| gc_inv_flag);
		xx_location_and_log(g_log,
							   'Customer TRX Type        : '
							|| gc_cust_trx_type);
		xx_location_and_log(g_log,
							   'Sales Order Number       : '
							|| gn_order_number);
		xx_location_and_log(g_log,
							   'Sales Order Trans Type   : '
							|| gc_sales_order_trans_type);
		xx_location_and_log(g_log,
							   'Order Retrieval Status   : '
							|| x_order_retrieval_status);
		xx_location_and_log(g_log,
							   'Cash Receipt Id          : '
							|| gn_cash_receipt_id);
		xx_location_and_log(g_log,
							   'Application Ref #        : '
							|| gc_application_ref_num);
		xx_location_and_log(g_log,
							   'Customer Account ID      : '
							|| gn_cust_account_id);
		xx_location_and_log(g_log,
							   'Customer Number          : '
							|| gc_customer_number);
		xx_location_and_log(g_log,
							   'Customer Orig Sys Ref    : '
							|| gc_cust_orig_system_ref);
		xx_location_and_log(g_log,
							   'Bill To Customer Id      : '
							|| gn_bill_to_customer_id);
		xx_location_and_log(g_log,
							   'Ship To Customer Td      : '
							|| gn_ship_to_customer_id);
		xx_location_and_log(g_log,
							   'Bill To Contact Id       : '
							|| gn_bill_to_contact_id);
		xx_location_and_log(g_log,
							   'Ship To Contact Id       : '
							|| gn_ship_to_contact_id);
		xx_location_and_log(g_log,
							   'Bill To Site Use Id      : '
							|| gn_bill_to_site_use_id);
		xx_location_and_log(g_log,
							   'Ship To Site Id          : '
							|| gn_ship_to_site_use_id);
		xx_location_and_log(g_log,
							   'Application Reference Num: '
							|| gc_application_ref_num);
	END xx_retrieve_order_info;

-- +====================================================================+
-- | PROCEDURE  : XX_RETRIEVE_DEPOSIT_INFO                              |
-- |                                                                    |
-- | DESCRIPTION: Procedure is used to retrieve information from a      |
-- |              single deposit, if it exists.                         |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : x_dep_retrieval_status                                |
-- +====================================================================+
	PROCEDURE xx_retrieve_deposit_info(
		x_dep_retrieval_status  OUT  VARCHAR2)
	IS
		ln_discount_amount  xx_iby_deposit_aops_order_dtls.ws_discount_amount%TYPE   := 0;
	BEGIN
--------------------------------------------------------------------------
-- Retrieve Deposit Information based on Sale Type.
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'Retrieving Deposit Information based on Sale Type. ');

		IF (    gc_sale_type = g_sale
			AND gc_remit_processing_type <> g_poe_single_pmt_multi_ord)
		THEN
----------------------------------------------------------
-- Retrieve Information for DEPOSIT receipt (SALE)
----------------------------------------------------------
			BEGIN
------------------------------------------------------
-- Check if Receipt is a DEPOSIT receipt (SALE)
------------------------------------------------------
				xx_location_and_log(g_loc,
									'Check if Receipt is a DEPOSIT receipt (SALE). ');
				gb_is_deposit_receipt := xx_validate_deposit_receipt(gn_cash_receipt_id);

------------------------------------------------------
-- Retrieve Information for DEPOSIT receipt (SALE)
------------------------------------------------------
				IF (gb_is_deposit_receipt = TRUE)
				THEN
					xx_location_and_log
								   (g_loc,
									'Retrieving the transaction_number and store_location for DEPOSIT receipt (SALE). ');
					gc_error_debug :=    'Cash Receipt id  '
									  || gn_cash_receipt_id;

					BEGIN
						-- Defect 13498 - Modified query
						SELECT xoldd.orig_sys_document_ref,
							   xold.store_location,
							   xoldd.transaction_number
						INTO   gc_orig_sys_document_ref,
							   gc_deposit_store_location,
							   gc_transaction_number
						FROM   xx_om_legacy_deposits xold, xx_om_legacy_dep_dtls xoldd
						WHERE  xold.cash_receipt_id = gn_cash_receipt_id
						AND    xold.payment_type_code = 'CREDIT_CARD'
						AND    xold.credit_card_approval_code = gc_approval_code
						AND    xold.transaction_number = xoldd.transaction_number;

						x_dep_retrieval_status := g_single;
						xx_location_and_log(g_log,
											'Deposit Receipt          : Yes');
					END;
				ELSE
					xx_location_and_log(g_loc,
										'Unable to determine if receipt is a deposit (SALE) ');
					x_dep_retrieval_status := g_zero;
				END IF;
			EXCEPTION
				WHEN OTHERS
				THEN
					xx_location_and_log(g_loc,
										'Encountered WHEN OTHERS in XX_RETRIEVE_DEPOSIT_INFO (SALE). ');
					x_dep_retrieval_status := g_zero;
			END;
		ELSIF(    gc_sale_type = g_refund
			  AND gc_remit_processing_type <> g_poe_single_pmt_multi_ord)
		THEN
----------------------------------------------------------
-- Retrieve Information for DEPOSIT receipt (RETURN)
----------------------------------------------------------
			BEGIN
				xx_location_and_log
								 (g_loc,
								  'Retrieving the transaction_number and store_location for DEPOSIT receipt (RETURN). ');
				gc_error_debug :=    'Receipt id: '
								  || gn_ref_receipt_id;

				SELECT /*+ LEADING(MISC) */
					   xoldd.orig_sys_document_ref,
					   xold.store_location,
					   xoldd.transaction_number
				INTO   gc_orig_sys_document_ref_dep,
					   gc_deposit_store_location,
					   gc_transaction_number
				FROM   ar_cash_receipts_all misc,
					   ar_cash_receipts_all cash,
					   xx_om_legacy_deposits xold,
					   xx_om_legacy_dep_dtls xoldd
				WHERE  misc.TYPE = 'MISC'
				AND    misc.reference_type = 'RECEIPT'
				AND    misc.receipt_number = gc_receipt_number
				AND    misc.reference_id = cash.cash_receipt_id
				AND    cash.TYPE = 'CASH'
				AND    cash.cash_receipt_id = xold.cash_receipt_id
				AND    xold.prepaid_amount < 0
				AND    xold.transaction_number = xoldd.transaction_number
				AND    ROWNUM = 1;

				x_dep_retrieval_status := g_single;
				gc_is_deposit_return := TRUE;   -- indicates deposit return
				gc_inv_flag := 'R';   -- indicates invoice type was a return
			END;
		END IF;

--------------------------------------------------------------------------
-- Retrieve Discount Amount, Ship To State, Zip Code for Deposit
--------------------------------------------------------------------------
		BEGIN
			IF (gc_remit_processing_type = g_poe_single_pmt_multi_ord)
			THEN
				xx_location_and_log
					(g_loc,
					 'Retrieve Deposit Discount, Ship To State, and Zip Code by AOPS Order Number and Receipt Number. ');

				SELECT   NVL(SUM(ws_discount_amount),
							 0),
						 attribute1 shiptozipcode,
						 attribute2 shiptostate
				INTO     ln_discount_amount,
						 gc_aops_dep_shipto_zipcode,
						 gc_aops_dep_shipto_state
				FROM     xx_iby_deposit_aops_order_dtls
				WHERE    receipt_number = gc_receipt_number
				--AND aops_order_number = gc_transaction_number   Transaction number holds the POS trx nunber, and not the AOPS deposit number
				AND      aops_order_number = gc_orig_sys_document_ref
				-- Orig Sys Doc Ref holds the actual AOPS number, Defect 17473.
				GROUP BY attribute1, attribute2;

				-- Setting deposit retrieval status for single payment call
				x_dep_retrieval_status := g_single;
			ELSE
				xx_location_and_log(g_loc,
									'Retrieve Deposit Discount, Ship To State, and Zip Code by Receipt Number Only. ');

				SELECT   NVL(SUM(ws_discount_amount),
							 0),
						 attribute1 shiptozipcode,
						 attribute2 shiptostate
				INTO     ln_discount_amount,
						 gc_aops_dep_shipto_zipcode,
						 gc_aops_dep_shipto_state
				FROM     xx_iby_deposit_aops_order_dtls
				WHERE    receipt_number = gc_receipt_number
				GROUP BY attribute1, attribute2;
			END IF;

			gc_ixdiscountamount :=   ln_discount_amount
								   * 100;
		EXCEPTION
			WHEN OTHERS
			THEN
				xx_location_and_log
						 (g_loc,
						  'Entering NO_DATA_FOUND Exception in XX_RETRIEVE_DEPOSIT_INFO for Retrieve Discount Amount. ');
				gc_ixdiscountamount := 0;
				gc_aops_dep_shipto_zipcode := NULL;
				gc_aops_dep_shipto_state := NULL;
		END;

----------------------------------------------------
-- Print Debug Information
----------------------------------------------------
		IF gc_sale_type = g_sale
		THEN
			xx_location_and_log(g_log,
								   'Transaction Number       : '
								|| gc_trx_number);
			xx_location_and_log(g_log,
								   'Customer TRX ID          : '
								|| gn_customer_trx_id);
		ELSE
			xx_location_and_log(g_log,
								   'CM Transaction Number    : '
								|| gc_cm_number);
			xx_location_and_log(g_log,
								   'CM Customer TRX ID       : '
								|| gc_cm_customer_trx_id);
		END IF;

		xx_location_and_log(g_log,
							   'Invoice Exists?          : '
							|| gc_inv_flag);
		xx_location_and_log(g_log,
							   'Customer TRX Type        : '
							|| gc_cust_trx_type);
		xx_location_and_log(g_log,
							   'Sales Order Number       : '
							|| gn_order_number);
		xx_location_and_log(g_log,
							   'Sales Order Trans Type   : '
							|| gc_sales_order_trans_type);
		xx_location_and_log(g_log,
							   'Deposit Retrieval Status : '
							|| x_dep_retrieval_status);
		xx_location_and_log(g_log,
							   'Cash Receipt Id          : '
							|| gn_cash_receipt_id);
		xx_location_and_log(g_log,
							   'Application Ref #        : '
							|| gc_application_ref_num);
		xx_location_and_log(g_log,
							   'Customer Account ID      : '
							|| gn_cust_account_id);
		xx_location_and_log(g_log,
							   'Customer Number          : '
							|| gc_customer_number);
		xx_location_and_log(g_log,
							   'Customer Orig Sys Ref    : '
							|| gc_cust_orig_system_ref);
		xx_location_and_log(g_log,
							   'Bill To Customer Id      : '
							|| gn_bill_to_customer_id);
		xx_location_and_log(g_log,
							   'Ship To Customer Td      : '
							|| gn_ship_to_customer_id);
		xx_location_and_log(g_log,
							   'Bill To Contact Id       : '
							|| gn_bill_to_contact_id);
		xx_location_and_log(g_log,
							   'Ship To Contact Id       : '
							|| gn_ship_to_contact_id);
		xx_location_and_log(g_log,
							   'Bill To Site Use Id      : '
							|| gn_bill_to_site_use_id);
		xx_location_and_log(g_log,
							   'Ship To Site Id          : '
							|| gn_ship_to_site_use_id);
		xx_location_and_log(g_log,
							   'Discount Amount          : '
							|| ln_discount_amount);
		xx_location_and_log(g_log,
							   'AOPS Dep Ship to Zipcode : '
							|| gc_aops_dep_shipto_zipcode);
		xx_location_and_log(g_log,
							   'AOPS Dep Ship to State   : '
							|| gc_aops_dep_shipto_state);
		xx_location_and_log(g_log,
							   'Transaction Number (Ref) : '
							|| gc_transaction_number);
		xx_location_and_log(g_log,
							   'Deposit Store Location   : '
							|| gc_deposit_store_location);
		xx_location_and_log(g_log,
							   'Orig Sys Doc Ref (Refund): '
							|| gc_orig_sys_document_ref);
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			xx_location_and_log(g_loc,
								'Encountered NO_DATA_FOUND in XX_RETRIEVE_DEPOSIT_INFO. ');
			x_dep_retrieval_status := g_zero;
		WHEN TOO_MANY_ROWS
		THEN
			xx_location_and_log(g_loc,
								'Encountered TOO_MANY_ROWS in XX_RETRIEVE_DEPOSIT_INFO. ');
			x_dep_retrieval_status := g_multi;
	END xx_retrieve_deposit_info;

-- +====================================================================+
-- | PROCEDURE  : XX_NON_POE_SETTLEMENT                                 |
-- |                                                                    |
-- | DESCRIPTION: Procedure is used for processing settlement for a     |
-- |              NON-POE receipt.                                      |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_non_poe_settlement
	IS
	BEGIN
--------------------------------------------------------------------------
-- Retrieve Invoice Information (Non-POS Sources)
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'***** Executing XX_RETRIEVE_INVOICE_INFO from XX_NON_POE_SETTLEMENT ***** ');
		xx_retrieve_invoice_info(x_inv_retrieval_status =>      gc_invoice_retrieval_status);
		xx_location_and_log(g_loc,
							'Checking Invoice Retrieval Status within XX_NON_POE_SETTLEMENT.');

		IF gc_invoice_retrieval_status = g_single
		THEN
			xx_location_and_log
				  (g_loc,
				   '***** Executing XX_SINGLE_TRX_SETTLEMENT from XX_NON_POE_SETTLEMENT (Single Invoice Retrieved)*** ');
			xx_single_trx_settlement;
		ELSIF(gc_invoice_retrieval_status = g_multi)
		THEN
			xx_location_and_log(g_loc,
								'Checking Remittance Processing Type (Multiple Invoices Found). ');

			IF (gc_remit_processing_type = g_irec)
			THEN
				xx_location_and_log
					(g_loc,
					 '***** Executing XX_IREC_MULTI_TRX_SETTLEMENT from XX_NON_POE_SETTLEMENT (IREC - Multiple Invoices Found) ***** ');
				xx_irec_multi_trx_settlement;
			ELSE
				xx_location_and_log
					(g_loc,
					 'Raising EX_TOO_MANY_INVOICES exception from XX_NON_POE_SETTLEMENT (Multiple Invoices Found and not IREC sale type). ');
				RAISE ex_too_many_invoices;
			END IF;
		ELSIF(gc_invoice_retrieval_status = g_zero)
		THEN
--------------------------------------------------------------------------
-- Retrieve ORDER Info Since Invoice Not Found (Non-POS Sources)
--------------------------------------------------------------------------
			xx_location_and_log
						  (g_loc,
						   '***** Executing XX_RETRIEVE_ORDER_INFO from XX_NON_POE_SETTLEMENT(No Invoice Found) ***** ');
			xx_retrieve_order_info(x_order_retrieval_status =>      gc_order_retrieval_status);
			xx_location_and_log(g_loc,
								'Checking Order Retrieval Status.');

			IF (gc_order_retrieval_status = g_single)
			THEN
				xx_location_and_log
					(g_loc,
					 '***** Executing XX_SINGLE_TRX_SETTLEMENT from XX_NON_POE_SETTLEMENT (Single Order Retrieved) ***** ');
				xx_single_trx_settlement;
			ELSIF(gc_order_retrieval_status = g_multi)
			THEN
				xx_location_and_log
					(g_loc,
					 'Raising EX_TOO_MANY_ORDERS exception from XX_NON_POE_SETTLEMENT (Multiple invoices retrieved for NON-IREC). ');
				RAISE ex_too_many_orders;
			ELSIF(gc_order_retrieval_status = g_zero)
			THEN
--------------------------------------------------------------------------
-- Retrieve DEPOSIT Info Since Inv. and Order Not Found (Non-POS Sources)
--------------------------------------------------------------------------
				xx_location_and_log
					   (g_loc,
						'***** Executing XX_RETRIEVE_DEPOSIT_INFO from XX_NON_POE_SETTLEMENT (No Invoice Found) ***** ');
				xx_retrieve_deposit_info(x_dep_retrieval_status =>      gc_deposit_retrieval_status);
				xx_location_and_log(g_loc,
									'Checking Deposit Retrieval Status.');

				IF (gc_deposit_retrieval_status = g_single)
				THEN
					xx_location_and_log
						(g_loc,
						 '***** Executing XX_SINGLE_TRX_SETTLEMENT from XX_NON_POE_SETTLEMENT (Single Deposit Retrieved) ***** ');
					xx_single_trx_settlement;
				ELSIF(gc_deposit_retrieval_status = g_multi)
				THEN
					xx_location_and_log
						(g_loc,
						 'Raising EX_TOO_MANY_DEPOSITS exception from XX_NON_POE_SETTLEMENT (Too many deposits found for NON-POE/POS). ');
					RAISE ex_too_many_deposits;
				ELSIF(gc_deposit_retrieval_status = g_zero)
				THEN
					xx_location_and_log
						(g_loc,
						 'Raising EX_NO_DEPOSIT_INFO exception from XX_NON_POE_SETTLEMENT (No Deposit/Order/Invoice found for NON-POE/POS). ');
					RAISE ex_no_deposit_info;
				END IF;   -- Deposit Retrieval
			END IF;   -- Order Retrieval
		END IF;   -- Invoice Retrieval
	END xx_non_poe_settlement;

-- +====================================================================+
-- | PROCEDURE  : XX_POE_INTSTORECUST_SETTLEMENT                        |
-- |                                                                    |
-- | DESCRIPTION: Procedure is used for processing settlement for       |
-- |              POS/POE receipt for internal store customers.         |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_poe_intstorecust_settlement
	IS
	BEGIN
--------------------------------------------------------------------------
-- AR invoice does not exist.  All information was retrieved from the Order
--------------------------------------------------------------------------
		gc_inv_flag := 'N';
--------------------------------------------------------------------------
-- Process Single Order Settlement (POE_INT_STORE_CUST)
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'Execute XX_SINGLE_TRX_SETTLEMENT from XX_POE_INTSTORECUST_SETTLEMENT. ');
		xx_single_trx_settlement;
	END xx_poe_intstorecust_settlement;

-- +====================================================================+
-- | PROCEDURE  : XX_POE_SGLPMT_MULTI_SETTLEMENT                        |
-- |                                                                    |
-- | DESCRIPTION: Procedure is used for processing settlement for a     |
-- |              receipt which pays multiple orders.                   |
-- |                                                                    |
-- | PARAMETERS : NONE *** private package variables are used ***       |
-- |                                                                    |
-- | RETURNS    : NONE *** private package variables are used ***       |
-- +====================================================================+
	PROCEDURE xx_poe_sglpmt_multi_settlement
	IS
		-- Local Variables for Holding Customer Exceptions for one AOPS Order
		lc_ixbankuserdata           xx_iby_batch_trxns.ixbankuserdata%TYPE;
		lc_ixcustomerreferenceid    xx_iby_batch_trxns.ixcustomerreferenceid%TYPE;
		ln_amex_except1             NUMBER                                                  := 0;
		ln_amex_except2             NUMBER                                                  := 0;
		ln_amex_except3             NUMBER                                                  := 0;
		ln_amex_except4             NUMBER                                                  := 0;
		ln_amex_except5             NUMBER                                                  := 0;
		ln_amex_except6             NUMBER                                                  := 0;
		ln_amex_except7             NUMBER                                                  := 0;
		lc_ixpurchasername          xx_iby_batch_trxns.ixpurchasername%TYPE;
		lc_po_override_set          xxcdh_cust_override_fl_v.po_override_settlements%TYPE;
		lc_cust_code_override       xxcdh_cust_override_fl_v.cust_code_override%TYPE;
		lc_sec_po_override          xxcdh_cust_override_fl_v.secondary_po%TYPE;
		ln_other_cust_exp           NUMBER                                                  := 0;
		lc_other_cust               xx_fin_translatevalues.source_value1%TYPE;
		lc_ixshiptoname             xx_iby_batch_trxns.ixshiptoname%TYPE;
		lc_aops_dep_shipto_zipcode  xx_iby_deposit_aops_order_dtls.attribute1%TYPE;
		lc_aops_dep_shipto_state    xx_iby_deposit_aops_order_dtls.attribute2%TYPE;
		-- Local Variables for holding the TOTALS for all orders retrieved
		lc_ixdiscountamount         xx_iby_batch_trxns.ixdiscountamount%TYPE                := '0';
		lc_ixmisccharge             xx_iby_batch_trxns.ixmisccharge%TYPE;
		lc_ixnationaltaxamount      xx_iby_batch_trxns.ixnationaltaxamount%TYPE             := '0';
		lc_ixothertaxamount         xx_iby_batch_trxns.ixothertaxamount%TYPE                := '0';
		lc_ixtaxableamount          xx_iby_batch_trxns.ixtaxableamount%TYPE                 := '0';
		lc_ixtotalsalestaxamount    xx_iby_batch_trxns.ixtotalsalestaxamount%TYPE           := '0';
		lc_tot_order_amount         xx_iby_batch_trxns.attribute5%TYPE                      := '0';
		-- Local Variables used for tracking
		lc_order_loop_cnt           NUMBER                                                  := 0;
		lc_201_created              VARCHAR2(1);
		lc_auth_date				xx_iby_batch_trxns.ixorderdate%TYPE				:= NULL;	-- Added for version 48.7

		CURSOR lcu_single_pmt
		IS
			SELECT   xaord.order_payment_id,
					 xaord.cash_receipt_id,
					 xoldd.orig_sys_document_ref,
					 xoldd.transaction_number,
					 xold.store_location,
					 xoldd.single_pay_ind,
					 ooha.order_number,
					 ooha.header_id,
					 ooha.cust_po_number,
					 xoha.cost_center_dept,
					 xoha.desk_del_addr,
					 xoha.release_number,
					 TO_CHAR(ooha.ordered_date,
							 'MMDDYYYY') ixorderdate,
					 ooha.ship_from_org_id,
					 DECODE(LENGTH(xoldd.orig_sys_document_ref),
							20, 'POS',
							'AOPS') sp_order_type
			FROM     xx_ar_order_receipt_dtl xaord,
					 xx_om_legacy_deposits xold,
					 xx_om_legacy_dep_dtls xoldd,
					 oe_order_headers_all ooha,
					 xx_om_header_attributes_all xoha
			WHERE    xaord.order_payment_id = gn_order_payment_id
			AND      xaord.cash_receipt_id = xold.cash_receipt_id
			AND      xold.transaction_number = xoldd.transaction_number
			AND      xoldd.orig_sys_document_ref = ooha.orig_sys_document_ref(+)
			AND      ooha.header_id = xoha.header_id(+)
			ORDER BY sp_order_type ASC, ooha.header_id DESC;

		ltab_single_pmt_rec         lcu_single_pmt%ROWTYPE;
	BEGIN
		gn_seq_number := 0;   -- added per Defect 13812
		lc_201_created := 'N';   -- added per defect 13640
		xx_location_and_log(g_loc,
							'Open lcu_single_pmt cursor. ');
		xx_location_and_log(g_loc,
							   'gn_order_payment_id = '
							|| gn_order_payment_id);

		OPEN lcu_single_pmt;

		LOOP
			xx_location_and_log(g_loc,
								'Fetch from lcu_single_pmt cursor. ');

			FETCH lcu_single_pmt
			INTO  ltab_single_pmt_rec;

			EXIT WHEN lcu_single_pmt%NOTFOUND;

--------------------------------------------------------------
-- Assign CURSOR variables to GLOBAL variables and increment counter
--------------------------------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Increment Loop Counter. ');
				lc_order_loop_cnt :=   lc_order_loop_cnt
									 + 1;
				xx_location_and_log(g_loc,
									'Assign CURSOR variables to GLOBAL variables. ');
				gn_order_payment_id := ltab_single_pmt_rec.order_payment_id;
				gn_cash_receipt_id := ltab_single_pmt_rec.cash_receipt_id;
				gc_orig_sys_document_ref := ltab_single_pmt_rec.orig_sys_document_ref;
				gc_transaction_number := ltab_single_pmt_rec.transaction_number;
				gc_single_pay_ind := ltab_single_pmt_rec.single_pay_ind;
				gc_deposit_store_location := ltab_single_pmt_rec.store_location;
				gn_order_number := ltab_single_pmt_rec.order_number;
				gn_order_header_id := ltab_single_pmt_rec.header_id;
				gc_ixcostcenter := ltab_single_pmt_rec.cost_center_dept;
				gc_ixdesktoplocation := ltab_single_pmt_rec.desk_del_addr;
				gc_ixreleasenumber := ltab_single_pmt_rec.release_number;
				gc_cust_po_number := ltab_single_pmt_rec.cust_po_number;
				gc_ixcustomerreferenceid := ltab_single_pmt_rec.cust_po_number;
				gc_ixorderdate := ltab_single_pmt_rec.ixorderdate;
				gn_ship_from_org_id := ltab_single_pmt_rec.ship_from_org_id;
			END;
			
			/* Version 48.7 - Retrieving credit_card_approval_date for xx_poe_sglpmt_multi_settlement */
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieving ixorderdate from auth date of oe_payments for xx_poe_sglpmt_multi_settlement. ');

				SELECT TO_CHAR(op.CREDIT_CARD_APPROVAL_DATE,'MMDDYYYY') CREDIT_CARD_APPROVAL_DATE
				INTO lc_auth_date
				FROM oe_payments op,
					 xx_ar_order_receipt_dtl xaord
				WHERE 1=1
				AND op.header_id = xaord.header_id
				AND op.orig_sys_payment_ref = xaord.orig_sys_payment_ref
				AND xaord.order_payment_id = gn_order_payment_id;

				xx_location_and_log(g_log,
									   'Auth Date for xx_poe_sglpmt_multi_settlement: '
									|| lc_auth_date);
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					xx_location_and_log
						(g_loc,
						 'Entering NO_DATA_FOUND Exception in lc_auth_date for xx_poe_sglpmt_multi_settlement Retrieve Auth Date. ');
					lc_auth_date := NULL;
			END;
				
			IF lc_auth_date IS NOT NULL
			THEN
			gc_ixorderdate := lc_auth_date;
			END IF;
			/* End version 48.7 */

--------------------------------------------------------------
-- Process Customer Exceptions
--------------------------------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Process Customer Exceptions for 1st AOPS order with customer fields. ');

				IF lc_order_loop_cnt = 1
				THEN
					xx_location_and_log
							   (g_loc,
								'***** Executing XX_PROCESS_CUST_EXCEPTIONS from XX_POE_SGLPMT_MULTI_SETTLEMENT ***** ');
					xx_process_cust_exceptions;
					xx_location_and_log(g_loc,
										'Capture customer fields and assign to local variables. ');
					lc_ixbankuserdata := gc_ixbankuserdata;
					lc_ixcustomerreferenceid := gc_ixcustomerreferenceid;
					ln_amex_except1 := gn_amex_except1;
					ln_amex_except2 := gn_amex_except2;
					ln_amex_except3 := gn_amex_except3;
					ln_amex_except4 := gn_amex_except4;
					ln_amex_except5 := gn_amex_except5;
					ln_amex_except6 := gn_amex_except6;
					ln_amex_except7 := gn_amex_except7;
					lc_ixpurchasername := gc_ixpurchasername;
					lc_po_override_set := gc_po_override_set;
					lc_cust_code_override := gc_cust_code_override;
					lc_sec_po_override := gc_sec_po_override; --26.5
					ln_other_cust_exp := gn_other_cust_exp;
					lc_other_cust := gc_other_cust;
					lc_ixshiptoname := gc_ixshiptoname;
				END IF;
			END;

--------------------------------------------------------------
-- Retrieve Remaining Information
--------------------------------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieve Remaining Information for Settlement Staging. ');

				IF gn_order_number IS NULL
				THEN
--------------------------------------------------------------
-- Retrieve Deposit Information (order not imported)
--------------------------------------------------------------
					BEGIN
						xx_location_and_log
							(g_loc,
							 '***** Executing XX_RETRIEVE_DEPOSIT_INFO from XX_POE_SGLPMT_MULTI_SETTLEMENT (Order/Invoice Not Imported) ***** ');
						xx_retrieve_deposit_info(x_dep_retrieval_status =>      gc_deposit_retrieval_status);
						-- Add discount amount to local running total for deposit information just retrieved
						lc_ixdiscountamount :=   lc_ixdiscountamount
											   + gc_ixdiscountamount;
						-- Capture Ship to information for deposit information just retrieved ??? should this be once
						lc_aops_dep_shipto_zipcode := gc_aops_dep_shipto_zipcode;
						lc_aops_dep_shipto_state := gc_aops_dep_shipto_state;
						xx_location_and_log(g_loc,
											'Checking Deposit Retrieval Status.');

						IF (gc_deposit_retrieval_status <> g_single)
						THEN
							IF (gc_deposit_retrieval_status = g_multi)
							THEN
								xx_location_and_log
										(g_loc,
										 'Raising EX_TOO_MANY_DEPOSITS exception from XX_POE_SGLPMT_MULTI_SETTLEMENT. ');
								RAISE ex_too_many_deposits;
							ELSIF(gc_deposit_retrieval_status = g_zero)
							THEN
								xx_location_and_log
										  (g_loc,
										   'Raising EX_NO_DEPOSIT_INFO exception from XX_POE_SGLPMT_MULTI_SETTLEMENT. ');
								RAISE ex_no_deposit_info;
							END IF;   -- Deposit Retrieval Status Check (Multi)
						END IF;   -- Deposit Retrieval Status Check (Single)
					END;
				ELSE
--------------------------------------------------------------------------
-- Retrieve Invoice Information (Attempting since order was imported)
--------------------------------------------------------------------------
					BEGIN
						xx_location_and_log
								 (g_loc,
								  '***** Executing XX_RETRIEVE_INVOICE_INFO from XX_POE_SGLPMT_MULTI_SETTLEMENT ***** ');
						xx_retrieve_invoice_info(x_inv_retrieval_status =>      gc_invoice_retrieval_status);
						xx_location_and_log(g_loc,
											'Checking Invoice Retrieval Status with XX_POE_SGLPMT_MULTI_SETTLEMENT.');

						IF gc_invoice_retrieval_status <> g_single
						THEN
							IF (gc_invoice_retrieval_status = g_multi)
							THEN
								xx_location_and_log
										(g_loc,
										 'Raising EX_TOO_MANY_INVOICES exception from XX_POE_SGLPMT_MULTI_SETTLEMENT. ');
								RAISE ex_too_many_invoices;
							ELSIF(gc_invoice_retrieval_status = g_zero)
							THEN
--------------------------------------------------------------------------
-- Retrieve ORDER Information (Invoice not imported)
--------------------------------------------------------------------------
								xx_location_and_log
									(g_loc,
									 '***** Executing XX_RETRIEVE_ORDER_INFO from XX_POE_SGLPMT_MULTI_SETTLEMENT (No Invoice Found) ***** ');
								xx_retrieve_order_info(x_order_retrieval_status =>      gc_order_retrieval_status);
								xx_location_and_log(g_loc,
													'Checking Order Retrieval Status.');

								IF (gc_order_retrieval_status <> g_single)
								THEN
									IF (gc_order_retrieval_status = g_multi)
									THEN
										xx_location_and_log
											(g_loc,
											 'Raising EX_TOO_MANY_ORDERS exception from XX_POE_SGLPMT_MULTI_SETTLEMENT. ');
										RAISE ex_too_many_orders;
									ELSIF(gc_order_retrieval_status = g_zero)
									THEN
										xx_location_and_log
											(g_loc,
											 'Raising EX_NO_ORDER_INFO exception from XX_POE_SGLPMT_MULTI_SETTLEMENT. ');
										RAISE ex_no_order_info;
									END IF;   -- Order Retrieval Check (Multi)
								END IF;   -- Order Retrieval Check (Single)
							END IF;   -- Invoice Retrieval Check (Zero)
						END IF;   -- Invoice Retrieval Check (Single)
					END;   -- Retrieve Invoice
				END IF;   -- Order Number Check
			END;

------------------------------------------------------------
-- Retrieve/Capture of Additional Variables Post Inv/Ord/Dep
------------------------------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieve/Capture Additional Variables Post Inv/Ord/Dep. ');

				IF lc_order_loop_cnt = 1
				THEN
					xx_set_post_trx_variables;
				END IF;
			END;

------------------------------------------------------------
-- Calculate and Capture Tax, Disc, and Shipping Amounts
------------------------------------------------------------
			BEGIN
				xx_location_and_log
							   (g_loc,
								'***** Executing XX_CALC_TAX_DISC_SHIP_AMTS from XX_POE_SGLPMT_MULTI_SETTLEMENT ***** ');
				xx_calc_tax_disc_ship_amts;
				xx_location_and_log
						  (g_loc,
						   'Calculate running totals as each dep/inv/order is processed by XX_CALC_TAX_DISC_SHIP_AMTS. ');
				lc_ixdiscountamount :=   lc_ixdiscountamount
									   + gc_ixdiscountamount;
				lc_ixmisccharge :=   lc_ixmisccharge
								   + gc_ixmisccharge;
				lc_ixnationaltaxamount :=   lc_ixnationaltaxamount
										  + gc_ixnationaltaxamount;
				lc_ixothertaxamount :=   lc_ixothertaxamount
									   + gc_ixothertaxamount;
				lc_ixtaxableamount :=   lc_ixtaxableamount
									  + gc_ixtaxableamount;
				lc_ixtotalsalestaxamount :=   lc_ixtotalsalestaxamount
											+ gc_ixtotalsalestaxamount;
				lc_tot_order_amount :=   lc_tot_order_amount
									   + gc_tot_order_amount;
			END;

------------------------------------------------------------
-- Set Receipt, Tran, and Recpt # for AOPS dep/inv/order
------------------------------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Set Receipt, Tran, and Recpt # for AOPS dep/inv/order. ');

				IF lc_order_loop_cnt = 1
				THEN
					xx_location_and_log
						   (g_loc,
							'***** Executing XX_SET_RECEIPT_TRANS_RECPT_NUM from XX_POE_SGLPMT_MULTI_SETTLEMENT ***** ');
					xx_set_receipt_trans_recpt_num;
				END IF;
			END;

------------------------------------------------------------
-- Create 201 Settlement Records for each dep/inv/order
------------------------------------------------------------
			xx_location_and_log
							 (g_loc,
							  ' ***** Executing XX_CREATE_201_SETTLEMENT_REC from XX_POE_SGLPMT_MULTI_SETTLEMENT ***** ');
			xx_create_201_settlement_rec;

---------------------------------------------
-- Checking that at least one 201 was created
---------------------------------------------
			IF gb_201_created
			THEN   -- added per defect 13640
				xx_location_and_log(g_loc,
									' ***** XX_POE_SGLPMT_MULTI_SETTLEMENT 201 succesfully created ***** ');
				lc_201_created := 'Y';
			END IF;
		END LOOP;

		CLOSE lcu_single_pmt;

-------------------------------------------------
-- Checking if no 201 records are created setting
-------------------------------------------------
		IF lc_201_created = 'N'
		THEN
			gb_201_created := FALSE;
		END IF;

------------------------------------------------------------
-- Set Global Variables for the one AOPS order local vars
------------------------------------------------------------
		BEGIN
			xx_location_and_log(g_loc,
								'Set Global Variables for the one AOPS order local vars. ');
			-- Customer exception fields (XX_PROCESS_CUST_EXCEPTIONS)
			gc_ixbankuserdata := lc_ixbankuserdata;
			gc_ixcustomerreferenceid := lc_ixcustomerreferenceid;
			gn_amex_except1 := ln_amex_except1;
			gn_amex_except2 := ln_amex_except2;
			gn_amex_except3 := ln_amex_except3;
			gn_amex_except4 := ln_amex_except4;
			gn_amex_except5 := ln_amex_except5;
			gn_amex_except6 := ln_amex_except6;
			gn_amex_except7 := ln_amex_except7;
			gc_ixpurchasername := lc_ixpurchasername;
			gc_po_override_set := lc_po_override_set;
			gc_cust_code_override := lc_cust_code_override;
			gc_sec_po_override   := lc_sec_po_override; --26.5
			gn_other_cust_exp := ln_other_cust_exp;
			gc_other_cust := lc_other_cust;
			gc_ixshiptoname := lc_ixshiptoname;
			-- Tax, Discount, Misc, etc. Amounts (XX_CALC_TAX_DISC_SHIP_AMTS)
			gc_ixdiscountamount := lc_ixdiscountamount;
			gc_ixmisccharge := lc_ixmisccharge;
			gc_ixnationaltaxamount := lc_ixnationaltaxamount;
			gc_ixothertaxamount := lc_ixothertaxamount;
			gc_ixtaxableamount := lc_ixtaxableamount;
			gc_ixtotalsalestaxamount := lc_ixtotalsalestaxamount;
			gc_tot_order_amount := lc_tot_order_amount;

			-- Added for defect 17473.
			IF (    lc_aops_dep_shipto_zipcode IS NOT NULL
				AND gc_aops_dep_shipto_zipcode IS NULL)
			THEN
				gc_aops_dep_shipto_zipcode := lc_aops_dep_shipto_zipcode;
			END IF;

			IF (    lc_aops_dep_shipto_state IS NOT NULL
				AND gc_aops_dep_shipto_state IS NULL)
			THEN
				gc_aops_dep_shipto_state := lc_aops_dep_shipto_state;
			END IF;
		END;

------------------------------------------------------------
-- Set IXTOTALSALESTAXCOLLIND and IXNATIONALTAXCOLLINDICATOR
------------------------------------------------------------
		xx_location_and_log(g_loc,
							'***** Executeing XX_SET_TAX_COLL_INDICATORS from XX_POE_SGLPMT_MULTI_SETTLEMENT ***** ');
		xx_set_tax_coll_indicators;
------------------------------------------------------------
-- Create 101 Settlement Record for single payment
------------------------------------------------------------
				--START Defect#38215 - amex to vantiv conv
				IF gn_amex_cpc > 0 and NVL(gc_ixtokenflag,'N') = 'Y'
			THEN
		   xx_location_and_log(g_loc,
							'***** Executing PROCESS_AMEX_DATA from XX_POE_SGLPMT_MULTI_SETTLEMENT ***** ');
				   process_amex_data;
				END IF;
				--END Defect#38215 - amex to vantiv conv

				--Start code Changes for V48.0
		xx_location_and_log(g_log,
							   'COF Transactions Update for Wallet Type            : '
							|| gc_ixwallet_type);
				IF gc_ixwallet_type is not null
			THEN
		   xx_location_and_log(g_loc,
							'***** Executing XX_UPDATE_COF_TRANS from xx_poe_sglpmt_multi_settlement ***** ');
				   XX_UPDATE_COF_TRANS;
				END IF;
				--End code Changes for V48.0

		xx_location_and_log(g_loc,
							'***** Executing XX_CREATE_101_SETTLEMENT_REC from XX_POE_SGLPMT_MULTI_SETTLEMENT ***** ');

---------------------------------------------------------------------------------------------------
-- Set gc_ixtransactiontype based on legacy_deposits Amount sign  --added by sripal for NAIT-115171
---------------------------------------------------------------------------------------------------
	  BEGIN
	  SELECT decode(sign(xold.PREPAID_AMOUNT),-1,'Refund','Sale')
	  INTO gc_ixtransactiontype
	  FROM xx_ar_order_receipt_dtl xaord,
		   xx_om_legacy_deposits xold
	 WHERE  xaord.order_payment_id = gn_order_payment_id
	 AND    xaord.cash_receipt_id    = xold.cash_receipt_id
	 AND    ROWNUM < 2;
	 EXCEPTION
	 WHEN NO_DATA_FOUND
	 THEN
	 xx_location_and_log
	(g_loc,
	'ENTERING NO_DATA_FOUND EXCEPTION FOR GC_IXTRANSACTIONTYPE IN XX_POE_SGLPMT_MULTI_SETTLEMENT. ');
		NULL;
END;


		xx_create_101_settlement_rec;
	END xx_poe_sglpmt_multi_settlement;

-- +====================================================================+
-- | PROCEDURE  : XX_STG_RECEIPT_FOR_SETTLEMENT (Overloaded - Private)  |
-- |                                                                    |
-- | DESCRIPTION: Procedure is used for performing the overall staging  |
-- |              of settlement records for all receipts except CCREFUND|
-- |                                                                    |
-- | PARAMETERS : p_cash_receipt_id                                     |
-- |              p_receipt_amount                                      |
-- |              p_oapfstoreid                                         |
-- |              p_oapforder_id                                        |
-- |              p_order_payment_id                                    |
-- |                                                                    |
-- | RETURNS    : x_error_buf                                           |
-- |              x_ret_code                                            |
-- |              x_receipt_ref                                         |
-- +====================================================================+
	PROCEDURE xx_stg_receipt_for_settlement(
		x_error_buf         OUT     VARCHAR2,
		x_ret_code          OUT     NUMBER,
		x_receipt_ref       OUT     VARCHAR2,
		p_cash_receipt_id   IN      VARCHAR2 DEFAULT NULL,
		p_receipt_amount    IN      VARCHAR2 DEFAULT NULL,
		p_oapfstoreid       IN      VARCHAR2 DEFAULT NULL,
		p_oapforder_id      IN      VARCHAR2 DEFAULT NULL,
		p_order_payment_id  IN      VARCHAR2 DEFAULT NULL)
	IS
	BEGIN
--------------------------------------------------------------------------
-- Step #1 - Initialize Variables
--------------------------------------------------------------------------
		BEGIN
			xx_location_and_log
							 (g_loc,
							  '***** Executing XX_INIT_PRIVATE_PKG_VARIABLES from XX_STG_RECEIPT_FOR_SETTLEMENT ***** ');
			xx_init_private_pkg_variables;
			-- Set Global Variables Based on Parameter Values
			xx_location_and_log(g_loc,
								'Set Global Variables Based on Parameter Values. ');
			-- Set Global Variables for all calls
			gn_order_payment_id := p_order_payment_id;
			-- Set Global Variables for Call from AR Automatic Remittance Program (non-POE_INT_STORE_CUST Remit Processing Type)
			gc_oapforder_id := p_oapforder_id;
			gn_cash_receipt_id := p_cash_receipt_id;
			gc_ixamount := p_receipt_amount;   -- gc_ixamount will be multiplied by 100 during XX_RETRIEVE_RECEIPT_INFO
			gc_oapfstoreid := p_oapfstoreid;
			DBMS_OUTPUT.put_line('Set Global Variables Based on Parameter Values');
		END;

		IF p_cash_receipt_id IS NOT NULL
		THEN
			xx_location_and_log(g_loc,
								   'Getting operating unit id for receipt id '
								|| p_cash_receipt_id);

			SELECT org_id
			INTO   gn_org_id
			FROM   ar_cash_receipts_all
			WHERE  cash_receipt_id = p_cash_receipt_id;
		ELSIF p_order_payment_id IS NOT NULL
		THEN
			xx_location_and_log(g_loc,
								   'Getting operating unit id for order_payment_id '
								|| p_order_payment_id);

			SELECT org_id
			INTO   gn_org_id
			FROM   xx_ar_order_receipt_dtl
			WHERE  order_payment_id = p_order_payment_id;
		END IF;

--------------------------------------------------------------------------
-- STEP #2 - Retrieve Processing Type
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'***** Executing XX_RETRIEVE_PROCESSING_TYPE from XX_STG_RECEIPT_FOR_SETTLEMENT ***** ');
		xx_retrieve_processing_type;   ---default


	 /*   if (gc_remit_processing_type != g_poe_int_store_cust)
		Then

		BEGIN
		SELECT CASH_RECEIPT_ID
		INTO  gn_cash_receipt_id
		FROM xx_ar_order_receipt_dtl xaord
		WHERE xaord.order_payment_id= p_order_payment_id;
		END;

		END IF;*/
--------------------------------------------------------------------------
-- STEP #3 - Set PRE-RECEIPT Variables
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'***** XX_SET_PRE_RECEIPT_VARIABLES from XX_STG_RECEIPT_FOR_SETTLEMENT ***** ');
		xx_set_pre_receipt_variables;
--------------------------------------------------------------------------
-- STEP #4 - Retrieve Receipt Information
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'***** Executing XX_RETRIEVE_RECEIPT_INFO from XX_STG_RECEIPT_FOR_SETTLEMENT ***** ');
		xx_retrieve_receipt_info;
--------------------------------------------------------------------------
-- STEP #5 - Set POST-RECEIPT Variables
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'***** Executing XX_SET_POST_RECEIPT_VARIABLES from XX_STG_RECEIPT_FOR_SETTLEMENT ***** ');
		xx_set_post_receipt_variables;
--------------------------------------------------------------------------
-- STEP #6 - Stage Settlement Based on Remittance Processing Type
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'Stage Settlement Based on Remittance Processing Type. ');

		BEGIN
			IF (gc_remit_processing_type = g_poe_int_store_cust)
			THEN
--------------------------------------------------------------------
-- POE/POS Processing Processing - Internal Store Customer
--------------------------------------------------------------------
				xx_location_and_log
							(g_loc,
							 '***** Executing XX_POE_INTSTORECUST_SETTLEMENT from XX_STG_RECEIPT_FOR_SETTLEMENT ***** ');
				xx_poe_intstorecust_settlement;
			ELSIF(gc_remit_processing_type = g_poe_single_pmt_multi_ord)
			THEN
--------------------------------------------------------------------
-- POE/POS Settlement Processing - Single Payment and Multiple Orders
--------------------------------------------------------------------
				xx_location_and_log
							(g_loc,
							 '***** Executing XX_POE_SGLPMT_MULTI_SETTLEMENT from XX_STG_RECEIPT_FOR_SETTLEMENT ***** ');
				xx_poe_sglpmt_multi_settlement;
			ELSE
--------------------------------------------------------------------
-- NON POE/POS Settlement Processing
--------------------------------------------------------------------
				xx_location_and_log(g_loc,
									'***** Executing XX_NON_POE_SETTLEMENT from XX_STG_RECEIPT_FOR_SETTLEMENT ***** ');
				xx_non_poe_settlement;
			END IF;
		END;

--------------------------------------------------------------------------
-- STEP #7 - Validate 101 and 201 Records Creation
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'Validate 101 and 201 Records Creation ');

		BEGIN
			IF xx_validate_101_201_creation
			THEN
				IF (gc_remit_processing_type <> g_poe_int_store_cust)
				THEN
					-- Set Receipt Reference for Automatic Remittance Call
					x_receipt_ref := gc_ixreceiptnumber;
				END IF;

				x_ret_code := 0;   -- SUCCESS
				x_error_buf := NULL;
			ELSE
				x_ret_code := 2;   -- ERROR
				x_error_buf :=
					   '101 or 201 Records could not be created.  Location: '
					|| gc_error_loc
					|| '. ERROR DEBUG: '
					|| gc_error_debug;
			END IF;
		END;
	EXCEPTION
		WHEN ex_debug_setting
		THEN
			x_ret_code := 1;   -- WARNING
			x_error_buf :=
				   'EX_DEBUG_SETTING exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_invalid_sale_type
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_INVALID_SALE_TYPE exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_no_cm
		THEN
			x_ret_code := 2;   --updated per defect 13149
			x_error_buf :=    'There is no CREDIT MEMO Applied for the Receipt : '
						   || gc_receipt_number;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                'Receipt Remittance',
										   p_program_name =>                'CCREFUND CALL',
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf   --updated per defect 13149
																					   ,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'iPayment Refund call',
										   p_object_id =>                   gc_receipt_number);
		WHEN ex_cc_encrytpt
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_CC_ENCRYTPT exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_cc_decrytpt
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_CC_DECRYTPT exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			fnd_file.put_line(fnd_file.LOG,	'EX_CC_DECRYTPT exception raised for order payment id ' || gn_order_payment_id);
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_pre2
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=    'EX_PRE2 raised at ERROR LOCATION: '
						   || gc_error_loc
						   || '. ERROR DEBUG: '
						   || gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_mandatory_fields
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_MANDATORY_FIELDS exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_corrupt_intstore
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_CORRUPT_INTSTORE exception exception raised.  Refresh of xx_ar_intstorecust_otc required. '
				|| 'ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_101_201_creation_error
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_101_201_CREATION_ERROR exception exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_no_order_info
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_NO_ORDER_INFO exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_no_deposit_info
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_NO_DEPOSIT_INFO exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_too_many_deposits
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_TOO_MANY_DEPOSITS exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug
				|| '.  Too many deposits for NON-POS (single pmt multi-order). ';
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_cm_null
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_CM_NULL exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| 'No Credit Memo has been set in the DFF of the Receipt Application Information'
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_too_many_orders
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_TOO_MANY_ORDERS exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf   --updated per defect 13149
																					   ,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_too_many_invoices
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_TOO_MANY_INVOICES exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf   --updated per defect 13149
																					   ,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_too_many_receipts
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_TOO_MANY_RECEIPTS exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf   --updated per defect 13149
																					   ,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN ex_no_receipt_info
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'EX_NO_RECEIPT_INFO exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| '. ERROR DEBUG: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               x_error_buf   --updated per defect 13149
																					   ,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
		WHEN OTHERS
		THEN
			x_ret_code := 2;   -- ERROR
			x_error_buf :=
				   'WHEN OTHERS ERROR encountered in XX_IBY_SETTLEMENT_PKG.XX_STG_RECEIPT_FOR_SETTLEMENT at: '
				|| gc_error_loc
				|| '. Error Message: '
				|| SQLERRM
				|| '. Error Debug: '
				|| gc_error_debug
				|| 'Remit Processing Type: '
				|| gc_remit_processing_type;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
	END xx_stg_receipt_for_settlement;

-- +====================================================================+
-- | PROCEDURE  : XX_STG_RECEIPT_FOR_SETTLEMENT (Overloaded - Public)   |
-- |                                                                    |
-- | DESCRIPTION: To populate the XX_IBY_BATCH_TRXNS 101, 201 tables    |
-- |              for calls from HVOP                                   |
-- |                                                                    |
-- | PARAMETERS : p_order_payment_id                                    |
-- |                                                                    |
-- | RETURNS    : x_settlement_staged                                   |
-- |              x_error_message                                       |
-- +====================================================================+
	PROCEDURE xx_stg_receipt_for_settlement(
		p_order_payment_id   IN      VARCHAR2,
		x_settlement_staged  OUT     BOOLEAN,
		x_error_message      OUT     VARCHAR2)
	IS
		ln_ret_code                    NUMBER;
		lc_error_message               VARCHAR2(4000);
		lc_receipt_ref                 xx_iby_batch_trxns.ixreceiptnumber%TYPE;
		lc_remitted_flag               xx_ar_order_receipt_dtl.remitted%TYPE;
		lc_customer_receipt_reference  xx_ar_order_receipt_dtl.customer_receipt_reference%TYPE;
		lc_payment_number              xx_ar_order_receipt_dtl.payment_number%TYPE;
		ln_rec_count                   NUMBER;
		ex_receipt_duplicate           EXCEPTION;
	BEGIN
		gn_request_id := fnd_global.conc_request_id;
		gn_user_id := fnd_global.user_id;
		gc_error_loc := 'Calling XX_CHECK_DEBUG_SETTINGS from XX_STG_RECEIPT_FOR_SETTLEMENT (Public). ';

		IF NOT xx_check_debug_settings
		THEN
			RAISE ex_debug_setting;
		END IF;

		xx_location_and_log(g_log,
							'*********************************** START ***********************************');
		xx_location_and_log(g_log,
							   'Current Time             : '
							|| SYSDATE);
		xx_location_and_log(g_log,
							' ');
		xx_location_and_log(g_log,
							   'Request ID               : '
							|| gn_request_id);
		xx_location_and_log(g_log,
							   'Order Payment ID         : '
							|| p_order_payment_id);
		xx_location_and_log(g_loc,
							'Validate Order Payment ID is not NULL in XX_STG_RECEIPT_FOR_SETTLEMENT. ');
		DBMS_OUTPUT.put_line(p_order_payment_id);

		IF p_order_payment_id IS NULL
		THEN
			x_error_message := 'p_order_payment_id is NULL.  A value is required.';
			x_settlement_staged := FALSE;
		ELSE
------------------------------------------
-- Retrieve/Validate remit status for receipt
------------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieving REMITTED flag. ');

				SELECT NVL(remitted,
						   'N'),
					   customer_receipt_reference,
					   payment_number
				INTO   lc_remitted_flag,
					   lc_customer_receipt_reference,
					   lc_payment_number
				FROM   xx_ar_order_receipt_dtl
				WHERE  order_payment_id = p_order_payment_id;

				xx_location_and_log(g_loc,
									'Validate REMITTED flag. ');
				xx_location_and_log(g_log,
									   'Order Payment ID         : '
									|| p_order_payment_id);

				IF lc_remitted_flag IN('Y', 'S')
				THEN
					xx_location_and_log(g_loc,
										'Raising EX_RECEIPT_REMITTED Exception from XX_STG_RECEIPT_FOR_SETTLEMENT. ');
					RAISE ex_receipt_remitted;
				END IF;
			END;

			xx_location_and_log(g_log,
								   'Remitted Flag            : '
								|| lc_remitted_flag);
			xx_location_and_log(g_log,
								   'Customer Receipt Ref.    : '
								|| lc_customer_receipt_reference);
			xx_location_and_log(g_log,
								   'Payment Number           : '
								|| lc_payment_number);

------------------------------------------
-- Checking if duplicate receipt exists
------------------------------------------
			BEGIN
				xx_location_and_log(g_loc,
									'Retrieve count of receipts. ');

				SELECT COUNT(1)
				INTO   ln_rec_count
				FROM   xx_ar_order_receipt_dtl
				WHERE  customer_receipt_reference = lc_customer_receipt_reference
				AND    payment_number = lc_payment_number;

				xx_location_and_log(g_log,
									   'Receipts in Detail Table : '
									|| ln_rec_count);
			EXCEPTION
				WHEN OTHERS
				THEN
					xx_location_and_log(g_loc,
										   'Error checking if duplicate receipt exist for '
										|| 'payment order '
										|| p_order_payment_id);
					fnd_file.put_line(fnd_file.LOG,
										 'Error checking if duplicate receipt exist '
									  || 'in XX_STG_RECEIPT_FOR_SETTLEMENT '
									  || SQLERRM);
					RAISE ex_receipt_remitted;
			END;

------------------------------------------
-- Validate receipt count
------------------------------------------
			xx_location_and_log(g_loc,
								'Calling XX_STG_RECEIPT_FOR_SETTLEMENT (Private) for Order Payment ID Only. ');
			xx_location_and_log(g_log,
								   'Order Payment ID         : '
								|| p_order_payment_id);

			IF ln_rec_count = 1
			THEN
				xx_stg_receipt_for_settlement(x_error_buf =>             lc_error_message,
											  x_ret_code =>              ln_ret_code,
											  x_receipt_ref =>           lc_receipt_ref,
											  p_cash_receipt_id =>       NULL,
											  p_receipt_amount =>        NULL,
											  p_oapfstoreid =>           NULL,
											  p_oapforder_id =>          NULL,
											  p_order_payment_id =>      p_order_payment_id);
			ELSIF ln_rec_count = 0
			THEN
				fnd_file.put_line(fnd_file.LOG,
									 'No customer receipt found for p_order_payment_id :'
								  || p_order_payment_id);
				lc_error_message :=    'No customer receipt found for p_order_payment_id :'
									|| p_order_payment_id;
			ELSE
				RAISE ex_receipt_duplicate;
			END IF;

------------------------------------------
-- Verify if settlement record was staged
------------------------------------------
			xx_location_and_log(g_loc,
								   'Checking if settlement was successfully staged for Order Payment ID: '
								|| p_order_payment_id);

			IF (    NVL(ln_ret_code,
						0) = 0
				AND lc_error_message IS NULL)
			THEN
				x_settlement_staged := TRUE;
			ELSE
				x_error_message :=
						lc_error_message
					 || '. Settlement records could not be staged. '
					 || 'Return Code: '
					 || ln_ret_code;
				x_settlement_staged := FALSE;
			END IF;

			xx_location_and_log(g_log,
								' ');
			xx_location_and_log(g_log,
								   'Current Time             : '
								|| SYSDATE);
			xx_location_and_log(g_log,
								'***********************************  END  ***********************************');
		END IF;
	EXCEPTION
		WHEN ex_receipt_duplicate
		THEN
			xx_location_and_log(g_loc,
								'Entering EX_RECEIPT_DUPLICATE exception in XX_STG_RECEIPT_FOR_SETTLEMENT. ');
			x_settlement_staged := FALSE;
			x_error_message :=    'Duplicate receipt found for order_payment_id: '
							   || p_order_payment_id;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_message);
		WHEN ex_receipt_remitted
		THEN
			-- We are not calling XX_SET_REMITTED_TO_ERROR here since receipt is already showing as remitted.
			xx_location_and_log(g_loc,
								'Entering EX_RECEIPT_REMITTED exception in XX_STG_RECEIPT_FOR_SETTLEMENT. ');
			x_settlement_staged := FALSE;
			x_error_message :=    'Receipt was already remitted for order_payment_id: '
							   || p_order_payment_id;
		WHEN ex_debug_setting
		THEN
			gc_error_loc := 'Entering EX_DEBUG_SETTING exception in XX_STG_RECEIPT_FOR_SETTLEMENT. ';
			x_settlement_staged := FALSE;
			x_error_message :=    'Debug was not properly enabled for order_payment_id: '
							   || p_order_payment_id;
		WHEN OTHERS
		THEN
			xx_location_and_log(g_loc,
								'Entering WHEN OTHERS exception in XX_STG_RECEIPT_FOR_SETTLEMENT. ');
			x_settlement_staged := FALSE;
			x_error_message :=
				   'WHEN OTHERS ERROR encountered in XX_STG_RECEIPT_FOR_SETTLEMENT (internal store cust) at: '
				|| gc_error_loc
				|| '. Error Message: '
				|| SQLERRM
				|| '. Error Debug: '
				|| gc_error_debug
				|| 'Remit Processing Type: '
				|| gc_remit_processing_type;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_message);
			fnd_file.put_line(fnd_file.LOG,
								 gc_error_loc
							  || x_error_message);
	END xx_stg_receipt_for_settlement;

-- +====================================================================+
-- | PROCEDURE  :XX_INSERT_IREC_RECEIPT                                 |
-- |                                                                    |
-- | DESCRIPTION: This procedure will be called to insert iReceivable   |
-- |              Receipt record information from AR_CASH_RECEIPTS to   |
-- |              XX_AR_ORDER_RECEIPT_DTL table.  The procedure will be |
-- |              called only by the PRE_CAPTURE_CCRETUNRN procedure    |
-- |                                                                    |
-- | PARAMETERS : p_cash_receipt_id                                     |
-- |                                                                    |
-- | RETURNS    : BOOLEAN (returns true if created else returns false)  |
-- +====================================================================+
	PROCEDURE xx_insert_irec_receipt(
		p_cash_receipt_id  IN  NUMBER)
	IS
		lc_method_name                 xx_fin_translatevalues.source_value1%TYPE;
		ln_rec_count                   NUMBER;
		ln_payment_server_order_num    ar_cash_receipts_all.payment_server_order_num%TYPE;
		ln_cash_receipt_id             ar_cash_receipts_all.cash_receipt_id%TYPE;
		lc_approval_code               iby_trxn_core.authcode%TYPE;
		ld_receipt_date                ar_cash_receipts_all.receipt_date%TYPE;
		lc_instrsubtype                iby_trxn_summaries_all.instrsubtype%TYPE;
		ld_instr_expirydate            iby_trxn_core.instr_expirydate%TYPE;
		lc_party_name                  hz_parties.party_name%TYPE;
		ln_instrnumber                 iby_trxn_summaries_all.instrnumber%TYPE;
		ln_cust_account_id             hz_cust_accounts.cust_account_id%TYPE;
		lc_customer_receipt_reference  ar_cash_receipts_all.customer_receipt_reference%TYPE;
		ln_amount                      ar_cash_receipts_all.amount%TYPE;
		ln_receipt_method_id           ar_cash_receipts_all.receipt_method_id%TYPE;
		ln_receipt_number              ar_cash_receipts_all.receipt_number%TYPE;
		lc_status                      ar_cash_receipts_all.status%TYPE;
		ln_org_id                      ar_cash_receipts_all.org_id%TYPE;
		lc_currency_code               ar_cash_receipts_all.currency_code%TYPE;
		lc_receipt_type                ar_cash_receipts_all.TYPE%TYPE;   -- Added for defect 12840
		xx_unable_insert_irec_recp     EXCEPTION;
		lc_identifier                  iby_creditcard.attribute5%TYPE;
		lc_token_number                iby_creditcard.attribute6%TYPE;   --Version 26.4
		lc_token_flag                  iby_creditcard.attribute7%TYPE;   --Version 26.4
	BEGIN
		-- Defect 12840 - Modified query to select receipt TYPE
		xx_location_and_log(g_loc,
							'Retrieiving information for inserting IREC receipt. ');

		SELECT ifte.payment_system_order_number payment_server_order_num,
			   acra.cash_receipt_id,
			   itc.authcode approval_code,
			   TRUNC(acra.receipt_date),
			   NVL (itsa.instrsubtype,  ic.card_issuer_code), --Added NVL condition in version 26.9
			   ic.expirydate instr_expirydate,
			   hp.party_name,
			   ic.attribute4 credit_card_number_enc,
			   ic.attribute5 IDENTIFIER,
			   ic.attribute6 token_number,  --Version 26.4
			   ic.attribute7 token_flag,    --Version 26.4
			   hca.cust_account_id,
			   acra.customer_receipt_reference,
			   acra.amount,
			   acra.receipt_method_id,
			   acra.receipt_number,
			   acra.org_id,
			   acra.currency_code,
			   acra.TYPE
		INTO   ln_payment_server_order_num,
			   ln_cash_receipt_id,
			   lc_approval_code,
			   ld_receipt_date,
			   lc_instrsubtype,
			   ld_instr_expirydate,
			   lc_party_name,
			   ln_instrnumber,            --Credit_card_number (attribute4)
			   lc_identifier,             --identifier (attribute5)
			   lc_token_number,           --attribute6
			   lc_token_flag,             --attribute7
			   ln_cust_account_id,
			   lc_customer_receipt_reference,
			   ln_amount,
			   ln_receipt_method_id,
			   ln_receipt_number,
			   ln_org_id,
			   lc_currency_code,
			   lc_receipt_type
		FROM   iby_fndcpt_tx_extensions ifte,
			   iby_fndcpt_tx_operations ifto,
			   iby_trxn_summaries_all itsa,
			   iby_trxn_core itc,
			   iby_creditcard ic,
			   ar_cash_receipts_all acra,
			   hz_cust_accounts hca,
			   hz_parties hp
		WHERE  acra.cash_receipt_id = p_cash_receipt_id
		AND    ifte.trxn_extension_id = acra.payment_trxn_extension_id
		AND    ifte.trxn_extension_id = ifto.trxn_extension_id
		AND    ifto.transactionid = itsa.transactionid
		AND    itsa.payerinstrid = ic.instrid
		AND    acra.pay_from_customer = hca.cust_account_id
		AND    hca.party_id = hp.party_id
		AND    itsa.trxnmid = itc.trxnmid(+)
		AND    itsa.status = 0;

		-- Defect 12840 - Modified insert statement to decode receipt type varible
		xx_location_and_log(g_loc,
							'Inserting IREC receipt information into XX_AR_ORDER_RECEIPT_DTL. ');

		INSERT INTO xx_ar_order_receipt_dtl
					(additional_auth_codes,
					 allied_ind,
					 cash_receipt_id,
					 cc_auth_manual,
					 cc_auth_ps2000,
					 cc_mask_number,
					 check_number,
					 created_by,
					 creation_date,
					 credit_card_approval_code,
					 credit_card_approval_date,
					 credit_card_code,
					 credit_card_expiration_date,
					 credit_card_holder_name,
					 credit_card_number,
					 customer_id,
					 customer_receipt_reference,
					 customer_site_billto_id,
					 header_id,
					 imp_file_name,
					 last_update_date,
					 last_updated_by,
					 MATCHED,
					 merchant_number,
					 od_payment_type,
					 order_number,
					 order_payment_id,
					 order_source,
					 order_type,
					 org_id,
					 orig_sys_document_ref,
					 orig_sys_payment_ref,
					 currency_code,
					 payment_amount,
					 payment_number,
					 payment_set_id,
					 payment_type_code,
					 process_code,
					 process_date,
					 receipt_date,
					 receipt_method_id,
					 receipt_number,
					 receipt_status,
					 remitted,
					 request_id,
					 sale_type,
					 ship_from,
					 store_number,
					 single_pay_ind,
					 IDENTIFIER,
					 token_flag,     --Version 26.3
					 emv_card,       --Version 26.3
					 emv_terminal,   --Version 26.3
					 emv_transaction,--Version 26.3
					 emv_offline,    --Version 26.3
					 emv_fallback,   --Version 26.3
					 emv_tvr)        --Version 26.3
		VALUES      (ln_payment_server_order_num,
					 NULL,
					 ln_cash_receipt_id,
					 NULL,
					 NULL,
					 NULL,
					 NULL,
					 gn_user_id,   --CREATED_BY
					 SYSDATE,      --CREATION_DATE
					 lc_approval_code,
					 ld_receipt_date,
					 lc_instrsubtype,
					 ld_instr_expirydate,
					 lc_party_name,
					-- ln_instrnumber, --Commented Version 26.3
					 DECODE ( lc_token_flag, 'Y', lc_token_number, ln_instrnumber), --Version 26.3, 26.4
					 ln_cust_account_id,
					 lc_customer_receipt_reference,
					 NULL,
					 NULL,
					 NULL,
					 SYSDATE,      --LAST_UPDATE_DATE
					 gn_user_id,   --LAST_UPDATED_BY
					 'N',
					 NULL,
					 NULL,
					 NULL,
					 xx_ar_order_payment_id_s.NEXTVAL,
					 NULL,
					 NULL,
					 ln_org_id,
					 NULL,
					 NULL,
					 lc_currency_code,
					 ln_amount,
					 NULL,
					 NULL,
					 'CREDIT_CARD'
								  --DECODE(gc_remit_processing_type,'IREC','CREDIT_CARD',NULL)     --if ( original receipt is IRec) else NULL.
		,
					 'REMIT-IREC',
					 ld_receipt_date,
					 ld_receipt_date,
					 ln_receipt_method_id,
					 ln_receipt_number,
					 'OPEN',
					 'N',
					 gn_request_id,
					 DECODE(lc_receipt_type,
							'MISC', g_refund,
							g_sale),
					 NULL,
					 g_irec_store_number,
					 'N',
					 lc_identifier,
					 lc_token_flag,             --Version 26.3
					 'N',    --emv_card         --Version 26.3
					 NULL,   --emv_terminal     --Version 27.0
					 'N',    --emv_transaction  --Version 26.3
					 'N',    --emv_offline      --Version 26.3
					 'N',    --emv_fallback     --Version 26.3
					 NULL    --emv_tvr          --Version 27.0
					 );

		ln_rec_count := SQL%ROWCOUNT;

		IF ln_rec_count = 1
		THEN
			COMMIT;
		ELSE
			ROLLBACK;
			RAISE xx_unable_insert_irec_recp;
		END IF;
	EXCEPTION
		WHEN xx_unable_insert_irec_recp
		THEN
			xx_location_and_log(g_loc,
								'Entering XX_UNABLE_INSERT_IREC_RECP exception of XX_INSERT_IREC_RECEIPT. ');
			gc_error_debug :=    'Unable to insert IREC into XX_AR_ORDER_RECEIPT_DTL for receipt id: '
							  || p_cash_receipt_id;
		WHEN OTHERS
		THEN
			xx_location_and_log(g_loc,
								'Entering WHEN OTHERS exception of XX_INSERT_IREC_RECEIPT. ');
			gc_error_debug :=    'Unable to insert IREC into XX_AR_ORDER_RECEIPT_DTL for receipt id: '
							  || p_cash_receipt_id;
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
			fnd_file.put_line(fnd_file.LOG,
								 'Error Msg XX_INSERT_IREC_RECEIPT  '
							  || 'Procedure: '
							  || SQLERRM);
	END xx_insert_irec_receipt;

-- +====================================================================+
-- | PROCEDURE  : XX_INSERT_MISC_RECEIPT                                |
-- |                                                                    |
-- | DESCRIPTION: This procedure will be called to insert iReceivable   |
-- |              Receipt record information from AR_CASH_RECEIPTS to   |
-- |              XX_AR_ORDER_RECEIPT_DTL table.  The procedure will be |
-- |              called only by the PRE_CAPTURE_CCRETUNRN procedure    |
-- |                                                                    |
-- | PARAMETERS : p_cash_receipt_id                                     |
-- |                                                                    |
-- | RETURNS    :                                                       |
-- +====================================================================+
	PROCEDURE xx_insert_misc_receipt(
		p_cash_receipt_id  IN  NUMBER)
	IS
		lc_method_name                 xx_fin_translatevalues.source_value1%TYPE;
		ln_rec_count                   NUMBER;
		ln_payment_server_order_num    ar_cash_receipts_all.payment_server_order_num%TYPE;
		ln_cash_receipt_id             ar_cash_receipts_all.cash_receipt_id%TYPE;
		lc_approval_code               iby_trxn_core.authcode%TYPE;
		ld_receipt_date                ar_cash_receipts_all.receipt_date%TYPE;
		lc_instrsubtype                iby_trxn_summaries_all.instrsubtype%TYPE;
		ld_instr_expirydate            iby_trxn_core.instr_expirydate%TYPE;
		lc_party_name                  hz_parties.party_name%TYPE;
		ln_instrnumber                 iby_trxn_summaries_all.instrnumber%TYPE;
		ln_cust_account_id             hz_cust_accounts.cust_account_id%TYPE;
		lc_customer_receipt_reference  ar_cash_receipts_all.customer_receipt_reference%TYPE;
		ln_amount                      ar_cash_receipts_all.amount%TYPE;
		ln_receipt_method_id           ar_cash_receipts_all.receipt_method_id%TYPE;
		ln_receipt_number              ar_cash_receipts_all.receipt_number%TYPE;
		lc_status                      ar_cash_receipts_all.status%TYPE;
		ln_org_id                      ar_cash_receipts_all.org_id%TYPE;
		lc_currency_code               ar_cash_receipts_all.currency_code%TYPE;
		lc_storenumber                 xx_ar_order_receipt_dtl.store_number%TYPE;
		lc_identifier                  iby_creditcard.attribute5%TYPE;
		lc_token_number                iby_creditcard.attribute6%TYPE;   --Version 27.0
		lc_token_flag                  iby_creditcard.attribute7%TYPE;   --Version 27.0
		xx_unable_insert_misc_recp     EXCEPTION;
	BEGIN
		-- Defect 12840 - added decode for checking attribute1
		xx_location_and_log(g_loc,
							'Retrieiving information for inserting MISC type receipt. ');

		SELECT acra.payment_server_order_num,
			   acra.cash_receipt_id,
			   itc.authcode approval_code,
			   TRUNC(acra.receipt_date),
			   NVL (itsa.instrsubtype, ic.card_issuer_code), --Added NVL condition in version 27.0
			   ic.expirydate,
			   hp.party_name,
			   ic.attribute4 instrnumber,
			   ic.attribute5 IDENTIFIER,
			   ic.attribute6 token_number,  --Version 27.0
			   ic.attribute7 token_flag,    --Version 27.0
			   hca.cust_account_id,
			   acra.customer_receipt_reference,
			   acra.amount,
			   acra.receipt_method_id,
			   acra.receipt_number,
			   acra.org_id,
			   acra.currency_code,
			   DECODE(acra.attribute1,
					  NULL, acra.attribute2,
					  acra.attribute1)
		INTO   ln_payment_server_order_num,
			   ln_cash_receipt_id,
			   lc_approval_code,
			   ld_receipt_date,
			   lc_instrsubtype,
			   ld_instr_expirydate,
			   lc_party_name,
			   ln_instrnumber,            --Credit_card_number (attribute4)
			   lc_identifier,             --identifier (attribute5)
			   lc_token_number,           --attribute6 --Version 27.0
			   lc_token_flag,             --attribute7 --Version 27.0
			   ln_cust_account_id,
			   lc_customer_receipt_reference,
			   ln_amount,
			   ln_receipt_method_id,
			   ln_receipt_number,
			   ln_org_id,
			   lc_currency_code,
			   lc_storenumber
		FROM   iby_fndcpt_tx_extensions ifte,
			   iby_fndcpt_tx_operations ifto,
			   iby_trxn_summaries_all itsa,
			   iby_trxn_core itc,
			   iby_creditcard ic,
			   ar_cash_receipts_all acra,
			   hz_cust_accounts hca,
			   hz_parties hp
		WHERE  acra.cash_receipt_id = p_cash_receipt_id
		AND    ifte.trxn_extension_id = acra.payment_trxn_extension_id
		AND    ifte.trxn_extension_id = ifto.trxn_extension_id
		AND    ifto.transactionid = itsa.transactionid
		AND    itsa.payerinstrid = ic.instrid
		AND    acra.pay_from_customer = hca.cust_account_id
		AND    hca.party_id = hp.party_id
		AND    itsa.reqtype = 'ORAPMTREQ'
		AND    itsa.trxnmid = itc.trxnmid(+)
		AND    itsa.status = 0;

		xx_location_and_log(g_loc,
							'Inserting MISC receipt information into XX_AR_ORDER_RECEIPT_DTL. ');

		INSERT INTO xx_ar_order_receipt_dtl
					(additional_auth_codes,
					 allied_ind,
					 cash_receipt_id,
					 cc_auth_manual,
					 cc_auth_ps2000,
					 cc_mask_number,
					 check_number,
					 created_by,
					 creation_date,
					 credit_card_approval_code,
					 credit_card_approval_date,
					 credit_card_code,
					 credit_card_expiration_date,
					 credit_card_holder_name,
					 credit_card_number,
					 customer_id,
					 customer_receipt_reference,
					 customer_site_billto_id,
					 header_id,
					 imp_file_name,
					 last_update_date,
					 last_updated_by,
					 MATCHED,
					 merchant_number,
					 od_payment_type,
					 order_number,
					 order_payment_id,
					 order_source,
					 order_type,
					 org_id,
					 orig_sys_document_ref,
					 orig_sys_payment_ref,
					 currency_code,
					 payment_amount,
					 payment_number,
					 payment_set_id,
					 payment_type_code,
					 process_code,
					 process_date,
					 receipt_date,
					 receipt_method_id,
					 receipt_number,
					 receipt_status,
					 remitted,
					 request_id,
					 sale_type,
					 ship_from,
					 store_number,
					 single_pay_ind,
					 IDENTIFIER,
					 token_flag,     --Version 27.0
					 emv_card,       --Version 27.0
					 emv_terminal,   --Version 27.0
					 emv_transaction,--Version 27.0
					 emv_offline,    --Version 27.0
					 emv_fallback,   --Version 27.0
					 emv_tvr)        --Version 27.0
		VALUES      (NULL,
					 NULL,
					 ln_cash_receipt_id,
					 NULL,
					 NULL,
					 NULL,
					 NULL,
					 gn_user_id   --CREATED_BY
							   ,
					 SYSDATE   --CREATION_DATE
							,
					 lc_approval_code,
					 ld_receipt_date,
					 lc_instrsubtype,
					 ld_instr_expirydate,
					 lc_party_name,
					-- ln_instrnumber, --Commented Version 27.0
					 DECODE ( lc_token_flag, 'Y', lc_token_number, ln_instrnumber), --Version 27.0
					 ln_cust_account_id,
					 lc_customer_receipt_reference,
					 NULL,
					 NULL,
					 NULL,
					 SYSDATE   --LAST_UPDATE_DATE
							,
					 gn_user_id   --LAST_UPDATED_BY
							   ,
					 'N',
					 NULL,
					 NULL,
					 NULL,
					 xx_ar_order_payment_id_s.NEXTVAL,
					 NULL,
					 NULL,
					 ln_org_id,
					 NULL,
					 NULL,
					 lc_currency_code,
					 ln_amount,
					 NULL,
					 NULL,
					 'CREDIT_CARD',
					 'REMIT-MISC',
					 ld_receipt_date,
					 ld_receipt_date,
					 ln_receipt_method_id,
					 ln_receipt_number,
					 'OPEN',
					 'N',
					 gn_request_id,
					 g_refund,
					 NULL,
					 lc_storenumber,
					 'N',
					 lc_identifier,
					 lc_token_flag,             --Version 27.0
					 'N',    --emv_card         --Version 27.0
					 NULL,   --emv_terminal     --Version 27.0
					 'N',    --emv_transaction  --Version 27.0
					 'N',    --emv_offline      --Version 27.0
					 'N',    --emv_fallback     --Version 27.0
					 NULL    --emv_tvr          --Version 27.0
					 );

		ln_rec_count := SQL%ROWCOUNT;

		IF ln_rec_count = 1
		THEN
			COMMIT;
		ELSE
			ROLLBACK;
			RAISE xx_unable_insert_misc_recp;
		END IF;
	EXCEPTION
		WHEN xx_unable_insert_misc_recp
		THEN
			xx_location_and_log(g_loc,
								'Entering XX_UNABLE_INSERT_IREC_RECP exception of XX_INSERT_MISC_RECEIPT. ');
			gc_error_debug :=    'Unable to insert MISC into XX_AR_ORDER_RECEIPT_DTL for receipt id: '
							  || p_cash_receipt_id;
		WHEN OTHERS
		THEN
			xx_location_and_log(g_loc,
								'Entering WHEN OTHERS exception of XX_INSERT_MISC_RECEIPT. ');
			gc_error_debug :=    'Unable to insert MISC into XX_AR_ORDER_RECEIPT_DTL for receipt id: '
							  || p_cash_receipt_id;
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              SUBSTR(gc_error_loc,
																				   1,
																				   60),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 gc_object_type,
										   p_object_id =>                   gc_object_id);
			ROLLBACK;   --  added per defect 13149
			fnd_file.put_line(fnd_file.LOG,
								 'Error Msg XX_INSERT_MISC_RECEIPT  '
							  || 'Procedure: '
							  || SQLERRM);
	END xx_insert_misc_receipt;

-- +====================================================================+
-- | PROCEDURE  : PRE_CAPTURE_CCRETUNRN                                 |
-- |                                                                    |
-- | DESCRIPTION: To populate the XX_IBY_BATCH_TRXNS 101, 201 tables    |
-- |              for calls from Automatic Remittance                   |
-- |                                                                    |
-- | PARAMETERS : p_oapf_action       -                                 |
-- |              p_oapf_currency     -                                 |
-- |              p_oapf_amount       -                                 |
-- |              p_receipt_currency  -                                 |
-- |              p_oapfStoreId       -                                 |
-- |              p_oapfTransactionId -                                 |
-- |              p_oapf_trxn_ref     -                                 |
-- |              p_oapf_order_id     -                                 |
-- |                                                                    |
-- | RETURNS    : x_error_buff        -                                 |
-- |              x_ret_code          -                                 |
-- |              x_receipt_ref       -                                 |
-- +====================================================================+
	PROCEDURE pre_capture_ccretunrn(
		x_error_buf          OUT     VARCHAR2,
		x_ret_code           OUT     NUMBER,
		x_receipt_ref        OUT     VARCHAR2,
		p_oapfaction         IN      VARCHAR2,
		p_oapfcurrency       IN      VARCHAR2 DEFAULT NULL,
		p_oapfamount         IN      VARCHAR2 DEFAULT NULL,
		p_oapfstoreid        IN      VARCHAR2 DEFAULT NULL,
		p_oapftransactionid  IN      VARCHAR2 DEFAULT NULL,
		p_oapftrxn_ref       IN      VARCHAR2 DEFAULT NULL,
		p_oapforder_id       IN      VARCHAR2 DEFAULT NULL)
	IS
		lc_error_message     VARCHAR2(4000);
		lc_receipt_ref       xx_iby_batch_trxns.ixreceiptnumber%TYPE;
		ln_cash_receipt_id   ar_cash_receipts_all.cash_receipt_id%TYPE;
		ln_order_payment_id  xx_ar_order_receipt_dtl.order_payment_id%TYPE;
		ex_no_ord_pmt_id     EXCEPTION;
	BEGIN
		gc_error_loc := 'Capture Request ID. ';
		gn_request_id := fnd_global.conc_request_id;
		gn_user_id := fnd_global.user_id;
		gc_error_loc := 'Calling XX_CHECK_DEBUG_SETTINGS from XX_STG_RECEIPT_FOR_SETTLEMENT (Public). ';

		IF NOT xx_check_debug_settings
		THEN
			RAISE ex_debug_setting;
		END IF;

		xx_location_and_log(g_loc,
							   'Retrieving Cash Receipt ID based on OAPFACTION. '
							|| ' '
							|| p_oapfaction);
		gc_error_debug :=    'OAPFACTION: '
						  || p_oapfaction;
		xx_location_and_log(g_loc,
							   'Input Parameter values : '
							|| ' p_oapfamount  :'
							|| p_oapfamount
							|| ' p_oapfstoreid :'
							|| p_oapfstoreid
							|| ' p_oapftransactionid :'
							|| p_oapftransactionid
							|| ' p_oapftrxn_ref :'
							|| p_oapftrxn_ref
							|| ' p_oapforder_id :'
							|| p_oapforder_id
							|| ' p_oapfaction :'
							|| p_oapfaction);

		IF (UPPER(p_oapfaction) = 'ORACAPTURE')
		THEN
			xx_location_and_log(g_loc,
								   'OAPFACTION = ORACAPTURE  and Oapforder ID = '
								|| p_oapforder_id);
			gc_error_debug :=    'Oapforder ID: '
							  || p_oapforder_id;

			BEGIN
				SELECT DISTINCT acra.cash_receipt_id
				INTO            ln_cash_receipt_id
				FROM            iby_fndcpt_tx_extensions ifte,
								iby_fndcpt_tx_operations ifto,
								iby_trxn_summaries_all itsa,
								ar_cash_receipts_all acra
				WHERE           ifto.transactionid = p_oapftransactionid
				AND             ifte.payment_system_order_number = p_oapforder_id
				AND             ifte.trxn_extension_id = acra.payment_trxn_extension_id
				AND             ifte.trxn_extension_id = ifto.trxn_extension_id
				AND             ifto.transactionid = itsa.transactionid
				AND             itsa.reqtype = 'ORAPMTCAPTURE';
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					xx_location_and_log(g_loc,
										'Retrieving Cash Receipt ID for ORACAPTURE based on p_oapftrxn_ref. ');
					gc_error_debug :=    'Oapftrxn Ref: '
									  || p_oapftrxn_ref;

					SELECT DISTINCT acra.cash_receipt_id
					INTO            ln_cash_receipt_id
					FROM            iby_fndcpt_tx_extensions ifte,
									iby_fndcpt_tx_operations ifto,
									iby_trxn_summaries_all itsa,
									ar_cash_receipts_all acra
					WHERE           ifto.transactionid = p_oapftransactionid
					AND             ifte.trxn_extension_id = acra.payment_trxn_extension_id
					AND             ifte.trxn_extension_id = ifto.trxn_extension_id
					AND             ifto.transactionid = itsa.transactionid
					AND             itsa.reqtype = 'ORAPMTCAPTURE';
			END;
		ELSIF(UPPER(p_oapfaction) = 'ORARETURN')
		THEN
			xx_location_and_log(g_loc,
								'OAPFACTION = ORARETURN. Retrieving Cash Receipt ID baesd on p_oapftrxn_ref. ');
			gc_error_debug :=    'Unique Reference: '
							  || p_oapftrxn_ref;

			-- made changes below query for defect 27580
			IF p_oapftrxn_ref IS NOT NULL
			THEN
				SELECT DISTINCT acr.cash_receipt_id
				INTO            ln_cash_receipt_id
				FROM            ar_cash_receipts_all acr
				WHERE           acr.unique_reference = p_oapftrxn_ref;
			ELSE
				SELECT DISTINCT acra.cash_receipt_id
				INTO            ln_cash_receipt_id
				FROM            iby_fndcpt_tx_extensions ifte,
								iby_fndcpt_tx_operations ifto,
								iby_trxn_summaries_all itsa,
								ar_cash_receipts_all acra
				WHERE           ifto.transactionid = p_oapftransactionid   --'164942362'
				AND             ifte.trxn_extension_id = acra.payment_trxn_extension_id
				AND             ifte.trxn_extension_id = ifto.trxn_extension_id
				-- AND   itsa.trxnmid              = p_oapforder_id  ---316836527
				AND             ifto.transactionid = itsa.transactionid
				AND             itsa.reqtype = 'ORAPMTRETURN'
				AND             acra.TYPE = 'MISC';
			END IF;   -- p_oapftrxn_ref
		END IF;

		xx_location_and_log(g_loc,
							   'Cash Receipt id '
							|| ln_cash_receipt_id);
		xx_location_and_log(g_loc,
							'***** Executing XX_RETRIEVE_ORDER_PMT_ID from PRE_CAPTURE_CCRETUNRN ***** ');
		xx_retrieve_order_pmt_id(p_cash_receipt_id =>       ln_cash_receipt_id,
								 x_order_payment_id =>      ln_order_payment_id,
								 x_error_message =>         lc_error_message);

		IF (    ln_order_payment_id IS NULL
			AND lc_error_message IS NULL)
		THEN
			IF xx_is_irec_receipt(ln_cash_receipt_id) = TRUE
			THEN
				xx_location_and_log(g_loc,
									'***** Executing XX_INSERT_IREC_RECEIPT from PRE_CAPTURE_CCRETUNRN ***** ');
				xx_insert_irec_receipt(ln_cash_receipt_id);
				xx_location_and_log(g_loc,
									'***** Executing XX_RETRIEVE_ORDER_PMT_ID from PRE_CAPTURE_CCRETUNRN (IREC) ***** ');
				xx_retrieve_order_pmt_id(p_cash_receipt_id =>       ln_cash_receipt_id,
										 x_order_payment_id =>      ln_order_payment_id,
										 x_error_message =>         lc_error_message);

				IF (ln_order_payment_id IS NULL)
				THEN
					RAISE ex_no_ord_pmt_id;
				END IF;
			ELSIF xx_is_misc_receipt(ln_cash_receipt_id) = TRUE
			THEN
				xx_location_and_log(g_loc,
									'***** Executing XX_INSERT_MISC_RECEIPT from PRE_CAPTURE_CCRETUNRN ***** ');
				xx_insert_misc_receipt(ln_cash_receipt_id);   -- to insert record XX_AR_ORDER_RECEIPT_DTL table.
				xx_location_and_log(g_loc,
									'***** Executing XX_RETRIEVE_ORDER_PMT_ID from PRE_CAPTURE_CCRETUNRN (MISC) ***** ');
				xx_retrieve_order_pmt_id(p_cash_receipt_id =>       ln_cash_receipt_id,
										 x_order_payment_id =>      ln_order_payment_id,
										 x_error_message =>         lc_error_message);

				IF (ln_order_payment_id IS NULL)
				THEN
					RAISE ex_no_ord_pmt_id;
				END IF;
			ELSE
				RAISE ex_no_ord_pmt_id;
			END IF;
		END IF;

		xx_location_and_log(g_log,
							'*********************************** START ***********************************');
		xx_location_and_log(g_log,
							   'START TIME               : '
							|| SYSDATE);
		xx_location_and_log(g_log,
							' ');
		xx_location_and_log(g_log,
							   'gn_request_id            : '
							|| gn_request_id);
		xx_location_and_log(g_log,
							   'p_oapfaction             : '
							|| UPPER(p_oapfaction) );
		xx_location_and_log(g_log,
							   'p_cash_receipt_id        : '
							|| ln_cash_receipt_id);
		xx_location_and_log(g_log,
							   'p_oapfstoreid            : '
							|| p_oapfstoreid);
		xx_location_and_log(g_log,
							   'p_oapforder_id           : '
							|| p_oapforder_id);
		xx_location_and_log(g_log,
							   'p_oapftrxn_ref           : '
							|| p_oapftrxn_ref);
		xx_location_and_log(g_log,
							   'Order Payment ID         : '
							|| ln_order_payment_id);
		xx_location_and_log(g_loc,
							'***** Executing XX_STG_RECEIPT_FOR_SETTLEMENT (Private) from PRE_CAPTURE_CCRETUNRN ***** ');
		xx_stg_receipt_for_settlement(x_error_buf =>             x_error_buf,
									  x_ret_code =>              x_ret_code,
									  x_receipt_ref =>           x_receipt_ref,
									  p_cash_receipt_id =>       ln_cash_receipt_id,
									  p_receipt_amount =>        p_oapfamount,
									  p_oapfstoreid =>           p_oapfstoreid,
									  p_oapforder_id =>          p_oapforder_id,
									  p_order_payment_id =>      ln_order_payment_id);

		IF (UPPER(p_oapfaction) = 'ORACAPTURE')
		THEN
			x_receipt_ref := NULL;   -- This is not returned for a SALE.  Only applies to REFUNDS.
		END IF;

		xx_location_and_log(g_log,
							' ');
		xx_location_and_log(g_log,
							   'END TIME                 : '
							|| SYSDATE);
		xx_location_and_log(g_log,
							'***********************************  END  ***********************************');
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			x_ret_code := 2;   --updated per Defect 13149
			x_error_buf :=
				   'NO_DATA_FOUND exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| ' ERROR MESSAGE: '
				|| lc_error_message;
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>                  'Error at: '
																			|| gc_error_loc
																			|| '. Debug: '
																			|| gc_error_debug
																			|| ' - '
																			|| SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'p_oapftrxn_ref',
										   p_object_id =>                   p_oapftrxn_ref);
		WHEN ex_receipt_remitted
		THEN
			x_ret_code := 2;   --updated per Defect 13149
			x_error_buf :=
				   'EX_RECEIPT_REMITTED exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| ' ERROR MESSAGE: '
				|| lc_error_message
				|| '. Receipt was already remitted or staged for Order Payment ID: '
				|| gn_order_payment_id;
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>                  'Error at: '
																			|| gc_error_loc
																			|| '. Debug: '
																			|| gc_error_debug
																			|| ' - '
																			|| SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'p_oapftrxn_ref',
										   p_object_id =>                   p_oapftrxn_ref);
		WHEN ex_no_ord_pmt_id
		THEN
			x_ret_code := 2;   --updated per Defect 13149
			x_error_buf :=
				   'EX_NO_ORD_PMT_ID exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| ' ERROR MESSAGE: '
				|| lc_error_message;
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>                  'Error at: '
																			|| gc_error_loc
																			|| '. Debug: '
																			|| gc_error_debug
																			|| ' - '
																			|| SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'p_oapftrxn_ref',
										   p_object_id =>                   p_oapftrxn_ref);
		WHEN ex_debug_setting
		THEN
			x_ret_code := 1;
			x_error_buf :=
				   'EX_DEBUG_SETTING exception raised at ERROR LOCATION: '
				|| gc_error_loc
				|| ' ERROR MESSAGE: '
				|| lc_error_message;
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>                  'Error at: '
																			|| gc_error_loc
																			|| '. Debug: '
																			|| gc_error_debug
																			|| ' - '
																			|| SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'p_oapftrxn_ref',
										   p_object_id =>                   p_oapftrxn_ref);
		WHEN OTHERS
		THEN
			x_ret_code := 2;   --updated per Defect 13149
			x_error_buf :=
				   'WHEN OTHERS ERROR encountered at XX_IBY_SETTLEMENT_PKG.PRE_CAPTURE_CCRETUNRN: '
				|| gc_error_loc
				|| '. Error Message: '
				|| SQLERRM
				|| '. Error Debug: '
				|| gc_error_debug;
			xx_com_error_log_pub.log_error(p_program_type =>                gc_program_type,
										   p_program_name =>                gc_program_name,
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>                  'Error at: '
																			|| gc_error_loc
																			|| '. Debug: '
																			|| gc_error_debug
																			|| ' - '
																			|| SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'p_oapftrxn_ref',
										   p_object_id =>                   p_oapftrxn_ref);
	END pre_capture_ccretunrn;

-- +====================================================================+
-- | PROCEDURE  : XX_IBY_BATCH_TRXNS_CCREFUND                           |
-- |                                                                    |
-- | DESCRIPTION: To populate the XX_IBY_BATCH_TRXNS 101, 201 tables    |
-- |              for calls from Close Batch for Credit Card Refunds    |
-- |              ($0.00 receipts)                                      |
-- |                                                                    |
-- | PARAMETERS :                                                       |
-- |                                                                    |
-- | RETURNS    :                                                       |
-- +====================================================================+
	PROCEDURE xx_iby_batch_trxns_ccrefund(
		x_ret_code   OUT  VARCHAR2,
		x_error_buf  OUT  VARCHAR2)
	IS
		ln_error_count         NUMBER         := 0;
		ln_staged_count        NUMBER         := 0;
		lc_error_message       VARCHAR2(4000);
		lb_receipt_stg_status  BOOLEAN;

		-- Defect 13318 - added hint to eliminate FTS
		CURSOR c_cc_refunds
		IS
			SELECT /*+ index(XAORD XX_AR_ORDER_RECEIPT_DTL_N3)*/
				   xaord.order_payment_id
			FROM   xx_ar_order_receipt_dtl xaord
			WHERE  xaord.remitted IN('N', 'E')
			AND    xaord.payment_type_code = 'CREDIT_CARD'
			AND    xaord.credit_card_code <> 'DEBIT CARD'
			AND    xaord.payment_amount = 0;
	BEGIN
--------------------------------------------------------------------------
-- Step #1 - Initialize Default Values for PRIVATE/Global Package Variables
--------------------------------------------------------------------------
		gc_error_loc := 'Calling XX_CHECK_DEBUG_SETTINGS from XX_STG_RECEIPT_FOR_SETTLEMENT (Public). ';

		IF NOT xx_check_debug_settings
		THEN
			RAISE ex_debug_setting;
		END IF;

		xx_location_and_log(g_loc,
							'Set default values for specific variables. ');
		gc_program_name := 'XX_IBY_BATCH_TRXNS_CCREFUND';
		gc_program_type := 'Settlement Staging for XX_IBY_BATCH_TRXNS_CCREFUND';
		x_ret_code := 0;
		x_error_buf := NULL;
		xx_location_and_log(g_log,
							'*********************************** CCREFUND START ***********************************');
		xx_location_and_log(g_log,
							   'START TIME               : '
							|| SYSDATE);
		xx_location_and_log(g_log,
							' ');
		xx_location_and_log(g_log,
							   'Program Name             : '
							|| gc_program_name);
		xx_location_and_log(g_log,
							   'Program Type             : '
							|| gc_program_type);
--------------------------------------------------------------------------
-- Step #2 - Identify Credit Card Refunds
--------------------------------------------------------------------------
		xx_location_and_log(g_loc,
							'Open lcu_cc_refunds cursor and begin looping. ');

		FOR lcu_cc_refunds IN c_cc_refunds
		LOOP
--------------------------------------------------------------------------
-- Step #3 - Stage Receipt for Settlement
--------------------------------------------------------------------------
			xx_location_and_log
					  (g_loc,
					   '***** Executing XX_STG_RECEIPT_FOR_SETTLEMENT (Public) from XX_IBY_BATCH_TRXNS_CCREFUND ***** ');
			xx_stg_receipt_for_settlement(p_order_payment_id =>       lcu_cc_refunds.order_payment_id,
										  x_settlement_staged =>      lb_receipt_stg_status,
										  x_error_message =>          lc_error_message);

			IF lb_receipt_stg_status
			THEN
				ln_staged_count :=   ln_staged_count
								   + 1;
			ELSE
				ln_error_count :=   ln_error_count
								  + 1;
				xx_location_and_log(g_log,
									   'Settlement Staging Error for order_payment_id '
									|| lcu_cc_refunds.order_payment_id
									|| ': '
									|| lc_error_message);
			END IF;
		END LOOP;

--------------------------------------------------------------------
-- Step #4 - Set Concurrent Program Status
--------------------------------------------------------------------
		IF ln_error_count > 0
		THEN
			fnd_file.put_line(fnd_file.LOG,
								 'Receipts Not Staged: '
							  || ln_error_count);
			-- To Send Warning even if one record is failed was gn_error
			x_ret_code := 1;
			x_error_buf :=    'Unable to stage '
						   || ln_error_count
						   || ' receipts for AJB settlement';
		ELSE
			fnd_file.put_line(fnd_file.LOG,
								 'Receipts Staged    : '
							  || ln_staged_count);
			x_ret_code := 0;
			x_error_buf := NULL;
		END IF;

		xx_location_and_log(g_log,
							' ');
		xx_location_and_log(g_log,
							   'END TIME                 : '
							|| SYSDATE);
		xx_location_and_log(g_log,
							'*********************************** CCREFUND END   ***********************************');
	EXCEPTION
		WHEN ex_debug_setting
		THEN
			gc_error_loc := 'Entering EX_DEBUG_SETTING exception in XX_IBY_BATCH_TRXNS_CCREFUND. ';
			x_ret_code := 1;
			x_error_buf := 'Debug was not properly enabled during XX_IBY_BATCH_TRXNS_CCREFUND. ';
			xx_com_error_log_pub.log_error(p_program_type =>                'Receipt Remittance',
										   p_program_name =>                'CCREFUND CALL',
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>                 'Error at '
																			|| SUBSTR(gc_error_loc,
																					  1,
																					  50),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'iPayment Refund call',
										   p_object_id =>                   '');
			fnd_file.put_line(fnd_file.LOG,
							  ' ');
			fnd_file.put_line(fnd_file.LOG,
							  x_error_buf);
		WHEN OTHERS
		THEN
			gc_error_loc := 'Entering WHEN OTHERS exception in XX_IBY_BATCH_TRXNS_CCREFUND. ';
			x_ret_code := 1;
			x_error_buf :=
				   'Error at XX_IBY_BATCH_TRXNS_CCREFUND : '
				|| gc_error_loc
				|| 'Error Message: '
				|| SQLERRM
				|| 'Error Debug: '
				|| gc_error_debug;
			xx_set_remitted_to_error(gn_order_payment_id,
									 x_error_buf);
			xx_com_error_log_pub.log_error(p_program_type =>                'Receipt Remittance',
										   p_program_name =>                'CCREFUND CALL',
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>                 'Error at '
																			|| SUBSTR(gc_error_loc,
																					  1,
																					  50),
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'iPayment Refund call',
										   p_object_id =>                   '');
			fnd_file.put_line(fnd_file.LOG,
							  ' ');
			fnd_file.put_line(fnd_file.LOG,
							  x_error_buf);
	END xx_iby_batch_trxns_ccrefund;

-- +====================================================================+
-- | PROCEDURE  : XX_AR_INVOICE_ODS                                     |
-- |                                                                    |
-- | DESCRIPTION: The Procedure is used in the I0349 Auth to pick up    |
-- |              Invoice that are sent to AJB.  The data is inserted   |
-- |              into the table by the pkg XX_AR_IREC_PAYMENTS.        |
-- |              INVOICE_TANGIBLEID                                    |
-- |                                                                    |
-- | PARAMETERS : p_oapforderid                                         |
-- |                                                                    |
-- | RETURNS    : x_trx_number                                          |
-- |              x_field_31                                            |
-- +====================================================================+
	PROCEDURE xx_ar_invoice_ods(
		p_oapforderid  IN      VARCHAR2,
		x_trx_number   OUT     VARCHAR2,
		x_field_31     OUT     VARCHAR2,
		x_token_flag   OUT     VARCHAR2)
	IS
	BEGIN
		BEGIN
		xx_location_and_log(g_loc,
							'Retrieving trx number from xx_ar_ipay_trxnumber. ');

		SELECT trx_number
		INTO   x_trx_number
		FROM   xx_ar_ipay_trxnumber
		WHERE  oapforderid = p_oapforderid;
		EXCEPTION -- Defect 35495
			WHEN OTHERS THEN
				 NULL;
		END;

		BEGIN

		xx_location_and_log(g_loc,
							'Retrieving field_31 from OD_IBY_AUTH_TRANSACTIONS translation definition. ');

		SELECT xftv.source_value1
		INTO   x_field_31
		FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
		WHERE  xftd.translate_id = xftv.translate_id
		AND    xftd.translation_name = 'OD_IBY_AUTH_TRANSACTIONS'
		AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																SYSDATE
															  + 1)
		AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																SYSDATE
															  + 1)
		AND    xftv.enabled_flag = 'Y'
		AND    xftd.enabled_flag = 'Y';

		EXCEPTION
		WHEN OTHERS THEN
			 NULL;
		END;

		SELECT icc.attribute7
		  INTO x_token_flag
		  FROM IBY_TRXN_SUMMARIES_ALL its,
			   IBY_CREDITCARD icc
		 WHERE its.tangibleid= p_oapforderid
		   AND its.payerinstrid = icc.instrid
		   AND its.reqtype = 'ORAPMTREQ';

	EXCEPTION
		WHEN OTHERS
		THEN
			NULL;   -- Need not have any exception message as AJB accepts without this also
					-- There will be no data found only if we pay multiple invoices.(FOR IREC)
	END xx_ar_invoice_ods;

-- +====================================================================+
-- | FUNCTION   : REPEAT_CHAR                                           |
-- |                                                                    |
-- | DESCRIPTION: Repeats a given character for the provided number of  |
-- |              times                                                 |
-- |                                                                    |
-- | PARAMETERS :                                                       |
-- |                                                                    |
-- | RETURNS    : VARCHAR2                                              |
-- +====================================================================+
	FUNCTION repeat_char(
		p_char  IN  VARCHAR2,
		p_num   IN  NUMBER)
		RETURN VARCHAR2
	AS
		lc_ret_var  VARCHAR2(1000) DEFAULT NULL;
	BEGIN
		FOR i IN 1 .. p_num
		LOOP
			lc_ret_var :=    lc_ret_var
						  || p_char;
		END LOOP;

		RETURN lc_ret_var;
	EXCEPTION
		WHEN OTHERS
		THEN
			fnd_file.put_line(fnd_file.LOG,
							  'Error in REPEAT_CHAR procedure.');
			fnd_file.put_line(fnd_file.LOG,
								 'Error is '
							  || SQLERRM
							  || ' and error code is '
							  || SQLCODE);
			RETURN NULL;
	END repeat_char;

-- +===========================================================================+
-- | Name : UPDATE_PROCESS_INDICATOR                                           |
-- | Description : To update the process indicator of the future dated records |
-- |                 XX_IBY_BATCH_TRXNS,                                       |
-- |                        XX_IBY_BATCH_TRXNS_DET                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns: x_error_buf, x_ret_code                                          |
-- +===========================================================================+
	PROCEDURE update_process_indicator(
		x_error_buf  OUT     VARCHAR2,
		x_ret_code   OUT     NUMBER,
		p_date       IN      DATE)
	IS
		lc_col_hdr_ast  VARCHAR2(150);
		lc_fut_flag     VARCHAR2(10)   := 'N';
		lc_error_loc    VARCHAR2(4000);
		lc_error_debug  VARCHAR2(4000);
		ln_update_101   NUMBER         := 0;
		lc_del_flag     VARCHAR2(1)    := 'N';

		CURSOR c_err_rcpt
		IS
			SELECT xbt.ixreceiptnumber,
				   acr.cash_receipt_id
			FROM   ar_cash_receipts_all acr, ar_cash_receipt_history acrh, xx_iby_batch_trxns xbt
			WHERE  acr.cash_receipt_id = acrh.cash_receipt_id
			AND    acr.receipt_number = xbt.ixrecptnumber
			AND    acr.cash_receipt_id = TO_NUMBER(xbt.attribute7)
			AND    acr.cc_error_flag = 'Y'
			AND    acrh.status = 'CONFIRMED'
			AND    acrh.current_record_flag = 'Y';

		CURSOR c_update_101
		IS
			SELECT xibt.ROWID,
				   xibt.ixdate,
				   xibt.ixreceiptnumber,
				   xibt.org_id,
				   xibt.ixamount,
				   xibt.ixrecptnumber
			FROM   xx_iby_batch_trxns xibt
			WHERE  process_indicator = 2;

		CURSOR c_update_201(
			p_ixreceiptnumber  VARCHAR2)
		IS
			SELECT xibtd.ROWID
			FROM   xx_iby_batch_trxns_det xibtd
			WHERE  xibtd.ixreceiptnumber = p_ixreceiptnumber;
	BEGIN
		fnd_file.put_line(fnd_file.LOG,
						  '***************************************************************************************');
		fnd_file.put_line(fnd_file.LOG,
						  'Deleted following Receipts from 101/201 History Table whose Receipt status is CONFIRMED');
		fnd_file.put_line(fnd_file.LOG,
						  '***************************************************************************************');

		FOR lc_err_rcpt IN c_err_rcpt
		LOOP
			DELETE FROM xx_iby_batch_trxns_det xbtd
			WHERE       xbtd.ixreceiptnumber = lc_err_rcpt.ixreceiptnumber;

			DELETE FROM xx_iby_batch_trxns xbt
			WHERE       xbt.ixreceiptnumber = lc_err_rcpt.ixreceiptnumber;

			fnd_file.put_line(fnd_file.LOG,
								 '     '
							  || lc_err_rcpt.ixreceiptnumber);

-------------------------------------------------
-- Added update statement below for defect 13074
-------------------------------------------------
			UPDATE xx_ar_order_receipt_dtl
			SET remitted = 'N'
			WHERE  cash_receipt_id = lc_err_rcpt.cash_receipt_id
			AND    remitted = 'S';

			COMMIT;
			lc_del_flag := 'Y';
		END LOOP;

		IF (lc_del_flag = 'N')
		THEN
			fnd_file.put_line(fnd_file.LOG,
							  'No Records to delete from 101/201 History table');
		END IF;

		fnd_file.put_line(fnd_file.LOG,
						  '***************************************************************************************');
		fnd_file.put_line(fnd_file.LOG,
							 'Date Parameter: '
						  || p_date);
		lc_col_hdr_ast := repeat_char('*',
									  120);
		fnd_file.put_line(fnd_file.LOG,
						  'Before Opening the cursor');
		fnd_file.put_line(fnd_file.output,
							 repeat_char('*',
										 48)
						  || 'Future Dated Transactions'
						  || repeat_char('*',
										 48) );
		fnd_file.put_line(fnd_file.output,
							 RPAD('Receipt Number',
								  g_rpad_len_30)
						  || RPAD('Receipt Amount',
								  g_rpad_len_30)
						  || RPAD('Receipt Date',
								  g_rpad_len_30)
						  || RPAD('Org Id',
								  g_rpad_len_30) );
		fnd_file.put_line(fnd_file.output,
						  lc_col_hdr_ast);
		lc_error_loc := 'Before Opening the cursor';
		lc_error_debug := NULL;

		FOR lc_update_101 IN c_update_101
		LOOP
			IF (TO_DATE(lc_update_101.ixdate,
						'MMDDYYYY') <= p_date)
			THEN
				UPDATE xx_iby_batch_trxns
				SET process_indicator = 1
				WHERE  ROWID = lc_update_101.ROWID;

				ln_update_101 :=   ln_update_101
								 + 1;

				FOR lc_update_201 IN c_update_201(lc_update_101.ixreceiptnumber)
				LOOP
					UPDATE xx_iby_batch_trxns_det
					SET process_indicator = 1
					WHERE  ROWID = lc_update_201.ROWID;
				END LOOP;
			ELSE
				lc_fut_flag := 'Y';
				fnd_file.put_line(fnd_file.output,
									 RPAD(lc_update_101.ixrecptnumber,
										  g_rpad_len_30)
								  || RPAD(lc_update_101.ixamount,
										  g_rpad_len_30)
								  || RPAD(TO_DATE(lc_update_101.ixdate,
												  'MMDDYYYY'),
										  g_rpad_len_30)
								  || RPAD(lc_update_101.org_id,
										  g_rpad_len_30) );
			END IF;
		END LOOP;

		IF (lc_fut_flag = 'N')
		THEN
			fnd_file.put_line(fnd_file.output,
								 repeat_char('-',
											 53)
							  || 'NO DATA FOUND'
							  || repeat_char('-',
											 53) );
		END IF;

		fnd_file.put_line(fnd_file.output,
						  lc_col_hdr_ast);
		fnd_file.put_line(fnd_file.LOG,
						  'After Closing the Cursor');
		fnd_file.put_line(fnd_file.LOG,
							 'No: of records updated in XX_IBY_BATCH_TRXNS: '
						  || ln_update_101);
	EXCEPTION
		WHEN OTHERS
		THEN
			fnd_file.put_line(fnd_file.LOG,
								 'Error Msg: '
							  || SQLERRM);
			xx_com_error_log_pub.log_error(p_program_type =>                'Update the Process indicator',
										   p_program_name =>                'Update the Process indicator',
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>                  'Error at : '
																			|| lc_error_loc
																			|| 'Debug : '
																			|| lc_error_debug
																			|| ' - '
																			|| SQLERRM,
										   p_error_message_severity =>      'Minor',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'Update the Process indicator',
										   p_object_id =>                   NULL);
			--x_ret_code := 1;  --For Defect# 35839
			x_ret_code := 2;  --For Defect# 35839, to error out the program
			x_error_buf :=
				   'Error at XX_IBY_SETTLEMENT_PKG.UPDATE_PROCESS_INDICATOR : '
				|| lc_error_loc
				|| 'Error Message: '
				|| SQLERRM
				|| 'Error Debug: '
				|| lc_error_debug;
	END update_process_indicator;

--START of Defect# 35839, to send email
-- +===================================================================+
-- | Name  :DUP_STLM_RECORDS_MAIL                                      |
-- | Description      : This procedure send email to business and	   |
-- |                   and AMS team if 101 and 201 tables have data	   |
-- |                   with ixipaymentbatchnumber populated			   |
-- | Added for the defect# 35839 by Rakesh Polepalli                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE DUP_STLM_RECORDS_MAIL
IS
	  l_mail_subject     VARCHAR2(2000);
	  l_mail_body        VARCHAR2(4000):=NULL;
	  l_mail_body1       VARCHAR2(4000):=NULL;
	  l_mail_header      VARCHAR2(1000);
	  l_debug_msg		 VARCHAR2(3000);
	  l_conc_id			 NUMBER;
	  l_no_of_groups_ids NUMBER;
	  lc_first_rec		 VARCHAR(1);
	  ln_cnt             NUMBER ;
	  slen                NUMBER  := 1;
	  v_addr              VARCHAR2 (1000);
	  lc_mail_host       VARCHAR2(100)  := fnd_profile.value('XX_COMN_SMTP_MAIL_SERVER');
	  lc_mail_conn       UTL_SMTP.connection;
	  lc_mail_from       VARCHAR2(100)  := 'noreply@officedepot.com';
	  lc_mail_recipient  VARCHAR2(500) := NULL  ;
	  crlf               VARCHAR2(10)   := CHR (13) || CHR (10);
	  lc_instance        VARCHAR2(100);
	  x_mail_sent_status VARCHAR2(1);
	  l_count_prgms 	 NUMBER;
	  l_rid				 Number(10) := 0;

cursor stuck_records
IS
select distinct ixipaymentbatchnumber, count(1) count
from xx_iby_batch_trxns
where ixipaymentbatchnumber is not null
group by ixipaymentbatchnumber;


	-----------------------------
	 --Define temp table of emails
	 -----------------------------
	 Type TYPE_TAB_EMAIL IS TABLE OF
			 XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX
			 BY BINARY_INTEGER ;

	 EMAIL_TBL TYPE_TAB_EMAIL;
BEGIN



				------------------------------------------
				-- Selecting emails from translation table
				------------------------------------------
			BEGIN
				SELECT xftv.target_value1
					  ,xftv.target_value2
					  ,xftv.target_value3
					  --,xftv.target_value4
					 -- ,xftv.target_value5
					  --,xftv.target_value6
					 -- ,xftv.target_value7
				INTO
					   EMAIL_TBL(1)
					  ,EMAIL_TBL(2)
					  ,EMAIL_TBL(3)
					 -- ,EMAIL_TBL(4)
					-- ,EMAIL_TBL(5)
					--  ,EMAIL_TBL(6)
					 -- ,EMAIL_TBL(7)
				FROM   xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
				WHERE  xftv.translate_id = xftd.translate_id
				AND    xftd.translation_name = 'FTP_DETAILS_AJB'
				AND    xftv.source_value1 = 'Dup_Issue'
				AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																		SYSDATE
																	+ 1)
				AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																		SYSDATE
																	+ 1)
				AND    xftv.enabled_flag = 'Y'
				AND    xftd.enabled_flag = 'Y';
			EXCEPTION
				WHEN NO_DATA_FOUND THEN

					FND_FILE.PUT_LINE(FND_FILE.LOG,'Emails are not being sent!!! '
												|| 'Mail needs to be setup in '
												|| 'Translation definition '
												|| ': FTP_DETAILS_AJB');

		   END;




	--SELECT NAME  INTO lc_instance FROM v$database;--Commented for v48.1
	select SUBSTR(sys_context('USERENV', 'DB_NAME'),1,8) into lc_instance  from dual;--Modified for v48.1

	--Modified for V42.0
	/*IF lc_instance = 'GSIPRDGB'
	THEN
	l_mail_subject := 'Email Alert: 101 or 201 tables already had data with ixipaymentbatchnumber populated - '||lc_instance;
	ELSE
	--l_count_prgms :=1;
	l_mail_subject :='Please Ignore this Email Alert: 101 or 201 tables already had data with ixipaymentbatchnumber populated - '||lc_instance;
	END IF;*/

	l_mail_subject := lc_instance||' - 101 or 201 tables already had data with ixipaymentbatchnumber populated';

FOR stk in stuck_records
LOOP
l_mail_header := '<TABLE border="1"><TR align="left"><TH><B>Payment Batch ID</B></TH><TH><B>Count</B></TH></TR>';
l_mail_body :=l_mail_body||'<TR><TD>'||stk.ixipaymentbatchnumber||'</TD><TD>'||stk.count||'</TD></TR>';
l_mail_body1 := l_mail_body1||rpad(stk.ixipaymentbatchnumber,50)||rpad(stk.count,32)||crlf;

END LOOP;

l_debug_msg := l_mail_subject|| crlf||crlf;

lc_mail_conn := UTL_SMTP.open_connection (lc_mail_host, 25);

UTL_SMTP.helo (lc_mail_conn, lc_mail_host);
UTL_SMTP.mail (lc_mail_conn, lc_mail_from);

		   ------------------------------------
		   --Building string of email addresses
		   ------------------------------------

		   lc_first_rec  := 'Y';

		   For ln_cnt in 1..3 Loop

				IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN

					IF lc_first_rec = 'Y' THEN

					   lc_mail_recipient :=  EMAIL_TBL(ln_cnt);
					   lc_first_rec := 'N';
					ELSE

					   lc_mail_recipient :=  lc_mail_recipient
										 ||' , ' || EMAIL_TBL(ln_cnt);
					END IF;
					UTL_SMTP.rcpt (lc_mail_conn, EMAIL_TBL(ln_cnt));

				END IF;

		   END LOOP;
		   FND_FILE.PUT_LINE(FND_FILE.LOG,'EMAIL_TBL(ln_cnt)::  '||lc_mail_recipient);

		l_rid := fnd_global.conc_request_id;

IF (lc_mail_recipient is not null)
THEN
UTL_SMTP.DATA
	 (lc_mail_conn,
		 'From:'
	  || lc_mail_from
	  || UTL_TCP.crlf
	  || 'To: '
	  || lc_mail_recipient
	  || UTL_TCP.crlf
	  || 'Subject: '
	  || l_mail_subject
	  || UTL_TCP.crlf||'MIME-Version: 1.0' || crlf || 'Content-type: text/html'
	  ||utl_tcp.CRLF
	  ||'<HTML><head><meta http-equiv="Content-Language" content="en-us" /><meta http-equiv="Content-Type" content="text/html; charset=windows-1252" /></head><BODY><BR>AMS Team,<BR><BR>'
	  || crlf
	  || crlf
	  || crlf
	  || 'The program OD: AR IBY Settlement Close Batch Program ('||l_rid||') failed as 101 or 201 tables already had data with ixipaymentbatchnumber populated or had duplicate data. Below are the Details:<BR><BR>'
	  || crlf
	  || crlf
	  ||l_mail_header
	  || l_mail_body
	  ||'</TABLE><BR>'
	  || crlf
	  || crlf
	  || '<BR>----------------------------------------------------------------------------------------------<BR>'
	  || crlf
	  || 'Clear the duplicate lines stuck in 101 and 201 tables -'||lc_instance
	  || crlf
	  || '<BR>----------------------------------------------------------------------------------------------<BR><BR><BR>'
	  || crlf||'</BODY></HTML>'
	 );

  UTL_SMTP.quit (lc_mail_conn);
  x_mail_sent_status := 'Y';
ELSE
  UTL_SMTP.quit (lc_mail_conn);
  x_mail_sent_status := 'N';
END IF;

IF x_mail_sent_status = 'Y'
THEN
	fnd_file.put_line (fnd_file.LOG,'Email Sent successfully');
ELSE
	fnd_file.put_line (fnd_file.LOG,'No email sent for duplicate data stuck in 101 and 201 tables'|| SQLERRM);
END IF;

EXCEPTION
  WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error
  THEN
	 raise_application_error (-20000, 'Unable to send mail: ' || SQLERRM);
  WHEN OTHERS
  THEN
	 fnd_file.put_line (fnd_file.LOG,'Unable to send mail..:'|| SQLERRM);
END DUP_STLM_RECORDS_MAIL;
--END of defect#35839 , to send mail


--START of Defect# 37763, to send ORDT alert email
-- +===================================================================+
-- | Name  			  : ORDT_RECORDS_MAIL                              |
-- | Description      : This procedure send email to business and	   |
-- |                   and AMS team with the details of records stuck  |
-- |				   in ORDT with New, Staged and Error Status       |
-- | Added for the defect# 37763 by Rakesh Polepalli                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE ORDT_RECORDS_MAIL
IS
	  l_mail_subject     VARCHAR2(2000);
	  l_mail_body        VARCHAR2(4000):=NULL;
	  --l_mail_body1       VARCHAR2(4000):=NULL;
	  l_mail_header      VARCHAR2(1000);
	  l_debug_msg		 VARCHAR2(3000);
	  l_no_of_groups_ids NUMBER;
	  lc_first_rec		 VARCHAR(1);
	  ln_cnt             NUMBER ;
	  lc_mail_host       VARCHAR2(100)  := fnd_profile.value('XX_COMN_SMTP_MAIL_SERVER');
	  lc_mail_conn       UTL_SMTP.connection;
	  lc_mail_from       VARCHAR2(100)  := 'noreply@officedepot.com';
	  lc_mail_recipient  VARCHAR2(500) := NULL  ;
	  crlf               VARCHAR2(10)   := CHR (13) || CHR (10);
	  lc_instance        VARCHAR2(100);
	  x_mail_sent_status VARCHAR2(1);


	  l_new_status		 VARCHAR2(20) := NULL;
	  l_stage_status	 VARCHAR2(20) := NULL;
	  l_error_status	 VARCHAR2(20) := NULL;
	  l_new_count		 VARCHAR2(20) := NULL;
	  l_stage_count 	 VARCHAR2(20) := NULL;
	  l_error_count 	 VARCHAR2(20) := NULL;
	  l_new_amount		 VARCHAR2(20) := NULL;
	  l_stage_amount	 VARCHAR2(20) := NULL;
	  l_error_amount	 VARCHAR2(20) := NULL;
	  l_date			 VARCHAR2(20) := to_char(sysdate-1, 'DD-MON-YY HH24:MI');		--Modified for the Defect#37866


	-----------------------------
	 --Define temp table of emails
	 -----------------------------
	 Type TYPE_TAB_EMAIL IS TABLE OF
			 XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX
			 BY BINARY_INTEGER ;

	 EMAIL_TBL TYPE_TAB_EMAIL;
BEGIN



				------------------------------------------
				-- Selecting emails from translation table
				------------------------------------------
			BEGIN
				SELECT xftv.target_value1
					  ,xftv.target_value2
					  ,xftv.target_value3

				INTO
					   EMAIL_TBL(1)
					  ,EMAIL_TBL(2)
					  ,EMAIL_TBL(3)

				FROM   xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
				WHERE  xftv.translate_id = xftd.translate_id
				AND    xftd.translation_name = 'FTP_DETAILS_AJB'
				AND    xftv.source_value1 = 'ORDT_Alert'
				AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																		SYSDATE
																	+ 1)
				AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																		SYSDATE
																	+ 1)
				AND    xftv.enabled_flag = 'Y'
				AND    xftd.enabled_flag = 'Y';
			EXCEPTION
				WHEN NO_DATA_FOUND THEN

					FND_FILE.PUT_LINE(FND_FILE.LOG,'Emails are not being sent!!! '
												|| 'Mail needs to be setup in '
												|| 'Translation definition '
												|| ': FTP_DETAILS_AJB');

		   END;




	--SELECT NAME INTO lc_instance FROM v$database;--Commented for v48.1
	select SUBSTR(sys_context('USERENV', 'DB_NAME'),1,8) into lc_instance  from dual;--Modified for v48.1

	--Modified for V42.0
	/*IF lc_instance = 'GSIPRDGB'
	THEN
	l_mail_subject := 'Remittance Status Alert as of cycle date '||l_date ||' - '||lc_instance;	--Modified for Defect# 37866
	ELSE
	l_mail_subject :='Please Ignore this Email Alert: Remittance Status Alert as of cycle date '||l_date ||' - '||lc_instance;
	END IF;*/

	l_mail_subject := lc_instance||' - Remittance Status Alert as of cycle date '||l_date;

SELECT   /*+ index(ORDT XX_AR_ORDER_RECEIPT_DTL_N3)*/
		'New', TO_CHAR(COUNT(1),'99,999,999') ,  TO_CHAR(NVL(SUM(ORDT.PAYMENT_AMOUNT),0),'$999,999,999,999.99')
into 	l_new_status, l_new_count, l_new_amount
FROM 	xx_ar_order_receipt_dtl ORDT
WHERE 	1=1
AND 	ORDT.remitted = 'N'
AND		ORDT.creation_date> sysdate-120;		--Modified for the Defect#37866

SELECT   /*+ index(ORDT XX_AR_ORDER_RECEIPT_DTL_N3)*/
		'Staged', TO_CHAR(COUNT(1),'99,999,999') ,  TO_CHAR(NVL(SUM(ORDT.PAYMENT_AMOUNT),0),'$999,999,999,999.99')
into 	l_stage_status, l_stage_count, l_stage_amount
FROM 	xx_ar_order_receipt_dtl ORDT
WHERE 	1=1
AND 	ORDT.remitted = 'S'
AND		ORDT.creation_date> sysdate-120;		--Modified for the Defect#37866


SELECT   /*+ index(ORDT XX_AR_ORDER_RECEIPT_DTL_N3)*/
		'Error', TO_CHAR(COUNT(1),'99,999,999') ,  TO_CHAR(NVL(SUM(ORDT.PAYMENT_AMOUNT),0),'$999,999,999,999.99')
into 	l_error_status, l_error_count, l_error_amount
FROM 	xx_ar_order_receipt_dtl ORDT
WHERE 	1=1
AND 	ORDT.remitted = 'E'
AND		ORDT.creation_date> sysdate-120;		--Modified for the Defect#37866


L_MAIL_HEADER := '<TABLE border="1" width = "250"><TR align="center"><TH height="20"><B>Status</B></TH><TH height="20"><B>Count</B></TH><TH height="20"><B>Amount</B></TH></TR>';
L_MAIL_BODY :=L_MAIL_BODY||'<TR><TD align="left" height="15">'||L_NEW_STATUS||'</TD><TD align="right" height="15">'||L_NEW_COUNT||'</TD><TD align="right" height="15">'||L_NEW_AMOUNT||'</TD></TR>';
L_MAIL_BODY :=L_MAIL_BODY||'<TR><TD align="left" height="15">'||L_STAGE_STATUS||'</TD><TD align="right" height="15">'||L_STAGE_COUNT||'</TD><TD align="right" height="15">'||L_STAGE_AMOUNT||'</TD></TR>';
l_mail_body :=l_mail_body||'<TR><TD align="left" height="15">'||l_error_status||'</TD><TD align="right" height="15">'||l_error_count||'</TD><TD align="right" height="15">'||l_error_amount||'</TD></TR>';


lc_mail_conn := UTL_SMTP.open_connection (lc_mail_host, 25);

UTL_SMTP.helo (lc_mail_conn, lc_mail_host);
UTL_SMTP.mail (lc_mail_conn, lc_mail_from);

		   ------------------------------------
		   --Building string of email addresses
		   ------------------------------------

		   lc_first_rec  := 'Y';

		   For ln_cnt in 1..3 Loop

				IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN

					IF lc_first_rec = 'Y' THEN

					   lc_mail_recipient :=  EMAIL_TBL(ln_cnt);
					   lc_first_rec := 'N';
					ELSE

					   lc_mail_recipient :=  lc_mail_recipient
										 ||' , ' || EMAIL_TBL(ln_cnt);
					END IF;
					UTL_SMTP.rcpt (lc_mail_conn, EMAIL_TBL(ln_cnt));

				END IF;

		   END LOOP;
		   FND_FILE.PUT_LINE(FND_FILE.LOG,'EMAIL recipients::  '||lc_mail_recipient);


IF (lc_mail_recipient is not null)
THEN
UTL_SMTP.DATA
	 (lc_mail_conn,
		 'From:'
	  || lc_mail_from
	  || UTL_TCP.crlf
	  || 'To: '
	  || lc_mail_recipient
	  || UTL_TCP.crlf
	  || 'Subject: '
	  || l_mail_subject
	  || UTL_TCP.crlf||'MIME-Version: 1.0' || crlf || 'Content-type: text/html'
	  ||utl_tcp.CRLF
	  ||'<HTML><head><meta http-equiv="Content-Language" content="en-us" /><meta http-equiv="Content-Type" content="text/html; charset=windows-1252" /></head><BODY><BR>Hi All,<BR><BR>'
	  || crlf
	  || crlf
	  || 'Settlement has been completed for the cycle date '||l_date|| '. <BR><BR>'
	  || crlf
	  || crlf
	  || 'Below is the count of records in ORDT that are yet to be processed: <BR><BR>'
	  || crlf
	  || crlf
	  ||l_mail_header
	  || l_mail_body
	  ||'</TABLE><BR>'
	  || crlf
	  || crlf
	  || crlf||'</BODY></HTML>'
	 );

  UTL_SMTP.quit (lc_mail_conn);
  x_mail_sent_status := 'Y';
ELSE
  UTL_SMTP.quit (lc_mail_conn);
  x_mail_sent_status := 'N';
END IF;

IF x_mail_sent_status = 'Y'
THEN
	fnd_file.put_line (fnd_file.LOG,'Email Sent successfully for ORDT alert');
ELSE
	fnd_file.put_line (fnd_file.LOG,'No email sent for ORDT alert'|| SQLERRM);
END IF;

EXCEPTION
  WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error
  THEN
	 raise_application_error (-20000, 'Unable to send mail for ORDT alert: ' || SQLERRM);
  WHEN OTHERS
  THEN
	 fnd_file.put_line (fnd_file.LOG,'Unable to send mail for ORDT alert..:'|| SQLERRM);
END ORDT_RECORDS_MAIL;
--END of defect#37763 , to send mail

-- +===================================================================+
-- | Name : CLBATCH                                                    |
-- | Description : To create the settlement file to send to AJB during |
-- |                 the Batch Close process.                          |
-- |                                                                   |
-- | Returns: x_error_buff, x_ret_code                                 |
-- +===================================================================+
	PROCEDURE clbatch(
		x_error_buff         OUT     VARCHAR2,
		x_ret_code           OUT     NUMBER,
		p_ajb_http_transfer  IN      VARCHAR2,
		p_printer_style      IN      VARCHAR2,
		p_printer_name       IN      VARCHAR2,
		p_number_copies      IN      NUMBER,
		p_save_output        IN      VARCHAR2,
		p_print_together     IN      VARCHAR2,
		p_validate_printer   IN      VARCHAR2)
	IS
		lf_out_file                    UTL_FILE.file_type;
		ln_chunk_size                  BINARY_INTEGER                                := 32767;
		lc_file_name                   VARCHAR2(240);
		lc_file_name_amex              VARCHAR2(240)                                 := NULL;
		lc_file_path_name_amex         VARCHAR2(4000)                                := NULL;
		lc_source_path_name            VARCHAR2(4000)                                := NULL;
		lc_file_amex_exists            VARCHAR2(1)                                   := 'N';
		lc_file_header                 VARCHAR2(4000);
		lc_file_trailer                VARCHAR2(4000);
		lc_file101_content1            VARCHAR2(4000);
		lc_file101_content2            VARCHAR2(4000);
		lc_file101_content3            VARCHAR2(4000);
		lc_file101_content4            VARCHAR2(4000);
		lc_file101_content5            VARCHAR2(4000);
		lc_file101_content6            VARCHAR2(4000);
		lc_file101_content7            VARCHAR2(4000);
		lc_file201_content1            VARCHAR2(4000);
		lc_file201_content2            VARCHAR2(4000);
		lc_file201_content3            VARCHAR2(4000);
		lc_file201_content4            VARCHAR2(4000);
		ln_count_101_rec               NUMBER                                        := 0;
		ln_count_201_rec               NUMBER                                        := 0;
		lc_name                        xx_ar_settlement.NAME%TYPE;
		ld_last_request_date           xx_ar_settlement.last_request_date%TYPE;
		ln_sequence_num                xx_ar_settlement.sequence_num%TYPE;
		ln_conc_request_id             fnd_concurrent_requests.request_id%TYPE;
		ln_conc_email_request_id       fnd_concurrent_requests.request_id%TYPE;
		lc_server_name                 xx_fin_translatevalues.target_value1%TYPE;
		lc_user_name                   xx_fin_translatevalues.target_value1%TYPE;
		lc_password                    xx_fin_translatevalues.target_value1%TYPE;
		lc_dest_path                   xx_fin_translatevalues.target_value1%TYPE;
		lc_source_path                 all_directories.directory_path%TYPE;
		lc_message_data                VARCHAR2(4000);
		lc_error_loc                   VARCHAR2(4000);
		lc_error_debug                 VARCHAR2(4000);
		lc_ixshiptocompany_format      VARCHAR2(242);
		lc_ixshiptoname_format         VARCHAR2(242);
		lc_ixshiptostreet_format       VARCHAR2(242);
		lc_ixshiptocity_format         VARCHAR2(242);
		lc_ixpurchasername_format      VARCHAR2(242);
		lc_ixproductcode_format        VARCHAR2(242);
		lc_ixskunumber_format          VARCHAR2(242);
		lc_ixitemdescription_format    VARCHAR2(242);
		lc_ixcustitemnum_format        VARCHAR2(242);
		lc_ixcustitemdesc_format       VARCHAR2(242);
		lc_ixcustreferenceid_format    VARCHAR2(242);
		lc_ixdesktoplocation_format    VARCHAR2(242);
		lc_ixbankuserdata_format       VARCHAR2(242);
		lc_ixshipfromzipcode_format    VARCHAR2(242);
		lc_ixshiptozipcode_format      VARCHAR2(242);
		lc_ixreleasenumber_format      VARCHAR2(242);
		lc_ixccnumber_format           VARCHAR2(242); --Defect 38215
		lc_ixcustcountrycode_format    VARCHAR2(2000);--Defect 38215
		--Version 26.3
		lc_ixtokenflag_format          VARCHAR2(242);
		--
		lc_comma_esc_char              xx_fin_translatevalues.target_value1%TYPE;
		lc_comma_esc_char_format       VARCHAR2(242);
		ex_batch_close_fail            EXCEPTION;
		lc_error_message               VARCHAR2(4000);
		lc_ret_code                    VARCHAR2(4000);
		ex_cc_encrytpt                 EXCEPTION;
		lc_hdr_flag                    VARCHAR2(1)                                   := 'N';
		lc_create_file_ajb             VARCHAR2(1)                                   := 'N';
		lc_amex_file_creation          xx_fin_translatevalues.target_value1%TYPE     := 'N';
		lc_file_creation_path          xx_fin_translatevalues.target_value1%TYPE;
		x_http_status_code             VARCHAR2(4000);
		x_http_reason                  VARCHAR2(4000);
		lc_email_address               xx_fin_translatevalues.target_value1%TYPE;
		lb_request_status              BOOLEAN;
		lc_phase                       VARCHAR2(1000);
		lc_status                      VARCHAR2(1000);
		lc_devphase                    VARCHAR2(1000);
		lc_devstatus                   VARCHAR2(1000);
		lc_message                     VARCHAR2(4000);
		lc_ajb_file_transfer           VARCHAR2(1)                                   := 'N';
		lc_cust_line_first_exec        VARCHAR2(1)                                   := 'Y';
		lc_cust_line_number            xx_iby_batch_trxns_det.ixcustpolinenum%TYPE;
		lc_cust_line_num_max           xx_iby_batch_trxns_det.ixcustpolinenum%TYPE;
		lc_email_body_text             VARCHAR2(1000)                                := NULL;
		lc_legacy_customer_number      hz_cust_accounts.orig_system_reference%TYPE;
		ln_leg_cust_number_sep         NUMBER;
		lc_new_line                    VARCHAR2(100);
		lc_amex_ship_to_name_trans     xx_fin_translatevalues.target_value1%TYPE;
		lc_ixinvoice_amex              VARCHAR2(100);
		lc_ixinvoice_amex_201          VARCHAR2(100);
		lc_ixsettlementdate            VARCHAR2(30);
		lb_save_output                 BOOLEAN;
		lb_print_option                BOOLEAN;
		ln_conc_stg_request_id         fnd_concurrent_requests.request_id%TYPE;
		ld_date                        DATE;
		ln_limit_value                 NUMBER;
		ln_conc_cc_extract_request_id  NUMBER;
		ln_conc_file_copy_request_id   NUMBER;
		ln_conc_bulk_ins_request_id    NUMBER;
		ln_conc_emailer_request_id     NUMBER;
		ln_conc_pkg_trans_request_id   NUMBER;
		lc_file_name_instance          VARCHAR2(30);
		lc_ixcostcenter_format         VARCHAR2(30);
		lc_ixinvoice_amex_sep_201      NUMBER;
		lc_ixinvoice_amex_sep          NUMBER;
		lc_country_code_amex           hr_operating_units.NAME%TYPE;
		lc_file101_content8            VARCHAR2(4000);
		lc_tid                         VARCHAR2(100);
		lc_pos_data                    VARCHAR2(100);
		lc_submitter_id                VARCHAR2(1000);
		lc_decrypt_error_msg           VARCHAR2(1000); -- Defect 31392
		x_credit_card_number_dec       VARCHAR2(30);   -- Defect 31392
		lc_credit_card_number          VARCHAR2(30);   -- Defect 31392
		lc_identifier                  VARCHAR2(30);   -- Defect 31392
		Duplicate_issue					EXCEPTION;     --Defect 35839
		Dup_count_101					NUMBER  := 0;  --Defect 35839
		Dup_count_201					NUMBER  := 0;  --Defect 35839
		ln_amex_except14               NUMBER;

					CURSOR c_trxn_101
		IS
			SELECT *
			FROM   xx_iby_batch_trxns a
			WHERE  a.process_indicator = 1;

		--Defect#38215 only AMEX CPC non tokenized transactions.
		CURSOR c_trxn_101_amex
		IS
			SELECT *
			FROM   xx_iby_batch_trxns
			WHERE  ixinstrsubtype = 'AMEX'
			AND    process_indicator = 1
			AND    NVL(ixtokenflag,'N') = 'N';

		CURSOR c_trxn_201(
			p_ixreceiptnumber  VARCHAR2)
		IS
			SELECT *
			FROM   (SELECT   *
					FROM     xx_iby_batch_trxns_det xibtd
					WHERE    xibtd.ixreceiptnumber = p_ixreceiptnumber
					ORDER BY TO_NUMBER(xibtd.ixrecseqnumber) );

		CURSOR c_trxn_201_amex(
			p_ixreceiptnumber  VARCHAR2)
		IS
			SELECT *
			FROM   (SELECT   *
					FROM     xx_iby_batch_trxns_det xibtd
					WHERE    xibtd.ixreceiptnumber = p_ixreceiptnumber
					ORDER BY TO_NUMBER(xibtd.ixinvoicelinenum) );
	BEGIN
		  -- For defect 31392
	  FOR c_rec in c_trxn_101 LOOP

		SELECT identifier, credit_card_number
		  INTO lc_identifier, lc_credit_card_number
		  FROM XX_AR_ORDER_RECEIPT_DTL
		 WHERE c_rec.order_payment_id = order_payment_id;

		IF lc_credit_card_number is not null THEN

		  DBMS_SESSION.set_context(
			NAMESPACE =>   'XX_IBY_CONTEXT',
			ATTRIBUTE =>   'TYPE',
				VALUE =>   'EBS');

		   xx_od_security_key_pkg.decrypt(x_decrypted_val =>      x_credit_card_number_dec,
										  x_error_message =>      lc_decrypt_error_msg,
										  p_module =>             'AJB',
										  p_key_label =>          lc_identifier,
										  p_algorithm =>          '3DES',
										  p_encrypted_val =>      lc_credit_card_number,
										  p_format =>             'BASE64');

		  IF lc_decrypt_error_msg IS NOT NULL THEN
			xx_location_and_log(g_loc, 'Error in xx_od_security_key_pkg.decrypt: '
								|| lc_decrypt_error_msg);
				  gc_error_loc   := 'decrypt_credit_card';
			gc_error_debug := lc_decrypt_error_msg;

			DELETE from xx_iby_batch_trxns
			 WHERE order_payment_id = c_rec.order_payment_id;

			DELETE from xx_iby_batch_trxns_det
			 WHERE order_payment_id = c_rec.order_payment_id;

			UPDATE XX_AR_ORDER_RECEIPT_DTL
			   SET remitted = 'E', settlement_error_message = 'Did not pass CC Decrypt: '
								|| lc_decrypt_error_msg
			WHERE order_payment_id = c_rec.order_payment_id;
		  ELSE
			 NULL; -- Debug Message
			 --UPDATE xx_iby_batch_trxns
			 --  SET attribute15 = 'MWS'
			 --WHERE order_payment_id = c_rec.order_payment_id;
		  END IF;
		END IF;
	  END LOOP;
	  --END Defect 31392

		ld_date := TO_DATE(SYSDATE,
						   'DD-MON-YYYY');
		/*  fnd_file.put_line(fnd_file.LOG,
							'Calling XX_IBY_BATCH_TRXNS_CCREFUND Procedure');
		  fnd_file.put_line(fnd_file.LOG,
							' ');
		  xx_iby_batch_trxns_ccrefund(lc_ret_code,
									  lc_error_message);
		  fnd_file.put_line(fnd_file.LOG,
							   'Ret Code Of XX_IBY_BATCH_TRXNS_CCREFUND : '
							|| lc_ret_code);
		  fnd_file.put_line(fnd_file.LOG,
							' ');

		  IF (lc_ret_code = 1)
		  THEN
			  x_ret_code := lc_ret_code;
		  END IF;*/
		fnd_file.put_line(fnd_file.LOG,
						  'Calling Future Ixdate Procedure');
		ln_conc_stg_request_id := fnd_request.submit_request('XXFIN',
															 'XX_IBY_UPD_PRO_IND',
															 '',
															 '',
															 FALSE,
															 ld_date);
		COMMIT;
		lb_request_status :=
			fnd_concurrent.wait_for_request(ln_conc_stg_request_id,
											'10',
											'',
											lc_phase,
											lc_status,
											lc_devphase,
											lc_devstatus,
											lc_message);

		IF (lc_devstatus = 'NORMAL')
		THEN
			fnd_file.put_line(fnd_file.LOG,
							  'UPDATE_PROCESS_INDICATOR Procedure Completed');
		ELSE
			--x_ret_code := 1;  --For Defect# 35839
			x_ret_code := 2; --for Defect# 35839, to error out the program
			x_error_buff := 'Failure in the UPDATE_PROCESS_INDICATOR Procedure';
			fnd_file.put_line(fnd_file.LOG,
							  x_error_buff);
		END IF;

		fnd_file.put_line(fnd_file.LOG,
						  'Generating Sequence Number for the Settlement file');
		-- Generating Sequence Number for the file name
		lc_error_loc := 'Generating Sequence Number for the Settlement file';
		lc_error_debug := 'Table : xx_ar_settlement';

		BEGIN
			SELECT last_request_date,
				   sequence_num
			INTO   ld_last_request_date,
				   ln_sequence_num
			FROM   xx_ar_settlement xas
			WHERE  xas.NAME = 'BTNAME';
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				ld_last_request_date := TRUNC(SYSDATE);
				ln_sequence_num := 0;

				INSERT INTO xx_ar_settlement
							(NAME,
							 last_request_date,
							 sequence_num)
				VALUES      ('BTNAME',
							 ld_last_request_date,
							 ln_sequence_num);
		END;

		IF (TRUNC(SYSDATE) = ld_last_request_date)
		THEN
			ln_sequence_num :=   ln_sequence_num
							   + 1;
		ELSE
			ln_sequence_num := 1;
			ld_last_request_date := TRUNC(SYSDATE);
		END IF;

		UPDATE xx_ar_settlement
		SET sequence_num = ln_sequence_num,
			last_request_date = ld_last_request_date
		WHERE  NAME = 'BTNAME';

		/*SELECT NAME
		INTO   lc_file_name_instance
		FROM   v$database;*/

		select SUBSTR(sys_context('USERENV', 'DB_NAME'),1,8) into lc_file_name_instance  from dual;--Modified for v48.1

		lc_file_name_instance := REPLACE(lc_file_name_instance,
										 'GSI',
										 '');
		lc_file_name :=    TO_CHAR(ld_last_request_date,
								   'YYYYMMDD')
						|| '-'
						|| TRIM(TO_CHAR(ln_sequence_num,
										'000') );
		lc_ixsettlementdate := TO_CHAR(ld_last_request_date,
									   'DD-MON-YYYY');   -- Defect 8403
		lc_error_loc := 'Getting the Translation Value for the AMEX file Creation';
		lc_error_debug := '';

		SELECT xftv.target_value1
		INTO   lc_amex_file_creation
		FROM   xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
		WHERE  xftv.translate_id = xftd.translate_id
		AND    xftd.translation_name = 'FTP_DETAILS_AJB'
		AND    xftv.source_value1 = 'AmexFileCreation'
		AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																SYSDATE
															  + 1)
		AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																SYSDATE
															  + 1)
		AND    xftv.enabled_flag = 'Y'
		AND    xftd.enabled_flag = 'Y';

		lc_error_loc := 'Getting the Translation Value for the AJB_SETTLEMENT_DBA_DIRECTORY';
		lc_error_debug := '';

		SELECT xftv.target_value1
		INTO   lc_file_creation_path
		FROM   xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
		WHERE  xftv.translate_id = xftd.translate_id
		AND    xftd.translation_name = 'FTP_DETAILS_AJB'
		AND    xftv.source_value1 = 'AJB_SETTLEMENT_DBA_DIRECTORY'
		AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																SYSDATE
															  + 1)
		AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																SYSDATE
															  + 1)
		AND    xftv.enabled_flag = 'Y'
		AND    xftd.enabled_flag = 'Y';

		-- Check if we need to create the Amex File
		IF (lc_amex_file_creation = 'Y')
		THEN
			lc_error_loc := 'Getting the Physical path of XXFIN_OUTBOUND, for the file writing';
			lc_error_debug := '';

			SELECT ad.directory_path
			INTO   lc_source_path_name
			FROM   all_directories ad
			WHERE  directory_name = lc_file_creation_path;

			lc_error_loc := 'Getting the Translation Value for the AMEX file name';
			lc_error_debug := '';

			SELECT    xftv.target_value1
				   || '-'
				   || TO_CHAR(SYSDATE,
							  'YYYYMMDDHHMISS')
			INTO   lc_file_name_amex
			FROM   xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
			WHERE  xftv.translate_id = xftd.translate_id
			AND    xftd.translation_name = 'FTP_DETAILS_AJB'
			AND    xftv.source_value1 = 'Amex File Name'
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';

			lc_error_loc := 'Getting the Translation Value for the AMEX file path';
			lc_error_debug := '';

			SELECT xftv.target_value1
			INTO   lc_file_path_name_amex
			FROM   xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
			WHERE  xftv.translate_id = xftd.translate_id
			AND    xftd.translation_name = 'FTP_DETAILS_AJB'
			AND    xftv.source_value1 = 'Amex File Path'
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';

			UPDATE xx_iby_batch_trxns
			SET attribute1 = lc_file_name_amex
			WHERE  ixinstrsubtype = 'AMEX';
		END IF;   -- check if we need to create the Amex File

		--START of Defect# 35839, to check the duplicate data in 101 and 201 tables
		BEGIN

		select count(1) into Dup_count_101
		from xx_iby_batch_trxns
		where ixipaymentbatchnumber is not null;

		select count(1) into Dup_count_201
		from xx_iby_batch_trxns_det
		where ixipaymentbatchnumber is not null;




		IF(Dup_count_101 > 0 or Dup_count_201 > 0)
		THEN
			lc_error_loc := '101 or 201 tables already had data with ixipaymentbatchnumber populated';
			--calling procedure to send mail
			DUP_STLM_RECORDS_MAIL;

			Raise Duplicate_issue;
		END IF;

		EXCEPTION
		WHEN OTHERS
		THEN
			fnd_file.put_line(fnd_file.LOG,lc_error_loc ||
								 '  Error Message: '
							  || SQLERRM);
			Raise Duplicate_issue;
		END;
		--END of the defect# 35839

		--Updating 101 with IXIPAYMENTBATCHNUMBER
		UPDATE xx_iby_batch_trxns
		SET ixipaymentbatchnumber = lc_file_name,
			ixsettlementdate = lc_ixsettlementdate
		WHERE  process_indicator = 1;

		--Updating 201 with IXIPAYMENTBATCHNUMBER
		UPDATE xx_iby_batch_trxns_det
		SET ixipaymentbatchnumber = lc_file_name,
			ixsettlementdate = lc_ixsettlementdate
		WHERE  process_indicator = 1;

		BEGIN
			lc_error_loc := 'Getting the Special Character to handle Commas in the .csv file format';
			lc_error_debug := '';

			SELECT xftv.target_value1
			INTO   lc_comma_esc_char
			FROM   xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
			WHERE  xftv.translate_id = xftd.translate_id
			AND    xftd.translation_name = 'OD_AJB_CLOSE_BATCH'
			AND    xftv.source_value1 = 'CommaESCChar'
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				lc_comma_esc_char := '"';
		END;

		lc_comma_esc_char_format :=    lc_comma_esc_char
									|| lc_comma_esc_char;
		fnd_file.put_line(fnd_file.LOG,
						  'Writing to the AJB Settlement File Before LOOP');

		SELECT CHR(10)
		INTO   lc_new_line
		FROM   DUAL;

		lc_error_loc := 'Getting the AMEX_SHITP_TO_NAME from the Translation AMEX_SETTLEMENT_FILE';
		lc_error_debug := '';

		SELECT xftv.target_value1
		INTO   lc_amex_ship_to_name_trans
		FROM   xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
		WHERE  xftv.translate_id = xftd.translate_id
		AND    xftd.translation_name = 'AMEX_SETTLEMENT_FILE'
		AND    xftv.source_value1 = 'AMEX_SHITP_TO_NAME'
		AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																SYSDATE
															  + 1)
		AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																SYSDATE
															  + 1)
		AND    xftv.enabled_flag = 'Y'
		AND    xftd.enabled_flag = 'Y';

		FOR lcu_trxn_101 IN c_trxn_101
		LOOP

			IF (lc_create_file_ajb = 'N')
			THEN
				lc_error_loc :=    'Writing to the File Name : '
								|| lc_file_name;
				lc_error_debug := ' DBA Directory Path : XXFIN_OUTBOUND';
				lf_out_file :=
					UTL_FILE.fopen(lc_file_creation_path,
									  lc_file_name_instance
								   || '-'
								   || lc_file_name
								   || '.set',
								   'w',
								   ln_chunk_size);
				lc_file_header :=    '101H,'
								  || lc_file_name
								  || ','
								  || TO_CHAR(ld_last_request_date,
											 'MMDDYYYY');
				UTL_FILE.put_line(lf_out_file,
								  lc_file_header);
			END IF;

			lc_create_file_ajb := 'Y';
			lc_ixshiptocompany_format := lcu_trxn_101.ixshiptocompany;
			lc_ixshiptoname_format := lcu_trxn_101.ixshiptoname;
			lc_ixshiptostreet_format := lcu_trxn_101.ixshiptostreet;
			lc_ixshiptocity_format := lcu_trxn_101.ixshiptocity;
			lc_ixpurchasername_format := lcu_trxn_101.ixpurchasername;
			lc_ixcustreferenceid_format := lcu_trxn_101.ixcustomerreferenceid;
			lc_ixdesktoplocation_format := lcu_trxn_101.ixdesktoplocation;
			lc_ixbankuserdata_format := lcu_trxn_101.ixbankuserdata;
			lc_ixshipfromzipcode_format := lcu_trxn_101.ixshipfromzipcode;
			lc_ixshiptozipcode_format := lcu_trxn_101.ixshiptozipcode;
			lc_ixreleasenumber_format := lcu_trxn_101.ixreleasenumber;
			lc_ixccnumber_format      := lcu_trxn_101.ixccnumber;          --Defect 38215
			lc_ixcustcountrycode_format := lcu_trxn_101.ixcustcountrycode; --Defect 38215


			IF    (INSTR(lcu_trxn_101.ixshiptocompany,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixshiptocompany,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixshiptocompany_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixshiptocompany,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			IF    (INSTR(lcu_trxn_101.ixshiptoname,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixshiptoname,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixshiptoname_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixshiptoname,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			IF    (INSTR(lcu_trxn_101.ixshiptostreet,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixshiptostreet,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixshiptostreet_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixshiptostreet,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			IF    (INSTR(lcu_trxn_101.ixshiptocity,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixshiptocity,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixshiptocity_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixshiptocity,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			IF    (INSTR(lcu_trxn_101.ixpurchasername,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixpurchasername,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixpurchasername_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixpurchasername,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			IF    (INSTR(lcu_trxn_101.ixcustomerreferenceid,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixcustomerreferenceid,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixcustreferenceid_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixcustomerreferenceid,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			IF    (INSTR(lcu_trxn_101.ixdesktoplocation,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixdesktoplocation,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixdesktoplocation_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixdesktoplocation,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			IF    (INSTR(lcu_trxn_101.ixbankuserdata,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixbankuserdata,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixbankuserdata_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixbankuserdata,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			IF    (INSTR(lcu_trxn_101.ixshipfromzipcode,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixshipfromzipcode,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixshipfromzipcode_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixshipfromzipcode,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			IF    (INSTR(lcu_trxn_101.ixshiptozipcode,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixshiptozipcode,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixshiptozipcode_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixshiptozipcode,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			IF    (INSTR(lcu_trxn_101.ixreleasenumber,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixreleasenumber,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixreleasenumber_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixreleasenumber,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			--START Defect#38215 - amex to vantiv conv
			IF    (INSTR(lcu_trxn_101.ixcustcountrycode,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixcustcountrycode,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixcustcountrycode_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixcustcountrycode,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;

			-- Defect 39040
			lc_ixcustcountrycode_format := REPLACE (lc_ixcustcountrycode_format,':');

			IF    (INSTR(lcu_trxn_101.ixccnumber,
						 ',') > 0)
			   OR (INSTR(lcu_trxn_101.ixccnumber,
						 lc_comma_esc_char) > 0)
			THEN
				lc_ixccnumber_format :=
					   lc_comma_esc_char
					|| REPLACE(lcu_trxn_101.ixccnumber,
							   lc_comma_esc_char,
							   lc_comma_esc_char_format)
					|| lc_comma_esc_char;
			END IF;
						--END Defect#38215 - amex to vantiv conv

			lc_file101_content1 :=
				   lcu_trxn_101.pre1
				|| lcu_trxn_101.pre2
				|| lcu_trxn_101.pre3
				|| lcu_trxn_101.ixrecordtype
				|| ','
				|| lcu_trxn_101.ixreserved2
				|| ','
				|| lcu_trxn_101.ixreserved3
				|| ','
				|| lcu_trxn_101.ixactioncode
				|| ','
				|| lcu_trxn_101.ixreserved5
				|| ','
				|| lcu_trxn_101.ixmessagetype
				|| ','
				|| lcu_trxn_101.ixreserved7
				|| ','
				|| lcu_trxn_101.ixstorenumber
				|| ','
				|| lcu_trxn_101.ixregisternumber
				|| ','
				|| lcu_trxn_101.ixtransactiontype
				|| ','
				|| lcu_trxn_101.ixreserved11
				|| ','
				|| lcu_trxn_101.ixreserved12;
			lc_file101_content2 :=
				   ','
				|| lcu_trxn_101.ixaccount
				|| ','
				|| lcu_trxn_101.ixexpdate
				|| ','
				|| lcu_trxn_101.ixswipe
				|| ','
				|| lcu_trxn_101.ixamount
				|| ','
				|| lcu_trxn_101.ixinvoice
				|| ','
				|| lcu_trxn_101.ixreserved18
				|| ','
				|| lcu_trxn_101.ixreserved19
				|| ','
				|| lcu_trxn_101.ixreserved20
				|| ','
				|| LTRIM(lcu_trxn_101.ixoptions)
				|| ','
				|| lc_ixbankuserdata_format
				|| ','
				|| lcu_trxn_101.ixreserved23
				|| ','
				|| lcu_trxn_101.ixreserved24
				|| ','
				|| lcu_trxn_101.ixissuenumber
				|| ','
				|| lcu_trxn_101.ixtotalsalestaxamount
				|| ','
				|| lcu_trxn_101.ixtotalsalestaxcollind;
			lc_file101_content3 :=
				   ','
				|| lcu_trxn_101.ixreserved28
				|| ','
				|| lcu_trxn_101.ixreserved29
				|| ','
				|| lcu_trxn_101.ixreserved30
				|| ','
				|| lcu_trxn_101.ixreserved31
				|| ','
				|| lcu_trxn_101.ixreserved32
				|| ','
				|| lcu_trxn_101.ixreserved33
				|| ','
				|| lcu_trxn_101.ixreceiptnumber
				|| ','
				|| lcu_trxn_101.ixreserved35
				|| ','
				|| lcu_trxn_101.ixreserved36
				|| ','
				|| lcu_trxn_101.ixauthorizationnumber
				|| ','
				|| lcu_trxn_101.ixreserved38
				|| ','
				|| lcu_trxn_101.ixreserved39
				|| ','
				|| lcu_trxn_101.ixreserved40
				|| ','
				|| lcu_trxn_101.ixreserved41
				|| ','
				|| lcu_trxn_101.ixreserved42;
			lc_file101_content4 :=
				   ','
				|| lcu_trxn_101.ixreserved43
				|| ','
				|| lcu_trxn_101.ixps2000
				|| ','
				|| lcu_trxn_101.ixreference
				|| ','
				|| lcu_trxn_101.ixreserved46
				|| ','
				|| lcu_trxn_101.ixipaymentbatchnumber
				|| ','
				|| lcu_trxn_101.ixreserved48
				|| ','
				|| lcu_trxn_101.ixreserved49
				|| ','
				|| lcu_trxn_101.ixdate
				|| ','
				|| lcu_trxn_101.ixtime
				|| ','
				|| lcu_trxn_101.ixreserved52
				|| ','
				|| lcu_trxn_101.ixreserved53
				|| ','
				|| lcu_trxn_101.ixreserved54
				|| ','
				|| lcu_trxn_101.ixreserved55
				|| ','
				|| lcu_trxn_101.ixreserved56
				|| ','
				|| lcu_trxn_101.ixreserved57;
			lc_file101_content5 :=
				   ','
				|| lcu_trxn_101.ixreserved58
				|| ','
				|| lcu_trxn_101.ixreserved59
				|| ','
				|| lc_ixcustreferenceid_format
				|| ','
				|| lcu_trxn_101.ixnationaltaxcollindicator
				|| ','
				|| lcu_trxn_101.ixnationaltaxamount
				|| ','
				|| lcu_trxn_101.ixothertaxamount
				|| ','
				|| lcu_trxn_101.ixdiscountamount
				|| ','
				|| lcu_trxn_101.ixshippingamount
				|| ','
				|| lcu_trxn_101.ixtaxableamount
				|| ','
				|| lcu_trxn_101.ixdutyamount
				|| ','
				|| lc_ixshipfromzipcode_format
				|| ','
				|| lc_ixshiptocompany_format
				|| ','
				|| REPLACE(lc_ixshiptoname_format,
						   lc_new_line,
						   ' ')
				|| ','
				|| REPLACE(lc_ixshiptostreet_format,
						   lc_new_line,
						   ' ')
				|| ','
				|| lc_ixshiptocity_format;
			lc_file101_content6 :=
				   ','
				|| lcu_trxn_101.ixshiptostate
				|| ','
				|| lcu_trxn_101.ixshiptocountry
				|| ','
				|| lc_ixshiptozipcode_format
				|| ','
				|| REPLACE(lc_ixpurchasername_format,
						   lc_new_line,
						   ' ')
				|| ','
				|| lcu_trxn_101.ixorderdate
				|| ','
				|| lcu_trxn_101.ixmerchantvatnumber
				|| ','
				|| lcu_trxn_101.ixcustomervatnumber
				|| ','
				|| lcu_trxn_101.ixvatinvoice
				|| ','
				|| lcu_trxn_101.ixvatamount
				|| ','
				|| lcu_trxn_101.ixvatrate
				|| ','
				|| lcu_trxn_101.ixmerchandiseshipped
				|| ','
				|| lc_ixcustcountrycode_format --Defect#38215
				|| ','
				|| lcu_trxn_101.ixcustaccountno
				|| ','
				|| lcu_trxn_101.ixcostcenter
				|| ','
				|| REPLACE(lc_ixdesktoplocation_format,
						   lc_new_line,
						   ' ');
			lc_file101_content7 :=
				   ','
				|| lc_ixreleasenumber_format
				|| ','
				-- Defect 39341 || lcu_trxn_101.ixoriginalinvoiceno
				|| ','
				|| lcu_trxn_101.ixothertaxamount2
				|| ','
				|| lcu_trxn_101.ixothertaxamount3
				|| ','
				|| lcu_trxn_101.ixmisccharge
				|| ','
				|| lcu_trxn_101.ixccnumber --Defect#38215
				|| ','
				|| lcu_trxn_101.attribute8;

			UTL_FILE.put(lf_out_file,
						 lc_file101_content1);
			UTL_FILE.put(lf_out_file,
						 lc_file101_content2);
			UTL_FILE.put(lf_out_file,
						 lc_file101_content3);
			UTL_FILE.put(lf_out_file,
						 lc_file101_content4);
			UTL_FILE.put(lf_out_file,
						 lc_file101_content5);
			UTL_FILE.put(lf_out_file,
						 lc_file101_content6);
			UTL_FILE.put_line(lf_out_file,
						 lc_file101_content7);
			ln_count_101_rec :=   ln_count_101_rec
								+ 1;

			FOR lcu_trxn_201 IN c_trxn_201(lcu_trxn_101.ixreceiptnumber)
			LOOP

				/*Start Defect#38215 skip sending record if amex cpc
				and customer(in except14 translation) and if unit price = 0.00*/
				IF lcu_trxn_101.ixinstrsubtype = 'AMEX' AND lcu_trxn_201.ixunitcost = 0
				THEN
				   ln_amex_except14 := 0;
				   SELECT COUNT(1)
					 INTO   ln_amex_except14
					 FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
					WHERE  xftd.translate_id = xftv.translate_id
					  AND    xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT'
					  AND    xftv.source_value1 = lcu_trxn_101.attribute6
					  AND    xftv.target_value1 = 'EXCEPT14'
					  AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE + 1)
					  AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE + 1)
					  AND    xftv.enabled_flag = 'Y'
					  AND    xftd.enabled_flag = 'Y';
				   fnd_file.put_line(fnd_file.LOG,'Amex Except14             : '|| to_char(ln_amex_except14));

				   CONTINUE WHEN ln_amex_except14 > 0;
				END IF;
				--End Defect#38215

				lc_ixproductcode_format := lcu_trxn_201.ixproductcode;
				lc_ixskunumber_format := lcu_trxn_201.ixskunumber;
				lc_ixitemdescription_format := lcu_trxn_201.ixitemdescription;
				lc_ixcustitemnum_format := lcu_trxn_201.ixcustitemnum;
				lc_ixcustitemdesc_format := lcu_trxn_201.ixcustitemdesc;

				IF    (INSTR(lcu_trxn_201.ixproductcode,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_201.ixproductcode,
							 lc_comma_esc_char) > 0)
				THEN   --Added for defect 702
					lc_ixproductcode_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_201.ixproductcode,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_201.ixskunumber,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_201.ixskunumber,
							 lc_comma_esc_char) > 0)
				THEN   --Added for defect 702
					lc_ixskunumber_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_201.ixskunumber,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_201.ixitemdescription,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_201.ixitemdescription,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixitemdescription_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_201.ixitemdescription,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_201.ixcustitemnum,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_201.ixcustitemnum,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixcustitemnum_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_201.ixcustitemnum,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_201.ixcustitemdesc,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_201.ixcustitemdesc,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixcustitemdesc_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_201.ixcustitemdesc,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				lc_file201_content1 :=
					   lcu_trxn_201.ixrecordtype
					|| ','
					|| lcu_trxn_201.ixrecseqnumber
					|| ','
					|| lcu_trxn_201.ixtotalskurecords
					|| ','
					|| lcu_trxn_201.ixactioncode
					|| ','
					|| lcu_trxn_201.ixreserved5
					|| ','
					|| lcu_trxn_201.ixmessagetype
					|| ','
					|| lcu_trxn_201.ixreserved7
					|| ','
					|| lcu_trxn_201.ixstorenumber
					|| ','
					|| lcu_trxn_201.ixregisternumber
					|| ','
					|| lcu_trxn_201.ixtransactiontype
					|| ','
					|| lcu_trxn_201.ixreserved11
					|| ','
					|| lcu_trxn_201.ixreserved12;
				lc_file201_content2 :=
					   ','
					|| lcu_trxn_201.ixreserved13
					|| ','
					|| lcu_trxn_201.ixreserved14
					|| ','
					|| lcu_trxn_201.ixreserved15
					|| ','
					|| lcu_trxn_201.ixreserved16
					|| ','
					|| lcu_trxn_201.ixinvoice
					|| ','
					|| lcu_trxn_201.ixreserved18
					|| ','
					|| lcu_trxn_201.ixreserved19
					|| ','
					|| lcu_trxn_201.ixreserved20
					|| ','
					|| lcu_trxn_201.ixreserved21
					|| ','
					|| lcu_trxn_201.ixreserved22
					|| ','
					|| lcu_trxn_201.ixreserved23
					|| ','
					|| lcu_trxn_201.ixreserved24
					|| ','
					|| lcu_trxn_201.ixreserved25
					|| ','
					|| lcu_trxn_201.ixreserved26
					|| ','
					|| lcu_trxn_201.ixreserved27;
				lc_file201_content3 :=
					   ','
					|| lcu_trxn_201.ixreserved28
					|| ','
					|| lcu_trxn_201.ixreserved29
					|| ','
					|| lcu_trxn_201.ixreserved30
					|| ','
					|| lcu_trxn_201.ixreserved31
					|| ','
					|| lcu_trxn_201.ixreserved32
					|| ','
					|| lcu_trxn_201.ixreserved33
					|| ','
					|| lcu_trxn_201.ixreceiptnumber
					|| ','
					|| lc_ixproductcode_format
					|| ','
					|| lc_ixskunumber_format
					|| ','
					|| REPLACE(lc_ixitemdescription_format,
							   lc_new_line,
							   ' ')
					|| ','
					|| lcu_trxn_201.ixitemquantity
					|| ','
					|| lcu_trxn_201.ixunitcost
					|| ','
					|| lcu_trxn_201.ixunitmeasure
					|| ','
					|| lcu_trxn_201.ixunitvatamount
					|| ','
					|| lcu_trxn_201.ixunitvatrate;
				lc_file201_content4 :=
					   ','
					|| lcu_trxn_201.ixunitdiscount
					|| ','
					|| lcu_trxn_201.ixunitdepartmentcode
					|| ','
					|| lcu_trxn_201.ixinvoicelinenum
					|| ','
					|| lcu_trxn_201.ixcustpolinenum
					|| ','
					|| lc_ixcustitemnum_format
					|| ','
					|| REPLACE(lc_ixcustitemdesc_format,
							   lc_new_line,
							   ' ')
					|| ','
					|| lcu_trxn_201.ixcustunitprice
					|| ','
					|| lcu_trxn_201.ixcustuom;
				UTL_FILE.put(lf_out_file,
							 lc_file201_content1);
				UTL_FILE.put(lf_out_file,
							 lc_file201_content2);
				UTL_FILE.put(lf_out_file,
							 lc_file201_content3);
				UTL_FILE.put_line(lf_out_file,
								  lc_file201_content4);
				ln_count_201_rec :=   ln_count_201_rec
									+ 1;
			END LOOP;
		END LOOP;

		IF (lc_create_file_ajb = 'Y')
		THEN
			lc_file_trailer :=    '101T,'
							   || lc_file_name
							   || ','
							   || ln_count_101_rec
							   || ','
							   || ln_count_201_rec;
			UTL_FILE.put(lf_out_file,
						 lc_file_trailer);
			UTL_FILE.fclose(lf_out_file);
			fnd_file.put_line(fnd_file.LOG,
								 'Settlement File Created: '
							  || lc_file_name
							  || '.set');
		END IF;

		-- Avoid the sequqence number missing
		IF (lc_create_file_ajb = 'N')
		THEN
			fnd_file.put_line(fnd_file.LOG,
							  'Reverting Sequence Number for the Settlement file');

			UPDATE xx_ar_settlement
			SET sequence_num =   ln_sequence_num
							   - 1
			WHERE  NAME = 'BTNAME';
		END IF;

		ln_count_101_rec := 0;   -- Reset
		ln_count_201_rec := 0;   -- Reset
		lc_ixshiptocompany_format := NULL;
		lc_ixshiptoname_format := NULL;
		lc_ixshiptostreet_format := NULL;
		lc_ixshiptocity_format := NULL;
		lc_ixpurchasername_format := NULL;
		lc_ixproductcode_format := NULL;
		lc_ixskunumber_format := NULL;
		lc_ixitemdescription_format := NULL;
		lc_ixcustitemnum_format := NULL;
		lc_ixcustitemdesc_format := NULL;
		lc_ixcustreferenceid_format := NULL;
		lc_ixdesktoplocation_format := NULL;
		lc_ixbankuserdata_format := NULL;
		lc_ixshipfromzipcode_format := NULL;
		lc_ixshiptozipcode_format := NULL;
		lc_ixreleasenumber_format := NULL;
		fnd_file.put_line(fnd_file.LOG,
						  'Writing to the AMEX Settlement File Before LOOP');
		lc_error_loc := 'Writing to the AMEX Settlement File Before LOOP ';

		-- to check if we need to create the Amex File
		IF (lc_amex_file_creation = 'Y')
		THEN
			BEGIN
				SELECT target_value2
				INTO   lc_submitter_id
				FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
				WHERE  xftd.translate_id = xftv.translate_id
				AND    xftd.translation_name = 'FTP_DETAILS_AJB'
				AND    xftv.source_value2 = 'Submitter ID';
			EXCEPTION
				WHEN OTHERS
				THEN
					lc_submitter_id := NULL;
					fnd_file.put_line(fnd_file.LOG,
										 'Unable to Derive Submitter ID - Error : '
									  || SQLERRM);
			END;

			FOR lcu_trxn_101 IN c_trxn_101_amex
			LOOP
				-- Check if the Amex transaction exists
				lc_file_amex_exists := 'Y';
				lc_ixinvoice_amex := NULL;
				lc_ixshiptocompany_format := lcu_trxn_101.ixshiptocompany;
				lc_ixshiptoname_format := NVL(lcu_trxn_101.ixshiptoname,
											  lc_amex_ship_to_name_trans);
				lc_ixshiptostreet_format := lcu_trxn_101.ixshiptostreet;
				lc_ixshiptocity_format := lcu_trxn_101.ixshiptocity;
				lc_ixpurchasername_format := lcu_trxn_101.ixpurchasername;
				lc_ixcustreferenceid_format := lcu_trxn_101.ixcustomerreferenceid;
				lc_ixdesktoplocation_format := lcu_trxn_101.ixdesktoplocation;
				lc_ixbankuserdata_format := lcu_trxn_101.ixbankuserdata;
				lc_ixshipfromzipcode_format := lcu_trxn_101.ixshipfromzipcode;
				lc_ixshiptozipcode_format := lcu_trxn_101.ixshiptozipcode;
				lc_ixreleasenumber_format := lcu_trxn_101.ixreleasenumber;
				lc_ixcostcenter_format := lcu_trxn_101.ixcostcenter;
				lc_ixinvoice_amex_sep := INSTR(lcu_trxn_101.ixreceiptnumber,
											   '##');
				lc_country_code_amex := NULL;

				IF (lc_ixinvoice_amex_sep) > 0
				THEN
					lc_ixinvoice_amex := lcu_trxn_101.ixinvoice;
				ELSE
					lc_ixinvoice_amex :=
						SUBSTR(lcu_trxn_101.ixreceiptnumber,
								 INSTR(lcu_trxn_101.ixreceiptnumber,
									   '#',
									   1)
							   + 1,
								 INSTR(lcu_trxn_101.ixreceiptnumber,
									   '#',
									   1,
									   2)
							   - (  INSTR(lcu_trxn_101.ixreceiptnumber,
										  '#',
										  1)
								  + 1) );
				END IF;

				ln_leg_cust_number_sep := INSTR(lcu_trxn_101.attribute6,
												'-');

				IF (ln_leg_cust_number_sep > 0)
				THEN
					lc_legacy_customer_number := SUBSTR(lcu_trxn_101.attribute6,
														1,
														(  ln_leg_cust_number_sep
														 - 1) );
				ELSE
					lc_legacy_customer_number := lcu_trxn_101.attribute6;
				END IF;

				IF (lc_hdr_flag = 'N')
				THEN
					lc_error_loc :=    'Writing to the AMEX - File Name : '
									|| lc_file_name_amex;
					lc_error_debug := ' DBA Directory Path : XXFIN_OUTBOUND';
					lf_out_file :=
								  UTL_FILE.fopen(lc_file_creation_path,
													lc_file_name_amex
												 || '.set',
												 'w',
												 ln_chunk_size);
				END IF;

				lc_hdr_flag := 'Y';

				IF    (INSTR(lcu_trxn_101.ixshiptocompany,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixshiptocompany,
							 lc_comma_esc_char) > 0)
				THEN   --Added for defect 702
					lc_ixshiptocompany_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixshiptocompany,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_101.ixshiptoname,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixshiptoname,
							 lc_comma_esc_char) > 0)
				THEN   --Added for defect 702
					lc_ixshiptoname_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixshiptoname,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_101.ixshiptostreet,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixshiptostreet,
							 lc_comma_esc_char) > 0)
				THEN   --Added for defect 702
					lc_ixshiptostreet_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixshiptostreet,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_101.ixshiptocity,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixshiptocity,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixshiptocity_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixshiptocity,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_101.ixpurchasername,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixpurchasername,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixpurchasername_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixpurchasername,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_101.ixcustomerreferenceid,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixcustomerreferenceid,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixcustreferenceid_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixcustomerreferenceid,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_101.ixdesktoplocation,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixdesktoplocation,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixdesktoplocation_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixdesktoplocation,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_101.ixbankuserdata,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixbankuserdata,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixbankuserdata_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixbankuserdata,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_101.ixshipfromzipcode,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixshipfromzipcode,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixshipfromzipcode_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixshipfromzipcode,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_101.ixshiptozipcode,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixshiptozipcode,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixshiptozipcode_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixshiptozipcode,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_101.ixreleasenumber,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixreleasenumber,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixreleasenumber_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixreleasenumber,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				IF    (INSTR(lcu_trxn_101.ixcostcenter,
							 ',') > 0)
				   OR (INSTR(lcu_trxn_101.ixcostcenter,
							 lc_comma_esc_char) > 0)
				THEN
					lc_ixcostcenter_format :=
						   lc_comma_esc_char
						|| REPLACE(lcu_trxn_101.ixcostcenter,
								   lc_comma_esc_char,
								   lc_comma_esc_char_format)
						|| lc_comma_esc_char;
				END IF;

				SELECT SUBSTR( (NAME),
							  4)
				INTO   lc_country_code_amex
				FROM   hr_operating_units hou
				WHERE  hou.organization_id = lcu_trxn_101.org_id
				AND    SYSDATE BETWEEN hou.date_from AND NVL(hou.date_to,
															   SYSDATE
															 + 1);

				lc_tid := lcu_trxn_101.ixps2000;
				lc_pos_data := lcu_trxn_101.ixreserved43;
				lc_file101_content1 :=
					   lcu_trxn_101.pre1
					|| lcu_trxn_101.pre2
					|| lcu_trxn_101.pre3
					|| lcu_trxn_101.ixrecordtype
					|| ','
					|| lcu_trxn_101.ixreserved2
					|| ','
					|| lcu_trxn_101.ixreserved3
					|| ','
					|| lcu_trxn_101.ixactioncode
					|| ','
					|| lcu_trxn_101.ixreserved5
					|| ','
					|| lcu_trxn_101.ixmessagetype
					|| ','
					|| lcu_trxn_101.ixreserved7
					|| ','
					|| lcu_trxn_101.ixstorenumber
					|| ','
					|| lcu_trxn_101.ixregisternumber
					|| ','
					|| lcu_trxn_101.ixtransactiontype
					|| ','
					|| lcu_trxn_101.ixreserved11
					|| ','
					|| lcu_trxn_101.ixreserved12;
				lc_file101_content2 :=
							  ','
						   || lcu_trxn_101.ixaccount
						   || ','
						   || lcu_trxn_101.ixexpdate
						   || ','
						   || lcu_trxn_101.ixswipe;

				IF (lcu_trxn_101.ixtransactiontype = 'Refund')
				THEN
					lc_file101_content2 :=
							lc_file101_content2
						 || ','
						 || TRIM(TO_CHAR(  lcu_trxn_101.ixamount
										 * -1
										 / 100,
										 '9999999990.99') );
				ELSE
					lc_file101_content2 :=
								lc_file101_content2
							 || ','
							 || TRIM(TO_CHAR(  lcu_trxn_101.ixamount
											 / 100,
											 '9999999990.99') );
				END IF;

				lc_file101_content2 :=
					   lc_file101_content2
					|| ','
					|| lc_ixinvoice_amex
					|| ','
					|| lcu_trxn_101.ixreserved18
					|| ','
					|| lcu_trxn_101.ixreserved19
					|| ','
					|| lcu_trxn_101.ixreserved20
					|| ','
					|| LTRIM(lcu_trxn_101.ixoptions)
					|| ','
					|| lc_ixbankuserdata_format
					|| ','
					|| lcu_trxn_101.ixreserved23
					|| ','
					|| lcu_trxn_101.ixreserved24
					|| ','
					|| lcu_trxn_101.ixissuenumber;

				IF (lcu_trxn_101.ixtransactiontype = 'Refund')
				THEN
					lc_file101_content2 :=
						   lc_file101_content2
						|| ','
						|| TRIM(TO_CHAR(  lcu_trxn_101.ixtotalsalestaxamount
										* -1
										/ 100,
										'9999999990.99') );
				ELSE
					lc_file101_content2 :=
						   lc_file101_content2
						|| ','
						|| TRIM(TO_CHAR(  lcu_trxn_101.ixtotalsalestaxamount
										/ 100,
										'9999999990.99') );
				END IF;

				lc_file101_content2 :=    lc_file101_content2
									   || ','
									   || lcu_trxn_101.ixtotalsalestaxcollind;
				lc_file101_content3 :=
					   ','
					|| lcu_trxn_101.ixreserved28
					|| ','
					|| lcu_trxn_101.ixreserved29
					|| ','
					|| lcu_trxn_101.ixreserved30
					|| ','
					|| lcu_trxn_101.ixreserved31
					|| ','
					|| lcu_trxn_101.ixreserved32
					|| ','
					|| lcu_trxn_101.ixreserved33
					|| ','
					|| lcu_trxn_101.ixreceiptnumber
					|| ','
					|| lcu_trxn_101.ixreserved35
					|| ','
					|| lcu_trxn_101.ixreserved36
					|| ','
					|| lcu_trxn_101.ixauthorizationnumber
					|| ','
					|| lcu_trxn_101.ixreserved38
					|| ','
					|| lcu_trxn_101.ixreserved39
					|| ','
					|| lcu_trxn_101.ixreserved40
					|| ','
					|| lcu_trxn_101.ixreserved41
					|| ','
					|| lcu_trxn_101.ixreserved42;
				lc_file101_content4 :=
					   ','
					|| lcu_trxn_101.ixreserved43
					|| ','
					|| lcu_trxn_101.ixps2000
					|| ','
					|| lcu_trxn_101.ixreference
					|| ','
					|| lcu_trxn_101.ixreserved46
					|| ','
					|| lcu_trxn_101.ixipaymentbatchnumber
					|| ','
					|| lcu_trxn_101.ixreserved48
					|| ','
					|| lcu_trxn_101.ixreserved49
					|| ','
					|| TO_CHAR(TO_DATE(lcu_trxn_101.ixdate,
									   'MMDDYYYY'),
							   'YYYY-MM-DD')
					|| ','
					|| lcu_trxn_101.ixtime
					|| ','
					|| lcu_trxn_101.ixreserved52
					|| ','
					|| lcu_trxn_101.ixreserved53
					|| ','
					|| lcu_trxn_101.ixreserved54
					|| ','
					|| lcu_trxn_101.ixreserved55
					|| ','
					|| lcu_trxn_101.ixreserved56
					|| ','
					|| lcu_trxn_101.ixreserved57;
				lc_file101_content5 :=
					   ','
					|| lcu_trxn_101.ixreserved58
					|| ','
					|| lcu_trxn_101.ixreserved59
					|| ','
					|| lc_ixcustreferenceid_format
					|| ','
					|| lcu_trxn_101.ixnationaltaxcollindicator
					|| ','
					|| TRIM(TO_CHAR(  lcu_trxn_101.ixnationaltaxamount
									/ 100,
									'9999999990.99') )
					|| ','
					|| TRIM(TO_CHAR(  lcu_trxn_101.ixothertaxamount
									/ 100,
									'9999999990.99') )
					|| ','
					|| TRIM(TO_CHAR(  lcu_trxn_101.ixdiscountamount
									/ 100,
									'9999999990.99') );

				IF (lcu_trxn_101.ixtransactiontype = 'Refund')
				THEN
					lc_file101_content5 :=
						   lc_file101_content5
						|| ','
						|| TRIM(TO_CHAR(  lcu_trxn_101.ixshippingamount
										* -1
										/ 100,
										'9999999990.99') );
				ELSE
					lc_file101_content5 :=
						   lc_file101_content5
						|| ','
						|| TRIM(TO_CHAR(  lcu_trxn_101.ixshippingamount
										/ 100,
										'9999999990.99') );
				END IF;

				IF (lcu_trxn_101.ixtransactiontype = 'Refund')
				THEN
					lc_file101_content5 :=
						   lc_file101_content5
						|| ','
						|| TRIM(TO_CHAR(  lcu_trxn_101.attribute5
										* -1
										/ 100,
										'9999999990.99') );
				ELSE
					lc_file101_content5 :=
							  lc_file101_content5
						   || ','
						   || TRIM(TO_CHAR(  lcu_trxn_101.attribute5
										   / 100,
										   '9999999990.99') );
				END IF;

				IF (lcu_trxn_101.ixtransactiontype = 'Refund')
				THEN
					lc_file101_content5 :=
						   lc_file101_content5
						|| ','
						|| TRIM(TO_CHAR(  lcu_trxn_101.ixdutyamount
										* -1
										/ 100,
										'9999999990.99') );
				ELSE
					lc_file101_content5 :=
							lc_file101_content5
						 || ','
						 || TRIM(TO_CHAR(  lcu_trxn_101.ixdutyamount
										 / 100,
										 '9999999990.99') );
				END IF;

				lc_file101_content5 :=
					   lc_file101_content5
					|| ','
					|| REPLACE(lc_ixshipfromzipcode_format,
							   ' ',
							   '')
					|| ','
					|| lc_ixshiptocompany_format
					|| ','
					|| REPLACE(lc_ixshiptoname_format,
							   lc_new_line,
							   ' ')
					|| ','
					|| REPLACE(lc_ixshiptostreet_format,
							   lc_new_line,
							   ' ')
					|| ','
					|| lc_ixshiptocity_format;
				lc_file101_content6 :=
					   ','
					|| lcu_trxn_101.ixshiptostate
					|| ','
					|| lcu_trxn_101.ixshiptocountry
					|| ','
					|| REPLACE(lc_ixshiptozipcode_format,
							   ' ',
							   '')
					|| ','
					|| REPLACE(lc_ixpurchasername_format,
							   lc_new_line,
							   ' ')
					|| ','
					|| TO_CHAR(TO_DATE(lcu_trxn_101.ixorderdate,
									   'MMDDYYYY'),
							   'YYYY-MM-DD')
					|| ','
					|| lcu_trxn_101.ixmerchantvatnumber
					|| ','
					|| lcu_trxn_101.ixcustomervatnumber
					|| ','
					|| lcu_trxn_101.ixvatinvoice
					|| ','
					|| TRIM(TO_CHAR(  lcu_trxn_101.ixvatamount
									/ 100,
									'9999999990.99') )
					|| ','
					|| lcu_trxn_101.ixvatrate
					|| ','
					|| lcu_trxn_101.ixmerchandiseshipped
					|| ','
					|| lc_country_code_amex
					|| ','
					|| lc_legacy_customer_number
					|| ','
					|| lc_ixcostcenter_format
					|| ','
					|| REPLACE(lc_ixdesktoplocation_format,
							   lc_new_line,
							   ' ');
				lc_file101_content7 :=
					   ','
					|| lc_ixreleasenumber_format
					|| ','
					-- Defect 39341 || lcu_trxn_101.attribute4
					|| ','
					|| TRIM(TO_CHAR(  lcu_trxn_101.ixothertaxamount2
									/ 100,
									'9999999990.99') )
					|| ','
					|| TRIM(TO_CHAR(  lcu_trxn_101.ixothertaxamount3
									/ 100,
									'9999999990.99') )
					|| ','
					|| lcu_trxn_101.ixmisccharge
					|| ','
					|| lcu_trxn_101.ixmerchantnumber
					|| ','
					|| lcu_trxn_101.attribute8;
				lc_file101_content8 :=    ','
									   || lc_tid
									   || ','
									   || lc_pos_data
									   || ','
									   || lc_submitter_id;
				UTL_FILE.put(lf_out_file,
							 lc_file101_content1);
				UTL_FILE.put(lf_out_file,
							 lc_file101_content2);
				UTL_FILE.put(lf_out_file,
							 lc_file101_content3);
				UTL_FILE.put(lf_out_file,
							 lc_file101_content4);
				UTL_FILE.put(lf_out_file,
							 lc_file101_content5);
				UTL_FILE.put(lf_out_file,
							 lc_file101_content6);
				UTL_FILE.put(lf_out_file,
							 lc_file101_content7);
				UTL_FILE.put_line(lf_out_file,
								  lc_file101_content8);
				ln_count_101_rec :=   ln_count_101_rec
									+ 1;
				-- To get the max of the custpolinenumber for first time only.
				lc_cust_line_first_exec := 'Y';

				FOR lcu_trxn_201 IN c_trxn_201_amex(lcu_trxn_101.ixreceiptnumber)
				LOOP

					lc_ixinvoice_amex_201 := NULL;
					lc_ixproductcode_format := lcu_trxn_201.ixproductcode;
					lc_ixskunumber_format := lcu_trxn_201.ixskunumber;
					lc_ixitemdescription_format := lcu_trxn_201.ixitemdescription;
					lc_ixcustitemnum_format := lcu_trxn_201.ixcustitemnum;
					lc_ixcustitemdesc_format := lcu_trxn_201.ixcustitemdesc;
					lc_ixinvoice_amex_sep_201 := NULL;
					lc_ixinvoice_amex_sep_201 := INSTR(lcu_trxn_201.ixreceiptnumber,
													   '##');

					IF (lc_ixinvoice_amex_sep_201) > 0
					THEN
						lc_ixinvoice_amex_201 := lcu_trxn_201.ixinvoice;
					ELSE
						lc_ixinvoice_amex_201 :=
							SUBSTR(lcu_trxn_201.ixreceiptnumber,
									 INSTR(lcu_trxn_201.ixreceiptnumber,
										   '#',
										   1)
								   + 1,
									 INSTR(lcu_trxn_201.ixreceiptnumber,
										   '#',
										   1,
										   2)
								   - (  INSTR(lcu_trxn_201.ixreceiptnumber,
											  '#',
											  1)
									  + 1) );
					END IF;

					IF    (INSTR(lcu_trxn_201.ixproductcode,
								 ',') > 0)
					   OR (INSTR(lcu_trxn_201.ixproductcode,
								 lc_comma_esc_char) > 0)
					THEN
						lc_ixproductcode_format :=
							   lc_comma_esc_char
							|| REPLACE(lcu_trxn_201.ixproductcode,
									   lc_comma_esc_char,
									   lc_comma_esc_char_format)
							|| lc_comma_esc_char;
					END IF;

					IF    (INSTR(lcu_trxn_201.ixskunumber,
								 ',') > 0)
					   OR (INSTR(lcu_trxn_201.ixskunumber,
								 lc_comma_esc_char) > 0)
					THEN
						lc_ixskunumber_format :=
							   lc_comma_esc_char
							|| REPLACE(lcu_trxn_201.ixskunumber,
									   lc_comma_esc_char,
									   lc_comma_esc_char_format)
							|| lc_comma_esc_char;
					END IF;

					IF    (INSTR(lcu_trxn_201.ixitemdescription,
								 ',') > 0)
					   OR (INSTR(lcu_trxn_201.ixitemdescription,
								 lc_comma_esc_char) > 0)
					THEN
						lc_ixitemdescription_format :=
							   lc_comma_esc_char
							|| REPLACE(lcu_trxn_201.ixitemdescription,
									   lc_comma_esc_char,
									   lc_comma_esc_char_format)
							|| lc_comma_esc_char;
					END IF;

					IF    (INSTR(lcu_trxn_201.ixcustitemnum,
								 ',') > 0)
					   OR (INSTR(lcu_trxn_201.ixcustitemnum,
								 lc_comma_esc_char) > 0)
					THEN
						lc_ixcustitemnum_format :=
							   lc_comma_esc_char
							|| REPLACE(lcu_trxn_201.ixcustitemnum,
									   lc_comma_esc_char,
									   lc_comma_esc_char_format)
							|| lc_comma_esc_char;
					END IF;

					IF    (INSTR(lcu_trxn_201.ixcustitemdesc,
								 ',') > 0)
					   OR (INSTR(lcu_trxn_201.ixcustitemdesc,
								 lc_comma_esc_char) > 0)
					THEN
						lc_ixcustitemdesc_format :=
							   lc_comma_esc_char
							|| REPLACE(lcu_trxn_201.ixcustitemdesc,
									   lc_comma_esc_char,
									   lc_comma_esc_char_format)
							|| lc_comma_esc_char;
					END IF;

					-- To generate the custlinenumber if it is not in EBS
					IF (     (lcu_trxn_201.ixcustpolinenum IS NULL)
						AND (lc_cust_line_first_exec = 'Y') )
					THEN
						SELECT   NVL(MAX(ixcustpolinenum),
									 0)
							   + 1
						INTO   lc_cust_line_num_max
						FROM   xx_iby_batch_trxns_det
						WHERE  ixreceiptnumber = lcu_trxn_101.ixreceiptnumber;

						lc_cust_line_number := lc_cust_line_num_max;
						lc_cust_line_first_exec := 'N';
					ELSIF(lcu_trxn_201.ixcustpolinenum IS NULL)
					THEN
						lc_cust_line_num_max :=   lc_cust_line_num_max
												+ 1;
						lc_cust_line_number := lc_cust_line_num_max;
					ELSE
						lc_cust_line_number := lcu_trxn_201.ixcustpolinenum;
					END IF;

					lc_cust_line_number := TRIM(TO_CHAR(lc_cust_line_number,
														'00000') );
					lc_file201_content1 :=
						   lcu_trxn_201.ixrecordtype
						|| ','
						|| lcu_trxn_201.ixrecseqnumber
						|| ','
						|| lcu_trxn_201.ixtotalskurecords
						|| ','
						|| lcu_trxn_201.ixactioncode
						|| ','
						|| lcu_trxn_201.ixreserved5
						|| ','
						|| lcu_trxn_201.ixmessagetype
						|| ','
						|| lcu_trxn_201.ixreserved7
						|| ','
						|| lcu_trxn_201.ixstorenumber
						|| ','
						|| lcu_trxn_201.ixregisternumber
						|| ','
						|| lcu_trxn_201.ixtransactiontype
						|| ','
						|| lcu_trxn_201.ixreserved11
						|| ','
						|| lcu_trxn_201.ixreserved12;
					lc_file201_content2 :=
						   ','
						|| lcu_trxn_201.ixreserved13
						|| ','
						|| lcu_trxn_201.ixreserved14
						|| ','
						|| lcu_trxn_201.ixreserved15
						|| ','
						|| lcu_trxn_201.ixreserved16
						|| ','
						|| lc_ixinvoice_amex_201
						|| ','
						|| lcu_trxn_201.ixreserved18
						|| ','
						|| lcu_trxn_201.ixreserved19
						|| ','
						|| lcu_trxn_201.ixreserved20
						|| ','
						|| lcu_trxn_201.ixreserved21
						|| ','
						|| lcu_trxn_201.ixreserved22
						|| ','
						|| lcu_trxn_201.ixreserved23
						|| ','
						|| lcu_trxn_201.ixreserved24
						|| ','
						|| lcu_trxn_201.ixreserved25
						|| ','
						|| lcu_trxn_201.ixreserved26
						|| ','
						|| lcu_trxn_201.ixreserved27;
					lc_file201_content3 :=
						   ','
						|| lcu_trxn_201.ixreserved28
						|| ','
						|| lcu_trxn_201.ixreserved29
						|| ','
						|| lcu_trxn_201.ixreserved30
						|| ','
						|| lcu_trxn_201.ixreserved31
						|| ','
						|| lcu_trxn_201.ixreserved32
						|| ','
						|| lcu_trxn_201.ixreserved33
						|| ','
						|| lcu_trxn_201.ixreceiptnumber
						|| ','
						|| lc_ixproductcode_format
						|| ','
						|| lc_ixskunumber_format
						|| ','
						|| REPLACE(lc_ixitemdescription_format,
								   lc_new_line,
								   ' ');

					IF (lcu_trxn_201.ixtransactiontype = 'Refund')
					THEN
						lc_file201_content3 :=    lc_file201_content3
											   || ','
											   ||   lcu_trxn_201.ixitemquantity
												  * -1;
					ELSE
						lc_file201_content3 :=    lc_file201_content3
											   || ','
											   || lcu_trxn_201.ixitemquantity;
					END IF;

					lc_file201_content3 :=
						   lc_file201_content3
						|| ','
						|| TRIM(TO_CHAR(  lcu_trxn_201.ixunitcost
										/ 100,
										'9999999990.99') )
						|| ','
						|| lcu_trxn_201.ixunitmeasure
						|| ','
						|| TRIM(TO_CHAR(  lcu_trxn_201.ixunitvatamount
										/ 100,
										'9999999990.99') )
						|| ','
						|| lcu_trxn_201.ixunitvatrate;
					lc_file201_content4 :=
						   ','
						|| TRIM(TO_CHAR(  lcu_trxn_201.ixunitdiscount
										/ 100,
										'9999999990.99') )
						|| ','
						|| lcu_trxn_201.ixunitdepartmentcode
						|| ','
						|| lcu_trxn_201.ixinvoicelinenum
						|| ','
						|| lc_cust_line_number
						|| ','
						|| lc_ixcustitemnum_format
						|| ','
						|| REPLACE(lc_ixcustitemdesc_format,
								   lc_new_line,
								   ' ')
						|| ','
						|| TRIM(TO_CHAR(  lcu_trxn_201.ixcustunitprice
										/ 100,
										'9999999990.99') )
						|| ','
						|| lcu_trxn_201.ixcustuom;
					UTL_FILE.put(lf_out_file,
								 lc_file201_content1);
					UTL_FILE.put(lf_out_file,
								 lc_file201_content2);
					UTL_FILE.put(lf_out_file,
								 lc_file201_content3);
					UTL_FILE.put_line(lf_out_file,
									  lc_file201_content4);
					ln_count_201_rec :=   ln_count_201_rec
										+ 1;
				END LOOP;
			END LOOP;

			IF (lc_hdr_flag = 'Y')
			THEN
				UTL_FILE.fclose(lf_out_file);
				fnd_file.put_line(fnd_file.LOG,
									 'Settlement File Created for AMEX: '
								  || lc_file_name_amex
								  || '.set');
			END IF;
		END IF;   -- To check if we need to create the Amex File

		fnd_file.put_line(fnd_file.LOG,
							 'Send Settlement File Flag : '
						  || p_ajb_http_transfer);
		fnd_file.put_line(fnd_file.LOG,
							 'AJB File Flag : '
						  || lc_create_file_ajb);
		fnd_file.put_line(fnd_file.LOG,
							 'AMEX File Flag : '
						  || lc_hdr_flag);

		-- ONLY if the file is created call the HTTPS Conc Prog
		IF (lc_create_file_ajb = 'Y')
		THEN   -- Call HTTPS Only if the file is created
			IF (NVL(p_ajb_http_transfer,
					'N') = 'Y')
			THEN
				fnd_file.put_line(fnd_file.LOG,
								  'Calling the Concurrent Program to transfer the Settlement file to AJB');
				lc_error_loc := 'Calling the Concurrent Program to transfer the Settlement file to AJB';
				lc_error_debug :=    'File Name: '
								  || lc_file_name
								  || '.set';
				ln_conc_pkg_trans_request_id :=
					fnd_request.submit_request('XXFIN',
											   'XX_IBY_SEC_HTTP_PKG_TRANSFER',
											   '',
											   '',
											   FALSE,
											   lc_file_creation_path,
												  lc_file_name_instance
											   || '-'
											   || lc_file_name
											   || '.set');   -- Added for Defect 13978
				COMMIT;
				lb_request_status :=
					fnd_concurrent.wait_for_request(ln_conc_pkg_trans_request_id,
													'10',
													'',
													lc_phase,
													lc_status,
													lc_devphase,
													lc_devstatus,
													lc_message);

				IF (lc_devstatus = 'NORMAL')
				THEN
					lc_ajb_file_transfer := 'Y';
					fnd_file.put_line(fnd_file.LOG,
									  'Settlement File has been sent to AJB');
				ELSE
					lc_ajb_file_transfer := 'E';
					--x_ret_code := 1;  --For Defect# 35839
					x_ret_code := 2; --Defect# 35839, to error out the program
					x_error_buff := 'Failure in the HTTP transmission of the Settlement file to AJB';
					fnd_file.put_line(fnd_file.LOG,
									  x_error_buff);
				END IF;
			END IF;
		END IF;   -- lc_create_file_ajb

		fnd_file.put_line(fnd_file.LOG,
						  'Calling the program to calculate the summary information of Settlement');
		ln_conc_email_request_id :=
			fnd_request.submit_request('XXFIN',
									   'XX_IBY_SETTLEMENT_PKG_EMAIL',
									   '',
									   '',
									   FALSE,
									   lc_file_name   --Batch File Name
												   ,
									   lc_file_name_amex   --Amex File Name
														,
									   ld_last_request_date   --Batch Date
														   ,
									   lc_create_file_ajb);
		COMMIT;

		IF (lc_create_file_ajb = 'N')
		THEN
			lc_file_name := NULL;
		END IF;

		SELECT xftv.target_value1
		INTO   lc_email_address
		FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
		WHERE  xftd.translate_id = xftv.translate_id
		AND    xftd.translation_name = 'FTP_DETAILS_AJB'
		AND    xftv.source_value1 = 'Email'
		AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																SYSDATE
															  + 1)
		AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																SYSDATE
															  + 1)
		AND    xftv.enabled_flag = 'Y'
		AND    xftd.enabled_flag = 'Y';

		lb_request_status :=
			fnd_concurrent.wait_for_request(ln_conc_email_request_id,
											'10',
											'',
											lc_phase,
											lc_status,
											lc_devphase,
											lc_devstatus,
											lc_message);
		fnd_file.put_line(fnd_file.LOG,
						  'Calling the Common Emailer program to send the summary information of Settlement');

		IF (lc_ajb_file_transfer = 'Y')
		THEN
			lc_email_body_text :=
					'Please Find The Attached File For Settlement Batch Statistics. '
				 || 'Note: File has been sent to AJB';
		ELSIF(lc_ajb_file_transfer = 'E')
		THEN
			lc_email_body_text :=
				   'Please Find The Attached File For Settlement Batch Statistics. '
				|| 'Note: There is a Error in the HTTPS File Transfer Program. Please look the Request ID '
				|| ln_conc_pkg_trans_request_id
				|| ' log for more information.';
		ELSE
			lc_email_body_text :=
				   'Please Find The Attached File For Settlement Batch Statistics. '
				|| 'Note: File has not been sent to AJB';
		END IF;

		ln_conc_emailer_request_id :=
			fnd_request.submit_request('XXFIN',
									   'XXODROEMAILER',
									   '',
									   '',
									   FALSE,
									   '',
									   lc_email_address,
										  'Settlement File Sent To AJB Batch Name:'
									   || lc_file_name_instance
									   || '-'
									   || lc_file_name,
									   lc_email_body_text,
									   'Y',
									   ln_conc_email_request_id);

		BEGIN
			SELECT xftv.target_value1
			INTO   ln_limit_value
			FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
			WHERE  xftd.translate_id = xftv.translate_id
			AND    xftd.translation_name = 'FTP_DETAILS_AJB'
			AND    xftv.source_value1 = 'Bulk Insert Limit'
			AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																	SYSDATE
																  + 1)
			AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																	SYSDATE
																  + 1)
			AND    xftv.enabled_flag = 'Y'
			AND    xftd.enabled_flag = 'Y';
		EXCEPTION
			WHEN OTHERS
			THEN
				ln_limit_value := 5000;
		END;

		fnd_file.put_line(fnd_file.LOG,
							 'Limit Size for BULKINSERT: '
						  || ln_limit_value);
		ln_conc_bulk_ins_request_id :=
			fnd_request.submit_request('XXFIN',
									   'XX_IBY_SETTLEMENT_PKG_BULKINS',
									   '',
									   '',
									   FALSE,
									   lc_file_name,
									   ln_limit_value);
		COMMIT;
		fnd_file.put_line(fnd_file.LOG,
							 'Request ID(OD: IBY Settlement History Insert Program) : '
						  || ln_conc_request_id);
		lb_request_status :=
			fnd_concurrent.wait_for_request(ln_conc_bulk_ins_request_id,
											'10',
											'',
											lc_phase,
											lc_status,
											lc_devphase,
											lc_devstatus,
											lc_message);

		IF (lc_file_amex_exists = 'Y')
		THEN
			fnd_file.put_line(fnd_file.LOG,
							  'Calling the Common File Copy to move the Amex Settlement file to Archive folder');
			ln_conc_file_copy_request_id :=
				fnd_request.submit_request('XXFIN',
										   'XXCOMFILCOPY',
										   '',
										   '',
										   FALSE,
											  lc_source_path_name
										   || '/'
										   || lc_file_name_amex
										   || '.set'   --Source File Name
													,
											  lc_file_path_name_amex
										   || '/'
										   || lc_file_name_amex
										   || '.set'   --Dest File Name
													,
										   '',
										   '',
										   'Y'   --Deleting the Source File
											  );
		END IF;

		COMMIT;

		IF (p_save_output = 'Y')
		THEN
			lb_save_output := TRUE;
		ELSE
			lb_save_output := FALSE;
		END IF;

		fnd_file.put_line(fnd_file.LOG,
						  'Setting the Print Options for the Extract');
		lc_error_loc := 'Setting the Print Options for the Extract';
		lb_print_option :=
			fnd_request.set_print_options(printer =>               p_printer_name,
										  style =>                 p_printer_style,
										  copies =>                p_number_copies,
										  save_output =>           lb_save_output,
										  print_together =>        p_print_together,
										  validate_printer =>      p_validate_printer);

		IF (lb_print_option = TRUE)
		THEN
			fnd_file.put_line(fnd_file.LOG,
								 'Return Value from Printer Options Set: '
							  || 'TRUE');
		ELSE
			fnd_file.put_line(fnd_file.LOG,
								 'Return Value from Printer Options Set: '
							  || 'FALSE');
		END IF;

		fnd_file.put_line(fnd_file.LOG,
						  'Calling the OD: CM CC Settlement Transactions Extract');
		lc_error_loc := 'Calling the OD: CM CC Settlement Transactions Extract';
		ln_conc_cc_extract_request_id :=
										fnd_request.submit_request('XXFIN',
																   'XXCMCCTRXEXT',
																   '',
																   '',
																   FALSE,
																   lc_file_name);
		COMMIT;
		lb_request_status :=
			fnd_concurrent.wait_for_request(ln_conc_cc_extract_request_id,
											'10',
											'',
											lc_phase,
											lc_status,
											lc_devphase,
											lc_devstatus,
											lc_message);

		ORDT_RECORDS_MAIL;  --Defect# 37763 - to send ORDT alert mail

	EXCEPTION
		--START of Defect# 35839, to handle duplicate record exception
		WHEN Duplicate_issue
		THEN
			x_ret_code := 2;
			x_error_buff := lc_error_loc|| '  Error Message: '
				|| SQLERRM;

			xx_com_error_log_pub.log_error(p_program_type =>                'CLOSE BATCH',
										   p_program_name =>                'CLOSE BATCH CALL',
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              'Calling the Close batch servlet',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               '101 or 201 tables already had data with ixipaymentbatchnumber populated',
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'Close Batch call',
										   p_object_id =>                   '');
		--END of defect# 35839
		WHEN ex_batch_close_fail
		THEN
			x_ret_code := 2;
			x_error_buff := lc_message_data;
			xx_com_error_log_pub.log_error(p_program_type =>                'CLOSE BATCH',
										   p_program_name =>                'CLOSE BATCH CALL',
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              'Calling the Close batch servlet',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               lc_message_data,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'Close Batch call',
										   p_object_id =>                   '');
			fnd_file.put_line(fnd_file.LOG,
								 'lc_message_data: '
							  || lc_message_data);
		WHEN OTHERS
		THEN
			x_ret_code := 2;
			xx_com_error_log_pub.log_error(p_program_type =>                'CLOSE BATCH',
										   p_program_name =>                'CLOSE BATCH CALL',
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_location =>              '',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>               SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'Close Batch call',
										   p_object_id =>                   '');
			x_error_buff :=
				   'Error at XX_IBY_SETTLEMENT_PKG.CLBATCH : '
				|| lc_error_loc
				|| 'Error Message: '
				|| SQLERRM
				|| 'Error Debug: '
				|| lc_error_debug;
			fnd_file.put_line(fnd_file.LOG,
							  SQLERRM);
	END clbatch;

-- +===================================================================+
-- | Name : BULKINSERT                                                 |
-- | Description : To insert into the history tables                   |
-- |                 XX_IBY_BATCH_TRXNS_HISTORY,                       |
-- |                        XX_IBY_BATCH_TRXNS_201_HISTORY             |
-- |                                                                   |
-- | Parameters  : p_payment_batch_number                              |
-- |               p_limit_translation_name                            |
-- | Returns: x_error_buff, x_ret_code                                 |
-- |                                                                   |
-- +===================================================================+
	PROCEDURE bulkinsert(
		x_error_buf             OUT     VARCHAR2,
		x_ret_code              OUT     NUMBER,
		p_payment_batch_number  IN      VARCHAR2,
		p_limit_value           IN      NUMBER)
	IS
		lc_error_loc                  VARCHAR2(4000);
		lc_error_debug                VARCHAR2(4000);
		ln_delete_101                 NUMBER;
		ln_delete_201                 NUMBER;
		ln_count                      NUMBER;
		ln_paymemt_id                 NUMBER;
		ln_ra_rows_ins_update_cnt     NUMBER;
		ln_ra_rows_ins_update_cnt_gt  NUMBER;

		TYPE xx_iby_batch_trxns_type IS TABLE OF xx_iby_batch_trxns%ROWTYPE;

		ltab_xx_iby_batch_trxns_type  xx_iby_batch_trxns_type;
		gt_update                     xx_iby_batch_trxns_type;

		TYPE xx_iby_batch_trxns_det_type IS TABLE OF xx_iby_batch_trxns_det%ROWTYPE;

		ltab_xx_iby_bat_trx_det_typ   xx_iby_batch_trxns_det_type;

		CURSOR c_insert_from_101
		IS
			SELECT *
			FROM   xx_iby_batch_trxns
			WHERE  ixipaymentbatchnumber = p_payment_batch_number;

		CURSOR c_insert_from_201
		IS
			SELECT *
			FROM   xx_iby_batch_trxns_det
			WHERE  ixipaymentbatchnumber = p_payment_batch_number;

		CURSOR c_update_from_101
		IS
			SELECT order_payment_id
			FROM   xx_iby_batch_trxns
			WHERE  ixipaymentbatchnumber = p_payment_batch_number;

		TYPE l_order_tbl_type IS TABLE OF c_update_from_101%ROWTYPE
			INDEX BY PLS_INTEGER;

		TYPE l_order_pay_type IS TABLE OF xx_iby_batch_trxns.order_payment_id%TYPE
			INDEX BY PLS_INTEGER;

		lt_pos_order                  l_order_tbl_type;
		lt_order_pay_id               l_order_pay_type;
	BEGIN
		lc_error_loc := 'Before Opening the Cursor for Bulk Insert';
		fnd_file.put_line(fnd_file.LOG,
						  'Before Opening the 101 cursor');
		fnd_file.put_line(fnd_file.LOG,
						  '***************************************************************');
		fnd_file.put_line(fnd_file.LOG,
							 'Start of Bulk Insert : '
						  || TO_CHAR(SYSDATE,
									 'DD-MON-YYYY : HH:MI:SS') );
		fnd_file.put_line(fnd_file.LOG,
						  ' ');

		OPEN c_insert_from_101;

		LOOP
			FETCH c_insert_from_101
			BULK COLLECT INTO ltab_xx_iby_batch_trxns_type LIMIT p_limit_value;   --Defect 10666

			FORALL i IN ltab_xx_iby_batch_trxns_type.FIRST .. ltab_xx_iby_batch_trxns_type.LAST
				INSERT INTO xx_iby_batch_trxns_history
				VALUES      ltab_xx_iby_batch_trxns_type(i);
			EXIT WHEN c_insert_from_101%NOTFOUND;
		END LOOP;

		CLOSE c_insert_from_101;

		fnd_file.put_line(fnd_file.LOG,
						  'After Closing the 101 Cursor');
		fnd_file.put_line(fnd_file.LOG,
						  'Before Opening the 201 cursor');

		OPEN c_insert_from_201;

		LOOP
			FETCH c_insert_from_201
			BULK COLLECT INTO ltab_xx_iby_bat_trx_det_typ LIMIT p_limit_value;   --Defect 10666

			FORALL i IN ltab_xx_iby_bat_trx_det_typ.FIRST .. ltab_xx_iby_bat_trx_det_typ.LAST
				INSERT INTO xx_iby_batch_trxns_201_history
				VALUES      ltab_xx_iby_bat_trx_det_typ(i);
			EXIT WHEN c_insert_from_201%NOTFOUND;
		END LOOP;

		CLOSE c_insert_from_201;

		fnd_file.put_line(fnd_file.LOG,
						  'After Closing the 201 Cursor');
		fnd_file.put_line(fnd_file.LOG,
						  ' ');
		fnd_file.put_line(fnd_file.LOG,
							 'End of Bulk Insert : '
						  || TO_CHAR(SYSDATE,
									 'DD-MON-YYYY : HH:MI:SS') );
		fnd_file.put_line(fnd_file.LOG,
						  '***************************************************************');
		fnd_file.put_line(fnd_file.LOG,
						  ' ');

-------------------------------------
--Update added to set remitted to Yes
-------------------------------------
		OPEN c_update_from_101;

		LOOP
			FETCH c_update_from_101
			BULK COLLECT INTO lt_pos_order LIMIT p_limit_value;

			EXIT WHEN lt_pos_order.COUNT = 0;

			FOR i IN 1 .. lt_pos_order.COUNT
			LOOP
				lt_order_pay_id(i) := lt_pos_order(i).order_payment_id;
			END LOOP;

			lc_error_loc := 'Updating Remitted to Yes on xx_ar_order_receipt_dtl';
-----------------------------------------
--Inserting POS into XX_RA_INT_LINES_ALL
-----------------------------------------
			FORALL i IN 1 .. lt_pos_order.COUNT
				UPDATE xx_ar_order_receipt_dtl
				SET remitted = 'Y',
					settlement_error_message =
						SUBSTR(DECODE(settlement_error_message,
									  NULL, NULL,
										 'CORRECTED '
									  || settlement_error_message),
							   1,
							   2000)
				WHERE  order_payment_id = lt_order_pay_id(i);
			ln_ra_rows_ins_update_cnt := SQL%ROWCOUNT;
			ln_ra_rows_ins_update_cnt_gt :=   ln_ra_rows_ins_update_cnt_gt
											+ ln_ra_rows_ins_update_cnt;
		END LOOP;

		CLOSE c_update_from_101;

		fnd_file.put_line(fnd_file.LOG,
							 'Start of Delete from 101/201 : '
						  || TO_CHAR(SYSDATE,
									 'DD-MON-YYYY : HH:MI:SS') );
		fnd_file.put_line(fnd_file.LOG,
						  '***************************************************************');
		lc_error_loc :=    'Deleting from xx_iby_batch_trxns : p_payment_batch_number='
						|| p_payment_batch_number;
		lc_error_debug := ' ';

		DELETE FROM xx_iby_batch_trxns
		WHERE       ixipaymentbatchnumber = p_payment_batch_number;

		ln_delete_101 := SQL%ROWCOUNT;
		lc_error_loc :=    'Deleting from xx_iby_batch_trxns_det : p_payment_batch_number='
						|| p_payment_batch_number;
		lc_error_debug := ' ';

		DELETE FROM xx_iby_batch_trxns_det
		WHERE       ixipaymentbatchnumber = p_payment_batch_number;

		ln_delete_201 := SQL%ROWCOUNT;
		lc_error_loc := 'Deleting from xx_ar_ipay_trxnumber';
		lc_error_debug := ' ';

		DELETE FROM xx_ar_ipay_trxnumber;

		COMMIT;
		fnd_file.put_line(fnd_file.LOG,
						  ' ');
		fnd_file.put_line(fnd_file.LOG,
							 'End of Delete from 101/201 : '
						  || TO_CHAR(SYSDATE,
									 'DD-MON-YYYY : HH:MI:SS') );
		fnd_file.put_line(fnd_file.LOG,
						  '***************************************************************');
		fnd_file.put_line(fnd_file.LOG,
							 'No: of records deleted from XX_IBY_BATCH_TRXNS: '
						  || ln_delete_101);
		fnd_file.put_line(fnd_file.LOG,
							 'No: of records deleted from XX_IBY_BATCH_TRXNS_DET: '
						  || ln_delete_201);
		fnd_file.put_line(fnd_file.LOG,
							 'No: of records inserted into XX_IBY_BATCH_TRXNS_HISTORY: '
						  || ln_delete_101);
		fnd_file.put_line(fnd_file.LOG,
							 'No: of records inserted into XX_IBY_BATCH_TRXNS_201_HISTORY: '
						  || ln_delete_201);
	EXCEPTION
		WHEN OTHERS
		THEN
			fnd_file.put_line(fnd_file.LOG,
								 'Error Msg: '
							  || SQLERRM);

			DUP_STLM_RECORDS_MAIL;  --For Defect#35839 ,to send mail when history prog fails

			xx_com_error_log_pub.log_error(p_program_type =>                'Bulk Insert',
										   p_program_name =>                'Bulk Insert',
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>                  'Error at : '
																			|| lc_error_loc
																			|| 'Debug : '
																			|| lc_error_debug
																			|| ' - '
																			|| SQLERRM,
										   p_error_message_severity =>      'Minor',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'Bulk Insert call',
										   p_object_id =>                   NULL);
			--x_ret_code := 1;  --For Defect# 35839
			x_ret_code := 2; --Defect# 35839, to error out the program
			x_error_buf :=
				   'Error at XX_IBY_SETTLEMENT_PKG.BULKINSERT : '
				|| lc_error_loc
				|| 'Error Message: '
				|| SQLERRM
				|| 'Error Debug: '
				|| lc_error_debug;
	END bulkinsert;

-- +===================================================================+
-- | Name : EMAIL                                                      |
-- | Description : To send the Batch Close details to the user in the  |
-- |                 email called from the concurrent program          |
-- |                  "OD: IBY Settlement E-mail Program"              |
-- |                                                                   |
-- | Returns: x_error_buff, x_ret_code                                 |
-- +===================================================================+
	PROCEDURE email(
		x_error_buf        OUT     VARCHAR2,
		x_ret_code         OUT     NUMBER,
		p_batch_file_name  IN      VARCHAR2,
		p_amex_file_name   IN      VARCHAR2,
		p_batch_date       IN      DATE,
		p_create_file_ajb  IN      VARCHAR2)
	IS
		ln_tot_amount                NUMBER;
		ln_tot_sales_amount          NUMBER;
		ln_refund_ar_amount          NUMBER;
		ln_refund_om_amount          NUMBER;
		ln_tot_trxns                 NUMBER;
		ln_tot_sales_trxns           NUMBER;
		ln_tot_refund_ar_trxns       NUMBER;
		ln_tot_refund_om_trxns       NUMBER;
		ln_conc_request_id           fnd_concurrent_requests.request_id%TYPE;
		lc_email_address             xx_fin_translatevalues.target_value1%TYPE;
		ln_tot_amount_amex           NUMBER;
		ln_tot_sales_amount_amex     NUMBER;
		ln_refund_ar_amount_amex     NUMBER;
		ln_refund_om_amount_amex     NUMBER;
		ln_tot_refund_amt            NUMBER;
		ln_tot_refund_vol            NUMBER;
		ln_tot_refund_amt_amex       NUMBER;
		ln_tot_refund_vol_amex       NUMBER;
		ln_tot_trxns_amex            NUMBER;
		ln_tot_sales_trxns_amex      NUMBER;
		ln_tot_refund_ar_trxns_amex  NUMBER;
		ln_tot_refund_om_trxns_amex  NUMBER;
		ld_batch_date_amex           DATE;
		--Added for QC 39910
		lc_avg_cnt_days				 NUMBER;
		ln_avg_amt					 NUMBER;
		ln_avg_cnt					 NUMBER;
		lc_avg_email_address		 xx_fin_translatevalues.target_value1%TYPE;
		lc_mail_from       			 VARCHAR2(100)  := 'noreply@officedepot.com';
		lc_mail_host 				 VARCHAR2(100):= fnd_profile.value('XX_COMN_SMTP_MAIL_SERVER');
		lc_mail_conn 				 utl_smtp.connection;
		crlf  						 VARCHAR2(10) := chr(13) || chr(10);
		slen 						 number :=1;
		v_addr 						 Varchar2(1000);
		lc_instance 				 varchar2(100);
		lc_mail_subject     		 VARCHAR2(2000);
		lc_mail_body1        		 VARCHAR2(5000):=NULL;
		lc_mail_body2       		 VARCHAR2(5000):=NULL;
		x_mail_sent_status 			 VARCHAR2(1);
		inst_count					 NUMBER := 0;

	BEGIN
		SELECT   NVL(SUM(xibt.ixamount),
					 0)
			   / 100,
			   COUNT(1)
		INTO   ln_tot_amount,
			   ln_tot_trxns
		FROM   xx_iby_batch_trxns xibt
		WHERE  xibt.ixipaymentbatchnumber = p_batch_file_name;

		SELECT   NVL(SUM(xibt.ixamount),
					 0)
			   / 100,
			   COUNT(1)
		INTO   ln_tot_sales_amount,
			   ln_tot_sales_trxns
		FROM   xx_iby_batch_trxns xibt
		WHERE  xibt.ixipaymentbatchnumber = p_batch_file_name
		AND    xibt.ixtransactiontype = 'Sale';

		SELECT   NVL(SUM(xibt.ixamount),
					 0)
			   / 100,
			   COUNT(1)
		INTO   ln_refund_ar_amount,
			   ln_tot_refund_ar_trxns
		FROM   xx_iby_batch_trxns xibt
		WHERE  xibt.ixipaymentbatchnumber = p_batch_file_name
		AND    xibt.ixtransactiontype = 'Refund'
		AND    NVL(xibt.attribute2,
				   'N') <> 'Y';

		SELECT   NVL(SUM(xibt.ixamount),
					 0)
			   / 100,
			   COUNT(1)
		INTO   ln_refund_om_amount,
			   ln_tot_refund_om_trxns
		FROM   xx_iby_batch_trxns xibt
		WHERE  xibt.ixipaymentbatchnumber = p_batch_file_name
		AND    xibt.ixtransactiontype = 'Refund'
		AND    xibt.attribute2 = 'Y';

		SELECT xftv.target_value1
		INTO   lc_email_address
		FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
		WHERE  xftd.translate_id = xftv.translate_id
		AND    xftd.translation_name = 'FTP_DETAILS_AJB'
		AND    xftv.source_value1 = 'Email'
		AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																SYSDATE
															  + 1)
		AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																SYSDATE
															  + 1)
		AND    xftv.enabled_flag = 'Y'
		AND    xftd.enabled_flag = 'Y';

		--Added for QC 39910
	BEGIN

		lc_mail_conn := utl_smtp.open_connection(lc_mail_host,25);
		utl_smtp.helo(lc_mail_conn, lc_mail_host);
		utl_smtp.mail(lc_mail_conn, lc_mail_from);

		SELECT xftv.target_value1
		INTO   lc_avg_cnt_days
		FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
		WHERE  xftd.translate_id = xftv.translate_id
		AND    xftd.translation_name = 'FTP_DETAILS_AJB'
		AND    xftv.source_value1 = 'Average'
		AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																SYSDATE
															  + 1)
		AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																SYSDATE
															  + 1)
		AND    xftv.enabled_flag = 'Y'
		AND    xftd.enabled_flag = 'Y';

		SELECT xftv.target_value1
		INTO   lc_avg_email_address
		FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
		WHERE  xftd.translate_id = xftv.translate_id
		AND    xftd.translation_name = 'FTP_DETAILS_AJB'
		AND    xftv.source_value1 = 'Avg_Email'
		AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
																SYSDATE
															  + 1)
		AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
																SYSDATE
															  + 1)
		AND    xftv.enabled_flag = 'Y'
		AND    xftd.enabled_flag = 'Y';

		SELECT NVL(ROUND(SUM(TOTAL_AMOUNT) /COUNT(1),2),0) AVG_AMOUNT,
		NVL(ROUND(SUM(TOTAL_TRANSACTIONS)/COUNT(1),0),0) AVG_TRANSACTIONS
		INTO ln_avg_amt, ln_avg_cnt
		FROM
		(SELECT NVL(SUM(IXAMOUNT),0)/ 100 TOTAL_AMOUNT,
			COUNT(1) TOTAL_TRANSACTIONS
		FROM XX_IBY_BATCH_TRXNS_HISTORY XIBT
		WHERE TRIM(TO_CHAR(TO_DATE(SUBSTR( p_batch_file_name ,1,8),'yyyymmdd'), 'DAY')) = TRIM(TO_CHAR(TO_DATE(SUBSTR(XIBT.IXIPAYMENTBATCHNUMBER,1,8),'yyyymmdd'), 'DAY'))
		AND XIBT.IXIPAYMENTBATCHNUMBER BETWEEN TO_CHAR((to_date(SUBSTR( p_batch_file_name ,1,8),'yyyymmdd')-lc_avg_cnt_days),'yyyymmdd')||'-001'
		AND TO_CHAR((TO_DATE(SUBSTR( p_batch_file_name ,1,8),'yyyymmdd')-1),'yyyymmdd')||'-001'
		AND ROUND(XIBT.ORDER_PAYMENT_ID) = XIBT.ORDER_PAYMENT_ID
		GROUP BY IXIPAYMENTBATCHNUMBER
		);


		if (instr(lc_avg_email_address,',') = 0) then
			v_addr:= lc_avg_email_address;
			utl_smtp.rcpt(lc_mail_conn,v_addr);
		else
			lc_avg_email_address := replace(lc_avg_email_address,' ','_') || ',';
			while (instr(lc_avg_email_address,',',slen)> 0) loop
			v_addr := substr(lc_avg_email_address,slen,instr(substr(lc_avg_email_address,slen),',')-1);
			slen := slen + instr(substr(lc_avg_email_address,slen),',');
			utl_smtp.rcpt(lc_mail_conn,v_addr);
			end loop;
		end if;

		--SELECT NAME INTO lc_instance FROM v$database;
		select SUBSTR(sys_context('USERENV', 'DB_NAME'),1,8) into lc_instance  from dual;--Modified for v48.1

		--Modified for V42.0
		/*IF lc_instance = 'GSIPRDGB'
		THEN
		lc_mail_subject := 'Settlement: Amount and Count - '||lc_instance||' - '||p_batch_date;
		ELSE
		lc_mail_subject :='Please Ignore: Settlement: Amount and Count - '||lc_instance||' - '||p_batch_date;
		END IF;*/

		lc_mail_subject := lc_instance||' - Settlement: Amount and Count for '||p_batch_date;

		--lc_mail_body1 := 'Average Transaction Volume (last '||lc_avg_cnt_days||' days) : '|| TRIM(TO_CHAR(ln_avg_cnt,'999,999,999,990') );
		--lc_mail_body2 := 'Average Dollar Amount      (last '||lc_avg_cnt_days||' days) : $'|| TRIM(TO_CHAR(ln_avg_amt,'999,999,999,990.99') );

		lc_mail_body1 := 'Today''s Settlement Amount: $'|| TRIM(TO_CHAR(ln_tot_amount,'999,999,999,990.99'))||'  for  '
							|| TRIM(TO_CHAR(ln_tot_trxns,'999,999,999,990'))||'  Transactions.' ;
		lc_mail_body2 := lc_avg_cnt_days||' Days Running Average: $'|| TRIM(TO_CHAR(ln_avg_amt,'999,999,999,990.99'))||'  for  '
							|| TRIM(TO_CHAR(ln_avg_cnt,'999,999,999,990'))||'  Transactions.';

		IF (lc_avg_email_address is not null)
		THEN
		UTL_SMTP.DATA
			(lc_mail_conn,
				'From:'
			|| lc_mail_from
			|| UTL_TCP.crlf
			|| 'To: '
			|| v_addr
			|| UTL_TCP.crlf
			|| 'Subject: '
			|| lc_mail_subject
			|| UTL_TCP.crlf||'MIME-Version: 1.0' || crlf || 'Content-type: text/html'
			||utl_tcp.CRLF
			||'<HTML><head><meta http-equiv="Content-Language" content="en-us" /><meta http-equiv="Content-Type" content="text/html; charset=windows-1252" /></head><BODY><BR><BR><BR>'
			|| crlf
			|| crlf
			|| crlf
			|| lc_mail_body1||'<BR><BR>'
			|| crlf
			|| crlf
			|| lc_mail_body2||'<BR>'
			|| crlf
			|| crlf
			|| crlf||'</BODY></HTML>'
			);
			UTL_SMTP.quit (lc_mail_conn);
			x_mail_sent_status := 'Y';
		ELSE
		UTL_SMTP.quit (lc_mail_conn);
		x_mail_sent_status := 'N';
		END IF;

		IF x_mail_sent_status = 'Y'
		THEN
			fnd_file.put_line (fnd_file.LOG,'Email Sent successfully');
		ELSE
			fnd_file.put_line (fnd_file.LOG,'No email sent for '|| SQLERRM);
		END IF;

		EXCEPTION
		WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error
		THEN
			raise_application_error (-20000, 'Unable to send mail: ' || SQLERRM);
		WHEN OTHERS
		THEN
			fnd_file.put_line (fnd_file.LOG,'Unable to send mail..:'|| SQLERRM);

	END;

		--END of 39910

		fnd_file.put_line(fnd_file.output,
						  LPAD('Summary of the Settlement File',
							   75) );
		fnd_file.put_line(fnd_file.output,
						  LPAD('------------------------------',
							   75) );
		fnd_file.put_line(fnd_file.output,
						  ' ');

		IF (p_create_file_ajb = 'Y')
		THEN
			fnd_file.put_line(fnd_file.output,
								 'Batch Name: '
							  || p_batch_file_name);
		ELSE
			fnd_file.put_line(fnd_file.output,
							  'Batch Name: File Not Created');
		END IF;

		ln_tot_refund_amt :=   ln_refund_om_amount
							 + ln_refund_ar_amount;
		fnd_file.put_line(fnd_file.output,
							 'Batch Date: '
						  || p_batch_date);
		fnd_file.put_line(fnd_file.output,
						  ' ');
		fnd_file.put_line(fnd_file.output,
							 'Total Net Dollar Amount being sent to AJB: $'
						  || TRIM(TO_CHAR( (  ln_tot_sales_amount
											- ln_tot_refund_amt),
										  '999,999,999,990.99') )
						  || ' ');
		fnd_file.put_line(fnd_file.output,
						  ' ');
		fnd_file.put_line(fnd_file.output,
							 'Total Sale Dollar Amount being sent in this Batch: $'
						  || TRIM(TO_CHAR(ln_tot_sales_amount,
										  '999,999,999,990.99') )
						  || ' ');
		fnd_file.put_line(fnd_file.output,
							 'Refund Dollar Amount processed from AR: $'
						  || TRIM(TO_CHAR(ln_refund_ar_amount,
										  '999,999,999,990.99') ) );
		fnd_file.put_line(fnd_file.output,
							 'Refund Dollar Amount that was processed from OM: $'
						  || TRIM(TO_CHAR(ln_refund_om_amount,
										  '999,999,999,990.99') ) );
		fnd_file.put_line(fnd_file.output,
							 'Total Refund Dollar Amount that was processed : $'
						  || TRIM(TO_CHAR(ln_tot_refund_amt,
										  '999,999,999,990.99') ) );
		fnd_file.put_line(fnd_file.output,
						  ' ');
		fnd_file.put_line(fnd_file.output,
							 'Total Transaction Volume being sent to AJB: '
						  || TRIM(TO_CHAR(ln_tot_trxns,
										  '999,999,999,990') ) );   --Added formatting for Defect 720
		fnd_file.put_line(fnd_file.output,
						  ' ');
		fnd_file.put_line(fnd_file.output,
							 'Total Sale Transaction Volume being sent in this Batch: '
						  || TRIM(TO_CHAR(ln_tot_sales_trxns,
										  '999,999,999,990') ) );
		fnd_file.put_line(fnd_file.output,
							 'Refund Transaction Volume processed from AR: '
						  || TRIM(TO_CHAR(ln_tot_refund_ar_trxns,
										  '999,999,999,990') ) );
		fnd_file.put_line(fnd_file.output,
							 'Refund Transaction Volume that was processed from OM: '
						  || TRIM(TO_CHAR(ln_tot_refund_om_trxns,
										  '999,999,999,999') ) );
		ln_tot_refund_vol :=   ln_tot_refund_om_trxns
							 + ln_tot_refund_ar_trxns;
		fnd_file.put_line(fnd_file.output,
							 'Total Refund Transaction Volume that was processed : '
						  || TRIM(TO_CHAR(ln_tot_refund_vol,
										  '999,999,999,990') ) );

		IF (p_amex_file_name IS NOT NULL)
		THEN
			-- For the AMEX CPC File
			SELECT   NVL(SUM(xibt.ixamount),
						 0)
				   / 100,
				   COUNT(1)
			INTO   ln_tot_amount_amex,
				   ln_tot_trxns_amex
			FROM   xx_iby_batch_trxns xibt
			WHERE  xibt.ixipaymentbatchnumber = p_batch_file_name
			AND    xibt.ixinstrsubtype = 'AMEX';

			SELECT   NVL(SUM(xibt.ixamount),
						 0)
				   / 100,
				   COUNT(1)
			INTO   ln_tot_sales_amount_amex,
				   ln_tot_sales_trxns_amex
			FROM   xx_iby_batch_trxns xibt
			WHERE  xibt.ixipaymentbatchnumber = p_batch_file_name
			AND    xibt.ixinstrsubtype = 'AMEX'
			AND    xibt.ixtransactiontype = 'Sale';

			SELECT   NVL(SUM(xibt.ixamount),
						 0)
				   / 100,
				   COUNT(1)
			INTO   ln_refund_ar_amount_amex,
				   ln_tot_refund_ar_trxns_amex
			FROM   xx_iby_batch_trxns xibt
			WHERE  xibt.ixipaymentbatchnumber = p_batch_file_name
			AND    xibt.ixtransactiontype = 'Refund'
			AND    xibt.ixinstrsubtype = 'AMEX'
			AND    NVL(xibt.attribute2,
					   'N') <> 'Y';

			SELECT   NVL(SUM(xibt.ixamount),
						 0)
				   / 100,
				   COUNT(1)
			INTO   ln_refund_om_amount_amex,
				   ln_tot_refund_om_trxns_amex
			FROM   xx_iby_batch_trxns xibt
			WHERE  xibt.ixipaymentbatchnumber = p_batch_file_name
			AND    xibt.ixtransactiontype = 'Refund'
			AND    xibt.ixinstrsubtype = 'AMEX'
			AND    xibt.attribute2 = 'Y';

			ld_batch_date_amex := p_batch_date;
		ELSE
			ln_tot_amount_amex := 0;
			ln_tot_trxns_amex := 0;
			ln_tot_sales_amount_amex := 0;
			ln_tot_sales_trxns_amex := 0;
			ln_refund_ar_amount_amex := 0;
			ln_tot_refund_ar_trxns_amex := 0;
			ln_refund_om_amount_amex := 0;
			ln_tot_refund_om_trxns_amex := 0;
			ld_batch_date_amex := NULL;
		END IF;

		ln_tot_refund_amt_amex :=   ln_refund_om_amount_amex
								  + ln_refund_ar_amount_amex;
		fnd_file.put_line(fnd_file.output,
						  ' ');
		fnd_file.put_line(fnd_file.output,
						  '****************************************************************');
		fnd_file.put_line(fnd_file.output,
						  ' ');
		fnd_file.put_line(fnd_file.output,
							 'Batch Name: '
						  || p_amex_file_name);
		fnd_file.put_line(fnd_file.output,
							 'Batch Date: '
						  || ld_batch_date_amex);
		fnd_file.put_line(fnd_file.output,
						  ' ');
		fnd_file.put_line(fnd_file.output,
							 'Total Net Dollar Amount being sent to AMEX-EDI: $'
						  || TRIM(TO_CHAR( (  ln_tot_sales_amount_amex
											- ln_tot_refund_amt_amex),
										  '999,999,999,990.99') )
						  || ' ');
		fnd_file.put_line(fnd_file.output,
						  ' ');
		fnd_file.put_line(fnd_file.output,
							 'Total Sale Dollar Amount being sent in this Batch: $'
						  || TRIM(TO_CHAR(ln_tot_sales_amount_amex,
										  '999,999,999,990.99') )
						  || ' ');
		fnd_file.put_line(fnd_file.output,
							 'Refund Dollar Amount processed from AR: $'
						  || TRIM(TO_CHAR(ln_refund_ar_amount_amex,
										  '999,999,999,990.99') ) );
		fnd_file.put_line(fnd_file.output,
							 'Refund Dollar Amount that was processed from OM: $'
						  || TRIM(TO_CHAR(ln_refund_om_amount_amex,
										  '999,999,999,990.99') ) );
		fnd_file.put_line(fnd_file.output,
							 'Total Refund Dollar Amount that was processed : $'
						  || TRIM(TO_CHAR(ln_tot_refund_amt_amex,
										  '999,999,999,990.99') ) );
		fnd_file.put_line(fnd_file.output,
						  ' ');
		fnd_file.put_line(fnd_file.output,
							 'Total Transaction Volume being sent to AMEX-EDI: '
						  || TRIM(TO_CHAR(ln_tot_trxns_amex,
										  '999,999,999,990') ) );
		fnd_file.put_line(fnd_file.output,
						  ' ');
		fnd_file.put_line(fnd_file.output,
							 'Total Sale Transaction Volume being sent in this Batch: '
						  || TRIM(TO_CHAR(ln_tot_sales_trxns_amex,
										  '999,999,999,990') ) );
		fnd_file.put_line(fnd_file.output,
							 'Refund Transaction Volume processed from AR: '
						  || TRIM(TO_CHAR(ln_tot_refund_ar_trxns_amex,
										  '999,999,999,990') ) );
		fnd_file.put_line(fnd_file.output,
							 'Refund Transaction Volume that was processed from OM: '
						  || TRIM(TO_CHAR(ln_tot_refund_om_trxns_amex,
										  '999,999,999,990') ) );
		ln_tot_refund_vol_amex :=   ln_tot_refund_om_trxns_amex
								  + ln_tot_refund_ar_trxns_amex;
		fnd_file.put_line(fnd_file.output,
							 'Total Refund Transaction Volume that was processed : '
						  || TRIM(TO_CHAR(ln_tot_refund_vol_amex,
										  '999,999,999,990') ) );

	EXCEPTION
		WHEN OTHERS
		THEN
			fnd_file.put_line(fnd_file.LOG,
								 'Error Message: '
							  || SQLERRM);
			x_ret_code := 2;
	END email;

-- +===================================================================+
-- | Name : PURGE                                                      |
-- | Description : To purge the History table of 101 and 201 tables    |
-- |                                                                   |
-- | Returns:                                                          |
-- +===================================================================+
	PROCEDURE PURGE(
		x_error_buff  OUT  VARCHAR2,
		x_ret_code    OUT  NUMBER)
	IS
	BEGIN
		--Deleting 5 yrs old records from 101 history table
		fnd_file.put_line(fnd_file.LOG,
						  'Deleting old records from XX_IBY_BATCH_TRXNS_HISTORY_ORG');

		DELETE FROM xx_iby_batch_trxns_history
		WHERE       TO_NUMBER(SUBSTR(ixipaymentbatchnumber,
									 1,
									 4) ) <= TO_NUMBER(  TO_CHAR(SYSDATE,
																 'yyyy')
													   - 5);

		--Deleting 5 yrs old records from 201 history table
		fnd_file.put_line(fnd_file.LOG,
						  'Deleting old records from XX_IBY_BATCH_TRXNS_201_HIS_ORG');

		DELETE FROM xx_iby_batch_trxns_201_history
		WHERE       TO_NUMBER(SUBSTR(ixipaymentbatchnumber,
									 1,
									 4) ) <= TO_NUMBER(  TO_CHAR(SYSDATE,
																 'yyyy')
													   - 5);

		COMMIT;
	END PURGE;

-- +===================================================================+
-- | Name : PMTCLOSEDATA                                               |
-- | Description : To get the batch details during the Close call      |
-- |                                                                   |
-- | Returns: x_oapfbatchdate, x_oapfcreditamount,x_oapfsalesamount    |
-- |          x_oapfbatchtotal, x_oapfcurr, x_oapfnumtrxns             |
-- |          x_oapfvpsbatchid, x_oapfgwbatchid, x_oapfbtatchstate     |
-- +===================================================================+
	PROCEDURE pmtclosedata(
		x_oapfbatchdate     OUT  VARCHAR2,
		x_oapfcreditamount  OUT  VARCHAR2,
		x_oapfsalesamount   OUT  VARCHAR2,
		x_oapfbatchtotal    OUT  VARCHAR2,
		x_oapfcurr          OUT  VARCHAR2,
		x_oapfnumtrxns      OUT  VARCHAR2,
		x_oapfvpsbatchid    OUT  VARCHAR2,
		x_oapfgwbatchid     OUT  VARCHAR2,
		x_oapfbtatchstate   OUT  VARCHAR2)
	IS
		ln_tot_amount        NUMBER;
		ln_tot_sales_amount  NUMBER;
		ln_refund_amount     NUMBER;
		ln_tot_trxns         NUMBER;
		ld_last_req_date     xx_ar_settlement.last_request_date%TYPE;
		ln_batch_id          xx_ar_settlement.sequence_num%TYPE;
	BEGIN
		SELECT   NVL(SUM(xibt.ixamount),
					 0)
			   / 100,
			   COUNT(1)
		INTO   x_oapfbatchtotal,
			   x_oapfnumtrxns
		FROM   xx_iby_batch_trxns xibt;

		SELECT   NVL(SUM(xibt.ixamount),
					 0)
			   / 100
		INTO   x_oapfsalesamount
		FROM   xx_iby_batch_trxns xibt
		WHERE  xibt.ixtransactiontype = 'Sale';

		SELECT   NVL(SUM(xibt.ixamount),
					 0)
			   / 100
		INTO   x_oapfcreditamount
		FROM   xx_iby_batch_trxns xibt
		WHERE  xibt.ixtransactiontype = 'Refund';

		x_oapfcurr := 'USD';

		BEGIN
			SELECT xas.last_request_date,
				   xas.sequence_num
			INTO   ld_last_req_date,
				   ln_batch_id
			FROM   xx_ar_settlement xas
			WHERE  xas.NAME = 'BTNAME';

			IF (TRUNC(ld_last_req_date) = TRUNC(SYSDATE) )
			THEN
				x_oapfbatchdate := TO_CHAR(ld_last_req_date,
										   'YYYYMMDD');
				ln_batch_id :=   ln_batch_id
							   + 1;
				x_oapfvpsbatchid :=    TO_CHAR(ld_last_req_date,
											   'YYYYMMDD')
									|| '-'
									|| TRIM(TO_CHAR(ln_batch_id,
													'000') );
			ELSE
				x_oapfbatchdate := TO_CHAR(SYSDATE,
										   'YYYYMMDD');
				x_oapfvpsbatchid :=    TO_CHAR(ld_last_req_date,
											   'YYYYMMDD')
									|| '-'
									|| '001';
			END IF;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				x_oapfbatchdate := TO_CHAR(SYSDATE,
										   'YYYYMMDD');
				x_oapfvpsbatchid :=    TO_CHAR(SYSDATE,
											   'YYYYMMDD')
									|| '-'
									|| '001';
		END;

		x_oapfgwbatchid := x_oapfvpsbatchid;
		x_oapfbtatchstate := '1';
	END pmtclosedata;

-- +===================================================================+
-- | PROCEDURE  : process_cc_processor_response                        |
-- |                                                                   |
-- | DESCRIPTION: Procedure is used to update AMEX iRec cash receipts  |
-- |              with the PS2000 code.                                |
-- |              Note, this is called by the TxnCustomer_ods.java     |
-- |              class in $CUSTOM_JAVA_TOP/ibyextend/                 |
-- |                                                                   |
-- | PARAMETERS : See below                                            |
-- | RETURNS    : Exception on error                                   |
-- +===================================================================+
	PROCEDURE process_cc_processor_response(
		p_payment_system_order_number  IN  iby_fndcpt_tx_extensions.payment_system_order_number%TYPE,
		p_transaction_id               IN  iby_fndcpt_tx_operations.transactionid%TYPE,
		p_instrument_sub_type          IN  iby_trxn_summaries_all.instrsubtype%TYPE,
		p_auth_code                    IN  iby_trxn_core.authcode%TYPE,
		p_status                       IN  VARCHAR2,
		p_ret_code_value               IN  ar_cash_receipts_all.attribute4%TYPE,
		p_ps2000_value                 IN  ar_cash_receipts_all.attribute4%TYPE)
	IS
		PRAGMA AUTONOMOUS_TRANSACTION;
		lr_iby_auth_response_rec  xx_iby_auth_response%ROWTYPE;
		lc_transaction            VARCHAR2(2000);
		lc_error_message          VARCHAR2(2000);
		le_process_exception      EXCEPTION;
	BEGIN
		lc_transaction :=
			   'xx_iby_settlement_pkg.process_cc_processor_response '
			|| 'for PSON: '
			|| p_payment_system_order_number
			|| ', transaction_id: '
			|| p_transaction_id
			|| ', instrument type: '
			|| p_instrument_sub_type
			|| ', auth_code '
			|| p_auth_code
			|| ', status: '
			|| p_status
			|| ', ret_code_value: '
			|| p_ret_code_value
			|| ', ps2000_value: '
			|| p_ps2000_value;
		gc_error_loc := 'Calling process_cc_processor_response.';
		xx_com_error_log_pub.log_error(p_program_type =>                'xx_iby_settlement_pkg.process_cc_processor_response',
									   p_program_name =>                'xx_iby_settlement_pkg.process_cc_processor_response',
									   p_program_id =>                  NULL,
									   p_module_name =>                 'IBY',
									   p_error_message_count =>         1,
									   p_error_message_code =>          'E',
									   p_error_message =>               lc_transaction,
									   p_error_message_severity =>      'Major',
									   p_notify_flag =>                 'N',
									   p_object_type =>                 'p_transaction_id',
									   p_object_id =>                   p_transaction_id);

		IF NOT xx_check_debug_settings
		THEN
			RAISE ex_debug_setting;
		END IF;

		xx_location_and_log(g_loc,
							lc_transaction);

		IF (   p_payment_system_order_number IS NULL
			OR p_transaction_id IS NULL)
		THEN
			lc_error_message := 'Invalid parameters: p_payment_system_order_number or p_transaction_id is NULL';
			RAISE le_process_exception;
		ELSE
			lr_iby_auth_response_rec.payment_transaction_id := p_transaction_id;
			lr_iby_auth_response_rec.payment_system_order_number := p_payment_system_order_number;
			lr_iby_auth_response_rec.instrument_sub_type := p_instrument_sub_type;
			lr_iby_auth_response_rec.auth_code := p_auth_code;
			lr_iby_auth_response_rec.status := p_status;
			lr_iby_auth_response_rec.ret_code_value := p_ret_code_value;
			lr_iby_auth_response_rec.ps2000_value := p_ps2000_value;
			lr_iby_auth_response_rec.creation_date := SYSDATE;
			lr_iby_auth_response_rec.created_by := NVL(fnd_global.user_id,
													   -1);
			lr_iby_auth_response_rec.last_update_date := SYSDATE;
			lr_iby_auth_response_rec.last_updated_by := NVL(fnd_global.user_id,
															-1);

			INSERT INTO xx_iby_auth_response
			VALUES      lr_iby_auth_response_rec;

			COMMIT;
		END IF;
	EXCEPTION
		WHEN ex_debug_setting
		THEN
			xx_com_error_log_pub.log_error(p_program_type =>                'xx_iby_settlment_pkg.process_cc_processor_response',
										   p_program_name =>                'xx_iby_settlment_pkg.process_cc_processor_response',
										   p_program_id =>                  NULL,
										   p_module_name =>                 'IBY',
										   p_error_message_count =>         1,
										   p_error_message_code =>          'E',
										   p_error_message =>                  'Error at: '
																			|| gc_error_loc
																			|| '. Debug: '
																			|| gc_error_debug
																			|| ' - '
																			|| SQLERRM,
										   p_error_message_severity =>      'Major',
										   p_notify_flag =>                 'N',
										   p_object_type =>                 'p_transaction_id',
										   p_object_id =>                   p_transaction_id);
		WHEN le_process_exception
		THEN
			lc_error_message := SUBSTR(   lc_transaction
									   || ' '
									   || lc_error_message,
									   1,
									   g_max_error_message_length);
			xx_location_and_log(g_loc,
								lc_error_message);
			raise_application_error(-20000,
									lc_error_message,
									FALSE);
		WHEN OTHERS
		THEN
			lc_error_message :=
				SUBSTR(   lc_transaction
					   || ' Unhandled Error.  SQLCODE: '
					   || SQLCODE
					   || ', SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			xx_location_and_log(g_loc,
								lc_error_message);
			raise_application_error(-20000,
									lc_error_message,
									FALSE);
	END process_cc_processor_response;

	PROCEDURE get_max_cash_receipt_id(
		p_org_id           IN  NUMBER,
		x_cash_receipt_id  OUT NOCOPY  ar_cash_receipts_all.cash_receipt_id%TYPE,
		x_return_status    OUT NOCOPY  VARCHAR2,
		x_error_message    OUT NOCOPY  VARCHAR2)
	IS
		lc_procedure_name  CONSTANT VARCHAR2(60)        :=    g_package_name
														   || '.'
														   || 'get_max_cash_receipt_id';
		lt_parameters               gt_input_parameters;
	BEGIN
		lt_parameters('p_org_id') := p_org_id;
		entering_sub(p_procedure_name =>      lc_procedure_name,
					 p_parameters =>          lt_parameters);

		SELECT MAX(cash_receipt_id)
		INTO   x_cash_receipt_id
		FROM   ar_cash_receipts_all
		WHERE  org_id = p_org_id;

		logit(p_message =>         '(RESULTS) Max cash receipt id: '
								|| x_cash_receipt_id,
			  p_force =>        TRUE);
		exiting_sub(p_procedure_name =>      lc_procedure_name);
		x_return_status := g_return_success;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			x_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' SQLCODE: '
					   || SQLCODE
					   || ' SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
			x_return_status := g_return_no_data_found;
		WHEN OTHERS
		THEN
			x_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' SQLCODE: '
					   || SQLCODE
					   || ' SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
			x_return_status := g_return_failure;
	END;

	-- +====================================================================+
-- | PROCEDURE  :xx_retrieve_manual_rct_info                                |
-- |                                                                        |
-- | DESCRIPTION: This procedure will be called to get payment_amount       |
-- |              and party name for given cash receipt id                  |
-- |                                                                        |
-- | PARAMETERS : p_cash_receipt_id                                         |
-- |                                                                        |
-- | RETURNS    : x_payment_amount, x_party_name, x_return_status           |
-- +========================================================================+
	PROCEDURE xx_retrieve_manual_rct_info(
		p_cash_receipt_id  IN             ar_cash_receipts_all.cash_receipt_id%TYPE,
		x_payment_amount   OUT            ar_cash_receipts_all.amount%TYPE,
		x_party_name       OUT            hz_parties.party_name%TYPE,
		x_return_status    OUT NOCOPY     VARCHAR2,
		x_error_message    OUT NOCOPY     VARCHAR2)
	IS
		lc_procedure_name  CONSTANT VARCHAR2(60)        :=    g_package_name
														   || '.'
														   || 'xx_retrieve_manual_rct_info';
		lt_parameters               gt_input_parameters;
	BEGIN
		lt_parameters('p_cash_receipt_id') := p_cash_receipt_id;
		entering_sub(p_procedure_name =>      lc_procedure_name,
					 p_parameters =>          lt_parameters);

		SELECT ara.amount_applied,
			   hp.party_name
		INTO   x_payment_amount,
			   x_party_name
		FROM   ar_receivable_applications_all ara,
			   ra_customer_trx_all rct,
			   ra_cust_trx_types_all rtt,
			   hz_cust_accounts hca,
			   hz_parties hp
		WHERE  ara.cash_receipt_id = p_cash_receipt_id
		AND    ara.applied_customer_trx_id = rct.customer_trx_id
		AND    rtt.cust_trx_type_id = rct.cust_trx_type_id
		AND    hca.cust_account_id = rct.bill_to_customer_id
		AND    ara.status = 'APP'
		AND    ara.amount_applied < 0
		AND    ara.display = 'Y'
		AND    hca.party_id = hp.party_id
		AND    rtt.TYPE = 'CM';

		logit(p_message =>         '(RESULTS) Amount, party on cash receipt id: '
								|| p_cash_receipt_id
								|| ' are payment_amount: '
								|| x_payment_amount
								|| ' and party_name: '
								|| x_party_name);
		exiting_sub(p_procedure_name =>      lc_procedure_name);
		x_return_status := g_return_success;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			x_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' SQLCODE: '
					   || SQLCODE
					   || ' SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
			x_return_status := g_return_no_data_found;
		WHEN OTHERS
		THEN
			x_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' SQLCODE: '
					   || SQLCODE
					   || ' SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
			x_return_status := g_return_failure;
	END;

	-- +====================================================================+
-- | PROCEDURE  :get_max_manual_receipt_info                              |
-- |                                                                    |
-- | DESCRIPTION: This procedure will be called to get maximum cash
-- |              receipt processed  value from translation values      |
-- |                                                                    |
-- | PARAMETERS : p_max_cash_receipt_info                               |
-- |                                                                    |
-- | RETURNS    :                                                       |
-- +====================================================================+
	PROCEDURE get_max_manual_receipt_info(
		p_org_id                 IN          NUMBER,
		x_max_cash_receipt_info  OUT NOCOPY  xx_fin_translatevalues%ROWTYPE,
		x_return_status          OUT NOCOPY  VARCHAR2,
		x_error_message          OUT NOCOPY  VARCHAR2)
	IS
		lc_procedure_name  CONSTANT VARCHAR2(60)        :=    g_package_name
														   || '.'
														   || 'get_max_manual_receipt_info';
		lt_parameters               gt_input_parameters;
	BEGIN
		lt_parameters('p_org_id') := p_org_id;
		entering_sub(p_procedure_name =>      lc_procedure_name,
					 p_parameters =>          lt_parameters);

		SELECT xtv.*
		INTO   x_max_cash_receipt_info
		FROM   xx_fin_translatedefinition xtd, xx_fin_translatevalues xtv
		WHERE  xtd.translation_name = 'OD_I0349_MANUAL_REFUND'
		AND    xtv.source_value2 = p_org_id
		AND    xtd.translate_id = xtv.translate_id
		AND    SYSDATE BETWEEN xtv.start_date_active AND NVL(xtv.end_date_active,
															   SYSDATE
															 + 1)
		AND    SYSDATE BETWEEN xtd.start_date_active AND NVL(xtd.end_date_active,
															   SYSDATE
															 + 1)
		AND    xtv.enabled_flag = 'Y'
		AND    xtd.enabled_flag = 'Y';

		logit(p_message =>         '(RESULTS) Max cash receipt id: '
								|| x_max_cash_receipt_info.source_value1,
			  p_force =>        TRUE);
		exiting_sub(p_procedure_name =>      lc_procedure_name);
		x_return_status := g_return_success;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			x_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' SQLCODE: '
					   || SQLCODE
					   || ' SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
			x_return_status := g_return_no_data_found;
		WHEN OTHERS
		THEN
			x_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' SQLCODE: '
					   || SQLCODE
					   || ' SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
			x_return_status := g_return_failure;
	END;

	-- +====================================================================+
-- | PROCEDURE  : update_max_manual_receipt_info                              |
-- |                                                                    |
-- | DESCRIPTION: This procedure will be called to update maximum cash
-- |              receipt processed  value in translation values        |
-- |                                                                    |
-- | PARAMETERS : p_max_cash_receipt_info                               |
-- |                                                                    |
-- | RETURNS    :                                                       |
-- +====================================================================+
	PROCEDURE update_max_manual_receipt_info(
		p_max_cash_receipt_info  IN             xx_fin_translatevalues%ROWTYPE,
		x_return_status          OUT NOCOPY     VARCHAR2,
		x_error_message          OUT NOCOPY     VARCHAR2)
	IS
		lc_procedure_name  CONSTANT VARCHAR2(60)        :=    g_package_name
														   || '.'
														   || 'update_max_manual_receipt_info';
		lt_parameters               gt_input_parameters;
	BEGIN
		lt_parameters('p_max_cash_receipt_info') := 'Record Type';
		lt_parameters('p_max_cash_receipt_info.translate_value_id') := p_max_cash_receipt_info.translate_value_id;
		lt_parameters('p_max_cash_receipt_info.source_value1') := p_max_cash_receipt_info.source_value1;
		lt_parameters('p_max_cash_receipt_info.source_value2') := p_max_cash_receipt_info.source_value2;
		lt_parameters('p_max_cash_receipt_info.source_value3') := p_max_cash_receipt_info.source_value3;
		entering_sub(p_procedure_name =>      lc_procedure_name,
					 p_parameters =>          lt_parameters);

		UPDATE xx_fin_translatevalues
		SET ROW = p_max_cash_receipt_info
		WHERE  translate_value_id = p_max_cash_receipt_info.translate_value_id;

		logit(p_message =>         '(RESULTS) rows updated: '
								|| SQL%ROWCOUNT);
		exiting_sub(p_procedure_name =>      lc_procedure_name);
		x_return_status := g_return_success;
	EXCEPTION
		WHEN OTHERS
		THEN
			x_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' SQLCODE: '
					   || SQLCODE
					   || ' SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
			x_return_status := g_return_failure;
	END;

-- +====================================================================+
-- | PROCEDURE  : XX_INSERT_MANUAL_RECEIPT                              |
-- |                                                                    |
-- | DESCRIPTION: This procedure will be called to insert iReceivable   |
-- |              Receipt record information from AR_CASH_RECEIPTS to   |
-- |              XX_AR_ORDER_RECEIPT_DTL table.  The procedure will be |
-- |              called only by the RETRY_ERRORS  procedure            |
-- |                                                                    |
-- | PARAMETERS : p_cash_receipt_info                                   |
-- |                                                                    |
-- | RETURNS    :                                                       |
-- +====================================================================+
	PROCEDURE xx_insert_manual_receipt(
		p_cash_receipt_info  IN             ar_cash_receipts_all%ROWTYPE,
		x_return_status      OUT NOCOPY     VARCHAR2,
		x_error_message      OUT NOCOPY     VARCHAR2)
	IS
		lc_procedure_name   CONSTANT VARCHAR2(60)                :=    g_package_name
																	|| '.'
																	|| 'xx_insert_manual_receipt';
		lt_parameters                gt_input_parameters;
		lc_action                    VARCHAR2(200);
		lr_orig_order_receipt_dtl    xx_ar_order_receipt_dtl%ROWTYPE;
		lr_return_order_receipt_dtl  xx_ar_order_receipt_dtl%ROWTYPE;
		ln_payment_amount            ar_cash_receipts_all.amount%TYPE;
		lc_party_name                hz_parties.party_name%TYPE;
		ln_pmt_num_count             NUMBER; --added for defect #32588
		le_amount_exp                EXCEPTION;
	BEGIN
		lt_parameters('p_cash_receipt_info') := 'Record Type';
		lt_parameters('p_cash_receipt_info.cash_receipt_id') := p_cash_receipt_info.cash_receipt_id;
		entering_sub(p_procedure_name =>      lc_procedure_name,
					 p_parameters =>          lt_parameters);
		lc_action :=
					 'Getting amount and customer information for cash_receipt_id: '
				  || p_cash_receipt_info.cash_receipt_id;
		xx_retrieve_manual_rct_info(p_cash_receipt_id =>      p_cash_receipt_info.cash_receipt_id,
									x_payment_amount =>       ln_payment_amount,
									x_party_name =>           lc_party_name,
									x_return_status =>        x_return_status,
									x_error_message =>        x_error_message);

		IF x_return_status != g_return_success
		THEN
			RAISE le_amount_exp;
		END IF;

		lc_action :=
				   'Getting original xx_ar_order_receipt_dtl record for receipt_number: '
				|| p_cash_receipt_info.attribute1;

		SELECT xaord.*
		INTO   lr_orig_order_receipt_dtl
		FROM   xx_ar_order_receipt_dtl xaord
		WHERE  xaord.receipt_number = TO_CHAR(p_cash_receipt_info.attribute1);

		lc_action := 'Assigning data to new xx_ar_order_receipt_dtl record.';
		lr_return_order_receipt_dtl.order_payment_id := xx_ar_order_payment_id_s.NEXTVAL;
		lr_return_order_receipt_dtl.cash_receipt_id := p_cash_receipt_info.cash_receipt_id;
		lr_return_order_receipt_dtl.credit_card_number := lr_orig_order_receipt_dtl.credit_card_number;
		lr_return_order_receipt_dtl.IDENTIFIER := lr_orig_order_receipt_dtl.IDENTIFIER;
		lr_return_order_receipt_dtl.creation_date := SYSDATE;
		lr_return_order_receipt_dtl.last_update_date := SYSDATE;
		lr_return_order_receipt_dtl.last_updated_by := NVL(fnd_global.user_id,
														   -1);
		lr_return_order_receipt_dtl.created_by := NVL(fnd_global.user_id,
													  -1);
		lr_return_order_receipt_dtl.receipt_date := TRUNC(p_cash_receipt_info.receipt_date);
		lr_return_order_receipt_dtl.credit_card_code := lr_orig_order_receipt_dtl.credit_card_code;
		lr_return_order_receipt_dtl.credit_card_expiration_date := lr_orig_order_receipt_dtl.credit_card_expiration_date;
		lr_return_order_receipt_dtl.credit_card_holder_name := lr_orig_order_receipt_dtl.credit_card_holder_name;
		lr_return_order_receipt_dtl.cc_mask_number := lr_orig_order_receipt_dtl.cc_mask_number;
		lr_return_order_receipt_dtl.payment_number := lr_orig_order_receipt_dtl.payment_number;
		lr_return_order_receipt_dtl.customer_receipt_reference := p_cash_receipt_info.customer_receipt_reference;
		lr_return_order_receipt_dtl.MATCHED := 'N';
		lr_return_order_receipt_dtl.org_id := p_cash_receipt_info.org_id;
		lr_return_order_receipt_dtl.currency_code := p_cash_receipt_info.currency_code;
		lr_return_order_receipt_dtl.store_number := lr_orig_order_receipt_dtl.store_number;
		lr_return_order_receipt_dtl.payment_type_code := 'CREDIT_CARD';
		lr_return_order_receipt_dtl.process_code := 'I1025';
		lr_return_order_receipt_dtl.process_date := TRUNC(p_cash_receipt_info.receipt_date);
		lr_return_order_receipt_dtl.receipt_method_id := p_cash_receipt_info.receipt_method_id;
		lr_return_order_receipt_dtl.receipt_number := p_cash_receipt_info.receipt_number;
		lr_return_order_receipt_dtl.receipt_status := 'OPEN';
		lr_return_order_receipt_dtl.remitted := 'N';
		lr_return_order_receipt_dtl.request_id := gn_request_id;
		lr_return_order_receipt_dtl.sale_type := g_dep_refund;
		lr_return_order_receipt_dtl.single_pay_ind := 'N';
		lr_return_order_receipt_dtl.customer_id := p_cash_receipt_info.pay_from_customer;
		lr_return_order_receipt_dtl.payment_amount := ln_payment_amount;
		lr_return_order_receipt_dtl.credit_card_holder_name := lc_party_name;
		lr_return_order_receipt_dtl.token_flag := lr_orig_order_receipt_dtl.token_flag;             --Version 27.0
		lr_return_order_receipt_dtl.emv_card := lr_orig_order_receipt_dtl.emv_card;                 --Version 27.0
		lr_return_order_receipt_dtl.emv_terminal := lr_orig_order_receipt_dtl.emv_terminal;         --Version 27.0
		lr_return_order_receipt_dtl.emv_transaction := lr_orig_order_receipt_dtl.emv_transaction;   --Version 27.0
		lr_return_order_receipt_dtl.emv_offline := lr_orig_order_receipt_dtl.emv_offline;           --Version 27.0
		lr_return_order_receipt_dtl.emv_fallback := lr_orig_order_receipt_dtl.emv_fallback;         --Version 27.0
		lr_return_order_receipt_dtl.emv_tvr := lr_orig_order_receipt_dtl.emv_tvr;                   --Version 27.0
		lc_action :=
			   'Inserting new xx_ar_order_receipt_dtl record with order_payment_id: '
			|| lr_return_order_receipt_dtl.order_payment_id;
		logit(p_message =>      lc_action);

		--changes start for defect #32588
		IF lr_return_order_receipt_dtl.customer_receipt_reference IS NULL
		   THEN
			lr_return_order_receipt_dtl.customer_receipt_reference := lr_orig_order_receipt_dtl.receipt_number;
		END IF;

		--Start Changes for Version 32.0
		IF lr_return_order_receipt_dtl.credit_card_number IS NULL THEN
		   BEGIN
			  SELECT nvl(xibth.ixaccount,substr(xibth.ixswipe,1,decode(instr(xibth.ixswipe,'=',-1),0,length(xibth.ixswipe),instr(xibth.ixswipe,'=',-1)-1))),
					 attribute8
				INTO lr_return_order_receipt_dtl.credit_card_number,
					 lr_return_order_receipt_dtl.IDENTIFIER
				FROM   xx_iby_batch_trxns_history xibth
			   WHERE xibth.order_payment_id = lr_orig_order_receipt_dtl.order_payment_id;
		   EXCEPTION
		   WHEN no_data_found then
			   lr_return_order_receipt_dtl.credit_card_number 	:= null;
			   lr_return_order_receipt_dtl.IDENTIFIER 		:= null;
		   END;
		END IF;
		--End Changes for Version 32.0

		SELECT NVL(MAX(Payment_number),0)
		INTO   ln_pmt_num_count
		FROM   xx_ar_order_receipt_dtl
		WHERE  customer_receipt_reference = lr_return_order_receipt_dtl.customer_receipt_reference;

		lr_return_order_receipt_dtl.payment_number := ln_pmt_num_count+1;

		--changes ends for defect #32588

		INSERT INTO xx_ar_order_receipt_dtl
		VALUES      lr_return_order_receipt_dtl;

		logit(p_message =>         'Created new xx_ar_order_receipt_dtl record with order_payment_id: '
								|| lr_return_order_receipt_dtl.order_payment_id);
		exiting_sub(p_procedure_name =>      lc_procedure_name);
		x_return_status := g_return_success;
	EXCEPTION
		WHEN le_amount_exp
		THEN
			x_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' Action: '
					   || lc_action
					   || ' Error: '
					   || x_error_message,
					   1,
					   g_max_error_message_length);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
			x_return_status := g_return_failure;
		WHEN OTHERS
		THEN
			x_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' Action: '
					   || lc_action
					   || ' SQLCODE: '
					   || SQLCODE
					   || ' SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
			x_return_status := g_return_failure;
	END xx_insert_manual_receipt;

-- +====================================================================+
-- | PROCEDURE  : process_manual_receipts                               |
-- |                                                                    |
-- | DESCRIPTION: This procedure will be called to insert Manual        |
-- |              Receipt record information from AR_CASH_RECEIPTS to   |
-- |              XX_AR_ORDER_RECEIPT_DTL table.  The procedure will be |
-- |              called only by the RETRY_ERRORS  procedure            |
-- |                                                                    |
-- | PARAMETERS :                                                       |
-- |                                                                    |
-- | RETURNS    :                                                       |
-- +====================================================================+
	PROCEDURE process_manual_receipts(
		p_org_id         IN  NUMBER,
		x_return_status  OUT NOCOPY  VARCHAR2,
		x_error_message  OUT NOCOPY  VARCHAR2)
	IS
		CURSOR c_manual_receipts(
			p_last_manual_receipt_id  IN  ar_cash_receipts_all.cash_receipt_id%TYPE,
			p_receipt_method_name     IN  ar_receipt_methods.NAME%TYPE,
			p_org_id                  IN  ar_cash_receipts_all.org_id%TYPE)
		IS
			SELECT DISTINCT acra.*
			FROM            xx_fin_translatedefinition xtd,
							xx_fin_translatevalues xtv,
							ar_cash_receipts_all acra,
							ar_receipt_methods arm,
							fnd_user fu
			WHERE           fu.user_name != xtv.source_value2
			AND             acra.created_by = fu.user_id
			AND             xtd.translation_name = 'OD_AR_RECIEPT_METHOD_LKUP'
			AND             xtd.translate_id = xtv.translate_id
			AND             acra.cash_receipt_id > p_last_manual_receipt_id
			AND             acra.receipt_method_id = arm.receipt_method_id
			AND             arm.NAME = p_receipt_method_name
			AND             acra.amount <= 0
			AND             acra.attribute_category = 'MANUAL_REFUND'
			AND             acra.attribute1 IS NOT NULL
			AND             acra.org_id = p_org_id
			ORDER BY        acra.cash_receipt_id;

		lc_procedure_name   CONSTANT VARCHAR2(60)                  :=    g_package_name
																	  || '.'
																	  || 'process_manual_receipts';
		lt_parameters                gt_input_parameters;
		lc_action                    VARCHAR(200);
		lr_max_cash_receipt_info     xx_fin_translatevalues%ROWTYPE;
		lc_return_status             VARCHAR2(30);
		lc_error_message             VARCHAR2(2000);
		ln_max_cash_receipt_id       ar_cash_receipts_all.cash_receipt_id%TYPE   := NULL;
		ln_max_proc_cash_receipt_id  ar_cash_receipts_all.cash_receipt_id%TYPE   := NULL;
		le_process_exception         EXCEPTION;
	BEGIN
		lt_parameters('p_org_id') := p_org_id;
		entering_sub(p_procedure_name =>      lc_procedure_name,
					 p_parameters =>          lt_parameters);
		x_return_status := g_return_success;
		lc_action := 'Getting max manual receipt information.';
		get_max_manual_receipt_info(p_org_id                        => p_org_id,
									x_max_cash_receipt_info =>      lr_max_cash_receipt_info,
									x_return_status =>              lc_return_status,
									x_error_message =>              lc_error_message);

		IF (lc_return_status != g_return_success)
		THEN
			RAISE le_process_exception;
		END IF;

		FOR rec_manual_receipt IN
			c_manual_receipts(p_last_manual_receipt_id =>      TO_NUMBER(lr_max_cash_receipt_info.source_value1),
							  p_receipt_method_name =>         lr_max_cash_receipt_info.source_value3,
							  p_org_id =>                      p_org_id)
		LOOP
			BEGIN
				lc_action :=    'Inserting manual receipt id: '
							 || rec_manual_receipt.cash_receipt_id;
				xx_insert_manual_receipt(p_cash_receipt_info =>      rec_manual_receipt,
										 x_return_status =>          lc_return_status,
										 x_error_message =>          lc_error_message);

				IF (lc_return_status != g_return_success)
				THEN
					RAISE le_process_exception;
				END IF;

				ln_max_proc_cash_receipt_id := rec_manual_receipt.cash_receipt_id;
			EXCEPTION
				WHEN OTHERS
				THEN
					x_error_message :=
						SUBSTR(   lc_procedure_name
							   || ' Action: '
							   || lc_action
							   || ' SQLCODE: '
							   || SQLCODE
							   || ' SQLERRM: '
							   || SQLERRM,
							   1,
							   g_max_error_message_length);
					x_return_status := g_return_failure;
					EXIT;
			END;
		END LOOP;


		IF (ln_max_proc_cash_receipt_id IS NOT NULL)
		THEN
			lr_max_cash_receipt_info.source_value1 := TO_CHAR(ln_max_proc_cash_receipt_id);
			lr_max_cash_receipt_info.last_update_date := SYSDATE;
			lr_max_cash_receipt_info.last_updated_by := NVL(fnd_global.user_id,
															-1);
			lc_action := 'Updating max manual receipt information';
			update_max_manual_receipt_info(p_max_cash_receipt_info =>      lr_max_cash_receipt_info,
										   x_return_status =>              lc_return_status,
										   x_error_message =>              lc_error_message);

			IF (lc_return_status != g_return_success)
			THEN
				RAISE le_process_exception;
			END IF;
		END IF;

		lc_action := 'Committing.';
		COMMIT;
		exiting_sub(p_procedure_name =>      lc_procedure_name);
	EXCEPTION
		WHEN le_process_exception
		THEN
			ROLLBACK;
			x_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' Action: '
					   || lc_action
					   || ' Error: '
					   || x_error_message,
					   1,
					   g_max_error_message_length);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
			x_return_status := g_return_failure;
		WHEN OTHERS
		THEN
			ROLLBACK;
			x_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' Action: '
					   || lc_action
					   || ' SQLCODE: '
					   || SQLCODE
					   || ' SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
			x_return_status := g_return_failure;
	END;

	-- +===================================================================+
-- | PROCEDURE  : RETRY_ERRORS_CHILD                                   |
-- |                                                                   |
-- | DESCRIPTION: Procedure to retry inserting into the  XX_IBY tables |
-- |                receipt that are pending and/or error status       |
-- |                                                                   |
-- | PARAMETERS : p_from_Date, p_to_Date, p_request_id,p_file_name     |
-- |                                                                   |
-- | RETURNS    : x_error_buf, x_ret_code                              |
-- +===================================================================+
	PROCEDURE retry_errors_child(
		x_error_buff         OUT     VARCHAR2,
		x_ret_code           OUT     NUMBER,
		p_org_id             IN      NUMBER,
		p_from_date          IN      VARCHAR2,
		p_to_date            IN      VARCHAR2,
		p_request_id         IN      NUMBER,
		p_file_name          IN      VARCHAR2,
		p_thread             IN      VARCHAR2,
		p_order_id_from      IN      VARCHAR2,
		p_order_id_to        IN      VARCHAR2,
		p_remit_status_flag  IN      VARCHAR2,
		p_debug_flag         IN      VARCHAR2 DEFAULT 'Y')
	IS
		lc_procedure_name  CONSTANT VARCHAR2(60)                             :=    g_package_name
																				|| '.'
																				|| 'retry_errors';
		lt_parameters               gt_input_parameters;
		lc_error_message            VARCHAR2(2000);
		lc_action                   VARCHAR2(200);
		lb_sett_stage               BOOLEAN;
		lc_err_msgs                 VARCHAR2(4000);
		lc_from_date                VARCHAR2(25);
		lc_to_date                  VARCHAR2(25);
		ln_error_cnt                NUMBER                                                      := 0;
		ln_total_cnt                NUMBER                                                      := 0;
		ln_stg_total_cnt            NUMBER                                                      := 0;
		ln_ret_code                 NUMBER                                                      := 0;
		lb_error_flag               BOOLEAN;
		lc_remit_pending_flag       VARCHAR2(1)                                                 := 'N';
		lc_remit_error_flag         VARCHAR2(1)                                                 := 'N';
		lc_receipt_ref              xx_iby_batch_trxns.ixreceiptnumber%TYPE;
		lc_oapfstoreid              xx_ar_order_receipt_dtl.store_number%TYPE;
		lc_oapforder_id             iby_fndcpt_tx_extensions.payment_system_order_number%TYPE;
		lc_oapfaction               VARCHAR2(25);
		lc_status                   ar_cash_receipt_history_all.status%TYPE;
		le_skip                     EXCEPTION;
		le_process_exception        EXCEPTION;

		CURSOR c_pending_payments(
			p_remit_error_flag    IN  VARCHAR2,
			p_remit_pending_flag  IN  VARCHAR2,
			p_org_id              IN  NUMBER,
			p_from_date           IN  VARCHAR2,
			p_to_date             IN  VARCHAR2,
			p_request_id          IN  NUMBER,
			p_file_name           IN  VARCHAR2)
		IS
			SELECT /*+ index(XAORD XX_AR_ORDER_RECEIPT_DTL_N3)*/
				   xaord.order_payment_id,
				   xaord.payment_amount,
				   xaord.cash_receipt_id,
				   xaord.remitted
			FROM   xx_ar_order_receipt_dtl xaord   --,
			WHERE  (   xaord.remitted = DECODE(p_remit_error_flag,
											   'Y', 'E',
											   '-X')
					OR xaord.remitted = DECODE(p_remit_pending_flag,
											   'Y', 'N',
											   '-X') )
			AND    xaord.receipt_date BETWEEN DECODE(p_from_date,
													 NULL, xaord.receipt_date,
													 TO_DATE(p_from_date,
															 'DD-MON-YY HH24:MI:SS') )
										  AND DECODE(p_to_date,
													 NULL, xaord.receipt_date,
													 TO_DATE(p_to_date,
															 'DD-MON-YY HH24:MI:SS') )
			AND    xaord.org_id = p_org_id
			AND    xaord.payment_type_code = 'CREDIT_CARD'
			AND    xaord.credit_card_code <> 'DEBIT CARD'
			AND    xaord.payment_amount <> 0
			AND    xaord.request_id = NVL(p_request_id,
										  xaord.request_id)
			AND    NVL(xaord.imp_file_name,
					   'N/A') = NVL(p_file_name,
									NVL(xaord.imp_file_name,
										'N/A') )
			AND    (    xaord.order_payment_id >= p_order_id_from
					AND xaord.order_payment_id <= p_order_id_to);

		-- Cursor to select AR Cash Receipts (non-internal store customers)
		CURSOR c_receipt_info(
			p_cash_receipt_id  IN  NUMBER)
		IS
			SELECT DISTINCT acr.unique_reference,
							NVL(ifte.payment_system_order_number,
								ifte.tangibleid) payment_system_order_number,
							arh.status
			FROM            ar_cash_receipts_all acr, ar_cash_receipt_history_all arh,
							iby_fndcpt_tx_extensions ifte
			WHERE           acr.cash_receipt_id = p_cash_receipt_id
			AND             acr.cash_receipt_id = arh.cash_receipt_id
			AND             acr.payment_trxn_extension_id = ifte.trxn_extension_id
			AND             arh.current_record_flag = 'Y';
	BEGIN
		mo_global.set_policy_context('S',
									 p_org_id);
		lt_parameters('p_org_id') := p_org_id;
		lt_parameters('p_from_date') := p_from_date;
		lt_parameters('p_to_date') := p_to_date;
		lt_parameters('p_file_name') := p_file_name;
		lt_parameters('p_remit_status_flag') := p_remit_status_flag;
		lt_parameters('p_debug_flag') := p_debug_flag;
		entering_main(p_procedure_name =>       lc_procedure_name,
					  p_rice_identifier =>      'I0349',
					  p_debug_flag =>           p_debug_flag,
					  p_parameters =>           lt_parameters);

		IF (    p_from_date IS NOT NULL
			AND p_to_date IS NOT NULL)
		THEN
			lc_from_date :=    TO_CHAR(TRUNC(fnd_date.canonical_to_date(p_from_date) ),
									   'DD-MON-YY')
							|| ' 00:00:00';
			lc_to_date :=    TO_CHAR(TRUNC(fnd_date.canonical_to_date(p_to_date) ),
									 'DD-MON-YY')
						  || ' 23:59:59';
		ELSE
			lc_error_message := 'Invalid parameters: To date and from data required.';
			RAISE le_process_exception;
		END IF;

		IF (p_remit_status_flag = 'A')
		THEN
			lc_remit_pending_flag := 'Y';
			lc_remit_error_flag := 'Y';
		ELSIF(p_remit_status_flag = 'N')
		THEN
			lc_remit_pending_flag := 'Y';
			lc_remit_error_flag := 'N';
		ELSE
			lc_remit_pending_flag := 'N';
			lc_remit_error_flag := 'Y';
		END IF;

		FOR r_payment_info IN c_pending_payments(p_remit_error_flag =>        lc_remit_error_flag,
												 p_remit_pending_flag =>      lc_remit_pending_flag,
												 p_org_id =>                  p_org_id,
												 p_from_date =>               lc_from_date,
												 p_to_date =>                 lc_to_date,
												 p_request_id =>              p_request_id,
												 p_file_name =>               p_file_name)
		LOOP
			BEGIN
				lb_sett_stage := NULL;
				lc_error_message := NULL;
				lc_oapfstoreid := NULL;
				lc_oapforder_id := NULL;
				lc_receipt_ref := NULL;
				ln_ret_code := 0;
				lb_error_flag := TRUE;
				lc_status := NULL;

				FOR r_receipt_info IN c_receipt_info(p_cash_receipt_id =>      r_payment_info.cash_receipt_id)
				LOOP
					lc_oapforder_id := r_receipt_info.payment_system_order_number;
					lc_receipt_ref := r_receipt_info.unique_reference;
					lc_status := r_receipt_info.status;
				END LOOP;

				/*****************************************
				* Transaction went through Oracle Payments
				*****************************************/
				IF lc_oapforder_id IS NOT NULL
				THEN
					IF (    NVL(r_payment_info.remitted,
								'X')IN ( 'E','N') --= 'E'
						AND NVL(lc_status,
								'N/A') IN('REMITTED', 'CLEARED') )
					THEN
						IF r_payment_info.payment_amount > 0
						THEN
							lc_oapfaction := 'ORACAPTURE';
						ELSIF r_payment_info.payment_amount < 0
						THEN
							lc_oapfaction := 'ORARETURN';
						END IF;

						IF xx_is_irec_receipt(r_payment_info.cash_receipt_id)
						THEN
							lc_oapfstoreid := g_irec_store_number;
						ELSE
							lc_oapfstoreid := '1234';   -- default value
						END IF;

						xx_iby_settlement_pkg.xx_stg_receipt_for_settlement
																  (x_error_buf =>             lc_error_message,
																   x_ret_code =>              ln_ret_code,
																   x_receipt_ref =>           lc_receipt_ref,
																   p_cash_receipt_id =>       r_payment_info.cash_receipt_id,
																   p_receipt_amount =>        r_payment_info.payment_amount,
																   p_oapfstoreid =>           lc_oapfstoreid,
																   p_oapforder_id =>          lc_oapforder_id,
																   p_order_payment_id =>      r_payment_info.order_payment_id);
						ln_total_cnt :=   ln_total_cnt
										+ 1;

						IF (    ln_ret_code = 0
							AND lc_error_message IS NULL)
						THEN
							lb_error_flag := FALSE;
						END IF;
					ELSE
						RAISE le_skip;   -- SKIP
					END IF;
				ELSE
					xx_iby_settlement_pkg.xx_stg_receipt_for_settlement
																(p_order_payment_id =>       r_payment_info.order_payment_id,
																 x_settlement_staged =>      lb_sett_stage,
																 x_error_message =>          lc_error_message);
					ln_total_cnt :=   ln_total_cnt
									+ 1;

					IF (    lb_sett_stage
						AND lc_error_message IS NULL)
					THEN
						lb_error_flag := FALSE;
					END IF;
				END IF;

				IF (lb_error_flag)
				THEN
					logit(p_message =>         'Order Payment Id: '
											|| r_payment_info.order_payment_id
											|| ' - Failed: '
											|| lc_error_message,
						  p_force =>        TRUE);

					UPDATE xx_ar_order_receipt_dtl
					SET remitted = 'E',
						settlement_error_message = SUBSTR(lc_error_message,
														  1,
														  g_max_error_message_length),
						last_update_date = SYSDATE,
						last_updated_by = NVL(fnd_global.user_id,
											  -1)
					WHERE  order_payment_id = r_payment_info.order_payment_id;

					ln_error_cnt :=   ln_error_cnt
									+ 1;
				ELSE
					UPDATE xx_ar_order_receipt_dtl
					SET remitted = 'S',
						settlement_error_message =
							SUBSTR(DECODE(settlement_error_message,
										  NULL, NULL,
											 'CORRECTED '
										  || settlement_error_message),
								   1,
								   g_max_error_message_length),
						last_update_date = SYSDATE,
						last_updated_by = NVL(fnd_global.user_id,
											  -1)
					WHERE  order_payment_id = r_payment_info.order_payment_id;

					logit(p_message =>         'Order Payment Id: '
											|| r_payment_info.order_payment_id
											|| ' - Passed',
						  p_force =>        TRUE);
				END IF;
			EXCEPTION
				WHEN le_skip
				THEN
					/**********************************************
					* Do nothing.. Move on to the next transaction.
					**********************************************/
					logit(p_message =>         'Order Payment Id: '
											|| r_payment_info.order_payment_id
											|| ' - Skipped',
						  p_force =>        TRUE);
				WHEN OTHERS
				THEN
					logit(p_message =>         'Order Payment Id: '
											|| r_payment_info.order_payment_id
											|| ' - Failed Unhandled Exception: '
											|| SQLERRM,
						  p_force =>        TRUE);
					lc_error_message := SUBSTR(   'Unhandled Exception: '
											   || SQLERRM,
											   1,
											   g_max_error_message_length);

					UPDATE xx_ar_order_receipt_dtl
					SET remitted = 'E',
						settlement_error_message = lc_error_message,
						last_update_date = SYSDATE,
						last_updated_by = NVL(fnd_global.user_id,
											  -1)
					WHERE  order_payment_id = r_payment_info.order_payment_id;

					ln_error_cnt :=   ln_error_cnt
									+ 1;
			END;

			COMMIT;
		END LOOP;

		ln_stg_total_cnt :=   ln_total_cnt
							- ln_error_cnt;
		logit(p_message =>         'Payment Receipts  - Total Attempted   : '
								|| ln_total_cnt,
			  p_force =>        TRUE);
		logit(p_message =>         'Payment Receipts  - Successfully Staged: '
								|| ln_stg_total_cnt,
			  p_force =>        TRUE);
		logit(p_message =>         'Payment Receipts  - Error             : '
								|| ln_error_cnt,
			  p_force =>        TRUE);

--------------------------------------------------------------------------
-- Set Concurrent Request Completion Status Based on Processing
--------------------------------------------------------------------------
		IF (ln_error_cnt = 0)
		THEN
			x_ret_code := 0;
		ELSE
			x_ret_code := 1;
		END IF;

		exiting_sub(p_procedure_name =>      lc_procedure_name);
	EXCEPTION
		WHEN le_process_exception
		THEN
			x_ret_code := 2;
			lc_error_message :=
							  SUBSTR(   lc_procedure_name
									 || ' ERROR:'
									 || lc_error_message,
									 1,
									 g_max_error_message_length);
			x_error_buff := SUBSTR(lc_error_message,
								   1,
								   g_max_err_buf_size);
			logit(p_message =>      lc_error_message,
				  p_force =>        TRUE);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
		WHEN OTHERS
		THEN
			x_ret_code := 2;
			lc_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' SQLCODE: '
					   || SQLCODE
					   || ' SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			x_error_buff := SUBSTR(lc_error_message,
								   1,
								   g_max_err_buf_size);
			logit(p_message =>      lc_error_message,
				  p_force =>        TRUE);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
	END retry_errors_child;

-- +===================================================================+
-- | PROCEDURE  : RETRY_ERRORS--NEW                                         |
-- |                                                                   |
-- | DESCRIPTION: Procedure to retry inserting into the  XX_IBY tables |
-- |                receipt that are pending and/or error status       |
-- |                                                                   |
-- | PARAMETERS : p_from_Date, p_to_Date, p_request_id,p_file_name     |
-- |                                                                   |
-- | RETURNS    : x_error_buf, x_ret_code                              |
-- +===================================================================+
	PROCEDURE retry_errors(
		x_error_buff         OUT     VARCHAR2,
		x_ret_code           OUT     NUMBER,
		p_org_id             IN      NUMBER,
		p_from_date          IN      VARCHAR2,
		p_to_date            IN      VARCHAR2,
		p_request_id         IN      NUMBER,
		p_file_name          IN      VARCHAR2,
		p_thread_count       IN      NUMBER,
		p_remit_status_flag  IN      VARCHAR2,
		p_debug_flag         IN      VARCHAR2 DEFAULT 'Y')
	IS
		TYPE lc_temp_tbl_num IS TABLE OF NUMBER
			INDEX BY PLS_INTEGER;

		lc_procedure_name  CONSTANT VARCHAR2(60)        :=    g_package_name
														   || '.'
														   || 'retry_errors';
		lt_parameters               gt_input_parameters;
		lc_error_message            VARCHAR2(2000);
		lc_return_status            VARCHAR2(30);
		l_ord_pay_id_from           lc_temp_tbl_num;
		l_ord_pay_id_to             lc_temp_tbl_num;
		l_thread_cnt                lc_temp_tbl_num;
		lc_from_date                VARCHAR2(30);
		lc_to_date                  VARCHAR2(30);
		lc_remit_pending_flag       VARCHAR2(1)         := 'N';
		lc_remit_error_flag         VARCHAR2(1)         := 'N';
		req_data                    VARCHAR2(10);
		l_err_temp                  NUMBER              := 0;
		l_war_temp                  NUMBER              := 0;
		l_nor_temp                  NUMBER              := 0;
		l_req_id                    NUMBER;
		le_process_exception        EXCEPTION;

		CURSOR c_pending_payments(
			p_remit_error_flag    IN  VARCHAR2,
			p_remit_pending_flag  IN  VARCHAR2,
			p_org_id              IN  NUMBER,
			p_from_date           IN  VARCHAR2,
			p_to_date             IN  VARCHAR2,
			p_request_id          IN  NUMBER,
			p_file_name           IN  VARCHAR2)
		IS
			WITH xx_pending_payments AS
				 (SELECT /*+ index(XAORD XX_AR_ORDER_RECEIPT_DTL_N3)  */
						 xaord.order_payment_id,
						 xaord.remitted,
						 xaord.customer_id,
						 xaord.cash_receipt_id,
						 xaord.payment_amount,
						 xaord.order_source
				  FROM   xx_ar_order_receipt_dtl xaord
				  WHERE  (   xaord.remitted = DECODE(p_remit_error_flag,
													 'Y', 'E',
													 '-X')
						  OR xaord.remitted = DECODE(p_remit_pending_flag,
													 'Y', 'N',
													 '-X') )
				  AND    xaord.receipt_date BETWEEN DECODE(p_from_date,
														   NULL, xaord.receipt_date,
														   TO_DATE(p_from_date,
																   'DD-MON-YY HH24:MI:SS') )
												AND DECODE(p_to_date,
														   NULL, xaord.receipt_date,
														   TO_DATE(p_to_date,
																   'DD-MON-YY HH24:MI:SS') )
				  AND    xaord.org_id = p_org_id
				  AND    xaord.payment_type_code = 'CREDIT_CARD'
				  AND    xaord.credit_card_code <> 'DEBIT CARD'
				  AND    xaord.payment_amount <> 0
				  AND    NVL(xaord.imp_file_name,
							 'N/A') = NVL(p_file_name,
										  NVL(xaord.imp_file_name,
											  'N/A') )
				  AND    xaord.request_id = NVL(p_request_id,
												xaord.request_id) )
			SELECT   MIN(order_payment_id),
					 MAX(order_payment_id),
					 thread_number
			FROM     (SELECT order_payment_id,
							 NTILE(p_thread_count) OVER(ORDER BY order_payment_id) AS thread_number
					  FROM   xx_pending_payments)
			GROUP BY thread_number
			ORDER BY thread_number;

		--Added for the defect# 38223
		CURSOR c_zero_dollar
		IS
			SELECT /*+ index(ORDT XX_AR_ORDER_RECEIPT_DTL_N3)*/  ORDER_PAYMENT_ID
			FROM 	XX_AR_ORDER_RECEIPT_DTL ORDT
			WHERE 	ORDT.PAYMENT_TYPE_CODE = 'CREDIT_CARD'
			AND 	ORDT.PAYMENT_AMOUNT      = 0
			AND 	ORDT.REMITTED            = 'N'
			AND 	ORDT.CREATION_DATE >= SYSDATE-2;

	BEGIN
		mo_global.set_policy_context('S',
									 p_org_id);
		gn_request_id := fnd_global.conc_request_id;
		gn_user_id := fnd_global.user_id;
		req_data := fnd_conc_global.request_data;
		lt_parameters('p_org_id') := p_org_id;
		lt_parameters('p_from_date') := p_from_date;
		lt_parameters('p_to_date') := p_to_date;
		lt_parameters('p_file_name') := p_file_name;
		lt_parameters('p_thread_count') := p_thread_count;
		lt_parameters('p_remit_status_flag') := p_remit_status_flag;
		lt_parameters('p_debug_flag') := p_debug_flag;
		lt_parameters('request_data') := req_data;
		entering_main(p_procedure_name =>       lc_procedure_name,
					  p_rice_identifier =>      'I0349',
					  p_debug_flag =>           p_debug_flag,
					  p_parameters =>           lt_parameters);

		IF (req_data IS NULL)
		THEN
			x_ret_code := 0;
			process_manual_receipts(p_org_id        => p_org_id,
									x_return_status =>      lc_return_status,
									x_error_message =>      lc_error_message);

			IF (lc_return_status != g_return_success)
			THEN
				x_ret_code := 2;
				logit(p_message =>      lc_error_message,
					  p_force =>        TRUE);
			END IF;

			IF (    p_from_date IS NOT NULL
				AND p_to_date IS NOT NULL)
			THEN
				lc_from_date :=    TO_CHAR(TRUNC(fnd_date.canonical_to_date(p_from_date) ),
										   'DD-MON-YY')
								|| ' 00:00:00';
				lc_to_date :=    TO_CHAR(TRUNC(fnd_date.canonical_to_date(p_to_date) ),
										 'DD-MON-YY')
							  || ' 23:59:59';
			ELSE
				lc_error_message := 'Invalid parameters: To date and from data required.';
				RAISE le_process_exception;
			END IF;

			IF (p_remit_status_flag = 'A')
			THEN
				lc_remit_pending_flag := 'Y';
				lc_remit_error_flag := 'Y';
			ELSIF(p_remit_status_flag = 'N')
			THEN
				lc_remit_pending_flag := 'Y';
				lc_remit_error_flag := 'N';
			ELSE
				lc_remit_pending_flag := 'N';
				lc_remit_error_flag := 'Y';
			END IF;

			OPEN c_pending_payments(p_remit_error_flag =>        lc_remit_error_flag,
									p_remit_pending_flag =>      lc_remit_pending_flag,
									p_org_id =>                  p_org_id,
									p_from_date =>               lc_from_date,
									p_to_date =>                 lc_to_date,
									p_request_id =>              p_request_id,
									p_file_name =>               p_file_name);

			FETCH c_pending_payments
			BULK COLLECT INTO l_ord_pay_id_from,
				   l_ord_pay_id_to,
				   l_thread_cnt;

			CLOSE c_pending_payments;

			--Handle Thread Count 0 condition in the parameters
			IF l_ord_pay_id_from.COUNT > 0
			THEN
				FOR i IN l_ord_pay_id_from.FIRST .. l_ord_pay_id_from.LAST
				LOOP
					l_req_id :=
						fnd_request.submit_request('XXFIN',

												   -- Application
												   'XX_IBY_SETTLE_RETRY_ERRORS_C',   -- Concurrent Program
												   '',   -- description
												   SYSDATE,
												   -- start time
												   TRUE,   --Sub Request
												   p_org_id,
												   p_from_date,
												   p_to_date,
												   p_request_id,
												   p_file_name,
												   l_thread_cnt(i),
												   l_ord_pay_id_from(i),
												   l_ord_pay_id_to(i),
												   p_remit_status_flag,
												   p_debug_flag);
					logit(p_message =>      '-----------------------------------------',
						  p_force =>        TRUE);
					logit(p_message =>         'Child program submitted with request id: '
											|| l_req_id,
						  p_force =>        TRUE);
					logit(p_message =>         'Org id: '
											|| p_org_id,
						  p_force =>        TRUE);
					logit(p_message =>         'From Date: '
											|| p_from_date,
						  p_force =>        TRUE);
					logit(p_message =>         'To Date: '
											|| p_to_date,
						  p_force =>        TRUE);
					logit(p_message =>         'File Name: '
											|| p_file_name,
						  p_force =>        TRUE);
					logit(p_message =>         'From order_payment_id: '
											|| l_ord_pay_id_from(i),
						  p_force =>        TRUE);
					logit(p_message =>         'To order_payment_id: '
											|| l_ord_pay_id_to(i),
						  p_force =>        TRUE);
					logit(p_message =>         'Remit Status Flag: '
											|| p_remit_status_flag,
						  p_force =>        TRUE);
					logit(p_message =>         'Debug Flag: '
											|| p_debug_flag,
						  p_force =>        TRUE);
				END LOOP;

				fnd_conc_global.set_req_globals(conc_status =>       'PAUSED',
												request_data =>      x_ret_code);
				COMMIT;
			ELSE
				logit(p_message =>      'No pending payments found.',
					  p_force =>        TRUE);
			END IF;

			--Added For the Defect# 38223
			FOR I IN c_zero_dollar
			LOOP
				UPDATE XX_AR_ORDER_RECEIPT_DTL
				SET REMITTED = 'I', MATCHED = 'Y', RECEIPT_STATUS = 'CLEARED'
				WHERE ORDER_PAYMENT_ID = I.ORDER_PAYMENT_ID;
			END LOOP;

			IF(sql%Rowcount > 0)
			THEN
				logit(p_message =>      'Updated the Remitted status for 0$ credit card payments.',
					  p_force =>        TRUE);
			END IF;

		ELSE
			x_ret_code := TO_NUMBER(req_data);

			IF NVL(x_ret_code,
				   0) < 2
			THEN
				FOR i IN (SELECT status_code
						  FROM   fnd_concurrent_requests
						  WHERE  parent_request_id = fnd_global.conc_request_id
						  AND    status_code IN('E', 'G', 'C') )
				LOOP
					IF i.status_code = 'E'
					THEN
						l_err_temp := 1;
					ELSIF i.status_code = 'G'
					THEN
						l_war_temp := 1;
					ELSIF i.status_code = 'C'
					THEN
						l_nor_temp := 1;
					END IF;
				END LOOP;

				IF l_err_temp > 0
				THEN
					x_error_buff := 'One or more child program completed in error.';
					x_ret_code := 2;
				ELSIF l_war_temp > 0
				THEN
					x_error_buff := 'One or more child program completed in warning.';
					x_ret_code := 1;
				ELSIF l_nor_temp > 0
				THEN
					x_error_buff := 'All child program(s) completed in success.';
					x_ret_code := 0;
				ELSE
					x_error_buff := 'No child programs executed.';
					x_ret_code := 0;
				END IF;
			END IF;
		END IF;

		exiting_sub(p_procedure_name =>      lc_procedure_name);

		--Added for the Defect#37866
		IF (req_data IS NOT NULL and p_org_id = 404 and p_remit_status_flag = 'E')
		THEN
			ORDT_RECORDS_MAIL;		--To send ORDT alert mail
		END IF;

	EXCEPTION
		WHEN le_process_exception
		THEN
			x_ret_code := 2;
			lc_error_message :=
							  SUBSTR(   lc_procedure_name
									 || ' ERROR:'
									 || lc_error_message,
									 1,
									 g_max_error_message_length);
			x_error_buff := SUBSTR(lc_error_message,
								   1,
								   g_max_err_buf_size);
			logit(p_message =>      lc_error_message,
				  p_force =>        TRUE);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
		WHEN OTHERS
		THEN
			x_ret_code := 2;
			lc_error_message :=
				SUBSTR(   lc_procedure_name
					   || ' SQLCODE: '
					   || SQLCODE
					   || ' SQLERRM: '
					   || SQLERRM,
					   1,
					   g_max_error_message_length);
			x_error_buff := SUBSTR(lc_error_message,
								   1,
								   g_max_err_buf_size);
			logit(p_message =>      lc_error_message,
				  p_force =>        TRUE);
			exiting_sub(p_procedure_name =>      lc_procedure_name,
						p_exception_flag =>      TRUE);
	END retry_errors;
END xx_iby_settlement_pkg;
/
show errors;
exit;