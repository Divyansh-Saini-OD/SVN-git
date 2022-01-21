create or replace PACKAGE BODY XX_QP_PRICELIST_SELECTION_PKG AS

-- * Parameters marked with asterisk will need to disapear when oe_order_Lines is used because it will be in this object.

  PROCEDURE Get_sku_price (
                      p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                    , p_source_id           IN  VARCHAR2
                    , p_Sector_Type         IN  VARCHAR2
                    , p_Referrer_Code       IN  VARCHAR2
                    , p_Ship_To_Postal_Code IN VARCHAR2
                    , p_Customer_Account_id IN NUMBER
                    , p_price_list_id       IN NUMBER  -- * see not at the top
                    , p_currency_code       IN VARCHAR2 -- * see not at the top
                    , x_line_rec            IN OUT NOCOPY XXOM_ORDER_LINE_REC_TYPE
                    , x_return_status       OUT NOCOPY VARCHAR2
                    , x_return_status_text  OUT NOCOPY VARCHAR2
                    );

PROCEDURE Add_Price_List_Record (   p_Price_list_name IN VARCHAR2
                                  , p_Price_List_id   IN NUMBER
                                  , p_Price_List_type IN VARCHAR2
                                  , p_type_name       IN VARCHAR2
                                  , p_Precedence      IN NUMBER
                                  , x_price_list_tbl  IN OUT NOCOPY XX_QP_PRICE_LIST_TBL_TYPE) IS
  
  l_index NUMBER:= nvl(x_price_list_tbl.count,0);
  BEGIN
    l_index:= l_index+1;
    x_price_list_tbl.extend(1);
    x_price_list_tbl(l_index).price_list_name:= p_price_list_name;
    x_price_list_tbl(l_index).price_list_header_id:= p_price_list_id;
    x_price_list_tbl(l_index).Price_list_precedence:= p_Precedence;
    x_price_list_tbl(l_index).price_list_type:= p_price_list_type;
    x_price_list_tbl(l_index).Type_name := p_type_name;
  
  END ADD_PRICE_LIST_RECORD;
  
  
-- +===================================================================+
-- | Name  :GET_CUSTOMER_PRICE_LIST                                    |
-- | Description : This procedure returns the price list for given sku |
-- |               for a given customer                                |
-- |                                                                   |
-- | Parameters :       p_customer_number  => customer number          |
-- |                    p_sku_id           => segment1                 |
-- |                                                                   |
-- | Returns :                                                         |
-- |                    x_price_list_tbl   => returned price list id   |
-- |                                                                   |
-- +===================================================================+ 
  PROCEDURE Get_Customer_PL_Forall( p_cust_account_id   IN NUMBER  
                                     , p_cust_acct_site_id IN NUMBER DEFAULT NULL
                                     , p_account_number    IN HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE DEFAULT NULL
                                     , p_line_tbl          IN XXOM_ORDER_LINES_TBL_TYPE
                                     , x_price_list_id     OUT NOCOPY NUMBER
                                     , x_price_list_type   OUT NOCOPY VARCHAR2
                                     , x_err_buff          OUT NOCOPY VARCHAR2
                                     , x_err_code          OUT NOCOPY VARCHAR2 ) IS
                                     
  lt_sku_tbl                XX_PLM_COMPOSER.sku_records_tbl;
  lr_sku_price_list         XX_PLM_COMPOSER.sku_price_list_rec;
  lc_err_msg                XX_PLM_COMPOSER.param_error_msg%TYPE;
  lc_err_code               XX_PLM_COMPOSER.param_ret_code%TYPE;
  BEGIN
   
      oe_debug_pub.add('----------------------------------------------------');
      oe_debug_pub.add(' Calling PLMS for customer specific pricing for a list of skus of '||p_line_tbl.count );
  
      x_price_list_id:=FND_API.G_MISS_NUM;  
      x_price_list_type:= FND_API.G_MISS_CHAR;
      x_err_code   :=FND_API.G_RET_STS_ERROR;
      x_err_buff :=FND_API.G_MISS_CHAR;
      
      
      -- Initial validation of data
      
      
      
      IF ( (p_cust_account_id is not null AND p_cust_account_id > 0 ) AND     
           (p_line_tbl is not null AND p_line_tbl.count > 0) ) THEN
           
           -- Call PLMS to obtain the price lists for the given SKU
           XX_PLM_COMPOSER.GetSkuPriceLists(
                p_customer_id       =>  p_cust_account_id
              , p_customer_site_id  =>  p_cust_acct_site_id
              , p_eff_date          =>  sysdate 
              , x_sku_records       =>  lt_sku_tbl
              , x_error_msg         =>  lc_err_msg
              , x_ret_code          =>  lc_err_code);
              
              
           
           IF (lc_err_code <> XX_PLM_COMPOSER.e_successful ) THEN
              
              --exit login the error           
              x_err_buff:= lc_err_msg;
              x_err_code:= lc_err_code;
              RAISE FND_API.G_EXC_ERROR;
              
           END IF;
           
           IF ( lt_sku_tbl is not null AND lt_sku_tbl.COUNT > 0 ) THEN
           
              -- loop throught the list and select the first one that returns price
              
                  
                  -- CALL QP
                  oe_debug_pub.add(' Price list header id='|| lr_sku_price_list.price_list_header_id  ||
                                   ' Price list id='|| lr_sku_price_list.price_list_id         ||
                                   ' Precedence='||lr_sku_price_list.precedence ||
                                   ' Inheritance level='||lr_sku_price_list.inheritance_level ||
                                   ' Selection reason='||lr_sku_price_list.selection_reason );
              
              
           
           END IF;
           
           
      END IF;
            
            
            
      SELECT xcp.price_list_id , G_PRICE_LIST_TYPE_CUSTOMER
        INTO x_price_list_id, x_price_list_type
        FROM xx_qp_cust_price_list xcp
       WHERE xcp.cust_account_id = p_cust_account_id;
      
      x_err_code   :=FND_API.G_RET_STS_SUCCESS;
  EXCEPTION 
            
    WHEN FND_API.G_EXC_ERROR THEN
         oe_debug_pub.add(' Error @GET_CUSTOMER_PRICE_LIST: '||x_err_buff );
        
    WHEN OTHERS THEN
      x_err_code:= 'U';
      x_err_buff := 'GET_CUSTOMER_PRICE_LIST-'||substr(sqlerrm, 1,240);

END GET_CUSTOMER_PL_FORALL;
-- +===================================================================+
-- | Name  :Is_Zone_Price_Allowed                                      |
-- | Description : This function validates if zone pricing is allowed  |
-- |               for a given customer                                |
-- |                                                                   |
-- +===================================================================+                                      
FUNCTION Is_Zone_Price_Allowed(  p_Order_Header_Rec IN XXOM_PRICE_REQUEST_REC_TYPE
                               , p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE
                              ) RETURN BOOLEAN IS

    lc_zip_code VARCHAR2(80);
    lb_allowed  BOOLEAN:=FALSE;
