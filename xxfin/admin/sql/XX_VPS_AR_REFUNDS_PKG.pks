create or replace 
PACKAGE      xx_vps_ar_refunds_pkg AS
-- =========================================================================================================================
--   NAME:       XX_VPS_AR_REFUNDS_PKG .
--   PURPOSE:    This package contains procedures and functions for the
--                VPS AR Automated Refund process.
--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  -------------------------------------------------------------------------------
--   1.0        08/01/2017  Uday Jadhav      1. Created this package. 
-- =========================================================================================================================
   g_print_line  VARCHAR2 (120)
      := '------------------------------------------------------------------------------------------------------------------------';

   TYPE idcustrec IS RECORD (
      customer_id      NUMBER
    , customer_number  VARCHAR2 (30)
    , org_id           NUMBER
    , refund_alt       VARCHAR2 (30)
    , trx_count        NUMBER
   );

   TYPE idtrxrec IS RECORD (
      source                  xx_ar_refund_trx_id_v.source%TYPE
    , customer_id             NUMBER
    , customer_number         hz_cust_accounts.account_number%TYPE
    , party_name              hz_parties.party_name%TYPE
    , aops_customer_number    hz_cust_accounts.orig_system_reference%TYPE 
    , cash_receipt_id         NUMBER
    , customer_trx_id         NUMBER
    , trx_id                  NUMBER
    , class                   VARCHAR2 (30)
    , trx_number              VARCHAR2 (30)
    , trx_date                DATE
    , trx_currency_code       VARCHAR2 (15)
    , refund_amount           NUMBER
    , cash_applied_date_last  DATE
    , selected_flag           VARCHAR2 (1) 
    , refund_request          VARCHAR2 (150)
    , refund_status           VARCHAR2 (150) 
    , org_id                  NUMBER
    , location_id             NUMBER
    , address1                VARCHAR2 (240)
    , address2                VARCHAR2 (240)
    , address3                VARCHAR2 (240)
    , city                    VARCHAR2 (60)
    , state                   VARCHAR2 (60)
    , province                VARCHAR2 (60)
    , postal_code             VARCHAR2 (60)
    , country                 VARCHAR2 (60)
    , om_hold_status          VARCHAR2 (10)
    , om_delete_status        VARCHAR2 (10)
    , om_store_number         VARCHAR2 (60)
    , store_customer_name     VARCHAR2 (200)  
    , ref_mailcheck_id        NUMBER  
   );

   PROCEDURE identify_refund_trx (
      errbuf               OUT NOCOPY     VARCHAR2
    , retcode              OUT NOCOPY     VARCHAR2
    , p_trx_date_from      IN             VARCHAR2
    , p_trx_date_to        IN             VARCHAR2
    , p_amount_from        IN             NUMBER DEFAULT 0.000001
    , p_amount_to          IN             NUMBER DEFAULT 9999999999999 
    , p_process_type       IN             VARCHAR2       
    , p_only_for_user_id   IN             NUMBER DEFAULT NULL
    , p_org_id             IN             VARCHAR2
    , p_limit_size         IN             NUMBER    
   );

   PROCEDURE create_refund (
      errbuf         OUT NOCOPY     VARCHAR2
    , retcode        OUT NOCOPY     VARCHAR2 
    , p_om_escheats  IN             VARCHAR2
    , p_user_id      IN             NUMBER          
   );

   PROCEDURE create_cm_adjustment (
      p_payment_schedule_id  IN             NUMBER
    , p_customer_trx_id      IN             NUMBER
    , p_customer_number      IN             VARCHAR2
    , p_amount               IN             NUMBER
    , p_org_id               IN             NUMBER
    , p_adj_name             IN             VARCHAR2
    , p_reason_code          IN             VARCHAR2
    , p_comments             IN             VARCHAR2
    , o_adj_num              OUT NOCOPY     VARCHAR2
    , x_return_status        OUT NOCOPY     VARCHAR2
    , x_msg_count            OUT NOCOPY     NUMBER
    , x_msg_data             OUT NOCOPY     VARCHAR2
   );

   PROCEDURE create_receipt_writeoff (
      p_refund_header_id           IN             NUMBER 
    , p_cash_receipt_id            IN             NUMBER
    , p_customer_number            IN             VARCHAR2
    , p_amount                     IN             NUMBER
    , p_org_id                     IN             NUMBER
    , p_wo_name                    IN             VARCHAR2
    , p_reason_code                IN             VARCHAR2
    , p_comments                   IN             VARCHAR2
    , p_escheat_flag               IN             VARCHAR2
    , o_receivable_application_id  OUT NOCOPY     VARCHAR2
    , x_return_status              OUT NOCOPY     VARCHAR2
    , x_msg_count                  OUT NOCOPY     NUMBER
    , x_msg_data                   OUT NOCOPY     VARCHAR2
   );

   PROCEDURE unapply_prepayment (
      p_receivable_application_id  IN             NUMBER
    , x_return_status              OUT NOCOPY     VARCHAR2
    , x_msg_count                  OUT NOCOPY     NUMBER
    , x_msg_data                   OUT NOCOPY     VARCHAR2
   );

   PROCEDURE unapply_on_account (
      p_receivable_application_id  IN             NUMBER
    , x_return_status              OUT NOCOPY     VARCHAR2
    , x_msg_count                  OUT NOCOPY     NUMBER
    , x_msg_data                   OUT NOCOPY     VARCHAR2
   );
 
   PROCEDURE create_ap_invoice (
      errbuf   IN OUT NOCOPY  VARCHAR2
    , errcode  IN OUT NOCOPY  INTEGER
   );
 

   PROCEDURE print_errors (p_request_id IN NUMBER);

   PROCEDURE update_dffs;
   
   PROCEDURE send_email_notif;

   FUNCTION get_status_descr (p_status_code   IN  VARCHAR2
                             ,p_escheat_flag  IN  VARCHAR2
                             )
                             RETURN VARCHAR2; 
   PROCEDURE insert_into_int_tables(errbuf OUT VARCHAR2
                                   ,retcode OUT NUMBER); 
END xx_vps_ar_refunds_pkg;
/