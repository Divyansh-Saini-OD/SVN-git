create or replace PACKAGE BODY XXAPPS_HISTORY_COMBO.ARP_MISC_CASH_DIST AS
/* $Header: ARREMCDB.pls 120.18.12010000.2 2012/02/24 14:14:25 anjprasa ship $ */

/* declare subtype */

SUBTYPE l_ae_doc_rec_type IS arp_acct_main.ae_doc_rec_type ;
--
 -- new type defined for 1543658
TYPE ard_tbl_type IS TABLE of ar_distributions%ROWTYPE
  INDEX BY BINARY_INTEGER;
ard_tbl_tbl  ard_tbl_type; --for 1543658

TYPE mcd_tbl_type IS TABLE of ar_misc_cash_distributions%ROWTYPE
  INDEX BY BINARY_INTEGER;
mcd_tbl_tbl  mcd_tbl_type; --for 1543658


/* ---------------------- Public functions -------------------------------- */


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    delete_mcd_rec                             			     |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Deletes a miscellaneous distribution record from 			     |
 |    ar_misc_cash_distributions.					     |
 |									     |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED 	                             |
 |                                                                           |
 | ARGUMENTS                                                                 |
 |    IN:								     |
 |    OUT:                                                                   |
 |                                                                           |
 | RETURNS    		                                                     |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY 						     |
 |									     |
 |    28-SEP-1995        OSTEINME	created				     |
 |    18-JAN-2001	ANUJ	        Modified			     |
 |                                                                           |
 +===========================================================================*/



PG_DEBUG varchar2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');

PROCEDURE delete_mcd_rec(
	p_mcd_id		IN
		ar_misc_cash_distributions.misc_cash_distribution_id%TYPE,
	p_form_name		IN  varchar2,
	p_form_version		IN  varchar2
				) IS
l_ard_line_id              ar_distributions.line_id%TYPE;-- for 1543658
l_ard_rec                  ar_distributions%ROWTYPE;-- for 1543658
l_ard_tax_source_id        ar_distributions.source_id%TYPE;-- for 1543658
BEGIN

  -- arp_standard.enable_debug;
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('arp_process_receipts.delete_mcd_rec()+');
  END IF;

  -- check if calling form is compatible with entity handler

  -- Call table handler for ar_misc_cash_distributions to delete record.
    -- for 1543658 new block is written,
    -- when a MCD record is deleted, the line for AR DISTRIBUTION is also
    -- deleted, but the TAX line in AR DISTRIBUTION is untouched
    -- we insure that line is not a TAX line by  source_type  ='MISCCASH'
    -- bec'z TAX line has same source_id as first  AR DISTRIBUTION line
    -- begin 1543658
   --bug5655154, commented the accounting_method='ACCRUAL' check
   --begin 1813186
--    if arp_global.sysparam.accounting_method = 'ACCRUAL' then
    --end 1813186
    BEGIN
        SELECT line_id into l_ard_line_id
        FROM  ar_distributions
        WHERE source_id = p_mcd_id AND
                source_table = 'MCD' AND
                source_type  ='MISCCASH' ;
        ARP_DISTRIBUTIONS_PKG.delete_p(l_ard_line_id);

        BEGIN
        SELECT * into l_ard_rec
        FROM  ar_distributions
        WHERE source_id = p_mcd_id AND
                source_table = 'MCD' AND
                source_type  ='TAX' AND
                source_id in (select misc_cash_distribution_id
                              from  ar_misc_cash_distributions
                              where cash_receipt_id = ar_distributions.source_id_secondary
                                     and reversal_gl_date is null);

           select nvl(min(source_id),0) into l_ard_tax_source_id
           FROM  ar_distributions
           WHERE source_table = 'MCD' AND
                 source_type  ='MISCCASH'  AND
                  source_id in (select misc_cash_distribution_id
                                from  ar_misc_cash_distributions
                                where cash_receipt_id = l_ard_rec.source_id_secondary
                                      and reversal_gl_date is null);
            l_ard_rec.source_id := l_ard_tax_source_id;
            ARP_DISTRIBUTIONS_PKG.update_p(l_ard_rec);


        EXCEPTION
           WHEN no_data_found then
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_standard.debug('delete_mcd_rec: ' || 'Distribution TAX line does not exists');
           END IF;
        END;
       -- Table handler for  AR DISTRIBUTION record
    EXCEPTION
       WHEN no_data_found then
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_standard.debug('delete_mcd_rec: ' || 'Distribution line does not exists');
           END IF;

    END;
    -- end 1543658
  --begin 1813186
--  end if;                           -- bug5655154
  --end 1813186

  arp_misc_cash_dist_pkg.delete_p(p_mcd_id);
    --Table handler for MCD record


  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('arp_process_receipts.delete_mcd_rec()-');
  END IF;

END delete_mcd_rec;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    insert_mcd_rec                             			     |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Inserts a misc cash distribution record into ar_misc_cash_distributions|
 |									     |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED 	                             |
 |                                                                           |
 | ARGUMENTS                                                                 |
 |    IN:								     |
 |    OUT:                                                                   |
 |                                                                           |
 | RETURNS    		                                                     |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY 						     |
 |									     |
 |    28-SEP-1995	OSTEINME	created				     |
 |    18-JAN-2001	ANUJ	        Modified			     |
 |                                                                           |
 +===========================================================================*/

PROCEDURE insert_mcd_rec(
	p_cash_receipt_id	IN  ar_cash_receipts.cash_receipt_id%TYPE,
	p_gl_date		IN  ar_misc_cash_distributions.gl_date%TYPE,
	p_percent		IN  ar_misc_cash_distributions.percent%TYPE,
	p_amount		IN  ar_misc_cash_distributions.amount%TYPE,
	p_comments		IN  ar_misc_cash_distributions.comments%TYPE,
	p_apply_date		IN  ar_misc_cash_distributions.apply_date%TYPE,
	p_code_combination_id	IN  ar_misc_cash_distributions.code_combination_id%TYPE,
	p_attribute_category    IN  ar_misc_cash_distributions.attribute_category%TYPE,
	p_attribute1		IN  ar_misc_cash_distributions.attribute1%TYPE,
	p_attribute2		IN  ar_misc_cash_distributions.attribute2%TYPE,
	p_attribute3		IN  ar_misc_cash_distributions.attribute3%TYPE,
	p_attribute4		IN  ar_misc_cash_distributions.attribute4%TYPE,
	p_attribute5		IN  ar_misc_cash_distributions.attribute5%TYPE,
	p_attribute6		IN  ar_misc_cash_distributions.attribute6%TYPE,
	p_attribute7		IN  ar_misc_cash_distributions.attribute7%TYPE,
	p_attribute8		IN  ar_misc_cash_distributions.attribute8%TYPE,
	p_attribute9		IN  ar_misc_cash_distributions.attribute9%TYPE,
	p_attribute10		IN  ar_misc_cash_distributions.attribute10%TYPE,
	p_attribute11		IN  ar_misc_cash_distributions.attribute11%TYPE,
	p_attribute12		IN  ar_misc_cash_distributions.attribute12%TYPE,
	p_attribute13		IN  ar_misc_cash_distributions.attribute13%TYPE,
	p_attribute14		IN  ar_misc_cash_distributions.attribute14%TYPE,
	p_attribute15		IN  ar_misc_cash_distributions.attribute15%TYPE,
	p_acctd_amount		IN  ar_misc_cash_distributions.acctd_amount%TYPE,
	p_ussgl_tc	IN ar_misc_cash_distributions.ussgl_transaction_code%TYPE,
        p_mcd_id	OUT NOCOPY ar_misc_cash_distributions.misc_cash_distribution_id%TYPE,
	p_form_name		IN  varchar2,
	p_form_version		IN  varchar2,
        p_amount_ard            IN ar_distributions.amount_dr%TYPE,--for 1543658
        p_acctd_amount_ard      IN ar_distributions.acctd_amount_dr%TYPE  --for 1543658
				)  IS
  l_mcd_rec	             ar_misc_cash_distributions%ROWTYPE;
  l_mcd_id	             ar_misc_cash_distributions.misc_cash_distribution_id%TYPE;
  l_ae_doc_rec               l_ae_doc_rec_type;
  l_ard_line_id              ar_distributions.line_id%TYPE;
  l_ard_rec                  ar_distributions%ROWTYPE;
  l_ard_tax_rec              ar_distributions%ROWTYPE;
  l_ard_tax_rec_flag         char(1);
  l_ard_chk_first_rec        char(1);
  l_cr_rec                   ar_cash_receipts%ROWTYPE;
  l_tax_account_id           ar_vat_tax.tax_account_id%TYPE; -- code_combination_id for tax
  l_vat_tax_id               ar_vat_tax.vat_tax_id%TYPE; -- tax_code_id
  ard_tbl_ctr                number := 0; --counter to store AR Distribution record
                                           -- in plsql Table
  -- for 1543658
  -- this cursor stores all AR Distributions lines  except the one
  -- which is processed presently
  -- and which is not a Tax line for the present receipt
  CURSOR cr_ard_cur
      (p_mcd_id in ar_misc_cash_distributions.misc_cash_distribution_id%TYPE,
       p_cash_receipt_id in ar_cash_receipts.cash_receipt_id%TYPE)
    IS
      SELECT *
      FROM  ar_distributions
      WHERE source_table = 'MCD' AND
            source_type  ='MISCCASH' and
            source_id in (select misc_cash_distribution_id
                          from ar_misc_cash_distributions
                          where cash_receipt_id = p_cash_receipt_id and
                                misc_cash_distribution_id <> p_mcd_id
                                and reversal_gl_date is null );