BEGIN

    lc_zip_code := substr (p_Order_Header_rec.p_Ship_To_Postal_Code, 1,instr(p_Order_Header_rec.p_Ship_To_Postal_Code,'-',1)-1);
                        
    IF (lc_zip_code is NOT null)  THEN
     
      lb_allowed := TRUE;

    END IF;
    
    Return (lb_allowed);
    
END Is_Zone_Price_Allowed;
-- +===================================================================+
-- | Name  :Get_Customer_Price_List                                    |
-- | Description : This procedure returns the price list for given sku |
-- |               for a given customer                                |
-- |                                                                   |
-- +===================================================================+ 
  PROCEDURE Get_Customer_Price_List( 
                                   p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                                 , p_cust_account_id   IN NUMBER  
                                 , p_cust_acct_site_id IN NUMBER DEFAULT NULL
                                 , p_account_number    IN HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE DEFAULT NULL
                                 , p_shipto_postalCode IN VARCHAR2    -- * see not at the top
                                 , p_line_rec          IN XXOM_ORDER_LINE_REC_TYPE
                                 , x_price_list_id     OUT NOCOPY NUMBER
                                 , x_price_list_type   OUT NOCOPY VARCHAR2
                                 , x_price_list_name   OUT NOCOPY VARCHAR2
                                 , x_currency_code     OUT NOCOPY VARCHAR2
                                 , x_err_buff          OUT NOCOPY VARCHAR2
                                 , x_err_code          OUT NOCOPY VARCHAR2 ) IS
    
  lcu_sku_price_lists       XX_PLM_COMPOSER.sku_price_lists_rec_cur;
  lr_sku_price_list         XX_PLM_COMPOSER.sku_price_list_rec;
  lc_err_msg                XX_PLM_COMPOSER.param_error_msg%TYPE;
  lc_err_code               XX_PLM_COMPOSER.param_ret_code%TYPE;
  lc_currency_code          QP_LIST_HEADERS.CURRENCY_CODE%TYPE;
  lc_list_type              QP_LIST_HEADERS.LIST_TYPE_CODE%TYPE;
  lc_list_name              QP_LIST_HEADERS.NAME%TYPE;
  lr_line                   XXOM_ORDER_LINE_REC_TYPE;
  
  BEGIN
   
      oe_debug_pub.add('----------------------------------------------------');
      oe_debug_pub.add(' Calling PLMS for customer specific pricing for sku '||p_line_rec.sku_id );
  
      x_price_list_id:=FND_API.G_MISS_NUM;  
      x_price_list_type:= FND_API.G_MISS_CHAR;
      x_err_code   :=FND_API.G_RET_STS_ERROR;
      x_err_buff :=FND_API.G_MISS_CHAR;
      lr_line := p_line_rec;
      
      -- Initial validation of data  
      IF ( (p_cust_account_id is not null AND p_cust_account_id > 0 ) AND     
           (p_line_rec.sku_id is not null AND LENGTH(p_line_rec.sku_id) > 0) ) THEN
           
            oe_debug_pub.add(' Invalid data - Account='||p_cust_account_id||
                             ' - sku='||p_line_rec.sku_id);
            RAISE FND_API.G_EXC_ERROR;
      END IF;
           
      -- Call PLMS to obtain the price lists for the given SKU
      
      XX_PLM_COMPOSER.GetSkuPriceLists(
          p_customer_id       =>  p_cust_account_id
        , p_customer_site_id  =>  p_cust_acct_site_id
        , p_eff_date          =>  sysdate 
        , p_sku_id            =>  p_line_rec.sku_id
        , x_sku_price_lists   =>  lcu_sku_price_lists 
        , x_error_msg         =>  lc_err_msg
        , x_ret_code          =>  lc_err_code);
        
        
      -- Make a call to QP to find out if the price list contains a price for the given item.
      
      IF (lc_err_code <> XX_PLM_COMPOSER.e_successful ) THEN
        
        --exit login the error           
        x_err_buff:= lc_err_msg;
        x_err_code:= lc_err_code;
        RAISE FND_API.G_EXC_ERROR;
        
      END IF;
      
      IF ( lcu_sku_price_lists is not null AND lcu_sku_price_lists%ROWCOUNT > 0 ) THEN
      
        -- loop throught the list and select the first one that returns price
        -- the best contract pricing won't be implemented in this version of the code
        LOOP
            FETCH lcu_sku_price_lists INTO lr_sku_price_list ;
            EXIT WHEN lcu_sku_price_lists%NOTFOUND;
            
            -- CALL QP
            oe_debug_pub.add(' Price list header id='|| lr_sku_price_list.price_list_header_id  ||
                             ' Price list id='|| lr_sku_price_list.price_list_id         ||
                             ' Precedence='||lr_sku_price_list.precedence ||
                             ' Inheritance level='||lr_sku_price_list.inheritance_level ||
                             ' Selection reason='||lr_sku_price_list.selection_reason );
            
            BEGIN
              SELECT L.CURRENCY_CODE, L.LIST_TYPE_CODE, L.NAME into lc_currency_code, lc_list_type, lc_list_name
              FROM   QP_LIST_HEADERS L
              WHERE  LIST_HEADER_ID = lr_sku_price_list.price_list_id;
          
              Get_sku_price (
                  p_web_site_key_rec    => p_web_site_key_rec
                , p_source_id           => null
                , p_Sector_Type         => null
                , p_Referrer_Code       => null
                , p_Ship_To_Postal_Code => p_shipto_postalCode
                , p_Customer_Account_id => p_cust_account_id
                , p_price_list_id       => lr_sku_price_list.price_list_header_id
                , p_currency_code       => lc_currency_code
                , x_line_rec            => lr_line
                , x_return_status       => lc_err_code
                , x_return_status_text  => lc_err_msg
                );
                
                IF ( lc_err_code <> FND_API.G_RET_STS_SUCCESS ) THEN
                
                  oe_debug_pub.add(' Error ='||lc_err_msg);
                  
                END IF;
                
                IF (lr_line.list_price >= 0 OR lr_line.Sale_price >= 0) THEN
                  
                  
                  --TODO  implementation of  best contract overall here
                  
                  x_price_list_id   := lr_sku_price_list.price_list_header_id;
                  x_price_list_type := lc_list_type;
                  x_price_list_name := lc_list_name;
                  x_currency_code   := lc_currency_code;
                  EXIT;
                  
                END IF;
        
            EXCEPTION 
            
                WHEN NO_DATA_FOUND THEN
                   oe_debug_pub.add(' *** Error PLMS price list '||lr_sku_price_list.price_list_id ||' NOT FOUND');
                WHEN OTHERS THEN
                   oe_debug_pub.add(' *** Error finding the Price for '||lr_sku_price_list.price_list_id ||sqlerrm);
                   
            END; -- end of internal block;
            
        END LOOP; -- end looping through the list of PLMS price lists.
        
        CLOSE lcu_sku_price_lists;
      
      END IF; 
           
      IF x_price_list_id <> FND_API.G_MISS_NUM THEN
      
         x_err_code   :=FND_API.G_RET_STS_SUCCESS;
         
      END IF;
      
  EXCEPTION 
            
    WHEN FND_API.G_EXC_ERROR THEN
         oe_debug_pub.add(' Error @GET_CUSTOMER_PRICE_LIST: '||x_err_buff );
        
    WHEN OTHERS THEN
      x_err_code:= 'U';
      x_err_buff := 'GET_CUSTOMER_PRICE_LIST-'||substr(sqlerrm, 1,240);
    
  END Get_Customer_Price_List;
