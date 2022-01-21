CREATE OR REPLACE PACKAGE BODY xx_arp_bf_bill AS
/* $Header: ARPBFBIB.pls 120.51.12020000.19 2014/10/16 20:42:28 rravikir ship $ */
---+====================================================================================================================================+
---|                       Retrofitted Office Depot - Project Simplify                              					|
---+====================================================================================================================================+
---|    Application     : AR                                                                    					|
---|    Name            : xx_arp_bf_bill                                              							|					
---|    Description     : Avoid non-AOPS transactions in Cons Billing                           					|
---|                                                                                            					|
---|    Change Record                                                                           					|
---|    ---------------------------------                                                       					|
---|    Version         DATE              AUTHOR               DESCRIPTION                      					|
---|    ------------    ----------------- ---------------      ---------------------            					|
---|    1.0             22-OCT-2013      Arun Gannarapu       Initial Version -made changes to  					|
---|                                                          to the seeded code as per OD requirements 				|
---|                                                          Defect# 8934                     						|
---|    1.1             10-NOV-2013     Arun Gannarapu        Made changes to fix the missing transactions issue			|
---|                                                          Defect# 8934                     						|
---|    1.2             10-SEP-2015     Shaik Ghouse          Added Hints for QC Defect # 35571 Perf Issue				|
---|																										|
---|    1.3             20-OCT-2015     Shaik Ghouse          Removed Schema name for Custom      					|
-- |    1.4             09-AUG-2016     Arun Gannarapu        12.2.5 Retrofit 								|
-- |    1.5             05-NOV-2018     Dinesh Nagapuri       Made Changes for Bill Complete NAIT-61963. 				|
-- |    1.6		14-MAR-2019	Dinesh Nagapuri	      Added Bill Doc level check to reduce the performance  			|	
-- |    1.7     15-OCT-2019 Nitin Tugave          Added NAIT- 109439 AB Subscription Recurring billing on Bill Complete account | 
---+====================================================================================================================================+

/*REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package phase=plb \
REM dbdrv: checkfile(120.22.12010000.56=120.51.12020000.19)(120.22.12010000.54=120.51.12020000.17)(120.21.12000000.50=120.22.12010000.47)(120.21.12000000.40=120.22.12010000.37)(120.21.12000000.35=120.22.12010000.32):~PROD:~PATH:~FILE
*/

-- define structure to store data that needs to be overridden
TYPE tab_trx_id       IS TABLE OF ra_customer_trx.customer_trx_id%TYPE
                      INDEX BY BINARY_INTEGER;
TYPE tab_term_id      IS TABLE OF ra_customer_trx.term_id%TYPE
                      INDEX BY BINARY_INTEGER;
TYPE tab_billing_date IS TABLE OF ra_customer_trx.billing_date%TYPE
                      INDEX BY BINARY_INTEGER;
TYPE tab_due_date     IS TABLE OF ra_customer_trx.term_due_date%TYPE
                      INDEX BY BINARY_INTEGER;


l_tab_trx_id       tab_trx_id;
l_tab_term_id      tab_term_id;
l_tab_billing_date tab_billing_date;
l_tab_due_date     tab_due_date;
l_tab_idx          BINARY_INTEGER := 0;


PROCEDURE write_debug_and_log(p_message IN VARCHAR2) IS

BEGIN

  IF FND_GLOBAL.CONC_REQUEST_ID is not null THEN

    fnd_file.put_line(FND_FILE.LOG,p_message);

  END IF;

  arp_standard.debug(p_message);

EXCEPTION
WHEN others THEN
    NULL;
END;


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
          write_debug_and_log( ' Exception: reprint: ');
          write_debug_and_log( ' P_consinv_id: '||P_consinv_id );
          write_debug_and_log( ' P_request_id: '||P_request_id );
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
   PROCEDURE accept( P_cust_num_low     IN VARCHAR2,
                     P_cust_num_high    IN VARCHAR2,
                     P_bill_site_low    IN NUMBER,
                     P_bill_site_high   IN NUMBER,
                     P_bill_date_low    IN DATE,
                     P_bill_date_high   IN DATE,
                     P_consinv_num_low  IN NUMBER,
                     P_consinv_num_high IN NUMBER,
                     P_request_id       IN NUMBER) IS
     -- bug13529389 start
     TYPE tab_site_use_id IS TABLE OF ar_cons_inv_all.site_use_id%TYPE;
     TYPE tab_currency_code IS TABLE OF ar_cons_inv_all.currency_code%TYPE;
     TYPE tab_cut_off_date IS TABLE OF ar_cons_inv_all.cut_off_date%TYPE;
     TYPE tab_cons_billing_number IS TABLE OF ar_cons_inv_all.cons_billing_number%TYPE; 

     l_site_use_id tab_site_use_id ;
     l_currency_code tab_currency_code;
     l_cut_off_date tab_cut_off_date ;
     l_cons_billing_number tab_cons_billing_number;

     CURSOR c_cons_inv IS
      SELECT site_use_id,
             currency_code,
             nvl(billing_date,cut_off_date),
         cons_billing_number
        FROM ar_cons_inv
       WHERE customer_id in (select cust_account_id
                               from   hz_cust_accounts c
                               where  c.account_number 
                                      between nvl(P_cust_num_low, c.account_number)
                                      and nvl(P_cust_num_high, c.account_number))
         AND    site_use_id between nvl(P_bill_site_low, site_use_id) and
                                nvl(P_bill_site_high, site_use_id)
         AND    nvl(billing_date,cut_off_date) between 
                     nvl(P_bill_date_low, nvl(billing_date,cut_off_date)) and   
                     nvl(P_bill_date_high, nvl(billing_date,cut_off_date))
         AND    cons_billing_number between nvl(P_consinv_num_low, cons_billing_number) and
                                nvl(P_consinv_num_high, cons_billing_number)                      
         AND concurrent_request_id = nvl(P_request_id, concurrent_request_id)
         AND status = 'DRAFT' ;
     -- bug13529389 end             

   BEGIN

     write_debug_and_log ( ' Parameters into accept:' );
     write_debug_and_log ( ' P_cust_num_low    : ' || P_cust_num_low);
     write_debug_and_log ( ' P_cust_num_high   : ' || P_cust_num_high);
     write_debug_and_log ( ' P_bill_site_low   : ' || P_bill_site_low);
     write_debug_and_log ( ' P_bill_site_high  : ' || P_bill_site_high);
     write_debug_and_log ( ' P_bill_date_low   : ' || P_bill_date_low);
     write_debug_and_log ( ' P_bill_date_high  : ' || P_bill_date_high);
     write_debug_and_log ( ' P_consinv_num_low : ' || P_consinv_num_low);
     write_debug_and_log ( ' P_consinv_num_high: ' || P_consinv_num_high);
     write_debug_and_log ( ' P_request_id      : ' || P_request_id);

     -- bug13529389 Added for merged customer's cbi.
     --            Change status from 'DRAFT_MERGE' to 'MERGED'
     OPEN c_cons_inv;
     FETCH c_cons_inv 
        BULK COLLECT INTO 
        l_site_use_id,
    l_currency_code,
    l_cut_off_date,
    l_cons_billing_number;

     FORALL i IN 1..l_site_use_id.count 
        UPDATE ar_cons_inv
        SET    status = 'MERGED',
               last_update_date = arp_global.last_update_date,
               last_updated_by = arp_global.last_updated_by,
               last_update_login = arp_global.last_update_login
        WHERE  status = 'DRAFT_MERGE'
        AND    site_use_id = l_site_use_id(i)
        AND    currency_code = l_currency_code(i)
        AND    nvl(billing_date,cut_off_date) <= l_cut_off_date(i) ;
     -- bug13529389 end

     --Bug 10023214.
    UPDATE ar_cons_inv
        SET    status = 'ACCEPTED',
               last_update_date = arp_global.last_update_date,
               last_updated_by = arp_global.last_updated_by,
               last_update_login = arp_global.last_update_login
        WHERE  customer_id in (select cust_account_id
                               from   hz_cust_accounts c
                               where  c.account_number 
                                      between nvl(P_cust_num_low, c.account_number)
                                      and nvl(P_cust_num_high, c.account_number))
        AND    site_use_id between nvl(P_bill_site_low, site_use_id) and
                                   nvl(P_bill_site_high, site_use_id)
        AND    nvl(billing_date,cut_off_date) between 
                      nvl(P_bill_date_low, nvl(billing_date,cut_off_date)) and -- Bug 8810634
                      nvl(P_bill_date_high, nvl(billing_date,cut_off_date))
        AND    cons_billing_number between nvl(P_consinv_num_low, cons_billing_number) and
                                   nvl(P_consinv_num_high, cons_billing_number)
        AND    concurrent_request_id = nvl(P_request_id, concurrent_request_id)
        AND    status in ( 'DRAFT');

        commit;

   EXCEPTION
     WHEN OTHERS THEN
         write_debug_and_log ( ' EXCEPTION: accept:' );
         write_debug_and_log ( ' P_cust_num_low    : ' || P_cust_num_low);
         write_debug_and_log ( ' P_cust_num_high   : ' || P_cust_num_high);
         write_debug_and_log ( ' P_bill_site_low   : ' || P_bill_site_low);
         write_debug_and_log ( ' P_bill_site_high  : ' || P_bill_site_high);
         write_debug_and_log ( ' P_bill_date_low   : ' || P_bill_date_low);
         write_debug_and_log ( ' P_bill_date_high  : ' || P_bill_date_high);
         write_debug_and_log ( ' P_consinv_num_low : ' || P_consinv_num_low);
         write_debug_and_log ( ' P_consinv_num_high: ' || P_consinv_num_high);
         write_debug_and_log ( ' P_request_id      : ' || P_request_id);

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
 |                                          |
 | C M Clyde        28 Aug 97     Modified to include transaction types of    |
 |                                'XSITE XCURR RECAPP', 'XSITE XCURR RECREV', |
 |                                'XCURR RECAPP', 'XCURR RECREV'.             |
 |                                                                            |
 *----------------------------------------------------------------------------*/
   PROCEDURE reject( P_cust_num_low     IN VARCHAR2,
                     P_cust_num_high    IN VARCHAR2,
                     P_bill_site_low    IN NUMBER,
                     P_bill_site_high   IN NUMBER,
                     P_bill_date_low    IN DATE,
                     P_bill_date_high   IN DATE,
                     P_consinv_num_low  IN NUMBER,
                     P_consinv_num_high IN NUMBER,
                     P_request_id       IN NUMBER) IS
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
             nvl(billing_date,cut_off_date)
        FROM ar_cons_inv
       WHERE  customer_id in (select cust_account_id
                               from   hz_cust_accounts c
                               where  c.account_number 
                                      between nvl(P_cust_num_low, c.account_number)
                                      and nvl(P_cust_num_high, c.account_number))
          AND    site_use_id between nvl(P_bill_site_low, site_use_id) and
                                nvl(P_bill_site_high, site_use_id)
          AND    nvl(billing_date,cut_off_date) between 
                     nvl(P_bill_date_low, nvl(billing_date,cut_off_date)) and   
                     nvl(P_bill_date_high, nvl(billing_date,cut_off_date))
          AND    cons_billing_number between nvl(P_consinv_num_low, cons_billing_number) and
                                nvl(P_consinv_num_high, cons_billing_number)                      
         AND concurrent_request_id = nvl(P_request_id, concurrent_request_id)
         AND status = 'PRE_REJECTED' ;
     -- bug2778646 end             

BEGIN

     write_debug_and_log ( ' Parameters into Reject:');
     write_debug_and_log ( ' P_cust_num_low    : ' || P_cust_num_low);
     write_debug_and_log ( ' P_cust_num_high   : ' || P_cust_num_high);
     write_debug_and_log ( ' P_bill_site_low   : ' || P_bill_site_low);
     write_debug_and_log ( ' P_bill_site_high  : ' || P_bill_site_high);
     write_debug_and_log ( ' P_bill_date_low   : ' || P_bill_date_low);
     write_debug_and_log ( ' P_bill_date_high  : ' || P_bill_date_high);
     write_debug_and_log ( ' P_consinv_num_low : ' || P_consinv_num_low);
     write_debug_and_log ( ' P_consinv_num_high: ' || P_consinv_num_high);
     write_debug_and_log ( ' P_request_id      : ' || P_request_id);

--Bug 10023214
     UPDATE ar_cons_inv
     SET    status       = 'PRE_REJECTED',
            print_status = 'PRINTED',
            last_update_date = arp_global.last_update_date,
            last_updated_by = arp_global.last_updated_by,
            last_update_login = arp_global.last_update_login
     WHERE  customer_id in (select cust_account_id
                            from   hz_cust_accounts c
                            where  c.account_number
                                   between nvl(P_cust_num_low, c.account_number)
                                   and nvl(P_cust_num_high, c.account_number))
     AND    site_use_id between nvl(P_bill_site_low, site_use_id) and
                                nvl(P_bill_site_high, site_use_id)
     AND    nvl(billing_date,cut_off_date) between 
                     nvl(P_bill_date_low, nvl(billing_date,cut_off_date)) and   -- Bug 8810634
                     nvl(P_bill_date_high, nvl(billing_date,cut_off_date))
     AND    cons_billing_number between nvl(P_consinv_num_low, cons_billing_number) and
                                nvl(P_consinv_num_high, cons_billing_number)
     AND    concurrent_request_id = nvl(P_request_id, concurrent_request_id)
     AND    status = 'DRAFT';

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
               WHERE  IT.transaction_type IN ('INVOICE','CREDIT_MEMO','DEBIT_MEMO', 'DEPOSIT', 'CHARGEBACK')
               AND    CI.cons_inv_id = IT.cons_inv_id
               AND    CI.cons_inv_id in (select cons_inv_id from ar_cons_inv i
                                         where  i.status = 'PRE_REJECTED')
               AND    PS.payment_schedule_id = IT.adj_ps_id);

     UPDATE ar_payment_schedules
     SET    cons_inv_id = NULL
     WHERE  payment_schedule_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type IN ('INVOICE','CREDIT_MEMO', 'DEBIT_MEMO', 'DEPOSIT', 'CHARGEBACK',
                                              'RECEIPT')
               AND    CI.cons_inv_id = IT.cons_inv_id
               AND    CI.cons_inv_id in (select cons_inv_id from ar_cons_inv i
                                         where  i.status = 'PRE_REJECTED'));

     UPDATE ar_payment_schedules
     SET    cons_inv_id_rev = NULL
     WHERE  payment_schedule_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type = 'RECEIPT REV'
               AND    CI.cons_inv_id = IT.cons_inv_id
               AND    CI.cons_inv_id in (select cons_inv_id from ar_cons_inv i
                                         where  i.status = 'PRE_REJECTED'));

     UPDATE ar_receivable_applications
     SET    cons_inv_id = NULL
     WHERE  receivable_application_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type IN ('XSITE RECREV', 'XSITE_CMREV',
                          'XCURR RECREV', 'XSITE XCURR RECREV',
                          'EXCLUDE RECREV', 'EXCLUDE_CMREV','RECEIPT ADJUST') /*Bug 9189970 */
               AND    CI.cons_inv_id      = IT.cons_inv_id
               AND    CI.cons_inv_id in (select cons_inv_id from ar_cons_inv i
                                         where  i.status = 'PRE_REJECTED'));

     UPDATE ar_receivable_applications
     SET    cons_inv_id_to = NULL
     WHERE  receivable_application_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type IN ('XSITE RECAPP','XSITE_CMAPP',
                          'XCURR RECAPP', 'XSITE XCURR RECAPP' ,
                          'EXCLUDE RECAPP', 'EXCLUDE_CMAPP', 
                                              'DELAY_CMAPP')
               AND    CI.cons_inv_id      = IT.cons_inv_id
               AND    CI.cons_inv_id in (select cons_inv_id from ar_cons_inv i
                                         where  i.status = 'PRE_REJECTED'));


     UPDATE ar_adjustments
     SET    cons_inv_id = NULL
     WHERE  adjustment_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type = 'ADJUSTMENT'
               AND    CI.cons_inv_id      = IT.cons_inv_id
               AND    CI.cons_inv_id in (select cons_inv_id from ar_cons_inv i
                                         where  i.status = 'PRE_REJECTED'));

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
        AND    nvl(billing_date,cut_off_date) <= l_cut_off_date(i) ;
     -- bug2778646 end
     
     DELETE FROM ar_cons_inv_trx_lines
     WHERE  cons_inv_id IN
              (SELECT CI.cons_inv_id
               FROM   ar_cons_inv CI               
               WHERE  CI.cons_inv_id in (select cons_inv_id from ar_cons_inv i
                                         where  i.status = 'PRE_REJECTED'));

     DELETE FROM ar_cons_inv_trx
     WHERE  cons_inv_id IN
              (SELECT CI.cons_inv_id
               FROM   ar_cons_inv CI
               WHERE  CI.cons_inv_id in (select cons_inv_id from ar_cons_inv i
                                         where  i.status = 'PRE_REJECTED'));

     UPDATE ar_cons_inv CI
     SET    status       = 'REJECTED'
     WHERE  CI.cons_inv_id in (select cons_inv_id from ar_cons_inv i
                               where  i.status = 'PRE_REJECTED');

     commit;

   EXCEPTION
     WHEN OTHERS THEN
         write_debug_and_log ( ' Exception: reject: ');
         write_debug_and_log ( ' P_cust_num_low    : ' || P_cust_num_low);
         write_debug_and_log ( ' P_cust_num_high   : ' || P_cust_num_high);
         write_debug_and_log ( ' P_bill_site_low   : ' || P_bill_site_low);
         write_debug_and_log ( ' P_bill_site_high  : ' || P_bill_site_high);
         write_debug_and_log ( ' P_bill_date_low   : ' || P_bill_date_low);
         write_debug_and_log ( ' P_bill_date_high  : ' || P_bill_date_high);
         write_debug_and_log ( ' P_consinv_num_low : ' || P_consinv_num_low);
         write_debug_and_log ( ' P_consinv_num_high: ' || P_consinv_num_high);
         write_debug_and_log ( ' P_request_id      : ' || P_request_id);

       RAISE;
   END;

/*----------------------------------------------------------------------------* 
 | PROCEDURE                                                                  |
 |    process_override                                                        |
 |                                                                            |
 | DESCRIPTION                                                                |
 |  This is a local procedure called from generate, which will process        |
 |  override requests                                                         |
 |                                                                            |
 | SCOPE - PRIVATE                                                            |
 |                                                                            |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                     |
 |                                                                            |
 | ARGUMENTS  : IN:                                                           |
 |                 P_trx_id                                                   |
 |                 P_class                                                    |
 |                 P_init_trx_id                                              |
 |                 P_prev_trx_id                                              |
 |            : OUT:                                                          |
 |                 P_comments                                                 |
 |                 P_new_term                                                 |
 |                 P_new_bill                                                 |
 |                                                                            |
 | RETURNS    : NONE                                                          |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | MODIFICATION HISTORY                                                       |
 |                                                                            |
 | 22-DEC-05     VCRISOST    Created
 *----------------------------------------------------------------------------*/
PROCEDURE process_override  
                   (P_field          IN VARCHAR2,
                    P_trx_id         IN NUMBER,
                    P_class          IN VARCHAR2,
                    P_init_trx_id    IN NUMBER,
                    P_prev_trx_id    IN NUMBER,
                    P_trx_bill_date  IN DATE,
                    P_trx_term_id    IN NUMBER,
                    P_bill_date      IN DATE,
                    P_due_date       IN DATE,
                    P_term_id        IN NUMBER, 
                    P_comments       IN OUT NOCOPY VARCHAR2,
                    P_bypass_trx     IN OUT NOCOPY BOOLEAN) IS

activity_flag VARCHAR2(1);
proc_field    VARCHAR2(12);
new_term_id   NUMBER;
new_bill_date DATE;
new_due_date  DATE;

