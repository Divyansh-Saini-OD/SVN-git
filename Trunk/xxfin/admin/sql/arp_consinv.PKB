SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE SPEC ARP_CONSINV

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
/*============================================================================+
 |  $Header: ARPCBIB.pls 115.8 99/09/30 13:24:16 porting ship  $
 +============================================================================+
 |  Copyright (c) 1996 Oracle Corporation Belmont, California, USA            |
 |                          All Rights Reserved                               |
 +============================================================================+
 |                                                                            |
 | FILENAME                                                                   |
 |                                                                            |
 |    ARPCBIB.pls                                                             |
 |                                                                            |
 | PACKAGE arp_consinv                                                        |
 |                                                                            |
 | DESCRIPTION                                                                |
 |     Contains the package arpcbi, which will generate Consolidated Billing  |
 |     Invoices.  Called By report ARXCBI.                                    |
 |                                                                            |
 | PUBLIC PROCEDURES                                                          |
 |     Report() - based on option chosen by user, will call one of the private|
 |                procedures listed below.                                    |
 |                                                                            |
 | PUBLIC FUNCTIONS                                                           |
 |                                                                            |
 | PUBLIC VARIABLES                                                           |
 |                                                                            |
 | PRIVATE VARIABLES                                                          |
 |                                                                            |
 | PRIVATE PROCEDURES                                                         |
 |    reprint()                                                               |
 |    accept()                                                                |
 |    reject()                                                                |
 |    generate()                                                              |
 |    update_status()                                                         |
 |                                                                            |
 | PRIVATE FUNCTIONS                                                          |
 |                                                                            |
 | EXTERNAL PROCEDURES ACCESSED                                               |
 |                                                                            |
 | KNOWN BUGS                                                                 |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | MODIFICATION HISTORY                                                       |
 |      05-AUG-97    Jack Martinez       Bug 499781 - updated routine generate|
 |                                       so that insert to ar_cons_inv_trx    |
 |                                       for type 'XSITE RECAPP' does not     |
 |                                       negate the amount.                   |
 |      06-AUG-97    Jack Martinez       bug 522890 - updated routine generate|
 |                                       to ignore guarantees when collecting |
 |                                       adjustments.  When an invoice is     |
 |                                       applied against a guarantee, a row   |
 |                                       is created in ar_adjustments and is  |
 |                                       applied against the payment schedule |
 |                                       of the guarantee. So when gathering  |
 |                                       adjustments, ignore if the class of  |
 |                                       the payment schedule is 'GUAR'.      |
 |      22-Aug-97    Jack Martinez       bug 531330 - patch 499781 was not    |
 |                                       correct.  Amount for 'XSITE RECAPP'  |
 |                                       must be negated, while 'XSITE RECREV'|
 |                                       is not negated                       |
 |      27-AUG-97    Jack Martinez       bug 536361 - when creating rows for  |
 |                                       credit memos do not negated amounts. |
 |      28-AUG-97    C M Clyde           Added the cross currency features.   |
 | 	16-DEC-97    Tasman Tang	 Bug 586251 - quantity in credit memo |
 |					 should be displayed	 	      |
 |      09-JAN-98    C M Clyde           Changed selection of Unit_Selling_   |
 |                                       Price to Gross_Unit_Selling_Price    |
 |                                       and Extended_Amount to Gross_        |
 |                                       Extended_Amount (in various places). |
 |      25-FEB-98    Jack Martinez       bug 632412 - do not use terms code   |
 |                                       id when getting ending balance from  |
 |                                       prior consolidated billing invoice.  |
 |      25-MAR-98    Jack Martinez       bug 635366 - if the invoice date is  |
 |                                       on the cut-off day, AR assigns a due |
 |                                       date for the invoice that corresponds|
 |                                       to the next billing period. To make  |
 |                                       consolidated billing consistent with |
 |                                       this, transactions are only included |
 |                                       in the current consolidated billing  |
 |                                       invoice if the transaction date is   |
 |                                       BEFORE the cut-off date.             |
 |      01-JUN-99  Frank Breslin         889478: Replaced the check to the    |
 |                                       term_id in the C_SITES cursor        |
 |                                       against the terms parameter because  |
 |                                       we were losing the ability to only   |
 |                                       select customer sites with the given |
 |                                       term.                                |
 |     08-JUL-99 Frank Breslin           857820: Implement the use of Last Day|
 |                                       of Month type terms.                 |
 |     23-JUL-99 Frank Breslin           940744: Terms check in C_SITES was   |
 |                                       causing a problem when there was no  |
 |                                       term defined  at the Bill To Site    |
 |                                       level.                               |
 |     25-AUG-99 Frank Breslin           919100: Modifed the cursor C_SITES in|
 |                                       generate to specifically exclude     |
 |                                       Bill To sites with a terms code that |
 |                                       does not have a day of month / months|
 |                                       ahead type due day.                  |
 |     27-SEP-99 Frank Breslin           1006767: Changed references to       |
 |                                       PS.class to PS.class||'' in the WHERE|
 |                                       clause of queries in Generate in     |
 |                                       in order to supress the use of index |
 |                                       AR_PAYMENT_SCHEDULES_N11 for the     |
 |                                       purpose of improving performance.    |
 +============================================================================*/

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY arp_consinv AS
/* $Header: ARPCBIB.pls 115.8 99/09/30 13:24:16 porting ship  $ */

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

   BEGIN
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
 |									      |
 | C M Clyde        28 Aug 97     Modified to include transaction types of    |
 |                                'XSITE XCURR RECAPP', 'XSITE XCURR RECREV', |
 |                                'XCURR RECAPP', 'XCURR RECREV'.             |
 |                                                                            |
 *----------------------------------------------------------------------------*/
   PROCEDURE reject (P_consinv_id  IN NUMBER, P_request_id IN NUMBER) IS

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
               WHERE  IT.transaction_type IN ('INVOICE','CREDIT MEMO')
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
               WHERE  IT.transaction_type IN ('INVOICE','CREDIT MEMO',
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


     UPDATE ar_receivable_applications
     SET    cons_inv_id = NULL
     WHERE  receivable_application_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type IN ('XSITE RECREV', 'XSITE CMREV',
					      'XCURR RECREV', 'XSITE XCURR RECREV')
               AND    CI.cons_inv_id      = IT.cons_inv_id
               AND    CI.cons_inv_id      = nvl(P_consinv_id, CI.cons_inv_id)
               AND    CI.concurrent_request_id = DECODE(P_consinv_id,
                                                   NULL, P_request_id,
                                                   CI.concurrent_request_id)
               AND    CI.status           = 'DRAFT');

     UPDATE ar_receivable_applications
     SET    cons_inv_id_to = NULL
     WHERE  receivable_application_id IN
              (SELECT IT.adj_ps_id
               FROM   ar_cons_inv CI,
                      ar_cons_inv_trx IT
               WHERE  IT.transaction_type IN ('XSITE RECAPP','XSITE CMAPP',
					      'XCURR RECAPP', 'XSITE XCURR RECAPP')
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
 |				       of 'XSITE XCURR RECAPP',               |
 |                                     'XSITE XCURR RECREV', 'XCURR RECAPP',  |
 |				       'XCURR RECREV'.                        |
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
 *----------------------------------------------------------------------------*/
   PROCEDURE generate (P_print_option    IN VARCHAR2,
                       P_detail_option   IN VARCHAR2,
                       P_currency        IN VARCHAR2,
                       P_customer_id     IN NUMBER,
                       P_customer_number IN VARCHAR2,
                       P_bill_to_site    IN NUMBER,
                       P_cutoff_date     IN DATE,
		       P_last_day_of_month IN VARCHAR2,
                       P_term_id         IN NUMBER) IS
     l_cutoff_day  NUMBER(15);
     l_beginning_balance NUMBER;
     l_consinv_id  NUMBER;
     l_consinv_lineno NUMBER(15);
     l_cons_billno VARCHAR2(30);
     l_new_billed NUMBER;
     l_period_receipts NUMBER;
     l_due_date DATE;
     l_due_last_day_of_month DATE;

     CURSOR C_sites (C_detail_option VARCHAR, C_customer_id NUMBER,
                     C_site_use_id   NUMBER,  C_cutoff_date DATE,
                     C_cutoff_day    NUMBER,  C_term_id NUMBER) IS
     SELECT 
            CP.customer_id,
            SU.site_use_id                          	site_id,
            nvl(SU.payment_term_id, 
		nvl(SP.standard_terms, 
                    nvl(CP.standard_terms,T.term_id)))  term_id,
            RA.address_id,
            nvl(SP.cons_inv_type,
                nvl(CP.cons_inv_type,'SUMMARY'))    	cons_inv_type,
            TL1.due_day_of_month                    	day_due,
            TL1.due_months_forward                  	months_forward
     FROM
            ra_customers         RC,
            ar_customer_profiles CP,
            ar_customer_profiles SP,
            ra_site_uses         SU,
            ra_addresses         RA,
            ra_terms             T,
            ra_terms_lines       TL1
     WHERE
     	    SU.site_use_code    = 'BILL_TO'
/*
889478: use the payment term parameter, if populated, to limit the sites that
        will have consolidated bills created.
*/
/*
940744: Correct the use of the term_id parameter
*/
     AND    ((C_term_id             IS NULL) 
           OR
             ((C_term_id            IS NOT NULL) AND
              (C_term_id            =  NVL(SU.payment_term_id,
                                           NVL(SP.standard_terms,
                                               CP.standard_terms)))))
     AND    SU.site_use_id         = nvl(C_site_use_id, SU.site_use_id)
     AND    SP.site_use_id(+)      = SU.site_use_id
     AND    T.term_id		   = nvl(C_term_id, T.term_id)
     AND    T.term_id              = nvl(SU.payment_term_id,
				         nvl(SP.standard_terms,
		                             CP.standard_terms))
     AND    T.due_cutoff_day       = C_cutoff_day
     AND    TL1.term_id            = T.term_id
/*
919100: Be sure that only that only Customer Bill To's with terms with a Due 
        Date / Months Forward type of due dates are selected as candidates.
*/
     AND    TL1.due_day_of_month   IS NOT NULL
     AND    TL1.due_months_forward IS NOT NULL
     AND    1                      = (SELECT count(*)
                                        FROM ra_terms_lines TL2
                                       WHERE TL2.term_id = TL1.term_id)
     AND    RA.address_id          = SU.address_id
     AND    RC.customer_id         = RA.customer_id
     AND    RC.customer_number     = nvl(P_customer_number,RC.customer_number)
     AND    CP.customer_id         = RA.customer_id
     AND    CP.site_use_id 	   IS NULL
     AND    CP.customer_id         = nvl(P_customer_id, CP.customer_id)
     AND    nvl(SP.cons_inv_flag, 
                CP.cons_inv_flag)  = 'Y'
     AND    nvl(SP.cons_inv_type, 
                nvl(CP.cons_inv_type,
                    'SUMMARY'))    = C_detail_option
     AND    NOT EXISTS
               (SELECT NULL
                FROM ar_cons_inv CI
                WHERE CI.site_use_id = SU.site_use_id
                AND CI.cut_off_date  = to_date(C_cutoff_date)
                AND CI.currency_code = P_currency
                AND CI.status <> 'REJECTED');

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
     AND    CT.trx_date              < to_date(C_cutoff_date)
     AND    PS.class||'' IN ('INV', 'DM', 'CM', 'DEP', 'CB')
     ORDER BY PS.trx_date, PS.customer_trx_id;

   BEGIN

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
     l_cutoff_day := to_date(P_cutoff_date) -
                             trunc(to_date(P_cutoff_date),'MONTH') + 1;
/* 
857820: If P_last_day_of_month = 'Y' then use last day of month type terms
*/

     if P_last_day_of_month = 'Y' then
	l_cutoff_day := 32;
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

     FOR L_sites IN C_sites(P_detail_option, P_customer_id,
                            P_bill_to_site,  P_cutoff_date,
                            l_cutoff_day,    P_term_id) LOOP

/* Use for debugging ... 
dbms_output.put_line(' ');
dbms_output.put_line('Process a row from cursor C_SITES');
dbms_output.put_line('customer_id    : '||TO_CHAR(L_SITES.customer_id));
dbms_output.put_line('site_id        : '||TO_CHAR(L_SITES.site_id));
dbms_output.put_line('term_id        : '||TO_CHAR(L_SITES.term_id));
dbms_output.put_line('address_id     : '||TO_CHAR(L_SITES.address_id));
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

       l_due_date := to_date(add_months(to_date(trunc(P_cutoff_date,'month')),
                            nvl(L_sites.months_forward,0))+L_sites.day_due-1);

/** if the due day is 29 or greater, it is possible that the due month does
    not have that many days, so will need to use last day of month instead  **/

       l_due_last_day_of_month :=
                     to_date(add_months(to_date(trunc(P_cutoff_date,'month')),
                             nvl(L_sites.months_forward,0)+1)-1);

/* 
857820: Add P_last_day_of_month = 'Y when seeing if the last day of the month 
        should be the due date.
/*

       IF ((l_due_date > l_due_last_day_of_month) OR
           (P_last_day_of_month = 'Y')) THEN
            l_due_date := l_due_last_day_of_month;
       END IF;

/** get beginning balance for new billing invoice from prior billing invoice**/
/** bug 632412: do not use term_id in where clause and subquery in case the **/
/**             terms code was changed for the site.                        **/

       BEGIN
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
                                ending_balance)
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
                                nvl(L_sites.cons_inv_type,'SUMMARY'),
                                DECODE(P_print_option,
                                       'DRAFT', 'DRAFT',
                                       'ACCEPTED'),
                               'PENDING',
                                L_sites.term_id,
                                sysdate,
                                P_cutoff_date,
                                l_due_date,
                                P_currency,
                                nvl(l_beginning_balance,0),
                                0);
                    
