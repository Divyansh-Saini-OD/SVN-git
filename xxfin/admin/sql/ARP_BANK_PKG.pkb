CREATE OR REPLACE PACKAGE BODY APPS.arp_bank_pkg AS
/* $Header: ARCUSBAB.pls 115.32.15104.13 2007/04/12 09:28:25 bsuri ship $*/

  /*-------------------------------------+
   |  WHO column values from FND_GLOBAL  |
   +-------------------------------------*/

  pg_user_id          varchar2(15);
  pg_login_id         number;
  pg_prog_appl_id     number;
  pg_program_id       number; /* J Rautiainen ACH Implementation */
  pg_request_id       number; /* J Rautiainen ACH Implementation */

  /*--------------------------------------+
   | other package level variables        |
   +--------------------------------------*/
  l_account_exists    number := 0;
  l_rowid            varchar2(18);
  l_inactive_date     date;
  CRLF                VARCHAR2(10):= arp_global.CRLF;
  pg_account_inserted VARCHAR2(1);
  pg_uses_inserted    VARCHAR2(1);
  PG_DEBUG varchar2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');

  /*---------------------------------------------------------------------+
   | Variables mainly created to convert the API as standar group API    |
   +---------------------------------------------------------------------*/
  G_PKG_NAME      CONSTANT VARCHAR2(30) := 'ARP_BANK_PKG';
  G_MSG_UERROR    CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR;
  G_MSG_ERROR     CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_ERROR;

FUNCTION format_cc_num(
    p_credit_card_num    IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE
  ) RETURN varchar2 IS

  TYPE numeric_tab_typ IS TABLE of number INDEX BY BINARY_INTEGER;
  TYPE character_tab_typ IS TABLE of char(1) INDEX BY BINARY_INTEGER;
  l_formatted_cc_num  varchar2(30);
  len_credit_card_num   number := 0;
  l_cc_num_char    character_tab_typ;
  j      number := 0;
  BEGIN
  --arp_util.debug('arp_bank_pkg.format_cc_num()+ ');

  SELECT lengthb(p_credit_card_num)
  INTO   len_credit_card_num
  FROM   dual;

  FOR i in 1..len_credit_card_num LOOP
     SELECT substrb(p_credit_card_num,i,1)
    INTO   l_cc_num_char(i)
    FROM   dual;

    IF ( (l_cc_num_char(i) >= '0') and
         (l_cc_num_char(i) <= '9') )
    THEN
      -- Numeric digit. Add to formatted_cc_num variable.
      j := j+1;
      if ( (mod(j-1,4) = 0) and (j > 1) )
      then
            -- Place a space after the 4th, 8th and 12th
                        -- digit of the credit card.
            l_formatted_cc_num  := l_formatted_cc_num || ' ';
      end if;
      l_formatted_cc_num := l_formatted_cc_num || l_cc_num_char(i);
    END IF;
  END LOOP;
  --arp_util.debug('arp_bank_pkg.format_cc_num()- ');

  return(l_formatted_cc_num);
  END format_cc_num;

  PROCEDURE strip_white_spaces(
  p_credit_card_num       IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
  p_stripped_cc_num  OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE
  ) IS

  TYPE character_tab_typ IS TABLE of char(1) INDEX BY BINARY_INTEGER;
  len_credit_card_num   number := 0;
  l_cc_num_char    character_tab_typ;
  BEGIN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('arp_bank_pkg.strip_white_spaces()+');
  END IF;

  SELECT lengthb(p_credit_card_num)
  INTO   len_credit_card_num
  FROM   dual;

  FOR i in 1..len_credit_card_num LOOP
     SELECT substrb(p_credit_card_num,i,1)
    INTO   l_cc_num_char(i)
    FROM   dual;

    IF ( (l_cc_num_char(i) >= '0') and
         (l_cc_num_char(i) <= '9')
       )
    THEN
        -- Numeric digit. Add to stripped_number and table.
        p_stripped_cc_num := p_stripped_cc_num || l_cc_num_char(i);
    END IF;
  END LOOP;

  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('arp_bank_pkg.strip_white_spaces()-');
  END IF;
  EXCEPTION
  WHEN OTHERS THEN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('Exception arp_bank_pkg.strip_white_spaces()-');
  END IF;
  RAISE;
  END strip_white_spaces;

/*====================================================================================+
 | PROCEDURE alloc_lock
 |
 | DESCRIPTION
 |    performs named locking
 |
 |
 | SCOPE - PRIVATE
 +------------------------------------------------------------------------------------*/
  PROCEDURE alloc_lock(p_lock_name VARCHAR2,x_lock_handle OUT NOCOPY VARCHAR2) IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   l_lock_status NUMBER;
  BEGIN
     IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('arp_bank_pkg.alloc_lock(+)');
      END IF;
      dbms_lock.allocate_unique(lockname        => p_lock_name,
                                   lockhandle      => x_lock_handle,
                                   expiration_secs => 1*24*60*60); -- 1 day.
     IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('arp_bank_pkg.alloc_lock(-)');
      END IF;
      COMMIT;
  EXCEPTION
   WHEN OTHERS THEN
    IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('EXCEPTION arp_bank_pkg.alloc_lock()');
    END IF;
    ROLLBACK;
    RAISE;
  END alloc_lock;

------------------------------------------
----Credit Card Encryption
------------------------------------------
/*Changed function for bug 5502540*/
FUNCTION mask_account_number
        ( p_account_number       IN VARCHAR2,
          p_bank_branch_id       IN NUMBER,
          p_called_from          IN VARCHAR2 DEFAULT 'NO_ARXCUDCI' ) RETURN VARCHAR2 IS

l_masked_account_num ap_bank_accounts.bank_account_num%type;

BEGIN

      --arp_util.debug('arp_bank_pkg.mask_account_number(+)');

 /*--------------------------------------------------------
 |  For Credit Cards call iPayment if Encryption is enabled|
 | For other Bank Accounts retain AR logic                 |
 ----------------------------------------------------------*/

 IF p_bank_branch_id = 1  THEN

  IF nvl(p_called_from,'NO_ARXCUDCI') <> 'ARXCUDCI' THEN  /*5502540*/
    ---Check if Credit Card Encryption is Enabled
    IF (IBY_CC_SECURITY_PUB.encryption_enabled = TRUE) THEN

       ---CAll iPayment API to mask it their way
       l_masked_account_num :=  IBY_CC_SECURITY_PUB.mask_card_number
                                (p_account_number);

       RETURN l_masked_account_num;

     ELSE --for encryption not enabled

       /*----------------------------------------------
       | Perform masking the way its done in iPayment |
       | With this logic the AR profile option        |
       | default_mask_account_profile is obsoleted    |
       -----------------------------------------------*/

       select lpad(substr(p_account_number,-4),length(p_account_number), 'X')
       into l_masked_account_num
       from dual;

       RETURN l_masked_account_num;


     END IF; --for encryption not enabled

/*Put for the call from ARXCUDCI-Customer Form bug 5502540*/
  ELSE
    IF (IBY_CC_SECURITY_PUB.encryption_enabled = TRUE)
        AND (FND_FUNCTION.TEST('IBY_UNMASK_SENSITIVE_DATA') = FALSE ) THEN /*5502540*/

       ---CAll iPayment API to mask it their way
       l_masked_account_num :=  IBY_CC_SECURITY_PUB.mask_card_number
                                (p_account_number);

       RETURN l_masked_account_num;


    ELSIF (IBY_CC_SECURITY_PUB.encryption_enabled = TRUE)
        AND (FND_FUNCTION.TEST('IBY_UNMASK_SENSITIVE_DATA') = TRUE ) THEN /*5502540*/

       l_masked_account_num :=  iby_creditcard_pkg.Get_Secured_Card_Number(p_account_number);
       RETURN l_masked_account_num;

    ELSE --for encryption not enabled

       IF (FND_FUNCTION.TEST('IBY_UNMASK_SENSITIVE_DATA') = TRUE ) THEN
         l_masked_account_num :=  p_account_number;
         RETURN l_masked_account_num;

       ELSE

       /*----------------------------------------------
       | Perform masking the way its done in iPayment |
       | With this logic the AR profile option        |
       | default_mask_account_profile is obsoleted    |
       -----------------------------------------------*/

         select lpad(substr(p_account_number,-4),length(p_account_number), 'X')
         into l_masked_account_num
         from dual;

         RETURN l_masked_account_num;
       END IF;


     END IF; --for encryption not enabled

  END IF;
/*End bug 5502540*/


  ELSE   ---for non credit card banks

   /*-----------------------------------------------------
   | Go By AR Profile option AR_MASK_BANK_ACCOUNT_NUMBERS|
   -----------------------------------------------------*/
    SELECT
    decode( nvl(fnd_profile.value('AR_MASK_BANK_ACCOUNT_NUMBERS'), 'F'),
                   'F', rpad(substr(p_account_number,1,4),
                             length(p_account_number), 'X'),
                   'L', lpad(substr(p_account_number,-4),
                             length(p_account_number), 'X'),
                   'N', p_account_number)
   into l_masked_account_num
   from dual;


   RETURN l_masked_account_num;

  END IF;

   -- arp_util.debug('arp_bank_pkg.mask_account_number(-)');

END MASK_ACCOUNT_NUMBER;



--------------------------------------------------------------
---Private Function get_hash1
--------------------------------------------------------------
FUNCTION get_hash1(p_bank_account_num in VARCHAR2) RETURN VARCHAR2
DETERMINISTIC IS

l_hash1 iby_security_segments.cc_number_hash1%TYPE;

BEGIN

  ---Call iPayment API to get hash1
 l_hash1 :=  IBY_SECURITY_PKG.get_hash(p_bank_account_num, FND_API.G_FALSE);

 RETURN l_hash1;

END get_hash1;

--------------------------------------------------------------
---Private Function get_hash2
--------------------------------------------------------------
FUNCTION get_hash2(p_bank_account_num in VARCHAR2) RETURN VARCHAR2
DETERMINISTIC IS

l_hash2 iby_security_segments.cc_number_hash1%TYPE;

BEGIN

  ---Call iPayment API to get hash2
 l_hash2 :=  IBY_SECURITY_PKG.get_hash(p_bank_account_num, FND_API.G_TRUE);

 RETURN l_hash2;

END get_hash2;

FUNCTION Get_cc_bank_act_id (
p_owner_party_id IN HZ_CUST_ACCOUNTS.party_id%TYPE,
p_customer_bank_account_num IN AP_BANK_ACCOUNTS.bank_account_num%TYPE)
RETURN NUMBER IS

l_customer_bank_account_id AP_BANK_ACCOUNTS.bank_account_id%TYPE;

BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_bank_pkg.Get_cc_bank_act_id(+)');
    END IF;

/*      SELECT  ba.bank_account_id
      INTO   l_customer_bank_account_id
      FROM  ap_bank_accounts ba, ap_bank_account_uses bau
      WHERE ba.bank_branch_id   = 1
      AND   ba.bank_account_num   = p_customer_bank_account_num
      AND   ba.account_type   = 'EXTERNAL'
      AND   ROWNUM = 1
      AND   bau.external_bank_account_id = ba.bank_account_id
      AND   nvl(bau.owning_party_id, -99) = p_owner_party_id;
*/
/* bug5493904 -- replaced the above sql -- since owning party_id is not there for records inserted from
    the customer WB */
       SELECT  ba.bank_account_id
       INTO   l_customer_bank_account_id
       FROM  ap_bank_accounts ba, ap_bank_account_uses bau,
             hz_cust_accounts hca,hz_parties party
       WHERE ba.bank_branch_id   = 1
       AND   ba.bank_account_num         =  p_customer_bank_account_num
       AND   ba.account_type     = 'EXTERNAL'
       AND   ROWNUM = 1
       AND   bau.external_bank_account_id = ba.bank_account_id
       AND   bau.customer_id = hca.cust_account_id
       AND   hca.party_id = party.party_id
       AND   party.party_id = p_owner_party_id;


 IF PG_DEBUG in ('Y', 'C') THEN
    arp_util.debug('Get_cc_bank_act_id: ' ||
      ' Found an existing bank account: '||
       to_char(l_customer_bank_account_id) );
 END IF;


 RETURN l_customer_bank_account_id;

 IF PG_DEBUG in ('Y', 'C') THEN
    arp_util.debug('arp_bank_pkg.Get_cc_bank_act_id(-)');
 END IF;

 EXCEPTION
 WHEN no_data_found THEN
 RETURN null;

END Get_cc_bank_act_id;
--------------------------------------------------------------
---Private Procedure to search for CC # in encrypted entries
--------------------------------------------------------------
PROCEDURE search_encrypted_entries(
   p_customer_bank_account_num IN VARCHAR2,
   p_cc_hash1                IN iby_security_segments.cc_number_hash1%TYPE,
   p_cc_hash2                IN iby_security_segments.cc_number_hash2%TYPE,
   p_owning_party_id         IN NUMBER,
   x_cc_no_matched OUT NOCOPY VARCHAR2,
   x_customer_bank_account_id         OUT NOCOPY NUMBER) IS

  l_cc_number_encrypted   AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE;
  l_cc_segment_id         iby_security_segments.sec_segment_id%TYPE;


  CURSOR c_get_cc_segment_id(x_cc_number_hash1 IN VARCHAR2,
                             x_cc_number_hash2 IN VARCHAR2) IS
  SELECT  sec_segment_id
  FROM   iby_security_segments iss
  where iss.cc_number_hash1 = x_cc_number_hash1
  AND   iss.cc_number_hash2 = x_cc_number_hash2 ;

BEGIN

 IF PG_DEBUG in ('Y', 'C') THEN
    arp_util.debug('arp_bank_pkg: ' ||
           'search_encrypted_entries(+)' );

    arp_util.debug('Searching using the hash entries...');
 END IF;



  -----------------------------------------------------------
  ---Get the secured_segment_id from the hash values
  -----------------------------------------------------------
  OPEN c_get_cc_segment_id(p_cc_hash1, p_cc_hash2);
  LOOP
       FETCH c_get_cc_segment_id into l_cc_segment_id;

             IF c_get_cc_segment_id%NOTFOUND THEN
                IF PG_DEBUG in ('Y', 'C') THEN
                  arp_util.debug('search_encrypted_entries: '||
                               ' Could not find record in '||
                               'iby_security_segments for hash values ');
                END IF;

                EXIT;
            END IF;



        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('search_encrypted_entries: ' ||
                          'Got segment_id for the card: '||
                          to_char(l_cc_segment_id));
        END IF;

       -------------------------------------------------------
       ---Get Encrypted Credit card no. from the segment_id
       -------------------------------------------------------
       l_cc_number_encrypted :=
              iby_cc_security_pub.get_secure_card_ref(
                                  l_cc_segment_id,
                                  p_customer_bank_account_num);


           IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('search_encrypted_entries: ' ||
                'Encrypted no for the input number based on hash values: '||
                l_cc_number_encrypted );

                 arp_util.debug('search_encrypted_entries: ' ||
                 'Finding bank_account_id with encrypted card no.');
           END IF;

           -------------------------------------------------------
           ---Find Bank account ID for multiple Encrypted Credit card no.
           -------------------------------------------------------
           x_customer_bank_account_id := get_cc_bank_act_id(
                    p_owner_party_id => p_owning_party_id,
                    p_customer_bank_account_num => l_cc_number_encrypted);

            IF  x_customer_bank_account_id is NOT NULL THEN

                x_cc_no_matched := l_cc_number_encrypted;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('search_encrypted_entries: '||
                   ' Found encrypted CC no. match for bank account ID: '
                   || x_customer_bank_account_id );

                END IF;

                exit;


           ELSE

              IF PG_DEBUG in ('Y', 'C') THEN

                 x_cc_no_matched := null;

                  arp_util.debug('search_encrypted_entries:: ' ||
                          'No_records_found for the given encrypted CC number'||
                          to_char(l_cc_number_encrypted) );

              END IF;


          END IF;

          END LOOP;
          CLOSE c_get_cc_segment_id;


 IF PG_DEBUG in ('Y', 'C') THEN
    arp_util.debug('arp_bank_pkg: ' ||
           'search_encrypted_entries(-)' );

 END IF;

END search_encrypted_entries;



-----------------------------------------------------------------------
---Credit Card Encryption
---This procedure is written for Credit Card Encryption uptake and
-- is called from this package and ar_receipt_lib_pvt
---Do not use it elsewhere.
----------------------------------------------------------------------
PROCEDURE default_cc_bank_id (
  p_customer_bank_account_num IN AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%type,
  p_customer_id     IN HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID%type DEFAULT NULL ,
  p_owning_party_id IN HZ_CUST_ACCOUNTS.PARTY_ID%type DEFAULT NULL,
  x_customer_bank_account_id OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%type,
  x_cc_no_matched OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%type)
IS


