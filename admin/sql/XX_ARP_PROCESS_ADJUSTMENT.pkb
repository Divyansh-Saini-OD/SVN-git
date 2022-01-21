/*=======================================================================+
 |  Copyright (c) 1995 Oracle Corporation Redwood Shores, California, USA|
 |                          All rights reserved.                         |
 +=======================================================================+
 | FILENAME
 |      ARTEADJB.pls  - entity handler for adjustments
 |
 | DESCRIPTION
 |      PL/SQL body for package:  XX_ARP_PROCESS_ADJUSTMENT
 |
 |
 | PUBLIC OBJECTS
 |      None
 |
 | PUBLIC PROCEDURES
 |    insert_adjustment
 |    update_adjustment
 |    update_approve_adj
 |    update_approve_adj
 |    test_adj
 |    reverse_adjustment - Entity handler to reverse an adjustment
 |    insert_reverse_actions -  This procedure performs all actions to modify
 |                              the passed in adjustments record and calls
 |                              adjustments insert table handler to 
 |                              insert the reversed adjuetments row
 |    validate_inv_line_amount_cover 
 |    cal_prorated_amounts - calculate prorated revenue and tax amounts
 |			     given an adjustment amount
 |
 | PUBLIC FUNCTIONS
 |      None
 | 
 | PRIVATE PROCEDURES
 |	validate_insert_adjustment
 |	validate_update_adjustment
 |      validate_inv_line_amount
 |      validate_update_approve_adj
 |      set_flags
 |      validate_args_radj - Validate arguments to reverse_adjustment
 |                           procedure 			
 |      modify_adj_rec - Modify an AR_ADJUSTMENTS row for reversal 	     
 |      val_insert_rev_actions - validated arguments passed to
 |			          insert_reverse_actions
 | 
 | PRIVATE FUNCTIONS
 |      None
 | 
 | KNOWN BUGS
 |
 | NOTES
 |	This module is called by AutoInstall (<driver file>) on install and
 |	upgrade.  The WHENEVER SQLERROR and EXIT (at bottom) are required.
 |
 | MODIFICATION HISTORY
 |      24-AUG-95  Martin Johnson      Created
 |      11-DEC-95  Martin Johnson      Merged in procedures from ARCEADJB.pls
 |                                     (reverse_adjustment and 
 |                                      insert_reverse_actions).
 |                                     Changed name of new table handler
 |                                     to ARP_ADJUSTMENTS_PKG.
 |	4/17/1996  Harri Kaukovuo      Modified insert_adjustment()
 |	4/18/1996  Harri Kaukovuo      Modified reverse_adjustment()
 |	7/16/1996  Harri Kaukovuo      Fixed validate_inv_line_amount()
 |				       to get applied_amount right from
 |				       ar_receivable_applications table.
 |					Bug 382421.
 |	7/30/1996 Harri Kaukovuo	Fixed problem with foreign date formats
 |					because AOL sequence number function
 |					date datatype was changed.
 |					Bug 386882.
 |	7/30/1996 Harri Kaukovuo	Bug fix 387035, doc_sequence_id
 |					was missing.
 |	9/17/1996 Harri Kaukovuo	Bug fix 394553 in insert_adjustment().
 |	9/18/1996 Harri Kaukovuo	Bug fix 403019 in update_adjustment().
 |     10/09/1996 Mahesh Sabapathy     PROD 15 : Tax Vendor Synchronization
 |				       Approved Tax adjustments now 
 |				       synchronize tax vendor audits using
 |				       arp_process_tax.sync_vendor_f_ct_adj_id
 |     27-AUG-97	OSTEINME	Fixed bug 540964 (see comments below)
 |     24-OCT-97	OSTEINME	Fixed bug 568533: need to clean up
 |					payment schedule if pending adjustment
 |					is rejected.  See comments below in
 |					update_ajustment procedure.
 |     06-MAR-98	KTANG	       Fixed bug 631699: trap the exception
 |				       if no doc sequence exists for adjustment
 |				       reversal to give a meaningful message.
 |				       Differentiate using always used and 
 |				       partially used doc sequence
 |     16-OCT-98        SBORDE         Fixed bug 741725: Modified insert_
 |                                     reverse_actions(). AOL patch for bug
 |                                     701013 is a prerequisite for this 
 |                                     fix.
 |     05-JAN-99	KTANG	       Changes for VAT
 |     11-FEB-99	KTANG	       Modified cal_prorated_amounts so 
 |				       that all adjusted amount goes to
 |				       charges in case tax remaining and
 |			               charges remaining are both 0.
 |     04-MAR-99	KTANG	       Modified cal_prorated_amounts to
 |				       consider activity tax code
 |     29-JUN-99	KTANG	       Fixed bug 916659: Should not create
 |				       accounting for pending adjustment
 |
 |     03-FEB-00        SRSHAH         Made changes for the BR/BOE project
 |                                     Modified procedures :
 | 					- validate_update_approve_adj
 |					- insert_adjustment
 |					- update_adjustment
 |					- update_approve_adj
 |     24-APR-00        SNAMBIAR       Bug 1277494 Added accounting engine
 |                                     call to update_approve_adj  which
 |                                     was missing
 |     12-May-00        SNAMBIAR       Bug 1290698. Set the type='REVERSE'
 |                                     only when it is an actual reversal
 |                                     not for partial adjustments .Added
 |                                     one more parameter p_move_deffered
 |                                     for BOE/BR project
 |     17-May-00        SNAMBIAR       Added p_move_deferred_tax for BOE/BR.The
 |                                     new parameter is used to detect whether
 |                                     the deferred tax is moved as part of
 |                                     maturity_date event or as a part of
 |                                     activity
 |                                     on the BR (Bug 1290698)
 |     13-Jun-00        SNAMBIAR       Bug 1329091 - Passing a new parameter
 |                                     pay_sched_upd_yn to accounting engine
 |                                     to acknowldge PS is updated.
 |     01-Sep-00        SNAMBIAR       Bug 1395396 - Modified the code to 
 |                                     support $0 LINE and TAX adjustment
 |     28-Sep-00        SNAMBIAR       Bug 1415964 - Modified the code to avoid
 |                                     recalculating the acctd_amount when 
 |                                     adjustment is being reversed. Instead 
 |                                     take the amounts from old adjustment 
 |                                     and reverse it.  Added p_called_from,
 |                                     old_adjust_id parameters
 |                                     to insert_adjustment rountine
 |     31-Jan-01        SNAMBIAR       Bug 1620930- Modified the code for 
 |                                     commitment adjustment 
 |     07-Mar-01        YREDDY         Bug 1686556: Modified to have the
 |                                     correct account in the distributions
 |     01-Mar-02        AMMISHRA       Bug 2248207: Checked for
 |                                     l_amount_original < 0 in procedure   
 |                                     validate_inv_line_amount.
 |     20-Mar-02        RBASKER        Bug 2189230: The tax of adjustment was
 | 			               calculated according to nearest rule
 | 				       everytime. 
 |     11-JUL-02        HYU            Bug 2365805: Manual Charge using 
 |                                     receivable Activity "Finance Charge" 
 |                                     is not hitting the right Receivable 
 |                                     Activity Account it is using the
 |                                     account setup for Adjustment.
 |     28-MAY-03        HYU            Bug#2750340 XLA uptake
 |     22-JUL-05        Naresh Aneja   Bug 4462243 removed GSCC warning 
 |                                     used nocopy hint.
 |     09-AUG-05        MRAYMOND       4544013 - eTax uptake
 |                                     added calls to prorate_recoverable
 |                                     for insert and approval routines.
 |     17-AUG-05        Debbie Jancis  Modified for LLCA
 *=======================================================================*/
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile(120.21.12000000.28=120.22.12010000.24)(120.21.12000000.25=120.22.12010000.21)(120.22.12010000.19=120.43)(120.21.12000000.20=120.22.12010000.16):~PROD:~PATH:~FILE
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_ARP_PROCESS_ADJUSTMENT AS
/* $Header: ARTEADJB.pls 120.22.12010000.24 2012/08/05 11:22:08 ankuagar ship $ */
PG_DEBUG varchar2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');

pg_msg_level_debug    binary_integer;
pg_user_id            binary_integer;  
pg_text_dummy         varchar2(10);
pg_base_curr_code     gl_sets_of_books.currency_code%type;
pg_base_precision     fnd_currencies.precision%type;  
pg_base_min_acc_unit  fnd_currencies.minimum_accountable_unit%type;
/* VAT changes */
SUBTYPE ae_doc_rec_type   IS arp_acct_main.ae_doc_rec_type; 


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    validate_insert_adjustment                                             |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Validates row that is going to be inserted into ar_adjustments         |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:							     |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     25-AUG-95  Martin Johnson      Created                                |
 |     09-APR-96  Martin Johnson      BugNo:354971.  Added call to           |
 |                                      arp_non_db_pkg.check_natural_        |
 |                                      application to check for overapp.    |
 |     18-AUG-97  Debbie Jancis       Bug 715036:  prevent saving of adj if  |
 |                                    balances are not correct.              |
 |                                                                           |
 +===========================================================================*/

PROCEDURE validate_insert_adjustment( p_adj_amount          IN number,
                                      p_payment_schedule_id IN number,
                                      p_type IN varchar2 ) IS

  l_amount_due_original   number;
  l_amount_due_remaining  number;
  l_creation_sign         varchar2(30);
  l_allow_overapp_flag    varchar2(1);

BEGIN

   arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.validate_insert_adjustment()+');

   SELECT ps.amount_due_original,
          ps.amount_due_remaining,
          ctt.creation_sign,
          ctt.allow_overapplication_flag
     INTO l_amount_due_original,
          l_amount_due_remaining,
          l_creation_sign,
          l_allow_overapp_flag
     FROM
          ra_cust_trx_types 	ctt
	, ar_payment_schedules 	ps
    WHERE ps.payment_schedule_id = p_payment_schedule_id
      AND ps.cust_trx_type_id    = ctt.cust_trx_type_id;

arp_util.debug( 'p_type = ' || p_type);
arp_util.debug('adj amount = ' || p_adj_amount);
arp_util.debug('amount due rem ' || l_amount_due_remaining);
 
   IF ( p_type = 'INVOICE'
        and p_adj_amount <> (0 - l_amount_due_remaining)) then
 
       fnd_message.set_name('AR', 'GENERIC_MESSAGE');
       fnd_message.set_token('GENERIC_TEXT', 'Internal Error:  Your totals are o
ut of balance.  Please requery the receipt applications.');
       app_exception.raise_exception;
 
   ELSE
 
      arp_non_db_pkg.check_natural_application( 
	      l_creation_sign,
	      l_allow_overapp_flag,
	      'N',
	      '+',
	      null,
	      p_adj_amount,
	      0,
	      l_amount_due_remaining,
	      l_amount_due_original );
   END IF;

   /* 12926153 - Prevent creation of adjustment if there exists 
      unearned revenue on the target invoice */
        DECLARE
          l_inv_amount  NUMBER;
          l_cm_amount   NUMBER;
          l_uns_amount  NUMBER;
        BEGIN
          /* This invoice either has rules or created with contingency */ 
          SELECT SUM(NVL(d.amount,0)) amount
          INTO   l_inv_amount
          FROM   ra_cust_trx_line_gl_dist d,
                 ar_payment_schedules p
          WHERE  p.payment_schedule_id = p_payment_schedule_id
          AND    d.customer_trx_id = p.customer_trx_id
          AND    d.account_class = 'UNEARN'
          AND    d.account_set_flag = 'N';

          IF l_inv_amount IS NOT NULL 
          THEN
            /* There can any CM applied on this invoice that offsets the Unearn
               balance on the invoice */
            SELECT SUM(NVL(d.amount,0)) amount
            INTO   l_cm_amount
            FROM   ra_cust_trx_line_gl_dist d,
                   ra_customer_trx t,
                   ar_payment_schedules p
            WHERE  p.payment_schedule_id = p_payment_schedule_id
            AND    p.customer_trx_id = t.previous_customer_trx_id
            AND    d.customer_trx_id = t.customer_trx_id
            AND    d.account_class = 'UNEARN'
            AND    d.account_set_flag = 'N';

            l_uns_amount := l_inv_amount + NVL(l_cm_amount,0);

            IF l_uns_amount <> 0 
            THEN
              /* Raise message and halt process */
              arp_util.debug('Unearned balance exists for this transaction');
              fnd_message.set_name('AR', 'AR_UNEARN_PREV_ADJ');
              app_exception.raise_exception;
            END IF;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            arp_util.debug('Exception during Unearned test: ' || SQLERRM); 
            RAISE;
        END;

   arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.validate_insert_adjustment()-');

EXCEPTION
    WHEN OTHERS THEN
     arp_util.debug(
       'EXCEPTION:  XX_ARP_PROCESS_ADJUSTMENT.validate_insert_adjustment()');
     RAISE;

END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    validate_update_adjustment                                             |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Validates row that is going to be updateded in ar_adjustments          |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:							     |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     06-SEP-95  Martin Johnson      Created                                |
 |     18-APR-96  Martin Johnson      BugNo:357974.  Check for               |
 |                                    overapplication when the adjustment    |
 |                                    is approved.                           |
 |                                                                           |
 +===========================================================================*/

PROCEDURE validate_update_adjustment(p_payment_schedule_id IN number,
                                     p_adj_amount          IN number,
                                     p_type                IN varchar2,
                                     p_status_changed_flag IN boolean,
                                     p_status              IN varchar2,
				     p_tax_adjusted	   IN number )
IS

  l_type_adr              number;
  l_type_ado              number;
  l_amount_due_original   number;
  l_amount_due_remaining  number;
  l_creation_sign         varchar2(30);
  l_allow_overapp_flag    varchar2(1);
  /* VAT changes */
  l_tax_remaining	  number;
  l_tax_original	  number;

BEGIN

  arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.validate_update_adjustment()+');

  IF ( p_status_changed_flag ) AND
     ( p_status = 'A' )
  THEN
  
    /*------------------------------------------------------------+
     |  If status changed to Approved, check for overapplication  |
     +------------------------------------------------------------*/

    SELECT     NVL(DECODE(p_type,
                            'CHARGES', ps.amount_due_remaining,
                            'INVOICE', ps.amount_due_remaining,
                            'FREIGHT', ps.freight_remaining,
                            'LINE',    ps.amount_line_items_remaining,
                            'TAX',     ps.tax_remaining ), 
               0 ),
               NVL(DECODE(p_type,
                            'CHARGES', ps.amount_due_original,
                            'INVOICE', ps.amount_due_original,
                            'FREIGHT', ps.freight_original,
                            'LINE',    ps.amount_line_items_original,
                            'TAX',     ps.tax_original ),
               0 ),
	       ps.tax_remaining,
	       ps.tax_original,
               ps.amount_due_remaining,
               ps.amount_due_original,
               ctt.creation_sign,
               ctt.allow_overapplication_flag
          INTO l_type_adr,
               l_type_ado,
	       /* VAT changes */
	       l_tax_remaining,
	       l_tax_original,
               l_amount_due_remaining,
               l_amount_due_original,
               l_creation_sign,
               l_allow_overapp_flag
          FROM ar_payment_schedules ps,
               ra_cust_trx_types ctt
         WHERE ps.payment_schedule_id = p_payment_schedule_id
           AND ps.cust_trx_type_id    = ctt.cust_trx_type_id;

    IF ( p_type = 'INVOICE' )
      THEN
        /*----------------------------------------------------------+
         |  Invoice type adjustment must make the balance due zero  |
         +----------------------------------------------------------*/

        IF ( l_amount_due_remaining + p_adj_amount <> 0 )
          THEN fnd_message.set_name('AR', 'AR_TW_VAL_AMT_ADJ_INV');
               app_exception.raise_exception;
        END IF;

      ELSE

        /*----------------------------------------------------------+
         |  Check for overapplication based on the adjustment type  |
         +----------------------------------------------------------*/

        arp_non_db_pkg.check_natural_application( 
	      l_creation_sign,
	      l_allow_overapp_flag,
	      'N',
	      '+',
	      null,
	      /* VAT changes */
	      p_adj_amount - nvl(p_tax_adjusted, 0),
	      0,
	      l_type_adr,
	      l_type_ado ); 

        /*------------------------------------+
         |  Check for overapplication of tax  |
         +------------------------------------*/

	IF p_type in ('CHARGES', 'LINE') and
	   nvl(p_tax_adjusted,0) <> 0 THEN
          arp_non_db_pkg.check_natural_application(
              l_creation_sign,
              l_allow_overapp_flag,
              'N',
              '+',
              null,
              p_tax_adjusted,
              0,
              l_tax_remaining,
              l_tax_original );
	END IF;


        /*-----------------------------------------------------+
         |  Check for overapplication of amount_due_remaining  |           
         +-----------------------------------------------------*/

        arp_non_db_pkg.check_natural_application( 
	      l_creation_sign,
	      l_allow_overapp_flag,
	      'N',
	      '+',
	      null,
	      p_adj_amount,
	      0,
	      l_amount_due_remaining,
	      l_amount_due_original );

    END IF;

  END IF;

  arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.validate_update_adjustment()-');

EXCEPTION
    WHEN OTHERS THEN
      FND_MESSAGE.set_name( 'AR', 'GENERIC_MESSAGE' );
      FND_MESSAGE.set_token( 'GENERIC_TEXT', 'arp_non_db_pkg.check_natural_application exception: '||SQLERRM ); 
     arp_util.debug(
       'EXCEPTION:  XX_ARP_PROCESS_ADJUSTMENT.validate_update_adjustment()');
     RAISE;

END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    set_flags								     |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Sets various change and status flags for the current record.  	     |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |			p_adjustment_id                                      |
 |			p_new_adj_rec                                        |
 |              OUT:                                                         |
 |			p_status_changed_flag                                |
 |          IN/ OUT:							     |
 |                    	None						     |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     06-SEP-95  Martin Johnson      Created                                |
 |                                                                           |
 +===========================================================================*/

PROCEDURE set_flags(
  p_adjustment_id        IN ar_adjustments.adjustment_id%type,
  p_old_adj_rec          IN ar_adjustments%rowtype,
  p_new_adj_rec          IN ar_adjustments%rowtype,
  p_status_changed_flag OUT NOCOPY boolean)

IS

BEGIN

   arp_util.debug('ar_process_adjustment.set_flags()+',
                  pg_msg_level_debug);

   arp_util.debug('p_old_adj_rec.status: ' || p_old_adj_rec.status );
   arp_util.debug('p_new_adj_rec.status: ' || p_new_adj_rec.status );
   arp_util.debug('pg_text_dummy: ' || pg_text_dummy );

   IF (
        nvl(p_old_adj_rec.status, '!@#$%') <> 
        nvl(p_new_adj_rec.status, '!@#$%')
        AND
        nvl(p_new_adj_rec.status, '!@#$%') <> pg_text_dummy
      )
     THEN p_status_changed_flag := TRUE;
     ELSE p_status_changed_flag := FALSE;
   END IF;

   arp_util.debug('ar_process_adjustment.set_flags()-',
                  pg_msg_level_debug);

EXCEPTION
  WHEN OTHERS THEN

  /*---------------------------------------------+
   |  Display parameters and raise the exception |
   +---------------------------------------------*/

   arp_util.debug('EXCEPTION:  XX_ARP_PROCESS_ADJUSTMENT.set_flags()');

   arp_util.debug('');
   arp_util.debug('---------- parameters for set_flags() ---------');

   arp_util.debug('p_adjustment_id = ' || p_adjustment_id);
   arp_util.debug('');

   arp_util.debug('---------- new adjustment record ----------');
   arp_adjustments_pkg.display_adj_rec( p_new_adj_rec );
   arp_util.debug('');

   RAISE;

END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    validate_inv_line_amount                                               |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    validates that the adjustment is not for more than available invoiced  |
 |       line amount.                                                        |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_adj_rec                                              |
 |                    p_ps_rec                                               |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 | 08-SEP-95  	Charlie Tomberg		Created
 | 7/16/1996	Harri Kaukovuo		Bug 382421. Line level adjustment
 |					check was looking for header level
 |					applications from 
 |					ar_receivable_applications.
 +===========================================================================*/

PROCEDURE validate_inv_line_amount(p_adj_rec IN
                                             ar_adjustments%rowtype,
                                   p_ps_rec  IN ar_payment_schedules%rowtype)
                                IS
  
   CURSOR cu_rem_amt(p_customer_trx_id IN NUMBER, p_customer_trx_line_id IN NUMBER) IS
   SELECT b.sum_orig                                                          sum_orig
         ,b.sum_acctd_orig                                                    sum_acctd_orig
         ,SUM((DECODE(a.activity_bucket,'ADJ_CHRG',amt
                      ,'APP_CHRG',DECODE(a.line_type,'LINE',amt,0) * -1,0)))       CHRG_ON_REV_LINE
         ,SUM((DECODE(a.activity_bucket,'ADJ_CHRG',acctd_amt
                      ,'APP_CHRG',DECODE(a.line_type,'LINE',acctd_amt,0) * -1,0))) ACCTD_CHRG_ON_REV_LINE
         ,SUM((DECODE(a.activity_bucket,'ADJ_FRT',amt
                      ,'APP_FRT',DECODE(a.line_type,'LINE',amt,0) * -1,0)))        FRT_ON_REV_LINE
         ,SUM((DECODE(a.activity_bucket,'ADJ_FRT',amt
                      ,'APP_FRT',DECODE(a.line_type,'LINE',acctd_amt,0) * -1,0)))  ACCTD_FRT_ON_REV_LINE
         ,SUM((DECODE(a.activity_bucket,'ED_FRT',amt,0)))                              ED_FRT_REV_LINE
         ,SUM((DECODE(a.activity_bucket,'ED_FRT',acctd_amt,0)))                        ACCTD_ED_FRT_REV_LINE
         ,SUM((DECODE(a.activity_bucket,'UNED_FRT',amt,0)))                            UNED_FRT_REV_LINE
         ,SUM((DECODE(a.activity_bucket,'UNED_FRT',acctd_amt,0)))                      ACCTD_UNED_FRT_REV_LINE
         ,SUM((DECODE(a.activity_bucket,'ADJ_LINE',amt
                              ,'APP_LINE',(amt * -1)  
                              ,'ED_LINE' ,amt
                              ,'UNED_LINE',amt -- line
                              ,'ADJ_TAX' ,amt
                              ,'APP_TAX' ,(amt * -1)  
                              ,'ED_TAX' ,amt
                              ,'UNED_TAX',amt  --tax
                              ,'APP_FRT' ,(DECODE(a.line_type,'FREIGHT',amt,0) * -1)  
                              ,'APP_CHRG',(DECODE(a.line_type,'CHARGES',amt,0) * -1)  
                              ,0)))                                           REM_TYPE_LINE
         ,SUM((DECODE(a.activity_bucket,'ADJ_LINE',acctd_amt
                              ,'APP_LINE',(acctd_amt * -1)  
                              ,'ED_LINE' ,acctd_amt
                              ,'UNED_LINE',acctd_amt -- line
                              ,'ADJ_TAX' ,acctd_amt
                              ,'APP_TAX' ,(acctd_amt * -1)  
                              ,'ED_TAX' ,acctd_amt
                              ,'UNED_TAX',acctd_amt  --tax
                              ,'APP_FRT' ,(DECODE(a.line_type,'FREIGHT',acctd_amt,0) * -1)  
                              ,'APP_CHRG',(DECODE(a.line_type,'CHARGES',acctd_amt,0) * -1) 
                              ,0)))                                           ACCTD_REM_TYPE_LINE
         ,b.customer_trx_line_id                                              CUSTOMER_TRX_LINE_ID,
          ctl1.line_type line_type
  FROM
  (SELECT SUM( NVL(ard.amount_cr,0)       - NVL(ard.amount_dr,0)      ) amt,
         SUM( NVL(ard.acctd_amount_cr,0) - NVL(ard.acctd_amount_dr,0)) acctd_amt,
         ard.ref_customer_trx_line_id,
         ard.ref_account_class,
         ard.activity_bucket,
         ctl.line_type
    FROM ar_distributions      ard,
         ra_customer_trx_lines ctl
   WHERE ctl.customer_trx_id      = p_customer_trx_id
     AND ctl.customer_trx_line_id = ard.ref_customer_trx_line_id
     AND (ctl.customer_trx_line_id = p_customer_trx_line_id
         OR
	 (ctl.link_to_cust_trx_line_id = p_customer_trx_line_id 
	  AND ctl.line_type = 'TAX'
	 )
	)
   GROUP BY 
         ard.ref_customer_trx_line_id,
         ard.ref_account_class,
         ard.activity_bucket,
         ctl.line_type) a,
  (SELECT SUM(ctlgd.AMOUNT)          sum_orig,
          SUM(ctlgd.ACCTD_AMOUNT)    sum_acctd_orig,
          ctlgd.customer_trx_line_id
     FROM ra_cust_trx_line_gl_dist ctlgd,
          ra_customer_trx_lines ctll
    WHERE ctlgd.customer_trx_id  = p_customer_trx_id
      AND ctlgd.customer_trx_line_id = ctll.customer_trx_line_id
      AND (ctll.customer_trx_line_id = p_customer_trx_line_id
          OR
	  (ctll.link_to_cust_trx_line_id = p_customer_trx_line_id 
	  AND ctll.line_type = 'TAX'
	  )
	 )
    GROUP BY ctlgd.customer_trx_line_id) b,
    ra_customer_trx_lines ctl1
  WHERE a.ref_customer_trx_line_id (+) =  b.customer_trx_line_id
  and b.customer_trx_line_id=ctl1.customer_trx_line_id
  GROUP BY b.customer_trx_line_id,
           b.sum_orig,
           b.sum_acctd_orig, ctl1.line_type;

/*  CURSOR cu_line_tax (p_customer_trx_id IN NUMBER, p_customer_trx_line_id IN NUMBER) IS
  SELECT customer_trx_line_id 
  FROM   ra_customer_trx_lines 
  WHERE  customer_trx_line_id = p_customer_trx_id 
  AND   (customer_trx_line_id = p_customer_trx_line_id
         OR
	 (link_to_cust_trx_line_id = p_customer_trx_line_id 
	  AND line_type = 'TAX'
	 )
	);
*/

  l_result         VARCHAR2(1);
  l_term_ratio     NUMBER;
  l_line_original  NUMBER;
  l_sum_line_adj   NUMBER;
  l_line_credited  NUMBER;
  l_line_applied   NUMBER;
  l_line_tax       VARCHAR2(10);
  l_remain_amt     NUMBER;
  l_tax_code_source    ar_receivables_trx.tax_code_source%TYPE; -- Bug 13882660


BEGIN

   arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.validate_inv_line_amount()+',
                  pg_msg_level_debug);

  /*----------------------------------------------------------------+
   |  IF   the line number is filled in                             |
   |  THEN validate adjustment is not more than available invoiced  |
   |       line amount                                              |
   +----------------------------------------------------------------*/

   IF    ( p_adj_rec.customer_trx_line_id IS NOT NULL )
   THEN  

       l_remain_amt := 0;
       l_line_original:= 0;
 
       IF(p_adj_rec.receivables_trx_id IS NOT NULL) THEN -- Bug 13882660
        SELECT tax_code_source
          INTO l_tax_code_source
          FROM ar_receivables_trx
          WHERE receivables_trx_id = p_adj_rec.receivables_trx_id;
       END IF;

       FOR i IN cu_rem_amt(p_adj_rec.customer_trx_id, p_adj_rec.customer_trx_line_id) LOOP
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('Value of l_remain_amt: ' || l_remain_amt);
	      arp_util.debug('Value of sum_orig: ' || i.sum_orig);
	      arp_util.debug('Value of REM_TYPE_LINE: ' || i.REM_TYPE_LINE);
	      arp_util.debug('Value of l_line_original: ' || l_line_original);
	   END IF;
 	      IF(Nvl(l_tax_code_source,'NONE') = 'NONE') THEN -- Bug 13882660
                IF(i.line_type <> 'TAX') THEN
                  l_remain_amt := l_remain_amt + i.sum_orig + i.REM_TYPE_LINE;
                  l_line_original := l_line_original + i.sum_orig;
                END IF;
              ELSE
                   l_remain_amt := l_remain_amt + i.sum_orig + i.REM_TYPE_LINE;
                   l_line_original := l_line_original + i.sum_orig;
              END IF;
       END LOOP;

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Value of l_remain_amt: ' || l_remain_amt);
	  arp_util.debug('Value of l_line_original: ' || l_line_original);
       END IF;

        /*------------------------------------------+ 
         |  Get the amounts used to calculate the   |
         |  available invoiced line amount.         |
         +------------------------------------------*/
