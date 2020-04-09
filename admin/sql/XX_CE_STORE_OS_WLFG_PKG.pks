create or replace PACKAGE      XX_CE_STORE_OS_WLFG_PKG AS
-- +=================================================================================+
-- |                       Office Depot							                     |
-- |                          					                 	                 |
-- +=================================================================================+
-- | Name       : XX_CE_STORE_OS_WLFG_PKG.pks                                        |
-- | Description: OD Cash Management Store Over/Short and Cash Sweep Extension 		 |
-- |			  for Wells FargoBank    	  										 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version  Date         Authors            Remarks                                 |
-- |=======  ===========  ===============    ============================            |
-- |1.0      13-Mar-2020  Amit Kumar        Initial version               	         |
-- |                                                                                 |
-- +=================================================================================+
-- | Name        : OD: CM Store Over/Short and Cash Concentration WF                 |
-- | Description : This procedure will be used to process the                        |
-- |               OD Cash Management Store Deposit Over/Short                       |
-- |               and Cash Concentration extention for Wells Fargo Bank             |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE  STORE_OS_CC_MAIN
                        (
						 x_errbuf        OUT NOCOPY VARCHAR2
                        ,x_retcode       OUT NOCOPY NUMBER
						, p_corpbank_acct_id IN NUMBER
                        ) ;
function   PF_DERIVE_LOB ( pfv_location      IN  VARCHAR2
                         , pfv_cost_center   IN  VARCHAR2
                          )
   return varchar2 ;

END XX_CE_STORE_OS_WLFG_PKG ;