x_cc_number_hash1       iby_security_segments.cc_number_hash1%TYPE;
x_cc_number_hash2       iby_security_segments.cc_number_hash2%TYPE;
x_card_issuer           iby_cc_issuer_ranges.card_issuer_code%TYPE;
l_owner_party_id        hz_cust_accounts.party_id%TYPE;


BEGIN

  IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_bank_pkg.default_cc_bank_id(+) ' );
  END IF;

  x_cc_no_matched := null;

  -------------------------------------------------------
  ---Encryption NOT enabled but Input number is Encrypted
  ---is an Invalid combination
  -------------------------------------------------------
  IF (
       (IBY_CC_SECURITY_PUB.encryption_enabled = FALSE) AND
       (IBY_CC_SECURITY_PUB.card_number_secured
           (p_card_number => p_customer_bank_account_num) = TRUE  )
     ) THEN

       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT',
         'Error as Encryption is not enabled while input Credit Card number is encrypted.');
       FND_MSG_PUB.Add;
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;

  -----------------------------------------------------------
  --Get the owner_party_id for the Credit Card
  ---------------------------------------------------------
  IF p_owning_party_id IS NULL THEN

     BEGIN
        SELECT party.party_id
        INTO l_owner_party_id
        FROM hz_cust_accounts cust_acct,
             hz_parties party
        WHERE cust_acct.party_id = party.party_id
        AND cust_account_id = p_customer_id;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('default_cc_bank_id: ' ||
                    'There is no Party Id for Cust_account_id = ' ||
                    to_char(p_customer_id));
         END IF;

         FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
         FND_MESSAGE.SET_TOKEN('GENERIC_TEXT',
          'There is no Party Id for cust_account_id = '||
          to_char(p_customer_id));
         FND_MSG_PUB.Add;
         RAISE FND_API.G_EXC_ERROR;

        WHEN OTHERS THEN
          IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('default_cc_bank_id: '||
            ' Unknown error encountered while validating p_owning_party_id');
          END IF;
          FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
          FND_MESSAGE.SET_TOKEN('GENERIC_TEXT',
           'Error while fetching party_id for cust_acct_id = '||
            to_char(p_customer_id) ||SQLERRM);
          FND_MSG_PUB.Add;
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END;

  ELSE  --if p_owning_party_id is passed

     l_owner_party_id := p_owning_party_id;

 END IF;



  /*-------CREDIT CARD MATCHING LOGIC -------------------------

                 ----      Input Values  ----
     D/B
     Values      |  UE              |  En
     ------------|------------------|----------------------------
                 | CASE 1           | CASE 2
    UE           | Direct Comprn    | use function based index approach
                 |                  |
    -------------|------------------|----------------------------
                 |CASE 4            | CASE 3
     En          |IBY get_card_info | IBY get_card_info
                 |

   ---------------------------------------------------------------*/



  ---------------------------------------------------------------
  ---INPUT CARD IS UN-ENCRYPTED
  ---------------------------------------------------------------
 IF ( IBY_CC_SECURITY_PUB.card_number_secured
      (p_card_number => p_customer_bank_account_num) = FALSE
 ) THEN

      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('default_cc_bank_id: ' ||
         'Input Credit Card Number is Not Encrypted. ');

         arp_util.debug('Finding the card by direct comparision ' );

      END IF;

      ---------------------------------------------------------------
      --- CASE 1: Search in Unecrypted entries by direct comparision
      ---------------------------------------------------------------

     x_customer_bank_account_id := get_cc_bank_act_id(
         p_owner_party_id => l_owner_party_id,
         p_customer_bank_account_num => p_customer_bank_account_num);

      ----------------------------------------------------------------
      ---Match found
      ----------------------------------------------------------------
      IF x_customer_bank_account_id is not null then

          x_cc_no_matched := null;

          IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('default_cc_bank_id: ' ||
            'Got customer_bank_account_id by direct comparision: '||
             to_char(x_customer_bank_account_id) );
          END IF;

         RETURN;

      ELSE
       ---------------------------------------------------------------
        --- CASE 4: Search in Encrypted Entries
       ---------------------------------------------------------------

        x_cc_number_hash1 := arp_bank_pkg.get_hash1(p_customer_bank_account_num);
        x_cc_number_hash2 := arp_bank_pkg.get_hash2(p_customer_bank_account_num);

         IF PG_DEBUG in ('Y', 'C') THEN

           arp_util.debug('Did not find match by direct comparision.... ' ||
                          'Searching for unencrypted card in encrypted entries');

            arp_util.debug('default_cc_bank_id: ' ||
               'Got Hash values for the Un-encrypted card ');
         END IF;


         search_encrypted_entries(
           p_customer_bank_account_num => p_customer_bank_account_num,
           p_cc_hash1                  => x_cc_number_hash1,
           p_cc_hash2                  => x_cc_number_hash2,
           p_owning_party_id           => l_owner_party_id,
           x_cc_no_matched   => x_cc_no_matched,
           x_customer_bank_account_id  => x_customer_bank_account_id);

         ----------------------------------------------------------------
         ---Match found
         ----------------------------------------------------------------
         IF x_customer_bank_account_id is not null then

                 IF PG_DEBUG in ('Y', 'C') THEN

                   arp_util.debug('default_cc_bank_id: ' ||
                  'Found a bank account ID for the Unencrypted input card: '||
                   x_customer_bank_account_id );

                   arp_util.debug('Encrypted Card matched is: '||
                                  x_cc_no_matched);
                 END IF;

                 RETURN;

         ELSE

            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('default_cc_bank_id: ' ||
              'Could not find a bank account ID even in Encrypted entries.');
            END IF;

            x_cc_no_matched := null;

        END IF; ----x_customer_bank_account_id after first test

    END IF;  -----x_customer_bank_account_id after second  test

 END IF;  ---Un-Encrypted

 ---------------------------------------------------------------
 ---INPUT CARD IS ENCRYPTED
 ---------------------------------------------------------------
 IF ( IBY_CC_SECURITY_PUB.card_number_secured
      (p_card_number => p_customer_bank_account_num) = TRUE
 ) THEN

     IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('default_cc_bank_id: ' ||
        'Input card is Encrypted : '|| p_customer_bank_account_num);

        arp_util.debug('Finding a match in Un-encrypted entries');
     END IF;
     -----------------------------------------------------------
     ---Case 2 Search in Unencrypted entries
     -----------------------------------------------------------
     IBY_CC_SECURITY_PUB.get_card_info(
     p_credit_card => p_customer_bank_account_num,
     x_cc_number_hash1 => x_cc_number_hash1,
     x_cc_number_hash2 => x_cc_number_hash2 ,
     x_card_issuer => x_card_issuer );


     IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('default_cc_bank_id: ' ||
         'Got 2 hash values for the card ');
     END IF;

    BEGIN

     ---Check in the UnEncrypted values in the database
     SELECT ba.bank_account_id , ba.bank_account_num
     INTO   x_customer_bank_account_id , x_cc_no_matched
     FROM  ap_bank_accounts ba, ap_bank_account_uses bau
     WHERE ba.bank_branch_id   = 1
     AND   ba.account_type   = 'EXTERNAL'
     AND   substr(bank_account_num, length(bank_account_num) ,-4)
           = substr(p_customer_bank_account_num ,
                    length(p_customer_bank_account_num) , -4)
     AND   arp_bank_pkg.get_hash1(ba.bank_account_num)
           = x_cc_number_hash1
     AND   arp_bank_pkg.get_hash2(ba.bank_account_num)
           = x_cc_number_hash2
     AND   ROWNUM = 1
     AND   bau.external_bank_account_id = ba.bank_account_id
     AND   nvl(bau.owning_party_id, -99) = p_owning_party_id
     AND   SUBSTRB(ba.bank_account_num, 1,1)<>'9'
     AND   LENGTH(ba.bank_account_num)<>25;


   EXCEPTION
   WHEN NO_DATA_FOUND THEN

     IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('default_cc_bank_id: ' ||
             'Could not find a bank account ID for Encrypted card ' ||
             'in Unencrypted entries. Trying in Encrypted entries..');
     END IF;
     x_customer_bank_account_id := null;

   END;

  ----------------------------------------------------------------
  ---Match found
  ----------------------------------------------------------------
  IF x_customer_bank_account_id is not null THEN

      IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('default_cc_bank_id: ' ||
        'Got bank_account_id for Encrypted card ' ||
        ' in Un-encrypted entries : '||
         to_char(x_customer_bank_account_id) );
      END IF;

      RETURN;

  ELSE
      -----------------------------------------------------------
      ---Case 3 Search in Encrypted entries
      -----------------------------------------------------------
      search_encrypted_entries(
      p_customer_bank_account_num => p_customer_bank_account_num,
      p_cc_hash1                  => x_cc_number_hash1,
      p_cc_hash2                  => x_cc_number_hash2,
      p_owning_party_id           => l_owner_party_id,
      x_cc_no_matched   => x_cc_no_matched,
      x_customer_bank_account_id  => x_customer_bank_account_id);


      IF x_customer_bank_account_id is not null THEN

        IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('default_cc_bank_id: ' ||
         'Found a bank account ID for the Encrypted input card in '||
          'Encrypted entries: '|| x_customer_bank_account_id );

          arp_util.debug('Encrypted Card matched is: '||
                         x_cc_no_matched);
        END IF;

        RETURN;

     ELSE

       IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('default_cc_bank_id: ' ||
        'Could not find a bank account ID for Encrypted input card '||
         ' in the Encrypted entries.');
       END IF;

       x_cc_no_matched := null;

     END IF; --x_customer_bank_account_id after first test

   END IF;    ---x_customer_bank_account_id after second test

 END IF;  --input card is encrypted

---------------------------------------------------------------
 --- If still can not find bank_account_id
---------------------------------------------------------------
 IF x_customer_bank_account_id is null THEN

    IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('Could not default CC bank acct_id');
    END IF;

    NULL;
 END IF;


IF PG_DEBUG in ('Y', 'C') THEN
  arp_util.debug('arp_bank_pkg.default_cc_bank_id(-) ' );
 END IF;

EXCEPTION
WHEN NO_DATA_FOUND THEN

 IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_bank_pkg.default_cc_bank_id:  '||
                     'Could not find an existing  bank account ID.' );
      x_customer_bank_account_id := null;
 END IF;
END   default_cc_bank_id ;




