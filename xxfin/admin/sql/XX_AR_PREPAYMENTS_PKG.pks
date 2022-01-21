CREATE OR REPLACE PACKAGE apps.xx_ar_prepayments_pkg
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AR_PREPAYMENTS_PKG                                                              |
-- |  Rice ID: I1025                                                                            |
-- |  Description:  This package is an extended version of AR_PREPAYMENTS_PUB.                  |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         02-Oct-2007  B.Looman         Initial version                                  |
-- | 2.0         28-AUG-2013  Edson Morales    Added R12 encryption                             |
-- | 3.0         04-Feb-2013  Edson M.         Changes for Defect 27883                         |
-- +============================================================================================+
    g_default_receipt_ext_attrs            xx_ar_cash_receipts_ext%ROWTYPE;
    gc_i1025_record_type_deposit  CONSTANT VARCHAR2(20)                      := 'D';
    gc_i1025_record_type_refund   CONSTANT VARCHAR2(20)                      := 'R';
    gc_i1025_record_type_order    CONSTANT VARCHAR2(20)                      := 'O';
    gc_i1025_msg_type_error       CONSTANT VARCHAR2(20)                      := 'E';
    gc_i1025_msg_type_warning     CONSTANT VARCHAR2(20)                      := 'W';
    gc_i1025_msg_type_info        CONSTANT VARCHAR2(20)                      := 'I';

--Added for 12i Retrofit by NB
    TYPE lr_payer_rec_type IS RECORD(
        payer_id    VARCHAR2(80),
        payer_name  VARCHAR2(80)
    );

    TYPE lr_address_rec_type IS RECORD(
        address1    VARCHAR2(80),
        address2    VARCHAR2(80),
        address3    VARCHAR2(80),
        city        VARCHAR2(80),
        county      VARCHAR2(80),
        state       VARCHAR2(80),
        country     VARCHAR2(80),
        postalcode  VARCHAR2(40),
        phone       VARCHAR2(40),
        email       VARCHAR2(40)
    );

    TYPE lr_creditcardinstr_rec_type IS RECORD(
        finame          VARCHAR2(80),
        cc_type         VARCHAR2(80),
        cc_num          VARCHAR2(80),
        cc_expdate      DATE,
        cc_holdername   VARCHAR2(80),
        cc_billingaddr  lr_address_rec_type
    );

    TYPE lr_purchasecardinstr_rec_type IS RECORD(
        finame          VARCHAR2(80),
        pc_type         VARCHAR2(80),
        pc_num          VARCHAR2(80),
        pc_expdate      DATE,
        pc_holdername   VARCHAR2(80),
        pc_billingaddr  lr_address_rec_type,
        pc_subtype      VARCHAR2(80)
    );

    TYPE lr_dualpaymentinstr_rec_type IS RECORD(
        pmtinstr_id            NUMBER,
        pmtinstr_shortname     VARCHAR2(80),
        bnfpmtinstr_id         NUMBER,
        bnfpmtinstr_shortname  VARCHAR2(80)
    );

    TYPE lr_debitcardinstr_rec_type IS RECORD(
        finame          VARCHAR2(80),
        dc_type         VARCHAR2(80)        := 'PINLESS',
        dc_num          VARCHAR2(80),
        dc_expdate      DATE,
        dc_holdername   VARCHAR2(80),
        dc_billingaddr  lr_address_rec_type,
        dc_subtype      VARCHAR2(80)
    );

    TYPE lr_pmtinstr_rec_type IS RECORD(
        pmtinstr_id         NUMBER,
        pmtinstr_shortname  VARCHAR2(80),
        creditcardinstr     lr_creditcardinstr_rec_type,
        purchasecardinstr   lr_purchasecardinstr_rec_type,
        dualpaymentinstr    lr_dualpaymentinstr_rec_type,
        debitcardinstr      lr_debitcardinstr_rec_type
    --commented, as this is not supported.
    --BankAcctInstr      BankAcctInstr_rec_type
    );

