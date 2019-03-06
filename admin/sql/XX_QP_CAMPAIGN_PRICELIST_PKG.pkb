SET SHOW OFF; 
SET VERIFY OFF; 
SET ECHO OFF; 
SET TAB OFF; 
SET FEEDBACK OFF; 
WHENEVER SQLERROR CONTINUE; 
WHENEVER OSERROR EXIT FAILURE ROLLBACK; 


create or replace PACKAGE BODY XX_QP_CAMPAIGN_PRICELIST_PKG AS

 
 --  Constant declaration

  L_EXCEPTION_HEADER    CONSTANT xx_om_global_exceptions.exception_header%TYPE   :=  'OTHERS';
  L_TRACK_CODE          CONSTANT xx_om_global_exceptions.track_code%TYPE         :=  'OTC';
  L_SOLUTION_DOMAIN     CONSTANT xx_om_global_exceptions.solution_domain%TYPE    :=  'Campaign Price List';
  L_FUNCTION            CONSTANT xx_om_global_exceptions.function_name%TYPE      :=  'I1317';

 -- Global/Local Declarations
  lr_rep_exp_type        xxom.xx_om_report_exception_t;
  lc_err_code            xxom.xx_om_global_exceptions.error_code%TYPE;
  lc_err_desc            xxom.xx_om_global_exceptions.description%TYPE;
  lc_entity_ref          xxom.xx_om_global_exceptions.entity_ref%TYPE;
  lc_entity_ref_id       xxom.xx_om_global_exceptions.entity_ref_id%TYPE;
  


PROCEDURE report_error (  p_error_code    IN xxom.xx_om_global_exceptions.error_code%TYPE DEFAULT '0006' 
                        , p_error_message IN xxom.xx_om_global_exceptions.description%TYPE DEFAULT 'OTHERS'
                        , p_entity_ref    IN xxom.xx_om_global_exceptions.entity_ref%TYPE DEFAULT 'Campaign'
                        , p_entity_ref_id IN xxom.xx_om_global_exceptions.entity_ref_id%TYPE) IS

  lc_err_buf          VARCHAR2(250);
  lc_ret_code         VARCHAR2(30);
BEGIN

    lr_rep_exp_type := xx_om_report_exception_t ( L_EXCEPTION_HEADER
                                                 ,L_TRACK_CODE
                                                 ,L_SOLUTION_DOMAIN
                                                 ,L_FUNCTION
                                                 ,p_error_code
                                                 ,p_error_message
                                                 ,p_entity_ref
                                                 ,p_entity_ref_id
                                                 );
                                                     
   
    xx_om_global_exception_pkg.insert_exception (p_report_exception => lr_rep_exp_type
                                                ,x_err_buf => lc_err_buf
                                                ,x_ret_code =>lc_ret_code
                                                );


END report_error;                        


-- +===================================================================+
-- | Name  : validate_Operating_Unit                                   |
-- | Description : Validate that the operating unit is valid           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE validate_Operating_Unit ( p_Operating_Unit IN NUMBER
                                  , x_return_status  OUT NOCOPY VARCHAR2
                                  , x_return_msg     OUT NOCOPY VARCHAR2
                                   ) IS
nExists   NUMBER;
BEGIN
 
 x_return_status  :=FND_API.G_RET_STS_ERROR; 
 x_return_msg   :=FND_API.G_MISS_CHAR;
  
  oe_debug_pub.add(' Validating operating Unit');
  IF p_Operating_Unit IS NOT NULL THEN
  
      SELECT 1 INTO nExists
      FROM   hr_operating_units
      WHERE  organization_id = p_operating_unit;
  
      x_return_status  :=FND_API.G_RET_STS_SUCCESS; 
  
  END IF;
  
  EXCEPTION WHEN NO_DATA_FOUND THEN
    
    fnd_message.set_name('QP','QP_SECU_INVALID_OU_NAME');
    fnd_message.set_token('SITE_OU',   p_Operating_Unit);
    x_return_msg   := fnd_message.get;
    
    report_error(p_error_code     => '0001'
                , p_error_message => x_return_msg
                , p_entity_ref    => 'OU'
                , p_entity_ref_id => p_operating_unit
                );
    

