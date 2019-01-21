create or replace
PACKAGE BODY ARP_PROCESS_CREDIT AS
/* $Header: ARTECMRB.pls 120.17.12010000.7 2010/02/08 06:38:57 pbapna ship $ */

pg_number_dummy number;
pg_date_dummy   date;
pg_name_dummy   varchar2(30);
pg_flag_dummy   varchar2(1);
pg_earliest_date  date;

pg_salesrep_required_flag  ar_system_parameters.salesrep_required_flag%type;
pg_base_curr_code          fnd_currencies.currency_code%type;
pg_base_precision          fnd_currencies.precision%type;
pg_base_min_acc_unit       fnd_currencies.minimum_accountable_unit%type;

-- TYPE credit_lines_type IS TABLE OF
--      ra_customer_trx_lines.customer_trx_line_id%type
--      INDEX BY BINARY_INTEGER;
--
-- pg_num_credit_lines     number;
-- pg_credit_lines         credit_lines_type;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    create_salescredits                                                    |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Inserts salescredit records into RA_CUST_TRX_LINE_SALESREPS            |
 |         - copies from the credited transaction line, if any               |
 |      OR - inserts a row based on the primary salesperson specified on     |
 |           the transaction                                                 |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |    arp_ctls_pkg.insert_f_cm_ct_ctl_id                                     |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_customer_trx_id                                      |
 |                    p_customer_trx_line_id                                 |
 |                    p_memo_line_type                                       |
 |                    p_primary_salesrep_id                                  |
 |                    p_currency_code                                        |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |                                                                           |
 +===========================================================================*/

PROCEDURE create_salescredits(
  p_customer_trx_id            IN ra_customer_trx.customer_trx_id%type,
  p_customer_trx_line_id       IN
                              ra_customer_trx_lines.customer_trx_line_id%type,
  p_memo_line_type             IN ar_memo_lines.line_type%type,
  p_primary_salesrep_id        IN ra_salesreps.salesrep_id%type,
  p_currency_code              IN fnd_currencies.currency_code%type)
IS
BEGIN

    arp_util.debug('arp_process_credit.create_salescredits()+');

    IF (p_customer_trx_line_id IS NULL)
    THEN

        /*------------------------------------+
         |  Create salescredits for the CM.   |
         +------------------------------------*/
         IF ( p_primary_salesrep_id IS NOT NULL)
            AND
            ( p_primary_salesrep_id <> -3
              OR
              pg_salesrep_required_flag = 'Y')
         THEN
             arp_ctls_pkg.insert_f_cm_ct_ctl_id(p_customer_trx_id,
                                                p_customer_trx_line_id,
                                                p_currency_code);
         END IF;
    ELSIF (p_memo_line_type <> 'CHARGES') THEN

       /*--------------------------------------+
        |  Charges do not have salescredits.   |
        |  If this is a charges memo line,     |
        |  then don't do any processing.       |
        +--------------------------------------*/

        IF ( p_primary_salesrep_id IS NOT NULL)
            AND
           ( p_primary_salesrep_id <> -3
             OR
             pg_salesrep_required_flag = 'Y')
        THEN
             arp_ctls_pkg.insert_f_cm_ct_ctl_id(p_customer_trx_id,
                                                p_customer_trx_line_id,
                                                p_currency_code);
        END IF;
    END IF;

    arp_util.debug('arp_process_credit.create_salescredits()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.create_salescredits()');
    arp_util.debug('');
    arp_util.debug('p_customer_trx_id      = '||p_customer_trx_id);
    arp_util.debug('p_customer_trx_line_id = '||p_customer_trx_line_id);
    arp_util.debug('p_memo_line_type       = '||p_memo_line_type);
    arp_util.debug('p_primary_salesrep_id  = '||p_primary_salesrep_id);
    arp_util.debug('p_currency_code        = '||p_currency_code);

    RAISE;
END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    credit_freight                                                         |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    create or updates freight lines for a credit memo                      |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_form_name                                            |
 |                    p_form_version                                         |
 |                    p_credit_rec                                           |
 |                    p_trx_class                                            |
 |                    p_gl_date                                              |
 |                    p_credit_ccid                                          |
 |              OUT:                                                         |
 |                    p_customer_trx_line_id                                 |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |                                                                           |
 +===========================================================================*/

PROCEDURE credit_freight (
  p_form_name             IN varchar2,
  p_form_version          IN number,
  p_customer_trx_id       IN ra_customer_trx.customer_trx_id%type,
  p_customer_trx_line_id  IN ra_customer_trx_lines.customer_trx_line_id%type,
  p_prev_ct_id            IN ra_customer_trx.customer_trx_id%type,
  p_prev_ctl_id           IN ra_customer_trx_lines.customer_trx_line_id%type,
  p_credit_freight_amount IN ra_customer_trx_lines.extended_amount%type,
  p_uncr_freight_amount   IN ra_customer_trx_lines.extended_amount%type,
  p_freight_type          IN varchar2,
  p_freight_ctlid         IN ra_customer_trx_lines.customer_trx_line_id%type,
  p_mode                  IN varchar2,
  p_gl_date               IN ra_cust_trx_line_gl_dist.gl_date%type,
  p_currency_code         IN fnd_currencies.currency_code%type,
  p_status               OUT NOCOPY varchar2)
IS
  l_credited_frt_ctlid      ra_customer_trx.customer_trx_id%type;
  l_freight_ctlid           ra_customer_trx_lines.customer_trx_line_id%type;
  l_sob_id                  ra_customer_trx_lines.set_of_books_id%type;
  l_frt_rec                 ra_customer_trx_lines%rowtype;
BEGIN

   arp_util.debug('arp_process_credit.credit_freight()+');

   IF ( p_prev_ct_id IS NULL)
      OR
      ( p_prev_ct_id IS NOT NULL
        AND
        (  p_freight_type = 'H'
           OR
           (  p_freight_type = 'L'
              AND
              p_customer_trx_line_id IS NOT NULL
           )
        )
      )
   THEN

       --
       -- on-account CM case / regular CM with header freight /
       -- regular CM and called at LINE level
       --

       IF (p_mode = 'INSERT')
       THEN

           l_frt_rec.customer_trx_id               := p_customer_trx_id;
           l_frt_rec.link_to_cust_trx_line_id      := p_customer_trx_line_id;
           l_frt_rec.previous_customer_trx_id      := p_prev_ct_id;
           l_frt_rec.previous_customer_trx_line_id := p_freight_ctlid;
           l_frt_rec.line_type                     := 'FREIGHT';
           l_frt_rec.line_number                   := 1;
           l_frt_rec.extended_amount               := p_credit_freight_amount;
           l_frt_rec.revenue_amount                := p_credit_freight_amount;

           arp_process_freight.insert_freight(
                                 p_form_name,
                                 p_form_version,
                                 l_frt_rec,
                                 'CM',
                                 p_gl_date,
                                 null,
                                 l_freight_ctlid,
                                 p_status);

       ELSIF (p_mode = 'UPDATE')
       THEN

           arp_ctl_pkg.set_to_dummy(l_frt_rec);

           l_frt_rec.customer_trx_id               := p_customer_trx_id;
           l_frt_rec.link_to_cust_trx_line_id      := p_customer_trx_line_id;
           l_frt_rec.previous_customer_trx_line_id := p_freight_ctlid;
           l_frt_rec.line_type                     := 'FREIGHT';
           l_frt_rec.line_number                   := 1;
           l_frt_rec.extended_amount               := p_credit_freight_amount;
           l_frt_rec.revenue_amount                := p_credit_freight_amount;

           arp_process_freight.update_freight(
                                 p_form_name,
                                 p_form_version,
                                 p_customer_trx_id,
                                 p_freight_ctlid,
                                 l_frt_rec,
                                 'CM',
                                 p_gl_date,
                                 null,
                                 null,
                                 null,
                                 p_status);
       ELSIF (p_mode = 'DELETE')
       THEN
           arp_ctlgd_pkg.delete_f_ct_ltctl_id_type(
                 p_customer_trx_id,
                 p_customer_trx_line_id,
                 'FREIGHT',
                 null,
                 null);

           arp_ctl_pkg.delete_f_ct_ltctl_id_type(
                 p_customer_trx_id,
                 p_customer_trx_line_id,
                 'FREIGHT');
       END IF;

   ELSE

       IF (p_mode = 'INSERT')
       THEN

           IF (p_customer_trx_line_id IS NULL)
           THEN

                /*-------------------------------------------+
                 |  crediting freight for the entire invoice |
                 +-------------------------------------------*/

                arp_ctl_pkg.insert_line_f_cm_ct_ctl_id(
                       p_customer_trx_id,
                       p_customer_trx_line_id,
                       p_prev_ct_id,
                       'FREIGHT',
		       0,
                       p_uncr_freight_amount,
                       p_credit_freight_amount,
                       p_currency_code);

                --
                -- call CM module to create FRIEGHT distributions
                --
           END IF;
       ELSIF (p_mode = 'DELETE')
       THEN
           arp_ctlgd_pkg.delete_f_ct_ltctl_id_type(
                 p_customer_trx_id,
                 p_customer_trx_line_id,
                 'FREIGHT',
                 null,
                 null);

           arp_ctl_pkg.delete_f_ct_ltctl_id_type(
                 p_customer_trx_id,
                 p_customer_trx_line_id,
                 'FREIGHT');
       END IF;
   END IF;

   arp_util.debug('arp_process_credit.credit_freight()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.credit_freight');
    arp_util.debug('');
    arp_util.debug('p_customer_trx_id       : '||p_customer_trx_id);
    arp_util.debug('p_customer_trx_line_id  : '||p_customer_trx_line_id);
    arp_util.debug('p_prev_ct_id            : '||p_prev_ct_id);
    arp_util.debug('p_prev_ctl_id           : '||p_prev_ctl_id);
    arp_util.debug('p_credit_freight_amount : '||p_credit_freight_amount);
    arp_util.debug('p_uncr_freight_amount   : '||p_uncr_freight_amount);
    arp_util.debug('p_freight_type          : '||p_freight_type);
    arp_util.debug('p_freight_ctlid         : '||p_freight_ctlid);
    arp_util.debug('p_mode                  : '||p_mode);
    arp_util.debug('p_gl_date               : '||p_gl_date);
    arp_util.debug('p_currency_code         : '||p_currency_code);

    RAISE;
END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    default_credit_header                                                  |
 |                                                                           |
 | DESCRIPTION                                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |                                                                           |
 +===========================================================================*/

PROCEDURE default_credit_header(
  p_cm_rec                IN  ra_customer_trx%rowtype,
  p_prev_customer_trx_id  IN ra_customer_trx.customer_trx_id%type,
  p_new_cm_rec           IN OUT NOCOPY ra_customer_trx%rowtype)
/* Modified IN to IN OUT NOCOPY in the line above - bug 460970 - Oracle 8 */
IS
  l_cr_txn_rec          ra_customer_trx%rowtype;
BEGIN

   arp_util.debug('arp_process_credit.default_credit_header()+');

   p_new_cm_rec := p_cm_rec;
   p_new_cm_rec.previous_customer_trx_id := p_prev_customer_trx_id;
   p_new_cm_rec.complete_flag            := 'N';

   IF p_prev_customer_trx_id IS NULL
   THEN
       return;
   END IF;

   arp_ct_pkg.fetch_p(l_cr_txn_rec, p_prev_customer_trx_id);

   IF (p_prev_customer_trx_id IS NOT NULL)
   THEN

      p_new_cm_rec.ship_to_customer_id := l_cr_txn_rec.ship_to_customer_id;
      p_new_cm_rec.ship_to_address_id  := l_cr_txn_rec.ship_to_address_id;
      p_new_cm_rec.ship_to_site_use_id := l_cr_txn_rec.ship_to_site_use_id;
      p_new_cm_rec.ship_to_contact_id  := l_cr_txn_rec.ship_to_contact_id;

      p_new_cm_rec.invoicing_rule_id   := l_cr_txn_rec.invoicing_rule_id;
      p_new_cm_rec.set_of_books_id     := l_cr_txn_rec.set_of_books_id;

      IF (p_new_cm_rec.bill_to_customer_id) IS NULL
      THEN
          p_new_cm_rec.bill_to_customer_id := l_cr_txn_rec.bill_to_customer_id;
          p_new_cm_rec.bill_to_address_id  := l_cr_txn_rec.bill_to_address_id;
          p_new_cm_rec.bill_to_site_use_id := l_cr_txn_rec.bill_to_site_use_id;
          p_new_cm_rec.bill_to_contact_id  := l_cr_txn_rec.bill_to_contact_id;
      END IF;

   END IF;

   IF (p_new_cm_rec.printing_option IS NULL)
   THEN
       -- populate printing option
       SELECT ctt.default_printing_option,
              decode(ctt.default_printing_option,
                'NOT', 'N',
                'PRI', 'Y',
                null)
       INTO   p_new_cm_rec.printing_option,
              p_new_cm_rec.printing_pending
       FROM   ra_cust_trx_types ctt
       WHERE  ctt.cust_trx_type_id = p_new_cm_rec.cust_trx_type_id;

   END IF;

   arp_util.debug('arp_process_credit.default_credit_header()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.default_credit_header');
    RAISE;
END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    validate_insert_header                                                 |
 |                                                                           |
 | DESCRIPTION                                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |                                                                           |
 +===========================================================================*/
PROCEDURE validate_insert_header
IS
BEGIN
   arp_util.debug('arp_process_credit.validate_insert_header()+');

   arp_util.debug('arp_process_credit.validate_insert_header()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.validate_insert_header');
    RAISE;

END;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    validate_update_header                                                 |
 |                                                                           |
 | DESCRIPTION                                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |                                                                           |
 +===========================================================================*/
PROCEDURE validate_update_header
IS
BEGIN
   arp_util.debug('arp_process_credit.validate_update_header()+');

   arp_util.debug('arp_process_credit.validate_update_header()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.validate_update_header');
    RAISE;

END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    validate_insert_line                                                   |
 |                                                                           |
 | DESCRIPTION                                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada  Created	                     |
 |	03-SEP-97	Tasman Tang    	    Fixed bug 547165: Change type    |
 |					    of p_line_rec to		     |
 |					    ra_customer_trx_lines%rowtype    |
 |                                                                           |
 +===========================================================================*/
PROCEDURE validate_insert_line(
  p_line_rec   IN ra_customer_trx_lines%rowtype)