/* 1909312
Terms will not be present for Credit Memos. 
Added the following IF Condition and the ELSE clause */
/*
	IF (p_ps_rec.Term_id IS NOT NULL) THEN 
         	SELECT  NVL( tl.relative_amount, 1) /
                	NVL( t.base_amount, 1),
                	arpcurr.CurrRound(
                                   (
                                     NVL( tl.relative_amount, 1) /
                                     NVL( t.base_amount, 1) 
                                   ) *
                                   ctl.extended_amount,
                                   p_ps_rec.invoice_currency_code
                                 )
        	INTO    l_term_ratio,
       	        	l_line_original
        	FROM    ra_terms_lines        tl,
       		        ra_terms              t,
               		ra_customer_trx_lines ctl
        	WHERE  p_ps_rec.term_id               = t.term_id
        	AND    t.term_id                      = tl.term_id
        	AND    p_ps_rec.terms_sequence_number = tl.sequence_num
        	AND    ctl.customer_trx_line_id       = 
						p_adj_rec.customer_trx_line_id;
	ELSE	*/ /* 1909312 Code Added begins */ 
/*		SELECT  ctl.extended_amount
		INTO	l_line_original
		FROM	ra_customer_trx_lines ctl
		WHERE	ctl.customer_trx_line_id = 
						p_adj_rec.customer_trx_line_id;	
		l_term_ratio := 1;
	END IF; */ /* 1909312 Code Added Ends */ 
  
  --Add for 13538911
/*  SELECT NVL(SUM(ctl.extended_amount),0)
  INTO l_line_tax
  FROM ra_customer_trx_lines ctl
  WHERE ctl.link_to_cust_trx_line_id= 
						p_adj_rec.customer_trx_line_id;
	
        SELECT NVL(SUM(amount),0)
        INTO   l_sum_line_adj
        FROM   ar_adjustments
        WHERE  customer_trx_line_id = p_adj_rec.customer_trx_line_id
        AND    NVL(postable, 'Y')   = 'Y'
        AND    customer_trx_id      = p_adj_rec.customer_trx_id;

        SELECT arpcurr.CurrRound(
                                  NVL(
                                        SUM( ctl.extended_amount *
                                             l_term_ratio ),
                                        0
                                     ),
                                  p_ps_rec.invoice_currency_code
                                )
        INTO   l_line_credited
        FROM   ra_customer_trx_lines ctl
        WHERE  ctl.previous_customer_trx_line_id = 
               p_adj_rec.customer_trx_line_id;
*/
/*
This does not work
        SELECT NVL(
                    SUM(ra.amount_applied )
                    , 0
                  )
        INTO   l_line_applied
        FROM   ar_receivable_applications ra
        WHERE  applied_payment_schedule_id = p_adj_rec.payment_schedule_id
        AND    applied_customer_trx_id     = p_adj_rec.customer_trx_id;
*/ 
/*        SELECT NVL(
                    SUM(ra.amount_applied )
                    , 0
                  )
        INTO   l_line_applied
        FROM   ar_receivable_applications ra
        WHERE  
        	ra.applied_customer_trx_id     = p_adj_rec.customer_trx_id
 	AND 	ra.applied_customer_trx_line_id= p_adj_rec.customer_trx_line_id;

        arp_util.debug('Adj Amt: ' || p_adj_rec.amount ||
                       '  Line Orig: ' || l_line_original ||
                       '  Adj : ' || l_sum_line_adj ||'  Cred: ' || 
                       l_line_credited || '  Appl: ' || l_line_applied ||
                       '  Net: ' || TO_CHAR(p_adj_rec.amount +
                                            l_line_original  +
                                            l_sum_line_adj   +
                                            l_line_credited  -
                                            l_line_applied ) );
*/
/*Bug 2248207: The procedure was initially checking for positive invoice amount and 
	       Was rejecting the Adjustment if the amount exceeds the remaining amount.
		Now this is checking for negative amount as well.
*/
/*
IF (l_line_original > 0) THEN
        IF  (
              p_adj_rec.amount +
              l_line_original  +
              l_sum_line_adj   +
			  l_line_tax       +--Add for 13538911
              l_line_credited  -
              l_line_applied      < 0
            )
        THEN
             arp_util.debug( 'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.' ||
                                         'validate_inv_line_amount ()',
                              pg_msg_level_debug);
             arp_util.debug( 'Adjustments cannot be more than available ' ||
                             'invoiced line amount.',
                             pg_msg_level_debug);
             FND_MESSAGE.set_name('AR', 'AR_VAL_ADJ_INV_LINE_AMT');
             APP_EXCEPTION.raise_exception;
        END IF;
ELSIF (l_line_original < 0) THEN
       IF (
		p_adj_rec.amount +
		l_line_original+
		l_sum_line_adj +
		l_line_tax       +--Add for 13538911
		l_line_credited -
		l_line_applied > 0
	 )
	THEN
		 arp_util.debug( 'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.' ||
                                         'validate_inv_line_amount ()',
                              pg_msg_level_debug);
             arp_util.debug( 'Adjustments cannot be more than available ' ||
                             'invoiced line amount.',
                             pg_msg_level_debug);
             FND_MESSAGE.set_name('AR', 'AR_VAL_ADJ_INV_LINE_AMT');
             APP_EXCEPTION.raise_exception;
        END IF;
END IF; */

IF (l_line_original > 0) THEN
        IF  (
              p_adj_rec.amount +
              l_remain_amt < 0
            )
        THEN
             arp_util.debug( 'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.' ||
                                         'validate_inv_line_amount ()',
                              pg_msg_level_debug);
             arp_util.debug( 'Adjustments cannot be more than available ' ||
                             'invoiced line amount.',
                             pg_msg_level_debug);
             FND_MESSAGE.set_name('AR', 'AR_VAL_ADJ_INV_LINE_AMT');
             APP_EXCEPTION.raise_exception;
        END IF;
ELSIF (l_line_original < 0) THEN
       IF (
		p_adj_rec.amount +
		l_remain_amt > 0
	 )
	THEN
		 arp_util.debug( 'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.' ||
                                         'validate_inv_line_amount ()',
                              pg_msg_level_debug);
             arp_util.debug( 'Adjustments cannot be more than available ' ||
                             'invoiced line amount.',
                             pg_msg_level_debug);
             FND_MESSAGE.set_name('AR', 'AR_VAL_ADJ_INV_LINE_AMT');
             APP_EXCEPTION.raise_exception;
        END IF;
END IF; 

   END IF;    -- end not approved or adjusted and line specified case


   arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.validate_inv_line_amount()-',
                  pg_msg_level_debug);

EXCEPTION
    WHEN OTHERS THEN
     arp_util.debug('EXCEPTION:  XX_ARP_PROCESS_ADJUSTMENT.' ||
                    'validate_inv_line_amount()',
                    pg_msg_level_debug);

     arp_util.debug('', pg_msg_level_debug);
     arp_util.debug('---------- parameters for validate_inv_line_amount()' ||
                    '  ---------',
                    pg_msg_level_debug);

     arp_adjustments_pkg.display_adj_rec( p_adj_rec );

     RAISE;

END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    validate_inv_line_amount_cover                                         |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    validates that the adjustment is not for more than available invoiced  |
 |       line amount.                                                        |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_customer_trx_line_id                                 |
 |                    p_customer_trx_id                                      |
 |                    p_payment_schedule_id                                  |
 |                    p_amount                                               |
 |                    p_invoice_currency_code                                |
 |                    p_term_id                                              |
 |                    p_terms_sequence_number                                |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     25-JUN-96  Charlie Tomberg      Created                               |
 |                                                                           |
 +===========================================================================*/

PROCEDURE validate_inv_line_amount_cover(
                                    p_customer_trx_line_id   IN number,
                                    p_customer_trx_id        IN number,
                                    p_payment_schedule_id    IN number,
                                    p_amount                 IN number,
				    p_receivables_trx_id     IN NUMBER DEFAULT NULL) IS

   l_adj_rec  ar_adjustments%rowtype;
   l_ps_rec   ar_payment_schedules%rowtype;

BEGIN

   arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.validate_inv_line_amount_cover()+',
                  pg_msg_level_debug);

   l_adj_rec.customer_trx_line_id  := p_customer_trx_line_id;
   l_adj_rec.customer_trx_id       := p_customer_trx_id;
   l_adj_rec.payment_schedule_id   := p_payment_schedule_id;
   l_adj_rec.amount                := p_amount;
   l_adj_rec.receivables_trx_id    := p_receivables_trx_id; -- Bug 13882660

   SELECT term_id,
          terms_sequence_number,
          invoice_currency_code
   INTO   l_ps_rec.term_id,
          l_ps_rec.terms_sequence_number,
          l_ps_rec.invoice_currency_code
   FROM   ar_payment_schedules
   WHERE  payment_schedule_id = p_payment_schedule_id;

   validate_inv_line_amount( l_adj_rec, l_ps_rec );

   arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.validate_inv_line_amount_cover()-',
                  pg_msg_level_debug);

EXCEPTION
    WHEN OTHERS THEN
     arp_util.debug('EXCEPTION:  XX_ARP_PROCESS_ADJUSTMENT.' ||
                    'validate_inv_line_amount_cover()',
                    pg_msg_level_debug);

     arp_util.debug('', pg_msg_level_debug);
     arp_util.debug('---------- parameters for ' ||
                    'validate_inv_line_amount_cover()' ||
                    '  ---------',
                    pg_msg_level_debug);

     arp_util.debug('p_customer_trx_line_id  = ' ||
                    TO_CHAR(p_customer_trx_line_id), pg_msg_level_debug);
     arp_util.debug('p_customer_trx_id       = ' || 
                    TO_CHAR(p_customer_trx_id), pg_msg_level_debug);
     arp_util.debug('p_payment_schedule_id   = ' || 
                    TO_CHAR(p_payment_schedule_id), pg_msg_level_debug);
     arp_util.debug('p_amount                = ' || 
                    TO_CHAR(p_amount), pg_msg_level_debug);

     RAISE;

END;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    validate_update_approve_adj                                            |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Validates row that is going to be approved.                            |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_adj_rec                                              |
 |                    p_ps_rec                                               |
 |                    p_adjustment_code                                      |
 |                    p_chk_approval_limits                                  |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     08-SEP-95  Charlie Tomberg  Created                                   |
 |                                                                           |
 |     03-FEB-00  Saloni Shah      Made changes data model changes to        |
 |                                 AR_APPROVAL_USER_LIMITS.                  |
 |                                                                           |
 |     03-FEB-00  Saloni Shah      Made changes for the BR/BOE project       |
 |                                 A new IN parameter p_chk_approval_limits  |
 |                                 was added.                                |
 |                                                                           |
 +===========================================================================*/

PROCEDURE validate_update_approve_adj( p_adj_rec          IN ar_adjustments%rowtype,
                                       p_ps_rec           IN ar_payment_schedules%rowtype,
                                       p_adjustment_code  IN ar_lookups.lookup_code%type,
                                       p_chk_approval_limits   IN      varchar2 
                                      ) IS

   l_varchar_dummy         VARCHAR2(128);
   l_date_dummy            DATE;
   l_number_dummy          NUMBER;
   l_closing_status        gl_period_statuses.closing_status%type;
   l_result                VARCHAR2(1);
   l_approval_amount_to    ar_approval_user_limits.amount_to%type;
   l_approval_amount_from  ar_approval_user_limits.amount_from%type;

