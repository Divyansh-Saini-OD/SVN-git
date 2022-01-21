/*_______10________20________30________40________50________60________70       */
/*============================================================================+
 |  Copyright (c) 2005, 2014 Oracle Corporation Redwood Shores, California, USA     |
 |                          All rights reserved.                              |
 +============================================================================+
 | PACKAGE BODY         XX_ARP_ETAX_UTIL 
 |
 | DESCRIPTION
 |      Package containing an assortment of utilities for passsing data
 |      to ETAX GT tables or structures and retrieving data back from
 |      ETAX .        
 |
 | PSEUDO CODE LOGIC/ALGORITHMS
 | 
 | CALLED PACKAGES                   
 |    debug
 |    fnd_installation.get_app_info
 |
 | PUBLIC PROCEDURES
 |    prorate_recoverable (overloaded)
 |    distribute_recoverable (for receipts only)
 |    build_ar_tax_lines
 |    delete_tax_lines_from_ar (for use prior to build_ar_tax_lines)
 |    get_tax_account (for use in autoaccounting)
 |    get_default_tax_classification 
 |    set_default_tax_classification
 |    calc_applied_and_remaining (wrapper for ARP_APP_CALC_PKG version)
 |
 | PUBLIC FUNCTIONS
 |    get_discount_rate (returns max discount for transaction)
 | 
 | PRIVATE PROCEDURES
 |    validate_tax_int  (externally callable)
 |    calculate_tax_int (externally callable)
 |
 | PUBLIC VARIABLES
 |
 | PROFILE OPTIONS                                                        
 |                                                         
 | KNOWN ISSUES
 | 
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 28-FEB-2005           MRAYMOND          Created                      
 | 23-JUN-2005           MRAYMOND          Updated build_ar_tax_lines to
 |                                         remove existing lines and dists first.
 | 12-AUG-2005           MRAYMOND          Updated prorate_recoverable to handle
 |                                         adjustments
 | 01-SEP-2005           MRAYMOND          Added support for tax_rate_id to
 |                                         get_tax_account
 | 25-OCT-2005           MRAYMOND          Modified build_ar_tax_lines to
 |                                         return number of rows inserted.
 | 29-DEC-2005           MRAYMOND          4917065 - get_tax_account raising 
 |                                          silent exception due to uninitialized
 |                                          return code.
 | 06-JAN-2006           MRAYMOND          4932916 - Revised upd_adj_and_ps
 |                                          to only update with delta amt
 |                                          on PS record.  Also only
 |                                          updates PS if required
 | 06-JAN-2006           MRAYMOND          4740826 - added procedure
 |                                          set_default_tax_classification
 | 08-JAN-2006           MRAYMOND          4937059 - Fixed line total problem
 |                                          when adj against line w/multiple 
 |                                          tax lines corrupted line_recoverable
 | 24-MAR-2006           MRAYMOND          4607809 - Added calc_applied_and_rem
 |                                          wrapper for use in quickcash
 |                                          discount logic.
 | 24-MAR-2006           MRAYMOND          5114068 - Revised build_ar_tax
 |                                          to not delete lines that were
 |                                          not previously affiliated with
 |                                          etax module.
 | 31-MAR-2006           MRAYMOND          4607809 - separated out
 |                                         call to arp_det_dist_pkg for
 |                                         receipts and placed it into
 | 06-APR-2006           MRAYMOND          5146437 - Corrected problem with logic
 |                                          that removes inclusive tax from inv lines.
 | 10-APR-2006           MRAYMOND          5125882 - Removed where conditions
 |                                          distribute_recoverable  
 | 13-APR-2006           MRAYMOND          5159129 - Calling arp_det_dist_pkg
 |                                          incorrectly resulted in acct failure.
 | 27-APR-2006           MRAYMOND          4928047 - Added logic to fetch
 |                                           ccid for default_classifictn call
 | 17-MAY-2006           MRAYMOND          5197332 - Corrected proration for
 |                                           tax-only adjustments
 | 26-MAY-2006           MRAYMOND          5152340 - Created new function
 |                                           to delete tax lines from
 |                                           ra_customer_trx_lines if they
 |                                           are present in ZX_LINES.  Called
 |                                           delete_tax_lines_from_ar
 | 16-JUN-2006           MRAYMOND          5235410 - Added function
 |                                           get_discount_rate
 | 27-JUN-2006           MRAYMOND          5264385 - Added poo/poa and
 |                                           ship_from columns
 | 11-SEP-2006           MRAYMOND          5385324 - added a new
 |                                           parameter to synchronize routine
 |                                           that allows update of line values
 |                                           (really just trx_line_gl_date)
 | 03-OCT-2006           MRAYMOND          5393508 - Do not populate
 |                                           trx_line_date
 | 06-OCT-2006           MRAYMOND          5487466 - Modified 
 |                                           adjust_for_inclusive to handle
 |                                           changes from incl/excl or when
 |                                           tax goes from incl/none.
 | 27-OCT-2006           MRAYMOND          5599088 - added org_id
 |                                           to get_tax_account for TAX_RATE
 |                                           type calls.
 | 15-NOV-2006           MRAYMOND          5659355 - added sob_id to
 |                                           get_tax_account calls for both
 |                                           TAX_RATE and TAX_LINE calls.
 | 04-DEC-2006           MRAYMOND          5636852 - rule-based transactions
 |                                           not fetching tax accounts
 |                                           correctly in get_tax_account
 | 07-DEC-2006           MRAYMOND          5677984 - added an overloaded
 |                                           version of prorate_recoverable
 |                                           specifically for receipts.
 | 01-MAR-2007           MRAYMOND          5748090 - Modified synchronize
 |                                           to preserve non-AR values
 |                                           using FND_API.G_MISS values.
 | 05-NOV-2008           MRAYMOND          7513162 - Addessed issue where
 |                                           line_recoverable is zero or null
 | 16-JUN-2009           MRAYMOND          8578810 - prevent tax recalc
 |                                           when transaction is posted.
 | 01-MAR-2011           QIONG             11671073 - THE TRANSACTION TOTAL DOUBLES 
 |                                         IF INCLULSIVE TAX AMOUNT IS SAME AS LINE 
 *============================================================================*/

/*_______10________20________30________40________50________60________70       */
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile(120.39.12000000.66=120.47.12010000.44)(120.39.12000000.60=120.47.12010000.38)(120.39.12000000.58=120.47.12010000.36)(120.39.12000000.46=120.47.12010000.24)(120.39.12000000.34=120.72):~PROD:~PATH:~FILE

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_ARP_ETAX_UTIL AS
/* $Header: AREBTUTB.pls 120.47.12010000.44 2014/02/20 05:36:07 kgnanase ship $ */

/*=======================================================================+
 |  Package Globals      
 +=======================================================================*/

   /* caching values for get_tax_account function */
   g_tax_customer_trx_line_id   ra_customer_trx_lines.customer_trx_line_id%type;
   g_tax_rate_id                NUMBER;
   g_tax_account_ccid           gl_code_combinations.code_combination_id%type;
   g_interim_tax_ccid           gl_code_combinations.code_combination_id%type;
   g_adj_ccid                   gl_code_combinations.code_combination_id%type := -1;
   g_edisc_ccid                 gl_code_combinations.code_combination_id%type := -1;
   g_unedisc_ccid               gl_code_combinations.code_combination_id%type := -1;
   g_finchrg_ccid               gl_code_combinations.code_combination_id%type := -1;
   g_adj_non_rec_tax_ccid       gl_code_combinations.code_combination_id%type := -1;
   g_edisc_non_rec_tax_ccid     gl_code_combinations.code_combination_id%type := -1;
   g_unedisc_non_rec_tax_ccid   gl_code_combinations.code_combination_id%type := -1;
   g_finchrg_non_rec_tax_ccid   gl_code_combinations.code_combination_id%type := -1;

   g_trx_id_for_disc            NUMBER;
   g_rate_for_disc              NUMBER;

   l_status                     VARCHAR2(1);  -- junk variable
   l_industry                   VARCHAR2(1);  -- junk variable
   PG_DEBUG VARCHAR2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');

   pg_so_org_id                  VARCHAR2(20);
   pg_org_id                     NUMBER;

   --PG_USE_TAX_CALC_ACCTD_AMT VARCHAR2(1) := NVL(FND_PROFILE.value('AR_USE_TAX_CALC_ACCTD_AMT'), 'N');

TYPE number_table_type IS
    TABLE OF ra_customer_trx_lines_all.line_recoverable%type
    INDEX BY VARCHAR2(100);  --Bug 9763252

TYPE l_line_id_type IS TABLE OF 
    ra_customer_trx_lines_all.customer_trx_line_id%type
    INDEX BY BINARY_INTEGER;

TYPE l_tax_classif_type IS TABLE OF 
    ra_customer_trx_lines_all.tax_classification_code%type
    INDEX BY BINARY_INTEGER;

/*========================================================================
 | Prototype Declarations Procedures
 *=======================================================================*/


/*========================================================================
 | Prototype Declarations Functions
 *=======================================================================*/

PROCEDURE debug(text IN VARCHAR2) IS
BEGIN
    --fnd_file.put_line(FND_FILE.LOG, text);
    arp_debug.debug(text);
END;

/*6932455 1. Removed the Pragma Autonomous Exception.
 *	  2. Changed the Truncate to Delete
 *	  3. Removed the Commit statement
 *
 * 7329586 - Removed schema logic and reverted DELETE statements
     to static sql (no need for dynamic sql here)
 */
PROCEDURE clear_ebt_gt IS
   l_owner VARCHAR2(30);

BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
         debug('XX_ARP_ETAX_UTIL.clear_ebt_gt()+');
   END IF;

   /* The eTax GT tables are cleared upon commit.  However
      we cannot blindly issue a commit in between our first
      (INV) and second (CM) calls.  So I am adding this tidbit
      of code to clear the tables prior to the call (for credits).

      NOTE:  The truncate command for GT tables only truncates
      data for this session, not other unrelated sessions (per
      SQL documentation) */

   DELETE FROM ZX_TRX_HEADERS_GT;
   DELETE FROM ZX_TRANSACTION_LINES_GT;
   DELETE FROM ZX_IMPORT_TAX_LINES_GT;
   DELETE FROM ZX_TRX_TAX_LINK_GT;
   DELETE FROM ZX_DETAIL_TAX_LINES_GT;

   IF PG_DEBUG in ('Y', 'C') THEN
         debug('XX_ARP_ETAX_UTIL.clear_ebt_gt()-');
   END IF;
END;

/* Procedure to retrieve TAX lines from ZX and populate 
   RA_CUSTOMER_TRX_LINES accordingly.

   During later testing, we discovered that this procedure actually
   needs to remove existing tax lines and distributions and create
   new tax lines.  At this point, we are leaving the call to autoaccounting
   out as the calling code already contains that call.  

   NOTE:  This is not used by autoinvoice as a similar
    procedure is defined in ARP_ETAX_AUTOINV_UTIL 

   24-MAR-2006 MRAYMOND   5114068 - Indian Localization guys
                            asked us to preserve their non-etax 
                            lines.

*/
PROCEDURE build_ar_tax_lines(
                 p_customer_trx_id  IN  NUMBER,
                 p_rows_inserted    OUT NOCOPY NUMBER) IS

  l_rows NUMBER;

BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
      debug('XX_ARP_ETAX_UTIL.build_ar_tax_lines()+');
   END IF; 

   /* Dev Notes:

   1) We set autotax flag as inverse of manaully_entered_flag
      coming from eTax
 
      RESP:  Ok.  That should be fine

   2) Does eTax generate autotax lines when manual ones for 
      same inv/cm line are present?  If so, can we still rely
      upon manually_entered_flag to determine which is which?

      RESP:  That is soft-configurable.  So we can use
      manually_entered_flag to determine what value
      of autotax should be.

   3) Previous_customer_trx_line_id.. we need a way to set this
      for each CM tax line.  I communicated this to Santosh on
      3-MAR-05 along with my suggestion which was to have them add
      a 45th column for link_to_trx_line_id or perhaps applied_to_trx_line_id
      The idea for this is that they pass me the eTax line_id of the target
      tax line and I use that to fetch the customer_trx_line_id of the
      corresponding line in ra_customer_trx_lines.  

      However, I'll probably need an index based on tax_line_id in
      RA_CUSTOMER_TRX_LINES table to make that search fast enough

   4) Changed from trx_line_id to trx_id per djancis.  We have to 
      build all tax lines each time.
 
   5) Added deletes for ra_customer_trx_lines and ra_cust_trx_line_gl_dist
      tables.
 
   6) Added logic to populate previous_customer_trx_line_id of CM 
      tax lines.  Used Navigator to tweak for improved perf.

   7) Added logic to preserve IL localization tax lines.
      spoke with Ling (etax) and she said I need to join
      to ZX lines to confirm that there is (or isnt) a
      tax line over there.  Just a value in tax_line_id is not
      sufficient to guarantee that it is a migrated or native R12
      tax line.

   8) Number 7 didnt work.  Only way to resolve is to separate
      delete logic from insert logic.  Execute delete before
      call to calculate_tax and insert afterwards.

   9) 5487466 - always call adjust_for_inclusive_tax because we
      may need to alter the line values if the inclusive/excl state
      of the tax changes or the tax lines go away.
 
   End Dev Notes */

   /* Bug 5152340 - Removed delete logic to its own procedure */

   INSERT INTO RA_CUSTOMER_TRX_LINES
   (
      CUSTOMER_TRX_LINE_ID, 
      LAST_UPDATE_DATE,
      LAST_UPDATED_BY,
      CREATION_DATE,
      CREATED_BY,
      LAST_UPDATE_LOGIN,
      PROGRAM_ID,
      PROGRAM_APPLICATION_ID,
      CUSTOMER_TRX_ID,
      LINE_NUMBER,
      SET_OF_BOOKS_ID,
      LINE_TYPE,                -- TAX
      LINK_TO_CUST_TRX_LINE_ID, -- parent line
      DEFAULT_USSGL_TRANSACTION_CODE, 
      REQUEST_ID,
      EXTENDED_AMOUNT,
      TAX_RATE,
      AUTOTAX,
      AMOUNT_INCLUDES_TAX_FLAG,
      TAXABLE_AMOUNT,
      VAT_TAX_ID,
      TAX_LINE_ID,               -- ID in ZX_ table
      PREVIOUS_CUSTOMER_TRX_LINE_ID,
      PREVIOUS_CUSTOMER_TRX_ID,  -- 5125882
      ORG_ID--, 
      --TAX_CALC_ACCTD_AMT
   )
   SELECT
      ra_customer_trx_lines_s.nextval,
      sysdate,
      arp_standard.profile.user_id,
      sysdate,
      arp_standard.profile.user_id,
      arp_standard.profile.user_id,
      arp_standard.profile.program_id,
      arp_standard.application_id,  
      zxt.trx_id,
      zxt.tax_line_number,
      arp_standard.sysparm.set_of_books_id,
      'TAX',
      zxt.trx_line_id,
      plin.default_ussgl_transaction_code,
      NULL,  -- request_id
      zxt.tax_amt,
      zxt.tax_rate,
      DECODE(NVL(zxt.manually_entered_flag, 'N'), 'Y', NULL, 'Y'),
      zxt.tax_amt_included_flag,
      zxt.taxable_amt,
      zxt.tax_rate_id,
      zxt.tax_line_id,
      inv_lin.customer_trx_line_id, -- invoice tax line id
      inv_lin.customer_trx_id,      -- inv trx_id, 5125882
      plin.org_id	--,
      --DECODE(PG_USE_TAX_CALC_ACCTD_AMT,'Y',zxt.TAX_AMT_FUNCL_CURR,NULL)		
   FROM   ZX_LINES               zxt,
          RA_CUSTOMER_TRX_LINES  plin,
          ZX_LINES               inv_zxt,
          RA_CUSTOMER_TRX_LINES  inv_lin
   WHERE
          zxt.application_id = 222
   AND    zxt.entity_code    = 'TRANSACTIONS'
   AND    zxt.event_class_code in ('INVOICE','DEBIT_MEMO','CREDIT_MEMO')
   AND    zxt.trx_id = p_customer_trx_id 
   AND    zxt.trx_level_type = 'LINE'
   AND    zxt.trx_line_id = plin.customer_trx_line_id
   AND    zxt.adjusted_doc_tax_line_id = inv_zxt.tax_line_id (+)
   AND    inv_zxt.trx_line_id = inv_lin.link_to_cust_trx_line_id (+)
   AND    inv_zxt.tax_line_id = inv_lin.tax_line_id (+);

   l_rows := SQL%ROWCOUNT;

   /* The routine below was written to be called only if tax
      returned lines.  However it was recently modified to handle
      cases where tax changes from incl to excl or when tax lines
      are completely removed from the transaction.  */ 

   /* reduce line amount for inclusive tax lines */
   adjust_for_inclusive_tax(p_customer_trx_id);

   /* set line_recoverable and tax_recoverable */
   set_recoverable(p_customer_trx_id);
  
   /* Return number of rows inserted to limit calls
      to autoaccounting and other followon code */
   p_rows_inserted := l_rows;

   IF PG_DEBUG in ('Y', 'C') THEN
      debug('  Number of tax lines retrieved = ' || l_rows);
      debug('XX_ARP_ETAX_UTIL.build_ar_tax_lines()-');
   END IF; 
END build_ar_tax_lines;

/* Procedure for removing tax lines from AR prior to calculate
   and build_ar_tax_lines calls.  This code was separated out so
   we could delete from AR based on existing tax lines just before
   calling calculate_tax (which recreates them in ZX).  This means
   that we can use the presence of lines in ZX_LINES as a basis 
   for our delete.  So the intended flow is now like this:

   1) call delete_tax_lines_from_ar
   2) call eTax calculate_tax 
   3) call build_ar_tax_lines

   NOTE:  This is really only relevant for forms code as the invoice
   API, autoinvoice, and invoice copy only create transactions so there
   should not be a case where we recalculate tax (again) or manipulate
   existing transactions with localization tax.
*/

PROCEDURE delete_tax_lines_from_ar(
                 p_customer_trx_id  IN  NUMBER) IS

  l_rows NUMBER;
  l_posted VARCHAR2(50);

BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
      debug('XX_ARP_ETAX_UTIL.delete_tax_lines_from_ar()+');
   END IF; 

   /* 8578810 - prevent deleting of posted rows or creation of additional
        or duplicate distributions for late tax calculations */
   BEGIN

      SELECT 'Transaction is not posted'
      INTO   l_posted
      FROM   ra_cust_trx_line_gl_dist
      WHERE  customer_trx_id = p_customer_trx_id
      AND    account_class = 'REC'
      AND    latest_rec_flag = 'Y'
      AND    posting_control_id = -3;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
          IF PG_DEBUG in ('Y','C')
          THEN
             debug('EXCEPTION:  Transaction is posted, cannot delete');
          END IF;
          fnd_message.set_name('AR','AR_CANT_UPDATE_IF_POSTED');
          app_exception.raise_exception;  
   END;


   DELETE FROM RA_CUST_TRX_LINE_GL_DIST gld
   WHERE  customer_trx_line_id in (
            SELECT tl.customer_trx_line_id
            FROM   RA_CUSTOMER_TRX_LINES tl,
                   ZX_LINES zx
            WHERE  tl.customer_trx_id = p_customer_trx_id
            AND    tl.line_type = 'TAX'
            AND    tl.tax_line_id IS NOT NULL
            AND    tl.tax_line_id = zx.tax_line_id)
   AND    customer_trx_id = p_customer_trx_id
   AND    account_class = 'TAX'
   AND    posting_control_id = -3;

   IF PG_DEBUG in ('Y', 'C') THEN
      l_rows := SQL%ROWCOUNT;
      debug('  Deleted tax dists = ' || l_rows);
   END IF; 
 
   /* NOTE:  zx_lines_u2 uses only tax_line_id as key */

   DELETE FROM RA_CUSTOMER_TRX_LINES
   WHERE  customer_trx_id = p_customer_trx_id
   AND    line_type = 'TAX'
   AND    tax_line_id IN
        (SELECT tax_line_id
         FROM   ZX_LINES);

   IF PG_DEBUG in ('Y', 'C') THEN
      l_rows := SQL%ROWCOUNT;
      debug('  Deleted tax lines = ' || l_rows);
      debug('XX_ARP_ETAX_UTIL.delete_tax_lines_from_ar()-');
   END IF; 

