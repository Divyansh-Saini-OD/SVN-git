create or replace 
PACKAGE XX_AR_VPS_CM_TO_INV_PKG
AS
-- +============================================================================================+
-- |  Office Depot                                                                          	  |
-- +============================================================================================+
-- |  Name:  XX_AR_VPS_CM_TO_INV_PKG                                                     	      |
-- |                                                                                            |
-- |  Description:  This packages helps to  autoapplication of credit memo to open invoices     | 
-- |                E7031 - AR VPS Auto Apply Credit Memos            	                        |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         11-AUG-2017  Uday Jadhav       Initial version                                 |
-- +============================================================================================+
    g_pkg_name VARCHAR2(50) :='XX_AR_VPS_CM_TO_INV_PKG';
    PROCEDURE APPLY_CM_INV_PROCESS (
                                      p_cm_customer_trx_id    IN  NUMBER
                                     ,p_cm_trx_number         IN VARCHAR2
                                     ,p_inv_customer_trx_id   IN  NUMBER
                                     ,p_inv_trx_number        IN VARCHAR2
                                     ,p_payment_schedule_id   IN  NUMBER
                                     ,p_amount_applied        IN  NUMBER
                                     ,p_msg_comments          IN  VARCHAR2
                                     ,p_user_id               IN  NUMBER
                                     ,p_resp_id               IN  NUMBER
                                     ,p_resp_appl_id          IN  NUMBER
                                     ,p_debug_flag            IN  VARCHAR2
                                     ,p_cycle_date            IN  VARCHAR2
                                     ,x_msg_count             OUT NUMBER
                                     ,x_msg_data              OUT VARCHAR2
                                     ,x_return_status         OUT VARCHAR2
                                   );

                    PROCEDURE MAIN (
                                      p_errbuf_out              OUT      VARCHAR2
                                     ,p_retcod_out              OUT      VARCHAR2
                                     ,p_vendor_number           IN       VARCHAR2 
                                   );

          PROCEDURE CM_MATCH_PROCESS (
                                        p_errbuf_out              OUT      VARCHAR2
                                       ,p_retcod_out              OUT      VARCHAR2
                                       ,p_vendor_number           IN       VARCHAR2
                                       ,p_attr_group_id           IN       NUMBER
                                      );
                      
END XX_AR_VPS_CM_TO_INV_PKG;
/