BEGIN

    -- initialize new values to current values, in case no override is done
    P_bypass_trx    := FALSE;
    new_term_id     := P_trx_term_id;
    new_bill_date   := P_trx_bill_date;
    new_due_date    := P_due_date;
    proc_field      := P_field;

    activity_flag := arpt_sql_func_util.get_activity_flag(
                       P_trx_id,
                       'Y',
                       'Y',
                       P_class,
                       P_init_trx_id,
                       P_prev_trx_id);

    IF activity_flag = 'N' THEN
       l_tab_idx := l_tab_idx + 1;
       l_tab_trx_id(l_tab_idx) := P_trx_id;

       IF proc_field = 'TERM_ID' THEN
          write_debug_and_log('...............OVERRIDE TERM ID');
          P_comments := P_comments || ' OVERRIDE TERM ID : FROM ' || to_char(P_trx_term_id) ||
                        ' TO ' || to_char(P_term_id) || '. ';
          new_term_id := P_term_id;

          -- after changing term data, you need to process billing_date as well
          proc_field := 'BILLING_DATE';
       END IF;

       IF proc_field = 'BILLING_DATE' THEN

          IF nvl(P_trx_bill_date, P_bill_date - 1) < P_bill_date THEN
             write_debug_and_log('...............OVERRIDE BILLING DATE');
             P_comments := P_comments || ' OVERRIDE BILLING DATE : FROM ' || to_char(P_trx_bill_date) ||
                           ' TO ' || to_char(P_bill_date) || '. ';
             new_bill_date := P_bill_date;

             -- need to recalculate due_date
             new_due_date := ar_bfb_utils_pvt.get_due_date(new_bill_date, new_term_id); 

          END IF;

       END IF;

       l_tab_term_id(l_tab_idx)      := new_term_id;
       l_tab_billing_date(l_tab_idx) := new_bill_date;
       l_tab_due_date(l_tab_idx)     := new_due_date;
       
       -- Following update statements are moved from generate procedure to here 
       -- for the bug 6488683
       -- update the RA_CUSTOMER_TRX with the new term id, billing date and due date
       UPDATE RA_CUSTOMER_TRX
             SET term_id = new_term_id,
                 billing_date = new_bill_date,
                 term_due_date = new_due_date
             WHERE customer_trx_id = P_trx_id;
             
      -- update AR_PAYMENT_SCHEDULES table with the new values
      arp_process_header.post_commit( 'ARPBFBIB',
                                           120.0,
                                           P_trx_id, -- customer_trx_id 
                                           NULL, -- cm trx_id
                                           'Y',  -- complete_flag
                                           NULL, -- INV open_rec flag
                                           NULL, -- CM open_rec_flag 
                                           NULL, -- creation_sign,
                                           NULL, -- allow_overapp_flag,
                                           NULL, -- natural_app_only_flag,
                                           NULL  -- cash_receipt_id
                                         );
        
        -- update AR_PAYMENT_SCHEDULES with the due date.
        UPDATE AR_PAYMENT_SCHEDULES
             SET due_date = new_due_date
             WHERE customer_trx_id = P_trx_id;

    ELSE
       -- activity exists, cannot override data in trx table, but this trx still
       -- needs to be pulled into this BFB

       IF proc_field = 'BILLING_DATE' THEN
          write_debug_and_log('...............CANNOT OVERRIDE BILLING DATE');
          P_comments := P_comments || ' CANNOT OVERRIDE BILLING DATE : ' || to_char(P_trx_bill_date) ||
                        ' BUT WILL PROCESS AS ' || to_char(P_bill_date) || '. ';

       ELSIF proc_field = 'TERM_ID' THEN
          write_debug_and_log('...............CANNOT OVERRIDE TERM_ID');
          P_comments := P_comments || ' CANNOT OVERRIDE TERM ID : ' || to_char(P_trx_term_id) ||
                        ' BUT WILL PROCESS AS ' || to_char(P_term_id) || '. ';
       END IF;
    END IF;
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
 |                 P_print_output     - 'Y' or 'N'                            |
 |                 P_billing_cycle_id -  Billing Cycle Id                     |
 |                 P_billing_date     -  Billing date required for EXTERNAL   |
 |                 P_currency         -  Currency Code                        |
 |                 P_cust_num_low     -  Customer number low                  |
 |                 P_cust_num_high    -  Customer number high                 |
 |                 P_bill_site_low    -  Bill-to Site low                     |
 |                 P_bill_site_high   -  Bill-to Site high                    |
 |                 P_term_id          -  Payment Terms id                     |
 |            : OUT:                                                          |
 |                     None                                                   |
 |                                                                            |
 | RETURNS    : NONE                                                          |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | MODIFICATION HISTORY                                                       |
 |                                                                            |
 *----------------------------------------------------------------------------*/
PROCEDURE generate (P_print_option     IN VARCHAR2,
                    P_print_output     IN VARCHAR2,
                    P_billing_cycle_id IN NUMBER,
                    P_billing_date     IN DATE,
                    P_currency         IN VARCHAR2,
                    P_cust_name_low    IN VARCHAR2,
                    P_cust_name_high   IN VARCHAR2,
                    P_cust_num_low     IN VARCHAR2,
                    P_cust_num_high    IN VARCHAR2,
                    P_bill_site_low    IN NUMBER,
                    P_bill_site_high   IN NUMBER,
                    P_term_id          IN NUMBER,
                    /* Bug 5203710 do not pass p_detail_option */
                    P_detail_option    IN VARCHAR2 DEFAULT NULL,

                    P_print_status     IN VARCHAR2,
                    p_future_date_bill_flag IN VARCHAR2,
                    p_org_id          IN  NUMBER   -- Added for R12 
					) IS --Bug 12739341, add a flag to check whether it can generate future date bill

l_beginning_balance NUMBER;
l_consinv_id        NUMBER;
l_consinv_lineno    NUMBER(15);
l_cons_billno       VARCHAR2(30);
l_new_billed        NUMBER;
l_period_trx        NUMBER;
l_period_receipts   NUMBER;
l_period_adj        NUMBER;
l_period_finchrg    NUMBER;
l_period_credits    NUMBER;
l_period_tax        NUMBER;
l_due_date          DATE;
l_last_bill_date    DATE;
l_request_id        NUMBER;
l_new_schedule_id   NUMBER;                -- bug 6488683
l_check_override    BINARY_INTEGER := 0;   -- bug 6488683
l_cm_flag           NUMBER;                -- bug 9392028
lc_cons_bill_num	VARCHAR2(30);
ln_bill_signal_cnt		NUMBER :=0;
ln_bill_comp_cust_cnt NUMBER :=0;
lc_bill_comp_check_count NUMBER :=0;
l_beginning_max_balance NUMBER;
l_tota_trx_max_balance NUMBER;

CURSOR val_param1 (P_cust_num_low VARCHAR2, P_cust_num_high VARCHAR2,
                   P_bill_site_low NUMBER, P_bill_site_high NUMBER) IS
SELECT /*+ index( cp1,HZ_CUSTOMER_PROFILES_N1) index( cp2,HZ_CUSTOMER_PROFILES_N1)*/   -- Added for Defect # 35571
       acct.cust_account_id customer_id,
       nvl(cp1.cons_bill_level, cp2.cons_bill_level) site_bill_level,
       cp2.cons_bill_level acct_bill_level,
       nvl(cp1.standard_terms, cp2.standard_terms) site_term, 
       cp2.standard_terms acct_term
FROM   hz_cust_accounts acct,
       hz_cust_acct_sites acct_site,
       hz_cust_site_uses site_uses,
       hz_customer_profiles  cp1,
       hz_customer_profiles  cp2
WHERE  acct.account_number between P_cust_num_low and P_cust_num_high
AND    acct_site.cust_account_id = acct.cust_account_id
AND    acct_site.cust_acct_site_id = site_uses.cust_acct_site_id
AND    site_uses.site_use_id between P_bill_site_low and P_bill_site_high
AND    cp1.cust_account_id = acct.cust_account_id
AND    cp1.site_use_id(+) = site_uses.site_use_id
AND    cp2.cust_account_id   = acct.cust_account_id
AND    cp2.site_use_id   IS NULL;


-- get the BFB payment trms 
CURSOR c_terms (C_billing_cycle_id NUMBER, C_term_id NUMBER) IS
SELECT T.term_id                   term_id,
       TL.due_days               due_day,
       TL.due_day_of_month       due_dom,
       TL.due_months_forward     due_mf
FROM   ra_terms              T,
       ra_terms_lines        TL
WHERE  TL.term_id            = T.term_id
AND    T.billing_cycle_id    = C_billing_cycle_id
AND    T.term_id             = nvl(C_term_id, T.term_id)
order  by 1;

		/* this cursor will pick up all transactions for given site/customer group by parent order number for Bill Complete */
CURSOR C_inv_parent (C_site_use_id NUMBER, C_customer_id NUMBER) IS
			Select Distinct Parent_Order_Number
						, Null Order_Number
						, 'N' bill_print_flag
			From xx_scm_bill_signal xsbs
			Where 1 					= 1 
			AND xsbs.site_use_id		= c_site_use_id
			AND xsbs.customer_id		= c_customer_id
			AND xsbs.bill_forward_flag  = 'N'
			AND xsbs.billing_date_flag  = 'C'
			AND NOT EXISTS (SELECT 1
			  FROM xx_scm_bill_signal
			  WHERE 1                	=1
			  AND customer_id        	= C_customer_id
			  AND parent_order_number 	= xsbs.Parent_Order_Number
			  AND bill_forward_flag  	= 'C')
			UNION ALL
			SELECT DISTINCT Parent_Order_Number,
							child_order_number Order_Number,
						   'Y' bill_print_flag
			From xx_scm_bill_signal xsbs
			Where 1 					= 1 
			AND xsbs.site_use_id		= c_site_use_id
			AND xsbs.customer_id		= c_customer_id
			AND xsbs.bill_forward_flag  = 'N'
			AND xsbs.billing_date_flag  = 'C'
			AND EXISTS (SELECT 1
			  FROM xx_scm_bill_signal
			  WHERE 1                	=1
			  AND customer_id        	= C_customer_id
			  AND parent_order_number 	= xsbs.Parent_Order_Number
			  AND bill_forward_flag  	= 'C')
			  ;
			  
		/* this cursor will pick up all transactions for given site/currency 
		
			this cursor will pick up all transactions for given site/currency */
	CURSOR C_inv_trx_parent (C_site_use_id NUMBER, C_billing_date DATE, C_use_currency VARCHAR2, c_parent_num VARCHAR2, c_bill_print_flag  VARCHAR2,c_trx_type_id NUMBER) -- Added parameter For NAIT- 109439
	IS 
		SELECT /*+  index(CT RA_CUSTOMER_TRX_U1)*/   -- Added for Defect # 35571
			   CT.customer_trx_id              trx_id,
			   CT.trx_date                     trx_date,
			   CT.trx_number                   trx_number,
			   PS.class                        class,
			   PS.payment_schedule_id          schedule_id,
			   PS.amount_due_original          amount_due,
			   PS.tax_original                 tax,
			   PS.invoice_currency_code        currency,
			   CT.term_id                      term_id,
			   CT.billing_date                 billing_date,
			   CT.initial_customer_trx_id      init_trx_id,
			   CT.previous_customer_trx_id     prev_trx_id,
			   CT.interface_header_attribute1  trx_desc,
			   CT.ship_to_site_use_id          ship_id,
			   CT.term_due_date                due_date
		FROM   ra_customer_trx   CT,
			   ar_payment_schedules PS,
			 --  oe_order_headers_all Ooh,
			   xx_om_header_attributes_all Xoha
		WHERE  PS.customer_site_use_id     = C_site_use_id
		AND    PS.cons_inv_id              IS NULL
		AND    PS.invoice_currency_code    = nvl(C_use_currency, PS.invoice_currency_code)
		AND    CT.customer_trx_id          = PS.customer_trx_id
		AND    CT.printing_option = 'PRI'
		AND    PS.class                    IN ('INV', 'DM', 'DEP', 'CB','CM')
		AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
		AND    nvl(CT.billing_date, CT.trx_date) <= C_billing_date
		--And    Ooh.Order_Number = To_Number(Ct.Trx_Number)							-- Removed Jira 72552
		And    (	
				    (Xoha.Parent_Order_Num   = c_parent_num	AND c_bill_print_flag='N') 
				OR  	
				   --(Ooh.Order_Number = c_parent_num AND c_bill_print_flag='Y')		-- Removed Jira 72552
					( Ct.Trx_Number = c_parent_num AND c_bill_print_flag='Y') 			-- Added Jira 72552
				OR  (Ct.Trx_Number = c_parent_num AND c_bill_print_flag ='N' and CT.CUST_TRX_TYPE_ID = c_trx_type_id) -- Added For NAIT- 109439	
				) 	
		AND    xoha.Bill_Comp_Flag		IN ('B','Y')
		--AND    Ooh.Header_Id      = Xoha.Header_Id									-- Removed Jira 72552
		AND to_number(ct.attribute14) = xoha.header_id --Jira 72552
		AND EXISTS
			  (SELECT 1
			  FROM xx_scm_bill_signal
			  WHERE 1                =1
			  AND child_order_number = CT.trx_number
			  AND bill_forward_flag  = 'N'
			  )
		ORDER  BY 10, 1;
				
	/* this cursor will pick up all transactions for given site/currency 
	 * that are not yet stamped with a cons_inv_id and have billing_date <= 
	 * billing date in process, this will include :
	 *
	 * a) transactions that completely comply with the BFB term and billing date 
	 *      - no additional processing required
	 * b) transactions that have diff term/bill date
	 *      - may require override 
	 * c) transactions that are CM
	 *
	 */
	 
CURSOR C_inv_trx (C_site_use_id NUMBER, C_billing_date DATE, C_use_currency VARCHAR2) IS
SELECT /*+  index(CT RA_CUSTOMER_TRX_U1)*/   -- Added for Defect # 35571
       CT.customer_trx_id              trx_id,
       CT.trx_date                     trx_date,
       CT.trx_number                   trx_number,
       PS.class                        class,
       PS.payment_schedule_id          schedule_id,
       PS.amount_due_original          amount_due,
       PS.tax_original                 tax,
       PS.invoice_currency_code        currency,
       CT.term_id                      term_id,
       CT.billing_date                 billing_date,
       CT.initial_customer_trx_id      init_trx_id,
       CT.previous_customer_trx_id     prev_trx_id,
       CT.interface_header_attribute1  trx_desc,
       CT.ship_to_site_use_id          ship_id,
       CT.term_due_date                due_date
FROM   ra_customer_trx   CT,
       ar_payment_schedules PS
WHERE  PS.customer_site_use_id     = C_site_use_id
AND    PS.cons_inv_id              IS NULL
AND    PS.invoice_currency_code    = nvl(C_use_currency, PS.invoice_currency_code)
AND    CT.customer_trx_id          = PS.customer_trx_id
AND    CT.printing_option = 'PRI'
AND    PS.class                    IN ('INV', 'DM', 'DEP', 'CB','CM')
AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
AND    nvl(CT.billing_date, CT.trx_date) <= C_billing_date
ORDER  BY 10, 1;

/* This cursor is used to fetch the recently created payment scheduled id 
 * for a given customer_trx_id. This is used to get the newly created 
 * payment_schedule_id for the transactions for which the term_id is over ridden.
 * bug 6488683 
*/
CURSOR ps_cur( C_trx_id number) IS
SELECT payment_schedule_id 
FROM ar_payment_schedules
WHERE customer_trx_id = C_trx_id 
ORDER BY creation_date DESC;

TYPE c_sites_type  IS REF CURSOR ;
C_sites C_sites_type; 
C_site_select VARCHAR2(5000);
C_site_from   VARCHAR2(5000);
C_site_where  VARCHAR2(5000);
C_site_stmt   VARCHAR2(5000);


/* Bug 5203710 get detail_option from customer setup */
TYPE L_sites_type IS RECORD
  ( customer_id    NUMBER,
    site_id        NUMBER,
    bill_level     VARCHAR2(1),
    override_terms VARCHAR2(1),
    cons_inv_type  hz_customer_profiles.cons_inv_type%TYPE );

L_sites L_sites_type ;

/* Bug 5203710 remove  detail_option as limiting criteria */
  --C_detail_option hz_customer_profiles.cons_inv_type%TYPE;

TYPE tab_line_id IS TABLE OF ra_customer_trx_lines_all.link_to_cust_trx_line_id%TYPE;
TYPE tab_num IS TABLE OF NUMBER ;

l_line_id tab_line_id ;
l_tax_sum tab_num ;
l_include_tax_sum tab_num ;

l_bulk_fetch_rows  NUMBER := 10000 ;

CURSOR c_tax (l_trx_id NUMBER) IS
SELECT link_to_cust_trx_line_id,
       sum(nvl(CTL.extended_amount,0)),
       sum(decode(amount_includes_tax_flag, 'Y', nvl(CTL.extended_amount,0),0))
FROM   ra_customer_trx_lines  CTL
WHERE  CTL.customer_trx_id = l_trx_id
AND    CTL.line_type = 'TAX'
GROUP  BY link_to_cust_trx_line_id;
  
l_comments              VARCHAR2(200);
l_bypass_trx            BOOLEAN;
l_bill_level            VARCHAR2(1);
l_billing_date          DATE;
l_site_term             NUMBER;
l_acct_term             NUMBER;
l_param_err             VARCHAR2(1);
l_customer_id        NUMBER; /* Added for bug fix 5232547 */
curr_customer_id        NUMBER;
l_cust_name_low         VARCHAR2(240);
l_cust_name_high        VARCHAR2(240);
l_cust_num_low          VARCHAR2(30);
l_cust_num_high         VARCHAR2(30);
l_bill_site_low         NUMBER;
l_bill_site_high        NUMBER;
l_remit_to_address_rec  arp_trx_defaults_3.address_rec_type;
l_remit_to_address_id   NUMBER;

l_party_id              NUMBER;
l_bucket_name           AR_AGING_BUCKETS.BUCKET_NAME%TYPE;
l_outstanding_balance   NUMBER; 
l_bucket_titletop_0     AR_AGING_BUCKET_LINES.REPORT_HEADING1%TYPE;
l_bucket_titlebottom_0  AR_AGING_BUCKET_LINES.REPORT_HEADING2%TYPE;
l_bucket_amount_0       NUMBER;
l_bucket_titletop_1     AR_AGING_BUCKET_LINES.REPORT_HEADING1%TYPE;
l_bucket_titlebottom_1  AR_AGING_BUCKET_LINES.REPORT_HEADING2%TYPE;
l_bucket_amount_1       NUMBER;
l_bucket_titletop_2     AR_AGING_BUCKET_LINES.REPORT_HEADING1%TYPE;
l_bucket_titlebottom_2  AR_AGING_BUCKET_LINES.REPORT_HEADING2%TYPE;
l_bucket_amount_2       NUMBER;
l_bucket_titletop_3     AR_AGING_BUCKET_LINES.REPORT_HEADING1%TYPE;
l_bucket_titlebottom_3  AR_AGING_BUCKET_LINES.REPORT_HEADING2%TYPE;
l_bucket_amount_3       NUMBER;
l_bucket_titletop_4     AR_AGING_BUCKET_LINES.REPORT_HEADING1%TYPE;
l_bucket_titlebottom_4  AR_AGING_BUCKET_LINES.REPORT_HEADING2%TYPE;
l_bucket_amount_4       NUMBER;
l_bucket_titletop_5     AR_AGING_BUCKET_LINES.REPORT_HEADING1%TYPE;
l_bucket_titlebottom_5  AR_AGING_BUCKET_LINES.REPORT_HEADING2%TYPE;
l_bucket_amount_5       NUMBER;
l_bucket_titletop_6     AR_AGING_BUCKET_LINES.REPORT_HEADING1%TYPE;
l_bucket_titlebottom_6  AR_AGING_BUCKET_LINES.REPORT_HEADING2%TYPE;
l_bucket_amount_6       NUMBER;

