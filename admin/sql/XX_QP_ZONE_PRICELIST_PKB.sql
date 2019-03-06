CREATE OR REPLACE PACKAGE BODY XX_QP_ZONE_PRICELIST_PKG AS

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
-- | 1.0     15-NOV-2007  Sachin Thaker    As per Dynemic Design added |
-- |                                       Pre-validation process.     |
-- |                                       replaced org_id,session type|
-- |                                       parameters with Site Key    |
-- |                                                                   |
-- | 1.1     27-Nov-2007  Sachin Thaker    Added function to return    |
-- |                                       price zone/zone PL/web PL   |
-- |                                       will be used by Effort PL   |
-- |                                       selection API.              |
-- +===================================================================+


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

PROCEDURE Zone_Pre_Selection    (   p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                                  , p_ship_to_rec        IN XX_QP_SHIP_REC_T
                                  , x_ret_code           OUT NOCOPY VARCHAR2
                                  , x_err_buf            OUT NOCOPY VARCHAR2  ) IS
BEGIN
 --Check if Country code is NULL

  IF p_ship_to_rec.country_code IS NULL then

     lc_err_code      := '0001';
     fnd_message.set_name ('XXOM', 'XX_WSH_INVALID_ZONE'); -- update message here -SACHIN
     lc_err_desc      := fnd_message.get;
     lc_entity_ref    := 'COUNTRY_CODE-'||p_ship_to_rec.country_code;
     lc_entity_ref_id := -99999;
     RAISE EX_ZONE_PL_ERR;
  ELSE
     x_ret_code := FND_API.G_RET_STS_SUCCESS ;
  END IF;

 EXCEPTION
    WHEN EX_ZONE_PL_ERR THEN

     lr_rep_exp_type := xx_om_report_exception_t (gc_exception_header
                                                 ,gc_track_code
                                                 ,gc_solution_domain
                                                 ,gc_function
                                                 ,lc_err_code
                                                 ,lc_err_desc
                                                 ,lc_entity_ref
                                                 ,lc_entity_ref_id
                                                 );

      xx_om_global_exception_pkg.insert_exception (lr_rep_exp_type
                                                  ,x_err_buf
                                                  ,x_ret_code
                                                  );
      x_ret_code := FND_API.G_RET_STS_ERROR;
      x_err_buf := lc_err_desc;


END ZONE_PRE_SELECTION;

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
-- |                x_zone_pricelist_id                                 |
-- |                x_web_pricelist_id                                 |
-- |                x_ret_code                                         |
-- |                x_err_buf                                          |
-- +===================================================================+


PROCEDURE GET_ZONE_WEB_PRICELIST  (p_web_site_key_rec  IN  XX_GLB_SITEKEY_REC_TYPE
                                  ,p_ship_to_rec        IN XX_QP_SHIP_REC_T
                                  ,x_zone               OUT NOCOPY VARCHAR2
                                  ,x_zone_pricelist_id  OUT NOCOPY NUMBER
                                  ,x_web_pricelist_id   OUT NOCOPY NUMBER
                                  ,x_ret_code           OUT NOCOPY VARCHAR2
                                  ,x_err_buf            OUT NOCOPY VARCHAR2) AS

lc_zone                 wsh_regions_tl.zone%TYPE;
ln_price_list_id        qp_list_headers_b.list_header_id%TYPE;
lc_zip_code             wsh_regions_tl.postal_code_from%TYPE;
ln_zone_price_list_id   qp_list_headers.list_header_id%TYPE;
ln_web_price_list_id    qp_list_headers.list_header_id%TYPE;


