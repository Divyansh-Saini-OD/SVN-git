create or replace PACKAGE XX_AR_VPS_ADJUSTMENTS_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	     :  XX_AR_VPS_ADJUSTMENTS_PKG                                                   |
-- |  RICE ID 	 :  E7047                                          			                    |
-- |  Description:                                                                          	|
-- |                                                           				                    |        
-- +============================================================================================+
-- | Version     Date          Author              Remarks                                      |
-- | =========   ===========   =============       =============================================|
-- | 1.0         28-JUN-2018   Havish Kasina       Initial version                              |
-- +============================================================================================+

-- +===============================================================================================+
-- |  Name	 : stage_vps_adj_dtls                                                                  |                 	
-- |  Description: This procedure is to insert the VPS Small Dollar and Penny transactions to the  |
-- |               staging table                                                                   |
-- ================================================================================================|
							  
PROCEDURE stage_vps_adj_dtls(p_errbuf         OUT  VARCHAR2
                            ,p_retcode        OUT  VARCHAR2   
                            ,p_debug          IN   VARCHAR2
							); 

-- +===================================================================+
-- | Name  : update_error_status_prc                                   |
-- | Description      : This Procedure will update errors flag and     |
-- |                    error message based on above calling api's     |
-- |                                                                   |
-- | Parameters      : p_customer_trx_id  IN -> Customer TRX ID        |
-- |                   p_process_flag     IN -> Process Flag           |
-- |                   p_error_message    IN -> Error message          |
-- |                   p_adjustment_id    IN -> Adjustment ID          |
-- |                   p_adjustment_num   IN -> Adjustment Number      |
-- +===================================================================+
PROCEDURE update_status_prc ( p_customer_trx_id IN NUMBER
                            , p_process_flag    IN VARCHAR2
                            , p_error_message   IN VARCHAR2
							, p_adjustment_id   IN NUMBER
							, p_adjustment_num  IN VARCHAR2
                            );

-- +===================================================================+
-- | Name  : CREATE_ADJ_PRC                                            |
-- | Description      : This Procedure will process Adjustment in AR   |
-- |                    based on category = 'ADJUSTMENTS'              |
-- |                                                                   |
-- | Parameters      : p_debug            IN -> Set Debug DEFAULT 'N'  |
-- |                   p_category         IN -> TRX CATEGORY           |
-- |                   p_inp_adj_rec      IN -> Customer TRX ID        |
-- |                   x_new_adjust_number OUT                         |
-- |                   x_new_adjust_id     OUT                         |
-- |                   X_return_status     OUT                         |
-- |                   x_return_message    OUT                         |
-- +===================================================================+
PROCEDURE create_adj_prc( p_debug             IN         VARCHAR2
                        , p_category          IN         VARCHAR2
                        , p_inp_adj_rec       IN         ar_adjustments%ROWTYPE
                        , x_new_adjust_number OUT        VARCHAR2
                        , x_new_adjust_id     OUT        NUMBER
                        , x_return_status     OUT NOCOPY VARCHAR2
                        , x_return_message    OUT NOCOPY VARCHAR2
                        );

-- +============================================================================================+
-- | Name  : main_prc                                                                           |
-- | Description      : This is the main procedure to create and approve the VPS Penny and Small|
-- |                    Dollar Adjustments                                                      |
-- |                                                                                            |
-- | Parameters       : p_retcode     OUT                                                       |
-- |                    p_errbuf      OUT                                                       |
-- |                    p_debug       IN  -> Set Debug DEFAULT 'N'                              |
-- +============================================================================================+
PROCEDURE main_prc( p_retcode        OUT NOCOPY  NUMBER
                   ,p_errbuf         OUT NOCOPY  VARCHAR2                 
                   ,p_debug          IN          VARCHAR2  DEFAULT 'N'
				   );
				   
END XX_AR_VPS_ADJUSTMENTS_PKG;
/
SHOW ERRORS;