END validate_Operating_Unit;

-- +===================================================================+
-- | Name  : validate_Campaign_code                                    |
-- | Description : Validate that the campaign code provided is not null|
-- |                                                                   |
-- +===================================================================+
PROCEDURE validate_Campaign_code ( p_Campaign_Code  IN VARCHAR2
                                 , x_return_status  OUT NOCOPY VARCHAR2
                                 , x_return_msg     OUT NOCOPY VARCHAR2
                                   ) IS
BEGIN
 
 x_return_status  :=FND_API.G_RET_STS_ERROR;
 x_return_msg     :=FND_API.G_MISS_CHAR;
  
    oe_debug_pub.add(' Validating Campaign Code');
    IF (p_Campaign_Code is null OR length( p_Campaign_Code) = 0 ) THEN
      
          -- Get the error message
          fnd_message.set_name('QP','XX_QP_INVALID_CAMPAIGN');
          x_return_msg    := fnd_message.get;
          -- save error message 
          report_error(p_error_code     => '0002'
                , p_error_message => x_return_msg
                , p_entity_ref    => 'Campaign'
                , p_entity_ref_id => p_Campaign_Code
                );
     ELSE 
        x_return_status  :=FND_API.G_RET_STS_SUCCESS;
     END IF;
  
END validate_Campaign_code;



-- +===================================================================+
-- | Name  : Get_Price_list                                            |
-- | Description : This procedure returns the price list with the most |
-- |              effective date for a given effort/campaign           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_Price_list (    p_operating_unit     IN  NUMBER
                            , p_campaign_code      IN  VARCHAR2
                            , p_pricing_zone       IN  VARCHAR2
                            , p_ordered_date       IN  DATE
                            , x_price_list_rec     IN OUT NOCOPY XX_QP_PRICE_LIST_REC_TYPE
                            , x_return_satus       OUT NOCOPY VARCHAR2
                           ) IS
                           
BEGIN
       
       --dbms_output.put_line(x_Price_list_rec.price_List_id);
              
              SELECT  LIST_HEADER_ID,  LIST_TYPE_CODE
              INTO    x_Price_list_rec.price_List_id, x_Price_list_rec.price_List_Type
              FROM    ( SELECT  *
                                --B.LIST_HEADER_ID, B.NAME,  B.END_DATE_ACTIVE , B.LIST_TYPE_CODE,ORIG_ORG_ID
                        FROM    QP_LIST_HEADERS B
                        WHERE   B.ORIG_ORG_ID = p_operating_unit
                        AND     B.ATTRIBUTE7 = 'Catalog'            --CAMPAIGN TYPE VALUE SET
                        AND     B.ATTRIBUTE9 = 'P'                  --CATALOG LABEL VALUE SET
                        AND     B.ATTRIBUTE10 = p_campaign_code
                        AND     B.ATTRIBUTE11 = p_pricing_zone
                        AND     B.ACTIVE_FLAG = 'Y'
                        AND     B.START_DATE_ACTIVE < p_ordered_date
                        AND     NVL(B.END_DATE_ACTIVE,SYSDATE+1) >= p_ordered_date
                        ORDER BY B.START_DATE_ACTIVE DESC
                      )
              WHERE ROWNUM = 1;                                         -- selects the most recent one
              
              x_return_satus:= 'S';
              
      EXCEPTION 
      
      WHEN NO_DATA_FOUND THEN
          
          dbms_output.put_line('no price list found');
          -- checks if an expired list EXITS 
          
          BEGIN
                SELECT  LIST_HEADER_ID,  LIST_TYPE_CODE
                INTO    x_Price_list_rec.price_List_id, x_Price_list_rec.price_List_Type
                FROM    ( SELECT  *
                          FROM    QP_LIST_HEADERS B
                          WHERE   B.ORIG_ORG_ID = p_operating_unit
                          AND     B.ATTRIBUTE7 = 'Catalog'            --CAMPAIGN TYPE VALUE SET
                          AND     B.ATTRIBUTE9 = 'P'                  --CATALOG LABEL VALUE SET
                          AND     B.ATTRIBUTE10 = p_campaign_code
                          AND     B.ATTRIBUTE11 = p_pricing_zone
                          AND     B.ACTIVE_FLAG = 'Y'
                          AND     B.START_DATE_ACTIVE < p_ordered_date
                          AND     NVL(B.END_DATE_ACTIVE,SYSDATE+1) < p_ordered_date
                          ORDER BY B.START_DATE_ACTIVE DESC
                        )
                WHERE ROWNUM = 1;
                
                    x_return_satus:= 'XX_QP_EXPIRED_CAMPAIGN';
                
                EXCEPTION WHEN NO_DATA_FOUND THEN
                   x_return_satus:='XX_QP_CAMPAIGN_LIST_NOT_FOUND';
                 
            END;
      
