REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=pls \
REM dbdrv: checkfile:~PROD:~PATH:~FILE

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

/* $Header: ARXPRELS.pls 115.23.15104.2 2006/02/27 13:04:45 naneja ship $    */
 ---+============================================================================================+
---|                              Office Depot - Project Simplify                               |
---|                                   Wipro Technologies                                       |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : XX_AR_RECEIPT_LIB_PVT.pks                                             |
---|                                                                                            |
---|    Description     : Added a hint for performance to                                       |
---|                      get_site_use_id cursor of Default_trx_info                            |
---|                      procedure. Original filename: ARXPRELS.pls                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             08-Apr-2009       Ranjith Prabu      Hint added to get_site_use_id      |
---|                                                         cursor of Default_trx_info         |
-- |                                                         procedure - Defect# 13970          |
---+============================================================================================+
CREATE OR REPLACE PACKAGE ar_receipt_lib_pvt  AS
/* $Header: ARXPRELS.pls 115.23.15104.2 2006/02/27 13:04:45 naneja ship $    */
--These package variables contain the profile option values.
pg_profile_doc_seq             VARCHAR2(240);
pg_profile_enable_cc           VARCHAR2(240);
pg_profile_appln_gl_date_def   VARCHAR2(240);
pg_profile_amt_applied_def     VARCHAR2(240);
pg_profile_cc_rate_type        VARCHAR2(240);
pg_profile_dsp_inv_rate        VARCHAR2(240);
pg_profile_create_bk_charges   VARCHAR2(240);
pg_profile_def_x_rate_type     VARCHAR2(240);

pg_cust_derived_from           VARCHAR2(20);
PROCEDURE Default_cash_ids(
              p_usr_currency_code           IN  fnd_currencies_vl.name%TYPE,
              p_usr_exchange_rate_type      IN  gl_daily_conversion_types.user_conversion_type%TYPE,
              p_customer_name               IN  hz_parties.party_name%TYPE,
              p_customer_number             IN  hz_cust_accounts.account_number%TYPE,
              p_location                    IN  hz_cust_site_uses.location%type,
              p_receipt_method_name         IN  OUT NOCOPY ar_receipt_methods.name%TYPE,
              p_customer_bank_account_name  IN  ap_bank_accounts.bank_account_name%TYPE,
              p_customer_bank_account_num   IN  ap_bank_accounts.bank_account_num%TYPE,
              p_remittance_bank_account_name IN  ap_bank_accounts.bank_account_name%TYPE,
              p_remittance_bank_account_num IN  ap_bank_accounts.bank_account_num%TYPE,
              p_currency_code               IN OUT NOCOPY ar_cash_receipts.currency_code%TYPE,
              p_exchange_rate_type          IN OUT NOCOPY ar_cash_receipts.exchange_rate_type%TYPE,
              p_customer_id                 IN OUT NOCOPY ar_cash_receipts.pay_from_customer%TYPE,
              p_customer_site_use_id        IN OUT NOCOPY hz_cust_site_uses.site_use_id%TYPE,
              p_receipt_method_id           IN OUT NOCOPY ar_cash_receipts.receipt_method_id%TYPE,
              p_customer_bank_account_id    IN OUT NOCOPY ar_cash_receipts.customer_bank_account_id%TYPE,
              p_remittance_bank_account_id  IN OUT NOCOPY ar_cash_receipts.remittance_bank_account_id%TYPE,
              p_receipt_date                IN  DATE,
              p_return_status               OUT NOCOPY VARCHAR2,
              p_default_site_use            IN VARCHAR2  /* Bug 5059320 and 5053864 are merged require one off 4448307 as pre-req*/
                  );