-- +===================================================================+
-- | Name  :Get_Customer_PLMS_Mockup                                    |
-- | Description : Temporary procedure to obtain customer specific     |
-- |                Price List from a mockup table                     |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+ 
  PROCEDURE Get_Customer_PLMS_Mockup( p_cust_account_id   IN NUMBER  
                                     , p_cust_acct_site_id IN NUMBER DEFAULT NULL
                                     , p_account_number    IN HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE DEFAULT NULL
                                     , x_price_list_id     OUT NOCOPY NUMBER
                                     , x_price_list_type   OUT NOCOPY VARCHAR2
                                     , x_err_buff          OUT NOCOPY VARCHAR2
                                     , x_err_code          OUT NOCOPY VARCHAR2 ) IS
    
   BEGIN
   
      oe_debug_pub.add('----------------------------------------------------');
      oe_debug_pub.add(' Calling MOCKUP process for Customer specific price list '||p_cust_account_id);
  
      x_price_list_id:=FND_API.G_MISS_NUM;  
      x_price_list_type:= FND_API.G_MISS_CHAR;
      x_err_code   :=FND_API.G_RET_STS_ERROR;
      x_err_buff :=FND_API.G_MISS_CHAR;
            
            
      SELECT xcp.price_list_id , G_PRICE_LIST_TYPE_CUSTOMER
        INTO x_price_list_id, x_price_list_type
        FROM xx_qp_cust_price_list xcp
       WHERE xcp.cust_account_id = p_cust_account_id;
      
      x_err_code   :=FND_API.G_RET_STS_SUCCESS;
      
  EXCEPTION 
            
    WHEN FND_API.G_EXC_ERROR THEN
         oe_debug_pub.add(' Error @GET_CUSTOMER_PRICE_LIST: '||x_err_buff );
        
    WHEN OTHERS THEN
      x_err_code:= 'U';
      x_err_buff := 'GET_CUSTOMER_PRICE_LIST-'||substr(sqlerrm, 1,240);
    
  END Get_Customer_PLMS_Mockup;
-- +===================================================================+
-- | Name  :Chk_Customer_Specific_Price                                |
-- | Description : This procedure returns checks if a particular       |
-- |               customer has specific price list associated         |
-- |                                                                   |
-- | Parameters :       p_customer_number  => customer number          |
-- |                                                                   |
-- | Returns :                                                         |
-- |                    x_customer_eligible_flag                       |
-- |                    x_best_contract_price_flag                     |
-- |                    x_best_overall_price_flag                      |
-- |                    x_order_PBS                                    |
-- |                                                                   |
-- +===================================================================+                                  
PROCEDURE Chk_Customer_Specific_Price
                                 ( p_cust_account_id            IN NUMBER 
                                  , p_cust_acct_site_id         IN NUMBER
                                  , p_account_number            IN HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE
                                  , x_customer_eligible_flag    OUT NOCOPY VARCHAR2
                                  , x_best_contract_price_flag  OUT NOCOPY VARCHAR2
                                  , x_best_overall_price_flag   OUT NOCOPY VARCHAR2
                                  , x_err_buff                  OUT NOCOPY VARCHAR2
                                  , x_err_code                  OUT NOCOPY VARCHAR2 ) IS
        
    lc_err_msg                    XX_PLM_COMPOSER.param_error_msg%TYPE;
    lc_err_code                   XX_PLM_COMPOSER.param_ret_code%TYPE;
    lc_account_number             HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
    
BEGIN
    
    x_err_code   :=FND_API.G_RET_STS_ERROR;
    x_err_buff :=FND_API.G_MISS_CHAR;
    
    x_customer_eligible_flag    :='N';
    x_best_contract_price_flag  :='N';
    x_best_overall_price_flag   :='N';
    
    oe_debug_pub.add('----------------------------------------------------');
    oe_debug_pub.add(' Calling PLMS to check for Customer Specific Pricing');
  
    IF ( p_cust_account_id is not null AND p_cust_account_id > 0) THEN
    
        
        -- Retrieve customer's Flags
          
            XX_PLM_COMPOSER.GetCustomerPriceFlags(
                  p_customer_id               => p_cust_account_id,
                  p_customer_site_id          => p_cust_acct_site_id,
                  p_eff_date                  => sysdate,
                  x_customer_eligible_flag    => x_customer_eligible_flag,
                  x_best_contract_price_flag  => x_best_contract_price_flag,
                  x_best_overall_price_flag   => x_best_overall_price_flag,
                  x_error_msg                 => lc_err_msg,
                  x_ret_code                  => lc_err_code);
                  
                  
            IF ( lc_err_code <> XX_PLM_COMPOSER.e_successful) THEN
               
               x_err_code := lc_err_code; 
               x_err_buff := lc_err_msg;
               oe_debug_pub.add('Error return from PLMS '||x_err_buff);
               
            ELSE
            
              x_err_code   :=FND_API.G_RET_STS_SUCCESS;
              
            END IF;
                      
    
    END IF; 
    
     
END Chk_Customer_Specific_Price;
  
-- +===================================================================+
-- | Name  : Get_Campaign_Price_list                                   |
-- | Description : This procedure returns the price list for a given   |
-- |               effort/campaign used by customer                    |
-- |                                                                   |
-- | Parameters :  P_Order_Source_Type  => G-MILL OR WWW               |
-- |               p_web_site_key_rec   => web site identifier         |
-- |               p_Price_zone_name    => commercial zone where the   |
-- |                  customer is shipping the order to                |
-- |               p_Campaign_Code      => Three-digit code that quali-|
-- |                                       fies the sku in catalog     |
-- | Returns :                                                         |
-- |               x_price_List_ID => price header id                  |
-- |                                                                   |
-- +===================================================================+                                  
  PROCEDURE Get_Campaign_Price_list (  p_Order_source_type  IN VARCHAR2 
                                    , p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                                    , p_Price_zone_Name    IN VARCHAR2
                                    , p_Campaign_Code      IN VARCHAR2
                                    , x_price_List_ID      OUT NOCOPY NUMBER
                                    , x_err_code           OUT NOCOPY VARCHAR2
                                    , x_err_buff           OUT NOCOPY VARCHAR2  ) AS
  BEGIN
   x_err_code   :=FND_API.G_RET_STS_SUCCESS;
   x_err_buff :=FND_API.G_MISS_CHAR;
     
    /* TODO implementation required */
  END Get_Campaign_Price_list;

