create or replace PACKAGE BODY ARW_SEARCH_CUSTOMERS AS
/*$Header: ARWCUSRB.pls 120.21.12020000.7 2015/01/23 14:31:57 gnramasa ship $*/
--
/*=======================================================================+
 |  Package Global Constants
 +=======================================================================*/
G_PKG_NAME      CONSTANT VARCHAR2(30)    := 'ARW_SEARCH_CUSTOMERS';

-- bugfix 2235673 - setting query limit to 200
  MAX_BUFFERED_ROWS BINARY_INTEGER := NVL(FND_PROFILE.value('VO_MAX_FETCH_SIZE'), 200);
  --MAX_BUFFERED_ROWS BINARY_INTEGER := 25;
--
--  Cursor to get all site records for given customer
--
CURSOR cust_cur (p_customer_id VARCHAR2, p_show_all_sites VARCHAR2) IS


SELECT * FROM (SELECT cust.cust_account_id CUSTOMER_ID,
  'CUST' DETAILS_LEVEL,
  cust.ACCOUNT_NUMBER CUSTOMER_NUMBER,
  SUBSTRB(cust.ACCOUNT_NAME,1,50) CUSTOMER_NAME,
  -1 address_id,
  'ALL_LOCATIONS' concatenated_address,
  TO_CHAR(NULL) contact_name,
  TO_CHAR(NULL) contact_phone,
  -1 BILL_TO_SITE_USE_ID,
  TO_CHAR(NULL) site_uses,
  -1 org_id,
  'N' selected,
   TO_CHAR(NULL) location
FROM hz_cust_accounts cust
WHERE cust.cust_account_id = to_number(p_customer_id) -- Added for Bug 18239163

UNION ALL

SELECT HCA.CUST_ACCOUNT_ID CUSTOMER_ID ,
  'ADDR' DETAILS_LEVEL,
  HCA.ACCOUNT_NUMBER CUSTOMER_NUMBER,
  SUBSTRB(HCA.ACCOUNT_NAME,1,50) CUSTOMER_NAME,
  ACCT_SITE.CUST_ACCT_SITE_ID ADDRESS_ID,
  ARP_ADDR_PKG.FORMAT_ADDRESS(LOC.ADDRESS_STYLE,LOC.ADDRESS1, LOC.ADDRESS2,LOC.ADDRESS3,LOC.ADDRESS4,LOC.CITY,LOC.COUNTY, LOC.STATE,LOC.PROVINCE,LOC.POSTAL_CODE, LOC.COUNTRY ) CONCATENATED_ADDRESS,
  TO_CHAR(NULL) CONTACT_NAME,
  TO_CHAR(NULL) CONTACT_PHONE,
  -1 BILL_TO_SITE_USE_ID,
  ari_utilities.get_site_uses(ACCT_SITE.CUST_ACCT_SITE_ID) SITE_USES,
  ACCT_SITE.org_id,
  'N' selected,
  ari_utilities.get_site_use_location(ACCT_SITE.CUST_ACCT_SITE_ID) location
FROM HZ_CUST_ACCT_SITES ACCT_SITE ,
  HZ_PARTY_SITES PARTY_SITE ,
  HZ_LOCATIONS LOC ,
  HZ_CUST_ACCOUNTS HCA
WHERE ACCT_SITE.PARTY_SITE_ID   = PARTY_SITE.PARTY_SITE_ID
  AND LOC.LOCATION_ID             = PARTY_SITE.LOCATION_ID
  AND PARTY_SITE.PARTY_ID		= HCA.PARTY_ID
  AND HCA.CUST_ACCOUNT_ID		= ACCT_SITE.CUST_ACCOUNT_ID
  AND nvl(acct_site.bill_to_flag, 'N') in (decode(p_show_all_sites,'N','P',nvl(acct_site.bill_to_flag,'N')),decode(p_show_all_sites,'N','Y',nvl(acct_site.bill_to_flag,'N')))
  AND ACCT_SITE.CUST_ACCOUNT_ID = to_number(p_customer_id)) -- Added for Bug 18239163
ORDER BY 2 DESC, 5;

/* <Temporary fix for bug number 2235656> */
CURSOR cust_cur_trx (p_search_criteria VARCHAR2) IS
  SELECT DISTINCT
       cus.cust_account_id customer_id,
       'CUST' DETAILS_LEVEL,
       cus.ACCOUNT_NUMBER customer_number,
       substrb(party.party_name, 1, 50) CUSTOMER_NAME,
       -1 address_id,
       'ALL_LOCATIONS' CONCATENATED_ADDRESS,
       ari_utilities.get_contact(cus.cust_account_id, null, 'ALL') CONTACT_NAME,
       ari_utilities.get_phone(cus.cust_account_id, null, 'ALL','GEN') CONTACT_PHONE,
       -1 BILL_TO_SITE_USE_ID,
       NULL SITE_USES,
       cus.org_id,
       'N' selected,
       '' location
  FROM
       hz_cust_accounts cus,
       hz_parties party,
       ra_customer_trx ct
  WHERE
       ct.trx_number = p_search_criteria
   and ct.bill_to_customer_id = cus.cust_account_id
   and party.party_id = cus.party_id;

CURSOR cust_cur_by_name (p_customer_name_number VARCHAR2, p_show_all_sites VARCHAR2) IS
SELECT * FROM
(SELECT cust.cust_account_id CUSTOMER_ID,
  'CUST' DETAILS_LEVEL,
  cust.ACCOUNT_NUMBER CUSTOMER_NUMBER,
  SUBSTRB(party.PARTY_NAME,1,50) CUSTOMER_NAME,
  -1 address_id,
  'ALL_LOCATIONS' concatenated_address,
  TO_CHAR(NULL) contact_name,
  TO_CHAR(NULL) contact_phone,
  -1 BILL_TO_SITE_USE_ID,
  TO_CHAR(NULL) site_uses,
  -1 org_id,
  'N' selected,
  TO_CHAR(NULL) location
FROM hz_cust_accounts cust,
  hz_parties party
WHERE cust.party_id = party.party_id AND
      cust.ACCOUNT_NUMBER LIKE p_customer_name_number

UNION ALL

SELECT HCA.CUST_ACCOUNT_ID CUSTOMER_ID ,
  'ADDR' DETAILS_LEVEL,
  HCA.ACCOUNT_NUMBER CUSTOMER_NUMBER,
  SUBSTRB(HP.PARTY_NAME,1,50) CUSTOMER_NAME,
  ACCT_SITE.CUST_ACCT_SITE_ID ADDRESS_ID,
  ARP_ADDR_PKG.FORMAT_ADDRESS(LOC.ADDRESS_STYLE,LOC.ADDRESS1, LOC.ADDRESS2,LOC.ADDRESS3,LOC.ADDRESS4,LOC.CITY,LOC.COUNTY, LOC.STATE,LOC.PROVINCE,LOC.POSTAL_CODE, T.TERRITORY_SHORT_NAME ) CONCATENATED_ADDRESS,
  TO_CHAR(NULL) CONTACT_NAME,
  TO_CHAR(NULL) CONTACT_PHONE,
  -1 BILL_TO_SITE_USE_ID,
  ari_utilities.get_site_uses(ACCT_SITE.CUST_ACCT_SITE_ID) SITE_USES,
  ACCT_SITE.org_id,
  'N' selected,
  ari_utilities.get_site_use_location(ACCT_SITE.CUST_ACCT_SITE_ID) location
FROM HZ_CUST_ACCT_SITES ACCT_SITE ,
  HZ_PARTY_SITES PARTY_SITE ,
 -- HZ_LOC_ASSIGNMENTS LOC_ASSIGN ,
  HZ_LOCATIONS LOC ,
  FND_TERRITORIES_VL T,
  HZ_CUST_ACCOUNTS HCA,
  HZ_PARTIES HP
WHERE ACCT_SITE.PARTY_SITE_ID   = PARTY_SITE.PARTY_SITE_ID
  AND LOC.LOCATION_ID             = PARTY_SITE.LOCATION_ID
  AND PARTY_SITE.PARTY_ID		= HCA.PARTY_ID
  AND HCA.CUST_ACCOUNT_ID		= ACCT_SITE.CUST_ACCOUNT_ID
  AND HCA.PARTY_ID		= HP.PARTY_ID
  AND PARTY_SITE.PARTY_ID		= HP.PARTY_ID
-- For Bug# 13688313
 -- AND LOC.LOCATION_ID             = LOC_ASSIGN.LOCATION_ID
--  AND NVL(ACCT_SITE.ORG_ID, -99)  = NVL(LOC_ASSIGN.ORG_ID, -99)
  AND LOC.COUNTRY                 = T.TERRITORY_CODE
  AND nvl(acct_site.bill_to_flag, 'N') in (decode(p_show_all_sites,'N','P',nvl(acct_site.bill_to_flag,'N')),decode(p_show_all_sites,'N','Y',nvl(acct_site.bill_to_flag,'N')))
  AND HP.PARTY_NAME LIKE p_customer_name_number)
