CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_QUERY_QTY_PKG AS

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
      ) AS

      CURSOR c_oh (c_base_org_id MTL_PARAMETERS_VIEW.organization_id%Type,
                   c_inventory_item_id MTL_SYSTEM_ITEMS_B.inventory_item_id%Type) IS
         SELECT Sum(oh.transaction_quantity)
         FROM   mtl_onhand_quantities_detail oh,
                mtl_secondary_inventories sub             
         WHERE  oh.inventory_item_id = c_inventory_item_id
         AND    oh.organization_id = c_base_org_id
         AND    oh.subinventory_code = sub.secondary_inventory_name
         AND    oh.organization_id = sub.organization_id
         AND    sub.availability_type = 1
         AND    sub.inventory_atp_code = 1
         AND    Trunc(Sysdate) < Nvl(sub.disable_date, Sysdate+1);

      CURSOR c_dmd1 (c_base_org_id MTL_PARAMETERS_VIEW.organization_id%Type,
                   c_inventory_item_id MTL_SYSTEM_ITEMS_B.inventory_item_id%Type) IS
         SELECT SUM(DECODE(ool.ordered_quantity, Null, 0,
                   INV_DECIMALS_PUB.Get_Primary_Quantity
                      (
                         ool.ship_from_org_id,
                         ool.inventory_item_id, 
                         ool.order_quantity_uom, 
                         ool.ordered_quantity
                      )))
                              -
                SUM(DECODE(ool.shipped_quantity,Null,0,
                   INV_DECIMALS_PUB.Get_Primary_Quantity
                      (
                         ool.ship_from_org_id, 
                         ool.inventory_item_id, 
                         ool.order_quantity_uom, 
                         ool.shipped_quantity
                      )))
         FROM  oe_order_lines_all ool
         WHERE OE_INSTALL.Get_Active_Product = 'ONT'
         AND   ool.ship_from_org_id = c_base_org_id
         AND   ool.inventory_item_id = c_inventory_item_id
         AND   DECODE(ool.source_document_type_id, 10, 8,DECODE(ool.line_category_code, 'ORDER', 2, 12)) = 2
         AND   ool.visible_demand_flag = 'Y'
         AND   ool.subinventory IS Null;


      CURSOR c_dmd2 (c_base_org_id MTL_PARAMETERS_VIEW.organization_id%Type,
                   c_inventory_item_id MTL_SYSTEM_ITEMS_B.inventory_item_id%Type) IS
         SELECT SUM(DECODE(ool.ordered_quantity, Null, 0,
                   INV_DECIMALS_PUB.Get_Primary_Quantity
                      (
                         ool.ship_from_org_id,
                         ool.inventory_item_id, 
                         ool.order_quantity_uom, 
                         ool.ordered_quantity
                      )))
                              -
                SUM(DECODE(ool.shipped_quantity,Null,0,
                   INV_DECIMALS_PUB.Get_Primary_Quantity
                      (
                         ool.ship_from_org_id, 
                         ool.inventory_item_id, 
                         ool.order_quantity_uom, 
                         ool.shipped_quantity
                      )))
         FROM  oe_order_lines_all ool,
               mtl_secondary_inventories sub
         WHERE OE_INSTALL.Get_Active_Product = 'ONT'
         AND   ool.inventory_item_id = c_inventory_item_id
         AND   ool.ship_from_org_id = c_base_org_id
         AND   ool.subinventory = sub.secondary_inventory_name
         AND   ool.ship_from_org_id = sub.organization_id
         AND   sub.availability_type = 1
         AND   sub.inventory_atp_code = 1
         AND   DECODE(ool.source_document_type_id, 10, 8,DECODE(ool.line_category_code, 'ORDER', 2, 12)) = 2
         AND   ool.visible_demand_flag = 'Y'
         AND   Trunc(Sysdate) < Nvl(sub.disable_date, Sysdate + 1);

      -- demand from AOPS
      CURSOR c_dmd3 (c_base_org_id MTL_PARAMETERS_VIEW.organization_id%Type,
                   c_inventory_item_id MTL_SYSTEM_ITEMS_B.inventory_item_id%Type) IS
         SELECT Sum(primary_uom_quantity)
         FROM   mtl_demand
         WHERE  organization_id = c_base_org_id
         AND    inventory_item_id = c_inventory_item_id
         AND    reservation_type = 1
         AND    demand_source_type = p_aops_source_type_id; 
         
      l_oh                    NUMBER;   
      l_dmd1                  NUMBER;
      l_dmd2                  NUMBER;
      l_dmd3                  NUMBER;
      l_qty                   NUMBER;
      l_base_org              MTL_PARAMETERS_VIEW.organization_code%Type;
      l_base_org_id           MTL_PARAMETERS_VIEW.organization_id%Type;
      l_postal_code           WSH_ZONE_REGIONS_V.postal_code_from%Type;
      l_planning_item_id      MSC_SYSTEM_ITEMS.inventory_item_id%Type;
      l_assignment_set_id     MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type;
      l_item_val_org          MTL_PARAMETERS_VIEW.organization_id%Type;
      l_category_set_id       MSC_CATEGORY_SETS.category_set_id%Type;
      l_category_name         MSC_ITEM_CATEGORIES.category_name%Type;
      l_sr_inventory_item_id  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type;
 
   BEGIN

      x_return_status := 'S';

      FND_CLIENT_INFO.Set_Org_Context(p_operating_unit);

      IF p_ship_to_loc IS Null AND p_postal_code IS Null THEN
         x_return_status := 'E';
         x_msg := 'Need postal code or ship to location';
         Return;
      END IF;

      -- dbms_output.put_line('Postal Code: '||p_postal_code);
      -- dbms_output.put_line('Ship to Location: '||p_ship_to_loc);

      IF p_postal_code IS Null THEN
         
         XX_MSC_SOURCING_PARAMS_PKG.Get_Postal_Code
            (
               p_ship_to_loc        => p_ship_to_loc,
               x_postal_code        => l_postal_code,
               x_return_status      => x_return_status,
               x_msg                => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

      END IF;

      -- dbms_output.put_line('Postal Code: '||l_postal_code);

      XX_MSC_SOURCING_UTIL_PKG.Get_Assignment_Set
         (
            x_assignment_set_id    => l_assignment_set_id,
            x_return_status        => x_return_status,
            x_msg                  => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      -- dbms_output.put_line('Assignment Set ID: '||l_assignment_set_id);

      XX_MSC_SOURCING_UTIL_PKG.Get_Item_Validation_Org
         (
            x_item_val_org        => l_item_val_org,
            x_return_status       => x_return_status,
            x_msg                 => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      -- dbms_output.put_line('Item Validation Org: '||l_item_val_org);

      XX_MSC_SOURCING_UTIL_PKG.Get_Category_Set_ID
         (
            x_category_set_id    => l_category_set_id,
            x_return_status      => x_return_status,
            x_msg                => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      -- dbms_output.put_line('Category Set ID: '||l_category_set_id);

      XX_MSC_SOURCING_PARAMS_PKG.Get_Item_ID
         (
             p_item_name            => p_item_ordered,
             p_organization_id      => l_item_val_org,
             x_item_id              => l_planning_item_id, 
             x_sr_item_id           => l_sr_inventory_item_id,
             x_return_status        => x_return_status,
             x_msg                  => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      -- dbms_output.put_line('Planning Item ID: '||l_planning_item_id);
      -- dbms_output.put_line('Sr Inventory Item ID: '||l_sr_inventory_item_id);

      XX_MSC_SOURCING_PARAMS_PKG.Get_Category_Name
         (
            p_item_id             => l_planning_item_id,
            p_org_id              => l_item_val_org,
            p_category_set_id     => l_category_set_id,
            x_category_name       => l_category_name,
            x_return_status       => x_return_status,
            x_msg                 => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      -- dbms_output.put_line('Category Name: '||l_category_name);
      -- dbms_output.put_line('Postal Code: '||Nvl(p_postal_code, l_postal_code));

      XX_MSC_SOURCING_SR_ORG_PKG.Get_Base_Org_From_SR
         (
            p_postal_code           => Nvl(p_postal_code, l_postal_code),
            p_item                  => p_item_ordered,
            p_assignment_set_id     => l_assignment_set_id, 
            p_item_val_org          => l_item_val_org,
            p_category_set_id       => l_category_set_id,
            p_category_name         => l_category_name, 
            x_base_org              => l_base_org,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      -- dbms_output.put_line('Base Org: '||l_base_org);

      XX_MSC_SOURCING_PARAMS_PKG.Get_Org_ID
         (
            p_base_org              => l_base_org,
            x_organization_id       => l_base_org_id,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
          );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      OPEN c_oh (l_base_org_id, l_sr_inventory_item_id);
      FETCH c_oh INTO l_oh;
      CLOSE c_oh;

      -- dbms_output.put_line('OH Qty: '||l_oh);

      OPEN c_dmd1 (l_base_org_id, l_sr_inventory_item_id);
      FETCH c_dmd1 INTO l_dmd1;
      CLOSE c_dmd1;

      -- dbms_output.put_line('Demand qty 1: '||l_dmd1);

      OPEN c_dmd2 (l_base_org_id, l_sr_inventory_item_id);
      FETCH c_dmd2 INTO l_dmd2;
      CLOSE c_dmd2;

      -- dbms_output.put_line('Demand qty 2: '||l_dmd2);

      OPEN c_dmd3 (l_base_org_id, l_sr_inventory_item_id);
      FETCH c_dmd3 INTO l_dmd3;
      CLOSE c_dmd3;

      -- dbms_output.put_line('Demand qty 3: '||l_dmd3);

      x_qty := Nvl(l_oh, 0) - (Nvl(l_dmd1, 0) + Nvl(l_dmd2, 0)) - Nvl(l_dmd3, 0);
      x_source_org_id := l_base_org_id;
      x_source_org := l_base_org;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Query_Qty_Pkg.Query_Qty()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Query_Qty;

END XX_MSC_SOURCING_QUERY_QTY_PKG;
/
