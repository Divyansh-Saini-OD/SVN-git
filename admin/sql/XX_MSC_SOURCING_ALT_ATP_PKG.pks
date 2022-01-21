CREATE OR REPLACE PACKAGE XX_MSC_SOURCING_ALT_ATP_PKG AS


-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_ALT_ATP_PKG                                       |
-- | Description: Office Depot - Custom ATP                                    |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1A 21-jun-2007  Roy Gomes        Initial draft version               |
-- |v1.1     10-Jan-2008  Roy Gomes        Resourcing                          |
-- |                                                                           |
-- +===========================================================================+

   PROCEDURE Alt_Org_ATP
      (
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_inventory_item_id        IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_quantity_ordered         IN  OE_ORDER_LINES_ALL.ordered_quantity%Type,
         p_order_quantity_uom       IN  OE_ORDER_LINES_ALL.order_quantity_uom%Type,
         p_requested_date           IN  OE_ORDER_LINES_ALL.schedule_ship_date%Type,
         p_ship_to_loc              IN  HZ_CUST_SITE_USES_ALL.location%Type, 
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_ship_method              IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_assignment_set_id        IN  MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         p_item_val_org             IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_category_set_id          IN  MSC_CATEGORY_SETS.category_set_id%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_zone_id                  IN  WSH_ZONE_REGIONS_V.zone_id%Type,
         p_current_date_time        IN  DATE,
         p_timezone_code            IN  HR_LOCATIONS_V.timezone_code%Type,
         p_base_org_id              IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_xdock_only               IN  VARCHAR2,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2,
         p_operating_unit           IN  HR_OPERATING_UNITS.organization_id%Type,
         p_exclude_org_id           IN  MTL_PARAMETERS_VIEW.organization_id%Type,  -- Resourcing
         p_session_id               IN  NUMBER,
         x_source_org_id            OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_requested_date_qty       OUT OE_ORDER_LINES_ALL.ordered_quantity%Type,
         x_ship_date                OUT OE_ORDER_LINES_ALL.schedule_ship_date%Type,
         x_arrival_date             OUT OE_ORDER_LINES_ALL.schedule_ship_date%Type,
         x_ship_method              OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         x_tcsc_org_id              OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_error_code               OUT NUMBER,
         x_return_status            OUT VARCHAR2,
         x_msg                      OUT VARCHAR2
      ) ;

END XX_MSC_SOURCING_ALT_ATP_PKG;
/
