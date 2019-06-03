CREATE OR REPLACE PACKAGE APPS.XX_PO_GET_ITEM_COST_API_PKG AS

PROCEDURE GET_ITEM_COST(p_vendor_id        IN      NUMBER
                       ,p_item_id          IN      NUMBER
                       ,p_order_qty        IN OUT  NUMBER
                       ,p_vendor_site_id   IN OUT  NUMBER
                       ,p_line_price       OUT     NUMBER
                       ,p_line_id          OUT     NUMBER
                       ,x_return_code      OUT     VARCHAR2);
END XX_PO_GET_ITEM_COST_API_PKG; 
/