ORDER BY 2 DESC, 5;

/* <Added against Bug# 5877217 Search By Customer Name and Customer Number>*/
CURSOR cust_cur_by_number (p_customer_name_number VARCHAR2, p_show_all_sites VARCHAR2) IS
SELECT * FROM
(SELECT cust.cust_account_id CUSTOMER_ID,
  'CUST' DETAILS_LEVEL,
  cust.ACCOUNT_NUMBER CUSTOMER_NUMBER,
  SUBSTRB(party.PARTY_NAME,1,50) CUSTOMER_NAME,
  -1 address_id,
  'ALL_LOCATIONS' concatenated_address,
  TO_CHAR(NULL) contact_name,
  TO_CHAR(NULL) contact_phone,
  -1 BILL_TO_SITE_USE_ID,
  TO_CHAR(NULL) site_uses,
  -1 org_id,
  'N' selected,
  TO_CHAR(NULL) location
FROM hz_cust_accounts cust,
  hz_parties party
WHERE cust.party_id = party.party_id AND
      cust.ACCOUNT_NUMBER LIKE p_customer_name_number

UNION ALL

SELECT HCA.CUST_ACCOUNT_ID CUSTOMER_ID ,
  'ADDR' DETAILS_LEVEL,
  HCA.ACCOUNT_NUMBER CUSTOMER_NUMBER,
  SUBSTRB(HP.PARTY_NAME,1,50) CUSTOMER_NAME,
  ACCT_SITE.CUST_ACCT_SITE_ID ADDRESS_ID,
  ARP_ADDR_PKG.FORMAT_ADDRESS(LOC.ADDRESS_STYLE,LOC.ADDRESS1, LOC.ADDRESS2,LOC.ADDRESS3,LOC.ADDRESS4,LOC.CITY,LOC.COUNTY, LOC.STATE,LOC.PROVINCE,LOC.POSTAL_CODE, LOC.COUNTRY) CONCATENATED_ADDRESS,
  TO_CHAR(NULL) CONTACT_NAME,
  TO_CHAR(NULL) CONTACT_PHONE,
  -1 BILL_TO_SITE_USE_ID,
  ari_utilities.get_site_uses(ACCT_SITE.CUST_ACCT_SITE_ID) SITE_USES,
  ACCT_SITE.org_id,
  'N' selected,
  ari_utilities.get_site_use_location(ACCT_SITE.CUST_ACCT_SITE_ID) location
FROM HZ_CUST_ACCT_SITES ACCT_SITE ,
  HZ_PARTY_SITES PARTY_SITE ,
 -- HZ_LOC_ASSIGNMENTS LOC_ASSIGN ,
  HZ_LOCATIONS LOC ,
  FND_TERRITORIES_VL T,
  HZ_CUST_ACCOUNTS HCA,
  HZ_PARTIES HP
WHERE ACCT_SITE.PARTY_SITE_ID   = PARTY_SITE.PARTY_SITE_ID
  AND LOC.LOCATION_ID             = PARTY_SITE.LOCATION_ID
  AND PARTY_SITE.PARTY_ID		= HCA.PARTY_ID
  AND HCA.CUST_ACCOUNT_ID		= ACCT_SITE.CUST_ACCOUNT_ID
  AND HCA.PARTY_ID		= HP.PARTY_ID
  AND PARTY_SITE.PARTY_ID		= HP.PARTY_ID
-- For Bug# 13688313
 -- AND LOC.LOCATION_ID             = LOC_ASSIGN.LOCATION_ID
 -- AND NVL(ACCT_SITE.ORG_ID, -99)  = NVL(LOC_ASSIGN.ORG_ID, -99)
  AND LOC.COUNTRY                 = T.TERRITORY_CODE
  AND nvl(acct_site.bill_to_flag, 'N') in (decode(p_show_all_sites,'N','P',nvl(acct_site.bill_to_flag,'N')),decode(p_show_all_sites,'N','Y',nvl(acct_site.bill_to_flag,'N')))
  AND HCA.ACCOUNT_NUMBER LIKE p_customer_name_number
)
ORDER BY 2 DESC, 5;

CURSOR large_cust_cur_by_number (p_customer_name_number VARCHAR2, p_show_all_sites VARCHAR2) IS
SELECT * FROM
(SELECT cust.cust_account_id CUSTOMER_ID,
  'CUST' DETAILS_LEVEL,
  cust.ACCOUNT_NUMBER CUSTOMER_NUMBER,
  SUBSTRB(cust.ACCOUNT_NAME,1,50) CUSTOMER_NAME,
  -1 address_id,
  'ALL_LOCATIONS' concatenated_address,
  TO_CHAR(NULL) contact_name,
  TO_CHAR(NULL) contact_phone,
  -1 BILL_TO_SITE_USE_ID,
  TO_CHAR(NULL) site_uses,
  -1 org_id,
  'N' selected,
  TO_CHAR(NULL) location
FROM hz_cust_accounts cust
WHERE cust.ACCOUNT_NUMBER LIKE p_customer_name_number

UNION ALL

SELECT HCA.CUST_ACCOUNT_ID CUSTOMER_ID ,
  'ADDR' DETAILS_LEVEL,
  HCA.ACCOUNT_NUMBER CUSTOMER_NUMBER,
  SUBSTRB(HCA.ACCOUNT_NAME,1,50) CUSTOMER_NAME,
  fsul.CUST_ACCT_SITE_ID ADDRESS_ID,
  ARP_ADDR_PKG.FORMAT_ADDRESS(LOC.ADDRESS_STYLE,LOC.ADDRESS1, LOC.ADDRESS2,LOC.ADDRESS3,LOC.ADDRESS4,LOC.CITY,LOC.COUNTY, LOC.STATE,LOC.PROVINCE,LOC.POSTAL_CODE, LOC.COUNTRY) CONCATENATED_ADDRESS,
  TO_CHAR(NULL) CONTACT_NAME,
  TO_CHAR(NULL) CONTACT_PHONE,
  -1 BILL_TO_SITE_USE_ID,
  'Bill To, Ship To' SITE_USES,
  fsul.org_id,
  'N' selected,
  fsul.location
FROM XX_FIN_SITE_USE_LOCATIONS fsul,
     HZ_LOCATIONS LOC ,
     HZ_CUST_ACCOUNTS HCA
WHERE HCA.CUST_ACCOUNT_ID		= fsul.CUST_ACCOUNT_ID
  AND fsul.LOCATION_ID    = LOC.LOCATION_ID
  AND fsul.ORG_ID = 404
  AND fsul.site_use_code = 'BILL_TO'
  --AND nvl(fsul.bill_to_flag, 'N') in (decode(p_show_all_sites,'N','P',nvl(fsul.bill_to_flag,'N')),decode(p_show_all_sites,'N','Y',nvl(fsul.bill_to_flag,'N')))
  AND HCA.ACCOUNT_NUMBER like p_customer_name_number)
ORDER BY 2 DESC, 13;