PROCEDURE Get_Cash_Defaults(
              p_currency_code      IN OUT NOCOPY ar_cash_receipts.currency_code%TYPE,
              p_exchange_rate_type IN OUT NOCOPY ar_cash_receipts.exchange_rate_type%TYPE,
              p_exchange_rate      IN OUT NOCOPY ar_cash_receipts.exchange_rate%TYPE,
              p_exchange_rate_date IN OUT NOCOPY ar_cash_receipts.exchange_date%TYPE,
              p_amount             IN OUT NOCOPY ar_cash_receipts.amount%TYPE,
              p_factor_discount_amount IN OUT NOCOPY ar_cash_receipts.factor_discount_amount%TYPE,
              p_receipt_date       IN  OUT NOCOPY ar_cash_receipts.receipt_date%TYPE,
              p_gl_date            IN  OUT NOCOPY DATE,
              p_maturity_date      IN  OUT NOCOPY DATE,
              p_customer_receipt_reference       IN OUT NOCOPY ar_cash_receipts.customer_receipt_reference%TYPE,
              p_override_remit_account_flag      IN OUT NOCOPY ar_cash_receipts.override_remit_account_flag%TYPE,
              p_remittance_bank_account_id       IN OUT NOCOPY ar_cash_receipts.remittance_bank_account_id%TYPE,
              p_deposit_date                     IN OUT NOCOPY ar_cash_receipts.deposit_date%TYPE,
              p_receipt_method_id                IN OUT NOCOPY ar_cash_receipts.receipt_method_id%TYPE,
              p_state                               OUT NOCOPY ar_receipt_classes.creation_status%TYPE,
              p_anticipated_clearing_date        IN OUT NOCOPY ar_cash_receipts.anticipated_clearing_date%TYPE,
              p_called_from                      IN     VARCHAR2,
              p_creation_method_code                OUT NOCOPY ar_receipt_classes.creation_method_code%TYPE,
              p_return_status                       OUT NOCOPY VARCHAR2
           );

/* Bug fix  3395686 : Added two new parameters p_customer_trx_line_id and p_line_number */

PROCEDURE Default_appln_ids(
              p_cash_receipt_id   IN OUT NOCOPY NUMBER,
              p_receipt_number    IN VARCHAR2,
              p_customer_trx_id   IN OUT NOCOPY NUMBER,
              p_trx_number        IN VARCHAR2,
              p_customer_trx_line_id IN OUT NOCOPY NUMBER,
              p_line_number       IN NUMBER,
              p_installment       IN OUT NOCOPY NUMBER,
              p_applied_payment_schedule_id IN NUMBER,
              p_return_status     OUT NOCOPY VARCHAR2);

PROCEDURE Default_application_info(
              p_cash_receipt_id       IN ar_cash_receipts.cash_receipt_id%TYPE,
              p_cr_gl_date            OUT NOCOPY DATE,
              p_cr_date               OUT NOCOPY DATE,
              p_cr_amount             OUT NOCOPY ar_cash_receipts.amount%TYPE,
              p_cr_unapp_amount       OUT NOCOPY NUMBER,
              p_cr_currency_code      OUT NOCOPY VARCHAR2,
              p_customer_trx_id       IN ra_customer_trx.customer_trx_id%TYPE,
              p_installment           IN OUT NOCOPY NUMBER,
              p_show_closed_invoices  IN VARCHAR2,
              p_customer_trx_line_id  IN NUMBER,
              p_trx_due_date          OUT NOCOPY DATE,
              p_trx_currency_code     OUT NOCOPY VARCHAR2,
              p_trx_date              OUT NOCOPY DATE,
              p_trx_gl_date                   OUT NOCOPY DATE,
              p_apply_gl_date              IN OUT NOCOPY DATE,
              p_calc_discount_on_lines_flag   OUT NOCOPY VARCHAR2,
              p_partial_discount_flag         OUT NOCOPY VARCHAR2,
              p_allow_overappln_flag          OUT NOCOPY VARCHAR2,
              p_natural_appln_only_flag       OUT NOCOPY VARCHAR2,
              p_creation_sign                 OUT NOCOPY VARCHAR2,
              p_cr_payment_schedule_id        OUT NOCOPY NUMBER,
              p_applied_payment_schedule_id  IN OUT NOCOPY NUMBER,
              p_term_id                       OUT NOCOPY NUMBER,
              p_amount_due_original           OUT NOCOPY NUMBER,
              p_amount_due_remaining          OUT NOCOPY NUMBER,
              p_trx_line_amount               OUT NOCOPY NUMBER,
              p_discount                   IN OUT NOCOPY NUMBER,
              p_apply_date                 IN OUT NOCOPY DATE,
              p_discount_max_allowed          OUT NOCOPY NUMBER,
              p_discount_earned_allowed       OUT NOCOPY NUMBER,
              p_discount_earned               OUT NOCOPY NUMBER,
              p_discount_unearned             OUT NOCOPY NUMBER,
              p_new_amount_due_remaining      OUT NOCOPY NUMBER,
              p_remittance_bank_account_id    OUT NOCOPY NUMBER,
              p_receipt_method_id             OUT NOCOPY NUMBER,
              p_amount_applied             IN OUT NOCOPY NUMBER,
              p_amount_applied_from        IN OUT NOCOPY NUMBER,
              p_trans_to_receipt_rate      IN OUT NOCOPY NUMBER,
              p_called_from                IN     VARCHAR2,
              p_return_status                 OUT NOCOPY VARCHAR2);