l_min_unit		NUMBER;
l_precision		NUMBER;
l_ard_cnt		NUMBER;
update_flag             CHAR(1);

l_ar_dist_key_value_list          gl_ca_utility_pkg.r_key_value_arr; /* MRC */
/* Bug fix 2827019  */
l_percent_total         NUMBER;
l_amount_total          NUMBER;


  --Bug#2750340
  l_xla_ev_rec      arp_xla_events.xla_events_type;
  l_xla_doc_table   VARCHAR2(20);

BEGIN

  -- arp_standard.enable_debug;
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('arp_process_receipts.insert_mcd_rec()+');
  END IF;
   --bug5655154, commented accounting_method ='ACCRUAL'
   --begin 1813186
--    if arp_global.sysparam.accounting_method = 'ACCRUAL' then
    --end 1813186


  -- check if calling form is compatible with entity handler

  -- ??????

    --begin 1543658
       -- this select will fetch some important information
     -- which we need to pass in the table handler
     -- of AR Distributions
      select cr.cash_receipt_id                  ,
             cr.amount                           ,
             cr.vat_tax_id                       ,
             cr.tax_rate                         ,
             cr.currency_code                    ,
             cr.exchange_rate                    ,
             cr.exchange_rate_type               ,
             cr.exchange_date                    ,
             cr.pay_from_customer                , --third_party_id
             cr.customer_site_use_id             , --third_party_sub_id
             avt.tax_account_id                  ,
             avt.vat_tax_id                      ,
             fc.precision                        ,
             fc.minimum_accountable_unit
      into  l_cr_rec.cash_receipt_id             ,
            l_cr_rec.amount                      ,
            l_cr_rec.vat_tax_id                  ,
            l_cr_rec.tax_rate                    ,
            l_cr_rec.currency_code               ,
            l_cr_rec.exchange_rate               ,
            l_cr_rec.exchange_rate_type          ,
            l_cr_rec.exchange_date               ,
            l_cr_rec.pay_from_customer           , --third_party_id
            l_cr_rec.customer_site_use_id        , --third_party_sub_id
            l_tax_account_id                     , --code_combination_id for tax
            l_vat_tax_id                         , --tax_code_id
            l_precision                          ,
            l_min_unit
      from ar_cash_receipts           cr,
           ar_vat_tax                 avt,
           fnd_currencies             fc
      where cr.cash_receipt_id      = p_cash_receipt_id
      and   cr.currency_code        = fc.currency_code
      and   cr.vat_tax_id           = avt.vat_tax_id(+);

IF (l_vat_tax_id is not null and l_cr_rec.amount <> 0 ) then /* Bug fix 2874047 : and condition added*/
        if (l_min_unit is null ) then
            l_mcd_rec.amount	:= round(l_cr_rec.amount* p_percent/100,l_precision);

        else
            l_mcd_rec.amount	:= round(l_cr_rec.amount* (p_percent/100)/l_min_unit)*l_min_unit;
        end if;

        if   (arp_global.base_min_acc_unit is null) then
            l_mcd_rec.acctd_amount :=  round((l_cr_rec.amount * p_percent/100) * nvl(l_cr_rec.exchange_rate ,1),
                            arp_global.base_precision);
        else
            l_mcd_rec.acctd_amount := round(l_cr_rec.amount* (p_percent/100) * nvl(l_cr_rec.exchange_rate ,1)
		                    / arp_global.base_min_acc_unit) * arp_global.base_min_acc_unit;
        end if;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_standard.debug(   'l_mcd_rec.amount :='||to_char(l_mcd_rec.amount));
           arp_standard.debug(   'l_mcd_rec.acctd_amount:='||
                            to_char(l_mcd_rec.acctd_amount));
        END IF;
 else
   l_mcd_rec.amount		:= p_amount;
   l_mcd_rec.acctd_amount	:= p_acctd_amount;
 end if;

    --end 1543658


  /* Bug fix 2827019 */
   arp_standard.debug('p_percent = '||to_char(p_percent));
    SELECT sum(amount), sum(percent)
    INTO l_amount_total, l_percent_total
    FROM ar_misc_cash_distributions
    WHERE cash_receipt_id = p_cash_receipt_id
     AND  reversal_gl_date IS NULL;
    arp_standard.debug('l_amount_total = '||to_char(l_amount_total));
    arp_standard.debug('l_percent_total = '||to_char(l_percent_total));

    IF l_amount_total = l_cr_rec.amount - l_mcd_rec.amount
       AND l_cr_rec.amount <> 0 THEN
      arp_standard.debug('Calculate percent = 100-total percent');
      l_mcd_rec.percent :=  100 - l_percent_total;
    ELSE
      arp_standard.debug('Calculate percent from p_percent');
      l_mcd_rec.percent                     := round(p_percent,3);
    END IF;
   arp_standard.debug('After rounding, p_percent = '||to_char(l_mcd_rec.percent));
  /* end bug fix 2827019*/

  -- create mcd record

  l_mcd_rec.cash_receipt_id		:= p_cash_receipt_id;
  l_mcd_rec.gl_date			:= p_gl_date;
--  l_mcd_rec.percent			:= p_percent; /* Bug fix 2827019 */
--  l_mcd_rec.amount			:= p_amount;
  l_mcd_rec.comments			:= p_comments;
  l_mcd_rec.apply_date			:= p_apply_date;
  l_mcd_rec.attribute_category 		:= p_attribute_category;
  l_mcd_rec.attribute1			:= p_attribute1;
  l_mcd_rec.attribute2			:= p_attribute2;
  l_mcd_rec.attribute3			:= p_attribute3;
  l_mcd_rec.attribute4			:= p_attribute4;
  l_mcd_rec.attribute5			:= p_attribute5;
  l_mcd_rec.attribute6			:= p_attribute6;
  l_mcd_rec.attribute7			:= p_attribute7;
  l_mcd_rec.attribute8			:= p_attribute8;
  l_mcd_rec.attribute9			:= p_attribute9;
  l_mcd_rec.attribute10			:= p_attribute10;
  l_mcd_rec.attribute11			:= p_attribute11;
  l_mcd_rec.attribute12			:= p_attribute12;
  l_mcd_rec.attribute13			:= p_attribute13;
  l_mcd_rec.attribute14			:= p_attribute14;
  l_mcd_rec.attribute15			:= p_attribute15;
 -- l_mcd_rec.acctd_amount		:= p_acctd_amount;
  l_mcd_rec.ussgl_transaction_code 	:= p_ussgl_tc;
  l_mcd_rec.posting_control_id		:= -3;   -- not posted;
  l_mcd_rec.set_of_books_id		:= arp_global.set_of_books_id;
  l_mcd_rec.code_combination_id		:= p_code_combination_id;
  l_mcd_rec.created_from		:= 'ARRERCT';


  -- Call table handler for ar_misc_cash_distributions to insert record.

  arp_misc_cash_dist_pkg.insert_p(l_mcd_rec, l_mcd_id);


--begin for 1543654

       l_ard_rec.source_id           := l_mcd_id;
       l_ard_rec.source_table        := 'MCD';
       l_ard_rec.source_type         := 'MISCCASH';
                                        -- It is 'MISCCASH' for line and
                                        --'TAX' for Tax line
       l_ard_rec.source_type_secondary  := '';
       l_ard_rec.code_combination_id  := p_code_combination_id;
       l_ard_rec.source_id_secondary  := l_cr_rec.cash_receipt_id;
       l_ard_rec.source_table_secondary   := 'CR';
       l_ard_rec.currency_code            := l_cr_rec.currency_code;
       l_ard_rec.currency_conversion_rate := l_cr_rec.exchange_rate;
       l_ard_rec.currency_conversion_type := l_cr_rec.exchange_rate_type;
       l_ard_rec.currency_conversion_date := l_cr_rec.exchange_date;
       l_ard_rec.third_party_id           := l_cr_rec.pay_from_customer;
       l_ard_rec.third_party_sub_id       := l_cr_rec.customer_site_use_id;

 IF sign(p_amount_ard) = -1 THEN    -- Debits for Ar distribution

          l_ard_rec.amount_dr   := abs(p_amount_ard);
            if  (arp_global.base_min_acc_unit is null) then
              l_ard_rec.acctd_amount_dr  := round(abs(p_amount_ard) *nvl(l_cr_rec.exchange_rate,1),
                                            arp_global.base_precision);

           else
              l_ard_rec.acctd_amount_dr  := round(abs(p_amount_ard)*nvl(l_cr_rec.exchange_rate,1)
                                            /arp_global.base_min_acc_unit)*arp_global.base_min_acc_unit;
            end if;


          l_ard_rec.amount_cr   := NULL;
          l_ard_rec.acctd_amount_cr := NULL;

       ELSE  -- Credits for Ar distribution

             l_ard_rec.amount_cr   := p_amount_ard;
            if  (arp_global.base_min_acc_unit is null) then
              l_ard_rec.acctd_amount_cr  := round(abs(p_amount_ard) *nvl(l_cr_rec.exchange_rate,1),
                                            arp_global.base_precision);

            else
              l_ard_rec.acctd_amount_cr  := round(abs(p_amount_ard)*nvl(l_cr_rec.exchange_rate,1)
                                            /arp_global.base_min_acc_unit)*arp_global.base_min_acc_unit;
            end if;
             l_ard_rec.amount_dr   := NULL;
             l_ard_rec.acctd_amount_dr := NULL;

       END IF;

