create or replace PACKAGE "XX_QP_CAMPAIGN_PRICELIST_PKG" AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :  XX_QP_PRICE_REQUEST_PKG                                  |
-- | Description: Interface created to select the Price List Header ID |
-- | that must be sent to QP for pricing calculation.                  |
-- | See I2022_PriceSelection_BestPrice MD050 and related docs.        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 04-OCT-2007  B.Penski         Initial draft version       |
-- |1.0      23-OCT-2007  B.Penski         Added as a single package   |
-- +===================================================================+


-- PRICE LIST TYPES
G_PRICE_LIST_TYPE_CAMPAIGN CONSTANT VARCHAR2(30):='CAMPAIGN';
G_PRICE_LIST_TYPE_CZONE    CONSTANT VARCHAR2(30):='COMMERCIAL ZONE';
G_PRICE_LIST_TYPE_WZONE    CONSTANT VARCHAR2(30):='WEB ZONE';
G_PRICE_LIST_TYPE_CUSTOMER CONSTANT VARCHAR2(30):='CUSTOMER';
G_PRICE_LIST_TYPE_FREIGHT  CONSTANT VARCHAR2(30):='FREIGHT';
G_PRICE_LIST_TYPE_STORE    CONSTANT VARCHAR2(30):='STORE';
G_PRICE_LIST_TYPE_DEFAULT  CONSTANT VARCHAR2(30):='DEFAULT';

-- +===================================================================+
-- | Name  : Get_Campaign_Price_list                                   |
-- | Description : This procedure returns the price list for a given   |
-- |               effort/campaign used by customer                    |
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
-- |               x_price_List_Name => Cataloge name (Price List name)|
-- |               x_price_List_ID   => price header id                |
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
                                      , x_err_buff           OUT NOCOPY VARCHAR2  );



END "XX_QP_CAMPAIGN_PRICELIST_PKG";
