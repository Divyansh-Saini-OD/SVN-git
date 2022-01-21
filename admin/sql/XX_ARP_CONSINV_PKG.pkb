CREATE OR REPLACE PACKAGE BODY XX_ARP_CONSINV AS
/* $Header: ARPCBIB.pls 120.27 2005/06/14 18:53:10 vcrisost ship $ */

/* bug2778646 : Added 'MERGE_PENDING','DRAFT_MERGE' and 'MERGED' status to
   correspond to customer merge as status of AR_CONS_INV_ALL table.

     MERGE_PENDING   -- Not merged yet. Next CBI has to pick up.
     DRAFT_MERGE -- Merged to new draft CBI. Other CBI cannot get it untill
                    the new draft CBI is rejected.
     MERGED  -- Merged to new accept CBI. Other CBI cannot get it.

   In merge process , ARCMCONB.pls updates customer_id , site_id and status of
   ar_cons_inv table. Update status to 'MERGED' except latest CBI.
   The ending_balance of latest CBI should be added to new customer site's CBI.
   The status of latest CBI is 'MERGE_PENDING'.

   In generic procedure, added up 'MERGE_PENDING' and latest 'ACCEPTED' CBI for
   beginning_balance.

   If create DRAFT CBI, status is from MERGE_PENDING to DRAFT_MERGE.
   If accecpt DRAFT CBI, status is from DRAFT_MERGE to MERGED.
   If reject DRAFT CBI , status is from DRAFT_MERGE to MERGE.
*/

/*----------------------------------------------------------------------------*
 | PROCEDURE                                                                  |
 |    reprint                                                                 |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    Update rows of consolidated billing invoice or rows associated with     |
 |    specified concurrent request id to print status of 'PENDING' so report  |
 |    ARXCBI will print them.                                                 |
 |                                                                            |
 | SCOPE - PRIVATE                                                            |
 |                                                                            |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                     |
 |                                                                            |
 | ARGUMENTS  : IN:                                                           |
 |                 P_consinv_id  -  consolidated billing invoice              |
 |                 P_request_id  -  concurrent request id                     |
 |              OUT:                                                          |
 |                   None                                                     |
 |                                                                            |
 | RETURNS    : NONE                                                          |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | MODIFICATION HISTORY                                                       |
 |                                                                            |
 *----------------------------------------------------------------------------*/
   PROCEDURE reprint (P_consinv_id IN NUMBER, P_request_id IN NUMBER) IS

   BEGIN
      UPDATE ar_cons_inv
      SET    print_status = 'PENDING',
             last_update_date = arp_global.last_update_date,
             last_updated_by = arp_global.last_updated_by,
             last_update_login = arp_global.last_update_login
      WHERE  cons_inv_id  = nvl(P_consinv_id, cons_inv_id)
      AND    concurrent_request_id = DECODE(P_consinv_id,
                                            NULL, P_request_id,
                                         concurrent_request_id);
   EXCEPTION
      WHEN OTHERS THEN
          arp_standard.debug( ' Exception: reprint: ');
          arp_standard.debug( ' P_consinv_id: '||P_consinv_id );
          arp_standard.debug( ' P_request_id: '||P_request_id );
          RAISE;
   END;

/*----------------------------------------------------------------------------*
 | PROCEDURE                                                                  |
 |    accept                                                                  |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    Updates rows for draft versions of consolidated billing invoices to     |
 |    status of 'PRINTED', from a prior status of 'DRAFT'                     |
 |                                                                            |
 | SCOPE - PRIVATE                                                            |
 |                                                                            |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                     |
 |                                                                            |
 | ARGUMENTS  : IN:                                                           |
 |                 P_consinv_id  -  Consolidated Billing Invoice id           |
 |                 P_request_id  -  Concurrent Request Id associated with     |
 |                                  rows that are to be accepted.             |
 |              OUT:                                                          |
 |                   None                                                     |
 |                                                                            |
 | RETURNS         : NONE                                                     |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | MODIFICATION HISTORY                                                       |
 |                                                                            |
 *----------------------------------------------------------------------------*/
   PROCEDURE accept (P_consinv_id IN NUMBER, P_request_id IN NUMBER) IS
     -- bug2778646 start
     TYPE tab_site_use_id IS TABLE OF ar_cons_inv_all.site_use_id%TYPE;
     TYPE tab_currency_code IS TABLE OF ar_cons_inv_all.currency_code%TYPE;
     TYPE tab_cut_off_date IS TABLE OF ar_cons_inv_all.cut_off_date%TYPE;

     l_site_use_id tab_site_use_id ;
     l_currency_code tab_currency_code;
     l_cut_off_date tab_cut_off_date ;

     CURSOR c_cons_inv IS
      SELECT site_use_id,
             currency_code,
             cut_off_date
        FROM ar_cons_inv
       WHERE cons_inv_id = nvl(P_consinv_id, cons_inv_id)
         AND concurrent_request_id = DECODE(P_consinv_id,
                                       NULL, P_request_id,
                                       concurrent_request_id)
         AND status = 'DRAFT' ;
     -- bug2778646 end

   BEGIN

     -- bug2778646 Added for merged customer's cbi.
     --            Change status from 'DRAFT_MERGE' to 'MERGED'
     OPEN c_cons_inv;
     FETCH c_cons_inv
        BULK COLLECT INTO
        l_site_use_id,
        l_currency_code,
        l_cut_off_date ;

     FORALL i IN 1..l_site_use_id.count
        UPDATE ar_cons_inv
        SET    status = 'MERGED',
               last_update_date = arp_global.last_update_date,
               last_updated_by = arp_global.last_updated_by,
               last_update_login = arp_global.last_update_login
        WHERE  status = 'DRAFT_MERGE'
        AND    site_use_id = l_site_use_id(i)
        AND    currency_code = l_currency_code(i)
        AND    cut_off_date <= l_cut_off_date(i) ;
     -- bug2778646 end

     UPDATE ar_cons_inv
     SET    status = 'ACCEPTED',
            last_update_date = arp_global.last_update_date,
            last_updated_by = arp_global.last_updated_by,
            last_update_login = arp_global.last_update_login
     WHERE  cons_inv_id = nvl(P_consinv_id, cons_inv_id)
     AND    concurrent_request_id = DECODE(P_consinv_id,
                                           NULL, P_request_id,
                                           concurrent_request_id)
     AND    status = 'DRAFT';
   EXCEPTION
     WHEN OTHERS THEN
         arp_standard.debug ( ' EXCEPTION: accept:' );
         arp_standard.debug ( ' P_consinv_id: '||P_consinv_id);
         arp_standard.debug ( ' P_request_id: '||P_request_id);
         RAISE;
   END;