CURSOR large_cust_cur_by_name (p_customer_name_number VARCHAR2, p_show_all_sites VARCHAR2) IS
SELECT * FROM
(SELECT cust.cust_account_id CUSTOMER_ID,
  'CUST' DETAILS_LEVEL,
  cust.ACCOUNT_NUMBER CUSTOMER_NUMBER,
  SUBSTRB(cust.ACCOUNT_NAME,1,50) CUSTOMER_NAME,
  -1 address_id,
  'ALL_LOCATIONS' concatenated_address,
  TO_CHAR(NULL) contact_name,
  TO_CHAR(NULL) contact_phone,
  -1 BILL_TO_SITE_USE_ID,
  TO_CHAR(NULL) site_uses,
  -1 org_id,
  'N' selected,
  TO_CHAR(NULL) location
FROM hz_cust_accounts cust
WHERE cust.ACCOUNT_NAME LIKE p_customer_name_number

UNION ALL

SELECT HCA.CUST_ACCOUNT_ID CUSTOMER_ID ,
  'ADDR' DETAILS_LEVEL,
  HCA.ACCOUNT_NUMBER CUSTOMER_NUMBER,
  SUBSTRB(HCA.ACCOUNT_NAME,1,50) CUSTOMER_NAME,
  fsul.CUST_ACCT_SITE_ID ADDRESS_ID,
  ARP_ADDR_PKG.FORMAT_ADDRESS(LOC.ADDRESS_STYLE,LOC.ADDRESS1, LOC.ADDRESS2,LOC.ADDRESS3,LOC.ADDRESS4,LOC.CITY,LOC.COUNTY, LOC.STATE,LOC.PROVINCE,LOC.POSTAL_CODE, LOC.COUNTRY) CONCATENATED_ADDRESS,
  TO_CHAR(NULL) CONTACT_NAME,
  TO_CHAR(NULL) CONTACT_PHONE,
  -1 BILL_TO_SITE_USE_ID,
  'Bill To, Ship To' SITE_USES,
  fsul.org_id,
  'N' selected,
  fsul.location location
FROM XX_FIN_SITE_USE_LOCATIONS fsul,
     HZ_LOCATIONS LOC ,
     HZ_CUST_ACCOUNTS HCA
WHERE HCA.CUST_ACCOUNT_ID		= fsul.CUST_ACCOUNT_ID
  AND fsul.LOCATION_ID    = LOC.LOCATION_ID
  AND fsul.ORG_ID = 404
  AND fsul.site_use_code = 'BILL_TO'
  --AND nvl(fsul.bill_to_flag, 'N') in (decode(p_show_all_sites,'N','P',nvl(fsul.bill_to_flag,'N')),decode(p_show_all_sites,'N','Y',nvl(fsul.bill_to_flag,'N')))
  AND HCA.ACCOUNT_NAME LIKE p_customer_name_number )
ORDER BY 2 DESC, 13;

/* </Temporary fix for bug number 2235656> */

--
-- Get ALL matching addresses returned by the context search
--
-- srajasek 06-APR-00 Changed ra_addresses_all to hz_cust_acct_sites_all because of tca changes in 11.5.1

-- modified for tca uptake.  replaced ra_customers with hz_cust_accounts and
-- hz_parties.

-- Bug 2094233
-- krmenon 28 Dec 2001 Removed the order by clause for performance issues
/*--
  -- krmenon 07 Jan 2002 Changed the Cursor to remove extra joins and reintroduce
  -- the order by score since this is necessary to get the high score results
  CURSOR ctx_cur (p_keyword VARCHAR2) IS
     SELECT adr.cust_acct_site_id address_id, adr.cust_account_id customer_id, score(1) total_score
     FROM   hz_cust_acct_sites_all adr,
            hz_cust_accounts cus,
            hz_parties party,
            ar_system_parameters_all sys
     WHERE ctxsys.CONTAINS (address_text, NVL(p_keyword, '%') , 1) > 0
     AND   adr.cust_account_id =  cus.cust_account_id
     AND   cus.party_id = party.party_id
     AND   adr.org_id      = sys.org_id    ;
     ORDER BY score(1) desc, cus.cust_account_id,
              party.party_name, cus.account_number, adr.cust_acct_site_id;
  --*/
  /* Bug2288089: Removed _all for hz_cust_acct_sites */
CURSOR ctx_cur (p_keyword VARCHAR2) IS
   SELECT adr.cust_acct_site_id address_id, adr.cust_account_id customer_id, score(1) total_score
   FROM   hz_cust_acct_sites adr
   WHERE ctxsys.CONTAINS (address_text, NVL(p_keyword, '%') , 1) > 0
   ORDER BY score(1) desc;

l_cust_tab     cust_tab;
l_rev_cust_tab rev_cust_tab;
--
l_addr_tab     addr_tab;
--
l_curr_ix BINARY_INTEGER;
l_end_ix   BINARY_INTEGER;
--
/***
-- Load the scores in the PL/SQL tables
***/

PG_DEBUG varchar2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');

PROCEDURE load_scores (p_keyword IN VARCHAR2 ) IS
l_cus_seq_num BINARY_INTEGER:= 1;
l_keyword     VARCHAR2(100) DEFAULT '%';
BEGIN
   l_cust_tab.DELETE;
   l_rev_cust_tab.DELETE;
   l_addr_tab.DELETE;

   IF ( p_keyword IS NOT NULL ) THEN
      l_keyword := p_keyword;
   END IF;

   FOR ctx_rec IN ctx_cur (l_keyword) LOOP
   --
      IF NOT l_cust_tab.EXISTS(ctx_rec.customer_id) THEN
	 l_cust_tab(ctx_rec.customer_id).cus_seq_num := l_cus_seq_num;
	 l_cust_tab(ctx_rec.customer_id).addr_cnt := 1;
	 l_rev_cust_tab(l_cus_seq_num).customer_id := ctx_rec.customer_id;
	 l_cus_seq_num := l_cus_seq_num + 1;
      ELSE
         l_cust_tab(ctx_rec.customer_id).addr_cnt := l_cust_tab(ctx_rec.customer_id).addr_cnt + 1;
      END IF;
   --
      l_rev_cust_tab(l_cust_tab(ctx_rec.customer_id).cus_seq_num).addr_cnt := l_cust_tab(ctx_rec.customer_id).addr_cnt;
   --
      l_addr_tab (ctx_rec.address_id).customer_id := ctx_rec.customer_id;
      l_addr_tab (ctx_rec.address_id).total_score := ctx_rec.total_score;
      l_addr_tab (ctx_rec.address_id).addr_seq_num := l_cust_tab(ctx_rec.customer_id).addr_cnt;
   --
   END LOOP;

END load_scores;


/* Bug2202580: Added these functions to avoid interMedia parse errors.
   These are borrowed from FND_IMUTL pkg and modified to suit irec . */
FUNCTION process_reserve_char(p_search_token IN VARCHAR2) RETURN VARCHAR2  IS

BEGIN

RETURN(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(p_search_token,
'\','\\'),
'&','\&'),
'{','\{'),
'}','\}'),
'[','\['),
']','\]'),
';','\;'),
'|','\|'),
'$','\$'),
'!','\!'),
'=','\='),
'>','\>'));

END process_reserve_char;

FUNCTION process_reserve_word(p_search_token IN VARCHAR2) RETURN VARCHAR2  IS
    l_search_token     varchar2(100) ;
BEGIN
    l_search_token := UPPER(p_search_token);

IF (l_search_token = 'ACCUM')THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'BT') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'BTG') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'BTI') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'BTP') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'MINUS') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'NEAR') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'NOT') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'NT') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'NTG') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'NTI') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'NTP') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'PT') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'SQE') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'SYN') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'TR') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'TRSYN') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'TT') THEN
   RETURN ( '{'||p_search_token||'}');
ELSIF (l_search_token = 'WITHIN') THEN
   RETURN ( '{'||p_search_token||'}');
ELSE
   RETURN (p_search_token);
END IF;

END process_reserve_word;

FUNCTION parse_search_string(p_search_string in varchar2 ) RETURN VARCHAR2  IS

  TYPE tokens is table of varchar2(256) index by binary_integer;
  string_token    	tokens;

  l_search_string      	varchar2(256):= '';
  l_str_token 	        varchar2(256):= '';
  l_new_search_string  	varchar2(256):= '';
  j                    	number :=0;
  i                    	number :=0;
  space                	number :=0;
  l_last_char 		varchar2(256):= '';
  l_last_char_new 	varchar2(256):= '';

BEGIN
  l_search_string := rtrim(p_search_string, ' ');
  l_search_string := ltrim(l_search_string, ' ');

  if (l_search_string is NULL) then
    return null;
  end if;

  l_search_string := l_search_string || ' @@';            -- identifies final token --
  l_search_string := replace(l_search_string,'*','%');    -- translate wildcard symbols --

  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug('l_search_string : '||l_search_string);
  END IF;
  -----------------------------
  -- Parse the search string --
  -----------------------------
  WHILE (TRUE) LOOP
    l_search_string := ltrim(l_search_string, ' ');
    --------------------------------
    -- Check to see if we're done --
    --------------------------------
    if ( instrb(l_search_string, '@@') = 1) then
      exit;
    end if;
    ---------------------------------------------------------------------
    -- Create a list of tokens delimited by spaces .
    --------------------------------------------------------------------
     space := instrb(l_search_string, ' ');
     string_token(j) := substrb(l_search_string, 1, space-1);
     l_search_string := substrb(l_search_string, space+1);

     j := j + 1;

  END LOOP;

  i := 0;
  WHILE ( i < j) LOOP

    l_str_token := process_reserve_word(process_reserve_char(string_token(i)));

    IF (i=j-1) THEN
      l_last_char := substrb(l_str_token,-1,1);
      l_last_char_new := '\'||l_last_char ;
      IF l_last_char in ('?',',','~','-') THEN
        l_str_token := replace(l_str_token,l_last_char,l_last_char_new);
      END IF;
      IF UPPER(l_str_token) in ('AND', 'OR', 'ABOUT') THEN
        l_str_token := '{' || l_str_token || '}' ;
      END IF;
    END IF;

    l_new_search_string :=  l_new_search_string || ' '|| l_str_token;
    i := i + 1;

  END LOOP;

  IF (PG_DEBUG = 'Y') THEN
    arp_standard.debug('l_new_search_string: '||l_new_search_string);
  END IF;

  RETURN ltrim(l_new_search_string,' ');

