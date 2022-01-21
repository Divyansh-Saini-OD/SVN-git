create or replace PACKAGE ari_utilities AUTHID CURRENT_USER AS
/* $Header: ARIUTILS.pls 120.18.12020000.5 2014/05/28 18:47:34 shvimal ship $ */


FUNCTION check_external_user_access (p_person_party_id  IN VARCHAR2,
				     p_customer_id      IN VARCHAR2,
				     p_customer_site_use_id IN VARCHAR2)
                               RETURN VARCHAR2 ;

PROCEDURE send_notification(p_user_name        IN VARCHAR2,
                            p_customer_name    IN VARCHAR2,
                            p_request_id       IN NUMBER,
                            p_requests         IN NUMBER,
                            p_parameter        IN VARCHAR2,
                            p_subject_msg_name IN VARCHAR2,
                            p_subject_msg_appl IN VARCHAR2 DEFAULT 'AR',
                            p_body_msg_name    IN VARCHAR2 DEFAULT NULL,
                            p_body_msg_appl    In VARCHAR2 DEFAULT 'AR');

/*========================================================================
 | PUBLIC function curr_round_amt
 |
 | DESCRIPTION
 |      Rounds a given amount based on the precision defined for the currency code.
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |      This function rounds the amount based on the precision defined for the
 |      currency code.
 |
 | PARAMETERS
 |      amount         IN NUMBER    Input amount for rounding
 |      currency_code  IN VARCHAR2  Currency Code
 |
 | RETURNS
 |       NUMBER  Rounded Amount
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 17-DEC-2004           vnb               Created
 |
 *=======================================================================*/
FUNCTION curr_round_amt( p_amount IN NUMBER,
                         p_currency_code IN VARCHAR2)
RETURN NUMBER;

TYPE t_ar_lookups_table IS TABLE OF VARCHAR2(80)
      INDEX BY BINARY_INTEGER;

pg_ar_lookups_rec t_ar_lookups_table;

FUNCTION get_lookup_meaning (p_lookup_type  IN VARCHAR2,
                             p_lookup_code  IN VARCHAR2)
 RETURN VARCHAR2;

FUNCTION get_bill_to_site_use_id (p_address_id IN NUMBER) RETURN NUMBER;

FUNCTION get_site_uses (p_address_id IN NUMBER) RETURN VARCHAR2;

FUNCTION get_site_uses (p_address_id IN NUMBER, p_customer_id IN NUMBER) RETURN VARCHAR2;

FUNCTION get_site_uses_status (p_address_id IN NUMBER) RETURN VARCHAR2; -- Added for Bug 16969969

FUNCTION site_use_meaning (p_site_use IN VARCHAR2) RETURN VARCHAR2;

FUNCTION site_use_status_meaning (p_site_use_status IN VARCHAR2) RETURN VARCHAR2; -- Added for Bug 16969969

FUNCTION cust_srch_sec_predicate(obj_schema VARCHAR2,
		                         obj_name   VARCHAR2) RETURN VARCHAR2;

FUNCTION get_default_currency (	p_customer_id      IN VARCHAR2,
				p_session_id IN VARCHAR2)

RETURN VARCHAR2;

--------------------------------------------------------------------------------
--Check if the person party has access to this customer site
FUNCTION check_site_access (p_person_party_id  IN VARCHAR2,
				            p_customer_id      IN VARCHAR2,
				            p_customer_site_use_id IN VARCHAR2)
    RETURN VARCHAR2;
--------------------------------------------------------------------------------
--Check if the admin identified by p_person_party_id has access to this customer
FUNCTION check_admin_access (p_person_party_id  IN VARCHAR2,
				             p_customer_id      IN VARCHAR2)
    RETURN VARCHAR2;
--------------------------------------------------------------------------------


/*========================================================================
 | PUBLIC procedure get_contact_id
 |
 | DESCRIPTION
 |      Returns contact id of the given site at the customer/site level
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_customer_id		IN	Customer Id
 |      p_customer_site_use_id	IN	Customer Site Id
 |	p_contact_role_type	IN	Contact Role Type
 |
 | RETURNS
 |      l_contact_id		Contact id of the given site at the customer/site level
 | KNOWN ISSUES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 12-AUG-2005           rsinthre	   Created
 *=======================================================================*/