IS
BEGIN
   arp_util.debug('arp_process_credit.validate_insert_line()+');

   arp_trx_validate.check_dup_line_number(p_line_rec.line_number,
                                          p_line_rec.customer_trx_id,
                                          p_line_rec.customer_trx_line_id);

   arp_util.debug('arp_process_credit.validate_insert_line()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.validate_insert_line');
    RAISE;

END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    validate_update_line                                                   |
 |                                                                           |
 | DESCRIPTION                                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |                                                                           |
 +===========================================================================*/
PROCEDURE validate_update_line
IS
BEGIN
   arp_util.debug('arp_process_credit.validate_update_line()+');

   arp_util.debug('arp_process_credit.validate_update_line()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.validate_update_line');
    RAISE;

END;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    default_credit_line                                                    |
 |                                                                           |
 | DESCRIPTION                                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |                                                                           |
 |      15-May-03    Sahana      Bug2880106- Modified logic in procedure     |
 |                                which defaults the quantity, amount and    |
 |                                unit selling price.                        |
 |      16-DEC-04   VCrisostomo  Bug 4072055 : retrieve UOM_CODE             |
 +===========================================================================*/

PROCEDURE default_credit_line(
  p_cm_line    		       IN  ra_customer_trx_lines%rowtype,
  p_customer_trx_id            IN  ra_customer_trx.customer_trx_id%type,
  p_prev_customer_trx_line_id  IN
                            ra_customer_trx_lines.customer_trx_line_id%type,
  p_line_amount		       IN  number,
  p_new_cm_line    	       IN OUT NOCOPY ra_customer_trx_lines%rowtype)
/* Modified OUT NOCOPY to IN OUT NOCOPY in the line above - bug460970  - Oracle 8 */
IS
  l_cr_txn_line  ra_customer_trx_lines%rowtype;
  l_trx_rec      ra_customer_trx%rowtype;
  l_calc_unit_price  VARCHAR2(1); --2880106
BEGIN

   arp_util.debug('arp_process_credit.default_credit_line()+');

   p_new_cm_line                 := p_cm_line;
   p_new_cm_line.customer_trx_id := p_customer_trx_id;
   p_new_cm_line.extended_amount := p_line_amount;

   IF (p_prev_customer_trx_line_id IS NOT NULL)
   THEN

       arp_ctl_pkg.fetch_p(l_cr_txn_line, p_prev_customer_trx_line_id);
       arp_ct_pkg.fetch_p(l_trx_rec, p_customer_trx_id);


       p_new_cm_line.previous_customer_trx_id      :=
                                l_cr_txn_line.customer_trx_id;
       p_new_cm_line.previous_customer_trx_line_id :=
                                l_cr_txn_line.customer_trx_line_id;
       p_new_cm_line.set_of_books_id               :=
                                l_cr_txn_line.set_of_books_id;
       p_new_cm_line.initial_customer_trx_line_id  :=
                                l_cr_txn_line.initial_customer_trx_line_id;

       -- Bug 2507329 / 2580574 : retrieve sales order number
       p_new_cm_line.sales_order := l_cr_txn_line.sales_order;

       -- Bug 4072055 : retrieve UOM code
       p_new_cm_line.uom_code := l_cr_txn_line.uom_code;

       IF (p_new_cm_line.line_type IS NULL)
       THEN
           IF (l_cr_txn_line.line_type = 'CB')
           THEN
               p_new_cm_line.line_type := 'LINE';
           ELSE
               p_new_cm_line.line_type := l_cr_txn_line.line_type;
           END IF;
       END IF;

--Bug6144741
       IF (p_cm_line.warehouse_id is null)
       THEN
           p_new_cm_line.warehouse_id := l_cr_txn_line.warehouse_id;
       END IF;

       IF (p_cm_line.line_number IS NULL)
       THEN
           p_new_cm_line.line_number := l_cr_txn_line.line_number;
       END IF;

       IF (p_cm_line.description IS NULL)
       THEN
           p_new_cm_line.description   := l_cr_txn_line.description;
       END IF;

       IF (p_cm_line.inventory_item_id IS NULL)
          AND
          (p_cm_line.memo_line_id IS NULL)
       THEN
           p_new_cm_line.inventory_item_id := l_cr_txn_line.inventory_item_id;
           p_new_cm_line.memo_line_id      := l_cr_txn_line.memo_line_id;
       END IF;

       p_new_cm_line.accounting_rule_id := l_cr_txn_line.accounting_rule_id;

       IF p_new_cm_line.accounting_rule_id IS NULL
       THEN
           p_new_cm_line.autorule_complete_flag := null;
       ELSE
           IF (l_trx_rec.credit_method_for_rules = 'UNIT')
           THEN
               p_new_cm_line.last_period_to_credit :=
                              l_cr_txn_line.accounting_rule_duration;
           ELSE
               p_new_cm_line.last_period_to_credit := null;
           END IF;
           p_new_cm_line.autorule_complete_flag := 'N';
       END IF;

/*Start of Bug2880106: Modified logic used to default quantity,
 unit selling price and amount

CASE A:  Amount is not passed then derive it from
   -  quantity and unit selling price if both are passed
   -  if only quantity is passed, the unit selling price is defaulted from the invoice line and the amount is calculated  (Similar to behaviour of forms today)

CASE B: Amount is Passed.
    - if both quantity and unit selling price is not passed, then leave them as null (similar to form behaviour)
    - if only one is passed, derive it from the other. If one is zero, then the other is defaulted to zero.
    - if qty * usp != amt, then rederive the unit selling price.
*/
     IF p_new_cm_line.extended_amount IS NULL THEN

       IF p_new_cm_line.unit_selling_price IS NULL
       THEN
            p_new_cm_line.unit_selling_price :=
                 l_cr_txn_line.unit_selling_price;
       END IF;
       p_new_cm_line.extended_amount
          := arpcurr.currround((p_new_cm_line.quantity_credited *
       p_new_cm_line.unit_selling_price), l_trx_rec.invoice_currency_code) ;

     ELSE -- Amount is not null

       IF p_new_cm_line.unit_selling_price IS NULL AND
         p_new_cm_line.quantity_credited IS  NULL THEN
              NULL;
       ELSE -- one or niether is null
         IF  p_new_cm_line.quantity_credited IS NULL
         THEN
            IF p_new_cm_line.unit_selling_price <> 0 THEN
                 p_new_cm_line.quantity_credited  :=
                   round((p_new_cm_line.extended_amount
                   /p_new_cm_line.unit_selling_price), 15);
            ELSE
             p_new_cm_line.quantity_credited  := 0 ;
           END IF;
         END IF;

         IF p_new_cm_line.unit_selling_price IS NOT NULL
         THEN
             IF p_new_cm_line.extended_amount <>
           arpcurr.currround((p_new_cm_line.quantity_credited *
       p_new_cm_line.unit_selling_price), l_trx_rec.invoice_currency_code)
             THEN
                l_calc_unit_price := 'Y';
             ELSE
                l_calc_unit_price := 'N';
             END IF;
         ELSE
             l_calc_unit_price := 'Y';
         END IF;

         IF l_calc_unit_price = 'Y' THEN
            IF p_new_cm_line.quantity_credited <> 0
            THEN
               p_new_cm_line.unit_selling_price :=
                    round(p_new_cm_line.extended_amount/
                      p_new_cm_line.quantity_credited,15);
            ELSE -- quantity = 0
               p_new_cm_line.unit_selling_price :=  0;
            END IF;
        END IF; -- l_calc_unit_price = 'Y'
      END IF;

    END IF; -- Amount is Null

 /*End of Bug2880106: Modified logic used to default quantity,
   unit selling price and amount */

    /* R12 eTax uptake: ship to values populated */
    p_new_cm_line.ship_to_customer_id := l_cr_txn_line.ship_to_customer_id;
    p_new_cm_line.ship_to_address_id := l_cr_txn_line.ship_to_address_id;
    p_new_cm_line.ship_to_site_use_id := l_cr_txn_line.ship_to_site_use_id;
    p_new_cm_line.ship_to_contact_id := l_cr_txn_line.ship_to_contact_id;

  END IF;

   arp_util.debug('arp_process_credit.default_credit_line()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.default_credit_line');
    RAISE;

END;


PROCEDURE get_cm_amounts(
  p_customer_trx_id         IN ra_customer_trx.customer_trx_id%type,
  p_customer_trx_line_id    IN ra_customer_trx_lines.customer_trx_line_id%type,
  p_prev_ct_id              IN ra_customer_trx.customer_trx_id%type,
  p_prev_ctl_id             IN ra_customer_trx_lines.customer_trx_line_id%type,
  p_cm_complete_flag       OUT NOCOPY varchar2,
  p_cr_line_amount         OUT NOCOPY number,
  p_cr_tax_amount          OUT NOCOPY number,
  p_cr_freight_amount      OUT NOCOPY number)
IS
  l_complete_flag        ra_customer_trx.complete_flag%type;
  l_cr_line_amount       number;
  l_cr_tax_amount        number;
  l_cr_freight_amount    number;
  l_cr_frt_type          varchar2(1);
  l_cr_frt_ctlid         number;
  l_line_count           number;
  l_tax_line_count       number;
  l_freight_line_count   number;

BEGIN

    arp_util.debug('arp_process_credit.get_cm_amounts()+');

    IF (p_customer_trx_id IS NOT NULL)
    THEN

        SELECT max(complete_flag)
        INTO   l_complete_flag
        FROM   ra_customer_trx
        WHERE  customer_trx_id = p_customer_trx_id;

        SELECT count(ctl.customer_trx_line_id),
               sum(extended_amount)
        INTO   l_line_count,
               l_cr_line_amount
        FROM   ra_customer_trx_lines ctl
        WHERE  ctl.customer_trx_id = p_customer_trx_id
        AND    ctl.line_type IN ('CHARGES', 'LINE')
        AND    decode(p_customer_trx_line_id,
                 null, -99,
                 ctl.customer_trx_line_id) = nvl(p_customer_trx_line_id, -99);

        IF (l_line_count > 0)
        THEN
            p_cr_line_amount := l_cr_line_amount;
        END IF;

        SELECT count(ctl.customer_trx_line_id),
               sum(extended_amount)
        INTO   l_tax_line_count,
               l_cr_tax_amount
        FROM   ra_customer_trx_lines ctl
        WHERE  ctl.customer_trx_id = p_customer_trx_id
        AND    ctl.line_type = 'TAX'
        AND    decode(p_customer_trx_line_id,
                 null, -99,
                 ctl.link_to_cust_trx_line_id) =
                      nvl(p_customer_trx_line_id, -99);

        IF (l_tax_line_count > 0)
        THEN
            p_cr_tax_amount := l_cr_tax_amount;
        END IF;

        SELECT count(ctl.customer_trx_line_id),
               sum(extended_amount),
               decode(max(ctl.link_to_cust_trx_line_id),
                      null, 'H', 'L'),
               max(ctl.customer_trx_line_id)
        INTO   l_freight_line_count,
               l_cr_freight_amount,
               l_cr_frt_type,
               l_cr_frt_ctlid
        FROM   ra_customer_trx_lines ctl
        WHERE  ctl.customer_trx_id = p_customer_trx_id
        AND    ctl.line_type = 'FREIGHT'
        AND    decode(p_customer_trx_line_id,
                 null, -99,
                 ctl.link_to_cust_trx_line_id) =
                      nvl(p_customer_trx_line_id, -99);

        IF (l_freight_line_count > 0)
        THEN
            p_cr_freight_amount := l_cr_freight_amount;
        END IF;

    END IF;

    arp_util.debug('arp_process_credit.get_cm_amounts()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.get_cm_amounts');

    RAISE;

END;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    get_uncredit_amounts                                                   |
 |                                                                           |
 | DESCRIPTION                                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |                                                                           |
 +===========================================================================*/

PROCEDURE get_uncredit_amounts(
  p_customer_trx_id         IN ra_customer_trx.customer_trx_id%type,
  p_customer_trx_line_id    IN ra_customer_trx_lines.customer_trx_line_id%type,
  p_prev_ct_id              IN ra_customer_trx.customer_trx_id%type,
  p_prev_ctl_id             IN ra_customer_trx_lines.customer_trx_line_id%type,
  p_mode                    IN varchar2,
  p_uncr_line_amount       OUT NOCOPY number,
  p_uncr_tax_amount        OUT NOCOPY number,
  p_uncr_freight_amount    OUT NOCOPY number,
  p_memo_line_type         OUT NOCOPY varchar2,
  p_freight_type           OUT NOCOPY varchar2,
  p_freight_ctl_id         OUT NOCOPY ra_customer_trx_lines.customer_trx_line_id%type)
IS
  l_uncr_line_amount       number;
  l_uncr_tax_amount        number;
  l_uncr_freight_amount    number;
  l_line_count             number;
  l_memo_line_type         ar_memo_lines.line_type%type;
  l_tax_count              number;
  l_freight_count          number;
  l_freight_type           varchar2(1);
  l_freight_ctl_id         ra_customer_trx_lines.customer_trx_line_id%type;