-- +===================================================================+
-- | Name  : Get_Zone_PriceList                                        |
-- | Description : This procedure returns the price list for a the cus-|
-- |               tomer commercial zone.                              |
-- |                                                                   |
-- +===================================================================+                                  
  PROCEDURE Get_Zone_PriceList (  
                                p_session_type       IN VARCHAR2
                               ,p_ship_to_rec        IN XX_QP_SHIP_REC_T 
                               ,p_inventory_item_id  IN MTL_SYSTEM_ITEMS.INVENTORY_ITEM_ID%TYPE
                               ,x_price_list_name    OUT NOCOPY VARCHAR2
                               ,x_price_list_id      OUT NOCOPY NUMBER
                               ,x_price_list_type    OUT NOCOPY VARCHAR2
                               ,x_list_type          OUT NOCOPY VARCHAR2
                               ,x_Zone_Name          OUT NOCOPY VARCHAR2    
                               ,x_err_code           OUT NOCOPY VARCHAR2
                               ,x_err_buff           OUT NOCOPY VARCHAR2 ) AS
  
  l_zone_price_list_id    NUMBER:=0;
  l_wzone_price_list_id   NUMBER:=0;
  ln_price_exist          NUMBER:=-1;
 
  BEGIN
 
    oe_debug_pub.add('----------------------------------------------------');
    oe_debug_pub.add(' Starting Zone Price List Selection  ');
    
    x_err_code      :=FND_API.G_RET_STS_ERROR;
    x_err_buff      :=FND_API.G_MISS_CHAR;
    x_price_list_name:=FND_API.G_MISS_CHAR;
    x_price_list_id :=FND_API.G_MISS_NUM;
    x_list_type     :=FND_API.G_MISS_CHAR;
    x_Zone_Name     :=FND_API.G_MISS_CHAR;
     
        SELECT rt_par.zone , R.ATTRIBUTE3 , R.ATTRIBUTE4
          INTO x_Zone_name, l_zone_price_list_id, l_wzone_price_list_id
          FROM WSH_REGIONS_TL RT 
              ,WSH_ZONE_REGIONS Z
              ,WSH_REGIONS_TL RT_PAR 
              ,WSH_REGIONS R
         WHERE rt.POSTAL_CODE_FROM = p_ship_to_rec.zip_code
           AND RT_PAR.REGION_ID=Z.PARENT_REGION_ID
           AND Z.REGION_ID = Rt.REGION_ID 
           AND rt_par.zone like 'QP%'
           AND R.REGION_ID = RT_PAR.REGION_ID;
        
        oe_debug_pub.add(' customer zone ='||x_Zone_name );
        
        IF p_session_type ='WWW' THEN 
        
                  -- selecting web zone price by checking if the list contains the requested item, 
                  -- otherwise it takes the commercial zone
                  BEGIN
                        SELECT 1 into ln_price_exist
                        FROM   QP_LIST_LINES_V L
                        WHERE  L.LIST_HEADER_ID = l_wzone_price_list_id
                        AND    L.PRODUCT_ATTR_VALUE = p_inventory_item_id;
                        
                        x_price_list_id := l_wzone_price_list_id;
                        x_list_type:= G_PRICE_LIST_TYPE_WZONE;
                        oe_debug_pub.add(' web price list='||l_wzone_price_list_id );
                        
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        -- item not in the list, use zone price list instead
                        x_price_list_id := l_zone_price_list_id;
                        x_list_type:= G_PRICE_LIST_TYPE_CZONE;

                  END;
           
        ELSE
                -- commercial zone price
                 x_price_list_id := l_zone_price_list_id;
                 x_list_type:= G_PRICE_LIST_TYPE_CZONE;
                 oe_debug_pub.add(' zone price list='||l_zone_price_list_id );
        END IF;
       
        BEGIN
        
            -- validates that the list is still active
            SELECT NAME, LIST_TYPE_CODE INTO x_price_list_name, x_price_list_type
            FROM QP_LIST_HEADERS
            WHERE QP_LIST_HEADERS.list_header_id = x_price_list_id
            AND   NVL(QP_LIST_HEADERS.END_DATE_ACTIVE, SYSDATE+1) > SYSDATE
            AND   QP_LIST_HEADERS.START_DATE_ACTIVE < SYSDATE 
            AND   QP_LIST_HEADERS.ACTIVE_FLAG = 'Y';
            
            
            x_err_code      :=FND_API.G_RET_STS_SUCCESS;
        
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN
          
            x_err_buff := 'ZONE PRICE LIST '|| x_price_list_id ||' IS EXPIRED ';
            oe_debug_pub.add(' Error @GET_ZONE_PRICELIST '||x_err_buff );

        END;
        
    EXCEPTION 
        
        WHEN NO_DATA_FOUND THEN
        x_err_code := 'E';
        x_err_buff := 'G_INVALID_PRICE_LIST';
        
        WHEN OTHERS THEN
        x_err_code := 'U';
        x_err_buff :=  'GET_ZONE_PRICE_LIST -'||SUBSTR(sqlerrm,1,200);
        
  END Get_Zone_PriceList;

-- +===================================================================+
-- | Name  : Get_Defult_Price_list                                     |
-- | Description : This procedure returns the price list according to  |
-- |               the rules framework being designed.                 |

-- | Parameters :  p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE     |

-- | Returns :                                                         |
-- |               x_price_List_id      => default price list header id|
-- |               x_price_List_type    => price list type             |
-- |                                                                   |
-- +===================================================================+    
  PROCEDURE Get_Defult_Price_list (    p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE 
                                      , x_price_List_id      OUT NOCOPY NUMBER
                                      , x_Price_List_type    OUT NOCOPY VARCHAR2
                                      , x_currency_code      OUT NOCOPY VARCHAR2
                                      , x_list_type_name     OUT NOCOPY VARCHAR2
                                      , x_err_code           OUT NOCOPY VARCHAR2
                                      , x_err_buff           OUT NOCOPY VARCHAR2 ) AS
  
         
         
  BEGIN
  
      x_price_list_id   :=FND_API.G_MISS_NUM;  
      x_price_list_type := FND_API.G_MISS_CHAR;
      x_err_code   :=FND_API.G_RET_STS_SUCCESS;
      x_err_buff :=FND_API.G_MISS_CHAR;
     
      SELECT xesd.price_list_id,qlb.LIST_TYPE_CODE, qlb.CURRENCY_CODE, G_PRICE_LIST_TYPE_DEFAULT
        INTO x_price_list_id,x_price_list_type, x_currency_code, x_currency_code
        FROM xxom.xxom_ecom_sitekey_defaults xesd
            ,QP_LIST_HEADERS_B qlb
       WHERE xesd.locale     = p_web_site_key_rec.locale
         AND xesd.brand      = p_web_site_key_rec.brand
         AND xesd.site_mode  = p_web_site_key_rec.site_mode
         AND xesd.price_list_id =qlb.list_header_id
         AND qlb.ACTIVE_FLAG='Y'
         AND nvl(qlb.end_date_active, sysdate+1) > sysdate 
       --  AND qlb.start_date_active < sysdate  -- FOR TESTING NEEDS TO BE REMOVED.
         ;
         
      EXCEPTION 
      
      WHEN NO_DATA_FOUND THEN
        x_err_code:= 'E';
        x_err_buff := 'GET_DEFAULT_PRICE_LIST- QP_DEFAULT_LIST_NOT_FOUND';
      
      WHEN OTHERS THEN
        x_err_code:= 'U';
        x_err_buff := 'GET_DEFAULT_PRICE_LIST-'||substr(sqlerrm, 1,200);
      
  END Get_Defult_Price_list;
