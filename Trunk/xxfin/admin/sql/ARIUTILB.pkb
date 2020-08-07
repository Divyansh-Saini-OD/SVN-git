REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile(120.22.12010000.31=120.37.12020000.12)(120.20.12000000.4=120.22.12010000.2):~PROD:~PATH:~FILE


REM SET ESCAPE `
SET VERIFY OFF;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE BODY ARI_UTILITIES AS

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name     :  ARIUTILB.pls                                            |
-- | Rice id  :   E1329                                                  |
-- | Description : Modified the package for patch p19052386              |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       19-Jan-2015   Sridevi K            Modified for patch      |
-- |                                             Incorporated changes    |
-- |                                             which were done by      |
-- |                                             Sreedhar for iRec Enhancement|
-- +=====================================================================+

/*============================================================================+
 $Header: ARIUTILB.pls 120.37.12020000.12 2014/08/23 11:21:06 melapaku ship $
 |  Copyright (c) 1996, 2014 Oracle Corporation Belmont, California, USA            |
 |                       All rights reserved                                  |
 +============================================================================+
 |                                                                            |
 | FILENAME                                                                   |
 |                                                                            |
 |    ARIUTILB.pls                                                            |
 |                                                                            |
 | DESCRIPTION                                                                |
 |                                                                            |
 | This is the package to for iReceivables utility functions 		      |
 |                                                                            |
 | HISTORY                                                                    |
 |	hikumar		28 July '04	Created			              |
 |      vnb             19 Oct  04      Bug 3957478 - Multiprint Workflow     |
 |  vnb       20 Dec 04  Bug 4071019 - Function for rounding amounts added    |
 |  	rsinthre	12 Jan 04       Bug 4101466 - Hyperlink not working   |
 |					for an external user assgined with    |
 |					same location      		      |
 |  	rsinthre	17 Jan 04	Bug 3800333 - iRec Invoice details    |
 |					type/status cols not fully translated |
 |					in Canadian French language	      |
 |  vnb         24 May 05      Bug 4197060 - MOAC Uptake					  |
 |  vnb         27 May 05      Bug 4371650 - Enhanced User Registration       |
 |  vnb         08 Jun 05      Bug 4417906 - Cust Label has extra line spacing |
 |  rsinthre    20 Jul 05      Bug 4488421 - Remove reference to obsolete TCA views
 |  rsinthre    02 Nov 05      Bug 4651472 - Location should be present in all|
 |			       VOs in customer search			      |
 |  abathini    02 May 06      Bug 5054123 - Commented out the line in        |
 |					     get_contact_info involving       |
 |					     the conversion of p_trx_id into  |
 |					     number as it results in an error |
 |					     in some cases, causing error in  |
 |					     display of dispute page 	      |	
 |  rsinthre    28 Jun 06      Bug 5258425 - Address SQL Repository issues    |	
 |  abathini    21 Dec 0       Bug 6503280 - Commeneted out the check         |
 |				         status='A' on hz_cust_site_uses table| 
 |					 to allow drill down                 |
 |					 from Inactive Bill-To Sites          |
 |  04-Aug-2009    avepati     Bug 8664350  R12 UNABLE TO LOAD FEDERAL RESERVE ACH PARTICAIPANT DAT|
 |  05-NOV-2009    avepati     Bug 9074606 - GSI: 12.1.1 Poor performance in external customer account |
 |  26-Nov-2009    avepati     Bug 9150636  - Payment Should not process when AR Bank Dir Profile set to None |
 |  19-May-2010    avepati     Bug 9795675 -  canadian transit numbers are not accepted in irec|
 |  05-Jul-2011    rsinthre    Bug 12719843 - CONTACT US NOT AS PER RULE IN CUSTOMER SEARCH PAGE|
 |  23-Apr-2012    parln       Bug 13882096 - IRECEIVABLES CREDIT MEMO VISIBILITY (DO NOT PRINT SETTING)|
 |  10-May-2012    parln       Bug 13848644 - FP:13455876:13117430: ACCOUNT SUMMARY PERF ISSUES|
 |  24-Dec-2012    shvimal     BUG 15876881 - FP: 14724976: OIR IS TAKING TOO LONG TO LOGIN FOR EXTERNAL CUSTOMERS|
 |  14-Feb-2013    melapaku    Bug 16168496 - UNABLE TO SEARCH A CUSTOMER ON ALL LOCATIONS IN BILL MANAGEMENT,
 |                                            IRECEIVABLES                    |
 |  10-Jul-2013    shvimal     Bug 16969969 - CUSTOMER SITE IS NOT ASSIGNED AS BILL_TO BUT SHOWING IN IRECEIVABLES SCREEN |
 |  04-Nov-2013    melapaku    Bug 17714122 - MAXIMUM FUTURE DATED PAYMENTS NOT WORKING AT RESPONSIBILITY LEVEL |
 |  29-May-2014    shvimal     Bug 16970987 - ABILITY TO CREATE DISPUTE ON CREDIT MEMO |
 |  07-Aug-2014    melapaku    Bug 19057880 - COMMENTS FOR CANCELLED DISPUTE REQUEST ARE NOT SAVING ANYWHERE|
 +===========================================================================*/
 
/* $Header: ARIUTILB.pls 120.37.12020000.12 2014/08/23 11:21:06 melapaku ship $ */

/*=======================================================================+
 |  Package Global Constants
 +=======================================================================*/
G_PKG_NAME CONSTANT VARCHAR2(30)    := 'ARI_UTILITIES';
PG_DEBUG   VARCHAR2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');

G_PRV_ADDRESS_ID   HZ_CUST_ACCT_SITES.CUST_ACCT_SITE_ID%TYPE := 0;
G_BILL_TO_SITE_USE_ID   HZ_CUST_SITE_USES.SITE_USE_ID%TYPE := 0;
G_PRV_SITE_USES   VARCHAR2(2000);


FUNCTION check_external_user_access (p_person_party_id  IN VARCHAR2,
				     p_customer_id      IN VARCHAR2,
				     p_customer_site_use_id IN VARCHAR2) RETURN VARCHAR2 IS
user_access VARCHAR2(1) ;
CURSOR customer_assigned_cur(p_customer_id IN VARCHAR2, p_person_party_id IN VARCHAR2) IS
	SELECT 'Y'
	INTO user_access
	FROM dual
	WHERE p_customer_id IN (SELECT cust_account_id
	    FROM ar_customers_assigned_v
	    WHERE party_id = p_person_party_id);
CURSOR customer_site_assigned_cur(p_person_party_id IN VARCHAR2, p_customer_site_use_id IN VARCHAR2) IS
		SELECT 'Y'
		  FROM ar_sites_assigned_v a,HZ_CUST_SITE_USES b
		  where a.cust_acct_site_id = b.cust_acct_site_id
		  and b.SITE_USE_CODE = 'BILL_TO'
		  AND party_id = p_person_party_id and site_use_id = p_customer_site_use_id;

CURSOR customer_acc_site_cur(p_person_party_id IN VARCHAR2, p_customer_site_use_id IN VARCHAR2) IS
	SELECT 'Y'
			  FROM ar_customers_assigned_v Custs_assigned,
	hz_cust_acct_sites Site,HZ_CUST_SITE_USES site_uses
			  WHERE Custs_assigned.party_id = p_person_party_id
			  AND  Site.cust_account_id =
	Custs_assigned.cust_account_id
			  and Site.cust_acct_site_id =
	site_uses.cust_acct_site_id
			  and site_uses.SITE_USE_CODE = 'BILL_TO' and site_uses.SITE_USE_ID = p_customer_site_use_id;


customer_assigned_rec  customer_assigned_cur%ROWTYPE;
customer_site_assigned_rec customer_site_assigned_cur%ROWTYPE;
customer_acc_site_rec customer_acc_site_cur%ROWTYPE;

BEGIN

OPEN  customer_assigned_cur(p_customer_id, p_person_party_id);
  FETCH customer_assigned_cur INTO customer_assigned_rec;

IF customer_assigned_cur%FOUND THEN
	user_access := 'Y';
ELSE
	OPEN  customer_site_assigned_cur(p_person_party_id, p_customer_site_use_id);
	FETCH customer_site_assigned_cur INTO customer_site_assigned_rec;
	IF customer_site_assigned_cur%FOUND THEN
		user_access := 'Y';
	ELSE
		OPEN  customer_acc_site_cur(p_person_party_id, p_customer_site_use_id);
		FETCH customer_acc_site_cur INTO customer_acc_site_rec;
		IF customer_acc_site_cur%FOUND THEN
			user_access := 'Y';
		END IF;
	END IF;
END IF;

IF user_access is not null
then
 return 'Y' ;
end if ;

return 'N';

EXCEPTION WHEN OTHERS THEN
 return 'N' ;

END check_external_user_access;
/*============================================================
  | PUBLIC procedure send_notification
  |
  | DESCRIPTION
  |   Send single Workflow notification for multiple print requests
  |   submitted through iReceivables
  |
  | PSEUDO CODE/LOGIC
  |
  | PARAMETERS
  |   p_user_name        IN VARCHAR2
  |   p_customer_name    IN VARCHAR2
  |   p_request_id       IN NUMBER
  |   p_requests         IN NUMBER
  |   p_parameter        IN VARCHAR2
  |   p_subject_msg_name IN VARCHAR2
  |   p_subject_msg_appl IN VARCHAR2 DEFAULT 'AR'
  |   p_body_msg_name    IN VARCHAR2 DEFAULT NULL
  |   p_body_msg_appl    In VARCHAR2 DEFAULT 'AR'
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
  | 19-OCT-2004   vnb          Created
  +============================================================*/

PROCEDURE send_notification(p_user_name        IN VARCHAR2,
                            p_customer_name    IN VARCHAR2,
                            p_request_id       IN NUMBER,
                            p_requests         IN NUMBER,
                            p_parameter        IN VARCHAR2,
                            p_subject_msg_name IN VARCHAR2,
                            p_subject_msg_appl IN VARCHAR2 DEFAULT 'AR',
                            p_body_msg_name    IN VARCHAR2 DEFAULT NULL,
                            p_body_msg_appl    In VARCHAR2 DEFAULT 'AR') IS

 l_subject           varchar2(2000);
 l_body              varchar2(2000);

 l_procedure_name           VARCHAR2(50);
 l_debug_info	 	        VARCHAR2(200);

BEGIN

  l_procedure_name  := '.send_notification';

  ----------------------------------------------------------------------------------------
  l_debug_info := 'Fetch the message used as the confirmation message subject';
  -----------------------------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug(l_debug_info);
  END IF;
  FND_MESSAGE.SET_NAME (p_subject_msg_appl, p_subject_msg_name);
  FND_MESSAGE.set_token('CUSTOMER_NAME',p_customer_name);
  l_subject := FND_MESSAGE.get;

  /*----------------------------------------------------------------------------------------
  l_debug_info := 'Fetch the message used as the confirmation message body';
  -----------------------------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug(l_debug_info);
  END IF;
  FND_MESSAGE.SET_NAME (p_body_msg_appl, p_body_msg_name);
  l_body := FND_MESSAGE.get;*/

  ----------------------------------------------------------------------------------------
  l_debug_info := 'Create a Workflow process for sending iReceivables Print Notification(ARIPRNTF)';
  -----------------------------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug(l_debug_info);
  END IF;
  WF_ENGINE.CREATEPROCESS('ARIPRNTF',
                           p_request_id,
                          'ARI_PRINT_NOTIFICATION_PROCESS');

 /*------------------------------------------------------------------+
  | Set the notification subject to the message fetched previously   |
  +------------------------------------------------------------------*/
  WF_ENGINE.SetItemAttrText('ARIPRNTF',
                             p_request_id,
                            'ARI_MSG_SUBJ',
                             l_subject);

 /*---------------------------------------------------------------+
  | Set the notification body to the message fetched previously   |
  +---------------------------------------------------------------*/
  /*WF_ENGINE.SetItemAttrText('ARIPRNTF',
                             p_request_id,
                            'AR_MESSAGE_BODY',
                             l_body);*/

 /*-----------------------------------------------------------+
  | Set the recipient to the user name passed in as parameter |
  +-----------------------------------------------------------*/
  WF_ENGINE.SetItemAttrText('ARIPRNTF',
                             p_request_id,
                            'ARI_MSG_RECIPIENT',
                               p_user_name);

  /*-----------------------------------------------------------+
  | Set the sender to System Administrator's role              |
  | Check Workflow ER 3720065                                  |
  +-----------------------------------------------------------*/
  WF_ENGINE.SetItemAttrText('ARIPRNTF',
                             p_request_id,
                            '#FROM_ROLE',
                            'SYSADMIN');

  /*-----------------------------------------------------------+
  | Set the customer name attribute                            |
  +-----------------------------------------------------------*/
  WF_ENGINE.SetItemAttrText('ARIPRNTF',
                             p_request_id,
                            'ARI_NOTIFICATION_CUSTOMER_NAME',
                             p_customer_name);

  /*-----------------------------------------------------------+
  | Set the current concurrent request id                      |
  +-----------------------------------------------------------*/
  WF_ENGINE.SetItemAttrText('ARIPRNTF',
                             p_request_id,
                            'ARI_NOTIFICATION_CONC_REQ_ID',
                             p_request_id);

  /*-----------------------------------------------------------+
  | Set the number of requests                                 |
  +-----------------------------------------------------------*/
  WF_ENGINE.SetItemAttrText('ARIPRNTF',
                             p_request_id,
                            'ARI_NOTIFICATION_NUM_REQUESTS',
                             p_requests);

  /*------------------------------------------------------------------+
  | Set the URL param for the embedded framework region               |
  +------------------------------------------------------------------*/
  WF_ENGINE.SetItemAttrText('ARIPRNTF',
                             p_request_id,
                            'ARI_NOTIFICATION_REQUEST_IDS',
                             p_parameter);

  ----------------------------------------------------------------------------------------
  l_debug_info := 'Start the notification process';
  -----------------------------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug(l_debug_info);
  END IF;
  WF_ENGINE.STARTPROCESS('ARIPRNTF',
                          p_request_id);

EXCEPTION
    WHEN OTHERS THEN
      IF (PG_DEBUG = 'Y') THEN
        arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
        arp_standard.debug(' - No of Requests: '||p_requests);
        arp_standard.debug(' - User Name     : '||p_user_name);
        arp_standard.debug(' - Customer Name : '||p_customer_name);
        arp_standard.debug(' - Requests List : '||p_parameter);
        arp_standard.debug(' - Concurrent Request Id : '||p_request_id);
        arp_standard.debug('ERROR =>'|| SQLERRM);
      END IF;

      FND_MESSAGE.SET_NAME ('AR','ARI_REG_DISPLAY_UNEXP_ERROR');
      FND_MESSAGE.SET_TOKEN('PROCEDURE', G_PKG_NAME || l_procedure_name);
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO', l_debug_info);
      FND_MSG_PUB.ADD;

END send_notification;

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
 |      p_amount         IN NUMBER    Input amount for rounding
 |      p_currency_code  IN VARCHAR2  Currency Code
 |
 | RETURNS
 |      l_return_amt     NUMBER  Rounded Amount
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
RETURN NUMBER IS
    l_return_amt     NUMBER;
    l_precision      NUMBER;
    l_ext_precision  NUMBER;
    l_min_acct_unit  NUMBER;

    l_procedure_name           VARCHAR2(50);
    l_debug_info	       VARCHAR2(200);

BEGIN
    l_return_amt     := p_amount;
    l_precision      := 2;
    l_procedure_name := '.round_amount_currency';

    ---------------------------------------------------------------------------
    l_debug_info := 'Get precision information for the active currency';
    ---------------------------------------------------------------------------
    FND_CURRENCY_CACHE. GET_INFO(
                currency_code => p_currency_code, /* currency code */
                precision     => l_precision,     /* number of digits to right of decimal */
                ext_precision => l_ext_precision, /* precision where more precision is needed */
                min_acct_unit => l_min_acct_unit  /* minimum value by which amt can vary */
                );

    IF (PG_DEBUG = 'Y') THEN
        arp_standard.debug('- Currency Code: '||p_currency_code);
        arp_standard.debug('- Precision: '||l_precision);
        arp_standard.debug('- Extended Precision: '||l_ext_precision);
        arp_standard.debug('- Minimum Accounting Unit: '||l_min_acct_unit);
    END IF;

    ---------------------------------------------------------------------------
    l_debug_info := 'Round the input amount based on the precision information';
    ---------------------------------------------------------------------------
    l_return_amt := round(p_amount,l_precision);

    IF (PG_DEBUG = 'Y') THEN
        arp_standard.debug('- Unrounded Amount: '||p_amount);
        arp_standard.debug('- Rounded Amount: '||l_return_amt);
    END IF;

    RETURN l_return_amt;

EXCEPTION
    WHEN OTHERS THEN
         IF (PG_DEBUG = 'Y') THEN
		    arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
	        arp_standard.debug('Input Amount: '||p_amount);
		    arp_standard.debug('Rounded Amount: '||l_return_amt);
	        arp_standard.debug('Currency: '||p_currency_code);
	        arp_standard.debug('Precision: '||l_precision);
		    arp_standard.debug('ERROR =>'|| SQLERRM);
	    END IF;

         FND_MESSAGE.SET_NAME ('AR','ARI_REG_DISPLAY_UNEXP_ERROR');
         FND_MESSAGE.SET_TOKEN('PROCEDURE', G_PKG_NAME || l_procedure_name);
         FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
         FND_MESSAGE.SET_TOKEN('DEBUG_INFO', l_debug_info);
         FND_MSG_PUB.ADD;

         RETURN l_return_amt;

END;

/*========================================================================
 | get_lookup_meaning function returns the lookup meaning of lookup code |
 | in user specific language.						 |
 *=======================================================================*/
FUNCTION get_lookup_meaning (p_lookup_type  IN VARCHAR2,
                             p_lookup_code  IN VARCHAR2)
 RETURN VARCHAR2 IS
l_meaning ar_lookups.meaning%TYPE;
l_hash_value NUMBER;
l_procedure_name   VARCHAR2(50);
l_debug_info VARCHAR2(200);

BEGIN
  l_procedure_name := '.get_lookup_meaning';
  ----------------------------------------------------------------------------------------
  l_debug_info := 'Fetch hash value by sending lookup code, type and user env language';
  -----------------------------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug(l_debug_info);
  END IF;

  IF p_lookup_code IS NOT NULL AND
     p_lookup_type IS NOT NULL THEN

    l_hash_value := DBMS_UTILITY.get_hash_value(
                                         p_lookup_type||'@*?'||p_lookup_code||USERENV('LANG'),
                                         1000,
                                         25000);

    IF pg_ar_lookups_rec.EXISTS(l_hash_value) THEN
        l_meaning := pg_ar_lookups_rec(l_hash_value);
    ELSE

     SELECT meaning
     INTO   l_meaning
     FROM   ar_lookups
     WHERE  lookup_type = p_lookup_type
      AND  lookup_code = p_lookup_code;

  ----------------------------------------------------------------------------------------
  l_debug_info := 'Setting lookup meaning into page lookups rec';
  -----------------------------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug(l_debug_info);
  END IF;

     pg_ar_lookups_rec(l_hash_value) := l_meaning;

    END IF;

  END IF;

  return(l_meaning);

EXCEPTION
 WHEN no_data_found  THEN
  return(null);
 WHEN OTHERS THEN
  	IF (PG_DEBUG = 'Y') THEN
  		    arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
  		    arp_standard.debug('ERROR =>'|| SQLERRM);
  		    arp_standard.debug('Debug Info : '||l_debug_info);
  	 END IF;

END;


FUNCTION get_bill_to_site_use_id (p_address_id IN NUMBER) RETURN NUMBER AS
l_procedure_name   VARCHAR2(50);
l_debug_info VARCHAR2(200);
--
BEGIN
  l_procedure_name := '.get_bill_to_site_use_id';
  ----------------------------------------------------------------------------------------
  l_debug_info := 'Fetch site use id';
  -----------------------------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug(l_debug_info);
  END IF;

   IF G_PRV_ADDRESS_ID <> p_address_id THEN
      G_PRV_ADDRESS_ID := p_address_id;
      G_PRV_SITE_USES := get_site_uses(p_address_id);
   END IF;

   RETURN(G_BILL_TO_SITE_USE_ID);

 EXCEPTION
    WHEN OTHERS THEN
         IF (PG_DEBUG = 'Y') THEN
		    arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
		    arp_standard.debug('ERROR =>'|| SQLERRM);
		    arp_standard.debug('Debug Info : '||l_debug_info);
	 END IF;



END;


FUNCTION get_site_uses (p_address_id IN NUMBER) RETURN VARCHAR2 AS
--
   l_site_uses  VARCHAR2(4000) := '';
--
   l_separator  VARCHAR2(2) := '';
--
CURSOR c01 (addr_id VARCHAR2) IS
SELECT
   SITE_USE_CODE, SITE_USE_ID
FROM
   hz_cust_site_uses
WHERE
    cust_acct_site_id = addr_id;
--AND status    = 'A'   ;
/*Bug 6503280: Commented out above condition on checking status='A'
 * to allow Drill Down from Inactive Sites from Customer Search Page*/
l_procedure_name   VARCHAR2(50);
l_debug_info VARCHAR2(200);
--
BEGIN
--
   G_BILL_TO_SITE_USE_ID := 0;
--
  l_procedure_name := '.get_site_uses';
  ----------------------------------------------------------------------------------------
  l_debug_info := 'Fetch Bill to Site use id';
  -----------------------------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug(l_debug_info);
  END IF;

   FOR c01_rec IN c01 (p_address_id) LOOP
       l_site_uses := l_site_uses || l_separator || site_use_meaning(c01_rec.site_use_code);

       IF c01_rec.site_use_code = 'BILL_TO' THEN
	  G_BILL_TO_SITE_USE_ID := c01_rec.site_use_id;
       END IF;

       IF l_separator IS NULL THEN
	  l_separator := ', ';
       END IF;

   END LOOP;
--
 RETURN l_site_uses;

 EXCEPTION
    WHEN OTHERS THEN
         IF (PG_DEBUG = 'Y') THEN
		    arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
		    arp_standard.debug('ERROR =>'|| SQLERRM);
		    arp_standard.debug('Debug Info : '||l_debug_info);
	 END IF;



END;

-- Added for Bug 16969969
FUNCTION get_site_uses_status (p_address_id IN NUMBER) RETURN VARCHAR2 AS
--
   l_site_uses_status  VARCHAR2(4000) := '';
--
   l_separator  VARCHAR2(2) := '';
--
CURSOR c01 (addr_id VARCHAR2) IS
SELECT
   status,SITE_USE_ID
FROM
   hz_cust_site_uses_all
WHERE
    cust_acct_site_id = addr_id;
--AND status    = 'A'   ;
/*Bug 6503280: Commented out above condition on checking status='A'
 * to allow Drill Down from Inactive Sites from Customer Search Page*/
l_procedure_name   VARCHAR2(50);
l_debug_info VARCHAR2(200);
--
BEGIN
--
   --G_BILL_TO_SITE_USE_ID := 0;
--
  l_procedure_name := '.get_site_uses_status';
  ----------------------------------------------------------------------------------------
  l_debug_info := 'Fetch Bill to Site use status';
  -----------------------------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug(l_debug_info);
  END IF;

   FOR c01_rec IN c01 (p_address_id) LOOP
       l_site_uses_status := l_site_uses_status || l_separator || site_use_status_meaning(c01_rec.status);

     /*  IF c01_rec.site_use_code = 'BILL_TO' THEN
	  G_BILL_TO_SITE_USE_ID := c01_rec.site_use_id;
       END IF;*/

       IF l_separator IS NULL THEN
	  l_separator := ', ';
       END IF;

   END LOOP;
--
 RETURN l_site_uses_status;

 EXCEPTION
    WHEN OTHERS THEN
         IF (PG_DEBUG = 'Y') THEN
		    arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
		    arp_standard.debug('ERROR =>'|| SQLERRM);
		    arp_standard.debug('Debug Info : '||l_debug_info);
	 END IF;



END;

FUNCTION site_use_meaning (p_site_use IN VARCHAR2) RETURN VARCHAR2 AS
--
l_meaning VARCHAR2(80);
l_procedure_name   VARCHAR2(50);
l_debug_info VARCHAR2(200);
--
BEGIN

  l_procedure_name := '.site_use_meaning';
    ----------------------------------------------------------------------------------------
    l_debug_info := 'Fetch lookup meaning for site use';
    -----------------------------------------------------------------------------------------
    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(l_debug_info);
  END IF;

   l_meaning := get_lookup_meaning('SITE_USE_CODE', p_site_use);

   RETURN l_meaning;

 EXCEPTION
    WHEN OTHERS THEN
         IF (PG_DEBUG = 'Y') THEN
		    arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
		    arp_standard.debug('ERROR =>'|| SQLERRM);
		    arp_standard.debug('Debug Info : '||l_debug_info);
	 END IF;

END;

-- Added for Bug 16969969
FUNCTION site_use_status_meaning (p_site_use_status IN VARCHAR2) RETURN VARCHAR2 AS
--
l_meaning VARCHAR2(80);
l_procedure_name   VARCHAR2(50);
l_debug_info VARCHAR2(200);
--
BEGIN

  l_procedure_name := '.site_use_meaning';
    ----------------------------------------------------------------------------------------
    l_debug_info := 'Fetch lookup meaning for site use';
    -----------------------------------------------------------------------------------------
    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(l_debug_info);
  END IF;

   l_meaning := get_lookup_meaning('CODE_STATUS', p_site_use_status);

   RETURN l_meaning;

 EXCEPTION
    WHEN OTHERS THEN
         IF (PG_DEBUG = 'Y') THEN
		    arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
		    arp_standard.debug('ERROR =>'|| SQLERRM);
		    arp_standard.debug('Debug Info : '||l_debug_info);
	 END IF;

END;

/*========================================================================
 | PUBLIC function cust_srch_sec_predicate
 |
 | DESCRIPTION
 |      Security predicate for internal customer search in iReceivables.
 |      This is to ensure the 'All Locations'(which has org_id = -1) record gets picked up.
 |
 | PARAMETERS
 |      obj_schema       IN VARCHAR2  Object Schema
 |      obj_name         IN VARCHAR2  Object Name
 |
 | RETURNS
 |      Where clause to be appended to the object.
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 24-MAY-2005           vnb               Created
 |
 *=======================================================================*/
FUNCTION cust_srch_sec_predicate(obj_schema VARCHAR2,
		                         obj_name   VARCHAR2) RETURN VARCHAR2
IS
BEGIN
     RETURN 'EXISTS (SELECT 1
                        FROM mo_glob_org_access_tmp oa
                       WHERE oa.organization_id = org_id
                       OR org_id = -1)';
END cust_srch_sec_predicate;

/*========================================================================
 | PUBLIC function get_default_currency
 |
 | DESCRIPTION
 |      Function returns the first currency set up in the customer/site profiles.
 |      If no currency is set up for the customer, it pickes up from the Set of Books.
 |
 | PARAMETERS
 |      p_customer_id           IN VARCHAR2
 |      p_customer_site_use_id  IN VARCHAR2
 |
 | RETURNS
 |      Default Currency Code
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 19-MAY-2005           vnb               Created
 | 08-JUN-2005           vnb               Bug 4417906 - Cust Label has extra line spacing
 | 20-JUL-2005		 rsinthre	   Bug 4488421 - Remove reference to obsolete TCA views
 | 05-NOV-2009          avepati	Bug 9074606 - GSI: 12.1.1 Poor performance in external customer account
 | 23-MAR-2011		rsinthre	   Bug 11804918 - Acct Summary no longer allows pulldown for multiple currency
 *=======================================================================*/
  FUNCTION get_default_currency (
      p_customer_id   IN   VARCHAR2,
      p_session_id    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      l_default_currency            VARCHAR2 (15);
      l_default_org_id              NUMBER (15, 0);
      l_profile_default_currrency   VARCHAR2 (15);
      l_currency_exist              NUMBER (4);
   BEGIN
      IF (fnd_global.org_id = 403)
      THEN
         l_default_currency := 'CAD';
      ELSE
         l_default_currency := 'USD';
      END IF;

      RETURN l_default_currency;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         SELECT sb.currency_code
           INTO l_default_currency
           FROM ar_system_parameters SYS, gl_sets_of_books sb
          WHERE sb.set_of_books_id = SYS.set_of_books_id;

         RETURN l_default_currency;
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_default_currency;
   /*
FUNCTION get_default_currency (	p_customer_id      IN VARCHAR2,
				                p_session_id IN VARCHAR2)

RETURN VARCHAR2
IS
	l_default_currency	         VARCHAR2(15);
	l_default_org_id	           NUMBER(15,0);
  l_profile_default_currrency  VARCHAR2(15);
  l_currency_exist             NUMBER(4);
BEGIN
  l_profile_default_currrency := FND_PROFILE.value('OIR_DEFAULT_CURRENCY_CODE');

  IF(p_customer_id IS NULL) THEN

  select count(*) into l_currency_exist from dual where l_profile_default_currrency in
    (( SELECT /*+ leading(auas) use_nl(auas cpf) * unique ( CUR.CURRENCY_CODE )	FROM   HZ_CUST_PROFILE_AMTS CPA,
		       FND_CURRENCIES_VL CUR, HZ_CUSTOMER_PROFILES CPF, ar_irec_user_acct_sites_all AUAS
		       WHERE  CPA.CURRENCY_CODE = CUR.CURRENCY_CODE
		       AND    CPF.CUST_ACCOUNT_PROFILE_ID = CPA.CUST_ACCOUNT_PROFILE_ID
		       AND    CPF.CUST_ACCOUNT_ID =AUAS.CUSTOMER_ID
		       AND    (
	                CPF.SITE_USE_ID = AUAS.CUSTOMER_SITE_USE_ID
	                OR
	                CPF.SITE_USE_ID IS NULL
		              )
	         AND AUAS.user_id=FND_GLOBAL.USER_ID()
	         AND AUAS.session_id=p_session_id)
           UNION
           (SELECT unique ( CUR.CURRENCY_CODE ) FROM FND_CURRENCIES_VL CUR, AR_TRX_BAL_SUMMARY ATB, 					ar_irec_user_acct_sites_all AUAS
            WHERE ATB.CURRENCY = CUR.CURRENCY_CODE AND
                  ATB.CUST_ACCOUNT_ID = AUAS.CUSTOMER_ID  AND
                  (ATB.SITE_USE_ID = AUAS.CUSTOMER_SITE_USE_ID OR ATB.SITE_USE_ID IS NULL)
                  AND AUAS.user_id=FND_GLOBAL.USER_ID()
                  AND AUAS.session_id=p_session_id));
  if( l_currency_exist > 0 ) then
    return l_profile_default_currrency;
  end if;

	SELECT /*+ leading(auas) use_nl(auas cpf) * unique ( CUR.CURRENCY_CODE )
		INTO   l_default_currency
		FROM   HZ_CUST_PROFILE_AMTS CPA,
		       FND_CURRENCIES_VL CUR,
		       HZ_CUSTOMER_PROFILES CPF,
		       ar_irec_user_acct_sites_all AUAS
		WHERE  CPA.CURRENCY_CODE = CUR.CURRENCY_CODE
		AND    CPF.CUST_ACCOUNT_PROFILE_ID = CPA.CUST_ACCOUNT_PROFILE_ID
		AND    CPF.CUST_ACCOUNT_ID =AUAS.CUSTOMER_ID
		AND    (
	               CPF.SITE_USE_ID = AUAS.CUSTOMER_SITE_USE_ID
	               OR

	               CPF.SITE_USE_ID IS NULL
		       )
	       AND AUAS.user_id=FND_GLOBAL.USER_ID()
	       AND AUAS.session_id=p_session_id
	       AND    ROWNUM = 1;

	 --If currency does not exist in customer profile, then check if currency exist in transactions of the customer
         if(l_default_currency = '' OR l_default_currency is null) then

          SELECT unique ( CUR.CURRENCY_CODE ) INTO   l_default_currency FROM FND_CURRENCIES_VL CUR,
          AR_TRX_BAL_SUMMARY ATB, ar_irec_user_acct_sites_all AUAS
          WHERE ATB.CURRENCY = CUR.CURRENCY_CODE AND
            ATB.CUST_ACCOUNT_ID = AUAS.CUSTOMER_ID  AND
             (ATB.SITE_USE_ID = AUAS.CUSTOMER_SITE_USE_ID OR ATB.SITE_USE_ID IS NULL)
            AND AUAS.user_id=FND_GLOBAL.USER_ID()
            AND AUAS.session_id=p_session_id;
         end if;

	ELSE

  select count(*) into l_currency_exist from dual where l_profile_default_currrency in
    (( SELECT /*+ leading(auas) use_nl(auas cpf) * unique ( CUR.CURRENCY_CODE ) FROM   HZ_CUST_PROFILE_AMTS CPA,
		       FND_CURRENCIES_VL CUR, HZ_CUSTOMER_PROFILES CPF, ar_irec_user_acct_sites_all AUAS
      	   WHERE CPA.CURRENCY_CODE = CUR.CURRENCY_CODE
           AND 	 CPF.CUST_ACCOUNT_PROFILE_ID = CPA.CUST_ACCOUNT_PROFILE_ID
           AND   CPF.CUST_ACCOUNT_ID = p_customer_id
           AND   (
		             CPF.SITE_USE_ID = AUAS.CUSTOMER_SITE_USE_ID
		             OR
		             CPF.SITE_USE_ID IS NULL
         	       )
		       AND AUAS.user_id=FND_GLOBAL.USER_ID()
		       AND AUAS.session_id=p_session_id)
           UNION
           (SELECT unique ( CUR.CURRENCY_CODE ) FROM FND_CURRENCIES_VL CUR, AR_TRX_BAL_SUMMARY ATB, ar_irec_user_acct_sites_all AUAS
            WHERE ATB.CURRENCY = CUR.CURRENCY_CODE AND
                  ATB.CUST_ACCOUNT_ID = p_customer_id  AND
                  (ATB.SITE_USE_ID = AUAS.CUSTOMER_SITE_USE_ID OR ATB.SITE_USE_ID IS NULL)
                  AND AUAS.user_id=FND_GLOBAL.USER_ID()
                  AND AUAS.session_id=p_session_id));

  if( l_currency_exist > 0 ) then
    return l_profile_default_currrency;
  end if;

		SELECT /*+ leading(auas) use_nl(auas cpf) * unique ( CUR.CURRENCY_CODE )
			INTO   l_default_currency
			FROM   HZ_CUST_PROFILE_AMTS CPA,
		               FND_CURRENCIES_VL CUR,
		               HZ_CUSTOMER_PROFILES CPF,
                               ar_irec_user_acct_sites_all AUAS
      	        WHERE
        	 CPA.CURRENCY_CODE = CUR.CURRENCY_CODE AND
         	 CPF.CUST_ACCOUNT_PROFILE_ID = CPA.CUST_ACCOUNT_PROFILE_ID AND
         	 CPF.CUST_ACCOUNT_ID = p_customer_id  AND
         	(
		 CPF.SITE_USE_ID = AUAS.CUSTOMER_SITE_USE_ID
		 OR
		 CPF.SITE_USE_ID IS NULL
         	)
		AND AUAS.user_id=FND_GLOBAL.USER_ID()
		AND AUAS.session_id=p_session_id
		AND    ROWNUM = 1;

         --If currency does not exist in customer profile, then check if currency exist in transactions of the customer
         if(l_default_currency = '' OR l_default_currency is null) then

          SELECT unique ( CUR.CURRENCY_CODE ) INTO   l_default_currency FROM FND_CURRENCIES_VL CUR,
          AR_TRX_BAL_SUMMARY ATB, ar_irec_user_acct_sites_all AUAS
          WHERE ATB.CURRENCY = CUR.CURRENCY_CODE AND
            ATB.CUST_ACCOUNT_ID =  p_customer_id AND
             (ATB.SITE_USE_ID = AUAS.CUSTOMER_SITE_USE_ID OR ATB.SITE_USE_ID IS NULL)
            AND AUAS.user_id=FND_GLOBAL.USER_ID()
            AND AUAS.session_id=p_session_id;
         end if;

	END IF;

	RETURN l_default_currency;

EXCEPTION
	WHEN NO_DATA_FOUND THEN

		SELECT sb.currency_code
		  INTO   l_default_currency
		FROM   ar_system_parameters sys,
		       gl_sets_of_books sb
		WHERE  sb.set_of_books_id = sys.set_of_books_id;

	  RETURN l_default_currency;

	WHEN OTHERS THEN
	  RETURN NULL;

END get_default_currency;

*/
/*========================================================================
 | PUBLIC FUNCTION check_site_access
 |
 | DESCRIPTION
 |      This function checks if the person party has access to the specified
 |      customer site.
 |
 | PARAMETERS
 |      p_person_party_id       IN VARCHAR2
 |      p_customer_id           IN VARCHAR2
 |      p_customer_site_use_id  IN VARCHAR2
 |
 | NOTES
 |      This does not check access at the account level - only at this particular site.
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 09-May-2005           vnb               Created
 |
 *=======================================================================*/
FUNCTION check_site_access (p_person_party_id  IN VARCHAR2,
				            p_customer_id      IN VARCHAR2,
				            p_customer_site_use_id IN VARCHAR2)
             RETURN VARCHAR2
IS
    user_access VARCHAR2(1) ;
BEGIN

    SELECT 'Y'
    INTO user_access
    FROM dual
    WHERE EXISTS (SELECT 'Y'
		            FROM ar_sites_assigned_v a,HZ_CUST_SITE_USES b
		            WHERE a.cust_acct_site_id = b.cust_acct_site_id
		            AND b.SITE_USE_CODE = 'BILL_TO'
		            AND party_id = p_person_party_id
                    AND site_use_id = p_customer_site_use_id );

    IF user_access is not null THEN
        RETURN 'Y' ;
    END IF ;

    RETURN 'N';

EXCEPTION WHEN OTHERS THEN
    RETURN 'N' ;

END;

/*========================================================================
 | PUBLIC FUNCTION check_admin_access
 |
 | DESCRIPTION
 |      Check if the admin identified by p_person_party_id has access to this customer.
 |
 | PARAMETERS
 |      p_person_party_id       IN VARCHAR2
 |      p_customer_id           IN VARCHAR2
 |
 | NOTES
 |      This does not check access at the account level - only at this particular site.
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 09-May-2005           vnb               Created
 |
 *=======================================================================*/
FUNCTION check_admin_access (p_person_party_id  IN VARCHAR2,
				             p_customer_id      IN VARCHAR2)
                    RETURN VARCHAR2
IS
    user_access VARCHAR2(1) ;
BEGIN

    SELECT 'Y'
    INTO user_access
    FROM dual
    WHERE p_customer_id IN (
                select hca.cust_account_id
                from hz_relationships hr,
                    hz_parties hp1,
                    hz_parties hp2,
	                hz_cust_accounts hca
                where hr.subject_id = hp1.party_id
                and   hr.object_id = hp2.party_id
                and   subject_table_name = 'HZ_PARTIES'
                and   object_table_name = 'HZ_PARTIES'
                and   hr.relationship_type IN ( 'EMPLOYMENT', 'CONTACT')
                and hr.subject_id = p_person_party_id
                and  hca.party_id = hp2.party_id);

    IF user_access is not null THEN
        RETURN 'Y' ;
    END IF;

    RETURN 'N';

EXCEPTION WHEN OTHERS THEN
 RETURN 'N' ;

END;

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
                        p_contact_role_type IN VARCHAR2 DEFAULT  'ALL') RETURN NUMBER AS

l_contact_id NUMBER := null;

CURSOR contact_id_cur(p_customer_id IN NUMBER,
                        p_customer_site_use_id IN NUMBER DEFAULT  NULL,
                        p_contact_role_type IN VARCHAR2 DEFAULT  'ALL') IS
select contact_id from (
      select SUB.cust_account_role_id contact_id,  SUB.CUST_ACCT_SITE_ID , SROLES.responsibility_type ,SROLES.PRIMARY_FLAG ,
      row_number() OVER ( partition by SROLES.responsibility_type , SUB.CUST_ACCT_SITE_ID order by SROLES.PRIMARY_FLAG DESC NULLS LAST, SUB.last_update_date desc) last_update_record,
      decode(SROLES.responsibility_type,p_contact_role_type,111,999) resp_code
      from hz_cust_account_roles SUB,
      hz_role_responsibility SROLES
      where SUB.cust_account_role_id      = SROLES.CUST_ACCOUNT_ROLE_ID AND
      SUB.status = 'A' AND
      SUB.CUST_ACCOUNT_ID     = p_customer_id
      AND ( SUB.CUST_ACCT_SITE_ID = p_customer_site_use_id)
      )
where last_update_record <=1
ORDER BY resp_code ASC, CUST_ACCT_SITE_ID ASC NULLS LAST ;

CURSOR contact_id_acct_cur(p_customer_id IN NUMBER,
                        p_contact_role_type IN VARCHAR2 DEFAULT  'ALL') IS
select contact_id from (
      select SUB.cust_account_role_id contact_id,  SUB.CUST_ACCT_SITE_ID , SROLES.responsibility_type ,SROLES.PRIMARY_FLAG ,
      row_number() OVER ( partition by SROLES.responsibility_type , SUB.CUST_ACCT_SITE_ID order by SROLES.PRIMARY_FLAG DESC NULLS LAST, SUB.last_update_date desc) last_update_record,
      decode(SROLES.responsibility_type,p_contact_role_type,111,999) resp_code
      from hz_cust_account_roles SUB,
      hz_role_responsibility SROLES
      where SUB.cust_account_role_id      = SROLES.CUST_ACCOUNT_ROLE_ID AND
      SUB.status = 'A' AND
      SUB.CUST_ACCOUNT_ID     = p_customer_id
      AND (SUB.CUST_ACCT_SITE_ID IS NULL)
      )
where last_update_record <=1
ORDER BY resp_code ASC, CUST_ACCT_SITE_ID ASC NULLS LAST ;

contact_id_rec contact_id_cur%ROWTYPE;

BEGIN

IF(p_customer_site_use_id IS NOT NULL AND p_customer_site_use_id <> -1) THEN
	OPEN contact_id_cur(p_customer_id, p_customer_site_use_id,  p_contact_role_type);
	FETCH contact_id_cur INTO contact_id_rec;
	l_contact_id := contact_id_rec.contact_id;
	CLOSE contact_id_cur;
ELSE
	OPEN contact_id_acct_cur(p_customer_id, p_contact_role_type);
	FETCH contact_id_acct_cur INTO contact_id_rec;
	l_contact_id := contact_id_rec.contact_id;
	CLOSE contact_id_acct_cur;
END IF;

IF l_contact_id IS NOT NULL THEN
    RETURN l_contact_id;
END IF;

RETURN l_contact_id;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL ;
   WHEN OTHERS THEN
      RAISE;
END;

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
		     p_contact_role_type IN VARCHAR2 DEFAULT  'ALL') RETURN VARCHAR2 AS

l_contact_id NUMBER := NULL;
l_contact_name VARCHAR2(2000):= null;
BEGIN
--
   l_contact_id := get_contact_id (p_customer_id, p_customer_site_use_id, p_contact_role_type);

   IF l_contact_id IS NOT NULL THEN
--
      SELECT LTRIM(substrb(PARTY.PERSON_FIRST_NAME,1,40) || ' ') ||
                    substrb(PARTY.PERSON_LAST_NAME,1,50)
      INTO   l_contact_name
      FROM HZ_CUST_ACCOUNT_ROLES          ACCT_ROLE,
           HZ_PARTIES                     PARTY,
           HZ_RELATIONSHIPS         REL
      WHERE ACCT_ROLE.CUST_ACCOUNT_ROLE_ID = l_contact_id
        AND ACCT_ROLE.PARTY_ID = REL.PARTY_ID
        AND REL.SUBJECT_ID =  PARTY.PARTY_ID
        AND SUBJECT_TABLE_NAME = 'HZ_PARTIES'
        AND OBJECT_TABLE_NAME = 'HZ_PARTIES'
        AND DIRECTIONAL_FLAG = 'F';
--
   END IF;

   RETURN l_contact_name;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL;
   WHEN OTHERS THEN
      RAISE;
END;


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
 |      l_contact_name		Contact name of the given site at the customer/site level
 | KNOWN ISSUES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 24-AUG-2005           rsinthre	   Created
 | 11-SEP- 2008           avepati     bug 7368288 For the New Customer search after running the
 | 		      program customer text data indexing is not showing any output
 *=======================================================================*/
FUNCTION get_contact(p_contact_id IN NUMBER) RETURN VARCHAR2 AS
l_contact_name VARCHAR2(2000):= null;
BEGIN

  IF p_contact_id IS NOT NULL THEN
      SELECT LTRIM(substrb(PARTY.PERSON_FIRST_NAME,1,40) || ' ') ||
                    substrb(PARTY.PERSON_LAST_NAME,1,50)
      INTO   l_contact_name
      FROM HZ_CUST_ACCOUNT_ROLES          ACCT_ROLE,
           HZ_PARTIES                     PARTY,
           HZ_RELATIONSHIPS         REL
      WHERE ACCT_ROLE.CUST_ACCOUNT_ROLE_ID = p_contact_id
        AND ACCT_ROLE.PARTY_ID = REL.PARTY_ID
        AND REL.SUBJECT_ID =  PARTY.PARTY_ID
        AND SUBJECT_TABLE_NAME = 'HZ_PARTIES'
        AND OBJECT_TABLE_NAME = 'HZ_PARTIES'
        AND DIRECTIONAL_FLAG = 'F';
   END IF;

   RETURN l_contact_name;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
      RETURN NULL ;
   WHEN OTHERS THEN
      RAISE;
END;


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
 | 24-Dec-2012           shvimal           Removed DEFAULT from p_contact_role_type parameter
 *=======================================================================*/
FUNCTION get_phone(p_customer_id IN NUMBER,
                   p_customer_site_use_id IN NUMBER DEFAULT  NULL,
		   p_contact_role_type IN VARCHAR2,
		   p_phone_type IN VARCHAR2 DEFAULT  'ALL') RETURN VARCHAR2 AS
l_phone_id      NUMBER := NULL;
l_contact_id    NUMBER := NULL;
l_contact_phone VARCHAR2(2000):= null;
CURSOR phone_id_cur(p_contact_id IN NUMBER DEFAULT  NULL,
			p_phone_type IN VARCHAR2 DEFAULT  'ALL',
                        p_primary_flag IN VARCHAR2 DEFAULT  'Y') IS
	SELECT phone_id FROM
              ( SELECT CONT_POINT.CONTACT_POINT_ID phone_id,
               row_number() OVER ( order by CONT_POINT.last_update_date desc) last_update_record
	      FROM HZ_CUST_ACCOUNT_ROLES          ACCT_ROLE,
		   HZ_CONTACT_POINTS              CONT_POINT
	      WHERE
		  ACCT_ROLE.CUST_ACCOUNT_ROLE_ID      = p_contact_id
	      AND ACCT_ROLE.PARTY_ID = CONT_POINT.OWNER_TABLE_ID
	      AND CONT_POINT.OWNER_TABLE_NAME = 'HZ_PARTIES'
	      AND CONT_POINT.STATUS = 'A'
	      AND INSTRB(NVL(CONT_POINT.PHONE_LINE_TYPE, CONT_POINT.CONTACT_POINT_TYPE) || 'ALL',   p_phone_type) > 0
	      AND CONT_POINT.PRIMARY_FLAG = p_primary_flag
              )
              WHERE last_update_record<=1;

phone_id_rec phone_id_cur%ROWTYPE;

BEGIN
--
   l_contact_id := get_contact_id (p_customer_id, p_customer_site_use_id, p_contact_role_type);



   IF l_contact_id IS NOT NULL THEN
--
      OPEN phone_id_cur(l_contact_id, p_phone_type ,'Y');
	FETCH phone_id_cur INTO phone_id_rec;
	l_phone_id := phone_id_rec.phone_id;
	CLOSE phone_id_cur;

        IF l_phone_id IS NULL THEN
            OPEN phone_id_cur(l_contact_id, p_phone_type ,'N');
	    FETCH phone_id_cur INTO phone_id_rec;
	    l_phone_id := phone_id_rec.phone_id;
	    CLOSE phone_id_cur;
        END IF;
--
   END IF;
--
   IF l_phone_id IS NOT NULL THEN
--
      SELECT RTRIM(LTRIM(cont_point.PHONE_AREA_CODE || '-' ||
                    DECODE(CONT_POINT.CONTACT_POINT_TYPE,'TLX',
                           CONT_POINT.TELEX_NUMBER,
                           CONT_POINT.PHONE_NUMBER)||'-'||
			   CONT_POINT.PHONE_EXTENSION, '-'), '-')
      INTO   l_contact_phone
      FROM  HZ_CONTACT_POINTS CONT_POINT
      WHERE CONT_POINT.CONTACT_POINT_ID = l_phone_id;
--
   END IF;

   RETURN l_contact_phone;

EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;


/*========================================================================
 | PUBLIC procedure get_phone
 |
 | DESCRIPTION
 |      Returns contact point of the given contact id
 |      ----------------------------------------
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_contact_id		IN	Customer Id
 |	p_phone_type		IN	contact type like 'PHONE', 'FAX', 'GEN' etc
 |
 | RETURNS
 |      l_contact_phone		Contact type number of the given site at the customer/site level
 | KNOWN ISSUES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 5-JUL-2005           hikumar 	   Created
 *=======================================================================*/
FUNCTION get_phone(p_contact_id IN NUMBER,
                   p_phone_type IN VARCHAR2 DEFAULT  'ALL') RETURN VARCHAR2 AS
l_phone_id      NUMBER := NULL;
l_contact_phone VARCHAR2(2000):= null;
CURSOR phone_id_cur(p_contact_id IN NUMBER DEFAULT  NULL,
			p_phone_type IN VARCHAR2 DEFAULT  'ALL',
                        p_primary_flag IN VARCHAR2 DEFAULT  'Y') IS
	SELECT phone_id FROM
              ( SELECT CONT_POINT.CONTACT_POINT_ID phone_id,
               row_number() OVER ( order by CONT_POINT.last_update_date desc) last_update_record
	      FROM HZ_CUST_ACCOUNT_ROLES          ACCT_ROLE,
		   HZ_CONTACT_POINTS              CONT_POINT
	      WHERE
		  ACCT_ROLE.CUST_ACCOUNT_ROLE_ID      = p_contact_id
	      AND ACCT_ROLE.PARTY_ID = CONT_POINT.OWNER_TABLE_ID
	      AND CONT_POINT.OWNER_TABLE_NAME = 'HZ_PARTIES'
	      AND CONT_POINT.STATUS = 'A'
	      AND INSTRB(NVL(CONT_POINT.PHONE_LINE_TYPE, CONT_POINT.CONTACT_POINT_TYPE) || 'ALL',   p_phone_type) > 0
	      AND CONT_POINT.PRIMARY_FLAG = p_primary_flag
              )
              WHERE last_update_record<=1;

phone_id_rec phone_id_cur%ROWTYPE;

BEGIN
--
  IF p_contact_id IS NOT NULL THEN
--
      OPEN phone_id_cur(p_contact_id, p_phone_type ,'Y');
	FETCH phone_id_cur INTO phone_id_rec;
	l_phone_id := phone_id_rec.phone_id;
	CLOSE phone_id_cur;

        IF l_phone_id IS NULL THEN
            OPEN phone_id_cur(p_contact_id, p_phone_type ,'N');
	    FETCH phone_id_cur INTO phone_id_rec;
	    l_phone_id := phone_id_rec.phone_id;
	    CLOSE phone_id_cur;
        END IF;
--
   END IF;
--
   IF l_phone_id IS NOT NULL THEN
--
      SELECT RTRIM(LTRIM(cont_point.PHONE_AREA_CODE || '-' ||
                    DECODE(CONT_POINT.CONTACT_POINT_TYPE,'TLX',
                           CONT_POINT.TELEX_NUMBER,
                           CONT_POINT.PHONE_NUMBER)||'-'||
			   CONT_POINT.PHONE_EXTENSION, '-'), '-')
      INTO   l_contact_phone
      FROM  HZ_CONTACT_POINTS CONT_POINT
      WHERE CONT_POINT.CONTACT_POINT_ID = l_phone_id;
--
   END IF;

   RETURN l_contact_phone;

EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;




FUNCTION save_payment_instrument_info ( p_customer_id          IN VARCHAR2,
                                        p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN
IS
l_attr varchar2(15):=null;
current_org_id  NUMBER ;
BEGIN
  -- If you do not want to save credit card info set this
  -- flag to false.
  -- Note:
  -- If this is set to false, you cannot use Bank Account
  -- to pay. Please disable bank account ACH payment method

  current_org_id := MO_GLOBAL.GET_CURRENT_ORG_ID ;
  IF (FUN_RULE_OBJECTS_PUB.rule_object_instance_exists(222,'ARI_SAVE_PAYMENT_INSTRUMENT', NULL,current_org_id) ) THEN

    FUN_RULE_PUB.SET_INSTANCE_CONTEXT('ARI_SAVE_PAYMENT_INSTRUMENT', 'AR', NULL, current_org_id );
    FUN_RULE_PUB.init_parameter_list;
    FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_ID',to_number(p_customer_id));
    FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_SITE_USE_ID',to_number(p_customer_site_use_id));
    FUN_RULE_PUB.apply_rule('AR','ARI_SAVE_PAYMENT_INSTRUMENT');
    l_attr := FUN_RULE_PUB.get_string;
    if(l_attr is not null) then
        if l_attr='Y'then
            return true;
        else
            return false;
        end if;
    end if;
  ELSIF (nvl(FND_PROFILE.VALUE('OIR_SAVE_PAYMENT_INSTR_INFO'),'N') = 'N') THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN TRUE;

END save_payment_instrument_info;


FUNCTION  is_save_payment_instr_enabled ( p_customer_id          IN VARCHAR2,
                                          p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2
IS
BEGIN
  IF save_payment_instrument_info(p_customer_id, p_customer_site_use_id) THEN
    RETURN 'Y';
  ELSE
    RETURN 'N';
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RETURN 'Y';

END is_save_payment_instr_enabled;




FUNCTION is_aging_enabled ( p_customer_id          IN VARCHAR2,
                            p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2
IS
l_attr varchar2(15):=NULL;
current_org_id  NUMBER ;
BEGIN
  
  current_org_id := MO_GLOBAL.GET_CURRENT_ORG_ID ;

  IF (FUN_RULE_OBJECTS_PUB.rule_object_instance_exists(222,'ARI_AGING_BUCKETS', NULL,current_org_id) ) THEN

      FUN_RULE_PUB.SET_INSTANCE_CONTEXT('ARI_AGING_BUCKETS', 'AR', NULL, current_org_id );
      FUN_RULE_PUB.init_parameter_list;
      FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_ID',to_number(p_customer_id));
      FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_SITE_USE_ID',to_number(p_customer_site_use_id));
      FUN_RULE_PUB.apply_rule('AR','ARI_AGING_BUCKETS');
      l_attr := FUN_RULE_PUB.get_string;

      IF(l_attr IS NOT NULL) THEN
        RETURN l_attr;
      ELSE
        RETURN (NVL(FND_PROFILE.VALUE('OIR_AGING_BUCKETS'),'0'));
      END IF;
  ELSE
      RETURN (NVL(FND_PROFILE.VALUE('OIR_AGING_BUCKETS'),'0'));
  END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN '0';

END is_aging_enabled;



FUNCTION multi_print_limit ( p_customer_id          IN VARCHAR2,
                             p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2
IS
l_attr varchar2(15):=null;
current_org_id  NUMBER ;
BEGIN
      current_org_id := MO_GLOBAL.GET_CURRENT_ORG_ID ;
      IF (FUN_RULE_OBJECTS_PUB.rule_object_instance_exists(222,'ARI_MULTI_PRINT_LIMIT', NULL,current_org_id) ) THEN

            FUN_RULE_PUB.SET_INSTANCE_CONTEXT('ARI_MULTI_PRINT_LIMIT', 'AR', NULL, current_org_id );
            FUN_RULE_PUB.init_parameter_list;
            FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_ID',to_number(p_customer_id));
            FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_SITE_USE_ID',to_number(p_customer_site_use_id));
            FUN_RULE_PUB.apply_rule('AR','ARI_MULTI_PRINT_LIMIT');
            l_attr := FUN_RULE_PUB.get_string;
            IF(l_attr IS NOT NULL) THEN
              RETURN l_attr;
            ELSE
              RETURN (NVL(FND_PROFILE.VALUE('OIR_BPA_MULTI_PRINT_LIMIT'),'0'));
            END IF;
      ELSE
              RETURN (NVL(FND_PROFILE.VALUE('OIR_BPA_MULTI_PRINT_LIMIT'),'0'));
      END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN '0';

END multi_print_limit;



FUNCTION is_discount_grace_days_enabled ( p_customer_id          IN VARCHAR2,
	                                  p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2
IS
l_attr varchar2(15):=null;
current_org_id  NUMBER ;
BEGIN
      current_org_id := MO_GLOBAL.GET_CURRENT_ORG_ID ;
      IF (FUN_RULE_OBJECTS_PUB.rule_object_instance_exists(222,'ARI_DISCOUNT_GRACE_DAYS', NULL,current_org_id) ) THEN

            FUN_RULE_PUB.SET_INSTANCE_CONTEXT('ARI_DISCOUNT_GRACE_DAYS', 'AR', NULL, current_org_id );
            FUN_RULE_PUB.init_parameter_list;
            FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_ID',to_number(p_customer_id));
            FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_SITE_USE_ID',to_number(p_customer_site_use_id));
            FUN_RULE_PUB.apply_rule('AR','ARI_DISCOUNT_GRACE_DAYS');
            l_attr := FUN_RULE_PUB.get_string;
            IF(l_attr IS NOT NULL) THEN
              RETURN l_attr;
            ELSE
              RETURN (NVL(FND_PROFILE.VALUE('OIR_ENABLE_DISCOUNT_GRACE_DAYS'),'N'));
            END IF;
      ELSE
              RETURN (NVL(FND_PROFILE.VALUE('OIR_ENABLE_DISCOUNT_GRACE_DAYS'),'N'));
      END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'N';

END is_discount_grace_days_enabled;


FUNCTION is_service_charge_enabled ( p_customer_id          IN VARCHAR2,
                                     p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN boolean
IS
l_attr varchar2(15):=null;
current_org_id NUMBER ;
BEGIN
  -- This can be configured to return the appropriate value based on
  -- the service charge needs to be applied

current_org_id := MO_GLOBAL.GET_CURRENT_ORG_ID ;
IF (FUN_RULE_OBJECTS_PUB.rule_object_instance_exists(222,'ARI_SERVICE_CHARGE_ENABLED', NULL,current_org_id) ) THEN

FUN_RULE_PUB.SET_INSTANCE_CONTEXT('ARI_SERVICE_CHARGE_ENABLED', 'AR', NULL, current_org_id );
FUN_RULE_PUB.init_parameter_list;
FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_ID',to_number(p_customer_id));
FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_SITE_USE_ID',to_number(p_customer_site_use_id));
FUN_RULE_PUB.apply_rule('AR','ARI_SERVICE_CHARGE_ENABLED');
l_attr := FUN_RULE_PUB.get_string;
if(l_attr is not null) then
   if l_attr='Y' then
    return true;
   else
    return false;
   end if;
end if;

ELSIF (nvl(FND_PROFILE.VALUE('OIR_ENABLE_SERVICE_CHARGE'),'N') = 'Y') THEN
    RETURN TRUE;
ELSE
    RETURN FALSE;
END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;

END is_service_charge_enabled;




FUNCTION is_discount_grace_days_enabled RETURN BOOLEAN
IS
BEGIN
  -- This can be configured to return the appropriate value based on
  -- whether grace days have to be picked up for discounts.
  IF (nvl(FND_PROFILE.VALUE('OIR_ENABLE_DISCOUNT_GRACE_DAYS'),'N') = 'Y') THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END is_discount_grace_days_enabled;





FUNCTION   get_service_charge_activity_id ( p_customer_id          IN VARCHAR2,
                                            p_customer_site_use_id IN VARCHAR2 DEFAULT NULL ) RETURN NUMBER
IS
CURSOR SYSPARAMCUR IS
  SELECT IREC_SERVICE_CHARGE_REC_TRX_ID FROM AR_SYSTEM_PARAMETERS;
l_attr varchar2(15):=null;
current_org_id  NUMBER ;
BEGIN
  -- This is the activity id for service charge
  -- Please configure this to the activity id at installation site
current_org_id := MO_GLOBAL.GET_CURRENT_ORG_ID ;
IF (FUN_RULE_OBJECTS_PUB.rule_object_instance_exists(222,'ARI_SERVICE_CHARGE_ACTIVITY_ID', NULL,current_org_id) ) THEN

FUN_RULE_PUB.SET_INSTANCE_CONTEXT('ARI_SERVICE_CHARGE_ACTIVITY_ID', 'AR', NULL, current_org_id );
FUN_RULE_PUB.init_parameter_list;
FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_ID',to_number(p_customer_id));
FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_SITE_USE_ID',to_number(p_customer_site_use_id));
FUN_RULE_PUB.apply_rule('AR','ARI_SERVICE_CHARGE_ACTIVITY_ID');
l_attr := FUN_RULE_PUB.get_string;
if(l_attr is not null) then
   return to_number(l_attr);
end if;

END IF ;

FOR rec IN SYSPARAMCUR
  LOOP
   RETURN NVL(rec.IREC_SERVICE_CHARGE_REC_TRX_ID,0);
  END LOOP;

RETURN 0 ;

EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END get_service_charge_activity_id;


PROCEDURE get_contact_info (
        p_customer_id           IN      VARCHAR2,
        p_customer_site_use_id  IN      VARCHAR2,
        p_language_string       IN      VARCHAR2,
        p_page                  IN      VARCHAR2,
        p_trx_id                IN      VARCHAR2,
        p_output_string         OUT NOCOPY      VARCHAR2
) IS
l_attr varchar2(200):=null;
current_org_id  NUMBER ;
l_org_id NUMBER;
BEGIN

current_org_id := MO_GLOBAL.GET_CURRENT_ORG_ID ;
--Bug 12719843 - In Customer Search Page, since the Org Id set is -1 always, get the MO:Default Operating Unit
--value in the page and apply the rule against the Default OU.
if('ARI_CUSTOMER_SEARCH' = p_page) then
  l_org_id := fnd_profile.value('DEFAULT_ORG_ID');
  if(l_org_id is not null AND l_org_id <> '-1') then
    current_org_id := l_org_id;
  end if;
end if;

if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||'GET_CONTACT_INFO','current_org_id => ' || current_org_id);
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||'GET_CONTACT_INFO','p_page => ' || p_page);
end if;

IF (FUN_RULE_OBJECTS_PUB.rule_object_instance_exists(222,'ARI_CONTACT_INFO', NULL,current_org_id) ) THEN

FUN_RULE_PUB.SET_INSTANCE_CONTEXT('ARI_CONTACT_INFO', 'AR', NULL, current_org_id );
FUN_RULE_PUB.init_parameter_list;
FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_ID',to_number(p_customer_id));
FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_SITE_USE_ID',to_number(p_customer_site_use_id));
FUN_RULE_PUB.add_parameter('ARI_LANGUAGE_STRING',p_language_string);
FUN_RULE_PUB.add_parameter('ARI_PAGE',p_page);
/* Fix for the Bug# 5054123. The below parameter 'ARI_TRX_ID' is not used anywhere.
 * Moreover, it can sometimes take the value of a URL and so it is not always a number.
 * So the below conversion can result in an error (Eg: for DISPUTE) and so it is commented out.
 */
--FUN_RULE_PUB.add_parameter('ARI_TRX_ID',to_number(p_trx_id));
FUN_RULE_PUB.apply_rule('AR','ARI_CONTACT_INFO');

l_attr := FUN_RULE_PUB.get_string;
if (l_attr is null) then
  SELECT WEB_HTML_CALL INTO l_attr FROM FND_FORM_FUNCTIONS WHERE FUNCTION_NAME LIKE 'ARICONTACTUS';
end if;

p_output_string := l_attr;

ELSE
 SELECT WEB_HTML_CALL INTO p_output_string FROM FND_FORM_FUNCTIONS WHERE FUNCTION_NAME LIKE 'ARICONTACTUS';
END IF ;

if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||'GET_CONTACT_INFO','p_output_string => ' || p_output_string);
end if;

END get_contact_info;




FUNCTION  get_max_future_payment_date( p_customer_id          IN VARCHAR2,
                                       p_customer_site_use_id IN VARCHAR2 DEFAULT NULL) RETURN DATE
IS
l_attr varchar2(15):=null;
current_org_id NUMBER  ;
BEGIN
  -- This date will be used to validate that any future dated payments
  -- are not beyond this date.

current_org_id := MO_GLOBAL.GET_CURRENT_ORG_ID ;
IF (FUN_RULE_OBJECTS_PUB.rule_object_instance_exists(222,'ARI_MAX_FUTURE_PAYMENT_DATE', NULL,current_org_id) ) THEN

FUN_RULE_PUB.SET_INSTANCE_CONTEXT('ARI_MAX_FUTURE_PAYMENT_DATE', 'AR', NULL, current_org_id );
FUN_RULE_PUB.init_parameter_list;
FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_ID',to_number(p_customer_id));
FUN_RULE_PUB.add_parameter('ARI_CUSTOMER_SITE_USE_ID',to_number(p_customer_site_use_id));
FUN_RULE_PUB.apply_rule('AR','ARI_MAX_FUTURE_PAYMENT_DATE');
l_attr := FUN_RULE_PUB.get_string;
if(l_attr is not null AND l_attr > 0) then  --Added condition for Bug #17714122
   RETURN TRUNC(SYSDATE+to_number(l_attr));
elsif(l_attr <= 0) then --Added elsif condition for Bug #17714122
   RETURN TRUNC(SYSDATE + NVL(FND_PROFILE.VALUE('OIR_MAX_FUTURE_PAYMENT_DAYS_ALLOWED'),365));
end if;

END IF;

RETURN TRUNC(SYSDATE + NVL(FND_PROFILE.VALUE('OIR_MAX_FUTURE_PAYMENT_DAYS_ALLOWED'),365));

EXCEPTION
    WHEN OTHERS THEN
        RETURN TRUNC(SYSDATE + 365);

END get_max_future_payment_date;




FUNCTION get_site_use_location (p_address_id IN NUMBER) RETURN VARCHAR2 AS
--
   l_site_uses  VARCHAR2(4000) := '';
--
   l_separator  VARCHAR2(2) := '';
--
CURSOR c01 (addr_id VARCHAR2) IS
SELECT
  unique( LOCATION)
FROM
   hz_cust_site_uses
WHERE
    cust_acct_site_id = addr_id
AND status    = 'A'   ;
l_procedure_name   VARCHAR2(50);
l_debug_info VARCHAR2(200);
--
BEGIN
--

--
  l_procedure_name := '.get_site_use_location';
  ----------------------------------------------------------------------------------------
  l_debug_info := 'Fetch Bill to Location';
  -----------------------------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug(l_debug_info);
  END IF;

   FOR c01_rec IN c01 (p_address_id) LOOP
       l_site_uses := l_site_uses || l_separator ||c01_rec.location;

       IF l_separator IS NULL THEN
          l_separator := ', ';
       END IF;

   END LOOP;
--
 RETURN l_site_uses;

 EXCEPTION
    WHEN OTHERS THEN
         IF (PG_DEBUG = 'Y') THEN
                    arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
                    arp_standard.debug('ERROR =>'|| SQLERRM);
                    arp_standard.debug('Debug Info : '||l_debug_info);
         END IF;

END;

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
 | 17-JAN-2006           rsinthre               Created
 | 21-JAN-2007           abathini               Modified for Bug 6503280
 *=======================================================================*/
FUNCTION get_site_use_code (p_address_id IN NUMBER) RETURN VARCHAR2 AS
   l_site_use_codes  VARCHAR2(4000) := '';
   l_separator  VARCHAR2(2) := '';
CURSOR c01 (addr_id VARCHAR2) IS
SELECT
   SITE_USE_CODE, SITE_USE_ID
FROM
   hz_cust_site_uses
WHERE
    cust_acct_site_id = addr_id;
--AND status    = 'A'   ;
/*Bug 6503280: Commented out above condition on checking status='A'
 * to allow Drill Down from Inactive Sites from Customer Search Page*/
l_procedure_name   VARCHAR2(50);
l_debug_info VARCHAR2(200);
--
BEGIN
--
   G_BILL_TO_SITE_USE_ID := 0;
--
  l_procedure_name := '.get_site_use_code';
  ----------------------------------------------------------------------------------------
  l_debug_info := 'Fetch Bill to Site use id';
  -----------------------------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug(l_debug_info);
  END IF;

   FOR c01_rec IN c01 (p_address_id) LOOP
       l_site_use_codes := l_site_use_codes || l_separator || c01_rec.site_use_code;

       IF c01_rec.site_use_code = 'BILL_TO' THEN
	  G_BILL_TO_SITE_USE_ID := c01_rec.site_use_id;
       END IF;

       IF l_separator IS NULL THEN
	  l_separator := ', ';
       END IF;

   END LOOP;
--
 RETURN l_site_use_codes;

 EXCEPTION
    WHEN OTHERS THEN
         IF (PG_DEBUG = 'Y') THEN
		    arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
		    arp_standard.debug('ERROR =>'|| SQLERRM);
		    arp_standard.debug('Debug Info : '||l_debug_info);
	 END IF;



END get_site_use_code;

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
  FUNCTION validate_ACH_routing_number(p_routing_number IN  VARCHAR2) RETURN NUMBER IS
    /*-----------------------------------------------------+
     | Cursor to fetch bank branch based on routing number |
     +-----------------------------------------------------*/
     CURSOR bank_branch_cur IS
       SELECT branch_party_id bank_branch_id
       FROM   ce_bank_branches_v
       WHERE  branch_number = p_routing_number
       and   nvl(trunc(end_date), trunc(sysdate)) >= trunc(sysdate);

    CURSOR bank_directory_cur IS
    	SELECT bank_name
    	FROM AR_BANK_DIRECTORY
    	WHERE routing_number = p_routing_number;

     bank_branch_rec             bank_branch_cur%ROWTYPE;
     bank_directory_rec          bank_directory_cur%ROWTYPE;
     l_routing_number_validation fnd_profile_option_values.profile_option_value%TYPE;
     l_result                    NUMBER;
     l_procedure_name VARCHAR2(30);

   BEGIN

      l_procedure_name         := '.validate_ACH_routing_number';

      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	  		fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Begin validate_ACH_routing_number');
      end if;


    /*--------------------------------------------------------------------+
     | Validate that the routing number cheksum is correct                |
     | bug # 9283134 -  canadian transit numbers are not accepted in irec |
     +--------------------------------------------------------------------*/
     l_routing_number_validation := FND_PROFILE.value('OIR_SKIP_ROUT_NUM_VALID');
     if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
       fnd_log.string(fnd_log.LEVEL_STATEMENT,'.validate_ACH_routing_number',
                 ' OIR: Skip Routing Number Validation :: '||l_routing_number_validation);
     end if;

     if l_routing_number_validation = 'Y' then
       l_result := 1;
     else
       l_result := validate_ACH_checksum(p_routing_number);
     end if;

     IF l_result = 0 THEN
       RETURN 0;
     END IF;

    /*-------------------------------------------------------------+
     | Validate if the routing number already exists in the system |
     +-------------------------------------------------------------*/
     OPEN bank_branch_cur;
     FETCH bank_branch_cur INTO bank_branch_rec;
     IF (bank_branch_cur%FOUND) then
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	  			fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Found routing number in ce_bank_branches_v');
      end if;
       CLOSE bank_branch_cur;
       RETURN 1;
     ELSE
       CLOSE bank_branch_cur;
     END IF;

     l_routing_number_validation := NVL(FND_PROFILE.value('AR_BANK_DIRECTORY_SOURCE'),'NONE');

      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	  			fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'profile AR_BANK_DIRECTORY_SOURCE value :: '||l_routing_number_validation);
      end if;

    /*-----------------------------------------------------+
     | If source is 'NONE' then no validate routing number against AR_BANKD_DIRECTORY |
     +-----------------------------------------------------*/
     IF NVL(l_routing_number_validation,'NONE') <> 'NONE'  THEN

		 OPEN bank_directory_cur;
     FETCH bank_directory_cur INTO bank_directory_rec;
     IF (bank_directory_cur%FOUND) then
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	  				fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Found routing number in AR_BANK_DIRECTORY');
      end if;
       CLOSE bank_directory_cur;
       RETURN 1;
     ELSE
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	  				fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Routing Number not found in AR_BANK_DIRECTORY');
      end if;
      CLOSE bank_directory_cur;
     	RETURN 0;
     END IF;

    ELSE
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	  				fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Routing Number not found in ce_bank_branches_v');
      end if;
        RETURN 0;
   END IF;

  END validate_ACH_routing_number;

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
                                 p_routing_number_type IN VARCHAR2 DEFAULT 'ABA') RETURN NUMBER IS

BEGIN

   if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
      fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME,' Begin is_routing_number_valid ');
      fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME,'  p_routing_number_type :: '||p_routing_number_type);
   end if;

  if p_routing_number_type = 'ABA' then

    return validate_ACH_routing_number(p_routing_number);

  else
     return 0;
  end if;

END is_routing_number_valid;

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
 |      TRUE  if ACH Routing number is valid
 |      FALSE if ACH Routing number is invalid
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
 | 27-Aug-2009           avepati           Created
 |
 *=======================================================================*/
FUNCTION validate_ACH_checksum (p_routing_number IN VARCHAR2) RETURN number IS

  l_routing_num_stripped  ap_bank_accounts.bank_account_num%TYPE;
  cheksum NUMBER := 0;
  counter NUMBER := 1;

BEGIN

   if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
      fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME,' Begin validate_ACH_checksum ');
   end if;

 /*---------------------------------+
  | Remove all non-digit characters |
  +---------------------------------*/
  if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
      fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME,' calling ari_utilities.strip_white_spaces p_routing_number ::'||p_routing_number);
   end if;

  ari_utilities.strip_white_spaces (p_routing_number,
                                   l_routing_num_stripped);

   if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
      fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME,' Stripped Routing number l_routing_num_stripped ::'||l_routing_num_stripped);
   end if;

 /*--------------------------------------------+
  | ACH routing number has to be 9 digits long |
  +--------------------------------------------*/
  if length(l_routing_num_stripped) <> 9 then
     return 0;
  else
   /*---------------------------------------------------+
    | Loop through the routing number incrementing by 3 |
    +---------------------------------------------------*/
    while counter < length(l_routing_num_stripped) loop
     /*------------------------------------------+
      | Multiply digits by the algorithm numbers |
      +------------------------------------------*/
      cheksum := cheksum +
                 to_number(substr(l_routing_num_stripped,counter,1))   * 3 +
                 to_number(substr(l_routing_num_stripped,counter+1,1)) * 7 +
                 to_number(substr(l_routing_num_stripped,counter+2,1));

      counter := counter + 3;

    end loop;

   if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
      fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME,' Routing number checksum  ::'||cheksum);
   end if;    /*-------------------------------------------------+
    | If the resulting sum is an even multiple of ten |
    | (but not zero), the ach routing number is good. |
    +-------------------------------------------------*/
    if (cheksum <> 0 and mod(cheksum,10) = 0) then
      return 1;
    else
      return 0;
    end if;
  end if;

END validate_ACH_checksum;

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

PROCEDURE strip_white_spaces(
	p_num_to_strip       IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
	p_stripped_num	OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE
  ) IS

  TYPE character_tab_typ IS TABLE of char(1) INDEX BY BINARY_INTEGER;
  len_strip_num 	number := 0;
  l_strip_num_char		character_tab_typ;
  BEGIN
	IF PG_DEBUG in ('Y', 'C') THEN
	   arp_standard.debug('ari_utilities.strip_white_spaces()+');
	END IF;

	SELECT lengthb(p_num_to_strip)
	INTO   len_strip_num
	FROM   dual;

	FOR i in 1..len_strip_num LOOP
	 	SELECT substrb(p_num_to_strip,i,1)
		INTO   l_strip_num_char(i)
		FROM   dual;

		IF ( (l_strip_num_char(i) >= '0') and
		     (l_strip_num_char(i) <= '9')
		   )
		THEN
		    -- Numeric digit. Add to stripped_number and table.
		    p_stripped_num := p_stripped_num || l_strip_num_char(i);
		END IF;
	END LOOP;

	IF PG_DEBUG in ('Y', 'C') THEN
	   arp_standard.debug('ari_utilities.strip_white_spaces()-');
	END IF;
  EXCEPTION
	when OTHERS then
		raise;
  END strip_white_spaces;

FUNCTION get_group_header(p_customer_id IN NUMBER,
                   p_party_id IN NUMBER , p_trx_number IN VARCHAR) RETURN NUMBER AS

l_account_access_count  NUMBER := NULL;
l_site_access_count NUMBER :=NULL;
l_flag NUMBER := NULL;

BEGIN

select count(*) into l_account_access_count from ar_customers_assigned_v hzca where hzca.cust_account_id = p_customer_id
and hzca.party_id=p_party_id;


IF l_account_access_count > 0 THEN
	RETURN 0;
END IF;

select count(*) into l_site_access_count from ar_sites_assigned_v acct_sites_count
				where acct_sites_count.party_id=p_party_id
				and acct_sites_count.cust_account_id=p_customer_id
				and INSTR(ARI_UTILITIES.GET_SITE_USE_CODE(acct_sites_count.CUST_ACCT_SITE_ID), 'BILL_TO')>0;

select count(*) into l_flag from(
	select trx_number,CUSTOMER_SITE_USE_ID from ar_payment_schedules where trx_number=p_trx_number
				and CUSTOMER_SITE_USE_ID in
				(
				 select ARI_UTILITIES.get_bill_to_site_use_id(CUST_ACCT_SITE_ID) from ar_sites_assigned_v where
				 party_id=p_party_id
				 and cust_account_id=p_customer_id
				)
	);

IF l_site_access_count > 1 AND l_flag > 0   THEN
	RETURN 1;
ELSE
	RETURN 2;
END IF;

END get_group_header;

FUNCTION invoke_invoice_email_notwf( p_subscription_guid In RAW , p_event IN OUT NOCOPY  WF_EVENT_T ) return varchar2 AS

  l_trx_number       VARCHAR2(30);
  l_customer_trx_id  NUMBER(15);
  l_org_id           NUMBER;
  l_user_id          NUMBER;
  l_resp_id          NUMBER;
  l_application_id   NUMBER;

  l_customer_id  NUMBER(15) := NULL;
  l_customer_acct_site_id NUMBER(15) := NULL;
  l_customer_acct_number  NUMBER(15) := NULL;
  l_customer_acct_name hz_parties.party_name%TYPE;


  l_procedure_name      VARCHAR2(30) 	:= '.invoke_invoice_email_notwf';
  l_debug_info          VARCHAR2(500);

  l_itemtype VARCHAR2(20) := 'ARINVNTF';

BEGIN

  --------------------------------------------------------------------
  l_debug_info := 'In debug mode, log we have entered this procedure';
  --------------------------------------------------------------------
  IF (PG_DEBUG = 'Y') THEN
     arp_standard.debug(G_PKG_NAME || l_procedure_name || '+');
  END IF;

  l_customer_trx_id := p_event.GetValueForParameter('CUSTOMER_TRX_ID');
  l_org_id          := p_event.GetValueForParameter('ORG_ID');
  l_user_id         := p_event.GetValueForParameter('USER_ID');
  l_resp_id         := p_event.GetValueForParameter('RESP_ID');
  l_application_id  := p_event.GetValueForParameter('RESP_APPL_ID');

  IF (PG_DEBUG = 'Y') THEN

        arp_standard.debug ('l_customer_trx_id ='||l_customer_trx_id);
        arp_standard.debug ('l_org_id ='||l_org_id);
        arp_standard.debug ('l_user_id ='||l_user_id);
        arp_standard.debug ('l_resp_id ='||l_resp_id);
        arp_standard.debug ('l_application_id ='||l_application_id);
   END IF;

  fnd_global.apps_initialize(l_user_id,l_resp_id,l_application_id);

  mo_global.init('AR');
  mo_global.set_policy_context('M',l_org_id);

   --------------------------------------------------------------------
  l_debug_info := 'fetching customer_id,customer_site_use_id and trx number';
  --------------------------------------------------------------------

  select aps.customer_id,sites.CUST_ACCT_SITE_ID,aps.trx_number
  into l_customer_id,l_customer_acct_site_id,l_trx_number
  from ar_payment_schedules_all aps,HZ_CUST_SITE_USES     sites
  where aps.customer_trx_id = l_customer_trx_id
  and aps.org_id = l_org_id
  and sites.site_use_id = aps.customer_site_use_id;

  select hp.party_name,hca.account_number
  into l_customer_acct_name,l_customer_acct_number
  from hz_parties hp,hz_cust_accounts hca
  where hp.party_id = hca.party_id
  and hca.cust_account_id = l_customer_id;

  IF (PG_DEBUG = 'Y') THEN
     arp_standard.debug(G_PKG_NAME || l_procedure_name || l_customer_id || '+');
     arp_standard.debug(G_PKG_NAME || l_procedure_name || l_customer_acct_site_id || '+');
     arp_standard.debug(G_PKG_NAME || l_procedure_name || l_trx_number || '+');
  END IF;

  --------------------------------------------------------------------
    l_debug_info := 'creating workflow process';
  --------------------------------------------------------------------

  WF_ENGINE.CREATEPROCESS(l_itemtype,
                           l_customer_trx_id,
                          'ARI_INVOICE_NTF_PROCESS');

   ----------------------------------------------------------------------------
  l_debug_info := 'Set parameters expected by ARINVNTF Workflow';
  ----------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  l_debug_info := 'Set ARI_CUSTOMER_TRX_ID parameter';
  ----------------------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_CUSTOMER_TRX_ID',
                              l_customer_trx_id);

  ----------------------------------------------------------------------------
  l_debug_info := 'Set ARI_TRX_NUM parameter';
  ----------------------------------------------------------------------------

  WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_TRX_NUMBER',
                              l_trx_number);

  ----------------------------------------------------------------------------
  l_debug_info := 'Set ARI_CUST_ACCT_NUM parameter';
  ----------------------------------------------------------------------------

  WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_CUST_ACCT_NUM',
                              l_customer_acct_number);

  ----------------------------------------------------------------------------
  l_debug_info := 'Set ARI_CUST_ACCT_ID parameter';
  ----------------------------------------------------------------------------

  WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_CUST_ACCT_ID',
                              l_customer_id);

  ----------------------------------------------------------------------------
  l_debug_info := 'Set ARI_CUST_ACCT_NAME parameter';
  ----------------------------------------------------------------------------

  WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_CUST_ACCT_NAME',
                              l_customer_acct_name);

  ----------------------------------------------------------------------------
  l_debug_info := 'Set ARI_CUST_ACCT_SITE_NUM parameter';
  ----------------------------------------------------------------------------

  WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_CUST_ACCT_SITE_ID',
                              l_customer_acct_site_id);

  ----------------------------------------------------------------------------
  l_debug_info := 'Starting Workflow..';
  ----------------------------------------------------------------------------

  IF (PG_DEBUG = 'Y') THEN
     arp_standard.debug(G_PKG_NAME || l_procedure_name || 'End time:' || TO_CHAR(SYSDATE, 'HH24:MI:SSSSS') || '+');
  END IF;

  WF_ENGINE.StartProcess(l_itemtype,l_customer_trx_id);


   RETURN 'SUCCESS';

 EXCEPTION
    WHEN OTHERS THEN
         IF (PG_DEBUG = 'Y') THEN
		    arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
		    arp_standard.debug('ERROR =>'|| SQLERRM);
		    arp_standard.debug('Debug Info : '||l_debug_info);
	 END IF;
    RETURN 'ERROR';

END invoke_invoice_email_notwf;

FUNCTION get_contact_emails_adhoc_list( p_customer_id IN VARCHAR2,
                             p_customer_acct_site_id IN VARCHAR2 ) RETURN VARCHAR2 AS

  l_adhoc_user_name          VARCHAR2(200);
  l_adhoc_user_display_name  VARCHAR2(200);

  l_email_address hz_contact_points.email_Address%TYPE;
  l_user_email_addr_list email_addr_type;
  l_adhoc_users_list varchar2 (32760) := null;
  l_contact_id NUMBER := NULL;
  i       PLS_INTEGER := 1 ;

  l_procedure_name      VARCHAR2(30) 	:= '.get_contact_emails';
  l_debug_info          VARCHAR2(500);

CURSOR contact_cur(p_customer_id IN NUMBER ,
			p_customer_acct_site_id IN NUMBER ) IS
          SELECT hcar.CUST_ACCOUNT_ROLE_ID as contact_id
          FROM HZ_CUST_ACCOUNT_ROLES hcar, HZ_PARTIES hpsub, HZ_PARTIES hprel,
            HZ_ORG_CONTACTS hoc, HZ_RELATIONSHIPS hr, HZ_PARTY_SITES hps, FND_TERRITORIES_VL ftv,
            fnd_lookup_values_vl lookups,hz_role_responsibility hrr
          WHERE hrr.responsibility_type = 'SELF_SERVICE_USER'
            and hrr.cust_account_role_id = hcar.cust_account_role_id
            and hcar.CUST_ACCOUNT_ID = p_customer_id
            AND hcar.ROLE_TYPE = 'CONTACT'
            AND hcar.PARTY_ID = hr.PARTY_ID
            AND hr.PARTY_ID = hprel.PARTY_ID
            AND hr.SUBJECT_ID = hpsub.PARTY_ID
            AND hoc.PARTY_RELATIONSHIP_ID = hr.RELATIONSHIP_ID
            AND hr.DIRECTIONAL_FLAG = 'F'
            AND hps.PARTY_ID(+) = hprel.PARTY_ID
            AND nvl(hps.IDENTIFYING_ADDRESS_FLAG, 'Y') = 'Y'
            AND nvl(hps.STATUS, 'A') = 'A'
            AND hprel.COUNTRY = ftv.TERRITORY_CODE(+)
            AND nvl(hcar.CUST_ACCT_SITE_ID, 1) = nvl(p_customer_acct_site_id, 1)
            AND lookups.LOOKUP_TYPE (+)='RESPONSIBILITY'
            AND lookups.LOOKUP_CODE(+)=hoc.JOB_TITLE_CODE
            and hcar.status='A';

CURSOR email_addr_cur  (l_contact_id IN NUMBER DEFAULT NULL) IS
        SELECT cont_point.email_Address
        FROM hz_cust_account_roles acct_role,
          hz_contact_points cont_point
        WHERE acct_role.cust_account_role_id =l_contact_id
         AND acct_role.party_id = cont_point.owner_table_id
         AND cont_point.owner_table_name = 'HZ_PARTIES'
         AND cont_point.status = 'A'
         AND cont_point.email_Address is not null;

contact_rec contact_cur%ROWTYPE;
email_addr_rec email_addr_cur%ROWTYPE;

BEGIN

    ----------------------------------------------------------------------------------------
    l_debug_info := 'fetches all email addres at account level  for all self sevice users';
    -----------------------------------------------------------------------------------------
    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(l_debug_info);
    END IF;

FOR contact_rec in contact_cur(p_customer_id,NULL) LOOP

    l_contact_id :=  contact_rec.contact_id;

    FOR email_addr_rec in email_addr_cur( l_contact_id )  LOOP
         l_email_address :=  email_addr_rec.email_Address;
          if (l_email_address is not null) then
              l_adhoc_user_name  :=  remove_existing_user_role(p_email_address => l_email_address);
           if (l_adhoc_user_name is null ) then
                  l_adhoc_user_name := SUBSTRB(l_email_address,1,INSTRB(l_email_address,'@')-1) || to_char(sysdate, 'YYYYMMDD_HH24MISSSS');
                  l_adhoc_user_display_name := l_adhoc_user_name;

                    ------------------------------------------------------------
                    l_debug_info := 'Create AdHoc Workflow User';
                    ------------------------------------------------------------

                      WF_DIRECTORY.CreateAdHocUser(name                     => l_adhoc_user_name,
                                                   display_name             => l_adhoc_user_display_name,
                                                   email_address            => l_email_address);
                end if;
            end if;

            l_user_email_addr_list(i) := l_adhoc_user_name;

            ----------------------------------------------------------------------------------------
            l_debug_info := 'emails at account level';
            -----------------------------------------------------------------------------------------
            IF (PG_DEBUG = 'Y') THEN
               arp_standard.debug(G_PKG_NAME || l_procedure_name || 'emails adhoc user list at Account Level ' || l_user_email_addr_list(i));
             END IF;

            i := i+1;

    END LOOP;

END LOOP;

    ----------------------------------------------------------------------------------------
    l_debug_info := 'fetches all email addres at site level  for all self sevice users';
    -----------------------------------------------------------------------------------------

FOR contact_rec in contact_cur(p_customer_id,p_customer_acct_site_id) LOOP

    l_contact_id :=  contact_rec.contact_id;

    FOR email_addr_rec in email_addr_cur( l_contact_id )  LOOP
         l_email_address :=  email_addr_rec.email_Address;
          if (l_email_address is not null) then
              l_adhoc_user_name  :=  remove_existing_user_role(p_email_address => l_email_address);
              if (l_adhoc_user_name is null ) then
                  l_adhoc_user_name := SUBSTRB(l_email_address,1,INSTRB(l_email_address,'@')-1) || to_char(sysdate, 'YYYYMMDD_HH24MISS');
                  l_adhoc_user_display_name := l_adhoc_user_name;

                    ------------------------------------------------------------
                    l_debug_info := 'Create AdHoc Workflow User';
                    ------------------------------------------------------------

                      WF_DIRECTORY.CreateAdHocUser(name                     => l_adhoc_user_name,
                                                   display_name             => l_adhoc_user_display_name,
                                                   email_address            => l_email_address);
              end if;
      end if;

     l_user_email_addr_list(i) := l_adhoc_user_name;

     ----------------------------------------------------------------------------------------
     l_debug_info := 'emails at account level';
     -----------------------------------------------------------------------------------------
     IF (PG_DEBUG = 'Y') THEN
         arp_standard.debug(G_PKG_NAME || l_procedure_name || 'emails adhoc user list at Site Level ' || l_user_email_addr_list(i));
     END IF;

     i := i+1;

    END LOOP;
END LOOP;


  l_adhoc_users_list :=  remove_duplicate_user_names( l_user_email_list => l_user_email_addr_list);

      IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || 'emails adhoc user list after Removing Duplicates ' || l_adhoc_users_list);
    END IF;

RETURN l_adhoc_users_list;

 EXCEPTION
    WHEN OTHERS THEN
         IF (PG_DEBUG = 'Y') THEN
		    arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
		    arp_standard.debug('ERROR =>'|| SQLERRM);
		    arp_standard.debug('Debug Info : '||l_debug_info);
	 END IF;
   RETURN 'ERROR';

END get_contact_emails_adhoc_list;

FUNCTION remove_duplicate_user_names(l_user_email_list IN  email_addr_type ) RETURN VARCHAR2 AS

  l_adhoc_users_list varchar2 (32760) := null;
  v_email_list email_addr_type;

  l_procedure_name      VARCHAR2(30) 	:= '.remove_duplicate_user_names';
  l_debug_info          VARCHAR2(500);

Begin

    v_email_list := l_user_email_list;
      ----------------------------------------------------------------------------------------
    l_debug_info := 'Removes All the Dulicate Uses in the List';
    -----------------------------------------------------------------------------------------
    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(l_debug_info);
    END IF;


   for i in 1..v_email_list.count loop
      for j in i+1..v_email_list.count loop
             if ( v_email_list(j) = v_email_list(i) ) then
                v_email_list(j) := 'REMOVED';

             end if;
        end loop;
 end loop;

     for k in 1..v_email_list.count loop
          if (v_email_list(k) <> 'REMOVED' and l_adhoc_users_list is null) then
              l_adhoc_users_list := v_email_list(k);

          elsif (v_email_list(k) <> 'REMOVED' and l_adhoc_users_list is not null) then
               l_adhoc_users_list := l_adhoc_users_list || ',' || v_email_list(k);

          end if;
     end loop;

     return l_adhoc_users_list;

end remove_duplicate_user_names;

FUNCTION remove_existing_user_role( p_email_address IN VARCHAR2 )   RETURN VARCHAR2 AS

   l_adhoc_user_name varchar2(1000) default null;
  l_adhoc_role_name varchar2(1000) default null;

  l_procedure_name      VARCHAR2(30) 	:= '.remove_existing_user_role';
  l_debug_info          VARCHAR2(500);

  CURSOR user_name_by_email_addr  (p_email_address IN varchar2 DEFAULT NULL) IS
  select name from wf_local_roles
  where upper(EMAIL_ADDRESS) = UPPER(p_email_address)
  and  ORIG_SYSTEM = 'WF_LOCAL_USERS'
  and  STATUS ='ACTIVE'
  and  USER_FLAG = 'Y'
  order by last_update_date desc;

  CURSOR user_role_by_email_addr  (l_adhoc_user_name IN varchar2 DEFAULT NULL) IS
  select role_name from wf_local_user_roles
  where user_name = l_adhoc_user_name
  and user_orig_system ='WF_LOCAL_USERS'
  and role_orig_system ='WF_LOCAL_ROLES';

  user_name_by_email_addr_rec user_name_by_email_addr%ROWTYPE;
  user_role_by_email_addr_rec user_role_by_email_addr%ROWTYPE;

  BEGIN

      ----------------------------------------------------------------------------------------
    l_debug_info := 'Checks whether the user is already created are not if created the value will be re-used';
    -----------------------------------------------------------------------------------------
    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(l_debug_info);
    END IF;

  -- Checks whether the user is already created are not.. if created the loop will exit and re-use the existing value
  FOR user_name_by_email_addr_rec in user_name_by_email_addr(p_email_address) LOOP

     l_adhoc_user_name := user_name_by_email_addr_rec.name;
    IF (PG_DEBUG = 'Y') THEN
         arp_standard.debug(G_PKG_NAME || l_procedure_name || 'Existing Adhoc user ' || l_adhoc_user_name);
     END IF;
     exit when user_name_by_email_addr%rowcount>0;
  end loop;

  -- removes the user from the role to which user has already assinged.

   FOR user_role_by_email_addr_rec in user_role_by_email_addr(l_adhoc_user_name) LOOP

     l_adhoc_role_name := user_role_by_email_addr_rec.role_name;

     WF_DIRECTORY.RemoveUsersFromAdHocRole (role_name =>l_adhoc_role_name,
                                            role_users => l_adhoc_user_name);
    IF (PG_DEBUG = 'Y') THEN
         arp_standard.debug(G_PKG_NAME || l_procedure_name || 'removed the user '|| l_adhoc_user_name ||' from the role ' || l_adhoc_role_name);
     END IF;
  end loop;


  return l_adhoc_user_name;

  END remove_existing_user_role;

PROCEDURE det_if_send_email(   l_itemtype    in   varchar2,
                                l_itemkey     in   varchar2,
                                actid       in   number,
                                funcmode    in   varchar2,
                                rslt      out NOCOPY  varchar2 ) IS

  l_adhoc_user_name          VARCHAR2(200);
  l_adhoc_user_display_name  VARCHAR2(200);
  l_role_prefix VARCHAR2(14) := 'ARINVNTF_';
  l_role_exists NUMBER;


  l_customer_trx_id  NUMBER ;
  l_users_list varchar2(3000) := null;
  p_customer_id  NUMBER := NULL;
  p_customer_acct_site_id NUMBER  := NULL;

  l_trx_number      VARCHAR2(30)  :=null;
  l_trx_type        VARCHAR2(20) :=null;
  l_trx_curr_code   VARCHAR2(15)  :=null;
  l_trx_term_name       VARCHAR2(15)  := null;
  l_trx_term_desc       VARCHAR2(240) :=null;
  l_trx_due_date    DATE;
  l_trx_amt_due     NUMBER;

  l_procedure_name      VARCHAR2(30) 	:= '.det_if_send_email';
  l_result_code         VARCHAR2(25);
  l_debug_info          VARCHAR2(500);

BEGIN

    -----------------------------------------------------------
    l_debug_info := 'Retrieve ARI_CUSTOMER_TRX_ID Item Attribute';
    -----------------------------------------------------------

    l_customer_trx_id:= wf_engine.GetItemAttrText(itemtype  => l_itemtype,
                                                 itemkey   => l_itemkey,
                                                 aname     => 'ARI_CUSTOMER_TRX_ID');
    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || 'ARI_CUSTOMER_TRX_ID ::' || l_customer_trx_id );
    END IF;

    -----------------------------------------------------------
    l_debug_info := 'Retrieve ARI_TRX_NUM Item Attribute';
    -----------------------------------------------------------

    l_trx_number:= wf_engine.GetItemAttrText(itemtype  => l_itemtype,
                                                 itemkey   => l_itemkey,
                                                 aname     => 'ARI_TRX_NUMBER');
    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || 'ARI_TRX_NUMBER ::' || l_trx_number);
    END IF;

    -----------------------------------------------------------
    l_debug_info := 'Retrieve ARI_CUST_ACCT_NUM Item Attribute';
    -----------------------------------------------------------

    p_customer_id:= wf_engine.GetItemAttrText(itemtype  => l_itemtype,
                                                itemkey   => l_itemkey,
                                                aname     => 'ARI_CUST_ACCT_ID');
    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || 'ARI_CUST_ACCT_ID ::' || p_customer_id );
    END IF;

    ---------------------------------------------------------------
    l_debug_info := 'Retrieve ARI_CUST_ACCT_SITE_ID Item Attribute';
    ----------------------------------------------------------------

    p_customer_acct_site_id :=  wf_engine.GetItemAttrText(itemtype  => l_itemtype,
                                                itemkey   => l_itemkey,
                                                aname     => 'ARI_CUST_ACCT_SITE_ID');

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || 'ARI_CUST_ACCT_SITE_ID ::' || p_customer_acct_site_id );
    END IF;

    --------------------------------------------------------------------------
    l_debug_info := 'selecting all the attributes required to send in notification';
    ---------------------------------------------------------------------------

    select aps.trx_number,aps.amount_due_original,aps.invoice_currency_code,aps.due_date,t.name,t.description,aps.class
    into l_trx_number,l_trx_amt_due,l_trx_curr_code,l_trx_due_date,l_trx_term_name,l_trx_term_desc,l_trx_type
    from ar_payment_schedules_all aps,ra_terms t
    where aps.trx_number = l_trx_number
    and   aps.customer_id = p_customer_id
    and   aps.term_id  = t.term_id(+);

      IF (PG_DEBUG = 'Y') THEN
        arp_standard.debug(G_PKG_NAME || l_procedure_name || 'l_trx_number ::'|| l_trx_number );
        arp_standard.debug(G_PKG_NAME || l_procedure_name || 'l_trx_amt_due ::'|| l_trx_amt_due );
        arp_standard.debug(G_PKG_NAME || l_procedure_name || 'l_trx_curr_code ::'||l_trx_curr_code );
        arp_standard.debug(G_PKG_NAME || l_procedure_name || 'l_trx_due_date ::'||l_trx_due_date );
        arp_standard.debug(G_PKG_NAME || l_procedure_name || 'l_trx_term_name ::'||l_trx_term_name );
        arp_standard.debug(G_PKG_NAME || l_procedure_name || 'l_trx_term_desc ::'||l_trx_term_desc );
        arp_standard.debug(G_PKG_NAME || l_procedure_name || 'l_trx_type ::'||l_trx_type );
    END IF;

    ------------------------------------------------------------------------------------------
    l_debug_info := 'check if wether  to send invoice notification or credit memo notification';
    -------------------------------------------------------------------------------------------

    if ( l_trx_type = 'INV')  then
        l_result_code := 'INVOICE';
    elsif ( l_trx_type = 'CM')  then
        l_result_code := 'CREDIT_MEMO';
    else
        l_result_code := 'OTHER';
    end if;

    IF (PG_DEBUG = 'Y') THEN
        arp_standard.debug(G_PKG_NAME || l_procedure_name || 'l_result_code ::'||l_result_code );
    END IF;

    --------------------------------------------------------------------------
    l_debug_info := 'fetching all contacts emails adhoc users list to send notification ';
    ---------------------------------------------------------------------------

   l_users_list := get_contact_emails_adhoc_list(p_customer_id,p_customer_acct_site_id);

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || 'l_users_list ::' || l_users_list );
    END IF;

   ------------------------------------------------------------------------------------------
    l_debug_info := 'check if emails exits , if yes creating adhoc user , if no invoice complete ';
    -------------------------------------------------------------------------------------------

   if ( l_users_list is null )  then
      rslt := 'COMPLETE:' || 'OTHER';
   else

    l_adhoc_user_name := l_role_prefix || l_customer_trx_id;
    l_adhoc_user_display_name := l_adhoc_user_name;

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || 'adhoc username :: ' || l_adhoc_user_name );
      arp_standard.debug(G_PKG_NAME || l_procedure_name || 'adhoc display name :: ' || l_adhoc_user_display_name);
    END IF;

  -------------------------------------------------------
    l_debug_info := 'if no role exits ,creating a new role';
    --------------------------------------------------------
    WF_DIRECTORY.CreateAdHocRole(role_name                => l_adhoc_user_name,
                                 role_display_name        => l_adhoc_user_display_name,
                                 notification_preference  => 'MAILHTM2');

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name  || l_adhoc_user_name || 'Created Role ' );
     END IF;

    wf_directory.AddUsersToAdhocRole(role_name => l_adhoc_user_name,
                                                 role_users => l_users_list);

   end if;

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || 'Assigned Users  To The Role' || l_adhoc_user_name );
    END IF;

    --------------------------------------------------------------
    l_debug_info := 'Set AR_NOTIFY_ROLES Item Attribute';
    --------------------------------------------------------------

    WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_NOTIFY_ROLES',
                              l_adhoc_user_name);

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || ' Attribute ARI_NOTIFY_ROLES set to :: ' ||l_adhoc_user_name);
    END IF;
    --------------------------------------------------------------
    l_debug_info := 'Set ARI_TRX_NUM Item Attribute';
    --------------------------------------------------------------

    WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_TRX_NUMBER',
                              l_trx_number);

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || ' Attribute ARI_TRX_NUMBER set to :: ' ||l_trx_number);
    END IF;

    --------------------------------------------------------------
    l_debug_info := 'Set ARI_TRX_AMT_DUE Item Attribute';
    --------------------------------------------------------------

    WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_TRX_AMT_DUE',
                              l_trx_amt_due);

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || ' Attribute ARI_TRX_AMT_DUE set to :: ' ||l_trx_amt_due);
    END IF;

    --------------------------------------------------------------
    l_debug_info := 'Set ARI_INV_CUR_CODE Item Attribute';
    --------------------------------------------------------------

    WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_TRX_CUR_CODE',
                              l_trx_curr_code);

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || ' Attribute ARI_TRX_CUR_CODE set to :: ' ||l_trx_curr_code);
    END IF;

    --------------------------------------------------------------
    l_debug_info := 'Set ARI_TRX_DUE_DATE Item Attribute';
    --------------------------------------------------------------

    WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_TRX_DUE_DATE',
                              l_trx_due_date);

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || ' Attribute ARI_TRX_DUE_DATE set to :: ' ||l_trx_due_date);
    END IF;

    --------------------------------------------------------------
    l_debug_info := 'Set ARI_TRX_PAY_TERM Item Attribute';
    --------------------------------------------------------------

    WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_TRX_PAY_TERM',
                              l_trx_term_name);

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || ' Attribute ARI_TRX_PAY_TERM set to :: ' ||l_trx_term_name);
    END IF;

    --------------------------------------------------------------
    l_debug_info := 'Set ARI_TRX_PAY_TERM_DESC Item Attribute';
    --------------------------------------------------------------

    WF_ENGINE.SetItemAttrText(l_itemtype,
                              l_customer_trx_id,
                              'ARI_TRX_PAY_TERM_DESC',
                              l_trx_term_desc);

    IF (PG_DEBUG = 'Y') THEN
      arp_standard.debug(G_PKG_NAME || l_procedure_name || ' Attribute ARI_TRX_PAY_TERM_DESC set to :: ' || l_trx_term_desc);
    END IF;

       rslt := 'COMPLETE:' || l_result_code;

EXCEPTION
WHEN OTHERS THEN
  rslt := 'COMPLETE:' || 'N';
  wf_core.context('ARI_UTILITIES','DET_IF_SEND_EMAIL',l_itemtype,
                   l_itemkey,to_char(actid),funcmode);
   IF (PG_DEBUG = 'Y') THEN
              arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
              arp_standard.debug('ERROR =>'|| SQLERRM);
              arp_standard.debug('Debug Info : '||l_debug_info);
   END IF;
  raise;

end det_if_send_email;

PROCEDURE cancel_dispute(p_dispute_id      IN NUMBER,
			 p_cancel_comments IN VARCHAR2,
                         p_return_status   OUT NOCOPY VARCHAR2
) IS

CURSOR c_item_type(l_item_key NUMBER) IS
SELECT item_type
FROM wf_items
WHERE item_key = l_item_key
 AND item_type IN('ARCMREQ','ARAMECM');


CURSOR ps_cur(p_customer_trx_id NUMBER) IS
SELECT payment_schedule_id,
  due_date,
  amount_in_dispute,
  dispute_date
FROM ar_payment_schedules ps
WHERE ps.customer_trx_id = p_customer_trx_id;

cursor get_partyid(p_cust_acct_id number) is
	select party_id
	from hz_cust_accounts
	where cust_account_id = p_cust_acct_id;

Cursor  Get_billto(p_cust_trx_id number) Is
            select bill_to_site_use_id
              from ra_customer_trx
              where customer_trx_id = p_cust_trx_id;

Cursor Get_paymentid(p_cust_trx_id number) Is
           select customer_id,payment_schedule_id
             from ar_payment_schedules
             where customer_trx_id = p_cust_trx_id;

l_item_type	                VARCHAR2(100);
l_customer_trx_id	        NUMBER;
l_status			VARCHAR2(8);
l_result			VARCHAR2(100);
l_last_updated_by		NUMBER;
l_last_update_login		NUMBER;
l_last_update_date		DATE;
l_creation_date			DATE;
l_created_by			NUMBER;
l_document_id			NUMBER;
l_note_id			NUMBER;
l_note_text			ar_notes.text%TYPE;
l_notes				wf_item_attribute_values.text_value%TYPE;
l_cust_account_id		NUMBER;
l_payment_schedule_id		NUMBER;
l_party_id  		        NUMBER;
l_customer_site_use_id		number;
new_dispute_date		DATE;
new_dispute_amt			NUMBER;
remove_from_dispute_amt		NUMBER;
i                               NUMBER;
l_default_note_type		varchar2(240) := FND_PROFILE.VALUE('AST_NOTES_DEFAULT_TYPE');
l_jtf_note_contexts_table       jtf_notes_pub.jtf_note_contexts_tbl_type;
l_context_tab			CONTEXTS_TBL_TYPE;
l_return_status             	VARCHAR2(1);
l_msg_count                 	NUMBER;
l_msg_data                  	VARCHAR2(32767);
l_procedure_name                VARCHAR2(50);
l_debug_info                    VARCHAR2(200);
-- Added below lines for Bug 19057880
l_new_comments VARCHAR2(50);
l_end_position NUMBER;

BEGIN

  l_procedure_name := '.cancel_dispute';
  l_debug_info := 'Cancel Credit Memo Request';

  SAVEPOINT CANCEL_DISPUTE;

  p_return_status := FND_API.G_RET_STS_SUCCESS;
  OPEN c_item_type(p_dispute_id);
     FETCH c_item_type   INTO l_item_type;
  CLOSE c_item_type;

  IF l_item_type IS NOT NULL THEN
    l_customer_trx_id := wf_engine.getitemattrnumber(l_item_type,   p_dispute_id,   'CUSTOMER_TRX_ID');
  END IF;

    SELECT total_amount * -1
     INTO remove_from_dispute_amt
     FROM ra_cm_requests
     WHERE request_id = p_dispute_id;

      FOR ps_rec IN ps_cur(l_customer_trx_id)
       LOOP
          new_dispute_amt := ps_rec.amount_in_dispute -remove_from_dispute_amt;

          IF new_dispute_amt = 0 THEN
            new_dispute_date := NULL;
          ELSE
            new_dispute_date := ps_rec.dispute_date;
          END IF;

            arp_process_cutil.update_ps(p_ps_id			=> ps_rec.payment_schedule_id,
					p_due_date		=> ps_rec.due_date,
					p_amount_in_dispute	=> new_dispute_amt,
					p_dispute_date		=> new_dispute_date,
					p_update_dff		=> 'N',
					p_attribute_category	=> NULL,
					p_attribute1		=> NULL,
					p_attribute2		=> NULL,
					p_attribute3		=> NULL,
					p_attribute4		=> NULL,
					p_attribute5		=> NULL,
					p_attribute6		=> NULL,
					p_attribute7		=> NULL,
					p_attribute8		=> NULL,
					p_attribute9		=> NULL,
					p_attribute10		=> NULL,
					p_attribute11		=> NULL,
					p_attribute12		=> NULL,
					p_attribute13		=> NULL,
					p_attribute14		=> NULL,
					p_attribute15		=> NULL);

      END LOOP;
      -- Added for Bug 19057880 : Start
       l_last_updated_by   := nvl(FND_GLOBAL.user_id,-1);
       l_last_update_login := nvl(FND_GLOBAL.conc_login_id,FND_GLOBAL.login_id);
       l_last_update_date  := sysdate;
       l_new_comments      := ':Cancel#:-'||p_cancel_comments;
       l_end_position      := 1760 - length(l_new_comments);
       IF (PG_DEBUG = 'Y') THEN
        arp_standard.debug('Inside cancel dispute procedure ');
        arp_standard.debug('p_cancel_comments >> '||p_cancel_comments);
        arp_standard.debug('p_dispute_id >> '||p_dispute_id);
        arp_standard.debug('l_last_updated_by >> '||l_last_updated_by);
        arp_standard.debug('l_last_update_date >> '||l_last_update_date);
        arp_standard.debug('l_last_update_login >> '||l_last_update_login);
        arp_standard.debug('l_new_comments >> '||l_new_comments);
        arp_standard.debug('Length of l_new_comments >> '||length(l_new_comments));
        arp_standard.debug('l_end_position >> '||l_end_position);
      END IF;
      UPDATE RA_CM_REQUESTS_ALL
	    SET INTERNAL_COMMENT = SUBSTR(INTERNAL_COMMENT,1,l_end_position) || l_new_comments,
	    LAST_UPDATED_BY   = l_last_updated_by,
	    LAST_UPDATE_DATE  = l_last_update_date,
	    LAST_UPDATE_LOGIN = l_last_update_login
	    WHERE REQUEST_ID  = p_dispute_id;
       -- Added for Bug 19057880 : End

    wf_engine.SetItemAttrText(l_item_type, p_dispute_id, 'NOTES', p_cancel_comments);
    wf_engine.itemstatus(itemtype => l_item_type,   itemkey => p_dispute_id,   status => l_status,   result => l_result);

    IF l_status <> wf_engine.eng_completed THEN
        wf_engine.abortprocess(itemtype => l_item_type,   itemkey => p_dispute_id);
        wf_engine.itemstatus(itemtype => l_item_type,   itemkey => p_dispute_id,   status => l_status,   result => l_result);
    END IF;

   l_last_updated_by := arp_global.user_id;
   l_last_update_login := arp_global.last_update_login;
   l_document_id := wf_engine.getitemattrnumber(l_item_type,   p_dispute_id,   'WORKFLOW_DOCUMENT_ID');
   l_customer_trx_id := wf_engine.getitemattrnumber(l_item_type,   p_dispute_id,   'CUSTOMER_TRX_ID');


   if l_customer_trx_id is null then
		SELECT customer_trx_id
		  INTO l_customer_trx_id
		  FROM ra_cm_requests
		  WHERE request_id = l_document_id;
   end if;

   l_notes := wf_engine.getitemattrtext(l_item_type,   p_dispute_id,   'NOTES');
   fnd_message.set_name('AR',   'AR_WF_REJECTED_RESPONSE');
   fnd_message.set_token('REQUEST_ID',   to_char(p_dispute_id));
   fnd_message.set_token('APPROVER',   fnd_global.user_id);
   l_note_text := fnd_message.GET;

   IF l_notes IS NOT NULL THEN
     l_note_text := substrb(l_note_text || ' "' || l_notes || '"',   1,   2000);
   END IF;

  arp_notes_pkg.insert_cover(
		p_note_type              => 'MAINTAIN',
		p_text                   => l_note_text,
		p_customer_call_id       => null,
		p_customer_call_topic_id => null,
		p_call_action_id         => NULL,
		p_customer_trx_id        => l_customer_trx_id,
		p_note_id                => l_note_id,
		p_last_updated_by        => l_last_updated_by,
		p_last_update_date       => l_last_update_date,
		p_last_update_login      => l_last_update_login,
		p_created_by             => l_created_by,
		p_creation_date          => l_creation_date);

EXCEPTION
 WHEN OTHERS THEN
    IF (PG_DEBUG = 'Y') THEN
	arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
	arp_standard.debug('ERROR =>'|| SQLERRM);
	arp_standard.debug('Debug Info : '||l_debug_info);
    END IF;
 ROLLBACK TO CANCEL_DISPUTE;
 p_return_status := FND_API.G_RET_STS_ERROR;
END cancel_dispute;

-- Added for Bug 16970987 - shvimal
PROCEDURE receivables_dispute
(p_trx_number IN VARCHAR2,
 p_customer_trx_id	IN NUMBER,
 p_payment_schedule_id	IN NUMBER,
 p_dispute_amount	IN NUMBER,
 p_reason_code		IN VARCHAR2,
 p_dispute_date		IN DATE,
 p_dispute_comment	IN VARCHAR2,
 p_return_status	OUT NOCOPY VARCHAR2
) IS
l_last_updated_by	NUMBER;
l_last_update_date	DATE;
l_last_update_login	NUMBER;
l_procedure_name	VARCHAR2(50);
l_debug_info		VARCHAR2(200);

BEGIN

	l_procedure_name	:= '.receivables_dispute';
	l_debug_info		:= 'Receivables Dispute';
	p_return_status		:= FND_API.G_RET_STS_SUCCESS;

	IF (PG_DEBUG = 'Y') THEN
		arp_standard.debug('Input parameter values ...');
		arp_standard.debug('p_trx_number :' || p_trx_number);
		arp_standard.debug('p_customer_trx_id :' || p_customer_trx_id);
		arp_standard.debug('p_payment_schedule_id :' || p_payment_schedule_id);
		arp_standard.debug('p_dispute_amount :' || p_dispute_amount);
		arp_standard.debug('p_reason_code :' || p_reason_code);
		arp_standard.debug('p_dispute_date :' || p_dispute_date);
		arp_standard.debug('p_dispute_comment :' || p_dispute_comment);
	END IF;

	SAVEPOINT CREDIT_MEMO_DISPUTE;

	l_last_updated_by := arp_global.user_id;
	l_last_update_login := arp_global.last_update_login;
	l_last_update_date := arp_global.last_update_date;

	IF (PG_DEBUG = 'Y') THEN
		arp_standard.debug('Update table RA_CUSTOMER_TRX with reason code and comments');
	END IF;

	UPDATE RA_CUSTOMER_TRX
	SET REASON_CODE = p_reason_code,
    COMMENTS = p_dispute_comment,
	  LAST_UPDATED_BY = l_last_updated_by,
	  LAST_UPDATE_DATE = l_last_update_date,
	  LAST_UPDATE_LOGIN = l_last_update_login
	WHERE CUSTOMER_TRX_ID = p_customer_trx_id;

	IF (PG_DEBUG = 'Y') THEN
		arp_standard.debug('Table RA_CUSTOMER_TRX has been updated successfully');
		arp_standard.debug('Update table AR_PAYMENT_SCHEDULES with dispute amount and date');
	END IF;

	UPDATE AR_PAYMENT_SCHEDULES
	SET AMOUNT_IN_DISPUTE = p_dispute_amount,
	  DISPUTE_DATE = p_dispute_date,
	  LAST_UPDATED_BY = l_last_updated_by,
	  LAST_UPDATE_DATE = l_last_update_date,
	  LAST_UPDATE_LOGIN = l_last_update_login
	WHERE PAYMENT_SCHEDULE_ID = p_payment_schedule_id;

	IF (PG_DEBUG = 'Y') THEN
		arp_standard.debug('Table AR_PAYMENT_SCHEDULES has been updated successfully');
	END IF;

	EXCEPTION
	WHEN OTHERS THEN
		IF (PG_DEBUG = 'Y') THEN
			arp_standard.debug('Unexpected Exception in ' || G_PKG_NAME || l_procedure_name);
			arp_standard.debug('ERROR =>'|| SQLERRM);
			arp_standard.debug('Debug Info : '||l_debug_info);
		END IF;
		ROLLBACK TO CREDIT_MEMO_DISPUTE;
		p_return_status := FND_API.G_RET_STS_ERROR;

END receivables_dispute;

/*===========================================================================+
| PROCEDURE get_link_filter                                              |
 |                                                                           |
 | DESCRIPTION                                                               |
 |  This proc returns if the link for a particular transaction in activities needs  |
 |  to be displayed or not.                                                                         |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                                                                           |
 | RETURNS    : OUT:                                                         |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     17-Apr-2012   parln      Created                                    |
 |                                                                           |
 +===========================================================================*/

FUNCTION get_link_filter(p_txn_no IN  VARCHAR2,
p_txn_type IN  VARCHAR2,
p_cust_trx_id IN NUMBER,
p_payment_schedule_id IN NUMBER)
 RETURN VARCHAR2 IS
  l_txn_difference NUMBER;
  l_profile_limit_days NUMBER;
  l_print_flag VARCHAR2(100);
  l_print_profile VARCHAR2(100);
	l_cust_trx_id NUMBER;
  p_result  VARCHAR(2);
  BEGIN
p_result := 'N';
if(p_cust_trx_id is null) then
	select customer_trx_id into l_cust_trx_id
	 from ar_payment_schedules_all
	 where payment_schedule_id = p_payment_schedule_id
	 and trx_number = p_txn_no;
else
	l_cust_trx_id := p_cust_trx_id;
end if;
if(p_txn_type<>'PMT') THEN
  Select (sysdate - ps.TRX_DATE), ra.Printing_option into l_txn_difference, l_print_flag
  from ar_payment_schedules_all ps, ra_customer_trx_all ra
  where ps.CUSTOMER_TRX_ID= ra.CUSTOMER_TRX_ID
  and ps.trx_number=p_txn_no
  and ps.CUSTOMER_TRX_ID = l_cust_trx_id;
else
	Select (sysdate - TRX_DATE) into l_txn_difference from ar_payment_schedules_all
	where trx_number=p_txn_no
	and PAYMENT_SCHEDULE_ID = p_payment_schedule_id;
end if;
IF (PG_DEBUG = 'Y') THEN
  	arp_standard.debug('In get_link_filter p_txn_no:'||p_txn_no||'p_txn_type:'||
	p_txn_type||'p_cust_trx_id:'||to_char(p_cust_trx_id)||
	'p_payment_schedule_id:'||to_char(p_payment_schedule_id));
END IF;
l_profile_limit_days := FND_PROFILE.VALUE('ARI_FILTER_TRXDATE_OLDER');
l_print_profile  := FND_PROFILE.VALUE('ARI_FILTER_DONOTPRINT_TRX');


IF (PG_DEBUG = 'Y') THEN
  	arp_standard.debug('In get_link_filter l_print_flag:'||
	l_print_flag||'l_print_profile: '||l_print_profile);
END IF;
if(l_profile_limit_days is not null and l_txn_difference > l_profile_limit_days ) THEN
     p_result:= 'Y';
END IF;
if(l_print_profile='Y' AND l_print_flag='NOT') THEN
     p_result:=  'Y';
END IF;
return p_result;
EXCEPTION
 WHEN OTHERS THEN
 p_result:=  'N';
    IF (PG_DEBUG = 'Y') THEN
  	arp_standard.debug('Unexpected Exception in get_link_filter'||SQLERRM);
    END IF;
return p_result;
END get_link_filter;


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
 | 10-May-2012           parln            Bug 13848644 - FP:13455876:13117430: ACCOUNT SUMMARY PERF ISSUES
 | 14-Feb-2013           melapaku         Bug 16168496 - UNABLE TO SEARCH A CUSTOMER ON ALL LOCATIONS IN BILL MANAGEMENT,
 |                                                       IRECEIVABLES
 *=======================================================================*/

FUNCTION get_pending_cmreq_amount(p_customer_id IN NUMBER,
                                    p_customer_site_use_id IN NUMBER,
                                    p_session_id IN NUMBER,
                                    p_currency_code IN VARCHAR2) RETURN NUMBER AS

pending_cmreq_amt NUMBER := 0;
l_procedure_name VARCHAR2(30);
BEGIN

l_procedure_name         := '.get_pending_cmreq_amount';

if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Begin+');
end if;

if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'p_customer_id '||p_customer_id);
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'p_customer_site_use_id '||p_customer_site_use_id);
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'p_session_id '||p_session_id);
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'p_currency_code '||p_currency_code);
end if;

if(p_customer_id IS NULL OR p_customer_id = -1) then
 SELECT /*+ LEADING(RaCmRequests)*/ nvl(sum ( total_amount ), 0) into pending_cmreq_amt
   FROM RA_CM_REQUESTS RaCmRequests, AR_PAYMENT_SCHEDULES ArPaymentSchedules,  ar_irec_user_acct_sites_all AcctSites, ra_customer_trx ct
   WHERE (RaCmRequests.CUSTOMER_TRX_ID = ArPaymentSchedules.CUSTOMER_TRX_ID) AND
   nvl(ArPaymentSchedules.terms_sequence_number,1) = 1
   AND AcctSites.user_id=FND_GLOBAL.USER_ID()
   AND ArPaymentSchedules.customer_id = AcctSites.customer_id
   AND AcctSites.customer_site_use_id=ArPaymentSchedules.customer_site_use_id
   AND AcctSites.session_id=p_session_id
   AND ( ArPaymentSchedules.class = 'INV' OR ArPaymentSchedules.class = 'GUAR' OR ArPaymentSchedules.class = 'CB' OR
    ArPaymentSchedules.class = 'DM' OR ArPaymentSchedules.class = 'DEP' )
    AND( ArPaymentSchedules.invoice_currency_code = p_currency_code ) AND
   (RaCmRequests.status IN ('PENDING_APPROVAL','APPROVED_PEND_COMP'))
   AND ArPaymentSchedules.customer_trx_id = ct.customer_trx_id
   AND(TRUNC(ArPaymentSchedules.trx_date)) >= trunc(decode( nvl(FND_PROFILE.VALUE('ARI_FILTER_TRXDATE_OLDER'), 0), 0, ArPaymentSchedules.trx_date, (sysdate-FND_PROFILE.VALUE('ARI_FILTER_TRXDATE_OLDER'))))
   AND ct.printing_option =  decode(nvl(FND_PROFILE.VALUE('ARI_FILTER_DONOTPRINT_TRX'), 'NOT'), 'Y', 'PRI', ct.printing_option) ;
else
 SELECT /*+ index(ARPAYMENTSCHEDULES AR_PAYMENT_SCHEDULES_N2) LEADING(RaCmRequests)*/ nvl(sum ( total_amount ), 0) into pending_cmreq_amt
   FROM RA_CM_REQUESTS RaCmRequests, AR_PAYMENT_SCHEDULES ArPaymentSchedules,  ar_irec_user_acct_sites_all AcctSites, ra_customer_trx ct
   WHERE (RaCmRequests.CUSTOMER_TRX_ID = ArPaymentSchedules.CUSTOMER_TRX_ID) AND
   nvl(ArPaymentSchedules.terms_sequence_number,1) = 1
   AND AcctSites.user_id=FND_GLOBAL.USER_ID()
   AND ArPaymentSchedules.customer_id=p_customer_id
   AND  ArPaymentSchedules.customer_id= AcctSites.customer_id
   AND AcctSites.customer_site_use_id=ArPaymentSchedules.customer_site_use_id
   AND AcctSites.session_id=p_session_id
   AND ( ArPaymentSchedules.class = 'INV' OR ArPaymentSchedules.class = 'GUAR' OR ArPaymentSchedules.class = 'CB' OR
    ArPaymentSchedules.class = 'DM' OR ArPaymentSchedules.class = 'DEP' )
    AND( ArPaymentSchedules.invoice_currency_code = p_currency_code ) AND
   (RaCmRequests.status IN ('PENDING_APPROVAL','APPROVED_PEND_COMP'))
   AND ArPaymentSchedules.customer_trx_id = ct.customer_trx_id
   AND(TRUNC(ArPaymentSchedules.trx_date)) >= trunc(decode( nvl(FND_PROFILE.VALUE('ARI_FILTER_TRXDATE_OLDER'), 0), 0, ArPaymentSchedules.trx_date, (sysdate-FND_PROFILE.VALUE('ARI_FILTER_TRXDATE_OLDER'))))
   AND ct.printing_option =  decode(nvl(FND_PROFILE.VALUE('ARI_FILTER_DONOTPRINT_TRX'), 'NOT'), 'Y', 'PRI', ct.printing_option) ;
end if;

if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'pending_cmreq_amt '||pending_cmreq_amt);
end if;

if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'End-');
end if;
  RETURN pending_cmreq_amt;
EXCEPTION
	WHEN OTHERS THEN
		pending_cmreq_amt := 0;
	  return pending_cmreq_amt;
END get_pending_cmreq_amount;

END ari_utilities;
/

commit;
EXIT ;