BEGIN

 IF p_ship_to_rec.zip_code IS NOT NULL AND p_ship_to_rec.country_code IS NOT NULL THEN

     --NA operation may send zip code like '99999-1234' for US. Canada will not have '-' in the zipcode so it will not be affected.Need to truncate first 5 characters.
      lc_zip_code := p_ship_to_rec.zip_code;
      IF length (lc_zip_code) >5 then
         SELECT  substr (lc_zip_code, 1,instr(lc_zip_code,'-',1)-1)
           INTO  lc_zip_code
           FROM  dual;
      END IF;

     --Zip code loop
      BEGIN
        -- dbms_output.put_line ('In zip code');
         SELECT rt_par.zone
               ,r_par.attribute3 -- Zone Pricelist id
               ,r_par.attribute4  -- Web Override Pricelist id
           INTO lc_zone,
                ln_zone_price_list_id,
                ln_web_price_list_id
           FROM wsh_regions_tl RT
               ,wsh_regions R
               ,wsh_zone_regions Z
               ,wsh_regions_tl RT_PAR
               ,wsh_regions R_PAR
          WHERE rt.postal_code_from = p_ship_to_rec.zip_code
            AND r.country_code      = p_ship_to_rec.country_code
            AND r.region_id         = rt.region_id
            AND rt.region_id        = z.region_id
            AND rt_par.region_id    = z.parent_region_id
            AND r_par.attribute5    = 'Y'
            AND r_par.region_id     = rt_par.region_id
              ;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           lc_err_code          := '0001';
           fnd_message.set_name ('XXOM','XX_WSH_INVALID_ZONE');
           lc_err_desc          := fnd_message.get;
           lc_entity_ref        := 'ZIP_CODE';
           lc_entity_ref_id     := lc_zip_code;
           RAISE EX_ZONE_PL_ERR;

         WHEN TOO_MANY_ROWS THEN
           lc_err_code            := '0002';
           fnd_message.set_name ('XXOM', 'XX_WSH_MULTI_ZONE');
           lc_err_desc            := fnd_message.get;
           lc_entity_ref          := 'ZIP_CODE';
           lc_entity_ref_id       := lc_zip_code;
           RAISE EX_ZONE_PL_ERR;
      END;

   ELSIF p_ship_to_rec.city IS NOT NULL AND p_ship_to_rec.state_code IS NOT NULL
                                           AND p_ship_to_rec.country_code IS NOT NULL THEN

               -- Dbms_output.put_line ('In city/state/country');

       BEGIN
          SELECT rt_par.zone
                ,r_par.attribute3 -- Zone Pricelist id
                ,r_par.attribute4  -- Web Override Pricelist id
            INTO lc_zone
                ,ln_zone_price_list_id
                ,ln_web_price_list_id
            FROM wsh_regions_tl RT
                ,wsh_regions R
                ,wsh_zone_regions Z
                ,wsh_regions_tl RT_PAR
                ,wsh_regions R_PAR
           WHERE r.country_code    = p_ship_to_rec.country_code
             AND r.state_code      = p_ship_to_rec.state_code
             AND rt.city           = p_ship_to_rec.city
             AND r.region_id       = rt.region_id
             AND rt.region_id      = z.region_id
             AND rt_par.region_id  = z.parent_region_id
             AND r_par.attribute5  = 'Y'
             AND r_par.region_id   = rt_par.region_id
               ;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lc_err_code      := '0001';
            fnd_message.set_name ('XXOM', 'XX_WSH_INVALID_ZONE');
            lc_err_desc      := fnd_message.get;
            lc_entity_ref    := 'CITY-'||p_ship_to_rec.city;
            lc_entity_ref_id := -99999; --p_ship_to_rec.city;
            RAISE EX_ZONE_PL_ERR;

          WHEN TOO_MANY_ROWS THEN
            lc_err_code      := '0002';
            fnd_message.set_name ('XXOM', 'XX_WSH_MULTI_ZONE');
            lc_err_desc      := fnd_message.get;
            lc_entity_ref    := 'CITY-'||p_ship_to_rec.city;
            lc_entity_ref_id := -99999; --p_ship_to_rec.city;
            lc_zone          := NULL;
            RAISE EX_ZONE_PL_ERR;
       END;

   ELSIF p_ship_to_rec.state_code IS NOT NULL AND p_ship_to_rec.country_code IS NOT NULL THEN
        dbms_output.put_line ('In state/country');
       BEGIN
          SELECT rt_par.zone
                ,r_par.attribute3
                ,r_par.attribute4
            INTO lc_zone
                ,ln_zone_price_list_id
                ,ln_web_price_list_id
            FROM wsh_regions_tl RT
                ,wsh_regions R
                ,wsh_zone_regions Z
                ,wsh_regions_tl RT_PAR
                ,wsh_regions R_PAR
           WHERE r.country_code    = p_ship_to_rec.country_code
             AND r.state_code      = p_ship_to_rec.state_code
             AND r.region_id       = rt.region_id
             AND rt.region_id      = z.region_id
             AND rt_par.region_id  = z.parent_region_id
             AND r_par.attribute5  = 'Y'
             AND r_par.region_id   = rt_par.region_id
               ;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
             lc_err_code      := '0001';
             fnd_message.set_name ('XXOM', 'XX_WSH_INVALID_ZONE');
             lc_err_desc      := fnd_message.get;
             lc_entity_ref    := 'STATE_CODE-'||p_ship_to_rec.state_code;
             lc_entity_ref_id := -99999;
             RAISE EX_ZONE_PL_ERR;

           WHEN TOO_MANY_ROWS THEN
             lc_err_code      := '0002';
             fnd_message.set_name ('XXOM', 'XX_WSH_MULTI_ZONE');
             lc_err_desc      := fnd_message.get;
             lc_entity_ref    := 'STATE_CODE-'||p_ship_to_rec.state_code;
             lc_entity_ref_id := -99999;
             lc_zone          := NULL;
             RAISE EX_ZONE_PL_ERR;
       END;

   ELSIF p_ship_to_rec.country_code IS NOT NULL THEN
        dbms_output.put_line ('In Country');
       BEGIN
          SELECT rt_par.zone
                ,r_par.attribute3
                ,r_par.attribute4
            INTO lc_zone
                ,ln_zone_price_list_id
                ,ln_web_price_list_id
            FROM wsh_regions_tl RT
                ,wsh_regions R
                ,wsh_zone_regions Z
                ,wsh_regions_tl RT_PAR
                ,wsh_regions R_PAR
           WHERE r.country_code    = p_ship_to_rec.country_code
             AND r.state_code      = p_ship_to_rec.state_code
             AND r.region_id       = rt.region_id
             AND rt.region_id      = z.region_id
             AND rt_par.region_id  = z.parent_region_id
             AND r_par.attribute5  = 'Y'
             AND r_par.region_id   = rt_par.region_id
               ;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lc_err_code      := '0001';
            fnd_message.set_name ('XXOM', 'XX_WSH_INVALID_ZONE');
            lc_err_desc      := fnd_message.get;
            lc_entity_ref    := 'COUNTRY_CODE-'||p_ship_to_rec.country_code;
            lc_entity_ref_id := -99999;
            RAISE EX_ZONE_PL_ERR;

           WHEN TOO_MANY_ROWS THEN
             lc_err_code      := '0002';
             fnd_message.set_name ('XXOM', 'XX_WSH_MULTI_ZONE');
             lc_err_desc      := fnd_message.get;
             lc_entity_ref    := 'COUNTRY_CODE-'||p_ship_to_rec.country_code;
             lc_entity_ref_id := -99999;
             lc_zone          := NULL;
             RAISE EX_ZONE_PL_ERR;
       END;

     END IF;
      --Dbms_output.put_line ('Zone -'||lc_zone||'PL id'||ln_zone_price_list_id);
    --Assigning values to Out parameters
    IF lc_zone IS NOT NULL THEN
     x_zone               := lc_zone ;
     x_zone_pricelist_id  := ln_zone_price_list_id;
     x_web_pricelist_id   := ln_web_price_list_id ;
     x_ret_code           := FND_API.G_RET_STS_SUCCESS;

    ELSE
      x_ret_code          := FND_API.G_RET_STS_ERROR ;
    END IF;