l_error_message  VARCHAR2(2000);
l_cycle_start_date     DATE;
l_org_id               NUMBER;
l_trx_type_id          NUMBER:=0;  -- Added For NAIT- 109439
BEGIN

   write_debug_and_log('And so it begins...');
   write_debug_and_log('P_print_option     : ' || P_print_option);
   write_debug_and_log('P_print_output     : ' || P_print_output);
   write_debug_and_log('P_billing_cycle_id : ' || to_char(P_billing_cycle_id));
   write_debug_and_log('P_billing_date     : ' || to_char(P_billing_date));
   write_debug_and_log('P_currency         : ' || P_currency);
   write_debug_and_log('P_cust_name_low    : ' || P_cust_name_low);
   write_debug_and_log('P_cust_name_high   : ' || P_cust_name_high);
   write_debug_and_log('P_cust_num_low     : ' || P_cust_num_low);
   write_debug_and_log('P_cust_num_high    : ' || P_cust_num_high);
   write_debug_and_log('P_bill_site_low    : ' || to_char(P_bill_site_low));
   write_debug_and_log('P_bill_site_high   : ' || to_char(P_bill_site_high));
   write_debug_and_log('P_term_id          : ' || to_char(P_term_id));
   write_debug_and_log('P_print_status     : ' || P_print_status);
   ----Bug 12739341, add a flag to check whether it can generate future date bill
   write_debug_and_log('P_future_bill_date     : ' || P_future_Date_bill_flag);
   write_debug_and_log('P_org_id     : ' || P_org_id);

  /* Bug 5203710 remove  detail_option as limiting criteria */
  -- C_detail_option := nvl(P_detail_option, 'SUMMARY') ;

   /* Validate params passed in are a valid combination, PRIOR to processing */

   l_param_err := 'N';

   IF FND_GLOBAL.CONC_REQUEST_ID is null THEN
      -- only do pre-validation for cases where call is not made from conc program

   IF P_term_id IS NOT NULL THEN
      IF ar_bfb_utils_pvt.get_billing_cycle(P_term_id) <> P_billing_cycle_id THEN
         write_debug_and_log('P_billing_cycle_id and P_term_id are not compatible');
         l_param_err := 'Y';
      ELSE
        write_debug_and_log('P_billing_cycle_id passed initial validation.');
      END IF;

      -- if user provides customer number and site do additional pre-validation
      IF P_cust_num_low IS NOT NULL AND
         P_bill_site_low IS NOT NULL THEN

         FOR v in val_param1(P_cust_num_low, P_cust_num_high, 
                             P_bill_site_low, P_bill_site_high) LOOP

            IF v.site_bill_level = 'ACCOUNT' AND v.acct_term <> P_term_id THEN
               write_debug_and_log('ACCT level : P_customer_id ' || to_char(v.customer_id) || 
                                  ' and P_term_id ' || to_char(P_term_id) || ' are not compatible');
               l_param_err := 'Y';
            ELSIF v.site_bill_level = 'SITE' AND v.site_term <> P_term_id THEN
               write_debug_and_log('SITE level : P_customer_id ' || to_char(v.customer_id) ||
                                  ' and P_term_id ' || to_char(P_term_id) || ' are not compatible');
               l_param_err := 'Y';
            END IF;

         END LOOP;
   
         IF l_param_err <> 'Y' THEN
            write_debug_and_log('P_customer_id and P_term_id passed initial validation.');
         END IF;
      END IF;

   END IF;
   END IF;


   --get billing_cycle attributes

   select start_date
   into l_cycle_start_date 
   from ar_cons_bill_cycles_b
   where billing_cycle_id = p_billing_cycle_id;

   IF l_param_err = 'Y' THEN
      write_debug_and_log('ERROR : Incompatible parameters passed');
   ELSE

   l_tab_idx        := 0;

   SELECT bucket_name
   INTO   l_bucket_name
   FROM   ar_aging_buckets
   WHERE  aging_bucket_id = 2;

    l_billing_date := P_billing_date;

   FOR L_terms IN c_terms(P_billing_cycle_id, P_term_id) LOOP

      write_debug_and_log(' ');
      write_debug_and_log('Loop c_terms');
      write_debug_and_log('...term_id : ' || to_char(L_terms.term_id));

      IF ar_bfb_utils_pvt.get_cycle_type(P_billing_cycle_id) = 'EVENT' THEN 
         -- for EXTERNAL cycles, billing date should be provided
         IF P_billing_date  IS NOT NULL THEN
            write_debug_and_log( 'EXCEPTION: generate, P_billing_date is null.' );
            APP_EXCEPTION.raise_exception;
         END IF;
      END IF;


      write_debug_and_log('...billing_date : ' || to_char(l_billing_date));

      -- only process billing cycles that have billing date <= sysdate
      IF l_billing_date > sysdate and  nvl(p_future_date_bill_flag, 'N') = 'N' then --Bug 12739341, add a flag to check whether it can generate future date bill
		write_debug_and_log('...BYPASSING THIS CYCLE SINCE NEXT SCHEDULED BILLING DATE IS IN THE FUTURE');
      ELSE

        -- pick up BFB related data from hz_customer_profiles
        -- if bill_level = 'SITE', get term from site level profile
        --               = 'ACCOUNT', get term from account level profile

        -- pre-process the parameter ranges passed in
        l_cust_name_low   := P_cust_name_low;
        l_cust_name_high  := P_cust_name_high;
        l_cust_num_low    := P_cust_num_low;
        l_cust_num_high   := P_cust_num_high;
        l_bill_site_low   := P_bill_site_low;
        l_bill_site_high  := P_bill_site_high;
        l_org_id          := p_org_id;

        if l_cust_name_low is not null then
           if l_cust_name_high is null then
              l_cust_name_high := l_cust_name_low;
           end if;
        else
           if l_cust_name_high is not null then
              l_cust_name_low := l_cust_name_high;
           end if;
        end if;

        if l_cust_num_low is not null then
           if l_cust_num_high is null then
              l_cust_num_high := l_cust_num_low;
           end if;
        else
           if l_cust_num_high is not null then
              l_cust_num_low := l_cust_num_high;
           end if;
        end if;

        if l_bill_site_low is not null then
           if l_bill_site_high is null then
              l_bill_site_high := l_bill_site_low;
           end if;
        else
           if l_bill_site_high is not null then
              l_bill_site_low := l_bill_site_high;
           end if;
        end if;

        -- define generic SELECT portion of the statement
       /* Bug 5203710 Add cons_inv_type as one of the params read */

       -- removed /*+ ORDERED */
        c_site_select := 
'SELECT ' ||
'acct_site.cust_account_id customer_id, ' ||
'site_uses.site_use_id site_id, ' ||
'ar_bfb_utils_pvt.get_bill_level(acct_site.cust_account_id) bill_level, ' ||
'decode(ar_bfb_utils_pvt.get_bill_level(acct_site.cust_account_id), ' ||
'       ''A'', CP.override_terms, ' ||
'       ''S'', SP.override_terms) override_terms, ' ||
'decode(ar_bfb_utils_pvt.get_bill_level(acct_site.cust_account_id), ' ||  
'       ''A'', CP.cons_inv_type,  ' ||
'       ''S'', SP.cons_inv_type) cons_inv_type ';

        -- define generic FROM clause
        c_site_from := 
'FROM ' ||
'hz_cust_acct_sites_all       acct_site, ' ||
'hz_cust_site_uses_all        site_uses, ' ||
'hz_customer_profiles     CP, ' ||
'hz_customer_profiles     SP ';

        -- define generic WHERE clause
       /* Bug 5203710 remove cons_inv_type as limiting criteria */
        c_site_where :=
'WHERE site_uses.cust_acct_site_id = acct_site.cust_acct_site_id ' ||
'AND    site_uses.site_use_code    = ''BILL_TO'' ' ||
'AND    CP.cust_account_id         = acct_site.cust_account_id ' ||
'AND    CP.site_use_id         IS NULL ' ||
'AND    SP.site_use_id(+) = site_uses.site_use_id ' ||
'AND    ar_bfb_utils_pvt.is_payment_term_bfb(nvl(SP.standard_terms, CP.standard_terms)) = ''Y'' ' ||
'AND    :term_id        = ' ||
'       decode(ar_bfb_utils_pvt.get_bill_level(acct_site.cust_account_id), ' ||
'              ''A'', CP.standard_terms, ' ||
'              ''S'', SP.standard_terms) ' ||
'AND    decode(ar_bfb_utils_pvt.get_bill_level(acct_site.cust_account_id), ' ||
'              ''A'', CP.cons_inv_flag, ' ||
'              ''S'', SP.cons_inv_flag) = ''Y'' ' ||
'AND    NOT EXISTS ' ||
'       (SELECT NULL ' ||
'        FROM ar_cons_inv CI ' ||
'        WHERE CI.site_use_id = site_uses.site_use_id ' ||
'        AND CI.billing_date  >= :billing_date ' ||
'        AND CI.currency_code = :currency ' ||
'        AND CI.status <> ''REJECTED'') ' ||
'AND    NOT EXISTS ' ||
'       (SELECT NULL ' ||
'        FROM ar_cons_inv CI2 ' ||
'        WHERE CI2.site_use_id = site_uses.site_use_id ' ||
'        AND CI2.currency_code = :currency ' ||
'        AND CI2.status = ''DRAFT'') ';

        -- add on tables/conditions depending on parameters passed in
        IF l_cust_name_low is not null THEN
           c_site_from := c_site_from || ', hz_parties party, hz_cust_accounts acct ';

           c_site_where := c_site_where ||
'AND    party.party_name            between :cust_name_low and :cust_name_high ' ||
'AND    party.party_id              = acct.party_id ' ||
'AND    acct.cust_account_id        = acct_site.cust_account_id ';

           IF l_cust_num_low is not null THEN
           c_site_where := c_site_where ||
'AND    acct.account_number         between :cust_num_low and :cust_num_high ';
           END IF;

        ELSIF ( l_cust_num_low is not null  AND 1=2 )  -- Added for R12 
		THEN
           c_site_from := c_site_from || ' ,hz_cust_accounts acct ';

           c_site_where := c_site_where ||
'AND    acct.account_number         between :cust_num_low and :cust_num_high ' ||
'AND    acct.cust_account_id        = acct_site.cust_account_id '||
' AND  1=2 ' ;
    ELSIF ( l_cust_num_low is not null AND 1 = 1 )  
    THEN
           c_site_from := c_site_from || ' ,hz_cust_accounts acct , xx_ar_interim_cust_acct_id xai ';

           c_site_where := c_site_where ||
            'AND    acct.account_number      = xai.account_number '||
            'AND    to_number(xai.account_number) >= to_number(:cust_num_low) ' ||
            'AND    to_number(xai.account_number) <= to_number(:cust_num_high) ' ||
            'AND    acct.cust_account_id        = acct_site.cust_account_id ' ||
            'AND    xai.org_id = :l_org_id '
             ;            

        END IF;

        IF l_bill_site_low is not null THEN

          c_site_where := c_site_where ||
'AND    site_uses.site_use_id       between :bill_site_low and :bill_site_high '; 
        END IF;

        -- put together dynamic SQL for the cursor C_Sites
        c_site_stmt := c_site_select || c_site_from || c_site_where;

        write_debug_and_log('c_site_stmt = ' || c_site_stmt);

        -- handle eight combinations :
        -- Name   Y  N  Y  Y  Y  N  N  N
        -- Num    Y  N  N  N  Y  Y  Y  N
        -- Site   Y  N  N  Y  N  Y  N  Y

        -- Y Y Y
        IF l_cust_name_low is not null AND
           l_cust_num_low is not null AND
           l_bill_site_low is not null THEN

           write_debug_and_log('...Name/Number/Site provided');

           OPEN C_sites FOR c_site_stmt USING
                L_Terms.term_id,
                --Bug 5203710 C_detail_option,
                P_billing_date,
                P_currency,
                P_currency,
                l_cust_name_low,
                l_cust_name_high,
                l_cust_num_low, 
                l_cust_num_high,
                l_bill_site_low,
                l_bill_site_high;

        -- N N N
        ELSIF l_cust_name_low is null AND
              l_cust_num_low is null AND
              l_bill_site_low is null THEN

           write_debug_and_log('...Name/Number/Site NOT provided');

           OPEN C_sites FOR c_site_stmt USING
                L_Terms.term_id,
                -- bug 5203710 C_detail_option,
                P_billing_date,
                P_currency,
                P_currency;

        -- Y N N
        ELSIF l_cust_name_low is not null AND
              l_cust_num_low is null AND
              l_bill_site_low is null THEN

           write_debug_and_log('...Name provided, Number/site NOT provided');

           OPEN C_sites FOR c_site_stmt USING
                L_Terms.term_id,
                -- bug 5203710 C_detail_option,
                P_billing_date,
                P_currency,
                P_currency,
                l_cust_name_low,
                l_cust_name_high;

        -- Y N Y
        ELSIF l_cust_name_low is not null AND
              l_cust_num_low is null AND
              l_bill_site_low is not null THEN

           write_debug_and_log('...Name/Site provided, Number NOT provided');

           OPEN C_sites FOR c_site_stmt USING
                L_Terms.term_id,
                -- bug 5203710 C_detail_option,
                P_billing_date,
                P_currency,
                P_currency,
                l_cust_name_low,
                l_cust_name_high,
                l_bill_site_low,
                l_bill_site_high;

        -- Y Y N
        ELSIF l_cust_name_low is not null AND
              l_cust_num_low is not null AND
              l_bill_site_low is null THEN

           write_debug_and_log('...Name/Number provided, Site NOT provided');

           OPEN C_sites FOR c_site_stmt USING
                L_Terms.term_id,
                -- bug 5203710 C_detail_option,
                P_billing_date,
                P_currency,
                P_currency,
                l_cust_name_low,
                l_cust_name_high,
                l_cust_num_low,
                l_cust_num_high;

        -- N Y Y
        ELSIF l_cust_name_low is null AND
              l_cust_num_low is not null AND
              l_bill_site_low is not null THEN

           write_debug_and_log('...Number/Site provided, Name NOT provided');

           OPEN C_sites FOR c_site_stmt USING
                L_Terms.term_id,
                -- bug 5203710 C_detail_option,
                P_billing_date,
                P_currency,
                P_currency,
                l_cust_num_low,
                l_cust_num_high,
                l_bill_site_low,
                l_bill_site_high;

        -- N Y N
        ELSIF l_cust_name_low is null AND
              l_cust_num_low is not null AND
              l_bill_site_low is null THEN

           write_debug_and_log('...Number provided, Name/Site NOT provided');

           OPEN C_sites FOR c_site_stmt USING
                L_Terms.term_id,
                -- bug 5203710 C_detail_option,
                P_billing_date,
                P_currency,
                P_currency,
                l_cust_num_low,
                l_cust_num_high,
				l_org_id;

        -- N N Y
        ELSIF l_cust_name_low is null AND
              l_cust_num_low is null AND
              l_bill_site_low is not null THEN

           write_debug_and_log('...Site provided, Name/Number NOT provided');

           OPEN C_sites FOR c_site_stmt USING
                L_Terms.term_id,
                -- bug 5203710 C_detail_option,
                P_billing_date,
                P_currency,
                P_currency,
                l_bill_site_low,
                l_bill_site_high;
        END IF;

        curr_customer_id := 0;
        l_customer_id := 0;

        LOOP
          FETCH C_sites INTO L_sites;

          IF C_sites%NOTFOUND THEN
            
            /*-----------------------------------------------
              Show the message below only when cursor did not
              find any rows to process.
            ------------------------------------------------*/

            IF  C_sites%ROWCOUNT = 0 THEN   
              FND_MESSAGE.SET_NAME( 'AR', 'AR_BFB_NO_RECORDS' );
              FND_MSG_PUB.ADD;
              FND_MSG_PUB.Reset;
      
              FOR i IN 1..FND_MSG_PUB.Count_Msg LOOP
                  l_error_message := FND_MSG_PUB.Get( 
                  p_msg_index   =>  i,
                  p_encoded     =>  FND_API.G_FALSE);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, l_error_message );
               FND_FILE.PUT_LINE(FND_FILE.log, l_error_message );
              END LOOP;
              EXIT;

            ELSE                     
              EXIT; 
            END IF;

         END IF;

          /** get next billing invoice id, create header with zero totals. **/

		   lc_cons_bill_num			:=NULL;
		   ln_bill_signal_cnt		:=0	;
		   ln_bill_comp_cust_cnt	:=0	;	
		
          write_debug_and_log(' ');
          write_debug_and_log('... Loop c_sites');
          write_debug_and_log('......customer_id    : '||TO_CHAR(L_sites.customer_id));
          write_debug_and_log('......site_id        : '||TO_CHAR(L_sites.site_id));
          write_debug_and_log('......bill_level     : '||TO_CHAR(L_sites.bill_level));
          write_debug_and_log('......override_terms : '||TO_CHAR(L_sites.override_terms));
          write_debug_and_log('.......cons_inv_type : '||TO_CHAR(L_sites.cons_inv_type));

          /* get party_id */
          select p.party_id 
          into   l_party_id
          from   hz_parties p, hz_cust_accounts c
          where  c.cust_account_id = L_sites.customer_id
          and    c.party_id = p.party_id;


          /** get beginning balance for new billing invoice from prior billing invoice **/
  /*6933233, modified the query to include cons invoice with status = 'FINAL' as well
    for calculating beginning balance.*/
    
    /* Bug 7677870: billing_date is replaced with nvl(billing_date,cut_off_date)
       to carry forward the ending balance of the last CBI run in 11i as
       beginning balance of the first BFB run in R12 */

 /* to address issue of merge customers moved begin balance statement after population of billing date */