/*===================================================================================================================+
 | PROCEDURE process_cust_bank_account
 |
 | DESCRIPTION
 |    Group API to process Credit Card and ACH customer bank accounts
 |
 |
 | SCOPE - PUBLIC
 |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED
 |    arp_util.debug
 |
 |
 |Standard API Input output parameter:
 |
 |Parameters         Type   Data-type     Required    Default Value     Description
 |p_api_version      IN     NUMBER         Yes                          Used to compare version numbers of
 |                                                                      incoming calls to its current version number.
 |                                                                      Unexpected error is raised if version
 |                                                                      in-compatibility exists.In the current
 |                                                                      version of the API,you should pass in a value
 |                                                                      of 1.0 for this parameter.
 |
 |p_init_msg_list    IN     VARCHAR2                 FND_API.G_FALSE    Allows API callers to request that
 |                                                                      the API does initialization of the
 |                                                                      message list on their behalf.
 |
 |p_commit           IN     VARCHAR2                 FND_API.G_FALSE    Used by API callers to ask the API to
 |                                                                      commit on their behalf.
 |
 |p_validation_level IN     NUMBER          FND_API.G_VALID_LEVEL_FULL  Level of validation.
 |
 |x_return_status    OUT    VARCHAR2                                    Represents the API overall return status.
 |                                                                      These are possible output values for this
 |                                                                      parameter
 |                                                                      Success - FND_API. G_RET_STS_SUCCESS
 |                                                                      Error - FND_API. G_RET_STS_ERROR
 |                                                                      Unexpected error - FND_API. G_RET_STS_UNEXP_ERROR
 |
 |x_msg_count        OUT    NUMBER                                      Number of messages in the API message list
 |
 |x_msg_data         OUT    VARCHAR2                                    This is the message in encoded format
 |                                                                      if x_msg_count=1
 |
 |arp_bank_pkg.process_cust_bank_account parameters :
 |
 |Parameters           Type   Data-type     Required    Default Value     Description
 |p_org_id              IN     NUMBER        Yes                          Indentifies Organization from which API
 |                                                                        is being called
 |p_trx_date            IN     DATE          Yes                          Date of the transaction
 |p_currency_code       IN     VARCHAR2      Yes                          Currecy_code Currency in which transaction
 |                                                                        will happen
 |p_cust_id             IN     NUMBER        Yes                          Identifies ct for which bank acct needs
 |                                                                        to be updated or created
 |p_site_use_id         IN     NUMBER                     NULL            Identifies site
 |p_credit_card_num     IN     VARCHAR2      Yes                          Bank account number
 |p_acct_name           IN     VARCHAR2      Yes                          Bank account name
 |p_exp_date            IN     DATE          Yes                          Inactive date
 |p_owning_party_id     IN     NUMBER                     NULL            Owning Party of a Credit Card Bank Account
 |p_bank_branch_id      IN     NUMBER                     NULL            Bank branch identifier
 |p_account_type        IN     VARCHAR2                   NULL            Bank account type code
 |p_payment_instrument  IN     VARCHAR2                  CREDIT_CARD      Can be BANK_ACCOUNT for ACH and CREDIT_CARD
 |                                                                        for Credit Card
 |x_bank_account_id     OUT    NUMBER                                     Bank_account_id of the newly created or
 |                                                                        already existing bank account
 |                                                                        for the given set of input parameters
 |x_bank_account_uses_id OUT    NUMBER                                    Bank_account_uses_id of the newly created
 |                                                                        or already existing bank uses record
 |
 |
 | MODIFICATION HISTORY
 |    15-Sep-2004   Srinivasa Kini       Re-written
 |    13-SEP-2005   Jyoti Pandey         Bug  4604999 CC Encryption uptake
 |
 +==================================================================================================================*/

  PROCEDURE process_cust_bank_account(
           -- Standard API parameters.
                 p_api_version        IN  NUMBER,
                 p_init_msg_list      IN  VARCHAR2 := FND_API.G_FALSE,
                 p_commit             IN  VARCHAR2 := FND_API.G_FALSE,
                 p_validation_level   IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
                 x_return_status      OUT NOCOPY VARCHAR2,
                 x_msg_count          OUT NOCOPY NUMBER,
                 x_msg_data           OUT NOCOPY VARCHAR2,
           -- Current API specific parameters
                 p_org_id             IN AP_BANK_ACCOUNT_USES.ORG_ID%TYPE,
           p_trx_date        IN  DATE,
           p_currency_code      IN  AP_BANK_ACCOUNTS.CURRENCY_CODE%TYPE,
           p_cust_id        IN  AP_BANK_ACCOUNT_USES.CUSTOMER_ID%TYPE,
           p_site_use_id         IN  AP_BANK_ACCOUNT_USES.CUSTOMER_SITE_USE_ID%TYPE DEFAULT NULL,
           p_credit_card_num    IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
           p_acct_name          IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NAME%TYPE,
           p_exp_date        IN  AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE,
                 p_owning_party_id    IN NUMBER DEFAULT NULL,
           p_bank_branch_id     IN AP_BANK_ACCOUNTS.BANK_BRANCH_ID%TYPE DEFAULT NULL, /*Added for ACH */
                 p_account_type       IN  VARCHAR2 DEFAULT NULL,           /* Added for ACH */
                 p_payment_instrument IN  VARCHAR2 DEFAULT 'CREDIT_CARD', /* Added for ACH */
           x_bank_account_id    OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE,
           x_bank_account_uses_id  OUT NOCOPY AP_BANK_ACCOUNT_USES.BANK_ACCOUNT_USES_ID%TYPE
  ) IS
  l_inactive_date     AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE;
  l_external_bank_account_id  AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE;
  l_acct_name                   AP_BANK_ACCOUNTS.BANK_ACCOUNT_NAME%TYPE; -- Bug 5762937
  l_bank_account_uses_id   AP_BANK_ACCOUNT_USES.BANK_ACCOUNT_USES_ID%TYPE;
  l_type      varchar2(4);  /* 'CUST' or 'SITE' */
  l_id        number(15);  /* customer or site-use-id */
  l_ba_ins_flag      boolean := FALSE;  /* Insert bank_acct record */
  l_bau_ins_flag    boolean := TRUE; /* Insrt bank_acct_uses flag */
  l_primary_flag    varchar2(1); /* Bnk_acct_uses prmry flg rtrnd */
  l_upd_primary_flag    varchar2(1) := 'N'; /*Updt bnk_acct_uses prflg*/
  l_rowid      varchar2(100);
  l_cc_valid      number := 1;
  l_cc_num_stripped    AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE;
  l_bank_branch_id     AP_BANK_BRANCHES.bank_branch_id%TYPE := 1;
  l_party_id                    HZ_PARTIES.PARTY_ID%TYPE;
  l_dummy       NUMBER;
  l_lock_name                   VARCHAR2(400);
  l_lock_handle                 VARCHAR2(100);
  l_lock_name_uses              VARCHAR2(400);
  l_lock_handle_uses            VARCHAR2(100);
  l_lock_status                 NUMBER;
  l_lock_status_uses            NUMBER;
  lock_exist                    VARCHAR2(1) := 'N';
  uses_lock_exist               VARCHAR2(1) := 'N';
  l_org_id     AP_BANK_ACCOUNT_USES.ORG_ID%TYPE;
  l_orig_org_id AP_BANK_ACCOUNT_USES.ORG_ID%TYPE;
  l_api_name       CONSTANT VARCHAR2(50) := 'Process_cust_Bank_Account';
  l_api_version    CONSTANT NUMBER       := 1.0;

 l_cc_no_matched AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE := null;

  BEGIN
      /*------------------------------------+
       |   Standard start of API savepoint  |
       +------------------------------------*/

       SAVEPOINT BANK_SAVE_PT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;

       /*-----------------------------------------------------------+
        |  Get the original org_id                                  |
        +-----------------------------------------------------------*/

         l_orig_org_id := fnd_profile.value( 'ORG_ID');

       /*-------------------------------------------------+
        | Initialize SOB/org dependent variables          |
        +-------------------------------------------------*/
        fnd_client_info.set_org_context(p_org_id);
        arp_standard.init_standard;
        arp_global.init_global;
        l_org_id:=arp_global.sysparam.org_id;

  IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('arp_bank_pkg.process_cust_bank_account()+');
  END IF;

       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;

       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

        IF (p_payment_instrument = 'CREDIT_CARD') THEN
          strip_white_spaces ( p_credit_card_num, l_cc_num_stripped );
        ELSE  /* ACH */
          l_cc_num_stripped := p_credit_card_num;
        END IF;

  /*--------------------------------------------------------------------------+
   | Intialize the lock release variables                                     |
   | Idea is if any insert has happened either for accounts or account_uses   |
   | we are going to retain the named locks..Eventually these locks will get  |
   | released on commit or rollback                                           |
   +--------------------------------------------------------------------------*/
   pg_account_inserted := 'N';
   pg_uses_inserted    := 'N';

        /*--------------------------------------------------------------------+
         | Validate owning_party_id                                           |
   | If it's passed as null populate it with party_id of cust_accounts  |
   +--------------------------------------------------------------------*/
         IF (p_owning_party_id IS NULL) THEN
           BEGIN
             SELECT party.party_id
             INTO l_party_id
             FROM hz_cust_accounts cust_acct,
                  hz_parties party
             WHERE cust_acct.party_id = party.party_id
             AND cust_account_id = p_cust_id;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('process_cust_bank_account: ' ||
                                  'There is no Party Id for Cust_account_id = ' || to_char(p_cust_id));
                END IF;
                FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','There is no Party Id for cust_account_id = '|| to_char(p_cust_id));
          FND_MSG_PUB.Add;
                RAISE FND_API.G_EXC_ERROR;
              WHEN OTHERS THEN
                IF PG_DEBUG in ('Y', 'C') THEN
                  arp_util.debug('process_cust_bank_account:  Unknown error encountered while validating p_owning_party_id');
                END IF;
                FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Error while fetching party_id for cust_acct_id = '|| to_char(p_cust_id) ||SQLERRM);
          FND_MSG_PUB.Add;
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END;
         ELSE
           -- make sure that the owning party_id passed to the api is valid
           l_party_id := p_owning_party_id;
           BEGIN
             SELECT 1
             INTO l_dummy
             FROM dual
             WHERE EXISTS ( SELECT 1 FROM hz_parties
                            WHERE party_id = p_owning_party_id);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                IF PG_DEBUG in ('Y', 'C') THEN
                  arp_util.debug('process_cust_bank_account: ' || 'Input parameter, owning party_id is invalid');
                END IF;
                FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Input parameter owning party_id is invalid'||to_char(p_owning_party_id));
          FND_MSG_PUB.Add;
                RAISE FND_API.G_EXC_ERROR;
        WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END;
         END IF;

       /*---------------------------------------------------------+
        | Do a named locking so, no other operation would be      |
        | performed on the same bank account from other session . |
  | For a ACH uniqueness is based on l_cc_num_stripped and  |
  | p_bank_branch_id. But for Credit Card uniqueness is     |
  | based on l_cc_num_stripped and l_party_id.              |
  | Do the locking accordingly.                             |
        +---------------------------------------------------------*/
  /* bug5303140 -- changed timeout to zero */
        BEGIN
     l_lock_name := 'AR.BANK_PKG.ACCOUNTS.'||l_cc_num_stripped;
   IF p_payment_instrument = 'CREDIT_CARD' THEN
     l_lock_name := l_lock_name || to_char(l_party_id);
   ELSE /*Case of ACH */
     l_lock_name := l_lock_name || to_char(p_bank_branch_id);
   END IF;
         alloc_lock(l_lock_name,l_lock_handle);
         l_lock_status := dbms_lock.request(lockhandle   => l_lock_handle,
                                            lockmode          => dbms_lock.x_mode,
                                            timeout           => 0,
                                            release_on_commit => TRUE);
          IF (l_lock_status <> 0) THEN
      IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('Error while named locking 1: Lock status :'||to_char(l_lock_status));
      END IF;
      lock_exist := 'Y';
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

        EXCEPTION
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','arp_bank_pkg.process_cust_bank_account named locking: '||SQLERRM);
      FND_MSG_PUB.Add;
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END;

       /*----------------------------------------------------------+
        |   In case of credit card the bank branch id equals to 1, |
        |   for bank account (ACH) use the bank branch id passed   |
  |   in as parameter.                                       |
        +----------------------------------------------------------*/

        IF (p_payment_instrument = 'BANK_ACCOUNT') THEN

          BEGIN
            l_bank_branch_id := p_bank_branch_id;

            SELECT  ba.bank_account_id,
                    ba.bank_account_num,
                    ba.inactive_date
            INTO    l_external_bank_account_id,
                    l_cc_num_stripped,
                    l_inactive_date
            FROM  ap_bank_accounts ba
            WHERE ba.bank_branch_id   = p_bank_branch_id
            AND   ba.bank_account_num   = l_cc_num_stripped
            AND   ba.account_type   = 'EXTERNAL'
            AND   ROWNUM = 1;

          EXCEPTION
            when NO_DATA_FOUND then
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('process_cust_bank_account: ' || '3: select 1: no_records_found');
              END IF;
              l_ba_ins_flag := TRUE;
            WHEN OTHERS then
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('process_cust_bank_account: ' || '1: when others error raised');
              END IF;
        FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
        FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','while checking for uniqueness : '||SQLERRM);
        FND_MSG_PUB.Add;
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END;
        ELSE /* Credit Card */

        ------------------------------------------------------------------
        --Bug  4604999 CC Encryption Duplicate Check logic for Credit Cards
        ------------------------------------------------------------------
         IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('process_cust_bank_account: ' ||
              'Calling new logic for CC encryption for finding matches....  ');
         END IF;

               default_cc_bank_id
                (
                 p_customer_bank_account_num => l_cc_num_stripped,
                 p_customer_id => p_cust_id,
                 p_owning_party_id => l_party_id,
                 x_customer_bank_account_id => l_external_bank_account_id,
                 x_cc_no_matched => l_cc_no_matched);

        IF l_external_bank_account_id is null THEN

            l_ba_ins_flag := TRUE;

            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('process_cust_bank_account: ' ||
              'Search for a bank account ID with same CC No. did not find results.  ');
            END IF;

        ELSE

            l_ba_ins_flag := FALSE;

            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('process_cust_bank_account: ' ||
               'Search for a bank account ID with same CC No. '||
               ' Found an existing bank_account_id: '||
               to_char(l_external_bank_account_id));
              END IF;
        END IF;

        ------------------------------------------------------------------
        --Bug  4604999 CC Encryption ends here
        ------------------------------------------------------------------

    END IF;

    -- Added below fix as per required in Bug 5762937
/* PCC 5410970 for bug -- bug5345117 -- for getting the p_acct_name -- start*/

if p_acct_name is not null THEN

   l_acct_name := p_acct_name;

end if;


if p_acct_name is null THEN

    IF (l_ba_ins_flag = TRUE) THEN

                   select substrb(party.party_name,1,80)
                   into   l_acct_name
                   from   hz_cust_accounts cust_acct,
                          hz_parties party
                   where  cust_acct.party_id = party.party_id
                   and    cust_account_id = p_cust_id;

    END IF;

    IF (l_ba_ins_flag = FALSE) THEN

                select bank_account_name
                into   l_acct_name
                from   ap_bank_accounts_all
                where  bank_account_id = l_external_bank_account_id;

    END IF;

end if;

            arp_util.debug('the value of l_acct_name '|| l_acct_name);

/*  PCC 5410970  -- bug5345117 -- for getting the p_acct_name -- end*/


  IF (l_ba_ins_flag = TRUE) THEN
           IF (rtrim(p_credit_card_num) is null) THEN
             IF (p_payment_instrument = 'BANK_ACCOUNT') THEN
               FND_MESSAGE.SET_NAME('AR','AR_INVALID_BANK_ACCOUNT_DATA');
               FND_MSG_PUB.Add;
             ELSE /* Credit Card type */
               FND_MESSAGE.SET_NAME('AR','AR_TW_INVALID_CREDIT_CARD_DATA');
               FND_MSG_PUB.Add;
             END IF;
       RAISE FND_API.G_EXC_ERROR;
           END IF;
          /*--------------------------------------------------------------+
           |   Account Number Validation only done for credit cards.      |
           |   CAll val_credit_card_from_ipay that calls iPay API to      |
           |   validate. API conditionally validates based on check digits|
           +-------------------------------------------------------------*/


           IF (p_payment_instrument <> 'BANK_ACCOUNT' AND
               val_credit_card_from_ipay(l_cc_num_stripped,
                                         p_exp_date) = FALSE
              ) THEN

       -- invalid cc_num. set error message and exit.
             FND_MESSAGE.SET_NAME('AR','AR_TW_INVALID_CREDIT_CARD_DATA');
             FND_MSG_PUB.Add;
             RAISE FND_API.G_EXC_ERROR;
     END IF;

           IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('calling insert_bank_account');
           END IF;

           -- insert into ap_bank_accounts table
     insert_bank_account(
    l_acct_name -- Bug 5762937
    ,l_cc_num_stripped
    ,l_bank_branch_id
    ,p_currency_code
    ,p_exp_date
                ,p_account_type /*ACH Implementation */
    ,l_external_bank_account_id
    ,l_org_id
    );
  ELSE  /* l_ba_ins_flag = FALSE */
          IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('6.1: Updating ap_bank_account with expiration date.');
          END IF;

         IF (trunc(p_exp_date) >= trunc(sysdate)) THEN

             ---CC Encryption
             IF  l_cc_no_matched is not null then
                 l_cc_num_stripped  := l_cc_no_matched;

                 IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('process_cust_bank_account: ' ||
                    'Passing encrypted Credit card to update_bank_account: '
                    || l_cc_num_stripped);
                 END IF;

            END IF;


      arp_bank_pkg.update_bank_account
        (
        l_acct_name, -- Bug 5762937
          l_cc_num_stripped,
          p_currency_code,
          p_exp_date,
          l_external_bank_account_id,
          l_bank_branch_id,
        l_org_id);
    END IF;
  END IF;

  /*------------------------------------------------------------------+
   | If primary bank_account_uses record exists, return to calling    |
   | env.Else add to ap_bank_account_uses.                            |
   +------------------------------------------------------------------*/
         IF ( p_site_use_id is null ) THEN
    l_type := 'CUST';
    l_id   := p_cust_id;
         ELSE
    l_type := 'SITE';
    l_id   := p_site_use_id;
         END IF;
        --
  BEGIN
         /*---------------------------------------------------------+
          | Do a named locking so, no other operation would be      |
          | performed on the same bank account from other session   |
          +---------------------------------------------------------*/
    /* bug5303140 -- changed timeout to zero */
          BEGIN
        l_lock_name_uses := 'AR.BANK_PKG.ACCOUNTS.'||to_char(l_external_bank_account_id)||
                                   l_type||to_char(l_id)||to_char(l_party_id);
            alloc_lock(l_lock_name_uses,l_lock_handle_uses);
            l_lock_status_uses := dbms_lock.request(lockhandle   => l_lock_handle_uses,
                                            lockmode          => dbms_lock.x_mode,
                                            timeout           => 0,
                                            release_on_commit => TRUE);
         /* bug5303140 */
         /*---------------------------------------------------------+
          | excluded the status 4 since it is the case where the    |
          | the user tries to acquire his own lock.                 |
          +---------------------------------------------------------*/
           IF (l_lock_status_uses <> 0) THEN
             IF (l_lock_status_uses = 4) THEN
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('Error while named locking on uses : Lock status :'||to_char(l_lock_status_uses));
           END IF;
              uses_lock_exist := 'N';
             ELSE
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('Error while named locking on uses : Lock status :'||to_char(l_lock_status_uses));
           END IF;
                 uses_lock_exist := 'Y';
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
             END IF;
     END IF;
          EXCEPTION
      WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
        FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','arp_bank_pkg.process_cust_bank_account named locking for ap_bank_account_uses: '||SQLERRM);
        FND_MSG_PUB.Add;
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
     END;

     -- Once the lock is obtained then proceed
     l_bank_account_uses_id := 0;
     check_unique(l_bank_account_uses_id,l_external_bank_account_id,sysdate,NULL,l_type,l_id,l_primary_flag, l_party_id,x_return_status);
     IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      IF x_return_status = FND_API.G_RET_STS_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
      ELSE
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;
     END IF;
           IF (l_bank_account_uses_id <> 0) THEN
        l_bau_ins_flag := FALSE;
        IF (l_primary_flag = 'Y') THEN
    l_upd_primary_flag := 'N';
        END IF;
      END IF;

       IF ( (l_bau_ins_flag = FALSE) and (l_upd_primary_flag = 'N') ) THEN
       NULL;
       arp_util.debug('8: After check unique : l_bau_ins_flag is null,l_upd_primary_flag = N');
      ELSE
        /*----------------------------------------------------------------------+
         |Check if there is any record with primary flag for the same date range|
         +----------------------------------------------------------------------*/
               check_primary(NULL,l_external_bank_account_id,sysdate, NULL,l_type,l_id,l_primary_flag,x_return_status);
               IF (l_primary_flag = 'Y') THEN
     l_upd_primary_flag := 'N';
         ELSE
     l_upd_primary_flag := 'Y';
         END IF;
         IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
           IF x_return_status = FND_API.G_RET_STS_ERROR THEN
             RAISE FND_API.G_EXC_ERROR;
           ELSE
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END IF;
         END IF;
      END IF;

            -- Do the insert or update
            IF (l_bau_ins_flag = TRUE) THEN
             /*--------------------------------------------------------------+
        |Check to see if any records exist in ap_bank_account_uses_all |
        |for this combination in any org. If it exists in another org, |
        |then populate org_id with the current value otherwise set     |
        |org_id to null -- BUG 1621932                                 |
        +--------------------------------------------------------------*/

              IF (l_type = 'CUST') THEN
                DECLARE
                   l_dummy NUMBER;
                BEGIN
                   SELECT 1
                   INTO l_dummy
                   FROM dual
                   WHERE EXISTS
                   ( SELECT 1 FROM
                              ap_bank_account_uses_all
                      WHERE customer_id = l_id
                      AND   customer_site_use_id IS null
                      AND   external_bank_account_id =  l_external_bank_account_id
                      AND org_id IS NOT NULL
                      AND owning_party_id = l_party_id );
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                       l_org_id := NULL;
                END;
              ELSE
    DECLARE
                   l_dummy NUMBER;
                BEGIN
                   SELECT 1
                   INTO l_dummy
                   FROM dual
                   WHERE EXISTS
                   ( SELECT 1 FROM
                               ap_bank_account_uses_all
                     WHERE  customer_site_use_id = l_id
                     AND   external_bank_account_id =  l_external_bank_account_id
                     AND org_id IS NOT NULL
                     AND owning_party_id = l_party_id
                    );
                 EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      l_org_id := NULL;
                END;
              END IF;

              -- Insert a new record
               SELECT ap_bank_account_uses_s.nextval
        INTO l_bank_account_uses_id
        FROM dual;

        IF PG_DEBUG in ('Y', 'C') THEN
    arp_util.debug('11: Inserting apbau record. bau_id = '||l_bank_account_uses_id);
              END IF;

        INSERT INTO AP_BANK_ACCOUNT_USES(
          bank_account_uses_id,
                last_update_date,
          last_updated_by,
          creation_date,
          created_by,
          last_update_login,
          customer_id,
          customer_site_use_id,
          external_bank_account_id,
          start_date,
          end_date,
          primary_flag,
                      owning_party_id,
                      org_id
       )
       VALUES
       (l_bank_account_uses_id,
        sysdate,
        pg_user_id,
        sysdate,
        pg_user_id,
        pg_login_id,
        p_cust_id,
        p_site_use_id,
        l_external_bank_account_id,
        trunc(least(p_trx_date,sysdate)),
        NULL,
        l_upd_primary_flag,
                    l_party_id,
                    l_org_id);

              pg_uses_inserted := 'Y';

              ELSIF (l_upd_primary_flag = 'Y') THEN
        -- Update record with only the primary flag.
                 UPDATE AP_BANK_ACCOUNT_USES SET
                         last_update_date                =     sysdate,
             last_updated_by                 =     pg_user_id,
             last_update_login               =     pg_login_id,
             customer_id                     =     p_cust_id,
             customer_site_use_id            =     p_site_use_id,
             external_bank_account_id        =     l_external_bank_account_id,
             start_date                      =     trunc(sysdate),
             end_date                        =     NULL,
             primary_flag                    =     'Y'
           WHERE bank_account_uses_id = l_bank_account_uses_id;
        END IF;
  END;

        x_bank_account_id := l_external_bank_account_id;
  x_bank_account_uses_id := l_bank_account_uses_id;

      /*-------------------------------------------------------------------+
       | Release  the named locking if there was no any insert in this API.|
       | If there was any then named lockings will get released upon       |
       | commit/rollback                                                   |
       +-------------------------------------------------------------------*/
       IF pg_account_inserted <> 'Y' THEN
         l_lock_status := dbms_lock.release(lockhandle => l_lock_handle);
         IF (l_lock_status <> 0) THEN
           IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_bank_pkg.process_cust_bank_account, accounts Lock release error: Lock Status'||to_char(l_lock_status));
     END IF;
     RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;
   lock_exist := 'N';
       END IF;
       IF pg_uses_inserted <> 'Y' THEN
         l_lock_status_uses := dbms_lock.release(lockhandle => l_lock_handle_uses);
         IF (l_lock_status <> 0) THEN
           IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_bank_pkg.process_cust_bank_account, uses Lock release error : Lock Status '||to_char(l_lock_status_uses));
     END IF;
     RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;
   uses_lock_exist := 'N';
       END IF;

      /*----------------------------------------+
       | Restore back the original contexts     |
       +----------------------------------------*/
        fnd_client_info.set_org_context(l_orig_org_id);
        arp_standard.init_standard;
        arp_global.init_global;

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug(  'committing');
            END IF;
            Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('arp_bank_pkg.process_cust_bank_account()-');
        END IF;

      /*-------------------------------------------------------------------+
       | Named locking will be released only on complete rollback.         |
       | Partial rollback, won't cause locks to be released                |
       +-------------------------------------------------------------------*/
       /* bug5303140 */
  EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN
         IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('EXCEPTION : arp_bank_pkg.process_cust_bank_account()-');
           arp_util.debug(SQLCODE, G_MSG_ERROR);
           arp_util.debug(SQLERRM, G_MSG_ERROR);
         END IF;
   IF lock_exist = 'Y' THEN
     l_lock_status := dbms_lock.release(lockhandle => l_lock_handle);
      IF l_lock_status <> 0 THEN
       arp_util.debug('Error while releasing the lock at final exception : Lock Status '||to_char(l_lock_status));
            END IF;
   END IF;
   IF uses_lock_exist = 'Y' THEN
     l_lock_status_uses := dbms_lock.release(lockhandle => l_lock_handle_uses);
     IF l_lock_status_uses <> 0 THEN
       arp_util.debug('Error while releasing the lock at final exception : Lock Status uses '||to_char(l_lock_status_uses));
           END IF;
   END IF;
   /* bug5303140 -code removed*/
   /*IF l_lock_status <> 0 OR l_lock_status_uses <> 0 THEN
           IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('Error while releasing the lock at final exception : Lock Status '||to_char(l_lock_status)||'Lock uses status  '||to_char(l_lock_status_uses));
     END IF;
   END IF;*/
         ROLLBACK TO BANK_SAVE_PT;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         --  Display_Parameters;
         FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                   p_count       =>      x_msg_count,
                                   p_data        =>      x_msg_data
                                  );
       WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('EXCEPTION : arp_bank_pkg.process_cust_bank_account()-');
     arp_util.debug(SQLCODE, G_MSG_ERROR);
           arp_util.debug(SQLERRM, G_MSG_ERROR);
         END IF;
   IF lock_exist = 'Y' THEN
     l_lock_status := dbms_lock.release(lockhandle => l_lock_handle);
     /* bug5303140*/
      IF l_lock_status <> 0 THEN
       arp_util.debug('Error while releasing the lock at final exception : Lock Status '||to_char(l_lock_status));
            END IF;
   END IF;
   IF uses_lock_exist = 'Y' THEN
     l_lock_status_uses := dbms_lock.release(lockhandle => l_lock_handle_uses);
          /* bug5303140*/
     IF l_lock_status_uses <> 0 THEN
       arp_util.debug('Error while releasing the lock at final exception : Lock Status uses '||to_char(l_lock_status_uses));
           END IF;
   END IF;
   /* bug5303140*/
   /*IF l_lock_status <> 0 OR l_lock_status_uses <> 0 THEN
           IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('Error while releasing the lock at final exception : Lock Status '||to_char(l_lock_status)||'Lock uses status  '||to_char(l_lock_status_uses));
     END IF;
   END IF;*/
         ROLLBACK TO BANK_SAVE_PT;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         --  Display_Parameters;
         FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                   p_count       =>      x_msg_count,
                                   p_data        =>      x_msg_data
                                   );
       WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('EXCEPTION : arp_bank_pkg.process_cust_bank_account()-');
     arp_util.debug(SQLCODE, G_MSG_ERROR);
           arp_util.debug(SQLERRM, G_MSG_ERROR);
        END IF;
  IF lock_exist = 'Y' THEN
    l_lock_status := dbms_lock.release(lockhandle => l_lock_handle);
  END IF;
  IF uses_lock_exist = 'Y' THEN
    l_lock_status_uses := dbms_lock.release(lockhandle => l_lock_handle_uses);
  END IF;
  IF l_lock_status <> 0 OR l_lock_status_uses <> 0 THEN
          IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('Error while releasing the lock at final exception : Lock Status '||to_char(l_lock_status)||'Lock uses status  '||to_char(l_lock_status_uses));
    END IF;
  END IF;
        ROLLBACK TO BANK_SAVE_PT;
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
        FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
        FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','PROCESS_CUST_BANK_ACCOUNT : '||SQLERRM);
        FND_MSG_PUB.Add;
         IF FND_MSG_PUB.Check_Msg_Level(G_MSG_UERROR) THEN
          FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME ,
                                  l_api_name);
      END IF;
  FND_MSG_PUB.Count_And_Get (p_encoded => FND_API.G_FALSE,
                  p_count => x_msg_count,
                        p_data  => x_msg_data
                                   );

  END process_cust_bank_account;