EXCEPTION
   WHEN EX_ZONE_PL_ERR THEN
    lr_rep_exp_type := xx_om_report_exception_t (gc_exception_header
                                                ,gc_track_code
                                                ,gc_solution_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,lc_err_desc
                                                ,lc_entity_ref
                                                ,lc_entity_ref_id
                                                );

     xx_om_global_exception_pkg.insert_exception (lr_rep_exp_type
                                                 ,x_err_buf
                                                 ,x_ret_code
                                                 );
     x_ret_code := FND_API.G_RET_STS_ERROR ;
     x_err_buf := lc_err_desc;

    WHEN OTHERS THEN
       lr_rep_exp_type := xx_om_report_exception_t (gc_exception_header
                                                      ,gc_track_code
                                                      ,gc_solution_domain
                                                      ,gc_function
                                                      ,lc_err_code
                                                      ,lc_err_desc
                                                      ,lc_entity_ref
                                                      ,lc_entity_ref_id
                                                      );

        xx_om_global_exception_pkg.insert_exception (lr_rep_exp_type
                                                       ,x_err_buf
                                                       ,x_ret_code
                                                       );
        x_ret_code := FND_API.G_RET_STS_ERROR ;
        x_err_buf := lc_err_desc;


END  GET_ZONE_WEB_PRICELIST ;


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

PROCEDURE GET_ZONE_PRICELIST   (p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                               ,p_ship_to_rec        IN XX_QP_SHIP_REC_T
                               ,p_price_date         IN DATE default sysdate
                               ,x_price_list_name    OUT VARCHAR2
                               ,x_price_list_id      OUT NUMBER
                               ,x_list_type          OUT VARCHAR2
                               ,x_ret_code           OUT NOCOPY VARCHAR2
                               ,x_err_buf            OUT NOCOPY VARCHAR2)AS

