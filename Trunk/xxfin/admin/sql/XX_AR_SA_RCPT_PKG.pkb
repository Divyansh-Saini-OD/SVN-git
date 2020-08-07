create or replace PACKAGE BODY xx_ar_sa_rcpt_pkg
AS
-- +=====================================================================================================+
-- |  Office Depot - Project Simplify                                                                    |
-- |  Providge Consulting                                                                                |
-- +====================================================================================================+|
-- |  Name:  XX_AR_SA_RCPT_PKG                                                                           |
-- |  Rice ID: I1025                                                                                     |
-- |  Description:  This package creates and applies cash receipts ppfor custom payments and             |
-- |                refund tenders made in OM.                                                           |
-- |                                                                                                     |
-- |    I1025_STATUS values (on XX_OM_LEGACY_DEPOSITS and XX_OM_RETURN_TENDERS_ALL tables)               |
-- |      NEW                          - New record (default insert value)                               |
-- |      CREATED_DEPOSIT              - Deposit receipt has been created                                |
-- |      STD_PREPAY_MATCH             - Deposit receipt can now use standard Prepayment Matching (HVOP) |
-- |      MATCHED_DEPOSIT              - Deposit  receipt has been matched to invoice (no longer used)   |
-- |      CANCELLED                    - Deposit receipt has been fully refunded (deposit cancelled)     |
-- |      MANUAL_REVERSE               - Deposit receipt has been manually reversed (voided)             |
-- |      FOUND_ORIGINAL               - Found original receipt for the refund/credit memo               |
-- |      CREATED_ZERO_DOLLAR          - Zero-Dollar receipt has been created (in place of original)     |
-- |      APPLIED_ORIGINAL             - Original receipt has been applied to the Credit Memo            |
-- |      APPLIED_ZERO_DOLLAR          - Zero-Dollar receipt has been applied to the Credit Memo         |
-- |      MATCHED_ORIGINAL             - Original Receipt has been full matched (unapplied amount has    |
-- |                                     has been written off with the appropriate recv activity)        |
-- |      MATCHED_ZERO_DOLLAR          - Zero-Dollar Receipt has been full matched (unapplied amount has |
-- |                                     has been written off with the appropriate recv activity)        |
-- |      MAILCHECK_HOLD               - Receipt flagged so E0055 can pay the customer via mailcheck     |
-- |      DELETED                      - Can only occur if manually updated (logical delete)             |
-- |      CREATED_ZERO_DOLLAR_MULTI    - Zero-Dollar receipt has been created (in place of original)     |
-- |                                     for Multitender Deposit Refunds                                 |
-- |      MATCHED_ORIGINAL_DEPOSIT     - Original Receipt has been full matched (unapplied amount has    |
-- |                                     has been written off with the appropriate recv activity)  for   |
-- |                                     Multitender Deposit Refunds                                     |
-- |      MATCHED_ZERO_DOLLAR_DEPOSIT  - Zero-Dollar Receipt has been full matched (unapplied amount has |
-- |                                     has been written off with the appropriate recv activity)        |
-- |  Change Record:                                                                                     |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  =============        ======================================================|
-- | 1.0         10-Jun-2007  B.Looman             Initial version                                       |
-- | 1.1         17-Oct-2008  Anitha D             Fix for Defect 11555                                  |
-- | 1.2         05-Nov-2008  Anitha D             Fix for Defect 12289                                  |
-- | 1.3         12-Aug-2009  Gokila Tamilselvam   Fix for Defect 1861                                   |
-- | 1.4         25-Aug-2010  Priyanka Nagesh      Fix for CR 722(Defect 6033)  to handle Mulltitender   |
-- |                                               Deposit Refunds.                                      |
-- | 2.0         11-Mar-2011  Vamshi Katta         SDR Changes for inserting records into custom receipt |
-- |                          Gaurav Agarwal       table.                                                |
-- | 2.1         16-May-2011  Gaurav Agarwal       code updated for QC defect # 11516                    |
-- |                                               comment inserting orignal sale details when refund is |
-- |                                               done against the original sale                        |
-- |                                               populate process_code as I1025 in order_receipt_dtl   |
-- |                                               table                                                 |
-- |                                               *Defect 11528 > Populate receipt_date in Order receipt|
-- |                                               details table without a timstamp                      |
-- |                                               *Defect 11561 > inserting duplicate return order infor|
-- |                                                in order receipt detail table.                       |
-- |                                                Sol - fetch record based on rowid insted of header id|
-- |                                               *Defect 12105 > AR I1025 - Deposits being inserted    |
-- |                                                into XX_AR_ORDER_RECEIPT_DTL with Wrong ORG_ID       |
-- | 2.2         08-Aug-2011  Gaurav Agarwal        POST SDR Changes for defect 13201                    |
-- |                                                Deposit reversals are not getting written off.       |
-- |                                                Search with 8/8/2011                                 |
-- | 2.3         16-Sep-2011  Gaurav Agarwal        For deposit reversal  ( Credit Card ) to have a      |
-- |                                                comment indicating single payment                    |
-- | 2.5         05-OCT-2011  Aravind A.            Fix for Defect 14071, multi tender deposit refunds   |
-- | 2.6         24-Oct-2011  Gaurav Agarwal        Fix for defect 14563 , 1025- Multi-tender deposit    |
-- |                                                reversal for single payment not clearing prepayments |
-- | 2.7         08-Dec-2011  Abdul Khan            Modified c_legacy_deposits cursor for QC Defect 13620|
-- |                                                Inserting the credit_card_code from OD_PAYMENT_TYPES |
-- | 2.8         13-SEP-2012  Ankit Arora           Modified lcu_create_deposits cursor for QC Defect    |
-- |                                                20281                                                |
-- | 2.9         27-DEC-2012  Bapuji Nanapaneni     Create zero dollar rcpt even if orig rcpt found for  |
-- |                                                PAYPAL transaction defect#21242                      |
-- | 3.0         10-APR-2013  Bapuji Nanapaneni     SET REMITTED FLAG TO 'Y' for PP tran DEFECT # 23070  |
-- | 3.1         25-Jun-2013  Abdul Khan            Modified logic for getting value of attribute7 while |
-- |                                                setting additional receipt information. Defect 24032 |
-- | 3.2         03-JUL-2013  Bapuji Nanapaneni     AMAZON Changes                                       |
-- | 3.3         12-JUL-2013  Bapuji Nanapaneni     RetorFit for 12i                                     |
-- | 3.4         29-AUG-2013  Edson Morales         R12 Encryption Changes                               |
-- | 3.5         25-SEPT-2013 Edson Morales         Fix for defect 25608                                 |
-- | 3.6         22-OCT-2013  Edson Morales         Fix for defect 25835                                 |
-- | 3.7         01-NOV-2013  Edson Morales         Fix for defect 26277                                 |
-- | 4.0         04-Feb-2014  Edson Morales         Changes for Defect 27883                             |
-- | 5.0         15-MAR-2014  Edson Morales         Fix for defect 28950                                 |
-- | 6.0         15-Jul-2014  Suresh Ponnambalam    OMX Gift Card Consolidation                          |
-- | 7.0         14-Nov-2014  Kirubha Samuel        Fix for defect 32362                                 |
-- | 8.0         02-Feb-2015  Avinash Baddam        Changes for AMZ MPLFix for defect 33473              |
-- | 9.0         17-Jun-2015  Arun Gannarapu        Made changes to update the token flag for            |
-- |                                                tokenization project                                 |
-- | 10.0        23-JUL-2015  Arun Gannarapu        Made changes to default N for                        |
-- |                                                tokenization fields 35134                            |
-- | 11.0        09-SEP-2015  Rakesh Polepalli      Modified create_refund_receipts for defect 25731     |
-- | 12.0	 	 12-NOV-2015  Vasu Raparla	    	Removed Schema References for R12.2                  |
-- | 13.0        03-MAR-2016  Arun Gannarapu        Made changes to support Master Pass 37172            |
-- | 14.0        05-JUL-2016  Rakesh Polepalli      Modified create_refund_receipts for defect 38421     |
-- | 15.0        07-FEB-2017  Havish Kasina         Added hint to improve the performance                |
-- | 16.0        03-MAY-2018  Theja Rajula			EBAY Market Place									 |
-- | 17.0        17-MAY-2018  Havish Kasina         Market Place Expansion - AR Changes for adding new   |
-- |                                                translations.To make the code configurable for future| 
-- |                                                market places(Defect NAIT-42023)                     |
-- +=====================================================================================================+
    gb_debug                           BOOLEAN                        DEFAULT TRUE;   -- print debug/log output
    gn_return_code                     NUMBER                         DEFAULT 0;   -- master program conc status
    gn_err_record_locked      CONSTANT NUMBER                         := -20054;
    gn_err_deadlock_detected  CONSTANT NUMBER                         := -20060;
    gn_receipt_method                  ar_receipt_methods.NAME%TYPE;   -- Added for Defect 12289
    -- Profiles:
    --  XX_AR_1025_MESSAGE_LOGGING_LEVEL: profile level for recording messages
    --   0 for no messages
    --   1 for only errors
    --   2 for errors and warnings
    --   3 for all messages (errors, warnings, and info) - DEFAULTS to ALL messages
    --  XX_AR_I1025_REFUND_AMT_TOLERANCE: Refund Amount Tolerance (difference in refund amount
    --     and credit memo amount due remaining)
    --  XX_AR_I1025_COMMIT_INTERVAL: Commit Interval (how often to commit records
    gn_commit_interval                 NUMBER                         DEFAULT 100;   -- interval for commits (profile)
    gn_i1025_message_level             NUMBER                         DEFAULT 3;   -- message logging level (profile)
    gn_refund_tolerance                NUMBER                         DEFAULT 0;   -- refund tolerance (profile)
    --GC_DISABLE_EXPIRED_CC_WORKARND VARCHAR2(10) DEFAULT 'N';  -- disable expired cc work-around (profile)
    gd_program_run_date                DATE                           DEFAULT SYSDATE;
    -- get the current date when first used
    gn_cc_aops_deposits_num            NUMBER                         DEFAULT 0;
                                                                                -- number of CC AOPS Deposits processed
    -- global variables for total number of records
    gn_create_deposits_num             NUMBER                         DEFAULT 0;   -- number of deposit records
    gn_create_refunds_num              NUMBER                         DEFAULT 0;   -- number of refund records
    --GN_APPLY_DEPOSITS_NUM      NUMBER          DEFAULT 0;     -- number of deposit records to apply
    gn_apply_refunds_num               NUMBER                         DEFAULT 0;   -- number of refund records to apply
    -- global variables for successful records
    gn_create_deposits_good            NUMBER                         DEFAULT 0;   -- number of deposit records
    gn_create_refunds_good             NUMBER                         DEFAULT 0;   -- number of refund records
    --GN_APPLY_DEPOSITS_GOOD     NUMBER          DEFAULT 0;     -- number of deposit records to apply
    gn_apply_refunds_good              NUMBER                         DEFAULT 0;   -- number of refund records to apply
    -- global variables for errored records
    gn_create_deposits_err             NUMBER                         DEFAULT 0;   -- number of deposit records
    gn_create_refunds_err              NUMBER                         DEFAULT 0;   -- number of refund records
    --GN_APPLY_DEPOSITS_ERR      NUMBER          DEFAULT 0;     -- number of deposit records to apply
    gn_apply_refunds_err               NUMBER                         DEFAULT 0;   -- number of refund records to apply
    gc_process_flag                    VARCHAR2(1)                    DEFAULT NULL;   -- V2.0
    gn_amount_rcpt_bal                 NUMBER                         DEFAULT 0;

    -- record type to hold record process status
    TYPE gt_rec_status IS RECORD(
        process_code           VARCHAR2(1),
        record_status          VARCHAR2(20),
        MESSAGE                VARCHAR2(4000),
        orig_sys_document_ref  VARCHAR2(50),
        order_number           NUMBER,
        payment_number         NUMBER,
        creation_date          DATE,
        receipt_method         VARCHAR2(100),
        amount                 NUMBER,
        receipt_number         VARCHAR2(50),
        comments               VARCHAR2(4000)
    );

    TYPE gt_rec_status_tab IS TABLE OF gt_rec_status
        INDEX BY BINARY_INTEGER;

    g_create_deposits_recs             gt_rec_status_tab;
    g_create_refunds_recs              gt_rec_status_tab;
    --G_APPLY_DEPOSITS_RECS          GT_REC_STATUS_TAB;
    g_apply_refunds_recs               gt_rec_status_tab;

    TYPE gt_current_record IS RECORD(
        record_type                  VARCHAR2(20),
        xx_payment_rowid             ROWID,
        orig_sys_document_ref        oe_order_headers.orig_sys_document_ref%TYPE,
        bill_to_customer_id          hz_cust_accounts.cust_account_id%TYPE,
        bill_to_site_use_id          hz_cust_site_uses.site_use_id%TYPE,
        party_id                     hz_parties.party_id%TYPE,
        bill_to_customer             hz_parties.party_name%TYPE,
        org_id                       oe_order_headers.org_id%TYPE,
        header_id                    oe_order_headers.header_id%TYPE,
        order_number                 oe_order_headers.order_number%TYPE,
        ordered_date                 oe_order_headers.ordered_date%TYPE,
        payment_number               oe_payments.payment_number%TYPE,
        payment_set_id               oe_payments.payment_set_id%TYPE,
        payment_type_code            oe_payments.payment_type_code%TYPE,
        payment_type_new             VARCHAR2(50),
        credit_card_code             oe_payments.credit_card_code%TYPE,
        credit_card_number           xx_ar_order_receipt_dtl.credit_card_number%TYPE,
        credit_card_holder_name      oe_payments.credit_card_holder_name%TYPE,
        credit_card_expiration_date  oe_payments.credit_card_expiration_date%TYPE,
        credit_card_approval_code    oe_payments.credit_card_approval_code%TYPE,
        credit_card_approval_date    oe_payments.credit_card_approval_date%TYPE,
        check_number                 oe_payments.check_number%TYPE,
        line_id                      oe_order_lines.line_id%TYPE,
        currency_code                fnd_currencies.currency_code%TYPE,
        receipt_method_id            ar_receipt_methods.receipt_method_id%TYPE,
        receipt_method               ar_receipt_methods.NAME%TYPE,
        receipt_class_id             ar_receipt_classes.receipt_class_id%TYPE,
        receipt_class                ar_receipt_classes.NAME%TYPE,
        cash_receipt_id              ar_cash_receipts.cash_receipt_id%TYPE,
        receipt_number               ar_cash_receipts.receipt_number%TYPE,
        receipt_appl_status          ar_cash_receipt_history.status%TYPE,
        original_receipt_date        ar_cash_receipts.receipt_date%TYPE,
        receipt_status               ar_cash_receipts.status%TYPE,
        i1025_process_code           ar_cash_receipts.attribute13%TYPE,
        customer_trx_id              ra_customer_trx.customer_trx_id%TYPE,
        trx_date                     ra_customer_trx.trx_date%TYPE,
        trx_number                   ra_customer_trx.trx_number%TYPE,
        trx_type                     oe_transaction_types_tl.NAME%TYPE,
        payment_schedule_id          ar_payment_schedules.payment_schedule_id%TYPE,
        amount_due_remaining         ar_payment_schedules.amount_due_remaining%TYPE,
        payment_schedule_status      ar_payment_schedules.status%TYPE,
        i1025_status                 VARCHAR2(50),
        debit_card_approval_ref      VARCHAR2(100),
        amount                       NUMBER,
        cc_auth_ps2000               VARCHAR2(240),
        cc_auth_manual               VARCHAR2(240),
        cc_mask_number               VARCHAR2(240),
        merchant_number              VARCHAR2(240),
        od_payment_type              VARCHAR2(240),
        creation_date                DATE,
        receipt_date                 DATE,
        paid_at_store_id             NUMBER,
        sale_location                VARCHAR2(30),
        ship_from_org_id             NUMBER,
        ship_from_org                VARCHAR2(30),
        process_code                 VARCHAR2(1),
        cc_entry_mode                VARCHAR2(10),
        cvv_resp_code                VARCHAR2(10),
        avs_resp_code                VARCHAR2(10),
        auth_entry_mode              VARCHAR2(10),
        payment_type_flag            VARCHAR2(20),
        deposit_reversal_flag        VARCHAR2(1),
        transaction_number           VARCHAR2(50),
        imp_file_name                VARCHAR2(100),
        om_import_date               DATE,
        single_pay_ind               VARCHAR2(1),
        ref_legacy_order_num         oe_order_headers.orig_sys_document_ref%TYPE,
        IDENTIFIER                   xx_ar_order_receipt_dtl.IDENTIFIER%TYPE
    );

    TYPE gt_original IS RECORD(
        org_id                    oe_order_headers.org_id%TYPE,
        orig_sys_document_ref     oe_order_headers.orig_sys_document_ref%TYPE,
        header_id                 oe_order_headers.header_id%TYPE,
        order_number              oe_order_headers.order_number%TYPE,
        customer_trx_id           ra_customer_trx.customer_trx_id%TYPE,
        trx_date                  ra_customer_trx.trx_date%TYPE,
        trx_number                ra_customer_trx.trx_number%TYPE,
        cash_receipt_id           ar_cash_receipts.cash_receipt_id%TYPE,
        receipt_number            ar_cash_receipts.receipt_number%TYPE,
        receipt_appl_status       ar_cash_receipt_history.status%TYPE,
        receipt_status            ar_cash_receipts.status%TYPE,
        receipt_date              ar_cash_receipts.receipt_date%TYPE,
        receipt_amount            ar_cash_receipts.amount%TYPE,
        pay_from_customer         ar_cash_receipts.pay_from_customer%TYPE,
        customer_bank_account_id  ar_cash_receipts.customer_bank_account_id%TYPE,
        customer_site_use_id      ar_cash_receipts.customer_site_use_id%TYPE,
        receipt_method_id         ar_receipt_methods.receipt_method_id%TYPE,
        receipt_method            ar_receipt_methods.NAME%TYPE,
        receipt_class_id          ar_receipt_classes.receipt_class_id%TYPE,
        receipt_class             ar_receipt_classes.NAME%TYPE,
        amount_applied            ar_receivable_applications.amount_applied%TYPE,
        application_type          ar_receivable_applications.application_type%TYPE,
        application_status        ar_receivable_applications.status%TYPE,
        credit_card_number        xx_ar_order_receipt_dtl.credit_card_number%TYPE,
        IDENTIFIER                xx_ar_order_receipt_dtl.IDENTIFIER%TYPE
    );

-- ==========================================================================
-- customer primary info cursor (by cust_account_id)
-- ==========================================================================
    CURSOR gcu_customer_id(
        cp_org_id           IN  NUMBER,
        cp_cust_account_id  IN  NUMBER)
    IS
        SELECT hca.cust_account_id,
               hp.party_id,
               hp.party_name customer_name,
               hca.account_number,
               hcas.cust_acct_site_id,
               hcsu.site_use_id
        FROM   hz_parties hp, hz_cust_accounts hca, hz_cust_acct_sites_all hcas, hz_cust_site_uses_all hcsu
        WHERE  hp.party_id = hca.party_id
        AND    hca.cust_account_id = hcas.cust_account_id
        AND    hcas.cust_acct_site_id = hcsu.cust_acct_site_id
        AND    hcas.org_id = cp_org_id
        AND    hca.cust_account_id = cp_cust_account_id
        AND    hcsu.site_use_code = 'BILL_TO'
        AND    hcsu.primary_flag = 'Y';

-- ==========================================================================
-- invoice information for a given order
-- ==========================================================================
    CURSOR gcu_om_invoice(
        cp_header_id  IN  NUMBER)
    IS
        SELECT rct.customer_trx_id,
               rct.trx_number,
               rct.status_trx,
               aps.payment_schedule_id,
               aps.amount_due_remaining,
               aps.status
        FROM   ra_customer_trx_all rct,
               ar_payment_schedules_all aps,
               oe_order_headers_all ooh,
               oe_transaction_types_tl ott
        WHERE  ooh.order_type_id = ott.transaction_type_id
        AND    rct.customer_trx_id = aps.customer_trx_id
        AND    aps.CLASS = 'INV'
        AND    rct.interface_header_attribute2 = ott.NAME
        AND    rct.interface_header_attribute1 = ooh.order_number
        AND    rct.interface_header_context = fnd_profile.VALUE('SO_SOURCE_CODE')
        AND    ooh.header_id = cp_header_id;

-- ==========================================================================
-- legacy deposits from OM
-- ==========================================================================
    CURSOR gcu_deposits(
        cp_org_id                  IN  NUMBER,
        cp_from_date               IN  DATE,
        cp_to_date                 IN  DATE,
        cp_request_id              IN  NUMBER DEFAULT NULL,
        cp_orig_sys_document_ref   IN  VARCHAR2 DEFAULT NULL,
        cp_only_deposit_reversals  IN  VARCHAR2 DEFAULT 'N',
        cp_child_process_id        IN  VARCHAR2 DEFAULT NULL)
    IS
        SELECT   xold.ROWID,
                 --xold.orig_sys_document_ref,   -- commented by Gaurav v2.0
                 NVL(xold.orig_sys_document_ref,
                     DECODE(NVL(xold.single_pay_ind,
                                'N'),
                            'N', (SELECT orig_sys_document_ref
                                  FROM   xx_om_legacy_dep_dtls xoldd1
                                  WHERE  xoldd1.transaction_number = xold.transaction_number
                                  AND    ROWNUM = 1),
--xold.orig_sys_document_ref   -- commented by Gaurav to pass xold.transaction_number as xold.orig_sys_document_ref in case of single payment.
                            xold.transaction_number) ) orig_sys_document_ref,
                 xold.sold_to_org_id,
                 hp.party_name sold_to_org,
                 hca.party_id,
                 xold.org_id,
                 xold.header_id,
                 (SELECT order_number
                  FROM   oe_order_headers_all
                  WHERE  header_id = xold.header_id) order_number,
                 TRUNC(SYSDATE) ordered_date,
                 xold.payment_number,
                 xold.payment_set_id,
                 xold.payment_type_code,
                 xold.credit_card_code,
                 xold.credit_card_number,
                 xold.credit_card_holder_name,
                 xold.credit_card_expiration_date,
                 xold.credit_card_approval_code,
                 xold.credit_card_approval_date,
                 xold.check_number,
                 xold.line_id,
                 xold.currency_code,
                 xold.receipt_method_id,
                 arm.NAME receipt_method,
                 arl.receipt_class_id,
                 arl.NAME receipt_class,
                 xold.cash_receipt_id,
                 xold.prepaid_amount amount,
                 xold.cc_auth_ps2000,
                 CASE xold.cc_auth_manual
                     WHEN 'Y'
                         THEN '1'
                     ELSE '2'
                 END cc_auth_manual,
                 xold.cc_mask_number,
                 xold.merchant_number,
                 xold.od_payment_type,
                 xold.debit_card_approval_ref,
                 xold.i1025_status,
                 xold.creation_date,
                 xold.transaction_number,
                 NVL(xold.receipt_date,
                     TRUNC(SYSDATE) ) receipt_date,
                 TRUNC(SYSDATE) trx_date,   -- need an actual date here
                 (SELECT LPAD(haou.attribute1,
                              6,
                              '0')
                  FROM   hr_all_organization_units haou
                  WHERE  haou.organization_id = xold.paid_at_store_id) sale_location,
                 xold.paid_at_store_id,
                 TO_NUMBER(NULL) ship_from_org_id,
                 NULL ship_from_org,
                 xold.process_code,
                 xold.cc_entry_mode,
                 xold.cvv_resp_code,
                 xold.avs_resp_code,
                 xold.auth_entry_mode,
                 TO_DATE(NULL) om_import_date,
                 xold.imp_file_name,
                 NVL(xold.single_pay_ind,
                     'N') single_pay_ind,
                 -- if header is defined, treat as post-payment
                 CASE
                     WHEN xold.header_id IS NOT NULL
                         THEN 'POST-PAY'
                     ELSE 'PRE-PAY'
                 END payment_type_flag,
                 -- if deposit amount is negative, then treat as reversal
                 CASE
                     WHEN xold.prepaid_amount < 0
                         THEN 'Y'
                     ELSE 'N'
                 END deposit_reversal_flag,
                 xold.IDENTIFIER
        FROM     xx_om_legacy_deposits xold,
                 hz_cust_accounts hca,
                 hz_parties hp,
                 ar_receipt_methods arm,
                 ar_receipt_classes arl,
                 ar_system_parameters_all asp
        WHERE    xold.receipt_method_id = arm.receipt_method_id(+)
        AND      arm.receipt_class_id = arl.receipt_class_id(+)
        AND      xold.sold_to_org_id = hca.cust_account_id(+)
        AND      hca.party_id = hp.party_id(+)
        AND      xold.org_id = asp.org_id
        --AND xold.process_code IN ('P','E')
        AND      xold.i1025_status IN('NEW')
        AND      xold.cash_receipt_id IS NULL
        AND      xold.org_id = cp_org_id
        AND      xold.creation_date BETWEEN cp_from_date AND   cp_to_date
                                                             + 0.99999
        --    commneted by Gaurav v2.0
        --  AND  xold.orig_sys_document_ref LIKE NVL(cp_orig_sys_document_ref,'%')
        -- added by Gaurav v2.0
        AND      (   xold.orig_sys_document_ref LIKE NVL(cp_orig_sys_document_ref,
                                                         '%')   --557338107001
                  OR (EXISTS(
                          SELECT 1
                          FROM   xx_om_legacy_dep_dtls xoldd
                          WHERE  xoldd.orig_sys_document_ref LIKE NVL(cp_orig_sys_document_ref,
                                                                      '%')   --557338107001
                          AND    xoldd.transaction_number = xold.transaction_number) ) )
        -- added by Gaurav v2.0
        AND      (    (cp_request_id IS NULL)
                  OR (    cp_request_id IS NOT NULL
                      AND xold.request_id = cp_request_id) )
        AND      xold.error_flag <> 'Y'   -- exclude deposits errored during HVOP
        AND      (    (cp_only_deposit_reversals = 'N')
                  OR (    cp_only_deposit_reversals = 'Y'
                      AND xold.prepaid_amount < 0) )
        AND      (    (cp_child_process_id IS NULL)
                  OR (    cp_child_process_id IS NOT NULL
                      AND xold.i1025_process_id = cp_child_process_id) )
        ORDER BY xold.orig_sys_document_ref, xold.payment_number,   -1
                                                                  * xold.prepaid_amount;   -- sorted by amount so refunds occur after deposit

-- ==========================================================================
    TYPE gt_deposits_tab_type IS TABLE OF gcu_deposits%ROWTYPE
        INDEX BY PLS_INTEGER;

-- ==========================================================================
-- refund tenders from OM
-- ==========================================================================
    CURSOR gcu_refunds(
        cp_org_id                 IN  NUMBER,
        cp_from_date              IN  DATE,
        cp_to_date                IN  DATE,
        cp_request_id             IN  NUMBER DEFAULT NULL,
        cp_orig_sys_document_ref  IN  VARCHAR2 DEFAULT NULL,
        cp_child_process_id       IN  VARCHAR2 DEFAULT NULL)
    IS
        SELECT   xort.ROWID,
                 xort.orig_sys_document_ref,
                 ooh.sold_to_org_id,
                 hp.party_name sold_to_org,
                 hca.party_id,
                 xort.org_id,
                 xort.header_id,
                 ooh.order_number,
                 ooh.ordered_date,
                 xort.payment_number,
                 xort.payment_set_id,
                 xort.payment_type_code,
                 xort.credit_card_code,
                 xort.credit_card_number,
                 xort.credit_card_holder_name,
                 xort.credit_card_expiration_date,
                 NULL credit_card_approval_code,
                 TO_DATE(NULL) credit_card_approval_date,
                 xort.line_id,
                 qlh.currency_code,
                 xort.receipt_method_id,
                 arm.NAME receipt_method,
                 arl.receipt_class_id,
                 arl.NAME receipt_class,
                 xort.cash_receipt_id,
                 xort.credit_amount amount,
                 xort.check_number,
                 xort.cc_auth_ps2000,
                 xort.merchant_number,
                 xort.od_payment_type,
                 NULL debit_card_approval_ref,
                 xort.i1025_status,
                 CASE xort.cc_auth_manual
                     WHEN 'Y'
                         THEN '1'
                     ELSE '2'
                 END cc_auth_manual,
                 xort.cc_mask_number,
                 xort.creation_date,
                 TO_DATE(NULL) om_import_date,
                 xoha.imp_file_name,
                 NVL( (SELECT actual_shipment_date
                       FROM   oe_order_lines_all
                       WHERE  header_id = ooh.header_id
                       AND    actual_shipment_date IS NOT NULL
                       AND    ROWNUM = 1),
                     (SELECT ordered_date
                      FROM   oe_order_headers_all
                      WHERE  header_id = ooh.header_id) ) receipt_date,
                 xoha.paid_at_store_id,
                 (SELECT LPAD(haou.attribute1,
                              6,
                              '0')
                  FROM   hr_all_organization_units haou
                  WHERE  haou.organization_id = xoha.paid_at_store_id) sale_location,
                 ooh.ship_from_org_id,
                 (SELECT LPAD(haou.attribute1,
                              6,
                              '0')
                  FROM   hr_all_organization_units haou
                  WHERE  haou.organization_id = ooh.ship_from_org_id) ship_from_org,
                 xort.process_code,
                 xort.IDENTIFIER
        FROM     xx_om_return_tenders_all xort,
                 oe_order_headers_all ooh,
                 hz_cust_accounts hca,
                 hz_parties hp,
                 xx_om_header_attributes_all xoha,
                 qp_list_headers_b qlh,
                 ar_receipt_methods arm,
                 ar_receipt_classes arl,
                 ar_system_parameters_all asp
        WHERE    xort.header_id = ooh.header_id
        AND      ooh.sold_to_org_id = hca.cust_account_id
        AND      hca.party_id = hp.party_id
        AND      xort.receipt_method_id = arm.receipt_method_id(+)
        AND      arm.receipt_class_id = arl.receipt_class_id(+)
        AND      ooh.price_list_id = qlh.list_header_id(+)
        AND      xort.org_id = asp.org_id
        AND      ooh.header_id = xoha.header_id(+)
        --AND xort.process_code IN ('P','E')
        AND      xort.i1025_status IN('NEW')
        AND      xort.cash_receipt_id IS NULL
        AND      xort.org_id = cp_org_id
        AND      xort.creation_date BETWEEN cp_from_date AND   cp_to_date
                                                             + 0.99999
        AND      xort.orig_sys_document_ref LIKE NVL(cp_orig_sys_document_ref,
                                                     '%')
        AND      (    (cp_request_id IS NULL)
                  OR (    cp_request_id IS NOT NULL
                      AND xort.request_id = cp_request_id) )
        AND      (    (cp_child_process_id IS NULL)
                  OR (    cp_child_process_id IS NOT NULL
                      AND xort.i1025_process_id = cp_child_process_id) )
        ORDER BY xort.orig_sys_document_ref, xort.payment_number;

    TYPE gt_refunds_tab_type IS TABLE OF gcu_refunds%ROWTYPE
        INDEX BY PLS_INTEGER;

-- ==========================================================================
-- credit memo transactions from OM that need to be applied
-- ==========================================================================
    CURSOR gcu_refund_cms(
        cp_org_id                 IN  NUMBER,
        cp_from_date              IN  DATE,
        cp_to_date                IN  DATE,
        cp_request_id             IN  NUMBER DEFAULT NULL,
        cp_orig_sys_document_ref  IN  VARCHAR2 DEFAULT NULL,
        cp_child_process_id       IN  VARCHAR2 DEFAULT NULL)
    IS
        SELECT   /*+ index(XORT,XX_OM_RETURN_TENDERS_N6) */  -- Added hint to improve the performance by Havish Kasina Version 15.0
		         xort.ROWID,
                 rct.customer_trx_id,
                 rct.trx_date,
                 rct.trx_number,
                 rct.bill_to_customer_id,
                 rct.bill_to_site_use_id,
                 hca.party_id,
                 hp.party_name customer_name,
                   -1
                 * xort.credit_amount amount,
                 ooh.header_id,
                 ooh.order_number,
                 ooh.orig_sys_document_ref,
                 ooh.ordered_date,
                 ott.NAME trx_type,
                 xort.payment_number,
                 xort.payment_set_id,
                 xort.payment_type_code,
                 xort.check_number,
                 xort.credit_card_code,
                 xort.credit_card_number,
                 xort.credit_card_holder_name,
                 xort.credit_card_expiration_date,
                 xort.line_id,
                 qlh.currency_code,
                 xort.cc_auth_ps2000,
                 CASE xort.cc_auth_manual
                     WHEN 'Y'
                         THEN '1'
                     ELSE '2'
                 END cc_auth_manual,
                 xort.cc_mask_number,
                 xort.merchant_number,
                 xort.od_payment_type,
                 NULL debit_card_approval_ref,
                 xort.i1025_status,
                 xort.creation_date,
                 NVL( (SELECT actual_shipment_date
                       FROM   oe_order_lines_all
                       WHERE  header_id = ooh.header_id
                       AND    actual_shipment_date IS NOT NULL
                       AND    ROWNUM = 1),
                     (SELECT ordered_date
                      FROM   oe_order_headers_all
                      WHERE  header_id = ooh.header_id) ) receipt_date,
                 acr.cash_receipt_id,
                 acr.receipt_number,
                 acr.status receipt_appl_status,
                 acrh.status receipt_status,
                 acr.receipt_date original_receipt_date,
                 acr.receipt_method_id,
                 acr.attribute13 i1025_process_code,
                 arm.NAME receipt_method,
                 arl.receipt_class_id,
                 arl.NAME receipt_class,
                 xoha.paid_at_store_id,
                 TO_DATE(NULL) om_import_date,
                 xoha.imp_file_name,
                 (SELECT LPAD(haou.attribute1,
                              6,
                              '0')
                  FROM   hr_all_organization_units haou
                  WHERE  haou.organization_id = xoha.paid_at_store_id) sale_location,
                 ooh.ship_from_org_id,
                 (SELECT LPAD(haou.attribute1,
                              6,
                              '0')
                  FROM   hr_all_organization_units haou
                  WHERE  haou.organization_id = ooh.ship_from_org_id) ship_from_org,
                 rct.org_id,
                 aps.payment_schedule_id,
                 aps.amount_due_remaining,
                 aps.status payment_schedule_status,
                 acr.pay_from_customer receipt_customer_id,
                 xort.IDENTIFIER
        FROM     ar_cash_receipts_all acr,
                 ar_cash_receipt_history_all acrh,
                 xx_om_return_tenders_all xort,
                 ar_receipt_methods arm,
                 ar_receipt_classes arl,
                 ra_customer_trx_all rct,
                 hz_cust_accounts hca,
                 hz_parties hp,
                 ar_payment_schedules_all aps,
                 ra_cust_trx_types_all rctt,
                 oe_order_headers_all ooh,
                 xx_om_header_attributes_all xoha,
                 qp_list_headers_b qlh,
                 oe_transaction_types_tl ott
        WHERE    rct.cust_trx_type_id = rctt.cust_trx_type_id
        AND      rct.bill_to_customer_id = hca.cust_account_id
        AND      hca.party_id = hp.party_id
        AND      ooh.order_type_id = ott.transaction_type_id
        AND      ooh.price_list_id = qlh.list_header_id(+)
        AND      rct.customer_trx_id = aps.customer_trx_id
        AND      ooh.header_id = xoha.header_id(+)
        --AND ooh.header_id = acr.attribute12
        AND      ooh.header_id = xort.header_id
        AND      acr.cash_receipt_id = xort.cash_receipt_id
        AND      acr.cash_receipt_id = acrh.cash_receipt_id
        --AND rct.bill_to_customer_id = acr.pay_from_customer
        AND      acr.receipt_method_id = arm.receipt_method_id
        AND      arm.receipt_class_id = arl.receipt_class_id
        AND      acrh.current_record_flag = 'Y'
        AND      rct.interface_header_context = fnd_profile.VALUE('SO_SOURCE_CODE')
        AND      rct.interface_header_attribute2 = ott.NAME
        AND      rct.interface_header_attribute1 = TO_CHAR(ooh.order_number)
        AND      acr.TYPE = 'CASH'
        --AND acr.attribute_category = 'SALES_ACCT'
        --AND acr.attribute11 = 'REFUND'
        --AND acr.attribute13 LIKE 'CREATED|%'
        AND      rct.status_trx = 'OP'
        --AND aps.class = 'CM'
        AND      aps.status = 'OP'
        AND      xort.i1025_status IN('CREATED_ZERO_DOLLAR', 'FOUND_ORIGINAL')
        AND      rct.org_id = cp_org_id
        AND      xort.creation_date BETWEEN cp_from_date AND   cp_to_date
                                                             + 0.99999
        AND      xort.orig_sys_document_ref LIKE NVL(cp_orig_sys_document_ref,
                                                     '%')
        --  AND xort.orig_sys_document_ref LIKE NVL('08582009072100101692' ,'%')
        AND      (    (cp_request_id IS NULL)
                  OR (    cp_request_id IS NOT NULL
                      AND xort.request_id = cp_request_id) )
        AND      (    (cp_child_process_id IS NULL)
                  OR (    cp_child_process_id IS NOT NULL
                      AND xort.i1025_process_id = cp_child_process_id) )
        ORDER BY xort.orig_sys_document_ref, xort.payment_number;

    TYPE gt_refund_cms_tab_type IS TABLE OF gcu_refund_cms%ROWTYPE
        INDEX BY PLS_INTEGER;

-- ==========================================================================
-- procedure to turn on/off debug
-- ==========================================================================
    PROCEDURE set_debug(
        p_debug  IN  BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        gb_debug := p_debug;
    END;

-- ==========================================================================
-- procedure to change debug to char (FND_API type)
-- ==========================================================================
    FUNCTION get_debug_char
        RETURN VARCHAR2
    IS
    BEGIN
        IF (gb_debug)
        THEN
            RETURN fnd_api.g_true;
        ELSE
            RETURN fnd_api.g_false;
        END IF;
    END;

-- ==========================================================================
-- procedure for printing to the output
-- ==========================================================================
    PROCEDURE put_out_line(
        p_buffer  IN  VARCHAR2 DEFAULT ' ')
    IS
    BEGIN
        -- if in concurrent program, print to output file
        IF (fnd_global.conc_request_id > 0)
        THEN
            fnd_file.put_line(fnd_file.output,
                              NVL(p_buffer,
                                  ' ') );
        -- else print to DBMS_OUTPUT
        ELSE
            DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,
                                            ' '),
                                        1,
                                        255) );
        END IF;
    END;

-- ==========================================================================
-- procedure for printing to the log
-- ==========================================================================
    PROCEDURE put_log_line(
        p_buffer  IN  VARCHAR2 DEFAULT ' ',
        p_force   IN  BOOLEAN DEFAULT FALSE)
    IS
    BEGIN
        --if debug is on (defaults to true)
        IF (   gb_debug
            OR p_force)
        THEN
            -- if in concurrent program, print to log file
            IF (fnd_global.conc_request_id > 0)
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  NVL(   TO_CHAR(SYSTIMESTAMP,
                                                 'HH24:MI:SS.FF: ')
                                      || p_buffer,
                                      ' ') );
            -- else print to DBMS_OUTPUT
            ELSE
                DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,
                                                ' '),
                                            1,
                                            255) );
            END IF;
        END IF;
    END;

-- ==========================================================================
-- procedure for printing to the log a separator line
-- ==========================================================================
    PROCEDURE put_log_separator(
        p_buffer  IN  VARCHAR2 DEFAULT ' ')
    IS
    BEGIN
        put_log_line('===========================================================================');
    END;

-- ==========================================================================
-- procedure for printing to the log the current datetime
-- ==========================================================================
    PROCEDURE put_current_datetime(
        p_buffer  IN  VARCHAR2 DEFAULT ' ')
    IS
    BEGIN
        NULL;
    --put_log_line('== ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS') || ' ==');
    END;

-- ==========================================================================
-- function to get the current timestamp (number in seconds)
-- ==========================================================================
    FUNCTION get_timestamp
        RETURN NUMBER
    IS
        l_time  TIMESTAMP := SYSTIMESTAMP;
    BEGIN
        RETURN(   (   (   (   (    EXTRACT(DAY FROM l_time)
                                 * 24
                               + EXTRACT(HOUR FROM l_time) )
                           * 60)
                       + EXTRACT(MINUTE FROM l_time) )
                   * 60)
               + EXTRACT(SECOND FROM l_time) );
    END;

-- ==========================================================================
-- procedure wrapper for clearing I1025 messages
-- ==========================================================================
    PROCEDURE clear_messages(
        p_current_row  IN OUT NOCOPY  gt_current_record)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'CLEAR_MESSAGES';
    BEGIN
        xx_ar_prepayments_pkg.clear_i1025_messages(p_i1025_record_type =>          p_current_row.record_type,
                                                   p_orig_sys_document_ref =>      p_current_row.orig_sys_document_ref,
                                                   p_payment_number =>             p_current_row.payment_number,
                                                   p_request_id =>                 NVL(fnd_global.conc_request_id,
                                                                                       -1) );
    END;

-- ==========================================================================
-- procedure wrapper for adding a message for errors/warnings/info
-- ==========================================================================
    PROCEDURE add_message(
        p_current_row     IN OUT NOCOPY  gt_current_record,
        p_message_code    IN             VARCHAR2,
        p_message_text    IN             VARCHAR2,
        p_error_location  IN             VARCHAR2,
        p_message_type    IN             VARCHAR2 DEFAULT xx_ar_prepayments_pkg.gc_i1025_msg_type_error)
    IS
        lc_sub_name      CONSTANT VARCHAR2(50) := 'ADD_MESSAGE';
        lc_orig_sys_document_ref  VARCHAR2(50);
    BEGIN
        IF p_current_row.orig_sys_document_ref IS NOT NULL
        THEN
            xx_ar_prepayments_pkg.insert_i1025_message(p_i1025_record_type =>          p_current_row.record_type,
                                                       p_orig_sys_document_ref =>      p_current_row.orig_sys_document_ref,
                                                       p_payment_number =>             p_current_row.payment_number,
                                                       p_program_run_date =>           gd_program_run_date,
                                                       p_request_id =>                 NVL(fnd_global.conc_request_id,
                                                                                           -1),
                                                       p_message_code =>               p_message_code,
                                                       p_message_text =>               p_message_text,
                                                       p_error_location =>             p_error_location,
                                                       p_message_type =>               p_message_type);
        ELSE
            BEGIN
                SELECT DECODE(a.single_pay_ind,
                              'Y', a.transaction_number,
                              NVL(a.orig_sys_document_ref,
                                  b.orig_sys_document_ref) )
                INTO   lc_orig_sys_document_ref
                FROM   xx_om_legacy_deposits a, xx_om_legacy_dep_dtls b
                WHERE  a.transaction_number = p_current_row.transaction_number
                AND    a.transaction_number = b.transaction_number(+)
                AND    ROWNUM = 1;

                xx_ar_prepayments_pkg.insert_i1025_message(p_i1025_record_type =>          p_current_row.record_type,
                                                           p_orig_sys_document_ref =>      lc_orig_sys_document_ref,
                                                           p_payment_number =>             p_current_row.payment_number,
                                                           p_program_run_date =>           gd_program_run_date,
                                                           p_request_id =>                 NVL
                                                                                               (fnd_global.conc_request_id,
                                                                                                -1),
                                                           p_message_code =>               p_message_code,
                                                           p_message_text =>               p_message_text,
                                                           p_error_location =>             p_error_location,
                                                           p_message_type =>               p_message_type);
            EXCEPTION
                WHEN OTHERS
                THEN
                    IF (gb_debug)
                    THEN
                        put_log_line();
                        put_log_line(   'Exception in ADD_MESSAGE  : '
                                     || SQLERRM);
                    END IF;
            END;
        END IF;
    END;

-- ==========================================================================
-- raise errors generated by an Oracle API
-- ==========================================================================
    PROCEDURE raise_api_errors(
        p_sub_name   IN  VARCHAR2,
        p_msg_count  IN  NUMBER,
        p_api_name   IN  VARCHAR2)
    IS
        lc_api_errors  VARCHAR2(2000) DEFAULT NULL;
    BEGIN
-- ==========================================================================
-- get API errors from the standard FND_MSG_PUB message stack
-- ==========================================================================
        FOR idx IN 1 .. p_msg_count
        LOOP
            IF (lc_api_errors IS NOT NULL)
            THEN
                lc_api_errors :=    lc_api_errors
                                 || CHR(10);
            END IF;

            lc_api_errors :=    lc_api_errors
                             || '  '
                             || idx
                             || ': '
                             || fnd_msg_pub.get(idx,
                                                'F');
        END LOOP;

-- ==========================================================================
-- if API errors generated, then push errors to message stack
-- ==========================================================================
        fnd_message.set_name('XXFIN',
                             'XX_AR_I1025_20002_API_ERRORS');
        fnd_message.set_token('SUB_NAME',
                              p_sub_name);
        fnd_message.set_token('API_NAME',
                              p_api_name);
        fnd_message.set_token('API_ERRORS',
                              lc_api_errors);
        raise_application_error(-20002,
                                fnd_message.get() );
    END;

-- ==========================================================================
-- raise errors for missing parameters
-- ==========================================================================
    PROCEDURE raise_missing_param_errors(
        p_sub_name    IN  VARCHAR2,
        p_param_name  IN  VARCHAR2)
    IS
    BEGIN
        fnd_message.set_name('XXFIN',
                             'XX_AR_I1025_20001_MISS_PARAM');
        fnd_message.set_token('SUB_NAME',
                              p_sub_name);
        fnd_message.set_token('PARAMETER',
                              p_param_name);
        raise_application_error(-20001,
                                fnd_message.get() );
    END;

-- ==========================================================================
-- Decrypt Credit Card.
-- ==========================================================================
    PROCEDURE decrypt_credit_card(
        p_credit_card_number_enc  IN             xx_ar_order_receipt_dtl.credit_card_number%TYPE,
        p_identifier              IN             xx_ar_order_receipt_dtl.IDENTIFIER%TYPE,
        x_credit_card_number      OUT NOCOPY     xx_ar_order_receipt_dtl.credit_card_number%TYPE,
        x_error_message           OUT NOCOPY     VARCHAR2)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'DECRYPT_CREDIT_CARD';
        le_process_exception  EXCEPTION;
    BEGIN
        BEGIN
            IF (    (p_identifier IS NULL)
                OR (p_credit_card_number_enc IS NULL) )
            THEN
                x_error_message := 'Invalid Parameters';
            ELSE
                IF (gb_debug)
                THEN
                    put_log_line('Setting Context ');
                    put_log_line();
                END IF;

                DBMS_SESSION.set_context(namespace =>      'XX_SA_RCPT_PKG',
                                         ATTRIBUTE =>      'TYPE',
                                         VALUE =>          'EBS');

                IF (gb_debug)
                THEN
                    put_log_line('Decrypting ');
                    put_log_line();
                END IF;

                xx_od_security_key_pkg.decrypt(p_module =>             'AJB',
                                               p_key_label =>          p_identifier,
                                               p_encrypted_val =>      p_credit_card_number_enc,
                                               p_algorithm =>          '3DES',
                                               x_decrypted_val =>      x_credit_card_number,
                                               x_error_message =>      x_error_message);

                IF x_error_message IS NOT NULL
                THEN
                    RAISE le_process_exception;
                ELSIF x_credit_card_number IS NULL
                THEN
                    x_error_message := 'Credit card decryption routine did not return decrypted credit card value.';
                    RAISE le_process_exception;
                END IF;

                x_error_message := NULL;
            END IF;
        EXCEPTION
            WHEN le_process_exception
            THEN
                x_error_message :=    'Processing error in '
                                   || lc_sub_name
                                   || ' Error: '
                                   || x_error_message;
            WHEN OTHERS
            THEN
                x_error_message :=    'Unexpected error in '
                                   || lc_sub_name
                                   || ' Error: '
                                   || SQLERRM;
        END;

        IF x_error_message IS NOT NULL
        THEN
            IF (gb_debug)
            THEN
                put_log_line(x_error_message);
                put_log_line();
            END IF;
        ELSE
            IF (gb_debug)
            THEN
                put_log_line('Credit Card successfully decrypted');
                put_log_line();
            END IF;
        END IF;
    END;

-- ==========================================================================
-- Compare Credit Card
-- ==========================================================================
    FUNCTION encrypted_credit_cards_match(
        p_credit_card_number_enc_1  IN  xx_ar_order_receipt_dtl.credit_card_number%TYPE,
        p_identifier_1              IN  xx_ar_order_receipt_dtl.IDENTIFIER%TYPE,
        p_credit_card_number_enc_2  IN  xx_ar_order_receipt_dtl.credit_card_number%TYPE,
        p_identifier_2              IN  xx_ar_order_receipt_dtl.IDENTIFIER%TYPE)
        RETURN BOOLEAN
    IS
        lc_sub_name     CONSTANT VARCHAR2(50)                                      := 'ENCRYPTED_CREDIT_CARDS_MATCH';
        lc_credit_card_number_1  xx_ar_order_receipt_dtl.credit_card_number%TYPE;
        lc_credit_card_number_2  xx_ar_order_receipt_dtl.credit_card_number%TYPE;
        lc_error_message         VARCHAR2(2000);
        lc_match_flag            BOOLEAN;
    BEGIN
        BEGIN
            lc_match_flag := FALSE;

            IF (    (p_credit_card_number_enc_1 IS NULL)
                OR (p_identifier_1 IS NULL)
                OR (p_credit_card_number_enc_2 IS NULL)
                OR (p_identifier_2 IS NULL) )
            THEN
                lc_error_message := 'Invalid parameters';
            ELSE
                decrypt_credit_card(p_credit_card_number_enc =>      p_credit_card_number_enc_1,
                                    p_identifier =>                  p_identifier_1,
                                    x_credit_card_number =>          lc_credit_card_number_1,
                                    x_error_message =>               lc_error_message);

                IF (    lc_error_message IS NULL
                    AND lc_credit_card_number_1 IS NOT NULL)
                THEN
                    decrypt_credit_card(p_credit_card_number_enc =>      p_credit_card_number_enc_2,
                                        p_identifier =>                  p_identifier_2,
                                        x_credit_card_number =>          lc_credit_card_number_2,
                                        x_error_message =>               lc_error_message);
                END IF;

                IF (lc_error_message IS NULL)
                THEN
                    IF (     (lc_credit_card_number_1 IS NOT NULL)
                        AND (lc_credit_card_number_2 IS NOT NULL)
                        AND (lc_credit_card_number_1 = lc_credit_card_number_2) )
                    THEN
                        lc_match_flag := TRUE;
                    END IF;
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_error_message := SQLERRM;
        END;

        IF (gb_debug)
        THEN
            IF lc_error_message IS NOT NULL
            THEN
                put_log_line(   'ERROR in '
                             || lc_sub_name
                             || ' '
                             || lc_error_message);
                put_log_line();
            END IF;

            IF lc_match_flag
            THEN
                put_log_line(   'RESULT of '
                             || lc_sub_name
                             || ' Credit cards matched');
            ELSE
                put_log_line(   'RESULT of '
                             || lc_sub_name
                             || ' Credit cards did NOT matched');
            END IF;

            put_log_line();
        END IF;

        RETURN lc_match_flag;
    END;

-- ==========================================================================
-- Get Receipt Credit Card Info
-- ==========================================================================
    PROCEDURE get_receipt_credit_card_info(
        p_cash_receipt_id     IN             xx_ar_order_receipt_dtl.cash_receipt_id%TYPE,
        x_credit_card_number  OUT NOCOPY     xx_ar_order_receipt_dtl.credit_card_number%TYPE,
        x_identifier          OUT NOCOPY     xx_ar_order_receipt_dtl.IDENTIFIER%TYPE)
    IS
        CURSOR cur_receipt_info(
            p_cash_receipt_id  IN  xx_ar_order_receipt_dtl.cash_receipt_id%TYPE)
        IS
            SELECT   credit_card_number,
                     IDENTIFIER
            INTO     x_credit_card_number,
                     x_identifier
            FROM     xx_ar_order_receipt_dtl
            WHERE    cash_receipt_id = p_cash_receipt_id
            AND      credit_card_number IS NOT NULL
            AND      IDENTIFIER IS NOT NULL
            ORDER BY order_payment_id DESC;

        lc_sub_name  CONSTANT VARCHAR2(50)   := 'GET_RECEIPT_CREDIT_CARD_INFO';
        lc_error_message      VARCHAR2(2000);
    BEGIN
        BEGIN
            IF (p_cash_receipt_id IS NULL)
            THEN
                lc_error_message := 'Invalid parameters';
            ELSE
                FOR receipt_info_rec IN cur_receipt_info(p_cash_receipt_id =>      p_cash_receipt_id)
                LOOP
                    x_credit_card_number := receipt_info_rec.credit_card_number;
                    x_identifier := receipt_info_rec.IDENTIFIER;
                    EXIT;
                END LOOP;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_error_message := SQLERRM;
        END;

        IF (gb_debug)
        THEN
            IF lc_error_message IS NOT NULL
            THEN
                put_log_line(   'ERROR in '
                             || lc_sub_name
                             || ' '
                             || lc_error_message);
                put_log_line();
            END IF;

            IF     x_credit_card_number IS NOT NULL
               AND x_identifier IS NOT NULL
            THEN
                put_log_line(   'RESULT of '
                             || lc_sub_name
                             || ' Encrypted credit card information found.');
            END IF;

            put_log_line();
        END IF;
    END;

    PROCEDURE get_receipt_method_info(
        p_od_payment_type      IN             xx_ar_order_receipt_dtl.od_payment_type%TYPE,
        p_org_id               IN             xx_ar_order_receipt_dtl.org_id%TYPE,
        x_receipt_method_id    IN OUT NOCOPY  ar_receipt_methods.receipt_method_id%TYPE,
        x_receipt_method_name  IN OUT NOCOPY  ar_receipt_methods.NAME%TYPE,
        x_receipt_class_id     IN OUT NOCOPY  ar_receipt_classes.receipt_class_id%TYPE,
        x_receipt_class_name   IN OUT NOCOPY  ar_receipt_classes.NAME%TYPE)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)                                := 'GET_RECEIPT_METHOD_ID';
        lc_error_message      VARCHAR2(2000);
        lc_action             VARCHAR(100);
        ln_receipt_method_id  ar_receipt_methods.receipt_method_id%TYPE;
    BEGIN
        BEGIN
            IF (    (p_od_payment_type IS NULL)
                OR (p_org_id IS NULL) )
            THEN
                lc_error_message :=
                                'Invalid parameters. param_name: '
                             || p_od_payment_type
                             || ', org_id: '
                             || p_org_id
                             || '.';
            ELSE
                lc_action := 'Calling oe_sys_paramenters';
                ln_receipt_method_id := oe_sys_parameters.VALUE(param_name =>      p_od_payment_type,
                                                                p_org_id =>        p_org_id);

                IF (ln_receipt_method_id IS NULL)
                THEN
                    lc_error_message :=
                           'Call to oe_sys_parameters.VALUE for param_name: '
                        || p_od_payment_type
                        || ', org_id: '
                        || p_org_id
                        || ' returned no value.';
                ELSE
                    lc_action := 'Selecting receipt information.';

                    SELECT arm.receipt_method_id,
                           arm.NAME,
                           arc.receipt_class_id,
                           arc.NAME
                    INTO   x_receipt_method_id,
                           x_receipt_method_name,
                           x_receipt_class_id,
                           x_receipt_class_name
                    FROM   ar_receipt_methods arm, ar_receipt_classes arc
                    WHERE  arm.receipt_method_id = ln_receipt_method_id
                    AND    arm.receipt_class_id = arc.receipt_class_id(+);
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_error_message := SQLERRM;
        END;

        IF (gb_debug)
        THEN
            IF lc_error_message IS NOT NULL
            THEN
                put_log_line(   'ERROR in '
                             || lc_sub_name
                             || ' '
                             || lc_action
                             || ' '
                             || lc_error_message);
                put_log_line();
            END IF;

            IF ln_receipt_method_id IS NOT NULL
            THEN
                put_log_line(   'RESULT of '
                             || lc_sub_name
                             || ' Receipt Method ID: '
                             || ln_receipt_method_id);
            END IF;

            put_log_line();
        END IF;
    END;

-- ===============================================================================
--V2.0 This new procedure used for inserting data into custom receipt table
-- ===============================================================================
    PROCEDURE insert_into_cust_recpt_tbl(
        p_header_id        IN             NUMBER,
        p_rowid            IN             ROWID,
        p_cash_receipt_id  IN             NUMBER,
        x_return_status    OUT NOCOPY     VARCHAR2)
    IS
        lc_sub_name           CONSTANT VARCHAR2(50)                                     := 'INSERT_INTO_CUST_RECPT_TBL';

-- ===============================================================================
-- Return tenders cursor
-- ===============================================================================
        CURSOR c_refund_tenders(
            p_header_id        IN  NUMBER,
            p_cash_receipt_id  IN  NUMBER)
        IS
            SELECT xx_ar_order_payment_id_s.NEXTVAL order_payment_id,
                   ooh.order_number order_number,
                   ooh.orig_sys_document_ref orig_sys_document_ref,
                   ooh.header_id header_id,
                   oos.NAME order_source,
                   ott.NAME order_type,
                   ooh.sold_to_org_id customer_id,
                   LPAD(aou.attribute1,
                        6,
                        '0') store_number,
                   ooh.org_id org_id,
                   ooh.request_id request_id,
                   xoh.imp_file_name imp_file_name,
                   SYSDATE creation_date,
                   ooh.created_by created_by,
                   SYSDATE last_update_date,
                   ooh.created_by last_updated_by,
                   oop.payment_number payment_number,
                   oop.orig_sys_payment_ref orig_sys_payment_ref,
                   oop.payment_type_code payment_type_code,
                   flv.meaning cc_code,
                   oop.credit_card_number cc_number,
                   oop.credit_card_holder_name cc_name,
                   oop.credit_card_expiration_date cc_exp_date,
                   (  -1
                    * oop.credit_amount) payment_amount,
                   oop.receipt_method_id receipt_method_id,
                   oop.check_number check_number,
                   oop.cc_auth_manual cc_auth_manual,
                   oop.merchant_number merchant_number,
                   oop.cc_auth_ps2000 cc_auth_ps2000,
                   oop.allied_ind allied_ind,
                   oop.cc_mask_number cc_mask_number,
                   oop.od_payment_type od_payment_type,
                   oop.cash_receipt_id cash_receipt_id,
                   oop.payment_set_id payment_set_id,
                   'I1025' process_code,   -- V2.1 changed by Gaurav
                   'N' remitted,
                   'N' MATCHED,
                   'OPEN' receipt_status,
                   (SELECT LPAD(attribute1,
                                6,
                                '0')
                    FROM   hr_all_organization_units a
                    WHERE  a.organization_id = NVL(xoh.paid_at_store_id,
                                                   ship_from_org_id) ) ship_from,
                   NULL credit_card_approval_code,
                   NULL credit_card_approval_date,
                   ooh.invoice_to_org_id customer_site_billto_id,
                   ooh.ordered_date receipt_date,
                   'REFUND' sale_type,
                   NULL additional_auth_codes,
                   xfh.process_date process_date,
                   ooh.transactional_curr_code,
                   arm.NAME receipt_method_name,
                   oop.IDENTIFIER,
                   xoh.external_transaction_number,  		--Changes for AMZ MPL
                   oop.token_flag,
                   oop.emv_card,
                   oop.emv_terminal,
                   oop.emv_transaction,
                   oop.emv_offline,
                   oop.emv_fallback,
                   oop.emv_tvr,
                   oop.wallet_type,
                   oop.wallet_id
            FROM   oe_order_headers_all ooh,
                   oe_order_sources oos,
                   oe_transaction_types_tl ott,
                   xx_om_header_attributes_all xoh,
                   xx_om_sacct_file_history xfh,
                   hr_all_organization_units aou,
                   xx_om_return_tenders_all oop,
                   fnd_lookup_values flv,
                   ar_receipt_methods arm
            WHERE  ooh.order_source_id = oos.order_source_id
            AND    ooh.order_type_id = ott.transaction_type_id
            AND    ott.LANGUAGE = USERENV('LANG')
            AND    ooh.header_id = xoh.header_id
            AND    xoh.imp_file_name = xfh.file_name
            AND    ooh.ship_from_org_id = aou.organization_id
            AND    ooh.header_id = oop.header_id
            AND    oop.od_payment_type = flv.lookup_code
            AND    flv.lookup_type = 'OD_PAYMENT_TYPES'
              --AND OOS.NAME              <> 'POE'
            --AND ooh.header_id = p_header_id -- Commented by gaurav for v2.1
            AND    oop.ROWID = p_rowid   -- added by gaurav for v2.1
            AND    arm.receipt_method_id = oop.receipt_method_id;

--      AND oop.cash_receipt_id   = p_cash_receipt_id;
-- ===============================================================================
-- Legacy Depositis Cursor
-- ===============================================================================
        CURSOR c_legacy_deposits(
            p_rowid  IN  ROWID)
        IS
            SELECT xx_ar_order_payment_id_s.NEXTVAL order_payment_id,
                   NULL order_number,
                   NULL header_id,
                   oos.NAME order_source,
                   NULL order_type,
                   xold.sold_to_org_id customer_id,
                   LPAD(SUBSTR(xold.transaction_number,
                               1,
                               4),
                        6,
                        0) store_number,
                   xold.org_id,
                   fnd_global.conc_request_id request_id,
                   xold.imp_file_name,
                   xold.creation_date,
                   xold.created_by,
                   xold.last_update_date,
                   xold.last_updated_by,
                   xold.payment_number,
                   xold.orig_sys_payment_ref,
                   xold.payment_type_code,
                   --xold.credit_card_code cc_code                                  , -- Commented for QC Defect # 13620
                   flv.meaning cc_code,   -- Added for QC Defect # 13620
                   xold.credit_card_number cc_number,
                   xold.credit_card_holder_name cc_name,
                   xold.credit_card_expiration_date cc_exp_date,
                   xold.prepaid_amount,
                   xold.receipt_method_id,
                   xold.check_number,
                   xold.cc_auth_manual,
                   xold.merchant_number,
                   xold.cc_auth_ps2000,
                   xold.allied_ind,
                   xold.cc_mask_number,
                   xold.od_payment_type,
                   xold.cash_receipt_id,
                   xold.payment_set_id,
                   'I1025' process_code,   -- V2.1 changed by Gaurav
                   'N' remitted,
                   'N' MATCHED,
                   'OPEN' receipt_status,
                   NULL ship_from
                                 --, acr.customer_receipt_reference
                                 --, acr.receipt_number
            ,
                   xold.credit_card_approval_code,
                   xold.credit_card_approval_date,
                   NULL customer_site_billto_id,
                   xold.receipt_date,
                   CASE
                       WHEN xold.prepaid_amount < 0
                           THEN 'DEPOSIT-REFUND'
                       ELSE 'DEPOSIT-SALE'
                   END sale_type,
                   (   xold.cc_entry_mode
                    || ':'
                    || xold.cvv_resp_code
                    || ':'
                    || xold.avs_resp_code
                    || ':'
                    || xold.auth_entry_mode) additional_auth_codes,
                   xfh.process_date process_date,
                   xold.transaction_number transaction_number,
                   xold.orig_sys_document_ref,
                   xold.single_pay_ind,
                   xold.currency_code,
                   arm.NAME receipt_method_name,
                   xold.IDENTIFIER,
                   xold.token_flag,
                   xold.emv_card,
                   xold.emv_terminal,
                   xold.emv_transaction,
                   xold.emv_offline,
                   xold.emv_fallback,
                   xold.emv_tvr
            FROM   xx_om_legacy_deposits xold,
                   xx_om_sacct_file_history xfh,
                   oe_order_sources oos,
                   ar_receipt_methods arm,
                   fnd_lookup_values flv
            -- Added for QC Defect # 13620
            WHERE  xold.imp_file_name = xfh.file_name
            AND    xold.ROWID = p_rowid
            AND    xold.order_source_id = oos.order_source_id
            AND    arm.receipt_method_id = xold.receipt_method_id
            AND    flv.lookup_type = 'OD_PAYMENT_TYPES'   -- Added for QC Defect # 13620
            AND    flv.lookup_code = xold.od_payment_type   -- Added for QC Defect # 13620
                                                         ;

        l_refund_tenders               c_refund_tenders%ROWTYPE;
        l_legacy_deposits              c_legacy_deposits%ROWTYPE;
        lc_receipt_number              xx_ar_order_receipt_dtl.receipt_number%TYPE               DEFAULT NULL;
        lc_remitted                    xx_ar_order_receipt_dtl.remitted%TYPE                     DEFAULT NULL;
        lc_matched                     xx_ar_order_receipt_dtl.MATCHED%TYPE                      DEFAULT NULL;
        lc_receipt_status              xx_ar_order_receipt_dtl.receipt_status%TYPE               DEFAULT NULL;
        lc_customer_receipt_reference  xx_ar_order_receipt_dtl.customer_receipt_reference%TYPE   DEFAULT NULL;
        lc_amount                      ar_cash_receipts_all.amount%TYPE                          DEFAULT NULL;
        lc_dep_remitted                xx_ar_order_receipt_dtl.remitted%TYPE                     DEFAULT NULL;
        lc_dep_matched                 xx_ar_order_receipt_dtl.MATCHED%TYPE                      DEFAULT NULL;
        lc_dep_receipt_status          xx_ar_order_receipt_dtl.receipt_status%TYPE               DEFAULT NULL;
        ln_single_pay_ind              xx_om_legacy_dep_dtls.single_pay_ind%TYPE                 DEFAULT NULL;
        ln_orig_sys_document_ref       xx_om_legacy_deposits.orig_sys_document_ref%TYPE          DEFAULT NULL;
        ln_count                       NUMBER                                                    := 0;
        ld_creation_date               ar_cash_receipts_all.creation_date%TYPE;
        lb_settlement_staged           BOOLEAN;
        lc_error_message               VARCHAR2(2000);
		ln_ref_count                   NUMBER := 0; -- Added as per Version 17.0 by Havish K
		ln_dep_count                   NUMBER := 0; -- Added as per Version 17.0 by Havish K
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('Capturing receipt number based on the cash receipt id is null or not ');
        END IF;

        --IF l_refund_tenders.cash_receipt_id IS NOT NULL
        IF p_cash_receipt_id IS NOT NULL
        THEN
            IF (gb_debug)
            THEN
                put_log_line();
                put_log_line(   ' Cash receipt id = '
                             || p_cash_receipt_id);
                put_log_line();
            END IF;

            SELECT receipt_number,
                   customer_receipt_reference,
                   amount,
                   TRUNC(receipt_date)
            INTO   lc_receipt_number,
                   lc_customer_receipt_reference,
                   lc_amount,
                   ld_creation_date
            FROM   ar_cash_receipts_all
            WHERE  cash_receipt_id = p_cash_receipt_id;

            IF (gb_debug)
            THEN
                put_log_line();
                put_log_line(   ' Receipt number = '
                             || lc_receipt_number);
                put_log_line(   ' Customer receipt reference = '
                             || lc_customer_receipt_reference);
                put_log_line(   ' Receipt amount = '
                             || lc_amount);
            END IF;
        ELSE
            lc_receipt_number := NULL;
        END IF;

--------------------------------------------------
-- Return Tenders mapping
--------------------------------------------------
        IF p_header_id IS NOT NULL
        THEN
            IF (gb_debug)
            THEN
                put_log_line();
                put_log_line('Before opening the Refund tenders cursor ');
            END IF;

            OPEN c_refund_tenders(p_header_id,
                                  p_cash_receipt_id);

            FETCH c_refund_tenders
            INTO  l_refund_tenders;

            CLOSE c_refund_tenders;
        -- Commented as per Version 17.0 by Havish K
		/*
            IF (   INSTR(l_refund_tenders.receipt_method_name,
                         'DEBIT') > 0
                OR INSTR(l_refund_tenders.receipt_method_name,
                         'TELECHECK') > 0
                OR INSTR(l_refund_tenders.receipt_method_name,
                         'CASH') > 0
                OR INSTR(l_refund_tenders.receipt_method_name,
                         'GIFT') > 0
                OR INSTR(l_refund_tenders.receipt_method_name,
                         'MAILCHECK') > 0
                OR INSTR(l_refund_tenders.receipt_method_name,
                         'AMAZON') > 0   --Amazon changes
				OR INSTR(l_refund_tenders.receipt_method_name,
                         'EBAY') > 0   --EBAY changes
                OR INSTR(l_refund_tenders.receipt_method_name,
                         'PAYPAL') > 0)
            THEN   -- ADDED FOR DEFECT # 23070
                lc_remitted := 'Y';
            ELSE
                lc_remitted := 'N';
            END IF;
		*/ 
		
		-- Start of adding changes as per Version 17.0 by Havish K
		    BEGIN  	
			    ln_ref_count := 0;
	           SELECT COUNT(1)
	             INTO ln_ref_count
                 FROM xx_fin_translatevalues
                WHERE translate_id IN (SELECT translate_id 
	                                     FROM xx_fin_translatedefinition 
	                                    WHERE translation_name = 'OD_AR_SA_RCPT_METHODS' 
	                                      AND enabled_flag = 'Y')
	              AND INSTR(l_refund_tenders.receipt_method_name,source_value1) > 0;
            EXCEPTION
	        WHEN OTHERS
	        THEN
	            ln_ref_count := 0;
            END;
			
			IF ln_ref_count > 0
			THEN
			    lc_remitted := 'Y';
            ELSE
                lc_remitted := 'N';
            END IF;
		-- End of adding changes as per Version 17.0 by Havish K

            IF (   INSTR(l_refund_tenders.receipt_method_name,
                         'CASH') > 0
                OR INSTR(l_refund_tenders.receipt_method_name,
                         'GIFT') > 0
                OR INSTR(l_refund_tenders.receipt_method_name,
                         'MAILCHECK') > 0)
            THEN
-- Commented by Gaurav for SDR changes
-- l_refund_tenders.payment_type_code IN ('CASH' ,'GIFT_CARD' ,'MAILCHECK') THEN
                lc_matched := 'Y';
                lc_receipt_status := 'CLEARED';
            ELSE
                lc_matched := 'N';
                lc_receipt_status := 'OPEN';
            END IF;

            IF (gb_debug)
            THEN
                put_log_line();
                put_log_line(   'Receipt Method Name = '
                             || l_refund_tenders.receipt_method_name);
                put_log_line(   'Remitted = '
                             || lc_remitted);
                put_log_line(   'Matched = '
                             || lc_matched);
                put_log_line(   'Receipt status = '
                             || lc_receipt_status);
            END IF;
        END IF;

--------------------------------------------------
--------------------------------------------------
-- Legacy Deposits mapping
--------------------------------------------------
        IF     p_header_id IS NULL
           AND p_cash_receipt_id IS NOT NULL
        THEN
            IF (gb_debug)
            THEN
                put_log_line();
                put_log_line('Before opening the Legacy Deposits cursor ');
            END IF;

            OPEN c_legacy_deposits(p_rowid);

            FETCH c_legacy_deposits
            INTO  l_legacy_deposits;

            CLOSE c_legacy_deposits;
        
		-- Commented as per Version 17.0 by Havish K
        /*    IF 
               -- l_legacy_deposits.payment_type_code IN ('DEBIT_CARD' ,'TELECHECK' ,'CASH' ,'GIFT_CARD' ,'MAILCHECK') THEN
               (   INSTR(l_legacy_deposits.receipt_method_name,
                         'DEBIT') > 0
                OR INSTR(l_legacy_deposits.receipt_method_name,
                         'TELECHECK') > 0
                OR INSTR(l_legacy_deposits.receipt_method_name,
                         'CASH') > 0
                OR INSTR(l_legacy_deposits.receipt_method_name,
                         'GIFT') > 0
                OR INSTR(l_legacy_deposits.receipt_method_name,
                         'MAILCHECK') > 0
                OR INSTR(l_legacy_deposits.receipt_method_name,
                         'AMAZON') > 0   --Amazon Changes
				OR INSTR(l_legacy_deposits.receipt_method_name,
                         'EBAY') > 0   --EBAY Changes
                OR INSTR(l_legacy_deposits.receipt_method_name,
                         'PAYPAL') > 0)
            THEN   -- ADDED FOR DEFECT # 23070
                lc_dep_remitted := 'Y';
            ELSE
                lc_dep_remitted := 'N';
            END IF;
		*/
		
		-- Start of adding changes as per Version 17.0 by Havish K
		    
		    BEGIN  	
			   ln_dep_count := 0;
	           SELECT COUNT(1)
	             INTO ln_dep_count
                 FROM xx_fin_translatevalues
                WHERE translate_id IN (SELECT translate_id 
	                                     FROM xx_fin_translatedefinition 
	                                    WHERE translation_name = 'OD_AR_SA_RCPT_METHODS' 
	                                      AND enabled_flag = 'Y')
	              AND INSTR(l_legacy_deposits.receipt_method_name,source_value1) > 0;
            EXCEPTION
	        WHEN OTHERS
	        THEN
	            ln_dep_count := 0;
            END;
			
			IF ln_dep_count > 0
			THEN
			    lc_dep_remitted := 'Y';
            ELSE
                lc_dep_remitted := 'N';
            END IF;
		-- End of adding changes as per Version 17.0 by Havish K

            IF   -- l_legacy_deposits.payment_type_code IN ('CASH' ,'GIFT_CARD' ,'MAILCHECK') THEN
               (   INSTR(l_legacy_deposits.receipt_method_name,
                         'CASH') > 0
                OR INSTR(l_legacy_deposits.receipt_method_name,
                         'GIFT') > 0
                OR INSTR(l_legacy_deposits.receipt_method_name,
                         'MAILCHECK') > 0)
            THEN
                lc_dep_matched := 'Y';
                lc_dep_receipt_status := 'CLEARED';
            ELSE
                lc_dep_matched := 'N';
                lc_dep_receipt_status := 'OPEN';
            END IF;

            IF (gb_debug)
            THEN
                put_log_line();
                put_log_line(   'Receipt Method Name = '
                             || l_legacy_deposits.receipt_method_name);
                put_log_line(   'Remitted = '
                             || lc_dep_remitted);
                put_log_line(   'Matched = '
                             || lc_dep_matched);
                put_log_line(   'Receipt status = '
                             || lc_dep_receipt_status);
            END IF;
        END IF;

--------------------------------------------------
--------------------------------------------------
        IF p_header_id IS NOT NULL
        THEN
            IF (gb_debug)
            THEN
                put_log_line(   'Cash receipt Id is: '
                             || p_cash_receipt_id);
                put_log_line('Before inserting records into Order receipt detail');
                put_log_line();
            END IF;

            INSERT INTO xx_ar_order_receipt_dtl
                        (order_payment_id,
                         order_number,
                         orig_sys_document_ref,
                         orig_sys_payment_ref,
                         payment_number,
                         header_id,
                         order_source,
                         order_type,
                         cash_receipt_id,
                         receipt_number,
                         customer_id,
                         store_number,
                         payment_type_code,
                         credit_card_code,
                         credit_card_number,
                         credit_card_holder_name,
                         credit_card_expiration_date,
                         payment_amount,
                         receipt_method_id,
                         cc_auth_manual,
                         merchant_number,
                         cc_auth_ps2000,
                         allied_ind,
                         payment_set_id,
                         process_code,
                         cc_mask_number,
                         od_payment_type,
                         check_number,
                         org_id,
                         request_id,
                         imp_file_name,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by,
                         remitted,
                         MATCHED,
                         ship_from,
                         receipt_status,
                         customer_receipt_reference,
                         credit_card_approval_code,
                         credit_card_approval_date,
                         customer_site_billto_id,
                         receipt_date,
                         sale_type,
                         additional_auth_codes,
                         process_date,
                         single_pay_ind,
                         currency_code,
                         last_update_login,
                         cleared_date,
                         IDENTIFIER,
                         mpl_order_id,
                         token_flag,
                         emv_card,
                         emv_terminal,
                         emv_transaction,
                         emv_offline,
                         emv_fallback,
                         emv_tvr,
                         wallet_type,
                         wallet_id)
            VALUES      (l_refund_tenders.order_payment_id,
                         l_refund_tenders.order_number,
                         l_refund_tenders.orig_sys_document_ref,
                         l_refund_tenders.orig_sys_payment_ref,
                         l_refund_tenders.payment_number,
                         l_refund_tenders.header_id,
                         l_refund_tenders.order_source,
                         l_refund_tenders.order_type,
                         p_cash_receipt_id,
                         lc_receipt_number,
                         l_refund_tenders.customer_id,
                         l_refund_tenders.store_number,
                         l_refund_tenders.payment_type_code,
                         l_refund_tenders.cc_code,
                         l_refund_tenders.cc_number,
                         l_refund_tenders.cc_name,
                         l_refund_tenders.cc_exp_date,
                         NVL(l_refund_tenders.payment_amount,
                             lc_amount),
                         l_refund_tenders.receipt_method_id,
                         l_refund_tenders.cc_auth_manual,
                         l_refund_tenders.merchant_number,
                         l_refund_tenders.cc_auth_ps2000,
                         l_refund_tenders.allied_ind,
                         l_refund_tenders.payment_set_id,
                         l_refund_tenders.process_code,
                         l_refund_tenders.cc_mask_number,
                         l_refund_tenders.od_payment_type,
                         l_refund_tenders.check_number,
                         l_refund_tenders.org_id,
                         fnd_global.conc_request_id,
                         l_refund_tenders.imp_file_name,
                         l_refund_tenders.creation_date,
                         l_refund_tenders.created_by,
                         l_refund_tenders.last_update_date,
                         l_refund_tenders.last_updated_by,
                         lc_remitted,
                         lc_matched,
                         l_refund_tenders.ship_from,
                         lc_receipt_status,
                         lc_customer_receipt_reference,
                         l_refund_tenders.credit_card_approval_code,
                         l_refund_tenders.credit_card_approval_date,
                         l_refund_tenders.customer_site_billto_id,
                         ld_creation_date,
                         l_refund_tenders.sale_type,
                         l_refund_tenders.additional_auth_codes,
                         l_refund_tenders.process_date,
                         DECODE(gc_process_flag,
                                NULL, NULL,
                                'Y'),
                         l_refund_tenders.transactional_curr_code,
                         fnd_global.login_id,
                         DECODE(lc_receipt_status,
                                'CLEARED', SYSDATE,
                                NULL),
                         l_refund_tenders.IDENTIFIER,
                         l_refund_tenders.external_transaction_number,  --Changes for AMZ MPL
                         NVL(LTRIM(RTRIM(l_refund_tenders.token_flag)),'N'),
                         NVL(LTRIM(RTRIM(l_refund_tenders.emv_card)),'N'),
                         LTRIM(RTRIM(l_refund_tenders.emv_terminal)),
                         NVL(LTRIM(RTRIM(l_refund_tenders.emv_transaction)),'N'),
                         NVL(LTRIM(RTRIM(l_refund_tenders.emv_offline)),'N'),
                         NVL(LTRIM(RTRIM(l_refund_tenders.emv_fallback)),'N'),
                         LTRIM(RTRIM(l_refund_tenders.emv_tvr)),
                         LTRIM(RTRIM(l_refund_tenders.wallet_type)),
                         LTRIM(RTRIM(l_refund_tenders.wallet_id))
                         );
        ELSIF     p_header_id IS NULL
         AND p_cash_receipt_id IS NOT NULL
        THEN
            BEGIN
                SELECT COUNT(1)
                INTO   ln_count
                FROM   xx_ar_order_receipt_dtl
                WHERE  1 = 1
                AND    cash_receipt_id = p_cash_receipt_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    ln_count := 0;
            END;

            IF ln_count = 0
            THEN
                BEGIN
                    SELECT xoldd.single_pay_ind,
                           orig_sys_document_ref
                    INTO   ln_single_pay_ind,
                           ln_orig_sys_document_ref
                    FROM   xx_om_legacy_dep_dtls xoldd
                    WHERE  transaction_number = l_legacy_deposits.transaction_number
                    AND    ROWNUM = 1;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        ln_single_pay_ind := 'N';
                END;

                IF (gb_debug)
                THEN
                    put_log_line(   'Value of single_pay_ind : '
                                 || ln_single_pay_ind);
                END IF;

                IF NVL(ln_single_pay_ind,
                       'N') = 'Y'
                THEN
                    ln_orig_sys_document_ref := l_legacy_deposits.transaction_number;
                END IF;

                IF (gb_debug)
                THEN
                    put_log_line();
                    put_log_line(   'Value of Orig Sys Document Ref is :'
                                 || ln_orig_sys_document_ref);
                    put_log_line();
                    put_log_line(   'Cash receipt Id is: '
                                 || p_cash_receipt_id);
                    put_log_line('Before inserting records into Order receipt detail');
                    put_log_line();
                END IF;

                INSERT INTO xx_ar_order_receipt_dtl
                            (order_payment_id,
                             order_number,
                             orig_sys_document_ref,
                             orig_sys_payment_ref,
                             payment_number,
                             header_id,
                             order_source,
                             order_type,
                             cash_receipt_id,
                             receipt_number,
                             customer_id,
                             store_number,
                             payment_type_code,
                             credit_card_code,
                             credit_card_number,
                             credit_card_holder_name,
                             credit_card_expiration_date,
                             payment_amount,
                             receipt_method_id,
                             cc_auth_manual,
                             merchant_number,
                             cc_auth_ps2000,
                             allied_ind,
                             payment_set_id,
                             process_code,
                             cc_mask_number,
                             od_payment_type,
                             check_number,
                             org_id,
                             request_id,
                             imp_file_name,
                             creation_date,
                             created_by,
                             last_update_date,
                             last_updated_by,
                             remitted,
                             MATCHED,
                             ship_from,
                             receipt_status,
                             customer_receipt_reference,
                             credit_card_approval_code,
                             credit_card_approval_date,
                             customer_site_billto_id,
                             receipt_date,
                             sale_type,
                             additional_auth_codes,
                             process_date,
                             single_pay_ind,
                             currency_code,
                             last_update_login,
                             cleared_date,
                             IDENTIFIER,
                             token_flag,
                             emv_card,
                             emv_terminal,
                             emv_transaction,
                             emv_offline,
                             emv_fallback,
                             emv_tvr)
                VALUES      (l_legacy_deposits.order_payment_id,
                             l_legacy_deposits.order_number,
                             ln_orig_sys_document_ref
                                                     --, l_legacy_deposits.orig_sys_document_ref
                ,
                             l_legacy_deposits.orig_sys_payment_ref,
                             l_legacy_deposits.payment_number,
                             l_legacy_deposits.header_id,
                             l_legacy_deposits.order_source,
                             l_legacy_deposits.order_type,
                             p_cash_receipt_id,
                             lc_receipt_number,
                             l_legacy_deposits.customer_id,
                             l_legacy_deposits.store_number,
                             l_legacy_deposits.payment_type_code,
                             l_legacy_deposits.cc_code,
                             l_legacy_deposits.cc_number,
                             l_legacy_deposits.cc_name,
                             l_legacy_deposits.cc_exp_date,
                             NVL(l_legacy_deposits.prepaid_amount,
                                 lc_amount),
                             l_legacy_deposits.receipt_method_id,
                             l_legacy_deposits.cc_auth_manual,
                             l_legacy_deposits.merchant_number,
                             l_legacy_deposits.cc_auth_ps2000,
                             l_legacy_deposits.allied_ind,
                             l_legacy_deposits.payment_set_id,
                             l_legacy_deposits.process_code,
                             l_legacy_deposits.cc_mask_number,
                             l_legacy_deposits.od_payment_type,
                             l_legacy_deposits.check_number,
                             l_legacy_deposits.org_id,   -- Added by gaurav for defect 12105
                             fnd_global.conc_request_id,
                             l_legacy_deposits.imp_file_name,
                             SYSDATE,
                             l_legacy_deposits.created_by,
                             l_legacy_deposits.last_update_date,
                             l_legacy_deposits.last_updated_by,
                             lc_dep_remitted,
                             lc_dep_matched,
                             l_legacy_deposits.ship_from,
                             lc_dep_receipt_status,
                             lc_customer_receipt_reference,
                             l_legacy_deposits.credit_card_approval_code,
                             l_legacy_deposits.credit_card_approval_date,
                             l_legacy_deposits.customer_site_billto_id,
                             ld_creation_date,
                             l_legacy_deposits.sale_type,
                             l_legacy_deposits.additional_auth_codes,
                             l_legacy_deposits.process_date,
                             l_legacy_deposits.single_pay_ind,
                             l_legacy_deposits.currency_code,
                             fnd_global.login_id,
                             DECODE(lc_dep_receipt_status,
                                    'CLEARED', SYSDATE,
                                    NULL),
                             l_legacy_deposits.IDENTIFIER,
                             NVL(LTRIM(RTRIM(l_legacy_deposits.token_flag)),'N'),
                             NVL(LTRIM(RTRIM(l_legacy_deposits.emv_card)),'N'),
                             LTRIM(RTRIM(l_legacy_deposits.emv_terminal)),
                             NVL(LTRIM(RTRIM(l_legacy_deposits.emv_transaction)),'N'),
                             NVL(LTRIM(RTRIM(l_legacy_deposits.emv_offline)),'N'),
                             NVL(LTRIM(RTRIM(l_legacy_deposits.emv_fallback)),'N'),
                             LTRIM(RTRIM(l_legacy_deposits.emv_tvr))
                             );
            END IF;   ---- if lv_count= 0 then
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;

        x_return_status := 'S';
    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_status := 'E';
    END insert_into_cust_recpt_tbl;

-- ===============================================================================
-- V2.0 The New Function will be used to check if receipt is for Single payment / POS scenario
-- ===============================================================================
    FUNCTION is_single_pay_pos_rec(
        p_header_id           IN  NUMBER,
        p_transaction_number  IN  VARCHAR2)
        RETURN BOOLEAN
    IS
        CURSOR c_single_pay_pos(
            p_header_id  IN  NUMBER)
        IS
            SELECT SUBSTR(op.attribute13,
                            INSTR(op.attribute13,
                                  ':',
                                  1,
                                  4)
                          + 1)
            FROM   oe_payments op
            WHERE  1 = 1
            AND    EXISTS(
                       SELECT ooh2.header_id   --, SUBSTR(op.attribute13 ,instr(op.attribute13 ,':' ,1 ,4)+1 )
                       FROM   oe_order_headers_all ooh,
                              oe_order_lines_all ool,
                              xx_om_line_attributes_all xola,
                              oe_order_headers_all ooh2
                       WHERE  ooh.header_id = ool.header_id
                       AND    ool.line_id = xola.line_id
                       AND    xola.ret_orig_order_num = ooh2.orig_sys_document_ref
                       AND    ooh.header_id = p_header_id   --137167515
                       AND    ooh2.header_id = op.header_id)
            AND    ROWNUM = 1;

        lc_sub_name  CONSTANT VARCHAR2(50)                   := 'IS_SINGLE_PAY_POS_REC';
        lc_single_pay_pos     oe_payments.attribute13%TYPE;
        lc_tran_num_cnt       NUMBER;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

        OPEN c_single_pay_pos(p_header_id);

        FETCH c_single_pay_pos
        INTO  lc_single_pay_pos;

        CLOSE c_single_pay_pos;

        IF lc_single_pay_pos = 'Y'
        THEN
            put_log_line('Function IS_SINGLE_PAY_POS_REC returns True');
            RETURN TRUE;
        ELSE
            put_log_line('Function IS_SINGLE_PAY_POS_REC returns False');
            RETURN FALSE;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END is_single_pay_pos_rec;

-- ==========================================================================
-- map create deposit cursor record to current record type
-- ==========================================================================
    PROCEDURE map_create_deposit_to_current(
        p_deposit_row  IN OUT NOCOPY  gcu_deposits%ROWTYPE,
        x_current_row  OUT NOCOPY     gt_current_record)
    IS
    BEGIN
        x_current_row.record_type := xx_ar_prepayments_pkg.gc_i1025_record_type_deposit;
        x_current_row.xx_payment_rowid := p_deposit_row.ROWID;
        x_current_row.orig_sys_document_ref := p_deposit_row.orig_sys_document_ref;
        x_current_row.bill_to_customer_id := p_deposit_row.sold_to_org_id;
        x_current_row.bill_to_customer := p_deposit_row.sold_to_org;
        x_current_row.bill_to_site_use_id := NULL;
        x_current_row.party_id := p_deposit_row.party_id;
        x_current_row.org_id := p_deposit_row.org_id;
        x_current_row.header_id := p_deposit_row.header_id;
        x_current_row.order_number := p_deposit_row.order_number;
        x_current_row.ordered_date := NULL;
        x_current_row.payment_number := p_deposit_row.payment_number;
        x_current_row.payment_set_id := p_deposit_row.payment_set_id;
        x_current_row.payment_type_code := p_deposit_row.payment_type_code;
        x_current_row.credit_card_code := p_deposit_row.credit_card_code;
        x_current_row.credit_card_number := p_deposit_row.credit_card_number;
        x_current_row.credit_card_holder_name := p_deposit_row.credit_card_holder_name;
        x_current_row.credit_card_expiration_date := p_deposit_row.credit_card_expiration_date;
        x_current_row.credit_card_approval_code := p_deposit_row.credit_card_approval_code;
        x_current_row.credit_card_approval_date := p_deposit_row.credit_card_approval_date;
        x_current_row.check_number := p_deposit_row.check_number;
        x_current_row.line_id := p_deposit_row.line_id;
        x_current_row.currency_code := p_deposit_row.currency_code;
        x_current_row.receipt_method_id := p_deposit_row.receipt_method_id;
        x_current_row.receipt_method := p_deposit_row.receipt_method;
        x_current_row.receipt_class_id := p_deposit_row.receipt_class_id;
        x_current_row.receipt_class := p_deposit_row.receipt_class;
        x_current_row.cash_receipt_id := p_deposit_row.cash_receipt_id;
        x_current_row.receipt_number := NULL;
        x_current_row.receipt_appl_status := NULL;
        x_current_row.receipt_status := NULL;
        x_current_row.original_receipt_date := p_deposit_row.receipt_date;
        x_current_row.i1025_process_code := NULL;
        x_current_row.customer_trx_id := NULL;
        x_current_row.trx_date := NULL;
        x_current_row.trx_number := NULL;
        x_current_row.trx_type := NULL;
        x_current_row.payment_schedule_id := NULL;
        x_current_row.amount_due_remaining := NULL;
        x_current_row.payment_schedule_status := NULL;
        x_current_row.amount := p_deposit_row.amount;
        x_current_row.cc_auth_ps2000 := p_deposit_row.cc_auth_ps2000;
        x_current_row.cc_auth_manual := p_deposit_row.cc_auth_manual;
        x_current_row.cc_mask_number := p_deposit_row.cc_mask_number;
        x_current_row.merchant_number := p_deposit_row.merchant_number;
        x_current_row.od_payment_type := p_deposit_row.od_payment_type;
        x_current_row.debit_card_approval_ref := p_deposit_row.debit_card_approval_ref;
        x_current_row.i1025_status := p_deposit_row.i1025_status;
        x_current_row.creation_date := p_deposit_row.creation_date;
        x_current_row.receipt_date := p_deposit_row.receipt_date;
        x_current_row.paid_at_store_id := p_deposit_row.paid_at_store_id;
        x_current_row.sale_location := p_deposit_row.sale_location;
        x_current_row.ship_from_org_id := p_deposit_row.ship_from_org_id;
        x_current_row.ship_from_org := p_deposit_row.ship_from_org;
        x_current_row.process_code := p_deposit_row.process_code;
        x_current_row.cc_entry_mode := p_deposit_row.cc_entry_mode;
        x_current_row.cvv_resp_code := p_deposit_row.cvv_resp_code;
        x_current_row.avs_resp_code := p_deposit_row.avs_resp_code;
        x_current_row.auth_entry_mode := p_deposit_row.auth_entry_mode;
        x_current_row.payment_type_flag := p_deposit_row.payment_type_flag;
        x_current_row.deposit_reversal_flag := p_deposit_row.deposit_reversal_flag;
        x_current_row.transaction_number := p_deposit_row.transaction_number;
        x_current_row.om_import_date := p_deposit_row.om_import_date;
        x_current_row.imp_file_name := p_deposit_row.imp_file_name;
        x_current_row.ref_legacy_order_num := NULL;
        x_current_row.single_pay_ind := p_deposit_row.single_pay_ind;   --added by Gaurav v2.0
        x_current_row.payment_type_new :=
            xx_ar_prepayments_pkg.get_payment_type(p_org_id =>                 p_deposit_row.org_id,
                                                   p_receipt_method_id =>      p_deposit_row.receipt_method_id,
                                                   p_payment_type =>           p_deposit_row.payment_type_code);
        x_current_row.IDENTIFIER := p_deposit_row.IDENTIFIER;
        get_receipt_method_info(p_od_payment_type =>          x_current_row.od_payment_type,
                                p_org_id =>                   x_current_row.org_id,
                                x_receipt_method_id =>        x_current_row.receipt_method_id,
                                x_receipt_method_name =>      x_current_row.receipt_method,
                                x_receipt_class_id =>         x_current_row.receipt_class_id,
                                x_receipt_class_name =>       x_current_row.receipt_class);
    END;

-- ==========================================================================
-- map create refund (zero-dollar) cursor record to current record type
-- ==========================================================================
    PROCEDURE map_create_refund_to_current(
        p_refund_row   IN OUT NOCOPY  gcu_refunds%ROWTYPE,
        x_current_row  OUT NOCOPY     gt_current_record)
    IS
    BEGIN
        x_current_row.record_type := xx_ar_prepayments_pkg.gc_i1025_record_type_refund;
        x_current_row.xx_payment_rowid := p_refund_row.ROWID;
        x_current_row.orig_sys_document_ref := p_refund_row.orig_sys_document_ref;
        x_current_row.bill_to_customer_id := p_refund_row.sold_to_org_id;
        x_current_row.bill_to_customer := p_refund_row.sold_to_org;
        x_current_row.bill_to_site_use_id := NULL;
        x_current_row.party_id := p_refund_row.party_id;
        x_current_row.org_id := p_refund_row.org_id;
        x_current_row.header_id := p_refund_row.header_id;
        x_current_row.order_number := p_refund_row.order_number;
        x_current_row.ordered_date := p_refund_row.ordered_date;
        x_current_row.payment_number := p_refund_row.payment_number;
        x_current_row.payment_set_id := p_refund_row.payment_set_id;
        x_current_row.payment_type_code := p_refund_row.payment_type_code;
        x_current_row.credit_card_code := p_refund_row.credit_card_code;
        x_current_row.credit_card_number := p_refund_row.credit_card_number;
        x_current_row.credit_card_holder_name := p_refund_row.credit_card_holder_name;
        x_current_row.credit_card_expiration_date := p_refund_row.credit_card_expiration_date;
        x_current_row.credit_card_approval_code := p_refund_row.credit_card_approval_code;
        x_current_row.credit_card_approval_date := p_refund_row.credit_card_approval_date;
        x_current_row.check_number := p_refund_row.check_number;
        x_current_row.line_id := p_refund_row.line_id;
        x_current_row.currency_code := p_refund_row.currency_code;
        x_current_row.receipt_method_id := p_refund_row.receipt_method_id;
        x_current_row.receipt_method := p_refund_row.receipt_method;
        x_current_row.receipt_class_id := p_refund_row.receipt_class_id;
        x_current_row.receipt_class := p_refund_row.receipt_class;
        x_current_row.cash_receipt_id := p_refund_row.cash_receipt_id;
        x_current_row.receipt_number := NULL;
        x_current_row.receipt_appl_status := NULL;
        x_current_row.receipt_status := NULL;
        x_current_row.original_receipt_date := p_refund_row.receipt_date;
        x_current_row.i1025_process_code := NULL;
        x_current_row.customer_trx_id := NULL;
        x_current_row.trx_date := NULL;
        x_current_row.trx_number := NULL;
        x_current_row.trx_type := NULL;
        x_current_row.payment_schedule_id := NULL;
        x_current_row.amount_due_remaining := NULL;
        x_current_row.payment_schedule_status := NULL;
        x_current_row.amount := p_refund_row.amount;
        x_current_row.cc_auth_ps2000 := p_refund_row.cc_auth_ps2000;
        x_current_row.cc_auth_manual := p_refund_row.cc_auth_manual;
        x_current_row.cc_mask_number := p_refund_row.cc_mask_number;
        x_current_row.merchant_number := p_refund_row.merchant_number;
        x_current_row.od_payment_type := p_refund_row.od_payment_type;
        x_current_row.debit_card_approval_ref := p_refund_row.debit_card_approval_ref;
        x_current_row.i1025_status := p_refund_row.i1025_status;
        x_current_row.creation_date := p_refund_row.creation_date;
        x_current_row.receipt_date := p_refund_row.receipt_date;
        x_current_row.paid_at_store_id := p_refund_row.paid_at_store_id;
        x_current_row.sale_location := p_refund_row.sale_location;
        x_current_row.ship_from_org_id := p_refund_row.ship_from_org_id;
        x_current_row.ship_from_org := p_refund_row.ship_from_org;
        x_current_row.process_code := p_refund_row.process_code;
        x_current_row.cc_entry_mode := NULL;
        x_current_row.cvv_resp_code := NULL;
        x_current_row.avs_resp_code := NULL;
        x_current_row.auth_entry_mode := NULL;
        x_current_row.payment_type_flag := NULL;
        x_current_row.deposit_reversal_flag := NULL;
        x_current_row.transaction_number := NULL;
        x_current_row.om_import_date := NULL;
        x_current_row.imp_file_name := p_refund_row.imp_file_name;
        x_current_row.ref_legacy_order_num := NULL;
        x_current_row.single_pay_ind := NULL;   --added by Gaurav v2.0
        x_current_row.payment_type_new :=
            xx_ar_prepayments_pkg.get_payment_type(p_org_id =>                 p_refund_row.org_id,
                                                   p_receipt_method_id =>      p_refund_row.receipt_method_id,
                                                   p_payment_type =>           p_refund_row.payment_type_code);
        x_current_row.IDENTIFIER := p_refund_row.IDENTIFIER;
        get_receipt_method_info(p_od_payment_type =>          x_current_row.od_payment_type,
                                p_org_id =>                   x_current_row.org_id,
                                x_receipt_method_id =>        x_current_row.receipt_method_id,
                                x_receipt_method_name =>      x_current_row.receipt_method,
                                x_receipt_class_id =>         x_current_row.receipt_class_id,
                                x_receipt_class_name =>       x_current_row.receipt_class);
    END;

-- ==========================================================================
-- map apply refund cursor record to current record type
-- ==========================================================================
    PROCEDURE map_apply_refund_to_current(
        p_refund_cm_row  IN OUT NOCOPY  gcu_refund_cms%ROWTYPE,
        x_current_row    OUT NOCOPY     gt_current_record)
    IS
    BEGIN
        x_current_row.record_type := xx_ar_prepayments_pkg.gc_i1025_record_type_refund;
        x_current_row.xx_payment_rowid := p_refund_cm_row.ROWID;
        x_current_row.orig_sys_document_ref := p_refund_cm_row.orig_sys_document_ref;
        x_current_row.bill_to_customer_id := p_refund_cm_row.bill_to_customer_id;
        x_current_row.bill_to_customer := p_refund_cm_row.customer_name;
        x_current_row.bill_to_site_use_id := NULL;
        x_current_row.party_id := p_refund_cm_row.party_id;
        x_current_row.org_id := p_refund_cm_row.org_id;
        x_current_row.header_id := p_refund_cm_row.header_id;
        x_current_row.order_number := p_refund_cm_row.order_number;
        x_current_row.ordered_date := p_refund_cm_row.ordered_date;
        x_current_row.payment_number := p_refund_cm_row.payment_number;
        x_current_row.payment_set_id := p_refund_cm_row.payment_set_id;
        x_current_row.payment_type_code := p_refund_cm_row.payment_type_code;
        x_current_row.credit_card_code := p_refund_cm_row.credit_card_code;
        x_current_row.credit_card_number := p_refund_cm_row.credit_card_number;
        x_current_row.credit_card_holder_name := p_refund_cm_row.credit_card_holder_name;
        x_current_row.credit_card_expiration_date := p_refund_cm_row.credit_card_expiration_date;
        x_current_row.credit_card_approval_code := NULL;
        x_current_row.credit_card_approval_date := NULL;
        x_current_row.check_number := p_refund_cm_row.check_number;
        x_current_row.line_id := p_refund_cm_row.line_id;
        x_current_row.currency_code := p_refund_cm_row.currency_code;
        x_current_row.receipt_method_id := p_refund_cm_row.receipt_method_id;
        x_current_row.receipt_method := p_refund_cm_row.receipt_method;
        x_current_row.receipt_class_id := p_refund_cm_row.receipt_class_id;
        x_current_row.receipt_class := p_refund_cm_row.receipt_class;
        x_current_row.cash_receipt_id := p_refund_cm_row.cash_receipt_id;
        x_current_row.receipt_number := p_refund_cm_row.receipt_number;
        x_current_row.receipt_appl_status := p_refund_cm_row.receipt_appl_status;
        x_current_row.receipt_status := p_refund_cm_row.receipt_status;
        x_current_row.original_receipt_date := NVL(p_refund_cm_row.original_receipt_date,
                                                   p_refund_cm_row.receipt_date);
        x_current_row.i1025_process_code := p_refund_cm_row.i1025_process_code;
        x_current_row.customer_trx_id := p_refund_cm_row.customer_trx_id;
        x_current_row.trx_date := p_refund_cm_row.trx_date;
        x_current_row.trx_number := p_refund_cm_row.trx_number;
        x_current_row.trx_type := p_refund_cm_row.trx_type;
        x_current_row.payment_schedule_id := p_refund_cm_row.payment_schedule_id;
        x_current_row.amount_due_remaining := p_refund_cm_row.amount_due_remaining;
        x_current_row.payment_schedule_status := p_refund_cm_row.payment_schedule_status;
        x_current_row.amount := p_refund_cm_row.amount;
        x_current_row.cc_auth_ps2000 := p_refund_cm_row.cc_auth_ps2000;
        x_current_row.cc_auth_manual := p_refund_cm_row.cc_auth_manual;
        x_current_row.cc_mask_number := p_refund_cm_row.cc_mask_number;
        x_current_row.merchant_number := p_refund_cm_row.merchant_number;
        x_current_row.od_payment_type := p_refund_cm_row.od_payment_type;
        x_current_row.debit_card_approval_ref := p_refund_cm_row.debit_card_approval_ref;
        x_current_row.i1025_status := p_refund_cm_row.i1025_status;
        x_current_row.creation_date := p_refund_cm_row.creation_date;
        x_current_row.receipt_date := p_refund_cm_row.receipt_date;
        x_current_row.paid_at_store_id := p_refund_cm_row.paid_at_store_id;
        x_current_row.sale_location := p_refund_cm_row.sale_location;
        x_current_row.ship_from_org_id := p_refund_cm_row.ship_from_org_id;
        x_current_row.ship_from_org := p_refund_cm_row.ship_from_org;
        x_current_row.process_code := NULL;
        x_current_row.cc_entry_mode := NULL;
        x_current_row.cvv_resp_code := NULL;
        x_current_row.avs_resp_code := NULL;
        x_current_row.auth_entry_mode := NULL;
        x_current_row.payment_type_flag := NULL;
        x_current_row.deposit_reversal_flag := NULL;
        x_current_row.transaction_number := NULL;
        x_current_row.om_import_date := NULL;
        x_current_row.imp_file_name := p_refund_cm_row.imp_file_name;
        x_current_row.ref_legacy_order_num := NULL;
        x_current_row.single_pay_ind := NULL;   --added by Gaurav v2.0
        x_current_row.payment_type_new :=
            xx_ar_prepayments_pkg.get_payment_type(p_org_id =>                 p_refund_cm_row.org_id,
                                                   p_receipt_method_id =>      p_refund_cm_row.receipt_method_id,
                                                   p_payment_type =>           p_refund_cm_row.payment_type_code);
        x_current_row.IDENTIFIER := p_refund_cm_row.IDENTIFIER;
    END;

-- ==========================================================================
-- lock the current record (either the deposit or refund tender)
-- ==========================================================================
    PROCEDURE lock_current_row(
        p_record_type  IN  VARCHAR2,
        p_rowid        IN  ROWID)
    IS
        lc_sub_name     CONSTANT VARCHAR2(50) := 'LOCK_CURRENT_ROW';
        ln_dummy                 NUMBER       DEFAULT NULL;
        lc_table_name            VARCHAR2(50) DEFAULT NULL;
        e_ora_record_locked      EXCEPTION;
        e_ora_deadlock_detected  EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_ora_record_locked, -54);
        PRAGMA EXCEPTION_INIT(e_ora_deadlock_detected, -60);
    BEGIN
        IF (p_record_type = xx_ar_prepayments_pkg.gc_i1025_record_type_deposit)
        THEN
            lc_table_name := 'XX_OM_LEGACY_DEPOSITS';

            SELECT     1
            INTO       ln_dummy
            FROM       xx_om_legacy_deposits
            WHERE      ROWID = p_rowid
            FOR UPDATE NOWAIT;
        ELSIF(p_record_type = xx_ar_prepayments_pkg.gc_i1025_record_type_refund)
        THEN
            lc_table_name := 'XX_OM_RETURN_TENDERS_ALL';

            SELECT     1
            INTO       ln_dummy
            FROM       xx_om_return_tenders_all
            WHERE      ROWID = p_rowid
            FOR UPDATE NOWAIT;
        ELSE
            raise_application_error(-20063,
                                       'Unknown Record Type for Locking the current row.'
                                    || CHR(10)
                                    || '  p_record_type = '
                                    || p_record_type);
        END IF;
    EXCEPTION
        WHEN e_ora_record_locked
        THEN
            raise_application_error(-20054,
                                       'ERRORS in '
                                    || lc_sub_name
                                    || '.'
                                    || CHR(10)
                                    || '  Record locked on '
                                    || lc_table_name
                                    || '.'
                                    || CHR(10)
                                    || '  ( ROWID = '
                                    || p_rowid
                                    || ')');
        WHEN e_ora_deadlock_detected
        THEN
            raise_application_error(-20060,
                                       'ERRORS in '
                                    || lc_sub_name
                                    || '.'
                                    || CHR(10)
                                    || '  Deadlock detected on '
                                    || lc_table_name
                                    || '.'
                                    || CHR(10)
                                    || '  ( ROWID = '
                                    || p_rowid
                                    || ')');
    END;

-- ==========================================================================
-- function for getting the primary bill-to customer info for the given
--   customer id
-- ==========================================================================
    FUNCTION get_bill_customer_by_id(
        p_org_id           IN  NUMBER,
        p_cust_account_id  IN  NUMBER)
        RETURN gcu_customer_id%ROWTYPE
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)              := 'GET_BILL_CUSTOMER_BY_ID';
        x_customer_rec        gcu_customer_id%ROWTYPE;
    BEGIN
        OPEN gcu_customer_id(cp_org_id =>               p_org_id,
                             cp_cust_account_id =>      p_cust_account_id);

        FETCH gcu_customer_id
        INTO  x_customer_rec;

        CLOSE gcu_customer_id;

        IF (gb_debug)
        THEN
            put_log_line('Primary Bill-to Customer Info:');
            put_log_line(   '  Customer Name: '
                         || x_customer_rec.customer_name);
            put_log_line(   '  Site Use Id  : '
                         || x_customer_rec.site_use_id);
            put_log_line();
        END IF;

        RETURN x_customer_rec;
    END;

-- ==========================================================================
-- procedure that returns the receipt write-off activity name for the deposit
--   credit card refund for the given org
-- ==========================================================================
    FUNCTION get_cc_deposit_writeoff_act(
        p_org_id  IN  ar_receivables_trx_all.org_id%TYPE)
        RETURN ar_receivables_trx_all.NAME%TYPE
    AS
        lc_activity_name  ar_receivables_trx_all.NAME%TYPE   := NULL;
    BEGIN
        BEGIN
            SELECT art.NAME
            INTO   lc_activity_name
            FROM   ar_receivables_trx_all art, xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
            WHERE  art.NAME = xftv.source_value5
            AND    xftd.translate_id = xftv.translate_id
            AND    xftd.translation_name = 'XX_AR_I1025_CC_DEP_REFUND'
            AND    art.org_id = xftv.source_value4
            AND    art.org_id = p_org_id
            AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                    SYSDATE
                                                                  + 1)
            AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                    SYSDATE
                                                                  + 1)
            AND    xftv.enabled_flag = 'Y'
            AND    xftd.enabled_flag = 'Y';
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_activity_name := NULL;
        END;

        RETURN(lc_activity_name);
    END;

-- ==========================================================================
-- procedure that returns the receipt write-off activity for the standard
--   credit card refund for the given org
-- ==========================================================================
    FUNCTION get_cc_refund_activity(
        p_org_id  IN  NUMBER)
        RETURN NUMBER
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'GET_CC_REFUND_ACTIVITY';
        ln_receivable_trx_id  VARCHAR2(50) DEFAULT NULL;

        CURSOR c_cc_refund
        IS
            SELECT receivables_trx_id
            FROM   ar_receivables_trx_all
            WHERE  TYPE = 'CCREFUND'
            AND    status = 'A'
            AND    org_id = p_org_id;
    BEGIN
        OPEN c_cc_refund;

        FETCH c_cc_refund
        INTO  ln_receivable_trx_id;

        CLOSE c_cc_refund;

        RETURN ln_receivable_trx_id;
    END;

-- ==========================================================================
-- procedure that returns the receipt write-off activity for the given
--   payment method code
-- ==========================================================================
    FUNCTION get_refund_writeoff_activity(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_sale_location      IN  VARCHAR2,
        p_payment_type_code  IN  VARCHAR2 DEFAULT NULL)
        RETURN VARCHAR2
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)  := 'GET_REFUND_WRITEOFF_ACTIVITY';
        lc_payment_type       VARCHAR2(100) DEFAULT NULL;
        lc_country_prefix     VARCHAR2(50)  DEFAULT NULL;
        lc_receipt_method     VARCHAR2(100);
		lc_receipt_writeoff   VARCHAR2(100) DEFAULT NULL; -- Added as per Version 17.0 by Havish K 
    BEGIN
-- ==========================================================================
-- get the country code prefix for the given operating unit (org_id)
-- ==========================================================================
        lc_country_prefix := xx_ar_prepayments_pkg.get_country_prefix(p_org_id);
-- ==========================================================================
-- get the payment method based on the given AR receipt method
-- ==========================================================================
        put_log_line('p_org_id ');
        put_log_line(   '  p_org_id : '
                     || p_org_id);
        put_log_line(   '  p_receipt_method_id  : '
                     || p_receipt_method_id);
        put_log_line(   ' p_payment_type_code :'
                     || p_payment_type_code);

        -- Defect # 21242 need to derive the coorect activity name for PAYPAL refund
        SELECT NAME
        INTO   lc_receipt_method
        FROM   ar_receipt_methods
        WHERE  receipt_method_id = p_receipt_method_id;

        lc_payment_type :=
            xx_ar_prepayments_pkg.get_payment_type(p_org_id =>                 p_org_id,
                                                   p_receipt_method_id =>      p_receipt_method_id,
                                                   p_payment_type =>           p_payment_type_code);
-- ==========================================================================
-- determine the refund activity for the given refund tender (receipt method)
--   the only refund write-off activities we have should be for:
--     credit card, gift card, debit card, telecheck eca, and cash
--       (mailchecks are not written-off)
-- ==========================================================================
        put_log_line(   ' lc_payment_type :'
                     || lc_payment_type);
        
	/*
        IF (lc_payment_type = 'CREDIT_CARD')
        THEN
            RETURN    lc_country_prefix
                   || '_REFUND_CC_WO_OD';
		ELSIF(lc_payment_type = 'GIFT_CARD' AND lc_receipt_method = lc_country_prefix || '_GIFT CARD_OMX') --Added for OMX gift card consolidation
        THEN
            RETURN    lc_country_prefix
                   || '_REFUND_GIFT_CARD_OMX';
        ELSIF(lc_payment_type = 'GIFT_CARD')
        THEN
            RETURN    lc_country_prefix
                   || '_REFUND_GIFT_CARD_OD';
        ELSIF(lc_payment_type = 'CASH')
        THEN
            -- Defect # 21242
            IF lc_receipt_method =    lc_country_prefix
                                   || '_PAYPAL_OD'
            THEN
                RETURN    lc_country_prefix
                       || '_REFUND_PAYPAL';
            ELSIF lc_receipt_method =    lc_country_prefix
                                      || '_AMAZON_OD'
            THEN   --Amazon Changes
                RETURN    lc_country_prefix
                       || '_REFUND_AMAZON';   --Amazon Changes
			ELSIF lc_receipt_method =    lc_country_prefix
                                      || '_EBAY_OD'
            THEN   --Ebay Changes
                RETURN    lc_country_prefix
                       || '_REFUND_EBAY';   --EBAY Changes
            ELSE
                RETURN    lc_country_prefix
                       || '_REFUND_CASH_'
                       || p_sale_location;
            END IF;
        ELSIF(lc_payment_type = 'DEBIT_CARD')
        THEN
            RETURN    lc_country_prefix
                   || '_REFUND_DEBIT_CARD_OD';
        ELSIF(lc_payment_type = 'TELECHECK')
        THEN
            RETURN    lc_country_prefix
                   || '_REFUND_TELECHECK_OD';
        -- V2.0 Included new payment type to writeoff the Mailcheck - Start
        ELSIF(lc_payment_type = 'MAILCHECK')
        THEN
            RETURN    lc_country_prefix
                   || '_MAILCK_CLR_OD';
        -- V2.0 Included new payment type to writeoff the Mailcheck - End
        ELSE
            fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20005_BAD_PMT_TYPE');
            fnd_message.set_token('SUB_NAME',
                                  lc_sub_name);
            fnd_message.set_token('PAYMENT_TYPE_CODE',
                                  lc_payment_type);
            raise_application_error(-20005,
                                    fnd_message.get() );
        END IF;
    */
	  -- Start of adding changes as per Version 17.0 by Havish K
	    BEGIN
	        SELECT lc_country_prefix||target_value1
	    	  INTO lc_receipt_writeoff
              FROM xx_fin_translatevalues
             WHERE translate_id IN (SELECT translate_id 
                                      FROM xx_fin_translatedefinition 
                                     WHERE translation_name = 'OD_AR_REFUND_WRITEOFF' 
                                       AND enabled_flag = 'Y')
               AND source_value1 = lc_payment_type 
               AND lc_country_prefix||source_value2 = lc_receipt_method;
	    EXCEPTION
	    WHEN NO_DATA_FOUND
	    THEN
	        IF lc_payment_type = 'CASH'
		    THEN
		       BEGIN
		           SELECT lc_country_prefix||target_value1|| p_sale_location
		    	     INTO lc_receipt_writeoff
                     FROM xx_fin_translatevalues
                    WHERE translate_id IN (SELECT translate_id 
                              FROM xx_fin_translatedefinition 
                             WHERE translation_name = 'OD_AR_REFUND_WRITEOFF' 
                               AND enabled_flag = 'Y')
                      AND source_value1 = lc_payment_type
                      AND source_value2 IS NULL;
		       EXCEPTION
		       WHEN OTHERS
		       THEN
		           lc_receipt_writeoff := NULL;
		       END;
		    ELSE
		       BEGIN
		           SELECT lc_country_prefix||target_value1
		    	     INTO lc_receipt_writeoff
                     FROM xx_fin_translatevalues
                    WHERE translate_id IN (SELECT translate_id 
                              FROM xx_fin_translatedefinition 
                             WHERE translation_name = 'OD_AR_REFUND_WRITEOFF' 
                               AND enabled_flag = 'Y')
                      AND source_value1 = lc_payment_type
                      AND source_value2 IS NULL;
		       EXCEPTION
		       WHEN OTHERS
		       THEN
		           lc_receipt_writeoff := NULL;
				   fnd_message.set_name('XXFIN','XX_AR_I1025_20005_BAD_PMT_TYPE');
                   fnd_message.set_token('SUB_NAME',lc_sub_name);
                   fnd_message.set_token('PAYMENT_TYPE_CODE',lc_payment_type);
                   raise_application_error(-20005,fnd_message.get() );
		       END;
		    END IF;
	    WHEN OTHERS
        THEN
            lc_receipt_writeoff := NULL;
			fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20005_BAD_PMT_TYPE');
            fnd_message.set_token('SUB_NAME',
                                  lc_sub_name);
            fnd_message.set_token('PAYMENT_TYPE_CODE',
                                  lc_payment_type);
            raise_application_error(-20005,
                                    fnd_message.get() );
        END;	
      -- End of adding changes as per Version 17.0 by Havish K		
    -- RETURN NULL; -- Commneted as per Version 17.0 by Havish K
	RETURN lc_receipt_writeoff; -- Added as per Version 17.0 by Havish K
    END;

-- ==========================================================================
-- procedure that returns the receipt write-off activity for the given
--   payment method code specifically for misc receipt creation
-- ==========================================================================
    FUNCTION get_refund_misc_rcpt_activity(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_sale_location      IN  VARCHAR2,
        p_payment_type_code  IN  VARCHAR2 DEFAULT NULL)
        RETURN VARCHAR2
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)  := 'GET_REFUND_MISC_RCPT_ACTIVITY';
        lc_payment_type       VARCHAR2(100) DEFAULT NULL;
        lc_country_prefix     VARCHAR2(50)  DEFAULT NULL;
    BEGIN
-- ==========================================================================
-- get the country code prefix for the given operating unit (org_id)
-- ==========================================================================
        lc_country_prefix := xx_ar_prepayments_pkg.get_country_prefix(p_org_id);
-- ==========================================================================
-- get the payment method based on the given AR receipt method
-- ==========================================================================
        lc_payment_type :=
            xx_ar_prepayments_pkg.get_payment_type(p_org_id =>                 p_org_id,
                                                   p_receipt_method_id =>      p_receipt_method_id,
                                                   p_payment_type =>           p_payment_type_code);

-- ==========================================================================
-- determine the refund activity for the given refund tender (receipt method)
--   the only refund write-off activities we have should be for misc rcpts:
--     debit card and telecheck
-- ==========================================================================
        IF (lc_payment_type = 'DEBIT_CARD')
        THEN
            RETURN    lc_country_prefix
                   || '_REFUND_DEBIT_CARD_MISC_OD';
        ELSIF(lc_payment_type = 'TELECHECK')
        THEN
            RETURN    lc_country_prefix
                   || '_REFUND_TELECHECK_MISC_OD';
        ELSE
            fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20005_BAD_PMT_TYPE');
            fnd_message.set_token('SUB_NAME',
                                  lc_sub_name);
            fnd_message.set_token('PAYMENT_TYPE_CODE',
                                  lc_payment_type);
            raise_application_error(-20005,
                                    fnd_message.get() );
        END IF;

        RETURN NULL;
    END;

-- ==========================================================================
-- procedure that returns the receivable trx id for the given receivable
--   trx name
-- ==========================================================================
    FUNCTION get_receivables_trx_id(
        p_org_id           IN  NUMBER,
        p_receivables_trx  IN  VARCHAR2)
        RETURN NUMBER
    IS
        lc_sub_name   CONSTANT VARCHAR2(50) := 'GET_RECEIVABLES_TRX_ID';
        ln_receivables_trx_id  NUMBER       DEFAULT NULL;

        CURSOR c_rcv_trx
        IS
            SELECT receivables_trx_id
            FROM   ar_receivables_trx_all
            WHERE  org_id = p_org_id
            AND    NAME = p_receivables_trx;
    BEGIN
        OPEN c_rcv_trx;

        FETCH c_rcv_trx
        INTO  ln_receivables_trx_id;

        CLOSE c_rcv_trx;

        RETURN ln_receivables_trx_id;
    END;

-- ==========================================================================
-- procedure that updates the receipt with the I1025 process code (attribute13)
--   it also returns the most recent copy of the cash receipt record
-- ==========================================================================
    PROCEDURE set_i1025_process_code(
        x_cash_receipt_rec    IN OUT NOCOPY  ar_cash_receipts%ROWTYPE,
        p_i1025_process_code  IN             VARCHAR2)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'SET_I1025_PROCESS_CODE';
    BEGIN
-- ==========================================================================
-- re-fetch the latest AR receipt
-- ==========================================================================
        arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec =>      x_cash_receipt_rec);

        IF (gb_debug)
        THEN
            put_log_line('Fetched Current Receipt: ');
            put_log_line(   '  cash receipt id = '
                         || x_cash_receipt_rec.cash_receipt_id);
            put_log_line(   '  receipt number  = '
                         || x_cash_receipt_rec.receipt_number);
        END IF;

-- ==========================================================================
-- set the I1025 process code to given process code
-- ==========================================================================
        x_cash_receipt_rec.attribute13 :=    p_i1025_process_code
                                          || '|'
                                          || TO_CHAR(SYSDATE,
                                                     'YYYY/MM/DD HH24:MI:SS');
-- ==========================================================================
-- update the AR receipts with new process status
-- ==========================================================================
        arp_cash_receipts_pkg.update_p(p_cr_rec =>      x_cash_receipt_rec);

        IF (gb_debug)
        THEN
            put_log_line(   '- Updated Receipt: '
                         || x_cash_receipt_rec.receipt_number);
            put_log_line(   '  I1025 Process Code (ATTRIBUTE13) = '
                         || p_i1025_process_code);
        END IF;
    END;

-- ==========================================================================
-- set the attributes for a cash receipt rowtype
-- ==========================================================================
    PROCEDURE set_receipt_attributes(
        p_receipt_context          IN             VARCHAR2,
        p_orig_sys_document_ref    IN             oe_order_headers.orig_sys_document_ref%TYPE,
        p_receipt_method_id        IN             ar_cash_receipts.receipt_method_id%TYPE,
        p_payment_type_code        IN             oe_payments.payment_type_code%TYPE,
        p_check_number             IN             oe_payments.check_number%TYPE DEFAULT NULL,
        p_paid_at_store_id         IN             NUMBER DEFAULT NULL,
        p_ship_from_org_id         IN             oe_order_headers.ship_from_org_id%TYPE DEFAULT NULL,
        p_cc_auth_manual           IN             VARCHAR2 DEFAULT NULL,
        p_cc_auth_ps2000           IN             VARCHAR2 DEFAULT NULL,
        p_merchant_number          IN             VARCHAR2 DEFAULT NULL,
        p_od_payment_type          IN             VARCHAR2 DEFAULT NULL,
        p_debit_card_approval_ref  IN             VARCHAR2 DEFAULT NULL,
        p_cc_mask_number           IN             VARCHAR2 DEFAULT NULL,
        p_payment_amount           IN             NUMBER DEFAULT NULL,
        p_original_receipt_id      IN             NUMBER DEFAULT NULL,
        p_transaction_number       IN             VARCHAR2 DEFAULT NULL,
        p_imp_file_name            IN             VARCHAR2 DEFAULT NULL,
        p_om_import_date           IN             DATE DEFAULT NULL,
        p_i1025_record_type        IN             VARCHAR2 DEFAULT NULL,
        p_called_from              IN             VARCHAR2 DEFAULT NULL,
        p_print_debug              IN             VARCHAR2 DEFAULT fnd_api.g_false,
        x_cash_receipt_rec         IN OUT NOCOPY  ar_cash_receipts%ROWTYPE,
        x_receipt_ext_attributes   IN OUT NOCOPY  xx_ar_cash_receipts_ext%ROWTYPE)
    IS
        lc_sub_name          CONSTANT VARCHAR2(50)                                         := 'SET_RECEIPT_ATTRIBUTES';
        x_receipt_number              ar_cash_receipts.receipt_number%TYPE                 DEFAULT NULL;
        x_receipt_comments            ar_cash_receipts.comments%TYPE                       DEFAULT NULL;
        x_customer_receipt_reference  ar_cash_receipts.customer_receipt_reference%TYPE     DEFAULT NULL;
        x_app_customer_reference      ar_receivable_applications.customer_reference%TYPE   DEFAULT NULL;
        x_app_comments                ar_receivable_applications.comments%TYPE             DEFAULT NULL;
        x_attributes                  ar_receipt_api_pub.attribute_rec_type;
        x_app_attributes              ar_receipt_api_pub.attribute_rec_type;
    --x_receipt_ext_attributes        XX_AR_CASH_RECEIPTS_EXT%ROWTYPE;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- assign current cash receipt attributes to the local variables
-- ==========================================================================
        x_attributes.attribute_category := x_cash_receipt_rec.attribute_category;
        x_attributes.attribute1 := x_cash_receipt_rec.attribute1;
        x_attributes.attribute2 := x_cash_receipt_rec.attribute2;
        x_attributes.attribute3 := x_cash_receipt_rec.attribute3;
        x_attributes.attribute4 := x_cash_receipt_rec.attribute4;
        x_attributes.attribute5 := x_cash_receipt_rec.attribute5;
        x_attributes.attribute6 := x_cash_receipt_rec.attribute6;
        x_attributes.attribute7 := x_cash_receipt_rec.attribute7;
        x_attributes.attribute8 := x_cash_receipt_rec.attribute8;
        x_attributes.attribute9 := x_cash_receipt_rec.attribute9;
        x_attributes.attribute10 := x_cash_receipt_rec.attribute10;
        x_attributes.attribute11 := x_cash_receipt_rec.attribute11;
        x_attributes.attribute12 := x_cash_receipt_rec.attribute12;
        x_attributes.attribute13 := x_cash_receipt_rec.attribute13;
        x_attributes.attribute14 := x_cash_receipt_rec.attribute14;
        x_attributes.attribute15 := x_cash_receipt_rec.attribute15;
        x_receipt_number := x_cash_receipt_rec.receipt_number;
        x_receipt_comments := x_cash_receipt_rec.comments;
        x_customer_receipt_reference := x_cash_receipt_rec.customer_receipt_reference;
-- ==========================================================================
-- assign receipt reference fields and DFFs
-- ==========================================================================
        xx_ar_prepayments_pkg.set_receipt_attr_references(p_receipt_context =>                 p_receipt_context,
                                                          p_orig_sys_document_ref =>           p_orig_sys_document_ref,
                                                          p_receipt_method_id =>               p_receipt_method_id,
                                                          p_payment_type_code =>               p_payment_type_code,
                                                          p_check_number =>                    p_check_number,
                                                          p_paid_at_store_id =>                p_paid_at_store_id,
                                                          p_ship_from_org_id =>                p_ship_from_org_id,
                                                          p_cc_auth_manual =>                  p_cc_auth_manual,
                                                          p_cc_auth_ps2000 =>                  p_cc_auth_ps2000,
                                                          p_merchant_number =>                 p_merchant_number,
                                                          p_od_payment_type =>                 p_od_payment_type,
                                                          p_cc_mask_number =>                  p_cc_mask_number,
                                                          p_payment_amount =>                  p_payment_amount,
                                                          p_debit_card_approval_ref =>         p_debit_card_approval_ref,
                                                          --p_applied_customer_trx_id      => p_current_row.customer_trx_id,
                                                          p_original_receipt_id =>             p_original_receipt_id,
                                                          p_transaction_number =>              p_transaction_number,
                                                          p_imp_file_name =>                   p_imp_file_name,
                                                          p_om_import_date =>                  p_om_import_date,
                                                          p_i1025_record_type =>               p_i1025_record_type,
                                                          p_called_from =>                     p_called_from,
                                                          p_print_debug =>                     get_debug_char(),
                                                          x_receipt_number =>                  x_receipt_number,
                                                          x_receipt_comments =>                x_receipt_comments,
                                                          x_customer_receipt_reference =>      x_customer_receipt_reference,
                                                          x_attribute_rec =>                   x_attributes,
                                                          x_app_customer_reference =>          x_app_customer_reference,
                                                          x_app_comments =>                    x_app_comments,
                                                          x_app_attribute_rec =>               x_app_attributes,
                                                          x_receipt_ext_attributes =>          x_receipt_ext_attributes);
-- ==========================================================================
-- assign back local variable attributes to cash receipt rowtype output
-- ==========================================================================
        x_cash_receipt_rec.attribute_category := x_attributes.attribute_category;
        x_cash_receipt_rec.attribute1 := x_attributes.attribute1;
        x_cash_receipt_rec.attribute2 := x_attributes.attribute2;
        x_cash_receipt_rec.attribute3 := x_attributes.attribute3;
        x_cash_receipt_rec.attribute4 := x_attributes.attribute4;
        x_cash_receipt_rec.attribute5 := x_attributes.attribute5;
        x_cash_receipt_rec.attribute6 := x_attributes.attribute6;
        x_cash_receipt_rec.attribute7 := x_attributes.attribute7;
        x_cash_receipt_rec.attribute8 := x_attributes.attribute8;
        x_cash_receipt_rec.attribute9 := x_attributes.attribute9;
        x_cash_receipt_rec.attribute10 := x_attributes.attribute10;
        x_cash_receipt_rec.attribute11 := x_attributes.attribute11;
        x_cash_receipt_rec.attribute12 := x_attributes.attribute12;
        x_cash_receipt_rec.attribute13 := x_attributes.attribute13;
        x_cash_receipt_rec.attribute14 := x_attributes.attribute14;
        x_cash_receipt_rec.attribute15 := x_attributes.attribute15;
        x_cash_receipt_rec.receipt_number := x_receipt_number;
        x_cash_receipt_rec.comments := x_receipt_comments;
        x_cash_receipt_rec.customer_receipt_reference := x_customer_receipt_reference;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure that insert the deposits into this iPayment custom table, so
--   that the level-3 line data can be interfaced (since the order does not
--   yet exist in OM)
-- ==========================================================================
    PROCEDURE insert_iby_deposit_aops_orders(
        p_aops_order_number  IN  VARCHAR2,
        p_receipt_number     IN  VARCHAR2,
        p_tran_number        IN  VARCHAR2)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'INSERT_IBY_DEPOSIT_AOPS_ORDERS';

        CURSOR l_cur(
            p_tran_number  IN  VARCHAR2)
        IS
            SELECT DISTINCT NVL(od.orig_sys_document_ref,
                                dtl.orig_sys_document_ref) orig_sys_document_ref
            FROM            xx_om_legacy_dep_dtls dtl, xx_om_legacy_deposits od
            WHERE           1 = 1
            AND             od.transaction_number = p_tran_number
            AND             LENGTH(NVL(od.orig_sys_document_ref,
                                       dtl.orig_sys_document_ref) ) <= 12
--       AND od.payment_number = 1
            AND             od.transaction_number = dtl.transaction_number(+);
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line('Inserting the deposit credit card data into XX_IBY_DEPOSIT_AOPS_ORDERS...');
            put_log_line(   '  AOPS Order Num: '
                         || p_aops_order_number);
            put_log_line(   '  Receipt Number: '
                         || p_receipt_number);
            put_log_line(   '  Transaction Number: '
                         || p_tran_number);
        END IF;

        FOR r_cur IN l_cur(p_tran_number)
        LOOP
            INSERT INTO xx_iby_deposit_aops_orders
                        (aops_order_number,
                         receipt_number,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by,
                         last_update_login,
                         program_application_id,
                         program_id,
                         program_update_date,
                         process_flag)   -- Added for Defect 11555
            VALUES      (r_cur.orig_sys_document_ref,
                         p_receipt_number,
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.user_id,
                         fnd_global.login_id,
                         CASE
                             WHEN fnd_global.conc_request_id > 0
                                 THEN fnd_global.prog_appl_id
                             ELSE NULL
                         END,
                         CASE
                             WHEN fnd_global.conc_request_id > 0
                                 THEN fnd_global.conc_program_id
                             ELSE NULL
                         END,
                         CASE
                             WHEN fnd_global.conc_request_id > 0
                                 THEN SYSDATE
                             ELSE NULL
                         END,
                         'New');   -- Added for Defect 11555

            gn_cc_aops_deposits_num :=   gn_cc_aops_deposits_num
                                       + 1;
        END LOOP;

        IF (gb_debug)
        THEN
            put_log_line(   '# Inserted '
                         || SQL%ROWCOUNT
                         || ' row[s] in XX_IBY_DEPOSIT_AOPS_ORDERS');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            IF (gb_debug)
            THEN
                put_log_line(   'Exception in XX_IBY_DEPOSIT_AOPS_ORDERS :'
                             || SQLERRM);
            END IF;
    END;

-- ==========================================================================
-- procedure to insert the credit card refunds that could not be handled
--   through the standard functionality
-- ==========================================================================
    PROCEDURE insert_iby_cc_refunds(
        p_credit_card_number   IN  VARCHAR2,
        p_cc_expiration_date   IN  DATE,
        p_refund_date          IN  DATE,
        p_sale_location        IN  VARCHAR2,
        p_ship_from_org        IN  VARCHAR2,
        p_cash_receipt_id      IN  NUMBER,
        p_receipt_number       IN  VARCHAR2,
        p_header_id            IN  NUMBER,
        p_legacy_order_number  IN  VARCHAR2)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'INSERT_IBY_CC_REFUNDS';
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line('Inserting the credit card refund data into XX_IBY_CC_REFUNDS...');
            put_log_line(   '  Credit Card Num: '
                         || p_credit_card_number);
            put_log_line(   '  Expiration Date: '
                         || p_cc_expiration_date);
            put_log_line(   '  Refund Date    : '
                         || p_refund_date);
            put_log_line(   '  Sale Location  : '
                         || p_sale_location);
            put_log_line(   '  Ship From Org  : '
                         || p_ship_from_org);
            put_log_line(   '  Receipt Number : '
                         || p_receipt_number);
        END IF;

-- ==========================================================================
-- insert the credit card refund information into the custom iPayment table
-- ==========================================================================
        INSERT INTO xx_iby_cc_refunds
                    (credit_card_number,
                     credit_card_expiration,
                     refund_date,
                     sale_location,
                     cash_receipt_id,
                     receipt_number,
                     om_header_id,
                     legacy_order_number,
                     creation_date,
                     created_by,
                     last_update_date,
                     last_updated_by,
                     last_update_login,
                     program_application_id,
                     program_id,
                     program_update_date,
                     process_flag)   -- Added for Defect 11555
        VALUES      (p_credit_card_number,
                     p_cc_expiration_date,
                     p_refund_date,
                     NVL(p_sale_location,
                         p_ship_from_org),
                     p_cash_receipt_id,
                     p_receipt_number,
                     p_header_id,
                     p_legacy_order_number,
                     SYSDATE,
                     fnd_global.user_id,
                     SYSDATE,
                     fnd_global.user_id,
                     fnd_global.login_id,
                     CASE
                         WHEN fnd_global.conc_request_id > 0
                             THEN fnd_global.prog_appl_id
                         ELSE NULL
                     END,
                     CASE
                         WHEN fnd_global.conc_request_id > 0
                             THEN fnd_global.conc_program_id
                         ELSE NULL
                     END,
                     CASE
                         WHEN fnd_global.conc_request_id > 0
                             THEN SYSDATE
                         ELSE NULL
                     END,
                     'New');   -- Added for Defect 11555

        IF (gb_debug)
        THEN
            put_log_line(   'Inserted '
                         || SQL%ROWCOUNT
                         || ' row[s] in XX_IBY_CC_REFUNDS');
        END IF;
    END;

-- ==========================================================================
-- procedure that updates the legacy deposits with the cash receipt id
--   and payment set id, and also sets the process code to given value
-- ==========================================================================
    PROCEDURE update_legacy_deposit_record(
        p_rowid            IN  ROWID,
        p_process_code     IN  VARCHAR2,
        p_cash_receipt_id  IN  NUMBER DEFAULT NULL,
        p_payment_set_id   IN  NUMBER DEFAULT NULL,
        p_error_message    IN  VARCHAR2 DEFAULT NULL)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'UPDATE_LEGACY_DEPOSIT_RECORD';
    BEGIN
-- ==========================================================================
-- update XX_OM_LEGACY_DEPOSITS with cash_receipt_id and x_payment_set_id
-- ==========================================================================
        UPDATE xx_om_legacy_deposits
        SET process_code = p_process_code,
            cash_receipt_id = NVL(p_cash_receipt_id,
                                  cash_receipt_id),
            payment_set_id = NVL(p_payment_set_id,
                                 payment_set_id),
            i1025_update_date = SYSDATE,
            i1025_message =
                      CASE p_process_code
                          WHEN 'E'
                              THEN SUBSTR(p_error_message,
                                          1,
                                          2000)
                          WHEN 'C'
                              THEN NULL
                          ELSE i1025_message
                      END,
            last_update_date = SYSDATE,
            last_updated_by = fnd_global.user_id,
            last_update_login = fnd_global.login_id,
            program_update_date = CASE
                                     WHEN fnd_global.conc_request_id > 0
                                         THEN SYSDATE
                                     ELSE program_update_date
                                 END,
            program_id = CASE
                            WHEN fnd_global.conc_request_id > 0
                                THEN fnd_global.conc_program_id
                            ELSE program_id
                        END,
            program_application_id =
                            CASE
                                WHEN fnd_global.conc_request_id > 0
                                    THEN fnd_global.prog_appl_id
                                ELSE program_application_id
                            END
        WHERE  ROWID = p_rowid;

        IF (gb_debug)
        THEN
            put_log_line(   '# Updated '
                         || SQL%ROWCOUNT
                         || ' row[s] in XX_OM_LEGACY_DEPOSITS');
        END IF;
    END;

-- ==========================================================================
-- procedure that updates the refund tender record with the cash receipt id
--   and payment set id, and also sets the process code to given value
-- ==========================================================================
    PROCEDURE update_return_tender_record(
        p_rowid            IN  ROWID,
        p_process_code     IN  VARCHAR2,
        p_cash_receipt_id  IN  NUMBER DEFAULT NULL,
        p_payment_set_id   IN  NUMBER DEFAULT NULL,
        p_error_message    IN  VARCHAR2 DEFAULT NULL)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'UPDATE_RETURN_TENDER_RECORD';
    BEGIN
-- ==========================================================================
-- update XX_OM_LEGACY_DEPOSITS with cash_receipt_id and x_payment_set_id
-- ==========================================================================
        UPDATE xx_om_return_tenders_all
        SET process_code = p_process_code,
            cash_receipt_id = NVL(p_cash_receipt_id,
                                  cash_receipt_id),
            payment_set_id = NVL(p_payment_set_id,
                                 payment_set_id),
            i1025_update_date = SYSDATE,
            i1025_message =
                      CASE p_process_code
                          WHEN 'E'
                              THEN SUBSTR(p_error_message,
                                          1,
                                          2000)
                          WHEN 'C'
                              THEN NULL
                          ELSE i1025_message
                      END,
            last_update_date = SYSDATE,
            last_updated_by = fnd_global.user_id
        WHERE  ROWID = p_rowid;

        IF (gb_debug)
        THEN
            put_log_line(   '# Updated '
                         || SQL%ROWCOUNT
                         || ' row[s] in XX_OM_RETURN_TENDERS_ALL');
        END IF;
    END;

-- ==========================================================================
-- procedure that updates the legacy deposits with the I1025 process
-- ==========================================================================
    PROCEDURE update_deposit_i1025_process(
        p_rowid         IN  ROWID,
        p_i1025_status  IN  VARCHAR2)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'UPDATE_DEPOSIT_I1025_PROCESS';
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('Update the Deposit record with the new I1025 process');
            put_log_line(   '  I1025 status = '
                         || p_i1025_status);
        END IF;

-- ==========================================================================
-- update XX_OM_LEGACY_DEPOSITS
-- ==========================================================================
        UPDATE xx_om_legacy_deposits
        SET i1025_status = NVL(p_i1025_status,
                               i1025_status),
            i1025_update_date = SYSDATE
        WHERE  ROWID = p_rowid;

        IF (gb_debug)
        THEN
            put_log_line(   '# Updated '
                         || SQL%ROWCOUNT
                         || ' row[s] in XX_OM_LEGACY_DEPOSITS');
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure that updates the deposit refunds with the cash receipt id
--   change for CR #341
-- ==========================================================================
    PROCEDURE update_deposit_refund_cr_id(
        p_rowid            IN  ROWID,
        p_cash_receipt_id  IN  NUMBER)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'UPDATE_DEPOSIT_REFUND_CR_ID';
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('Update the Deposit refund record with the related cash receipt');
            put_log_line(   '  Cash Receipt = '
                         || p_cash_receipt_id);
        END IF;

-- ==========================================================================
-- update XX_OM_LEGACY_DEPOSITS
-- ==========================================================================
        UPDATE xx_om_legacy_deposits
        SET cash_receipt_id = p_cash_receipt_id
        WHERE  ROWID = p_rowid;

        IF (gb_debug)
        THEN
            put_log_line(   '# Updated '
                         || SQL%ROWCOUNT
                         || ' row[s] in XX_OM_LEGACY_DEPOSITS');
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure that updates the refund tenders with the I1025 process
-- ==========================================================================
    PROCEDURE update_refund_i1025_process(
        p_rowid         IN  ROWID,
        p_i1025_status  IN  VARCHAR2)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'UPDATE_REFUND_I1025_PROCESS';
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('Update the Refund record with the new I1025 process');
            put_log_line(   '  I1025 status = '
                         || p_i1025_status);
        END IF;

-- ==========================================================================
-- update XX_OM_RETURN_TENDERS_ALL
-- ==========================================================================
        UPDATE xx_om_return_tenders_all
        SET i1025_status = NVL(p_i1025_status,
                               i1025_status),
            i1025_update_date = SYSDATE
        WHERE  ROWID = p_rowid;

        IF (gb_debug)
        THEN
            put_log_line(   '# Updated '
                         || SQL%ROWCOUNT
                         || ' row[s] in XX_OM_RETURN_TENDERS_ALL');
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure that marks the specific fields/flags in the deposits table
--   XX_OM_LEGACY_DEPOSITS.  it also logs the errors/success in global vars
-- ==========================================================================
    PROCEDURE mark_create_deposit_record(
        p_index_num         IN             NUMBER,
        p_process_code      IN             VARCHAR2,
        p_deposits_row      IN OUT NOCOPY  gcu_deposits%ROWTYPE,
        p_cash_receipt_rec  IN OUT NOCOPY  ar_cash_receipts%ROWTYPE,
        p_payment_set_id    IN             NUMBER,
        p_error_code        IN             NUMBER DEFAULT NULL,
        p_error_message     IN             VARCHAR2 DEFAULT NULL,
        p_comments          IN             VARCHAR2 DEFAULT NULL)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'MARK_CREATE_DEPOSIT_RECORD';
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
            put_log_line(   '  Process Code    : '
                         || p_process_code);
            put_log_line(   '  Orig Sys Doc Ref: '
                         || p_deposits_row.orig_sys_document_ref);
            put_log_line(   '  Receipt Number  : '
                         || p_cash_receipt_rec.receipt_number);
            put_log_line(   '  Comments        : '
                         || p_comments);
        END IF;

        IF (p_process_code = 'C')
        THEN
            IF (NVL(p_error_code,
                    0) NOT IN(gn_err_record_locked, gn_err_deadlock_detected) )
            THEN
                update_legacy_deposit_record(p_rowid =>                p_deposits_row.ROWID,
                                             p_process_code =>         p_process_code,
                                             p_cash_receipt_id =>      p_cash_receipt_rec.cash_receipt_id,
                                             p_payment_set_id =>       p_payment_set_id);
            END IF;

            gn_create_deposits_good :=   gn_create_deposits_good
                                       + 1;
            g_create_deposits_recs(p_index_num) := NULL;
            g_create_deposits_recs(p_index_num).process_code := p_process_code;
            g_create_deposits_recs(p_index_num).record_status := 'Success';
            g_create_deposits_recs(p_index_num).MESSAGE := NULL;
            g_create_deposits_recs(p_index_num).orig_sys_document_ref := p_deposits_row.orig_sys_document_ref;
            g_create_deposits_recs(p_index_num).order_number := p_deposits_row.order_number;
            g_create_deposits_recs(p_index_num).payment_number := p_deposits_row.payment_number;
            g_create_deposits_recs(p_index_num).creation_date := p_deposits_row.creation_date;
            g_create_deposits_recs(p_index_num).receipt_method := p_deposits_row.receipt_method;
            g_create_deposits_recs(p_index_num).amount := p_deposits_row.amount;
            g_create_deposits_recs(p_index_num).receipt_number := p_cash_receipt_rec.receipt_number;
            g_create_deposits_recs(p_index_num).comments := p_comments;
        ELSIF(p_process_code = 'E')
        THEN
            IF (NVL(p_error_code,
                    0) NOT IN(gn_err_record_locked, gn_err_deadlock_detected) )
            THEN
                update_legacy_deposit_record(p_rowid =>              p_deposits_row.ROWID,
                                             p_process_code =>       p_process_code,
                                             p_error_message =>      p_error_message);
            END IF;

            gn_create_deposits_err :=   gn_create_deposits_err
                                      + 1;
            gn_return_code := 1;   -- mark program status as "Warning"
            g_create_deposits_recs(p_index_num) := NULL;
            g_create_deposits_recs(p_index_num).process_code := p_process_code;
            g_create_deposits_recs(p_index_num).record_status := 'Error';
            g_create_deposits_recs(p_index_num).MESSAGE := p_error_message;
            g_create_deposits_recs(p_index_num).orig_sys_document_ref := p_deposits_row.orig_sys_document_ref;
            g_create_deposits_recs(p_index_num).order_number := p_deposits_row.order_number;
            g_create_deposits_recs(p_index_num).payment_number := p_deposits_row.payment_number;
            g_create_deposits_recs(p_index_num).creation_date := p_deposits_row.creation_date;
            g_create_deposits_recs(p_index_num).receipt_method := p_deposits_row.receipt_method;
            g_create_deposits_recs(p_index_num).amount := p_deposits_row.amount;
            g_create_deposits_recs(p_index_num).receipt_number := p_cash_receipt_rec.receipt_number;
            g_create_deposits_recs(p_index_num).comments := p_comments;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure that marks the specific fields/flags in the refund tenders table
--   XX_OM_RETURN_TENDERS_ALL.  it also logs the errors/success in global vars
-- ==========================================================================
    PROCEDURE mark_create_refund_record(
        p_index_num         IN             NUMBER,
        p_process_code      IN             VARCHAR2,
        p_refunds_row       IN OUT NOCOPY  gcu_refunds%ROWTYPE,
        p_cash_receipt_rec  IN OUT NOCOPY  ar_cash_receipts%ROWTYPE,
        p_payment_set_id    IN             NUMBER,
        p_error_code        IN             NUMBER DEFAULT NULL,
        p_error_message     IN             VARCHAR2 DEFAULT NULL,
        p_comments          IN             VARCHAR2 DEFAULT NULL)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'MARK_CREATE_REFUND_RECORD';
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
            put_log_line(   '  Process Code    : '
                         || p_process_code);
            put_log_line(   '  Orig Sys Doc Ref: '
                         || p_refunds_row.orig_sys_document_ref);
            put_log_line(   '  Receipt Number  : '
                         || p_cash_receipt_rec.receipt_number);
            put_log_line(   '  Comments        : '
                         || p_comments);
        END IF;

        IF (p_process_code = 'C')
        THEN
            IF (NVL(p_error_code,
                    0) NOT IN(gn_err_record_locked, gn_err_deadlock_detected) )
            THEN
                update_return_tender_record(p_rowid =>                p_refunds_row.ROWID,
                                            p_process_code =>         p_process_code,
                                            p_cash_receipt_id =>      p_cash_receipt_rec.cash_receipt_id,
                                            p_payment_set_id =>       p_payment_set_id);
            END IF;

            gn_create_refunds_good :=   gn_create_refunds_good
                                      + 1;
            g_create_refunds_recs(p_index_num) := NULL;
            g_create_refunds_recs(p_index_num).process_code := p_process_code;
            g_create_refunds_recs(p_index_num).record_status := 'Success';
            g_create_refunds_recs(p_index_num).MESSAGE := NULL;
            g_create_refunds_recs(p_index_num).orig_sys_document_ref := p_refunds_row.orig_sys_document_ref;
            g_create_refunds_recs(p_index_num).order_number := p_refunds_row.order_number;
            g_create_refunds_recs(p_index_num).payment_number := p_refunds_row.payment_number;
            g_create_refunds_recs(p_index_num).creation_date := p_refunds_row.creation_date;
            g_create_refunds_recs(p_index_num).receipt_method := p_refunds_row.receipt_method;
            g_create_refunds_recs(p_index_num).amount := p_refunds_row.amount;
            g_create_refunds_recs(p_index_num).receipt_number := p_cash_receipt_rec.receipt_number;
            g_create_refunds_recs(p_index_num).comments := p_comments;
        ELSIF(p_process_code = 'E')
        THEN
            IF (NVL(p_error_code,
                    0) NOT IN(gn_err_record_locked, gn_err_deadlock_detected) )
            THEN
                update_return_tender_record(p_rowid =>              p_refunds_row.ROWID,
                                            p_process_code =>       p_process_code,
                                            p_error_message =>      p_error_message);
            END IF;

            gn_create_refunds_err :=   gn_create_refunds_err
                                     + 1;
            gn_return_code := 1;   -- mark program status as "Warning"
            g_create_refunds_recs(p_index_num) := NULL;
            g_create_refunds_recs(p_index_num).process_code := p_process_code;
            g_create_refunds_recs(p_index_num).record_status := 'Error';
            g_create_refunds_recs(p_index_num).MESSAGE := p_error_message;
            g_create_refunds_recs(p_index_num).orig_sys_document_ref := p_refunds_row.orig_sys_document_ref;
            g_create_refunds_recs(p_index_num).order_number := p_refunds_row.order_number;
            g_create_refunds_recs(p_index_num).payment_number := p_refunds_row.payment_number;
            g_create_refunds_recs(p_index_num).creation_date := p_refunds_row.creation_date;
            g_create_refunds_recs(p_index_num).receipt_method := p_refunds_row.receipt_method;
            g_create_refunds_recs(p_index_num).amount := p_refunds_row.amount;
            g_create_refunds_recs(p_index_num).receipt_number := p_cash_receipt_rec.receipt_number;
            g_create_refunds_recs(p_index_num).comments := p_comments;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure that logs the errors/success for apply refunds in global vars
-- ==========================================================================
    PROCEDURE mark_apply_refund_record(
        p_index_num       IN             NUMBER,
        p_process_code    IN             VARCHAR2,
        p_refund_cms_row  IN OUT NOCOPY  gcu_refund_cms%ROWTYPE,
        p_error_code      IN             NUMBER DEFAULT NULL,
        p_error_message   IN             VARCHAR2 DEFAULT NULL,
        p_comments        IN             VARCHAR2 DEFAULT NULL)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'MARK_APPLY_REFUND_RECORD';
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
            put_log_line(   '  Process Code    : '
                         || p_process_code);
            put_log_line(   '  Orig Sys Doc Ref: '
                         || p_refund_cms_row.orig_sys_document_ref);
            put_log_line(   '  Receipt Number  : '
                         || p_refund_cms_row.receipt_number);
            put_log_line(   '  Comments        : '
                         || p_comments);
        END IF;

        IF (p_process_code = 'C')
        THEN
            IF (NVL(p_error_code,
                    0) NOT IN(gn_err_record_locked, gn_err_deadlock_detected) )
            THEN
                update_return_tender_record(p_rowid =>                p_refund_cms_row.ROWID,
                                            p_process_code =>         p_process_code,
                                            p_cash_receipt_id =>      p_refund_cms_row.cash_receipt_id,
                                            p_payment_set_id =>       p_refund_cms_row.payment_set_id);
            END IF;

            gn_apply_refunds_good :=   gn_apply_refunds_good
                                     + 1;
            g_apply_refunds_recs(p_index_num) := NULL;
            g_apply_refunds_recs(p_index_num).process_code := p_process_code;
            g_apply_refunds_recs(p_index_num).record_status := 'Success';
            g_apply_refunds_recs(p_index_num).MESSAGE := NULL;
            g_apply_refunds_recs(p_index_num).orig_sys_document_ref := p_refund_cms_row.orig_sys_document_ref;
            g_apply_refunds_recs(p_index_num).order_number := p_refund_cms_row.order_number;
            g_apply_refunds_recs(p_index_num).payment_number := p_refund_cms_row.payment_number;
            g_apply_refunds_recs(p_index_num).creation_date := p_refund_cms_row.creation_date;
            g_apply_refunds_recs(p_index_num).receipt_method := p_refund_cms_row.receipt_method;
            g_apply_refunds_recs(p_index_num).amount := p_refund_cms_row.amount;
            g_apply_refunds_recs(p_index_num).receipt_number := p_refund_cms_row.receipt_number;
            g_apply_refunds_recs(p_index_num).comments := p_comments;
        ELSIF(p_process_code = 'E')
        THEN
            IF (NVL(p_error_code,
                    0) NOT IN(gn_err_record_locked, gn_err_deadlock_detected) )
            THEN
                update_return_tender_record(p_rowid =>              p_refund_cms_row.ROWID,
                                            p_process_code =>       p_process_code,
                                            p_error_message =>      p_error_message);
            END IF;

            gn_apply_refunds_err :=   gn_apply_refunds_err
                                    + 1;
            gn_return_code := 1;   -- mark program status as "Warning"
            g_apply_refunds_recs(p_index_num) := NULL;
            g_apply_refunds_recs(p_index_num).process_code := p_process_code;
            g_apply_refunds_recs(p_index_num).record_status := 'Error';
            g_apply_refunds_recs(p_index_num).MESSAGE := p_error_message;
            g_apply_refunds_recs(p_index_num).orig_sys_document_ref := p_refund_cms_row.orig_sys_document_ref;
            g_apply_refunds_recs(p_index_num).order_number := p_refund_cms_row.order_number;
            g_apply_refunds_recs(p_index_num).payment_number := p_refund_cms_row.payment_number;
            g_apply_refunds_recs(p_index_num).creation_date := p_refund_cms_row.creation_date;
            g_apply_refunds_recs(p_index_num).receipt_method := p_refund_cms_row.receipt_method;
            g_apply_refunds_recs(p_index_num).amount := p_refund_cms_row.amount;
            g_apply_refunds_recs(p_index_num).receipt_number := p_refund_cms_row.receipt_number;
            g_apply_refunds_recs(p_index_num).comments := p_comments;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- get the original order/invoice payment for the given refund
-- ==========================================================================
    FUNCTION get_original_receipt(
        p_current_row  IN OUT NOCOPY  gt_current_record,
        x_original     IN OUT NOCOPY  gt_original)
        RETURN BOOLEAN
    IS
        lc_sub_name        CONSTANT VARCHAR2(50)        := 'GET_ORIGINAL_RECEIPT';
        x_customer_bank_account_id  NUMBER              DEFAULT NULL;
        x_cc_no_matched             VARCHAR2(100)       DEFAULT NULL;

        CURSOR c_order
        IS
            SELECT ool.credit_invoice_line_id,
                   ool.reference_customer_trx_line_id,
                   ool.reference_header_id,
                   ool.reference_line_id,
                   xola.ret_orig_order_num,
                   ooh2.order_number,
                   xola.ret_orig_order_line_num,
                   ooh.sold_to_org_id customer_id
            FROM   oe_order_headers_all ooh,
                   oe_order_lines_all ool,
                   xx_om_line_attributes_all xola,
                   oe_order_headers_all ooh2
            WHERE  ooh.header_id = ool.header_id
            AND    ool.line_id = xola.line_id
            AND    xola.ret_orig_order_num = ooh2.orig_sys_document_ref
            AND    ooh.header_id = p_current_row.header_id;

        l_order                     c_order%ROWTYPE;

        CURSOR c_ref_invoice(
            cp_customer_trx_line_id  IN  NUMBER,
            cp_receipt_method_id     IN  NUMBER)
        IS
            SELECT acr.cash_receipt_id,
                   acr.receipt_number,
                   acr.status receipt_status,
                   acr.amount receipt_amount,
                   acr.receipt_method_id,
                   acr.pay_from_customer,
                   NULL credit_card_number,
                   NULL IDENTIFIER,
                   acr.customer_site_use_id,
                   arm.NAME receipt_method,
                   arl.receipt_class_id,
                   arl.NAME receipt_class,
                   ara.amount_applied,
                   ara.application_type,
                   ara.status application_status,
                   rct.trx_number,
                   rctl.sales_order
            FROM   ra_customer_trx_all rct,
                   ra_customer_trx_lines_all rctl,
                   ar_receivable_applications_all ara,
                   ar_cash_receipts_all acr,
                   ar_receipt_methods arm,
                   ar_receipt_classes arl
            WHERE  ara.cash_receipt_id = acr.cash_receipt_id
            AND    ara.cash_receipt_id = acr.cash_receipt_id
            AND    acr.receipt_method_id = arm.receipt_method_id
            AND    arm.receipt_class_id = arl.receipt_class_id
            AND    ara.applied_customer_trx_id = rctl.customer_trx_id
            AND    rct.customer_trx_id = rctl.customer_trx_id
            AND    ara.status = 'APP'
            AND    ara.display = 'Y'
            AND    rctl.customer_trx_line_id = cp_customer_trx_line_id
            AND    acr.receipt_method_id = cp_receipt_method_id;

        TYPE t_ref_invoice_tab IS TABLE OF c_ref_invoice%ROWTYPE
            INDEX BY PLS_INTEGER;

        l_ref_invoice_tab           t_ref_invoice_tab;

        CURSOR c_ref_order(
            cp_order_header_id    IN  NUMBER,
            cp_receipt_method_id  IN  NUMBER)
        IS
            -- added ordered hint to improve performance
            SELECT          /*+ ORDERED */
            DISTINCT        acr.cash_receipt_id,
                            acr.receipt_number,
                            acr.status receipt_status,
                            acr.amount receipt_amount,
                            acr.receipt_method_id,
                            acr.pay_from_customer,
                            NULL credit_card_number,
                            NULL IDENTIFIER,
                            acr.customer_site_use_id,
                            arm.NAME receipt_method,
                            arl.receipt_class_id,
                            arl.NAME receipt_class,
                            ara.amount_applied,
                            ara.application_type,
                            ara.status application_status,
                            ooh.orig_sys_document_ref,
                            ooh.order_number
            FROM            oe_order_headers_all ooh,
                            oe_payments op,
                            ar_receivable_applications_all ara,
                            ar_cash_receipts_all acr,
                            ar_receipt_methods arm,
                            ar_receipt_classes arl
            WHERE           ara.cash_receipt_id = acr.cash_receipt_id
            AND             ara.cash_receipt_id = acr.cash_receipt_id
            AND             acr.receipt_method_id = arm.receipt_method_id
            AND             arm.receipt_class_id = arl.receipt_class_id
            AND             ooh.header_id = op.header_id
            AND             op.receipt_method_id = acr.receipt_method_id
            AND             op.payment_set_id = ara.payment_set_id
            AND             ara.status = 'OTHER ACC'
            AND             ara.display = 'Y'
            AND             ara.applied_payment_schedule_id = -7   -- prepayment
            AND             ara.application_ref_type = 'OM'
            AND             ara.application_ref_id = ooh.header_id
            AND             ooh.header_id = cp_order_header_id
            AND             acr.receipt_method_id = cp_receipt_method_id;

        TYPE t_ref_order_tab IS TABLE OF c_ref_order%ROWTYPE
            INDEX BY PLS_INTEGER;

        l_ref_order_tab             t_ref_order_tab;

        CURSOR c_ref_order_inv(
            cp_ret_orig_order_num  IN  VARCHAR2,   -- changed to VARCHAR2, Defect 3385
            cp_receipt_method_id   IN  NUMBER)
        IS
            SELECT acr.cash_receipt_id,
                   acr.receipt_number,
                   acr.status receipt_status,
                   acr.amount receipt_amount,
                   acr.receipt_method_id,
                   acr.pay_from_customer,
                   NULL credit_card_number,
                   NULL IDENTIFIER,
                   acr.customer_site_use_id,
                   arm.NAME receipt_method,
                   arl.receipt_class_id,
                   arl.NAME receipt_class,
                   ara.amount_applied,
                   ara.application_type,
                   ara.status application_status,
                   rct.trx_number,
                   rct.interface_header_attribute1
            FROM   ra_customer_trx_all rct,
                   ar_receivable_applications_all ara,
                   ar_cash_receipts_all acr,
                   ar_receipt_methods arm,
                   ar_receipt_classes arl
            WHERE  ara.cash_receipt_id = acr.cash_receipt_id
            AND    ara.cash_receipt_id = acr.cash_receipt_id
            AND    acr.receipt_method_id = arm.receipt_method_id
            AND    arm.receipt_class_id = arl.receipt_class_id
            AND    ara.status = 'APP'
            AND    ara.display = 'Y'
            AND    ara.applied_customer_trx_id = rct.customer_trx_id
            AND    rct.interface_header_context = 'ORDER ENTRY'
            AND    rct.interface_header_attribute1 = cp_ret_orig_order_num
            AND    acr.receipt_method_id = cp_receipt_method_id;

        TYPE t_ref_order_inv_tab IS TABLE OF c_ref_order_inv%ROWTYPE
            INDEX BY PLS_INTEGER;

        l_ref_order_inv_tab         t_ref_order_inv_tab;

        CURSOR c_ref_attr(
            cp_orig_sys_document_ref  IN  VARCHAR2,
            cp_receipt_method_id      IN  NUMBER)
        IS
            -- added ordered hint to improve performance
            SELECT          /*+ ORDERED */
            DISTINCT        acr.cash_receipt_id,
                            acr.receipt_number,
                            acr.status receipt_status,
                            acr.amount receipt_amount,
                            acr.receipt_method_id,
                            acr.pay_from_customer,
                            NULL credit_card_number,
                            NULL IDENTIFIER,
                            acr.customer_site_use_id,
                            arm.NAME receipt_method,
                            arl.receipt_class_id,
                            arl.NAME receipt_class,
                            ara.amount_applied,
                            ara.application_type,
                            ara.status application_status,
                            ooh.orig_sys_document_ref,
                            ooh.order_number
            FROM            oe_order_headers_all ooh,
                            oe_payments op,
                            ar_receivable_applications_all ara,
                            ar_cash_receipts_all acr,
                            ar_receipt_methods arm,
                            ar_receipt_classes arl
            WHERE           ara.cash_receipt_id = acr.cash_receipt_id
            AND             ara.cash_receipt_id = acr.cash_receipt_id
            AND             acr.receipt_method_id = arm.receipt_method_id
            AND             arm.receipt_class_id = arl.receipt_class_id
            AND             ooh.header_id = op.header_id
            AND             op.receipt_method_id = acr.receipt_method_id
            AND             op.payment_set_id = ara.payment_set_id
            AND             ara.status = 'OTHER ACC'
            AND             ara.display = 'Y'
            AND             ara.applied_payment_schedule_id = -7   -- prepayment
            AND             ara.application_ref_type = 'OM'
            AND             ara.application_ref_id = ooh.header_id
            AND             ooh.orig_sys_document_ref = cp_orig_sys_document_ref
            AND             acr.receipt_method_id = cp_receipt_method_id;

        TYPE t_ref_attr_tab IS TABLE OF c_ref_attr%ROWTYPE
            INDEX BY PLS_INTEGER;

        l_ref_attr_tab              t_ref_attr_tab;

        CURSOR c_ref_attr_inv(
            cp_orig_order_number  IN  VARCHAR2,
            cp_receipt_method_id  IN  NUMBER)
        IS
            SELECT acr.cash_receipt_id,
                   acr.receipt_number,
                   acr.status receipt_status,
                   acr.amount receipt_amount,
                   acr.receipt_method_id,
                   acr.pay_from_customer,
                   NULL credit_card_number,
                   NULL IDENTIFIER,
                   acr.customer_site_use_id,
                   arm.NAME receipt_method,
                   arl.receipt_class_id,
                   arl.NAME receipt_class,
                   ara.amount_applied,
                   ara.application_type,
                   ara.status application_status,
                   rct.trx_number,
                   rct.interface_header_attribute1
            FROM   ra_customer_trx_all rct,
                   ar_receivable_applications_all ara,
                   ar_cash_receipts_all acr,
                   ar_receipt_methods arm,
                   ar_receipt_classes arl
            WHERE  ara.cash_receipt_id = acr.cash_receipt_id
            AND    ara.cash_receipt_id = acr.cash_receipt_id
            AND    acr.receipt_method_id = arm.receipt_method_id
            AND    arm.receipt_class_id = arl.receipt_class_id
            AND    ara.status = 'APP'
            AND    ara.display = 'Y'
            AND    ara.applied_customer_trx_id = rct.customer_trx_id
            AND    rct.interface_header_context = 'ORDER ENTRY'
            AND    rct.interface_header_attribute1 = cp_orig_order_number
            AND    acr.receipt_method_id = cp_receipt_method_id;

        TYPE t_ref_attr_inv_tab IS TABLE OF c_ref_attr_inv%ROWTYPE
            INDEX BY PLS_INTEGER;

        l_ref_attr_inv_tab          t_ref_attr_inv_tab;
    BEGIN
-- ==========================================================================
-- clear out any existing data in the x_original output parameter
-- ==========================================================================
        x_original := NULL;

-- ==========================================================================
-- get the references on the refund to the original order/invoice payment
-- ==========================================================================
        OPEN c_order;

        FETCH c_order
        INTO  l_order;

        IF (c_order%NOTFOUND)
        THEN
            RETURN FALSE;
        END IF;

        CLOSE c_order;

        IF (gb_debug)
        THEN
            put_log_line('Original Order/Invoice payment references:');
            put_log_line(   '  credit_invoice_line_id  : '
                         || l_order.credit_invoice_line_id);
            put_log_line(   '  ref_customer_trx_line_id: '
                         || l_order.reference_customer_trx_line_id);
            put_log_line(   '  reference_header_id     : '
                         || l_order.reference_header_id);
            put_log_line(   '  reference_line_id       : '
                         || l_order.reference_line_id);
            put_log_line(   '  ret_orig_order_num      : '
                         || l_order.ret_orig_order_num);
            put_log_line(   '  order_number (OM)       : '
                         || l_order.order_number);
            put_log_line(   '  ret_orig_order_line_num : '
                         || l_order.ret_orig_order_line_num);
            put_log_line(   '  refund customer_id      : '
                         || l_order.customer_id);
        END IF;

-- ==========================================================================
-- check that at least one of the references is defined
-- ==========================================================================
        IF (l_order.credit_invoice_line_id IS NOT NULL)
        THEN
-- ==========================================================================
-- look for the original invoice
-- ==========================================================================
            IF (gb_debug)
            THEN
                put_log_line('- Fetch the original invoice payment.');
            --put_log_line('  credit_invoice_line_id = ' || l_order.credit_invoice_line_id );
            END IF;

            OPEN c_ref_invoice(cp_customer_trx_line_id =>      l_order.credit_invoice_line_id,
                               cp_receipt_method_id =>         p_current_row.receipt_method_id);

            FETCH c_ref_invoice
            BULK COLLECT INTO l_ref_invoice_tab;

            CLOSE c_ref_invoice;

            IF (gb_debug)
            THEN
                put_log_line(   '# Original Reference Count = '
                             || l_ref_invoice_tab.COUNT);
                put_log_line();
            END IF;

            IF (l_ref_invoice_tab.COUNT > 0)
            THEN
                FOR i_index IN l_ref_invoice_tab.FIRST .. l_ref_invoice_tab.LAST
                LOOP
                    IF (gb_debug)
                    THEN
                        put_log_line('An original invoice payment was found for this refund tender.');
                        put_log_line(   '  Receipt Number = '
                                     || l_ref_invoice_tab(i_index).receipt_number);
                        put_log_line(   '  Receipt Method = '
                                     || l_ref_invoice_tab(i_index).receipt_method);
                        put_log_line(   '  Receipt Amount = '
                                     || l_ref_invoice_tab(i_index).receipt_amount);
                        put_log_line(   '  Amount Applied = '
                                     || l_ref_invoice_tab(i_index).amount_applied);
                        put_log_line(   '  Original Order = '
                                     || l_ref_invoice_tab(i_index).sales_order);
                        put_log_line(   '  Original Invoice = '
                                     || l_ref_invoice_tab(i_index).trx_number);
                        put_log_line(   '  Customer ID = '
                                     || l_ref_invoice_tab(i_index).pay_from_customer);
                        put_log_line();
                    END IF;

-- ==========================================================================
-- if the refund customer (or store) is different than the original,
--  then we must create a zero-dollar receipt instead of using original
--   defect 10914
-- ==========================================================================
                    IF (p_current_row.bill_to_customer_id <> l_ref_invoice_tab(i_index).pay_from_customer)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line('- Refund DOES NOT MATCH original receipt (Customer or Store is different).');
                        END IF;

                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20100_DIFF_CARDS');
                        add_message(p_current_row =>         p_current_row,
                                    p_message_code =>        'REFUND_NOT_MATCH_DIFF_CUSTOMER_STORE',
                                    p_message_text =>        fnd_message.get(),
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                        RETURN FALSE;
                    END IF;

-- ==========================================================================
-- if a matching record is found for the original credit card,
--   then check that the credit card numbers match
-- ==========================================================================
                    IF (p_current_row.payment_type_new IN('CREDIT_CARD', 'DEBIT_CARD') )
                    THEN
                        get_receipt_credit_card_info
                                                (p_cash_receipt_id =>         l_ref_invoice_tab(i_index).cash_receipt_id,
                                                 x_credit_card_number =>      l_ref_invoice_tab(i_index).credit_card_number,
                                                 x_identifier =>              l_ref_invoice_tab(i_index).IDENTIFIER);

                        IF (NOT encrypted_credit_cards_match
                                           (p_credit_card_number_enc_1 =>      p_current_row.credit_card_number,
                                            p_identifier_1 =>                  p_current_row.IDENTIFIER,
                                            p_credit_card_number_enc_2 =>      l_ref_invoice_tab(i_index).credit_card_number,
                                            p_identifier_2 =>                  l_ref_invoice_tab(i_index).IDENTIFIER) )
                        THEN
                            IF (gb_debug)
                            THEN
                                put_log_line
                                           ('- Refund DOES NOT MATCH original receipt (Credit card numbers different).');
                            END IF;

-- ==========================================================================
-- if more than one original receipt exists, check next one
-- ==========================================================================
                            IF (i_index < l_ref_invoice_tab.LAST)
                            THEN
                                put_log_line('- More original receipts exist, check the next one...');
                                GOTO next_ref_invoice;   -- mimics the CONTINUE command that isn't available until 11g
                            END IF;

                            fnd_message.set_name('XXFIN',
                                                 'XX_AR_I1025_20100_DIFF_CARDS');
                            add_message(p_current_row =>         p_current_row,
                                        p_message_code =>        'REFUND_NOT_MATCH_DIFF_CARD_NUMBERS',
                                        p_message_text =>        fnd_message.get(),
                                        p_error_location =>      lc_sub_name,
                                        p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                            RETURN FALSE;
                        END IF;
                    END IF;

-- ==========================================================================
-- if refunding more than the original receipt
-- ==========================================================================
                    IF (p_current_row.amount > l_ref_invoice_tab(i_index).receipt_amount)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line
                                        ('- Refund DOES NOT MATCH original receipt (Refund amt greater than original).');
                        END IF;

                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20101_OVER_REFUND');
                        add_message(p_current_row =>         p_current_row,
                                    p_message_code =>        'REFUND_NOT_MATCH_OVER_REFUND',
                                    p_message_text =>        fnd_message.get(),
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                        RETURN FALSE;
                    END IF;

                    x_original := NULL;
                    x_original.orig_sys_document_ref := l_order.ret_orig_order_num;
                    x_original.cash_receipt_id := l_ref_invoice_tab(i_index).cash_receipt_id;
                    x_original.receipt_number := l_ref_invoice_tab(i_index).receipt_number;
                    x_original.receipt_status := l_ref_invoice_tab(i_index).receipt_status;
                    x_original.receipt_amount := l_ref_invoice_tab(i_index).receipt_amount;
                    x_original.pay_from_customer := l_ref_invoice_tab(i_index).pay_from_customer;
                    x_original.credit_card_number := l_ref_invoice_tab(i_index).credit_card_number;
                    x_original.IDENTIFIER := l_ref_invoice_tab(i_index).IDENTIFIER;
                    x_original.customer_site_use_id := l_ref_invoice_tab(i_index).customer_site_use_id;
                    x_original.receipt_method_id := l_ref_invoice_tab(i_index).receipt_method_id;
                    x_original.receipt_method := l_ref_invoice_tab(i_index).receipt_method;
                    x_original.receipt_class_id := l_ref_invoice_tab(i_index).receipt_class_id;
                    x_original.receipt_class := l_ref_invoice_tab(i_index).receipt_class;
                    x_original.amount_applied := l_ref_invoice_tab(i_index).amount_applied;
                    x_original.application_type := l_ref_invoice_tab(i_index).application_type;
                    x_original.application_status := l_ref_invoice_tab(i_index).application_status;
                    RETURN TRUE;

                    <<next_ref_invoice>>
                    NULL;
                END LOOP;
            END IF;
        ELSIF(l_order.reference_header_id IS NOT NULL)
        THEN
-- ==========================================================================
-- look for the original order header
-- ==========================================================================
            IF (gb_debug)
            THEN
                put_log_line('- Fetch the original order payment (using prepayment application).');
            --put_log_line('  reference_header_id = ' || l_order.reference_header_id );
            END IF;

            OPEN c_ref_order(cp_order_header_id =>        l_order.reference_header_id,
                             cp_receipt_method_id =>      p_current_row.receipt_method_id);

            FETCH c_ref_order
            BULK COLLECT INTO l_ref_order_tab;

            CLOSE c_ref_order;

            IF (gb_debug)
            THEN
                put_log_line(   '# Original Reference Count = '
                             || l_ref_order_tab.COUNT);
            END IF;

            IF (l_ref_order_tab.COUNT > 0)
            THEN
                FOR i_index IN l_ref_order_tab.FIRST .. l_ref_order_tab.LAST
                LOOP
                    IF (gb_debug)
                    THEN
                        put_log_line('An original order payment was found for this refund tender.');
                        put_log_line(   '  Receipt Number = '
                                     || l_ref_order_tab(i_index).receipt_number);
                        put_log_line(   '  Receipt Method = '
                                     || l_ref_order_tab(i_index).receipt_method);
                        put_log_line(   '  Receipt Amount = '
                                     || l_ref_order_tab(i_index).receipt_amount);
                        put_log_line(   '  Amount Applied = '
                                     || l_ref_order_tab(i_index).amount_applied);
                        put_log_line(   '  Original Order = '
                                     || l_ref_order_tab(i_index).order_number);
                        put_log_line(   '  Legacy Orig Order = '
                                     || l_ref_order_tab(i_index).orig_sys_document_ref);
                        put_log_line(   '  Customer ID = '
                                     || l_ref_order_tab(i_index).pay_from_customer);
                        put_log_line();
                    END IF;

-- ==========================================================================
-- if the refund customer (or store) is different than the original,
--  then we must create a zero-dollar receipt instead of using original
--   defect 10914
-- ==========================================================================
                    IF (p_current_row.bill_to_customer_id <> l_ref_order_tab(i_index).pay_from_customer)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line('- Refund DOES NOT MATCH original receipt (Customer or Store is different).');
                        END IF;

                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20100_DIFF_CARDS');
                        add_message(p_current_row =>         p_current_row,
                                    p_message_code =>        'REFUND_NOT_MATCH_DIFF_CUSTOMER_STORE',
                                    p_message_text =>        fnd_message.get(),
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                        RETURN FALSE;
                    END IF;

-- ==========================================================================
-- if a matching record is found for the original credit card,
--   then check that the credit card numbers match
-- ==========================================================================
                    IF (p_current_row.payment_type_new IN('CREDIT_CARD', 'DEBIT_CARD') )
                    THEN
                        get_receipt_credit_card_info
                                                  (p_cash_receipt_id =>         l_ref_order_tab(i_index).cash_receipt_id,
                                                   x_credit_card_number =>      l_ref_order_tab(i_index).credit_card_number,
                                                   x_identifier =>              l_ref_order_tab(i_index).IDENTIFIER);

                        IF (NOT encrypted_credit_cards_match
                                             (p_credit_card_number_enc_1 =>      p_current_row.credit_card_number,
                                              p_identifier_1 =>                  p_current_row.IDENTIFIER,
                                              p_credit_card_number_enc_2 =>      l_ref_order_tab(i_index).credit_card_number,
                                              p_identifier_2 =>                  l_ref_order_tab(i_index).IDENTIFIER) )
                        THEN
                            IF (gb_debug)
                            THEN
                                put_log_line
                                           ('- Refund DOES NOT MATCH original receipt (Credit card numbers different).');
                            END IF;

-- ==========================================================================
-- if more than one original receipt exists, check next one
-- ==========================================================================
                            IF (i_index < l_ref_order_tab.LAST)
                            THEN
                                put_log_line('- More original receipts exist, check the next one...');
                                GOTO next_ref_order;   -- mimics the CONTINUE command that isn't available until 11g
                            END IF;

                            fnd_message.set_name('XXFIN',
                                                 'XX_AR_I1025_20100_DIFF_CARDS');
                            add_message(p_current_row =>         p_current_row,
                                        p_message_code =>        'REFUND_NOT_MATCH_DIFF_CARD_NUMBERS',
                                        p_message_text =>        fnd_message.get(),
                                        p_error_location =>      lc_sub_name,
                                        p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                            RETURN FALSE;
                        END IF;
                    END IF;

-- ==========================================================================
-- if refunding more than the original receipt
-- ==========================================================================
                    IF (p_current_row.amount > l_ref_order_tab(i_index).receipt_amount)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line
                                        ('- Refund DOES NOT MATCH original receipt (Refund amt greater than original).');
                        END IF;

                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20101_OVER_REFUND');
                        add_message(p_current_row =>         p_current_row,
                                    p_message_code =>        'REFUND_NOT_MATCH_OVER_REFUND',
                                    p_message_text =>        fnd_message.get(),
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                        RETURN FALSE;
                    END IF;

                    x_original := NULL;
                    x_original.orig_sys_document_ref := l_order.ret_orig_order_num;
                    x_original.cash_receipt_id := l_ref_order_tab(i_index).cash_receipt_id;
                    x_original.receipt_number := l_ref_order_tab(i_index).receipt_number;
                    x_original.receipt_status := l_ref_order_tab(i_index).receipt_status;
                    x_original.receipt_amount := l_ref_order_tab(i_index).receipt_amount;
                    x_original.pay_from_customer := l_ref_order_tab(i_index).pay_from_customer;
                    x_original.credit_card_number := l_ref_order_tab(i_index).credit_card_number;
                    x_original.IDENTIFIER := l_ref_order_tab(i_index).IDENTIFIER;
                    x_original.customer_site_use_id := l_ref_order_tab(i_index).customer_site_use_id;
                    x_original.receipt_method_id := l_ref_order_tab(i_index).receipt_method_id;
                    x_original.receipt_method := l_ref_order_tab(i_index).receipt_method;
                    x_original.receipt_class_id := l_ref_order_tab(i_index).receipt_class_id;
                    x_original.receipt_class := l_ref_order_tab(i_index).receipt_class;
                    x_original.amount_applied := l_ref_order_tab(i_index).amount_applied;
                    x_original.application_type := l_ref_order_tab(i_index).application_type;
                    x_original.application_status := l_ref_order_tab(i_index).application_status;
                    RETURN TRUE;

                    <<next_ref_order>>
                    NULL;
                END LOOP;
            END IF;

-- ==========================================================================
-- look for the original order header
-- ==========================================================================
            IF (gb_debug)
            THEN
                put_log_line('- Fetch the original order payment (using invoice applied to receipt).');
            --put_log_line('  ret_orig_order_num = ' || l_order.ret_orig_order_num );
            END IF;

            OPEN c_ref_order_inv(cp_ret_orig_order_num =>      l_order.order_number,
                                 cp_receipt_method_id =>       p_current_row.receipt_method_id);

            FETCH c_ref_order_inv
            BULK COLLECT INTO l_ref_order_inv_tab;

            CLOSE c_ref_order_inv;

            IF (gb_debug)
            THEN
                put_log_line(   '# Original Reference Count = '
                             || l_ref_order_inv_tab.COUNT);
            END IF;

            IF (l_ref_order_inv_tab.COUNT > 0)
            THEN
                FOR i_index IN l_ref_order_inv_tab.FIRST .. l_ref_order_inv_tab.LAST
                LOOP
                    IF (gb_debug)
                    THEN
                        put_log_line('An original order payment was found for this refund tender.');
                        put_log_line(   '  Receipt Number = '
                                     || l_ref_order_inv_tab(i_index).receipt_number);
                        put_log_line(   '  Receipt Method = '
                                     || l_ref_order_inv_tab(i_index).receipt_method);
                        put_log_line(   '  Receipt Amount = '
                                     || l_ref_order_inv_tab(i_index).receipt_amount);
                        put_log_line(   '  Amount Applied = '
                                     || l_ref_order_inv_tab(i_index).amount_applied);
                        put_log_line(   '  Original Order = '
                                     || l_ref_order_inv_tab(i_index).interface_header_attribute1);
                        put_log_line(   '  Original Invoice = '
                                     || l_ref_order_inv_tab(i_index).trx_number);
                        put_log_line(   '  Customer ID = '
                                     || l_ref_order_inv_tab(i_index).pay_from_customer);
                        put_log_line();
                    END IF;

-- ==========================================================================
-- if the refund customer (or store) is different than the original,
--  then we must create a zero-dollar receipt instead of using original
--   defect 10914
-- ==========================================================================
                    IF (p_current_row.bill_to_customer_id <> l_ref_order_inv_tab(i_index).pay_from_customer)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line('- Refund DOES NOT MATCH original receipt (Customer or Store is different).');
                        END IF;

                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20100_DIFF_CARDS');
                        add_message(p_current_row =>         p_current_row,
                                    p_message_code =>        'REFUND_NOT_MATCH_DIFF_CUSTOMER_STORE',
                                    p_message_text =>        fnd_message.get(),
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                        RETURN FALSE;
                    END IF;

-- ==========================================================================
-- if a matching record is found for the original credit card,
--   then check that the credit card numbers match
-- ==========================================================================
                    IF (p_current_row.payment_type_new IN('CREDIT_CARD', 'DEBIT_CARD') )
                    THEN
                        get_receipt_credit_card_info
                                              (p_cash_receipt_id =>         l_ref_order_inv_tab(i_index).cash_receipt_id,
                                               x_credit_card_number =>      l_ref_order_inv_tab(i_index).credit_card_number,
                                               x_identifier =>              l_ref_order_inv_tab(i_index).IDENTIFIER);

                        IF (NOT encrypted_credit_cards_match
                                         (p_credit_card_number_enc_1 =>      p_current_row.credit_card_number,
                                          p_identifier_1 =>                  p_current_row.IDENTIFIER,
                                          p_credit_card_number_enc_2 =>      l_ref_order_inv_tab(i_index).credit_card_number,
                                          p_identifier_2 =>                  l_ref_order_inv_tab(i_index).IDENTIFIER) )
                        THEN
                            IF (gb_debug)
                            THEN
                                put_log_line
                                           ('- Refund DOES NOT MATCH original receipt (Credit card numbers different).');
                            END IF;

-- ==========================================================================
-- if more than one original receipt exists, check next one
-- ==========================================================================
                            IF (i_index < l_ref_order_inv_tab.LAST)
                            THEN
                                put_log_line('- More original receipts exist, check the next one...');
                                GOTO next_ref_order_inv;   -- mimics the CONTINUE command that isn't available until 11g
                            END IF;

                            fnd_message.set_name('XXFIN',
                                                 'XX_AR_I1025_20100_DIFF_CARDS');
                            add_message(p_current_row =>         p_current_row,
                                        p_message_code =>        'REFUND_NOT_MATCH_DIFF_CARD_NUMBERS',
                                        p_message_text =>        fnd_message.get(),
                                        p_error_location =>      lc_sub_name,
                                        p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                            RETURN FALSE;
                        END IF;
                    END IF;

-- ==========================================================================
-- if refunding more than the original receipt
-- ==========================================================================
                    IF (p_current_row.amount > l_ref_order_inv_tab(i_index).receipt_amount)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line
                                        ('- Refund DOES NOT MATCH original receipt (Refund amt greater than original).');
                        END IF;

                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20101_OVER_REFUND');
                        add_message(p_current_row =>         p_current_row,
                                    p_message_code =>        'REFUND_NOT_MATCH_OVER_REFUND',
                                    p_message_text =>        fnd_message.get(),
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                        RETURN FALSE;
                    END IF;

                    x_original := NULL;
                    x_original.orig_sys_document_ref := l_order.ret_orig_order_num;
                    x_original.cash_receipt_id := l_ref_order_inv_tab(i_index).cash_receipt_id;
                    x_original.receipt_number := l_ref_order_inv_tab(i_index).receipt_number;
                    x_original.receipt_status := l_ref_order_inv_tab(i_index).receipt_status;
                    x_original.receipt_amount := l_ref_order_inv_tab(i_index).receipt_amount;
                    x_original.pay_from_customer := l_ref_order_inv_tab(i_index).pay_from_customer;
                    x_original.credit_card_number := l_ref_order_inv_tab(i_index).credit_card_number;
                    x_original.IDENTIFIER := l_ref_order_inv_tab(i_index).IDENTIFIER;
                    x_original.customer_site_use_id := l_ref_order_inv_tab(i_index).customer_site_use_id;
                    x_original.receipt_method_id := l_ref_order_inv_tab(i_index).receipt_method_id;
                    x_original.receipt_method := l_ref_order_inv_tab(i_index).receipt_method;
                    x_original.receipt_class_id := l_ref_order_inv_tab(i_index).receipt_class_id;
                    x_original.receipt_class := l_ref_order_inv_tab(i_index).receipt_class;
                    x_original.amount_applied := l_ref_order_inv_tab(i_index).amount_applied;
                    x_original.application_type := l_ref_order_inv_tab(i_index).application_type;
                    x_original.application_status := l_ref_order_inv_tab(i_index).application_status;
                    RETURN TRUE;

                    <<next_ref_order_inv>>
                    NULL;
                END LOOP;
            END IF;
        ELSIF(l_order.ret_orig_order_num IS NOT NULL)
        THEN
-- ==========================================================================
-- look for the original order header (based on reference in
--   XX_OM_LINE_ATTRIBUTES_ALL.RET_ORIG_ORDER_NUM )
-- ==========================================================================
            IF (gb_debug)
            THEN
                put_log_line('- Fetch the original order payment (using prepayment application).');
                put_log_line('  (order reference from XX_OM_LINE_ATTRIBUTES_ALL) ');
            END IF;

            OPEN c_ref_attr(cp_orig_sys_document_ref =>      l_order.ret_orig_order_num,
                            cp_receipt_method_id =>          p_current_row.receipt_method_id);

            FETCH c_ref_attr
            BULK COLLECT INTO l_ref_attr_tab;

            CLOSE c_ref_attr;

            IF (gb_debug)
            THEN
                put_log_line(   '# Original Reference Count = '
                             || l_ref_attr_tab.COUNT);
            END IF;

            IF (l_ref_attr_tab.COUNT > 0)
            THEN
                FOR i_index IN l_ref_attr_tab.FIRST .. l_ref_attr_tab.LAST
                LOOP
                    IF (gb_debug)
                    THEN
                        put_log_line('An original order payment was found for this refund tender.');
                        put_log_line(   '  Receipt Number = '
                                     || l_ref_attr_tab(i_index).receipt_number);
                        put_log_line(   '  Receipt Method = '
                                     || l_ref_attr_tab(i_index).receipt_method);
                        put_log_line(   '  Receipt Amount = '
                                     || l_ref_attr_tab(i_index).receipt_amount);
                        put_log_line(   '  Amount Applied = '
                                     || l_ref_attr_tab(i_index).amount_applied);
                        put_log_line(   '  Original Order = '
                                     || l_ref_attr_tab(i_index).order_number);
                        put_log_line(   '  Legacy Orig Order = '
                                     || l_ref_attr_tab(i_index).orig_sys_document_ref);
                        put_log_line(   '  Customer ID = '
                                     || l_ref_attr_tab(i_index).pay_from_customer);
                        put_log_line();
                    END IF;

-- ==========================================================================
-- if the refund customer (or store) is different than the original,
--  then we must create a zero-dollar receipt instead of using original
--   defect 10914
-- ==========================================================================
                    IF (p_current_row.bill_to_customer_id <> l_ref_attr_tab(i_index).pay_from_customer)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line('- Refund DOES NOT MATCH original receipt (Customer or Store is different).');
                        END IF;

                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20100_DIFF_CARDS');
                        add_message(p_current_row =>         p_current_row,
                                    p_message_code =>        'REFUND_NOT_MATCH_DIFF_CUSTOMER_STORE',
                                    p_message_text =>        fnd_message.get(),
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                        RETURN FALSE;
                    END IF;

-- ==========================================================================
-- if refunding more than the original receipt
-- ==========================================================================
                    IF (p_current_row.amount > l_ref_attr_tab(i_index).receipt_amount)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line
                                        ('- Refund DOES NOT MATCH original receipt (Refund amt greater than original).');
                        END IF;

                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20101_OVER_REFUND');
                        add_message(p_current_row =>         p_current_row,
                                    p_message_code =>        'REFUND_NOT_MATCH_OVER_REFUND',
                                    p_message_text =>        fnd_message.get(),
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                        RETURN FALSE;
                    END IF;

                    x_original := NULL;
                    x_original.orig_sys_document_ref := l_order.ret_orig_order_num;
                    x_original.cash_receipt_id := l_ref_attr_tab(i_index).cash_receipt_id;
                    x_original.receipt_number := l_ref_attr_tab(i_index).receipt_number;
                    x_original.receipt_status := l_ref_attr_tab(i_index).receipt_status;
                    x_original.receipt_amount := l_ref_attr_tab(i_index).receipt_amount;
                    x_original.pay_from_customer := l_ref_attr_tab(i_index).pay_from_customer;
                    x_original.credit_card_number := l_ref_attr_tab(i_index).credit_card_number;
                    x_original.IDENTIFIER := l_ref_attr_tab(i_index).IDENTIFIER;
                    x_original.customer_site_use_id := l_ref_attr_tab(i_index).customer_site_use_id;
                    x_original.receipt_method_id := l_ref_attr_tab(i_index).receipt_method_id;
                    x_original.receipt_method := l_ref_attr_tab(i_index).receipt_method;
                    x_original.receipt_class_id := l_ref_attr_tab(i_index).receipt_class_id;
                    x_original.receipt_class := l_ref_attr_tab(i_index).receipt_class;
                    x_original.amount_applied := l_ref_attr_tab(i_index).amount_applied;
                    x_original.application_type := l_ref_attr_tab(i_index).application_type;
                    x_original.application_status := l_ref_attr_tab(i_index).application_status;
                    RETURN TRUE;

                    <<next_ref_attr>>
                    NULL;
                END LOOP;
            END IF;

-- ==========================================================================
-- look for the original order header (based on reference in
--   XX_OM_LINE_ATTRIBUTES_ALL.RET_ORIG_ORDER_NUM )
-- ==========================================================================
            IF (gb_debug)
            THEN
                put_log_line('- Fetch the original order payment (using invoice applied to receipt).');
                put_log_line('  (order reference from XX_OM_LINE_ATTRIBUTES_ALL) ');
            --put_log_line('  ret_orig_order_num = ' || l_order.ret_orig_order_num );
            END IF;

            OPEN c_ref_attr_inv(cp_orig_order_number =>      l_order.order_number,
                                cp_receipt_method_id =>      p_current_row.receipt_method_id);

            FETCH c_ref_attr_inv
            BULK COLLECT INTO l_ref_attr_inv_tab;

            CLOSE c_ref_attr_inv;

            IF (gb_debug)
            THEN
                put_log_line(   '# Original Reference Count = '
                             || l_ref_attr_inv_tab.COUNT);
            END IF;

            IF (l_ref_attr_inv_tab.COUNT > 0)
            THEN
                FOR i_index IN l_ref_attr_inv_tab.FIRST .. l_ref_attr_inv_tab.LAST
                LOOP
                    IF (gb_debug)
                    THEN
                        put_log_line('An original order payment was found for this refund tender.');
                        put_log_line(   '  Receipt Number = '
                                     || l_ref_attr_inv_tab(i_index).receipt_number);
                        put_log_line(   '  Receipt Method = '
                                     || l_ref_attr_inv_tab(i_index).receipt_method);
                        put_log_line(   '  Receipt Amount = '
                                     || l_ref_attr_inv_tab(i_index).receipt_amount);
                        put_log_line(   '  Amount Applied = '
                                     || l_ref_attr_inv_tab(i_index).amount_applied);
                        put_log_line(   '  Original Order = '
                                     || l_ref_attr_inv_tab(i_index).interface_header_attribute1);
                        put_log_line(   '  Original Invoice = '
                                     || l_ref_attr_inv_tab(i_index).trx_number);
                        --put_log_line( '  Legacy Orig Order = ' || l_ref_attr_inv_tab(i_index).orig_sys_document_ref );
                        put_log_line(   '  Customer ID = '
                                     || l_ref_attr_inv_tab(i_index).pay_from_customer);
                        put_log_line();
                    END IF;

-- ==========================================================================
-- if the refund customer (or store) is different than the original,
--  then we must create a zero-dollar receipt instead of using original
--   defect 10914
-- ==========================================================================
                    IF (p_current_row.bill_to_customer_id <> l_ref_attr_inv_tab(i_index).pay_from_customer)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line('- Refund DOES NOT MATCH original receipt (Customer or Store is different).');
                        END IF;

                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20100_DIFF_CARDS');
                        add_message(p_current_row =>         p_current_row,
                                    p_message_code =>        'REFUND_NOT_MATCH_DIFF_CUSTOMER_STORE',
                                    p_message_text =>        fnd_message.get(),
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                        RETURN FALSE;
                    END IF;

-- ==========================================================================
-- if a matching record is found for the original credit card,
--   then check that the credit card numbers match
-- ==========================================================================
                    IF (p_current_row.payment_type_new IN('CREDIT_CARD', 'DEBIT_CARD') )
                    THEN
                        get_receipt_credit_card_info
                                               (p_cash_receipt_id =>         l_ref_attr_inv_tab(i_index).cash_receipt_id,
                                                x_credit_card_number =>      l_ref_attr_inv_tab(i_index).credit_card_number,
                                                x_identifier =>              l_ref_attr_inv_tab(i_index).IDENTIFIER);

                        IF (NOT encrypted_credit_cards_match
                                          (p_credit_card_number_enc_1 =>      p_current_row.credit_card_number,
                                           p_identifier_1 =>                  p_current_row.IDENTIFIER,
                                           p_credit_card_number_enc_2 =>      l_ref_attr_inv_tab(i_index).credit_card_number,
                                           p_identifier_2 =>                  l_ref_attr_inv_tab(i_index).IDENTIFIER) )
                        THEN
                            IF (gb_debug)
                            THEN
                                put_log_line
                                           ('- Refund DOES NOT MATCH original receipt (Credit card numbers different).');
                            END IF;

-- ==========================================================================
-- if more than one original receipt exists, check next one
-- ==========================================================================
                            IF (i_index < l_ref_attr_inv_tab.LAST)
                            THEN
                                put_log_line('- More original receipts exist, check the next one...');
                                GOTO next_ref_attr_inv;   -- mimics the CONTINUE command that isn't available until 11g
                            END IF;

                            fnd_message.set_name('XXFIN',
                                                 'XX_AR_I1025_20100_DIFF_CARDS');
                            add_message(p_current_row =>         p_current_row,
                                        p_message_code =>        'REFUND_NOT_MATCH_DIFF_CARD_NUMBERS',
                                        p_message_text =>        fnd_message.get(),
                                        p_error_location =>      lc_sub_name,
                                        p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                            RETURN FALSE;
                        END IF;
                    END IF;

-- ==========================================================================
-- if refunding more than the original receipt
-- ==========================================================================
                    IF (p_current_row.amount > l_ref_attr_inv_tab(i_index).receipt_amount)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line
                                        ('- Refund DOES NOT MATCH original receipt (Refund amt greater than original).');
                        END IF;

                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20101_OVER_REFUND');
                        add_message(p_current_row =>         p_current_row,
                                    p_message_code =>        'REFUND_NOT_MATCH_OVER_REFUND',
                                    p_message_text =>        fnd_message.get(),
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                        RETURN FALSE;
                    END IF;

                    x_original := NULL;
                    x_original.orig_sys_document_ref := l_order.ret_orig_order_num;
                    x_original.cash_receipt_id := l_ref_attr_inv_tab(i_index).cash_receipt_id;
                    x_original.receipt_number := l_ref_attr_inv_tab(i_index).receipt_number;
                    x_original.receipt_status := l_ref_attr_inv_tab(i_index).receipt_status;
                    x_original.receipt_amount := l_ref_attr_inv_tab(i_index).receipt_amount;
                    x_original.pay_from_customer := l_ref_attr_inv_tab(i_index).pay_from_customer;
                    x_original.credit_card_number := l_ref_attr_inv_tab(i_index).credit_card_number;
                    x_original.IDENTIFIER := l_ref_attr_inv_tab(i_index).IDENTIFIER;
                    x_original.customer_site_use_id := l_ref_attr_inv_tab(i_index).customer_site_use_id;
                    x_original.receipt_method_id := l_ref_attr_inv_tab(i_index).receipt_method_id;
                    x_original.receipt_method := l_ref_attr_inv_tab(i_index).receipt_method;
                    x_original.receipt_class_id := l_ref_attr_inv_tab(i_index).receipt_class_id;
                    x_original.receipt_class := l_ref_attr_inv_tab(i_index).receipt_class;
                    x_original.amount_applied := l_ref_attr_inv_tab(i_index).amount_applied;
                    x_original.application_type := l_ref_attr_inv_tab(i_index).application_type;
                    x_original.application_status := l_ref_attr_inv_tab(i_index).application_status;
                    RETURN TRUE;

                    <<next_ref_attr_inv>>
                    NULL;
                END LOOP;
            END IF;
        ELSE
            IF (gb_debug)
            THEN
                put_log_line('- Refund DOES NOT MATCH original receipt (No original reference cound be found).');
            END IF;

            fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20102_NO_ORIG_REF');
            add_message(p_current_row =>         p_current_row,
                        p_message_code =>        'REFUND_NOT_MATCH_NO_REFERENCE',
                        p_message_text =>        fnd_message.get(),
                        p_error_location =>      lc_sub_name,
                        p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
            RETURN FALSE;   -- if no reference present, return false
        END IF;

        RETURN FALSE;
    END;

-- ==========================================================================
-- this create a receipt for the deposit payment
-- ==========================================================================
    PROCEDURE create_apply_deposit_receipt(
        p_current_row       IN OUT NOCOPY  gt_current_record,
        p_invoice_row       IN OUT NOCOPY  gcu_om_invoice%ROWTYPE,
        x_payment_set_id    IN OUT NOCOPY  NUMBER,
        x_cash_receipt_rec  IN OUT NOCOPY  ar_cash_receipts%ROWTYPE)
    IS
-- ==========================================================================
--V2.0 -- Start
        CURSOR c_dep_rcpt
        IS
            SELECT xoldd.orig_sys_document_ref
            FROM   xx_om_legacy_dep_dtls xoldd
            WHERE  xoldd.transaction_number = p_current_row.transaction_number;

--V2.0 -- End
-- ==========================================================================
        lc_sub_name           CONSTANT VARCHAR2(50)                                    := 'CREATE_APPLY_DEPOSIT_RECEIPT';
        x_return_status                VARCHAR2(20)                                         DEFAULT NULL;
        x_msg_count                    NUMBER                                               DEFAULT NULL;
        x_msg_data                     VARCHAR2(4000)                                       DEFAULT NULL;
        x_receipt_number               ar_cash_receipts.receipt_number%TYPE                 DEFAULT NULL;
        x_cash_receipt_id              ar_cash_receipts.cash_receipt_id%TYPE                DEFAULT NULL;
        lc_receipt_comments            ar_cash_receipts.comments%TYPE                       DEFAULT NULL;
        lc_customer_receipt_reference  ar_cash_receipts.customer_receipt_reference%TYPE     DEFAULT NULL;
        lc_app_customer_reference      ar_receivable_applications.customer_reference%TYPE   DEFAULT NULL;
        lc_app_comments                ar_receivable_applications.comments%TYPE             DEFAULT NULL;
        x_attributes                   ar_receipt_api_pub.attribute_rec_type;
        x_app_attributes               ar_receipt_api_pub.attribute_rec_type;
        x_receipt_ext_attributes       xx_ar_cash_receipts_ext%ROWTYPE;
        l_customer_rec                 gcu_customer_id%ROWTYPE;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- validate the customer account is defined
-- ==========================================================================
        IF (p_current_row.bill_to_customer_id IS NULL)
        THEN
            raise_missing_param_errors(p_sub_name =>        lc_sub_name,
                                       p_param_name =>      'Customer Account (SOLD_TO_ORG_ID)');
        END IF;

-- ==========================================================================
-- validate the receipt method is defined
-- ==========================================================================
        IF (p_current_row.receipt_method_id IS NULL)
        THEN
            raise_missing_param_errors(p_sub_name =>        lc_sub_name,
                                       p_param_name =>      'Receipt Method (RECEIPT_METHOD_ID)');
        END IF;

-- ==========================================================================
-- get primary bill-to customer information
-- ==========================================================================
        l_customer_rec :=
            get_bill_customer_by_id(p_org_id =>               p_current_row.org_id,
                                    p_cust_account_id =>      p_current_row.bill_to_customer_id);
-- ==========================================================================

        -- ==========================================================================
-- ==========================================================================
-- assign receipt reference fields and DFFs
-- ==========================================================================
        xx_ar_prepayments_pkg.set_receipt_attr_references
                                                    (p_receipt_context =>                 'SALES_ACCT',
                                                     p_orig_sys_document_ref =>           p_current_row.orig_sys_document_ref,
                                                     p_receipt_method_id =>               p_current_row.receipt_method_id,
                                                     p_payment_type_code =>               p_current_row.payment_type_code,
                                                     p_check_number =>                    p_current_row.check_number,
                                                     p_paid_at_store_id =>                p_current_row.paid_at_store_id,
                                                     p_ship_from_org_id =>                p_current_row.ship_from_org_id,
                                                     p_cc_auth_manual =>                  p_current_row.cc_auth_manual,
                                                     p_cc_auth_ps2000 =>                  p_current_row.cc_auth_ps2000,
                                                     p_merchant_number =>                 p_current_row.merchant_number,
                                                     p_od_payment_type =>                 p_current_row.od_payment_type,
                                                     p_debit_card_approval_ref =>         p_current_row.debit_card_approval_ref,
                                                     p_cc_mask_number =>                  p_current_row.cc_mask_number,
                                                     p_payment_amount =>                  p_current_row.amount,
                                                     p_applied_customer_trx_id =>         p_current_row.customer_trx_id,
                                                     p_original_receipt_id =>             NULL,
                                                     p_transaction_number =>              p_current_row.transaction_number,
                                                     p_imp_file_name =>                   p_current_row.imp_file_name,
                                                     p_om_import_date =>                  p_current_row.om_import_date,
                                                     p_i1025_record_type =>               p_current_row.record_type,
                                                     p_called_from =>                     'I1025',
                                                     p_print_debug =>                     get_debug_char(),
                                                     x_receipt_number =>                  x_receipt_number,
                                                     x_receipt_comments =>                lc_receipt_comments,
                                                     x_customer_receipt_reference =>      lc_customer_receipt_reference,
                                                     x_attribute_rec =>                   x_attributes,
                                                     x_app_customer_reference =>          lc_app_customer_reference,
                                                     x_app_comments =>                    lc_app_comments,
                                                     x_app_attribute_rec =>               x_app_attributes,
                                                     x_receipt_ext_attributes =>          x_receipt_ext_attributes);
-- ==========================================================================
-- assign receipt reference fields and DFFs specific to I1025
-- ==========================================================================
-- Payment Source
        x_attributes.attribute11 := 'SA_POST_PMT';
        -- Order Header ID
        --x_attributes.attribute12  := TO_CHAR(p_current_row.header_id);
        -- I1025 Process Code
        x_attributes.attribute13 :=    'MATCHED|'
                                    || TO_CHAR(SYSDATE,
                                               'YYYY/MM/DD HH24:MI:SS');

-- ==========================================================================
-- create and apply receipt to the invoice from the SA COD Post-Payment Order
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('Create and Apply Post-Payment Receipt to the SA Invoice.');
            put_log_line(   '  Trx Number      = '
                         || p_invoice_row.trx_number);
            put_log_line(   '  Trx Status      = '
                         || p_invoice_row.status_trx);
            put_log_line(   '  Pmt Schedule Id = '
                         || p_invoice_row.payment_schedule_id);
            put_log_line(   '  Amount Due      = '
                         || p_invoice_row.amount_due_remaining);
            put_log_line(   '  Amount to apply = '
                         || p_current_row.amount);
        END IF;

        -- added by Gaurav v2.0
        IF p_current_row.single_pay_ind = 'Y'
        THEN
            lc_receipt_comments := 'I1025 Create Deposit Receipt (Single Payment for POS )';
            x_attributes.attribute7 := NULL;

            FOR i IN c_dep_rcpt
            LOOP
                x_attributes.attribute7 :=    x_attributes.attribute7
                                           || '-'
                                           || i.orig_sys_document_ref;
            END LOOP;

            x_attributes.attribute7 := SUBSTR(SUBSTR(x_attributes.attribute7,
                                                     2),
                                              1,
                                              150);
        END IF;

        -- added by Gaurav v2.0
        IF (p_invoice_row.amount_due_remaining > 0)
        THEN
            ar_receipt_api_pub.create_and_apply(p_api_version =>                      1.0,
                                                p_init_msg_list =>                    fnd_api.g_true,
                                                p_commit =>                           fnd_api.g_false,
                                                p_validation_level =>                 fnd_api.g_valid_level_full,
                                                x_return_status =>                    x_return_status,
                                                x_msg_count =>                        x_msg_count,
                                                x_msg_data =>                         x_msg_data,
                                                p_currency_code =>                    p_current_row.currency_code,
                                                p_amount =>                           p_current_row.amount,
                                                p_receipt_method_id =>                p_current_row.receipt_method_id,
                                                p_customer_id =>                      l_customer_rec.cust_account_id,
                                                p_customer_site_use_id =>             l_customer_rec.site_use_id,
                                                p_customer_receipt_reference =>       lc_customer_receipt_reference,
                                                p_customer_bank_account_id =>         NULL,
                                                p_cr_id =>                            x_cash_receipt_id,
                                                p_receipt_date =>                     p_current_row.receipt_date,
                                                p_receipt_number =>                   x_receipt_number,
                                                p_receipt_comments =>                 lc_receipt_comments,
                                                app_comments =>                       lc_app_comments,
                                                p_called_from =>                      'I1025',
                                                p_applied_payment_schedule_id =>      p_invoice_row.payment_schedule_id,
                                                p_amount_applied =>                   p_invoice_row.amount_due_remaining,
                                                p_attribute_rec =>                    x_attributes,
                                                app_attribute_rec =>                  x_app_attributes);

            IF (gb_debug)
            THEN
                put_log_line(   '- Return Status: '
                             || x_return_status
                             || ', Msg Cnt: '
                             || x_msg_count);
            END IF;

            IF (x_return_status = 'S')
            THEN
                IF (gb_debug)
                THEN
                    put_log_line('Successfully created and applied the post-payment receipt.');
                    put_log_line(   '  x_cash_receipt_id = '
                                 || x_cash_receipt_id);
                    put_log_line(   '  x_payment_set_id = '
                                 || x_payment_set_id);
                END IF;
            ELSE
                raise_api_errors(p_sub_name =>       lc_sub_name,
                                 p_msg_count =>      x_msg_count,
                                 p_api_name =>       'AR_RECEIPT_API_PUB.create_and_apply');
            END IF;
        ELSE
            IF (gb_debug)
            THEN
                put_log_line('- Receipt will be left unapplied since invoice balance due is zero.');
            END IF;

            --p_preauthorized_flag => lc_preauthorized_flag , Removed by NB for R12 Upgrade as this api does not have
            ar_receipt_api_pub.create_cash(p_api_version =>                     1.0,
                                           p_init_msg_list =>                   fnd_api.g_true,
                                           p_commit =>                          fnd_api.g_false,
                                           p_validation_level =>                fnd_api.g_valid_level_full,
                                           x_return_status =>                   x_return_status,
                                           x_msg_count =>                       x_msg_count,
                                           x_msg_data =>                        x_msg_data,
                                           p_currency_code =>                   p_current_row.currency_code,
                                           p_amount =>                          p_current_row.amount,
                                           p_receipt_date =>                    p_current_row.receipt_date,
                                           p_receipt_method_id =>               p_current_row.receipt_method_id,
                                           p_customer_id =>                     l_customer_rec.cust_account_id,
                                           p_customer_site_use_id =>            l_customer_rec.site_use_id,
                                           p_customer_receipt_reference =>      p_current_row.check_number,
                                           p_customer_bank_account_id =>        NULL,
                                           p_cr_id =>                           x_cash_receipt_id,
                                           p_receipt_number =>                  x_receipt_number,
                                           p_comments =>                        'I1025 Deposit (Create Receipt)',
                                           p_called_from =>                     'I1025',
                                           p_attribute_rec =>                   x_attributes);

            IF (gb_debug)
            THEN
                put_log_line(   '- Return Status: '
                             || x_return_status
                             || ', Msg Cnt: '
                             || x_msg_count);
            END IF;

            IF (x_return_status = 'S')
            THEN
                IF (gb_debug)
                THEN
                    put_log_line('Successfully created the post-payment receipt.');
                    put_log_line(   '  x_cash_receipt_id = '
                                 || x_cash_receipt_id);
                    put_log_line(   '  x_payment_set_id = '
                                 || x_payment_set_id);
                END IF;
            ELSE
                raise_api_errors(p_sub_name =>       lc_sub_name,
                                 p_msg_count =>      x_msg_count,
                                 p_api_name =>       'AR_RECEIPT_API_PUB.create_cash');
            END IF;
        END IF;

        x_cash_receipt_rec.cash_receipt_id := x_cash_receipt_id;
-- ==========================================================================
-- re-fetch the latest AR receipt
-- ==========================================================================
        arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec =>      x_cash_receipt_rec);

        IF (gb_debug)
        THEN
            put_log_line('- Re-Fetched Receipt: ');
            put_log_line(   '  cash receipt id = '
                         || x_cash_receipt_rec.cash_receipt_id);
            put_log_line(   '  receipt number  = '
                         || x_cash_receipt_rec.receipt_number);
        END IF;

-- ==========================================================================
-- insert extra receipt info into XX_AR_CASH_RECEIPTS_EXT for deposit receipt
-- ==========================================================================
        x_receipt_ext_attributes.cash_receipt_id := x_cash_receipt_rec.cash_receipt_id;
        x_receipt_ext_attributes.payment_number := p_current_row.payment_number;
        x_receipt_ext_attributes.cc_entry_mode := p_current_row.cc_entry_mode;
        x_receipt_ext_attributes.cvv_resp_code := p_current_row.cvv_resp_code;
        x_receipt_ext_attributes.avs_resp_code := p_current_row.avs_resp_code;
        x_receipt_ext_attributes.auth_entry_mode := p_current_row.auth_entry_mode;
        xx_ar_prepayments_pkg.insert_receipt_ext_info(p_receipt_ext_attributes =>      x_receipt_ext_attributes);

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- this refunds the balance of the receipt to the credit card
-- ==========================================================================
    PROCEDURE update_misc_receipt_attrs_refs(
        x_misc_receipt_rec  IN OUT NOCOPY  ar_cash_receipts%ROWTYPE,
        p_current_row       IN OUT NOCOPY  gt_current_record)
    IS
        lc_sub_name      CONSTANT VARCHAR2(50)                      := 'UPDATE_MISC_RECEIPT_ATTRS_REFS';
        x_receipt_ext_attributes  xx_ar_cash_receipts_ext%ROWTYPE;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- validate the customer account is defined
-- ==========================================================================
        IF (x_misc_receipt_rec.cash_receipt_id IS NULL)
        THEN
            raise_missing_param_errors(p_sub_name =>        lc_sub_name,
                                       p_param_name =>      'Cash Receipt (CASH_RECEIPT_ID)');
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   '  Misc Receipt Id = '
                         || x_misc_receipt_rec.cash_receipt_id);
        END IF;

-- ==========================================================================
-- re-fetch the latest AR receipt
-- ==========================================================================
        arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec =>      x_misc_receipt_rec);

        IF (gb_debug)
        THEN
            put_log_line('Fetched Misc Receipt for Refund: ');
            put_log_line(   '  receipt number  = '
                         || x_misc_receipt_rec.receipt_number);
        END IF;

-- ==========================================================================
-- set the attributes on the misc receipt
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('- Set all the necessary Descriptive Flexfields on the Misc Receipt.');
        END IF;

        set_receipt_attributes(p_receipt_context =>              'SALES_ACCT',
                               p_orig_sys_document_ref =>        p_current_row.orig_sys_document_ref,
                               p_receipt_method_id =>            p_current_row.receipt_method_id,
                               p_payment_type_code =>            p_current_row.payment_type_code,
                               p_check_number =>                 p_current_row.check_number,
                               p_paid_at_store_id =>             p_current_row.paid_at_store_id,
                               p_ship_from_org_id =>             p_current_row.ship_from_org_id,
                               p_cc_auth_manual =>               p_current_row.cc_auth_manual,
                               p_cc_auth_ps2000 =>               p_current_row.cc_auth_ps2000,
                               p_merchant_number =>              p_current_row.merchant_number,
                               p_od_payment_type =>              p_current_row.od_payment_type,
                               p_debit_card_approval_ref =>      p_current_row.debit_card_approval_ref,
                               p_cc_mask_number =>               p_current_row.cc_mask_number,
                               p_payment_amount =>               p_current_row.amount,
                               --p_applied_customer_trx_id      => p_current_row.customer_trx_id,
                               p_original_receipt_id =>          NULL,
                               p_transaction_number =>           p_current_row.transaction_number,
                               p_imp_file_name =>                p_current_row.imp_file_name,
                               p_om_import_date =>               p_current_row.om_import_date,
                               p_i1025_record_type =>            p_current_row.record_type,
                               p_called_from =>                  'I1025',
                               p_print_debug =>                  get_debug_char(),
                               x_cash_receipt_rec =>             x_misc_receipt_rec,
                               x_receipt_ext_attributes =>       x_receipt_ext_attributes);
-- ==========================================================================
-- assign receipt reference fields and DFFs specific to I1025
-- ==========================================================================
-- Payment Source
        x_misc_receipt_rec.attribute11 :=    'REFUND:'
                                          || p_current_row.payment_type_new;
        -- Order Header ID
        --x_misc_receipt_rec.attribute12  := TO_CHAR(p_current_row.header_id);
        -- I1025 Process Code
        x_misc_receipt_rec.attribute13 :=
                            'REFUND:'
                         || p_current_row.payment_type_new
                         || '|'
                         || TO_CHAR(SYSDATE,
                                    'YYYY/MM/DD HH24:MI:SS');
-- ==========================================================================
-- update the AR receipts with new process status
-- ==========================================================================
        arp_cash_receipts_pkg.update_p(p_cr_rec =>      x_misc_receipt_rec);
-- ==========================================================================
-- insert extra receipt info into XX_AR_CASH_RECEIPTS_EXT for misc receipt
-- ==========================================================================
        x_receipt_ext_attributes.cash_receipt_id := x_misc_receipt_rec.cash_receipt_id;
        x_receipt_ext_attributes.payment_number := p_current_row.payment_number;
        xx_ar_prepayments_pkg.insert_receipt_ext_info(p_receipt_ext_attributes =>      x_receipt_ext_attributes);

        IF (gb_debug)
        THEN
            put_log_line(   '- Updated Misc Receipt: '
                         || x_misc_receipt_rec.receipt_number);
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- this refunds the balance of the receipt to the credit card
-- ==========================================================================
    PROCEDURE refund_credit_card(
        p_current_row  IN OUT NOCOPY  gt_current_record,
        x_comments     OUT NOCOPY     VARCHAR2)
    IS
        lc_sub_name            CONSTANT VARCHAR2(50)                                            := 'REFUND_CREDIT_CARD';
        x_return_status                 VARCHAR2(20)                                                   DEFAULT NULL;
        x_msg_count                     NUMBER                                                         DEFAULT NULL;
        x_msg_data                      VARCHAR2(4000)                                                 DEFAULT NULL;
        x_receipt_number                ar_cash_receipts.receipt_number%TYPE                           DEFAULT NULL;
        x_receivable_application_id     ar_receivable_applications.receivable_application_id%TYPE      DEFAULT NULL;
        x_application_ref_type          ar_receivable_applications.application_ref_type%TYPE           DEFAULT NULL;
        x_application_ref_id            ar_receivable_applications.application_ref_id%TYPE             DEFAULT NULL;
        x_application_ref_num           ar_receivable_applications.application_ref_num%TYPE            DEFAULT NULL;
        x_secondary_application_ref_id  ar_receivable_applications.secondary_application_ref_id%TYPE   DEFAULT NULL;
        x_payment_set_id                ar_receivable_applications.payment_set_id%TYPE                 DEFAULT NULL;
        lc_receipt_comments             ar_cash_receipts.comments%TYPE                                 DEFAULT NULL;
        lc_customer_receipt_reference   ar_cash_receipts.customer_receipt_reference%TYPE               DEFAULT NULL;
        lc_app_customer_reference       ar_receivable_applications.customer_reference%TYPE             DEFAULT NULL;
        lc_app_comments                 ar_receivable_applications.comments%TYPE                       DEFAULT NULL;
        lc_rec_comments                 ar_cash_receipts_all.comments%TYPE                             DEFAULT NULL;
        x_attributes                    ar_receipt_api_pub.attribute_rec_type;
        x_app_attributes                ar_receipt_api_pub.attribute_rec_type;
        x_receipt_ext_attributes        xx_ar_cash_receipts_ext%ROWTYPE;
        lc_receivables_trx              ar_receivables_trx.NAME%TYPE                                   DEFAULT NULL;
        ln_receivables_trx_id           ar_receivables_trx.receivables_trx_id%TYPE                     DEFAULT NULL;
        x_misc_receipt_rec              ar_cash_receipts%ROWTYPE;

        CURSOR c_misc_rcpt(
            cp_receivable_application_id  IN  NUMBER)
        IS
            SELECT application_ref_id,
                   application_ref_num
            FROM   ar_receivable_applications_all
            WHERE  application_ref_type = 'MISC_RECEIPT'
            AND    receivable_application_id = cp_receivable_application_id;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- set the attributes for the activity and possible misc receipt
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('- Set all the necessary references and flexfields on the receipt');
        END IF;

-- ==========================================================================
-- assign receipt reference fields and DFFs
-- ==========================================================================
        xx_ar_prepayments_pkg.set_receipt_attr_references
                                                    (p_receipt_context =>                 'SALES_ACCT',
                                                     p_orig_sys_document_ref =>           p_current_row.orig_sys_document_ref,
                                                     p_receipt_method_id =>               p_current_row.receipt_method_id,
                                                     p_payment_type_code =>               p_current_row.payment_type_code,
                                                     p_check_number =>                    p_current_row.check_number,
                                                     p_paid_at_store_id =>                p_current_row.paid_at_store_id,
                                                     p_ship_from_org_id =>                p_current_row.ship_from_org_id,
                                                     p_cc_auth_manual =>                  p_current_row.cc_auth_manual,
                                                     p_cc_auth_ps2000 =>                  p_current_row.cc_auth_ps2000,
                                                     p_merchant_number =>                 p_current_row.merchant_number,
                                                     p_od_payment_type =>                 p_current_row.od_payment_type,
                                                     p_debit_card_approval_ref =>         p_current_row.debit_card_approval_ref,
                                                     p_cc_mask_number =>                  p_current_row.cc_mask_number,
                                                     p_payment_amount =>                  p_current_row.amount,
                                                     p_applied_customer_trx_id =>         p_current_row.customer_trx_id,
                                                     p_original_receipt_id =>             NULL,
                                                     p_transaction_number =>              p_current_row.transaction_number,
                                                     p_imp_file_name =>                   p_current_row.imp_file_name,
                                                     p_om_import_date =>                  p_current_row.om_import_date,
                                                     p_i1025_record_type =>               p_current_row.record_type,
                                                     p_called_from =>                     'I1025',
                                                     p_print_debug =>                     get_debug_char(),
                                                     x_receipt_number =>                  x_receipt_number,
                                                     x_receipt_comments =>                lc_receipt_comments,
                                                     x_customer_receipt_reference =>      lc_customer_receipt_reference,
                                                     x_attribute_rec =>                   x_attributes,
                                                     x_app_customer_reference =>          lc_app_customer_reference,
                                                     x_app_comments =>                    lc_app_comments,
                                                     x_app_attribute_rec =>               x_app_attributes,
                                                     x_receipt_ext_attributes =>          x_receipt_ext_attributes);
-- ==========================================================================
-- get the receivable transaction id for CC refunds
-- ==========================================================================
        ln_receivables_trx_id := get_cc_refund_activity(p_org_id =>      p_current_row.org_id);

--ln_receivables_trx_id :=
--  get_receivables_trx_id
--  ( p_receivables_trx  => lc_receivables_trx );
-- ==========================================================================
-- Issue a credit card Refund
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('Issue a credit card refund for this receipt');
        END IF;

/* Following IF condition added by Gaurav for v2.3 */
        IF p_current_row.single_pay_ind = 'Y'
        THEN
            lc_rec_comments := 'I1025 Deposit Reversal (Single Payment for POS  - AOPS)';
        ELSE
            lc_rec_comments := 'I1025 Credit Card Refund (Matching Original)';
        END IF;

        ar_receipt_api_pub.activity_application(p_api_version =>                       1.0,
                                                p_init_msg_list =>                     fnd_api.g_true,
                                                p_commit =>                            fnd_api.g_false,
                                                p_validation_level =>                  fnd_api.g_valid_level_full,
                                                x_return_status =>                     x_return_status,
                                                x_msg_count =>                         x_msg_count,
                                                x_msg_data =>                          x_msg_data,
                                                p_cash_receipt_id =>                   p_current_row.cash_receipt_id,
                                                p_amount_applied =>                      -1
                                                                                       * p_current_row.amount,
                                                -- use the greatest of the refund date or original receipt date
                                                --   defect #3547
                                                p_apply_date =>                        GREATEST
                                                                                           (p_current_row.receipt_date,
                                                                                            p_current_row.original_receipt_date),
                                                p_applied_payment_schedule_id =>       -6,   --this is for CC Refund
                                                p_receivables_trx_id =>                ln_receivables_trx_id,
                                                -- 'US_CC REFUND_OD'
                                                p_application_ref_type =>              x_application_ref_type,
                                                p_application_ref_id =>                x_application_ref_id,
                                                p_application_ref_num =>               x_application_ref_num,
                                                p_secondary_application_ref_id =>      x_secondary_application_ref_id,
                                                p_receivable_application_id =>         x_receivable_application_id,
                                                p_payment_set_id =>                    x_payment_set_id,
                                                p_attribute_rec =>                     x_app_attributes,
                                                p_customer_reference =>                lc_app_customer_reference,
                                                p_comments =>                          lc_rec_comments,
                                                p_called_from =>                       'I1025');

        IF (gb_debug)
        THEN
            put_log_line(   '- Return Status: '
                         || x_return_status
                         || ', Msg Cnt: '
                         || x_msg_count);
        END IF;

        IF (x_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Successfully applied Credit Card Refund activity');
                put_log_line(   '  x_receivable_application_id = '
                             || x_receivable_application_id);
            END IF;
        ELSE
            raise_api_errors(p_sub_name =>       lc_sub_name,
                             p_msg_count =>      x_msg_count,
                             p_api_name =>       'AR_RECEIPT_API_PUB.activity_application');
        END IF;

-- ==========================================================================
-- get the misc receipt id reference from the application
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('- Getting the misc receipt id from the receivable application');
        END IF;

        OPEN c_misc_rcpt(cp_receivable_application_id =>      x_receivable_application_id);

        FETCH c_misc_rcpt
        INTO  x_misc_receipt_rec.cash_receipt_id,
              x_misc_receipt_rec.receipt_number;

        CLOSE c_misc_rcpt;

-- ==========================================================================
-- Adding Misc Receipt number to the Output Comments field
-- ==========================================================================
        x_comments :=    x_comments
                      || CHR(10)
                      || '        Misc Receipt:  '
                      || x_misc_receipt_rec.receipt_number;

-- ==========================================================================
-- if misc receipt is found, then update flexfields/references on Misc Receipt
-- ==========================================================================
        IF (x_misc_receipt_rec.cash_receipt_id IS NOT NULL)
        THEN
            update_misc_receipt_attrs_refs(x_misc_receipt_rec =>      x_misc_receipt_rec,
                                           p_current_row =>           p_current_row);

-- ==========================================================================
    -- V2.0 Calling new insert procedure, inserts records into custom receipt table,
    -- when ever a miscellaneous cash receipt is created  -- Start
    -- ==========================================================================
            IF (gb_debug)
            THEN
                put_log_line('- Values passed to Custom Receipt Table: ');
                put_log_line(   '  MIsc cash Receipt id = '
                             || x_misc_receipt_rec.cash_receipt_id);
            END IF;

            insert_into_cust_recpt_tbl(p_header_id =>            p_current_row.header_id,
                                       p_rowid =>                p_current_row.xx_payment_rowid,
                                       p_cash_receipt_id =>      x_misc_receipt_rec.cash_receipt_id,
                                       x_return_status =>        x_return_status);

            IF (gb_debug)
            THEN
                put_log_line(   '- Status of Custom Receipt Table: '
                             || x_return_status);
            END IF;
        -- V2.0 -- End
        ELSE
            IF (gb_debug)
            THEN
                put_log_line('  NO Misc Receipt Id could be found for this application.');
            END IF;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure to write-off a receipt
-- ==========================================================================
    PROCEDURE writeoff_receipt(
        x_cash_receipt_rec  IN OUT NOCOPY  ar_cash_receipts%ROWTYPE,
        p_current_row       IN OUT NOCOPY  gt_current_record,
        p_activity_name     IN             ar_receivables_trx.NAME%TYPE DEFAULT NULL)
    IS
        lc_sub_name            CONSTANT VARCHAR2(50)                                              := 'WRITEOFF_RECEIPT';
        x_return_status                 VARCHAR2(20)                                                   DEFAULT NULL;
        x_msg_count                     NUMBER                                                         DEFAULT NULL;
        x_msg_data                      VARCHAR2(4000)                                                 DEFAULT NULL;
        x_cash_receipt_id               ar_cash_receipts.cash_receipt_id%TYPE                          DEFAULT NULL;
        x_receipt_number                ar_cash_receipts.receipt_number%TYPE                           DEFAULT NULL;
        x_receivable_application_id     ar_receivable_applications.receivable_application_id%TYPE      DEFAULT NULL;
        x_application_ref_type          ar_receivable_applications.application_ref_type%TYPE           DEFAULT NULL;
        x_application_ref_id            ar_receivable_applications.application_ref_id%TYPE             DEFAULT NULL;
        x_application_ref_num           ar_receivable_applications.application_ref_num%TYPE            DEFAULT NULL;
        x_secondary_application_ref_id  ar_receivable_applications.secondary_application_ref_id%TYPE   DEFAULT NULL;
        x_payment_set_id                ar_receivable_applications.payment_set_id%TYPE                 DEFAULT NULL;
        lc_receipt_comments             ar_cash_receipts.comments%TYPE                                 DEFAULT NULL;
        lc_customer_receipt_reference   ar_cash_receipts.customer_receipt_reference%TYPE               DEFAULT NULL;
        lc_app_customer_reference       ar_receivable_applications.customer_reference%TYPE             DEFAULT NULL;
        lc_app_comments                 ar_receivable_applications.comments%TYPE                       DEFAULT NULL;
        x_attributes                    ar_receipt_api_pub.attribute_rec_type;
        x_app_attributes                ar_receipt_api_pub.attribute_rec_type;
        x_receipt_ext_attributes        xx_ar_cash_receipts_ext%ROWTYPE;
        lc_receivables_trx              ar_receivables_trx.NAME%TYPE                                   DEFAULT NULL;
        ln_receivables_trx_id           ar_receivables_trx.receivables_trx_id%TYPE                     DEFAULT NULL;
        lc_refund_recv_trx              ar_receivables_trx.NAME%TYPE                                   DEFAULT NULL;
        ln_refund_recv_trx_id           ar_receivables_trx.receivables_trx_id%TYPE                     DEFAULT NULL;
        x_recv_app_rec                  ar_receivable_applications%ROWTYPE;
        x_misc_receipt_rec              ar_cash_receipts%ROWTYPE;
        lc_dep_orig_sys_document_ref    xx_om_legacy_deposits.orig_sys_document_ref%TYPE;   -- V2.0
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- any other payment method, get the receipt write-off activity to apply
-- ==========================================================================
        IF (p_activity_name IS NULL)
        THEN
            lc_receivables_trx :=
                get_refund_writeoff_activity(p_org_id =>                 p_current_row.org_id,
                                             p_receipt_method_id =>      p_current_row.receipt_method_id,
                                             p_sale_location =>          p_current_row.sale_location,
                                             p_payment_type_code =>      p_current_row.payment_type_code);
        ELSE
            lc_receivables_trx := p_activity_name;
        END IF;

        ln_receivables_trx_id :=
                       get_receivables_trx_id(p_org_id =>               p_current_row.org_id,
                                              p_receivables_trx =>      lc_receivables_trx);

        IF (gb_debug)
        THEN
            put_log_line(   '  Receipt Method = '
                         || p_current_row.receipt_method);

            IF (p_current_row.sale_location IS NOT NULL)
            THEN
                put_log_line(   '    (Location = '
                             || p_current_row.sale_location
                             || ')');
            END IF;

            put_log_line('Fetch the receivables trx for the write-off activity.');
            put_log_line(   '  Write-off Recv Trx = '
                         || lc_receivables_trx);
            put_log_line(   '  Write-off Recv Trx Id = '
                         || ln_receivables_trx_id);
        END IF;

        IF (ln_receivables_trx_id IS NULL)
        THEN
            fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20006_NO_RECV_ACTV');
            fnd_message.set_token('SUB_NAME',
                                  lc_sub_name);
            fnd_message.set_token('RECV_ACTIVITY',
                                  lc_receivables_trx);
            raise_application_error(-20006,
                                    fnd_message.get() );
        END IF;

-- ==========================================================================
-- set the attributes for the activity and possible misc receipt
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('- Set all the necessary references and flexfields on the receipt');
        END IF;

-- ==========================================================================
-- assign receipt reference fields and DFFs
-- ==========================================================================
        xx_ar_prepayments_pkg.set_receipt_attr_references
                                                    (p_receipt_context =>                 'SALES_ACCT',
                                                     p_orig_sys_document_ref =>           p_current_row.orig_sys_document_ref,
                                                     p_receipt_method_id =>               p_current_row.receipt_method_id,
                                                     p_payment_type_code =>               p_current_row.payment_type_code,
                                                     p_check_number =>                    p_current_row.check_number,
                                                     p_paid_at_store_id =>                p_current_row.paid_at_store_id,
                                                     p_ship_from_org_id =>                p_current_row.ship_from_org_id,
                                                     p_cc_auth_manual =>                  p_current_row.cc_auth_manual,
                                                     p_cc_auth_ps2000 =>                  p_current_row.cc_auth_ps2000,
                                                     p_merchant_number =>                 p_current_row.merchant_number,
                                                     p_od_payment_type =>                 p_current_row.od_payment_type,
                                                     p_debit_card_approval_ref =>         p_current_row.debit_card_approval_ref,
                                                     p_cc_mask_number =>                  p_current_row.cc_mask_number,
                                                     p_payment_amount =>                  p_current_row.amount,
                                                     p_applied_customer_trx_id =>         p_current_row.customer_trx_id,
                                                     p_original_receipt_id =>             NULL,
                                                     p_transaction_number =>              p_current_row.transaction_number,
                                                     p_imp_file_name =>                   p_current_row.imp_file_name,
                                                     p_om_import_date =>                  p_current_row.om_import_date,
                                                     p_i1025_record_type =>               p_current_row.record_type,
                                                     p_called_from =>                     'I1025',
                                                     p_print_debug =>                     get_debug_char(),
                                                     x_receipt_number =>                  x_receipt_number,
                                                     x_receipt_comments =>                lc_receipt_comments,
                                                     x_customer_receipt_reference =>      lc_customer_receipt_reference,
                                                     x_attribute_rec =>                   x_attributes,
                                                     x_app_customer_reference =>          lc_app_customer_reference,
                                                     x_app_comments =>                    lc_app_comments,
                                                     x_app_attribute_rec =>               x_app_attributes,
                                                     x_receipt_ext_attributes =>          x_receipt_ext_attributes);

-- ==========================================================================
-- create a misc receipt for reconciliation of debit card and telecheck
--   this essentially mimics the activity of the "Credit Card Refund"
-- ==========================================================================
        IF (p_current_row.payment_type_new IN('DEBIT_CARD', 'TELECHECK') )
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Create a misc receipt for refund activities on Debit Card and Telecheck.');
            END IF;

-- ==========================================================================
-- get the receipt write-off activity for the misc receipt
-- ==========================================================================
            lc_refund_recv_trx :=
                get_refund_misc_rcpt_activity(p_org_id =>                 p_current_row.org_id,
                                              p_receipt_method_id =>      p_current_row.receipt_method_id,
                                              p_sale_location =>          p_current_row.sale_location,
                                              p_payment_type_code =>      p_current_row.payment_type_code);
            ln_refund_recv_trx_id :=
                       get_receivables_trx_id(p_org_id =>               p_current_row.org_id,
                                              p_receivables_trx =>      lc_refund_recv_trx);

            IF (gb_debug)
            THEN
                put_log_line('Fetch the receivables trx for the misc receipt');
                put_log_line(   '  Write-off Recv Trx = '
                             || lc_refund_recv_trx);
                put_log_line(   '  Write-off Recv Trx Id = '
                             || ln_refund_recv_trx_id);
            END IF;

            IF (ln_refund_recv_trx_id IS NULL)
            THEN
                fnd_message.set_name('XXFIN',
                                     'XX_AR_I1025_20006_NO_RECV_ACTV');
                fnd_message.set_token('SUB_NAME',
                                      lc_sub_name);
                fnd_message.set_token('RECV_ACTIVITY',
                                      lc_refund_recv_trx);
                raise_application_error(-20006,
                                        fnd_message.get() );
            END IF;

-- ==========================================================================
-- assign receipt reference fields and DFFs specific to I1025
-- ==========================================================================
-- Payment Source
            x_attributes.attribute11 :=    'REFUND:'
                                        || p_current_row.payment_type_new;
            x_attributes.attribute13 :=
                            'REFUND:'
                         || p_current_row.payment_type_new
                         || '|'
                         || TO_CHAR(SYSDATE,
                                    'YYYY/MM/DD HH24:MI:SS');

            IF p_current_row.single_pay_ind = 'Y'
            THEN
                lc_receipt_comments := 'I1025 Deposit Reversal (Single Payment for POS )';
            END IF;

            IF gc_process_flag = 'M'
            THEN
                IF (gb_debug)
                THEN
                    put_log_line('- Comments for Single Payment for POS and AOPS.');
                    put_log_line();
                END IF;

                lc_receipt_comments := 'I1025 Create Refund Receipt(Single Payment for POS and AOPS)';

                IF (gb_debug)
                THEN
                    put_log_line(   'Receipt comments: '
                                 || lc_receipt_comments);
                    put_log_line();
                END IF;
            END IF;

-- ==========================================================================
-- create the misc receipt for Debit Card refunds
-- ==========================================================================
            ar_receipt_api_pub.create_misc(p_api_version =>             1.0,
                                           p_init_msg_list =>           fnd_api.g_true,
                                           p_commit =>                  fnd_api.g_false,
                                           p_validation_level =>        fnd_api.g_valid_level_full,
                                           x_return_status =>           x_return_status,
                                           x_msg_count =>               x_msg_count,
                                           x_msg_data =>                x_msg_data,
                                           p_amount =>                  p_current_row.amount,
                                           p_receipt_date =>            p_current_row.receipt_date,
                                           p_receipt_method_id =>       x_cash_receipt_rec.receipt_method_id,
                                           p_currency_code =>           x_cash_receipt_rec.currency_code,
                                           p_receivables_trx_id =>      ln_refund_recv_trx_id,
                                           p_reference_type =>          'RECEIPT',
                                           p_reference_id =>            x_cash_receipt_rec.cash_receipt_id,
                                           p_reference_num =>           x_cash_receipt_rec.receipt_number,
                                           p_attribute_record =>        x_attributes,
                                           p_receipt_number =>          x_receipt_number,
                                           p_misc_receipt_id =>         x_cash_receipt_id,
                                           p_comments =>                lc_receipt_comments,
                                           p_called_from =>             'I1025');

            IF (gb_debug)
            THEN
                put_log_line(   '- Return Status: '
                             || x_return_status
                             || ', Msg Cnt: '
                             || x_msg_count);
            END IF;

            IF (x_return_status = 'S')
            THEN
                IF (gb_debug)
                THEN
                    put_log_line('Successfully created Misc Receipt');
                    put_log_line(   '  x_cash_receipt_id = '
                                 || x_cash_receipt_id);
                    put_log_line(   '  x_receipt_number = '
                                 || x_receipt_number);
                END IF;
            ELSE
                raise_api_errors(p_sub_name =>       lc_sub_name,
                                 p_msg_count =>      x_msg_count,
                                 p_api_name =>       'AR_RECEIPT_API_PUB.create_misc');
            END IF;

-- ==========================================================================
-- if misc receipt is created, then update flexfields/references on Misc Receipt
--   that could not be updated using the API
-- ==========================================================================
            x_misc_receipt_rec.cash_receipt_id := x_cash_receipt_id;
            update_misc_receipt_attrs_refs(x_misc_receipt_rec =>      x_misc_receipt_rec,
                                           p_current_row =>           p_current_row);

-- ==========================================================================
-- V2.0 Calling new insert procedure, inserts records into custom receipt table,
-- when ever a miscellaneous cash receipt is created  -- Start
-- ==========================================================================
            IF (gb_debug)
            THEN
                put_log_line('- Values passed to Custom Receipt Table: ');
                put_log_line(   '  header id = '
                             || p_current_row.header_id);
                put_log_line(   '  cash Receipt id = '
                             || x_cash_receipt_rec.cash_receipt_id);
            END IF;

            insert_into_cust_recpt_tbl(p_header_id =>            p_current_row.header_id,
                                       p_rowid =>                p_current_row.xx_payment_rowid,
                                       p_cash_receipt_id =>      x_misc_receipt_rec.cash_receipt_id,
                                       x_return_status =>        x_return_status);

            IF (gb_debug)
            THEN
                put_log_line(   '- Status of Custom Receipt Table: '
                             || x_return_status);
            END IF;
        END IF;

-- ==========================================================================
-- Write-off the deposit receipt with the refund activity
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('Write-off the receipt.');
            put_log_line(   '  Amt to Writeoff = '
                         ||   -1
                            * p_current_row.amount);
        END IF;

-- ==========================================================================
-- call activity application to Write-off the deposit receipt
-- ==========================================================================
        ar_receipt_api_pub.activity_application(p_api_version =>                       1.0,
                                                p_init_msg_list =>                     fnd_api.g_true,
                                                p_commit =>                            fnd_api.g_false,
                                                p_validation_level =>                  fnd_api.g_valid_level_full,
                                                x_return_status =>                     x_return_status,
                                                x_msg_count =>                         x_msg_count,
                                                x_msg_data =>                          x_msg_data,
                                                p_cash_receipt_id =>                   x_cash_receipt_rec.cash_receipt_id,
                                                p_amount_applied =>                      -1
                                                                                       * p_current_row.amount,
                                                p_apply_date =>                        GREATEST
                                                                                           (p_current_row.receipt_date,
                                                                                            p_current_row.original_receipt_date),
                                                p_applied_payment_schedule_id =>       -3,
                                                --this is for Receipt Write-off
                                                p_link_to_customer_trx_id =>           NULL,
                                                p_receivables_trx_id =>                ln_receivables_trx_id,
                                                p_comments =>                          'I1025 Refund Receipt Write-Off',
                                                p_application_ref_type =>              x_application_ref_type,
                                                p_application_ref_id =>                x_application_ref_id,
                                                p_application_ref_num =>               x_application_ref_num,
                                                p_secondary_application_ref_id =>      x_secondary_application_ref_id,
                                                p_receivable_application_id =>         x_receivable_application_id,
                                                p_payment_set_id =>                    x_payment_set_id,
                                                p_attribute_rec =>                     x_app_attributes,
                                                p_customer_reference =>                lc_app_customer_reference,
                                                p_val_writeoff_limits_flag =>          'Y',
                                                p_called_from =>                       'I1025');

        IF (gb_debug)
        THEN
            put_log_line(   '- Return Status: '
                         || x_return_status
                         || ', Msg Cnt: '
                         || x_msg_count);
        END IF;

        IF (x_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Successfully applied Receipt Write-Off');
                put_log_line(   '  x_receivable_application_id = '
                             || x_receivable_application_id);
            --- code to be added here on 11/01
            END IF;
        ELSE
            raise_api_errors(p_sub_name =>       lc_sub_name,
                             p_msg_count =>      x_msg_count,
                             p_api_name =>       'AR_RECEIPT_API_PUB.activity_application');
        END IF;

-- ==========================================================================
-- update application with references to the misc receipt
--   only for debit card and telecheck
--    this essentially mimics the activity of the "Credit Card Refund"
-- ==========================================================================
        IF (p_current_row.payment_type_new IN('DEBIT_CARD', 'TELECHECK') )
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Update Application with references to the Misc Receipt...');
                put_log_line('  (Only for Debit Card and Telecheck)');
            END IF;

            arp_app_pkg.nowaitlock_p(p_ra_id =>      x_receivable_application_id);
            arp_app_pkg.fetch_p(p_ra_id =>       x_receivable_application_id,
                                p_ra_rec =>      x_recv_app_rec);
            x_recv_app_rec.application_ref_type := 'MISC_RECEIPT';
            x_recv_app_rec.application_ref_id := x_cash_receipt_id;
            x_recv_app_rec.application_ref_num := x_receipt_number;
            arp_app_pkg.update_p(p_ra_rec =>      x_recv_app_rec);

            IF (gb_debug)
            THEN
                put_log_line('- Successfully updated Application with references.');
            END IF;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure to gather customer address data from the mail check holds table
--   and add it to the comments field for printing to the program output
--   CR #341, manually processing of reversals for multi-tender deposits
-- ==========================================================================
    PROCEDURE add_mailcheck_details(
        p_orig_sys_document_ref  IN             VARCHAR2,
        x_comments               OUT NOCOPY     VARCHAR2)
    IS
        CURSOR c_check
        IS
            SELECT *
            FROM   xx_ar_mail_check_holds
            WHERE  aops_order_number = p_orig_sys_document_ref;

        l_check  c_check%ROWTYPE;
    BEGIN
        OPEN c_check;

        FETCH c_check
        INTO  l_check;

        CLOSE c_check;

        IF (l_check.ref_mailcheck_id IS NOT NULL)
        THEN
            x_comments :=
                   x_comments
                || CHR(10)
                || '       Mail Check Customer/Address Info:'
                || CHR(10)
                || '         '
                || l_check.store_customer_name
                || CHR(10)
                || '         '
                || l_check.address_line_1;

            IF (l_check.address_line_2 IS NOT NULL)
            THEN
                x_comments :=    x_comments
                              || CHR(10)
                              || '         '
                              || l_check.address_line_2;
            END IF;

            IF (l_check.address_line_3 IS NOT NULL)
            THEN
                x_comments :=    x_comments
                              || CHR(10)
                              || '         '
                              || l_check.address_line_3;
            END IF;

            IF (l_check.address_line_4 IS NOT NULL)
            THEN
                x_comments :=    x_comments
                              || CHR(10)
                              || '         '
                              || l_check.address_line_4;
            END IF;

            x_comments :=
                   x_comments
                || CHR(10)
                || '       '
                || l_check.city
                || ', '
                || l_check.state_province
                || '  '
                || l_check.postal_code;
        ELSE
            x_comments :=    x_comments
                          || CHR(10)
                          || '        Mailcheck Customer/Address Info not available.';
        END IF;
    END;

-- ==========================================================================
-- this create a zero-dollar receipt for the refund payment tender
-- ==========================================================================
    PROCEDURE create_zero_receipt(
        x_return_status     OUT NOCOPY     VARCHAR2,
        p_current_row       IN OUT NOCOPY  gt_current_record,
        x_cash_receipt_rec  IN OUT NOCOPY  ar_cash_receipts%ROWTYPE,
        x_original          IN OUT NOCOPY  gt_original,
        x_process_flag      IN OUT NOCOPY  VARCHAR2   -- Added for CR 722(Defect 6033)
                                                   )
    IS
        lc_sub_name            CONSTANT VARCHAR2(50)                                           := 'CREATE_ZERO_RECEIPT';
        x_msg_count                     NUMBER                                                         DEFAULT NULL;
        x_msg_data                      VARCHAR2(4000)                                                 DEFAULT NULL;
        x_cash_receipt_id               ar_cash_receipts.cash_receipt_id%TYPE                          DEFAULT NULL;
        x_receipt_number                ar_cash_receipts.receipt_number%TYPE                           DEFAULT NULL;
        x_receivable_application_id     ar_receivable_applications.receivable_application_id%TYPE      DEFAULT NULL;
        x_application_ref_type          ar_receivable_applications.application_ref_type%TYPE           DEFAULT NULL;
        x_application_ref_id            ar_receivable_applications.application_ref_id%TYPE             DEFAULT NULL;
        x_application_ref_num           ar_receivable_applications.application_ref_num%TYPE            DEFAULT NULL;
        x_secondary_application_ref_id  ar_receivable_applications.secondary_application_ref_id%TYPE   DEFAULT NULL;
        x_payment_set_id                ar_receivable_applications.payment_set_id%TYPE                 DEFAULT NULL;
        lc_receipt_comments             ar_cash_receipts.comments%TYPE                                 DEFAULT NULL;
        lc_customer_receipt_reference   ar_cash_receipts.customer_receipt_reference%TYPE               DEFAULT NULL;
        lc_app_customer_reference       ar_receivable_applications.customer_reference%TYPE             DEFAULT NULL;
        lc_app_comments                 ar_receivable_applications.comments%TYPE                       DEFAULT NULL;
        x_attributes                    ar_receipt_api_pub.attribute_rec_type;
        x_app_attributes                ar_receipt_api_pub.attribute_rec_type;
        x_receipt_ext_attributes        xx_ar_cash_receipts_ext%ROWTYPE;
        l_customer_rec                  gcu_customer_id%ROWTYPE;
        l_count                         NUMBER                                                         := 0;
        lc_flg                          VARCHAR2(1)                                                    DEFAULT 'N';
        lc_card_name                    xx_fin_translatevalues.target_value1%TYPE;
        lc_return_status                VARCHAR2(1);
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- validate the customer account is defined
-- ==========================================================================
        IF (p_current_row.bill_to_customer_id IS NULL)
        THEN
            raise_missing_param_errors(p_sub_name =>        lc_sub_name,
                                       p_param_name =>      'Customer Account (CUST_ACCOUNT_ID)');
        END IF;

-- ==========================================================================
-- validate the receipt method is defined
-- ==========================================================================
        IF (p_current_row.receipt_method_id IS NULL)
        THEN
            raise_missing_param_errors(p_sub_name =>        lc_sub_name,
                                       p_param_name =>      'Receipt Method (RECEIPT_METHOD_ID)');
        END IF;

-- ==========================================================================
-- get primary bill-to customer information
-- ==========================================================================
        l_customer_rec :=
            get_bill_customer_by_id(p_org_id =>               p_current_row.org_id,
                                    p_cust_account_id =>      p_current_row.bill_to_customer_id);
-- ==========================================================================
-- assign receipt reference fields and DFFs
-- ==========================================================================
        xx_ar_prepayments_pkg.set_receipt_attr_references
                                                    (p_receipt_context =>                 'SALES_ACCT',
                                                     p_orig_sys_document_ref =>           p_current_row.orig_sys_document_ref,
                                                     p_receipt_method_id =>               p_current_row.receipt_method_id,
                                                     p_payment_type_code =>               p_current_row.payment_type_code,
                                                     p_check_number =>                    p_current_row.check_number,
                                                     p_paid_at_store_id =>                p_current_row.paid_at_store_id,
                                                     p_ship_from_org_id =>                p_current_row.ship_from_org_id,
                                                     p_cc_auth_manual =>                  p_current_row.cc_auth_manual,
                                                     p_cc_auth_ps2000 =>                  p_current_row.cc_auth_ps2000,
                                                     p_merchant_number =>                 p_current_row.merchant_number,
                                                     p_od_payment_type =>                 p_current_row.od_payment_type,
                                                     p_debit_card_approval_ref =>         p_current_row.debit_card_approval_ref,
                                                     p_cc_mask_number =>                  p_current_row.cc_mask_number,
                                                     p_payment_amount =>                  p_current_row.amount,
                                                     p_applied_customer_trx_id =>         p_current_row.customer_trx_id,
                                                     p_original_receipt_id =>             x_original.cash_receipt_id,
                                                     p_transaction_number =>              p_current_row.transaction_number,
                                                     p_imp_file_name =>                   p_current_row.imp_file_name,
                                                     p_om_import_date =>                  p_current_row.om_import_date,
                                                     p_i1025_record_type =>               p_current_row.record_type,
                                                     p_called_from =>                     'I1025',
                                                     p_original_order =>                  x_original.orig_sys_document_ref,
                                                     p_print_debug =>                     get_debug_char(),
                                                     x_receipt_number =>                  x_receipt_number,
                                                     x_receipt_comments =>                lc_receipt_comments,
                                                     x_customer_receipt_reference =>      lc_customer_receipt_reference,
                                                     x_attribute_rec =>                   x_attributes,
                                                     x_app_customer_reference =>          lc_app_customer_reference,
                                                     x_app_comments =>                    lc_app_comments,
                                                     x_app_attribute_rec =>               x_app_attributes,
                                                     x_receipt_ext_attributes =>          x_receipt_ext_attributes);
-- ==========================================================================
-- assign receipt reference fields and DFFs specific to I1025
-- ==========================================================================
-- Payment Source
        x_attributes.attribute11 := 'REFUND';
        x_attributes.attribute13 :=    'CREATED|'
                                    || TO_CHAR(SYSDATE,
                                               'YYYY/MM/DD HH24:MI:SS');
        lc_receipt_comments := 'I1025 Refund Receipt (Create Refund Zero-Dollar Receipt)';

-- ==========================================================================
-- create the credit card bank account (or retrieve it if it already exists)
--   only for credit card and debit card
-- ==========================================================================
        IF (p_current_row.payment_type_new IN('CREDIT_CARD', 'DEBIT_CARD') )
        THEN
            BEGIN
                IF (gb_debug)
                THEN
                    put_log_line(   'Getting OD Credit Card Type for  = '
                                 || x_attributes.attribute14);
                END IF;

                SELECT target_value1
                INTO   lc_card_name
                FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
                WHERE  translation_name = 'OD_IBY_CREDIT_CARD_TYPE'
                AND    xftv.translate_id = xftd.translate_id
                AND    xftv.source_value1 = x_attributes.attribute14
                AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                        SYSDATE
                                                                      + 1)
                AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                        SYSDATE
                                                                      + 1)
                AND    xftv.enabled_flag = 'Y'
                AND    xftd.enabled_flag = 'Y';
            EXCEPTION
                WHEN OTHERS
                THEN
                    lc_card_name := NULL;
            END;

            IF (gb_debug)
            THEN
                put_log_line(   'Card name = '
                             || lc_card_name);
            END IF;
        END IF;

-- ==========================================================================
-- create a zero-dollar cash receipt in place of the original receipt
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('Create a zero-dollar cash receipt in place of the original.');
        END IF;

        --V2.0  -- Single Payment for POS and AOPS.
        IF gc_process_flag = 'M'
        THEN
            lc_receipt_comments := 'I1025 Create Refund Receipt(Single Payment for POS and AOPS)';
        END IF;

        --V2.0  -- Single Payment for POS and AOPS.
        -- added by Gaurav v2.0
        IF x_process_flag = 'D'
        THEN
            BEGIN
                SELECT xoldd2.single_pay_ind   -- COUNT(1)
                INTO   lc_flg
                FROM   xx_om_legacy_dep_dtls xoldd1, xx_om_legacy_dep_dtls xoldd2
                WHERE  xoldd1.transaction_number = p_current_row.transaction_number
                AND    SUBSTR(xoldd1.orig_sys_document_ref,
                              1,
                              9) = SUBSTR(xoldd2.orig_sys_document_ref,
                                          1,
                                          9)
                AND    xoldd1.transaction_number != xoldd2.transaction_number
                AND    NVL(xoldd2.single_pay_ind,
                           'N') = 'Y';
            EXCEPTION
                WHEN OTHERS
                THEN
                    lc_flg := 'N';
            END;

            IF lc_flg = 'Y'
            THEN
                lc_receipt_comments := 'I1025 Multi-tender Deposit Reversal (Single Payment for POS - AOPS)';
            END IF;

            IF (gb_debug)
            THEN
                put_log_line(   'Receipt comments: '
                             || lc_receipt_comments);
                put_log_line();
            END IF;
        END IF;

        ar_receipt_api_pub.create_cash(p_api_version =>                     1.0,
                                       p_init_msg_list =>                   fnd_api.g_true,
                                       p_commit =>                          fnd_api.g_false,
                                       p_validation_level =>                fnd_api.g_valid_level_full,
                                       x_return_status =>                   x_return_status,
                                       x_msg_count =>                       x_msg_count,
                                       x_msg_data =>                        x_msg_data,
                                       p_currency_code =>                   p_current_row.currency_code,
                                       p_amount =>                          0,
                                       p_receipt_date =>                    p_current_row.receipt_date,
                                       p_receipt_method_id =>               p_current_row.receipt_method_id,
                                       p_customer_id =>                     l_customer_rec.cust_account_id,
                                       p_customer_site_use_id =>            l_customer_rec.site_use_id,
                                       p_customer_receipt_reference =>      lc_customer_receipt_reference,
                                       p_customer_bank_account_id =>        NULL,
                                       p_cr_id =>                           x_cash_receipt_id,
                                       p_receipt_number =>                  x_receipt_number,
                                       p_comments =>                        lc_receipt_comments,
                                       p_called_from =>                     'I1025',
                                       p_attribute_rec =>                   x_attributes,
                                       p_payment_trxn_extension_id =>       NULL);

        IF (gb_debug)
        THEN
            put_log_line(   '- Return Status: '
                         || x_return_status
                         || ', Msg Cnt: '
                         || x_msg_count);
        END IF;

        IF (x_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Successfully created a zero-dollar receipt for the refund tender.');
                put_log_line(   '  x_cash_receipt_id = '
                             || x_cash_receipt_id);
            END IF;
        ELSE
            raise_api_errors(p_sub_name =>       lc_sub_name,
                             p_msg_count =>      x_msg_count,
                             p_api_name =>       'AR_RECEIPT_API_PUB.create_cash');
        END IF;

        x_cash_receipt_rec.cash_receipt_id := x_cash_receipt_id;
-- ==========================================================================
-- insert extra receipt info into XX_AR_CASH_RECEIPTS_EXT for zero-dollar receipt
-- ==========================================================================
        x_receipt_ext_attributes.cash_receipt_id := x_cash_receipt_rec.cash_receipt_id;
        x_receipt_ext_attributes.payment_number := p_current_row.payment_number;
        xx_ar_prepayments_pkg.insert_receipt_ext_info(p_receipt_ext_attributes =>      x_receipt_ext_attributes);
-- ==========================================================================
-- re-fetch the latest AR receipt
-- ==========================================================================
        arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec =>      x_cash_receipt_rec);

        IF (gb_debug)
        THEN
            put_log_line('- Re-Fetched Receipt: ');
            put_log_line(   '  cash receipt id = '
                         || x_cash_receipt_rec.cash_receipt_id);
            put_log_line(   '  receipt number  = '
                         || x_cash_receipt_rec.receipt_number);
        END IF;

---  Commneted for CR 722(Defect 6033)  ---
/*update_refund_I1025_process
( p_rowid         => p_current_row.xx_payment_rowid,
p_I1025_status  => 'CREATED_ZERO_DOLLAR' );*/
-- =============================================================================================================
---  Start of code added for CR 722(Defect 6033) to update XX_OM_LEGACY_DEPOSITS for zero-dollar creation forDeposits   -----
-- =============================================================================================================
        IF x_process_flag = 'D'
        THEN
            update_deposit_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                         p_i1025_status =>      'CREATED_ZERO_DOLLAR_MULTI');
        ELSE
            update_refund_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                        p_i1025_status =>      'CREATED_ZERO_DOLLAR');
        END IF;

-- =============================================================================================================
-- End of code added for CR 722(Defect 6033) to update XX_OM_LEGACY_DEPOSITS for zero-dollar creation forDeposits   -----
-- =============================================================================================================
        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- this writes-off the credit balance of the receipt
-- ==========================================================================
    PROCEDURE writeoff_receipt_credit_bal(
        p_current_row       IN OUT NOCOPY  gt_current_record,
        x_cash_receipt_rec  IN OUT NOCOPY  ar_cash_receipts%ROWTYPE,
        x_process_flag      IN             VARCHAR2)   -- Added for CR 722(Defect 6033)
    IS
        lc_sub_name            CONSTANT VARCHAR2(50)   := 'WRITEOFF_RECEIPT_CREDIT_BAL';
        x_return_status                 VARCHAR2(20)   DEFAULT NULL;
        x_msg_count                     NUMBER         DEFAULT NULL;
        x_msg_data                      VARCHAR2(4000) DEFAULT NULL;
        x_application_ref_type          VARCHAR2(4000) DEFAULT NULL;
        x_application_ref_id            NUMBER         DEFAULT NULL;
        x_application_ref_num           VARCHAR2(4000) DEFAULT NULL;
        x_secondary_application_ref_id  NUMBER         DEFAULT NULL;
        x_receivable_application_id     NUMBER         DEFAULT NULL;
        x_payment_set_id                NUMBER         DEFAULT NULL;
        lc_receivables_trx              VARCHAR2(200)  DEFAULT NULL;
        ln_receivables_trx_id           NUMBER         DEFAULT NULL;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- do not write-off receipts with mail check refund tender
-- ==========================================================================
        IF (p_current_row.payment_type_new = 'MAILCHECK')
        THEN
-- ==========================================================================
-- set the I1025 process code to "On-Hold" so that E0055 AR Automated
--   Refund can process it further
-- ==========================================================================
            set_i1025_process_code(x_cash_receipt_rec =>        x_cash_receipt_rec,
                                   p_i1025_process_code =>      'ON_HOLD');

            --- Commented for CR 722(Defect 6033)---
            /*update_refund_I1025_process
            ( p_rowid         => p_current_row.xx_payment_rowid,
            p_I1025_status  => 'MAILCHECK_HOLD' );*/
            --Added for CR 722(Defect 6033)-- Start------
            IF x_process_flag = 'D'
            THEN
                update_deposit_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                             p_i1025_status =>      'MAILCHECK_HOLD');
            ELSE
                update_refund_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                            p_i1025_status =>      'MAILCHECK_HOLD');
            END IF;

--Added for CR 722(Defect 6033)-- End---------
--======================================================================================
-- V2.0 Included WRITEOFF_RECEIPT procedure.
--Incase of payment type is MAILCHECK we will call this writeoff_receipt procedure -- Start
--======================================================================================
            writeoff_receipt(x_cash_receipt_rec =>      x_cash_receipt_rec,
                             p_current_row =>           p_current_row);
        -- V2.0 Included WRITEOFF_RECEIPT procedure -- End
        ELSE
-- ==========================================================================
-- any other payment method, write off the receipt with the corresponding
--   refund write-off activity
-- ==========================================================================
            writeoff_receipt(x_cash_receipt_rec =>      x_cash_receipt_rec,
                             p_current_row =>           p_current_row);

-- ==========================================================================
-- update the receipt I1025 process code (ATTRIBUTE13) to MATCHED
--   (keeping "ORIGINAL" identifier)
-- ==========================================================================
            IF (x_cash_receipt_rec.attribute13 LIKE '%|ORIGINAL|%')
            THEN
                set_i1025_process_code(x_cash_receipt_rec =>        x_cash_receipt_rec,
                                       p_i1025_process_code =>      'MATCHED|ORIGINAL');

                --Commented for CR 722(Defect 6033)--
                /* update_refund_I1025_process
                ( p_rowid         => p_current_row.xx_payment_rowid,
                p_I1025_status  => 'MATCHED_ORIGINAL' );*/
                --Added for CR 722(Defect 6033)-- Start------
                IF x_process_flag = 'D'
                THEN
                    update_deposit_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                                 p_i1025_status =>      'MATCHED_ORIGINAL_DEPOSIT');
                ELSE
                    update_refund_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                                p_i1025_status =>      'MATCHED_ORIGINAL');
                END IF;
            --Added for CR 722(Defect 6033)-- End---------
            ELSE
                set_i1025_process_code(x_cash_receipt_rec =>        x_cash_receipt_rec,
                                       p_i1025_process_code =>      'MATCHED');

                --Commented for CR 722(Defect 6033)--
                /*update_refund_I1025_process
                ( p_rowid         => p_current_row.xx_payment_rowid,
                p_I1025_status  => 'MATCHED_ZERO_DOLLAR' );*/
                --Added for CR 722(Defect 6033)-- Start---------
                IF x_process_flag = 'D'
                THEN
                    update_deposit_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                                 p_i1025_status =>      'MATCHED_ZERO_DOLLAR_DEPOSIT');
                ELSE
                    update_refund_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                                p_i1025_status =>      'MATCHED_ZERO_DOLLAR');
                END IF;
            --Added for CR 722(Defect 6033)-- End---------
            END IF;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==============================================================================================
-- Added for CR 722(Defect 6033) -Procedure to map apply deposit cursor record to current record type
-- ==============================================================================================
    PROCEDURE map_apply_deposit_to_current(
        p_rowid            IN             ROWID,
        p_org_id           IN             NUMBER,
        p_cash_receipt_id  IN             ar_cash_receipts_all.cash_receipt_id%TYPE,
        p_customer_trx_id  IN             ra_customer_trx_all.customer_trx_id%TYPE,
        x_current_row      OUT NOCOPY     gt_current_record)
    IS
        lc_sub_name        CONSTANT VARCHAR2(50)              := 'MAP_APPLY_DEPOSIT_TO_CURRENT';
        lc_receipt_method           VARCHAR2(50);
        ln_cash_receipt_id          NUMBER;
        ln_receipt_class_id         NUMBER;
        lc_receipt_class            VARCHAR2(50);
        ln_receipt_number           NUMBER;
        lc_receipt_status           VARCHAR2(50);
        lc_receipt_appl_status      VARCHAR2(50);
        ld_original_receipt_date    DATE;
        lc_i1025_process_code       VARCHAR2(50);
        ln_customer_trx_id          NUMBER;
        ln_trx_number               NUMBER;
        lc_status_trx               VARCHAR2(50);
        ld_trx_date                 DATE;
        lc_trx_type                 VARCHAR2(50);
        ln_payment_schedule_id      NUMBER;
        ln_amount_due_remaining     NUMBER;
        lc_payment_schedule_status  VARCHAR2(50);
        ln_bill_to_site_use_id      NUMBER;

        ---- Get data from XX_OM_LEGACY_DEPOSITS_ALL----
        CURSOR gcu_deposits_cm
        IS
            SELECT xold.ROWID,
                   xold.orig_sys_document_ref,
                   xold.sold_to_org_id,
                   hp.party_name sold_to_org,
                   hca.party_id,
                   xold.org_id,
                   xold.header_id,
                   (SELECT order_number
                    FROM   oe_order_headers_all
                    WHERE  orig_sys_document_ref = xold.orig_sys_document_ref) order_number,
                   TRUNC(SYSDATE) ordered_date,
                   xold.payment_number,
                   xold.payment_set_id,
                   xold.payment_type_code,
                   xold.credit_card_code,
                   xold.credit_card_number,
                   xold.credit_card_holder_name,
                   xold.credit_card_expiration_date,
                   xold.credit_card_approval_code,
                   xold.credit_card_approval_date,
                   xold.check_number,
                   xold.line_id,
                   xold.currency_code,
                   xold.receipt_method_id,
                   xold.cash_receipt_id,
                   xold.prepaid_amount amount,
                   xold.cc_auth_ps2000,
                   CASE xold.cc_auth_manual
                       WHEN 'Y'
                           THEN '1'
                       ELSE '2'
                   END cc_auth_manual,
                   xold.cc_mask_number,
                   xold.merchant_number,
                   xold.od_payment_type,
                   xold.debit_card_approval_ref,
                   xold.i1025_status,
                   xold.creation_date,
                   (SELECT LPAD(haou.attribute1,
                                6,
                                '0')
                    FROM   hr_all_organization_units haou
                    WHERE  haou.organization_id = xold.paid_at_store_id) sale_location,
                   xold.transaction_number,
                   NVL(xold.receipt_date,
                       TRUNC(SYSDATE) ) receipt_date,
                   TRUNC(SYSDATE) trx_date,
                   xold.paid_at_store_id,
                   TO_NUMBER(NULL) ship_from_org_id,
                   NULL ship_from_org,
                   xold.process_code,
                   xold.cc_entry_mode,
                   xold.cvv_resp_code,
                   xold.avs_resp_code,
                   xold.auth_entry_mode,
                   TO_DATE(NULL) om_import_date,
                   xold.imp_file_name
                                     -- if header is defined, treat as post-payment
            ,
                   CASE
                       WHEN xold.header_id IS NOT NULL
                           THEN 'POST-PAY'
                       ELSE 'PRE-PAY'
                   END payment_type_flag
                                        -- if deposit amount is negative, then treat as reversal
            ,
                   CASE
                       WHEN xold.prepaid_amount < 0
                           THEN 'Y'
                       ELSE 'N'
                   END deposit_reversal_flag,
                   xold.IDENTIFIER
            FROM   xx_om_legacy_deposits xold, hz_cust_accounts hca, hz_parties hp
            WHERE  xold.ROWID = p_rowid
            AND    hca.party_id = hp.party_id(+)
            AND    xold.org_id = p_org_id
            AND    xold.sold_to_org_id = hca.cust_account_id(+);

        l_deposits_cm_row           gcu_deposits_cm%ROWTYPE;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- -------------------------------------------------
-- Get the Deposit Information  ---------
-- -------------------------------------------------
        IF (gb_debug)
        THEN
            put_log_line('        Getting the Deposit information ');
        END IF;

        OPEN gcu_deposits_cm;

        FETCH gcu_deposits_cm
        INTO  l_deposits_cm_row;

        CLOSE gcu_deposits_cm;

-- -------------------------------------------------
----Get Receipt information------
-- -------------------------------------------------
        IF (gb_debug)
        THEN
            put_log_line('        Getting the Deposit Receipt information ');
        END IF;

        SELECT arm.NAME,
               acr.cash_receipt_id,
               arl.receipt_class_id,
               arl.NAME receipt_class,
               acr.receipt_number,
               acr.status receipt_status,
               acrh.status receipt_appl_status,
               acr.receipt_date original_receipt_date,
               acr.attribute13 i1025_process_code
        INTO   lc_receipt_method,
               ln_cash_receipt_id,
               ln_receipt_class_id,
               lc_receipt_class,
               ln_receipt_number,
               lc_receipt_status,
               lc_receipt_appl_status,
               ld_original_receipt_date,
               lc_i1025_process_code
        FROM   ar_cash_receipts_all acr,
               ar_receipt_methods arm,
               ar_receipt_classes arl,
               ar_cash_receipt_history_all acrh
        WHERE  acr.cash_receipt_id = acrh.cash_receipt_id
        AND    acr.receipt_method_id = arm.receipt_method_id
        AND    arm.receipt_class_id = arl.receipt_class_id
        AND    acr.org_id = p_org_id
        AND    acr.cash_receipt_id = p_cash_receipt_id
        AND    acrh.current_record_flag = 'Y';

-- -------------------------------------------------
------Get payment information---------
-- -------------------------------------------------
        IF (gb_debug)
        THEN
            put_log_line('       Getting the Despoit Payment Information');
        END IF;

        BEGIN
            SELECT rct.customer_trx_id,
                   rct.trx_number,
                   rct.status_trx,
                   rct.trx_date,
                   aps.payment_schedule_id,
                   aps.amount_due_remaining,
                   aps.status payment_schedule_status
            INTO   ln_customer_trx_id,
                   ln_trx_number,
                   lc_status_trx,
                   ld_trx_date,
                   ln_payment_schedule_id,
                   ln_amount_due_remaining,
                   lc_payment_schedule_status
            FROM   ra_customer_trx_all rct, ar_payment_schedules_all aps
            WHERE  rct.customer_trx_id = aps.customer_trx_id
            AND    rct.org_id = p_org_id
            AND    rct.customer_trx_id = p_customer_trx_id;
        EXCEPTION
            WHEN OTHERS
            THEN
                ln_customer_trx_id := NULL;
                ln_trx_number := NULL;
                lc_status_trx := NULL;
                ld_trx_date := NULL;
                ln_payment_schedule_id := NULL;
                ln_amount_due_remaining := NULL;
                lc_payment_schedule_status := NULL;
        END;

-- -------------------------------------------------
-- Mapping the Information ---------
-- -------------------------------------------------
        IF (gb_debug)
        THEN
            put_log_line('       Mapping the information');
        END IF;

        x_current_row.record_type := xx_ar_prepayments_pkg.gc_i1025_record_type_deposit;
        x_current_row.xx_payment_rowid := l_deposits_cm_row.ROWID;
        x_current_row.orig_sys_document_ref := l_deposits_cm_row.orig_sys_document_ref;
        x_current_row.bill_to_customer_id := l_deposits_cm_row.sold_to_org_id;
        x_current_row.bill_to_customer := l_deposits_cm_row.sold_to_org;
        x_current_row.bill_to_site_use_id := NULL;
        x_current_row.party_id := l_deposits_cm_row.party_id;
        x_current_row.org_id := l_deposits_cm_row.org_id;
        x_current_row.header_id := l_deposits_cm_row.header_id;
        x_current_row.order_number := l_deposits_cm_row.order_number;
        x_current_row.ordered_date := l_deposits_cm_row.ordered_date;
        x_current_row.payment_number := l_deposits_cm_row.payment_number;
        x_current_row.payment_set_id := l_deposits_cm_row.payment_set_id;
        x_current_row.payment_type_code := l_deposits_cm_row.payment_type_code;
        x_current_row.credit_card_code := l_deposits_cm_row.credit_card_code;
        x_current_row.credit_card_number := l_deposits_cm_row.credit_card_number;
        x_current_row.credit_card_holder_name := l_deposits_cm_row.credit_card_holder_name;
        x_current_row.credit_card_expiration_date := l_deposits_cm_row.credit_card_expiration_date;
        x_current_row.credit_card_approval_code := l_deposits_cm_row.credit_card_approval_code;
        x_current_row.credit_card_approval_date := l_deposits_cm_row.credit_card_approval_date;
        x_current_row.check_number := l_deposits_cm_row.check_number;
        x_current_row.line_id := l_deposits_cm_row.line_id;
        x_current_row.currency_code := l_deposits_cm_row.currency_code;
        x_current_row.receipt_method_id := l_deposits_cm_row.receipt_method_id;
        x_current_row.receipt_method := lc_receipt_method;
        x_current_row.receipt_class_id := ln_receipt_class_id;
        x_current_row.receipt_class := lc_receipt_class;
        x_current_row.cash_receipt_id := ln_cash_receipt_id;
        x_current_row.receipt_number := ln_receipt_number;
        x_current_row.receipt_appl_status := lc_receipt_appl_status;
        x_current_row.receipt_status := lc_receipt_status;
        x_current_row.original_receipt_date := ld_original_receipt_date;
        x_current_row.i1025_process_code := lc_i1025_process_code;
        x_current_row.customer_trx_id := ln_customer_trx_id;
        x_current_row.trx_date := ld_trx_date;
        x_current_row.trx_number := ln_trx_number;
        x_current_row.trx_type := NULL;
        x_current_row.payment_schedule_id := ln_payment_schedule_id;
        x_current_row.amount_due_remaining := ln_amount_due_remaining;
        x_current_row.payment_schedule_status := lc_payment_schedule_status;
        x_current_row.amount := l_deposits_cm_row.amount;
        x_current_row.cc_auth_ps2000 := l_deposits_cm_row.cc_auth_ps2000;
        x_current_row.cc_auth_manual := l_deposits_cm_row.cc_auth_manual;
        x_current_row.cc_mask_number := l_deposits_cm_row.cc_mask_number;
        x_current_row.merchant_number := l_deposits_cm_row.merchant_number;
        x_current_row.od_payment_type := l_deposits_cm_row.od_payment_type;
        x_current_row.debit_card_approval_ref := l_deposits_cm_row.debit_card_approval_ref;
        x_current_row.i1025_status := l_deposits_cm_row.i1025_status;
        x_current_row.creation_date := l_deposits_cm_row.creation_date;
        x_current_row.receipt_date := l_deposits_cm_row.receipt_date;
        x_current_row.paid_at_store_id := l_deposits_cm_row.paid_at_store_id;
        x_current_row.sale_location := l_deposits_cm_row.sale_location;
        x_current_row.ship_from_org_id := NULL;
        x_current_row.ship_from_org := NULL;
        x_current_row.process_code := l_deposits_cm_row.process_code;
        x_current_row.cc_entry_mode := l_deposits_cm_row.cc_entry_mode;
        x_current_row.cvv_resp_code := l_deposits_cm_row.cvv_resp_code;
        x_current_row.avs_resp_code := l_deposits_cm_row.avs_resp_code;
        x_current_row.auth_entry_mode := l_deposits_cm_row.auth_entry_mode;
        x_current_row.payment_type_flag := l_deposits_cm_row.payment_type_flag;
        x_current_row.deposit_reversal_flag := l_deposits_cm_row.deposit_reversal_flag;
        x_current_row.transaction_number := l_deposits_cm_row.transaction_number;
        x_current_row.om_import_date := l_deposits_cm_row.om_import_date;
        x_current_row.imp_file_name := l_deposits_cm_row.imp_file_name;
        x_current_row.ref_legacy_order_num := NULL;
        x_current_row.payment_type_new :=
            xx_ar_prepayments_pkg.get_payment_type(p_org_id =>                 l_deposits_cm_row.org_id,
                                                   p_receipt_method_id =>      l_deposits_cm_row.receipt_method_id,
                                                   p_payment_type =>           l_deposits_cm_row.payment_type_code);
        x_current_row.IDENTIFIER := l_deposits_cm_row.IDENTIFIER;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END map_apply_deposit_to_current;

-- ====================================================================================
-- Start  Procedure added for credit card deposit cancellations
--      1.Create a Zero Dollar Reeceipt
--      2.Create a Credit Memo
--      3.Apply the Zero-Dollar Receipt to the Credit Memo created
--      4.Write-off the Zero-Dollar Deposit receipt
-- ====================================================================================
    PROCEDURE create_credit_card_deposit_ref(
        p_current_row       IN OUT NOCOPY  gt_current_record,
        x_cash_receipt_row  OUT NOCOPY     ar_cash_receipts%ROWTYPE)
    IS
        lc_sub_name     CONSTANT VARCHAR2(50)                                 := 'CREATE_CREDIT_CARD_DEPOSIT_REFUND';
        x_original               gt_original;
        x_return_status          VARCHAR2(1)                                  DEFAULT NULL;
        x_cash_receipt_rec       ar_cash_receipts%ROWTYPE;
        x_process_flag           VARCHAR2(10)                                 DEFAULT NULL;
        lc_return_status         VARCHAR2(10)                                 DEFAULT NULL;
        ln_msg_count             NUMBER                                       DEFAULT NULL;
        lc_msg_data              VARCHAR2(2000);
        ln_batch_source_id       NUMBER;
        ln_cust_trx_type_id      NUMBER;
        lr_batch_source_rec      ar_invoice_api_pub.batch_source_rec_type;
        lt_trx_header_tbl        ar_invoice_api_pub.trx_header_tbl_type;
        lt_trx_lines_tbl         ar_invoice_api_pub.trx_line_tbl_type;
        lt_trx_dist_tbl          ar_invoice_api_pub.trx_dist_tbl_type;
        lt_trx_salescredits_tbl  ar_invoice_api_pub.trx_salescredits_tbl_type;
        ln_cust_trx_id           NUMBER                                       DEFAULT NULL;
        ln_cnt                   NUMBER                                       := 0;
        ln_seq                   NUMBER;
        ln_customer_trx_id       NUMBER;
        ln_memo_line_id          NUMBER;
        lc_memo_description      VARCHAR2(50)                                 DEFAULT NULL;
        ln_pay_schedule_id       NUMBER;
        p_rowid                  ROWID;
        p_org_id                 NUMBER;
        ln_error_message         VARCHAR2(2000);
        ln_error_value           VARCHAR2(2000);

        CURSOR cm_error(
            p_trx_header_id  NUMBER)
        IS
            SELECT error_message,
                   invalid_value
            FROM   ar_trx_errors_gt
            WHERE  trx_header_id = p_trx_header_id;
    BEGIN
-- ===========================================================
-- To create zero-dollar receipts for Deposits           -----
-- ===========================================================
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
            put_log_line();
            put_log_line('Call Create Zero Dollar Receipt for Deposit...');
        END IF;

        -- Reinitialising----
        x_original := NULL;
        x_process_flag := 'D';
        create_zero_receipt(x_return_status =>         x_return_status,
                            p_current_row =>           p_current_row,
                            x_cash_receipt_rec =>      x_cash_receipt_rec,
                            x_original =>              x_original,
                            x_process_flag =>          x_process_flag   --Added for CR 722(Defect 6033)
                                                                     );

        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('Zero dollar Receipt Created ');
        END IF;

        x_cash_receipt_row := x_cash_receipt_rec;

-- ===============================================
---  To create Credit Memo for Deposits   -----
-- ==============================================
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('To Create Credit Memo for Deposit ...');
        END IF;

        SELECT ra_customer_trx_s.NEXTVAL
        INTO   ln_seq
        FROM   DUAL;

---=========================---
------Get the Line Memo ID ----
---=========================---
        SELECT aml.memo_line_id,
               aml.description
        INTO   ln_memo_line_id,
               lc_memo_description
        FROM   ar_memo_lines_all_tl aml, xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
        WHERE  aml.NAME = xftv.source_value1
        AND    xftd.translate_id = xftv.translate_id
        AND    xftd.translation_name = 'XX_AR_I1025_CC_DEP_REFUND'
        AND    aml.org_id = xftv.source_value4
        AND    aml.org_id = p_current_row.org_id
        AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    xftv.enabled_flag = 'Y'
        AND    xftd.enabled_flag = 'Y';

------------------------------
-----Get the Batch Source Id --
------------------------------
        SELECT rbs.batch_source_id
        INTO   ln_batch_source_id
        FROM   ra_batch_sources_all rbs, xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
        WHERE  rbs.NAME = xftv.source_value2
        AND    xftd.translate_id = xftv.translate_id
        AND    xftd.translation_name = 'XX_AR_I1025_CC_DEP_REFUND'
        AND    rbs.org_id = xftv.source_value4
        AND    rbs.org_id = p_current_row.org_id
        AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    xftv.enabled_flag = 'Y'
        AND    xftd.enabled_flag = 'Y';

---------------------------------
-----Get the Cust Trx Type Id ---
---------------------------------
        SELECT rct.cust_trx_type_id
        INTO   ln_cust_trx_type_id
        FROM   ra_cust_trx_types_all rct, xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
        WHERE  rct.NAME = xftv.source_value3
        AND    xftd.translate_id = xftv.translate_id
        AND    xftd.translation_name = 'XX_AR_I1025_CC_DEP_REFUND'
        AND    rct.org_id = xftv.source_value4
        AND    rct.org_id = p_current_row.org_id
        AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    xftv.enabled_flag = 'Y'
        AND    xftd.enabled_flag = 'Y';

---------------------------------
-----Header and Line Details-----
---------------------------------
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(' ---- Header Details ------');
            put_log_line(   'Batch_source_id      '
                         || ln_batch_source_id);
            put_log_line(   'Trx_header_id        '
                         || ln_seq);
            put_log_line(   'trx_date             '
                         || p_current_row.receipt_date);
            put_log_line(   'Cust_trx_type_id     '
                         || ln_cust_trx_type_id);
            put_log_line(   'Bill_to_customer_id  '
                         || p_current_row.bill_to_customer_id);
            put_log_line();
            put_log_line(' ---- Line Details ------ ');
            put_log_line(   'Memo_line_id         '
                         || ln_memo_line_id);
            put_log_line(   'Unit_selling_price   '
                         || p_current_row.amount);
        END IF;

-----------------------------------------
-- Setting value to headers parameters --
-----------------------------------------
        lr_batch_source_rec.batch_source_id := ln_batch_source_id;
        lt_trx_header_tbl(1).trx_header_id := ln_seq;
        lt_trx_header_tbl(1).trx_date := p_current_row.receipt_date;
        lt_trx_header_tbl(1).trx_currency := p_current_row.currency_code;
        lt_trx_header_tbl(1).cust_trx_type_id := ln_cust_trx_type_id;
        lt_trx_header_tbl(1).bill_to_customer_id := p_current_row.bill_to_customer_id;
-----------------------------------------
-- Setting value to Line parameters  --
-----------------------------------------
        lt_trx_lines_tbl(1).trx_header_id := ln_seq;
        lt_trx_lines_tbl(1).trx_line_id := 101;
        lt_trx_lines_tbl(1).line_number := 1;
        lt_trx_lines_tbl(1).memo_line_id := ln_memo_line_id;
        lt_trx_lines_tbl(1).description := lc_memo_description;
        lt_trx_lines_tbl(1).quantity_invoiced := 1;
        lt_trx_lines_tbl(1).unit_selling_price := p_current_row.amount;   --Negative value
        lt_trx_lines_tbl(1).line_type := 'LINE';
        lt_trx_lines_tbl(1).tax_exempt_flag := 'E';
        lt_trx_lines_tbl(1).tax_exempt_reason_code := 'OTHER/MISCELLANEOUS';

        IF (gb_debug)
        THEN
            arp_standard.enable_debug;
        END IF;

        lc_return_status := NULL;
        ln_msg_count := NULL;
        lc_msg_data := NULL;
        ar_invoice_api_pub.create_single_invoice(p_api_version =>               1.0,
                                                 p_commit =>                    fnd_api.g_false,
                                                 p_batch_source_rec =>          lr_batch_source_rec,
                                                 p_trx_header_tbl =>            lt_trx_header_tbl,
                                                 p_trx_lines_tbl =>             lt_trx_lines_tbl,
                                                 p_trx_dist_tbl =>              lt_trx_dist_tbl,
                                                 p_trx_salescredits_tbl =>      lt_trx_salescredits_tbl,
                                                 x_customer_trx_id =>           ln_customer_trx_id,
                                                 x_return_status =>             lc_return_status,
                                                 x_msg_count =>                 ln_msg_count,
                                                 x_msg_data =>                  lc_msg_data);

        IF (gb_debug)
        THEN
            put_log_line(   '- Return Status: '
                         || lc_return_status
                         || ', Msg Cnt: '
                         || ln_msg_count);
        END IF;

        --------Getting the Data from AR_TRX_ERRORS_GT-------------
        FOR rec_error IN cm_error(ln_seq)
        LOOP
            put_log_line(   'ln_error_message '
                         || rec_error.error_message);
            put_log_line(   'ln_error_value '
                         || rec_error.invalid_value);
        END LOOP;

        IF (lc_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Successfully Created credit memo.');
                put_log_line(   '   customer_trx_id = '
                             || ln_customer_trx_id);
            END IF;
        ELSE
            raise_api_errors(p_sub_name =>       lc_sub_name,
                             p_msg_count =>      ln_msg_count,
                             p_api_name =>       'AR_INVOICE_API_PUB.create_single_invoice');
        END IF;

        lc_return_status := NULL;
        ln_msg_count := NULL;
        lc_msg_data := NULL;

-- ================================================================================================
-- Apply the zero-dollar receipt or the matching original receipt to the newly created credit memo
-- ================================================================================================
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('To Apply the newly created Credit Memo to the Zero-Dollar Receipt');
            put_log_line(   '     Customer_trxId '
                         || ln_customer_trx_id);
            put_log_line(   '     Cash Receipt Id '
                         || x_cash_receipt_rec.cash_receipt_id);
        END IF;

        ar_receipt_api_pub.APPLY(p_api_version =>           1.0,
                                 p_init_msg_list =>         fnd_api.g_true,
                                 p_commit =>                fnd_api.g_false,
                                 p_validation_level =>      fnd_api.g_valid_level_full,
                                 x_return_status =>         lc_return_status,
                                 x_msg_count =>             ln_msg_count,
                                 x_msg_data =>              lc_msg_data,
                                 p_cash_receipt_id =>       x_cash_receipt_rec.cash_receipt_id,
                                 p_customer_trx_id =>       ln_customer_trx_id,
                                 p_amount_applied =>        p_current_row.amount,
                                 p_comments =>              'I1025 (Apply Credit Memo)',
                                 p_called_from =>           'I1025');

        IF (gb_debug)
        THEN
            put_log_line(   '   - Return Status: '
                         || lc_return_status
                         || ', Msg Cnt: '
                         || ln_msg_count);
        END IF;

        IF (lc_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Successfully applied Refund Receipt to credit memo.');
            END IF;
        ELSE
            raise_api_errors(p_sub_name =>       lc_sub_name,
                             p_msg_count =>      ln_msg_count,
                             p_api_name =>       'Deposit : AR_RECEIPT_API_PUB.apply');
        END IF;

-- ==================================================================
----Mapping the applied deposit cursor record to current record type
-- ==================================================================
        p_rowid := p_current_row.xx_payment_rowid;
        p_org_id := p_current_row.org_id;

        IF (gb_debug)
        THEN
            put_log_line('Map_apply_deposit_to_current');
            put_log_line(   '  Row ID  : '
                         || p_rowid);
            put_log_line(   '  Org_id  : '
                         || p_org_id);
            put_log_line(   '  Cash Receipt Id : '
                         || x_cash_receipt_rec.cash_receipt_id);
            put_log_line(   '  Customer_trxId  : '
                         || ln_customer_trx_id);
        END IF;

        map_apply_deposit_to_current(p_rowid =>                p_rowid,
                                     p_org_id =>               p_org_id,
                                     p_cash_receipt_id =>      x_cash_receipt_rec.cash_receipt_id,
                                     p_customer_trx_id =>      ln_customer_trx_id,
                                     x_current_row =>          p_current_row);

-- ==========================================================================
-- output the details of the record
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('Mapped Values .....');
            put_log_line(   '  Cust Acct Id      = '
                         || p_current_row.bill_to_customer_id);
            put_log_line(   '  Legacy Order      = '
                         || p_current_row.orig_sys_document_ref);
            put_log_line(   '  Receipt Number    = '
                         || p_current_row.receipt_number);
            put_log_line(   '  Receipt Status    = '
                         || p_current_row.receipt_status);
            put_log_line(   '  Cash Receipt Id   = '
                         || p_current_row.cash_receipt_id);
            put_log_line(   '  Customer Trx Id   = '
                         || p_current_row.customer_trx_id);
            put_log_line(   '  Invoice Number    = '
                         || p_current_row.trx_number);
            put_log_line(   '  Sale Location     = '
                         || p_current_row.sale_location);
            put_log_line(   '  Ship From Org     = '
                         || p_current_row.ship_from_org);
            put_log_line(   '  Pmt Schedule Id   = '
                         || p_current_row.payment_schedule_id);
            put_log_line(   '  Trx Status        = '
                         || p_current_row.payment_schedule_status);
            put_log_line(   '  Pmt Type (Actual) = '
                         || p_current_row.payment_type_new);
            put_log_line(   '  Receipt Date      = '
                         || p_current_row.receipt_date);
            put_log_line(   '  I1025 Status      = '
                         || p_current_row.i1025_status);
            put_log_line();
        END IF;

-- ==========================================================================
-- For any other refund other than matching CC refund, writeoff the receipt
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('Calling  Writeoff_receipt_credit_bal');
        END IF;

        writeoff_receipt_credit_bal(p_current_row =>           p_current_row,
                                    x_cash_receipt_rec =>      x_cash_receipt_rec,
                                    x_process_flag =>          x_process_flag);   --Added for CR 722(Defect 6033)

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END create_credit_card_deposit_ref;

-- ====================================================================================
-- Start  Procedure added for CR 722(Defect 6033) for I1025 Multitender Refund for Deposit process:
--      1.Create a Zero Dollar Reeceipt
--      2.Create a Credit Memo
--      3.Apply the Zero-Dollar Receipt to the Credit Memo created
--      4.Write-off the Zero-Dollar Deposit receipt
-- ====================================================================================
    PROCEDURE create_multitender_deposit_ref(
        p_current_row       IN OUT NOCOPY  gt_current_record,
        x_cash_receipt_row  OUT NOCOPY     ar_cash_receipts%ROWTYPE)
    IS
        lc_sub_name     CONSTANT VARCHAR2(50)                                 := 'CREATE_MULTITENDER_DEPOSIT_REF';
        x_original               gt_original;
        x_return_status          VARCHAR2(1)                                  DEFAULT NULL;
        x_cash_receipt_rec       ar_cash_receipts%ROWTYPE;
        x_process_flag           VARCHAR2(10)                                 DEFAULT NULL;
        lc_return_status         VARCHAR2(10)                                 DEFAULT NULL;
        ln_msg_count             NUMBER                                       DEFAULT NULL;
        lc_msg_data              VARCHAR2(2000);
        ln_batch_source_id       NUMBER;
        ln_cust_trx_type_id      NUMBER;
        lr_batch_source_rec      ar_invoice_api_pub.batch_source_rec_type;
        lt_trx_header_tbl        ar_invoice_api_pub.trx_header_tbl_type;
        lt_trx_lines_tbl         ar_invoice_api_pub.trx_line_tbl_type;
        lt_trx_dist_tbl          ar_invoice_api_pub.trx_dist_tbl_type;
        lt_trx_salescredits_tbl  ar_invoice_api_pub.trx_salescredits_tbl_type;
        ln_cust_trx_id           NUMBER                                       DEFAULT NULL;
        ln_cnt                   NUMBER                                       := 0;
        ln_seq                   NUMBER;
        ln_customer_trx_id       NUMBER;
        ln_memo_line_id          NUMBER;
        lc_memo_description      VARCHAR2(50)                                 DEFAULT NULL;
        ln_pay_schedule_id       NUMBER;
        p_rowid                  ROWID;
        p_org_id                 NUMBER;
        ln_error_message         VARCHAR2(2000);
        ln_error_value           VARCHAR2(2000);

        CURSOR cm_error(
            p_trx_header_id  NUMBER)
        IS
            SELECT error_message,
                   invalid_value
            FROM   ar_trx_errors_gt
            WHERE  trx_header_id = p_trx_header_id;
    BEGIN
-- ===========================================================
-- To create zero-dollar receipts for Deposits           -----
-- ===========================================================
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
            put_log_line();
            put_log_line('Call Create Zero Dollar Receipt for Deposit...');
        END IF;

        -- Reinitialising----
        x_original := NULL;
        x_process_flag := 'D';
        create_zero_receipt(x_return_status =>         x_return_status,
                            p_current_row =>           p_current_row,
                            x_cash_receipt_rec =>      x_cash_receipt_rec,
                            x_original =>              x_original,
                            x_process_flag =>          x_process_flag   --Added for CR 722(Defect 6033)
                                                                     );

        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('Zero dollar Receipt Created ');
        END IF;

        x_cash_receipt_row := x_cash_receipt_rec;

-- ===============================================
---  To create Credit Memo for Deposits   -----
-- ==============================================
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('To Create Credit Memo for Deposit ...');
        END IF;

        SELECT ra_customer_trx_s.NEXTVAL
        INTO   ln_seq
        FROM   DUAL;

---=========================---
------Get the Line Memo ID ----
---=========================---
        SELECT aml.memo_line_id,
               aml.description
        INTO   ln_memo_line_id,
               lc_memo_description
        FROM   ar_memo_lines_all_tl aml, xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
        WHERE  aml.NAME = xftv.source_value1
        AND    xftd.translate_id = xftv.translate_id
        AND    xftd.translation_name = 'XX_AR_I1025_MULTI_DEPOSIT'
        AND    aml.org_id = xftv.source_value4
        AND    aml.org_id = p_current_row.org_id
        AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    xftv.enabled_flag = 'Y'
        AND    xftd.enabled_flag = 'Y';

------------------------------
-----Get the Batch Source Id --
------------------------------
        SELECT rbs.batch_source_id
        INTO   ln_batch_source_id
        FROM   ra_batch_sources_all rbs, xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
        WHERE  rbs.NAME = xftv.source_value2
        AND    xftd.translate_id = xftv.translate_id
        AND    xftd.translation_name = 'XX_AR_I1025_MULTI_DEPOSIT'
        AND    rbs.org_id = xftv.source_value4
        AND    rbs.org_id = p_current_row.org_id
        AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    xftv.enabled_flag = 'Y'
        AND    xftd.enabled_flag = 'Y';

---------------------------------
-----Get the Cust Trx Type Id ---
---------------------------------
        SELECT rct.cust_trx_type_id
        INTO   ln_cust_trx_type_id
        FROM   ra_cust_trx_types_all rct, xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
        WHERE  rct.NAME = xftv.source_value3
        AND    xftd.translate_id = xftv.translate_id
        AND    xftd.translation_name = 'XX_AR_I1025_MULTI_DEPOSIT'
        AND    rct.org_id = xftv.source_value4
        AND    rct.org_id = p_current_row.org_id
        AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    xftv.enabled_flag = 'Y'
        AND    xftd.enabled_flag = 'Y';

---------------------------------
-----Header and Line Details-----
---------------------------------
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(' ---- Header Details ------');
            put_log_line(   'Batch_source_id      '
                         || ln_batch_source_id);
            put_log_line(   'Trx_header_id        '
                         || ln_seq);
            put_log_line(   'trx_date             '
                         || p_current_row.receipt_date);
            put_log_line(   'Cust_trx_type_id     '
                         || ln_cust_trx_type_id);
            put_log_line(   'Bill_to_customer_id  '
                         || p_current_row.bill_to_customer_id);
            put_log_line();
            put_log_line(' ---- Line Details ------ ');
            put_log_line(   'Memo_line_id         '
                         || ln_memo_line_id);
            put_log_line(   'Unit_selling_price   '
                         || p_current_row.amount);
        END IF;

-----------------------------------------
-- Setting value to headers parameters --
-----------------------------------------
        lr_batch_source_rec.batch_source_id := ln_batch_source_id;
        lt_trx_header_tbl(1).trx_header_id := ln_seq;
        lt_trx_header_tbl(1).trx_date := p_current_row.receipt_date;
        lt_trx_header_tbl(1).trx_currency := p_current_row.currency_code;
        lt_trx_header_tbl(1).cust_trx_type_id := ln_cust_trx_type_id;
        lt_trx_header_tbl(1).bill_to_customer_id := p_current_row.bill_to_customer_id;
-----------------------------------------
-- Setting value to Line parameters  --
-----------------------------------------
        lt_trx_lines_tbl(1).trx_header_id := ln_seq;
        lt_trx_lines_tbl(1).trx_line_id := 101;
        lt_trx_lines_tbl(1).line_number := 1;
        lt_trx_lines_tbl(1).memo_line_id := ln_memo_line_id;
        lt_trx_lines_tbl(1).description := lc_memo_description;
        lt_trx_lines_tbl(1).quantity_invoiced := 1;
        lt_trx_lines_tbl(1).unit_selling_price := p_current_row.amount;   --Negative value
        lt_trx_lines_tbl(1).line_type := 'LINE';
        lt_trx_lines_tbl(1).tax_exempt_flag := 'E';
        lt_trx_lines_tbl(1).tax_exempt_reason_code := 'OTHER/MISCELLANEOUS';

        IF (gb_debug)
        THEN
            arp_standard.enable_debug;
        END IF;

        lc_return_status := NULL;
        ln_msg_count := NULL;
        lc_msg_data := NULL;
        ar_invoice_api_pub.create_single_invoice(p_api_version =>               1.0,
                                                 p_commit =>                    fnd_api.g_false,
                                                 p_batch_source_rec =>          lr_batch_source_rec,
                                                 p_trx_header_tbl =>            lt_trx_header_tbl,
                                                 p_trx_lines_tbl =>             lt_trx_lines_tbl,
                                                 p_trx_dist_tbl =>              lt_trx_dist_tbl,
                                                 p_trx_salescredits_tbl =>      lt_trx_salescredits_tbl,
                                                 x_customer_trx_id =>           ln_customer_trx_id,
                                                 x_return_status =>             lc_return_status,
                                                 x_msg_count =>                 ln_msg_count,
                                                 x_msg_data =>                  lc_msg_data);

        IF (gb_debug)
        THEN
            put_log_line(   '- Return Status: '
                         || lc_return_status
                         || ', Msg Cnt: '
                         || ln_msg_count);
        END IF;

        --------Getting the Data from AR_TRX_ERRORS_GT-------------
        FOR rec_error IN cm_error(ln_seq)
        LOOP
            put_log_line(   'ln_error_message '
                         || rec_error.error_message);
            put_log_line(   'ln_error_value '
                         || rec_error.invalid_value);
        END LOOP;

        IF (lc_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Successfully Created credit memo.');
                put_log_line(   '   customer_trx_id = '
                             || ln_customer_trx_id);
            END IF;
        ELSE
            raise_api_errors(p_sub_name =>       lc_sub_name,
                             p_msg_count =>      ln_msg_count,
                             p_api_name =>       'AR_INVOICE_API_PUB.create_single_invoice');
        END IF;

        lc_return_status := NULL;
        ln_msg_count := NULL;
        lc_msg_data := NULL;

-- ================================================================================================
-- Apply the zero-dollar receipt or the matching original receipt to the newly created credit memo
-- ================================================================================================
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('To Apply the newly created Credit Memo to the Zero-Dollar Receipt');
            put_log_line(   '     Customer_trxId '
                         || ln_customer_trx_id);
            put_log_line(   '     Cash Receipt Id '
                         || x_cash_receipt_rec.cash_receipt_id);
        END IF;

        ar_receipt_api_pub.APPLY(p_api_version =>           1.0,
                                 p_init_msg_list =>         fnd_api.g_true,
                                 p_commit =>                fnd_api.g_false,
                                 p_validation_level =>      fnd_api.g_valid_level_full,
                                 x_return_status =>         lc_return_status,
                                 x_msg_count =>             ln_msg_count,
                                 x_msg_data =>              lc_msg_data,
                                 p_cash_receipt_id =>       x_cash_receipt_rec.cash_receipt_id,
                                 p_customer_trx_id =>       ln_customer_trx_id,
                                 p_amount_applied =>        p_current_row.amount,
                                 p_comments =>              'I1025 (Apply Credit Memo)',
                                 p_called_from =>           'I1025');

        IF (gb_debug)
        THEN
            put_log_line(   '   - Return Status: '
                         || lc_return_status
                         || ', Msg Cnt: '
                         || ln_msg_count);
        END IF;

        IF (lc_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Successfully applied Refund Receipt to credit memo.');
            END IF;
        ELSE
            raise_api_errors(p_sub_name =>       lc_sub_name,
                             p_msg_count =>      ln_msg_count,
                             p_api_name =>       'Deposit : AR_RECEIPT_API_PUB.apply');
        END IF;

-- ==================================================================
----Mapping the applied deposit cursor record to current record type
-- ==================================================================
        p_rowid := p_current_row.xx_payment_rowid;
        p_org_id := p_current_row.org_id;

        IF (gb_debug)
        THEN
            put_log_line('Map_apply_deposit_to_current');
            put_log_line(   '  Row ID  : '
                         || p_rowid);
            put_log_line(   '  Org_id  : '
                         || p_org_id);
            put_log_line(   '  Cash Receipt Id : '
                         || x_cash_receipt_rec.cash_receipt_id);
            put_log_line(   '  Customer_trxId  : '
                         || ln_customer_trx_id);
        END IF;

        map_apply_deposit_to_current(p_rowid =>                p_rowid,
                                     p_org_id =>               p_org_id,
                                     p_cash_receipt_id =>      x_cash_receipt_rec.cash_receipt_id,
                                     p_customer_trx_id =>      ln_customer_trx_id,
                                     x_current_row =>          p_current_row);

-- ==========================================================================
-- output the details of the record
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('Mapped Values .....');
            put_log_line(   '  Cust Acct Id      = '
                         || p_current_row.bill_to_customer_id);
            put_log_line(   '  Legacy Order      = '
                         || p_current_row.orig_sys_document_ref);
            put_log_line(   '  Receipt Number    = '
                         || p_current_row.receipt_number);
            put_log_line(   '  Receipt Status    = '
                         || p_current_row.receipt_status);
            put_log_line(   '  Cash Receipt Id   = '
                         || p_current_row.cash_receipt_id);
            put_log_line(   '  Customer Trx Id   = '
                         || p_current_row.customer_trx_id);
            put_log_line(   '  Invoice Number    = '
                         || p_current_row.trx_number);
            put_log_line(   '  Sale Location     = '
                         || p_current_row.sale_location);
            put_log_line(   '  Ship From Org     = '
                         || p_current_row.ship_from_org);
            put_log_line(   '  Pmt Schedule Id   = '
                         || p_current_row.payment_schedule_id);
            put_log_line(   '  Trx Status        = '
                         || p_current_row.payment_schedule_status);
            put_log_line(   '  Pmt Type (Actual) = '
                         || p_current_row.payment_type_new);
            put_log_line(   '  Receipt Date      = '
                         || p_current_row.receipt_date);
            put_log_line(   '  I1025 Status      = '
                         || p_current_row.i1025_status);
            put_log_line();
        END IF;

-- ==========================================================================
-- For any other refund other than matching CC refund, writeoff the receipt
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('Calling  Writeoff_receipt_credit_bal');
        END IF;

        writeoff_receipt_credit_bal(p_current_row =>           p_current_row,
                                    x_cash_receipt_rec =>      x_cash_receipt_rec,
                                    x_process_flag =>          x_process_flag);   --Added for CR 722(Defect 6033)

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END create_multitender_deposit_ref;

-- ==================================================================================
-- Added for CR 722(Defect 6033) -Procedure to Write Off the Original multi deposit receipts
-- ==================================================================================
    PROCEDURE multi_deposit_rec_writeoff(
        p_cash_receipt_id  IN             ar_cash_receipts_all.cash_receipt_id%TYPE,
        p_current_row      IN OUT NOCOPY  gt_current_record)
    IS
        lc_sub_name            CONSTANT VARCHAR2(50)                                    := 'MULTI_DEPOSIT_REC_WRITEOFF';
        x_cash_receipt_rec              ar_cash_receipts%ROWTYPE;
        l_prepay_appl_rec               xx_ar_prepayments_pkg.gcu_prepay_appl%ROWTYPE;
        lc_sale_location                VARCHAR2(50);
        ln_receipt_method_id            NUMBER                                                         DEFAULT NULL;
        ln_org_id                       NUMBER                                                         DEFAULT NULL;
        lc_payment_type_code            VARCHAR2(50);
        lc_receivables_trx              ar_receivables_trx.NAME%TYPE                                   DEFAULT NULL;
        ln_receivables_trx_id           ar_receivables_trx.receivables_trx_id%TYPE                     DEFAULT NULL;
        lc_refund_recv_trx              ar_receivables_trx.NAME%TYPE                                   DEFAULT NULL;
        x_receivable_application_id     ar_receivable_applications.receivable_application_id%TYPE      DEFAULT NULL;
        x_return_status                 VARCHAR2(20)                                                   DEFAULT NULL;
        x_msg_count                     NUMBER                                                         DEFAULT NULL;
        x_msg_data                      VARCHAR2(4000)                                                 DEFAULT NULL;
        x_application_ref_type          ar_receivable_applications.application_ref_type%TYPE           DEFAULT NULL;
        x_application_ref_id            ar_receivable_applications.application_ref_id%TYPE             DEFAULT NULL;
        x_application_ref_num           ar_receivable_applications.application_ref_num%TYPE            DEFAULT NULL;
        x_secondary_application_ref_id  ar_receivable_applications.secondary_application_ref_id%TYPE   DEFAULT NULL;
        x_payment_set_id                ar_receivable_applications.payment_set_id%TYPE                 DEFAULT NULL;
        ln_customer_trx_id              NUMBER;
        lc_app_customer_reference       ar_receivable_applications.customer_reference%TYPE             DEFAULT NULL;
        lc_app_comments                 ar_receivable_applications.comments%TYPE                       DEFAULT NULL;
        x_receipt_number                ar_cash_receipts.receipt_number%TYPE                           DEFAULT NULL;
        lc_receipt_comments             ar_cash_receipts.comments%TYPE                                 DEFAULT NULL;
        lc_customer_receipt_reference   ar_cash_receipts.customer_receipt_reference%TYPE               DEFAULT NULL;
        x_attributes                    ar_receipt_api_pub.attribute_rec_type;
        x_app_attributes                ar_receipt_api_pub.attribute_rec_type;
        x_receipt_ext_attributes        xx_ar_cash_receipts_ext%ROWTYPE;
        lc_application_ref_num          ar_receivable_applications.application_ref_num%TYPE;
        ln_rowid                        ROWID;
        lc_write_off_activity           VARCHAR2(50);
        ln_amount_recpt_bal             NUMBER;
        ln_amount_recpt_bal_tot         NUMBER;
        ln_amount_rev_bal               NUMBER                                                         := 0;
        lc_single_pay_ind               VARCHAR2(1)                                                    := 'N';
        ln_num_1                        NUMBER;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
            put_log_line();
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   '- To Fetch and Lock Receipt: '
                         || p_cash_receipt_id);
        END IF;

        x_cash_receipt_rec.cash_receipt_id := p_cash_receipt_id;
-- ==========================================================================
-- Fetch the latest AR receipt with a lock
-- ==========================================================================
        arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec =>      x_cash_receipt_rec);

        IF (gb_debug)
        THEN
            put_log_line('- Fetched and Locked Receipt: ');
            put_log_line(   '  cash receipt id = '
                         || x_cash_receipt_rec.cash_receipt_id);
            put_log_line(   '  receipt number  = '
                         || x_cash_receipt_rec.receipt_number);
            put_log_line(   '  Refund Amount   = '
                         || TO_CHAR(  -1
                                    * x_cash_receipt_rec.amount) );
            put_log_line(   '  Refund Date     = '
                         || x_cash_receipt_rec.receipt_date);
        END IF;

-- ==========================================================================
-- Fetch the recv application for the prepayment --Start
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('Fetching Prepayment: ');
        END IF;

-- Following Code added by Gaurav on 8/8/2011
        lc_application_ref_num := NULL;

        BEGIN
            SELECT raa.application_ref_num
            INTO   lc_application_ref_num
            FROM   ar_receivable_applications_all raa
            WHERE  cash_receipt_id = p_cash_receipt_id
            AND    raa.status = 'OTHER ACC'
            AND    raa.display = 'Y'
            AND    ROWNUM = 1;
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_application_ref_num := NULL;
        END;

        --  Ends here.

        -- l_prepay_appl_rec                               := XX_AR_PREPAYMENTS_PKG.get_prepay_application_record ( p_cash_receipt_id => p_cash_receipt_id ,p_reference_type => '%' ,p_reference_number => SUBSTR(p_current_row.orig_sys_document_ref ,1 ,9) || '%' );
        l_prepay_appl_rec :=
            xx_ar_prepayments_pkg.get_prepay_application_record(p_cash_receipt_id =>       p_cash_receipt_id,
                                                                p_reference_type =>        '%',
                                                                p_reference_number =>         lc_application_ref_num
                                                                                           || '%');

        IF (l_prepay_appl_rec.receivable_application_id IS NOT NULL)
        THEN
            IF (gb_debug)
            THEN
                put_log_line('  Unapply Prepayment: ');
                put_log_line(   '  recv appl id  = '
                             || l_prepay_appl_rec.receivable_application_id);
                put_log_line(   '  appl ref type = '
                             || l_prepay_appl_rec.application_ref_type);
                put_log_line(   '  appl ref num  = '
                             || l_prepay_appl_rec.application_ref_num);
                put_log_line(   '  prepay amount = '
                             || l_prepay_appl_rec.amount_applied);
            END IF;

-- ==========================================================================
-- Unapply the prepayment application
-- ==========================================================================
            xx_ar_prepayments_pkg.unapply_prepayment_application(p_prepay_appl_row =>      l_prepay_appl_rec);
        ELSE
            IF (gb_debug)
            THEN
                put_log_line('- No Prepayment Application could be found.');
            END IF;

            fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20104_NO_PREPAY_AP');
            add_message(p_current_row =>         p_current_row,
                        p_message_code =>        'NO_DEPOSIT_PREPAYMENT',
                        p_message_text =>        fnd_message.get(),
                        p_error_location =>      lc_sub_name,
                        p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_warning);
        END IF;

-- ==========================================================================
-- Fetch the recv application for the prepayment --End
-- ==========================================================================
        SELECT LPAD(haou.attribute1,
                    6,
                    '0'),
               xold.receipt_method_id,
               xold.org_id,
               xold.ROWID
        INTO   lc_sale_location,
               ln_receipt_method_id,
               ln_org_id,
               ln_rowid
        FROM   hr_all_organization_units haou, xx_om_legacy_deposits xold
        WHERE  haou.organization_id = xold.paid_at_store_id
        AND    xold.cash_receipt_id = p_cash_receipt_id;

        IF (gb_debug)
        THEN
            put_log_line('  Get the WriteOff Activity for the Receipt Method');
            put_log_line(   '  Receipt Method = '
                         || ln_receipt_method_id);
            put_log_line(   '  Sale  Location = '
                         || lc_sale_location);
            put_log_line(   '  Org ID         = '
                         || ln_org_id);
        END IF;

-- ==========================================================================
--Deriving  the Receivables Trx ID for the Writeoff Activity --
-- ==========================================================================
        BEGIN
            SELECT art.receivables_trx_id,
                   xftv.source_value5
            INTO   ln_receivables_trx_id,
                   lc_write_off_activity
            FROM   ar_receivables_trx_all art, xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
            WHERE  art.NAME = xftv.source_value5
            AND    xftd.translate_id = xftv.translate_id
            AND    xftd.translation_name = 'XX_AR_I1025_MULTI_DEPOSIT'
            AND    art.org_id = xftv.source_value4
            AND    art.org_id = ln_org_id
            AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                    SYSDATE
                                                                  + 1)
            AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                    SYSDATE
                                                                  + 1)
            AND    xftv.enabled_flag = 'Y'
            AND    xftd.enabled_flag = 'Y';
        EXCEPTION
            WHEN OTHERS
            THEN
                ln_receivables_trx_id := NULL;
        END;

        IF (gb_debug)
        THEN
            put_log_line(   '  Write-off Recv Trx Id = '
                         || ln_receivables_trx_id);
            put_log_line(   '  Write-off Activity    = '
                         || lc_write_off_activity);
        END IF;

        IF (ln_receivables_trx_id IS NULL)
        THEN
            fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20006_NO_RECV_ACTV');
            fnd_message.set_token('SUB_NAME',
                                  lc_sub_name);
            fnd_message.set_token('RECV_ACTIVITY',
                                  lc_receivables_trx);
            raise_application_error(-20006,
                                    fnd_message.get() );
        END IF;

-- ==========================================================================================
-- call map_apply_deposit_to_current to Map the values of the original Multitender  receipts
-- ==========================================================================================
        IF (gb_debug)
        THEN
            put_log_line
                  ('- Calling the map_apply_deposit_to_current to Map the values of the original Multitender  receipts');
        END IF;

        map_apply_deposit_to_current(p_rowid =>                ln_rowid,
                                     p_org_id =>               ln_org_id,
                                     p_cash_receipt_id =>      p_cash_receipt_id,
                                     p_customer_trx_id =>      ln_customer_trx_id,
                                     x_current_row =>          p_current_row);

        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('Mapped Values .....');
            put_log_line(   '  Cust Acct Id      = '
                         || p_current_row.bill_to_customer_id);
            put_log_line(   '  Legacy Order      = '
                         || p_current_row.orig_sys_document_ref);
            put_log_line(   '  Receipt Number    = '
                         || p_current_row.receipt_number);
            put_log_line(   '  Receipt Status    = '
                         || p_current_row.receipt_status);
            put_log_line(   '  Cash Receipt Id   = '
                         || p_cash_receipt_id);
            put_log_line(   '  Customer Trx Id   = '
                         || p_current_row.customer_trx_id);
            put_log_line(   '  Invoice Number    = '
                         || p_current_row.trx_number);
            put_log_line(   '  Sale Location     = '
                         || p_current_row.sale_location);
            put_log_line(   '  Ship From Org     = '
                         || p_current_row.ship_from_org);
            put_log_line(   '  Pmt Schedule Id   = '
                         || p_current_row.payment_schedule_id);
            put_log_line(   '  Trx Status        = '
                         || p_current_row.payment_schedule_status);
            put_log_line(   '  Pmt Type (Actual) = '
                         || p_current_row.payment_type_new);
            put_log_line(   '  Receipt Date      = '
                         || p_current_row.receipt_date);
            put_log_line(   '  I1025 Status      = '
                         || p_current_row.i1025_status);
            put_log_line(   '  amount_due_remaining = '
                         || p_current_row.amount_due_remaining);
            put_log_line();
        END IF;

        IF (gb_debug)
        THEN
            put_log_line('- Mapping done for Original receipts');
            put_log_line('- Set all the necessary references and flexfields on the receipt');
        END IF;

-- ==========================================================================
-- Assign receipt reference fields and DFFs
-- ==========================================================================
        xx_ar_prepayments_pkg.set_receipt_attr_references
                                                    (p_receipt_context =>                 'SALES_ACCT',
                                                     p_orig_sys_document_ref =>           p_current_row.orig_sys_document_ref,
                                                     p_receipt_method_id =>               p_current_row.receipt_method_id,
                                                     p_payment_type_code =>               p_current_row.payment_type_code,
                                                     p_check_number =>                    p_current_row.check_number,
                                                     p_paid_at_store_id =>                p_current_row.paid_at_store_id,
                                                     p_ship_from_org_id =>                p_current_row.ship_from_org_id,
                                                     p_cc_auth_manual =>                  p_current_row.cc_auth_manual,
                                                     p_cc_auth_ps2000 =>                  p_current_row.cc_auth_ps2000,
                                                     p_merchant_number =>                 p_current_row.merchant_number,
                                                     p_od_payment_type =>                 p_current_row.od_payment_type,
                                                     p_debit_card_approval_ref =>         p_current_row.debit_card_approval_ref,
                                                     p_cc_mask_number =>                  p_current_row.cc_mask_number,
                                                     p_payment_amount =>                  p_current_row.amount,
                                                     p_applied_customer_trx_id =>         p_current_row.customer_trx_id,
                                                     p_original_receipt_id =>             NULL,
                                                     p_transaction_number =>              p_current_row.transaction_number,
                                                     p_imp_file_name =>                   p_current_row.imp_file_name,
                                                     p_om_import_date =>                  p_current_row.om_import_date,
                                                     p_i1025_record_type =>               p_current_row.record_type,
                                                     p_called_from =>                     'I1025',
                                                     p_print_debug =>                     get_debug_char(),
                                                     x_receipt_number =>                  x_receipt_number,
                                                     x_receipt_comments =>                lc_receipt_comments,
                                                     x_customer_receipt_reference =>      lc_customer_receipt_reference,
                                                     x_attribute_rec =>                   x_attributes,
                                                     x_app_customer_reference =>          lc_app_customer_reference,
                                                     x_app_comments =>                    lc_app_comments,
                                                     x_app_attribute_rec =>               x_app_attributes,
                                                     x_receipt_ext_attributes =>          x_receipt_ext_attributes);

-- ==========================================================================
-- Call activity application to Write-off the deposit receipt
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('- Calling the activity application to Write-off the Multitender receipts');
        END IF;

        BEGIN
            SELECT amount_due_remaining
            INTO   ln_amount_recpt_bal
            FROM   ar_payment_schedules_all
            WHERE  cash_receipt_id = p_cash_receipt_id;
        EXCEPTION
            WHEN OTHERS
            THEN
                ln_amount_recpt_bal := NULL;
        END;

        ln_amount_recpt_bal_tot := ln_amount_recpt_bal;

        -- Following code added by gaurav on 10/21 defect 14563
        IF NVL(ln_amount_recpt_bal,
               0) <> 0
        THEN
            BEGIN
                SELECT single_pay_ind
                INTO   lc_single_pay_ind
                FROM   xx_om_legacy_deposits
                WHERE  cash_receipt_id = p_cash_receipt_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    lc_single_pay_ind := 'N';
            END;

            IF (gb_debug)
            THEN
                put_log_line(   '- lc_single_pay_ind :   '
                             || lc_single_pay_ind);
            END IF;

            IF lc_single_pay_ind = 'Y'
            THEN
                IF (gb_debug)
                THEN
                    put_log_line('Inside single pay LOGIC ');
                END IF;

                ln_amount_rev_bal :=   gn_amount_rcpt_bal
                                     * -1;
                put_log_line(   'p_cash_receipt_id : '
                             || p_cash_receipt_id);

                -- above code added by gaurav on 10/21
                --ln_amount_recpt_bal :=  p_current_row.amount; --added by guarav on 10/21/2011
                IF (gb_debug)
                THEN
                    put_log_line(   '-Amount To reverse '
                                 || ln_amount_rev_bal);
                END IF;

                -- added on 10/26 defect 14563
                IF (  -1
                    * ln_amount_recpt_bal_tot) >=(  -1
                                                  * ln_amount_rev_bal)
                THEN
                    gn_amount_rcpt_bal := 0;
                    ln_amount_recpt_bal := ln_amount_rev_bal;
                    l_prepay_appl_rec.amount_applied :=(    -1
                                                          * ln_amount_recpt_bal_tot
                                                        - (  -1
                                                           * ln_amount_rev_bal) );
                ELSE
                    gn_amount_rcpt_bal :=   (  -1
                                             * ln_amount_rev_bal)
                                          - (  -1
                                             * ln_amount_recpt_bal_tot);
                    ln_amount_recpt_bal := ln_amount_recpt_bal_tot;
                    l_prepay_appl_rec.amount_applied := 0;
                END IF;
            END IF;   --IF lc_single_pay_ind = 'Y'
        END IF;   --F NVL (ln_amount_recpt_bal, 0) <> 0

        -- above  added on 10/26  defect 14563
        IF ln_amount_recpt_bal <> 0
        THEN
            ar_receipt_api_pub.activity_application(p_api_version =>                       1.0,
                                                    p_init_msg_list =>                     fnd_api.g_true,
                                                    p_commit =>                            fnd_api.g_false,
                                                    p_validation_level =>                  fnd_api.g_valid_level_full,
                                                    x_return_status =>                     x_return_status,
                                                    x_msg_count =>                         x_msg_count,
                                                    x_msg_data =>                          x_msg_data,
                                                    p_cash_receipt_id =>                   p_cash_receipt_id,
                                                    p_amount_applied =>                    (  -1
                                                                                            * ln_amount_recpt_bal),
                                                    --x_cash_receipt_rec.amount,
                                                    p_apply_date =>                        SYSDATE,
                                                    p_applied_payment_schedule_id =>       -3,
                                                    --This is for Receipt Write-off
                                                    p_link_to_customer_trx_id =>           NULL,
                                                    p_receivables_trx_id =>                ln_receivables_trx_id,
                                                    p_comments =>                          'DEPOSIT : I1025 Refund Receipt Write-Off',
                                                    p_application_ref_type =>              x_application_ref_type,
                                                    p_application_ref_id =>                x_application_ref_id,
                                                    p_application_ref_num =>               x_application_ref_num,
                                                    p_secondary_application_ref_id =>      x_secondary_application_ref_id,
                                                    p_receivable_application_id =>         x_receivable_application_id,
                                                    p_payment_set_id =>                    x_payment_set_id,
                                                    p_attribute_rec =>                     x_app_attributes,
                                                    p_customer_reference =>                lc_app_customer_reference,
                                                    p_val_writeoff_limits_flag =>          'Y',
                                                    p_called_from =>                       'I1025');

            BEGIN
                UPDATE xx_om_legacy_deposits
                SET avail_balance =   avail_balance
                                    - (  -1
                                       * ln_amount_recpt_bal)
                WHERE  cash_receipt_id = p_cash_receipt_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    put_log_line
                        (   'Exception when calling update to xx_om_legacy_deposits after  ar_receipt_api_pub.activity_application  :  '
                         || SQLERRM);
            END;

            IF (gb_debug)
            THEN
                put_log_line(   '- Return Status: '
                             || x_return_status
                             || ', Msg Cnt: '
                             || x_msg_count);
            END IF;

            IF (x_return_status = 'S')
            THEN
                IF (gb_debug)
                THEN
                    put_log_line('Successfully applied Receipt Write-Off');
                    put_log_line(   '  x_receivable_application_id = '
                                 || x_receivable_application_id);
                END IF;

                put_log_line(   'lc_single_pay_ind   : '
                             || lc_single_pay_ind);
                put_log_line(   ' total ln_amount_recpt_bal = '
                             ||   -1
                                * ln_amount_recpt_bal_tot);
                put_log_line(   ' rev ln_amount_recpt_bal = '
                             || ln_amount_recpt_bal);
                put_log_line(   '  amount_applied = '
                             || (    -1
                                   * ln_amount_recpt_bal_tot
                                 - (  -1
                                    * ln_amount_recpt_bal) ) );

                -- following code added by gaurav on 10/24 -- defect 14563
                IF     (lc_single_pay_ind = 'Y')
                   AND (l_prepay_appl_rec.amount_applied <> 0)
                THEN
                    put_log_line('Calling  XX_AR_PREPAYMENTS_PKG.apply_prepayment_application for Singale payment ');
                    --l_prepay_appl_rec.amount_applied    := (-1 * ln_amount_recpt_bal_tot - (-1 * ln_amount_recpt_bal));
                    put_log_line(   'Amount Applied    : '
                                 || l_prepay_appl_rec.amount_applied);
                    xx_ar_prepayments_pkg.apply_prepayment_application(p_prepay_appl_row =>      l_prepay_appl_rec);
                END IF;
            -- Above code added by gaurav on 10/24  defect 14563
            ELSE
                raise_api_errors(p_sub_name =>       lc_sub_name,
                                 p_msg_count =>      x_msg_count,
                                 p_api_name =>       'AR_RECEIPT_API_PUB.activity_application');
            END IF;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END multi_deposit_rec_writeoff;

-- ==========================================================================
-- procedure to write-off an existing deposit receipt that has been
--   reversed (refunded to the customer) in Sales Accounting
--
-- known limitations:
--   1. if the original deposit receipt is not Remitted, then the refund
--        will error out, so that it can be resubmitted again later
--   2. if the deposit refund is credit card, and the credit card refunded
--        is different than the original deposit
-- ==========================================================================
    PROCEDURE writeoff_deposit_receipt(
        p_current_row       IN OUT NOCOPY  gt_current_record,
        x_cash_receipt_row  OUT NOCOPY     ar_cash_receipts%ROWTYPE,
        x_comments          OUT NOCOPY     VARCHAR2)
    IS
        lc_sub_name     CONSTANT VARCHAR2(50)                                             := 'WRITEOFF_DEPOSIT_RECEIPT';
        l_prepay_appl_rec        xx_ar_prepayments_pkg.gcu_prepay_appl%ROWTYPE;
        l_prepay_remain_rec      xx_ar_prepayments_pkg.gcu_prepay_appl%ROWTYPE;
        lc_application_ref_num   ar_receivable_applications_all.application_ref_num%TYPE;
        x_cash_receipt_rec       ar_cash_receipts%ROWTYPE;
        lb_manually_processed    BOOLEAN                                                   DEFAULT NULL;
        ln_manual_process_count  NUMBER                                                    DEFAULT NULL;
        ln_amount_due_rem        NUMBER                                                    DEFAULT 0;
        --Added for CR 722(Defect 6033)
        x_payment_set_id         ar_receivable_applications.payment_set_id%TYPE            DEFAULT NULL;
        --Added for CR 722(Defect 6033)
        lc_orig_tran_number      xx_om_legacy_dep_dtls.transaction_number%TYPE             DEFAULT NULL;
        -- added by Gaurav v2.0
        lc_single_pay_ind        VARCHAR2(1)                                               := 'N';
        lc_activity_name         ar_receivables_trx_all.NAME%TYPE                          := NULL;

        CURSOR lcu_deposit
                          --( cp_orig_sys_document_ref    IN    VARCHAR2)
        (
            cp_orig_sys_document_ref  IN  VARCHAR2,
            cp_orig_tran_num          IN  VARCHAR2)   -- added by Gaurav v2.0
        IS
            SELECT xold.ROWID,
                   acr.cash_receipt_id,
                   acr.receipt_number,
                   acr.receipt_date,
                   acr.status receipt_appl_status,
                   acr.amount,
                   acr.receipt_method_id,
                   acr.attribute13 i1025_process_code,
                   acrh.status receipt_status,
                   arm.NAME receipt_method,
                   aps.payment_schedule_id,
                   xold.payment_type_code,
                   xold.orig_sys_document_ref,
                   xold.credit_card_number,
                   xold.credit_card_holder_name,
                   xold.credit_card_expiration_date,
                   xold.credit_card_code,
                   xold.credit_card_approval_code,
                   xold.credit_card_approval_date,
                   xold.prepaid_amount,
                   xold.paid_at_store_id,
                     -1
                   * aps.amount_due_remaining amount_due_remaining,
                   acr.pay_from_customer pay_from_customer,   --Added for Defect# 1861
                   xold.IDENTIFIER
            FROM   xx_om_legacy_deposits xold,
                   ar_cash_receipts_all acr,
                   ar_cash_receipt_history_all acrh,
                   ar_receipt_methods arm,
                   ar_payment_schedules_all aps
            WHERE  xold.cash_receipt_id = acr.cash_receipt_id
            AND    acr.cash_receipt_id = acrh.cash_receipt_id
            AND    acr.cash_receipt_id = aps.cash_receipt_id
            AND    acr.receipt_method_id = arm.receipt_method_id
            AND    acrh.current_record_flag = 'Y'
            --AND acr.attribute_category = 'SALES_ACCT'
            --AND acr.attribute11 = 'SA_DEPOSIT'
            AND    aps.CLASS = 'PMT'
            --AND xold.avail_balance > 0   -- Added  by Gaurav on 10/20
              --AND aps.amount_due_remaining <> 0
            AND    xold.prepaid_amount > 0   -- only reverse regular deposit records
            AND    xold.process_code <> 'P'   -- only reverse completed deposit records (not pending)
            --AND xold.orig_sys_document_ref = cp_orig_sys_document_ref
            -- changes for CR #341
            AND    (    (xold.orig_sys_document_ref LIKE    SUBSTR(NVL(cp_orig_sys_document_ref,
                                                                       'x'),
                                                                   1,
                                                                   9)
                                                         || '%')
                    OR (xold.transaction_number = NVL(cp_orig_tran_num,
                                                      -1) )   -- added by Gaurav v2.0
                                                           );

        -- only use the first 9 digits of the AOPS order (ignore backorder/sub num)
        TYPE t_deposit_tab IS TABLE OF lcu_deposit%ROWTYPE
            INDEX BY PLS_INTEGER;

        l_deposit_tab            t_deposit_tab;

        CURSOR lcu_misc_receipt(
            cp_cash_receipt_id    IN  NUMBER,
            cp_pay_from_customer  IN  NUMBER   -- Added for Defect# 1861
                                            )
        IS
            SELECT cash_receipt_id misc_receipt_id,
                   receipt_number
            FROM   ar_cash_receipts_all
            WHERE  TYPE = 'MISC'
            AND    reference_type = 'RECEIPT'
            AND    reference_id = cp_cash_receipt_id
            AND    pay_from_customer = cp_pay_from_customer;   -- Added for the Defect# 1861

        l_misc_receipt           lcu_misc_receipt%ROWTYPE;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
            put_log_line(   '  Legacy Order Number = '
                         || p_current_row.orig_sys_document_ref);
        END IF;

         -- added by Gaurav v2.0
         --  If condition commnented by Gaurav Agarwal V2.0
        -- IF p_current_row.orig_sys_document_ref IS NULL THEN
        BEGIN
            SELECT xoldd2.transaction_number,
                   xoldd2.single_pay_ind
            INTO   lc_orig_tran_number,
                   lc_single_pay_ind
            FROM   xx_om_legacy_deposits xold, xx_om_legacy_dep_dtls xoldd1, xx_om_legacy_dep_dtls xoldd2
            WHERE  1 = 1
            AND    xold.transaction_number = p_current_row.transaction_number
            AND    xold.transaction_number = xoldd1.transaction_number
            AND    SUBSTR(xoldd1.orig_sys_document_ref,
                          1,
                          9) = SUBSTR(xoldd2.orig_sys_document_ref,
                                      1,
                                      9)
            AND    xoldd1.transaction_number != xoldd2.transaction_number
            AND    ROWNUM = 1;

            put_log_line(   '  lc_orig_tran_number = '
                         || lc_orig_tran_number);
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_orig_tran_number := NULL;
        END;

--  END IF; condition commnented by Gaurav Agarwal V2.0
  -- added by Gaurav v2.0
  -- ==========================================================================
  -- get the deposit record to reverse
  -- ==========================================================================
        put_log_line(   lc_sub_name
                     || '  orig_sys_document_ref  = '
                     || p_current_row.orig_sys_document_ref);
        put_log_line(   lc_sub_name
                     || '  lc_orig_tran_number    = '
                     || lc_orig_tran_number);

        OPEN lcu_deposit(cp_orig_sys_document_ref =>      p_current_row.orig_sys_document_ref,
                         cp_orig_tran_num =>              lc_orig_tran_number);

        FETCH lcu_deposit
        BULK COLLECT INTO l_deposit_tab;

        CLOSE lcu_deposit;

        IF (gb_debug)
        THEN
            put_log_line(   ' # Number of original deposit receipts found = '
                         || l_deposit_tab.COUNT);
        END IF;

-- ==========================================================================
-- check to see if the deposit receipt was already manually reversed
-- ==========================================================================
        IF (l_deposit_tab.COUNT > 1)
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Check to see if the deposit receipt[s] were already manually reversed. ');
            END IF;

            ln_manual_process_count := 0;

-- ==========================================================================
-- loop through the original deposit receipt records
-- ==========================================================================
            FOR i_index IN l_deposit_tab.FIRST .. l_deposit_tab.LAST
            LOOP
                IF (gb_debug)
                THEN
                    put_log_line(   '======== Record #'
                                 || i_index
                                 || ' ======== ');
                    put_log_line(   ' Deposit Receipt : '
                                 || l_deposit_tab(i_index).receipt_number);
                    put_log_line(   ' I1025 Process   : '
                                 || l_deposit_tab(i_index).i1025_process_code);
                    put_log_line(   ' Deposit Amount  : '
                                 || l_deposit_tab(i_index).prepaid_amount);
                    put_log_line(   ' Amt Remaining   : '
                                 || l_deposit_tab(i_index).amount_due_remaining);
                END IF;

-- ==========================================================================
-- Adding a list of the original deposit receipts to the Output Comments field
-- ==========================================================================
                IF (i_index = 1)
                THEN
                    x_comments :=
                            x_comments
                         || CHR(10)
                         || '        Deposit Receipts:  '
                         || l_deposit_tab(i_index).receipt_number;
                ELSE
                    x_comments :=    x_comments
                                  || ', '
                                  || l_deposit_tab(i_index).receipt_number;
                END IF;

                IF (UPPER(l_deposit_tab(i_index).i1025_process_code) LIKE 'MANUAL%')
                THEN
                    IF (gb_debug)
                    THEN
                        put_log_line('* This deposit receipt has been flagged as manually processed. ');
                    END IF;

-- ==========================================================================
-- if the order exists only in Sales Accounting, then insert the CC
--   deposits into this iPayment custom table, so that the level-3 line
--   data can be interfaced (since the order does not yet exist in OM)
-- ==========================================================================
                    IF (p_current_row.payment_type_new = 'CREDIT_CARD')
                    THEN
-- ==========================================================================
-- use the misc receipt number on the Credit Card Refund when inserting into
--  the deposit aops orders table for iPayment - for line level-3 details
--  - defect #5799
-- ==========================================================================
                        OPEN lcu_misc_receipt(cp_cash_receipt_id =>        l_deposit_tab(i_index).cash_receipt_id,
                                              cp_pay_from_customer =>      l_deposit_tab(i_index).pay_from_customer
                                                                                                                   -- Added for the Defect# 1861
                                             );

                        FETCH lcu_misc_receipt
                        INTO  l_misc_receipt;

                        CLOSE lcu_misc_receipt;

                        IF (gb_debug)
                        THEN
                            put_log_line('Found the Misc Receipt referencing this Cash Receipt.');
                            put_log_line(   ' Misc Receipt Id  = '
                                         || l_misc_receipt.misc_receipt_id);
                            put_log_line(   ' Misc Receipt Num = '
                                         || l_misc_receipt.receipt_number);
                        END IF;

                        insert_iby_deposit_aops_orders(p_aops_order_number =>      p_current_row.orig_sys_document_ref,
                                                       p_receipt_number =>         NVL
                                                                                       (l_misc_receipt.receipt_number,
                                                                                        l_deposit_tab(i_index).receipt_number),
                                                       p_tran_number =>            p_current_row.transaction_number);
                    END IF;

                    lb_manually_processed := TRUE;
                    ln_manual_process_count :=   ln_manual_process_count
                                               + 1;
                ELSE
                    IF (gb_debug)
                    THEN
                        put_log_line('* This deposit receipt has NOT been manually processed. ');
                        put_log_line
                             ('  If it has been manually refunded, then update the "I1025 Process Status" to "MANUAL" ');
                    END IF;
                END IF;

                IF (gb_debug)
                THEN
                    put_log_line();
                END IF;
            END LOOP;

-- ==========================================================================
-- if mailcheck, then print mailcheck refund info (if available)
-- ==========================================================================
            IF (p_current_row.payment_type_new = 'MAILCHECK')
            THEN
                add_mailcheck_details(p_orig_sys_document_ref =>      p_current_row.orig_sys_document_ref,
                                      x_comments =>                   x_comments);
            END IF;

-- ==========================================================================
-- if one of the original deposits was flagged as manual
-- ==========================================================================
            IF (lb_manually_processed)
            THEN
                IF (gb_debug)
                THEN
                    put_log_line('At least one of the deposit receipts has been flagged as manual.');
                    put_log_line(   ' Deposit Receipt Count = '
                                 || l_deposit_tab.COUNT);
                    put_log_line(   ' Manual Receipt Count  = '
                                 || ln_manual_process_count);
                END IF;

                IF (ln_manual_process_count = l_deposit_tab.COUNT)
                THEN
                    IF (gb_debug)
                    THEN
                        put_log_line('All Receipts have been Manually processed.');
                    END IF;

                    fnd_message.set_name('XXFIN',
                                         'XX_AR_I1025_20103_MAN_DEP_REV');
                    add_message(p_current_row =>         p_current_row,
                                p_message_code =>        'MANUALLY_PROCESSED',
                                p_message_text =>        fnd_message.get(),
                                p_error_location =>      lc_sub_name,
                                p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_info);
                ELSE
                    fnd_message.set_name('XXFIN',
                                         'XX_AR_I1025_20007_NOT_MANUAL');
                    fnd_message.set_token('SUB_NAME',
                                          lc_sub_name);
                    raise_application_error(-20007,
                                            fnd_message.get() );
                END IF;

-- ==========================================================================
-- update deposit as manually reversed (voided)
-- ==========================================================================
                update_deposit_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                             p_i1025_status =>      'MANUAL_REVERSE');
-- ==========================================================================
-- Add comment to program output
-- ==========================================================================
                x_comments :=    'MANUALLY PROCESSED - '
                              || x_comments;
-- ==========================================================================
-- return since this deposit reversal was already manually processed
-- ==========================================================================
                RETURN;
            END IF;
        END IF;

-- ==========================================================================
-- check to see that a single deposit record was found
-- ==========================================================================
        IF (l_deposit_tab.COUNT < 1)
        THEN
            fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20008_NO_DEPOSIT_R');
            fnd_message.set_token('SUB_NAME',
                                  lc_sub_name);
            raise_application_error(-20008,
                                    fnd_message.get() );
        ELSIF(l_deposit_tab.COUNT > 1)
        THEN
-- ===============================================================
-- -------------Start of Changes For CR 722(Defect 6033)-----------------------
-- ===============================================================
-- ----------------------------------------------------------------
-- Calling create_multitender_deposit_ref Procedure for CR 722(Defect 6033)  ---
-- ----------------------------------------------------------------
            IF (gb_debug)
            THEN
                put_log_line(' Multitender Deposit Receipts Found  ');
                put_log_line(   ' Deposit Receipt Count = '
                             || l_deposit_tab.COUNT);
            END IF;

            create_multitender_deposit_ref(p_current_row =>           p_current_row,
                                           x_cash_receipt_row =>      x_cash_receipt_row);

            IF (gb_debug)
            THEN
                put_log_line(' Multitender Deposit Refund Process Completed  ');
            END IF;

-- ----------------------------------------------------------------
-- Writeoff multi_Tender Original Receipts for CR 722(Defect 6033)
-- ----------------------------------------------------------------
            SAVEPOINT before_writeoff_multi_dep_ref;

            IF (gb_debug)
            THEN
                put_log_line(' ');
                put_log_line('Writeoff Multi_Tender Original Receipts...');
            END IF;

            BEGIN
                FOR i_index IN l_deposit_tab.FIRST .. l_deposit_tab.LAST
                LOOP
                    ----- Multitender Deposit Receipts -------
                    IF (gb_debug)
                    THEN
                        put_log_line(   '======== Record #'
                                     || i_index
                                     || ' ======== ');
                        put_log_line(   ' Deposit Receipt : '
                                     || l_deposit_tab(i_index).receipt_number);
                        put_log_line(   ' Amt Remaining   : '
                                     || l_deposit_tab(i_index).amount_due_remaining);
                    END IF;

                    ln_amount_due_rem :=   ln_amount_due_rem
                                         + l_deposit_tab(i_index).amount_due_remaining;
                END LOOP;

                gn_amount_rcpt_bal :=   -1
                                      * p_current_row.amount;

                IF (gb_debug)
                THEN
                    put_log_line(' ');
                    put_log_line(   ' Total Amt Remaining   : '
                                 || ln_amount_due_rem);
                    put_log_line(   ' Deposit Refund Amount : '
                                 || p_current_row.amount);
                END IF;

                -- IF (ABS(ln_amount_due_rem) <> ABS(p_current_row.amount)) THEN -- Commented BY GAURAV ON 10/20/11
                IF (ABS(ln_amount_due_rem) < ABS(p_current_row.amount) )
                THEN   -- ADDED BY GAURAV ON 10/20/11
                    put_log_line
                        ('Deposit refund amount is Not Equal to the Original Deposit Amount of Multitender Deposit Receipts and cannot be Written-Off. Please Process Manually');
                    fnd_message.set_name('XXFIN',
                                         'XX_AR_I1025_20010_DPST_NE_REF');
                    fnd_message.set_token('SUB_NAME',
                                          lc_sub_name);
                    fnd_message.set_token('DEPOSIT_REFUND_AMOUNT',
                                          p_current_row.amount);
                    fnd_message.set_token('ORG_RECPT_BAL_AMOUNT',
                                          ln_amount_due_rem);
                    add_message(p_current_row =>         p_current_row,
                                p_message_code =>        'TO_BE_MANUALLY_PROCESSED',
                                p_message_text =>        fnd_message.get(),
                                p_error_location =>      lc_sub_name,
                                p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_warning);
                    x_comments :=
                           x_comments
                        || CHR(10)
                        || ' Unable to Write Off the Original Deposit Receipts. Refund Amount and Original Receipt Amount Not Matching. - Please Process Manually';
                ELSE
                    FOR i_index IN l_deposit_tab.FIRST .. l_deposit_tab.LAST
                    LOOP
                        IF (gb_debug)
                        THEN
                            put_log_line(   'Writing Off Multi Tender Deopsit Receipt '
                                         || l_deposit_tab(i_index).cash_receipt_id);
                        END IF;

                        IF (gb_debug)
                        THEN
                            put_log_line(   'GN_AMOUNT_RCPT_BAL  :  '
                                         || gn_amount_rcpt_bal);
                        END IF;

                        IF     gn_amount_rcpt_bal = 0
                           AND lc_single_pay_ind = 'Y'
                        THEN
                            EXIT;
                        END IF;

                        multi_deposit_rec_writeoff(p_cash_receipt_id =>      l_deposit_tab(i_index).cash_receipt_id,
                                                   p_current_row =>          p_current_row);
                    END LOOP;
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    IF (gb_debug)
                    THEN
                        put_log_line(   '*ERROR - '
                                     || SQLERRM);
                    END IF;

                    ROLLBACK TO SAVEPOINT before_writeoff_multi_dep_ref;
                    fnd_message.set_name('XXFIN',
                                         'XX_AR_I1025_20010_DPST_NA_REF');
                    fnd_message.set_token('SUB_NAME',
                                          lc_sub_name);
                    add_message(p_current_row =>         p_current_row,
                                p_message_code =>        'TO_BE_MANUALLY_PROCESSED',
                                p_message_text =>        fnd_message.get(),
                                p_error_location =>      lc_sub_name,
                                p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_warning);
                    x_comments :=
                           x_comments
                        || CHR(10)
                        || ' Unable to Write Off the Original Deposit Receipts. Error Occured - Please Process Manually';
            END;

            RETURN;
-- ===============================================================
-- -------------  End of Changes For CR 722(Defect 6033) ------------------- --
-- ===============================================================
------------------------------------------------------
---- Commented for CR 722(Defect 6033) -----
------------------------------------------------------
/*
FND_MESSAGE.set_name('XXFIN','XX_AR_I1025_20009_DPST_MLT_TND');
FND_MESSAGE.set_token('SUB_NAME',lc_sub_name);
RAISE_APPLICATION_ERROR(-20009, FND_MESSAGE.get() );
*/
        END IF;

        x_cash_receipt_rec.cash_receipt_id := l_deposit_tab(1).cash_receipt_id;
-- ==========================================================================
-- update the deposit refund with the cash receipt from the original
--   deposit payment - used by E0055 Mail Checks and I0349 iPayment to get
--   receipt information - change for CR #341
-- ==========================================================================
        update_deposit_refund_cr_id(p_rowid =>                p_current_row.xx_payment_rowid,
                                    p_cash_receipt_id =>      l_deposit_tab(1).cash_receipt_id);
-- ==========================================================================
-- set the original receipt date of the current record to the receipt date
--   of the original deposit receipt
-- ==========================================================================
        p_current_row.original_receipt_date := l_deposit_tab(1).receipt_date;
-- ==========================================================================
-- fetch the latest AR receipt with a lock
-- ==========================================================================
        arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec =>      x_cash_receipt_rec);

        IF (gb_debug)
        THEN
            put_log_line('- Fetched and Locked Receipt: ');
            put_log_line(   '  cash receipt id = '
                         || x_cash_receipt_rec.cash_receipt_id);
            put_log_line(   '  receipt number  = '
                         || x_cash_receipt_rec.receipt_number);
            put_log_line('Deposit Reversal information: ');
            put_log_line(   '  Cash Receipt Id = '
                         || l_deposit_tab(1).cash_receipt_id);
            put_log_line(   '  Receipt Number  = '
                         || l_deposit_tab(1).receipt_number);
            put_log_line(   '  Refund Amount   = '
                         || TO_CHAR(  -1
                                    * p_current_row.amount) );
            put_log_line(   '  Refund Date     = '
                         || p_current_row.receipt_date);
            put_log_line(   '  Receipt Date    = '
                         || p_current_row.original_receipt_date);
            put_log_line(   '  Receipt Status  = '
                         || l_deposit_tab(1).receipt_status);
            put_log_line(   '  Receipt Amount  = '
                         || l_deposit_tab(1).amount);
            put_log_line(   '  Orig Unapplied Amt = '
                         || l_deposit_tab(1).amount_due_remaining);
        END IF;

        x_cash_receipt_row := x_cash_receipt_rec;

-- ==========================================================================
-- if the deposit refund amount is greater than the original deposit, raise
--   an error since we cannot refund it
-- ==========================================================================
        IF (  -1
            * p_current_row.amount > l_deposit_tab(1).amount_due_remaining)
        THEN
            fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20010_DPST_OVR_REF');
            fnd_message.set_token('SUB_NAME',
                                  lc_sub_name);
            raise_application_error(-20010,
                                    fnd_message.get() );
        END IF;

-- ==========================================================================
-- fetch the recv application for the prepayment
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('Fetching Prepayment: ');
        END IF;

        -- Following Code added by Gaurav on 8/8/2011
        BEGIN
            lc_application_ref_num := NULL;

            SELECT raa.application_ref_num
            INTO   lc_application_ref_num
            FROM   ar_receivable_applications_all raa
            WHERE  cash_receipt_id = l_deposit_tab(1).cash_receipt_id
            AND    raa.status = 'OTHER ACC'
            AND    raa.display = 'Y'
            AND    ROWNUM = 1;
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_application_ref_num := NULL;
        END;

        --  Ends here.
        -- l_prepay_appl_rec                               := XX_AR_PREPAYMENTS_PKG.get_prepay_application_record ( p_cash_receipt_id => l_deposit_tab(1).cash_receipt_id ,p_reference_type => '%' ,p_reference_number => SUBSTR(p_current_row.orig_sys_document_ref ,1 ,9) || '%' );
        l_prepay_appl_rec :=
            xx_ar_prepayments_pkg.get_prepay_application_record(p_cash_receipt_id =>       l_deposit_tab(1).cash_receipt_id,
                                                                p_reference_type =>        '%',
                                                                p_reference_number =>         lc_application_ref_num
                                                                                           || '%');

        IF (l_prepay_appl_rec.receivable_application_id IS NOT NULL)
        THEN
            IF (gb_debug)
            THEN
                put_log_line(   '  recv appl id  = '
                             || l_prepay_appl_rec.receivable_application_id);
                put_log_line(   '  appl ref type = '
                             || l_prepay_appl_rec.application_ref_type);
                put_log_line(   '  appl ref num  = '
                             || l_prepay_appl_rec.application_ref_num);
                put_log_line(   '  prepay amount = '
                             || l_prepay_appl_rec.amount_applied);
            END IF;

-- ==========================================================================
-- unapply the prepayment application
-- ==========================================================================
            xx_ar_prepayments_pkg.unapply_prepayment_application(p_prepay_appl_row =>      l_prepay_appl_rec);
        ELSE
            IF (gb_debug)
            THEN
                put_log_line('- No Prepayment Application could be found.');
            END IF;

            fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20104_NO_PREPAY_AP');
            add_message(p_current_row =>         p_current_row,
                        p_message_code =>        'NO_DEPOSIT_PREPAYMENT',
                        p_message_text =>        fnd_message.get(),
                        p_error_location =>      lc_sub_name,
                        p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_warning);
        END IF;

-- ==========================================================================
-- if mailcheck, then don't write-off the receipt
-- ==========================================================================
        IF (p_current_row.payment_type_new = 'MAILCHECK')
        THEN
-- ==========================================================================
-- set the I1025 process code to "On-Hold" so that E0055 AR Automated
--   Refund can process it further
-- ==========================================================================
            set_i1025_process_code(x_cash_receipt_rec =>        x_cash_receipt_rec,
                                   p_i1025_process_code =>      'ON_HOLD');
            update_deposit_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                         p_i1025_status =>      'MAILCHECK_HOLD');
--======================================================================================
-- V2.0 Included below procedure.
-- If payment type id MAILCHECK then we are going to Writeoff the receipt-- Start
--======================================================================================
            writeoff_receipt(x_cash_receipt_rec =>      x_cash_receipt_rec,
                             p_current_row =>           p_current_row);

            -- V2.0   -- End

            -- code added on 11/01
            IF     (lc_single_pay_ind = 'Y')
               AND (l_deposit_tab(1).amount_due_remaining >   -1
                                                            * p_current_row.amount)
            THEN
                l_prepay_appl_rec.amount_applied :=   l_deposit_tab(1).amount_due_remaining
                                                    - (  -1
                                                       * p_current_row.amount);
                put_log_line('Calling  XX_AR_PREPAYMENTS_PKG.apply_prepayment_application for Singale payment ');
                put_log_line(   'Amount Applied    : '
                             || l_prepay_appl_rec.amount_applied);
                xx_ar_prepayments_pkg.apply_prepayment_application(p_prepay_appl_row =>      l_prepay_appl_rec);
            END IF;
        -- code added on 11/01
        ELSE
-- ==========================================================================
-- if credit card, check if it matches the original
-- ==========================================================================
            IF (p_current_row.payment_type_new IN('CREDIT_CARD', 'DEBIT_CARD') )
            THEN
-- ==========================================================================
-- does credit card match on refund deposit and original deposit?
-- ==========================================================================
                IF (    p_current_row.payment_type_code = l_deposit_tab(1).payment_type_code
                    AND p_current_row.receipt_method = l_deposit_tab(1).receipt_method
                    AND p_current_row.credit_card_code = l_deposit_tab(1).credit_card_code)
                THEN
                    IF (encrypted_credit_cards_match(p_credit_card_number_enc_1 =>      p_current_row.credit_card_number,
                                                     p_identifier_1 =>                  p_current_row.IDENTIFIER,
                                                     p_credit_card_number_enc_2 =>      l_deposit_tab(1).credit_card_number,
                                                     p_identifier_2 =>                  l_deposit_tab(1).IDENTIFIER) )
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line(   '- This is a credit card or debit card deposit reversal, and the card'
                                         || ' number matches the original card used for the deposit.');
                        END IF;

                        IF (l_deposit_tab(1).receipt_status <> 'CONFIRMED')
                        THEN
                            IF (gb_debug)
                            THEN
                                put_log_line('- Original deposit receipt status is "Remitted".');
                            END IF;

-- ==========================================================================
-- pass receipt info through current row to refund
-- ==========================================================================
                            p_current_row.cash_receipt_id := l_deposit_tab(1).cash_receipt_id;

                            IF (p_current_row.paid_at_store_id IS NULL)
                            THEN
                                p_current_row.paid_at_store_id := l_deposit_tab(1).paid_at_store_id;
                            END IF;

                            IF (p_current_row.paid_at_store_id IS NULL)
                            THEN
                                raise_missing_param_errors(p_sub_name =>        lc_sub_name,
                                                           p_param_name =>      'Sale Location (PAID_AT_STORE_ID)');
                            END IF;

                            IF (p_current_row.payment_type_new = 'CREDIT_CARD')
                            THEN
-- ----------------------------------------------------------------
-- Calling create_multitender_deposit_ref Procedure for CR 722(Defect 6033)  ---
-- ----------------------------------------------------------------
                                IF (gb_debug)
                                THEN
                                    put_log_line(' Credit Card Deposit Cancellation  ');
                                END IF;

                                create_credit_card_deposit_ref(p_current_row =>           p_current_row,
                                                               x_cash_receipt_row =>      x_cash_receipt_row);
                            END IF;

                            IF (gb_debug)
                            THEN
                                put_log_line('    Use the custom credit/debit card refund writeoff activity.');
                            END IF;

                            IF (p_current_row.payment_type_new IN('CREDIT_CARD') )
                            THEN
                                lc_activity_name := get_cc_deposit_writeoff_act(p_org_id =>      p_current_row.org_id);
                            END IF;

                            IF (gb_debug)
                            THEN
                                IF (lc_activity_name IS NULL)
                                THEN
                                    put_log_line('    Use the custom credit/debit card refund writeoff activity.');
                                ELSE
                                    put_log_line('    Use the ' || lc_activity_name || ' refund writeoff activity.');
                                END IF;
                                
                            END IF;

                            writeoff_receipt(x_cash_receipt_rec =>      x_cash_receipt_rec,
                                             p_current_row =>           p_current_row,
                                             p_activity_name =>         lc_activity_name);
                        ELSE
                            IF (gb_debug)
                            THEN
                                put_log_line('- Original deposit receipt status is NOT "Remitted".');
                            END IF;

                            fnd_message.set_name('XXFIN',
                                                 'XX_AR_I1025_20011_NOT_REMITTED');
                            fnd_message.set_token('SUB_NAME',
                                                  lc_sub_name);
                            raise_application_error(-20011,
                                                    fnd_message.get() );
                        END IF;
                    ELSE
                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20012_DIFF_CR_CARD');
                        fnd_message.set_token('SUB_NAME',
                                              lc_sub_name);
                        raise_application_error(-20012,
                                                fnd_message.get() );
                    END IF;
                ELSE
                    fnd_message.set_name('XXFIN',
                                         'XX_AR_I1025_20012_DIFF_CR_CARD');
                    fnd_message.set_token('SUB_NAME',
                                          lc_sub_name);
                    raise_application_error(-20012,
                                            fnd_message.get() );
                END IF;
            ELSE
-- ==========================================================================
-- any other payment method, write off the receipt with the corresponding
--   refund write-off activity
-- ==========================================================================
                writeoff_receipt(x_cash_receipt_rec =>      x_cash_receipt_rec,
                                 p_current_row =>           p_current_row);
            END IF;

-- ==========================================================================
-- if the order exists only in Sales Accounting, then insert the CC
--   deposits into this iPayment custom table, so that the level-3 line
--   data can be interfaced (since the order does not yet exist in OM)
--     defect #4381
-- ==========================================================================
            IF (p_current_row.payment_type_new = 'CREDIT_CARD')
            THEN
-- ==========================================================================
-- use the misc receipt number on the Credit Card Refund when inserting into
--  the deposit aops orders table for iPayment - for line level-3 details
--  - defect #5799
-- ==========================================================================
                OPEN lcu_misc_receipt(cp_cash_receipt_id =>        l_deposit_tab(1).cash_receipt_id,
                                      cp_pay_from_customer =>      l_deposit_tab(1).pay_from_customer
                                                                                                     -- Added for the Defect# 1861
                                     );

                FETCH lcu_misc_receipt
                INTO  l_misc_receipt;

                CLOSE lcu_misc_receipt;

                IF (gb_debug)
                THEN
                    put_log_line('Found the Misc Receipt referencing this Cash Receipt.');
                    put_log_line(   ' Misc Receipt Id  = '
                                 || l_misc_receipt.misc_receipt_id);
                    put_log_line(   ' Misc Receipt Num = '
                                 || l_misc_receipt.receipt_number);
                END IF;

                insert_iby_deposit_aops_orders(p_aops_order_number =>      p_current_row.orig_sys_document_ref,
                                               p_receipt_number =>         NVL(l_misc_receipt.receipt_number,
                                                                               l_deposit_tab(1).receipt_number),
                                               p_tran_number =>            p_current_row.transaction_number);
            END IF;

-- ==========================================================================
-- re-fetch the latest AR receipt
-- ==========================================================================
            arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec =>      x_cash_receipt_rec);

            IF (gb_debug)
            THEN
                put_log_line('- Fetched and Locked Receipt: ');
                put_log_line(   '  cash receipt id = '
                             || x_cash_receipt_rec.cash_receipt_id);
                put_log_line(   '  receipt number  = '
                             || x_cash_receipt_rec.receipt_number);
            END IF;

-- ==========================================================================
-- reapply the difference back to the old reference
-- ==========================================================================
            l_prepay_remain_rec := l_prepay_appl_rec;
            l_prepay_remain_rec.amount_applied :=   l_deposit_tab(1).amount_due_remaining
                                                  - (  -1
                                                     * p_current_row.amount);

-- ==========================================================================
-- reapply remainder back to prepayment if it exists, otherwise update
--   receipt as cancelled
-- ==========================================================================
            IF (l_prepay_remain_rec.amount_applied > 0)
            THEN
                xx_ar_prepayments_pkg.apply_prepayment_application(p_prepay_appl_row =>      l_prepay_remain_rec);
                fnd_message.set_name('XXFIN',
                                     'XX_AR_I1025_20105_REMAIN_PREPA');
                add_message(p_current_row =>         p_current_row,
                            p_message_code =>        'REMAINING_DEPOSIT_PREPAYMENT',
                            p_message_text =>        fnd_message.get(),
                            p_error_location =>      lc_sub_name,
                            p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_warning);
            ELSE
                set_i1025_process_code(x_cash_receipt_rec =>        x_cash_receipt_rec,
                                       p_i1025_process_code =>      'CANCELLED');
                update_deposit_i1025_process(p_rowid =>             l_deposit_tab(1).ROWID,
                                             p_i1025_status =>      'CANCELLED');
            END IF;

            update_deposit_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                         p_i1025_status =>      'CANCELLED');
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- using this api will create an ar prepayment
--   the api creates a cash receipt for the given receipt method (i.e. cash, check, cc, etc.)
--   the customer bank account number is the credit card number, the arp_bank_pkg.process_cust_bank_account
--     api is responsible for creating the customer bank account based on the encrypted credit card
--     number reference
-- ==========================================================================
    PROCEDURE create_prepay_receipt(
        p_current_row       IN OUT NOCOPY  gt_current_record,
        p_invoice_exists    IN             VARCHAR2,
        x_payment_set_id    IN OUT NOCOPY  NUMBER,
        x_cash_receipt_rec  IN OUT NOCOPY  ar_cash_receipts%ROWTYPE)
    IS
        lc_sub_name           CONSTANT VARCHAR2(50)                                         := 'CREATE_PREPAY_RECEIPT';
        x_return_status                VARCHAR2(20)                                         DEFAULT NULL;
        x_msg_count                    NUMBER                                               DEFAULT NULL;
        x_msg_data                     VARCHAR2(4000)                                       DEFAULT NULL;
        x_cash_receipt_id              ar_cash_receipts.cash_receipt_id%TYPE                DEFAULT NULL;
        x_receipt_number               ar_cash_receipts.receipt_number%TYPE                 DEFAULT NULL;
        lc_receipt_comments            ar_cash_receipts.comments%TYPE                       DEFAULT NULL;
        lc_customer_receipt_reference  ar_cash_receipts.customer_receipt_reference%TYPE     DEFAULT NULL;
        lc_app_customer_reference      ar_receivable_applications.customer_reference%TYPE   DEFAULT NULL;
        lc_app_comments                ar_receivable_applications.comments%TYPE             DEFAULT NULL;
        x_attributes                   ar_receipt_api_pub.attribute_rec_type;
        x_app_attributes               ar_receipt_api_pub.attribute_rec_type;
        l_receipt_ext_attributes       xx_ar_cash_receipts_ext%ROWTYPE;
        x_payment_response_error_code  VARCHAR2(80)                                         DEFAULT NULL;
        l_customer_rec                 gcu_customer_id%ROWTYPE;
        ln_ord_cnt                     NUMBER;
        lc_attribute7                  VARCHAR2(4000)                                       DEFAULT NULL;

-- ==========================================================================
--V2.0 -- Start
        CURSOR c_dep_rcpt
        IS
            SELECT xoldd.orig_sys_document_ref
            FROM   xx_om_legacy_dep_dtls xoldd
            WHERE  xoldd.transaction_number = p_current_row.transaction_number;
--V2.0 -- End
-- ==========================================================================
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- validate the customer account is defined
-- ==========================================================================
        IF (p_current_row.bill_to_customer_id IS NULL)
        THEN
            raise_missing_param_errors(p_sub_name =>        lc_sub_name,
                                       p_param_name =>      'Customer Account (SOLD_TO_ORG_ID)');
        END IF;

-- ==========================================================================
-- get primary bill-to customer information
-- ==========================================================================
        l_customer_rec :=
            get_bill_customer_by_id(p_org_id =>               p_current_row.org_id,
                                    p_cust_account_id =>      p_current_row.bill_to_customer_id);
-- ==========================================================================
-- assign receipt reference fields and DFFs
-- ==========================================================================
        xx_ar_prepayments_pkg.set_receipt_attr_references
                                                    (p_receipt_context =>                 'SALES_ACCT',
                                                     p_orig_sys_document_ref =>           p_current_row.orig_sys_document_ref,
                                                     p_receipt_method_id =>               p_current_row.receipt_method_id,
                                                     p_payment_type_code =>               p_current_row.payment_type_code,
                                                     p_check_number =>                    p_current_row.check_number,
                                                     p_paid_at_store_id =>                p_current_row.paid_at_store_id,
                                                     p_ship_from_org_id =>                p_current_row.ship_from_org_id,
                                                     p_cc_auth_manual =>                  p_current_row.cc_auth_manual,
                                                     p_cc_auth_ps2000 =>                  p_current_row.cc_auth_ps2000,
                                                     p_merchant_number =>                 p_current_row.merchant_number,
                                                     p_od_payment_type =>                 p_current_row.od_payment_type,
                                                     p_debit_card_approval_ref =>         p_current_row.debit_card_approval_ref,
                                                     p_cc_mask_number =>                  p_current_row.cc_mask_number,
                                                     p_payment_amount =>                  p_current_row.amount,
                                                     p_applied_customer_trx_id =>         p_current_row.customer_trx_id,
                                                     p_original_receipt_id =>             NULL,
                                                     p_transaction_number =>              p_current_row.transaction_number,
                                                     p_imp_file_name =>                   p_current_row.imp_file_name,
                                                     p_om_import_date =>                  p_current_row.om_import_date,
                                                     p_i1025_record_type =>               p_current_row.record_type,
                                                     p_called_from =>                     'I1025',
                                                     p_print_debug =>                     get_debug_char(),
                                                     x_receipt_number =>                  x_receipt_number,
                                                     x_receipt_comments =>                lc_receipt_comments,
                                                     x_customer_receipt_reference =>      lc_customer_receipt_reference,
                                                     x_attribute_rec =>                   x_attributes,
                                                     x_app_customer_reference =>          lc_app_customer_reference,
                                                     x_app_comments =>                    lc_app_comments,
                                                     x_app_attribute_rec =>               x_app_attributes,
                                                     x_receipt_ext_attributes =>          l_receipt_ext_attributes);
-- ==========================================================================
-- assign receipt reference fields and DFFs specific to I1025
-- ==========================================================================
-- Payment Source
        x_attributes.attribute11 := 'SA_DEPOSIT';
        -- Order Header ID - not available for deposits
        --x_attributes.attribute12  := TO_CHAR(p_current_row.header_id);
        -- I1025 Process Code
        x_attributes.attribute13 :=    'CREATED|'
                                    || TO_CHAR(SYSDATE,
                                               'YYYY/MM/DD HH24:MI:SS');
        lc_receipt_comments := 'I1025 Create Deposit Receipt (with Prepayment to SA Order)';

-- ==========================================================================
-- set additional receipt information for prepayment
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line(' Set additional receipt information... ');
            put_log_line();
        END IF;

        l_receipt_ext_attributes.cc_entry_mode := p_current_row.cc_entry_mode;
        l_receipt_ext_attributes.cvv_resp_code := p_current_row.cvv_resp_code;
        l_receipt_ext_attributes.avs_resp_code := p_current_row.avs_resp_code;
        l_receipt_ext_attributes.auth_entry_mode := p_current_row.auth_entry_mode;

-- ==========================================================================
-- create pre-payment which creates an AR receipt with a prepay application
-- ==========================================================================
-- added by Gaurav v2.0
        IF p_current_row.single_pay_ind = 'Y'
        THEN
            lc_receipt_comments := 'I1025 Create Deposit Receipt (Single Payment for POS )';
            x_attributes.attribute7 := NULL;
            lc_attribute7 := NULL;   -- Added for QC Defect 24032

            FOR i IN c_dep_rcpt
            LOOP
                --x_attributes.attribute7 := x_attributes.attribute7 ||'-' ||i.orig_sys_document_ref; -- Commented for QC Defect 24032
                lc_attribute7 :=    lc_attribute7
                                 || '-'
                                 || i.orig_sys_document_ref;   -- Added for QC Defect 24032
            END LOOP;

            --x_attributes.attribute7 := SUBSTR ( SUBSTR ( x_attributes.attribute7 ,2),1,150); -- Commented for QC Defect 24032
            x_attributes.attribute7 := SUBSTR(SUBSTR(lc_attribute7,
                                                     2),
                                              1,
                                              150);   -- Added for QC Defect 24032
        END IF;

        -- added by Gaurav v2.0
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'p_current_row.orig_sys_document_ref  :  '
                         || p_current_row.orig_sys_document_ref);
            put_log_line(   'lc_customer_receipt_reference   :  '
                         || lc_customer_receipt_reference);
            put_log_line(   'p_current_row.orig_sys_document_ref  :  '
                         || p_current_row.orig_sys_document_ref);
            put_log_line(   'p_current_row.orig_sys_document_ref  :  '
                         || p_current_row.orig_sys_document_ref);
            put_log_line(   'l_customer_rec.cust_account_id  :  '
                         || l_customer_rec.cust_account_id);
        END IF;

        xx_ar_prepayments_pkg.create_prepayment(p_api_version =>                     1.0,
                                                p_init_msg_list =>                   fnd_api.g_true,
                                                p_commit =>                          fnd_api.g_false,
                                                p_validation_level =>                fnd_api.g_valid_level_full,
                                                x_return_status =>                   x_return_status,
                                                x_msg_count =>                       x_msg_count,
                                                x_msg_data =>                        x_msg_data,
                                                p_print_debug =>                     get_debug_char(),
                                                p_receipt_method_id =>               p_current_row.receipt_method_id,
                                                p_payment_type_code =>               NULL,
                                                p_currency_code =>                   p_current_row.currency_code,
                                                p_amount =>                          p_current_row.amount,
                                                p_payment_number =>                  p_current_row.payment_number,
                                                p_sas_sale_date =>                   p_current_row.receipt_date,
                                                p_receipt_date =>                    NULL,
                                                p_gl_date =>                         NULL,
                                                p_customer_id =>                     l_customer_rec.cust_account_id,
                                                p_customer_site_use_id =>            l_customer_rec.site_use_id,
                                                p_customer_bank_account_id =>        NULL,
                                                p_customer_receipt_reference =>      lc_customer_receipt_reference,
                                                p_remittance_bank_account_id =>      NULL,
                                                p_called_from =>                     'I1025',
                                                p_attribute_rec =>                   x_attributes,
                                                p_receipt_comments =>                lc_receipt_comments,
                                                p_application_ref_type =>            'SA',
                                                p_application_ref_num =>             p_current_row.transaction_number,
                                                p_apply_date =>                      NULL,
                                                p_apply_gl_date =>                   NULL,
                                                p_amount_applied =>                  NULL,
                                                p_app_attribute_rec =>               x_app_attributes,
                                                p_app_comments =>                    lc_app_comments,
                                                x_payment_set_id =>                  x_payment_set_id,
                                                x_cash_receipt_id =>                 x_cash_receipt_id,
                                                x_receipt_number =>                  x_receipt_number,
                                                p_receipt_ext_attributes =>          l_receipt_ext_attributes);

        -- x_payment_server_order_num         => x_payment_server_order_num,
        -- x_payment_response_error_code      => x_payment_response_error_code,

        -- p_trxn_extension_id                => ln_entity_id,
        -- p_identifier                       => p_current_row.IDENTIFIER);

        -- p_credit_card_code                 => p_current_row.credit_card_code,
        -- p_credit_card_number               => p_current_row.credit_card_number,
        -- p_credit_card_holder_name          => p_current_row.credit_card_holder_name,
        -- p_credit_card_expiration_date      => p_current_row.credit_card_expiration_date,
        -- p_credit_card_approval_code        => p_current_row.credit_card_approval_code,
        -- p_credit_card_approval_date        => p_current_row.credit_card_approval_date,
        -- p_payment_server_order_prefix      => 'XXI',
        IF (gb_debug)
        THEN
            put_log_line(   '- Return Status: '
                         || x_return_status
                         || ', Msg Cnt: '
                         || x_msg_count);
        END IF;

        IF (x_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Successfully created the deposit receipt with prepayment.');
            END IF;

            -- assign cash receipt id, so that it can be refetched later
            x_cash_receipt_rec.cash_receipt_id := x_cash_receipt_id;
        ELSE
            raise_api_errors(p_sub_name =>       lc_sub_name,
                             p_msg_count =>      x_msg_count,
                             p_api_name =>       'XX_AR_PREPAYMENTS_PKG.create_prepayment');
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure that handles all the pending deposit payments in the table
--   XX_OM_LEGACY_DEPOSITS.  it creates an AR receipt with the prepayment
--   application with references to the legacy order number
-- ==========================================================================
    PROCEDURE create_deposit_receipts(
        p_org_id                  IN  NUMBER,
        p_from_date               IN  DATE,
        p_to_date                 IN  DATE,
        p_request_id              IN  NUMBER DEFAULT NULL,
        p_orig_sys_document_ref   IN  VARCHAR2 DEFAULT NULL,
        p_only_deposit_reversals  IN  VARCHAR2 DEFAULT 'N',
        p_child_process_id        IN  VARCHAR2 DEFAULT NULL)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)               := 'CREATE_DEPOSIT_RECEIPTS';
        x_return_status       VARCHAR2(1)                DEFAULT NULL;
        x_payment_set_id      NUMBER                     DEFAULT NULL;
        l_deposits_tab        gt_deposits_tab_type;
        l_current_row         gt_current_record;
        l_invoice_rec         gcu_om_invoice%ROWTYPE;
        x_cash_receipt_rec    ar_cash_receipts%ROWTYPE;
        lc_invoice_exists     VARCHAR2(20)               DEFAULT NULL;
        --lc_comments                 VARCHAR2(200)   DEFAULT NULL;                                           --Commented for CR 722(Defect 6033)
        lc_comments           VARCHAR2(4000)             DEFAULT NULL;   --Added for CR 722(Defect 6033)
        lc_pre_pay            VARCHAR2(1)                := 'N';   -- added by gaurav v2.0
        ln_ord_cnt            NUMBER                     := 0;
        x_msg_count           NUMBER                     := 0;

-- ==========================================================================
--V2.0 -- Start
        CURSOR c_dep_rcpt(
            lp_orig_sys_document_ref  VARCHAR2)
        IS
            SELECT xoldd.orig_sys_document_ref
            FROM   xx_om_legacy_dep_dtls xoldd
            WHERE  xoldd.transaction_number = lp_orig_sys_document_ref;
--V2.0 -- End
-- ==========================================================================
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- get legacy deposits from OM which will create AR
--   receipts (with prepayments)
-- ==========================================================================
        put_log_line(   ' # p_org_id = '
                     || p_org_id);
        put_log_line(   ' # p_from_date = '
                     || p_from_date);
        put_log_line(   ' # p_to_date = '
                     || p_to_date);
        put_log_line(   ' # p_request_id = '
                     || p_request_id);
        put_log_line(   ' # p_orig_sys_document_ref = '
                     || p_orig_sys_document_ref);
        put_log_line(   ' # p_only_deposit_reversals = '
                     || p_only_deposit_reversals);
        put_log_line(   ' # p_child_process_id  = '
                     || p_child_process_id);

        OPEN gcu_deposits(cp_org_id =>                      p_org_id,
                          cp_from_date =>                   p_from_date,
                          cp_to_date =>                     p_to_date,
                          cp_request_id =>                  p_request_id,
                          cp_orig_sys_document_ref =>       p_orig_sys_document_ref,
                          cp_only_deposit_reversals =>      p_only_deposit_reversals,
                          cp_child_process_id =>            p_child_process_id);

        FETCH gcu_deposits
        BULK COLLECT INTO l_deposits_tab;

        CLOSE gcu_deposits;

        IF (gb_debug)
        THEN
            put_log_line(   ' # Record Count = '
                         || l_deposits_tab.COUNT);
        END IF;

        gn_create_deposits_num := l_deposits_tab.COUNT;

-- ==========================================================================
-- loop through all the deposits and create the receipts
-- ==========================================================================
        IF (l_deposits_tab.COUNT > 0)
        THEN
            FOR i_index IN l_deposits_tab.FIRST .. l_deposits_tab.LAST
            LOOP
                BEGIN
-- ==========================================================================
-- set a savepoint for the create deposit record processing
-- ==========================================================================
                    SAVEPOINT before_create_deposit_receipt;
-- ==========================================================================
-- map (convert) deposit record to create record type
-- ==========================================================================
                    l_current_row := NULL;
                    x_cash_receipt_rec := NULL;
                    lc_invoice_exists := NULL;
                    lc_comments := NULL;
                    lc_pre_pay := 'N';   -- added by gaurav
                    map_create_deposit_to_current(p_deposit_row =>      l_deposits_tab(i_index),
                                                  x_current_row =>      l_current_row);

-- ==========================================================================
-- output the details of the record
-- ==========================================================================
                    IF (gb_debug)
                    THEN
                        put_log_line();
                        put_log_line(   '======== Record (index='
                                     || i_index
                                     || ') ======== ');
                        put_log_line(   '(Start Date: '
                                     || TO_CHAR(SYSDATE,
                                                'DD-MON-YYYY HH24:MI:SS')
                                     || ')');
                        put_log_line(   '  Operating Unit = '
                                     || l_current_row.org_id
                                     || ' ('
                                     || xx_ar_prepayments_pkg.get_country_prefix(l_current_row.org_id)
                                     || ')');
                        put_log_line(   '  Current Status = '
                                     || l_current_row.process_code);
                        put_log_line(   '  Legacy Order   = '
                                     || l_current_row.orig_sys_document_ref);
                        put_log_line(   '  Payment Number = '
                                     || l_current_row.payment_number);
                        put_log_line(   '  Customer Name  = '
                                     || l_current_row.bill_to_customer);
                        put_log_line(   '  Payment Method = '
                                     || l_current_row.payment_type_code);
                        put_log_line(   '  Receipt Method = '
                                     || l_current_row.receipt_method);
                        put_log_line(   '  Prepaid Amt    = '
                                     || l_current_row.amount);
                        put_log_line(   '  Sale Location  = '
                                     || l_current_row.sale_location);
                        put_log_line(   '  Ship From Org  = '
                                     || l_current_row.ship_from_org);
                        put_log_line(   '  Order Number   = '
                                     || l_current_row.order_number);
                        put_log_line(   '  Pmt Type (Actual) = '
                                     || l_current_row.payment_type_new);
                        put_log_line(   '  Receipt Date   = '
                                     || l_current_row.receipt_date);
                        put_log_line();
                    END IF;

-- ==========================================================================
-- clear all previous I1025 messages
-- ==========================================================================
                    clear_messages(p_current_row =>      l_current_row);
-- ==========================================================================
-- lock the current row
-- ==========================================================================
                    lock_current_row(p_record_type =>      l_current_row.record_type,
                                     p_rowid =>            l_current_row.xx_payment_rowid);

-- ==========================================================================
-- reset payment set id for each group of payments
-- ==========================================================================
                    IF (l_current_row.payment_number = 1)
                    THEN
                        x_payment_set_id := NULL;
                    END IF;

-- ==========================================================================
-- validate the credit card is defined if credit card
-- ==========================================================================
                    IF (    l_current_row.payment_type_new = 'CREDIT_CARD'
                        AND l_current_row.credit_card_number IS NULL)
                    THEN
                        raise_missing_param_errors(p_sub_name =>        lc_sub_name,
                                                   p_param_name =>      'Credit Card Number (CREDIT_CARD_NUMBER)');
                    END IF;

-- ==========================================================================
-- if this deposit is a reversal
-- ==========================================================================
                    IF (l_current_row.deposit_reversal_flag = 'Y')
                    THEN
-- ==========================================================================
-- write-off the existing deposit receipt
-- ==========================================================================
                        writeoff_deposit_receipt(p_current_row =>           l_current_row,
                                                 x_cash_receipt_row =>      x_cash_receipt_rec,
                                                 x_comments =>              lc_comments);
                    ELSE
-- ==========================================================================
-- determine the type of payment record -
--   Type = 'POST-PAY', OM Order header_id IS NOT NULL:  COD / post-payment
--   Type = 'PRE-PAY', OM Order header_id IS NULL:  Deposit / pre-payment
-- ==========================================================================
                        IF (l_current_row.payment_type_flag = 'POST-PAY')
                        THEN
-- ==========================================================================
-- fetch the invoice if it already exists for this order
-- ==========================================================================
                            OPEN gcu_om_invoice(cp_header_id =>      l_current_row.header_id);

                            FETCH gcu_om_invoice
                            INTO  l_invoice_rec;

                            CLOSE gcu_om_invoice;

-- ==========================================================================
-- determine if the OM Order has already been invoiced
--   if not, indicate that it needs to be applied to the OM Order
-- ==========================================================================
                            IF (l_invoice_rec.customer_trx_id IS NOT NULL)
                            THEN
                                lc_invoice_exists := 'AR';
                            ELSE
                                lc_invoice_exists := 'OM';
                            END IF;
                        ELSE
-- ==========================================================================
-- Create the receipt with the pre-payment application to the
--   Sales Account Legacy Order Number
-- ==========================================================================
                            lc_invoice_exists := 'SA';
                        END IF;

                        IF (lc_invoice_exists = 'AR')
                        THEN
-- ==========================================================================
-- create and apply deposit receipt to existing customer trx
-- ==========================================================================
                            create_apply_deposit_receipt(p_current_row =>           l_current_row,
                                                         p_invoice_row =>           l_invoice_rec,
                                                         x_payment_set_id =>        x_payment_set_id,
                                                         x_cash_receipt_rec =>      x_cash_receipt_rec);
                        ELSE
-- ==========================================================================
-- create receipt for legacy deposit with prepay application to legacy order
-- ==========================================================================
                            lc_pre_pay := 'Y';   --added by gaurav v2.0
                            create_prepay_receipt(p_current_row =>           l_current_row,
                                                  p_invoice_exists =>        lc_invoice_exists,
                                                  x_payment_set_id =>        x_payment_set_id,
                                                  x_cash_receipt_rec =>      x_cash_receipt_rec);
                        END IF;

                        update_deposit_i1025_process(p_rowid =>             l_current_row.xx_payment_rowid,
                                                     p_i1025_status =>      'CREATED_DEPOSIT');
-- ==========================================================================
-- re-fetch the AR cash receipts that has just been created
-- ==========================================================================
                        arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec =>      x_cash_receipt_rec);

                        IF (gb_debug)
                        THEN
                            put_log_line('- Re-Fetched Receipt: ');
                            put_log_line(   '  cash receipt id = '
                                         || x_cash_receipt_rec.cash_receipt_id);
                            put_log_line(   '  receipt number  = '
                                         || x_cash_receipt_rec.receipt_number);
                        END IF;

-- ==========================================================================
-- if the order exists only in Sales Accounting, then insert the CC
--   deposits into this iPayment custom table, so that the level-3 line
--   data can be interfaced (since the order does not yet exist in OM)
-- ==========================================================================
                        IF (    l_current_row.payment_type_new = 'CREDIT_CARD'
                            AND lc_invoice_exists = 'SA')
                        THEN
                            insert_iby_deposit_aops_orders(p_aops_order_number =>      l_current_row.orig_sys_document_ref,
                                                           p_receipt_number =>         x_cash_receipt_rec.receipt_number,
                                                           p_tran_number =>            l_current_row.transaction_number);
                        END IF;
                    END IF;

-- ==========================================================================
-- update XX_OM_LEGACY_DEPOSITS with cash_receipt_id and x_payment_set_id
--   and mark as completed
-- ==========================================================================
                    mark_create_deposit_record(p_index_num =>             i_index,
                                               p_process_code =>          'C',
                                               p_deposits_row =>          l_deposits_tab(i_index),
                                               p_cash_receipt_rec =>      x_cash_receipt_rec,
                                               p_payment_set_id =>        x_payment_set_id,
                                               p_comments =>              lc_comments);

                    IF (    l_current_row.single_pay_ind = 'Y'
                        AND lc_pre_pay = 'Y')
                    THEN
                        FOR i IN c_dep_rcpt(l_current_row.orig_sys_document_ref)
                        LOOP
                            IF (gb_debug)
                            THEN
                                put_log_line
                                        (   ' Calling XX_OM_HVOP_DEPOSIT_CONC_PKG.apply_payment_to_prepay for Order : '
                                         || i.orig_sys_document_ref);
                            END IF;

                            BEGIN
                                SELECT COUNT(*)
                                INTO   ln_ord_cnt
                                FROM   oe_order_headers_all
                                WHERE  orig_sys_document_ref = i.orig_sys_document_ref
                                AND    flow_status_code NOT IN('CLOSED', 'INVOICED');

                                put_log_line(   ' ln_ord_cnt   :   '
                                             || ln_ord_cnt);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    put_log_line(   ' ln_ord_cnt   :   '
                                                 || ln_ord_cnt);
                                    ln_ord_cnt := 0;
                            END;

                            IF ln_ord_cnt > 0
                            THEN
                                xx_om_hvop_deposit_conc_pkg.apply_payment_to_prepay
                                                                   (p_orig_sys_document_ref =>      i.orig_sys_document_ref,
                                                                    x_return_status =>              x_return_status);
                                put_log_line(   ' HVOP  x_return_status   :   '
                                             || x_return_status);

                                IF (x_return_status = 'S')
                                THEN
                                    IF (gb_debug)
                                    THEN
                                        put_log_line(   '- Return Status: '
                                                     || x_return_status);
                                    END IF;
                                ELSE
                                    put_log_line
                                        (   'Error while calling XX_OM_HVOP_DEPOSIT_CONC_PKG.apply_payment_to_prepay -  x_return_status :   '
                                         || x_return_status);
                                END IF;
                            END IF;
                        END LOOP;
                    END IF;

                    -- added by Gaurav v2.0

                    -- ==========================================================================
-- commit at each commit interval
-- ==========================================================================
--
-- ==========================================================================
-- V2.0 Included below procedure  for capturing the orginal receipt information
-- into custom receipt table also  -- start
-- ==========================================================================
--IF (l_current_row.deposit_reversal_flag != 'Y')  then  -- added by Gaurav v2.0
                    IF (gb_debug)
                    THEN
                        put_log_line('- Call the procedure to insert records into Custom Receipt Table: ');
                    END IF;

                    -- Start of change for defect 14071
                    -- insert_into_cust_recpt_tbl ( p_header_id => l_current_row.header_id ,p_rowid => l_current_row.xx_payment_rowid ,p_cash_receipt_id => x_cash_receipt_rec.cash_receipt_id ,x_return_status => x_return_status );
                    insert_into_cust_recpt_tbl(p_header_id =>            l_deposits_tab(i_index).header_id,
                                               p_rowid =>                l_deposits_tab(i_index).ROWID,
                                               p_cash_receipt_id =>      x_cash_receipt_rec.cash_receipt_id,
                                               x_return_status =>        x_return_status);

                    IF (gb_debug)
                    THEN
                        put_log_line('- After calling the procedure to insert records into Custom Receipt Table: ');
                        put_log_line(   '  Header id = '
                                     || l_current_row.header_id);
                        put_log_line(   '  Cash Receipt id = '
                                     || x_cash_receipt_rec.cash_receipt_id);
                        put_log_line(   '  Return status  = '
                                     || x_return_status);
                    END IF;

                    --   end if;
                    -- V2.0  -- End
                    IF (MOD(i_index,
                            gn_commit_interval) = 0)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line('- COMMIT interval met');
                        END IF;

                        COMMIT;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line(   '*ERROR - '
                                         || SQLERRM);
                        END IF;

                        ROLLBACK TO SAVEPOINT before_create_deposit_receipt;
                        add_message(p_current_row =>         l_current_row,
                                    p_message_code =>        'CREATE_DEPOSIT_ERRORS',
                                    p_message_text =>        SQLERRM,
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_error);
-- ==========================================================================
-- update XX_OM_LEGACY_DEPOSITS record as errored
-- ==========================================================================
                        mark_create_deposit_record(p_index_num =>             i_index,
                                                   p_process_code =>          'E',
                                                   p_deposits_row =>          l_deposits_tab(i_index),
                                                   p_cash_receipt_rec =>      x_cash_receipt_rec,
                                                   p_payment_set_id =>        x_payment_set_id,
                                                   p_error_code =>            SQLCODE,
                                                   p_error_message =>         SQLERRM,
                                                   p_comments =>              lc_comments);
                END;
            END LOOP;
        END IF;

-- ==========================================================================
-- commit any open work
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('- COMMIT any open work');
        END IF;

        COMMIT;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- this procedure updates the original receipt for the refund
-- ==========================================================================
    PROCEDURE update_original_receipt(
        p_current_row       IN OUT NOCOPY  gt_current_record,
        x_cash_receipt_rec  IN OUT NOCOPY  ar_cash_receipts%ROWTYPE)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'UPDATE_ORIGINAL_RECEIPT';
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- fetch the original AR receipt
-- ==========================================================================
        arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec =>      x_cash_receipt_rec);

        IF (gb_debug)
        THEN
            put_log_line('- Fetched Original Receipt: ');
            put_log_line(   '  cash receipt id = '
                         || x_cash_receipt_rec.cash_receipt_id);
            put_log_line(   '  receipt number  = '
                         || x_cash_receipt_rec.receipt_number);
        END IF;

-- ==========================================================================
-- assign receipt reference fields and DFFs
-- ==========================================================================
-- set Sales Accounting DFF Context
        x_cash_receipt_rec.attribute_category := 'SALES_ACCT';

        -- Legacy Order Number (AOPS Order or POS Transaction)
        -- really do not want to update ATTRIBUTE7, but leave as original legacy order number
        --   however this is required for mail check refunds and cash mgmt reconciliation
        IF (p_current_row.payment_type_new = 'MAILCHECK')
        THEN
            x_cash_receipt_rec.attribute7 := p_current_row.orig_sys_document_ref;
        END IF;

        -- Payment Source
        x_cash_receipt_rec.attribute11 := 'REFUND';
        -- Order Header ID
        --x_cash_receipt_rec.attribute12  := NULL;
        -- I1025 Process Code
        x_cash_receipt_rec.attribute13 :=    'CREATED|ORIGINAL|'
                                          || TO_CHAR(SYSDATE,
                                                     'YYYY/MM/DD HH24:MI:SS');
-- ==========================================================================
-- update the original AR receipt with new reference DFFs
-- ==========================================================================
        arp_cash_receipts_pkg.update_p(p_cr_rec =>      x_cash_receipt_rec);

        IF (gb_debug)
        THEN
            put_log_line('- Updated Receipt: ');
            put_log_line(   '  cash receipt id = '
                         || x_cash_receipt_rec.cash_receipt_id);
            put_log_line(   '  receipt number  = '
                         || x_cash_receipt_rec.receipt_number);
        END IF;

        update_refund_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                    p_i1025_status =>      'FOUND_ORIGINAL');

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure that handles all pending return tenders in the table
--   XX_OM_RETURN_TENDERS_ALL.  it attempts to find an original receipt to
--   tie the refund to, or creates a zero-dollar receipt if the original
--   reference does not exist or does not match the refund
-- ==========================================================================
    PROCEDURE create_refund_receipts(
        p_org_id                 IN  NUMBER,
        p_from_date              IN  DATE,
        p_to_date                IN  DATE,
        p_request_id             IN  NUMBER DEFAULT NULL,
        p_orig_sys_document_ref  IN  VARCHAR2 DEFAULT NULL,
        p_child_process_id       IN  VARCHAR2 DEFAULT NULL)
    IS
        lc_sub_name      CONSTANT VARCHAR2(50)               := 'CREATE_REFUND_RECEIPTS';
        x_return_status           VARCHAR2(1)                DEFAULT NULL;
        l_refunds_tab             gt_refunds_tab_type;
        l_current_row             gt_current_record;
        x_original                gt_original;
        l_customer_rec            gcu_customer_id%ROWTYPE;
        x_cash_receipt_rec        ar_cash_receipts%ROWTYPE;
        lc_comments               VARCHAR2(200)              DEFAULT NULL;
        x_process_flag            VARCHAR2(10)               DEFAULT NULL;   -- Added for CR 722(Defect 6033)
        -- Added for Defect#21242
        lc_orig_receipt_comments  VARCHAR2(200);
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- get all the pending return tenders from XX_OM_RETURN_TENDERS_ALL
-- ==========================================================================
        OPEN gcu_refunds(cp_org_id =>                     p_org_id,
                         cp_from_date =>                  p_from_date,
                         cp_to_date =>                    p_to_date,
                         cp_request_id =>                 p_request_id,
                         cp_orig_sys_document_ref =>      p_orig_sys_document_ref,
                         cp_child_process_id =>           p_child_process_id);

        FETCH gcu_refunds
        BULK COLLECT INTO l_refunds_tab;

        CLOSE gcu_refunds;

        IF (gb_debug)
        THEN
            put_log_line(   ' # Record Count = '
                         || l_refunds_tab.COUNT);
        END IF;

        gn_create_refunds_num := l_refunds_tab.COUNT;

-- ==========================================================================
-- loop through all the return tender payment records that are retrieved
-- ==========================================================================
        IF (l_refunds_tab.COUNT > 0)
        THEN
            FOR i_index IN l_refunds_tab.FIRST .. l_refunds_tab.LAST
            LOOP
                BEGIN
-- ==========================================================================
-- set a savepoint for the create refund (zero-dollar) record processing
-- ==========================================================================
                    SAVEPOINT before_create_zero_receipt;
-- ==========================================================================
-- map (convert) refund (zero-dollar) record to create record type
-- ==========================================================================
                    l_current_row := NULL;
                    x_cash_receipt_rec := NULL;
                    x_original := NULL;
                    lc_comments := NULL;
                    map_create_refund_to_current(p_refund_row =>       l_refunds_tab(i_index),
                                                 x_current_row =>      l_current_row);

-- ==========================================================================
-- output the details of the record
-- ==========================================================================
                    IF (gb_debug)
                    THEN
                        put_log_line();
                        put_log_line(   '======== Record (index='
                                     || i_index
                                     || ') ========');
                        put_log_line(   '(Start Date: '
                                     || TO_CHAR(SYSDATE,
                                                'DD-MON-YYYY HH24:MI:SS')
                                     || ')');
                        put_log_line(   '  Operating Unit = '
                                     || l_current_row.org_id
                                     || ' ('
                                     || xx_ar_prepayments_pkg.get_country_prefix(l_current_row.org_id)
                                     || ')');
                        put_log_line(   '  Current Status = '
                                     || l_current_row.process_code);
                        put_log_line(   '  Legacy Order   = '
                                     || l_current_row.orig_sys_document_ref);
                        put_log_line(   '  Payment Number = '
                                     || l_current_row.payment_number);
                        put_log_line(   '  Customer Name  = '
                                     || l_current_row.bill_to_customer);
                        put_log_line(   '  Payment Method = '
                                     || l_current_row.payment_type_code);
                        put_log_line(   '  Receipt Method = '
                                     || l_current_row.receipt_method);
                        put_log_line(   '  Credit Amount  = '
                                     || l_current_row.amount);
                        put_log_line(   '  Sale Location  = '
                                     || l_current_row.sale_location);
                        put_log_line(   '  Ship From Org  = '
                                     || l_current_row.ship_from_org);
                        put_log_line(   '  Order Number   = '
                                     || l_current_row.order_number);
                        put_log_line(   '  Pmt Type (Actual) = '
                                     || l_current_row.payment_type_new);
                        put_log_line(   '  Receipt Date   = '
                                     || l_current_row.receipt_date);
                        put_log_line();
                    END IF;

-- ==========================================================================
-- clear all previous I1025 messages
-- ==========================================================================
                    clear_messages(p_current_row =>      l_current_row);
-- ==========================================================================
-- lock the current row
-- ==========================================================================
                    lock_current_row(p_record_type =>      l_current_row.record_type,
                                     p_rowid =>            l_current_row.xx_payment_rowid);

-- ==========================================================================
-- check to see if we can find the original payment receipt
-- if original could not be found or original does not match, create
--   zero-dollar receipt
-- ==========================================================================
-- V2.0 -- Start -- Calling single payment scenario procedure
                    IF (gb_debug)
                    THEN
                        put_log_line('Check Single payment Scenario.');
                    END IF;

                    IF (is_single_pay_pos_rec(l_current_row.header_id,
                                              NULL) )
                    THEN
                        gc_process_flag := 'M';

                        IF (gb_debug)
                        THEN
                            put_log_line('If Single payment then calling Create a zero-dollar receipt procedure.');
                            put_log_line(   'Value of Header Id before checking for Single payment scenario : '
                                         || l_current_row.header_id);
                        END IF;

                        create_zero_receipt(x_return_status =>         x_return_status,
                                            p_current_row =>           l_current_row,
                                            x_cash_receipt_rec =>      x_cash_receipt_rec,
                                            x_original =>              x_original,
                                            x_process_flag =>          gc_process_flag);
                        lc_comments := 'Zero-Dollar Rcpt';
                    ELSE
                        -- V2.0 -- Else condition -- Calling single payment scenario procedure
                        gc_process_flag := NULL;

                        IF (    get_original_receipt(p_current_row =>      l_current_row,
                                                     x_original =>         x_original)
                            AND SUBSTR(l_current_row.receipt_method,
                                       4,
                                       6) = 'PAYPAL')
                        THEN
                            IF (gb_debug)
                            THEN
                                put_log_line('Update original receipt with refund info.');
                            END IF;

                            x_cash_receipt_rec.cash_receipt_id := x_original.cash_receipt_id;  
                            update_original_receipt(p_current_row =>           l_current_row,
                                                    x_cash_receipt_rec =>      x_cash_receipt_rec);
                            lc_comments := 'Original Rcpt';
                            lc_orig_receipt_comments := lc_comments;
                        ELSE
                            IF (gb_debug)
                            THEN
                                put_log_line('Create a zero-dollar receipt.');
                            END IF;

                            lc_comments := 'Zero-Dollar Rcpt';
                        END IF;

                        create_zero_receipt(x_return_status =>         x_return_status,
                                            p_current_row =>           l_current_row,
                                            x_cash_receipt_rec =>      x_cash_receipt_rec,
                                            x_original =>              x_original,
                                            x_process_flag =>          x_process_flag);
                    END IF;   -- V2.0 -- Else condition -- Calling single payment scenario procedure
					
					--changes for defect #32362
					IF lc_comments = 'Original Rcpt' AND SUBSTR(l_current_row.receipt_method,
                              4,
                              6) = 'PAYPAL' 
					THEN
						insert_into_cust_recpt_tbl(p_header_id =>            l_current_row.header_id,
                                                   p_rowid =>                l_current_row.xx_payment_rowid,
                                                   p_cash_receipt_id =>      x_cash_receipt_rec.cash_receipt_id,
                                                   x_return_status =>        x_return_status);
					END IF;
					--changes ends for defect #32362
-- ==========================================================================
-- update XX_OM_RETURN_TENDERS_ALL with cash_receipt_id and x_payment_set_id
--   and mark as completed
-- ==========================================================================
--DEFECT#21242 START
                    IF SUBSTR(l_current_row.receipt_method,
                              4,
                              6) = 'PAYPAL'
                    THEN
					    	--Commented to apply credit memo to Zero Dollar receipt			    
                        --x_cash_receipt_rec.cash_receipt_id := x_original.cash_receipt_id;  --commented as part of the defect# 25731
                        mark_create_refund_record(p_index_num =>             i_index,
                                                  p_process_code =>          'C',
                                                  p_refunds_row =>           l_refunds_tab(i_index),
                                                  p_cash_receipt_rec =>      x_cash_receipt_rec,
                                                  p_payment_set_id =>        l_current_row.payment_set_id,
                                                  p_comments =>              lc_orig_receipt_comments);
                    ELSE
                        mark_create_refund_record(p_index_num =>             i_index,
                                                  p_process_code =>          'C',
                                                  p_refunds_row =>           l_refunds_tab(i_index),
                                                  p_cash_receipt_rec =>      x_cash_receipt_rec,
                                                  p_payment_set_id =>        l_current_row.payment_set_id,
                                                  p_comments =>              lc_comments);
                    END IF;
					
					IF NVL(lc_comments,
                           'X') != 'Original Rcpt'
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line('Calling the procedure to insert records into Custom Receipt Table: ');
                        END IF;

                        insert_into_cust_recpt_tbl(p_header_id =>            l_current_row.header_id,
                                                   p_rowid =>                l_current_row.xx_payment_rowid,
                                                   p_cash_receipt_id =>      x_cash_receipt_rec.cash_receipt_id,
                                                   x_return_status =>        x_return_status);

                        IF (gb_debug)
                        THEN
                            put_log_line('- After calling the procedure to insert records into Custom Receipt Table: ');
                            put_log_line(   '  header id = '
                                         || l_current_row.header_id);
                            put_log_line(   '  cash Receipt id = '
                                         || x_cash_receipt_rec.cash_receipt_id);
                            put_log_line(   '  return status  = '
                                         || x_return_status);
                        END IF;
                    END IF;
					
					/*--Commented as part of Defect# 38421 to avoid additional receipt write-off for original receipt
					--Start of Defect# 25731
					IF SUBSTR(l_current_row.receipt_method,
                              4,
                              6) = 'PAYPAL'
                    THEN
					
					x_cash_receipt_rec.cash_receipt_id := x_original.cash_receipt_id;
					Writeoff_Receipt(x_cash_receipt_rec =>      x_cash_receipt_rec, -- to write-off original receipt
                             p_current_row =>           l_current_row,
                             p_activity_name =>     'US_REFUND_PAYPAL');
							 
					END IF;
					--End of Defect# 25731
					*/

                    IF (MOD(i_index,
                            gn_commit_interval) = 0)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line('- COMMIT interval met');
                        END IF;

                        COMMIT;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line(   '*ERROR - '
                                         || SQLERRM);
                        END IF;

                        ROLLBACK TO SAVEPOINT before_create_zero_receipt;
                        add_message(p_current_row =>         l_current_row,
                                    p_message_code =>        'CREATE_REFUND_ERRORS',
                                    p_message_text =>        SQLERRM,
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_error);
-- ==========================================================================
-- update XX_OM_RETURN_TENDERS_ALL refund record as errored
-- ==========================================================================
                        mark_create_refund_record(p_index_num =>             i_index,
                                                  p_process_code =>          'E',
                                                  p_refunds_row =>           l_refunds_tab(i_index),
                                                  p_cash_receipt_rec =>      x_cash_receipt_rec,
                                                  p_payment_set_id =>        l_current_row.payment_set_id,
                                                  p_error_code =>            SQLCODE,
                                                  p_error_message =>         SQLERRM,
                                                  p_comments =>              lc_comments);
                END;
            END LOOP;
        END IF;

-- ==========================================================================
-- commit any open work
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('- COMMIT any open work');
        END IF;

        COMMIT;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- this applies the receipt to a credit memo created from the OM refund
-- ==========================================================================
    PROCEDURE apply_receipt_to_cm(
        p_current_row       IN OUT NOCOPY  gt_current_record,
        x_cash_receipt_rec  IN OUT NOCOPY  ar_cash_receipts%ROWTYPE)
    IS
        lc_sub_name    CONSTANT VARCHAR2(50)               := 'APPLY_RECEIPT_TO_CM';
        x_return_status         VARCHAR2(20)               DEFAULT NULL;
        x_msg_count             NUMBER                     DEFAULT NULL;
        x_msg_data              VARCHAR2(4000)             DEFAULT NULL;
        ln_apply_amount         NUMBER                     DEFAULT NULL;
        ld_apply_date           DATE                       DEFAULT NULL;
        x_balance_due           NUMBER                     DEFAULT NULL;
        x_default_gl_date       DATE                       DEFAULT NULL;
        x_defaulting_rule_used  VARCHAR2(200)              DEFAULT NULL;
        x_error_message         VARCHAR2(4000)             DEFAULT NULL;

        CURSOR lcu_existing_app
        IS
            SELECT receivable_application_id,
                   amount_applied
            FROM   ar_receivable_applications_all
            WHERE  cash_receipt_id = p_current_row.cash_receipt_id
            AND    display = 'Y'
            AND    status = 'APP'
            AND    applied_payment_schedule_id = p_current_row.payment_schedule_id;

        l_existing_app          lcu_existing_app%ROWTYPE;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
            put_log_line('Apply Refund Receipt to newly created credit memo.');
        END IF;

-- ==========================================================================
-- set apply amount to current refund amount
-- ==========================================================================
        ln_apply_amount := p_current_row.amount;
-- ==========================================================================
-- determine the apply date
--   use the greatest of the refund date or original receipt date
--     defect #3547
-- ==========================================================================
        ld_apply_date := GREATEST(p_current_row.receipt_date,
                                  p_current_row.original_receipt_date);

-- ==========================================================================
-- Check if existing receivable application for this transaction (pmt sched)
-- ==========================================================================
        OPEN lcu_existing_app;

        FETCH lcu_existing_app
        INTO  l_existing_app;

        CLOSE lcu_existing_app;

-- ==========================================================================
-- Unapply the existing application, so that we can apply the correct amount
-- ==========================================================================
        IF (l_existing_app.receivable_application_id IS NOT NULL)
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Un-Apply existing application on this credit memo.');
                put_log_line(   '  Payment Sched Id = '
                             || p_current_row.payment_schedule_id);
                put_log_line(   '  Receivable App Id = '
                             || l_existing_app.receivable_application_id);
                put_log_line(   '  Existing Amount = '
                             || l_existing_app.amount_applied);
            END IF;

-- ==========================================================================
-- validate and default the GL date
-- ==========================================================================
            IF (NOT arp_standard.validate_and_default_gl_date(gl_date =>                    SYSDATE,
                                                              trx_date =>                   ld_apply_date,
                                                              validation_date1 =>           NULL,
                                                              validation_date2 =>           NULL,
                                                              validation_date3 =>           NULL,
                                                              default_date1 =>              NULL,
                                                              default_date2 =>              NULL,
                                                              default_date3 =>              NULL,
                                                              p_allow_not_open_flag =>      NULL,
                                                              p_invoicing_rule_id =>        NULL,
                                                              p_set_of_books_id =>          NULL,
                                                              p_application_id =>           NULL,
                                                              default_gl_date =>            x_default_gl_date,
                                                              defaulting_rule_used =>       x_defaulting_rule_used,
                                                              error_message =>              x_error_message) )
            THEN
                fnd_message.set_name('XXFIN',
                                     'XX_AR_I1025_20002_API_ERRORS');
                fnd_message.set_token('SUB_NAME',
                                      lc_sub_name);
                fnd_message.set_token('API_NAME',
                                      'ARP_STANDARD.validate_and_default_gl_date');
                fnd_message.set_token('API_ERRORS',
                                      x_error_message);
                raise_application_error(-20002,
                                        fnd_message.get() );
            END IF;

-- ==========================================================================
-- reverse (unapply) the existing receipt application to this Credit Memo
-- ==========================================================================
--p_comments => 'I1025 (Un-Apply Credit Memo)' -- Removed by NB for 1i upgrade api doec not have the parameter.
            arp_process_application.REVERSE(p_ra_id =>                  l_existing_app.receivable_application_id,
                                            p_reversal_gl_date =>       x_default_gl_date,
                                            p_reversal_date =>          ld_apply_date,
                                            p_module_name =>            NULL,
                                            p_module_version =>         NULL,
                                            p_bal_due_remaining =>      x_balance_due,
                                            p_called_from =>            'I1025');
-- ==========================================================================
-- set new apply amount (current refund amount + original applied amount)
-- ==========================================================================
            ln_apply_amount :=   p_current_row.amount
                               + l_existing_app.amount_applied;

            IF (gb_debug)
            THEN
                put_log_line('Set new Apply Amount.');
                put_log_line(   '  CM Apply Amount = '
                             || ln_apply_amount);
            END IF;
        END IF;

-- ==========================================================================
-- Apply the zero-dollar receipt or the matching original receipt to the
--   newly created credit memo
-- ==========================================================================
        ar_receipt_api_pub.APPLY(p_api_version =>                      1.0,
                                 p_init_msg_list =>                    fnd_api.g_true,
                                 p_commit =>                           fnd_api.g_false,
                                 p_validation_level =>                 fnd_api.g_valid_level_full,
                                 x_return_status =>                    x_return_status,
                                 x_msg_count =>                        x_msg_count,
                                 x_msg_data =>                         x_msg_data,
                                 p_cash_receipt_id =>                  p_current_row.cash_receipt_id,
                                 p_apply_date =>                       ld_apply_date,
                                 p_amount_applied =>                   ln_apply_amount,
                                 p_applied_payment_schedule_id =>      p_current_row.payment_schedule_id,
                                 p_comments =>                         'I1025 (Apply Credit Memo)',
                                 p_called_from =>                      'I1025');

        IF (gb_debug)
        THEN
            put_log_line(   '- Return Status: '
                         || x_return_status
                         || ', Msg Cnt: '
                         || x_msg_count);
        END IF;

        IF (x_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Successfully applied Refund Receipt to credit memo.');
                put_log_line(   '  cash_receipt_id = '
                             || p_current_row.cash_receipt_id);
                put_log_line(   '  customer_trx_id = '
                             || p_current_row.customer_trx_id);
            END IF;
        ELSE
            raise_api_errors(p_sub_name =>       lc_sub_name,
                             p_msg_count =>      x_msg_count,
                             p_api_name =>       'AR_RECEIPT_API_PUB.apply');
        END IF;

-- ==========================================================================
-- re-fetch the latest AR receipt
-- ==========================================================================
        arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec =>      x_cash_receipt_rec);

        IF (gb_debug)
        THEN
            put_log_line('- Re-Fetched and Locked Receipt: ');
            put_log_line(   '  cash receipt id = '
                         || x_cash_receipt_rec.cash_receipt_id);
            put_log_line(   '  receipt number  = '
                         || x_cash_receipt_rec.receipt_number);
        END IF;

-- ==========================================================================
-- update I1025 process code to "Applied" (keeping "ORIGINAL" identifier)
-- ==========================================================================
        IF (x_cash_receipt_rec.attribute13 LIKE '%|ORIGINAL|%')
        THEN
            set_i1025_process_code(x_cash_receipt_rec =>        x_cash_receipt_rec,
                                   p_i1025_process_code =>      'APPLIED|ORIGINAL');
            update_refund_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                        p_i1025_status =>      'APPLIED_ORIGINAL');
        ELSE
            set_i1025_process_code(x_cash_receipt_rec =>        x_cash_receipt_rec,
                                   p_i1025_process_code =>      'APPLIED');
            update_refund_i1025_process(p_rowid =>             p_current_row.xx_payment_rowid,
                                        p_i1025_status =>      'APPLIED_ZERO_DOLLAR');
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure that handles applying the credit memo (refund transactions) to
--  the original or zero dollar receipt
-- ==========================================================================
    PROCEDURE apply_refund_receipts(
        p_org_id                 IN  NUMBER,
        p_from_date              IN  DATE,
        p_to_date                IN  DATE,
        p_request_id             IN  NUMBER DEFAULT NULL,
        p_orig_sys_document_ref  IN  VARCHAR2 DEFAULT NULL,
        p_child_process_id       IN  VARCHAR2 DEFAULT NULL)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)               := 'APPLY_REFUND_RECEIPTS';
        x_cash_receipt_rec    ar_cash_receipts%ROWTYPE;
        l_refund_cms_tab      gt_refund_cms_tab_type;
        l_current_row         gt_current_record;
        ln_cm_amount_due      NUMBER                     DEFAULT NULL;
        ln_difference         NUMBER                     DEFAULT NULL;
        lc_comments           VARCHAR2(200)              DEFAULT NULL;
        x_process_flag        VARCHAR2(10)               DEFAULT NULL;   ---Added for CR 722(Defect 6033)
        x_return_status       VARCHAR2(1)                DEFAULT NULL;

        -- V2.0 Included new variable to capture status of procedure
        CURSOR c_amt_due(
            cp_customer_trx_id  IN  NUMBER)
        IS
            SELECT NVL(amount_due_remaining,
                       0)
            FROM   ar_payment_schedules_all
            WHERE  CLASS = 'CM'
            AND    customer_trx_id = cp_customer_trx_id;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- get the credit memos that need to be applied to the original or zero
-- dollar cash receipts
-- ==========================================================================
        OPEN gcu_refund_cms(cp_org_id =>                     p_org_id,
                            cp_from_date =>                  p_from_date,
                            cp_to_date =>                    p_to_date,
                            cp_request_id =>                 p_request_id,
                            cp_orig_sys_document_ref =>      p_orig_sys_document_ref,
                            cp_child_process_id =>           p_child_process_id);

        FETCH gcu_refund_cms
        BULK COLLECT INTO l_refund_cms_tab;

        CLOSE gcu_refund_cms;

        IF (gb_debug)
        THEN
            put_log_line(   ' # Record Count = '
                         || l_refund_cms_tab.COUNT);
        END IF;

        gn_apply_refunds_num := l_refund_cms_tab.COUNT;

-- ==========================================================================
-- loop through the credit memos retreived
-- ==========================================================================
        IF (l_refund_cms_tab.COUNT > 0)
        THEN
            FOR i_index IN l_refund_cms_tab.FIRST .. l_refund_cms_tab.LAST
            LOOP
                BEGIN
-- ==========================================================================
-- set a savepoint for the applying deposit record processing
-- ==========================================================================
                    SAVEPOINT before_apply_refund_receipt;
-- ==========================================================================
-- map (convert) apply deposit record to create record type
-- ==========================================================================
                    l_current_row := NULL;
                    x_cash_receipt_rec := NULL;
                    lc_comments := NULL;
                    map_apply_refund_to_current(p_refund_cm_row =>      l_refund_cms_tab(i_index),
                                                x_current_row =>        l_current_row);

-- ==========================================================================
-- output the details of the record
-- ==========================================================================
                    IF (gb_debug)
                    THEN
                        put_log_line();
                        put_log_line(   '======== Record (index='
                                     || i_index
                                     || ') ========');
                        put_log_line(   '(Start Date: '
                                     || TO_CHAR(SYSDATE,
                                                'DD-MON-YYYY HH24:MI:SS')
                                     || ')');
                        put_log_line(   '  Operating Unit  = '
                                     || l_current_row.org_id
                                     || ' ('
                                     || xx_ar_prepayments_pkg.get_country_prefix(l_current_row.org_id)
                                     || ')');
                        put_log_line(   '  Cust Acct Id    = '
                                     || l_current_row.bill_to_customer_id);
                        put_log_line(   '  Legacy Order    = '
                                     || l_current_row.orig_sys_document_ref);
                        put_log_line(   '  Receipt Number  = '
                                     || l_current_row.receipt_number);
                        put_log_line(   '  Receipt Status  = '
                                     || l_current_row.receipt_status);
                        put_log_line(   '  Cash Receipt Id = '
                                     || l_current_row.cash_receipt_id);
                        put_log_line(   '  Customer Trx Id = '
                                     || l_current_row.customer_trx_id);
                        put_log_line(   '  Invoice Number  = '
                                     || l_current_row.trx_number);
                        put_log_line(   '  Sale Location   = '
                                     || l_current_row.sale_location);
                        put_log_line(   '  Ship From Org   = '
                                     || l_current_row.ship_from_org);
                        put_log_line(   '  Pmt Schedule Id = '
                                     || l_current_row.payment_schedule_id);
                        put_log_line(   '  Trx Status      = '
                                     || l_current_row.payment_schedule_status);
                        put_log_line(   '  Pmt Type (Actual) = '
                                     || l_current_row.payment_type_new);
                        put_log_line(   '  Receipt Date    = '
                                     || l_current_row.receipt_date);
                        put_log_line(   '  I1025 Status    = '
                                     || l_current_row.i1025_status);
                        put_log_line(   '  Receipt Cust Id = '
                                     || l_refund_cms_tab(i_index).receipt_customer_id);
                        put_log_line();
                    END IF;

-- ==========================================================================
-- clear all previous I1025 messages
-- ==========================================================================
                    clear_messages(p_current_row =>      l_current_row);
-- ==========================================================================
-- lock the current row
-- ==========================================================================
                    lock_current_row(p_record_type =>      l_current_row.record_type,
                                     p_rowid =>            l_current_row.xx_payment_rowid);

-- ==========================================================================
-- set comment if this refund is on an original or zero-dollar receipt
-- ==========================================================================
                    IF (l_current_row.i1025_status LIKE '%ORIGINAL%')
                    THEN
                        lc_comments := 'Original Rcpt';
                    ELSE
                        lc_comments := 'Zero-Dollar Rcpt';
                    END IF;

                    x_cash_receipt_rec.cash_receipt_id := l_current_row.cash_receipt_id;
-- ==========================================================================
-- fetch the AR receipts that need to be applied
-- ==========================================================================
                    arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec =>      x_cash_receipt_rec);

                    IF (gb_debug)
                    THEN
                        put_log_line('- Fetched and Locked Receipt: ');
                        put_log_line(   '  cash receipt id = '
                                     || x_cash_receipt_rec.cash_receipt_id);
                        put_log_line(   '  receipt number  = '
                                     || x_cash_receipt_rec.receipt_number);
                    END IF;

-- ==========================================================================
-- validate that the customer on the receipt matches the customer on the
--  credit memo (otherwise we get weird applied payment schedule errors)
--   defect 10914
-- ==========================================================================
                    IF (l_current_row.bill_to_customer_id <> l_refund_cms_tab(i_index).receipt_customer_id)
                    THEN
                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20018_DIFF_CUST');
                        fnd_message.set_token('SUB_NAME',
                                              lc_sub_name);
                        raise_application_error(-20003,
                                                fnd_message.get() );
                    END IF;

-- ==========================================================================
-- validate credit memo is not closed
-- ==========================================================================
                    IF (l_current_row.payment_schedule_status = 'CL')
                    THEN
                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20003_APPLY_CLOSED');
                        fnd_message.set_token('SUB_NAME',
                                              lc_sub_name);
                        raise_application_error(-20003,
                                                fnd_message.get() );
                    END IF;

-- ==========================================================================
-- validate apply amount is not zero
-- ==========================================================================
                    IF (l_current_row.amount = 0)
                    THEN
                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20004_APPLY_ZERO');
                        fnd_message.set_token('SUB_NAME',
                                              lc_sub_name);
                        raise_application_error(-20004,
                                                fnd_message.get() );
                    END IF;

-- ==========================================================================
-- get the current amount due for this credit memo
-- ==========================================================================
                    OPEN c_amt_due(cp_customer_trx_id =>      l_current_row.customer_trx_id);

                    FETCH c_amt_due
                    INTO  ln_cm_amount_due;

                    CLOSE c_amt_due;

                    ln_cm_amount_due := NVL(ln_cm_amount_due,
                                            0);

                    IF (gb_debug)
                    THEN
                        put_log_line('- Verify Credit Memo Amounts and Dates: ');
                        put_log_line(   '  Credit Memo Amt  = '
                                     || ln_cm_amount_due);
                        put_log_line(   '  Refund Amount    = '
                                     || l_current_row.amount);
                        put_log_line(   '  Credit Memo Date = '
                                     || l_current_row.trx_date);
                        put_log_line(   '  Receipt Date     = '
                                     || l_current_row.receipt_date);
                        put_log_line();
                    END IF;

-- ==========================================================================
-- determine if the credit memo amount due remaining is less than refund amt,
--   if so, then CM amount should be used for applying to the credit memo
-- ==========================================================================
                    IF (  -1
                        * l_current_row.amount >   -1
                                                 * ln_cm_amount_due)
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line(   ' Refund Amount Tolerance = '
                                         || gn_refund_tolerance);
                        END IF;

                        ln_difference := ABS(  l_current_row.amount
                                             - ln_cm_amount_due);

                        IF (gb_debug)
                        THEN
                            put_log_line(   ' Diff in Refund Amt and CM = '
                                         || ln_difference);
                        END IF;

                        IF (ln_difference < gn_refund_tolerance)
                        THEN
                            fnd_message.set_name('XXFIN',
                                                 'XX_AR_I1025_20105_REMAIN_PREPA');
                            fnd_message.set_token('CM_AMOUNT',
                                                  ln_cm_amount_due);
                            fnd_message.set_token('REFUND_AMOUNT',
                                                  l_current_row.amount);
                            add_message(p_current_row =>         l_current_row,
                                        p_message_code =>        'REFUND_NEW_APPLY_AMOUNT',
                                        p_message_text =>        fnd_message.get(),
                                        p_error_location =>      lc_sub_name,
                                        p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_warning);
                            -- using the GREATEST function, because we want the least of negative amounts
                            l_current_row.amount := GREATEST(ln_cm_amount_due,
                                                             l_current_row.amount);

                            IF (gb_debug)
                            THEN
                                put_log_line('* Refund Amount different than CM and within tolerance ');
                                put_log_line(   '  New Apply Amount = '
                                             || l_current_row.amount);
                                put_log_line();
                            END IF;
                        ELSE
                            fnd_message.set_name('XXFIN',
                                                 'XX_AR_I1025_20013_OVER_REF_TOL');
                            fnd_message.set_token('SUB_NAME',
                                                  lc_sub_name);
                            fnd_message.set_token('CM_AMOUNT',
                                                  TO_CHAR(ln_cm_amount_due,
                                                          '$99,990.00') );
                            fnd_message.set_token('REFUND_AMOUNT',
                                                  TO_CHAR(l_current_row.amount,
                                                          '$99,990.00') );
                            fnd_message.set_token('TOLERANCE',
                                                  TO_CHAR(gn_refund_tolerance,
                                                          '$990.00') );
                            raise_application_error(-20013,
                                                    fnd_message.get() );
                        END IF;
                    END IF;

-- ==========================================================================
-- update XX_OM_RETURN_TENDERS_ALL
-- ==========================================================================
                    UPDATE xx_om_return_tenders_all
                    SET i1025_apply_amount = l_current_row.amount
                    WHERE  ROWID = l_current_row.xx_payment_rowid;

-- ==========================================================================
-- determine if the credit memo transaction date is later than the receipt
--   date, if so, then apply date should be greatest of the dates
-- ==========================================================================
                    IF (l_current_row.trx_date > l_current_row.receipt_date)
                    THEN
                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20107_NEW_APP_DATE');
                        fnd_message.set_token('TRX_DATE',
                                              l_current_row.trx_date);
                        fnd_message.set_token('REFUND_DATE',
                                              l_current_row.receipt_date);
                        add_message(p_current_row =>         l_current_row,
                                    p_message_code =>        'REFUND_NEW_APPLY_DATE',
                                    p_message_text =>        fnd_message.get(),
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_warning);
                        l_current_row.receipt_date := GREATEST(l_current_row.trx_date,
                                                               l_current_row.receipt_date);

                        IF (gb_debug)
                        THEN
                            put_log_line('* CM Trx Date is later than receipt date, apply using Trx Date ');
                            put_log_line(   '  New Apply Date = '
                                         || l_current_row.receipt_date);
                            put_log_line();
                        END IF;
                    END IF;

-- ==========================================================================
-- apply the zero-dollar or original receipt to the credit memo
-- ==========================================================================
                    apply_receipt_to_cm(p_current_row =>           l_current_row,
                                        x_cash_receipt_rec =>      x_cash_receipt_rec);

                    IF (   l_current_row.receipt_status <> 'CONFIRMED'
                        OR x_cash_receipt_rec.amount = 0)
                    THEN
-- ==========================================================================
-- for any other refund other than matching CC refund, writeoff the receipt
-- ==========================================================================
                        IF (is_single_pay_pos_rec(l_current_row.header_id,
                                                  NULL) )
                        THEN
                            gc_process_flag := 'M';
                        ELSE
                            gc_process_flag := NULL;
                        END IF;

                        writeoff_receipt_credit_bal(p_current_row =>           l_current_row,
                                                    x_cash_receipt_rec =>      x_cash_receipt_rec,
                                                    x_process_flag =>          x_process_flag);
                    --Added for CR 722(Defect 6033)
                    ELSE
                        fnd_message.set_name('XXFIN',
                                             'XX_AR_I1025_20011_NOT_REMITTED');
                        fnd_message.set_token('SUB_NAME',
                                              lc_sub_name);
                        raise_application_error(-20011,
                                                fnd_message.get() );
                    END IF;

-- ==========================================================================
-- mark apply refund record as completed successfully
-- ==========================================================================
                    mark_apply_refund_record(p_index_num =>           i_index,
                                             p_process_code =>        'C',
                                             p_refund_cms_row =>      l_refund_cms_tab(i_index),
                                             p_comments =>            lc_comments);
-- ==========================================================================
-- commit at each commit interval
--   defect 7462, apply refunds will have locking issues on AR batches,
--     if not committed every record, removing commit interval check
-- ==========================================================================
                    COMMIT;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        IF (gb_debug)
                        THEN
                            put_log_line(   '*ERROR - '
                                         || SQLERRM);
                        END IF;

                        ROLLBACK TO SAVEPOINT before_apply_refund_receipt;
                        add_message(p_current_row =>         l_current_row,
                                    p_message_code =>        'APPLY_REFUND_ERRORS',
                                    p_message_text =>        SQLERRM,
                                    p_error_location =>      lc_sub_name,
                                    p_message_type =>        xx_ar_prepayments_pkg.gc_i1025_msg_type_error);
-- ==========================================================================
-- mark apply refund record as errored
-- ==========================================================================
                        mark_apply_refund_record(p_index_num =>           i_index,
                                                 p_process_code =>        'E',
                                                 p_refund_cms_row =>      l_refund_cms_tab(i_index),
                                                 p_error_code =>          SQLCODE,
                                                 p_error_message =>       SQLERRM,
                                                 p_comments =>            lc_comments);
                END;
            END LOOP;
        END IF;

-- ==========================================================================
-- commit any open work
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('- COMMIT any open work');
        END IF;

        COMMIT;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure used by summary report to print column headings
-- ==========================================================================
    PROCEDURE print_column_headings
    IS
    BEGIN
        put_out_line(   RPAD('Status',
                             8)
                     || RPAD('Legacy Order',
                             22)
                     || RPAD('Order Number',
                             14)
                     || RPAD('Pmt',
                             4)
                     || RPAD('Created',
                             10)
                     || RPAD('Receipt Method',
                             22)
                     || LPAD('Amount',
                             12)
                     || RPAD(' Receipt Num',
                             13) );
        put_out_line(   RPAD('=======',
                             8)
                     || RPAD('=====================',
                             22)
                     || RPAD('=============',
                             14)
                     || RPAD('===',
                             4)
                     || RPAD('=========',
                             10)
                     || RPAD('=====================',
                             22)
                     || LPAD('============',
                             12)
                     || RPAD(' ============',
                             13) );
    END;

-- ==========================================================================
-- procedure used by summary report to print column headings
-- ==========================================================================
    PROCEDURE print_row_data(
        p_record_status_row  IN  gt_rec_status)
    IS
    BEGIN
        put_out_line(   RPAD(NVL(p_record_status_row.record_status,
                                 ' '),
                             8)
                     || RPAD(NVL(p_record_status_row.orig_sys_document_ref,
                                 ' '),
                             22)
                     || RPAD(NVL(TO_CHAR(p_record_status_row.order_number),
                                 ' '),
                             14)
                     || RPAD(NVL(TO_CHAR(p_record_status_row.payment_number),
                                 ' '),
                             4)
                     || RPAD(NVL(TO_CHAR(p_record_status_row.creation_date,
                                         'DD-MON-RR'),
                                 ' '),
                             10)
                     || RPAD(NVL(p_record_status_row.receipt_method,
                                 ' '),
                             22)
                     || LPAD(NVL(TO_CHAR(p_record_status_row.amount,
                                         '$999,990.00'),
                                 ' '),
                             12)
                     || ' '
                     || RPAD(NVL(p_record_status_row.receipt_number,
                                 ' '),
                             13)
                     || ' '
                     || NVL(p_record_status_row.comments,
                            ' ') );

        IF (p_record_status_row.process_code = 'E')
        THEN
            put_out_line('*** Errors processing record *** ');
            put_out_line(   ' '
                         || REPLACE(p_record_status_row.MESSAGE,
                                    CHR(10),
                                       CHR(10)
                                    || ' ') );
            put_out_line();
        END IF;
    END;

-- ==========================================================================
-- procedure called by the master program to call iPayment I1325 that
--   fetches deposit AOPS orders for line level-3 order details
--   This should be called after any call to create deposit receipts
--     (specifically for Credit Cards).
--   Conc Prog:  OD: Line Level 3 Detail for Deposits Program
-- ==========================================================================
    PROCEDURE submit_fetch_depst_aops_orders
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'SUBMIT_FETCH_DEPOSIT_AOPS_ORDERS';
        n_conc_request_id     NUMBER       DEFAULT NULL;
        b_sub_request         BOOLEAN      DEFAULT FALSE;
    BEGIN
-- ===========================================================================
-- set child flag if this is a child request
-- ===========================================================================
        IF (fnd_global.conc_request_id IS NOT NULL)
        THEN
            b_sub_request := TRUE;
        END IF;

-- ===========================================================================
-- submit the request
-- ===========================================================================
        n_conc_request_id :=
            fnd_request.submit_request(application =>      'XXFIN',   -- application short name
                                       program =>          'XX_IBY_DEPOSIT_DTLS_PKG_DETAIL',   -- concurrent program name
                                       description =>      NULL,   -- additional request description
                                       start_time =>       NULL,   -- request submit time
                                       sub_request =>      b_sub_request);   -- is this a sub-request?

-- this program requires no parameters
-- ===========================================================================
-- if request was successful
-- ===========================================================================
        IF (n_conc_request_id > 0)
        THEN
-- ===========================================================================
-- if a child request, then update it for concurrent mgr to process
-- ===========================================================================
            IF (b_sub_request)
            THEN
                UPDATE fnd_concurrent_requests
                SET phase_code = 'P',
                    status_code = 'I'
                WHERE  request_id = n_conc_request_id;
            END IF;

-- ===========================================================================
-- must commit work so that the concurrent manager polls the request
-- ===========================================================================
            COMMIT;
            put_log_line(   ' Concurrent Request ID: '
                         || n_conc_request_id
                         || '.');
-- ===========================================================================
-- else errors have occured for request
-- ===========================================================================
        ELSE
-- ===========================================================================
-- retrieve and raise any errors
-- ===========================================================================
            fnd_message.raise_error;
        END IF;
    END;

-- ==========================================================================
-- procedure called by the master program to produce an output summary report
-- ==========================================================================
    PROCEDURE print_summary_report(
        p_from_date              IN  DATE,
        p_to_date                IN  DATE,
        p_which_process          IN  VARCHAR2 DEFAULT gc_process_all,
        p_request_id             IN  NUMBER DEFAULT NULL,
        p_orig_sys_document_ref  IN  VARCHAR2 DEFAULT NULL,
        p_child_process_id       IN  VARCHAR2 DEFAULT NULL,
        p_print_error_report     IN  BOOLEAN DEFAULT FALSE,
        p_print_heading          IN  BOOLEAN DEFAULT TRUE,
        p_error_group_text       IN  VARCHAR2 DEFAULT NULL,
        p_print_end_of_report    IN  BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        IF (p_print_heading)
        THEN
            put_out_line(   'Office Depot, Inc.         OD: AR Create and Apply Receipts Summary    Date: '
                         || TO_CHAR(SYSDATE,
                                    'DD-MON-YYYY HH24:MI:SS') );
            put_out_line(   'Request Id: '
                         || RPAD(fnd_global.conc_request_id,
                                 12,
                                 ' ')
                         || '                                               Page: '
                         || TO_CHAR(1) );
            put_out_line();
            put_out_line();
            put_out_line(' ====================== Parameters ====================== ');
            put_out_line(   '    From Date:             '
                         || TO_CHAR(p_from_date,
                                    'DD-MON-YYYY') );
            put_out_line(   '    To Date:               '
                         || TO_CHAR(p_to_date,
                                    'DD-MON-YYYY') );
            put_out_line(   '    Which Process:         '
                         || p_which_process);
            put_out_line(   '    Request Id:            '
                         || p_request_id);
            put_out_line(   '    Receipt Method:        '
                         || gn_receipt_method);   -- Added for Defect 12289

            IF (NOT p_print_error_report)
            THEN
                put_out_line(   '    Orig Sys Document Ref: '
                             || p_orig_sys_document_ref);
                put_out_line(   '    Process Id:            '
                             || p_child_process_id);
            END IF;
        END IF;

        IF (NOT p_print_error_report)
        THEN
            put_out_line();
            put_out_line();
            put_out_line
                (' ========================================= Number of Records Fetched ============================================');
            put_out_line(   '    Create Deposit Receipts: '
                         || gn_create_deposits_num);
            put_out_line(   '    Create/Find Refund Original Receipts: '
                         || gn_create_refunds_num);
            put_out_line(   '    Apply Refund Original Rcpts to Credit Memos: '
                         || gn_apply_refunds_num);
            put_out_line();
            put_out_line();
            put_out_line
                (' ================================== Number of Records Successfully Processed ====================================');
            put_out_line(   '    Create Deposit Receipts: '
                         || gn_create_deposits_good);
            put_out_line(   '    Create/Find Refund Original Receipts: '
                         || gn_create_refunds_good);
            put_out_line(   '    Apply Refund Original Rcpts to Credit Memos: '
                         || gn_apply_refunds_good);
        END IF;

        put_out_line();
        put_out_line();

        IF (p_error_group_text IS NOT NULL)
        THEN
            put_out_line(p_error_group_text);
            put_out_line();
        END IF;

        put_out_line
            (' ======================================== Number of Records with Errors =========================================');
        put_out_line(   '    Create Deposit Receipts: '
                     || gn_create_deposits_err);
        put_out_line(   '    Create/Find Refund Original Receipts: '
                     || gn_create_refunds_err);
        put_out_line(   '    Apply Refund Original Rcpts to Credit Memos: '
                     || gn_apply_refunds_err);
        put_out_line();
        put_out_line();

        IF (g_create_deposits_recs.COUNT > 0)
        THEN
            put_out_line
                ('========================================= Create Deposit Receipts Details ==========================================');
            print_column_headings();

            FOR i_index IN g_create_deposits_recs.FIRST .. g_create_deposits_recs.LAST
            LOOP
                print_row_data(p_record_status_row =>      g_create_deposits_recs(i_index) );
            END LOOP;

            put_out_line();
            put_out_line();
        END IF;

        IF (g_create_refunds_recs.COUNT > 0)
        THEN
            put_out_line
                ('==================================== Create/Find Refund Original Receipts Details ==================================');
            print_column_headings();

            FOR i_index IN g_create_refunds_recs.FIRST .. g_create_refunds_recs.LAST
            LOOP
                print_row_data(p_record_status_row =>      g_create_refunds_recs(i_index) );
            END LOOP;

            put_out_line();
            put_out_line();
        END IF;

        IF (g_apply_refunds_recs.COUNT > 0)
        THEN
            put_out_line
                ('======================================= Apply Refund Original Receipts Details =====================================');
            print_column_headings();

            FOR i_index IN g_apply_refunds_recs.FIRST .. g_apply_refunds_recs.LAST
            LOOP
                print_row_data(p_record_status_row =>      g_apply_refunds_recs(i_index) );
            END LOOP;

            put_out_line();
            put_out_line();
        END IF;

        put_out_line();
        put_out_line();

        IF (p_print_end_of_report)
        THEN
            IF (NOT p_print_error_report)
            THEN
                put_out_line('Errors can be viewed in further detail on the concurrent program log file.');
                put_out_line();
            END IF;

            put_out_line();
            put_out_line();
            put_out_line('                                        *** End of Report *** ');
        END IF;
    END;

-- ==========================================================================
-- master concurrent program that runs all sub-programs for creating and
--   applying receipts
--   run by concurrent executable: XX_AR_CREATE_APPLY_RECEIPTS
-- ==========================================================================
    PROCEDURE master_program(
        x_error_buffer           OUT     VARCHAR2,
        x_return_code            OUT     NUMBER,
        p_org_id                 IN      NUMBER,
        p_from_date              IN      VARCHAR2 DEFAULT NULL,
        p_to_date                IN      VARCHAR2 DEFAULT NULL,
        p_which_process          IN      VARCHAR2 DEFAULT gc_process_all,
        p_request_id             IN      NUMBER DEFAULT NULL,
        p_orig_sys_document_ref  IN      VARCHAR2 DEFAULT NULL,
        p_child_process_id       IN      VARCHAR2 DEFAULT NULL)
    IS
        lc_sub_name       CONSTANT VARCHAR2(50) := 'MASTER_PROGRAM';
        ld_from_date               DATE         DEFAULT NULL;
        ld_to_date                 DATE         DEFAULT NULL;
        lc_only_deposit_reversals  VARCHAR2(1)  DEFAULT 'N';
    BEGIN
-- ==========================================================================
-- reset master program return code status (just in case)
--   and set program run date
-- ==========================================================================
        gn_return_code := 0;
        gd_program_run_date := SYSDATE;

-- ==========================================================================
-- Set debug based on the profile "OD: AR I1025 Debug Mode"
-- ==========================================================================
        IF (fnd_profile.VALUE('XX_AR_I1025_DEBUG_MODE') = 'Y')
        THEN
            set_debug(TRUE);
        ELSE
            set_debug(FALSE);
        END IF;

-- ==========================================================================
-- Set debug on in XX_AR_PREPAYMENTS_PKG when debug is on in this package.
-- ==========================================================================
        xx_ar_prepayments_pkg.set_debug(gb_debug);

-- ==========================================================================
-- Set global vars from profile values (for any errors, use default values)
-- ==========================================================================
        BEGIN
            gn_i1025_message_level := NVL(fnd_profile.VALUE('XX_AR_I1025_MESSAGE_LOGGING_LEVEL'),
                                          3);
        EXCEPTION
            WHEN OTHERS
            THEN
                gn_i1025_message_level := 3;
        END;

        BEGIN
            gn_refund_tolerance := NVL(fnd_profile.VALUE('XX_AR_I1025_REFUND_AMT_TOLERANCE'),
                                       0);
        EXCEPTION
            WHEN OTHERS
            THEN
                gn_refund_tolerance := 0;
        END;

        BEGIN
            gn_commit_interval := NVL(fnd_profile.VALUE('XX_AR_I1025_COMMIT_INTERVAL'),
                                      100);
        EXCEPTION
            WHEN OTHERS
            THEN
                gn_commit_interval := 100;
        END;

        IF (gb_debug)
        THEN
            put_log_line('Profile Values:');
            put_log_line(   '  XX_AR_I1025_DEBUG_MODE : '
                         || NVL(fnd_profile.VALUE('XX_AR_I1025_DEBUG_MODE'),
                                'N (default)') );
            put_log_line(   '  XX_AR_I1025_MESSAGE_LOGGING_LEVEL : '
                         || NVL(fnd_profile.VALUE('XX_AR_I1025_MESSAGE_LOGGING_LEVEL'),
                                '3 (default)') );
            put_log_line(   '  XX_AR_I1025_REFUND_AMT_TOLERANCE : '
                         || NVL(fnd_profile.VALUE('XX_AR_I1025_REFUND_AMT_TOLERANCE'),
                                '0.00 (default)') );
            put_log_line(   '  XX_AR_I1025_COMMIT_INTERVAL : '
                         || NVL(fnd_profile.VALUE('XX_AR_I1025_COMMIT_INTERVAL'),
                                '100 (default)') );
        END IF;

-- ==========================================================================
-- create data variable from date parameter (which is varchar2)
-- ==========================================================================
        ld_from_date := TRUNC(NVL(fnd_conc_date.string_to_date(p_from_date),
                                  SYSDATE) );
        ld_to_date := TRUNC(NVL(fnd_conc_date.string_to_date(p_to_date),
                                SYSDATE) );

        IF (gb_debug)
        THEN
            put_current_datetime();
        END IF;

-- ==========================================================================
-- create any pending deposit records that exist in XX_OM_LEGACY_DEPOSITS
-- ==========================================================================
        IF (p_which_process IN(gc_process_create_deposits, gc_process_resubmit_dpsts, gc_process_all) )
        THEN
            gn_cc_aops_deposits_num := 0;

-- ==========================================================================
-- If running the resubmit of deposit reversals, set the parameter to only
--   pull the deposits with negative amounts
-- ==========================================================================
            IF (p_which_process = gc_process_resubmit_dpsts)
            THEN
                lc_only_deposit_reversals := 'Y';
            ELSE
                lc_only_deposit_reversals := 'N';
            END IF;

            create_deposit_receipts(p_org_id =>                      p_org_id,
                                    p_from_date =>                   ld_from_date,
                                    p_to_date =>                     ld_to_date,
                                    p_request_id =>                  p_request_id,
                                    p_orig_sys_document_ref =>       p_orig_sys_document_ref,
                                    p_only_deposit_reversals =>      lc_only_deposit_reversals,
                                    p_child_process_id =>            p_child_process_id);

-- ==========================================================================
-- Fetch deposit AOPS orders for line level-3 order details for CC receipts
-- ==========================================================================
            IF (gn_cc_aops_deposits_num > 0)
            THEN
                submit_fetch_depst_aops_orders();
            END IF;

            IF (gb_debug)
            THEN
                put_log_separator();
                put_current_datetime();
            END IF;
        END IF;

-- ==========================================================================
-- create pending refund receipt records existing in XX_OM_RETURN_TENDERS_ALL
-- ==========================================================================
        IF (p_which_process IN(gc_process_create_refunds, gc_process_all) )
        THEN
            create_refund_receipts(p_org_id =>                     p_org_id,
                                   p_from_date =>                  ld_from_date,
                                   p_to_date =>                    ld_to_date,
                                   p_request_id =>                 p_request_id,
                                   p_orig_sys_document_ref =>      p_orig_sys_document_ref,
                                   p_child_process_id =>           p_child_process_id);

            IF (gb_debug)
            THEN
                put_log_separator();
                put_current_datetime();
            END IF;
        END IF;

-- ==========================================================================
-- apply all zero dollar receipts associated to the new credit memos
-- ==========================================================================
        IF (p_which_process IN(gc_process_apply_refunds, gc_process_all) )
        THEN
            apply_refund_receipts(p_org_id =>                     p_org_id,
                                  p_from_date =>                  ld_from_date,
                                  p_to_date =>                    ld_to_date,
                                  p_request_id =>                 p_request_id,
                                  p_orig_sys_document_ref =>      p_orig_sys_document_ref,
                                  p_child_process_id =>           p_child_process_id);

            IF (gb_debug)
            THEN
                put_log_separator();
                put_current_datetime();
            END IF;
        END IF;

-- ==========================================================================
-- commit any open work
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('- COMMIT any open work');
        END IF;

        COMMIT;
-- ==========================================================================
-- print a summary report of deposits/refunds processed
-- ==========================================================================
        print_summary_report(p_from_date =>                  ld_from_date,
                             p_to_date =>                    ld_to_date,
                             p_which_process =>              p_which_process,
                             p_request_id =>                 p_request_id,
                             p_orig_sys_document_ref =>      p_orig_sys_document_ref,
                             p_child_process_id =>           p_child_process_id,
                             p_print_error_report =>         FALSE,
                             p_print_heading =>              TRUE,
                             p_error_group_text =>           NULL,
                             p_print_end_of_report =>        TRUE);
-- ==========================================================================
-- set master program return code (all warnings and errors are logged in
--   the log file)
-- ==========================================================================
        x_return_code := gn_return_code;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_code := 2;
            x_error_buffer := SQLERRM;
            xx_com_error_log_pub.log_error(p_program_type =>                'CONCURRENT PROGRAM',
                                           p_program_name =>                'XX_AR_CREATE_APPLY_RECEIPTS',
                                           p_program_id =>                  fnd_global.conc_program_id,
                                           p_module_name =>                 'AR',
                                           p_error_location =>              'Error in Master Program',
                                           p_error_message_count =>         1,
                                           p_error_message_code =>          'E',
                                           p_error_message =>               SQLERRM,
                                           p_error_message_severity =>      'Major',
                                           p_notify_flag =>                 'N',
                                           p_object_type =>                 lc_sub_name);
            RAISE;
    END;

-- ==========================================================================
-- procedure called by the multi-thread master program to print summary report
-- ==========================================================================
    PROCEDURE print_multithread_report(
        p_from_date          IN  DATE,
        p_to_date            IN  DATE,
        p_which_process      IN  VARCHAR2 DEFAULT gc_process_all,
        p_request_id_from    IN  NUMBER DEFAULT NULL,
        p_request_id_to      IN  NUMBER DEFAULT NULL,
        p_number_of_batches  IN  NUMBER DEFAULT NULL)
    IS
    BEGIN
        put_out_line(   'Office Depot, Inc.                OD: AR I1025 Master Program          Date: '
                     || TO_CHAR(SYSDATE,
                                'DD-MON-YYYY HH24:MI:SS') );
        put_out_line(   'Request Id: '
                     || RPAD(fnd_global.conc_request_id,
                             12,
                             ' ')
                     || '                                               Page: '
                     || TO_CHAR(1) );
        put_out_line();
        put_out_line();
        put_out_line(' ===================== Parameters ======================== ');
        put_out_line(   '    From Date:             '
                     || TO_CHAR(p_from_date,
                                'DD-MON-YYYY') );
        put_out_line(   '    To Date:               '
                     || TO_CHAR(p_to_date,
                                'DD-MON-YYYY') );
        put_out_line(   '    Which Process:         '
                     || p_which_process);
        put_out_line(   '    From Request Id:       '
                     || p_request_id_from);
        put_out_line(   '    To Request Id:         '
                     || p_request_id_to);
        put_out_line(   '    Number of Batches:     '
                     || p_number_of_batches);
        put_out_line();
        put_out_line();
    END;

-- ==========================================================================
-- procedure that determines the I1025 child batch size (based on the params)
-- ==========================================================================
    PROCEDURE get_batch_size(
        p_number_of_batches   IN      NUMBER,
        p_record_count        IN      NUMBER,
        x_new_num_of_batches  OUT     NUMBER,
        x_batch_size          OUT     NUMBER)
    IS
        ln_new_num_of_batches  NUMBER DEFAULT NULL;
        ln_batch_size          NUMBER DEFAULT NULL;
    BEGIN
        IF (p_number_of_batches > p_record_count)
        THEN
            ln_new_num_of_batches := p_record_count;

            IF (gb_debug)
            THEN
                put_log_line(   '# Updating number of batches to: '
                             || ln_new_num_of_batches);
                put_log_line();
            END IF;
        ELSE
            ln_new_num_of_batches := p_number_of_batches;
        END IF;

        ln_batch_size := CEIL(  p_record_count
                              / ln_new_num_of_batches);

        IF (gb_debug)
        THEN
            put_log_line(   '# Number of Records per Batch: '
                         || ln_batch_size);
            put_log_line();
        END IF;

        x_new_num_of_batches := ln_new_num_of_batches;
        x_batch_size := ln_batch_size;
    END;

-- ==========================================================================
-- procedure that determines thread range for each child (based on params)
-- ==========================================================================
    PROCEDURE get_thread_range(
        p_current_number      IN             NUMBER,
        p_batch_size          IN             NUMBER,
        p_record_count        IN             NUMBER,
        x_new_num_of_batches  IN OUT NOCOPY  NUMBER,
        x_from_index          OUT            NUMBER,
        x_to_index            OUT            NUMBER,
        x_exit_flag           OUT            BOOLEAN)
    IS
        ln_from_index  NUMBER DEFAULT NULL;
        ln_to_index    NUMBER DEFAULT NULL;
    BEGIN
        ln_from_index :=   (   (  p_current_number
                                - 1)
                            * p_batch_size)
                         + 1;
        ln_to_index :=   p_current_number
                       * p_batch_size;

        IF (ln_to_index > p_record_count)
        THEN
            ln_to_index := p_record_count;
        END IF;

        IF (ln_from_index > ln_to_index)
        THEN
            x_new_num_of_batches := p_current_number;

            IF (gb_debug)
            THEN
                put_log_line(   '# Updated number of batches to: '
                             || x_new_num_of_batches);
                put_log_line();
            END IF;

            x_exit_flag := TRUE;
            RETURN;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'Index '
                         || p_current_number
                         || ': UPDATE records from '
                         || ln_from_index
                         || ' to '
                         || ln_to_index
                         || '.');
        END IF;

        x_from_index := ln_from_index;
        x_to_index := ln_to_index;
        x_exit_flag := FALSE;
    END;

-- ==========================================================================
-- master procedure that submits AR I1025 children (multi-threaded version)
-- ==========================================================================
    PROCEDURE multi_thread_master(
        x_error_buffer       OUT     VARCHAR2,
        x_return_code        OUT     NUMBER,
        p_org_id             IN      NUMBER,
        p_from_date          IN      VARCHAR2 DEFAULT NULL,
        p_to_date            IN      VARCHAR2 DEFAULT NULL,
        p_which_process      IN      VARCHAR2 DEFAULT gc_process_all,
        p_request_id_from    IN      NUMBER DEFAULT NULL,
        p_request_id_to      IN      NUMBER DEFAULT NULL,
        p_number_of_batches  IN      NUMBER DEFAULT NULL)
    IS
        lc_sub_name   CONSTANT VARCHAR2(50)  := 'MULTI_THREAD_MASTER';
        ld_from_date           DATE          DEFAULT NULL;
        ld_to_date             DATE          DEFAULT NULL;
        ln_batch_size          NUMBER        DEFAULT NULL;
        ln_conc_request_id     NUMBER        DEFAULT NULL;
        lc_i1025_process_id    VARCHAR2(20)  DEFAULT NULL;
        ln_from_index          NUMBER        DEFAULT NULL;
        ln_to_index            NUMBER        DEFAULT NULL;
        ln_number_of_batches   NUMBER        DEFAULT NULL;
        lb_exit_flag           BOOLEAN       DEFAULT NULL;
        ln_requests_submitted  NUMBER        DEFAULT NULL;
        ln_this_request_id     NUMBER        := fnd_global.conc_request_id;
        lc_request_data        VARCHAR2(240) := fnd_conc_global.request_data;

        CURSOR lcu_create_deposits(
            cp_org_id           IN  NUMBER,
            cp_from_date        IN  DATE,
            cp_to_date          IN  DATE,
            cp_request_id_from  IN  NUMBER,
            cp_request_id_to    IN  NUMBER)
        IS
            SELECT xold.ROWID
            FROM   xx_om_legacy_deposits xold
            WHERE  xold.i1025_status = 'NEW'
            AND    xold.cash_receipt_id IS NULL
            AND    xold.org_id = cp_org_id
            AND    xold.creation_date BETWEEN cp_from_date AND   cp_to_date
                                                               + 0.99999
            AND    xold.error_flag <> 'Y'   -- exclude deposits errored during HVOP
            AND    xold.request_id >= NVL(cp_request_id_from,
                                          xold.request_id)
            AND    xold.request_id <= NVL(cp_request_id_to,
                                          xold.request_id);

        CURSOR lcu_create_refunds(
            cp_org_id           IN  NUMBER,
            cp_from_date        IN  DATE,
            cp_to_date          IN  DATE,
            cp_request_id_from  IN  NUMBER,
            cp_request_id_to    IN  NUMBER)
        IS
            SELECT xort.ROWID
            FROM   xx_om_return_tenders_all xort
            WHERE  xort.i1025_status = 'NEW'
            AND    xort.cash_receipt_id IS NULL
            AND    xort.org_id = cp_org_id
            AND    xort.creation_date BETWEEN cp_from_date AND   cp_to_date
                                                               + 0.99999
            AND    xort.request_id >= NVL(cp_request_id_from,
                                          xort.request_id)
            AND    xort.request_id <= NVL(cp_request_id_to,
                                          xort.request_id);

        CURSOR lcu_apply_refunds(
            cp_org_id           IN  NUMBER,
            cp_from_date        IN  DATE,
            cp_to_date          IN  DATE,
            cp_request_id_from  IN  NUMBER,
            cp_request_id_to    IN  NUMBER)
        IS
            SELECT xort.ROWID
            FROM   ar_cash_receipts_all acr,
                   xx_om_return_tenders_all xort,
                   ra_customer_trx_all rct,
                   ar_payment_schedules_all aps,
                   ra_cust_trx_types_all rctt,
                   oe_order_headers_all ooh,
                   oe_transaction_types_tl ott
            WHERE  rct.cust_trx_type_id = rctt.cust_trx_type_id
            AND    ooh.order_type_id = ott.transaction_type_id
            AND    rct.customer_trx_id = aps.customer_trx_id
            AND    ooh.header_id = xort.header_id
            AND    acr.cash_receipt_id = xort.cash_receipt_id
            --AND rct.bill_to_customer_id = acr.pay_from_customer
            AND    rct.interface_header_context = fnd_profile.VALUE('SO_SOURCE_CODE')
            AND    rct.interface_header_attribute2 = ott.NAME
            AND    rct.interface_header_attribute1 = TO_CHAR(ooh.order_number)
            AND    acr.TYPE = 'CASH'
            AND    rct.status_trx = 'OP'
            --AND aps.class = 'CM'
            AND    aps.status = 'OP'
            AND    xort.i1025_status IN('CREATED_ZERO_DOLLAR', 'FOUND_ORIGINAL')
            AND    rct.org_id = cp_org_id
            AND    xort.creation_date BETWEEN cp_from_date AND   cp_to_date
                                                               + 0.99999
            AND    xort.request_id >= NVL(cp_request_id_from,
                                          xort.request_id)
            AND    xort.request_id <= NVL(cp_request_id_to,
                                          xort.request_id);

        TYPE lt_rowid_tab IS TABLE OF ROWID
            INDEX BY PLS_INTEGER;

        l_create_deposits      lt_rowid_tab;
        l_create_refunds       lt_rowid_tab;
        l_apply_refunds        lt_rowid_tab;
    BEGIN
-- ==========================================================================
-- Debug can always be on for parent request
-- ==========================================================================
        gb_debug := TRUE;
        gn_return_code := 0;
-- ==========================================================================
-- create data variable from date parameter (which is varchar2)
-- ==========================================================================
        put_log_line('- Set the date variables: ');
        ld_from_date := TRUNC(NVL(fnd_conc_date.string_to_date(p_from_date),
                                  SYSDATE) );
        ld_to_date := TRUNC(NVL(fnd_conc_date.string_to_date(p_to_date),
                                SYSDATE) );

-- ==========================================================================
-- if initial execution (first step)
-- ==========================================================================
        IF (NVL(lc_request_data,
                1) = 1)
        THEN
            IF (gb_debug)
            THEN
                put_log_line();
                put_log_line(   'BEGIN '
                             || lc_sub_name);
            END IF;

-- ==========================================================================
-- print to output the header and parameters
-- ==========================================================================
            print_multithread_report(p_from_date =>              ld_from_date,
                                     p_to_date =>                ld_to_date,
                                     p_which_process =>          p_which_process,
                                     p_request_id_from =>        p_request_id_from,
                                     p_request_id_to =>          p_request_id_to,
                                     p_number_of_batches =>      p_number_of_batches);

-- ==========================================================================
-- Validate the Number of Batches
-- ==========================================================================
            IF (NVL(p_number_of_batches,
                    0) <= 0)
            THEN
                raise_application_error(-20093,
                                        'Number of Batches "p_number_of_batches" must be greater than zero.');
            END IF;

-- ==========================================================================
-- Print all the profile option values
-- ==========================================================================
            IF (gb_debug)
            THEN
                put_log_line('Profile Values:');
                put_log_line(   '  XX_AR_I1025_DEBUG_MODE : '
                             || NVL(fnd_profile.VALUE('XX_AR_I1025_DEBUG_MODE'),
                                    'N (default)') );
                put_log_line(   '  XX_AR_I1025_MESSAGE_LOGGING_LEVEL : '
                             || NVL(fnd_profile.VALUE('XX_AR_I1025_MESSAGE_LOGGING_LEVEL'),
                                    '3 (default)') );
                put_log_line(   '  XX_AR_I1025_REFUND_AMT_TOLERANCE : '
                             || NVL(fnd_profile.VALUE('XX_AR_I1025_REFUND_AMT_TOLERANCE'),
                                    '0.00 (default)') );
                put_log_line(   '  XX_AR_I1025_COMMIT_INTERVAL : '
                             || NVL(fnd_profile.VALUE('XX_AR_I1025_COMMIT_INTERVAL'),
                                    '100 (default)') );
                put_log_line();
            END IF;

-- ==========================================================================
-- multi-threading not enabled for "Resubmit Deposit Reversals"
-- ==========================================================================
            IF (p_which_process = gc_process_resubmit_dpsts)
            THEN
                x_return_code := 1;
                x_error_buffer :=    'Multi-threading not enabled for "'
                                  || gc_process_resubmit_dpsts
                                  || '"';
                RETURN;
            END IF;
        END IF;

-- ==========================================================================
-- Execute the first step of this program (Submit Create Deposit children)
-- ==========================================================================
        IF (NVL(lc_request_data,
                1) = 1)
        THEN
            IF (gb_debug)
            THEN
                put_log_line(   'At Step '
                             || NVL(lc_request_data,
                                    1) );
                put_log_line();
            END IF;

            IF (p_which_process IN(gc_process_create_deposits, gc_process_all) )
            THEN
                IF (gb_debug)
                THEN
                    put_log_line('Submit the "Create Deposit Receipts" child programs.');
                    put_log_line();
                END IF;

                OPEN lcu_create_deposits(cp_org_id =>               p_org_id,
                                         cp_from_date =>            ld_from_date,
                                         cp_to_date =>              ld_to_date,
                                         cp_request_id_from =>      p_request_id_from,
                                         cp_request_id_to =>        p_request_id_to);

                FETCH lcu_create_deposits
                BULK COLLECT INTO l_create_deposits;

                CLOSE lcu_create_deposits;

                IF (gb_debug)
                THEN
                    put_log_line(   '# Number of "Create Deposit" Records: '
                                 || l_create_deposits.COUNT);
                    put_log_line(   '# Number of Batches Parameter: '
                                 || p_number_of_batches);
                    put_log_line();
                END IF;

                ln_requests_submitted := 0;

                IF (l_create_deposits.COUNT > 0)
                THEN
                    get_batch_size(p_number_of_batches =>       p_number_of_batches,
                                   p_record_count =>            l_create_deposits.COUNT,
                                   x_new_num_of_batches =>      ln_number_of_batches,
                                   x_batch_size =>              ln_batch_size);

                    FOR i_index IN 1 .. ln_number_of_batches
                    LOOP
                        get_thread_range(p_current_number =>          i_index,
                                         p_batch_size =>              ln_batch_size,
                                         p_record_count =>            l_create_deposits.COUNT,
                                         x_new_num_of_batches =>      ln_number_of_batches,
                                         x_from_index =>              ln_from_index,
                                         x_to_index =>                ln_to_index,
                                         x_exit_flag =>               lb_exit_flag);
                        EXIT WHEN lb_exit_flag;
                        lc_i1025_process_id :=    ln_this_request_id
                                               || '-'
                                               || i_index;

                        IF (gb_debug)
                        THEN
                            put_log_line(   'Generated new child process id: '
                                         || lc_i1025_process_id);
                            put_log_line();
                        END IF;

                        FORALL i_sel IN ln_from_index .. ln_to_index
                            UPDATE xx_om_legacy_deposits
                            SET i1025_process_id = lc_i1025_process_id
                            WHERE  ROWID = l_create_deposits(i_sel);

                        IF (gb_debug)
                        THEN
                            put_log_line(   '# Updated '
                                         || SQL%ROWCOUNT
                                         || ' XX_OM_LEGACY_DEPOSIT rows.');
                            put_log_line();
                        END IF;

                        ln_conc_request_id :=
                            fnd_request.submit_request(application =>      'XXFIN',   -- application short name
                                                       program =>          'XX_AR_CREATE_APPLY_RECEIPTS',
                                                       -- concurrent program name
                                                       description =>      'OD: AR I1025 - Create Deposits',
                                                       -- additional request description
                                                       start_time =>       NULL,   -- request submit time
                                                       sub_request =>      TRUE,   -- is this a sub-request?
                                                       argument1 =>        p_org_id,   -- Operating Unit (Org Id)
                                                       argument2 =>        p_from_date,   -- From Date
                                                       argument3 =>        p_to_date,   -- To Date
                                                       argument4 =>        gc_process_create_deposits,   -- Which Process
                                                       argument5 =>        NULL,   -- Request Id
                                                       argument6 =>        NULL,   -- Orig Sys Document Ref
                                                       argument7 =>        lc_i1025_process_id);   -- Child Process Id

-- ===========================================================================
-- check if request was successful, otherwise raise errors
-- ===========================================================================
                        IF (ln_conc_request_id > 0)
                        THEN
                            COMMIT;
                            ln_requests_submitted :=   ln_requests_submitted
                                                     + 1;

                            IF (gb_debug)
                            THEN
                                put_log_line(   '  - Submitted Concurrent Request ID: '
                                             || ln_conc_request_id
                                             || '.');
                                put_log_line();
                            END IF;
                        ELSE
                            fnd_message.raise_error;
                        END IF;
                    END LOOP;

                    IF (gb_debug)
                    THEN
                        put_log_line('Submitted all the "Create Deposit Receipts" child programs.');
                        put_log_line();
                    END IF;

                    put_out_line(' =============== Create Deposit Receipts ================= ');
                    put_out_line(   '    Number of Records: '
                                 || l_create_deposits.COUNT);
                    put_out_line(   '    Planned Number of Batches: '
                                 || p_number_of_batches);
                    put_out_line(   '    Actual Number of Batches: '
                                 || ln_number_of_batches);
                    put_out_line(   '    Batch Size: '
                                 || ln_batch_size);
                    put_out_line(   '    Number of Requests Submitted: '
                                 || ln_requests_submitted);
                    put_out_line();
                    put_out_line();
                    fnd_conc_global.set_req_globals(conc_status =>       'PAUSED',
                                                    request_data =>      2);
                    COMMIT;
                    RETURN;
                END IF;
            END IF;

            lc_request_data := 2;   -- continue to next step
        END IF;

-- ==========================================================================
-- Execute the 2nd step of this program (Submit Create Refund children)
-- ==========================================================================
        IF (NVL(lc_request_data,
                1) = 2)
        THEN
            IF (gb_debug)
            THEN
                put_log_line(   'At Step '
                             || lc_request_data);
                put_log_line();
            END IF;

            IF (p_which_process IN(gc_process_create_refunds, gc_process_all) )
            THEN
                IF (gb_debug)
                THEN
                    put_log_line('Submit the "Create Refund Receipts" child programs.');
                    put_log_line();
                END IF;

                OPEN lcu_create_refunds(cp_org_id =>               p_org_id,
                                        cp_from_date =>            ld_from_date,
                                        cp_to_date =>              ld_to_date,
                                        cp_request_id_from =>      p_request_id_from,
                                        cp_request_id_to =>        p_request_id_to);

                FETCH lcu_create_refunds
                BULK COLLECT INTO l_create_refunds;

                CLOSE lcu_create_refunds;

                IF (gb_debug)
                THEN
                    put_log_line(   '# Number of "Create Refund" Records: '
                                 || l_create_refunds.COUNT);
                    put_log_line(   '# Number of Batches Parameter: '
                                 || p_number_of_batches);
                    put_log_line();
                END IF;

                ln_requests_submitted := 0;

                IF (l_create_refunds.COUNT > 0)
                THEN
                    get_batch_size(p_number_of_batches =>       p_number_of_batches,
                                   p_record_count =>            l_create_refunds.COUNT,
                                   x_new_num_of_batches =>      ln_number_of_batches,
                                   x_batch_size =>              ln_batch_size);

                    FOR i_index IN 1 .. ln_number_of_batches
                    LOOP
                        get_thread_range(p_current_number =>          i_index,
                                         p_batch_size =>              ln_batch_size,
                                         p_record_count =>            l_create_refunds.COUNT,
                                         x_new_num_of_batches =>      ln_number_of_batches,
                                         -- num of batches limited by records
                                         x_from_index =>              ln_from_index,
                                         x_to_index =>                ln_to_index,
                                         x_exit_flag =>               lb_exit_flag);
                        EXIT WHEN lb_exit_flag;
                        lc_i1025_process_id :=    ln_this_request_id
                                               || '-'
                                               || i_index;

                        IF (gb_debug)
                        THEN
                            put_log_line(   'Generated new child process id: '
                                         || lc_i1025_process_id);
                            put_log_line();
                        END IF;

                        FORALL i_sel IN ln_from_index .. ln_to_index
                            UPDATE xx_om_return_tenders_all
                            SET i1025_process_id = lc_i1025_process_id
                            WHERE  ROWID = l_create_refunds(i_sel);

                        IF (gb_debug)
                        THEN
                            put_log_line(   '# Updated '
                                         || SQL%ROWCOUNT
                                         || ' XX_OM_RETURN_TENDERS_ALL rows.');
                            put_log_line();
                        END IF;

                        ln_conc_request_id :=
                            fnd_request.submit_request(application =>      'XXFIN',   -- application short name
                                                       program =>          'XX_AR_CREATE_APPLY_RECEIPTS',
                                                       -- concurrent program name
                                                       description =>      'OD: AR I1025 - Create Refunds',
                                                       -- additional request description
                                                       start_time =>       NULL,   -- request submit time
                                                       sub_request =>      TRUE,   -- is this a sub-request?
                                                       argument1 =>        p_org_id,   -- Operating Unit (Org Id)
                                                       argument2 =>        p_from_date,   -- From Date
                                                       argument3 =>        p_to_date,   -- To Date
                                                       argument4 =>        gc_process_create_refunds,   -- Which Process
                                                       argument5 =>        NULL,   -- Request Id
                                                       argument6 =>        NULL,   -- Orig Sys Document Ref
                                                       argument7 =>        lc_i1025_process_id);   -- Child Process Id

-- ===========================================================================
-- check if request was successful, otherwise raise errors
-- ===========================================================================
                        IF (ln_conc_request_id > 0)
                        THEN
                            COMMIT;
                            ln_requests_submitted :=   ln_requests_submitted
                                                     + 1;

                            IF (gb_debug)
                            THEN
                                put_log_line(   '  - Submitted Concurrent Request ID: '
                                             || ln_conc_request_id
                                             || '.');
                                put_log_line();
                            END IF;
                        ELSE
                            fnd_message.raise_error;
                        END IF;
                    END LOOP;

                    IF (gb_debug)
                    THEN
                        put_log_line('Submitted all the "Create Refund Receipts" child programs.');
                        put_log_line();
                    END IF;

                    put_out_line(' ========= Create/Find Refund Original Receipts ========== ');
                    put_out_line(   '    Number of Records: '
                                 || l_create_refunds.COUNT);
                    put_out_line(   '    Planned Number of Batches: '
                                 || p_number_of_batches);
                    put_out_line(   '    Actual Number of Batches: '
                                 || ln_number_of_batches);
                    put_out_line(   '    Batch Size: '
                                 || ln_batch_size);
                    put_out_line(   '    Number of Requests Submitted: '
                                 || ln_requests_submitted);
                    put_out_line();
                    put_out_line();
                    fnd_conc_global.set_req_globals(conc_status =>       'PAUSED',
                                                    request_data =>      3);
                    COMMIT;
                    RETURN;
                END IF;
            END IF;

            lc_request_data := 3;   -- continue to next step
        END IF;

-- ==========================================================================
-- Execute the 3rd step of this program (Submit Apply Refund children)
-- ==========================================================================
        IF (NVL(lc_request_data,
                1) = 3)
        THEN
            IF (gb_debug)
            THEN
                put_log_line(   'At Step '
                             || lc_request_data);
                put_log_line();
            END IF;

            IF (p_which_process IN(gc_process_apply_refunds, gc_process_all) )
            THEN
                IF (gb_debug)
                THEN
                    put_log_line('Submit the "Apply Refund Receipts" child programs.');
                    put_log_line();
                END IF;

                OPEN lcu_apply_refunds(cp_org_id =>               p_org_id,
                                       cp_from_date =>            ld_from_date,
                                       cp_to_date =>              ld_to_date,
                                       cp_request_id_from =>      p_request_id_from,
                                       cp_request_id_to =>        p_request_id_to);

                FETCH lcu_apply_refunds
                BULK COLLECT INTO l_apply_refunds;

                CLOSE lcu_apply_refunds;

                IF (gb_debug)
                THEN
                    put_log_line(   '# Number of "Apply Refund" Records: '
                                 || l_apply_refunds.COUNT);
                    put_log_line(   '# Number of Batches Parameter: '
                                 || p_number_of_batches);
                    put_log_line();
                END IF;

                ln_requests_submitted := 0;

                IF (l_apply_refunds.COUNT > 0)
                THEN
                    get_batch_size(p_number_of_batches =>       p_number_of_batches,
                                   p_record_count =>            l_apply_refunds.COUNT,
                                   x_new_num_of_batches =>      ln_number_of_batches,
                                   x_batch_size =>              ln_batch_size);

                    FOR i_index IN 1 .. ln_number_of_batches
                    LOOP
                        get_thread_range(p_current_number =>          i_index,
                                         p_batch_size =>              ln_batch_size,
                                         p_record_count =>            l_apply_refunds.COUNT,
                                         x_new_num_of_batches =>      ln_number_of_batches,
                                         -- num of batches limited by records
                                         x_from_index =>              ln_from_index,
                                         x_to_index =>                ln_to_index,
                                         x_exit_flag =>               lb_exit_flag);
                        EXIT WHEN lb_exit_flag;
                        lc_i1025_process_id :=    ln_this_request_id
                                               || '-'
                                               || i_index;

                        IF (gb_debug)
                        THEN
                            put_log_line(   'Generated new child process id: '
                                         || lc_i1025_process_id);
                            put_log_line();
                        END IF;

                        FORALL i_sel IN ln_from_index .. ln_to_index
                            UPDATE xx_om_return_tenders_all
                            SET i1025_process_id = lc_i1025_process_id
                            WHERE  ROWID = l_apply_refunds(i_sel);

                        IF (gb_debug)
                        THEN
                            put_log_line(   '# Updated '
                                         || SQL%ROWCOUNT
                                         || ' XX_OM_RETURN_TENDERS_ALL rows.');
                            put_log_line();
                        END IF;

                        ln_conc_request_id :=
                            fnd_request.submit_request(application =>      'XXFIN',   -- application short name
                                                       program =>          'XX_AR_CREATE_APPLY_RECEIPTS',
                                                       -- concurrent program name
                                                       description =>      'OD: AR I1025 - Apply Refunds',
                                                       -- additional request description
                                                       start_time =>       NULL,   -- request submit time
                                                       sub_request =>      TRUE,   -- is this a sub-request?
                                                       argument1 =>        p_org_id,   -- Operating Unit (Org Id)
                                                       argument2 =>        p_from_date,   -- From Date
                                                       argument3 =>        p_to_date,   -- To Date
                                                       argument4 =>        gc_process_apply_refunds,   -- Which Process
                                                       argument5 =>        NULL,   -- Request Id
                                                       argument6 =>        NULL,   -- Orig Sys Document Ref
                                                       argument7 =>        lc_i1025_process_id);   -- Child Process Id

-- ===========================================================================
-- check if request was successful, otherwise raise errors
-- ===========================================================================
                        IF (ln_conc_request_id > 0)
                        THEN
                            COMMIT;
                            ln_requests_submitted :=   ln_requests_submitted
                                                     + 1;

                            IF (gb_debug)
                            THEN
                                put_log_line(   '  - Submitted Concurrent Request ID: '
                                             || ln_conc_request_id
                                             || '.');
                                put_log_line();
                            END IF;
                        ELSE
                            fnd_message.raise_error;
                        END IF;
                    END LOOP;

                    IF (gb_debug)
                    THEN
                        put_log_line('Submitted all the "Apply Refund Receipts" child programs.');
                        put_log_line();
                    END IF;

                    put_out_line(' ====== Apply Refund Original Rcpts to Credit Memos ====== ');
                    put_out_line(   '    Number of Records: '
                                 || l_apply_refunds.COUNT);
                    put_out_line(   '    Planned Number of Batches: '
                                 || p_number_of_batches);
                    put_out_line(   '    Actual Number of Batches: '
                                 || ln_number_of_batches);
                    put_out_line(   '    Batch Size: '
                                 || ln_batch_size);
                    put_out_line(   '    Number of Requests Submitted: '
                                 || ln_requests_submitted);
                    put_out_line();
                    put_out_line();
                    fnd_conc_global.set_req_globals(conc_status =>       'PAUSED',
                                                    request_data =>      4);
                    COMMIT;
                    RETURN;
                END IF;
            END IF;

            lc_request_data := 4;   -- continue to next step
        END IF;

        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('Submitted all child requests successfully.');
            put_log_line();
        END IF;

-- ==========================================================================
-- set master program return code (all warnings and errors are logged in
--   the log file)
-- ==========================================================================
        x_return_code := gn_return_code;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_code := 2;
            x_error_buffer := SQLERRM;
            xx_com_error_log_pub.log_error(p_program_type =>                'CONCURRENT PROGRAM',
                                           p_program_name =>                'XX_AR_I1025_MASTER',
                                           p_program_id =>                  fnd_global.conc_program_id,
                                           p_module_name =>                 'AR',
                                           p_error_location =>              'Error in Multi-Thread Master Program',
                                           p_error_message_count =>         1,
                                           p_error_message_code =>          'E',
                                           p_error_message =>               SQLERRM,
                                           p_error_message_severity =>      'Major',
                                           p_notify_flag =>                 'N',
                                           p_object_type =>                 lc_sub_name);
            RAISE;
    END;

-- ==========================================================================
-- procedure to print all errored deposit/refund records
-- ==========================================================================
    PROCEDURE print_error_report(
        x_error_buffer       OUT     VARCHAR2,
        x_return_code        OUT     NUMBER,
        p_org_id             IN      NUMBER,   -- org_id is no longer used as both US and CA are printed
        p_from_date          IN      VARCHAR2 DEFAULT NULL,
        p_to_date            IN      VARCHAR2 DEFAULT NULL,
        p_which_process      IN      VARCHAR2 DEFAULT gc_process_all,
        p_request_id         IN      NUMBER DEFAULT NULL,
        p_receipt_method_id  IN      NUMBER DEFAULT NULL)   -- Added for Defect 12289
    IS
        lc_sub_name       CONSTANT VARCHAR2(50) := 'PRINT_ERROR_REPORT';
        ld_from_date               DATE         DEFAULT NULL;
        ld_to_date                 DATE         DEFAULT NULL;
        lc_only_deposit_reversals  VARCHAR2(1)  DEFAULT 'N';
        ln_org_id                  NUMBER       DEFAULT NULL;

        CURSOR lcu_create_deposits(
            cp_org_id                  IN  NUMBER,
            cp_from_date               IN  DATE,
            cp_to_date                 IN  DATE,
            cp_request_id              IN  NUMBER,
            cp_only_deposit_reversals  IN  VARCHAR2 DEFAULT 'N',
            cp_receipt_method_id       IN  NUMBER)   -- Added for Defect 12289
        IS
            SELECT CASE
                       WHEN xold.error_flag = 'Y'
                           THEN 'Errors occured during HVOP.  Deposit will not be processed by AR I1025.'
                       ELSE xold.i1025_message
                   END i1025_message,
-- Defect 20281 Change start
                   NVL(xold.orig_sys_document_ref,
                       DECODE(NVL(xold.single_pay_ind,
                                  'N'),
                              'N', (SELECT orig_sys_document_ref
                                    FROM   xx_om_legacy_dep_dtls xoldd1
                                    WHERE  xoldd1.transaction_number = xold.transaction_number
                                    AND    ROWNUM = 1),
--xold.orig_sys_document_ref   -- commented by Gaurav to pass xold.transaction_number as xold.orig_sys_document_ref in case of single payment.
                              xold.transaction_number) ) orig_sys_document_ref,
                   
-- Defect 20281 Change End
                   (SELECT order_number
                    FROM   oe_order_headers_all
                    WHERE  orig_sys_document_ref = xold.orig_sys_document_ref) order_number,
                   xold.payment_number,
                   xold.creation_date,
                   arm.NAME receipt_method,
                   xold.prepaid_amount amount,
                   acr.receipt_number
            FROM   xx_om_legacy_deposits xold, ar_receipt_methods arm, ar_cash_receipts_all acr
            WHERE  xold.cash_receipt_id = acr.cash_receipt_id(+)
            AND    xold.receipt_method_id = arm.receipt_method_id(+)
            AND    xold.i1025_status = 'NEW'
            AND    xold.process_code = 'E'
            AND    xold.org_id = cp_org_id
            AND    xold.creation_date BETWEEN cp_from_date AND   cp_to_date
                                                               + 0.99999
            --AND xold.error_flag <> 'Y'
            AND    (    (cp_only_deposit_reversals = 'N')
                    OR (    cp_only_deposit_reversals = 'Y'
                        AND xold.prepaid_amount < 0) )
            AND    (    (cp_request_id IS NULL)
                    OR (    cp_request_id IS NOT NULL
                        AND xold.request_id = cp_request_id) )
            AND    arm.receipt_method_id = NVL(cp_receipt_method_id,
                                               arm.receipt_method_id);   -- Added for Defect 12289

        CURSOR lcu_create_refunds(
            cp_org_id             IN  NUMBER,
            cp_from_date          IN  DATE,
            cp_to_date            IN  DATE,
            cp_request_id         IN  NUMBER,
            cp_receipt_method_id  IN  NUMBER)   -- Added for Defect 12289
        IS
            SELECT xort.i1025_message,
                   xort.orig_sys_document_ref,
                   (SELECT order_number
                    FROM   oe_order_headers_all
                    WHERE  orig_sys_document_ref = xort.orig_sys_document_ref) order_number,
                   xort.payment_number,
                   xort.creation_date,
                   arm.NAME receipt_method,
                   xort.credit_amount amount,
                   acr.receipt_number
            FROM   xx_om_return_tenders_all xort, ar_receipt_methods arm, ar_cash_receipts_all acr
            WHERE  xort.cash_receipt_id = acr.cash_receipt_id(+)
            AND    xort.receipt_method_id = arm.receipt_method_id(+)
            AND    xort.i1025_status = 'NEW'
            AND    xort.process_code = 'E'
            AND    xort.org_id = cp_org_id
            AND    xort.creation_date BETWEEN cp_from_date AND   cp_to_date
                                                               + 0.99999
            AND    (    (cp_request_id IS NULL)
                    OR (    cp_request_id IS NOT NULL
                        AND xort.request_id = cp_request_id) )
            AND    arm.receipt_method_id = NVL(cp_receipt_method_id,
                                               arm.receipt_method_id);   -- Added for Defect 12289

        CURSOR lcu_apply_refunds(
            cp_org_id             IN  NUMBER,
            cp_from_date          IN  DATE,
            cp_to_date            IN  DATE,
            cp_request_id         IN  NUMBER,
            cp_receipt_method_id  IN  NUMBER)   -- Added for Defect 12289
        IS
            SELECT xort.i1025_message,
                   xort.orig_sys_document_ref,
                   ooh.order_number,
                   xort.payment_number,
                   xort.creation_date,
                   arm.NAME receipt_method,
                   xort.credit_amount amount,
                   acr.receipt_number
            FROM   xx_om_return_tenders_all xort,
                   ar_cash_receipts_all acr,
                   ar_receipt_methods arm,
                   ra_customer_trx_all rct,
                   ar_payment_schedules_all aps,
                   ra_cust_trx_types_all rctt,
                   oe_order_headers_all ooh,
                   oe_transaction_types_tl ott
            WHERE  rct.cust_trx_type_id = rctt.cust_trx_type_id
            AND    ooh.order_type_id = ott.transaction_type_id
            AND    rct.customer_trx_id = aps.customer_trx_id
            AND    ooh.header_id = xort.header_id
            AND    xort.cash_receipt_id = acr.cash_receipt_id
            AND    xort.receipt_method_id = arm.receipt_method_id
            --AND rct.bill_to_customer_id = acr.pay_from_customer
            AND    rct.interface_header_context = fnd_profile.VALUE('SO_SOURCE_CODE')
            AND    rct.interface_header_attribute2 = ott.NAME
            AND    rct.interface_header_attribute1 = TO_CHAR(ooh.order_number)
            AND    acr.TYPE = 'CASH'
            AND    rct.status_trx = 'OP'
            --AND aps.class = 'CM'
            AND    aps.status = 'OP'
            AND    xort.i1025_status IN('CREATED_ZERO_DOLLAR', 'FOUND_ORIGINAL')
            AND    xort.process_code = 'E'
            AND    rct.org_id = cp_org_id
            AND    xort.creation_date BETWEEN cp_from_date AND   cp_to_date
                                                               + 0.99999
            AND    (    (cp_request_id IS NULL)
                    OR (    cp_request_id IS NOT NULL
                        AND xort.request_id = cp_request_id) )
            AND    arm.receipt_method_id = NVL(cp_receipt_method_id,
                                               arm.receipt_method_id);   -- Added for Defect 12289

        TYPE t_record_tab IS TABLE OF lcu_create_deposits%ROWTYPE
            INDEX BY PLS_INTEGER;

        l_create_deposits          t_record_tab;
        l_create_refunds           t_record_tab;
        l_apply_refunds            t_record_tab;
    BEGIN
        -- Added for Defect 12289
        IF (p_receipt_method_id IS NOT NULL)
        THEN
            SELECT NAME
            INTO   gn_receipt_method
            FROM   ar_receipt_methods
            WHERE  receipt_method_id = p_receipt_method_id;
        ELSE
            gn_receipt_method := NULL;
        END IF;

-- ==========================================================================
-- Debug can always be on for report
-- ==========================================================================
        gb_debug := TRUE;
        gn_return_code := 0;
-- ==========================================================================
-- create data variable from date parameter (which is varchar2)
-- ==========================================================================
        put_log_line('- Set the date variables: ');
        ld_from_date := TRUNC(NVL(fnd_conc_date.string_to_date(p_from_date),
                                  SYSDATE) );
        ld_to_date := TRUNC(NVL(fnd_conc_date.string_to_date(p_to_date),
                                SYSDATE) );
        put_log_line('- Input Parameters: ');
        put_log_line(   '- From Date: '
                     || ld_from_date);
        put_log_line(   '- To Date: '
                     || ld_to_date);
-- ==========================================================================
-- clear out all the global variables
-- ==========================================================================
        gn_create_deposits_err := 0;
        gn_create_refunds_err := 0;
        gn_apply_refunds_err := 0;
        g_create_deposits_recs.DELETE;
        g_create_refunds_recs.DELETE;
        g_apply_refunds_recs.DELETE;
        ln_org_id := xx_fin_country_defaults_pkg.f_org_id('US');

-- ==========================================================================
-- print out the errors for US
-- ==========================================================================
        IF (p_which_process IN(gc_process_create_deposits, gc_process_resubmit_dpsts, gc_process_all) )
        THEN
            IF (p_which_process = gc_process_resubmit_dpsts)
            THEN
                lc_only_deposit_reversals := 'Y';
            ELSE
                lc_only_deposit_reversals := 'N';
            END IF;

            OPEN lcu_create_deposits(cp_org_id =>                      ln_org_id,
                                     cp_from_date =>                   ld_from_date,
                                     cp_to_date =>                     ld_to_date,
                                     cp_request_id =>                  p_request_id,
                                     cp_only_deposit_reversals =>      lc_only_deposit_reversals,
                                     cp_receipt_method_id =>           p_receipt_method_id);   -- Added for Defect 12289

            FETCH lcu_create_deposits
            BULK COLLECT INTO l_create_deposits;

            CLOSE lcu_create_deposits;

            IF (l_create_deposits.COUNT > 0)
            THEN
                FOR i IN l_create_deposits.FIRST .. l_create_deposits.LAST
                LOOP
                    gn_create_deposits_err :=   gn_create_deposits_err
                                              + 1;
                    g_create_deposits_recs(i) := NULL;
                    g_create_deposits_recs(i).process_code := 'E';
                    g_create_deposits_recs(i).record_status := 'Error';
                    g_create_deposits_recs(i).MESSAGE := l_create_deposits(i).i1025_message;
                    g_create_deposits_recs(i).orig_sys_document_ref := l_create_deposits(i).orig_sys_document_ref;
                    g_create_deposits_recs(i).order_number := l_create_deposits(i).order_number;
                    g_create_deposits_recs(i).payment_number := l_create_deposits(i).payment_number;
                    g_create_deposits_recs(i).creation_date := l_create_deposits(i).creation_date;
                    g_create_deposits_recs(i).receipt_method := l_create_deposits(i).receipt_method;
                    g_create_deposits_recs(i).amount := l_create_deposits(i).amount;
                    g_create_deposits_recs(i).receipt_number := l_create_deposits(i).receipt_number;
                    g_create_deposits_recs(i).comments := NULL;
                END LOOP;
            END IF;
        END IF;

        IF (p_which_process IN(gc_process_create_refunds, gc_process_all) )
        THEN
            OPEN lcu_create_refunds(cp_org_id =>                 ln_org_id,
                                    cp_from_date =>              ld_from_date,
                                    cp_to_date =>                ld_to_date,
                                    cp_request_id =>             p_request_id,
                                    cp_receipt_method_id =>      p_receipt_method_id);   -- Added for Defect 12289

            FETCH lcu_create_refunds
            BULK COLLECT INTO l_create_refunds;

            CLOSE lcu_create_refunds;

            IF (l_create_refunds.COUNT > 0)
            THEN
                FOR i IN l_create_refunds.FIRST .. l_create_refunds.LAST
                LOOP
                    gn_create_refunds_err :=   gn_create_refunds_err
                                             + 1;
                    g_create_refunds_recs(i) := NULL;
                    g_create_refunds_recs(i).process_code := 'E';
                    g_create_refunds_recs(i).record_status := 'Error';
                    g_create_refunds_recs(i).MESSAGE := l_create_refunds(i).i1025_message;
                    g_create_refunds_recs(i).orig_sys_document_ref := l_create_refunds(i).orig_sys_document_ref;
                    g_create_refunds_recs(i).order_number := l_create_refunds(i).order_number;
                    g_create_refunds_recs(i).payment_number := l_create_refunds(i).payment_number;
                    g_create_refunds_recs(i).creation_date := l_create_refunds(i).creation_date;
                    g_create_refunds_recs(i).receipt_method := l_create_refunds(i).receipt_method;
                    g_create_refunds_recs(i).amount := l_create_refunds(i).amount;
                    g_create_refunds_recs(i).receipt_number := l_create_refunds(i).receipt_number;
                    g_create_refunds_recs(i).comments := NULL;
                END LOOP;
            END IF;
        END IF;

        IF (p_which_process IN(gc_process_apply_refunds, gc_process_all) )
        THEN
            OPEN lcu_apply_refunds(cp_org_id =>                 ln_org_id,
                                   cp_from_date =>              ld_from_date,
                                   cp_to_date =>                ld_to_date,
                                   cp_request_id =>             p_request_id,
                                   cp_receipt_method_id =>      p_receipt_method_id);   -- Added for Defect 12289

            FETCH lcu_apply_refunds
            BULK COLLECT INTO l_apply_refunds;

            CLOSE lcu_apply_refunds;

            IF (l_apply_refunds.COUNT > 0)
            THEN
                FOR i IN l_apply_refunds.FIRST .. l_apply_refunds.LAST
                LOOP
                    gn_apply_refunds_err :=   gn_apply_refunds_err
                                            + 1;
                    g_apply_refunds_recs(i) := NULL;
                    g_apply_refunds_recs(i).process_code := 'E';
                    g_apply_refunds_recs(i).record_status := 'Error';
                    g_apply_refunds_recs(i).MESSAGE := l_apply_refunds(i).i1025_message;
                    g_apply_refunds_recs(i).orig_sys_document_ref := l_apply_refunds(i).orig_sys_document_ref;
                    g_apply_refunds_recs(i).order_number := l_apply_refunds(i).order_number;
                    g_apply_refunds_recs(i).payment_number := l_apply_refunds(i).payment_number;
                    g_apply_refunds_recs(i).creation_date := l_apply_refunds(i).creation_date;
                    g_apply_refunds_recs(i).receipt_method := l_apply_refunds(i).receipt_method;
                    g_apply_refunds_recs(i).amount := l_apply_refunds(i).amount;
                    g_apply_refunds_recs(i).receipt_number := l_apply_refunds(i).receipt_number;
                    g_apply_refunds_recs(i).comments := NULL;
                END LOOP;
            END IF;
        END IF;

-- ==========================================================================
-- print a summary report of deposits/refunds processed
-- ==========================================================================
        print_summary_report(p_from_date =>                  ld_from_date,
                             p_to_date =>                    ld_to_date,
                             p_which_process =>              p_which_process,
                             p_request_id =>                 p_request_id,
                             p_orig_sys_document_ref =>      NULL,
                             p_child_process_id =>           NULL,
                             p_print_error_report =>         TRUE,
                             p_print_heading =>              TRUE,
                             p_error_group_text =>           '================== Operating Unit:  US ================== ',
                             p_print_end_of_report =>        FALSE);
-- ==========================================================================
-- clear out all the global variables
-- ==========================================================================
        gn_create_deposits_err := 0;
        gn_create_refunds_err := 0;
        gn_apply_refunds_err := 0;
        g_create_deposits_recs.DELETE;
        g_create_refunds_recs.DELETE;
        g_apply_refunds_recs.DELETE;
        ln_org_id := xx_fin_country_defaults_pkg.f_org_id('CA');

-- ==========================================================================
-- print out the errors for CA
-- ==========================================================================
        IF (p_which_process IN(gc_process_create_deposits, gc_process_resubmit_dpsts, gc_process_all) )
        THEN
            IF (p_which_process = gc_process_resubmit_dpsts)
            THEN
                lc_only_deposit_reversals := 'Y';
            ELSE
                lc_only_deposit_reversals := 'N';
            END IF;

            OPEN lcu_create_deposits(cp_org_id =>                      ln_org_id,
                                     cp_from_date =>                   ld_from_date,
                                     cp_to_date =>                     ld_to_date,
                                     cp_request_id =>                  p_request_id,
                                     cp_only_deposit_reversals =>      lc_only_deposit_reversals,
                                     cp_receipt_method_id =>           p_receipt_method_id);   -- Added for Defect 12289

            FETCH lcu_create_deposits
            BULK COLLECT INTO l_create_deposits;

            CLOSE lcu_create_deposits;

            IF (l_create_deposits.COUNT > 0)
            THEN
                FOR i IN l_create_deposits.FIRST .. l_create_deposits.LAST
                LOOP
                    gn_create_deposits_err :=   gn_create_deposits_err
                                              + 1;
                    g_create_deposits_recs(i) := NULL;
                    g_create_deposits_recs(i).process_code := 'E';
                    g_create_deposits_recs(i).record_status := 'Error';
                    g_create_deposits_recs(i).MESSAGE := l_create_deposits(i).i1025_message;
                    g_create_deposits_recs(i).orig_sys_document_ref := l_create_deposits(i).orig_sys_document_ref;
                    g_create_deposits_recs(i).order_number := l_create_deposits(i).order_number;
                    g_create_deposits_recs(i).payment_number := l_create_deposits(i).payment_number;
                    g_create_deposits_recs(i).creation_date := l_create_deposits(i).creation_date;
                    g_create_deposits_recs(i).receipt_method := l_create_deposits(i).receipt_method;
                    g_create_deposits_recs(i).amount := l_create_deposits(i).amount;
                    g_create_deposits_recs(i).receipt_number := l_create_deposits(i).receipt_number;
                    g_create_deposits_recs(i).comments := NULL;
                END LOOP;
            END IF;
        END IF;

        IF (p_which_process IN(gc_process_create_refunds, gc_process_all) )
        THEN
            OPEN lcu_create_refunds(cp_org_id =>                 ln_org_id,
                                    cp_from_date =>              ld_from_date,
                                    cp_to_date =>                ld_to_date,
                                    cp_request_id =>             p_request_id,
                                    cp_receipt_method_id =>      p_receipt_method_id);   -- Added for Defect 12289

            FETCH lcu_create_refunds
            BULK COLLECT INTO l_create_refunds;

            CLOSE lcu_create_refunds;

            IF (l_create_refunds.COUNT > 0)
            THEN
                FOR i IN l_create_refunds.FIRST .. l_create_refunds.LAST
                LOOP
                    gn_create_refunds_err :=   gn_create_refunds_err
                                             + 1;
                    g_create_refunds_recs(i) := NULL;
                    g_create_refunds_recs(i).process_code := 'E';
                    g_create_refunds_recs(i).record_status := 'Error';
                    g_create_refunds_recs(i).MESSAGE := l_create_refunds(i).i1025_message;
                    g_create_refunds_recs(i).orig_sys_document_ref := l_create_refunds(i).orig_sys_document_ref;
                    g_create_refunds_recs(i).order_number := l_create_refunds(i).order_number;
                    g_create_refunds_recs(i).payment_number := l_create_refunds(i).payment_number;
                    g_create_refunds_recs(i).creation_date := l_create_refunds(i).creation_date;
                    g_create_refunds_recs(i).receipt_method := l_create_refunds(i).receipt_method;
                    g_create_refunds_recs(i).amount := l_create_refunds(i).amount;
                    g_create_refunds_recs(i).receipt_number := l_create_refunds(i).receipt_number;
                    g_create_refunds_recs(i).comments := NULL;
                END LOOP;
            END IF;
        END IF;

        IF (p_which_process IN(gc_process_apply_refunds, gc_process_all) )
        THEN
            OPEN lcu_apply_refunds(cp_org_id =>                 ln_org_id,
                                   cp_from_date =>              ld_from_date,
                                   cp_to_date =>                ld_to_date,
                                   cp_request_id =>             p_request_id,
                                   cp_receipt_method_id =>      p_receipt_method_id);   -- Added for Defect 12289

            FETCH lcu_apply_refunds
            BULK COLLECT INTO l_apply_refunds;

            CLOSE lcu_apply_refunds;

            IF (l_apply_refunds.COUNT > 0)
            THEN
                FOR i IN l_apply_refunds.FIRST .. l_apply_refunds.LAST
                LOOP
                    gn_apply_refunds_err :=   gn_apply_refunds_err
                                            + 1;
                    g_apply_refunds_recs(i) := NULL;
                    g_apply_refunds_recs(i).process_code := 'E';
                    g_apply_refunds_recs(i).record_status := 'Error';
                    g_apply_refunds_recs(i).MESSAGE := l_apply_refunds(i).i1025_message;
                    g_apply_refunds_recs(i).orig_sys_document_ref := l_apply_refunds(i).orig_sys_document_ref;
                    g_apply_refunds_recs(i).order_number := l_apply_refunds(i).order_number;
                    g_apply_refunds_recs(i).payment_number := l_apply_refunds(i).payment_number;
                    g_apply_refunds_recs(i).creation_date := l_apply_refunds(i).creation_date;
                    g_apply_refunds_recs(i).receipt_method := l_apply_refunds(i).receipt_method;
                    g_apply_refunds_recs(i).amount := l_apply_refunds(i).amount;
                    g_apply_refunds_recs(i).receipt_number := l_apply_refunds(i).receipt_number;
                    g_apply_refunds_recs(i).comments := NULL;
                END LOOP;
            END IF;
        END IF;

-- ==========================================================================
-- print a summary report of deposits/refunds processed
-- ==========================================================================
        print_summary_report(p_from_date =>                  ld_from_date,
                             p_to_date =>                    ld_to_date,
                             p_which_process =>              p_which_process,
                             p_request_id =>                 p_request_id,
                             p_orig_sys_document_ref =>      NULL,
                             p_child_process_id =>           NULL,
                             p_print_error_report =>         TRUE,
                             p_print_heading =>              FALSE,
                             p_error_group_text =>           '================== Operating Unit:  CA ================== ',
                             p_print_end_of_report =>        TRUE);
-- ==========================================================================
-- return success
-- ==========================================================================
        x_return_code := 0;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_code := 2;
            x_error_buffer := SQLERRM;
            xx_com_error_log_pub.log_error(p_program_type =>                'CONCURRENT PROGRAM',
                                           p_program_name =>                'XX_AR_I1025_ERROR_REPORT',
                                           p_program_id =>                  fnd_global.conc_program_id,
                                           p_module_name =>                 'AR',
                                           p_error_location =>              'Error in AR I1025 Error Report',
                                           p_error_message_count =>         1,
                                           p_error_message_code =>          'E',
                                           p_error_message =>               SQLERRM,
                                           p_error_message_severity =>      'Major',
                                           p_notify_flag =>                 'N',
                                           p_object_type =>                 lc_sub_name);
            RAISE;
    END;

-- ==========================================================================
-- procedure used by unprocessed records report to print report header
-- ==========================================================================
    PROCEDURE print_unproc_recs_header(
        p_from_date   IN  DATE,
        p_to_date     IN  DATE,
        p_request_id  IN  NUMBER DEFAULT NULL)
    IS
    BEGIN
        put_out_line(   'Office Depot, Inc.           OD: AR I1025 - Unprocessed Deposits/Refunds         Date: '
                     || TO_CHAR(SYSDATE,
                                'DD-MON-YYYY HH24:MI:SS') );
        put_out_line(   'Request Id: '
                     || RPAD(fnd_global.conc_request_id,
                             12,
                             ' ')
                     || '                                                         Page: '
                     || TO_CHAR(1) );
        put_out_line();
        put_out_line(' ====================== Parameters ====================== ');
        put_out_line(   '    From Date:             '
                     || TO_CHAR(p_from_date,
                                'DD-MON-YYYY') );
        put_out_line(   '    To Date:               '
                     || TO_CHAR(p_to_date,
                                'DD-MON-YYYY') );
        put_out_line(   '    Request Id:            '
                     || p_request_id);
        put_out_line(   '    Receipt Method:        '
                     || gn_receipt_method);   -- Added for Defect 12289
        put_out_line();
    END;

-- ==========================================================================
-- procedure used by unprocessed records report to print column headings
-- ==========================================================================
    PROCEDURE print_unproc_recs_headings
    IS
    BEGIN
        put_out_line(   RPAD('Status',
                             20)
                     || RPAD('Legacy Order',
                             22)
                     || RPAD('Order Number',
                             14)
                     || RPAD('Trx Number',
                             14)
                     || RPAD('Pmt',
                             4)
                     || RPAD('Created',
                             10)
                     || RPAD('Receipt Method',
                             22)
                     || LPAD('Amount',
                             12)
                     || RPAD(' Receipt Num',
                             13)
                     || RPAD(' OM Errs',
                             8) );
        put_out_line(   RPAD('===================',
                             20)
                     || RPAD('=====================',
                             22)
                     || RPAD('=============',
                             14)
                     || RPAD('=============',
                             14)
                     || RPAD('===',
                             4)
                     || RPAD('=========',
                             10)
                     || RPAD('=====================',
                             22)
                     || LPAD('============',
                             12)
                     || RPAD(' ============',
                             13)
                     || RPAD(' =======',
                             8) );
    END;

-- ==========================================================================
-- procedure used by unprocessed records report to print data
-- ==========================================================================
/* PROCEDURE print_unproc_recs_data
( p_current_row     IN     GT_REC_STATUS )
IS
BEGIN
put_out_line
(  RPAD(NVL(p_current_row.I1025_status,' '),8)
|| RPAD(NVL(p_current_row.orig_sys_document_ref,' '),22)
|| RPAD(NVL(TO_CHAR(p_current_row.order_number),' '),14)
|| RPAD(NVL(TO_CHAR(p_current_row.trx_number),' '),14)
|| RPAD(NVL(TO_CHAR(p_current_row.payment_number),' '),4)
|| RPAD(NVL(TO_CHAR(p_current_row.creation_date,'DD-MON-RR'),' '),10)
|| RPAD(NVL(p_current_row.receipt_method,' '),22)
|| LPAD(NVL(TO_CHAR(p_current_row.amount,'$999,990.00'),' '),12)
|| ' ' || RPAD(NVL(p_current_row.receipt_number,' '),13)
|| RPAD(NVL(TO_CHAR(p_current_row.om_error_flag),' '),8) );
END; */
-- ==========================================================================
-- procedure to print all unprocessed deposit/refund records
-- ==========================================================================
    PROCEDURE print_unprocessed_report(
        x_error_buffer       OUT     VARCHAR2,
        x_return_code        OUT     NUMBER,
        p_org_id             IN      NUMBER,   -- org_id is no longer used as both US and CA are printed
        p_from_date          IN      VARCHAR2 DEFAULT NULL,
        p_to_date            IN      VARCHAR2 DEFAULT NULL,
        p_request_id         IN      NUMBER DEFAULT NULL,
        p_receipt_method_id  IN      NUMBER DEFAULT NULL)   -- Added for Defect 12289
    IS
        lc_sub_name       CONSTANT VARCHAR2(50)               := 'PRINT_UNPROCESSED_REPORT';
        ld_from_date               DATE                       DEFAULT NULL;
        ld_to_date                 DATE                       DEFAULT NULL;
        lc_only_deposit_reversals  VARCHAR2(1)                DEFAULT 'N';
        ln_org_id                  NUMBER                     DEFAULT NULL;
        ln_unproc_deposits_amt     NUMBER                     DEFAULT 0;
        ln_unproc_refunds_amt      NUMBER                     DEFAULT 0;

        CURSOR lcu_unprocessed_deposits(
            cp_org_id             IN  NUMBER,
            cp_from_date          IN  DATE,
            cp_to_date            IN  DATE,
            cp_request_id         IN  NUMBER,
            cp_receipt_method_id  IN  NUMBER)   -- Added for Defect 12889
        IS
            SELECT   /*+ ORDERED */
                     xold.i1025_status,
                     xold.orig_sys_document_ref,
                     (SELECT order_number
                      FROM   oe_order_headers_all
                      WHERE  orig_sys_document_ref = xold.orig_sys_document_ref) order_number,
                     NULL trx_number,
                     xold.payment_number,
                     xold.creation_date,
                     arm.NAME receipt_method,
                     xold.prepaid_amount amount,
                     acr.receipt_number,
                     xold.error_flag om_error_flag
            FROM     xx_om_legacy_deposits xold,
                     ar_receipt_methods arm,
                     ar_cash_receipts_all acr,
                     ar_payment_schedules_all aps
            WHERE    xold.cash_receipt_id = acr.cash_receipt_id(+)
            AND      xold.receipt_method_id = arm.receipt_method_id(+)
            AND      acr.cash_receipt_id = aps.cash_receipt_id(+)
            AND      xold.org_id = cp_org_id
            AND      xold.process_code <> 'E'
            AND      (    (xold.i1025_status = 'NEW')
                      OR (    xold.i1025_status = 'CREATED_DEPOSIT'
                          AND EXISTS   -- if deposit has not been processed, even though order exists
                                    (SELECT 1
                                     FROM   oe_order_headers_all
                                     WHERE  orig_sys_document_ref = xold.orig_sys_document_ref)
                          AND EXISTS   -- if deposit has not been processed, and receipt is still open
                                    (SELECT 1
                                     FROM   ar_payment_schedules_all
                                     WHERE  cash_receipt_id = xold.cash_receipt_id
                                     AND    amount_due_remaining <> 0) ) )
            AND      xold.creation_date BETWEEN cp_from_date AND   cp_to_date
                                                                 + 0.99999   -- Added for Defect 12289
            AND      arm.receipt_method_id = NVL(cp_receipt_method_id,
                                                 arm.receipt_method_id)   -- Added for Defect 12289
            ORDER BY xold.error_flag,   -- put those with OM error_flag of Y first
                                     TRUNC(xold.creation_date), xold.orig_sys_document_ref, xold.payment_number;

        TYPE t_unprocessed_deposits_tab IS TABLE OF lcu_unprocessed_deposits%ROWTYPE
            INDEX BY PLS_INTEGER;

        l_unprocessed_deposits     t_unprocessed_deposits_tab;

        CURSOR lcu_unprocessed_refunds(
            cp_org_id             IN  NUMBER,
            cp_from_date          IN  DATE,
            cp_to_date            IN  DATE,
            cp_request_id         IN  NUMBER,
            cp_receipt_method_id  IN  NUMBER)   -- Added for Defect 12889
        IS
            SELECT   /*+ ORDERED */
                     xort.i1025_status,
                     xort.orig_sys_document_ref,
                     ooh.order_number,
                     rct.trx_number,
                     xort.payment_number,
                     xort.creation_date,
                     arm.NAME receipt_method,
                     xort.credit_amount amount,
                     acr.receipt_number,
                     'N' om_error_flag
            FROM     xx_om_return_tenders_all xort,
                     ar_receipt_methods arm,
                     ar_cash_receipts_all acr,
                     ar_payment_schedules_all aps,
                     oe_order_headers_all ooh,
                     --oe_transaction_types_tl ott,
                     ra_customer_trx_all rct,
                     ar_payment_schedules_all aps2
            WHERE    xort.cash_receipt_id = acr.cash_receipt_id(+)
            AND      xort.receipt_method_id = arm.receipt_method_id(+)
            AND      acr.cash_receipt_id = aps.cash_receipt_id(+)
            AND      xort.header_id = ooh.header_id
            --AND ooh.order_type_id = ott.transaction_type_id
            AND      rct.customer_trx_id = aps2.customer_trx_id(+)
            AND      rct.interface_header_context(+) = 'ORDER ENTRY'   --FND_PROFILE.value('SO_SOURCE_CODE')
            --AND rct.interface_header_attribute2(+) = ott.name
            AND      rct.interface_header_attribute1(+) = TO_CHAR(ooh.order_number)
            AND      xort.org_id = cp_org_id
            AND      xort.process_code <> 'E'
            AND      (    (xort.i1025_status = 'NEW')
                      OR (xort.i1025_status IN('CREATED_ZERO_DOLLAR', 'FOUND_ORIGINAL') ) )
            AND      xort.creation_date BETWEEN cp_from_date AND   cp_to_date
                                                                 + 0.99999   -- Added for Defect 12289
            AND      arm.receipt_method_id = NVL(cp_receipt_method_id,
                                                 arm.receipt_method_id)   -- Added for Defect 12289
            ORDER BY TRUNC(xort.creation_date), xort.orig_sys_document_ref, xort.payment_number;

        TYPE t_unprocessed_refunds_tab IS TABLE OF lcu_unprocessed_refunds%ROWTYPE
            INDEX BY PLS_INTEGER;

        l_unprocessed_refunds      t_unprocessed_refunds_tab;
    BEGIN
        -- Added for Defect 12289
        IF (p_receipt_method_id IS NOT NULL)
        THEN
            SELECT NAME
            INTO   gn_receipt_method
            FROM   ar_receipt_methods
            WHERE  receipt_method_id = p_receipt_method_id;
        ELSE
            gn_receipt_method := NULL;
        END IF;

-- ==========================================================================
-- create data variable from date parameter (which is varchar2)
-- ==========================================================================
        put_log_line('- Set the date variables: ');
        ld_from_date := TRUNC(NVL(fnd_conc_date.string_to_date(p_from_date),
                                  SYSDATE) );
        ld_to_date := TRUNC(NVL(fnd_conc_date.string_to_date(p_to_date),
                                SYSDATE) );
        put_log_line('- Input Parameters: ');
        put_log_line(   '- From Date: '
                     || ld_from_date);
        put_log_line(   '- To Date: '
                     || ld_to_date);
        print_unproc_recs_header(p_from_date =>       ld_from_date,
                                 p_to_date =>         ld_to_date,
                                 p_request_id =>      p_request_id);
-- ==========================================================================
-- get org id for US
-- ==========================================================================
        ln_org_id := xx_fin_country_defaults_pkg.f_org_id('US');

-- ==========================================================================
-- get all unprocessed deposits for US
-- ==========================================================================
        OPEN lcu_unprocessed_deposits(cp_org_id =>                 ln_org_id,
                                      cp_from_date =>              ld_from_date,
                                      cp_to_date =>                ld_to_date,
                                      cp_request_id =>             p_request_id,
                                      cp_receipt_method_id =>      p_receipt_method_id);   -- Added for Defect 12289

        FETCH lcu_unprocessed_deposits
        BULK COLLECT INTO l_unprocessed_deposits;

        CLOSE lcu_unprocessed_deposits;

-- ==========================================================================
-- print out all unprocessed deposits
-- ==========================================================================
        IF (l_unprocessed_deposits.COUNT > 0)
        THEN
            put_out_line(' ================= Unprocessed Deposits (Operating Unit: US) ================= ');
            put_out_line();
            print_unproc_recs_headings();
            ln_unproc_deposits_amt := 0;

            FOR i IN l_unprocessed_deposits.FIRST .. l_unprocessed_deposits.LAST
            LOOP
                -- put gap between those with OM Error Flag of Y and of N
                IF (i > 1)
                THEN
                    IF (l_unprocessed_deposits(  i
                                               - 1).om_error_flag <> l_unprocessed_deposits(i).om_error_flag)
                    THEN
                        put_out_line();
                        put_out_line();
                    END IF;
                END IF;

                put_out_line(   RPAD(NVL(l_unprocessed_deposits(i).i1025_status,
                                         ' '),
                                     20)
                             || RPAD(NVL(l_unprocessed_deposits(i).orig_sys_document_ref,
                                         ' '),
                                     22)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).order_number),
                                         ' '),
                                     14)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).trx_number),
                                         ' '),
                                     14)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).payment_number),
                                         ' '),
                                     4)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).creation_date,
                                                 'DD-MON-RR'),
                                         ' '),
                                     10)
                             || RPAD(NVL(l_unprocessed_deposits(i).receipt_method,
                                         ' '),
                                     22)
                             || LPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).amount,
                                                 '$999,990.00'),
                                         ' '),
                                     12)
                             || ' '
                             || RPAD(NVL(l_unprocessed_deposits(i).receipt_number,
                                         ' '),
                                     13)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).om_error_flag),
                                         ' '),
                                     8) );
                ln_unproc_deposits_amt :=   ln_unproc_deposits_amt
                                          + l_unprocessed_deposits(i).amount;
            END LOOP;
        END IF;

        put_out_line();
        put_out_line(   '   Total Number of US Unprocessed Deposits:  '
                     || LPAD(TO_CHAR(NVL(l_unprocessed_deposits.COUNT,
                                         0),
                                     '9,999,999,990'),
                             15) );
        put_out_line(   '   Total Amount of US Unprocessed Deposits:  '
                     || LPAD(TO_CHAR(NVL(ln_unproc_deposits_amt,
                                         0),
                                     '$99,999,990.00'),
                             15) );
        put_out_line();
        put_out_line();
        put_out_line();

-- ==========================================================================
-- get all unprocessed refunds
-- ==========================================================================
        OPEN lcu_unprocessed_refunds(cp_org_id =>                 ln_org_id,
                                     cp_from_date =>              ld_from_date,
                                     cp_to_date =>                ld_to_date,
                                     cp_request_id =>             p_request_id,
                                     cp_receipt_method_id =>      p_receipt_method_id);   -- Added for Defect 12289

        FETCH lcu_unprocessed_refunds
        BULK COLLECT INTO l_unprocessed_refunds;

        CLOSE lcu_unprocessed_refunds;

-- ==========================================================================
-- print out all unprocessed refunds
-- ==========================================================================
        IF (l_unprocessed_refunds.COUNT > 0)
        THEN
            put_out_line(' ================= Unprocessed Refunds (Operating Unit: US) ================== ');
            put_out_line();
            print_unproc_recs_headings();

            FOR i IN l_unprocessed_refunds.FIRST .. l_unprocessed_refunds.LAST
            LOOP
                put_out_line(   RPAD(NVL(l_unprocessed_refunds(i).i1025_status,
                                         ' '),
                                     20)
                             || RPAD(NVL(l_unprocessed_refunds(i).orig_sys_document_ref,
                                         ' '),
                                     22)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).order_number),
                                         ' '),
                                     14)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).trx_number),
                                         ' '),
                                     14)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).payment_number),
                                         ' '),
                                     4)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).creation_date,
                                                 'DD-MON-RR'),
                                         ' '),
                                     10)
                             || RPAD(NVL(l_unprocessed_refunds(i).receipt_method,
                                         ' '),
                                     22)
                             || LPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).amount,
                                                 '$999,990.00'),
                                         ' '),
                                     12)
                             || ' '
                             || RPAD(NVL(l_unprocessed_refunds(i).receipt_number,
                                         ' '),
                                     13)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).om_error_flag),
                                         ' '),
                                     8) );
                ln_unproc_refunds_amt :=   ln_unproc_refunds_amt
                                         + l_unprocessed_refunds(i).amount;
            END LOOP;
        END IF;

        put_out_line();
        put_out_line(   '   Total Number of US Unprocessed Refunds:  '
                     || LPAD(TO_CHAR(NVL(l_unprocessed_refunds.COUNT,
                                         0),
                                     '9,999,999,990'),
                             15) );
        put_out_line(   '   Total Amount of US Unprocessed Refunds:  '
                     || LPAD(TO_CHAR(NVL(ln_unproc_refunds_amt,
                                         0),
                                     '$99,999,990.00'),
                             15) );
        put_out_line();
        put_out_line();
        put_out_line(   '====================================================================='
                     || '=====================================================================');
        put_out_line();
        put_out_line();
-- ==========================================================================
-- get org id for CA
-- ==========================================================================
        ln_org_id := xx_fin_country_defaults_pkg.f_org_id('CA');

-- ==========================================================================
-- get all unprocessed deposits for CA
-- ==========================================================================
        OPEN lcu_unprocessed_deposits(cp_org_id =>                 ln_org_id,
                                      cp_from_date =>              ld_from_date,
                                      cp_to_date =>                ld_to_date,
                                      cp_request_id =>             p_request_id,
                                      cp_receipt_method_id =>      p_receipt_method_id);   -- Added for Defect 12289

        FETCH lcu_unprocessed_deposits
        BULK COLLECT INTO l_unprocessed_deposits;

        CLOSE lcu_unprocessed_deposits;

        ln_unproc_deposits_amt := 0;   --Resetted for the Defect 12289

-- ==========================================================================
-- print out all unprocessed deposits
-- ==========================================================================
        IF (l_unprocessed_deposits.COUNT > 0)
        THEN
            put_out_line(' ================= Unprocessed Deposits (Operating Unit: CA) ================= ');
            put_out_line();
            print_unproc_recs_headings();
            ln_unproc_deposits_amt := 0;

            FOR i IN l_unprocessed_deposits.FIRST .. l_unprocessed_deposits.LAST
            LOOP
                -- put gap between those with OM Error Flag of Y and of N
                IF (i > 1)
                THEN
                    IF (l_unprocessed_deposits(  i
                                               - 1).om_error_flag <> l_unprocessed_deposits(i).om_error_flag)
                    THEN
                        put_out_line();
                        put_out_line();
                    END IF;
                END IF;

                put_out_line(   RPAD(NVL(l_unprocessed_deposits(i).i1025_status,
                                         ' '),
                                     20)
                             || RPAD(NVL(l_unprocessed_deposits(i).orig_sys_document_ref,
                                         ' '),
                                     22)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).order_number),
                                         ' '),
                                     14)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).trx_number),
                                         ' '),
                                     14)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).payment_number),
                                         ' '),
                                     4)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).creation_date,
                                                 'DD-MON-RR'),
                                         ' '),
                                     10)
                             || RPAD(NVL(l_unprocessed_deposits(i).receipt_method,
                                         ' '),
                                     22)
                             || LPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).amount,
                                                 '$999,990.00'),
                                         ' '),
                                     12)
                             || ' '
                             || RPAD(NVL(l_unprocessed_deposits(i).receipt_number,
                                         ' '),
                                     13)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_deposits(i).om_error_flag),
                                         ' '),
                                     8) );
                ln_unproc_deposits_amt :=   ln_unproc_deposits_amt
                                          + l_unprocessed_deposits(i).amount;
            END LOOP;
        END IF;

        put_out_line();
        put_out_line(   '   Total Number of CA Unprocessed Deposits:  '
                     || LPAD(TO_CHAR(NVL(l_unprocessed_deposits.COUNT,
                                         0),
                                     '9,999,999,990'),
                             15) );
        put_out_line(   '   Total Amount of CA Unprocessed Deposits:  '
                     || LPAD(TO_CHAR(NVL(ln_unproc_deposits_amt,
                                         0),
                                     '$99,999,990.00'),
                             15) );
        put_out_line();
        put_out_line();
        put_out_line();

-- ==========================================================================
-- get all unprocessed refunds
-- ==========================================================================
        OPEN lcu_unprocessed_refunds(cp_org_id =>                 ln_org_id,
                                     cp_from_date =>              ld_from_date,
                                     cp_to_date =>                ld_to_date,
                                     cp_request_id =>             p_request_id,
                                     cp_receipt_method_id =>      p_receipt_method_id);   -- Added for Defect 12289

        FETCH lcu_unprocessed_refunds
        BULK COLLECT INTO l_unprocessed_refunds;

        CLOSE lcu_unprocessed_refunds;

        ln_unproc_refunds_amt := 0;   -- Resetted for the Defect 12289

-- ==========================================================================
-- print out all unprocessed refunds
-- ==========================================================================
        IF (l_unprocessed_refunds.COUNT > 0)
        THEN
            put_out_line(' ================= Unprocessed Refunds (Operating Unit: CA) ================== ');
            put_out_line();
            print_unproc_recs_headings();
            ln_unproc_refunds_amt := 0;

            FOR i IN l_unprocessed_refunds.FIRST .. l_unprocessed_refunds.LAST
            LOOP
                put_out_line(   RPAD(NVL(l_unprocessed_refunds(i).i1025_status,
                                         ' '),
                                     20)
                             || RPAD(NVL(l_unprocessed_refunds(i).orig_sys_document_ref,
                                         ' '),
                                     22)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).order_number),
                                         ' '),
                                     14)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).trx_number),
                                         ' '),
                                     14)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).payment_number),
                                         ' '),
                                     4)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).creation_date,
                                                 'DD-MON-RR'),
                                         ' '),
                                     10)
                             || RPAD(NVL(l_unprocessed_refunds(i).receipt_method,
                                         ' '),
                                     22)
                             || LPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).amount,
                                                 '$999,990.00'),
                                         ' '),
                                     12)
                             || ' '
                             || RPAD(NVL(l_unprocessed_refunds(i).receipt_number,
                                         ' '),
                                     13)
                             || RPAD(NVL(TO_CHAR(l_unprocessed_refunds(i).om_error_flag),
                                         ' '),
                                     8) );
                ln_unproc_refunds_amt :=   ln_unproc_refunds_amt
                                         + l_unprocessed_refunds(i).amount;
            END LOOP;
        END IF;

        put_out_line();
        put_out_line(   '   Total Number of CA Unprocessed Refunds:  '
                     || LPAD(TO_CHAR(NVL(l_unprocessed_refunds.COUNT,
                                         0),
                                     '9,999,999,990'),
                             15) );
        put_out_line(   '   Total Amount of CA Unprocessed Refunds:  '
                     || LPAD(TO_CHAR(NVL(ln_unproc_refunds_amt,
                                         0),
                                     '$99,999,990.00'),
                             15) );
        put_out_line();
        put_out_line();
        put_out_line();
        put_out_line();
        put_out_line('                                        *** End of Report *** ');
-- ==========================================================================
-- return success
-- ==========================================================================
        x_return_code := 0;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_code := 2;
            x_error_buffer := SQLERRM;
            xx_com_error_log_pub.log_error(p_program_type =>                'CONCURRENT PROGRAM',
                                           p_program_name =>                'XX_AR_I1025_UNPROCESSED_REPORT',
                                           p_program_id =>                  fnd_global.conc_program_id,
                                           p_module_name =>                 'AR',
                                           p_error_location =>              'Error in AR I1025 Unprocessed Report',
                                           p_error_message_count =>         1,
                                           p_error_message_code =>          'E',
                                           p_error_message =>               SQLERRM,
                                           p_error_message_severity =>      'Major',
                                           p_notify_flag =>                 'N',
                                           p_object_type =>                 lc_sub_name);
            RAISE;
    END;

-- Added BY NB FOR 12i UPGRADE
-- ==========================================================================
-- Function to get country code
-- ==========================================================================
    FUNCTION get_country_code(
        p_org_id  IN  NUMBER)
        RETURN VARCHAR2
    IS
        lc_country_code  VARCHAR2(80);
    BEGIN
        SELECT SUBSTR(NAME,
                      4,
                      2)
        INTO   lc_country_code
        FROM   hr_operating_units
        WHERE  organization_id = p_org_id;

        RETURN(lc_country_code);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN(NULL);
        WHEN OTHERS
        THEN
            RETURN(NULL);
    END get_country_code;
END;
/