FUNCTION get_contact_id(p_customer_id IN NUMBER,
                        p_customer_site_use_id IN NUMBER DEFAULT  NULL,
                        p_contact_role_type IN VARCHAR2 DEFAULT  'ALL') RETURN NUMBER;


 /*========================================================================
 | PUBLIC procedure get_contact
 |
 | DESCRIPTION
 |      Returns contact name of the given site at the customer/site level
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_customer_id		IN	Customer Id
 |      p_customer_site_use_id	IN	Customer Site Id
 |	p_contact_role_type	IN	Contact Role Type
 |
 | RETURNS
 |      l_contact_name		Contact name of the given site at the customer/site level
 | KNOWN ISSUES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 12-AUG-2005           rsinthre	   Created
 *=======================================================================*/
FUNCTION get_contact(p_customer_id IN NUMBER,
                     p_customer_site_use_id IN NUMBER,
		     p_contact_role_type IN VARCHAR2 DEFAULT  'ALL') RETURN VARCHAR2;

/*========================================================================
 | PUBLIC procedure get_contact
 |
 | DESCRIPTION
 |      Returns contact name of the given contact id
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_contact_id		IN	Customer Id
 |
 | RETURNS
 |      l_contact_name	Contact name of the given contact id
 | KNOWN ISSUES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 5-JUL-2005           hikumar 	   Created
 *=======================================================================*/
FUNCTION get_contact(p_contact_id IN NUMBER) RETURN VARCHAR2;

  /*========================================================================
 | PUBLIC procedure get_phone
 |
 | DESCRIPTION
 |      Returns contact point of the given contact type, site at the customer/site level
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_customer_id		IN	Customer Id
 |      p_customer_site_use_id	IN	Customer Site Id
 |	p_contact_role_type	IN	Contact Role Type
 |	p_phone_type		IN	contact type like 'PHONE', 'FAX', 'GEN' etc
 |
 | RETURNS
 |      l_contact_phone		Contact type number of the given site at the customer/site level
 | KNOWN ISSUES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 12-AUG-2005           rsinthre	   Created
 | 24-DEC-2012           shvimal           Removed DEFAULT from p_contact_role_type parameter
 *=======================================================================*/
FUNCTION get_phone(p_customer_id IN NUMBER,
                   p_customer_site_use_id IN NUMBER DEFAULT  NULL,
		   p_contact_role_type IN VARCHAR2,
		   p_phone_type IN VARCHAR2 DEFAULT  'ALL') RETURN VARCHAR2;
 /*========================================================================
 | PUBLIC procedure get_phone
 |
 | DESCRIPTION
 |      Returns contact point of the given contact id
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_contact_id		IN	Customer Id
 |	p_phone_type		IN	contact type like 'PHONE', 'FAX', 'GEN' etc
 |
 | RETURNS
 |      l_contact_phone		Contact type number of the given contact id
 | KNOWN ISSUES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 5-JUL-2005           hikumar 	   Created
 *=======================================================================*/
FUNCTION get_phone(p_contact_id IN NUMBER,
                   p_phone_type IN VARCHAR2 DEFAULT  'ALL') RETURN VARCHAR2;

