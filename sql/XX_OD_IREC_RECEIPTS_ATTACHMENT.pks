{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fswiss\fcharset0 Arial;}}
{\*\generator Msftedit 5.41.21.2500;}\viewkind4\uc1\pard\f0\fs20 create or replace\par
PACKAGE XX_OD_IREC_RECEIPTS_ATTACHMENT AS \par
\par
 PROCEDURE attach_file( p_file_name IN varchar2, p_cash_receipt_id IN Number,p_return_status OUT varchar2);\par
 \par
 PROCEDURE CALL_ACH_EPAY_WEBSERVICE(\par
    p_businessId              IN NUMBER,\par
    p_login                   IN VARCHAR2,\par
    p_password                IN VARCHAR2,\par
    p_product                 IN VARCHAR2,\par
    p_bankAccountType         IN VARCHAR2,\par
    p_routingNumber           IN VARCHAR2,\par
    p_bankAccountNumber       IN VARCHAR2,\par
    p_accountHolderName       IN VARCHAR2,\par
    p_accountAddress1         IN VARCHAR2,\par
    p_accountAddress2         IN VARCHAR2,\par
    p_accountCity             IN VARCHAR2,\par
    p_accountState            IN VARCHAR2,\par
    p_accountPostalCode       IN VARCHAR2,\par
    p_accountCountryCode      IN VARCHAR2,\par
    p_nachaStandardEntryClass IN VARCHAR2,\par
    p_individualIdentifier    IN VARCHAR2,\par
    p_companyName             IN VARCHAR2,\par
    p_creditDebitIndicator    IN VARCHAR2,\par
    p_requestedPaymentDate    IN VARCHAR2,\par
    p_billingAccountNumber    IN VARCHAR2,\par
    p_remitAmount             IN VARCHAR2,\par
    p_remitFee                IN VARCHAR2,\par
    p_feeWaiverReason         IN VARCHAR2,\par
    p_transactionCode         IN VARCHAR2,\par
    p_emailAddress            IN VARCHAR2,\par
    p_remitFieldValue         IN VARCHAR2,\par
    p_messageCode OUT NUMBER,\par
    p_messageText OUT VARCHAR2,\par
    p_confirmation_number OUT VARCHAR2,\par
    p_status out varchar2);\par
\par
END XX_OD_IREC_RECEIPTS_ATTACHMENT;\par
}
 