END parse_search_string ;


/*----------------------------------------------------------------------------*
 | PUBLIC FUNCTION                                                            |
 |    search_customers                                                       |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    This function returns the customer table which will contain the         |
 |    customer records. Sorted in the following order :                       |
 |          - Customers containing best matches will appear at top of the     |
 |            list.                                                           |
 |          - Within a customer, best address matches will appear at the top  |
 |                                                                            |
 | REQUIRES                                                                   |
 |                                                                            |
 | RETURNS                                                                    |
 |    Customer Record table in pre-defined sorted order                       |
 |                                                                            |
 | EXCEPTIONS RAISED                                                          |
 |                                                                            |
 | KNOWN BUGS                                                                 |
 |    <none>                                                                  |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | HISTORY                                                                    |
 |      15-APR-99       Ramakant Alat           Created                       |
 *----------------------------------------------------------------------------*/

FUNCTION search_customers(
    i_keyword IN varchar2 DEFAULT NULL, -- Default added for Bug 16737932
    i_show_all_sites IN VARCHAR2 DEFAULT 'Y', -- Default added for Bug 16737932
    i_first_row IN binary_integer DEFAULT 1 , -- Default added for Bug 16737932
    i_last_row IN binary_integer DEFAULT NULL -- Default added for Bug 16737932
  ) RETURN customer_tabletype IS

  l_cust_ix	binary_integer := 1;
  l_cust_st_ix	binary_integer := 1;

  no_match_cnt	binary_integer := 0;
  addr_offset	binary_integer := 0;
  l_keyword     varchar2(256)  DEFAULT NULL;

  l_cust_table customer_tabletype;

BEGIN
   l_keyword := parse_search_string(i_keyword);

   -- Load Scores into PL/SQL tables
   load_scores (l_keyword);

   FOR i IN 1..l_rev_cust_tab.COUNT LOOP
   --
      l_cust_st_ix := l_cust_ix;
   --

   /***
    *** Get address offset = No of addr matches + 1
    ***/

      addr_offset := l_rev_cust_tab(i).addr_cnt + 1;
   --
      no_match_cnt := 0;
   --
   ----------------------------------------
   -- **** Get all customer records ***
   ----------------------------------------
   --
      FOR l_cust_rec IN cust_cur (l_rev_cust_tab(i).customer_id, i_show_all_sites) LOOP
      --
	 IF l_addr_tab.EXISTS(l_cust_rec.address_id) THEN  -- Matched Address
	     l_cust_rec.selected := 'Y';
         END IF;
      --
	 IF l_cust_st_ix = l_cust_ix THEN  --- Process first record ("All Locations" for more than one)
            l_cust_table( l_cust_ix ) := l_cust_rec;
	 ELSE
	    IF l_addr_tab.EXISTS(l_cust_rec.address_id) THEN

	    -- For Matched address use address seq to copy

	       l_cust_table(l_cust_st_ix + l_addr_tab(l_cust_rec.address_id).addr_seq_num) := l_cust_rec;

            ELSE

	    -- For Unmatched use offset to copy

               l_cust_table( l_cust_st_ix + addr_offset + no_match_cnt) := l_cust_rec;
	       no_match_cnt := no_match_cnt + 1;

            END IF;
	 END IF;
      --
         l_cust_ix := l_cust_ix + 1;
      --
         -- bugfix 2235673 : reversing bugfix 2175758
         IF l_cust_ix > nvl(i_last_row ,MAX_BUFFERED_ROWS) THEN
         /* bug 2175758 : remove NVL on i_last_row, because it is limiting the number
            of customers returned for blind queries
	 IF l_cust_ix > i_last_row  THEN*/
	    GOTO limited_rows;
	 END IF;
      --
      END LOOP;
   --
   END LOOP;

<<limited_rows>>

   RETURN l_cust_table;

END search_customers;


/* <Added against Bug# 5877217 Search By Customer Name and Customer Number> */


FUNCTION search_by_name_num(
    i_customer_name_number IN varchar2,
    i_show_all_sites IN VARCHAR2
) RETURN customer_tabletype IS

  no_match_cnt	binary_integer := 0;
  l_cust_table customer_tabletype;
  l_large_cust_flag varchar2(1) := 'N';

  l_temp number;
  l_is_number varchar2(1) := 'Y';
BEGIN

   ----------------------------------------
   -- **** Get all customer records ***
   ----------------------------------------
   --

   begin
     l_temp := null;

     select to_number(i_customer_name_number) into l_temp from dual;
     l_is_number := 'Y';
   exception
     when others then
       l_is_number := 'N';
   end;


   if (l_is_number = 'Y') then

      begin
        select firl.enabled_flag
        into   l_large_cust_flag
        from   hz_cust_accounts acct
              ,xx_fin_irec_large_customers firl
        where  acct.cust_account_id = firl.cust_account_id
        and    acct.account_number = i_customer_name_number
        and    status='A'
        ;
      exception
        when others then
          l_large_cust_flag := 'N';
      end;


      if (l_large_cust_flag = 'Y') then
        FOR lr_cust_rec IN large_cust_cur_by_number (i_customer_name_number, i_show_all_sites) LOOP
           IF no_match_cnt > MAX_BUFFERED_ROWS THEN
              RETURN l_cust_table;
           ELSE
                 l_cust_table(no_match_cnt) := lr_cust_rec;
	         no_match_cnt := no_match_cnt + 1;
           END IF;
        END LOOP;

      else
        FOR l_cust_rec IN cust_cur_by_number (i_customer_name_number, i_show_all_sites) LOOP
           IF no_match_cnt > MAX_BUFFERED_ROWS THEN
              RETURN l_cust_table;
           ELSE
                 l_cust_table(no_match_cnt) := l_cust_rec;
	         no_match_cnt := no_match_cnt + 1;
           END IF;
        END LOOP;

      end if;
    else

      if (instr(i_customer_name_number, '%') <> 0) then
        begin
          select firl.enabled_flag
          into   l_large_cust_flag
          from   hz_cust_accounts acct
                ,xx_fin_irec_large_customers firl
          where  acct.cust_account_id = firl.cust_account_id
          and    acct.account_name = i_customer_name_number
          and    status='A'
          ;
        exception
          when others then
            l_large_cust_flag := 'N';
        end;
      end if;


      if (l_large_cust_flag = 'Y') then
        FOR lr_cust_rec IN large_cust_cur_by_name (i_customer_name_number, i_show_all_sites) LOOP
           IF no_match_cnt > MAX_BUFFERED_ROWS THEN
              RETURN l_cust_table;
           ELSE
                 l_cust_table(no_match_cnt) := lr_cust_rec;
	         no_match_cnt := no_match_cnt + 1;
           END IF;
        END LOOP;

      else
        FOR l_cust_rec IN cust_cur_by_name (i_customer_name_number, i_show_all_sites) LOOP
           IF no_match_cnt > MAX_BUFFERED_ROWS THEN
              RETURN l_cust_table;
           ELSE
                 l_cust_table(no_match_cnt) := l_cust_rec;
	         no_match_cnt := no_match_cnt + 1;
           END IF;
        END LOOP;
      end if;

    end if;
   RETURN l_cust_table;

END search_by_name_num;


/* <Temporary fix for bug number 2235656> */


/*----------------------------------------------------------------------------*
 | PUBLIC FUNCTION                                                            |
 |    search_customers_by_trx                                                 |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    This function returns the customer who has an invoice number that       |
 |    matches i_keyword.                                                      |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 | REQUIRES                                                                   |
 |                                                                            |
 | RETURNS                                                                    |
 |    The customer as a row in a Customer Record table                        |
 |                                                                            |
 | EXCEPTIONS RAISED                                                          |
 |                                                                            |
 | KNOWN BUGS                                                                 |
 |    <none>                                                                  |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | HISTORY                                                                    |
 |      19-APR-02       Joe Albowicz            Created                       |
 *----------------------------------------------------------------------------*/