-- end for 1543654



  -- Call accounting entry library begins

  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug(    'Insert Misc Cash Receipt Distribution start');
  END IF;

  l_ae_doc_rec.document_type           := 'RECEIPT';
  l_ae_doc_rec.document_id             := l_mcd_rec.cash_receipt_id;
  l_ae_doc_rec.accounting_entity_level := 'ONE';
  l_ae_doc_rec.source_table            := 'MCD';
  l_ae_doc_rec.source_id               := '';


-- begin for 1543658
      -- Instead of calling accounting engine to insert lines in
      -- AR Distribution table, we are simultaneously  inserting line using
      -- table handler, side by side of MCD record.
      -- We presevre all other lines in  AR Distribution table except the one
      -- on which we perform any  modification or insertion
      -- In the case of delete, we delete line from  AR Distribution table
      -- simultaneously when we delete from MCD.
      -- During Insert and update of Distribution, AR Distribution lines for the
      -- the partcular misc receipt are conserverd in plsql table
      -- then record are deleted. Later new lines are entered in  AR Distribution
      -- appending the new changes, using Plsql table record , tax record
      -- and current record.


       BEGIN
          -- to select the tax record of AR distribution in local variable
          -- which will be deleted by arp_acct_main.Delete_Acct_Entry(l_ae_doc_rec);
          -- In the next call storing it back by
          -- "procedure ARP_DISTRIBUTIONS_PKG.insert_p(l_ard_tax_rec,l_ard_line_id);"
            select * into l_ard_tax_rec
            from ar_distributions
            where source_type   ='TAX' and
                  source_table  ='MCD' and
                  source_type_secondary = 'MISCCASH' and
                  source_id in (select misc_cash_distribution_id
                                from ar_misc_cash_distributions
                                where cash_receipt_id = l_cr_rec.cash_receipt_id
                                 and reversal_gl_date is null
                                 UNION
                                 select 0 from dual);


            if  (arp_global.base_min_acc_unit is null) then
               l_ard_tax_rec.acctd_amount_dr  := round(l_ard_tax_rec.amount_dr
                                                      *nvl(l_cr_rec.exchange_rate,1),
                                                      arp_global.base_precision);

               l_ard_tax_rec.acctd_amount_cr:= round(l_ard_tax_rec.amount_cr
                                                     *nvl(l_cr_rec.exchange_rate,1),
                                                     arp_global.base_precision);
           else
              l_ard_tax_rec.acctd_amount_dr  := round(l_ard_tax_rec.amount_dr
                                                       *nvl(l_cr_rec.exchange_rate,1)
                                                       /arp_global.base_min_acc_unit)
                                                       *arp_global.base_min_acc_unit;

              l_ard_tax_rec.acctd_amount_cr := round(l_ard_tax_rec.amount_cr
                                                     *nvl(l_cr_rec.exchange_rate,1)
                                                     /arp_global.base_min_acc_unit)
                                                     *arp_global.base_min_acc_unit;

            end if;
            DELETE FROM  ar_distributions
            WHERE source_table = 'MCD' AND
                  source_type  ='TAX' and
                  source_id = 0
            RETURNING line_id
            BULK COLLECT into l_ar_dist_key_value_list;


          l_ard_tax_rec_flag:='Y';  -- flag to check if we have tax record
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_standard.debug(   'NO INSERT, TAX IS STORED WITH FIRST misc_cash_distribution_id');
          END IF;
          l_ard_tax_rec_flag:='N';

       END;


        -- this loop  stores all AR Distributions lines  except the one
        -- which is processed presently and which is not a Tax line for
        --  the present receipt in a plsql table
        update_flag:='N';
        FOR cr_ard_rec IN cr_ard_cur(l_mcd_id,l_cr_rec.cash_receipt_id) LOOP
          ard_tbl_ctr := ard_tbl_ctr + 1;
            if  (arp_global.base_min_acc_unit is null) then
               cr_ard_rec.acctd_amount_dr := round(cr_ard_rec.amount_dr*
                                                   nvl(l_cr_rec.exchange_rate,1),
                                                   arp_global.base_precision);

               cr_ard_rec.acctd_amount_cr := round(cr_ard_rec.amount_cr
                                                   *nvl(l_cr_rec.exchange_rate,1),
                                                   arp_global.base_precision);
           else
               cr_ard_rec.acctd_amount_dr := round(cr_ard_rec.amount_dr
                                                   *nvl(l_cr_rec.exchange_rate,1)
                                                  /arp_global.base_min_acc_unit)
                                                   *arp_global.base_min_acc_unit;
               cr_ard_rec.acctd_amount_cr := round(cr_ard_rec.amount_cr*
                                                   nvl(l_cr_rec.exchange_rate,1)
                                                  /arp_global.base_min_acc_unit)
                                                   *arp_global.base_min_acc_unit;

            end if;
          ard_tbl_tbl(ard_tbl_ctr) := cr_ard_rec;
        update_flag:='Y';
        END LOOP;

        SELECT count(*) cnt into l_ard_cnt
        FROM  ar_distributions
        WHERE source_table = 'MCD' AND
              source_type   ='MISCCASH' and
              source_id in (select misc_cash_distribution_id
                          from ar_misc_cash_distributions
                          where cash_receipt_id = l_cr_rec.cash_receipt_id
                                and reversal_gl_date is null );

       -- delete all AR Distribution Entery
        if l_ard_cnt > 0 then
        arp_acct_main.Delete_Acct_Entry(l_ae_doc_rec);
        end if;

       -- strore back all records from above plsql table
        IF update_flag='Y' THEN
          FOR l_ctr IN ard_tbl_tbl.FIRST .. ard_tbl_tbl.LAST LOOP
            ARP_DISTRIBUTIONS_PKG.insert_p(ard_tbl_tbl(l_ctr),l_ard_line_id);

            IF PG_DEBUG in ('Y', 'C') THEN
               arp_standard.debug(   'line id for line:=  '||to_char(l_ard_line_id));
            END IF;
          END LOOP;
        END IF;
       -- delete record from plsql table
        ard_tbl_tbl.delete;

          /* Bug 2233284
             tax_link_id must be assigned before inserting the new record */

          if l_ard_tax_rec_flag ='Y' then
            l_ard_rec.tax_link_id := 1;
          end if;

           -- to insert new line record
           ARP_DISTRIBUTIONS_PKG.insert_p(l_ard_rec,l_ard_line_id);

           IF PG_DEBUG in ('Y', 'C') THEN
              arp_standard.debug(   'line id for line:=  '||to_char(l_ard_line_id));
           END IF;

           -- to update the tax record
          IF l_ard_tax_rec_flag = 'Y' THEN
             if  l_ard_tax_rec.source_id = 0 then
                 l_ard_tax_rec.source_id :=l_mcd_id;
              end if;
              ARP_DISTRIBUTIONS_PKG.insert_p(l_ard_tax_rec,l_ard_line_id);

          END IF;

 --end for 1543658

   -- Call to accounting engine is  commented for 1543658
  --arp_acct_main.Create_Acct_Entry(l_ae_doc_rec);

  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug(    'Insert Misc Cash Receipt Distribution start');
  END IF;

  -- populate return variable:

  p_mcd_id := l_mcd_id;

/********** bug5655154
 --begin 1813186
   else

  -- create mcd record for cash besis

  l_mcd_rec.cash_receipt_id		:= p_cash_receipt_id;
  l_mcd_rec.gl_date			:= p_gl_date;
  l_mcd_rec.percent			:= p_percent;
  l_mcd_rec.amount			:= p_amount;
  l_mcd_rec.comments			:= p_comments;
  l_mcd_rec.apply_date			:= p_apply_date;
  l_mcd_rec.attribute_category 		:= p_attribute_category;
  l_mcd_rec.attribute1			:= p_attribute1;
  l_mcd_rec.attribute2			:= p_attribute2;
  l_mcd_rec.attribute3			:= p_attribute3;
  l_mcd_rec.attribute4			:= p_attribute4;
  l_mcd_rec.attribute5			:= p_attribute5;
  l_mcd_rec.attribute6			:= p_attribute6;
  l_mcd_rec.attribute7			:= p_attribute7;
  l_mcd_rec.attribute8			:= p_attribute8;
  l_mcd_rec.attribute9			:= p_attribute9;
  l_mcd_rec.attribute10			:= p_attribute10;
  l_mcd_rec.attribute11			:= p_attribute11;
  l_mcd_rec.attribute12			:= p_attribute12;
  l_mcd_rec.attribute13			:= p_attribute13;
  l_mcd_rec.attribute14			:= p_attribute14;
  l_mcd_rec.attribute15			:= p_attribute15;
  l_mcd_rec.acctd_amount		:= p_acctd_amount;
  l_mcd_rec.ussgl_transaction_code 	:= p_ussgl_tc;
  l_mcd_rec.posting_control_id		:= -3;   -- not posted;
  l_mcd_rec.set_of_books_id		:= arp_global.set_of_books_id;
  l_mcd_rec.code_combination_id		:= p_code_combination_id;
  l_mcd_rec.created_from		:= 'ARRERCT';


  -- Call table handler for ar_misc_cash_distributions to insert record.

  arp_misc_cash_dist_pkg.insert_p(l_mcd_rec, l_mcd_id);

  -- populate return variable:

  p_mcd_id := l_mcd_id;


   end if;
 --end 1813186
************ bug5655154 ****/

   l_xla_ev_rec.xla_from_doc_id := p_cash_receipt_id;
   l_xla_ev_rec.xla_to_doc_id   := p_cash_receipt_id;
   l_xla_ev_rec.xla_mode        := 'O';
   l_xla_ev_rec.xla_call        := 'B';

   l_xla_ev_rec.xla_doc_table := 'MCD';
   l_xla_ev_rec.xla_call  := 'D';
   ARP_XLA_EVENTS.create_events(p_xla_ev_rec => l_xla_ev_rec);


  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('arp_process_receipts.insert_mcd_rec()-');
  END IF;