BEGIN

   arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.validate_update_approve_adj()+',
                  pg_msg_level_debug);


   IF  ( p_adjustment_code  = 'A' )
   THEN
   
       /*-------------------------------------------------------------------+
        |  validate that GL Date is in an open or future enterable period   |
        +-------------------------------------------------------------------*/

        arp_standard.gl_period_info( p_adj_rec.gl_date,
                                     l_varchar_dummy,
                                     l_date_dummy,
                                     l_date_dummy,
                                     l_closing_status,
                                     l_varchar_dummy,
                                     l_number_dummy,
                                     l_number_dummy,
                                     l_number_dummy );

        IF     ( l_closing_status not in ('O', 'F' ) )
        THEN  

             arp_util.debug( 'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.' ||
                                         'validate_update_approve_adj ()',
                              pg_msg_level_debug);
             arp_util.debug( 'Invalid date. Enter a GL date in an open or' ||
                             ' future enterable period.',
                             pg_msg_level_debug);
             FND_MESSAGE.set_name('AR', 'AR_VAL_GL_DATE_OPEN');
             APP_EXCEPTION.raise_exception;
        END IF;

       /*------------------------------------------------------------------+
        |  validate that GL date is not be prior to the invoice's GL date  |
        +------------------------------------------------------------------*/

        IF    ( p_adj_rec.gl_date < p_ps_rec.gl_date )
        THEN  
        
             arp_util.debug( 'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.' ||
                                         'validate_update_approve_adj ()',
                              pg_msg_level_debug);
             arp_util.debug( 'The GL date should not be prior to the ' ||
                             'invoice''s GL date.',
                             pg_msg_level_debug);
             FND_MESSAGE.set_name('AR', 'AR_VAL_GL_INV_GL');
             APP_EXCEPTION.raise_exception;

        END IF;

       /*------------------------------------------------------------+
        |  validate that user has approval limits for the currency   |
        |                                                            |
        |  Change made for BR/BOE project                            |
        |  The adjusted amount is validated against the user approval|
        |  limits only if the p_chk_approval_limits has value 'T'    |
        +------------------------------------------------------------*/
  
    IF (p_chk_approval_limits = FND_API.G_TRUE ) THEN
        BEGIN
             SELECT aul.amount_to,
                    aul.amount_from
             INTO   l_approval_amount_to,
                    l_approval_amount_from
             FROM   ar_approval_user_limits aul
             WHERE  aul.user_id       = arp_adjustments_pkg.pg_user_id
             AND    aul.currency_code = p_ps_rec.invoice_currency_code
  /* Bug 941429: Credit memo workflow added a new document_type column
     to AR_APPROVAL_USER_LIMITS. Now user_id and currency_code alone can't
     uniquely identify a row. Need to include document_type as well */
	     AND    aul.document_type = 'ADJ';

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
             arp_util.debug( 'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.' ||
                                         'validate_update_approve_adj ()',
                              pg_msg_level_debug);
             arp_util.debug( 'You do not have approval limits for currency ' ||
                             p_ps_rec.invoice_currency_code,
                             pg_msg_level_debug);
             FND_MESSAGE.set_name('AR', 'AR_VAL_USER_LIMIT');
             FND_MESSAGE.set_token( 'CURRENCY', 
                                    p_ps_rec.invoice_currency_code);
             APP_EXCEPTION.raise_exception;

          WHEN OTHERS THEN RAISE;
        END;
     
        IF  (
                 (  p_adj_rec.amount > l_approval_amount_to )
             OR
                 (  p_adj_rec.amount < l_approval_amount_from )
            )
        THEN

             arp_util.debug( 'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.' ||
                                         'validate_update_approve_adj ()',
                              pg_msg_level_debug);
             arp_util.debug( 'User ID: ' || arp_adjustments_pkg.pg_user_id || 
                             '  Amount: ' ||
                             p_adj_rec.amount || '   From: ' ||
                             l_approval_amount_from || '   To: ' ||
                             l_approval_amount_to, 
                             pg_msg_level_debug);
             arp_util.debug( 'Amount exceeded approval limit.',
                             pg_msg_level_debug);
             FND_MESSAGE.set_name('AR', 'AR_VAL_AMT_APPROVAL_LIMIT');
             APP_EXCEPTION.raise_exception;

        END IF;

     END IF; 

        validate_inv_line_amount( p_adj_rec,
                                  p_ps_rec );

   END IF;         -- end approved case


   arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.validate_update_approve_adj()-',
                  pg_msg_level_debug);

EXCEPTION
    WHEN OTHERS THEN
     arp_util.debug('EXCEPTION:  XX_ARP_PROCESS_ADJUSTMENT.' ||
                    'validate_update_approve_adj()',
                    pg_msg_level_debug);

     arp_util.debug('', pg_msg_level_debug);
     arp_util.debug('---------- parameters for validate_update_approve_adj()'
                    || '  ---------',
                    pg_msg_level_debug);

     arp_util.debug('p_adjustment_code   = ' || p_adjustment_code );
     arp_adjustments_pkg.display_adj_rec( p_adj_rec );

     RAISE;

END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    insert_adjustment							     |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Inserts a record into ar_adjustments                                   |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |			p_form_name                                          |
 |			p_form_version                                       |
 |			p_check_amount                                       |
 |              OUT:                                                         |
 |			p_adjustment_number                                  |
 |			p_adjustment_id                                      |
 |          IN/ OUT:							     |
 |			p_adj_rec                                            |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |	24-AUG-95	Martin Johnson      Created                          |
 |	4/17/1996	Harri Kaukovuo	Added special handling for           |
 |					chargebacks.                         |
 |	9/17/1996	Harri Kaukovuo	Bug fix 394553.                      |
 |     									     |
 |     03-FEB-00        Saloni Shah     Made changes for the BR/BOE project. |
 |                                      When adjustment is reversed, then the|
 |                                      validation on the amounts is not done|
 |     17-May-00       Satheesh Nambiar Added p_move_deferred_tax for BOE/BR.
 |                                      The new parameter is used to detect 
 |                                      whether the deferred tax is moved as 
 |                                      part of maturity_date event or as a 
 |                                      part of activity on the BR(Bug 1290698)
 |     13-Jun-00       Satheesh Nambiar Bug 1329091 - Passing one more      | 
 |                                      parameter to accounting engine      |
 |     25-Aug-00       SNAMBIAR         Bug 1395396
 |                                      Modified the code accept $0 adjustment
 |     25-Aug-00       SNAMBIAR         Added a new parameter p_called_from
 |                                      for BR to pass to Accounting engine.
 |                                      Added a new parameter old_adjustment_id
 |                                      for calling Accounting engine in REVERSE
 |                                      mode.(Bug 1415964) 
 |     31-Jan-01       SNAMBIAR         Bug 1620930 - Modified for commitment
 |                                      adjustment 
 |     07-Mar-01       YREDDY           Bug 1686556: Modified to have the
 |                                      correct account in the distributions
 |     11-JUL-02       HYU              Bug 2365805: Manual charge using "Finance Charge"
 |                                      is incorrect.
 |     09-AUG-05       MRAYMOND         4544013 - Implemented etax calls for
 |                                      adjustment API and forms
 +===========================================================================*/

PROCEDURE insert_adjustment(p_form_name IN varchar2,
                            p_form_version IN number,
                            p_adj_rec IN OUT
                              ar_adjustments%rowtype,
                            p_adjustment_number OUT NOCOPY 
                              ar_adjustments.adjustment_number%type,
                            p_adjustment_id OUT NOCOPY 
                              ar_adjustments.adjustment_id%type,
			    p_check_amount IN varchar2 := FND_API.G_TRUE,
			    p_move_deferred_tax IN varchar2 := 'Y',
			    p_called_from IN varchar2 DEFAULT NULL, 
			    p_old_adjust_id IN ar_adjustments.adjustment_id%type DEFAULT NULL,
                            p_override_flag IN varchar2 DEFAULT NULL,
                            p_app_level  IN VARCHAR2 DEFAULT 'TRANSACTION')


IS

   l_adjustment_id   ar_adjustments.adjustment_id%type;
   l_ps_rec          ar_payment_schedules%rowtype;
   l_acctd_amount    ar_adjustments.acctd_amount%type;
   l_amount_adjusted ar_payment_schedules.amount_adjusted%type;
   l_aah_rec         ar_approval_action_history%rowtype;
   l_approval_action_history_id 
     ar_approval_action_history.approval_action_history_id%type;
   ln_adr_tmp		NUMBER;
   ln_acctd_adr_tmp	NUMBER;
   /* VAT changes */
   l_ae_doc_rec 	ae_doc_rec_type;

   l_adj_type ar_adjustments.type%type;
   l_accounting_affect_flag ar_receivables_trx.accounting_affect_flag%type;
   
   l_app_ps_status VARCHAR2(10);
   --BUG#2750340
   l_xla_ev_rec   arp_xla_events.xla_events_type;

   /* 4544013 */
   l_gt_id          NUMBER := 0;
   l_gt_id_temp     NUMBER := 0;
   l_line_amt       NUMBER;
   l_tax_amt        NUMBER;
   l_from_llca_call VARCHAR2(1) := 'N';
   l_mode           VARCHAR2(20);
-- Line level Adjustment 
   l_line_adjusted	NUMBER;
   l_tax_adjusted  NUMBER;
   l_line_id       NUMBER;

   l_customer_trx ra_customer_trx%ROWTYPE;
   l_gl_account_source ar_receivables_trx.gl_account_source%type;
   l_tax_code_source ar_receivables_trx.tax_code_source%type;
BEGIN

   arp_util.debug('ar_process_adjustment.insert_adjustment()+');

   p_adjustment_number 	:= NULL;
   p_adjustment_id 	:= NULL;

   -- check form version to determine if it is compatible with the 
   -- entity handler.
      arp_trx_validate.ar_entity_version_check(p_form_name, p_form_version);

   -- Lock rows in other tables that reference this customer_trx_id 
      arp_trx_util.lock_transaction(p_adj_rec.customer_trx_id);

   /*-----------------------------------+
    |  Get the payment schedule record  |
    +-----------------------------------*/

   arp_ps_pkg.fetch_p(p_adj_rec.payment_schedule_id, l_ps_rec);

   --apandit
   l_app_ps_status := l_ps_rec.status;

   /*--------------------+
    |  pre-insert logic  | 
    +--------------------*/

   arp_util.debug( 'p_app_level = ' || p_app_level);
   arp_util.debug( 'p_type = ' || p_adj_rec.type);
   arp_util.debug('adj amount = ' || p_adj_rec.amount);

   /*----------------------------------------------------+
    |  BOE change                                        |
    |  For a reverse adjustment the validation on insert |
    |  for the amounts is not done.                      |
    |  The reversal of an adjustment is indicated by     |
    |  p_check_amount flag set to 'F'                    |
    +----------------------------------------------------*/
    
   select nvl(gl_account_source,'NONE'),
          nvl(tax_code_source,'NONE') 
   into   l_gl_account_source,
          l_tax_code_source
   from ar_receivables_trx 
   where receivables_trx_id =  p_adj_rec.receivables_trx_id;

   IF  ((l_gl_account_source = 'REVENUE_ON_INVOICE')
         AND (((nvl(p_adj_rec.line_adjusted,0) +
                nvl(p_adj_rec.freight_adjusted,0) +
                nvl(p_adj_rec.receivables_charges_adjusted,0)) <> 0)
         OR ((l_tax_code_source = 'NONE') 
             AND  (nvl(p_adj_rec.tax_adjusted,0) <> 0))
        ))
   THEN
   IF (p_check_amount = FND_API.G_TRUE) THEN
      validate_insert_adjustment( p_adj_rec.amount,
                               p_adj_rec.payment_schedule_id,
                               p_adj_rec.type );
   END IF;
   END IF;
   
   IF p_adj_rec.status = 'A'
     THEN 
	  -- ------------------------------------------------------------------
	  -- This is to make arp_ps_util.update_adj_related_columns work OK
          -- CB means that we are adjusting chargeback amount to applied 
          -- transaction.
          -- This does not work the same way as normal invoice adjustment 
          -- because normal invoice adjustment assumes that the whole 
          -- full amount of amount due remaining is adjusted.
          -- Chargeback can be done to be less or equal to amount due remaining.
	  -- ------------------------------------------------------------------

          IF (p_adj_rec.type = 'CB')
          THEN
	    /* VAT changes */
            arp_ps_util.update_adj_related_columns(
					null,
					p_adj_rec.type,
					p_adj_rec.amount,
 					null,
					p_adj_rec.line_adjusted,
					p_adj_rec.tax_adjusted,
					p_adj_rec.freight_adjusted,
					p_adj_rec.receivables_charges_adjusted,
					p_adj_rec.apply_date,
					p_adj_rec.gl_date,
					l_acctd_amount,
                                        l_ps_rec);

	   -- ----------------------------------------------------------------
	   -- Change this back to INVOICE for standard way of treating this
	   -- adjustment.
 	   -- ----------------------------------------------------------------
           l_ae_doc_rec.other_flag    := 'CHARGEBACK';
           l_ae_doc_rec.source_id_old := p_adj_rec.code_combination_id;
	   p_adj_rec.type := 'INVOICE';

         ELSE
            arp_util.debug( 'before update_adj_related_adjustment');
            arp_util.debug( 'line adjusted = ' || p_adj_rec.line_adjusted);
            arp_util.debug( 'tax adjusted = ' || p_adj_rec.tax_adjusted);
            arp_util.debug( 'freight adjusted = ' || p_adj_rec.freight_adjusted);

          /*-------------------------------------------------------------+
           | If the flag p_check_amount has the value of 'F' ie it is    |
           | an adjustment reversal, then adjustment_type is set to      |
           | 'REVERSE' so that the values for line_adjusted, tax_adjusted|
           | freight_adjusted and amount_adjusted are not calculated in  |
           | arp_ps_util.update_adj_related_columns procedure.           |
           +-------------------------------------------------------------*/ 
          /*-------------------------------------------------------------+
           | Bug 1290698 - For partial adjustment, p_check_amount is 'F'.|
           | So set the type = 'REVERSE' only when it is actual reversal |  
           +-------------------------------------------------------------*/
            --Modified to call Accounting Engine in reverse mode while 
            --creating reverse adjustment with old_adjustment_id
  
            IF (p_check_amount = FND_API.G_FALSE) 
                and p_adj_rec.created_from = 'REVERSE_ADJUSTMENT' THEN
               l_adj_type := 'REVERSE';
               l_ae_doc_rec.source_id_old := p_old_adjust_id;
               l_ae_doc_rec.other_flag := 'REVERSE';
              
            ELSE
               l_adj_type := p_adj_rec.type;
            END IF;

          --Bug 1395396.Update PS record only if Amount is not 0
            IF p_adj_rec.amount <> 0 THEN
                
                IF l_adj_type <> 'REVERSE' THEN 
                     arp_ps_util.update_adj_related_columns(
					null,
					l_adj_type,
					p_adj_rec.amount,
 					null,
					p_adj_rec.line_adjusted,
					p_adj_rec.tax_adjusted,
					p_adj_rec.freight_adjusted,
					p_adj_rec.receivables_charges_adjusted,
					p_adj_rec.apply_date,
					p_adj_rec.gl_date,
					l_acctd_amount,
                                        l_ps_rec);
               ELSE
                --Bug 1415964
                --Do not recalculate the acctd amount while reversing
                --Take the amounts from old_adjustment and reverse it
          
                  l_amount_adjusted := NVL(p_adj_rec.line_adjusted, 0 ) +
                              NVL(p_adj_rec.tax_adjusted, 0 ) +
                              NVL(p_adj_rec.freight_adjusted, 0 ) +
                              NVL(p_adj_rec.receivables_charges_adjusted, 0 );  
      
                 --Assign the amounts from old adjustment record 
                
                   l_ps_rec.amount_due_remaining := 
                             l_ps_rec.amount_due_remaining +
                             nvl(l_amount_adjusted,0);
                   l_ps_rec.acctd_amount_due_remaining :=
                             l_ps_rec.acctd_amount_due_remaining + 
                             p_adj_rec.acctd_amount;
                   l_acctd_amount :=  p_adj_rec.acctd_amount; 
    

                -- Add amount adjusted to current amount_adjusted and subtract
    	        -- adjusted amounts from amounts remaining
    
                   l_ps_rec.amount_adjusted := 
                            nvl(l_ps_rec.amount_adjusted, 0) +
                            l_amount_adjusted;

                   IF ( p_adj_rec.line_adjusted IS NOT NULL ) THEN
                      l_ps_rec.amount_line_items_remaining :=
                             NVL(l_ps_rec.amount_line_items_remaining, 0 ) +
                             p_adj_rec.line_adjusted;

                   END IF;
                  
                   IF (p_adj_rec.receivables_charges_adjusted IS NOT NULL) THEN
                       l_ps_rec.receivables_charges_remaining :=
                             NVL(l_ps_rec.receivables_charges_remaining, 0 ) +
                             p_adj_rec.receivables_charges_adjusted;

                  END IF;
    
                  IF ( p_adj_rec.tax_adjusted IS NOT NULL ) THEN
                       l_ps_rec.tax_remaining := 
                            NVL( l_ps_rec.tax_remaining, 0 ) +
                            p_adj_rec.tax_adjusted;

                  END IF;
    
                  IF ( p_adj_rec.freight_adjusted IS NOT NULL ) THEN
                       l_ps_rec.freight_remaining := 
                             NVL( l_ps_rec.freight_remaining, 0 ) +
                             p_adj_rec.freight_adjusted;
                                  
                  END IF;
               
                  arp_ps_util.populate_closed_dates(p_adj_rec.gl_date, 
                                 p_adj_rec.apply_date, 'ADJ', l_ps_rec );
                  arp_ps_pkg.update_p(l_ps_rec );
        
              END IF; -- Close for Reverse block
                   
            END IF;
        END IF;

     ELSE 
           --update ar_payment_schedules.amount_adjusted_pending
           --Bug 1395396.Update PS record only if Amount is not 0

       IF p_adj_rec.amount <> 0 THEN

	  /*3869570 Replaced p_adj_rec.apply_date and 
	   p_adj_rec.gl_Date with l_ps_rec.actual_date_closed and
	   l_ps_rec.gl_date_closed*/
          arp_ps_util.update_adj_related_columns(
					null,
					null,
					null,
					p_adj_rec.amount,
					p_adj_rec.line_adjusted,
					p_adj_rec.tax_adjusted,
					p_adj_rec.freight_adjusted,
					p_adj_rec.receivables_charges_adjusted,
					l_ps_rec.actual_date_closed,
					l_ps_rec.gl_date_closed,
					l_acctd_amount,
                                        l_ps_rec);
              
           -- We store ADR (amount due remaining) values to temporary
           -- variables, because we do not update transaction payment
           -- schedule when adjustment is not approved.

	   arp_util.calc_acctd_amount( 
		  NULL
		, NULL
		, NULL
            	, NVL(l_ps_rec.exchange_rate,1)	       -- Exchange rate
            	, '+'          	-- amount_applied must be added to ADR 
            	, l_ps_rec.amount_due_remaining	       -- Current ADR
            	, l_ps_rec.acctd_amount_due_remaining  -- Current Acctd. ADR
            	, p_adj_rec.amount                     -- Amount adjusted
            	, ln_adr_tmp			       -- New ADR (OUT)
            	, ln_acctd_adr_tmp		       -- New Acctd. ADR (OUT)
            	, l_acctd_amount);                     -- Acct. amount adjusted
						       -- (OUT)
       END IF;
   END IF;

   p_adj_rec.acctd_amount := l_acctd_amount;

   --Bug 1620930 Add the folowing conditions for commitment adjustment
     IF (p_adj_rec.receivables_trx_id = -1) THEN
       p_adj_rec.adjustment_type   := 'C';
     END IF;

   -- if a line level adjustment, then we want to tag the created_From
   -- for later use.

   IF (p_app_level = 'LINE') THEN
       p_adj_rec.created_from := 'ARXRWLLC';
   END IF;

   /*----------------------+
    |  call table-handler  |
    +----------------------*/
   arp_adjustments_pkg.insert_p(p_adj_rec, 
                        l_ps_rec.exchange_rate,
                        p_adjustment_number, 
                        l_adjustment_id);

   /* 4544013 - Call etax routine to prorate line and
      tax for recoverable tax transactions.  Note that 
      this routine will only change the line_adjusted
      and tax_adjusted columns.  It will not affect
      the overall adj amount or trx balance.

      Passing a 'Y' for p_upd_adj_and_ps causes
      the proration code to update the adjustment
      and target payment schedule with the new
      prorated amounts (overriding what was
      passed in or written in the original PS insert */

      --================== For LLCA adjustment, inserting into Activity Details Table =================
	IF p_app_level = 'LINE' 
	THEN

	 SELECT ar_activity_details_s.nextval
	    INTO l_line_id
	    FROM dual;

	 SELECT 
		LINE_ADJUSTED,                                                                          
		TAX_ADJUSTED
	 INTO
		l_line_adjusted,
		l_tax_adjusted
	 FROM 	ar_adjustments
	 WHERE 	adjustment_id = l_adjustment_id;

	INSERT INTO AR_ACTIVITY_DETAILS (
		LINE_ID,
		APPLY_TO,
		customer_trx_line_id,
		CASH_RECEIPT_ID,
		GROUP_ID,
		AMOUNT,
		TAX,
		CREATED_BY,
		CREATION_DATE,
		LAST_UPDATE_LOGIN,
		LAST_UPDATE_DATE,
		LAST_UPDATED_BY,
		OBJECT_VERSION_NUMBER,
		CREATED_BY_MODULE,
		SOURCE_ID,
		SOURCE_TABLE,
		CURRENT_ACTIVITY_FLAG
	    )

	    VALUES (
		l_line_id,                         -- line_id
		1,                                 -- APPLY_TO
		p_adj_rec.customer_trx_line_id,    -- customer_Trx_line_id
		NULL,                              -- cash_Receipt_id
		NULL,                              -- Group_ID (ll grp adj not implem)
		l_line_adjusted,                   -- Amount
		l_tax_adjusted,                    -- TAX 
		NVL(FND_GLOBAL.user_id,-1),        -- Created_by
		SYSDATE,                           -- Creation_date
		decode(FND_GLOBAL.conc_login_id,
		       null,FND_GLOBAL.login_id,
		       -1, FND_GLOBAL.login_id,
		       FND_GLOBAL.conc_login_id),  -- Last_update_login
		SYSDATE,                           -- Last_update_date
		NVL(FND_GLOBAL.user_id,-1),        -- last_updated_by
		0,                                 -- object_version_number
		'ARXTWADJ',                        -- created_by_module
		l_adjustment_id,                   -- source_id
		'ADJ',                             -- source_table
                'Y'                                -- Application record status 
		   );

	END IF;

      --================== For LLCA adjustment, inserting into Activity Details Table =================
  
   IF p_adj_rec.type in ('INVOICE','LINE','TAX','CHARGES') AND
      p_adj_rec.status = 'A'
   THEN

      /* Set mode */
      IF p_adj_rec.type = 'INVOICE'
      THEN
         l_mode := 'INV';
      ELSIF p_adj_rec.type = 'CHARGES'
      THEN
         l_mode := 'LINE';
      ELSE
         l_mode := p_adj_rec.type;
      END IF;

     arp_util.debug(' cust trx line id = ' || p_adj_rec.customer_trx_line_id);

     IF (p_app_level = 'LINE') THEN
      XX_ARP_ETAX_UTIL.prorate_recoverable(
              p_adj_id         => l_adjustment_id,
              p_target_id      => p_adj_rec.customer_trx_id,
              p_target_line_id => p_adj_rec.customer_trx_line_id,
              p_amount         => p_adj_rec.amount - nvl(p_adj_rec.freight_adjusted,0) - nvl(p_adj_rec.receivables_charges_adjusted,0),
              p_apply_date     => p_adj_rec.apply_date,
              p_mode           => l_mode,
              p_upd_adj_and_ps => 'Y',
              p_gt_id          => l_gt_id,
              p_prorated_line  => l_line_amt,
              p_prorated_tax   => l_tax_amt);

     ELSE
      XX_ARP_ETAX_UTIL.prorate_recoverable(
              p_adj_id         => l_adjustment_id,
              p_target_id      => p_adj_rec.customer_trx_id,
              p_target_line_id => NULL,
              p_amount         => p_adj_rec.amount - nvl(p_adj_rec.freight_adjusted,0) - nvl(p_adj_rec.receivables_charges_adjusted,0),
              p_apply_date     => p_adj_rec.apply_date,
              p_mode           => l_mode,
              p_upd_adj_and_ps => 'Y',
              p_gt_id          => l_gt_id,
              p_prorated_line  => l_line_amt,
              p_prorated_tax   => l_tax_amt);
      END IF;

      /* If the rec_activity is not recoverable, this routine
         just returns as-is.  Since we requested that the
         routine update the adj and ps rows, the returned
         prorated amounts can be ignored from this point
         on. */

      /* display results in debug log */
      arp_util.debug('After return from XX_ARP_ETAX_UTIL.prorate_recoverable');
      arp_util.debug('   l_gt_id    = ' || l_gt_id);
      arp_util.debug('   l_line_amt = ' || l_line_amt);
      arp_util.debug('   l_tax_amt  = ' || l_tax_amt);

      IF NVL(l_gt_id,0) <> 0
      THEN
        l_from_llca_call := 'Y';
      ELSE
        l_from_llca_call := 'N';
        l_gt_id := NULL;
      END IF;  
 
   END IF;