END delete_tax_lines_from_ar;

/* Wrapper for call to zx_api_pub.validate_and_default_tax_attr */
PROCEDURE validate_tax_int (p_return_status OUT NOCOPY NUMBER,
                             p_called_from_AI IN VARCHAR2 DEFAULT 'N') IS
  l_return_status VARCHAR2(50);
  l_message_count NUMBER;
  l_message_data  VARCHAR2(2000);
  l_msg           VARCHAR2(2000);
BEGIN

   ZX_API_PUB.validate_and_default_tax_attr(
     p_api_version      => 1.0,
     p_init_msg_list    => FND_API.G_FALSE,
     p_commit           => FND_API.G_FALSE,
     p_validation_level => FND_API.G_VALID_LEVEL_FULL,
     x_return_status    => l_return_status,
     x_msg_count        => l_message_count,
     x_msg_data         => l_message_data
   );

   IF l_return_status = FND_API.G_RET_STS_SUCCESS
   THEN
      IF PG_DEBUG in ('Y', 'C') THEN
         debug('validate_and_default_tax_attr returns successfully');
      END IF; 
      p_return_status := 0;
   ELSE /* fatal error */
      IF PG_DEBUG in ('Y', 'C') THEN
         debug('validate_and_default_tax_attr returns failure');
      END IF; 

      IF p_called_from_AI = 'Y' THEN
         debug('XX_ARP_ETAX_UTIL.validate_tax_int()+');
	 debug('ZX_API_PUB.validate_and_default_tax_attr returns failure');
      END IF;

      IF l_return_status = FND_API.G_RET_STS_ERROR
      THEN
         p_return_status := 1;
      ELSE
         /* Unexpected error */
         p_return_status := 2;
      END IF;

      /* Retrieve and log errors */
      IF l_message_count = 1 
      THEN
         debug(l_message_data);
         IF p_called_from_AI = 'Y' THEN
           debug(l_message_data);
	 END IF;
      ELSIF l_message_count > 1 
      THEN
         LOOP
            l_msg := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT, 
                                               FND_API.G_FALSE);
            IF l_msg IS NULL
            THEN
               EXIT;
            ELSE
               debug(l_msg);
               IF p_called_from_AI = 'Y' THEN
	         debug(l_msg);
	       END IF;
            END IF; 
         END LOOP;
      END IF;
   END IF;
  
END validate_tax_int;

/* wrapper for call to zx_api_pub.import_document_with_tax */
/*  6743811 - returns 0, 1, or 2 as p_return_status
      0=success, 1=Error, 2=Unexpected Error */
PROCEDURE calculate_tax_int (p_return_status OUT NOCOPY NUMBER,
                             p_called_from_AI IN VARCHAR2 DEFAULT 'N') IS
  l_return_status VARCHAR2(50);
  l_message_count NUMBER;
  l_message_data  VARCHAR2(2000);
  l_msg           VARCHAR2(2000);
BEGIN
   ZX_API_PUB.import_document_with_tax(
     p_api_version      => 1.0,
     p_init_msg_list    => FND_API.G_FALSE,
     p_commit           => FND_API.G_FALSE,
     p_validation_level => FND_API.G_VALID_LEVEL_FULL,
     x_return_status    => l_return_status,
     x_msg_count        => l_message_count,
     x_msg_data         => l_message_data
   );

   IF l_return_status = FND_API.G_RET_STS_SUCCESS
   THEN
      IF PG_DEBUG in ('Y', 'C') THEN
         debug('import_document_with_tax returns successfully');
      END IF; 
      p_return_status := 0;
   ELSE /* fatal error */
      IF PG_DEBUG in ('Y', 'C') THEN
         debug('import_document_with_tax returns failure');
      END IF; 

      IF p_called_from_AI = 'Y' THEN
         debug('XX_ARP_ETAX_UTIL.calculate_tax_int()+');
	 debug('ZX_API_PUB.import_document_with_tax returns failure');
      END IF;

      IF l_return_status = FND_API.G_RET_STS_ERROR
      THEN
         p_return_status := 1;
      ELSE
         /* Unexpected error */
         p_return_status := 2;
      END IF;

      /* Retrieve and log errors */
      IF l_message_count = 1 
      THEN
         debug(l_message_data);
         IF p_called_from_AI = 'Y' THEN
           debug(l_message_data);
	 END IF;
      ELSIF l_message_count > 1 
      THEN
         LOOP
            l_msg := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT, 
                                     FND_API.G_FALSE);
            IF l_msg IS NULL
            THEN
               EXIT;
            ELSE
               debug(l_msg);
               IF p_called_from_AI = 'Y' THEN
	         debug(l_msg);
	       END IF;
	    END IF; 
         END LOOP;
      END IF;
   
   END IF;

  
END calculate_tax_int;

/* External procedure to fetch legal entity and country
   this is a mock up since LE should be in our tables
   for full implementation */

/* Dev Note:  This is a hack that only fetches the first
   LE/Country.. but the underlying code supports multiple
   LE/Country combinations.  Good thing it defaults to
   204/US! */
PROCEDURE get_country_and_legal_ent(
              p_org_id  IN NUMBER,
              p_def_country OUT NOCOPY VARCHAR2,
              p_legal_ent   OUT NOCOPY NUMBER)
IS


  xle_tbl xle_businessinfo_grp.OU_LE_Tbl_Type;

  l_return_status VARCHAR2(50);
  l_message_count NUMBER;
  l_message_data  VARCHAR2(2000);
  l_msg           VARCHAR2(2000);

BEGIN
     IF PG_DEBUG in ('Y', 'C') THEN
        debug('XX_ARP_ETAX_UTIL.get_country_and_legal_ent()+');
     END IF; 


       xle_businessinfo_grp.get_operatingunit_info(l_return_status,
                                                   l_message_data,
                                                   p_org_id,
                                                   NULL,
                                                   NULL,
                                                   xle_tbl);

          /* Using first one for simplicity */
          p_def_country := xle_tbl(1).country;
          p_legal_ent   := xle_tbl(1).legal_entity_id;

   
     IF PG_DEBUG in ('Y', 'C') THEN
        debug('OU = ' || p_org_id);
        debug('LE = ' || p_legal_ent);
        debug('DEF Country = ' || p_def_country);
        debug('XX_ARP_ETAX_UTIL.get_country_and_legal_ent()-');
     END IF; 

END get_country_and_legal_ent;

/* Public Procedure - to update doc sequence data on batch
   transactions after insert 
  
    5468039 - added support for trx_line_gl_date 
        specifically for when gl_date changes */

PROCEDURE synchronize_for_doc_seq(p_trx_id IN NUMBER,
                                  p_return_status  OUT NOCOPY NUMBER,
                                  p_request_id IN NUMBER DEFAULT NULL,
                                  p_sync_line_data IN VARCHAR2 DEFAULT 'N')
IS
  l_return_status VARCHAR2(50);
  l_message_count NUMBER;
  l_message_data  VARCHAR2(2000);
  l_msg           VARCHAR2(2000);
  l_default_country VARCHAR2(50);
  l_legal_entity_id NUMBER;
  l_sync_trx_rec        ZX_API_PUB.sync_trx_rec_type; 
  l_sync_trx_lines_t    ZX_API_PUB.sync_trx_lines_tbl_type%type; 
  l_ttype           ra_cust_trx_types_all.type%type;

CURSOR c_req(p_request_id NUMBER) IS 
   SELECT 
     DECODE(TT.type, 'INV', 'INVOICE',
                     'DM',  'DEBIT_MEMO',
                     'CM',  'CREDIT_MEMO') event_class, 
     TT.type || '_UPDATE'      event_type,
     'Y'                       tax_reporting_flag,
     T.customer_trx_id         customer_trx_id,
     T.trx_number              trx_number,
     SUBSTRB(T.comments,1,240) description,
     T.doc_sequence_id         doc_sequence_id,
     TT.name                   trx_type_name,
     -- bug 6806843
     SEQ.name                  doc_seq_name,
     T.doc_sequence_value      doc_sequence_value, 
     T.batch_source_id         batch_source_id,
     TB.name                   batch_source_name,
     T.cust_trx_type_id        cust_trx_type_id,
     T.trx_date                trx_date,
     T.printing_original_date  printing_original_date,
     T.term_due_date           term_due_date,
     T.bill_to_site_use_id     bill_to_site_use_id
   FROM  RA_CUSTOMER_TRX      T,
         RA_CUST_TRX_TYPES    TT,
         RA_BATCH_SOURCES     TB,
	 FND_DOCUMENT_SEQUENCES SEQ
   WHERE T.request_id = p_request_id
   AND   T.cust_trx_type_id = TT.cust_trx_type_id
   AND   T.doc_sequence_id = SEQ.doc_sequence_id (+)
   AND   T.batch_source_id = TB.batch_source_id
   AND  (T.doc_sequence_id IS NOT NULL OR
         T.doc_sequence_value IS NOT NULL OR
         NVL(T.old_trx_number, T.trx_number) <> T.trx_number OR
         p_sync_line_data = 'Y');

CURSOR c_trx(trx_id NUMBER, sync_line_data VARCHAR2) IS 
   SELECT 
     DECODE(TT.type, 'INV', 'INVOICE',
                     'DM',  'DEBIT_MEMO',
                     'CM',  'CREDIT_MEMO') event_class, 
     TT.type || '_UPDATE'      event_type,
     T.customer_trx_id         customer_trx_id,
     T.trx_number              trx_number,
     SUBSTRB(T.comments,1,240) description,
     T.doc_sequence_id         doc_sequence_id,
     -- bug 6806843
     --TT.name                   trx_type_name,
     SEQ.name                  doc_seq_name,
     T.doc_sequence_value      doc_sequence_value, 
     T.batch_source_id         batch_source_id,
     TB.name                   batch_source_name,
     TT.description            trx_type_description,
     T.printing_original_date  printing_original_date,
     T.term_due_date           term_due_date,
     TT.type                   type
   FROM  RA_CUSTOMER_TRX      T,
         RA_CUST_TRX_TYPES    TT,
         RA_BATCH_SOURCES     TB,
	 FND_DOCUMENT_SEQUENCES SEQ
   WHERE T.customer_trx_id = trx_id
   AND   T.cust_trx_type_id = TT.cust_trx_type_id
   AND   T.doc_sequence_id = SEQ.doc_sequence_id (+)
   AND   T.batch_source_id = TB.batch_source_id
   AND  (T.doc_sequence_id IS NOT NULL OR
         T.doc_sequence_value IS NOT NULL OR
         NVL(T.old_trx_number, T.trx_number) <> T.trx_number OR
         sync_line_data = 'Y');

CURSOR c_trx_lines(trx_id NUMBER) IS
   SELECT 222                 application_id,
          'TRANSACTIONS'      entity_code,
          DECODE(TT.type, 'INV', 'INVOICE',
                          'DM',  'DEBIT_MEMO',
                          'CM',  'CREDIT_MEMO') event_class_code, 
          T.customer_trx_id   trx_id,
          'LINE'              trx_level_type,
          TL.customer_trx_line_id  trx_line_id,
          NULL                trx_waybill_number,
          TL.description      trx_line_description,
          NULL                product_description,
          REC.gl_date         trx_line_gl_date,
          NULL                merchant_party_name,
          NULL                merchant_party_document_number,
          NULL                merchant_party_reference,
          NULL                merchant_party_taxpayer_id,
          NULL                merchant_party_tax_reg_number,
          NULL                asset_number
   FROM
          RA_CUSTOMER_TRX T,
          RA_CUSTOMER_TRX_LINES TL,
          RA_CUST_TRX_TYPES TT,
          RA_CUST_TRX_LINE_GL_DIST REC
   WHERE  T.customer_trx_id = trx_id
   AND    T.cust_trx_type_id = TT.cust_trx_type_id
   AND    T.org_id = TT.org_id
   AND    T.customer_trx_id = TL.customer_trx_id
   AND    TL.line_type = 'LINE'
   AND    T.customer_trx_id = REC.customer_trx_id (+)
   AND    REC.account_class (+) = 'REC' 
   AND    REC.latest_rec_flag (+) = 'Y';

BEGIN
   IF PG_DEBUG in ('Y', 'C') 
   THEN
      debug('XX_ARP_ETAX_UTIL.synchronize_for_doc_seq()+');
      debug('  p_sync_line_data = ' || p_sync_line_data);
   END IF;

     l_sync_trx_rec.application_id                 := 222;
     l_sync_trx_rec.entity_code                    := 'TRANSACTIONS';
     p_return_status                               := 0;
   
   IF p_trx_id is NOT NULL
   THEN

      OPEN c_trx(p_trx_id, p_sync_line_data);
      FETCH c_trx INTO
        l_sync_trx_rec.event_class_code,
        l_sync_trx_rec.event_type_code,
        l_sync_trx_rec.trx_id,
        l_sync_trx_rec.trx_number,
        l_sync_trx_rec.trx_description,
        l_sync_trx_rec.doc_seq_id,
        l_sync_trx_rec.doc_seq_name,
        l_sync_trx_rec.doc_seq_value,
        l_sync_trx_rec.batch_source_id,
        l_sync_trx_rec.batch_source_name,
        l_sync_trx_rec.trx_type_description,
        l_sync_trx_rec.trx_communicated_date,
        l_sync_trx_rec.trx_due_date,
        l_ttype;

        IF PG_DEBUG in ('Y', 'C') 
        THEN
          debug('event_class_code: '||l_sync_trx_rec.event_class_code);
          debug('event_type_code: '||l_sync_trx_rec.event_type_code);
          debug('trx_id: '||l_sync_trx_rec.trx_id);
          debug('trx_number: '||l_sync_trx_rec.trx_number);
          debug('trx_description: '||l_sync_trx_rec.trx_description);
          debug('doc_seq_id: '||l_sync_trx_rec.doc_seq_id);
          debug('doc_seq_name: '||l_sync_trx_rec.doc_seq_name);
          debug('doc_seq_value: '||l_sync_trx_rec.doc_seq_value);
          debug('batch_source_id: '||l_sync_trx_rec.batch_source_id);
          debug('batch_source_name: '||l_sync_trx_rec.batch_source_name);
          debug('trx_type_description: '||l_sync_trx_rec.trx_type_description);
          debug('trx_communicated_date: '||l_sync_trx_rec.trx_communicated_date);
          debug('trx_due_date: '||l_sync_trx_rec.trx_due_date);
          debug('trx_type.type: ' || l_ttype);
        END IF;
        
        /* 5748090 - preserve values in columns that are not
           directly used by AR */
        l_sync_trx_rec.supplier_tax_invoice_number :=  FND_API.G_MISS_CHAR;
        l_sync_trx_rec.supplier_tax_invoice_date   :=  FND_API.G_MISS_DATE;
        l_sync_trx_rec.supplier_exchange_rate      :=  FND_API.G_MISS_NUM;
        l_sync_trx_rec.tax_invoice_date            :=  FND_API.G_MISS_DATE;
        l_sync_trx_rec.tax_invoice_number          :=  FND_API.G_MISS_CHAR;
        l_sync_trx_rec.port_of_entry_code          :=  FND_API.G_MISS_CHAR;
        l_sync_trx_rec.application_doc_status      :=  FND_API.G_MISS_CHAR;

      IF c_trx%rowcount > 0 AND l_ttype NOT IN ('DEP','GUAR')
      THEN
        /* 5468039 - set p_sync_trx_lines_tbl if gl_date
           has to get updated */
        IF p_sync_line_data = 'Y'        
        THEN
           OPEN c_trx_lines(p_trx_id);
           FETCH c_trx_lines BULK COLLECT INTO
              l_sync_trx_lines_t;
           CLOSE c_trx_lines;
        END IF;

        /* Now call the API to synchronize the repository */
        ZX_API_PUB.synchronize_tax_repository(
          p_api_version        => 1.0,
          p_init_msg_list      => FND_API.G_FALSE,
          p_commit             => FND_API.G_FALSE,
          p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
          x_return_status      => l_return_status,
          x_msg_count          => l_message_count,
          x_msg_data           => l_message_data,
          p_sync_trx_rec       => l_sync_trx_rec,
          p_sync_trx_lines_tbl => l_sync_trx_lines_t
        ); 

        /* If a problem arises with synchronization, document it */
        IF l_return_status = FND_API.G_RET_STS_SUCCESS
        THEN
           IF PG_DEBUG in ('Y', 'C') THEN
              debug('sychronize_tax returns successfully');
           END IF;
           p_return_status := 0; 
        ELSIF l_return_status = FND_API.G_RET_STS_ERROR
        THEN
           IF PG_DEBUG in ('Y', 'C') THEN
              debug('synchronize_tax returns with validation errors');
           END IF;
           p_return_status := 1; 
        ELSE /* fatal error */
           p_return_status := 2;
           IF PG_DEBUG in ('Y', 'C') THEN
              debug('synchronize_tax returns failure');
           END IF; 

           /* Retrieve and log errors */
           IF l_message_count = 1 
           THEN
              debug(l_message_data);
           ELSIF l_message_count > 1 
           THEN   
              LOOP
                 l_msg := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT, 
                                          FND_API.G_FALSE);
                 IF l_msg IS NULL
                 THEN
                    EXIT;
                 ELSE
                    debug(l_msg);
                 END IF; 
              END LOOP;
           END IF;
        END IF;
       END IF;
      CLOSE c_trx;

   ELSIF p_request_id IS NOT NULL
   THEN

        /* 8401487 - preserve values in columns that are not
           directly used by AR */
        l_sync_trx_rec.supplier_tax_invoice_number :=  FND_API.G_MISS_CHAR;
        l_sync_trx_rec.supplier_tax_invoice_date   :=  FND_API.G_MISS_DATE;
        l_sync_trx_rec.supplier_exchange_rate      :=  FND_API.G_MISS_NUM;
        l_sync_trx_rec.tax_invoice_date            :=  FND_API.G_MISS_DATE;
        l_sync_trx_rec.tax_invoice_number          :=  FND_API.G_MISS_CHAR;
        l_sync_trx_rec.port_of_entry_code          :=  FND_API.G_MISS_CHAR;
        l_sync_trx_rec.application_doc_status      :=  FND_API.G_MISS_CHAR;

      FOR trx IN c_req(p_request_id) LOOP
        
        /* move columns from cursor to record */
        l_sync_trx_rec.event_class_code               := trx.event_class;
        l_sync_trx_rec.event_type_code                := trx.event_type;
        l_sync_trx_rec.trx_id                         := trx.customer_trx_id;
        l_sync_trx_rec.trx_number                     := trx.trx_number;
        l_sync_trx_rec.trx_description                := trx.description;
        l_sync_trx_rec.doc_seq_id                     := trx.doc_sequence_id;
        l_sync_trx_rec.doc_seq_name                   := trx.doc_seq_name;
        l_sync_trx_rec.doc_seq_value                  := trx.doc_sequence_value;
        l_sync_trx_rec.batch_source_id                := trx.batch_source_id;
        l_sync_trx_rec.batch_source_name              := trx.batch_source_name;
        l_sync_trx_rec.trx_type_description           := trx.trx_type_name;
        l_sync_trx_rec.trx_communicated_date          := trx.printing_original_date;
        l_sync_trx_rec.trx_due_date                   := trx.term_due_date;

        IF PG_DEBUG in ('Y', 'C') 
        THEN
          debug('event_class_code: '||l_sync_trx_rec.event_class_code);
          debug('event_type_code: '||l_sync_trx_rec.event_type_code);
          debug('trx_id: '||l_sync_trx_rec.trx_id);
          debug('trx_number: '||l_sync_trx_rec.trx_number);
          debug('trx_description: '||l_sync_trx_rec.trx_description);
          debug('doc_seq_id: '||l_sync_trx_rec.doc_seq_id);
          debug('doc_seq_name: '||l_sync_trx_rec.doc_seq_name);
          debug('doc_seq_value: '||l_sync_trx_rec.doc_seq_value);
          debug('batch_source_id: '||l_sync_trx_rec.batch_source_id);
          debug('batch_source_name: '||l_sync_trx_rec.batch_source_name);
          debug('trx_type_description: '||l_sync_trx_rec.trx_type_description);
          debug('trx_communicated_date: '||l_sync_trx_rec.trx_communicated_date);
          debug('trx_due_date: '||l_sync_trx_rec.trx_due_date);
        END IF;

        /* Now call the API to synchronize the repository */
        ZX_API_PUB.synchronize_tax_repository(
          p_api_version        => 1.0,
          p_init_msg_list      => FND_API.G_FALSE,
          p_commit             => FND_API.G_FALSE,
          p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
          x_return_status      => l_return_status,
          x_msg_count          => l_message_count,
          x_msg_data           => l_message_data,
          p_sync_trx_rec       => l_sync_trx_rec,
          p_sync_trx_lines_tbl => l_sync_trx_lines_t
        ); 

        /* If a problem arises with synchronization, document it */
        IF l_return_status = FND_API.G_RET_STS_SUCCESS
        THEN
           IF PG_DEBUG in ('Y', 'C') THEN
              debug('sychronize_tax returns successfully');
           END IF; 
           p_return_status := 0;
        ELSIF l_return_status = FND_API.G_RET_STS_ERROR
        THEN
           IF PG_DEBUG in ('Y', 'C') THEN
              debug('synchronize_tax returns with validation errors');
           END IF; 
           p_return_status := 1;
        ELSE /* fatal error */
           p_return_status := 2;
           IF PG_DEBUG in ('Y', 'C') THEN
              debug('synchronize_tax returns failure');
           END IF; 

           /* Retrieve and log errors */
           IF l_message_count = 1 
           THEN
              debug(l_message_data);
           ELSIF l_message_count > 1 
           THEN   
              LOOP
                 l_msg := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT, 
                                          FND_API.G_FALSE);
                 IF l_msg IS NULL
                 THEN
                    EXIT;
                 ELSE
                    debug(l_msg);
                 END IF; 
              END LOOP;
           END IF;
        END IF;

      END LOOP;

   END IF;

   IF PG_DEBUG in ('Y', 'C') 
   THEN
      debug('XX_ARP_ETAX_UTIL.synchronize_for_doc_seq()-');
   END IF;

