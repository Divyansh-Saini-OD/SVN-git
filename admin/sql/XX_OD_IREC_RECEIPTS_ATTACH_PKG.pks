create or replace
PACKAGE xx_od_irec_receipts_attach_pkg
AS
-- +=============================================================================+
-- |                     Office Depot                                            |
-- +=============================================================================+
-- | Name             : XX_OD_IREC_RECEIPTS_ATTACH_PKG                           |
-- | Description      : This Package 1. Adds the attachment to the Receipts      |
-- |                    2. Calls the BPEL service and generates the confirmation |
-- |                       number                                                |
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |Version    Date          Author            Remarks                           |
-- |=======    ==========    =============     ==================================|
-- |DRAFT 1A   20-JUN-2012   Suraj Charan      Initial draft version             |
-- |1.0        03-APR-2013   Suraj Charan      Parameter add in attach_file      |
-- |2.0        04-MAR-2015   Sridevi K         Modified for CR1120               |
-- +=============================================================================+
   gv_fileid                   NUMBER;
   lv_url                      VARCHAR2 (5000);
   g_test_acc_name             VARCHAR2 (100);
   g_p_product                 VARCHAR2 (150);
   g_bankaccounttype           VARCHAR2 (100);
   g_routingnumber             VARCHAR2 (100);
   g_bankaccountnumber         VARCHAR2 (100);
   g_accountholdername         VARCHAR2 (100);
   g_accountaddress1           VARCHAR2 (150);
   g_accountaddress2           VARCHAR2 (150);
   g_accountcity               VARCHAR2 (100);
   g_accountstate              VARCHAR2 (100);
   g_accountpostalcode         VARCHAR2 (50);
   g_accountcountrycode        VARCHAR2 (50);
   g_nachastandardentryclass   VARCHAR2 (50);
   g_individualidentifier      VARCHAR2 (50);
   g_companyname               VARCHAR2 (150);
   g_creditdebitindicator      VARCHAR2 (50);
   g_requestedpaymentdate      VARCHAR2 (50);
   g_billingaccountnumber      VARCHAR2 (100);
   g_remitamount               VARCHAR2 (1000);
   g_remitfee                  VARCHAR2 (1000);
   g_feewaiverreason           VARCHAR2 (150);
   g_transactioncode           VARCHAR2 (100);
   g_emailaddress              VARCHAR2 (100);
   g_remitfieldvalue           VARCHAR2 (100);

   PROCEDURE log_msg (p_msg IN VARCHAR2);

   PROCEDURE attach_file (
      p_confirmemail      IN       VARCHAR2,
      p_file_name         IN       VARCHAR2,
      p_cash_receipt_id   IN       NUMBER,
      p_blob_file         IN       BLOB,
      p_return_status     OUT      VARCHAR2
   );

   FUNCTION generate_url
      RETURN VARCHAR2;

   PROCEDURE call_ach_epay_webservice (
      p_businessid                IN       NUMBER,
      p_login                     IN       VARCHAR2,
      p_password                  IN       VARCHAR2,
      p_product                   IN       VARCHAR2,
      p_bankaccounttype           IN       VARCHAR2,
      p_routingnumber             IN       VARCHAR2,
      p_bankaccountnumber         IN       VARCHAR2,
      p_accountholdername         IN       VARCHAR2,
      p_accountaddress1           IN       VARCHAR2,
      p_accountaddress2           IN       VARCHAR2,
      p_accountcity               IN       VARCHAR2,
      p_accountstate              IN       VARCHAR2,
      p_accountpostalcode         IN       VARCHAR2,
      p_accountcountrycode        IN       VARCHAR2,
      p_nachastandardentryclass   IN       VARCHAR2,
      p_individualidentifier      IN       VARCHAR2,
      p_companyname               IN       VARCHAR2,
      p_creditdebitindicator      IN       VARCHAR2,
      p_requestedpaymentdate      IN       VARCHAR2,
      p_billingaccountnumber      IN       VARCHAR2,
      p_remitamount               IN       VARCHAR2,
      p_remitfee                  IN       VARCHAR2,
      p_feewaiverreason           IN       VARCHAR2,
      p_transactioncode           IN       VARCHAR2,
      p_emailaddress              IN       VARCHAR2,
      p_remitfieldvalue           IN       VARCHAR2,
      p_messagecode               OUT      NUMBER,
      p_messagetext               OUT      VARCHAR2,
      p_confirmation_number       OUT      VARCHAR2,
      p_status                    OUT      VARCHAR2
   );

   PROCEDURE send_mail (
      p_to            IN   VARCHAR2,
      p_from          IN   VARCHAR2,
      p_subject       IN   VARCHAR2,
      p_text_msg      IN   VARCHAR2 DEFAULT NULL,
      p_attach_name   IN   VARCHAR2 DEFAULT NULL,
      p_attach_mime   IN   VARCHAR2 DEFAULT NULL,
      p_attach_blob   IN   BLOB DEFAULT NULL,
      p_smtp_host     IN   VARCHAR2,
      p_smtp_port     IN   NUMBER DEFAULT 25
   );
END xx_od_irec_receipts_attach_pkg;
/

