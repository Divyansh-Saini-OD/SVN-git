CREATE OR REPLACE PACKAGE XX_MSC_SOURCING_PREPROCESS_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_PREPROCESS_PKG                                    |
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



   PROCEDURE ATP_Pre_Process
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_timezone_code            IN  HR_LOCATIONS_V.timezone_code%Type,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_operating_unit           IN  HR_OPERATING_UNITS.organization_id%Type,
         p_session_id               IN  NUMBER,
         x_base_org                 OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_base_org_id              OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_sr_item_id               OUT MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         x_order_flow_type          OUT FND_FLEX_VALUES_VL.flex_value%Type,
         x_atp_types                OUT XX_MSC_Sourcing_Util_Pkg.ATP_TYpes,
         x_assignment_set_id        OUT MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         x_item_val_org             OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_category_set_id          OUT MSC_CATEGORY_SETS.category_set_id%Type,
         x_category_name            OUT MSC_ITEM_CATEGORIES.category_name%Type,
         x_zone_id                  OUT WSH_ZONE_REGIONS_V.zone_id%Type,
         x_xref_item                OUT MTL_CROSS_REFERENCES_V.cross_reference%Type,
         x_xref_sr_item_id          OUT MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         x_pickup                   OUT VARCHAR2,
         x_bulk                     OUT VARCHAR2,
         x_return_status            OUT VARCHAR2,
         x_msg                      OUT VARCHAR2
      );

END XX_MSC_SOURCING_PREPROCESS_PKG;
/
