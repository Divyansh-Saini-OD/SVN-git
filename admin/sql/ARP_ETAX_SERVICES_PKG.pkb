create or replace
PACKAGE BODY ARP_ETAX_SERVICES_PKG AS
/* $Header: AREBTSRB.pls 120.37.12010000.16 2010/02/25 21:10:45 dgaurab ship $ */


/*=======================================================================+
 |  Package Globals
 +=======================================================================*/
  G_PKG_NAME          CONSTANT VARCHAR2(30) := 'ARP_ETAX_SERVICES_PKG';

  -- for Manual tax lines, store the line information that the user overrides:
  pg_extended_amount_changed    BOOLEAN := FALSE;
  pg_new_line_rec               ra_customer_trx_lines%rowtype;
  pg_tax_amount_changed         BOOLEAN := FALSE;
  pg_line_changed               BOOLEAN := FALSE;

  pg_use_inv_acctg              VARCHAR2(1);
  pg_so_org_id                  VARCHAR2(20);
  pg_org_id                     NUMBER;

  pg_salesrep_id                NUMBER := -99;
  pg_poo_party_id               NUMBER;
  pg_poo_location_id            NUMBER;

  /*--------------------------------------------------------+
   |  Table records for record and replace tax accounts     |
   +--------------------------------------------------------*/
TYPE table_id_type IS TABLE OF ra_customer_trx_all.customer_trx_id%TYPE
   INDEX BY BINARY_INTEGER;
TYPE amount_type IS TABLE OF ra_cust_trx_line_gl_dist_all.amount%TYPE
   INDEX BY BINARY_INTEGER;
TYPE regime_type IS TABLE OF zx_lines.tax_regime_code%TYPE
   INDEX BY BINARY_INTEGER;
TYPE tax_type IS TABLE OF zx_lines.tax%TYPE
   INDEX BY BINARY_INTEGER;
TYPE flag_type IS TABLE OF ra_cust_trx_line_gl_dist_all.account_set_flag%TYPE
   INDEX BY BINARY_INTEGER;
TYPE account_id_type IS TABLE OF ra_cust_trx_line_gl_dist_all.code_combination_id%TYPE
   INDEX BY BINARY_INTEGER;
TYPE tax_rate_type IS TABLE OF ra_customer_trx_lines_all.vat_tax_id%TYPE
   INDEX BY BINARY_INTEGER;
TYPE collected_tax_ccid_type IS TABLE OF ra_cust_trx_line_gl_dist_all.collected_tax_ccid%TYPE
   INDEX BY BINARY_INTEGER;

t_customer_trx_id           table_id_type;
t_customer_trx_line_id      table_id_type;
t_cust_trx_line_gl_dist_id  table_id_type;
t_cust_trx_line_salesrep_id table_id_type;
t_tax_line_id               table_id_type;
t_amount                    amount_type;
t_account_set_flag          flag_type;
t_tax_regime_code           regime_type;
t_tax                       tax_type;
t_code_combination_id       account_id_type;
t_tax_rate_id		    tax_rate_type;
t_collected_tax_ccid        collected_tax_ccid_type;

  /*--------------------------------------------------------+
   |  Dummy constants for use in update and lock operations |
   +--------------------------------------------------------*/

  AR_TEXT_DUMMY   CONSTANT VARCHAR2(10) := '~~!@#$*&^';
  AR_FLAG_DUMMY   CONSTANT VARCHAR2(10) := '~';
  AR_NUMBER_DUMMY CONSTANT NUMBER(15)   := -999999999999999;

  PG_DEBUG        varchar2(1):= NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');

  FUNCTION use_invoice_accounting
      RETURN BOOLEAN IS
  BEGIN
     IF pg_use_inv_acctg IS NULL
     THEN
        fnd_profile.get( 'AR_USE_INV_ACCT_FOR_CM_FLAG',
                          pg_use_inv_acctg );
        IF pg_use_inv_acctg IS NULL
        THEN
           pg_use_inv_acctg := 'N';
        END IF;

        arp_util.debug('  pg_use_inv_acctg = ' || pg_use_inv_acctg);
     END IF;

     IF pg_use_inv_acctg = 'Y'
     THEN
       RETURN TRUE;
     ELSE
       RETURN FALSE;
     END IF;

  END use_invoice_accounting;

  PROCEDURE copy_inv_tax_dists(p_customer_trx_id IN number)
  IS
    base_min_acc_unit NUMBER;
    base_precision    NUMBER;
    l_rows            NUMBER := 0;
  BEGIN
     IF PG_DEBUG in ('Y','C')
     THEN
         arp_util.debug('arp_etax_services_pkg.copy_inv_tax_dists()+');
     END IF;

     /* Get base precision and minimum accountable unit */
     base_min_acc_unit := arp_trx_global.system_info.base_min_acc_unit;
     base_precision := arp_trx_global.system_info.base_precision;

     /* This insert copied from the logic in arp_credit_memo_module.
        The idea is that copying invoice tax accounting is pretty
        simple, but we need the logic to be callable at any time
        rather than tied to other arp_credit_memo_module behavior */

     /* 5413663 - due to concerns that this code might create
        incorrect or poorly timed tax dists, I have modified
        the program_id logic to use -5 instead of a valid value.
        That way, we can tell if this code created the tax or
        if it came from somewhere else (rev rec, autoaccounting) */

     INSERT into ra_cust_trx_line_gl_dist
     (
        /* gl_dist_id used to be here - now populated by BRI trigger */
        customer_trx_id,               /* credit memo customer_trx_id */
        customer_trx_line_id,          /* credit memo customer_trx_line_id */
        set_of_books_id,
        last_update_date,
        last_updated_by,
        creation_date,
        created_by,
        last_update_login,
        program_application_id,
        program_id,
        program_update_date,
        account_class,
        account_set_flag,
        percent,
        amount,
        acctd_amount,
        gl_date,
        code_combination_id,
        posting_control_id,
        collected_tax_ccid,
        ussgl_transaction_code,
        org_id,
        event_id
     )
     SELECT
        ctl.customer_trx_id,
        ctl.customer_trx_line_id,
        ct.set_of_books_id,
        sysdate,
        ct.last_updated_by,
        sysdate,
        ct.created_by,
        ct.last_update_login,
        ctl.program_application_id,           /* program_appl_id */
        -5,                                   /* program_id */
        sysdate,                              /* program_update_date */
        'TAX',
        'N',
        decode(ctl.extended_amount, 0, prev_ctlgd.percent,
            round(((decode(foreign_fc.minimum_accountable_unit,
                      null, round(
      NVL(prev_ctlgd.amount /
        decode(prev_ctl.extended_amount,0,1,prev_ctl.extended_amount),1) *
          decode(ctl.extended_amount,0,
            decode(prev_ctl.extended_amount,0,-1,0),
               ctl.extended_amount) , foreign_fc.precision),
                            round(
      NVL(prev_ctlgd.amount /
        decode(prev_ctl.extended_amount,0,1,prev_ctl.extended_amount),1) *
           decode(ctl.extended_amount,0,
             decode(prev_ctl.extended_amount,0,-1,0),
               ctl.extended_amount)
                           / foreign_fc.minimum_accountable_unit) *
                             foreign_fc.minimum_accountable_unit) /
               decode(ctl.extended_amount, 0, 1, ctl.extended_amount)) *
                 decode(ctl.extended_amount, 0, 0, 1))
                     * 100, 4)),            /*   percent */
      decode(foreign_fc.minimum_accountable_unit,
         null, round(NVL(prev_ctlgd.amount /
            decode(prev_ctl.extended_amount,0,1,
                   prev_ctl.extended_amount),1) *
              decode(ctl.extended_amount,0,
                decode(prev_ctl.extended_amount,0,-1,0),
                     ctl.extended_amount), foreign_fc.precision),
               round(NVL(prev_ctlgd.amount /
            decode(prev_ctl.extended_amount,0,1,
                   prev_ctl.extended_amount),1) *
              decode(ctl.extended_amount,0,
                decode(prev_ctl.extended_amount,0,-1,0),
                     ctl.extended_amount)
                          / foreign_fc.minimum_accountable_unit) *
                            foreign_fc.minimum_accountable_unit
       ),                                /*    amount   */
        decode(base_min_acc_unit, NULL,
            round(decode(foreign_fc.minimum_accountable_unit,
               null, round(NVL(prev_ctlgd.amount /
                   decode(prev_ctl.extended_amount,0,1,
                          prev_ctl.extended_amount),1) *
                     decode(ctl.extended_amount,0,
                       decode(prev_ctl.extended_amount,0,-1,0),
                         ctl.extended_amount), foreign_fc.precision),
                     round(NVL(prev_ctlgd.amount /
                   decode(prev_ctl.extended_amount,0,1,
                          prev_ctl.extended_amount),1) *
                     decode(ctl.extended_amount,0,
                       decode(prev_ctl.extended_amount,0,-1,0),
                         ctl.extended_amount)
                       / foreign_fc.minimum_accountable_unit) *
                         foreign_fc.minimum_accountable_unit) *
                    nvl(ct.exchange_rate, 1),
                  base_precision),
            round(decode(foreign_fc.minimum_accountable_unit,
               null, round(NVL(prev_ctlgd.amount /
                   decode(prev_ctl.extended_amount,0,1,
                          prev_ctl.extended_amount),1) *
                     decode(ctl.extended_amount,0,
                       decode(prev_ctl.extended_amount,0,-1,0),
                         ctl.extended_amount), foreign_fc.precision),
                     round(NVL(prev_ctlgd.amount /
                       decode(prev_ctl.extended_amount,0,1,
                              prev_ctl.extended_amount),1) *
                          decode(ctl.extended_amount,0,
                            decode(prev_ctl.extended_amount,0,-1,0),
                               ctl.extended_amount)
                      / foreign_fc.minimum_accountable_unit) *
                        foreign_fc.minimum_accountable_unit) *
                  nvl(ct.exchange_rate, 1) /
                  base_min_acc_unit) * base_min_acc_unit),
                                          /*  acctd_amount */
      rec_ctlgd.gl_date,
      prev_ctlgd.code_combination_id,
      -3,
      prev_ctlgd.collected_tax_ccid,
      ct.default_ussgl_transaction_code,
      ct.org_id,
      rec_ctlgd.event_id
     FROM
        fnd_currencies foreign_fc,
        ra_customer_trx ct,
        ra_customer_trx_lines ctl,
        ra_cust_trx_line_gl_dist ctlgd,
        ra_cust_trx_line_gl_dist rec_ctlgd,     /* cm rec dist */
        ra_customer_trx prev_ct,
        ra_customer_trx_lines prev_ctl,
        ra_cust_trx_line_gl_dist prev_ctlgd
     WHERE
           ct.customer_trx_id = p_customer_trx_id
     AND   ct.customer_trx_id = ctl.customer_trx_id
     AND   ctl.line_type = 'TAX'
       /* Do not duplicate if already there */
     AND   ctl.customer_trx_line_id = ctlgd.customer_trx_line_id (+)
     AND   ctlgd.customer_trx_id IS NULL
       /* Get CM Rec row (for gl_date) */
     AND   ct.customer_trx_id = rec_ctlgd.customer_trx_id (+)
     AND   rec_ctlgd.account_class (+) = 'REC'
     AND   rec_ctlgd.latest_rec_flag (+) = 'Y'
     AND   ct.invoice_currency_code = foreign_fc.currency_code
       /* Join to the invoice */
     AND   ctl.previous_customer_trx_line_id
                         = prev_ctl.customer_trx_line_id(+)
     AND   prev_ctl.customer_trx_line_id
                         = prev_ctlgd.customer_trx_line_id(+)
     AND   prev_ctl.customer_trx_id  = prev_ct.customer_trx_id(+)
       /* 5413663 - only non-model dists */
     AND   prev_ctlgd.account_set_flag = 'N';

     l_rows := SQL%ROWCOUNT;

     IF PG_DEBUG in ('Y','C')
     THEN
         arp_util.debug('  tax dists inserted = ' || l_rows);
         arp_util.debug('arp_etax_services_pkg.copy_inv_tax_dists()-');
     END IF;
  END copy_inv_tax_dists;

  /* Records tax accounting prior to deletion in global plsql tables.
     These rows are later used for a bulk update
     of ra_cust_trx_line_gl_dist */

  PROCEDURE record_tax_accounts(p_customer_trx_id IN number)
  IS

    CURSOR tax_line_and_dist(p_customer_trx_id NUMBER) IS
      SELECT tl.customer_trx_id,           -- trx_id
             tl.link_to_cust_trx_line_id,  -- parent line
             tgl.cust_trx_line_gl_dist_id, -- tax dist ID
             NVL(tgl.cust_trx_line_salesrep_id,
                    -99),                  -- SR ID (from dist)
             tl.tax_line_id,               -- originated tax line in ebt
             tgl.amount,                   -- tax amount (not currently used)
             tgl.account_set_flag,         -- account set Y/N
             zx.tax_regime_code,           -- ZX tax regime code
             zx.tax,                       -- ZX tax code
             tgl.code_combination_id,      -- tax account!
	     tl.vat_tax_id,		   -- Tax Rate ID
	     tgl.collected_tax_ccid	   -- Collected Tax ccid for deferrred taxes
      FROM   ra_customer_trx_lines    tl,
             ra_cust_trx_line_gl_dist tgl,
             zx_lines                 zx
      WHERE  tl.customer_trx_id = p_customer_trx_id
      AND    tl.line_type = 'TAX'
      AND    tl.customer_trx_line_id = tgl.customer_trx_line_id
      AND    tgl.code_combination_id <> -1 -- skip invalid accounts
      -- Bug 9012585: This will have value only for deferred tax so using NVL
      AND    nvl(tgl.collected_tax_ccid, 0) <> -1
      AND    tl.tax_line_id = zx.tax_line_id;

    l_rows NUMBER;

  BEGIN
     IF PG_DEBUG in ('Y','C')
     THEN
         arp_debug.debug('arp_etax_services_pkg.record_tax_accounts()+');
     END IF;

     OPEN tax_line_and_dist(P_CUSTOMER_TRX_ID);
	FETCH tax_line_and_dist BULK COLLECT INTO
            t_customer_trx_id,
            t_customer_trx_line_id,
            t_cust_trx_line_gl_dist_id,
            t_cust_trx_line_salesrep_id,
            t_tax_line_id,
            t_amount,
            t_account_set_flag,
            t_tax_regime_code,
            t_tax,
            t_code_combination_id,
	    t_tax_rate_id,
	    t_collected_tax_ccid;


        l_rows := tax_line_and_dist%ROWCOUNT;

        CLOSE tax_line_and_dist;

     IF PG_DEBUG in ('Y','C')
     THEN
         arp_debug.debug('  distribution(s) recorded = ' || l_rows);
         arp_debug.debug('arp_etax_services_pkg.record_tax_accounts()-');
     END IF;
  END record_tax_accounts;

  /* Uses tax account tables to bulk update ra_cust_trx_line_gl_dist with
     corrected or overridden accounts. */

  PROCEDURE replace_tax_accounts
  IS
     l_rows NUMBER := 0;
  BEGIN
     IF PG_DEBUG in ('Y','C')
     THEN
         arp_debug.debug('arp_etax_services_pkg.replace_tax_accounts()+');

       /* Debug Code - start +/
       -- this code dumps the cached accounting lines so we can
       -- see what is happening during the caching process.
       IF t_customer_trx_id.EXISTS(1)
       THEN
         FOR acc in t_customer_trx_id.FIRST .. t_customer_trx_id.LAST LOOP
           arp_debug.debug(acc || ':' ||
              t_customer_trx_id(acc) || '~' ||
              t_customer_trx_line_id(acc) || '~' ||
              t_cust_trx_line_salesrep_id(acc) || '~' ||
              t_tax_regime_code(acc) || '~' ||
              t_tax(acc) || '~' ||
	      t_tax_rate_id(acc) || '~' ||
	      t_tax_line_id(acc) || '~' ||
              t_account_set_flag(acc) || '~' ||
              t_code_combination_id(acc));
         END LOOP;
       END IF;
       /+ Debug Code - end */
     END IF;

     /* Bulk update of gl_dist rows for tax...
        Note that this code updates all tax accounting rows where
        the new and old tax accounts are different.  Additionally,
        it will never bring forward an invalid account (ccid -1).
        we match up the tax regime, tax, salesrep_id, account_set_flag,
        and line_id.  This may need to be adjusted later if we find
        reasons to not preserve the original tax accounts */
     IF t_customer_trx_id.EXISTS(1)
     THEN
       FORALL i IN t_customer_trx_id.FIRST .. t_customer_trx_id.LAST
       UPDATE ra_cust_trx_line_gl_dist gld
       SET    code_combination_id = t_code_combination_id(i),
	      collected_tax_ccid  = t_collected_tax_ccid(i)
       WHERE  customer_trx_id = t_customer_trx_id(i)
       AND    account_class = 'TAX'
       AND    cust_trx_line_gl_dist_id IN
         (SELECT tgl.cust_trx_line_gl_dist_id
          FROM   ra_cust_trx_line_gl_dist tgl,
                 ra_customer_trx_lines    tl,
                 zx_lines                 zx
          WHERE  tl.customer_trx_id = t_customer_trx_id(i)
          AND    tl.link_to_cust_trx_line_id =
                    t_customer_trx_line_id(i)
          AND    tl.line_type = 'TAX'
          AND    tl.customer_trx_line_id = tgl.customer_trx_line_id
          AND    tgl.account_class = 'TAX'
          AND    tgl.account_set_flag = t_account_set_flag(i)
          AND  ( tgl.code_combination_id <> t_code_combination_id(i)
	  -- Bug 9012585 : Honour manual override for collected_tax_ccid as well
	  OR	 NVL(tgl.collected_tax_ccid,0) <> NVL(t_collected_tax_ccid(i),0) )
          AND    nvl(tgl.cust_trx_line_salesrep_id, -99) =
                    t_cust_trx_line_salesrep_id(i)
          AND    tl.tax_line_id = zx.tax_line_id
	  AND    tl.vat_tax_id  = t_tax_rate_id(i)
	  AND    tl.tax_line_id = t_tax_line_id(i));

     l_rows := SQL%ROWCOUNT;
     END IF;


     IF PG_DEBUG in ('Y','C')
     THEN
         arp_debug.debug('  distribution(s) updated = ' || l_rows);
         arp_debug.debug('arp_etax_services_pkg.replace_tax_accounts()-');
     END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        IF PG_DEBUG = 'Y' THEN
          arp_debug.debug( 'no rows in tax account tables');
        END IF;

  END replace_tax_accounts;

