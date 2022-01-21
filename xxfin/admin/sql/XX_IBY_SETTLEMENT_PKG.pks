CREATE OR REPLACE PACKAGE APPS.xx_iby_settlement_pkg
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | PACKAGE NAME: Settlement and Payment Processing                   |
-- |                                                                   |
-- | RICE ID     : I0349                                               |
-- |                                                                   |
-- | DESCRIPTION : To populate the XX_IBY_BATCH_TRXNS (101) and        |
-- |               XX_IBY_BATCH_TRXNS_DET (201) tables.                |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ==========   ==================    =======================|
-- |1.0      30-AUG-2007  Gowri Shankar         Initial version        |
-- |                                                                   |
-- |1.1      11-SEP-2007  Gowri Shankar         Fixed the Code for the |
-- |                                            Defect ID 2302         |
-- |                                                                   |
-- |1.2      10-DEC-2007  Gowri Shankar         Defect ID 2984         |
-- |1.3      20-DEC-2007  Gowri Shankar         Defect ID 2808         |
-- |1.4      13-FEB-2008  Gowri Shankar         Defect 4606            |
-- |1.5      06-MAR-2008  Subbarao Bangaru      Defect 4870            |
-- |1.6      09-APR-2008  Subbarao Bangaru      Defect 5901            |
-- |1.7      17-JUL-2008  Subbarao Bangaru      Defect 8403            |
-- |1.8      21-OCT-2008  Anitha D              Defect 11555           |
-- |1.9      24-MAR-2010  R. Aldridge           Defect 10836 (CR 898)  |
--                                              SDR changes            |
-- |1.10     01-JUL-2012  Rohit Ranjan         Defect#13405 added multi|
-- |                                            threading functionality|
-- |26.6     03-JUN-2015 Suresh Ponnambalam   Tokenization: Added token|
-- |                                          flag to xx_ar_invoice_ods|
-- +===================================================================+

    -- +===================================================================+
-- | PROCEDURE  : XX_STG_RECEIPT_FOR_SETTLEMENT                        |
-- |                                                                   |
-- | DESCRIPTION: This is 1 of 3 methods for staging receipts to the   |
-- |              settlement tables (XX_IBY_BATCH_TRXNS and            |
-- |              XX_IBY_BATCH_TRXNS_DET) before creating the file to  |
-- |              sent to AJB.                                         |
-- |                                                                   |
-- |              This particular public method is called only by HVOP |
-- |              and for POS internal store customers ONLY.           |
-- |                                                                   |
-- |              Note: There are a total of 3 methods (1 is private)  |
-- |                                                                   |
-- | PARAMETERS : p_order_payment_id  -> order payment id from         |
-- |                                     xx_ar_order_receipt_dtl       |
-- |                                                                   |
-- | RETURNS    : x_settlement_staged -> TRUE if staged, else FALSE    |
-- |              x_error_message     -> Error message if not staged   |
-- +===================================================================+
    PROCEDURE xx_stg_receipt_for_settlement(
        p_order_payment_id   IN      VARCHAR2,
        x_settlement_staged  OUT     BOOLEAN,
        x_error_message      OUT     VARCHAR2);

-- +===================================================================+
-- | PROCEDURE  : CLBATCH                                              |
-- |                                                                   |
-- | DESCRIPTION: To create the settlemt file to send to AJB during    |
-- |              the Batch Close process.                             |
-- |                                                                   |
-- |              Note: This procedure calls a private procedure for   |
-- |              for staging credit card refunds ($0.00 receipts). It |
-- |              is 1 of 3 methods for staging settlement records     |
-- |                                                                   |
-- | PARAMETERS : p_ajb_http_transfer                                  |
-- |              p_printer_style                                      |
-- |              p_printer_name                                       |
-- |              p_number_copies                                      |
-- |              p_save_output                                        |
-- |              p_print_together                                     |
-- |              p_validate_printer                                   |
-- |                                                                   |
-- | RETURNS    : x_error_buff -> Error message                        |
-- |              x_ret_code   -> Completion status code               |
-- +===================================================================+
    PROCEDURE clbatch(
        x_error_buff         OUT     VARCHAR2,
        x_ret_code           OUT     NUMBER,
        p_ajb_http_transfer  IN      VARCHAR2,
        p_printer_style      IN      VARCHAR2,
        p_printer_name       IN      VARCHAR2,
        p_number_copies      IN      NUMBER,
        p_save_output        IN      VARCHAR2,
        p_print_together     IN      VARCHAR2,
        p_validate_printer   IN      VARCHAR2);