/*----------------------------------------------------------------------------*
 | PROCEDURE                                                                  |
 |     reject                                                                 |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    Will delete the consolidated billing invoice or all consolidated        |
 |    billing invoices associated with the specified concurrent request id.   |
 |    All of the AR tables that have been updated with these consolidated     |
 |    billing invoice id's will be updated so that these deleted id's are     |
 |    no longer referenced.                                                   |
 |                                                                            |
 | SCOPE - PRIVATE                                                            |
 |                                                                            |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                     |
 |                                                                            |
 | ARGUMENTS  : IN:                                                           |
 |                 P_consinv_id  -  Consolidated Billing Invoice id           |
 |                 P_request_id  -  Concurrent Request Id                     |
 |              OUT:                                                          |
 |                   None                                                     |
 |                                                                            |
 | RETURNS    : NONE                                                          |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | MODIFICATION HISTORY                                                       |
 |                                                                            |
 | C M Clyde        28 Aug 97     Modified to include transaction types of    |
 |                                'XSITE XCURR RECAPP', 'XSITE XCURR RECREV', |
 |                                'XCURR RECAPP', 'XCURR RECREV'.             |
 |                                                                            |
 *----------------------------------------------------------------------------*/
   PROCEDURE reject (P_consinv_id  IN NUMBER, P_request_id IN NUMBER) IS

     -- bug2778646 start
     TYPE tab_site_use_id IS TABLE OF ar_cons_inv_all.site_use_id%TYPE;
     TYPE tab_currency_code IS TABLE OF ar_cons_inv_all.currency_code%TYPE;
     TYPE tab_cut_off_date IS TABLE OF ar_cons_inv_all.cut_off_date%TYPE;

     l_site_use_id tab_site_use_id ;
     l_currency_code tab_currency_code;
     l_cut_off_date tab_cut_off_date ;

     CURSOR c_cons_inv IS
      SELECT site_use_id,
             currency_code,
             cut_off_date
        FROM ar_cons_inv
       WHERE cons_inv_id = nvl(P_consinv_id, cons_inv_id)
         AND concurrent_request_id = DECODE(P_consinv_id,
                                       NULL, P_request_id,
                                       concurrent_request_id)
         AND status = 'DRAFT' ;
     -- bug2778646 end

   BEGIN
     UPDATE ra_customer_trx
     SET    printing_original_date =
                             DECODE(printing_count,
                                    1, NULL,
                                    printing_original_date),
            printing_last_printed =
                             DECODE(printing_count,
                                    1, NULL,
                                    printing_last_printed),
            printing_count = DECODE(printing_count,
                                    1, NULL,
                                    printing_count - 1)
     WHERE  customer_trx_id IN
              (SELECT PS.customer_trx_id
               FROM   ar_payment_schedules PS,
                      ar_cons_inv_trx IT,
                      ar_cons_inv CI
               WHERE  IT.transaction_type IN ('INVOICE','CREDIT_MEMO')
               AND    CI.cons_inv_id = IT.cons_inv_id
               AND    CI.cons_inv_id = nvl(P_consinv_id,CI.cons_inv_id)
               AND    CI.concurrent_request_id = DECODE (P_consinv_id,
                                                   NULL, P_request_id,
                                                   CI.concurrent_request_id)
               AND    CI.status      = 'DRAFT'
               AND    PS.payment_schedule_id = IT.adj_ps_id);

     UPDATE ar_payment_schedules
     SET    cons_inv_id = NULL
     WHERE  payment_schedule_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type IN ('INVOICE','CREDIT_MEMO',
                                              'RECEIPT')
               AND    CI.cons_inv_id = IT.cons_inv_id
               AND    CI.cons_inv_id = nvl(P_consinv_id, CI.cons_inv_id)
               AND    CI.concurrent_request_id = DECODE (P_consinv_id,
                                                   NULL, P_request_id,
                                                   CI.concurrent_request_id)
               AND    CI.status           = 'DRAFT');

     UPDATE ar_payment_schedules
     SET    cons_inv_id_rev = NULL
     WHERE  payment_schedule_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type = 'RECEIPT REV'
               AND    CI.cons_inv_id = IT.cons_inv_id
               AND    CI.cons_inv_id = nvl(P_consinv_id, CI.cons_inv_id)
               AND    CI.concurrent_request_id = DECODE(P_consinv_id,
                                                   NULL, P_request_id,
                                                   CI.concurrent_request_id)
               AND    CI.status      = 'DRAFT');


      /* bug2882196 : Added 'EXCLUDE RECREV' and 'EXCLUDE_CMREV' */
     UPDATE ar_receivable_applications
     SET    cons_inv_id = NULL
     WHERE  receivable_application_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type IN ('XSITE RECREV', 'XSITE_CMREV',
                                              'XCURR RECREV', 'XSITE XCURR RECREV',
                                              'EXCLUDE RECREV', 'EXCLUDE_CMREV')
               AND    CI.cons_inv_id      = IT.cons_inv_id
               AND    CI.cons_inv_id      = nvl(P_consinv_id, CI.cons_inv_id)
               AND    CI.concurrent_request_id = DECODE(P_consinv_id,
                                                   NULL, P_request_id,
                                                   CI.concurrent_request_id)
               AND    CI.status           = 'DRAFT');

      /* bug2882196 : Added 'EXCLUDE RECAPP' and 'EXCLUDE_CMAPP' */
     UPDATE ar_receivable_applications
     SET    cons_inv_id_to = NULL
     WHERE  receivable_application_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type IN ('XSITE RECAPP','XSITE_CMAPP',
                                              'XCURR RECAPP', 'XSITE XCURR RECAPP' ,
                                              'EXCLUDE RECAPP', 'EXCLUDE_CMAPP')
               AND    CI.cons_inv_id      = IT.cons_inv_id
               AND    CI.cons_inv_id      = nvl(P_consinv_id, CI.cons_inv_id)
               AND    CI.concurrent_request_id = DECODE(P_consinv_id,
                                                   NULL, P_request_id,
                                                   CI.concurrent_request_id)
               AND    CI.status           = 'DRAFT');

     UPDATE ar_adjustments
     SET    cons_inv_id = NULL
     WHERE  adjustment_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type = 'ADJUSTMENT'
               AND    CI.cons_inv_id      = IT.cons_inv_id
               AND    CI.cons_inv_id      = nvl(P_consinv_id, CI.cons_inv_id)
               AND    CI.concurrent_request_id = DECODE (P_consinv_id,
                                                   NULL, P_request_id,
                                                   CI.concurrent_request_id)
               AND    CI.status           = 'DRAFT');

     -- bug2778646 Added for merged customer's cbi.
     --            Changed status from 'DRAFT_MERGE' to 'MERGE_PENDING'
     OPEN c_cons_inv;
     FETCH c_cons_inv
        BULK COLLECT INTO
             l_site_use_id,
             l_currency_code,
             l_cut_off_date ;

     FORALL i IN 1..l_site_use_id.count
        UPDATE ar_cons_inv
        SET    status = 'MERGE_PENDING',
               last_update_date = arp_global.last_update_date,
               last_updated_by = arp_global.last_updated_by,
               last_update_login = arp_global.last_update_login
        WHERE  status = 'DRAFT_MERGE'
        AND    site_use_id = l_site_use_id(i)
        AND    currency_code = l_currency_code(i)
        AND    cut_off_date <= l_cut_off_date(i) ;
     -- bug2778646 end

     DELETE FROM ar_cons_inv_trx_lines
     WHERE  cons_inv_id IN
              (SELECT CI.cons_inv_id
               FROM   ar_cons_inv CI
               WHERE  CI.cons_inv_id = nvl(P_consinv_id, CI.cons_inv_id)
               AND    CI.concurrent_request_id = DECODE (P_consinv_id,
                                                   NULL, P_request_id,
                                                   CI.concurrent_request_id)
               AND    CI.status      = 'DRAFT');

     DELETE FROM ar_cons_inv_trx
     WHERE  cons_inv_id IN
              (SELECT CI.cons_inv_id
               FROM   ar_cons_inv CI
               WHERE  CI.cons_inv_id = nvl(P_consinv_id, CI.cons_inv_id)
               AND    CI.concurrent_request_id = DECODE (P_consinv_id,
                                                   NULL, P_request_id,
                                                   CI.concurrent_request_id)
               AND    CI.status      = 'DRAFT');

     UPDATE ar_cons_inv
     SET status       = 'REJECTED',
         print_status = 'PRINTED'
     WHERE  cons_inv_id           = nvl(P_consinv_id, cons_inv_id)
     AND    concurrent_request_id = DECODE(P_consinv_id,
                                      NULL, P_request_id,
                                      concurrent_request_id)
     AND    status                = 'DRAFT';

   EXCEPTION
     WHEN OTHERS THEN
       arp_standard.debug( ' Exception: reject: ');
       arp_standard.debug( 'P_consinv_id: '||P_consinv_id);
       arp_standard.debug( 'P_request_id: '||P_request_id);
       RAISE;
   END;

