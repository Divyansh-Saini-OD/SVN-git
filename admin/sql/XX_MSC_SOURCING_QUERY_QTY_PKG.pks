CREATE OR REPLACE PACKAGE XX_MSC_SOURCING_QUERY_QTY_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_QUERY_QTY_PKG                                     |
-- | Description: Office Depot - Custom ATP                                    |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |v1.0     26-nov-2007  Roy Gomes        Initial draft version               |
-- |                                                                           |
-- +===========================================================================+



   PROCEDURE Query_Qty
      (
         p_item_ordered             IN  MTL_SYSTEM_ITEMS_B.segment1%Type,
         p_ship_to_loc              IN  HZ_CUST_SITE_USES_ALL.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_operating_unit           IN  HR_OPERATING_UNITS.organization_id%Type,
         p_aops_source_type_id      IN  MTL_TXN_SOURCE_TYPES.transaction_source_type_id%Type,
         x_source_org_id            OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_source_org               OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_qty                      OUT NUMBER,
         x_return_status            OUT VARCHAR2,
         x_msg                      OUT VARCHAR2
      );

END XX_MSC_SOURCING_QUERY_QTY_PKG;
/
