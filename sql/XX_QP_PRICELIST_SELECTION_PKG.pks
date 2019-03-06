create or replace PACKAGE "XX_QP_PRICELIST_SELECTION_PKG" AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :  XX_QP_PRICE_REQUEST_PKG                                  |
-- | Description: Interface created to interact with  Oracle Advance   |
-- | Pricing (QP) for all Order entry applications in OD.              |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 24-JUL-2007  B.Penski         Initial draft version       |
-- |1.1      25-OCT-2007                   Added customer specific-PLMS|
-- +===================================================================+

TYPE XX_QP_PRICE_LIST_REC_TYPE IS RECORD 
(
    Price_list_header_id   NUMBER,
    Price_list_precedence  NUMBER,
    Price_list_Name        VARCHAR2(40), 
    Price_list_type        VARCHAR2(40),
    Type_name              VARCHAR2(40)
);

TYPE XX_QP_PRICE_LIST_TBL_TYPE IS TABLE OF XX_QP_PRICE_LIST_REC_TYPE;



-- PRICE LIST TYPES
G_PRICE_LIST_TYPE_CAMPAIGN CONSTANT VARCHAR2(30):='CAMPAIGN';
G_PRICE_LIST_TYPE_CZONE    CONSTANT VARCHAR2(30):='COMMERCIAL ZONE';
G_PRICE_LIST_TYPE_WZONE    CONSTANT VARCHAR2(30):='WEB ZONE';
G_PRICE_LIST_TYPE_CUSTOMER CONSTANT VARCHAR2(30):='CUSTOMER';
G_PRICE_LIST_TYPE_FREIGHT  CONSTANT VARCHAR2(30):='FREIGHT';
G_PRICE_LIST_TYPE_STORE    CONSTANT VARCHAR2(30):='STORE';
G_PRICE_LIST_TYPE_DEFAULT  CONSTANT VARCHAR2(30):='DEFAULT';

-- PRICE LIST PRECEDENCE ORDER
G_PRECEDENCE_STORE    CONSTANT NUMBER:=2;
G_PRECEDENCE_CUSTOMER CONSTANT NUMBER:=1;
G_PRECEDENCE_CAMPAIGN CONSTANT NUMBER:=4;
G_PRECEDENCE_ZONE     CONSTANT NUMBER:=5;

                                 
-- +===================================================================+
-- | Name  :Is_Zone_Price_Allowed                                      |
-- | Description : This function validates if zone pricing is allowed  |
-- |               for a given customer                                |
-- |                                                                   |
-- +===================================================================+                                      
FUNCTION Is_Zone_Price_Allowed(  p_Order_Header_Rec IN XXOM_PRICE_REQUEST_REC_TYPE
                               , p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE
                              ) RETURN BOOLEAN;

-- +===================================================================+
-- | Name  :Chk_Customer_Specific_Price                                |
-- | Description : This procedure returns checks if a particular       |
-- |               customer has specific price list associated         |
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
                                  , x_err_code                  OUT NOCOPY VARCHAR2 ) ;
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
                                 , x_err_code          OUT NOCOPY VARCHAR2 ) ;

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
                               , x_usr_msg_tbl        OUT NOCOPY XXOM_VARCHAR2_2000_TBL);

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
                         ,x_return_status_text OUT NOCOPY VARCHAR2 );   

END;