FUNCTION   get_service_charge_activity_id ( p_customer_id          IN VARCHAR2,
                                            p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN NUMBER;

FUNCTION   is_service_charge_enabled ( p_customer_id          IN VARCHAR2,
                                       p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN boolean;

FUNCTION   get_max_future_payment_date( p_customer_id          IN VARCHAR2,
                                        p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN DATE;

FUNCTION   save_payment_instrument_info ( p_customer_id          IN VARCHAR2,
                                          p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN;

FUNCTION   is_save_payment_instr_enabled ( p_customer_id          IN VARCHAR2,
                                           p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

FUNCTION   is_aging_enabled ( p_customer_id          IN VARCHAR2,
                              p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

FUNCTION   multi_print_limit ( p_customer_id          IN VARCHAR2,
                               p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

FUNCTION   is_discount_grace_days_enabled ( p_customer_id          IN VARCHAR2,
                                	    p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

FUNCTION   is_discount_grace_days_enabled RETURN boolean;

-- this procedure returns the html used for the 'Contact Us'
-- icon.

PROCEDURE get_contact_info (
	p_customer_id		IN	VARCHAR2,
	p_customer_site_use_id	IN	VARCHAR2,
	p_language_string	IN	VARCHAR2,
        p_page                  IN      VARCHAR2,
        p_trx_id                IN      VARCHAR2,
	p_output_string		OUT NOCOPY	VARCHAR2
);

FUNCTION get_site_use_location (p_address_id IN NUMBER) RETURN VARCHAR2;

/*========================================================================
 | PUBLIC function get_site_use_code
 |
 | DESCRIPTION
 |      Function returns the site use codes for the given adddress id
 |
 | PARAMETERS
 |      p_address_id           IN NUMBER
 |
 | RETURNS
 |      Site Use Codes for the given address id.
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 12-Feb-2007           abhisjai               Created
 *=======================================================================*/
FUNCTION get_site_use_code (p_address_id IN NUMBER) RETURN VARCHAR2;

/*========================================================================
 | PUBLIC function is_routing_number_valid
 |
 | DESCRIPTION
 |      Determines if a given routing number is valid.
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |      This function validates routing number, note currently it only
 |      validates US specific ABA (ACH) routing number. When other
 |      types are added also new logic needs to be introduced.
 |
 | PARAMETERS
 |      p_routing_number      IN      Routing number
 |      p_routing_number_type IN      Routing number type, defaults to ABA
 |
 | RETURNS
 |      1 if Routing number is valid
 |      0 if Routing number is invalid
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 27-Aug-2009           avepati          Created
 |
 *=======================================================================*/
FUNCTION is_routing_number_valid(p_routing_number      IN VARCHAR2,
                                 p_routing_number_type IN VARCHAR2 DEFAULT 'ABA') RETURN NUMBER;

/*========================================================================
 | PUBLIC function validate_ACH_checksum
 |
 | DESCRIPTION
 |      Determines if a given ACH routing number checksum is valid.
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |      This function validates US specific ACH routing number.
 |      Note that even if a number passes this test, it does not
 |      necessarily mean that it is valid. The number may not, in fact,
 |      be assigned to any financial institution. ACH routing numbers are
 |      always nine digits long. The first four specify the routing
 |      symbol, the next four identify the institution and the last is
 |      the checksum digit.
 |      Here's how the algorithm works. First the code strips out any non-numeric characters
 |      (like dashes or spaces) and makes sure the resulting string's length is nine digits,
 |       7 8 9 4 5 6 1 2 4
 |      Then we multiply the first digit by 3, the second by 7, the third by 1, the fourth by 3,
 |      the fifth by 7, the sixth by 1, etc., and add them all up.
 |       (7 x 3) + (8 x 7) + (9 x 1) +
 |       (4 x 3) + (5 x 7) + (6 x 1) +
 |       (1 x 3) + (2 x 7) + (4 x 1) = 160
 |      If this sum is an integer multiple of 10 (e.g., 10, 20, 30, 40, 50,...) then the number
 |      is valid, as far as the checksum is concerned.
 |
 | PARAMETERS
 |      p_routing_number   IN      ACH Routing number
 |
 | RETURNS
 |      1 if ACH Routing number is valid
 |      0 if ACH Routing number is invalid
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 27-Aug-2009           avepati           Created
 |
 *=======================================================================*/
FUNCTION validate_ACH_checksum(p_routing_number IN VARCHAR2) RETURN NUMBER;

/*===========================================================================+
 | FUNCTION validate_ACH_routing_number                                      |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    This function validates that given routing number is an existing ACH   |
 |    bank.                                                                  |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    None                                                                   |
 |                                                                           |
 | ARGUMENTS  : IN: p_routing_number Routing Number                          |
 |                                                                           |
 | RETURNS    : 1 routing number is valid                                    |
 |              0 routing number is invalid                                  |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     27-Aug-2009   avepati      Created                                    |
 |                                                                           |
 +===========================================================================*/
  FUNCTION validate_ACH_routing_number(p_routing_number IN  VARCHAR2) RETURN NUMBER;

  /*===========================================================================+
 | PROCEDURE strip_white_spaces                                              |
 |                                                                           |
 | DESCRIPTION                                                               |
 |  This proc stips out any non numberic characters like sapces,dashes etc   |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 |                                                                           |
 | ARGUMENTS  : IN: p_num_to_strip    Number to be stripped               |
 |                                                                           |
 | RETURNS    : OUT: p_stripped_num      Stripped number                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     27-Aug-2009   avepati      Created                                    |
 |                                                                           |
 +===========================================================================*/

  PROCEDURE strip_white_spaces( p_num_to_strip   IN         AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
                                p_stripped_num      OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE );

FUNCTION get_group_header (p_customer_id IN NUMBER,p_party_id IN NUMBER , p_trx_number IN VARCHAR) RETURN NUMBER;


FUNCTION invoke_invoice_email_notwf ( p_subscription_guid In RAW, p_event IN OUT NOCOPY WF_EVENT_T) RETURN VARCHAR2;

PROCEDURE det_if_send_email (  l_itemtype    in   varchar2,
                               	   l_itemkey     in   varchar2,
	                             actid       in   number,
                                	   funcmode    in   varchar2,
                                                       rslt      out NOCOPY  varchar2);

FUNCTION get_contact_emails_adhoc_list(  p_customer_id          IN VARCHAR2 ,
                             	  p_customer_acct_site_id IN VARCHAR2 ) RETURN VARCHAR2;

Type email_addr_type IS TABLE OF hz_contact_points.email_Address%TYPE INDEX BY BINARY_INTEGER;

FUNCTION remove_existing_user_role(  p_email_address  IN VARCHAR2 )  RETURN VARCHAR2;

FUNCTION remove_duplicate_user_names ( l_user_email_list IN email_addr_type )  RETURN VARCHAR2;

TYPE CONTEXT_REC_TYPE IS RECORD
(
	CONTEXT_TYPE		VARCHAR2(100),
	CONTEXT_ID		NUMBER
);
TYPE CONTEXTS_TBL_TYPE IS TABLE OF CONTEXT_REC_TYPE INDEX BY BINARY_INTEGER;

PROCEDURE cancel_dispute(p_dispute_id      IN NUMBER,
						 p_cancel_comments IN VARCHAR2,
                         p_return_status   OUT NOCOPY VARCHAR2
                         );

-- Added for Bug 16970987 - shvimal
PROCEDURE receivables_dispute(p_trx_number IN VARCHAR2,
							  p_customer_trx_id IN NUMBER,
							  p_payment_schedule_id IN NUMBER,
							  p_dispute_amount IN NUMBER,
							  p_reason_code IN VARCHAR2,
							  p_dispute_date IN DATE,
							  p_dispute_comment IN VARCHAR2,
							  p_return_status  OUT NOCOPY VARCHAR2
							);

FUNCTION get_link_filter(p_txn_no IN  VARCHAR2,
			 p_txn_type IN  VARCHAR2,
			 p_cust_trx_id IN NUMBER,
			 p_payment_schedule_id IN NUMBER) RETURN VARCHAR2;

/*========================================================================
 | PUBLIC function get_pending_cmreq_amount
 |
 | DESCRIPTION
 |      Function returns the pending credit memo request amount for the customer id passed.
 |      If customer is not passed, then it will return the pending credit memo request amount
 |      for all the customer in current session.
 |
 | PARAMETERS
 |      p_customer_id IN NUMBER,
 |      p_customer_site_use_id IN NUMBER,
 |      p_session_id IN NUMBER,
 |      p_currency_code IN VARCHAR2
 |
 | RETURNS
 |      Pending Credit Memo Request amount
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 16-Nov-2011           melapaku               Created
 | 10-May-2012          parln            Bug 13484644 - FP:13455876:13117430: ACCOUNT SUMMARY PERF ISSUES
 *=======================================================================*/

FUNCTION get_pending_cmreq_amount(p_customer_id IN NUMBER,
                                    p_customer_site_use_id IN NUMBER,
                                    p_session_id IN NUMBER,
                                    p_currency_code IN VARCHAR2) RETURN NUMBER;
END ari_utilities ;
/