/*Moved the query for getting the accounting flag here, as we need accounting flag to decide whether to call create events or not.
  Refer Bug7299812 for details. - vavenugo */

/*--------------------------------------------+
    |  Get the value for accounting_affect_flag  |
    +--------------------------------------------*/

      SELECT NVL(accounting_affect_flag, 'Y')
      INTO  l_accounting_affect_flag
      FROM  ar_receivables_trx
      WHERE receivables_trx_id = p_adj_rec.receivables_trx_id;


   --BUG#2750340
   /*------------------------------------------+
    | Need to call XLA engine to create the    |
    | ADJ_CREATE event because it can be not   |
    | approved in which case no accounting are |
    | created.                                 |
    +------------------------------------------*/
   l_xla_ev_rec.xla_from_doc_id := l_adjustment_id;
   l_xla_ev_rec.xla_to_doc_id   := l_adjustment_id;
   l_xla_ev_rec.xla_doc_table   := 'ADJ';
   l_xla_ev_rec.xla_mode        := 'O';
   l_xla_ev_rec.xla_call        := 'B';

   
   IF (l_accounting_affect_flag <> 'N') THEN
      ARP_XLA_EVENTS.create_events(p_xla_ev_rec => l_xla_ev_rec);
   END IF;

   /*End Bug7299812 */

   p_adjustment_id := l_adjustment_id;

   --apandit
   IF l_app_ps_status <> l_ps_rec.status THEN
     l_app_ps_status := l_ps_rec.status;
   ELSE
     l_app_ps_status := 'NO_CHANGE';
   END IF;
   --Bug 2641517 raise business event   
   AR_BUS_EVENT_COVER.Raise_Adj_Create_Event(l_adjustment_id,
                                             l_app_ps_status,
                                             p_adj_rec.status );


   /*-----------------------------------------------------------------------+
    | VAT changes: create acct entry                                        |
    | Bug 916659: Create accounting only if adjustment is approved          |
    | Change made for BR/BOE project. Accounting is created only if the     |
    | accounting_affect_flag for the receivable_trx_id is not 'N'           |
    +-----------------------------------------------------------------------*/ 
           
   IF (p_adj_rec.status = 'A'  and l_accounting_affect_flag <> 'N') 
   THEN

     --{BUG 2365805:
     -- old code :l_ae_doc_rec.document_type := 'ADJUSTMENT';
     IF p_adj_rec.Type = 'CHARGES' THEN
        l_ae_doc_rec.document_type := 'FINANCE_CHARGES'; 
     ELSE 
        l_ae_doc_rec.document_type := 'ADJUSTMENT';
     END IF;
     --}
     l_ae_doc_rec.document_id   := l_adjustment_id;
     l_ae_doc_rec.accounting_entity_level := 'ONE';
     l_ae_doc_rec.source_table  := 'ADJ';
     l_ae_doc_rec.source_id     := l_adjustment_id;
     l_ae_doc_rec.deferred_tax  := p_move_deferred_tax;
     
     --Bug 1329091 - PS is updated before Accounting Engine Call
     
     l_ae_doc_rec.pay_sched_upd_yn := 'Y';

    --Added a new parameter p_called_from for BR
     
     l_ae_doc_rec.event := p_called_from;

     /* Bug 1686556: The changed adjustment account is now reflected 
     in the distributions also */


     IF Nvl(p_override_flag,'N') = 'Y' and 
        p_adj_rec.code_combination_id is NOT NULL
      THEN
       l_ae_doc_rec.other_flag    := 'OVERRIDE';
       l_ae_doc_rec.source_id_old := p_adj_rec.code_combination_id;
     END IF;
     
 
   --Bug 1620930 Add the folowing conditions for commitment adjustment
     IF (p_adj_rec.receivables_trx_id = -1) THEN
       l_ae_doc_rec.other_flag    := 'COMMITMENT';
       l_ae_doc_rec.source_id_old := p_adj_rec.code_combination_id;
     END IF;

     IF (l_from_llca_call = 'N' and p_app_level = 'LINE') THEN
         -- we have line level app with non-recoverable tax
         -- we need to populate the gt table before calling the 
         -- the accting engine.
     
         arp_llca_adjust_pkg.LLCA_Adjustments(
                  p_customer_trx_line_id => p_adj_rec.customer_trx_line_id,
                  p_customer_trx_id      => p_adj_rec.customer_trx_id,
                  p_line_adjusted        => p_adj_rec.line_adjusted,
                  p_tax_adjusted         => p_adj_rec.tax_adjusted,
                  p_adj_id               => l_adjustment_id,
                  p_inv_currency_code    => l_ps_rec.invoice_currency_code,
                  p_gt_id                =>  l_gt_id_temp );

         l_gt_id := l_gt_id_temp;
         l_from_llca_call := 'Y';

     END IF;
     
     arp_util.debug('Before Calling arp_acct_main.Create_Acct_Entry');
     arp_util.debug('l_gt_id    = ' || l_gt_id);
     arp_util.debug('l_from_llca_call = '||l_from_llca_call);

     arp_acct_main.Create_Acct_Entry(p_ae_doc_rec     => l_ae_doc_rec,
                                     p_from_llca_call => l_from_llca_call,
                                     p_gt_id          => l_gt_id);
   END IF;

   /*---------------------+
    |  post-insert logic  |
    +---------------------*/
         begin
         select * into l_customer_trx from ra_customer_trx
         where customer_trx_id= p_adj_rec.customer_trx_id;
         exception
         when others then 
          null;
         end;
      IF p_adj_rec.customer_trx_line_id is not null or l_customer_trx.upgrade_method = 'R12' then
         ARP_DET_DIST_PKG.re_calcul_rem_amt(l_customer_trx);
      END IF;

   IF p_adj_rec.status <> 'A'
   THEN 
       -- insert row into ar_approval_action_history

       l_aah_rec.action_name   := p_adj_rec.status;
       l_aah_rec.adjustment_id := l_adjustment_id;
       l_aah_rec.action_date   := trunc(sysdate);
       l_aah_rec.comments      := p_adj_rec.comments;

       arp_aah_pkg.insert_p(l_aah_rec,
                            l_approval_action_history_id);

   END IF;

   arp_util.debug('ar_process_adjustment.insert_adjustment()-');

EXCEPTION
    WHEN OTHERS THEN
     FND_MESSAGE.set_name( 'AR', 'GENERIC_MESSAGE' );
     FND_MESSAGE.set_token( 'GENERIC_TEXT', 'XX_ARP_PROCESS_ADJUSTMENT.insert_adjustment exception: '||SQLERRM );
     arp_util.debug(
           'EXCEPTION: ar_process_adjustment.insert_adjustment()');
     RAISE;

END;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    update_adjustment							     |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Updates a record in ar_adjustments                                     |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:							     |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |     Adjustment amount cannot be updated in Rel 10.  This procedure        |
 |     assumes that adjustment amount will never be updated.                 |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     06-SEP-95  Martin Johnson      Created                                |
 |     26-MAR-96  Martin Johnson      BugNo:352255.  Fixed so that           |
 |                                    l_old_adj_rec is always fetched.       |
 |     9/18/1996  Harri Kaukovuo      Fixed the procedure to recalculate     |
 |				      accounted adjust amount when adjustment|
 |				      is approved. Bug fix 403019.           |
 |     03-FEB-00  Saloni Shah         Changes made for the BR/BOE project.   |
 |                                    The accounting enteries will be created|
 |                                    only if the status is 'A' and the      |
 |                                    accounting_affect_flag for the         |
 |                                    receivables_Trx_id is not set to 'N'   |
 |     17-May-00     Satheesh Nambiar Added p_move_deferred_tax for BOE/BR.  |
 |                                    The new parameter is used to detect    |
 |                                    whether the deferred tax is moved as   |
 |                                    part of maturity_date event or as a    |
 |                                    part of activity on the BR(Bug 1290698)|
 |     13-Jun-00     Satheesh Nambiar Bug 1329091- Passing one more parameter|
 |                                    to accounting engine to acknowledge PS |
 |                                    updated.                               |
 |     05-Jun-02     Rahna Kader      Bug 2377672: While updating an         | 
 | 		                      adjustment reversal, the accounting    |
 | 			              entries should not be re-created       |
 +===========================================================================*/

PROCEDURE update_adjustment(
  p_form_name           IN varchar2,
  p_form_version        IN varchar2,
  p_adj_rec             IN ar_adjustments%rowtype,
  p_move_deferred_tax   IN varchar2 := 'Y',
  p_adjustment_id       IN ar_adjustments.adjustment_id%type)

IS

   l_adj_rec                      ar_adjustments%rowtype;
   l_aah_rec                      ar_approval_action_history%rowtype;
   l_ps_rec                       ar_payment_schedules%rowtype;
   l_approval_action_history_id 
     ar_approval_action_history.approval_action_history_id%type;
   l_status_changed_flag          boolean;
   l_old_adj_rec                  ar_adjustments%rowtype;
   l_acctd_amount_adjusted        ar_adjustments.acctd_amount%type;
   l_ae_doc_rec         	  ae_doc_rec_type;
   l_accounting_affect_flag ar_receivables_trx.accounting_affect_flag%type;
   /* Bug fix 2377672
      variables to decide whether the accounting  needs to be re-created */
   l_recreate_accounting          boolean;
   l_accounts                     number;
   --apandit
   l_app_ps_status    VARCHAR2(20);
   l_gt_id_temp       NUMBER := 0;

   l_amount_adjusted_pending   NUMBER; /*3590046 */

--BUG#2750340
   l_xla_ev_rec   arp_xla_events.xla_events_type;

/* 6888581 */
l_event_source_info   xla_events_pub_pkg.t_event_source_info;
l_event_id            NUMBER;
l_security            xla_events_pub_pkg.t_security;
l_adj_post_to_gl	ra_cust_trx_types.adj_post_to_gl%TYPE := 'Y' ;
/* Added local variables to be used in Update_Adjustment procedure, manishri, Bug 9708599 */
l_mode			VARCHAR2(20);
l_gt_id			NUMBER := 0;
l_line_amt              NUMBER;
l_tax_amt		NUMBER;
l_from_llca_call        VARCHAR2(1) := 'N';
/* End of change, manishri, Bug 9708599 */
l_line_adjusted         NUMBER;
l_tax_adjusted          NUMBER;

BEGIN
   arp_util.debug('ar_process_adjustment.update_adjustment()+',
                  pg_msg_level_debug);

  /*----------------------------------------------------------------+
   |  check form version to determine if it is compatible with the  |
   |  entity handler.                                               |
   +----------------------------------------------------------------*/

   arp_trx_validate.ar_entity_version_check(p_form_name, p_form_version);


  /*-------------------------------------------------------------------+
   |  If the adjustment record parameter does not have all the columns |
   |  filled in, the procedure will not work. In this case,            |
   |  fetch the adjustment record from the database and construct a    |
   |  new record that consists of the unchanged columns from the old   |
   |  records and the changed columns from the record passed in as a   |
   |  parameter.                                                       |
   +-------------------------------------------------------------------*/

   arp_adjustments_pkg.fetch_p( l_old_adj_rec,
                                p_adjustment_id );

   IF (p_adj_rec.type = arp_adjustments_pkg.get_text_dummy )
   THEN

        arp_adjustments_pkg.merge_adj_recs( l_old_adj_rec,
                                    p_adj_rec,
                                    l_adj_rec );
   ELSE 
        l_adj_rec := p_adj_rec;
   END IF;


  /*-----------------------------------------------------------------+
   |  Lock rows in other tables that reference this customer_trx_id  |
   +-----------------------------------------------------------------*/

   arp_trx_util.lock_transaction(l_adj_rec.customer_trx_id); 

   /*-----------------------------------+
    |  Get the payment schedule record  |
    +-----------------------------------*/

   arp_ps_pkg.fetch_p(l_adj_rec.payment_schedule_id, l_ps_rec);
   --apandit
   l_app_ps_status := l_ps_rec.status;

   /*--------------------+
    |  pre-update logic  |
    +--------------------*/

   set_flags(p_adjustment_id, 
             l_old_adj_rec,
             l_adj_rec,
             l_status_changed_flag);

   validate_update_adjustment(l_adj_rec.payment_schedule_id,
                              l_adj_rec.amount,
                              l_adj_rec.type,
                              l_status_changed_flag,
                              l_adj_rec.status, 
			      l_adj_rec.tax_adjusted );

/* Added cal to Validate_Update_Approve_Adj while approving Adjustment, manishri, Bug 9708599 */
   IF (l_adj_rec.status IN ('A', 'R') and l_old_adj_rec.status = 'W') THEN
      validate_update_approve_adj( p_adj_rec => l_adj_rec,
                                   p_ps_rec => l_ps_rec,
                                   p_adjustment_code => l_adj_rec.status,
				   p_chk_approval_limits => FND_API.G_TRUE);
   END IF;