/*----------------------------------------------------------------------------*
 | PROCEDURE                                                                  |
 |    generate                                                                |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    Will create new Consolidated Billing Invoices for the specified user    |
 |    criteria.  It can either be in 'DRAFT' or 'PRINT'.                      |
 |                                                                            |
 | SCOPE - PRIVATE                                                            |
 |                                                                            |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                     |
 |                                                                            |
 | ARGUMENTS  : IN:                                                           |
 |                 P_print_option     - 'DRAFT' or 'PRINT'                    |
 |                 P_detail_option    - 'DETAIL' or 'SUMMARY'                 |
 |                 P_currency         -  Currency Code                        |
 |                 P_customer_id      -  Customer id                          |
 |                 P_customer_number  -  Customer number                      |
 |                 P_bill_to_site     -  Bill-to Site                         |
 |                 P_cutoff_date      -  Cut-off Date                         |
 |                 P_term_id          -  Payment Terms id                     |
 |            : OUT:                                                          |
 |                     None                                                   |
 |                                                                            |
 | RETURNS    : NONE                                                          |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | MODIFICATION HISTORY                                                       |
 |      05-AUG-97  Jack Martinez       bug 499781:                            |
 |                                     insert into ar_cons_inv_trx for type   |
 |                                     'XSITE RECAPP' should not negate amount|
 |      06-AUG-97  Jack Martinez       bug 522890:                            |
 |                                     ignore guarantees when collecting      |
 |                                     adjustments.  When an invoice is       |
 |                                     applied against a guarantee, a row is  |
 |                                     created in ar_adjustments and is       |
 |                                     applied against the payment schedule of|
 |                                     the guarantee.  When gathering adjust- |
 |                                     ments, ignore if the class of the      |
 |                                     related payment schedule is 'GUAR'.    |
 |     22-AUG-97   Jack Martinez       bug 531330:                            |
 |                                     patch 499781 incorrect. 'XSITE RECAPP' |
 |                                     should be negated. and 'XSITE RECREV'  |
 |                                     is not negated.                        |
 |     27-AUG-97   Jack Martinez       bug 536361:                            |
 |                                     amounts for credit memo should not be  |
 |                                     negated.                               |
 |     28-AUG-97   C M Clyde           Cross Currency functionality           |
 |                                     Modified to include transaction types  |
 |                                     of 'XSITE XCURR RECAPP',               |
 |                                     'XSITE XCURR RECREV', 'XCURR RECAPP',  |
 |                                     'XCURR RECREV'.                        |
 |     01-JUN-99  Frank Breslin        889478: Replaced the check to the terms|
 |                                     in the C_SITES cursor against the terms|
 |                                     parameter because we were losing the   |
 |                                     ability to only select customer sites  |
 |                                     with the given term.                   |
 |     08-JUL-99 Frank Breslin         857820: Implement the use of Last Day  |
 |                                     of Month type terms.                   |
 |     23-JUL-99 Frank Breslin         940744: Terms check in C_SITES was     |
 |                                     causing a problem when there was no    |
 |                                     term defined at the Bill To Site level.|
 |     25-AUG-99 Frank Breslin         919100: Modifed the cursor C_SITES in  |
 |                                     generate to specifically exclude       |
 |                                     Bill To sites with a terms code that   |
 |                                     does not have a day of month / months  |
 |                                     ahead type due day.                    |
 |     27-SEP-99 Frank Breslin         1006767: Changed all occurance of      |
 |                                     PS.class to PS.class||'' in the WHERE  |
 |                                     clause of SQL in the generate function |
 |                                     in order to supress the use of index   |
 |                                     AR_PAYMENT_SCHEDULES_N11.              |
 |    12-DEC-01 Hiroshi Yoshiahra      2134375: Added "+1" to C_cutoff_date   |
 |                                     of c_inv_trx cursor in generate        |
 |                                     procedure when P_last_day_of_month     |
 |                                     flag is 'Y' and C_cutoff_date is last  |
 |                                     day of month.                          |
 |    06-SEP-02 Hiroshi Yoshiahra      2501071: Created c_types cursor to     |
 |                                     fix cartesian join of c_sites cursor.  |
 |    07-NOV-02 Hiroshi Yoshiahra      2656229: Added codition to c_sites cursor
 |    19-Nov-02 Sahana                 2650786: Corrected a typo in           |
 |                                     Consolidated Bill Transaction Types.   |
 |                                     Used XCURR RECREV and XSITE XCURR RECREV
 |                                     instead of XCURR RECREC and XSITE      |
 |                                     XCURR RECREC in the update statement for
 |                                     ar_receivable_applications table       |
 |    13-Dec-02 Sahana Shetty          Bug2677085: Period receipt amounts     |
 |                                     were calculated incorrectly when       |
 |                                     receipt location was filled in after   |
 |                                     applications were made to invoices.    |
 |    25-DEC-02 Hiroshi Yoshiahra      2700662: Removed link to ra_customer_trx
 |                                     table from sub-query of two insert stmts,
 |                                     one is for XSITE_CMREV,other is for    |
 |                                     XSITE_CMAPP.                           |
 |    09-JUN-05 V Crisostomo           Bug 4367354: SSA, add org_id to inserts|
 |    30-NOV-15 Vasu Raparla           Removed Schema References for R.12.2   |
 *----------------------------------------------------------------------------*/
   PROCEDURE generate (P_print_option         IN VARCHAR2,
                       P_detail_option        IN VARCHAR2,
                       P_currency             IN VARCHAR2,
                       P_customer_id          IN NUMBER,
                       P_customer_number      IN VARCHAR2,
                       P_bill_to_site         IN NUMBER,
                       P_cutoff_date          IN DATE,
                       P_last_day_of_month    IN VARCHAR2,
                       P_interim_cut_off_date IN DATE,  --Added for defect # 6693 ??
                       P_term_id              IN NUMBER) IS
     l_cutoff_day  NUMBER(15);
     l_beginning_balance NUMBER;
     l_consinv_id  NUMBER;
     l_consinv_lineno NUMBER(15);
     l_cons_billno VARCHAR2(30);
     l_new_billed NUMBER;
     l_period_receipts NUMBER;
     l_due_date DATE;
     l_due_last_day_of_month DATE;
     -- bug2434295
     l_real_cutoff_date DATE;

     ln_org_id   NUMBER := FND_PROFILE.VALUE('ORG_ID');                --Added for Defect #4422

     -- bug2501071 : Created to fix cartesian join of c_sites
     CURSOR C_types (C_cutoff_day NUMBER, C_term_id NUMBER) IS
     SELECT T.term_id   term_id ,
            TL1.due_day_of_month       day_due,
            TL1.due_months_forward     months_forward
     FROM   ra_terms   T,
            ra_terms_lines  TL1
     WHERE  TL1.term_id            = T.term_id
     AND    T.term_id              = nvl(C_term_id, T.term_id)
     AND    T.due_cutoff_day       = C_cutoff_day
     AND    TL1.due_day_of_month   IS NOT NULL
     AND    TL1.due_months_forward IS NOT NULL
     AND    1                      = (select count(*)
                                        from ra_terms_lines TL2
                                       where TL2.term_id = TL1.term_id) ;

     /* bug2892106 Broke up this stmt into 3 stmt based on parameter.
     -- bug2501071 : Moved ra_terms/(_lines) to c_types in order to
     --              fix cartesian join
     -- bug2656229 : Added NOT EXISTS condition to prevent from data corruption
     CURSOR C_sites (C_detail_option VARCHAR, C_customer_id NUMBER,
                     C_site_use_id   NUMBER,  C_cutoff_date DATE,
                     C_term_id NUMBER ) IS
     SELECT
            CP.cust_account_id customer_id,
            site_uses.site_use_id  site_id,
            acct_site.cust_acct_site_id,
            nvl(SP.cons_inv_type,
               nvl(CP.cons_inv_type,'SUMMARY'))         cons_inv_type
     FROM
            hz_cust_accounts     cust_acct,
            hz_customer_profiles CP,
            hz_customer_profiles SP,
            hz_cust_site_uses    site_uses,
            hz_cust_acct_sites   acct_site
     WHERE
            site_uses.site_use_code    = 'BILL_TO'
     AND    site_uses.site_use_id    = nvl(C_site_use_id, site_uses.site_use_id)
     AND    SP.site_use_id(+)      = site_uses.site_use_id
     AND    acct_site.cust_acct_site_id = site_uses.cust_acct_site_id
     AND    cust_acct.cust_account_id         = acct_site.cust_account_id
     AND    cust_acct.account_number = nvl(P_customer_number,cust_acct.account_number)
     AND    CP.cust_account_id         = cust_acct.cust_account_id
     AND    CP.site_use_id         IS NULL
     AND    C_term_id              = nvl(site_uses.payment_term_id,
                                         nvl(SP.standard_terms,
                                             CP.standard_terms))
     AND    nvl(SP.cons_inv_flag,
                CP.cons_inv_flag)  = 'Y'
     AND    nvl(SP.cons_inv_type,
                nvl(CP.cons_inv_type,
                    'SUMMARY'))    = C_detail_option
     AND    NOT EXISTS
               (SELECT NULL
                FROM ar_cons_inv CI
                WHERE CI.site_use_id = site_uses.site_use_id
                AND CI.cut_off_date  = to_date(C_cutoff_date)
                AND CI.currency_code = P_currency
                AND CI.status <> 'REJECTED')
     AND    NOT EXISTS
               (SELECT NULL
                FROM ar_cons_inv CI2
                WHERE CI2.site_use_id = site_uses.site_use_id
                AND CI2.currency_code = P_currency
                AND CI2.status = 'DRAFT') ;
     */

     CURSOR  C_inv_trx (C_site_use_id NUMBER, C_cutoff_date DATE) IS
     SELECT
            CT.customer_trx_id            trx_id,
            CT.trx_date                   trx_date,
            CT.trx_number                 trx_number,
            PS.class                      class,
            PS.payment_schedule_id        schedule_id,
            PS.amount_due_original        amount_due,
            PS.tax_original               tax,
            PS.invoice_currency_code      currency
     FROM
            ra_customer_trx   CT,
            ar_payment_schedules PS
     WHERE
            PS.customer_site_use_id  = C_site_use_id
     AND    PS.cons_inv_id IS NULL
     AND    PS.invoice_currency_code = P_currency
     AND    CT.customer_trx_id       = PS.customer_trx_id
     AND    CT.trx_date              < C_cutoff_date
     /*  bug2434295 C_cutoff_date was already calculated.
                        + decode(C_last_day_of_month, 'Y',
                                decode(C_cutoff_date, Last_day(C_cutoff_date),
                                        1 , 0) , 0 ) -- bug2134375
     */
     AND    PS.class||'' IN ('INV', 'DM', 'CM', 'DEP', 'CB')
     AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y' -- bug2882196
     ORDER BY PS.trx_date, PS.customer_trx_id;

     --  bug2892106 Added new cursor variable
     TYPE c_sites_type  IS REF CURSOR ;
     C_sites C_sites_type ;

     --  bug2892106 Added new record variable because cannot use cursor
     --             variable in FOR LOOP.
     -- Bug 7205906 Added term details variable.
     TYPE L_sites_type IS RECORD
       ( customer_id  NUMBER ,
         site_id  NUMBER);
     L_sites L_sites_type ;

     -- bug2892106 Removed cons_inv_type column from select stmt because
     --            it must be same value with P_detal_option.
     C_detail_option hz_customer_profiles.cons_inv_type%TYPE;

     -- bug3039537
     -- Calculate all tax amount and inclusive tax amount
     TYPE tab_line_id IS TABLE OF ra_customer_trx_lines_all.link_to_cust_trx_line_id%TYPE;
     TYPE tab_num IS TABLE OF NUMBER ;

     l_line_id tab_line_id ;
     l_tax_sum tab_num ;
     l_include_tax_sum tab_num ;

     l_bulk_fetch_rows  NUMBER := 10000 ;

     CURSOR c_tax (l_trx_id NUMBER)
     IS
       SELECT link_to_cust_trx_line_id,
         sum(nvl(CTL.extended_amount,0)),
         sum(decode(amount_includes_tax_flag, 'Y', nvl(CTL.extended_amount,0),0))
       FROM  ra_customer_trx_lines  CTL
       WHERE  CTL.customer_trx_id = l_trx_id
         AND  CTL.line_type = 'TAX'
       GROUP BY link_to_cust_trx_line_id;
     -- bug3039537

   BEGIN

     -- bug2892106
     C_detail_option := nvl(P_detail_option, 'SUMMARY') ;

/* Use for debugging...
dbms_output.put_line('And so it begins...');
dbms_output.put_line('P_print_option     : '||P_print_option);
dbms_output.put_line('P_detail_option    : '||P_detail_option);
dbms_output.put_line('P_currency         : '||P_currency);
dbms_output.put_line('P_customer_id      : '||TO_CHAR(P_customer_id));
dbms_output.put_line('P_customer_number  : '||P_customer_number);
dbms_output.put_line('P_bill_to_site     : '||TO_CHAR(p_bill_to_site));
dbms_output.put_line('P_cutoff_date      : '||TO_CHAR(P_cutoff_date));
dbms_output.put_line('P_last_day_of_month: '||P_last_day_of_month);
dbms_output.put_line('P_term_id          : '||TO_CHAR(P_term_id));
*/


/** need day of month of cut-off date to match against ra_terms.            **/
     l_cutoff_day := P_cutoff_date -
                             trunc(P_cutoff_date,'MONTH') + 1;
/*
857820: If P_last_day_of_month = 'Y' then use last day of month type terms
*/

     if P_last_day_of_month = 'Y' then
        l_cutoff_day := 32;

     /* 2434295 start
        P_cutoff_date is not real cutoff date when p_last_day_of_month
        is 'Y' and P_cutoff_date is last day of month. In this case,
        should add 1 to P_cutoff_date for selecting invoices , adjustments
        and receipts.
      */
        if P_cutoff_date = Last_day(P_cutoff_date) then
           l_real_cutoff_date := P_cutoff_date + 1 ;
        else
           l_real_cutoff_date := P_cutoff_date;
        end if;

     else
        l_real_cutoff_date := P_cutoff_date;

    /* bug2434295 end */

     end if;