-- ==========================================================================
-- prepayment application record cursor
-- ==========================================================================
    CURSOR gcu_prepay_appl(
        cp_cash_receipt_id   IN  NUMBER,
        cp_reference_type    IN  VARCHAR2,
        cp_reference_number  IN  VARCHAR2)
    IS
        SELECT /*+ index(raa AR_RECEIVABLE_APPLICATIONS_N1) */                -- hint added by Gaurav for defect # 11467
               raa.receivable_application_id,
               raa.amount_applied,
               raa.display,
               raa.apply_date,
               raa.status,
               raa.application_type,
               raa.payment_schedule_id,
               raa.cash_receipt_id,
               acr.receipt_number,
               acr.status receipt_status,
               acr.amount receipt_amount,
               raa.applied_customer_trx_id,
               raa.applied_customer_trx_line_id,
               raa.applied_payment_schedule_id,
               raa.org_id,
               raa.receivables_trx_id,
               raa.application_ref_type,
               raa.application_ref_id,
               NVL(raa.application_ref_num,
                   acr.customer_receipt_reference) application_ref_num,
               raa.secondary_application_ref_id,
               raa.application_ref_reason,
               raa.payment_set_id,
               raa.customer_reference,
               raa.secondary_application_ref_type,
               raa.secondary_application_ref_num
        FROM   ar_cash_receipts_all acr,
               ar_receivable_applications_all raa
        WHERE  acr.cash_receipt_id = raa.cash_receipt_id
        AND    acr.cash_receipt_id = cp_cash_receipt_id
        AND    raa.application_ref_type LIKE cp_reference_type
        AND    NVL(raa.application_ref_num,
                   acr.customer_receipt_reference) LIKE cp_reference_number
        --AND raa.applied_payment_schedule_id = -7  -- commneted by Gaurav for defect # 11467
        AND      raa.applied_payment_schedule_id
               + 0 = -7                                                            -- Added by Gaurav for defect # 11467
        AND    raa.status = 'OTHER ACC'
        AND    raa.display = 'Y';

-- +============================================================================================+
-- |  Name: SET_DEBUG                                                                           |
-- |  Description: This procedure turns on/off the debug mode.                                  |
-- |                                                                                            |
-- |  Parameters:  p_debug - Debug Mode: TRUE=On, FALSE=Off                                     |
-- |                                                                                            |
-- |  Returns:     N/A                                                                          |
-- +============================================================================================+
    PROCEDURE set_debug(
        p_debug  IN  BOOLEAN DEFAULT TRUE);

-- +============================================================================================+
-- |  Name: CLEAR_I1025_MESSAGES                                                                |
-- |  Description: This procedure clears all the messages for the given I1025 record.           |
-- |                                                                                            |
-- |  Parameters:  p_I1025_record_type - I1025 Record Type (DEPOSIT, REFUND, ORDER)             |
-- |               p_orig_sys_document_ref - Original System Document Reference (Legacy Order)  |
-- |               p_payment_number - Payment Number                                            |
-- |               p_request_id - Request Id for this Request                                   |
-- |                                                                                            |
-- +============================================================================================+
    PROCEDURE clear_i1025_messages(
        p_i1025_record_type      IN  VARCHAR2,
        p_orig_sys_document_ref  IN  VARCHAR2,
        p_payment_number         IN  NUMBER,
        p_request_id             IN  NUMBER);

-- +============================================================================================+
-- |  Name: INSERT_I1025_MESSAGE                                                                |
-- |  Description: This procedure inserts a message for the given I1025 record being processed. |
-- |                                                                                            |
-- |  Parameters:  p_I1025_record_type - I1025 Record Type (DEPOSIT, REFUND, ORDER)             |
-- |               p_orig_sys_document_ref - Original System Document Reference (Legacy Order)  |
-- |               p_payment_number - Payment Number                                            |
-- |               p_program_run_date - I1025 program run date                                  |
-- |               p_request_id - Request Id for this Request                                   |
-- |               p_message_code - Code used to categorize similar messages                    |
-- |               p_message_text - Text Message for Error or Warning                           |
-- |               p_error_location - Location of the error                                     |
-- |               p_message_type - Message Type: E=Error (default), W=Warning, I=Info          |
-- |                                                                                            |
-- +============================================================================================+
    PROCEDURE insert_i1025_message(
        p_i1025_record_type      IN  VARCHAR2,
        p_orig_sys_document_ref  IN  VARCHAR2,
        p_payment_number         IN  NUMBER,
        p_program_run_date       IN  DATE,
        p_request_id             IN  NUMBER,
        p_message_code           IN  VARCHAR2,
        p_message_text           IN  VARCHAR2,
        p_error_location         IN  VARCHAR2,
        p_message_type           IN  VARCHAR2 DEFAULT gc_i1025_msg_type_error);

