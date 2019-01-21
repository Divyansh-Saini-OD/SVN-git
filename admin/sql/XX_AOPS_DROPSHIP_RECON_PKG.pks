create or replace 
PACKAGE XX_AOPS_DROPSHIP_RECON_PKG
AS 

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AOPS_DROPSHIP_RECON_PKG	                                                |
-- | RICE ID 	 :  AOPS DropShip Recon                                  			|
-- |		            								        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         08/09/2017   Avinash Baddam   Initial version                                  |
-- +============================================================================================+
  --=================================================================
  -- Declaring Global variables
  --=================================================================
  gc_package_name        CONSTANT VARCHAR2 (50) := 'XX_AOPS_DROPSHIP_RECON_PKG';

PROCEDURE Invoke_webservice(p_retry_errors IN 	VARCHAR2
                           ,p_errbuf       OUT  VARCHAR2
                           ,p_retcode      OUT  VARCHAR2);
   
PROCEDURE load_staging(p_date_from    IN   DATE, 
                       p_errbuf       OUT  VARCHAR2,
                       p_retcode      OUT  VARCHAR2);   
   
--+============================================================================+
--| Name          : main                                                       |
--| Description   : main procedure will be called from the concurrent program  |
--| Parameters    : p_debug_level          IN       VARCHAR2                   |        
--| Returns       :                                                            |
--|                 x_errbuf                  OUT      VARCHAR2                |
--|                 x_retcode                 OUT      NUMBER                  |
--|                                                                            |
--|                                                                            |
--+============================================================================+
PROCEDURE main(p_errbuf       OUT  VARCHAR2
              ,p_retcode      OUT  VARCHAR2
              ,p_from_date         VARCHAR2
              ,p_retry_errors      VARCHAR2 
              ,p_debug             VARCHAR2);

END XX_AOPS_DROPSHIP_RECON_PKG;
/