END Get_Price_list;
                                  

-- +===================================================================+
-- | Name  : Campaign_Pre_Selection                                   |
-- | Description : This procedure returns the price list with the most |
-- |              effective date for a given effort/campaign           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Campaign_Pre_Selection (  
                                    p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                                  , p_plselection_rec    IN XX_QP_PLSELECTION_REC_TYPE
                                  , x_pricing_zone       OUT NOCOPY VARCHAR2
                                  , x_allow_default_campaign OUT NOCOPY VARCHAR2
                                  , x_return_status      OUT NOCOPY VARCHAR2
                                  , x_return_msg         OUT NOCOPY VARCHAR2  ) IS
       
      
      ln_zone_PL      NUMBER;
      ln_web_zone_PL  NUMBER;
      lc_ret_code     VARCHAR2(30);
      lc_err_buf      VARCHAR2(250);
BEGIN
      oe_debug_pub.add('----------------------------------------------------');
      oe_debug_pub.add(' In Campaign_PreSelection');
      x_return_status  :=FND_API.G_RET_STS_ERROR; 
      x_return_msg   :=FND_API.G_MISS_CHAR;
      x_allow_default_campaign := 'N';
 
      -- TODO validate site key
      validate_Operating_unit( p_Operating_Unit => p_web_site_key_rec.operating_unit
                             , x_return_status  => x_return_status
                             , x_return_msg     => x_return_msg);
                             
      IF ( x_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      
          RAISE FND_API.G_EXC_ERROR;
      
      END IF;
      
      
      validate_Campaign_code ( p_Campaign_Code  => p_plselection_rec.Campaign_Code
                             , x_return_status  => x_return_status
                             , x_return_msg     => x_return_msg
                             );
     
      IF ( x_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      
          RAISE FND_API.G_EXC_ERROR;
      
      END IF;
      
      
      IF ( p_plselection_rec.cust_zone is NULL ) THEN
          oe_debug_pub.add(' customer pricing zone is null finding zone');
          -- find the customer pricing zone by calling new API
          
          XX_QP_ZONE_PRICELIST_PKG.GET_ZONE_WEB_PRICELIST  (
           p_web_site_key_rec   => p_web_site_key_rec
          ,p_plselection_rec    => p_plselection_rec
          ,x_zone               => x_pricing_zone
          ,x_zone_pricelist_id  => ln_zone_PL
          ,x_web_pricelist_id   => ln_web_zone_PL
          ,x_ret_code           => lc_ret_code
          ,x_err_buf            => lc_err_buf
          );
          
          IF ( lc_ret_code <> FND_API.G_RET_STS_SUCCESS ) THEN
             oe_debug_pub.add(' error finding zone='||lc_ret_code);
              x_return_msg := lc_err_buf;
              RAISE FND_API.G_EXC_ERROR;
              
          END IF;
      
      ELSE
          
          x_pricing_zone:= p_plselection_rec.cust_zone;
        
      END IF;        
      oe_debug_pub.add(' zone='||x_pricing_zone);
      -- TODO: Get “Allow_Default_CampaignCode_Usage” from BRF
      
      x_return_status := FND_API.G_RET_STS_SUCCESS;
          
      EXCEPTION 
      
        WHEN FND_API.G_EXC_ERROR THEN
            NULL; -- it will return errors previously set
END Campaign_Pre_Selection;

-- +===================================================================+
-- | Name  : Campaign_Post_Selection                                   |
-- | Description : The procedure will analize the results of the       |
-- | Get_Price_list procedure and will set the corresponding message   |
-- | to be returned.                                                    |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Campaign_Post_Selection ( p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE 
                                  , p_plselection_rec    IN  XX_QP_PLSELECTION_REC_TYPE
                                  , P_price_list_rec     IN  XX_QP_PRICE_LIST_REC_TYPE
                                  , P_status             IN  VARCHAR2
                                  , x_return_status      OUT NOCOPY VARCHAR2
                                  , X_return_msg         OUT NOCOPY VARCHAR2
                                  ) IS
BEGIN
       oe_debug_pub.add('----------------------------------------------------');
       oe_debug_pub.add(' In Campaign_Post_Selection  ');
       IF (P_status = 'S') THEN
                  
                  X_return_status:=FND_API.G_RET_STS_SUCCESS; 
                  X_return_msg   :=FND_API.G_MISS_CHAR;
       
       ELSIF (P_status = 'XX_QP_EXPIRED_CAMPAIGN') THEN
                  
                    fnd_message.set_name('QP','XX_QP_EXPIRED_CAMPAIGN');
                    fnd_message.set_token('CAMPAIGN',   P_plselection_rec.campaign_code);
                      
                    X_return_status:=FND_API.G_RET_STS_ERROR; 
                    x_return_msg   := fnd_message.get;
                     
                     report_error(p_error_code     => '0005'
                    , p_error_message => X_return_msg
                    , p_entity_ref    => 'CAMPAIGN'
                    , p_entity_ref_id => P_plselection_rec.campaign_code
                    );            
                  
       ELSE--IF (P_status = 'XX_QP_CAMPAIGN_LIST_NOT_FOUND') THEN
              
                  fnd_message.set_name('QP','XX_QP_CAMPAIGN_LIST_NOT_FOUND');
                  fnd_message.set_token('CAMPAIGN',  P_plselection_rec.campaign_code);
                  fnd_message.set_token('ZONE',   P_plselection_rec.cust_zone);
                  
                  X_return_status:=FND_API.G_RET_STS_ERROR; 
                  X_return_msg   :=fnd_message.get;
                  
                   report_error(p_error_code     => '0004'
                    , p_error_message => X_return_msg
                    , p_entity_ref    => 'CAMPAIGN'
                    , p_entity_ref_id => P_plselection_rec.campaign_code
                    );
              
       END IF;
              
END Campaign_Post_Selection;


  -- +===================================================================+
-- | Name  : Get_Campaign_Price_list                                    |
-- | Description : This procedure returns the price list with the most  |
-- |              effective date for a given effort/campaign            |
-- | Parameters:                                                        |
-- | x_plselection_rec => record that contains the parameters needed to |
-- |                      obtain the catalog price list which are:      |
-- |                      campaign_code, pricing_zone, and ou           |
-- |                                                                    |
-- | x_price_list_rec   => record to return the price list information  |
-- | Created by:   Bibiana Penski                                       |
-- | Last Updated: 19-Dec-07                                            |
-- +===================================================================+
  PROCEDURE Get_Campaign_PriceList (  
                                        p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                                      , p_plselection_rec    IN XX_QP_PLSELECTION_REC_TYPE
                                      , x_Price_list_rec     OUT NOCOPY XX_QP_PRICE_LIST_REC_TYPE
                                      , x_return_status      OUT NOCOPY VARCHAR2
                                      , x_return_msg         OUT NOCOPY VARCHAR2  ) AS
                                      
            lv_default_campaign   VARCHAR2(40);
            lv_return_status      VARCHAR2(40);
            lv_allow_default_campaign VARCHAR2(1);
            lc_pricing_zone       VARCHAR2(80);
  BEGIN
             oe_debug_pub.add('----------------------------------------------------');
             oe_debug_pub.add(' In Campaign_PriceList  ');
             -- Initializing the output variable
             x_Price_list_rec:= XX_QP_PRICE_LIST_REC_TYPE(NULL, NULL,NULL,NULL,NULL);
             
             -- Initializing the returning messages with error which will change throughout the interface. 
             X_return_status:=FND_API.G_RET_STS_ERROR; 
             X_return_msg   :=FND_API.G_MISS_CHAR;
             
             Campaign_Pre_Selection(p_web_site_key_rec   => p_web_site_key_rec
                                  , p_plselection_rec    => p_plselection_rec
                                  , x_pricing_zone       => lc_pricing_zone
                                  , x_allow_default_campaign => lv_allow_default_campaign
                                  , x_return_status      => X_return_status
                                  , x_return_msg         => X_return_msg);
                                  
              IF (X_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
              
                  RAISE FND_API.G_EXC_ERROR;
              
              END IF;
             
              
              -- finds the catalog list for the given campaign code
              Get_Price_list (    p_operating_unit     => p_web_site_key_rec.operating_unit
                                , p_campaign_code      => p_plselection_rec.campaign_code
                                , p_pricing_zone       => lc_pricing_zone
                                , p_ordered_date       => p_plselection_rec.ordered_date
                                , x_price_list_rec     => x_Price_list_rec
                                , x_return_satus       => lv_return_status
                               );
       
              -- analize results
              Campaign_Post_Selection (  
                                    p_web_site_key_rec   => p_web_site_key_rec
                                  , p_plselection_rec    => p_plselection_rec
                                  , P_price_list_rec     => x_Price_list_rec
                                  , P_status             => lv_return_status
                                  , x_return_status      => x_return_status
                                  , X_return_msg         => x_return_msg
                                  );
              
              IF (lv_return_status = 'XX_QP_EXPIRED_CAMPAIGN') THEN
                  
                  IF (lv_allow_default_campaign = 'Y' ) THEN
                  
                      -- find the default campaign code from BRF
                      
                      -- TODO
                      --lv_default_campaign := BRF.getValue();
                      
                      Get_Price_list (
                                  p_operating_unit     => p_web_site_key_rec.operating_unit
                                , p_campaign_code      => lv_default_campaign
                                , p_pricing_zone       => lc_pricing_zone
                                , p_ordered_date       => p_plselection_rec.ordered_date
                                , x_price_list_rec     => x_Price_list_rec
                                , x_return_satus       => lv_return_status
                               );
                               
                      -- analizes results
                      Campaign_Post_Selection (  
                                    p_web_site_key_rec   => p_web_site_key_rec
                                  , p_plselection_rec    => p_plselection_rec
                                  , P_price_list_rec     => x_Price_list_rec
                                  , P_status             => lv_return_status
                                  , x_return_status      => x_return_status
                                  , X_return_msg         => x_return_msg
                                  );
                              
                  END IF;
                  
              END IF;
              
              IF (lv_return_status = 'S') THEN
                  
                  x_Price_list_rec.OD_Price_list_type :=XX_QP_LIST_SELECTION_UTIL_PKG.G_PRICE_LIST_TYPE_CAMPAIGN;
                  --dbms_output.put_line('OD pirce list type'|| x_Price_list_rec.OD_Price_list_type);  
              
              END IF;
              
                
    EXCEPTION 
     
     WHEN FND_API.G_EXC_ERROR THEN
            
            NULL; -- error message have been set
      
      WHEN OTHERS THEN
            X_return_status:=FND_API.G_RET_STS_UNEXP_ERROR; 
            X_return_msg   :=SUBSTR(SQLERRM,1,200);
            
  END Get_Campaign_PriceList;
  


END XX_QP_CAMPAIGN_PRICELIST_PKG;
/ 

SHOW ERRORS PACKAGE XX_QP_PRICELIST_SELECTION_PKG; 
EXIT; 
