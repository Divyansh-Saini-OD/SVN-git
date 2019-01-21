CREATE OR REPLACE PACKAGE apps.xx_ar_manual_pmts_pkg
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AR_MANUAL_PMTS_PKG                                                              |
-- |  Description:  This package is used to run manual processes on payments.                   |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         04-Jun-2008  Brian J Looman   Initial version                                  |
-- | 2.0         04-Feb-2013  Edson Morales    Changes for Defect 27883                         |
-- +============================================================================================+

    -- +============================================================================================+
-- |  Name: CLEAR_RECEIPT_CC_ERRORS                                                             |
-- |  Description: This procedure clears all credit card errors on the given receipts.          |
-- |                                                                                            |
-- |  Parameters:  p_receipt_method_id - Credit Card Receipt Method Id                          |
-- |               p_receipt_date_from - From Receipt Date                                      |
-- |               p_receipt_date_to - To Receipt Date                                          |
-- |               p_receipt_number_from - From Receipt Number                                  |
-- |               p_receipt_number_to - To Receipt Number                                      |
-- |               p_tangible_prefix - Current Tangible prefix                                  |
-- |               p_cc_error_text - Credit Card error text                                     |
-- |               p_commit_flag - Y/N flag to issue commit (defaults to "Y")                   |
-- |                                                                                            |
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
    PROCEDURE clear_receipt_cc_errors(
        x_error_buffer         OUT     VARCHAR2,
        x_return_code          OUT     NUMBER,
        p_receipt_method_id    IN      NUMBER,
        p_receipt_date_from    IN      VARCHAR2,
        p_receipt_date_to      IN      VARCHAR2,
        p_receipt_number_from  IN      VARCHAR2,
        p_receipt_number_to    IN      VARCHAR2,
        p_tangible_prefix      IN      VARCHAR2 DEFAULT NULL,
        p_cc_error_text        IN      VARCHAR2 DEFAULT NULL,
        p_commit_flag          IN      VARCHAR2 DEFAULT 'Y');

-- +============================================================================================+
-- |  Name: CORRECT_RECEIPT_METHOD                                                              |
-- |  Description: This procedure corrects invalid receipt methods on both of the AR I1025      |
-- |                 tender tables (XX_OM_RETURN_TENDERS_ALL and XX_OM_LEGACY_DEPOSITS).        |
-- |                                                                                            |
-- |  Parameters:  p_source_table - Source table of the tender records                          |
-- |                  - values allowed: Deposit Payments, Refund Tenders, Order Payments, All   |
-- |               p_receipt_method_from - Old Receipt Method                                   |
-- |               p_receipt_method_to - New Receipt Method                                     |
-- |               p_from_date - From Creation Date                                             |
-- |               p_to_date - To Creation Date                                                 |
-- |                                                                                            |
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
    PROCEDURE correct_receipt_method(
        x_error_buffer         OUT     VARCHAR2,
        x_return_code          OUT     NUMBER,
        p_source_table         IN      VARCHAR2,
        p_receipt_method_from  IN      VARCHAR2,
        p_receipt_method_to    IN      VARCHAR2,
        p_from_date            IN      VARCHAR2,
        p_to_date              IN      VARCHAR2);

-- +============================================================================================+
-- |  Name: CLEAR_SELECTED_REMIT_BATCH                                                          |
-- |  Description: This procedure clears all remittance batch id's from the given receipts.     |
-- |               This usually occurs when Autoremittance has been prematurely cancelled.      |
-- |                                                                                            |
-- |  Parameters:  p_receipt_method_id - Credit Card Receipt Method Id                          |
-- |               p_remit_batch_id - Selected Remittance Batch Id on the AR Receipts           |
-- |               p_receipt_date_from - From Receipt Date                                      |
-- |               p_receipt_date_to - To Receipt Date                                          |
-- |               p_receipt_number_from - From Receipt Number                                  |
-- |               p_receipt_number_to - To Receipt Number                                      |
-- |               p_tangible_prefix - Current Tangible prefix                                  |
-- |               p_cc_error_text - Credit Card error text                                     |
-- |               p_commit_flag - Y/N flag to issue commit (defaults to "Y")                   |
-- |                                                                                            |
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
    PROCEDURE clear_selected_remit_batch(
        x_error_buffer         OUT     VARCHAR2,
        x_return_code          OUT     NUMBER,
        p_receipt_method_id    IN      NUMBER,
        p_remit_batch_id       IN      NUMBER,
        p_receipt_date_from    IN      VARCHAR2,
        p_receipt_date_to      IN      VARCHAR2,
        p_receipt_number_from  IN      VARCHAR2,
        p_receipt_number_to    IN      VARCHAR2,
        p_tangible_prefix      IN      VARCHAR2 DEFAULT NULL,
        p_cc_error_text        IN      VARCHAR2 DEFAULT NULL,
        p_commit_flag          IN      VARCHAR2 DEFAULT 'Y');
END;
/