/* Use for debugging
dbms_output.put_line('Parameters for L_sites cursor open...');
dbms_output.put_line('P_detail_option :'||P_detail_option);
dbms_output.put_line('P_customer_id   :'||TO_CHAR(P_customer_id));
dbms_output.put_line('P_bill_to_site  :'||TO_CHAR(P_bill_to_site));
dbms_output.put_line('P_cutoff_date   :'||TO_CHAR(P_cutoff_date));
dbms_output.put_line('L_cutoff_day    :'||TO_CHAR(l_cutoff_day));
dbms_output.put_line('P_term_id       :'||TO_CHAR(P_term_id));
*/

     -- bug2501071 : Added c_types LOOP
     FOR L_types IN C_types(l_cutoff_day, p_term_id ) LOOP

     /* bug2892106 Removed
     FOR L_sites IN C_sites(P_detail_option, P_customer_id,
                            P_bill_to_site,  P_cutoff_date,
                            L_types.term_id) LOOP
     */

     -- bug2892106 These are 3 stmt instead of previous c_sites cursor
     IF P_customer_id is not null THEN

        IF P_bill_to_site is not null THEN

           -- with customer and site id
           OPEN C_sites FOR
              SELECT /*+ ORDERED */
                    P_customer_id customer_id ,
                    P_bill_to_site site_id
              FROM
                    hz_cust_site_uses    site_uses,
                    hz_customer_profiles CP,
                    hz_customer_profiles SP
              WHERE
                     site_uses.site_use_id    = P_bill_to_site
              AND    CP.cust_account_id         = P_customer_id
              AND    CP.site_use_id         IS NULL
              AND    SP.site_use_id(+) = site_uses.site_use_id
              AND    L_types.term_id   = nvl(site_uses.payment_term_id,
                                          nvl(SP.standard_terms,CP.standard_terms))
              AND    nvl(SP.cons_inv_flag, CP.cons_inv_flag) = 'Y'
              AND    nvl(nvl(SP.cons_inv_type,CP.cons_inv_type),'SUMMARY')
                            = C_detail_option
              AND    NOT EXISTS
                        (SELECT NULL
                         FROM ar_cons_inv CI
                         WHERE CI.site_use_id = site_uses.site_use_id
                         -- bug3129948 added '>'
                         AND CI.cut_off_date  >=P_cutoff_date
                         AND CI.currency_code = P_currency
                         AND CI.status <> 'REJECTED')
              AND    NOT EXISTS
                        (SELECT NULL
                         FROM ar_cons_inv CI2
                         WHERE CI2.site_use_id = site_uses.site_use_id
                         AND CI2.currency_code = P_currency
                         AND CI2.status = 'DRAFT') ;
        ELSE

           -- with customer id only
           OPEN C_sites FOR
              SELECT /*+ ORDERED */
                     P_customer_id customer_id ,
                     site_uses.site_use_id  site_id
              FROM
                     hz_cust_acct_sites   acct_site,
                     hz_cust_site_uses    site_uses,
                     hz_customer_profiles CP,
                     hz_customer_profiles SP
              WHERE
                     acct_site.cust_account_id = P_customer_id
              AND    site_uses.cust_acct_site_id = acct_site.cust_acct_site_id
              AND    site_uses.site_use_code    = 'BILL_TO'
              AND    CP.cust_account_id         = P_customer_id
              AND    CP.site_use_id         IS NULL
              AND    SP.site_use_id(+) = site_uses.site_use_id
              AND    L_types.term_id   = nvl(site_uses.payment_term_id,
                                          nvl(SP.standard_terms,CP.standard_terms))
              AND    nvl(SP.cons_inv_flag, CP.cons_inv_flag) = 'Y'
              AND    nvl(nvl(SP.cons_inv_type,CP.cons_inv_type),'SUMMARY')
                            = C_detail_option
              AND    NOT EXISTS
                        (SELECT NULL
                         FROM ar_cons_inv CI
                         WHERE CI.site_use_id = site_uses.site_use_id
                         -- bug3129948 added '>'
                         AND CI.cut_off_date  >=P_cutoff_date
                         AND CI.currency_code = P_currency
                         AND CI.status <> 'REJECTED')
              AND    NOT EXISTS
                        (SELECT NULL
                         FROM ar_cons_inv CI2
                         WHERE CI2.site_use_id = site_uses.site_use_id
                         AND CI2.currency_code = P_currency
                         AND CI2.status = 'DRAFT') ;
        END IF ;

     ELSE

        -- without customer and site id


        OPEN C_sites FOR
           SELECT
                  acct_site.cust_account_id customer_id ,
                  site_uses.site_use_id  site_id
           FROM
                  hz_cust_acct_sites   acct_site,
                  hz_cust_site_uses    site_uses,
                  hz_customer_profiles CP,
                  hz_customer_profiles SP,
                  xx_ar_interim_cust_acct_id xaic
           WHERE
                  site_uses.cust_acct_site_id = acct_site.cust_acct_site_id
           AND    site_uses.site_use_code    = 'BILL_TO'
           AND    CP.cust_account_id         = acct_site.cust_account_id
           AND    xaic.cust_account_id = acct_site.cust_account_id                 --Added on 5/21/2010 for Defect #4422
           AND    xaic.org_id = ln_org_id                                          --Added on 5/21/2010 for Defect #4422
           AND    CP.site_use_id         IS NULL
           AND    SP.site_use_id(+) = site_uses.site_use_id
           AND    L_types.term_id   = nvl(site_uses.payment_term_id,
                                       nvl(SP.standard_terms,CP.standard_terms))
           AND    nvl(SP.cons_inv_flag, CP.cons_inv_flag) = 'Y'
           AND    nvl(nvl(SP.cons_inv_type,CP.cons_inv_type),'SUMMARY')
                         = C_detail_option
           AND    NOT EXISTS
                     (SELECT NULL
                      FROM ar_cons_inv CI
                      WHERE CI.site_use_id = site_uses.site_use_id
                      -- bug3129948 added '>'
                      --AND CI.cut_off_date  >= P_cutoff_date                      -- Commented for Defect #6693 on 06-JUL-10
                      AND CI.cut_off_date  >= P_interim_cut_off_date                -- Added for Defect #6693 on 06-JUL-10
                      AND CI.currency_code = P_currency
                      AND CI.status <> 'REJECTED')
           AND    NOT EXISTS
                     (SELECT NULL
                      FROM ar_cons_inv CI2
                      WHERE CI2.site_use_id = site_uses.site_use_id
                      AND CI2.currency_code = P_currency
                      AND CI2.status = 'DRAFT') ;
      END IF;



      LOOP

        FETCH C_sites INTO L_sites;
        EXIT WHEN C_sites%NOTFOUND;
      -- bug2892106

/* Use for debugging ...
dbms_output.put_line(' ');
dbms_output.put_line('Process a row from cursor C_SITES');
dbms_output.put_line('customer_id    : '||TO_CHAR(L_SITES.customer_id));
dbms_output.put_line('site_id        : '||TO_CHAR(L_SITES.site_id));
dbms_output.put_line('term_id        : '||TO_CHAR(L_SITES.term_id));
dbms_output.put_line('address_id     : '||TO_CHAR(L_SITES.cust_acct_site_id));
dbms_output.put_line('cons_inv_type  : '||L_SITES.cons_inv_type);
dbms_output.put_line('day_due        : '||TO_CHAR(L_SITES.day_due));
dbms_output.put_line('months_forward : '||TO_CHAR(L_SITES.months_forward));
*/

/** For site: process invoices first, add invoice detail.                   **/

       l_consinv_lineno := 1;

/** For Site: get next billing invoice id, create header with zero totals.**/

       SELECT ar_cons_inv_s.NEXTVAL INTO l_consinv_id FROM dual;
       l_cons_billno := to_char(l_consinv_id);

/** calculate due date                                                      **/

       l_due_date := add_months(trunc(P_cutoff_date,'month'),
                            nvl(L_types.months_forward,0))+L_types.day_due-1;

/** if the due day is 29 or greater, it is possible that the due month does
    not have that many days, so will need to use last day of month instead  **/

       l_due_last_day_of_month :=
                     add_months(trunc(P_cutoff_date,'month'),
                             nvl(L_types.months_forward,0)+1)-1;

       IF l_due_date > l_due_last_day_of_month
          THEN l_due_date := l_due_last_day_of_month;
       END IF;

/** get beginning balance for new billing invoice from prior billing invoice**/
/** bug 632412: do not use term_id in where clause and subquery in case the **/
/**             terms code was changed for the site.                        **/

       BEGIN

         /* bug2778646 Modified this select stmt to get balance of merged cbi.
         SELECT  sum(ending_balance)
         INTO    l_beginning_balance
         FROM    ar_cons_inv CI1
         WHERE   CI1.site_use_id   = L_sites.site_id
         AND     CI1.currency_code = P_currency
         AND     CI1.status       <> 'REJECTED'
         AND     CI1.cut_off_date  =
                             (SELECT max(CI2.cut_off_date)
                              FROM   ar_cons_inv CI2
                              WHERE  CI2.site_use_id   = L_sites.site_id
                              AND    CI2.currency_code = P_currency
                              AND    CI2.cut_off_date  < P_cutoff_date
                              AND    CI2.status       <> 'REJECTED');
         */

         SELECT  sum(ending_balance)
         INTO    l_beginning_balance
         FROM    ar_cons_inv CI1
         WHERE   CI1.site_use_id   = L_sites.site_id
         AND     CI1.currency_code = P_currency
         AND    ((CI1.status       = 'ACCEPTED'
                  AND     CI1.cut_off_date  =
                             (SELECT max(CI2.cut_off_date)
                              FROM   ar_cons_inv CI2
                              WHERE  CI2.site_use_id   = L_sites.site_id
                              AND    CI2.currency_code = P_currency
                              AND    CI2.cut_off_date  < P_cutoff_date
                              AND    CI2.status       = 'ACCEPTED'))
              OR (CI1.status = 'MERGE_PENDING'
                  AND CI1.cut_off_date <= P_cutoff_date) );

       EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_beginning_balance := 0;
       END;