END insert_mcd_rec;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    update_mcd_rec                             			     |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    updates a record in ar_misc_cash_distributions                         |
 |									     |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED 	                             |
 |                                                                           |
 | ARGUMENTS                                                                 |
 |    IN:								     |
 |    OUT:                                                                   |
 |                                                                           |
 | RETURNS    		                                                     |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY 						     |
 |									     |
 |    02-OCT-1995	OSTEINME  created				     |
 |    29-SEP-1998 	GJWANG    Bug fix: 737949 Remove code setting posting|
 | 				  control id to -3 when update               |
 |    18-JAN-2001	ANUJ	  Modified  for 1543658			     |
 +===========================================================================*/

PROCEDURE update_mcd_rec(
	p_misc_cash_distribution_id
				IN  ar_misc_cash_distributions.misc_cash_distribution_id%TYPE,
	p_cash_receipt_id	IN  ar_cash_receipts.cash_receipt_id%TYPE,
	p_gl_date		IN  ar_misc_cash_distributions.gl_date%TYPE,
	p_percent		IN  ar_misc_cash_distributions.percent%TYPE,
	p_amount		IN  ar_misc_cash_distributions.amount%TYPE,
	p_comments		IN  ar_misc_cash_distributions.comments%TYPE,
	p_apply_date		IN  ar_misc_cash_distributions.apply_date%TYPE,
	p_code_combination_id	IN  ar_misc_cash_distributions.code_combination_id%TYPE,
	p_attribute_category    IN  ar_misc_cash_distributions.attribute_category%TYPE,
	p_attribute1		IN  ar_misc_cash_distributions.attribute1%TYPE,
	p_attribute2		IN  ar_misc_cash_distributions.attribute2%TYPE,
	p_attribute3		IN  ar_misc_cash_distributions.attribute3%TYPE,
	p_attribute4		IN  ar_misc_cash_distributions.attribute4%TYPE,
	p_attribute5		IN  ar_misc_cash_distributions.attribute5%TYPE,
	p_attribute6		IN  ar_misc_cash_distributions.attribute6%TYPE,
	p_attribute7		IN  ar_misc_cash_distributions.attribute7%TYPE,
	p_attribute8		IN  ar_misc_cash_distributions.attribute8%TYPE,
	p_attribute9		IN  ar_misc_cash_distributions.attribute9%TYPE,
	p_attribute10		IN  ar_misc_cash_distributions.attribute10%TYPE,
	p_attribute11		IN  ar_misc_cash_distributions.attribute11%TYPE,
	p_attribute12		IN  ar_misc_cash_distributions.attribute12%TYPE,
	p_attribute13		IN  ar_misc_cash_distributions.attribute13%TYPE,
	p_attribute14		IN  ar_misc_cash_distributions.attribute14%TYPE,
	p_attribute15		IN  ar_misc_cash_distributions.attribute15%TYPE,
	p_acctd_amount		IN  ar_misc_cash_distributions.acctd_amount%TYPE,
	p_ussgl_tc		IN ar_misc_cash_distributions.ussgl_transaction_code%TYPE,
	p_form_name		IN  varchar2,
	p_form_version		IN  varchar2,
        p_amount_ard            IN ar_distributions.amount_dr%TYPE,--for 1543658
        p_acctd_amount_ard      IN ar_distributions.acctd_amount_dr%TYPE  --for 1543658
				)  IS

  l_mcd_rec	ar_misc_cash_distributions%ROWTYPE;
  l_ard_line_id              ar_distributions.line_id%TYPE;
  l_ard_rec                  ar_distributions%ROWTYPE;
  l_ard_tax_rec              ar_distributions%ROWTYPE;
  l_ard_tax_rec_flag         char(1);
  l_ard_chk_first_rec        char(1);
  l_cr_rec                   ar_cash_receipts%ROWTYPE;
  l_tax_account_id           ar_vat_tax.tax_account_id%TYPE; -- code_combination_id for tax
  l_vat_tax_id               ar_vat_tax.vat_tax_id%TYPE; -- tax_code_id
  ard_tbl_ctr                number := 0; --counter to store AR Distribution record
                                           -- in plsql Table
  -- for 1543658
  -- this cursor stores all AR Distributions lines  except the one
  -- which is processed presently
  -- and which is not a Tax line for the present receipt

CURSOR cr_ard_cur
      (p_mcd_id in ar_misc_cash_distributions.misc_cash_distribution_id%TYPE,
       p_cash_receipt_id in ar_cash_receipts.cash_receipt_id%TYPE)
    IS
      SELECT *
      FROM  ar_distributions
      WHERE source_table = 'MCD' AND
            source_type  ='MISCCASH' and
            source_id in (select misc_cash_distribution_id
                          from ar_misc_cash_distributions
                          where cash_receipt_id = p_cash_receipt_id and
                                misc_cash_distribution_id <> p_mcd_id
                                and reversal_gl_date is null);

  --VAT variable
  l_ae_doc_rec            l_ae_doc_rec_type;
  l_min_unit		NUMBER;
  l_precision		NUMBER;
  update_flag           CHAR(1);
  /* Bug fix 2827019 */
  l_amount_total        NUMBER;
  l_percent_total       NUMBER;
  l_amount_current      NUMBER;
  l_percent_current     NUMBER;

  --Bug#2750340
  l_xla_ev_rec      arp_xla_events.xla_events_type;
  l_xla_doc_table   VARCHAR2(20);
  l_ard_cnt         NUMBER := 0 ;            -- bug5655154
BEGIN

  -- arp_standard.enable_debug;
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('arp_process_receipts.update_mcd_rec()+');
  END IF;
    --bug5655154, commented accounting_method = 'ACCRUAL'
     --begin 1813186
     -- if arp_global.sysparam.accounting_method = 'ACCRUAL' then
    --end 1813186


  -- check if calling form is compatible with entity handler

  -- ??????


  -- fetch existing record from database:
  arp_misc_cash_dist_pkg.fetch_p(p_misc_cash_distribution_id, l_mcd_rec);
--begin 1543658
       -- this select will fetch some important information
     -- which we need to pass in the table handler
     -- of AR Distributions
      select cr.cash_receipt_id                  ,
             cr.amount                           ,
             cr.vat_tax_id                       ,
             cr.tax_rate                         ,
             cr.currency_code                    ,
             cr.exchange_rate                    ,
             cr.exchange_rate_type               ,
             cr.exchange_date                    ,
             cr.pay_from_customer                , --third_party_id
             cr.customer_site_use_id             , --third_party_sub_id
             avt.tax_account_id                  ,
             avt.vat_tax_id                      ,
             fc.precision                        ,
             fc.minimum_accountable_unit
      into  l_cr_rec.cash_receipt_id             ,
            l_cr_rec.amount                      ,
            l_cr_rec.vat_tax_id                  ,
            l_cr_rec.tax_rate                    ,
            l_cr_rec.currency_code               ,
            l_cr_rec.exchange_rate               ,
            l_cr_rec.exchange_rate_type          ,
            l_cr_rec.exchange_date               ,
            l_cr_rec.pay_from_customer           , --third_party_id
            l_cr_rec.customer_site_use_id        , --third_party_sub_id
            l_tax_account_id                     , --code_combination_id for tax
            l_vat_tax_id                         , --tax_code_id
            l_precision                          ,
            l_min_unit
      from ar_cash_receipts           cr,
           ar_vat_tax                 avt,
           fnd_currencies             fc
      where cr.cash_receipt_id      = p_cash_receipt_id
      and   cr.currency_code        = fc.currency_code
      and   cr.vat_tax_id           = avt.vat_tax_id(+);

IF (l_vat_tax_id is not null  and l_cr_rec.amount <> 0) then  /* Bug fix 2874047 : Added the and condition */
        if (l_min_unit is null ) then
            l_mcd_rec.amount	:= round(l_cr_rec.amount* p_percent/100,l_precision);

        else
            l_mcd_rec.amount	:= round(l_cr_rec.amount* (p_percent/100)/l_min_unit)*l_min_unit;
        end if;

        if   (arp_global.base_min_acc_unit is null) then
            l_mcd_rec.acctd_amount :=  round((l_cr_rec.amount * p_percent/100) * nvl(l_cr_rec.exchange_rate ,1),
                            arp_global.base_precision);
        else
            l_mcd_rec.acctd_amount := round(l_cr_rec.amount* (p_percent/100) * nvl(l_cr_rec.exchange_rate ,1)
		                    / arp_global.base_min_acc_unit) * arp_global.base_min_acc_unit;
        end if;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_standard.debug('l_mcd_rec.amount	    :='||to_char(l_mcd_rec.amount));
           arp_standard.debug('l_mcd_rec.acctd_amount	:='||to_char(l_mcd_rec.acctd_amount));
        END IF;
 else
   l_mcd_rec.amount		:= p_amount;
   l_mcd_rec.acctd_amount	:= p_acctd_amount;
 end if;

  --end 1543658

  /* Bug fix 2827019 */
    SELECT sum(amount), sum(percent)
    INTO l_amount_total, l_percent_total
    FROM ar_misc_cash_distributions
    WHERE cash_receipt_id = p_cash_receipt_id
    AND   reversal_gl_date IS NULL;

    SELECT amount,percent
    INTO l_amount_current, l_percent_current
    FROM ar_misc_cash_distributions
    WHERE misc_cash_distribution_id = p_misc_cash_distribution_id;

    arp_standard.debug('l_amount_total = '||to_char(l_amount_total));
    arp_standard.debug('l_percent_total = '||to_char(l_percent_total));
    arp_standard.debug('l_amount_current = '||to_char(l_amount_current));
    arp_standard.debug('l_percent_current = '||to_char(l_percent_current));

    IF l_amount_total - l_amount_current = l_cr_rec.amount - l_mcd_rec.amount
         AND l_cr_rec.amount <> 0 THEN
      arp_standard.debug('Calculate percent = 100-total percent');
      l_mcd_rec.percent :=  100 - l_percent_total + l_percent_current;
    ELSE
      arp_standard.debug('Calculate percent from p_percent');
      l_mcd_rec.percent                     := round(p_percent,3);
    END IF;
   arp_standard.debug('After rounding, p_percent = '||to_char(l_mcd_rec.percent));
  /* end bug fix 2827019*/


  -- check if record has already been posted.  If yes, raise exception
  -- (updates are not allowed in that case).

  IF (l_mcd_rec.posting_control_id <> -3 OR
      (l_mcd_rec.gl_posted_date IS NOT NULL)) THEN

    -- raise exception!
    NULL;
  END IF;

  -- update mcd record

  l_mcd_rec.cash_receipt_id		:= p_cash_receipt_id;
  l_mcd_rec.gl_date			:= p_gl_date;
