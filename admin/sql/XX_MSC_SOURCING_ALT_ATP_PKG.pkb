 CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_ALT_ATP_PKG AS


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
      l_session_id                    NUMBER;
      l_error_message                 VARCHAR2(250);
      x_error_message                 VARCHAR2(80);
      i                               NUMBER;

   BEGIN 
      -- Initialize   

      /*
      FND_GLOBAL.Apps_Initialize
         (
             user_id        => FND_GLOBAL.User_ID,
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
         x_msg := 'Error: XX_MSC_Sourcing_XDock_ATP_Pkg.Call_ATP()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Call_Atp;

   PROCEDURE Call_Alt_Org_ATP 
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
         p_exclude_org_id           IN  MTL_PARAMETERS_VIEW.organization_id%Type, -- Resourcing
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
      ) AS

      l_atp_rec                     MRP_ATP_PUB.ATP_Rec_Typ;
      x_atp_rec                     MRP_ATP_PUB.ATP_Rec_Typ;
      l_inventory_item_id           MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type;
      l_org_id                      MTL_PARAMETERS_VIEW.organization_id%Type;
      l_sr_orgs                     XX_MSC_Sourcing_Util_Pkg.SR_Orgs_Typ;
      l_location_id                 MSC_LOCATION_ASSOCIATIONS.location_id%Type;
      l_base_loc_id                 MSC_LOCATION_ASSOCIATIONS.location_id%Type;
      l_today                       DATE := Trunc(Sysdate);
      l_intransit_time              MSC_INTERORG_SHIP_METHODS.intransit_time%Type;
      l_ship_method                 MTL_INTERORG_SHIP_METHODS.ship_method%Type;
      l_intransit_time_1            MSC_INTERORG_SHIP_METHODS.intransit_time%Type;
      l_ship_method_1               MTL_INTERORG_SHIP_METHODS.ship_method%Type;
      l_intransit_time_2            MSC_INTERORG_SHIP_METHODS.intransit_time%Type;
      l_ship_method_2               MTL_INTERORG_SHIP_METHODS.ship_method%Type;
      l_partner_id                  MSC_TRADING_PARTNERS.partner_id%Type;
      l_requested_date              DATE;
      l_ship_direct_from_xdock      VARCHAR2(1);
      l_org_type                    HR_ORGANIZATION_UNITS.type%Type;
      j                             NUMBER;
      l_session_id                  NUMBER;
      l_item_xdock_sourceable       VARCHAR2(1);   --  ???
      l_item_replenishable_type     XX_INV_ITMS_ORG_ATTR_V.od_replen_type_cd%Type;
      l_item_replenishable_subtype  XX_INV_ITMS_ORG_ATTR_V.od_replen_sub_type_cd%Type; 

   BEGIN

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_ALT_ATP_PKG.Call_ALT_Org_ATP ...');
      END IF;
 
      -- FND_CLIENT_INFO.Set_Org_Context(p_operating_unit);

      IF p_ship_to_loc IS NOT Null THEN

         XX_MSC_Sourcing_SR_Org_Pkg.Get_Orgs_From_SR
         (
            p_ship_to_loc           => p_ship_to_loc,
            p_assignment_set_id     => p_assignment_set_id,
            p_item_val_org          => p_item_val_org,
            p_category_set_id       => p_category_set_id,
            p_category_name         => p_category_name,
            p_xdock_only            => p_xdock_only,
            p_exclude_org_id        => p_exclude_org_id,   -- Resourcing
            x_sr_orgs               => l_sr_orgs,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
          );

      ELSE

         XX_MSC_Sourcing_SR_Org_Pkg.Get_Orgs_From_SR
         (
            p_postal_code           => p_postal_code,
            p_assignment_set_id     => p_assignment_set_id,
            p_item_val_org          => p_item_val_org,
            p_category_set_id       => p_category_set_id,
            p_category_name         => p_category_name,
            p_xdock_only            => p_xdock_only,
            p_exclude_org_id        => p_exclude_org_id,  -- Resourcing
            x_sr_orgs               => l_sr_orgs,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
          );

      END IF;

      IF x_return_status <> 'S' THEN
         Return;
      END IF;


      IF l_sr_orgs.org_id.COUNT = 0 THEN
         x_msg := 'No Orgs in Sourcing Rule';
         x_error_code := 80; -- No Sources
         Return;
      END IF;

      XX_MSC_Sourcing_Util_Pkg.Get_Location_From_Org
         (
            p_organization_id         => p_base_org_id,
            x_location_id             => l_base_loc_id,
            x_return_status           => x_return_status,
            x_msg                     => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF p_xdock_only = 'Y' THEN
         j := 1;
      ELSE
         j := 2;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Sourcing Rule Orgs-Rank:');
         FOR i IN j..l_sr_orgs.org_id.count LOOP
            MSC_SCH_WB.ATP_Debug(' +   '||l_sr_orgs.org_id(i)||'-'||l_sr_orgs.rank(i));
         END LOOP;
      END IF;
      /*
      dbms_output.put_line('  -> Sourcing Rule Orgs-Rank:');
      for i in j..l_sr_orgs.org_id.count loop
         dbms_output.put_line(' +   '||l_sr_orgs.org_id(i)||'-'||l_sr_orgs.rank(i));
      end loop;
      */
      -- ====================================================  
      -- IF using 11.5.9 and above, Use MSC_ATP_GLOBAL.Extend_ATP 
      -- API to extend record structure as per standards. This 
      -- will ensure future compatibility.

      MSC_ATP_GLOBAL.Extend_Atp(L_atp_rec,x_return_status,1);

      -- IF using 11.5.8 code, Use MSC_SATP_FUNC.Extend_ATP 
      -- API to avoid any issues with Extending ATP record 
      -- type.
      -- ====================================================  

      FOR i IN j..l_sr_orgs.org_id.COUNT LOOP

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> **'||l_sr_orgs.org_id(i));
         END IF;

         -- dbms_output.put_line('  -> **'||l_sr_orgs.org_id(i));

         XX_MSC_Sourcing_Util_Pkg.Get_Org_Type
            (
               p_organization_id         => l_sr_orgs.org_id(i),
               x_org_type                => l_org_type,
               x_return_status           => x_return_status,
               x_msg                     => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Org Type: '||l_org_type);
         END IF;

         -- dbms_output.put_line('  -> Org Type: '||l_org_type);


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

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Item X-Dock Sourceable: '|| l_item_xdock_sourceable);
         END IF;

         -- dbms_output.put_line('  -> Item X-Dock Sourceable: '|| l_item_xdock_sourceable);

         IF l_org_type = 'WHXDRG' AND l_item_xdock_sourceable = 'N' THEN
            GOTO end_loop;
         END IF;

         l_atp_rec.requested_ship_date(1)       := l_today;
         l_atp_rec.Inventory_Item_Id(1)         := p_inventory_item_id; 
         l_atp_rec.Quantity_Ordered(1)          := p_quantity_ordered;
         l_atp_rec.Quantity_UOM(1)              := p_order_quantity_uom;
         l_atp_rec.ship_method(1)               := p_ship_method;
         l_atp_rec.Action(1)                    := 100;  
         l_atp_rec.Source_Organization_Id(1)    := l_sr_orgs.org_id(i);
         l_atp_rec.OE_Flag(1)                   := 'N';
         l_atp_rec.Insert_Flag(1)               := 1; 
         l_atp_rec.Attribute_04(1)              := 1;
         l_atp_rec.override_flag(1)             := 'N';

         Call_ATP
            (
               p_atp_rec         => l_atp_rec,
               x_atp_rec         => x_atp_rec,
               x_return_status   => x_return_status,
               x_msg             => x_msg
            );

         IF (x_atp_rec.Error_Code(1) <> 0) THEN
            SELECT meaning
            INTO   x_msg
            FROM   mfg_lookups
            WHERE  lookup_type = 'MTL_DEMAND_INTERFACE_ERRORS'
            AND    lookup_code = x_atp_rec.Error_Code(1);
         END IF;

         x_requested_date_qty          := x_atp_rec.Requested_Date_Quantity(1);
         x_error_code                  := x_atp_rec.error_code(1);
         x_ship_date                   := x_atp_rec.ship_date(1);

         -- dbms_output.put_line('i:'||i||'-'||x_error_code||'-'||x_requested_date_qty||'-'||x_ship_date);

         IF PG_DEBUG in ('Y', 'C') THEN

            MSC_SCH_WB.Set_Session_ID(p_session_id);

         END IF;

         IF x_error_code = 0 THEN

            XX_MSC_Sourcing_Util_Pkg.Get_Location_From_Org
               (
                  p_organization_id         => l_sr_orgs.org_id(i),
                  x_location_id             => l_location_id,
                  x_return_status           => x_return_status,
                  x_msg                     => x_msg
               );

            IF x_return_status <> 'S' THEN
               Return;
            END IF;


            XX_MSC_Sourcing_Util_Pkg.Check_If_XDock_Can_Ship_Direct
              (
                  p_organization_id       => l_sr_orgs.org_id(i),
                  x_ship_from_xdock_org   => l_ship_direct_from_xdock,
                  x_return_status         => x_return_status,
                  x_msg                   => x_msg
              );

            IF x_return_status <> 'S' THEN
               Return;
            END IF;


            IF PG_DEBUG in ('Y', 'C') THEN
               MSC_SCH_WB.ATP_Debug('  -> Ship Direct From XDock: '||l_ship_direct_from_xdock);
            END IF;

            -- dbms_output.put_line('  -> Ship Direct From XDock: '||l_ship_direct_from_xdock);


            IF l_org_type = 'WHXDRG' AND l_ship_direct_from_xdock = 'N' THEN

               XX_MSC_Sourcing_Date_Calc_Pkg.Get_Zone_Arrival_Date
                  (
                     p_partner_number        => p_customer_number,
                     p_ship_from_loc_id      => l_location_id,
                     p_ship_from_org_id      => l_sr_orgs.org_id(i),
                     p_base_org_id           => p_base_org_id,
                     p_base_loc_id           => l_base_loc_id, 
                     p_ship_method           => p_ship_method,
                     p_category_name         => p_category_name,
                     p_order_type            => p_order_type,
                     p_ship_to_region_id     => p_zone_id,
                     p_current_date_time     => p_current_date_time,
                     p_timezone_code         => p_timezone_code,
                     p_pickup                => p_pickup,
                     p_bulk                  => p_bulk,
                     x_ship_date             => x_ship_date,
                     x_arrival_date          => x_arrival_date,
                     x_intransit_time_1      => l_intransit_time_1,
                     x_ship_method_1         => l_ship_method_1,
                     x_intransit_time_2      => l_intransit_time_2,
                     x_ship_method_2         => l_ship_method_2,
                     x_partner_id            => l_partner_id,
                     x_return_status         => x_return_status,
                     x_msg                   => x_msg
                  );

               x_ship_method := l_ship_method_2;

            ELSE
               XX_MSC_Sourcing_Date_Calc_Pkg.Get_Zone_Arrival_Date
                  (
                     p_partner_number           => p_customer_number,
                     p_ship_from_loc_id         => l_location_id, 
                     p_ship_from_org_id         => l_sr_orgs.org_id(i), 
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
                     x_ship_method              => l_ship_method,
                     x_partner_id               => l_partner_id,
                     x_return_status            => x_return_status,
                     x_msg                      => x_msg
                 );

               x_ship_method := l_ship_method;

            END IF;

            IF x_return_status <> 'S' THEN
               Return;
            END IF;

            -- dbms_output.put_line('Requested Date: '||Trunc(p_requested_date));

            IF Trunc(p_requested_date) < Trunc(x_arrival_date) THEN

               x_error_code := 53;
               SELECT meaning
               INTO   x_msg
               FROM   mfg_lookups
               WHERE  lookup_type = 'MTL_DEMAND_INTERFACE_ERRORS'
               AND    lookup_code = 53;

               x_ship_method := Null;

               GOTO end_loop;
         
            ELSIF Trunc(p_requested_date) > Trunc(x_arrival_date) THEN

               l_requested_date := p_requested_date;

               IF l_org_type = 'WHXDRG' AND l_ship_direct_from_xdock = 'N' THEN

                  XX_MSC_Sourcing_Date_Calc_Pkg.Get_XDock_Ship_Date
                     (
                         p_partner_number         => p_customer_number,
                         p_partner_id             => l_partner_id,
                         p_ship_from_org_id       => l_sr_orgs.org_id(i),
                         p_base_org_id            => p_base_org_id,
                         p_ship_method_1          => l_ship_method_1,
                         p_intransit_time_1       => l_intransit_time_1,
                         p_ship_method_2          => l_ship_method_2,
                         p_intransit_time_2       => l_intransit_time_2,
                         x_requested_date         => l_requested_date,
                         x_ship_date              => x_ship_date,
                         x_return_status          => x_return_status,
                         x_msg                    => x_msg
                     );


               ELSE

                  XX_MSC_Sourcing_Date_Calc_Pkg.Get_Org_Ship_Date
                     (
                        p_partner_number           => p_customer_number,
                        p_partner_id               => l_partner_id,
                        p_ship_from_org_id         => l_sr_orgs.org_id(i),
                        p_ship_method              => l_ship_method,
                        p_intransit_time           => l_intransit_time,
                        x_requested_date           => l_requested_date,
                        x_ship_date                => x_ship_date,
                        x_return_status            => x_return_status,
                        x_msg                      => x_msg
                    );

               END IF;

               x_arrival_date := l_requested_date;

               IF l_org_type = 'WHXDRG' AND l_ship_direct_from_xdock = 'N' THEN
                  x_source_org_id := p_base_org_id;
                  x_tcsc_org_id   := l_sr_orgs.org_id(i);
               ELSE
                  x_source_org_id := l_sr_orgs.org_id(i);
                  x_tcsc_org_id   := Null;
               END IF;

               Return;
            ELSE

               IF l_org_type = 'WHXDRG' AND l_ship_direct_from_xdock = 'N' THEN
                  x_source_org_id := p_base_org_id;
                  x_tcsc_org_id   := l_sr_orgs.org_id(i);
               ELSE
                  x_source_org_id := l_sr_orgs.org_id(i);
                  x_tcsc_org_id   := Null;
               END IF;

               Return;

            END IF;


         ELSIF x_error_code = 53 THEN
            GOTO end_loop;
         ELSE
            x_ship_date := Null;
            x_requested_date_qty := Null;
            Return;
         END IF;

         <<end_loop>>
         Null;

      END LOOP;
      x_ship_date := Null;
      x_arrival_date := Null;
      x_requested_date_qty := Null;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Source Org ID: ' ||x_source_org_id);
         MSC_SCH_WB.ATP_Debug('  -> TCSC Org ID: ' ||x_tcsc_org_id);
         MSC_SCH_WB.ATP_Debug('  -> Requested Date Qty: '|| x_requested_date_qty);
         MSC_SCH_WB.ATP_Debug('  -> Ship Date: '||x_ship_date);
         MSC_SCH_WB.ATP_Debug('  -> Arrival Date: '||x_arrival_date);
         MSC_SCH_WB.ATP_Debug('  -> Ship Method to Use: '||x_ship_method);
         MSC_SCH_WB.ATP_Debug('  -> Error Code: ' || x_error_code);
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_ALT_ATP_PKG.Call_ALT_Org_ATP ...');
      END IF;
   

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Alt_ATP_Pkg.Call_Alt_Org_ATP()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Call_Alt_Org_ATP;

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
         p_exclude_org_id           IN  MTL_PARAMETERS_VIEW.organization_id%Type,
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
      ) AS

      l_session_id NUMBER;

   BEGIN

     IF PG_DEBUG in ('Y', 'C') THEN

         MSC_SCH_WB.Set_Session_ID(p_session_id);

      END IF;
      /*
      dbms_output.put_line('  ============================================================');
      dbms_output.put_line('  ->               INPUT PARAMETERS                           ');
      dbms_output.put_line('  ============================================================');
      dbms_output.put_line('  -> Customer Number              : '||p_customer_number);
      dbms_output.put_line('  -> Inventory Item ID            : '||p_inventory_item_id);
      dbms_output.put_line('  -> Requested Qty                : '||p_quantity_ordered);
      dbms_output.put_line('  -> Requested Qty UOM            : '||p_order_quantity_uom);
      dbms_output.put_line('  -> Requested Date               : '||p_requested_date);
      dbms_output.put_line('  -> Ship to Location             : '||p_ship_to_loc);
      dbms_output.put_line('  -> Postal Code                  : '||p_postal_code);
      dbms_output.put_line('  -> Ship Method                  : '||p_ship_method);
      dbms_output.put_line('  -> Assignment Set ID            : '||p_assignment_set_id);
      dbms_output.put_line('  -> Item Validation Org ID       : '||p_item_val_org);
      dbms_output.put_line('  -> Category Set ID              : '||p_category_set_id);
      dbms_output.put_line('  -> Category                     : '||p_category_name);
      dbms_output.put_line('  -> Order Type                   : '||p_order_type);
      dbms_output.put_line('  -> Zone ID                      : '||p_zone_id);
      dbms_output.put_line('  -> Inquiry Date Time            : '||to_char(p_current_date_time, 'DD-Mon-YYYY HH24:MI:SS'));
      dbms_output.put_line('  -> Inquiry Timezone             : '||p_timezone_code);
      dbms_output.put_line('  -> Base Org ID                  : '||p_base_org_id);
      dbms_output.put_line('  -> X-Dock Only                  : '||p_xdock_only);
      dbms_output.put_line('  -> Pickup                       : '||p_pickup);
      dbms_output.put_line('  -> Bulk                         : '||p_bulk);
      dbms_output.put_line('  -> Operating Unit               : '||p_operating_unit);
      dbms_output.put_line('  -> Session ID                   : '||p_session_id);
      dbms_output.put_line('  ============================================================');
      */

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_ALT_ATP_PKG.ALT_Org_ATP ...');
         MSC_SCH_WB.ATP_Debug('  ============================================================');
         MSC_SCH_WB.ATP_Debug('  ->               INPUT PARAMETERS                           ');
         MSC_SCH_WB.ATP_Debug('  ============================================================');
         MSC_SCH_WB.ATP_Debug('  -> Customer Number              : '||p_customer_number);
         MSC_SCH_WB.ATP_Debug('  -> Inventory Item ID            : '||p_inventory_item_id);
         MSC_SCH_WB.ATP_Debug('  -> Requested Qty                : '||p_quantity_ordered);
         MSC_SCH_WB.ATP_Debug('  -> Requested Qty UOM            : '||p_order_quantity_uom);
         MSC_SCH_WB.ATP_Debug('  -> Requested Date               : '||p_requested_date);
         MSC_SCH_WB.ATP_Debug('  -> Ship to Location             : '||p_ship_to_loc);
         MSC_SCH_WB.ATP_Debug('  -> Postal Code                  : '||p_postal_code);
         MSC_SCH_WB.ATP_Debug('  -> Ship Method                  : '||p_ship_method);
         MSC_SCH_WB.ATP_Debug('  -> Assignment Set ID            : '||p_assignment_set_id);
         MSC_SCH_WB.ATP_Debug('  -> Item Validation Org ID       : '||p_item_val_org);
         MSC_SCH_WB.ATP_Debug('  -> Category Set ID              : '||p_category_set_id);
         MSC_SCH_WB.ATP_Debug('  -> Category                     : '||p_category_name);
         MSC_SCH_WB.ATP_Debug('  -> Order Type                   : '||p_order_type);
         MSC_SCH_WB.ATP_Debug('  -> Zone ID                      : '||p_zone_id);
         MSC_SCH_WB.ATP_Debug('  -> Inquiry Date Time            : '||to_char(p_current_date_time, 'DD-Mon-YYYY HH24:MI:SS'));
         MSC_SCH_WB.ATP_Debug('  -> Inquiry Timezone             : '||p_timezone_code);
         MSC_SCH_WB.ATP_Debug('  -> Pickup                       : '||p_pickup);
         MSC_SCH_WB.ATP_Debug('  -> Bulk                         : '||p_bulk);
         MSC_SCH_WB.ATP_Debug('  -> Base Org ID                  : '||p_base_org_id);
         MSC_SCH_WB.ATP_Debug('  -> X-Dock Only                  : '||p_xdock_only);
         MSC_SCH_WB.ATP_Debug('  -> Operating Unit               : '||p_operating_unit);
         MSC_SCH_WB.ATP_Debug('  -> Excluded Org ID              : '||p_exclude_org_id);
         MSC_SCH_WB.ATP_Debug('  -> Session ID                   : '||p_session_id);
         MSC_SCH_WB.ATP_Debug('  ============================================================');
      END IF;

      IF p_pickup = 'Y' THEN
         x_return_status := 'E';
         x_msg := 'Ship method "Pickup" not applicable for Alternate Org ATP';
         Return;
      END IF;

      Call_Alt_Org_ATP 
         (
            p_customer_number            => p_customer_number,
            p_inventory_item_id          => p_inventory_item_id,
            p_quantity_ordered           => p_quantity_ordered,
            p_order_quantity_uom         => p_order_quantity_uom,
            p_requested_date             => p_requested_date,
            p_ship_to_loc                => p_ship_to_loc, 
            p_postal_code                => p_postal_code,
            p_ship_method                => p_ship_method,
            p_assignment_set_id          => p_assignment_set_id,
            p_item_val_org               => p_item_val_org,
            p_category_set_id            => p_category_set_id,
            p_category_name              => p_category_name,
            p_order_type                 => p_order_type,
            p_zone_id                    => p_zone_id,
            p_current_date_time          => p_current_date_time,
            p_timezone_code              => p_timezone_code,
            p_base_org_id                => p_base_org_id,
            p_xdock_only                 => p_xdock_only,
            p_pickup                     => p_pickup,
            p_bulk                       => p_bulk,
            p_operating_unit             => p_operating_unit,
            p_exclude_org_id             => p_exclude_org_id,
            p_session_id                 => p_session_id,
            x_source_org_id              => x_source_org_id,
            x_requested_date_qty         => x_requested_date_qty,
            x_ship_date                  => x_ship_date,
            x_arrival_date               => x_arrival_date,
            x_ship_method                => x_ship_method,
            x_tcsc_org_id                => x_tcsc_org_id,
            x_error_code                 => x_error_code,
            x_return_status              => x_return_status,
            x_msg                        => x_msg
         );

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_ALT_ATP_PKG.ALT_Org_ATP ...');
      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Alt_ATP_Pkg.Alt_Org_ATP()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Alt_Org_ATP;


END XX_MSC_SOURCING_ALT_ATP_PKG;
/
