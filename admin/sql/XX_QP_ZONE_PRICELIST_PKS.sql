CREATE OR REPLACE PACKAGE XX_QP_ZONE_PRICELIST_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Office Depot                                                 |
-- +===================================================================+
-- | Name  :  XX_QP_ZONE_PRICELIST_PKG                                 |
-- | Description: This procedure will be part of package               |
-- |            XX_QP_PRICE_REQUEST which is under development.        |
-- |            The procedure returns zone price list-Name,Id,Type to  |
-- |            calling application.                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 17-JUL-2007  Sachin Thaker    Initial draft version       |
-- |Ver 1.0  15-NOV-2007  Sachin Thaker    As per Dynamic Design added |
-- |                                       Pre-validation process      |
-- |                                                                   |
-- |Ver 1.1  27-Nov-2007  Sachin Thaker    Added proceudre to return   |
-- |                                       price zone/zone PL/web PL   |
-- +===================================================================+


--  Global/Local Parameters

  GC_EXCEPTION_HEADER    xx_om_global_exceptions.exception_header%TYPE   :=  'OTHERS';
  GC_TRACK_CODE          xx_om_global_exceptions.track_code%TYPE         :=  'OTC';
  GC_SOLUTION_DOMAIN     xx_om_global_exceptions.solution_domain%TYPE    :=  'Zone Price List';
  GC_FUNCTION            xx_om_global_exceptions.function_name%TYPE      :=  'I121022';

  EX_ZONE_PL_ERR         EXCEPTION;
  lr_rep_exp_type        xxom.xx_om_report_exception_t;
  x_err_buf              VARCHAr2(100); --CHECK
  x_ret_code             VARCHAr2(100);  --CHECK
  lc_err_desc            xxom.xx_om_global_exceptions.description%TYPE DEFAULT 'OTHERS';
  lc_entity_ref          xxom.xx_om_global_exceptions.entity_ref%TYPE DEFAULT 'Zone';
  lc_entity_ref_id       xxom.xx_om_global_exceptions.entity_ref_id%TYPE;
  lc_err_code            xxom.xx_om_global_exceptions.error_code%TYPE DEFAULT '1001';


-- +===================================================================+
-- | Name         : ZONE_PRE_SELECTION                                 |
-- | Description  : This procedure will be used to validate required   |
-- |                parameters/information. The process will be called |
-- |                by Price list selection process                    |
-- | Parameters   : p_web_site_key_rec                                 |
-- |                p_ship_to_rec                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns      : x_list_type                                        |
-- |                x_err_buf                                          |
-- |                                                                   |
-- +===================================================================+

PROCEDURE ZONE_PRE_SELECTION  (  p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                               , p_ship_to_rec        IN XX_QP_SHIP_REC_T
                               , x_ret_code           OUT NOCOPY VARCHAR2
                               , x_err_buf            OUT NOCOPY VARCHAR2  ) ;

-- +===================================================================+
-- | Name         : GET_ZONE_PRICELIST                                 |
-- | Description  : This procedure will be used to retrieve Zone or Web|
-- |                Price List                                         |
-- |                                                                   |
-- | Parameters   : p_web_site_key_rec  -Site Key                      |
-- |                p_ship_to_rec                                      |
-- |                p_price_date                                       |
-- | Returns      : x_price_list_name  -- PL name                      |
-- |                x_price_list_id    -- PL ID                        |
-- |                x_list_type        -- PL type                      |
-- |                x_ret_code                                         |
-- |                x_err_buf                                          |
-- |                                                                   |
-- +===================================================================+


PROCEDURE GET_ZONE_PRICELIST  ( p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                               ,p_ship_to_rec        IN XX_QP_SHIP_REC_T
                               ,p_price_date         IN DATE default sysdate
                               ,x_price_list_name    OUT VARCHAR2
                               ,x_price_list_id      OUT NUMBER
                               ,x_list_type          OUT VARCHAR2
                               ,x_ret_code           OUT NOCOPY VARCHAR2
                               ,x_err_buf            OUT NOCOPY VARCHAR2  )  ;


-- +===================================================================+
-- | Name         : GET_ZONE_WEB_PRICELIST                             |
-- | Description  : This procedure will be used to retrieve Zone, Zone |
-- |                Price List and Web Pricelist.The procedure will be |
-- |                used internally as well as by other application.   |
-- |                                                                   |
-- | Parameters   : p_web_site_key_rec                                 |
-- |                p_ship_to_rec                                      |
-- |                                                                   |
-- | Returns      : x_zone                                             |
-- |                x_zone_priceist_id                                 |
-- |                x_web_pricelist_id                                 |
-- |                x_ret_code                                         |
-- |                x_err_buf                                          |
-- +===================================================================+


PROCEDURE GET_ZONE_WEB_PRICELIST  (p_web_site_key_rec   IN  XX_GLB_SITEKEY_REC_TYPE
                                  ,p_ship_to_rec        IN XX_QP_SHIP_REC_T
                                  ,x_zone               OUT NOCOPY VARCHAR2
                                  ,x_zone_pricelist_id  OUT NOCOPY NUMBER
                                  ,x_web_pricelist_id   OUT NOCOPY NUMBER
                                  ,x_ret_code           OUT NOCOPY VARCHAR2
                                  ,x_err_buf            OUT NOCOPY VARCHAR2 ) ;

END XX_QP_ZONE_PRICELIST_PKG;