/* End of change, manishri, Bug 9708599 */

   arp_util.debug(
     'l_status_changed_flag: ' || 
       arp_trx_util.boolean_to_varchar2(l_status_changed_flag) );

   IF l_status_changed_flag
     THEN 
        IF l_adj_rec.status = 'A'
          THEN 
             arp_ps_util.update_adj_related_columns( 
                  null,				-- payment_schedule_id
                  l_adj_rec.type,		-- p_type
                  l_adj_rec.amount,		-- p_amount_adjusted
                  l_adj_rec.amount * -1,	-- p_amount_adjusted_pending
                  l_adj_rec.line_adjusted,	-- p_line_adjusted
                  l_adj_rec.tax_adjusted,	-- p_tax_adjusted
                  l_adj_rec.freight_adjusted,	-- p_freight_adjusted
                  l_adj_rec.receivables_charges_adjusted,
                  l_adj_rec.apply_date,		-- p_apply_date
                  l_adj_rec.gl_date,		-- p_gl_date
                  l_acctd_amount_adjusted,	-- p_acctd_amount_adjusted
                  l_ps_rec );			-- p_ps_rec

           -- Bug fix 403019, to avoid rounding errors. 
           l_adj_rec.acctd_amount := l_acctd_amount_adjusted;

        END IF;  /* IF l_adj_rec.status = 'A */

        -- Bug 568533: need to update payment schedule to remove
        -- adjusted amount pending if Adjustment is rejected.

        IF    ( l_adj_rec.status  = 'R' )
        THEN 

	  /*3869570 Replaced p_adj_rec.apply_date and 
	   p_adj_rec.gl_Date with l_ps_rec.actual_date_closed and
	   l_ps_rec.gl_date_closed*/

           arp_ps_util.update_adj_related_columns( 
                  null,			-- paymenty schedule id
                  l_adj_rec.type,       -- p_type
                  null,                 -- p_amount_adjusted
                  -1 * l_adj_rec.amount,-- p_amount_adjusted_pending
                  l_adj_rec.line_adjusted,
                  l_adj_rec.tax_adjusted,
                  l_adj_rec.freight_adjusted,
                  l_adj_rec.receivables_charges_adjusted,
                  l_ps_rec.actual_date_closed,
                  l_ps_rec.gl_date_closed,
                  l_acctd_amount_adjusted,
                  l_ps_rec );
                        
       END IF;

   END IF;  /* IF l_status_changed_flag */

  /*----------------------+
   |  call table-handler  |
   +----------------------*/

   arp_adjustments_pkg.update_p(l_adj_rec,
                        p_adjustment_id,
                        l_ps_rec.exchange_rate);

--Bug 12959780.
   IF l_adj_rec.created_from = 'ARXRWLLC' THEN
      SELECT 
	     LINE_ADJUSTED,                                                                          
	     TAX_ADJUSTED
      INTO
	     l_line_adjusted,
	     l_tax_adjusted
      FROM   ar_adjustments
      WHERE  adjustment_id = p_adjustment_id;

      UPDATE AR_ACTIVITY_DETAILS 
      SET    AMOUNT = l_line_adjusted,
             TAX = l_tax_adjusted
      WHERE  SOURCE_TABLE = 'ADJ'
        AND  SOURCE_ID    = p_adjustment_id
	AND  customer_trx_line_id = l_adj_rec.customer_trx_line_id;

   END IF;

--Bug 12959780.
--Bug 1277494 Added NVL to selection which was missing
   BEGIN
     SELECT NVL(accounting_affect_flag,'Y')
     INTO  l_accounting_affect_flag
     FROM  ar_receivables_trx
     WHERE receivables_trx_id = l_adj_rec.receivables_trx_id;

   EXCEPTION
     WHEN OTHERS THEN
           l_accounting_affect_flag := 'Y';
   END;

/* Added to execute tax calculation, manishri, Bug 9708599 */
   IF (l_adj_rec.status = 'A' and l_old_adj_rec.status = 'W') THEN

      IF l_adj_rec.type in ('INVOICE','LINE','TAX','CHARGES') THEN

         /* Set mode */
         IF l_adj_rec.type = 'INVOICE' THEN
            l_mode := 'INV';
         ELSIF l_adj_rec.type = 'CHARGES' THEN
            l_mode := 'LINE';
         ELSE
            l_mode := l_adj_rec.type;
         END IF;

         -- Added for Line Level Adjustment
	IF l_adj_rec.created_from = 'ARXRWLLC' THEN

	  XX_ARP_ETAX_UTIL.prorate_recoverable(
              p_adj_id         => p_adjustment_id, 
              p_target_id      => l_adj_rec.customer_trx_id,
              p_target_line_id => l_adj_rec.customer_trx_line_id,
              p_amount         => l_adj_rec.amount - nvl(p_adj_rec.freight_adjusted,0) - nvl(p_adj_rec.receivables_charges_adjusted,0),
              p_apply_date     => l_adj_rec.apply_date,
              p_mode           => l_mode,
              p_upd_adj_and_ps => NULL, -- no maint reqd
              p_gt_id          => l_gt_id,
              p_prorated_line  => l_line_amt,
              p_prorated_tax   => l_tax_amt);
	ELSE

	 XX_ARP_ETAX_UTIL.prorate_recoverable(
              p_adj_id         => p_adjustment_id, 
              p_target_id      => l_adj_rec.customer_trx_id,
              p_target_line_id => NULL,
              p_amount         => l_adj_rec.amount - nvl(p_adj_rec.freight_adjusted,0) - nvl(p_adj_rec.receivables_charges_adjusted,0),
              p_apply_date     => l_adj_rec.apply_date,
              p_mode           => l_mode,
              p_upd_adj_and_ps => NULL, -- no maint reqd
              p_gt_id          => l_gt_id,
              p_prorated_line  => l_line_amt,
              p_prorated_tax   => l_tax_amt);
	END IF;

        /* If the rec_activity is not recoverable, this routine
           just returns as-is.  Since we requested that the
           routine update the adj and ps rows, the returned
           prorated amounts can be ignored from this point
           on. */

        /* display results in debug log */
        arp_util.debug('After return from XX_ARP_ETAX_UTIL.prorate_recoverable');
        arp_util.debug('   l_gt_id    = ' || l_gt_id);
        arp_util.debug('   l_line_amt = ' || l_line_amt);
        arp_util.debug('   l_tax_amt  = ' || l_tax_amt);

        IF l_gt_id <> 0 THEN
           l_from_llca_call := 'Y';

           /* Set adj line and tax amounts before call to
              update PS */
           l_adj_rec.line_adjusted := l_line_amt;
           l_adj_rec.tax_adjusted  := l_tax_amt;
        ELSE
           l_from_llca_call := 'N';
        END IF;

--Bug 12959780.
        IF l_adj_rec.status = 'A'  and l_accounting_affect_flag <> 'N' 
	   AND l_adj_rec.created_from = 'ARXRWLLC' AND l_from_llca_call = 'N' THEN
                arp_llca_adjust_pkg.LLCA_Adjustments(
                  p_customer_trx_line_id => l_adj_rec.customer_trx_line_id,
                  p_customer_trx_id      => l_adj_rec.customer_trx_id,
                  p_line_adjusted        => l_adj_rec.line_adjusted,
                  p_tax_adjusted         => l_adj_rec.tax_adjusted,
                  p_adj_id               => p_adjustment_id,
                  p_inv_currency_code    => l_ps_rec.invoice_currency_code,
                  p_gt_id                =>  l_gt_id_temp );

                l_gt_id := l_gt_id_temp;
                l_from_llca_call := 'Y';

        End If;

      END IF;

   END IF;
/* End of change, manishri, Bug 9708599 */


    /*3321021*/
    /*Gives provision to modify the amount for statuses other than
      Approved/Waiting */
    /*The user can completely change the amount .. hence the amount
      pending to be adjusted needs to be re-calculated*/
    BEGIN
     l_amount_adjusted_pending:=0;
     Select SUM(AMOUNT) into l_amount_adjusted_pending
     FROM ar_adjustments where payment_schedule_id=l_adj_rec.payment_schedule_id
     AND STATUS NOT IN ('A','R','U');
     UPDATE ar_payment_schedules set amount_adjusted_pending=
                DECODE(l_amount_adjusted_pending,0,NULL,l_amount_adjusted_pending)
     WHERE payment_schedule_id=l_adj_rec.payment_schedule_id;
    EXCEPTION
     WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Problem in Amount adjusted pending calculation ' ||
           'EXCEPTION: arp_ps_util.update_adj_related_columns' );
         END IF;
         RAISE;
    END;

/* Bug 7621813: Get Adjustment Post to GL flag */
BEGIN

    Select decode (nvl(ctt.post_to_gl,'N'),'Y', 'Y', nvl(ctt.adj_post_to_gl,'N'))
    into   l_adj_post_to_gl
    from   ra_customer_trx ct,   ra_cust_trx_types ctt
    where  ct.customer_trx_id  = l_adj_rec.customer_trx_id
    and    ct.cust_trx_type_id = ctt.cust_trx_type_id ;

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('l_adj_post_to_gl : '|| l_adj_post_to_gl);
    END IF;

EXCEPTION 
    WHEN OTHERS THEN 

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('Unable to get post to gl flag for adjustment' );
       arp_util.debug('EXCEPTION: arp_ps_util.update_adjustment '|| SQLERRM);
    END IF;
    RAISE;
END;

IF NVL(l_adj_post_to_gl, 'N') = 'Y' THEN
  /* 6888581 */ 
  IF    ( l_adj_rec.status  = 'R' )  THEN
  
  BEGIN 
  
  select /*+ INDEX(xet xla_transaction_entities_N1) */ 
        xet.legal_entity_id legal_entity_id,
        adj.SET_OF_BOOKS_ID set_of_books_id,
        adj.org_id          org_id,
        adj.event_id        event_id,
        xet.entity_code     entity_code,
        adj.adjustment_id   adjustment_id,
        xet.application_id
        into 
        l_event_source_info.legal_entity_id,
        l_event_source_info.ledger_id,
        l_security.security_id_int_1,
        l_event_id ,
        l_event_source_info.entity_type_code,
        l_event_source_info.source_id_int_1,
        l_event_source_info.application_id
        from 
        ar_adjustments adj ,
        xla_transaction_entities_upg  xet 
where   adj.adjustment_id               = p_adjustment_id
        and   adj.adjustment_id         = NVL(xet.source_id_int_1, -99)  	
        and   xet.entity_code           ='ADJUSTMENTS'
        AND   xet.application_id        = 222
        AND   adj.SET_OF_BOOKS_ID       = xet.LEDGER_ID;
        
   xla_events_pub_pkg.update_event
               (p_event_source_info    => l_event_source_info,
                p_event_id             => l_event_id,
                p_event_status_code    => 'N',
                p_valuation_method     => null,
                p_security_context     => l_security);
    EXCEPTION
     WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Unable to get the XLA Entites Data ' ||
           'EXCEPTION: arp_ps_util.update_adjustment' );
         END IF;
         RAISE;
    END;
    
 ELSE
        
   --BUG#2750340
   /*----------------------------------------------+
    | Need to call AR XLA engine for ADJ modified  |
    | not approved without distributions.          |
    +----------------------------------------------*/
   l_xla_ev_rec.xla_from_doc_id := p_adjustment_id;
   l_xla_ev_rec.xla_to_doc_id   := p_adjustment_id;
   l_xla_ev_rec.xla_doc_table   := 'ADJ';
   l_xla_ev_rec.xla_mode        := 'O';
   l_xla_ev_rec.xla_call        := 'B';
   ARP_XLA_EVENTS.create_events(p_xla_ev_rec => l_xla_ev_rec);

  END IF;
  END IF;
   /*-------------------------------------------------------------------+
    | VAT changes: update the accounting by first deleting the old one  |
    | and then creating a new one.                                      |
    | Change for the BR/BOE project has been made.                      | 
    | Accounting is created only if the status is 'A' and the           |
    | accounting_affect_flag of the receivables_Trx is not set to 'N'   |
    +-------------------------------------------------------------------*/

  /*--------------------------------------------+
   |  Change made for BR/BOE project.           |
   |  Get the value for accounting_affect_flag  |
   +--------------------------------------------*/
 /* Moved this code on top. Bug 12959780.
 --Bug 1277494 Added NVL to selection which was missing
   BEGIN
     SELECT NVL(accounting_affect_flag,'Y')
     INTO  l_accounting_affect_flag
     FROM  ar_receivables_trx
     WHERE receivables_trx_id = l_adj_rec.receivables_trx_id;

   EXCEPTION
     WHEN OTHERS THEN
           l_accounting_affect_flag := 'Y';
   END;
*/
   /* Fix for bug 2377672
      If the updated record is an adjustment reversal, the accounting
      entries should not be changed  */
      select count(*)
      into  l_accounts
      from ar_distributions
      where source_id = p_adjustment_id
        and source_table = 'ADJ';
      IF l_adj_rec.receivables_trx_id = -13  AND l_accounts > 0 THEN
        l_recreate_accounting := FALSE;
      ELSE
        l_recreate_accounting := TRUE;
      END IF;

   IF (l_adj_rec.status = 'A'  and l_accounting_affect_flag <> 'N'
                               and l_recreate_accounting) THEN
     l_ae_doc_rec.document_type := 'ADJUSTMENT';
     l_ae_doc_rec.document_id   := p_adjustment_id;
     l_ae_doc_rec.accounting_entity_level := 'ONE';
     l_ae_doc_rec.source_table  := 'ADJ';
     l_ae_doc_rec.source_id     := p_adjustment_id;
     l_ae_doc_rec.deferred_tax  := p_move_deferred_tax;
     /* Bug 916659: For a pending adjustment, there is no accounting,
	so no need to delete */

     --Bug 1329091 - PS is updated before Accounting engine call
     l_ae_doc_rec.pay_sched_upd_yn := 'Y';
 
  /*-------------------------------------------------------------------+
   | Call the accounting engine in delete mode for unposted adjustments|
   | This is necessary as the parent adjustment has changed so a fresh |
   | call is given to the accounting engine to re-create the accounting|
   +-------------------------------------------------------------------*/
/*bug2636927*/
     IF ( l_old_adj_rec.status NOT IN ('M', 'W')
          and l_adj_rec.posting_control_id =-3
          and l_accounts <> 0 --Bug 3483238
        )
     THEN
       arp_acct_main.Delete_Acct_Entry(l_ae_doc_rec);
     END IF; --Bug 1787087

  /*------------------------------------------------------------------+
   | Bug 1787087 : When an adjustment is approved, the newly created  |
   | distributions should always reflect the account from adj record  |
   | and not the defaulted account only if they are not the same.     |
   +------------------------------------------------------------------*/
     arp_standard.debug('l_old_adj_rec.code_combination_id ' || l_old_adj_rec.code_combination_id);
     arp_standard.debug('l_adj_rec.code_combination_id ' || l_adj_rec.code_combination_id);

     IF l_adj_rec.code_combination_id IS NOT NULL THEN
        l_ae_doc_rec.source_id_old := l_adj_rec.code_combination_id;
        l_ae_doc_rec.other_flag    := 'OVERRIDE';
     END IF;

--Bug 12959780.
     arp_acct_main.Create_Acct_Entry(p_ae_doc_rec     => l_ae_doc_rec,
                                     p_from_llca_call => l_from_llca_call,
				     p_gt_id          => l_gt_id);


   END IF;

  /*---------------------+
   |  post-update logic  |
   +---------------------*/

   IF l_status_changed_flag
     THEN 
       -- insert row into ar_approval_action_history

       l_aah_rec.action_name   := l_adj_rec.status;
       l_aah_rec.adjustment_id := p_adjustment_id;
       l_aah_rec.action_date   := trunc(sysdate);
       l_aah_rec.comments      := l_adj_rec.comments;         

       arp_aah_pkg.insert_p(
                         l_aah_rec,
                         l_approval_action_history_id);


        -- Status changed
        IF ( l_adj_rec.status = 'A' AND 
	     l_adj_rec.type in ('TAX', 'LINE', 'CHARGES' ) AND     -- Approved Tax Adjustment?
	     /* VAT changes */
	     nvl(l_adj_rec.tax_adjusted,0) <> 0) 
        THEN
           /* 4544013 - removed call to sync_vendor_f_ct_adj_id. */
           NULL; 
        END IF;

      arp_standard.debug('before call to the business events');

   IF l_app_ps_status <> l_ps_rec.status THEN
     l_app_ps_status := l_ps_rec.status;
   ELSE
     l_app_ps_status := 'NO_CHANGE';
   END IF;
        --apandit
        --Bug 2641517 raise business event for approval
        AR_BUS_EVENT_COVER.Raise_Adj_Approve_Event(p_adjustment_id,
                                                   l_approval_action_history_id,
                                                   l_app_ps_status);
   END IF;

   arp_util.debug('ar_process_adjustment.update_adjustment()-',
                  pg_msg_level_debug);


EXCEPTION
    WHEN OTHERS THEN
     FND_MESSAGE.set_name( 'AR', 'GENERIC_MESSAGE' );
     FND_MESSAGE.set_token( 'GENERIC_TEXT', 'XX_ARP_PROCESS_ADJUSTMENT.update_adjustment exception: '||SQLERRM );
     arp_util.debug(
           'EXCEPTION: ar_process_adjustment.update_adjustment()', 
            pg_msg_level_debug);
     RAISE;

END;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    update_approve_adj                                                     |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Deletes a record from ar_adjustments                                   |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                     p_form_name                                           |
 |                     p_form_version                                        |
 |                     p_adj_rec                                             |
 |                     p_adjustment_code                                     |
 |                     p_adjustment_id                                       |
 |              OUT:                                                         |
 |                     None                                                  |
 |          IN/ OUT:                                                         |
 |                     None                                                  |
 |                                                                           |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     05-SEP-95  Charlie Tomberg      Created                               |
 |     03-FEB-00  Saloni Shah          Changes for the BR/BOE project is made|
 |                                     A new p_chk_approval_limits parameter |
 |                                     is added.                             |
 |     17-May-00     Satheesh Nambiar Added p_move_deferred_tax for BOE/BR.  |
 |                                    The new parameter is used to detect    |
 |                                    whether the deferred tax is moved as   |
 |                                    part of maturity_date event or as a    |
 |                                    part of activity on the BR(Bug 1290698)|
 |     13-Jun-00     Satheesh Nambiar Bug 1329091- Passing one more parameter|
 |                                    to accounting engine to acknowledge PS |
 |                                    updated.                               |
 |                                                                           |
 +===========================================================================*/

PROCEDURE update_approve_adj(p_form_name IN varchar2,
                             p_form_version    IN number,
                             p_adj_rec         IN ar_adjustments%rowtype,
                             p_adjustment_code ar_lookups.lookup_code%type,
                             p_adjustment_id   IN ar_adjustments.adjustment_id%type,
			     p_chk_approval_limits   IN      varchar2, 
			     p_move_deferred_tax     IN      varchar2 := 'Y') IS

   l_ps_rec                       ar_payment_schedules%rowtype;
   l_adj_rec                      ar_adjustments%rowtype;
   l_aah_rec                      ar_approval_action_history%rowtype;
   l_acctd_amount_adjusted        ar_adjustments.acctd_amount%type;

   l_approval_action_history_id 
                    ar_approval_action_history.approval_action_history_id%type;
   l_old_adj_rec                  ar_adjustments%rowtype;
   l_ae_doc_rec         	  ae_doc_rec_type;
   l_accounting_affect_flag       ar_receivables_trx.accounting_affect_flag%type;
   --BUG#2750340
   l_xla_ev_rec   arp_xla_events.xla_events_type;

   /* 4544013 */
   l_gt_id          NUMBER := 0;
   l_line_amt       NUMBER;
   l_tax_amt        NUMBER;
   l_from_llca_call VARCHAR2(1) := 'N';
   l_mode           VARCHAR2(20);

   l_gt_id_temp     NUMBER := 0;
