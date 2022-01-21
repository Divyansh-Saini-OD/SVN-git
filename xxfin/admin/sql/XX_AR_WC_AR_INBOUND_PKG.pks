SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_AR_WC_AR_INBOUND_PKG AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   | 
-- |                Office Depot                                        | 
-- +====================================================================+
-- | Name  : XX_AR_WC_AR_INBOUND_PKG                                    |
-- | Description  : This package contains procedures related to the     |
-- | Web collect data to be processed in EBS oracle as CREDIT MEMO      |
-- | ADJUSTMENTS, UPDATE DISPUTE FLAG, REFUND FLAG which come as INBOUND|
-- | data from CAPGEMINI                                                |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version    Date          Author           Remarks                   |
-- |=======    ==========    =============    ==========================|
-- |1.0        29-NOV-2011   Bapuji N    Initial version                |
-- |                                                                    |
-- +====================================================================+

-- +=====================================================================+
-- | Name  : main_prc                                                    |
-- | Description      : This Procedure will pull all data send from WC   |
-- |                    from custom stg table and process based on       |
-- |                    Category                                         |
-- |                                                                     |
-- | Parameters      : p_debug        IN -> Set Debug DEFAULT 'N'        |
-- |                   p_process_type IN -> Procssing Type DEFAULT 'NEW' |
-- |                   p_category     IN -> TRX CATEGORY                 |
-- |                   p_invoice_id   IN -> Customer TRX ID              |
-- |                   x_retcode           OUT                           |
-- |                   x_errbuf            OUT                           |
-- +=====================================================================+
PROCEDURE main_prc( x_retcode             OUT NOCOPY  NUMBER
                  , x_errbuf              OUT NOCOPY  VARCHAR2
                  , p_debug               IN          VARCHAR2
                  , p_process_type        IN          VARCHAR2
                  , p_category            IN          VARCHAR2
                  , p_invoice_id          IN          NUMBER
                  );
				  
-- +===================================================================+
-- | Name  : create_cm_prc                                             |
-- | Description      : This Procedure will process Credit Memo in AR  |
-- |                    based on category = 'CREDIT MEMO'              |
-- |                                                                   |
-- | Parameters      : p_debug            IN -> Set Debug DEFAULT 'N'  |
-- |                   p_category         IN -> TRX CATEGORY           |
-- |                   P_customer_trx_id  IN -> Customer TRX ID        |
-- |                   P_amount           IN -> amount                 |
-- |                   P_reason_code      IN -> return reason for CM   |
-- |                   p_comments         IN -> Comments for CM        |
-- |                   p_dispute_number   IN -> Dispute Number         |
-- |                   x_request_id       OUT                          |
-- |                   X_return_status    OUT                          |
-- |                   x_return_message   OUT                          |
-- +===================================================================+
PROCEDURE create_cm_prc( P_debug             IN         VARCHAR2
                       , P_category          IN         VARCHAR2
                       , P_customer_trx_id   IN         NUMBER
                       , P_amount            IN         NUMBER
                       , P_reason_code       IN         VARCHAR2
                       , p_comments          IN         VARCHAR2
                       , p_dispute_number    IN         VARCHAR2
                       , x_request_id        OUT        NUMBER 
                       , X_return_status     OUT NOCOPY VARCHAR2
                       , x_return_message    OUT NOCOPY VARCHAR2
                       ); 	
-- +===================================================================+
-- | Name  : dispute_tran_prc                                          |
-- | Description      : This Procedure will process Disputes in AR     |
-- |                    based on category = 'DISPUTES'                 |
-- |                                                                   |
-- | Parameters      : p_debug            IN -> Set Debug DEFAULT 'N'  |
-- |                   p_category         IN -> TRX CATEGORY           |
-- |                   P_customer_trx_id  IN -> Customer TRX ID        |
-- |                   p_dispute_status   IN -> Dispute status         |
-- |                   p_dispute_number   IN -> Dispute number         |
-- |                   X_return_status    OUT                          |
-- |                   x_return_message   OUT                          |
-- +===================================================================+
PROCEDURE dispute_tran_prc( P_debug             IN         VARCHAR2
                          , P_category          IN         VARCHAR2
                          , P_customer_trx_id   IN         NUMBER
                          , p_dispute_status    IN         VARCHAR2
                          , p_dispute_number    IN         VARCHAR2
                          , x_return_status     OUT NOCOPY VARCHAR2
                          , x_return_message    OUT NOCOPY VARCHAR2
                          ); 

-- +===================================================================+
-- | Name  : refund_tran_prc                                           |
-- | Description      : This Procedure will process Disputes in AR     |
-- |                    based on category = 'REFUNDS'                  |
-- |                                                                   |
-- | Parameters      : p_debug            IN -> Set Debug DEFAULT 'N'  |
-- |                   p_category         IN -> TRX CATEGORY           |
-- |                   P_customer_trx_id  IN -> Customer TRX ID        |
-- |                   p_send_refund   IN -> refund status             |
-- |                   X_return_status    OUT                          |
-- |                   x_return_message   OUT                          |
-- +===================================================================+
PROCEDURE refund_tran_prc( P_debug             IN         VARCHAR2
                         , P_category          IN         VARCHAR2
                         , P_customer_trx_id   IN         NUMBER
                         , p_send_refund       IN         VARCHAR2
                         , x_return_status     OUT NOCOPY VARCHAR2
                         , x_return_message    OUT NOCOPY VARCHAR2
                         ); 	
						 
-- +===================================================================+
-- | Name  : create_adj_prc                                            |
-- | Description      : This Procedure will process Adjustment in AR   |
-- |                    based on category = 'ADJUSTMENTS'              |
-- |                                                                   |
-- | Parameters      : p_debug            IN -> Set Debug DEFAULT 'N'  |
-- |                   p_category         IN -> TRX CATEGORY           |
-- |                   P_customer_trx_id  IN -> Customer TRX ID        |
-- |                   P_amount           IN -> amount                 |
-- |                   p_dispute_number   IN -> Dispute number         |
-- |                   p_rec_trx_name     IN -> Activity Name          |
-- |                   x_new_adjust_number OUT                         |
-- |                   x_new_adjust_id     OUT                         |
-- |                   X_return_status     OUT                         |
-- |                   x_return_message    OUT                         |
-- +===================================================================+
PROCEDURE create_adj_prc( P_debug             IN         VARCHAR2
                        , P_category          IN         VARCHAR2
                        , P_customer_trx_id   IN         NUMBER
                        , P_amount            IN         NUMBER
                        , p_dispute_number    IN         VARCHAR2
                        , p_rec_trx_name      IN         VARCHAR2
                        , p_collector_name    IN         VARCHAR2
						, p_reason_code       IN         VARCHAR2
						, p_comments          IN         VARCHAR2
                        , x_new_adjust_number OUT        VARCHAR2
                        , x_new_adjust_id     OUT        NUMBER
                        , x_return_status     OUT NOCOPY VARCHAR2
                        , x_return_message    OUT NOCOPY VARCHAR2
                        );
						  
END XX_AR_WC_AR_INBOUND_PKG;
/
SHOW ERRORS PACKAGE XX_AR_WC_AR_INBOUND_PKG;
EXIT;
