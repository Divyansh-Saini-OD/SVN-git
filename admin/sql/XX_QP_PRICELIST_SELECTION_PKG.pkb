create or replace
PACKAGE BODY XX_QP_PRICELIST_SELECTION_PKG AS


-- * Parameters marked with asterisk will need to disapear when oe_order_Lines is used because it will be in this object.


 --  Constant declaration

  L_EXCEPTION_HEADER    CONSTANT xx_om_global_exceptions.exception_header%TYPE   :=  'OTHERS';
  L_TRACK_CODE          CONSTANT xx_om_global_exceptions.track_code%TYPE         :=  'OTC';
  L_SOLUTION_DOMAIN     CONSTANT xx_om_global_exceptions.solution_domain%TYPE    :=  'Price List Selection';
  L_FUNCTION            CONSTANT xx_om_global_exceptions.function_name%TYPE      :=  'I2022';

 -- Global/Local Declarations
  lr_rep_exp_type        xxom.xx_om_report_exception_t;
  lc_err_code            xxom.xx_om_global_exceptions.error_code%TYPE;
  lc_err_desc            xxom.xx_om_global_exceptions.description%TYPE;
  lc_entity_ref          xxom.xx_om_global_exceptions.entity_ref%TYPE;
  lc_entity_ref_id       xxom.xx_om_global_exceptions.entity_ref_id%TYPE;





