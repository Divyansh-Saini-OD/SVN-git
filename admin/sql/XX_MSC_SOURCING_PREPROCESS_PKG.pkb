CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_PREPROCESS_PKG AS

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


   PG_DEBUG VARCHAR2(1) := NVL(FND_PROFILE.Value('MSC_ATP_DEBUG'), 'N');

   PROCEDURE Get_Flow_type
      (
         p_item_ordered             IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered         IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom       IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc              IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code              IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time        IN  DATE,
         p_requested_date           IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type               IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org            IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_cust_setup_org           IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.Category_name%Type,
         p_base_org_id              IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_pickup                   IN  VARCHAR2,
         p_bulk                     IN  VARCHAR2,
         p_flow_types               IN  XX_MSC_Sourcing_Util_Pkg.ATP_Order_Flow_Typ,
         x_order_flow_type          OUT FND_FLEX_VALUES_VL.flex_value%Type,
         x_return_status            OUT VARCHAR2,
         x_msg                      OUT VARCHAR2
      ) AS

      l_stmt                        VARCHAR2(4000);
      l_yes_no                      VARCHAR2(3);


   BEGIN

      x_return_status := 'S';

      FOR i in 1..p_flow_types.atp_flow_name.count LOOP

         l_stmt := 'SELECT XX_MSC_Sourcing_Order_Flow_Pkg.'||
                   p_flow_types.atp_flow_func(i)||
                  '(:p1, :p2,:p3, :p4, :p5, :p6, :p7, :p8, :p9, :p10, :p11, :p12, :p13, :p14, :p15, :p16) FROM Dual';

         EXECUTE IMMEDIATE (l_stmt) INTO l_yes_no 
         USING p_item_ordered,
               p_quantity_ordered,
               p_order_quantity_uom,
               p_customer_number,
               p_ship_to_loc,
               p_postal_code,
               p_current_date_time,
               p_requested_date,
               p_order_type,
               p_ship_method,
               p_ship_from_org,
               p_cust_setup_org,
               p_category_name,
               p_base_org_id,
               p_pickup,
               p_bulk;


         IF l_yes_no = 'Yes' THEN

            x_order_flow_type := p_flow_types.atp_flow_name(i);
            Return;

         END IF;
                                          
      END LOOP;      

      IF x_order_flow_type IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine Order Flow Type';
         Return;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Preprocess_Pkg.Get_Flow_Type()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Flow_Type;

   PROCEDURE Get_ATP_Types
      (
         p_order_flow_type          IN  FND_FLEX_VALUES_VL.flex_value%Type,
         x_atp_types                OUT XX_MSC_Sourcing_Util_Pkg.ATP_Types, 
         x_return_status            OUT VARCHAR2,
         x_msg                      OUT VARCHAR2
      ) AS


   CURSOR c_vset (c_parent_value_set_name  FND_FLEX_VSET_V.parent_value_set_name%Type) IS
      SELECT flex_value_set_id
      FROM   fnd_flex_vset_v
      WHERE  parent_value_set_name = c_parent_value_set_name;

   CURSOR c_flex (c_flex_value_set_id  FND_FLEX_VSET_V.flex_value_set_id%Type) IS
      SELECT flex_value,
             attribute1           -- sequence
      FROM   fnd_flex_values_vl
      WHERE  enabled_flag = 'Y'
      AND    Sysdate BETWEEN Nvl(start_date_active, Sysdate) AND Nvl(end_date_active, sysdate+1)
      AND    flex_value_set_id = c_flex_value_set_id
      ORDER  BY attribute1;
   

   l_flex_value_set_id    FND_FLEX_VSET_V.flex_value_set_id%Type;
   l_flex_value           FND_FLEX_VALUES_VL.flex_value%Type;
   i                      NUMBER := 0;

   BEGIN

      x_return_status := 'S';

      OPEN  c_vset (p_order_flow_type);
      FETCH c_vset INTO l_flex_value_set_id;
      CLOSE c_vset;

      IF l_flex_value_set_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Value Set "'||p_order_flow_type||'" not set up correctly';
         Return;
      END IF;

      FOR c_flex_rec In c_flex(l_flex_value_set_id) LOOP

         i := i+1;

         x_atp_types.atp_type.extend(1);
         x_atp_types.atp_seq.extend(1);
         
         x_atp_types.atp_type(i) := c_flex_rec.flex_value;
         x_atp_types.atp_seq(i)  := c_flex_rec.attribute1;
     
      END LOOP;

      IF x_atp_types.atp_type.count = 0 THEN
         x_return_status := 'E';
         x_msg := 'No ATP Types set up for value set "'||p_order_flow_type||'"';
         Return;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Preprocess_Pkg.Get_ATP_Types()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_ATP_Types;


   PROCEDURE Pre_Processing
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
         x_atp_types                OUT XX_MSC_Sourcing_Util_Pkg.ATP_Types,
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
      )  AS

      l_cust_setup_org              MTL_PARAMETERS_VIEW.organization_code%Type;
      l_category_name               MSC_ITEM_CATEGORIES.category_name%Type; 
      l_item_id                     MSC_SYSTEM_ITEMS.inventory_item_id%Type;
      l_flow_types                  XX_MSC_Sourcing_Util_Pkg.ATP_Order_Flow_Typ;
      l_assignment_set_id           MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type;
      l_item_val_org                MTL_PARAMETERS_VIEW.organization_id%Type;
      l_category_set_id             MSC_CATEGORY_SETS.category_set_id%Type;
      l_organization_id             MTL_PARAMETERS_VIEW.organization_id%Type;
      l_location_id                 MSC_LOCATION_ASSOCIATIONS.location_id%Type;
      l_postal_code                 HZ_LOCATIONS.postal_code%Type;
      l_sr_item_id                  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type;
      l_xref_item                   MTL_CROSS_REFERENCES_V.cross_reference%Type;
      l_xref_item_id                MSC_SYSTEM_ITEMS.inventory_item_id%Type;
      l_xref_sr_item_id             MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type;
      l_pickup                      VARCHAR2(1);
      l_bulk                        VARCHAR2(1);
   

   BEGIN 


      x_return_status := 'S';

      XX_MSC_Sourcing_Util_Pkg.Validate_Operating_Unit
         (
            p_operating_unit     => p_operating_unit,
            x_return_status      => x_return_status,
            x_msg                => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;


      FND_CLIENT_INFO.Set_Org_Context(p_operating_unit);

      IF p_ship_method IS NOT NUll THEN
         XX_MSC_Sourcing_Params_Pkg.Check_If_ShipMethod_Pickup
            (
               p_ship_method          => p_ship_method,
               x_pickup               => l_pickup,
               x_return_status        => x_return_status,
               x_msg                  => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Pickup: '||l_pickup);
      END IF;


      XX_MSC_Sourcing_Params_Pkg.Validate_Parameters
         (
            p_item_ordered             => p_item_ordered,
            p_quantity_ordered         => p_quantity_ordered,
            p_order_quantity_uom       => p_order_quantity_uom,
            p_customer_number          => p_customer_number,
            p_ship_to_loc              => p_ship_to_loc,
            p_postal_code              => p_postal_code,
            p_current_date_time        => p_current_date_time,
            p_timezone_code            => p_timezone_code,
            p_requested_date           => p_requested_date,
            p_order_type               => p_order_type,
            p_ship_method              => p_ship_method,
            p_ship_from_org            => p_ship_from_org,
            p_pickup                   => l_pickup,
            x_return_status            => x_return_status,
            x_msg                      => x_msg      
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;


      XX_MSC_Sourcing_Util_Pkg.Get_Assignment_Set
         (
            x_assignment_set_id  => l_assignment_set_id,
            x_return_status      => x_return_status,
            x_msg                => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Assignment Set ID: '||l_assignment_set_id);
      END IF;

      xx_MSC_Sourcing_Util_Pkg.Get_Item_Validation_Org
         (
            x_item_val_org      => l_item_val_org,
            x_return_status     => x_return_status,
            x_msg               => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Item Validation Org: '||l_item_val_org);
      END IF;

      XX_MSC_Sourcing_Util_Pkg.Get_Category_Set_ID
         (
            x_category_set_id   => l_category_set_id,
            x_return_status     => x_return_status,
            x_msg               => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Category Set ID: '||l_category_set_id);
      END IF;

      XX_MSC_Sourcing_Util_Pkg.Get_ATP_Order_Flow_Types
         (
            x_flow_types         => l_flow_types,
            x_return_status      => x_return_status,
            x_msg                => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      /*
      dbms_output.put_line('=');
      dbms_output.put_line('-> Flow Name(s)-Precedence-Func: ');
      for i in 1..l_flow_types.atp_flow_name.count loop
         dbms_output.put_line('+       '||
                                l_flow_types.atp_flow_name(i)||'-'||
                                l_flow_types.atp_flow_seq(i) ||'-'||
                                l_flow_types.atp_flow_func(i) ||'()');
      end loop;
      */
      IF PG_DEBUG in ('Y', 'C') THEN

         MSC_SCH_WB.ATP_Debug('  -> Flow Name(s)-Precedence-Func: ');
         FOR i IN 1..l_flow_types.atp_flow_name.count LOOP
            MSC_SCH_WB.ATP_Debug('  +   '||
                  l_flow_types.atp_flow_name(i)||'-'||
                  l_flow_types.atp_flow_seq(i) ||'-'||
                  l_flow_types.atp_flow_func(i) ||'()');
         END LOOP;

      END IF;
      

      XX_MSC_Sourcing_Params_Pkg.Get_Org_From_Cust_Setup
         (
            p_customer_number    => p_customer_number,
            x_org                => l_cust_setup_org,
            x_return_status      => x_return_status,
            x_msg                => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Customer Setup Org: '||l_cust_setup_org);
      END IF;

      XX_MSC_Sourcing_Params_Pkg.Get_Item_ID
         (
            p_item_name         => p_item_ordered,
            p_organization_id   => l_item_val_org,
            x_item_id           => l_item_id,
            x_sr_item_id        => l_sr_item_id,
            x_return_status     => x_return_status,
            x_msg               => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Item ID: '||l_item_id);
         MSC_SCH_WB.ATP_Debug('  -> Source Item ID: '||l_sr_item_id);
      END IF;

      XX_MSC_Sourcing_Params_Pkg.Get_Category_Name
         (
            p_item_id         => l_item_id,
            p_org_id          => l_item_val_org,
            p_category_set_id => l_category_set_id,
            x_category_name   => l_category_name,
            x_return_status   => x_return_status,
            x_msg             => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Category Name: '||l_category_name);
      END IF;

      IF p_ship_to_loc IS NOT Null THEN

         XX_MSC_Sourcing_Params_Pkg.Get_Postal_Code
            (
               p_ship_to_loc          => p_ship_to_loc,
               x_postal_code          => l_postal_code,
               x_return_status        => x_return_status,
               x_msg                  => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Postal Code: '||l_postal_code);
         END IF;

      ELSE
   
         l_postal_code := p_postal_code;

      END IF;
       

      XX_MSC_Sourcing_SR_Org_Pkg.Get_Base_Org
         (
            p_customer_number       => p_customer_number,
            p_item                  => p_item_ordered,
            p_ship_to_loc           => p_ship_to_loc,
            p_postal_code           => l_postal_code,
            p_ship_from_org         => p_ship_from_org,
            p_cust_setup_org        => l_cust_setup_org,
            p_assignment_set_id     => l_assignment_set_id,
            p_item_val_org          => l_item_val_org,
            p_category_set_id       => l_category_set_id,
            p_category_name         => l_category_name,
            x_base_org              => x_base_org,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Base Org: '||x_base_org);
      END IF;

      XX_MSC_Sourcing_Params_Pkg.Get_Org_ID
      (
         p_base_org                => x_base_org,
         x_organization_id         => l_organization_id,
         x_return_status           => x_return_status,
         x_msg                     => x_msg
       );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Base Org ID: '||l_organization_id);
      END IF;

      XX_MSC_Sourcing_Params_Pkg.Get_Zone
         (
            p_postal_code       => l_postal_code,
            p_category_name     => l_category_name,
            x_zone_id           => x_zone_id,
            x_return_status     => x_return_status,
            x_msg               => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Zone ID: '||x_zone_id);
      END IF;

      XX_MSC_Sourcing_Params_Pkg.Check_If_Order_Bulk
         (
            p_category_name         => l_category_name,
            p_item_ordered          => p_item_ordered,
            p_quantity_ordered      => p_quantity_ordered,
            p_item_val_org_id       => l_item_val_org,
            x_bulk                  => l_bulk,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Bulk: '||l_bulk);
      END IF;

      Get_Flow_Type
         (
            p_item_ordered             => p_item_ordered,
            p_quantity_ordered         => p_quantity_ordered,
            p_order_quantity_uom       => p_order_quantity_uom,
            p_customer_number          => p_customer_number,
            p_ship_to_loc              => p_ship_to_loc,
            p_postal_code              => l_postal_code,
            p_current_date_time        => p_current_date_time,
            p_requested_date           => p_requested_date,
            p_order_type               => p_order_type,
            p_ship_method              => p_ship_method,
            p_ship_from_org            => p_ship_from_org,
            p_cust_setup_org           => l_cust_setup_org,
            p_category_name            => l_category_name,
            p_base_org_id              => l_organization_id,
            p_pickup                   => Nvl(l_pickup, 'N'),
            p_bulk                     => Nvl(l_bulk, 'N'),
            p_flow_types               => l_flow_types,
            x_order_flow_type          => x_order_flow_type,
            x_return_status            => x_return_status,
            x_msg                      => x_msg
      );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Order Flow Type: '||x_order_flow_type);
      END IF;

      Get_ATP_Types
         (
            p_order_flow_type          => x_order_flow_type,
            x_atp_types                => x_atp_types,
            x_return_status            => x_return_status,
            x_msg                      => x_msg
         );
            
      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         FOR i IN 1..x_atp_types.atp_type.count LOOP
            MSC_SCH_WB.ATP_Debug('  +   '||x_atp_types.atp_type(i)||'('||x_atp_types.atp_seq(i)||')');
         END LOOP;
      END IF;

      /*
      dbms_output.put_line('ATP Type(s): ');
      for i in 1..x_atp_types.atp_type.count loop
         dbms_output.put_line('+'||x_atp_types.atp_type(i)||'-'||
                                            x_atp_types.atp_seq(i));
      end loop;
      */

      XX_MSC_Sourcing_Params_Pkg.Get_Forced_Substitute
         (
            p_inventory_item_id     => l_sr_item_id,
            p_organization_id       => l_organization_id,
            x_xref_item             => l_xref_item,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Substitute: '||l_xref_item);
      END IF;

      -- Substitute
      IF l_xref_item IS NOT NUll THEN

         XX_MSC_Sourcing_Params_Pkg.Get_Item_ID
            (
               p_item_name        => l_xref_item,
               p_organization_id  => l_organization_id,
               x_item_id          => l_xref_item_id,
               x_sr_item_id       => l_xref_sr_item_id,
               x_return_status    => x_return_status,
               x_msg              => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Substitute Item ID: '||l_xref_item_id);
            MSC_SCH_WB.ATP_Debug('  -> Substitute Source Item ID: '||l_xref_sr_item_id);
         END IF;

      END IF;

      x_assignment_set_id        := l_assignment_set_id;
      x_item_val_org             := l_item_val_org;
      x_category_set_id          := l_category_set_id;
      x_category_name            := l_category_name;
      x_xref_item                := l_xref_item;
      x_base_org_id              := l_organization_id;
      x_sr_item_id               := l_sr_item_id;
      x_xref_sr_item_id          := l_xref_sr_item_id;
      x_pickup                   := l_pickup; 
      x_bulk                     := l_bulk;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Preprocess_Pkg.Pre_Processing()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Pre_Processing;

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
         x_atp_types                OUT XX_MSC_Sourcing_Util_Pkg.ATP_Types,
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
      ) AS

      l_session_id NUMBER;

   BEGIN


      
      dbms_output.put_line('  ============================================================');
      dbms_output.put_line('  ->               INPUT PARAMETERS                           ');
      dbms_output.put_line('  ============================================================');
      dbms_output.put_line('  -> Item Ordered               : '||p_item_ordered);
      dbms_output.put_line('  -> Qty Ordered                : '||p_quantity_ordered);
      dbms_output.put_line('  -> Order Qty UOM              : '||p_order_quantity_uom);
      dbms_output.put_line('  -> Customer Number            : '||p_customer_number);
      dbms_output.put_line('  -> Ship To Location           : '||p_ship_to_loc);
      dbms_output.put_line('  -> Postal Code                : '||p_postal_code);
      dbms_output.put_line('  -> Request Current Date Time  : '||p_current_date_time);
      dbms_output.put_line('  -> Request Timezone code      : '||p_timezone_code);
      dbms_output.put_line('  -> Requested Date             : '||p_requested_date);
      dbms_output.put_line('  -> Order Type                 : '||p_order_type);
      dbms_output.put_line('  -> Ship Method                : '||p_ship_method);
      dbms_output.put_line('  -> Ship From Org              : '||p_ship_from_org);
      dbms_output.put_line('  -> Operating Unit             : '||p_operating_unit);
      dbms_output.put_line('  ============================================================');
      
      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_PREPROCESS_PKG.ATP_Pre_Process() ...');
         MSC_SCH_WB.ATP_Debug('  ============================================================');
         MSC_SCH_WB.ATP_Debug('  ->               INPUT PARAMETERS                           ');
         MSC_SCH_WB.ATP_Debug('  ============================================================');
         MSC_SCH_WB.ATP_Debug('  -> Item Ordered               : '||p_item_ordered);
         MSC_SCH_WB.ATP_Debug('  -> Qty Ordered                : '||p_quantity_ordered);
         MSC_SCH_WB.ATP_Debug('  -> Order Qty UOM              : '||p_order_quantity_uom);
         MSC_SCH_WB.ATP_Debug('  -> Customer Number            : '||p_customer_number);
         MSC_SCH_WB.ATP_Debug('  -> Ship To Location           : '||p_ship_to_loc);
         MSC_SCH_WB.ATP_Debug('  -> Postal Code                : '||p_postal_code);
         MSC_SCH_WB.ATP_Debug('  -> Request Current Date Time  : '||p_current_date_time);
         MSC_SCH_WB.ATP_Debug('  -> Request Timezone code      : '||p_timezone_code);
         MSC_SCH_WB.ATP_Debug('  -> Requested Date             : '||p_requested_date);
         MSC_SCH_WB.ATP_Debug('  -> Order Type                 : '||p_order_type);
         MSC_SCH_WB.ATP_Debug('  -> Ship Method                : '||p_ship_method);
         MSC_SCH_WB.ATP_Debug('  -> Ship From Org              : '||p_ship_from_org);
         MSC_SCH_WB.ATP_Debug('  -> Operating Unit             : '||p_operating_unit);
         MSC_SCH_WB.ATP_Debug('  ============================================================');
      END IF;

      Pre_Processing
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
            x_base_org              => x_base_org,
            x_base_org_id           => x_base_org_id,
            x_sr_item_id            => x_sr_item_id,
            x_order_flow_type       => x_order_flow_type,
            x_atp_types             => x_atp_types,
            x_assignment_set_id     => x_assignment_set_id,
            x_item_val_org          => x_item_val_org,
            x_category_set_id       => x_category_set_id,
            x_category_name         => x_category_name,
            x_zone_id               => x_zone_id,
            x_xref_item             => x_xref_item,
            x_xref_sr_item_id       => x_xref_sr_item_id,
            x_pickup                => x_pickup,
            x_bulk                  => x_bulk,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
         );


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Return Status: '||x_return_status);
         MSC_SCH_WB.ATP_Debug('  -> Message: '||x_msg);
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_PREPROCESS_PKG.ATP_Pre_Process() ...');
      END IF;
      

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Preprocess_Pkg.ATP_Pre_Process()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END ATP_Pre_Process;

END XX_MSC_SOURCING_PREPROCESS_PKG;
/
