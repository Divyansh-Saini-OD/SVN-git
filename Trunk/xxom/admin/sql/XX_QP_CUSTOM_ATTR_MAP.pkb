SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY "XX_QP_CUSTOM_ATTR_MAP" AS
--+====================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name       :    XX_QP_CUSTOM_ATTR_MAP.pks                         |
-- | Description:    Map custom attributes to custom PTE               |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 27-APR-07    Raj Jagarlamudi  Initial draft version       |
-- |                                                                   |
-- +===================================================================+

-- Attribute Map List details for coupon issues 
 /*=======================================================================+
 | Qualifier_Attribute31  - Channel.
 | Qualifier_Attribute34  - Customer Type 
 | Qualifier_Attribute35  - Department
 | Qualifier_Attribute36 -  Class
 *=======================================================================*/
 
/***********************************************************************
/*  Get OD Ship Country 
/***********************************************************************/

FUNCTION get_om_ship_to_country(p_ship_to_org_id IN NUMBER)
RETURN VARCHAR2
AS
    lc_ship_to_country      VARCHAR2(100);

BEGIN

    SELECT  distinct country
    INTO    lc_ship_to_country
    FROM    apps.hz_locations loc,
            apps.hz_cust_site_uses_all csu,
            apps.hz_cust_acct_sites_all cas,
            apps.hz_party_sites ps
    WHERE   csu.site_use_id       = p_ship_to_org_id
    AND     csu.cust_acct_site_id = cas.cust_acct_site_id
    AND     cas.party_site_id     = ps.party_site_id
    AND     ps.location_id        = loc.location_id;


    RETURN lc_ship_to_country;

   EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_om_ship_to_country;

/***********************************************************************
/*  Get OD customer category code
/***********************************************************************/

FUNCTION get_cust_category(p_sold_to_org_id IN NUMBER)
RETURN VARCHAR2
AS
    lc_cust_category      VARCHAR2(100);

BEGIN

    SELECT  distinct category_code
    INTO    lc_cust_category
    FROM    apps.hz_parties cust_party,
            apps.hz_cust_accounts cust_account
    WHERE   cust_account.cust_account_id       = p_sold_to_org_id
    AND     cust_account.party_id              = cust_party.party_id;


    RETURN lc_cust_category;

   EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_cust_category;


/***********************************************************************
/*  Get OD customer revenue code DFF
/***********************************************************************/

FUNCTION get_cust_revenue_code(p_ship_to_org_id IN NUMBER)
RETURN VARCHAR2
AS
    lc_cust_revenue_code      VARCHAR2(100);

BEGIN

    SELECT  acct_sites.attribute4
    INTO    lc_cust_revenue_code
    FROM    apps.hz_cust_acct_sites_all acct_sites,
            apps.hz_cust_site_uses_all site_uses
    WHERE   site_uses.site_use_id       = p_ship_to_org_id
    AND     site_uses.cust_acct_site_id = acct_sites.cust_acct_site_id;

    RETURN lc_cust_revenue_code;

    EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_cust_revenue_code;

/***********************************************************************
/*  Get OD Order Ship To state code
/***********************************************************************/


FUNCTION get_om_ship_to_state(p_ship_to_org_id IN NUMBER)
RETURN VARCHAR2
AS
    lc_ship_to_state      VARCHAR2(100);

BEGIN

    SELECT  distinct state
    INTO    lc_ship_to_state
    FROM    apps.hz_locations loc,
            apps.hz_cust_site_uses_all csu,
            apps.hz_cust_acct_sites_all cas,
            apps.hz_party_sites ps
    WHERE   csu.site_use_id       = p_ship_to_org_id
    AND     csu.cust_acct_site_id = cas.cust_acct_site_id
    AND     cas.party_site_id     = ps.party_site_id
    AND     ps.location_id        = loc.location_id;


    RETURN lc_ship_to_state;

    EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_om_ship_to_state;

/***********************************************************************
/*  Get OD Order Ship To zip code
/***********************************************************************/