FUNCTION search_customers_by_trx (
    i_keyword IN varchar2
  ) RETURN customer_tabletype IS

  l_cust_table customer_tabletype;
  i_index binary_integer;
BEGIN

    OPEN cust_cur_trx(i_keyword);

    i_index := 1;

    LOOP
        FETCH cust_cur_trx INTO l_cust_table(i_index);
        EXIT WHEN cust_cur_trx%NOTFOUND;
        i_index := i_index +1;
    END LOOP;

    CLOSE cust_cur_trx;

    RETURN l_cust_table;

END search_customers_by_trx;

/* </Temporary fix for bug number 2235656> */




/*----------------------------------------------------------------------------*
 | PUBLIC PROCEDURE                                                           |
 |    ari_search                                                              |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    This procedure is a wrapper for the search_customers function. It       |
 |    invokes the search_customers function for a given keyword, and inserts  |
 |    the result data from the PL/SQL table into a global temporary table.    |
 |                                                                            |
 | REQUIRES                                                                   |
 |                                                                            |
 | RETURNS                                                                    |
 |                                                                            |
 | EXCEPTIONS RAISED                                                          |
 |                                                                            |
 | KNOWN BUGS                                                                 |
 |    <none>                                                                  |
 |                                                                            |
 | NOTES                                                                      |
 |    This wrapper was necessary because the new techstack did not have any   |
 |    way to exchange PL/SQL table types b/w java beans and PL/SQL procedures.|
 | HISTORY                                                                    |
 |      15-Dec-00       Krishnakumar Menon           Created                  |
 |      25-Oct-04       vnb                 Bug 3926187 - Modified to handle  |
 |                                          exceptions                        |
 | 23-Jan-15    gnramasa    Bug 20387436 - PAYMENTS - SWITCHING OU/CURRENCY   |
 |                            AND MAKING 2ND PYMT CAUSES EXCHANGE RATE ERROR  |
 *----------------------------------------------------------------------------*/
PROCEDURE ari_search ( i_keyword   IN varchar2,
		       i_name_num IN VARCHAR2,
		       i_exclude_contact IN VARCHAR2,
		       i_show_all_sites IN VARCHAR2,
		       x_status    OUT NOCOPY VARCHAR2,
                       x_msg_count OUT NOCOPY NUMBER,
                       x_msg_data  OUT NOCOPY VARCHAR2 ) is

    l_search_result_table  customer_tabletype;

    l_all_locations       VARCHAR2(100) := icx_util.getPrompt(
                                                  p_region_application_id => 222,
                                                  p_region_code => 'ARW_COMMON',
                                                  p_attribute_application_id => 222,
                                                  p_attribute_code => 'ARW_TEXT_ALL_LOCATIONS'
                                               );
    l_tab_idx  BINARY_INTEGER;
    l_keyword  VARCHAR2(128);
    l_show_all_sites VARCHAR2(20);
    l_prefix   CHAR;
    l_contact_id   NUMBER;
    l_procedure_name VARCHAR2(30);
    l_debug_info	 VARCHAR2(200);

BEGIN
    l_procedure_name := '.ari_search';
    x_msg_count      := 0;
    x_msg_data       := '';
    x_status         := FND_API.G_RET_STS_ERROR;


    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	  fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,
                 'Begin+');
       end if;

    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	     fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'1. Calling arp_global.init_global');
	     fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'org_id value is : ' || mo_global.get_current_org_id);
    end if;
    IF mo_global.get_current_org_id is null then
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Calling ARP_GLOBAL.INIT_GLOBAL without org_id as parameter');
      end if;
      ARP_GLOBAL.INIT_GLOBAL;
    ELSE
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Calling ARP_GLOBAL.INIT_GLOBAL with org_id :' || mo_global.get_current_org_id || ' as parameter');
      end if;
      ARP_GLOBAL.INIT_GLOBAL(mo_global.get_current_org_id);
    END IF;
    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Functional currency is: ' || arp_global.functional_currency);
    end if;

    --------------------------------------------------------------------------
    l_debug_info := 'Delete all entries from the table for the current session';
    --------------------------------------------------------------------------

    IF (PG_DEBUG = 'Y') THEN
     arp_standard.debug(l_debug_info);
    END IF;

    -- Delete all entries from the table for the current session
    delete from ar_cust_search_gt;

    l_keyword := ltrim(rtrim(i_keyword));
    l_prefix := substrb(l_keyword,1,1);

    IF(i_show_all_sites = 'Y') THEN
	  l_show_all_sites := 'Y';
    ELSE
	  l_show_all_sites := 'N';
    END IF;
    --------------------------------------------------------------------------
    l_debug_info := 'Call to the search customer by name and number function';
    --------------------------------------------------------------------------
    IF (PG_DEBUG = 'Y') THEN
        arp_standard.debug(l_debug_info);
     END IF;

    if i_name_num = 'YES' then

	l_search_result_table := arw_search_customers.search_by_name_num(
					    i_customer_name_number => l_keyword,
					    i_show_all_sites => l_show_all_sites);

    else

	    --------------------------------------------------------------------------
	    l_debug_info := 'Call the search customer function';
	    --------------------------------------------------------------------------
	    IF (PG_DEBUG = 'Y') THEN
        	arp_standard.debug(l_debug_info);
	    END IF;
	    -- Call the search customer function
	    --   Use search_customers_by_trx if search string prefaced by '#'
	/* <Temporary fix for bug number 2235656> */
	    if l_prefix = '#' then
	      l_keyword := substrb(l_keyword, 2, lengthb(l_keyword)-1);
	      l_search_result_table := arw_search_customers.search_customers_by_trx(i_keyword => l_keyword);
	    else
	/* </Temporary fix for bug number 2235656> */
	      l_search_result_table := arw_search_customers.search_customers(
					    i_keyword => l_keyword,
					    i_show_all_sites => l_show_all_sites);
	    end if;

    end if;

    -- Insert returned rows into the global temporary table.
    -- Bug Fix 1920131 [Cannot loop sequencially since certain indexes may not be populated]
    --------------------------------------------------------------------------
    l_debug_info := 'Insert returned rows into the global temporary table';
    --------------------------------------------------------------------------
    IF (PG_DEBUG = 'Y') THEN
	arp_standard.debug(l_debug_info);
    END IF;

   if   i_exclude_contact <> 'YES'  then     -- added for bug 10265497

      IF (PG_DEBUG = 'Y') THEN
        arp_standard.debug('Just before For Loop getting Customer Contacts ');
      END IF;

      --Fetch the Contact and get the contact name and phone and update for each bill to
      l_tab_idx := l_search_result_table.FIRST;

      LOOP
        -- Exit if there are no more records
        EXIT WHEN l_tab_idx IS NULL;
        l_contact_id := ari_utilities.get_contact_id(l_search_result_table(l_tab_idx).customer_id,l_search_result_table(l_tab_idx).address_id, 'SELF_SERVICE_USER');

        l_search_result_table(l_tab_idx).contact_name := ari_utilities.get_contact(l_contact_id);
        l_search_result_table(l_tab_idx).contact_phone := ari_utilities.get_phone(l_contact_id, 'GEN');
        l_search_result_table(l_tab_idx).site_uses := ari_utilities.get_site_uses(l_search_result_table(l_tab_idx).address_id);
        l_tab_idx := l_search_result_table.NEXT(l_tab_idx);

        END LOOP;

        IF (PG_DEBUG = 'Y') THEN
          arp_standard.debug('After For Loop getting Customer Contacts ');
        END IF;

    end if;    -- end if  condition added for bug 10265497



    l_tab_idx := l_search_result_table.FIRST;

    LOOP
        BEGIN
            -- Exit if there are no more records
            EXIT WHEN l_tab_idx IS NULL;

            INSERT INTO ar_cust_search_gt (
                customer_id,
                address_id,
                bill_to_site_use_id,
                details_level,
                customer_number,
                customer_name,
                contact_name,
                contact_phone,
                site_uses,
                org_id,
                concatenated_address,
                location
            )
            VALUES (
                l_search_result_table(l_tab_idx).customer_id,
                l_search_result_table(l_tab_idx).address_id,
                decode(l_search_result_table(l_tab_idx).bill_to_site_use_id,-1,null,
                       l_search_result_table(l_tab_idx).bill_to_site_use_id),
                l_search_result_table(l_tab_idx).details_level,
                l_search_result_table(l_tab_idx).customer_number,
                l_search_result_table(l_tab_idx).customer_name,
                l_search_result_table(l_tab_idx).contact_name,
                l_search_result_table(l_tab_idx).contact_phone,
                l_search_result_table(l_tab_idx).site_uses,
                l_search_result_table(l_tab_idx).org_id,
                decode(l_search_result_table(l_tab_idx).address_id, -1, l_all_locations,
                       substrb(l_search_result_table(l_tab_idx).concatenated_address,1,255)),
                l_search_result_table(l_tab_idx).location

              );

            l_tab_idx := l_search_result_table.NEXT(l_tab_idx);

            EXCEPTION
                WHEN OTHERS THEN
                BEGIN
                    x_msg_data  := SQLERRM;
                    x_msg_count := x_msg_count + 1;
                    IF (PG_DEBUG = 'Y') THEN
                       arp_standard.debug('Unexpected Exception in ari_search: Loop and Insert');
                       arp_standard.debug('- Search Key: '||i_keyword );
                       arp_standard.debug('- Current Index: '||to_char(l_tab_idx));
                       arp_standard.debug(SQLERRM);
                    END IF;
                END;

        END;

    END LOOP;

    x_status := FND_API.G_RET_STS_SUCCESS;