/** For Site: process invoices, credit memos. Need loop to assign line no.  **/
/** 536361 - do not negate credit memo amounts.                             **/
       l_consinv_lineno := 1;

/* Use for debugging
dbms_output.put_line('Parameters to cursor C_INV_TRX...');
dbms_output.put_line('L_sites.site_id :'||TO_CHAR(L_sites.site_id));
dbms_output.put_line('P_cutoff_date   :'||TO_CHAR(P_cutoff_date));
*/
       FOR L_inv_trx IN C_inv_trx(L_sites.site_id, P_cutoff_date) LOOP
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
                                      cons_inv_line_number)
         VALUES                      (l_consinv_id,
                                      DECODE(L_inv_trx.class,
                                             'CM','CREDIT MEMO',
                                             'INVOICE'),
                                      L_inv_trx.trx_number,
                                      L_inv_trx.trx_date,
                                      L_inv_trx.amount_due,
                                      L_inv_trx.tax,
                                      L_inv_trx.schedule_id,
                                      l_consinv_lineno);

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
                                              tax_amount)
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
                  0
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
                                              tax_amount)
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
                  0
           FROM
                  ra_customer_trx_lines
           WHERE
                  customer_trx_id  = L_inv_trx.trx_id
           AND    line_type NOT IN ('TAX', 'FREIGHT');
         END IF;