lc_zone                 wsh_regions_tl.zone%TYPE;
ln_zone_priceist_id     qp_list_headers_b.list_header_id%TYPE;
ln_web_pricelist_id     qp_list_headers_b.list_header_id%TYPE;
lc_price_list_id        qp_list_headers_b.list_header_id%TYPE;
--lc_price_list_name      qp_list_headers_tl.name%TYPE;
lc_zip_code             wsh_regions_tl.postal_code_from%TYPE;
lc_ret_code             VARCHAR2(10);


 BEGIN

   GET_ZONE_WEB_PRICELIST (p_web_site_key_rec
                          ,p_ship_to_rec
                          ,lc_zone
                          ,ln_zone_priceist_id
                          ,ln_web_pricelist_id
                          ,x_ret_code
                          ,lc_err_desc )  ;

   IF x_ret_code =FND_API.G_RET_STS_SUCCESS then
      --   dbms_output.put_line ('in main process --ln_zone_priceist_id -'||ln_zone_priceist_id|| '---ln_web_pricelist_id  '||ln_web_pricelist_id  );

       IF p_web_site_key_rec.order_source ='WWW' THEN
          lc_price_list_id := ln_web_pricelist_id;
       ELSE
          lc_price_list_id := ln_zone_priceist_id ;
       END IF;
   --  dbms_output.put_line ('in main process --lc_price_list_id -'||lc_price_list_id);

        BEGIN
        dbms_output.put_line ('in main process --p_price_date -'||p_price_date);

           SELECT qlt.list_header_id,
                  qlb.list_type_code,
                  qlt.name
             INTO x_price_list_id
                 ,x_list_type
                 ,x_price_list_name
             FROM qp_list_headers_tl QLT,
                  qp_list_headers_b QLB
            WHERE 1=1
              AND qlt.list_header_id    = qlb.list_header_id
              AND qlt.list_header_id    = lc_price_list_id
              AND qlb.orig_org_id       = p_web_site_key_rec.operating_unit
              AND qlb.active_flag       = 'Y'
          --    AND nvl(qlb.end_date_active,(NVL(p_price_date,sysdate )+1))> NVL(p_price_date,sysdate )
             -- AND qlb.start_date_active < NVL(p_price_date,sysdate )
              AND nvl(qlb.end_date_active,sysdate+1)> p_price_date
              AND qlb.start_date_active <= p_price_date
                  ;


              x_ret_code      := FND_API.G_RET_STS_SUCCESS ;

             -- dbms_output.put_line ('in main process --x_price_list_id-'||x_price_list_id);


           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 dbms_output.put_line ('in main process --ndf');
                 fnd_message.set_name ('ONT','OE_INVALID_NONAGR_PLIST');
                 fnd_message.set_token ('PRICE_LIST1' ,'ID-'||lc_price_list_id);
                 fnd_message.set_token ('PRICING_DATE',sysdate);

                 lc_err_code      := '0003';
                 lc_err_desc      := fnd_message.get;
                 lc_entity_ref    := 'PRICE_LIST_ID';
                 lc_entity_ref_id := lc_price_list_id;
                 RAISE EX_ZONE_PL_ERR;



           END;
    Else
      Null;

      --return user message, once decided;- check -sachin
    END IF;

    EXCEPTION
     WHEN EX_ZONE_PL_ERR THEN
     --  dbms_output.put_line ('in main process --Exception');
      lr_rep_exp_type := xx_om_report_exception_t (gc_exception_header
                                                  ,gc_track_code
                                                  ,gc_solution_domain
                                                  ,gc_function
                                                  ,lc_err_code
                                                  ,lc_err_desc
                                                  ,lc_entity_ref
                                                  ,lc_entity_ref_id
                                                  );

       xx_om_global_exception_pkg.insert_exception (lr_rep_exp_type
                                                   ,x_err_buf
                                                   ,x_ret_code
                                                   );
       x_ret_code := FND_API.G_RET_STS_ERROR ;
       x_err_buf := lc_err_desc;

    WHEN OTHERS THEN

       lr_rep_exp_type := xx_om_report_exception_t (gc_exception_header
                                                   ,gc_track_code
                                                   ,gc_solution_domain
                                                   ,gc_function
                                                   ,lc_err_code
                                                   ,lc_err_desc
                                                   ,lc_entity_ref
                                                   ,lc_entity_ref_id
                                                   );

        xx_om_global_exception_pkg.insert_exception (lr_rep_exp_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );
        x_ret_code := FND_API.G_RET_STS_ERROR ;
        x_err_buf := lc_err_desc;

     END GET_ZONE_PRICELIST;

 end XX_QP_ZONE_PRICELIST_PKG;