BEGIN

    arp_util.debug('arp_process_credit.get_uncredit_amounts()+');

    SELECT sum(nra.net_amount),
           count(nra.customer_trx_line_id),
           max(decode(p_prev_ctl_id,
                 null, null,
                 nvl(ml.line_type, 'LINE')))
    INTO   l_uncr_line_amount,
           l_line_count,
           l_memo_line_type
    FROM   ar_net_revenue_amount nra,
           ra_customer_trx_lines ctl,
           ar_memo_lines ml
    WHERE  nra.customer_trx_id      = p_prev_ct_id
    AND    ctl.customer_trx_line_id = nra.customer_trx_line_id
    AND    ctl.memo_line_id         = ml.memo_line_id (+)
    AND    decode(p_prev_ctl_id,
             null, -99,
             nra.customer_trx_line_id) = nvl(p_prev_ctl_id, -99)
    AND    nra.line_type in ('LINE', 'CB', 'CHARGES');

    SELECT sum(nra.net_amount),
           count(nra.customer_trx_line_id)
    INTO   l_uncr_tax_amount,
           l_tax_count
    FROM   ar_net_revenue_amount nra,
           ra_customer_trx_lines ctl
    WHERE  nra.customer_trx_id      = p_prev_ct_id
    AND    nra.line_type            = 'TAX'
    AND    ctl.customer_trx_line_id = nra.customer_trx_line_id
    AND    decode(p_prev_ctl_id,
             null, -99,
             ctl.link_to_cust_trx_line_id) = nvl(p_prev_ctl_id, -99);

    SELECT max(decode(ctl.link_to_cust_trx_line_id,
                 null, 'H',
                 'L')),
           sum(nra.net_amount),
           max(ctl.customer_trx_line_id),
           count(nra.customer_trx_line_id)
    INTO   l_freight_type,
           l_uncr_freight_amount,
           l_freight_ctl_id,
           l_freight_count
    FROM   ar_net_revenue_amount nra,
           ra_customer_trx_lines ctl
    WHERE  nra.customer_trx_id      = p_prev_ct_id
    AND    nra.line_type            = 'FREIGHT'
    AND    ctl.customer_trx_line_id = nra.customer_trx_line_id
    AND    decode(p_prev_ctl_id,
             null, -99,
             ctl.link_to_cust_trx_line_id) = nvl(p_prev_ctl_id, -99);

    IF (l_line_count > 0)
    THEN
        p_uncr_line_amount     := l_uncr_line_amount;
        p_memo_line_type       := l_memo_line_type;
    END IF;

    IF (l_tax_count > 0)
    THEN
        p_uncr_tax_amount      := l_uncr_tax_amount;
    END IF;

    IF (l_freight_count > 0)
    THEN
        p_uncr_freight_amount  := l_uncr_freight_amount;
        p_freight_type         := l_freight_type;
        p_freight_ctl_id       := l_freight_ctl_id;
    END IF;

    arp_util.debug('arp_process_credit.get_uncredit_amounts()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.get_uncredit_amounts');
    RAISE;
END;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    get_credited_txn_balances                                              |
 |                                                                           |
 | DESCRIPTION                                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |                                                                           |
 +===========================================================================*/

PROCEDURE get_credited_txn_balances(
  p_prev_customer_trx_id       IN ra_customer_trx.customer_trx_id%type,
  p_prev_customer_trx_line_id  IN
                             ra_customer_trx_lines.customer_trx_line_id%type,
  p_total_uncr_line_amount    OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_total_uncr_tax_amount     OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_total_uncr_freight_amount OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_trx_balance_due           OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_line_balance_due          OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_tax_balance_due           OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_freight_balance_due       OUT NOCOPY ra_customer_trx_lines.extended_amount%type)
IS
  l_count                     number;
  l_total_uncr_line_amount    ra_customer_trx_lines.extended_amount%type;
  l_total_uncr_tax_amount     ra_customer_trx_lines.extended_amount%type;
  l_total_uncr_freight_amount ra_customer_trx_lines.extended_amount%type;
  l_trx_balance_due           ra_customer_trx_lines.extended_amount%type;
  l_line_balance_due          ra_customer_trx_lines.extended_amount%type;
  l_tax_balance_due           ra_customer_trx_lines.extended_amount%type;
  l_freight_balance_due       ra_customer_trx_lines.extended_amount%type;
BEGIN

   arp_util.debug('arp_process_credit.get_credited_txn_balances()+');

    SELECT sum(decode(
                 decode(nra.line_type,
                   'CB', 'LINE',
                   'CHARGES', 'LINE',
                   nra.line_type),
                 'LINE', nra.net_amount,
                 0)),
           sum(decode(nra.line_type, 'TAX',      nra.net_amount, 0)),
           sum(decode(nra.line_type, 'FREIGHT',  nra.net_amount, 0))
    INTO   l_total_uncr_line_amount,
           l_total_uncr_tax_amount,
           l_total_uncr_freight_amount
    FROM   ar_net_revenue_amount nra,
           ra_customer_trx_lines ctl
    WHERE  nra.customer_trx_id = p_prev_customer_trx_id
    AND    ctl.customer_trx_line_id = nra.customer_trx_line_id
    AND    ctl.line_type            = nra.line_type
    AND    decode(p_prev_customer_trx_line_id,
             null, -99,
             ctl.link_to_cust_trx_line_id) =
                         nvl(p_prev_customer_trx_line_id, -99);

   p_total_uncr_line_amount    := l_total_uncr_line_amount;
   p_total_uncr_tax_amount     := l_total_uncr_tax_amount;
   p_total_uncr_freight_amount := l_total_uncr_freight_amount;

   IF (p_prev_customer_trx_line_id IS NULL)
   THEN

      /*--------------------------------------------------------+
       | get balances from the payment schedule, if they exist  |
       +--------------------------------------------------------*/
       SELECT count(*)
       INTO   l_count
       FROM   ar_payment_schedules
       WHERE  customer_trx_id = p_prev_customer_trx_id;

       IF (l_count > 0)
       THEN
           SELECT sum(nvl(amount_due_remaining, 0)),
                  sum(nvl(amount_line_items_remaining, 0)),
                  sum(nvl(tax_remaining, 0)),
                  sum(nvl(freight_remaining, 0))
           INTO   l_trx_balance_due,
                  l_line_balance_due,
                  l_tax_balance_due,
                  l_freight_balance_due
           FROM   ar_payment_schedules
           WHERE  customer_trx_id = p_prev_customer_trx_id;

          /*---------------------------------------------------------+
           | For CMs against a child of a deposit, add the amount of |
           | the commitment adjustment back to the due amounts       |
           +--------------------------------------------------------*/
           SELECT l_trx_balance_due - sum(nvl(amount, 0)),
                  l_line_balance_due - sum(nvl(amount, 0))
           INTO   l_trx_balance_due,
                  l_line_balance_due
           FROM   ar_adjustments adj,
                  ra_cust_trx_types commit_ctt,
                  ra_customer_trx commit_trx,
                  ra_customer_trx credited_trx
           WHERE  commit_ctt.cust_trx_type_id  = commit_trx.cust_trx_type_id
           AND    commit_trx.customer_trx_id   =
                                       credited_trx.initial_customer_trx_id
           AND    credited_trx.customer_trx_id = p_prev_customer_trx_id
           AND    commit_ctt.type              = 'DEP'
           AND    adj.customer_trx_id          = p_prev_customer_trx_id
           AND    adj.adjustment_type          = 'C';
       ELSE
           l_line_balance_due    := l_total_uncr_line_amount;
           l_tax_balance_due     := l_total_uncr_tax_amount;
           l_freight_balance_due := l_total_uncr_freight_amount;

           l_trx_balance_due := l_line_balance_due +
                                l_tax_balance_due +
                                l_freight_balance_due;
       END IF;
   END IF;

   arp_util.debug('arp_process_credit.get_credited_txn_balances()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION : arp_process_credit.get_credited_txn_balances');
    arp_util.debug('');

    RAISE;

END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    derive_credit_information                                              |
 |                                                                           |
 | DESCRIPTION                                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |      03-APR-02       Michael Raymond         Bug 2217161 - added
 |                                              p_submit_cm_dist parameter
 |                                              to allow user to submit the
 |                                              gl_dist portion of ARXTWCMI
 |                                              as a concurrent request.
 |                                                                           |
 +===========================================================================*/
PROCEDURE derive_credit_information(
  p_form_name                   IN varchar2,
  p_form_version                IN number,
  p_customer_trx_id             IN ra_customer_trx.customer_trx_id%type,
  p_prev_customer_trx_id        IN ra_customer_trx.customer_trx_id%type,
  p_credit_line_amount          IN ra_customer_trx_lines.extended_amount%type,
  p_credit_freight_amount       IN ra_customer_trx_lines.extended_amount%type,
  p_currency_code               IN fnd_currencies.currency_code%type,
  p_gl_date                     IN ra_cust_trx_line_gl_dist.gl_date%type,
  p_primary_salesrep_id         IN ra_salesreps.salesrep_id%type,
  p_compute_tax                 IN varchar2,
  p_line_percent		IN number,
  p_credit_tax_amount       IN OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_status                     OUT NOCOPY varchar2,
  p_submit_cm_dist              IN varchar2 DEFAULT 'N')

IS

  l_credited_ctlid             ra_customer_trx_lines.customer_trx_line_id%type;
  l_customer_trx_line_id       ra_customer_trx_lines.customer_trx_line_id%type;

  l_line_rec                   ra_customer_trx_lines%rowtype;

  l_freight_type               varchar2(1);
  l_freight_ctl_id             ra_customer_trx_lines.customer_trx_line_id%type;
  l_memo_line_type             ar_memo_lines.line_type%type;

  l_uncr_line_amount           number;
  l_uncr_tax_amount            number;
  l_uncr_freight_amount        number;

  l_credit_line_amount         number;
  l_credit_tax_amount          number;
  l_credit_freight_amount      number;
  l_tax_amount                 number;
  l_tax_percent                number;

  l_failure_count              number;

  l_total_uncr_line_amount     number;
  l_total_uncr_tax_amount      number;
  l_total_uncr_freight_amount  number;
  l_trx_balance_due            number;
  l_line_balance_due           number;
  l_tax_balance_due            number;
  l_freight_balance_due        number;

  l_num_rows                   number;

  l_cmm_status                 varchar2(30) := 'OK';
  l_all_line_status            varchar2(30) := 'OK';
  l_line_status                varchar2(30) := 'OK';
  l_tax_status                 varchar2(30) := 'OK';
  l_frt_status                 varchar2(30) := 'OK';
BEGIN

    arp_util.debug('arp_process_credit.derive_credit_information()+');

    IF (nvl(pg_num_credit_lines, 0) > 0)
    THEN

       /*-------------------------------------+
        | credit lines have been identified,  |
        | credit uncredited portion           |
        +-------------------------------------*/

        FOR i IN 1..pg_num_credit_lines LOOP
            --
            -- get amounts to be credited
            --
            get_uncredit_amounts(p_customer_trx_id,
                                 null,
                                 p_prev_customer_trx_id,
                                 pg_credit_lines(i),
                                 'INSERT',
                                 l_total_uncr_line_amount,
                                 l_total_uncr_tax_amount,
                                 l_total_uncr_freight_amount,
                                 l_memo_line_type,
                                 l_freight_type,
                                 l_freight_ctl_id);

           --
           -- call insert_lines to credit the line
           --

           l_tax_amount := -1 * l_total_uncr_tax_amount;

           l_line_status := 'OK';

           arp_process_credit.insert_line(
                                          p_form_name,
                                          p_form_version,
                                          l_line_rec,
                                          -1 * l_total_uncr_line_amount,
                                          -1 * l_total_uncr_freight_amount,
                                          null,
                                          null,
                                          l_memo_line_type,
                                          p_gl_date,
                                          p_currency_code,
                                          p_primary_salesrep_id,
                                          p_compute_tax,
                                          p_customer_trx_id,
                                          p_prev_customer_trx_id,
                                          pg_credit_lines(i),
                                          l_tax_percent,
                                          l_tax_amount,
                                          l_customer_trx_line_id,
                                          l_line_status);

            IF (NVL(l_line_status, 'OK') <> 'OK' ) THEN
               l_all_line_status := l_line_status;
            END IF;

        END LOOP;

    ELSE

        arp_util.debug('derive_credit_information() : get_uncredit_amounts');

        get_uncredit_amounts(p_customer_trx_id,
                             null,
                             p_prev_customer_trx_id,
                             null,
                             null,
                             l_total_uncr_line_amount,
                             l_total_uncr_tax_amount,
                             l_total_uncr_freight_amount,
                             l_memo_line_type,
                             l_freight_type,
                             l_freight_ctl_id);

        arp_util.debug('Freight type  : '||l_freight_type);
        arp_util.debug('Freight ctlid : '||l_freight_ctl_id);

        l_credit_line_amount    := p_credit_line_amount;
        l_credit_tax_amount     := p_credit_tax_amount;
        l_credit_freight_amount := p_credit_freight_amount;

        IF p_credit_line_amount IS NULL
        THEN
            IF ((p_credit_tax_amount IS NOT NULL)
                OR
                (p_credit_freight_amount IS NOT NULL
            -- Added the OR clause with the condition for l_freight_type = 'H' :bug 867191.
                 AND
                 (l_freight_type = 'L' OR l_freight_type = 'H')
                 )
               )
            THEN
                l_credit_line_amount := 0;
            END IF;
        END IF;

        IF (l_credit_line_amount IS NOT NULL)
        THEN
           /*------------------------------------+
            | create credit memo LINE lines      |
            +------------------------------------*/
            arp_ctl_pkg.insert_line_f_cm_ct_ctl_id(p_customer_trx_id,
                                                   null,
                                                   p_prev_customer_trx_id,
                                                   'LINE',
					           p_line_percent,
                                                   l_total_uncr_line_amount,
                                                   l_credit_line_amount,
                                                   p_currency_code,
					           p_credit_tax_amount);
        END IF;

       /*-------------------------------+
        | create sales credit lines     |
        +-------------------------------*/
        IF (l_credit_line_amount IS NOT NULL)
        THEN

            create_salescredits(
                   p_customer_trx_id,
                   NULL,
                   NULL,
                   p_primary_salesrep_id,
                   p_currency_code);

        END IF;

       IF (l_credit_freight_amount IS NOT NULL)
       THEN
          /*------------------------------------+
           | create credit memo FREIGHT lines   |
           +------------------------------------*/
           arp_util.debug('derive_credit_information() : credit_freight');
           credit_freight(
                        p_form_name,
                        p_form_version,
                        p_customer_trx_id,
                        null,
                        p_prev_customer_trx_id,
                        null,
                        l_credit_freight_amount,
                        l_total_uncr_freight_amount,
                        l_freight_type,
                        l_freight_ctl_id,
                        'INSERT',
                        p_gl_date,
                        p_currency_code,
                        l_frt_status);

       END IF;

      /*-------------------------------+
       | call credit memo module       |
       +-------------------------------*/
       /* Bug 2217161 - supress call to arp_credit_memo_module
          if user elected to submit */
       IF (l_credit_line_amount IS NOT NULL AND
           p_submit_cm_dist = 'N')
       THEN
           BEGIN
               arp_util.debug('derive_credit_information() : '||
                              'credit_transactions');

               arp_credit_memo_module.credit_transactions(
                         p_customer_trx_id,
                         null,
                         p_prev_customer_trx_id,
                         null,
                         null,
                         l_failure_count);
           EXCEPTION
             WHEN arp_credit_memo_module.no_ccid THEN
               arp_util.debug('credit memo module exception : no_ccid');
               l_cmm_status := 'ARP_CREDIT_MEMO_MODULE.NO_CCID';
             WHEN NO_DATA_FOUND THEN
               arp_util.debug('credit memo module exception : no_data_found');
               null;
             WHEN app_exception.application_exception THEN
               arp_util.debug('credit memo module exception : app_exception ');
               RAISE;
             WHEN OTHERS THEN
               RAISE;
           END;
       END IF;

      /* #AR CREDIT_MEMO
          MODE            = "I"
          CUSTOMER_TRX_ID = ":CREDIT_MEMO.CUSTOMER_TRX_ID"
          PREVIOUS_CUSTOMER_TRX_ID = ":INVOICE.CUSTOMER_TRX_ID" */

     END IF;

     arp_util.debug('l_all_line_status : '||l_all_line_status);
     arp_util.debug('l_tax_status : '||l_tax_status);
     arp_util.debug('l_frt_status : '||l_frt_status);
     arp_util.debug('l_cmm_status : '||l_cmm_status);

     IF (NVL(l_all_line_status, 'OK') <> 'OK') THEN
        p_status := l_all_line_status;
     ELSIF (NVL(l_tax_status, 'OK') <> 'OK') THEN
        p_status := l_tax_status;
     ELSIF (NVL(l_frt_status, 'OK') <> 'OK') THEN
        p_status := l_frt_status;
     ELSIF (NVL(l_cmm_status, 'OK') <> 'OK') THEN
        p_status := l_cmm_status;
     END IF;

     arp_util.debug('arp_process_credit.derive_credit_information()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: derive_credit_information');
    RAISE;