/*       
          BEGIN
  
             SELECT  sum(ending_balance), max(nvl(billing_date,cut_off_date))
             INTO    l_beginning_balance, l_last_bill_date
             FROM    ar_cons_inv CI1
             WHERE   CI1.site_use_id   = L_sites.site_id
             AND     CI1.currency_code = P_currency
             AND    (CI1.status       IN ('ACCEPTED', 'FINAL')
                     AND     nvl(CI1.billing_date,CI1.cut_off_date)  =
                               (SELECT max(nvl(CI2.billing_date,CI2.cut_off_date))
                                FROM   ar_cons_inv CI2
                                WHERE  CI2.site_use_id   = L_sites.site_id
                                AND    CI2.currency_code = P_currency
                                AND    CI2.status       IN ('ACCEPTED', 'FINAL'))
             OR (CI1.status = 'MERGE_PENDING'
                 AND nvl(CI1.billing_date,CI1.cut_off_date) <= l_billing_date));

          EXCEPTION
          WHEN NO_DATA_FOUND THEN
             l_beginning_balance := 0;
          END;
*/

         write_debug_and_log('Get Billing Date for Bill');

         IF L_sites.bill_level = 'A' THEN
             -- ACCT LEVEL : use same cons_billing_number for all sites of this customer
             IF curr_customer_id <> L_sites.customer_id THEN
                curr_customer_id := L_sites.customer_id;

               --all sites under this ACCOUNT LEVEl bill will have same
               --same billing_date, so we will calc the billing_date right here.

               IF ar_bfb_utils_pvt.get_cycle_type(P_billing_cycle_id) <> 'EVENT'
                THEN -- calculate next logical billing date
                 IF l_billing_date is null THEN
                    l_billing_date := ar_bfb_utils_pvt.get_bill_process_date
                                                            (P_billing_cycle_id, 
                                                             trunc(sysdate),
                                                             nvl(l_last_bill_date,l_cycle_start_date));

                 ELSE
                   l_billing_date := ar_bfb_utils_pvt.get_bill_process_date
                                                            (P_billing_cycle_id,
                                                             l_billing_date,
                                                             nvl(l_last_bill_date,l_cycle_start_date));

                END IF;

               END IF;

             END IF;

          ELSE
             -- SITE LEVEL : use one cons_billing_number per site
             
               IF ar_bfb_utils_pvt.get_cycle_type(P_billing_cycle_id) <> 'EVENT'
                THEN -- calculate next logical billing date
                 IF l_billing_date is null THEN
                    l_billing_date := ar_bfb_utils_pvt.get_bill_process_date
                                                            (P_billing_cycle_id,
                                                             trunc(sysdate),
                                                             nvl(l_last_bill_date,l_cycle_start_date));

                 ELSE
                   l_billing_date := ar_bfb_utils_pvt.get_bill_process_date
                                                            (P_billing_cycle_id,
                                                             l_billing_date,
                                                             nvl(l_last_bill_date,l_cycle_start_date));

                 END IF;
               END IF;   

          END IF;
         write_debug_and_log('........billing_date :'||l_billing_date);


          BEGIN

             SELECT  sum(ending_balance), max(nvl(billing_date,cut_off_date))
             INTO    l_beginning_balance, l_last_bill_date
             FROM    ar_cons_inv CI1
             WHERE   CI1.site_use_id   = L_sites.site_id
             AND     CI1.currency_code = P_currency
             AND    (CI1.status       IN ('ACCEPTED', 'FINAL')
                     AND     nvl(CI1.billing_date,CI1.cut_off_date)  =
                               (SELECT max(nvl(CI2.billing_date,CI2.cut_off_date))
                                FROM   ar_cons_inv CI2
                                WHERE  CI2.site_use_id   = L_sites.site_id
                                AND    CI2.currency_code = P_currency
                                AND    CI2.status       IN ('ACCEPTED', 'FINAL'))
             OR (CI1.status = 'MERGE_PENDING'
                 AND nvl(CI1.billing_date,CI1.cut_off_date) <= l_billing_date));

          EXCEPTION
          WHEN NO_DATA_FOUND THEN
             l_beginning_balance := 0;
          END;

         
         /* Bug 8242289: Bypass the site if New Billing Date is same as last Billing Date */
         if l_billing_date = l_last_bill_date then
          write_debug_and_log('New Billing Date is same as the last Billing Date, so bypassing this Site: '||L_sites.site_id);
          else
 
       /** calculate due date **/
           
          l_due_date := ar_bfb_utils_pvt.get_due_date(l_billing_date, L_terms.term_id);
          write_debug_and_log('......l_due_date     : '||TO_CHAR(l_due_date));


          /* get remit_to_address */
          BEGIN
             arp_trx_defaults_3.get_remit_to_address(
                                                 null,
                                                 null,
                                                 null,
                                                 null,
                                                 L_sites.site_id,
                                                 l_remit_to_address_id,
                                                 l_remit_to_address_rec
                                               );
          EXCEPTION
          WHEN OTHERS THEN
             l_remit_to_address_id := NULL;
          END;

          /** For Site: create header.                                               
              note it is possible that only the header will created if no  
              transactions are found.                                       
          **/

      -- Added for Bill Complete to check if bill complete customer and exists bill Signal Transactions NAIT-61963.
			BEGIN
				-- V1.6 Added Bill Doc level check to reduce the performance Impact 
				SELECT COUNT(1)
				INTO lc_bill_comp_check_count
				FROM xx_cdh_cust_acct_ext_b
				WHERE 1              =1
				AND cust_account_id  = l_sites.customer_id
				AND bc_pod_flag      IN ('Y','B') 
				AND ROWNUM <2;
					
				IF lc_bill_comp_check_count > 0
				THEN
					SELECT 	COUNT(1)
					INTO ln_bill_comp_cust_cnt
					FROM ar_payment_schedules_all api
					WHERE 1                 =1
					AND api.Status          		= 'OP'
					AND api.cons_inv_id         	IS NULL
					AND api.customer_site_use_id	= l_sites.site_id
					AND api.customer_id     		= l_sites.customer_id
					AND ROWNUM < 2 
                    AND ( EXISTS 
                        (
                          SELECT 1
                          FROM oe_order_headers_all ooh,
                               xx_om_header_attributes_all xoha
                          WHERE ooh.Order_Number = TO_NUMBER(api.trx_number)
                          AND ooh.Header_Id      = Xoha.Header_Id
                          AND NVL(BILL_COMP_FLAG,'N')     IN ('B','Y')
						)
                        OR EXISTS  -- Added For NAIT- 109439
                        (
                         SELECT 1
                           FROM oe_order_headers_all ooh,
                                xx_om_header_attributes_all xoha ,
                                ra_customer_trx_all rct
                           WHERE 1=1
                             AND ooh.Header_Id      = Xoha.Header_Id
                             AND rct.CUSTOMER_TRX_ID = api.CUSTOMER_TRX_ID
                             AND Xoha.header_id      = to_number(rct.attribute14) 
                             AND NVL(xoha.BILL_COMP_FLAG,'N')     IN ('B','Y')
                        ) 
                        );						
                END IF;  
				
				IF ln_bill_comp_cust_cnt >0
				THEN
					SELECT COUNT(1)
					INTO ln_bill_signal_cnt
					FROM Xx_Scm_Bill_Signal
					WHERE 1=1
					AND customer_id = l_sites.customer_id
					AND site_use_id = l_sites.site_id 	 
					AND Bill_forward_flag    = 'N' 
					AND ROWNUM < 2 ;
				END IF;
			END;
			
		 --Added for Bill Complete. If Non Bill Complete Customer will have regular flow NAIT-61963.
		  IF ln_bill_comp_cust_cnt =0	 
		  THEN
				SELECT ar_cons_inv_s.NEXTVAL
				INTO   l_consinv_id
				FROM   dual;
				
			    write_debug_and_log('......insert to ar_cons_inv, ID: ' || TO_CHAR(l_consinv_id) ||' number: ' || l_cons_billno);
				l_cons_billno := to_char(l_consinv_id);

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
									   due_date,
									   currency_code,
									   beginning_balance,
									   ending_balance,
									   org_id,
									   billing_date,
									   bill_level_flag,
									   last_billing_date,
									   billing_cycle_id,
									   remit_to_address_id)
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
									   --Bug 5203710 get the cons_inv_type from customer setup
									   L_sites.cons_inv_type,
									   P_print_option,
									   P_print_status,
									   L_terms.term_id,
									   sysdate,
									   l_due_date,
									   P_currency,
									   nvl(l_beginning_balance,0),
									   0,
									   arp_standard.sysparm.org_id,
									   l_billing_date,
									   L_sites.bill_level,
									   l_last_bill_date,
									   P_billing_cycle_id,
									   l_remit_to_address_id);
				
			  /** For Site: process invoices, credit memos. Need loop to assign line no. **/

			  l_consinv_lineno := 1;

			  FOR L_inv_trx IN C_inv_trx(L_sites.site_id, l_billing_date, P_currency) LOOP

				 write_debug_and_log(' ');
				 write_debug_and_log(' System');
				 write_debug_and_log('.........Loop C_inv_trx for site = ' || to_char(L_sites.site_id));
				 write_debug_and_log('.........trx_id       :'||TO_CHAR(L_inv_trx.trx_id));
				 write_debug_and_log('.........trx_date     :'||TO_CHAR(L_inv_trx.trx_date));
				 write_debug_and_log('.........trx_number   :'||L_inv_trx.trx_number);
				 write_debug_and_log('.........class        :'||L_inv_trx.class);
				 write_debug_and_log('.........term_id      :'||TO_CHAR(L_inv_trx.term_id));
				 write_debug_and_log('.........billing_date :'||TO_CHAR(L_inv_trx.billing_date));
	  
				 -- initialize comment 
				 l_comments := '';
				 l_bypass_trx := FALSE;
				 
				 -- set the value of l_check_override to l_tab_idx so that we can check 
				 -- after process_override whether an update has taken place by comparing
				 -- these two variables. bug 6488683
				 l_check_override := l_tab_idx;
	  
				 -- Prior to inserting into ar_cons_inv_trx, need to perform validation and override if necessary 
				 IF nvl(L_inv_trx.term_id,'-1') <> L_terms.term_id THEN
	  
			   IF L_inv_trx.class = 'CM' THEN
			/* Bug 9392028 */
			   SELECT count(*)
			   INTO l_cm_flag
			   FROM ar_payment_schedules ps,
					ra_customer_trx      ct
			   WHERE ps.customer_trx_id = l_inv_trx.trx_id
			   AND   ct.customer_trx_id = ps.customer_trx_id
			   AND   ps.status = 'OP'
			   AND   ct.previous_customer_trx_id IS NULL;

			   IF l_cm_flag = 0 THEN
				 --Resetting the same flag l_cm_flag.

				SELECT count(*)
				 INTO l_cm_flag
				 FROM RA_CUSTOMER_TRX ct,
					  AR_PAYMENT_SCHEDULES ps
				 WHERE ct.customer_trx_id IN (Select ra.APPLIED_CUSTOMER_TRX_ID
										   FROM ar_receivable_applications ra
							   WHERE ra.customer_trx_id = l_inv_trx.trx_id
												   AND   ra.status = 'APP'
												   AND   ra.application_type = 'CM'
												   AND   ra.apply_date <= l_billing_date
							   GROUP BY ra.APPLIED_CUSTOMER_TRX_ID
							   HAVING SUM(nvl(ra.amount_applied_from, ra.amount_applied)) <> 0)
						 AND ct.customer_trx_id = ps.customer_trx_id
						-- AND ar_bfb_utils_pvt.is_payment_term_bfb(ct.term_id) = 'Y'  -- commented on 08mar2012
						 AND nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
						 ---Added below condition to verify if associated INV is there in prior BFB
			 AND    EXISTS (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'                                         
				  FROM ar_cons_inv c,
					   ar_cons_inv_trx ctrx
				  WHERE ct.customer_trx_id = ctrx.customer_trx_id
				  AND   c.cons_inv_id = ctrx.cons_inv_id
				  AND   c.status <> 'REJECTED');

				 If l_cm_flag = 0 THEN
					l_bypass_trx := TRUE;
				 END IF;
			   END IF;

					   -- bypass additional validation, since CM's have no term id / billing date
					   write_debug_and_log('............bypassing BFB validation for CM');
		
					ELSE 
					   -- perform additional validation
		
					   IF L_sites.override_terms = 'Y' THEN
	  
						  IF ar_bfb_utils_pvt.is_payment_term_bfb(L_inv_trx.term_id) = 'N' THEN
							 -- trx does not have BFB term, bypass it
							 l_bypass_trx := TRUE;
						  ELSE
	  
							 write_debug_and_log('............override_terms = Y, term_id is different');
	  
							 process_override
								('TERM_ID',
								 L_inv_trx.trx_id,
								 L_inv_trx.class,
								 L_inv_trx.init_trx_id,
								 L_inv_trx.prev_trx_id,
								 L_inv_trx.billing_date,
								 L_inv_trx.term_id,
								 l_billing_date,
								 L_inv_trx.due_date,
								 L_terms.term_id,
								 l_comments,
								 l_bypass_trx);
	  
						  END IF;
	  
					   ELSE  
						  write_debug_and_log('............override_terms = N, term_id is different');
			  
			  /* Bug 9092366: When the transaction and the customer profile have different
				 payment terms, and if the 'Override Terms' is unchecked, then that
				 transaction should not be processed. */                         
						  l_bypass_trx := TRUE;
		
					   END IF; 
					END IF;
	  
				 ELSE 
	  
					IF nvl(trunc(L_inv_trx.billing_date),to_date('12/31/4712','MM/DD/YYYY')) = 
					   trunc(l_billing_date) THEN
	  
					   write_debug_and_log('............BFB data fully compliant');
					   l_comments := 'FULLY COMPLIANT';
					ELSE
					   write_debug_and_log('............billing_date is different');
					   process_override
						 ('BILLING_DATE',
						  L_inv_trx.trx_id,
						  L_inv_trx.class,
						  L_inv_trx.init_trx_id,
						  L_inv_trx.prev_trx_id,
						  L_inv_trx.billing_date,
						  L_inv_trx.term_id,
						  l_billing_date,
						  L_inv_trx.due_date,
						  L_terms.term_id,
						  l_comments,
						  l_bypass_trx);
					END IF;
				 END IF; 
	  
				IF NOT l_bypass_trx THEN
				
					-- get the current value of payment schedule id in case 
					-- it is changed for overridden payment terms . 
					-- If it is not overridden, assign the actual value of 
					-- payment_schedule_id . bug 6488683
					IF ( l_tab_idx > l_check_override ) THEN
					   OPEN ps_cur(L_inv_trx.trx_id);
					   FETCH ps_cur INTO l_new_schedule_id;
					   CLOSE ps_cur;
					ELSE
					   l_new_schedule_id := L_inv_trx.schedule_id;
					END IF;
						  
				   write_debug_and_log('new payment schedule id ' || l_new_schedule_id ); 
				   write_debug_and_log('insert to ar_cons_inv_trx for ' || L_inv_trx.trx_id);
				   
				   INSERT INTO ar_cons_inv_trx (cons_inv_id,
												transaction_type,
												trx_number,
												transaction_date,
												amount_original,
												tax_original,
												adj_ps_id,
												cons_inv_line_number,
												org_id,
												justification,
												trx_description,
												customer_trx_id,
												ship_to_site_id)
				   VALUES                      (l_consinv_id,
												DECODE(L_inv_trx.class,
													   'CM','CREDIT_MEMO',
													   'DM','DEBIT_MEMO',
													   'DEP','DEPOSIT',
													   'CB','CHARGEBACK',
													   'INVOICE'),
												L_inv_trx.trx_number,
												L_inv_trx.trx_date,
												L_inv_trx.amount_due,
												L_inv_trx.tax,
												l_new_schedule_id,    -- bug 6488683
												l_consinv_lineno,
												arp_standard.sysparm.org_id,
												l_comments,
												L_inv_trx.trx_desc,
												L_inv_trx.trx_id,
												L_inv_trx.ship_id);
	   
				   /** For audit purposes, insert detail line information even if 
					   reporting in summary. Also note that cons_inv_line_number 
					   is one value for detail lines for a specific invoice. **/ 
	   
				   write_debug_and_log('insert to ar_cons_inv_trx_lines for ' || L_inv_trx.trx_id);
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
				   SELECT l_consinv_id,
						  l_consinv_lineno,
						  customer_trx_id,
						  customer_trx_line_id,
						  line_number,
						  inventory_item_id,
						  description,
						  uom_code,
						  decode(L_inv_trx.class,'CM', quantity_credited,quantity_invoiced),
						  nvl (gross_unit_selling_price, unit_selling_price),
						  nvl (gross_extended_amount, extended_amount),
						  0,
						  org_id
				   FROM   ra_customer_trx_lines
				   WHERE  customer_trx_id  = L_inv_trx.trx_id
				   AND    line_type NOT IN ('TAX', 'FREIGHT');
	   
				   /** now update lines with associated tax line **/
	   
				   write_debug_and_log('update ar_cons_inv_trx_lines for TAX');
				   OPEN c_tax(L_inv_trx.trx_id);
				   LOOP
					  FETCH c_tax BULK COLLECT INTO
					  l_line_id , l_tax_sum, l_include_tax_sum LIMIT l_bulk_fetch_rows;
					
					  -- 1. Update tax_amount 
					  -- 2. Exclude inclusive tax amount total from extended_amount
					  FORALL i IN 1..l_line_id.count
						 UPDATE ar_cons_inv_trx_lines
						 SET    tax_amount = l_tax_sum(i),
								extended_amount = extended_amount - l_include_tax_sum(i)
						 WHERE  customer_trx_id = L_inv_trx.trx_id
						 AND    customer_trx_line_id = l_line_id(i) ;
		 
					  EXIT WHEN c_tax%NOTFOUND ;
				   END LOOP; 
				   CLOSE c_tax;
	   
				   /** now create 1 summary row for freight **/
				   write_debug_and_log('insert to ar_cons_inv_trx_lines for FREIGHT');
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
				   
				   
				   
				END IF; /* NOT l_bypass_trx */

			 END LOOP; /* c_inv_trx */
			
				   
			 write_debug_and_log('.........Done with Loop C_inv_trx');

			 /** TRANSACTION ACTIVITY :
				 Pick up all Receipts / CMs / Adjustments that affect the BFB balance **/

			 /* Bug 9392028 Modified Activities */

			 /* ACTIVITY 1 : ADJUSTMENTS
				pick up all adjustments except finance charges generated against this BFB site 
				(fin charge is in next select ACTIVITY 1A) */
	  
			 write_debug_and_log('.........ACTIVITY 1');

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
					ADJ.apply_date,
					ADJ.amount,
					NVL(ADJ.tax_adjusted, 0),
					ADJ.adjustment_id,
					NULL,
					ps.org_id
			 FROM
				  ar_adjustments ADJ,
				  ar_payment_schedules PS
			 WHERE
					ADJ.cons_inv_id is NULL
			 AND    ADJ.apply_date               <= l_billing_date
			 AND    ADJ.type in ('CHARGES','FREIGHT','INVOICE','LINE','TAX')
			 AND    ADJ.created_from         <> 'ARFCCF'    -- exclude auto-generated finance charges
			 AND    ADJ.status = 'A'
			 AND    PS.payment_schedule_id   = ADJ.payment_schedule_id
			 AND    PS.customer_site_use_id  = L_sites.site_id
			 AND    PS.invoice_currency_code = P_currency
			 AND    PS.class||''             <> 'GUAR'
			 AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
			 AND    EXISTS (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
						   FROM ar_cons_inv c,
								ar_cons_inv_trx ctrx
						   WHERE adj.customer_trx_id = ctrx.customer_trx_id
						   AND   c.cons_inv_id = ctrx.cons_inv_id
						   AND   c.status <> 'REJECTED')
			 AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;                       

			 /* ACTIVITY 1A : FINANCE CHARGES
				pick up all adjustments (only finance charges) generated against this BFB site */

			 write_debug_and_log('.........ACTIVITY 1A');

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
				  'FINANCE CHARGE',
				  PS.trx_number,
				  ADJ.apply_date,
				  ADJ.amount,
				  NVL(ADJ.tax_adjusted, 0),
				  ADJ.adjustment_id,
				  NULL,
				  ps.org_id
			 FROM
				  ar_adjustments ADJ,
				  ar_payment_schedules PS
			 WHERE
					ADJ.cons_inv_id is NULL
			 AND    ADJ.apply_date               <= l_billing_date
			 AND    ADJ.type = 'CHARGES'
			 AND    ADJ.created_from = 'ARFCCF'
			 AND    ADJ.status = 'A'
			 AND    PS.payment_schedule_id   = ADJ.payment_schedule_id
			 AND    PS.customer_site_use_id  = L_sites.site_id
			 AND    PS.invoice_currency_code = P_currency
			 AND    PS.class||''             <> 'GUAR'
			 AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
		 AND    EXISTS (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
						   FROM ar_cons_inv c,
								ar_cons_inv_trx ctrx
						   WHERE adj.customer_trx_id = ctrx.customer_trx_id
						   AND   c.cons_inv_id = ctrx.cons_inv_id
						   AND   c.status <> 'REJECTED')
		 AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

			 /* ACTIVITY 2 : RECEIPTS 
				pick up FULL receipt amount for receipts created against this BFB
				site (in ACTIVITY 4 : we back out amounts applied to diff site) */
	  
			 write_debug_and_log('.........ACTIVITY 2');
	  
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
			 WHERE PS.customer_site_use_id  = L_sites.site_id
			 AND    PS.cons_inv_id           IS NULL
			 AND    PS.class                 = 'PMT'
			 AND    PS.invoice_currency_code = P_currency
			 AND    CR.cash_receipt_id       = PS.cash_receipt_id
			 AND    CR.receipt_date          <= l_billing_date
			 AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
			 AND   (PS.status = 'OP'
				 OR    (ps.amount_due_original + 
						 (SELECT nvl(SUM(nvl(ra.amount_applied_from, ra.amount_applied)), 0)
						  FROM ar_receivable_applications ra, 
							   ar_payment_schedules ps_inv, 
							   ra_customer_trx inv_trx 
						  WHERE ra.cash_receipt_id = cr.cash_receipt_id
						  AND inv_trx.customer_trx_id = ra.applied_customer_trx_id
						  AND RA.status = 'APP'
						  AND ra.application_type = 'CASH'
						  AND ra.apply_date <= l_billing_date
						  AND ps_inv.customer_trx_id = inv_trx.customer_trx_id
						  AND (Decode(ps_inv.class ,'CM','Y',ar_bfb_utils_pvt.is_payment_term_bfb(inv_trx.term_id)) <> 'Y' /* Bug 13485325 */
						   OR nvl(ps_inv.exclude_from_cons_bill_flag, 'N') = 'Y'))) <> 0)
			  AND 1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM; 
	  
			 /* ACTIVITY 3 : RECEIPT REVERSAL 
				Reverse FULL receipt amount for receipt reversals of 
				receipts created against this BFB site */
	  
			 write_debug_and_log('.........ACTIVITY 3');

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
			 AND    PS.class                 = 'PMT'
			 AND    CR.cash_receipt_id       = PS.cash_receipt_id
			 AND    CR.reversal_date         <= l_billing_date
			 AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
		 AND     EXISTS 
				 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
			  FROM   ar_cons_inv c,
					 ar_cons_inv_trx ctrx
				  WHERE  PS.payment_schedule_id = ctrx.adj_ps_id
			  AND    c.cons_inv_id = ctrx.cons_inv_id
			  AND    c.status <> 'REJECTED')
			  AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;

			 /* ACTIVITY 4 : Exclude RECEIPT APPLICATIONS for Receipts 
				with this BFB site which are applied to TRX which have 
				a different site */ 

			 write_debug_and_log('.........ACTIVITY 4');

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
			 AND    RA.apply_date                <= l_billing_date
			 AND    ps_cash.payment_schedule_id   = RA.payment_schedule_id
			 AND    ps_cash.customer_site_use_id  = L_sites.site_id
			 AND    ps_cash.invoice_currency_code = P_currency
			 AND    ps_inv.payment_schedule_id    = RA.applied_payment_schedule_id
			 AND    nvl(ps_cash.exclude_from_cons_bill_flag, 'N') <> 'Y' 
			 AND   (   ps_cash.customer_site_use_id  <> ps_inv.customer_site_use_id
				  OR ps_cash.invoice_currency_code  <> ps_inv.invoice_currency_code) -- bug 17659675
	--                OR RA.amount_applied_from IS NOT NULL) --Bug 8208763
	--                OR nvl(ps_inv.exclude_from_cons_bill_flag, 'N') = 'Y')
		 AND     EXISTS 
				 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
			  FROM   ar_cons_inv c,
					 ar_cons_inv_trx ctrx
				  WHERE  RA.payment_schedule_id = ctrx.adj_ps_id
			  AND    c.cons_inv_id = ctrx.cons_inv_id
			  AND    c.status <> 'REJECTED')
			 AND     EXISTS                                         --bug 12349325
				 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
				FROM   ar_cons_inv c,
					 ar_cons_inv_trx ctrx
				  WHERE  ps_inv.payment_schedule_id = ctrx.adj_ps_id
			  AND    c.cons_inv_id = ctrx.cons_inv_id
			  AND    c.status <> 'REJECTED')
			  AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;

			 /* ACTIVITY 5 : Include RECEIPT APPLICATIONS for Receipts created with
				different (or null) site, but applied to TRX with this BFB Site */

			 write_debug_and_log('.........ACTIVITY 5');

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
			 AND    RA.apply_date               <= l_billing_date
			 AND    ps_cash.payment_schedule_id  = RA.payment_schedule_id
			 AND    ps_inv.payment_schedule_id   = RA.applied_payment_schedule_id
			 AND    ps_inv.customer_site_use_id  = L_sites.site_id
			 AND    ps_inv.invoice_currency_code = P_currency
			 AND    nvl(ps_inv.exclude_from_cons_bill_flag, 'N') <> 'Y'
			 AND   (   nvl(ps_cash.customer_site_use_id, -1) <> ps_inv.customer_site_use_id
	--                OR ra.amount_applied_from IS NOT NULL
			OR ps_cash.invoice_currency_code  <> ps_inv.invoice_currency_code -- bug 17659675
					OR nvl(ps_cash.exclude_from_cons_bill_flag, 'N') = 'Y')
		 AND     EXISTS 
				 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'  -- bug 19248291
			  FROM   ar_cons_inv c,
					 ar_cons_inv_trx ctrx
				  WHERE  ps_inv.customer_trx_id = ctrx.customer_trx_id
			  AND    c.cons_inv_id = ctrx.cons_inv_id
			  AND    c.status <> 'REJECTED')
			  AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

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
										cons_inv_line_number)
		   SELECT
				  l_consinv_id,
				  DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
								  'XSITE RECAPP', 'XSITE XCURR RECAPP'),
				  ps_cash.trx_number,
				  RA.apply_date,
				  (-1)*RA.amount_applied,
				  NULL,
				  RA.receivable_application_id,
				  NULL
		   FROM
				  ar_cons_inv_trx inv_trx,
				  ar_receivable_applications ra,
				  ar_payment_schedules ps_cash,
				  ar_payment_schedules ps_inv
		  WHERE ra.cons_inv_id_to is null
		  AND ra.cons_inv_id is not null
		  AND ra.status = 'APP'
		  AND ra.application_type = 'CASH'
	AND ra.apply_date <  to_date(l_billing_date)
		  AND    ps_cash.payment_schedule_id  = RA.payment_schedule_id
		  AND    ps_inv.payment_schedule_id   = RA.applied_payment_schedule_id
		  AND    ps_inv.customer_site_use_id  = L_sites.site_id
		  AND    ps_inv.invoice_currency_code = P_currency
		  AND ps_cash.customer_site_use_id = ps_inv.customer_site_use_id
		  AND ra.receivable_application_id = inv_trx.adj_ps_id
		  AND inv_trx.transaction_type IN ('XSITE RECREV','XSITE XCURR RECREV')
		  AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

			 /* ACTIVITY 6 : When a receipt is originally created without a location, 
				and is immediately applied to an invoice, the receipt's ps.customer_site_use_id 
				remains NULL, hence such an application is considered in ACTIVITY 5.
				Now if later, that receipt is updated with a Location = this BFB site the 
				receipt will now be picked up in ACTIVITY 2. 

				The following select is necessary to counter what was previously picked up 
				in ACTIVITY 5, otherwise the receipt application is recorded twice */
	  
			 write_debug_and_log('.........ACTIVITY 6');
	  
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
			AND ra.apply_date <=  l_billing_date
			AND ps_cash.payment_schedule_id = ra.payment_schedule_id
			AND ps_cash.customer_site_use_id =  L_sites.site_id
			AND ps_cash.invoice_currency_code = P_currency
			AND ps_inv.payment_schedule_id = ra.applied_payment_schedule_id
			AND ps_cash.customer_site_use_id = ps_inv.customer_site_use_id
			AND ra.receivable_application_id = inv_trx.adj_ps_id
			AND inv_trx.transaction_type IN ('XSITE RECAPP','XSITE XCURR RECAPP')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

			/* ACTIVITY 7 : When a receipt is originally created without a location,
			   and is immediately applied to an invoice, the receipt's ps.customer_site_use_id
			   remains NULL, hence such an application is considered in ACTIVITY 5.
			   Now if later, that receipt is updated with a Location different from this BFB site
			   we need to exclude it. */
	  
			 write_debug_and_log('.........ACTIVITY 7');
	   
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
			AND   ra.cons_inv_id is not null
			AND   ra.status = 'APP'
			AND   ra.application_type = 'CASH'
			AND   ra.apply_date <=  l_billing_date
			AND   ps_cash.payment_schedule_id  = RA.payment_schedule_id
			AND   ps_inv.payment_schedule_id   = RA.applied_payment_schedule_id
			AND   ps_inv.customer_site_use_id  = L_sites.site_id
			AND   ps_inv.invoice_currency_code = P_currency
			AND   ps_cash.customer_site_use_id = ps_inv.customer_site_use_id
			AND   ra.receivable_application_id = inv_trx.adj_ps_id
			AND   inv_trx.transaction_type IN ('XSITE RECREV','XSITE XCURR RECREV')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

			/* ACTIVITY 8 : CM applications where CM is for this BFB site, but
			   applied to an invoice having a different site */

			write_debug_and_log('.........ACTIVITY 8');

			INSERT INTO ar_cons_inv_trx (cons_inv_id,
										transaction_type,
										trx_number,
										transaction_date,
										amount_original,
										tax_original,
										adj_ps_id,
										cons_inv_line_number,
										org_id)
			SELECT /*+ ORDERED */
				  l_consinv_id,
				  DECODE(nvl(PS_INV.exclude_from_cons_bill_flag,'N'), 
					  'Y', 'EXCLUDE_CMREV', 
						   'XSITE_CMREV'),
				  PS_CM.trx_number,
				  RA.apply_date,
				  RA.amount_applied,
				  NULL,
				  RA.receivable_application_id,
				  NULL,
				  PS_CM.org_id
			FROM  
				 AR_PAYMENT_SCHEDULES PS_CM ,
				 AR_RECEIVABLE_APPLICATIONS RA ,
				 AR_PAYMENT_SCHEDULES PS_INV,
				 AR_CONS_INV_TRX CTRX,
				 AR_CONS_INV C
			WHERE
				   RA.cons_inv_id IS NULL
			AND    RA.status                 = 'APP'
			AND    RA.application_type       = 'CM'
			AND    RA.apply_date            <= l_billing_date
			AND    PS_CM.payment_schedule_id   = RA.payment_schedule_id
			AND    PS_CM.customer_site_use_id  = L_sites.site_id
			AND    PS_CM.invoice_currency_code = P_currency
			AND    nvl(PS_CM.exclude_from_cons_bill_flag, 'N') <> 'Y'
			AND    PS_INV.payment_schedule_id   = RA.applied_payment_schedule_id
			AND   ( PS_INV.customer_site_use_id <> PS_CM.customer_site_use_id
					or nvl(PS_INV.exclude_from_cons_bill_flag, 'N') = 'Y' ) 
			AND   PS_CM.customer_trx_id = ctrx.customer_trx_id
			AND    c.cons_inv_id = ctrx.cons_inv_id
			AND    c.status <> 'REJECTED'
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

		   /* ACTIVITY 8A : CM applied to INV both have same BFB site, BUT
			  INV is not pulled into BFB yet, need to exclude */

			write_debug_and_log('.........ACTIVITY 8A');

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
				  'DELAY_CMAPP',
				  PS_CM.trx_number,
				  RA.apply_date,
				  RA.amount_applied,
				  NULL,
				  RA.receivable_application_id,
				  NULL,
				  PS_CM.org_id
			FROM
				  ar_receivable_applications RA,
				  ar_payment_schedules PS_CM,
				  ar_payment_schedules PS_INV
			WHERE
				   RA.cons_inv_id_to IS NULL
			AND    RA.status                 = 'APP'
			AND    RA.application_type       = 'CM'
			AND    RA.apply_date            <= l_billing_date
			AND    PS_CM.payment_schedule_id   = RA.payment_schedule_id
			AND    PS_CM.customer_site_use_id  = L_sites.site_id
			AND    PS_CM.invoice_currency_code = P_currency
			AND    nvl(PS_CM.exclude_from_cons_bill_flag, 'N') <> 'Y'
			AND    PS_INV.payment_schedule_id  = RA.applied_payment_schedule_id
			AND    PS_INV.customer_site_use_id = L_sites.site_id
			AND    NOT EXISTS 
					(SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
					 FROM   ar_cons_inv c,
							ar_cons_inv_trx ctrx
					 WHERE  PS_INV.customer_trx_id = ctrx.customer_trx_id
					 AND    c.cons_inv_id = ctrx.cons_inv_id
					 AND    c.status <> 'REJECTED')
			AND    EXISTS
			   (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
					 FROM   ar_cons_inv c,
							ar_cons_inv_trx ctrx
					 WHERE  PS_CM.customer_trx_id = ctrx.customer_trx_id
					 AND    c.cons_inv_id = ctrx.cons_inv_id
					 AND    c.status <> 'REJECTED')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;

			/* ACTIVITY 9 : CM Applications where CM site is different, but applied to
			   TRX which has this BFB site
			   NOTE : do not pull in CM application if the INV it is applied to is not 
			   part of an BFB yet */

			write_debug_and_log('.........ACTIVITY 9');

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
				  DECODE( nvl(PS_CM.exclude_from_cons_bill_flag, 'N') , 'Y', 'EXCLUDE_CMAPP','XSITE_CMAPP') ,
				  PS_INV.trx_number,
				  RA.apply_date,
				  (-1)*RA.amount_applied,
				  NULL,
				  RA.receivable_application_id,
				  NULL,
				  PS_INV.org_id
			FROM
				  ar_receivable_applications RA,
				  ar_payment_schedules PS_INV,  -- INV
				  ar_payment_schedules PS_CM   -- CM
			WHERE
				   RA.cons_inv_id_to IS NULL
			AND    RA.status                 = 'APP'
			AND    RA.application_type       = 'CM'
			AND    RA.apply_date            <= l_billing_date
			AND    PS_INV.payment_schedule_id   = RA.applied_payment_schedule_id
			AND    PS_INV.customer_site_use_id  = L_sites.site_id
			AND    PS_INV.invoice_currency_code = P_currency
			AND    nvl(PS_INV.exclude_from_cons_bill_flag, 'N') <> 'Y'
			AND    PS_CM.payment_schedule_id   = RA.payment_schedule_id
			AND    ( PS_CM.customer_site_use_id <> PS_INV.customer_site_use_id
				or    nvl(PS_CM.exclude_from_cons_bill_flag, 'N') = 'Y')
			AND    EXISTS (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
						   FROM ar_cons_inv c,
								ar_cons_inv_trx ctrx
						   WHERE PS_INV.customer_trx_id = ctrx.customer_trx_id
						   AND   c.cons_inv_id = ctrx.cons_inv_id
						   AND   c.status <> 'REJECTED')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;


			/* Bug fix 5232547 : Receipts without Billing Location */
			 IF L_sites.bill_level = 'A' THEN
				 -- Run the inserts only once for a customer
				 IF l_customer_id <> L_sites.customer_id THEN
					l_customer_id := L_sites.customer_id;

					write_debug_and_log('.........ACTIVITY 10 : Receipts with No Location');
																																				
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
						 PS.customer_id           = L_sites.customer_id
					AND    PS.customer_site_use_id  IS NULL
					AND    PS.cons_inv_id           IS NULL
					AND    PS.class                 = 'PMT'
					AND    PS.invoice_currency_code = P_currency
					AND    CR.cash_receipt_id       = PS.cash_receipt_id
					AND    CR.receipt_date          <= l_billing_date
					AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
			AND    (PS.status = 'OP'
						OR (ps.amount_due_original + 
							   (SELECT nvl(SUM(nvl(ra.amount_applied_from, ra.amount_applied)), 0)
							FROM ar_receivable_applications ra, 
								 ar_payment_schedules ps_inv, 
								 ra_customer_trx inv_trx 
							WHERE ra.cash_receipt_id = cr.cash_receipt_id
							AND inv_trx.customer_trx_id = ra.applied_customer_trx_id
					AND RA.status = 'APP'
							AND ra.application_type = 'CASH'
							AND ra.apply_date <= l_billing_date
							AND ps_inv.customer_trx_id = inv_trx.customer_trx_id
									AND (ar_bfb_utils_pvt.is_payment_term_bfb(inv_trx.term_id) <> 'Y'
								 OR nvl(ps_inv.exclude_from_cons_bill_flag, 'N') = 'Y'))) <> 0)
					AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;
																																				
					/* ACTIVITY 11 : RECEIPT REVERSAL
					Reverse FULL receipt amount for receipt reversals of
					receipts created without site */
																																				
					write_debug_and_log('.........ACTIVITY 11: Reversal of receipts with no location');
																																				
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
						 PS.customer_id           =L_sites.customer_id
					AND  PS.customer_site_use_id  IS NULL
					AND    PS.cons_inv_id_rev       IS NULL
					AND    PS.invoice_currency_code = P_currency
					AND    PS.class                 = 'PMT'
					AND    CR.cash_receipt_id       = PS.cash_receipt_id
					AND    CR.reversal_date         <= l_billing_date
					AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
				AND     EXISTS 
						 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
					  FROM   ar_cons_inv c,
							 ar_cons_inv_trx ctrx
						  WHERE  PS.payment_schedule_id = ctrx.adj_ps_id
					  AND    c.cons_inv_id = ctrx.cons_inv_id
					  AND    c.status <> 'REJECTED')
					  AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;                                                                                                                                            
				 END IF;
			 END IF;
																																				
			/* Code changes ends for bug 5232547 */
			
			/* Bug 8832473 code changes start
			
			ACTIVITY 12 : RECEIPT ADJUSTMENT
					
			Below are the scenarios handled under this code:
			
			1. When the receipt is fully applied (no unapplied amount) to Invoices
			  with non-BFB term.
			  
			  There are two scenarios here. First one is if the receipt was already
			  included in a prior BFB and later applied to non-BFB invoice then the next
			  BFB should include a Receipt Adjustment entry to remove the receipt impact on
			  the BFB. For example if the receipt amount is 100 USD then receipt adjustment
			  entry will be for 100 USD. Second scenario is receipt was not included in any
			  prior BFB then in this case it should not appear on the current BFB.
			  
			2. When the receipt is partially applied (unapplied amount exists) to
			  Invoices with non-BFB term.
			  
			  In this scenario the BFB should contain the entry for the receipt for
			  full amount and a receipt adjustment entry for the amount applied to non-BFB
			  term invoice. Example, receipt is for 100 USD and 25 USD is applied to
			  non-BFB term invoice. Then BFB will contain -100 USD for the receipt and 25
			  USD for the receipt adjustment.
			*/

					write_debug_and_log('.........ACTIVITY 12 : RECEIPT ADJUSTMENT');

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
							'RECEIPT ADJUST',
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
						  ra_customer_trx inv_trx,
						  ar_payment_schedules ps_app
					WHERE
						   RA.cons_inv_id IS NULL
					AND    RA.status                     = 'APP'
					AND    RA.application_type           = 'CASH'
					AND    RA.apply_date                <= l_billing_date
					AND    ps_cash.payment_schedule_id   = RA.payment_schedule_id
					AND    ps_cash.customer_site_use_id  = L_sites.site_id
					AND    ps_cash.invoice_currency_code = P_currency
					AND    nvl(ps_cash.exclude_from_cons_bill_flag, 'N') <> 'Y'
					AND    inv_trx.CUSTOMER_TRX_ID       = RA.APPLIED_CUSTOMER_TRX_ID
					AND    ra.applied_payment_schedule_id = ps_app.payment_schedule_id
			AND     EXISTS 
						 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
					  FROM   ar_cons_inv c,
							 ar_cons_inv_trx ctrx
						  WHERE  ps_cash.payment_schedule_id = ctrx.adj_ps_id
				  AND    ctrx.transaction_type = 'RECEIPT'
					  AND    c.cons_inv_id = ctrx.cons_inv_id
					  AND    c.status <> 'REJECTED')
			 AND   NOT EXISTS (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
						   FROM ar_cons_inv c,
								ar_cons_inv_trx ctrx
						   WHERE inv_trx.customer_trx_id = ctrx.customer_trx_id
						   AND   c.cons_inv_id = ctrx.cons_inv_id
						   AND   c.status <> 'REJECTED'
						   UNION ALL
						   select '*'
						   FROM ar_cons_inv c,
								ar_cons_inv_trx ctrx
						   where c.cons_inv_id=ps_app.cons_inv_id
						   AND   c.status <> 'REJECTED'
						   AND ctrx.cons_inv_id=c.cons_inv_id
						   AND ctrx.customer_trx_id is null
						   AND ctrx.adj_ps_id=ps_app.payment_schedule_id )
							AND    1=2  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;
				 --bug 12349325
			UNION
			SELECT
				  l_consinv_id,
				  'RECEIPT ADJUST',
				  ps_cash.trx_number,
				  RA.apply_date,
				  nvl (ra.amount_applied_from, RA.amount_applied),
				  NULL,
				  RA.receivable_application_id,
				  NULL,
				  ps_cash.org_id
			FROM
				  ar_receivable_applications RA,
				  ar_payment_schedules ps_cash
			WHERE
				   RA.cons_inv_id IS NULL
			AND    RA.applied_payment_schedule_id  = -3
			AND    RA.application_type           = 'CASH'
			AND    RA.apply_date                <= l_billing_date
			AND    ps_cash.payment_schedule_id   = RA.payment_schedule_id
			AND    ps_cash.customer_site_use_id  = L_sites.site_id
			AND    ps_cash.invoice_currency_code = P_currency
			AND    nvl(ps_cash.exclude_from_cons_bill_flag, 'N') <> 'Y'
			AND     EXISTS 
				 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
				  FROM   ar_cons_inv c,
					 ar_cons_inv_trx ctrx
				  WHERE  ps_cash.payment_schedule_id = ctrx.adj_ps_id
				  AND    c.cons_inv_id = ctrx.cons_inv_id
							  AND    ctrx.transaction_type = 'RECEIPT'
						  AND    c.status <> 'REJECTED')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;
					
			/* Bug 8832473 code changes end  */  


			/** For Site: calculate totals **/
			SELECT nvl(sum(amount_original),0)
			INTO   l_period_trx
			FROM   ar_cons_inv_trx
			WHERE  cons_inv_id = l_consinv_id
			AND    transaction_type IN ('INVOICE', 'DEBIT_MEMO', 'DEPOSIT', 'CHARGEBACK');

			SELECT nvl(sum(amount_original),0)
			INTO   l_period_receipts
			FROM   ar_cons_inv_trx
			WHERE  cons_inv_id      = l_consinv_id
			AND    transaction_type IN ('RECEIPT','RECEIPT REV','XSITE RECREV',
										'XSITE RECAPP',
										'XCURR RECAPP', 'XCURR RECREV', 
							'XSITE XCURR RECAPP','XSITE XCURR RECREV',
						'EXCLUDE RECREV', 'EXCLUDE RECAPP','RECEIPT ADJUST'); 

			SELECT nvl(sum(amount_original),0)
			INTO   l_period_finchrg
			FROM   ar_cons_inv_trx
			WHERE  cons_inv_id = l_consinv_id
			AND    transaction_type IN ('FINANCE CHARGE');
	 
			SELECT nvl(sum(amount_original),0)
			INTO   l_period_adj
			FROM   ar_cons_inv_trx
			WHERE  cons_inv_id = l_consinv_id
			AND    transaction_type = 'ADJUSTMENT';

			SELECT nvl(sum(amount_original),0)
			INTO   l_period_credits
			FROM   ar_cons_inv_trx
			WHERE  cons_inv_id = l_consinv_id
			AND    transaction_type IN ('CREDIT_MEMO',
										'XSITE_CMREV','XSITE_CMAPP',
										'EXCLUDE_CMREV', 'EXCLUDE_CMAPP',
										'DELAY_CMAPP');
	 
			SELECT nvl(sum(tax_amount),0)
			INTO   l_period_tax
			FROM   ar_cons_inv_trx_lines
			WHERE  cons_inv_id = l_consinv_id;

			
			UPDATE ar_cons_inv
			SET    total_receipts_amt = l_period_receipts,
				   total_adjustments_amt = l_period_adj,
				   total_credits_amt = l_period_credits,
				   total_finance_charges_amt = l_period_finchrg, 
				   total_trx_amt = l_period_trx,
				   total_tax_amt = l_period_tax,
				   ending_balance = beginning_balance + l_period_trx + l_period_receipts +
									l_period_adj + l_period_credits + l_period_finchrg 
			WHERE  cons_inv_id    = l_consinv_id;

			/** For Site: update ar_payment_schedules, ar_receivable_applications 
				and ar_adjustments **/

			write_debug_and_log('Updating AR_PAYMENT_SCHEDULES');

			UPDATE  ar_payment_schedules PS
			SET     PS.cons_inv_id = l_consinv_id
			WHERE   PS.payment_schedule_id IN
					   (SELECT IT.adj_ps_id
						FROM   ar_cons_inv_trx IT
						WHERE  IT.cons_inv_id      = l_consinv_id
						AND    IT.transaction_type IN ('INVOICE','CREDIT_MEMO', 'DEBIT_MEMO', 'DEPOSIT', 'CHARGEBACK', 
													   'RECEIPT'));
	 
			UPDATE  ar_payment_schedules PS
			SET     PS.cons_inv_id_rev = l_consinv_id
			WHERE   PS.payment_schedule_id IN
					   (SELECT IT.adj_ps_id 
						FROM   ar_cons_inv_trx IT
						WHERE  IT.cons_inv_id      = l_consinv_id
						AND    IT.transaction_type = 'RECEIPT REV')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;
	 
			write_debug_and_log('Updating AR_RECEIVABLE_APPLICATIONS');
	 
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
							   'EXCLUDE_CMREV',
				   'RECEIPT ADJUST'));    -- Bug 8946152
	 
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
							   'EXCLUDE_CMAPP',
							  'DELAY_CMAPP')) --Bug 13406831
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;
	 
			write_debug_and_log('Updating AR_ADJUSTMENTS');
	 
			UPDATE  ar_adjustments  RA
			SET     RA.cons_inv_id = l_consinv_id
			WHERE   RA.adjustment_id IN
					   (SELECT /*+ index (IT AR_CONS_INV_TRX_N1)  */
							   IT.adj_ps_id
						FROM   ar_cons_inv_trx IT
						WHERE  IT.cons_inv_id      = l_consinv_id
						AND    IT.transaction_type = 'ADJUSTMENT')
			 AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;
	 
			write_debug_and_log('Updating AR_CONS_INV');

		-- bug2778646 Changed status of selected merged cbi. 
		   --            DRAFT_MERGE/MERGED status CBI is not selected by other CBI.
		   UPDATE ar_cons_inv ci
		   SET status = DECODE(P_print_option, 'DRAFT', 'DRAFT_MERGE','MERGED')
		   WHERE status = 'MERGE_PENDING'
		   AND site_use_id   = L_sites.site_id
		   AND currency_code = P_currency
		   AND nvl(billing_date,cut_off_date) <= l_billing_date ;

			-- 6955957
			-- update ra_customer_trx_all with the printing dates for all the transactions included.
			UPDATE ra_customer_trx trx 
			SET printing_original_date = nvl(printing_original_date, SYSDATE), 
				printing_last_printed = nvl(printing_last_printed, SYSDATE)
			WHERE trx.trx_number IN 
				  (SELECT trx_number 
				   FROM ar_cons_inv_trx IT 
				   WHERE IT.cons_inv_id = l_consinv_id );

		  --Get the Aging information and update the 
		  -- aging buckets on the Bill  
		  -- 
			  ar_cmgt_aging.calc_aging_buckets(
				  l_party_id,
				  L_sites.customer_id,
				  L_sites.site_id,
				  P_currency,
				  NULL,
				  l_bucket_name,
				  arp_standard.sysparm.org_id,
				  NULL,
				  'CONS_BILL',
				  l_outstanding_balance,
				  l_bucket_titletop_0,
				  l_bucket_titlebottom_0,
				  l_bucket_amount_0,
				  l_bucket_titletop_1,
				  l_bucket_titlebottom_1,
				  l_bucket_amount_1,
				  l_bucket_titletop_2,
				  l_bucket_titlebottom_2,
				  l_bucket_amount_2,
				  l_bucket_titletop_3,
				  l_bucket_titlebottom_3,
				  l_bucket_amount_3,
				  l_bucket_titletop_4,
				  l_bucket_titlebottom_4,
				  l_bucket_amount_4,
				  l_bucket_titletop_5,
				  l_bucket_titlebottom_5,
				  l_bucket_amount_5,
				  l_bucket_titletop_6,
				  l_bucket_titlebottom_6,
				  l_bucket_amount_6);

			  UPDATE ar_cons_inv
		  SET aging_bucket1_amt = l_bucket_amount_0,
				  aging_bucket2_amt = l_bucket_amount_1,
				  aging_bucket3_amt = l_bucket_amount_2,
				  aging_bucket4_amt = l_bucket_amount_3,
				  aging_bucket5_amt = l_bucket_amount_4,
				  aging_bucket6_amt = l_bucket_amount_5,
				  aging_bucket7_amt = l_bucket_amount_6
			  WHERE cons_inv_id = l_consinv_id;
		
		--Added for Bill Complete. If Bill Complete Customer has Consolidating bills to parent bill NAIT-61963.
		ELSIF	ln_bill_comp_cust_cnt >0 AND ln_bill_signal_cnt > 0 THEN --Recommend Jira 72552	
 write_debug_and_log(' cons');
				BEGIN
					SELECT  sum(total_trx_amt), max(beginning_balance)
					INTO    l_tota_trx_max_balance, l_beginning_max_balance
					FROM    ar_cons_inv CI1
					WHERE   CI1.site_use_id   = L_sites.site_id
					AND     CI1.currency_code = P_currency
					AND    (CI1.status       IN ('ACCEPTED', 'FINAL')
					AND     nvl(CI1.billing_date,CI1.cut_off_date)  =
						(SELECT max(nvl(CI2.billing_date,CI2.cut_off_date))
						FROM   ar_cons_inv CI2
						WHERE  CI2.site_use_id   = L_sites.site_id
						AND    CI2.currency_code = P_currency
						AND    CI2.status       IN ('ACCEPTED', 'FINAL'))
						OR (CI1.status = 'MERGE_PENDING'
						AND nvl(CI1.billing_date,CI1.cut_off_date) <= l_billing_date));
				EXCEPTION
				WHEN NO_DATA_FOUND THEN
				l_beginning_balance := 0;
				END;
				
				l_beginning_balance	:=	l_beginning_max_balance+l_tota_trx_max_balance;

				FOR L_inv_parent IN C_inv_parent(L_sites.site_id, L_sites.customer_id) LOOP	
								
				l_consinv_lineno := 1;
				
				IF L_inv_parent.bill_print_flag = 'Y'
				THEN
					lc_cons_bill_num	:=	L_inv_parent.order_number;
				ELSE
					lc_cons_bill_num	:=	L_inv_parent.parent_order_number;
				END IF;
				
					SELECT ar_cons_inv_s.NEXTVAL
					INTO   l_consinv_id
					FROM   dual;
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
									   due_date,
									   currency_code,
									   beginning_balance,
									   ending_balance,
									   org_id,
									   billing_date,
									   bill_level_flag,
									   last_billing_date,
									   billing_cycle_id,
									   remit_to_address_id)
				VALUES                  (l_consinv_id,
									   lc_cons_bill_num,
									   L_sites.customer_id,
									   L_sites.site_id,
									   arp_standard.profile.request_id,
									   arp_global.last_update_date,
									   arp_global.last_updated_by,
									   arp_global.creation_date,
									   arp_global.created_by,
									   arp_global.last_update_login,
									   --Bug 5203710 get the cons_inv_type from customer setup
									   L_sites.cons_inv_type,
									   P_print_option,
									   P_print_status,
									   L_terms.term_id,
									   sysdate,
									   l_due_date,
									   P_currency,
									   nvl(l_beginning_balance,0),
									   0,
									   arp_standard.sysparm.org_id,
									   l_billing_date,
									   L_sites.bill_level,
									   l_last_bill_date,
									   P_billing_cycle_id,
									   l_remit_to_address_id);
			  -- Added For NAIT- 109439
			  l_trx_type_id:=0;	
			  BEGIN
			    SELECT rct.CUST_TRX_TYPE_ID 
				  INTO l_trx_type_id
				  FROM RA_CUST_TRX_TYPES_ALL rct
                 WHERE 1=1 
                   AND rct.name = 'US_SERVICE_AOPS_OD'
                  ;
			  EXCEPTION
			      WHEN OTHERS THEN
				  l_trx_type_id:=0;				  
			  END;		