END synchronize_for_doc_seq;

/*bug 6806843. Removing the procedure synchronize_for_auto_trxnum. Please see
 * the bug for details */
  

/* Internal Helper Procedure for calling zx api */
  PROCEDURE zx_global_document_update(
        p_trx_rec IN OUT NOCOPY ZX_API_PUB.transaction_rec_type)
  IS
    l_return_status VARCHAR2(50);
    l_message_count NUMBER;
    l_message_data  VARCHAR2(2000);
    l_msg           VARCHAR2(2000);

  BEGIN
     IF PG_DEBUG in ('Y', 'C') THEN
        debug('zx_global_document_update called for ' || 
             p_trx_rec.trx_id);
     END IF; 

     /* Now call the API to synchronize the repository */
     ZX_API_PUB.global_document_update(
       p_api_version        => 1.0,
       p_init_msg_list      => FND_API.G_FALSE,
       p_commit             => FND_API.G_FALSE,
       p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
       x_return_status      => l_return_status,
       x_msg_count          => l_message_count,
       x_msg_data           => l_message_data,
       p_transaction_rec    => p_trx_rec
     ); 

     /* If a problem arises with synchronization, document it */
     IF l_return_status = FND_API.G_RET_STS_SUCCESS
     THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           debug('gdu returns successfully');
        END IF; 
     ELSIF l_return_status = FND_API.G_RET_STS_ERROR
     THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           debug('gdu returns with validation errors');
        END IF; 
     ELSE /* fatal error */
        IF PG_DEBUG in ('Y', 'C') THEN
           debug('gdu returns failure');
        END IF; 

        /* Retrieve and log errors */
        IF l_message_count = 1 
        THEN
           debug(l_message_data);
        ELSIF l_message_count > 1 
        THEN   
           LOOP
              l_msg := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT, 
                                       FND_API.G_FALSE);
              IF l_msg IS NULL
              THEN
                 EXIT;
              ELSE
                 debug(l_msg);
              END IF; 
           END LOOP;
        END IF;
     END IF;

  END zx_global_document_update;

/* Public Procedure - notifies etax that we are freezing the transaction.
     Supported Actions:

             PRINT */ 

PROCEDURE global_document_update(p_customer_trx_id IN NUMBER,
                                 p_request_id      IN NUMBER,
                                 p_action          IN VARCHAR2)
IS
  l_return_status VARCHAR2(50);
  l_message_count NUMBER;
  l_message_data  VARCHAR2(2000);
  l_msg           VARCHAR2(2000);

  l_trx_rec        ZX_API_PUB.transaction_rec_type; 

  CURSOR batch_trx(p_request_id NUMBER) IS
      SELECT t.customer_trx_id customer_trx_id,  
        DECODE(tt.type, 
            'INV', 'INVOICE',
            'DM',  'DEBIT_MEMO',
            'CM',  'CREDIT_MEMO') event_class,
        tt.type                   event_prefix 
      FROM    ra_customer_trx t,
              ra_cust_trx_types tt
      WHERE   t.request_id = p_request_id
      AND     t.cust_trx_type_id = tt.cust_trx_type_id;
    
BEGIN
   IF PG_DEBUG in ('Y', 'C') 
   THEN
      debug('XX_ARP_ETAX_UTIL.global_document_update()+');
      debug('   trx_id = ' || p_customer_trx_id);
      debug('   req_id = ' || p_request_id);
      debug('   action = ' || p_action);
   END IF;

     l_trx_rec.internal_organization_id       := arp_global.sysparam.org_id;
     l_trx_rec.application_id                 := 222;
     l_trx_rec.entity_code                    := 'TRANSACTIONS';

   IF p_customer_trx_id IS NOT NULL
   THEN

      /* set event_class based on trx type */
      SELECT t.customer_trx_id,  
        DECODE(tt.type, 
            'INV', 'INVOICE',
            'DM',  'DEBIT_MEMO',
            'CM',  'CREDIT_MEMO'),
        tt.type || '_' || p_action
      INTO    l_trx_rec.trx_id,  
              l_trx_rec.event_class_code,
              l_trx_rec.event_type_code
      FROM    ra_customer_trx t,
              ra_cust_trx_types tt
      WHERE   t.customer_trx_id = p_customer_trx_id
      AND     t.cust_trx_type_id = tt.cust_trx_type_id;

      zx_global_document_update(l_trx_rec);

   ELSIF p_request_id IS NOT NULL
   THEN

     FOR c_trx IN batch_trx(p_request_id) LOOP

       l_trx_rec.trx_id           := c_trx.customer_trx_id;
       l_trx_rec.event_class_code := c_trx.event_class;
       l_trx_rec.event_type_code  := c_trx.event_prefix || '_' || p_action;

       zx_global_document_update(l_trx_rec);

     END LOOP;

   END IF;        

   IF PG_DEBUG in ('Y', 'C') 
   THEN
      debug('XX_ARP_ETAX_UTIL.global_document_update()-');
   END IF;
END global_document_update;

/*=======================================================================
 | 
 | PROCEDURE
 |    get_default_tax_classification 
 |
 | DESCRIPTION
 |    This routine will call the Etax Api: get_default_Tax_classification
 |    and will return just a tax classification code.   This will replace
 |    the 11i get_default_tax_code calls (which returned tax code,
 |    tax override flag, tax code id, tax type and description)
 |
 | 
 | ARGUMENTS  :   IN
 |                  p_ship_to_site_use_id  (line, header or null)
 |                  p_bill_to_site_use_id  (Header level)
 |                  p_inv_item_id
 |                  p_org_id
 |                  p_sob_id
 |                  p_trx_date
 |                  p_trx_type_id
 |                  p_memo_line_id
 |                  p_salesrep_id
 |                  p_warehouse_id
 |                  p_customer_id
 |                  p_cust_trx_id
 |                  p_cust_trx_line_id
 |                  p_func_short_name (ACCT_RULES, ACCT_DIST, GL_ACCT_FIXUP,
 |                                     GL_ACCT_FIRST)
 |            :   OUT
 |                  tax_classification_code
 |                                              
 | NOTES:
 |
 |  MODIFICATION HISTORY:
 |
 | 03/07/05	Debbie Sue Jancis	Created
 |
 +========================================================================*/
PROCEDURE get_default_tax_classification( 
              p_ship_to_site_use_id        IN     NUMBER DEFAULT NULL,
              p_bill_to_site_use_id        IN     NUMBER DEFAULT NULL,
              p_inv_item_id                IN     NUMBER DEFAULT NULL,
              p_org_id                     IN     NUMBER,
              p_sob_id                     IN     NUMBER,
              p_trx_date                   IN     DATE,
              p_trx_type_id                IN     NUMBER,
              p_cust_trx_id                IN     NUMBER,
              p_cust_trx_line_id           IN     NUMBER DEFAULT NULL,
              p_customer_id                IN     NUMBER DEFAULT NULL,
              p_memo_line_id               IN     NUMBER DEFAULT NULL,
              p_salesrep_id                IN     NUMBER DEFAULT NULL,
              p_warehouse_id               IN     NUMBER DEFAULT NULL,
              p_entity_code                IN     VARCHAR2,
              p_event_class_code           IN     VARCHAR2,
              p_function_short_name        IN     VARCHAR2,
              p_tax_classification_code    OUT    NOCOPY VARCHAR2  ) IS

  l_ccid         ra_cust_trx_line_gl_dist_all.code_combination_id%type;
  l_concat_segments  VARCHAR2(2000);
  l_fail_count   NUMBER;
BEGIN
    debug('XX_ARP_ETAX_UTILs.get_default_tax_classification()+');

    /* 4928047 - Call autoaccounting to get the ccid first, then
       feed it to zx */
         ARP_AUTO_ACCOUNTING.do_autoaccounting(
                   'G'
                  ,'REV'
                  ,p_cust_trx_id
                  ,NULL
                  ,NULL
                  ,NULL
                  ,p_trx_date
                  ,NULL
                  ,NULL
                  ,NULL
                  ,NULL
                  ,p_trx_type_id
                  ,p_salesrep_id
                  ,p_inv_item_id
                  ,p_memo_line_id
		  ,p_warehouse_id
                  ,l_ccid
                  ,l_concat_segments
                  ,l_fail_count); 

    IF l_ccid = -1
    THEN
       debug('Unable to fetch ccid');
       l_ccid := NULL;
    END IF;
    
    zx_ar_tax_classificatn_def_pkg.get_default_tax_classification(
              p_ship_to_site_use_id => p_ship_to_site_use_id,
              p_bill_to_site_use_id => p_bill_to_site_use_id,
              p_inventory_item_id => p_inv_item_id,
              p_organization_id => p_warehouse_id,
              p_set_of_books_id => p_sob_id,
              p_trx_date => p_trx_date,
              p_trx_type_id => p_trx_type_id,
              p_cust_trx_id => p_cust_trx_id,
              p_cust_trx_line_id => p_cust_trx_line_id,
              p_customer_id => p_customer_id,
              p_memo_line_id => p_memo_line_id,
              APPL_SHORT_NAME => 'AR',
              FUNC_SHORT_NAME => p_function_short_name,
              p_entity_code => p_entity_code,
              p_event_class_code => p_event_class_code,
              p_application_id => 222,
              p_internal_organization_id => p_org_id,
              p_ccid => l_ccid,
              p_tax_classification_code => p_tax_classification_code);

    debug('XX_ARP_ETAX_UTIL.get_default_tax_classification()-)');    

END get_default_tax_classification;

/*=======================================================================
 | 
 | PROCEDURE
 |    set_default_tax_classification 
 |
 | DESCRIPTION
 |    This routine copies the tax_classification back from
 |    zx_lines to the corresponding LINE row in ra_customer_trx_lines. 
 |
 | 
 | ARGUMENTS  :   IN
 |                  p_request_id IN NUMBER
 |                  p_phase      IN VARCHAR2 DEFAULT 'INV'
 |            :   OUT
 |                  
 |                                              
 | NOTES:
 |
 |  MODIFICATION HISTORY:
 |
 | 01/06/06	MRAYMOND	Created
 |
 +========================================================================*/
PROCEDURE set_default_tax_classification(p_request_id IN NUMBER,
                                         p_phase      IN VARCHAR2 DEFAULT 'INV')
IS

  t_line_id     l_line_id_type;
  t_class_code  l_tax_classif_type;

  l_rows_needing_update  NUMBER;
  l_rows_updated         NUMBER;

  CURSOR line_to_tax_class(p_request_id NUMBER, p_phase VARCHAR2) IS
     select 	/*+ index (tl RA_CUSTOMER_TRX_LINES_N4) */ 
             tl.customer_trx_line_id,
             nvl(tl.tax_classification_code, zx.output_tax_classification_code)
     from    ra_customer_trx       t,
             ra_customer_trx_lines tl,
             zx_lines_det_factors  zx
     where   t.request_id = p_request_id
     and     t.customer_trx_id = tl.customer_trx_id
     and     tl.line_type = 'LINE'
     and     tl.request_id = p_request_id 
     and     NVL(t.previous_customer_trx_id, -99) =
             DECODE(p_phase, 'INV', -99, t.previous_customer_trx_id)
     and     zx.application_id = 222
     and     zx.entity_code = 'TRANSACTIONS'
     and     zx.event_class_code in ('INVOICE','DEBIT_MEMO','CREDIT_MEMO')
     and     zx.trx_id = tl.customer_trx_id
     and     zx.trx_level_type = 'LINE'
     and     zx.trx_line_id = tl.customer_trx_line_id;

BEGIN
  IF PG_DEBUG = 'Y' THEN
  	debug( 'XX_ARP_ETAX_UTIL.set_default_tax_classification()+' );
  END IF;

      OPEN line_to_tax_class(p_request_id, p_phase);
      FETCH line_to_tax_class BULK COLLECT INTO
             t_line_id,
             t_class_code;

      l_rows_needing_update := line_to_tax_class%ROWCOUNT;

      IF l_rows_needing_update > 0
      THEN
        FORALL i IN t_line_id.FIRST..t_line_id.LAST
          UPDATE ra_customer_trx_lines
          SET    tax_classification_code = t_class_code(i)
          WHERE  customer_trx_line_id = t_line_id(i);
      END IF;

      l_rows_updated := SQL%ROWCOUNT;

  IF PG_DEBUG = 'Y' THEN
        debug( '  rows found   : ' || l_rows_needing_update); 
        debug( '  rows updated : ' || l_rows_updated);
  	debug( 'XX_ARP_ETAX_UTIL.set_default_tax_classification()-' );
  END IF;

END; 

FUNCTION get_event_information (p_customer_trx_id IN NUMBER,
                                p_action IN VARCHAR2,
                                p_event_class_code OUT NOCOPY VARCHAR2,
                                p_event_type_code OUT NOCOPY VARCHAR2)
RETURN BOOLEAN  IS

   l_trx_class  RA_CUST_TRX_TYPES.TYPE%TYPE;
   l_return_var                 BOOLEAN := TRUE;

BEGIN

  IF PG_DEBUG = 'Y' THEN
    debug('XX_ARP_ETAX_UTIL.get_event_information()+)');
  END IF;

  BEGIN 

    Select type.type
     into l_trx_class
    from  ra_customer_trx trx,
          ra_cust_trx_types type
    where trx.customer_trx_id = p_customer_trx_id
    and   trx.cust_trx_type_id = type.cust_Trx_type_id;


    IF PG_DEBUG = 'Y' THEN
      debug('TRX_TYPE for customer_trx_id ' || p_customer_trx_id || 
         ' is ' || l_trx_class);
    END IF;

  EXCEPTION
   WHEN OTHERS THEN
     IF PG_DEBUG = 'Y' THEN
       debug('EXCEPTION occured while getting trx_type: ' || 
           sqlcode || ', ' || sqlerrm);
     END IF;
  END;

    IF (l_trx_class = 'INV') THEN
        p_event_class_code := 'INVOICE';
    ELSIF (l_trx_class = 'DM') THEN
       p_event_class_code := 'DEBIT_MEMO';
    ELSIF (l_trx_class = 'CM') THEN
       p_event_class_code := 'CREDIT_MEMO';
    ELSE
       -- Event Class code is null so the function will return false because
       -- eTax is not defined to be called for this Type
       p_event_class_code := NULL;
       p_event_type_code := NULL;
       RETURN FALSE;
    END IF;

   p_event_type_code := l_trx_class || '_' || p_action;  

   IF PG_DEBUG = 'Y' THEN
      debug('TRX_CLASS = ' || l_trx_class || ', TRX_CLASS_CODE = ' || 
           p_event_class_code || ', P_EVENT_TYPE_CODE = ' || 
           p_event_type_code); 
      debug('XX_ARP_ETAX_UTIL.get_event_information()-)');    
   END IF;    

  RETURN l_return_var;

END get_event_information;

/* Pulled from arp_tax_compound verbatum.  Need to support same logic
   but wanted to get away from dependency to old tax logic */
FUNCTION tax_curr_round( p_amount  	     IN NUMBER,
			 p_trx_currency_code IN VARCHAR2 default null,
			 p_precision 	     IN NUMBER,
			 p_min_acct_unit     IN NUMBER,
			 p_rounding_rule     IN VARCHAR2 default 'NEAREST',
			 p_autotax_flag      IN VARCHAR2 default 'Y' )

                 RETURN NUMBER IS

  l_rounded_amount	NUMBER;
  l_precision           NUMBER;
  l_rounding_rule       VARCHAR2(30);
  l_min_acct_unit       NUMBER;
  l_round_adj		NUMBER;

BEGIN
  IF PG_DEBUG = 'Y' THEN
  	debug( 'XX_ARP_ETAX_UTIL.tax_curr_round(' || p_amount || ')+' );
  END IF;

  l_rounding_rule := p_rounding_rule;

  if p_trx_currency_code = arp_standard.sysparm.tax_currency_code and p_autotax_flag in ( 'Y','U')
  THEN

     l_precision := least( p_precision, nvl(arp_standard.sysparm.tax_precision, p_precision) );
     l_min_acct_unit := greatest( nvl(p_min_acct_unit, arp_standard.sysparm.tax_minimum_accountable_unit),
				  nvl(arp_standard.sysparm.tax_minimum_accountable_unit, p_min_acct_unit));

  ELSE

     l_precision := p_precision;
     l_min_acct_unit := p_min_acct_unit;

  END IF;

IF PG_DEBUG = 'Y' THEN
	debug(' trx currency  = :'||p_trx_currency_code||':');
	debug(' sys currency  = :'||arp_standard.sysparm.tax_currency_code||':');
	debug(' autotax       = :'||p_autotax_flag||':');
	debug(' rounding rule = :'||l_rounding_rule||':');
	debug(' precision     = :'||l_precision||':');
	debug(' mau           = :'||l_min_acct_unit||':');