EXCEPTION
    WHEN OTHERS THEN
      -- Handle Oracle Text errors (specific to the InterMedia index)
      IF (SQLCODE = -20000) THEN
        -- If the customer index has not been built...
        IF INSTRB(SQLERRM,'DRG-10599')>0 THEN
            FND_MESSAGE.SET_NAME ('AR','ARI_CUST_SEARCH_INDEX_ERROR');
            x_msg_data  := FND_MESSAGE.GET;
            x_msg_count := x_msg_count + 1;
        --If the wildcard search returns too many matches...
        ELSIF INSTRB(SQLERRM,'DRG-51030')>0 THEN
            FND_MESSAGE.SET_NAME ('AR','HZ_DQM_WILDCARD_ERR');
            x_msg_data  := FND_MESSAGE.GET;
            x_msg_count := x_msg_count + 1;
        ELSE
            x_msg_data  := SQLERRM;
            x_msg_count := x_msg_count + 1;
        END IF;
      ELSE
        x_msg_data  := SQLERRM;
        x_msg_count := x_msg_count + 1;
      END IF;

      IF (PG_DEBUG = 'Y') THEN
        arp_standard.debug('Unexpected Exception in ARI_SEARCH');
        arp_standard.debug('- Search Key: '||i_keyword );
        arp_standard.debug(SQLERRM);
      END IF;

END ari_search;

PROCEDURE initialize_account_sites ( p_custsite_rec_tbl in CustSite_tbl,
		p_party_id in number,
		p_session_id in number,
		p_user_id in number ,
		p_org_id in number ,
		p_is_internal_user in varchar2
		)
	IS

	 l_curr_index   NUMBER;
   	l_index        NUMBER := 0;
	 p_customer_id  NUMBER;
	 p_site_use_id  NUMBER;
   l_org_id       NUMBER;
   l_procedure_name VARCHAR2(30) := 'initialize_account_sites';

	CURSOR FETCH_SITES_ID_CURSOR IS
		SELECT
		Sites_assigned.CUST_ACCOUNT_ID account_id , acct_sites.CUST_ACCT_SITE_ID address_id,acct_sites.org_id org_id
		FROM
		hz_cust_acct_sites     acct_sites,
		hz_party_sites         party_sites,
		hz_cust_accounts       Cust,
		ar_sites_assigned_v    Sites_assigned
		WHERE Sites_assigned.party_id = p_party_id
		AND Sites_assigned.cust_account_id=nvl(p_customer_id,Sites_assigned.cust_account_id)
		AND cust.cust_account_id = Sites_assigned.cust_account_id
		AND Sites_assigned.cust_account_id = acct_sites.cust_account_id
		AND Sites_assigned.cust_acct_site_id = acct_sites.cust_acct_site_id
		AND ACCT_SITES.party_site_id     = PARTY_SITES.party_site_id;

pragma autonomous_transaction ;

BEGIN
delete from ar_irec_user_acct_sites_all where (session_id=p_session_id
  or trunc(CREATION_DATE)<=trunc(sysdate-2));

IF (p_user_id = 6) THEN
  mo_global.init('AR');
  mo_global.set_policy_context('M',-1);

  if(p_org_id is null) then
    l_org_id := FND_PROFILE.value('ORG_ID');
  else
    l_org_id := p_org_id;
  end if;
END IF;

    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	     fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'2. Calling arp_global.init_global');
	     fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'org_id value is : ' || mo_global.get_current_org_id);
    end if;
    IF mo_global.get_current_org_id is null then
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Calling ARP_GLOBAL.INIT_GLOBAL without org_id as parameter');
      end if;
      ARP_GLOBAL.INIT_GLOBAL;
    ELSE
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Calling ARP_GLOBAL.INIT_GLOBAL with org_id :' || mo_global.get_current_org_id || ' as parameter');
      end if;
      ARP_GLOBAL.INIT_GLOBAL(mo_global.get_current_org_id);
    END IF;
    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Functional currency is: ' || arp_global.functional_currency);
    end if;

      l_curr_index :=  p_custsite_rec_tbl.first;

	-- bug #5858769
	--   iterating for each customerid and siteid pair and populating the table.

      WHILE (l_curr_index <= p_custsite_rec_tbl.last) LOOP

	 p_customer_id := p_custsite_rec_tbl(l_curr_index).CustomerId;
	 p_site_use_id := p_custsite_rec_tbl(l_curr_index).SiteUseId;

  IF ( p_site_use_id is not null ) THEN
      select org_id into l_org_id from hz_cust_site_uses where site_use_id = p_site_use_id;
  END IF;
	  IF (p_is_internal_user='Y') THEN

		IF ( p_site_use_id is null and p_customer_id is not null) THEN

		/* the following insert statement is added for bug 7678038  to show receipts created with out location */

  	     	INSERT INTO ar_irec_user_acct_sites_all
   		(SESSION_ID,CUSTOMER_ID,CUSTOMER_SITE_USE_ID,USER_ID,CURRENT_DATE,ORG_ID, CREATION_DATE)
     		VALUES(p_session_id,p_customer_id,'-1',p_user_id,sysdate,fnd_global.org_id, trunc(sysdate));

            /*
			FOR account_assigned_site IN (
				select CUST_ACCT_SITE_ID,org_id from hz_cust_acct_sites where CUST_ACCOUNT_ID = p_customer_id
			)LOOP

             -- Bug 14486763 - To insert multiple bill to site use ids of a CUST_ACCT_SITE_ID
			 insert_acct_site_uses(p_session_id => p_session_id, p_user_id => p_user_id, p_org_id => account_assigned_site.org_id, p_customer_id => p_customer_id, p_cust_acct_site_id => account_assigned_site.CUST_ACCT_SITE_ID);


			END LOOP;
            */

		  ELSIF (( p_site_use_id is not null ) and (p_customer_id is not null)) THEN

          -- Bug 14486763 - To insert multiple bill to site use ids of a CUST_ACCT_SITE_ID
					insert_acct_site_uses(p_session_id => p_session_id, p_user_id => p_user_id, p_org_id => l_org_id, p_customer_id => p_customer_id, p_site_use_id => p_site_use_id);

		  END IF;
	  ELSE
		  IF ( p_site_use_id is null ) THEN

			/* insert all the sites this party is having direct access */

			FOR FETCH_SITES_ID_CURSOR_RECORD IN FETCH_SITES_ID_CURSOR loop

              -- Bug 14486763 - To insert multiple bill to site use ids of a CUST_ACCT_SITE_ID
              insert_acct_site_uses(p_session_id => p_session_id, p_user_id => p_user_id, p_org_id => FETCH_SITES_ID_CURSOR_RECORD.org_id, p_customer_id => FETCH_SITES_ID_CURSOR_RECORD.account_id, p_cust_acct_site_id => FETCH_SITES_ID_CURSOR_RECORD.address_id);


			END LOOP;

			/* Check for account level access and insert all bill to sites */

			FOR customer_assigned_record IN (
				select cust_account_id from ar_customers_assigned_v where party_id=p_party_id AND cust_account_id=nvl(p_customer_id,cust_account_id)
			)LOOP

				FOR account_assigned_site IN (
					select CUST_ACCT_SITE_ID,org_id from hz_cust_acct_sites where CUST_ACCOUNT_ID=customer_assigned_record.cust_account_id
				)LOOP
                -- Bug 14486763 - To insert multiple bill to site use ids of a CUST_ACCT_SITE_ID
				insert_acct_site_uses(p_session_id => p_session_id, p_user_id => p_user_id, p_org_id => account_assigned_site.org_id, p_customer_id => customer_assigned_record.cust_account_id, p_cust_acct_site_id => account_assigned_site.CUST_ACCT_SITE_ID);

				END LOOP;

		      /* the following insert statement is added for bug 7678038  to show receipts created with out location */

			END LOOP;

		  ELSIF (( p_site_use_id is not null ) and (p_customer_id is not null)) THEN

                 -- Bug 14486763 - To insert multiple bill to site use ids of a CUST_ACCT_SITE_ID
				insert_acct_site_uses(p_session_id => p_session_id, p_user_id => p_user_id, p_org_id => l_org_id, p_customer_id => p_customer_id, p_site_use_id => p_site_use_id);

		  END IF;
	   END IF;
	------------------------------------------------

        l_curr_index := p_custsite_rec_tbl.next(l_curr_index);

      END LOOP;