END;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    insert_header                                                          |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Inserts a row into RA_CUSTOMER_TRX for Credit Memos                    |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_form_name                                            |
 |                    p_form_version                                         |
 |                    p_credit_rec                                           |
 |                    p_trx_class                                            |
 |                    p_gl_date                                              |
 |                    p_credit_ccid                                          |
 |              OUT:                                                         |
 |                    p_customer_trx_line_id                                 |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |      03-APR-02       Michael Raymond         Bug 2217161 - added
 |                                              p_submit_cm_dist parameter
 |                                              to allow supression of gl_dist
 |                                              rows coming from form.
 |                                                                           |
 +===========================================================================*/

PROCEDURE insert_header(
  p_form_name                   IN varchar2,
  p_form_version                IN number,
  p_trx_rec                     IN ra_customer_trx%rowtype,
  p_trx_class                   IN ra_cust_trx_types.type%type,
  p_gl_date                     IN ra_cust_trx_line_gl_dist.gl_date%type,
  p_primary_salesrep_id         IN ra_salesreps.salesrep_id%type,
  p_currency_code               IN fnd_currencies.currency_code%type,
  p_prev_customer_trx_id        IN ra_customer_trx.customer_trx_id%type,
  p_line_percent                IN number,
  p_freight_pecent              IN number,
  p_line_amount                 IN ra_customer_trx_lines.extended_amount%type,
  p_freight_amount              IN ra_customer_trx_lines.extended_amount%type,
  p_compute_tax                 IN varchar2,
  p_trx_number                 OUT NOCOPY ra_customer_trx.trx_number%type,
  p_customer_trx_id            OUT NOCOPY ra_customer_trx.customer_trx_id%type,
  p_tax_percent             IN OUT NOCOPY number,
  p_tax_amount              IN OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_status                     OUT NOCOPY varchar2,
  p_submit_cm_dist              IN varchar2 DEFAULT 'N')
IS

  l_customer_trx_id       ra_customer_trx.customer_trx_id%type;
  l_trx_rec               ra_customer_trx%rowtype;
  l_total_credit_amount   ra_customer_trx_lines.extended_amount%type;

  l_result                number;
  l_ccid                  number;
  l_concat_segments       varchar2(2000);
  l_num_failed_dist_rows  number;
  l_errorbuf              varchar2(200);

  l_rec_aa_status         varchar2(30);
  l_derive_status         varchar2(30);
  l_df_return_status	  VARCHAR2(1);
  l_msg_data		  VARCHAR2(4000);
  l_msg_count		  NUMBER;

--BUG#2750340
  l_ev_rec                arp_xla_events.xla_events_type;

BEGIN

    arp_util.debug('arp_process_credit.insert_header()+');

   /*--------------------------------------------------------------+
    | check form version to determine IF it is compatible with the |
    | entity handler.                                              |
    +--------------------------------------------------------------*/
    arp_trx_validate.ar_entity_version_check(p_form_name, p_form_version);


   /*--------------------+
    |  pre-insert logic  |
    +--------------------*/

    -- default_credit_header(p_trx_rec, p_prev_customer_trx_id, l_trx_rec);
    l_trx_rec := p_trx_rec;

   /* Bug 609042:  get the default_status_trx  */
   IF    ( p_trx_rec.status_trx IS NULL )
   THEN

         SELECT NVL( default_status, 'OP' )
         INTO   l_trx_rec.status_trx
         FROM   ra_cust_trx_types
         WHERE  cust_trx_type_id = p_trx_rec.cust_trx_type_id;
   END IF;

    validate_insert_header;

   /*----------------------+
    |  call table-handler  |
    +----------------------*/
    arp_ct_pkg.insert_p(l_trx_rec, p_trx_number, l_customer_trx_id);

    p_customer_trx_id := l_customer_trx_id;

   -- BUG#2750340 : Call AR_XLA_EVENTS
    l_ev_rec.xla_from_doc_id   := p_customer_trx_id;
    l_ev_rec.xla_to_doc_id     := p_customer_trx_id;
    l_ev_rec.xla_req_id        := NULL;
    l_ev_rec.xla_dist_id       := NULL;
    l_ev_rec.xla_doc_table     := 'CT';
    l_ev_rec.xla_doc_event     := NULL;
    l_ev_rec.xla_mode          := 'O';
    l_ev_rec.xla_call          := 'B';
    l_ev_rec.xla_fetch_size    := 999;
    arp_xla_events.create_events(p_xla_ev_rec => l_ev_rec );

   /*--------------------------------------------------+
    |  call autoaccounting to insert the REC record    |
    +--------------------------------------------------*/

    BEGIN
        arp_auto_accounting.do_autoaccounting(
                                'I',
                                'REC',
                                l_customer_trx_id,
                                null,
                                null,
                                null,
                                p_gl_date,
                                null,
                                nvl(l_total_credit_amount, 0),
                                null,
                                null,
                                null,
                                null,
                                null,
                                null,
                                l_ccid,
                                l_concat_segments,
                                l_num_failed_dist_rows);
   EXCEPTION
     WHEN arp_auto_accounting.no_ccid THEN
       l_rec_aa_status := 'ARP_AUTO_ACCOUNTING.NO_CCID';
     WHEN OTHERS THEN
       RAISE;
   END;


   /*------------------------------------------------------+
    |  derive credit information for regular credit memos  |
    +------------------------------------------------------*/
    IF (( p_prev_customer_trx_id IS NOT NULL)
        AND
        (( p_line_amount IS NOT NULL
          OR
          p_tax_amount IS NOT NULL
          OR
          p_freight_amount IS NOT NULL)
         OR
          nvl(pg_num_credit_lines,0) > 0))
    THEN
        l_derive_status := 'OK';
        /* Bug 2217161 - added p_submit_cm_dist parameter */
        derive_credit_information(p_form_name,
                                  p_form_version,
                                  l_customer_trx_id,
                                  p_prev_customer_trx_id,
                                  p_line_amount,
                                  p_freight_amount,
                                  p_currency_code,
                                  p_gl_date,
                                  p_primary_salesrep_id,
                                  p_compute_tax,
				  p_line_percent,
                                  p_tax_amount,
                                  l_derive_status,
                                  p_submit_cm_dist);
    END IF;

    arp_util.debug('l_rec_aa_status : '||l_rec_aa_status);
    arp_util.debug('l_derive_status : '||l_derive_status);

    IF (NVL(l_rec_aa_status, 'OK') <> 'OK') THEN
        p_status := l_rec_aa_status;
    ELSIF (NVL(l_derive_status, 'OK') <> 'OK') THEN
        p_status := l_derive_status;
    END IF;

    IF l_df_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       p_status := 'eTAX_ERROR';
    END IF;

    arp_util.debug('arp_process_credit.insert_header()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.insert_header');
    RAISE;
END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    delete_cm_records                                                      |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Deletes Credit Memo records                                            |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_customer_trx_id                                      |
 |                    p_trx_number_change_flag                               |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |      19-NOV-01       Santosh Vaze                    Bug Fix 2109490	     |
 |                                  Added parameter p_trx_number_change_flag |
 |      11-APR-03       M Raymond   Bug 2868648 - added delete of CMA rows
 |                                                                           |
 +===========================================================================*/
PROCEDURE delete_cm_records(
  p_customer_trx_id            IN ra_customer_trx.customer_trx_id%type,
  p_trx_number_change_flag     IN boolean)
IS
BEGIN

    arp_util.debug('arp_process_credit.delete_cm_records()+');

    /*-----------------------+
     | delete sales credits  |
     +-----------------------*/
    arp_ctls_pkg.delete_f_ct_id(p_customer_trx_id);

    /*----------------------------------------+
     | delete distributions, except for 'REC' |
     +----------------------------------------*/
    arp_ctlgd_pkg.delete_f_ct_ltctl_id_type(
                          p_customer_trx_id,
                          null,
                          null,
                          null,
                          null);

     /*--------------------------------------------------------+
      | Reverse Tax vendor's audit for existing CM tax amounts.|
      +--------------------------------------------------------*/

     ARP_ETAX_UTIL.global_document_update(p_customer_trx_id,
                                          NULL,
                                          'DELETE');

    /* Bug 2868648 - remove credit memo amount rows */
    arp_cma_pkg.delete_f_ct_id(p_customer_trx_id);

    /*---------------------+
     | delete line records |
     +---------------------*/
    arp_ctl_pkg.delete_f_ct_id(p_customer_trx_id);

    arp_util.debug('arp_process_credit.delete_cm_records()-');

EXCEPTION

  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.delete_cm_records');
    arp_util.debug('');
    arp_util.debug('p_customer_trx_id     = '||p_customer_trx_id);

    RAISE;
END;


PROCEDURE rerun_aa(
  p_customer_trx_id       IN ra_customer_trx.customer_trx_id%type,
  p_customer_trx_line_id  IN ra_customer_trx_lines.customer_trx_line_id%type,
  p_gl_date               IN ra_cust_trx_line_gl_dist.gl_date%type,
  p_credit_amount         IN ra_cust_trx_line_gl_dist.amount%type,
  p_status               OUT NOCOPY varchar2)
IS
  l_ccid                       number;
  l_concat_segments            varchar2(2000);
  l_num_failed_dist_rows       number;
  l_result                     number;
  l_errorbuf                   varchar2(200);

  l_rec_aa_status              varchar2(30) := 'OK';
  l_other_aa_status            varchar2(30) := 'OK';
BEGIN
    arp_util.debug('arp_process_credit.line_rerun_aa()+');

    IF p_customer_trx_line_id IS NULL
    THEN
        BEGIN
        arp_auto_accounting.do_autoaccounting (
                            'U',
                            'REC',
                            p_customer_trx_id,
                            p_customer_trx_line_id,
                            null,
                            null,
                            null,
                            p_gl_date,
                            null,
                            p_credit_amount,
                            null,
                            null,
                            null,
                            null,
                            null,
                            l_ccid,
                            l_concat_segments,
                            l_num_failed_dist_rows );
   EXCEPTION
     WHEN arp_auto_accounting.no_ccid THEN
       l_rec_aa_status := 'ARP_AUTO_ACCOUNTING.NO_CCID';
     WHEN NO_DATA_FOUND THEN
       null;
     WHEN OTHERS THEN
       RAISE;
   END;

    END IF;

    BEGIN
        arp_auto_accounting.do_autoaccounting (
                            'U',
                            'ALL',
                            p_customer_trx_id,
                            p_customer_trx_line_id,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            l_ccid,
                            l_concat_segments,
                            l_num_failed_dist_rows);
   EXCEPTION
     WHEN arp_auto_accounting.no_ccid THEN
       l_other_aa_status := 'ARP_AUTO_ACCOUNTING.NO_CCID';
     WHEN NO_DATA_FOUND THEN
       null;
     WHEN OTHERS THEN
       RAISE;
   END;

   arp_util.debug('l_rec_aa_status   : '||l_rec_aa_status);
   arp_util.debug('l_other_aa_status : '||l_other_aa_status);

   IF (NVL(l_rec_aa_status, 'OK') <> 'OK') THEN
      p_status := l_rec_aa_status;
   ELSIF (NVL(l_other_aa_status, 'OK') <> 'OK') THEN
      p_status := l_other_aa_status;
   END IF;

    arp_util.debug('arp_process_credit.line_rerun_aa()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.line_rerun_aa');
    RAISE;
END;

/* Bug 3619804 */
/*===========================================================================+
 | PROCEDURE                                                                 |
 |    reverse_revrec_effect_cm                                               |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    When a transaction with rule is incompleted, we will now reverse the   |
 |    effect of revenue recognition on the transaction, if it is already run.|
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 | ARGUMENTS :                                                               |
 |                 IN :  p_customer_trx_id                                   |
 |                 OUT:                                                      |
 |             IN/ OUT:                                                      |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     10-May-04  Surendra Rajan Created                                     |
 |                                                                           |
 +===========================================================================*/
   PROCEDURE reverse_revrec_effect_cm (
      p_customer_trx_id IN ra_customer_trx.customer_trx_id%type
        )  IS

   l_line_rec                ra_customer_trx_lines%rowtype;
   l_dist_rec                ra_cust_trx_line_gl_dist%rowtype;

   BEGIN

      arp_util.debug('arp_process_credit.reverse_revrec_effect_cm()+');

      arp_ctl_pkg.set_to_dummy( l_line_rec );
      l_line_rec.autorule_complete_flag := 'N';
      l_line_rec.autorule_duration_processed := NULL;

      BEGIN
           arp_ctl_pkg.update_f_ct_id( l_line_rec,
                                p_customer_trx_id,
                                            'LINE');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            arp_util.debug('arp_process_credit..reverse_revrec_effect_cm: '||
                              'no child lines to update.');
       WHEN OTHERS THEN
            arp_util.debug('EXCEPTION:  '||
                        'arp_process_credit.reverse_revrec_effect_cm()');
         RAISE;
      END;

      BEGIN

	  --6870437
          ARP_XLA_EVENTS.delete_reverse_revrec_event( p_document_id  => p_customer_trx_id,
                                                      p_doc_table    => 'CT');

	  arp_ctlgd_pkg.delete_f_ct_id(p_customer_trx_id,
                                                      'N',
                                                     NULL);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           arp_util.debug('arp_process_credit.reverse_revrec_effect_cm: '||
                                     'no dists to delete.');
         WHEN OTHERS THEN
           arp_util.debug('EXCEPTION:  '||
                      'arp_process_credit.reverse_revrec_effect_cm()');
         RAISE;
      END;

      arp_ctlgd_pkg.set_to_dummy(l_dist_rec);
      l_dist_rec.latest_rec_flag := 'Y';
      BEGIN
        arp_ctlgd_pkg.update_f_ct_id(l_dist_rec,
                              p_customer_trx_id,
                                            'Y',
                                         'REC');
      EXCEPTION
           WHEN NO_DATA_FOUND THEN
            arp_util.debug('arp_process_credit.reverse_revrec_effect_cm: '||
                                    'no dists to update.');
           WHEN OTHERS THEN
            arp_util.debug('EXCEPTION:  '||
                       'arp_process_credit.reverse_revrec_effect_cm()');
           RAISE;
      END;
 EXCEPTION
     WHEN OTHERS THEN
       arp_util.debug('EXCEPTION:  '||
                'arp_process_credit.reverse_revrec_effect_cm()');
     RAISE;
 END ;



