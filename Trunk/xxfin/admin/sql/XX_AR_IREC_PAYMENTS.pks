SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE xx_ar_irec_payments
AUTHID CURRENT_USER AS
/* $Header: ARIRPMTB.pls 120.24.12020000.10 2015/02/16 14:09:59 gnramasa ship $ */

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name     :   Verbal Auth                                            |
-- | Rice id  :   E1294                                                  |
-- | Description : Modified the package for Voice Authorization          |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       10-Aug-2007   Madankumar J         Initial version         |
-- |                        Wipro Technologies                           |
-- |                                                                     |
-- |1.1       03-NOv-2007   Madankumar J         Defect 2462(CR 247)     |
-- |                                                                     |
-- |1.2       28-Mar-2008   Madankumar J         Version updation due to |
-- |                                             patch application.      |
-- |                                             Standard Package is     |
-- |                                             modified to include the |
-- |                                             changes for verbal Auth |
-- |1.3       13-Jun-2008   Sambasiva Reddy D    Defect 6326             |
-- |1.4       12-Jan-2013   Jay Gupta            Changes for CR868 - ePay|
-- |2.0       12-Aug-2013   Sridevi K            Considered R12 standard |
-- |                                             package and retrofitted |
-- |                                             for R12 upgrade         |
-- |3.0       16-Jan-2015   Sridevi K            For Patch_19052386-B    |
-- |4.0       4-Mar-2015    Sridevi K            Modified for CR1120     |
-- |4.1       30-Aug-2016   Vasu Raparla         Considered standard 12.2.5|
-- |                                             version and retrofitted   |
-- |                                             for R12.2.5 upgrade       |
-- |4.2       5-OCT-2016    Sridevi K            Modified for Vantiv     |
-- +=====================================================================+

/*============================================================================+
 | $Header: ARIRPMTS.pls 120.24.12020000.10 2015/02/16 14:09:59 gnramasa ship $
 +============================================================================+
 |  Copyright (c) 2000, 2015 Oracle Corporation Redwood Shores, California, USA     |
 |                          All rights reserved.                              |
 +============================================================================+
 | PACKAGE          AR_IREC_PAYMENTS
 |
 | DESCRIPTION
 |      iReceivables Payments Functionality.
 |
 | EXTERNAL PUBLIC VARIABLES
 |
 | EXTERNAL DATATYPES
 |
 | KNOWN ISSUES
 |      Enter business functionality which was de-scoped as part of the
 |      implementation
 |
 | REFERENCES
 |      High Level Design document Reference     :
 |
 |      Detailed Level Design document Reference :
 |
 | NOTES
 |      Any interesting aspect of the code in the package body which needs
 |      to be stated
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 22-JAN-2001           O. Steinmeier     Created
 | 26-APR-2004           vnb               Bug # 3467287 - Modified procedures/functions to
 |					   stripe the Transaction List by customer and customer site.
 | 19-JUL-2004           vnb               Bug 3718315 - Added wrapper function for calculating discounts
 | 23-JUL-2004           vnb               Bug 3630101 - Payment process setup errors to be displayed to internal user.
 | 21-SEP-2004           vnb               Bug 3886652 - Customer and customer site added as params to save_payment_instrument_info_wrapper
 | 03-JAN-2005           vnb               Bug 4071551 - Performance issues while inserting records into transaction list
 | 20-Jan-2005           vnb               Bug 4117211 - Added code for resetting payment amounts when 'Reset to Defaults' button is clicked
 | 21-Jan-2005		 rsinthre  	   Bug 4080357 - Added a procedure create_open_credit_pay_list to insert open credits/payments in payment list GT
 | 26-MAY-2005		 rsinthre	   Bug 4392371 - OIR needs to support cross customer payment
 | 20-Oct-2005  	 rsinthre          Bug 4673563 - Error making credit card payment
 | 04-Aug-2009           avepati           Bug 8664350  - R12 UNABLE TO LOAD FEDERAL RESERVE ACH PARTICAIPANT DATA
 | 22-Mar-2010           nkanchan          Bug 8293098 - Service change based on credit card types
 | 27-Apr-2011           avepati           Bug 9910157 - AUTHORIZATION CODE NOT SEEN IN IRECEIVABLES FOR CREDIT CARD PAYMENTS
 | 27-Dec-2012           melapaku          Bug 14797865- ccard billing address defaulting and q.pymt page appearance
 |                                                       inconsistency
 | 06-Feb-2013           melapaku          Bug16262617 - cannot remove end date entered via ireceivables pay function
 | 14-Mar-2013           melapaku          Bug16471455 - OIR Payment Audit History Feature
 | 29-May-2014           melapaku          Bug18832462 - Future date payment for double discount and disputed invoices
 | 23-Jul-2014           gnramasa          Bug17475275 - TST1223:CREDIT CARD DETAILS BEING SHOWN TWICE, WHEN PAID PART BY PART
 | 14-Oct-2014           melapaku          Bug19800178 - IRECEIVABLES LEADING ZERO REMOVED IN CVV CODE
 | 16-Feb-2015           gnramasa          Bug 20502416 - IREC- CODE: INCONSISTENT BEHAVIOR OF PAY BUTTON IN ACCNT DETAIL AND TRX DETAIL
 *============================================================================*/

 /*=======================================================================+
 |  Declare PUBLIC Data Types and Variables
 +=======================================================================*/
   temp_variable1   VARCHAR2 (10);
