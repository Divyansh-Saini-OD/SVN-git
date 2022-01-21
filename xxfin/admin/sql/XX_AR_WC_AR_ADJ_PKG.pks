create or replace 
PACKAGE XX_AR_WC_AR_ADJ_PKG AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                Office Depot                                        |
-- +====================================================================+
-- | Name  : XX_AR_WC_AR_ADJ_PKG                                        |
-- | Description  : This package contains procedures related to the     |
-- | Web collect data to be processed in EBS oracle as                  |
-- | ADJUSTMENTS  which come as INBOUND                                 |
-- | data from CAPGEMINI                                                |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version    Date          Author           Remarks                   |
-- |=======    ==========    =============    ==========================|
-- |1.0        7-APR-2016   Madhan Sanjeevi   Initial version           |
-- |                                          Created for Defect# 36388 |
-- +====================================================================+

-- +=====================================================================+
-- | Name  : main_prc                                                    |
-- | Description      : This Procedure will pull all data send from WC   |
-- |                    from custom stg table and process based on       |
-- |                    Category                                         |
-- |                                                                     |
-- | Parameters      : p_debug        IN -> Set Debug DEFAULT 'N'        |
-- |                   p_process_type IN -> Processing Type DEFAULT 'NEW'|
-- |                   p_category     IN -> TRX CATEGORY                 |
-- |                   p_invoice_id   IN -> Customer TRX ID              |
-- |                   x_retcode           OUT                           |
-- |                   x_errbuf            OUT                           |
-- +=====================================================================+
PROCEDURE main_prc( x_retcode             OUT NOCOPY  NUMBER
                  , x_errbuf              OUT NOCOPY  VARCHAR2
                  , p_debug               IN          VARCHAR2
                  , p_invoice_id          IN          NUMBER
				  , p_cre_adj             IN          VARCHAR2
				  , p_appr_adj            IN          VARCHAR2 DEFAULT 'N'
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

END XX_AR_WC_AR_ADJ_PKG;
/