--  l_mcd_rec.percent			:= p_percent; /* Bug fix 2827019*/
 -- l_mcd_rec.amount			:= p_amount;
  l_mcd_rec.comments			:= p_comments;
  l_mcd_rec.apply_date			:= p_apply_date;
  l_mcd_rec.attribute_category 		:= p_attribute_category;
  l_mcd_rec.attribute1			:= p_attribute1;
  l_mcd_rec.attribute2			:= p_attribute2;
  l_mcd_rec.attribute3			:= p_attribute3;
  l_mcd_rec.attribute4			:= p_attribute4;
  l_mcd_rec.attribute5			:= p_attribute5;
  l_mcd_rec.attribute6			:= p_attribute6;
  l_mcd_rec.attribute7			:= p_attribute7;
  l_mcd_rec.attribute8			:= p_attribute8;
  l_mcd_rec.attribute9			:= p_attribute9;
  l_mcd_rec.attribute10			:= p_attribute10;
  l_mcd_rec.attribute11			:= p_attribute11;
  l_mcd_rec.attribute12			:= p_attribute12;
  l_mcd_rec.attribute13			:= p_attribute13;
  l_mcd_rec.attribute14			:= p_attribute14;
  l_mcd_rec.attribute15			:= p_attribute15;
--  l_mcd_rec.acctd_amount		:= p_acctd_amount;
  l_mcd_rec.ussgl_transaction_code 	:= p_ussgl_tc;
--  l_mcd_rec.posting_control_id		:= -3;   -- not posted;
  l_mcd_rec.set_of_books_id		:= arp_global.set_of_books_id;
  l_mcd_rec.code_combination_id		:= p_code_combination_id;
  l_mcd_rec.created_from		:= 'ARRERCT';

  IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('MCD amount ' || TO_CHAR(l_mcd_rec.amount));
  END IF;

  -- Call table handler for ar_misc_cash_distributions to update record.

  arp_misc_cash_dist_pkg.update_p(l_mcd_rec);

   /*-------------------------------------------------------------------------+
    | Bug 2399871 : Call the Accounting Engine for the unposted records only .|
    +-------------------------------------------------------------------------*/
  IF ( l_mcd_rec.posting_control_id = -3 ) THEN
--begin for 1543654
       l_ard_rec.source_id           := p_misc_cash_distribution_id;
       l_ard_rec.source_table        := 'MCD';
       l_ard_rec.source_type         := 'MISCCASH';
       l_ard_rec.source_type_secondary  := '';
       l_ard_rec.code_combination_id  := p_code_combination_id;
       l_ard_rec.source_id_secondary  := l_cr_rec.cash_receipt_id;
       l_ard_rec.source_table_secondary   := 'CR';
       l_ard_rec.currency_code            := l_cr_rec.currency_code;
       l_ard_rec.currency_conversion_rate := l_cr_rec.exchange_rate;
       l_ard_rec.currency_conversion_type := l_cr_rec.exchange_rate_type;
       l_ard_rec.currency_conversion_date := l_cr_rec.exchange_date;
       l_ard_rec.third_party_id           := l_cr_rec.pay_from_customer;
       l_ard_rec.third_party_sub_id       := l_cr_rec.customer_site_use_id;


    IF sign(p_amount_ard) = -1 THEN    -- Debits for Ar distribution

          l_ard_rec.amount_dr   := abs(p_amount_ard);
            if  (arp_global.base_min_acc_unit is null) then
              l_ard_rec.acctd_amount_dr  := round(abs(p_amount_ard)
                                                   *nvl(l_cr_rec.exchange_rate,1),
                                                   arp_global.base_precision);

           else
              l_ard_rec.acctd_amount_dr  := round(abs(p_amount_ard)
                                                  *nvl(l_cr_rec.exchange_rate,1)
                                                  /arp_global.base_min_acc_unit)
                                                  *arp_global.base_min_acc_unit;
            end if;


          l_ard_rec.amount_cr   := NULL;
          l_ard_rec.acctd_amount_cr := NULL;

       ELSE  -- Credits for Ar distribution

             l_ard_rec.amount_cr   := p_amount_ard;
            if  (arp_global.base_min_acc_unit is null) then
              l_ard_rec.acctd_amount_cr  := round(abs(p_amount_ard)
                                                  *nvl(l_cr_rec.exchange_rate,1),
                                                  arp_global.base_precision);

            else
              l_ard_rec.acctd_amount_cr  := round(abs(p_amount_ard)
                                                  *nvl(l_cr_rec.exchange_rate,1)
                                                  /arp_global.base_min_acc_unit)
                                                  *arp_global.base_min_acc_unit;
            end if;
             l_ard_rec.amount_dr   := NULL;
             l_ard_rec.acctd_amount_dr := NULL;

       END IF;
-- end for 1543654


  -- Call accounting entry library begins for updating Distribution

  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('Update Misc Cash Receipt Distribution start');
  END IF;

  l_ae_doc_rec.document_type           := 'RECEIPT';
  l_ae_doc_rec.document_id             := l_mcd_rec.cash_receipt_id;
  l_ae_doc_rec.accounting_entity_level := 'ONE';
  l_ae_doc_rec.source_table            := 'MCD';
  l_ae_doc_rec.source_id               := '';

-- begin for 1543658
      -- Instead of calling accounting engine to update lines in
      -- AR Distribution table, we are simultaneously  inserting line using
      -- table handler, side by side of MCD record.
      -- We presevre all other lines in  AR Distribution table except the one
      -- on which we perform any  modification or insertion
      -- In the case of delete, we delete line from  AR Distribution table
      -- simultaneously when we delete from MCD.
      -- During Insert and update of Distribution, AR Distribution lines for the
      -- the partcular misc receipt are conserverd in plsql table
      -- then record are deleted. Later new lines are entered in  AR Distribution
      -- appending the new changes, using Plsql table record , tax record
      -- and current record.

       BEGIN
          -- to select the tax record of AR distribution in local variable
          -- which will be deleted by arp_acct_main.Delete_Acct_Entry(l_ae_doc_rec);
          -- In the next call storing it back by
          -- "procedure ARP_DISTRIBUTIONS_PKG.insert_p(l_ard_tax_rec,l_ard_line_id);"
            select * into l_ard_tax_rec
            from ar_distributions
            where source_type   ='TAX' and
                 source_table  ='MCD' and
                 source_type_secondary = 'MISCCASH' and
                 source_id in (select misc_cash_distribution_id
                               from ar_misc_cash_distributions
                               where cash_receipt_id = l_mcd_rec.cash_receipt_id
                                and reversal_gl_date is null
                                UNION
                                select 0 from dual);

            if  (arp_global.base_min_acc_unit is null) then
               l_ard_tax_rec.acctd_amount_dr  := round(l_ard_tax_rec.amount_dr
                                                       *nvl(l_cr_rec.exchange_rate,1),
                                                        arp_global.base_precision);

               l_ard_tax_rec.acctd_amount_cr:= round(l_ard_tax_rec.amount_cr
                                                     *nvl(l_cr_rec.exchange_rate,1),
                                                     arp_global.base_precision);
           else
              l_ard_tax_rec.acctd_amount_dr  := round(l_ard_tax_rec.amount_dr
                                                      *nvl(l_cr_rec.exchange_rate,1)
                                                      /arp_global.base_min_acc_unit)
                                                      *arp_global.base_min_acc_unit;

              l_ard_tax_rec.acctd_amount_cr := round(l_ard_tax_rec.amount_cr
                                                     *nvl(l_cr_rec.exchange_rate,1)
                                                     /arp_global.base_min_acc_unit)
                                                     *arp_global.base_min_acc_unit;

            end if;
          l_ard_tax_rec_flag:='Y';  -- flag to check if we have tax record
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_standard.debug('NO INSERT, TAX IS STORED WITH FIRST misc_cash_distribution_id');
          END IF;
          l_ard_tax_rec_flag:='N';
       END;

        -- this loop  stores all AR Distributions lines  except the one
        -- which is processed presently and which is not a Tax line for
        --  the present receipt in a plsql table

        update_flag:='N';
        FOR cr_ard_rec IN cr_ard_cur(p_misc_cash_distribution_id,l_cr_rec.cash_receipt_id) LOOP
          ard_tbl_ctr := ard_tbl_ctr + 1;

            if  (arp_global.base_min_acc_unit is null) then
               cr_ard_rec.acctd_amount_dr := round(cr_ard_rec.amount_dr *nvl(l_cr_rec.exchange_rate,1),
                                                  arp_global.base_precision);

               cr_ard_rec.acctd_amount_cr := round(cr_ard_rec.amount_cr*nvl(l_cr_rec.exchange_rate,1),
                                                  arp_global.base_precision);
           else
               cr_ard_rec.acctd_amount_dr := round(cr_ard_rec.amount_dr*nvl(l_cr_rec.exchange_rate,1)
                                                 /arp_global.base_min_acc_unit)*arp_global.base_min_acc_unit;

               cr_ard_rec.acctd_amount_cr := round(cr_ard_rec.amount_cr*nvl(l_cr_rec.exchange_rate,1)
                                                /arp_global.base_min_acc_unit)*arp_global.base_min_acc_unit;

            end if;
          ard_tbl_tbl(ard_tbl_ctr) := cr_ard_rec;
          update_flag:='Y';

        END LOOP;

