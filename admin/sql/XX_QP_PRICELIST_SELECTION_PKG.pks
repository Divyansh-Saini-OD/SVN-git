create or replace
PACKAGE "XX_QP_PRICELIST_SELECTION_PKG" AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :  XX_QP_PRICE_LIST_SELECTION_PKE                           |
-- | Rice  :  I2022 Price List-Best Price List Selection               |
-- | Description: This package contains the functionality necessary to |
-- | assign the price list to the request line before sending the to   |
-- | QP.                                                               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 24-JUL-2007  B.Penski         Initial draft version       |
-- |1.1      25-OCT-2007                   Added customer specific-PLMS|
-- |1.2      22-Jan-2008  B.Penski         Standarized parameters with |
-- |                                       the plselection_rec record  |
-- +===================================================================+

G_MAP_Price_list_BRF NUMBER:=111;
G_MSRP_Price_list_BRF NUMBER:=222;
G_Store_Price_list_BRF NUMBER:=333;

G_FIRST_PRICE_LIST    VARCHAR2(1):= 'F';
G_BEST_PRICE_LIST     VARCHAR2(1):= 'B';

-- +===================================================================+
-- | Name  : Get_MAP_Price_list                                        |
-- | Description : This procedure returns the MAP price list           |
-- |               the rules framework being designed.                 |
-- |                                                                   |
-- +===================================================================+ 
  PROCEDURE Get_MAP_Pricelist (   p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE 
                                , p_plselection_rec    IN XX_QP_PLSELECTION_REC_TYPE
                                , x_price_list_rec     OUT NOCOPY XX_QP_PRICE_LIST_REC_TYPE
                                , x_return_code        OUT NOCOPY VARCHAR2
                                , x_return_msg         OUT NOCOPY VARCHAR2  );
                                
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
PROCEDURE Get_Price_List (   p_web_site_key_rec    IN XX_GLB_SITEKEY_REC_TYPE
                           , p_Request_Mode        IN VARCHAR2 
                           , p_header_rec          IN XXOM_PRICE_REQUEST_REC_TYPE                   -- To be replaced with oe_order_header
                           , x_header_attrs_rec    IN OUT NOCOPY XX_OM_HEADER_ATTRS_REC_TYPE
                           , x_Lines_tbl           IN OUT NOCOPY XXOM_ORDER_LINES_TBL_TYPE            -- to be replaced with oe_order_lines
                           , x_lines_attrs_tbl     IN OUT NOCOPY XX_OM_LINE_ATTRS_TBL_TYPE
                           , x_msg_count          OUT NOCOPY NUMBER
                           , x_return_status      OUT NOCOPY VARCHAR2
                           , x_return_msg         OUT NOCOPY VARCHAR2
                               );

 

END;