-- +============================================================================================+
-- |  Name: GET_PREPAYMENT_RECV_TRX_ID                                                          |
-- |  Description: This procedure returns the prepayment receivable transaction id assigned     |
-- |               to the given operating unit (org_id).                                        |
-- |                                                                                            |
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |                                                                                            |
-- |  Returns:     receivable transaction id                                                    |
-- +============================================================================================+
    FUNCTION get_prepayment_recv_trx_id(
        p_org_id  IN  NUMBER)
        RETURN NUMBER;

-- +============================================================================================+
-- |  Name: GET_COUNTRY_PREFIX                                                                  |
-- |  Description: This procedure returns the country code assigned to the given operating      |
-- |               unit (org_id).                                                               |
-- |                                                                                            |
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |                                                                                            |
-- |  Returns:     country code                                                                 |
-- +============================================================================================+
    FUNCTION get_country_prefix(
        p_org_id  IN  NUMBER)
        RETURN VARCHAR2;

-- +============================================================================================+
-- |  Name: GET_RECEIPT_METHOD                                                                  |
-- |  Description: This procedure returns the receipt mthd name from the given receipt mthd id. |
-- |                                                                                            |
-- |  Parameters:  p_receipt_method_id - Receipt Method Id                                      |
-- |                                                                                            |
-- |  Returns:     receipt method name                                                          |
-- +============================================================================================+
    FUNCTION get_receipt_method(
        p_receipt_method_id  IN  NUMBER)
        RETURN VARCHAR2;

