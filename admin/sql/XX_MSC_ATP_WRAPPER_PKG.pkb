create or replace
Package  Body                XX_MSC_ATP_WRAPPER_PKG as 
/* -------------------------------------------------------------------------- */
/*  Program Name : XX_MSC_ATP_WRAPPER_PKG                                     */
/*                                                                            */
/*  TYPE         : PL/SQL Package Specs.                                      */
/*                                                                            */
/*  AUTHOR       : Satish Mani                                                */
/*                                                                            */
/*  DATE         : 22-JUN-2007                                                */
/*                                                                            */
/*  VERSION      : 1.0                                                        */
/*                                                                            */
/*  DESCRIPTION	 : Office Depot - Custom ATP                                */
/*                                                                            */
/*  CHANGE HISTORY                                                            */
/* -------------------------------------------------------------------------- */
/* DATE        AUTHOR       VERSION REASON                                    */
/* -------------------------------------------------------------------------- */
/* 22-JUN-2007 Satish Mani 1.0     Initial creation                           */
/*                                                                            */
/* -------------------------------------------------------------------------- */
PROCEDURE Call_ATP_Pre_Process
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
         x_base_org                 OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_base_org_id              OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_sr_item_id               OUT MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         x_order_flow_type          OUT FND_FLEX_VALUES_VL.flex_value%Type,
         x_atp_type		    OUT XX_MSC_ATP_WRAPPER_PKG.CHAR_ARRAY,
         x_atp_seq		    OUT XX_MSC_ATP_WRAPPER_PKG.NUMBER_ARRAY,
         x_assignment_set_id        OUT MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         x_item_val_org             OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_category_set_id          OUT MSC_CATEGORY_SETS.category_set_id%Type,
         x_category_name            OUT MSC_ITEM_CATEGORIES.category_name%Type,
         x_zone_id                  OUT WSH_ZONE_REGIONS_V.zone_id%Type,
         x_xref_item                OUT MTL_CROSS_REFERENCES_V.cross_reference%Type,
         x_xref_sr_item_id          OUT MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         x_pickup                   OUT VARCHAR2,
         x_session_id               OUT NUMBER,
         x_return_status            OUT VARCHAR2,
         x_msg                      OUT VARCHAR2
      )

AS

l_atp_code char_array;
l_atp_seq number_array;
   
x_atp_types  XX_MSC_Sourcing_Util_Pkg.ATP_TYpes;


BEGIN

XX_MSC_Sourcing_Preprocess_Pkg.ATP_Pre_Process
      (
         p_item_ordered,
         p_quantity_ordered,
         p_order_quantity_uom,
         p_customer_number,
         p_ship_to_loc ,
         p_postal_code,
         p_current_date_time ,
         p_timezone_code,
         p_requested_date,
         p_order_type,
         p_ship_method ,
         p_ship_from_org ,
         p_operating_unit,
         x_base_org ,
         x_base_org_id  ,
         x_sr_item_id,
         x_order_flow_type,
         x_atp_types ,
         x_assignment_set_id ,
         x_item_val_org  ,
         x_category_set_id  ,
         x_category_name ,
         x_zone_id ,
         x_xref_item ,
         x_xref_sr_item_id,
         x_pickup,
         x_session_id,
         x_return_status,
         x_msg 
      );
      
for i IN 1..x_atp_types.atp_type.count LOOP
	l_atp_code(i) := x_atp_types.atp_type(i);
	l_atp_seq(i) := x_atp_types.atp_seq(i);
END Loop;

x_atp_type := l_atp_code;
x_atp_seq := l_atp_seq;


END Call_ATP_Pre_Process;

END  XX_MSC_ATP_WRAPPER_PKG;