END IF;

  IF ( nvl(l_min_acct_unit,0) <> 0 )
  THEN

     IF nvl(l_rounding_rule, 'NEAREST' ) = 'UP'
     THEN
	 --
	 -- Round the amount Up to next Min Accountable Unit
	 --
         l_rounded_amount := sign(p_amount)* (CEIL(abs(p_amount) / l_min_acct_unit) * l_min_acct_unit);

     ELSIF nvl(l_rounding_rule, 'NEAREST' ) = 'DOWN'
     THEN

	 --
	 -- Round the amount Down to the prior Min Accountable Unit
	 --
         l_rounded_amount := TRUNC(p_amount/l_min_acct_unit) * l_min_acct_unit;

     ELSE /* ROUND NEAREST BY DEFAULT */

	 --
	 -- Round the amount to the nearest Min Accountable Unit
	 --
         l_rounded_amount := ROUND(p_amount / l_min_acct_unit) * l_min_acct_unit;

     END IF;


  ELSE

     --
     -- Minimum Accountable Unit is not specified, use
     -- the precision to control the rounding
     --
     IF nvl(l_rounding_rule, 'NEAREST' ) = 'UP'
     THEN
	 --
	 -- Round the amount Up at the given precision
	 -- Amounts that are already at this precision
	 -- are not changed.
	 --
	 IF p_amount <> trunc(p_amount, l_precision)
	 THEN
             l_rounded_amount := ROUND( p_amount + (sign( p_amount)*(power( 10, (l_precision*-1))/2)), l_precision );
	 ELSE
	     l_rounded_amount := p_amount;
	 END IF;
     ELSIF nvl(l_rounding_rule, 'NEAREST' ) = 'DOWN'
	 THEN
	 --
	 -- Round the amount Down to the prior precision
	 --
         l_rounded_amount:= TRUNC( p_amount, l_precision );

     ELSE /* Default Nearest */
	 --
	 -- Round the amount to the nearest precision
	 --
         l_rounded_amount := ROUND( p_amount, l_precision );

     END IF;

  END IF;

  IF PG_DEBUG = 'Y' THEN
  	debug( 'arp_tax_compound.tax_curr_round('||l_rounded_amount||')-');
  END IF;
  RETURN (l_rounded_amount);

EXCEPTION
  WHEN OTHERS THEN
      debug( 'EXCEPTION: arp_tax_compound.tax_curr_round(-)');
    RAISE;
END tax_curr_round;

/* init accounting structure */
PROCEDURE init_ae_struct(p_ae_sys_rec IN OUT NOCOPY arp_acct_main.ae_sys_rec_type)

IS
BEGIN
  SELECT sob.set_of_books_id,
         sob.chart_of_accounts_id,
         sob.currency_code,
         c.precision,
         c.minimum_accountable_unit,
         sysp.code_combination_id_gain,
         sysp.code_combination_id_loss,
         sysp.code_combination_id_round
  INTO   p_ae_sys_rec.set_of_books_id,
         p_ae_sys_rec.coa_id, 
         p_ae_sys_rec.base_currency,
         p_ae_sys_rec.base_precision,
         p_ae_sys_rec.base_min_acc_unit,  
         p_ae_sys_rec.gain_cc_id,
         p_ae_sys_rec.loss_cc_id,
         p_ae_sys_rec.round_cc_id
  FROM   ar_system_parameters sysp,
         gl_sets_of_books sob,
         fnd_currencies c
  WHERE  sob.set_of_books_id = sysp.set_of_books_id  
  AND    sob.currency_code   = c.currency_code;
END;

/* Internal procedure for prorating the accounting entires
    associated with adjustments or discounts */

/* Dev Note:  I debated adding the line_id to this call - but 
   I dont think it is necessary.  These routines only process the 
   lines that are present in zx_lines for the given adjustment.  There
   is no expectation that the same adj would be processed more than once.
*/

/* 4607809 - The call to arp_det_dist_pkg requires that the RA row
     be present.  However, in many cases, receipts do not have
     application rows when this is called.  To facilitate that,
     I am removing the call from here and creating a new (separate)
     public function that can be called near ARP_ACCT_MAIN calls 
*/

/* 5677984 - Add p_ra_app_id parameter.  For receipt UNAPPLY, we call
   with the same parameters as an APPLY and get a duplicate set of dists
   because the sql returns both APP and UNAPP ones.  Using the p_ra_app_id
   (passed as APP or UNAPP application row, allows us to limit returns
   to only the current APP or UNAPP row. */

--  Added parameter for line level adjustment ER.
PROCEDURE prorate_accounting(p_transaction_rec IN zx_api_pub.transaction_rec_type,
                             p_mode            IN VARCHAR2,
                             p_ra_app_id       IN NUMBER,
                             p_gt_id           IN OUT NOCOPY number,
			     p_from_llca_call  IN varchar2 DEFAULT 'N',
			     p_target_line_id  IN ra_customer_trx_lines.customer_trx_line_id%TYPE DEFAULT NULL)
IS
    l_gt_id  NUMBER;
    l_return_status_service  VARCHAR2(4000);
    l_msg_count              NUMBER;
    l_msg_data               VARCHAR2(4000);
    l_msg                    VARCHAR2(2000);
    l_mode                   VARCHAR2(20);
    l_adj_rec                ar_adjustments%ROWTYPE;
    l_trx_rec                ra_customer_trx%ROWTYPE;
    l_app_rec                ar_receivable_applications%ROWTYPE;
    l_rows_inserted          NUMBER;
    l_acct_meth              ar_system_parameters.accounting_method%TYPE;
    l_ae_sys_rec             arp_acct_main.ae_sys_rec_type;
    l_gt_passed              BOOLEAN := FALSE;

    -- Added for Line Level Adjustment
   l_from_llca_call	    VARCHAR2(1);

    CURSOR debug_gt IS
       SELECT gt_id,
              source_id,
              source_table,
              customer_trx_id,
              customer_trx_line_id,
              line_type,
              line_amount,
              ed_line_amount,
              uned_line_amount,
              tax_amount,
              ed_tax_amount,
              uned_tax_amount
       FROM   AR_LINE_DIST_INTERFACE_GT;
    

BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_etax_util.prorate_accounting()+');
      arp_util.debug('   p_mode             = ' || p_mode);
      arp_util.debug('   p_trans_rec.trx_id = ' || p_transaction_rec.trx_id);
      arp_util.debug('   p_ra_app_id        = ' || p_ra_app_id);
      arp_util.debug('   p_from_llca_call   = ' || p_from_llca_call);
      arp_util.debug('   p_target_line_id   = ' || p_target_line_id);
   END IF;
 

  -- Added for Line Level Adjustment
   l_from_llca_call	  := p_from_llca_call;

         /* set local mode variable for use in sql */
         IF p_mode in ('INV','LINE','TAX')
         THEN
            l_mode := 'ADJUST';
         ELSIF p_mode in ('APP_ED','UNAPP_ED')
         THEN
            l_mode := 'EDISC';
         ELSE
            l_mode := 'UNEDISC';
         END IF;

   IF PG_DEBUG in ('Y','C') THEN
      arp_util.debug('  local mode = ' || l_mode);
   END IF; 

         IF NVL(p_gt_id,0) = 0
         THEN 
           /* Get sequence for line level distributions API */
           arp_det_dist_pkg.get_gt_sequence
            (l_gt_id,
             l_return_status_service,
             l_msg_count,
             l_msg_data);

           p_gt_id := l_gt_id;
         ELSE
           l_gt_passed := TRUE; -- don't allow it to get nulled in this 
                                -- program.
           l_gt_id := p_gt_id;
         END IF;

         IF PG_DEBUG in ('Y','C') THEN
            arp_util.debug('l_gt_id = ' || l_gt_id);
         END IF;

         /* Insert tax lines into _GT table for processing */

         /* Dev Note:  Discounts are calculated as negative amounts
            in etax because they are decreasing the tax liability.
            However, for proration purposes, the allocation code
            expects them to be positive values.  As such, we
            have to reverse the sign of the amount(s) from ZX
            specifically for discounts.  Adjustments are already
            in the correct sign (same sign for AR and ZX) */

         INSERT INTO AR_LINE_DIST_INTERFACE_GT
         (  GT_ID,
            SOURCE_ID,
            SOURCE_TABLE,
            CUSTOMER_TRX_ID,
            CUSTOMER_TRX_LINE_ID,
            LINE_TYPE,
            TAX_AMOUNT,
            ED_TAX_AMOUNT,
            UNED_TAX_AMOUNT)
         (SELECT   
            l_gt_id,
            zx.trx_id,
            DECODE(l_mode,     'ADJUST' ,'ADJ',
                               'UNEDISC','RA',
                               'EDISC'  ,'RA'),
            tl.customer_trx_id,
            tl.customer_trx_line_id,
            'TAX',
            DECODE(l_mode,     'ADJUST', zx.tax_amt, NULL),
            DECODE(l_mode,     'EDISC',  zx.tax_amt, NULL),
            DECODE(l_mode,     'UNEDISC',zx.tax_amt, NULL)
          FROM
            zx_lines zx,
            ra_customer_trx_lines tl
          WHERE
              zx.application_id   = p_transaction_rec.application_id 
          AND zx.entity_code      = p_transaction_rec.entity_code
          AND zx.event_class_code = p_transaction_rec.event_class_code
          AND zx.trx_id           = p_transaction_rec.trx_id
          AND zx.trx_level_type   =
               DECODE(l_mode, 'EDISC','LINE_EARNED',
                              'UNEDISC','LINE_UNEARNED',
                              'LINE')
--          AND zx.trx_line_id      = NVL(p_ra_app_id, zx.trx_line_id)
          AND tl.link_to_cust_trx_line_id = zx.adjusted_doc_line_id 
          AND tl.line_type = 'TAX'
          AND tl.tax_line_id = zx.adjusted_doc_tax_line_id);

          l_rows_inserted := SQL%ROWCOUNT;
       
          arp_util.debug('tax lines inserted = ' || l_rows_inserted);

         /* Only insert LINEs if it is not a tax-only adj */
         IF p_mode <> 'TAX'
         THEN

/* Insert line amounts */  
            INSERT INTO AR_LINE_DIST_INTERFACE_GT
            (  GT_ID,
               SOURCE_ID,
               SOURCE_TABLE,
               CUSTOMER_TRX_ID,
               CUSTOMER_TRX_LINE_ID,
               LINE_TYPE,
               LINE_AMOUNT,
               ED_LINE_AMOUNT,
               UNED_LINE_AMOUNT)
            (SELECT   
               l_gt_id,
               zx.trx_id,
               DECODE(l_mode, 'ADJUST' ,'ADJ',
                              'UNEDISC','RA',
                              'EDISC'  ,'RA'),
               il.customer_trx_id,
               il.customer_trx_line_id,
               'LINE',
               DECODE(l_mode, 'ADJUST', max(zx.line_amt) - 
                                   sum(zx.tax_amt), NULL),
               DECODE(l_mode, 'EDISC',max(zx.line_amt) - 
                                   sum(zx.tax_amt), NULL),
               DECODE(l_mode, 'UNEDISC',max(zx.line_amt) -
                                   sum(zx.tax_amt), NULL) 
             FROM
               zx_lines zx,
               ra_customer_trx_lines il
             WHERE
                 zx.application_id   = p_transaction_rec.application_id 
             AND zx.entity_code      = p_transaction_rec.entity_code
             AND zx.event_class_code = p_transaction_rec.event_class_code
             AND zx.trx_id           = p_transaction_rec.trx_id
             AND il.customer_trx_id  = zx.adjusted_doc_trx_id
             AND il.customer_trx_line_id = zx.adjusted_doc_line_id 
             AND il.line_type = 'LINE'
             GROUP BY zx.trx_id, zx.adjusted_doc_line_id,
                      il.customer_trx_id, il.customer_trx_line_id);

             l_rows_inserted := l_rows_inserted + SQL%ROWCOUNT;
             arp_util.debug('Total line and tax rows inserted = ' || 
                      l_rows_inserted);

         END IF; 

         /* Check total rows inserted.. if none, set p_gt_id to zero
            and exit */
         IF l_rows_inserted = 0
         THEN
            IF l_gt_passed
            THEN
              /* gt_id was passed into this program from a prior
                 call.  Do not null it here as there are other
                 accounting entries using it */
              NULL;
            ELSE 
              /* set gt_id to zero so we don't use
                 it later */
              p_gt_id := 0;
            END IF;
            RETURN;
         ELSE
            /* Displays content of GT table.  This was necessary
               because the GT table was doing some strange things
               in the early days of SLA */  
            IF PG_DEBUG in ('Y', 'C') THEN
             FOR d IN debug_gt LOOP
               arp_util.debug(d.customer_trx_id || '~' ||
                              d.customer_trx_line_id || '~' ||
                              d.line_type || ' line=' ||
                              d.line_amount || ' ed_line=' ||
                              d.ed_line_amount || ' uned_line=' ||
                              d.uned_line_amount || ' tax=' ||
                              d.tax_amount || ' ed_tax=' ||
                              d.ed_tax_amount || ' uned_tax=' ||
                              d.uned_tax_amount);
             END LOOP;
            END IF;     
            /* End debug code */
         END IF;

         /* Set up various parameter records */
         IF l_mode = 'ADJUST'
         THEN
            SELECT *
            INTO   l_adj_rec
            FROM   ar_adjustments
            WHERE  adjustment_id   = p_transaction_rec.trx_id;

            SELECT *
            INTO   l_trx_rec
            FROM   ra_customer_trx
            WHERE  customer_trx_id = l_adj_rec.customer_trx_id;

            /* Now initialize the acct engine and
               call the distribution routine (adjustments) */
            init_ae_struct(l_ae_sys_rec);  

            arp_det_dist_pkg.adjustment_with_interface(
              p_customer_trx => l_trx_rec,
              p_adj_rec      => l_adj_rec,
              p_ae_sys_rec   => l_ae_sys_rec,
              p_gt_id        => l_gt_id,
              p_line_flag    => 'INTERFACE',
              p_tax_flag     => 'INTERFACE',
              x_return_status=> l_return_status_service,
              x_msg_count    => l_msg_count,
              x_msg_data     => l_msg_data,
	      p_llca_from_call => l_from_llca_call,
	      p_customer_trx_line_id => p_target_line_id);

         ELSIF l_mode in ('EDISC', 'UNEDISC') 
         THEN
            /* Call arp_det_dist_pkg later by
               calling distribute_recoverable */
            IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Discount accounting skipped');
                arp_util.debug('  see distribute_recoverable later in log');
            END IF;

         ELSE
           arp_util.debug('EXCEPTION:  Invalid mode.  ' || l_mode);
           p_gt_id := 0;
           RETURN;
         END IF;

         /* Check for errors */
         IF l_return_status_service <> FND_API.G_RET_STS_SUCCESS THEN

           /* Retrieve and log errors */
           IF l_msg_count = 1 
           THEN
              debug(l_msg_data);
              p_gt_id := 0;
           ELSIF l_msg_count > 1 
           THEN   
              LOOP
                 l_msg := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT, 
                                          FND_API.G_FALSE);
                 IF l_msg IS NULL
                 THEN
                    EXIT;
                 ELSE
                    debug(l_msg);
                 END IF; 
              END LOOP;
              p_gt_id := 0;
           END IF;
         END IF;

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_etax_util.prorate_accounting()-');
   END IF;

END prorate_accounting;

PROCEDURE distribute_recoverable(p_rec_app_id  IN NUMBER,
                                 p_gt_id       IN NUMBER)
IS
    l_return_status_service  VARCHAR2(4000);
    l_msg_count              NUMBER;
    l_msg_data               VARCHAR2(4000);
    l_msg                    VARCHAR2(2000);
    l_trx_rec                ra_customer_trx%ROWTYPE;
    l_app_rec                ar_receivable_applications%ROWTYPE;
    l_acct_meth              ar_system_parameters.accounting_method%TYPE;
    l_ae_sys_rec             arp_acct_main.ae_sys_rec_type;

BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_etax_util.distribute_recoverable()+');
      arp_util.debug('   p_rec_app_id = ' || p_rec_app_id);
   END IF;
 
            SELECT *
            INTO   l_app_rec
            FROM   ar_receivable_applications
            WHERE  receivable_application_id   = p_rec_app_id;

            SELECT *
            INTO   l_trx_rec
            FROM   ra_customer_trx
            WHERE  customer_trx_id = l_app_rec.applied_customer_trx_id;

            init_ae_struct(l_ae_sys_rec); 

            /* Now call the distribution routine (receipts) */
            /* 5159129 Added p_line_flag and p_tax_flag for discounts */
            /* 5677984 Added p_uned* parameters so this handles
                unearned discounts properly */
            arp_det_dist_pkg.application_with_interface(
              p_customer_trx => l_trx_rec,
              p_app_rec      => l_app_rec,
              p_ae_sys_rec   => l_ae_sys_rec,
              p_gt_id        => p_gt_id,
              p_line_flag    => 'NORMAL',
              p_tax_flag     => 'NORMAL',
              p_ed_line_flag => 'INTERFACE',
              p_ed_tax_flag  => 'INTERFACE',
              p_uned_line_flag => 'INTERFACE',
              p_uned_tax_flag =>  'INTERFACE',
              x_return_status=> l_return_status_service,
              x_msg_count    => l_msg_count,
              x_msg_data     => l_msg_data);

         /* Check for errors */
         IF l_return_status_service <> FND_API.G_RET_STS_SUCCESS THEN

           /* Retrieve and log errors */
           IF l_msg_count = 1 
           THEN
              debug(l_msg_data);
           ELSIF l_msg_count > 1 
           THEN   
              LOOP
                 l_msg := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT, 
                                          FND_API.G_FALSE);
                 IF l_msg IS NULL
                 THEN
                    EXIT;
                 ELSE
                    debug(l_msg);
                 END IF; 
              END LOOP;
           END IF;
         END IF;

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_etax_util.distribute_recoverable()-');
   END IF;

END distribute_recoverable;


/* Procedure for updating adjustment and PS rows in cases where the
   originals were inserted before the etax call.  Supports the following
   values:

     Y - update both
     A - update adjustments only
     N - update neither
*/

PROCEDURE update_adj_and_ps(
                              p_upd_adj_and_ps IN VARCHAR2,
                              p_adj_id         IN NUMBER,
                              p_prorated_line  IN NUMBER,
                              p_prorated_tax   IN NUMBER)
IS
   l_adj_rec      ar_adjustments%ROWTYPE;
   l_ps_rec       ar_payment_schedules%ROWTYPE;
   l_orig_line_adj  NUMBER := 0;
   l_orig_tax_adj   NUMBER := 0;
   l_ps_update_needed BOOLEAN := TRUE;
BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_etax_util.update_adj_and_ps()+');
      arp_util.debug('    p_upd_adj_and_ps = ' || p_upd_adj_and_ps);
      arp_util.debug('    p_prorated_line  = ' || p_prorated_line);
      arp_util.debug('    p_prorated_tax   = ' || p_prorated_tax);
   END IF;

   IF p_upd_adj_and_ps in ('Y','A')
   THEN
      /* get original adjustment amounts */
      SELECT nvl(line_adjusted,0), 
             nvl(tax_adjusted,0)
      INTO   l_orig_line_adj,
             l_orig_tax_adj
      FROM   ar_adjustments
      WHERE  adjustment_id = p_adj_id;

      /* if the original and new amounts are 
         different, update adjustment here */
      IF l_orig_line_adj <> p_prorated_line OR
         l_orig_tax_adj <> p_prorated_tax
      THEN

         /* update adjustment manually */
         UPDATE ar_adjustments
         SET    line_adjusted = p_prorated_line,
                tax_adjusted  = p_prorated_tax
         WHERE  adjustment_id = p_adj_id;
      ELSE
         /* the new and original adj amounts
            are equal, set bool so we skip the 
            PS update */
         l_ps_update_needed := FALSE;

         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('  orig and prorate amts same, skip update(s)');
         END IF;
      END IF;
   END IF;

   /* Do the PS update if specified and if
      it is still deemed necessary */
   IF p_upd_adj_and_ps in ('Y','P') AND
      l_ps_update_needed = TRUE
   THEN
 
      /* select adj back from db for PS update
        NOTE:  This includes update line and tax
        from above */
      SELECT *
      INTO   l_adj_rec
      FROM   ar_adjustments
      WHERE  adjustment_id = p_adj_id;

      arp_util.debug('from adj record <in db>');
      arp_util.debug('  line adjusted = ' || l_adj_rec.line_adjusted);
      arp_util.debug('  tax adjusted  = ' || l_adj_rec.tax_adjusted);


         /* Incorporate the original adj line and tax amounts.
            These columns are zero if the adjustment was not changed
            by this routine */
         l_adj_rec.line_adjusted := l_adj_rec.line_adjusted - l_orig_line_adj;
         l_adj_rec.tax_adjusted := l_adj_rec.tax_adjusted - l_orig_tax_adj;

         arp_ps_util.update_adj_related_columns( 
                                    l_adj_rec.payment_schedule_id,
                                    l_adj_rec.type,
                                    l_adj_rec.amount,
                                    null,
                                    l_adj_rec.line_adjusted,
                                    l_adj_rec.tax_adjusted,
                                    l_adj_rec.freight_adjusted,
                                    l_adj_rec.receivables_charges_adjusted,
                                    l_adj_rec.apply_date,
                                    l_adj_rec.gl_date,
                                    l_adj_rec.acctd_amount,
                                    l_ps_rec );

   END IF;
 
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('arp_etax_util.update_adj_and_ps()-');
   END IF;