/*===========================================================================+
 | PROCEDURE                                                                 |
 |    set_header_flags                                                       |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Compares the header record with that existing in the database and      |
 |    sets various flags                                                     |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_customer_trx_id                                      |
 |                    p_new_trx_rec                                          |
 |                    p_new_gl_date                                          |
 |              OUT:                                                         |
 |                    p_exch_rate_changed_flag                               |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |                                                                           |
 +===========================================================================*/
PROCEDURE set_header_flags(
  p_customer_trx_id          IN ra_customer_trx.customer_trx_id%type,
  p_new_trx_rec              IN ra_customer_trx%rowtype,
  p_new_gl_date              IN ra_cust_trx_line_gl_dist.gl_date%type,
  p_exch_rate_changed_flag  OUT NOCOPY boolean,
  p_gl_date_changed_flag    OUT NOCOPY boolean,
  p_complete_changed_flag   OUT NOCOPY boolean,
  p_old_trx_rec             OUT NOCOPY ra_customer_trx%rowtype)
IS
  l_old_trx_rec             ra_customer_trx%rowtype;
  l_old_gl_date             ra_cust_trx_line_gl_dist.gl_date%type;
BEGIN
    arp_util.debug('arp_process_credit.set_header_flags()+');

    arp_ct_pkg.fetch_p(l_old_trx_rec, p_customer_trx_id);

    p_old_trx_rec := l_old_trx_rec;

    p_gl_date_changed_flag  := FALSE;
    p_complete_changed_flag := FALSE;

    IF (nvl(p_new_gl_date, pg_earliest_date) <> pg_date_dummy)
    THEN

        SELECT gl_date
        INTO   l_old_gl_date
        FROM   ra_cust_trx_line_gl_dist
        WHERE  customer_trx_id = p_customer_trx_id
        AND    account_class   = 'REC'
        AND    latest_rec_flag = 'Y';

        IF (nvl(l_old_gl_date, pg_earliest_date) <>
            nvl(p_new_gl_date, pg_earliest_date))
        THEN
            p_gl_date_changed_flag := TRUE;
        ELSE
            p_gl_date_changed_flag := FALSE;
        END IF;

     END IF;

     IF (nvl(l_old_trx_rec.complete_flag, 'x') <>
         nvl(p_new_trx_rec.complete_flag, 'x')
         AND
         nvl(p_new_trx_rec.complete_flag, 'x') <> pg_flag_dummy)
     THEN
         p_complete_changed_flag := TRUE;
     ELSE
         p_complete_changed_flag := FALSE;
     END IF;

     arp_util.debug('arp_process_credit.set_header_flags()-');

EXCEPTION
  WHEN OTHERS THEN
     arp_util.debug('EXCEPTION: arp_process_credit.set_header_flags');
     arp_util.debug('');
     RAISE;
END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    update_header                                                          |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Updates the row in RA_CUSTOMER_TRX for Credit Memos                    |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_form_name                                            |
 |                    p_form_version                                         |
 |                    p_trx_class                                            |
 |                    p_gl_date                                              |
 |                    p_credit_ccid                                          |
 |              OUT:                                                         |
 |                    p_customer_trx_line_id                                 |
 |          IN/ OUT:                                                         |
 |                    p_credit_rec                                           |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |      19-NOV-01       Santosh Vaze                    Bug Fix 2109490      |
 |                                                                           |
 +===========================================================================*/
PROCEDURE update_header(
  p_form_name                   IN varchar2,
  p_form_version                IN number,
  p_customer_trx_id             IN ra_customer_trx.customer_trx_id%type,
  p_trx_rec                     IN OUT NOCOPY ra_customer_trx%rowtype,
  p_trx_class                   IN ra_cust_trx_types.type%type,
  p_gl_date                     IN ra_cust_trx_line_gl_dist.gl_date%type,
  p_primary_salesrep_id         IN ra_salesreps.salesrep_id%type,
  p_currency_code               IN fnd_currencies.currency_code%type,
  p_prev_customer_trx_id        IN ra_customer_trx.customer_trx_id%type,
  p_line_percent                IN number,
  p_freight_pecent              IN number,
  p_line_amount                 IN ra_customer_trx_lines.extended_amount%type,
  p_freight_amount              IN ra_customer_trx_lines.extended_amount%type,
  p_credit_amount               IN ra_customer_trx_lines.extended_amount%type,
  p_cr_txn_invoicing_rule_id    IN ra_customer_trx.invoicing_rule_id%type,
  p_rederive_credit_info        IN varchar2,
  p_rerun_aa                    IN varchar2,
  p_rerun_cm_module             IN varchar2,
  p_compute_tax                 IN varchar2,
  p_tax_percent             IN OUT NOCOPY number,
  p_tax_amount              IN OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_status                     OUT NOCOPY varchar2)
IS
  l_old_trx_rec                ra_customer_trx%rowtype;
  l_dist_rec                   ra_cust_trx_line_gl_dist%rowtype;
  l_exchange_rate              ra_customer_trx.exchange_rate%type;
  l_exch_rate_changed_flag     boolean;
  l_complete_changed_flag      boolean;
  l_gl_date_changed_flag       boolean;
  l_frt_only_rules             boolean;
  l_acct_set_change            varchar2(10);

  l_recalc_tax_flag            boolean := FALSE;
  l_trx_number_change_flag     boolean := FALSE; --Bug2109490
  orig_trx_number              ra_customer_trx.trx_number%type;
  l_failure_count              number;

  l_tax_status                 varchar2(100) := 'OK';
  l_derive_status              varchar2(100) := 'OK';
  l_cmm_status                 varchar2(100) := 'OK';
  --BUG#2750340
  l_ev_rec  arp_xla_events.xla_events_type;
  l_action			VARCHAR2(10);
  l_return_status 		VARCHAR2(1);
  l_msg_data			VARCHAR2(4000);
  l_msg_count			NUMBER;
  l_ret_status    NUMBER;

  --6870437
  l_event_source_info   xla_events_pub_pkg.t_event_source_info;
  l_event_id            NUMBER;
  l_security            xla_events_pub_pkg.t_security;

  CURSOR l_rec IS
  SELECT 222,
         min(ev.event_id) event_id,
         trx.legal_entity_id legal_entity_id,
         trx.set_of_books_id set_of_books_id,
         xet.entity_code entity_code,
         trx.trx_number trx_number,
         trx.customer_trx_id customer_trx_id,
         trx.org_id org_id
  FROM ra_customer_trx              trx,
       ra_cust_trx_line_gl_dist      gld,
       xla_transaction_entities_upg  xet,
       xla_events                    ev
  WHERE trx.customer_trx_id     = p_customer_trx_id
 AND trx.customer_trx_id       =  gld.customer_trx_id
 AND gld.account_class         = 'REC'
 AND gld.posting_control_id    = -3
 AND gld.latest_rec_flag	= 'Y'
  AND trx.SET_OF_BOOKS_ID       = xet.LEDGER_ID
  AND xet.application_id        = 222
  AND nvl(xet.source_id_int_1, -99)       = trx.customer_trx_id
  AND xet.entity_code           = 'TRANSACTIONS'
  AND xet.entity_id             = ev.entity_id
  AND ev.application_id         = 222
  AND ev.event_status_code  = 'I'
  group by trx.legal_entity_id,
         trx.set_of_books_id,
         xet.entity_code,
         trx.trx_number,
         trx.customer_trx_id,
         trx.org_id;

BEGIN
    arp_util.debug('arp_process_credit.update_header()+');

   /*--------------------------------------------------------------+
    | check form version to determine IF it is compatible with the |
    | entity handler.                                              |
    +--------------------------------------------------------------*/

    arp_trx_validate.ar_entity_version_check(p_form_name, p_form_version);

    p_status := 'OK';
   /*---------------------------------------------+
    | Validate the record that is being updated   |
    +---------------------------------------------*/
    validate_update_header;

--Bug2109490
   /*----------------------------------------------------------------------+
    | The procedure arp_process_tax.before_update_cm_header checks whether |
    | transaction number has been replaced by document sequence value.     |
    | If Yes, this is identified as Tax Event for Vendors and Vendor data  |
    | is synchronized with the new transaction number.                     |
    | This is not a Tax Event for GTE.                                     |
    +----------------------------------------------------------------------*/
arp_util.debug( 'p_compute_tax : ' || p_compute_tax);
arp_util.debug( 'p_rederive_credit_info : ' || p_rederive_credit_info);
arp_util.debug( 'p_trx_rec.trx_number : ' || p_trx_rec.trx_number);
arp_util.debug( 'p_trx_rec.old_trx_number : ' || p_trx_rec.old_trx_number);
    l_trx_number_change_flag := FALSE;


    IF ( p_trx_rec.old_trx_number is not null )
    THEN

      BEGIN
        SELECT trx_number
        INTO   orig_trx_number
        FROM   ra_customer_trx
        WHERE  customer_trx_id = p_customer_trx_id;

        arp_util.debug( 'orig_trx_number : ' || orig_trx_number);

        IF p_trx_rec.trx_number <> orig_trx_number
        THEN
           l_trx_number_change_flag := TRUE;
           --Bug Fix 7115142 Synchronization for Document Sequence should happen only after the header has been updated.
           /* arp_etax_util.synchronize_for_doc_seq(null,
                        p_customer_trx_id); */
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          RAISE;
      END;

    END IF;

--Bug2109490
    arp_util.debug('l_trx_number_change_flag : '||arp_trx_util.boolean_to_varchar2(l_trx_number_change_flag));
    --
    -- call Tax engine, checking if tax needs to be recalculated
    --
   l_action := arp_etax_services_pkg.Get_tax_Action(p_customer_trx_id);

   IF (l_action = 'UPDATE') THEN
      -- next call the etax for header det factor update
      arp_etax_services_pkg.Header_det_factors(
                    p_customer_trx_id => p_customer_trx_id,
                    p_mode => l_action,
                    x_return_status => l_return_status,
                    x_msg_count => l_msg_count,
                    x_msg_data => l_msg_data);
      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         p_status := 'ETAX_ERROR';
      END IF;
   END IF;

   /*---------------------------------------------------------------+
    | Lock rows in other tables that reference this customer_trx_id |
    | and the credited transaction                                  |
    +---------------------------------------------------------------*/
    arp_trx_util.lock_transaction(p_customer_trx_id);

    set_header_flags(p_customer_trx_id,
                     p_trx_rec,
                     p_gl_date,
                     l_exch_rate_changed_flag,
                     l_gl_date_changed_flag,
                     l_complete_changed_flag,
                     l_old_trx_rec);

   /*---------------------------------------------------------------+
    | If the CM is a freight-only transaction and if the credited   |
    | transaction has rules, then clear out NOCOPY invoicing_rule_id on CM |
    | If CM is made incomplete and if the credited transaction has  |
    | rules, then set the invoicing_rule_id on CM                   |
    +---------------------------------------------------------------*/
   l_acct_set_change := null;

   IF ((l_complete_changed_flag = TRUE)
       AND
       (p_prev_customer_trx_id IS NOT NULL))
   THEN
       l_frt_only_rules :=
                arp_trx_util.detect_freight_only_rules_case(p_customer_trx_id);

       IF p_trx_rec.complete_flag = 'Y'
       THEN
           IF ((l_frt_only_rules = TRUE)
               AND
               (p_cr_txn_invoicing_rule_id IS NOT NULL))
           THEN
               p_trx_rec.invoicing_rule_id := null;
               l_acct_set_change := 'REAL';
           END IF;
       ELSE
           IF ((l_frt_only_rules = TRUE)
                AND
               (p_cr_txn_invoicing_rule_id IS NOT NULL))
           THEN
               p_trx_rec.invoicing_rule_id := p_cr_txn_invoicing_rule_id;
               l_acct_set_change := 'ACCT_SET';
           END IF;
       END IF;

    END IF;

   /*----------------------+
    |  call table-handler  |
    +----------------------*/
    arp_ct_pkg.update_p(p_trx_rec, p_customer_trx_id);

   /*---------------------+

    |  post-update logic  |
    +---------------------*/

    --Bug Fix 7115142, Synchronize Document Sequence if required
    IF(l_trx_number_change_flag) THEN
         arp_etax_util.synchronize_for_doc_seq(p_customer_trx_id,l_ret_status);

         IF l_ret_status > 0
         THEN
           arp_util.debug('EXCEPTION:  error calling eBusiness Tax, status = ' ||
                           l_ret_status);
           arp_util.debug('Please review the plsql debug log for additional details.');
           p_status := 'SYNCH_DOC_SEQ_ERROR';
         END IF;
    END IF;