-- +===================================================================+
-- | Name  : Get_MAP_Price_list                                        |
-- | Description : This procedure returns the MAP price list           |
-- |               the rules framework being designed.                 |
-- |                                                                   |
-- | Parameters :  p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE     |
-- |               p_price_List_id      OUT NOCOPY NUMBER              |
-- | Returns :                                                         |
-- |               x_return_status      OUT NOCOPY VARCHAR2            |
-- |               x_return_status_text OUT NOCOPY VARCHAR2            |
-- |                                                                   |
-- +===================================================================+ 
  PROCEDURE Get_MAP_Price_list (  p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE 
                                , p_price_List_id      OUT NOCOPY NUMBER
                                , x_err_code           OUT NOCOPY VARCHAR2
                                , x_err_buff           OUT NOCOPY VARCHAR2  ) AS
  BEGIN
    /* TODO implementation required */
    NULL;     
  END Get_MAP_Price_list;
  
  
-- +===================================================================+
-- | Name  : Get_Items_Price_List                                      |
-- | Description : This procedure sets the price list id, price list   |
-- |               type and the currency in every order_line_tbl       |
-- |               based on the customer account settings and ship-to  |
-- |               location.                                           |
-- | Note on 10-25-07                                                  |
-- | This prototype only implements customer specific pricing and zone |
-- | pricing. 
-- +===================================================================+ 
  PROCEDURE Get_Items_Price_List (p_Order_source_type   IN VARCHAR2 
                               , p_Price_Mode          IN VARCHAR2
                               , p_Customer_Account_id IN NUMBER
                               , p_web_site_key_rec    IN XX_GLB_SITEKEY_REC_TYPE
                               , p_Order_header_rec    IN XXOM_PRICE_REQUEST_REC_TYPE          -- To be replaced with oe_order_header
                               , x_Order_Lines_tbl     OUT NOCOPY XXOM_ORDER_LINES_TBL_TYPE            -- oe_order_lines
                               , x_cust_specific_flag  OUT NOCOPY VARCHAR2
                               , x_best_contract_price_flag OUT NOCOPY VARCHAR2
                               , x_best_overall_price_flag  OUT NOCOPY VARCHAR2
                               , x_return_status      OUT NOCOPY VARCHAR2
                               , x_msg_count          OUT NOCOPY NUMBER
                               , x_ebs_msg_tbl        OUT NOCOPY XXOM_VARCHAR2_2000_TBL
                               , x_usr_msg_tbl        OUT NOCOPY XXOM_VARCHAR2_2000_TBL) AS
  
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
  
  BEGIN
    
    x_return_status:= 'E';
    lc_zip_code := substr (p_Order_Header_rec.p_Ship_To_Postal_Code, 1,instr(p_Order_Header_rec.p_Ship_To_Postal_Code,'-',1)-1);
                
    
    IF (x_Order_Lines_tbl.COUNT <= 0) THEN
        fnd_message.set_name('ONT','OE_ATTRIBUTE_REQUIRED');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE',' Order Lines');
        OE_MSG_PUB.Add;
        RAISE FND_API.G_EXC_ERROR;
    END IF;
    
    select uses.site_use_id, acct.ACCOUNT_NUMBER INTO ln_account_site_id, lc_account_number
    from  HZ_CUST_ACCT_SITES_ALL site,
          HZ_CUST_SITE_USES uses,
          HZ_CUST_ACCOUNTS acct
    where site.cust_account_id = p_Customer_Account_id
    and   uses.cust_acct_site_id = site.cust_acct_site_id
    and   uses.site_use_code = 'BILL_TO'
    and   uses.status='A'
    and   uses.primary_flag = 'Y'
    and   acct.cust_account_id = site.cust_account_id;

    
    
    -- check if the customer has specific price list associated
    IF (nvl(p_Customer_Account_id,0) != 0 AND x_cust_specific_flag IS NULL  ) THEN
      
       Chk_Customer_Specific_Price( p_cust_account_id            => p_Customer_Account_id
                                  , p_cust_acct_site_id         => ln_account_site_id
                                  , p_account_number            => lc_account_number
                                  , x_customer_eligible_flag    => x_cust_specific_flag
                                  , x_best_contract_price_flag  => x_best_contract_price_flag
                                  , x_best_overall_price_flag   => x_best_overall_price_flag
                                  , x_err_code                  => lc_err_code
                                  , x_err_buff                  => lc_err_buff 
                                  );
       
       
    END IF;
    
    FOR ii in x_Order_Lines_tbl.FIRST .. x_Order_Lines_tbl.LAST LOOP
    
                lc_price_list_name:= fnd_api.g_miss_char;
                ln_price_list_id  := fnd_api.g_miss_num;
                lc_price_list_type:= fnd_api.g_miss_char;
                lc_Zone_Name      := fnd_api.g_miss_char;
                        
                
                -- Initialize the price list table
                lt_price_list_tbl := XX_QP_PRICE_LIST_TBL_TYPE();
            
                
                IF (x_cust_specific_flag = 'Y') THEN
                        
                        -- Getting customer specific price list for current item
                        Get_Customer_Price_List( 
                                               p_web_site_key_rec  => p_web_site_key_rec
                                             , p_cust_account_id   => p_Customer_Account_id  
                                             , p_cust_acct_site_id => ln_account_site_id
                                             , p_account_number    => lc_account_number
                                             , p_shipto_postalCode => p_Order_header_rec.p_Ship_To_Postal_Code
                                             , p_line_rec          => x_Order_Lines_tbl(ii)
                                             , x_price_list_id     => ln_price_list_id
                                             , x_price_list_type   => lc_price_list_type
                                             , x_price_list_name   => lc_price_list_name
                                             , x_currency_code     => lc_currency_code
                                             , x_err_buff          => lc_err_buff
                                             , x_err_code          => lc_err_code);
                        
                        IF ( lc_err_code = FND_API.G_RET_STS_SUCCESS ) THEN
                              
                               IF ( x_best_overall_price_flag = 'Y' ) THEN
                               
                                   -- Adding customer specific price list into the array of price list
                                  
                                   ADD_PRICE_LIST_RECORD ( 
                                                        p_Price_list_name => lc_price_list_name
                                                      , p_Price_List_id   => ln_price_list_id
                                                      , p_Price_List_type => lc_price_list_type
                                                      , p_type_name       => G_PRICE_LIST_TYPE_CUSTOMER
                                                      , p_Precedence      => G_PRECEDENCE_CUSTOMER
                                                      , x_price_list_tbl  => lt_price_list_tbl);    
                                    
                                ELSE
                                
                                    -- it is a contract customer without best overall, 
                                    -- and hence he should receive this price

                                    x_Order_Lines_tbl(ii).price_list_id := ln_price_list_id;
                                    x_Order_Lines_tbl(ii).price_list_type := lc_price_list_type;
                                    x_Order_Lines_tbl(ii).currency_code := lc_currency_code;
                                    
                                END IF;
                                
                        ELSE
                        
                              oe_debug_pub.add(' Error getting customer List '||lc_err_buff );
                              -- Allowing the customer getting commercial pricing
                              x_cust_specific_flag := 'N';
                              
                        END IF;
                
                END IF; -- end of loading customer specific price lists.
                    
                 
                -- /// 
                -- commercial price list selection for customers without specific pricing or
                -- customers with best overall pricing contracts
                
                IF ( x_cust_specific_flag = 'N' OR x_best_overall_price_flag = 'Y') THEN
                   
                  BEGIN 
                        
                        IF ( IS_ZONE_PRICE_ALLOWED(p_Order_header_rec,p_web_site_key_rec) ) THEN
                        
                            oe_debug_pub.add('Zone Pricing Validation Error - Zip is not provided');
                            RAISE FND_API.G_EXC_ERROR;
                            
                        END IF;            
                            
                        -- For purposes of the test the ship to record will be populated
                        -- but it should be part of the order lines
                        lr_shipping_rec:= XX_QP_SHIP_REC_T(UPPER(substr(p_web_site_key_rec.locale,1,2)),lc_zip_code, null,null);
          
          
                        GET_ZONE_PRICELIST (
                                          p_session_type       => p_Order_source_type
                                         ,p_ship_to_rec        => lr_shipping_rec 
                                         ,p_inventory_item_id  => x_Order_Lines_tbl(ii).inventory_item_id
                                         ,x_price_list_name    => lc_price_list_name
                                         ,x_price_list_id      => ln_price_list_id
                                         ,x_price_list_type    => lc_price_list_type
                                         ,x_list_type          => lc_list_type_name
                                         ,x_Zone_Name          => lc_Zone_Name
                                         ,x_err_code           => lc_err_code
                                         ,x_err_buff           => lc_err_buff );
                    
                    
                        IF lc_err_code = FND_API.G_RET_STS_SUCCESS THEN
                          
                             IF ( x_best_overall_price_flag = 'Y' ) THEN
                                 -- this is because the contract customer might have best overall.
                                 -- Adding zone price list to an array for alter comparison
                                  ADD_PRICE_LIST_RECORD ( 
                                                      p_Price_list_name => lc_price_list_name
                                                    , p_Price_List_id   => ln_price_list_id
                                                    , p_Price_List_type => lc_price_list_type
                                                    , p_type_name       => lc_list_type_name
                                                    , p_Precedence      => G_PRECEDENCE_ZONE
                                                    , x_price_list_tbl  => lt_price_list_tbl);     
                             ELSE
                                  
                                  -- it is a commercial customers and hence save the zone price list within the
                                  -- order line.
                                  x_Order_Lines_tbl(ii).price_list_id := ln_price_list_id;
                                  x_Order_Lines_tbl(ii).price_list_type := lc_price_list_type;
                                  x_Order_Lines_tbl(ii).currency_code := lc_currency_code;
                                  
                             END IF;
                        
                        ELSE
                    
                          oe_debug_pub.add(' Error getting zone pricing '||lc_err_buff);
                    
                        END IF;
                      
                      
                  EXCEPTION 
                          
                    WHEN FND_API.G_EXC_ERROR THEN
                       oe_debug_pub.add(' Error Validation in Commercial Price list selection');
                  END; 
        
              
                END IF; -- end of commercial price list selection /contract with best overall 
              

    END LOOP;
    
   x_return_status:= 'S';
    
   EXCEPTION
   
   WHEN FND_API.G_EXC_ERROR THEN
      x_return_status:= 'E';
      XXOM_MESSAGES.Retrieve_EBS_MEssages(x_ebs_msg_tbl,x_usr_msg_tbl,x_msg_count);
   
   WHEN OTHERS THEN
     x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
     XXOM_MESSAGES.Retrieve_EBS_MEssages(x_ebs_msg_tbl,x_usr_msg_tbl,x_msg_count);
     
  END Get_Items_Price_List;
  