/* REMOVE DUPLICATE ROWS IF ANY */

DELETE FROM ar_irec_user_acct_sites_all A WHERE ROWID > (
     SELECT min(rowid) FROM ar_irec_user_acct_sites_all B
     WHERE A.org_id = B.org_id
     AND A.SESSION_ID=B.SESSION_ID
     AND A.USER_ID=B.USER_ID
     AND A.CUSTOMER_ID=B.CUSTOMER_ID
     AND A.CUSTOMER_SITE_USE_ID=B.CUSTOMER_SITE_USE_ID
     AND A.CREATION_DATE=B.CREATION_DATE
     );

commit;

END initialize_account_sites;

-- Bug 14486763 - To insert multiple bill to site use ids of a CUST_ACCT_SITE_ID
PROCEDURE insert_acct_site_uses ( p_session_id in number,
		p_user_id in number ,
		p_org_id in number ,
		p_customer_id in number,
		p_cust_acct_site_id in number default null,
		p_site_use_id in number default null
		) is
l_site_use_id  NUMBER;
l_cust_acct_site_id  NUMBER;
l_procedure_name     VARCHAR2(30) := 'insert_acct_site_uses';
begin

    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	     fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'3. Calling arp_global.init_global');
	     fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'org_id value is : ' || mo_global.get_current_org_id);
    end if;
    IF mo_global.get_current_org_id is null then
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Calling ARP_GLOBAL.INIT_GLOBAL without org_id as parameter');
      end if;
      ARP_GLOBAL.INIT_GLOBAL;
    ELSE
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Calling ARP_GLOBAL.INIT_GLOBAL with org_id :' || mo_global.get_current_org_id || ' as parameter');
      end if;
      ARP_GLOBAL.INIT_GLOBAL(mo_global.get_current_org_id);
    END IF;
    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Functional currency is: ' || arp_global.functional_currency);
    end if;

	  if(p_site_use_id is not null) then
			SELECT cust_acct_site_id into l_cust_acct_site_id FROM hz_cust_site_uses WHERE  SITE_USE_ID = p_site_use_id;
		end if;
		if(p_cust_acct_site_id is not null) then
			l_cust_acct_site_id := p_cust_acct_site_id;
		end if;
		FOR account_assigned_site IN (
				SELECT SITE_USE_ID FROM hz_cust_site_uses WHERE cust_acct_site_id = l_cust_acct_site_id and SITE_USE_CODE = 'BILL_TO'
			)LOOP
					INSERT INTO ar_irec_user_acct_sites_all
					(SESSION_ID,CUSTOMER_ID,CUSTOMER_SITE_USE_ID,USER_ID,CURRENT_DATE,ORG_ID, CREATION_DATE)
					VALUES(p_session_id,p_customer_id,account_assigned_site.SITE_USE_ID,p_user_id,sysdate,fnd_global.org_id, trunc(sysdate));
			END LOOP;

end insert_acct_site_uses;


PROCEDURE init_acct_sites_anon_login ( p_customer_id in number,
		p_site_use_id in number,
		p_party_id in number,
		p_session_id in number,
		p_user_id in number ,
		p_org_id in number ,
		p_is_internal_user in varchar2
		)
	IS

	 l_curr_index   NUMBER;
         l_index        NUMBER := 0;
         l_org_id       NUMBER;
         l_procedure_name VARCHAR2(30) := 'init_acct_sites_anon_login';

	CURSOR FETCH_SITES_ID_CURSOR IS
		SELECT
		Sites_assigned.CUST_ACCOUNT_ID account_id , acct_sites.CUST_ACCT_SITE_ID address_id
		FROM
		hz_cust_acct_sites     acct_sites,
		hz_party_sites         party_sites,
		hz_cust_accounts       Cust,
		ar_sites_assigned_v    Sites_assigned
		WHERE -- Sites_assigned.party_id = p_party_id AND
		Sites_assigned.cust_account_id=nvl(p_customer_id,Sites_assigned.cust_account_id)
		AND cust.cust_account_id = Sites_assigned.cust_account_id
		AND Sites_assigned.cust_account_id = acct_sites.cust_account_id
		AND Sites_assigned.cust_acct_site_id = acct_sites.cust_acct_site_id
		AND ACCT_SITES.party_site_id     = PARTY_SITES.party_site_id;

pragma autonomous_transaction ;

BEGIN
delete from ar_irec_user_acct_sites_all where (session_id=p_session_id
  or trunc(CREATION_DATE)<=trunc(sysdate-2));

mo_global.init('AR');
mo_global.set_policy_context('M',-1);

if(p_org_id is null) then
  l_org_id := FND_PROFILE.value('ORG_ID');
else
  l_org_id := fnd_global.org_id;
end if;

	  if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	     fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'4. Calling arp_global.init_global');
	     fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'org_id value is : ' || mo_global.get_current_org_id);
    end if;
    IF mo_global.get_current_org_id is null then
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Calling ARP_GLOBAL.INIT_GLOBAL without org_id as parameter');
      end if;
      ARP_GLOBAL.INIT_GLOBAL;
    ELSE
      if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Calling ARP_GLOBAL.INIT_GLOBAL with org_id :' || mo_global.get_current_org_id || ' as parameter');
      end if;
      ARP_GLOBAL.INIT_GLOBAL(mo_global.get_current_org_id);
    END IF;
    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	       fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Functional currency is: ' || arp_global.functional_currency);
    end if;

    IF (p_is_internal_user='Y') THEN

		IF ( p_site_use_id is null and p_customer_id is not null) THEN
			FOR account_assigned_site IN (
				select CUST_ACCT_SITE_ID from hz_cust_acct_sites where CUST_ACCOUNT_ID = p_customer_id
			)LOOP

              -- Bug 14486763 - To insert multiple bill to site use ids of a CUST_ACCT_SITE_ID
              insert_acct_site_uses(p_session_id => p_session_id, p_user_id => p_user_id, p_org_id => l_org_id, p_customer_id => p_customer_id, p_cust_acct_site_id => account_assigned_site.CUST_ACCT_SITE_ID);

			END LOOP;

		  ELSIF (( p_site_use_id is not null ) and (p_customer_id is not null)) THEN

            -- Bug 14486763 - To insert multiple bill to site use ids of a CUST_ACCT_SITE_ID
            insert_acct_site_uses(p_session_id => p_session_id, p_user_id => p_user_id, p_org_id => l_org_id, p_customer_id => p_customer_id, p_site_use_id => p_site_use_id);


		  END IF;
	  ELSE
		  IF ( p_site_use_id is null ) THEN

			/* insert all the sites this party is having direct access */

			FOR FETCH_SITES_ID_CURSOR_RECORD IN FETCH_SITES_ID_CURSOR loop

              -- Bug 14486763 - To insert multiple bill to site use ids of a CUST_ACCT_SITE_ID
              insert_acct_site_uses(p_session_id => p_session_id, p_user_id => p_user_id, p_org_id => l_org_id, p_customer_id => FETCH_SITES_ID_CURSOR_RECORD.account_id, p_cust_acct_site_id => FETCH_SITES_ID_CURSOR_RECORD.address_id);

			END LOOP;

			/* Check for account level access and insert all bill to sites */

			FOR customer_assigned_record IN (
				select cust_account_id from ar_customers_assigned_v where cust_account_id=nvl(p_customer_id,cust_account_id)
			)LOOP

				FOR account_assigned_site IN (
					select CUST_ACCT_SITE_ID from hz_cust_acct_sites where CUST_ACCOUNT_ID=customer_assigned_record.cust_account_id
				)LOOP
                  -- Bug 14486763 - To insert multiple bill to site use ids of a CUST_ACCT_SITE_ID
                  insert_acct_site_uses(p_session_id => p_session_id, p_user_id => p_user_id, p_org_id => l_org_id, p_customer_id => customer_assigned_record.cust_account_id, p_cust_acct_site_id => account_assigned_site.CUST_ACCT_SITE_ID);

				END LOOP;
			END LOOP;

		  ELSIF (( p_site_use_id is not null ) and (p_customer_id is not null)) THEN
             -- Bug 14486763 - To insert multiple bill to site use ids of a CUST_ACCT_SITE_ID
		     insert_acct_site_uses(p_session_id => p_session_id, p_user_id => p_user_id, p_org_id => l_org_id, p_customer_id => p_customer_id, p_site_use_id => p_site_use_id);

		  END IF;
	   END IF;
	------------------------------------------------