IF ( nvl(p_status, 'OK') <> 'SYNCH_DOC_SEQ_ERROR' )
THEN --bug 7193337
    IF p_trx_rec.exchange_rate = pg_number_dummy THEN
        l_exchange_rate := nvl(l_old_trx_rec.exchange_rate, 1);
    ELSE
        l_exchange_rate := nvl(p_trx_rec.exchange_rate, 1);
    END IF;

    IF (l_acct_set_change = 'REAL')
    THEN
        arp_ctlgd_pkg.set_to_dummy(l_dist_rec);

        l_dist_rec.account_set_flag := 'N';

        l_dist_rec.acctd_amount := arp_standard.functional_amount(
                                                 p_credit_amount,
                                                 pg_base_curr_code,
                                                 l_exchange_rate,
                                                 pg_base_precision,
                                                 pg_base_min_acc_unit);
        l_dist_rec.amount := p_credit_amount;
        l_dist_rec.gl_date := p_gl_date;
        l_dist_rec.original_gl_date := p_gl_date;

        arp_ctlgd_pkg.update_f_ct_id(l_dist_rec,
                                    p_customer_trx_id,
                                    null,
                                    null);

    ELSIF (l_acct_set_change = 'ACCT_SET')
    THEN

        arp_ctlgd_pkg.set_to_dummy(l_dist_rec);

        l_dist_rec.account_set_flag := 'Y';

        --
        -- update acct_set_flag = Y for REC record
        --
        arp_ctlgd_pkg.update_f_ct_id(l_dist_rec,
                                     p_customer_trx_id,
                                     'N',
                                     'REC');

        --
        -- now update acct_set_flag = Y for the remaining
        -- account classes
        --
        l_dist_rec.account_set_flag := 'N';
        l_dist_rec.amount           := null;
        l_dist_rec.acctd_amount     := null;
        l_dist_rec.original_gl_date := null;
        l_dist_rec.gl_date          := null;

        arp_ctlgd_pkg.update_f_ct_id(l_dist_rec,
                                     p_customer_trx_id,
                                     'Y',
                                     null);
    END IF;

--Bug2109490
arp_util.debug( 'p_prev_customer_trx_id : ' || to_char( p_prev_customer_trx_id ));
arp_util.debug( 'p_rederive_credit_info : ' || p_rederive_credit_info);
arp_util.debug(' l_recalc_tax_flag : '||arp_trx_util.boolean_to_varchar2(l_recalc_tax_flag));
arp_util.debug( 'p_compute_tax : ' || p_compute_tax);
arp_util.debug('l_trx_number_change_flag : '||arp_trx_util.boolean_to_varchar2(l_trx_number_change_flag));

    IF (( p_prev_customer_trx_id IS NOT NULL)
        AND
        nvl(p_rederive_credit_info, 'N') = 'Y' )
    THEN
        --
        -- if rederive credit memo info is set, then delete all records
        -- and rederive info if any of the amounts are not null
        --

arp_util.debug( 'p_prev_customer_trx_id : ' || to_char( p_prev_customer_trx_id ));
arp_util.debug( 'p_customer_trx_id : ' || to_char( p_customer_trx_id ));
        delete_cm_records(p_customer_trx_id, l_trx_number_change_flag);
        /*Bug 8974913*/
        IF ( p_compute_tax = 'Y' AND p_tax_amount <> 0)
        THEN
            p_tax_amount := NULL;
            p_tax_percent := NULL;
        END IF;

        IF ( p_line_amount IS NOT NULL
             OR
             p_tax_amount IS NOT NULL
             OR
             p_freight_amount IS NOT NULL)
        THEN
            derive_credit_information(p_form_name,
                                      p_form_version,
                                      p_customer_trx_id,
                                      p_prev_customer_trx_id,
                                      p_line_amount,
                                      p_freight_amount,
                                      p_currency_code,
                                      p_gl_date,
                                      p_primary_salesrep_id,
                                      p_compute_tax,
				      p_line_percent,
                                      p_tax_amount,
                                      l_derive_status);
        END IF;

    END IF;

    IF (l_exch_rate_changed_flag = TRUE
        AND
        l_acct_set_change IS NULL
        AND
        nvl(p_rederive_credit_info, 'N') = 'N')
    THEN
        arp_ctlgd_pkg.update_acctd_amount(p_customer_trx_id,
                                          pg_base_curr_code,
                                          l_exchange_rate,
                                          pg_base_precision,
                                          pg_base_min_acc_unit);
    END IF;

    IF (l_gl_date_changed_flag = TRUE
        AND
        l_acct_set_change IS NULL
        AND
        nvl(p_rederive_credit_info, 'N') = 'N')
    THEN
        arp_ctlgd_pkg.set_to_dummy(l_dist_rec);
        l_dist_rec.gl_date := p_gl_date;

        BEGIN
            /* Bug 3251996 Updating the gl_date of the distributions
               with account_set_flag Y for CM's attached to invoice
               with rules.Else the distributions with account_set_flag
               N is updated with the gl_date. */

            IF (p_cr_txn_invoicing_rule_id IS NOT NULL)
            THEN
            arp_ctlgd_pkg.update_f_ct_id(l_dist_rec,
                                         p_customer_trx_id,
                                         'Y',
                                         null);
            ELSE
            arp_ctlgd_pkg.update_f_ct_id(l_dist_rec,
                                         p_customer_trx_id,
                                         'N',
                                         null);
            END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
               arp_util.debug('arp_process_credit.update_header: '||
                              'no distributions to update');
          WHEN OTHERS THEN
               arp_util.debug('EXCEPTION : arp_process_credit.update_header');
               arp_util.debug('            update gl_date');
               RAISE;
        END;
    END IF;

    IF (p_rerun_cm_module = 'Y'
        AND
        nvl(p_rederive_credit_info, 'N') = 'N')
    THEN
           BEGIN
               arp_util.debug('update_header() : credit_transactions');

               arp_credit_memo_module.credit_transactions(
                         p_customer_trx_id,
                         null,
                         p_prev_customer_trx_id,
                         null,
                         null,
                         l_failure_count,
                         'U');
           EXCEPTION
             WHEN arp_credit_memo_module.no_ccid THEN
               arp_util.debug('credit memo module exception : no_ccid');
               l_cmm_status := 'ARP_CREDIT_MEMO_MODULE.NO_CCID';
             WHEN NO_DATA_FOUND THEN
               arp_util.debug('credit memo module exception : no_data_found');
               null;
             WHEN app_exception.application_exception THEN
               arp_util.debug('credit memo module exception : app_exception ');
               RAISE;
             WHEN OTHERS THEN
               RAISE;
           END;

    END IF;
     /* Bug 3619804 Added the call to the procedure reverse_revrec_effect_cm */
    arp_util.debug('Complete_changed_flag : '||arp_trx_util.boolean_to_varchar2(l_complete_changed_flag));
    arp_util.debug('Complete Flag         : '|| p_trx_rec.complete_flag);
    arp_util.debug('Customer_trx_id       : '|| p_customer_trx_id );
    arp_util.debug('CM invoicing_rule_id  : '|| p_cr_txn_invoicing_rule_id );
    arp_util.debug('CM Rev Recog Run Flag : ' ||arpt_sql_func_util.get_revenue_recog_run_flag(p_customer_trx_id,p_cr_txn_invoicing_rule_id));

     IF l_complete_changed_flag  AND p_trx_rec.complete_flag = 'N'
       THEN
          IF  p_cr_txn_invoicing_rule_id IS NOT NULL
          AND arpt_sql_func_util.get_revenue_recog_run_flag(p_customer_trx_id,
                                          p_cr_txn_invoicing_rule_id) = 'Y'
          THEN

	      reverse_revrec_effect_cm(p_customer_trx_id);

          END IF;
      END IF;   /* IF l_complete_flag_changed */


    arp_util.debug('l_tax_status      : '|| l_tax_status);
    arp_util.debug('l_derive_status   : '|| l_derive_status);
    arp_util.debug('l_cmm_status      : '|| l_cmm_status);

    IF (NVL(l_tax_status, 'OK') <> 'OK') THEN
        p_status := l_tax_status;
    ELSIF (NVL(l_derive_status, 'OK') <> 'OK' ) THEN
        p_status := l_derive_status;
    ELSIF (NVL(l_cmm_status, 'OK') <> 'OK' ) THEN
        p_status := l_cmm_status;
    END IF;

 --6870437
IF  p_trx_rec.complete_flag = 'N'  AND l_gl_date_changed_flag = TRUE
    AND p_cr_txn_invoicing_rule_id IS NOT NULL  THEN

  FOR c IN l_rec loop

  l_event_source_info.application_id    := 222;
  l_event_source_info.legal_entity_id   := c.legal_entity_id;
  l_event_source_info.ledger_id         := c.set_of_books_id;
  l_event_source_info.entity_type_code  := c.entity_code;
  l_event_source_info.transaction_number:= c.trx_number;
  l_event_source_info.source_id_int_1   := c.customer_trx_id;

  l_security.security_id_int_1          :=  c.org_id;
  l_event_id                            :=  c.event_id;

    xla_events_pub_pkg.update_event
               (p_event_source_info    => l_event_source_info,
                p_event_id             => l_event_id,
                p_event_date           => p_gl_date,
                p_valuation_method     => null,
                p_transaction_date     => p_trx_rec.trx_date,
                p_security_context     => l_security);
  END loop;
  ELSE

   -- BUG#2750340 : Call AR_XLA_EVENTS
    l_ev_rec.xla_from_doc_id   := p_customer_trx_id;
    l_ev_rec.xla_to_doc_id     := p_customer_trx_id;
    l_ev_rec.xla_req_id        := NULL;
    l_ev_rec.xla_dist_id       := NULL;
    l_ev_rec.xla_doc_table     := 'CT';
    l_ev_rec.xla_doc_event     := NULL;
    l_ev_rec.xla_mode          := 'O';
    l_ev_rec.xla_call          := 'B';
    l_ev_rec.xla_fetch_size    := 999;
    arp_xla_events.create_events(p_xla_ev_rec => l_ev_rec );

 END IF;
END IF; --bug 7193337
    arp_util.debug('arp_process_credit.update_header()-');

EXCEPTION

  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION : arp_process_credit.update_header');

    RAISE;
END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    insert_line                                                            |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Inserts a row into RA_CUSTOMER_TRX_LINES for Credit Memos              |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_form_name                                            |
 |                    p_form_version                                         |
 |                    p_credit_rec                                           |
 |                    p_trx_class                                            |
 |                    p_gl_date                                              |
 |                    p_credit_ccid                                          |
 |              OUT:                                                         |
 |                    p_customer_trx_line_id                                 |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95	Subash Chadalavada		Created              |
 |                                                                           |
 +===========================================================================*/

PROCEDURE insert_line(
  p_form_name			IN varchar2,
  p_form_version		IN number,
  p_credit_rec			IN ra_customer_trx_lines%rowtype,
  p_line_amount                 IN ra_customer_trx_lines.extended_amount%type,
  p_freight_amount              IN ra_customer_trx_lines.extended_amount%type,
  p_line_percent                IN number,
  p_freight_percent             IN number,
  p_memo_line_type              IN ar_memo_lines.line_type%type,
  p_gl_date                     IN ra_cust_trx_line_gl_dist.gl_date%type,
  p_currency_code               IN fnd_currencies.currency_code%type,
  p_primary_salesrep_id         IN ra_salesreps.salesrep_id%type,
  p_compute_tax                 IN varchar2,
  p_customer_trx_id             IN ra_customer_trx.customer_trx_id%type,
  p_prev_customer_trx_id        IN ra_customer_trx_lines.customer_trx_id%type,
  p_prev_customer_trx_line_id   IN
                              ra_customer_trx_lines.customer_trx_line_id%type,
  p_tax_percent             IN OUT NOCOPY number,
  p_tax_amount              IN OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_customer_trx_line_id	OUT NOCOPY
                              ra_customer_trx_lines.customer_trx_line_id%type,
  p_status                     OUT NOCOPY varchar2)
IS

  l_customer_trx_line_id  ra_customer_trx_lines.customer_trx_line_id%type;
  l_credit_rec		  ra_customer_trx_lines%rowtype;
  l_line_credit_flag      boolean;
  l_tax_credit_flag       boolean;
  l_freight_credit_flag   boolean;

  l_account_class         ra_customer_trx_lines.line_type%type;

  l_uncr_line_amount     number;
  l_uncr_tax_amount      number;
  l_uncr_freight_amount  number;
  l_trx_balance_due            number;
  l_line_balance_due           number;
  l_tax_balance_due            number;
  l_freight_balance_due        number;
  l_memo_line_type         ar_memo_lines.line_type%type;
  l_freight_type           varchar2(1);
  l_freight_ctl_id         ra_customer_trx_lines.customer_trx_line_id%type;

  l_result                integer;
  l_ccid                  ra_cust_trx_line_gl_dist.code_combination_id%type;
  l_concat_segments       varchar2(200);
  l_num_failed_dist_rows  number;
  l_rows_processed        number;
  l_errorbuf              varchar2(2000);

  l_rule_start_date             date;
  l_accounting_rule_duration    number;


  l_frt_status            varchar2(30) := 'OK';
  l_tax_status            varchar2(30) := 'OK';
  l_aa_status             varchar2(30) := 'OK';
  l_cmm_status            varchar2(30) := 'OK';

  l_mode                  varchar2(30);