BEGIN

   arp_util.debug('ar_process_adjustment.update_approve_adj()+',
                  pg_msg_level_debug);


  /*-----------------------------------------------------------------+
   |  check form version to determine if it is compatible with the   |
   |  entity handler.                                                |
   +-----------------------------------------------------------------*/

   arp_trx_validate.ar_entity_version_check(p_form_name, p_form_version);


  /*-------------------------------------------------------------------+
   |  If the adjustment record parameter does not have all the columns |
   |  filled in, the procedure will not work. In this case,            |
   |  fetch the adjustment record from the database and construct a    |
   |  new record that consists of the unchanged columns from the old   |
   |  records and the changed columns from the record passed in as a   |
   |  parameter.                                                       |
   +-------------------------------------------------------------------*/

   IF (p_adj_rec.type = arp_adjustments_pkg.get_text_dummy )
   THEN
        arp_adjustments_pkg.fetch_p( l_old_adj_rec,
                             p_adjustment_id );

        arp_adjustments_pkg.merge_adj_recs( l_old_adj_rec,
                                    p_adj_rec,
                                    l_adj_rec );
   ELSE 
        l_adj_rec := p_adj_rec;
   END IF;

  /*-----------------------------------------------------------------+
   |  Lock rows in other tables that reference this customer_trx_id  |
   +-----------------------------------------------------------------*/

   arp_trx_util.lock_transaction(l_adj_rec.customer_trx_id);

   arp_ps_pkg.fetch_p( l_adj_rec.payment_schedule_id,
                       l_ps_rec );

   validate_update_approve_adj( l_adj_rec,
                                l_ps_rec,
                                p_adjustment_code,
				p_chk_approval_limits );


   /* 4544013 - Call etax routine to prorate line and
      tax for recoverable tax transactions.  Note that 
      this routine will only change the line_adjusted
      and tax_adjusted columns.  It will not affect
      the overall adj amount or trx balance.

   */
  
      IF p_adj_rec.type in ('INVOICE','LINE','TAX','CHARGES') AND
         p_adjustment_code in ('A','R')
      THEN

         /* Set mode */
         IF p_adj_rec.type = 'INVOICE'
         THEN
            l_mode := 'INV';
         ELSIF p_adj_rec.type = 'CHARGES'
         THEN
            l_mode := 'LINE';
         ELSE
            l_mode := p_adj_rec.type;
         END IF;

         -- Added for Line Level Adjustment
	IF p_adj_rec.created_from = 'ARXRWLLC' 
	THEN

	  XX_ARP_ETAX_UTIL.prorate_recoverable(
              p_adj_id         => p_adjustment_id, 
              p_target_id      => p_adj_rec.customer_trx_id,
              p_target_line_id => p_adj_rec.customer_trx_line_id,
              p_amount         => p_adj_rec.amount - nvl(p_adj_rec.freight_adjusted,0) - nvl(p_adj_rec.receivables_charges_adjusted,0),
              p_apply_date     => p_adj_rec.apply_date,
              p_mode           => l_mode,
              p_upd_adj_and_ps => NULL, -- no maint reqd
              p_gt_id          => l_gt_id,
              p_prorated_line  => l_line_amt,
              p_prorated_tax   => l_tax_amt);
	ELSE

	 XX_ARP_ETAX_UTIL.prorate_recoverable(
              p_adj_id         => p_adjustment_id, 
              p_target_id      => p_adj_rec.customer_trx_id,
              p_target_line_id => NULL,
              p_amount         => p_adj_rec.amount - nvl(p_adj_rec.freight_adjusted,0) - nvl(p_adj_rec.receivables_charges_adjusted,0),
              p_apply_date     => p_adj_rec.apply_date,
              p_mode           => l_mode,
              p_upd_adj_and_ps => NULL, -- no maint reqd
              p_gt_id          => l_gt_id,
              p_prorated_line  => l_line_amt,
              p_prorated_tax   => l_tax_amt);
	END IF;

        /* If the rec_activity is not recoverable, this routine
           just returns as-is.  Since we requested that the
           routine update the adj and ps rows, the returned
           prorated amounts can be ignored from this point
           on. */

        /* display results in debug log */
        arp_util.debug('After return from XX_ARP_ETAX_UTIL.prorate_recoverable');
        arp_util.debug('   l_gt_id    = ' || l_gt_id);
        arp_util.debug('   l_line_amt = ' || l_line_amt);
        arp_util.debug('   l_tax_amt  = ' || l_tax_amt);

        IF l_gt_id <> 0
        THEN
           l_from_llca_call := 'Y';

           /* Set adj line and tax amounts before call to
              update PS */
           l_adj_rec.line_adjusted := l_line_amt;
           l_adj_rec.tax_adjusted  := l_tax_amt;
        ELSE
           l_from_llca_call := 'N';
        END IF;

       END IF;

  /*---------------------------------+
   |   update ar_payment_schedules   |
   +---------------------------------*/

   IF    ( p_adjustment_code = 'A' )
   THEN  

         arp_ps_util.update_adj_related_columns( 
                                             null,
                                             l_adj_rec.type,
                                             l_adj_rec.amount,
                                             l_adj_rec.amount * -1,
                                             l_adj_rec.line_adjusted,
                                             l_adj_rec.tax_adjusted,
                                             l_adj_rec.freight_adjusted,
                                       l_adj_rec.receivables_charges_adjusted,
                                             l_adj_rec.apply_date,
                                             l_adj_rec.gl_date,
                                             l_acctd_amount_adjusted,
                                             l_ps_rec );

   END IF;

   IF    ( p_adjustment_code  = 'R' )
   THEN 
	  /*3869570 Replaced p_adj_rec.apply_date and 
	   p_adj_rec.gl_Date with l_ps_rec.actual_date_closed and
	   l_ps_rec.gl_date_closed*/
         arp_ps_util.update_adj_related_columns( 
                                             null,
                                             l_adj_rec.type,
                                             null,
                                             -1 * 
                                              l_ps_rec.amount_adjusted_pending,
                                             l_adj_rec.line_adjusted,
                                             l_adj_rec.tax_adjusted,
                                             l_adj_rec.freight_adjusted,
                                       l_adj_rec.receivables_charges_adjusted,
                                             l_ps_rec.actual_date_closed,
                                             l_ps_rec.gl_date_closed,
                                             l_acctd_amount_adjusted,
                                             l_ps_rec );
                        
   END IF;

   l_adj_rec.status := NVL( p_adjustment_code, l_adj_rec.status );

  /*--------------------------+
   |  Update ar_adjustments   |
   +--------------------------*/

   arp_adjustments_pkg.update_p( l_adj_rec,
                         p_adjustment_id,
                         l_ps_rec.exchange_rate );

  --BUG#2750340
  /*------------------------------------------------+
   | Need to call AR XLA event because a ADJ can be |
   | updated without touching its accounting        |
   +------------------------------------------------*/
  l_xla_ev_rec.xla_from_doc_id := p_adjustment_id;
  l_xla_ev_rec.xla_to_doc_id   := p_adjustment_id;
  l_xla_ev_rec.xla_doc_table   := 'ADJ';
  l_xla_ev_rec.xla_mode        := 'O';
  l_xla_ev_rec.xla_call        := 'B';
  ARP_XLA_EVENTS.create_events(p_xla_ev_rec => l_xla_ev_rec);

  /*-------------------------------------------------------------------+
   | Change for the BR/BOE project has been made.                      |
   | Accounting is created only if the status is 'A' and the           |
   | accounting_affect_flag of the receivables_Trx is not set to 'N'   |
   +-------------------------------------------------------------------*/

  /*--------------------------------------------+
   |  Change made for BR/BOE project.           |
   |  Get the value for accounting_affect_flag  |
   +--------------------------------------------*/

  /*-------------------------------------------------------------------+
   |  Bug 1277494 Added NVL to selection which was missing             |
   |  and Call Accounting Engine if accounting affect flag is not 'N'  |
   +------------------------------------------------------------------+*/
   BEGIN
    SELECT NVL(accounting_affect_flag,'Y')
    INTO  l_accounting_affect_flag
    FROM  ar_receivables_trx
    WHERE receivables_trx_id = l_adj_rec.receivables_trx_id;

   EXCEPTION
    WHEN OTHERS THEN
          l_accounting_affect_flag := 'Y';
   END;

   --  need to do some stuff for LLCA
   IF (l_adj_rec.created_from = 'ARXRWLLC' and l_gt_id = 0) THEN
       -- we have line level app with non-recoverable tax
       -- we need to populate the gt table before calling the
       -- the accting engine.

       arp_llca_adjust_pkg.LLCA_Adjustments(
               p_customer_trx_line_id => l_adj_rec.customer_trx_line_id,
               p_customer_trx_id      => l_adj_rec.customer_trx_id,
               p_line_adjusted        => l_adj_rec.line_adjusted,
               p_tax_adjusted         => l_adj_rec.tax_adjusted,
               p_adj_id               => p_adjustment_id,
               p_inv_currency_code    => l_ps_rec.invoice_currency_code,
               p_gt_id                => l_gt_id_temp );

         l_gt_id := l_gt_id_temp;
         l_from_llca_call := 'Y'; 
   END IF;

   IF (l_adj_rec.status = 'A'  and l_accounting_affect_flag <> 'N') THEN
    l_ae_doc_rec.document_type := 'ADJUSTMENT';
    l_ae_doc_rec.document_id   := p_adjustment_id;
    l_ae_doc_rec.accounting_entity_level := 'ONE';
    l_ae_doc_rec.source_table  := 'ADJ';
    l_ae_doc_rec.source_id     := p_adjustment_id;
    l_ae_doc_rec.deferred_tax  := p_move_deferred_tax;

    --Bug 1329091 - PS is updated before Accounting Engine Call
    l_ae_doc_rec.pay_sched_upd_yn := 'Y';

    /*---------------------------+
     | Call Accounting Engine    |
     +---------------------------*/ 

    arp_acct_main.Create_Acct_Entry(p_ae_doc_rec     => l_ae_doc_rec,
                                    p_from_llca_call => l_from_llca_call,
                                    p_gt_id          => l_gt_id);

   END IF;

  /*-------------------------------------------+
   |  Insert into ar_approval_action_history   |
   +-------------------------------------------*/

   l_aah_rec.action_name    := l_adj_rec.status;
   l_aah_rec.adjustment_id  := p_adjustment_id;
   l_aah_rec.action_date    := TRUNC( sysdate );
   l_aah_rec.comments       := l_adj_rec.comments;

   arp_aah_pkg.insert_p(
                         l_aah_rec,
                         l_approval_action_history_id 
                       );
   
   arp_util.debug('ar_process_adjustment.update_approve_adj()-',
                  pg_msg_level_debug); 


EXCEPTION
    WHEN OTHERS THEN
     arp_util.debug(
           'EXCEPTION: ar_process_adjustment.update_approve_adj()', 
            pg_msg_level_debug);
     FND_MESSAGE.set_name( 'AR', 'GENERIC_MESSAGE' );
     FND_MESSAGE.set_token( 'GENERIC_TEXT', 'XX_ARP_PROCESS_ADJUSTMENT.update_approce_adjustment exception: '||SQLERRM );

     arp_util.debug('', pg_msg_level_debug);
     arp_util.debug('---------- parameters for update_approve_adj()' 
                    || '  ---------',
                    pg_msg_level_debug);

     arp_util.debug('p_form_name         = '  || p_form_name );
     arp_util.debug('p_form_version      = '  || p_form_version );
     arp_util.debug('p_adjustment_code   = '  || p_adjustment_code );
     arp_util.debug('p_adjustment_id     = '  || p_adjustment_id );

     arp_adjustments_pkg.display_adj_rec( p_adj_rec );

     RAISE;

END;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    test_adj                                                               |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Verifies that adjustment approvals updates the relevant tables         |
 |    correctly. This procedure should only be called during tests of        |
 |    the update_approve_adj() procedure.                                    |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    None                                                   |
 |              OUT:                                                         |
 |                    None                                                   |
 |         IN / OUT:                                                         |
 |                    p_result                                               |
 |                    p_old_ps_rec                                           |
 |                    p_adj_rec                                              |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     12-SEP-95  Charlie Tomberg      Created                               |
 |                                                                           |
 +===========================================================================*/

PROCEDURE test_adj( p_adj_rec    IN OUT NOCOPY ar_adjustments%rowtype,
                    p_result     IN OUT NOCOPY varchar2,
                    p_old_ps_rec IN OUT NOCOPY ar_payment_schedules%rowtype) IS

  l_new_ps_rec  ar_payment_schedules%rowtype;

BEGIN
   arp_util.debug('test_adj()+');


   /*---------------------------------------------------+
    |  Verify that the adjustment was updated properly  |
    +---------------------------------------------------*/

   p_adj_rec.acctd_amount := 
         arpcurr.functional_amount(
                                   p_adj_rec.amount,
                                   'USD',
                                   p_old_ps_rec.exchange_rate,
                                   2,
                                   null);

   select decode(max(adjustment_id),
                 NULL, 'A: Fail, ',
                     'A: Pass, ')
     into p_result
     from ar_adjustments
    where adjustment_id        = p_adj_rec.adjustment_id
      and adjustment_number    = p_adj_rec.adjustment_number
      and payment_schedule_id  = p_adj_rec.payment_schedule_id
      and customer_trx_id      = p_adj_rec.customer_trx_id 
      and amount               = p_adj_rec.amount
      and (
            (
                 nvl(line_adjusted, 
                     -99.9999)        = decode(p_adj_rec.type,
                                               'LINE', p_adj_rec.amount,
                                                       -99.9999) 
             and nvl(tax_adjusted, 
                     -99.9999)        = decode(p_adj_rec.type,
                                               'TAX', p_adj_rec.amount,
                                                      -99.9999) 
             and nvl(freight_adjusted, 
                     -99.9999)        = decode(p_adj_rec.type,
                                               'FREIGHT', p_adj_rec.amount,
                                                          -99.9999) 
             and nvl(receivables_charges_adjusted , 
                     -99.9999)        = decode(p_adj_rec.type,
                                               'CHARGES', p_adj_rec.amount,
                                                       -99.9999) 
            ) OR
            (
              ( 
                    p_adj_rec.type = 'INVOICE'
                and p_adj_rec.amount = nvl(line_adjusted, 0)     +
                                       nvl(tax_adjusted, 0)      +
                                       nvl(freight_adjusted, 0)  +
                                       nvl(receivables_charges_adjusted, 0)
              )
            )
          )
      and apply_date           = p_adj_rec.apply_date
      and gl_date              = p_adj_rec.gl_date
      and code_combination_id  = p_adj_rec.code_combination_id
      and type                 = p_adj_rec.type 
      and adjustment_type      = p_adj_rec.adjustment_type
      and status               = p_adj_rec.status 
      and nvl(customer_trx_line_id, 
              -999.999)        = NVL(p_adj_rec.customer_trx_line_id, -999.999) 
      and receivables_trx_id   = p_adj_rec.receivables_trx_id
      and created_from         = p_adj_rec.created_from   
          -- check the derived columns 
      and postable             = 'Y' 
      and approved_by          = arp_adjustments_pkg.pg_user_id 
      and nvl(comments, '^%')  = nvl(p_adj_rec.comments, '^%') 
      and acctd_amount         = p_adj_rec.acctd_amount;   

   IF   ( p_result = 'A: Fail, ' )
   THEN
        arp_util.debug('----- database adjustment record -----');
        arp_adjustments_pkg.display_adj_p(p_adj_rec.adjustment_id);
        arp_util.debug('----- parameter adjustment record -----');   
        arp_adjustments_pkg.display_adj_rec(p_adj_rec);
   END IF;


   /*------------------------------------------------------------------+
    |  Verify that a row was inserted into ar_approval_action_history  |
    +------------------------------------------------------------------*/

   select p_result ||
          decode(max(approval_action_history_id),
                 NULL, 'H: Fail, ',
                     'H: Pass, ')
            into p_result
            from ar_approval_action_history
           where adjustment_id = p_adj_rec.adjustment_id
             and action_name   = p_adj_rec.status
             and action_date   = TRUNC(sysdate)
             and nvl(comments, '!@#$%') = nvl(p_adj_rec.comments, '!@#$%');

   /*---------------------------------------------------------+
    |  Verify that the payment schedule was updated properly  |
    +---------------------------------------------------------*/

   arp_ps_pkg.fetch_p(p_adj_rec.payment_schedule_id, l_new_ps_rec);


   select decode( max(dummy),
                  null, p_result || 'P: Fail',
                        p_result || 'P: Pass'
                )
   into   p_result
   from   dual
   where
   (
      (l_new_ps_rec.amount_due_remaining =
       p_old_ps_rec.amount_due_remaining + p_adj_rec.amount)
      AND 
      (l_new_ps_rec.acctd_amount_due_remaining =
         round(
                (p_old_ps_rec.amount_due_remaining + p_adj_rec.amount)
                * p_old_ps_rec.exchange_rate,
               2
              ) )
      AND 
      ( 
        (
           decode(p_adj_rec.type,
                  'LINE',     l_new_ps_rec.amount_line_items_remaining,
                  'TAX',      l_new_ps_rec.tax_remaining,
                  'FREIGHT',  l_new_ps_rec.freight_remaining,
                  'CHARGES',  l_new_ps_rec.receivables_charges_remaining) =
           decode(p_adj_rec.type,
                  'LINE',     p_old_ps_rec.amount_line_items_remaining,
                  'TAX',      p_old_ps_rec.tax_remaining,
                  'FREIGHT',  p_old_ps_rec.freight_remaining,
                  'CHARGES',  p_old_ps_rec.receivables_charges_remaining) +
           p_adj_rec.amount
        )
        OR
        ( p_adj_rec.type = 'INVOICE')
      )
      AND 
      (l_new_ps_rec.amount_adjusted = 
          (
            nvl(p_old_ps_rec.amount_adjusted, 0) + 
                                         p_adj_rec.amount) )
      AND
      (l_new_ps_rec.amount_due_remaining =
         nvl(l_new_ps_rec.amount_line_items_remaining,0) +
         nvl(l_new_ps_rec.tax_remaining,0) +
         nvl(l_new_ps_rec.freight_remaining,0) +
         nvl(l_new_ps_rec.receivables_charges_remaining,0))
      AND 
      (l_new_ps_rec.amount_due_remaining =
         l_new_ps_rec.amount_due_original
         + nvl(l_new_ps_rec.amount_adjusted,0)
         - nvl(l_new_ps_rec.amount_applied,0)
         + nvl(l_new_ps_rec.amount_credited,0)
         - nvl(l_new_ps_rec.discount_taken_earned,0)
         - nvl(l_new_ps_rec.discount_taken_unearned,0))
      AND 
      ( (l_new_ps_rec.status = 'OP' AND
         l_new_ps_rec.amount_due_remaining <> 0)
        OR
        (l_new_ps_rec.status = 'CL' AND
         l_new_ps_rec.amount_due_remaining = 0))
   );


   arp_util.debug('test_adj()-');

   EXCEPTION
       WHEN OTHERS THEN
            arp_util.debug( 'EXCEPTION: ar_process_adjustment.test_adj()', 
            pg_msg_level_debug);
            RAISE;
 END;


PROCEDURE validate_args_radj( p_adj_id IN ar_adjustments.adjustment_id%TYPE,
                             p_reversal_gl_date IN DATE,
                             p_reversal_date IN DATE );
--
PROCEDURE modify_adj_rec( p_adj_id IN ar_adjustments.adjustment_id%TYPE,
                          p_reversal_gl_date IN DATE,
                          p_reversal_date IN DATE );
--

PROCEDURE val_insert_rev_actions( 
			p_adj_id IN ar_adjustments.adjustment_id%TYPE );
--
/*===========================================================================+
 | PROCEDURE                                                                 |
 |    reverse_adjustment()                                                   |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    This function reverses an adjustment by inserting an opposing entry    |
 |    in the AR_ADJUSTMENTS table                  			     |
 |									     |
 | SCOPE - PUBLIC                                                            |
 |									     |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_aa_history_pkg.insert_p - approval history table insert table      |
 |                                  handler                                  |
 |                                                                           |
 | ARGUMENTS  : IN:                     				     |
 |		   p_adj_id - Id of row to be reversed                       |
 |                 p_reversal_gl_date - Reversal GL date 		     |
 |                 p_reversal_date - Reversal Date			     |
 |                 p_module_name - Name of the module that called this proc. |
 |                 p_module_version - Version of module that called this proc|
 |              OUT:                                                         |
 |                    None                                                   |
 |                                                                           |
 | RETURNS    : NONE                    				     |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY
 | 04/25/95	Ganesh Vaidee	Created
 | 4/18/1996	Harri Kaukovuo	Added RAISE clause to locking block
 |				Added NOWAIT to FOR UPDATE OF ... clause
 |				Removed hard coded comment and replaced it
 |				with message dictionary equivalent.
 +===========================================================================*/