/*=======================================================================+
 |  Declare PUBLIC Exceptions
 +=======================================================================*/
   temp_exception   EXCEPTION;

/*========================================================================
 | PUBLIC function get_credit_card_type
 |
 | DESCRIPTION
 |      Determines if a given credit card is valid.
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |      This function uses arp_bank_pkg.val_credit_card function.
 |      This is essentially a cover for that function right now, and is
 |      designed to isolate iReceivables from future AR/CE API changes.
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
      RETURN NUMBER;

   FUNCTION get_pymt_amnt_due_remaining (p_cash_receipt_id IN NUMBER)
      RETURN NUMBER;

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
 |      creditcard_number   IN      Creditcard number
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
 |
 *=======================================================================*/
   FUNCTION get_credit_card_type (p_credit_card_number IN VARCHAR2)
      RETURN VARCHAR2;

   PRAGMA RESTRICT_REFERENCES (get_credit_card_type, WNDS);

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
 |      Return Value: 0 if payment is not allowed,
 |                    1 if payment is allowed.
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
   FUNCTION payment_allowed (
      p_payment_schedule_id   IN   NUMBER,
      p_customer_id           IN   NUMBER,
      p_customer_site_id      IN   NUMBER,
      p_org_id                IN   NUMBER Default null
   )
      RETURN NUMBER;

-- deprecated function: BOOLEAN cannot be used in SQL statements
/* 16-Feb-2015           gnramasa  Bug 20502416 - IREC- CODE: INCONSISTENT BEHAVIOR OF PAY BUTTON IN ACCNT DETAIL AND TRX DETAIL */
   FUNCTION allow_payment (
      p_payment_schedule_id   IN   NUMBER,
      p_customer_id           IN   NUMBER,
      p_customer_site_id      IN   NUMBER,
      p_org_id                IN   NUMBER  Default null
   )
      RETURN BOOLEAN;

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
 |
 | RETURNS
 |      p_bank_account_num_masked Masked credit card number
 |      p_credit_card_type        Type of the credit card
 |      p_expiry_month            Credit card expiry month
 |      p_expiry_year             Credit card expiry year
 |      p_credit_card_expired     '1' if credit card has expired, '0' otherwise
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
 | 22-JAN-2001           J Rautiainen      Created
 | 20-May-2004    hikumar        Added Currency Parameter
 | 04-Jan-2005          vnb                Bug 3928412 - RA_CUSTOMERS obsolete;removed reference to it
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
   );

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
 | 06-Feb-2013           melapaku          Bug16262617 - cannot remove end date entered via ireceivables pay function
 | 23-Jul-2014           gnramasa          Bug17475275 - TST1223:CREDIT CARD DETAILS BEING SHOWN TWICE, WHEN PAID PART BY PART
 |                                         Added new parameter p_instr_assignment_id
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
   );