-- begin bug5655154, added to check if distributions exists or not
        SELECT count(*) cnt into l_ard_cnt
        FROM  ar_distributions
        WHERE source_table = 'MCD' AND
              source_type   ='MISCCASH' and
              source_id in ( select misc_cash_distribution_id
                             from   ar_misc_cash_distributions
                             where  cash_receipt_id = l_cr_rec.cash_receipt_id
                             and    reversal_gl_date is null );

      IF l_ard_cnt >0  THEN
      -- delete all AR Distribution Entery
        arp_acct_main.Delete_Acct_Entry(l_ae_doc_rec);
      END IF ;
-- end bug5655154
       -- strore back all records from above plsql table
      IF update_flag='Y'  THEN
          FOR l_ctr IN ard_tbl_tbl.FIRST .. ard_tbl_tbl.LAST LOOP
            ARP_DISTRIBUTIONS_PKG.insert_p(ard_tbl_tbl(l_ctr),l_ard_line_id);

          END LOOP;
      END IF;
       -- cleaning up of plsql table
       ard_tbl_tbl.delete;

          /* Bug 2233284
             tax_link_id must be assigned before inserting the new record */

           if l_ard_tax_rec_flag = 'Y' then
             l_ard_rec.tax_link_id := 1;
           end if;

           -- to insert new line record
           ARP_DISTRIBUTIONS_PKG.insert_p(l_ard_rec,l_ard_line_id);

           IF PG_DEBUG in ('Y', 'C') THEN
              arp_standard.debug('line id for line:=  '||to_char(l_ard_line_id));
           END IF;

           -- to update the tax record
          if l_ard_tax_rec_flag = 'Y' then
               if  l_ard_tax_rec.source_id = 0 then
                 l_ard_tax_rec.source_id :=p_misc_cash_distribution_id;
              end if;
              ARP_DISTRIBUTIONS_PKG.insert_p(l_ard_tax_rec,l_ard_line_id);

          end if;

 --end for 1543658

   -- Call to accounting engine is  commented for 1543658
   -- arp_acct_main.Create_Acct_Entry(l_ae_doc_rec);
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('Update Misc Cash Receipt Distribution end');
  END IF;

  END IF;   /*  IF ( l_mcd_rec.posting_control_id = -3 )  */

/****** bug5655154
--begin 1813186
 else  --for CASH basis

  -- check if calling form is compatible with entity handler

  -- ??????

 -- fetch existing record from database:

  arp_misc_cash_dist_pkg.fetch_p(p_misc_cash_distribution_id, l_mcd_rec);

  -- check if record has already been posted.  If yes, raise exception
  -- (updates are not allowed in that case).

  IF (l_mcd_rec.posting_control_id <> -3 OR
      (l_mcd_rec.gl_posted_date IS NOT NULL)) THEN

    -- raise exception!
    NULL;
  END IF;

  -- update mcd record

  l_mcd_rec.cash_receipt_id		:= p_cash_receipt_id;
  l_mcd_rec.gl_date			:= p_gl_date;
  l_mcd_rec.percent			:= p_percent;
  l_mcd_rec.amount			:= p_amount;
  l_mcd_rec.comments			:= p_comments;
  l_mcd_rec.apply_date			:= p_apply_date;
  l_mcd_rec.attribute_category 		:= p_attribute_category;
  l_mcd_rec.attribute1			:= p_attribute1;
  l_mcd_rec.attribute2			:= p_attribute2;
  l_mcd_rec.attribute3			:= p_attribute3;
  l_mcd_rec.attribute4			:= p_attribute4;
  l_mcd_rec.attribute5			:= p_attribute5;
  l_mcd_rec.attribute6			:= p_attribute6;
  l_mcd_rec.attribute7			:= p_attribute7;
  l_mcd_rec.attribute8			:= p_attribute8;
  l_mcd_rec.attribute9			:= p_attribute9;
  l_mcd_rec.attribute10			:= p_attribute10;
  l_mcd_rec.attribute11			:= p_attribute11;
  l_mcd_rec.attribute12			:= p_attribute12;
  l_mcd_rec.attribute13			:= p_attribute13;
  l_mcd_rec.attribute14			:= p_attribute14;
  l_mcd_rec.attribute15			:= p_attribute15;
  l_mcd_rec.acctd_amount		:= p_acctd_amount;
  l_mcd_rec.ussgl_transaction_code 	:= p_ussgl_tc;
--  l_mcd_rec.posting_control_id		:= -3;   -- not posted;
  l_mcd_rec.set_of_books_id		:= arp_global.set_of_books_id;
  l_mcd_rec.code_combination_id		:= p_code_combination_id;
  l_mcd_rec.created_from		:= 'ARRERCT';

  -- Call table handler for ar_misc_cash_distributions to update record.

  arp_misc_cash_dist_pkg.update_p(l_mcd_rec);




 end if;
******** bug5655154 ***/
   l_xla_ev_rec.xla_from_doc_id := p_cash_receipt_id;
   l_xla_ev_rec.xla_to_doc_id   := p_cash_receipt_id;
   l_xla_ev_rec.xla_mode        := 'O';
   l_xla_ev_rec.xla_call        := 'B';

   l_xla_ev_rec.xla_doc_table := 'MCD';
   l_xla_ev_rec.xla_call  := 'D';
   ARP_XLA_EVENTS.create_events(p_xla_ev_rec => l_xla_ev_rec);



 --end 1813186
 /* Bug fix 3032059
    Update the receipt version number */
  arp_cash_receipts_pkg.update_version_number(p_cash_receipt_id);

  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('arp_process_receipts.update_mcd_rec()-');
  END IF;

END update_mcd_rec;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |    lock_mcd_rec                             			             |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    locks a record in ar_misc_cash_distributions and the corresponding     |
 |    cash receipt record.						     |
 |									     |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED 	                             |
 |                                                                           |
 | ARGUMENTS                                                                 |
 |    IN:								     |
 |    OUT:                                                                   |
 |                                                                           |
 | RETURNS    		                                                     |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY 						     |
 |									     |
 |    05-OCT-95	OSTEINME	created					     |
 |    09-SEP-99 GJWANG		941243: when distribution amount change, lock|
 |                              amount from ar_distributions table isntead of|
 |				ar_misc_cash_distributions table             |
 |    30-DEC-02 MRAMANAT	Bugfix 2626083. Added code to compare 	     |
 |				gl_posted_date.				     |
 |                                                                           |
 +===========================================================================*/

PROCEDURE lock_mcd_rec(
	p_misc_cash_distribution_id
				IN  ar_misc_cash_distributions.misc_cash_distribution_id%TYPE,
	p_cash_receipt_id	IN  ar_cash_receipts.cash_receipt_id%TYPE,
	p_percent		IN  ar_misc_cash_distributions.percent%TYPE,
	p_amount		IN  ar_misc_cash_distributions.amount%TYPE,
	p_comments		IN  ar_misc_cash_distributions.comments%TYPE,
	p_code_combination_id	IN  ar_misc_cash_distributions.code_combination_id%TYPE,
	p_attribute_category    IN  ar_misc_cash_distributions.attribute_category%TYPE,
	p_attribute1		IN  ar_misc_cash_distributions.attribute1%TYPE,
	p_attribute2		IN  ar_misc_cash_distributions.attribute2%TYPE,
	p_attribute3		IN  ar_misc_cash_distributions.attribute3%TYPE,
	p_attribute4		IN  ar_misc_cash_distributions.attribute4%TYPE,
	p_attribute5		IN  ar_misc_cash_distributions.attribute5%TYPE,
	p_attribute6		IN  ar_misc_cash_distributions.attribute6%TYPE,
	p_attribute7		IN  ar_misc_cash_distributions.attribute7%TYPE,
	p_attribute8		IN  ar_misc_cash_distributions.attribute8%TYPE,
	p_attribute9		IN  ar_misc_cash_distributions.attribute9%TYPE,
	p_attribute10		IN  ar_misc_cash_distributions.attribute10%TYPE,
	p_attribute11		IN  ar_misc_cash_distributions.attribute11%TYPE,
	p_attribute12		IN  ar_misc_cash_distributions.attribute12%TYPE,
	p_attribute13		IN  ar_misc_cash_distributions.attribute13%TYPE,
	p_attribute14		IN  ar_misc_cash_distributions.attribute14%TYPE,
	p_attribute15		IN  ar_misc_cash_distributions.attribute15%TYPE,
	p_ussgl_tc		IN ar_misc_cash_distributions.ussgl_transaction_code%TYPE,
	p_form_name		IN  varchar2,
	p_form_version		IN  varchar2,
	p_gl_posted_date	IN  ar_misc_cash_distributions.gl_posted_date%TYPE,
        p_rec_version_number    IN  ar_cash_receipts.rec_version_number%TYPE /* Bug fix 3032059 */
				)  IS

  l_mcd_rec	ar_misc_cash_distributions%ROWTYPE;
  l_dist_rec_amt	NUMBER;
  l_dist_rec	ar_distributions%ROWTYPE;
  l_ard_cnt     NUMBER := 0 ;