/*===================================================================================================================+
 | PROCEDURE process_cust_bank_account
 |
 | DESCRIPTION
 |    Group API to process Credit Card and ACH customer bank accounts
 |    This overloaded procedure kept for upward compatibility
 |
 |
 | SCOPE - PUBLIC
 |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED
 |    arp_util.debug
 |
 |
 |Standard API Input output parameter:
 |
 |Parameters         Type   Data-type     Required    Default Value     Description
 |p_api_version      IN     NUMBER         Yes                          Used to compare version numbers of
 |                                                                      incoming calls to its current version number.
 |                                                                      Unexpected error is raised if version
 |                                                                      in-compatibility exists.In the current
 |                                                                      version of the API,you should pass in a value
 |                                                                      of 1.0 for this parameter.
 |
 |p_init_msg_list    IN     VARCHAR2                 FND_API.G_FALSE    Allows API callers to request that
 |                                                                      the API does initialization of the
 |                                                                      message list on their behalf.
 |
 |p_commit           IN     VARCHAR2                 FND_API.G_FALSE    Used by API callers to ask the API to
 |                                                                      commit on their behalf.
 |
 |p_validation_level IN     NUMBER          FND_API.G_VALID_LEVEL_FULL  Level of validation.
 |
 |x_return_status    OUT    VARCHAR2                                    Represents the API overall return status.
 |                                                                      These are possible output values for this
 |                                                                      parameter
 |                                                                      Success - FND_API. G_RET_STS_SUCCESS
 |                                                                      Error - FND_API. G_RET_STS_ERROR
 |                                                                      Unexpected error - FND_API. G_RET_STS_UNEXP_ERROR
 |
 |x_msg_count        OUT    NUMBER                                      Number of messages in the API message list
 |
 |x_msg_data         OUT    VARCHAR2                                    This is the message in encoded format
 |                                                                      if x_msg_count=1
 |
 |arp_bank_pkg.process_cust_bank_account parameters :
 |
 |Parameters           Type   Data-type     Required    Default Value     Description
 |p_org_id              IN     NUMBER        Yes                          Indentifies Organization from which API
 |                                                                        is being called
 |p_trx_date            IN     DATE          Yes                          Date of the transaction
 |p_currency_code       IN     VARCHAR2      Yes                          Currecy_code Currency in which transaction
 |                                                                        will happen
 |p_cust_id             IN     NUMBER        Yes                          Identifies ct for which bank acct needs
 |                                                                        to be updated or created
 |p_site_use_id         IN     NUMBER                     NULL            Identifies site
 |p_credit_card_num     IN     VARCHAR2      Yes                          Bank account number
 |p_exp_date            IN     DATE          Yes                          Inactive date
 |x_bank_account_id     OUT    NUMBER                                     Bank_account_id of the newly created or
 |                                                                        already existing bank account
 |                                                                        for the given set of input parameters
 |x_bank_account_uses_id OUT    NUMBER                                    Bank_account_uses_id of the newly created
 |                                                                        or already existing bank uses record
 |
 |
 | MODIFICATION HISTORY
 |    15-Sep-2004   Srinivasa Kini       Re-written
 |
 +==================================================================================================================*/

  PROCEDURE process_cust_bank_account(
                 p_api_version      IN  NUMBER,
                 p_init_msg_list    IN  VARCHAR2 := FND_API.G_FALSE,
                 p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
                 p_validation_level IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
                 x_return_status    OUT NOCOPY VARCHAR2,
                 x_msg_count        OUT NOCOPY NUMBER,
                 x_msg_data         OUT NOCOPY VARCHAR2,
                 p_org_id           IN AP_BANK_ACCOUNT_USES.ORG_ID%TYPE,
                 p_trx_date    IN  DATE,
                 p_currency_code    IN  AP_BANK_ACCOUNTS.CURRENCY_CODE%TYPE,
             p_cust_id    IN  AP_BANK_ACCOUNT_USES.CUSTOMER_ID%TYPE,
             p_site_use_id     IN  AP_BANK_ACCOUNT_USES.CUSTOMER_SITE_USE_ID%TYPE DEFAULT NULL,
             p_credit_card_num       IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
             p_exp_date    IN  AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE,
             x_bank_account_id  OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE,
             x_bank_account_uses_id  OUT NOCOPY AP_BANK_ACCOUNT_USES.BANK_ACCOUNT_USES_ID%TYPE
  ) IS
  BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('arp_bank_pkg.process_cust_bank_account_overloaded()+');
   END IF;
         process_cust_bank_account(
                  p_api_version=>p_api_version,
                  p_init_msg_list=>p_init_msg_list,
                  p_commit=>p_commit,
                  p_validation_level=>p_validation_level,
                  x_return_status=>x_return_status,
                  x_msg_count=>x_msg_count,
                  x_msg_data=>x_msg_data,
            p_org_id=>p_org_id,
            p_trx_date=>p_trx_date,
            p_currency_code=>p_currency_code,
      p_cust_id=>p_cust_id,
      p_site_use_id=>p_site_use_id,
      p_credit_card_num=>p_credit_card_num,
      p_acct_name =>p_credit_card_num, -- Account Name
      p_exp_date=>p_exp_date,
      x_bank_account_id=>x_bank_account_id,
      x_bank_account_uses_id=>x_bank_account_uses_id);
   IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('arp_bank_pkg.process_cust_bank_account_overloaded()-');
   END IF;
  END process_cust_bank_account;

  PROCEDURE process_cust_bank_account(
  p_trx_date    IN  DATE,
  p_currency_code    IN  AP_BANK_ACCOUNTS.CURRENCY_CODE%TYPE,
  p_cust_id    IN  AP_BANK_ACCOUNT_USES.CUSTOMER_ID%TYPE,
  p_site_use_id     IN  AP_BANK_ACCOUNT_USES.CUSTOMER_SITE_USE_ID%TYPE DEFAULT NULL,
  p_credit_card_num       IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
  p_acct_name             IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NAME%TYPE,
  p_exp_date    IN  AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE,
  p_bank_account_id  OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE,
  p_bank_account_uses_id  OUT NOCOPY AP_BANK_ACCOUNT_USES.BANK_ACCOUNT_USES_ID%TYPE,
        p_owning_party_id  IN NUMBER DEFAULT NULL,
  p_bank_branch_id  IN AP_BANK_ACCOUNTS.BANK_BRANCH_ID%TYPE DEFAULT NULL, /* J Rautiainen ACH Implementation */
        p_account_type          IN  VARCHAR2 DEFAULT NULL,           /* J Rautiainen ACH Implementation */
        p_payment_instrument    IN  VARCHAR2 DEFAULT 'CREDIT_CARD' /* J Rautiainen ACH Implementation */
  ) IS
  l_org_id                   AP_BANK_ACCOUNT_USES.ORG_ID%TYPE;
  l_return_status            VARCHAR2(1);
  l_msg_count                NUMBER;
  l_msg_data                 VARCHAR2(2000);
  l_msg_index                NUMBER;
  API_exception              EXCEPTION;
  BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_bank_pkg.process_cust_bank_account overloaded3()+');
    END IF;

    arp_standard.init_standard;
    arp_global.init_global;
    l_org_id:=arp_global.sysparam.org_id;

    arp_bank_pkg.process_cust_bank_account(p_api_version            => 1.0,
                                           p_init_msg_list          => FND_API.G_TRUE,
             x_return_status          => l_return_status,
             x_msg_count              => l_msg_count,
             x_msg_data               => l_msg_data,
                                           p_org_id                 => l_org_id,
                                           p_trx_date               => p_trx_date,
                                           p_currency_code          => p_currency_code,
                                           p_cust_id                => p_cust_id,
                                           p_site_use_id            => p_site_use_id,
                                           p_credit_card_num        => p_credit_card_num,
                                           p_acct_name              => p_acct_name,
                                           p_exp_date               => p_exp_date,
                                           p_owning_party_id        => p_owning_party_id,
                                           p_bank_branch_id         => p_bank_branch_id,
                                           p_account_type           => p_account_type,
                                           p_payment_instrument     => p_payment_instrument,
                                           x_bank_account_id        => p_bank_account_id,
                                           x_bank_account_uses_id   => p_bank_account_uses_id);

   /*------------------------------------------------+
    | Write API output to the concurrent program log |
    +------------------------------------------------*/
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('process_cust_bank_account: ' || 'API error count '||to_char(NVL(l_msg_count,0)));
   END IF;

   IF NVL(l_msg_count,0)  > 0 Then
    IF l_msg_count  = 1 Then
       /*------------------------------------------------+
        | There is one message returned by the API, so it|
        | has been sent out NOCOPY in the parameter x_msg_data  |
        +------------------------------------------------*/
     IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('process_cust_bank_account: ' || l_msg_data);
     END IF;
          ELSIF l_msg_count > 1 Then
           /*-------------------------------------------------------+
      | There are more than one messages returned by the API, |
      | so call them in a loop and print the messages         |
      +-------------------------------------------------------*/
       FOR l_count IN 1..l_msg_count LOOP
      l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('process_cust_bank_account: ' || to_char(l_count)||' : '||l_msg_data);
      END IF;
             END LOOP;
    END IF; -- l_msg_count
   END IF; -- NVL(l_msg_count,0)
   /*-----------------------------------------------------+
    | If API return status is not SUCCESS raise exception |
    +-----------------------------------------------------*/
   IF l_return_status = FND_API.G_RET_STS_SUCCESS Then
      /*-----------------------------------------------------+
       | Success do nothing, else branch introduced to make  |
       | sure that NULL case will also raise exception       |
       +-----------------------------------------------------*/
      NULL;
   ELSE
       /*---------------------------+
  | Error, raise an exception |
  +---------------------------*/
      RAISE API_exception;
   END IF; -- l_return_status

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_standard.debug( 'arp_bank_pkg.process_cust_bank_account overloaded3()-' );
   END IF;
   /*----------------------------------+
    | APIs propagate exception upwards |
    +----------------------------------*/
  EXCEPTION
    WHEN API_exception THEN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('process_cust_bank_account: ' || 'API EXCEPTION: ' ||
                 'arp_bank_pkg.process_cust_bank_account'
           ||SQLERRM);
    END IF;
    FND_MSG_PUB.Get (FND_MSG_PUB.G_FIRST, FND_API.G_TRUE,
             l_msg_data, l_msg_index);
    FND_MESSAGE.Set_Encoded (l_msg_data);
    app_exception.raise_exception;

    WHEN OTHERS THEN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('EXCEPTION: arp_bank_pkg.process_cust_bank_account overloaded3'
           ||SQLERRM);
    END IF;
      RAISE;
  END process_cust_bank_account;


  /*** This overloaded procedure kept for backward compatibility ****/

  PROCEDURE process_cust_bank_account(
  p_trx_date    IN  DATE,
  p_currency_code    IN  AP_BANK_ACCOUNTS.CURRENCY_CODE%TYPE,
  p_cust_id    IN  AP_BANK_ACCOUNT_USES.CUSTOMER_ID%TYPE,
  p_site_use_id     IN  AP_BANK_ACCOUNT_USES.CUSTOMER_SITE_USE_ID%TYPE DEFAULT NULL,
  p_credit_card_num       IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
  p_exp_date    IN  AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE,
  p_bank_account_id  OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE,
  p_bank_account_uses_id  OUT NOCOPY AP_BANK_ACCOUNT_USES.BANK_ACCOUNT_USES_ID%TYPE
  ) IS
  BEGIN
         process_cust_bank_account(
      p_trx_date,
      p_currency_code,
      p_cust_id,
      p_site_use_id,
      p_credit_card_num,
      p_credit_card_num, -- Account Name
      p_exp_date,
      p_bank_account_id,
      p_bank_account_uses_id);
  EXCEPTION
  when OTHERS then
      RAISE;
  END;

  PROCEDURE check_primary(x_bank_account_uses_id  in number,
        x_external_bank_account_id  in number,
        x_start_date      in date,
        x_end_date      in date,
        x_bank_type      in varchar2,
        x_id        in number,
        x_primary_flag    out NOCOPY varchar2
       ) IS
  l_return_status            VARCHAR2(1);
  l_msg_count                NUMBER;
  l_msg_data                 VARCHAR2(2000);
  l_msg_index                NUMBER;
  API_exception              EXCEPTION;
  BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_bank_pkg.check_primary overloaded1()+');
    END IF;
       check_primary(x_bank_account_uses_id=>x_bank_account_uses_id,
                     x_external_bank_account_id=>x_external_bank_account_id,
         x_start_date=>x_start_date,
         x_end_date=>x_end_date,
         x_bank_type=>x_bank_type,
                     x_id=>x_id,
         x_primary_flag=>x_primary_flag,
                     x_return_status=>l_return_status);
   /*------------------------------------------------+
    | Write API output to the concurrent program log |
    +------------------------------------------------*/
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('check_primary: ' || 'API error count '||to_char(NVL(l_msg_count,0)));
   END IF;

   IF NVL(l_msg_count,0)  > 0 Then
    IF l_msg_count  = 1 Then
       /*------------------------------------------------+
        | There is one message returned by the API, so it|
        | has been sent out NOCOPY in the parameter x_msg_data  |
        +------------------------------------------------*/
     IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('check_primary: ' || l_msg_data);
     END IF;
          ELSIF l_msg_count > 1 Then
           /*-------------------------------------------------------+
      | There are more than one messages returned by the API, |
      | so call them in a loop and print the messages         |
      +-------------------------------------------------------*/
       FOR l_count IN 1..l_msg_count LOOP
      l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('check_primary: ' || to_char(l_count)||' : '||l_msg_data);
      END IF;
             END LOOP;
    END IF; -- l_msg_count
   END IF; -- NVL(l_msg_count,0)
   /*-----------------------------------------------------+
    | If API return status is not SUCCESS raise exception |
    +-----------------------------------------------------*/
   IF l_return_status = FND_API.G_RET_STS_SUCCESS Then
      /*-----------------------------------------------------+
       | Success do nothing, else branch introduced to make  |
       | sure that NULL case will also raise exception       |
       +-----------------------------------------------------*/
      NULL;
   ELSE
       /*---------------------------+
  | Error, raise an exception |
  +---------------------------*/
      RAISE API_exception;
   END IF; -- l_return_status

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_standard.debug( 'arp_bank_pkg.check_primary overloaded1()-' );
   END IF;
   /*----------------------------------+
    | APIs propagate exception upwards |
    +----------------------------------*/
  EXCEPTION
    WHEN API_exception THEN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('check_primary: ' || 'API EXCEPTION: ' ||
                 'arp_bank_pkg.check_primary'
           ||SQLERRM);
    END IF;
    FND_MSG_PUB.Get (FND_MSG_PUB.G_FIRST, FND_API.G_TRUE,
             l_msg_data, l_msg_index);
    FND_MESSAGE.Set_Encoded (l_msg_data);
    app_exception.raise_exception;

    WHEN OTHERS THEN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('EXCEPTION: arp_bank_pkg.check_primary overloaded1'
           ||SQLERRM);
    END IF;
      RAISE;
  END check_primary;


  PROCEDURE check_primary(x_bank_account_uses_id  in number,
        x_external_bank_account_id  in number,
        x_start_date      in date,
        x_end_date      in date,
        x_bank_type      in varchar2,
        x_id        in number,
        x_primary_flag    out NOCOPY varchar2,
                          x_return_status    OUT NOCOPY VARCHAR2
       ) is
  l_primary_count  number(15);
  BEGIN
  --arp_util.debug('arp_bank_pkg.check_primary()+');
        x_return_status := FND_API.G_RET_STS_SUCCESS;
        IF x_bank_type NOT IN ('CUST','SITE') THEN
          x_return_status := FND_API.G_RET_STS_ERROR;
          FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
          FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Error  arp_bank_pkg.check_primary, bank_type can not be'||x_bank_type);
          FND_MSG_PUB.Add;
          RETURN;
        END IF;
  x_primary_flag := 'N';
  IF ( x_bank_type = 'CUST') THEN
  --
    --arp_util.debug(':check_primary: bank_type=CUST');