/*=============================================================================
 |  FUNCTION - Calculate()
 |
 |  DESCRIPTION
 |      Public function that will call the calculate_tax service for
 |      calculation and recalculation.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  14-Apr-2005     Debbie Sue Jancis   Created
 |  26-MAY-2006     M Raymond           5152340 - added call to
 |                                        delete_tax_lines_from_ar
 *===========================================================================*/
FUNCTION Calculate( p_customer_trx_id IN NUMBER,
                    p_cust_trx_line_id IN NUMBER,
                    p_action IN VARCHAR2,
                    p_line_level_action IN VARCHAR2 ) RETURN BOOLEAN IS

    l_transaction_rec            zx_api_pub.transaction_rec_type;

    l_return_status_service             VARCHAR2(4000);
    l_msg_count                         NUMBER;
    l_msg_data                          VARCHAR2(4000);
    l_msg_data_out                      VARCHAR2(4000);
    l_mesg                              VARCHAR2(4000);
    l_doc_level_recalc_flag             VARCHAR2(1);

    l_event_class_code   VARCHAR2(80);
    l_event_type_code    VARCHAR2(80);
    l_success BOOLEAN;
    l_rows   NUMBER;
BEGIN
 arp_util.debug('ARP_ETAX_SERVICES_PKG.Calculate(+)');
    /* get event class code */
    l_success := arp_etax_util.get_event_information(
                 p_customer_trx_id => p_customer_trx_id,
                 p_action => p_action,
                 p_event_class_code => l_event_class_code,
                 p_event_type_code => l_event_type_code);

    arp_util.debug('customer trx id = ' || p_customer_trx_id);
    arp_util.debug('action = ' || p_action);
    arp_util.debug('event class code = ' || l_event_class_code);
    arp_util.debug('event type code = ' || l_event_type_code);

    IF (l_success) THEN
      /* populate transaction rec type */
       l_transaction_rec.internal_organization_id := arp_global.sysparam.org_id;
       l_transaction_rec.application_id           := 222;
       l_transaction_rec.entity_code              := 'TRANSACTIONS';
       l_transaction_rec.event_class_code         := l_event_class_code;
       l_transaction_rec.event_type_code          := l_event_type_code;
       l_transaction_rec.trx_id                   := p_customer_trx_id;

       /* initialize the pl/sql table
       ZX_GLOBAL_STRUCTURES_PKG.INIT_TRX_LINE_DIST_TBL(1); */

       /* insert data into ebt plsql tables

        arp_util.debug('calling populate_ebt_plsql_tables ');
        populate_ebt_plsql_tables(
                  p_customer_trx_id      => p_customer_trx_id,
                  p_customer_trx_line_id => p_cust_trx_line_id,
                  p_event_type_code      => l_event_type_code,
                  p_event_class_code     => l_event_class_code,
                  p_line_level_action    => p_line_level_action); */


        /* 5152340 - Remove AR tax lines before calculating tax */
        arp_etax_util.delete_Tax_lines_from_ar(p_customer_trx_id);

        /* call Tax */
        arp_util.debug('calling ZX api to calculate tax');
        arp_util.debug('ORG ID = ' || l_transaction_rec.internal_organization_id);

        zx_api_pub.calculate_tax(
             p_api_version           => 1.0,
             p_init_msg_list         => FND_API.G_TRUE,
             p_commit                => FND_API.G_FALSE,
             p_validation_level      => FND_API.G_VALID_LEVEL_FULL,
             p_transaction_rec       => l_transaction_rec,
             p_quote_flag            => 'N',
             p_data_transfer_mode    => 'WIN',
             x_return_status         => l_return_status_service,
             x_msg_count             => l_msg_count,
             x_msg_data              => l_msg_data,
             x_doc_level_recalc_flag => l_doc_level_recalc_flag );

      arp_util.debug('return status service = ' || l_return_status_service);

      IF (l_return_status_service = 'S') THEN
        --  insert Tax records into ra_customer_trx_lines based upon
        --  customer trx line id
           arp_util.debug('calling build_ar_tax_lines ...');
           arp_util.debug('customer trx id = ' || p_customer_trx_id);

           arp_etax_util.build_ar_tax_lines(
                    p_customer_trx_id  => p_customer_trx_id,
                    p_rows_inserted    => l_rows);

      ELSE
         arp_util.debug('Calculate returned error');
        IF ( l_msg_count = 1 ) THEN
           -- then there is only 1 message raised by the API, and
           -- it has been sent out in the parameter x_msg_data.
           l_msg_data_out := l_msg_data;
           arp_util.debug('API failed with : ' || l_msg_data_out);
           l_mesg := l_msg_data_out;

        ELSIF (l_msg_count > 1) THEN
           -- the messages are on the stack and there is more then
           -- 1 so call them in a loop
           loop
             l_mesg := FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT,
                                       FND_API.G_FALSE);
             if (l_mesg IS NULL) THEN
                EXIT;
             end if;
             arp_util.debug('API failed with : ' || l_mesg);
           end loop;
        END IF;

        -- raise error
        /* 4919401 - Added generic message fetch */
        FND_MESSAGE.SET_NAME('FND', 'FND_GENERIC_MESSAGE');
        FND_MESSAGE.SET_TOKEN('MESSAGE', l_mesg);
        FND_MSG_PUB.ADD;

        APP_EXCEPTION.RAISE_EXCEPTION;

        RETURN FALSE;
      END IF;

  ELSE
    arp_standard.debug('could not get an event class code');
    RETURN FALSE;
  END IF;

   RETURN TRUE;

END Calculate;

PROCEDURE populate_ebt_plsql_tables(
                p_customer_trx_id IN NUMBER,
                p_customer_trx_line_id  IN NUMBER,
                p_event_type_code IN VARCHAR2,
                p_event_class_code IN VARCHAR2,
                p_line_level_action IN VARCHAR2,
		p_tax_amount IN NUMBER DEFAULT NULL) IS

l_line_ship_to_cust_id   RA_CUSTOMER_TRX_LINES.ship_to_customer_id%TYPE;
l_line_ship_to_su_id   RA_CUSTOMER_TRX_LINES.ship_to_site_use_id%TYPE;
l_hdr_ship_to_cust_id   RA_CUSTOMER_TRX.ship_to_customer_id%TYPE;
l_hdr_ship_to_su_id   RA_CUSTOMER_TRX.ship_to_site_use_id%TYPE;
l_cust_id  RA_CUSTOMER_TRX.ship_to_customer_id%TYPE;
l_site_use_id RA_CUSTOMER_TRX.ship_to_site_use_id%TYPE;
l_memo_line_id RA_CUSTOMER_TRX_LINES.memo_line_id%TYPE;  --bug6770861