PROCEDURE Default_cash_receipt_id(
              p_cash_receipt_id IN OUT NOCOPY NUMBER,
              p_receipt_number  IN VARCHAR2,
              p_return_status   OUT NOCOPY VARCHAR2
                         );

PROCEDURE Derive_unapp_ids(
              p_trx_number                   IN VARCHAR2,
              p_customer_trx_id              IN OUT NOCOPY NUMBER,
              p_installment                  IN NUMBER,
              p_applied_payment_schedule_id  IN OUT NOCOPY NUMBER,
              p_receipt_number               IN VARCHAR2,
              p_cash_receipt_id              IN OUT NOCOPY NUMBER,
              p_receivable_application_id    IN OUT NOCOPY NUMBER,
              p_called_from                  IN VARCHAR2,
              p_apply_gl_date                OUT NOCOPY DATE,
              p_return_status                OUT NOCOPY VARCHAR2
                    );
/* Added for bug 3119391 */
PROCEDURE Default_unapp_info(
              p_receivable_application_id IN NUMBER,
              p_apply_gl_date    IN  DATE,
              p_cash_receipt_id  IN  NUMBER,
              p_reversal_gl_date IN OUT NOCOPY DATE,
              p_receipt_gl_date  OUT NOCOPY DATE,
	      p_cr_unapp_amount  OUT NOCOPY NUMBER );

PROCEDURE Default_reverse_info(p_cash_receipt_id  IN NUMBER,
              p_reversal_gl_date IN OUT NOCOPY DATE,
              p_reversal_date    IN OUT NOCOPY DATE,
              p_receipt_state    OUT NOCOPY VARCHAR2,
              p_receipt_gl_date  OUT NOCOPY DATE,
              p_type             OUT NOCOPY VARCHAR2
                     ) ;

PROCEDURE Derive_reverse_ids(
                         p_receipt_number         IN     VARCHAR2,
                         p_cash_receipt_id        IN OUT NOCOPY NUMBER,
                         p_reversal_category_name IN     VARCHAR2,
                         p_reversal_category_code IN OUT NOCOPY VARCHAR2,
                         p_reversal_reason_name   IN     VARCHAR2,
                         p_reversal_reason_code   IN OUT NOCOPY VARCHAR2,
                         p_return_status             OUT NOCOPY VARCHAR2
                           );
PROCEDURE Default_on_ac_app_info(
                         p_cash_receipt_id         IN NUMBER,
                         p_cr_gl_date                 OUT NOCOPY DATE,
                         p_cr_unapp_amount            OUT NOCOPY NUMBER,
                         p_receipt_date               OUT NOCOPY DATE,
                         p_cr_payment_schedule_id     OUT NOCOPY NUMBER,
                         p_amount_applied          IN OUT NOCOPY NUMBER,
                         p_apply_gl_date           IN OUT NOCOPY DATE,
                         p_apply_date              IN OUT NOCOPY DATE,
                         p_cr_currency_code           OUT NOCOPY VARCHAR2,
                         p_return_status              OUT NOCOPY VARCHAR2
                              );
PROCEDURE Derive_unapp_on_ac_ids(
                         p_receipt_number    IN VARCHAR2,
                         p_cash_receipt_id   IN OUT NOCOPY NUMBER,
                         p_receivable_application_id   IN OUT NOCOPY NUMBER,
                         p_apply_gl_date    OUT NOCOPY DATE,
                         p_return_status  OUT NOCOPY VARCHAR2
                               );