/** now update lines with associated tax line **/
         UPDATE ar_cons_inv_trx_lines  TL
                set TL.tax_amount =
                    (SELECT sum(nvl(CTL.extended_amount,0))
                     FROM   ra_customer_trx_lines  CTL
                     WHERE  CTL.link_to_cust_trx_line_id =
                                TL.customer_trx_line_id
                     AND    CTL.line_type = 'TAX')
                WHERE
                     TL.customer_trx_id = L_inv_trx.trx_id;

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
                                            tax_amount)
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
               0
         FROM  
               ra_customer_trx_lines
         WHERE
               customer_trx_id = L_inv_trx.trx_id
         AND   line_type = 'FREIGHT'
         GROUP BY line_type;

         l_consinv_lineno := l_consinv_lineno + 1;

       END LOOP;

/** For site: adjustments                                                   **/
/** bug 522890 - ignore guarantees.  When an invoice is applied against a   **/
/**              guarantee, an adjustment row is created and is applied     **/
/**              against the payment schedule of the guarantee.  When       **/
/**              gathering adjustments, check the class of the related      **/
/**              payment schedule and omit if class = 'GUAR'.               **/
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
              'ADJUSTMENT',
              PS.trx_number,
              RA.gl_date,
              RA.amount,
              NULL,
              RA.adjustment_id,
              NULL
       FROM
              ar_adjustments RA,
              ar_payment_schedules PS
       WHERE
              RA.cons_inv_id is NULL
       AND    RA.gl_date              < to_date(P_cutoff_date)
       AND    RA.type in ('CHARGES','FREIGHT','INVOICE','LINE','TAX')
       AND    PS.payment_schedule_id   = RA.payment_schedule_id
       AND    PS.customer_site_use_id  = L_sites.site_id
       AND    PS.invoice_currency_code = P_currency
       AND    PS.class||''             <> 'GUAR'
              AND    1=2;  -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