FUNCTION get_om_ship_to_zip(p_ship_to_org_id IN NUMBER)
RETURN VARCHAR2
AS
    lc_ship_to_zip      VARCHAR2(100);

BEGIN

    SELECT  distinct postal_code
    INTO    lc_ship_to_zip
    FROM    apps.hz_locations loc,
            apps.hz_cust_site_uses_all csu,
            apps.hz_cust_acct_sites_all cas,
            apps.hz_party_sites ps
    WHERE   csu.site_use_id       = p_ship_to_org_id
    AND     csu.cust_acct_site_id = cas.cust_acct_site_id
    AND     cas.party_site_id     = ps.party_site_id
    AND     ps.location_id        = loc.location_id;


    RETURN lc_ship_to_zip;

   EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END get_om_ship_to_zip;

/***********************************************************************
/*  Get OD Order Ship metod code
/***********************************************************************/

FUNCTION get_om_ship_method(p_order_header_id IN NUMBER)
RETURN VARCHAR2
AS
    lc_ship_method      VARCHAR2(100);

BEGIN

    select shipping_method_code
    into   lc_ship_method
    from   oe_order_headers_all
    where  header_id = p_order_header_id;

    RETURN lc_ship_method;

    EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_om_ship_method;

/***********************************************************************
/*  Get Disocunted order amount
/***********************************************************************/

FUNCTION  get_om_order_amt (p_header_id IN NUMBER)
RETURN NUMBER
IS

lc_orders_total_amt      NUMBER;
lc_orders_total_qty      NUMBER;
lc_returns_total_amt     NUMBER;
lc_returns_total_qty     NUMBER;
lc_order_amount        NUMBER;

BEGIN

  --IF qp_preq_grp.g_new_pricing_call = qp_preq_grp.g_yes then

      BEGIN
          SELECT SUM(nvl(ol.ordered_quantity,0)*(ol.unit_selling_price)),
                 SUM(nvl(ol.ordered_quantity,0))
          INTO   lc_orders_total_amt, lc_orders_total_qty
          FROM   oe_order_lines ol
          WHERE  ol.header_id= p_header_id
          AND    (ol.cancelled_flag='N' OR ol.cancelled_flag IS NULL)
          AND    (ol.line_category_code<>'RETURN' OR ol.line_category_code IS NULL)
          GROUP BY header_id;

      EXCEPTION
            WHEN no_data_found THEN
            null;
      END;

      --END IF;
   lc_order_amount := FND_NUMBER.NUMBER_TO_CANONICAL(NVL(lc_orders_total_amt,0)-NVL(lc_returns_total_amt,0));
   RETURN lc_order_amount;
   
   EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END;

/******************************************************************************
/*  Get Discounted item amount
/******************************************************************************/


FUNCTION get_disc_item_amount( p_ordered_qty IN NUMBER,p_pricing_qty IN NUMBER)
RETURN VARCHAR2
IS

x_return NUMBER;

BEGIN

  x_return := FND_NUMBER.NUMBER_TO_CANONICAL(NVL(p_pricing_qty,p_ordered_qty) * 
                    NVL(OE_ORDER_PUB.G_LINE.UNIT_SELLING_PRICE_PER_PQTY, 
                            OE_ORDER_PUB.G_LINE.UNIT_SELLING_PRICE));

  IF (OE_ORDER_PUB.G_LINE.UNIT_SELLING_PRICE_PER_PQTY IS NULL) 
      AND (OE_ORDER_PUB.G_LINE.UNIT_SELLING_PRICE is NULL) THEN
     x_return := 0;
  END IF;

  RETURN x_return;

END Get_Disc_Item_Amount;

/***********************************************************************
/*  Get Discounted item Cost
/***********************************************************************/

FUNCTION get_item_cost(p_inventory_item_id IN NUMBER, p_organization_id IN NUMBER)
RETURN VARCHAR2
AS
    	lc_item_cost      VARCHAR2(100);

	BEGIN
    		select distinct item_cost
    		into   lc_item_cost
    		from   cst_item_costs
    		where  inventory_item_id = p_inventory_item_id
		and organization_id = p_organization_id;


    	RETURN lc_item_cost;

    EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_item_cost;