END update_adj_and_ps;

/* 5677984 redirected original prorate_recoverable to the new
    overloaded version (see next definition)

   Procedure for prorating recoverable and calculating tax.  Making this
   generic so it can be used for adjustments, discounts, and perhaps
   other places as needed */

/* PARAMETERS:
    p_adj_id       ID for adjustment or receivable application
    
    p_target_id    customer_trx_id of target invoice
 
    p_amount       raw adjustment amount (to be allocated)
 
    p_apply_date   date of application or adjustment

    p_mode         LINE    Prorate line and tax (normal line adj mode)
                   TAX     Adjust tax-only
                   INV     Adjust entire transaction
                   APP_ED  Receipt apply (earned discount)
                   APP_UED  Receipt apply (unearned discount)
                   UNAPP_ED   Receipt unapply (earned discount)
                   UNAPP_UED   Receipt unapply (unearned discount)

    p_upd_adj_and_ps  Flag to indicate if we need to do the mainteannce
                      of adj and ps rows for this adjustment
                      Y=update both
                      A=update adj only
                      NULL/N=do nothing

    p_gt_id        ID assigned for proration logic

    p_prorated_line  amount allocated to lines

    p_prorated_tax   amount allocated to tax 
*/
PROCEDURE prorate_recoverable(
                              p_adj_id         IN NUMBER,
                              p_target_id      IN NUMBER,
                              p_target_line_id IN NUMBER,
                              p_amount         IN NUMBER,
                              p_apply_date     IN DATE,
                              p_mode           IN VARCHAR2,
                              p_upd_adj_and_ps IN VARCHAR2,
                              p_gt_id          IN OUT NOCOPY NUMBER,
                              p_prorated_line  IN OUT NOCOPY NUMBER,
                              p_prorated_tax   IN OUT NOCOPY NUMBER,
                              p_quote          IN VARCHAR2 DEFAULT 'N')
IS
   l_junk_ra_app_id NUMBER := -1;
BEGIN
   /* call new prorate_recoverable with -1 for receivable_application_id */
     prorate_recoverable(
                              p_adj_id,
                              p_target_id,
                              p_target_line_id,
                              p_amount,
                              p_apply_date,
                              p_mode,
                              p_upd_adj_and_ps,
                              p_gt_id,
                              p_prorated_line,
                              p_prorated_tax,
                              p_quote,
                              l_junk_ra_app_id);

END prorate_recoverable;

/* Procedure for prorating recoverable and calculating tax.  Making this
   generic so it can be used for adjustments, discounts, and perhaps
   other places as needed */

/* PARAMETERS:
    p_adj_id       ID for adjustment or cash_receipt 
    
    p_target_id    customer_trx_id of target invoice

    p_target_line_id  customer_trx_line_id of target invoice
 
    p_amount       raw adjustment amount (to be allocated)
 
    p_apply_date   date of application or adjustment

    p_mode         LINE    Prorate line and tax (normal line adj mode)
                   TAX     Adjust tax-only
                   INV     Adjust entire transaction
                   APP_ED  Receipt apply (earned discount)
                   APP_UED  Receipt apply (unearned discount)
                   UNAPP_ED   Receipt unapply (earned discount)
                   UNAPP_UED   Receipt unapply (unearned discount)

    p_upd_adj_and_ps  Flag to indicate if we need to do the mainteannce
                      of adj and ps rows for this adjustment
                      Y=update both
                      A=update adj only
                      NULL/N=do nothing

    p_gt_id        ID assigned for proration logic

    p_prorated_line  amount allocated to lines

    p_prorated_tax   amount allocated to tax 
 
    p_ra_app_id      the application_id to be used for receipt
              APP and UNAPP activities.  
         If passed in as -1, ignore.
         If passed in as NULL, assign a value.
         If passed as value other than -1, use as is
              
*/
PROCEDURE prorate_recoverable(
                              p_adj_id         IN NUMBER,
                              p_target_id      IN NUMBER,
                              p_target_line_id IN NUMBER,
                              p_amount         IN NUMBER,
                              p_apply_date     IN DATE,
                              p_mode           IN VARCHAR2,
                              p_upd_adj_and_ps IN VARCHAR2,
                              p_gt_id          IN OUT NOCOPY NUMBER,
                              p_prorated_line  IN OUT NOCOPY NUMBER,
                              p_prorated_tax   IN OUT NOCOPY NUMBER,
                              p_quote          IN VARCHAR2 DEFAULT 'N',
                              p_ra_app_id      IN OUT NOCOPY NUMBER)
IS

   l_recov_flag  VARCHAR2(1);
   l_historical_flag VARCHAR2(1);
   l_sum      NUMBER;                   -- divisor for proration logic
   l_row      NUMBER := 0;              -- row counter for inserting 
                                        -- line_det_fact rows
   l_round_target_amt NUMBER := 0;      -- rounding corrections
   l_round_target_line_id NUMBER := NULL;  -- rounding corrections
   l_amount   NUMBER;                   -- working copy of adj/disc amount
   l_tax_amount NUMBER;                 -- for tax_only adj calcs
   l_line_proration  NUMBER;            -- amount prorated to given line
   l_total_proration NUMBER := 0;       -- total prorated for transaction
   l_total_tax_recov NUMBER := 0;       -- tax recoverable for entire trx

   l_transaction_rec        zx_api_pub.transaction_rec_type;
   l_transaction_line_rec   zx_api_pub.transaction_line_rec_type;

   l_return_status_service  VARCHAR2(4000);
   l_msg_count              NUMBER;
   l_msg_data               VARCHAR2(4000);
   l_doc_level_recalc_flag  VARCHAR2(1); 
   l_adj_number             VARCHAR2(30);
   l_rounding_correction    NUMBER;
   l_prorated_tax           NUMBER;
   l_prorated_line          NUMBER;
   l_cust_id                NUMBER;
   l_site_use_id            NUMBER; 
   t_prorated_amt    number_table_type;   -- total prorated adj amount per line

   l_lines_processed        BOOLEAN := FALSE;

   l_adj_ra_id              NUMBER; -- adj_id or ra_app_id
                                    -- depending on whether its an adj or app

 -- Added for Line Level Adjustment ER 
   l_from_llca_call	    VARCHAR2(1);
   
   /* Bug 8512053 */
   l_amt_due_remaining  NUMBER;
   l_ctrl_hdr_tx_appl_flag VARCHAR2(1) DEFAULT 'N';
   l_tax_adjusted NUMBER DEFAULT 0;

/* Added parameter to hold values properly*/

   l_event_exists varchar2(10);

   CURSOR trx_lines(p_trx_id NUMBER, p_trx_line_id NUMBER) IS
   SELECT
      TRX.org_id                       internal_organization_id,
      TRX.customer_trx_id              inv_trx_id,
      TRX.trx_number                   trx_number,
      TRX.invoice_currency_code        trx_currency_code, 
      CUR.precision                    trx_precision,
      CUR.minimum_accountable_unit     trx_mau,
      TRX.exchange_date,
      TRX.exchange_rate,
      TRX.exchange_rate_type,
      TRX.legal_entity_id              legal_entity_id,
      TRX.trx_date                     inv_trx_date,
      DECODE(TT.type,'CM','CREDIT_MEMO',
                     'DM','DEBIT_MEMO',
                          'INVOICE')   trx_event_class, 
      TRX.ship_to_customer_id          trx_ship_to_customer_id,
      TRX.ship_to_site_use_id          trx_ship_to_site_use_id,
      AR.set_of_books_id               ledger_id,
      BILL_CUST.party_id               bill_to_party_id,
      BILL_AS.party_site_id            bill_to_party_site_id,
      BILL_PS.location_id              bill_to_location_id,
      LINES.customer_trx_line_id       inv_trx_line_id,
      LINES.line_number                inv_trx_line_number,
      NVL(LINES.historical_flag,'N')   historical_flag,
      LINES.extended_amount            line_amt,
      LINES.tax_exempt_flag            exemption_control_flag,
      LINES.tax_exempt_number          exempt_certificate_number,
      LINES.tax_exempt_reason_code     exempt_reason,
      DECODE(LINES.memo_line_id, NULL,
        NVL(LINES.warehouse_id,to_number(pg_so_org_id))) warehouse_id,
      LINES.line_recoverable,
      LINES.tax_recoverable,
      LINES.ship_to_customer_id        line_ship_to_customer_id,
      LINES.ship_to_site_use_id        line_ship_to_site_use_id,
      LINES.inventory_item_id          inv_product_id,
      HR.location_id                   ship_from_location_id,
      HRL.location_id                  poa_location_id,
      SR_PER.organization_id           poo_party_id,
      SR_HRL.location_id               poo_location_id
   FROM
       RA_CUSTOMER_TRX          TRX,
       RA_CUST_TRX_TYPES        TT,
       RA_CUSTOMER_TRX_LINES    LINES,
       AR_SYSTEM_PARAMETERS     AR,
       FND_CURRENCIES           CUR,
       HZ_CUST_ACCOUNTS         BILL_CUST,
       HZ_PARTIES               BILL_PARTY,
       HZ_CUST_ACCT_SITES       BILL_AS,
       HZ_CUST_SITE_USES        BILL_SU,
       HZ_PARTY_SITES           BILL_PS,
       HR_ALL_ORGANIZATION_UNITS HR,
       HR_ORGANIZATION_UNITS     HRL,
       JTF_RS_SALESREPS          SR,
       PER_ALL_ASSIGNMENTS_F     SR_PER,
       HR_ORGANIZATION_UNITS     SR_HRL
   WHERE  
      TRX.customer_trx_id = p_trx_id and
      LINES.customer_trx_id = TRX.customer_trx_id and
      LINES.customer_trx_line_id = 
          NVL(p_trx_line_id,LINES.customer_trx_line_id) and 
      LINES.line_type IN ('LINE' ,'CB') and 
      TRX.org_id = AR.org_id and 
      TRX.cust_trx_type_id = TT.cust_trx_type_id and
      TRX.invoice_currency_code = CUR.currency_code and
      TRX.bill_to_customer_id = BILL_CUST.cust_account_id and
      BILL_CUST.party_id = BILL_PARTY.party_id and 
      BILL_CUST.cust_account_id = BILL_AS.cust_account_id and
      BILL_AS.cust_acct_site_id = BILL_SU.cust_acct_site_id and
      BILL_SU.site_use_id = TRX.bill_to_site_use_id and
      BILL_AS.party_site_id = BILL_PS.party_site_id and
      LINES.warehouse_id = HR.organization_id (+) and
      TRX.org_id = HRL.organization_id and
      TRX.primary_salesrep_id = SR.salesrep_id (+) and 
      TRX.org_id = SR.org_id (+) and
      SR.person_id = SR_PER.person_id (+) and
      TRX.trx_date BETWEEN nvl(SR_PER.effective_start_date, TRX.trx_date)
                     AND nvl(SR_PER.effective_end_date, TRX.trx_date) and
      NVL(SR_PER.primary_flag, 'Y') = 'Y' and
      SR_PER.assignment_type (+) = 'E' and
      SR_PER.organization_id = SR_HRL.organization_id (+)
    order by LINES.extended_amount;

   /* Selects detail tax lines back from ZX by adj_id/app_id */
   /* 4937059 - grouped by line_id */
   CURSOR tax_lines(p_entity VARCHAR2, p_event_class VARCHAR2, 
                    p_trx_id NUMBER, p_trx_line_id NUMBER,
                    p_mode   VARCHAR2) IS
   SELECT adjusted_doc_line_id, SUM(tax_amt) tax_amt, MAX(line_amt) line_amt 
   FROM   zx_lines
   WHERE  application_id   = 222
   AND    entity_code      = p_entity
   AND    event_class_code = p_event_class
   AND    trx_id           = p_trx_id
   AND    trx_line_id      = NVL(p_trx_line_id, trx_line_id)
   AND    trx_level_type   = DECODE(p_mode,
                               'APP_ED',   'LINE_EARNED',
                               'UNAPP_ED', 'LINE_EARNED',
                               'APP_UED',  'LINE_UNEARNED',
                               'UNAPP_UED','LINE_UNEARNED',
                                           'LINE')
   GROUP BY adjusted_doc_line_id;

   /* For Quotes */
   CURSOR est_tax_lines(p_entity VARCHAR2, p_event_class VARCHAR2, 
                        p_trx_id NUMBER, p_trx_line_id NUMBER,
                        p_mode   VARCHAR2) IS
   SELECT adjusted_doc_line_id, SUM(tax_amt) tax_amt, MAX(line_amt) line_amt 
   FROM   zx_detail_tax_lines_gt
   WHERE  application_id   = 222
   AND    entity_code      = p_entity
   AND    event_class_code = p_event_class
   AND    trx_id           = p_trx_id
   AND    trx_line_id      = NVL(p_trx_line_id, trx_line_id)
   AND    trx_level_type   = DECODE(p_mode,
                               'APP_ED',   'LINE_EARNED',
                               'UNAPP_ED', 'LINE_EARNED',
                               'APP_UED',  'LINE_UNEARNED',
                               'UNAPP_UED','LINE_UNEARNED',
                                           'LINE')
   GROUP BY adjusted_doc_line_id;
   

BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
      debug('arp_etax_debug.prorate_recoverable()+');
      debug('  p_adj_id = ' || p_adj_id);
      debug('  p_target_id = ' || p_target_id);
      debug('  p_target_line_id = ' || p_target_line_id);
      debug('  p_amount = ' || p_amount);
      debug('  p_apply_date = ' || p_apply_date);
      debug('  p_mode = ' || p_mode);
      debug('  p_upd_adj_and_ps = ' || p_upd_adj_and_ps);
      debug('  p_gt_id = ' || p_gt_id); 
      debug('  p_quote = ' || p_quote);
      debug('  p_ra_app_id = ' || p_ra_app_id);
   END IF;
 
      /* Set pg_so_org_id any time it is not set or
         any time the OU changes.  This supports cases where
         users change OU without exiting form */
      IF NVL(pg_org_id,-99) <> arp_global.sysparam.org_id
      THEN 
         pg_org_id := arp_global.sysparam.org_id;

         pg_so_org_id := oe_profile.value('SO_ORGANIZATION_ID',
                           pg_org_id);
      END IF;

      /* Set event class, type, and entity based on 
         receivables_trx.type */
      IF p_mode in ('LINE','TAX','INV')
      THEN
         /* ADJUSTMENTS */
         l_amount := p_amount; /* adj in correct sign already */
         l_transaction_rec.entity_code              := 'ADJUSTMENTS';
         l_transaction_rec.event_class_code         := 'INVOICE_ADJUSTMENT';
         l_transaction_rec.event_type_code          := 'ADJ_CREATE';

         /* Get adj number */
         SELECT a.adjustment_number, r.tax_recoverable_flag,a.tax_adjusted
         INTO   l_adj_number,
                l_recov_flag,
                l_tax_adjusted     /* Bug 8512053 */          
         FROM   ar_adjustments a,
                ar_receivables_trx r
         WHERE  a.adjustment_id = p_adj_id
         AND    a.receivables_trx_id = r.receivables_trx_id
         AND    a.org_id = r.org_id;

      ELSIF p_mode in ('APP_ED', 'APP_UED', 'UNAPP_ED', 'UNAPP_UED')
      THEN
         /* RECEIPTS */
         l_transaction_rec.entity_code              := 'RECEIPTS';
         l_transaction_rec.event_class_code         := 'RECEIPTS';
         IF p_mode in ('APP_ED','APP_UED') /* APPLY */
         THEN
            l_amount := p_amount * -1; /* apps are passed as positive */
            l_transaction_rec.event_type_code       := 'RECP_APPLY';
         ELSE /* UNAPPLY */
            l_amount := p_amount;      /* unapp should be kept positive */
            l_transaction_rec.event_type_code       := 'RECP_UNAPPLY';
         END IF;

         /* 5677984 - deal with receipt application id.
             It may be zero coming from arcpau */
         IF NVL(p_ra_app_id,0) = 0
         THEN
            /* get it from sequence */
            SELECT ar_receivable_applications_s.nextval 
            INTO   p_ra_app_id
            FROM   DUAL;
 
            IF PG_DEBUG IN ('Y','C')
            THEN
               debug('assigned p_ra_app_id = ' || 
                         p_ra_app_id);
            END IF;
         ELSIF p_ra_app_id = -1
         THEN
            /* we have a problem -- wrong prorate_recoverable routine
               was called and -1 was defaulted */
            debug('EXCEPTION:  p_ra_app_id is -1 for a receipt');
         ELSE
            /* application_id passed in, don't change a thing */
            NULL;
         END IF;

         /* Get receipt number into adj_number */
         /* set local l_recov_flag based on mode and outer joins, 
                no return = N */
         select cr.receipt_number,
                NVL(decode(p_mode, 'APP_ED',   earn.tax_recoverable_flag,
                                   'UNAPP_ED', earn.tax_recoverable_flag,
                                   'APP_UED',   unearn.tax_recoverable_flag,
                                   'UNAPP_UED', unearn.tax_recoverable_flag),
                           'N')
         into   l_adj_number,
                l_recov_flag
         from   ar_cash_receipts           cr,
                ar_receipt_method_accounts arm,
                ar_receivables_trx         earn,
                ar_receivables_trx         unearn
         where  cr.cash_receipt_id = p_adj_id
         and    cr.receipt_method_id = arm.receipt_method_id
         and    arm.edisc_receivables_trx_id = earn.receivables_trx_id (+)
         and    arm.unedisc_receivables_trx_id = unearn.receivables_trx_id (+)
	 and    cr.remit_bank_acct_use_id = arm.remit_bank_acct_use_id; --bug6401710

      ELSE
         /* Unknown condition, note it in log for debugging */
         debug('EXCEPTION:  unknown mode : ' || p_mode);
         p_prorated_line := p_amount;
         p_prorated_tax  := 0; 
         RETURN;         
      END IF;

      /* If the activity is not recoverable, then bail out without
         doing anything */
      IF NVL(l_recov_flag, 'N') = 'N' 
      THEN
        IF (p_quote = 'N')
        THEN
            p_prorated_line := p_amount;
            p_prorated_tax := 0;
        END IF; 
        IF (PG_DEBUG in ('Y','C')) THEN
           debug('receivables activity is not recoverable');
           debug('arp_etax_util.prorate_recoverable()-');
        END IF;
        RETURN;
      END IF;

      /* Set header structure for calculate_tax call */
      l_transaction_rec.internal_organization_id := arp_global.sysparam.org_id;
      l_transaction_rec.application_id           := 222;
      IF p_mode in ('APP_ED','APP_UED','UNAPP_ED','UNAPP_UED') 
      THEN
         l_transaction_rec.trx_id                := p_ra_app_id;
      ELSE
         l_transaction_rec.trx_id                := p_adj_id;
      END IF;

      /* Initialize line record to null */
      l_transaction_line_rec.internal_organization_id := NULL; 
      l_transaction_line_rec.application_id         :=  NULL;
      l_transaction_line_rec.entity_code            :=  NULL;
      l_transaction_line_rec.event_class_code       :=  NULL;
      l_transaction_line_rec.event_type_code        :=  NULL;
      l_transaction_line_rec.trx_id                 :=  NULL;
      l_transaction_line_rec.trx_level_type         :=  NULL;
      l_transaction_line_rec.trx_line_id            :=  NULL;

      /* Start of proration code */
      /* Get divisor for proration equation */
      /* Bug 8964860, Handled the condition for tax_recoverable and 
         line_recoverable being NULL. */
      IF p_mode = 'TAX'
      THEN
        /* TAX only adjustment 
           NOTE:  This was not coded to handle line-level adjustments.  */
         SELECT sum(least(tax_line.extended_amount, nvl(line.tax_recoverable, tax_line.extended_amount))),
                sum(nvl(line.tax_recoverable,0))
         INTO   l_sum,
                l_total_tax_recov
         FROM   ra_customer_trx_lines line,
                ra_customer_trx_lines tax_line
         WHERE  line.customer_trx_id = p_target_id
         AND    line.line_type = 'LINE' 
         AND    tax_line.link_to_cust_trx_line_id = line.customer_trx_line_id
         AND    tax_line.line_type = 'TAX';

         IF (PG_DEBUG in ('Y','C')) THEN
            debug('tax-only adjustment so divisor only considers tax');
         END IF;

      ELSE
        /* Both LINE and TAX or discounts that prorate LINE and TAX */
         SELECT   
              sum(least(tl.extended_amount,nvl(tl.line_recoverable, tl.extended_amount)) *
                  (1 + nvl(tl.tax_recoverable, 0)/
                      DECODE(tl.line_recoverable,0,1,NULL,1,
                             tl.line_recoverable))),
              sum(nvl(tl.tax_recoverable,0))
         INTO    l_sum, 
                 l_total_tax_recov
         FROM    ra_customer_trx_lines tl
         WHERE   tl.customer_trx_id = p_target_id 
         AND     tl.customer_trx_line_id = 
             NVL(p_target_line_id, tl.customer_trx_line_id)
         AND     tl.line_type = 'LINE';
         
      END IF;   
      
      /* Bug 8512053: If the transaction is fully adjusted, then AR has to pass
             the balance tax amount as 'CTRL_TOTAL_HDR_TX_AMT' and 
             CTRL_HDR_TX_APPL_FLAG as 'Y' to EBTAX */   
      IF p_mode in ('LINE','TAX','INV')
      THEN      
          SELECT sum(amount_due_remaining)
          INTO  l_amt_due_remaining
          FROM ar_payment_schedules ps
          where ps.customer_trx_id = p_target_id
          group by ps.customer_trx_id;   
           
          IF (PG_DEBUG in ('Y','C')) THEN
             debug('remaining balance on the transaction = ' || l_amt_due_remaining);
          END IF;
          
          IF l_amt_due_remaining = 0 THEN
             l_total_tax_recov :=  l_tax_adjusted;
             l_ctrl_hdr_tx_appl_flag := 'Y';
          END IF;
      
      END IF;
      
      IF (PG_DEBUG in ('Y','C')) THEN
         debug('sum (divisor) for proration calc = ' || l_sum);
      END IF;

      /* Now iterate through the lines and figure the prorated amounts.
         Insert them into the ZX structure for processing */
      FOR c_tl in trx_lines(p_target_id, p_target_line_id) LOOP

        IF (PG_DEBUG in ('Y','C')) THEN
           debug('processing trx_line_id ' || c_tl.inv_trx_line_id);
           debug('   extended_amount  = '  || c_tl.line_amt);
           debug('   line_recoverable = '  || c_tl.line_recoverable);
           debug('   tax_recoverable  = '  || c_tl.tax_recoverable);
        END IF;

        /* calculate the prorated adjustment */
        IF p_mode = 'TAX' 
        THEN
           /* In this case, the proration is based on tax only and will be 
              allocated for tax.  This sql uses link_to in order
              to find the tax lines for a given invoice line. */
           SELECT LEAST(nvl(c_tl.tax_recoverable, sum(extended_amount)), sum(extended_amount))
           INTO   l_tax_amount
           FROM   RA_CUSTOMER_TRX_LINES 
           WHERE  customer_trx_id = c_tl.inv_trx_id
           AND    link_to_cust_trx_line_id = c_tl.inv_trx_line_id
           AND    line_type = 'TAX';

           l_line_proration := l_amount * (nvl(l_tax_amount,0)/l_sum);

        ELSE
           /* In this case, the proration is line + tax and will eventually
              be allocated for line and tax separately */
           IF NVL(c_tl.line_recoverable,0) = 0
           THEN
              l_line_proration := 0;
           ELSE
             /* Added debug and modified clause to populate value as 0 in place of null */
	      arp_util.debug('l_amount'||l_amount);
	      arp_util.debug('c_tl.line_amt'||c_tl.line_amt);
	      arp_util.debug('c_tl.line_recoverable'||c_tl.line_recoverable);
	      arp_util.debug('c_tl.line_recoverable'||c_tl.line_recoverable);
	      arp_util.debug('l_sum'||l_sum);
              l_line_proration := (l_amount * 
                          LEAST(c_tl.line_amt, c_tl.line_recoverable) *
                            (1 + NVL(c_tl.tax_recoverable,0) / c_tl.line_recoverable))
                              / l_sum;
           END IF;
        END IF;

        /* Round l_line_proration amount to the currency (uses NEAREST) */
        IF c_tl.trx_precision is not null
        THEN
            l_line_proration := round(l_line_proration, c_tl.trx_precision);
        ELSE
            l_line_proration := (round(l_line_proration / c_tl.trx_mau) 
                                    * c_tl.trx_mau);
        END IF;

        /* Store the line proration in a simple table
           for later use (figuring recoverable) */
        t_prorated_amt(c_tl.inv_trx_line_id) := l_line_proration;

        /* track what we have allocated so far, 
           used to correct rounding at end */ 
        l_total_proration := l_total_proration + l_line_proration;

        /* Identify a line for rounding corrections.  This will
           note the largest positive or smallest negative line
           and assign rounding to that line. */
        l_row := l_row + 1;
        IF nvl(l_line_proration,0) <> 0 AND
          (l_round_target_amt <= l_line_proration AND
           sign(l_line_proration) = 1) OR
          (l_round_target_amt >= l_line_proration AND
           sign(l_line_proration) = -1)
        THEN
           l_round_target_amt := l_line_proration;
           l_round_target_line_id := l_row;
        END IF;

        /* Initialize ZX tables */
        ZX_GLOBAL_STRUCTURES_PKG.INIT_TRX_LINE_DIST_TBL(l_row);

        /* Set ZX table variables specific to adjustments */
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.adjusted_doc_application_id(l_row) := 222;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.adjusted_doc_entity_code(l_row)    := 'TRANSACTIONS';
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.adjusted_doc_event_class_code(l_row):= c_tl.trx_event_class;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.adjusted_doc_trx_id(l_row)         := c_tl.inv_trx_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.adjusted_doc_line_id(l_row)    := c_tl.inv_trx_line_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.adjusted_doc_trx_level_type(l_row) := 'LINE';
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.adjusted_doc_number(l_row)         := c_tl.trx_number;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.adjusted_doc_date(l_row)           := c_tl.inv_trx_date;
       
        /* Set ZX tables for Tax only allocations */
        IF p_mode = 'TAX' 
        THEN
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_LEVEL_ACTION(l_row)  
              := 'ALLOCATE_TAX_ONLY_ADJUSTMENT';
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CTRL_TOTAL_LINE_TX_AMT(l_row):= l_line_proration; 
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_AMT(l_row)              := 0;
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_AMT_INCLUDES_TAX_FLAG(l_row) := 'N';
        ELSE
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_LEVEL_ACTION(l_row)  := 'CREATE';
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_AMT(l_row) := l_line_proration;
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_AMT_INCLUDES_TAX_FLAG(l_row) := 'A';
        END IF;

        /* Set ZX table variables from l_transaction_rec structure */
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.INTERNAL_ORGANIZATION_ID(l_row) := 
           l_transaction_rec.internal_organization_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.APPLICATION_ID(l_row)     := 
           l_transaction_rec.application_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ENTITY_CODE(l_row)        := 
           l_transaction_rec.entity_code;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EVENT_CLASS_CODE(l_row)   := 
           l_transaction_rec.event_class_code;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EVENT_TYPE_CODE(l_row)    := 
           l_transaction_rec.event_type_code;

        /* Set line level variables from cursor or parameters */
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_DATE(l_row)           := p_apply_date;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LEDGER_ID(l_row)          := c_tl.ledger_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_CURRENCY_CODE(l_row)     := c_tl.trx_currency_code;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.PRECISION(l_row) := c_tl.trx_precision;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.MINIMUM_ACCOUNTABLE_UNIT(l_row) := c_tl.trx_mau;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CURRENCY_CONVERSION_DATE(l_row) := c_tl.exchange_date;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CURRENCY_CONVERSION_RATE(l_row) := c_tl.exchange_rate;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CURRENCY_CONVERSION_TYPE(l_row) := c_tl.exchange_rate_type;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LEGAL_ENTITY_ID(l_row)       := c_tl.legal_entity_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CTRL_TOTAL_HDR_TX_AMT(l_row) := l_total_tax_recov;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_NUMBER(l_row)            := l_adj_number;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_ID(l_row) := 
                   c_tl.inv_trx_line_id;

        /* 5677984 - applications use passed app_id, all others (adj) 
            use customer_trx_line_id */
        IF p_mode in ('APP_ED', 'APP_UED', 'UNAPP_ED', 'UNAPP_UED')
        THEN
           l_adj_ra_id := p_ra_app_id;
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_ID(l_row)
                   := p_ra_app_id;

           /* Set Applied_from columns */
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.applied_from_application_id(l_row) := 222;
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.applied_from_entity_code(l_row) := 'RECEIPTS';
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.applied_from_event_class_code(l_row) := 'RECEIPTS';
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.applied_from_trx_id(l_row) := p_adj_id; -- cash_receipt_id
           -- need to set line_id = LLCA.detail.line_id for LLCA
           -- ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.applied_from_line_id := NULL; 

           IF p_mode in ('APP_ED','UNAPP_ED')
           THEN
              /* Earned */
              ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LEVEL_TYPE(l_row)
                  := 'LINE_EARNED';
           ELSE
              /* Unearned */
              ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LEVEL_TYPE(l_row)
                  := 'LINE_UNEARNED';
           END IF;
        ELSE
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_ID(l_row)
                := p_adj_id;
           ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LEVEL_TYPE(l_row)
                := 'LINE';
           l_adj_ra_id := p_adj_id;
        END IF;

        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.PRODUCT_ID(l_row)            := c_tl.inv_product_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.APPLIED_TO_TRX_NUMBER(l_row) := c_tl.trx_number;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_TO_PARTY_ID(l_row)      := c_tl.bill_to_party_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.ROUNDING_BILL_TO_PARTY_ID(l_row) := c_tl.bill_to_party_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_TO_PARTY_SITE_ID(l_row) := c_tl.bill_to_party_site_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.RNDG_BILL_TO_PARTY_SITE_ID(l_row) := c_tl.bill_to_party_site_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_TO_LOCATION_ID(l_row) := c_tl.bill_to_location_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.HISTORICAL_FLAG(l_row)       := c_tl.historical_flag;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CTRL_HDR_TX_APPL_FLAG(l_row) := l_ctrl_hdr_tx_appl_flag;
/*      5393508 - Do not populate trx_line_date 
      ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_DATE(l_row) := 
          p_apply_date;
*/
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EXEMPTION_CONTROL_FLAG(l_row):= c_tl.exemption_control_flag;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EXEMPT_CERTIFICATE_NUMBER(l_row) := c_tl.exempt_certificate_number;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.EXEMPT_REASON_CODE(l_row)         := c_tl.exempt_reason;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_FROM_PARTY_ID(l_row)    := c_tl.warehouse_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_FROM_LOCATION_ID(l_row) := c_tl.ship_from_location_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.POA_LOCATION_ID(l_row) := c_tl.poa_location_id;
	ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.BILL_FROM_LOCATION_ID(l_row) := c_tl.poa_location_id;  -- Bug 17313768.
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.POO_PARTY_ID(l_row) := c_tl.poo_party_id;
        ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.POO_LOCATION_ID(l_row) := c_tl.poo_location_id;

        /* Determine ship_to cust and site info */
        IF ( c_tl.line_ship_to_customer_id IS NOT NULL and 
             c_tl.line_ship_to_site_use_id IS NOT NULL) 
        THEN
             l_cust_id := c_tl.line_ship_to_customer_id;
             l_site_use_id := c_tl.line_ship_to_site_use_id;
        ELSIF ( c_tl.trx_ship_to_customer_id IS NOT NULL and
                c_tl.trx_ship_to_site_use_id IS NOT NULL) 
        THEN
             l_cust_id := c_tl.trx_ship_to_customer_id;
             l_site_use_id := c_tl.trx_ship_to_site_use_id;
        ELSE
             l_cust_id := NULL;
             l_site_use_id := NULL;
 
        END IF;
 
        /* Fetch ship_to party info */
        IF (l_cust_id IS NOT NULL and l_site_use_id IS NOT NULL) 
        THEN

          SELECT  
               CUST_ACCT.party_id,
               ACCT_SITE.party_site_id,
               PARTY_SITE.location_id
          INTO
             -- ship_to_party_id
             ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_PARTY_ID(l_row),
             -- ship_to_party_site_id
             ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_PARTY_SITE_ID(l_row),
             -- ship_to_location_id
             ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.SHIP_TO_LOCATION_ID(l_row)
          FROM
             hz_cust_accounts         CUST_ACCT,
             hz_parties               PARTY,
             hz_cust_acct_sites       ACCT_SITE,
             hz_cust_site_uses        SITE_USES,
             hz_party_sites           PARTY_SITE
          WHERE
             CUST_ACCT.cust_account_id = l_cust_id AND
             CUST_ACCT.party_id = PARTY.party_id AND          
             CUST_ACCT.cust_account_id = ACCT_SITE.cust_account_id AND
             ACCT_SITE.cust_acct_site_id = SITE_USES.cust_acct_site_id AND
             SITE_USES.site_use_id = l_site_use_id and
             PARTY_SITE.party_site_id = ACCT_SITE.party_site_id;
 
        END IF; /* end fetch */ 
       
      END LOOP;

      /* correct rounding if needed */
      IF l_total_proration <> l_amount
      THEN
         l_rounding_correction := l_amount - l_total_proration;

         /* make sure we identified a line for rounding.. if not
            then use the last row processed */
         IF l_round_target_line_id IS NULL
         THEN
            l_round_target_line_id := l_row;
         END IF;

         IF p_mode = 'TAX'
         THEN
            ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CTRL_TOTAL_LINE_TX_AMT(l_round_target_line_id):=
            ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.CTRL_TOTAL_LINE_TX_AMT(l_round_target_line_id) + l_rounding_correction;
         ELSE
            ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_AMT(l_round_target_line_id) :=
            ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.LINE_AMT(l_round_target_line_id) +
                l_rounding_correction;
         END IF;

         /* fix the line proration table, too */
         t_prorated_amt(ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_ID(l_round_target_line_id)) :=
         t_prorated_amt(ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl.TRX_LINE_ID(l_round_target_line_id)) +
             l_rounding_correction;         
      END IF;

      /* insert det factors */   
      ZX_API_PUB.insert_line_det_factors (
             p_api_version        => 1.0, 
             p_init_msg_list      => FND_API.G_TRUE,
             p_commit             => FND_API.G_FALSE,
             p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
             x_return_status      => l_return_status_service,
             x_msg_count          => l_msg_count,
             x_msg_data           => l_msg_data,
             p_duplicate_line_rec => l_transaction_line_rec);

      /* calculate tax */
      zx_api_pub.calculate_tax(
             p_api_version           => 1.0,
             p_init_msg_list         => FND_API.G_TRUE,
             p_commit                => FND_API.G_FALSE,
             p_validation_level      => FND_API.G_VALID_LEVEL_FULL,
             p_transaction_rec       => l_transaction_rec,
             p_quote_flag            => p_quote,  -- quote
             p_data_transfer_mode    => 'WIN',
             x_return_status         => l_return_status_service,
             x_msg_count             => l_msg_count,
             x_msg_data              => l_msg_data,
             x_doc_level_recalc_flag => l_doc_level_recalc_flag );

      /* When the API returns success, prorate the tax out and 
         update the line and tax_recoverable columns */
      IF (l_return_status_service = 'S')   
      THEN
    
         /* initialize prorated tax and line amounts to zero */
         p_prorated_line := 0;
         p_prorated_tax := 0;
       
       IF (p_quote = 'N')
       THEN
         /* Existing logic for actual tax calculations */
         /* Set out parameter totals and update LINES recoverable columns */
         FOR c_tax_lines IN tax_lines(l_transaction_rec.entity_code,
                                      l_transaction_rec.event_class_code,
                                      l_adj_ra_id,
                                      p_target_line_id,
                                      p_mode) LOOP                                     
           l_lines_processed := TRUE;

           /* switch sign of tax_amt (discounts are normally positive
              but pos is reflected as negative in etax) */

           IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug(c_tax_lines.adjusted_doc_line_id || 
                            '  t_prorated_amt =' || t_prorated_amt(c_tax_lines.adjusted_doc_line_id) || 
                            '  zx.tax =' || c_tax_lines.tax_amt);
           END IF;

           l_prorated_tax := c_tax_lines.tax_amt;
			
		   /*bug 14595727*/	
		   IF t_prorated_amt(c_tax_lines.adjusted_doc_line_id) <> 0 or l_prorated_tax <> 0 THEN	
		      	l_prorated_line := t_prorated_amt(c_tax_lines.adjusted_doc_line_id) 
                                    - l_prorated_tax;
       ELSE l_prorated_line := 0;                               
       END IF;
			
           UPDATE RA_CUSTOMER_TRX_LINES
           SET    line_recoverable = line_recoverable + l_prorated_line,
                  tax_recoverable  = tax_recoverable  + l_prorated_tax,
                  last_updated_by  = arp_standard.profile.user_id,
                  last_update_date = sysdate
           WHERE  customer_trx_line_id = c_tax_lines.adjusted_doc_line_id; 

           IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('before swap: ' || c_tax_lines.adjusted_doc_line_id || 
                            '  line=' || l_prorated_line || 
                            '  tax=' || l_prorated_tax);
           END IF;

           IF p_mode in ('APP_ED', 'APP_UED')
           THEN
              /* for receipt applications, we switched the sign 
                 at the beginning.. now we have to switch it back */
              l_prorated_tax := l_prorated_tax * -1;
              l_prorated_line := l_prorated_line * -1;

              /* This means that the returned values are in the same
                 sign as the p_amount that was passed in now */
           END IF;

           /* accumulate into the parameter columns */
           p_prorated_tax := p_prorated_tax + l_prorated_tax;
           p_prorated_line := p_prorated_line + l_prorated_line;

           IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('after swap: ' || c_tax_lines.adjusted_doc_line_id || 
                            '  line=' || l_prorated_line || 
                            '  tax=' || l_prorated_tax);
           END IF;

         END LOOP;

         IF l_lines_processed = FALSE 
         THEN
            arp_util.debug('initializing prorated_line to adj amt');

            /* initalize the outbound parameters as LINE=amt, TAX=0 
               In a situation where etax does nothing, then we should
               act as if there was no tax in our proration logic.  */
            p_prorated_line := l_amount;
            p_prorated_tax  := 0;
         END IF; 

         /* Update PS and ADJ records if required */

	 ---------------------------------ASHLESH-----------------------
/* Added sql to idenitfy upgrade data and preven re-update for the data in ps and adjustment again */
BEGIN

select 'Y' INTO l_event_exists from dual
where exists(
select 'X'
FROM xla_transaction_entities_upg 
WHERE nvl(source_id_int_1,-99) = p_target_id
AND ledger_id = arp_global.sysparam.set_of_books_id
AND entity_code = 'TRANSACTIONS'
AND upg_batch_id IS NOT NULL
AND application_id=222
AND upg_source_application_id = 222);

