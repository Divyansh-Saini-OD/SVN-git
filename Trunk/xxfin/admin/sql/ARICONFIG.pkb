REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile(120.21.12010000.5=120.25)(120.21.12000000.2=120.22)(115.28=120.18):~PROD:~PATH:~FILE
REM SET ESCAPE `
SET VERIFY OFF;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE BODY ari_config
AS
  /* $Header: ARICNFGB.pls 120.25 2008/11/10 11:52:02 avepati ship $ */
  /*============================================================================+
  $Header: ARICNFGB.pls 120.25 2008/11/10 11:52:02 avepati ship $
  |  Copyright (c) 1996 Oracle Corporation Belmont, California, USA            |
  |                       All rights reserved                                  |
  +============================================================================+
  |                                                                            |
  | FILENAME                                                                   |
  |                                                                            |
  |    ARICNFGB.pls                                                            |
  |                                                                            |
  | DESCRIPTION                                                                |
  |                                                                            |
  | PUBLIC PROCEDURES AND FUNCTIONS                                            |
  |                                                                            |
  | PRIVATE PROCEDURES AND FUNCTIONS                                           |
  |                                                                            |
  | HISTORY                                                                    |
  | sjamall  06/05/2001: bugfix 1671116 : removed Create_Home_Page_Welcome;    |
  |                      removed deprecated procedures for creating            |
  |                      news/faq/policies section, these are now replaced by  |
  |                      get_homepage_customization(); added user_id to        |
  |                      parameter list of get_homepage_customization();       |
  | sjamall  06/14/2001: bugfix 1796817 added Search_Months_Limit              |
  | krmenon  01/25/2003: bugfix 2745797 commented the SET ESCAPE to improve    |
  |                      patching performance                                  |
  | krmenon  02/20/2003: bugfix 2812717 : Added new procedures/functions as    |
  |                      part of setup config for payment functionality        |
  | albowicz 03/14/2003: bugfix 2734074 : Removed hardcode English Strings     |
  |                      from Homepage Customization procedure as it was       |
  |       a translation issue.                                                 |
  | hikumar  06/13/2003: bugfix 3000512 : To enable custom transaction search  |
  |       on Account Details Page , added the procedure                        |
  |       search_custom_trx which needs to be modified by the                  |
  |       deploying company to add the search query for custom                 |
  |       attribute.                                                           |
  | vnb      06/14/2004: Bugfix # 3458134 - Added function to enable/disable   |
  |       discount grace days calculation                                      |
  | hikumar  07/01/2004: Bug # 3738162 Added encrypted customerId and siteId as|
  |                         parameters in function get_homepage_customization()|
  | vnb      09/21/2004: Bug 3886652 - Customer and Customer Site added as     |
  |                 params in configurable APIs.                               |
  | rsinthre 10/06/2005: Bug 4651476 - Location should be present in all VOs   |
  |                in customer search                                          |
  | rsinthre 11/02/2005: Bug 4651472 - Location should be present in all VOs   |
  |                in customer search                                          |
  | Sridevi K 15/07/2013: Retrofitted for R12 upgrade - E2052                  |
  | Sridevi K 14/03/2014: Modified for Defect #28945                           |
  |                       Reference of similar defect in R11 - Defect #17090   |
  | Pradhan, N 08/08/2014: Modified for Defect# 29880 - Home Screen custom     |
  |                                                                     Message|
  | Abhi K    09/04/2014: Modified for Defect#31273                            |
  |                       Added Consolidated Bill Code( XX_CON_BILL_NO)        |
  | Sridevi K 16/12/2014  Modified for iRec Enhancement changes                |
  | Vasu R    29/10/2015  Removed Schema References for R12.2                  |
  | Vasu R    29/08/2016  Retrofitted for 12.2.5 Upgrade                       |
  | Dinesh N  14-MAY-2018 Retrofit OM tables with Views -NAIT-37762            |
  +===========================================================================*/
  
  FUNCTION IS_LARGE_CUSTOMER( 
                              P_CUSTOMER_ID           IN NUMBER
  ) RETURN VARCHAR2 
  IS
    l_large_cust_flag VARCHAR2(1) :='N';
  BEGIN
    select 'Y' 
    into   l_large_cust_flag
    from   xx_fin_irec_large_customers
    where  cust_account_id =  p_customer_id
    ; 
    
    return l_large_cust_flag;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      l_large_cust_flag := 'N';
      return l_large_cust_flag;
  END IS_LARGE_CUSTOMER;
  
  --Added for R12 upgrade retrofit
  -- Only these two procs are customized in this package for OD:
  --   get_contact_info -- Not present in R12.
  --   search_custom_customer (See E2052 CR619 R1.2)
  -- generates raw html code used by the homepage for the configurable section : the second column : when customer_id, user_id, or site_use_id are not available, the procedure should be passed -1.
  -- If p_site_use_id = -1, then user has Customer level access. In all your custom queries, you need to set site ID to NULL
  -- Please note the customerId and customerSiteUseId has been enforced to be encrypted in all URLs
  -- If there are any customized links in this customized area in which p_customer_id or p_site_use_id is there in URL
  -- THE LINK WILL STOP WORKING
  -- For all links to any iReceivables pages in the URL use p_encrypted_customer_id and p_encrypted_site_use_id
  -- The p_customer_id and p_site_use_id contains the same id in plain text to be used for select query or any other purpose.
PROCEDURE get_homepage_customization(
    p_user_id               IN NUMBER,
    p_customer_id           IN NUMBER,
    p_site_use_id           IN NUMBER,
    p_encrypted_customer_id IN VARCHAR2,
    p_encrypted_site_use_id IN VARCHAR2,
    p_language              IN VARCHAR2,
    p_output_string OUT NOCOPY VARCHAR2 )
IS
BEGIN
  p_output_string := '                    <table border="0" cellpadding="0" cellspacing="0" width="100%">                      
<tr>                        
<td>                          
<table border="0" cellpadding="0" cellspacing="0" width="100%">';
  /* commented for defect# 29880
  <tr>
  <td class="OraHeader">';
  p_output_string :=
  p_output_string
  || fnd_message.get_string ('AR', 'ARI_HOMEPAGE_CUST_NEWS');
  p_output_string :=
  p_output_string
  || '</td>
  </tr>
  */
  p_output_string := p_output_string || '<tr>                              
<td class="OraBGAccentDark"></td>                            
</tr>                          
</table>                        
</td>                      
</tr>                      
<tr>                        
<td height="10"></td>                      
</tr>                      
<tr>                        
<td>                          
<table border="0" cellpadding="0" cellspacing="0" width="100%">                              
<tr><td>';
  /* commented for defect# 29880
  <td><ul>';
  p_output_string :=
  p_output_string
  || fnd_message.get_string ('AR', 'ARI_HOMEPAGE_CUST_NEWS_BODY');
  p_output_string :=
  p_output_string
  || '</ul>
  */
  p_output_string := p_output_string || 'We now offer electronic daily or weekly billing.  To ask how you can take advantage of this feature for a Greener Environment email <a href="mailto:billingsetup@officedepot.com">billingsetup@officedepot.com.'; -- Added for defect# 29880.
  p_output_string := p_output_string || '</td>                             
</tr>                           
</table>                          
</td>                       
</tr>                     
</table><br>                     
<table border="0" cellpadding="0" cellspacing="0" width="100%">                       
<tr>                         
<td>                           
<table border="0" cellpadding="0" cellspacing="0" width="100%">                             
<tr>                               
<td class="OraHeader">';
  p_output_string := p_output_string || fnd_message.get_string ('AR', 'ARI_HOMEPAGE_CUST_FAQS');
  p_output_string := p_output_string || '</td>                            
</tr>                            
<tr>                              
<td class="OraBGAccentDark"></td>                            
</tr>                          
</table>                        
</td>                      
</tr>                      
<tr>                        
<td height="10"></td>                      
</tr>                      
<tr>                        
<td>                          
<table border="0" cellpadding="0" cellspacing="0" width="100%">                            
<tr>                              
<td><ul>';
  p_output_string := p_output_string || fnd_message.get_string ('AR', 'ARI_HOMEPAGE_CUST_FAQS_BODY');
  p_output_string := p_output_string || '</td>                            
</tr>                          
</table>                        
</td>                      
</tr>                    
</table><br>                    
<table border="0" cellpadding="0" cellspacing="0" width="100%">                      
<tr>                        
<td>                          
<table border="0" cellpadding="0" cellspacing="0" width="100%">                            
<tr>                              
<td class="OraHeader">';
  p_output_string := p_output_string || fnd_message.get_string ('AR', 'ARI_HOMEPAGE_CUST_POLICY');
  p_output_string := p_output_string || '</td>                            
</tr>                            
<tr>                              
<td class="OraBGAccentDark"></td>                            
</tr>                          
</table>                        
</td>                      
</tr>                      
<tr>                        
<td height="10"></td>                      
</tr>                      
<tr>                        
<td>                          
<table border="0" cellpadding="0" cellspacing="0" width="100%">                            
<tr>                              
<td><ul>';
  p_output_string := p_output_string || fnd_message.get_string ('AR', 'ARI_HOMEPAGE_CUST_POLICY_BODY');
  p_output_string := p_output_string || '</td>                            
</tr>                          
</table>                        
</td>                      
</tr>                    
</table><br>                    
<table border="0" cellpadding="0" cellspacing="0" width="100%">                      
<tr>                        
<td>                          
<table border="0" cellpadding="0" cellspacing="0" width="100%">                            
<tr>                              
<td class="OraHeader">';
  p_output_string := p_output_string || fnd_message.get_string ('AR', 'ARI_HOMEPAGE_CUST_RESRC');
  p_output_string := p_output_string || '</td>                            
</tr>                            
<tr>                              
<td class="OraBGAccentDark"></td>                            
</tr>                          
</table>                        
</td>                      
</tr>                      
<tr>                        
<td height="10"></td>                      
</tr>                      
<tr>                        
<td>                          
<table border="0" cellpadding="0" cellspacing="0" width="100%">                            
<tr>                              
<td><ul>';
  p_output_string := p_output_string || fnd_message.get_string ('AR', 'ARI_HOMEPAGE_CUST_RESRC_BODY');
  p_output_string := p_output_string || '</ul></td>                            
</tr>                          
</table>                        
</td>                      
</tr>                    
</table>
';
END;
-- this procedure outputs the number of rows that the default
-- account details page view should show in the results region.
PROCEDURE restrict_by_rows(
    x_output_number OUT NOCOPY NUMBER,
    x_customer_id          IN VARCHAR2,
    x_customer_site_use_id IN VARCHAR2,
    x_language_string      IN VARCHAR2 )
IS
BEGIN
  x_output_number := 10; 
END restrict_by_rows; 
PROCEDURE get_discount_customization(
    p_customer_id IN NUMBER,
    p_site_use_id IN NUMBER,
    p_language    IN VARCHAR2,
    p_render OUT NOCOPY        VARCHAR2,
    p_output_string OUT NOCOPY VARCHAR2 )
IS
BEGIN
  p_output_string := 'Put your customized discount information here.';
  p_render        := 'Y';
END get_discount_customization;
PROCEDURE get_dispute_customization(
    p_customer_id IN NUMBER,
    p_site_use_id IN NUMBER,
    p_language    IN VARCHAR2,
    p_render OUT NOCOPY        VARCHAR2,
    p_output_string OUT NOCOPY VARCHAR2 )
IS
BEGIN
  p_output_string := 'Put your customized dispute information here.';
  p_render        := 'Y';
END get_dispute_customization;
-- CUSTOM TRANSACTION SEARCH
-- This procedure need to be modified by deploying company to write
-- the query for the customized search
-- The customer MUST select all columns in  AR_IREC_CUSTOM_SRCH_GT
-- Table , except columns Attribute1 to Attribute5 which are optional
--
-- The input parameter to the procedure are :-
--  p_customer_id    Customer ID
--  p_customer_site_id     Customer Site Use ID
--  p_person_id         Person ID
--  p_transaction_status   Transaction Status value in pop list
--  p_transaction_type     Transaction Type value in pop list
--  p_currency       Active Currency type
--  p_keyword        Search Keyword , NULL if user not entered
--  p_amount_from    Amount From in Advance search , NULL if not entered
--  p_amount_to         Amount To in Advance search , NULL if user not entered
--  p_trans_date_from      Transaction Date From in Advance search (DD-MON-YYYY )
--          NULL if user not entered
--  p_trans_date_to     Transaction Date To in Advance Search (DD-MON-YYYY )
--          NULL if user not entered
--  p_due_date_from     Due Date From in Advance search , NULL if user not entered
--  p_due_date_to    Due Date To in Advance search , NULL if user not entered
-- The users need to return the column heading for all columns which has
-- to be displayed in the custom search
-- and to return NULL for the columns which needs not to be displayed
--
--  PARAMETER      Corresponding  Field in Table    Default Column Heading
--           ( AR_IREC_CUSTOM_SRCH_GT)
--  p_transaction_col   TRX_NUMBER     "Transactions"
--  p_type_col    CLASS       "Type"
--  p_status_col  STATUS          "Status"
--  p_date_col    TRX_DATE     "Date"
--  p_due_date_col   DUE_DATE     "Due Date"
--  p_purchase_order_col     - - -      "Purchase Order"
--  p_sales_order_col        - - -         "Sales Order / Project"
--  p_original_amt_col  AMOUNT_DUE_ORIGINAL   "Original Amount"
--  p_remaining_amt_col AMOUNT_DUE_REMAINING  "Remaining Amount"
--  p_attribute1_col ATTRIBUTE1        NULL  ( not displayed )
--  p_attribute2_col ATTRIBUTE2        NULL  ( not displayed )
--  p_attribute3_col ATTRIBUTE3        NULL  ( not displayed )
--  p_attribute4_col ATTRIBUTE4        NULL  ( not displayed )
--  p_attribute5_col ATTRIBUTE5        NULL  ( not displayed )
--
--  The users need to do all validation checks , depending on the custom
--  search attribute , in case of any error
--
--  set the value of p_search_result to 'ERROR'
--
--  set the value of p_message_id to the Error message Id which is to be thrown in
--  case of the error
--
--  set the value of p_msg_app_id to the application id of error message. If no
--  application id is specified default is taken as 'AR'
--
-- For more Reference please refer to "iReceivables Custom Transaction Search"
-- White paper available on MetaLink
--
PROCEDURE search_custom_trx(
    p_session_id         IN VARCHAR2,
    p_customer_id        IN VARCHAR2,
    p_customer_site_id   IN VARCHAR2,
    p_org_id             IN VARCHAR2,
    p_person_id          IN VARCHAR2,
    p_transaction_status IN VARCHAR2,
    p_transaction_type   IN VARCHAR2,
    p_currency           IN VARCHAR2,
    p_keyword            IN VARCHAR2,
    p_amount_from        IN VARCHAR2,
    p_amount_to          IN VARCHAR2,
    p_trans_date_from    IN VARCHAR2,
    p_trans_date_to      IN VARCHAR2,
    p_due_date_from      IN VARCHAR2,
    p_due_date_to        IN VARCHAR2,
    p_org_name OUT NOCOPY           VARCHAR2,
    p_transaction_col OUT NOCOPY    VARCHAR2,
    p_type_col OUT NOCOPY           VARCHAR2,
    p_status_col OUT NOCOPY         VARCHAR2,
    p_date_col OUT NOCOPY           VARCHAR2,
    p_due_date_col OUT NOCOPY       VARCHAR2,
    p_purchase_order_col OUT NOCOPY VARCHAR2,
    p_sales_order_col OUT NOCOPY    VARCHAR2,
    p_original_amt_col OUT NOCOPY   VARCHAR2,
    p_remaining_amt_col OUT NOCOPY  VARCHAR2,
    p_attribute1_col OUT NOCOPY     VARCHAR2,
    p_attribute2_col OUT NOCOPY     VARCHAR2,
    p_attribute3_col OUT NOCOPY     VARCHAR2,
    p_attribute4_col OUT NOCOPY     VARCHAR2,
    p_attribute5_col OUT NOCOPY     VARCHAR2,
    p_search_result OUT NOCOPY      VARCHAR2,
    p_message_id OUT NOCOPY         VARCHAR2,
    p_msg_app_id OUT NOCOPY         VARCHAR2 )
IS
BEGIN
  p_transaction_col    := 'Transaction';
  p_type_col           := 'Type';
  p_status_col         := 'Status';
  p_date_col           := 'Date';
  p_due_date_col       := 'Due Date';
  p_purchase_order_col := 'Purchase Order';
  p_sales_order_col    := 'Sales Order /Project';
  p_original_amt_col   := 'Original Amount ';
  p_remaining_amt_col  := 'Remaining Amount ';
  p_attribute1_col     := NULL;
  p_attribute2_col     := NULL;
  p_attribute3_col     := NULL;
  p_attribute4_col     := NULL;
  p_attribute5_col     := NULL;
  p_msg_app_id         := 'AR';
END search_custom_trx;
-- CUSTOM CUSTOMER SEARCH
-- This procedure need to be modified by deploying company to write
-- the query for the customized customer search
-- The following columns MUST be inserted in table AR_IREC_CUSTOM_CUST_GT for all rows
--
-- CUSTOMER_ID
-- ADDRESS_ID
-- The following columns are not mandatory but are advised to be inserted in table
-- AR_IREC_CUSTOM_CUST_GT for all rows
--
-- CUSTOMER_NUMBER
-- CUSTOMER_NAME
-- CONCATENATED_ADDRESS
-- LOCATION
--
-- The link for customer account level ( all locations ) could be created by putting
-- the address_id as -1 ( minus one )
-- The address ( concatenated_address ) displayed for account level link is 'All Locations'.
-- Any value for column CONCATENATED_ADDRESS if entered is ignored for the row
-- with ADDRESS_ID as -1 and 'All Locations' text is shown for address column.
-- For All Locations, set LOCATION to null
-- The following columns MUST be inserted in table AR_IREC_CUSTOM_CUST_GT if
-- the TRANSACTION NUMBER column is displayed and transaction is of type
-- Invoice , Debit Memo , Charge Back , Deposit or Guarantee ( Class as INV , DM , CB ,
-- DEP , or GAUR respectively )
--
-- TRX_NUMBER
-- CUSTOMER_TRX_ID
-- CASH_RECEIPT_ID
-- TERMS_SEQUENCE_NUMBER
-- CLASS ( e.g. INV , DM , CB , DEP or GAUR )
-- The following columns MUST be inserted in table AR_IREC_CUSTOM_CUST_GT if
-- the TRANSACTION NUMBER column is displayed and transaction is of type
-- Payment ( Class as PMT )
--
-- TRX_NUMBER
-- CASH_RECEIPT_ID
-- CLASS ( as PMT )
-- The following columns MUST be inserted in table AR_IREC_CUSTOM_CUST_GT if
-- the TRANSACTION NUMBER column is displayed and transaction is of type
-- Credit Memo ( Class as CM )
--
-- TRX_NUMBER
-- CUSTOMER_TRX_ID
-- TERMS_SEQUENCE_NUMBER
-- CLASS ( as CM )
--
-- The following columns MUST be inserted in table AR_IREC_CUSTOM_CUST_GT if
-- the TRANSACTION NUMBER column is displayed and transaction is of type
-- Credit Request ( CLASS as REQ)
--
-- TRX_NUMBER
-- CUSTOMER_TRX_ID
-- INVOICE_CURRENCY_CODE
-- REQUEST_ID
-- REQUEST_URL ( column URL in view ra_cm_requests )
-- CLASS ( as REQ )
--
--
-- columns Attribute1 to Attribute5 which are optional for all search types
--
--
-- The input parameter to the procedure are :-
--  p_user_id        User Name
--  p_is_external_user      Responsibility type , in case of External user value is 'Y'
--           and in case of internal user the value is 'N'
--  p_search_attribute      lookup code for custom search attribute
--  p_search_keyword        Search keyword , null in case user has not entered anything
--  p_org_id                OrgId of the user
--
-- The users need to return the column heading for all columns which has
-- to be displayed in the custom search
-- and to return NULL for the columns which needs not to be displayed
--
--  PARAMETER      Corresponding  Field in Table   Suggested Column Heading
--           ( AR_IREC_CUSTOM_CUST_GT)
--  p_org_name      Organization            "Organization"
--  p_trx_number_col      TRX_NUMBER         "Transaction Number"
--  p_customer_name_col   CUSTOMER_NAME         "Customer Name"
--  p_customer_number_col CUSTOMER_NUMBER    "Customer Number"
--  p_address_col         CONCATENATED_ADDRESS     "Address"
--  p_address_type_col Transient (based on Customer_id   "Address Type"
--        and Addrress_id )
--  p_contact_name_col      - do -        "Contact Name"
--  p_contact_phone_col     - do -        "Contact Phone"
--  p_account_summary_col   - do -        "Account Summary"
--  p_attribute1_col   ATTRIBUTE1         NULL  ( not displayed )
--  p_attribute2_col   ATTRIBUTE2         NULL  ( not displayed )
--  p_attribute3_col   ATTRIBUTE3         NULL  ( not displayed )
--  p_attribute4_col   ATTRIBUTE4         NULL  ( not displayed )
--  p_attribute5_col   ATTRIBUTE5         NULL  ( not displayed )
--  p_customer_location_col   LOCATION       "Customer Location"
--
--  ERROR DISPLAY
--
--  The users need to do all validation checks , depending on the context of custom
--  search attribute.
--  In case of any error set the value of p_search_result to FND_API.G_RET_STS_ERROR
--  In case of success search set the value of p_search_result to FND_API.G_RET_STS_SUCCESS
--
--  set the value of p_message_id to the Error message Id which is to be thrown in
--  case of the error
--
--  set the value of p_msg_app_id to the application id of error message. If no
--  application id is specified default is taken as 'AR'
--
-- For more Reference please refer to "iReceivables Custom Customer Search"
-- White paper available on MetaLink
--
PROCEDURE search_custom_customer(
    p_user_name        IN VARCHAR2,
    p_is_external_user IN VARCHAR2,
    p_search_attribute IN VARCHAR2,
    p_search_keyword   IN VARCHAR2,
    p_org_id           IN NUMBER,
    p_org_name OUT NOCOPY              VARCHAR2,
    p_trx_number_col OUT NOCOPY        VARCHAR2,
    p_customer_name_col OUT NOCOPY     VARCHAR2,
    p_customer_number_col OUT NOCOPY   VARCHAR2,
    p_address_col OUT NOCOPY           VARCHAR2,
    p_address_type_col OUT NOCOPY      VARCHAR2,
    p_contact_name_col OUT NOCOPY      VARCHAR2,
    p_contact_phone_col OUT NOCOPY     VARCHAR2,
    p_account_summary_col OUT NOCOPY   VARCHAR2,
    p_attribute1_col OUT NOCOPY        VARCHAR2,
    p_attribute2_col OUT NOCOPY        VARCHAR2,
    p_attribute3_col OUT NOCOPY        VARCHAR2,
    p_attribute4_col OUT NOCOPY        VARCHAR2,
    p_attribute5_col OUT NOCOPY        VARCHAR2,
    p_search_result OUT NOCOPY         VARCHAR2,
    p_message_id OUT NOCOPY            VARCHAR2,
    p_msg_app_id OUT NOCOPY            VARCHAR2,
    p_customer_location_col OUT NOCOPY VARCHAR2 )
IS
  --Start - Added - R12 upgrade
  lc_search_keyword VARCHAR2 (100);
  lc_large_customer VARCHAR2(1) := 'N';
  ln_cust_account_id hz_cust_accounts.cust_account_id%TYPE;
  ls_success              VARCHAR2 (2);
  lc_fnd_log_debug_enable CONSTANT VARCHAR2 (30) := fnd_profile.VALUE ('AFLOG_ENABLED');
  --End - Added - R12 upgrade
BEGIN
  arp_global.init_global;
  --Start - Added - R12 upgrade
  IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
    fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer.begin', MESSAGE => 'ari_config.search_custom_customer+' );
    fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'p_user_name' || p_user_name || 'p_is_external_user' || p_is_external_user || 'p_search_attribute' || p_search_attribute || 'p_search_keyword' || p_search_keyword || 'p_org_id' || p_org_id );
  END IF;
  --DELETE FROM ar_irec_custom_cust_gt;
  DELETE FROM ar_irec_cstm_cust_gt_all;
  IF p_search_attribute                   = 'XX_AOPS_CUST_NO' THEN
    lc_search_keyword                    := trim(p_search_keyword)|| '-00001-A0';
    IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
      fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'p_search_attribute = XX_AOPS_CUST_NO' );
    END IF;
    IF p_search_keyword                   IS NULL THEN
      p_search_result                     := fnd_api.g_ret_sts_error;
      p_message_id                        := 'ARI_NO_SEARCH_CRITERIA';
      p_msg_app_id                        := 'AR';
    ELSIF ( INSTR (p_search_keyword, '*') <> 0 OR INSTR (p_search_keyword, '%') <> 0 OR INSTR (p_search_keyword, '?') <> 0 ) THEN
      p_search_result                     := fnd_api.g_ret_sts_error;
      p_message_id                        := 'QOT_CUST_NEED_FULL_ACNT_NUM';
      p_msg_app_id                        := 'QOT';
    ELSE
      BEGIN
        begin
          select cust_account_id 
          into   ln_cust_account_id
          from   hz_cust_accounts
          where  orig_system_reference = lc_search_keyword
          ;
          
          lc_large_customer := is_large_customer(ln_cust_account_id);
        exception
          when no_data_found then
            lc_large_customer := 'N';
        end;
        
        if ( lc_large_customer = 'N') then
        
          --INSERT INTO ar_irec_custom_cust_gt
          INSERT
          INTO ar_irec_cstm_cust_gt_all
            (
              customer_id,
              address_id,
              customer_number,
              customer_name,
              concatenated_address,
              attribute1,
              LOCATION
            )
            (
              (SELECT cust.cust_account_id customer_id,
                -1 address_id,
                cust.account_number customer_number,
                SUBSTRB (cust.account_name, 1, 50) customer_name,
                NULL concatenated_address,
                SUBSTR (cust.orig_system_reference, 1, 8 ) attribute1,
                'All Locations' LOCATION
              FROM hz_cust_accounts cust
              WHERE  cust.orig_system_reference = lc_search_keyword
              )
            UNION
              (
              --Query - Modified for R12 upgrade retrofit
          
              SELECT acct.cust_account_id customer_id,
                cas.cust_acct_site_id address_id,
                acct.account_number customer_number,
                SUBSTRB (acct.account_name, 1, 50) customer_name,
                SUBSTR (arp_addr_pkg.format_address (loc.address_style, loc.address1, loc.address2, loc.address3, loc.address4, loc.city, loc.county, loc.state, loc.province, loc.postal_code, loc.country ), 1, 255 ) concatenated_address,
                SUBSTR (acct.orig_system_reference, 1, 8 ) attribute1,
                csu.LOCATION
              FROM hz_cust_accounts    acct,
                hz_cust_acct_sites_all cas,
                hz_cust_site_uses_all  csu,
                hz_party_sites         hps,
                hz_locations           loc
              WHERE 1 = 1
              AND acct.cust_account_id    = cas.cust_account_id
              AND csu.cust_acct_site_id   = cas.cust_acct_site_id
              AND csu.site_use_code       = 'BILL_TO'
              AND csu.status              = 'A'
              AND cas.party_site_id       = hps.party_site_id
              AND cas.status              = 'A'
              AND cas.bill_to_flag        = 'P'
              AND hps.status              = 'A'
              AND loc.location_id         = hps.location_id
              AND ( acct.orig_system_reference = lc_search_keyword )
              )
            );
          else
            INSERT
            INTO ar_irec_cstm_cust_gt_all
              (
                customer_id,
                address_id,
                customer_number,
                customer_name,
                concatenated_address,
                attribute1,
                LOCATION
              )
              (
                (SELECT cust.cust_account_id customer_id,
                  -1 address_id,
                  cust.account_number customer_number,
                  SUBSTRB (cust.account_name, 1, 50) customer_name,
                  NULL concatenated_address,
                  SUBSTR (cust.orig_system_reference, 1, 8 ) attribute1,
                  'All Locations' LOCATION
                FROM hz_cust_accounts cust
                WHERE  cust.orig_system_reference = lc_search_keyword
                )
              );
          end if;
        IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
          fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'No.of Rows count' || SQL%ROWCOUNT );
        END IF;
        p_trx_number_col        := NULL;
        p_customer_name_col     := 'Customer Name';
        p_customer_number_col   := 'Billing ID';
        p_customer_location_col := 'Customer Location';
        p_address_col           := 'Address';
        p_address_type_col      := 'Address Type';
        p_contact_name_col      := 'Contact Name';
        p_contact_phone_col     := NULL;
        p_account_summary_col   := 'Account Detail';
        p_attribute1_col        := 'AOPS Customer Number';
        p_attribute2_col        := NULL;
        p_attribute3_col        := NULL;
        p_attribute4_col        := NULL;
        p_attribute5_col        := NULL;
        p_search_result         := fnd_api.g_ret_sts_success;
        p_message_id            := NULL;
        p_msg_app_id            := NULL;
      END;
    END IF;
  ELSIF p_search_attribute                = 'XX_CON_BILL_NO' THEN
    IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
      fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'p_search_attribute = XX_CON_BILL_NO' );
    END IF;
    IF p_search_keyword                   IS NULL THEN
      p_search_result                     := fnd_api.g_ret_sts_error;
      p_message_id                        := 'ARI_NO_SEARCH_CRITERIA';
      p_msg_app_id                        := 'AR';
    ELSIF ( INSTR (p_search_keyword, '*') <> 0 OR INSTR (p_search_keyword, '%') <> 0 OR INSTR (p_search_keyword, '?') <> 0 ) THEN
      p_search_result                     := fnd_api.g_ret_sts_error;
      p_message_id                        := 'QOT_CUST_NEED_FULL_ACNT_NUM';
      p_msg_app_id                        := 'QOT';
    ELSE
      BEGIN
        --select * from ar_irec_cstm_cust_gt_all
        --INSERT INTO ar_irec_custom_cust_gt
        INSERT
        INTO ar_irec_cstm_cust_gt_all
          (
            customer_id,
            -- TRX_NUMBER,
            customer_number,
            customer_trx_id,
            cash_receipt_id,
            Terms_sequence_number,
            Customer_name,
            -- ORG_ID,
            attribute2,
            Address_ID,
            concatenated_address,
            Location,
            attribute3,
            attribute4,
            attribute1
          )
        SELECT *
        FROM
          (SELECT DISTINCT cust.cust_account_id customer_id,
            cust.account_number customer_number,
            -- my_sites.trx_number Transaction_Number,
            my_sites.customer_trx_id,
            my_sites.receipt_id,
            my_sites.terms_sequence_number,
            SUBSTRB(PARTY.PARTY_NAME,1,50) CUSTOMER_NAME,
            -- '1',
            my_sites. Cons_Billing_Number,
            -1 address_id,
            NULL CONCATENATED_ADDRESS ,
            'All Locations' LOCATION,
            fnd_message.get_string('AR','ARI_ALL_ORGANIZATIONS') AS ORG_NAME,
            NULL CONTACT_PHONE ,
            NULL contact_name
          FROM HZ_CUST_ACCOUNTS CUST,
            HZ_PARTIES PARTY,
            FND_TERRITORIES_VL TERR,
            HZ_LOCATIONS LOC,
            HZ_CUST_SITE_USES SITES,
            HZ_CUST_ACCT_SITES ACCT_SITES,
            HZ_PARTY_SITES PARTY_SITES,
            (SELECT DISTINCT customer_site_use_id,
              -- aps.trx_number,
              aps.customer_trx_id,
              aps.cash_receipt_id receipt_id,
              aps.customer_id,
              aps.terms_sequence_number,
              aps.CLASS,
              aps.invoice_currency_code,
              aps.cash_receipt_id,
              trx.purchase_order,
              Cons_Billing_Number ,
              aps.org_id
            FROM ra_customer_trx_all trx,
              ar_payment_schedules_all aps,
              AR_CONS_INV_ALL arci ,
              AR_CONS_INV_TRX_ALL arctrx
            WHERE aps.class             IN ('INV', 'GUAR', 'CB')
            AND aps.customer_trx_id      = trx.customer_trx_id
            AND arci.cons_inv_id         = arctrx.cons_inv_id
            AND trx.trx_number           = arctrx.trx_number
            AND arci.Cons_Billing_Number = p_search_keyword
            ) my_sites
          WHERE 1                          = 1
          AND sites.site_use_id            = my_sites.customer_site_use_id
          AND ACCT_SITES.cust_acct_site_id = sites.CUST_ACCT_SITE_ID
          AND ACCT_SITES.party_site_id     = PARTY_SITES.party_site_id
          AND PARTY_SITES.location_id      = LOC.location_id
          AND cust.cust_account_id         = my_sites.customer_id
          AND cust.party_id                = party.party_id
          AND LOC.COUNTRY                  = TERR.TERRITORY_CODE(+)
          AND rownum                       = 1
          )
        -- WHERE CONCATENATED_ADDRESS IS NOT NULL
        UNION
          (SELECT DISTINCT cust.cust_account_id customer_id,
            cust.account_number customer_number,
            -- my_sites.trx_number Transaction_Number,
            my_sites.customer_trx_id,
            my_sites.receipt_id,
            my_sites.terms_sequence_number,
            SUBSTRB(PARTY.PARTY_NAME,1,50) CUSTOMER_NAME,
            -- '1',
            my_sites. Cons_Billing_Number,
            ACCT_SITES.cust_acct_site_id address_id,
            SUBSTR(ARP_ADDR_PKG.FORMAT_ADDRESS(LOC.ADDRESS_STYLE, LOC.ADDRESS1, LOC.ADDRESS2, LOC.ADDRESS3, LOC.ADDRESS4, LOC.CITY, LOC.COUNTY, LOC.STATE, LOC.PROVINCE, LOC.POSTAL_CODE, TERR.TERRITORY_SHORT_NAME),1,255) CONCATENATED_ADDRESS ,
            sites.LOCATION,
            mo_global.get_ou_name(my_sites.ORG_ID) AS ORG_NAME,
            NULL  CONTACT_PHONE,
            NULL contact_name
            --ari_utilities.get_phone(cust.cust_account_id, NULL, 'SELF_SERVICE_USER', 'GEN') CONTACT_PHONE,
           -- ari_utilities.get_contact(cust.cust_account_id,sites.CUST_ACCT_SITE_ID, 'SELF_SERVICE_USER') contact_name
          FROM HZ_CUST_ACCOUNTS CUST,
            HZ_PARTIES PARTY,
            FND_TERRITORIES_VL TERR,
            HZ_LOCATIONS LOC,
            HZ_CUST_SITE_USES SITES,
            HZ_CUST_ACCT_SITES ACCT_SITES,
            HZ_PARTY_SITES PARTY_SITES,
            (SELECT DISTINCT customer_site_use_id,
              -- aps.trx_number,
              aps.customer_trx_id,
              aps.cash_receipt_id receipt_id,
              aps.customer_id,
              aps.terms_sequence_number,
              aps.CLASS,
              aps.invoice_currency_code,
              aps.cash_receipt_id,
              trx.purchase_order,
              Cons_Billing_Number ,
              aps.org_id
            FROM ra_customer_trx_all trx,
              ar_payment_schedules_all aps,
              AR_CONS_INV_ALL arci ,
              AR_CONS_INV_TRX_ALL arctrx
            WHERE aps.class             IN ('INV', 'GUAR', 'CB')
            AND aps.customer_trx_id      = trx.customer_trx_id
            AND arci.cons_inv_id         = arctrx.cons_inv_id
            AND trx.trx_number           = arctrx.trx_number
            AND arci.Cons_Billing_Number = p_search_keyword
            ) my_sites
          WHERE 1                          = 1
          AND sites.site_use_id            = my_sites.customer_site_use_id
          AND ACCT_SITES.cust_acct_site_id = sites.CUST_ACCT_SITE_ID
          AND ACCT_SITES.party_site_id     = PARTY_SITES.party_site_id
          AND PARTY_SITES.location_id      = LOC.location_id
          AND cust.cust_account_id         = my_sites.customer_id
          AND cust.party_id                = party.party_id
          AND LOC.COUNTRY                  = TERR.TERRITORY_CODE(+)
          AND rownum                       = 1
          ) ;
        IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
          fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'No.of Rows count' || SQL%ROWCOUNT );
        END IF;
        p_attribute3_col := 'Organization';
        --p_attribute2_col := 'Consolidate Bill';
        --p_trx_number_col        := 'Trasaction Number';
        p_customer_name_col   := 'Customer Name';
        p_customer_number_col := 'Billing ID';
        --P_customer_trx_id_col      := 'Customer Trx Id';
        --p_customer_id_col   := 'Customer ID';
        -- p_customer_location_col := 'Customer Location';
        p_address_col      := 'Address';
        p_address_type_col := 'Address Type';
        --p_contact_name_col      := 'Primary Contact';
        --p_contact_phone_col     := 'Contact Phone';
        p_account_summary_col := 'Account Detail';
        p_attribute1_col      := 'Primary Contact';
        p_attribute3_col      := 'Organization';
        p_attribute4_col      := 'Contact Phone';
        --p_attribute5_col        := NULL;
        p_search_result := fnd_api.g_ret_sts_success;
        p_message_id    := NULL;
        p_msg_app_id    := NULL;
      END;
    END IF;
  ELSIF p_search_attribute                = 'XX_DEPT' THEN
    IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
      fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'p_search_attribute = XX_DEPT' );
    END IF;
    BEGIN
      lc_search_keyword                 := p_search_keyword;
      IF INSTR (lc_search_keyword, '%') <= 0 THEN
        lc_search_keyword               := lc_search_keyword || '%';
      END IF;
      BEGIN
        SELECT acct.cust_account_id
        INTO ln_cust_account_id
        FROM hz_relationships rel,
          fnd_user fnd,
          hz_cust_accounts acct
        WHERE rel.party_id   = fnd.customer_id
        AND rel.subject_id   = acct.party_id
        AND rel.subject_type = 'ORGANIZATION'
        AND fnd.user_id      = fnd_global.user_id;
      EXCEPTION
      WHEN OTHERS THEN
        p_search_result := fnd_api.g_ret_sts_error;
        p_message_id    := 'XX_ARI_ACCOUNT_NOT_FOUND';
        p_msg_app_id    := 'AR';
        RETURN;
      END;
      --INSERT INTO ar_irec_custom_cust_gt
      INSERT
      INTO ar_irec_cstm_cust_gt_all
        (
          customer_id,
          address_id,
          customer_number,
          customer_name,
          concatenated_address,
          trx_number,
          customer_trx_id,
          cash_receipt_id,
          terms_sequence_number,
          CLASS,
          invoice_currency_code,
          attribute1,
          attribute2,
          attribute3,
          attribute4
        )
        (
          (
          --Query - Modified for R12 upgrade retrofit
          SELECT cust.cust_account_id customer_id,
            -1,
            cust.account_number customer_number,
            SUBSTRB (party.party_name, 1, 50) customer_name,
            NULL concatenated_address,
            my_sites.trx_number,
            my_sites.customer_trx_id,
            my_sites.cash_receipt_id cash_receipt_id,
            my_sites.terms_sequence_number terms_sequence_number,
            my_sites.CLASS trx_class,
            my_sites.invoice_currency_code,
            my_sites.purchase_order,
            my_sites.cost_center_dept,
            my_sites.desk_del_addr,
            my_sites.release_number
          FROM hz_cust_accounts cust,
            hz_parties party,
            fnd_territories_vl terr,
            --ra_addresses_all addr,
            hz_cust_acct_sites acct, --hz_cust_acct_sites_all acct,
            hz_party_sites party_site,
            --apps.hz_loc_assignments loc_assign,
            hz_locations loc,
            hz_cust_site_uses sites, --hz_cust_site_uses_all sites,
            (SELECT DISTINCT customer_site_use_id,
              aps.trx_number,
              aps.customer_id,
              aps.customer_trx_id,
              aps.terms_sequence_number,
              aps.CLASS,
              aps.invoice_currency_code,
              aps.cash_receipt_id,
              trx.purchase_order,
              oha.cost_center_dept,
              oha.desk_del_addr,
              oha.release_number
            FROM ra_customer_trx_all trx,
              xx_om_header_attributes_v oha,									--Retrofit NAIT-37762
              ar_payment_schedules_all aps
            WHERE trx.bill_to_customer_id = ln_cust_account_id
            AND trx.attribute14           = oha.header_id
            AND aps.customer_trx_id       = trx.customer_trx_id
            AND oha.cost_center_dept LIKE lc_search_keyword
            ) my_sites
          WHERE 1 = 1
            --AND addr.address_id = sites.cust_acct_site_id
            --AND addr.address_id = sites.cust_acct_site_id
          AND cust.party_id           = party.party_id
          AND acct.party_site_id      = party_site.party_site_id
          AND cust.cust_account_id    = acct.cust_account_id
          AND party_site.party_id     = cust.party_id
          AND party_site.party_id     = party.party_id
          AND sites.cust_acct_site_id = acct.cust_acct_site_id
          AND acct.party_site_id      = party_site.party_site_id
          AND loc.country             = terr.territory_code(+)
          AND loc.location_id         = party_site.location_id
            --                    AND loc.location_id = loc_assign.location_id
            --                    AND NVL (acct.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND NVL (sites.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND acct.org_id = p_org_id
            --AND addr.customer_id = cust.cust_account_id
            --AND addr.country = terr.territory_code(+)
          AND sites.site_use_id    = my_sites.customer_site_use_id
          AND cust.cust_account_id = my_sites.customer_id
          )
        UNION
          (
          --Query - Modified for R12 upgrade retrofit
          SELECT cust.cust_account_id customer_id,
            --addr.address_id,
            acct.cust_acct_site_id address_id,
            cust.account_number customer_number,
            SUBSTRB (party.party_name, 1, 50) customer_name,
            /*
            SUBSTR
            (arp_addr_pkg.format_address
            (addr.address_style,
            addr.address1,
            addr.address2,
            addr.address3,
            addr.address4,
            addr.city,
            addr.county,
            addr.state,
            addr.province,
            addr.postal_code,
            terr.territory_short_name
            ),
            1,
            255
            ) concatenated_address,*/
            SUBSTR (arp_addr_pkg.format_address (loc.address_style, loc.address1, loc.address2, loc.address3, loc.address4, loc.city, loc.county, loc.state, loc.province, loc.postal_code, terr.territory_short_name ), 1, 255 ) concatenated_address,
            my_sites.trx_number,
            my_sites.customer_trx_id,
            my_sites.cash_receipt_id cash_receipt_id,
            my_sites.terms_sequence_number terms_sequence_number,
            my_sites.CLASS trx_class,
            my_sites.invoice_currency_code,
            my_sites.purchase_order,
            my_sites.cost_center_dept,
            my_sites.desk_del_addr,
            my_sites.release_number
          FROM hz_cust_accounts cust,
            hz_parties party,
            fnd_territories_vl terr,
            --ra_addresses_all addr,
            hz_cust_acct_sites acct, --hz_cust_acct_sites_all acct,
            hz_party_sites party_site,
            --apps.hz_loc_assignments loc_assign,
            hz_locations loc,
            hz_cust_site_uses sites, --hz_cust_site_uses_all sites,
            (SELECT DISTINCT customer_site_use_id,
              aps.trx_number,
              aps.customer_id,
              aps.customer_trx_id,
              aps.terms_sequence_number,
              aps.CLASS,
              aps.invoice_currency_code,
              aps.cash_receipt_id,
              trx.purchase_order,
              oha.cost_center_dept,
              oha.desk_del_addr,
              oha.release_number
            FROM ra_customer_trx_all trx,
              xx_om_header_attributes_v oha,									--Retrofit NAIT-37762
              ar_payment_schedules_all aps
            WHERE trx.bill_to_customer_id = ln_cust_account_id
            AND trx.attribute14           = oha.header_id
            AND aps.customer_trx_id       = trx.customer_trx_id
            AND oha.cost_center_dept LIKE lc_search_keyword
            ) my_sites
          WHERE 1 = 1
            --AND addr.address_id = sites.cust_acct_site_id
            --AND addr.address_id = sites.cust_acct_site_id
          AND cust.party_id = party.party_id
            --AND addr.customer_id = cust.cust_account_id
            --AND addr.country = terr.territory_code(+)
          AND cust.cust_account_id    = acct.cust_account_id
          AND sites.cust_acct_site_id = acct.cust_acct_site_id
          AND acct.party_site_id      = party_site.party_site_id
          AND loc.country             = terr.territory_code(+)
          AND loc.location_id         = party_site.location_id
            --                    AND loc.location_id = loc_assign.location_id
            --                    AND NVL (acct.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND NVL (sites.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND acct.org_id = p_org_id
          AND sites.site_use_id    = my_sites.customer_site_use_id
          AND cust.cust_account_id = my_sites.customer_id
          )
        );
      p_search_result       := fnd_api.g_ret_sts_success;
      p_message_id          := NULL;
      p_msg_app_id          := NULL;
      p_trx_number_col      := 'Transaction Number';
      p_customer_name_col   := 'Customer Name';
      p_customer_number_col := 'Billing ID';
      p_address_col         := 'Address';
      p_address_type_col    := 'Address Type';
      p_contact_name_col    := 'Contact Name';
      p_contact_phone_col   := 'Contact Phone';
      p_account_summary_col := 'Account Detail';
      xx_irec_search_pkg.get_soft_headers (ln_cust_account_id, p_attribute2_col, p_attribute1_col, p_attribute4_col, p_attribute3_col, ls_success );
      IF ls_success      <> 'Y' THEN
        p_attribute1_col := 'Purchase Order';
        p_attribute2_col := 'Department';
        p_attribute3_col := 'Desktop';
        p_attribute4_col := 'Release';
      END IF;
      p_attribute5_col := NULL;
    END;
  ELSIF p_search_attribute                = 'XX_PO' THEN
    IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
      fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'p_search_attribute = XX_PO' );
    END IF;
    BEGIN
      lc_search_keyword    := p_search_keyword;
      IF lc_search_keyword IS NULL OR INSTR (lc_search_keyword, '%') <= 0 THEN
        lc_search_keyword  := lc_search_keyword || '%';
      END IF;
      IF LENGTH (lc_search_keyword) < 2 THEN
        p_search_result            := fnd_api.g_ret_sts_error;
        p_message_id               := 'XX_ARI_SEARCH_BY_TOO_SHORT';
        p_msg_app_id               := 'AR';
        RETURN;
      END IF;
      BEGIN
        SELECT acct.cust_account_id
        INTO ln_cust_account_id
        FROM hz_relationships rel,
          fnd_user fnd,
          hz_cust_accounts acct
        WHERE rel.party_id   = fnd.customer_id
        AND rel.subject_id   = acct.party_id
        AND rel.subject_type = 'ORGANIZATION'
        AND fnd.user_id      = fnd_global.user_id;
      EXCEPTION
      WHEN OTHERS THEN
        p_search_result := fnd_api.g_ret_sts_error;
        p_message_id    := 'XX_ARI_ACCOUNT_NOT_FOUND';
        p_msg_app_id    := 'AR';
        RETURN;
      END;
      --INSERT INTO ar_irec_custom_cust_gt
      INSERT
      INTO ar_irec_cstm_cust_gt_all
        (
          customer_id,
          address_id,
          customer_number,
          customer_name,
          concatenated_address,
          trx_number,
          customer_trx_id,
          cash_receipt_id,
          terms_sequence_number,
          CLASS,
          invoice_currency_code,
          attribute1,
          attribute2,
          attribute3,
          attribute4
        )
        (
          (
          --Query - Modified for R12 upgrade retrofit
          SELECT cust.cust_account_id customer_id,
            -1,
            cust.account_number customer_number,
            SUBSTRB (party.party_name, 1, 50) customer_name,
            NULL concatenated_address,
            my_sites.trx_number,
            my_sites.customer_trx_id,
            my_sites.cash_receipt_id cash_receipt_id,
            my_sites.terms_sequence_number terms_sequence_number,
            my_sites.CLASS trx_class,
            my_sites.invoice_currency_code,
            my_sites.purchase_order,
            my_sites.cost_center_dept,
            my_sites.desk_del_addr,
            my_sites.release_number
          FROM hz_cust_accounts cust,
            hz_parties party,
            fnd_territories_vl terr,
            --ra_addresses_all addr,
            hz_cust_acct_sites acct, --hz_cust_acct_sites_all acct,
            hz_party_sites party_site,
            --apps.hz_loc_assignments loc_assign,
            hz_locations loc,
            hz_cust_site_uses sites, --hz_cust_site_uses_all sites,
            (SELECT DISTINCT customer_site_use_id,
              aps.trx_number,
              aps.customer_id,
              aps.customer_trx_id,
              aps.terms_sequence_number,
              aps.CLASS,
              aps.invoice_currency_code,
              aps.cash_receipt_id,
              trx.purchase_order,
              oha.cost_center_dept,
              oha.desk_del_addr,
              oha.release_number
            FROM ra_customer_trx_all trx,
              xx_om_header_attributes_v oha,									--Retrofit NAIT-37762
              ar_payment_schedules_all aps
            WHERE trx.bill_to_customer_id = ln_cust_account_id
            AND trx.attribute14           = oha.header_id
            AND aps.customer_trx_id       = trx.customer_trx_id
            AND trx.purchase_order LIKE lc_search_keyword
            ) my_sites
          WHERE 1 = 1
            --AND addr.address_id = sites.cust_acct_site_id
            --AND addr.address_id = sites.cust_acct_site_id
          AND cust.party_id           = party.party_id
          AND cust.cust_account_id    = acct.cust_account_id
          AND sites.cust_acct_site_id = acct.cust_acct_site_id
          AND acct.party_site_id      = party_site.party_site_id
          AND loc.country             = terr.territory_code(+)
          AND loc.location_id         = party_site.location_id
            --                    AND loc.location_id = loc_assign.location_id
            --                    AND NVL (acct.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND NVL (sites.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND acct.org_id = p_org_id
            --AND addr.customer_id = cust.cust_account_id
            --AND addr.country = terr.territory_code(+)
          AND sites.site_use_id    = my_sites.customer_site_use_id
          AND cust.cust_account_id = my_sites.customer_id
          )
        UNION
          (
          --Query - Modified for R12 upgrade retrofit
          SELECT cust.cust_account_id customer_id,
            --addr.address_id,
            acct.cust_acct_site_id address_id,
            cust.account_number customer_number,
            SUBSTRB (party.party_name, 1, 50) customer_name,
            /*
            SUBSTR
            (arp_addr_pkg.format_address
            (addr.address_style,
            addr.address1,
            addr.address2,
            addr.address3,
            addr.address4,
            addr.city,
            addr.county,
            addr.state,
            addr.province,
            addr.postal_code,
            terr.territory_short_name
            ),
            1,
            255
            ) concatenated_address,*/
            SUBSTR (arp_addr_pkg.format_address (loc.address_style, loc.address1, loc.address2, loc.address3, loc.address4, loc.city, loc.county, loc.state, loc.province, loc.postal_code, terr.territory_short_name ), 1, 255 ) concatenated_address,
            my_sites.trx_number,
            my_sites.customer_trx_id,
            my_sites.cash_receipt_id cash_receipt_id,
            my_sites.terms_sequence_number terms_sequence_number,
            my_sites.CLASS trx_class,
            my_sites.invoice_currency_code,
            my_sites.purchase_order,
            my_sites.cost_center_dept,
            my_sites.desk_del_addr,
            my_sites.release_number
          FROM hz_cust_accounts cust,
            hz_parties party,
            fnd_territories_vl terr,
            --ra_addresses_all addr,
            hz_cust_acct_sites acct, --hz_cust_acct_sites_all acct,
            hz_party_sites party_site,
            --apps.hz_loc_assignments loc_assign,
            hz_locations loc,
            hz_cust_site_uses sites, --hz_cust_site_uses_all sites,
            (SELECT DISTINCT customer_site_use_id,
              aps.trx_number,
              aps.customer_id,
              aps.customer_trx_id,
              aps.terms_sequence_number,
              aps.CLASS,
              aps.invoice_currency_code,
              aps.cash_receipt_id,
              trx.purchase_order,
              oha.cost_center_dept,
              oha.desk_del_addr,
              oha.release_number
            FROM ra_customer_trx_all trx,
              xx_om_header_attributes_v oha,									--Retrofit NAIT-37762
              ar_payment_schedules_all aps
            WHERE trx.bill_to_customer_id = ln_cust_account_id
            AND trx.attribute14           = oha.header_id
            AND aps.customer_trx_id       = trx.customer_trx_id
            AND purchase_order LIKE lc_search_keyword
            ) my_sites
          WHERE 1 = 1
            --AND addr.address_id = sites.cust_acct_site_id
            --AND addr.address_id = sites.cust_acct_site_id
          AND cust.party_id           = party.party_id
          AND cust.cust_account_id    = acct.cust_account_id
          AND sites.cust_acct_site_id = acct.cust_acct_site_id
          AND acct.party_site_id      = party_site.party_site_id
          AND party_site.party_id     = cust.party_id
          AND party_site.party_id     = party.party_id
          AND loc.country             = terr.territory_code(+)
          AND loc.location_id         = party_site.location_id
            --                    AND loc.location_id = loc_assign.location_id
            --                    AND NVL (acct.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND NVL (sites.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND acct.org_id = p_org_id
            --AND addr.customer_id = cust.cust_account_id
            --AND addr.country = terr.territory_code(+)
          AND sites.site_use_id    = my_sites.customer_site_use_id
          AND cust.cust_account_id = my_sites.customer_id
          )
        );
      p_search_result       := fnd_api.g_ret_sts_success;
      p_message_id          := NULL;
      p_msg_app_id          := NULL;
      p_trx_number_col      := 'Transaction Number';
      p_customer_name_col   := 'Customer Name';
      p_customer_number_col := 'Billing ID';
      p_address_col         := 'Address';
      p_address_type_col    := 'Address Type';
      p_contact_name_col    := 'Contact Name';
      p_contact_phone_col   := 'Contact Phone';
      p_account_summary_col := 'Account Detail';
      xx_irec_search_pkg.get_soft_headers (ln_cust_account_id, p_attribute2_col, p_attribute1_col, p_attribute4_col, p_attribute3_col, ls_success );
      IF ls_success      <> 'Y' THEN
        p_attribute1_col := 'Purchase Order';
        p_attribute2_col := 'Department';
        p_attribute3_col := 'Desktop';
        p_attribute4_col := 'Release';
      END IF;
    END;
  ELSIF p_search_attribute                = 'XX_DESKTOP' THEN
    IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
      fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'p_search_attribute = XX_DESKTOP' );
    END IF;
    BEGIN
      lc_search_keyword                 := p_search_keyword;
      IF INSTR (lc_search_keyword, '%') <= 0 THEN
        lc_search_keyword               := lc_search_keyword || '%';
      END IF;
      BEGIN
        SELECT acct.cust_account_id
        INTO ln_cust_account_id
        FROM hz_relationships rel,
          fnd_user fnd,
          hz_cust_accounts acct
        WHERE rel.party_id   = fnd.customer_id
        AND rel.subject_id   = acct.party_id
        AND rel.subject_type = 'ORGANIZATION'
        AND fnd.user_id      = fnd_global.user_id;
      EXCEPTION
      WHEN OTHERS THEN
        p_search_result := fnd_api.g_ret_sts_error;
        p_message_id    := 'XX_ARI_ACCOUNT_NOT_FOUND';
        p_msg_app_id    := 'AR';
        RETURN;
      END;
      --INSERT INTO ar_irec_custom_cust_gt
      INSERT
      INTO ar_irec_cstm_cust_gt_all
        (
          customer_id,
          address_id,
          customer_number,
          customer_name,
          concatenated_address,
          trx_number,
          customer_trx_id,
          cash_receipt_id,
          terms_sequence_number,
          CLASS,
          invoice_currency_code,
          attribute1,
          attribute2,
          attribute3,
          attribute4
        )
        (
          (
          --Query - Modified for R12 upgrade retrofit
          SELECT cust.cust_account_id customer_id,
            -1,
            cust.account_number customer_number,
            SUBSTRB (party.party_name, 1, 50) customer_name,
            NULL concatenated_address,
            my_sites.trx_number,
            my_sites.customer_trx_id,
            my_sites.cash_receipt_id cash_receipt_id,
            my_sites.terms_sequence_number terms_sequence_number,
            my_sites.CLASS trx_class,
            my_sites.invoice_currency_code,
            my_sites.purchase_order,
            my_sites.cost_center_dept,
            my_sites.desk_del_addr,
            my_sites.release_number
          FROM hz_cust_accounts cust,
            hz_parties party,
            fnd_territories_vl terr,
            --ra_addresses_all addr,
            hz_cust_acct_sites acct, --hz_cust_acct_sites_all acct,
            hz_party_sites party_site,
            --apps.hz_loc_assignments loc_assign,
            hz_locations loc,
            hz_cust_site_uses sites, --hz_cust_site_uses_all sites,
            (SELECT DISTINCT customer_site_use_id,
              aps.trx_number,
              aps.customer_id,
              aps.customer_trx_id,
              aps.terms_sequence_number,
              aps.CLASS,
              aps.invoice_currency_code,
              aps.cash_receipt_id,
              trx.purchase_order,
              oha.cost_center_dept,
              oha.desk_del_addr,
              oha.release_number
            FROM ra_customer_trx_all trx,
              xx_om_header_attributes_v oha,									--Retrofit NAIT-37762
              ar_payment_schedules_all aps
            WHERE trx.bill_to_customer_id = ln_cust_account_id
            AND trx.attribute14           = oha.header_id
            AND aps.customer_trx_id       = trx.customer_trx_id
            AND oha.desk_del_addr LIKE lc_search_keyword
            ) my_sites
          WHERE 1 = 1
            --AND addr.address_id = sites.cust_acct_site_id
            --AND addr.address_id = sites.cust_acct_site_id
          AND cust.party_id = party.party_id
            --AND addr.customer_id = cust.cust_account_id
            --AND addr.country = terr.territory_code(+)
          AND cust.cust_account_id    = acct.cust_account_id
          AND sites.cust_acct_site_id = acct.cust_acct_site_id
          AND acct.party_site_id      = party_site.party_site_id
          AND party_site.party_id     = cust.party_id
          AND party_site.party_id     = party.party_id
          AND loc.country             = terr.territory_code(+)
          AND loc.location_id         = party_site.location_id
            --                    AND loc.location_id = loc_assign.location_id
            --                    AND NVL (acct.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND NVL (sites.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND acct.org_id = p_org_id
          AND sites.site_use_id    = my_sites.customer_site_use_id
          AND cust.cust_account_id = my_sites.customer_id
          )
        UNION
          (
          --Query - Modified for R12 upgrade retrofit
          SELECT cust.cust_account_id customer_id,
            --addr.address_id,
            acct.cust_acct_site_id address_id,
            cust.account_number customer_number,
            SUBSTRB (party.party_name, 1, 50) customer_name,
            /*
            SUBSTR
            (arp_addr_pkg.format_address
            (addr.address_style,
            addr.address1,
            addr.address2,
            addr.address3,
            addr.address4,
            addr.city,
            addr.county,
            addr.state,
            addr.province,
            addr.postal_code,
            terr.territory_short_name
            ),
            1,
            255
            ) concatenated_address,
            */
            SUBSTR (arp_addr_pkg.format_address (loc.address_style, loc.address1, loc.address2, loc.address3, loc.address4, loc.city, loc.county, loc.state, loc.province, loc.postal_code, terr.territory_short_name ), 1, 255 ) concatenated_address,
            my_sites.trx_number,
            my_sites.customer_trx_id,
            my_sites.cash_receipt_id cash_receipt_id,
            my_sites.terms_sequence_number terms_sequence_number,
            my_sites.CLASS trx_class,
            my_sites.invoice_currency_code,
            my_sites.purchase_order,
            my_sites.cost_center_dept,
            my_sites.desk_del_addr,
            my_sites.release_number
          FROM hz_cust_accounts cust,
            hz_parties party,
            fnd_territories_vl terr,
            --ra_addresses_all addr,
            hz_cust_acct_sites acct, --hz_cust_acct_sites_all acct,
            hz_party_sites party_site,
            --apps.hz_loc_assignments loc_assign,
            hz_locations loc,
            hz_cust_site_uses sites, --hz_cust_site_uses_all sites,
            (SELECT DISTINCT customer_site_use_id,
              aps.trx_number,
              aps.customer_id,
              aps.customer_trx_id,
              aps.terms_sequence_number,
              aps.CLASS,
              aps.invoice_currency_code,
              aps.cash_receipt_id,
              trx.purchase_order,
              oha.cost_center_dept,
              oha.desk_del_addr,
              oha.release_number
            FROM ra_customer_trx_all trx,
              xx_om_header_attributes_v oha,									--Retrofit NAIT-37762
              ar_payment_schedules_all aps
            WHERE trx.bill_to_customer_id = ln_cust_account_id
            AND trx.attribute14           = oha.header_id
            AND aps.customer_trx_id       = trx.customer_trx_id
            AND oha.desk_del_addr LIKE lc_search_keyword
            ) my_sites
          WHERE 1 = 1
            --AND addr.address_id = sites.cust_acct_site_id
            --AND addr.address_id = sites.cust_acct_site_id
          AND cust.party_id = party.party_id
            --AND addr.customer_id = cust.cust_account_id
            --AND addr.country = terr.territory_code(+)
          AND cust.cust_account_id    = acct.cust_account_id
          AND sites.cust_acct_site_id = acct.cust_acct_site_id
          AND acct.party_site_id      = party_site.party_site_id
          AND party_site.party_id     = cust.party_id
          AND party_site.party_id     = party.party_id
          AND loc.country             = terr.territory_code(+)
          AND loc.location_id         = party_site.location_id
            --                    AND loc.location_id = loc_assign.location_id
            --                    AND NVL (acct.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND NVL (sites.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND acct.org_id = p_org_id
          AND sites.site_use_id    = my_sites.customer_site_use_id
          AND cust.cust_account_id = my_sites.customer_id
          )
        );
      p_search_result       := fnd_api.g_ret_sts_success;
      p_message_id          := NULL;
      p_msg_app_id          := NULL;
      p_trx_number_col      := 'Transaction Number';
      p_customer_name_col   := 'Customer Name';
      p_customer_number_col := 'Billing ID';
      p_address_col         := 'Address';
      p_address_type_col    := 'Address Type';
      p_contact_name_col    := 'Contact Name';
      p_contact_phone_col   := 'Contact Phone';
      p_account_summary_col := 'Account Detail';
      xx_irec_search_pkg.get_soft_headers (ln_cust_account_id, p_attribute2_col, p_attribute1_col, p_attribute4_col, p_attribute3_col, ls_success );
      IF ls_success      <> 'Y' THEN
        p_attribute1_col := 'Purchase Order';
        p_attribute2_col := 'Department';
        p_attribute3_col := 'Desktop';
        p_attribute4_col := 'Release';
      END IF;
    END;
  ELSIF p_search_attribute                = 'XX_RELEASE' THEN
    IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
      fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'p_search_attribute = XX_RELEASE' );
    END IF;
    BEGIN
      lc_search_keyword                 := p_search_keyword;
      IF INSTR (lc_search_keyword, '%') <= 0 THEN
        lc_search_keyword               := lc_search_keyword || '%';
      END IF;
      BEGIN
        SELECT acct.cust_account_id
        INTO ln_cust_account_id
        FROM hz_relationships rel,
          fnd_user fnd,
          hz_cust_accounts acct
        WHERE rel.party_id   = fnd.customer_id
        AND rel.subject_id   = acct.party_id
        AND rel.subject_type = 'ORGANIZATION'
        AND fnd.user_id      = fnd_global.user_id;
      EXCEPTION
      WHEN OTHERS THEN
        p_search_result := fnd_api.g_ret_sts_error;
        p_message_id    := 'XX_ARI_ACCOUNT_NOT_FOUND';
        p_msg_app_id    := 'AR';
        RETURN;
      END;
      --INSERT INTO ar_irec_custom_cust_gt
      INSERT
      INTO ar_irec_cstm_cust_gt_all
        (
          customer_id,
          address_id,
          customer_number,
          customer_name,
          concatenated_address,
          trx_number,
          customer_trx_id,
          cash_receipt_id,
          terms_sequence_number,
          CLASS,
          invoice_currency_code,
          attribute1,
          attribute2,
          attribute3,
          attribute4
        )
        (
          (
          --Query - Modified for R12 upgrade retrofit
          SELECT cust.cust_account_id customer_id,
            -1,
            cust.account_number customer_number,
            SUBSTRB (party.party_name, 1, 50) customer_name,
            NULL concatenated_address,
            my_sites.trx_number,
            my_sites.customer_trx_id,
            my_sites.cash_receipt_id cash_receipt_id,
            my_sites.terms_sequence_number terms_sequence_number,
            my_sites.CLASS trx_class,
            my_sites.invoice_currency_code,
            my_sites.purchase_order,
            my_sites.cost_center_dept,
            my_sites.desk_del_addr,
            my_sites.release_number
          FROM hz_cust_accounts cust,
            hz_parties party,
            fnd_territories_vl terr,
            --ra_addresses_all addr,
            hz_cust_acct_sites acct, --hz_cust_acct_sites_all acct,
            hz_party_sites party_site,
            --apps.hz_loc_assignments loc_assign,
            hz_locations loc,
            hz_cust_site_uses sites, --hz_cust_site_uses_all sites,
            (SELECT DISTINCT customer_site_use_id,
              aps.trx_number,
              aps.customer_id,
              aps.customer_trx_id,
              aps.terms_sequence_number,
              aps.CLASS,
              aps.invoice_currency_code,
              aps.cash_receipt_id,
              trx.purchase_order,
              oha.cost_center_dept,
              oha.desk_del_addr,
              oha.release_number
            FROM ra_customer_trx_all trx,
              xx_om_header_attributes_v oha,									--Retrofit NAIT-37762
              ar_payment_schedules_all aps
            WHERE trx.bill_to_customer_id = ln_cust_account_id
            AND trx.attribute14           = oha.header_id
            AND aps.customer_trx_id       = trx.customer_trx_id
            AND oha.release_number LIKE lc_search_keyword
            ) my_sites
          WHERE 1 = 1
            --AND addr.address_id = sites.cust_acct_site_id
            --AND addr.address_id = sites.cust_acct_site_id
          AND cust.party_id           = party.party_id
          AND cust.cust_account_id    = acct.cust_account_id
          AND sites.cust_acct_site_id = acct.cust_acct_site_id
          AND acct.party_site_id      = party_site.party_site_id
          AND party_site.party_id     = cust.party_id
          AND party_site.party_id     = party.party_id
          AND loc.country             = terr.territory_code(+)
          AND loc.location_id         = party_site.location_id
            --                    AND loc.location_id = loc_assign.location_id
            --                    AND NVL (acct.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND NVL (sites.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND acct.org_id = p_org_id
            --AND addr.customer_id = cust.cust_account_id
            --AND addr.country = terr.territory_code(+)
          AND sites.site_use_id    = my_sites.customer_site_use_id
          AND cust.cust_account_id = my_sites.customer_id
          )
        UNION
          (
          --Query - Modified for R12 upgrade retrofit
          SELECT cust.cust_account_id customer_id,
            --addr.address_id,
            acct.cust_acct_site_id address_id,
            cust.account_number customer_number,
            SUBSTRB (party.party_name, 1, 50) customer_name,
            /*
            SUBSTR
            (arp_addr_pkg.format_address
            (addr.address_style,
            addr.address1,
            addr.address2,
            addr.address3,
            addr.address4,
            addr.city,
            addr.county,
            addr.state,
            addr.province,
            addr.postal_code,
            terr.territory_short_name
            ),
            1,
            255
            ) concatenated_address,*/
            SUBSTR (arp_addr_pkg.format_address (loc.address_style, loc.address1, loc.address2, loc.address3, loc.address4, loc.city, loc.county, loc.state, loc.province, loc.postal_code, terr.territory_short_name ), 1, 255 ) concatenated_address,
            my_sites.trx_number,
            my_sites.customer_trx_id,
            my_sites.cash_receipt_id cash_receipt_id,
            my_sites.terms_sequence_number terms_sequence_number,
            my_sites.CLASS trx_class,
            my_sites.invoice_currency_code,
            my_sites.purchase_order,
            my_sites.cost_center_dept,
            my_sites.desk_del_addr,
            my_sites.release_number
          FROM hz_cust_accounts cust,
            hz_parties party,
            fnd_territories_vl terr,
            --ra_addresses_all addr,
            hz_cust_acct_sites acct, --hz_cust_acct_sites_all acct,
            hz_party_sites party_site,
            --apps.hz_loc_assignments loc_assign,
            hz_locations loc,
            hz_cust_site_uses sites, --hz_cust_site_uses_all sites,
            (SELECT DISTINCT customer_site_use_id,
              aps.trx_number,
              aps.customer_id,
              aps.customer_trx_id,
              aps.terms_sequence_number,
              aps.CLASS,
              aps.invoice_currency_code,
              aps.cash_receipt_id,
              trx.purchase_order,
              oha.cost_center_dept,
              oha.desk_del_addr,
              oha.release_number
            FROM ra_customer_trx_all trx,
              xx_om_header_attributes_v oha,									--Retrofit NAIT-37762
              ar_payment_schedules_all aps
            WHERE trx.bill_to_customer_id = ln_cust_account_id
            AND trx.attribute14           = oha.header_id
            AND aps.customer_trx_id       = trx.customer_trx_id
            AND oha.release_number LIKE lc_search_keyword
            ) my_sites
          WHERE 1 = 1
            --AND addr.address_id = sites.cust_acct_site_id
            --AND addr.address_id = sites.cust_acct_site_id
          AND cust.party_id           = party.party_id
          AND cust.cust_account_id    = acct.cust_account_id
          AND sites.cust_acct_site_id = acct.cust_acct_site_id
          AND acct.party_site_id      = party_site.party_site_id
          AND party_site.party_id     = cust.party_id
          AND party_site.party_id     = party.party_id
          AND loc.country             = terr.territory_code(+)
          AND loc.location_id         = party_site.location_id
            --                    AND loc.location_id = loc_assign.location_id
            --                    AND NVL (acct.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND NVL (sites.org_id, -99) = NVL (loc_assign.org_id, -99)
            --                    AND acct.org_id = p_org_id
            --AND addr.customer_id = cust.cust_account_id
            --AND addr.country = terr.territory_code(+)
          AND sites.site_use_id    = my_sites.customer_site_use_id
          AND cust.cust_account_id = my_sites.customer_id
          )
        );
      p_search_result       := fnd_api.g_ret_sts_success;
      p_message_id          := NULL;
      p_msg_app_id          := NULL;
      p_trx_number_col      := 'Transaction Number';
      p_customer_name_col   := 'Customer Name';
      p_customer_number_col := 'Billing ID';
      p_address_col         := 'Address';
      p_address_type_col    := 'Address Type';
      p_contact_name_col    := 'Contact Name';
      p_contact_phone_col   := 'Contact Phone';
      p_account_summary_col := 'Account Detail';
      xx_irec_search_pkg.get_soft_headers (ln_cust_account_id, p_attribute2_col, p_attribute1_col, p_attribute4_col, p_attribute3_col, ls_success );
      IF ls_success      <> 'Y' THEN
        p_attribute1_col := 'Purchase Order';
        p_attribute2_col := 'Department';
        p_attribute3_col := 'Desktop';
        p_attribute4_col := 'Release';
      END IF;
    END;
  /*Start - 16Dec2014 - Added for iRec Enhancement changes*/  
  ELSIF p_search_attribute                = 'XX_RELEASE' THEN
      IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
        fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'p_search_attribute = XX_RELEASE' );
      END IF;
      BEGIN
        lc_search_keyword                 := p_search_keyword;
        IF INSTR (lc_search_keyword, '%') <= 0 THEN
          lc_search_keyword               := lc_search_keyword || '%';
        END IF;
        BEGIN
          SELECT acct.cust_account_id
          INTO ln_cust_account_id
          FROM hz_relationships rel,
            fnd_user fnd,
            hz_cust_accounts acct
          WHERE rel.party_id   = fnd.customer_id
          AND rel.subject_id   = acct.party_id
          AND rel.subject_type = 'ORGANIZATION'
          AND fnd.user_id      = fnd_global.user_id;
        EXCEPTION
        WHEN OTHERS THEN
          p_search_result := fnd_api.g_ret_sts_error;
          p_message_id    := 'XX_ARI_ACCOUNT_NOT_FOUND';
          p_msg_app_id    := 'AR';
          RETURN;
        END;
        --INSERT INTO ar_irec_custom_cust_gt
        INSERT
        INTO ar_irec_cstm_cust_gt_all
          (
            customer_id,
            address_id,
            customer_number,
            customer_name,
            concatenated_address,
            trx_number,
            customer_trx_id,
            cash_receipt_id,
            terms_sequence_number,
            CLASS,
            invoice_currency_code,
            attribute1,
            attribute2,
            attribute3,
            attribute4
          )
          (
            (
            --Query - Modified for R12 upgrade retrofit
            SELECT cust.cust_account_id customer_id,
              -1,
              cust.account_number customer_number,
              SUBSTRB (party.party_name, 1, 50) customer_name,
              NULL concatenated_address,
              my_sites.trx_number,
              my_sites.customer_trx_id,
              my_sites.cash_receipt_id cash_receipt_id,
              my_sites.terms_sequence_number terms_sequence_number,
              my_sites.CLASS trx_class,
              my_sites.invoice_currency_code,
              my_sites.purchase_order,
              my_sites.cost_center_dept,
              my_sites.desk_del_addr,
              my_sites.release_number
            FROM hz_cust_accounts cust,
              hz_parties party,
              fnd_territories_vl terr,
              --ra_addresses_all addr,
              hz_cust_acct_sites acct, --hz_cust_acct_sites_all acct,
              hz_party_sites party_site,
              --apps.hz_loc_assignments loc_assign,
              hz_locations loc,
              hz_cust_site_uses sites, --hz_cust_site_uses_all sites,
              (SELECT DISTINCT customer_site_use_id,
                aps.trx_number,
                aps.customer_id,
                aps.customer_trx_id,
                aps.terms_sequence_number,
                aps.CLASS,
                aps.invoice_currency_code,
                aps.cash_receipt_id,
                trx.purchase_order,
                oha.cost_center_dept,
                oha.desk_del_addr,
                oha.release_number
              FROM ra_customer_trx_all trx,
                xx_om_header_attributes_v oha,									--Retrofit NAIT-37762
                ar_payment_schedules_all aps
              WHERE trx.bill_to_customer_id = ln_cust_account_id
              AND trx.attribute14           = oha.header_id
              AND aps.customer_trx_id       = trx.customer_trx_id
              AND oha.release_number LIKE lc_search_keyword
              ) my_sites
            WHERE 1 = 1
              --AND addr.address_id = sites.cust_acct_site_id
              --AND addr.address_id = sites.cust_acct_site_id
            AND cust.party_id           = party.party_id
            AND cust.cust_account_id    = acct.cust_account_id
            AND sites.cust_acct_site_id = acct.cust_acct_site_id
            AND acct.party_site_id      = party_site.party_site_id
            AND party_site.party_id     = cust.party_id
            AND party_site.party_id     = party.party_id
            AND loc.country             = terr.territory_code(+)
            AND loc.location_id         = party_site.location_id
              --                    AND loc.location_id = loc_assign.location_id
              --                    AND NVL (acct.org_id, -99) = NVL (loc_assign.org_id, -99)
              --                    AND NVL (sites.org_id, -99) = NVL (loc_assign.org_id, -99)
              --                    AND acct.org_id = p_org_id
              --AND addr.customer_id = cust.cust_account_id
              --AND addr.country = terr.territory_code(+)
            AND sites.site_use_id    = my_sites.customer_site_use_id
            AND cust.cust_account_id = my_sites.customer_id
            )
          UNION
            (
            --Query - Modified for R12 upgrade retrofit
            SELECT cust.cust_account_id customer_id,
              --addr.address_id,
              acct.cust_acct_site_id address_id,
              cust.account_number customer_number,
              SUBSTRB (party.party_name, 1, 50) customer_name,
              /*
              SUBSTR
              (arp_addr_pkg.format_address
              (addr.address_style,
              addr.address1,
              addr.address2,
              addr.address3,
              addr.address4,
              addr.city,
              addr.county,
              addr.state,
              addr.province,
              addr.postal_code,
              terr.territory_short_name
              ),
              1,
              255
              ) concatenated_address,*/
              SUBSTR (arp_addr_pkg.format_address (loc.address_style, loc.address1, loc.address2, loc.address3, loc.address4, loc.city, loc.county, loc.state, loc.province, loc.postal_code, terr.territory_short_name ), 1, 255 ) concatenated_address,
              my_sites.trx_number,
              my_sites.customer_trx_id,
              my_sites.cash_receipt_id cash_receipt_id,
              my_sites.terms_sequence_number terms_sequence_number,
              my_sites.CLASS trx_class,
              my_sites.invoice_currency_code,
              my_sites.purchase_order,
              my_sites.cost_center_dept,
              my_sites.desk_del_addr,
              my_sites.release_number
            FROM hz_cust_accounts cust,
              hz_parties party,
              fnd_territories_vl terr,
              --ra_addresses_all addr,
              hz_cust_acct_sites acct, --hz_cust_acct_sites_all acct,
              hz_party_sites party_site,
              --apps.hz_loc_assignments loc_assign,
              hz_locations loc,
              hz_cust_site_uses sites, --hz_cust_site_uses_all sites,
              (SELECT DISTINCT customer_site_use_id,
                aps.trx_number,
                aps.customer_id,
                aps.customer_trx_id,
                aps.terms_sequence_number,
                aps.CLASS,
                aps.invoice_currency_code,
                aps.cash_receipt_id,
                trx.purchase_order,
                oha.cost_center_dept,
                oha.desk_del_addr,
                oha.release_number
              FROM ra_customer_trx_all trx,
                xx_om_header_attributes_v oha,									--Retrofit NAIT-37762
                ar_payment_schedules_all aps
              WHERE trx.bill_to_customer_id = ln_cust_account_id
              AND trx.attribute14           = oha.header_id
              AND aps.customer_trx_id       = trx.customer_trx_id
              AND oha.release_number LIKE lc_search_keyword
              ) my_sites
            WHERE 1 = 1
              --AND addr.address_id = sites.cust_acct_site_id
              --AND addr.address_id = sites.cust_acct_site_id
            AND cust.party_id           = party.party_id
            AND cust.cust_account_id    = acct.cust_account_id
            AND sites.cust_acct_site_id = acct.cust_acct_site_id
            AND acct.party_site_id      = party_site.party_site_id
            AND party_site.party_id     = cust.party_id
            AND party_site.party_id     = party.party_id
            AND loc.country             = terr.territory_code(+)
            AND loc.location_id         = party_site.location_id
              --                    AND loc.location_id = loc_assign.location_id
              --                    AND NVL (acct.org_id, -99) = NVL (loc_assign.org_id, -99)
              --                    AND NVL (sites.org_id, -99) = NVL (loc_assign.org_id, -99)
              --                    AND acct.org_id = p_org_id
              --AND addr.customer_id = cust.cust_account_id
              --AND addr.country = terr.territory_code(+)
            AND sites.site_use_id    = my_sites.customer_site_use_id
            AND cust.cust_account_id = my_sites.customer_id
            )
          );
        p_search_result       := fnd_api.g_ret_sts_success;
        p_message_id          := NULL;
        p_msg_app_id          := NULL;
        p_trx_number_col      := 'Transaction Number';
        p_customer_name_col   := 'Customer Name';
        p_customer_number_col := 'Billing ID';
        p_address_col         := 'Address';
        p_address_type_col    := 'Address Type';
        p_contact_name_col    := 'Contact Name';
        p_contact_phone_col   := 'Contact Phone';
        p_account_summary_col := 'Account Detail';
        xx_irec_search_pkg.get_soft_headers (ln_cust_account_id, p_attribute2_col, p_attribute1_col, p_attribute4_col, p_attribute3_col, ls_success );
        IF ls_success      <> 'Y' THEN
          p_attribute1_col := 'Purchase Order';
          p_attribute2_col := 'Department';
          p_attribute3_col := 'Desktop';
          p_attribute4_col := 'Release';
        END IF;
      END;
    ELSIF p_search_attribute                = 'XX_ACCOUNTLEVEL_ONLY' THEN
      IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
        fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'p_search_attribute = XX_ACCOUNTLEVEL_ONLY' );
      END IF;
      IF p_search_keyword IS NULL THEN
        p_search_result   := fnd_api.g_ret_sts_error;
        p_message_id      := 'ARI_NO_SEARCH_CRITERIA';
        p_msg_app_id      := 'AR';
      ELSE
        lc_search_keyword                 := p_search_keyword;
        IF INSTR (lc_search_keyword, '%') <= 0 THEN
          lc_search_keyword               := lc_search_keyword || '%';
        END IF;
        BEGIN
          INSERT
          INTO ar_irec_cstm_cust_gt_all
            (
              customer_id,
              customer_number,
              Customer_name,
              Address_ID,
              -- concatenated_address,
              attribute3 ,
              attribute1 ,
              attribute2 ,
              attribute4
            )
          SELECT *
          FROM
            (SELECT cust.cust_account_id      CUSTOMER_ID,
              cust.ACCOUNT_NUMBER             CUSTOMER_NUMBER,
              SUBSTRB(cust.ACCOUNT_NAME,1,50) CUSTOMER_NAME,
              -1 address_id,
              fnd_message.get_string('AR','ARI_ALL_ORGANIZATIONS') AS ORG_NAME , -- attribute3
              'Account Detail', -- attribute1
              'Account Summary', -- attribute2
               cust.cust_account_id -- attribute4
            FROM hz_cust_accounts       cust
            WHERE  cust.account_number=p_search_keyword
            UNION
            SELECT cust.cust_account_id      CUSTOMER_ID,
              cust.ACCOUNT_NUMBER             CUSTOMER_NUMBER,
              SUBSTRB(cust.ACCOUNT_NAME,1,50) CUSTOMER_NAME,
              -1 address_id,
              fnd_message.get_string('AR','ARI_ALL_ORGANIZATIONS') AS ORG_NAME , -- attribute3
              'Account Detail', -- attribute1
              'Account Summary', -- attribute2
               cust.cust_account_id -- attribute4
            FROM hz_cust_accounts       cust
            WHERE  cust.account_name LIKE lc_search_keyword
            );
          IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
            fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'No.of Rows count' || SQL%ROWCOUNT );
          END IF;
          p_attribute3_col      := NULL;--'Organization';
          p_customer_name_col   := 'Customer Name';
          p_customer_number_col := 'Billing ID';
          p_address_col         := 'Address';
          --    p_address_type_col := 'Address Type';
          p_attribute1_col      := 'Account Detail';
          p_attribute2_col      := NULL; --'Account Summary';
          p_account_summary_col := NULL; -- 'Account Detail Orig';
          p_trx_number_col      := NULL;
          p_attribute5_col      := NULL;
          p_search_result       := NULL;
          p_message_id          := NULL;
          p_msg_app_id          := NULL;
        END;
    END IF;
  /*End - 16Dec2014 - Added for iRec Enhancement changes*/   
  ELSE
    IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
      fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer', MESSAGE => 'IN ELSE CONDITION' );
    END IF;
    p_trx_number_col        := NULL;
    p_org_name              := 'Organization';
    p_customer_name_col     := 'Customer Name';
    p_customer_number_col   := 'Customer Number';
    p_customer_location_col := 'Customer Location';
    p_address_col           := 'Address';
    p_address_type_col      := 'Address Type';
    p_contact_name_col      := 'Contact Name';
    p_contact_phone_col     := 'Contact Phone';
    p_account_summary_col   := 'Account Detail';
    p_attribute1_col        := NULL;
    p_attribute2_col        := NULL;
    p_attribute3_col        := NULL;
    p_attribute4_col        := NULL;
    p_attribute5_col        := NULL;
    p_search_result         := NULL;
    p_message_id            := NULL;
    p_msg_app_id            := NULL;
  END IF;
  COMMIT;
  --End - Added - R12 upgrade
  /*
  --Commented for R12 upgrade
  p_org_name       := 'Organization';
  p_trx_number_col := NULL ;
  p_customer_name_col := 'Customer Name' ;
  p_customer_number_col := 'Customer Number' ;
  p_customer_location_col := 'Customer Location';
  p_address_col := 'Address' ;
  p_address_type_col := 'Address Type' ;
  p_contact_name_col := 'Contact Name' ;
  p_contact_phone_col := 'Contact Phone' ;
  p_account_summary_col := 'Account Summary' ;
  p_attribute1_col := NULL ;
  p_attribute2_col := NULL ;
  p_attribute3_col := NULL ;
  p_attribute4_col := NULL ;
  p_attribute5_col := NULL ;
  p_search_result := NULL ;
  p_message_id := NULL ;
  p_msg_app_id := NULL ;
  */
  IF NVL (lc_fnd_log_debug_enable, 'N') = 'Y' THEN
    fnd_log.STRING (log_level => fnd_log.level_statement, module => 'ari_config.search_custom_customer.end', MESSAGE => 'ari_config.search_custom_customer-' );
  END IF;
END search_custom_customer;
END ari_config;
/