/** For Site: create header.                                                **/
/**           note it is possible that only the header will created if no   **/
/**           transactions are found.                                       **/
       INSERT INTO ar_cons_inv (cons_inv_id,
                                cons_billing_number,
                                customer_id,
                                site_use_id,
                                concurrent_request_id,
                                last_update_date,
                                last_updated_by,
                                creation_date,
                                created_by,
                                last_update_login,
                                cons_inv_type,
                                status,
                                print_status,
                                term_id,
                                issue_date,
                                cut_off_date,
                                due_date,
                                currency_code,
                                beginning_balance,
                                ending_balance,
                                org_id)
       VALUES                  (l_consinv_id,
                                l_cons_billno,
                                L_sites.customer_id,
                                L_sites.site_id,
                                arp_standard.profile.request_id,
                                arp_global.last_update_date,
                                arp_global.last_updated_by,
                                arp_global.creation_date,
                                arp_global.created_by,
                                arp_global.last_update_login,
                                C_detail_option,
                                DECODE(P_print_option,
                                       'DRAFT', 'DRAFT',
                                       'ACCEPTED'),
                               'PENDING',
                                L_types.term_id,
                                sysdate,
                                P_cutoff_date,
                                l_due_date,
                                P_currency,
                                nvl(l_beginning_balance,0),
                                0,
                                arp_standard.sysparm.org_id);

/** For Site: process invoices, credit memos. Need loop to assign line no.  **/
/** 536361 - do not negate credit memo amounts.                             **/
       l_consinv_lineno := 1;

/* Use for debugging
dbms_output.put_line('Parameters to cursor C_INV_TRX...');
dbms_output.put_line('L_sites.site_id :'||TO_CHAR(L_sites.site_id));
dbms_output.put_line('P_cutoff_date   :'||TO_CHAR(P_cutoff_date));
*/
/* bug2134375 Added P_last_day_of_month argument */
/* bug2434295 Removed P_last_day_of_month argument
              Changed P_cutoff_date to l_real_cutoff_date */
       FOR L_inv_trx IN C_inv_trx(L_sites.site_id, l_real_cutoff_date ) LOOP
/* Use for debugging
dbms_output.put_line('process a row from CURSOR C_INV_TRX...');
dbms_output.put_line('trx_id     :'||TO_CHAR(l_inv_trx.trx_id));
dbms_output.put_line('trx_date   :'||TO_CHAR(l_inv_trx.trx_date));
dbms_output.put_line('trx_number :'||l_inv_trx.trx_number);
*/

         INSERT INTO ar_cons_inv_trx (cons_inv_id,
                                      transaction_type,
                                      trx_number,
                                      transaction_date,
                                      amount_original,
                                      tax_original,
                                      adj_ps_id,
                                      cons_inv_line_number,
                                      org_id)
         VALUES                      (l_consinv_id,
                                      DECODE(L_inv_trx.class,
                                             'CM','CREDIT_MEMO',
                                             'INVOICE'),
                                      L_inv_trx.trx_number,
                                      L_inv_trx.trx_date,
                                      L_inv_trx.amount_due,
                                      L_inv_trx.tax,
                                      L_inv_trx.schedule_id,
                                      l_consinv_lineno,
                                      arp_standard.sysparm.org_id);


/** For audit purposes, insert detail line information even if reporting    **/
/**    in summary.                                                          **/
/** also note that cons_inv_line_number is one value for detail lines for
/**    a specific invoice.                                                  **/

         /* Bug 586099: For credit memo, quantity is stored in
            quantity_credited rather than quantity_invoiced. */
         IF (L_inv_trx.class = 'CM') THEN
           INSERT INTO ar_cons_inv_trx_lines (cons_inv_id,
                                              cons_inv_line_number,
                                              customer_trx_id,
                                              customer_trx_line_id,
                                              line_number,
                                              inventory_item_id,
                                              description,
                                              uom_code,
                                              quantity_invoiced,
                                              unit_selling_price,
                                              extended_amount,
                                              tax_amount,
                                              org_id)
           SELECT
                  l_consinv_id,
                  l_consinv_lineno,
                  customer_trx_id,
                  customer_trx_line_id,
                  line_number,
                  inventory_item_id,
                  description,
                  uom_code,
                  quantity_credited,
                  nvl (gross_unit_selling_price, unit_selling_price),
                  nvl (gross_extended_amount, extended_amount),
                  0,
                  org_id
           FROM
                  ra_customer_trx_lines
           WHERE
                  customer_trx_id  = L_inv_trx.trx_id
           AND    line_type NOT IN ('TAX', 'FREIGHT');

         ELSE
           INSERT INTO ar_cons_inv_trx_lines (cons_inv_id,
                                              cons_inv_line_number,
                                              customer_trx_id,
                                              customer_trx_line_id,
                                              line_number,
                                              inventory_item_id,
                                              description,
                                              uom_code,
                                              quantity_invoiced,
                                              unit_selling_price,
                                              extended_amount,
                                              tax_amount,
                                              org_id)
           SELECT
                  l_consinv_id,
                  l_consinv_lineno,
                  customer_trx_id,
                  customer_trx_line_id,
                  line_number,
                  inventory_item_id,
                  description,
                  uom_code,
                  quantity_invoiced,
                  nvl (gross_unit_selling_price, unit_selling_price),
                  nvl (gross_extended_amount, extended_amount),
                  0,
                  org_id
           FROM
                  ra_customer_trx_lines
           WHERE
                  customer_trx_id  = L_inv_trx.trx_id
           AND    line_type NOT IN ('TAX', 'FREIGHT');
         END IF;

/** now update lines with associated tax line **/
         /* bug3039537 : Removed
         UPDATE ar_cons_inv_trx_lines  TL
                set TL.tax_amount =
                    (SELECT sum(nvl(CTL.extended_amount,0))
                     FROM   ra_customer_trx_lines  CTL
                     WHERE  CTL.link_to_cust_trx_line_id =
                                TL.customer_trx_line_id
                     AND    CTL.line_type = 'TAX')
                WHERE
                     TL.customer_trx_id = L_inv_trx.trx_id;
         */

         -- bug3039537
         -- Get all tax total amount and inclusive tax total amount
         OPEN c_tax(L_inv_trx.trx_id);
         LOOP
           FETCH c_tax BULK COLLECT INTO
             l_line_id , l_tax_sum, l_include_tax_sum LIMIT l_bulk_fetch_rows;

           -- 1. Update tax_amount
           -- 2. Exclude inclusive tax amount total from extended_amount
           FORALL i IN 1..l_line_id.count
             UPDATE ar_cons_inv_trx_lines
             SET tax_amount = l_tax_sum(i),
                 extended_amount = extended_amount - l_include_tax_sum(i)
             WHERE customer_trx_id = L_inv_trx.trx_id /*4375045*/
                        AND
                     customer_trx_line_id = l_line_id(i) ;

           EXIT WHEN c_tax%NOTFOUND ;
         END LOOP;
         CLOSE c_tax;

/** now create 1 summary row for freight **/
         INSERT INTO ar_cons_inv_trx_lines (cons_inv_id,
                                            cons_inv_line_number,
                                            customer_trx_id,
                                            customer_trx_line_id,
                                            line_number,
                                            inventory_item_id,
                                            description,
                                            uom_code,
                                            quantity_invoiced,
                                            unit_selling_price,
                                            extended_amount,
                                            tax_amount,
                                            org_id)
         SELECT
               l_consinv_id,
               l_consinv_lineno,
               max(customer_trx_id),
               max(customer_trx_line_id),
               max(line_number),
               NULL,
               'Freight',
               NULL,
               1,
               sum (nvl (gross_extended_amount, extended_amount)),
               sum (nvl (gross_extended_amount, extended_amount)),
               0,
               org_id
         FROM
               ra_customer_trx_lines
         WHERE
               customer_trx_id = L_inv_trx.trx_id
         AND   line_type = 'FREIGHT'
         GROUP BY line_type,org_id;

         l_consinv_lineno := l_consinv_lineno + 1;

       END LOOP;

/** For site: adjustments                                                   **/
/** bug 522890 - ignore guarantees.  When an invoice is applied against a   **/
/**              guarantee, an adjustment row is created and is applied     **/
/**              against the payment schedule of the guarantee.  When       **/
/**              gathering adjustments, check the class of the related      **/
/**              payment schedule and omit if class = 'GUAR'.               **/

/*
1357024 fbreslin put AR_ADJUSTMENTS.tax_adjusted into AR_CONS_INV.TAX_ORIGINAL
*/

/*
1340426 fbreslin: Only include approved adjustments
*/

/* bug2882196 : Added exclude_from_cons_bill_flag condition not to get legacy
                transactions. */
/* bug2922922 : Added hint */


       INSERT INTO ar_cons_inv_trx (cons_inv_id,
                                    transaction_type,
                                    trx_number,
                                    transaction_date,
                                    amount_original,
                                    tax_original,
                                    adj_ps_id,
                                    cons_inv_line_number,
                                    org_id)
       SELECT /*+ index (PS AR_PAYMENT_SCHEDULES_N5) */
              l_consinv_id,
              'ADJUSTMENT',
              PS.trx_number,
              RA.gl_date,
              RA.amount,
              NVL(RA.tax_adjusted, 0),
              RA.adjustment_id,
              NULL,
              ps.org_id
       FROM
              ar_adjustments RA,
              ar_payment_schedules PS
       WHERE
              RA.cons_inv_id is NULL
/* bug2434295 Changed P_cutoff_date to l_real_cutoff_date */
       AND    RA.gl_date              < l_real_cutoff_date
       AND    RA.type in ('CHARGES','FREIGHT','INVOICE','LINE','TAX')
       AND    RA.status = 'A'
       AND    PS.payment_schedule_id   = RA.payment_schedule_id
       AND    PS.customer_site_use_id  = L_sites.site_id
       AND    PS.invoice_currency_code = P_currency
       AND    PS.class||''             <> 'GUAR'
       AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
       AND    1=2;  -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

/** For Site: cash receipts.                                                **/
/* bug2882196 : Added exclude_from_cons_bill_flag condition not to get legacy
                receipts. */
       INSERT INTO ar_cons_inv_trx (cons_inv_id,
                                    transaction_type,
                                    trx_number,
                                    transaction_date,
                                    amount_original,
                                    tax_original,
                                    adj_ps_id,
                                    cons_inv_line_number,
                                    org_id)
       SELECT
              l_consinv_id,
              'RECEIPT',
              PS.trx_number,
              CR.receipt_date,
              PS.amount_due_original,
              NULL,
              PS.payment_schedule_id,
              NULL,
              PS.org_id
       FROM
              ar_payment_schedules PS,
              ar_cash_receipts CR
       WHERE
              PS.customer_site_use_id  = L_sites.site_id
       AND    PS.cons_inv_id           IS NULL
       AND    PS.class||''             = 'PMT'
       AND    PS.invoice_currency_code = P_currency
       AND    CR.cash_receipt_id       = PS.cash_receipt_id