--    SELECT  count(1)
--    INTO    l_primary_count
--      FROM   ap_bank_account_uses bau,
--      ap_bank_accounts ba,
--                        ap_bank_accounts ba2
--     WHERE   bau.primary_flag     = 'Y'
--       AND   bau.customer_id     = x_id
--       AND   bau.customer_site_use_id   is null
--          AND     (trunc(x_start_date) BETWEEN bau.start_date
--                          AND     NVL(bau.end_date,TRUNC( x_start_date))
--            OR bau.start_date    BETWEEN x_start_date
--                         AND     NVL(x_end_date,bau.start_date)
--      )
--       AND   bau.external_bank_account_id = ba.bank_account_id
--                AND     ba2.bank_account_id       = x_external_bank_account_id
--       AND   ba.currency_code        = ba2.currency_code;


   -- DEFECT 7124 - AR I1025 - Performance issue in HVOP run. Full table scan on AP_BANK_ACCOUNTS
   -- Office Depot - Brian J Looman - May 20, 2008 
   -- temporary solution to remove unnecessary use of ap_bank_accounts,
   --  while waiting for performance SR for permanent fix
   SELECT COUNT(1)
     INTO l_primary_count
     FROM ap_bank_account_uses bau, 
          ap_bank_accounts ba
     WHERE bau.primary_flag = 'Y'
       AND bau.customer_id = x_id
       AND bau.customer_site_use_id   is null 
      AND (trunc(x_start_date) BETWEEN bau.start_date
                   AND NVL(bau.end_date,TRUNC( x_start_date))
            OR bau.start_date BETWEEN x_start_date
                  AND NVL(x_end_date,bau.start_date) )
       AND bau.external_bank_account_id = ba.bank_account_id
      AND ba.bank_account_id = x_external_bank_account_id;


    --
    IF (l_primary_count >= 1) THEN
      x_primary_flag := 'Y';
    END IF;
    --
  ELSIF ( x_bank_type = 'SITE' ) THEN
    --
    --arp_util.debug(':check_primary: bank_type=SITE');
--    SELECT  count(1)
--    INTO    l_primary_count
--      FROM   ap_bank_account_uses bau,
--      ap_bank_accounts ba,
--        ap_bank_accounts ba2
--     WHERE   bau.primary_flag     = 'Y'
--       AND   bau.customer_site_use_id   = x_id
--          AND     (trunc(x_start_date) BETWEEN bau.start_date
--                          AND     NVL(bau.end_date,TRUNC( x_start_date))
--            OR bau.start_date    BETWEEN x_start_date
--                         AND     NVL(x_end_date,bau.start_date)
--      )
--       AND   bau.external_bank_account_id   = ba.bank_account_id
--     AND     ba2.bank_account_id         = x_external_bank_account_id
--       AND   ba.currency_code          = ba2.currency_code;
    --
          
    
   -- DEFECT 7124 - AR I1025 - Performance issue in HVOP run. Full table scan on AP_BANK_ACCOUNTS
   -- Office Depot - Brian J Looman - May 20, 2008 
   -- temporary solution to remove unnecessary use of ap_bank_accounts,
   --  while waiting for performance SR for permanent fix
   SELECT COUNT(1)
     INTO l_primary_count
     FROM ap_bank_account_uses bau, 
          ap_bank_accounts ba
     WHERE bau.primary_flag = 'Y'
       AND bau.customer_site_use_id = x_id
      AND (trunc(x_start_date) BETWEEN bau.start_date
                   AND NVL(bau.end_date,TRUNC( x_start_date))
            OR bau.start_date BETWEEN x_start_date
                  AND NVL(x_end_date,bau.start_date) )
       AND bau.external_bank_account_id = ba.bank_account_id
      AND ba.bank_account_id = x_external_bank_account_id;
    
    
    IF (l_primary_count >= 1) THEN
      x_primary_flag := 'Y';
    END IF;
    --
  END IF;
  IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('arp_bank_pkg.check_primary()-');
  END IF;
EXCEPTION
    WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
   FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
         FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Error  arp_bank_pkg.check_primary '||SQLERRM);
         FND_MSG_PUB.Add;
         IF PG_DEBUG in ('Y', 'C') THEN
           arp_standard.debug ('Exception: arp_bank_pkg.check_primary' ||sqlerrm);
         END IF;
END check_primary;

PROCEDURE check_unique(x_bank_account_uses_id    IN OUT NOCOPY NUMBER,
       x_external_bank_account_id  IN OUT NOCOPY NUMBER,
       x_start_date      IN DATE,
       x_end_date      IN DATE,
       x_bank_type      IN VARCHAR2,
       x_id          IN NUMBER,
       x_primary_flag      IN OUT NOCOPY VARCHAR2,
                         x_owning_party_id           IN NUMBER
       ) IS
  l_return_status            VARCHAR2(1);
  l_msg_count                NUMBER;
  l_msg_data                 VARCHAR2(2000);
  l_msg_index                NUMBER;
  API_exception              EXCEPTION;
  BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_bank_pkg.check_unique1()+');
    END IF;
       check_unique(x_bank_account_uses_id=>x_bank_account_uses_id,
                     x_external_bank_account_id=>x_external_bank_account_id,
         x_start_date=>x_start_date,
         x_end_date=>x_end_date,
         x_bank_type=>x_bank_type,
                     x_id=>x_id,
         x_primary_flag=>x_primary_flag,
         x_owning_party_id=>x_owning_party_id,
                     x_return_status=>l_return_status);
   /*------------------------------------------------+
    | Write API output to the concurrent program log |
    +------------------------------------------------*/
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('check_unique: ' || 'API error count '||to_char(NVL(l_msg_count,0)));
   END IF;

   IF NVL(l_msg_count,0)  > 0 Then
    IF l_msg_count  = 1 Then
       /*------------------------------------------------+
        | There is one message returned by the API, so it|
        | has been sent out NOCOPY in the parameter x_msg_data  |
        +------------------------------------------------*/
     IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('check_unique: ' || l_msg_data);
     END IF;
          ELSIF l_msg_count > 1 Then
           /*-------------------------------------------------------+
      | There are more than one messages returned by the API, |
      | so call them in a loop and print the messages         |
      +-------------------------------------------------------*/
       FOR l_count IN 1..l_msg_count LOOP
      l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('check_unique: ' || to_char(l_count)||' : '||l_msg_data);
      END IF;
             END LOOP;
    END IF; -- l_msg_count
   END IF; -- NVL(l_msg_count,0)
   /*-----------------------------------------------------+
    | If API return status is not SUCCESS raise exception |
    +-----------------------------------------------------*/
   IF l_return_status = FND_API.G_RET_STS_SUCCESS Then
      /*-----------------------------------------------------+
       | Success do nothing, else branch introduced to make  |
       | sure that NULL case will also raise exception       |
       +-----------------------------------------------------*/
      NULL;
   ELSE
       /*---------------------------+
  | Error, raise an exception |
  +---------------------------*/
      RAISE API_exception;
   END IF; -- l_return_status

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_standard.debug( 'arp_bank_pkg.check_unique1()-' );
   END IF;
   /*----------------------------------+
    | APIs propagate exception upwards |
    +----------------------------------*/
  EXCEPTION
    WHEN API_exception THEN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('check_unique: ' || 'API EXCEPTION: ' ||
                 'arp_bank_pkg.check_primary'
           ||SQLERRM);
    END IF;
    FND_MSG_PUB.Get (FND_MSG_PUB.G_FIRST, FND_API.G_TRUE,
             l_msg_data, l_msg_index);
    FND_MESSAGE.Set_Encoded (l_msg_data);
    app_exception.raise_exception;

    WHEN OTHERS THEN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('EXCEPTION: arp_bank_pkg.check_unique1'
           ||SQLERRM);
    END IF;
      RAISE;
END check_unique;

PROCEDURE check_unique(x_bank_account_uses_id    IN OUT NOCOPY NUMBER,
       x_external_bank_account_id  IN OUT NOCOPY NUMBER,
       x_start_date      IN DATE,
       x_end_date      IN DATE,
       x_bank_type      IN VARCHAR2,
       x_id          IN NUMBER,
       x_primary_flag      IN OUT NOCOPY VARCHAR2,
                         x_owning_party_id           IN NUMBER,
                         x_return_status                OUT NOCOPY VARCHAR2
      ) IS
overlap_count number;
BEGIN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('arp_bank_pkg.check_unique()+');
  END IF;

  x_return_status := FND_API.G_RET_STS_SUCCESS;

  IF x_bank_type NOT IN ('CUST','SITE') THEN
   x_return_status := FND_API.G_RET_STS_ERROR;
   FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
   FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Error  arp_bank_pkg.check_unique, bank_type can not be'||x_bank_type);
   FND_MSG_PUB.Add;
   RETURN;
  END IF;

  IF ( x_bank_type = 'CUST') THEN
  SELECT   count(1)
        INTO  overlap_count
    FROM     ap_bank_account_uses
   WHERE    customer_id = x_id
     AND      customer_site_use_id is null
     AND      external_bank_account_id = x_external_bank_account_id
     AND   (trunc(x_start_date) BETWEEN start_date
                     AND NVL(END_DATE,trunc( x_start_date))
          OR start_date BETWEEN x_start_date
                      AND     nvl(x_end_date,start_date)
    )
        AND     NVL(owning_party_id, -9999) = x_owning_party_id;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('overlap_count = ' || to_char(overlap_count));
        END IF;

  --
  --
  IF (overlap_count > 1 ) THEN
          x_return_status := FND_API.G_RET_STS_ERROR;
    fnd_message.set_name('AR','AR_CUST_ACCOUNT_DEFINED');
                FND_MSG_PUB.Add;
  ELSIF (overlap_count = 1) THEN
    SELECT   bank_account_uses_id,
      external_bank_account_id,
      nvl(primary_flag,'N')
    INTO   x_bank_account_uses_id,
      x_external_bank_account_id,
      x_primary_flag
    FROM     ap_bank_account_uses
    WHERE    customer_id = x_id
    AND      customer_site_use_id is null
    AND      external_bank_account_id = x_external_bank_account_id
    AND   (trunc(x_start_date) BETWEEN start_date
           AND NVL(END_DATE,trunc( x_start_date))
      OR start_date BETWEEN x_start_date
              AND     nvl(x_end_date,start_date)
      )
                AND     NVL(owning_party_id, -9999) = x_owning_party_id;


           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('bank_type = CUST');
              arp_util.debug('... x_bank_account_uses_id = ' || to_char(x_bank_account_uses_id));
              arp_util.debug('... x_external_bank_account_id = ' || to_char(x_external_bank_account_id));
              arp_util.debug('... x_primary_flag = ' || x_primary_flag);
           END IF;


  END IF;
    --
  ELSIF ( x_bank_type = 'SITE') THEN
  --
  SELECT   count(1)
        INTO  overlap_count
    FROM     ap_bank_account_uses
   WHERE    customer_site_use_id     = x_id
     AND      external_bank_account_id = x_external_bank_account_id
     AND   (trunc(x_start_date) BETWEEN start_date
                      AND NVL(end_date,trunc( x_start_date))
          OR start_date BETWEEN x_start_date
                      AND     nvl(x_end_date,start_date)
    )
        AND     NVL(owning_party_id, -9999) = x_owning_party_id;
  --
  IF (overlap_count > 1 ) THEN
          x_return_status := FND_API.G_RET_STS_ERROR;
    fnd_message.set_name('AR','AR_CUST_ACCOUNT_DEFINED');
                FND_MSG_PUB.Add;
  ELSIF (overlap_count = 1) then
    SELECT   bank_account_uses_id,
      external_bank_account_id,
      nvl(primary_flag,'N')
    INTO   x_bank_account_uses_id,
      x_external_bank_account_id,
      x_primary_flag
    FROM     ap_bank_account_uses
    WHERE    customer_site_use_id     = x_id
    AND      external_bank_account_id = x_external_bank_account_id
    AND   (trunc(x_start_date) BETWEEN start_date
              AND NVL(end_date,trunc( x_start_date))
      OR start_date BETWEEN x_start_date
              AND     nvl(x_end_date,start_date)
      )
                AND     NVL(owning_party_id, -9999) = x_owning_party_id;
  END IF;
  END IF;

  IF PG_DEBUG in ('Y', 'C') THEN
   arp_util.debug('arp_bank_pkg.check_unique()-');
  END IF;