EXCEPTION
WHEN OTHERS THEN
l_event_exists := 'N';
END;

     IF p_mode = 'INV' AND l_event_exists = 'Y' then
     p_prorated_line := p_amount - p_prorated_tax;
     END IF;
	 
	 IF NVL(p_upd_adj_and_ps, 'N') <> 'N'            
         THEN
            update_adj_and_ps(p_upd_adj_and_ps,
                              p_adj_id,
                              p_prorated_line,
                              p_prorated_tax);
         END IF;

         /* Call line-level proration logic for accounting entries */
	  -- Added for Line Level Adjustment ER 
         IF p_target_line_id IS NOT NULL
	  THEN		
		l_from_llca_call := 'Y';
	 ELSE	      
		l_from_llca_call := 'N';
	 END IF;
         prorate_accounting(l_transaction_rec,
                            p_mode,
                            p_ra_app_id, -- isolates APP/UNAPP
                            p_gt_id,
			    l_from_llca_call,
			    p_target_line_id);

       ELSE
         IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug(' prorate_recoverable called in quote mode');
         END IF;

         /* p_quote = Y -- so this is quote logic */
         FOR c_tax_lines IN est_tax_lines(l_transaction_rec.entity_code,
                                      l_transaction_rec.event_class_code,
                                      l_transaction_rec.trx_id,
                                      l_adj_ra_id,
                                      p_mode) LOOP

           l_lines_processed := TRUE;

           /* switch sign of tax_amt (discounts are normally positive
              but pos is reflected as negative in etax) */

           IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug(c_tax_lines.adjusted_doc_line_id || 
                            '  t_prorated_amt =' || t_prorated_amt(c_tax_lines.adjusted_doc_line_id) || 
                            '  zx.tax =' || c_tax_lines.tax_amt);
           END IF;

           l_prorated_tax := c_tax_lines.tax_amt;

           l_prorated_line := t_prorated_amt(c_tax_lines.adjusted_doc_line_id) 
                                    - l_prorated_tax; 

           IF p_mode in ('APP_ED', 'APP_UED', 'UNAPP_ED', 'UNAPP_UED')
           THEN
              /* for receipt applications, we switched the sign 
                 at the beginning.. now we have to switch it back */
              l_prorated_tax := l_prorated_tax * -1;
              l_prorated_line := l_prorated_line * -1;

              /* This means that the returned values are in the same
                 sign as the p_amount that was passed in now */
           END IF;

           /* accumulate into the parameter columns */
           p_prorated_tax := p_prorated_tax + l_prorated_tax;
           p_prorated_line := p_prorated_line + l_prorated_line;

           IF PG_DEBUG in ('Y', 'C') THEN
             debug(c_tax_lines.adjusted_doc_line_id || 
                            '  line=' || l_prorated_line || 
                            '  tax=' || l_prorated_tax);
           END IF;

         END LOOP;

         IF l_lines_processed = FALSE 
         THEN
            debug('initializing prorated_line to adj amt');

            /* initalize the outbound parameters as LINE=amt, TAX=0 
               In a situation where etax does nothing, then we should
               act as if there was no tax in our proration logic.  */
            p_prorated_line := l_amount;
            p_prorated_tax  := 0;
         END IF; 

       END IF;

       IF PG_DEBUG in ('Y','C')
       THEN
          debug('returned values');
          debug('  p_prorated_line = ' || p_prorated_line);
          debug('  p_prorated_tax  = ' || p_prorated_tax);
       END IF;
         
      ELSE
      /* When the API returns a failure, do something bad! */
          debug('EXCEPTION:  Unable to calculate tax ');

          p_prorated_tax  := 0; 
          RETURN;
      END IF;

   IF PG_DEBUG in ('Y', 'C') THEN
      debug('arp_etax_util.prorate_recoverable()-');
   END IF;

END prorate_recoverable;

/* Public Procedure - adjusted line amounts for inclusive tax.
   can be used for individual transactions or batches.

   This will adjust the extended_amount
                        unit_selling_price
                        gross_extended_amount
                        gross_unit_selling_price

   06-APR-2006    5146437 - fixed syntax error for inclusive tax logic
   05-OCT-2006    5487466 - Revised c_trx to handle removal of incl
                    taxes and removal of all taxes from a transaction

   28-MAR-2007    5942753 - Handle cases where line amount is zero
                    and transaction is tax-only
   01-MAR-2011    11671073 - CODEFIX: THE TRANSACTION TOTAL DOUBLES 
                                        IF INCLULSIVE TAX AMOUNT IS SAME AS LINE .
*/ 

PROCEDURE adjust_for_inclusive_tax(p_trx_id      IN NUMBER,
                                   p_request_id  IN NUMBER DEFAULT NULL,
                                   p_phase       IN VARCHAR2 DEFAULT NULL)
IS

   l_new_extended_amount NUMBER;
   l_new_unit_selling_price NUMBER;
   l_base_currency          FND_CURRENCIES.currency_code%type;
   l_base_precision         FND_CURRENCIES.precision%type;
   l_base_mau               FND_CURRENCIES.minimum_accountable_unit%type;

   CURSOR c_trx(p_trx_id NUMBER) IS
      SELECT line.CUSTOMER_TRX_LINE_ID          customer_trx_line_id,
/*             sum(decode(tax.amount_includes_tax_flag, 
                  'Y', decode(line.extended_amount, 0, 0,
                              tax.extended_amount), 0)) inclusive_amount,*/
             sum(decode(tax.amount_includes_tax_flag,
                  'Y', decode(nvl(line.gross_extended_amount, line.extended_amount), 0, 0,
                              tax.extended_amount), 0)) inclusive_amount,--qiong fix bug :11671073  
             header.invoice_currency_code       currency_code,  
             header.exchange_rate               exchange_rate,
             currency.precision                 precision,
             currency.minimum_accountable_unit  mau
      FROM   RA_CUSTOMER_TRX       header,
             FND_CURRENCIES        currency,
             RA_CUSTOMER_TRX_LINES line,
             RA_CUSTOMER_TRX_LINES tax 
      WHERE  header.CUSTOMER_TRX_ID = p_trx_id 
      AND    line.CUSTOMER_TRX_ID = header.CUSTOMER_TRX_ID
      AND    line.LINE_TYPE = 'LINE'
      AND    tax.LINK_TO_CUST_TRX_LINE_ID = line.CUSTOMER_TRX_LINE_ID
      AND    tax.LINE_TYPE = 'TAX'
      AND    (tax.AMOUNT_INCLUDES_TAX_FLAG = 'Y' OR
               (nvl(tax.AMOUNT_INCLUDES_TAX_FLAG, 'N') = 'N' AND 
                nvl(line.gross_extended_amount,0) <> 0 ))
      AND    header.INVOICE_CURRENCY_CODE = currency.CURRENCY_CODE
      GROUP BY line.CUSTOMER_TRX_LINE_ID, header.INVOICE_CURRENCY_CODE, 
               header.EXCHANGE_RATE, currency.PRECISION, 
               currency.MINIMUM_ACCOUNTABLE_UNIT
      UNION -- following is for lines w/out tax
      SELECT line.CUSTOMER_TRX_LINE_ID          customer_trx_line_id,
             0                                  inclusive_amount,
             header.invoice_currency_code       currency_code,  
             header.exchange_rate               exchange_rate,
             currency.precision                 precision,
             currency.minimum_accountable_unit  mau
      FROM   RA_CUSTOMER_TRX       header,
             FND_CURRENCIES        currency,
             RA_CUSTOMER_TRX_LINES line
      WHERE  header.CUSTOMER_TRX_ID = p_trx_id 
      AND    line.CUSTOMER_TRX_ID = header.CUSTOMER_TRX_ID
      AND    line.LINE_TYPE = 'LINE'
      AND    nvl(line.gross_extended_amount,0) <> 0 
      AND    header.INVOICE_CURRENCY_CODE = currency.CURRENCY_CODE
      AND NOT EXISTS
             (SELECT 'any tax line'
              FROM   ra_customer_trx_lines tax
              WHERE  tax.customer_trx_id = line.customer_trx_id
              AND    tax.link_to_cust_trx_line_id = 
                       line.customer_trx_line_id
              AND    tax.line_type = 'TAX'); 

   CURSOR c_req(p_request_id NUMBER) IS
      SELECT /*+ index (line RA_CUSTOMER_TRX_LINES_N4) */
             line.CUSTOMER_TRX_LINE_ID          customer_trx_line_id,
             sum(decode(line.extended_amount, 0, 0, 
                tax.extended_amount))           inclusive_amount,
             header.invoice_currency_code       currency_code,  
             header.exchange_rate               exchange_rate,
             currency.precision                 precision,
             currency.minimum_accountable_unit  mau
      FROM   RA_CUSTOMER_TRX       header,
             FND_CURRENCIES        currency,
             RA_CUSTOMER_TRX_LINES line,
             RA_CUSTOMER_TRX_LINES tax 
      WHERE  header.REQUEST_ID = p_request_id 
      AND    NVL(header.PREVIOUS_CUSTOMER_TRX_ID, -99) = 
                DECODE(p_phase, 'CM', header.PREVIOUS_CUSTOMER_TRX_ID, -99)
      AND    line.CUSTOMER_TRX_ID = header.CUSTOMER_TRX_ID
      AND    line.LINE_TYPE = 'LINE'
      AND    line.request_id = p_request_id -- 7039838
      AND    tax.LINK_TO_CUST_TRX_LINE_ID = line.CUSTOMER_TRX_LINE_ID
      AND    tax.LINE_TYPE = 'TAX'
      AND    tax.AMOUNT_INCLUDES_TAX_FLAG = 'Y'
      AND    tax.CUSTOMER_TRX_ID = line.CUSTOMER_TRX_ID 
      AND    header.INVOICE_CURRENCY_CODE = currency.CURRENCY_CODE
      GROUP BY line.CUSTOMER_TRX_LINE_ID, header.INVOICE_CURRENCY_CODE, 
               header.EXCHANGE_RATE, currency.PRECISION, currency.MINIMUM_ACCOUNTABLE_UNIT;

BEGIN
   IF PG_DEBUG in ('Y', 'C') 
   THEN
      debug('arp_etax_util.adjust_for_inclusive_tax()+');
      debug('   trx_id = ' || p_trx_id);
      debug('   req_id = ' || p_request_id);
      debug('   phase  = ' || p_phase);
   END IF;

   /* Initialize currency info */
      SELECT 
             sob.currency_code,
             c.precision,
             c.minimum_accountable_unit
      INTO   
             l_base_currency,
             l_base_precision,
             l_base_mau
      FROM   gl_sets_of_books sob, 
             fnd_currencies c,
             ar_system_parameters sp
      WHERE  sob.set_of_books_id = sp.set_of_books_id
      AND    sob.currency_code = c.currency_code;


   IF p_trx_id IS NOT NULL
   THEN

     /* execute a loop for each line that has at least one
        inclusive tax calculated for it.  Fetch the sum
        of the inclusive taxes and update the lines, sc, and dist
        for the reduction of that amount.  */

     FOR trx IN c_trx(p_trx_id) LOOP

       IF PG_DEBUG IN ('C','Y')
       THEN
          debug(trx.customer_trx_line_id || ':' ||
                          trx.inclusive_amount);
       END IF;

       arp_ctl_pkg.update_amount_f_ctl_id(
   		trx.customer_trx_line_id,
		trx.inclusive_amount,	
		l_new_extended_amount,
		l_new_unit_selling_price,
		trx.precision, trx.mau);

       arp_ctls_pkg.update_amounts_f_ctl_id(
  		trx.customer_trx_line_id,
		l_new_extended_amount,
		trx.currency_code);

       arp_ctlgd_pkg.update_amount_f_ctl_id(
		trx.customer_trx_line_id,
		l_new_extended_amount,
		trx.currency_code,
		l_base_currency,
		trx.exchange_rate,
		l_base_precision,
		l_base_mau);

     END LOOP;

   ELSIF p_request_id IS NOT NULL
   THEN

     /* execute a loop for each line that has at least one
        inclusive tax calculated for it.  Fetch the sum
        of the inclusive taxes and update the lines, sc, and dist
        for the reduction of that amount.  */

     FOR trx IN c_req(p_request_id) LOOP

       IF PG_DEBUG IN ('C','Y')
       THEN
          debug(trx.customer_trx_line_id || ':' ||
                          trx.inclusive_amount);
       END IF;

       arp_ctl_pkg.update_amount_f_ctl_id(
   		trx.customer_trx_line_id,
		trx.inclusive_amount,	
		l_new_extended_amount,
		l_new_unit_selling_price,
		trx.precision, trx.mau);

       arp_ctls_pkg.update_amounts_f_ctl_id(
  		trx.customer_trx_line_id,
		l_new_extended_amount,
		trx.currency_code);

       arp_ctlgd_pkg.update_amount_f_ctl_id(
		trx.customer_trx_line_id,
		l_new_extended_amount,
		trx.currency_code,
		l_base_currency,
		trx.exchange_rate,
		l_base_precision,
		l_base_mau);

     END LOOP;


   END IF;        

   IF PG_DEBUG in ('Y', 'C') 
   THEN
      debug('arp_etax_util.adjust_for_inclusive_tax()-');
   END IF;
END adjust_for_inclusive_tax; 

/* Public Procedure - sets recoverable columns for transaction or batch.

*/ 

PROCEDURE set_recoverable(p_trx_id      IN NUMBER,
                          p_request_id  IN NUMBER DEFAULT NULL,
                          p_phase       IN VARCHAR2 DEFAULT NULL)
IS

BEGIN
   IF PG_DEBUG in ('Y', 'C') 
   THEN
      debug('arp_etax_util.set_recoverable()+');
      debug('   trx_id = ' || p_trx_id);
      debug('   req_id = ' || p_request_id);
      debug('   phase  = ' || p_phase);
   END IF;

   IF p_trx_id IS NOT NULL
   THEN

      UPDATE ra_customer_trx_lines mtl
      SET    line_recoverable = extended_amount,
             tax_recoverable = (select sum(extended_amount)
                                from   ra_customer_trx_lines sqtl
                                where sqtl.link_to_cust_trx_line_id = 
                                      mtl.customer_trx_line_id
                                and   sqtl.customer_trx_id = 
                                      mtl.customer_trx_id
                                and   sqtl.line_type = 'TAX')
      WHERE  mtl.customer_trx_id = p_trx_id
      AND    mtl.line_type = 'LINE';

   ELSIF p_request_id IS NOT NULL
   THEN

      /* mode logic is different here.  if CM, then we need to join
         by previous_customer_trx_id, otherwise, NVL to -99.  This allows this
         logic to be called for invoice copy (by request_id) but with phase not
         specified */ 
      UPDATE ra_customer_trx_lines mtl
      SET    line_recoverable = extended_amount,
             tax_recoverable = (select sum(extended_amount)
                                from   ra_customer_trx_lines sqtl
                                where sqtl.link_to_cust_trx_line_id = 
                                      mtl.customer_trx_line_id
                                and   sqtl.customer_trx_id = 
                                      mtl.customer_trx_id
                                and   sqtl.line_type = 'TAX')
      WHERE  mtl.request_id = p_request_id
      AND    NVL(mtl.previous_customer_trx_id, -99) = 
                DECODE(p_phase, 'CM', mtl.previous_customer_trx_id, -99)
      AND    mtl.line_type = 'LINE';

   END IF;        

   IF PG_DEBUG in ('Y', 'C') 
   THEN
      debug('arp_etax_util.set_recoverable()-');
   END IF;
END set_recoverable;

/* public function get_tax_account
   Intended to call etax account procedure to fetch tax and interim 
   accounts.  Will cache accounts by customer_trx_line_id to prevent
   function from calling out to etax twice for each loop of 
   autoaccounting sql.

   Parameters:
      subject_id            IN NUMBER    autoaccounting (tax trx_line_id)
                                         adjustment     (adj_id)...
      gl_date               IN DATE      date for acct validation
      desired_account       IN VARCHAR2  TAX
                                         INTERIM              
                                         ADJUSTMENT
      subject_table         IN VARCHAR2  default TAX_LINE
                                            TAX_RATE

   Called From        Parameters                 Results
   =================  =========================  ===================================
   Autoaccounting     1. tax.customer_trx_line_id
                      2. rec.gl_date
                      3a. TAX                    Tax ccid
                      3b. INTERIM                Interim tax ccid
                          ADJ, EDISC, UNEDISC, FINCHRG,
                          ADJ_NON_REC, EDISC_NON_REC,
                          UNEDISC_NON_REC, FINCHRG_NON_REC,
                      4. Null or TAX_LINE
                           

   Allocations        1. tax_rate_id
                      2. sysdate or appropriate
                      3. See above               Accounts from zx_accounts
                                                 based on tax_rate_id alone.
                      4. TAX_RATE 

DEV NOTE: The ZX routine currently does not return accounts for anything other
     than TAX and INTERIM  
*/

FUNCTION get_tax_account(
            p_subject_id            IN NUMBER,
            p_gl_date               IN DATE,
            p_desired_account       IN VARCHAR2,
            p_subject_table         IN VARCHAR2 DEFAULT 'TAX_LINE')
     RETURN NUMBER
  IS
           l_location_segment_id  NUMBER;
           l_org_id               NUMBER;
           l_sob_id               NUMBER;
           l_tax_line_id          NUMBER;
           l_tax_rate_id          NUMBER;
           l_tax_account_ccid     NUMBER;
           l_interim_tax_ccid     NUMBER;
           l_adj_ccid             NUMBER;
           l_edisc_ccid           NUMBER;
           l_unedisc_ccid         NUMBER;
           l_finchrg_ccid         NUMBER;
           l_adj_non_rec_tax_ccid NUMBER;
           l_edisc_non_rec_tax_ccid NUMBER;
           l_unedisc_non_rec_tax_ccid NUMBER;
           l_finchrg_non_rec_tax_ccid NUMBER;
           l_return_status            VARCHAR2(128);
           l_gl_date              DATE;
