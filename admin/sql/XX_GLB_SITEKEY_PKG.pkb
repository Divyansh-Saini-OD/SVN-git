SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_GLB_SITEKEY_PKG AS

 -- Local Constants Definition
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
-- |1.1      05-Feb-2008  B. Penski        changed the query where to  |
-- |                                       use Upper case function     |
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
                             , x_return_msg             OUT NOCOPY VARCHAR2) AS
  
    
  BEGIN

        x_return_status:= FND_API.G_RET_STS_ERROR; 
        x_return_msg:= FND_API.G_MISS_CHAR;
        x_validated_site_key_rec := XX_GLB_SITEKEY_REC_TYPE(null,null,null,null,null,null,-1);
                                                            
        
        SELECT  site_brand, site_mode, country_code,
	        language_code, operating_unit, order_source_code, 
	        site_key_id, attribute1, attribute2
        INTO    x_validated_site_key_rec.site_brand, x_validated_site_key_rec.site_mode, x_validated_site_key_rec.country_code,
                x_validated_site_key_rec.language_code, x_validated_site_key_rec.operating_unit, x_validated_site_key_rec.order_source,
                x_validated_site_key_rec.site_key_id,  x_user_id, x_responsibility_id
        FROM    XX_GLB_SITEKEY_ALL
        WHERE SITE_BRAND = UPPER(NVL(p_site_key_rec.site_brand,'-'))
        AND   NVL(SITE_MODE,'-') = NVL(UPPER(p_site_key_rec.site_mode),'-')
        AND   COUNTRY_CODE = UPPER(NVL(p_site_key_rec.country_code,'-'))
        AND   LANGUAGE_CODE = UPPER(NVL(p_site_key_rec.language_code,'-'))
        AND   OPERATING_UNIT= NVL(p_site_key_rec.operating_Unit,-1)
        AND   ORDER_SOURCE_CODE = UPPER(NVL(p_site_key_rec.order_source,'-'));
        
         x_return_status:= FND_API.G_RET_STS_SUCCESS; 

  EXCEPTION 
  
      WHEN NO_DATA_FOUND THEN
         fnd_message.set_name('XXOM','XX_GLB_INVALID_SITE_KEY');
         x_return_msg:= FND_MESSAGE.GET;
         
                                        
    WHEN OTHERS THEN
         x_return_status:=FND_API.G_RET_STS_UNEXP_ERROR;
         x_return_msg:= SQLERRM;
         
        
  END Validate_SiteKey;

END XX_GLB_SITEKEY_PKG;
/

SHOW ERRORS PACKAGE XX_QP_PRICELIST_SELECTION_PKG; 

PROMPT 
PROMPT Exiting.... 
PROMPT 

SET FEEDBACK ON 
EXIT; 