/** For Site: cash receipts.                                                **/
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
              'RECEIPT',
              PS.trx_number,
              CR.receipt_date,
              PS.amount_due_original,
              NULL,
              PS.payment_schedule_id,
              NULL
       FROM
              ar_payment_schedules PS,
              ar_cash_receipts CR
       WHERE
              PS.customer_site_use_id  = L_sites.site_id
       AND    PS.cons_inv_id           IS NULL
       AND    PS.class||''             = 'PMT'
       AND    PS.invoice_currency_code = P_currency
       AND    CR.cash_receipt_id       = PS.cash_receipt_id
       AND    CR.receipt_date          < to_date(P_cutoff_date)
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM


/** For Site: cash receipts reversals.                                      **/
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
              'RECEIPT REV',
              PS.trx_number,
              CR.reversal_date,
              (-1)*PS.amount_due_original,
              NULL,
              PS.payment_schedule_id,
              NULL
       FROM
              ar_payment_schedules PS,
              ar_cash_receipts CR
       WHERE
              PS.customer_site_use_id  = L_sites.site_id
       AND    PS.cons_inv_id_rev       IS NULL
       AND    PS.invoice_currency_code = P_currency
       AND    PS.class||''             = 'PMT'
       AND    CR.cash_receipt_id       = PS.cash_receipt_id
       AND    CR.reversal_date         < to_date(P_cutoff_date)
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

 
/** For Site: need to reverse cash receipts if applied to a different       **/
/**    bill-to.                                                             **/
/** 531330 - changed '(-1)*RA.amount_applied' to 'RA.amount_applied         **/
/** Cross Currency functionality implemented.                               **/

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
	      DECODE (nvl (ps_cash.customer_site_use_id, -1), ps_inv.customer_site_use_id,
                      DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
		              'XXXXXXXXXX', 'XCURR RECREV'),
                      DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
                              'XSITE RECREV', 'XSITE XCURR RECREV')),
              ps_cash.trx_number,
              RA.apply_date,
              nvl (ra.amount_applied_from, RA.amount_applied),
              NULL,
              RA.receivable_application_id,
              NULL
       FROM
              ar_receivable_applications RA,
              ar_payment_schedules ps_cash,
              ar_payment_schedules ps_inv
       WHERE
              RA.cons_inv_id IS NULL
       AND    RA.status                     = 'APP' 
       AND    RA.application_type           = 'CASH'
       AND    RA.apply_date                < to_date(P_cutoff_date)
       AND    ps_cash.payment_schedule_id   = RA.payment_schedule_id
       AND    ps_cash.customer_site_use_id  = L_sites.site_id
       AND    ps_cash.invoice_currency_code = P_currency
       AND    ps_inv.payment_schedule_id    = RA.applied_payment_schedule_id
       AND   (   ps_cash.customer_site_use_id  <> ps_inv.customer_site_use_id
              OR ra.amount_applied_from IS NOT NULL)
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM


/** For Site: applied cash receipts where cash receipt bill-to is different **/

/** bug 499781 - changed '(-1)*RA.amount_applied' to 'RA.amount_applied'    **/
/** BUG 531330 - changed back to (-1)*RA.amount_applied                     **/
/** Cross Currency functionality has been added.			    **/

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
              DECODE (nvl (ps_cash.customer_site_use_id, -1), ps_inv.customer_site_use_id,
                      DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
                              'XXXXXXXXXX', 'XCURR RECAPP'),
                      DECODE (ps_cash.invoice_currency_code, ps_inv.invoice_currency_code,
                              'XSITE RECAPP', 'XSITE XCURR RECAPP')),
              ps_cash.trx_number,
              RA.apply_date,
              (-1)*RA.amount_applied,
              NULL,
              RA.receivable_application_id,
              NULL
       FROM
              ar_receivable_applications RA,
              ar_payment_schedules  ps_cash,
              ar_payment_schedules  ps_inv
       WHERE
              RA.cons_inv_id_to IS NULL
       AND    RA.status                    = 'APP'
       AND    RA.application_type          = 'CASH'
       AND    RA.apply_date               < to_date(P_cutoff_date)
       AND    ps_cash.payment_schedule_id  = RA.payment_schedule_id
       AND    ps_inv.payment_schedule_id   = RA.applied_payment_schedule_id
       AND    ps_inv.customer_site_use_id  = L_sites.site_id
       AND    ps_inv.invoice_currency_code = P_currency
       AND   (   nvl(ps_cash.customer_site_use_id,-1) <> ps_inv.customer_site_use_id
              OR ra.amount_applied_from IS NOT NULL)
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM


