SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_SKU_EXPLOSION_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_OM_SKU_EXPLOSION_PKG.pks                                       |
-- | Description: This package will location the BOM for a service sku if it   |
-- |              exists. The process will return the child skus and vendor    |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======  ===========  =============    ====================================|
-- |1.0      12-Jul-2010  Matthew Craig    Initial draft version               |
-- |                                                                           |
-- +===========================================================================+

-- +===========================================================================+
-- | Name: sr_sku_explosion                                                    |
-- |                                                                           |
-- | Description: This procodure will be called when creating an SR to replace |
-- |              the parent sku with with child skus and locate the vendor    |
-- |              that supplies the service                                    |
-- |                                                                           |
-- | Parameters:  p_sr_order_tbl                                               |
-- |                                                                           |
-- | Returns :    p_sr_order_tbl                                               |
-- |              x_retcode                                                    |
-- |              x_errmsg                                                     |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE SR_SKU_Explosion (
     p_sr_order_tbl     IN OUT NOCOPY XX_CS_SR_ORDER_TBL
    ,x_retcode          OUT NOCOPY VARCHAR2
    ,x_errmsg           OUT NOCOPY VARCHAR2 );

-- +===========================================================================+
-- | Name: Build_Parent_Child_File                                             |
-- |                                                                           |
-- | Description: This prcodure will be called to create a file with the parent|
-- |              child combinations to be used by the consignment extract     |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |              p_org_id                                                     |
-- |                                                                           |
-- | Returns :                                                                 |
-- |              x_retcode                                                    |
-- |              x_errmsg                                                     |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE Build_Parent_Child_File (
     x_retcode          OUT NOCOPY VARCHAR2
    ,x_errbuff          OUT NOCOPY VARCHAR2 );
    
PROCEDURE log_message(pBUFF  IN  VARCHAR2) ;
    

END XX_OM_SKU_EXPLOSION_PKG;
/