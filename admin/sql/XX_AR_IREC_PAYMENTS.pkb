create or replace PACKAGE BODY xx_ar_irec_payments
AS
/*  | $Header: ARIRPMTB.pls 120.99.12020000.44 2015/03/13 14:21:57 gnramasa ship  $ */

-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |                       WIPRO Technologies                              |
-- +=======================================================================+
-- | Name     :   Verbal Auth                                              |
-- | Rice id  :   E1294                                                    |
-- | Description : Modified the package for Voice Authorization            |
-- |                                                                       |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version   Date              Author              Remarks                |
-- |======   ==========     =============        =======================   |
-- |1.0       10-Aug-2007   Madankumar J         Initial version           |
-- |                        Wipro Technologies                             |
-- |                                                                       |
-- |1.1       03-NOv-2007   Madankumar J         Defect 2462(CR 247)       |
-- |                                                                       |
-- |1.2       28-Mar-2008   Madankumar J         Version updation due to   |
-- |                                             patch application.        |
-- |                                             Standard Package is       |
-- |                                             modified to include the   |
-- |                                             changes for verbal Auth   |
-- |1.3       13-Jun-2008   Sambasiva Reddy D    Defect 6326               |
-- |1.4       14-Jun-2008   Rama Krishna         Defect 6326               |
-- |1.5       15-Jun-2008   Sambasiva Reddy D    Defect 6326               |
-- |1.5       21-Jun-2008   Rama Krishna         Defect 6326               |
-- |1.5       22-Jun-2008   Rama Krishna         Defect 6326               |
-- |1.6       07-Oct-2008   Anitha.D             Patch # 7377247 applied   |
-- |                                             and hence modified        |
-- |1.7       21-May-2009   Anitha.D             Patch # 8460233 applied   |
-- |                                             and hence modified        |
-- |1.8       04-Jun-2009   Shobana.S            Patch # 8460233 applied   |
-- |                                             and hence modified        |
-- |1.9       21-Jul-2009   Bushrod              Defect 4180               |
-- |2.0       12-Jan-2013   Jay Gupta            Changes for CR868 - ePay  |
-- |3.0       12-Aug-2013   Sridevi K            Considered standard R12   |
-- |                                             version and retrofitted   |
-- |                                             for R12 upgrade           |
-- |4.0       16-Sep-2013   Sridevi K            Retrofitted for E1294     |
-- |4.1       18-Sep-2013   Sridevi K            Incorporated Gautham's    |
-- |                                             and Rick's review comments|
-- |4.2       15-DEC-2013   Sridevi K            Modified                  |
-- |                                             pay_multiple_invoices     |
-- |                                             for Defect27002           |
-- |4.3       17-DEC-2013   Edson Morales        Modified for ps2000       |
-- |                                             Defect 25807|             |
-- |5.0       22-Jan-2014   Sridevi K            Modified for Defect 27242 |
-- |                                             CC Issue                  |
-- |6.0       5-FEB-2014    Sridevi K            Modified for Defect27888  |
-- |6.1       05-FEB-2014   Jay Gupta            Defect#27883 - Bypass     |
-- |                                             Receipt Method for CC     |
-- |6.2       07-MAY-2014   Arun Gannarapu       Made changes to fix the   |
-- |                                             defect 29753              |
-- |6.3       23-JUN-2014   Avinash Baddam       For defect#30662          |
-- |                  Rollback if soa call fails                           |
-- |6.4       24-Jun-2014   Sridevi K            For defect#30000          |
-- |6.5       4-Jul-2014    Sridevi K            For defect#30000          |
-- |7.0       16-Jan-2015   Sridevi K            For Patch_19052386-B      |
-- |8.0       4-Mar-2015    Sridevi K            Modified for CR1120       |
-- |8.1       22-Apr-2015   Sridevi K            Modified for Defect1080   |
-- |9         22-Jun-2015   Sridevi K            Modified for Defect#34441 |
-- |9.1		  01-JUL-2015	Rajesh				 Modified for Defect#34865 |
-- |9.2       27-AUG-2015   Suresh Ponnambalam   Defect 35495.             |
-- |9.3       20-NOV-2015   Vasu Raparla         Modified for Defects 35918|
-- |                                              35919 and 35910          |
-- |9.4       30-Aug-2016   Vasu Raparla         Considered standard 12.2.5|
-- |                                             version and retrofitted   |
-- |                                             for R12.2.5 upgrade       |
-- |10.0      5-OCT-2016    Sridevi K            Modified for Vantiv       |
-- |11.0      19-OCT-2017   Vasu R               Modified for defec 35919  |
-- |12.0      12-AUG-2020   Divyansh saini       Modified for PCI Irec     |
-- |                                             JIRA NAIT-129669          |
-- +=======================================================================+

 /* ============================================================================+
 | $Header: ARIRPMTB.pls 120.99.12020000.44 2015/03/13 14:21:57 gnramasa ship $
 +============================================================================+
 |  Copyright (c) 2000, 2015 Oracle Corporation Redwood Shores, California, USA     |
 |                          All rights reserved.                              |
 +============================================================================+
 | PACKAGE BODY         AR_IREC_PAYMENTS
 |
 | DESCRIPTION
 |      iReceivables Payments Functionality.
 |
 | PSEUDO CODE LOGIC/ALGORITHMS
 |
 | CALLED PACKAGES
 |
 |
 | PUBLIC PROCEDURES
 |
 | PUBLIC FUNCTIONS
 |
 |
 | PUBLIC VARIABLES
 |
 |
 | PROFILE OPTIONS
 |
 |
 | KNOWN ISSUES
 |
 |
 | NOTES
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 22-JAN-2001           O. Steinmeier     Created
 |
 | 09-SEP-2003     hikumar    Modified to pass account check digits
 |       ( Bug # 3127651 )    and Bank Address details to iPayment
 |
 |                Also the call to get_iby_payment_instrument
 |                has been replaced by add_iby_payment_instrument
 |                because the function find_iby_payment_instrument
 |                has been modified to return null always
 |                because of security reasons and therefore
 |                get_iby_payment_instrument always
 |                call the function add_iby_payment_instrument
 |
 |                The functions get_iby_payment_instrument and
 |                   find_iby_payment_instrument have been commented.
 |
 | 31-OCT-2003           yreddy            Bug2925392: Payment process fails for some currencies.
 | 25-FEB-2004           vnb               Bug 3433884 - Pass org_id to iPayment API
 |                    in 'process_ach_payment' and 'process_payment'
 | 30-APR-2004           vnb               Bug # 3338276 - To check if one-time payment is enabled,
 |                a wrapper has been added to check if the option has been enabled
 |                in ARI_CONFIG.save_payment_instrument_info;
 | 18-MAY-2004           vnb               Bug # 3467287 - Procedures/functions modified to stripe
 |                                         the Transaction List (the Global Temp table)
 |                                         by Customer and Customer Site.
 | 14-JUN-2004           vnb               Bug # 3458134 - To check for grace days while adding discount,
 |                               a wrapper has been added to check if the option has been enabled
 |                               in ARI_CONFIG.is_discount_grace_days_enabled;
 |                               The call to calculate the discounts will check for grace days or otherwise,
 |                               based on the above API.
 | 16-JULY-2004      hikumar        Modified cursor batch_cur for Autoremittance with no receipt class and payment method
 | 19-JUL-2004           vnb               Bug # 2830823 - Added exception blocks to service charge APIs to handle exceptions
 | 23-JUL-2004           vnb               Bug # 3630101 - Payment process setup errors to be displayed to internal user
 | 09-AUG-2004           vnb               Bug # 3810143 - "Recalculate" not working on Payment Page at customer account level
 | 21-SEP-2004           vnb       Bug 3886652 - Customer and Customer Site added as
 |                            params in configurable ARI_CONFIG APIs.
 | 21-OCT-2004           vnb       Bug 3944029 - Modified pay_multiple_invoices to pass correct site_use_id to other APIs
 | 14-Dec-2004           vnb       Bug 4062938 - Handling of transactions with no site id
 | 20-Dec-2004           vnb       Bug 4071019 - Round payment amounts based on precision only
 | 03-Jan-2005           vnb       Bug 4071551 - Removed redundant code while inserting into transaction list
 | 20-Jan-2005           vnb       Bug 4117211 - Added code for resetting payment amounts when 'Reset to Defaults' button is clicked
 | 21-Jan-2005     rsinthre  Bug 4080357 - Added a procedure create_open_credit_pay_list to insert open credits/payments in payment list GT
 | 11-Feb-2005     rsinthre  Bug 4161986 - Pay Icon does not appear in the ChargeBack and its activities page
 | 18-Feb-2005     rsinthre  Bug 4188493 - Advance Payment page not showing full details of previous saved cards
 | 24-May-2005           vnb   Bug 4197060 - MOAC Uptake
 | 07-Jul-2005           vnb       Bug 4479224 - Recalculate discounts after select credits on apply credits flow
 | 07-Jul-2005     rsinthre  Bug 4437220 - Payment amount not changed when discount recalculated
 | 08-Jul-2005     rsinthre  Bug 4437225 - Disputed amount against invoice not displayed during payment
 | 11-Jul-2005           vnb       Bug 4483091 - Support negative invoices
 | 12-Jul-2005     rsinthre  Bug 4488409 - Pass Created_by_module as ARI to TCA V2 APIs
 | 15-Sep-2005     rsinthre  Bug 4609067 - FWD PORT: BUG 4482396: R12: PAYMENT AMT NOT CHANGED WHEN DISCOUNT RECALCULATED
 | 02-Sep-2005     rsinthre  Bug 4604121 - Unable to add payments to transaction list in r12 sep drop
 | 18-Oct-2005     rsinthre  Bug 4673563 - Error making credit card payment
 | 27-Oct-2005           rsinthre  Bug 4701797 - Default Payment instrument  not shown
 | 07-Nov-2005        rsinthre  Bug 4711762 - Performance issue with Pay ALL button
 | 10-Nov-2005           rsinthre  Bug 4721421 - Card Secuiryt Code not shown for MasterCard in NEW CC pmt region
 | 15-Nov-2005        rsinthre  Bug 4735828 - Rejected Dispute doesn't reset to 0.00 when paying invoice
 | 06-Feb-2006           vgundlap  Bug 4947418 - Invalid objects caused by obsolete objects in aru on appsre env
 | 05-May-2007     mbolli     Bug 6024713 - Trunc should be done for the left date column also when trunc is there for right date column in criteria
 | 22-JUN-2007     mbolli     Bug 6109909 - Not using 'Payment Method' set at customer/site level
 | 18-Feb-2008     rsinthre  Bug 6819964 - Paying an invoice is throwing NullPointer exception
 | 11-Sep-2008           avepati   Bug 7390041 Future Dated Payment Should Corresponds to Latest open AR Period
 | 22-Jan-2008           avepati   Bug 7712779 TST1211.XB3.QA. ABLE TO PAY THRU BANK EVEN IF SYS OPTION HAVE NO BANK PAY METHOD
 | 15-Feb-2009           avepati   Bug 8239939 - TST1211.E.XB3.QA AR_RECEIPT_API_PUB.APPLY RETURNS 'S'  BUT APPLIED AMT IS NOT
 | 13-Mar-2009           avepati   Bug 8329821  NEED TO DISPLAY MASKED CC HOLDER NAME IN IREC AS PART OF PA-DSS CERTIFICATION
 | 26-May-2009     avepati   Bug 8547988  AS PART OF PADSS CERT,ENCRYPTED FILEDS SHOULD NOT BE QUERIED FROM IBY_CREDITCARD
 | 04-Aug-2009     avepati   Bug 8664350  R12 UNABLE TO LOAD FEDERAL RESERVE ACH PARTICAIPANT DAT
 | 19-AUG-2009     nkanchan  Bug 8780501 - Payments are failing
 | 07-SEP-2009     avepati   Bug 8873709 - Error : The Credit Card Number Already Exists,Please Enter a New Credit Card
 | 26-OCT-2009     avepati   Bug 8897653 - UPLOADING  ACH BANKS AND BRANCHES
 | 30-Oct-2009     nkanchan  Bug 9046643 - unable to end date bank accounts from advanced payment pages
 | 11-Nov-2009     avepati   Bug 8915943 - Bank Details are not coming up after click on show bank details
 | 26-Nov-2009     avepati   Bug 9156182 - BAnk Accounts Show Partial Information  In OIR
 | 05-Mar-2010     avepati   Bug 9173720 - Able to see same invoice twice in payment details page.
 | 22-Mar-2010     nkanchan  Bug 8293098 - Service change based on credit card types
 | 28-Apr-2010     avepati   Bug 9596552 - COMPLETE PMT WTH SERVICE CHARGE FRM 'ALL LOCATIONS' ENDS IN ERROR
 | 12-May-2010     rsinthre  Bug 9683510 - R.TST1213.XB1.QA:RECEIPT CREATED THROUGH OIR ERRORS OUT ON REMITTANCE IN AR
 | 26-May-2010     avepati   Bug 9696292 - TST1213.XB1.QA:PAGE ERRORS OUT ON NAVIGATING BTWN 'ALL LOCATIONS' & 'SITE' LEVEL
 | 08-Jun-2010     nkanchan  Bug 9696274 - PAGE ERRORS OUT ON NAVIGATING 'PAY BELOW' RELATED CUSTOMER DATA
 | 11-Oct-2010     avepati   Bug 10121591 - 12I CREDIT CARDS AFTER UPGRADE DOES NOT HAVE EXPIRY DATES POPULATED
 | 12-Nov-2010     avepati   Bug 10034475 - INSTR_ID IS NOT PASSED TO IBY WHEN MAKING ONE TIME CREDIT CARD PAYMENT FROM IREC
 | 23-Feb-2011     avepati   Bug 11654712 - AR CREATING RECEIPTS WHEN CALLS TO IPAYMENT FAILED
 | 17-Mar-2011     avepati   Bug 11832912 - EXPIRED CARDS SHOWING UP IN IRECEIVABLES
 | 27-Apr-2011     avepati   Bug 9910157 - AUTHORIZATION CODE NOT SEEN IN IRECEIVABLES FOR CREDIT CARD PAYMENTS
 | 06-May-2011     rsinthre  Bug 10106518 - FP:10080781:DISCOUNT ALERTS DUE DATE IS INCORRECT
 | 06-May-2011           avepati   Bug 12410542 - CREDIT CARD PAYMENT FAILURE IN OIR IF IPAYMENT DEMO IS OFF
 | 18-May-2011     rsinthre  Bug 12542249 - TST122.XB2.QA.DISCOUNT AMT NOT COMING CORRECTLY FOR INSTALLMENT PAYMENT TERMS
 | 24-Jun-2011     rsinthre  Bug 12670265 - TST122.XB5.QA.NEED TO FIX ONE TIME CREDIT CARD PAYMENT FUNCTIONALITY
 | 03-NOV-2011     rsinthre  Bug 13337289 - CAN NOT MAKE PAYMENTS THROGUH I RECEIVABLES WHEN THE AR PERIOD IS NOT OPEN
 | 23-JAN-2011     rsinthre  Bug 13601435 - PAYMENT ERROR VIA IRECEIVABLES
 | 30-Apr-2012           parln     Bug 13504453 - ABILITY TO MAKE FUTURE DATED PAYMENTS FOR FUTURE INVOICES
 | 12-Jun-2012     rsinthre  Bug 14157868 - INVALID SEC CODE (811) ERROR IN IRECEIVABLES
 | 25-Sep-2012     rsinthre  Bug 14534172 - IRECEIVABLES ONE-TIME CREDIT CARD PAYMENT ISSUES
 | 28-Sep-2012           melapaku  Bug 14646910 - RECEIPT CREATED BUT STAYS UNAPPLIED WHEN PAID BY CUSTOMER FROM
 |                                                IRECEIVABLES
 | 28-Sep-2012     rsinthre  Bug 14646909 - IRECEIVABLES ADVANCED PAYMENT UPDATES BANK ACCOUNT WITH INVALID VALUE
 | 08-Oct-12             melapaku  Bug 14556872 - FIELD REQUIRED ON PAYMENT SCREEN TO GIVE CUSTOMERS OPTION TO SAVE
 |                                                CREDIT CARD
 | 11-Oct-12             melapaku  Bug 14672025 - DISCOUNT CALCULATION IS WRONG FOR FUTURE DATED PAYMENTS.
 | 19-Oct-12             melapaku  Bug 14781706 -  FUTURE DATED PAYMENT INCLUDING CREDIT MEMO FAILS WITH
 |                                                 APPLY DATE MUST BE GREATER RECEIPT DATE
 | 27-Dec-12             melapaku  Bug 14798065 - ccard saved in ar cust pymt details even though save box
 |                                                unchecked
 | 27-Dec-12             melapaku  Bug 14797865 - ccard billing address defaulting pymt page appearance inconsiste
 | 12-Jan-13             melapaku  Bug 16097315 - IRECEIVABLES SHOWS FUTURE DATED BANK ACCOUNTS
 | 06-Feb-2013           melapaku  Bug16262617 - cannot remove end date entered via ireceivables pay function
 | 13-Feb-2013           melapaku  Bug16306925 - PAYMENTS FAIL WHEN SAME BANK ACCOUNT NUMBER , ROUTING NUMBER AND ACCOUNT
 | 01-Mar-2013           melapaku  Bug16420473 - CANNOT END DATE BANK ACC WHICH IS ASSOCIATED AT ACC AND SITE LEVEL IN
 |                                               IRECEIVABLES
 | 14-Mar-2013           melapaku  Bug16471455 - Payment Audit History Feature
 | 23-Oct-2013           shvimal   Bug 17625348 - ERROR APPEARS WHEN USING AN UNSAVED CREDIT CARD IN IRECEIVABLES
 | 06-Nov-2013           melapaku  Bug 17654698 - RECEIPTS IS CREATED FOR FAILED CREDIT CARD TRANSACTION AND CREDIT CARD SAVED
 | 19-Feb-2014           shvimal   Bug 18247364 - DISCOUNT IS CALCULATING TOTAL INVOICE AMOUNT INSTEAD OF UNDISPUTED AMOUNT
 | 14-May-2014           rsurimen  Bug 18727728 - FUTURE DATED PAYMENT FOR A DISPUTED AND DISCOUNTED INVOICE GIVES WRONG TOTAL PAY
 | 29-May-2014           melapaku  Bug 18832462 - Future date payment for double discount  invoices
 | 06-Jun-2014           melapaku  Bug 18866462 - Cannot make future dated payment when it includes a credit memo
 | 15-Jul-2014           gnramasa  Bug 19190706 - PPG: PAYMENT PROCESS FAILED IBYIBY_INVALID_INSTR_ASSIGN AND INVALID_INSTRUMENT_A
 | 23-Jul-2014           gnramasa  Bug 17475275 - TST1223:CREDIT CARD DETAILS BEING SHOWN TWICE, WHEN PAID PART BY PART
 | 12-Aug-2014           melapaku  Bug 19331908 - RPC-AUG14:Discount alerts at home page not shown for newly created
 |                                                customers
 | 14-Oct-2014           melapaku  Bug 19800178 - IRECEIVABLES LEADING ZERO REMOVED IN CVV CODE
 | 30-Dec-2014	         gnramasa  Bug 20236871 - QUICK PAYMENT PAGE NOT DISPLAYED WHEN PAYMENT METHOD AT ACCOUNT LEVEL ONLY
 | 21-Jan-2015           gnramasa  Bug 20389172 - IRECEIVABLES CREDIT CARD PAYMENTS
 | 21-Jan-2015           gnramasa  Bug20359618 - CUSTOMER (BANK ACCT TRANSFER) BANK PRIORITY CHGS WHEN IRECEIVABLES IS USED
 | 22-Jan-2015           ssiddams  Bug 20387036 - ENDDATED RECEIPT METHOD DOES NOT REMOVE NEW CREDIT CARD OPTION
 | 23-Jan-2015           gnramasa  Bug 20387436 - PAYMENTS - SWITCHING OU/CURRENCY AND MAKING 2ND PYMT CAUSES EXCHANGE RATE ERROR
 | 16-Feb-2015           gnramasa  Bug 20502416 - IREC- CODE: INCONSISTENT BEHAVIOR OF PAY BUTTON IN ACCNT DETAIL AND TRX DETAIL
 | 05-Mar-2015	         gnramasa  Bug 20352248 - ISSUE WITH PAYMENTS FOR SAME ROUTING # BUT DIFFERENT ACCOUNTS
 | 13-Mar-2015           gnramasa  Bug 20502416 - IREC- CODE: INCONSISTENT BEHAVIOR OF PAY BUTTON IN ACCNT DETAIL AND TRX DETAIL
 *============================================================================ */
/*=======================================================================+
|  Package Global Constants
+=======================================================================*/
   g_pkg_name           CONSTANT VARCHAR2 (30)   := 'XX_AR_IREC_PAYMENTS';
/* Start - Added for R12 upgrade retrofit */
   gc_auth_code                  VARCHAR2 (50)   := NULL;
   -- Included by Madankumar J, Wipro Technologies for E1294
   gc_trx_number                 VARCHAR2 (50)   := NULL;           --  I0349
/* End - Added for R12 upgrade retrofit */

   /* E1294 - Added for Credit Encrypt functionality */
   gc_encrypted_cc_num           VARCHAR2 (2000);
   gc_cc_encrypt_error_message   VARCHAR2 (2000);
   gc_key_label                  VARCHAR2 (2000);
/* E1294 - End - Added for Credit Encrypt functionality */
   g_creation_failed    CONSTANT VARCHAR2 (30)   := 'CREATION_FAILED';
   g_app_failed         CONSTANT VARCHAR2 (30)   := 'APP_FAILED';
   g_svc_failed         CONSTANT VARCHAR2 (30)   := 'SVC_FAILED';
   g_cc_auth_failed     CONSTANT VARCHAR2 (30)   := 'CC_AUTH_FAILED';
   g_successful         CONSTANT VARCHAR2 (30)   := 'SUCCESSFUL';
   g_failed             CONSTANT VARCHAR2 (30)   := 'FAILED';


   TYPE invoice_rec_type IS RECORD (
      payment_schedule_id   NUMBER (15),
      payment_amount        NUMBER,
      customer_id           NUMBER (15),
      account_number        VARCHAR2 (30),
      customer_trx_id       NUMBER (15),
      currency_code         VARCHAR2 (15),
      service_charge        NUMBER
   );

   TYPE invoice_list_tabtype IS TABLE OF invoice_rec_type;

/*========================================================================
 | Prototype Declarations Procedures
 *=======================================================================*/
   pg_debug                      VARCHAR2 (1)
                             := NVL (fnd_profile.VALUE ('AFLOG_ENABLED'), 'N');

   FUNCTION get_iby_account_type (p_account_type IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION mask_account_number(p_value IN VARCHAR2) RETURN VARCHAR2
   IS
   BEGIN

     RETURN lpad(substr(p_value,-4),length(p_value),'*');
   EXCEPTION
     WHEN OTHERS THEN
       RETURN null;
   END mask_account_number;

   PROCEDURE write_debug_and_log (p_message IN VARCHAR2);

   PROCEDURE write_api_output (p_msg_count IN NUMBER, p_msg_data IN VARCHAR2);

   PROCEDURE apply_service_charge (
      p_customer_id     IN              NUMBER,
      p_site_use_id     IN              NUMBER DEFAULT NULL,
      x_return_status   OUT NOCOPY      VARCHAR2
   );

   PROCEDURE apply_cash (
      p_customer_id       IN              NUMBER,
      p_site_use_id       IN              NUMBER DEFAULT NULL,
      p_cash_receipt_id   IN              NUMBER,
      p_return_status     OUT NOCOPY      VARCHAR2,
      p_apply_err_count   OUT NOCOPY      NUMBER,
      x_msg_count         OUT NOCOPY      NUMBER,
      x_msg_data          OUT NOCOPY      VARCHAR2
   );

   --Modified for R12 upgrade retrofit
   PROCEDURE create_receipt (
      p_payment_amount               IN              NUMBER,
      p_customer_id                  IN              NUMBER,
      p_site_use_id                  IN              NUMBER,
      p_bank_account_id              IN              NUMBER,
      p_receipt_date                 IN              DATE
            DEFAULT TRUNC (SYSDATE),
      p_receipt_method_id            IN              NUMBER,
      p_receipt_currency_code        IN              VARCHAR2,
      p_receipt_exchange_rate        IN              NUMBER,
      p_receipt_exchange_rate_type   IN              VARCHAR2,
      p_receipt_exchange_rate_date   IN              DATE,
      p_trxn_extn_id                 IN              NUMBER,
      p_cash_receipt_id              OUT NOCOPY      NUMBER,
      p_status                       OUT NOCOPY      VARCHAR2,
      x_msg_count                    OUT NOCOPY      NUMBER,
      x_msg_data                     OUT NOCOPY      VARCHAR2,
      p_attr1                        IN              VARCHAR2,
      p_attr_category                IN              VARCHAR2,
      p_confirmemail                IN              VARCHAR2
   );

   --Modified for R12 upgrade retrofit
   PROCEDURE process_payment (
      p_cash_receipt_id       IN              NUMBER,
      p_payer_rec             IN              iby_fndcpt_common_pub.payercontext_rec_type,
      p_payee_rec             IN              iby_fndcpt_trxn_pub.payeecontext_rec_type,
      p_called_from           IN              VARCHAR2,
      p_response_error_code   OUT NOCOPY      VARCHAR2,
      x_msg_count             OUT NOCOPY      NUMBER,
      x_msg_data              OUT NOCOPY      VARCHAR2,
      x_return_status         OUT NOCOPY      VARCHAR2,
      p_cc_auth_code          OUT NOCOPY      VARCHAR2,
      x_auth_result           OUT NOCOPY      iby_fndcpt_trxn_pub.authresult_rec_type,
      x_bep_code              OUT NOCOPY      VARCHAR2
   );

   PROCEDURE update_cc_bill_to_site (
      p_cc_location_rec      IN              hz_location_v2pub.location_rec_type,
      x_cc_bill_to_site_id   IN              NUMBER,
      x_return_status        OUT NOCOPY      VARCHAR2,
      x_msg_count            OUT NOCOPY      NUMBER,
      x_msg_data             OUT NOCOPY      VARCHAR2
   );

   /*Start-Added for R12 upgrade retrofit*/
     -- FOR I0349 AUTH --
   PROCEDURE invoice_tangibleid (
      p_trx_number                 IN   VARCHAR2,
      p_payment_server_order_num   IN   VARCHAR2
   )
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO xx_ar_ipay_trxnumber
                  (trx_number, oapforderid
                  )
           VALUES (p_trx_number, p_payment_server_order_num
                  );

      COMMIT;
   END invoice_tangibleid;

   /*Start-Added for Defect 35910*/
   /* Procedure to reset Debug_flag*/
   PROCEDURE set_tmp_debug_flag ( p_log_flag   in varchar2
                                 ,p_log_module in varchar2
                                 ,p_log_level  in varchar2)
   AS
   BEGIN
    fnd_profile.put('AFLOG_ENABLED', p_log_flag);
    fnd_profile.put('AFLOG_MODULE', p_log_module);
    fnd_profile.put('AFLOG_LEVEL',p_log_level);
    fnd_log_repository.init;
    Exception
    when others then
    null;
   END set_tmp_debug_flag;

   PROCEDURE process_ps2000_info (
      p_trxn_extension_id   IN   iby_fndcpt_tx_extensions.trxn_extension_id%TYPE,
      p_cash_receipt_id     IN   ar_cash_receipts_all.cash_receipt_id%TYPE
   )
   AS
      CURSOR cur_transactionid (
         p_trxn_extension_id   IN   iby_fndcpt_tx_extensions.trxn_extension_id%TYPE,
         p_cash_receipt_id     IN   ar_cash_receipts_all.cash_receipt_id%TYPE
      )
      IS
         SELECT itsa.transactionid
           FROM iby_fndcpt_tx_extensions ifte,
                iby_fndcpt_tx_operations ifto,
                iby_trxn_summaries_all itsa,
                ar_cash_receipts_all acra
          WHERE ifte.trxn_extension_id = p_trxn_extension_id
            AND ifte.trxn_extension_id = acra.payment_trxn_extension_id
            AND acra.cash_receipt_id = p_cash_receipt_id
            AND ifte.trxn_extension_id = ifto.trxn_extension_id
            AND ifto.transactionid = itsa.transactionid
            AND itsa.reqtype = 'ORAPMTREQ';

      CURSOR cur_auth_req (
         p_transaction_id   IN   iby_fndcpt_tx_operations.transactionid%TYPE
      )
      IS
         SELECT *
           FROM xx_iby_auth_response
          WHERE payment_transaction_id = p_transaction_id;

      lr_cash_receipt_rec   ar_cash_receipts_all%ROWTYPE;
      lb_update_receipt     BOOLEAN                        := FALSE;
   BEGIN
      SELECT *
        INTO lr_cash_receipt_rec
        FROM ar_cash_receipts_all
       WHERE cash_receipt_id IN p_cash_receipt_id;

      FOR rec_transactionid IN
         cur_transactionid (p_trxn_extension_id      => p_trxn_extension_id,
                            p_cash_receipt_id        => p_cash_receipt_id
                           )
      LOOP
         FOR rec_auth_response IN
            cur_auth_req (p_transaction_id      => rec_transactionid.transactionid)
         LOOP
            IF     rec_auth_response.auth_code IS NOT NULL
               AND rec_auth_response.status = '0000'
            THEN
               lr_cash_receipt_rec.attribute3 := '1';
               lb_update_receipt := TRUE;
            END IF;

            IF     rec_auth_response.ps2000_value IS NOT NULL
               AND rec_auth_response.ret_code_value IS NOT NULL
            THEN
               lr_cash_receipt_rec.attribute4 :=
                     rec_auth_response.ps2000_value
                  || rec_auth_response.ret_code_value;
               lb_update_receipt := TRUE;
            END IF;

            IF lb_update_receipt
            THEN
               lr_cash_receipt_rec.attribute_category := 'SALES_ACCT';
               lr_cash_receipt_rec.last_update_date := SYSDATE;
               lr_cash_receipt_rec.last_updated_by :=
                                       NVL (fnd_profile.VALUE ('USER_ID'),
                                            -1);

               UPDATE ar_cash_receipts_all
                  SET ROW = lr_cash_receipt_rec
                WHERE cash_receipt_id = lr_cash_receipt_rec.cash_receipt_id;
            END IF;
         END LOOP;
      END LOOP;
   END process_ps2000_info;

  /*End-Added for R12 upgrade retrofit*/
/*========================================================================
 | Prototype Declarations Functions
 *=======================================================================*/
/*========================================================================
 | PUBLIC function get_credit_card_type
 |
 | DESCRIPTION
 |      Determines if a credit card number is valid
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 |
 |
 |
 | PARAMETERS
 |      credit_card_number   IN      Credit card number --
 |                                   without white spaces
 |
 | RETURNS
 |      TRUE  if credit card number is valid
 |      FALSE if credit card number is invalid
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 23-JAN-2001           O Steinmeier      Created
 |
 *=======================================================================*/
   FUNCTION is_credit_card_number_valid (p_credit_card_number IN VARCHAR2)
      RETURN NUMBER
   IS
      TYPE numeric_tab_typ IS TABLE OF NUMBER
         INDEX BY BINARY_INTEGER;

      TYPE character_tab_typ IS TABLE OF CHAR (1)
         INDEX BY BINARY_INTEGER;

      l_stripped_num_table      numeric_tab_typ;
      /* Holds credit card number stripped of white spaces */
      l_product_table           numeric_tab_typ;
      /* Table of cc digits multiplied by 2 or 1,for validity check */
      l_len_credit_card_num     NUMBER          := 0;
      /* Length of credit card number stripped of white spaces */
      l_product_tab_sum         NUMBER          := 0;
      /* Sum of digits in product table */
      l_actual_cc_check_digit   NUMBER          := 0;
      /* First digit of credit card, numbered from right to left */
      l_mod10_check_digit       NUMBER          := 0;
      /* Check digit after mod10 algorithm is applied */
      j                         NUMBER          := 0;
   /* Product table index */
   BEGIN
      arp_util.DEBUG ('xx_ar_irec_payments_pkg.is_credit_card_number_valid()+0');

      SELECT LENGTHB (p_credit_card_number)
        INTO l_len_credit_card_num
        FROM DUAL;

      FOR i IN 1 .. l_len_credit_card_num
      LOOP
         SELECT TO_NUMBER (SUBSTRB (p_credit_card_number, i, 1))
           INTO l_stripped_num_table (i)
           FROM DUAL;
      END LOOP;

      l_actual_cc_check_digit := l_stripped_num_table (l_len_credit_card_num);

      FOR i IN 1 .. l_len_credit_card_num - 1
      LOOP
         IF (MOD (l_len_credit_card_num + 1 - i, 2) > 0)
         THEN
            -- Odd numbered digit.  Store as is, in the product table.
            j := j + 1;
            l_product_table (j) := l_stripped_num_table (i);
         ELSE
            -- Even numbered digit.  Multiply digit by 2 and store in the product table.
            -- Numbers beyond 5 result in 2 digits when multiplied by 2. So handled seperately.
            IF (l_stripped_num_table (i) >= 5)
            THEN
               j := j + 1;
               l_product_table (j) := 1;
               j := j + 1;
               l_product_table (j) := (l_stripped_num_table (i) - 5) * 2;
            ELSE
               j := j + 1;
               l_product_table (j) := l_stripped_num_table (i) * 2;
            END IF;
         END IF;
      END LOOP;

      -- Sum up the product table's digits
      FOR k IN 1 .. j
      LOOP
         l_product_tab_sum := l_product_tab_sum + l_product_table (k);
      END LOOP;

      l_mod10_check_digit := MOD ((10 - MOD (l_product_tab_sum, 10)), 10);

      -- If actual check digit and check_digit after mod10 don't match, the credit card is an invalid one.
      IF (l_mod10_check_digit <> l_actual_cc_check_digit)
      THEN
         arp_util.DEBUG ('Card is Valid');
         arp_util.DEBUG
                       ('xx_ar_irec_payments_pkg.is_credit_card_number_valid()-');
         RETURN (0);
      ELSE
         arp_util.DEBUG ('Card is not Valid');
         arp_util.DEBUG
                       ('xx_ar_irec_payments_pkg.is_credit_card_number_valid()-');
         RETURN (1);
      END IF;
   END is_credit_card_number_valid;

/*========================================================================
 | PUBLIC function get_credit_card_type
 |
 | DESCRIPTION
 |      Determines for a given credit card number the credit card type.
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      credit_card_number   IN      Credit card number
 |
 | RETURNS
 |      credit_card type (based on lookup type  AR_IREC_CREDIT_CARD_TYPE
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 22-JAN-2001           O Steinmeier      Created
 | 11-AUG-2008          avepati             Bug 6493495 - TST1203.XB5.QA: CREDIT CARD PAYMENT NOT WORKING
 |
 *=======================================================================*/
   FUNCTION get_credit_card_type (p_credit_card_number IN VARCHAR2)
      RETURN VARCHAR2
   IS
       /*-----------------------------------------------------------------------+
      | Use for file debug or standard output debug                           |
      +-----------------------------------------------------------------------*/

      --   arp_standard.debug('AR_IREC_PAYMENTS.get_credit_card_type()+');

      --   arp_standard.debug(' p_credit_card_number :' || p_credit_card_number);
      l_card_issuer    iby_creditcard_issuers_b.card_issuer_code%TYPE;
      l_issuer_range   iby_cc_issuer_ranges.cc_issuer_range_id%TYPE;
      l_card_prefix    iby_cc_issuer_ranges.card_number_prefix%TYPE;
      l_digit_check    iby_creditcard_issuers_b.digit_check_flag%TYPE;

      CURSOR c_range (
         ci_card_number   IN   iby_creditcard.ccnumber%TYPE,
         ci_card_len      IN   NUMBER
      )
      IS
         SELECT cc_issuer_range_id, r.card_issuer_code, card_number_prefix,
                NVL (digit_check_flag, 'N')
           FROM iby_cc_issuer_ranges r, iby_creditcard_issuers_b i
          WHERE (card_number_length = ci_card_len)
            AND (INSTR (ci_card_number, card_number_prefix) = 1)
            AND (r.card_issuer_code = i.card_issuer_code);
   BEGIN
      IF (c_range%ISOPEN)
      THEN
         CLOSE c_range;
      END IF;

      OPEN c_range (p_credit_card_number, LENGTH (p_credit_card_number));

      FETCH c_range
       INTO l_issuer_range, l_card_issuer, l_card_prefix, l_digit_check;

      CLOSE c_range;

--   arp_standard.debug(' l_card_issuer  :' || l_card_issuer);
      IF (l_card_issuer IS NULL)
      THEN
         l_card_issuer := 'UNKNOWN';
         l_digit_check := 'N';
      END IF;

      RETURN l_card_issuer;
   END get_credit_card_type;

/*========================================================================
 | PUBLIC function get_exchange_rate
 |
 | DESCRIPTION
 |      Returns exchange rate information
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 |
 |
 |
 |
 | RETURNS
 |
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 27-FEB-2001           O Steinmeier      Created
 |
 *=======================================================================*/
   PROCEDURE get_exchange_rate (
      p_trx_currency_code        IN              VARCHAR2,
      p_trx_exchange_rate        IN              NUMBER,
      p_def_exchange_rate_date   IN              DATE DEFAULT TRUNC (SYSDATE),
      p_exchange_rate            OUT NOCOPY      NUMBER,
      p_exchange_rate_type       OUT NOCOPY      VARCHAR2,
      p_exchange_rate_date       OUT NOCOPY      DATE
   )
   IS
      l_fixed_rate       VARCHAR2 (30);
      l_procedure_name   VARCHAR2 (30);
      l_debug_info       VARCHAR2 (200);
   BEGIN
      l_procedure_name := '.get_exchange_rate';
-- By default set the exchange rate date to the proposed default.
--------------------------------------------------------------------------------
      l_debug_info := 'Set the exchange rate date to the proposed default';
--------------------------------------------------------------------------------
      p_exchange_rate_date := p_def_exchange_rate_date;

      -- first check if invoice is in foreign currency:
      IF (p_trx_currency_code = arp_global.functional_currency)
      THEN
-- trx currency is base currency; no exchange rate needed.
--------------------------------------------------------------------------------
         l_debug_info :=
             'Transaction currency is base currency; no exchange rate needed';

--------------------------------------------------------------------------------
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG
                           ('Trx currency is functional --> no exchange rate');
         END IF;

         p_exchange_rate := NULL;
         p_exchange_rate_type := NULL;
         p_exchange_rate_date := NULL;
         RETURN;
      END IF;

-- check if currencies have fixed-rate relationship
--------------------------------------------------------------------------------
      l_debug_info := 'Check if currencies have fixed-rate relationship';
--------------------------------------------------------------------------------
      l_fixed_rate :=
         gl_currency_api.is_fixed_rate (p_trx_currency_code,
                                        arp_global.functional_currency,
                                        p_exchange_rate_date
                                       );

      IF l_fixed_rate = 'Y'
      THEN
--------------------------------------------------------------------------
         l_debug_info := 'Exchange rate is fixed';

--------------------------------------------------------------------------
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG ('Fixed Rate');
         END IF;

         p_exchange_rate_type := 'EMU FIXED';

         /* no need to get rate; rct api will get it anyway

         p_exchange_rate := arpcurr.getrate
                 (p_trx_currency_code,
                  arp_global.functional_currency,
                  p_exchange_rate_date,
                  p_exchange_rate_type);

         */
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG ('Rate = ' || TO_CHAR (p_exchange_rate));
         END IF;
      ELSE    -- exchange rate is not fixed --> check profile for default type
-------------------------------------------------------------------------------------
         l_debug_info :=
            'Exchange rate is not fixed - check profile option for default type';

-------------------------------------------------------------------------------------
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG ('No Fixed Rate');
         END IF;

         p_exchange_rate_type :=
                           fnd_profile.VALUE ('AR_DEFAULT_EXCHANGE_RATE_TYPE');

         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (   'Profile option default exch rate type: '
                                || p_exchange_rate_type
                               );
         END IF;

         IF (p_exchange_rate_type IS NOT NULL)
         THEN
-- try to get exchange rate from GL for this rate type
-------------------------------------------------------------------------------------------
            l_debug_info :=
               'Exchange rate type obtained from profile option - get exchange rate from GL';
-------------------------------------------------------------------------------------------
            p_exchange_rate :=
               arpcurr.getrate (p_trx_currency_code,
                                arp_global.functional_currency,
                                p_exchange_rate_date,
                                p_exchange_rate_type
                               );

            IF (pg_debug = 'Y')
            THEN
               arp_standard.DEBUG ('Rate = ' || TO_CHAR (p_exchange_rate));
            END IF;

            IF p_exchange_rate = -1
            THEN                                        -- no rate found in GL
-------------------------------------------------------------------------------------------
               l_debug_info :=
                   'Exchange rate not found in GL- use invoice exchange rate';

-------------------------------------------------------------------------------------------
               IF (pg_debug = 'Y')
               THEN
                  arp_standard.DEBUG
                                ('no conversion rate found... using trx rate');
               END IF;

               p_exchange_rate_type := 'User';
               p_exchange_rate := p_trx_exchange_rate;
            ELSE -- rate was successfully derived --> null it out so
                 -- rct api can rederive it (it doesn't allow a derivable rate
                 -- to be passed in!)
               p_exchange_rate := NULL;
            END IF;
         ELSE    -- rate type profile is not set --> use invoice exchange rate
-------------------------------------------------------------------------------------------
            l_debug_info :=
                      'Rate type profile not set - use invoice exchange rate';
-------------------------------------------------------------------------------------------
            p_exchange_rate_type := 'User';
            p_exchange_rate := p_trx_exchange_rate;
         END IF;
      END IF;                                     -- fixed/non-fixed rate case

      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG ('Leaving get_exchange_rate: ');
         arp_standard.DEBUG ('p_exchange_rate_type = ' || p_exchange_rate_type
                            );
         arp_standard.DEBUG (   'p_exchange_rate      = '
                             || TO_CHAR (p_exchange_rate)
                            );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         write_debug_and_log (   '- Transaction Currency Code: '
                              || p_trx_currency_code
                             );
         write_debug_and_log (   '- Transaction Exchange Rate: '
                              || p_trx_exchange_rate
                             );
         write_debug_and_log ('- Exchange Rate found: ' || p_exchange_rate);
         write_debug_and_log ('ERROR =>' || SQLERRM);
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END get_exchange_rate;

/*========================================================================
 | PUBLIC function get_payment_information
 |
 | DESCRIPTION
 |      Returns payment method and remittance bank information
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 |
 |
 |
 |
 | RETURNS
 |
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 13-FEB-2001           O Steinmeier      Created
 | 26-APR-2004           vnb               Bug # 3467287 - Customer Site ID made an input
 |                               parameter.
 | 22-JUN-2007     mbolli        Bug#6109909 - Not using 'Payment Method' set at
 |                  customer/site level
 | 19-AUG-2009   nkanchan   Bug # 8780501 - Payments are failing
 |
 *=======================================================================*/
   PROCEDURE get_payment_information (
      p_customer_id               IN              NUMBER,
      p_site_use_id               IN              NUMBER DEFAULT NULL,
      p_payment_schedule_id       IN              NUMBER,
      p_payment_instrument        IN              VARCHAR2,
      p_trx_date                  IN              DATE,
      p_currency_code             OUT NOCOPY      VARCHAR2,
      p_exchange_rate             OUT NOCOPY      VARCHAR2,
      p_receipt_method_id         OUT NOCOPY      NUMBER,
      p_remit_bank_account_id     OUT NOCOPY      NUMBER,
      p_receipt_creation_status   OUT NOCOPY      VARCHAR2,
      p_trx_number                OUT NOCOPY      VARCHAR2,
      p_payment_channel_code      OUT NOCOPY      VARCHAR2
   )
   IS
      CURSOR payment_method_info_cur
      IS
         SELECT rm.receipt_method_id receipt_method_id,
                rm.payment_channel_code payment_channel_code,
                rc.creation_status receipt_creation_status
           FROM ar_system_parameters sp,
                ar_receipt_classes rc,
                ar_receipt_methods rm
          WHERE rm.receipt_method_id =
                   DECODE
                      (p_payment_instrument,

                       /* J Rautiainen ACH Implementation */
                       'BANK_ACCOUNT', sp.irec_ba_receipt_method_id,
                       /* J Rautiainen ACH Implementation */
                       sp.irec_cc_receipt_method_id
                      )                  /* J Rautiainen ACH Implementation */
            AND rm.receipt_class_id = rc.receipt_class_id;

      --Bug3186314: Cursor to get the payment method at customer/site level.
      CURSOR cust_payment_method_info_cur (
         p_siteuseid   NUMBER,
         p_currcode    VARCHAR2
      )
      IS
         SELECT   arm.receipt_method_id receipt_method_id,
                  arm.payment_channel_code payment_channel_code,
                  arc.creation_status receipt_creation_status
             FROM ar_receipt_methods arm,
                  ra_cust_receipt_methods rcrm,
                  ar_receipt_method_accounts arma,
                  ce_bank_acct_uses_ou_v aba,
                  ce_bank_accounts cba,
                  ar_receipt_classes arc
            WHERE arm.receipt_method_id = rcrm.receipt_method_id
              AND arm.receipt_method_id = arma.receipt_method_id
              AND arm.receipt_class_id = arc.receipt_class_id
              AND rcrm.customer_id = p_customer_id
              AND arma.remit_bank_acct_use_id = aba.bank_acct_use_id
              AND aba.bank_account_id = cba.bank_account_id
              AND (   NVL (rcrm.site_use_id, p_siteuseid) = p_siteuseid
                   OR (p_siteuseid IS NULL AND rcrm.site_use_id IS NULL)
                  )
--Bug#6109909
   --AND       rcrm.primary_flag          = 'Y'
              AND (   cba.currency_code = p_currcode
                   OR cba.receipt_multi_currency_flag = 'Y'
                  )
              AND (   (    p_payment_instrument = 'BANK_ACCOUNT'
--Bug 6024713: Choose 'NONE' if arm.payment_type_code is NULL
--Bug#6109909:
      -- In 11i The 'PaymentMethod' in UI maps to 'payment_type_code' column of table ar_receipts_methods
      -- and in R12, it maps to 'payment_channel_code' whose values are taken from IBY sources.
      -- In R12, the 'payment_type_code' is 'NONE' for new records.
      -- AND In R12, Here we are not handling the code for the other payment Methods like Bills Receivable, Debit Card etc..,

                       --  and nvl(arm.payment_type_code, 'NONE') <> 'CREDIT_CARD'
                       AND arm.payment_channel_code <> 'CREDIT_CARD'
                       AND arc.remit_flag = 'Y'
                       AND arc.confirm_flag = 'N'
                      )
                   OR (    p_payment_instrument <> 'BANK_ACCOUNT'
                       --Bug#6109909
                                   --and nvl(arm.payment_type_code, 'NONE') = 'CREDIT_CARD')
                       AND arm.payment_channel_code = 'CREDIT_CARD'
                      )
                  )
              -- Bug#6109909:
                 -- In R12,Currency code is not mandatory on the customer bank account and so removing the
                 -- below condition.
                 -- Observations for the below condition, if it requires in future:
                 -- a. The where caluse criteria 'party_id = p_customer_id' should be replaced
                 --    with 'cust_account_id = p_customer_id'
                 -- b. For 'AUTOMATIC' creation methods, Don't validate the currencyCode for
                 -- 'Credit Card' instrucment types. Here validate only for 'BankAccount'

              /*

                 AND      ( arc.creation_method_code = 'MANUAL' or
                          ( arc.creation_method_code = 'AUTOMATIC' and
              --Bug 4947418: Modified the following query as ar_customer_bank_accounts_v
              --has been obsoleted in r12.
                            p_currcode in (select currency_code from
                    iby_fndcpt_payer_assgn_instr_v
                    where party_id=p_customer_id)))
                 */

              -- AND       aba.set_of_books_id = arp_trx_global.system_info.system_parameters.set_of_books_id
              AND TRUNC (NVL (aba.end_date, p_trx_date)) >= TRUNC (p_trx_date)
--Bug 6024713: Added TRUNC for the left side for the below 3 criterias
              AND TRUNC (p_trx_date) BETWEEN TRUNC (NVL (arm.start_date,
                                                         p_trx_date
                                                        )
                                                   )
                                         AND TRUNC (NVL (arm.end_date,
                                                         p_trx_date
                                                        )
                                                   )
              AND TRUNC (p_trx_date) BETWEEN TRUNC (NVL (rcrm.start_date,
                                                         p_trx_date
                                                        )
                                                   )
                                         AND TRUNC (NVL (rcrm.end_date,
                                                         p_trx_date
                                                        )
                                                   )
              AND TRUNC (p_trx_date) BETWEEN TRUNC (arma.start_date)
                                         AND TRUNC (NVL (arma.end_date,
                                                         p_trx_date
                                                        )
                                                   )
         ORDER BY rcrm.primary_flag DESC;

--Bug 6339265 : Cursor to get CC Payment Method set in the profile OIR_CC_PMT_METHOD.
      CURSOR cc_profile_pmt_method_info_cur
      IS
         SELECT arm.receipt_method_id receipt_method_id,
                arm.payment_channel_code payment_channel_code,
                arc.creation_status receipt_creation_status
           FROM ar_receipt_methods arm,
                ar_receipt_method_accounts arma,
                ce_bank_acct_uses_ou_v aba,
                ce_bank_accounts cba,
                ar_receipt_classes arc
          WHERE arm.payment_channel_code = 'CREDIT_CARD'
            AND arm.receipt_method_id =
                   NVL (TO_NUMBER (fnd_profile.VALUE ('OIR_CC_PMT_METHOD')),
                        arm.receipt_method_id
                       )
            AND arm.receipt_method_id = arma.receipt_method_id
            AND arm.receipt_class_id = arc.receipt_class_id
            AND arma.remit_bank_acct_use_id = aba.bank_acct_use_id
            AND aba.bank_account_id = cba.bank_account_id
            AND (   cba.currency_code = p_currency_code
                 OR cba.receipt_multi_currency_flag = 'Y'
                )
            AND TRUNC (NVL (aba.end_date, p_trx_date)) >= TRUNC (p_trx_date)
            AND TRUNC (p_trx_date) BETWEEN TRUNC (NVL (arm.start_date,
                                                       p_trx_date
                                                      )
                                                 )
                                       AND TRUNC (NVL (arm.end_date,
                                                       p_trx_date
                                                      )
                                                 )
            AND TRUNC (p_trx_date) BETWEEN TRUNC (arma.start_date)
                                       AND TRUNC (NVL (arma.end_date,
                                                       p_trx_date
                                                      )
                                                 );

      --Bug 6339265 : Cursor to get Bank Acount Payment Method set in the profile OIR_BA_PMT_METHOD.
      CURSOR ba_profile_pmt_method_info_cur
      IS
         SELECT arm.receipt_method_id receipt_method_id,
                arm.payment_channel_code payment_channel_code,
                arc.creation_status receipt_creation_status
           FROM ar_receipt_methods arm,
                ar_receipt_method_accounts arma,
                ce_bank_acct_uses_ou_v aba,
                ce_bank_accounts cba,
                ar_receipt_classes arc
          WHERE NVL (arm.payment_channel_code, 'NONE') <> 'CREDIT_CARD'
            AND arm.receipt_method_id =
                   NVL (TO_NUMBER (fnd_profile.VALUE ('OIR_BA_PMT_METHOD')),
                        arm.receipt_method_id
                       )
            AND arm.receipt_method_id = arma.receipt_method_id
            AND arm.receipt_class_id = arc.receipt_class_id
            AND arma.remit_bank_acct_use_id = aba.bank_acct_use_id
            AND aba.bank_account_id = cba.bank_account_id
            AND (   cba.currency_code = p_currency_code
                 OR cba.receipt_multi_currency_flag = 'Y'
                )
            AND TRUNC (NVL (aba.end_date, p_trx_date)) >= TRUNC (p_trx_date)
            AND TRUNC (p_trx_date) BETWEEN TRUNC (NVL (arm.start_date,
                                                       p_trx_date
                                                      )
                                                 )
                                       AND TRUNC (NVL (arm.end_date,
                                                       p_trx_date
                                                      )
                                                 )
            AND TRUNC (p_trx_date) BETWEEN TRUNC (arma.start_date)
                                       AND TRUNC (NVL (arma.end_date,
                                                       p_trx_date
                                                      )
                                                 );

      CURSOR payment_schedule_info_cur
      IS
         SELECT customer_site_use_id, invoice_currency_code, exchange_rate,
                trx_number
           FROM ar_payment_schedules
          WHERE payment_schedule_id = p_payment_schedule_id;

      payment_method_info          payment_method_info_cur%ROWTYPE;
      payment_schedule_info        payment_schedule_info_cur%ROWTYPE;
      cust_payment_method_info     cust_payment_method_info_cur%ROWTYPE;
      cc_profile_pmt_method_info   cc_profile_pmt_method_info_cur%ROWTYPE;
      ba_profile_pmt_method_info   ba_profile_pmt_method_info_cur%ROWTYPE;
      l_customer_id                ra_cust_receipt_methods.customer_id%TYPE;
      l_site_use_id                ra_cust_receipt_methods.site_use_id%TYPE;
      l_currency_code              ar_payment_schedules_all.invoice_currency_code%TYPE;
      l_procedure_name             VARCHAR2 (30);
      l_debug_info                 VARCHAR2 (200);
   BEGIN
      l_procedure_name := '.get_payment_information';
--------------------------------------------------------------------
      l_debug_info := 'Get payment schedule information';

--------------------------------------------------------------------
      OPEN payment_schedule_info_cur;

      FETCH payment_schedule_info_cur
       INTO payment_schedule_info;

      CLOSE payment_schedule_info_cur;

      l_currency_code := payment_schedule_info.invoice_currency_code;
      l_site_use_id := payment_schedule_info.customer_site_use_id;
      p_trx_number := payment_schedule_info.trx_number;
      p_exchange_rate := payment_schedule_info.exchange_rate;

      -- ### required change: error handling
      -- ### in case the query fails.

      --Bug # 3467287 - The Global Temp table must be striped by Customer and Customer Site.
      IF (p_payment_schedule_id IS NULL)
      THEN
-- this is the case for multiple invoices.
------------------------------------------------------------------------
         l_debug_info :=
                      'There are multiple invoices: get customer information';

------------------------------------------------------------------------
         BEGIN
            SELECT customer_id, customer_site_use_id, currency_code
              INTO l_customer_id, l_site_use_id, l_currency_code
              FROM ar_irec_payment_list_gt
             WHERE customer_id = p_customer_id
               AND customer_site_use_id =
                      NVL (DECODE (p_site_use_id, -1, NULL, p_site_use_id),
                           customer_site_use_id
                          );
         EXCEPTION
            WHEN OTHERS
            THEN
               IF (pg_debug = 'Y')
               THEN
                  arp_standard.DEBUG
                                ('There may be invoices with different sites');
               END IF;
         END;

         IF (l_customer_id IS NULL)
         THEN
            --Code should not come here ideally
            BEGIN
               SELECT   currency_code
                   INTO l_currency_code
                   FROM ar_irec_payment_list_gt
               GROUP BY currency_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  IF (pg_debug = 'Y')
                  THEN
                     arp_standard.DEBUG
                           ('There may be invoices with different currencies');
                  END IF;
            END;
         END IF;
      END IF;

      -- IF Customer Site Use Id is -1 then it is to be set as null
      IF (l_site_use_id = -1)
      THEN
         l_site_use_id := NULL;
      END IF;

      IF (p_payment_instrument <> 'BANK_ACCOUNT')
      THEN
---------------------------------------------------------------------------------
         l_debug_info :=
            'Get payment method information from the OIR_CC_PMT_METHOD profile';

---------------------------------------------------------------------------------
         IF (    fnd_profile.VALUE ('OIR_CC_PMT_METHOD') IS NOT NULL
             AND fnd_profile.VALUE ('OIR_CC_PMT_METHOD') <> 'DISABLED'
            )
         THEN
            BEGIN
               OPEN cc_profile_pmt_method_info_cur;

               FETCH cc_profile_pmt_method_info_cur
                INTO cc_profile_pmt_method_info;

               /* If CC Payment Method set is NULL or DISABLED or an invalid payment method, it returns NO rows */
               IF cc_profile_pmt_method_info_cur%FOUND
               THEN
                  p_receipt_creation_status :=
                           cc_profile_pmt_method_info.receipt_creation_status;
                  p_receipt_method_id :=
                                 cc_profile_pmt_method_info.receipt_method_id;
                  p_payment_channel_code :=
                              cc_profile_pmt_method_info.payment_channel_code;
               END IF;

               CLOSE cc_profile_pmt_method_info_cur;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_debug_info :=
                        'Invalid Payment Method is Set in the profile OIR_CC_PMT_METHOD. Value in profile='
                     || fnd_profile.VALUE ('OIR_CC_PMT_METHOD');

                  IF (fnd_log.level_statement >=
                                               fnd_log.g_current_runtime_level
                     )
                  THEN
                     fnd_log.STRING (fnd_log.level_statement,
                                     g_pkg_name || l_procedure_name,
                                     l_debug_info || ':ERROR =>' || SQLERRM
                                    );
                  END IF;
            END;
         END IF;
      END IF;

      IF (p_payment_instrument <> 'CREDIT_CARD')
      THEN
---------------------------------------------------------------------------------
         l_debug_info :=
            'Get payment method information from the OIR_BA_PMT_METHOD profile';

---------------------------------------------------------------------------------
         IF (    fnd_profile.VALUE ('OIR_BA_PMT_METHOD') IS NOT NULL
             AND fnd_profile.VALUE ('OIR_BA_PMT_METHOD') <> 'DISABLED'
            )
         THEN
            BEGIN
               OPEN ba_profile_pmt_method_info_cur;

               FETCH ba_profile_pmt_method_info_cur
                INTO ba_profile_pmt_method_info;

               /* If BA Payment Method set is NULL or DISABLED or an invalid payment method, it returns NO rows */
               IF ba_profile_pmt_method_info_cur%FOUND
               THEN
                  p_receipt_creation_status :=
                           ba_profile_pmt_method_info.receipt_creation_status;
                  p_receipt_method_id :=
                                 ba_profile_pmt_method_info.receipt_method_id;
                  p_payment_channel_code :=
                              ba_profile_pmt_method_info.payment_channel_code;
               END IF;

               CLOSE ba_profile_pmt_method_info_cur;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_debug_info :=
                        'Invalid Payment Method is Set in the profile OIR_BA_PMT_METHOD. Value in profile='
                     || fnd_profile.VALUE ('OIR_BA_PMT_METHOD');

                  IF (fnd_log.level_statement >=
                                               fnd_log.g_current_runtime_level
                     )
                  THEN
                     fnd_log.STRING (fnd_log.level_statement,
                                     g_pkg_name || l_procedure_name,
                                     l_debug_info || ':ERROR =>' || SQLERRM
                                    );
                  END IF;
            END;
         END IF;
      END IF;

      IF (p_receipt_method_id IS NULL)
      THEN
---------------------------------------------------------------------------------
         l_debug_info :=
             'Get payment method information from the relevant customer site';

---------------------------------------------------------------------------------
         OPEN cust_payment_method_info_cur (l_site_use_id, l_currency_code);

         FETCH cust_payment_method_info_cur
          INTO cust_payment_method_info;

         IF cust_payment_method_info_cur%FOUND
         THEN
            p_receipt_creation_status :=
                             cust_payment_method_info.receipt_creation_status;
            p_receipt_method_id := cust_payment_method_info.receipt_method_id;
            p_payment_channel_code :=
                                cust_payment_method_info.payment_channel_code;
         END IF;

         CLOSE cust_payment_method_info_cur;
      END IF;

      IF (p_receipt_method_id IS NULL)
      THEN
----------------------------------------------------------------------------------------
         l_debug_info :=
            'Get payment method information from the customer at the account level';
----------------------------------------------------------------------------------------
         l_site_use_id := NULL;

         OPEN cust_payment_method_info_cur (l_site_use_id, l_currency_code);

         FETCH cust_payment_method_info_cur
          INTO cust_payment_method_info;

         IF cust_payment_method_info_cur%FOUND
         THEN
            p_receipt_creation_status :=
                             cust_payment_method_info.receipt_creation_status;
            p_receipt_method_id := cust_payment_method_info.receipt_method_id;
            p_payment_channel_code :=
                                cust_payment_method_info.payment_channel_code;
         END IF;

         CLOSE cust_payment_method_info_cur;
      END IF;

      IF (p_receipt_method_id IS NULL)
      THEN
-- get from system parameters
----------------------------------------------------------------------------------------
         l_debug_info :=
                  'Get payment method information from the system parameters';

----------------------------------------------------------------------------------------
         OPEN payment_method_info_cur;

         FETCH payment_method_info_cur
          INTO payment_method_info;

         IF payment_method_info_cur%FOUND
         THEN
            p_receipt_creation_status :=
                                  payment_method_info.receipt_creation_status;
            p_receipt_method_id := payment_method_info.receipt_method_id;
            p_payment_channel_code :=
                                     payment_method_info.payment_channel_code;
         END IF;

         CLOSE payment_method_info_cur;
      END IF;

      --Bug # 3467287 - p_site_use_id is made an input parameter.
      --p_site_use_id   := l_site_use_id;
      p_currency_code := l_currency_code;

      /*Start - Added for R12 upgrade retrofit */

      --V2.0, Added below IF Statement to redirect the receipt_method_id to pick
      --from translation table instead of system parameters i.e. US_IREC ECHECK_OD
      IF     (p_payment_instrument = 'BANK_ACCOUNT')
         AND p_receipt_method_id IS NOT NULL
      THEN
         SELECT arm.receipt_method_id
           INTO p_receipt_method_id
           FROM xx_fin_translatedefinition xftd,
                xx_fin_translatevalues xftv,
                ar_receipt_methods arm
          WHERE xftd.translate_id = xftv.translate_id
            AND xftd.translation_name = 'ACH_ECHECK_DETAILS'
            AND xftv.source_value1 = 'Receipt Method'
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y'
            AND xftv.target_value1 = arm.NAME;
      --V6.1, Added else if condition for CC, to bypass Remittance
      ELSIF     (p_payment_instrument = 'CC_ACCOUNT')
            AND p_receipt_method_id IS NOT NULL
      THEN
         SELECT arm.receipt_method_id
           INTO p_receipt_method_id
           FROM xx_fin_translatedefinition xftd,
                xx_fin_translatevalues xftv,
                ar_receipt_methods arm
          WHERE xftd.translate_id = xftv.translate_id
            AND xftd.translation_name = 'ACH_ECHECK_DETAILS'
            AND UPPER (xftv.source_value1) = 'CC_RECEIPT_METHOD'
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y'
            AND xftv.target_value1 = arm.NAME;
      END IF;
   --V2.0, IF Statement ends her
   /*End - Added for R12 upgrade retrofit */
   EXCEPTION
      WHEN OTHERS
      THEN
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         write_debug_and_log ('- Customer Id: ' || p_customer_id);
         write_debug_and_log ('- Customer Site Id: ' || p_site_use_id);
         write_debug_and_log ('- Receipt Method Id: ' || p_receipt_method_id);
         write_debug_and_log (   '- Payment Schedule Id: '
                              || p_payment_schedule_id
                             );
         write_debug_and_log ('ERROR =>' || SQLERRM);
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END get_payment_information;

/*========================================================================
 | PUBLIC procedure update_expiration_date
 |
 | DESCRIPTION
 |      Updates credit card expiration date
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 |      p_bank_account_id         Credit Card bank account id
 |      p_expiration_date    New expiration date
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 10-FEB-2001           O Steinmeier      Created
 |
 | Removed code 'BANK_ACCOUNT_NUM = p_bank_account_num AND ' from select for bug # 9046643
 | 06-Feb-2013           melapaku  Bug16262617 - cannot remove end date entered via ireceivables pay function
 | 01-Mar-2013           melapaku  Bug16420473 - CANNOT END DATE BANK ACC WHICH IS ASSOCIATED AT ACC AND SITE LEVEL IN
 |                                               IRECEIVABLES
 | 23-Jul-2014           gnramasa  Bug17475275 - TST1223:CREDIT CARD DETAILS BEING SHOWN TWICE, WHEN PAID PART BY PART
 |                                 Added new parameter p_instr_assignment_id and used this to fetch the details from
 |                                 IBY_FNDCPT_PAYER_ASSGN_INSTR_V instead of INSTRUMENT_ID
 | 21-Jan-2015           gnramasa  Bug20359618 - CUSTOMER (BANK ACCT TRANSFER) BANK PRIORITY CHGS WHEN IRECEIVABLES IS USED
 *=======================================================================*/
   PROCEDURE update_expiration_date (
      p_bank_account_id         IN              NUMBER,
      p_expiration_date         IN              DATE,
      p_payment_instrument      IN              VARCHAR2,
      p_branch_id               IN              iby_ext_bank_accounts.branch_id%TYPE,
      p_bank_id                 IN              iby_ext_bank_accounts.bank_id%TYPE,
      p_bank_account_num        IN              iby_ext_bank_accounts.bank_account_num%TYPE,
      p_currency                IN              iby_ext_bank_accounts.currency_code%TYPE,
      p_object_version_number   IN              iby_ext_bank_accounts.object_version_number%TYPE,
      x_return_status           OUT NOCOPY      VARCHAR,
      x_msg_count               OUT NOCOPY      NUMBER,
      x_msg_data                OUT NOCOPY      VARCHAR2,
      p_customer_id             IN              NUMBER,
      p_customer_site_id        IN              NUMBER,
      p_instr_assignment_id     IN              NUMBER DEFAULT NULL
   )
   IS                    /* Added for Bug17475275 gnramasa 23rd July 2014   */
--Modified for Bug17475275 : Start
/*
CURSOR instr_details(p_bank_account_id IN NUMBER,
                      l_party_id IN NUMBER,
                      l_customer_site_id IN NUMBER) IS
  select org_id,instr_assignment_id,assignment_start_date,acct_site_use_id
  from IBY_FNDCPT_PAYER_ASSGN_INSTR_V
  where INSTRUMENT_ID =  p_bank_account_id AND PARTY_ID = l_party_id
  AND((l_customer_site_id IS NOT NULL AND ACCT_SITE_USE_ID = l_customer_site_id ) OR (l_customer_site_id IS NULL AND ACCT_SITE_USE_ID IS NULL));
*/
      CURSOR instr_details (l_instr_assignment_id IN NUMBER)
      IS
         SELECT org_id, instr_assignment_id, assignment_start_date,
                acct_site_use_id,order_of_preference
           FROM iby_fndcpt_payer_assgn_instr_v
          WHERE instr_assignment_id = l_instr_assignment_id;

      l_create_credit_card            iby_fndcpt_setup_pub.creditcard_rec_type;
      l_ext_bank_acct_rec             iby_ext_bankacct_pub.extbankacct_rec_type;
      l_result_rec                    iby_fndcpt_common_pub.result_rec_type;
      l_procedure_name                VARCHAR2 (30);
      l_party_id                      NUMBER;
      l_payercontext_rec_type         iby_fndcpt_common_pub.payercontext_rec_type;
      l_pmtinstrassignment_rec_type   iby_fndcpt_setup_pub.pmtinstrassignment_rec_type;
      l_pmtinstr_rec_type             iby_fndcpt_setup_pub.pmtinstrument_rec_type;
      l_org_id                        NUMBER;
      l_instr_assignment_id           NUMBER;
      l_assignment_start_date         DATE;
      l_assignment_id                 NUMBER (15, 0);
      l_customer_site_id              NUMBER;
      l_acct_site_use_id              NUMBER;
      l_card_issuer                   iby_creditcard.card_issuer_code%type;
      l_priority         iby_fndcpt_payer_assgn_instr_v.order_of_preference%type;
      l_update_priority  varchar2(3);
   BEGIN
      l_procedure_name := '.update_expiration_date';
      write_debug_and_log (   'Input Parameters for update_expiration_date'
                           || ' p_customer_site_id: '
                           || p_customer_site_id
                           || ' p_object_version_number: '
                           || p_object_version_number
                           || ' p_bank_account_id: '
                           || p_bank_account_id
                           || ' p_currency: '
                           || p_currency
                           || ' p_expiration_date: '
                           || p_expiration_date
                           || ' p_customer_id: '
                           || p_customer_id
                           || ' p_branch_id: '
                           || p_branch_id
                           || ' p_instr_assignment_id: '
                           || p_instr_assignment_id
                          );

--Added for Bug#16262617
      IF (p_customer_site_id = -1)
      THEN
         l_customer_site_id := NULL;
      ELSE
         l_customer_site_id := p_customer_site_id;
      END IF;

      IF p_payment_instrument = 'CREDIT_CARD'
      THEN
         write_debug_and_log ('In CC expiration date update');
         /* E1294 - Added for Creditcard Encryption functionality */
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'E1294 Encryption functionality start'
                        );
         DBMS_SESSION.set_context (namespace      => 'XX_AR_IREC_CONTEXT',
                                   ATTRIBUTE      => 'TYPE',
                                   VALUE          => 'EBS'
                                  );

         --Modified for Defect#34441
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'p_bank_account_num ::' || mask_account_number(p_bank_account_num)
                        );
         xx_od_security_key_pkg.encrypt_outlabel
                              (p_module             => 'AJB',
                               p_key_label          => NULL,
                               p_algorithm          => '3DES',
                               p_decrypted_val      => p_bank_account_num,
                               x_encrypted_val      => gc_encrypted_cc_num,
                               x_error_message      => gc_cc_encrypt_error_message,
                               x_key_label          => gc_key_label
                              );
         fnd_log.STRING
            (fnd_log.level_statement,
             g_pkg_name || l_procedure_name,
                'E1294 xx_od_security_key_pkg.encrypt_outlabel error message:'
             || gc_cc_encrypt_error_message
            );

         IF gc_cc_encrypt_error_message IS NOT NULL
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'ERROR IN UPDATING CREDIT CARD'
                           );
            x_msg_data := gc_cc_encrypt_error_message;
            x_return_status := fnd_api.g_ret_sts_error;
            RETURN;
         END IF;

         /* E1294 - End - Added for Creditcard Encryption functionality */
         l_create_credit_card.card_id := p_bank_account_id;
         l_create_credit_card.expiration_date := p_expiration_date;
         /* E1294 - Start - Added for Creditcard Encryption functionality */
      --   l_create_credit_card.attribute4 := gc_encrypted_cc_num;  /* Commented for Defect 35918 */
         l_create_credit_card.attribute5 := gc_key_label;
         /* E1294 - End - Added for Creditcard Encryption functionality */

         iby_fndcpt_setup_pub.update_card
                                   (p_api_version          => 1.0,
                                    p_init_msg_list        => fnd_api.g_true,
                                    p_commit               => fnd_api.g_false,
                                    x_return_status        => x_return_status,
                                    x_msg_count            => x_msg_count,
                                    x_msg_data             => x_msg_data,
                                    p_card_instrument      => l_create_credit_card,
                                    x_response             => l_result_rec
                                   );

         IF (x_return_status <> fnd_api.g_ret_sts_success)
         THEN
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'ERROR IN UPDATING CREDIT CARD'
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               l_result_rec.result_code
                              );
            END IF;

            x_msg_data := l_result_rec.result_code;
            x_return_status := fnd_api.g_ret_sts_error;
            write_error_messages (x_msg_data, x_msg_count);
         END IF;
      ELSE
         write_debug_and_log ('In BA expiration date update');

         -- Modified for Bug#16262617 : Start
         SELECT party_id
           INTO l_party_id
           FROM hz_cust_accounts
          WHERE cust_account_id = p_customer_id;

              /*
          -- Modified for Bug#16420473 :Start
              OPEN instr_details(p_bank_account_id,l_party_id,l_customer_site_id);
              IF (instr_details%NOTFOUND) THEN
                  select org_id,instr_assignment_id,assignment_start_date,acct_site_use_id
                  into l_org_id,l_instr_assignment_id,l_assignment_start_date,l_acct_site_use_id
                  from IBY_FNDCPT_PAYER_ASSGN_INSTR_V
                  where INSTRUMENT_ID =  p_bank_account_id AND PARTY_ID = l_party_id
                  AND ACCT_SITE_USE_ID IS NULL;
                 CLOSE instr_details;
              ELSE
                 FETCH instr_details into l_org_id,l_instr_assignment_id,l_assignment_start_date,l_acct_site_use_id;
                 CLOSE instr_details;
              END IF;
              -- Modified for Bug#16420473 :End
         */
         OPEN instr_details (p_instr_assignment_id);

         FETCH instr_details
          INTO l_org_id, l_instr_assignment_id, l_assignment_start_date,
               l_acct_site_use_id,l_priority;

         CLOSE instr_details;

         l_payercontext_rec_type.payment_function := 'CUSTOMER_PAYMENT';
         l_payercontext_rec_type.party_id := l_party_id;
         l_payercontext_rec_type.cust_account_id := p_customer_id;

         IF (l_acct_site_use_id IS NOT NULL)
         THEN
            l_payercontext_rec_type.org_type := 'OPERATING_UNIT';
            l_payercontext_rec_type.org_id := l_org_id;
            l_payercontext_rec_type.account_site_id := l_acct_site_use_id;
         END IF;

         l_pmtinstr_rec_type.instrument_type := 'BANKACCOUNT';
         l_pmtinstr_rec_type.instrument_id := p_bank_account_id;
         l_pmtinstrassignment_rec_type.assignment_id := l_instr_assignment_id;
         l_pmtinstrassignment_rec_type.instrument := l_pmtinstr_rec_type;
         write_debug_and_log('l_priority :' || l_priority);
          --Get the profile value to decide whether to update the priority to 1 or keep the existing priority
          --Y -> update the priority to 1 -- Default value is Y
          --N -> Keep the existing priority
          l_update_priority := fnd_profile.value('OIR_PAYMENT_UPDATE_PRIORITY');
          write_debug_and_log('l_update_priority :' || l_update_priority);

           --if l_priority is null then
           if nvl(l_update_priority,'Y') = 'N' then
           --l_pmtInstrAssignment_Rec_type.priority		:= l_priority;
           write_debug_and_log('Profile OIR: Payment Update Priority value is No, so priority is not passed to get it updated');
           else
           l_pmtinstrassignment_rec_type.priority		:= 1;
           write_debug_and_log('Profile value is Yes, so priority has to be updated to 1. So passing Priority as 1');
           end if;
         l_pmtinstrassignment_rec_type.start_date := l_assignment_start_date;
         l_pmtinstrassignment_rec_type.end_date := p_expiration_date;
         write_debug_and_log (   'l_instr_assignment_id '
                              || l_instr_assignment_id
                              || 'l_assignment_start_date '
                              || l_assignment_start_date
                              || 'l_org_id '
                              || l_org_id
                              || ' l_party_id '
                              || l_party_id
                              || 'l_payerContext_Rec_type.Account_Site_id '
                              || l_payercontext_rec_type.account_site_id
                              || 'l_customer_site_id '
                              || l_customer_site_id
                             );
         iby_fndcpt_setup_pub.set_payer_instr_assignment
                       (p_api_version             => 1.0,
                        p_init_msg_list           => fnd_api.g_false,
                        p_commit                  => fnd_api.g_false,
                        x_return_status           => x_return_status,
                        x_msg_count               => x_msg_count,
                        x_msg_data                => x_msg_data,
                        p_payer                   => l_payercontext_rec_type,
                        p_assignment_attribs      => l_pmtinstrassignment_rec_type,
                        x_assign_id               => l_assignment_id,
                        x_response                => l_result_rec
                       );

         -- Modified for Bug# 16262617 : End
         IF (x_return_status = fnd_api.g_ret_sts_success)
         THEN
            write_debug_and_log
               ('IBY_FNDCPT_SETUP_PUB.Set_Payer_Instr_Assignment call is success'
               );
         ELSE
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'ERROR IN UPDATING BANK ACCOUNT'
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               x_msg_data
                              );
            END IF;

            x_return_status := fnd_api.g_ret_sts_error;
            write_error_messages (x_msg_data, x_msg_count);
         END IF;
      END IF;
--Modified for Bug17475275 : End
   EXCEPTION
      WHEN OTHERS
      THEN
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         write_debug_and_log ('- Card Id: ' || p_bank_account_id);
         write_debug_and_log ('- Expiration Date: ' || p_expiration_date);
         write_debug_and_log ('ERROR =>' || SQLERRM);
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_msg_pub.ADD;
   END;

/*========================================================================
 | PUBLIC function allow_payment
 |
 | DESCRIPTION
 |      Determines if payment schedule can be paid:
 |
 |   It will return TRUE if
 |
 |   - payment button is enabled via function security
 |     (need to define function)
 |   - the remaining balance of the payment schedule is > 0
 |   - a payment method has been defined in AR_SYSTEM_PARAMETERS
 |     for credit card payments
 |   - a bank account assignment in the currency of the invoice
 |     exists and is active.
 |
 |   Use this function to enable or disable the "Pay" button on
 |   the invoice and invoice activities pages.
 |
 |
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 |      p_payment_schedule_id     Payment Schedule to be paid
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 13-FEB-2001           O Steinmeier      Created
 | 16-Feb-2015           gnramasa  Bug 20502416 - IREC- CODE: INCONSISTENT BEHAVIOR OF PAY BUTTON IN ACCNT DETAIL AND TRX DETAIL
 *=======================================================================*/
   FUNCTION allow_payment (
      p_payment_schedule_id   IN   NUMBER,
      p_customer_id           IN   NUMBER,
      p_customer_site_id      IN   NUMBER,
      p_org_id                IN   NUMBER  Default null
   )
      RETURN BOOLEAN
   IS
      l_ps_balance            NUMBER;
      l_bank_account_method   NUMBER;
      l_credit_card_method    NUMBER;   /* J Rautiainen ACH Implementation */
      l_currency_code         ar_payment_schedules.invoice_currency_code%TYPE;
      l_class                 ar_payment_schedules.CLASS%TYPE;
      l_creation_status       ar_receipt_classes.creation_status%TYPE;
   BEGIN
      -- check that function security is allowing access to payment button
      IF NOT fnd_function.TEST ('ARW_PAY_INVOICE')
      THEN
         RETURN FALSE;
      END IF;

      -- check trx type and balance: trx type must be debit item, balance > 0
      SELECT amount_due_remaining, CLASS, invoice_currency_code
        INTO l_ps_balance, l_class, l_currency_code
        FROM ar_payment_schedules
       WHERE payment_schedule_id = p_payment_schedule_id;

      --Bug 4161986 - Pay Icon does not appear in the ChargeBack and its activities page. Added the class CB(Chargeback)
      IF l_ps_balance <= 0
         OR l_class NOT IN ('INV', 'DEP', 'GUAR', 'DM', 'CB')
      THEN
         RETURN FALSE;
      END IF;

      -- verify that method is set up
      l_credit_card_method :=
         is_credit_card_payment_enabled (p_customer_id,
                                         p_customer_site_id,
                                         l_currency_code,
                                         p_org_id
                                        );

      -- Bug 3338276
      -- If one-time payment is enabled, bank account payment is not enabled;
      -- Hence, the check for valid bank account payment methods can be defaulted to 0.
      -- Bug 3886652 - Customer Id and Customer Site Use Id added as params to ARI_CONFIG.save_payment_instrument_info
      IF NOT ari_utilities.save_payment_instrument_info (p_customer_id,
                                                         p_customer_site_id
                                                        )
      THEN
         l_bank_account_method := 0;
      ELSE
         l_bank_account_method :=
            is_bank_acc_payment_enabled (p_customer_id,
                                         p_customer_site_id,
                                         l_currency_code,
                                         p_org_id
                                        );
      END IF;

      IF l_bank_account_method = 0 AND l_credit_card_method = 0
      THEN
         RETURN FALSE;
      END IF;

      RETURN TRUE;
   END allow_payment;

-- cover function on top of allow_payments to allow usage in SQL statements.
   FUNCTION payment_allowed (
      p_payment_schedule_id   IN   NUMBER,
      p_customer_id           IN   NUMBER,
      p_customer_site_id      IN   NUMBER,
      p_org_id                IN   NUMBER Default null
   )
      RETURN NUMBER
   IS
   BEGIN
      IF allow_payment (p_payment_schedule_id,
                        p_customer_id,
                        p_customer_site_id,
                        p_org_id
                       )
      THEN
         RETURN 1;
      ELSE
         RETURN 0;
      END IF;
   END payment_allowed;

/*========================================================================
 | PUBLIC procedure get_default_payment_instrument
 |
 | DESCRIPTION
 |      Return payment instrument information if one can be defaulted for the user
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      customer_id IN Customer Id to which credit cards are releated to
 |      customer_site_use_id IN Customer Site Use Id to which credit cards are releated to
 | currency_code  IN VARCHAR2
 |
 | RETURNS
 |      p_bank_account_num_masked Masked credit card number
 |      p_credit_card_type        Type of the credit card
 |      p_expiry_month            Credit card expiry month
 |      p_expiry_year             Credit card expiry year
 |      p_credit_card_expired     '1' if credit card has expired, '0' otherwise
 |      p_bank_account_id         Bank Account id of the credit card
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 22-JAN-2001           J Rautiainen      Created
 | 20-May-2004     hikumar    Added currencyCode
 | 26-Oct-2004       vnb           Bug 3944029 - Correct payment instrument to be picked at customer account level
 | 23-Dec-2004       vnb           Bug 3928412 - RA_CUSTOMERS obsolete;removed reference to it
 | 09-Nov-2009      avepati     Bug 9098662 - Able to make payments with end dated bank accounts
 | 11-Oct-2010      avepati     Bug 10121591 - 12I CREDIT CARDS AFTER UPGRADE DOES NOT HAVE EXPIRY DATES POPULATED
 | 12-Jan-13        melapaku    Bug 16097315 - IRECEIVABLES SHOWS FUTURE DATED BANK ACCOUNTS
 | 30-Dec-2014	    gnramasa    Bug 20236871 - QUICK PAYMENT PAGE NOT DISPLAYED WHEN PAYMENT METHOD AT ACCOUNT LEVEL ONLY
 *=======================================================================*/
   PROCEDURE get_default_payment_instrument (
      p_customer_id               IN              NUMBER,
      p_customer_site_use_id      IN              NUMBER DEFAULT NULL,
      p_currency_code             IN              VARCHAR2,
      p_bank_account_num_masked   OUT NOCOPY      VARCHAR2,
      p_account_type              OUT NOCOPY      VARCHAR2,
      p_expiry_month              OUT NOCOPY      VARCHAR2,
      p_expiry_year               OUT NOCOPY      VARCHAR2,
      p_credit_card_expired       OUT NOCOPY      VARCHAR2,
      p_bank_account_id           OUT NOCOPY      ce_bank_accounts.bank_account_id%TYPE,
      p_bank_branch_id            OUT NOCOPY      ce_bank_accounts.bank_branch_id%TYPE,
      p_account_holder            OUT NOCOPY      VARCHAR2,
      p_card_brand                OUT NOCOPY      VARCHAR2,
      p_cvv_code                  OUT NOCOPY      VARCHAR2,
      p_conc_address              OUT NOCOPY      VARCHAR2,
      p_cc_bill_site_id           OUT NOCOPY      NUMBER,
      p_instr_assignment_id       OUT NOCOPY      NUMBER,
      p_bank_party_id             OUT NOCOPY      NUMBER,
      p_branch_party_id           OUT NOCOPY      NUMBER,
      p_object_version_no         OUT NOCOPY      NUMBER
   )
   IS
      CURSOR last_used_instr_cur
      IS
         SELECT bank.masked_bank_account_num bank_account_num_masked,
                bank.bank_account_type account_type, NULL expiry_month,
                NULL expiry_year, '0' credit_card_expired,
                u.instrument_id bank_account_id,
                bank.branch_id bank_branch_id,
                bank.bank_account_name account_holder, NULL cvv_code,
                NULL conc_address, NULL card_code, NULL party_site_id,
                u.instrument_payment_use_id instr_assignment_id,
                bank.bank_id bank_party_id, bank.branch_id branch_party_id,
                bank.object_version_number
           FROM hz_cust_accounts cust,
                hz_party_preferences pp1,
                iby_external_payers_all p,
                iby_pmt_instr_uses_all u,
                iby_ext_bank_accounts bank,
                hz_organization_profiles bapr,
                hz_organization_profiles brpr,
                iby_account_owners ow
          WHERE cust.cust_account_id = p_customer_id
            AND pp1.party_id = cust.party_id
            AND pp1.CATEGORY = 'LAST_USED_PAYMENT_INSTRUMENT'
            AND pp1.preference_code = 'INSTRUMENT_ID'
            AND p.cust_account_id = p_customer_id
            AND p.party_id = cust.party_id
             --Start bug 20236871 gnramasa 30th Dec 2014
           /* AND (   (p.acct_site_use_id = p_customer_site_use_id)
                 OR (    p.acct_site_use_id IS NULL
                     AND DECODE (p_customer_site_use_id,
                                 -1, NULL,
                                 p_customer_site_use_id
                                ) IS NULL
                    )
                )*/
            AND (nvl(p.acct_site_use_id, p_customer_site_use_id) = p_customer_site_use_id)
            --End bug 20236871 gnramasa 30th Dec 2014
            AND u.ext_pmt_party_id = p.ext_payer_id
            AND u.instrument_type = 'BANKACCOUNT'
            AND u.payment_flow = 'FUNDS_CAPTURE'
            AND u.instrument_id = pp1.value_number
            AND NVL (TRUNC (bank.start_date), SYSDATE - 1) <= TRUNC (SYSDATE)
            -- Added for Bug# 16097315
            AND NVL (TRUNC (u.start_date), SYSDATE - 1) <= TRUNC (SYSDATE)
            -- 16097315 to not fetch the instrument if start date is in future
            AND NVL (TRUNC (u.end_date), SYSDATE + 10) >= TRUNC (SYSDATE)
            -- 13601435, to avoid picking end dated bank account assignments
            AND pp1.value_number = bank.ext_bank_account_id(+)
            AND (   DECODE (bank.currency_code, NULL, 'Y', 'N') = 'Y'
                 OR bank.currency_code = p_currency_code
                )
            AND bank.bank_id = bapr.party_id(+)
            AND bank.branch_id = brpr.party_id(+)
            AND TRUNC (SYSDATE) BETWEEN NVL (TRUNC (bapr.effective_start_date),
                                             SYSDATE - 1
                                            )
                                    AND NVL (TRUNC (bapr.effective_end_date),
                                             SYSDATE + 1
                                            )
            AND TRUNC (SYSDATE) BETWEEN NVL (TRUNC (brpr.effective_start_date),
                                             SYSDATE - 1
                                            )
                                    AND NVL (TRUNC (brpr.effective_end_date),
                                             SYSDATE + 1
                                            )
            AND bank.ext_bank_account_id = ow.ext_bank_account_id(+)
            AND ow.primary_flag(+) = 'Y'
            AND NVL (TRUNC (bank.end_date), SYSDATE + 10) >= TRUNC (SYSDATE)
         --bug 9098662
         UNION ALL
         SELECT c.card_number bank_account_num_masked,
                c.card_issuer_name account_type,
                DECODE (sysoptions.supplemental_data_option,
                        'Y', 'XX',
                        TO_CHAR (TO_DATE (c.card_expirydate), 'MM')
                       ) expiry_month,
                DECODE (sysoptions.supplemental_data_option,
                        'Y', 'XXXX',
                        TO_CHAR (TO_DATE (c.card_expirydate), 'YYYY')
                       ) expiry_year,
                DECODE (c.card_expired_flag,
                        'Y', '1',
                        '0'
                       ) credit_card_expired,
                c.instrument_id bank_account_id, 1 bank_branch_id,
                NVL (c.card_holder_name, hzcc.party_name) account_holder,
                NULL cvv_code,
                arp_addr_pkg.format_address
                                      (loc.address_style,
                                       loc.address1,
                                       loc.address2,
                                       loc.address3,
                                       loc.address4,
                                       loc.city,
                                       loc.county,
                                       loc.state,
                                       loc.province,
                                       loc.postal_code,
                                       terr.territory_short_name
                                      ) conc_address,
                c.card_issuer_code card_code, psu.party_site_id,
                c.instr_assignment_id, NULL bank_party_id,
                NULL branch_party_id, NULL object_version_number
           FROM hz_cust_accounts cust,
                hz_party_preferences pp1,
                iby_external_payers_all p,
                iby_fndcpt_payer_assgn_instr_v c,
                hz_parties hzcc,
                hz_party_site_uses psu,
                hz_party_sites hps,
                hz_locations loc,
                fnd_territories_vl terr,
                (SELECT encrypt_supplemental_card_data
                                                  AS supplemental_data_option
                   FROM iby_sys_security_options) sysoptions
          WHERE cust.cust_account_id = p_customer_id
            AND cust.party_id = hzcc.party_id
            AND pp1.party_id = hzcc.party_id
            AND pp1.CATEGORY = 'LAST_USED_PAYMENT_INSTRUMENT'
            AND pp1.preference_code = 'INSTRUMENT_ID'
            AND p.cust_account_id = p_customer_id
            AND p.party_id = hzcc.party_id
            --Start bug 20236871 gnramasa 30th Dec 2014
            /*
            AND (   (p.acct_site_use_id = p_customer_site_use_id)
                 OR (    p.acct_site_use_id IS NULL
                     AND DECODE (p_customer_site_use_id,
                                 -1, NULL,
                                 p_customer_site_use_id
                                ) IS NULL
                    )
                )*/
            AND (nvl(p.acct_site_use_id, p_customer_site_use_id) = p_customer_site_use_id)
             --End bug 20236871 gnramasa 30th Dec 2014
            AND c.instrument_type = 'CREDITCARD'
            AND NVL (TRUNC (c.assignment_start_date), SYSDATE - 1) <=
                                                               TRUNC (SYSDATE)
            -- Added for Bug#16097315
            AND NVL (TRUNC (c.assignment_end_date), SYSDATE + 10) >=
                                                               TRUNC (SYSDATE)
            -- bug 11832912
            AND c.instrument_id = pp1.value_number
            AND c.ext_payer_id = p.ext_payer_id
            AND c.card_billing_address_id = psu.party_site_use_id(+)
            AND psu.party_site_id = hps.party_site_id(+)
            AND hps.location_id = loc.location_id(+)
            AND loc.country = terr.territory_code(+);

      CURSOR bank_account_cur
      IS
         SELECT u.instrument_type instrument_type,
                bank.masked_bank_account_num bank_account_num_masked,
                bank.bank_account_type account_type, NULL expiry_month,
                NULL expiry_year, '0' credit_card_expired,
                u.instrument_id bank_account_id,
                bank.branch_id bank_branch_id,
                bank.bank_account_name account_holder, NULL cvv_code,
                NULL conc_address, NULL card_code, NULL party_site_id,
                u.instrument_payment_use_id instr_assignment_id,
                bank.bank_id bank_party_id, bank.branch_id branch_party_id,
                bank.object_version_number
           FROM hz_cust_accounts cust,
                iby_external_payers_all p,
                iby_pmt_instr_uses_all u,
                iby_ext_bank_accounts bank,
                hz_organization_profiles bapr,
                hz_organization_profiles brpr,
                iby_account_owners ow
          WHERE cust.cust_account_id = p_customer_id
            AND p.cust_account_id = cust.cust_account_id
            AND p.party_id = cust.party_id
            --Start bug 20236871 gnramasa 30th Dec 2014
            /* AND (   (p.acct_site_use_id = p_customer_site_use_id)
                 OR (    p.acct_site_use_id IS NULL
                     AND DECODE (p_customer_site_use_id,
                                 -1, NULL,
                                 p_customer_site_use_id
                                ) IS NULL
                    )
                ) */
            AND (nvl(p.acct_site_use_id, p_customer_site_use_id) = p_customer_site_use_id)
             --End bug 20236871 gnramasa 30th Dec 2014
            AND u.ext_pmt_party_id = p.ext_payer_id
            AND u.instrument_type = 'BANKACCOUNT'
            AND u.payment_flow = 'FUNDS_CAPTURE'
            AND u.instrument_id = bank.ext_bank_account_id(+)
            AND NVL (TRUNC (bank.start_date), SYSDATE - 1) <= TRUNC (SYSDATE)
            -- Added for Bug#16097315
            AND NVL (TRUNC (u.start_date), SYSDATE - 1) <= TRUNC (SYSDATE)
            -- Added for Bug#16097315
            AND NVL (TRUNC (u.end_date), SYSDATE + 10) >= TRUNC (SYSDATE)
            -- bug 13601435 to avoid fetching end dated bank account assignments
            AND (   DECODE (bank.currency_code, NULL, 'Y', 'N') = 'Y'
                 OR bank.currency_code = p_currency_code
                )
            AND bank.bank_id = bapr.party_id(+)
            AND bank.branch_id = brpr.party_id(+)
            AND TRUNC (SYSDATE) BETWEEN NVL (TRUNC (bapr.effective_start_date),
                                             SYSDATE - 1
                                            )
                                    AND NVL (TRUNC (bapr.effective_end_date),
                                             SYSDATE + 1
                                            )
            AND TRUNC (SYSDATE) BETWEEN NVL (TRUNC (brpr.effective_start_date),
                                             SYSDATE - 1
                                            )
                                    AND NVL (TRUNC (brpr.effective_end_date),
                                             SYSDATE + 1
                                            )
            AND bank.ext_bank_account_id = ow.ext_bank_account_id(+)
            AND NVL (TRUNC (bank.end_date), SYSDATE + 10) >= TRUNC (SYSDATE)
            -- bug 13601435 to avoid fetching end dated bank account
            AND ow.primary_flag(+) = 'Y'
            AND NVL (TRUNC (ow.end_date), SYSDATE + 10) > TRUNC (SYSDATE);

      CURSOR credit_card_cur
      IS
         SELECT u.instrument_type instrument_type,
                c.masked_cc_number bank_account_num_masked,
                DECODE (i.card_issuer_code,
                        NULL, ccunk.meaning,
                        i.card_issuer_name
                       ) account_type,
                NULL expiry_month, NULL expiry_year, '0' credit_card_expired,
                u.instrument_id bank_account_id, 1 bank_branch_id,
                NVL (c.chname, hzcc.party_name) account_holder, NULL cvv_code,
                arp_addr_pkg.format_address
                                      (loc.address_style,
                                       loc.address1,
                                       loc.address2,
                                       loc.address3,
                                       loc.address4,
                                       loc.city,
                                       loc.county,
                                       loc.state,
                                       loc.province,
                                       loc.postal_code,
                                       terr.territory_short_name
                                      ) conc_address,
                c.card_issuer_code card_code, psu.party_site_id,
                u.instrument_payment_use_id instr_assignment_id,
                NULL bank_party_id, NULL branch_party_id,
                NULL object_version_number
           FROM fnd_lookup_values_vl ccunk,
                iby_creditcard c,
                iby_creditcard_issuers_vl i,
                iby_external_payers_all p,
                iby_pmt_instr_uses_all u,
                hz_parties hzcc,
                hz_cust_accounts cust,
                hz_party_site_uses psu,
                hz_party_sites hps,
                hz_locations loc,
                fnd_territories_vl terr
          WHERE cust.cust_account_id = p_customer_id
            AND p.cust_account_id = cust.cust_account_id
            AND p.party_id = cust.party_id
            --Start bug 20236871 gnramasa 30th Dec 2014
           /*
             AND (   (p.acct_site_use_id = p_customer_site_use_id)
                 OR (    p.acct_site_use_id IS NULL
                     AND DECODE (p_customer_site_use_id,
                                 -1, NULL,
                                 p_customer_site_use_id
                                ) IS NULL
                    )
                )
                */
            AND (nvl(p.acct_site_use_id, p_customer_site_use_id) = p_customer_site_use_id)
            --End bug 20236871 gnramasa 30th Dec 2014
            AND u.ext_pmt_party_id = p.ext_payer_id
            AND u.instrument_type = 'CREDITCARD'
            AND u.payment_flow = 'FUNDS_CAPTURE'
            AND NVL (TRUNC (u.start_date), SYSDATE - 1) <= TRUNC (SYSDATE)
            -- Added for Bug#16097315
            AND NVL (TRUNC (u.end_date), SYSDATE + 10) >= TRUNC (SYSDATE)
            -- bug 11832912
            AND u.instrument_id = c.instrid(+)
            AND NVL (c.inactive_date, SYSDATE + 10) > SYSDATE
            AND c.card_issuer_code = i.card_issuer_code(+)
            AND c.card_owner_id = hzcc.party_id(+)
            AND c.addressid = psu.party_site_use_id(+)
            AND psu.party_site_id = hps.party_site_id(+)
            AND hps.location_id = loc.location_id(+)
            AND loc.country = terr.territory_code(+)
            AND ccunk.lookup_type = 'IBY_CARD_TYPES'
            AND ccunk.lookup_code = 'UNKNOWN';

      bank_account_rec       bank_account_cur%ROWTYPE;
      credit_card_rec        credit_card_cur%ROWTYPE;
      last_used_instr_rec    last_used_instr_cur%ROWTYPE;
      l_ba_count             NUMBER                                   := 0;
      l_cc_count             NUMBER                                   := 0;
      l_result               ce_bank_accounts.bank_account_num%TYPE;
      l_payment_instrument   VARCHAR2 (100);
      x_return_status        VARCHAR2 (100);
      x_cvv_use              VARCHAR2 (100);
      x_billing_addr_use     VARCHAR2 (100);
      x_msg_count            NUMBER;
      x_msg_data             VARCHAR2 (100);
   BEGIN
         WRITE_DEBUG_AND_LOG('Begin get_default_payment_instrument');
         WRITE_DEBUG_AND_LOG('p_customer_id: ' || p_customer_id);
         WRITE_DEBUG_AND_LOG('p_customer_site_use_id : ' || p_customer_site_use_id);
         WRITE_DEBUG_AND_LOG('p_currency_code : ' || p_currency_code);
      get_payment_channel_attribs (p_channel_code          => 'CREDIT_CARD',
                                   x_return_status         => x_return_status,
                                   x_cvv_use               => x_cvv_use,
                                   x_billing_addr_use      => x_billing_addr_use,
                                   x_msg_count             => x_msg_count,
                                   x_msg_data              => x_msg_data
                                  );
         WRITE_DEBUG_AND_LOG('x_return_status : ' || x_return_status);
         WRITE_DEBUG_AND_LOG('x_cvv_use : ' || x_cvv_use);
         WRITE_DEBUG_AND_LOG('x_billing_addr_use : ' || x_billing_addr_use);

/*
If there are multiple BA and only 1 CC, we return the CC details
If there is 1 BA and multiple CC, we return the BA details
If there is 1 BA, 1CC we return the BA details

Return NULL values in the following cases:
1)If there are more than one BA and more than one CC
2)If no saved instrument exists
3)If there's only one saved instrument and it doesn't have address
*/
      OPEN last_used_instr_cur;

      FETCH last_used_instr_cur
       INTO last_used_instr_rec;

      IF last_used_instr_cur%FOUND
      THEN
         --If there's a last used instrument, return the address and other details.
         --But, if that instrument doesn't have a BilltositeID associated(i.e., no bill to address), we return empty values
         WRITE_DEBUG_AND_LOG('Cursor last_used_instr_cur returned value');
         CLOSE last_used_instr_cur;

-- bank_branch_id will be always 1  for CC , --  bug 7712779
         WRITE_DEBUG_AND_LOG('last_used_instr_rec.bank_branch_id: ' || last_used_instr_rec.bank_branch_id);
         IF (last_used_instr_rec.bank_branch_id = 1)
         THEN
            IF (xx_ar_irec_payments.is_credit_card_payment_enabled
                                                      (p_customer_id,
                                                       p_customer_site_use_id,
                                                       p_currency_code
                                                      ) = 1
               )
            THEN
              WRITE_DEBUG_AND_LOG('XX_AR_IREC_PAYMENTS.IS_CREDIT_CARD_PAYMENT_ENABLED returned value as 1');
               p_bank_account_num_masked :=
                                  last_used_instr_rec.bank_account_num_masked;
               p_credit_card_expired :=
                                      last_used_instr_rec.credit_card_expired;
               p_account_type := last_used_instr_rec.account_type;
               p_expiry_month := last_used_instr_rec.expiry_month;
               p_expiry_year := last_used_instr_rec.expiry_year;
               p_bank_account_id := last_used_instr_rec.bank_account_id;
               p_bank_branch_id := last_used_instr_rec.bank_branch_id;
               p_account_holder := last_used_instr_rec.account_holder;
               p_cvv_code := last_used_instr_rec.cvv_code;
               p_card_brand := last_used_instr_rec.card_code;
               p_conc_address := last_used_instr_rec.conc_address;
               p_cc_bill_site_id := last_used_instr_rec.party_site_id;
               p_instr_assignment_id :=
                                      last_used_instr_rec.instr_assignment_id;
               p_bank_party_id := last_used_instr_rec.bank_party_id;
               p_branch_party_id := last_used_instr_rec.branch_party_id;
               p_object_version_no :=
                                    last_used_instr_rec.object_version_number;
            END IF;
         ELSE
            -- bug 7712779
            WRITE_DEBUG_AND_LOG('XX_AR_IREC_PAYMENTS.IS_CREDIT_CARD_PAYMENT_ENABLED did not return value as 1, in else condition');
            IF (xx_ar_irec_payments.is_bank_acc_payment_enabled
                                                      (p_customer_id,
                                                       p_customer_site_use_id,
                                                       p_currency_code
                                                      ) = 1
               )
            THEN
              WRITE_DEBUG_AND_LOG('XX_AR_IREC_PAYMENTS.IS_BANK_ACC_PAYMENT_ENABLED returned value as 1');
               p_bank_account_num_masked :=
                                  last_used_instr_rec.bank_account_num_masked;
               p_credit_card_expired :=
                                      last_used_instr_rec.credit_card_expired;
               p_account_type := last_used_instr_rec.account_type;
               p_expiry_month := last_used_instr_rec.expiry_month;
               p_expiry_year := last_used_instr_rec.expiry_year;
               p_bank_account_id := last_used_instr_rec.bank_account_id;
               p_bank_branch_id := last_used_instr_rec.bank_branch_id;
               p_account_holder := last_used_instr_rec.account_holder;
               p_cvv_code := last_used_instr_rec.cvv_code;
               p_card_brand := last_used_instr_rec.card_code;
               p_conc_address := last_used_instr_rec.conc_address;
               p_cc_bill_site_id := last_used_instr_rec.party_site_id;
               p_instr_assignment_id :=
                                      last_used_instr_rec.instr_assignment_id;
               p_bank_party_id := last_used_instr_rec.bank_party_id;
               p_branch_party_id := last_used_instr_rec.branch_party_id;
               p_object_version_no :=
                                    last_used_instr_rec.object_version_number;
            END IF;
         END IF;

           /* Bug 4744886 - When last used payment instrument is created without Address
              and if profile value now requires Address, then this procedure will return
              no default instrument found, so that it would be taken to Adv Pmt Page

         p_bank_branch_id is 1 only for Credit Cards
            */
                WRITE_DEBUG_AND_LOG('p_bank_branch_id: ' || p_bank_branch_id);
                WRITE_DEBUG_AND_LOG('p_cc_bill_site_id: ' || p_cc_bill_site_id);
                WRITE_DEBUG_AND_LOG('x_billing_addr_use: ' || x_billing_addr_use);
         IF (    p_bank_branch_id = 1
             AND p_cc_bill_site_id IS NULL
             AND (x_billing_addr_use = 'REQUIRED')
            )
         THEN
           WRITE_DEBUG_AND_LOG('inside if condition...');
            p_bank_account_num_masked := '';
            p_account_type := '';
            p_expiry_month := '';
            p_expiry_year := '';
            p_bank_account_id := TO_NUMBER (NULL);
            p_bank_branch_id := TO_NUMBER (NULL);
            p_credit_card_expired := '';
            p_account_holder := '';
            p_card_brand := '';
            p_cvv_code := '';
            p_conc_address := '';
            p_cc_bill_site_id := TO_NUMBER (NULL);
            p_instr_assignment_id := TO_NUMBER (NULL);
            p_bank_party_id := TO_NUMBER (NULL);
            p_branch_party_id := TO_NUMBER (NULL);
            p_object_version_no := TO_NUMBER (NULL);
         END IF;
      ELSE
           WRITE_DEBUG_AND_LOG('in else condition, there is no last used instrument...');
         --If there's NO last used instrument
         CLOSE last_used_instr_cur;

         FOR bank_account_rec IN bank_account_cur
         LOOP
            --  bug 7712779
            WRITE_DEBUG_AND_LOG('cursor bank_account_rec returned value');

            IF (ar_irec_payments.is_bank_acc_payment_enabled
                                                      (p_customer_id,
                                                       p_customer_site_use_id,
                                                       p_currency_code
                                                      ) = 0
               )
            THEN
               WRITE_DEBUG_AND_LOG('ar_irec_payments.is_bank_acc_payment_enabled returned value as 0');
               EXIT;
            END IF;

            --If there are any BA, in the first iteration read those values.
            --From 2nd iteration, maintain a count of the BA and CC existing

            WRITE_DEBUG_AND_LOG('l_ba_count: ' || l_ba_count);
            IF (l_ba_count = 0)
            THEN
               l_payment_instrument := 'BANKACCOUNT';
               p_bank_account_num_masked :=
                                     bank_account_rec.bank_account_num_masked;
               p_credit_card_expired := bank_account_rec.credit_card_expired;
               p_account_type := bank_account_rec.account_type;
               p_expiry_month := bank_account_rec.expiry_month;
               p_expiry_year := bank_account_rec.expiry_year;
               p_bank_account_id := bank_account_rec.bank_account_id;
               p_bank_branch_id := bank_account_rec.bank_branch_id;
               p_account_holder := bank_account_rec.account_holder;
               p_card_brand := '';
               p_cvv_code := '';
               p_conc_address := '';
               p_cc_bill_site_id := '';
               p_instr_assignment_id := bank_account_rec.instr_assignment_id;
               p_bank_party_id := bank_account_rec.bank_party_id;
               p_branch_party_id := bank_account_rec.branch_party_id;
               p_object_version_no := bank_account_rec.object_version_number;
            END IF;

            l_ba_count := l_ba_count + 1;

            IF (l_ba_count > 1)
            THEN
               WRITE_DEBUG_AND_LOG('l_ba_count is > 1');
               EXIT;
            END IF;
         END LOOP;

         FOR credit_card_rec IN credit_card_cur
         LOOP
            --  bug 7712779
            WRITE_DEBUG_AND_LOG('cursor credit_card_cur returned value');

            IF (xx_ar_irec_payments.is_credit_card_payment_enabled
                                                      (p_customer_id,
                                                       p_customer_site_use_id,
                                                       p_currency_code
                                                      ) = 0
               )
            THEN
                WRITE_DEBUG_AND_LOG('xx_ar_irec_payments.is_credit_card_payment_enabled returned value as 0');
               EXIT;
            END IF;

              WRITE_DEBUG_AND_LOG('l_ba_count: ' || l_ba_count);
	            WRITE_DEBUG_AND_LOG('l_cc_count: ' || l_cc_count);

            IF (l_ba_count <> 1 AND l_cc_count = 0)
            THEN
               WRITE_DEBUG_AND_LOG('inside IF(l_ba_count <>1 AND l_cc_count = 0)');
               l_payment_instrument := 'CREDITCARD';
               p_bank_account_num_masked :=
                                     credit_card_rec.bank_account_num_masked;
               p_credit_card_expired := credit_card_rec.credit_card_expired;
               p_account_type := credit_card_rec.account_type;
               p_expiry_month := credit_card_rec.expiry_month;
               p_expiry_year := credit_card_rec.expiry_year;
               p_bank_account_id := credit_card_rec.bank_account_id;
               p_bank_branch_id := credit_card_rec.bank_branch_id;
               p_account_holder := credit_card_rec.account_holder;
               p_card_brand := credit_card_rec.card_code;
               p_cvv_code := credit_card_rec.cvv_code;
               p_conc_address := credit_card_rec.conc_address;
               p_cc_bill_site_id := credit_card_rec.party_site_id;
               p_instr_assignment_id := credit_card_rec.instr_assignment_id;
               p_bank_party_id := '';
               p_branch_party_id := '';
               p_object_version_no := '';
            END IF;

            l_cc_count := l_cc_count + 1;
            WRITE_DEBUG_AND_LOG('l_cc_count: ' || l_cc_count);

            IF (l_cc_count > 1)
            THEN
               EXIT;
            END IF;
         END LOOP;
         WRITE_DEBUG_AND_LOG('end of loop credit_card_rec');

         IF (   (l_payment_instrument = 'BANKACCOUNT' AND l_ba_count > 1)
             OR (l_payment_instrument = 'CREDITCARD' AND l_cc_count > 1)
             OR (l_payment_instrument IS NULL)
             OR (    p_bank_branch_id = 1
                 AND p_cc_bill_site_id IS NULL
                 AND x_billing_addr_use = 'REQUIRED'
                )
            )
         THEN
            WRITE_DEBUG_AND_LOG('set null as value for all return arguments');
            p_bank_account_num_masked := '';
            p_account_type := '';
            p_expiry_month := '';
            p_expiry_year := '';
            p_bank_account_id := TO_NUMBER (NULL);
            p_bank_branch_id := TO_NUMBER (NULL);
            p_credit_card_expired := '';
            p_account_holder := '';
            p_card_brand := '';
            p_cvv_code := '';
            p_conc_address := '';
            p_cc_bill_site_id := TO_NUMBER (NULL);
            p_instr_assignment_id := TO_NUMBER (NULL);
            p_bank_party_id := '';
            p_branch_party_id := '';
            p_object_version_no := '';
         END IF;
      END IF;
         WRITE_DEBUG_AND_LOG('End get_default_payment_instrument');
   --End for bug 20236871 gnramasa 30th Dec 2014
   END get_default_payment_instrument;

/*========================================================================
 | PUBLIC function is_credit_card_expired
 |
 | DESCRIPTION
 |      Determines if a given credit card expiration date has passed.
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |      This function compares given month and year in the given parameter
 |      to the month and year of the current date.
 |
 | PARAMETERS
 |      p_expiration_date   IN   Credit card expiration date
 |
 | RETURNS
 |      1     if credit card has expired
 |      0     if credit card has not expired
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 21-Feb-2001           Jani Rautiainen   Created
 |
 *=======================================================================*/
   FUNCTION is_credit_card_expired (p_expiration_date IN DATE)
      RETURN NUMBER
   IS
      CURSOR current_date_cur
      IS
         SELECT TO_CHAR (TO_NUMBER (TO_CHAR (SYSDATE, 'MM'))) current_month,
                TO_CHAR (SYSDATE, 'YYYY') current_year
           FROM DUAL;

      current_date_rec   current_date_cur%ROWTYPE;
   BEGIN
      OPEN current_date_cur;

      FETCH current_date_cur
       INTO current_date_rec;

      CLOSE current_date_cur;

      IF    TO_NUMBER (TO_CHAR (p_expiration_date, 'YYYY')) <
                                    TO_NUMBER (current_date_rec.current_year)
         OR (    TO_NUMBER (TO_CHAR (p_expiration_date, 'YYYY')) =
                                     TO_NUMBER (current_date_rec.current_year)
             AND TO_NUMBER (TO_CHAR (p_expiration_date, 'MM')) <
                                    TO_NUMBER (current_date_rec.current_month)
            )
      THEN
         RETURN 1;                                                    --TRUE;
      ELSE
         RETURN 0;                                                    --FALSE
      END IF;
   END is_credit_card_expired;

/*========================================================================
 | PUBLIC procedure store_last_used_ba
 |
 | DESCRIPTION
 |      Stores the last used bank account
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_customer_id      IN  NUMBER
 |      p_bank_account_id  IN  NUMBER
 | p_instr_type      IN  VARCHAR2 DEFAULT 'BA'
 |
 | RETURNS
 |      p_status     OUT NOCOPY varchar2
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 09-May-2001           J Rautiainen      Created
 | 26-Oct-2005     rsinthre          Bug 4673563 - Error in updating last used instrument
 *=======================================================================*/
   PROCEDURE store_last_used_ba (
      p_customer_id       IN              NUMBER,
      p_bank_account_id   IN              NUMBER,
      p_instr_type        IN              VARCHAR2 DEFAULT 'BA',
      p_status            OUT NOCOPY      VARCHAR2
   )
   IS
      l_msg_count               NUMBER;
      l_object_version_number   NUMBER;
      l_msg_data                VARCHAR (2000);

      CURSOR customer_party_cur
      IS
         SELECT party_id
           FROM hz_cust_accounts
          WHERE cust_account_id = p_customer_id;

      CURSOR object_version_cur (
         p_party_id          IN   NUMBER,
         p_preference_code   IN   VARCHAR2
      )
      IS
         SELECT party_preference_id, object_version_number
           FROM hz_party_preferences
          WHERE party_id = p_party_id
            AND CATEGORY = 'LAST_USED_PAYMENT_INSTRUMENT'
            AND preference_code = p_preference_code;

      customer_party_rec        customer_party_cur%ROWTYPE;
      object_version_rec        object_version_cur%ROWTYPE;
   BEGIN
      OPEN customer_party_cur;

      FETCH customer_party_cur
       INTO customer_party_rec;

      CLOSE customer_party_cur;

      OPEN object_version_cur (customer_party_rec.party_id,
                               'INSTRUMENT_TYPE');

      FETCH object_version_cur
       INTO object_version_rec;

      CLOSE object_version_cur;

      SAVEPOINT store_inst;
      hz_preference_pub.put
         (p_party_id                   => customer_party_rec.party_id,
          p_category                   => 'LAST_USED_PAYMENT_INSTRUMENT',
          p_preference_code            => 'INSTRUMENT_TYPE',
          p_value_varchar2             => p_instr_type,
          p_module                     => 'IRECEIVABLES',
          p_additional_value1          => NULL,
          p_additional_value2          => NULL,
          p_additional_value3          => NULL,
          p_additional_value4          => NULL,
          p_additional_value5          => NULL,
          p_object_version_number      => object_version_rec.object_version_number,
          x_return_status              => p_status,
          x_msg_count                  => l_msg_count,
          x_msg_data                   => l_msg_data
         );

      IF (p_status <> fnd_api.g_ret_sts_success)
      THEN
         write_error_messages (l_msg_data, l_msg_count);
         ROLLBACK TO store_inst;
         RETURN;
      END IF;

      OPEN object_version_cur (customer_party_rec.party_id, 'INSTRUMENT_ID');

      FETCH object_version_cur
       INTO object_version_rec;

      CLOSE object_version_cur;

      hz_preference_pub.put
         (p_party_id                   => customer_party_rec.party_id,
          p_category                   => 'LAST_USED_PAYMENT_INSTRUMENT',
          p_preference_code            => 'INSTRUMENT_ID',
          p_value_number               => p_bank_account_id,
          p_module                     => 'IRECEIVABLES',
          p_additional_value1          => NULL,
          p_additional_value2          => NULL,
          p_additional_value3          => NULL,
          p_additional_value4          => NULL,
          p_additional_value5          => NULL,
          p_object_version_number      => object_version_rec.object_version_number,
          x_return_status              => p_status,
          x_msg_count                  => l_msg_count,
          x_msg_data                   => l_msg_data
         );

      IF (p_status <> fnd_api.g_ret_sts_success)
      THEN
         write_error_messages (l_msg_data, l_msg_count);
         ROLLBACK TO store_inst;
         RETURN;
      END IF;

      --If payment process goes through, the transaction will be committed irrespective of
      --the result of this procedure. If the record is stored successfully in hz party preference, commit
      COMMIT;
   END store_last_used_ba;

/*========================================================================
 | PUBLIC function is_bank_account_duplicate
 |
 | DESCRIPTION
 |      Checks whether given bank account number already exists
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_bank_account_number IN  VARCHAR2
 |      p_routing_number      IN  VARCHAR2
 |      p_account_holder_name IN  VARCHAR2
 |
 | RETURNS
 |      Return Value: 0 if given bank account number does not exist.
 |                    1 if given bank account number already exists.
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 01-Aug-2001           J Rautiainen      Created
 |
 | 15-Apr-2002           AMMISHRA          Bug:2210677 , Passed an extra
 |                                         parameter p_account_holder_name
 *=======================================================================*/
   FUNCTION is_bank_account_duplicate (
      p_bank_account_number   IN   VARCHAR2,
      p_routing_number        IN   VARCHAR2 DEFAULT NULL,
      p_account_holder_name   IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      CURSOR cc_cur (p_instrument_id iby_creditcard.instrid%TYPE)
      IS
         SELECT COUNT (1) ca_exists
           FROM iby_fndcpt_payer_assgn_instr_v iby
          WHERE iby.instrument_id = p_instrument_id
            AND iby.card_holder_name <> p_account_holder_name;

      CURSOR ba_cur
      IS
         SELECT COUNT (1) ba_exists
           FROM iby_ext_bank_accounts_v ba
          WHERE ba.branch_number = p_routing_number
            AND ba.bank_account_number = p_bank_account_number
            AND ROWNUM = 1
            AND ba.bank_account_name <> p_account_holder_name;

      ba_rec                 ba_cur%ROWTYPE;
      cc_rec                 cc_cur%ROWTYPE;
      l_create_credit_card   iby_fndcpt_setup_pub.creditcard_rec_type;
      l_result_rec           iby_fndcpt_common_pub.result_rec_type;
      l_procedure_name       VARCHAR2 (30);
      l_return_status        VARCHAR2 (2);
      l_msg_count            NUMBER;
      l_msg_data             VARCHAR2 (2000);
   BEGIN
      l_procedure_name := '.is_bank_account_duplicate';

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         ' Begin +'
                        );
      END IF;

      IF p_routing_number IS NULL
      THEN
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            ' Calling..  IBY_FNDCPT_SETUP_PUB.Card_Exists '
                           );
         END IF;

         iby_fndcpt_setup_pub.card_exists
                                   (p_api_version          => 1.0,
                                    p_init_msg_list        => fnd_api.g_false,
                                    x_return_status        => l_return_status,
                                    x_msg_count            => l_msg_count,
                                    x_msg_data             => l_msg_data,
                                    p_owner_id             => NULL,
                                    p_card_number          => p_bank_account_number,
                                    x_card_instrument      => l_create_credit_card,
                                    x_response             => l_result_rec
                                   );

         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'l_return_status :: ' || l_return_status
                           );
            fnd_log.STRING
               (fnd_log.level_statement,
                g_pkg_name || l_procedure_name,
                'Return 0 - credit card exists validation is not required from OIR'
               );
         END IF;

         --Bug 14534172 - As per bug, do not validate the credit card exists from OIR.
         RETURN 0;
       /*
        IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
            -- no card exists
            return 0;
        ELSE
             OPEN  cc_cur(l_create_credit_card.card_id);
             FETCH cc_cur into cc_rec;
             CLOSE cc_cur;

       if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
      fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'l_create_credit_card.card_id :: ' || l_create_credit_card.card_id);
      fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'cc_rec.ca_exists :: ' || cc_rec.ca_exists);
       end if;

             if cc_rec.ca_exists = 0 then
                return 0;
             else
                return 1;
             end if;

        END IF;
        */
      ELSE
         OPEN ba_cur;

         FETCH ba_cur
          INTO ba_rec;

         CLOSE ba_cur;

         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'ba_rec.ba_exists :: ' || ba_rec.ba_exists
                           );
         END IF;

         IF ba_rec.ba_exists = 0
         THEN
            RETURN 0;
         ELSE
            RETURN 1;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         --Modified for Defect#34441
         write_debug_and_log ('- Account Number: ' || mask_account_number(p_bank_account_number));
         write_debug_and_log ('- Holder Name: ' || p_account_holder_name);
         write_debug_and_log ('ERROR =>' || SQLERRM);
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_msg_pub.ADD;
   END is_bank_account_duplicate;

/*========================================================================
 | PUBLIC function is_bank_account_duplicate
 |
 | DESCRIPTION
 |      Checks whether given bank account number already exists
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_bank_account_number IN  VARCHAR2
 |
 | RETURNS
 |      Return Value: 0 if given bank account number does not exist.
 |                    1 if given bank account number already exists.
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 01-Aug-2001           J Rautiainen      Created
 |
 *=======================================================================*/
   FUNCTION is_credit_card_duplicate (
      p_bank_account_number   IN   VARCHAR2,
      p_account_holder_name   IN   VARCHAR2
   )
      RETURN NUMBER
   IS
   BEGIN
      RETURN is_bank_account_duplicate
                             (p_bank_account_number      => p_bank_account_number,
                              p_routing_number           => NULL,
                              p_account_holder_name      => p_account_holder_name
                             );
   END is_credit_card_duplicate;

/*========================================================================
 | PUBLIC function get_iby_account_type
 |
 | DESCRIPTION
 |      Maps AP bank account type to a iPayment bank account type. If
 |      AP bank account type is not recognized, CHECKING is used.
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_account_type      Account type from the ap table
 |
 | RETURNS
 |      iPayment bank account type
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 28-Feb-2002           J Rautiainen      Created
 |
 *=======================================================================*/
   FUNCTION get_iby_account_type (p_account_type IN VARCHAR2)
      RETURN VARCHAR2
   IS
      CURSOR account_type_cur
      IS
         SELECT lookup_code
           FROM fnd_lookups
          WHERE lookup_type = 'IBY_BANKACCT_TYPES'
            AND lookup_code = UPPER (p_account_type);

      account_type_rec   account_type_cur%ROWTYPE;
   BEGIN
      OPEN account_type_cur;

      FETCH account_type_cur
       INTO account_type_rec;

      IF account_type_cur%FOUND
      THEN
         CLOSE account_type_cur;

         RETURN account_type_rec.lookup_code;
      ELSE
         CLOSE account_type_cur;

         RETURN 'CHECKING';
      END IF;
   END get_iby_account_type;

/*===========================================================================+
 | PROCEDURE write_debug_and_log                                             |
 |                                                                            |
 | DESCRIPTION                                                               |
 |    Writes standard messages to standard debugging and to the log          |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:  p_message - Message to be writted                       |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     28-Feb-2002  Jani Rautiainen      Created                             |
 |                                                                           |
 +===========================================================================*/
   PROCEDURE write_debug_and_log (p_message IN VARCHAR2)
   IS
   BEGIN
      /*------------------------------------------------+
       | Write the message to log and to the standard   |
       | debugging channel                              |
       +------------------------------------------------*/
      IF fnd_global.conc_request_id IS NOT NULL
      THEN
         /*------------------------------------------------+
          | Only write to the log if call was made from    |
          | concurrent program.                            |
          +------------------------------------------------*/
         fnd_file.put_line (fnd_file.LOG, p_message);
      END IF;

      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG ('OIR' || p_message);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         /*-------------------------------------------------------+
          | Error writing to the log, nothing we can do about it. |
          | Error is not raised since API messages also contain   |
          | non fatal warnings. If a real exception happened it   |
          | is handled on the calling routine.                    |
          +-------------------------------------------------------*/
         NULL;
   END write_debug_and_log;

/*===========================================================================+
 | PROCEDURE write_API_output                                                |
 |                                                                            |
 | DESCRIPTION                                                               |
 |    Writes API output to the concurrent program log. Messages from the     |
 |    API can contain warnings and errors                                    |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:  p_msg_count  - Number of messages from the API          |
 |                   p_msg_data   - Actual messages from the API             |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     28-Feb-2002  Jani Rautiainen      Created                             |
 |                                                                           |
 +===========================================================================*/
   PROCEDURE write_api_output (p_msg_count IN NUMBER, p_msg_data IN VARCHAR2)
   IS
      l_msg_data   VARCHAR2 (2000);
   BEGIN
      --Bug 3810143 - Ensure that the messages are picked up from the message
      --stack in any case.
      FOR l_count IN 1 .. p_msg_count
      LOOP
         l_msg_data := fnd_msg_pub.get (fnd_msg_pub.g_next, fnd_api.g_false);
         write_debug_and_log (TO_CHAR (l_count) || ' : ' || l_msg_data);
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         /*-------------------------------------------------------+
          | Error writing to the log, nothing we can do about it. |
          | Error is not raised since API messages also contain   |
          | non fatal warnings. If a real exception happened it   |
          | is handled on the calling routine.                    |
          +-------------------------------------------------------*/
         NULL;
   END write_api_output;

/*========================================================================
 | PUBLIC store_last_used_cc
 |
 | DESCRIPTION
 |      Backward compatibility methods introduced for mobile account
 |      management.
 |      ----------------------------------------
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 10-Mar-2002           J Rautiainen      Created
 | 26-Apr-2004           vnb               Added Customer Site as input parameter.
 |
 *=======================================================================*/
   PROCEDURE store_last_used_cc (
      p_customer_id       IN              NUMBER,
      p_bank_account_id   IN              NUMBER,
      p_status            OUT NOCOPY      VARCHAR2
   )
   IS
   BEGIN
      store_last_used_ba (p_customer_id          => p_customer_id,
                          p_bank_account_id      => p_bank_account_id,
                          p_instr_type           => 'CC',
                          p_status               => p_status
                         );
   END store_last_used_cc;

/*============================================================
 | PUBLIC procedure create_invoice_pay_list
 |
 | DESCRIPTION
 |   Creates a list of transactions to be paid by the customer
 |   based on the list type. List type has the following values:
 |   OPEN_INVOICES
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |   p_customer_id           IN    NUMBER
 |   p_currency_code         IN    VARCHAR2
 |   p_customer_site_use_id  IN    NUMBER DEFAULT NULL
 |   p_payment_schedule_id   IN    NUMBER DEFAULT NULL
 |   p_trx_type              IN    VARCHAR2 DEFAULT NULL
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date          Author       Description of Changes
 | 13-Jan-2003   krmenon      Created
 | 31-Dec-2004   vnb          Bug 4071551 - Removed redundant code
 | 20-Jan-2005   vnb          Bug 4117211 - Original discount amount column added for ease of resetting payment amounts
 | 08-Jul-2005  rsinthre     Bug 4437225 - Disputed amount against invoice not displayed during payment
 | 05-Mar-2010   avepati    Bug#9173720 -Able to see same invoice twice in payment details page.
 | 22-Mar-2010   nkanchan     Bug 8293098 - Service change based on credit card types
 | 09-Jun-2010   nkanchan Bug # 9696274- PAGE ERRORS OUT ON NAVIGATING 'PAY BELOW' RELATED CUSTOMER DATA
 +============================================================*/
   PROCEDURE create_invoice_pay_list (
      p_customer_id            IN   NUMBER,
      p_customer_site_use_id   IN   NUMBER DEFAULT NULL,
      p_payment_schedule_id    IN   NUMBER DEFAULT NULL,
      p_currency_code          IN   VARCHAR2,
      p_payment_type           IN   VARCHAR2 DEFAULT NULL,
      p_lookup_code            IN   VARCHAR2 DEFAULT NULL
   )
   IS
      -- Cursor to fetch all the open invoices
      CURSOR open_invoice_list (
         p_customer_id            NUMBER,
         p_customer_site_use_id   NUMBER,
         p_payment_schedule_id    NUMBER,
         p_currency_code          VARCHAR2
      )
      IS
         SELECT ps.customer_id, ps.customer_site_use_id,     -- Bug # 3828358
                                                        acct.account_number,
                ps.customer_trx_id, ps.trx_number, ps.trx_date, ps.CLASS,
                ps.due_date, ps.payment_schedule_id, ps.status,
                trm.NAME term_desc,
                arpt_sql_func_util.get_number_of_due_dates
                                           (ps.term_id)
                                                      number_of_installments,
                ps.terms_sequence_number,
                ps.amount_line_items_original line_amount,
                ps.tax_original tax_amount,
                ps.freight_original freight_amount,
                ps.receivables_charges_charged finance_charge,
                ps.invoice_currency_code, ps.amount_due_original,
                ps.amount_due_remaining, 0 payment_amt, 0 service_charge,
                0 discount_amount,
                CASE
                   WHEN ((TRUNC (ps.trx_date) - TRUNC (SYSDATE)) <= 0
                        )
                      THEN TRUNC (SYSDATE)
                   ELSE ps.trx_date
                END AS receipt_date,
                '' receipt_number, ct.purchase_order AS po_number,
                NULL AS so_number, ct.printing_option, ct.attribute_category,
                ct.attribute1, ct.attribute2, ct.attribute3, ct.attribute4,
                ct.attribute5, ct.attribute6, ct.attribute7, ct.attribute8,
                ct.attribute9, ct.attribute10, ct.attribute11,
                ct.attribute12, ct.attribute13, ct.attribute14,
                ct.attribute15, ct.interface_header_context,
                ct.interface_header_attribute1,
                ct.interface_header_attribute2,
                ct.interface_header_attribute3,
                ct.interface_header_attribute4,
                ct.interface_header_attribute5,
                ct.interface_header_attribute6,
                ct.interface_header_attribute7,
                ct.interface_header_attribute8,
                ct.interface_header_attribute9,
                ct.interface_header_attribute10,
                ct.interface_header_attribute11,
                ct.interface_header_attribute12,
                ct.interface_header_attribute13,
                ct.interface_header_attribute14,
                ct.interface_header_attribute15, SYSDATE last_update_date,
                0 last_updated_by, SYSDATE creation_date, 0 created_by,
                0 last_update_login, 0 application_amount, 0 cash_receipt_id,
                0 original_discount_amt, ps.org_id, ct.paying_customer_id,
                ct.paying_site_use_id,
                (  DECODE (NVL (ps.amount_due_original, 0),
                           0, 1,
                           (  ps.amount_due_original
                            / ABS (ps.amount_due_original)
                           )
                          )
                 * ABS (NVL (ps.amount_in_dispute, 0))
                ) dispute_amt
           FROM ar_payment_schedules ps,
                ra_customer_trx ct,
                hz_cust_accounts acct,
                ra_terms trm
          WHERE ps.CLASS IN ('INV', 'DM', 'CB', 'DEP')
            AND ps.customer_trx_id = ct.customer_trx_id
            AND acct.cust_account_id = ps.customer_id
            AND ps.status = 'OP'
            AND ps.term_id = trm.term_id(+)
            AND (   ps.payment_schedule_id = p_payment_schedule_id
                 OR p_payment_schedule_id IS NULL
                )
            AND ps.customer_id = p_customer_id
            AND ps.customer_site_use_id =
                   NVL (DECODE (p_customer_site_use_id,
                                -1, NULL,
                                p_customer_site_use_id
                               ),
                        ps.customer_site_use_id
                       )
            AND ps.invoice_currency_code = p_currency_code;

      l_query_period            NUMBER (15);
      l_query_date              DATE;
      l_total_service_charge    NUMBER;
      l_discount_amount         NUMBER;
      l_rem_amt_rcpt            NUMBER;
      l_rem_amt_inv             NUMBER;
      l_grace_days_flag         VARCHAR2 (2);
      l_paying_cust_id          NUMBER (15);
      l_pay_for_cust_id         NUMBER (15);
      l_pay_for_cust_site_id    NUMBER (15);
      l_paying_cust_site_id     NUMBER (15);
      l_dispute_amount          NUMBER                  := 0;
      l_trx_rec_exists          NUMBER                  := 0;
      l_procedure_name          VARCHAR2 (50);
      l_debug_info              VARCHAR2 (200);

      TYPE t_open_invoice_list_rec IS TABLE OF open_invoice_list%ROWTYPE
         INDEX BY BINARY_INTEGER;

      l_open_invoice_list_rec   t_open_invoice_list_rec;
   BEGIN
      --Assign default values
      l_query_period := -12;
      l_total_service_charge := 0;
      l_discount_amount := 0;
      l_rem_amt_rcpt := 0;
      l_rem_amt_inv := 0;
      l_procedure_name := '.create_invoice_pay_list';
      SAVEPOINT create_invoice_pay_list_sp;
----------------------------------------------------------------------------------------
      l_debug_info :=
         'Clear the transaction list for the active customer, site, currency';

-----------------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

  --Bug # 3467287 - The Global Temp table must be striped by Customer and Customer Site.
  --DELETE FROM AR_IREC_PAYMENT_LIST_GT
  --WHERE CUSTOMER_ID        = p_customer_id
  --AND CUSTOMER_SITE_USE_ID = nvl(p_customer_site_use_id, CUSTOMER_SITE_USE_ID)
  --AND CURRENCY_CODE        = p_currency_code;
-- commented the delete sql as part of  bug 9173720

      --Added for bug # 9696274
      IF (p_payment_schedule_id IS NOT NULL)
      THEN
         DELETE FROM ar_irec_payment_list_gt
               WHERE payment_schedule_id = p_payment_schedule_id
                 AND currency_code = p_currency_code;
      END IF;

----------------------------------------------------------------------------------------
      l_debug_info := 'Fetch all the rows into the global temporary table';

-----------------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

      OPEN open_invoice_list (p_customer_id,
                              p_customer_site_use_id,
                              p_payment_schedule_id,
                              p_currency_code
                             );

      FETCH open_invoice_list
      BULK COLLECT INTO l_open_invoice_list_rec;

      CLOSE open_invoice_list;

      --l_grace_days_flag := is_grace_days_enabled_wrapper();
      l_grace_days_flag :=
         ari_utilities.is_discount_grace_days_enabled (p_customer_id,
                                                       p_customer_site_use_id
                                                      );

      FOR trx IN l_open_invoice_list_rec.FIRST .. l_open_invoice_list_rec.LAST
      LOOP
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (   'Inserting: '
                                || l_open_invoice_list_rec (trx).trx_number
                               );
         END IF;

----------------------------------------------------------------------------------------
         l_debug_info := 'Calculate discount';

-----------------------------------------------------------------------------------------
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (l_debug_info);
         END IF;

         arp_discounts_api.get_discount
            (p_ps_id                  => l_open_invoice_list_rec (trx).payment_schedule_id,
             p_apply_date             => TRUNC (SYSDATE),
             p_in_applied_amount      =>   l_open_invoice_list_rec (trx).amount_due_remaining
                                         - l_open_invoice_list_rec (trx).dispute_amt,
             p_grace_days_flag        => l_grace_days_flag,
             p_out_discount           => l_open_invoice_list_rec (trx).original_discount_amt,
             p_out_rem_amt_rcpt       => l_rem_amt_rcpt,
             p_out_rem_amt_inv        => l_rem_amt_inv,
             p_called_from            => 'OIR'
            );
         l_open_invoice_list_rec (trx).discount_amount :=
                           l_open_invoice_list_rec (trx).original_discount_amt;
         l_open_invoice_list_rec (trx).paying_customer_id :=
                                     l_open_invoice_list_rec (trx).customer_id;
         l_open_invoice_list_rec (trx).paying_site_use_id :=
                            l_open_invoice_list_rec (trx).customer_site_use_id;
         --Bug 4479224
         l_open_invoice_list_rec (trx).customer_id := p_customer_id;

         IF (p_customer_site_use_id = NULL)
         THEN
            l_open_invoice_list_rec (trx).customer_site_use_id := -1;
         ELSE
            l_open_invoice_list_rec (trx).customer_site_use_id :=
                                                       p_customer_site_use_id;
         END IF;

         BEGIN
            l_open_invoice_list_rec (trx).payment_amt :=
               ari_utilities.curr_round_amt
                        (  l_open_invoice_list_rec (trx).amount_due_remaining
                         - l_open_invoice_list_rec (trx).discount_amount
                         - l_open_invoice_list_rec (trx).dispute_amt,
                         l_open_invoice_list_rec (trx).invoice_currency_code
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
--Commented for bug # 9696274
-- Added for bug  9173720
--    BEGIN
--    select 1 into l_trx_rec_exists FROM ar_irec_payment_list_gt where payment_schedule_id = l_open_invoice_list_rec(trx).payment_schedule_id;
--   EXCEPTION
--   WHEN NO_DATA_FOUND THEN
--        l_trx_rec_Exists :=0;
--    END;

      --    IF (l_trx_rec_exists = 1) Then
-- l_open_invoice_list_rec.delete(trx);
--    END IF ;
      END LOOP;

      FORALL trx IN l_open_invoice_list_rec.FIRST .. l_open_invoice_list_rec.LAST
         INSERT INTO ar_irec_payment_list_gt
              VALUES l_open_invoice_list_rec (trx);
----------------------------------------------------------------------------------------
      l_debug_info := 'Compute service charge';

-----------------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

      l_total_service_charge :=
         get_service_charge (p_customer_id,
                             p_customer_site_use_id,
                             p_payment_type,
                             p_lookup_code
                            );
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (   'Unexpected Exception in '
                                || g_pkg_name
                                || l_procedure_name
                               );
            arp_standard.DEBUG ('- Customer Id: ' || p_customer_id);
            arp_standard.DEBUG (   '- Customer Site Use Id: '
                                || p_customer_site_use_id
                               );
            arp_standard.DEBUG ('- Currency Code: ' || p_currency_code);
            arp_standard.DEBUG (   '- Payment Schedule Id: '
                                || p_payment_schedule_id
                               );
            arp_standard.DEBUG ('ERROR =>' || SQLERRM);
         END IF;

         ROLLBACK TO create_invoice_pay_list_sp;
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END create_invoice_pay_list;

/*============================================================
  | PUBLIC procedure create_open_credit_pay_list
  |
  | DESCRIPTION
  |   Copy all open credit transactions for the active customer, site and currency from the
  |   AR_PAYMENT_SCHEDULES to the Payment List GT
  |
  | PSEUDO CODE/LOGIC
  |
  | PARAMETERS
  |   p_customer_id               IN NUMBER
  |   p_customer_site_use_id      IN NUMBER DEFAULT NULL
  |   p_currency_code             IN VARCHAR2
  |
  | KNOWN ISSUES
  |
  |
  |
  | NOTES
  |
  |
  |
  | MODIFICATION HISTORY
  | Date          Author       Description of Changes
  | 21-JAN-2004   rsinthre     Created
  | 08-Jul-2005     rsinthre     Bug 4437225 - Disputed amount against invoice not displayed during payment
  +============================================================*/
   PROCEDURE create_open_credit_pay_list (
      p_customer_id            IN   NUMBER,
      p_customer_site_use_id   IN   NUMBER DEFAULT NULL,
      p_currency_code          IN   VARCHAR2
   )
   IS
      CURSOR credit_transactions_list (
         p_customer_id            NUMBER,
         p_customer_site_use_id   NUMBER,
         p_currency_code          VARCHAR2
      )
      IS
         (SELECT *
            FROM (SELECT ps.customer_id,
                         DECODE
                            (ps.customer_site_use_id,
                             NULL, -1,
                             ps.customer_site_use_id
                            ) AS customer_site_use_id,
                         acct.account_number, ps.customer_trx_id,
                         ps.trx_number, ps.trx_date, ps.CLASS, ps.due_date,
                         ps.payment_schedule_id, ps.status,
                         trm.NAME term_desc,
                         arpt_sql_func_util.get_number_of_due_dates
                                           (ps.term_id)
                                                       number_of_installments,
                         ps.terms_sequence_number,
                         ps.amount_line_items_original line_amount,
                         ps.tax_original tax_amount,
                         ps.freight_original freight_amount,
                         ps.receivables_charges_charged finance_charge,
                         ps.invoice_currency_code, ps.amount_due_original,
                         DECODE
                            (ps.CLASS,
                             'PMT', ar_irec_payments.get_pymt_amnt_due_remaining
                                                           (ps.cash_receipt_id),
                             ps.amount_due_remaining
                            ) AS amount_due_remaining,
                         0 payment_amt, 0 service_charge, 0 discount_amount,
                         CASE
                            WHEN ((TRUNC (ps.trx_date) - TRUNC (SYSDATE)) <= 0
                                 )
                               THEN TRUNC (SYSDATE)
                            ELSE ps.trx_date
                         END AS receipt_date,
                         '' receipt_number, ct.purchase_order AS po_number,
                         NULL AS so_number, ct.printing_option,
                         ct.interface_header_context,
                         ct.interface_header_attribute1,
                         ct.interface_header_attribute2,
                         ct.interface_header_attribute3,
                         ct.interface_header_attribute4,
                         ct.interface_header_attribute5,
                         ct.interface_header_attribute6,
                         ct.interface_header_attribute7,
                         ct.interface_header_attribute8,
                         ct.interface_header_attribute9,
                         ct.interface_header_attribute10,
                         ct.interface_header_attribute11,
                         ct.interface_header_attribute12,
                         ct.interface_header_attribute13,
                         ct.interface_header_attribute14,
                         ct.interface_header_attribute15,
                         ps.attribute_category, ps.attribute1, ps.attribute2,
                         ps.attribute3, ps.attribute4, ps.attribute5,
                         ps.attribute6, ps.attribute7, ps.attribute8,
                         ps.attribute9, ps.attribute10, ps.attribute11,
                         ps.attribute12, ps.attribute13, ps.attribute14,
                         ps.attribute15, SYSDATE last_update_date,
                         0 last_updated_by, SYSDATE creation_date,
                         0 created_by, 0 last_update_login,
                         0 application_amount, ps.cash_receipt_id,
                         0 original_discount_amt, ps.org_id,
                         0 paying_customer_id, 0 paying_site_use_id,
                         0 dispute_amt
                    FROM ar_payment_schedules ps,
                         ra_customer_trx_all ct,
                         hz_cust_accounts acct,
                         ra_terms trm
                   WHERE ps.customer_id = p_customer_id
                     AND (ps.CLASS = 'CM' OR ps.CLASS = 'PMT')
                     AND ps.customer_trx_id = ct.customer_trx_id(+)
                     AND NVL (ps.customer_site_use_id, -1) =
                            NVL (p_customer_site_use_id,
                                 NVL (ps.customer_site_use_id, -1)
                                )
                     AND acct.cust_account_id = ps.customer_id
                     AND ps.status = 'OP'
                     AND ps.invoice_currency_code = p_currency_code
                     AND ps.term_id = trm.term_id(+))
           WHERE amount_due_remaining < 0);

      l_procedure_name                 VARCHAR2 (50);
      l_debug_info                     VARCHAR2 (200);

      TYPE t_credit_transactions_list_rec IS TABLE OF credit_transactions_list%ROWTYPE
         INDEX BY BINARY_INTEGER;

      l_credit_transactions_list_rec   t_credit_transactions_list_rec;
   BEGIN
      l_procedure_name := '.create_open_credit_pay_list';
---------------------------------------------------------------------------
      l_debug_info :=
                    'Fetch all open credit transactions into Payment List GT';

---------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

      OPEN credit_transactions_list (p_customer_id,
                                     p_customer_site_use_id,
                                     p_currency_code
                                    );

      FETCH credit_transactions_list
      BULK COLLECT INTO l_credit_transactions_list_rec;

      CLOSE credit_transactions_list;

      FOR trx IN
         l_credit_transactions_list_rec.FIRST .. l_credit_transactions_list_rec.LAST
      LOOP
         l_credit_transactions_list_rec (trx).payment_amt :=
                    l_credit_transactions_list_rec (trx).amount_due_remaining;
      END LOOP;

      FORALL trx IN l_credit_transactions_list_rec.FIRST .. l_credit_transactions_list_rec.LAST
         INSERT INTO ar_irec_payment_list_gt
              VALUES l_credit_transactions_list_rec (trx);
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (   'Unexpected Exception in '
                                || g_pkg_name
                                || l_procedure_name
                               );
            arp_standard.DEBUG ('- Customer Id: ' || p_customer_id);
            arp_standard.DEBUG (   '- Customer Site Use Id: '
                                || p_customer_site_use_id
                               );
            arp_standard.DEBUG ('- Currency Code: ' || p_currency_code);
            arp_standard.DEBUG ('ERROR =>' || SQLERRM);
         END IF;

         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END create_open_credit_pay_list;

/*============================================================
 | PUBLIC procedure cal_discount_and_service_chrg
 |
 | DESCRIPTION
 |   Calculate discount and service charge on the selected
 |   invoices and update the amounts
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |   This procedure acts on the rows inserted in the global
 |   temporary table by the create_invoice_pay_list procedure.
 |   It is session specific.
 |
 |
 | MODIFICATION HISTORY
 | Date          Author       Description of Changes
 | 13-Jan-2003   krmenon      Created
 | 26-Apr-2004   vnb          Added Customer and Customer Site as input params.
 | 10-Jun-2004   vnb          Bug # 3458134 - Check if the grace days for discount option is
 |                     enabled while calculating discount
 | 19-Jul-2004   vnb          Bug # 2830823 - Added exception block to handle exceptions
 | 31-Dec-2004   vnb          Bug 4071551 - Removed redundant code
 | 07-Jul-2005     rsinthre  Bug 4437220 - Payment amount not changed when discount recalculated
 | 22-Mar-2010   nkanchan     Bug 8293098 - Service change based on credit card types
 | 18-May-2011  rsinthre      Bug 12542249 - DISCOUNT AMT NOT COMING CORRECTLY FOR INSTALLMENT PAYMENT TERMS
 | 11-Oct-2012  melapaku      Bug 14672025 - DISCOUNT CALCULATION IS WRONG FOR FUTURE DATED PAYMENTS.
 | 19-Oct-2012  melapaku      Bug 14781706 -  FUTURE DATED PAYMENT INCLUDING CREDIT MEMO FAILS WITH
 |                                            APPLY DATE MUST BE GREATER RECEIPT DATE
 | 29-May-2014  melapaku      Bug 18832462 - Future date payment for double discount  and disputed invoices
 +============================================================*/
   PROCEDURE cal_discount_and_service_chrg (
      p_customer_id         IN   NUMBER,
      p_site_use_id         IN   NUMBER DEFAULT NULL,
      p_receipt_date        IN   DATE DEFAULT TRUNC (SYSDATE),
      p_payment_type        IN   VARCHAR2 DEFAULT NULL,
      p_lookup_code         IN   VARCHAR2 DEFAULT NULL,
      p_receipt_date_flag   IN   VARCHAR2 DEFAULT NULL
   )
   IS                                                -- Added for Bug 18832462
      --l_invoice_list        ARI_SERVICE_CHARGE_PKG.INVOICE_LIST_TABTYPE;
      l_total_service_charge   NUMBER;
      l_count                  NUMBER;
      l_payment_amount         NUMBER;
      l_prev_disc_amt          NUMBER;
      l_discount_amount        NUMBER;
      l_amt_due_remaining      NUMBER;
      l_rem_amt_rcpt           NUMBER;
      l_rem_amt_inv            NUMBER;
      l_grace_days_flag        VARCHAR2 (2);
      l_procedure_name         VARCHAR2 (50);
      l_debug_info             VARCHAR2 (200);
      l_receipt_date           DATE;
      l_dispute_amt            NUMBER;

      --Bug # 3467287 - The Global Temp table must be striped by Customer and Customer Site.
      --Bug 4062938 - Select only debit transactions
      CURSOR invoice_list
      IS
         SELECT     payment_schedule_id, receipt_date, amount_due_remaining,
                    payment_amt AS payment_amount, discount_amount,
                    customer_id, account_number, customer_trx_id,
                    currency_code, service_charge, trx_date, dispute_amt
               FROM ar_irec_payment_list_gt
              WHERE customer_id = p_customer_id
                AND customer_site_use_id =
                       NVL (DECODE (p_site_use_id, -1, NULL, p_site_use_id),
                            customer_site_use_id
                           )
                AND trx_class IN ('INV', 'DEP', 'DM', 'CB', 'CM')
         --Modified for Bug 14781706
         FOR UPDATE;
   BEGIN
      --Assign default values
      l_total_service_charge := 0;
      l_discount_amount := 0;
      l_payment_amount := 0;
      l_prev_disc_amt := 0;
      l_amt_due_remaining := 0;
      l_rem_amt_rcpt := 0;
      l_rem_amt_inv := 0;
      l_procedure_name := '.cal_discount_and_service_chrg';
      l_dispute_amt := 0;
      SAVEPOINT cal_disc_and_service_charge_sp;
      -- Check if grace days have to be considered for discount.
      --l_grace_days_flag := is_grace_days_enabled_wrapper();
      l_grace_days_flag :=
         ari_utilities.is_discount_grace_days_enabled (p_customer_id,
                                                       p_site_use_id
                                                      );

      -- Create the invoice list table
      FOR invoice_rec IN invoice_list
      LOOP
---------------------------------------------------------------------------
         l_debug_info := 'Calculate discount';

---------------------------------------------------------------------------
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (l_debug_info);
         END IF;

         l_prev_disc_amt := invoice_rec.discount_amount;
         l_amt_due_remaining := invoice_rec.amount_due_remaining;
         l_dispute_amt := invoice_rec.dispute_amt;
         l_receipt_date := p_receipt_date;

         -- Added below code for Bug 18832462
         IF (p_receipt_date_flag IS NULL)
         THEN
            l_payment_amount := invoice_rec.payment_amount;
         ELSE
            l_payment_amount := l_amt_due_remaining - l_dispute_amt;
         END IF;

         -- Bug# 14672025 - Added IF condition inorder to fetch the correct receipt date based on payment type
         IF ((    (p_payment_type = 'CREDIT_CARD')
              AND (invoice_rec.trx_date >= TRUNC (SYSDATE))
             )
            )
         THEN
            l_receipt_date := invoice_rec.trx_date;
         END IF;

         IF (    (p_payment_type = 'BANK_ACCOUNT')
             AND (TRUNC (l_receipt_date) < TRUNC (invoice_rec.trx_date))
            )
         THEN
            l_receipt_date := invoice_rec.trx_date;
         END IF;

         -- Added below code for Bug 18832462
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (   'l_payment_amount: '
                                || l_payment_amount
                                || 'p_receipt_date: '
                                || p_receipt_date
                                || 'invoice_rec.payment_schedule_id: '
                                || invoice_rec.payment_schedule_id
                                || 'l_amt_due_remaining: '
                                || l_amt_due_remaining
                                || 'l_dispute_amt: '
                                || l_dispute_amt
                                || 'l_prev_disc_amt: '
                                || l_prev_disc_amt
                                || 'p_receipt_date_flag: '
                                || p_receipt_date_flag
                               );
         END IF;

         arp_discounts_api.get_discount
                                  (p_ps_id                  => invoice_rec.payment_schedule_id,
                                   p_apply_date             => p_receipt_date,
                                   -- Modified for Bug#14672025
                                   p_in_applied_amount      => l_payment_amount,
                                   p_grace_days_flag        => l_grace_days_flag,
                                   p_out_discount           => l_discount_amount,
                                   p_out_rem_amt_rcpt       => l_rem_amt_rcpt,
                                   p_out_rem_amt_inv        => l_rem_amt_inv,
                                   p_called_from            => 'OIR'
                                  );                 -- Added for Bug 18247364

         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (   'Trx: '
                                || invoice_rec.payment_schedule_id
                                || ' Discount: '
                                || l_discount_amount
                                || ' Rcpt: '
                                || l_rem_amt_rcpt
                                || ' Inv: '
                                || l_rem_amt_inv
                                || 'l_receipt_date: '
                                || l_receipt_date
                               );
         END IF;

         -- Bug 18727728 - Future dated payment for a disputed and discounted invoice gives wrong total pay

         -- Bug 4352272 - Support both positive and negative invoices
         IF (   (ABS (l_payment_amount + l_discount_amount + l_dispute_amt) >
                                                     ABS (l_amt_due_remaining)
                )
             OR (ABS (l_payment_amount + l_prev_disc_amt + l_dispute_amt) =
                                                     ABS (l_amt_due_remaining)
                )
            )
         THEN
            l_payment_amount :=
                      l_amt_due_remaining - l_discount_amount - l_dispute_amt;
         ELSIF (l_payment_amount <>
                    (l_amt_due_remaining - l_discount_amount - l_dispute_amt
                    )
               )
         THEN
            l_payment_amount := l_payment_amount - l_discount_amount;
         END IF;

         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG ('l_payment_amount: ' || l_payment_amount);
         END IF;

-----------------------------------------------------------------------------------------
         l_debug_info :=
                      'Update transaction list with discount and receipt date';

-----------------------------------------------------------------------------------------
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (l_debug_info);
         END IF;

         UPDATE ar_irec_payment_list_gt
            SET discount_amount = l_discount_amount,
                receipt_date = TRUNC (l_receipt_date),
                payment_amt = l_payment_amount
          WHERE CURRENT OF invoice_list;
      END LOOP;

-----------------------------------------------------------------------------------------
      l_debug_info := 'Compute service charge';

-----------------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

      -- Bug # 3467287 - The service charge calculator API is striped by
      --                 Customer and Customer Site.
      -- Bug 3886652 - Customer Id and Customer Site Use Id added as params to ARI_CONFIG.is_service_charge_enabled
      l_total_service_charge :=
         get_service_charge (p_customer_id,
                             p_site_use_id,
                             p_payment_type,
                             p_lookup_code
                            );
   --COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            write_debug_and_log
               ('Unexpected Exception while calculating discount and service charge'
               );
            write_debug_and_log ('- Customer Id: ' || p_customer_id);
            write_debug_and_log ('- Customer Site Id: ' || p_site_use_id);
            write_debug_and_log (   '- Total Service charge: '
                                 || l_total_service_charge
                                );
            write_debug_and_log (SQLERRM);
         END;

         ROLLBACK TO cal_disc_and_service_charge_sp;
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END cal_discount_and_service_chrg;

/*============================================================
 | procedure create_payment_instrument
 |
 | DESCRIPTION
 |   Creates a payment instrument with the given details
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date          Author       Description of Changes
 | 15-Jun-2005   rsinthre     Created
 | 18-Oct-2005  rsinthre     Bug 4673563 - Error making credit card payment
 | 04-Aug-2009   avepati      Bug 8664350 - R12 UNABLE TO LOAD FEDERAL RESERVE ACH PARTICIPANT DATA
 | 11-Nov-2009  avepati      Bug 8915943 -  BANK DETAILS NOT COMING ON CLICKING SHOW DETAILS FOR BANK
 | 13-Feb-2013           melapaku  Bug16306925 - PAYMENTS FAIL WHEN SAME BANK ACCOUNT NUMBER , ROUTING NUMBER AND ACCOUNT
 | 05-Mar-2015   gnramasa     Bug 20352248 - ISSUE WITH PAYMENTS FOR SAME ROUTING # BUT DIFFERENT ACCOUNTS
 +============================================================*/
   PROCEDURE create_payment_instrument (
      p_customer_id           IN              NUMBER,
      p_customer_site_id      IN              NUMBER,
      p_account_number        IN              VARCHAR2,
      p_payer_party_id        IN              NUMBER,
      p_expiration_date       IN              DATE,
      p_account_holder_name   IN              VARCHAR2,
      p_account_type          IN              VARCHAR2,
      p_payment_instrument    IN              VARCHAR2,
      p_address_country       IN              VARCHAR2 DEFAULT NULL,
      p_bank_branch_id        IN              NUMBER,
      p_receipt_curr_code     IN              VARCHAR2,
      p_bank_id               IN              NUMBER,
      p_card_brand            IN              VARCHAR2,
      p_cc_bill_to_site_id    IN              NUMBER,
      p_single_use_flag       IN              VARCHAR2,
      p_iban                  IN              VARCHAR2,
      p_routing_number        IN              VARCHAR2,
      p_status                OUT NOCOPY      VARCHAR2,
      x_msg_count             OUT NOCOPY      NUMBER,
      x_msg_data              OUT NOCOPY      VARCHAR2,
      p_assignment_id         OUT NOCOPY      NUMBER,
      p_bank_account_id       OUT NOCOPY      NUMBER
   )
   IS
      l_create_credit_card            iby_fndcpt_setup_pub.creditcard_rec_type;
      l_ext_bank_act_rec              iby_ext_bankacct_pub.extbankacct_rec_type;
      l_result_rec                    iby_fndcpt_common_pub.result_rec_type;
      l_location_rec                  hz_location_v2pub.location_rec_type;
      l_party_site_rec                hz_party_site_v2pub.party_site_rec_type;
      l_payercontext_rec_type         iby_fndcpt_common_pub.payercontext_rec_type;
      l_pmtinstrassignment_rec_type   iby_fndcpt_setup_pub.pmtinstrassignment_rec_type;
      l_pmtinstr_rec_type             iby_fndcpt_setup_pub.pmtinstrument_rec_type;
      l_payer_attibute_id             NUMBER (15, 0);
      l_joint_acct_owner_id           NUMBER;
      l_instrument_type               VARCHAR2 (20);
      l_assignment_id                 NUMBER (15, 0);
      l_count                         NUMBER                             := 0;
--  l_bank_account_id      NUMBER;
      x_return_status                 VARCHAR2 (100);
      l_procedure_name                VARCHAR2 (30);
      l_debug_info                    VARCHAR2 (200);
      l_bank_branch_cur_exists        VARCHAR2 (1)                     := 'N';
      P_ERROR_MSG                     VARCHAR2(1000)  := NULL;
      P_ERROR_CODE                    VARCHAR2(200)  := NULL;
      P_OapfAction                    VARCHAR2(60)   := NULL;
      P_OapfTransactionId             VARCHAR2(60)   := NULL;
      P_OapfNlsLang                   VARCHAR2(30)   := NULL;
      P_OapfPmtInstrID                VARCHAR2(30)   := NULL;
      P_OapfPmtFactorFlag             VARCHAR2(10)   := NULL;
      P_OapfPmtInstrExp               VARCHAR2(30)   := NULL;
      P_OapfOrgType                   VARCHAR2(30)   := NULL;
      P_OapfTrxnRef                   VARCHAR2(60)   := NULL;
      P_OapfPmtInstrDBID              VARCHAR2(60)   := NULL;
      P_OapfPmtChannelCode            VARCHAR2(30)   := NULL;
      P_OapfAuthType                  VARCHAR2(60)   := NULL;
      P_OapfTrxnmid                   VARCHAR2(60)   := NULL;
      P_OapfStoreId                   VARCHAR2(30)   := NULL;
      P_OapfPrice                     VARCHAR2(30)   := NULL;
      P_OapfOrderId                   VARCHAR2(60)   := NULL;
      P_OapfCurr                      VARCHAR2(15)   := NULL;
      P_OapfRetry                     VARCHAR2(15)   := NULL;
      P_OapfCVV2                      VARCHAR2(15)   := NULL;
      X_TOKEN                         VARCHAR2(200)  := NULL;
      X_TOKEN_FLAG                    VARCHAR2(1)    := 'N';

	    AJB_EXCEPTION                   EXCEPTION;
      L_ENCRYPTED_TOKEN               VARCHAR2 (60);
      l_card_tokenizable_flag         VARCHAR2(1)    := 'Y';

      /* Added for Defect 35910 */
       l_log_enabled  FND_PROFILE_OPTION_VALUES.PROFILE_OPTION_VALUE%TYPE;
       l_log_module   FND_PROFILE_OPTION_VALUES.PROFILE_OPTION_VALUE%TYPE;
       l_log_level    FND_PROFILE_OPTION_VALUES.PROFILE_OPTION_VALUE%TYPE;
--  l_commit                      VARCHAR2(2);

      -- added for bug 8664350
      CURSOR bank_branch_cur (l_routing_number VARCHAR2)
      IS
         SELECT DECODE (country,
                        NULL, bank_home_country,
                        country
                       ) country_code,
                bank_party_id, branch_party_id
           FROM ce_bank_branches_v
          WHERE branch_number = l_routing_number;

      CURSOR bank_branch_name_cur (l_routing_number VARCHAR2)
      IS
         SELECT DECODE (bank_name,
                        NULL, routing_number,
                        bank_name
                       ) bank_name,
                DECODE (bank_name,
                        NULL, routing_number,
                        bank_name
                       ) branch_name
           FROM ar_bank_directory
          WHERE routing_number = l_routing_number;

      CURSOR ce_chk_bank_exists_cur (l_bank_name VARCHAR2)
      IS
         -- cursor to check whether the bank exists in ce_bank_Branches_v or not
         SELECT bank_party_id, branch_party_id, branch_number
           FROM ce_bank_branches_v
          WHERE UPPER (bank_name) = UPPER (l_bank_name);

      CURSOR chk_instr_assigned_cur (
         l_bank_account_id    NUMBER,
         p_customer_id        NUMBER,
         p_customer_site_id   NUMBER
      )
      IS
         SELECT instrument_payment_use_id, order_of_preference, start_date
           FROM iby_pmt_instr_uses_all
          WHERE instrument_id = l_bank_account_id
            AND ext_pmt_party_id =
                   (SELECT ext_payer_id
                      FROM iby_external_payers_all
                     WHERE cust_account_id = p_customer_id
                       AND acct_site_use_id = p_customer_site_id);
    --Start added for bug 20352248 gnramasa 5th Mar 2015
    CURSOR c_ext_bank_account (l_account_number VARCHAR2, l_bank_id number, l_branch_id number) IS
      select ext_bank_account_id
      from iby_ext_bank_accounts
      where BANK_ACCOUNT_NUM = l_account_number
      and bank_id = l_bank_id
      and branch_id = l_branch_id
      order by creation_date desc;

      l_api_version                   NUMBER                            := 1.0;
      l_init_msg_list                 VARCHAR2 (30)     DEFAULT fnd_api.g_true;
      l_commit                        VARCHAR2 (30)    DEFAULT fnd_api.g_false;
      l_bank_account_id               iby_ext_bank_accounts_v.bank_account_id%TYPE;
      l_start_date                    iby_ext_bank_accounts_v.start_date%TYPE;
      l_end_date                      iby_ext_bank_accounts_v.end_date%TYPE;
      l_bank_acct_response            iby_fndcpt_common_pub.result_rec_type;
      l_bank_response                 iby_fndcpt_common_pub.result_rec_type;
      l_branch_response               iby_fndcpt_common_pub.result_rec_type;
      l_ext_bank_rec                  iby_ext_bankacct_pub.extbank_rec_type;
      l_ext_branch_rec                iby_ext_bankacct_pub.extbankbranch_rec_type;
      l_bank_party_id                 ce_bank_branches_v.bank_party_id%TYPE;
      l_branch_party_id               ce_bank_branches_v.branch_party_id%TYPE;
      l_address_country               ce_bank_branches_v.country%TYPE
                                                                  DEFAULT 'US';
      l_bank_name                     ar_bank_directory.bank_name%TYPE;
      l_branch_name                   ar_bank_directory.bank_name%TYPE;
      l_st_date                       iby_pmt_instr_uses_all.start_date%TYPE;
      l_priority                      iby_pmt_instr_uses_all.order_of_preference%TYPE;
      l_bank_id                       ce_bank_branches_v.bank_party_id%TYPE;
      l_branch_id                     ce_bank_branches_v.branch_party_id%TYPE;
      bank_branch_rec                 bank_branch_cur%ROWTYPE;
      bank_branch_name_rec            bank_branch_name_cur%ROWTYPE;
      ce_chk_bank_exists_rec          ce_chk_bank_exists_cur%ROWTYPE;
      instr_assign_rec                chk_instr_assigned_cur%ROWTYPE;
   BEGIN

      l_procedure_name := '.create_payment_instrument';
      l_commit := fnd_api.g_false;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'in create_payment_instrument (+)'
                        );
      END IF;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'p_bank_id :: ' || p_bank_id
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'p_bank_branch_id :: ' || p_bank_branch_id
                        );
      END IF;
      IF (p_payment_instrument = 'BANK_ACCOUNT')
      THEN
         l_bank_id := p_bank_id;
         l_branch_id := p_bank_branch_id;

         OPEN bank_branch_cur (p_routing_number);

         FETCH bank_branch_cur
          INTO bank_branch_rec;

         IF (bank_branch_cur%FOUND)
         THEN
            CLOSE bank_branch_cur;

            l_bank_branch_cur_exists := 'Y';
            l_bank_party_id := bank_branch_rec.bank_party_id;
            l_branch_party_id := bank_branch_rec.branch_party_id;
            l_address_country := bank_branch_rec.country_code;

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                          (fnd_log.level_statement,
                           g_pkg_name || l_procedure_name,
                              'Bank and Branch exist for this Routing Number'
                           || p_routing_number
                          );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'Bank Id :: ' || l_bank_party_id
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'Branch Id :: ' || l_branch_party_id
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'l_address_country :: ' || l_address_country
                              );
            END IF;

            l_bank_id := l_bank_party_id;                        --bug 8915943
            l_branch_id := l_branch_party_id;
         ELSE
            CLOSE bank_branch_cur;
         END IF;

--Fetching bank and branch names
         OPEN bank_branch_name_cur (p_routing_number);

         FETCH bank_branch_name_cur
          INTO bank_branch_name_rec;

         IF (bank_branch_name_cur%FOUND)
         THEN
            CLOSE bank_branch_name_cur;

            l_bank_name := bank_branch_name_rec.bank_name;
            l_branch_name := bank_branch_name_rec.branch_name;

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                  (fnd_log.level_statement,
                   g_pkg_name || l_procedure_name,
                      'Fetcheing Bank Name and Branch name for this routing number :: '
                   || p_routing_number
                  );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'Bank Name :: ' || l_bank_name
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'Branch Name :: ' || l_branch_name
                              );
            END IF;
         ELSE
            CLOSE bank_branch_name_cur;
         END IF;

-- Check wether bank already exists in CE . If bank aleady exists create a branch with this routing number for that bank
         OPEN ce_chk_bank_exists_cur (l_bank_name);

         FETCH ce_chk_bank_exists_cur
          INTO ce_chk_bank_exists_rec;

         IF (ce_chk_bank_exists_cur%FOUND AND l_bank_name IS NOT NULL)
         THEN
            CLOSE ce_chk_bank_exists_cur;

            l_bank_party_id := ce_chk_bank_exists_rec.bank_party_id;

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                                  'This Bank '
                               || l_bank_name
                               || ' for the routing number '
                               || p_routing_number
                               || 'already exists in CE_BANK_BRANCHES_V'
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'Bank Id :: ' || l_bank_party_id
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'Branch Id :: ' || l_branch_party_id
                              );
            END IF;
         ELSE
            CLOSE ce_chk_bank_exists_cur;
         END IF;

         IF (l_bank_party_id IS NOT NULL AND l_branch_party_id IS NULL)
         THEN
            l_ext_branch_rec.branch_party_id := NULL;
            l_ext_branch_rec.bank_party_id := l_bank_party_id;
            l_ext_branch_rec.branch_name := p_routing_number;
            l_ext_branch_rec.branch_number := p_routing_number;
            l_ext_branch_rec.branch_type := 'ABA';
            l_ext_branch_rec.bch_object_version_number := '1';
            l_ext_branch_rec.typ_object_version_number := '1';

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                  (fnd_log.level_statement,
                   g_pkg_name || l_procedure_name,
                   'Calling iby_ext_bankacct_pub.create_ext_bank_branch .....'
                  );
            END IF;

            iby_ext_bankacct_pub.create_ext_bank_branch
                                   (
                                    -- IN parameters
                                    p_api_version              => l_api_version,
                                    p_init_msg_list            => l_init_msg_list,
                                    p_ext_bank_branch_rec      => l_ext_branch_rec,
                                    -- OUT parameters
                                    x_branch_id                => l_branch_party_id,
                                    x_return_status            => x_return_status,
                                    x_msg_count                => x_msg_count,
                                    x_msg_data                 => x_msg_data,
                                    x_response                 => l_branch_response
                                   );

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                           (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'End iby_ext_bankacct_pub.create_ext_bank_branch'
                           );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'branch party id :: ' || l_branch_party_id
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'branch x_return_status ::' || x_return_status
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'branch x_msg_data ::' || x_msg_data
                              );
            END IF;

            IF (x_return_status = fnd_api.g_ret_sts_success)
            THEN
               l_bank_id := l_bank_party_id;
               l_branch_id := l_branch_party_id;
            END IF;
         /*---------------------------------------------------------------+
          | If bank and branch could not be found, create new bank,branch |
          +---------------------------------------------------------------*/
         ELSIF (l_bank_party_id IS NULL AND l_branch_party_id IS NULL)
         THEN
            l_ext_bank_rec.bank_id := NULL;
            l_ext_bank_rec.bank_name := l_bank_name;
            l_ext_bank_rec.bank_number := p_routing_number;
            l_ext_bank_rec.institution_type := 'BANK';
            l_ext_bank_rec.country_code := 'US';
--Create banks are used from Federal Sites.. which has details about US banks only.
            l_ext_bank_rec.object_version_number := '1';

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                        (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Calling iby_ext_bankacct_pub.create_ext_bank .....'
                        );
            END IF;

            iby_ext_bankacct_pub.create_ext_bank
                                          (
                                           -- IN parameters
                                           p_api_version        => l_api_version,
                                           p_init_msg_list      => l_init_msg_list,
                                           p_ext_bank_rec       => l_ext_bank_rec,
                                           -- OUT parameters
                                           x_bank_id            => l_bank_party_id,
                                           x_return_status      => x_return_status,
                                           x_msg_count          => x_msg_count,
                                           x_msg_data           => x_msg_data,
                                           x_response           => l_bank_response
                                          );

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'end  iby_ext_bankacct_pub.create_ext_bank'
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'bank party Id ::' || l_bank_party_id
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'bank x_return_status ::' || x_return_status
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'bank x_msg_data ::' || x_msg_data
                              );
            END IF;

            IF (x_return_status = fnd_api.g_ret_sts_success)
            THEN
               l_bank_id := l_bank_party_id;
            END IF;

            l_ext_branch_rec.branch_party_id := NULL;
            l_ext_branch_rec.bank_party_id := l_bank_party_id;
            l_ext_branch_rec.branch_name := l_branch_name;
            l_ext_branch_rec.branch_number := p_routing_number;
            l_ext_branch_rec.branch_type := 'ABA';
            l_ext_branch_rec.bch_object_version_number := '1';
            l_ext_branch_rec.typ_object_version_number := '1';

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                  (fnd_log.level_statement,
                   g_pkg_name || l_procedure_name,
                   'Calling iby_ext_bankacct_pub.create_ext_bank_branch .....'
                  );
            END IF;

            iby_ext_bankacct_pub.create_ext_bank_branch
                                   (
                                    -- IN parameters
                                    p_api_version              => l_api_version,
                                    p_init_msg_list            => l_init_msg_list,
                                    p_ext_bank_branch_rec      => l_ext_branch_rec,
                                    -- OUT parameters
                                    x_branch_id                => l_branch_party_id,
                                    x_return_status            => x_return_status,
                                    x_msg_count                => x_msg_count,
                                    x_msg_data                 => x_msg_data,
                                    x_response                 => l_branch_response
                                   );

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                           (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'End iby_ext_bankacct_pub.create_ext_bank_branch'
                           );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'branch party id :: ' || l_branch_party_id
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'branch x_return_status ::' || x_return_status
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'branch x_msg_data ::' || x_msg_data
                              );
            END IF;

            IF (x_return_status = fnd_api.g_ret_sts_success)
            THEN
               l_branch_id := l_branch_party_id;
            END IF;
         END IF;

-- Added for Bug# 16306925
         IF (l_bank_branch_cur_exists = 'Y')
         THEN
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                                  'Inside when l_bank_branch_cur_exists = '
                               || l_bank_branch_cur_exists
                              );
            END IF;

--   select EXT_BANK_ACCOUNT_ID into l_bank_account_id from iby_ext_bank_accounts where BANK_ACCOUNT_NUM = p_account_number;
--l_bank_id  := l_bank_party_id;  --bug 8915943
--    l_branch_id := l_branch_party_id;
           /* BEGIN
               SELECT ext_bank_account_id
                 INTO l_bank_account_id
                 FROM iby_ext_bank_accounts
                WHERE bank_account_num = p_account_number
                  AND bank_id = l_bank_id
                  AND branch_id = l_branch_id;
              */
               IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level
                  )
               THEN
               fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Inside when l_bank_branch_cur_exists, p_account_number: ' || p_account_number ||' ,l_bank_id: ' || l_bank_id || ' ,l_branch_id: ' || l_branch_id);
               END IF;

               open c_ext_bank_account(p_account_number, l_bank_id, l_branch_id);
               fetch c_ext_bank_account into l_bank_account_id;
               IF (c_ext_bank_account%FOUND) then
                 if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
                  fnd_log.STRING
                     (fnd_log.level_statement,
                      g_pkg_name || l_procedure_name,
                         'Inside when l_bank_branch_cur_exists,l_bank_account_id  = '
                      || l_bank_account_id
                     );
               END IF;
           -- EXCEPTION
               --WHEN OTHERS THEN
              Else
--------------------------------------------------------------------------------------------------------
                  l_debug_info :=
                     'Call IBY create external bank acct - create_ext_bank_acct - to Create a new bank account';
---------------------------------------------------------------------------------------------------------
                  l_ext_bank_act_rec.acct_owner_party_id := p_payer_party_id;

                  IF (p_address_country IS NULL OR p_address_country = '')
                  THEN
                     l_ext_bank_act_rec.country_code := l_address_country;
                  ELSE
                     l_ext_bank_act_rec.country_code := p_address_country;
                  END IF;

                  l_ext_bank_act_rec.bank_account_name :=
                                                         p_account_holder_name;
                  l_ext_bank_act_rec.bank_account_num := p_account_number;
                  l_ext_bank_act_rec.bank_id := l_bank_id;
                  l_ext_bank_act_rec.branch_id := l_branch_id;
                  l_ext_bank_act_rec.currency := p_receipt_curr_code;
                  l_ext_bank_act_rec.multi_currency_allowed_flag := 'Y';
                  l_ext_bank_act_rec.acct_type := p_account_type;
                  l_ext_bank_act_rec.iban := p_iban;

                  IF (fnd_log.level_statement >=
                                               fnd_log.g_current_runtime_level
                     )
                  THEN
                     fnd_log.STRING
                        (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'calling IBY_EXT_BANKACCT_PUB.create_ext_bank_acct ..'
                        );
                     fnd_log.STRING (fnd_log.level_statement,
                                     g_pkg_name || l_procedure_name,
                                        'l_ext_bank_act_rec.bank_id :: '
                                     || l_ext_bank_act_rec.bank_id
                                    );
                     fnd_log.STRING (fnd_log.level_statement,
                                     g_pkg_name || l_procedure_name,
                                        'l_ext_bank_act_rec.branch_id ::'
                                     || l_ext_bank_act_rec.branch_id
                                    );
                     fnd_log.STRING (fnd_log.level_statement,
                                     g_pkg_name || l_procedure_name,
                                        'l_ext_bank_act_rec.country_code ::'
                                     || l_ext_bank_act_rec.country_code
                                    );
                     fnd_log.STRING
                              (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                                  'l_ext_bank_act_rec.acct_owner_party_id :: '
                               || l_ext_bank_act_rec.acct_owner_party_id
                              );
                     fnd_log.STRING
                                  (fnd_log.level_statement,
                                   g_pkg_name || l_procedure_name,
                                      'l_ext_bank_act_rec.bank_account_num ::'
                                   || l_ext_bank_act_rec.bank_account_num
                                  );
                     fnd_log.STRING (fnd_log.level_statement,
                                     g_pkg_name || l_procedure_name,
                                        'l_ext_bank_act_rec.currency ::'
                                     || l_ext_bank_act_rec.currency
                                    );
                     fnd_log.STRING
                                 (fnd_log.level_statement,
                                  g_pkg_name || l_procedure_name,
                                     'l_ext_bank_act_rec.bank_account_name ::'
                                  || l_ext_bank_act_rec.bank_account_name
                                 );
                     fnd_log.STRING (fnd_log.level_statement,
                                     g_pkg_name || l_procedure_name,
                                        'l_ext_bank_act_rec.iban	 ::'
                                     || l_ext_bank_act_rec.iban
                                    );
                     fnd_log.STRING (fnd_log.level_statement,
                                     g_pkg_name || l_procedure_name,
                                        'l_ext_bank_act_rec.acct_type ::'
                                     || l_ext_bank_act_rec.acct_type
                                    );
                  END IF;

                  iby_ext_bankacct_pub.create_ext_bank_acct
                                   (p_api_version            => 1.0,
                                    p_init_msg_list          => fnd_api.g_false,
                                    p_ext_bank_acct_rec      => l_ext_bank_act_rec,
                                    x_acct_id                => l_bank_account_id,
                                    x_return_status          => x_return_status,
                                    x_msg_count              => x_msg_count,
                                    x_msg_data               => x_msg_data,
                                    x_response               => l_result_rec
                                   );
                  write_debug_and_log (   'l_bank_account_id :'
                                       || l_bank_account_id
                                      );

                  IF (x_return_status <> fnd_api.g_ret_sts_success)
                  THEN
                     x_msg_data := l_result_rec.result_code;
                     p_status := fnd_api.g_ret_sts_error;
                     write_error_messages (x_msg_data, x_msg_count);
                     RETURN;
                  END IF;
           -- END;                                              -- exception end
           end if;                                  --IF (c_ext_bank_account%FOUND) then
           close c_ext_bank_account;
          --End added for bug 20352248 gnramasa 5th Mar 2015
         END IF;                                    -- IF l_bank_branch_exists
      ELSE
	     dbms_output.put_line('in else that is - p_payment_instrument = CREDIT_CARD');

 /* E1294 - Added for Creditcard Encryption functionality */
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'E1294 Encryption functionality start'
                        );
         DBMS_SESSION.set_context (namespace      => 'XX_AR_IREC_CONTEXT',
                                   ATTRIBUTE      => 'TYPE',
                                   VALUE          => 'EBS'
                                  );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'p_account_number ::' || MASK_ACCOUNT_NUMBER(p_account_number)
                        );

         /* E1294 - Start - Added for Creditcard Tokenization functionality */
-----------------------------------------------------------------------------------------
         l_debug_info :=
                    'Call to retrieve Token';
-----------------------------------------------------------------------------------------
         /*--Get_token start
         BEGIN ---- Start Block for GET_TOKEN
           BEGIN -- Block start for Call to XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN
             BEGIN  -- to get the card type translation value
               SELECT TARGET_VALUE2
               INTO
               l_card_tokenizable_flag
               FROM   XX_FIN_TRANSLATEVALUES     VAL,
                      XX_FIN_TRANSLATEDEFINITION DEF
               WHERE 1=1
               and   DEF.TRANSLATE_ID = VAL.TRANSLATE_ID
               and   DEF.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
               and   VAL.SOURCE_VALUE1 = 'TOKENABLE_CARD_TYPE'
               and   VAL.ENABLED_FLAG = 'Y'
               and   SYSDATE between VAL.START_DATE_ACTIVE and nvl(VAL.END_DATE_ACTIVE, SYSDATE+1)
               and   VAL.TARGET_VALUE1 = p_card_brand
               ;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                l_card_tokenizable_flag := 'N';
             END; -- end to get the card type translation value

             IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'before call to get_token..' );
                fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'p_card_brand: ' || p_card_brand || ', l_card_tokenizable_flag:' || l_card_tokenizable_flag );
             END IF;

             if ( l_card_tokenizable_flag = 'Y') THEN
               XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN(
                 P_ERROR_MSG => P_ERROR_MSG,
                 P_ERROR_CODE => P_ERROR_CODE,
                 P_OAPFACTION => P_OAPFACTION,
                 P_OAPFTRANSACTIONID => P_OAPFTRANSACTIONID,
                 P_OAPFNLSLANG => P_OAPFNLSLANG,
                 P_OAPFPMTINSTRID => p_account_number,
                 P_OAPFPMTFACTORFLAG => P_OAPFPMTFACTORFLAG,
                 P_OAPFPMTINSTREXP => p_expiration_date,
                 P_OAPFORGTYPE => P_OAPFORGTYPE,
                 P_OAPFTRXNREF => P_OAPFTRXNREF,
                 P_OAPFPMTINSTRDBID => P_OAPFPMTINSTRDBID,
                 P_OAPFPMTCHANNELCODE => P_OAPFPMTCHANNELCODE,
                 P_OAPFAUTHTYPE => P_OAPFAUTHTYPE,
                 P_OAPFTRXNMID => P_OAPFTRXNMID,
                 P_OAPFSTOREID => P_OAPFSTOREID,
                 P_OAPFPRICE => P_OAPFPRICE,
                 P_OAPFORDERID => P_OAPFORDERID,
                 P_OAPFCURR => P_OAPFCURR,
                 P_OAPFRETRY => P_OAPFRETRY,
                 P_OAPFCVV2 => P_OAPFCVV2,
                 X_TOKEN => X_TOKEN,
                 X_TOKEN_FLAG => X_TOKEN_FLAG
               );
               IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                  fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'After call to get_token, X_TOKEN:' || X_TOKEN || ', X_TOKEN_FLAG:' || X_TOKEN_FLAG );
               END IF;
             END IF;
           EXCEPTION
             WHEN OTHERS THEN
               IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                  fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'Exception in call to XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN - ' || SQLERRM );
               END IF;

           END; -- End Block start for Call to XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN
           IF ( l_card_tokenizable_flag = 'Y' and X_TOKEN_FLAG <> 'Y') THEN
             RAISE AJB_EXCEPTION;
           END IF;
         EXCEPTION
           WHEN AJB_EXCEPTION THEN
           ---- Send Email to AMS Team
              xx_ar_irec_token_err_email_pkg.raise_business_event('xx_fin_irec_cc_token_pkg.get_token',p_error_msg,p_customer_id);   --Added for defect 35910
                --Insert into Fnd_log_messages Independent of FND_DEBUG_LOG PROFILE OPTION
                l_log_enabled:=fnd_profile.value('AFLOG_ENABLED');
                if ( l_log_enabled='Y')
                 then
                  fnd_log.STRING (fnd_log.level_statement, g_pkg_name ||l_procedure_name, substr('AJB Exception in call to XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN :'|| UTL_TCP.crlf||p_error_msg,1,2999) );
                else
                 l_log_module:=fnd_profile.value('AFLOG_MODULE');
                 l_log_level :=fnd_profile.value('AFLOG_LEVEL');
                  set_tmp_debug_flag ( 'Y','%','1');
                   fnd_log.STRING (fnd_log.level_statement, g_pkg_name ||l_procedure_name, substr('AJB Exception in call to XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN: '|| UTL_TCP.crlf||p_error_msg ,1,2999));
                  set_tmp_debug_flag ( l_log_enabled,l_log_module,l_log_level);
                end if;
            -- RAISE_APPLICATION_ERROR (-20001, 'Error in processing the payment. Please contact System Administrator');
           WHEN OTHERS THEN
               IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                  fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'Other Exception in get_token - ' || SQLERRM );
               END IF;
         END; --
		 */
         --E1294 - End - Added for Creditcard Tokenization functionality
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
            fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'before xx_od_security_key_pkg.encrypt_outlabel, for credit card encryption' );
         END IF;
         xx_od_security_key_pkg.encrypt_outlabel
                              (p_module             => 'AJB',
                               p_key_label          => NULL,
                               p_algorithm          => '3DES',
                               p_decrypted_val      => p_account_number,
                               x_encrypted_val      => gc_encrypted_cc_num,
                               x_error_message      => gc_cc_encrypt_error_message,
                               x_key_label          => gc_key_label
                              );
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
            fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'after xx_od_security_key_pkg.encrypt_outlabel, for credit card encryption --gc_cc_encrypt_error_message: ' || gc_cc_encrypt_error_message );
         END IF;


         --Get encrypted Token
     --     IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
     --        fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'before xx_od_security_key_pkg.encrypt_outlabel, for Token encryption' );
     --     END IF;
		 --if (l_card_tokenizable_flag = 'Y') then
     --      xx_od_security_key_pkg.encrypt_outlabel
     --                           (p_module             => 'AJB',
     --                            p_key_label          => NULL,
     --                            p_algorithm          => '3DES',
     --                            p_decrypted_val      => X_TOKEN,
     --                            x_encrypted_val      => L_ENCRYPTED_TOKEN,
     --                            x_error_message      => gc_cc_encrypt_error_message,
     --                            x_key_label          => gc_key_label
     --                          );
     --       IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
     --          fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'after xx_od_security_key_pkg.encrypt_outlabel, for token encryption, L_ENCRYPTED_TOKEN: ' || L_ENCRYPTED_TOKEN || ',--gc_cc_encrypt_error_message: ' || gc_cc_encrypt_error_message );
     --      END IF;
     --
     --    end if;


         fnd_log.STRING
            (fnd_log.level_statement,
             g_pkg_name || l_procedure_name,
                'E1294 xx_od_security_key_pkg.encrypt_outlabel error message:'
             || gc_cc_encrypt_error_message
            );

         IF gc_cc_encrypt_error_message IS NOT NULL
         THEN
            x_msg_data := gc_cc_encrypt_error_message;
            p_status := fnd_api.g_ret_sts_error;
            RETURN;
         END IF;


         l_create_credit_card.card_id := NULL;
         l_create_credit_card.owner_id := p_payer_party_id;
         l_create_credit_card.card_holder_name := p_account_holder_name;
         l_create_credit_card.active_flag := 'Y'; -- Added as per defect 29753

         IF p_cc_bill_to_site_id > 0
         THEN
            l_create_credit_card.billing_address_id := p_cc_bill_to_site_id;
            l_create_credit_card.billing_postal_code := NULL;
            l_create_credit_card.billing_address_territory := NULL;
         ELSE
            l_create_credit_card.billing_address_id := NULL;
            l_create_credit_card.billing_postal_code := 94065;
            l_create_credit_card.billing_address_territory := 'US';
         END IF;

         l_create_credit_card.card_number := p_account_number;
         l_create_credit_card.expiration_date := p_expiration_date;
         l_create_credit_card.instrument_type := 'CREDITCARD';
         l_create_credit_card.purchasecard_subtype := NULL;
         --Due to iFrame changes, the UI will not have element to capture card type/card brand.
         --So, we need to invoke the following function to get the card_brand
         l_create_credit_card.card_issuer := GET_CREDIT_CARD_TYPE(p_account_number); --p_card_brand;
         l_create_credit_card.single_use_flag := p_single_use_flag;
         l_create_credit_card.info_only_flag := 'N';
         /* E1294 - Start - Added for Creditcard Encryption functionality */
       --  l_create_credit_card.attribute4 := gc_encrypted_cc_num    /* Commented for Defect 35918 and 35919 */
         l_create_credit_card.attribute5 := gc_key_label;


         /* E1294 - Start - Added for Creditcard Tokenization functionality */
         if ( l_card_tokenizable_flag = 'Y' ) then
           l_create_credit_card.attribute6            := gc_encrypted_cc_num;
           l_create_credit_card.card_number           := p_account_number;
           l_create_credit_card.Register_Invalid_Card := 'Y';
         end if;

         --The token call is being done in PaymentUtilities.java. Hence,
         --X_TOKEN_FLAG will always be 'Y', for all cards. If we get error in getting token, we throw exception
         l_create_credit_card.attribute7 := 'Y';


         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
            fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'before iby_fndcpt_setup_pub.create_card,  l_create_credit_card.card_issuer: ' || l_create_credit_card.card_issuer );
         END IF;
-----------------------------------------------------------------------------------------
         l_debug_info :=
                    'Call IBY create card - Create_Card - to Create with a Token or CC';
-----------------------------------------------------------------------------------------
         iby_fndcpt_setup_pub.create_card
                                   (p_api_version          => 1.0,
                                    p_init_msg_list        => fnd_api.g_false,
                                    p_commit               => l_commit,
                                    x_return_status        => x_return_status,
                                    x_msg_count            => x_msg_count,
                                    x_msg_data             => x_msg_data,
                                    p_card_instrument      => l_create_credit_card,
                                    x_card_id              => l_bank_account_id,
                                    x_response             => l_result_rec
                                   );
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
            fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'after iby_fndcpt_setup_pub.create_card, x_return_status: ' || x_return_status || ', l_card_id :' || l_bank_account_id );
         END IF;

         write_debug_and_log ('l_card_id :' || l_bank_account_id);

         IF (x_return_status <> fnd_api.g_ret_sts_success)
         THEN
            p_status := fnd_api.g_ret_sts_error;
            x_msg_data := l_result_rec.result_code;
            dbms_output.put_line('--after iby_fndcpt_setup_pub.create_card, x_msg_data: ' || x_msg_data);
            write_error_messages (x_msg_data, x_msg_count);
            RETURN;
         END IF;
      END IF;

      -- Added for Bug#16306925
      IF (p_payment_instrument = 'BANK_ACCOUNT')
      THEN
         SELECT COUNT (*)
           INTO l_count
           FROM iby_account_owners
          WHERE account_owner_party_id = p_payer_party_id
            AND ext_bank_account_id = l_bank_account_id;

         IF (l_count <= 0)
         THEN
            write_debug_and_log
                       (   'Adding joint account owner >> l_bank_account_id '
                        || l_bank_account_id
                        || ' p_payer_party_id :'
                        || p_payer_party_id
                       );
            iby_ext_bankacct_pub.add_joint_account_owner
                              (p_api_version              => 1.0,
                               p_init_msg_list            => fnd_api.g_false,
                               p_bank_account_id          => l_bank_account_id,
                               p_acct_owner_party_id      => p_payer_party_id,
                               x_joint_acct_owner_id      => l_joint_acct_owner_id,
                               x_return_status            => x_return_status,
                               x_msg_count                => x_msg_count,
                               x_msg_data                 => x_msg_data,
                               x_response                 => l_result_rec
                              );
            write_debug_and_log (   'l_joint_acct_owner_id : '
                                 || l_joint_acct_owner_id
                                );

            IF (x_return_status <> fnd_api.g_ret_sts_success)
            THEN
               p_status := fnd_api.g_ret_sts_error;
               x_msg_data := l_result_rec.result_code;
               write_error_messages (x_msg_data, x_msg_count);
               RETURN;
            END IF;
         END IF;                                               -- l_count <= 0
      END IF;                                               -- if bank account

      --Now assign the instrument to the payer.
      OPEN chk_instr_assigned_cur (l_bank_account_id,
                                   p_customer_id,
                                   p_customer_site_id
                                  );

      FETCH chk_instr_assigned_cur
       INTO instr_assign_rec;

      IF (chk_instr_assigned_cur%FOUND)
      THEN
         CLOSE chk_instr_assigned_cur;

         l_assignment_id := instr_assign_rec.instrument_payment_use_id;
         l_priority := instr_assign_rec.order_of_preference;
         l_st_date := instr_assign_rec.start_date;
         write_debug_and_log (   'l_bank_account_id = '
                              || l_bank_account_id
                              || ' p_customer_id = '
                              || p_customer_id
                              || ' p_customer_site_id = '
                              || p_customer_site_id
                             );
         write_debug_and_log (   'l_assignment_id = '
                              || l_assignment_id
                              || 'l_priority '
                              || l_priority
                              || 'l_st_date '
                              || l_st_date
                             );
      ELSE
         CLOSE chk_instr_assigned_cur;

         l_assignment_id := NULL;
         l_priority := 1;
         l_st_date := SYSDATE;
      END IF;

  -- End  Bug# 16306925
-----------------------------------------------------------------------------------------
      l_debug_info := 'Call IBY Instrumnet Assignment - To assign instrument';
-----------------------------------------------------------------------------------------
      write_debug_and_log (l_debug_info);

      IF (p_payment_instrument = 'BANK_ACCOUNT')
      THEN
         l_instrument_type := 'BANKACCOUNT';
      ELSE
         l_instrument_type := 'CREDITCARD';
      END IF;

      l_payercontext_rec_type.payment_function := 'CUSTOMER_PAYMENT';
      l_payercontext_rec_type.party_id := p_payer_party_id;
      l_payercontext_rec_type.cust_account_id := p_customer_id;

      IF (p_customer_site_id IS NOT NULL)
      THEN
         l_payercontext_rec_type.org_type := 'OPERATING_UNIT';
         l_payercontext_rec_type.org_id := mo_global.get_current_org_id;
         l_payercontext_rec_type.account_site_id := p_customer_site_id;
      END IF;

      l_pmtinstr_rec_type.instrument_type := l_instrument_type;
      l_pmtinstr_rec_type.instrument_id := l_bank_account_id;
      l_pmtinstrassignment_rec_type.assignment_id := l_assignment_id;
      l_pmtinstrassignment_rec_type.instrument := l_pmtinstr_rec_type;
      l_pmtinstrassignment_rec_type.priority := l_priority;
      l_pmtinstrassignment_rec_type.start_date := l_st_date;
      l_pmtinstrassignment_rec_type.end_date := NULL;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
         fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'before iby_fndcpt_setup_pub.set_payer_instr_assignment' );
      END IF;

      iby_fndcpt_setup_pub.set_payer_instr_assignment
                       (p_api_version             => 1.0,
                        p_init_msg_list           => fnd_api.g_false,
                        p_commit                  => fnd_api.g_false,
                        x_return_status           => x_return_status,
                        x_msg_count               => x_msg_count,
                        x_msg_data                => x_msg_data,
                        p_payer                   => l_payercontext_rec_type,
                        p_assignment_attribs      => l_pmtinstrassignment_rec_type,
                        x_assign_id               => l_assignment_id,
                        x_response                => l_result_rec
                       );
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
         fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'after iby_fndcpt_setup_pub.set_payer_instr_assignment, x_return_status: ' || x_return_status || ', l_assignment_id: ' || l_assignment_id || ', Credit Card Number - ' || MASK_ACCOUNT_NUMBER(p_account_number) );
      END IF;

      IF (x_return_status <> fnd_api.g_ret_sts_success)
      THEN
         p_status := fnd_api.g_ret_sts_error;
         x_msg_data := l_result_rec.result_code;
         write_error_messages (x_msg_data, x_msg_count);
         RETURN;
      END IF;

      p_assignment_id := l_assignment_id;
      p_bank_account_id := l_bank_account_id;
      p_status := x_return_status;
      write_debug_and_log ('instrument_assignment_id :' || p_assignment_id);

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'Create Payment Instrument - Return status - '
                         || x_return_status
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'Create Payment Instrument - Message Count - '
                         || x_msg_count
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'Create Payment Instrument - Message Data - '
                         || x_msg_data
                        );
         --Modified for Defect#34441
         fnd_log.STRING
                       (fnd_log.level_statement,
                        g_pkg_name || l_procedure_name,
                           'Create Payment Instrument - Credit Card Number - '
                        || mask_account_number(p_account_number)
                       );
      END IF;

      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_status := fnd_api.g_ret_sts_error;
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         --Modified for Defect#34441
         write_debug_and_log ('- Card Number: ' || mask_account_number(p_account_number));
         write_debug_and_log (   '- CC Billing Addrress Site Id: '
                              || p_cc_bill_to_site_id
                             );
         write_debug_and_log ('- Singe Use Flag: ' || p_single_use_flag);
         write_debug_and_log ('- Return Status: ' || p_status);
         write_debug_and_log ('ERROR =>' || SQLERRM);
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END create_payment_instrument;

/*============================================================
 | procedure create_cc_bill_to_site
 |
 | DESCRIPTION
 |   Creates/Updates Credit card bill to location with the given details
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date          Author       Description of Changes
 | 17-Aug-2005   rsinthre     Created
 +============================================================*/
   PROCEDURE create_cc_bill_to_site (
      p_init_msg_list        IN              VARCHAR2 := fnd_api.g_false,
      p_commit               IN              VARCHAR2 := fnd_api.g_true,
      p_cc_location_rec      IN              hz_location_v2pub.location_rec_type,
      p_payer_party_id       IN              NUMBER,
      x_cc_bill_to_site_id   IN OUT NOCOPY   NUMBER,
      x_return_status        OUT NOCOPY      VARCHAR2,
      x_msg_count            OUT NOCOPY      NUMBER,
      x_msg_data             OUT NOCOPY      VARCHAR2
   )
   IS
      l_location_id             NUMBER (15, 0);
      l_location_rec            hz_location_v2pub.location_rec_type;
      l_party_site_rec          hz_party_site_v2pub.party_site_rec_type;
      l_party_site_number       VARCHAR2 (30);
      l_object_version_number   NUMBER (15, 0);

      CURSOR location_id_cur
      IS
         SELECT hps.location_id, hl.object_version_number
           FROM hz_party_sites hps, hz_locations hl
          WHERE party_site_id = x_cc_bill_to_site_id
            AND hps.location_id = hl.location_id;

      location_id_rec           location_id_cur%ROWTYPE;
      l_procedure_name          VARCHAR2 (30);
      l_debug_info              VARCHAR2 (200);
   BEGIN
      l_procedure_name := '.create_cc_bill_to_site';
-----------------------------------------------------------------------------------------
      l_debug_info :=
         'Call TCA create location - create_location - to create location for new CC';
-----------------------------------------------------------------------------------------
      hz_location_v2pub.create_location (p_init_msg_list      => p_init_msg_list,
                                         p_location_rec       => p_cc_location_rec,
                                         x_location_id        => l_location_id,
                                         x_return_status      => x_return_status,
                                         x_msg_count          => x_msg_count,
                                         x_msg_data           => x_msg_data
                                        );

      IF (x_return_status <> fnd_api.g_ret_sts_success)
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         write_error_messages (x_msg_data, x_msg_count);
         RETURN;
      END IF;

      write_debug_and_log ('cc_billing_location_id :' || l_location_id);
      l_party_site_rec.party_id := p_payer_party_id;
      l_party_site_rec.location_id := l_location_id;
      l_party_site_rec.identifying_address_flag := 'N';
      l_party_site_rec.created_by_module := 'ARI';
      hz_party_site_v2pub.create_party_site
                                  (p_init_msg_list          => p_init_msg_list,
                                   p_party_site_rec         => l_party_site_rec,
                                   x_party_site_id          => x_cc_bill_to_site_id,
                                   x_party_site_number      => l_party_site_number,
                                   x_return_status          => x_return_status,
                                   x_msg_count              => x_msg_count,
                                   x_msg_data               => x_msg_data
                                  );
      write_debug_and_log ('cc_billing_site_id :' || x_cc_bill_to_site_id);

      IF (x_return_status <> fnd_api.g_ret_sts_success)
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         write_error_messages (x_msg_data, x_msg_count);
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         write_debug_and_log ('- Return Status: ' || x_return_status);
         write_debug_and_log ('ERROR =>' || SQLERRM);
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END create_cc_bill_to_site;

/*============================================================
 | PUBLIC procedure create_receipt
 |
 | DESCRIPTION
 |   Creates a cash receipt fpr the given customer
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date          Author       Description of Changes
 | 13-Jan-2003   krmenon      Created
 | 17-Nov-2004   vnb          Bug 4000279 - Modified to return error message, if any
 +============================================================*/
   PROCEDURE create_receipt (
      p_payment_amount               IN              NUMBER,
      p_customer_id                  IN              NUMBER,
      p_site_use_id                  IN              NUMBER,
      p_bank_account_id              IN              NUMBER,
      p_receipt_date                 IN              DATE
            DEFAULT TRUNC (SYSDATE),
      p_receipt_method_id            IN              NUMBER,
      p_receipt_currency_code        IN              VARCHAR2,
      p_receipt_exchange_rate        IN              NUMBER,
      p_receipt_exchange_rate_type   IN              VARCHAR2,
      p_receipt_exchange_rate_date   IN              DATE,
      p_trxn_extn_id                 IN              NUMBER,
      p_cash_receipt_id              OUT NOCOPY      NUMBER,
      p_status                       OUT NOCOPY      VARCHAR2,
      x_msg_count                    OUT NOCOPY      NUMBER,
      x_msg_data                     OUT NOCOPY      VARCHAR2,
      p_attr1                        IN              VARCHAR2,
      p_attr_category                IN              VARCHAR2,
      p_confirmemail                IN              VARCHAR2
   )
   IS
      l_receipt_method_id         ar_cash_receipts_all.receipt_method_id%TYPE;
      l_receipt_creation_status   VARCHAR2 (80);
      l_cash_receipt_id           ar_cash_receipts_all.cash_receipt_id%TYPE;
      x_return_status             VARCHAR2 (100);
      l_procedure_name            VARCHAR2 (30);
      l_debug_info                VARCHAR2 (200);
      l_instr_assign_id           NUMBER;
      l_attribute_rec             ar_receipt_api_pub.attribute_rec_type;
   BEGIN
      l_procedure_name := '.create_receipt';
      fnd_log_repository.init;
      l_attribute_rec.attribute11 := p_bank_account_id;
      --Added for R12 upgrade retrofit. For Defect27888
      l_attribute_rec.attribute4 := p_attr1;                           --V2.0
      l_attribute_rec.attribute_category := p_attr_category;           --V2.0
-----------------------------------------------------------------------------------------
      l_debug_info :=
         'Call public AR receipts API - create_cash - to create receipt for payment';
-----------------------------------------------------------------------------------------
      write_debug_and_log ('p_payment_amount:' || p_payment_amount);
      write_debug_and_log ('p_receipt_method_id:' || p_receipt_method_id);
      write_debug_and_log ('p_trxn_extn_id:' || p_trxn_extn_id);
      write_debug_and_log ('p_customer_id:' || p_customer_id);
      write_debug_and_log ('p_site_use_id:' || p_site_use_id);
      write_debug_and_log (   'p_receipt_currency_code:'
                           || p_receipt_currency_code
                          );
      write_debug_and_log ('p_bank_account_id:' || p_bank_account_id);
      write_debug_and_log ('p_attr1:' || p_attr1);
      write_debug_and_log ('p_attr_category:' || p_attr_category);

-------------------------------------------------------------------------------------------
      IF p_attr_category IS NOT NULL
      THEN                                          -- for echeck bank payment
         ar_receipt_api_pub.create_cash
                       (p_api_version                    => 1.0,
                        p_init_msg_list                  => fnd_api.g_true,
                        p_commit                         => fnd_api.g_false,
                        p_validation_level               => fnd_api.g_valid_level_full,
                        x_return_status                  => x_return_status,
                        x_msg_count                      => x_msg_count,
                        x_msg_data                       => x_msg_data,
                        p_amount                         => p_payment_amount,
                        p_receipt_method_id              => p_receipt_method_id,
                        p_customer_id                    => p_customer_id,
                        p_customer_site_use_id           => p_site_use_id,
                        p_customer_bank_account_id       => p_bank_account_id,
                        /* Added for defect30000 */
                        p_default_site_use               => 'N',
                        p_payment_trxn_extension_id      => p_trxn_extn_id,
                        p_currency_code                  => p_receipt_currency_code,
                        p_exchange_rate                  => p_receipt_exchange_rate,
                        p_exchange_rate_type             => p_receipt_exchange_rate_type,
                        p_exchange_rate_date             => p_receipt_exchange_rate_date,
                        p_receipt_date                   => TRUNC
                                                               (p_receipt_date),
                        p_attribute_rec                  => l_attribute_rec,
                        --V2.0
                        p_cr_id                          => l_cash_receipt_id,
                        p_called_from                    => 'IREC'
                       );


           insert_irec_ext (l_cash_receipt_id,
                              p_confirmemail );
      ELSE                                                   --for credit card
         ar_receipt_api_pub.create_cash
                       (p_api_version                    => 1.0,
                        p_init_msg_list                  => fnd_api.g_true,
                        p_commit                         => fnd_api.g_false,
                        p_validation_level               => fnd_api.g_valid_level_full,
                        x_return_status                  => x_return_status,
                        x_msg_count                      => x_msg_count,
                        x_msg_data                       => x_msg_data,
                        p_amount                         => p_payment_amount,
                        p_receipt_method_id              => p_receipt_method_id,
                        p_customer_id                    => p_customer_id,
                        p_customer_site_use_id           => p_site_use_id,
                        p_default_site_use               => 'N',
                        p_payment_trxn_extension_id      => p_trxn_extn_id,
                        p_currency_code                  => p_receipt_currency_code,
                        p_exchange_rate                  => p_receipt_exchange_rate,
                        p_exchange_rate_type             => p_receipt_exchange_rate_type,
                        p_exchange_rate_date             => p_receipt_exchange_rate_date,
                        p_receipt_date                   => TRUNC
                                                               (p_receipt_date),
                        p_attribute_rec                  => l_attribute_rec,
                        --V2.0
                        p_cr_id                          => l_cash_receipt_id,
                        p_called_from                    => 'IREC'
                       );
      END IF;

      p_cash_receipt_id := l_cash_receipt_id;
      p_status := x_return_status;
      write_debug_and_log ('p_receipt_currency_code:' || l_cash_receipt_id);

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Create Cash - Rerturn status - ' || x_return_status
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Create Cash - Message Count - ' || x_msg_count
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Create Cash - Message Data - ' || x_msg_data
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Create Cash - CR Id - ' || l_cash_receipt_id
                        );
      END IF;

      arp_standard.DEBUG ('X_RETURN_STATUS=>' || x_return_status);
      arp_standard.DEBUG ('X_MSG_COUNT=>' || TO_CHAR (x_msg_count));
   EXCEPTION
      WHEN OTHERS
      THEN
         p_status := fnd_api.g_ret_sts_error;
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         write_debug_and_log ('- Customer Id: ' || p_customer_id);
         write_debug_and_log ('- Customer Site Id: ' || p_site_use_id);
         write_debug_and_log ('- Cash Receipt Id: ' || p_cash_receipt_id);
         write_debug_and_log ('- Bank Account Id: ' || p_bank_account_id);
         write_debug_and_log ('- Return Status: ' || p_status);
         write_debug_and_log ('ERROR =>' || SQLERRM);
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END create_receipt;

/*=============================================================
 | HISTORY
 |  17-Nov-2004   vnb          Bug 4000279 - Modified to return error message, if any
 |
 | PARAMETERS
 |
 |   p_customer_id          IN    Customer Id
 |   p_site_use_id          IN    Customer Site Id
 |   p_cash_receipt_id      IN    Cash Receipt Id
 |   p_return_status       OUT    Success/Error status
 |   p_apply_err_count     OUT    Number of unsuccessful applications
 |
 +=============================================================*/
   PROCEDURE apply_cash (
      p_customer_id       IN              NUMBER,
      p_site_use_id       IN              NUMBER DEFAULT NULL,
      p_cash_receipt_id   IN              NUMBER,
      p_return_status     OUT NOCOPY      VARCHAR2,
      p_apply_err_count   OUT NOCOPY      NUMBER,
      x_msg_count         OUT NOCOPY      NUMBER,
      x_msg_data          OUT NOCOPY      VARCHAR2
   )
   IS
--Bug # 3467287 - The Global Temp table must be striped by Customer and Customer Site.
      CURSOR credit_trx_list
      IS
         SELECT *
           FROM ar_irec_payment_list_gt
          WHERE customer_id = p_customer_id
            AND customer_site_use_id =
                   NVL (DECODE (p_site_use_id, -1, NULL, p_site_use_id),
                        customer_site_use_id
                       )
            AND (trx_class = 'CM' OR trx_class = 'PMT');

      CURSOR debit_trx_list
      IS
         SELECT   *
             FROM ar_irec_payment_list_gt
            WHERE customer_id = p_customer_id
              AND customer_site_use_id =
                     NVL (DECODE (p_site_use_id, -1, NULL, p_site_use_id),
                          customer_site_use_id
                         )
              AND (   trx_class = 'INV'
                   OR trx_class = 'DM'
                   OR trx_class = 'GUAR'
                   OR trx_class = 'CB'
                   OR trx_class = 'DEP'
                  )
         ORDER BY amount_due_remaining ASC;

      x_return_status               VARCHAR2 (100);
      l_msg_count                   NUMBER;
      l_msg_data                    VARCHAR2 (255);
      l_apply_err_count             NUMBER;
      l_application_ref_num         ar_receivable_applications.application_ref_num%TYPE;
      l_receivable_application_id   ar_receivable_applications.receivable_application_id%TYPE;
      l_applied_rec_app_id          ar_receivable_applications.receivable_application_id%TYPE;
      l_acctd_amount_applied_from   ar_receivable_applications.acctd_amount_applied_from%TYPE;
      l_acctd_amount_applied_to     ar_receivable_applications.acctd_amount_applied_to%TYPE;
      l_procedure_name              VARCHAR2 (30);
      l_debug_info                  VARCHAR2 (200);
      credit_trx_list_count         NUMBER;
      debit_trx_list_count          NUMBER;
      total_trx_count               NUMBER;
      l_rec_apply_date              DATE;            -- Added for Bug 18866462
   BEGIN
      --Assign default values
      l_msg_count := 0;
      l_apply_err_count := 0;
      l_procedure_name := '.apply_cash';

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'In apply_cash: p_customer_id='
                         || p_customer_id
                         || ','
                         || 'p_site_use_id='
                         || p_site_use_id
                         || ','
                         || 'p_cash_receipt_id='
                         || p_cash_receipt_id
                        );
      END IF;

      --Pring in the debug log : Total No of rows in ar_irec_payment_list_gt
      SELECT COUNT (*)
        INTO total_trx_count
        FROM ar_irec_payment_list_gt;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'Total no of rows in ar_irec_payment_list_gt='
                         || total_trx_count
                        );
      END IF;

--Pring in the debug log : No of rows that will be picked by the cursor credit_trx_list
      SELECT COUNT (*)
        INTO credit_trx_list_count
        FROM ar_irec_payment_list_gt
       WHERE customer_id = p_customer_id
         AND customer_site_use_id =
                NVL (DECODE (p_site_use_id, -1, NULL, p_site_use_id),
                     customer_site_use_id
                    )
         AND (trx_class = 'CM' OR trx_class = 'PMT');

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'credit_trx_list_count: ' || credit_trx_list_count
                        );
      END IF;

--Pring in the debug log : No of rows that will be picked by the cursor debit_trx_list
      SELECT COUNT (*)
        INTO debit_trx_list_count
        FROM ar_irec_payment_list_gt
       WHERE customer_id = p_customer_id
         AND customer_site_use_id =
                NVL (DECODE (p_site_use_id, -1, NULL, p_site_use_id),
                     customer_site_use_id
                    )
         AND (   trx_class = 'INV'
              OR trx_class = 'DM'
              OR trx_class = 'GUAR'
              OR trx_class = 'CB'
              OR trx_class = 'DEP'
             );

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'debit_trx_list_count: ' || debit_trx_list_count
                        );
      END IF;

      -- Added below code for Bug 18866462 : Start
      SELECT TRUNC (SYSDATE)
        INTO l_rec_apply_date
        FROM DUAL;

      BEGIN
         SELECT TRUNC (receipt_date)
           INTO l_rec_apply_date
           FROM ar_cash_receipts_all cr
          WHERE cr.cash_receipt_id = p_cash_receipt_id;
      END;

      -- Added below code for Bug 18866462 : End
      --
      -- Establish a save point
      --
      SAVEPOINT ari_apply_cash_receipt_pvt;
----------------------------------------------------------------------------------
      l_debug_info := 'Step 1: Apply credits against the receipt (if any)';

----------------------------------------------------------------------------------
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         l_debug_info
                        );
      END IF;

      FOR trx IN credit_trx_list
      LOOP
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'trx.trx_class=' || trx.trx_class
                           );
         END IF;

         IF (trx.trx_class = 'CM')
         THEN
            -- The transaction is a credit memo
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                                  'Calling AR_RECEIPT_API_PUB.apply for CM:'
                               || 'trx.customer_trx_id='
                               || trx.customer_trx_id
                               || ','
                               || 'trx.terms_sequence_number='
                               || trx.terms_sequence_number
                               || ','
                               || 'trx.payment_schedule_id='
                               || trx.payment_schedule_id
                               || ','
                               || 'trx.payment_amt='
                               || trx.payment_amt
                               || ','
                               || 'trx.discount_amount='
                               || trx.discount_amount
                               || ','
                               || 'trx.receipt_date='
                               || l_rec_apply_date
                              );                  -- Modified for Bug 18866462
            END IF;

            ar_receipt_api_pub.APPLY
                    (p_api_version                      => 1.0,
                     p_init_msg_list                    => fnd_api.g_true,
                     p_commit                           => fnd_api.g_false,
                     p_validation_level                 => fnd_api.g_valid_level_full,
                     x_return_status                    => x_return_status,
                     x_msg_count                        => x_msg_count,
                     x_msg_data                         => x_msg_data,
                     p_cash_receipt_id                  => p_cash_receipt_id,
                     p_customer_trx_id                  => trx.customer_trx_id,
                     p_installment                      => trx.terms_sequence_number,
                     p_applied_payment_schedule_id      => trx.payment_schedule_id,
                     p_amount_applied                   => trx.payment_amt,
                     p_discount                         => trx.discount_amount,
                     p_apply_date                       => l_rec_apply_date,
                     -- Modified for Bug 18866462
                     p_called_from                      => 'IREC'
                    );

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                             (fnd_log.level_statement,
                              g_pkg_name || l_procedure_name,
                              'Execution of AR_RECEIPT_API_PUB.apply is over'
                             );
            END IF;
         ELSE
            -- The transaction must be a payment
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                  (fnd_log.level_statement,
                   g_pkg_name || l_procedure_name,
                      'Calling AR_RECEIPT_API_PUB.apply_open_receipt for PMT:'
                   || 'trx.cash_receipt_id='
                   || trx.cash_receipt_id
                   || ','
                   || 'trx.payment_amt='
                   || trx.payment_amt
                   || ','
                   || 'l_application_ref_num='
                   || l_application_ref_num
                   || ','
                   || 'l_receivable_application_id='
                   || l_receivable_application_id
                   || ','
                   || 'l_applied_rec_app_id='
                   || l_applied_rec_app_id
                   || ','
                   || 'l_acctd_amount_applied_from='
                   || l_acctd_amount_applied_from
                   || ','
                   || 'l_acctd_amount_applied_to='
                   || l_acctd_amount_applied_to
                  );
            END IF;

            ar_receipt_api_pub.apply_open_receipt
                  (p_api_version                    => 1.0,
                   p_init_msg_list                  => fnd_api.g_true,
                   p_commit                         => fnd_api.g_false,
                   x_return_status                  => x_return_status,
                   x_msg_count                      => x_msg_count,
                   x_msg_data                       => x_msg_data,
                   p_cash_receipt_id                => p_cash_receipt_id,
                   p_open_cash_receipt_id           => trx.cash_receipt_id,
                   p_amount_applied                 => trx.payment_amt,
                   p_called_from                    => 'IREC',
                   x_application_ref_num            => l_application_ref_num,
                   x_receivable_application_id      => l_receivable_application_id,
                   x_applied_rec_app_id             => l_applied_rec_app_id,
                   x_acctd_amount_applied_from      => l_acctd_amount_applied_from,
                   x_acctd_amount_applied_to        => l_acctd_amount_applied_to
                  );

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                  (fnd_log.level_statement,
                   g_pkg_name || l_procedure_name,
                   'Execution of AR_RECEIPT_API_PUB.apply_open_receipt is over'
                  );
            END IF;
         END IF;

         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'x_return_status=' || x_return_status
                           );
         END IF;

         -- Check for errors and increment the count for
         -- errored applcations
         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            l_apply_err_count := l_apply_err_count + 1;
            p_apply_err_count := l_apply_err_count;
            p_return_status := fnd_api.g_ret_sts_error;
            ROLLBACK TO ari_apply_cash_receipt_pvt;
            RETURN;
         END IF;

         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                               'Applied receipt '
                            || trx.trx_number
                            || ', Status: '
                            || x_return_status
                           );
         END IF;

         write_debug_and_log ('X_RETURN_STATUS=>' || x_return_status);
         write_debug_and_log ('X_MSG_COUNT=>' || TO_CHAR (x_msg_count));
      END LOOP;

----------------------------------------------------------------------------------
      l_debug_info := 'Step 2: Apply debits against the receipt';

----------------------------------------------------------------------------------
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         l_debug_info
                        );
      END IF;

      FOR trx IN debit_trx_list
      LOOP
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING
                       (fnd_log.level_statement,
                        g_pkg_name || l_procedure_name,
                           'Calling AR_RECEIPT_API_PUB.apply for debit trx: '
                        || 'p_cash_receipt_id='
                        || p_cash_receipt_id
                        || ','
                        || 'trx.customer_trx_id='
                        || trx.customer_trx_id
                        || ','
                        || 'trx.payment_schedule_id='
                        || trx.payment_schedule_id
                        || ','
                        || 'trx.payment_amt='
                        || trx.payment_amt
                        || ','
                        || 'trx.service_charge='
                        || trx.service_charge
                        || ','
                        || 'trx.discount_amount='
                        || trx.discount_amount
                        || ','
                        || 'p_apply_date='
                        || TO_CHAR (TRUNC (l_rec_apply_date))
                       );                         -- Modified for Bug 18866462
         END IF;

         --
         -- Call the application API
         --
         ar_receipt_api_pub.APPLY
                    (p_api_version                      => 1.0,
                     p_init_msg_list                    => fnd_api.g_true,
                     p_commit                           => fnd_api.g_false,
                     p_validation_level                 => fnd_api.g_valid_level_full,
                     x_return_status                    => x_return_status,
                     x_msg_count                        => x_msg_count,
                     x_msg_data                         => x_msg_data,
                     p_cash_receipt_id                  => p_cash_receipt_id,
                     p_customer_trx_id                  => trx.customer_trx_id,
                     p_applied_payment_schedule_id      => trx.payment_schedule_id,
                     p_amount_applied                   =>   trx.payment_amt
                                                           + NVL
                                                                (trx.service_charge,
                                                                 0
                                                                ),
                     p_discount                         => trx.discount_amount,
                     p_apply_date                       => l_rec_apply_date,
                     -- Modified for Bug 18866462
                     p_called_from                      => 'IREC'
                    );

         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING
               (fnd_log.level_statement,
                g_pkg_name || l_procedure_name,
                   'Execution of AR_RECEIPT_API_PUB.apply is over. Return Status='
                || x_return_status
               );
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'x_msg_data=' || x_msg_data
                           );
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'x_msg_count=' || x_msg_count
                           );
         END IF;

         -- Check for errors and increment the count for
         -- errored applcations
         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            l_apply_err_count := l_apply_err_count + 1;
            p_apply_err_count := l_apply_err_count;
            p_return_status := fnd_api.g_ret_sts_error;
            ROLLBACK TO ari_apply_cash_receipt_pvt;
            RETURN;
         END IF;

         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                               'Applied Cash to '
                            || trx.trx_number
                            || ' Status: '
                            || x_return_status
                           );
         END IF;

         write_debug_and_log ('X_RETURN_STATUS=>' || x_return_status);
         write_debug_and_log ('X_MSG_COUNT=>' || TO_CHAR (x_msg_count));
         write_debug_and_log ('x_msg_data=>' || x_msg_data);
      END LOOP;

      p_apply_err_count := l_apply_err_count;
      -- There are no errored applications; set the
      -- return status to success
      p_return_status := fnd_api.g_ret_sts_success;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'Exiting apply_cash with return status: '
                         || p_return_status
                        );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            p_return_status := fnd_api.g_ret_sts_error;
            write_debug_and_log (   'Unexpected Exception in '
                                 || g_pkg_name
                                 || l_procedure_name
                                );
            write_debug_and_log ('- Customer Id: ' || p_customer_id);
            write_debug_and_log ('- Customer Site Id: ' || p_site_use_id);
            write_debug_and_log ('- Cash Receipt Id: ' || p_cash_receipt_id);
            write_debug_and_log ('- Return Status: ' || p_return_status);
            write_debug_and_log (SQLERRM);
            fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
            fnd_message.set_token ('PROCEDURE',
                                   g_pkg_name || l_procedure_name);
            fnd_message.set_token ('ERROR', SQLERRM);
            fnd_message.set_token ('DEBUG_INFO', l_debug_info);
            fnd_msg_pub.ADD;
         END;
   END apply_cash;

/*=====================================================================
 | FUNCTION get_service_charge
 |
 | DESCRIPTION
 |   This function will calculate the service charge for the multiple
 |   invoices that have been selected for payment and return the
 |   total service charge that is to be applied.
 |
 | HISTORY
 |   26-APR-2004     vnb      Bug # 3467287 - Added Customer and Customer Site
 |                     as input parameters.
 |   19-JUL-2004     vnb      Bug # 2830823 - Added exception block to handle exceptions
 |   21-SEP-2004     vnb      Bug # 3886652 - Added customer site use id to ARI_SERVICE_CHARGE_PKG.INVOICE_LIST_TABTYPE
 | 22-Mar-2010   nkanchan     Bug 8293098 - Service change based on credit card types
 |
 +=====================================================================*/
   FUNCTION get_service_charge (
      p_customer_id    IN   NUMBER,
      p_site_use_id    IN   NUMBER DEFAULT NULL,
      p_payment_type   IN   VARCHAR2 DEFAULT NULL,
      p_lookup_code    IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_invoice_list           ari_service_charge_pkg.invoice_list_tabtype;
      l_total_service_charge   NUMBER;
      l_count                  NUMBER;
      l_currency_code          ar_irec_payment_list_gt.currency_code%TYPE;
      l_service_charge         NUMBER;
      l_procedure_name         VARCHAR2 (30);
      l_debug_info             VARCHAR2 (200);

      --Bug # 3467287 - The Global Temp table must be striped by Customer and Customer Site.
      --Bug # 3886652 - Added customer site use id to ARI_SERVICE_CHARGE_PKG.INVOICE_LIST_TABTYPE
      CURSOR invoice_list
      IS
         SELECT payment_schedule_id, payment_amt AS payment_amount,
                customer_id, customer_site_use_id, account_number,
                customer_trx_id, currency_code, service_charge
           FROM ar_irec_payment_list_gt
          WHERE customer_id = p_customer_id
            AND customer_site_use_id =
                   NVL (DECODE (p_site_use_id, -1, NULL, p_site_use_id),
                        customer_site_use_id
                       )
            AND trx_class IN ('INV', 'DM', 'CB', 'DEP');
   BEGIN
      --Assign default values
      l_total_service_charge := 0;
      l_procedure_name := '.get_service_charge';
      SAVEPOINT service_charge_sp;
----------------------------------------------------------------------------------------
      l_debug_info := 'Check if service charge is enabled; else return zero';

-----------------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

      IF NOT (ari_utilities.is_service_charge_enabled (p_customer_id,
                                                       p_site_use_id
                                                      )
             )
      THEN
         RETURN l_total_service_charge;
      END IF;

----------------------------------------------------------------------------------------
      l_debug_info := 'Create the invoice list table';

-----------------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG ('In getServiceCharge begin for Loop..');
      END IF;

      FOR invoice_rec IN invoice_list
      LOOP
         --Bug 4071551 - Changed the indexing field to Payment Schedule Id from Customer Trx Id to keep uniqueness
         l_count := invoice_rec.payment_schedule_id;

         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG ('Index: ' || l_count);
         END IF;

         l_invoice_list (l_count).payment_schedule_id :=
                                               invoice_rec.payment_schedule_id;
         l_invoice_list (l_count).payment_amount := invoice_rec.payment_amount;
         l_invoice_list (l_count).customer_id := invoice_rec.customer_id;
         --Bug # 3886652 - Added customer site use id to ARI_SERVICE_CHARGE_PKG.INVOICE_LIST_TABTYPE
         l_invoice_list (l_count).customer_site_use_id :=
                                              invoice_rec.customer_site_use_id;
         l_invoice_list (l_count).account_number := invoice_rec.account_number;
         l_invoice_list (l_count).customer_trx_id :=
                                                   invoice_rec.customer_trx_id;
         l_invoice_list (l_count).currency_code := invoice_rec.currency_code;
         l_invoice_list (l_count).service_charge := invoice_rec.service_charge;
         l_currency_code := invoice_rec.currency_code;

         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (   'invoice_rec.payment_schedule_id: '
                                || invoice_rec.payment_schedule_id
                               );
            arp_standard.DEBUG (   'invoice_rec.payment_amount: '
                                || invoice_rec.payment_amount
                               );
            arp_standard.DEBUG (   'invoice_rec.customer_id: '
                                || invoice_rec.customer_id
                               );
            arp_standard.DEBUG (   'invoice_rec.customer_site_use_id: '
                                || invoice_rec.customer_site_use_id
                               );
            --Modified for Defect#34441
            arp_standard.DEBUG (   'invoice_rec.account_number: '
                                || mask_account_number(invoice_rec.account_number)
                               );
            arp_standard.DEBUG (   'invoice_rec.customer_trx_id '
                                || invoice_rec.customer_trx_id
                               );
            arp_standard.DEBUG (   'invoice_rec.currency_code: '
                                || invoice_rec.currency_code
                               );
            arp_standard.DEBUG (   'invoice_rec.service_charge: '
                                || invoice_rec.service_charge
                               );
         END IF;
      END LOOP;

      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (   'End first Loop. Total records: '
                             || l_invoice_list.COUNT
                            );
      END IF;

----------------------------------------------------------------------------------------
      l_debug_info := 'Call the service charge package to compute';

-----------------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

      ari_service_charge_pkg.compute_service_charge (l_invoice_list,
                                                     p_payment_type,
                                                     p_lookup_code
                                                    );
      l_count := l_invoice_list.FIRST;

      WHILE l_count IS NOT NULL
      LOOP
         l_service_charge :=
            ari_utilities.curr_round_amt
                                     (l_invoice_list (l_count).service_charge,
                                      l_currency_code
                                     );

         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG
                              (   'Index: '
                               || l_count
                               || ' PaymentScheduleId: '
                               || l_invoice_list (l_count).payment_schedule_id
                               || 'Service Charge: '
                               || l_invoice_list (l_count).service_charge
                              );
         END IF;

----------------------------------------------------------------------------------------
         l_debug_info := 'Update service charge in the Payment GT';

-----------------------------------------------------------------------------------------
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (l_debug_info);
         END IF;

         UPDATE ar_irec_payment_list_gt
            SET service_charge = l_service_charge
          WHERE payment_schedule_id =
                                  l_invoice_list (l_count).payment_schedule_id;

         l_total_service_charge := l_total_service_charge + l_service_charge;

         -- Error handling required
         IF SQL%ROWCOUNT < 1
         THEN
            IF (pg_debug = 'Y')
            THEN
               arp_standard.DEBUG ('Error - Cannot update ' || l_count);
            END IF;
         END IF;

         l_count := l_invoice_list.NEXT (l_count);
      END LOOP;

      COMMIT;
      RETURN l_total_service_charge;
   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            write_debug_and_log
                       ('Unexpected Exception while computing service charge');
            write_debug_and_log ('- Customer Id: ' || p_customer_id);
            write_debug_and_log ('- Customer Site Id: ' || p_site_use_id);
            write_debug_and_log (   '- Total Service charge: '
                                 || l_total_service_charge
                                );
            write_debug_and_log (SQLERRM);
         END;

         ROLLBACK TO service_charge_sp;
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END get_service_charge;

/*=====================================================================
 | PROCEDURE apply_service_charge
 |
 | DESCRIPTION
 |   This function will calculate the service charge for the multiple
 |   invoices that have been selected for payment and return the
 |   total service charge that is to be applied.
 |
 | HISTORY
 |  26-APR-2004  vnb         Bug # 3467287 - Added Customer and Customer Site
 |                           as input parameters.
 |  19-JUL-2004  vnb         Bug # 2830823 - Added exception block to handle exceptions
 |  21-SEP-2004  vnb         Bug # 3886652 - Added customer site use id to ARI_SERVICE_CHARGE_PKG.INVOICE_LIST_TABTYPE
 |
 +=====================================================================*/
   PROCEDURE apply_service_charge (
      p_customer_id     IN              NUMBER,
      p_site_use_id     IN              NUMBER DEFAULT NULL,
      x_return_status   OUT NOCOPY      VARCHAR2
   )
   IS
      l_invoice_list           ari_service_charge_pkg.invoice_list_tabtype;
      l_total_service_charge   NUMBER;
      l_count                  NUMBER;
      l_return_status          VARCHAR2 (2);
      l_procedure_name         VARCHAR2 (50);
      l_debug_info             VARCHAR2 (200);

      --Bug # 3467287 - The Global Temp table must be striped by Customer and Customer Site.
      --Bug # 3886652 - Added customer site use id to ARI_SERVICE_CHARGE_PKG.INVOICE_LIST_TABTYPE
      CURSOR invoice_list
      IS
         SELECT payment_schedule_id, payment_amt AS payment_amount,
                customer_id, customer_site_use_id, account_number,
                customer_trx_id, currency_code, service_charge, receipt_date
           FROM ar_irec_payment_list_gt
          WHERE customer_id = p_customer_id
            AND customer_site_use_id =
                   NVL (DECODE (p_site_use_id, -1, NULL, p_site_use_id),
                        customer_site_use_id
                       )
            AND (   trx_class = 'INV'
                 OR trx_class = 'DM'
                 OR trx_class = 'GUAR'
                 OR trx_class = 'CB'
                 OR trx_class = 'DEP'
                );
   BEGIN
      --Assign default values
      l_total_service_charge := 0;
      l_procedure_name := '.apply_service_charge';
      fnd_log_repository.init;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         '+'
                        );
      END IF;

      l_count := 1;
-- Create the invoice list table
----------------------------------------------------------------------------------
      l_debug_info := 'Create the invoice list table';

----------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG ('In Apply_Service_Charge begin for Loop..');
      END IF;

      FOR invoice_rec IN invoice_list
      LOOP
         --l_count := invoice_rec.customer_trx_id;
         --l_invoice_list.EXTEND;
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'Index: ' || l_count
                           );
         END IF;

         l_invoice_list (l_count).payment_schedule_id :=
                                               invoice_rec.payment_schedule_id;
         l_invoice_list (l_count).payment_amount := invoice_rec.payment_amount;
         l_invoice_list (l_count).customer_id := invoice_rec.customer_id;
         --Bug # 3886652 - Added customer site use id to ARI_SERVICE_CHARGE_PKG.INVOICE_LIST_TABTYPE
         l_invoice_list (l_count).customer_site_use_id :=
                                              invoice_rec.customer_site_use_id;
         l_invoice_list (l_count).account_number := invoice_rec.account_number;
         l_invoice_list (l_count).customer_trx_id :=
                                                   invoice_rec.customer_trx_id;
         l_invoice_list (l_count).currency_code := invoice_rec.currency_code;
         l_invoice_list (l_count).service_charge := invoice_rec.service_charge;
         l_invoice_list (l_count).apply_date := invoice_rec.receipt_date;
         l_invoice_list (l_count).gl_date := invoice_rec.receipt_date;

         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (   'invoice_rec.payment_schedule_id: '
                                || invoice_rec.payment_schedule_id
                               );
            arp_standard.DEBUG (   'invoice_rec.payment_amount: '
                                || invoice_rec.payment_amount
                               );
            arp_standard.DEBUG (   'invoice_rec.customer_id: '
                                || invoice_rec.customer_id
                               );
            arp_standard.DEBUG (   'invoice_rec.customer_site_use_id: '
                                || invoice_rec.customer_site_use_id
                               );
            --Modified for Defect#34441
            arp_standard.DEBUG (   'invoice_rec.account_number: '
                                || mask_account_number(invoice_rec.account_number)
                               );
            arp_standard.DEBUG (   'invoice_rec.customer_trx_id '
                                || invoice_rec.customer_trx_id
                               );
            arp_standard.DEBUG (   'invoice_rec.currency_code: '
                                || invoice_rec.currency_code
                               );
            arp_standard.DEBUG (   'invoice_rec.service_charge: '
                                || invoice_rec.service_charge
                               );
         END IF;

         l_count := l_count + 1;
      END LOOP;

-- Call the service charge compute package
----------------------------------------------------------------------------------
      l_debug_info := 'Apply service charge';
----------------------------------------------------------------------------------
      l_return_status := ari_service_charge_pkg.apply_charge (l_invoice_list);

      IF (l_return_status <> fnd_api.g_ret_sts_success)
      THEN
         -- bug 3672530 - Ensure graceful error handling
         x_return_status := fnd_api.g_ret_sts_error;

         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'ERROR: Loop count is: ' || l_count
                           );
         END IF;

         app_exception.raise_exception;
      END IF;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         '-'
                        );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            x_return_status := fnd_api.g_ret_sts_error;
            write_debug_and_log (   'Unexpected Exception in '
                                 || g_pkg_name
                                 || l_procedure_name
                                );
            write_debug_and_log ('- Customer Id: ' || p_customer_id);
            write_debug_and_log ('- Customer Site Id: ' || p_site_use_id);
            write_debug_and_log (   '- Total Service charge: '
                                 || l_total_service_charge
                                );
            write_debug_and_log ('- Return Status: ' || l_return_status);
            write_debug_and_log (SQLERRM);
            fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
            fnd_message.set_token ('PROCEDURE',
                                   g_pkg_name || l_procedure_name);
            fnd_message.set_token ('ERROR', SQLERRM);
            fnd_message.set_token ('DEBUG_INFO', l_debug_info);
            fnd_msg_pub.ADD;
         END;
   END apply_service_charge;

   /*==============================================================
   | PROCEDURE  pay_multiple_invoices
   |
   | DESCRIPTION Used to make paymnets from iRec UI
   |
   | PARAMETERS  Lots
   |
   | KNOWN ISSUES
   |
   | NOTES
   | p_cc_bill_to_site_id value is sent as 0 when OIR_VERIFY_CREDIT_CARD_DETAILS profile is NONE or SECURITY_CODE for both New  Credit Cards
   | p_cc_bill_to_site_id value is sent as -1 when OIR_VERIFY_CREDIT_CARD_DETAILS is either BOTH or ADDRESS and for New Credit Card  Accounts
   | p_cc_bill_to_site_id value is sent as CC bill site id when OIR_VERIFY_CREDIT_CARD_DETAILS profile is either BOTH or ADDRESS for Saved Credit Cards
   |
   | MODIFICATION HISTORY
   | Date          Author       Description of Changes
   | 13-Jan-2003   krmenon      Created
   | 21-OCT-2004   vnb          Bug 3944029 - Modified pay_multiple_invoices to pass
   |                     correct site_use_id to other APIs
   | 03-NOV-2004   vnb          Bug 3335944 - One Time Credit Card Verification
   | 18-Oct-2005  rsinthre     Bug 4673563 - Error making credit card payment
   | 14-Mar-2013   melapaku     Bug 16471455 - Payment Audit History Feature
   | 14-Oct-2014   melapaku     Bug 19800178 - IRECEIVABLES LEADING ZERO REMOVED IN CVV CODE
   | 21-Jan-2015   gnramasa     Bug 20389172 - IRECEIVABLES CREDIT CARD PAYMENTS
   | 23-Jan-2015   gnramasa     Bug 20387436 - PAYMENTS - SWITCHING OU/CURRENCY AND MAKING 2ND PYMT CAUSES EXCHANGE RATE ERROR
   +==============================================================*/
   PROCEDURE pay_multiple_invoices (
      p_payment_amount        IN              NUMBER,
      p_discount_amount       IN              NUMBER,
      p_customer_id           IN              NUMBER,
      p_site_use_id           IN              NUMBER,
      p_account_number        IN              VARCHAR2,
      p_expiration_date       IN              DATE,
      p_account_holder_name   IN              VARCHAR2,
      p_account_type          IN              VARCHAR2,
      p_payment_instrument    IN              VARCHAR2,
      p_address_line1         IN              VARCHAR2 DEFAULT NULL,
      p_address_line2         IN              VARCHAR2 DEFAULT NULL,
      p_address_line3         IN              VARCHAR2 DEFAULT NULL,
      p_address_line4         IN              VARCHAR2 DEFAULT NULL,
      -- Added for Bug#14797865
      p_address_city          IN              VARCHAR2 DEFAULT NULL,
      p_address_county        IN              VARCHAR2 DEFAULT NULL,
      p_address_state         IN              VARCHAR2 DEFAULT NULL,
      p_address_country       IN              VARCHAR2 DEFAULT NULL,
      p_address_postalcode    IN              VARCHAR2 DEFAULT NULL,
      p_cvv2                  IN              VARCHAR2 default null,
      p_bank_branch_id        IN              NUMBER,
      p_receipt_date          IN              DATE DEFAULT TRUNC (SYSDATE),
      p_new_account_flag      IN              VARCHAR2 DEFAULT 'FALSE',
      p_receipt_site_id       IN              NUMBER,
      p_bank_id               IN              NUMBER,
      p_card_brand            IN              VARCHAR2,
      p_cc_bill_to_site_id    IN              NUMBER,
      p_single_use_flag       IN              VARCHAR2 DEFAULT 'N',
      p_iban                  IN              VARCHAR2,
      p_routing_number        IN              VARCHAR2,
      p_instr_assign_id       IN              NUMBER DEFAULT 0,
      p_payment_audit_id      IN              NUMBER,
      -- Added for Bug 16471455
      p_bank_account_id       IN OUT NOCOPY   NUMBER,
      p_cash_receipt_id       OUT NOCOPY      NUMBER,
      p_cc_auth_code          OUT NOCOPY      VARCHAR2,
      p_cc_auth_id            OUT NOCOPY      NUMBER,
      -- Added for Bug 16471455
      p_status                OUT NOCOPY      VARCHAR2,
      p_status_reason         OUT NOCOPY      VARCHAR2,
      -- Added for Bug 16471455
      x_msg_count             OUT NOCOPY      NUMBER,
      x_msg_data              OUT NOCOPY      VARCHAR2,
      --Added for R12 upgrade retrofit
      p_auth_code             IN              VARCHAR2,               -- E1294
      x_bep_code              OUT NOCOPY      VARCHAR2,
      -- Added for the Defect 2462(CR 247), for E1294
      p_bank_routing_number   IN              VARCHAR2 DEFAULT NULL,    --V2.0
      p_bank_account_name     IN              VARCHAR2 DEFAULT NULL,    --V2.0
      p_soa_receipt_number    OUT NOCOPY      VARCHAR2,                 --V2.0
      p_soa_msg               OUT NOCOPY      VARCHAR2  ,
      p_confirmemail          IN VARCHAR2
   )
   IS
-- =================================
-- DECLARE ALL LOCAL VARIABLES HERE
-- =================================
      l_receipt_currency_code        ar_cash_receipts_all.currency_code%TYPE;
      l_receipt_exchange_rate        ar_cash_receipts_all.exchange_rate%TYPE;
      l_receipt_exchange_rate_type   ar_cash_receipts_all.exchange_rate_type%TYPE;
      l_receipt_exchange_rate_date   DATE;
      l_invoice_exchange_rate        ar_payment_schedules_all.exchange_rate%TYPE;
      l_receipt_method_id            ar_cash_receipts_all.receipt_method_id%TYPE;
      l_remit_bank_account_id        ar_cash_receipts_all.remit_bank_acct_use_id%TYPE;
      l_receipt_creation_status      VARCHAR2 (80);
      l_site_use_id                  NUMBER (15);
      l_site_use_id_pay_instr        NUMBER (15);   -- Added for Bug#14556872
      l_bank_account_id              NUMBER;
      l_bank_account_uses_id         NUMBER;
      l_cvv2                         iby_fndcpt_tx_extensions.instrument_security_code%TYPE;
      l_invoice_trx_number           ar_payment_schedules_all.trx_number%TYPE;
      l_cr_id                        ar_cash_receipts_all.cash_receipt_id%TYPE;
      x_return_status                VARCHAR2 (100);
      l_msg_count                    NUMBER;
      x_auth_result                  iby_fndcpt_trxn_pub.authresult_rec_type;
      l_call_payment_processor       VARCHAR2 (1);
      l_response_error_code          VARCHAR2 (80);
      l_bank_branch_id               ce_bank_accounts.bank_branch_id%TYPE;
      l_apply_err_count              NUMBER;
      p_payment_schedule_id          NUMBER;
      l_create_credit_card           iby_fndcpt_setup_pub.creditcard_rec_type;
      l_result_rec_type              iby_fndcpt_common_pub.result_rec_type;
      l_procedure_name               VARCHAR2 (30);
      l_debug_info                   VARCHAR2 (200);
      l_payer_rec                    iby_fndcpt_common_pub.payercontext_rec_type;
      l_trxn_rec                     iby_fndcpt_trxn_pub.trxnextension_rec_type;
      l_payee_rec                    iby_fndcpt_trxn_pub.payeecontext_rec_type;
      l_result_rec                   iby_fndcpt_common_pub.result_rec_type;
      l_payment_channel_code         iby_fndcpt_pmt_chnnls_b.payment_channel_code%TYPE;
      l_cc_location_rec              hz_location_v2pub.location_rec_type;
      l_cc_bill_to_site_id           NUMBER;
      l_extn_id                      NUMBER;
      l_payer_party_id               NUMBER;
      l_payment_server_order_num     VARCHAR2 (80);
      l_instr_assign_id              NUMBER;
      l_cvv_use                      VARCHAR2 (100);
      l_billing_addr_use             VARCHAR2 (100);
      --Start - Added for R12 upgrade retrofit
      l_receipt_number               ar_cash_receipts_all.receipt_number%TYPE;
      l_attr6                        ar_cash_receipts_all.attribute1%TYPE;
      --CR868
      l_attr_category                ar_cash_receipts_all.attribute_category%TYPE;
      --CR868
      l_account_number               VARCHAR2 (300);                   --deep
      --V2.0, Added below variable
      l_attr1                        ar_cash_receipts_all.attribute1%TYPE;
      l_aatr_category                ar_cash_receipts_all.attribute_category%TYPE;
      ln_bank_cust_acct_num          NUMBER;
      lc_soa_msg_code                NUMBER;
      lc_soa_msg_text                VARCHAR2 (2000);
      l_msg_data                     VARCHAR (2000);
      l_auth_id                      NUMBER;        -- Added for Bug 16471455
      /* Added for Defect 35910*/
      l_log_enabled  FND_PROFILE_OPTION_VALUES.PROFILE_OPTION_VALUE%TYPE;
      l_log_module   FND_PROFILE_OPTION_VALUES.PROFILE_OPTION_VALUE%TYPE;
      l_log_level    FND_PROFILE_OPTION_VALUES.PROFILE_OPTION_VALUE%TYPE;
      l_card_brand                  VARCHAR2(256);
      --End - Added for R12 upgrade retrofit
      CURSOR party_id_cur
      IS
         SELECT party_id
           FROM hz_cust_accounts
          WHERE cust_account_id = p_customer_id;

      party_id_rec                   party_id_cur%ROWTYPE;
      p_site_use_id_srvc_chrg        NUMBER;
      l_home_country                 VARCHAR2 (10);
   BEGIN
      --Assign default values
	  dbms_output.put_line('--1--');
      l_receipt_currency_code := 'USD';
      l_call_payment_processor := fnd_api.g_true;
      l_apply_err_count := 0;
      x_msg_count := 0;
      x_msg_data := '';
      l_procedure_name := '.pay_multiple_invoices';
      --Added for R12 upgrade retrofit
      l_account_number := p_account_number;                       --deep V2.0
      gc_auth_code := p_auth_code;
      --Included for E1294 by Madankumar J, Wipro Technologies
      --End - Added for R12 upgrade retrofit
      fnd_log_repository.init;
--------------------------------------------------------------------
      l_debug_info := 'In debug mode, log we have entered this procedure';

--------------------------------------------------------------------
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Begin+'
                        );
         --Modified for Defect#34441
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'p_payment_amount '
                         || p_payment_amount
                         || 'p_discount_amount '
                         || p_discount_amount
                         || 'p_customer_id '
                         || p_customer_id
                         || 'p_site_use_id '
                         || p_site_use_id
                         || 'p_account_number '
                         || mask_account_number(p_account_number)
                         || 'p_expiration_date '
                         || p_expiration_date
                         || 'p_account_holder_name '
                         || p_account_holder_name
                         || 'p_account_type '
                         || p_account_type
                         || 'p_payment_instrument '
                         || p_payment_instrument
                         || 'p_bank_branch_id '
                         || p_bank_branch_id
                         || 'p_new_account_flag '
                         || p_new_account_flag
                         || 'p_receipt_date '
                         || p_receipt_date
                         || 'p_receipt_site_id '
                         || p_receipt_site_id
                         || 'p_bank_account_id '
                         || p_bank_account_id
                         || 'p_single_use_flag '
                         || p_single_use_flag
                         || 'p_cc_bill_to_site_id: '
                         || p_cc_bill_to_site_id
                         || 'p_address_line1: '
                         || p_address_line1
                         || 'p_address_line2: '
                         || p_address_line2
                         || 'p_address_line3 '
                         || p_address_line3
                         || 'p_address_line4 '
                         || p_address_line4
                         || 'p_address_city: '
                         || p_address_city
                         || 'p_address_country: '
                         || p_address_country
                         || 'l_account_number'
                         || mask_account_number(l_account_number)       --deep V2.0
                         || 'p_payment_audit_id: '
                         || p_payment_audit_id
                         ||'p_confirmemail'
                         ||p_confirmemail
                        );
      END IF;

      write_debug_and_log('org_id value is : ' || mo_global.get_current_org_id);
        IF mo_global.get_current_org_id is null then
            write_debug_and_log('Calling ARP_GLOBAL.INIT_GLOBAL without org_id as parameter');
            ARP_GLOBAL.INIT_GLOBAL;
       ELSE
          write_debug_and_log('Calling ARP_GLOBAL.INIT_GLOBAL with org_id :' || mo_global.get_current_org_id || ' as parameter');
         ARP_GLOBAL.INIT_GLOBAL(mo_global.get_current_org_id);
      END IF;
           write_debug_and_log('Functional currency is: ' || arp_global.functional_currency);
      -- IF Customer Site Use Id is -1 then it is to be set as null
      IF (p_site_use_id = -1)
      THEN
         -- Added for Bug#14556872
         l_site_use_id_pay_instr := NULL;

--Start commenting for bug 19190706 gnramasa 15th July 2014
-- Bug 12410542 when  system option - Require Billing location is enabled
-- then Primary Bill To Site Id is passed  while creating the Receipt
         --IF arp_global.sysparam.site_required_flag = 'Y'
         --THEN
         BEGIN
            SELECT site_use.site_use_id
              INTO l_site_use_id
              FROM hz_cust_site_uses site_use, hz_cust_acct_sites acct_site
             WHERE acct_site.cust_account_id = p_customer_id
               AND acct_site.status = 'A'
               AND site_use.cust_acct_site_id = acct_site.cust_acct_site_id
               AND site_use.site_use_code =
                                       NVL ('BILL_TO', site_use.site_use_code)
               AND site_use.status = 'A'
               AND site_use.primary_flag = 'Y';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_site_use_id := NULL;

               IF (pg_debug = 'Y')
               THEN
                  arp_standard.DEBUG ('No primary bill to site exists ');
               END IF;
         END;
          /* ELSE
              l_site_use_id := NULL;
           END IF;
      */
       --End commenting for bug 19190706 gnramasa 15th July 2014
      ELSE
         l_site_use_id := p_site_use_id;
         -- Added for Bug#14556872
         l_site_use_id_pay_instr := p_site_use_id;
      END IF;

-- Added for bug 9683510
      IF (    p_site_use_id IS NULL
          AND (p_receipt_site_id IS NOT NULL OR p_receipt_site_id <> -1)
         )
      THEN
         l_site_use_id := p_receipt_site_id;
      END IF;
-- Modified for bug 19800178
fnd_log.STRING
               (fnd_log.level_statement,
                g_pkg_name || l_procedure_name,
                'Red ... OD iRec Debug CVV ' || p_cvv2
               );
      IF p_cvv2 IS NULL OR p_payment_instrument = 'BANK_ACCOUNT' THEN
         l_cvv2 := NULL;

         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING
               (fnd_log.level_statement,
                g_pkg_name || l_procedure_name,
                'Since p_cvv2 is 0 or p_payment_instrument is BANK_ACCOUNT, setting l_cvv2 as null'
               );
         END IF;
      ELSE
         l_cvv2 := p_cvv2;

		 fnd_log.STRING
               (fnd_log.level_statement,
                g_pkg_name || l_procedure_name,
                'Red ... iRec Debug ' || l_cvv2 || ' - p_cvv2 = ' || p_cvv2
               );

         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING
               (fnd_log.level_statement,
                g_pkg_name || l_procedure_name,
                'Since p_cvv2 is not 0 and p_payment_instrument is not BANK_ACCOUNT, setting l_cvv2 as p_cvv2'
               );
         END IF;
      END IF;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Calling get_payment_information'
                        );
      END IF;

---------------------------------------------------------------------------
      l_debug_info :=
                    'Get the Payment Schedule Id if there is only one invoice';

---------------------------------------------------------------------------
      BEGIN
         SELECT payment_schedule_id
           INTO p_payment_schedule_id
           FROM ar_irec_payment_list_gt
          WHERE customer_id = p_customer_id
            AND customer_site_use_id =
                                     NVL (l_site_use_id, customer_site_use_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            IF (pg_debug = 'Y')
            THEN
               arp_standard.DEBUG
                                ('There may be multiple invoices for payment');
            END IF;
      END;
	  dbms_output.put_line('--3--');

---------------------------------------------------------------------------
      l_debug_info := 'Call get_payment_information';
---------------------------------------------------------------------------
      get_payment_information
                      (p_customer_id                  => p_customer_id,
                       p_site_use_id                  => l_site_use_id,
                       p_payment_schedule_id          => p_payment_schedule_id,
                       p_payment_instrument           => p_payment_instrument,
                       p_trx_date                     => TRUNC (p_receipt_date),
                       p_currency_code                => l_receipt_currency_code,
                       p_exchange_rate                => l_invoice_exchange_rate,
                       p_receipt_method_id            => l_receipt_method_id,
                       p_remit_bank_account_id        => l_remit_bank_account_id,
                       p_receipt_creation_status      => l_receipt_creation_status,
                       p_trx_number                   => l_invoice_trx_number,
                       p_payment_channel_code         => l_payment_channel_code
                      );
	  dbms_output.put_line('--4--');

      --DEBUG
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'l_rct_curr => ' || l_receipt_currency_code
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'l_rct_method_id => ' || l_receipt_method_id
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'l_remit_bank_account_id => '
                         || l_remit_bank_account_id
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'l_receipt_creation_status => '
                         || l_receipt_creation_status
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'l_site_use_id => ' || l_site_use_id
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'l_receipt_currency_code => '
                         || l_receipt_currency_code
                        );
      END IF;

      IF p_payment_instrument = 'CREDIT_CARD'
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Before p_payment_instrument = CREDIT_CARD'
                        );
		dbms_output.put_line('--5--');

         get_payment_channel_attribs
                                    (p_channel_code          => 'CREDIT_CARD',
                                     x_return_status         => x_return_status,
                                     x_cvv_use               => l_cvv_use,
                                     x_billing_addr_use      => l_billing_addr_use,
                                     x_msg_count             => x_msg_count,
                                     x_msg_data              => x_msg_data
                                    );
		 dbms_output.put_line('--5 a --x_return_status: ' || x_return_status);
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'After p_payment_instrument = CREDIT_CARD'
                         || x_msg_count
                        );

         IF (x_return_status <> fnd_api.g_ret_sts_success)
         THEN
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                           (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'ERROR IN GETTING IBY PAYMENT CHANNEL ATTRIBUTES'
                           );
            END IF;

            x_return_status := fnd_api.g_ret_sts_error;
            write_error_messages (x_msg_data, x_msg_count);
            RETURN;
         END IF;
      END IF;

      -- If the payment instrument is a bank account then
      -- set the bank branch id
      IF (p_payment_instrument = 'BANK_ACCOUNT')
      THEN
         l_bank_branch_id := p_bank_branch_id;
      ELSE
         l_bank_branch_id := NULL;
      END IF;

      fnd_log.STRING (fnd_log.level_statement,
                      g_pkg_name || l_procedure_name,
                      'l_bank_branch_id ' || l_bank_branch_id
                     );

      --KRMENON DEBUG
      IF (l_receipt_currency_code IS NULL OR '' = l_receipt_currency_code)
      THEN
--Bug2925392: Get Currency from AR_IREC_PAYMENT_LIST_GT. All records will have same currency.
--Bug # 3467287 - The Global Temp table must be striped by Customer and Customer Site.
---------------------------------------------------------------------------
         l_debug_info :=
                 'If the currency code is not set yet, get the currency code';

---------------------------------------------------------------------------
         BEGIN
            SELECT currency_code
              INTO l_receipt_currency_code
              FROM ar_irec_payment_list_gt
             WHERE customer_id = p_customer_id
               AND customer_site_use_id =
                                     NVL (l_site_use_id, customer_site_use_id);
         --group by currency_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               IF (pg_debug = 'Y')
               THEN
                  arp_standard.DEBUG ('Error getting currency code');
               END IF;
         END;
      END IF;

      SAVEPOINT ari_create_cash_pvt;

      OPEN party_id_cur;

      FETCH party_id_cur
       INTO party_id_rec;

      IF (party_id_cur%FOUND)
      THEN
         l_payer_party_id := party_id_rec.party_id;
      END IF;

      CLOSE party_id_cur;

      l_cc_bill_to_site_id := p_cc_bill_to_site_id;
      l_cc_location_rec.country := p_address_country;
      l_cc_location_rec.address1 := p_address_line1;
      l_cc_location_rec.address2 := p_address_line2;
      l_cc_location_rec.address3 := p_address_line3;
      l_cc_location_rec.address4 := p_address_line4;
      l_cc_location_rec.city := p_address_city;
      l_cc_location_rec.postal_code := p_address_postalcode;
      l_cc_location_rec.state := p_address_state;
      l_cc_location_rec.county := p_address_county;
      l_cc_location_rec.created_by_module := 'ARI';
      fnd_log.STRING (fnd_log.level_statement,
                      g_pkg_name || l_procedure_name,
                      'BEFORE calling create_cc_bill_to_site'
                     );
      fnd_log.STRING (fnd_log.level_statement,
                      g_pkg_name || l_procedure_name,
                         'p_cc_bill_to_site_id'
                      || p_cc_bill_to_site_id
                      || 'p_address_country'
                      || p_address_country
                      || 'p_address_line1'
                      || p_address_line1
                      || 'p_address_line2'
                      || p_address_line2
                      || 'p_address_line3'
                      || p_address_line3
                      || 'p_address_city'
                      || p_address_city
                      || 'p_address_postalcode'
                      || p_address_postalcode
                      || 'p_address_state'
                      || p_address_state
                      || 'p_address_county'
                      || p_address_county
                     );

      -- Bug#14797865 : Removed the condition if billing_addr_use is required
      /*
      IF (p_payment_instrument = 'CREDIT_CARD') AND l_cc_bill_to_site_id = -1
      THEN
         create_cc_bill_to_site
                               (p_init_msg_list           => fnd_api.g_false,
                                p_commit                  => fnd_api.g_false,
                                p_cc_location_rec         => l_cc_location_rec,
                                p_payer_party_id          => l_payer_party_id,
                                x_cc_bill_to_site_id      => l_cc_bill_to_site_id,
                                x_return_status           => x_return_status,
                                x_msg_count               => l_msg_count,
                                x_msg_data                => l_msg_data
                               );

         IF (x_return_status <> fnd_api.g_ret_sts_success)
         THEN
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'ERROR IN CREATING PAYMENT INSTRUMENT'
                              );
            END IF;

            p_status := fnd_api.g_ret_sts_error;
            ROLLBACK TO ari_create_cash_pvt;
            write_error_messages (x_msg_data, x_msg_count);
            RETURN;
         END IF;
      END IF;                                           --p_payment_instrument


      */
	  dbms_output.put_line('--6--p_new_account_flag:' || p_new_account_flag);
      IF (p_new_account_flag = 'TRUE')
      THEN
-- Now create a payment instrument
  ---------------------------------------------------------------------------
         l_debug_info := 'Create a payment instrument';
---------------------------------------------------------------------------
         	  dbms_output.put_line('--7--');
         --For Vantiv P2PE, as UI is not taking card type, we use the following call to get the card brand
         l_card_brand := GET_CREDIT_CARD_TYPE(p_account_number);

         fnd_log.STRING (fnd_log.level_statement,
                      g_pkg_name || l_procedure_name,
                      'BEFORE calling create_payment_instrument, l_card_brand: ' || l_card_brand
                     );
         create_payment_instrument
                             (p_customer_id              => p_customer_id,
                              p_customer_site_id         => l_site_use_id_pay_instr,
                              -- Modified for Bug#14556872
                              p_account_number           => p_account_number,
                              p_payer_party_id           => l_payer_party_id,
                              p_expiration_date          => p_expiration_date,
                              p_account_holder_name      => p_account_holder_name,
                              p_account_type             => p_account_type,
                              p_payment_instrument       => p_payment_instrument,
                              p_address_country          => p_address_country,
                              p_bank_branch_id           => p_bank_branch_id,
                              p_receipt_curr_code        => l_receipt_currency_code,
                              p_status                   => x_return_status,
                              x_msg_count                => l_msg_count,
                              x_msg_data                 => l_msg_data,
                              p_bank_id                  => p_bank_id,
                              p_card_brand               => l_card_brand,
                              p_cc_bill_to_site_id       => l_cc_bill_to_site_id,
                              p_single_use_flag          => 'N',
                              ---p_single_use_flag, Modified for Defect 29753
                              p_iban                     => p_iban,
                              p_routing_number           => p_routing_number,
                              p_assignment_id            => l_instr_assign_id,
                              p_bank_account_id          => l_bank_account_id
                             );
							 
              
         	  dbms_output.put_line('--7--');
      

         -- Check if the payment instrument was created successfully
         IF (x_return_status <> fnd_api.g_ret_sts_success)
         THEN
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'ERROR IN CREATING PAYMENT INSTRUMENT'
                              );
            END IF;

            p_status := fnd_api.g_ret_sts_error;
            write_error_messages (x_msg_data, x_msg_count);
            ROLLBACK TO ari_create_cash_pvt;
            RETURN;
         ELSE
            -- When payment instrument is created successfully
            IF (ari_utilities.save_payment_instrument_info (p_customer_id,
                                                            l_site_use_id
                                                           )
               )
            THEN
               -- If iRec set up is not to save CC then, if update of CC fails we should roll back even create.
               -- So here the commit flag is controlled by that profile
               IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level
                  )
               THEN
                  fnd_log.STRING
                        (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'ARI_UTILITIES.save_payment_instrument_info is true'
                        );
               END IF;

               COMMIT;
            END IF;
         END IF;
      ELSE
         /*Added for R12 upgrade retrofit */
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'IN ELSE part of ( p_new_account_flag = TRUE ) '
                        );

         /*--- Deep added for Prev bank account case */ -- V2.0
         IF (p_payment_instrument = 'BANK_ACCOUNT')
         THEN
            /*
            SELECT bank_account_num
              INTO l_account_number
              FROM ap_bank_accounts_all
             WHERE bank_account_id = p_bank_account_id;*/

            /*
            --Commented for Defect#27002
            SELECT cba.bank_account_num
                  INTO l_account_number
                  FROM ce_bank_accounts cba
                 WHERE cba.bank_account_id = p_bank_account_id;
             */
            SELECT bank_account_num
              INTO l_account_number
              FROM iby_ext_bank_accounts
             WHERE ext_bank_account_id = p_bank_account_id;


             --Modified for Defect#34441
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                               'Bank Account number Prev account'
                            || mask_account_number(l_account_number)
                           );
         END IF;

         /*End of Deep changes*/ -- V2.0
         /*End - Added for R12 upgrade retrofit */
         l_bank_account_id := p_bank_account_id;
         l_instr_assign_id := p_instr_assign_id;
      END IF;
      dbms_output.put_line('--7-- p_instr_assign_id: '|| p_instr_assign_id);
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Done with bank Creation .....'
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'Expiration date for bank account: '
                         || p_expiration_date
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Bank Acct Id: ' || l_bank_account_id
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Bank Acct Uses Id: ' || l_bank_account_uses_id
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Instr Assign ID: ' || l_instr_assign_id
                        );
      END IF;

-----------------------------------------------------------------------------------------
      l_debug_info := 'Call public IBY API - create TRANSACTION EXTENSION';
-----------------------------------------------------------------------------------------
      SAVEPOINT ari_create_trans_extn_pvt;

        /*Start- Added for R12 upgrade retrofit */
           --V2.0, Added below IF statement to update for VPD Policy, which will be applied when Lockbox runs
      --IF l_bank_account_uses_id IS NOT NULL AND p_payment_instrument = 'BANK_ACCOUNT' THEN
      IF     l_instr_assign_id IS NOT NULL
         AND p_payment_instrument = 'BANK_ACCOUNT'
      THEN
         /*
         UPDATE ap_bank_account_uses_all
            SET attribute_category   = 'ACH'
              , attribute1           = 'ACH'
             , attribute2           = p_bank_account_name
              , attribute3           = p_account_type
          WHERE bank_account_uses_id = l_bank_account_uses_id;
          */
         UPDATE iby_pmt_instr_uses_all
            SET attribute_category = 'ACH',
                attribute1 = 'ACH',
                attribute2 = p_bank_account_name,
                attribute3 = p_account_type,
                attribute4= p_confirmemail
          WHERE instrument_payment_use_id = l_instr_assign_id;
      END IF;
      	  dbms_output.put_line('--9--');

      --V2.0, above IF statement ends here

      /*End - Added for R12 upgrade retrofit */
      l_payer_rec.payment_function := 'CUSTOMER_PAYMENT';
      l_payer_rec.cust_account_id := p_customer_id;
      l_payer_rec.account_site_id := l_site_use_id;
      l_payer_rec.party_id := l_payer_party_id;

      IF l_site_use_id IS NOT NULL
      THEN
         l_payer_rec.org_type := 'OPERATING_UNIT';
         l_payer_rec.org_id := mo_global.get_current_org_id;
      ELSE
         l_payer_rec.org_type := NULL;
         l_payer_rec.org_id := NULL;
      END IF;

      l_payee_rec.org_type := 'OPERATING_UNIT';
      l_payee_rec.org_id := mo_global.get_current_org_id;

      SELECT 'ARI_' || ar_payment_server_ord_num_s.NEXTVAL
        INTO l_payment_server_order_num
        FROM DUAL;

      l_trxn_rec.originating_application_id := 222;
      l_trxn_rec.order_id := l_payment_server_order_num;
      l_trxn_rec.instrument_security_code := l_cvv2;
      -- Debug message
      write_debug_and_log ('l_payment_channel_code' || l_payment_channel_code);
      write_debug_and_log ('l_instr_assign_id' || l_instr_assign_id);
      write_debug_and_log (   'l_payment_server_order_num'
                           || l_payment_server_order_num
                          );

       dbms_output.put_line('--10-- l_payment_channel_code:' || l_payment_channel_code || ', l_instr_assign_id:' || l_instr_assign_id);
      iby_fndcpt_trxn_pub.create_transaction_extension
                                     (p_api_version           => 1.0,
                                      p_init_msg_list         => fnd_api.g_true,
                                      --    p_commit    => FND_API.G_FALSE, -- bug 9683510
                                      x_return_status         => x_return_status,
                                      x_msg_count             => l_msg_count,
                                      x_msg_data              => l_msg_data,
                                      p_payer                 => l_payer_rec,
                                      p_pmt_channel           => l_payment_channel_code,
                                      p_instr_assignment      => l_instr_assign_id,
                                      p_trxn_attribs          => l_trxn_rec,
                                      x_entity_id             => l_extn_id,
                                      x_response              => l_result_rec
                                     );
									   ---Changes done by Divyansh
       dbms_output.put_line('--10 a --' || x_return_status);
       dbms_output.put_line('--10 b --' || l_msg_data);
--		x_return_status := fnd_api.g_ret_sts_success;---Changes done by Divyansh
      IF (x_return_status <> fnd_api.g_ret_sts_success)
      THEN
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'ERROR IN CREATING TRANSACTION EXTENSION'
                           );
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            l_result_rec.result_code
                           );
         END IF;

         x_msg_count := x_msg_count + l_msg_count;

         IF (l_msg_data IS NOT NULL)
         THEN
            x_msg_data := x_msg_data || l_msg_data || '*';
         END IF;

         x_msg_data := x_msg_data || '*' || l_result_rec.result_code;
         p_status := fnd_api.g_ret_sts_error;
         ROLLBACK TO ari_create_trans_extn_pvt;
         write_error_messages (x_msg_data, x_msg_count);
         RETURN;
      END IF;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Done with create trxn extn.....'
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'l_extn_id : ' || l_extn_id
                        );
      END IF;

      write_debug_and_log (   'l_receipt_currency_code : '
                           || l_receipt_currency_code
                          );
      write_debug_and_log (   'l_invoice_exchange_rate : '
                           || TO_CHAR (l_invoice_exchange_rate)
                          );
      write_debug_and_log ('l_extn_id : ' || l_extn_id);
---------------------------------------------------------------------------
      l_debug_info := 'Call get_exchange_rate';
---------------------------------------------------------------------------
      get_exchange_rate (p_trx_currency_code           => l_receipt_currency_code,
                         p_trx_exchange_rate           => l_invoice_exchange_rate,
                         p_def_exchange_rate_date      => TRUNC (SYSDATE),
                         p_exchange_rate               => l_receipt_exchange_rate,
                         p_exchange_rate_type          => l_receipt_exchange_rate_type,
                         p_exchange_rate_date          => l_receipt_exchange_rate_date
                        );

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Done with getexchangerate.....'
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'l_receipt_currency_code : '
                         || l_receipt_currency_code
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'l_receipt_exchange_rate : '
                         || TO_CHAR (l_invoice_exchange_rate)
                        );
      END IF;

      -- for demo purposes only: if fnd function ARIPAYMENTDEMOMODE
      -- is added to the menu of the current responsibility, supress
      -- call to iPayment after the receipt creation.

      /*------------------------------------------------------+
       | For credit cards iPayment is called to authorize and |
       | capture the payment. For bank account transfers      |
       | iPayment is called in receivables remittance process |
       +------------------------------------------------------*/
      IF (   fnd_function.TEST ('ARIPAYMENTDEMOMODE')
          OR p_payment_instrument = 'BANK_ACCOUNT'
         )
      THEN                               /* J Rautiainen ACH Implementation */
         l_call_payment_processor := fnd_api.g_false;
      ELSE
         l_call_payment_processor := fnd_api.g_true;
      END IF;

-- commented for bug 9683510
/*  IF (p_receipt_site_id <> -1) THEN
    l_site_use_id := p_receipt_site_id;
  END IF;  */

      /*Added for R12 upgrade retrofit*/
      --V2.0, Added below IF ELSE Statement
      IF p_payment_instrument = 'BANK_ACCOUNT'
      THEN
         l_attr_category := 'SALES_ACCT';
         l_attr1 := p_bank_account_name;
      ELSE
         l_attr_category := NULL;
         l_attr1 := NULL;
         l_receipt_number := NULL;
      END IF;

      --V2.0, above IF ELSE Statement ends here

      /*End - Added for R12 upgrade retrofit*/

      -- Now create a cash receipt
---------------------------------------------------------------------------
      l_debug_info := 'Create a cash receipt: Call create_receipt';
---------------------------------------------------------------------------
/*------------------------------------+
 | Standard start of API savepoint    |
 +------------------------------------*/
      SAVEPOINT ari_create_receipt_pvt;              -- added for bug 11654712

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'calling  create_receipt api ....'
                        );
      END IF;

      /*Start -Modified for R12 upgrade retrofit*/
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING
                     (fnd_log.level_statement,
                      g_pkg_name || l_procedure_name,
                         'before calling - paramters create_receipt api ....'
                      || 'p_payment_amount              '
                      || p_payment_amount
                      || 'p_customer_id                 '
                      || p_customer_id
                      || 'l_site_use_id                 '
                      || l_site_use_id
                      || 'l_bank_account_id             '
                      || l_bank_account_id
                      || 'p_receipt_date                '
                      || p_receipt_date
                      || 'l_receipt_method_id           '
                      || l_receipt_method_id
                      || 'l_receipt_currency_code       '
                      || l_receipt_currency_code
                      || 'l_receipt_exchange_rate       '
                      || l_receipt_exchange_rate
                      || 'l_receipt_exchange_rate_type  '
                      || l_receipt_exchange_rate_type
                      || 'l_receipt_exchange_rate_date  '
                      || l_receipt_exchange_rate_date
                      || 'l_extn_id                     '
                      || l_extn_id
                      || 'p_cash_receipt_id             '
                      || p_cash_receipt_id
                      || 'x_return_status               '
                      || x_return_status
                      || 'l_attr1                       '
                      || l_attr1
                      || 'l_attr_category               '
                      || l_attr_category
                      || 'l_msg_count                   '
                      || l_msg_count
                      || 'x_msg_data                    '
                      || l_msg_data
                     );
      END IF;
      dbms_output.put_line('--11--');
      create_receipt
                (p_payment_amount                  => p_payment_amount,
                 p_customer_id                     => p_customer_id,
                 p_site_use_id                     => l_site_use_id,
                 p_bank_account_id                 => l_bank_account_id,
                 p_receipt_date                    => TRUNC (p_receipt_date),
                 p_receipt_method_id               => l_receipt_method_id,
                 p_receipt_currency_code           => l_receipt_currency_code,
                 p_receipt_exchange_rate           => l_receipt_exchange_rate,
                 p_receipt_exchange_rate_type      => l_receipt_exchange_rate_type,
                 p_receipt_exchange_rate_date      => l_receipt_exchange_rate_date,
                 p_trxn_extn_id                    => l_extn_id,
                 p_cash_receipt_id                 => p_cash_receipt_id,
                 p_status                          => x_return_status,
                 x_msg_count                       => l_msg_count,
                 x_msg_data                        => l_msg_data,
                 p_attr1                           => l_attr1,
                 --Added as part of R12 upgrade retrofit
                 p_attr_category                   => l_attr_category,
                 p_confirmemail                    => p_confirmemail
                --Added as part of R12 upgrade retrofit
                );

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING
                      (fnd_log.level_statement,
                       g_pkg_name || l_procedure_name,
                          'after calling - paramters create_receipt api ....'
                       || 'p_cash_receipt_id             '
                       || p_cash_receipt_id
                       || 'x_return_status               '
                       || x_return_status
                       || 'l_msg_count                   '
                       || l_msg_count
                       || 'x_msg_data                    '
                       || l_msg_data
                      );
      END IF;

/*End -Modified for R12 upgrade retrofit*/
      arp_standard.DEBUG (   'create receipt -->  '
                          || x_return_status
                          || 'receipt id --> '
                          || p_cash_receipt_id
                         );
      arp_standard.DEBUG ('X_RETURN_STATUS=>' || x_return_status);

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Done with receipt creation ....'
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Return Status: ' || x_return_status
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Cash Receipt Id: ' || TO_CHAR (p_cash_receipt_id)
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Bank Account Id: ' || TO_CHAR (p_bank_account_id)
                        );
      END IF;

      -- Check for error in receipt creation. If it is an error
      -- the rollback and return.
      IF (   x_return_status <> fnd_api.g_ret_sts_success
          OR p_cash_receipt_id IS NULL
         )
      THEN
         --Bug 3672530 - Error handling
         p_status := fnd_api.g_ret_sts_error;
         p_status_reason := g_creation_failed;
         ROLLBACK TO ari_create_receipt_pvt;
         write_error_messages (x_msg_data, x_msg_count);
         RETURN;
      END IF;

      p_site_use_id_srvc_chrg := l_site_use_id;

-- commented for bug 9683510
/*  IF (p_receipt_site_id <> -1) THEN
    p_site_use_id_srvc_chrg := p_receipt_site_id;
  END IF; */

      -- If service charge has been enabled, adjust the invoice
      -- with the service charge
      -- Bug 3886652 - Customer Id and Customer Site Use Id added as params to ARI_CONFIG.is_service_charge_enabled
      IF (ari_utilities.is_service_charge_enabled (p_customer_id,
                                                   p_site_use_id_srvc_chrg
                                                  )
         )
      THEN
---------------------------------------------------------------------------------
         l_debug_info :=
             'Service charge enabled: adjust the invoice with service charge';
---------------------------------------------------------------------------------
         apply_service_charge (p_customer_id, NULL, x_return_status);

         -- Bug 9596552
         IF (x_return_status <> fnd_api.g_ret_sts_success)
         THEN
            --Bug 3672530 - Error handling
            p_status := fnd_api.g_ret_sts_error;
            ROLLBACK TO ari_create_receipt_pvt;
            write_error_messages (x_msg_data, x_msg_count);
            RETURN;
         END IF;
      END IF;

   --Bug 8239939 , 6026781: All locations project. Reset the site_use_id to actual value
 --when navigating from All Locations or My All Locations
-- commented for bug 9683510
/*  IF (p_receipt_site_id <> -1) THEN
    l_site_use_id := p_site_use_id;
  END IF; */

      -- If the cash receipt has been created successfully then
-- apply the receipt to the transactions selected
---------------------------------------------------------------------------------
      l_debug_info :=
              'Apply the receipt to the transactions selected:call apply_cash';
---------------------------------------------------------------------------------
      apply_cash (p_customer_id          => p_customer_id,
                  p_site_use_id          => p_site_use_id,
-- Modified for Bug#14646910, we don't require l_site_use_id to be passed while applying the receipt to the transactions
                  p_cash_receipt_id      => p_cash_receipt_id,
                  p_return_status        => x_return_status,
                  p_apply_err_count      => l_apply_err_count,
                  x_msg_count            => l_msg_count,
                  x_msg_data             => l_msg_data
                 );

      -- Check if any of the applications errored out
      -- If so the rollback everything and return
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'Apply Cash call ended with Status : '
                         || x_return_status
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'l_apply_err_count : ' || l_apply_err_count
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'x_msg_data : ' || x_msg_data
                        );
      END IF;

      IF (x_return_status <> fnd_api.g_ret_sts_success)
      THEN
         p_status := fnd_api.g_ret_sts_error;
         p_status_reason := g_app_failed;           -- Added for Bug 16471455
         ROLLBACK TO ari_create_receipt_pvt;

         IF (l_apply_err_count > 0)
         THEN
            x_msg_count := x_msg_count + l_msg_count;
         END IF;

         IF (l_msg_data IS NOT NULL)
         THEN
            x_msg_data := x_msg_data || l_msg_data || '*';
         END IF;

         --p_status := fnd_api.g_ret_sts_error;
         --ROLLBACK TO ari_create_receipt_pvt;
         write_error_messages (x_msg_data, x_msg_count);
         RETURN;
      END IF;

      -- Seems like all is fine. So we shall go ahead and
      -- do the final task of capturing the CC payment
      -- only if it is a credit card payment
      IF (    p_payment_instrument = 'CREDIT_CARD'
          AND l_call_payment_processor = fnd_api.g_true
         )
      THEN
         BEGIN
            SELECT pr.home_country
              INTO l_home_country
              FROM ar_cash_receipts_all cr,
                   ce_bank_acct_uses bau,
                   ce_bank_accounts cba,
                   hz_parties bank,
                   hz_organization_profiles pr
             WHERE cr.cash_receipt_id = p_cash_receipt_id
               AND cr.remit_bank_acct_use_id = bau.bank_acct_use_id
               AND bau.bank_account_id = cba.bank_account_id
               AND cba.bank_id = bank.party_id
               AND bank.party_id = pr.party_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               IF (pg_debug = 'Y')
               THEN
                  arp_standard.DEBUG ('Error getting Home Country Code..');
                  l_home_country := NULL;
               END IF;
         END;

         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'Got home country code..' || l_home_country
                           );
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'Calling process_payment .....'
                           );
         END IF;

         l_payee_rec.int_bank_country_code := l_home_country;
--------------------------------------------------------------------
         l_debug_info := 'Capture Credit Card payment';

--------------------------------------------------------------------

         /* Start - Added for R12 upgrade retrofit */
         --Added for I0349
         BEGIN
            SELECT trx_number
              INTO gc_trx_number
              FROM ar_irec_payment_gt_all            --ar_irec_payment_list_gt
             WHERE customer_id = p_customer_id
               AND customer_site_use_id =
                                     NVL (l_site_use_id, customer_site_use_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         /* End- Added for R12 upgrade retrofit */
         dbms_output.put_line('--12--');
         --Modified for R12 upgrade retrofit
             --Added for I0349
         process_payment (p_cash_receipt_id          => p_cash_receipt_id,
                          p_payer_rec                => l_payer_rec,
                          p_payee_rec                => l_payee_rec,
                          p_called_from              => 'IREC',
                          p_response_error_code      => l_response_error_code,
                          x_msg_count                => l_msg_count,
                          x_msg_data                 => l_msg_data,
                          x_return_status            => x_return_status,
                          p_cc_auth_code             => p_cc_auth_code,
                          x_auth_result              => x_auth_result,
                          x_bep_code                 => x_bep_code
                         -- Added for the Defect 2462(CR 247), for E1294
                         );
						 
						      --- Commented by Divyansh
         l_auth_id := x_auth_result.auth_id;  ---Changes done by Divyansh
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'XXOD: Process Payment : p_cc_auth_code'
                         || p_cc_auth_code
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'XXOD: Process Payment : l_response_error_code'
                         || l_response_error_code
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'XXOD: Process Payment : l_msg_count' || l_msg_count
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'XXOD: Process Payment : l_msg_data' || l_msg_data
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'XXOD: Process Payment : x_return_status'
                         || x_return_status
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'XXOD: Process Payment : x_bep_code' || x_bep_code
                        );
         x_msg_count := x_msg_count + l_msg_count;

         IF (l_msg_data IS NOT NULL)
         THEN
/*Bug 6523108 - Show only iPayments error messages if there is an iPayments error and
 * hide other error messages
 */ --    x_msg_data  := x_msg_data || l_msg_data || '*';
            x_msg_data := l_msg_data || '*';
         END IF;

         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                               'Process Payment ended with Status : '
                            || x_return_status
                           );
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'Response Code: ' || l_response_error_code
                           );
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'l_auth_id: ' || l_auth_id
                           );
         END IF;

         -- If the payment processor call fails, then we need to rollback all the changes
         -- made in the create() and apply() routines also.
         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            --Bug 3672530 - Error handling
            p_status := fnd_api.g_ret_sts_error;
            --ROLLBACK TO ari_create_bank_account_pvt;
            ROLLBACK;
/*Bug 6523108 - Show only iPayments error messages if there is an iPayments error and
 * hide other error messages.
 * Commented the call to write_error_messages as it prints all the error messages added to FND_MSG_PUB
 */--   write_error_messages(x_msg_data, x_msg_count);
            RETURN;                                    -- exit back to caller
         END IF;
       /*
       --Modified for R12 upgrade retrofit
                  --Added for I0349
				  dbms_output.put_line('--13--');
                  process_payment(p_cash_receipt_id          => p_cash_receipt_id,
                                  p_payer_rec                => l_payer_rec,
                                  p_payee_rec                => l_payee_rec,
                                  p_called_from              => 'IREC',
                                  p_response_error_code      => l_response_error_code,
                                  x_msg_count                => l_msg_count,
                                  x_msg_data                 => l_msg_data,
                                  x_return_status            => x_return_status,
                                  p_cc_auth_code             => p_cc_auth_code,
                                  x_bep_code                 => x_bep_code
                                                                          -- Added for the Defect 2462(CR 247), for E1294
                                 );
                  dbms_output.put_line('--14--');
                  IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                  THEN
                      fnd_log.STRING(fnd_log.level_statement,
                                        g_pkg_name
                                     || l_procedure_name,
                                        'Process Payment ended with Status : '
                                     || x_return_status);
                      fnd_log.STRING(fnd_log.level_statement,
                                        g_pkg_name
                                     || l_procedure_name,
                                        'Response Code: '
                                     || l_response_error_code);
                  END IF;

                  -- If the payment processor call fails, then we need to rollback all the changes
                  -- made in the create() and apply() routines also.
                  IF x_return_status <> fnd_api.g_ret_sts_success
                  THEN
                      x_msg_count :=   x_msg_count
                                     + l_msg_count;

                      IF (l_msg_data IS NOT NULL)
                      THEN
                          x_msg_data :=    x_msg_data
                                        || l_msg_data
                                        || '*';
                      END IF;

                             --   x_msg_data := x_msg_data || '*' || l_result_rec.result_code;  --  bug 8353477
                      --Bug 3672530 - Error handling
                      p_status := fnd_api.g_ret_sts_error;
                      -- ROLLBACK TO ari_create_cash_pvt;
                      // commented for R12 upgrade - as wa resulting
                      // ORA-01086: savepoint 'ARI_CREATE_CASH_PVT' never established in this session or is invalid
                      ROLLBACK;
                      write_error_messages(x_msg_data,
                                           x_msg_count);
                      RETURN;                                                                           -- exit back to caller
                  END IF;
      */      /* Start - Added for R12 upgrade retrofit */
              -- V2.0, Added below ELSE Statement for SOA Call
      ELSE
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'In else part to call SOA  :: '
                        );

         BEGIN
            SELECT account_number
              INTO ln_bank_cust_acct_num
              FROM hz_cust_accounts
             WHERE cust_account_id = p_customer_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               ln_bank_cust_acct_num := NULL;
         END;

         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'Before SOA CALL  ln_bank_cust_acct_num : '
                         || ln_bank_cust_acct_num
                        );

         BEGIN
		    dbms_output.put_line('--15--');
            xx_od_irec_receipts_attach_pkg.call_ach_epay_webservice
                            (p_businessid                   => 0,
                             p_login                        => NULL,
                             p_password                     => NULL,
                             p_product                      => fnd_global.resp_name,
                             --'OD (US) iReceivables'
                             p_bankaccounttype              => p_account_type,
                             --'BUSINESS CHECKING'
                             p_routingnumber                => p_bank_routing_number,
                             p_bankaccountnumber            => l_account_number,
                             p_accountholdername            => p_bank_account_name,
                             p_accountaddress1              => NULL,
                             p_accountaddress2              => NULL,
                             p_accountcity                  => NULL,
                             p_accountstate                 => NULL,
                             p_accountpostalcode            => NULL,
                             p_accountcountrycode           => NULL,
                             p_nachastandardentryclass      => NULL,   --'CCD'
                             p_individualidentifier         => NULL,
                             p_companyname                  => NULL,
                             p_creditdebitindicator         => 'DEBIT',
                             p_requestedpaymentdate         => TO_CHAR
                                                                  (SYSDATE,
                                                                   'YYYY-MM-DD'
                                                                  ),
                             --'2012-12-14'
                             p_billingaccountnumber         => p_customer_id,
                             p_remitamount                  => p_payment_amount,
                             p_remitfee                     => '0',
                             p_feewaiverreason              => NULL,
                             p_transactioncode              => NULL,
                             p_emailaddress                 => fnd_global.user_id,
                             p_remitfieldvalue              => NULL,
                             p_messagecode                  => lc_soa_msg_code,
                             p_messagetext                  => lc_soa_msg_text,
                             p_confirmation_number          => p_soa_receipt_number,
                             p_status                       => p_status
                            );
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                                  'After SOA CALL  exception when others : '
                               || SQLERRM
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               'After SOA CALL  p_status : ' || p_status
                              );
         END;

         IF p_soa_receipt_number IS NOT NULL AND p_status = 'S'
         THEN
            p_status := fnd_api.g_ret_sts_success;

            UPDATE ar_cash_receipts_all
               SET customer_receipt_reference = p_soa_receipt_number
             WHERE cash_receipt_id = p_cash_receipt_id;
         ELSE
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'After SOA CALL  p_status : ' || p_status
                           );                                           --V2.0
            p_status := fnd_api.g_ret_sts_error;
            p_soa_receipt_number := NULL;

            -- p_soa_msg := lc_soa_msg_code || ' - '|| lc_soa_msg_text; -- commented and added below line V2.0
            IF lc_soa_msg_code IS NULL
            THEN
               p_soa_msg :=
                  'We apologize but the system is temporarily unavailable. Please try again later.';
            ELSE
               p_soa_msg := lc_soa_msg_code || ' - ' || lc_soa_msg_text;
            END IF;
            -- Send Email to AMS Team
            xx_ar_irec_token_err_email_pkg.raise_business_event('xx_od_irec_receipts_attach_pkg.call_ach_epay_webservice'
                                                           ,'Error :'||p_soa_msg|| UTL_TCP.crlf|| UTL_TCP.crlf||'URL used :'||fnd_profile.VALUE ('XX_OD_IREC_URL')
                                                           ,p_customer_id
                                                             );
               /* Insert into Fnd_log_messages Independent of FND_DEBUG_LOG PROFILE OPTION*/
               l_log_enabled:=fnd_profile.value('AFLOG_ENABLED');
                if ( l_log_enabled='Y')
                 then
                  fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, substr('Exception in call to XX_OD_IREC_RECEIPTS_ATTACH_PKG.CALL_ACH_EPAY_WEBSERVICE :'|| UTL_TCP.crlf||p_soa_msg|| UTL_TCP.crlf|| UTL_TCP.crlf||'URL used :'||fnd_profile.VALUE ('XX_OD_IREC_URL'),1,2999)  );
                else
                 l_log_module:=fnd_profile.value('AFLOG_MODULE');
                 l_log_level :=fnd_profile.value('AFLOG_LEVEL');
                  set_tmp_debug_flag ( 'Y','%','1');
                   fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, substr('Exception in call to XX_OD_IREC_RECEIPTS_ATTACH_PKG.CALL_ACH_EPAY_WEBSERVICE :'|| UTL_TCP.crlf|| p_soa_msg|| UTL_TCP.crlf|| UTL_TCP.crlf||'URL used :'||fnd_profile.VALUE ('XX_OD_IREC_URL'),1,2999) );
                  set_tmp_debug_flag ( l_log_enabled,l_log_module,l_log_level);
                end if;


            fnd_log.STRING (fnd_log.level_statement,g_pkg_name || l_procedure_name,'ROLLBACK TO ari_create_cash_pvt;'
                           );
            --ROLLBACK TO ari_create_cash_pvt; -- commented because getting savepoint ARI_CREATE_CASH_PVT never established
            ROLLBACK;                                       --For Defect 30662

            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'ROLLBACK TO ari_create_cash_pvt completed'
                           );
            RETURN;                                     -- exit back to caller
         END IF;

         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'End --- After SOA CALL  p_status : ' || p_status
                        );
      --V2.0, ELSE part ends here
      /* End - Added for R12 upgrade retrofit */
      END IF;                                      -- END PROCESS_PAYMENT CALL

      -- Now that we have successfully captured the payment
      -- erase the CC info if setup says not to store this
      -- info
      -- Bug 3886652 - Customer and Customer Site added to ARI_CONFIG APIs
      --               to add flexibility in configuration.
      IF NOT (ari_utilities.save_payment_instrument_info (p_customer_id,
                                                          p_site_use_id
                                                         )
             )
      THEN
---------------------------------------------------------------------------------------------------------
         l_debug_info :=
            'Payment instrument information not to be stored, erase the CC information after payment';
---------------------------------------------------------------------------------------------------------

         /* E1294 - Added for Creditcard Encryption functionality */
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'E1294 Encryption functionality start'
                        );
         DBMS_SESSION.set_context (namespace      => 'XX_AR_IREC_CONTEXT',
                                   ATTRIBUTE      => 'TYPE',
                                   VALUE          => 'EBS'
                                  );
         --Modified for Defect#34441
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'l_account_number ::' || mask_account_number(l_account_number)
                        );
         xx_od_security_key_pkg.encrypt_outlabel
                              (p_module             => 'AJB',
                               p_key_label          => NULL,
                               p_algorithm          => '3DES',
                               p_decrypted_val      => l_account_number,
                               x_encrypted_val      => gc_encrypted_cc_num,
                               x_error_message      => gc_cc_encrypt_error_message,
                               x_key_label          => gc_key_label
                              );
         fnd_log.STRING
            (fnd_log.level_statement,
             g_pkg_name || l_procedure_name,
                'E1294 xx_od_security_key_pkg.encrypt_outlabel error message:'
             || gc_cc_encrypt_error_message
            );

         IF gc_cc_encrypt_error_message IS NOT NULL
         THEN
            x_msg_data := gc_cc_encrypt_error_message;
            p_status := fnd_api.g_ret_sts_error;
            ROLLBACK TO ari_create_receipt_pvt;
            RETURN;
         END IF;

         /* E1294 - End - Added for Creditcard Encryption functionality */
         l_create_credit_card.card_id := l_bank_account_id;
         l_create_credit_card.active_flag := 'N';
         l_create_credit_card.inactive_date := TRUNC (SYSDATE - 1);
         l_create_credit_card.single_use_flag := 'Y';
         /* E1294 - Start - Added for Creditcard Encryption functionality */
        -- l_create_credit_card.attribute4 := gc_encrypted_cc_num;  /* Commented for Defect 35918 */
         l_create_credit_card.attribute5 := gc_key_label;


         /* E1294 - End - Added for Creditcard Encryption functionality */
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
         THEN
            fnd_log.STRING
                    (fnd_log.level_statement,
                     g_pkg_name || l_procedure_name,
                     'Before Calling  IBY_FNDCPT_SETUP_PUB.Update_Card .....'
                    );
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                               'l_create_credit_card.Card_Id : '
                            || l_create_credit_card.card_id
                           );
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                               'l_create_credit_card.Active_Flag : '
                            || l_create_credit_card.active_flag
                           );
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                               'l_create_credit_card.single_use_flag : '
                            || l_create_credit_card.single_use_flag
                           );
         END IF;
         dbms_output.put_line('--16--');
         iby_fndcpt_setup_pub.update_card
                                   (p_api_version          => 1.0,
                                    p_init_msg_list        => fnd_api.g_true,
                                    p_commit               => fnd_api.g_false,
                                    x_return_status        => x_return_status,
                                    x_msg_count            => l_msg_count,
                                    x_msg_data             => l_msg_data,
                                    p_card_instrument      => l_create_credit_card,
                                    x_response             => l_result_rec_type
                                   );

         IF (x_return_status <> fnd_api.g_ret_sts_success)
         THEN
            p_status := fnd_api.g_ret_sts_error;
            x_msg_count := x_msg_count + l_msg_count;

            IF (l_msg_data IS NOT NULL)
            THEN
               x_msg_data := x_msg_data || l_msg_data || '*';
            END IF;

            x_msg_data := x_msg_data || '*' || l_result_rec.result_code;
            ROLLBACK TO ari_create_receipt_pvt;
            write_error_messages (x_msg_data, x_msg_count);
            RETURN;
         END IF;
      ELSE
         IF (p_payment_instrument = 'CREDIT_CARD')
         THEN
            /* E1294 - Added for Creditcard Encryption functionality */
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'E1294 Encryption functionality start'
                           );
            DBMS_SESSION.set_context (namespace      => 'XX_AR_IREC_CONTEXT',
                                      ATTRIBUTE      => 'TYPE',
                                      VALUE          => 'EBS'
                                     );

            --Modified for Defect#34441
            fnd_log.STRING (fnd_log.level_statement,
                            g_pkg_name || l_procedure_name,
                            'l_account_number ::' || mask_account_number(l_account_number)
                           );
            xx_od_security_key_pkg.encrypt_outlabel
                              (p_module             => 'AJB',
                               p_key_label          => NULL,
                               p_algorithm          => '3DES',
                               p_decrypted_val      => l_account_number,
                               x_encrypted_val      => gc_encrypted_cc_num,
                               x_error_message      => gc_cc_encrypt_error_message,
                               x_key_label          => gc_key_label
                              );
            fnd_log.STRING
               (fnd_log.level_statement,
                g_pkg_name || l_procedure_name,
                   'E1294 xx_od_security_key_pkg.encrypt_outlabel error message:'
                || gc_cc_encrypt_error_message
               );

            IF gc_cc_encrypt_error_message IS NOT NULL
            THEN
               x_msg_data := gc_cc_encrypt_error_message;
               p_status := fnd_api.g_ret_sts_error;
               ROLLBACK TO ari_create_cash_pvt;
               RETURN;
            END IF;

            /* E1294 - End - Added for Creditcard Encryption functionality */
            l_create_credit_card.card_id := l_bank_account_id;
            l_create_credit_card.single_use_flag := p_single_use_flag;
            l_create_credit_card.active_flag := 'Y';

            -- Added for Bug 17625348 -- Added as per defect 29753
            IF (p_single_use_flag = 'Y')
            THEN
               l_create_credit_card.active_flag := NULL;
               --'N';  -- Changed to NULL as per defect 29753
               l_create_credit_card.inactive_date := TRUNC (SYSDATE - 1);
            -- Added for Bug#14798065
            END IF;

            l_create_credit_card.card_holder_name := p_account_holder_name;

            -- Bug#14797865 : Removed the condition if billing_addr_use is required
            IF (l_cc_bill_to_site_id <> 0 AND l_cc_bill_to_site_id <> -1)
            THEN
               l_create_credit_card.billing_address_id :=
                                                         l_cc_bill_to_site_id;
            END IF;

            /* E1294 - Start - Added for Creditcard Encryption functionality */
           -- l_create_credit_card.attribute4 := gc_encrypted_cc_num;  /* Commented for Defect 35918  */
            l_create_credit_card.attribute5 := gc_key_label;


            /* E1294 - End - Added for Creditcard Encryption functionality */
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING
                  (fnd_log.level_statement,
                   g_pkg_name || l_procedure_name,
                   'Inside Else,Save payment instr set to yes..before update CC'
                  );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                                  'l_create_credit_card.Card_Id : '
                               || l_create_credit_card.card_id
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                                  'l_create_credit_card.Active_Flag : '
                               || l_create_credit_card.active_flag
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                                  'l_create_credit_card.single_use_flag : '
                               || l_create_credit_card.single_use_flag
                              );
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                                  'l_create_credit_card.Inactive_Date: '
                               || l_create_credit_card.inactive_date
                              );
            END IF;

            iby_fndcpt_setup_pub.update_card
                                   (p_api_version          => 1.0,
                                    p_init_msg_list        => fnd_api.g_true,
                                    p_commit               => fnd_api.g_false,
                                    x_return_status        => x_return_status,
                                    x_msg_count            => l_msg_count,
                                    x_msg_data             => l_msg_data,
                                    p_card_instrument      => l_create_credit_card,
                                    x_response             => l_result_rec_type
                                   );

            IF (x_return_status <> fnd_api.g_ret_sts_success)
            THEN
               p_status := fnd_api.g_ret_sts_error;
               x_msg_count := x_msg_count + l_msg_count;

               IF (l_msg_data IS NOT NULL)
               THEN
                  x_msg_data := x_msg_data || l_msg_data || '*';
               END IF;

               x_msg_data := x_msg_data || '*' || l_result_rec.result_code;
               ROLLBACK TO ari_create_cash_pvt;
               write_error_messages (x_msg_data, x_msg_count);
               RETURN;
            END IF;
         END IF;
      END IF;

      SAVEPOINT ari_update_cc_bill_to_site_pvt;
      fnd_log.STRING (fnd_log.level_statement,
                      g_pkg_name || l_procedure_name,
                      'savepoint ari_update_cc_bill_to_site_pvt started'
                     );
      fnd_log.STRING (fnd_log.level_statement,
                      g_pkg_name || l_procedure_name,
                      'p_cc_bill_to_site_id' || p_cc_bill_to_site_id
                     );

      IF p_cc_bill_to_site_id > 0
      THEN
---------------------------------------------------------------------------------------------------------
         l_debug_info := 'CC billing site update required';
---------------------------------------------------------------------------------------------------------
         update_cc_bill_to_site
                               (p_cc_location_rec         => l_cc_location_rec,
                                x_cc_bill_to_site_id      => p_cc_bill_to_site_id,
                                x_return_status           => x_return_status,
                                x_msg_count               => l_msg_count,
                                x_msg_data                => l_msg_data
                               );

         IF (x_return_status <> fnd_api.g_ret_sts_success)
         THEN
            p_status := fnd_api.g_ret_sts_error;
            x_msg_count := x_msg_count + l_msg_count;

            IF (l_msg_data IS NOT NULL)
            THEN
               x_msg_data := x_msg_data || l_msg_data || '*';
            END IF;

            x_msg_data := x_msg_data || '*' || l_result_rec.result_code;
            ROLLBACK TO ari_update_cc_bill_to_site_pvt;
            write_error_messages (x_msg_data, x_msg_count);
            --Start added for bug 20389172 gnramasa 21st Jan 2014
            --Some customer restrict the external user not to update the credit card billing address thru security profile.
            --In that case update on HZ_LOCATIONS might fail. So ignoring the error.
		           --RETURN;
            --End added for bug 20389172 gnramasa 21st Jan 2014
         END IF;
      END IF;

      p_status := fnd_api.g_ret_sts_success;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'End-'
                        );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Others Exception occured ' || SQLERRM
                        );
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         write_debug_and_log ('- Customer Id: ' || p_customer_id);
         write_debug_and_log ('- Customer Site Id: ' || p_site_use_id);
         write_debug_and_log ('- Cash Receipt Id: ' || p_cash_receipt_id);
         write_debug_and_log ('- Return Status: ' || p_status);
         write_debug_and_log ('ERROR =>' || SQLERRM);
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
         p_status := fnd_api.g_ret_sts_error;
         x_msg_data :=
               'Unexpected Exception in '
            || g_pkg_name
            || l_procedure_name
            || ' '
            || SQLERRM;
         write_error_messages (x_msg_data, x_msg_count);
   END pay_multiple_invoices;

/*==============================================================
 | PROCEDURE process_payment
 |
 | DESCRIPTION
 |
 | PARAMETERS
 |
 | KNOWN ISSUES
 |
 | NOTES
 |   This procedure is the same as the on in the ar_receipt_api_pub.
 |   It was duplicated here in order to avoid exposing the api as a
 |   public api.
 |
 | MODIFICATION HISTORY
 | Date          Author       Description of Changes
 | 13-Jan-2003   krmenon      Created
 | 25-Feb-2004   vnb          Modified to add 'org_id' to rct_info
 |                            cursor,to be passed onto iPayment API
 | 07-Oct-2004   vnb          Bug 3335944 - One Time Credit Card Verification
 | 14-Mar-2013   melapaku     Bug16471455 - Payment Audit History
 | 21-Jul-2010   Bushrod      Updated for I0349 Defect 4180
 | 12-AUG-2020   Divyansh     Changes done for NAIT-129669 
 +==============================================================*/
   PROCEDURE process_payment (
      p_cash_receipt_id       IN              NUMBER,
      p_payer_rec             IN              iby_fndcpt_common_pub.payercontext_rec_type,
      p_payee_rec             IN              iby_fndcpt_trxn_pub.payeecontext_rec_type,
      p_called_from           IN              VARCHAR2,
      p_response_error_code   OUT NOCOPY      VARCHAR2,
      x_msg_count             OUT NOCOPY      NUMBER,
      x_msg_data              OUT NOCOPY      VARCHAR2,
      x_return_status         OUT NOCOPY      VARCHAR2,
      p_cc_auth_code          OUT NOCOPY      VARCHAR2,
      x_auth_result           OUT NOCOPY      iby_fndcpt_trxn_pub.authresult_rec_type,
      x_bep_code              OUT NOCOPY      VARCHAR2
   )
   IS
      CURSOR rct_info_cur
      IS
         SELECT cr.receipt_number, cr.amount, cr.currency_code,
                rc.creation_status, cr.org_id, cr.payment_trxn_extension_id,
                cr.receipt_method_id
           FROM ar_cash_receipts cr,
                ar_receipt_methods rm,
                ar_receipt_classes rc
          WHERE cr.cash_receipt_id = p_cash_receipt_id
            AND cr.receipt_method_id = rm.receipt_method_id
            AND rm.receipt_class_id = rc.receipt_class_id;

      rct_info                      rct_info_cur%ROWTYPE;
      l_cr_rec                      ar_cash_receipts%ROWTYPE;
      l_auth_rec                    iby_fndcpt_trxn_pub.authattribs_rec_type;
      l_amount_rec                  iby_fndcpt_trxn_pub.amount_rec_type;
      x_response                    iby_fndcpt_common_pub.result_rec_type;
      l_payment_trxn_extension_id   NUMBER;
      l_action                      VARCHAR2 (80);
      l_return_status               VARCHAR2 (1);
      l_msg_count                   NUMBER;
      l_msg_data                    VARCHAR2 (2000);
      l_procedure_name              VARCHAR2 (30);
      l_debug_info                  VARCHAR2 (200);
      /*Added for R12 upgrade retrofit*/
      l_tangible_rec                iby_payment_adapter_pub.tangible_rec_type;
      l_payment_server_order_num    VARCHAR2 (80);
      lc_meaning                    fnd_lookup_values.meaning%TYPE;
      -- Included by Madankumar J, Wipro Technologies for E1294
      lc_error_msg                  VARCHAR2 (2000);
      -- Included by Madankumar J, Wipro Technologies for E1294
      lc_error_loc                  VARCHAR2 (150);
      -- Included by Madankumar J, Wipro Technologies for E1294
      x_msg_data1                   VARCHAR2 (2000);
   /*End-Added for R12 upgrade retrofit*/
      l_instr_type                  VARCHAR2 (150);  -- Added for NAIT-129669

		lc_auth_code                  VARCHAR2 (50)   := NULL;  -- Added as part of Defect#34865
   BEGIN
      --Assign default values
      l_return_status := fnd_api.g_ret_sts_success;
      l_procedure_name := '.process_payment';
      arp_standard.DEBUG (   'Entering credit card processing...'
                          || p_cash_receipt_id
                         );
---------------------------------------------------------------------------------
      l_debug_info := 'Entering credit card processing';

---------------------------------------------------------------------------------
      OPEN rct_info_cur;

      FETCH rct_info_cur
       INTO rct_info;

      IF rct_info_cur%FOUND
      THEN
---------------------------------------------------------------------------------
         l_debug_info :=
            'This is a credit card account - determining if capture is necessary';
---------------------------------------------------------------------------------
         write_debug_and_log ('l_debug_info');

         -- determine whether to AUTHORIZE only or to
         -- CAPTURE and AUTHORIZE in one step.  This is
         -- dependent on the receipt creation status, i.e.,
         -- if the receipt is created as remitted or cleared, the
         -- funds need to be authorized and captured.  If the
         -- receipt is confirmed, the remittance process will
         -- handle the capture and at this time we'll only
         -- authorize the charges to the credit card.
         IF rct_info.creation_status IN ('REMITTED', 'CLEARED')
         THEN
            l_action := 'AUTHANDCAPTURE';
         ELSIF rct_info.creation_status = 'CONFIRMED'
         THEN
            l_action := 'AUTHONLY';
         ELSE
            arp_standard.DEBUG (   'ERROR: Creation status is '
                                || rct_info.creation_status
                               );
            fnd_message.set_name ('AR', 'AR_PAY_PROCESS_INVALID_STATUS');
            fnd_msg_pub.ADD;
            x_return_status := fnd_api.g_ret_sts_error; -- should never happen
            RETURN;
         END IF;

         l_payment_trxn_extension_id := rct_info.payment_trxn_extension_id;
         -- Step 1: (always performed):
         -- authorize credit card charge

         ---------------------------------------------------------------------------------
         l_debug_info := 'Authorize credit card charge: set auth record';
---------------------------------------------------------------------------------
         l_auth_rec.memo := NULL;
         l_auth_rec.order_medium := NULL;
         l_auth_rec.shipfrom_siteuse_id := NULL;
         l_auth_rec.shipfrom_postalcode := NULL;
         l_auth_rec.shipto_siteuse_id := NULL;
         l_auth_rec.shipto_postalcode := NULL;
         l_auth_rec.riskeval_enable_flag := NULL;
         l_amount_rec.VALUE := rct_info.amount;
         l_amount_rec.currency_code := rct_info.currency_code;
         /*Bug 8263633 pass receipt method id as per IBY requirement*/
         l_auth_rec.receipt_method_id := rct_info.receipt_method_id;
         -- call to iPayment API OraPmtReq to authorize funds
         write_debug_and_log ('Calling Create_Authorization');
         write_debug_and_log (   'p_trxn_entity_id: '
                              || l_payment_trxn_extension_id
                             );
         write_debug_and_log (   'p_payer_rec.payment_function:'
                              || p_payer_rec.payment_function
                             );
         write_debug_and_log ('p_payer_rec.org_type: ' || p_payer_rec.org_type);
         write_debug_and_log (   'p_payer_rec.Cust_Account_Id: '
                              || p_payer_rec.cust_account_id
                             );
         write_debug_and_log (   'p_payer_rec.Account_Site_Id: '
                              || p_payer_rec.account_site_id
                             );
         write_debug_and_log (   'l_amount_rec.Value: '
                              || TO_CHAR (l_amount_rec.VALUE)
                             );
         write_debug_and_log (   'l_amount_rec.Currency_Code: '
                              || l_amount_rec.currency_code
                             );
         write_debug_and_log ('p_payee_rec.org_type: ' || p_payee_rec.org_type);
         write_debug_and_log ('p_payee_rec.org_id : ' || p_payee_rec.org_id);
         write_debug_and_log (   'l_auth_rec.receipt_method_id : '
                              || l_auth_rec.receipt_method_id
                             );
         write_debug_and_log (   'p_payee_rec.Int_Bank_Country_Code : '
                              || p_payee_rec.int_bank_country_code
                             );
---------------------------------------------------------------------------------
         l_debug_info := 'Call to iPayment API to authorize funds';

---------------------------------------------------------------------------------

		 -- Start of the Defect#34865
         lc_auth_code := gc_auth_code;
          -- End of the Defect# 34865

         /*Added for R12 upgrade retrofit*/
         -- Added FOR I0349 AUTH
         --INVOICE_TANGIBLEID(GC_TRX_NUMBER ,l_payment_server_order_num);

         -- Added for R12 upgrade.
         -- Added FOR I0349 AUTH
         --Modification for E1294 by Madankumar J, Wipro Technologies begins
         /*
         IF (gc_auth_code IS NOT NULL)
         THEN
            l_pmtreqtrxn_rec.authcode := gc_auth_code;
            l_pmtreqtrxn_rec.voiceauthflag := 'Y';
            l_pmtreqtrxn_rec.dateofvoiceauthorization := SYSDATE;
         ELSE
            l_pmtreqtrxn_rec.authcode := NULL;
            l_pmtreqtrxn_rec.voiceauthflag := NULL;
            l_pmtreqtrxn_rec.dateofvoiceauthorization := NULL;
         END IF;
         */
         --Modification for E1294 by Madankumar J, Wipro Technologies ends

         --Modified above conmented piece of code for R12 upgrade
         IF (gc_auth_code IS NOT NULL)
         THEN
            UPDATE iby_fndcpt_tx_extensions ife
               SET ife.voice_authorization_code = gc_auth_code,
                   ife.voice_authorization_flag = 'Y',
                   ife.voice_authorization_date = SYSDATE
             WHERE trxn_extension_id = l_payment_trxn_extension_id;
         ELSE
            UPDATE iby_fndcpt_tx_extensions ife
               SET ife.voice_authorization_code = NULL,
                   ife.voice_authorization_flag = NULL,
                   ife.voice_authorization_date = NULL
             WHERE trxn_extension_id = l_payment_trxn_extension_id;
         END IF;
         invoice_tangibleid (gc_trx_number, 'ARI' || l_payment_trxn_extension_id); -- Defect 35495
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
            fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'Before Create_Authorization...' );
         END IF;

		 /*End-Added for R12 upgrade retrofit*/
        --Code changes done for NAIT-129669
        --
        -- Check for type of transaction
        --
        BEGIN
         SELECT distinct instrument_type
           INTO l_instr_type
           FROM ar_cash_receipts_all acr, ar_receipt_methods arm,iby_fndcpt_pmt_chnnls_b ifp
          WHERE acr.receipt_method_id = arm.receipt_method_id
            AND arm.payment_channel_code = ifp.payment_channel_code
            AND acr.payment_trxn_extension_id = l_payment_trxn_extension_id;
        EXCEPTION WHEN OTHERS THEN
          l_instr_type := 'BANK';
        END;
        
        IF l_instr_type = 'CREDITCARD' THEN
        --If credit card transaction then modify the logic
            xx_eai_authorization.create_authorization
                             (p_api_version         => 1.0,
                              p_init_msg_list       => fnd_api.g_true,
                              x_return_status       => l_return_status,
                              x_msg_count           => l_msg_count,
                              x_msg_data            => l_msg_data,
                              p_payer               => p_payer_rec,
                              p_payee               => p_payee_rec,
                              p_trxn_entity_id      => l_payment_trxn_extension_id,
                              p_auth_attribs        => l_auth_rec,
                              p_amount              => l_amount_rec,
                              x_auth_result         => x_auth_result,
                              x_response            => x_response
                             );        
        ELSE         
            -- Keeping existing logic forany other transaction type
            iby_fndcpt_trxn_pub.create_authorization
                             (p_api_version         => 1.0,
                              p_init_msg_list       => fnd_api.g_true,
                              x_return_status       => l_return_status,
                              x_msg_count           => l_msg_count,
                              x_msg_data            => l_msg_data,
                              p_payer               => p_payer_rec,
                              p_payee               => p_payee_rec,
                              p_trxn_entity_id      => l_payment_trxn_extension_id,
                              p_auth_attribs        => l_auth_rec,
                              p_amount              => l_amount_rec,
                              x_auth_result         => x_auth_result,
                              x_response            => x_response
                             );
        END IF;
--Code changes end for NAIT-129669                             
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
            fnd_log.STRING (fnd_log.level_statement, g_pkg_name || l_procedure_name, 'After Create_Authorization, l_return_status:' || l_return_status );
         END IF;

         arp_standard.DEBUG ('l_return_status: ' || l_return_status);
          --Added for R12 upgrade retrofit
          --l_reqresp_rec is not present
           -- Added for the Defect 2462(CR 247), for E1294
         -- x_bep_code := NVL(l_reqresp_rec.beperrcode,0);
         x_bep_code := NVL (x_auth_result.paymentsys_code, 0);

/* Defect 35495
         SELECT payment_system_order_number
           INTO l_payment_server_order_num
           FROM iby_fndcpt_tx_extensions
          WHERE trxn_extension_id = l_payment_trxn_extension_id;

         invoice_tangibleid (gc_trx_number, l_payment_server_order_num);
Defect 35495 */
         -- Added for the Defect 2462(CR 247), for E1294
         x_msg_count := l_msg_count;
         x_msg_data := l_msg_data;
         p_response_error_code := x_response.result_code;
         write_debug_and_log ('-------------------------------------');
         write_debug_and_log (   'x_response.Result_Code: '
                              || x_response.result_code
                             );
         write_debug_and_log (   'x_response.Result_Message: '
                              || x_response.result_message
                             );
         write_debug_and_log (   'x_response.Result_Category: '
                              || x_response.result_category
                             );
         write_debug_and_log (   'x_auth_result.Auth_Id : '
                              || x_auth_result.auth_id
                             );
         write_debug_and_log (   'x_auth_result.Auth_Date: '
                              || TO_CHAR (x_auth_result.auth_date)
                             );
         write_debug_and_log (   'x_auth_result.Auth_Code: '
                              || x_auth_result.auth_code
                             );
         write_debug_and_log (   'x_auth_result.AVS_Code: '
                              || x_auth_result.avs_code
                             );
         write_debug_and_log (   'x_auth_result.Instr_SecCode_Check: '
                              || x_auth_result.instr_seccode_check
                             );
         write_debug_and_log (   'x_auth_result.PaymentSys_Code: '
                              || x_auth_result.paymentsys_code
                             );
         write_debug_and_log (   'x_auth_result.PaymentSys_Msg: '
                              || x_auth_result.paymentsys_msg
                             );
         write_debug_and_log ('-------------------------------------');

         -- check if call was successful
         --Add message to message stack only it it is called from iReceivables
         --if not pass the message stack received from iPayment
         IF     (l_return_status <> fnd_api.g_ret_sts_success)
            AND (NVL (p_called_from, 'NONE') = 'IREC')
         THEN
            write_debug_and_log
                         ('l_return_status <> fnd_api.g_ret_sts_success IREC');
            fnd_message.set_name ('AR', 'AR_CC_AUTH_FAILED');
            fnd_msg_pub.ADD;
            x_return_status := l_return_status;
            --Bug 7673372 - When IBY API throws an error without contacting 3rd pmt system the error msg would
            --returned in x_response.Result_Message;
            --x_msg_data := x_response.result_message;
            x_msg_data := x_auth_result.paymentsys_msg;
            RETURN;
         ELSIF (l_return_status <> fnd_api.g_ret_sts_success)
         THEN
            write_debug_and_log
                              ('l_return_status <> fnd_api.g_ret_sts_success');
            p_cc_auth_code := x_auth_result.auth_code;
            x_return_status := l_return_status;
            --x_msg_data := x_response.result_message;                                    /* Added for R12 upgrade */
            x_msg_data := x_auth_result.paymentsys_msg;
            RETURN;
         END IF;

-- update cash receipt with authorization code
 ---------------------------------------------------------------------------------
         l_debug_info :=
            'update cash receipt with authorization code and payment server order id';
---------------------------------------------------------------------------------
         arp_cash_receipts_pkg.set_to_dummy (l_cr_rec);
         l_cr_rec.approval_code := x_auth_result.auth_code;
         arp_cash_receipts_pkg.update_p (l_cr_rec, p_cash_receipt_id);
         write_debug_and_log ('CR rec updated with payment server auth code');

         /*Start-Added for R12 upgrade retrofit*/
         --Modification for E1294 by Madankumar J, Wipro Technologies begins
         BEGIN
            SELECT meaning
              INTO lc_meaning
              FROM fnd_lookup_values flv
             WHERE lookup_type = 'AR_VER_AUTH'
               AND lookup_code = 'VERAUTH_STORES'
               AND TRUNC (NVL (flv.end_date_active, SYSDATE + 1)) >
                                                               TRUNC (SYSDATE);
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_msg := SQLERRM;
               lc_error_loc := 'While getting lookup meaning';
               xx_com_error_log_pub.log_error
                    (p_program_type                => 'PROCEDURE',
                     p_attribute15                => 'XX_AR_IREC_PAYMENTS',
                     p_module_name                 => 'AR',
                     p_error_location              =>    'Error at '
                                                      || lc_error_loc,
                     p_error_message_count         => 1,
                     p_error_message_code          => 'E',
                     p_error_message               => lc_error_msg,
                     p_error_message_severity      => 'Major',
                     p_notify_flag                 => 'N',
                     p_object_type                 => 'Verbal Auth'
                    );
         END;

         IF (    l_return_status = fnd_api.g_ret_sts_success
             AND gc_auth_code IS NOT NULL
            )
         THEN
            UPDATE ar_cash_receipts
               SET attribute1 = lc_meaning,
                   attribute3 = '1',
                   attribute_category = 'SALES_ACCT'
             WHERE cash_receipt_id = p_cash_receipt_id;
         END IF;

         process_ps2000_info
                          (p_trxn_extension_id      => l_payment_trxn_extension_id,
                           p_cash_receipt_id        => p_cash_receipt_id
                          );

         IF (l_action = 'AUTHANDCAPTURE')
         THEN
            write_debug_and_log ('starting capture...');
---------------------------------------------------------------------------------
            l_debug_info := 'Capture required: capture funds';
---------------------------------------------------------------------------------
-- Step 2: (optional): capture funds

            ---------------------------------------------------------------------------------
            l_debug_info := 'Call iPayment API to capture funds';
---------------------------------------------------------------------------------
            iby_fndcpt_trxn_pub.create_settlement
                            (p_api_version         => 1.0,
                             p_init_msg_list       => fnd_api.g_true,
                             x_return_status       => l_return_status,
                             x_msg_count           => l_msg_count,
                             x_msg_data            => l_msg_data,
                             p_payer               => p_payer_rec,
                             p_trxn_entity_id      => l_payment_trxn_extension_id,
                             p_amount              => l_amount_rec,
                             x_response            => x_response
                            );
            write_debug_and_log ('CAPTURE l_return_status: '
                                 || l_return_status
                                );
            x_msg_count := l_msg_count;
            x_msg_data := l_msg_data;
            p_response_error_code := x_response.result_code;
            arp_standard.DEBUG ('-------------------------------------');
            arp_standard.DEBUG (   'x_response.Result_Code: '
                                || x_response.result_code
                               );
            arp_standard.DEBUG (   'x_response.Result_Category: '
                                || x_response.result_category
                               );
            arp_standard.DEBUG (   'x_response.Result_Message: '
                                || x_response.result_message
                               );
            arp_standard.DEBUG ('-------------------------------------');

            --Add message to message stack only it it is called from iReceivables
            --if not pass the message stack received from iPayment
            IF     (l_return_status <> fnd_api.g_ret_sts_success)
               AND (NVL (p_called_from, 'NONE') = 'IREC')
            THEN
               fnd_message.set_name ('AR', 'AR_CC_CAPTURE_FAILED');
               fnd_msg_pub.ADD;
            END IF;

            x_return_status := l_return_status;
            --Bug 7673372 - When IBY API throws an error without contacting 3rd pmt system the error msg would
            --returned in x_response.Result_Message;
            x_msg_data := x_response.result_message;
         END IF;                                     -- if capture required...
      ELSE
         write_debug_and_log
              ('should never come here --> receipt method cursor has no rows');
      -- currently no processing required
	  END IF;

	  --Start of the Defect#34865
	    IF (lc_auth_code IS NULL)
        THEN
            UPDATE ar_cash_receipts
            SET attribute3 = null
            WHERE cash_receipt_id = p_cash_receipt_id;
		END IF;
	  --End of the Defect#34865

   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            x_return_status := fnd_api.g_ret_sts_error;
            write_debug_and_log (   'Unexpected Exception in '
                                 || g_pkg_name
                                 || l_procedure_name
                                );
            write_debug_and_log ('- Cash Receipt Id: ' || p_cash_receipt_id);
            write_debug_and_log ('- Return Status: ' || x_return_status);
            write_debug_and_log (SQLERRM);
            fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
            fnd_message.set_token ('PROCEDURE',
                                   g_pkg_name || l_procedure_name);
            fnd_message.set_token ('ERROR', SQLERRM);
            fnd_message.set_token ('DEBUG_INFO', l_debug_info);
            fnd_msg_pub.ADD;
         END;
   END process_payment;

   FUNCTION validate_payment_setup (
      p_customer_id        IN   NUMBER,
      p_customer_site_id   IN   NUMBER,
      p_currency_code      IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      l_ccmethodcount     NUMBER;
      l_bamethodcount     NUMBER;       /* J Rautiainen ACH Implementation */
      l_creation_status   ar_receipt_classes.creation_status%TYPE;
      l_procedure_name    VARCHAR2 (30);
   BEGIN
      l_procedure_name := '.validate_payment_setup';

      -- check that function security is allowing access to payment button
      IF NOT fnd_function.TEST ('ARW_PAY_INVOICE')
      THEN
         RETURN 0;
      END IF;

      -- verify that payment method is set up
      l_ccmethodcount :=
         is_credit_card_payment_enabled (p_customer_id,
                                         p_customer_site_id,
                                         p_currency_code
                                        );

      -- Bug 3338276
      -- If one-time payment is enabled, bank account payment is not enabled;
      -- Hence, the check for valid bank account payment methods can be defaulted to 0.
      -- Bug 3886652 - Customer Id and Customer Site Use Id added as params to ARI_CONFIG.save_payment_instrument_info
      IF NOT ari_utilities.save_payment_instrument_info (p_customer_id,
                                                         p_customer_site_id
                                                        )
      THEN
         l_bamethodcount := 0;
      ELSE
         l_bamethodcount :=
            is_bank_acc_payment_enabled (p_customer_id,
                                         p_customer_site_id,
                                         p_currency_code
                                        );
      END IF;

      IF     l_ccmethodcount = 0
         AND l_bamethodcount = 0         /* J Rautiainen ACH Implementation */
      THEN
         RETURN 0;
      END IF;

      RETURN 1;
   END validate_payment_setup;

/*============================================================
  | PUBLIC procedure create_transaction_list_record
  |
  | DESCRIPTION
  |   Creates a record in the transaction List to be paid by the customer
  |   based on the selected list .
  |
  | PSEUDO CODE/LOGIC
  |
  | PARAMETERS
  |   p_payment_schedule_id   IN    NUMBER
  |   p_customer_id        IN    NUMBER
  |   p_customer_site_id      IN    NUMBER
  |
  | KNOWN ISSUES
  |
  |
  |
  | NOTES
  |
  |
  |
  | MODIFICATION HISTORY
  | Date          Author       Description of Changes
  | 27-JUN-2003   yreddy       Created
  | 31-DEC-2004   vnb          Bug 4071551 - Modified for avoiding redundant code
  | 20-Jan-2005   vnb          Bug 4117211 - Original discount amount column added for ease of resetting payment amounts
  | 26-May-05     rsinthre     Bug # 4392371 - OIR needs to support cross customer payment
  | 08-Jul-2005     rsinthre     Bug 4437225 - Disputed amount against invoice not displayed during payment
  | 08-Jun-2010  nkanchan Bug # 9696274 - PAGE ERRORS OUT ON NAVIGATING 'PAY BELOW' RELATED CUSTOMER DATA
  +============================================================*/
   PROCEDURE create_transaction_list_record (
      p_payment_schedule_id   IN   NUMBER,
      p_customer_id           IN   NUMBER,
      p_customer_site_id      IN   NUMBER
   )
   IS
      l_query_period           NUMBER (15);
      l_query_date             DATE;
      l_total_service_charge   NUMBER;
      l_discount_amount        NUMBER;
      l_rem_amt_rcpt           NUMBER;
      l_rem_amt_inv            NUMBER;
      l_amount_due_remaining   NUMBER;
      l_trx_class              VARCHAR2 (20);
      l_cash_receipt_id        NUMBER;
      l_grace_days_flag        VARCHAR2 (2);
      l_pay_for_cust_id        NUMBER (15);
      l_paying_cust_id         NUMBER (15);
      l_pay_for_cust_site_id   NUMBER (15);
      l_paying_cust_site_id    NUMBER (15);
      l_dispute_amount         NUMBER         := 0;
      l_customer_trx_id        NUMBER (15, 0);
      l_procedure_name         VARCHAR2 (50);
      l_debug_info             VARCHAR2 (200);
   BEGIN
      --Assign default values
      l_query_period := -12;
      l_total_service_charge := 0;
      l_discount_amount := 0;
      l_rem_amt_rcpt := 0;
      l_rem_amt_inv := 0;
      l_amount_due_remaining := 0;
      l_procedure_name := '.create_transaction_list_record';
      SAVEPOINT create_trx_list_record_sp;

      SELECT CLASS, amount_due_remaining, cash_receipt_id,
             ps.customer_id, ct.paying_customer_id, ps.customer_site_use_id,
             ct.paying_site_use_id, ps.customer_trx_id,
             (  DECODE (NVL (amount_due_original, 0),
                        0, 1,
                        (amount_due_original / ABS (amount_due_original)
                        )
                       )
              * ABS (NVL (amount_in_dispute, 0))
             )
        INTO l_trx_class, l_amount_due_remaining, l_cash_receipt_id,
             l_pay_for_cust_id, l_paying_cust_id, l_pay_for_cust_site_id,
             l_paying_cust_site_id, l_customer_trx_id,
             l_dispute_amount
        FROM ar_payment_schedules ps, ra_customer_trx_all ct
       WHERE ps.customer_trx_id = ct.customer_trx_id(+)
         AND ps.payment_schedule_id = p_payment_schedule_id;

      --Bug 4479224
      l_paying_cust_id := p_customer_id;

      --l_paying_cust_site_id := p_customer_site_id;
      --Commented for bug 9696274
      IF (   p_customer_site_id IS NULL
          OR p_customer_site_id = ''
          OR p_customer_site_id = -1
         )
      THEN
         IF (l_paying_cust_id = l_pay_for_cust_id)
         THEN
            l_paying_cust_site_id := l_pay_for_cust_site_id;
         ELSE
            l_paying_cust_site_id := -1;
         END IF;
      ELSE
         l_paying_cust_site_id := p_customer_site_id;
      END IF;

----------------------------------------------------------------------------------------
      l_debug_info :=
              'If the transaction is a Payment, then set the Remaining Amount';

-----------------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

      -- Bug 4000279 - Modified to check for 'UNAPP' status only
      IF (l_trx_class = 'PMT')
      THEN
         SELECT -SUM (app.amount_applied)
           INTO l_amount_due_remaining
           FROM ar_receivable_applications app
          WHERE NVL (app.confirmed_flag, 'Y') = 'Y'
            AND app.status = 'UNAPP'
            AND app.cash_receipt_id = l_cash_receipt_id;

----------------------------------------------------------------------------------------
         l_debug_info :=
                      'If the transaction is a debit, then calculate discount';

-----------------------------------------------------------------------------------------
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (l_debug_info);
         END IF;
      ELSIF (   l_trx_class = 'INV'
             OR l_trx_class = 'DEP'
             OR l_trx_class = 'DM'
             OR l_trx_class = 'CB'
            )
      THEN
         --Bug 6819964 - If AR API errors out then payments are failing as l_discount_amount is not set to any value
         BEGIN
            --l_grace_days_flag := is_grace_days_enabled_wrapper();
            l_grace_days_flag :=
               ari_utilities.is_discount_grace_days_enabled
                                                          (p_customer_id,
                                                           p_customer_site_id
                                                          );
            arp_discounts_api.get_discount
                            (p_ps_id                  => p_payment_schedule_id,
                             p_apply_date             => TRUNC (SYSDATE),
                             p_in_applied_amount      => (  l_amount_due_remaining
                                                          - l_dispute_amount
                                                         ),
                             p_grace_days_flag        => l_grace_days_flag,
                             p_out_discount           => l_discount_amount,
                             p_out_rem_amt_rcpt       => l_rem_amt_rcpt,
                             p_out_rem_amt_inv        => l_rem_amt_inv,
                             p_called_from            => 'OIR'
                            );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_discount_amount := 0;
               write_debug_and_log
                           ('Unexpected Exception while calculating discount');
               write_debug_and_log (   'Payment Schedule Id: '
                                    || p_payment_schedule_id
                                   );
         END;
      END IF;

--Bug 4117211 - Original discount amount column added for ease of resetting payment amounts
----------------------------------------------------------------------------------------
      l_debug_info := 'Populate the Payment GT with the transaction';

-----------------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

      INSERT INTO ar_irec_payment_list_gt
                  (customer_id, customer_site_use_id, account_number,
                   customer_trx_id, trx_number, payment_schedule_id, trx_date,
                   due_date, status, trx_class, po_number, so_number,
                   currency_code, amount_due_original, amount_due_remaining,
                   discount_amount, service_charge, payment_amt,
                   payment_terms, number_of_installments,
                   terms_sequence_number, line_amount, tax_amount,
                   freight_amount, finance_charges, receipt_date,
                   printing_option, interface_header_context,
                   interface_header_attribute1, interface_header_attribute2,
                   interface_header_attribute3, interface_header_attribute4,
                   interface_header_attribute5, interface_header_attribute6,
                   interface_header_attribute7, interface_header_attribute8,
                   interface_header_attribute9, interface_header_attribute10,
                   interface_header_attribute11, interface_header_attribute12,
                   interface_header_attribute13, interface_header_attribute14,
                   interface_header_attribute15, attribute_category,
                   attribute1, attribute2, attribute3, attribute4, attribute5,
                   attribute6, attribute7, attribute8, attribute9,
                   attribute10, attribute11, attribute12, attribute13,
                   attribute14, attribute15, cash_receipt_id,
                   original_discount_amt, org_id, pay_for_customer_id,
                   pay_for_customer_site_id, dispute_amt)
         SELECT l_paying_cust_id,
                DECODE (l_paying_cust_site_id,
                        NULL, -1,
                        TO_NUMBER (''), -1,
                        l_paying_cust_site_id
                       ),
                acct.account_number, ps.customer_trx_id, ps.trx_number,
                ps.payment_schedule_id, ps.trx_date, ps.due_date, ps.status,
                ps.CLASS, ct.purchase_order AS po_number, NULL AS so_number,
                ps.invoice_currency_code, ps.amount_due_original,
                l_amount_due_remaining, l_discount_amount, 0,
                DECODE
                      (ps.CLASS,
                       'PMT', l_amount_due_remaining,
                       'CM', l_amount_due_remaining,
                       ari_utilities.curr_round_amt (  l_amount_due_remaining
                                                     - l_discount_amount
                                                     - l_dispute_amount,
                                                     ps.invoice_currency_code
                                                    )
                      ),
                trm.NAME term_desc,
                arpt_sql_func_util.get_number_of_due_dates
                                           (ps.term_id)
                                                       number_of_installments,
                ps.terms_sequence_number,
                ps.amount_line_items_original line_amount,
                ps.tax_original tax_amount,
                ps.freight_original freight_amount,
                ps.receivables_charges_charged finance_charge,
                CASE
                   WHEN ((TRUNC (ps.trx_date) - TRUNC (SYSDATE)) <= 0
                        )
                      THEN TRUNC (SYSDATE)
                   ELSE ps.trx_date
                END AS receipt_date,
                ct.printing_option, ct.interface_header_context,
                ct.interface_header_attribute1,
                ct.interface_header_attribute2,
                ct.interface_header_attribute3,
                ct.interface_header_attribute4,
                ct.interface_header_attribute5,
                ct.interface_header_attribute6,
                ct.interface_header_attribute7,
                ct.interface_header_attribute8,
                ct.interface_header_attribute9,
                ct.interface_header_attribute10,
                ct.interface_header_attribute11,
                ct.interface_header_attribute12,
                ct.interface_header_attribute13,
                ct.interface_header_attribute14,
                ct.interface_header_attribute15, ct.attribute_category,
                ct.attribute1, ct.attribute2, ct.attribute3, ct.attribute4,
                ct.attribute5, ct.attribute6, ct.attribute7, ct.attribute8,
                ct.attribute9, ct.attribute10, ct.attribute11, ct.attribute12,
                ct.attribute13, ct.attribute14, ct.attribute15,
                ps.cash_receipt_id, l_discount_amount, ps.org_id,
                l_pay_for_cust_id,

                --Bug 4062938 - Handling of transactions with no site id
                DECODE (ps.customer_site_use_id,
                        NULL, -1,
                        ps.customer_site_use_id
                       ) AS customer_site_use_id,
                (  DECODE (NVL (ps.amount_due_original, 0),
                           0, 1,
                           (  ps.amount_due_original
                            / ABS (ps.amount_due_original)
                           )
                          )
                 * ABS (NVL (ps.amount_in_dispute, 0))
                )
           FROM ar_payment_schedules ps,
                ra_customer_trx_all ct,
                hz_cust_accounts acct,
                ra_terms trm
          WHERE ps.payment_schedule_id = p_payment_schedule_id
            AND ps.CLASS IN ('INV', 'DM', 'GUAR', 'CB', 'DEP', 'CM', 'PMT')
            -- CCA - hikumar
            AND ps.customer_trx_id = ct.customer_trx_id(+)
            AND acct.cust_account_id = ps.customer_id
            AND ps.term_id = trm.term_id(+);

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF (pg_debug = 'Y')
         THEN
            arp_standard.DEBUG (   'Unexpected Exception in '
                                || g_pkg_name
                                || l_procedure_name
                               );
            arp_standard.DEBUG (   '- Payment Schedule Id: '
                                || p_payment_schedule_id
                               );
            arp_standard.DEBUG ('ERROR =>' || SQLERRM);
         END IF;

         ROLLBACK TO create_trx_list_record_sp;
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END create_transaction_list_record;

/*========================================================================
 | PUBLIC procedure is_credit_card_payment_enabled
 |
 | DESCRIPTION
 |      Checks if the credit card payment method has been setup
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 | RETURNS
 |      Number 1 or 0 corresponing to true and false for the credit card
 |      payment has been setup or not.
 |
 | MODIFICATION HISTORY
 | Date          Author       Description of Changes
 | 10-Mar-2004   hikumar       Created
 | 16-Feb-2015   gnramasa  Bug 20502416 - IREC- CODE: INCONSISTENT BEHAVIOR OF PAY BUTTON IN ACCNT DETAIL AND TRX DETAIL
 ========================================================================*/
   FUNCTION is_credit_card_payment_enabled (
      p_customer_id        IN   NUMBER,
      p_customer_site_id   IN   NUMBER,
      p_currency_code      IN   VARCHAR2,
      p_org_id             IN   NUMBER Default null
   )
      RETURN NUMBER
   IS
      system_cc_payment_method     NUMBER;
      customer_cc_payment_method   NUMBER;
      profile_cc_payment_method    VARCHAR2 (200);

      CURSOR cc_profile_pmt_method_info_cur
      IS
         SELECT arm.receipt_method_id receipt_method_id,
                arc.creation_status receipt_creation_status
           FROM ar_receipt_methods arm,
                ar_receipt_method_accounts arma,
                ce_bank_acct_uses_ou_v aba,
                ce_bank_accounts cba,
                ar_receipt_classes arc,
                ar_system_parameters sp
          WHERE arm.payment_channel_code = 'CREDIT_CARD'
            AND arm.receipt_method_id =
                   NVL (TO_NUMBER (fnd_profile.VALUE ('OIR_CC_PMT_METHOD')),
                        arm.receipt_method_id
                       )
            AND arm.receipt_method_id = arma.receipt_method_id
            AND arm.receipt_class_id = arc.receipt_class_id
            AND arma.remit_bank_acct_use_id = aba.bank_acct_use_id
            AND aba.bank_account_id = cba.bank_account_id
            AND (   cba.currency_code = p_currency_code
                 OR cba.receipt_multi_currency_flag = 'Y'
                )
            AND sp.irec_cc_receipt_method_id = arm.receipt_method_id
            AND sp.org_id = nvl(p_org_id, sp.org_id)
            AND TRUNC (NVL (aba.end_date, SYSDATE)) >= TRUNC (SYSDATE)
            AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (arm.start_date, SYSDATE))
                                    AND TRUNC (NVL (arm.end_date, SYSDATE))
            AND TRUNC (SYSDATE) BETWEEN TRUNC (arma.start_date)
                                    AND TRUNC (NVL (arma.end_date, SYSDATE));

      cc_profile_pmt_method_info   cc_profile_pmt_method_info_cur%ROWTYPE;
      l_procedure_name             VARCHAR2 (30);
      l_debug_info                 VARCHAR2 (300);
   BEGIN
      l_procedure_name := 'is_credit_card_payment_enabled';
--------------------------------------------------------------------
      l_debug_info :=
         'Checking if valid CC payment method is set in the profile OIR_CC_PMT_METHOD';

--------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.debug('Inside Procedure is_credit_card_payment_enabled');
         arp_standard.DEBUG (l_debug_info);
         arp_standard.debug('CC, p_org_id : ' || p_org_id);
      END IF;

      profile_cc_payment_method := fnd_profile.VALUE ('OIR_CC_PMT_METHOD');

      IF (profile_cc_payment_method = 'DISABLED')
      THEN                               /* Credit Card Payment is Disabled */
         RETURN 0;
      ELSIF (profile_cc_payment_method IS NOT NULL)
      THEN               /* A Credit Card Payment Method has been mentioned */
         OPEN cc_profile_pmt_method_info_cur;

         FETCH cc_profile_pmt_method_info_cur
          INTO cc_profile_pmt_method_info;

         /* If CC Payment Method set is NULL or DISABLED or an invalid payment method, it returns NO rows */
         IF cc_profile_pmt_method_info_cur%FOUND
         THEN
            l_debug_info :=
                  'Payment Method Set in the profile OIR_CC_PMT_METHOD is Valid. Val='
               || fnd_profile.VALUE ('OIR_CC_PMT_METHOD');

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               l_debug_info
                              );
            END IF;

            RETURN 1;
         ELSE
            l_debug_info :=
                  'Invalid Payment Method is Set in the profile OIR_CC_PMT_METHOD. Value in profile='
               || fnd_profile.VALUE ('OIR_CC_PMT_METHOD');

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               l_debug_info
                              );
            END IF;

            RETURN 0;
         END IF;

         CLOSE cc_profile_pmt_method_info_cur;
      END IF;

      l_debug_info :=
         'No value is set in the profile OIR_CC_PMT_METHOD. Checking at customer site, acct and system options level.';

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         l_debug_info
                        );
      END IF;

      /* Default behavior, as no Credit Card Payment method is mentioned in the OIR_CC_PMT_METHOD profile */

      -- verify that Credit Card payment method is set up in AR_SYSTEM_PARAMETERS
       -- Bug 3886652 - Customer Id and Customer Site Use Id added as params to ARI_CONFIG.save_payment_instrument_info
      SELECT /*+ leading(rc) */
             COUNT (irec_cc_receipt_method_id)
        INTO system_cc_payment_method
        FROM ar_system_parameters sp,
             ar_receipt_methods rm,
             ar_receipt_method_accounts rma,
             ce_bank_accounts cba,
             ce_bank_acct_uses_ou_v ba,
             ar_receipt_classes rc
       WHERE sp.irec_cc_receipt_method_id = rm.receipt_method_id
         AND rma.receipt_method_id = rm.receipt_method_id
         AND rma.remit_bank_acct_use_id = ba.bank_acct_use_id
         AND ba.bank_account_id = cba.bank_account_id
         AND (   cba.currency_code = p_currency_code
              OR cba.receipt_multi_currency_flag = 'Y'
             )
         AND SYSDATE < NVL (ba.end_date, SYSDATE + 1)
         AND SYSDATE BETWEEN rma.start_date AND NVL (rma.end_date, SYSDATE)
         AND SYSDATE BETWEEN rm.start_date AND NVL (rm.end_date, SYSDATE)
         AND  sp.org_id = nvl(p_org_id, sp.org_id)
         /* Commented for bug 12670265
          AND (
                save_payment_inst_info_wrapper(p_customer_id,p_customer_site_id) = 'true'
               OR
                  -- If the one time payment is true , then ensure that the receipt
                   -- class is set for one step remittance.
                   rc.creation_status IN ('REMITTED','CLEARED')) */
         AND rc.receipt_class_id = rm.receipt_class_id;

      -- verify that Credit Card payment method is set up at Customer Account Level or Site Level
      SELECT COUNT (arm.receipt_method_id)
        INTO customer_cc_payment_method
        FROM ar_receipt_methods arm,
             ra_cust_receipt_methods rcrm,
             ar_receipt_method_accounts arma,
             ce_bank_acct_uses_ou_v aba,
             ce_bank_accounts cba,
             ar_receipt_classes arc
       WHERE arm.receipt_method_id = rcrm.receipt_method_id
         AND arm.receipt_method_id = arma.receipt_method_id
         AND arm.receipt_class_id = arc.receipt_class_id
         AND rcrm.customer_id = p_customer_id
         AND arma.remit_bank_acct_use_id = aba.bank_acct_use_id
         AND aba.bank_account_id = cba.bank_account_id
         AND (   NVL (rcrm.site_use_id, p_customer_site_id) =
                                                            p_customer_site_id
              OR (p_customer_site_id IS NULL AND rcrm.site_use_id IS NULL)
             )
         AND (   cba.currency_code = p_currency_code
              OR cba.receipt_multi_currency_flag = 'Y'
             )
-- Bug#6109909
--     AND  arm.payment_type_code = 'CREDIT_CARD'
         AND arm.payment_channel_code = 'CREDIT_CARD'
         AND arc.creation_method_code = 'AUTOMATIC'
         -- AND       aba.set_of_books_id = arp_trx_global.system_info.system_parameters.set_of_books_id
         AND SYSDATE < NVL (aba.end_date, SYSDATE + 1)
         AND SYSDATE BETWEEN arm.start_date AND NVL (arm.end_date, SYSDATE)
         AND SYSDATE BETWEEN arma.start_date AND NVL (arma.end_date, SYSDATE)
             --Added below condition for bug-20387036
         AND sysdate between rcrm.start_date AND NVL(rcrm.end_date, sysdate)
                                                                             /* Commented for bug 12670265
                                                                             AND (
                                                                                  ( save_payment_inst_info_wrapper(p_customer_id,p_customer_site_id) = 'true' )
                                                                                  OR
                                                                                  (   -- If the one time payment is true , then ensure that the receipt
                                                                                      -- class is set for one step remittance.
                                                                                    arc.creation_status IN ('REMITTED','CLEARED')
                                                                                  )
                                                                                 ) */
      ;
            if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
                fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name, 'customer_cc_payment_method  :'||customer_cc_payment_method);
                fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name, 'system_cc_payment_method  :'||system_cc_payment_method);
            end if;

      IF ((customer_cc_payment_method = 0) AND (system_cc_payment_method = 0)
         )
      THEN
         RETURN 0;
      ELSE
         RETURN 1;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_debug_info :=
               'Unknown exception. Value in profile OIR_CC_PMT_METHOD='
            || fnd_profile.VALUE ('OIR_CC_PMT_METHOD');
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         write_debug_and_log ('ERROR =>' || SQLERRM);
         write_debug_and_log ('-DEBUG_INFO-' || l_debug_info);
         RETURN 0;
   END is_credit_card_payment_enabled;

/*========================================================================
 | PUBLIC procedure is_bank_acc_payment_enabled
 |
 | DESCRIPTION
 |      Checks if the Bank Account payment method has been setup
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 | RETURNS
 |      Number 1 or 0 corresponing to true and false for the credit card
 |      payment has been setup or not.
 |
 | MODIFICATION HISTORY
 | Date          Author       Description of Changes
 | 10-Mar-2004   hikumar       Created
 | 16-Feb-2015   gnramasa  Bug 20502416 - IREC- CODE: INCONSISTENT BEHAVIOR OF PAY BUTTON IN ACCNT DETAIL AND TRX DETAIL
 ========================================================================*/
   FUNCTION is_bank_acc_payment_enabled (
      p_customer_id        IN   NUMBER,
      p_customer_site_id   IN   NUMBER,
      p_currency_code      IN   VARCHAR2,
      p_org_id             IN   NUMBER Default null
   )
      RETURN NUMBER
   IS
      system_bank_payment_method     NUMBER;
      customer_bank_payment_method   NUMBER;
      profile_ba_payment_method      VARCHAR2 (200);

      CURSOR ba_profile_pmt_method_info_cur
      IS
         SELECT arm.receipt_method_id receipt_method_id,
                arc.creation_status receipt_creation_status
           FROM ar_receipt_methods arm,
                ar_receipt_method_accounts arma,
                ce_bank_acct_uses_ou_v aba,
                ce_bank_accounts cba,
                ar_receipt_classes arc,
                ar_system_parameters sp
          WHERE NVL (arm.payment_channel_code, 'NONE') <> 'CREDIT_CARD'
            AND arm.receipt_method_id =
                   NVL (TO_NUMBER (fnd_profile.VALUE ('OIR_BA_PMT_METHOD')),
                        arm.receipt_method_id
                       )
            AND arm.receipt_method_id = arma.receipt_method_id
            AND arm.receipt_class_id = arc.receipt_class_id
            AND arma.remit_bank_acct_use_id = aba.bank_acct_use_id
            AND aba.bank_account_id = cba.bank_account_id
            AND (   cba.currency_code = p_currency_code
                 OR cba.receipt_multi_currency_flag = 'Y'
                )
            AND sp.irec_ba_receipt_method_id = arm.receipt_method_id
            AND sp.org_id = nvl(p_org_id, sp.org_id)
            AND TRUNC (NVL (aba.end_date, SYSDATE)) >= TRUNC (SYSDATE)
            AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (arm.start_date, SYSDATE))
                                    AND TRUNC (NVL (arm.end_date, SYSDATE))
            AND TRUNC (SYSDATE) BETWEEN TRUNC (arma.start_date)
                                    AND TRUNC (NVL (arma.end_date, SYSDATE));

      ba_profile_pmt_method_info     ba_profile_pmt_method_info_cur%ROWTYPE;
      l_procedure_name               VARCHAR2 (30);
      l_debug_info                   VARCHAR2 (300);
   BEGIN
      l_procedure_name := 'is_bank_acc_payment_enabled';
--------------------------------------------------------------------
      l_debug_info :=
         'Checking if valid Bank Account payment method is set in the profile OIR_BA_PMT_METHOD';

--------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
        arp_standard.debug('Inside Procedure is_bank_acc_payment_enabled');
        arp_standard.debug(l_debug_info);
		    arp_standard.debug('BA, p_org_id : ' || p_org_id);
      END IF;

      profile_ba_payment_method := fnd_profile.VALUE ('OIR_BA_PMT_METHOD');

      IF (profile_ba_payment_method = 'DISABLED')
      THEN                              /* Bank Account Payment is Disabled */
         RETURN 0;
      ELSIF (profile_ba_payment_method IS NOT NULL)
      THEN              /* A Bank Account Payment Method has been mentioned */
         OPEN ba_profile_pmt_method_info_cur;

         FETCH ba_profile_pmt_method_info_cur
          INTO ba_profile_pmt_method_info;

         /* If Bank Account Payment Method set is NULL or DISABLED or an invalid payment method, it returns NO rows */
         IF ba_profile_pmt_method_info_cur%FOUND
         THEN
            l_debug_info :=
                  'Payment Method Set in the profile OIR_BA_PMT_METHOD is Valid. Val='
               || fnd_profile.VALUE ('OIR_BA_PMT_METHOD');

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               l_debug_info
                              );
            END IF;

            RETURN 1;
         ELSE
            l_debug_info :=
                  'Invalid Payment Method is Set in the profile OIR_BA_PMT_METHOD. Value in profile='
               || fnd_profile.VALUE ('OIR_BA_PMT_METHOD');

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
               fnd_log.STRING (fnd_log.level_statement,
                               g_pkg_name || l_procedure_name,
                               l_debug_info
                              );
            END IF;

            RETURN 0;
         END IF;

         CLOSE ba_profile_pmt_method_info_cur;
      END IF;

      l_debug_info :=
         'No value is set in the profile OIR_BA_PMT_METHOD. Checking at customer site, acct and system options level.';

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         l_debug_info
                        );
      END IF;

      /* Default behavior, as no Bank Account Payment method is mentioned in the OIR_BA_PMT_METHOD profile */

      -- verify that Bank Account payment method is set up in AR_SYSTEM_PARAMETERS
      SELECT COUNT (irec_ba_receipt_method_id)
        /* J Rautiainen ACH Implementation */
      INTO   system_bank_payment_method
        FROM ar_system_parameters sp,
             ar_receipt_methods rm,
             ar_receipt_method_accounts rma,
             ce_bank_acct_uses_ou_v ba,
             ce_bank_accounts cba
       WHERE sp.irec_ba_receipt_method_id = rm.receipt_method_id
         AND rma.receipt_method_id = rm.receipt_method_id
         AND rma.remit_bank_acct_use_id = ba.bank_acct_use_id
         AND ba.bank_account_id = cba.bank_account_id
         AND (   cba.currency_code = p_currency_code
              OR cba.receipt_multi_currency_flag = 'Y'
             )
         AND SYSDATE < NVL (ba.end_date, SYSDATE + 1)
         AND SYSDATE BETWEEN rma.start_date AND NVL (rma.end_date, SYSDATE)
         AND SYSDATE BETWEEN rm.start_date AND NVL (rm.end_date, SYSDATE)
         AND  sp.org_id = nvl(p_org_id, sp.org_id);

      -- verify that Bank Account payment method is set up in AR_SYSTEM_PARAMETERS
      SELECT COUNT (arm.receipt_method_id)
        INTO customer_bank_payment_method
        FROM ar_receipt_methods arm,
             ra_cust_receipt_methods rcrm,
             ar_receipt_method_accounts arma,
             ce_bank_acct_uses_ou_v aba,
             ce_bank_accounts cba,
             ar_receipt_classes arc
       WHERE arm.receipt_method_id = rcrm.receipt_method_id
         AND arm.receipt_method_id = arma.receipt_method_id
         AND arm.receipt_class_id = arc.receipt_class_id
         AND rcrm.customer_id = p_customer_id
         AND arma.remit_bank_acct_use_id = aba.bank_acct_use_id
         AND aba.bank_account_id = cba.bank_account_id
         AND (   NVL (rcrm.site_use_id, p_customer_site_id) =
                                                            p_customer_site_id
              OR (p_customer_site_id IS NULL AND rcrm.site_use_id IS NULL)
             )
         AND (   cba.currency_code = p_currency_code
              OR cba.receipt_multi_currency_flag = 'Y'
             )
         AND (arc.remit_flag = 'Y' AND arc.confirm_flag = 'N')
         AND (   arc.creation_method_code = 'MANUAL'
              OR
                 --Bug#6109909
                 (    arm.payment_channel_code = 'BANK_ACCT_XFER'
                  AND arc.creation_method_code = 'AUTOMATIC'
                 )
             )
         -- AND       aba.set_of_books_id = arp_trx_global.system_info.system_parameters.set_of_books_id
         AND SYSDATE < NVL (aba.end_date, SYSDATE + 1)
         AND SYSDATE BETWEEN arm.start_date AND NVL (arm.end_date, SYSDATE)
         AND SYSDATE BETWEEN arma.start_date AND NVL (arma.end_date, SYSDATE)
         --Added below condition for bug-20387036
         AND sysdate between rcrm.start_date AND NVL(rcrm.end_date, sysdate) ;

           if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
                fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name, 'customer_bank_payment_method  :'||customer_bank_payment_method);
                fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name, 'system_bank_payment_method  :'||system_bank_payment_method);
           end if;

      IF (    (customer_bank_payment_method = 0)
          AND (system_bank_payment_method = 0)
         )
      THEN
         RETURN 0;
      ELSE
         RETURN 1;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_debug_info :=
               'Unknown exception. Value in profile OIR_BA_PMT_METHOD='
            || fnd_profile.VALUE ('OIR_BA_PMT_METHOD');
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         write_debug_and_log ('ERROR =>' || SQLERRM);
         write_debug_and_log ('-DEBUG_INFO-' || l_debug_info);
         RETURN 0;
   END is_bank_acc_payment_enabled;

/*============================================================
  | PUBLIC function save_payment_inst_info_wrapper
  |
  | DESCRIPTION
  |   This is a wrapper to return a VARCHAR2 instead of the Boolean returned
  |   by ARI_CONFIG.save_payment_instrument_info.
  |
  | PSEUDO CODE/LOGIC
  |
  | PARAMETERS
  |
  | KNOWN ISSUES
  |
  |
  |
  | NOTES
  |
  |
  |
  | MODIFICATION HISTORY
  | Date          Author       Description of Changes
  | 29-APR-2004   vnb          Created
  | 21-SEP-2004   vnb          Bug 3886652 - Customer Id and Customer Site Use Id added as params to ARI_CONFIG.save_payment_instrument_info
  +============================================================*/
   FUNCTION save_payment_inst_info_wrapper (
      p_customer_id            IN   VARCHAR2,
      p_customer_site_use_id   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      l_save_payment_inst_flag   VARCHAR2 (6);
   BEGIN
      -- Bug 3886652 - Customer Id and Customer Site Use Id added as params to ARI_CONFIG.save_payment_instrument_info
      IF (ari_utilities.save_payment_instrument_info
                                                 (p_customer_id,
                                                  NVL (p_customer_site_use_id,
                                                       -1
                                                      )
                                                 )
         )
      THEN
         l_save_payment_inst_flag := 'true';
      ELSE
         l_save_payment_inst_flag := 'false';
      END IF;

      RETURN l_save_payment_inst_flag;
   END save_payment_inst_info_wrapper;

   /*============================================================
    | PUBLIC function is_grace_days_enabled_wrapper
    |
    | DESCRIPTION
    |   This is a wrapper to return a VARCHAR2 instead of the Boolean returned
    |   by ARI_CONFIG.is_discount_grace_days_enabled.
    |
    | PSEUDO CODE/LOGIC
    |
    | PARAMETERS
    |
    | KNOWN ISSUES
    |
    |
    |
    | NOTES
    |
    |
    |
    | MODIFICATION HISTORY
    | Date          Author       Description of Changes
    | 28-APR-2004   vnb          Created
    +============================================================*/
   FUNCTION is_grace_days_enabled_wrapper
      RETURN VARCHAR2
   IS
      l_grace_days_flag   VARCHAR2 (2);
   BEGIN
      IF (ari_utilities.is_discount_grace_days_enabled)
      THEN
         l_grace_days_flag := 'Y';
      ELSE
         l_grace_days_flag := 'N';
      END IF;

      RETURN l_grace_days_flag;
   END is_grace_days_enabled_wrapper;

/*============================================================
  | PUBLIC function get_discount_wrapper
  |
  | DESCRIPTION
  |   This is a function that is a wrapper to call the AR API for calculating
  |   discounts.
  |
  | PSEUDO CODE/LOGIC
  |
  | PARAMETERS
  |
  | KNOWN ISSUES
  |
  |
  |
  | NOTES
  |
  |
  |
  | MODIFICATION HISTORY
  | Date          Author       Description of Changes
  | 19-JUL-2004   vnb          Created
  +============================================================*/
   FUNCTION get_discount_wrapper (
      p_ps_id               IN   ar_payment_schedules.payment_schedule_id%TYPE,
      p_in_applied_amount   IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_discount_amount        NUMBER;
      l_customer_id            NUMBER;
      l_customer_site_use_id   NUMBER;
      l_rem_amt_rcpt           NUMBER;
      l_rem_amt_inv            NUMBER;
      l_grace_days_flag        VARCHAR2 (2);
   BEGIN
      SELECT customer_id, customer_site_use_id
        INTO l_customer_id, l_customer_site_use_id
        FROM ar_payment_schedules
       WHERE payment_schedule_id = p_ps_id;

      -- Check if grace days have to be considered for discount.
      --l_grace_days_flag := is_grace_days_enabled_wrapper();
      l_grace_days_flag :=
         ari_utilities.is_discount_grace_days_enabled (l_customer_id,
                                                       l_customer_site_use_id
                                                      );
      arp_discounts_api.get_discount
                                  (p_ps_id                  => p_ps_id,
                                   p_apply_date             => TRUNC (SYSDATE),
                                   p_in_applied_amount      => p_in_applied_amount,
                                   p_grace_days_flag        => l_grace_days_flag,
                                   p_out_discount           => l_discount_amount,
                                   p_out_rem_amt_rcpt       => l_rem_amt_rcpt,
                                   p_out_rem_amt_inv        => l_rem_amt_inv,
                                   p_called_from            => 'OIR'
                                  );                 -- Added for Bug 18247364
      RETURN l_discount_amount;
   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            l_discount_amount := 0;
            write_debug_and_log
                           ('Unexpected Exception while calculating discount');
            write_debug_and_log ('- Payment Schedule Id: ' || p_ps_id);
            write_debug_and_log (SQLERRM);
            RETURN l_discount_amount;
         END;
   END;

/*============================================================
  | PUBLIC function write_error_messages
  |
  | DESCRIPTION
  |   This is a procedure that reads and returns the error messages
  |   from the message stack.
  |
  | PSEUDO CODE/LOGIC
  |
  | PARAMETERS
  |
  | KNOWN ISSUES
  |
  |
  |
  | NOTES
  |
  |
  |
  | MODIFICATION HISTORY
  | Date          Author       Description of Changes
  | 23-JUL-2004   vnb          Created
  +============================================================*/
   PROCEDURE write_error_messages (
      p_msg_data    IN OUT NOCOPY   VARCHAR2,
      p_msg_count   IN OUT NOCOPY   NUMBER
   )
   IS
      l_msg_data   VARCHAR2 (2000);
   BEGIN
      p_msg_data := p_msg_data || '*';
      p_msg_count := 0;

      LOOP
         l_msg_data := fnd_msg_pub.get (p_encoded => fnd_api.g_false);

         IF (l_msg_data IS NULL)
         THEN
            l_msg_data := fnd_msg_pub.get (p_encoded => fnd_api.g_true);

            IF (l_msg_data IS NULL)
            THEN
               EXIT;
            END IF;
         END IF;

         p_msg_data := p_msg_data || l_msg_data || '*';
         p_msg_count := p_msg_count + 1;
         write_debug_and_log (l_msg_data);
      END LOOP;
   END;

    /*=====================================================================
   | PROCEDURE reset_payment_amounts
   |
   | DESCRIPTION
   |   This function will reset the payment amounts on the Payment GT
   |   when the user clicks 'Reset to Defaults' button on Advanced Payment page
   |
   | PARAMETERS
   |   p_customer_id      IN     NUMBER
   |   p_site_use_id     IN     NUMBER DEFAULT NULL
   |
   | HISTORY
   |   20-JAN-2005     vnb      Created
   |
   +=====================================================================*/
   PROCEDURE reset_payment_amounts (
      p_customer_id    IN   NUMBER,
      p_site_use_id    IN   NUMBER DEFAULT NULL,
      p_payment_type   IN   VARCHAR2 DEFAULT NULL,
      p_lookup_code    IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_total_service_charge   NUMBER;
      l_procedure_name         VARCHAR2 (50);
      l_debug_info             VARCHAR2 (200);
   BEGIN
      --Assign default values
      l_total_service_charge := 0;
      l_procedure_name := '.reset_payment_amounts';
      SAVEPOINT reset_payment_amounts_sp;
-----------------------------------------------------------------------------------------
      l_debug_info :=
          'Update transaction list with original discount and payment amount';

-----------------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

      --Striping by currency code is not required because
      --it is not possible to navigate to Payment page with multiple currencies
      --in the Transaction List for a cusomer context
      UPDATE ar_irec_payment_list_gt
         SET discount_amount = original_discount_amt,
             payment_amt =
                  amount_due_remaining
                - original_discount_amt
                - NVL (dispute_amt, 0)
       WHERE customer_id = p_customer_id
         AND customer_site_use_id =
                NVL (DECODE (p_site_use_id, -1, NULL, p_site_use_id),
                     customer_site_use_id
                    );

-----------------------------------------------------------------------------------------
      l_debug_info := 'Compute service charge';

-----------------------------------------------------------------------------------------
      IF (pg_debug = 'Y')
      THEN
         arp_standard.DEBUG (l_debug_info);
      END IF;

      l_total_service_charge :=
         get_service_charge (p_customer_id,
                             p_site_use_id,
                             p_payment_type,
                             p_lookup_code
                            );
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         write_debug_and_log
            ('Unexpected Exception while resetting payment and discount amounts'
            );
         write_debug_and_log ('- Customer Id: ' || p_customer_id);
         write_debug_and_log ('- Customer Site Id: ' || p_site_use_id);
         write_debug_and_log (   '- Total Service charge: '
                              || l_total_service_charge
                             );
         write_debug_and_log (SQLERRM);
         ROLLBACK TO reset_payment_amounts_sp;
   END reset_payment_amounts;

/*=====================================================================
 | FUNCTION get_pymt_amnt_due_remaining
 |
 | DESCRIPTION
 |   This function will calculate the remianing amount for a
 |   payment that has been selected for apply credit andd return the
 |   total amount dure remaining that can be applied.
 |
 | HISTORY
 |
 +=====================================================================*/
   FUNCTION get_pymt_amnt_due_remaining (p_cash_receipt_id IN NUMBER)
      RETURN NUMBER
   IS
      l_amount_due_remaining   NUMBER;
   BEGIN
      SELECT -SUM (app.amount_applied)
        INTO l_amount_due_remaining
        FROM ar_receivable_applications app
       WHERE NVL (app.confirmed_flag, 'Y') = 'Y'
         AND app.status = 'UNAPP'
         AND app.cash_receipt_id = p_cash_receipt_id;

      RETURN l_amount_due_remaining;
   END get_pymt_amnt_due_remaining;

/*============================================================
 | procedure update_cc_bill_to_site
 |
 | DESCRIPTION
 |   Creates/Updates Credit card bill to location with the given details
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date          Author       Description of Changes
 | 17-Aug-2005   rsinthre     Created
 +============================================================*/
   PROCEDURE update_cc_bill_to_site (
      p_cc_location_rec      IN              hz_location_v2pub.location_rec_type,
      x_cc_bill_to_site_id   IN              NUMBER,
      x_return_status        OUT NOCOPY      VARCHAR2,
      x_msg_count            OUT NOCOPY      NUMBER,
      x_msg_data             OUT NOCOPY      VARCHAR2
   )
   IS
      l_location_id             NUMBER (15, 0);
      l_location_rec            hz_location_v2pub.location_rec_type;
      l_party_site_rec          hz_party_site_v2pub.party_site_rec_type;
      l_party_site_number       VARCHAR2 (30);
      l_object_version_number   NUMBER (15, 0);

      CURSOR location_id_cur
      IS
         SELECT hps.location_id, hl.object_version_number
           FROM hz_party_sites hps, hz_locations hl
          WHERE party_site_id = x_cc_bill_to_site_id
            AND hps.location_id = hl.location_id;

      location_id_rec           location_id_cur%ROWTYPE;
      l_procedure_name          VARCHAR2 (30);
      l_debug_info              VARCHAR2 (200);
   BEGIN
      l_procedure_name := '.update_cc_bill_to_site';
-----------------------------------------------------------------------------------------
      l_debug_info :=
         'Call TCA update location - update_location - to update location for CC';
-----------------------------------------------------------------------------------------
      write_debug_and_log ('Site_id_to_update' || x_cc_bill_to_site_id);

--Get LocationId from PartySiteId and update the location
      OPEN location_id_cur;

      FETCH location_id_cur
       INTO location_id_rec;

      IF (location_id_cur%FOUND)
      THEN
         l_location_id := location_id_rec.location_id;
         l_object_version_number := location_id_rec.object_version_number;
      ELSE
         write_debug_and_log (   'No Location found for site:'
                              || x_cc_bill_to_site_id
                             );
         x_return_status := fnd_api.g_ret_sts_error;
         write_error_messages (x_msg_data, x_msg_count);
         RETURN;
      END IF;

      CLOSE location_id_cur;

      write_debug_and_log ('Loaction id to update:' || l_location_id);
      l_location_rec.location_id := l_location_id;
      l_location_rec.country := p_cc_location_rec.country;
      l_location_rec.address1 := p_cc_location_rec.address1;
      l_location_rec.address2 := p_cc_location_rec.address2;
      l_location_rec.address3 := p_cc_location_rec.address3;
      l_location_rec.address4 := p_cc_location_rec.address4;
      l_location_rec.city := p_cc_location_rec.city;
      l_location_rec.postal_code := p_cc_location_rec.postal_code;
      l_location_rec.state := p_cc_location_rec.state;
      l_location_rec.county := p_cc_location_rec.county;
      hz_location_v2pub.update_location
                          (p_init_msg_list              => fnd_api.g_true,
                           p_location_rec               => l_location_rec,
                           p_object_version_number      => l_object_version_number,
                           x_return_status              => x_return_status,
                           x_msg_count                  => x_msg_count,
                           x_msg_data                   => x_msg_data
                          );

      IF (x_return_status <> fnd_api.g_ret_sts_success)
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         write_error_messages (x_msg_data, x_msg_count);
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         write_debug_and_log ('l_location_id' || l_location_id);
         write_debug_and_log ('- Return Status: ' || x_return_status);
         write_debug_and_log (SQLERRM);
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END update_cc_bill_to_site;

   /*=====================================================================
   | PROCEDURE get_payment_channel_attribs
   |
   | DESCRIPTION
   |   Gets payment channel attribute usages
   |
   | PARAMETERS
   |   p_channel_code  IN        VARCHAR2
   |   x_return_status    OUT NOCOPY  VARCHAR2
   |   x_cvv_use       OUT NOCOPY  VARCHAR2
   |   x_billing_addr_use OUT NOCOPY  VARCHAR2
   |   x_msg_count        OUT NOCOPY  NUMBER
   |   x_msg_data         OUT NOCOPY  VARCHAR2
   |
   | HISTORY
   |   20-SEP-2006     abathini      Created
   |
   +=====================================================================*/
   PROCEDURE get_payment_channel_attribs (
      p_channel_code       IN              VARCHAR2,
      x_return_status      OUT NOCOPY      VARCHAR2,
      x_cvv_use            OUT NOCOPY      VARCHAR2,
      x_billing_addr_use   OUT NOCOPY      VARCHAR2,
      x_msg_count          OUT NOCOPY      NUMBER,
      x_msg_data           OUT NOCOPY      VARCHAR2
   )
   IS
      userectype         iby_fndcpt_setup_pub.pmtchannel_attribuses_rec_type;
      resrectype         iby_fndcpt_common_pub.result_rec_type;
      l_procedure_name   VARCHAR2 (50);
      l_debug_info       VARCHAR2 (200);
   BEGIN
      l_procedure_name := '.get_payment_channel_attribs';
-----------------------------------------------------------------------------------------
      l_debug_info :=
         'Call IBY_FNDCPT_SETUP_PUB.Get_Payment_Channel_Attribs - to get payment channel attribute usages';
-----------------------------------------------------------------------------------------
      iby_fndcpt_setup_pub.get_payment_channel_attribs
                                        (p_api_version              => 1.0,
                                         x_return_status            => x_return_status,
                                         x_msg_count                => x_msg_count,
                                         x_msg_data                 => x_msg_data,
                                         p_channel_code             => p_channel_code,
                                         x_channel_attrib_uses      => userectype,
                                         x_response                 => resrectype
                                        );
      x_cvv_use := userectype.instr_seccode_use;
      x_billing_addr_use := userectype.instr_billing_address;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         write_debug_and_log ('p_channel_code' || p_channel_code);
         write_debug_and_log ('- Return Status: ' || x_return_status);
         write_debug_and_log (SQLERRM);
         fnd_message.set_name ('AR', 'ARI_REG_DISPLAY_UNEXP_ERROR');
         fnd_message.set_token ('PROCEDURE', g_pkg_name || l_procedure_name);
         fnd_message.set_token ('ERROR', SQLERRM);
         fnd_message.set_token ('DEBUG_INFO', l_debug_info);
         fnd_msg_pub.ADD;
   END get_payment_channel_attribs;

/*=====================================================================
 | PROCEDURE update_invoice_payment_status
 |
 | DESCRIPTION
 |   This procedure will update the PAYMENT_APPROVAL column in ar_payment_schedules
 |   with the value p_inv_pay_status for the records in p_payment_schedule_id_list
 |
 | PARAMETERS
 |   p_payment_schedule_id_list     IN     Inv_list_table_type
 |   p_inv_pay_status            IN     VARCHAR2
 |
 | HISTORY
 |   17-FEB-2007     abathini          Created
 |
 +=====================================================================*/
   PROCEDURE update_invoice_payment_status (
      p_payment_schedule_id_list   IN              inv_list_table_type,
      p_inv_pay_status             IN              VARCHAR2,
      x_return_status              OUT NOCOPY      VARCHAR2,
      x_msg_count                  OUT NOCOPY      NUMBER,
      x_msg_data                   OUT NOCOPY      VARCHAR2
   )
   IS
      l_last_update_login   NUMBER (15);
      l_last_update_date    DATE;
      l_last_updated_by     NUMBER (15);
   BEGIN
      l_last_update_login := fnd_global.login_id;
      l_last_update_date := SYSDATE;
      l_last_updated_by := fnd_global.user_id;
      FORALL trx IN p_payment_schedule_id_list.FIRST .. p_payment_schedule_id_list.LAST
         UPDATE ar_payment_schedules
            SET payment_approval = p_inv_pay_status,
                last_update_date = l_last_update_date,
                last_updated_by = l_last_updated_by,
                last_update_login = l_last_update_login
          WHERE payment_schedule_id = p_payment_schedule_id_list (trx);
      x_return_status := fnd_api.g_ret_sts_success;
      x_msg_count := 0;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         fnd_msg_pub.count_and_get (p_encoded      => fnd_api.g_false,
                                    p_count        => x_msg_count,
                                    p_data         => x_msg_data
                                   );
   END update_invoice_payment_status;

/*=====================================================================
 | FUNCTION get_customer_site_use_id
 |
 | DESCRIPTION
 | This function checks if the user has access to the primary bill to site
 | of the customer. If yes, then returns that site id.
 | else, checks if the transactions selected by the user belongs
 | to a same site. If yes, then return that site id else, returns -1.
 |
 | PARAMETERS
 |   p_session_id  IN   NUMBER
 |   p_customer_id IN   NUMBER
 |
 | RETURN
 |   l_customer_site_use_id  NUMBER
 | HISTORY
 |   29-Oct-2009     rsinthre              Created
 |
 +=====================================================================*/
   FUNCTION get_customer_site_use_id (
      p_session_id    IN   NUMBER,
      p_customer_id   IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_customer_site_use_id   NUMBER;
      l_debug_info             VARCHAR2 (200);
      l_procedure_name         VARCHAR2 (30);
      e_no_rows_in_gt          EXCEPTION;

      CURSOR get_cust_site_use_id_cur
      IS
         SELECT DISTINCT pay_for_customer_site_id
                    FROM ar_irec_payment_list_gt
                   WHERE customer_id = p_customer_id;
   BEGIN
      l_procedure_name := '.get_customer_site_use_id';
      l_customer_site_use_id := NULL;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         'Begin+'
                        );
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'p_session_id='
                         || p_session_id
                         || 'p_user_id='
                         || fnd_global.user_id
                         || 'p_customer_id='
                         || p_customer_id
                        );
      END IF;

---------------------------------------------------------------------------
      l_debug_info :=
                 'Check if the user has access to the primary bill to site id';

---------------------------------------------------------------------------
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                         l_debug_info
                        );
      END IF;

      BEGIN
         SELECT usite.customer_site_use_id
           INTO l_customer_site_use_id
           FROM ar_irec_user_acct_sites_all usite, hz_cust_site_uses hzcsite
          WHERE usite.session_id = p_session_id
            AND usite.customer_id = p_customer_id
            AND usite.user_id = fnd_global.user_id
            AND hzcsite.site_use_id = usite.customer_site_use_id
            AND hzcsite.primary_flag = 'Y'
            AND hzcsite.site_use_code = 'BILL_TO'
            AND hzcsite.status = 'A';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_customer_site_use_id := NULL;
      END;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING
            (fnd_log.level_statement,
             g_pkg_name || l_procedure_name,
                'Check for acess to the Primary bill to site returned site id='
             || l_customer_site_use_id
            );
      END IF;

      IF (l_customer_site_use_id IS NULL)
      THEN
         /* So, user does not have access to primary bill to site
           Check, if the selected transactions belong to a same site. If yes, then return that site id else return -1.
         */
         OPEN get_cust_site_use_id_cur;

         LOOP
            FETCH get_cust_site_use_id_cur
             INTO l_customer_site_use_id;

            IF get_cust_site_use_id_cur%ROWCOUNT > 1
            THEN
               IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level
                  )
               THEN
                  fnd_log.STRING
                     (fnd_log.level_statement,
                      g_pkg_name || l_procedure_name,
                      'The selected transactions belong to more than one site'
                     );
               END IF;

               l_customer_site_use_id := -1;
               EXIT;
            ELSIF get_cust_site_use_id_cur%ROWCOUNT = 0
            THEN
               IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level
                  )
               THEN
                  fnd_log.STRING
                          (fnd_log.level_statement,
                           g_pkg_name || l_procedure_name,
                           'Query on ar_irec_payment_list_gt returned 0 rows'
                          );
               END IF;

               RAISE e_no_rows_in_gt;
               EXIT;
            END IF;

            EXIT WHEN get_cust_site_use_id_cur%NOTFOUND
                  OR get_cust_site_use_id_cur%NOTFOUND IS NULL;
         END LOOP;

         CLOSE get_cust_site_use_id_cur;
      END IF;

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
      THEN
         fnd_log.STRING (fnd_log.level_statement,
                         g_pkg_name || l_procedure_name,
                            'Return val: l_customer_site_use_id='
                         || l_customer_site_use_id
                        );
      END IF;

      RETURN l_customer_site_use_id;
   EXCEPTION
      WHEN e_no_rows_in_gt
      THEN
         write_debug_and_log
            (   'No rows present in ar_irec_payment_list_gt for the given customer in '
             || g_pkg_name
             || l_procedure_name
            );
         write_debug_and_log ('p_session_id: ' || p_session_id);
         write_debug_and_log ('p_user_id: ' || fnd_global.user_id);
         write_debug_and_log ('p_customer_id: ' || p_customer_id);
      WHEN OTHERS
      THEN
         write_debug_and_log (   'Unexpected Exception in '
                              || g_pkg_name
                              || l_procedure_name
                             );
         write_debug_and_log ('ERROR =>' || SQLERRM);
         write_debug_and_log ('p_session_id: ' || p_session_id);
         write_debug_and_log ('p_user_id: ' || fnd_global.user_id);
         write_debug_and_log ('p_customer_id: ' || p_customer_id);
   END get_customer_site_use_id;

   /*============================================================
    | PUBLIC function get_future_discount_wrapper
    |
    | DESCRIPTION
    |   This is a function that is a wrapper to call the AR API for calculating
    |   future discounts.
    |
    | PSEUDO CODE/LOGIC
    |
    | PARAMETERS
    |
    | KNOWN ISSUES
    |
    |
    |
    | NOTES
    |
    |
    |
    | MODIFICATION HISTORY
    | Date          Author       Description of Changes
    | 06-MAY-2011   rsinthre     Created for bug 10106518
    | 12-Aug-2014   melapaku     Bug 19331908 - RPC-AUG14:Discount alerts at home page not shown for newly created
    |                                           customers
    +============================================================*/
   FUNCTION get_future_discount_wrapper (
      p_ps_id               IN   ar_payment_schedules.payment_schedule_id%TYPE,
      p_in_applied_amount   IN   NUMBER,
      p_discount_date       IN   DATE DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_discount_amount   NUMBER;
      l_rem_amt_rcpt      NUMBER;
      l_rem_amt_inv       NUMBER;
      l_grace_days_flag   VARCHAR2 (2);
      l_discount_date     DATE;
      -- Added for Bug 19331908
      l_customer_id     NUMBER;
      l_customer_site_use_id NUMBER;
   BEGIN
             -- Added below query for Bug 19331908
               SELECT CUSTOMER_ID, CUSTOMER_SITE_USE_ID
                 INTO  l_customer_id, l_customer_site_use_id
                 FROM  ar_payment_schedules
                WHERE PAYMENT_SCHEDULE_ID = p_ps_id;
      -- Check if grace days have to be considered for discount.
      -- Modified for Bug 19331908
      l_grace_days_flag := ARI_UTILITIES.is_discount_grace_days_enabled(l_customer_id,l_customer_site_use_id);

      IF (p_discount_date IS NULL)
      THEN
         l_discount_date := TRUNC (SYSDATE);
      ELSE
         l_discount_date := TRUNC (p_discount_date);
      END IF;

      arp_discounts_api.get_discount
                                  (p_ps_id                  => p_ps_id,
                                   p_apply_date             => l_discount_date,
                                   p_in_applied_amount      => p_in_applied_amount,
                                   p_grace_days_flag        => l_grace_days_flag,
                                   p_out_discount           => l_discount_amount,
                                   p_out_rem_amt_rcpt       => l_rem_amt_rcpt,
                                   p_out_rem_amt_inv        => l_rem_amt_inv,
                                   p_called_from            => 'OIR'
                                  );                 -- Added for Bug 18247364
      RETURN l_discount_amount;
   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            l_discount_amount := 0;
            write_debug_and_log
                    ('Unexpected Exception while calculating future discount');
            write_debug_and_log ('- Payment Schedule Id: ' || p_ps_id);
            write_debug_and_log (SQLERRM);
            RETURN l_discount_amount;
         END;
   END;

 --Included the procedure VERBAL_AUTH_CODE for E1294 by Madankumar J,Wipro Tech
-- +==========================================================================+
-- | Name : VERBAL_AUTH_CODE                                                  |
-- | Description : This procedure will validate the user if he is a collector |
-- |                                                                          |
-- |                                                                          |
-- | Parameters :   p_user_name                                               |
-- |                                                                          |
-- | Returns    :   x_return_value                                            |
-- +==========================================================================+
   PROCEDURE verbal_auth_code (
      p_user_name      IN       VARCHAR2,
      x_return_value   OUT      VARCHAR2
   )
   AS
      ln_count       NUMBER;
      ln_count1      NUMBER;   --Added for the Defect 2462(CR 247), for E1294
      lc_error_loc   VARCHAR2 (150);
      ln_resp_id     NUMBER;   --Added for the Defect 2462(CR 247), for E1294
   BEGIN
      lc_error_loc :=
         'To Check if the User is a Collector and attached to the proper responsibility';
      ln_resp_id := fnd_profile.VALUE ('RESP_ID');

      --Added for the Defect 2462(CR 247), for E1294
      SELECT COUNT (1)
        INTO ln_count
        FROM jtf_rs_resource_extns jrre, fnd_user fu, ar_collectors arc
       WHERE fu.user_name = arc.NAME
         AND jrre.user_id = fu.user_id
         AND fu.user_name = p_user_name
         AND TRUNC (NVL (jrre.end_date_active, SYSDATE + 1)) > TRUNC (SYSDATE)
         AND TRUNC (NVL (fu.end_date, SYSDATE + 1)) > TRUNC (SYSDATE);

      SELECT COUNT (1)          --Added for the Defect 2462(CR 247), for E1294
        INTO ln_count1
        FROM fnd_responsibility_tl frt,
             xx_fin_translatedefinition xftd,
             xx_fin_translatevalues xftv
       WHERE xftv.source_value1 = 'OD Verbal Auth Resp'
         AND frt.responsibility_id = ln_resp_id
         AND frt.responsibility_name = xftv.target_value1
         AND xftv.enabled_flag = 'Y'
         AND xftd.translate_id = xftv.translate_id
         AND TRUNC (NVL (xftv.end_date_active, SYSDATE + 1)) > TRUNC (SYSDATE);

      ln_count := 1;
      ln_count1 := 1;

      IF ((ln_count = 0) OR (ln_count1 = 0))
      THEN
         --Modified to include ln_count1 for the Defect 2462(CR 247), for E1294
         x_return_value := 'FALSE';
      ELSIF ((ln_count > 0) AND (ln_count1 > 0))
      THEN
         --Modified to include ln_count1 for the Defect 2462(CR 247), for E1294
         x_return_value := 'TRUE';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_value :=
                         'User Name  - ' || p_user_name || '  -  ' || SQLERRM;
         xx_com_error_log_pub.log_error
                   (p_program_type                => 'PROCEDURE',
                    p_attribute15                => 'XX_AR_IREC_PAYMENTS',
                    p_module_name                 => 'AR',
                    p_error_location              =>    'Error at '
                                                     || lc_error_loc,
                    p_error_message_count         => 1,
                    p_error_message_code          => 'E',
                    p_error_message               => x_return_value,
                    p_error_message_severity      => 'Major',
                    p_notify_flag                 => 'N',
                    p_object_type                 => 'Verbal Auth'
                   );
   END verbal_auth_code;



   PROCEDURE insert_irec_ext (p_cash_receipt_id IN NUMBER,
                              p_confirmemail            IN  VARCHAR2) IS

   BEGIN


      INSERT INTO XX_AR_CASH_RECEIPTS_IREC_EXT(
                    cash_receipt_id
                   ,CONFIRMEMAIL
                    ,creation_date
                   ,created_by
                   ,last_update_date
                   ,last_updated_by
                   ,last_update_login
                  ) VALUES (
                    p_cash_receipt_id
                   ,p_confirmemail
                   ,trunc(sysdate)
                   ,fnd_global.user_id
                   ,trunc(sysdate)
                   ,fnd_global.user_id
                   ,fnd_global.login_id
                  );

  EXCEPTION
  when OTHERS then
       RAISE;
  END insert_irec_ext;


  PROCEDURE get_token_wrapper (
   p_account_number    IN              VARCHAR2,
   p_expiration_date   IN              DATE,
   x_token             OUT NOCOPY      VARCHAR2,
   x_status            OUT NOCOPY      VARCHAR2,
   x_ERROR_MSG            IN OUT NOCOPY VARCHAR2,
    x_ERROR_CODE           IN OUT NOCOPY VARCHAR2
)
IS
   l_procedure_name       VARCHAR2 (30);
   l_commit               VARCHAR2 (30)   DEFAULT fnd_api.g_false;
   p_error_msg            VARCHAR2 (1000) := NULL;
   p_error_code           VARCHAR2 (200)  := NULL;
   p_oapfaction           VARCHAR2 (60)   := NULL;
   p_oapftransactionid    VARCHAR2 (60)   := NULL;
   p_oapfnlslang          VARCHAR2 (30)   := NULL;
   p_oapfpmtinstrid       VARCHAR2 (30)   := NULL;
   p_oapfpmtfactorflag    VARCHAR2 (10)   := NULL;
   p_oapfpmtinstrexp      VARCHAR2 (30)   := NULL;
   p_oapforgtype          VARCHAR2 (30)   := NULL;
   p_oapftrxnref          VARCHAR2 (60)   := NULL;
   p_oapfpmtinstrdbid     VARCHAR2 (60)   := NULL;
   p_oapfpmtchannelcode   VARCHAR2 (30)   := NULL;
   p_oapfauthtype         VARCHAR2 (60)   := NULL;
   p_oapftrxnmid          VARCHAR2 (60)   := NULL;
   p_oapfstoreid          VARCHAR2 (30)   := NULL;
   p_oapfprice            VARCHAR2 (30)   := NULL;
   p_oapforderid          VARCHAR2 (60)   := NULL;
   p_oapfcurr             VARCHAR2 (15)   := NULL;
   p_oapfretry            VARCHAR2 (15)   := NULL;
   p_oapfcvv2             VARCHAR2 (15)   := NULL;
   x_token_flag           VARCHAR2 (1)    := 'N';
  -- x_error_msg            VARCHAR2 (4000);
BEGIN
   x_status := fnd_api.g_ret_sts_success;
   l_procedure_name := '.get_token_wrapper';

   IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
   THEN
      fnd_log.STRING (fnd_log.level_statement,
                      g_pkg_name || l_procedure_name,
                      'in get_token_wrapper (+)'
                     );
   END IF;

   /*xx_fin_irec_cc_token_pkg.get_token
                                (p_error_msg               => x_error_msg,
                                 p_error_code              => x_error_code,
                                 p_oapfaction              => p_oapfaction,
                                 p_oapftransactionid       => p_oapftransactionid,
                                 p_oapfnlslang             => p_oapfnlslang,
                                 p_oapfpmtinstrid          => p_account_number,
                                 p_oapfpmtfactorflag       => p_oapfpmtfactorflag,
                                 p_oapfpmtinstrexp         => p_expiration_date,
                                 p_oapforgtype             => p_oapforgtype,
                                 p_oapftrxnref             => p_oapftrxnref,
                                 p_oapfpmtinstrdbid        => p_oapfpmtinstrdbid,
                                 p_oapfpmtchannelcode      => p_oapfpmtchannelcode,
                                 p_oapfauthtype            => p_oapfauthtype,
                                 p_oapftrxnmid             => p_oapftrxnmid,
                                 p_oapfstoreid             => p_oapfstoreid,
                                 p_oapfprice               => p_oapfprice,
                                 p_oapforderid             => p_oapforderid,
                                 p_oapfcurr                => p_oapfcurr,
                                 p_oapfretry               => p_oapfretry,
                                 p_oapfcvv2                => p_oapfcvv2,
                                 x_token                   => x_token,
                                 x_token_flag              => x_token_flag
                                );*/ --commented code for NAIT-129669

  --Code chnages done for NAIT-129669
  xx_fin_irec_cc_token_pkg.get_token_ecomm(p_account_number ,
                                           p_expiration_date,
                                           x_token  ,
                                           x_token_flag,
                                           x_error_msg,
                                           x_error_code);
   IF (x_token_flag <> 'Y')
   THEN
     IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
     THEN
       x_status := fnd_api.g_ret_sts_error;
       x_error_msg :=  'Unexpected Exception while getting token in xx_fin_irec_cc_token_pkg.get_token '||x_error_msg;

       fnd_log.STRING (fnd_log.level_statement,
                        'x_error_msg :'||x_error_msg||' '||'x_error_code :'||x_error_code,
                        'get_token_wrapper'
                       );
     END IF;
   END IF;

   IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
   THEN

      fnd_log.STRING (fnd_log.level_statement,
                      g_pkg_name || l_procedure_name,
                      'in get_token_wrapper (-)'
                     );
   END IF;

EXCEPTION
   WHEN OTHERS
   THEN
      x_status := fnd_api.g_ret_sts_error;
      x_error_msg :=  'Unexpected Exception'|| SQLERRM ||' in '
                           || g_pkg_name
                           || l_procedure_name;
      write_debug_and_log (   'Unexpected Exception in '
                           || g_pkg_name
                           || l_procedure_name
                          );
END get_token_wrapper;

END XX_AR_IREC_PAYMENTS;
/