-- +============================================================================================+
-- |  Name: GET_PAYMENT_TYPE                                                                    |
-- |  Description: This procedure returns the payment type derived from the given receipt mthd. |
-- |                                                                                            |
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_receipt_method_id - Receipt Method Id                                      |
-- |               p_payment_type - Payment Type from OE_PAYMENTS (Optional)                    |
-- |                                                                                            |
-- |  Returns:     payment type                                                                 |
-- +============================================================================================+
    FUNCTION get_payment_type(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN VARCHAR2;

-- +============================================================================================+
-- |  Name: IS_PAYMENT_TYPE                                                                     |
-- |  Description: This procedure returns true/false if payment type associated to the given    |
-- |                 receipt method matches the given payment type.                             |
-- |                                                                                            |
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_receipt_method_id - Receipt Method Id for the payment (AR Receipt)         |
-- |               p_payment_type - Payment Type from OE_PAYMENTS (Optional)                    |
-- |               p_matches_pmt_type - Payment Type (CASH, CHECK, DEBIT_CARD, CREDIT_CARD,     |
-- |                                  TELECHECK, MAILCHECK, GIFT_CARD)                          |
-- |                                                                                            |
-- |  Returns:     True/False                                                                   |
-- +============================================================================================+
    FUNCTION is_payment_type(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL,
        p_matches_pmt_type   IN  VARCHAR2)
        RETURN BOOLEAN;

-- +============================================================================================+
-- |  Name: IS_CASH                                                                             |
-- |  Description: This procedure returns true/false if payment type associated to the given    |
-- |                 receipt method is CASH.                                                    |
-- |                                                                                            |
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_receipt_method_id - Receipt Method Id for the payment (AR Receipt)         |
-- |               p_payment_type - Payment Type from OE_PAYMENTS (Optional)                    |
-- |                                                                                            |
-- |  Returns:     True/False                                                                   |
-- +============================================================================================+
    FUNCTION is_cash(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN;

-- +============================================================================================+
-- |  Name: IS_CHECK                                                                            |
-- |  Description: This procedure returns true/false if payment type associated to the given    |
-- |                 receipt method is CHECK.                                                   |
-- |                                                                                            |
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_receipt_method_id - Receipt Method Id for the payment (AR Receipt)         |
-- |               p_payment_type - Payment Type from OE_PAYMENTS (Optional)                    |
-- |                                                                                            |
-- |  Returns:     True/False                                                                   |
-- +============================================================================================+
    FUNCTION is_check(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN;

-- +============================================================================================+
-- |  Name: IS_CREDIT_CARD                                                                      |
-- |  Description: This procedure returns true/false if payment type associated to the given    |
-- |                 receipt method is CREDIT_CARD.                                             |
-- |                                                                                            |
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_receipt_method_id - Receipt Method Id for the payment (AR Receipt)         |
-- |               p_payment_type - Payment Type from OE_PAYMENTS (Optional)                    |
-- |                                                                                            |
-- |  Returns:     True/False                                                                   |
-- +============================================================================================+
    FUNCTION is_credit_card(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN;

-- +============================================================================================+
-- |  Name: IS_DEBIT_CARD                                                                       |
-- |  Description: This procedure returns true/false if payment type associated to the given    |
-- |                 receipt method is DEBIT_CARD.                                              |
-- |                                                                                            |
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_receipt_method_id - Receipt Method Id for the payment (AR Receipt)         |
-- |               p_payment_type - Payment Type from OE_PAYMENTS (Optional)                    |
-- |                                                                                            |
-- |  Returns:     True/False                                                                   |
-- +============================================================================================+
    FUNCTION is_debit_card(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN;

-- +============================================================================================+
-- |  Name: IS_MAILCHECK                                                                        |
-- |  Description: This procedure returns true/false if payment type associated to the given    |
-- |                 receipt method is MAILCHECK.                                               |
-- |                                                                                            |
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_receipt_method_id - Receipt Method Id for the payment (AR Receipt)         |
-- |               p_payment_type - Payment Type from OE_PAYMENTS (Optional)                    |
-- |                                                                                            |
-- |  Returns:     True/False                                                                   |
-- +============================================================================================+
    FUNCTION is_mailcheck(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN;

-- +============================================================================================+
-- |  Name: IS_TELECHECK                                                                        |
-- |  Description: This procedure returns true/false if payment type associated to the given    |
-- |                 receipt method is TELECHECK.                                               |
-- |                                                                                            |
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_receipt_method_id - Receipt Method Id for the payment (AR Receipt)         |
-- |               p_payment_type - Payment Type from OE_PAYMENTS (Optional)                    |
-- |                                                                                            |
-- |  Returns:     True/False                                                                   |
-- +============================================================================================+
    FUNCTION is_telecheck(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN;

-- +============================================================================================+
-- |  Name: IS_GIFT_CARD                                                                        |
-- |  Description: This procedure returns true/false if payment type associated to the given    |
-- |                 receipt method is GIFT_CARD.                                               |
-- |                                                                                            |
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_receipt_method_id - Receipt Method Id for the payment (AR Receipt)         |
-- |               p_payment_type - Payment Type from OE_PAYMENTS (Optional)                    |
-- |                                                                                            |
-- |  Returns:     True/False                                                                   |
-- +============================================================================================+
    FUNCTION is_gift_card(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN;

-- +============================================================================================+
-- |  Name: GET_PREPAY_APPLICATION_RECORD                                                       |
-- |  Description: This function returns the pre-payment application line for the given         |
-- |               cash receipt.                                                                |
-- |                                                                                            |
-- |  Parameters:  p_cash_receipt_id - Cash Receipt Id                                          |
-- |               p_reference_type - Recv. Application reference type                          |
-- |               p_reference_number - Recv. Application reference number                      |
-- |                                                                                            |
-- |  Returns:     Prepay Appl rowtype                                                          |
-- +============================================================================================+
    FUNCTION get_prepay_application_record(
        p_cash_receipt_id   IN  NUMBER,
        p_reference_type    IN  VARCHAR2,
        p_reference_number  IN  VARCHAR2)
        RETURN gcu_prepay_appl%ROWTYPE;

-- +============================================================================================+
-- |  Name: UNAPPLY_PREPAYMENT_APPLICATION                                                      |
-- |  Description: This procedure unapplies the given prepayment application.                   |                                                               |
-- |                                                                                            |
-- |  Parameters:  p_prepay_appl_row - Prepayment application record to unapply                 |
-- |                                                                                            |
-- |  Returns:     N/A                                                                          |
-- +============================================================================================+
    PROCEDURE unapply_prepayment_application(
        p_prepay_appl_row  IN OUT NOCOPY  gcu_prepay_appl%ROWTYPE);

-- +============================================================================================+
-- |  Name: APPLY_PREPAYMENT_APPLICATION                                                        |
-- |  Description: This procedure applies the given prepayment application.                     |                                                               |
-- |                                                                                            |
-- |  Parameters:  p_prepay_appl_row - Prepayment application record to unapply                 |
-- |                                                                                            |
-- |  Returns:     N/A                                                                          |
-- +============================================================================================+
    PROCEDURE apply_prepayment_application(
        p_prepay_appl_row  IN OUT NOCOPY  gcu_prepay_appl%ROWTYPE);

-- +============================================================================================+
-- |  Name: SET_RECEIPT_ATTR_REFERENCES                                                         |
-- |  Description: This procedure sets all the receipt and receipt applications descriptive     |
-- |               flexfields and receipt references for the given context.                     |
-- |                                                                                            |
-- |  Parameters:  p_receipt_context - Receipt Flexfield Context                                |
-- |               p_orig_sys_document_ref - Legacy Order Number                                |
-- |               p_receipt_method_id - Receipt Method Id for the payment (AR Receipt)         |
-- |               p_payment_type_code - Payment Type Code from the order payments              |
-- |               p_check_number - Check Number reference on the order payments                |
-- |               p_paid_at_store_id - Organization Id for the store where this was paid       |
-- |               p_ship_from_org_id - Organization Id for the ship-from warehouse             |
-- |               p_cc_auth_manual - Y/N (or 1/2) to indicate if trxn was approved manually    |
-- |               p_cc_auth_ps2000 - PS2000 Authorization code for this trxn                   |
-- |               p_merchant_number - Merchant number of the credit card transaction           |
-- |               p_od_payment_type - OD Payment Type code indicating the payment/card type    |
-- |               p_debit_card_approval_ref - Approval reference for debit card transactions   |
-- |               p_cc_mask_number - Mask Number of Credit Card (1st 6 and last 4)             |
-- |               p_payment_amount - Amount of this payment transaction                        |
-- |               p_application_customer_trx_id - Credit Memo Trx Id for reference on activity |
-- |               p_called_from - The program calling this function                            |
-- |               p_print_debug - T/F if debug info should print to DBMS_OUTPUT or FND_LOG     |
-- |               x_receipt_number - OUT - Receipt Number for the newly created receipt        |
-- |               x_receipt_comments - OUT - Comments for the receipt                          |
-- |               x_customer_receipt_reference - OUT - Reference on the receipt (used for CM)  |
-- |               x_attribute_rec - OUT - DFF attributes defined for the receipt               |
-- |               x_app_customer_reference - OUT - Refence for the receipt applications        |
-- |               x_app_comments - OUT - Comments for the receipt applications                 |
-- |               x_app_attribute_rec - OUT - DFF attributes defined for the receipt appl      |
-- |                                                                                            |
-- |  Returns:     None                                                                         |
-- +============================================================================================+
    PROCEDURE set_receipt_attr_references(
        p_receipt_context             IN             VARCHAR2,
        p_orig_sys_document_ref       IN             oe_order_headers.orig_sys_document_ref%TYPE,
        p_receipt_method_id           IN             ar_cash_receipts.receipt_method_id%TYPE,
        p_payment_type_code           IN             oe_payments.payment_type_code%TYPE,
        p_check_number                IN             oe_payments.check_number%TYPE DEFAULT NULL,
        p_paid_at_store_id            IN             NUMBER DEFAULT NULL,
        p_ship_from_org_id            IN             oe_order_headers.ship_from_org_id%TYPE DEFAULT NULL,
        p_cc_auth_manual              IN             VARCHAR2 DEFAULT NULL,
        p_cc_auth_ps2000              IN             VARCHAR2 DEFAULT NULL,
        p_merchant_number             IN             VARCHAR2 DEFAULT NULL,
        --p_company_code                 IN  VARCHAR2 DEFAULT NULL,
        p_od_payment_type             IN             VARCHAR2 DEFAULT NULL,
        p_debit_card_approval_ref     IN             VARCHAR2 DEFAULT NULL,
        p_cc_mask_number              IN             VARCHAR2 DEFAULT NULL,
        p_payment_amount              IN             NUMBER DEFAULT NULL,
        p_applied_customer_trx_id     IN             NUMBER DEFAULT NULL,
        p_original_receipt_id         IN             NUMBER DEFAULT NULL,
        p_transaction_number          IN             VARCHAR2 DEFAULT NULL,
        p_additional_auth_codes       IN             VARCHAR2 DEFAULT NULL,
        p_imp_file_name               IN             VARCHAR2 DEFAULT NULL,
        p_om_import_date              IN             DATE DEFAULT NULL,
        p_i1025_record_type           IN             VARCHAR2 DEFAULT gc_i1025_record_type_order,
        p_called_from                 IN             VARCHAR2 DEFAULT NULL,
        p_original_order              IN             VARCHAR2 DEFAULT NULL,
        p_print_debug                 IN             VARCHAR2 DEFAULT fnd_api.g_false,
        x_receipt_number              IN OUT NOCOPY  ar_cash_receipts.receipt_number%TYPE,
        x_receipt_comments            IN OUT NOCOPY  ar_cash_receipts.comments%TYPE,
        x_customer_receipt_reference  IN OUT NOCOPY  ar_cash_receipts.customer_receipt_reference%TYPE,
        x_attribute_rec               IN OUT NOCOPY  ar_receipt_api_pub.attribute_rec_type,
        x_app_customer_reference      IN OUT NOCOPY  ar_receivable_applications.customer_reference%TYPE,
        x_app_comments                IN OUT NOCOPY  ar_receivable_applications.comments%TYPE,
        x_app_attribute_rec           IN OUT NOCOPY  ar_receipt_api_pub.attribute_rec_type,
        x_receipt_ext_attributes      IN OUT NOCOPY  xx_ar_cash_receipts_ext%ROWTYPE);

-- +============================================================================================+
-- |  Name: INSERT_RECEIPT_EXT_INFO                                                             |
-- |  Description: This procedure creates records in XX_AR_CASH_RECEIPTS_EXT for extra info     |
-- |                 on AR Receipts.                                                            |
-- |                                                                                            |
-- |  Parameters:  p_receipt_ext_attributes - XX_AR_CASH_RECEIPTS_EXT row type                  |
-- +============================================================================================+
    PROCEDURE insert_receipt_ext_info(
        p_receipt_ext_attributes  IN OUT NOCOPY  xx_ar_cash_receipts_ext%ROWTYPE);

-- +============================================================================================+
-- |  Name: CREATE_PREPAYMENT                                                                   |
-- |  Description: This procedure creates prepayments (AR receipts) through HVOP/I1025.         |
-- |               It is an extended version of AR_PREPAYMENTS_PUB.create_prepayment.  This     |
-- |               procedure checks required fields, creates the bank account for the customer  |
-- |               credit card, requests an iPayment voice authorization for the pre-approved   |
-- |               credit card transactions                                                     |
-- |                                                                                            |
-- |  Parameters:  Standard API Parameters:                                                     |
-- |                 p_api_version - Std API Parameter - Function API Version                   |
-- |                 p_init_msg_list - Std API Parameter - Initialize the msg stack             |
-- |                 p_commit - Std API Parameter - Commit after success                        |
-- |                 p_validation_level - Std API Parameter - Error validation level            |
-- |                 x_return_status - Std API Parameter - Return status of API                 |
-- |                 x_msg_count - Std API Parameter - Message Stack Count                      |
-- |                 x_msg_data - Std API Parameter - Message Data from stack                   |
-- |               Function Parameters:                                                         |
-- |                 p_print_debug - Print Debug Output (T/F)                                   |
-- |                 p_receipt_method_id - Receipt Method ID for the receipt                    |
-- |                 p_payment_type_code - Payment Type Code from the order payment record      |
-- |                 p_currency_code - Currency Code for the payment                            |
-- |                 p_amount - Amount of the payment (receipt)                                 |
-- |                 p_receipt_date - Date for the receipt                                      |
-- |                 p_gl_date - GL Date for the receipt accounting                             |
-- |                 p_customer_id - Customer Id for the customer identified to the receipt     |
-- |                 p_customer_site_use_id - Customer Site Use Id for the customer site        |
-- |                 p_customer_bank_account_id - Bank Account (Credit Card Acct) for the cust. |
-- |                 p_customer_receipt_reference - Receipt reference (ties back to SA/AOPS)    |
-- |                 p_remittance_bank_account_id - Remittance bank account for the receipt     |
-- |                 p_called_from - What program is calling the API                            |
-- |                 p_attribute_rec - Descriptive Flexfield Attributes record type for receipt |
-- |                 p_receipt_comments - Comments on the receipt                               |
-- |                 p_application_ref_type - Reference Type for prepay applications (OM/SA)    |
-- |                 p_application_ref_id - ID of the document for the prepayment application   |
-- |                 p_application_ref_num - Document number for the prepayment application     |
-- |                 p_secondary_application_ref_id - 2nd ID of the document for the prepay app |
-- |                 p_apply_date - Date on the receipt prepayment application                  |
-- |                 p_apply_gl_date - GL Date on the receipt prepayment application            |
-- |                 p_amount_applied - Amount of the prepayment application                    |
-- |                 p_app_attribute_rec - DFF Attributes record type for prepay application    |
-- |                 p_app_comments - Comments on the receipt prepayment application            |
-- |                 p_app_customer_reference - Receipt Receipt for the prepayment application  |
-- |                 p_credit_card_code - Credit card code (Card type for the credit card)      |
-- |                 p_credit_card_number - Encrypted Credit Card Number                        |
-- |                                        (this will be customer bank acct number)            |
-- |                 p_credit_card_holder_name - Name on the credit card                        |
-- |                 p_credit_card_expiration_date - Expiration date of the credit card         |
-- |                 p_credit_card_approval_code - Approval code for the credit card trxn       |
-- |                 p_credit_card_approval_date - Approval date of the credit card trxn        |
-- |                 p_payment_server_order_prefix - Prefix on the Tangible Id (default XXO)    |
-- |                 x_payment_set_id - Payment set id for the receipt (for multi order pmts)   |
-- |                 x_cash_receipt_id - Cash Receipt Id returned from the API for this payment |
-- |                 x_receipt_number - Receipt Number of the cash receipt created              |
-- |                 x_payment_server_order_num - Tangible Id for the iPayment CC trxn          |
-- |                 x_payment_response_error_code - Error Code returned from iPayment servlet  |
-- |                                                                                            |
-- |  Returns:     None                                                                         |
-- +============================================================================================+
    PROCEDURE create_prepayment(
        p_api_version                   IN             NUMBER,
        p_init_msg_list                 IN             VARCHAR2 DEFAULT fnd_api.g_false,
        p_commit                        IN             VARCHAR2 DEFAULT fnd_api.g_false,
        p_validation_level              IN             NUMBER DEFAULT fnd_api.g_valid_level_full,
        x_return_status                 OUT NOCOPY     VARCHAR2,
        x_msg_count                     OUT NOCOPY     NUMBER,
        x_msg_data                      OUT NOCOPY     VARCHAR2,
        p_print_debug                   IN             VARCHAR2 DEFAULT fnd_api.g_false,
        p_receipt_method_id             IN             ar_cash_receipts.receipt_method_id%TYPE,
        p_payment_type_code             IN             oe_payments.payment_type_code%TYPE DEFAULT NULL,
        p_currency_code                 IN             ar_cash_receipts.currency_code%TYPE DEFAULT NULL,
        p_amount                        IN             ar_cash_receipts.amount%TYPE,
        p_payment_number                IN             NUMBER DEFAULT NULL,
        p_sas_sale_date                 IN             DATE DEFAULT NULL,
        p_receipt_date                  IN             ar_cash_receipts.receipt_date%TYPE DEFAULT NULL,
        p_gl_date                       IN             ar_cash_receipt_history.gl_date%TYPE DEFAULT NULL,
        p_customer_id                   IN             ar_cash_receipts.pay_from_customer%TYPE DEFAULT NULL,
        p_customer_site_use_id          IN             hz_cust_site_uses.site_use_id%TYPE DEFAULT NULL,
        p_customer_bank_account_id      IN             ar_cash_receipts.customer_bank_account_id%TYPE DEFAULT NULL,
        p_customer_receipt_reference    IN             ar_cash_receipts.customer_receipt_reference%TYPE DEFAULT NULL,
        p_remittance_bank_account_id    IN             ar_cash_receipts.remittance_bank_account_id%TYPE DEFAULT NULL,
        p_called_from                   IN             VARCHAR2 DEFAULT NULL,
        p_attribute_rec                 IN             ar_receipt_api_pub.attribute_rec_type
                DEFAULT ar_receipt_api_pub.attribute_rec_const,
        p_receipt_comments              IN             VARCHAR2 DEFAULT NULL,
        p_application_ref_type          IN             ar_receivable_applications.application_ref_type%TYPE DEFAULT NULL,
        p_application_ref_id            IN             ar_receivable_applications.application_ref_id%TYPE DEFAULT NULL,
        p_application_ref_num           IN             ar_receivable_applications.application_ref_num%TYPE DEFAULT NULL,
        p_secondary_application_ref_id  IN             ar_receivable_applications.secondary_application_ref_id%TYPE
                DEFAULT NULL,
        p_apply_date                    IN             ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
        p_apply_gl_date                 IN             ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
        p_amount_applied                IN             ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
        p_app_attribute_rec             IN             ar_receipt_api_pub.attribute_rec_type
                DEFAULT ar_receipt_api_pub.attribute_rec_const,
        p_app_comments                  IN             ar_receivable_applications.comments%TYPE DEFAULT NULL,
        x_payment_set_id                IN OUT NOCOPY  NUMBER,              -- pass payment_set_id for multiple payments
        x_cash_receipt_id               OUT NOCOPY     ar_cash_receipts.cash_receipt_id%TYPE,
        x_receipt_number                IN OUT NOCOPY  ar_cash_receipts.receipt_number%TYPE,
        p_receipt_ext_attributes        IN             xx_ar_cash_receipts_ext%ROWTYPE
                DEFAULT g_default_receipt_ext_attrs);

-- +============================================================================================+
-- |  Name: REAPPLY_DEPOSIT_PREPAYMENT                                                          |
-- |  Description: This procedure unapplies the prepayment application on the AOPS order and    |
-- |               applies a new prepayment application to the new OM order.                    |
-- |                                                                                            |
-- |  Parameters:  Standard API Parameters:                                                     |
-- |                 p_init_msg_list - Std API Parameter - Initialize the msg stack             |
-- |                 p_commit - Std API Parameter - Commit after success                        |
-- |                 p_validation_level - Std API Parameter - Error validation level            |
-- |                 x_return_status - Std API Parameter - Return status of API                 |
-- |                 x_msg_count - Std API Parameter - Message Stack Count                      |
-- |                 x_msg_data - Std API Parameter - Message Data from stack                   |
-- |               New Reference Parameters:                                                    |
-- |                 p_cash_receipt_id - AR Cash Receipt Id (from Deposit table)                |
-- |                 p_header_id - Header Id for new OM Order (interfaced from AOPS order)      |
-- |                 p_order_number - Order Number for new OM Order (interfaced from AOPS order)|
-- |                 p_apply_amount - Order Total (this could be less than the original         |
-- |                                    deposit amount in backorder situations)                 |
-- |                 x_payment_set_id -  Payment Set Id for the order payments                  |
-- |                                       (will be generated if not defined)                   |
-- |                                                                                            |
-- |  Returns:     None                                                                         |
-- +============================================================================================+
    PROCEDURE reapply_deposit_prepayment(
        p_init_msg_list     IN             VARCHAR2 DEFAULT fnd_api.g_false,
        p_commit            IN             VARCHAR2 DEFAULT fnd_api.g_false,
        p_validation_level  IN             NUMBER DEFAULT fnd_api.g_valid_level_full,
        x_return_status     OUT NOCOPY     VARCHAR2,
        x_msg_count         OUT NOCOPY     NUMBER,
        x_msg_data          OUT NOCOPY     VARCHAR2,
        p_cash_receipt_id   IN             NUMBER,
        p_header_id         IN             NUMBER,
        p_order_number      IN             VARCHAR2,
        p_apply_amount      IN             NUMBER,
        x_payment_set_id    IN OUT NOCOPY  NUMBER);
END;
/