BEGIN

   arp_util.debug('arp_process_credit.insert_line()+');

   /*--------------------------------------------------------------+
    | check form version to determine IF it is compatible with the |
    | entity handler.                                              |
    +--------------------------------------------------------------*/

   arp_trx_validate.ar_entity_version_check(p_form_name, p_form_version);

   /*---------------------------------------------------------------+
    | Lock rows in other tables that reference this customer_trx_id |
    | and the credited transaction                                  |
    +---------------------------------------------------------------*/
   arp_trx_util.lock_transaction(p_customer_trx_id);

   /*--------------------+
    |  pre-insert logic  |
    +--------------------*/

   default_credit_line(p_credit_rec,
                       p_customer_trx_id,
                       p_prev_customer_trx_line_id,
                       p_line_amount,
                       l_credit_rec);
   /*4556000-4606558*/
   /* This condition is added to keep intact of work flow functionality*/
   IF p_credit_rec.attribute_category IS NOT NULL then
      l_credit_rec.attribute_category:=p_credit_rec.attribute_category;
      l_credit_rec.attribute1:=p_credit_rec.attribute1;
      l_credit_rec.attribute2:=p_credit_rec.attribute2;
      l_credit_rec.attribute3:=p_credit_rec.attribute3;
      l_credit_rec.attribute4:=p_credit_rec.attribute4;
      l_credit_rec.attribute5:=p_credit_rec.attribute5;
      l_credit_rec.attribute6:=p_credit_rec.attribute6;
      l_credit_rec.attribute7:=p_credit_rec.attribute7;
      l_credit_rec.attribute8:=p_credit_rec.attribute8;
      l_credit_rec.attribute9:=p_credit_rec.attribute9;
      l_credit_rec.attribute10:=p_credit_rec.attribute10;
      l_credit_rec.attribute11:=p_credit_rec.attribute11;
      l_credit_rec.attribute12:=p_credit_rec.attribute12;
      l_credit_rec.attribute13:=p_credit_rec.attribute13;
      l_credit_rec.attribute14:=p_credit_rec.attribute14;
      l_credit_rec.attribute15:=p_credit_rec.attribute15;
   END IF;

   IF p_credit_rec.interface_line_context IS NOT NULL then
      l_credit_rec.interface_line_context:=p_credit_rec.interface_line_context;
      l_credit_rec.interface_line_attribute1:=p_credit_rec.interface_line_attribute1;
      l_credit_rec.interface_line_attribute2:=p_credit_rec.interface_line_attribute2;
      l_credit_rec.interface_line_attribute3:=p_credit_rec.interface_line_attribute3;
      l_credit_rec.interface_line_attribute4:=p_credit_rec.interface_line_attribute4;
      l_credit_rec.interface_line_attribute5:=p_credit_rec.interface_line_attribute5;
      l_credit_rec.interface_line_attribute6:=p_credit_rec.interface_line_attribute6;
      l_credit_rec.interface_line_attribute7:=p_credit_rec.interface_line_attribute7;
      l_credit_rec.interface_line_attribute8:=p_credit_rec.interface_line_attribute8;
      l_credit_rec.interface_line_attribute9:=p_credit_rec.interface_line_attribute9;
      l_credit_rec.interface_line_attribute10:=p_credit_rec.interface_line_attribute10;
      l_credit_rec.interface_line_attribute11:=p_credit_rec.interface_line_attribute11;
      l_credit_rec.interface_line_attribute12:=p_credit_rec.interface_line_attribute12;
      l_credit_rec.interface_line_attribute13:=p_credit_rec.interface_line_attribute13;
      l_credit_rec.interface_line_attribute14:=p_credit_rec.interface_line_attribute14;
      l_credit_rec.interface_line_attribute15:=p_credit_rec.interface_line_attribute15;
   END IF;

   IF p_credit_rec.global_attribute_category is not null then
      l_credit_rec.global_attribute_category:=p_credit_rec.global_attribute_category;
      l_credit_rec.global_attribute1:=p_credit_rec.global_attribute1;
      l_credit_rec.global_attribute2:=p_credit_rec.global_attribute2;
      l_credit_rec.global_attribute3:=p_credit_rec.global_attribute3;
      l_credit_rec.global_attribute4:=p_credit_rec.global_attribute4;
      l_credit_rec.global_attribute5:=p_credit_rec.global_attribute5;
      l_credit_rec.global_attribute6:=p_credit_rec.global_attribute6;
      l_credit_rec.global_attribute7:=p_credit_rec.global_attribute7;
      l_credit_rec.global_attribute8:=p_credit_rec.global_attribute8;
      l_credit_rec.global_attribute9:=p_credit_rec.global_attribute9;
      l_credit_rec.global_attribute10:=p_credit_rec.global_attribute10;
      l_credit_rec.global_attribute11:=p_credit_rec.global_attribute11;
      l_credit_rec.global_attribute12:=p_credit_rec.global_attribute12;
      l_credit_rec.global_attribute13:=p_credit_rec.global_attribute13;
      l_credit_rec.global_attribute14:=p_credit_rec.global_attribute14;
      l_credit_rec.global_attribute15:=p_credit_rec.global_attribute15;
      l_credit_rec.global_attribute16:=p_credit_rec.global_attribute16;
      l_credit_rec.global_attribute17:=p_credit_rec.global_attribute17;
      l_credit_rec.global_attribute18:=p_credit_rec.global_attribute18;
      l_credit_rec.global_attribute19:=p_credit_rec.global_attribute19;
      l_credit_rec.global_attribute20:=p_credit_rec.global_attribute20;
   END IF;

   arp_process_credit.validate_insert_line(l_credit_rec);

   -- call the table handler
   arp_ctl_pkg.insert_p(l_credit_rec, l_customer_trx_line_id);

   p_customer_trx_line_id := l_customer_trx_line_id;

   /*--------------------+
    |  post-insert logic |
    +--------------------*/

   create_salescredits( p_customer_trx_id,
                        l_customer_trx_line_id,
                        p_memo_line_type,
                        p_primary_salesrep_id,
                        p_currency_code);
   --
   -- if regular credit memo, then credit freight lines if freight credit
   -- is passed
   --

   IF (p_prev_customer_trx_id IS NOT NULL)
   THEN
       get_uncredit_amounts(p_customer_trx_id,
                            null,
                            p_prev_customer_trx_id,
                            p_prev_customer_trx_line_id,
                            'INSERT',
                            l_uncr_line_amount,
                            l_uncr_tax_amount,
                            l_uncr_freight_amount,
                            l_memo_line_type,
                            l_freight_type,
                            l_freight_ctl_id);
   END IF;

   IF (p_freight_amount IS NOT NULL)
   THEN
       credit_freight(p_form_name,
                      p_form_version,
                      p_customer_trx_id,
                      l_customer_trx_line_id,
                      p_prev_customer_trx_id,
                      p_prev_customer_trx_line_id,
                      p_freight_amount,
                      l_uncr_freight_amount,
                      l_freight_type,
                      l_freight_ctl_id,
                      'INSERT',
                      p_gl_date,
                      p_currency_code,
                      l_frt_status);
   END IF;

   /* R12 eTax uptake - we need to call the line_Det_Factors table handler to
      set the attributes for calculating tax */

   /* 5402228 - clarified use of tax for line-only scenarios.  There are
      two to be concerned with.  They are:

      1) inv or cm with memo_line of type TAX -
             INSERT_NO_TAX       - LINE_INFO_TAX_ONLY
      2) inv or cm with no tax at all
             INSERT_NO_TAX_EVER  - RECORD_WITH_NO_TAX
   */
   IF NVL(p_tax_amount,0) = 0
      AND p_form_name = 'ARXTWCMI'
   THEN

      IF NVL(p_memo_line_type, 'XXX') = 'TAX'
      THEN
         l_mode := 'INSERT_NO_TAX';
      ELSE
         l_mode := 'INSERT_NO_TAX_EVER';
      END IF;

   ELSIF NVL(p_line_amount,0) = 0 THEN
      l_mode := 'INSERT_NO_LINE';
   ELSE
      /* 7658882 - determine if tax should be called
         based on p_form (source) and p_compute_tax parameters */
      IF p_form_name = 'AR_CREDIT_MEMO_API'
      THEN
         IF p_compute_tax = 'Y'
         THEN
            /* 7658882 - this is the condition for line+tax */
            l_mode := 'INSERT';
         ELSE
            /* This is for line-only */
            l_mode := 'INSERT_NO_TAX_EVER';
         END IF;
      ELSE
         /* original behavior */
         l_mode := 'INSERT';
      END IF;

   END IF;

   ARP_ETAX_SERVICES_PKG.line_det_factors(
         p_customer_trx_line_id => l_customer_trx_line_id,
         p_customer_trx_id => p_customer_trx_id,
         p_mode => l_mode,
         p_tax_amount => p_tax_amount);

   IF (p_prev_customer_trx_id IS NULL)
   THEN
       -- create distributions for on-account CM lines

       IF (p_memo_line_type = 'CHARGES')
       THEN
           l_account_class := 'CHARGES';
       ELSE
           l_account_class := 'REV';
       END IF;

       BEGIN
        arp_auto_accounting.do_autoaccounting(
                                'I',
                                l_account_class,
                                p_customer_trx_id,
                                l_customer_trx_line_id,
                                null,
                                null,
                                p_gl_date,
                                null,
                                p_line_amount,
                                null,
                                null,
                                null,
                                null,
                                null,
                                null,
                                l_ccid,
                                l_concat_segments,
                                l_num_failed_dist_rows );
   EXCEPTION
     WHEN arp_auto_accounting.no_ccid THEN
       l_aa_status := 'ARP_AUTO_ACCOUNTING.NO_CCID';
     WHEN NO_DATA_FOUND THEN
       null;
     WHEN OTHERS THEN
       RAISE;
   END;

   ELSE
       -- call credit-memo module for regular credit-memo case
       /*-------------------------------+
        | call credit memo module       |
        +-------------------------------*/
     BEGIN
        arp_credit_memo_module.credit_transactions(
                            p_customer_trx_id,
                            l_customer_trx_line_id,
                            p_prev_customer_trx_id,
                            p_prev_customer_trx_line_id,
                            null,
                            l_num_failed_dist_rows,
                            l_rule_start_date,
                            l_accounting_rule_duration,
                            'I');
     EXCEPTION
       WHEN arp_credit_memo_module.no_ccid THEN
         l_cmm_status := 'ARP_CREDIT_MEMO_MODULE.NO_CCID';
       WHEN NO_DATA_FOUND THEN
         null;
       WHEN OTHERS THEN
         RAISE;
     END;

   END IF;

   arp_util.debug('l_tax_status   : '||l_tax_status);
   arp_util.debug('l_frt_status   : '||l_frt_status);
   arp_util.debug('l_aa_status    : '||l_aa_status);
   arp_util.debug('l_cmm_status   : '||l_cmm_status);

   IF (NVL(l_tax_status, 'OK') <> 'OK') THEN
      p_status := l_tax_status;
   ELSIF (NVL(l_frt_status, 'OK') <> 'OK') THEN
      p_status := l_frt_status;
   ELSIF (NVL(l_aa_status, 'OK') <> 'OK') THEN
      p_status := l_aa_status;
   ELSIF (NVL(l_cmm_status, 'OK') <> 'OK') THEN
      p_status := l_cmm_status;
   END IF;

   arp_util.debug('arp_process_credit.insert_line()-');

EXCEPTION
   when OTHERS THEN
     arp_util.debug('EXCEPTION: arp_process_credit.insert_line()');
     arp_ctl_pkg.display_line_rec(l_credit_rec);
     RAISE;
END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    set_line_flags                                                         |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Compares the line   record with that existing in the database and      |
 |    sets various flags                                                     |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_customer_trx_line_id                                 |
 |                    p_new_trx_rec                                          |
 |                    p_new_gl_date                                          |
 |              OUT:                                                         |
 |                    p_exch_rate_changed_flag                               |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada              Created              |
 |                                                                           |
 +===========================================================================*/
PROCEDURE set_line_flags(
  p_line_rec             IN  ra_customer_trx_lines%rowtype,
  p_customer_trx_id      IN  ra_customer_trx.customer_trx_id%type,
  p_customer_trx_line_id IN  ra_customer_trx_lines.customer_trx_line_id%type,
  p_prev_ct_id           IN  ra_customer_trx.customer_trx_id%type,
  p_prev_ctl_id          IN  ra_customer_trx_lines.customer_trx_line_id%type,
  p_line_amount          IN  number,
  p_tax_amount           IN  number,
  p_frt_amount           IN  number,
  p_cr_line_amount       OUT NOCOPY number,
  p_cr_tax_amount        OUT NOCOPY number,
  p_cr_frt_amount        OUT NOCOPY number,
  p_line_amt_chng_flag   OUT NOCOPY boolean,
  p_tax_amt_chng_flag    OUT NOCOPY boolean,
  p_frt_amt_chng_flag    OUT NOCOPY boolean,
  p_tax_mode             OUT NOCOPY varchar2,
  p_frt_mode             OUT NOCOPY varchar2,
  p_frt_ctlid            OUT NOCOPY ra_customer_trx_lines.customer_trx_line_id%type,
  p_cm_complete_flag     OUT NOCOPY ra_customer_trx.complete_flag%type,
  p_old_line_rec         OUT NOCOPY ra_customer_trx_lines%rowtype)
IS

  l_old_line_rec          ra_customer_trx_lines%rowtype;

  l_frt_amount            ra_customer_trx_lines.extended_amount%type;
  l_frt_ctlid             ra_customer_trx_lines.customer_trx_line_id%type;

  l_cm_complete_flag      ra_customer_trx.complete_flag%type;
  l_credited_line_amount  number;
  l_credited_tax_amount   number;
  l_credited_frt_amount   number;

  l_line_amt_chng_flag   boolean;
  l_tax_amt_chng_flag    boolean;
  l_frt_amt_chng_flag    boolean;
  l_tax_mode             varchar2(10);
  l_frt_mode             varchar2(10);