EXCEPTION
    WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
   FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
         FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Error  arp_bank_pkg.check_unique '||SQLERRM);
         FND_MSG_PUB.Add;
         IF pg_debug = 'Y' THEN
           arp_standard.debug ('Exception: arp_bank_pkg.check_unique' ||sqlerrm);
         END IF;
END check_unique;

------------------------------------------------------------
--- This function calls iPayment APIs to check the Credit Card
--- number. The digits are checked for validity only if
--- Credit card number contains the check for digits
------------------------------------------------------------

FUNCTION val_credit_card_from_ipay (
  p_cc_num_stripped IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
        p_exp_date        IN  AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE) RETURN BOOLEAN IS

  l_return_status varchar2(1);
  l_msg_count number := 0;
  l_msg_data varchar2(2000);
  l_cc_valid boolean := false;
  l_cc_type varchar2(80) := null;

  BEGIN

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_bank_pkg.val_credit_card_from_ipay(+)');
   END IF;

     ------------------------------------------------------
     ---If Credit Card Encryption is enabled AND
     ---Passed Number is in Encrypted format
     ---skip the validation
     ------------------------------------------------------
     IF ( (IBY_CC_SECURITY_PUB.encryption_enabled = TRUE) AND
          ( IBY_CC_SECURITY_PUB.card_number_secured(
              p_card_number => p_cc_num_stripped) = TRUE )
         )THEN

           IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('The input Credit Card number is encrypted' ||
               ' not validating..['|| p_cc_num_stripped ||']');
         END IF;

           RETURN TRUE;


     ------------------------------------------------------
     ---If Credit Card Encryption is NOT enabled OR
     ---Passed Number is NOT Encrypted
     ---skip the validation
     ------------------------------------------------------

    ELSE   ---Else encryption not ON or Card is Unencrypted


       IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug(' Calling IBY_CC_VALIDATE.ValidateCC' ||
           ' to check Credit card digits.');

           arp_util.debug('Expiry Date: '|| p_exp_date);
       END IF;

        IBY_CC_VALIDATE.ValidateCC(
        p_api_version  => 1.0,
        p_init_msg_list => FND_API.G_TRUE,
  p_cc_id   => p_cc_num_stripped,
  p_expr_date  => p_exp_date,
  x_return_status => l_return_status,
  x_msg_count  => l_msg_count,
  x_msg_data  => l_msg_data,
  x_cc_valid   => l_cc_valid,
        x_cc_type       => l_cc_type);


     IF l_cc_valid = TRUE THEN
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug(' Credit Card is Valid' );
          arp_util.debug(' Credit Card Type: '||l_cc_type  );
          arp_util.debug(' iPayment API Return status : '||l_return_status  );
       END IF;

     ELSE
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug(' Credit Card is NOT Valid' );
          arp_util.debug(' Credit Card Type: '||l_cc_type  );
          arp_util.debug(' iPayment API Return status : '||l_return_status  );
     END IF;

     END IF;

   ----Return Value from iPayment
   RETURN l_cc_valid;

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_bank_pkg.val_credit_card_from_ipay(-)');
   END IF;


  END IF;


  END val_credit_card_from_ipay;

  FUNCTION val_credit_card (
      p_cc_num_stripped       IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE
  ) RETURN number IS

  l_stripped_num_table    numeric_tab_typ;   /* Holds credit card number stripped of white spaces */
  l_product_table    numeric_tab_typ;   /* Table of cc digits multiplied by 2 or 1,for validity check */
  l_len_credit_card_num     number := 0;       /* Length of credit card number stripped of white spaces */
  l_product_tab_sum       number := 0;       /* Sum of digits in product table */
  l_actual_cc_check_digit       number := 0;       /* First digit of credit card, numbered from right to left */
  l_mod10_check_digit          number := 0;       /* Check digit after mod10 algorithm is applied */
  j         number := 0;       /* Product table index */
  BEGIN
  --arp_util.debug('arp_bank_pkg.val_credit_card()+');

  SELECT lengthb(p_cc_num_stripped)
  INTO   l_len_credit_card_num
  FROM   dual;

  FOR i in 1..l_len_credit_card_num LOOP
    SELECT to_number(substrb(p_cc_num_stripped,i,1))
    INTO   l_stripped_num_table(i)
    FROM   dual;
  END LOOP;
  l_actual_cc_check_digit := l_stripped_num_table(l_len_credit_card_num);

  FOR i in 1..l_len_credit_card_num-1 LOOP
    IF ( mod(l_len_credit_card_num+1-i,2) > 0 )
    THEN
        -- Odd numbered digit.  Store as is, in the product table.
        j := j+1;
         l_product_table(j) := l_stripped_num_table(i);
    ELSE
        -- Even numbered digit.  Multiply digit by 2 and store in the product table.
        -- Numbers beyond 5 result in 2 digits when multiplied by 2. So handled seperately.
              IF (l_stripped_num_table(i) >= 5)
        THEN
             j := j+1;
        l_product_table(j) := 1;
             j := j+1;
        l_product_table(j) := (l_stripped_num_table(i) - 5) * 2;
        ELSE
             j := j+1;
        l_product_table(j) := l_stripped_num_table(i) * 2;
        END IF;
    END IF;
  END LOOP;

  -- Sum up the product table's digits
  FOR k in 1..j LOOP
    l_product_tab_sum := l_product_tab_sum + l_product_table(k);
  END LOOP;

  l_mod10_check_digit := mod( (10 - mod( l_product_tab_sum, 10)), 10);

  -- If actual check digit and check_digit after mod10 don't match, the credit card is an invalid one.
  IF ( l_mod10_check_digit <> l_actual_cc_check_digit)
  THEN
    --arp_util.debug('arp_bank_pkg.val_credit_card()-');
    return(0);
  ELSE
    --arp_util.debug('arp_bank_pkg.val_credit_card()-');
    return(1);
  END IF;
  END val_credit_card;


  PROCEDURE update_bank_account(
      P_BANK_ACCOUNT_NAME           IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NAME%TYPE,
      P_BANK_ACCOUNT_NUM            IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
      P_CURRENCY_CODE               IN  AP_BANK_ACCOUNTS.CURRENCY_CODE%TYPE,
      P_INACTIVE_DATE               IN  AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE,
      P_BANK_ACCOUNT_ID             IN OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE,
      P_BANK_BRANCH_ID              IN OUT NOCOPY AP_BANK_ACCOUNTS.BANK_BRANCH_ID%TYPE,
      P_ORG_ID                      IN AP_BANK_ACCOUNT_USES.ORG_ID%TYPE
  ) IS
    l_org_id    AP_BANK_ACCOUNTS.ORG_ID%TYPE;
    l_orig_org_id AP_BANK_ACCOUNTS.ORG_ID%TYPE;
    l_lock_name                   VARCHAR2(400); /* 5303140 */
    l_lock_handle                 VARCHAR2(100);
    l_lock_status                 NUMBER;
    lock_exist                    VARCHAR2(1) := 'N';
   BEGIN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('arp_bank_pkg.update_bank_account()+');
        END IF;

        /*-------------------------------------------------------+
   | Set the org_context based on input org_id parameter   |
   +-------------------------------------------------------*/
        l_orig_org_id := fnd_profile.value( 'ORG_ID');
        fnd_client_info.set_org_context(p_org_id);
        arp_standard.init_standard;
        arp_global.init_global;
        l_org_id:=arp_global.sysparam.org_id;

  -- For credit card branch, branch_id = 1
  P_BANK_BRANCH_ID := 1;
        --
/* bug5303140 start */
         /*----------------------------------------------------------------------+
          | Do a named locking for the update so that, no other update would be  |
          | performed on the same bank account from other session                |
          +----------------------------------------------------------------------*/

        BEGIN
     l_lock_name := 'AR.BANK_PKG.ACCOUNTS.'||to_char(p_bank_account_id);
   IF p_bank_branch_id = 1  THEN
     l_lock_name := l_lock_name ||to_char(p_bank_branch_id)||to_char(p_bank_account_num);
   ELSE /*Case of ACH */
     l_lock_name := l_lock_name || to_char(p_bank_branch_id);
   END IF;

         alloc_lock(l_lock_name,l_lock_handle);


         l_lock_status := dbms_lock.request(lockhandle   => l_lock_handle,
                                            lockmode          =>dbms_lock.x_mode,
                                            timeout           =>0,
                                            release_on_commit => TRUE);

          /*---------------------------------------------------------+
          | excluded the status 4 since it is the case where the    |
          | the user tries to acquire his own lock.                 |
          +---------------------------------------------------------*/
            IF (l_lock_status <> 0) THEN
              IF (l_lock_status = 4) THEN
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug(' NO Error while named locking : Lock status :'||to_char(l_lock_status));
           END IF;
                  lock_exist := 'N';
              ELSE
            IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('Error while named locking : Lock status :'||to_char(l_lock_status));
            END IF;
                 lock_exist := 'Y';
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
              END IF;
      END IF;
        EXCEPTION
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','arp_bank_pkg.process_cust_bank_account named locking: '||SQLERRM);
      FND_MSG_PUB.Add;
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END;


/* bug5303140 end */

  BEGIN
          SELECT  ba.bank_account_id
           INTO     P_BANK_ACCOUNT_ID
    FROM   ap_bank_accounts ba
    WHERE   ba.bank_branch_id   = P_BANK_BRANCH_ID
    AND   ba.bank_account_num   = P_BANK_ACCOUNT_NUM
    AND   ba.account_type   = 'EXTERNAL'
    AND     ROWNUM = 1
                -- bug 2652345 : include bank_account_id in where condition, to
                -- ensure you update the correct row
                AND     ba.bank_account_id      = P_BANK_ACCOUNT_ID;

    IF ( trunc(P_INACTIVE_DATE) >= trunc(sysdate))
    THEN

         /*Bug 1713685 The bank account name should not be changed for
                       manual Invoices for Credit card payment */

         /* Bug 2015371 :  1) Modified the fix made in the bug 1713685.
                           2) Now, update stmt. will not update all the records
                              with bank account name if P_BANK_ACCOUNT_NAME is
            null.
            Bug 1994974 : further modified fix from 1713685.  We will now only
                          update the bank account when the name or the date
                          differ from the current values on the account.
         */

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('do update');
                END IF;

                update ap_bank_accounts
          set    BANK_ACCOUNT_NAME     = NVL(P_BANK_ACCOUNT_NAME,
                                                    BANK_ACCOUNT_NAME),
           INACTIVE_DATE         = P_INACTIVE_DATE,
             LAST_UPDATE_DATE      = sysdate,
           LAST_UPDATED_BY       = pg_user_id
          where bank_account_id       = P_BANK_ACCOUNT_ID
                  and (BANK_ACCOUNT_NAME               <> P_BANK_ACCOUNT_NAME
                  or   nvl(INACTIVE_DATE,sysdate-1000) <> P_INACTIVE_DATE);


    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND then
         IF PG_DEBUG in ('Y', 'C') THEN
                       arp_util.debug('Creating bank_account record...');
         END IF;
         insert_bank_account(
        P_BANK_ACCOUNT_NAME          ,
        P_BANK_ACCOUNT_NUM           ,
        P_BANK_BRANCH_ID             ,
        P_CURRENCY_CODE              ,
        P_INACTIVE_DATE              ,
        P_BANK_ACCOUNT_ID            ,
        L_ORG_ID
        );
    WHEN OTHERS then
         RAISE;
  END;
        /*Re-set back the org context */
        fnd_client_info.set_org_context(l_orig_org_id);
        arp_standard.init_standard;
        arp_global.init_global;
        IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('arp_bank_pkg.update_bank_account()-');
  END IF;
  EXCEPTION
  WHEN OTHERS THEN
       IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('arp_bank_pkg.update_bank_account: '||sqlerrm);
       END IF;
       RAISE;
  END update_bank_account;

/*------------------------------------------------------------+
 | Overloaded procedure, this does NOT contain org id.        |
 | Overloading to prevent breaking any existing functionality.|
 +------------------------------------------------------------*/
  PROCEDURE update_bank_account(
      P_BANK_ACCOUNT_NAME           IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NAME%TYPE,
      P_BANK_ACCOUNT_NUM            IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
      P_CURRENCY_CODE               IN  AP_BANK_ACCOUNTS.CURRENCY_CODE%TYPE,
      P_INACTIVE_DATE               IN  AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE,
      P_BANK_ACCOUNT_ID             IN OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE,
      P_BANK_BRANCH_ID              IN OUT NOCOPY AP_BANK_ACCOUNTS.BANK_BRANCH_ID%TYPE
  ) IS
  l_org_id AP_BANK_ACCOUNT_USES.ORG_ID%TYPE;
  BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('overloaded arp_bank_pkg.update_bank_account1()+');
    END IF;
    arp_standard.init_standard;
    arp_global.init_global;
    l_org_id:=arp_global.sysparam.org_id;

       update_bank_account(P_BANK_ACCOUNT_NAME,
                           P_BANK_ACCOUNT_NUM,
                           P_CURRENCY_CODE,
         P_INACTIVE_DATE,
         P_BANK_ACCOUNT_ID,
         P_BANK_BRANCH_ID,
                           L_ORG_ID);
    IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('overloaded arp_bank_pkg.update_bank_account1()-');
    END IF;
   END update_bank_account;