/* bug2434295 Changed P_cutoff_date to l_real_cutoff_date */
       AND    CR.receipt_date          < l_real_cutoff_date
       AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

/** For Site: cash receipts reversals.                                      **/
/* bug2882196 : Added exclude_from_cons_bill_flag condition not to get legacy
                receipts. */
       INSERT INTO ar_cons_inv_trx (cons_inv_id,
                                    transaction_type,
                                    trx_number,
                                    transaction_date,
                                    amount_original,
                                    tax_original,
                                    adj_ps_id,
                                    cons_inv_line_number,
                                    org_id)
       SELECT
              l_consinv_id,
              'RECEIPT REV',
              PS.trx_number,
              CR.reversal_date,
              (-1)*PS.amount_due_original,
              NULL,
              PS.payment_schedule_id,
              NULL,
              CR.org_id
       FROM
              ar_payment_schedules PS,
              ar_cash_receipts CR
       WHERE
              PS.customer_site_use_id  = L_sites.site_id
       AND    PS.cons_inv_id_rev       IS NULL
       AND    PS.invoice_currency_code = P_currency
       AND    PS.class||''             = 'PMT'
       AND    CR.cash_receipt_id       = PS.cash_receipt_id
/* bug2434295 Changed P_cutoff_date to l_real_cutoff_date */
       AND    CR.reversal_date         < l_real_cutoff_date
       AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

/** For Site: need to reverse cash receipts if applied to a different       **/
/**    bill-to.                                                             **/
/** 531330 - changed '(-1)*RA.amount_applied' to 'RA.amount_applied         **/
/** Cross Currency functionality implemented.                               **/
/* bug2882196 : Added 'EXCLUDE RECREV' for when applied to legacy invoices  */

       INSERT INTO ar_cons_inv_trx (cons_inv_id,
                                    transaction_type,
                                    trx_number,
                                    transaction_date,
                                    amount_original,
                                    tax_original,
                                    adj_ps_id,
                                    cons_inv_line_number,
                                    org_id)
       SELECT
              l_consinv_id,
              DECODE (nvl(ps_inv.exclude_from_cons_bill_flag, 'N'), 'Y','EXCLUDE RECREV',
              DECODE (nvl (ps_cash.customer_site_use_id, -1), ps_inv.customer_site_use_id,
                      DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
                              'XXXXXXXXXX', 'XCURR RECREV'),
                      DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
                              'XSITE RECREV', 'XSITE XCURR RECREV')) ),
              ps_cash.trx_number,
              RA.apply_date,
              nvl (ra.amount_applied_from, RA.amount_applied),
              NULL,
              RA.receivable_application_id,
              NULL,
              ps_cash.org_id
       FROM
              ar_receivable_applications RA,
              ar_payment_schedules ps_cash,
              ar_payment_schedules ps_inv
       WHERE
              RA.cons_inv_id IS NULL
       AND    RA.status                     = 'APP'
       AND    RA.application_type           = 'CASH'
/* bug2434295 Changed P_cutoff_date to l_real_cutoff_date */
       AND    RA.apply_date                < l_real_cutoff_date
       AND    ps_cash.payment_schedule_id   = RA.payment_schedule_id
       AND    ps_cash.customer_site_use_id  = L_sites.site_id
       AND    ps_cash.invoice_currency_code = P_currency
       AND    ps_inv.payment_schedule_id    = RA.applied_payment_schedule_id
       AND    nvl(ps_cash.exclude_from_cons_bill_flag, 'N') <> 'Y'
       AND   (   ps_cash.customer_site_use_id  <> ps_inv.customer_site_use_id
              OR ra.amount_applied_from IS NOT NULL
              OR nvl(ps_inv.exclude_from_cons_bill_flag, 'N') = 'Y')
       AND    1=2;  -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

/*Bug2677085- Added a select statement to pick up those applications which were considered as XSITE RECAPP but now have the same bill to site as that of the
invoice being processed by the CBI. A XSITE RECREV (or XSITE XCURR RECREV) is
created to negate the application from receipt amount.  */

       INSERT INTO ar_cons_inv_trx (cons_inv_id,
                                    transaction_type,
                                    trx_number,
                                    transaction_date,
                                    amount_original,
                                    tax_original,
                                    adj_ps_id,
                                    cons_inv_line_number,
                                    org_id)
       SELECT
              l_consinv_id,
              DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
                              'XSITE RECREV', 'XSITE XCURR RECREV'),
              ps_cash.trx_number,
              RA.apply_date,
              nvl (ra.amount_applied_from, RA.amount_applied),
              NULL,
              RA.receivable_application_id,
              NULL,
              ps_cash.org_id
       FROM
              ar_cons_inv_trx inv_trx,
              ar_receivable_applications ra,
              ar_payment_schedules ps_cash,
              ar_payment_schedules ps_inv
      WHERE ra.cons_inv_id_to is not null
      AND ra.cons_inv_id is null
      AND ra.status = 'APP'
      AND ra.application_type = 'CASH'
      AND ra.apply_date <  l_real_cutoff_date
      AND ps_cash.payment_schedule_id = ra.payment_schedule_id
      AND ps_cash.customer_site_use_id =  L_sites.site_id
      AND ps_cash.invoice_currency_code = P_currency
      AND ps_inv.payment_schedule_id = ra.applied_payment_schedule_id
      AND ps_cash.customer_site_use_id = ps_inv.customer_site_use_id
/* bug2786667 : Modified bad join condition.
      AND ra.cons_inv_id_to = inv_trx.cons_inv_id
*/
      AND ra.receivable_application_id = inv_trx.adj_ps_id
      AND inv_trx.transaction_type IN ('XSITE RECAPP','XSITE XCURR RECAPP')
      AND 1=2;  -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM



/** For Site: applied cash receipts where cash receipt bill-to is different **/

/** bug 499781 - changed '(-1)*RA.amount_applied' to 'RA.amount_applied'    **/
/** BUG 531330 - changed back to (-1)*RA.amount_applied                     **/
/** Cross Currency functionality has been added.                            **/
/* bug2882196 : Added 'EXCLUDE RECAPP' for when legacy receipt applied to
                non-legacy invoices. */

       INSERT INTO ar_cons_inv_trx (cons_inv_id,
                                    transaction_type,
                                    trx_number,
                                    transaction_date,
                                    amount_original,
                                    tax_original,
                                    adj_ps_id,
                                    cons_inv_line_number,
                                    org_id)
       SELECT
              l_consinv_id,
              DECODE (nvl(ps_cash.exclude_from_cons_bill_flag, 'N'),'Y','EXCLUDE RECAPP',
              DECODE (nvl (ps_cash.customer_site_use_id, -1), ps_inv.customer_site_use_id,
                      DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
                              'XXXXXXXXXX', 'XCURR RECAPP'),
                      DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
                              'XSITE RECAPP', 'XSITE XCURR RECAPP')) ),
              ps_cash.trx_number,
              RA.apply_date,
              (-1)*RA.amount_applied,
              NULL,
              RA.receivable_application_id,
              NULL,
              ps_cash.org_id
       FROM
              ar_receivable_applications RA,
              ar_payment_schedules  ps_cash,
              ar_payment_schedules  ps_inv
       WHERE
              RA.cons_inv_id_to IS NULL
       AND    RA.status                    = 'APP'
       AND    RA.application_type          = 'CASH'
/* bug2434295 Changed P_cutoff_date to l_real_cutoff_date */
       AND    RA.apply_date               < l_real_cutoff_date
       AND    ps_cash.payment_schedule_id  = RA.payment_schedule_id
       AND    ps_inv.payment_schedule_id   = RA.applied_payment_schedule_id
       AND    ps_inv.customer_site_use_id  = L_sites.site_id
       AND    ps_inv.invoice_currency_code = P_currency
       AND    nvl(ps_inv.exclude_from_cons_bill_flag, 'N') <> 'Y'
       AND   (   nvl(ps_cash.customer_site_use_id,-1) <> ps_inv.customer_site_use_id
              OR ra.amount_applied_from IS NOT NULL
              OR nvl(ps_cash.exclude_from_cons_bill_flag, 'N') = 'Y')
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

/* Bug2778646- Added a select statement to pick up those applications which were
considered as XSITE RECREV but now have the same bill to site as that of the
invoice being processed by the CBI. A XSITE RECAPP (or XSITE XCURR RECAPP) is
created to negate the application from receipt amount.  */
       INSERT INTO ar_cons_inv_trx (cons_inv_id,
                                    transaction_type,
                                    trx_number,
                                    transaction_date,
                                    amount_original,
                                    tax_original,
                                    adj_ps_id,
                                    cons_inv_line_number,
                                    org_id)
       SELECT
              l_consinv_id,
              DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
                              'XSITE RECAPP', 'XSITE XCURR RECAPP'),
              ps_cash.trx_number,
              RA.apply_date,
              (-1)*RA.amount_applied,
              NULL,
              RA.receivable_application_id,
              NULL,
              ps_cash.org_id
       FROM
              ar_cons_inv_trx inv_trx,
              ar_receivable_applications ra,
              ar_payment_schedules ps_cash,
              ar_payment_schedules ps_inv
      WHERE ra.cons_inv_id_to is null
      AND ra.cons_inv_id is not null
      AND ra.status = 'APP'
      AND ra.application_type = 'CASH'
      AND ra.apply_date <  l_real_cutoff_date
      AND    ps_cash.payment_schedule_id  = RA.payment_schedule_id
      AND    ps_inv.payment_schedule_id   = RA.applied_payment_schedule_id
      AND    ps_inv.customer_site_use_id  = L_sites.site_id
      AND    ps_inv.invoice_currency_code = P_currency
      AND ps_cash.customer_site_use_id = ps_inv.customer_site_use_id
      AND ra.receivable_application_id = inv_trx.adj_ps_id
      AND inv_trx.transaction_type IN ('XSITE RECREV','XSITE XCURR RECREV')
      AND 1=2;  -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