/*========================================================================
 | PUBLIC function is_credit_card_expired
 |
 | DESCRIPTION
 |      Checks whether credit card has expired
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_expiration_date  IN DATE
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
      RETURN NUMBER;

   PRAGMA RESTRICT_REFERENCES (is_credit_card_expired, WNDS);

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
 |
 *=======================================================================*/
   PROCEDURE store_last_used_ba (
      p_customer_id       IN              NUMBER,
      p_bank_account_id   IN              NUMBER,
      p_instr_type        IN              VARCHAR2 := 'BA',
      p_status            OUT NOCOPY      VARCHAR2
   );

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
 |      p_account_holder_name  IN VARCHAR2
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
 | 15-Apr-2002            AMMISHRA         Bug:2210677, passed account
 |                                         holder name as a parameter.
 *=======================================================================*/
   FUNCTION is_bank_account_duplicate (
      p_bank_account_number   IN   VARCHAR2,
      p_routing_number        IN   VARCHAR2 DEFAULT NULL,
      p_account_holder_name   IN   VARCHAR2
   )
      RETURN NUMBER;

/*========================================================================
 | PUBLIC function is_credit_card_duplicate
 |
 | DESCRIPTION
 |      Overloaded function calling is_bank_account_duplicate, used to checks whether given
 |      credit card number already exists.
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
 | 29-Oct-2001           J Rautiainen      Created
 |
 *=======================================================================*/
   FUNCTION is_credit_card_duplicate (
      p_bank_account_number   IN   VARCHAR2,
      p_account_holder_name   IN   VARCHAR2
   )
      RETURN NUMBER;

/*========================================================================
 | PUBLIC store_last_used_cc and pay_invoice_installment
 |
 | DESCRIPTION
 |      Backward compatibility methods introduced for mobile account
 |      management.
 |      ----------------------------------------
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 10-Mar-2002           J Rautiainen      Created
 |
 *=======================================================================*/
   PROCEDURE store_last_used_cc (
      p_customer_id       IN              NUMBER,
      p_bank_account_id   IN              NUMBER,
      p_status            OUT NOCOPY      VARCHAR2
   );

   /*============================================================
    | PUBLIC procedure create_invoice_pay_list
    |
    | DESCRIPTION
    |   Creates a list of transactions to be paid by the customer
    |   based on the trx type and the trx status.
    |
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
    | 22-Mar-2010   nkanchan     Bug 8293098 - Service change based on credit card types
    +============================================================*/
   PROCEDURE create_invoice_pay_list (
      p_customer_id            IN   NUMBER,
      p_customer_site_use_id   IN   NUMBER DEFAULT NULL,
      p_payment_schedule_id    IN   NUMBER DEFAULT NULL,
      p_currency_code          IN   VARCHAR2,
      p_payment_type           IN   VARCHAR2 DEFAULT NULL,
      p_lookup_code            IN   VARCHAR2 DEFAULT NULL
   );

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
     +============================================================*/
   PROCEDURE create_open_credit_pay_list (
      p_customer_id            IN   NUMBER,
      p_customer_site_use_id   IN   NUMBER DEFAULT NULL,
      p_currency_code          IN   VARCHAR2
   );

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
 | 22-Mar-2010   nkanchan     Bug 8293098  - Service change based on credit card types
 | 29-May-2014   melapaku     Bug 18832462 - Future date payment for double discount and disputed invoices
 +============================================================*/
   PROCEDURE cal_discount_and_service_chrg (
      p_customer_id         IN   NUMBER,
      p_site_use_id         IN   NUMBER DEFAULT NULL,
      p_receipt_date        IN   DATE DEFAULT TRUNC (SYSDATE),
      p_payment_type        IN   VARCHAR2 DEFAULT NULL,
      p_lookup_code         IN   VARCHAR2 DEFAULT NULL,
      p_receipt_date_flag   IN   VARCHAR2 DEFAULT NULL
   );                                                --Added for Bug 18832462