PROCEDURE Derive_otheraccount_ids(
                         p_receipt_number    IN VARCHAR2,
                         p_cash_receipt_id   IN OUT NOCOPY NUMBER,
                         p_applied_ps_id     IN NUMBER,
                         p_receivable_application_id   IN OUT NOCOPY NUMBER,
                         p_apply_gl_date    OUT NOCOPY DATE,
                         p_cr_unapp_amt     OUT NOCOPY NUMBER, /* Bug fix 3199157 */
                         p_return_status  OUT NOCOPY VARCHAR2
                               );

PROCEDURE Default_unapp_on_ac_act_info(
                         p_receivable_application_id IN NUMBER,
                         p_apply_gl_date             IN DATE,
                         p_cash_receipt_id           IN NUMBER,
                         p_reversal_gl_date          IN OUT NOCOPY DATE,
                         p_receipt_gl_date           OUT NOCOPY DATE
                               );

PROCEDURE Derive_activity_unapp_ids(
              p_receipt_number               IN      VARCHAR2,
              p_cash_receipt_id              IN OUT NOCOPY  NUMBER,
              p_receivable_application_id    IN OUT NOCOPY  NUMBER,
              p_called_from                  IN      VARCHAR2,
              p_apply_gl_date                   OUT NOCOPY  DATE,
              p_cr_unapp_amount                 OUT NOCOPY  NUMBER, /* Bug fix 3199157 */
              p_return_status                   OUT NOCOPY  VARCHAR2);

/* bug 2649369, proactive change to param p_met_code, change type from CHAR to VARCHAR2 */

PROCEDURE  get_doc_seq(
              p_application_id               IN      NUMBER,
              p_document_name                IN      VARCHAR2,
              p_sob_id                       IN      NUMBER,
              p_met_code	             IN      VARCHAR2,
              p_trx_date                     IN      DATE,
              p_doc_sequence_value           IN OUT NOCOPY  NUMBER,
              p_doc_sequence_id                 OUT NOCOPY  NUMBER,
              p_return_status                   OUT NOCOPY  VARCHAR2
                         );
PROCEDURE Derive_cust_info_from_trx(
              p_customer_trx_id              IN      ar_payment_schedules.customer_trx_id%TYPE,
              p_trx_number                   IN      ra_customer_trx.trx_number%TYPE,
              p_installment                  IN      ar_payment_schedules.terms_sequence_number%TYPE,
              p_applied_payment_schedule_id  IN      ar_payment_schedules.payment_schedule_id%TYPE,
              p_currency_code                IN      ar_cash_receipts.currency_code%TYPE,
              p_customer_id                     OUT NOCOPY  ar_payment_schedules.customer_id%TYPE,
              p_customer_site_use_id            OUT NOCOPY  hz_cust_site_uses.site_use_id%TYPE,
              p_return_status                   OUT NOCOPY  VARCHAR2
                       );
PROCEDURE Validate_Desc_Flexfield(
              p_desc_flex_rec                IN OUT NOCOPY  ar_receipt_api_pub.attribute_rec_type,
              p_desc_flex_name               IN      VARCHAR2,
              p_return_status                IN OUT NOCOPY  VARCHAR2
                       );
/* Bug fix 2248814 */
PROCEDURE Default_Desc_Flexfield(
              p_desc_flex_rec                OUT NOCOPY  ar_receipt_api_pub.attribute_rec_type,
              p_cash_receipt_id              IN      NUMBER,
              p_return_status                IN OUT NOCOPY  VARCHAR2
                       );
PROCEDURE Default_misc_ids(
              p_usr_currency_code            IN      VARCHAR2,
              p_usr_exchange_rate_type       IN      VARCHAR2,
              p_activity                     IN      VARCHAR2,
              p_reference_type               IN      VARCHAR2,
              p_reference_num                IN      VARCHAR2,
              p_tax_code                     IN      VARCHAR2,
              p_receipt_method_name          IN OUT NOCOPY  VARCHAR2,
              p_remittance_bank_account_name IN      VARCHAR2,
              p_remittance_bank_account_num  IN      VARCHAR2,
              p_currency_code                IN OUT NOCOPY  VARCHAR2,
              p_exchange_rate_type           IN OUT NOCOPY  VARCHAR2,
              p_receivables_trx_id           IN OUT NOCOPY  NUMBER,
              p_reference_id                 IN OUT NOCOPY  NUMBER,
              p_vat_tax_id                   IN OUT NOCOPY  NUMBER,
              p_receipt_method_id            IN OUT NOCOPY  NUMBER,
              p_remittance_bank_account_id   IN OUT NOCOPY  NUMBER,
              p_return_status                   OUT NOCOPY  VARCHAR2
                       );