write_debug_and_log('L_sites.site_id '||L_sites.site_id||'l_billing_date '||l_billing_date);	
write_debug_and_log('lc_cons_bill_num '||lc_cons_bill_num||'P_currency '||P_currency);	
write_debug_and_log('L_inv_parent.bill_print_flag '||L_inv_parent.bill_print_flag||'l_trx_type_id '||l_trx_type_id);				  
			  FOR L_inv_trx IN C_inv_trx_parent(L_sites.site_id, l_billing_date, P_currency, lc_cons_bill_num, L_inv_parent.bill_print_flag,l_trx_type_id) -- Added parameter For NAIT- 109439
			  LOOP		
				 write_debug_and_log(' ');
				 write_debug_and_log('.........Loop C_inv_trx for site = ' || to_char(L_sites.site_id));
				 write_debug_and_log('.........trx_id       :'||TO_CHAR(L_inv_trx.trx_id));
				 write_debug_and_log('.........trx_date     :'||TO_CHAR(L_inv_trx.trx_date));
				 write_debug_and_log('.........trx_number   :'||L_inv_trx.trx_number);
				 write_debug_and_log('.........class        :'||L_inv_trx.class);
				 write_debug_and_log('.........term_id      :'||TO_CHAR(L_inv_trx.term_id));
				 write_debug_and_log('.........billing_date :'||TO_CHAR(L_inv_trx.billing_date));
	  
				 -- initialize comment 
				 l_comments := '';
				 l_bypass_trx := FALSE;
				 
				 -- set the value of l_check_override to l_tab_idx so that we can check 
				 -- after process_override whether an update has taken place by comparing
				 -- these two variables. bug 6488683
				 l_check_override := l_tab_idx;
	  
				 -- Prior to inserting into ar_cons_inv_trx, need to perform validation and override if necessary 
				 IF nvl(L_inv_trx.term_id,'-1') <> L_terms.term_id THEN
	  
					IF L_inv_trx.class = 'CM' THEN
			/* Bug 9392028 */
				  SELECT count(*)
			   INTO l_cm_flag
			   FROM ar_payment_schedules ps,
					ra_customer_trx      ct
			   WHERE ps.customer_trx_id = l_inv_trx.trx_id
			   AND   ct.customer_trx_id = ps.customer_trx_id
			   AND   ps.status = 'OP'
			   AND   ct.previous_customer_trx_id IS NULL;

			   IF l_cm_flag = 0 THEN
				 --Resetting the same flag l_cm_flag.

						SELECT count(*)
				 INTO l_cm_flag
				 FROM RA_CUSTOMER_TRX ct,
					  AR_PAYMENT_SCHEDULES ps
				 WHERE ct.customer_trx_id IN (Select ra.APPLIED_CUSTOMER_TRX_ID
										   FROM ar_receivable_applications ra
							   WHERE ra.customer_trx_id = l_inv_trx.trx_id
												   AND   ra.status = 'APP'
												   AND   ra.application_type = 'CM'
												   AND   ra.apply_date <= l_billing_date
							   GROUP BY ra.APPLIED_CUSTOMER_TRX_ID
							   HAVING SUM(nvl(ra.amount_applied_from, ra.amount_applied)) <> 0)
						 AND ct.customer_trx_id = ps.customer_trx_id
						-- AND ar_bfb_utils_pvt.is_payment_term_bfb(ct.term_id) = 'Y'  -- commented on 08mar2012
						 AND nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
						 ---Added below condition to verify if associated INV is there in prior BFB
			 AND    EXISTS (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'                                         
				  FROM ar_cons_inv c,
					   ar_cons_inv_trx ctrx
				  WHERE ct.customer_trx_id = ctrx.customer_trx_id
				  AND   c.cons_inv_id = ctrx.cons_inv_id
				  AND   c.status <> 'REJECTED');

				 If l_cm_flag = 0 THEN
					l_bypass_trx := TRUE;
				 END IF;
			   END IF;

					   -- bypass additional validation, since CM's have no term id / billing date
					   write_debug_and_log('............bypassing BFB validation for CM');
		
					ELSE 
					   -- perform additional validation
		
					   IF L_sites.override_terms = 'Y' THEN
	  
						  IF ar_bfb_utils_pvt.is_payment_term_bfb(L_inv_trx.term_id) = 'N' THEN
							 -- trx does not have BFB term, bypass it
							 l_bypass_trx := TRUE;
						  ELSE
	  
							 write_debug_and_log('............override_terms = Y, term_id is different');
	  
							 process_override
								('TERM_ID',
								 L_inv_trx.trx_id,
								 L_inv_trx.class,
								 L_inv_trx.init_trx_id,
								 L_inv_trx.prev_trx_id,
								 L_inv_trx.billing_date,
								 L_inv_trx.term_id,
								 l_billing_date,
								 L_inv_trx.due_date,
								 L_terms.term_id,
								 l_comments,
								 l_bypass_trx);
	  
						  END IF;
	  
					   ELSE  
						  write_debug_and_log('............override_terms = N, term_id is different');
			  
			  /* Bug 9092366: When the transaction and the customer profile have different
				 payment terms, and if the 'Override Terms' is unchecked, then that
				 transaction should not be processed. */                         
						  l_bypass_trx := TRUE;
		
					   END IF; 
					END IF;
	  
				 ELSE 
	  
					IF nvl(trunc(L_inv_trx.billing_date),to_date('12/31/4712','MM/DD/YYYY')) = 
					   trunc(l_billing_date) THEN
	  
					   write_debug_and_log('............BFB data fully compliant');
					   l_comments := 'FULLY COMPLIANT';
					ELSE
					   write_debug_and_log('............billing_date is different');
					   process_override
						 ('BILLING_DATE',
						  L_inv_trx.trx_id,
						  L_inv_trx.class,
						  L_inv_trx.init_trx_id,
						  L_inv_trx.prev_trx_id,
						  L_inv_trx.billing_date,
						  L_inv_trx.term_id,
						  l_billing_date,
						  L_inv_trx.due_date,
						  L_terms.term_id,
						  l_comments,
						  l_bypass_trx);
					END IF;
				 END IF; 
	  
				IF NOT l_bypass_trx THEN
				
					-- get the current value of payment schedule id in case 
					-- it is changed for overridden payment terms . 
					-- If it is not overridden, assign the actual value of 
					-- payment_schedule_id . bug 6488683
					IF ( l_tab_idx > l_check_override ) THEN
					   OPEN ps_cur(L_inv_trx.trx_id);
					   FETCH ps_cur INTO l_new_schedule_id;
					   CLOSE ps_cur;
					ELSE
					   l_new_schedule_id := L_inv_trx.schedule_id;
					END IF;
						  
				   write_debug_and_log('new payment schedule id ' || l_new_schedule_id ); 
				   write_debug_and_log('insert to ar_cons_inv_trx for ' || L_inv_trx.trx_id);
				   
				   INSERT INTO ar_cons_inv_trx (cons_inv_id,
												transaction_type,
												trx_number,
												transaction_date,
												amount_original,
												tax_original,
												adj_ps_id,
												cons_inv_line_number,
												org_id,
												justification,
												trx_description,
												customer_trx_id,
												ship_to_site_id)
				   VALUES                      (l_consinv_id,
												DECODE(L_inv_trx.class,
													   'CM','CREDIT_MEMO',
													   'DM','DEBIT_MEMO',
													   'DEP','DEPOSIT',
													   'CB','CHARGEBACK',
													   'INVOICE'),
												L_inv_trx.trx_number,
												L_inv_trx.trx_date,
												L_inv_trx.amount_due,
												L_inv_trx.tax,
												l_new_schedule_id,    -- bug 6488683
												l_consinv_lineno,
												arp_standard.sysparm.org_id,
												l_comments,
												L_inv_trx.trx_desc,
												L_inv_trx.trx_id,
												L_inv_trx.ship_id);
	   
				   /** For audit purposes, insert detail line information even if 
					   reporting in summary. Also note that cons_inv_line_number 
					   is one value for detail lines for a specific invoice. **/ 
	   
				   write_debug_and_log('insert to ar_cons_inv_trx_lines for ' || L_inv_trx.trx_id);
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
				   SELECT l_consinv_id,
						  l_consinv_lineno,
						  customer_trx_id,
						  customer_trx_line_id,
						  line_number,
						  inventory_item_id,
						  description,
						  uom_code,
						  decode(L_inv_trx.class,'CM', quantity_credited,quantity_invoiced),
						  nvl (gross_unit_selling_price, unit_selling_price),
						  nvl (gross_extended_amount, extended_amount),
						  0,
						  org_id
				   FROM   ra_customer_trx_lines
				   WHERE  customer_trx_id  = L_inv_trx.trx_id
				   AND    line_type NOT IN ('TAX', 'FREIGHT');
					--Added for Bill Complete. Marking as Completed if bill is generated for Child Order NAIT-61963.
					BEGIN
						UPDATE xx_scm_bill_signal
						SET Bill_forward_flag	 =	'C',
							last_update_date 	 = arp_global.last_update_date,
							last_updated_by 	 = arp_global.last_updated_by,
							last_update_login 	 = arp_global.last_update_login
						WHERE child_order_number = L_inv_trx.trx_number
						AND Bill_forward_flag    = 'N' ;
					
						FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill_forward_flag Updated Count : '|| sql%rowcount );
					EXCEPTION
					WHEN NO_DATA_FOUND THEN
						 FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND: Xx_Scm_Bill_Signal ');
					WHEN OTHERS THEN
						FND_FILE.PUT_LINE(FND_FILE.LOG,'Other EXCEPTION: lc_Bill_Comp_Flag '||SQLERRM );
					END;						
							
				   /** now update lines with associated tax line **/
	   
				   write_debug_and_log('update ar_cons_inv_trx_lines for TAX');
				   OPEN c_tax(L_inv_trx.trx_id);
				   LOOP
					  FETCH c_tax BULK COLLECT INTO
					  l_line_id , l_tax_sum, l_include_tax_sum LIMIT l_bulk_fetch_rows;
					
					  -- 1. Update tax_amount 
					  -- 2. Exclude inclusive tax amount total from extended_amount
					  FORALL i IN 1..l_line_id.count
						 UPDATE ar_cons_inv_trx_lines
						 SET    tax_amount = l_tax_sum(i),
								extended_amount = extended_amount - l_include_tax_sum(i)
						 WHERE  customer_trx_id = L_inv_trx.trx_id
						 AND    customer_trx_line_id = l_line_id(i) ;
		 
					  EXIT WHEN c_tax%NOTFOUND ;
				   END LOOP; 
				   CLOSE c_tax;
	   
				   /** now create 1 summary row for freight **/
				   write_debug_and_log('insert to ar_cons_inv_trx_lines for FREIGHT');
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
				   
				END IF; /* NOT l_bypass_trx */

			 END LOOP; /* c_inv_trx */
			
			 write_debug_and_log('.........Done with Loop C_inv_trx');
			 
			 /** TRANSACTION ACTIVITY :
				 Pick up all Receipts / CMs / Adjustments that affect the BFB balance **/

			 /* Bug 9392028 Modified Activities */

			 /* ACTIVITY 1 : ADJUSTMENTS
				pick up all adjustments except finance charges generated against this BFB site 
				(fin charge is in next select ACTIVITY 1A) */
	  
			 write_debug_and_log('.........ACTIVITY 1');

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
					ADJ.apply_date,
					ADJ.amount,
					NVL(ADJ.tax_adjusted, 0),
					ADJ.adjustment_id,
					NULL,
					ps.org_id
			 FROM
				  ar_adjustments ADJ,
				  ar_payment_schedules PS
			 WHERE
					ADJ.cons_inv_id is NULL
			 AND    ADJ.apply_date               <= l_billing_date
			 AND    ADJ.type in ('CHARGES','FREIGHT','INVOICE','LINE','TAX')
			 AND    ADJ.created_from         <> 'ARFCCF'    -- exclude auto-generated finance charges
			 AND    ADJ.status = 'A'
			 AND    PS.payment_schedule_id   = ADJ.payment_schedule_id
			 AND    PS.customer_site_use_id  = L_sites.site_id
			 AND    PS.invoice_currency_code = P_currency
			 AND    PS.class||''             <> 'GUAR'
			 AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
			 AND    EXISTS (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
						   FROM ar_cons_inv c,
								ar_cons_inv_trx ctrx
						   WHERE adj.customer_trx_id = ctrx.customer_trx_id
						   AND   c.cons_inv_id = ctrx.cons_inv_id
						   AND   c.status <> 'REJECTED')
			 AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;                       

			 /* ACTIVITY 1A : FINANCE CHARGES
				pick up all adjustments (only finance charges) generated against this BFB site */

			 write_debug_and_log('.........ACTIVITY 1A');

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
				  'FINANCE CHARGE',
				  PS.trx_number,
				  ADJ.apply_date,
				  ADJ.amount,
				  NVL(ADJ.tax_adjusted, 0),
				  ADJ.adjustment_id,
				  NULL,
				  ps.org_id
			 FROM
				  ar_adjustments ADJ,
				  ar_payment_schedules PS
			 WHERE
					ADJ.cons_inv_id is NULL
			 AND    ADJ.apply_date               <= l_billing_date
			 AND    ADJ.type = 'CHARGES'
			 AND    ADJ.created_from = 'ARFCCF'
			 AND    ADJ.status = 'A'
			 AND    PS.payment_schedule_id   = ADJ.payment_schedule_id
			 AND    PS.customer_site_use_id  = L_sites.site_id
			 AND    PS.invoice_currency_code = P_currency
			 AND    PS.class||''             <> 'GUAR'
			 AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
		 AND    EXISTS (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
						   FROM ar_cons_inv c,
								ar_cons_inv_trx ctrx
						   WHERE adj.customer_trx_id = ctrx.customer_trx_id
						   AND   c.cons_inv_id = ctrx.cons_inv_id
						   AND   c.status <> 'REJECTED')
		 AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

			 /* ACTIVITY 2 : RECEIPTS 
				pick up FULL receipt amount for receipts created against this BFB
				site (in ACTIVITY 4 : we back out amounts applied to diff site) */
	  
			 write_debug_and_log('.........ACTIVITY 2');
	  
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
			 WHERE PS.customer_site_use_id  = L_sites.site_id
			 AND    PS.cons_inv_id           IS NULL
			 AND    PS.class                 = 'PMT'
			 AND    PS.invoice_currency_code = P_currency
			 AND    CR.cash_receipt_id       = PS.cash_receipt_id
			 AND    CR.receipt_date          <= l_billing_date
			 AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
			 AND   (PS.status = 'OP'
				 OR    (ps.amount_due_original + 
						 (SELECT nvl(SUM(nvl(ra.amount_applied_from, ra.amount_applied)), 0)
						  FROM ar_receivable_applications ra, 
							   ar_payment_schedules ps_inv, 
							   ra_customer_trx inv_trx 
						  WHERE ra.cash_receipt_id = cr.cash_receipt_id
						  AND inv_trx.customer_trx_id = ra.applied_customer_trx_id
						  AND RA.status = 'APP'
						  AND ra.application_type = 'CASH'
						  AND ra.apply_date <= l_billing_date
						  AND ps_inv.customer_trx_id = inv_trx.customer_trx_id
						  AND (Decode(ps_inv.class ,'CM','Y',ar_bfb_utils_pvt.is_payment_term_bfb(inv_trx.term_id)) <> 'Y' /* Bug 13485325 */
						   OR nvl(ps_inv.exclude_from_cons_bill_flag, 'N') = 'Y'))) <> 0)
			  AND 1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM; 
	  
			 /* ACTIVITY 3 : RECEIPT REVERSAL 
				Reverse FULL receipt amount for receipt reversals of 
				receipts created against this BFB site */
	  
			 write_debug_and_log('.........ACTIVITY 3');

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
			 AND    PS.class                 = 'PMT'
			 AND    CR.cash_receipt_id       = PS.cash_receipt_id
			 AND    CR.reversal_date         <= l_billing_date
			 AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
		 AND     EXISTS 
				 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
			  FROM   ar_cons_inv c,
					 ar_cons_inv_trx ctrx
				  WHERE  PS.payment_schedule_id = ctrx.adj_ps_id
			  AND    c.cons_inv_id = ctrx.cons_inv_id
			  AND    c.status <> 'REJECTED')
			  AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;

			 /* ACTIVITY 4 : Exclude RECEIPT APPLICATIONS for Receipts 
				with this BFB site which are applied to TRX which have 
				a different site */ 

			 write_debug_and_log('.........ACTIVITY 4');

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
			 AND    RA.apply_date                <= l_billing_date
			 AND    ps_cash.payment_schedule_id   = RA.payment_schedule_id
			 AND    ps_cash.customer_site_use_id  = L_sites.site_id
			 AND    ps_cash.invoice_currency_code = P_currency
			 AND    ps_inv.payment_schedule_id    = RA.applied_payment_schedule_id
			 AND    nvl(ps_cash.exclude_from_cons_bill_flag, 'N') <> 'Y' 
			 AND   (   ps_cash.customer_site_use_id  <> ps_inv.customer_site_use_id
				  OR ps_cash.invoice_currency_code  <> ps_inv.invoice_currency_code) -- bug 17659675
	--                OR RA.amount_applied_from IS NOT NULL) --Bug 8208763
	--                OR nvl(ps_inv.exclude_from_cons_bill_flag, 'N') = 'Y')
		 AND     EXISTS 
				 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
			  FROM   ar_cons_inv c,
					 ar_cons_inv_trx ctrx
				  WHERE  RA.payment_schedule_id = ctrx.adj_ps_id
			  AND    c.cons_inv_id = ctrx.cons_inv_id
			  AND    c.status <> 'REJECTED')
			 AND     EXISTS                                         --bug 12349325
				 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
				FROM   ar_cons_inv c,
					 ar_cons_inv_trx ctrx
				  WHERE  ps_inv.payment_schedule_id = ctrx.adj_ps_id
			  AND    c.cons_inv_id = ctrx.cons_inv_id
			  AND    c.status <> 'REJECTED')
			  AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;

			 /* ACTIVITY 5 : Include RECEIPT APPLICATIONS for Receipts created with
				different (or null) site, but applied to TRX with this BFB Site */

			 write_debug_and_log('.........ACTIVITY 5');

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
			 AND    RA.apply_date               <= l_billing_date
			 AND    ps_cash.payment_schedule_id  = RA.payment_schedule_id
			 AND    ps_inv.payment_schedule_id   = RA.applied_payment_schedule_id
			 AND    ps_inv.customer_site_use_id  = L_sites.site_id
			 AND    ps_inv.invoice_currency_code = P_currency
			 AND    nvl(ps_inv.exclude_from_cons_bill_flag, 'N') <> 'Y'
			 AND   (   nvl(ps_cash.customer_site_use_id, -1) <> ps_inv.customer_site_use_id
	--                OR ra.amount_applied_from IS NOT NULL
			OR ps_cash.invoice_currency_code  <> ps_inv.invoice_currency_code -- bug 17659675
					OR nvl(ps_cash.exclude_from_cons_bill_flag, 'N') = 'Y')
		 AND     EXISTS 
				 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'  -- bug 19248291
			  FROM   ar_cons_inv c,
					 ar_cons_inv_trx ctrx
				  WHERE  ps_inv.customer_trx_id = ctrx.customer_trx_id
			  AND    c.cons_inv_id = ctrx.cons_inv_id
			  AND    c.status <> 'REJECTED')
			  AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

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
										cons_inv_line_number)
		   SELECT
				  l_consinv_id,
				  DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
								  'XSITE RECAPP', 'XSITE XCURR RECAPP'),
				  ps_cash.trx_number,
				  RA.apply_date,
				  (-1)*RA.amount_applied,
				  NULL,
				  RA.receivable_application_id,
				  NULL
		   FROM
				  ar_cons_inv_trx inv_trx,
				  ar_receivable_applications ra,
				  ar_payment_schedules ps_cash,
				  ar_payment_schedules ps_inv
		  WHERE ra.cons_inv_id_to is null
		  AND ra.cons_inv_id is not null
		  AND ra.status = 'APP'
		  AND ra.application_type = 'CASH'
	AND ra.apply_date <  to_date(l_billing_date)
		  AND    ps_cash.payment_schedule_id  = RA.payment_schedule_id
		  AND    ps_inv.payment_schedule_id   = RA.applied_payment_schedule_id
		  AND    ps_inv.customer_site_use_id  = L_sites.site_id
		  AND    ps_inv.invoice_currency_code = P_currency
		  AND ps_cash.customer_site_use_id = ps_inv.customer_site_use_id
		  AND ra.receivable_application_id = inv_trx.adj_ps_id
		  AND inv_trx.transaction_type IN ('XSITE RECREV','XSITE XCURR RECREV')
		  AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

			 /* ACTIVITY 6 : When a receipt is originally created without a location, 
				and is immediately applied to an invoice, the receipt's ps.customer_site_use_id 
				remains NULL, hence such an application is considered in ACTIVITY 5.
				Now if later, that receipt is updated with a Location = this BFB site the 
				receipt will now be picked up in ACTIVITY 2. 

				The following select is necessary to counter what was previously picked up 
				in ACTIVITY 5, otherwise the receipt application is recorded twice */
	  
			 write_debug_and_log('.........ACTIVITY 6');
	  
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
			AND ra.apply_date <=  l_billing_date
			AND ps_cash.payment_schedule_id = ra.payment_schedule_id
			AND ps_cash.customer_site_use_id =  L_sites.site_id
			AND ps_cash.invoice_currency_code = P_currency
			AND ps_inv.payment_schedule_id = ra.applied_payment_schedule_id
			AND ps_cash.customer_site_use_id = ps_inv.customer_site_use_id
			AND ra.receivable_application_id = inv_trx.adj_ps_id
			AND inv_trx.transaction_type IN ('XSITE RECAPP','XSITE XCURR RECAPP')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

			/* ACTIVITY 7 : When a receipt is originally created without a location,
			   and is immediately applied to an invoice, the receipt's ps.customer_site_use_id
			   remains NULL, hence such an application is considered in ACTIVITY 5.
			   Now if later, that receipt is updated with a Location different from this BFB site
			   we need to exclude it. */
	  
			 write_debug_and_log('.........ACTIVITY 7');
	   
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
			AND   ra.cons_inv_id is not null
			AND   ra.status = 'APP'
			AND   ra.application_type = 'CASH'
			AND   ra.apply_date <=  l_billing_date
			AND   ps_cash.payment_schedule_id  = RA.payment_schedule_id
			AND   ps_inv.payment_schedule_id   = RA.applied_payment_schedule_id
			AND   ps_inv.customer_site_use_id  = L_sites.site_id
			AND   ps_inv.invoice_currency_code = P_currency
			AND   ps_cash.customer_site_use_id = ps_inv.customer_site_use_id
			AND   ra.receivable_application_id = inv_trx.adj_ps_id
			AND   inv_trx.transaction_type IN ('XSITE RECREV','XSITE XCURR RECREV')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

			/* ACTIVITY 8 : CM applications where CM is for this BFB site, but
			   applied to an invoice having a different site */

			write_debug_and_log('.........ACTIVITY 8');

			INSERT INTO ar_cons_inv_trx (cons_inv_id,
										transaction_type,
										trx_number,
										transaction_date,
										amount_original,
										tax_original,
										adj_ps_id,
										cons_inv_line_number,
										org_id)
			SELECT /*+ ORDERED */
				  l_consinv_id,
				  DECODE(nvl(PS_INV.exclude_from_cons_bill_flag,'N'), 
					  'Y', 'EXCLUDE_CMREV', 
						   'XSITE_CMREV'),
				  PS_CM.trx_number,
				  RA.apply_date,
				  RA.amount_applied,
				  NULL,
				  RA.receivable_application_id,
				  NULL,
				  PS_CM.org_id
			FROM  
				 AR_PAYMENT_SCHEDULES PS_CM ,
				 AR_RECEIVABLE_APPLICATIONS RA ,
				 AR_PAYMENT_SCHEDULES PS_INV,
				 AR_CONS_INV_TRX CTRX,
				 AR_CONS_INV C
			WHERE
				   RA.cons_inv_id IS NULL
			AND    RA.status                 = 'APP'
			AND    RA.application_type       = 'CM'
			AND    RA.apply_date            <= l_billing_date
			AND    PS_CM.payment_schedule_id   = RA.payment_schedule_id
			AND    PS_CM.customer_site_use_id  = L_sites.site_id
			AND    PS_CM.invoice_currency_code = P_currency
			AND    nvl(PS_CM.exclude_from_cons_bill_flag, 'N') <> 'Y'
			AND    PS_INV.payment_schedule_id   = RA.applied_payment_schedule_id
			AND   ( PS_INV.customer_site_use_id <> PS_CM.customer_site_use_id
					or nvl(PS_INV.exclude_from_cons_bill_flag, 'N') = 'Y' ) 
			AND   PS_CM.customer_trx_id = ctrx.customer_trx_id
			AND    c.cons_inv_id = ctrx.cons_inv_id
			AND    c.status <> 'REJECTED'
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;

		   /* ACTIVITY 8A : CM applied to INV both have same BFB site, BUT
			  INV is not pulled into BFB yet, need to exclude */

			write_debug_and_log('.........ACTIVITY 8A');

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
				  'DELAY_CMAPP',
				  PS_CM.trx_number,
				  RA.apply_date,
				  RA.amount_applied,
				  NULL,
				  RA.receivable_application_id,
				  NULL,
				  PS_CM.org_id
			FROM
				  ar_receivable_applications RA,
				  ar_payment_schedules PS_CM,
				  ar_payment_schedules PS_INV
			WHERE
				   RA.cons_inv_id_to IS NULL
			AND    RA.status                 = 'APP'
			AND    RA.application_type       = 'CM'
			AND    RA.apply_date            <= l_billing_date
			AND    PS_CM.payment_schedule_id   = RA.payment_schedule_id
			AND    PS_CM.customer_site_use_id  = L_sites.site_id
			AND    PS_CM.invoice_currency_code = P_currency
			AND    nvl(PS_CM.exclude_from_cons_bill_flag, 'N') <> 'Y'
			AND    PS_INV.payment_schedule_id  = RA.applied_payment_schedule_id
			AND    PS_INV.customer_site_use_id = L_sites.site_id
			AND    NOT EXISTS 
					(SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
					 FROM   ar_cons_inv c,
							ar_cons_inv_trx ctrx
					 WHERE  PS_INV.customer_trx_id = ctrx.customer_trx_id
					 AND    c.cons_inv_id = ctrx.cons_inv_id
					 AND    c.status <> 'REJECTED')
			AND    EXISTS
			   (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
					 FROM   ar_cons_inv c,
							ar_cons_inv_trx ctrx
					 WHERE  PS_CM.customer_trx_id = ctrx.customer_trx_id
					 AND    c.cons_inv_id = ctrx.cons_inv_id
					 AND    c.status <> 'REJECTED')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;

			/* ACTIVITY 9 : CM Applications where CM site is different, but applied to
			   TRX which has this BFB site
			   NOTE : do not pull in CM application if the INV it is applied to is not 
			   part of an BFB yet */

			write_debug_and_log('.........ACTIVITY 9');

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
				  DECODE( nvl(PS_CM.exclude_from_cons_bill_flag, 'N') , 'Y', 'EXCLUDE_CMAPP','XSITE_CMAPP') ,
				  PS_INV.trx_number,
				  RA.apply_date,
				  (-1)*RA.amount_applied,
				  NULL,
				  RA.receivable_application_id,
				  NULL,
				  PS_INV.org_id
			FROM
				  ar_receivable_applications RA,
				  ar_payment_schedules PS_INV,  -- INV
				  ar_payment_schedules PS_CM   -- CM
			WHERE
				   RA.cons_inv_id_to IS NULL
			AND    RA.status                 = 'APP'
			AND    RA.application_type       = 'CM'
			AND    RA.apply_date            <= l_billing_date
			AND    PS_INV.payment_schedule_id   = RA.applied_payment_schedule_id
			AND    PS_INV.customer_site_use_id  = L_sites.site_id
			AND    PS_INV.invoice_currency_code = P_currency
			AND    nvl(PS_INV.exclude_from_cons_bill_flag, 'N') <> 'Y'
			AND    PS_CM.payment_schedule_id   = RA.payment_schedule_id
			AND    ( PS_CM.customer_site_use_id <> PS_INV.customer_site_use_id
				or    nvl(PS_CM.exclude_from_cons_bill_flag, 'N') = 'Y')
			AND    EXISTS (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
						   FROM ar_cons_inv c,
								ar_cons_inv_trx ctrx
						   WHERE PS_INV.customer_trx_id = ctrx.customer_trx_id
						   AND   c.cons_inv_id = ctrx.cons_inv_id
						   AND   c.status <> 'REJECTED')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;


			/* Bug fix 5232547 : Receipts without Billing Location */
			 IF L_sites.bill_level = 'A' THEN
				 -- Run the inserts only once for a customer
				 IF l_customer_id <> L_sites.customer_id THEN
					l_customer_id := L_sites.customer_id;

					write_debug_and_log('.........ACTIVITY 10 : Receipts with No Location');
																																				
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
						 PS.customer_id           = L_sites.customer_id
					AND    PS.customer_site_use_id  IS NULL
					AND    PS.cons_inv_id           IS NULL
					AND    PS.class                 = 'PMT'
					AND    PS.invoice_currency_code = P_currency
					AND    CR.cash_receipt_id       = PS.cash_receipt_id
					AND    CR.receipt_date          <= l_billing_date
					AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
			AND    (PS.status = 'OP'
						OR (ps.amount_due_original + 
							   (SELECT nvl(SUM(nvl(ra.amount_applied_from, ra.amount_applied)), 0)
							FROM ar_receivable_applications ra, 
								 ar_payment_schedules ps_inv, 
								 ra_customer_trx inv_trx 
							WHERE ra.cash_receipt_id = cr.cash_receipt_id
							AND inv_trx.customer_trx_id = ra.applied_customer_trx_id
					AND RA.status = 'APP'
							AND ra.application_type = 'CASH'
							AND ra.apply_date <= l_billing_date
							AND ps_inv.customer_trx_id = inv_trx.customer_trx_id
									AND (ar_bfb_utils_pvt.is_payment_term_bfb(inv_trx.term_id) <> 'Y'
								 OR nvl(ps_inv.exclude_from_cons_bill_flag, 'N') = 'Y'))) <> 0)
					AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;
																																				
					/* ACTIVITY 11 : RECEIPT REVERSAL
					Reverse FULL receipt amount for receipt reversals of
					receipts created without site */
																																				
					write_debug_and_log('.........ACTIVITY 11: Reversal of receipts with no location');
																																				
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
						 PS.customer_id           =L_sites.customer_id
					AND  PS.customer_site_use_id  IS NULL
					AND    PS.cons_inv_id_rev       IS NULL
					AND    PS.invoice_currency_code = P_currency
					AND    PS.class                 = 'PMT'
					AND    CR.cash_receipt_id       = PS.cash_receipt_id
					AND    CR.reversal_date         <= l_billing_date
					AND    nvl(PS.exclude_from_cons_bill_flag, 'N') <> 'Y'
				AND     EXISTS 
						 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
					  FROM   ar_cons_inv c,
							 ar_cons_inv_trx ctrx
						  WHERE  PS.payment_schedule_id = ctrx.adj_ps_id
					  AND    c.cons_inv_id = ctrx.cons_inv_id
					  AND    c.status <> 'REJECTED')
					  AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;                                                                                                                                            
				 END IF;
			 END IF;
																																				
			/* Code changes ends for bug 5232547 */
			
			/* Bug 8832473 code changes start
			
			ACTIVITY 12 : RECEIPT ADJUSTMENT
					
			Below are the scenarios handled under this code:
			
			1. When the receipt is fully applied (no unapplied amount) to Invoices
			  with non-BFB term.
			  
			  There are two scenarios here. First one is if the receipt was already
			  included in a prior BFB and later applied to non-BFB invoice then the next
			  BFB should include a Receipt Adjustment entry to remove the receipt impact on
			  the BFB. For example if the receipt amount is 100 USD then receipt adjustment
			  entry will be for 100 USD. Second scenario is receipt was not included in any
			  prior BFB then in this case it should not appear on the current BFB.
			  
			2. When the receipt is partially applied (unapplied amount exists) to
			  Invoices with non-BFB term.
			  
			  In this scenario the BFB should contain the entry for the receipt for
			  full amount and a receipt adjustment entry for the amount applied to non-BFB
			  term invoice. Example, receipt is for 100 USD and 25 USD is applied to
			  non-BFB term invoice. Then BFB will contain -100 USD for the receipt and 25
			  USD for the receipt adjustment.
			*/

					write_debug_and_log('.........ACTIVITY 12 : RECEIPT ADJUSTMENT');

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
							'RECEIPT ADJUST',
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
						  ra_customer_trx inv_trx,
						  ar_payment_schedules ps_app
					WHERE
						   RA.cons_inv_id IS NULL
					AND    RA.status                     = 'APP'
					AND    RA.application_type           = 'CASH'
					AND    RA.apply_date                <= l_billing_date
					AND    ps_cash.payment_schedule_id   = RA.payment_schedule_id
					AND    ps_cash.customer_site_use_id  = L_sites.site_id
					AND    ps_cash.invoice_currency_code = P_currency
					AND    nvl(ps_cash.exclude_from_cons_bill_flag, 'N') <> 'Y'
					AND    inv_trx.CUSTOMER_TRX_ID       = RA.APPLIED_CUSTOMER_TRX_ID
					AND    ra.applied_payment_schedule_id = ps_app.payment_schedule_id
			AND     EXISTS 
						 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
					  FROM   ar_cons_inv c,
							 ar_cons_inv_trx ctrx
						  WHERE  ps_cash.payment_schedule_id = ctrx.adj_ps_id
				  AND    ctrx.transaction_type = 'RECEIPT'
					  AND    c.cons_inv_id = ctrx.cons_inv_id
					  AND    c.status <> 'REJECTED')
			 AND   NOT EXISTS (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
						   FROM ar_cons_inv c,
								ar_cons_inv_trx ctrx
						   WHERE inv_trx.customer_trx_id = ctrx.customer_trx_id
						   AND   c.cons_inv_id = ctrx.cons_inv_id
						   AND   c.status <> 'REJECTED'
						   UNION ALL
						   select '*'
						   FROM ar_cons_inv c,
								ar_cons_inv_trx ctrx
						   where c.cons_inv_id=ps_app.cons_inv_id
						   AND   c.status <> 'REJECTED'
						   AND ctrx.cons_inv_id=c.cons_inv_id
						   AND ctrx.customer_trx_id is null
						   AND ctrx.adj_ps_id=ps_app.payment_schedule_id )
							AND    1=2  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;
				 --bug 12349325
			UNION
			SELECT
				  l_consinv_id,
				  'RECEIPT ADJUST',
				  ps_cash.trx_number,
				  RA.apply_date,
				  nvl (ra.amount_applied_from, RA.amount_applied),
				  NULL,
				  RA.receivable_application_id,
				  NULL,
				  ps_cash.org_id
			FROM
				  ar_receivable_applications RA,
				  ar_payment_schedules ps_cash
			WHERE
				   RA.cons_inv_id IS NULL
			AND    RA.applied_payment_schedule_id  = -3
			AND    RA.application_type           = 'CASH'
			AND    RA.apply_date                <= l_billing_date
			AND    ps_cash.payment_schedule_id   = RA.payment_schedule_id
			AND    ps_cash.customer_site_use_id  = L_sites.site_id
			AND    ps_cash.invoice_currency_code = P_currency
			AND    nvl(ps_cash.exclude_from_cons_bill_flag, 'N') <> 'Y'
			AND     EXISTS 
				 (SELECT /*+ push_subq no_unnest leading(CTRX) use_nl(CTRX C) */ '*'
				  FROM   ar_cons_inv c,
					 ar_cons_inv_trx ctrx
				  WHERE  ps_cash.payment_schedule_id = ctrx.adj_ps_id
				  AND    c.cons_inv_id = ctrx.cons_inv_id
							  AND    ctrx.transaction_type = 'RECEIPT'
						  AND    c.status <> 'REJECTED')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;
					
			/* Bug 8832473 code changes end  */  


			/** For Site: calculate totals **/
			SELECT nvl(sum(amount_original),0)
			INTO   l_period_trx
			FROM   ar_cons_inv_trx
			WHERE  cons_inv_id = l_consinv_id
			AND    transaction_type IN ('INVOICE', 'DEBIT_MEMO', 'DEPOSIT', 'CHARGEBACK');

			SELECT nvl(sum(amount_original),0)
			INTO   l_period_receipts
			FROM   ar_cons_inv_trx
			WHERE  cons_inv_id      = l_consinv_id
			AND    transaction_type IN ('RECEIPT','RECEIPT REV','XSITE RECREV',
										'XSITE RECAPP',
										'XCURR RECAPP', 'XCURR RECREV', 
							'XSITE XCURR RECAPP','XSITE XCURR RECREV',
						'EXCLUDE RECREV', 'EXCLUDE RECAPP','RECEIPT ADJUST'); 

			SELECT nvl(sum(amount_original),0)
			INTO   l_period_finchrg
			FROM   ar_cons_inv_trx
			WHERE  cons_inv_id = l_consinv_id
			AND    transaction_type IN ('FINANCE CHARGE');
	 
			SELECT nvl(sum(amount_original),0)
			INTO   l_period_adj
			FROM   ar_cons_inv_trx
			WHERE  cons_inv_id = l_consinv_id
			AND    transaction_type = 'ADJUSTMENT';

			SELECT nvl(sum(amount_original),0)
			INTO   l_period_credits
			FROM   ar_cons_inv_trx
			WHERE  cons_inv_id = l_consinv_id
			AND    transaction_type IN ('CREDIT_MEMO',
										'XSITE_CMREV','XSITE_CMAPP',
										'EXCLUDE_CMREV', 'EXCLUDE_CMAPP',
										'DELAY_CMAPP');
	 
			SELECT nvl(sum(tax_amount),0)
			INTO   l_period_tax
			FROM   ar_cons_inv_trx_lines
			WHERE  cons_inv_id = l_consinv_id;

			
			UPDATE ar_cons_inv
			SET    total_receipts_amt = l_period_receipts,
				   total_adjustments_amt = l_period_adj,
				   total_credits_amt = l_period_credits,
				   total_finance_charges_amt = l_period_finchrg, 
				   total_trx_amt = l_period_trx,
				   total_tax_amt = l_period_tax,
				   ending_balance = beginning_balance + l_period_trx + l_period_receipts +
									l_period_adj + l_period_credits + l_period_finchrg 
			WHERE  cons_inv_id    = l_consinv_id;

			/** For Site: update ar_payment_schedules, ar_receivable_applications 
				and ar_adjustments **/

			write_debug_and_log('Updating AR_PAYMENT_SCHEDULES');

			UPDATE  ar_payment_schedules PS
			SET     PS.cons_inv_id = l_consinv_id
			WHERE   PS.payment_schedule_id IN
					   (SELECT IT.adj_ps_id
						FROM   ar_cons_inv_trx IT
						WHERE  IT.cons_inv_id      = l_consinv_id
						AND    IT.transaction_type IN ('INVOICE','CREDIT_MEMO', 'DEBIT_MEMO', 'DEPOSIT', 'CHARGEBACK', 
													   'RECEIPT'));
	 
			UPDATE  ar_payment_schedules PS
			SET     PS.cons_inv_id_rev = l_consinv_id
			WHERE   PS.payment_schedule_id IN
					   (SELECT IT.adj_ps_id 
						FROM   ar_cons_inv_trx IT
						WHERE  IT.cons_inv_id      = l_consinv_id
						AND    IT.transaction_type = 'RECEIPT REV')
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;;
	 
			write_debug_and_log('Updating AR_RECEIVABLE_APPLICATIONS');
	 
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
							   'EXCLUDE_CMREV',
				   'RECEIPT ADJUST'));    -- Bug 8946152
	 
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
							   'EXCLUDE_CMAPP',
							  'DELAY_CMAPP')) --Bug 13406831
			AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;
	 
			write_debug_and_log('Updating AR_ADJUSTMENTS');
	 
			UPDATE  ar_adjustments  RA
			SET     RA.cons_inv_id = l_consinv_id
			WHERE   RA.adjustment_id IN
					   (SELECT /*+ index (IT AR_CONS_INV_TRX_N1)  */
							   IT.adj_ps_id
						FROM   ar_cons_inv_trx IT
						WHERE  IT.cons_inv_id      = l_consinv_id
						AND    IT.transaction_type = 'ADJUSTMENT')
			 AND    1=2;  -- Added by AG on 10/24/2013 as for 11i Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM;
	 
			write_debug_and_log('Updating AR_CONS_INV');

		-- bug2778646 Changed status of selected merged cbi. 
		   --            DRAFT_MERGE/MERGED status CBI is not selected by other CBI.
		   UPDATE ar_cons_inv ci
		   SET status = DECODE(P_print_option, 'DRAFT', 'DRAFT_MERGE','MERGED')
		   WHERE status = 'MERGE_PENDING'
		   AND site_use_id   = L_sites.site_id
		   AND currency_code = P_currency
		   AND nvl(billing_date,cut_off_date) <= l_billing_date ;

			-- 6955957
			-- update ra_customer_trx_all with the printing dates for all the transactions included.
			UPDATE ra_customer_trx trx 
			SET printing_original_date = nvl(printing_original_date, SYSDATE), 
				printing_last_printed = nvl(printing_last_printed, SYSDATE)
			WHERE trx.trx_number IN 
				  (SELECT trx_number 
				   FROM ar_cons_inv_trx IT 
				   WHERE IT.cons_inv_id = l_consinv_id );

		  --Get the Aging information and update the 
		  -- aging buckets on the Bill  
		  -- 
			  ar_cmgt_aging.calc_aging_buckets(
				  l_party_id,
				  L_sites.customer_id,
				  L_sites.site_id,
				  P_currency,
				  NULL,
				  l_bucket_name,
				  arp_standard.sysparm.org_id,
				  NULL,
				  'CONS_BILL',
				  l_outstanding_balance,
				  l_bucket_titletop_0,
				  l_bucket_titlebottom_0,
				  l_bucket_amount_0,
				  l_bucket_titletop_1,
				  l_bucket_titlebottom_1,
				  l_bucket_amount_1,
				  l_bucket_titletop_2,
				  l_bucket_titlebottom_2,
				  l_bucket_amount_2,
				  l_bucket_titletop_3,
				  l_bucket_titlebottom_3,
				  l_bucket_amount_3,
				  l_bucket_titletop_4,
				  l_bucket_titlebottom_4,
				  l_bucket_amount_4,
				  l_bucket_titletop_5,
				  l_bucket_titlebottom_5,
				  l_bucket_amount_5,
				  l_bucket_titletop_6,
				  l_bucket_titlebottom_6,
				  l_bucket_amount_6);

			  UPDATE ar_cons_inv
		  SET aging_bucket1_amt = l_bucket_amount_0,
				  aging_bucket2_amt = l_bucket_amount_1,
				  aging_bucket3_amt = l_bucket_amount_2,
				  aging_bucket4_amt = l_bucket_amount_3,
				  aging_bucket5_amt = l_bucket_amount_4,
				  aging_bucket6_amt = l_bucket_amount_5,
				  aging_bucket7_amt = l_bucket_amount_6
			  WHERE cons_inv_id = l_consinv_id;
							END LOOP;			--*/ L_inv_parent*/
		END IF;		-- Bill Complete Loop

        END IF; /* Bug 8242289 Bypass the site if new billing date = last billing date */

     END LOOP;  /* c_site */

     END IF; /* l_billing_date <= sysdate */
   END LOOP; /* c_terms */