/*==============================================================
 | PROCEDURE pay_multiple_invoices
 |
 | DESCRIPTION
 |
 | PARAMETERS
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date          Author       Description of Changes
 | 13-Jan-2003   krmenon      Created
 | 07-Oct-2004   vnb          Bug 3335944  - One Time Credit Card Verification
 | 14-Mar-2013   melapaku     Bug 16471455 - Payment Audit History Feature
 | 14-Oct-2014   melapaku     Bug19800178 - IRECEIVABLES LEADING ZERO REMOVED IN CVV CODE
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
      p_cvv2                  IN              VARCHAR2 default null,-- Added for Bug#19800178
      p_bank_branch_id        IN              NUMBER,
      p_receipt_date          IN              DATE DEFAULT TRUNC (SYSDATE),
      p_new_account_flag      IN              VARCHAR2 DEFAULT 'FALSE',
      p_receipt_site_id       IN              NUMBER,
      p_bank_id               IN              NUMBER,
      p_card_brand            IN              VARCHAR2,
      p_cc_bill_to_site_id    IN              NUMBER,
      p_single_use_flag       IN              VARCHAR2 := 'N',
      p_iban                  IN              VARCHAR2,
      p_routing_number        IN              VARCHAR2,
      p_instr_assign_id       IN              NUMBER := 0,
      p_payment_audit_id      IN              NUMBER,
                                                    -- Added for Bug#16471455
      p_bank_account_id       IN OUT NOCOPY   NUMBER,
      p_cash_receipt_id       OUT NOCOPY      NUMBER,
      p_cc_auth_code          OUT NOCOPY      VARCHAR2,
      p_cc_auth_id            OUT NOCOPY      NUMBER,
                                                    -- Added for Bug#16471455
      p_status                OUT NOCOPY      VARCHAR2,
      p_status_reason         OUT NOCOPY      VARCHAR2,
                                                    -- Added for Bug#16471455
      x_msg_count             OUT NOCOPY      NUMBER,
      x_msg_data              OUT NOCOPY      VARCHAR2,
    /* Added for R12 upgrade retrofit */
      p_auth_code             IN              VARCHAR2,               --E1294
      x_bep_code              OUT NOCOPY      VARCHAR2,
      -- Added for the Defect 2462(CR 247), for E1294
      p_bank_routing_number   IN              VARCHAR2 DEFAULT NULL,  -- V1.4
      p_bank_account_name     IN              VARCHAR2 DEFAULT NULL,  -- V1.4
      p_soa_receipt_number    OUT NOCOPY      VARCHAR2,               -- V1.4
      p_soa_msg               OUT NOCOPY      VARCHAR2,                -- V1.4
      p_confirmemail          IN VARCHAR2
   /* End - Added for R12 upgrade retrofit */
   );