PROCEDURE reverse_adjustment( 
		p_adj_id IN ar_adjustments.adjustment_id%TYPE,
                p_reversal_gl_date IN DATE,
                p_reversal_date IN DATE,
		p_module_name IN VARCHAR2,
		p_module_version IN VARCHAR2 ) IS
l_aah_rec		ar_approval_action_history%ROWTYPE;
l_aah_id		NUMBER;
l_adj_rec		ar_adjustments%ROWTYPE;
l_ps_rec                ar_payment_schedules%rowtype;
--BUG#2750340
l_xla_ev_rec   arp_xla_events.xla_events_type;

/* 7699796 */
l_event_source_info   xla_events_pub_pkg.t_event_source_info;
l_event_id            NUMBER;
l_security            xla_events_pub_pkg.t_security;
l_adj_post_to_gl	ra_cust_trx_types.adj_post_to_gl%TYPE := 'Y' ;

BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug(   'XX_ARP_PROCESS_ADJUSTMENT.reverse_adjustment()+' );
       arp_standard.debug(   'p_adj_id = '||to_char( p_adj_id ) );
    END IF;

    IF 	(p_module_name IS NOT NULL 
	AND p_module_version IS NOT NULL ) 
    THEN
         validate_args_radj( p_adj_id, p_reversal_gl_date, p_reversal_date );
    END IF;

    -- Select from ar_adjustments to update status. This is just a 
    -- simple select statement, so not using a separate function. Also  
    -- note that the WHERE clause is different than the fetch_p procedure
    -- in the table handler. Also locking the table

    -- This block will update all other adjustments than Approved and
    -- Rejected to be Rejected.

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug (  'before update all other adjustments');
    END IF;
    BEGIN
         SELECT *
         INTO   l_adj_rec
         FROM   ar_adjustments adj
         WHERE  adj.adjustment_id = p_adj_id
         AND    adj.status not in ('A', 'R')
         FOR UPDATE of adj.STATUS NOWAIT;

         l_adj_rec.status := 'R';

         arp_adj_pkg.update_p( l_adj_rec );
         
   BEGIN
   
    /* 7699796 */ 

    Select decode (nvl(ctt.post_to_gl,'N'),'Y', 'Y', nvl(ctt.adj_post_to_gl,'N'))
    into   l_adj_post_to_gl
    from   ra_customer_trx ct,   ra_cust_trx_types ctt
    where  ct.customer_trx_id  = l_adj_rec.customer_trx_id
    and    ct.cust_trx_type_id = ctt.cust_trx_type_id ;

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('l_adj_post_to_gl : '|| l_adj_post_to_gl);
    END IF;
    
    EXCEPTION 
    WHEN OTHERS THEN 

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('Unable to get post to gl flag for adjustment' );
       arp_util.debug('EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.reverse_adjustment '|| SQLERRM);
    END IF;
    RAISE;
END;

   
   IF NVL(l_adj_post_to_gl, 'N') = 'Y' THEN
   
      IF    ( l_adj_rec.status  = 'R' )  THEN
   BEGIN 
    
        select xet.legal_entity_id legal_entity_id,
        adj.SET_OF_BOOKS_ID set_of_books_id,
        adj.org_id          org_id,
        adj.event_id        event_id,
        xet.entity_code     entity_code,
        adj.adjustment_id   adjustment_id,
        xet.application_id
        into 
        l_event_source_info.legal_entity_id,
        l_event_source_info.ledger_id,
        l_security.security_id_int_1,
        l_event_id ,
        l_event_source_info.entity_type_code,
        l_event_source_info.source_id_int_1,
        l_event_source_info.application_id
        from 
        ar_adjustments adj ,
        xla_transaction_entities_upg  xet 
where   adj.adjustment_id               = p_adj_id
        and   adj.adjustment_id         = nvl(xet.source_id_int_1,-99)  	
        and   xet.entity_code           ='ADJUSTMENTS'
        AND   xet.application_id        = 222
        AND   adj.SET_OF_BOOKS_ID       = xet.LEDGER_ID;
        
   xla_events_pub_pkg.update_event
               (p_event_source_info    => l_event_source_info,
                p_event_id             => l_event_id,
                p_event_status_code    => 'N',
                p_valuation_method     => null,
                p_security_context     => l_security);
    EXCEPTION
     WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Unable to get the XLA Entites Data ' ||
           'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.reverse_adjustment' );
         END IF;
         RAISE;
    END;
     END IF ;        
 END IF;

         EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 IF PG_DEBUG in ('Y', 'C') THEN
                    arp_standard.debug(   
	           'NO_DATA_FOUND: XX_ARP_PROCESS_ADJUSTMENT.reverse_adjustment' );
                 END IF;

              WHEN OTHERS THEN
                 IF PG_DEBUG in ('Y', 'C') THEN
                    arp_standard.debug(   
		    'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.reverse_adjustment:SELECT' );
                 END IF;
		 RAISE;
    END;

    -- Create a record in AR_APPROVAL_ACTION_HISTORY for the above adj
    -- Get the message from message dict for inserting in comments

    l_aah_rec.action_name 	:= 'R';
    l_aah_rec.adjustment_id 	:= p_adj_id;
    l_aah_rec.action_date 	:= TRUNC( SYSDATE );

    l_aah_rec.comments 		:= 
	    fnd_message.get_string ('AR','AR_ADJ_REVERSED');

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug(  'before insert_p for ar_approval_action_history');
    END IF;
    arp_aa_history_pkg.insert_p( l_aah_rec, l_aah_id );

    -- If status of adj == R, then there is no need to create an opposing
    --  Approved adj. In fact, in this case you dont have to do anything
    --  Otherwise, create an opposing adj with status = A
    --  and amount = (-1)*amount

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug(  'before modify_adj_rec');
    END IF;
    modify_adj_rec( 
	  p_adj_id
	, p_reversal_gl_date
	, p_reversal_date );


    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug(   'XX_ARP_PROCESS_ADJUSTMENT.reverse_adjustment()-' );
    END IF;

    EXCEPTION
      WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_standard.debug(   
		      'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.reverse_adjustment' );
        END IF;
        FND_MESSAGE.set_name( 'AR', 'GENERIC_MESSAGE' );
        FND_MESSAGE.set_token( 'GENERIC_TEXT', 'XX_ARP_PROCESS_ADJUSTMENT.reverse_adjustment exception: '||SQLERRM );

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_standard.debug (  'p_adj_id 		= '|| TO_CHAR(p_adj_id ) );
           arp_standard.debug (  'p_reversal_gl_date = '|| TO_CHAR(p_reversal_gl_date));
           arp_standard.debug (  'p_reversal_date	= '|| TO_CHAR(p_reversal_date));
	   arp_standard.debug (  'p_module_name	= '|| p_module_name);
	   arp_standard.debug (  'p_module_version	= '|| p_module_version);
	END IF;

        RAISE;
END;
--  
/*===========================================================================+
 | PROCEDURE                                                                 |
 |    validate_args_radj                                                     |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Validate inputs to reverse_adjustment procedure                        |
 |									     |
 | SCOPE - PRIVATE                                                           |
 |									     |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED - NONE                            |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                 p_adj_id - Adjustments Record Id                          |
 |                 p_reversal_gl_date - Reversal GL date                     |
 |                 p_reversal_date - Reversal Date                           |
 |              OUT:                                                         |
 |                 None                                                      |
 |                                                                           |
 | RETURNS    : NONE                    				     |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY - Created by Ganesh Vaidee - 04/25/95		     |
 |                                                                           |
 +===========================================================================*/
PROCEDURE validate_args_radj( p_adj_id IN ar_adjustments.adjustment_id%TYPE, 
                             p_reversal_gl_date IN DATE,
                             p_reversal_date IN DATE ) IS
BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug(   'XX_ARP_PROCESS_ADJUSTMENT.validate_args_radj()+' );
    END IF;
    IF ( p_adj_id is NULL OR p_reversal_gl_date is NULL OR 
	 p_reversal_date is NULL ) THEN
         IF PG_DEBUG in ('Y', 'C') THEN
            arp_standard.debug(  ' Null values found in input variable' );
         END IF;
         FND_MESSAGE.set_name ('AR', 'AR_ARGUEMENTS_FAIL' );
         APP_EXCEPTION.raise_exception;
    END IF;
    --
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug(   'XX_ARP_PROCESS_ADJUSTMENT.validate_args_radj()-' );
    END IF;
    EXCEPTION
         WHEN OTHERS THEN
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_standard.debug(   
		      'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.validate_args_radj' );
              END IF;
              RAISE;
END;
--
/*===========================================================================+
 | PROCEDURE                                                                 |
 |    modify_adj_rec                                                         |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Modify Adjustment Record to prepare for reversal                       |
 |									     |
 | SCOPE - PRIVATE                                                           |
 |									     |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED - NONE                            |
 |                                                                           |
 | ARGUMENTS  : IN:                     				     |
 |                 p_adj_id - Adjustments Record Id                          |
 |                 p_reversal_gl_date - Reversal GL date                     |
 |                 p_reversal_date - Reversal Date                           |
 |              OUT:                                                         |
 |		   None                                                      |
 |                                                                           |
 | RETURNS    : NONE                    				     |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY - Created by Ganesh Vaidee - 04/25/95		     |
 |                                                                           |
 +===========================================================================*/
PROCEDURE modify_adj_rec( p_adj_id IN ar_adjustments.adjustment_id%TYPE,
			  p_reversal_gl_date IN DATE,
                          p_reversal_date IN DATE ) IS
l_adj_rec		ar_adjustments%ROWTYPE;
l_rev_gl_date DATE;
l_error_message        VARCHAR2(128);
l_defaulting_rule_used VARCHAR2(100);
l_default_gl_date      DATE;
BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug(   'XX_ARP_PROCESS_ADJUSTMENT.modify_adj_rec()+' );
       arp_standard.debug(   'p_adj_id = '||to_char( p_adj_id ) );
    END IF;

    arp_adj_pkg.fetch_p( p_adj_id, l_adj_rec );

    l_adj_rec.apply_date := p_reversal_date;

    /* bug 3687113 */
    IF  p_reversal_gl_date > l_adj_rec.gl_date THEN
       l_adj_rec.gl_date := p_reversal_gl_date;
    ELSE
       l_rev_gl_date := l_adj_rec.gl_date;
       IF (arp_standard.validate_and_default_gl_date(
                l_rev_gl_date,
                NULL,
                l_rev_gl_date,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                'N',
                NULL,
                arp_global.set_of_books_id,
                222,
                l_default_gl_date,
                l_defaulting_rule_used,
                l_error_message) = TRUE)
       THEN
          l_adj_rec.gl_date := l_default_gl_date;
       END IF;
    END IF;
    arp_standard.debug(' Adjustment Reversal GL Date '|| l_default_gl_date);

    l_adj_rec.amount := -l_adj_rec.amount;
    l_adj_rec.acctd_amount := -l_adj_rec.acctd_amount;
    IF ( l_adj_rec.chargeback_customer_trx_id is NULL ) THEN
         l_adj_rec.receivables_trx_id := -13;
    ELSE
         l_adj_rec.receivables_trx_id := arp_global.G_CB_REV_RT_ID;
    END IF;

    l_adj_rec.line_adjusted := -l_adj_rec.line_adjusted;
    l_adj_rec.freight_adjusted := -l_adj_rec.freight_adjusted;
    l_adj_rec.tax_adjusted := -l_adj_rec.tax_adjusted;
    l_adj_rec.receivables_charges_adjusted := 
				-l_adj_rec.receivables_charges_adjusted;
    l_adj_rec.adjustment_type := 'M';
    l_adj_rec.created_from := 'REVERSE_ADJUSTMENT';

    /* VAT changes: pass old adjustment_id to insert_reverse_actions
       to be in turn passed to accounting library */
    l_adj_rec.adjustment_id := p_adj_id;

    insert_reverse_actions( l_adj_rec, NULL, NULL );

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug(   'XX_ARP_PROCESS_ADJUSTMENT.modify_adj_rec()-' );
    END IF;

    EXCEPTION
         WHEN OTHERS THEN
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_standard.debug(   
		      'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.modify_adj_rec' );
              END IF;
              RAISE;

END;
--
/*===========================================================================+
 | PROCEDURE                                                                 |
 |    insert_reverse_actions                                                 |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    This procedure performs all actions to modify the passed in            |
 |    adjustments record and calls adjustments insert table handler to       |
 |    insert the reversed adjuetments row                                    |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED -                                 |
 |      arp_adj_pkg.insert_p - Insert a row into AR_ADJUSTMENTS table|
 |                                                                           |
 | ARGUMENTS  : IN OUT:                                                      |
 |                  p_adj_rec - Adjustment Record structure                  |
 |                  p_module_name _ Name of module that called this procedure|
 |                  p_module_version - Version of module that called this    |
 |                                     procedure                             |
 |              OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY - Created by Ganesh Vaidee - 04/25/95                |
 | 7/30/1996	Harri Kaukovuo	Fixed the code to fnd_seqnum, because AOL
 |				has changed the data type of the date parameter.
 |				Fixed possible bug cancidate when trying to
 |				select name from ar_receivables_trx into
 |				VARCHAR2(30) field. Name is VARCHAR2(50).
 | 7/30/1996	Harri Kaukovuo	Bug fix 387035
 |10/16/1998    Sushama Borde   Bug fix 741725: Used AOL API get_next_sequence
 |                              instead of get_seq_name.
 +===========================================================================*/
PROCEDURE insert_reverse_actions (
                p_adj_rec               IN OUT NOCOPY ar_adjustments%ROWTYPE,
                p_module_name           IN VARCHAR2,
                p_module_version        IN VARCHAR2 ) IS
l_new_adj_id    ar_adjustments.adjustment_id%TYPE;
l_old_adj_id    ar_adjustments.adjustment_id%TYPE;

l_rec_name      VARCHAR2(50);
l_number         NUMBER;

-- This stuff is for sequence numbering
l_sequence_name            VARCHAR2(500);
l_sequence_id              NUMBER;
l_sequence_value           NUMBER;
l_sequence_assignment_id   NUMBER;
/* VAT changes */
l_ae_doc_rec         	   ae_doc_rec_type;
--BUG#2750340
l_xla_ev_rec   arp_xla_events.xla_events_type;
/* 7699796 */
l_event_source_info   xla_events_pub_pkg.t_event_source_info;
l_event_id            NUMBER;
l_security            xla_events_pub_pkg.t_security;
l_adj_post_to_gl	ra_cust_trx_types.adj_post_to_gl%TYPE := 'Y' ;
l_adj_status      VARCHAR2(1);


BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug(   'XX_ARP_PROCESS_ADJUSTMENT.insert_reverse_actions()+');
    END IF;

    /* VAT changes: save p_adj_rec.adjustment_id in l_old_adj_id
       to be passed to accounting library. Clear p_adj_rec.adjustment_id
       afterwards */
    l_old_adj_id := p_adj_rec.adjustment_id;
    p_adj_rec.adjustment_id := NULL;

    -- -------------------------------------------------------------------
    --  This function could be called from a FORMS or SRW and if so, this
    --  validate args function should be enabled, However at that time we 
    --  should determine what argument to check for
    -- -------------------------------------------------------------------
    IF ( p_adj_rec.status is NULL ) THEN
         p_adj_rec.status := 'A';
    END IF;

    -- Set up sequential numbering stuff

    -- Fix for bug 540964: use p_adj_rec.receivables_trx_id instead of 
    --                     arp_global.G_CB_REV_RT_ID to make sure the
    --			   correct sequence is used for Adjustments

    SELECT rt.name
    INTO   l_rec_name
    FROM   ar_receivables_trx rt
    WHERE  rt.receivables_trx_id = p_adj_rec.receivables_trx_id;

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug(   'after select in insert_revers_actions in app_delete' );
    END IF;

    -- -----------------------------------------------------------------
    -- Get document numbers only if customer is using document numbering
    -- -----------------------------------------------------------------
    -- Profile option values:
    -- 	'A' = always used
    -- 	'P' = Partially Used
    -- 	'N' = not used
    IF (fnd_profile.value('UNIQUE:SEQ_NUMBERS') <> 'N')
    THEN
      BEGIN

    /* Commented to fix bug #741725, as this does not handle gapless sequence
       -- numbering.
        FND_SEQNUM.GET_SEQ_NAME(
        arp_standard.application_id
        , l_rec_name                     -- category code
        , arp_global.set_of_books_id
        , 'A'
        , p_adj_rec.apply_date
        , l_sequence_name
        , l_sequence_id
        , l_sequence_assignment_id);

        p_adj_rec.doc_sequence_value :=
                fnd_seqnum.get_next_auto_seq(l_sequence_name);
        p_adj_rec.doc_sequence_id := l_sequence_id;
     */

        -- Bug fix #741725: Use AOL API get_next_sequence() instead of 
        -- get_seq_name.
        p_adj_rec.doc_sequence_value :=
        FND_SEQNUM.GET_NEXT_SEQUENCE(
                appid           => arp_standard.application_id,
                cat_code        => l_rec_name,
                sobid           => arp_global.set_of_books_id,
                met_code        => 'A',
                trx_date        => p_adj_rec.apply_date,
                dbseqnm         => l_sequence_name,
                dbseqid         => p_adj_rec.doc_sequence_id);
 
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_standard.debug(  'doc sequence name  = '|| l_sequence_name);
           arp_standard.debug(  'doc sequence id    = '|| p_adj_rec.doc_sequence_id);
           arp_standard.debug(  'doc sequence value = '||p_adj_rec.doc_sequence_value);
        END IF;
        -- End fix for bug #741725    
 
      /* Bug 631699: If no document sequence is defined, gives an error
         if profile is set to "always used". If it is "partially used",
         set document number to null as adjustment reversal must have
         automatic sequence and cannot be entered manually */
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (fnd_profile.value('UNIQUE:SEQ_NUMBERS') = 'A') THEN
            FND_MESSAGE.set_name ('AR', 'AR_TW_NO_DOC_SEQ' );
            APP_EXCEPTION.raise_exception;
          ELSE
            p_adj_rec.doc_sequence_value      := NULL;
            p_adj_rec.doc_sequence_id         := NULL;
          END IF;
      END;
 
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_standard.debug(  'doc sequence name = ' || l_sequence_name);
         arp_standard.debug(  'doc sequence id    = ' || l_sequence_id);
         arp_standard.debug(  'doc sequence value = ' || l_sequence_value);
      END IF;
    ELSE
      p_adj_rec.doc_sequence_value 	:= NULL;
      p_adj_rec.doc_sequence_id		:= NULL;
    END IF;

 
