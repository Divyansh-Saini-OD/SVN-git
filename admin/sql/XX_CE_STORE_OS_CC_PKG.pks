CREATE OR REPLACE PACKAGE APPS.XX_CE_STORE_OS_CC_PKG AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : XX_CE_STORE_OS_CC_PKG.pks                                          |
-- | Description: OD Cash Management Store Over/Short and Cash Sweep Extension       |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version  Date         Authors            Remarks                                 |
-- |=======  ===========  ===============    ============================            |
-- |1.0      23-JUL-2007  Terry Banks        Initial version                         |
-- |                                                                                 |
-- +=================================================================================+
-- | Name        :                                                                   |
-- | Description : This procedure will be used to process the                        |
-- |               OD Cash Management Store Deposit Over/Short                       |
-- |               and Cash Concentration extention.                                 |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE  STORE_OS_CC_MAIN 
                        (x_errbuf        OUT NOCOPY VARCHAR2
                        ,x_retcode       OUT NOCOPY NUMBER
                        ) ;
function   PF_DERIVE_LOB ( pfv_location      IN  VARCHAR2
                         , pfv_cost_center   IN  VARCHAR2
                          )
   return varchar2 ;
   
END XX_CE_STORE_OS_CC_PKG ;
/