/*==============================================================
 | PROCEDURE validate_payment_setup
 |
 | DESCRIPTION
 |     Validates if the payment methods have been setup for
 |     a particular currency code.
 | PARAMETERS
 |    p_customer_id     IN     NUMBER
 |    p_customer_site_id  IN       NUMBER
 |     p_currency_code     IN       VARCHAR2
 |
 | RETURN
 |     1         if setup is valid
 |     0         if setup is invalid
 | KNOWN ISSUES
 |
 | NOTES
 |     Had to return NUMBER instead of BOOLEAN for ease of use
 |     in java calls
 | MODIFICATION HISTORY
 | Date          Author       Description of Changes
 | 13-Jan-2003   krmenon      Created
 |
 +==============================================================*/
   FUNCTION validate_payment_setup (
      p_customer_id        IN   NUMBER,
      p_customer_site_id   IN   NUMBER,
      p_currency_code      IN   VARCHAR2
   )
      RETURN NUMBER;

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
    |   p_customer_id           IN    NUMBER
    |   p_customer_site_use_id  IN    NUMBER
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
    | 26-MAY-2005   rsinthre     Bug 4392371 - OIR needs to support cross customer payment
    +============================================================*/
   PROCEDURE create_transaction_list_record (
      p_payment_schedule_id   IN   NUMBER,
      p_customer_id           IN   NUMBER,
      p_customer_site_id      IN   NUMBER
   );

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
 |      p_customer_id       IN       NUMBER
 |      p_customer_site_id  IN       NUMBER
 |      p_currency_code     IN       VARCHAR2
 | RETURNS
 |      Number 1 or 0 corresponing to true and false for the credit card
 |      payment has been setup or not.
 |
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
      RETURN NUMBER;

   FUNCTION is_bank_acc_payment_enabled (
      p_customer_id        IN   NUMBER,
      p_customer_site_id   IN   NUMBER,
      p_currency_code      IN   VARCHAR2,
      p_org_id             IN   NUMBER Default null
   )
      RETURN NUMBER;

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
  | 21-SEP-2004   vnb          Bug 3886652 - Customer and Customer site added as params
  +============================================================*/
   FUNCTION save_payment_inst_info_wrapper (
      p_customer_id            IN   VARCHAR2,
      p_customer_site_use_id   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2;

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
   | 14-JUN-2004   vnb          Created
   +============================================================*/
   FUNCTION is_grace_days_enabled_wrapper
      RETURN VARCHAR2;

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
      RETURN NUMBER;

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
   );

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
   |   03-JAN-2005     vnb      Bug 4071551 - Function to compute service charge made public
   | 22-Mar-2010   nkanchan     Bug 8293098 - Service change based on credit card types
   |
   +=====================================================================*/
   FUNCTION get_service_charge (
      p_customer_id    IN   NUMBER,
      p_site_use_id    IN   NUMBER DEFAULT NULL,
      p_payment_type   IN   VARCHAR2 DEFAULT NULL,
      p_lookup_code    IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;

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
   | 22-Mar-2010   nkanchan     Bug 8293098 - Service change based on credit card types
   |
   +=====================================================================*/
   PROCEDURE reset_payment_amounts (
      p_customer_id    IN   NUMBER,
      p_site_use_id    IN   NUMBER DEFAULT NULL,
      p_payment_type   IN   VARCHAR2 DEFAULT NULL,
      p_lookup_code    IN   VARCHAR2 DEFAULT NULL
   );

   TYPE inv_list_table_type IS TABLE OF ar_payment_schedules.payment_schedule_id%TYPE
      INDEX BY BINARY_INTEGER;

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
   );

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
   |   17-MAR-2006     rsinthre          Created
   |
   +=====================================================================*/
   PROCEDURE update_invoice_payment_status (
      p_payment_schedule_id_list   IN              inv_list_table_type,
      p_inv_pay_status             IN              VARCHAR2,
      x_return_status              OUT NOCOPY      VARCHAR2,
      x_msg_count                  OUT NOCOPY      NUMBER,
      x_msg_data                   OUT NOCOPY      VARCHAR2
   );

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
 |   29-Oct-2008     rsinthre              Created
 |
 +=====================================================================*/
   FUNCTION get_customer_site_use_id (
      p_session_id    IN   NUMBER,
      p_customer_id   IN   NUMBER
   )
      RETURN NUMBER;

   /*============================================================
   | PUBLIC function get_future_discount_wrapper
   |
   | DESCRIPTION
   |   This is a function that is a wrapper to call the AR API for calculating
   |   future date discounts.
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
   | Date                   Author       Description of Changes
   | 06-MAY-2011         rsinthre     Created
   +============================================================*/
   FUNCTION get_future_discount_wrapper (
      p_ps_id               IN   ar_payment_schedules.payment_schedule_id%TYPE,
      p_in_applied_amount   IN   NUMBER,
      p_discount_date       IN   DATE DEFAULT NULL
   )
      RETURN NUMBER;

 --Added for R12 upgrade retrofit
-- Included the procedure VERBAL_AUTH_CODE for E1294 by Madankumar J,Wipro Tech
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
   );


PROCEDURE insert_irec_ext (p_cash_receipt_id IN NUMBER,
                              p_confirmemail            IN  VARCHAR2);
							  
PROCEDURE get_token_wrapper (
   p_account_number       IN              VARCHAR2,
   p_expiration_date      IN              DATE,
   x_token                OUT NOCOPY      VARCHAR2,
   x_status               OUT NOCOPY      VARCHAR2,
   x_ERROR_MSG            IN OUT NOCOPY   VARCHAR2,
   x_ERROR_CODE           IN OUT NOCOPY   VARCHAR2
);

END xx_ar_irec_payments;
/
COMMIT;
EXIT;