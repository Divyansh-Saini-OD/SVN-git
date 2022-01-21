CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_ORDER_FLOW_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_ORDER_FLOW_PKG                                    |
-- | Description: Office Depot - Custom ATP                                    |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1A 21-jun-2007  Roy Gomes        Initial draft version               |
-- |                                                                           |
-- +===========================================================================+


   FUNCTION Is_Flow_Cust_Set_Loc
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

   BEGIN

     IF p_cust_setup_org IS Not Null THEN
        Return ('Yes');
     ELSE
        Return ('No');
     END IF;

   END Is_Flow_Cust_Set_Loc;

   FUNCTION Is_Flow_DPS
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

   BEGIN

     IF p_category_name = 'D' THEN
        Return ('Yes');
     ELSE
        Return ('No');
     END IF;

   END Is_Flow_DPS; 

   FUNCTION Is_Flow_Export
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

   BEGIN

      IF p_order_type = 'EXPORT' THEN
         Return ('Yes');
      ELSE
         Return ('No');
      END IF;

   END Is_Flow_Export; 

   FUNCTION Is_Flow_Seasonal
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

   BEGIN

      IF p_order_type = 'SEASONAL' THEN
         Return ('Yes');
      ELSE
         Return ('No');
      END IF;

   END Is_Flow_Seasonal; 

   FUNCTION Is_Flow_Pickup
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

   BEGIN

      IF p_pickup = 'Y' THEN
         Return ('Yes');
      ELSE
         Return ('No');
      END IF;

   END Is_Flow_Pickup; 

   FUNCTION Is_Flow_Furniture
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

   BEGIN

     IF p_category_name = 'F' THEN
        Return ('Yes');
     ELSE
        Return ('No');
     END IF;

   END Is_Flow_Furniture; 

   FUNCTION Is_Flow_Hub
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

   BEGIN

     IF p_category_name = 'H' THEN
        Return ('Yes');
     ELSE
        Return ('No');
     END IF;

   END Is_Flow_Hub; 

   FUNCTION Is_Flow_Standard
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

   BEGIN

     IF p_category_name = 'S' THEN
        Return ('Yes');
     ELSE
        Return ('No');
     END IF;

   END Is_Flow_Standard;

   FUNCTION Is_Flow_User_Input_Loc
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

   BEGIN
  
     IF p_ship_from_org IS NOT Null THEN
        Return ('Yes');
     ELSE
        Return ('No');
     END IF;

   END Is_Flow_User_Input_Loc;


   FUNCTION Is_Flow_APO_FPO
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

      CURSOR c_ap (c_customer_number AR_CUSTOMERS_V.customer_number%Type) IS
         SELECT s.attribute24 
         FROM   ar_customers_v c, 
                ar_addresses_v a, 
                hz_site_uses_v s
         WHERE  a.address_id = s.address_id
         AND    a.customer_id = c.customer_id
         AND    a.status = 'A'
         AND    s.status = 'A'
         AND    c.status = 'A'
         AND    s.site_use_code = 'SHIP_TO'
         AND    c.customer_number = c_customer_number;

      l_yes_no HZ_SITE_USES_V.attribute24%Type;

   BEGIN

      OPEN c_ap (p_customer_number);
      FETCH c_ap INTO l_yes_no;
      CLOSE c_ap;

      IF l_yes_no = 'Y' THEN
         Return('Yes');
      ELSE
         Return('No');
      END IF;

   END Is_Flow_APO_FPO;


   FUNCTION Is_Flow_CA_National
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

      CURSOR c_ap (c_customer_number AR_CUSTOMERS_V.customer_number%Type) IS
         SELECT s.attribute25 
         FROM   ar_customers_v c, 
                ar_addresses_v a, 
                hz_site_uses_v s
         WHERE  a.address_id = s.address_id
         AND    a.customer_id = c.customer_id
         AND    a.status = 'A'
         AND    s.status = 'A'
         AND    c.status = 'A'
         AND    s.site_use_code = 'SHIP_TO'
         AND    c.customer_number = c_customer_number;

      l_yes_no HZ_SITE_USES_V.attribute25%Type;

   BEGIN
  
      OPEN c_ap (p_customer_number);
      FETCH c_ap INTO l_yes_no;
      CLOSE c_ap;

      IF l_yes_no = 'Y' THEN
         Return('Yes');
      ELSE
         Return('No');
      END IF;

   END Is_Flow_CA_National;


   FUNCTION Is_Flow_Bulk
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

   BEGIN

      IF p_bulk = 'Y' THEN
         Return('Yes');
      ELSE
         Return('No');
      END IF;

   END Is_Flow_Bulk;

   /* -------------------------------------------------------------------------- *

    *              Sample function to be added for each new flow                 *

    * -------------------------------------------------------------------------- *

   FUNCTION Is_Flow_MyFlow
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2
      ) RETURN VARCHAR2 IS

   BEGIN
  
     IF <condition> THEN
        Return ('Yes');
     ELSE
        Return ('No');
     END IF;

   END Is_Flow_MyFlow;

  

    * -------------------------------------------------------------------------- */


END XX_MSC_SOURCING_ORDER_FLOW_PKG;
/
