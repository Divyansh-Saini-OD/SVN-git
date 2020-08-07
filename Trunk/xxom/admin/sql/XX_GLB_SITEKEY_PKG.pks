SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_GLB_SITEKEY_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :  XX_GLB_SITEKEY_PKG                                       |
-- | Rice ID: I1176 CreateServiceRequest                               |
-- | Description:  Package that contains the validation procedures for |
-- | the site key.                                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 31-DEC-2007  B.Penski         Initial draft version for   |
-- |                                       Release 1.0                 |
-- |1.0      28-Jan-2008  B. Penski        Added Validated site key out|
-- |                                       put parameter               |
-- +===================================================================+

                           
-- +========================================================================+
-- | Name: Validate_SiteKey                                                 |
-- | Description: This procedure validates that the site key object         |
-- | passed as parameter exist in the XX_GLB_SITEKEY_ALL.                   |
-- | If the object exists, the procedure returns additional information     |
-- | that can be used for initializing the application context.             |
-- |                                                                        |
-- | Input Parameters:                                                      |
-- |    p_sitekey_obj  => site key object                                   |
-- | Output Parameters:                                                     |
-- |    x_validated_site_key_rec => validated object that needs to be used  |
-- |                           in the back-end APIs                         |
-- |    x_responsibility_id => applicaiton user responsibility identifier   |
-- |    x_user_id      => application user idenntifier                      |
-- +========================================================================+
  PROCEDURE Validate_SiteKey ( p_site_key_rec           IN XX_GLB_SITEKEY_REC_TYPE
                             , x_validated_site_key_rec OUT NOCOPY XX_GLB_SITEKEY_REC_TYPE
                             , x_responsibility_id      OUT NOCOPY NUMBER
                             , x_user_id                OUT NOCOPY NUMBER
                             , x_return_status          OUT NOCOPY VARCHAR2
                             , x_return_msg             OUT NOCOPY VARCHAR2);

                           
END XX_GLB_SITEKEY_PKG;
/

SHOW ERRORS PACKAGE XX_QP_PRICELIST_SELECTION_PKG; 

PROMPT 
PROMPT Exiting.... 
PROMPT 

SET FEEDBACK ON 
EXIT; 