-- +===================================================================+
-- | Name  : Get_Best_Price_List                                       |
-- | Description : returns the price list that offers best (lowest)    |
-- |               price among the list provided. It calls QP to obtain|
-- |               the price list.                                     |
-- +===================================================================+ 
  PROCEDURE Get_Best_Price_List (
                                   p_Price_Mode         IN VARCHAR2
                                 , p_Order_source_type  IN VARCHAR2 
                                 , p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                                 , p_Order_header_rec   IN XXOM_PRICE_REQUEST_REC_TYPE          
                                 , p_Order_Line         IN XXOM_ORDER_LINE_REC_TYPE    
                                 , p_price_list_tbl     IN XX_QP_PRICE_LIST_TBL_TYPE
                                 , x_best_price_list    OUT NOCOPY XX_QP_PRICE_LIST_REC_TYPE          
                                 , x_err_code           OUT NOCOPY VARCHAR2
                                 , x_err_buff           OUT NOCOPY VARCHAR2
                                 )  IS
  
  lc_cust_specific_pl_flag     VARCHAR2(1):='N';
  lc_best_contract_price_flag  VARCHAR2(1):= NULL;
  lc_best_overall_price_flag   VARCHAR2(1):= NULL;
  
  BEGIN

   -- Get the price list array that should be used to price every line
   
         IF  ( p_price_list_tbl IS NULL AND p_price_list_tbl.count = 0 ) THEN 
            x_err_code := 'E';
            x_err_buff := 'No price list in Best Price Selection';
            RAISE FND_API.G_EXC_ERROR;
         END IF;
         
         FOR jj in p_price_list_tbl.FIRST .. p_price_list_tbl.LAST LOOP
              
                null;
                
         END LOOP;
            
       
            
          
                       
   EXCEPTION 
   WHEN FND_API.G_EXC_ERROR THEN
      x_err_code:= 'E';
   
   WHEN OTHERS THEN
     x_err_code := FND_API.G_RET_STS_UNEXP_ERROR;

  END Get_Best_Price_List;
  
-- +===================================================================+
-- | Name  : Get_price_list                                            |
-- | Description : This procedure returns the price list for a given   |
-- |               line item                                           |