PROCEDURE Get_misc_defaults(
              p_currency_code                IN OUT NOCOPY  VARCHAR2,
              p_exchange_rate_type           IN OUT NOCOPY  VARCHAR2,
              p_exchange_rate                IN OUT NOCOPY  NUMBER,
              p_exchange_date                IN OUT NOCOPY  DATE,
              p_amount                       IN OUT NOCOPY  NUMBER,
              p_receipt_date                 IN OUT NOCOPY  DATE,
              p_gl_date                      IN OUT NOCOPY  DATE,
              p_remittance_bank_account_id   IN OUT NOCOPY  NUMBER,
              p_deposit_date                 IN OUT NOCOPY  DATE,
              p_state                        IN OUT NOCOPY  VARCHAR2,
              p_distribution_set_id          IN OUT NOCOPY  NUMBER,
              p_vat_tax_id                   IN OUT NOCOPY  NUMBER,
              p_tax_rate                     IN OUT NOCOPY  NUMBER,
              p_receipt_method_id            IN      NUMBER,
              p_receivables_trx_id           IN      NUMBER,
              p_tax_code                     IN      VARCHAR2,
              p_tax_amount                   IN      NUMBER,
              p_creation_method_code            OUT NOCOPY  VARCHAR2,
              p_return_status                   OUT NOCOPY  VARCHAR2
                        );

PROCEDURE Default_prepay_cc_activity(
              p_appl_type                    IN      VARCHAR2,
              p_receivable_trx_id            IN OUT NOCOPY  NUMBER,
              p_return_status                OUT NOCOPY     VARCHAR2
             );

PROCEDURE default_open_receipt(
              p_cash_receipt_id          IN OUT NOCOPY NUMBER
            , p_receipt_number           IN OUT NOCOPY VARCHAR2
            , p_applied_ps_id            IN OUT NOCOPY NUMBER
            , p_open_cash_receipt_id     IN OUT NOCOPY NUMBER
            , p_open_receipt_number      IN OUT NOCOPY VARCHAR2
            , p_apply_gl_date            IN OUT NOCOPY DATE
            , p_open_rec_app_id          IN NUMBER
            , x_cr_payment_schedule_id   OUT NOCOPY NUMBER
            , x_last_receipt_date        OUT NOCOPY DATE
            , x_open_applied_ps_id       OUT NOCOPY NUMBER
            , x_unapplied_cash           OUT NOCOPY NUMBER
            , x_open_amount_applied      OUT NOCOPY NUMBER
            , x_claim_rec_trx_id         OUT NOCOPY NUMBER
            , x_application_ref_num      OUT NOCOPY VARCHAR2
            , x_secondary_app_ref_id     OUT NOCOPY NUMBER
            , x_application_ref_reason   OUT NOCOPY VARCHAR2
            , x_customer_reference       OUT NOCOPY VARCHAR2
            , x_customer_reason          OUT NOCOPY VARCHAR2
            , x_cr_gl_date               OUT NOCOPY DATE
            , x_open_cr_gl_date          OUT NOCOPY DATE
            , x_receipt_currency         OUT NOCOPY VARCHAR2
            , x_open_receipt_currency    OUT NOCOPY VARCHAR2
            , x_cr_customer_id           OUT NOCOPY NUMBER
            , x_open_cr_customer_id      OUT NOCOPY NUMBER
            , x_return_status            OUT NOCOPY VARCHAR2);

PROCEDURE default_unapp_open_receipt(
              p_receivable_application_id  IN  NUMBER               
            , x_applied_cash_receipt_id    OUT NOCOPY NUMBER
            , x_applied_rec_app_id         OUT NOCOPY NUMBER
            , x_amount_applied             OUT NOCOPY NUMBER
            , x_return_status              OUT NOCOPY VARCHAR2);

END ar_receipt_lib_pvt;
/
SHOW ERR
