CREATE OR REPLACE PACKAGE XX_MSC_SOURCING_PARAMS_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_PARAMS_PKG                                        |
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

   PROCEDURE Get_Org_From_Cust_Setup
      (
         p_customer_number       IN  RA_CUSTOMERS.customer_number%Type,
         x_org                   OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      );

   PROCEDURE Get_Category_Name
      (
         p_item_id              IN  MSC_SYSTEM_ITEMS.inventory_item_id%Type,
         p_org_id               IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_category_set_id      IN  MSC_CATEGORY_SETS.category_set_id%Type,
         x_category_name        OUT MSC_ITEM_CATEGORIES.Category_name%Type,
         x_return_status        OUT VARCHAR2,
         x_msg                  OUT VARCHAR2
      );

   PROCEDURE Get_Item_ID
      (
          p_item_name          IN  MSC_SYSTEM_ITEMS.item_name%Type,
          p_organization_id    IN  MSC_SYSTEM_ITEMS.organization_id%Type,
          x_item_id            OUT MSC_SYSTEM_ITEMS.inventory_item_id%Type, 
          x_sr_item_id         OUT MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
          x_return_status      OUT VARCHAR2,
          x_msg                OUT VARCHAR2
      );

   PROCEDURE Get_Org_ID
      (
         p_base_org              IN  MTL_PARAMETERS_VIEW.organization_code%Type,
         x_organization_id       OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       );

   PROCEDURE Get_Zone
      (
         p_postal_code          IN  WSH_ZONE_REGIONS_V.postal_code_from%Type,
         p_category_name        IN  MSC_ITEM_CATEGORIES.category_name%Type,
         x_zone_id              OUT WSH_ZONE_REGIONS_V.zone_id%Type,
         x_return_status        OUT VARCHAR2,
         x_msg                  OUT VARCHAR2
      );

   PROCEDURE Get_Postal_Code
      (
         p_ship_to_loc        IN  HZ_CUST_SITE_USES_ALL.location%Type,
         x_postal_code        OUT WSH_ZONE_REGIONS_V.postal_code_from%Type,
         x_return_status      OUT VARCHAR2,
         x_msg                OUT VARCHAR2
      );


   PROCEDURE Get_Cust_Site_ID
      (
         p_ship_to_loc           IN  HZ_CUST_SITE_USES_ALL.location%Type,
         x_customer_site_id      OUT HZ_CUST_SITE_USES_ALL.site_use_id%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      );

   PROCEDURE Get_Cust_ID
      (
         p_customer_number       IN  MSC_TRADING_PARTNERS.partner_number%Type,
         x_customer_id           OUT MSC_TRADING_PARTNERS.sr_tp_id%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      );


   PROCEDURE Get_Forced_Substitute
      (
         p_inventory_item_id     IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_organization_id       IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         x_xref_item             OUT MTL_CROSS_REFERENCES_V.cross_reference%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      );

  
   PROCEDURE Validate_Parameters
      (
         p_item_ordered          IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered      IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom    IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number       IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc           IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code           IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time     IN  DATE,
         p_timezone_code         IN  HR_LOCATIONS_V.timezone_code%Type,
         p_requested_date        IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type            IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method           IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org         IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_pickup                IN  VARCHAR2,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      );

   PROCEDURE Check_If_ShipMethod_Pickup
      (
         p_ship_method           IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         x_pickup                OUT VARCHAR2,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      );

   PROCEDURE Get_Ship_To_Location
      (
         p_customer_site_id      IN  HZ_CUST_SITE_USES_ALL.site_use_id%Type,
         x_ship_to_loc           OUT HZ_CUST_SITE_USES_ALL.location%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      );

   PROCEDURE Check_If_Order_Bulk
      (
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_item_ordered          IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered      IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_item_val_org_id       In  MTL_PARAMETERS_VIEW.organization_id%Type,
         x_bulk                  OUT VARCHAR2,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      );

END XX_MSC_SOURCING_PARAMS_PKG;
/
