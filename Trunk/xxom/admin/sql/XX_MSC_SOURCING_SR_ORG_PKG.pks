CREATE OR REPLACE PACKAGE XX_MSC_SOURCING_SR_ORG_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_SR_ORG_PKG                                        |
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

   PROCEDURE Get_Base_Org
      (
         p_customer_number       IN  RA_CUSTOMERS.customer_number%Type,
         p_item                  IN  MTL_SYSTEM_ITEMS_B.segment1%Type,
         p_ship_to_loc           IN  HZ_CUST_SITE_USES_ALL.location%Type,
         p_postal_code           IN  HZ_LOCATIONS.postal_code%Type,
         p_ship_from_org         IN  MTL_PARAMETERS_VIEW.organization_code%Type,
         p_cust_setup_org        IN  MTL_PARAMETERS_VIEW.organization_code%Type,
         p_assignment_set_id     IN  MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         p_item_val_org          IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_category_set_id       IN  MSC_CATEGORY_SETS.category_set_id%Type,
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         x_base_org              OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      );

   PROCEDURE Get_Base_Org_From_SR
      (
         p_postal_code           IN  HZ_LOCATIONS.postal_code%Type,
         p_item                  IN  MTL_SYSTEM_ITEMS_B.segment1%Type,
         p_assignment_set_id     IN  MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         p_item_val_org          IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_category_set_id       IN  MSC_CATEGORY_SETS.category_set_id%Type,
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         x_base_org              OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       );

   PROCEDURE Get_Base_Org_From_SR
      (
         p_ship_to_loc           IN  HZ_CUST_SITE_USES_ALL.location%Type,
         p_item                  IN  MTL_SYSTEM_ITEMS_B.segment1%Type,
         p_assignment_set_id     IN  MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         p_item_val_org          IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_category_set_id       IN  MSC_CATEGORY_SETS.category_set_id%Type,
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         x_base_org              OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       );

   PROCEDURE Get_Orgs_From_SR
      (
         p_ship_to_loc           IN  HZ_CUST_SITE_USES_ALL.location%Type,
         p_assignment_set_id     IN  MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         p_item_val_org          IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_category_set_id       IN  MSC_CATEGORY_SETS.category_set_id%Type,
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_xdock_only            IN  VARCHAR2,
         p_exclude_org_id        IN  MTL_PARAMETERS_VIEW.organization_id%Type,  -- Resourcing
         x_sr_orgs               OUT XX_MSC_Sourcing_Util_Pkg.SR_Orgs_Typ,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       );

   PROCEDURE Get_Orgs_From_SR
      (
         p_postal_code           IN  HZ_LOCATIONS.postal_code%Type,
         p_assignment_set_id     IN  MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         p_item_val_org          IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_category_set_id       IN  MSC_CATEGORY_SETS.category_set_id%Type,
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_xdock_only            IN  VARCHAR2,
         p_exclude_org_id        IN  MTL_PARAMETERS_VIEW.organization_id%Type,  -- Resourcing
         x_sr_orgs               OUT XX_MSC_Sourcing_Util_Pkg.SR_Orgs_Typ,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       );


END XX_MSC_SOURCING_SR_ORG_PKG;
/
