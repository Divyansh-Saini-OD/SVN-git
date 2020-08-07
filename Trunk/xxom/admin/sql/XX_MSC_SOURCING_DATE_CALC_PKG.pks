CREATE OR REPLACE PACKAGE XX_MSC_SOURCING_DATE_CALC_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_DATE_CALC_PKG                                     |
-- | Description: Office Depot - Custom ATP                                    |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1A 21-jun-2007  Roy Gomes        Initial draft version               |
-- |V 1.1    22-aug-2007  Roy Gomes        Added functions for                 |
-- |                                       Is_Carrier_Calendar_Open() &        |
-- |                                       Is_Customer_Calendar_Open() for     |
-- |                                       Appointment Scheduling              |
-- |v1.2     01-oct-2007  Roy Gomes        Included procedures for External ATP|
-- |v1.3     10-Jan-2008  Roy Gomes        Resourcing                          |
-- |                                                                           |
-- +===========================================================================+

   PROCEDURE Get_Zone_Arrival_Date
      (
         p_partner_number                IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_from_loc_id              IN  MTL_INTERORG_SHIP_METHODS.from_location_id%Type, 
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_ship_method                   IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_category_name                 IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_order_type                    IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_to_region_id             IN  MTL_INTERORG_SHIP_METHODS.to_region_id%Type,
         p_current_date_time             IN  DATE,
         p_timezone_code                 IN  HR_LOCATIONS_V.timezone_code%Type,
         p_pickup                        IN  VARCHAR2,
         p_bulk                          IN  VARCHAR2,
         x_ship_date                     IN OUT DATE,
         x_arrival_date                  OUT DATE,
         x_intransit_time                OUT MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         x_ship_method                   OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         x_partner_id                    OUT MSC_TRADING_PARTNERS.partner_id%Type,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
      );


   PROCEDURE Get_Org_Ship_Date
      (
         p_partner_number                IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_partner_id                    IN  MSC_TRADING_PARTNERS.partner_id%Type,
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type, 
         p_ship_method                   IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_intransit_time                IN  MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         x_requested_date                IN OUT DATE,
         x_ship_date                     OUT DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
      );

   PROCEDURE Get_Zone_Arrival_Date
      (
         p_partner_number                IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_from_loc_id              IN  MTL_INTERORG_SHIP_METHODS.from_location_id%Type,
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_base_org_id                   IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_base_loc_id                   IN  MTL_INTERORG_SHIP_METHODS.from_location_id%Type, 
         p_ship_method                   IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_category_name                 IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_order_type                    IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_to_region_id             IN  MTL_INTERORG_SHIP_METHODS.to_region_id%Type,
         p_current_date_time             IN  DATE,
         p_timezone_code                 IN  HR_LOCATIONS_V.timezone_code%Type,
         p_pickup                        IN  VARCHAR2,
         p_bulk                          IN  VARCHAR2,
         x_ship_date                     IN OUT DATE,
         x_arrival_date                  OUT DATE,
         x_intransit_time_1              OUT MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         x_ship_method_1                 OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         x_intransit_time_2              OUT MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         x_ship_method_2                 OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         x_partner_id                    OUT MSC_TRADING_PARTNERS.partner_id%Type,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
      );

   PROCEDURE Get_XDock_Ship_Date
      (
         p_partner_number                IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_partner_id                    IN  MSC_TRADING_PARTNERS.partner_id%Type,
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_base_org_id                   IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_ship_method_1                 IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_intransit_time_1              IN  MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         p_ship_method_2                 IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_intransit_time_2              IN  MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         x_requested_date                IN OUT DATE,
         x_ship_date                     OUT DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
      );


   PROCEDURE Get_Pickup_Date
     (
         p_ship_from_loc_id              IN  MTL_INTERORG_SHIP_METHODS.from_location_id%Type,
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_category_name                 IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_pickup                        IN  VARCHAR2,
         p_current_date_time             IN  DATE,
         p_timezone_code                 IN  HR_LOCATIONS_V.timezone_code%Type,
         x_ship_date                     IN OUT DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
     );

   PROCEDURE Get_Future_Pickup_Date
     (
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         x_ship_date                     IN OUT DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
     );

   PROCEDURE Get_Schedule_Arrival_Date
     (
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_customer_site_id              IN  HZ_CUST_SITE_USES_ALL.site_use_id%Type,
         p_sr_item_id                    IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_ship_method                   IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_customer_id                   IN  RA_CUSTOMERS.customer_id%Type,
         p_ship_date                     IN  DATE,
         x_arrival_date                  OUT DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
     );

   -- 22-Aug-2007 v1.1 New function for appointment scheduling
   FUNCTION Is_Carrier_Calendar_Open
     (
         p_ship_method                   IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_date                          IN  DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
     ) RETURN BOOLEAN;

   -- 22-Aug-2007 v1.1 New function for appointment scheduling
   FUNCTION Is_Customer_Calendar_Open
     (
         p_partner_number                IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_calendar_usage                IN  VARCHAR2,	
         p_date                          IN  DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
     ) RETURN BOOLEAN;

   -- 01-Oct-2007 v1.2 New procedures for External ATP
   PROCEDURE Get_External_ATP_Dates
      (
          p_customer_number              IN  MSC_TRADING_PARTNERS.partner_number%Type,
          p_ship_method                  IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
          p_category_name                IN  MSC_ITEM_CATEGORIES.category_name%Type,
          p_bulk                         IN  VARCHAR2,
          p_zone_id                      IN  WSH_ZONE_REGIONS_V.zone_id%Type,
          p_base_org_id                  IN  MTL_PARAMETERS_VIEW.organization_id%Type,
          p_drop_ship_cd                 IN  XX_PO_SSA_V.drop_ship_cd%Type,
          p_supply_type                  IN  XX_PO_SSA_V.supp_loc_count_ind%Type,
          p_ssa_lead_time                IN  XX_PO_SSA_V.lead_time%Type,
          p_supply_loc_no                IN  XX_PO_MLSS_DET.supply_loc_no%Type,
          p_vendor_id                    IN  XX_PO_SSA_V.vendor_id%Type,
          p_vendor_site_id               IN  XX_PO_SSA_V.vendor_site_id%Type,
          p_mlss_ds_lt                   IN  XX_PO_MLSS_DET.ds_lt%Type,
          p_mlss_b2b_lt                  IN  XX_PO_MLSS_DET.b2b_lt%Type,
          p_current_date_time            IN  DATE,
          p_timezone_code                IN  HR_LOCATIONS_V.timezone_code%Type,
          p_mlss_cutoff_time             IN  VARCHAR2,
          x_ship_date                    OUT DATE,
          x_arrival_date                 OUT DATE,
          x_ship_method                  OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
          x_return_status                OUT VARCHAR2,
          x_msg                          OUT VARCHAR2
       );

   -- 10-Jan-2008 v1.3 Resourcing
   PROCEDURE Get_Org_Calendar
      (
          p_org_id                       IN  MTL_PARAMETERS_VIEW.organization_id%Type,  
          p_calendar_type                IN  VARCHAR2,
          x_calendar_code                OUT MSC_CALENDAR_ASSIGNMENTS.calendar_code%Type,
          x_return_status                OUT VARCHAR2,
          x_msg                          OUT VARCHAR2
      );

   -- 10-Jan-2008 v1.3 Resourcing
   PROCEDURE Get_Next_Calendar_Date
      (
          p_calendar_code                IN  MSC_CALENDAR_DATES.calendar_code%Type,
          p_date                         IN  DATE,
          p_days                         IN  NUMBER,
          x_date                         OUT DATE,
          x_calendar_exists              OUT BOOLEAN,
          x_return_status                OUT VARCHAR2,
          x_msg                          OUT VARCHAR2
      );

END XX_MSC_SOURCING_DATE_CALC_PKG;
/