BEGIN

    arp_util.debug('arp_process_credit.set_line_flags()+');

    arp_ctl_pkg.fetch_p(l_old_line_rec, p_customer_trx_line_id);

    arp_process_credit.get_cm_amounts(
           p_customer_trx_id,
           p_customer_trx_line_id,
           p_prev_ct_id,
           p_prev_ctl_id,
           l_cm_complete_flag,
           l_credited_line_amount,
           l_credited_tax_amount,
           l_credited_frt_amount);

    p_cr_line_amount := l_credited_line_amount;
    p_cr_tax_amount  := l_credited_tax_amount;
    p_cr_frt_amount  := l_credited_frt_amount;

    IF (nvl(p_line_rec.extended_amount, 0) <> pg_number_dummy
        AND
        nvl(p_line_rec.extended_amount, pg_number_dummy) <>
            nvl(l_old_line_rec.extended_amount, pg_number_dummy))
    THEN
        l_line_amt_chng_flag := TRUE;
    ELSE
        l_line_amt_chng_flag := FALSE;
    END IF;

    IF (nvl(p_frt_amount, pg_number_dummy) <>
        nvl(l_credited_frt_amount, pg_number_dummy))
    THEN
        l_frt_amt_chng_flag := TRUE;

        IF p_frt_amount IS NULL
        THEN
           l_frt_mode := 'DELETE';
        ELSIF l_credited_frt_amount IS NULL
        THEN
           l_frt_mode := 'INSERT';
        ELSE
           l_frt_mode := 'UPDATE';
        END IF;
    ELSE
        l_frt_amt_chng_flag := FALSE;
    END IF;

    IF (nvl(p_tax_amount, pg_number_dummy) <>
        nvl(l_credited_tax_amount, pg_number_dummy))
    THEN
        l_tax_amt_chng_flag := TRUE;

        IF p_tax_amount IS NULL
        THEN
           l_tax_mode := 'DELETE';
        ELSIF l_credited_tax_amount IS NULL
        THEN
           l_tax_mode := 'INSERT';
        ELSE
           l_tax_mode := 'UPDATE';
        END IF;
    ELSE
        l_tax_amt_chng_flag := FALSE;
    END IF;

    p_cr_line_amount     := l_credited_line_amount;
    p_cr_tax_amount      := l_credited_tax_amount;
    p_cr_frt_amount      := l_credited_frt_amount;
    p_line_amt_chng_flag := l_line_amt_chng_flag;
    p_tax_amt_chng_flag  := l_tax_amt_chng_flag;
    p_frt_amt_chng_flag  := l_frt_amt_chng_flag;
    p_tax_mode           := l_tax_mode;
    p_frt_mode           := l_frt_mode;
    p_frt_ctlid          := l_frt_ctlid;
    p_cm_complete_flag   := l_cm_complete_flag;

    arp_util.debug('p_cr_line_amount     : '||l_credited_line_amount);
    arp_util.debug('p_cr_tax_amount      : '||l_credited_tax_amount);
    arp_util.debug('p_cr_frt_amount      : '||l_credited_frt_amount );
    arp_util.debug('p_line_amt_chng_flag : '||
                       arp_trx_util.boolean_to_varchar2(l_line_amt_chng_flag));
    arp_util.debug('p_tax_amt_chng_flag  : '||
                       arp_trx_util.boolean_to_varchar2(l_tax_amt_chng_flag));
    arp_util.debug('p_frt_amt_chng_flag  : '||
                       arp_trx_util.boolean_to_varchar2(l_frt_amt_chng_flag));
    arp_util.debug('p_tax_mode           : '||l_tax_mode);
    arp_util.debug('p_frt_mode           : '||l_frt_mode);
    arp_util.debug('p_frt_ctlid          : '||l_frt_ctlid);
    arp_util.debug('p_cm_complete_flag   : '||l_cm_complete_flag);

    arp_util.debug('arp_process_credit.set_line_flags()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.set_line_flags');
    RAISE;
END;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    update_line                                                            |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Updates the row in RA_CUSTOMER_TRX_LINES for Credit Memos              |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                    p_form_name                                            |
 |                    p_form_version                                         |
 |                    p_credit_rec                                           |
 |                    p_trx_class                                            |
 |                    p_gl_date                                              |
 |                    p_credit_ccid                                          |
 |              OUT:                                                         |
 |                    p_customer_trx_line_id                                 |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |      11-AUG-95       Subash Chadalavada  Created            		     |
 | 	03-SEP-97	Tasman Tang	    Fixed bug 547165: Change type of |
 |					    l_old_line_rec to 		     |
 |					    ra_customer_trx_lines%rowtype    |
 |                                                                           |
 +===========================================================================*/

PROCEDURE update_line(
  p_form_name                   IN varchar2,
  p_form_version                IN number,
  p_credit_rec                  IN ra_customer_trx_lines%rowtype,
  p_customer_trx_line_id        IN
                              ra_customer_trx_lines.customer_trx_line_id%type,
  p_line_amount                 IN ra_customer_trx_lines.extended_amount%type,
  p_freight_amount              IN ra_customer_trx_lines.extended_amount%type,
  p_line_percent                IN number,
  p_freight_percent             IN number,
  p_memo_line_type              IN ar_memo_lines.line_type%type,
  p_gl_date                     IN ra_cust_trx_line_gl_dist.gl_date%type,
  p_currency_code               IN fnd_currencies.currency_code%type,
  p_primary_salesrep_id         IN ra_salesreps.salesrep_id%type,
  p_exchange_rate               IN ra_customer_trx.exchange_rate%type,
  p_rerun_aa                    IN varchar2,
  p_recalculate_tax             IN varchar2,
  p_compute_tax                 IN varchar2,
  p_customer_trx_id             IN ra_customer_trx.customer_trx_id%type,
  p_prev_customer_trx_id        IN ra_customer_trx_lines.customer_trx_id%type,
  p_prev_customer_trx_line_id   IN
                              ra_customer_trx_lines.customer_trx_line_id%type,
  p_tax_percent             IN OUT NOCOPY number,
  p_tax_amount              IN OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_status                     OUT NOCOPY varchar2)
IS

  l_frt_exists_flag          boolean;
  l_line_amt_chng_flag       boolean;
  l_frt_amt_chng_flag        boolean;
  l_tax_amt_chng_flag        boolean;

  l_memo_line_type           ar_memo_lines.line_type%type;
  l_frt_type                 varchar2(1);
  l_prev_frt_ctlid           ra_customer_trx_lines.customer_trx_line_id%type;

  l_uncr_line_amount         number;
  l_uncr_tax_amount          number;
  l_uncr_frt_amount          number;
  l_cr_line_amount           number;
  l_cr_tax_amount            number;
  l_cr_frt_amount            number;
  l_net_uncr_line_amount     number;
  l_net_uncr_tax_amount      number;
  l_net_uncr_frt_amount      number;

  l_tax_mode                 varchar2(10);
  l_frt_mode                 varchar2(10);

  l_cm_complete_flag         ra_customer_trx.complete_flag%type;

  l_frt_ctlid                ra_customer_trx_lines.customer_trx_line_id%type;
  l_old_line_rec             ra_customer_trx_lines%rowtype;
  l_rerun_aa_status          varchar2(30) := 'OK';
  l_tax_status               varchar2(30) := 'OK';
  l_frt_status               varchar2(30) := 'OK';
  l_recalculate_tax_flag     BOOLEAN;

BEGIN
   arp_util.debug('arp_process_credit.update_line()+');

   /*--------------------------------------------------------------+
    | check form version to determine IF it is compatible with the |
    | entity handler.                                              |
    +--------------------------------------------------------------*/

   arp_trx_validate.ar_entity_version_check(p_form_name, p_form_version);

   /*---------------------------------------------------------------+
    | Lock rows in other tables that reference this customer_trx_id |
    | and the credited transaction                                  |
    +---------------------------------------------------------------*/
   arp_trx_util.lock_transaction(p_customer_trx_id);

   /*--------------------+
    |  pre-update logic  |
    +--------------------*/

   arp_process_credit.validate_update_line;

      BEGIN


        --  Check to see if any relevant columns have been updated which
        --  affect tax calculation. If there are columns which affect tax
        --  have been modified, we will delete the tax lines and the
        --  accounting from those lines before we will eventually call
        --  ETAX to recreate the tax lines.

        arp_etax_services_pkg.before_update_line(
                       p_customer_trx_line_id,
                       p_credit_rec,
                       l_recalculate_tax_flag);


      EXCEPTION
        WHEN OTHERS THEN

          arp_util.debug(
            'arp_etax_services_pkg.before_update_line raised exception');
          RAISE;
      END;



   arp_process_credit.set_line_flags(
          p_credit_rec,
          p_customer_trx_id,
          p_customer_trx_line_id,
          p_prev_customer_trx_id,
          p_prev_customer_trx_line_id,
          p_line_amount,
          p_tax_amount,
          p_freight_amount,
          l_cr_line_amount,
          l_cr_tax_amount,
          l_cr_frt_amount,
          l_line_amt_chng_flag,
          l_tax_amt_chng_flag,
          l_frt_amt_chng_flag,
          l_tax_mode,
          l_frt_mode,
          l_frt_ctlid,
          l_cm_complete_flag,
          l_old_line_rec);

   /*--------------------------+
    |  call the table handler  |
    +--------------------------*/

   arp_ctl_pkg.update_p(p_credit_rec, p_customer_trx_line_id);


   /*--------------------+
    | post-update logic  |
    +--------------------*/

   IF (p_prev_customer_trx_id IS NOT NULL)
   THEN
       arp_process_credit.get_uncredit_amounts(
              p_customer_trx_id,
              p_customer_trx_line_id,
              p_prev_customer_trx_id,
              p_prev_customer_trx_line_id,
              null,
              l_uncr_line_amount,
              l_uncr_tax_amount,
              l_uncr_frt_amount,
              l_memo_line_type,
              l_frt_type,
              l_prev_frt_ctlid);
   END IF;

   /* R12 eTax uptake */
   IF (l_recalculate_tax_flag) THEN
           /* we need to call the line_Det_Factors table handler to
              set the attributes for calculating tax */
           ARP_ETAX_SERVICES_PKG.line_det_factors(
                       p_customer_trx_line_id => p_customer_trx_line_id,
                       p_customer_trx_id => p_customer_trx_id,
                       p_mode => 'UPDATE');
   END IF;

   IF (l_frt_amt_chng_flag)
   THEN

       IF (l_cm_complete_flag = 'Y')
       THEN
           l_net_uncr_frt_amount := nvl(l_uncr_frt_amount, 0) -
                                    nvl(l_cr_frt_amount, 0);
       ELSE
           l_net_uncr_frt_amount := l_uncr_frt_amount;
       END IF;

       arp_process_credit.credit_freight(
              p_form_name,
              p_form_version,
              p_customer_trx_id,
              p_customer_trx_line_id,
              p_prev_customer_trx_id,
              p_prev_customer_trx_line_id,
              p_freight_amount,
              l_net_uncr_frt_amount,
              l_frt_type,
              l_frt_ctlid,
              l_frt_mode,
              p_gl_date,
              p_currency_code,
              l_frt_status);

   END IF;

   /*-----------------------+
    | update salescredits   |
    *-----------------------*/

   IF (l_line_amt_chng_flag = TRUE)
   THEN
       arp_ctls_pkg.update_amounts_f_ctl_id(p_customer_trx_line_id,
                                            p_line_amount,
                                            p_currency_code);
   END IF;

   /*-----------------------+
    | update distributions  |
    *-----------------------*/
   IF (p_rerun_aa = 'Y')
   THEN
       rerun_aa(p_customer_trx_id,
                p_customer_trx_line_id,
                p_gl_date,
                null,
                l_rerun_aa_status);
   ELSE
     IF (l_line_amt_chng_flag = TRUE)
     THEN
       BEGIN
         arp_ctlgd_pkg.update_amount_f_ctl_id(p_customer_trx_line_id,
                                              p_line_amount,
                                              p_currency_code,
                                              pg_base_curr_code,
                                              p_exchange_rate,
                                              pg_base_precision,
                                              pg_base_min_acc_unit);
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
              arp_util.debug('arp_process_credit.update_line '||
                             'no distributions updated');
           WHEN OTHERS THEN
             RAISE;
       END;
     END IF;
   END IF;

   arp_util.debug('l_tax_status : '||l_tax_status);
   arp_util.debug('l_frt_status : '||l_frt_status);
   arp_util.debug('l_rerun_aa_status : '||l_rerun_aa_status);

   IF (NVL(l_tax_status, 'OK') <> 'OK') THEN
      p_status := l_tax_status;
   ELSIF (NVL(l_frt_status, 'OK') <> 'OK') THEN
      p_status := l_frt_status;
   ELSIF (NVL(l_rerun_aa_status, 'OK') <> 'OK') THEN
      p_status := l_rerun_aa_status;
   END IF;

   arp_util.debug('arp_process_credit.update_line()-');

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.update_line');
    RAISE;
END;
/*===========================================================================+
 | PROCEDURE                                                                 |
 |    freight_post_update                                                    |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Post update logic for processing freight for CMs                       |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |    arp_util.debug                                                         |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |          IN/ OUT:                                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     12-JUL-95  Subash Chadalavada  Created                                |
 |                                                                           |
 +===========================================================================*/

PROCEDURE freight_post_update(
  p_frt_rec               IN ra_customer_trx_lines%rowtype,
  p_gl_date               IN ra_cust_trx_line_gl_dist.gl_date%type,
  p_frt_ccid              IN
                           ra_cust_trx_line_gl_dist.code_combination_id%type)
IS
  l_ccid
                        ra_cust_trx_line_gl_dist.code_combination_id%type;
  l_concat_segments             varchar2(200);
  l_num_failed_dist_rows        number;
  l_rows_processed              number;
  l_errorbuf                    varchar2(200);
  l_result                      number;
BEGIN
    arp_util.debug('arp_process_credit.freight_post_update()+');

    -- replace this with the call to the CREDIT MEMO procedure
    -- update the distribution record

    BEGIN
        arp_auto_accounting.do_autoaccounting(
                                'U',
                                'FREIGHT',
                                p_frt_rec.customer_trx_id,
                                p_frt_rec.customer_trx_line_id,
                                null,
                                null,
                                p_gl_date,
                                null,
                                p_frt_rec.extended_amount,
                                p_frt_ccid,
                                null,
                                null,
                                null,
                                null,
                                null,
                                l_ccid,
                                l_concat_segments,
                                l_num_failed_dist_rows );
   EXCEPTION
     WHEN arp_auto_accounting.no_ccid THEN
       null;
     WHEN OTHERS THEN
       RAISE;
   END;


    arp_util.debug('arp_process_credit.freight_post_update()-');

EXCEPTION

  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION: arp_process_credit.freight_post_update()');

    arp_util.debug('p_customer_trx_line_id : '||p_frt_rec.customer_trx_line_id);
    arp_util.debug('p_frt_ccid             : '||p_frt_ccid);
    arp_util.debug('p_gl_date              : '||p_gl_date);

END;


PROCEDURE init IS
BEGIN

    pg_number_dummy       := arp_ctl_pkg.get_number_dummy;
    pg_date_dummy         := arp_ct_pkg.get_date_dummy;
    pg_flag_dummy         := arp_ct_pkg.get_flag_dummy;
    pg_name_dummy         := arp_ctl_pkg.get_text_dummy;

    pg_earliest_date      := to_date('01/01/1901', 'DD/MM/YYYY');

    pg_base_curr_code     := arp_trx_global.system_info.base_currency;
    pg_base_precision     := arp_trx_global.system_info.base_precision;
    pg_base_min_acc_unit  := arp_trx_global.system_info.base_min_acc_unit;
    pg_salesrep_required_flag :=
         arp_trx_global.system_info.system_parameters.salesrep_required_flag;

EXCEPTION
  WHEN OTHERS THEN
    arp_util.debug('EXCEPTION:  arp_process_credit.initialization');
    RAISE;
END init;

BEGIN
   init;
END ARP_PROCESS_CREDIT;
/
