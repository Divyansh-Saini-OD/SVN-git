CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_CUSTOM_ATP_PKG AS

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


   PG_DEBUG VARCHAR2(1) := NVL(FND_PROFILE.Value('MSC_ATP_DEBUG'), 'N');


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
      ) AS

      l_session_id NUMBER;

      l_base_org                    MTL_PARAMETERS_VIEW.organization_code%Type;
      l_base_org_id                 MTL_PARAMETERS_VIEW.organization_id%Type;
      l_sr_item_id                  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type;
      l_order_flow_type             FND_FLEX_VALUES_VL.flex_value%Type;
      l_atp_types                   XX_MSC_Sourcing_Util_Pkg.ATP_Types;
      l_assignment_set_id           MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type;
      l_item_val_org                MTL_PARAMETERS_VIEW.organization_id%Type;
      l_category_set_id             MSC_CATEGORY_SETS.category_set_id%Type;
      l_category_name               MSC_ITEM_CATEGORIES.category_name%Type;
      l_zone_id                     WSH_ZONE_REGIONS_V.zone_id%Type;
      l_xref_item                   MTL_CROSS_REFERENCES_V.cross_reference%Type;
      l_xref_sr_item_id             MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type;
      l_pickup                      VARCHAR2(1);
      l_bulk                        VARCHAR2(1);
      l_xdock_only                  VARCHAR2(1);

      l_source_org_id               MTL_PARAMETERS_VIEW.organization_id%Type;
      l_requested_date_qty          NUMBER;
      l_ship_date                   DATE;
      l_arrival_date                DATE;
      l_ship_method                 MTL_INTERORG_SHIP_METHODS.ship_method%Type;
      l_error_code                  NUMBER;
      
      l_tcsc_org_id                 MTL_PARAMETERS_VIEW.organization_id%Type;
      l_current_sr_item_id          MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type;

      l_vendor_id                   PO_VENDORS.vendor_id%Type;
      l_vendor_site_id              PO_VENDOR_SITES.vendor_site_id%Type;
      l_vendor_type                 XX_PO_SSA_V.supp_loc_count_ind%Type;
      l_vendor_facility_code        XX_PO_MLSS_DET.supp_facility_cd%Type;
      l_vendor_account              XX_PO_MLSS_DET.supp_loc_ac%Type;
      l_drop_ship_code              XX_PO_SSA_V.drop_ship_cd%Type;

      t_source_org_id               MTL_PARAMETERS_VIEW.organization_id%Type;
      t_requested_date_qty          NUMBER;
      t_ship_date                   DATE;
      t_arrival_date                DATE;
      t_ship_method                 MTL_INTERORG_SHIP_METHODS.ship_method%Type;
      t_error_code                  NUMBER;

   BEGIN

      x_return_status := 'S';

      FND_GLOBAL.Apps_Initialize
         (
             user_id        => Nvl(p_user_id, FND_GLOBAL.User_ID),
             resp_id        => XX_MSC_SOURCING_UTIL_PKG.RESP_ID,
             resp_appl_id   => XX_MSC_SOURCING_UTIL_PKG.RESP_APPL_ID
         ); 

      PG_DEBUG := NVL(FND_PROFILE.Value('MSC_ATP_DEBUG'), 'N');

      IF PG_DEBUG in ('Y', 'C') THEN

         SELECT OE_ORDER_SCH_UTIL.Get_Session_Id
         INTO   l_session_id
         FROM   dual;  

         MSC_SCH_WB.Set_Session_ID(l_session_id);

      END IF;
      
      -- dbms_output.put_line('  -> Session ID: '||l_session_id);
      -- dbms_output.put_line('  -> User ID: '||p_user_id);

      x_session_id := l_session_id;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_CUSTOM_ATP_PKG.Call_ATP() ...');
         MSC_SCH_WB.ATP_Debug('  -> Session ID: '||l_session_id);
         MSC_SCH_WB.ATP_Debug('  -> User ID: '||p_user_id);
      END IF;

      XX_MSC_SOURCING_PREPROCESS_PKG.ATP_Pre_Process
         (
            p_item_ordered          => p_item_ordered,
            p_quantity_ordered      => p_quantity_ordered,
            p_order_quantity_uom    => p_order_quantity_uom,
            p_customer_number       => p_customer_number,
            p_ship_to_loc           => p_ship_to_loc,
            p_postal_code           => p_postal_code,
            p_current_date_time     => p_current_date_time,
            p_timezone_code         => p_timezone_code,
            p_requested_date        => p_requested_date,
            p_order_type            => p_order_type,
            p_ship_method           => p_ship_method,
            p_ship_from_org         => p_ship_from_org,
            p_operating_unit        => p_operating_unit,
            p_session_id            => l_session_id,
            x_base_org              => l_base_org,
            x_base_org_id           => l_base_org_id,
            x_sr_item_id            => l_sr_item_id,
            x_order_flow_type       => l_order_flow_type,
            x_atp_types             => l_atp_types,
            x_assignment_set_id     => l_assignment_set_id,
            x_item_val_org          => l_item_val_org,
            x_category_set_id       => l_category_set_id,
            x_category_name         => l_category_name,
            x_zone_id               => l_zone_id,
            x_xref_item             => l_xref_item,
            x_xref_sr_item_id       => l_xref_sr_item_id,
            x_pickup                => l_pickup,
            x_bulk                  => l_bulk,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
         ); 

         IF x_return_status <> 'S' THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               MSC_SCH_WB.ATP_Debug('  -> Return Status: '||x_return_status);
               MSC_SCH_WB.ATP_Debug('  -> Message: '||x_msg);
            END IF;
            Return;
         END IF;

         FOR i IN 1..l_atp_types.atp_type.count LOOP
            IF Upper(l_atp_types.atp_type(i)) NOT IN ('BASE','ALT','SUB','EXT','XDOCK','NO ATP') THEN
               x_return_status := 'E';
               x_msg := 'Invalid ATP type "'||l_atp_types.atp_type(i)||'" in Value Set '||l_order_flow_type;

               IF PG_DEBUG in ('Y', 'C') THEN
                  MSC_SCH_WB.ATP_Debug('  -> Return Status: '||x_return_status);
                  MSC_SCH_WB.ATP_Debug('  -> Message: '||x_msg);
               END IF;
               Return;
            END IF;

         END LOOP;

         FOR i IN 1..l_atp_types.atp_type.count LOOP
            IF l_atp_types.atp_type(i) = 'NO ATP' THEN
               x_ship_date := p_requested_date;
               x_arrival_date := p_requested_date;
               x_source_org_id := l_base_org_id;

               IF PG_DEBUG in ('Y', 'C') THEN
                  MSC_SCH_WB.ATP_Debug('  -> NO ATP for this order flow type');
               END IF;
               Return;
            END IF;
         END LOOP;

         FOR i IN 1..l_atp_types.atp_type.count LOOP

            x_msg := Null;
            l_source_org_id := Null;
            l_requested_date_qty := Null;
            l_ship_date := Null;
            l_arrival_date := Null;
            l_ship_method := Null;
            l_error_code := Null;
            l_current_sr_item_id := Null;
           

            IF ( l_atp_types.atp_type(i) = 'BASE' ) OR
               ( l_atp_types.atp_type(i) = 'SUB' AND l_xref_sr_item_id IS NOT Null) THEN

               IF l_atp_types.atp_type(i) = 'BASE' THEN
                  l_current_sr_item_id := l_sr_item_id;
               ELSIF l_atp_types.atp_type(i) = 'SUB' THEN
                  l_current_sr_item_id := l_xref_sr_item_id;
               END IF;


               XX_MSC_SOURCING_BASE_ATP_PKG.Base_Org_ATP
                  (
                     p_customer_number      => p_customer_number,
                     p_inventory_item_id    => l_current_sr_item_id,
                     p_category_name        => l_category_name,
                     p_quantity_ordered     => p_quantity_ordered,
                     p_order_quantity_uom   => p_order_quantity_uom,
                     p_requested_date       => p_requested_date,
                     p_base_org_id          => l_base_org_id,
                     p_zone_id              => l_zone_id, 
                     p_ship_method          => p_ship_method,
                     p_order_type           => p_order_type,
                     p_current_date_time    => p_current_date_time,
                     p_timezone_code        => p_timezone_code,
                     p_pickup               => Nvl(l_pickup, 'N'),
                     p_bulk                 => Nvl(l_bulk, 'N'),
                     p_operating_unit       => p_operating_unit,  -- Resourcing
                     p_exclude_org_id       => p_exclude_org_id,  -- Resourcing
                     p_session_id           => l_session_id,
                     x_source_org_id        => l_source_org_id,
                     x_requested_date_qty   => l_requested_date_qty,
                     x_ship_date            => l_ship_date,
                     x_arrival_date         => l_arrival_date,
                     x_ship_method          => l_ship_method,
                     x_error_code           => l_error_code,
                     x_return_status        => x_return_status,
                     x_msg                  => x_msg
                  ) ;

               IF x_return_status <> 'S' THEN 
                  IF PG_DEBUG in ('Y', 'C') THEN
                     MSC_SCH_WB.ATP_Debug('  -> Return Status: '||x_return_status);
                     MSC_SCH_WB.ATP_Debug('  -> Message: '||x_msg);
                  END IF;       
                  Return;
               END IF;

               IF l_error_code = 0 THEN
                  x_source_org_id        := l_source_org_id;
                  x_requested_date_qty   := l_requested_date_qty;
                  x_ship_date            := l_ship_date;
                  x_arrival_date         := l_arrival_date;
                  x_ship_method          := l_ship_method;
                  x_error_code           := l_error_code;

                  IF l_atp_types.atp_type(i) = 'SUB' THEN
                     x_substitute_item_id  :=  l_xref_sr_item_id;
                  END IF;

                  IF PG_DEBUG in ('Y', 'C') THEN
                     MSC_SCH_WB.ATP_Debug('  -> Sourced from Base Org');
                  END IF;                 
                  Return;
               ELSIF l_error_code = 53 THEN

                  IF l_atp_types.atp_type(i) = 'BASE' THEN
                     t_source_org_id        := l_source_org_id;
                     t_requested_date_qty   := l_requested_date_qty;
                     t_ship_date            := l_ship_date;
                     t_arrival_date         := l_arrival_date;
                     t_ship_method          := l_ship_method;
                     t_error_code           := l_error_code;
     
                     IF PG_DEBUG in ('Y', 'C') THEN
                        MSC_SCH_WB.ATP_Debug('  -> Base Org cannot supply');
                     END IF;

                  ELSE

                     IF PG_DEBUG in ('Y', 'C') THEN
                        MSC_SCH_WB.ATP_Debug('  -> Base Org (Substitute) cannot supply');
                     END IF;

                  END IF;

               ELSE
 
                  x_error_code           := l_error_code;

                  IF PG_DEBUG in ('Y', 'C') THEN
                     MSC_SCH_WB.ATP_Debug('  -> Return Status: '||x_return_status);
                     MSC_SCH_WB.ATP_Debug('  -> Message: '||x_msg);
                     MSC_SCH_WB.ATP_Debug('  -> Base Org Exit');
                  END IF;

                  Return;
               END IF;

            ELSIF l_atp_types.atp_type(i) IN ('ALT', 'XDOCK') THEN

               IF Nvl(l_pickup, 'N') = 'N' THEN

                  l_source_org_id           := Null;
                  l_requested_date_qty      := Null;
                  l_ship_date               := Null;
                  l_arrival_date            := Null;
                  l_ship_method             := Null;
                  l_error_code              := Null;

                  IF l_atp_types.atp_type(i) = 'ALT' THEN
                     l_xdock_only := 'N';
                  ELSE
                     l_xdock_only := 'Y';
                  END IF;

                  XX_MSC_SOURCING_ALT_ATP_PKG.Alt_Org_ATP
                     (
                         p_customer_number          => p_customer_number,
                         p_inventory_item_id        => l_sr_item_id,
                         p_quantity_ordered         => p_quantity_ordered,
                         p_order_quantity_uom       => p_order_quantity_uom,
                         p_requested_date           => p_requested_date,
                         p_ship_to_loc              => p_ship_to_loc, 
                         p_postal_code              => p_postal_code,
                         p_ship_method              => p_ship_method,
                         p_assignment_set_id        => l_assignment_set_id,
                         p_item_val_org             => l_item_val_org,
                         p_category_set_id          => l_category_set_id,
                         p_category_name            => l_category_name,
                         p_order_type               => p_order_type,
                         p_zone_id                  => l_zone_id,
                         p_current_date_time        => p_current_date_time,
                         p_timezone_code            => p_timezone_code,
                         p_base_org_id              => l_base_org_id,
                         p_xdock_only               => l_xdock_only,
                         p_pickup                   => 'N',
                         p_bulk                     => Nvl(l_bulk, 'N'),
                         p_operating_unit           => p_operating_unit,
                         p_exclude_org_id           => p_exclude_org_id,  -- Resourcing
                         p_session_id               => l_session_id,
                         x_source_org_id            => l_source_org_id,
                         x_requested_date_qty       => l_requested_date_qty,
                         x_ship_date                => l_ship_date,
                         x_arrival_date             => l_arrival_date,
                         x_ship_method              => l_ship_method,
                         x_tcsc_org_id              => l_tcsc_org_id,
                         x_error_code               => l_error_code,
                         x_return_status            => x_return_status,
                         x_msg                      => x_msg
                      );


                  IF x_return_status <> 'S' THEN  
                     IF PG_DEBUG in ('Y', 'C') THEN
                        MSC_SCH_WB.ATP_Debug('  -> Return Status: '||x_return_status);
                        MSC_SCH_WB.ATP_Debug('  -> Message: '||x_msg);
                     END IF;      
                     Return;
                  END IF;

                  IF l_error_code = 0 THEN
                     x_source_org_id            := l_source_org_id;
                     x_requested_date_qty       := l_requested_date_qty;
                     x_ship_date                := l_ship_date;
                     x_arrival_date             := l_arrival_date;
                     x_ship_method              := l_ship_method;
                     x_tcsc_org_id              := l_tcsc_org_id;
                     x_error_code               := l_error_code;

                     IF PG_DEBUG in ('Y', 'C') THEN
                        MSC_SCH_WB.ATP_Debug('  -> Sourced from Alt Org');
                     END IF;

                     Return;
                  
                  ELSIF l_error_code = 53 THEN

                     IF PG_DEBUG in ('Y', 'C') THEN
                        MSC_SCH_WB.ATP_Debug('  -> Alt Org cannot supply');
                     END IF;
                     Null;

                  ELSE
                     
                     x_error_code           := l_error_code;

                     IF PG_DEBUG in ('Y', 'C') THEN
                        MSC_SCH_WB.ATP_Debug('  -> Return Status: '||x_return_status);
                        MSC_SCH_WB.ATP_Debug('  -> Message: '||x_msg);
                        MSC_SCH_WB.ATP_Debug('  -> Alt Org exit');
                     END IF;
   
                     Return;

                  END IF;
               END IF;

            ELSIF l_atp_types.atp_type(i) IN ('EXT') THEN
           
               XX_MSC_SOURCING_VENDOR_ATP_PKG.Vendor_ATP
                  (
                     p_customer_number          => p_customer_number,
                     p_inventory_item_id        => l_sr_item_id,
                     p_quantity_ordered         => p_quantity_ordered,
                     p_order_quantity_uom       => p_order_quantity_uom,
                     p_requested_date           => p_requested_date,
                     p_base_org_id              => l_base_org_id,
                     p_zone_id                  => l_zone_id, 
                     p_current_date_time        => p_current_date_time,
                     p_timezone_code            => p_timezone_code,
                     p_unit_selling_price       => p_unit_selling_price,
                     p_operating_unit           => p_operating_unit,
                     p_drop_ship_cd             => p_drop_ship_code,
                     p_ship_method              => p_ship_method,
                     p_category_name            => l_category_name,
                     p_bulk                     => Nvl(l_bulk, 'N'),
                     p_exclude_vendor_site_id   => p_exclude_vendor_site_id,   -- Resourcing
                     p_session_id               => l_session_id,
                     x_source_org_id            => l_source_org_id,
                     x_vendor_id                => l_vendor_id,
                     x_vendor_site_id           => l_vendor_site_id,
                     x_vendor_type              => l_vendor_type,
                     x_vendor_facility_code     => l_vendor_facility_code,  
                     x_vendor_account           => l_vendor_account,
                     x_requested_date_qty       => l_requested_date_qty,
                     x_drop_ship_cd             => l_drop_ship_code,
                     x_ship_method              => l_ship_method,
                     x_ship_date                => l_ship_date,
                     x_arrival_date             => l_arrival_date,
                     x_error_code               => l_error_code,
                     x_return_status            => x_return_status,
                     x_msg                      => x_msg
                  );

               IF x_return_status <> 'S' THEN  
                  IF PG_DEBUG in ('Y', 'C') THEN
                     MSC_SCH_WB.ATP_Debug('  -> Return Status: '||x_return_status);
                     MSC_SCH_WB.ATP_Debug('  -> Message: '||x_msg);
                  END IF;      
                  Return;
               END IF;

               IF l_error_code = 0 THEN

                  x_source_org_id         := l_source_org_id;
                  x_requested_date_qty    := l_requested_date_qty;
                  x_ship_date             := l_ship_date;
                  x_arrival_date          := l_arrival_date; 
                  x_error_code            := l_error_code;
                  x_vendor_id             := l_vendor_id;
                  x_vendor_site_id        := l_vendor_site_id;
                  x_vendor_type           := l_vendor_type;
                  x_vendor_facility_code  := l_vendor_facility_code;
                  x_vendor_account        := l_vendor_account;
                  x_drop_ship_code        := l_drop_ship_code;
                  x_ship_method           := l_ship_method;
                  x_return_status         := x_return_status;
                  x_msg                   := x_msg;

                  IF PG_DEBUG in ('Y', 'C') THEN
                     MSC_SCH_WB.ATP_Debug('  -> Sourced from External Vendor');
                  END IF;

                  Return;
               END IF;

            END IF;

                        
         END LOOP;

         x_source_org_id        := t_source_org_id;
         x_requested_date_qty   := t_requested_date_qty;
         x_ship_date            := t_ship_date;
         x_arrival_date         := t_arrival_date;
         x_ship_method          := t_ship_method;
         x_error_code           := t_error_code;
         x_future_order         := 'Y';
         


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Base Org Future Date');
         MSC_SCH_WB.ATP_Debug('  -> Return Status: '||x_return_status);
         MSC_SCH_WB.ATP_Debug('  -> Message: '||x_msg);
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_CUSTOM_ATP_PKG.Call_ATP() ...');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Custom_ATP_Pkg.Call_ATP()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Call_ATP;

END XX_MSC_SOURCING_CUSTOM_ATP_PKG;
/