/***********************************************************************
/*  Get Item Manufacuturer Name
/***********************************************************************/


FUNCTION get_item_manufacturer(p_inventory_item_id IN NUMBER, p_organization_id IN NUMBER)
RETURN VARCHAR2
AS
    	lc_item_manufacturer      VARCHAR2(100);

	BEGIN

		select mm.manufacturer_name
		into lc_item_manufacturer
		from mtl_manufacturers mm
		where mm.manufacturer_id = 
                        (select manufacturer_id from mtl_mfg_part_numbers mmpn 
                         where  mmpn.inventory_item_id = p_inventory_item_id 
                          and mmpn.organization_id = p_organization_id);
    		
    	RETURN lc_item_manufacturer;

    EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_item_manufacturer;

/***********************************************************************
/*  Get Item Vendor Name
/***********************************************************************/

FUNCTION get_item_vendor(p_inventory_item_id IN NUMBER, p_organization_id IN NUMBER)
RETURN VARCHAR2
AS
    	lc_item_vendor      VARCHAR2(100);

	BEGIN
    		select attribute11
    		into   lc_item_vendor
    		from   mtl_system_items_b
    		where  inventory_item_id = p_inventory_item_id
		and organization_id = p_organization_id;


    	RETURN lc_item_vendor;

    EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_item_vendor;

/***********************************************************************
/*  Get OD Item Brand Name
/***********************************************************************/

FUNCTION get_item_OD_brand(p_inventory_item_id IN NUMBER)
RETURN VARCHAR2
AS
    	lc_item_OD_brand      VARCHAR2(100);

	BEGIN
    		select segment12
    		into   lc_item_OD_brand
    		from   mtl_categories_b mcb, mtl_item_categories mic
    		where  mic.inventory_item_id = p_inventory_item_id
		and mic.category_id = mcb.category_id
		and mIC.category_set_id = (select category_set_id FROM mtl_category_sets_tl 
                                           where category_set_name = 'OD Item Brand Category');


    	RETURN lc_item_OD_brand;

    EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_item_OD_brand;

/***********************************************************************
/*  Get OD Item Type
/***********************************************************************/

FUNCTION get_item_type(p_inventory_item_id IN NUMBER)
  RETURN VARCHAR2
AS
	lc_item_type VARCHAR2(100);

	BEGIN
		select item_type
		into lc_item_type
		from mtl_system_items_b
		where inventory_item_id = p_inventory_item_id
		and organization_id = (select organization_id FROM mtl_parameters 
                                       WHERE  master_organization_id = organization_id);

	RETURN lc_item_type;

    EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_item_type;

/***********************************************************************************
/*  Get OD List Price
/***********************************************************************************/
FUNCTION get_list_price(p_list_header_id IN NUMBER, p_inventory_item_id IN NUMBER)
RETURN VARCHAR2
AS
    	lc_list_price      VARCHAR2(100);

	BEGIN
            select qll.operand
            into lc_list_price
            from qp_list_lines qll, qp_pricing_attributes qpa
            where qll.list_header_id = p_list_header_id
            and qll.list_header_id = qpa.list_header_id
            and qll.list_line_id = qpa.list_line_id
            and qpa.product_attr_value = to_char(p_inventory_item_id);
            
    	RETURN lc_list_price;

    EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_list_price;

/***********************************************************************************
/*  Get OD Item Cost
/***********************************************************************************/
FUNCTION get_OD_cost(p_inventory_item_id IN NUMBER, p_organization_id IN NUMBER)
RETURN VARCHAR2
AS
    	lc_OD_cost      VARCHAR2(100);

	BEGIN
    		select distinct attribute11
    		into   lc_OD_cost
    		from   mtl_system_items_b
    		where  inventory_item_id = p_inventory_item_id
		and organization_id = p_organization_id;


    	RETURN lc_OD_cost;

    EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_OD_cost;