--Variables defined for Bug6126010.
p_salesrep_id NUMBER;
p_ccid NUMBER;
p_conc_seg VARCHAR2(240);
p_num_fail NUMBER;
p_error_buf VARCHAR2(2000);
p_trx_type_id NUMBER;
p_inv_item_id NUMBER;
p_memo_line_id NUMBER;
l_trx_date     DATE;
p_warehouse_id NUMBER; /* Bug 8758638 */
BEGIN
   IF PG_DEBUG in ('Y','C') THEN
       arp_util.debug('populate_ebt_plsql_tables(+)');
   END IF;

   /* Set pg_so_org_id any time it is not set or
      any time the OU changes.  This supports cases where
      users change OU without exiting form */
   IF NVL(pg_org_id,-99) <> arp_global.sysparam.org_id
   THEN
       pg_org_id := arp_global.sysparam.org_id;

       pg_so_org_id := oe_profile.value('SO_ORGANIZATION_ID',
                           pg_org_id);
       pg_salesrep_id := -99;
   END IF;

   SELECT
      TRX.org_id,                       -- internal_organization_id
      222,                              -- application_id
      'TRANSACTIONS',                   -- entity_code
      p_event_class_code,               -- event_class_code
      p_event_type_code,                -- event_type_code
      p_customer_trx_id,                -- trx_id
      TRX.trx_date,                     -- trx_date
      AR.set_of_books_id,               -- ledger_id
      TRX.invoice_currency_code,        -- trx_currency_code
      TRX.exchange_date,                -- currency_conversion_date
      TRX.exchange_rate,                -- currency_conversion_rate
      TRX.exchange_rate_type,           -- currency_conversion_type
      CURR.minimum_accountable_unit,    -- minimum_accountable_unit
      CURR.precision,                   -- precision
      TRX.legal_entity_id,                -- legal_entity_id
      'LINE',                           -- trx_level_type
      p_line_level_action,              -- line_level_action ?????? *****
      p_customer_trx_line_id,           -- trx_line_id
      -- trx_business_category
      TRX.cust_trx_type_id,             -- receivables_trx_type_id
      'Y',                              -- tax_reporting_flag
      'N',                              -- Quote_Flag
      LINES.tax_classification_code,    -- output_tax_classification_code
      NULL,                             -- interface_entity_code
      NULL,                             -- interface_line_id
      LINES.line_number,                -- trx_line_number
      LINES.historical_flag,            -- historical_flag
      'N',                              -- ctrl_hdr_tx_appl_flag
      TRX.trx_number,                   -- trx_number
      substrb(TRX.comments,1,240),      -- trx_description
      TRX.printing_original_date,       -- trx_communicated_date
      TRX.batch_source_id,              -- batch_source_id
      BS.NAME,                          -- batch_source_name
      TRX.doc_sequence_id,              -- doc_seq_id
      SEQ.name,                         -- doc_seq_name
      TRX.doc_sequence_value,           -- doc_seq_value
      TRX.term_due_date,                -- trx_due_date
      TYPES.description,                -- trx_type_description
      NVL(REC.gl_date, TRUNC(sysdate)), --trx_line_gl_date
      DECODE(TYPES.type,
             'CM', 'CREDIT_MEMO',
             'DM', 'DEBIT_MEMO',
             'INVOICE'),               -- line_class
      LINES.sales_order_date,          -- trx_shipping_date
      DECODE(LINES.inventory_item_id, NULL, 'MISC', 'ITEM'), -- trx_line_type
      NULL,                            -- trx_line_date
      DECODE(LINES.amount_includes_tax_flag, 'Y',
             'A','N', 'N', 'S'),       -- line_amt_includes_tax_flag
      NVL(LINES.GROSS_EXTENDED_AMOUNT,LINES.extended_amount),           -- line_amt Bug 7692158
      DECODE(TYPES.type,
             'CM', LINES.quantity_credited,
             LINES.quantity_invoiced),         -- trx_line_quantity -- Bug 8717137
      LINES.unit_selling_price,        -- unit_price
      LINES.tax_exempt_flag,           -- exemption_control_flag
      LINES.tax_exempt_number,         -- exempt_certificate_number
      LINES.tax_exempt_reason_code,    -- exempt_reason
      NVL(LINES.inventory_item_id,
          LINES.memo_line_id),         -- product_id
      LINES.uom_code,                  -- uom_code
      TRX.fob_point,                   -- fob_point
      LINES.warehouse_id,              -- ship_from_party_id
      HR.location_id,                  -- ship_from_location_id
      BILL_CUST.party_id,              -- bill_to_party_id
      BILL_CUST.party_id,              -- rounding_bill_to_party_id
      BILL_AS.party_site_id,           -- bill_to_party_site_id
      BILL_AS.party_site_id,           -- rndg_bill_to_party_site_id
      BILL_LOC.location_id,            -- bill_to_location_id
      -- account_ccid ***see select below due to possible multiple records
      -- source_application_id
      -- source_entity_code
      -- source_event_class_code
      -- source_trx_id
      -- source_lines_id
      -- source_trx_level_type
      -- tax_amt_included_flag
      TRX.ship_to_customer_id,
      TRX.ship_to_site_use_id,
      LINES.ship_to_customer_id,
      LINES.ship_to_site_use_id,
      TRX.invoice_currency_code,        -- trx_line_currency_code
      CURR.precision,                   -- trx_line_precision
      /*Bug8650264, Modified the code to pass adjusted_doc details as NULL for
        Deposit and Guarantee.*/
      /*Bug8731231, Modified the code to pass adjusted_doc details as NULL for
        Chargeback */
      DECODE(TRX.previous_customer_trx_id,
             NULL, NULL, DECODE(INV_TT.TYPE,'DEP',NULL,'GUAR',NULL,'CB',NULL,222)),           -- adjusted_doc_application_id
      DECODE(TRX.previous_customer_trx_id,
             NULL, NULL, DECODE(INV_TT.TYPE,'DEP',NULL,'GUAR',NULL,'CB',NULL,'TRANSACTIONS')),-- adjusted_doc_entity_code
      /* bug6769106 vavenugo
      modified the line below to pass the correct value for adjusted_doc_event_class_code based on the type of the document */
      DECODE(TRX.previous_customer_trx_id,
             NULL, NULL, DECODE(INV_TT.TYPE,'DM','DEBIT_MEMO','DEP',NULL,'GUAR',NULL,'CB',NULL,'INVOICE')), -- adjusted_doc_event_class_Code
      DECODE(TRX.previous_customer_trx_id,
             NULL, NULL, DECODE(INV_TT.TYPE,'DEP',NULL,'GUAR',NULL,'CB',NULL,TRX.previous_customer_trx_id)), -- adjusted_doc_trx_id
      DECODE(LINES.previous_customer_trx_line_id, NULL, NULL,
             DECODE(INV_TT.TYPE,'DEP',NULL,'GUAR',NULL,'CB',NULL,LINES.previous_customer_trx_line_id)), -- adjusted_doc_line_id
      DECODE(TRX.previous_customer_trx_id,
              NULL, NULL, DECODE(INV_TT.TYPE,'DEP',NULL,'GUAR',NULL,'CB',NULL,'LINE')),              -- adjusted_doc_trx_level_type
      DECODE(TRX.previous_customer_trx_id, NULL,
             NULL, DECODE(INV_TT.TYPE,'DEP',NULL,'GUAR',NULL,'CB',NULL,INV.trx_number)),              -- adjusted_doc_number
      DECODE(TRX.previous_customer_trx_id, NULL,
             NULL, DECODE(INV_TT.TYPE,'DEP',NULL,'GUAR',NULL,'CB',NULL,INV.trx_date)),                 -- adjusted_doc_date
      /* 4666566 */
      TRX.bill_to_customer_id,
      TRX.bill_to_site_use_id,
      BILL_AS.cust_acct_site_id,
      DECODE(LINES.memo_line_id, NULL,
         NVL(LINES.warehouse_id,to_number(pg_so_org_id)),NULL),
      TRX.org_id,                   -- poa_party_id
      HRL.location_id,              -- poa_location_id
      DECODE(REL_T.customer_trx_id, NULL, NULL, 222),
      DECODE(REL_T.customer_trx_id, NULL, NULL, 'TRANSACTIONS'),
      DECODE(REL_T.customer_trx_id, NULL, NULL,
         DECODE(REL_TT.type, 'INV', 'INVOICE',
                             'DM',  'DEBIT_MEMO',
                             'CM',  'CREDIT_MEMO')),
      DECODE(REL_T.customer_trx_id, NULL, NULL, REL_T.customer_trx_id),
      DECODE(REL_T.customer_trx_id, NULL, NULL, REL_T.trx_number),
      DECODE(REL_T.customer_trx_id, NULL, NULL, REL_T.trx_date),
      HRL.location_id,         -- bill_from_location_id
      ML.tax_product_category,  -- bug6770861, 6874006
      LINES.description
   INTO
     -- internal_organization_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.INTERNAL_ORGANIZATION_ID(1),
     -- application_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.APPLICATION_ID(1),
     -- entity_code
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ENTITY_CODE(1),
     -- event_class_code
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EVENT_CLASS_CODE(1),
     -- event_type_code
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EVENT_TYPE_CODE(1),
     -- trx_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_ID(1),
     -- trx_date
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_DATE(1),
     -- ledger_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LEDGER_ID(1),
     -- trx_currency_code
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_CURRENCY_CODE(1),
     -- currency_conversion_date
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CURRENCY_CONVERSION_DATE(1),
     -- currency_conversion_rate
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CURRENCY_CONVERSION_RATE(1),
     -- currency_conversion_type
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CURRENCY_CONVERSION_TYPE(1),
     -- minimum_accountable_unit
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.MINIMUM_ACCOUNTABLE_UNIT(1),
     -- precision
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.PRECISION(1),
     -- legal_entity_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LEGAL_ENTITY_ID(1),
     -- trx_level_type
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LEVEL_TYPE(1),
     -- line_level_action ?????? *****
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_LEVEL_ACTION(1),
     -- trx_line_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_ID(1),
     -- trx_business_category
     -- receivables_trx_type_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.RECEIVABLES_TRX_TYPE_ID(1),
     -- tax_reporting_flag
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TAX_REPORTING_FLAG(1),
     -- Quote_Flag
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.QUOTE_FLAG(1),
     -- output_tax_classification_code
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.OUTPUT_TAX_CLASSIFICATION_CODE(1),
     -- interface_entity_code
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.INTERFACE_ENTITY_CODE(1),
     -- interface_line_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.INTERFACE_LINE_ID(1),
     -- trx_line_number
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_NUMBER(1),
     -- historical_flag
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.HISTORICAL_FLAG(1),
     -- ctrl_hdr_tx_appl_flag
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CTRL_HDR_TX_APPL_FLAG(1),
     -- trx_number
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_NUMBER(1),
     -- trx_description
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_DESCRIPTION(1),
     -- trx_communicated_date
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_COMMUNICATED_DATE(1),
     -- batch_source_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BATCH_SOURCE_ID(1),
     -- batch_source_name
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BATCH_SOURCE_NAME(1),
     -- doc_seq_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.DOC_SEQ_ID(1),
     -- doc_seq_name
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.DOC_SEQ_NAME(1),
     -- doc_seq_value
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.DOC_SEQ_VALUE(1),
     -- trx_due_date
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_DUE_DATE(1),
     -- trx_type_description
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_TYPE_DESCRIPTION(1),
     -- trx_line_gl_date
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_GL_DATE(1),
     -- line_class
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_CLASS(1),
     -- trx_shipping_date
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_SHIPPING_DATE(1),
     -- trx_line_type
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_TYPE(1),
     -- trx_line_date
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_DATE(1),
     -- line_amt_includes_tax_flag
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_AMT_INCLUDES_TAX_FLAG(1),
     -- line_amt
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_AMT(1),
     -- trx_line_quantity
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_QUANTITY(1),
     -- unit_price
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.UNIT_PRICE(1),
     -- exemption_control_flag
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EXEMPTION_CONTROL_FLAG(1),
     -- exempt_certificate_number
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EXEMPT_CERTIFICATE_NUMBER(1),
     -- exempt_reason
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EXEMPT_REASON_CODE(1),
     -- product_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.PRODUCT_ID(1),
     -- uom_code
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.UOM_CODE(1),
     -- fob_point
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.FOB_POINT(1),
     -- ship_from_party_id, location_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_FROM_PARTY_ID(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_FROM_LOCATION_ID(1),
     -- bill_to_party_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_TO_PARTY_ID(1),
     -- rounding_bill_to_party_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ROUNDING_BILL_TO_PARTY_ID(1),
     -- bill_to_party_site_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_TO_PARTY_SITE_ID(1),
     -- rndg_bill_to_party_site_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.RNDG_BILL_TO_PARTY_SITE_ID(1),
     -- bill_to_location_id
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_TO_LOCATION_ID(1),
     -- SHIP TO information for later derivation
     l_hdr_ship_to_cust_id,
     l_hdr_ship_to_su_id,
     l_line_ship_to_cust_id,
     l_line_ship_to_su_id,
     -- trx_line_currency_code
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_CURRENCY_CODE(1),
     -- trx_line_precison
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_PRECISION(1),
     --adjusted_doc_application_id,
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ADJUSTED_DOC_APPLICATION_ID(1),
     --adjusted_doc_entity_code,
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ADJUSTED_DOC_ENTITY_CODE(1),
     --adjusted_doc_event_class_code,
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ADJUSTED_DOC_EVENT_CLASS_CODE(1),
     --adjusted_doc_trx_id,
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ADJUSTED_DOC_TRX_ID(1),
     --adjusted_doc_line_id,
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ADJUSTED_DOC_LINE_ID(1),
     --adjusted_doc_trx_level_type,
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ADJUSTED_DOC_TRX_LEVEL_TYPE(1),
     --adjusted_doc_number,
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ADJUSTED_DOC_NUMBER(1),
     --adjusted_doc_date
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ADJUSTED_DOC_DATE(1),
     /* 4666566 */
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_THIRD_PTY_ACCT_ID(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_TO_CUST_ACCT_SITE_USE_ID(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_THIRD_PTY_ACCT_SITE_ID(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.PRODUCT_ORG_ID(1),
     /* 5082548 - poo and poa values */
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.poa_party_id(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.poa_location_id(1),
     /* 6874006 - moved poo values to separate statement below */
     /* 5345904 - related_doc columns */
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.related_doc_application_id(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.related_doc_entity_code(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.related_doc_event_class_code(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.related_doc_trx_id(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.related_doc_number(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.related_doc_date(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.bill_from_location_id(1),
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.product_category(1),
     ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_DESCRIPTION(1)
   FROM
       RA_CUSTOMER_TRX          TRX,
       RA_CUSTOMER_TRX_LINES    LINES,
       RA_CUST_TRX_LINE_GL_DIST REC,
       FND_CURRENCIES           CURR,
       FND_DOCUMENT_SEQUENCES   SEQ,
       AR_SYSTEM_PARAMETERS     AR,
       RA_BATCH_SOURCES         BS,
       RA_CUST_TRX_TYPES        TYPES,
       HZ_CUST_ACCOUNTS         BILL_CUST,
       HZ_PARTIES               BILL_PARTY,
       HZ_CUST_ACCT_SITES       BILL_AS,
       HZ_CUST_SITE_USES        BILL_SU,
       HZ_PARTY_SITES           BILL_PS,
       HZ_LOCATIONS             BILL_LOC,
       RA_CUSTOMER_TRX          INV,
       RA_CUST_TRX_TYPES        INV_TT,
       HR_ALL_ORGANIZATION_UNITS HR,
       HR_ORGANIZATION_UNITS     HRL,
       RA_CUSTOMER_TRX          REL_T,
       RA_CUST_TRX_TYPES        REL_TT,
       AR_MEMO_LINES_B          ML
   WHERE
      TRX.customer_trx_id = p_customer_trx_id and
      TRX.customer_trx_id = LINES.customer_trx_id and
      TRX.previous_customer_trx_id = INV.customer_trx_id (+) and
      INV.cust_trx_type_id = INV_TT.cust_trx_type_id (+) and
      TRX.doc_sequence_id = SEQ.doc_sequence_id (+) and
      LINES.customer_trx_line_id = p_customer_trx_line_id and
      REC.customer_Trx_id = TRX.customer_Trx_id and
      REC.account_class = 'REC' and
      REC.latest_rec_flag = 'Y' and
      TRX.invoice_currency_code = CURR.currency_code and
      TRX.org_id = AR.org_id and
      TRX.batch_source_id = BS.batch_source_id and
      TRX.cust_trx_type_id = TYPES.cust_trx_type_id and
      TRX.bill_to_customer_id = BILL_CUST.cust_account_id and
      BILL_CUST.party_id = BILL_PARTY.party_id and
      BILL_CUST.cust_account_id = BILL_AS.cust_account_id and
      BILL_AS.cust_acct_site_id = BILL_SU.cust_acct_site_id and
      BILL_SU.site_use_id = TRX.bill_to_site_use_id and
      BILL_AS.party_site_id = BILL_PS.party_site_id and
      BILL_PS.location_id = BILL_LOC.location_id and
      LINES.warehouse_id = HR.organization_id (+) and
      TRX.org_id = HRL.organization_id and
      TRX.related_customer_trx_id = REL_T.customer_trx_id (+) and
      REL_T.cust_trx_type_id = REL_TT.cust_trx_type_id (+) and
      LINES.memo_line_id = ML.memo_line_id (+) and
      LINES.org_id = ML.org_id(+);

  IF PG_DEBUG in ('Y','C') THEN
  	arp_util.debug('Changed code by Arnab');
  END IF;

--bug6770861, Passing product category to ZX structure.
-- 6874006 - merged memo line/product category into main insert
--Bug6126010 begin, removed the existing query to find revenue CCID and added new query to retrieve CCID for REV account and passing it for tax calculation.

  IF PG_DEBUG in ('Y','C') THEN
     arp_util.debug('Fetching values of primary_salesrep_id, memo_line_id, inventory_item_id and cust_trx_type_id to use it for calculating CCID of REV account.');
  END IF;

  SELECT ctl.inventory_item_id, ctl.memo_line_id,
         ctx.cust_trx_type_id, ctx.primary_salesrep_id
  INTO   p_inv_item_id, p_memo_line_id, p_trx_type_id, p_salesrep_id
  FROM   ra_customer_trx_lines ctl, ra_customer_trx ctx
  WHERE  ctl.customer_trx_id = p_customer_trx_id
  AND    ctl.customer_trx_line_id = p_customer_trx_line_id
  AND    ctl.customer_trx_id=ctx.customer_trx_id;

  IF PG_DEBUG in ('Y','C') THEN
     arp_util.debug('Calling ARP_Auto_Accounting');
     arp_util.debug('customer_trx_id : '||p_customer_trx_id);
     arp_util.debug('customer_trx__line_id : '||p_customer_trx_line_id);
     arp_util.debug('trx_type_id : '||p_trx_type_id);
     arp_util.debug('primary_salesrep_id : '||p_salesrep_id);
     arp_util.debug('inventory_item_id : '||p_inv_item_id);
     arp_util.debug('Memo_line_id : '||p_memo_line_id);
  END IF;

      ARP_Auto_Accounting.do_autoaccounting(
                p_mode	           => 'G',
		p_account_class	   => 'REV',
		p_customer_trx_id  => p_customer_trx_id,
                p_customer_trx_line_id	    => p_customer_trx_line_id,
		p_cust_trx_line_salesrep_id => NULL,
		p_request_id		    => NULL,
		p_gl_date		    => NULL,
		p_original_gl_date	    => NULL,
		p_total_trx_amount	    => NULL,
		p_passed_ccid		    => NULL,
		p_force_account_set_no	    => NULL,
		p_cust_trx_type_id	    => p_trx_type_id,
		p_primary_salesrep_id	    => p_salesrep_id,
		p_inventory_item_id	    => p_inv_item_id,
		p_memo_line_id		    => p_memo_line_id,
		p_warehouse_id		    => p_warehouse_id, /* Bug 8758638 */
		p_ccid			    => p_ccid,
		p_concat_segments	    => p_conc_seg,
		p_failure_count	            => p_num_fail);
     /* Bug 8758638 */
     IF NVL(p_ccid,-1) = -1 THEN
        IF PG_DEBUG in ('Y','C') THEN
	   arp_util.debug('Failure Count ' || p_num_fail);
           arp_util.debug('EXCEPTION: ARP_Auto_Accounting returned 0'||
            ' and no ccid is being passed for Tax Calculation.');
        END IF;
        p_ccid := NULL;

     ELSE
        IF PG_DEBUG in ('Y','C') THEN
	    arp_util.debug('REV CCID passed for tax calculation :'|| p_ccid);
        END IF;

            ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ACCOUNT_CCID(1):= p_ccid;
     END IF;
--Bug6126010 End.

    l_trx_date := ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_DATE(1);

  /* 6874006 - set POO columns based on primary salesrep */
  IF p_salesrep_id IS NOT NULL AND
     p_salesrep_id <> -3
  THEN
      IF p_salesrep_id <> pg_salesrep_id
      THEN
         pg_salesrep_id := p_salesrep_id;

         IF PG_DEBUG in ('Y','C') THEN
            arp_util.debug('Fetching poo values for salesrep');
            arp_util.debug(' salesrep_id = ' || pg_salesrep_id);
            arp_util.debug(' org_id      = ' || pg_org_id);
         END IF;

         BEGIN
         select SR_PER.organization_id,      -- poo_party_id
                SR_HRL.location_id           -- poo_location_id
         into   pg_poo_party_id, pg_poo_location_id
         from   JTF_RS_SALESREPS          SR,
                PER_ALL_ASSIGNMENTS_F     SR_PER,
                HR_ORGANIZATION_UNITS     SR_HRL
         where  SR.salesrep_id = pg_salesrep_id
         and    SR.org_id      = pg_org_id
         and    SR.person_id = SR_PER.person_id
         and    l_trx_date BETWEEN
                         nvl(SR_PER.effective_start_date, l_trx_date)
                     AND nvl(SR_PER.effective_end_date, l_trx_date)
         and    NVL(SR_PER.primary_flag, 'Y') = 'Y'
         and    SR_PER.assignment_type = 'E'
         and    SR_PER.organization_id = SR_HRL.organization_id;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
              pg_poo_party_id    := NULL;
              pg_poo_location_id := NULL;
         END;
      END IF;
  ELSE
     pg_poo_party_id    := NULL;
     pg_poo_location_id := NULL;
  END IF;

  IF PG_DEBUG in ('Y','C') THEN
     arp_util.debug('poo_party_id := ' || pg_poo_party_id);
     arp_util.debug('poo_location_id = ' || pg_poo_location_id);
  END IF;

  /* Now copy POO values from cache or POA */
  IF pg_poo_party_id IS NOT NULL
  THEN
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.poo_party_id(1) :=
        pg_poo_party_id;
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.poo_location_id(1) :=
        pg_poo_location_id;
  ELSE
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.poo_party_id(1) :=
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.poa_party_id(1);
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.poo_location_id(1) :=
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.poa_location_id(1);
  END IF;

  /* 5235410 - Set max discount amount */
  ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CASH_DISCOUNT(1) :=
      ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_AMT(1) *
         arp_etax_util.get_discount_rate(p_customer_trx_id);

  /*  need to derive the ship_to_party_id and the ship_to_party_site_id
   *  from either the line or the header level if possible */

    IF ( l_line_ship_to_cust_id IS NOT NULL and
      l_line_ship_to_su_id IS NOT NULL) THEN
      l_cust_id := l_line_ship_to_cust_id;
      l_site_use_id := l_line_ship_to_su_id;
    ELSIF ( l_hdr_ship_to_cust_id IS NOT NULL and
      l_hdr_ship_to_su_id IS NOT NULL) THEN
      l_cust_id := l_hdr_ship_to_cust_id;
      l_site_use_id := l_hdr_ship_to_su_id;
    ELSE
      l_cust_id := NULL;
      l_site_use_id := NULL;

      -- ship_to_party_id
      ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_PARTY_ID(1) := NULL;
      -- rounding_ship_to_party_id
      ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ROUNDING_SHIP_TO_PARTY_ID(1)
                := NULL;
      -- ship_to_party_site_id
      ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_PARTY_SITE_ID(1)
             := NULL;
      -- rndg_ship_to_party_site_id
      ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.RNDG_SHIP_TO_PARTY_SITE_ID(1)
              := NULL;
      -- ship_to_location_id
      ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_LOCATION_ID(1) := NULL;

      ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_THIRD_PTY_ACCT_SITE_ID(1)
              := NULL;
    END IF;

    IF (l_cust_id IS NOT NULL and l_site_use_id IS NOT NULL) THEN

       /* 4666566 - set these fields */
       ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_THIRD_PTY_ACCT_ID(1) :=
          l_cust_id;
       ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_CUST_ACCT_SITE_USE_ID(1) :=
          l_site_use_id;

        SELECT
             CUST_ACCT.party_id,
             CUST_ACCT.party_id,
             ACCT_SITE.party_site_id,
             ACCT_SITE.party_site_id,
             LOC.location_id,
             ACCT_SITE.cust_acct_site_id
        INTO
           -- ship_to_party_id
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_PARTY_ID(1),
           -- rounding_ship_to_party_id
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ROUNDING_SHIP_TO_PARTY_ID(1),
           -- ship_to_party_site_id
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_PARTY_SITE_ID(1),
           -- rndg_ship_to_party_site_id
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.RNDG_SHIP_TO_PARTY_SITE_ID(1),
           -- ship_to_location_id
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_LOCATION_ID(1),
           /* 4666566 */
           -- ship_third_pty_acct_site_id (warehouse id)
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_THIRD_PTY_ACCT_SITE_ID(1)
        FROM
           hz_cust_accounts         CUST_ACCT,
           hz_parties               PARTY,
           hz_cust_acct_sites       ACCT_SITE,
           hz_cust_site_uses        SITE_USES,
           hz_party_sites           PARTY_SITE,
           hz_locations             LOC
        WHERE
           CUST_ACCT.cust_account_id = l_cust_id AND
           CUST_ACCT.party_id = PARTY.party_id AND
           CUST_ACCT.cust_account_id = ACCT_SITE.cust_account_id AND
           ACCT_SITE.cust_acct_site_id = SITE_USES.cust_acct_site_id AND
           SITE_USES.site_use_id = l_site_use_id AND
           ACCT_SITE.party_site_id = PARTY_SITE.party_site_id AND
           PARTY_SITE.location_id = LOC.location_id;

    END IF;

ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CTRL_TOTAL_HDR_TX_AMT(1) := NULL;
ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.RELATED_DOC_DATE(1) := NULL;
ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ROUNDING_SHIP_FROM_PARTY_ID(1) := NULL;
ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ROUNDING_BILL_FROM_PARTY_ID(1) := NULL;
ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.RNDG_SHIP_FROM_PARTY_SITE_ID(1) := NULL;
ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.RNDG_BILL_FROM_PARTY_SITE_ID(1) := NULL;
     /** Following is for tax only CMs **/
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CTRL_TOTAL_LINE_TX_AMT(1) := p_tax_amount;

   IF PG_DEBUG in ('Y','C') THEN
      arp_etax_services_pkg.print_ebt_plsql_vars;
      arp_util.debug('populate_ebt_plsql_tables(-)');
   END IF;
END  populate_ebt_plsql_tables;

/*=============================================================================
 |  PROCEDURE set_line_flags
 |
 |  DESCRIPTION
 |    Checks each of the attributes of an invoice line that can affect the
 |    tax amount calculated, and returns true for each field that has changed.
 |
 |  PARAMETERS:
 |         IN :  p_customer_trx_line_id
 |               p_item_line_rec
 |        OUT :  p_inventory_item_changed
 |               p_extended_amount_changed
 |               p_tax_exempt_flag_change
 |               p_tax_exempt_reason_changed
 |               p_tax_exempt_cert_changed
 |               p_memo_line_changed
 |               p_quantity_changed
 |               p_tax_code_changed
 |               p_warehouse_flag_changed
 |               p_ship_to_changed
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  13-JUN-2005     Debbie Sue Jancis   Created
 |
 *===========================================================================*/
PROCEDURE set_line_flags(
              p_customer_trx_line_id        IN  NUMBER,
              p_line_rec                    IN  ra_customer_trx_lines%rowtype,
              p_inventory_item_changed      OUT NOCOPY boolean,
              p_memo_line_changed           OUT NOCOPY boolean,
              p_quantity_changed            OUT NOCOPY boolean,
              p_extended_amount_changed     OUT NOCOPY boolean,
              p_tax_exempt_flag_changed     OUT NOCOPY boolean,
              p_tax_exempt_reason_changed   OUT NOCOPY boolean,
              p_tax_exempt_cert_changed     OUT NOCOPY boolean,
              p_tax_code_changed            OUT NOCOPY boolean,
              p_warehouse_flag_changed      OUT NOCOPY boolean,
              p_ship_to_changed             OUT NOCOPY boolean ) IS

  l_old_line_rec                ra_customer_trx_lines%rowtype;

  l_inventory_item_changed      BOOLEAN;
  l_memo_line_changed           BOOLEAN;
  l_quantity_changed            BOOLEAN;
  l_extended_amount_changed     BOOLEAN;
  l_tax_exempt_flag_changed     BOOLEAN;
  l_tax_exempt_reason_changed   BOOLEAN;
  l_tax_exempt_cert_changed     BOOLEAN;
  l_tax_code_changed            BOOLEAN;
  l_warehouse_flag_changed      BOOLEAN;
  l_ship_to_changed             BOOLEAN;

BEGIN
  arp_util.debug('ARP_ETAX_SERVICES_PKG.set_line_flags()+');
  arp_util.debug('p_cust_trx_line_id = ' || to_char(p_customer_trx_line_id));

  /*-----------------------------------------+
   |  Fetch the old record from the database |
   +-----------------------------------------*/

   arp_ctl_pkg.fetch_p(l_old_line_rec, p_customer_trx_line_id);

  /*--------------------------------------------------+
   |  Compare the fetched record with the new record  |
   +--------------------------------------------------*/

   -- pg_new_line_rec := p_line_rec;

   -- did inventory_item_id change?
   IF ( nvl(l_old_line_rec.inventory_item_id, 0) <>
        nvl(p_line_rec.inventory_item_id, 0)
       AND nvl(p_line_rec.inventory_item_id,0) <> AR_NUMBER_DUMMY ) THEN
      l_inventory_item_changed := TRUE;
      arp_standard.debug('inventory item id changed');
   ELSE
      l_inventory_item_changed := FALSE;
   END IF;

   -- did memo_line_id change?
   IF ( nvl(l_old_line_rec.memo_line_id, 0) <> nvl(p_line_rec.memo_line_id, 0)
       AND nvl(p_line_rec.memo_line_id,0) <> AR_NUMBER_DUMMY ) THEN
      l_memo_line_changed := TRUE;
      arp_standard.debug('memo line id changed');
   ELSE
      l_memo_line_changed := FALSE;
   END IF;

   -- did quantity_invoiced change?
   IF ( nvl(l_old_line_rec.quantity_invoiced, 0) <>
                           nvl(p_line_rec.quantity_invoiced, 0)
         AND nvl(p_line_rec.quantity_invoiced,0) <> AR_NUMBER_DUMMY ) THEN
      l_quantity_changed := TRUE;
      arp_standard.debug('quantity changed');
   ELSE
      l_quantity_changed := FALSE;
   END IF;

   -- did gross extended amount change?
   IF ( nvl(l_old_line_rec.gross_extended_amount,
            l_old_line_rec.extended_amount) =
        nvl(p_line_rec.gross_extended_amount, p_line_rec.extended_amount) AND
        pg_tax_amount_changed = FALSE) THEN
      l_extended_amount_changed := FALSE;
      arp_standard.debug('extended amount did not change');
   ELSE
      l_extended_amount_changed := TRUE;
      arp_standard.debug('extended amount chnged');
   END IF;

   -- did tax_exempt_flag change?
   IF ( nvl(l_old_line_rec.tax_exempt_flag, 'S') <>
                nvl(p_line_rec.tax_exempt_flag, 'S')
        AND nvl(p_line_rec.tax_exempt_flag, 'S') <> AR_FLAG_DUMMY )
   THEN
      l_tax_exempt_flag_changed := TRUE;
      arp_standard.debug('tax exempt flag chnged');
   ELSE
      l_tax_exempt_flag_changed := FALSE;
   END IF;

   -- did tax_exempt_reason_code change?
   IF ( nvl(l_old_line_rec.tax_exempt_reason_code, '0') <>
           nvl(p_line_rec.tax_exempt_reason_code, '0')
        AND nvl(p_line_rec.tax_exempt_reason_code, '0') <> AR_TEXT_DUMMY )
   THEN
       l_tax_exempt_reason_changed := TRUE;
      arp_standard.debug('tax exempt reason flag chnged');
   ELSE
       l_tax_exempt_reason_changed := FALSE;
   END IF;

   -- did tax_exempt_number change?
   IF ( nvl(l_old_line_rec.tax_exempt_number, '0') <>
               nvl(p_line_rec.tax_exempt_number, '0')
        AND nvl(p_line_rec.tax_exempt_number, '0') <> AR_TEXT_DUMMY )
   THEN
       l_tax_exempt_cert_changed := TRUE;
      arp_standard.debug('tax exempt cert chnged');
   ELSE
       l_tax_exempt_cert_changed := FALSE;
   END IF;

   -- did vat_tax_id or tax classification_code change?
        -- Added the if condition for historical transactions for the Bug Fix 6804913
      	IF (NVL(l_old_line_rec.historical_flag, 'Y') = 'Y') AND (l_old_line_rec.tax_classification_code IS NULL)
	THEN
          l_tax_code_changed := FALSE;
	ELSIF ( ( nvl(l_old_line_rec.vat_tax_id, 0) <> nvl(p_line_rec.vat_tax_id, 0)
                 AND nvl(p_line_rec.vat_tax_id,0) <> AR_NUMBER_DUMMY) OR
           ( nvl(l_old_line_rec.tax_classification_code, '0') <>
                 nvl(p_line_rec.tax_classification_code, '0') AND
             nvl(p_line_rec.tax_classification_code,'0') <> AR_TEXT_DUMMY))
     	THEN
          l_tax_code_changed := TRUE;
      	  arp_standard.debug('tax code changed');
	ELSE
          l_tax_code_changed := FALSE;
	END IF;

   -- did warehouse_id change?
   IF ( nvl(l_old_line_rec.warehouse_id, 0) <> nvl(p_line_rec.warehouse_id, 0)
          AND nvl(p_line_rec.warehouse_id,0) <> AR_NUMBER_DUMMY) THEN
      l_warehouse_flag_changed := TRUE;
      arp_standard.debug('warehouse flag changed');
   ELSE
      l_warehouse_flag_changed := FALSE;
   END IF;

   -- did ship to location change at the line level?
   IF ( nvl(l_old_line_rec.ship_to_site_use_id, 0) <>
            nvl(p_line_rec.ship_to_site_use_id, 0 )  AND
        nvl(p_line_rec.ship_to_site_use_id,0) <> AR_NUMBER_DUMMY) THEN
      l_ship_to_changed := TRUE;
      arp_standard.debug('ship to  changed');
   ELSE
      l_ship_to_changed := FALSE;
   END IF;

   --   do we need to check for GDF changes???

--   IF PG_DEBUG = 'Y' THEN
      arp_util_tax.debug('p_inventory_item_changed     : '||
                arp_trx_util.boolean_to_varchar2(l_inventory_item_changed));
      arp_util_tax.debug('p_memo_line_changed     : '||
                arp_trx_util.boolean_to_varchar2(l_memo_line_changed));
      arp_util_tax.debug('p_quantity_changed           : '||
                arp_trx_util.boolean_to_varchar2(l_quantity_changed));
      arp_util_tax.debug('p_extended_amount_changed    : ' ||
                arp_trx_util.boolean_to_varchar2(l_extended_amount_changed ));        arp_util_tax.debug('p_tax_exempt_flag_changed    : ' ||
                arp_trx_util.boolean_to_varchar2(l_tax_exempt_flag_changed ));        arp_util_tax.debug('p_tax_exempt_reason_changed  : ' ||
                arp_trx_util.boolean_to_varchar2(l_tax_exempt_reason_changed ));
      arp_util_tax.debug('p_tax_exempt_cert_changed    : ' ||
                arp_trx_util.boolean_to_varchar2(l_tax_exempt_cert_changed ));        arp_util_tax.debug('p_tax_code_changed     : '||
                arp_trx_util.boolean_to_varchar2(l_tax_code_changed));
      arp_util_tax.debug('p_warehouse_flag_changed     : '||
                arp_trx_util.boolean_to_varchar2(l_warehouse_flag_changed));
      arp_util_tax.debug('p_ship_to_changed     : '||
                arp_trx_util.boolean_to_varchar2(l_ship_to_changed));
--   END IF;

   p_inventory_item_changed    := l_inventory_item_changed;
   p_memo_line_changed         := l_memo_line_changed;
   p_quantity_changed          := l_quantity_changed;
   p_extended_amount_changed   := l_extended_amount_changed;
   p_tax_exempt_flag_changed   := l_tax_exempt_flag_changed;
   p_tax_exempt_reason_changed := l_tax_exempt_reason_changed;
   p_tax_exempt_cert_changed   := l_tax_exempt_cert_changed;
   p_tax_code_changed          := l_tax_code_changed;
   p_warehouse_flag_changed    := l_warehouse_flag_changed;
   p_ship_to_changed           := l_ship_to_changed;

   pg_extended_amount_changed   := l_extended_amount_changed;

   arp_util.debug('ARP_ETAX_SERVICES_PKG.set_line_flags()-');

 END set_line_flags;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    delete_tax_f_ctl_id                                                    |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    This routine will delete one or more tax lines given the invoice line  |
 |    of type LINE that they can all be linked too, returning old and new    |
 |    tax amounts.                                                           |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |                                                                           |
 | ARGUMENTS  : IN:  p_customer_trx_line_id                                  |
 |                   p_error_mode               -- default 'STANDARD'        |
 |              OUT: p_old_tax_amount                                        |
 |                   p_new_tax_amount                                        |
 |                                                                           |
 | NOTES
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     14-Jun-2005  Debbie Jancis     Created                                |
 |                                                                           |
 +===========================================================================*/
PROCEDURE delete_tax_f_ctl_id( p_customer_trx_line_id IN Number ) IS

cursor  s_tax_lines_for_inv_line( p_customer_trx_line_id in number ) IS
        SELECT  lines.customer_trx_line_id
        FROM   ra_customer_trx_lines lines
        WHERE  link_to_cust_trx_line_id = p_customer_trx_line_id
          AND  line_type = 'TAX';

BEGIN

  arp_util.debug('ARP_ETAX_SERVICES_PKG.delete_tax_f_ctl_id()+');

  FOR tax in s_tax_lines_for_inv_line( p_customer_trx_line_id )
   LOOP

  arp_util.debug('customer trx line id = ' || to_char(p_customer_Trx_line_id));
  arp_util.debug('assoc customer trx line id = ' ||
                  to_char(tax.customer_Trx_line_id));

     /*********************************************************************
      | Delete the account assignments and account sets associated with   |
      | this tax line.                                                    |
      *********************************************************************/

     arp_ctlgd_pkg.delete_f_ctl_id( tax.customer_trx_line_id, null, null );

     /*********************************************************************
      | Call the table handler to delete the tax record                   |
      *********************************************************************/

      arp_ctl_pkg.delete_p( tax.customer_trx_line_id );


   END LOOP;
  arp_util.debug('ARP_ETAX_SERVICES_PKG.delete_tax_f_ctl_id()-');

EXCEPTION
   WHEN OTHERS
     THEN
        IF PG_DEBUG = 'Y' THEN
        arp_util_tax.debug( 'EXCEPTION: arp_etax_services_pkg.delete_tax_f_ctl_id()');
        END IF;
      RAISE;

END delete_tax_f_ctl_id;


/*=============================================================================
 |  PROCEDURE  Before_Update_Line
 |
 |  DESCRIPTION
 |    Called from Invoice Line Entity handler.   This proceudre will
 |    check each of the attributes of an invoice line that can affect
 |    tax and will return TRUE in p_recalc_tax if any of those attributes
 |    have changed.
 |
 |  PARAMETERS:
 |         IN :  p_customer_trx_line_id
 |               p_item_line_rec
 |               p_error_mode
 |        OUT :  p_old_tax_amount
 |               p_new_tax_amount
 |               p_recalc_tax
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  13-JUN-2005     Debbie Sue Jancis   Created
 |
 *===========================================================================*/

PROCEDURE before_update_line(
              p_customer_trx_line_id   IN Number,
              p_line_rec               IN ra_customer_trx_lines%rowtype,
              p_recalc_tax            OUT NOCOPY BOOLEAN ) IS

   l_inventory_item_changed      BOOLEAN;
   l_memo_line_changed           BOOLEAN;
   l_quantity_changed            BOOLEAN;
   l_extended_amount_changed     BOOLEAN;
   l_tax_exempt_flag_changed     BOOLEAN;
   l_tax_exempt_reason_changed   BOOLEAN;
   l_tax_exempt_cert_changed     BOOLEAN;
   l_tax_code_changed            BOOLEAN;
   l_warehouse_flag_changed      BOOLEAN;
   l_ship_to_changed             BOOLEAN;
   l_trx_id                      NUMBER;

BEGIN
  arp_util.debug('ARP_ETAX_SERVICES_PKG.before_update_line()+');
  arp_util.debug('customer_trx_line_id = ' || to_char(p_customer_trx_line_id));

  arp_etax_services_pkg.set_line_flags(
                              p_customer_trx_line_id,
                              p_line_rec,
                              l_inventory_item_changed,
                              l_memo_line_changed,
                              l_quantity_changed,
                              l_extended_amount_changed,
                              l_tax_exempt_flag_changed,
                              l_tax_exempt_reason_changed,
                              l_tax_exempt_cert_changed,
                              l_tax_code_changed,
                              l_warehouse_flag_changed,
                              l_ship_to_changed);

  pg_line_changed := l_inventory_item_changed OR
                     l_memo_line_changed OR
                     l_quantity_changed OR
                     l_extended_amount_changed OR
                     l_tax_exempt_flag_changed OR
                     l_tax_exempt_reason_changed OR
                     l_tax_exempt_cert_changed OR
                     l_tax_code_changed OR
                     l_warehouse_flag_changed OR
                     l_ship_to_changed;

  IF (pg_line_changed) THEN
     -- need to delete tax lines and distributions associated with the line_id
     arp_etax_services_pkg.delete_tax_f_ctl_id (p_customer_trx_line_id);
  END IF;

  p_recalc_tax := pg_line_changed;

  arp_util.debug('ARP_ETAX_SERVICES_PKG.before_update_line()-');

END before_update_line;

/*=============================================================================
 |  FUNCTION  Mark_tax_lines_deleted()
 |
 |  DESCRIPTION
 |   This function will call the ETAX mark_tax_lines_deleted service.  This
 |   API assumes that the calling code controls the commit cycle.  This
 |   function will return a TRUE if the call to the ETAX service is
 |   successful, Otherwise, it will return FALSE.
 |
 |   This should be called per invoice line.
 |
 |  PARAMETERS:
 |         IN :  p_customer_trx_line_id
 |               p_customer_trx_id
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  14-JUN-2005     Debbie Sue Jancis   Created
 |
 *===========================================================================*/
FUNCTION Mark_Tax_Lines_Deleted( p_customer_trx_line_id IN Number,
                                p_customer_trx_id      IN Number)
                        RETURN BOOLEAN IS


 CURSOR TRX_Header IS
  SELECT *
    FROM ra_customer_trx
   WHERE customer_trx_id = p_customer_trx_id;

 l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
 l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;
 l_transaction_line_rec       zx_api_pub.transaction_line_rec_type;
 l_trx_header_rec             ra_customer_trx%ROWTYPE;

 l_return_status_service      VARCHAR2(4000);
 l_msg_count                  NUMBER;
 l_msg_data                   VARCHAR2(4000);
 l_msg                        VARCHAR2(4000);

 l_return_status              BOOLEAN := TRUE;
 l_success                    BOOLEAN;
BEGIN

  arp_util.debug('ARP_ETAX_SERVICES_PKG.Mark_Tax_Lines_Deleted()+');

  -- populate the trx header local record.
  BEGIN
     OPEN Trx_Header;
     FETCH Trx_Header INTO l_trx_header_rec;
     CLOSE Trx_Header;
  END;

  -- get event class and event type codes
  l_success := arp_etax_util.get_event_information(
          p_customer_trx_id  => p_customer_trx_id,
          p_action           => 'UPDATE',
          p_event_class_code => l_event_class_code,
          p_event_type_code  => l_event_type_code);

   arp_util.debug('customer trx id = ' || p_customer_trx_id);
   arp_util.debug('event class code = ' || l_event_class_code);
   arp_util.debug('event type code = ' || l_event_type_code);

   IF (l_success) THEN
       -- populate the transaction_line_rec for use in the tax service
       l_transaction_line_rec.internal_organization_id :=
                                            arp_global.sysparam.org_id;
       l_transaction_line_rec.application_id         := 222;
       l_transaction_line_rec.entity_code            := 'TRANSACTIONS';
       l_transaction_line_rec.event_class_code       := l_event_class_code;
       l_transaction_line_rec.event_type_code        := l_event_type_code;
       l_transaction_line_rec.trx_id                 := p_customer_trx_id;
       l_transaction_line_rec.trx_level_type         := 'LINE';
       l_transaction_line_rec.trx_line_id            := p_customer_trx_line_id;

     -- Call the ETAX API
     zx_api_pub.mark_tax_lines_deleted(
        p_api_version             => 1.0,
        p_init_msg_list           => FND_API.G_TRUE,
        p_commit                  => FND_API.G_FALSE,
        p_validation_level        => FND_API.G_VALID_LEVEL_FULL,
        p_transaction_line_rec    => l_transaction_line_rec,
        x_return_status           => l_return_status_service,
        x_msg_count               => l_msg_count,
        x_msg_data                => l_msg_data);

     -- verify the return status from the tax api.
     IF (l_return_status_service <> 'S') THEN  -- handle errors
         l_return_status := FALSE;
     END IF;
  ELSE
    RETURN FALSE;
  END IF;

  arp_util.debug('ARP_ETAX_SERVICES_PKG.Mark_Tax_Lines_Deleted()-');
  RETURN l_return_status;

EXCEPTION
  WHEN OTHERS THEN
      APP_EXCEPTION.RAISE_EXCEPTION;

END Mark_Tax_Lines_Deleted;

/*=============================================================================
 |  PROCEDURE  Before_Delete_Line
 |
 |  DESCRIPTION
 |    Called from Invoice Line Entity handler. This procedure will delete
 |    the tax lines from ra_Customer_Trx_lines and its associated accounting
 |    and call the etax api's to mark the records for deletion in the ZX tables
 |
 |  PARAMETERS:
 |         IN :  p_customer_trx_line_id
 |               p_customer_trx_id
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  14-JUN-2005     Debbie Sue Jancis   Created
 |
 *===========================================================================*/
PROCEDURE Before_Delete_Line( p_customer_trx_line_id IN Number,
                              p_customer_trx_id      IN Number) IS
l_success  BOOLEAN;
BEGIN

  arp_util.debug('ARP_ETAX_SERVICES_PKG.before_delete_line()+');

  -- delete tax line from ra_customer_Trx_lines and associated accting.

  arp_etax_services_pkg.delete_tax_f_ctl_id(
              p_customer_trx_line_id =>   p_customer_trx_line_id);

   l_success := arp_etax_services_pkg.Mark_Tax_Lines_Deleted (
                         p_customer_trx_line_id => p_customer_trx_line_id,
                         p_customer_trx_id      => p_customer_trx_id);

   IF (not l_success) THEN
    arp_util.debug('unable to mark tax for deletion');
   END IF;

  arp_util.debug('ARP_ETAX_SERVICES_PKG.before_delete_line()-');

END Before_Delete_Line;


PROCEDURE print_ebt_plsql_vars IS
BEGIN

  arp_util.debug(' internal_organization_id i:' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.INTERNAL_ORGANIZATION_ID(1) );

  arp_util.debug('application_id: ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.APPLICATION_ID(1) );

  arp_util.debug('entity_code : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ENTITY_CODE(1));

  arp_util.debug('event_class_code : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EVENT_CLASS_CODE(1));

  arp_util.debug('event_type_code : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EVENT_TYPE_CODE(1) );

   arp_util.debug('trx_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_ID(1));

   arp_util.debug('trx_date : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_DATE(1));

   arp_util.debug('ledger_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LEDGER_ID(1));

   arp_util.debug('trx_currency_code : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_CURRENCY_CODE(1));

   arp_util.debug('currency_conversion_date : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CURRENCY_CONVERSION_DATE(1));

   arp_util.debug('currency_conversion_rate : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CURRENCY_CONVERSION_RATE(1));

   arp_util.debug('currency_conversion_type : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CURRENCY_CONVERSION_TYPE(1));

   arp_util.debug('minimum_accountable_unit : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.MINIMUM_ACCOUNTABLE_UNIT(1));

   arp_util.debug('precision : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.PRECISION(1));

   arp_util.debug('legal_entity_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LEGAL_ENTITY_ID(1));

   arp_util.debug('rounding_ship_to_party_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ROUNDING_SHIP_TO_PARTY_ID(1));

   arp_util.debug('rounding_bill_to_party_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ROUNDING_BILL_TO_PARTY_ID(1));

   arp_util.debug('rndg_ship_to_party_site_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.RNDG_SHIP_TO_PARTY_SITE_ID(1));

   arp_util.debug('rndg_bill_to_party_site_id :' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.RNDG_BILL_TO_PARTY_SITE_ID(1));

   arp_util.debug('receivables_trx_type_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.RECEIVABLES_TRX_TYPE_ID(1));

   arp_util.debug('tax_reporting_flag : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TAX_REPORTING_FLAG(1));

   arp_util.debug('quote_flag : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.QUOTE_FLAG(1));

   arp_util.debug('trx_number : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_NUMBER(1));

   arp_util.debug('trx_description : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_DESCRIPTION(1));

   arp_util.debug('trx_communicated_date : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_COMMUNICATED_DATE(1));

   arp_util.debug('batch_source_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BATCH_SOURCE_ID(1));

   arp_util.debug('batch_source_name : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BATCH_SOURCE_NAME(1));

   arp_util.debug('doc_seq_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.DOC_SEQ_ID(1));

   arp_util.debug('doc_seq_name :' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.DOC_SEQ_NAME(1));

   arp_util.debug('doc_seq_value : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.DOC_SEQ_VALUE(1));

   arp_util.debug('trx_due_date : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_DUE_DATE(1));

   arp_util.debug('trx_type_description : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_TYPE_DESCRIPTION(1));

   arp_util.debug('trx_level_type : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LEVEL_TYPE(1));

   arp_util.debug('trx_line_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_ID(1));

   arp_util.debug('line_class : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_CLASS(1));

   arp_util.debug('line_level_action : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_LEVEL_ACTION(1));

   arp_util.debug('trx_shipping_date : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_SHIPPING_DATE(1));

   arp_util.debug('trx_line_type : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_TYPE(1));

   arp_util.debug('trx_line_date : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_DATE(1));

   arp_util.debug('line_amt_includes_tax_flag : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_AMT_INCLUDES_TAX_FLAG(1));

   arp_util.debug('line_amt : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_AMT(1));

   arp_util.debug('trx_line_quantity : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_QUANTITY(1));

   arp_util.debug('unit_price : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.UNIT_PRICE(1));

   arp_util.debug('exemption_control_flag : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EXEMPTION_CONTROL_FLAG(1));

   arp_util.debug('exempt_certificate_number : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EXEMPT_CERTIFICATE_NUMBER(1));

   arp_util.debug('exempt_reason : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EXEMPT_REASON_CODE(1));

   arp_util.debug('product_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.PRODUCT_ID(1));

   arp_util.debug('product_org_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.PRODUCT_ORG_ID(1));

   arp_util.debug('uom_code : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.UOM_CODE(1));

   arp_util.debug('fob_point : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.FOB_POINT(1));

   arp_util.debug('ship_to_party_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_PARTY_ID(1));

   arp_util.debug('ship_from_party_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_FROM_PARTY_ID(1));

   arp_util.debug('bill_to_party_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_TO_PARTY_ID(1));

   arp_util.debug('ship_to_party_site_id : ' ||
      ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_PARTY_SITE_ID(1));

   arp_util.debug('ship_to_location_id : ' ||
      ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_LOCATION_ID(1));

   arp_util.debug('bill_to_location_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_TO_LOCATION_ID(1));

   arp_util.debug('account_ccid : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ACCOUNT_CCID(1));

   arp_util.debug('output_tax_classification_code : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.OUTPUT_TAX_CLASSIFICATION_CODE(1));

   arp_util.debug('interface_entity_code : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.INTERFACE_ENTITY_CODE(1));

   arp_util.debug('interface_line_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.INTERFACE_LINE_ID(1));

   arp_util.debug('trx_line_number : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_NUMBER(1));

   arp_util.debug('historical_flag : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.HISTORICAL_FLAG(1));

   arp_util.debug('ctrl_hdr_tx_appl_flag : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CTRL_HDR_TX_APPL_FLAG(1));

   arp_util.debug('ship_third_pty_acct_site_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_THIRD_PTY_ACCT_SITE_ID(1));

   arp_util.debug('bill_third_pty_acct_site_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_THIRD_PTY_ACCT_SITE_ID(1));

   arp_util.debug('ship_third_pty_acct_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_THIRD_PTY_ACCT_ID(1));

   arp_util.debug('bill_third_pty_acct_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_THIRD_PTY_ACCT_ID(1));

   arp_util.debug('ship_to_cust_acct_site_use_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_CUST_ACCT_SITE_USE_ID(1));

   arp_util.debug('bill_to_cust_acct_site_use_id : ' ||
     ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_TO_CUST_ACCT_SITE_USE_ID(1));

END print_ebt_plsql_vars;

/*=============================================================================
 |  PROCEDURE - line_det_factors
 |
 |  DESCRIPTION
 |      Public function that will call the INSERT_LINE_DET_FACTORS or
 |      UPDATE_LINE_DET_FACTORS service
 |      This API assumes the calling code controls the commit cycle.
 |
 |  PARAMETERS
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  17-JUN-2005     Debbie Sue Jancis   Created
 |  16-AUG-2005     Jon Beckett         Introduced INSERT_NO_LINE and
 | 					INSERT_NO_TAX modes for lines where
 |					line amount or tax amount are zero.
 |  08-MAY-2006     M Raymond       5197390 - Added logic to support
 |                                     calls for lines with memo line of
 |                                     type 'TAX'
 |
 *===========================================================================*/
PROCEDURE Line_det_factors ( p_customer_trx_line_id IN Number,
                             p_customer_trx_id      IN Number,
                             p_mode                 IN VARCHAR2,
                             p_tax_amount	    IN NUMBER DEFAULT NULL) IS

   l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
   l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;
   l_transaction_line_rec       zx_api_pub.transaction_line_rec_type;

   l_return_status_service      VARCHAR2(4000);
   l_msg_count                  NUMBER;
   l_msg_data                   VARCHAR2(4000);
   l_msg_data_out               VARCHAR2(4000);
   l_mesg                       VARCHAR2(4000);
   l_success                    BOOLEAN;
   l_action                     VARCHAR2(12);
   l_line_level_action          VARCHAR2(30);
   l_tax_amount			NUMBER;

BEGIN

  arp_util.debug('ARP_ETAX_SERVICES_PKG.Line_det_factors()+');

  IF (p_mode IN ('INSERT','INSERT_NO_TAX','INSERT_NO_TAX_EVER',
                 'INSERT_NO_LINE')) THEN
     l_action := 'CREATE';
  ELSE
     l_action := 'UPDATE';
  END IF;

  l_tax_amount := NULL;

  IF (p_mode = 'INSERT_NO_TAX') THEN
     /* 5197390 - Changed to LINE_INFO_TAX_ONLY, was
            ALLOCATE_LINE_ONLY_ADJUSTMENT */
     l_line_level_action := 'LINE_INFO_TAX_ONLY';
  ELSIF (p_mode = 'INSERT_NO_TAX_EVER') THEN
     l_line_level_action := 'RECORD_WITH_NO_TAX';
  ELSIF (p_mode = 'INSERT_NO_LINE') THEN
     l_tax_amount := p_tax_amount;
     l_line_level_action := 'ALLOCATE_TAX_ONLY_ADJUSTMENT';
  ELSIF  (p_mode = 'INSERT') THEN
     l_line_level_action := 'CREATE';
  ELSE
     l_line_level_action := 'UPDATE';
  END IF;

  -- get event class and event type codes
  l_success := arp_etax_util.get_event_information(
          p_customer_trx_id  => p_customer_trx_id,
          p_action           => l_action,
          p_event_class_code => l_event_class_code,
          p_event_type_code  => l_event_type_code);

   arp_util.debug('customer trx id = ' || p_customer_trx_id);
   arp_util.debug('event class code = ' || l_event_class_code);
   arp_util.debug('event type code = ' || l_event_type_code);
   arp_util.debug('line level action = ' || l_line_level_action);

   IF (l_success) THEN
       -- populate the transaction_line_rec for use in the tax service
       l_transaction_line_rec.internal_organization_id := NULL;
       l_transaction_line_rec.application_id         :=  NULL;
       l_transaction_line_rec.entity_code            :=  NULL;
       l_transaction_line_rec.event_class_code       :=  NULL;
       l_transaction_line_rec.event_type_code        :=  NULL;
       l_transaction_line_rec.trx_id                 :=  NULL;
       l_transaction_line_rec.trx_level_type         :=  NULL;
       l_transaction_line_rec.trx_line_id            :=  NULL;

       /* initialize the plsql table */
       ZX_GLOBAL_STRUCTURES_PKG.INIT_TRX_LINE_DIST_TBL(1);

        arp_util.debug('calling populate_ebt_plsql_tables ');
        populate_ebt_plsql_tables(
                  p_customer_trx_id      => p_customer_trx_id,
                  p_customer_trx_line_id => p_customer_trx_line_id,
                  p_event_type_code      => l_event_type_code,
                  p_event_class_code     => l_event_class_code,
                  p_line_level_action    => l_line_level_action,
		  p_tax_amount           => l_tax_amount);

       IF (p_mode IN ('INSERT','INSERT_NO_TAX','INSERT_NO_LINE')) THEN
         ZX_API_PUB.insert_line_det_factors (
                         p_api_version        => 1.0,
                         p_init_msg_list      => FND_API.G_TRUE,
                         p_commit             => FND_API.G_FALSE,
			 p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
                         x_return_status      => l_return_status_service,
                         x_msg_count          => l_msg_count,
                         x_msg_data           => l_msg_data,
                         p_duplicate_line_rec => l_transaction_line_rec);
       else
         ZX_API_PUB.update_line_det_factors (
                         p_api_version        => 1.0,
                         p_init_msg_list      => FND_API.G_TRUE,
                         p_commit             => FND_API.G_FALSE,
			 p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
                         x_return_status      => l_return_status_service,
                         x_msg_count          => l_msg_count,
                         x_msg_data           => l_msg_data );
       end if;

          -- verify the return status from the tax api.
       IF (l_return_status_service <> 'S') THEN  -- handle errors
                 arp_util.debug('line_det_factors returned error');
        IF ( l_msg_count = 1 ) THEN
           -- then there is only 1 message raised by the API, and
           -- it has been sent out in the parameter x_msg_data.
           l_msg_data_out := l_msg_data;
           arp_util.debug('API failed with : ' || l_msg_data_out);
           l_mesg := l_msg_data_out;

        ELSIF (l_msg_count > 1) THEN
           -- the messages are on the stack and there is more then
           -- 1 so call them in a loop
           loop
             l_mesg := FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT,
                                       FND_API.G_FALSE);
             if (l_mesg IS NULL) THEN
                EXIT;
             end if;
             arp_util.debug('API failed with : ' || l_mesg);
           end loop;
        END IF;

        -- raise error
        /* 4919401 - Added generic message fetch */
        FND_MESSAGE.SET_NAME('FND', 'FND_GENERIC_MESSAGE');
        FND_MESSAGE.SET_TOKEN('MESSAGE', l_mesg);
        FND_MSG_PUB.ADD;

        APP_EXCEPTION.RAISE_EXCEPTION;
     END IF;
   ELSE
     arp_util.debug('ERROR getting EVENT INFORMATION');
   END IF;
  arp_util.debug('ARP_ETAX_SERVICES_PKG.Line_det_factors()-');

  END line_det_factors;

/*=============================================================================
 |  PROCEDURE - Header_det_factors
 |
 |  DESCRIPTION
 |      Public function that will call the UPDATE_DET_FACTORS_HDR
 |      This API assumes the calling code controls the commit cycle.
 |
 |  PARAMETERS
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  20-JUN-2005     Debbie Sue Jancis   Created
 |  04-NOV-2005     M Raymond           4713671 - initialize header det
 |                                       factor structure to not override
 |                                       ship to (and other) columns
 |  29-NOV-2005     M Raymond           4763946 - init all header det factor
 |                                       parameters to G_MISS values.
 |  09-JAN-2006     M Raymond           4928019 - handle void trx for etax
 *===========================================================================*/
PROCEDURE Header_det_factors ( p_customer_trx_id  IN Number,
                               p_mode             IN VARCHAR2,
                               x_return_status    OUT NOCOPY VARCHAR2,
                               x_msg_count        OUT NOCOPY NUMBER,
                               x_msg_data         OUT NOCOPY VARCHAR2 ) IS

l_hdr_det_factors_rec   zx_api_pub.header_det_factors_rec_type;
l_hdr_ship_to_cust_id   RA_CUSTOMER_TRX.ship_to_customer_id%TYPE;
l_hdr_ship_to_su_id   RA_CUSTOMER_TRX.ship_to_site_use_id%TYPE;
l_action VARCHAR2(12);
l_success BOOLEAN;
l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;
l_llst_exists   NUMBER := 0; -- 4713671
BEGIN
   arp_util.debug('arp_etax_services_pkg.Header_det_factors(+)');

   /* Initializing return status ..*/
   x_return_status := FND_API.G_RET_STS_SUCCESS;

   IF (p_mode = 'UPDATE') THEN
      l_action := 'UPDATE';

     /* 4713671/4763946 initialize various columns in structure
        to prevent overlay of data in update det call */
     l_hdr_det_factors_rec.trx_date := FND_API.G_MISS_DATE;
     l_hdr_det_factors_rec.trx_doc_revision  := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.ledger_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.trx_currency_code := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.currency_conversion_date := FND_API.G_MISS_DATE;
     l_hdr_det_factors_rec.currency_conversion_rate := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.currency_conversion_type := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.minimum_accountable_unit := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.precision := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.legal_entity_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.rounding_ship_to_party_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.rounding_ship_from_party_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.rounding_bill_to_party_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.rounding_bill_from_party_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.rndg_ship_to_party_site_id  := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.rndg_ship_from_party_site_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.rndg_bill_from_party_site_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.rndg_bill_to_party_site_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.bill_to_cust_acct_site_use_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.ship_third_pty_acct_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.bill_third_pty_acct_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.ship_third_pty_acct_site_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.bill_third_pty_acct_site_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.ship_to_cust_acct_site_use_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.provnl_tax_determination_date := FND_API.G_MISS_DATE;
     l_hdr_det_factors_rec.establishment_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.trx_batch_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.application_doc_status := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.receivables_trx_type_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.related_doc_application_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.related_doc_entity_code := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.related_doc_event_class_code := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.related_doc_trx_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.related_doc_number := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.related_doc_date := FND_API.G_MISS_DATE;
     l_hdr_det_factors_rec.default_taxation_country := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.tax_reporting_flag := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.port_of_entry_code := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.ship_to_party_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.ship_from_party_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.poa_party_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.poo_party_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.bill_to_party_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.bill_from_party_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.ship_from_party_site_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.ship_to_party_site_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.poa_party_site_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.poo_party_site_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.bill_to_party_site_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.bill_from_party_site_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.ship_to_location_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.ship_from_location_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.poa_location_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.poo_location_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.bill_to_location_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.bill_from_location_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.document_sub_type := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.quote_flag := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.ctrl_total_hdr_tx_amt := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.applied_to_trx_number := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.trx_number := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.trx_description := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.trx_communicated_date := FND_API.G_MISS_DATE;
     l_hdr_det_factors_rec.batch_source_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.batch_source_name := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.doc_seq_id := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.doc_seq_name := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.doc_seq_value := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.trx_due_date := FND_API.G_MISS_DATE;
     l_hdr_det_factors_rec.trx_type_description := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.supplier_tax_invoice_number := FND_API.G_MISS_CHAR;
     l_hdr_det_factors_rec.supplier_tax_invoice_date := FND_API.G_MISS_DATE;
     l_hdr_det_factors_rec.supplier_exchange_rate := FND_API.G_MISS_NUM;
     l_hdr_det_factors_rec.tax_invoice_date := FND_API.G_MISS_DATE;
     l_hdr_det_factors_rec.tax_invoice_number := FND_API.G_MISS_CHAR;

     -- get event class and event type codes
     l_success := arp_etax_util.get_event_information(
          p_customer_trx_id  => p_customer_trx_id,
          p_action           => l_action,
          p_event_class_code => l_event_class_code,
          p_event_type_code  => l_event_type_code);

      arp_util.debug('customer trx id = ' || p_customer_trx_id);
      arp_util.debug('event class code = ' || l_event_class_code);
      arp_util.debug('event type code = ' || l_event_type_code);

      IF (l_success) THEN
      --  need to select from the table as items have been posted to
      --  populate the header_det_factors_rec_type

         SELECT
           TRX.org_id,                       -- internal_organization_id
           222,                              -- application_id
           'TRANSACTIONS',                   -- entity_code
           l_event_class_code,               -- event_class_code
           l_event_type_code,                -- event_type_code
           p_customer_trx_id,                -- trx_id
           TRX.trx_date,                     -- trx_date
           AR.set_of_books_id,               -- ledger_id
           TRX.invoice_currency_code,        -- trx_currency_code
           TRX.exchange_date,                -- currency_conversion_date
           TRX.exchange_rate,                -- currency_conversion_rate
           TRX.exchange_rate_type,           -- currency_conversion_type
           CURR.minimum_accountable_unit,    -- minimum_accountable_unit
           CURR.precision,                   -- precision
           TRX.legal_entity_id,              -- legal_entity_id
           BILL_CUST.party_id,               -- rounding_bill_to_party_id
           BILL_AS.party_site_id,            -- rndg_bill_to_party_site_id
           TRX.cust_trx_type_id,             -- receivables_trx_type_id
           'Y',                              -- tax_reporting_flag
           BILL_CUST.party_id,              -- bill_to_party_id
           BILL_AS.party_site_id,           -- bill_to_party_site_id
           BILL_LOC.location_id,            -- bill_to_location_id
           TRX.trx_number,                   -- trx_number
           substrb(TRX.comments,1,240),      -- trx_description
           TRX.printing_original_date,       -- trx_communicated_date
           TRX.batch_source_id,              -- batch_source_id
           BS.NAME,                          -- batch_source_name
           TRX.doc_sequence_id,              -- doc_seq_id
	   -- bug 6806843
           --TYPES.name,                       -- doc_seq_name
	   SEQ.name,                          -- doc_seq_name
           TRX.doc_sequence_value,           -- doc_seq_value
           TRX.term_due_date,                -- trx_due_date
           TYPES.description,                -- trx_type_description
           TRX.ship_to_customer_id,
           TRX.ship_to_site_use_id,
           BILL_SU.site_use_id,             --bill_to_cust_acct_site_use_id
           DECODE(TRX.status_trx,'VD','VD',NULL),
           TRX.bill_to_customer_id,         --bill_third_pty_acct_id
           BILL_AS.cust_acct_site_id        --bill_third_pty_acct_site_id
         INTO
           l_hdr_det_factors_rec.internal_organization_id,
           l_hdr_det_factors_rec.application_id,
           l_hdr_det_factors_rec.entity_code,
           l_hdr_det_factors_rec.event_class_code,
           l_hdr_det_factors_rec.event_type_code,
           l_hdr_det_factors_rec.trx_id,
           l_hdr_det_factors_rec.trx_date,
           l_hdr_det_factors_rec.ledger_id,
           l_hdr_det_factors_rec.trx_currency_code,
           l_hdr_det_factors_rec.currency_conversion_date,
           l_hdr_det_factors_rec.currency_conversion_rate,
           l_hdr_det_factors_rec.currency_conversion_type,
           l_hdr_det_factors_rec.minimum_accountable_unit,
           l_hdr_det_factors_rec.precision,
           l_hdr_det_factors_rec.legal_entity_id,
           l_hdr_det_factors_rec.rounding_bill_to_party_id,
           l_hdr_det_factors_rec.rndg_bill_to_party_site_id,
           l_hdr_det_factors_rec.receivables_trx_type_id,
           l_hdr_det_factors_rec.tax_reporting_flag,
           l_hdr_det_factors_rec.bill_to_party_id,
           l_hdr_det_factors_rec.bill_to_party_site_id,
           l_hdr_det_factors_rec.bill_to_location_id,
           l_hdr_det_factors_rec.trx_number,
           l_hdr_det_factors_rec.trx_description,
           l_hdr_det_factors_rec.trx_communicated_date,
           l_hdr_det_factors_rec.batch_source_id,
           l_hdr_det_factors_rec.batch_source_name,
           l_hdr_det_factors_rec.doc_seq_id,
           l_hdr_det_factors_rec.doc_seq_name,
           l_hdr_det_factors_rec.doc_seq_value,
           l_hdr_det_factors_rec.trx_due_date,
           l_hdr_det_factors_rec.trx_type_description,
           l_hdr_ship_to_cust_id,
           l_hdr_ship_to_su_id,
           l_hdr_det_factors_rec.bill_to_cust_acct_site_use_id,
           l_hdr_det_factors_rec.application_doc_status,
           l_hdr_det_factors_rec.bill_third_pty_acct_id,
           l_hdr_det_factors_rec.bill_third_pty_acct_site_id
           FROM
             RA_CUSTOMER_TRX          TRX,
             FND_CURRENCIES           CURR,
	     FND_DOCUMENT_SEQUENCES   SEQ,
             AR_SYSTEM_PARAMETERS     AR,
             RA_BATCH_SOURCES         BS,
             RA_CUST_TRX_TYPES        TYPES,
             HZ_CUST_ACCOUNTS         BILL_CUST,
             HZ_PARTIES               BILL_PARTY,
             HZ_CUST_ACCT_SITES       BILL_AS,
             HZ_CUST_SITE_USES        BILL_SU,
             HZ_PARTY_SITES           BILL_PS,
             HZ_LOCATIONS             BILL_LOC
         WHERE
            TRX.customer_trx_id = p_customer_trx_id and
            TRX.invoice_currency_code = CURR.currency_code and
            TRX.org_id = AR.org_id and
            TRX.batch_source_id = BS.batch_source_id and
            TRX.cust_trx_type_id = TYPES.cust_trx_type_id and
	    TRX.doc_sequence_id = SEQ.doc_sequence_id (+) and
            TRX.bill_to_customer_id = BILL_CUST.cust_account_id and
            BILL_CUST.party_id = BILL_PARTY.party_id and
            BILL_CUST.cust_account_id = BILL_AS.cust_account_id and
            BILL_AS.cust_acct_site_id = BILL_SU.cust_acct_site_id and
            BILL_SU.site_use_id = TRX.bill_to_site_use_id and
            BILL_AS.party_site_id = BILL_PS.party_site_id AND
            BILL_PS.location_id = BILL_LOC.location_id;

        /* Detect line-level ship to info first, used to
           determine if the user is nulling the ship to
           out, or it is not changed */
           SELECT count(*)
           INTO   l_llst_exists
           FROM   ra_customer_trx_lines
           WHERE  customer_trx_id = p_customer_trx_id
           AND    line_type = 'LINE'
           AND    ship_to_customer_id IS NOT NULL
           AND    ship_to_site_use_id IS NOT NULL;

        IF l_llst_exists > 0
        THEN
           /* Line level ship_to values exist, Ignore
              changes to header-level ship-to */
           NULL;
        ELSE
           IF (l_hdr_ship_to_cust_id IS NULL OR
               l_hdr_ship_to_su_id IS NULL)
           THEN
              /* Header ship_to is now null, clear
                 what was there in LDF */
              l_hdr_det_factors_rec.ship_to_party_id           := NULL;
              l_hdr_det_factors_rec.rounding_ship_to_party_id  := NULL;
              l_hdr_det_factors_rec.ship_to_party_site_id      := NULL;
              l_hdr_det_factors_rec.rndg_ship_to_party_site_id := NULL;
              l_hdr_det_factors_rec.ship_to_location_id        := NULL;
              l_hdr_det_factors_rec.ship_to_cust_acct_site_use_id:= NULL;

           ELSE
              /* Header ship_to is populated, set
                 LDF accordingly */
             SELECT
              CUST_ACCT.party_id,
              CUST_ACCT.party_id,
              ACCT_SITE.party_site_id,
              ACCT_SITE.party_site_id,
              LOC.location_id,
              SITE_USES.site_use_id
             INTO
              l_hdr_det_factors_rec.ship_to_party_id,
              l_hdr_det_factors_rec.rounding_ship_to_party_id,
              l_hdr_det_factors_rec.ship_to_party_site_id,
              l_hdr_det_factors_rec.rndg_ship_to_party_site_id,
              l_hdr_det_factors_rec.ship_to_location_id,
              l_hdr_det_factors_rec.ship_to_cust_acct_site_use_id
             FROM
              hz_cust_accounts         CUST_ACCT,
              hz_parties               PARTY,
              hz_cust_acct_sites       ACCT_SITE,
              hz_cust_site_uses        SITE_USES,
              hz_party_sites           PARTY_SITE,
              hz_locations             LOC
             WHERE
              CUST_ACCT.cust_account_id = l_hdr_ship_to_cust_id AND
              CUST_ACCT.party_id = PARTY.party_id AND
              CUST_ACCT.cust_account_id = ACCT_SITE.cust_account_id AND
              ACCT_SITE.cust_acct_site_id = SITE_USES.cust_acct_site_id AND
              SITE_USES.site_use_id = l_hdr_ship_to_su_id AND
              ACCT_SITE.party_site_id = PARTY_SITE.party_site_id AND
              PARTY_SITE.location_id = LOC.location_id;

           END IF; -- end header is null
        END IF; -- end llst exists
      ELSE
        arp_util.debug('ERROR getting EVENT INFORMATION');
      END IF;

     --  need to call the tax api
     zx_api_pub.update_det_factors_hdr(
            p_api_version         => 1.0,
            p_init_msg_list       => FND_API.G_TRUE,
            p_commit              => FND_API.G_FALSE,
            p_validation_level    => FND_API.G_VALID_LEVEL_FULL,
            x_return_status       => x_return_status,
            x_msg_count           => x_msg_count,
            x_msg_data            => x_msg_data,
            p_hdr_det_factors_rec => l_hdr_det_factors_rec
         );

  END IF;
   arp_util.debug('arp_etax_services_pkg.Header_det_factors(-)');

END Header_det_factors;

/*=============================================================================
 |  FUNCTION - Calculate_tax()
 |
 |  DESCRIPTION
 |      Public function that will call the calculate_tax service for
 |      calculation and recalculation.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  14-Apr-2005     Debbie Sue Jancis   Created
 |  21-JUL-2006     M Raymond           5211848 - added call to arp_rounding
 |  04-OCT-2006     M Raymond           5457495 - cache and honor tax
 |                                        account overrides
 *===========================================================================*/
 PROCEDURE Calculate_tax (p_customer_trx_id IN NUMBER,
                         p_action IN VARCHAR2,
                         x_return_status OUT NOCOPY VARCHAR2,
                         x_msg_count OUT NOCOPY NUMBER,
                         x_msg_data OUT NOCOPY VARCHAR2 ) IS

    l_transaction_rec            zx_api_pub.transaction_rec_type;

    l_return_status_service             VARCHAR2(4000);
    l_doc_level_recalc_flag             VARCHAR2(1);

    l_event_class_code                  VARCHAR2(80);
    l_event_type_code                   VARCHAR2(80);
    l_success                           BOOLEAN;
    l_ccid                              NUMBER;
    l_concat_segments                   VARCHAR2(2000);
    l_num_failed_dist_rows              NUMBER;
    l_rows                              NUMBER;
--Added for Bug5125882
    l_is_reg_cm                         NUMBER;

--Added for bug 5211848 (call to arp_rounding)
    pg_base_precision            fnd_currencies.precision%type;
    pg_base_min_acc_unit         fnd_currencies.minimum_accountable_unit%type;
    pg_trx_header_level_rounding ar_system_parameters.trx_header_level_rounding%type;
    l_error_message              VARCHAR2(128);
    l_dist_count                 NUMBER;
    l_rules_check_flag           VARCHAR2(1);
    l_account_set_flag           VARCHAR2(1);
    l_rtn                        NUMBER;
    l_xla_ev_rec	         ARP_XLA_EVENTS.XLA_EVENTS_TYPE;
 BEGIN
   arp_util.debug('ARP_ETAX_SERVICES_PKG.Calculate_tax(+)');
   arp_util.debug('p_action = ' || p_action);
   
   FND_FILE.PUT_LINE(FND_FILE.LOG,'ARP_ETAX_SERVICES_PKG.Calculate_tax(+)');
   FND_FILE.PUT_LINE(FND_FILE.LOG,'p_action = ' || p_action);

   /* initializing precision, mau, hdr level rdn */
   pg_base_precision := arp_trx_global.system_info.base_precision;
   pg_base_min_acc_unit := arp_trx_global.system_info.base_min_acc_unit;
   pg_trx_header_level_rounding :=
       arp_global.sysparam.trx_header_level_rounding;

   /* Initializing return status ..*/
   x_return_status := FND_API.G_RET_STS_SUCCESS;

   -- get event class code
    l_success := arp_etax_util.get_event_information(
                 p_customer_trx_id => p_customer_trx_id,
                 p_action => p_action,
                 p_event_class_code => l_event_class_code,
                 p_event_type_code => l_event_type_code);

    arp_util.debug('customer trx id = ' || p_customer_trx_id);
    arp_util.debug('action = ' || p_action);
    arp_util.debug('event class code = ' || l_event_class_code);
    arp_util.debug('event type code = ' || l_event_type_code);
	
	FND_FILE.PUT_LINE(FND_FILE.LOG,'p_action: ' || p_action);
	FND_FILE.PUT_LINE(FND_FILE.LOG,'l_event_class_code: ' || l_event_class_code);
	FND_FILE.PUT_LINE(FND_FILE.LOG,'l_event_type_code: ' || l_event_type_code);

    IF (l_success) THEN
      /* populate transaction rec type */
       l_transaction_rec.internal_organization_id := arp_global.sysparam.org_id;       l_transaction_rec.application_id           := 222;
       l_transaction_rec.entity_code              := 'TRANSACTIONS';
       l_transaction_rec.event_class_code         := l_event_class_code;
       l_transaction_rec.event_type_code          := l_event_type_code;
       l_transaction_rec.trx_id                   := p_customer_trx_id;

       /* initialize the pl/sql table. We do not need to populate this
          table if we are calling calculate tax at commit time.  */
       ZX_GLOBAL_STRUCTURES_PKG.INIT_TRX_LINE_DIST_TBL(1);
	   
	   FND_FILE.PUT_LINE(FND_FILE.LOG,'--Before calling record_tax_accounts, l_event_class_code: ' || l_event_class_code || ', l_event_type_code: ' || l_event_type_code);

       /* 5457495 - cache tax accounting for use later */
       record_tax_accounts(p_customer_trx_id);
	   FND_FILE.PUT_LINE(FND_FILE.LOG,'--After calling record_tax_accounts--');

       /* 5152340 - Remove AR tax lines prior to calculate call */
	   FND_FILE.PUT_LINE(FND_FILE.LOG,'--Before calling arp_etax_util.delete_tax_lines_from_ar--');
       arp_etax_util.delete_tax_lines_from_ar(p_customer_trx_id);
	   FND_FILE.PUT_LINE(FND_FILE.LOG,'--After calling arp_etax_util.delete_tax_lines_from_ar--');

       /* call Tax */
       arp_util.debug('calling ZX api to calculate tax');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Before calling zx_api_pub.calculate_tax--');
       zx_api_pub.calculate_tax(
             p_api_version           => 1.0,
             p_init_msg_list         => FND_API.G_TRUE,
             p_commit                => FND_API.G_FALSE,
             p_validation_level      => FND_API.G_VALID_LEVEL_FULL,
             p_transaction_rec       => l_transaction_rec,
             p_quote_flag            => 'N',
             p_data_transfer_mode    => 'WIN',
             x_return_status         => x_return_status,
             x_msg_count             => x_msg_count,
             x_msg_data              => x_msg_data,
             x_doc_level_recalc_flag => l_doc_level_recalc_flag );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'After calling zx_api_pub.calculate_tax x_return_status: ' 
		          || x_return_status || ', x_msg_count: ' || x_msg_count || ', : x_msg_data' || x_msg_data || ', l_doc_level_recalc_flag:' || l_doc_level_recalc_flag);

        arp_util.debug('return status service = ' || x_return_status);

        IF (x_return_status = FND_API.G_RET_STS_SUCCESS) THEN
           --  insert Tax records into ra_customer_trx_lines based upon
           --  customer trx id
           arp_util.debug('calling build_ar_tax_lines ...');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Before calling arp_etax_util.build_ar_tax_lines: customer_trx_id: ' || p_customer_trx_id || ', rows_inserted: ' || l_rows);
           arp_etax_util.build_ar_tax_lines(
                    p_customer_trx_id  => p_customer_trx_id,
                    p_rows_inserted    => l_rows);

           IF l_rows > 0
           THEN

             /* 5125882 - This routine is called upon completion of
                credit memos (happens way after arp_credit_memo_module
                call).  So we need to check the use_inv_acct profile
                and do an insert (like CMM code) if the profile is yes
                and otherwise call autoaccounting */

	    /*GGADHAMS 5125882 Added this to check whether the CM is Regular
	      or On Account. If it is a  On Account we call autoaccounting
	      else if use_inv_acct profile set to Y we copy from the Invoice
              otherwise we  use auotaccounting*/

            select previous_customer_trx_id,
                   DECODE(invoicing_rule_id, NULL, 'N', 'Y')
	    into l_is_reg_cm,
                 l_rules_check_flag
 	    from ra_customer_trx
	    where customer_trx_id = p_customer_trx_id;


             IF l_event_class_code = 'CREDIT_MEMO' and
                use_invoice_accounting and
	        l_is_reg_cm IS  NOT NULL
             THEN
			    FND_FILE.PUT_LINE(FND_FILE.LOG,'Before calling copy_inv_tax_dists for trx_id: ' || p_customer_trx_id);
                copy_inv_tax_dists(p_customer_trx_id);
			    FND_FILE.PUT_LINE(FND_FILE.LOG,'After calling copy_inv_tax_dists');
             ELSE

                BEGIN
                  -- need to call autoaccounting for these lines:
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Before calling ARP_AUTO_ACCOUNTING.do_autoaccounting--');   

                  ARP_AUTO_ACCOUNTING.do_autoaccounting( 'I', -- p_mode
                             'TAX', --p_account_class
                             p_customer_trx_id, -- p_customer_trx_id
                             NULL, -- p_customer_trx_line_id
                             NULL, -- p_cust_trx_line_salesrep_id
                             null, --p_request_id
                             NULL, --p_gl_date
                             NULL, --p_original_gl_date
                             null, --p_total_trx_amount
                             null, --p_passed_ccid,
                             null, --p_force_account_set_no
                             null, --p_cust_trx_type_id
                             null, --p_primary_salesrep_id,
                             null, --p_inventory_item_id,
                             null, --p_memo_line_id,
                             l_ccid, --p_ccid
                             l_concat_segments, --p_concat_segments
                             l_num_failed_dist_rows ); --p_failure_count

                EXCEPTION
                   WHEN arp_auto_accounting.no_ccid THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION in calling arp_auto_accounting.no_ccid: ' || SQLERRM);   
                      fnd_message.set_name('AR', 'ARP_AUTO_ACCOUNTING.NO_CCID');
                   WHEN NO_DATA_FOUND THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION in calling arp_auto_accounting.no_ccid NO_DATA_FOUND: ' || SQLERRM);   
                      null;
                   WHEN OTHERS THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'EXCEPTION in calling arp_auto_accounting.no_ccid WHEN OTHERS: ' || SQLERRM);   
                      RAISE;
                END;

                /* 7131147 - recreate the tax accounting dists */
                IF l_rules_check_flag = 'Y'
                THEN
                   SELECT account_set_flag
                   INTO   l_account_set_flag
                   FROM   ra_cust_trx_line_gl_dist
                   WHERE  customer_trx_id = p_customer_trx_id
                   AND    account_class = 'REC'
                   AND    latest_rec_flag = 'Y';

                   IF l_account_set_flag = 'N'
                   THEN
                      /* This executes if transaction has rules,
                          and the lines have already been generated */
                      l_rtn := arp_auto_rule.create_other_tax(
                                  p_trx_id => p_customer_trx_id,
                                  p_base_precision => pg_base_precision ,
                   	          p_bmau => pg_base_min_acc_unit,
                                  p_ignore_rule_flag => 'Y');

                      /* Call SLA to stamp the event ids on new rows */
                      l_xla_ev_rec.xla_from_doc_id := p_customer_trx_id;
                      l_xla_ev_rec.xla_to_doc_id := p_customer_trx_id;
                      l_xla_ev_rec.xla_doc_table := 'CT';
                      l_xla_ev_rec.xla_mode := 'O';
                      l_xla_ev_rec.xla_call := 'D';
                      arp_xla_events.create_events(l_xla_ev_rec);
                   END IF;
                END IF;
             END IF;

             /* 5457495 - Replace resulting code_combination_ids
                with previous ones if any existed.  Note that
                we have made a concious decision to always use
                previously existing accounts when possible
                and we do so if the tax values and salesrep
                match. */
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Before calling replace_tax_accounts');
             replace_tax_accounts;
             FND_FILE.PUT_LINE(FND_FILE.LOG,'After calling replace_tax_accounts');

             /* 5211848 - Once we insert accounting distributions,
                 we must call arp_rounding to fix the amounts on
                 the REC dist to reflect the new tax */
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Before calling arp_rounding.correct_dist_rounding_errors');   
             IF  arp_rounding.correct_dist_rounding_errors(
					NULL,
					p_customer_trx_id ,
                   			NULL,
                   			l_dist_count,
                   			l_error_message ,
                   			pg_base_precision ,
                   			pg_base_min_acc_unit ,
                   			'ALL' ,
                   			l_rules_check_flag,
                   			'N' ,
                   			pg_trx_header_level_rounding ,
                   			'N',
                   			'N') = 0 -- FALSE
             THEN
                arp_util.debug('EXCEPTION:  arp_etax_services_pkg.calculate_tax()');
                arp_util.debug(l_error_message);
                fnd_message.set_name('AR', 'AR_ROUNDING_ERROR');
                fnd_message.set_token('ROUTINE','ARP_ETAX_SERVICES_PKG.CALCULATE_TAX');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in ARP_ETAX_SERVICES_PKG.Calculate_tax: ' || SQLERRM);   
                APP_EXCEPTION.raise_exception;
             END IF;
             /* end 5211848 */
           END IF; -- l_rows
         ELSE							-- Bug7300346
         	x_return_status := FND_API.G_RET_STS_ERROR;	-- Bug7300346
         END IF;
   ELSE
     arp_standard.debug('could not get an event class code');
   END IF;

   arp_util.debug('ARP_ETAX_SERVICES_PKG.Calculate_tax(-)');
 Exception
   when others then
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in ARP_ETAX_SERVICES_PKG.Calculate_tax: ' || SQLERRM);   
 END Calculate_tax;

/*=============================================================================
 |  FUNCTION - Get_Tax_Action()
 |
 |  DESCRIPTION
 |    This function will be called at commit time before the table handers
 |    to determine if data exists for this transaction before current
 |    actions.  IF there is no data in the ra_customer_Trx_lines table
 |    then by default the tax action is 'CREATE' else it is 'UPDATE'
 |
 |  PARAMETERS
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  14-Apr-2005     Debbie Sue Jancis   Created
 |
 *===========================================================================*/

 FUNCTION Get_Tax_Action (p_customer_trx_id IN NUMBER) RETURN VARCHAR2 IS
   l_count NUMBER;
   l_action VARCHAR2(12);

 BEGIN

   arp_util.debug('ARP_ETAX_SERVICES_PKG.Get_Tax_Action(+)');

   select count(customer_trx_id)
     INTO l_count
    FROM  ra_customer_trx_lines
   where customer_Trx_id = p_customer_trx_id and
    line_type = 'LINE';

   IF (l_count = 0 ) then
      l_action := 'CREATE';
   ELSE
      l_action := 'UPDATE';
   END IF;

   arp_util.debug('ARP_ETAX_SERVICES_PKG.Get_Tax_Action(-)');

   return l_action;

 END Get_Tax_Action;

/*=============================================================================
 |  PROCEDURE- Override_tax_lines ()
 |
 |  DESCRIPTION
 |    This procedure will be called if there were changes in the
 |    Detail TAX Lines window.
 |
 |  PARAMETERS
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  23-Jun-2005	    Debbie Sue Jancis	Created
 |
 *===========================================================================*/
 PROCEDURE Override_Tax_Lines (p_customer_trx_id   IN NUMBER,
                               p_action            IN VARCHAR2,
                               x_return_status    OUT NOCOPY VARCHAR2,
                               x_msg_count        OUT NOCOPY NUMBER,
                               x_msg_data         OUT NOCOPY VARCHAR2,
                               p_event_id          IN NUMBER,
                               p_override_status   IN VARCHAR2) IS

   l_transaction_rec            zx_api_pub.transaction_rec_type;
   l_return_status_service             VARCHAR2(4000);

   l_event_class_code   VARCHAR2(80);
   l_event_type_code    VARCHAR2(80);
   l_success BOOLEAN;
   l_ccid                              NUMBER;
   l_concat_segments                   VARCHAR2(2000);
   l_msg_count                         NUMBER;
   l_num_failed_dist_rows              NUMBER;
   l_msg_data                          VARCHAR2(4000);
   l_rows                              NUMBER;
   l_is_reg_cm                         NUMBER;
   --Added for Bug 8220233 (call to arp_rounding)
   l_dist_count                 NUMBER;
   l_error_message              VARCHAR2(128);
   pg_base_precision            fnd_currencies.precision%type;
   pg_base_min_acc_unit         fnd_currencies.minimum_accountable_unit%type;
   pg_trx_header_level_rounding ar_system_parameters.trx_header_level_rounding%type;

 BEGIN
   arp_util.debug('ARP_ETAX_SERVICES_PKG.Override_Tax_Lines(+)');

   /* Bug 8220233: Initializing precision, mau, hdr level rounding */
   pg_base_precision            := arp_trx_global.system_info.base_precision;
   pg_base_min_acc_unit         := arp_trx_global.system_info.base_min_acc_unit;
   pg_trx_header_level_rounding := arp_global.sysparam.trx_header_level_rounding;

   /* Initializing return status ..*/
   x_return_status := FND_API.G_RET_STS_SUCCESS;

   -- get event information (OVERRIDE_TAX)
   l_success := arp_etax_util.get_event_information(
                 p_customer_trx_id => p_customer_trx_id,
                 p_action => p_action,
                 p_event_class_code => l_event_class_code,
                 p_event_type_code => l_event_type_code);

   arp_util.debug('customer trx id = ' || p_customer_trx_id);
   arp_util.debug('action = ' || p_action);
   arp_util.debug('event class code = ' || l_event_class_code);
   arp_util.debug('event type code = ' || l_event_type_code);

   IF (l_success) THEN
      /* populate transaction rec type */
       l_transaction_rec.internal_organization_id := arp_global.sysparam.org_id;
       l_transaction_rec.application_id           := 222;
       l_transaction_rec.entity_code              := 'TRANSACTIONS';
       l_transaction_rec.event_class_code         := l_event_class_code;
       l_transaction_rec.event_type_code          := l_event_type_code;
       l_transaction_rec.trx_id                   := p_customer_trx_id;

	/*Bug 8402096 - Record any manual override of CCID by user*/
	record_tax_accounts(p_customer_trx_id);

       /* 5152340 - Remove tax lines from AR before call */
       arp_etax_util.delete_tax_lines_from_ar(p_customer_trx_id);

       -- CAll override_tax service
       zx_api_pub.override_tax(
          p_api_version      => 1.0,
          p_init_msg_list    => FND_API.G_TRUE,
          p_commit           => FND_API.G_FALSE,
          p_validation_level => FND_API.G_VALID_LEVEL_FULL,
          p_override_level   => p_override_status,
          p_transaction_rec  => l_transaction_rec,
          p_event_id         => p_event_id,
          x_return_status    => l_return_status_service,
          x_msg_count        => l_msg_count,
          x_msg_data         => l_msg_data);

       -- update AR with return from tax
       IF (x_return_status = FND_API.G_RET_STS_SUCCESS) THEN
           --  insert Tax records into ra_customer_trx_lines based upon
           --  customer trx id
           arp_util.debug('calling build_ar_tax_lines ...');

           arp_etax_util.build_ar_tax_lines(
                    p_customer_trx_id  => p_customer_trx_id,
                    p_rows_inserted    => l_rows);

           /* 4694486 - Prevent call to autoaccounting if
               no rows were inserted */
           IF l_rows > 0
           THEN

     /*Bug 8402096 - Calling copy_inv_tax_dists() if use_invoice_accounting is yes*/
	     select previous_customer_trx_id
	     into l_is_reg_cm
	     from ra_customer_trx
	     where customer_trx_id = p_customer_trx_id;


             IF l_event_class_code = 'CREDIT_MEMO' and
                use_invoice_accounting and
	        l_is_reg_cm IS  NOT NULL
             THEN
                copy_inv_tax_dists(p_customer_trx_id);

             ELSE

             BEGIN
               -- need to call autoaccounting for these lines:

               ARP_AUTO_ACCOUNTING.do_autoaccounting( 'I', -- p_mode
                             'TAX', --p_account_class
                             p_customer_trx_id, -- p_customer_trx_id
                             NULL, -- p_customer_trx_line_id
                             NULL, -- p_cust_trx_line_salesrep_id
                             null, --p_request_id
                             NULL, --p_gl_date
                             NULL, --p_original_gl_date
                             null, --p_total_trx_amount
                             null, --p_passed_ccid,
                             null, --p_force_account_set_no
                             null, --p_cust_trx_type_id
                             null, --p_primary_salesrep_id,
                             null, --p_inventory_item_id,
                             null, --p_memo_line_id,
                             l_ccid, --p_ccid
                             l_concat_segments, --p_concat_segments
                             l_num_failed_dist_rows ); --p_failure_count

             EXCEPTION
                WHEN arp_auto_accounting.no_ccid THEN
                  fnd_message.set_name('AR', 'ARP_AUTO_ACCOUNTING.NO_CCID');
                WHEN NO_DATA_FOUND THEN
                   null;
                WHEN OTHERS THEN
                 RAISE;
             END;
	     END IF;

	     /*Bug 8402096 - Replace the manual override of CCID by user*/
	     replace_tax_accounts;

             /* Bug 8220233 - Once we insert accounting distributions,
                we must call arp_rounding to fix the amounts on
                the REC dist to reflect the new tax */

               IF  arp_rounding.correct_dist_rounding_errors(
  				                                          	NULL,
  					                                          p_customer_trx_id ,
                                                 			NULL,
                                                 			l_dist_count,
                                                 			l_error_message ,
                                                 			pg_base_precision ,
                                                 			pg_base_min_acc_unit ,
                                                 			'ALL' ,
                                                 			NULL,
                                                 			'N' ,
                                                 			pg_trx_header_level_rounding ,
                                                 			'N',
                                                 			'N') = 0 -- FALSE
               THEN
                  arp_util.debug('EXCEPTION:  arp_etax_services_pkg.Override_Tax_Lines()');
                  arp_util.debug(l_error_message);
                  fnd_message.set_name('AR', 'AR_ROUNDING_ERROR');
                  fnd_message.set_token('ROUTINE','ARP_ETAX_SERVICES_PKG.OVERRIDE_TAX_LINES');
                  APP_EXCEPTION.raise_exception;
               END IF;

               /* End Bug 8220233 */

           END IF; -- l_rows
       END IF;

   END IF;   -- if event codes were derived.
   arp_util.debug('ARP_ETAX_SERVICES_PKG.Override_Tax_Lines(-)');
 END Override_Tax_Lines;

/*=============================================================================
 |  FUNCTION - is_trx_completed()
 |
 |  DESCRIPTION
 |    This function will be called by the following etax program units:
 |      o IS_CANCEL_TAX_LINE_ALLOWED
 |      o IS_MANUAL_DTL_TX_LINE_ALLOWED
 |      o IS_TAX_LINE_DELETE_ALLOWED
 |      o IS_TRX_LINE_FROZEN
 |
 |    In general, these actions are not allowed for transactions that are
 |    in a complete state.
 |
 |  PARAMETERS
 |     p_trx_id NUMBER (customer_trx_id of target transaction)
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  03-MAR-2005     M Raymond           Created
 |
 *===========================================================================*/

 FUNCTION is_tax_update_allowed (p_customer_trx_id IN NUMBER) RETURN BOOLEAN IS
   l_update boolean;
   l_complete_flag varchar2(1);
 BEGIN

   arp_util.debug('ARP_ETAX_SERVICES_PKG.is_tax_update_allowed()+');

   SELECT complete_flag
   INTO   l_complete_flag
   FROM   ra_customer_trx
   WHERE  customer_trx_id = p_customer_trx_id;

   IF (l_complete_flag = 'Y' )
   THEN
      /* trx is complete, prevent updates */
      l_update := FALSE;
      arp_util.debug('  updates prevented by complete_flag');
   ELSE
      /* trx is incomplete, changes are allowed */
      l_update := TRUE;
   END IF;

   arp_util.debug('ARP_ETAX_SERVICES_PKG.is_tax_update_allowed()-');

   return l_update;

 END is_tax_update_allowed;

/*=============================================================================
 | PROCEDURE - validate_for_tax
 |
 |  DESCRIPTION
 |    This routine calls etax API validate_document_for_tax to insure
 |    that the tax, rate, status, juris, and regime are still valid
 |    at the time of completion.
 |
 |
 |    NOTE:  This was intended specifically for calls from
 |       arp_trx_complete_chk package for forms issues.
 |  PARAMETERS
 |     p_customer_trx_id NUMBER (customer_trx_id of target transaction)
 |     p_error_mode      VARCHAR IN (passed from do_completion_chk)
 |     p_valid_for_tax   VARCHAR OUT (Y or N)
 |     p_number_of_errors NUMBER OUT (count of returned errors from etax)
 |
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  11-JUL-2006     M Raymond           Created
 |
 *===========================================================================*/

 PROCEDURE validate_for_tax (p_customer_trx_id IN NUMBER,
                          p_error_mode      IN VARCHAR2,
                          p_valid_for_tax   OUT NOCOPY VARCHAR2,
                          p_number_of_errors OUT NOCOPY NUMBER) IS

      l_return_status   VARCHAR2(50) := FND_API.G_RET_STS_SUCCESS;
      l_msg_count       NUMBER;
      l_msg_data        VARCHAR2(2000);
      l_trx_rec         ZX_API_PUB.transaction_rec_type;
      l_validation_status VARCHAR2(1);
      l_hold_codes_tbl  ZX_API_PUB.hold_codes_tbl_type;
      l_error_count     NUMBER;
      l_trx_number      RA_CUSTOMER_TRX.trx_number%type;
      l_msg             VARCHAR2(2000);
      l_ttype           ra_cust_trx_types_all.type%type;
      l_line_count      NUMBER;

    CURSOR c_errors IS
       select trx_id, trx_line_id, message_name, message_text
       from   zx_validation_errors_gt
       where  application_id = l_trx_rec.application_id
       and    entity_code    = l_trx_rec.entity_code
       and    event_class_code = l_trx_rec.event_class_code
       and    trx_id           = l_trx_rec.trx_id;

 BEGIN
   IF PG_DEBUG in ('Y', 'C')
   THEN
     arp_debug.debug('arp_etax_services_pkg.validate_for_tax()+');
   END IF;

    /* Set l_trx_rec values before call to API */
    select t.customer_trx_id,
           222,
           t.org_id,
           'TRANSACTIONS',
           DECODE(tt.type,
            'INV', 'INVOICE',
            'DM',  'DEBIT_MEMO',
            'CM',  'CREDIT_MEMO'),
           tt.type || '_COMPLETE',
           t.trx_number,
           tt.type,
	   SUM(decode(ctl.line_type, 'LINE', 1, 0))
    into
          l_trx_rec.trx_id,
          l_trx_rec.application_id,
          l_trx_rec.internal_organization_id,
          l_trx_rec.entity_code,
          l_trx_rec.event_class_code,
          l_trx_rec.event_type_code,
          l_trx_number,
          l_ttype, -- 7668830
	  l_line_count
    from  ra_customer_trx t,
          ra_cust_trx_types tt,
	  ra_customer_trx_lines ctl
    where t.customer_trx_id = p_customer_trx_id
    and   t.cust_trx_type_id = tt.cust_trx_type_id
    and   t.org_id = tt.org_id
    and   t.customer_trx_id = ctl.customer_trx_id
    group by
          t.customer_trx_id,
          222,
          t.org_id,
          'TRANSACTIONS',
          DECODE(tt.type,
          'INV', 'INVOICE',
          'DM',  'DEBIT_MEMO',
          'CM',  'CREDIT_MEMO'),
          tt.type || '_COMPLETE',
          t.trx_number,
          tt.type,
          t.customer_trx_id;

    IF l_ttype NOT IN ('DEP','GUAR') AND l_line_count > 0
    THEN
       zx_api_pub.validate_document_for_tax(
                      p_api_version      => 1.0,
                      p_init_msg_list    => FND_API.G_TRUE,
                      p_commit           => FND_API.G_FALSE,
                      p_validation_level => NULL,
                      x_return_status    => l_return_status,
                      x_msg_count        => l_msg_count,
                      x_msg_data         => l_msg_data,
                      p_transaction_rec  => l_trx_rec,
                      x_validation_status=> l_validation_status,
                      x_hold_codes_tbl   => l_hold_codes_tbl);
    END IF;

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS
    THEN
       /* Retrieve and log errors */
       IF l_msg_count = 1
       THEN
          arp_debug.debug(l_msg_data);
          arp_trx_validate.add_to_error_list(        -- Added for Bug 7260572
                              p_error_mode,
                              l_error_count,
                              p_customer_trx_id,
                              l_trx_number,
                              NULL,  -- line_number
                              NULL,  -- other_line_number
                              'GENERIC_MESSAGE',
                              NULL,  -- p_error_location,
                              'GENERIC_TEXT',  -- token name 1
                              l_msg_data,  -- token 1
                              NULL,  -- token name 2
                              NULL   -- token 2
                           );
       ELSIF l_msg_count > 1
       THEN
          LOOP
            l_msg := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,
                                     FND_API.G_FALSE);
            IF l_msg IS NULL
            THEN
               EXIT;
            ELSE
              arp_debug.debug(l_msg);
              arp_trx_validate.add_to_error_list(        -- Added for Bug 7260572
                              p_error_mode,
                              l_error_count,
                              p_customer_trx_id,
                              l_trx_number,
                              NULL,  -- line_number
                              NULL,  -- other_line_number
                              'GENERIC_MESSAGE',
                              NULL,  -- p_error_location,
                              'GENERIC_TEXT',  -- token name 1
                              l_msg,  -- token 1
                              NULL,  -- token name 2
                              NULL   -- token 2
                           );
            END IF;
          END LOOP;
       END IF;

    ELSE
      /* Successful return, copy parameters and distribute messages */
      IF l_validation_status = 'Y'
      THEN
         /* Do nothing, there was no problems with the validation */
         IF PG_DEBUG in ('Y','C')
         THEN
            arp_debug.debug('   transaction is valid');
         END IF;

         l_error_count := 0;
      ELSE
         /* Transaction has failed validation, indicate as
            much back to arp_trx_completion_chk so completion
            is not allowed */
         IF PG_DEBUG in ('Y','C')
         THEN
            arp_debug.debug('   transaction is invalid');
         END IF;

         FOR errors IN c_errors LOOP

             arp_debug.debug(errors.trx_id || '-' || errors.message_text);

             arp_trx_validate.add_to_error_list(
                              p_error_mode,
                              l_error_count,
                              errors.trx_id,
                              l_trx_number,
                              NULL,  -- line_number
                              NULL,  -- other_line_number
                              'GENERIC_MESSAGE',
                              NULL,  -- p_error_location,
                              'GENERIC_TEXT',  -- token name 1
                              errors.message_text,  -- token 1
                              NULL,  -- token name 2
                              NULL   -- token 2
                           );

         END LOOP;

      END IF;

      p_number_of_errors := l_error_count;
      p_valid_for_tax    := l_validation_status;

    END IF;

   IF PG_DEBUG in ('Y', 'C')
   THEN
     arp_debug.debug('  validation_status = ' || l_validation_status);
     arp_debug.debug('arp_etax_services_pkg.validate_for_tax()-');
   END IF;

 END validate_for_tax;


/*=============================================================================
 | PROCEDURE - update_exchange_info
 |
 |  DESCRIPTION
 |    This routine calls etax API ZX_API_PUB.update_exchange_rate to update
 |    the Exchange Rate, Exchange Date and Exchange Rate Type in ZX
 |    repository.
 |
 |
 |  PARAMETERS
 |     p_customer_trx_id NUMBER (customer_trx_id of transaction)
 |     p_exchange_rate   NUMBER IN (current Exchange Rate)
 |     p_exchange_date   DATE IN (current Exhange Date)
 |     p_exchange_rate_type VARCHAR2 OUT (current Exchange Rate Type)
 |
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  09-JUL-2009     Deep Gaurab           Created
 |
 *===========================================================================*/

PROCEDURE update_exchange_info (p_customer_trx_id    IN NUMBER,
                                p_exchange_rate      IN NUMBER,
                                p_exchange_date      IN DATE,
                                p_exchange_rate_type IN VARCHAR2) IS

  l_success             Boolean;
  l_event_class_code    zx_trx_headers_gt.event_class_code%TYPE;
  l_event_type_code     zx_trx_headers_gt.event_type_code%TYPE;
  l_transaction_rec     zx_api_pub.transaction_rec_type;
  l_ret_status          VARCHAR2(50);
  l_msg_count           NUMBER;
  l_msg_data            VARCHAR2(4000);
  l_mesg                VARCHAR2(4000);

BEGIN

     IF PG_DEBUG in ('Y','C') THEN
        arp_debug.debug('arp_etax_services_pkg.update_exchange_info (+)');
     END IF;

     l_success := arp_etax_util.get_event_information(
                  p_customer_trx_id  => p_customer_trx_id,
		  p_action           => 'UPDATE',
		  p_event_class_code => l_event_class_code,
		  p_event_type_code  => l_event_type_code);

     IF l_success THEN
        l_transaction_rec.internal_organization_id := arp_global.sysparam.org_id;
	l_transaction_rec.application_id           := 222;
	l_transaction_rec.entity_code              := 'TRANSACTIONS';
	l_transaction_rec.event_class_code         := l_event_class_code;
	l_transaction_rec.event_type_code          := l_event_type_code;
	l_transaction_rec.trx_id                   := p_customer_trx_id;

	IF PG_DEBUG in ('Y','C')
	THEN
	   arp_debug.debug('Calling ZX_API_PUB.update_exchange_rate.');
           arp_debug.debug('Parameters within p_transaction_rec::');
           arp_debug.debug('======================================');
           arp_debug.debug('Internal_Organization_id: '|| l_transaction_rec.internal_organization_id);
           arp_debug.debug('Application_Id: '|| l_transaction_rec.application_id);
           arp_debug.debug('Entity_Code: '|| l_transaction_rec.entity_code);
           arp_debug.debug('Event_Class_Code: '|| l_transaction_rec.event_class_code);
           arp_debug.debug('Event_Type_Code: '|| l_transaction_rec.event_type_code);
           arp_debug.debug('Customer_trx_id:: '|| l_transaction_rec.trx_id);
           arp_debug.debug('======================================');
	END IF;

	ZX_API_PUB.update_exchange_rate(
	           p_api_version         => 1.0,
		   p_init_msg_list       => FND_API.G_TRUE,
		   p_commit              => FND_API.G_FALSE,
		   p_validation_level    => FND_API.G_VALID_LEVEL_FULL,
		   x_return_status       => l_ret_status,
		   x_msg_count           => l_msg_count,
		   x_msg_data            => l_msg_data,
		   p_transaction_rec     => l_transaction_rec,
		   p_curr_conv_rate      => p_exchange_rate,
		   p_curr_conv_date      => p_exchange_date,
		   p_curr_conv_type      => p_exchange_rate_type);

        IF (l_ret_status <> 'S') THEN
	  IF PG_DEBUG in ('Y','C') THEN
	   arp_debug.debug('ZX_API_PUB.update_exchange_rate returned error');
	  END IF;

	   IF ( l_msg_count = 1 ) THEN

	     IF PG_DEBUG in ('Y','C') THEN
	      arp_debug.debug('API failed with : ' || l_msg_data);
	     END IF;

	     l_mesg := l_msg_data;
	   ELSIF (l_msg_count > 1) THEN
	      LOOP
	        l_mesg := FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
		IF (l_mesg IS NULL) THEN
		   Exit;
		End IF;

		IF PG_DEBUG in ('Y','C') THEN
		  arp_debug.debug('API failed with : ' || l_mesg);
		END IF;
	      END LOOP;
	   END IF;

	   FND_MESSAGE.SET_NAME('FND', 'FND_GENERIC_MESSAGE');
	   FND_MESSAGE.SET_TOKEN('MESSAGE', l_mesg);
	   FND_MSG_PUB.ADD;
	   APP_EXCEPTION.RAISE_EXCEPTION;
	END IF;

     ELSE
        IF PG_DEBUG in ('Y','C') THEN
           arp_debug.debug('ERROR getting EVENT INFORMATION');
	END IF;
     END IF;  -- END IF for l_success

     IF PG_DEBUG in ('Y','C') THEN
        arp_debug.debug('arp_etax_services_pkg.update_exchange_info (-)');
     END IF;

END update_exchange_info;

END ARP_ETAX_SERVICES_PKG;
/
