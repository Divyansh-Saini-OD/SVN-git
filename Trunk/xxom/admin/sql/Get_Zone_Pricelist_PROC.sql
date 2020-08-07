CREATE OR REPLACE
PROCEDURE GET_ZONE_PRICELIST 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Office Depot                                                 |
-- +===================================================================+
-- | Name  :  GET_ZONE_PRICELIST                                       |
-- | Description: This procedure will be part of package               |
-- |            XX_QP_PRICE_REQUEST_PKG which is under development.    |
-- |            The procedure returns zone price list-Name,Id,Type to  |
-- |            calling application.                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 17-JUL-2007  Sachin Thaker    Initial draft version       |
-- |                                                                   |  
-- +===================================================================+
                        ( p_org_id             IN NUMBER  
                         ,p_session_type       IN VARCHAR2
                         ,p_ship_to_rec        IN XX_QP_SHIP_REC_T 
                         ,x_price_list_name    OUT VARCHAR2
                         ,x_price_list_id      OUT NUMBER
                         ,x_list_type          OUT VARCHAR2
                         ,x_ret_code           OUT NOCOPY VARCHAR2
                         ,x_err_buf            OUT NOCOPY VARCHAR2 )
                         IS
--  Global/Local Parameters

  gc_exception_header    xx_om_global_exceptions.exception_header%TYPE   :=  'OTHERS';
  gc_track_code          xx_om_global_exceptions.track_code%TYPE         :=  'OTC';
  gc_solution_domain     xx_om_global_exceptions.solution_domain%TYPE    :=  'Zone Price List';
  gc_function            xx_om_global_exceptions.function_name%TYPE      :=  'I121022';
   
  EX_ZONE_PL_ERR          EXCEPTION;
  lr_rep_exp_type         xxom.xx_om_report_exception_t;
  lc_err_desc             xxom.xx_om_global_exceptions.description%TYPE DEFAULT 'OTHERS';
  lc_entity_ref           xxom.xx_om_global_exceptions.entity_ref%TYPE DEFAULT 'Zone';
  lc_entity_ref_id        xxom.xx_om_global_exceptions.entity_ref_id%TYPE;
  lc_err_code             xxom.xx_om_global_exceptions.error_code%TYPE DEFAULT '1001';
  lc_zone                 wsh_regions_tl.zone%TYPE; 
  ln_price_list_id        qp_list_headers_b.list_header_id%TYPE;
  lc_price_list_name      qp_list_headers_tl.name%TYPE;
  lc_zip_code             wsh_regions_tl.postal_code_from%TYPE;
  ln_zone_price_list_id   qp_list_headers.list_header_id%TYPE;
  ln_web_price_list_id    qp_list_headers.list_header_id%TYPE;
  lc_price_list_id        number;
  
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
        
        SELECT rt_par.zone
              ,r_par.attribute3 -- Zone Pricelist id
              ,r_par.attribute4  -- Web Override Pricelist id 
          INTO lc_zone, 
               ln_zone_price_list_id, 
               ln_web_price_list_id
          FROM wsh_regions_tl rt 
              ,wsh_regions r
              ,wsh_zone_regions z
              ,wsh_regions_tl rt_par 
              ,wsh_regions r_par    
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
                                          
      BEGIN
         SELECT rt_par.zone 
               ,r_par.attribute3 -- Zone Pricelist id
               ,r_par.attribute4  -- Web Override Pricelist id 
           INTO lc_zone
               ,ln_zone_price_list_id
               ,ln_web_price_list_id     
           FROM wsh_regions_tl rt 
               ,wsh_regions r
               ,wsh_zone_regions z
               ,wsh_regions_tl rt_par 
               ,wsh_regions r_par    
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
  
      BEGIN
         SELECT rt_par.zone 
               ,r_par.attribute3 
               ,r_par.attribute4   
           INTO lc_zone 
               ,ln_zone_price_list_id 
               ,ln_web_price_list_id     
           FROM wsh_regions_tl rt 
               ,wsh_regions r
               ,wsh_zone_regions z
               ,wsh_regions_tl rt_par 
               ,wsh_regions r_par    
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
  
      BEGIN
         SELECT rt_par.zone
               ,r_par.attribute3 
               ,r_par.attribute4  
           INTO lc_zone 
               ,ln_zone_price_list_id 
               ,ln_web_price_list_id   
           FROM wsh_regions_tl rt 
               ,wsh_regions r
               ,wsh_zone_regions z
               ,wsh_regions_tl rt_par 
               ,wsh_regions r_par    
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
   -- Select and validate PL 
   
       IF lc_zone IS NOT NULL THEN 
              
          IF p_session_type ='WWW' THEN 
              lc_price_list_id := ln_web_price_list_id;
          ELSE
              lc_price_list_id := ln_zone_price_list_id;
          END IF;
                               
          
          BEGIN
             SELECT qlt.list_header_id,
                    qlb.list_type_code,
                    qlt.name 
               INTO x_price_list_id
                   ,x_list_type
                   ,x_price_list_name
               FROM qp_list_headers_tl qlt,
                    qp_list_headers_b qlb
              WHERE 1=1
                AND qlt.list_header_id    = qlb.list_header_id
                AND qlt.list_header_id    = lc_price_list_id
                AND qlb.orig_org_id       = p_org_id
                AND qlb.ACTIVE_FLAG       = 'Y'
                AND nvl(qlb.end_date_active, sysdate+1) > sysdate 
                AND qlb.start_date_active < sysdate 
                    ;
                    
                x_ret_code      := 'S' ;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN 
                
                fnd_message.set_name ('ONT','OE_INVALID_NONAGR_PLIST');
                fnd_message.set_token ('PRICE_LIST1' ,'ID-'||lc_price_list_id);
                fnd_message.set_token ('PRICING_DATE',sysdate);
                
                lc_err_code      := '0003';
                lc_err_desc      := fnd_message.get;
                lc_entity_ref    := 'PRICE_LIST_ID';
                lc_entity_ref_id := lc_price_list_id;
                RAISE EX_ZONE_PL_ERR;
          
          END;
          
    ELSE  -- zone is Null
       x_ret_code      := 'E' ;
    END IF; -- zone is Null
    
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
      x_ret_code := 'E';
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
       x_ret_code := 'E';
       x_err_buf := lc_err_desc;
    
    END GET_ZONE_PRICELIST;
    
  /
  
  show errors