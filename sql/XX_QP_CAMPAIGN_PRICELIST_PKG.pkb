create or replace PACKAGE BODY XX_QP_CAMPAIGN_PRICELIST_PKG AS


-- +===================================================================+
-- | Name  : Get_Campaign_Price_list                                   |
-- | Description : This procedure returns the price list with the most |
-- |              effective date for a given effort/campaign           |
-- |                                                                   |
-- | Parameters :                                                      |
-- | p_web_site_key_rec   => web site identifier                       |
-- | p_Price_zone         => commercial pricing zone for which the     |
-- |                         catalog was created. This also corresponds|
-- |                         to the customer pricing zone.             |
-- | p_Campaign_Code      => effort/campaign code that corresponds to  |
-- |                         the prefix of the SKU ID entered by the   |
-- |                         customer.                                 |
-- | Returns :                                                         |
-- |               x_price_List_ID => price header id                  |
-- |               x_price_List_type => G_PRICE_LIST_TYPE_CAMPAIGN     |
-- |                                                                   |
-- | Created by:   Bibiana Penski                                      |
-- | Last Updated: 04-OCT-07
-- +===================================================================+
  PROCEDURE Get_Campaign_PriceList (  
                                        p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                                      , p_Price_zone         IN VARCHAR2
                                      , p_Campaign_Code      IN VARCHAR2
                                      , x_price_List_Name    OUT NOCOPY VARCHAR2
                                      , x_price_List_ID      OUT NOCOPY NUMBER
                                      , x_price_List_Type    OUT NOCOPY VARCHAR2
                                      , x_err_code           OUT NOCOPY VARCHAR2
                                      , x_err_buff           OUT NOCOPY VARCHAR2  ) AS
            ln_org_id           NUMBER;
            ld_end_date_active  QP_LIST_HEADERS.END_DATE_ACTIVE%TYPE;
  BEGIN
             x_price_List_ID:= NULL;
             x_price_List_Type := NULL;
             x_err_code   :=FND_API.G_RET_STS_ERROR; 
             x_err_buff   :=FND_API.G_MISS_CHAR;
             
             -- Parameter Validation
              IF (p_Price_zone is null) THEN
                    x_err_buff:= 'INVALID_ZONE';
                    fnd_message.set_name('ONT','INVALID_ZONE');
                    OE_MSG_PUB.Add;
                    RAISE FND_API.G_EXC_ERROR;
              END IF;  
               
              IF (p_Campaign_Code is null) THEN
                    x_err_buff:= 'INVALID_CAMPAIGN';
                    fnd_message.set_name('ONT','INVALID_CAMPAIGN');
                    OE_MSG_PUB.Add;
                    RAISE FND_API.G_EXC_ERROR;
              END IF;
              
              fnd_profile.get('ORG_ID', ln_org_id);
              IF (ln_org_id is null) THEN
                    x_err_buff:= 'ORGANIZATION_ID CANNOT BE NULL';
                    RAISE FND_API.G_EXC_ERROR;
              END IF;
             
              -- the followign statement selects the catalog price list with the most
              -- effective date has the following naming conventions:
              -- [zone name] + '_' + [effort/campaign code] + '_' + [MMYY] + [event name]
              
              SELECT  T.LIST_HEADER_ID, T.NAME, NVL(B.END_DATE_ACTIVE,SYSDATE+1) , B.LIST_TYPE_CODE
              INTO    x_price_List_id, x_price_List_Name, ld_end_date_active, x_price_List_Type
              FROM    QP_LIST_HEADERS B,
                      QP_LIST_HEADERS_TL T
              WHERE   T.LIST_HEADER_ID = B.LIST_HEADER_ID
              AND     T.NAME LIKE p_Price_zone||'_'||p_Campaign_Code ||'_%'
              AND     B.ACTIVE_FLAG = 'Y'
              AND     B.START_DATE_ACTIVE = (SELECT MAX( A.START_DATE_ACTIVE) 
                                             FROM QP_LIST_HEADERS A
                                             WHERE  A.NAME LIKE p_Price_zone||'_'||p_Campaign_Code ||'_%'
                                             AND    A.ACTIVE_FLAG = 'Y'
                                             AND    SYSDATE BETWEEN A.START_DATE_ACTIVE AND NVL(A.END_DATE_ACTIVE, SYSDATE + 1)
                                             )
              AND     SYSDATE BETWEEN B.START_DATE_ACTIVE AND NVL(B.END_DATE_ACTIVE, SYSDATE+1)
              AND     B.ORIG_ORG_ID = ln_org_id;
              
             
              IF ld_end_date_active > sysdate THEN
                x_price_List_Type := G_PRICE_LIST_TYPE_CAMPAIGN;
                x_err_code   :=FND_API.G_RET_STS_SUCCESS;
              ELSE
                x_err_buff:= 'EXPIRED_CAMPAIGN';
              END IF;
    
   
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
          x_err_buff:= 'PRICE_LIST_NOT_FOUND';
          fnd_message.set_name('ONT','PRICE_LIST_NOT_FOUND');
          OE_MSG_PUB.Add;
    WHEN FND_API.G_EXC_ERROR THEN
          NULL;
    
    WHEN OTHERS THEN
          x_err_buff:= SUBSTR(SQLERRM,1,200);
  END Get_Campaign_PriceList;
  


END XX_QP_CAMPAIGN_PRICELIST_PKG;