-- +===================================================================+
-- | PROCEDURE  : BULKINSERT                                           |
-- |                                                                   |
-- | DESCRIPTION: To insert into the history tables                    |
-- |              XX_IBY_BATCH_TRXNS_HISTORY,                          |
-- |              XX_IBY_BATCH_TRXNS_201_HISTORY                       |
-- |                                                                   |
-- | PARAMETERS : p_payment_batch_number                               |
-- |              p_limit_translation_name                             |
-- |                                                                   |
-- | RETURNS    : x_error_buff, x_ret_code                             |
-- +===================================================================+
    PROCEDURE bulkinsert(
        x_error_buf             OUT     VARCHAR2,
        x_ret_code              OUT     NUMBER,
        p_payment_batch_number  IN      VARCHAR2,
        p_limit_value           IN      NUMBER);

-- +===================================================================+
-- | PROCEDURE  : EMAIL                                                |
-- |                                                                   |
-- | DESCRIPTION: To send the Batch Close details to the user in the   |
-- |              email called from the concurrent program             |
-- |              "OD: IBY Settlement E-mail Program"                  |
-- |                                                                   |
-- | PARAMETERS :                                                      |
-- |                                                                   |
-- | RETURNS    : x_error_buff, x_ret_code,x_receipt_ref               |
-- +===================================================================+
    PROCEDURE email(
        x_error_buf        OUT     VARCHAR2,
        x_ret_code         OUT     NUMBER,
        p_batch_file_name  IN      VARCHAR2,
        p_amex_file_name   IN      VARCHAR2,
        p_batch_date       IN      DATE,
        p_create_file_ajb  IN      VARCHAR2);

-- +===================================================================+
-- | PROCEDURE  : PURGE                                                |
-- |                                                                   |
-- | DESCRIPTION: To purge the History table of 101 and 201 tables     |
-- |                                                                   |
-- | PARAMETERS :                                                      |
-- |                                                                   |
-- | RETURNS    : x_error_buff, x_ret_code,x_receipt_ref               |
-- +===================================================================+
    PROCEDURE PURGE(
        x_error_buff  OUT  VARCHAR2,
        x_ret_code    OUT  NUMBER);

-- +===================================================================+
-- | PROCEDURE  : PMTCLOSEDATA                                         |
-- |                                                                   |
-- | DESCRIPTION: To get the batch details during the Close call       |
-- |                                                                   |
-- | PARAMETERS :                                                      |
-- |                                                                   |
-- | RETURNS    : x_oapfbatchdate, x_oapfcreditamount,x_oapfsalesamount|
-- |            x_oapfbatchtotal, x_oapfcurr, x_oapfnumtrxns           |
-- |            x_oapfvpsbatchid, x_oapfgwbatchid, x_oapfbtatchstate   |
-- +===================================================================+
    PROCEDURE pmtclosedata(
        x_oapfbatchdate     OUT  VARCHAR2,
        x_oapfcreditamount  OUT  VARCHAR2,
        x_oapfsalesamount   OUT  VARCHAR2,
        x_oapfbatchtotal    OUT  VARCHAR2,
        x_oapfcurr          OUT  VARCHAR2,
        x_oapfnumtrxns      OUT  VARCHAR2,
        x_oapfvpsbatchid    OUT  VARCHAR2,
        x_oapfgwbatchid     OUT  VARCHAR2,
        x_oapfbtatchstate   OUT  VARCHAR2);

-- +===================================================================+
-- | PROCEDURE  : PRE_CAPTURE_CCRETUNRN                                |
-- |                                                                   |
-- | DESCRIPTION: This is 1 of 2 public methods to populate the staging|
-- |              settlement tables (XX_IBY_BATCH_TRXNS and            |
-- |              XX_IBY_BATCH_TRXNS_DET) before creating the file to  |
-- |              sent to AJB.                                         |
-- |                                                                   |
-- |              This particular method is called only by Automatic   |
-- |              Remittance via Office Depot's custom servlet         |
-- |              There are a total of 3 methods.                      |
-- |                                                                   |
-- | PARAMETERS : p_oapf_action, p_oapf_currency                       |
-- |              p_oapf_amount, p_receipt_currency                    |
-- |              p_oapfStoreId, p_oapfTransactionId,                  |
-- |              p_oapf_trxn_ref, p_oapf_order_id                     |
-- |                                                                   |
-- | RETURNS    : x_error_buff, x_ret_code                             |
-- +===================================================================+
    PROCEDURE pre_capture_ccretunrn(
        x_error_buf          OUT     VARCHAR2,
        x_ret_code           OUT     NUMBER,
        x_receipt_ref        OUT     VARCHAR2,
        p_oapfaction         IN      VARCHAR2,
        p_oapfcurrency       IN      VARCHAR2 DEFAULT NULL,
        p_oapfamount         IN      VARCHAR2 DEFAULT NULL,
        p_oapfstoreid        IN      VARCHAR2 DEFAULT NULL,
        p_oapftransactionid  IN      VARCHAR2 DEFAULT NULL,
        p_oapftrxn_ref       IN      VARCHAR2 DEFAULT NULL,
        p_oapforder_id       IN      VARCHAR2 DEFAULT NULL);