-- commmented out the following code for bug 6488683
-- This is moved to the process_override procedure and the update is done for 
-- individual transactions instead of doing it as a bulk here.
-- This is in order to get the new payment schedule id while inserting 
-- into ar_cons_inv_trx.
/*
       -- Following is the update for all data overridden in TRX table
       IF l_tab_idx > 0 THEN
          write_debug_and_log('Override : Updating RA_CUSTOMER_TRX');
          FORALL i IN 1..l_tab_idx
          UPDATE RA_CUSTOMER_TRX
             SET term_id = l_tab_term_id(i),
                 billing_date = l_tab_billing_date(i),
                 term_due_date = l_tab_due_date(i)
             WHERE customer_trx_id = l_tab_trx_id(i);

          write_debug_and_log('Override : Updating AR_PAYMENT_SCHEDULES');
          FOR i IN 1..l_tab_idx LOOP
              arp_process_header.post_commit( 'ARPBFBIB',
                                           120.0,
                                           l_tab_trx_id(i), -- customer_trx_id 
                                           NULL, -- cm trx_id
                                           'Y',  -- complete_flag
                                           NULL, -- INV open_rec flag
                                           NULL, -- CM open_rec_flag 
                                           NULL, -- creation_sign,
                                           NULL, -- allow_overapp_flag,
                                           NULL, -- natural_app_only_flag,
                                           NULL  -- cash_receipt_id
                                         );
          END LOOP;

          FORALL i IN 1..l_tab_idx
          UPDATE AR_PAYMENT_SCHEDULES
             SET due_date = l_tab_due_date(i)
             WHERE customer_trx_id = l_tab_trx_id(i);

       END IF;
       
*/

   END IF;

   commit;