/*
    p_adj_rec.doc_sequence_value :=
                        FND_SEQNUM.get_next_auto_sequence (
				arp_standard.application_id
				, l_rec_name
                                , arp_standard.sysparm.set_of_books_id
                                , 'A'
				, to_char(p_adj_rec.apply_date,'YYYY/MM/DD'));
*/ 
    p_adj_rec.set_of_books_id 	:= arp_standard.sysparm.set_of_books_id;
    p_adj_rec.batch_id 		:= NULL;
    p_adj_rec.distribution_set_id := NULL;
    p_adj_rec.gl_posted_date 	:= NULL;
    p_adj_rec.comments 		:= 'XXXXXXX';
    p_adj_rec.automatically_generated := 'Y';
    p_adj_rec.approved_by 	:= FND_GLOBAL.user_id;
    p_adj_rec.ussgl_transaction_code := NULL;
    p_adj_rec.ussgl_transaction_code_context := NULL;
    p_adj_rec.posting_control_id := -3;
    p_adj_rec.cons_inv_id        :=NULL;  /*-------bug 	13111718 */


    -- Insert opposing adjustment

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug(   'before ar_adjustments_pkg.insert_p  in app_delete' );
    END IF;
    arp_adj_pkg.insert_p( p_adj_rec, l_new_adj_id );
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug(   'after ar_adjustments_pkg.insert_p in app_delete' );
    END IF;
    
    
     /* VAT changes: create acct entry */

      l_ae_doc_rec.document_type := 'ADJUSTMENT';
      l_ae_doc_rec.document_id   := l_new_adj_id;
      l_ae_doc_rec.accounting_entity_level := 'ONE';
      l_ae_doc_rec.source_table  := 'ADJ';
      l_ae_doc_rec.source_id     := l_new_adj_id;
      IF (p_adj_rec.created_from = 'REVERSE_CHARGEBACK') THEN
        l_ae_doc_rec.source_id_old := p_adj_rec.code_combination_id;
        l_ae_doc_rec.other_flag := 'CBREVERSAL';
      ELSE
        l_ae_doc_rec.source_id_old := l_old_adj_id;
        l_ae_doc_rec.other_flag := 'REVERSE';
      END IF;
      arp_acct_main.Create_Acct_Entry(l_ae_doc_rec);
 
 /*7699796*/
 
 BEGIN
   
    Select decode (nvl(ctt.post_to_gl,'N'),'Y', 'Y', nvl(ctt.adj_post_to_gl,'N'))
    into   l_adj_post_to_gl
    from   ra_customer_trx ct,   ra_cust_trx_types ctt
    where  ct.customer_trx_id  = p_adj_rec.customer_trx_id
    and    ct.cust_trx_type_id = ctt.cust_trx_type_id ;

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('l_adj_post_to_gl : '|| l_adj_post_to_gl);
    END IF;
    
    EXCEPTION 
    WHEN OTHERS THEN 

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('Unable to get post to gl flag for adjustment' );
       arp_util.debug('EXCEPTION: apr_process_adjustment.insert_reverse_actions '|| SQLERRM);
    END IF;
    RAISE;
END;

   
   IF NVL(l_adj_post_to_gl, 'N') = 'Y' THEN
   
      select status into l_adj_status from ar_adjustments 
      where adjustment_id = l_new_adj_id ;
     
      IF   ( l_adj_status  = 'R' )  THEN
  BEGIN 
  
  select xet.legal_entity_id legal_entity_id,
        adj.SET_OF_BOOKS_ID set_of_books_id,
        adj.org_id          org_id,
        adj.event_id        event_id,
        xet.entity_code     entity_code,
        adj.adjustment_id   adjustment_id,
        xet.application_id
        into 
        l_event_source_info.legal_entity_id,
        l_event_source_info.ledger_id,
        l_security.security_id_int_1,
        l_event_id ,
        l_event_source_info.entity_type_code,
        l_event_source_info.source_id_int_1,
        l_event_source_info.application_id
        from 
        ar_adjustments adj ,
        xla_transaction_entities_upg  xet 
where   adj.adjustment_id               = l_new_adj_id
        and   adj.adjustment_id         = nvl(xet.source_id_int_1,-99)  	
        and   xet.entity_code           ='ADJUSTMENTS'
        AND   xet.application_id        = 222
        AND   adj.SET_OF_BOOKS_ID       = xet.LEDGER_ID;
        
   xla_events_pub_pkg.update_event
               (p_event_source_info    => l_event_source_info,
                p_event_id             => l_event_id,
                p_event_status_code    => 'N',
                p_valuation_method     => null,
                p_security_context     => l_security);
    EXCEPTION
     WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Unable to get the XLA Entites Data ' ||
           'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.insert_reverse_actions' );
         END IF;
         RAISE;
    END;
    
   END IF;
 END IF;     
      
      

/**********************************************************************
 * DO NOT THINK THIS IS NEEDED FOR ETAX SO COMMENTING OUT 
 * IF  p_adj_rec.type = 'TAX' AND
 *       p_adj_rec.status = 'A' AND      -- Approved Tax Adjustment?
 *	nvl(p_adj_rec.tax_adjusted,0) <> 0
 *	/o VAT changes o/
 *
 * THEN
 *   IF PG_DEBUG in ('Y', 'C') THEN
 *     arp_standard.debug(   'before arp_process_tax.sync_vendor_f_ct_adj_id' );
 *   END IF;
 *
 *   /o--------------------------------------------------------+
 *    | Synchronize Tax Vendor.                                |
 *    +--------------------------------------------------------o/
 *	BEGIN
 *       arp_process_tax.sync_vendor_f_ct_adj_id( NULL,
 *                               		 l_new_adj_id,
 *                               		 'ADJ' );
 *     	EXCEPTION
 *	  WHEN arp_tax.AR_TAX_EXCEPTION then
 *		-- Ignore Exception for now.
 *		null;
 *	END;
 *
 *    IF PG_DEBUG in ('Y', 'C') THEN
 *     arp_standard.debug(   'after arp_process_tax.sync_vendor_f_ct_adj_id' );
 *    END IF;
 *
 *   END IF;
 *********************************************************************/

    IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug(   'XX_ARP_PROCESS_ADJUSTMENT.insert_reverse_actions()-');
    END IF;

    EXCEPTION
        WHEN OTHERS THEN
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_standard.debug(   
	      'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.insert_reverse_actions');
              END IF;
              RAISE;
END insert_reverse_actions;
--
/*===========================================================================+
 | PROCEDURE                                                                 |
 |    val_insert_rev_actions                                                 |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    This procedure validated arguments passed to insert_reverse_actions    |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED - NONE                            |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_adj_id -  Adjustment Record Id                       |
 |              OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY - Created by Ganesh Vaidee - 04/25/95                |
 |                                                                           |
 +===========================================================================*/
PROCEDURE val_insert_rev_actions(
                        p_adj_id IN ar_adjustments.adjustment_id%TYPE ) IS
BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug( 'XX_ARP_PROCESS_ADJUSTMENT.val_insert_rev_actions()+' );
    END IF;
    IF ( p_adj_id IS NULL ) THEN
         IF PG_DEBUG in ('Y', 'C') THEN
            arp_standard.debug(  ' Null values found in input variable' );
         END IF;
         FND_MESSAGE.set_name ('AR', 'AR_ARGUEMENTS_FAIL' );
         APP_EXCEPTION.raise_exception;
    END IF;
    --
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug( 'XX_ARP_PROCESS_ADJUSTMENT.val_insert_rev_actions()-' );
    END IF;
    EXCEPTION
       WHEN OTHERS THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_standard.debug(   
      		   'EXCEPTION: XX_ARP_PROCESS_ADJUSTMENT.val_insert_rev_actions' );
            END IF;
            RAISE;
END val_insert_rev_actions;

/* VAT changes: new procedure */
/*===========================================================================+
 | PROCEDURE                                                                 |
 |   cal_prorated_amounts						     |
 |                                                                           |
 | DESCRIPTION                                                               |
 |   Given the adjusted amount, this procedure will calculate the net amount |
 |   and the tax amount. If tax code for the receivable activity is:   	     |
 |   NONE - prorated line amount = adjustment amount			     |
 |	    proated tax = 0						     |
 |   ACTIVITY - prorated amounts are calculated using tax rate of the asset  |
 |	    tax code for the receivable activity			     |
 |	    prorated tax = adjustment amount * tax rate / (100 + tax rate)   |
 |	    prorated line amount = adjustment amount - prorated tax          |
 |   INVOICE - prorated tax = adjustment amount * tax remaining /	     |
 |			      (tax remaining + line remaining)		     |
 |	    prorated line amount = adjustment amount - prorated tax	     |	
 |   In case there is any error occurred, prorated tax and line will return 0|
 |   and p_error_num will be non-zero depending on error encountered	     |
 |   p_error_num = 1 when tax rate for the receivable activity tax code      |
 |		     cannot be found   					     |
 |   p_error_num = 2 when sum of lines remaining and tax remaining is zero   |
 |		     so that the proratio rate cannot be determined when     |
 |		     tax code source is invoice				     |
 |   p_error_num = 3 when a finance charge activity has a tax code source of |
 |		     invoice 						     |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED -                                 |
 |   arpcurr.currround							     |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |			p_adj_amount					     |
 |			p_payment_schedule_id				     |
 |			p_type						     |
 |              OUT:                                                         |
 |			p_prorated_amt					     |
 |			p_prorated_tax					     |
 |			p_error_num					     |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES: 								     |
 |                                                                           |
 | MODIFICATION HISTORY 						     |
 |     10-DEC-98  Tasman Tang	      Created                                |
 |     04-MAR-99  Tasman Tang	      Added parameters p_receivables_trx_id  |
 |				      and p_apply_date. Used tax rate to     |
 |				      calculate prorated amounts for activity|
 |				      tax code				     |
 |     17-AUG-05  Debbie Jancis       Added customer_Trx_line_id for LLCA    |
 |                                    and selected the balances from         |
 |                                    ra_customer_Trx_lines for Line Level   |
 +===========================================================================*/

PROCEDURE cal_prorated_amounts( p_adj_amount          IN number,
			        p_payment_schedule_id IN number,
			        p_type IN varchar2, 
				p_receivables_trx_id  IN number,
				p_apply_date IN date,
			        p_prorated_amt OUT NOCOPY number,
				p_prorated_tax OUT NOCOPY number,
			        p_error_num OUT NOCOPY number,
                                p_cust_trx_line_id IN NUMBER default NULL
				) IS
l_line_remaining	number;
l_tax_remaining		number;
l_prorated_tax		number;
l_invoice_currency_code ar_payment_schedules.invoice_currency_code%TYPE;
l_activity_type		ar_receivables_trx.type%TYPE;
l_tax_code_source	ar_receivables_trx.tax_code_source%TYPE;
l_asset_tax_code	ar_receivables_trx.asset_tax_code%TYPE;
l_sob_id		ar_receivables_trx.set_of_books_id%TYPE;
l_tax_rate		ar_vat_tax.tax_rate%TYPE;

-- Bug 2189230 
/* The tax of Adjustment was calculated according to nearest rule everytime */

l_precision          number;
l_extended_precision number;
l_min_acct_unit      number;
l_rounding_rule      varchar2(30);

l_le_id      NUMBER;
/* Bug 8652261 */
l_msg_count       NUMBER;
l_msg_data        VARCHAR2(1024);
l_effective_date  DATE;
l_return_status   VARCHAR2(10);

BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.cal_prorated_amounts()+');
      arp_util.debug(  'p_adj_amount = ' || to_char(p_adj_amount));
      arp_util.debug(  'p_payment_schedule_id = ' || to_char(p_payment_schedule_id));
      arp_util.debug(  'p_type = ' || p_type);
      arp_util.debug(  'p_receivables_trx_id = ' || to_char(p_receivables_trx_id));
      arp_util.debug(  'p_apply_date = ' || to_char(p_apply_date));
      arp_util.debug(' cust trx line id = ' || to_char(p_cust_trx_line_id));
   END IF;

   p_error_num := 0;

   IF (arp_legal_entity_util.Is_LE_Subscriber) THEN
       SELECT trx.legal_entity_id
         INTO l_le_id
         FROM ra_customer_Trx trx,
              ar_payment_schedules ps
        where ps.payment_schedule_id = p_payment_schedule_id
          and ps.customer_trx_id = trx.customer_trx_id;

       /* 5236782 - detail table not required for adj */
       SELECT trx.type, 
              trx.tax_code_source,
              nvl(details.asset_tax_code, trx.asset_tax_code), 
              trx.set_of_books_id
         INTO l_activity_type,
              l_tax_code_source, 
              l_asset_tax_code, 
              l_sob_id
         FROM ar_receivables_trx trx,
              ar_rec_trx_le_details details
        WHERE trx.receivables_trx_id = p_receivables_trx_id
          and trx.receivables_trx_id = details.receivables_trx_id (+)
          and details.legal_entity_id (+) = l_le_id;
   ELSE
       SELECT type, tax_code_source, asset_tax_code, set_of_books_id
         INTO l_activity_type, l_tax_code_source, l_asset_tax_code, l_sob_id
         FROM ar_receivables_trx
        WHERE receivables_trx_id = p_receivables_trx_id;
   END IF;

   IF l_tax_code_source = 'NONE' THEN
     l_prorated_tax := 0;

   ELSE
     -- if p_cust_Trx_line_id is null - then it is a header level adj
     IF (p_cust_trx_line_id IS NULL ) THEN
        SELECT amount_line_items_remaining, 
               tax_remaining, 
               invoice_currency_code
          INTO l_line_remaining, 
               l_tax_remaining, 
               l_invoice_currency_code
          FROM ar_payment_schedules
         WHERE payment_schedule_id = p_payment_schedule_id;
      ELSE
         -- then we are adjusting at the Line Level.
           SELECT sum(DECODE (lines.line_type,
                              'TAX',0,
                              'FREIGHT',0 , 1) *
                       DECODE(ct.complete_flag, 'N',
                              0, lines.amount_due_remaining)), -- line adr
                  sum(DECODE (lines.line_type,
                              'TAX',1,0) *
                        DECODE(ct.complete_flag,
                               'N', 0,
                               lines.amount_due_remaining )), -- tax adr
                  max(ct.invoice_currency_code) -- curr code
           INTO l_line_remaining,
                l_tax_remaining,
                l_invoice_currency_code
           FROM ra_customer_trx ct,
                ra_customer_trx_lines lines
          WHERE (lines.customer_Trx_line_id = p_cust_trx_line_id or
                 lines.link_to_cust_trx_line_id = p_cust_trx_line_id)
            AND  ct.customer_Trx_id = lines.customer_trx_id;
     END IF;

     -- Bug 2189230
     -- Bug 5514473 : Handled no data found so that tax_rounding_rule will be defaulted if there is no data in zx_product_options for the org
     -- Bug 5514473 : When application tax options are not defined through tax manager for newly created orgs there will no data in zx_product_options
     BEGIN
           SELECT tax_rounding_rule INTO l_rounding_rule
             FROM zx_product_options
            WHERE application_id = 222
	    AND org_id = arp_global.sysparam.org_id;
     EXCEPTION
           WHEN NO_DATA_FOUND THEN
                 l_rounding_rule := NULL;
                 arp_util.debug('tax_rounding_rule will be defaulted because there is no row in zx_product_options');
                 arp_util.debug('Ideal Default Tax Rounding Rule will be : NEAREST');
     END;
     arp_util.debug('tax_rounding_rule = ' || l_rounding_rule);
    
     fnd_currency.Get_info(l_invoice_currency_code,
                                     l_precision,
                                     l_extended_precision,
                                     l_min_acct_unit);

     /* NOTE: needs to be addressed when ETAX does receivable activity */
     IF l_tax_code_source = 'ACTIVITY' THEN
     
           SELECT trx.legal_entity_id
           INTO l_le_id
           FROM ra_customer_Trx trx,
                ar_payment_schedules ps
           WHERE ps.payment_schedule_id = p_payment_schedule_id
           AND ps.customer_trx_id = trx.customer_trx_id;
            
       /* Bug 8652261: Setting the tax security profile as we query the zx tables */          
  
       zx_api_pub.set_tax_security_context(
               p_api_version      => 1.0,
               p_init_msg_list    => 'T',
               p_commit           => 'F',
               p_validation_level => NULL,
               x_return_status    => l_return_status,
               x_msg_count        => l_msg_count,
               x_msg_data         => l_msg_data,
               p_internal_org_id  => arp_standard.sysparm.org_id,
               p_legal_entity_id  => l_le_id,
               p_transaction_date => p_apply_date,
               p_related_doc_date => NULL,
               p_adjusted_doc_date=> NULL,
               x_effective_date   => l_effective_date);
     
       BEGIN

--Bug 10136019. Added condition for zx_accounts.internal_organization_id.
         SELECT zxr.percentage_rate
         INTO   l_tax_rate
         FROM   zx_sco_rates zxr,
                zx_accounts  zxa
         WHERE  zxa.tax_account_entity_code = 'RATES'
         AND    zxa.tax_account_entity_id = zxr.tax_rate_id
         AND    NVL(zxr.tax_class, 'OUTPUT') = 'OUTPUT'
         AND    zxr.tax_jurisdiction_code is NULL
         AND    p_apply_date
               BETWEEN nvl(zxr.effective_from, p_apply_date)
                   AND nvl(zxr.effective_to, p_apply_date)
         AND    zxr.tax_rate_code = l_asset_tax_code
	 AND   (zxa.internal_organization_id = arp_standard.sysparm.org_id
	        OR zxa.internal_organization_id IS NULL);


         -- Bug 2189230

         l_prorated_tax :=  XX_ARP_ETAX_UTIL.tax_curr_round(
                            (p_adj_amount*l_tax_rate/(100 + l_tax_rate)),
                            l_invoice_currency_code,
                            l_precision,
                            l_min_acct_unit,
                            l_rounding_rule);

         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug(  'l_tax_rate = ' || to_char(l_tax_rate));
         END IF;
       EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	 IF PG_DEBUG in ('Y', 'C') THEN
	    arp_util.debug(  'EXCEPTION:  Cannot find a tax rate for the receivable activity tax code');
	 END IF;
	 p_error_num := 1;
	 FND_MESSAGE.SET_NAME('AR', 'AR_TW_PRORATE_ADJ_NO_TAX_RATE');
       END;

     ELSIF l_tax_code_source = 'INVOICE' THEN
       IF l_activity_type = 'FINCHRG' and
          p_type = 'CHARGES' THEN
	 p_error_num := 3;
       END IF;
       IF (l_tax_remaining+l_line_remaining = 0) THEN
         p_error_num := 2;
	 FND_MESSAGE.SET_NAME('AR', 'AR_TW_PRORATE_ADJ_OVERAPPLY');
       ELSE
         -- Bug 2189230
         l_prorated_tax := XX_ARP_ETAX_UTIL.tax_curr_round(
				(l_tax_remaining*p_adj_amount/
                                (l_tax_remaining+l_line_remaining)),
                            l_invoice_currency_code,
                            l_precision,
                            l_min_acct_unit,
                            l_rounding_rule);

       END IF;
     END IF;
   END IF;

   IF p_error_num = 0 THEN
     p_prorated_amt := p_adj_amount - l_prorated_tax;
     p_prorated_tax := l_prorated_tax;
   ELSE
     p_prorated_amt := 0;
     p_prorated_tax := 0;
   END IF;

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug(  'p_prorated_amt = ' || to_char(p_prorated_amt));
      arp_util.debug(  'p_prorated_tax = ' || to_char(p_prorated_tax));
      arp_util.debug(  'p_error_num = ' || to_char(p_error_num));
      arp_util.debug('XX_ARP_PROCESS_ADJUSTMENT.cal_prorated_amounts()-');
   END IF;
 
EXCEPTION
    WHEN OTHERS THEN
     IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug(  
       'EXCEPTION:  XX_ARP_PROCESS_ADJUSTMENT.cal_prorated_amounts()');
     END IF;
     FND_MESSAGE.set_name( 'AR', 'GENERIC_MESSAGE' );
     FND_MESSAGE.set_token( 'GENERIC_TEXT', 'XX_ARP_PROCESS_ADJUSTMENT.cal_prorated_amounts exception: '||SQLERRM );
     RAISE;

END cal_prorated_amounts;


  /*---------------------------------------------+
   |   Package initialization section.           |
   +---------------------------------------------*/


BEGIN

   pg_msg_level_debug   := arp_global.MSG_LEVEL_DEBUG;
   pg_user_id          := fnd_global.user_id;
   pg_text_dummy        := arp_adjustments_pkg.get_text_dummy;
   pg_base_curr_code    := arp_global.functional_currency;
   pg_base_precision    := arp_global.base_precision;
   pg_base_min_acc_unit := arp_global.base_min_acc_unit;

EXCEPTION
    WHEN OTHERS THEN
        arp_util.debug('EXCEPTION:  XX_ARP_PROCESS_ADJUSTMENT.initialization');
        RAISE;   


END XX_ARP_PROCESS_ADJUSTMENT;
/


COMMIT;
EXIT;