/** For Site: get on-account credit memo's applied to different bill-to.    **/
/**           Will need to add a reversal line because Credit Memo was used **/
/**           for a bill-to that is different from the current bill-to.     **/
/* bug2882196 : Added 'EXCLUDE_CMREV' for when credit memo applied to
                legacy invoices */
       INSERT INTO ar_cons_inv_trx (cons_inv_id,
                                    transaction_type,
                                    trx_number,
                                    transaction_date,
                                    amount_original,
                                    tax_original,
                                    adj_ps_id,
                                    cons_inv_line_number,
                                    org_id)
       SELECT
              l_consinv_id,
              DECODE ( nvl(PS2.exclude_from_cons_bill_flag, 'N'), 'Y', 'EXCLUDE_CMREV', 'XSITE_CMREV'),
              PS1.trx_number,
              RA.apply_date,
              RA.amount_applied,
              NULL,
              RA.receivable_application_id,
              NULL,
              PS1.org_id
       FROM
              ar_receivable_applications RA,
              ar_payment_schedules PS1,
              ar_payment_schedules PS2
/* bug2700662 Removed
              ra_customer_trx CT
*/
       WHERE
              RA.cons_inv_id IS NULL
       AND    RA.status                 = 'APP'
       AND    RA.application_type       = 'CM'
/* bug2434295 Changed P_cutoff_date to l_real_cutoff_date */
       AND    RA.apply_date            < l_real_cutoff_date
/* bug2700662 Removed
       AND    CT.customer_trx_id        = RA.customer_trx_id
*/
       AND    PS1.payment_schedule_id   = RA.payment_schedule_id
       AND    PS1.customer_site_use_id  = L_sites.site_id
       AND    PS1.invoice_currency_code = P_currency
       AND    nvl(PS1.exclude_from_cons_bill_flag, 'N') <> 'Y'
       AND    PS2.payment_schedule_id   = RA.applied_payment_schedule_id
       AND   ( PS2.customer_site_use_id <> PS1.customer_site_use_id
           or nvl(PS2.exclude_from_cons_bill_flag, 'N') = 'Y' )
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM


/** For Site: get on-account credit memos assigned to different bill-to but **/
/**           applied against invoice for current bill-to.                  **/
/* bug2882196 : Added 'EXCLUDE_CMAPP' for when legacy credit memo applied to
                non-legacy invoice. */
       INSERT INTO ar_cons_inv_trx (cons_inv_id,
                                    transaction_type,
                                    trx_number,
                                    transaction_date,
                                    amount_original,
                                    tax_original,
                                    adj_ps_id,
                                    cons_inv_line_number,
                                    org_id)
       SELECT
              l_consinv_id,
              DECODE( nvl(PS2.exclude_from_cons_bill_flag, 'N') , 'Y', 'EXCLUDE_CMAPP','XSITE_CMAPP') ,
              PS1.trx_number,
              RA.apply_date,
              (-1)*RA.amount_applied,
              NULL,
              RA.receivable_application_id,
              NULL,
              PS1.org_id
       FROM
              ar_receivable_applications RA,
              ar_payment_schedules PS1,
              ar_payment_schedules PS2
/* bug2700662 Removed
              ra_customer_trx CT
*/
       WHERE
              RA.cons_inv_id_to IS NULL
       AND    RA.status                 = 'APP'
       AND    RA.application_type       = 'CM'
/* bug2434295  Changed P_cutoff_date to l_real_cutoff_date */
       AND    RA.apply_date            < l_real_cutoff_date
/* bug2700662 Removed
       AND    CT.customer_trx_id        = RA.customer_trx_id
       AND    CT.previous_customer_trx_id IS NULL
*/
       AND    PS1.payment_schedule_id   = RA.applied_payment_schedule_id
       AND    PS1.customer_site_use_id  = L_sites.site_id
       AND    PS1.invoice_currency_code = P_currency
       AND    nvl(PS1.exclude_from_cons_bill_flag, 'N') <> 'Y'
       AND    PS2.payment_schedule_id   = RA.payment_schedule_id
       AND    ( PS2.customer_site_use_id <> PS1.customer_site_use_id
           or    nvl(PS2.exclude_from_cons_bill_flag, 'N') = 'Y')
       AND    1=2;     -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

/** For Site: update header for totals.                                     **/
/* bug2882196 Added EXCLUDE_CMREV/APP transaction_type */
       SELECT nvl(sum(amount_original),0)
       INTO   l_new_billed
       FROM   ar_cons_inv_trx
       WHERE  cons_inv_id = l_consinv_id
       AND    transaction_type IN ('INVOICE','CREDIT_MEMO','ADJUSTMENT',
                                   'XSITE_CMREV','XSITE_CMAPP',
                                   'EXCLUDE_CMREV', 'EXCLUDE_CMAPP');

/* bug2786667 Added XCURR transaction_type */
/* bug2882196 Added EXCLUDE RECREV/APP transaction_type */
       SELECT nvl(sum(amount_original),0)
       INTO   l_period_receipts
       FROM   ar_cons_inv_trx
       WHERE  cons_inv_id      = l_consinv_id
       AND    transaction_type IN ('RECEIPT','RECEIPT REV','XSITE RECREV',
                                   'XSITE RECAPP',
                                  'XSITE XCURR RECAPP','XSITE XCURR RECREV',
                                  'EXCLUDE RECREV', 'EXCLUDE RECAPP'
                                   );

       UPDATE ar_cons_inv
       SET    ending_balance =
                beginning_balance + l_new_billed + l_period_receipts
       WHERE  cons_inv_id    = l_consinv_id;

/** For Site: update ar_payment_schedules, ar_receivable_applications       **/
/**           and ar_adjustments                                            **/
/** Cross Currency functionality.                                           **/

       UPDATE  ar_payment_schedules PS
       SET     PS.cons_inv_id = l_consinv_id
       WHERE   PS.payment_schedule_id IN
                  (SELECT IT.adj_ps_id
                   FROM   ar_cons_inv_trx IT
                   WHERE  IT.cons_inv_id      = l_consinv_id
                   AND    IT.transaction_type IN ('INVOICE','CREDIT_MEMO',
                                                  'RECEIPT'));

       UPDATE  ar_payment_schedules PS
       SET     PS.cons_inv_id_rev = l_consinv_id
       WHERE   PS.payment_schedule_id IN
                  (SELECT IT.adj_ps_id
                   FROM   ar_cons_inv_trx IT
                   WHERE  IT.cons_inv_id      = l_consinv_id
                   AND    IT.transaction_type = 'RECEIPT REV')
       AND 1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;

       /* bug2882196 Added 'EXCLUDE RECREV' and 'EXCLUDE_CMREV' */
       UPDATE  ar_receivable_applications  RA
       SET     RA.cons_inv_id = l_consinv_id
       WHERE   RA.receivable_application_id IN
                  (SELECT IT.adj_ps_id
                   FROM   ar_cons_inv_trx IT
                   WHERE  IT.cons_inv_id      = l_consinv_id
                   AND    IT.transaction_type IN ('XSITE RECREV',
                                                  'XSITE_CMREV',
                                                  'XCURR RECREV',
                                                  'XSITE XCURR RECREV',
                                                  'EXCLUDE RECREV',
                                                  'EXCLUDE_CMREV'))
         AND 1=2 ;  -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM
  /*Bug 2650786: Corrected Typo in above statement */


       /* bug2882196 Added 'EXCLUDE RECAPP' and 'EXCLUDE_CMAPP' */
       UPDATE  ar_receivable_applications RA
       SET     RA.cons_inv_id_to = l_consinv_id
       WHERE   RA.receivable_application_id IN
                  (SELECT IT.adj_ps_id
                   FROM   ar_cons_inv_trx IT
                   WHERE  IT.cons_inv_id = l_consinv_id
                   AND    IT.transaction_type IN ('XSITE RECAPP',
                                                  'XSITE_CMAPP',
                                                  'XCURR RECAPP',
                                                  'XSITE XCURR RECAPP',
                                                  'EXCLUDE RECAPP',
                                                  'EXCLUDE_CMAPP'))
       AND 1=2;  -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

/* bug2922922 : Added hint */
       UPDATE  ar_adjustments  RA
       SET     RA.cons_inv_id = l_consinv_id
       WHERE   RA.adjustment_id IN
                  (SELECT /*+ index (IT AR_CONS_INV_TRX_N1)  */
                          IT.adj_ps_id
                   FROM   ar_cons_inv_trx IT
                   WHERE  IT.cons_inv_id      = l_consinv_id
                   AND    IT.transaction_type = 'ADJUSTMENT')
       AND 1=2;  -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

       -- bug2778646 Changed status of selected merged cbi.
       --            DRAFT_MERGE/MERGED status CBI is not selected by other CBI.
       UPDATE ar_cons_inv ci
       SET status = DECODE(P_print_option, 'DRAFT', 'DRAFT_MERGE','MERGED')
       WHERE status = 'MERGE_PENDING'
       AND site_use_id   = L_sites.site_id
       AND currency_code = P_currency
       AND cut_off_date <= P_cutoff_date ;


/** set cons_inv_id to -1 for all rows where unapplied bill-to is same      **/
/** as bill-to of apply-to.                                                 **/
/*
1226201 fbreslin: change the order of the tables in the WHERE cluase of the
sub-query for performance purposes.
*/
/* bug2706497 : Removed meaningless update stmt.
       UPDATE  ar_receivable_applications RA
       SET     RA.cons_inv_id = -1
       WHERE   RA.cons_inv_id IN
       (SELECT RA1.cons_inv_id
        FROM   ar_payment_schedules PS1,
               ar_payment_schedules PS2,
               ar_receivable_applications RA1
        WHERE  RA1.cons_inv_id IS NULL
        AND    RA1.status                  = 'APP'
        AND    RA1.application_type        IN ('CM', 'CASH')
        AND    RA1.apply_date             < to_date(l_real_cutoff_date)
        AND    PS1.payment_schedule_id    = RA1.payment_schedule_id
        AND    PS1.customer_site_use_id   = L_sites.site_id
        AND    PS1.invoice_currency_code  = P_currency
        AND    PS2.payment_schedule_id    = RA1.applied_payment_schedule_id
        AND    PS1.customer_site_use_id   = PS2.customer_site_use_id);
*/