EXCEPTION
WHEN OTHERS THEN
   write_debug_and_log('EXCEPTION: generate:' );
   write_debug_and_log('P_print_option     : ' || P_print_option);
   write_debug_and_log('P_print_output     : ' || P_print_output);
   write_debug_and_log('P_billing_cycle_id : ' || to_char(P_billing_cycle_id));
   write_debug_and_log('P_billing_date     : ' || to_char(P_billing_date));
   write_debug_and_log('P_currency         : ' || P_currency);
   write_debug_and_log('P_cust_num_low     : ' || to_char(P_cust_num_low));
   write_debug_and_log('P_cust_num_high    : ' || to_char(P_cust_num_high));
   write_debug_and_log('P_bill_site_low    : ' || to_char(P_bill_site_low));
   write_debug_and_log('P_bill_site_high   : ' || to_char(P_bill_site_high));
   write_debug_and_log('P_term_id          : ' || to_char(P_term_id));
   write_debug_and_log('P_print_status     : ' || P_print_status);
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
                 AND    IT.transaction_type IN ('INVOICE','CREDIT_MEMO',
                                'DEBIT_MEMO', 'DEPOSIT', 'CHARGEBACK')
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

     /* 4188835 - If printing for first time, freeze trans for tax */
     IF P_print_option = 'PRINT'
     THEN
       FOR trx in c_pending_trx LOOP
          arp_etax_util.global_document_update(trx.customer_trx_id,
                                               null,
                                               'PRINT');
       END LOOP;
     END IF;

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
       write_debug_and_log( ' Exception: update_status: ');
       RAISE;
   END;