BEGIN

  -- arp_standard.enable_debug;
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('arp_process_receipts.lock_mcd_rec()+');
  END IF;


  -- check if calling form is compatible with entity handler

  -- ??????


  arp_misc_cash_dist_pkg.nowaitlock_fetch_p(p_misc_cash_distribution_id, l_mcd_rec);
 --bug5655154, commented accounting_method = 'ACCRUAL' check
 --begin 1813186
-- if arp_global.sysparam.accounting_method = 'ACCRUAL' then
 --end 1813186

  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('Begin lock Dist amount ');
     arp_util.debug('lock_mcd_rec: ' || ' MCD_ID ' || TO_CHAR(p_misc_cash_distribution_id));
  END IF;

-- begin, bug5655154, to check if distributions already exist or not
   SELECT count(*) cnt into l_ard_cnt
   FROM   ar_distributions
   WHERE  source_table = 'MCD' AND
          source_type  = 'MISCCASH' and
          source_id    = p_misc_cash_distribution_id ;

   IF l_ard_cnt > 0 THEN                                    -- bug5655154
     SELECT   decode(sign(p_amount), 1, amount_cr,
                                     0, amount_cr,
      				    -1, amount_dr )
      INTO   l_dist_rec_amt
      FROM   ar_distributions
      WHERE  source_id = p_misc_cash_distribution_id
        AND  source_table = 'MCD'
        AND  source_type = 'MISCCASH'
      FOR UPDATE OF source_id NOWAIT;
   ELSE                                                     -- bug5655154
      l_dist_rec_amt := ABS(p_amount) ;
   END IF  ;                                                -- bug5655154
-- end bug5655154

  IF  (((l_mcd_rec.percent = p_percent) OR
       (l_mcd_rec.percent IS NULL AND p_percent IS NULL))
    AND
--      ((l_mcd_rec.amount = p_amount) OR
--      (l_mcd_rec.amount IS NULL AND p_amount IS NULL))
--    11/3/2000 mramanat Bugfix 1424234. While Checking
--    l_dist_rec_amt to p_amount, Then the Absolute Value of
--    p_amount is used.
        ((l_dist_rec_amt = ABS(p_amount)) OR    --Bug Fix 1424234
        (l_dist_rec_amt IS NULL AND p_amount IS NULL))
    AND
      ((l_mcd_rec.comments = p_comments) OR
      (l_mcd_rec.comments IS NULL AND p_comments IS NULL))
    AND
      ((l_mcd_rec.code_combination_id = p_code_combination_id) OR
      (l_mcd_rec.code_combination_id IS NULL AND p_code_combination_id IS NULL))
    AND
      ((l_mcd_rec.attribute_category = p_attribute_category) OR
      (l_mcd_rec.attribute_category IS NULL AND p_attribute_category IS NULL))
    AND
      ((l_mcd_rec.ussgl_transaction_code = p_ussgl_tc) OR
      (l_mcd_rec.ussgl_transaction_code IS NULL AND p_ussgl_tc IS NULL))
    AND
      ((l_mcd_rec.attribute1 = p_attribute1) OR
      (l_mcd_rec.attribute1 IS NULL AND p_attribute1 IS NULL))
    AND
      ((l_mcd_rec.attribute2 = p_attribute2) OR
      (l_mcd_rec.attribute2 IS NULL AND p_attribute2 IS NULL))
    AND
      ((l_mcd_rec.attribute3 = p_attribute3) OR
      (l_mcd_rec.attribute3 IS NULL AND p_attribute3 IS NULL))
    AND
      ((l_mcd_rec.attribute4 = p_attribute4) OR
      (l_mcd_rec.attribute4 IS NULL AND p_attribute4 IS NULL))
    AND
      ((l_mcd_rec.attribute5 = p_attribute5) OR
      (l_mcd_rec.attribute5 IS NULL AND p_attribute5 IS NULL))
    AND
      ((l_mcd_rec.attribute6 = p_attribute6) OR
      (l_mcd_rec.attribute6 IS NULL AND p_attribute6 IS NULL))
    AND
      ((l_mcd_rec.attribute7 = p_attribute7) OR
      (l_mcd_rec.attribute7 IS NULL AND p_attribute7 IS NULL))
    AND
      ((l_mcd_rec.attribute8 = p_attribute8) OR
      (l_mcd_rec.attribute8 IS NULL AND p_attribute8 IS NULL))
    AND
      ((l_mcd_rec.attribute9 = p_attribute9) OR
      (l_mcd_rec.attribute9 IS NULL AND p_attribute9 IS NULL))
    AND
      ((l_mcd_rec.attribute10 = p_attribute10) OR
      (l_mcd_rec.attribute10 IS NULL AND p_attribute10 IS NULL))
    AND
      ((l_mcd_rec.attribute11 = p_attribute11) OR
      (l_mcd_rec.attribute11 IS NULL AND p_attribute11 IS NULL))
    AND
      ((l_mcd_rec.attribute12 = p_attribute12) OR
      (l_mcd_rec.attribute12 IS NULL AND p_attribute12 IS NULL))
    AND
      ((l_mcd_rec.attribute13 = p_attribute13) OR
      (l_mcd_rec.attribute13 IS NULL AND p_attribute13 IS NULL))
    AND
      ((l_mcd_rec.attribute14 = p_attribute14) OR
      (l_mcd_rec.attribute14 IS NULL AND p_attribute14 IS NULL))
    AND
      ((l_mcd_rec.attribute15 = p_attribute15) OR
      (l_mcd_rec.attribute15 IS NULL AND p_attribute15 IS NULL))
    AND
      ((l_mcd_rec.gl_posted_date = p_gl_posted_date) OR
      (l_mcd_rec.gl_posted_date IS NULL AND p_gl_posted_date IS NULL)) )
  THEN
      NULL;
IF PG_DEBUG in ('Y', 'C') THEN
   arp_standard.debug(' after IF');
END IF;
  ELSE
      FND_MESSAGE.Set_Name('FND', 'FORM_RECORD_CHANGED');
      APP_EXCEPTION.Raise_Exception;
  END IF;
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug(' distribution amount ' || TO_CHAR(l_dist_rec_amt));
     arp_standard.debug(' End lock AR_DIST amount');
  END IF;

 --begin 1813186
-- end if;
 --end 1813186
  -- Call table handler for ar_cash_receipts to lock record.
  /* Bug fix 3032059 */
  /* Receipt Version Number also to be used for locking the cash_receipt record */
  arp_cash_receipts_pkg.nowaitlock_version_p(p_cash_receipt_id,p_rec_version_number);
  /*arp_cash_receipts_pkg.nowaitlock_p(p_cash_receipt_id);*/
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('arp_process_receipts.lock_mcd_rec()-');
  END IF;

--    EXCEPTION
--       WHEN NO_DATA_FOUND THEN
--              FND_MESSAGE.Set_Name('FND', 'FORM_RECORD_CHANGED');
--              APP_EXCEPTION.Raise_Exception;
--        WHEN  OTHERS THEN
--           IF (SQLCODE = -54) THEN
--                 FND_MESSAGE.Set_Name('FND', 'FORM-CANNOT LOCK');
--                 FND_MESSAGE.set_token( 'TABLE', 'AR_MISC_CASH_DISTRIBUTIONS');
--                 APP_EXCEPTION.Raise_Exception;
--            ELSE
--                  arp_util.debug( SQLERRM );
--                  RAISE;
--            END IF;

--	  APP_EXCEPTION.Raise_Exception;

END lock_mcd_rec;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    round_correction_mcd_rec                         			     |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Correct the rounding correctiopn in  a miscellaneous distribution      |
 |    record from ar_misc_cash_distributions lines to 1st line.   	     |
 |    we don't take care of rounding while insert or updation new MCD        |
 |    in Distribution window						     |
 |									     |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED 	                             |
 |                                                                           |
 | ARGUMENTS                                                                 |
 |    IN:								     |
 |    OUT:                                                                   |
 |                                                                           |
 | RETURNS    		                                                     |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY 						     |
 |									     |
 |    18-JAN-2001	ANUJ	        Created  for 1543658 		     |
 |    19-Sep-2001	Debbie Jancis	Added hook for mrc engine for        |
 |					to process update information        |
 +===========================================================================*/



PROCEDURE round_correction_mcd_rec(
	p_cash_receipt_id	IN  ar_cash_receipts.cash_receipt_id%TYPE,
    p_flag 		OUT NOCOPY NUMBER
)  IS

l_min_unit		        NUMBER;
l_precision	           	NUMBER;
l_acctd_rounding_diff	NUMBER;
l_rounding_diff		    NUMBER;
l_acctd_amount	        NUMBER;
l_dummy			        NUMBER;
l_cr_rec                ar_cash_receipts%ROWTYPE;
l_ard_acctd_cr_rounding_diff	NUMBER;
l_ard_acctd_dr_rounding_diff	NUMBER;
l_ar_rounding_diff             	NUMBER;
l_ard_acctd_cr	                NUMBER;
l_ard_acctd_dr               	NUMBER;