/*------------------------------------------------------------+
 | Overloaded procedure,                                      |
 | Overloading to prevent breaking any existing functionality.|
 +------------------------------------------------------------*/
  PROCEDURE insert_bank_account(
                        P_BANK_ACCOUNT_NAME           IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NAME%TYPE,
                        P_BANK_ACCOUNT_NUM            IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
                        P_BANK_BRANCH_ID              IN  AP_BANK_ACCOUNTS.BANK_BRANCH_ID%TYPE,
                        P_CURRENCY_CODE               IN  AP_BANK_ACCOUNTS.CURRENCY_CODE%TYPE,
                        P_INACTIVE_DATE               IN  AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE,
                        P_BANK_ACCOUNT_ID             OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE,
      P_ORG_ID                      IN AP_BANK_ACCOUNT_USES.ORG_ID%TYPE
  ) IS
  BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('overloaded arp_bank_pkg.insert_bank_account1()+');
   END IF;
                 insert_bank_account(P_BANK_ACCOUNT_NAME,
                                     P_BANK_ACCOUNT_NUM,
                                     P_BANK_BRANCH_ID,
                                     P_CURRENCY_CODE,
                                     P_INACTIVE_DATE,
                                     'BANK',
                                     P_BANK_ACCOUNT_ID,
             P_ORG_ID);
   IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('overloaded arp_bank_pkg.insert_bank_account1()-');
   END IF;
  END insert_bank_account;

  PROCEDURE insert_bank_account(
                        P_BANK_ACCOUNT_NAME           IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NAME%TYPE,
                        P_BANK_ACCOUNT_NUM            IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
                        P_BANK_BRANCH_ID              IN  AP_BANK_ACCOUNTS.BANK_BRANCH_ID%TYPE,
                        P_CURRENCY_CODE               IN  AP_BANK_ACCOUNTS.CURRENCY_CODE%TYPE,
                        P_INACTIVE_DATE               IN  AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE,
                        P_BANK_ACCOUNT_ID             OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE
  ) IS
  l_org_id AP_BANK_ACCOUNT_USES.ORG_ID%TYPE;
  BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('overloaded arp_bank_pkg.insert_bank_account2()+');
   END IF;
    arp_standard.init_standard;
    arp_global.init_global;
    l_org_id:=arp_global.sysparam.org_id;

                 insert_bank_account(P_BANK_ACCOUNT_NAME,
                                     P_BANK_ACCOUNT_NUM,
                                     P_BANK_BRANCH_ID,
                                     P_CURRENCY_CODE,
                                     P_INACTIVE_DATE,
                                     'BANK',
                                     P_BANK_ACCOUNT_ID,
             L_ORG_ID);
   IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('overloaded arp_bank_pkg.insert_bank_account2()-');
   END IF;
  END insert_bank_account;

  PROCEDURE insert_bank_account(
        P_BANK_ACCOUNT_NAME        IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NAME%TYPE,
        P_BANK_ACCOUNT_NUM         IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
        P_BANK_BRANCH_ID           IN  AP_BANK_ACCOUNTS.BANK_BRANCH_ID%TYPE,
        P_CURRENCY_CODE            IN  AP_BANK_ACCOUNTS.CURRENCY_CODE%TYPE,
        P_INACTIVE_DATE            IN  AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE,
        P_BANK_ACCOUNT_TYPE        IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_TYPE%TYPE,
        P_BANK_ACCOUNT_ID          OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE) IS
  l_org_id AP_BANK_ACCOUNT_USES.ORG_ID%TYPE;
  BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('overloaded arp_bank_pkg.insert_bank_account3()+');
   END IF;
     arp_standard.init_standard;
     arp_global.init_global;
     l_org_id:=arp_global.sysparam.org_id;
     insert_bank_account(P_BANK_ACCOUNT_NAME,
                         P_BANK_ACCOUNT_NUM,
       P_BANK_BRANCH_ID,
                         P_CURRENCY_CODE,
       P_INACTIVE_DATE,
       P_BANK_ACCOUNT_TYPE,
       P_BANK_ACCOUNT_ID,
       L_ORG_ID);
   IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('overloaded arp_bank_pkg.insert_bank_account3()-');
   END IF;
  END insert_bank_account;


/*------------------------------------------------------------+
 | Overloaded procedure, this contains the account type.      |
 | Overloading to prevent breaking any existing functionality.|
 +------------------------------------------------------------*/
  PROCEDURE insert_bank_account(
        P_BANK_ACCOUNT_NAME        IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NAME%TYPE,
        P_BANK_ACCOUNT_NUM         IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE,
        P_BANK_BRANCH_ID           IN  AP_BANK_ACCOUNTS.BANK_BRANCH_ID%TYPE,
        P_CURRENCY_CODE            IN  AP_BANK_ACCOUNTS.CURRENCY_CODE%TYPE,
        P_INACTIVE_DATE            IN  AP_BANK_ACCOUNTS.INACTIVE_DATE%TYPE,
        P_BANK_ACCOUNT_TYPE        IN  AP_BANK_ACCOUNTS.BANK_ACCOUNT_TYPE%TYPE,
        P_BANK_ACCOUNT_ID          OUT NOCOPY AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE,
  P_ORG_ID                   IN AP_BANK_ACCOUNT_USES.ORG_ID%TYPE) IS


    l_org_id    AP_BANK_ACCOUNTS.ORG_ID%TYPE;
    l_orig_org_id AP_BANK_ACCOUNTS.ORG_ID%TYPE;
    l_sob_id AP_BANK_ACCOUNTS.SET_OF_BOOKS_ID%TYPE;
    l_bank_account_num AP_BANK_ACCOUNTS.BANK_ACCOUNT_NUM%TYPE;


   BEGIN
        IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('arp_bank_pkg.insert_bank_account()+');
  END IF;
        /*-------------------------------------------------------+
   | Set the org_context based on input org_id parameter   |
   +-------------------------------------------------------*/
        l_orig_org_id := fnd_profile.value( 'ORG_ID');
        fnd_client_info.set_org_context(p_org_id);
        arp_standard.init_standard;
        arp_global.init_global;
        l_org_id:=arp_global.sysparam.org_id;
  l_sob_id           := arp_global.set_of_books_id;

        BEGIN
          SELECT  AP_BANK_ACCOUNTS_S.NEXTVAL
           INTO    P_BANK_ACCOUNT_ID
          FROM    DUAL;
        EXCEPTION
          WHEN OTHERS then
            RAISE;
        END;
        /*-------------------------------------------------------------+
   | If already cc has been inserted with orgid then             |
   | we need to insert new record with current orgid..or else    |
   | insert the record with null orgid                           |
   +-------------------------------------------------------------*/

        DECLARE
    l_dummy  NUMBER;
        BEGIN

         SELECT 1
         INTO   l_dummy
         FROM dual
   WHERE EXISTS ( SELECT 1
      FROM  ap_bank_accounts_all ba
      WHERE ba.bank_branch_id       = 1
      AND   ba.bank_account_num     = p_bank_account_num
      AND   ba.account_type         = 'EXTERNAL');
        EXCEPTION
    WHEN NO_DATA_FOUND THEN
             l_org_id := null;
    WHEN OTHERS THEN
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('check_primary: ' || '1a: when others error raised');
      END IF;
        END;


        ------------------------------------------------------
        ---Bug  4604999 Credit Card Encryption Logic
        ------------------------------------------------------
        IF P_BANK_BRANCH_ID = 1 THEN

           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('The input bank account is Credit Card account.');
     END IF;

           ------------------------------------------------------
           ---Check if the input CC number is already encrypted
           ---If not, then encrypt it and then insert into table
           ---else add as it is in the table
           ------------------------------------------------------

           ---Check if encryption is enabled
           IF IBY_CC_SECURITY_PUB.encryption_enabled = TRUE THEN

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('The encryption for Credit Cards is turned ON.');
       END IF;

             ---Check if the input CC Number is encrypted
             IF IBY_CC_SECURITY_PUB.card_number_secured
                   (p_card_number => P_BANK_ACCOUNT_NUM) = TRUE THEN

                IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('The input Credit Card number is already encrypted.');
          END IF;

                l_bank_account_num := P_BANK_ACCOUNT_NUM;

             ---if the input CC Number is NOT encrypted
             ELSE

               IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('Calling API to encrypt the Credit Card number.');
         END IF;

               ---Call Encryption API
               l_bank_account_num := IBY_CC_SECURITY_PUB.secure_card_number
               (p_commit => FND_API.G_FALSE,
                p_card_number => P_BANK_ACCOUNT_NUM);

            END IF;

          ELSE --encryption is NOT enabled

              IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('The encryption for Credit Cards is turned OFF.');
        END IF;

           l_bank_account_num := P_BANK_ACCOUNT_NUM;

          END IF;

        ELSE ----NOT an external Credit card bank

        l_bank_account_num := P_BANK_ACCOUNT_NUM;

        END IF;

        ------------------------------------------------------
        ---Bug  4604999 Credit Card Encryption Logic ends here
        ------------------------------------------------------
         INSERT INTO ap_bank_accounts
      (
       BANK_ACCOUNT_ID
      ,BANK_ACCOUNT_NAME
      ,LAST_UPDATE_DATE
      ,LAST_UPDATED_BY
      ,LAST_UPDATE_LOGIN
      ,CREATION_DATE
      ,CREATED_BY
      ,BANK_ACCOUNT_NUM
      ,BANK_BRANCH_ID
      ,SET_OF_BOOKS_ID
      ,CURRENCY_CODE
      ,INACTIVE_DATE
      ,BANK_ACCOUNT_TYPE
      ,MULTI_CURRENCY_FLAG
      ,ACCOUNT_TYPE
      ,PROGRAM_APPLICATION_ID
      ,PROGRAM_UPDATE_DATE
      ,RECEIPT_MULTI_CURRENCY_FLAG
      ,org_id
      )
    VALUES(
       P_BANK_ACCOUNT_ID
      ,P_BANK_ACCOUNT_NAME
      ,sysdate
      ,pg_user_id
      ,pg_login_id
      ,sysdate
      ,pg_user_id
      ,l_bank_account_num
      ,P_BANK_BRANCH_ID
      ,l_sob_id
      ,P_CURRENCY_CODE
      ,P_INACTIVE_DATE
      ,P_BANK_ACCOUNT_TYPE /*For ACH*/
      ,'N'
      ,'EXTERNAL'
      ,pg_prog_appl_id
      ,trunc(sysdate)
      ,'N'
      ,l_org_id );

            pg_account_inserted := 'Y';

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Inserting apba record. ba_id = '||to_char(P_BANK_ACCOUNT_ID));
        END IF;

        /*Re-set back the org context */
        fnd_client_info.set_org_context(l_orig_org_id);
        arp_standard.init_standard;
        arp_global.init_global;

  IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('arp_bank_pkg.insert_bank_account()-');
  END IF;

  EXCEPTION
  WHEN OTHERS THEN
      IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('arp_bank_pkg.insert_bank_account: '||sqlerrm);
      END IF;
       RAISE;
  END insert_bank_account;

  FUNCTION get_bank_acct(p_customer_id IN NUMBER ,
           p_site_use_id IN NUMBER DEFAULT null,
           p_cc_only IN BOOLEAN DEFAULT FALSE,
           p_primary IN BOOLEAN DEFAULT TRUE,
           p_as_of_date IN DATE DEFAULT TRUNC(SYSDATE)) RETURN NUMBER IS
  --
  TYPE pri_bank_acc_typ IS REF CURSOR;

  pri_bank_acc   pri_bank_acc_typ;

  sql_stmt       VARCHAR2(10000);

  l_bank_acct_id AP_BANK_ACCOUNTS.BANK_ACCOUNT_ID%TYPE := NULL;
  l_site_use_id  AP_BANK_ACCOUNT_USES.CUSTOMER_SITE_USE_ID%TYPE;
  l_as_of_date   DATE := NVL(p_as_of_date, TRUNC(SYSDATE));
  --
  site_sql_stmt      VARCHAR2(4000) := '
        SELECT  external_bank_account_id, NVL(customer_site_use_id, -1)
    FROM   ap_bank_account_uses bau
     WHERE   bau.customer_id     = :p_customer_id
     AND   bau.customer_site_use_id        = NVL(:p_site_use_id, -1)
        AND     :p_as_of_date BETWEEN bau.start_date AND NVL(bau.end_date, :p_as_of_date ) ';
  --
  cust_sql_stmt      VARCHAR2(4000) := '
  UNION
        SELECT  external_bank_account_id, NVL(customer_site_use_id, -1)
    FROM   ap_bank_account_uses bau
     WHERE   bau.customer_id     = :p_customer_id
     AND   bau.customer_site_use_id        IS NULL
        AND     :p_as_of_date BETWEEN bau.start_date AND NVL(bau.end_date, :p_as_of_date ) ';
  --
  cc_only_stmt   VARCHAR2(4000) := ' AND EXISTS ( SELECT 1 FROM ap_bank_accounts ba
                  WHERE ba.bank_account_id = bau.external_bank_account_id
               AND   ba.bank_branch_id  = 1 ) ';
  --
  primary_stmt       VARCHAR2(4000) := ' AND bau.primary_flag     = ''Y'' ';
  --
  order_by_stmt      VARCHAR2(4000) := '
          ORDER BY 2 desc ';
  --
  BEGIN
     --
     sql_stmt := site_sql_stmt;
     --
     IF p_primary THEN
     --
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('check_primary: ' || 'Primary Only..');
  END IF;
  sql_stmt := sql_stmt || CRLF || primary_stmt;
     --
     END IF;
     --
     IF p_cc_only THEN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('check_primary: ' || 'In CC Only..');
  END IF;
  sql_stmt := sql_stmt || CRLF || cc_only_stmt;
  null;
     END IF;
     --
     sql_stmt := sql_stmt || CRLF || cust_sql_stmt;

     IF p_primary THEN
     --
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('check_primary: ' || 'Primary Only..');
  END IF;
  sql_stmt := sql_stmt || CRLF || primary_stmt;
     --
     END IF;
     --
     IF p_cc_only THEN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('check_primary: ' || 'In CC Only..');
  END IF;
  sql_stmt := sql_stmt || CRLF || cc_only_stmt;
  null;
     END IF;

     IF PG_DEBUG in ('Y', 'C') THEN
        arp_standard.debug('check_primary: ' || sql_stmt);
     END IF;

     OPEN  pri_bank_acc FOR sql_stmt USING p_customer_id, p_site_use_id, l_as_of_date, l_as_of_date,
                                           p_customer_id, l_as_of_date, l_as_of_date;
     FETCH pri_bank_acc INTO l_bank_acct_id, l_site_use_id;

     CLOSE pri_bank_acc;

     RETURN (l_bank_acct_id);

  EXCEPTION
     WHEN OTHERS THEN
  RAISE;
  END get_bank_acct;

  FUNCTION get_primary_bank_acct(p_customer_id IN NUMBER ,
           p_site_use_id IN NUMBER DEFAULT null,
           p_cc_only IN BOOLEAN DEFAULT FALSE,
           p_as_of_date IN DATE DEFAULT TRUNC(SYSDATE)) RETURN NUMBER IS
  BEGIN

  RETURN(get_bank_acct(p_customer_id=>p_customer_id,
           p_site_use_id=>p_site_use_id,
           p_cc_only=>p_cc_only,
           p_primary=>TRUE,
           p_as_of_date=>NVL(p_as_of_date, TRUNC(SYSDATE))));
  EXCEPTION
     WHEN OTHERS THEN
  RAISE;
  END get_primary_bank_acct;

  FUNCTION get_cust_pay_method(p_customer_id IN NUMBER,
                p_site_use_id IN NUMBER DEFAULT null,
          p_pay_method_id IN NUMBER DEFAULT null,
                p_cc_only IN BOOLEAN DEFAULT TRUE,
                p_primary IN BOOLEAN DEFAULT TRUE,
          p_check IN BOOLEAN DEFAULT FALSE,
                p_as_of_date IN DATE DEFAULT TRUNC(SYSDATE)) RETURN NUMBER IS
  TYPE pri_pay_method_typ IS REF CURSOR;

  pri_pay_method      pri_pay_method_typ;
  l_receipt_method_id AR_RECEIPT_METHODS.receipt_method_id%TYPE := NULL;
  l_site_use_id       AP_BANK_ACCOUNT_USES.CUSTOMER_SITE_USE_ID%TYPE;
  l_as_of_date        DATE := NVL(p_as_of_date, TRUNC(SYSDATE));

  sql_stmt       VARCHAR2(10000);

  site_sql_stmt      VARCHAR2(4000) := '
        SELECT  cust_RECEIPT_METHOD_ID, NVL(site_use_id, -1)
    FROM   ra_cust_receipt_methods rm
     WHERE   rm.customer_id     = :p_customer_id
     AND   rm.SITE_USE_ID          = NVL(:p_site_use_id, -1)
        AND     :p_as_of_date BETWEEN rm.start_date AND NVL(rm.end_date, :p_as_of_date ) ';

  cust_sql_stmt      VARCHAR2(4000) := '
  UNION
        SELECT  cust_RECEIPT_METHOD_ID, NVL(site_use_id, -1)
    FROM   ra_cust_receipt_methods rm
     WHERE   rm.customer_id     = :p_customer_id
     AND   rm.SITE_USE_ID          IS NULL
        AND     :p_as_of_date BETWEEN rm.start_date AND NVL(rm.end_date, :p_as_of_date ) ';

  cc_only_stmt   VARCHAR2(4000) := ' AND EXISTS ( SELECT 1 FROM ar_receipt_methods ba
                  WHERE ba.RECEIPT_METHOD_ID = rm.RECEIPT_METHOD_ID
               AND   ba.payment_type_code  = ''CREDIT_CARD'' ) ';
  primary_stmt   VARCHAR2(4000) := ' AND rm.primary_flag                 = ''Y'' ';
  pay_stmt       VARCHAR2(4000) := ' AND rm.receipt_method_id = :p_pay_method_id ';

  BEGIN
     --
     IF NOT p_check THEN
  IF p_site_use_id IS NOT NULL THEN
     cust_sql_stmt := cust_sql_stmt || CRLF || ' AND 1 = 2 ';
  END IF;
     END IF;
     --
     sql_stmt := site_sql_stmt;
     --
     IF p_primary THEN
     --
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('check_primary: ' || 'Primary Only..');
  END IF;
  sql_stmt := sql_stmt || CRLF || primary_stmt;
     --
     END IF;
     --
     IF p_cc_only THEN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('check_primary: ' || 'In CC Only..');
  END IF;
  sql_stmt := sql_stmt || CRLF || cc_only_stmt;
  null;
     END IF;
     --
     IF p_pay_method_id IS NOT NULL THEN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('check_primary: ' || 'Pay Method Only..');
  END IF;
  sql_stmt := sql_stmt || CRLF || pay_stmt;
  null;
     END IF;
     --
     sql_stmt := sql_stmt || CRLF || cust_sql_stmt;

     IF p_primary THEN
     --
  sql_stmt := sql_stmt || CRLF || primary_stmt;
     --
     END IF;
     --
     IF p_cc_only THEN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('check_primary: ' || 'In CC Only..');
  END IF;
  sql_stmt := sql_stmt || CRLF || cc_only_stmt;
  null;
     END IF;
     --
     IF p_pay_method_id IS NOT NULL THEN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('check_primary: ' || 'Pay Method Only..');
  END IF;
  sql_stmt := sql_stmt || CRLF || pay_stmt;
  null;
     END IF;
     --
     IF PG_DEBUG in ('Y', 'C') THEN
        arp_standard.debug('check_primary: ' || sql_stmt);
     END IF;

     IF p_pay_method_id IS NOT NULL THEN
        OPEN  pri_pay_method FOR sql_stmt USING p_customer_id, p_site_use_id, l_as_of_date,
               l_as_of_date, p_pay_method_id,
                                             p_customer_id, l_as_of_date,
               l_as_of_date, p_pay_method_id;

     ELSE
        OPEN  pri_pay_method FOR sql_stmt USING p_customer_id, p_site_use_id, l_as_of_date, l_as_of_date,
                                           p_customer_id, l_as_of_date, l_as_of_date;
     END IF;

     -- Always pick the first

     FETCH pri_pay_method INTO l_receipt_method_id, l_site_use_id;

     CLOSE pri_pay_method;

     RETURN (l_receipt_method_id);

  EXCEPTION
     WHEN OTHERS THEN
  RAISE;
  END get_cust_pay_method;

  FUNCTION get_pay_method(p_customer_id IN NUMBER,
                p_site_use_id IN NUMBER DEFAULT null,
                p_cc_only IN BOOLEAN DEFAULT TRUE,
                p_primary IN BOOLEAN DEFAULT TRUE,
                p_as_of_date IN DATE DEFAULT TRUNC(SYSDATE)) RETURN NUMBER IS
  l_cust_pay_method   NUMBER;
  l_pay_method        NUMBER;
  BEGIN
     l_cust_pay_method := get_cust_pay_method(p_customer_id=>p_customer_id,
                p_site_use_id=>p_site_use_id,
                p_cc_only=>p_cc_only,
                p_primary=>p_primary,
                p_as_of_date=>NVL(p_as_of_date, TRUNC(SYSDATE)));
     IF l_cust_pay_method IS NOT NULL THEN

  BEGIN
     SELECT
        receipt_method_id
     INTO
        l_pay_method
     FROM
        ra_cust_receipt_methods
     WHERE
        cust_receipt_method_id = l_cust_pay_method;
  EXCEPTION
     WHEN OTHERS THEN
        RAISE;
  END;

     END IF;

     RETURN(l_pay_method);

  EXCEPTION
     WHEN OTHERS THEN
  RAISE;
  END get_pay_method;
  --
  FUNCTION get_primary_pay_method(p_customer_id IN NUMBER,
                p_site_use_id IN NUMBER DEFAULT null,
                p_cc_only IN BOOLEAN DEFAULT TRUE,
                p_as_of_date IN DATE DEFAULT TRUNC(SYSDATE)) RETURN NUMBER IS
  BEGIN
     RETURN( get_pay_method(p_customer_id=>p_customer_id,
                p_site_use_id=>p_site_use_id,
                p_cc_only=>p_cc_only,
                p_primary=>TRUE,
                p_as_of_date=>NVL(p_as_of_date, TRUNC(SYSDATE))));
  EXCEPTION
     WHEN OTHERS THEN
  RAISE;
  END get_primary_pay_method;

  -- Bug #1569152 mramanat 01/16/2001
  -- modified function process_cust_pay_method so that the new payment method added is
  -- not primary for cust/site.
  FUNCTION process_cust_pay_method (
             p_pay_method_id IN NUMBER,
             p_customer_id IN NUMBER,
             p_site_use_id IN NUMBER DEFAULT null,
             p_as_of_date IN DATE DEFAULT TRUNC(SYSDATE) ) RETURN NUMBER IS
  l_cust_pay_method_id NUMBER;
  /***    Commented out NOCOPY the code for bug #1569152
  l_primary_flag       ra_cust_receipt_methods.primary_flag%type;

    FUNCTION check_primary_method_exists (p_customer_id IN NUMBER,
            p_site_use_id IN NUMBER DEFAULT null,
            p_as_of_date IN DATE DEFAULT TRUNC(SYSDATE)) RETURN BOOLEAN IS
       l_result BOOLEAN := FALSE;
    BEGIN
       IF get_cust_pay_method(p_customer_id=>p_customer_id,
            p_site_use_id=>p_site_use_id,
            p_cc_only=>FALSE,
            p_primary=>TRUE,
            p_as_of_date=>NVL(p_as_of_date, TRUNC(SYSDATE))) IS NOT NULL THEN
          l_result := TRUE;
       ELSE
    l_result := FALSE;
       END IF;

       RETURN(l_result);
    EXCEPTION
       WHEN OTHERS THEN
    RAISE;
    END check_primary_method_exists;
    ***/
  BEGIN
     l_cust_pay_method_id := get_cust_pay_method(p_customer_id=>p_customer_id,
                p_site_use_id=>p_site_use_id,
                p_pay_method_id=>p_pay_method_id,
                p_cc_only=>FALSE,
                p_primary=>FALSE,
                p_as_of_date=>NVL(p_as_of_date, TRUNC(SYSDATE)));
     IF l_cust_pay_method_id IS NULL THEN
     --
  SELECT
     RA_CUST_RECEIPT_METHODS_S.NEXTVAL
        INTO
     l_cust_pay_method_id
        FROM
     dual;
     --
     /*** Commented for bug #1569152
  IF check_primary_method_exists(p_customer_id=>p_customer_id,
              p_site_use_id=>p_site_use_id,
            p_as_of_date=>NVL(p_as_of_date, TRUNC(SYSDATE))) THEN
           l_primary_flag := 'N';
  ELSE
           l_primary_flag := 'Y';
  END IF;
     ***/
  INSERT INTO ra_cust_receipt_methods
  (customer_id,
   receipt_method_id,
   primary_flag,
   creation_date,
   created_by,
   last_update_date,
   last_updated_by,
   program_application_id,
   site_use_id,
   start_date,
   cust_receipt_method_id)
  VALUES
  (p_customer_id,    -- Customer Id
   p_pay_method_id,  -- Receipt Method Id
   'N',              -- Primary Flag Bug #1569152
   SYSDATE,          -- Creation Date
   pg_user_id,       -- Created By
   SYSDATE,          -- Last Update Date
   pg_user_id,       -- Last Updated By
   pg_prog_appl_id,  -- Program Application Id
   p_site_use_id,    -- Site use Id
   TRUNC(p_as_of_date),   -- Start Date
   l_cust_pay_method_id);

     END IF;

     RETURN(l_cust_pay_method_id);

  EXCEPTION
     WHEN OTHERS THEN
  RAISE;

  END process_cust_pay_method;