PROCEDURE report_error (  p_error_code    IN xxom.xx_om_global_exceptions.error_code%TYPE DEFAULT '1000' 
                        , p_error_message IN xxom.xx_om_global_exceptions.description%TYPE DEFAULT 'OTHERS'
                        , p_entity_ref    IN xxom.xx_om_global_exceptions.entity_ref%TYPE DEFAULT 'Price List Selection'
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
-- | Name  : Get_MAP_Price_list                                        |
-- | Description : This procedure returns the MAP price list           |
-- |               the rules framework being designed.                 |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+ 
  PROCEDURE Get_MAP_Pricelist (   p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE 
                                , p_plselection_rec    IN XX_QP_PLSELECTION_REC_TYPE
                                , x_price_list_rec     OUT NOCOPY XX_QP_PRICE_LIST_REC_TYPE
                                , x_return_code        OUT NOCOPY VARCHAR2
                                , x_return_msg         OUT NOCOPY VARCHAR2  ) AS
  BEGIN
    x_price_list_rec:= XX_QP_PRICE_LIST_REC_TYPE(NULL, NULL,NULL,NULL,NULL);
    x_price_list_rec.price_list_id := G_MAP_Price_list_BRF;
    x_price_list_rec.price_list_type := 'PRL';
    x_price_list_rec.OD_Price_list_type := XX_QP_LIST_SELECTION_UTIL_PKG.G_PRICE_LIST_TYPE_MAP;
    x_return_code:= FND_API.G_RET_STS_SUCCESS;
    x_return_msg:= FND_API.G_MISS_CHAR;
  END Get_MAP_Pricelist;

-- +===================================================================+
-- | Name  : Get_MSRP_Pricelist                                        |
-- | Description : This procedure returns the msrp price list          |
-- |               the rules framework being designed.                 |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+ 
  PROCEDURE Get_MSRP_Pricelist (  p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE 
                                , p_plselection_rec    IN XX_QP_PLSELECTION_REC_TYPE
                                , x_price_list_rec     OUT NOCOPY XX_QP_PRICE_LIST_REC_TYPE
                                , x_return_code        OUT NOCOPY VARCHAR2
                                , x_return_msg         OUT NOCOPY VARCHAR2  ) AS
  BEGIN
    x_price_list_rec:= XX_QP_PRICE_LIST_REC_TYPE(NULL, NULL,NULL,NULL,NULL);
    x_price_list_rec.price_list_id := G_MSRP_Price_list_BRF;
    x_price_list_rec.price_list_type := 'PRL';
    x_price_list_rec.OD_Price_list_type := XX_QP_LIST_SELECTION_UTIL_PKG.G_PRICE_LIST_TYPE_MSRP;
    x_return_code:= FND_API.G_RET_STS_SUCCESS;
    x_return_msg:= FND_API.G_MISS_CHAR;
  END Get_MSRP_Pricelist;  
  
-- +===================================================================+
-- | Name  : Get_MSRP_Pricelist                                        |
-- | Description : This procedure returns the msrp price list          |
-- |               the rules framework being designed.                 |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+ 
  PROCEDURE Get_Store_Pricelist ( p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE 
                                , p_plselection_rec    IN XX_QP_PLSELECTION_REC_TYPE
                                , x_price_list_rec     OUT NOCOPY XX_QP_PRICE_LIST_REC_TYPE
                                , x_return_code        OUT NOCOPY VARCHAR2
                                , x_return_msg         OUT NOCOPY VARCHAR2  ) AS
  BEGIN
    
    x_price_list_rec:= XX_QP_PRICE_LIST_REC_TYPE(NULL, NULL,NULL,NULL,NULL);
    x_price_list_rec.price_list_id := G_Store_Price_list_BRF;
    x_price_list_rec.price_list_type := 'PRL';
    x_price_list_rec.OD_Price_list_type := XX_QP_LIST_SELECTION_UTIL_PKG.G_PRICE_LIST_TYPE_STORE;
    x_return_code:= FND_API.G_RET_STS_SUCCESS;
    x_return_msg:= FND_API.G_MISS_CHAR;
    
  END Get_Store_Pricelist;    
  
-- +===================================================================+
-- | Name  : Pre_selection                                             |
-- | Description : This procedure validates the input parameters and   |
-- | retrieves the additional information that is needed for the price |
-- | list selection process (i.e. defines if MAP, MSRP, PLMS price list|
-- | selection process needs to be executed, as well as if the customer|
-- | receives specific pricing.                                        |
-- |                                                                   |
-- | Input parameters:                                                 |
-- | p_web_site_key_rec => Web site key object identifier              |
-- | p_Request_Mode     => It is used to evaluate wheather to display  |
-- |                       MAP and MSRP price.                         |
-- | p_header_rec       => order header.                               |
-- | Output Parameters:                                                |
-- | X_customer_specific_pricing => Code that identifies if the        |
-- |                      customer receive specific pricing as follow: |
-- |                      NSP=no specific price                        |
-- |                      WSP=Customer With Specific pricing           |
-- |                      BCP=Best contracted price                    |
-- |                      BOP =Best overall price                      |
-- |                      BCO=Best contracted and overall pricing      |
-- | X_MAP_allowed    =>  Return Y/N flag when MAP pricing is allowed  |
-- | X_MSRP_allowed   =>  Return Y/N flag when MSRP pricing is allowed |
-- | X_PLMS_allowed   =>  Return Y/N flag when PLMS pricing is allowed |
-- +===================================================================+ 
  PROCEDURE Pre_selection (  p_web_site_key_rec       IN XX_GLB_SITEKEY_REC_TYPE 
                           , p_Request_Mode           IN VARCHAR2 
                           , p_cust_account_id        IN NUMBER
                           , P_cust_specific_pricing  IN VARCHAR2
                           , x_MAP_allowed            OUT NOCOPY VARCHAR2 
                           , x_MSRP_allowed           OUT NOCOPY VARCHAR2
                           , x_PLMS_allowed           OUT NOCOPY VARCHAR2
                           , x_plselection_rec        OUT NOCOPY XX_QP_PLSELECTION_REC_TYPE
                           , x_return_code            OUT NOCOPY VARCHAR2
                           , x_return_msg             OUT NOCOPY VARCHAR2
                           ) IS
  
  
  lc_customer_pricing       VARCHAR2(1);
  lc_best_overall 	    VARCHAR2(1);
  lc_best_contracted_price  VARCHAR2(1);
  ln_cust_site_id            NUMBER;
  
  BEGIN
    oe_debug_pub.add('----------------------------------------------------');
    oe_debug_pub.add(' In Pre-Selection ');
    x_return_code := FND_API.G_RET_STS_ERROR; 
    x_return_msg  := FND_API.G_MISS_CHAR;
     
    -- initialize the output object
    x_plselection_rec:= XX_QP_PLSELECTION_REC_TYPE(p_cust_account_id,NULL,NULL,NULL,NULL,NULL,
                                                   NULL,NULL,NULL,NULL,NULL,NULL,
                                                   NULL,NULL,NULL,NULL,NULL,NULL,
                                                   NULL,NULL,NULL,NULL,NULL,NULL);
                                                   
    -- validates if the site and the mode allows MAP price
    x_MAP_allowed:= XX_QP_LIST_SELECTION_FLOW_PKG.IS_MAP_Flow_Allowed( 
                                            p_web_site_key_rec => p_web_site_key_rec
                                          , p_Request_Mode => p_Request_Mode
                                          , p_plselection_rec => x_plselection_rec);
    oe_debug_pub.add(' After validating if MAP Price is allowed in the site for mode='||p_Request_Mode||' result='||x_MAP_allowed);
    
    -- validates if the site and the mode allows MSRP price
    x_MSRP_allowed:= XX_QP_LIST_SELECTION_FLOW_PKG.IS_MSRP_Flow_Allowed( 
                                            p_web_site_key_rec => p_web_site_key_rec
                                          , p_Request_Mode => p_Request_Mode
                                          , p_plselection_rec => x_plselection_rec);
    oe_debug_pub.add(' After validating if MSRP Price is allowed in the site for mode='||p_Request_Mode||' result='||x_MSRP_allowed);
    
    
    IF p_cust_specific_pricing is NOT NULL THEN
        
        -- the flag has been previously calculated, hence it copies to the output record
        x_plselection_rec.specific_pricing_code:= p_cust_specific_pricing;
    
    ELSE
      
       -- first request for the customer, therefore checks if it needs to call PLMS validating the customer account
       x_PLMS_allowed:= XX_QP_LIST_SELECTION_FLOW_PKG.is_PLMS_Flow_Allowed(
                                            p_web_site_key_rec => p_web_site_key_rec
                                          , p_Request_Mode     => p_Request_Mode
                                          , p_plselection_rec  => x_plselection_rec
                                           );
      oe_debug_pub.add(' After validating if PLMS is allowed in site result='||x_PLMS_allowed);
    
      
                            
       IF (x_PLMS_allowed= XX_QP_LIST_SELECTION_FLOW_PKG.G_TRUE) THEN
       
          BEGIN
                SELECT 
                       acct.ACCOUNT_NUMBER,
                       SITE.CUST_ACCT_SITE_ID
                INTO  
                      x_plselection_rec.account_number,
                      x_plselection_rec.Cust_acct_site_id
                FROM HZ_CUST_ACCT_SITES_ALL site,
                     HZ_CUST_SITE_USES_ALL uses,
                     HZ_CUST_ACCOUNTS acct
                where site.cust_account_id = x_plselection_rec.cust_account_id
                and   uses.cust_acct_site_id = site.cust_acct_site_id
                and   uses.site_use_code = 'BILL_TO'
                and   uses.status='A'
                and   uses.primary_flag = 'Y'
                and   acct.CUST_ACCOUNT_ID = site.cust_account_id;
          
                XX_QP_CUSTOMER_PRICE_LIST_PKG.chk_customer_specific_price( 
                                            p_cust_account_id           => x_plselection_rec.cust_account_id
                                          , p_cust_acct_site_id         => x_plselection_rec.Cust_acct_site_id            
                                          , x_customer_eligible_flag    => lc_customer_pricing
                                          , x_best_contract_price_flag  => lc_best_contracted_price
                                          , x_best_overall_price_flag   => lc_best_overall
                                          , x_err_buff                  => x_return_msg 
                                          , x_err_code                  => x_return_code
                                          );
         
                IF (x_return_code <> FND_API.G_RET_STS_SUCCESS) THEN
                
                    -- There was an error getting information from PLMS, then record error and 
                    -- and raise exception.
                    fnd_message.set_name('QP','XX_QP_ERROR_CHCK_CUST_IN_PLMS');
                    FND_MESSAGE.SET_TOKEN('ACCOUNT_ID', x_plselection_rec.cust_account_id);
                    FND_MESSAGE.SET_TOKEN('SITE_ID', x_plselection_rec.Cust_acct_site_id );
                    x_return_msg:= fnd_message.get;
                    
                    report_error (  p_error_code    => '0001' 
                                  , p_error_message =>  x_return_msg
                                  , p_entity_ref    => 'account_id'
                                  , p_entity_ref_id =>  x_plselection_rec.cust_account_id);
                    
                    lc_customer_pricing := 'N';
                
                END IF;
                  
          EXCEPTION WHEN NO_DATA_FOUND THEN
               fnd_message.set_name('QP','XX_QP_CUST_ACCT_NOT_FOUND');
               FND_MESSAGE.SET_TOKEN('ACCOUNT_ID', x_plselection_rec.cust_account_id);
               
               x_return_msg:= fnd_message.get;
                    
               report_error (  p_error_code    => '0001' 
                             , p_error_message =>  x_return_msg
                             , p_entity_ref    => 'account_id'
                             , p_entity_ref_id =>  x_plselection_rec.cust_account_id);
               lc_customer_pricing := 'N';
                      
          END;
       
          
          
          IF (lc_customer_pricing = 'Y') THEN
              
              oe_debug_pub.add(' is Contract customer - generating customer flag');
              IF (lc_best_contracted_price = 'Y' AND lc_best_overall = 'Y') THEN
              
                  x_plselection_rec.specific_pricing_code:= XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_CONT_OVER_PR;
              
              ELSIF (lc_best_overall = 'Y') THEN
              
                  x_plselection_rec.specific_pricing_code:= XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_OVERALL_PR;
              
              ELSIF (lc_best_contracted_price= 'Y') THEN
              
                  x_plselection_rec.specific_pricing_code:= XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_CONTRACT_PR;
                  
              ELSE
              
                  x_plselection_rec.specific_pricing_code:= XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_SPEC_PRICE;
                  
              END IF;
          
          ELSE
              oe_debug_pub.add(' is Commercial customer - generating customer flag');
              x_plselection_rec.specific_pricing_code:= XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_NO_SPEC_PRICE;
          
          END IF;
       
       ELSE 
       
            oe_debug_pub.add(' PLMS NOT ALLOWED - generating customer flag for comercial customer');
            x_plselection_rec.specific_pricing_code:= XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_NO_SPEC_PRICE;
            
       END IF;
  
       
    END IF;
    
    x_return_code := FND_API.G_RET_STS_SUCCESS;
    
    EXCEPTION 
        
        WHEN FND_API.G_EXC_ERROR THEN
            NULL; -- will forward the respective error
        
  END Pre_selection;
  -- +===================================================================+
-- | Name  : Post_Selection                                            |
-- | Description : This procedure sets the price list id, price list   |
-- |               type and the currency in every order_line_tbl       |
-- |               based on the customer account settings and ship-to  |
-- |               location.                                           |
-- +===================================================================+ 
  PROCEDURE Post_Selection ( p_web_site_key_rec    IN XX_GLB_SITEKEY_REC_TYPE
                           , p_price_list_rec      IN XX_QP_PRICE_LIST_REC_TYPE
                           , x_plselection_rec     OUT NOCOPY XX_QP_PLSELECTION_REC_TYPE
                           ) AS
  BEGIN
      oe_debug_pub.add('in Post_Selection ');
      
      IF (p_price_list_rec.OD_Price_list_type = XX_QP_LIST_SELECTION_UTIL_PKG.G_PRICE_LIST_TYPE_MAP) THEN
      
          -- save the MAP price list 
          x_plselection_rec.MAP_PL_id := p_price_list_rec.Price_list_id;
      
      ELSIF (p_price_list_rec.OD_Price_list_type = XX_QP_LIST_SELECTION_UTIL_PKG.G_PRICE_LIST_TYPE_MSRP) THEN
      
          x_plselection_rec.MSRP_PL_id := p_price_list_rec.Price_list_id;
      
      ELSE
      
          x_plselection_rec.selling_PL_id := p_price_list_rec.Price_list_id;
          x_plselection_rec.selling_PL_type := p_price_list_rec.price_list_type;
          x_plselection_rec.Selling_PL_OD_Type := p_price_list_rec.OD_Price_list_type;
          x_plselection_rec.Final_campaign_code := p_price_list_rec.Pricing_with_Campaign;
      END IF;
  
  
  END Post_Selection;
  
  -- +=================================================================+
-- | Name  : Choose_Winning_Price_List                                 |
-- | Description : returns the price list that evaluates each the price|
-- |               price list passed in p_price_list_tbl by calling    |
-- |               Price Request API in LINE mode, and returns either  |
-- |               the first or the best price list (according to the  |
-- |               value in p_selection_code)                          |
-- |                                                                   |
-- | input parameters:                                                 |
-- |    p_web_site_key_rec :web site identifier                        |
-- |    p_request_Mode     :Browse (B), Add-to-cart (A), Checkout (C)  |
-- |                        Page Detail (P)                            |
-- |    p_plselection_rec  :Record that contains the information about | 
-- |                        the item that is being requested           |
-- |    p_price_list_tbl   :Table with the price list id that need to  |
-- |                        be evaluated                               |
-- |    p_selection_code   :Identifies if the process must select the  |
-- |                        First (G_FIRST_PRICE_LIST) or the best     |
-- |                        Best  (G_BEST_PRICE_LIST)                  |
-- |                                                                   |
-- | output parameters:                                                |
-- |    x_winning_PL_rec   :Corresponds the first or best              |
-- |    error handing                                                  |
-- +===================================================================+ 
  PROCEDURE Choose_Winning_Price_List (
                                   p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                                 , p_Request_Mode       IN VARCHAR2 
                                 , p_plselection_rec    IN XX_QP_PLSELECTION_REC_TYPE
                                 , p_price_list_tbl     IN XX_QP_PRICE_LIST_TBL_TYPE
                                 , p_selection_code     IN VARCHAR2
                                 , x_winning_PL_rec     OUT NOCOPY XX_QP_PRICE_LIST_REC_TYPE
                                 , x_return_code        OUT NOCOPY VARCHAR2
                                 , x_return_msg         OUT NOCOPY VARCHAR2
                                 )  IS
  
  lc_cust_specific_pl_flag     VARCHAR2(1):='N';
  lc_best_contract_price_flag  VARCHAR2(1):= NULL;
  lc_best_overall_price_flag   VARCHAR2(1):= NULL;
  lr_request_options           APPS.XX_QP_PREQ_OPTIONS;
  lt_coupons                   APPS.XX_ONT_ORDER_COUPON_TBL_TYPE;
  lt_lines                     XXOM_ORDER_LINES_TBL_TYPE;
  lr_header                    XXOM_PRICE_REQUEST_REC_TYPE;
  lc_pricing_return_status     VARCHAR2(250);
  lc_pricing_return_msg        VARCHAR2(250);
  
      Procedure copy_to_outputRecord (p_list_rec in XX_QP_PRICE_LIST_REC_TYPE,
                                      p_price in NUMBER) is
      Begin

           x_winning_PL_rec.price_list_id := p_list_rec.price_list_id;
           x_winning_PL_rec.price_list_type := p_list_rec.price_list_type;
           x_winning_PL_rec.OD_Price_list_type := p_list_rec.OD_Price_list_type;
           x_winning_PL_rec.Pricing_with_Campaign:= p_list_rec.Pricing_with_Campaign; 
           x_winning_PL_rec.Price:= p_price; -- selling price
      
      End;
  BEGIN

   -- Get the price list array that should be used to price every line
   
         IF  ( p_price_list_tbl IS NULL AND p_price_list_tbl.count = 0 ) THEN 
            x_return_code := 'E';
            fnd_message.set_name('ONT','XX_QP_NO_PRICE_LISTS_PROVIDED');
            x_return_msg:= FND_MESSAGE.GET;
            
            report_error (  p_error_code    => '0003' 
                          , p_error_message => x_return_msg
                          , p_entity_ref    => 'customer account id'
                          , p_entity_ref_id => p_plselection_rec.cust_account_id);
            
            RAISE FND_API.G_EXC_ERROR;
         END IF;
         
      lr_request_options := APPS.XX_QP_PREQ_OPTIONS('N','N','N');
      lt_coupons:=APPS.XX_ONT_ORDER_COUPON_TBL_TYPE();
      
      -- creating the line table
      lt_lines:= APPS.XXOM_ORDER_LINES_TBL_TYPE(XXOM_ORDER_LINE_REC_TYPE( 
                                                p_plselection_rec.inventory_item_id
                                              , p_plselection_rec.sku_id
                                              , NULL
                                              , NULL
                                              , p_plselection_rec.ordered_Quantity
                                              , NULL
                                              , NULL
                                              , NULL
                                              , p_plselection_rec.ordered_uom
                                              , NULL 
                                              , NULL
                                              , NULL 
                                              , NULL 
                                              , NULL 
                                              , p_plselection_rec.ordered_date
                                              , NULL
                                              , NULL
                                              , 1
                                              , NULL
                                              , NULL
                                              , NULL --   List_price                    
                                              , NULL --   Sale_price
                                              , NULL --   Extended_price
                                              , NULL
                                              , NULL --   price_list_id 
                                              , NULL 
                                              , NULL --   MAP_Price
                                              , NULL 
                                              , NULL
                                              , NULL -- TLD_price                     NUMBER          -- Price too low to display
                                              , NULL -- Was_price                     NUMBER
                                              , NULL 
                                              , NULL
                                              , NULL
                                              , NULL
                                              , NULL--  break_Price                  XXOM_NUMBER_ARR
                                              , NULL --  Default_freight_charge        NUMBER          -- the price wrapper will return the ground shipping in each line. Used when browsing for skus
                                              , NULL --   config_hdr_id                NUMBER
                                              , NULL --   config_rev_nbr               NUMBER
                                              , NULL --  sequence_nbr                 NUMBER
                                              , NULL --   component_code               VARCHAR2(1200)
                                              , NULL --  price_list_type varchar2(40)
                                              , 'USD'));
                                      
      -- creating header record
      lr_header:= XXOM_PRICE_REQUEST_REC_TYPE(NULL --p_Ecom_Site_Key           XXOM_ECOM_SITEKEY_REC_TYPE
                                             ,NULL -- p_Sector_Type             VARCHAR2(40)
                                             ,NULL -- p_Referrer_Code           VARCHAR2(40)
                                             ,p_plselection_rec.Postal_Code   
                                             ,p_plselection_rec.Cust_Account_id    
                                             ,'USD'
                                             ,p_plselection_rec.cust_acct_site_id
                                             ,p_plselection_rec.ordered_date
                                             ,p_plselection_rec.cust_account_id);
      
      FOR jj in p_price_list_tbl.FIRST .. p_price_list_tbl.LAST LOOP
              
              -- assign the header line
              lr_header.p_currency_code := 'USD';
              -- assign the first price list to the request line
              lt_lines(1).price_list_id := p_price_list_tbl(jj).price_list_id;
              lt_lines(1).price_list_type := p_price_list_tbl(jj).price_list_type;
              
              
              XX_QP_PRICE_REQUEST_PKG.GET_PRICE_REQUEST(
              P_PRICE_MODE      => 'LINE',
              P_ORDER_SOURCE    => p_web_site_key_rec.order_source,
              P_SITEKEY_ID      => p_web_site_key_rec,
              P_REQUEST_OPTIONS => lr_request_options,
              P_COUPONS_TBL     => lt_coupons,
              X_HEADER_REC      => lr_header,
              X_ORDER_LINES_TBL => lt_lines,
              X_RETURN_STATUS   => lc_pricing_return_status,
              X_RETURN_STATUS_TEXT => lc_pricing_return_msg
              );
              
              IF (lc_pricing_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                            
                 fnd_message.set_name('ONT','XX_QP_ERROR_EVAUATING_PRICELIST');
                 FND_MESSAGE.SET_TOKEN('PRICE_LIST',p_price_list_tbl(jj).price_list_id);
                 lc_pricing_return_msg:= FND_MESSAGE.GET;
            
                 -- Report the Exception
                  report_error (  p_error_code    => '0004' 
                , p_error_message => lc_pricing_return_msg
                , p_entity_ref    => 'Price List id'
                , p_entity_ref_id => p_price_list_tbl(jj).price_list_id);
         
               
              ELSE
              
                  IF (p_selection_code = G_FIRST_PRICE_LIST ) THEN
                  
                      IF (lt_lines(1).sale_price > 0 ) THEN
                        
                        copy_to_outputRecord(p_price_list_tbl(jj), lt_lines(1).sale_price);
                        EXIT;
                        
                      END IF;
                  
                  ELSIF ( p_selection_code = G_BEST_PRICE_LIST) THEN
                  
                      IF ( (x_winning_PL_rec.price_list_id IS NULL) OR 
                           (lt_lines(1).Sale_price < x_winning_PL_rec.price) ) THEN
                          
                          copy_to_outputRecord(p_price_list_tbl(jj), lt_lines(1).sale_price);
                      
                      END IF;
                     
                  END IF;
                  
              END IF;
              
         END LOOP;
            
                       
   EXCEPTION 
   WHEN FND_API.G_EXC_ERROR THEN
      x_return_code:= 'E';
   
   WHEN OTHERS THEN
     x_return_code := FND_API.G_RET_STS_UNEXP_ERROR;

  END Choose_Winning_Price_List;

-- +===================================================================+
-- | Name  : Selection_process                                         |
-- | Description : This procedure finds the price list for the given   |
-- | line.                                                             |
-- |                                                                   |
-- | Input parameters:                                                 |
-- | p_web_site_key_rec => Web site key object identifier              |
-- | p_Request_Mode     => This is the mode in which the user is       |
-- |                       executing the called.                       |
-- | p_header_rec       => order header record                         |
-- | p_header_attrs_rec => OD custom order header attributes           |
-- |                                                                   |
-- | Output Parameters:                                                |
-- | x_line_rec         => line attributes                             |
-- | x_line_attrs_rec   => OD custom line attributes                   |
-- | x_return_status    => 'S', 'E', 'U'                               |
-- | x_return_msg       => Error message                               |
-- +===================================================================+ 
PROCEDURE Selection_Process( p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE 
                           , p_Request_Mode       IN VARCHAR2
                           , x_plselection_rec    OUT NOCOPY XX_QP_PLSELECTION_REC_TYPE
                           , x_return_status      OUT NOCOPY VARCHAR2
                           , x_return_msg         OUT NOCOPY VARCHAR2  
                           ) IS

  lr_list                 XX_QP_PRICE_LIST_REC_TYPE;
  lt_lists                XX_QP_PRICE_LIST_TBL_TYPE;
  lt_line_process_flow    XX_QP_LIST_SELECTION_UTIL_PKG.XX_QP_FLOW_TBL_TYPE;
  lc_err_code             VARCHAR2(30);
  lc_err_buff             VARCHAR2(240);
  ln_Index                NUMBER:=0;
  
  PROCEDURE Add_list (  p_list IN XX_QP_PRICE_LIST_REC_TYPE) is
  BEGIN
      
          ln_Index := ln_Index + 1;
          lt_lists.extend;
          lt_lists(ln_Index):= p_list;
      
   END Add_list;
   
   PROCEDURE run_process ( p_proc_name IN VARCHAR2) IS
   BEGIN
          
          oe_debug_pub.add('CALL '||p_proc_name ||'(:p_site, :p_param, :x_list, :x_err_code, :x_err_msg)');
          
          EXECUTE IMMEDIATE 'CALL '||p_proc_name ||'(:p_site, :p_param, :x_list, :x_err_code, :x_err_msg)'
          USING p_web_site_key_rec, x_plselection_rec, OUT lr_list, OUT lc_err_code, OUT lc_err_buff;
          oe_debug_pub.add('returned code= '||lc_err_code);
          
   END run_process;
   
   
BEGIN
    oe_debug_pub.add('----------------------------------------------------');
    oe_debug_pub.add(' in Selection Process');
    oe_debug_pub.add(' Calling Control Flow....');
    
    lt_lists := XX_QP_PRICE_LIST_TBL_TYPE();
    
    
    -- Get the list of processes that need to be executed for the current line
    XX_QP_LIST_SELECTION_FLOW_PKG.Control_Flow ( 
                           p_web_site_key_rec    => p_web_site_key_rec
                         , p_Request_Mode        => p_Request_Mode
                         , p_plselection_rec     => x_plselection_rec
                         , x_process_flow        => lt_line_process_flow
                         , x_return_code         => lc_err_code
                         , x_return_msg          => lc_err_buff
                         );
                         
    oe_debug_pub.add(' Number of Processes to be run is '||lt_line_process_flow.count);
    
    
    FOR ii in lt_line_process_flow.first .. lt_line_process_flow.last LOOP
    
      
        dbms_output.put_line(' executing '||lt_line_process_flow(ii).process_name);
        oe_debug_pub.add(' Executing '||lt_line_process_flow(ii).process_name);
        
        run_process(lt_line_process_flow(ii).process_name);
        
        IF ( lc_err_code <> FND_API.G_RET_STS_SUCCESS OR lr_list.price_list_id IS NULL ) THEN
           
           -- report error
           lc_err_code :=lc_err_code; 
           lc_err_buff := lc_err_buff;
           oe_debug_pub.add(' Error returned:'||lc_err_buff);     
           oe_debug_pub.add(' Checking for the next price list.. ');   
        ELSE
        
            oe_debug_pub.add('Price List id='||lr_list.price_list_id);
            oe_debug_pub.add('Price List type='||lr_list.price_list_type);
            oe_debug_pub.add('OD List type='||lr_list.OD_Price_list_type);
            oe_debug_pub.add('Defaultl campaign='||lr_list.pricing_with_campaign);
            oe_debug_pub.add('Price='||lr_list.price);
            
            
            IF (x_plselection_rec.specific_pricing_code IN (XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_CONTRACT_PR,
                                                               XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_OVERALL_PR,
                                                               XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_CONT_OVER_PR) AND
                lt_line_process_flow(ii).part_of_best_price = 'Y' ) THEN
              
                    --save the price list into a table for further analysis for best pricing
                    Add_list(lr_list);
          
            ELSE
                   -- if the customer has NO best pricing, the price list found should be saved into the output record.   
                   -- call the post processing to copy the price list in the record
                   Post_Selection (  p_web_site_key_rec    => p_web_site_key_rec
                                   , p_price_list_rec      => lr_list
                                   , x_plselection_rec     => x_plselection_rec
                                   );
                   
                   -- if selling price is defined, it should terminate serarching 
                   -- since the MAP and MSRP should have been already calculated
                   IF (lt_line_process_flow(ii).defines_selling_price = 'Y') THEN
                      
                      EXIT;
                                                                        
                   END IF;                
                
            END IF; -- end validating customer specific pricing code                                              
        
        END IF; -- end validating error
    
    END LOOP;
    
   
    IF (lt_lists.COUNT > 0 AND
        x_plselection_rec.specific_pricing_code IN (XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_OVERALL_PR,
                                                    XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_CONT_OVER_PR) ) THEN
                                                       
        
              Choose_Winning_Price_List (
                             p_web_site_key_rec   => p_web_site_key_rec
                           , p_Request_Mode       => p_Request_Mode
                           , p_plselection_rec    => x_plselection_rec
                           , p_price_list_tbl     => lt_lists
                           , p_selection_code     => G_BEST_PRICE_LIST
                           , x_winning_PL_rec     => lr_list
                           , x_return_code        => x_return_status
                           , x_return_msg         => x_return_msg
                           );
              
              IF (lc_err_code = FND_API.G_RET_STS_SUCCESS ) THEN
              -- update the request line with the price list that offers the lowest price
               Post_Selection (  p_web_site_key_rec    => p_web_site_key_rec
                               , p_price_list_rec      => lr_list
                               , x_plselection_rec     => x_plselection_rec
                               );
              ELSE
                oe_debug_pub.add(' Error in best price resolution :'||lc_err_buff);     
                oe_debug_pub.add(' Checking for the next price list.. '); 
              END IF;
                                                   
    END IF;                                                          
    
    
END Selection_Process;



-- +===================================================================+
-- | Name  : Get_Price_List                                            |
-- | Description : This procedure sets the price list id, price list   |
-- |               type and the currency in every order_line_tbl       |
-- |               based on the customer account settings and ship-to  |
-- |               location.                                           |
-- | Note on 10-25-07                                                  |
-- | This prototype only implements customer specific pricing and zone |
-- | pricing. 
-- +===================================================================+ 
  PROCEDURE Get_Price_List ( p_web_site_key_rec    IN XX_GLB_SITEKEY_REC_TYPE
                           , p_Request_Mode        IN VARCHAR2 
                           , p_header_rec          IN XXOM_PRICE_REQUEST_REC_TYPE                   -- To be replaced with oe_order_header
                           , x_header_attrs_rec    IN OUT NOCOPY XX_OM_HEADER_ATTRS_REC_TYPE
                           , x_Lines_tbl           IN OUT NOCOPY XXOM_ORDER_LINES_TBL_TYPE            -- to be replaced with oe_order_lines
                           , x_lines_attrs_tbl     IN OUT NOCOPY XX_OM_LINE_ATTRS_TBL_TYPE
                           , x_msg_count           OUT NOCOPY NUMBER
                           , x_return_status       OUT NOCOPY VARCHAR2
                           , x_return_msg          OUT NOCOPY VARCHAR2
                               ) AS
  
  lr_shipping_rec              XX_QP_SHIP_REC_T;
  lc_price_list_name           VARCHAR2(100):= fnd_api.g_miss_char;
  ln_price_list_id             NUMBER:= fnd_api.g_miss_num;
  lc_price_list_type           VARCHAR(80):= fnd_api.g_miss_char;
  lc_list_type_name            VARCHAR2(30);
  lc_currency_code             QP_LIST_HEADERS.CURRENCY_CODE%TYPE;

  lc_Zone_Name                 VARCHAR2(80):= fnd_api.g_miss_char;
  lc_zip_code                  VARCHAR2(10);
  lc_err_code                  VARCHAR2(30);
  lc_err_buff                  VARCHAR2(240);
  lc_account_number            HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
  ln_account_site_id           HZ_CUST_ACCT_SITES.CUST_ACCT_SITE_ID%TYPE;
  lt_price_list_tbl            XX_QP_PRICE_LIST_TBL_TYPE;
  lr_plselection_rec           XX_QP_PLSELECTION_REC_TYPE;
  
  lc_MAP_allowed               VARCHAR2(1);
  lc_MSRP_allowed              VARCHAR2(1);
  lc_PLMS_allowed              VARCHAR2(1);
  lc_temp                      VARCHAR2(2000):=NULL;
  
  BEGIN
    
   DBMS_OUTPUT.PUT_LINE('Start time: '||to_char(sysdate,'hh:mi:sssss'));

-- TODO: This needs to be deleted when this API is integrated with the Get SKU INFO
    fnd_global.apps_initialize(user_id => 2025,    -- My USer Id
                               resp_id => 21623	,   -- OD US Order Management Super USer
                               resp_appl_id => 660 -- Order Management
    );

   FND_PROFILE.PUT('ONT_DEBUG_LEVEL',5);
   
    -- Initialize the messages context
    oe_msg_pub.initialize;

     dbms_output.put_line(To_number(Nvl(fnd_profile.value('ONT_DEBUG_LEVEL'), '0')));

     IF To_number(Nvl(fnd_profile.value('ONT_DEBUG_LEVEL'), '0')) > 0 THEN
        oe_debug_pub.initialize;
        lc_temp := oe_debug_pub.set_debug_mode('FILE');
        oe_debug_pub.debug_on;
        oe_debug_pub.setdebuglevel(5);
        dbms_output.put_line('Inside debug ON ' || lc_temp);
    END IF;
-- Delete Up to here

    x_return_status:= FND_API.G_RET_STS_ERROR;
    oe_debug_pub.add('----------------------------------------------------');
    oe_debug_pub.add(' Starting PRICELISET_SELECTION.Get_Price_List at '||to_char(sysdate,'hh:mi:sssss'));
    
    IF (x_Lines_tbl.COUNT <= 0) THEN
        fnd_message.set_name('ONT','OE_ATTRIBUTE_REQUIRED');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE',' Order Lines');
        x_return_msg:= FND_MESSAGE.GET;
        
        report_error (  p_error_code    => '0001' 
                      , p_error_message => fnd_message.get
                      , p_entity_ref    => 'p_cust_account_id'
                      , p_entity_ref_id => p_header_rec.P_Customer_Account_id);
        
        RAISE FND_API.G_EXC_ERROR;
    END IF;
    
    
    oe_debug_pub.add('-before pre-selection');
   
    Pre_selection (  p_web_site_key_rec   => p_web_site_key_rec
                   , p_Request_Mode       => p_Request_Mode
                   , p_cust_account_id    => p_header_rec.sold_to_org_id
                   , p_cust_specific_pricing => x_header_attrs_rec.cust_specific_pric_code
                   , x_MAP_allowed        => lc_MAP_allowed
                   , x_MSRP_allowed       => lc_MSRP_allowed
                   , x_PLMS_allowed       => lc_PLMS_allowed
                   , x_plselection_rec    => lr_plselection_rec
                   , x_return_code        => lc_err_code
                   , x_return_msg         => lc_err_buff
                   );
    oe_debug_pub.add('- customer specific pricing code='|| x_header_attrs_rec.cust_specific_pric_code);
   
    
    FOR ii in x_Lines_tbl.FIRST .. x_Lines_tbl.LAST LOOP
    
                
                -- 1. Validates that the price list is not already there
                IF ( (x_lines_tbl(ii).price_list_id IS NULL) OR 
                     (lc_MAP_allowed = XX_QP_LIST_SELECTION_FLOW_PKG.G_TRUE AND x_lines_attrs_tbl(ii).MAP_Price_list_id IS NULL) OR
                     (lc_MSRP_allowed= XX_QP_LIST_SELECTION_FLOW_PKG.G_TRUE AND x_lines_attrs_tbl(ii).MSRP_PRICE_LIST_ID is NULL)) THEN
                
                    lr_plselection_rec.country_code    := x_lines_attrs_tbl(ii).ship_to_country_code;
                    lr_plselection_rec.Postal_code     := x_lines_attrs_tbl(ii).ship_to_zip_code;
                    lr_plselection_rec.city            := x_lines_attrs_tbl(ii).ship_to_city;
                    lr_plselection_rec.state_code      := x_lines_attrs_tbl(ii).ship_to_state_code;
                    lr_plselection_rec.Inventory_Item_id := x_lines_tbl(ii).Inventory_Item_id;
                    lr_plselection_rec.SKU_ID            := x_lines_tbl(ii).sku_id;
                    lr_plselection_rec.ordered_uom       := x_lines_tbl(ii).Unit_of_measure;
                    lr_plselection_rec.ordered_quantity  := x_lines_tbl(ii).Quantity;
                    lr_plselection_rec.has_MAP           := x_lines_attrs_tbl(ii).call_4_MAP_flag;
                    lr_plselection_rec.has_MSRP          := x_lines_attrs_tbl(ii).call_4_MSRP_flag;
                    lr_plselection_rec.campaign_code     := x_lines_attrs_tbl(ii).usr_entered_campaign;
                    lr_plselection_rec.ordered_date      := p_header_rec.pricing_date;
                    lr_plselection_rec.OD_store_id       := x_lines_attrs_tbl(ii).OD_store_id;
                    lr_plselection_rec.MAP_PL_id         := x_lines_attrs_tbl(ii).MAP_price_list_id;
                    lr_plselection_rec.MSRP_PL_id        := x_lines_attrs_tbl(ii).MSRP_Price_list_id;
                    lr_plselection_rec.Selling_PL_ID     := x_lines_tbl(ii).price_list_id;
                    lr_plselection_rec.Selling_PL_Type   := NULL;
                    lr_plselection_rec.Selling_PL_OD_Type  := NULL;
                    lr_plselection_rec.Final_Campaign_Code := NULL;
                
                    selection_process( 
                             p_web_site_key_rec   => p_web_site_key_rec
                           , p_Request_Mode       => p_Request_Mode
                           , x_plselection_rec    => lr_plselection_rec
                          ,  x_return_status      => x_return_status
                           , x_return_msg         => x_return_msg
                           ) ;
                    
                    IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                            
                        -- Report the Exception
                        report_error (  p_error_code    => '0002' 
                      , p_error_message => x_return_msg
                      , p_entity_ref    => 'Inventory Item in Line '||x_Lines_tbl(ii).line_number
                      , p_entity_ref_id => x_Lines_tbl(ii).Inventory_item_id);
               
                    
                    END IF;
                    
                    -- Copy the selected (winning) price list back into the line record
                    x_lines_tbl(ii).price_list_id:= lr_plselection_rec.Selling_PL_id;
                    x_lines_attrs_tbl(ii).MAP_price_list_id:= lr_plselection_rec.MAP_PL_id;
                    x_lines_attrs_tbl(ii).MSRP_price_list_id:= lr_plselection_rec.MSRP_PL_id;
                    x_lines_attrs_tbl(ii).campaign_code := lr_plselection_rec.final_campaign_code;
                    
                END IF;
               
    END LOOP;
    
   x_return_status:= 'S';
    
   EXCEPTION
   
   WHEN FND_API.G_EXC_ERROR THEN
      x_return_status:= 'E';
     -- XXOM_MESSAGES.Retrieve_EBS_MEssages(x_ebs_msg_tbl,x_usr_msg_tbl,x_msg_count);
   
   WHEN OTHERS THEN
     oe_debug_pub.add('----------------------------------------------------');
   
     x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
     oe_debug_pub.add(SQLERRM);
   
    -- XXOM_MESSAGES.Retrieve_EBS_MEssages(x_ebs_msg_tbl,x_usr_msg_tbl,x_msg_count);
     
  END Get_Price_List;
  

  


END XX_QP_PRICELIST_SELECTION_PKG;