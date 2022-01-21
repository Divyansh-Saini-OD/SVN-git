SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT 'Creating Procedure XX_AR_RCPT_CLR_ERRORS_PROC'

CREATE OR REPLACE PROCEDURE XX_AR_RCPT_CLR_ERRORS_PROC
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      XX_AR_RCPT_CLR_ERRORS_PROC                            |
-- | Description : To clear the credit card errors                     |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.1       02-May-2008  Rama Krishna K       Rcpt errclearing script|
-- +===================================================================+
IS
BEGIN
DBMS_APPLICATION_INFO.SET_CLIENT_INFO('404');
    UPDATE    apps.ar_cash_receipts CR
    SET       CR.selected_remittance_batch_id = NULL
    WHERE     CR.cash_receipt_id IN (SELECT CR.cash_receipt_id
    FROM   apps.ar_cash_receipt_history CRH
          ,apps.ar_cash_receipts CR
          ,apps.ar_receipt_methods RM
          ,apps.ar_receipt_classes RCLASS
    WHERE  CRH.cash_receipt_id = CR.cash_receipt_id
    AND    RM.receipt_method_id = CR.receipt_method_id
    AND    RCLASS.receipt_class_id = RM.receipt_class_id
    AND    RM.receipt_method_id = 2005
    AND    CR.remittance_bank_account_id = 10780
    AND    CR.selected_remittance_batch_id IS NOT NULL
    AND    CR.cc_error_flag IS NULL
    AND    CR.currency_code = 'USD'
    AND    CRH.status = 'CONFIRMED'
    AND    CRH.current_record_flag = 'Y'
    AND    RCLASS.remit_method_code = 'STANDARD'
    AND    RM.payment_type_code='CREDIT_CARD');
    --DBMS_OUTPUT.PUT_LINE('Row Count : ' || sql%rowcount);

COMMIT;

END XX_AR_RCPT_CLR_ERRORS_PROC;

/
show error

EXEC XX_AR_RCPT_CLR_ERRORS_PROC;
