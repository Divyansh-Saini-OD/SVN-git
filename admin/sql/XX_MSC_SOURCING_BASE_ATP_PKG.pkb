CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_BASE_ATP_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_BASE_ATP_PKG                                      |
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


   PG_DEBUG VARCHAR2(1) := NVL(FND_PROFILE.Value('MSC_ATP_DEBUG'), 'N');

   PROCEDURE Call_ATP
      (
         p_atp_rec                       IN  MRP_ATP_PUB.ATP_Rec_Typ, 
         x_atp_rec                       OUT MRP_ATP_PUB.ATP_Rec_Typ,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
      ) AS


      x_atp_supply_demand             MRP_ATP_PUB.ATP_Supply_Demand_Typ;
      x_atp_period                    MRP_ATP_PUB.ATP_Period_Typ;
      x_atp_details                   MRP_ATP_PUB.ATP_Details_Typ;
      x_msg_data                      VARCHAR2(500);
      x_msg_count                     NUMBER;
      l_error_message                 VARCHAR2(250);
      x_error_message                 VARCHAR2(80);
      i                               NUMBER;
      l_session_id                    NUMBER;

   BEGIN 
      -- Initialize   

      /*
      FND_GLOBAL.Apps_Initialize
         (
             user_id        => FND_GLOBAL.User_ID,   -- MFG User ID
             resp_id        => XX_MSC_SOURCING_UTIL_PKG.RESP_ID,
             resp_appl_id   => XX_MSC_SOURCING_UTIL_PKG.RESP_APPL_ID
         );                          
      */

      l_error_message                        := null;

      
      SELECT OE_ORDER_SCH_UTIL.Get_Session_Id
      INTO   l_session_id
      FROM   dual;
     
      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Calling ATP....');
         MSC_SCH_WB.ATP_Debug('  -> Session ID: '||l_session_id);
      END IF;

      APPS.MRP_ATP_PUB.Call_ATP
         (
            l_session_id,
            p_atp_rec,
            x_atp_rec ,
            x_atp_supply_demand ,
            x_atp_period,
            x_atp_details,
            x_return_status,
            x_msg_data,
            x_msg_count
         );


   EXCEPTION 
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Base_ATP_Pkg.Call_ATP()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Call_Atp;

   PROCEDURE Call_Base_Org_ATP 
      (
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_inventory_item_id        IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_quantity_ordered         IN  OE_ORDER_LINES_ALL.ordered_quantity%Type,
         p_order_quantity_uom       IN  OE_ORDER_LINES_ALL.order_quantity_uom%Type,
         p_requested_date           IN  OE_ORDER_LINES_ALL.schedule_ship_date%Type,
         p_base_org_id              IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_zone_id                  IN  WSH_ZONE_REGIONS_V.zone_id%Type,
         p_ship_method              IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_current_date_time        IN  DATE,
         p_timezone_code            IN  HR_LOCATIONS_V.timezone_code%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2,
         p_operating_unit           IN  HR_OPERATING_UNITS.organization_id%Type,
         p_exclude_org_id           IN  MTL_PARAMETERS_VIEW.organization_id%Type, -- Resourcing
         p_session_id               IN  NUMBER,
         x_source_org_id            OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_requested_date_qty       OUT OE_ORDER_LINES_ALL.ordered_quantity%Type,
         x_ship_date                OUT OE_ORDER_LINES_ALL.schedule_ship_date%Type,
         x_arrival_date             OUT OE_ORDER_LINES_ALL.schedule_ship_date%Type,
         x_ship_method              OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         x_error_code               OUT NUMBER,
         x_return_status            OUT VARCHAR2,
         x_msg                      OUT VARCHAR2
      ) AS

      l_atp_rec                     MRP_ATP_PUB.ATP_Rec_Typ;
      x_atp_rec                     MRP_ATP_PUB.ATP_Rec_Typ;
      l_location_id                 MSC_LOCATION_ASSOCIATIONS.location_id%Type;
      l_today                       DATE := Trunc(Sysdate);
      l_intransit_time              MSC_INTERORG_SHIP_METHODS.intransit_time%Type;
      l_partner_id                  MSC_TRADING_PARTNERS.partner_id%Type;
      l_requested_date              DATE;
      l_session_id                  NUMBER;
      l_item_xdock_sourceable       VARCHAR2(1);   -- ???
      l_item_replenishable_type     XX_INV_ITMS_ORG_ATTR_V.od_replen_type_cd%Type;
      l_item_replenishable_subtype  XX_INV_ITMS_ORG_ATTR_V.od_replen_sub_type_cd%Type;      
      l_item_replenishable          BOOLEAN;

      -- v1.1 10-Jan-2008 Resourcing
      l_calendar_code               MSC_CALENDAR_DATES.calendar_code%Type;
      l_calendar_exists             BOOLEAN;


   BEGIN

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_BASE_ATP_PKG.Call_Base_Org_ATP() ...');
      END IF;


      -- FND_CLIENT_INFO.Set_Org_Context(p_operating_unit);

      -- ====================================================  
      -- IF using 11.5.9 and above, Use MSC_ATP_GLOBAL.Extend_ATP 
      -- API to extend record structure as per standards. This 
      -- will ensure future compatibility.

      MSC_ATP_GLOBAL.Extend_Atp(L_atp_rec,x_return_status,1);

      -- IF using 11.5.8 code, Use MSC_SATP_FUNC.Extend_ATP 
      -- API to avoid any issues with Extending ATP record 
      -- type.
      -- ====================================================  


      l_atp_rec.requested_ship_date(1)       := l_today;
      l_atp_rec.Inventory_Item_Id(1)         := p_inventory_item_id; 
      l_atp_rec.Quantity_Ordered(1)          := p_quantity_ordered;
      l_atp_rec.Quantity_UOM(1)              := p_order_quantity_uom;
      l_atp_rec.ship_method(1)               := p_ship_method;
      l_atp_rec.Action(1)                    := 100;  
      l_atp_rec.Source_Organization_Id(1)    := p_base_org_id;
      l_atp_rec.OE_Flag(1)                   := 'N';
      l_atp_rec.Insert_Flag(1)               := 1; 
      l_atp_rec.Attribute_04(1)              := 1;
      l_atp_rec.override_flag(1)             := 'N';

      -- 10-Jan-2008 v1.1 Resourcing
      IF p_base_org_id != Nvl(p_exclude_org_id, '-1') THEN

         Call_ATP
            (
                p_atp_rec         => l_atp_rec,
                x_atp_rec         => x_atp_rec,
                x_return_status   => x_return_status,
                x_msg             => x_msg
            );

         x_requested_date_qty          := x_atp_rec.Requested_Date_Quantity(1);
         x_error_code                  := x_atp_rec.error_code(1);
         x_ship_date                   := x_atp_rec.ship_date(1);

      ELSE

         x_error_code := 53;

         XX_MSC_SOURCING_DATE_CALC_PKG.Get_Org_Calendar
            (
                p_org_id               => p_base_org_id,  
                p_calendar_type        => 'SHIPPING',
                x_calendar_code        => l_calendar_code,
                x_return_status        => x_return_status,
                x_msg                  => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

         XX_MSC_SOURCING_DATE_CALC_PKG.Get_Next_Calendar_Date
            (
                p_calendar_code        => l_calendar_code,
                p_date                 => Trunc(Sysdate),
                p_days                 => 0,
                x_date                 => x_ship_date,
                x_calendar_exists      => l_calendar_exists,
                x_return_status        => x_return_status,
                x_msg                  => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

         IF NOT l_calendar_exists THEN
            x_return_status := 'E';
            x_msg := 'Unable to find Org Calendar. (ORG ID: '||p_base_org_id||')';
            Return;
         END IF;

      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN

         MSC_SCH_WB.Set_Session_ID(p_session_id);

      END IF;


      -- IF (x_atp_rec.Error_Code(1) <> 0) THEN  -- Resourcing
         IF (x_error_code <> 0) THEN
          SELECT meaning
          INTO   x_msg
          FROM   mfg_lookups
          WHERE  lookup_type = 'MTL_DEMAND_INTERFACE_ERRORS'
          -- AND    lookup_code = x_atp_rec.Error_Code(1); -- Resourcing
          AND lookup_code = x_error_code;
      END IF;

      IF x_error_code IN (0, 53) THEN

         XX_MSC_Sourcing_Util_Pkg.Get_Location_From_Org
            (
               p_organization_id         => p_base_org_id,
               x_location_id             => l_location_id,
               x_return_status           => x_return_status,
               x_msg                     => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

         IF p_pickup = 'Y' THEN

            XX_MSC_Sourcing_Date_Calc_Pkg.Get_Pickup_Date
               (
                   p_ship_from_loc_id      => l_location_id,
                   p_ship_from_org_id      => p_base_org_id,
                   p_category_name         => p_category_name,
                   p_pickup                => p_pickup,
                   p_current_date_time     => p_current_date_time,
                   p_timezone_code         => p_timezone_code,
                   x_ship_date             => x_ship_date,
                   x_return_status         => x_return_status,
                   x_msg                   => x_msg
               );


            IF x_return_status <> 'S' THEN
               Return;
            END IF;

            IF Trunc(p_requested_date) < Trunc(x_ship_date) THEN

               x_error_code := 53;
               x_arrival_date := x_ship_date;

            ELSIF Trunc(p_requested_date) = Trunc(x_ship_date) THEN

               x_arrival_date := x_ship_date;

            ELSIF Trunc(p_requested_date) > Trunc(x_ship_date) THEN
 
               x_ship_date := Trunc(p_requested_date);
         
               XX_MSC_Sourcing_Date_Calc_Pkg.Get_Future_Pickup_Date
                  (
                     p_ship_from_org_id    => p_base_org_id,
                     x_ship_date           => x_ship_date,
                     x_return_status       => x_return_status,
                     x_msg                 => x_msg
                  );

               IF x_return_status <> 'S' THEN
                  Return;
               END IF;

               x_arrival_date := x_ship_date;

               
            END IF;

            x_ship_method := p_ship_method;

         ELSE


            XX_MSC_Sourcing_Date_Calc_Pkg.Get_Zone_Arrival_Date
               (
                  p_partner_number           => p_customer_number,
                  p_ship_from_loc_id         => l_location_id, 
                  p_ship_from_org_id         => p_base_org_id, 
                  p_ship_method              => p_ship_method,
                  p_category_name            => p_category_name,
                  p_order_type               => p_order_type,
                  p_ship_to_region_id        => p_zone_id,
                  p_current_date_time        => p_current_date_time,
                  p_timezone_code            => p_timezone_code,
                  p_pickup                   => p_pickup,
                  p_bulk                     => p_bulk,
                  x_ship_date                => x_ship_date,
                  x_arrival_date             => x_arrival_date,
                  x_intransit_time           => l_intransit_time,
                  x_ship_method              => x_ship_method,
                  x_partner_id               => l_partner_id,
                  x_return_status            => x_return_status,
                  x_msg                      => x_msg
              );

            IF x_return_status <> 'S' THEN
               Return;
            END IF;

            -- dbms_output.put_line('Requested Date: '||Trunc(p_requested_date));
            -- dbms_output.Put_line('  -> Ship Method: '||x_ship_method);

            IF Trunc(p_requested_date) < Trunc(x_arrival_date) THEN

               x_error_code := 53;
      
            ELSIF Trunc(p_requested_date) > Trunc(x_arrival_date) THEN

               l_requested_date := p_requested_date;

               XX_MSC_Sourcing_Date_Calc_Pkg.Get_Org_Ship_Date
                  (
                     p_partner_number           => p_customer_number,
                     p_partner_id               => l_partner_id,
                     p_ship_from_org_id         => p_base_org_id,
                     p_ship_method              => x_ship_method,
                     p_intransit_time           => l_intransit_time,
                     x_requested_date           => l_requested_date,
                     x_ship_date                => x_ship_date,
                     x_return_status            => x_return_status,
                     x_msg                      => x_msg
                  );


               IF x_return_status <> 'S' THEN
                  Return;
               END IF;

               x_arrival_date := l_requested_date;

            END IF;

       
         END IF; -- p_pickup

      ELSE
         x_ship_date := Null;
         x_arrival_date := Null;
         x_ship_method := Null;
         Return;
      END IF;

      x_source_org_id := p_base_org_id;

      XX_MSC_Sourcing_Util_Pkg.Get_Item_Attributes
         (
             p_inventory_item_id           => p_inventory_item_id,
             p_organization_id             => p_base_org_id,
             x_item_xdock_sourceable       => l_item_xdock_sourceable,
             x_item_replenishable_type     => l_item_replenishable_type,
             x_item_replenishable_subtype  => l_item_replenishable_subtype,  
             x_return_status               => x_return_status,
             x_msg                         => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      l_item_replenishable := XX_OM_DMDEXTLEG_PKG.Is_Replenished
                                 (
                                    p_replen_type     => l_item_replenishable_type,
                                    p_replen_subtype  => l_item_replenishable_subtype
                                 );

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Item Replenishable Type: '|| l_item_replenishable_type);
         MSC_SCH_WB.ATP_Debug('  -> Item Replenishable Sub Type: '|| l_item_replenishable_subtype);
         IF (l_item_replenishable) THEN
            MSC_SCH_WB.ATP_Debug('  -> Item Replenishable');
         ELSE
            MSC_SCH_WB.ATP_Debug('  -> Item Not Replenishable');
         END IF;
      END IF;

      /*      
      dbms_output.put_line('  -> Item Replenishable Type: '|| l_item_replenishable_type);
      dbms_output.put_line('  -> Item Replenishable Sub Type: '|| l_item_replenishable_subtype);
      IF (l_item_replenishable) THEN
         dbms_output.put_line('  -> Item Replenishable');
      ELSE
         dbms_output.put_line('  -> Item Not Replenishable');
      END IF;
      */
     
      IF x_error_code = 53 AND NOT (l_item_replenishable) THEN
         x_source_org_id := Null;
         x_requested_date_qty := Null;
         x_ship_date := Null;
         x_arrival_date := Null;
         x_ship_method := Null;
      END IF;

      IF x_msg IS Null AND x_error_code = 53 THEN
         SELECT meaning
         INTO   x_msg
         FROM   mfg_lookups
         WHERE  lookup_type = 'MTL_DEMAND_INTERFACE_ERRORS'
         AND    lookup_code = 53;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Source Org ID: '|| x_source_org_id);
         MSC_SCH_WB.ATP_Debug('  -> Requested Date Qty: '||x_requested_date_qty);
         MSC_SCH_WB.ATP_Debug('  -> Ship Date: '||x_ship_date);
         MSC_SCH_WB.ATP_Debug('  -> Arrival Date: '||x_arrival_date);
         MSC_SCH_WB.ATP_Debug('  -> Ship Method: '||x_ship_method);
         MSC_SCH_WB.ATP_Debug('  -> Error Code: '||x_error_code);
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_BASE_ATP_PKG.Call_Base_Org_ATP ...');
      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Base_ATP_Pkg.Call_Base_Org_ATP()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Call_Base_Org_ATP;

   PROCEDURE Base_Org_ATP 
      (
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_inventory_item_id        IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_quantity_ordered         IN  OE_ORDER_LINES_ALL.ordered_quantity%Type,
         p_order_quantity_uom       IN  OE_ORDER_LINES_ALL.order_quantity_uom%Type,
         p_requested_date           IN  OE_ORDER_LINES_ALL.schedule_ship_date%Type,
         p_base_org_id              IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_zone_id                  IN  WSH_ZONE_REGIONS_V.zone_id%Type,
         p_ship_method              IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_current_date_time        IN  DATE,
         p_timezone_code            IN  HR_LOCATIONS_V.timezone_code%Type,
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
         x_error_code               OUT NUMBER,
         x_return_status            OUT VARCHAR2,
         x_msg                      OUT VARCHAR2
      ) AS

      l_session_id NUMBER;

   BEGIN

      /*
      dbms_output.put_line('  ============================================================');
      dbms_output.put_line('  ->               INPUT PARAMETERS                           ');
      dbms_output.put_line('  ============================================================');
      dbms_output.put_line('  -> Customer Number            : '||p_customer_number);
      dbms_output.put_line('  -> Inventory Item ID          : '||p_inventory_item_id);
      dbms_output.put_line('  -> Category                   : '||p_category_name);
      dbms_output.put_line('  -> Requested Qty              : '||p_quantity_ordered);
      dbms_output.put_line('  -> Requested Qty UOM          : '||p_order_quantity_uom);
      dbms_output.put_line('  -> Requested Date             : '||p_requested_date);
      dbms_output.put_line('  -> Base Org ID                : '||p_base_org_id);
      dbms_output.put_line('  -> Zone ID                    : '||p_zone_id);
      dbms_output.put_line('  -> Ship Method                : '||p_ship_method);
      dbms_output.put_line('  -> Order Type                 : '||p_order_type);
      dbms_output.put_line('  -> Inquiry Date Time          : '||to_char(p_current_date_time, 'DD-Mon-YYYY HH24:MI:SS'));
      dbms_output.put_line('  -> Inquiry Timezone           : '||p_timezone_code);
      dbms_output.put_line('  -> Pickup                     : '||p_pickup);
      dbms_output.put_line('  -> Bulk                       : '||p_bulk);
      dbms_output.put_line('  -> Operating Unit             : '||p_operating_unit);
      dbms_output.put_line('  -> Session ID                 : '||p_session_id);
      dbms_output.put_line('  ============================================================');
      */
      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_BASE_ATP_PKG.Base_Org_ATP() ...');
         MSC_SCH_WB.ATP_Debug('  ============================================================');
         MSC_SCH_WB.ATP_Debug('  ->               INPUT PARAMETERS                           ');
         MSC_SCH_WB.ATP_Debug('  ============================================================');
         MSC_SCH_WB.ATP_Debug('  -> Customer Number            : '||p_customer_number);
         MSC_SCH_WB.ATP_Debug('  -> Inventory Item ID          : '||p_inventory_item_id);
         MSC_SCH_WB.ATP_Debug('  -> Category                   : '||p_category_name);
         MSC_SCH_WB.ATP_Debug('  -> Requested Qty              : '||p_quantity_ordered);
         MSC_SCH_WB.ATP_Debug('  -> Requested Qty UOM          : '||p_order_quantity_uom);
         MSC_SCH_WB.ATP_Debug('  -> Requested Date             : '||p_requested_date);
         MSC_SCH_WB.ATP_Debug('  -> Base Org ID                : '||p_base_org_id);
         MSC_SCH_WB.ATP_Debug('  -> Zone ID                    : '||p_zone_id);
         MSC_SCH_WB.ATP_Debug('  -> Ship Method                : '||p_ship_method);
         MSC_SCH_WB.ATP_Debug('  -> Order Type                 : '||p_order_type);
         MSC_SCH_WB.ATP_Debug('  -> Inquiry Date Time          : '||to_char(p_current_date_time, 'DD-Mon-YYYY HH24:MI:SS'));
         MSC_SCH_WB.ATP_Debug('  -> Inquiry Timezone           : '||p_timezone_code);
         MSC_SCH_WB.ATP_Debug('  -> Pickup                     : '||p_pickup);
         MSC_SCH_WB.ATP_Debug('  -> Bulk                       : '||p_bulk);
         MSC_SCH_WB.ATP_Debug('  -> Operating Unit             : '||p_operating_unit);
         MSC_SCH_WB.ATP_Debug('  -> Excluded Organization ID   : '||p_exclude_org_id);
         MSC_SCH_WB.ATP_Debug('  -> Session ID                 : '||p_session_id);
         MSC_SCH_WB.ATP_Debug('  ============================================================');
      END IF;

      Call_Base_Org_ATP 
         (
            p_customer_number          => p_customer_number,
            p_inventory_item_id        => p_inventory_item_id,
            p_category_name            => p_category_name,
            p_quantity_ordered         => p_quantity_ordered,
            p_order_quantity_uom       => p_order_quantity_uom,
            p_requested_date           => p_requested_date,
            p_base_org_id              => p_base_org_id,
            p_zone_id                  => p_zone_id,
            p_ship_method              => p_ship_method,
            p_order_type               => p_order_type,
            p_current_date_time        => p_current_date_time,
            p_timezone_code            => p_timezone_code,
            p_pickup                   => p_pickup,
            p_bulk                     => p_bulk,
            p_operating_unit           => p_operating_unit,
            p_exclude_org_id           => p_exclude_org_id,  -- Resourcing
            p_session_id               => p_session_id,
            x_source_org_id            => x_source_org_id,
            x_requested_date_qty       => x_requested_date_qty,
            x_ship_date                => x_ship_date,
            x_arrival_date             => x_arrival_date,
            x_ship_method              => x_ship_method,
            x_error_code               => x_error_code,
            x_return_status            => x_return_status,
            x_msg                      => x_msg
         );


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Return Status: '||x_return_status);
         MSC_SCH_WB.ATP_Debug('  -> Message: '||x_msg);
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_BASE_ATP_PKG.Base_Org_ATP() ...');
      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Base_ATP_Pkg.Base_Org_ATP()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Base_Org_ATP;


END XX_MSC_SOURCING_BASE_ATP_PKG;
/