/** For Site: get on-account credit memo's applied to different bill-to.    **/
/**           Will need to add a reversal line because Credit Memo was used **/
/**           for a bill-to that is different from the current bill-to.     **/
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
              'XSITE CMREV',
              PS1.trx_number,
              RA.apply_date,
              RA.amount_applied,
              NULL,
              RA.receivable_application_id,
              NULL
       FROM  
              ar_receivable_applications RA,
              ar_payment_schedules PS1,
              ar_payment_schedules PS2,
              ra_customer_trx CT
       WHERE
              RA.cons_inv_id IS NULL
       AND    RA.status                 = 'APP'
       AND    RA.application_type       = 'CM'
       AND    RA.apply_date            < to_date(P_cutoff_date)
       AND    CT.customer_trx_id        = RA.customer_trx_id
       AND    PS1.payment_schedule_id   = RA.payment_schedule_id
       AND    PS1.customer_site_use_id  = L_sites.site_id
       AND    PS1.invoice_currency_code = P_currency
       AND    PS2.payment_schedule_id   = RA.applied_payment_schedule_id
       AND    PS2.customer_site_use_id <> PS1.customer_site_use_id
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM


/** For Site: get on-account credit memos assigned to different bill-to but **/
/**           applied against invoice for current bill-to.                  **/
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
              'XSITE CMAPP',
              PS1.trx_number,
              RA.apply_date,
              (-1)*RA.amount_applied,
              NULL,
              RA.receivable_application_id,
              NULL
       FROM
              ar_receivable_applications RA,
              ar_payment_schedules PS1,
              ar_payment_schedules PS2,
              ra_customer_trx CT
       WHERE
              RA.cons_inv_id_to IS NULL
       AND    RA.status                 = 'APP'
       AND    RA.application_type       = 'CM'
       AND    RA.apply_date            < to_date(P_cutoff_date)
       AND    CT.customer_trx_id        = RA.customer_trx_id
       AND    CT.previous_customer_trx_id IS NULL
       AND    PS1.payment_schedule_id   = RA.applied_payment_schedule_id
       AND    PS1.customer_site_use_id  = L_sites.site_id
       AND    PS1.invoice_currency_code = P_currency
       AND    PS2.payment_schedule_id   = RA.payment_schedule_id
       AND    PS2.customer_site_use_id <> PS1.customer_site_use_id
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM


/** For Site: update header for totals.                                     **/
       SELECT nvl(sum(amount_original),0)
       INTO   l_new_billed
       FROM   ar_cons_inv_trx
       WHERE  cons_inv_id = l_consinv_id
       AND    transaction_type IN ('INVOICE','CREDIT MEMO','ADJUSTMENT',
                                   'XSITE CMREV','XSITE CMAPP');

       SELECT nvl(sum(amount_original),0)
       INTO   l_period_receipts
       FROM   ar_cons_inv_trx
       WHERE  cons_inv_id      = l_consinv_id
       AND    transaction_type IN ('RECEIPT','RECEIPT REV','XSITE RECREV',
                                   'XSITE RECAPP');

       UPDATE ar_cons_inv
       SET    ending_balance =
                beginning_balance + l_new_billed + l_period_receipts
       WHERE  cons_inv_id    = l_consinv_id;