/*===========================================================================+
 | PROCEDURE insert_bank_branch                                              |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Inserts a bank branch.                                                 |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN: p_bank_name            Bank Name                         |
 |                  p_bank_branch_name     Bank Branch Name                  |
 |                  p_bank_number          Bank Number                       |
 |                  p_bank_num             Bank Branch Number                |
 |                  p_bank_branch_type     Bank Branch Type                  |
 |                  p_institution_type     Institution Type                  |
 |                  p_end_date             Inactive on                       |
 |                  p_eft_user_number      EFT Number                        |
 |                  p_eft_swift_code       Swift Code                        |
 |                  p_edi_id_number        EDI ID Number                     |
 |                  p_ece_tp_location_code EDI Location                      |
 |                  p_description          Description                       |
 |                                                                           |
 |              OUT:                                                         |
 |                  p_bank_branch_id       Bank Branch Id                    |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     25-Oct-2001  Jani Rautiainen      Created                             |
 |                                                                           |
 +===========================================================================*/
  PROCEDURE insert_bank_branch(p_bank_name            IN  ap_bank_branches.bank_name%TYPE,
                               p_bank_branch_name     IN  ap_bank_branches.bank_branch_name%TYPE,
                               p_bank_number          IN  ap_bank_branches.bank_number%TYPE,
                               p_bank_num             IN  ap_bank_branches.bank_num%TYPE,
                               p_bank_branch_type     IN  ap_bank_branches.bank_branch_type%TYPE,
                               p_institution_type     IN  ap_bank_branches.institution_type%TYPE,
                               p_end_date             IN  ap_bank_branches.end_date%TYPE,
                               p_eft_user_number      IN  ap_bank_branches.eft_user_number%TYPE,
                               p_eft_swift_code       IN  ap_bank_branches.eft_swift_code%TYPE,
                               p_edi_id_number        IN  ap_bank_branches.edi_id_number%TYPE,
                               p_ece_tp_location_code IN  ap_bank_branches.ece_tp_location_code%TYPE,
                               p_description          IN  ap_bank_branches.description%TYPE,
                               p_bank_branch_id       OUT NOCOPY ap_bank_branches.bank_branch_id%TYPE) IS

   BEGIN

      BEGIN
         SELECT  AP_BANK_BRANCHES_S.NEXTVAL
          INTO    P_BANK_BRANCH_ID
         FROM    DUAL;
      EXCEPTION
         when OTHERS then
            RAISE;
      END;

      INSERT INTO ap_bank_branches(
                    bank_branch_id
                   ,bank_name
                   ,bank_branch_name
                   ,bank_number
                   ,bank_num
                   ,bank_branch_type
                   ,institution_type
                   ,end_date
                   ,eft_user_number
                   ,eft_swift_code
                   ,edi_id_number
                   ,ece_tp_location_code
                   ,description
                   ,creation_date
                   ,created_by
                   ,last_update_date
                   ,last_updated_by
                   ,last_update_login
                   ,program_application_id
                   ,program_update_date
                   ,program_id
                   ,request_id

                  ) VALUES (

                    p_bank_branch_id
                   ,p_bank_name
                   ,p_bank_branch_name
                   ,p_bank_number
                   ,p_bank_num
                   ,p_bank_branch_type
                   ,p_institution_type
                   ,p_end_date
                   ,p_eft_user_number
                   ,p_eft_swift_code
                   ,p_edi_id_number
                   ,p_ece_tp_location_code
                   ,p_description
                   ,trunc(sysdate)
                   ,pg_user_id
                   ,trunc(sysdate)
                   ,pg_user_id
                   ,pg_login_id
                   ,pg_prog_appl_id
                   ,trunc(sysdate)
                   ,pg_program_id
                   ,pg_request_id
                  );

  EXCEPTION
  when OTHERS then
       RAISE;
  END insert_bank_branch;

/*===========================================================================+
 | PROCEDURE insert_bank_branch                                              |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Overloaded procedure, used by iReceivables to enter a bank branch with |
 |    minimal possible input from the user.                                  |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN: p_routing_number       Routing Number                    |
 |                                                                           |
 |              OUT:                                                         |
 |                  p_bank_branch_id       Bank Branch Id                    |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     25-Oct-2001  Jani Rautiainen      Created                             |
 |                                                                           |
 +===========================================================================*/
  PROCEDURE insert_bank_branch(p_routing_number       IN  VARCHAR2,
                               p_bank_branch_id       OUT NOCOPY ap_bank_branches.bank_branch_id%TYPE) IS

    l_bank_name        AR_BANK_DIRECTORY.bank_name%TYPE;
    l_bank_name_source fnd_profile_option_values.profile_option_value%TYPE;
    /*3967102*/
    l_branch_name      AP_BANK_BRANCHES.bank_branch_name%TYPE;

   BEGIN

    /*--------------------------------------------------------------+
     | Fetch profile option which determines where bank name should |
     | be obtained. Possible values:                                |
     |  'NONE'  -> Routing number is used as bank name              |
     |  'LOCAL' -> Bank name is fetched from local table            |
     |  'WEB_SERVICE' -> Bank name is fetched from a web service    |
     |  'WEB_SERVICE_AND_LOCAL' -> First try web service, then      |
     |                             local table.                     |
     +--------------------------------------------------------------*/
     l_bank_name_source := NVL(FND_PROFILE.value('AR_BANK_DIRECTORY_SOURCE'),'');

    /*-----------------+
     | Fetch bank name |
     +-----------------*/
     l_bank_name := arp_bank_directory.get_bank_name(p_routing_number,
                                                     l_bank_name_source);
    /*--------------------------------------------------+
     | If bank name could not be defaulted, use routing |
     | number as bank name.                             |
     +--------------------------------------------------*/
     IF l_bank_name = '' OR l_bank_name IS NULL THEN
       l_bank_name := p_routing_number;
       l_branch_name:=l_bank_name;
     /*3967102*/
     ELSE
  BEGIN
     SELECT bank_branch_name INTO l_branch_name FROM
     AP_BANK_BRANCHES WHERE bank_name=SUBSTRB(l_bank_name,1,30)
     AND bank_branch_name=SUBSTRB(l_bank_name,1,30);
     l_branch_name:=p_routing_number;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
       l_branch_name:=SUBSTRB(l_bank_name,1,30);
  END;
     END IF;


            insert_bank_branch(p_bank_name            => SUBSTRB(l_bank_name,1,30),
                               p_bank_branch_name     => SUBSTRB(l_branch_name,1,30),   /*3967102*/
                               p_bank_number          => SUBSTRB(p_routing_number,1,30),
                               p_bank_num             => SUBSTRB(p_routing_number,1,25),
                               p_bank_branch_type     => null,
                               p_institution_type     => 'BANK',
                               p_end_date             => null,
                               p_eft_user_number      => null,
                               p_eft_swift_code       => null,
                               p_edi_id_number        => null,
                               p_ece_tp_location_code => null,
                               p_description          => null,
                               p_bank_branch_id       => p_bank_branch_id);

  EXCEPTION
  when OTHERS then
       RAISE;
  END insert_bank_branch;

/*===========================================================================+
 | PROCEDURE get_bank_branch_id                                              |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Tries to find a bank branch based on routing number, if branch not     |
 |    found, then a new one is created.                                      |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN: p_routing_number       Routing Number                    |
 |                                                                           |
 |              OUT:                                                         |
 |                  p_bank_branch_id       Bank Branch Id                    |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     25-Oct-2001  Jani Rautiainen      Created                             |
 |                                                                           |
 +===========================================================================*/
  PROCEDURE get_bank_branch_id(p_routing_number       IN  VARCHAR2,
                               p_bank_branch_id       OUT NOCOPY ap_bank_branches.bank_branch_id%TYPE) IS

 /*-----------------------------------------------------+
  | Cursor to fetch bank branch based on routing number |
  +-----------------------------------------------------*/
  CURSOR bank_branch_cur(l_routing_number VARCHAR2) IS
    SELECT bank_branch_id
    FROM ap_bank_branches
    WHERE bank_num = l_routing_number;

    l_routing_number   VARCHAR2(100);
    bank_branch_rec    bank_branch_cur%ROWTYPE;

  BEGIN
   /*-----------------------------------------------------+
    | Remove non-digit characters from the routing number |
    +-----------------------------------------------------*/
    strip_white_spaces(p_routing_number,l_routing_number);

   /*-----------------------------------------------------+
    | Try to find bank branch with given routing number   |
    +-----------------------------------------------------*/
    OPEN bank_branch_cur(l_routing_number);
    FETCH bank_branch_cur INTO bank_branch_rec;
    IF (bank_branch_cur%FOUND) then
      CLOSE bank_branch_cur;
      p_bank_branch_id := bank_branch_rec.bank_branch_id;
    ELSE
      CLOSE bank_branch_cur;
     /*------------------------------------------------------+
      | If bank branch could not be found, create new branch |
      +------------------------------------------------------*/
      insert_bank_branch(p_routing_number => p_routing_number,
                         p_bank_branch_id => p_bank_branch_id);
    END IF;

  EXCEPTION
  when OTHERS then
       RAISE;
  END get_bank_branch_id;

  --
  /*---------------------------------------------+
   |   Package initialization section.           |
   |   Sets WHO column variables for later use.  |
   +---------------------------------------------*/
BEGIN
    pg_user_id          := fnd_global.user_id;
    pg_login_id         := fnd_global.login_id;
    pg_prog_appl_id     := fnd_global.prog_appl_id;
        pg_program_id       := fnd_global.conc_program_id; /* J Rautiainen ACH Implementation */
        pg_request_id       := fnd_global.conc_request_id; /* J Rautiainen ACH Implementation */

END arp_bank_pkg;
/