-- | Parameters :       p_customer_number -> customer number           |
-- |                    p_web_site_key_rec -> web site brand,mode and  |
-- |                    locale.                                        |
-- |                    p_zip_code         => customer's ship to zip   |
-- |                    p_req_effort_code  => campaign_code            |
-- |                    p_sku_id           => sku id                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                    x_price_list_id    => returned price list id   |
-- |                    x_list_type        => returned list type       |
-- |                    x_effort_code_used => campaign used for pricing|
-- |                    x_cust_price_zone  => zone pricing             |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+                                  
PROCEDURE Get_price_list ( p_cust_number        IN NUMBER  
                         ,p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                         ,p_session            IN VARCHAR2
                         ,p_zip_code           IN VARCHAR2 
                         ,p_req_effort_code    IN VARCHAR2
                         ,p_sku_id             IN NUMBER 
                         ,x_price_list_id      OUT NOCOPY NUMBER
                         ,x_list_type          OUT NOCOPY VARCHAR2
                         ,x_effort_code_used   OUT NOCOPY VARCHAR2
                         ,x_cust_price_zone    OUT NOCOPY VARCHAR2
                         ,x_return_status      OUT NOCOPY VARCHAR2
                         ,x_return_status_text OUT NOCOPY VARCHAR2 )
                                  IS
        --parameters
       
        l_session           VARCHAR2(30); --:= 'WWW';
        l_req_effort_code   VARCHAR2 (30) ; --:= NUll;
        l_zone              WSH_REGIONS_TL.zone%Type; 
        l_price_list        NUMBER;
        l_price_list_name   VARCHAR2(300);
        l_zip_code          VARCHAR2(30);
        l_zone_price_list   QP_LIST_HEADERS.LIST_HEADER_ID%TYPE;
        l_web_price_list    QP_LIST_HEADERS.LIST_HEADER_ID%TYPE;
        ln_org_id           NUMBER;
        ln_base_price       NUMBER;
        
        CURSOR cur_price_list_zip_code (p_zip_code in VARCHAR2) IS 
        SELECT rt_par.zone , R.ATTRIBUTE3 , R.ATTRIBUTE4
          FROM WSH_REGIONS_TL RT 
              ,WSH_ZONE_REGIONS Z
              ,WSH_REGIONS_TL RT_PAR 
              ,WSH_REGIONS R
         WHERE rt.POSTAL_CODE_FROM = p_zip_code
           AND RT_PAR.REGION_ID=Z.PARENT_REGION_ID
           AND Z.REGION_ID = Rt.REGION_ID 
           AND rt_par.zone like 'QP%'
           AND R.REGION_ID = RT_PAR.REGION_ID;
           
        
        CURSOR cur_price_list (p_price_list_id In NUMBER) is
        SELECT qlt.LIST_HEADER_ID,qlb.LIST_TYPE_CODE
          FROM QP_LIST_HEADERS_TL qlt,
               QP_LIST_HEADERS_B qlb
         WHERE 1=1
           AND qlt.list_header_id=qlb.list_header_id
           AND qlt.list_header_id= p_price_list_id
           AND qlb.ACTIVE_FLAG='Y'
           AND nvl(qlb.end_date_active, sysdate+1) > sysdate 
           AND qlb.start_date_active < sysdate;
           --Operating unit is not required as GLOBAL_FLAG overrides the OU. 
           --No functionality is required to check SKU ID 
          CURSOR cur_default_price_list (p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE) IS
          SELECT xesd.price_list_id,qlb.LIST_TYPE_CODE
            FROM xxom.xxom_ecom_sitekey_defaults xesd
                ,QP_LIST_HEADERS_B qlb
           WHERE xesd.locale     = p_web_site_key_rec.locale
             AND xesd.brand      = p_web_site_key_rec.brand-- OD, VIKING, TECH DEPOT
             AND xesd.site_mode  = p_web_site_key_rec.site_mode
             AND xesd.price_list_id =qlb.list_header_id
             AND qlb.ACTIVE_FLAG='Y'
             AND nvl(qlb.end_date_active, sysdate+1) > sysdate 
           --  AND qlb.start_date_active < sysdate  -- FOR TESTING NEEDS TO BE REMOVED.
             ;
           
   BEGIN
   
   oe_debug_pub.add('------------------------------');
   oe_debug_pub.add(' In xx_qp_pricelist_selection_pkg.get_price_list');
   
   fnd_profile.get('ORG_ID', ln_org_id);
   
   
       IF nvl(p_cust_number,0) != 0  then
                                     
                                  
          XX_QP_PRICELIST_SELECTION_PKG.Get_Customer_PLMS_Mockup( 
                                    p_cust_account_id     => p_cust_number
                                  , p_cust_acct_site_id   => null
                                  , p_account_number      => null
                                  , x_price_list_id       => x_price_list_id
                                  , x_price_list_type     => x_list_type
                                  , x_err_buff            => x_return_status
                                  , x_err_code            => x_return_status_text);
       
       END IF;
     
       --Get five Digit zip code to get zone/price list 
      
      IF x_price_list_id is null THEN
   
          IF p_zip_code IS NOT NULL THEN 
              
              oe_debug_pub.add('------------------------------');
              oe_debug_pub.add(' In Get zone Price List for zip code'||p_zip_code);
   
        l_zip_code :=p_zip_code;
        IF length (l_zip_code) >5 then 
           SELECT  substr (l_zip_code, 1,instr(l_zip_code,'-',1)-1)
             INTO  l_zip_code
             FROM  dual;
        END IF;
           
           OPEN cur_price_list_zip_code (l_zip_code);
           FETCH cur_price_list_zip_code INTO l_zone, l_zone_price_list, l_web_price_list;
           CLOSE cur_price_list_zip_code;
            x_cust_price_zone := l_zone; 
            
            oe_debug_pub.add(' Customer Price Zone '||x_cust_price_zone|| ' zone price list '||l_zone_price_list || ' web list'||l_web_price_list);
           --IF l_zone IS NULL THEN 
             --call made to get default price list
               OPEN cur_default_price_list (p_web_site_key_rec);
               FETCH cur_default_price_list 
               INTO x_price_list_id,x_list_type;
               
               oe_debug_pub.add(' Customer  default Price List '||x_price_list_id);
               IF cur_default_price_list%NOTFOUND then
                   x_return_status      := 'E' ;
                   x_return_status_text := ('Please Define default active price list');
               END IF;
               CLOSE cur_default_price_list;
               
           IF l_zone IS NOT NULL THEN 
              
               --Change price list name for Web Orders  
               IF p_session ='WWW' THEN 
               
                  -- check if the list contains the requested item
                  BEGIN
                        SELECT L.OPERAND into ln_base_price
                        FROM   QP_LIST_HEADERS_B B,
                               QP_LIST_LINES_V L,
                               MTL_SYSTEM_ITEMS I
                        WHERE  B.LIST_HEADER_ID = l_web_price_list
                        AND    L.LIST_HEADER_ID = B.LIST_HEADER_ID
                        AND    I.INVENTORY_ITEM_ID = L.PRODUCT_ATTR_VALUE
                        AND    I.ORGANIZATION_ID = ln_org_id;
                    
                        l_price_list := l_web_price_list;
                        
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        -- item not in the list, use zone price list instead
                        l_price_list := l_zone_price_list;

                  END;
                  
               ELSE
                  l_price_list := l_zone_price_list;
               END IF;
               oe_debug_pub.add(' Using Price List '||l_price_list);
                               
               OPEN cur_price_list (l_price_list);
               FETCH cur_price_list 
               INTO x_price_list_id,x_list_type;
               
               IF cur_price_list%NOTFOUND then
                    oe_debug_pub.add(' Zone Price List Not found '||l_price_list_name);
                    -- return default price list
               ElSE
                    oe_debug_pub.add(' Zone Price List '||x_price_list_id);
                    x_return_status      := 'S' ;
                END IF;
               CLOSE cur_price_list;
            
            END IF; -- zone is Null
      ELSE 
       -- no zip code available get default price list 
         OPEN  cur_default_price_list (p_web_site_key_rec);
         FETCH cur_default_price_list 
          INTO x_price_list_id,x_list_type;
         CLOSE cur_default_price_list;
           
         IF cur_default_price_list%NOTFOUND then
            x_return_status      := 'E' ;
            x_return_status_text := ('Please Define default active price list');
         END IF;
       
       END IF; --  no zip code 
       
       IF x_return_status IS NULL THEN 
          x_return_status      := 'S' ;
       END IF;
       
    END IF;     
    
    oe_debug_pub.add(' Returning PL= '||x_price_list_id);
    
   EXCEPTION
   WHEN OTHERS THEN
     fnd_file.put_line ('LOG', 'In 
     price_list others' ||sqlerrm );
      CLOSE cur_price_list_zip_code;
      CLOSE cur_price_list;
      x_return_status      := 'E' ;
      x_return_status_text := ('In Get_price_list -' ||sqlerrm );
      
  END Get_price_list;
  
  
-- +===================================================================+
-- | Name  : Get_sku_price                                             |
-- | Description : This procedure returns the price for a given        |
-- |               line item                                           |
-- |                                                                   |
-- +===================================================================+ 
  PROCEDURE Get_sku_price (
                      p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                    , p_source_id           IN  VARCHAR2
                    , p_Sector_Type         IN  VARCHAR2
                    , p_Referrer_Code       IN  VARCHAR2
                    , p_Ship_To_Postal_Code IN VARCHAR2
                    , p_Customer_Account_id IN NUMBER
                    , p_price_list_id       IN NUMBER  -- * see not at the top
                    , p_currency_code       IN VARCHAR2 -- * see not at the top
                    , x_line_rec            IN OUT NOCOPY XXOM_ORDER_LINE_REC_TYPE
                    , x_return_status       OUT NOCOPY VARCHAR2
                    , x_return_status_text  OUT NOCOPY VARCHAR2
                    ) is

 l_price_request_rec            APPS.XXOM_PRICE_REQUEST_REC_TYPE;
 l_priced_lines                 APPS.XXOM_ORDER_LINES_TBL_TYPE;
 lr_request_options             APPS.XX_QP_PREQ_OPTIONS;
 lt_coupons                     APPS.XX_ONT_ORDER_COUPON_TBL_TYPE;
 lr_ecom_site_key               APPS.XXOM_ECOM_SITEKEY_REC_TYPE;
 l_price_event                  VARCHAR2(30);
 


begin
 
  
      oe_debug_pub.add(' ====================================');
      oe_debug_pub.add('Getting the price for SKU '||x_line_rec.sku_id);
      
      lr_ecom_site_key := APPS.XXOM_ECOM_SITEKEY_REC_TYPE(p_web_site_key_rec.locale, p_web_site_key_rec.brand, p_web_site_key_rec.site_mode);
      
      l_price_request_rec := APPS.XXOM_PRICE_REQUEST_REC_TYPE(lr_ecom_site_key,NULL,NULL, p_Ship_To_Postal_Code,p_Customer_Account_id,p_currency_code);
                                
      lr_request_options := APPS.XX_QP_PREQ_OPTIONS('N','N','N');
      
      lt_coupons:=APPS.XX_ONT_ORDER_COUPON_TBL_TYPE();
      
      l_priced_lines:= APPS.XXOM_ORDER_LINES_TBL_TYPE();
      l_priced_Lines.extend();
      l_priced_lines(1):= x_line_rec;
      l_price_event:= 'LINE';

      XX_QP_PRICE_REQUEST_PKG.GET_PRICE_REQUEST(
              P_PRICE_MODE      => l_price_event,
              P_ORDER_SOURCE    => p_source_id,
              P_SITEKEY_ID      => p_web_site_key_rec,
              P_REQUEST_OPTIONS => lr_request_options,
              P_COUPONS_TBL     => lt_coupons,
              X_HEADER_REC      => l_price_request_rec,
              X_ORDER_LINES_TBL => l_priced_lines,
              X_RETURN_STATUS   => X_RETURN_STATUS,
              X_RETURN_STATUS_TEXT => X_RETURN_STATUS_TEXT
              );
      

      if (x_return_status <>'S') then
        dbms_output.put_line('Global Price Request - Errors reported');
        dbms_output.put_line('x_return_status ='||x_return_status);
        dbms_output.put_line('x_return_status_text='||x_return_status_text);
      end if;

      if (x_return_status = FND_API.G_RET_STS_SUCCESS) then
        -- overwriting the pricing information

        oe_debug_pub.add('priced lines = '||l_priced_lines.count);
        oe_debug_pub.add(' sell price='||l_priced_lines(l_priced_lines.first).sale_price||
                        ' list price='||l_priced_lines(l_priced_lines.first).list_price||
                        ' quantity='||l_priced_lines(l_priced_lines.first).quantity||
                        ' price list='||l_priced_lines(l_priced_lines.first).price_list_id||
                        ' extended price='||l_priced_lines(l_priced_lines.first).Extended_price||
                        ' Line number='||l_priced_lines(l_priced_lines.first).line_number);
  
            x_line_rec.list_price := l_priced_lines(l_priced_lines.first).List_price;
            x_line_rec.Sale_price := l_priced_lines(l_priced_lines.first).sale_price;
            x_line_rec.price_list_id := l_priced_lines(l_priced_lines.first).price_list_id;

      else
        x_return_status_text := x_return_status;
        oe_debug_pub.add('error getting the line price '||x_return_status_text);
      end if;

 
  EXCEPTION

  WHEN FND_API.G_EXC_ERROR THEN
        oe_debug_pub.add('Error finding the Price List ');

  WHEN OTHERS THEN
    X_RETURN_STATUS := FND_API.G_RET_STS_UNEXP_ERROR;
    x_return_status_text := 'XXOM_SKU_PUB.GET_PRICE ERROR: '||SQLERRM;
    oe_debug_pub.add(x_return_status_text);


end Get_sku_price;

END XX_QP_PRICELIST_SELECTION_PKG;