-- +===================================================================+
-- | PROCEDURE  : XX_AR_INVOICE_ODS                                    |
-- |                                                                   |
-- | DESCRIPTION: The Procedure is used in the I0349 Auth              |
-- |              to pick up Invoice that are sent to AJB              |
-- |              The data is inserted into the table by the pkg       |
-- |              XX_AR_IREC_PAYMENTS.INVOICE_TANGIBLEID               |
-- |                                                                   |
-- | PARAMETERS :  p_oapforderid                                       |
-- |                                                                   |
-- | RETURNS    : x_trx_number                                         |
-- +===================================================================+
    PROCEDURE xx_ar_invoice_ods(
        p_oapforderid  IN      VARCHAR2,
        x_trx_number   OUT     VARCHAR2,
        x_field_31     OUT     VARCHAR2,
		x_token_flag   OUT     VARCHAR2
		);

-- +===================================================================+
-- | PROCEDURE  : UPDATE_PROCESS_INDICATOR                             |
-- |                                                                   |
-- | DESCRIPTION: To update the process indicator of the future dated  |
-- |              records XX_IBY_BATCH_TRXNS, XX_IBY_BATCH_TRXNS_DET   |
-- |                                                                   |
-- | PARAMETERS :                                                      |
-- |                                                                   |
-- | RETURNS    : x_error_buf, x_ret_code                              |
-- +===================================================================+
    PROCEDURE update_process_indicator(
        x_error_buf  OUT     VARCHAR2,
        x_ret_code   OUT     NUMBER,
        p_date       IN      DATE);

-- +===================================================================+
-- | PROCEDURE  : process_cc_processor_response                        |
-- |                                                                   |
-- | DESCRIPTION: Procedure is used to update AMEX iRec cash receipts  |
-- |              with the PS2000 code.                                |
-- |              Note, this is called by the TxnCustomer_ods.java     |
-- |              class in $CUSTOM_JAVA_TOP/ibyextend/                 |
-- |                                                                   |
-- | PARAMETERS : See below                                            |
-- | RETURNS    : Exception on error                                   |
-- +===================================================================+
    PROCEDURE process_cc_processor_response(
        p_payment_system_order_number  IN  iby_fndcpt_tx_extensions.payment_system_order_number%TYPE,
        p_transaction_id               IN  iby_fndcpt_tx_operations.transactionid%TYPE,
        p_instrument_sub_type          IN  iby_trxn_summaries_all.instrsubtype%TYPE,
        p_auth_code                    IN  iby_trxn_core.authcode%TYPE,
        p_status                       IN  VARCHAR2,
        p_ret_code_value               IN  ar_cash_receipts_all.attribute4%TYPE,
        p_ps2000_value                 IN  ar_cash_receipts_all.attribute4%TYPE);

-- +===================================================================+
-- | PROCEDURE  : RETRY_ERRORS                                         |
-- |                                                                   |
-- | DESCRIPTION: Procedure to retry inserting into the  XX_IBY tables |
-- |                receipt that are pending and/or error status       |
-- |                                                                   |
-- | PARAMETERS : p_from_Date, p_to_Date, p_request_id,p_file_name     |
-- |                                                                   |
-- | RETURNS    : x_error_buf, x_ret_code                              |
-- +===================================================================+
    PROCEDURE retry_errors(
        x_error_buff         OUT     VARCHAR2,
        x_ret_code           OUT     NUMBER,
        p_org_id             IN      NUMBER,
        p_from_date          IN      VARCHAR2,
        p_to_date            IN      VARCHAR2,
        p_request_id         IN      NUMBER,
        p_file_name          IN      VARCHAR2,
        p_thread_count       IN      NUMBER,
        p_remit_status_flag  IN      VARCHAR2,
        p_debug_flag         IN      VARCHAR2 DEFAULT 'Y');
        
        
-- +===================================================================+
   -- | PROCEDURE  : RETRY_ERRORS_CHILD                                   |
   -- |                                                                   |
   -- | DESCRIPTION: Procedure to retry inserting into the  XX_IBY tables |
   -- |                receipt that are pending and/or error status       |
   -- |                                                                   |
   -- | PARAMETERS : p_from_Date, p_to_Date, p_request_id,p_file_name     |
   -- |                                                                   |
   -- | RETURNS    : x_error_buf, x_ret_code                              |
   -- +===================================================================+
    PROCEDURE retry_errors_child(
        x_error_buff         OUT     VARCHAR2,
        x_ret_code           OUT     NUMBER,
        p_org_id             IN      NUMBER,
        p_from_date          IN      VARCHAR2,
        p_to_date            IN      VARCHAR2,
        p_request_id         IN      NUMBER,
        p_file_name          IN      VARCHAR2,
        p_thread             IN      VARCHAR2,
        p_order_id_from      IN      VARCHAR2,
        p_order_id_to        IN      VARCHAR2,
        p_remit_status_flag  IN      VARCHAR2,
        p_debug_flag         IN      VARCHAR2 DEFAULT 'Y');
        
END xx_iby_settlement_pkg;
/