PROCEDURE Report( P_report IN ReportParametersType) Is

BEGIN

   write_debug_and_log('arp_bf_bill.Report3(+)');

   IF P_report.print_option in ('DRAFT','FINAL') THEN

      generate(P_Report.print_option,
               P_Report.print_output,
               P_Report.billing_cycle_id,
               P_Report.billing_date,
               P_Report.currency,
               P_Report.cust_name_low,
               P_Report.cust_name_high,
               P_Report.cust_num_low,
               P_Report.cust_num_high,
               P_Report.bill_site_low,
               P_Report.bill_site_high,
               P_Report.term_id,
               NULL, /*Bug 5203710 */
               P_report.print_status,
               --Bug 12739341, add a flag to check whether it can generate future date bill
               p_report.future_date_bill_flag,
               p_report.org_id  -- Added for R12
			   );

   ELSIF P_report.print_option = 'REPRINT' THEN

      IF P_report.print_status = 'PENDING' THEN
         reprint(P_report.consinv_id_low,
                 P_report.request_id);
      ELSE
         update_status(P_report.print_option,
                       P_report.consinv_id_low,
                       P_report.request_id);
      END IF;

   ELSIF P_report.print_option = 'ACCEPT'  THEN
      accept( P_report.cust_num_low,
              P_report.cust_num_high,
              P_report.bill_site_low,
              P_report.bill_site_high,
              P_report.bill_date_low,
              P_report.bill_date_high,
              P_report.consinv_id_low,
              P_report.consinv_id_high,
              P_report.request_id);


   ELSIF P_report.print_option = 'REJECT' THEN

      reject( P_report.cust_num_low,
              P_report.cust_num_high,
              P_report.bill_site_low,
              P_report.bill_site_high,
              P_report.bill_date_low,
              P_report.bill_date_high,
              P_report.consinv_id_low,
              P_report.consinv_id_high,
              P_report.request_id);

   END IF;

   write_debug_and_log('arp_bf_bill.Report3(-)');
   
EXCEPTION
WHEN OTHERS THEN
   write_debug_and_log( 'Exception: arp_bf_bill.Report3 :'||sqlerrm );
   RAISE_APPLICATION_ERROR( -20000, sqlerrm);
END;

-- overloaded procedure called for Accept / Reject
/* Bug 5137184 Billing Date param should be varchar */

PROCEDURE Report( Errbuf     OUT NOCOPY VARCHAR2,
                  Retcode    OUT NOCOPY NUMBER,
                  P_print_option     IN VARCHAR2,
                  P_org_id           IN NUMBER,
                  P_cust_num_low     IN VARCHAR2,
                  P_cust_num_high    IN VARCHAR2,
                  P_bill_site_low    IN NUMBER,
                  P_bill_site_high   IN NUMBER,
                  P_bill_date_low    IN VARCHAR2,
                  P_bill_date_high   IN VARCHAR2,
                  P_consinv_id_low   IN NUMBER,
                  P_consinv_id_high  IN NUMBER,
                  P_request_id       IN NUMBER) IS


l_report ReportParametersType;
CURSOR org_rec is 
select org_id
from ar_system_parameters
where org_id = nvl(p_org_id,org_id);
BEGIN

  write_debug_and_log('arp_bf_bill.Report2 (+)');

  mo_global.init('AR');

   l_report.print_option     := P_print_option;
   l_report.print_output     := NULL;
   l_report.billing_cycle_id := NULL;
   l_report.billing_date     := NULL;
   l_report.currency         := NULL;
   l_report.cust_name_low    := NULL;
   l_report.cust_name_high   := NULL;
   l_report.cust_num_low     := P_cust_num_low;
   l_report.cust_num_high    := P_cust_num_high;
   l_report.bill_site_low    := P_bill_site_low;
   l_report.bill_site_high   := P_bill_site_high;

   /* Bug 5137184 --Program ends when Billing Date is passed */
   l_report.bill_date_low    := fnd_date.canonical_to_date(P_bill_date_low);
   l_report.bill_date_high   := fnd_date.canonical_to_date(P_bill_date_high);


   l_report.term_id          := NULL;
   l_report.detail_option    := NULL;
   l_report.consinv_id_low   := P_consinv_id_low;
   l_report.consinv_id_high  := P_consinv_id_high;
   l_report.request_id       := P_request_id;
   l_report.print_status     := NULL;

 IF P_org_id is not null THEN
  write_debug_and_log('ORG ID : '||p_org_id);
  mo_global.set_policy_context('S',p_org_id);
  arp_standard.init_standard(p_org_id); 
  Report(l_report);

ELSE

 FOR k in org_rec LOOP
   write_debug_and_log('ORG ID : '||k.org_id);

   mo_global.set_policy_context('S',k.org_id); 
    arp_standard.init_standard(p_org_id);
   Report(l_report);

 END LOOP;

END IF;
   write_debug_and_log('arp_bf_bill.Report2 (-)');

EXCEPTION
WHEN OTHERS THEN
   write_debug_and_log( 'Exception:arp_bf_bill.Report2:'||sqlerrm);
   RAISE_APPLICATION_ERROR( -20000, sqlerrm);
END;



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
 | RETURNS        : NONE                                                      |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | MODIFICATION HISTORY                                                       |
 | May-23-2006 Jyoti Pandey  Bug 5137184 Billing Date param should be varchar |
 |                                                                            |
 *----------------------------------------------------------------------------*/
PROCEDURE Report( Errbuf     OUT NOCOPY VARCHAR2,
                  Retcode    OUT NOCOPY NUMBER,
                  P_print_option     IN VARCHAR2,
                  P_org_id           IN NUMBER,
                  P_print_output     IN VARCHAR2,
                  P_billing_cycle_id IN NUMBER,
                  --Bug 12739341, add a flag to check whether it can generate future date bill
                  p_future_date_bill_flag IN VARCHAR2,
                  P_billing_date     IN VARCHAR2,
                  P_currency         IN VARCHAR2,
                  P_cust_name_low    IN VARCHAR2,
                  P_cust_name_high   IN VARCHAR2,
                  P_cust_num_low     IN VARCHAR2,
                  P_cust_num_high    IN VARCHAR2,
                  P_bill_site_low    IN NUMBER,
                  P_bill_site_high   IN NUMBER,
                  P_term_id          IN NUMBER,
                  P_detail_option    IN VARCHAR2,
                  P_consinv_id       IN NUMBER DEFAULT 0,
                  P_request_id       IN NUMBER DEFAULT 0) IS

l_report ReportParametersType;
l_use_currency VARCHAR2(15);
l_request_id  NUMBER;
CURSOR org_rec is 
select org_id
from ar_system_parameters
where org_id = nvl(p_org_id,org_id);
BEGIN
  
   mo_global.init('AR'); 
   write_debug_and_log('arp_bf_bill.Report1 (+)');
   
   write_debug_and_log('New changes ');
   

IF P_org_id is not null THEN

  write_debug_and_log('ORG ID : '||p_org_id);
  mo_global.set_policy_context('S',p_org_id);
  arp_standard.init_standard(p_org_id);
 
   if P_Print_option in ( 'PRINT', 'DRAFT') THEN
      l_report.print_option := 'DRAFT';
   else
      l_report.print_option     := P_print_option;
   end if;

   IF p_currency is NULL THEN
      -- default to functional currency
      SELECT  sob.currency_code
      INTO    l_use_currency
      FROM    gl_sets_of_books sob
      WHERE   sob.set_of_books_id = arp_standard.sysparm.set_of_books_id;
   ELSE
      l_use_currency := P_currency;
   END IF;

   l_report.print_output     := P_print_output;
   l_report.billing_cycle_id := P_billing_cycle_id;

   /* Bug 5137184 --Program ends when Billing Date is passed */
   l_report.billing_date     := fnd_date.canonical_to_date(P_billing_date);
   --Bug 12739341, add a flag to check whether it can generate future date bill
   l_report.future_date_bill_flag := p_future_date_bill_flag;
   l_report.currency         := l_use_currency;
   l_report.cust_name_low    := P_cust_name_low;
   l_report.cust_name_high   := P_cust_name_high;
   l_report.cust_num_low     := P_cust_num_low;
   l_report.cust_num_high    := P_cust_num_high;
   l_report.bill_site_low    := P_bill_site_low;
   l_report.bill_site_high   := P_bill_site_high;
   l_report.term_id          := P_term_id;
   l_report.detail_option    := P_detail_option;
   l_report.consinv_id_low   := P_consinv_id;
   l_report.request_id       := P_request_id;
   l_report.org_id           := p_org_id; -- Added for R12 
  
   IF P_print_option = 'FINAL' THEN
      l_report.print_status     := 'FINAL';
   ELSE
      l_report.print_status     := 'PENDING';
   END IF;

   Report(l_report);

ELSE

 FOR k in org_rec LOOP
  
   mo_global.set_policy_context('S',k.org_id); 
   arp_standard.init_standard(p_org_id);
   
   l_report.org_id := p_org_id;

   if P_Print_option in ( 'PRINT', 'DRAFT') THEN
      l_report.print_option := 'DRAFT';
   else
      l_report.print_option     := P_print_option;
   end if;

   IF p_currency is NULL THEN
      -- default to functional currency
      SELECT  sob.currency_code
      INTO    l_use_currency
      FROM    gl_sets_of_books sob
      WHERE   sob.set_of_books_id = arp_standard.sysparm.set_of_books_id;
   ELSE
      l_use_currency := P_currency;
   END IF;

   l_report.print_output     := P_print_output;
   l_report.billing_cycle_id := P_billing_cycle_id;

   /* Bug 5137184 --Program ends when Billing Date is passed */
   l_report.billing_date     := fnd_date.canonical_to_date(P_billing_date);
   --Bug 12868601, add a flag to check whether it can generate future date bill when the operating unit is null
   l_report.future_date_bill_flag := p_future_date_bill_flag;
   l_report.currency         := l_use_currency;
   l_report.cust_name_low    := P_cust_name_low;
   l_report.cust_name_high   := P_cust_name_high; 
   l_report.cust_num_low     := P_cust_num_low;
   l_report.cust_num_high    := P_cust_num_high;
   l_report.bill_site_low    := P_bill_site_low;
   l_report.bill_site_high   := P_bill_site_high;
   l_report.term_id          := P_term_id;
   l_report.detail_option    := P_detail_option;
   l_report.consinv_id_low   := P_consinv_id;
   l_report.request_id       := P_request_id;
   l_report.org_id           := p_org_id;
   
   IF P_print_option = 'FINAL' THEN
      l_report.print_status     := 'FINAL';
   ELSE
      l_report.print_status     := 'PENDING';
   END IF;

   Report(l_report);

  END  LOOP;

 END IF;

 /** LAUNCH THE BPA PRINT PROGRAM  **/

   write_debug_and_log('p_print_option : '||p_print_option);

     IF p_print_option in ('DRAFT','PRINT','FINAL') AND 
        p_print_output = 'Y' THEN

      write_debug_and_log('Submitting call to ARBPBFMP');


      l_request_id := FND_REQUEST.SUBMIT_REQUEST(
                         'AR',
                         'ARBPBFMP',
                         null,
                         null,
                         FALSE,
                         to_char(null),                    -- Operating Unit
                         to_char(null),                    -- Job Size
                         to_char(null),                    -- Customer Number Low
                         to_char(null),                    -- Customer Number High
                         to_char(null),                    -- Location Low
                         to_char(null),                    -- Location High
                         to_char(null),                    -- Bill Date Low
                         to_char(null),                    -- Bill Date High
                         to_char(null),                    -- Bill Number Low
                         to_char(null),                    -- Bill Number High
                         arp_standard.profile.request_id,  -- Conc Request ID
                         to_char(null));

      write_debug_and_log('... request ID is ' || to_char(l_request_id));

   END IF;

   write_debug_and_log('arp_bf_bill.Report1 (-)');




EXCEPTION
WHEN OTHERS THEN
   write_debug_and_log( 'Exception:arp_bf_bill.Report1:'||sqlerrm);
   RAISE_APPLICATION_ERROR( -20000, sqlerrm); 
END;

END xx_arp_bf_bill;
/


--commit;
--exit;

