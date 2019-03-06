CREATE OR REPLACE PACKAGE XX_MSC_SOURCING_UTIL_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_UTIL_PKG                                          |
-- | Description: Office Depot - Custom ATP                                    |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1A 21-jun-2007  Roy Gomes        Initial draft version               |
-- |v1.1     01-oct-2007  Roy Gomes        Included procedures for External ATP|
-- |                                                                           |
-- +===========================================================================+


   SR_INSTANCE_ID  CONSTANT  INTEGER := 1;       -- ERP Source instance
   PLAN_ID         CONSTANT  INTEGER := -1;      -- Plan ID
   RESP_ID         CONSTANT  INTEGER := 21634;   -- Advanced Supply Chain Planner
   RESP_APPL_ID    CONSTANT  INTEGER := 724;     -- Advanced Supply Chain Planning

   TYPE char1_arr IS TABLE OF varchar2(1);
   TYPE char10_arr IS TABLE OF varchar2(10);
   TYPE char25_arr IS TABLE OF varchar2(25);
   TYPE char40_arr IS TABLE OF varchar2(40);
   TYPE char150_arr IS TABLE OF varchar2(150);
   TYPE char240_arr IS TABLE OF varchar2(240);
   TYPE number_arr IS TABLE OF number;

   TYPE ATP_Order_Flow_Typ IS RECORD
      (
          atp_flow_name    char150_arr := char150_arr(),
          atp_flow_func    char240_arr := char240_arr(),
          atp_flow_seq     number_arr  := number_arr()
      );

   TYPE ATP_TYPES IS RECORD
      (
          atp_type         char150_arr := char150_arr(),
          atp_seq          number_arr  := number_arr()
      );

   TYPE SR_Orgs_Typ IS RECORD
      (
          org_id           number_arr := number_arr(),
          rank             number_arr := number_arr()
      );

   -- 01-oct-2007 v1.1 Roy Gomes External ATP
   TYPE ext_ssa_typ IS RECORD
      (
          asl_id                   number_arr  := number_arr(),
          using_org_id             number_arr  := number_arr(),
          item_id                  number_arr  := number_arr(),
          vendor_id                number_arr  := number_arr(),
          vendor_site_id           number_arr  := number_arr(),
          vm_indicator             char150_arr := char150_arr(),
          rank                     number_arr  := number_arr(),
          supp_loc_count_ind       char150_arr := char150_arr(),
          inv_type_ind             char150_arr := char150_arr(),
          lead_time                number_arr  := number_arr(),
          drop_ship_cd             char10_arr  := char10_arr(),
          primary_supp_ind         char1_arr   := char1_arr(),
          primary_vendor_item      char25_arr  := char25_arr(),
          legacy_vendor_number     char150_arr := char150_arr(),
          backorders_allowed_flag  char1_arr   := char1_arr(),
          mlss_header_id           number_arr  := number_arr(),
          qty                      number_arr  := number_arr()
       );

   TYPE feed_availability_typ IS RECORD
      (
          vendor_id                number_arr  := number_arr(),
          qty                      number_arr  := number_arr()
      );

   TYPE rt_availability_typ IS RECORD
      (
          org_id                   number_arr  := number_arr(),
          vendor_id                number_arr  := number_arr(),
          vendor_site_id           number_arr  := number_arr(),
          supplier_type            char1_arr   := char1_arr(),
          inventory_item_id        number_arr  := number_arr(),
          primary_vendor_item      char25_arr  := char25_arr(),
          legacy_vendor_number     char150_arr := char150_arr(),
          quantity_ordered         number_arr  := number_arr(),
          supply_loc_no            char10_arr  := char10_arr(),
          rank                     number_arr  := number_arr(),
          end_point                char1_arr   := char1_arr(),
          ds_lt                    number_arr  := number_arr(),
          b2b_lt                   number_arr  := number_arr(),
          supp_loc_ac              number_arr  := number_arr(),
          supp_facility_cd         char40_arr  := char40_arr(), 
          imu_amt_pt               char1_arr   := char1_arr(),
          imu_value                number_arr  := number_arr(),    
          qty                      number_arr  := number_arr(),
          supplier_response_code   char1_arr   := char1_arr()
      );


   PROCEDURE Get_ATP_Order_flow_Types 
      (
         x_flow_types            OUT XX_MSC_Sourcing_Util_Pkg.ATP_Order_Flow_Typ,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2 
      );

   PROCEDURE Get_Assignment_Set
      (
         x_assignment_set_id    OUT MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         x_return_status        OUT VARCHAR2,
         x_msg                  OUT VARCHAR2
      );

   PROCEDURE Get_Item_Validation_Org
      (
         x_item_val_org          OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      );

   PROCEDURE Get_Category_Set_ID
      (
         x_category_set_id OUT MSC_CATEGORY_SETS.category_set_id%Type,
         x_return_status   OUT VARCHAR2,
         x_msg             OUT VARCHAR2
      );

   PROCEDURE Get_Location_From_Org
      (
         p_organization_id       IN  MSC_LOCATION_ASSOCIATIONS.organization_id%Type,
         x_location_id           OUT MSC_LOCATION_ASSOCIATIONS.location_id%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       );

   PROCEDURE Check_If_XDock_Can_Ship_Direct
     (
        p_organization_id         IN  MTL_PARAMETERS_VIEW.organization_id%Type,
        x_ship_from_xdock_org     OUT VARCHAR2,
        x_return_status           OUT VARCHAR2,
        x_msg                     OUT VARCHAR2
     );

   PROCEDURE Get_Customer_Partner_ID
      (
          p_partner_number      IN  MSC_TRADING_PARTNERS.partner_number%Type,
          x_partner_id          OUT MSC_TRADING_PARTNERS.partner_id%Type,
          x_return_status       OUT VARCHAR2,
          x_msg                 OUT VARCHAR2
      );

   PROCEDURE Get_Customer_Number
      (
          p_customer_id         IN  RA_CUSTOMERS.customer_id%Type,
          x_customer_number     OUT RA_CUSTOMERS.customer_number%Type,
          x_return_status       OUT VARCHAR2,
          x_msg                 OUT VARCHAR2
      );

   PROCEDURE Get_Org_From_Location
      (
          p_loc_id              IN  MSC_LOCATION_ASSOCIATIONS.location_id%Type,
          x_org_id              OUT MSC_LOCATION_ASSOCIATIONS.organization_id%Type,
          x_return_status       OUT VARCHAR2,
          x_msg                 OUT VARCHAR2
      );

   PROCEDURE Get_Org_Type
      (
         p_organization_id       IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         x_org_type              OUT HR_ORGANIZATION_UNITS.type%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       );

   PROCEDURE Get_Item_Attributes
     (
        p_inventory_item_id            IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
        p_organization_id              IN  MTL_PARAMETERS_VIEW.organization_id%Type,
        x_item_xdock_sourceable        OUT VARCHAR2,
        x_item_replenishable_type      OUT XX_INV_ITMS_ORG_ATTR_V.od_replen_type_cd%Type,
        x_item_replenishable_subtype   OUT XX_INV_ITMS_ORG_ATTR_V.od_replen_sub_type_cd%Type,
        x_return_status                OUT VARCHAR2,
        x_msg                          OUT VARCHAR2
     );

   PROCEDURE Validate_Operating_Unit
     (
        p_operating_unit        IN  HR_OPERATING_UNITS.organization_id%Type,
        x_return_status         OUT VARCHAR2,
        x_msg                   OUT VARCHAR2
     );

   PROCEDURE Get_Org_Attributes
     (
        p_organization_id                 IN  MTL_PARAMETERS_VIEW.organization_id%Type,
        x_delivery_code                   OUT XX_INV_ORG_LOC_RMS_ATTRIBUTE.od_delivery_cd_sw%Type,
        x_pickup_cutoff                   OUT XX_INV_ORG_LOC_RMS_ATTRIBUTE.pickup_delivery_cutoff_sw%Type,
        x_sameday_cutoff                  OUT XX_INV_ORG_LOC_RMS_ATTRIBUTE.sameday_delivery_sw%Type,
        x_furniture_cutoff                OUT XX_INV_ORG_LOC_RMS_ATTRIBUTE.furniture_cutoff_sw%Type,     
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     );

   PROCEDURE Get_Item_Name
     (
        p_inventory_item_id               IN  MTL_SYSTEM_ITEMS_B.inventory_item_id%Type,
        p_organization_id                 IN  MTL_SYSTEM_ITEMS_B.organization_id%Type,
        x_item                            OUT MTL_SYSTEM_ITEMS_B.segment1%Type,
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     );

   -- v1.1 Roy Gomes - External ATP
   PROCEDURE Get_VM_Indicator
     (
        p_customer_number                 IN  MSC_TRADING_PARTNERS.partner_number%Type,
        x_vm_indicator                    OUT XX_PO_SSA_V.vm_indicator%Type,
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     );

   PROCEDURE Get_IMU_Values
     (
        p_mlss_header_id                  IN  XX_PO_SSA_V.mlss_header_id%Type,
        x_imu_amt_pt                      OUT XX_PO_MLSS_HDR.imu_amt_pt%Type,
        x_imu_value                       OUT XX_PO_MLSS_HDR.imu_value%Type,
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     );

   PROCEDURE Do_IMU_Check
     (
        p_item_id                         IN  XX_PO_SSA_V.item_id%Type,
        p_quantity_ordered                IN  OE_ORDER_LINES_ALL.ordered_quantity%Type,
        p_mlss_header_id                  IN  XX_PO_MLSS_HDR.mlss_header_id%Type,
        p_unit_selling_price              IN  OE_ORDER_LINES_All.unit_selling_price%Type,
        p_vendor_id                       IN  XX_PO_SSA_V.vendor_id%Type,
        p_vendor_site_id                  IN  XX_PO_SSA_V.vendor_site_id%Type,
        p_primary_vendor_id               IN  XX_PO_SSA_V.vendor_id%Type,
        p_primary_vendor_site_id          IN  XX_PO_SSA_V.vendor_site_id%Type,
        p_operating_unit                  IN  HR_OPERATING_UNITS.organization_id%Type,
        x_imu_check                       OUT VARCHAR2,
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     );

   PROCEDURE Get_MLS_Details
     (
        p_mlss_header_id                  IN  XX_PO_SSA_V.mlss_header_id%Type,
        p_end_point                       IN  XX_PO_MLSS_DET.end_point%Type,
        x_supply_loc_no                   OUT XX_PO_MLSS_DET.supply_loc_no%Type,
        x_mlss_ds_lt                      OUT XX_PO_MLSS_DET.ds_lt%Type,
        x_mlss_b2b_lt                     OUT XX_PO_MLSS_DET.b2b_lt%Type,
        x_end_point                       OUT XX_PO_MLSS_DET.end_point%Type,
        x_vendor_facility_code            OUT XX_PO_MLSS_DET.supp_facility_cd%Type,  
        x_vendor_account                  OUT XX_PO_MLSS_DET.supp_loc_ac%Type,
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     );


END XX_MSC_SOURCING_UTIL_PKG;
/