/***********************************************************************************
/*  Get OD Order Source
/***********************************************************************************/

FUNCTION get_order_source(p_order_source_id IN NUMBER)
  RETURN VARCHAR2

AS
    lc_order_source      VARCHAR2(100);

	BEGIN
    		SELECT  name
    		INTO    lc_order_source
    		FROM    oe_order_sources
    		WHERE	order_source_id = p_order_source_id;
    		
	RETURN lc_order_source;

    EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_order_source;

/***********************************************************************/
/*    Get OD department 
/***********************************************************************/
FUNCTION get_dept(p_inv_item_id IN NUMBER)
RETURN VARCHAR2
AS
    lc_dept      VARCHAR2(100);

BEGIN
    IF p_inv_item_id is not null then
      
        select b.segment3
        into   lc_dept
        from   mtl_categories_b b, 
               mtl_item_categories m
        where  m.category_id = b.category_id
        and    m.inventory_item_id = p_inv_item_id
        and    m.organization_id = to_number(FND_PROFILE.VALUE('QP_ORGANIZATION_ID')) 
        and    m.category_set_id = (select category_set_id 
                                    FROM mtl_category_sets_tl 
                                    where category_set_name = 'Inventory');

    END IF;
    
    RETURN lc_dept;

    EXCEPTION
        WHEN no_data_found THEN
          RETURN NULL;
        WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_dept;

/***********************************************************************/
/*    Get OD department class
/***********************************************************************/

FUNCTION get_class(p_inv_item_id IN NUMBER)
RETURN VARCHAR2
AS
    lc_class      VARCHAR2(100);

BEGIN
    IF p_inv_item_id is not null then
        
        select b.segment4
        into   lc_class
        from   mtl_categories_b b, 
               mtl_item_categories m
        where  m.category_id = b.category_id
        and    m.inventory_item_id = p_inv_item_id
        and    m.organization_id = to_number(FND_PROFILE.VALUE('QP_ORGANIZATION_ID'))
        and    m.category_set_id = (select category_set_id 
                                    FROM mtl_category_sets_tl 
                                    where category_set_name = 'Inventory');

    END IF;
    
    RETURN lc_class;

   EXCEPTION
        WHEN no_data_found THEN
              RETURN NULL;
        WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_class;

/***********************************************************************
/*  Get OD customer Account Type 
/***********************************************************************/

FUNCTION get_customer_type(p_sold_to_org_id IN NUMBER)
  RETURN VARCHAR2
AS
    lc_customer_type      VARCHAR2(100);
    
BEGIN
     IF p_sold_to_org_id is not null then
     
        SELECT attribute1
        into lc_customer_type
        from hz_cust_accounts
        where cust_account_id = p_sold_to_org_id;
      
     END IF;
    
     RETURN lc_customer_type;

     EXCEPTION
      WHEN no_data_found then
          RETURN NULL;
      WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END get_customer_type;

/***********************************************************************
/*  Get Pricing Group 
/***********************************************************************/

FUNCTION get_pricing_group(p_inv_item_id IN NUMBER)
RETURN VARCHAR2
AS
    lc_pricing_group      VARCHAR2(100);

BEGIN
    IF p_inv_item_id is not null then
        
        select b.segment1
        into   lc_pricing_group
        from   mtl_categories_b b, 
               mtl_item_categories m
        where  m.category_id = b.category_id
        and    m.inventory_item_id = p_inv_item_id
        and    m.organization_id = to_number(FND_PROFILE.VALUE('QP_ORGANIZATION_ID'))
        and    m.category_set_id = (select category_set_id 
                                    FROM mtl_category_sets_tl 
                                    where category_set_name = 'Pricing Discount Group');

    END IF;
    
    RETURN lc_pricing_group;

   EXCEPTION
        WHEN no_data_found THEN
              RETURN NULL;
        WHEN OTHERS THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END get_pricing_group;

END;