/** For Site: finished. Get another site.                                   **/
     END LOOP;

     -- bug2501071 : for C_types cursor loop.
     END LOOP;

   EXCEPTION
    WHEN OTHERS THEN
        arp_standard.debug( 'EXCEPTION: generate:' );
        arp_standard.debug( 'P_customer_id: '||P_customer_id);
        arp_standard.debug( 'P_customer_number: '||P_customer_number);
        arp_standard.debug( 'P_bill_to_site: '||P_bill_to_site);
        arp_standard.debug( 'P_term_id: '||P_term_id);
        arp_standard.debug( 'P_cutoff_date: '||P_cutoff_date);
        arp_standard.debug( 'P_print_option: '||P_print_option);
        arp_standard.debug( 'P_currency: '||P_currency);
        RAISE;
   END;
--
/*----------------------------------------------------------------------------*
 | PROCEDURE                                                                  |
 |    update_status                                                           |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    After Consolidated Billing Invoices are printed successfully, update    |
 |    status of the billing invoices from 'PENDING' to 'PRINTED'.             |
 |    For NEW or DRAFT, parameters P_consinv_id and P_request_id are NULL.    |
 |    These parameters are specified by the user for a REPRINT only.          |
 |                                                                            |
 | SCOPE - PRIVATE                                                            |
 |                                                                            |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                     |
 |                                                                            |
 | ARGUMENTS  :  IN:                                                          |
 |                 P_print_option - print option                              |
 |                 P_consinv_id   - consolidated billing invoice              |
 |                 P_request_id   - concurrent request id                     |
 |                                                                            |
 |              OUT:                                                          |
 |                  None                                                      |
 | RETURNS    :     None                                                      |
 |                                                                            |
 | MODIFICATION HISTORY                                                       |
 |   26-MAY-2005   MRAYMOND     4188835 - Added freeze call related to
 |                               etax.  When a invoice is printed, we need
 |                               to notify etax that it will not change.
 |
 *----------------------------------------------------------------------------*/
   PROCEDURE update_status (P_print_option IN VARCHAR,
                            P_consinv_id IN NUMBER,
                            P_request_id IN NUMBER) IS

      CURSOR c_pending_trx IS
                 SELECT PS.customer_trx_id
                 FROM   ar_payment_schedules PS,
                        ar_cons_inv_trx IT,
                        ar_cons_inv CI
                 WHERE
                        CI.print_status = 'PENDING'
                 AND    IT.cons_inv_id = CI.cons_inv_id
                 AND    IT.transaction_type IN ('INVOICE','CREDIT_MEMO')
                 AND    PS.payment_schedule_id = IT.adj_ps_id;


   BEGIN

     /* bug3604391 Changed the sequence of following update stmts.
                   Because ra_customer_trx was not updated after
                   ar_cons_inv.print_status was changed.
     */
     UPDATE  ra_customer_trx  CT
     SET     CT.printing_original_date =
                  nvl(CT.printing_original_date,sysdate),
             CT.printing_last_printed = sysdate,
             CT.printing_count = nvl(CT.printing_count,0) +
                                    DECODE(P_print_option,
                                           'REPRINT', 0,
                                           1)
     WHERE   CT.customer_trx_id IN
                (SELECT PS.customer_trx_id
                 FROM   ar_payment_schedules PS,
                        ar_cons_inv_trx IT,
                        ar_cons_inv CI
                 WHERE  (
                           (P_print_option = 'REPRINT'
                            AND CI.cons_inv_id=nvl(P_consinv_id,CI.cons_inv_id)
                            AND    CI.concurrent_request_id =
                                 nvl(P_request_id, CI.concurrent_request_id))
                         OR
                           (P_print_option IN ('DRAFT', 'PRINT')
                            AND CI.print_status = 'PENDING')
                         )
                 AND    IT.cons_inv_id = CI.cons_inv_id
                 AND    IT.transaction_type IN ('INVOICE','CREDIT_MEMO')
                 AND    PS.payment_schedule_id = IT.adj_ps_id);

     UPDATE ar_cons_inv
     SET    print_status = 'PRINTED',
            last_update_date = arp_global.last_update_date,
            last_updated_by  = arp_global.last_updated_by,
            last_update_login = arp_global.last_update_login
     WHERE  (P_print_option  = 'REPRINT'
             AND cons_inv_id = nvl(P_consinv_id,cons_inv_id)
             AND concurrent_request_id = DECODE (P_consinv_id,
                                                 NULL, P_request_id,
                                                 concurrent_request_id))
     OR     (P_print_option IN ('DRAFT', 'PRINT')
             AND print_status = 'PENDING');

   EXCEPTION
     WHEN OTHERS THEN
       arp_standard.debug( ' Exception: update_status: ');
       RAISE;
   END;
--
   PROCEDURE Report( P_report IN ReportParametersType) Is
   BEGIN
     IF P_report.print_option = 'PRINT'  OR
        P_report.print_option = 'DRAFT'
     THEN
        IF P_report.print_status = 'PENDING' THEN
             generate (P_report.print_option,
                       P_report.detail_option,
                       P_report.currency_code,
                       P_report.customer_id,
                       P_report.customer_number,
                       P_report.bill_to_site,
                       P_report.cutoff_date,
                       P_report.last_day_of_month,
                       P_report.interim_cutoff_date,  --Added for defect # 6693
                       P_report.term_id);

/**after-report trigger:  update status from 'PENDING' to 'PRINTED'       **/
/** to denote a successful print.  Pass current concurrent request id     **/
        ELSE
             update_status(P_report.print_option,
                           P_report.consinv_id,
                           P_report.request_id);
        END IF;

        ELSIF P_report.print_option = 'REPRINT' THEN
             IF P_report.print_status = 'PENDING' THEN
                 reprint(P_report.consinv_id,
                         P_report.request_id);
             ELSE
/**after-report trigger: update status from 'PENDING' to 'PRINTED'        **/
/** to indicate a successful print.  Pass concurrent request id           **/
                 update_status(P_report.print_option,
                               P_report.consinv_id,
                               P_report.request_id);
             END IF;

        ELSIF P_report.print_option = 'DRAFT_ACCEPT'  THEN
             accept(P_report.consinv_id,
                    P_report.request_id);

        ELSIF P_report.print_option = 'DRAFT_REJECT' THEN
             reject(P_report.consinv_id,
                    P_report.request_id);
     END IF;

   EXCEPTION
       WHEN OTHERS THEN
           arp_standard.debug( 'Exception: XX_ARP_CONSINV( P_report):'||sqlerrm );
           RAISE_APPLICATION_ERROR( -20000, sqlerrm||'$Revision 70.00 $:Report (
P_report ):');
   END;
--
/*----------------------------------------------------------------------------+
 | PROCEDURE                                                                  |
 |    report                                                                  |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    Called by before-report trigger in report ARXCBI.  Depending on value   |
 |    of parameter print_option, will call the appropriate procedure.         |
 |    The print_status will be 'PENDING' when called by the before-report     |
 |    trigger.                                                                |
 |    The after-report trigger in report ARXCBI will execute this stored      |
 |    procedure with print_status 'PRINTED' to denote a successful print for  |
 |    print options 'DRAFT', 'PRINTED', 'REPRINT'.                            |
 |                                                                            |
 | SCOPE - public                                                             |
 |                                                                            |
 | EXTERNAL PROCEDURE/FUNCTIONS ACCESSED                                      |
 |                                                                            |
 | ARGUMENTS  : IN:                                                           |
 |                 P_print_option   -  Print Option   (required)              |
 |                 P_detail_option  -  Detail/Summary (not required)          |
 |                 P_currency_code  -  Currency code  (required)              |
 |                 P_customer_id    -  Customer id    (not required)          |
 |                 P_bill_to_site   -  Bill-to site   (not required)          |
 |                 P_term_id        -  Term id        (not required)          |
 |                 P_cutoff_date    -  cut-off date   (required)              |
 |                 P_consinv_id     -  Consolidated Billing Invoice id        |
 |                                                    (not required)          |
 |                 P_request_id     -  Concurrent Request id                  |
 |                                                    (not required)          |
 |                 P_print_status   -  print status   (required)              |
 |             OUT:                                                           |
 |                 None                                                       |
 |                                                                            |
 | RETURNS        : NONE                                                      |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | MODIFICATION HISTORY                                                       |
 |                                                                            |
 *----------------------------------------------------------------------------*/
   PROCEDURE Report( P_print_option    VARCHAR2,
                     P_detail_option   VARCHAR2,
                     P_currency_code   VARCHAR2,
                     P_customer_id     NUMBER,
                     P_customer_number VARCHAR2,
                     P_bill_to_site    NUMBER,
                     P_cutoff_date     DATE,
                     P_last_day_of_month VARCHAR2,
                     P_interim_cut_off_date   DATE,   -- Added for defect # 6693
                     P_term_id         NUMBER,
                     P_consinv_id      NUMBER,
                     P_request_id      NUMBER,
                     P_print_status    VARCHAR2) IS
   l_report ReportParametersType;
   BEGIN
       l_report.print_option               := P_print_option;
       l_report.detail_option              := P_detail_option;
       l_report.currency_code              := P_currency_code;
       l_report.customer_id                := P_customer_id;
       l_report.customer_number            := P_customer_number;
       l_report.bill_to_site               := P_bill_to_site;
       l_report.cutoff_date                := P_cutoff_date;
       l_report.last_day_of_month          := P_last_day_of_month;
       l_report.interim_cutoff_date        := P_interim_cut_off_date; -- Added for defect # 6693
       l_report.term_id                    := P_term_id;
       l_report.consinv_id                 := P_consinv_id;
       l_report.request_id                 := P_request_id;
       l_report.print_status               := P_print_status;
--
       Report(l_report);
--
   EXCEPTION
       WHEN OTHERS THEN
           arp_standard.debug( 'Exception:XX_ARP_CONSINV.Report( ...):'||sqlerrm);
           RAISE_APPLICATION_ERROR( -20000, sqlerrm||'$Revision 70.00 $:Report(
... ):' );
   END;
--
   END XX_ARP_CONSINV;
/