/** For Site: update ar_payment_schedules, ar_receivable_applications       **/
/**           and ar_adjustments                                            **/
/** Cross Currency functionality.					    **/

       UPDATE  ar_payment_schedules PS
       SET     PS.cons_inv_id = l_consinv_id
       WHERE   PS.payment_schedule_id IN
                  (SELECT IT.adj_ps_id
                   FROM   ar_cons_inv_trx IT
                   WHERE  IT.cons_inv_id      = l_consinv_id
                   AND    IT.transaction_type IN ('INVOICE','CREDIT MEMO',
                                                  'RECEIPT'));

       UPDATE  ar_payment_schedules PS
       SET     PS.cons_inv_id_rev = l_consinv_id
       WHERE   PS.payment_schedule_id IN
                  (SELECT IT.adj_ps_id 
                   FROM   ar_cons_inv_trx IT
                   WHERE  IT.cons_inv_id      = l_consinv_id
                   AND    IT.transaction_type = 'RECEIPT REV')
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM


       UPDATE  ar_receivable_applications  RA
       SET     RA.cons_inv_id = l_consinv_id
       WHERE   RA.receivable_application_id IN
                  (SELECT IT.adj_ps_id
                   FROM   ar_cons_inv_trx IT
                   WHERE  IT.cons_inv_id      = l_consinv_id
                   AND    IT.transaction_type IN ('XSITE RECREV',
                                                  'XSITE CMREV',
						  'XCURR RECREC',
						  'XSITE XCURR RECREC'))
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM


       UPDATE  ar_receivable_applications RA
       SET     RA.cons_inv_id_to = l_consinv_id
       WHERE   RA.receivable_application_id IN
                  (SELECT IT.adj_ps_id
                   FROM   ar_cons_inv_trx IT
                   WHERE  IT.cons_inv_id = l_consinv_id
                   AND    IT.transaction_type IN ('XSITE RECAPP',
                                                  'XSITE CMAPP',
						  'XCURR RECAPP',
						  'XSITE XCURR RECAPP'))
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM


       UPDATE  ar_adjustments  RA
       SET     RA.cons_inv_id = l_consinv_id
       WHERE   RA.adjustment_id IN
                  (SELECT IT.adj_ps_id
                   FROM   ar_cons_inv_trx IT
                   WHERE  IT.cons_inv_id      = l_consinv_id
                   AND    IT.transaction_type = 'ADJUSTMENT')
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM

 
/** set cons_inv_id to -1 for all rows where unapplied bill-to is same      **/
/** as bill-to of apply-to.                                                 **/
       UPDATE  ar_receivable_applications RA
       SET     RA.cons_inv_id = -1
       WHERE   RA.cons_inv_id IN
       (SELECT RA1.cons_inv_id
        FROM   ar_receivable_applications RA1,
               ar_payment_schedules PS1,
               ar_payment_schedules PS2
        WHERE  RA1.cons_inv_id IS NULL
        AND    RA1.status                  = 'APP'
        AND    RA1.application_type        IN ('CM', 'CASH')
        AND    RA1.apply_date             < to_date(P_cutoff_date)
        AND    PS1.payment_schedule_id    = RA1.payment_schedule_id
        AND    PS1.customer_site_use_id   = L_sites.site_id
        AND    PS1.invoice_currency_code  = P_currency
        AND    PS2.payment_schedule_id    = RA1.applied_payment_schedule_id
        AND    PS1.customer_site_use_id   = PS2.customer_site_use_id)
       AND    1=2;   -- Added for Defect # 4422 on 5/21/2010 to exclude transactions from consolidation other than INV/CM


/** For Site: finished. Get another site.                                   **/
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
 |                                                                            |
 *----------------------------------------------------------------------------*/
   PROCEDURE update_status (P_print_option IN VARCHAR,
                            P_consinv_id IN NUMBER,
                            P_request_id IN NUMBER) IS

   BEGIN
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
                 AND    IT.transaction_type IN ('INVOICE','CREDIT MEMO')
                 AND    PS.payment_schedule_id = IT.adj_ps_id);

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
           arp_standard.debug( 'Exception: arp_consinv( P_report):'||sqlerrm );
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
                     P_term_id         NUMBER,
                     P_consinv_id      NUMBER,
                     P_request_id      NUMBER,
                     P_print_status    VARCHAR2) IS
   l_report ReportParametersType;
   BEGIN
       l_report.print_option    := P_print_option;
       l_report.detail_option   := P_detail_option;
       l_report.currency_code   := P_currency_code;
       l_report.customer_id     := P_customer_id;
       l_report.customer_number := P_customer_number;
       l_report.bill_to_site    := P_bill_to_site;
       l_report.cutoff_date     := P_cutoff_date;
       l_report.last_day_of_month    := P_last_day_of_month;
       l_report.term_id         := P_term_id;
       l_report.consinv_id      := P_consinv_id;
       l_report.request_id      := P_request_id;
       l_report.print_status    := P_print_status;
--
       Report(l_report);
--
   EXCEPTION
       WHEN OTHERS THEN
           arp_standard.debug( 'Exception:arp_consinv.Report( ...):'||sqlerrm);
           RAISE_APPLICATION_ERROR( -20000, sqlerrm||'$Revision 70.00 $:Report(
... ):' );
   END;
--
   END arp_consinv;
/
SHOW ERR