l_misc_cash_key_value_list      gl_ca_utility_pkg.r_key_value_arr; /* MRC */

  CURSOR mcd_cur
      ( l_cash_receipt_id in ar_cash_receipts.cash_receipt_id%TYPE)
   IS
      SELECT *
      from ar_misc_cash_distributions
      where cash_receipt_id = l_cash_receipt_id
            and reversal_gl_date is null;
  tbl_ctr number;
  update_flag Char(1);

BEGIN

  -- arp_standard.enable_debug;
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('arp_process_receipts.rounding_correction_mcd_rec()+');
  END IF;
 p_flag := 0;

     -- this select will fetch some important information
     -- which we need to pass in the table handler
     -- of AR Distributions
      select cr.cash_receipt_id                  ,
             cr.amount                           ,
             cr.vat_tax_id                       ,
             cr.tax_rate                         ,
             cr.type                             ,
             cr.currency_code                    ,
             cr.exchange_rate                    ,
             cr.exchange_rate_type               ,
             cr.exchange_date                    ,
             cr.pay_from_customer                , --third_party_id
             cr.customer_site_use_id             , --third_party_sub_id
             fc.precision                        ,
             fc.minimum_accountable_unit
      into  l_cr_rec.cash_receipt_id             ,
            l_cr_rec.amount                      ,
            l_cr_rec.vat_tax_id                  ,
            l_cr_rec.tax_rate                    ,
            l_cr_rec.type                        ,
            l_cr_rec.currency_code               ,
            l_cr_rec.exchange_rate               ,
            l_cr_rec.exchange_rate_type          ,
            l_cr_rec.exchange_date               ,
            l_cr_rec.pay_from_customer           , --third_party_id
            l_cr_rec.customer_site_use_id        , --third_party_sub_id
            l_precision                          ,
            l_min_unit
      from ar_cash_receipts           cr,
           fnd_currencies             fc
      where cr.cash_receipt_id      = p_cash_receipt_id
      and   cr.currency_code        = fc.currency_code;
  -- calculate accounted amount
  -- Changes for triangulation: If exchange rate type is not user, call
  -- GL API to calculate accounted amount
  IF (l_cr_rec.type = 'MISC' ) THEN
    IF (l_cr_rec.exchange_rate_type = 'User') THEN
     arp_util.calc_acctd_amount(	NULL,
				NULL,
				NULL,
				l_cr_rec.exchange_rate,
				'+',
				l_cr_rec.amount ,
				l_acctd_amount,
				0,
				l_dummy,
				l_dummy,
				l_dummy);
    ELSE
        l_acctd_amount := gl_currency_api.convert_amount(
			arp_global.set_of_books_id,
			l_cr_rec.currency_code,
			l_cr_rec.exchange_date,
			l_cr_rec.exchange_rate_type,
			l_cr_rec.amount);
    END IF;
        tbl_ctr :=0;
        FOR cr_mcd_rec IN mcd_cur(p_cash_receipt_id) LOOP
          --tbl_ctr := tbl_ctr + 1;   -- Commented for bug 2113787.
          if l_cr_rec.exchange_rate is not null then
	     tbl_ctr := tbl_ctr + 1;  -- Added for bug 2113787.
           if  (arp_global.base_min_acc_unit is null) then

               cr_mcd_rec.acctd_amount  :=  round(cr_mcd_rec.amount*nvl(l_cr_rec.exchange_rate ,1),
                                                arp_global.base_precision);
           else
               cr_mcd_rec.acctd_amount  := round(cr_mcd_rec.amount*nvl(l_cr_rec.exchange_rate ,1)
		                    / arp_global.base_min_acc_unit) * arp_global.base_min_acc_unit;
           end if;


          --end if;   Commented for bug 2113787.
          mcd_tbl_tbl(tbl_ctr) := cr_mcd_rec;
          update_flag:='Y';
	  end if;  -- Added for bug2113787.
        END LOOP;
      IF update_flag='Y'  THEN
          FOR l_ctr IN mcd_tbl_tbl.FIRST .. mcd_tbl_tbl.LAST LOOP
            arp_misc_cash_dist_pkg.update_p(mcd_tbl_tbl(l_ctr));
          END LOOP;
          p_flag :=p_flag +1;
      END IF;
      mcd_tbl_tbl.delete;



    SELECT  NVL(l_cr_rec.amount, 0) -
            NVL(SUM(amount),0)
            ,
            NVL(l_acctd_amount,0) -
            NVL(SUM(acctd_amount),0)

    INTO    l_rounding_diff,
            l_acctd_rounding_diff
    FROM    ar_misc_cash_distributions
    WHERE   cash_receipt_id = p_cash_receipt_id
            and reversal_gl_date is null;

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('round_correction_mcd_rec: ' || 'Rounding error = ' ||to_char(l_rounding_diff));
       arp_util.debug('round_correction_mcd_rec: ' || 'Rounding error (acctd) = ' ||to_char(l_acctd_rounding_diff));
    END IF;

    IF (l_acctd_rounding_diff <> 0 OR l_rounding_diff <>0) THEN

        UPDATE  ar_misc_cash_distributions
        SET     amount  	= amount + l_rounding_diff,
            acctd_amount	= acctd_amount + l_acctd_rounding_diff

        WHERE   cash_receipt_id = p_cash_receipt_id
                and reversal_gl_date is null
                AND   ROWNUM = 1
        RETURNING misc_cash_distribution_id
        BULK COLLECT INTO l_misc_cash_key_value_list;

        p_flag :=p_flag +1;
    END IF;


    --Now rounding correction of accounting amount for AR Distribution

        SELECT   NVL(SUM(acctd_amount_cr),0),
                 NVL(SUM(acctd_amount_dr),0)
        INTO     l_ard_acctd_cr,
                 l_ard_acctd_dr
        FROM    ar_distributions
        where source_id in (select misc_cash_distribution_id
                            from ar_misc_cash_distributions
                            where cash_receipt_id = p_cash_receipt_id
                                  and reversal_gl_date is null ) and
              source_table = 'MCD' ;

     l_ard_acctd_dr_rounding_diff:= 0;
     l_ard_acctd_cr_rounding_diff:= 0;
     IF sign(l_cr_rec.amount) = -1 THEN
         l_ard_acctd_dr_rounding_diff:=
               ABS(NVL(l_acctd_amount,0)) +l_ard_acctd_cr -l_ard_acctd_dr;
     ELSE

        l_ard_acctd_cr_rounding_diff:=
              ABS(NVL(l_acctd_amount,0)) -l_ard_acctd_cr+l_ard_acctd_dr;
     END IF;


     IF (l_ard_acctd_dr_rounding_diff <> 0) THEN

        UPDATE  ar_distributions
        SET   acctd_amount_dr	= acctd_amount_dr + l_ard_acctd_dr_rounding_diff

        WHERE   source_id in (select misc_cash_distribution_id
                              from ar_misc_cash_distributions
                              where cash_receipt_id = p_cash_receipt_id
                                    and reversal_gl_date is null )
                AND   ROWNUM = 1
                AND   source_table = 'MCD'
                AND   source_type  ='MISCCASH'
		AND   acctd_amount_dr is not null ; /* Added for bug 2278738 */
        p_flag :=p_flag +1;
     END IF;
   IF (l_ard_acctd_cr_rounding_diff <>0) THEN

        UPDATE  ar_distributions
        SET     acctd_amount_cr	= acctd_amount_cr + l_ard_acctd_cr_rounding_diff
        WHERE   source_id in (select misc_cash_distribution_id
                              from ar_misc_cash_distributions
                              where cash_receipt_id = p_cash_receipt_id
                                    and reversal_gl_date is null)
                AND   ROWNUM = 1
                AND   source_table = 'MCD'
                AND   source_type  ='MISCCASH'
		AND   acctd_amount_cr is not null ; /* Added for bug 2278738 */
        p_flag :=p_flag +1;
    END IF;
/* Added for bug 2278738 */
/* Bug fix 2929316 : Commented out the call to COMMIT
   The rounding correction is called in the ON-COMMIT trigger and
   need not be committed again */
/*   IF (p_flag > 0) THEN
      COMMIT;
   END IF; */

  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('round_correction_mcd_rec: ' || 'arp_process_receipts.rounding_correction_mcd_rec()-');
  END IF;
END IF;
END round_correction_mcd_rec;

/* Bug fix 2300268 */
/* Function which returns the code combination id associated with the tax line of a MISC receipt */
/* Bugfix 2753644 . Code modified since reversal or rate adjustment results
  in ora 1422. Used MIN to select source_id. */
FUNCTION  misc_cash_tax_line_ccid_in_ard(
            p_cash_receipt_id IN number) return NUMBER IS
 return_value number;

    min_misc_cash_distribution_id number;

BEGIN
    BEGIN
         select MIN(misc_cash_distribution_id) into min_misc_cash_distribution_id
         from ar_misc_cash_distributions
         where cash_receipt_id=p_cash_receipt_id;

         select code_combination_id into return_value
         from ar_distributions
         where source_id = min_misc_cash_distribution_id
--          where source_id in (select MIN(misc_cash_distribution_id)
--                           from ar_misc_cash_distributions
--                           where cash_receipt_id=p_cash_receipt_id)
         and SOURCE_TABLE ='MCD'
         and SOURCE_TYPE = 'TAX';
    EXCEPTION
         when no_data_found then null;
    END;
    RETURN return_value ;
EXCEPTION
    WHEN others THEN
        raise ;
END misc_cash_tax_line_ccid_in_ard;
/* End bug fix 2300268 */

END ARP_MISC_CASH_DIST;