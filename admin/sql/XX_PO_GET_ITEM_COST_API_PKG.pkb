CREATE OR REPLACE PACKAGE BODY APPS.XX_PO_GET_ITEM_COST_API_PKG
AS
PROCEDURE GET_ITEM_COST(p_vendor_id        IN      NUMBER
                       ,p_item_id          IN      NUMBER
                       ,p_order_qty        IN OUT  NUMBER
                       ,p_vendor_site_id   IN OUT  NUMBER
                       ,p_line_price       OUT     NUMBER
                       ,p_line_id          OUT     NUMBER
                       ,x_return_code      OUT     VARCHAR2) IS


             --p_vendor_id                NUMBER:=10001;
             --p_item_id                  NUMBER:=2027;
             --p_order_qty                NUMBER:=1;
             
             p_currency_code              VARCHAR2(30);
             p_org_id                     NUMBER; --:=141;
             x_vendor_site_id             NUMBER;
             x_document_header_id         NUMBER;
             x_document_type_code         VARCHAR2(30);
             x_document_line_num          NUMBER;
             x_document_line_id           NUMBER;
             x_vendor_contact_id          NUMBER;
             x_vendor_product_num         VARCHAR2(30);
             x_buyer_id                   NUMBER;
             x_purchasing_uom             VARCHAR2(30):='Each';
             
             -- ln_price                     NUMBER:=0;
BEGIN

-- Deriving Quotation Info for the Item for a given Supplier 

  BEGIN

    PO_AUTOSOURCE_SV.get_latest_document(
             p_item_id,                      --x_item_id 
             p_vendor_id,                    --x_vendor_id
             NULL,                           --x_destination_doc_type
             p_currency_code,                --x_currency_code
             NULL,                           --x_item_rev
             SYSDATE,                        --x_autosource_date
             p_vendor_site_id             ,  --x_vendor_site_id
             x_document_header_id         ,
             x_document_type_code         ,
             x_document_line_num          ,
             x_document_line_id           ,
             x_vendor_contact_id          ,
             x_vendor_product_num         ,
             x_buyer_id                   ,
             x_purchasing_uom             ,
             NULL,                           --x_asl_id
             'Y',                            --x_multi_org
             'N',                            --p_vendor_site_sourcing_flag
             NULL,                           --p_vendor_site_code
             p_org_id,                       --p_org_id
             NULL,                           --p_item_rev_control
             NULL,                           --p_using_organization_id
             NULL,                           --p_category_id
         'Y'                             --p_return_contract
     );
     
     p_line_id :=  x_document_line_id;
     
  EXCEPTION
  WHEN OTHERS THEN

    x_return_code:= -1;

  END;

  IF p_order_qty is NULL or p_order_qty = 0 THEN
     p_order_qty := 1;
  END IF;
  
  -- Deriving Price Break Info 
  p_line_price:=  PO_SOURCING2_SV.GET_BREAK_PRICE(x_order_quantity => p_order_qty,
                        x_ship_to_org=>NULL,
                        x_ship_to_loc=>NULL,
                        x_po_line_id=>x_document_line_id,
                        x_cum_flag=>FALSE,
                        p_need_by_date=>SYSDATE,
                        x_line_location_id=>NULL);
  --DBMS_OUTPUT.PUT_LINE(' Price ='||ln_price);
    
  x_return_code:= 0;

EXCEPTION
WHEN OTHERS THEN

     x_return_code:= -1;
                        
END;
END XX_PO_GET_ITEM_COST_API_PKG; 
/

