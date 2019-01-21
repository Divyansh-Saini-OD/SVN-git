/*============================================================================+
 $Header: ARIUTILB.pls 115.19 2008/03/17 13:44:30 rsinthre noship $
 |  Copyright (c) 1996 Oracle Corporation Belmont, California, USA            |
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
 |  	rsinthre	17 Jan 05	Bug 3800333 - iRec Invoice details    |
 |					type/status cols not fully translated |
 |					in Canadian French language	      |
 |  	rsinthre	08 Sep 05   	Bug 4595876 iRec Customer search also |
 |					displays inactive contacts	      |
 |	avepati		19 Jan 08	Bug 6753167 Commeneted out the check  |
 |				         status='A' on hz_cust_site_uses table| 
 |					 to allow drill down                  |
 |					 from Inactive Bill-To Sites          |
 +===========================================================================*/

REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE


REM SET ESCAPE `
SET VERIFY OFF;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
 
CREATE OR REPLACE PACKAGE BODY ARI_UTILITIES AS
/* $Header: ARIUTILB.pls 115.19 2008/03/17 13:44:30 rsinthre noship $ */

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
BEGIN

/* For fixing Bug 4101466 - Hyperlink not working for an external user assgined with same location
*/

SELECT 'Y' 
INTO user_access 
FROM dual 
WHERE p_customer_id IN (SELECT cust_account_id 
	    FROM ar_customers_assigned_v 
	    WHERE party_id = p_person_party_id ) 
OR exists (SELECT 'Y' 
		  FROM ar_sites_assigned_v a,HZ_CUST_SITE_USES b 
		  where a.cust_acct_site_id = b.cust_acct_site_id 
		  and b.SITE_USE_CODE = 'BILL_TO' 
		  AND party_id = p_person_party_id and site_use_id = p_customer_site_use_id
		  UNION 
		  SELECT 'Y'
		  FROM ar_customers_assigned_v Custs_assigned, 
hz_cust_acct_sites Site,HZ_CUST_SITE_USES site_uses 
		  WHERE Custs_assigned.party_id = p_person_party_id 
		  AND  Site.cust_account_id = 
Custs_assigned.cust_account_id 
		  and Site.cust_acct_site_id = 
site_uses.cust_acct_site_id 
		  and site_uses.SITE_USE_CODE = 'BILL_TO' and site_uses.SITE_USE_ID = p_customer_site_use_id );

IF user_access is not null
then
 return 'Y' ;
end if ;

return 'N';

EXCEPTION WHEN OTHERS THEN
 return 'N' ;


END;

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
      AND  lookup_code = p_lookup_code ;
      
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
--AND status    = 'A'  

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
 | 24-AUG-2005           rsinthre	   Created
 | 08-SEP-2005 		 rsinthre	   Bug 4595876 iRec Customer search also displays inactive contacts
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
 | 24-AUG-2005           rsinthre	   Created
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
 | 24-AUG-2005           rsinthre	   Created
 | 08-SEP-2005 		 rsinthre	   Bug 4595876 iRec Customer search also displays inactive contacts
 *=======================================================================*/
FUNCTION get_phone(p_customer_id IN NUMBER,
                   p_customer_site_use_id IN NUMBER DEFAULT  NULL,
		   p_contact_role_type IN VARCHAR2 DEFAULT  'ALL',
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
 *=======================================================================*/
FUNCTION get_default_currency (	p_customer_id      IN VARCHAR2,
				                p_session_id IN VARCHAR2)
RETURN VARCHAR2
IS
	l_default_currency	VARCHAR2(15);
	l_default_org_id	NUMBER(15,0);
BEGIN
      IF(p_customer_id IS NULL) THEN 
		SELECT unique ( CUR.CURRENCY_CODE )
			INTO   l_default_currency
			FROM   HZ_CUST_PROFILE_AMTS CPA,
		       FND_CURRENCIES_VL CUR,
		       HZ_CUSTOMER_PROFILES CPF,
                       ar_irec_user_acct_sites_all AUAS
      	WHERE
        	 CPA.CURRENCY_CODE = CUR.CURRENCY_CODE AND
         	 CPF.CUST_ACCOUNT_PROFILE_ID = CPA.CUST_ACCOUNT_PROFILE_ID AND     
         	 CPF.CUST_ACCOUNT_ID = AUAS.CUSTOMER_ID AND
         	(   
		 CPF.SITE_USE_ID = AUAS.CUSTOMER_SITE_USE_ID
		 OR    
		 CPF.SITE_USE_ID IS NULL 
         	)
		AND AUAS.user_id=FND_GLOBAL.USER_ID()
		AND AUAS.session_id=p_session_id
		AND    ROWNUM = 1;
	ELSE
		SELECT unique ( CUR.CURRENCY_CODE )
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
  l_procedure_name := '.get_site_uses';
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
 | 18-Jan-2008		 avepati		Modified For Bug 6753167
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
--AND status    = 'A' 
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
				 select arw_db_functions.get_bill_to_site_use_id(CUST_ACCT_SITE_ID) from ar_sites_assigned_v where 
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

END ari_utilities;
/

commit;
EXIT ;