/* REMOVE DUPLICATE ROWS IF ANY */
DELETE FROM ar_irec_user_acct_sites_all A WHERE ROWID > (
     SELECT min(rowid) FROM ar_irec_user_acct_sites_all B
     WHERE A.org_id = B.org_id
     AND A.SESSION_ID=B.SESSION_ID
     AND A.USER_ID=B.USER_ID
     AND A.CUSTOMER_ID=B.CUSTOMER_ID
     AND A.CUSTOMER_SITE_USE_ID=B.CUSTOMER_SITE_USE_ID
     AND A.CREATION_DATE=B.CREATION_DATE
     );

commit;
END init_acct_sites_anon_login;

PROCEDURE update_account_sites ( p_customer_id in number,
		p_session_id in number,
		p_user_id in number ,
		p_org_id in number ,
		p_is_internal_user in varchar2
		)
	IS

	 l_curr_index   NUMBER;
         l_index        NUMBER := 0;
--	 p_customer_id  NUMBER;
	 p_site_use_id  NUMBER;
	 p_party_id	NUMBER;
	 l_procedure_name VARCHAR2(30) := 'update_account_sites';

	CURSOR FETCH_SITES_ID_CURSOR IS
		SELECT
		Sites_assigned.CUST_ACCOUNT_ID account_id , acct_sites.CUST_ACCT_SITE_ID address_id
		FROM
		hz_cust_acct_sites     acct_sites,
		hz_party_sites         party_sites,
		hz_cust_accounts       Cust,
		ar_sites_assigned_v    Sites_assigned
		WHERE Sites_assigned.party_id = p_party_id
		AND Sites_assigned.cust_account_id=nvl(p_customer_id,Sites_assigned.cust_account_id)
		AND cust.cust_account_id = Sites_assigned.cust_account_id
		AND Sites_assigned.cust_account_id = acct_sites.cust_account_id
		AND Sites_assigned.cust_acct_site_id = acct_sites.cust_acct_site_id
		AND ACCT_SITES.party_site_id     = PARTY_SITES.party_site_id;

pragma autonomous_transaction ;

BEGIN

if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
   fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'4. Calling arp_global.init_global');
   fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'org_id value is : ' || mo_global.get_current_org_id);
end if;
IF mo_global.get_current_org_id is null then
  if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
     fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Calling ARP_GLOBAL.INIT_GLOBAL without org_id as parameter');
  end if;
  ARP_GLOBAL.INIT_GLOBAL;
ELSE
  if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
     fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Calling ARP_GLOBAL.INIT_GLOBAL with org_id :' || mo_global.get_current_org_id || ' as parameter');
  end if;
  ARP_GLOBAL.INIT_GLOBAL(mo_global.get_current_org_id);
END IF;
if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
     fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME||l_procedure_name,'Functional currency is: ' || arp_global.functional_currency);
end if;
delete from ar_irec_user_acct_sites_all where session_id=p_session_id AND RELATED_CUSTOMER_FLAG = 'Y';

select person_party_id into p_party_id from fnd_user where user_id = p_user_id;

	  IF (p_is_internal_user='Y') THEN

		/* the following insert statement is added for bug 7678038  to show receipts created with out location */

  	     	INSERT INTO ar_irec_user_acct_sites_all
   		(SESSION_ID,CUSTOMER_ID,CUSTOMER_SITE_USE_ID,USER_ID,CURRENT_DATE,ORG_ID, CREATION_DATE,RELATED_CUSTOMER_FLAG)
     		VALUES(p_session_id,p_customer_id,'-1',p_user_id,sysdate,p_org_id, trunc(sysdate),'Y');

			FOR account_assigned_site IN (
				select CUST_ACCT_SITE_ID from hz_cust_acct_sites where CUST_ACCOUNT_ID = p_customer_id
			)LOOP
				IF ari_utilities.get_bill_to_site_use_id( account_assigned_site.CUST_ACCT_SITE_ID )>0 THEN
					INSERT INTO ar_irec_user_acct_sites_all
					(SESSION_ID,CUSTOMER_ID,CUSTOMER_SITE_USE_ID,USER_ID,CURRENT_DATE,ORG_ID, CREATION_DATE, RELATED_CUSTOMER_FLAG)
					VALUES(p_session_id,p_customer_id,ari_utilities.get_bill_to_site_use_id( account_assigned_site.CUST_ACCT_SITE_ID ),p_user_id,sysdate,p_org_id, trunc(sysdate), 'Y');
				END IF;
			END LOOP;

	  ELSE
			/* insert all the sites this party is having direct access */
			FOR FETCH_SITES_ID_CURSOR_RECORD IN FETCH_SITES_ID_CURSOR loop
			IF  FETCH_SITES_ID_CURSOR_RECORD.address_id IS NOT NULL
			AND ari_utilities.get_bill_to_site_use_id( FETCH_SITES_ID_CURSOR_RECORD.address_id ) > 0
			THEN
				INSERT INTO ar_irec_user_acct_sites_all
				(SESSION_ID,CUSTOMER_ID,CUSTOMER_SITE_USE_ID,USER_ID,CURRENT_DATE,ORG_ID, CREATION_DATE, RELATED_CUSTOMER_FLAG )
				VALUES(p_session_id,FETCH_SITES_ID_CURSOR_RECORD.account_id,ari_utilities.get_bill_to_site_use_id( FETCH_SITES_ID_CURSOR_RECORD.address_id ),p_user_id,sysdate,p_org_id, trunc(sysdate), 'Y');
			END IF;
			END LOOP;
			/* Check for account level access and insert all bill to sites */
			FOR account_assigned_site IN (
					select CUST_ACCT_SITE_ID from hz_cust_acct_sites where CUST_ACCOUNT_ID=p_customer_id
				)LOOP

					IF ari_utilities.get_bill_to_site_use_id( account_assigned_site.CUST_ACCT_SITE_ID )>0 THEN
						INSERT INTO ar_irec_user_acct_sites_all
						(SESSION_ID,CUSTOMER_ID, CUSTOMER_SITE_USE_ID,USER_ID,CURRENT_DATE,ORG_ID, CREATION_DATE, RELATED_CUSTOMER_FLAG)
						VALUES(p_session_id,p_customer_id,ari_utilities.get_bill_to_site_use_id( account_assigned_site.CUST_ACCT_SITE_ID ),p_user_id,sysdate,p_org_id, trunc(sysdate), 'Y');
					END IF;
			END LOOP;
		/* the following insert statement is added for bug 7678038  to show receipts created with out location */

  	     	INSERT INTO ar_irec_user_acct_sites_all
   		(SESSION_ID,CUSTOMER_ID,CUSTOMER_SITE_USE_ID,USER_ID,CURRENT_DATE,ORG_ID, CREATION_DATE,RELATED_CUSTOMER_FLAG)
     		VALUES(p_session_id,p_customer_id,'-1',p_user_id,sysdate,p_org_id, trunc(sysdate),'Y');

	   END IF;


/* REMOVE DUPLICATE ROWS IF ANY */
DELETE FROM ar_irec_user_acct_sites_all A WHERE ROWID > (
     SELECT min(rowid) FROM ar_irec_user_acct_sites_all B
     WHERE A.org_id = B.org_id
     AND A.SESSION_ID=B.SESSION_ID
     AND A.USER_ID=B.USER_ID
     AND A.CUSTOMER_ID=B.CUSTOMER_ID
     AND A.CUSTOMER_SITE_USE_ID=B.CUSTOMER_SITE_USE_ID
     AND A.CREATION_DATE=B.CREATION_DATE
     );

commit;

END update_account_sites;


END arw_search_customers;
/