BEGIN
   /* Debug +/
   debug('arp_etax_util.get_tax_account()+');
   debug('  p_subject_id = ' || p_subject_id);
   debug('  p_gl_date    = ' || p_gl_date);
   debug('  p_desired    = ' || p_desired_account);
   debug('  p_subject_tab= ' || p_subject_table);
   /+ end debug */

   /* Process from cache or zx based on subject_table and 
      cached ID */
   IF NVL(g_tax_customer_trx_line_id,-99) = p_subject_id AND
      p_subject_table = 'TAX_LINE'
   THEN
      /* we have already gone to etax so just return the desired account */
      NULL;
   ELSIF NVL(g_tax_rate_id, -99) = p_subject_id AND
      p_subject_table = 'TAX_RATE'
   THEN
      /* already got the ccids */
      NULL;

   ELSE
      /* init return to prevent false returns */
      l_return_status := FND_API.G_RET_STS_SUCCESS;

      IF p_subject_table = 'TAX_LINE'
      THEN
    
        g_tax_customer_trx_line_id := p_subject_id;
        g_tax_rate_id := NULL; -- so we dont accidentally cross over

        /* new line, get tax_line info and call etax */
        SELECT 
           ar_tax.location_segment_id,
           ar_tax.org_id,
           ar_tax.tax_line_id,
           ar_tax.vat_tax_id,
           ar_tax.set_of_books_id,
           NVL(ar_rec.gl_date, TRUNC(sysdate))
        INTO
           l_location_segment_id,
           l_org_id,
           l_tax_line_id,
           l_tax_rate_id,
           l_sob_id,
           l_gl_date
        FROM
           ra_customer_trx_lines ar_tax,
           ra_cust_trx_line_gl_dist  ar_rec
        WHERE
            ar_tax.customer_trx_line_id = p_subject_id
        AND ar_tax.customer_trx_id = ar_rec.customer_trx_id
        AND ar_rec.account_class = 'REC'
        AND ar_rec.latest_rec_flag = 'Y';

        IF p_gl_date IS NOT NULL
        THEN
           l_gl_date := p_gl_date;
        END IF;

        zx_trd_services_pub_pkg.get_output_tax_ccid(
            p_gl_date             => l_gl_date,
            p_tax_rate_id         => l_tax_rate_id,
            p_location_segment_id => l_location_segment_id,
            p_tax_line_id         => l_tax_line_id,
            p_org_id              => l_org_id,
            p_ledger_id           => l_sob_id,
            p_event_class_code    => null,
            p_entity_code         => 'TRANSACTIONS',
            p_application_id      => 222,
            p_document_id         => to_number(null),
            p_document_line_id    => to_number(null),
            p_trx_level_type      => null,
            p_tax_account_ccid    => l_tax_account_ccid,
            p_interim_tax_ccid    => l_interim_tax_ccid,
            p_adj_ccid            => l_adj_ccid,
            p_edisc_ccid          => l_edisc_ccid,
            p_unedisc_ccid        => l_unedisc_ccid,
            p_finchrg_ccid        => l_finchrg_ccid,
            p_adj_non_rec_tax_ccid     => l_adj_non_rec_tax_ccid,
            p_edisc_non_rec_tax_ccid   => l_edisc_non_rec_tax_ccid,
            p_unedisc_non_rec_tax_ccid => l_unedisc_non_rec_tax_ccid,
            p_finchrg_non_rec_tax_ccid => l_finchrg_non_rec_tax_ccid,
            x_return_status            => l_return_status);

      ELSIF p_subject_table = 'TAX_RATE'
      THEN
        /* Limited call to ZX to get accounts for a tax rate */
        g_tax_customer_trx_line_id := NULL;
        g_tax_rate_id := p_subject_id; 

        /* 5599088 - pass org_id for TAX_RATE search */
        l_org_id := arp_global.sysparam.org_id;
        l_sob_id := arp_global.sysparam.set_of_books_id;

        /* Insure that we have a date to use */
        IF p_gl_date IS NULL
        THEN
           l_gl_date := TRUNC(sysdate);
        ELSE
           l_gl_date := p_gl_date;
        END IF;

        zx_trd_services_pub_pkg.get_output_tax_ccid(
            p_gl_date             => l_gl_date,
            p_tax_rate_id         => g_tax_rate_id,
            p_location_segment_id => null,
            p_tax_line_id         => null,
            p_org_id              => l_org_id,
            p_ledger_id           => l_sob_id,
            p_event_class_code    => null,
            p_entity_code         => null,
            p_application_id      => 222,
            p_document_id         => null,
            p_document_line_id    => null,
            p_trx_level_type      => null,
            p_tax_account_ccid    => l_tax_account_ccid,
            p_interim_tax_ccid    => l_interim_tax_ccid,
            p_adj_ccid            => l_adj_ccid,
            p_edisc_ccid          => l_edisc_ccid,
            p_unedisc_ccid        => l_unedisc_ccid,
            p_finchrg_ccid        => l_finchrg_ccid,
            p_adj_non_rec_tax_ccid     => l_adj_non_rec_tax_ccid,
            p_edisc_non_rec_tax_ccid   => l_edisc_non_rec_tax_ccid,
            p_unedisc_non_rec_tax_ccid => l_unedisc_non_rec_tax_ccid,
            p_finchrg_non_rec_tax_ccid => l_finchrg_non_rec_tax_ccid,
            x_return_status            => l_return_status);
   
      ELSE
         debug('EXCEPTION:  Unknown subject table ' || p_subject_Table);
         RETURN -1;
      END IF; 
 
      /* 4917065 - Moved return logic inside IF/ELSE */
           IF l_return_status = FND_API.G_RET_STS_SUCCESS
           THEN
              g_tax_account_ccid := nvl(l_tax_account_ccid, -1);
              g_interim_tax_ccid := nvl(l_interim_tax_ccid, -1);
              g_adj_ccid         := nvl(l_adj_ccid,-1);
              g_edisc_ccid       := nvl(l_edisc_ccid,-1);
              g_unedisc_ccid     := nvl(l_unedisc_ccid,-1);
              g_finchrg_ccid     := nvl(l_finchrg_ccid,-1);
              g_adj_non_rec_tax_ccid := nvl(l_adj_non_rec_tax_ccid,-1);
              g_edisc_non_rec_tax_ccid := nvl(l_edisc_non_rec_tax_ccid,-1);
              g_unedisc_non_rec_tax_ccid := nvl(l_unedisc_non_rec_tax_ccid,-1);
              g_finchrg_non_rec_tax_ccid := nvl(l_finchrg_non_rec_tax_ccid,-1);
           ELSE
              g_tax_account_ccid := -1;
              g_interim_tax_ccid := -1;
              g_adj_ccid         := -1;
              g_edisc_ccid       := -1;
              g_unedisc_ccid     := -1;
              g_finchrg_ccid     := -1;
              g_adj_non_rec_tax_ccid := -1;
              g_edisc_non_rec_tax_ccid := -1;
              g_unedisc_non_rec_tax_ccid := -1;
              g_finchrg_non_rec_tax_ccid := -1;
  
              debug('EXCEPTION: get_output_tax_ccid returns error');
              RETURN -1;
           END IF;

   END IF;

/* Debug +/
debug('Returning ccids:');
debug('  tax: ' || g_tax_account_ccid);
debug('  interim: ' || g_interim_tax_ccid);
debug('  adj: ' || g_adj_ccid);
debug('  adj_non_rec: ' || g_adj_non_rec_tax_ccid);
debug('  finchrg: ' || g_finchrg_ccid);
debug('  finchrg_non_rec: ' || g_finchrg_non_rec_tax_ccid);
debug('  edisc: ' || g_edisc_ccid);
debug('  unedisc: ' || g_unedisc_ccid);
debug('  edisc_non_rec: ' || g_edisc_non_rec_tax_ccid);
debug('  unedisc_non_rec: ' || g_unedisc_non_rec_tax_ccid);
/+ End debug */

   /* Now return a value */
   IF p_desired_account = 'TAX'
   THEN
      RETURN g_tax_account_ccid;
   ELSIF p_desired_account = 'INTERIM'
   THEN
      RETURN g_interim_tax_ccid;
   ELSIF p_desired_account = 'ADJ'
   THEN
      RETURN g_adj_ccid;
   ELSIF p_desired_account = 'ADJ_NON_REC'
   THEN
      RETURN g_adj_non_rec_tax_ccid;
   ELSIF p_desired_account = 'FINCHRG'
   THEN 
      RETURN g_finchrg_ccid;
   ELSIF p_desired_account = 'FINCHRG_NON_REC'
   THEN
      RETURN g_finchrg_non_rec_tax_ccid;
   ELSIF p_desired_account = 'EDISC'
   THEN
      RETURN g_edisc_ccid;
   ELSIF p_desired_account = 'UNEDISC'
   THEN
      RETURN g_unedisc_ccid;
   ELSIF p_desired_account = 'EDISC_NON_REC'
   THEN
      RETURN g_edisc_non_rec_tax_ccid;
   ELSIF p_desired_account = 'UNEDISC_NON_REC'
   THEN
      RETURN g_unedisc_non_rec_tax_ccid;
   ELSE
      /* no idea what they want */
      debug('EXCEPTION: Invalid desired account = ' || p_desired_account);
      RETURN -1;
   END IF;

END get_tax_account;

/* PUBLIC PROCEDURE calc_applied_and_remaining

   Implemented here as a wrapper for ARP_APP_CALC_PKG version.  In 
   lockbox/cash, we need to call this routine to prorate discount and determine
   if the tax portion is recoverable.  When it is recoverable, we have to 
   call etax to calculate the tax amount, then remove it from the line
   amount.

   If the transaction is not recoverable, then the etax code will not
   be called and this routine will behave exactly as the original. 

   p_mode  currently only supports APP_ED and APP_UED

   p_rec_app_id  - takes and/or returns receivable_application_id
                    this is used by the etax calculate calls.
*/

PROCEDURE calc_applied_and_remaining ( p_amt in number
                               ,p_receipt_id in number
                               ,p_apply_date in date
                               ,p_trx_id     in number
                               ,p_mode in varchar2
                               ,p_rule_set_id number
                               ,p_currency in varchar2
                               ,p_line_remaining in out NOCOPY number
                               ,p_line_tax_remaining in out NOCOPY number
                               ,p_freight_remaining in out NOCOPY number
                               ,p_charges_remaining in out NOCOPY number
                               ,p_line_applied out NOCOPY number
                               ,p_line_tax_applied  out NOCOPY number
                               ,p_freight_applied  out NOCOPY number
                               ,p_charges_applied  out NOCOPY number
                               ,p_rec_app_id       in out NOCOPY number)
IS
   l_tax_recov        VARCHAR2(1);
   l_rec_act_id       NUMBER;
   l_line_applied     NUMBER;
   l_line_tax_applied NUMBER; 
   l_amt              NUMBER;

   l_line_applied_orig NUMBER;
   l_tax_applied_orig  NUMBER; 

   l_gt_id            NUMBER;
BEGIN
   IF PG_DEBUG in ('Y', 'C') 
   THEN
      debug('arp_etax_util.calc_applied_and_remaining()+');
      debug('   p_amt         = ' || p_amt);
      debug('   p_receipt_id  = ' || p_receipt_id);
      debug('   p_apply_date  = ' || p_apply_date);
      debug('   p_trx_id      = ' || p_trx_id);
      debug('   p_mode        = ' || p_mode);
      debug('   p_rule_set_id = ' || p_rule_set_id);
      debug('   p_currency    = ' || p_currency);
      debug('   p_line_remaining     = ' || p_line_remaining);
      debug('   p_line_tax_remaining = ' || p_line_tax_remaining);
      debug('   p_rec_app_id         = ' || p_rec_app_id);
   END IF;
      IF p_receipt_id IS NOT NULL
      THEN

         /* Determine if the discount is recoverable */
--Included remit_bank_acct_use_id condition for bug 6955088
           SELECT NVL(rt.tax_recoverable_flag, 'N'),
                  rt.receivables_trx_id
           INTO   l_tax_recov,
                  l_rec_act_id
           FROM   ar_cash_receipts           cr,
                  ar_receipt_method_accounts arm,
                  ar_receivables_trx         rt
           WHERE  cr.cash_receipt_id = p_receipt_id
           AND    cr.receipt_method_id = arm.receipt_method_id
           AND    cr.remit_bank_acct_use_id = arm.remit_bank_acct_use_id	
           AND    DECODE(p_mode,
                        'APP_ED',arm.edisc_receivables_trx_id,
                        'APP_UED',arm.unedisc_receivables_trx_id) =
                  rt.receivables_trx_id (+);
      ELSE
         l_tax_recov := 'N';
      END IF;

   /* Call original calc_applied_and_remaining */

      ARP_APP_CALC_PKG.calc_applied_and_remaining(
              p_amt,
              p_rule_set_id,
              p_currency,
              p_line_remaining,
              p_line_tax_remaining,
              p_freight_remaining,
              p_charges_remaining,
              p_line_applied,
              p_line_tax_applied,
              p_freight_applied,
              p_charges_applied);

      IF PG_DEBUG in ('Y', 'C')
      THEN
         debug('  returned from arp_app_calc_pkg.calc_applied_and_remaining');
      END IF;
         
      IF l_tax_recov = 'Y'
      THEN
         IF PG_DEBUG in ('Y', 'C') 
         THEN
            debug('  tax is recoverable ');
         END IF;
         /* Deduction activity is recoverable.  Put the
            original tax amount back into the line bucket
            and call etax to prorate it */

           /* Put the line and tax applied back into remaining */
           p_line_tax_remaining := p_line_tax_remaining + 
                                   NVL(p_line_tax_applied,0);

           p_line_remaining := p_line_remaining + 
                               NVL(p_line_applied,0);

           /* Get total applied (the discount) for use in 
               prorate_recoverable */
           l_amt := NVL(p_line_applied, 0) + NVL(p_line_tax_applied,0);

           prorate_recoverable(p_receipt_id,
                               p_trx_id, 
                               NULL,
                               l_amt,
                               p_apply_date, 
                               p_mode,
                               'N',
                               g_gt_id,
                               l_line_applied,
                               l_line_tax_applied,
                               'N',
                               p_rec_app_id); 

           IF PG_DEBUG in ('Y', 'C') 
           THEN
              debug('  g_gt_id = ' || g_gt_id);
              debug('  p_rec_app_id = ' || p_rec_app_id);
           END IF;
 
           IF nvl(g_gt_id,0) <> 0
           THEN
              p_line_applied := l_line_applied;
              p_line_tax_applied := l_line_tax_applied;
              p_line_remaining := p_line_remaining - p_line_applied;
              p_line_tax_remaining := p_line_tax_remaining - p_line_tax_applied;

              IF PG_DEBUG in ('Y', 'C') 
              THEN
                debug('  tax now prorated ');
                debug('    line_applied (post etax) = ' || 
                          l_line_applied);
                debug('    tax_applied (post etax)  = ' || 
                          l_line_tax_applied);
                debug('    line_remaining = ' || p_line_remaining);
                debug('    tax_remaining  = ' ||
                    p_line_tax_remaining);
              END IF;
           END IF; 
      ELSE
        IF PG_DEBUG in ('Y', 'C') 
        THEN
           debug('  Non-recoverable activity (' || l_rec_act_id || 
                                ')  etax skipped');
        END IF;

      END IF;

   IF PG_DEBUG in ('Y', 'C') 
   THEN
     debug('arp_etax_util.calc_applied_and_remaining()-');
   END IF;
END calc_applied_and_remaining;

/* PUBLIC FUNCTION get_discount_rate
    returns max(percentage) from ra_terms_lines_discounts
    for use in transaction tax calculations.  Note that the 
    discount is /100 to make it ready for direct use in 
    calculations. 
*/

FUNCTION get_discount_rate (p_trx_id IN NUMBER)
RETURN NUMBER  IS
BEGIN

   IF nvl(g_trx_id_for_disc, -99) = p_trx_id
   THEN
      RETURN g_rate_for_disc;
   ELSE   
      g_trx_id_for_disc := p_trx_id;

      select max(nvl(tld.discount_percent/100,0))
      into   g_rate_for_disc
      from   ra_terms_lines_discounts tld,
             ra_customer_trx          trx
      where  trx.customer_trx_id = p_trx_id
      and    trx.term_id = tld.term_id (+);

      RETURN g_rate_for_disc;
   END IF;

   RETURN 0;

END get_discount_rate;

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
 |     p_request_id NUMBER (customer_trx_id of target transaction)
 |
 |
 |  MODIFICATION HISTORY
 |    DATE          Author              Description of Changes
 |  11-JUL-2006     M Raymond           Created
 |
 *===========================================================================*/

 PROCEDURE validate_for_tax (p_request_id IN NUMBER) IS

      l_return_status   VARCHAR2(50) := FND_API.G_RET_STS_SUCCESS;
      l_msg_count       NUMBER;
      l_msg_data        VARCHAR2(2000);
--      l_trx_rec         ZX_API_PUB.transaction_rec_type;
--      l_validation_status VARCHAR2(1);
--      l_hold_codes_tbl  ZX_API_PUB.hold_codes_tbl_type;
--      l_error_count     NUMBER;
--      l_trx_number      RA_CUSTOMER_TRX.trx_number%type;
      l_msg             VARCHAR2(2000);

/*  CURSOR c_errors IS
       select trx_id, trx_line_id, message_name, message_text
       from   zx_validation_errors_gt
       where  application_id = l_trx_rec.application_id
       and    entity_code    = l_trx_rec.entity_code
       and    event_class_code = l_trx_rec.event_class_code
       and    trx_id           = l_trx_rec.trx_id;
*/
 BEGIN
   IF PG_DEBUG in ('Y', 'C')
   THEN
     debug('arp_etax_util.validate_for_tax()+');
   END IF;


    DELETE from ZX_TRX_HEADERS_GT zx 
    WHERE  application_id = 222 
    AND    entity_code = 'TRANSACTIONS' 
    AND    (trx_id, event_class_code) IN 
    (SELECT trx.customer_trx_id, decode(t.type, 'INV', 'INVOICE', 
    'CM', 'CREDIT_MEMO', 'DM','DEBIT_MEMO') 
    FROM   ra_customer_trx trx,  ra_cust_trx_types t 
    WHERE  trx.request_id = p_request_id 
    AND   trx.complete_flag = 'N' 
    AND   trx.cust_trx_type_id = t.cust_trx_type_id 
    AND   trx.org_id = t.org_id); 


    IF PG_DEBUG in ('Y', 'C') THEN
       debug('before calling etax bulk processing api ');
    END IF;
    zx_api_pub.validate_document_for_tax(
                     p_api_version      => 1.0,
                     p_init_msg_list    => FND_API.G_TRUE,
                     p_commit           => FND_API.G_FALSE,
                     p_validation_level => NULL,
                     x_return_status    => l_return_status,
                     x_msg_count        => l_msg_count,
                     x_msg_data         => l_msg_data);
    IF PG_DEBUG in ('Y', 'C') THEN
       debug('after calling etax bulk processing api');
    END IF;

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS
    THEN
       /* Retrieve and log errors */
       IF l_msg_count = 1
       THEN
          debug(l_msg_data);
       ELSIF l_msg_count > 1
       THEN
          LOOP
            l_msg := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,
                                     FND_API.G_FALSE);
            IF l_msg IS NULL
            THEN
               EXIT;
            ELSE
              debug(l_msg);
            END IF;
          END LOOP;
       END IF;
    END IF;

   IF PG_DEBUG in ('Y', 'C')
   THEN
     debug('arp_etax_util.validate_for_tax()-');
   END IF;

 END validate_for_tax;

/*===========================================================================+
 | FUNTION                                                                   |
 |    get_taxpayer_masked_value                                              |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns masked taxpayer value depending on profile option value        |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |         arp_standard.debug                                                |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |               p_unmasked_value     Value to mask 			     |
 |                                                                           |
 |                                                                           |
 | RETURNS    :Masked value                                                  |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     01-feb-14          kgnanase      	Created  (Bug 17176393)      |
 +===========================================================================*/

 FUNCTION get_taxpayer_masked_value(p_unmasked_value  IN VARCHAR2 )
   RETURN VARCHAR2
   IS
     l_profile_value    VARCHAR2(30);
     l_len  NUMBER;
     l_masked_value  VARCHAR2(15);
   BEGIN

     l_len := LENGTH(p_unmasked_value);

      IF l_len < 4  THEN
     	   RETURN p_unmasked_value; 
      END IF;

     l_profile_value := NVL(FND_PROFILE.value ( 'MASK_TAX_PAYER_ID' ), 'NO MASK');


     IF l_profile_value = 'F' THEN /*FIRST FOUR VISIBLE*/
       l_masked_value := SUBSTR(p_unmasked_value, 1, 4);
       RETURN RPAD(l_masked_value, l_len, '*');
     ELSIF l_profile_value = 'L' THEN /* LAST FOUR VISIBLE */
       l_masked_value := SUBSTR(p_unmasked_value, -4, 4);
       RETURN LPAD(l_masked_value, l_len, '*');
     ELSE
       RETURN p_unmasked_value;
     END IF;

   EXCEPTION
     WHEN OTHERS THEN
       arp_standard.debug (' get_taxpayer_masked_value error = ' || sqlerrm);
   END get_taxpayer_masked_value;
/*========================================================================
 | INITIALIZATION SECTION             
 |
 | DESCRIPTION
 |    Initialized global variables for controlling program flow
 |
 | KNOWN ISSUES
 | 
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 28-FEB-2005           MRAYMOND          Created    
 | 10-SEP-2008           MRAYMOND       7329586 - Removed schema logic
 *=======================================================================*/

BEGIN
   NULL;
END XX_ARP_ETAX_UTIL; 
/

COMMIT;
EXIT;