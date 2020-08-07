CREATE OR REPLACE PACKAGE XX_MSC_SOURCING_CUSTOM_ATP_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_CUSTOM_ATP_PKG                                    |
-- | Description: Office Depot - Custom ATP                                    |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1A 21-jun-2007  Roy Gomes        Initial draft version               |
-- |v1.1     01-oct-2007  Roy Gomes        Included changes for External ATP   |
-- |v1.2     10-Jan-2008  Roy Gomes        Resourcing                          |
-- |                                                                           |
-- +===========================================================================+



   PROCEDURE Call_ATP
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_unit_selling_price       IN  OE_ORDER_LINES_ALL.unit_selling_price%Type,
         p_drop_ship_code           IN  XX_PO_SSA_V.drop_ship_cd%Type,
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
         p_user_id                  IN  FND_USER.user_id%Type,
         p_exclude_vendor_site_id   IN  PO_VENDOR_SITES.vendor_site_id%Type,  -- Resourcing
         p_exclude_org_id           IN  MTL_PARAMETERS_VIEW.organization_id%Type, -- Resourcing
         x_source_org_id            OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_substitute_item_id       OUT MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         x_future_order             OUT VARCHAR2,
         x_requested_date_qty       OUT NUMBER,
         x_ship_date                OUT DATE,
         x_arrival_date             OUT DATE,
         x_ship_method              OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         x_tcsc_org_id              OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_vendor_id                OUT PO_VENDORS.vendor_id%Type,
         x_vendor_site_id           OUT PO_VENDOR_SITES.vendor_site_id%Type,
         x_vendor_type              OUT XX_PO_SSA_V.supp_loc_count_ind%Type,
         x_vendor_facility_code     OUT XX_PO_MLSS_DET.supp_facility_cd%Type,
         x_vendor_account           OUT XX_PO_MLSS_DET.supp_loc_ac%Type,
         x_drop_ship_code           OUT XX_PO_SSA_V.drop_ship_cd%Type,
         x_session_id               OUT NUMBER,
         x_error_code               OUT NUMBER,
         x_return_status            OUT VARCHAR2,
         x_msg                      OUT VARCHAR2
      );

END XX_MSC_SOURCING_CUSTOM_ATP_PKG;
/
