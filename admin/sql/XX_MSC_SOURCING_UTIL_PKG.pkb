CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_UTIL_PKG AS

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


   CUSTOMER_PARTNER_TYPE       CONSTANT  INTEGER := 2;

   PROCEDURE Get_Customer_Partner_ID
      (
          p_partner_number      IN  MSC_TRADING_PARTNERS.partner_number%Type,
          x_partner_id          OUT MSC_TRADING_PARTNERS.partner_id%Type,
          x_return_status       OUT VARCHAR2,
          x_msg                 OUT VARCHAR2
      ) AS

      CURSOR c_cust (c_partner_number MSC_TRADING_PARTNERS.partner_number%Type) IS
         SELECT partner_id 
         FROM   msc_trading_partners
         WHERE  partner_number = c_partner_number
         AND    partner_type = CUSTOMER_PARTNER_TYPE
         AND    sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    disable_date IS Null
         AND    Nvl(status, 'A') = 'A';

   BEGIN

      x_return_status := 'S';

      OPEN  c_cust (p_partner_number);
      FETCH c_cust INTO x_partner_id;
      CLOSE c_cust;

      IF x_partner_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine Partner ID on planning instance. (PARTNER NUMBER:'||p_partner_number||')';
         Return;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_Customer_Partner_ID()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Get_Customer_Partner_ID;

   PROCEDURE Get_Customer_Number
      (
          p_customer_id         IN  RA_CUSTOMERS.customer_id%Type,
          x_customer_number     OUT RA_CUSTOMERS.customer_number%Type,
          x_return_status       OUT VARCHAR2,
          x_msg                 OUT VARCHAR2
      ) AS

      CURSOR c_cust (c_customer_id RA_CUSTOMERS.customer_id%Type) IS
         SELECT customer_number
         FROM   ra_customers
         WHERE  customer_id = c_customer_id
         AND    status = 'A';

   BEGIN

      x_return_status := 'S';

      OPEN  c_cust (p_customer_id);
      FETCH c_cust INTO x_customer_number;
      CLOSE c_cust;

      IF x_customer_number IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine Customer Number. (CUSTOMER ID:'||p_customer_id||')';
         Return;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_Customer_Number()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Get_Customer_Number;

   PROCEDURE Check_If_XDock_Can_Ship_Direct
     (
        p_organization_id         IN  MTL_PARAMETERS_VIEW.organization_id%Type,
        x_ship_from_xdock_org     OUT VARCHAR2,
        x_return_status           OUT VARCHAR2,
        x_msg                     OUT VARCHAR2
     ) AS

     l_delivery_code     XX_INV_ORG_LOC_RMS_ATTRIBUTE.od_delivery_cd_sw%Type;
     l_pickup_cutoff     XX_INV_ORG_LOC_RMS_ATTRIBUTE.pickup_delivery_cutoff_sw%Type; 
     l_sameday_cutoff    XX_INV_ORG_LOC_RMS_ATTRIBUTE.sameday_delivery_sw%Type; 
     l_furniture_cutoff  XX_INV_ORG_LOC_RMS_ATTRIBUTE.furniture_cutoff_sw%Type;

   BEGIN

      x_return_status := 'S';

      Get_Org_Attributes
        (
           p_organization_id      => p_organization_id,
           x_delivery_code        => l_delivery_code,
           x_pickup_cutoff        => l_pickup_cutoff,
           x_sameday_cutoff       => l_sameday_cutoff,
           x_furniture_cutoff     => l_furniture_cutoff,
           x_return_status        => x_return_status,
           x_msg                  => x_msg
        );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;
    

      IF l_delivery_code IS Null THEN
         x_ship_from_xdock_org := 'N';
      ELSE
         x_ship_from_xdock_org := 'Y';
      END IF;

   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Check_If_XDock_Can_Ship_Direct()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Check_If_XDock_Can_Ship_Direct;

   PROCEDURE Get_ATP_Order_Flow_Types 
      (
         x_flow_types            OUT XX_MSC_Sourcing_Util_Pkg.ATP_Order_Flow_Typ,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2 
      ) AS

   CURSOR c_vset IS
      SELECT flex_value_set_id
      FROM   fnd_flex_vset_v
      WHERE  parent_value_set_name = 'XX_MSC_ATP_ORDER_FLOW_TYPES';

   CURSOR c_flex (c_flex_value_set_id  FND_FLEX_VSET_V.flex_value_set_id%Type) IS
      SELECT flex_value,
             attribute1,           -- precedence
             attribute2            -- function name
      FROM   fnd_flex_values_vl
      WHERE  enabled_flag = 'Y'
      AND    Sysdate BETWEEN Nvl(start_date_active, Sysdate) AND Nvl(end_date_active, sysdate+1)
      AND    flex_value_set_id = c_flex_value_set_id
      ORDER  BY To_Number(attribute1);
   

   l_flex_value_set_id    FND_FLEX_VSET_V.flex_value_set_id%Type;
   l_flex_value           FND_FLEX_VALUES_VL.flex_value%Type;
   l_function             FND_FLEX_VALUES_VL.attribute2%Type;
   i                      NUMBER := 0;

   BEGIN

      x_return_status := 'S';

      OPEN c_vset;
      FETCH c_vset INTO l_flex_value_set_id;
      CLOSE c_vset;

      IF l_flex_value_set_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Value Set for ATP Order Flow Types does not exists';
         Return;
      END IF;

      FOR c_flex_rec IN c_flex(l_flex_value_set_id) LOOP

         i := i+1;

         x_flow_types.atp_flow_name.extend(1);
         x_flow_types.atp_flow_seq.extend(1);
         x_flow_types.atp_flow_func.extend(1);
         
         x_flow_types.atp_flow_name(i) := c_flex_rec.flex_value;
         x_flow_types.atp_flow_seq(i)  := c_flex_rec.attribute1;
         x_flow_types.atp_flow_func(i) := c_flex_rec.attribute2;

      END LOOP;

      IF x_flow_types.atp_flow_name.count = 0 THEN
         x_return_status := 'E';
         x_msg := 'No Order Flow Type exists in Value Set "XX MSC ATP Order Flow Types"';
         Return;

      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_ATP_Order_Flow_Types()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_ATP_Order_Flow_Types;

   PROCEDURE Get_Assignment_Set
      (
         x_assignment_set_id    OUT MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         x_return_status        OUT VARCHAR2,
         x_msg                  OUT VARCHAR2
      ) AS

   BEGIN

      x_return_status := 'S'; 

      x_assignment_set_id := FND_PROFILE.Value('MSC_ATP_ASSIGN_SET');

      IF x_assignment_set_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'No value in profile "MSC:ATP Assignment Set"';
         Return;

      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_Assignment_Set()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Assignment_Set;

   PROCEDURE Get_Item_Validation_Org
      (
         x_item_val_org          OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      ) AS

   BEGIN

      x_return_status := 'S'; 

      -- x_item_val_org := FND_PROFILE.Value_wnps('SO_ORGANIZATION_ID');
      x_item_val_org := FND_PROFILE.Value('SO_ORGANIZATION_ID');

      IF x_item_val_org IS Null THEN
         x_return_status := 'E';
         x_msg := 'No value in profile "OE: Item Validation Organization"';
         Return;

      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_Item_Validation_Org()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Item_Validation_Org;

   PROCEDURE Get_Category_Set_ID
      (
         x_category_set_id OUT MSC_CATEGORY_SETS.category_set_id%Type,
         x_return_status   OUT VARCHAR2,
         x_msg             OUT VARCHAR2
      ) AS

      CURSOR c_cat_set IS
         SELECT category_set_id
         FROM   msc_category_sets
         WHERE  category_set_name = 'ATP_CATEGORY'
         AND    sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID;

   BEGIN

      x_return_status := 'S';

      OPEN  c_cat_set;
      FETCH c_cat_set INTO x_category_set_id;
      CLOSE c_cat_set;

      IF x_category_set_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine category set ID for ATP Planning Category';

      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_Category_Set_ID()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Category_Set_ID;

   PROCEDURE Get_Location_From_Org
      (
         p_organization_id       IN  MSC_LOCATION_ASSOCIATIONS.organization_id%Type,
         x_location_id           OUT MSC_LOCATION_ASSOCIATIONS.location_id%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      ) AS

      CURSOR c_loc (c_org_id     MSC_LOCATION_ASSOCIATIONS.organization_id%Type) IS
         SELECT location_id
         FROM   msc_location_associations
         WHERE  organization_id = c_org_id
         AND    sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID;

   BEGIN

      x_return_status := 'S';  

      OPEN  c_loc (p_organization_id);
      FETCH c_loc INTO x_location_id;
      CLOSE c_loc;

      IF x_location_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot get Location ID from Org ID. (ORG ID:'||p_organization_id||')';
         Return;

      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_Location_From_Org()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Location_From_Org;

   PROCEDURE Get_Org_From_Location
      (
          p_loc_id    IN  MSC_LOCATION_ASSOCIATIONS.location_id%Type,
          x_org_id    OUT MSC_LOCATION_ASSOCIATIONS.organization_id%Type,
          x_return_status       OUT VARCHAR2,
          x_msg                 OUT VARCHAR2
      ) AS

      CURSOR c_org (c_loc_id MTL_INTERORG_SHIP_METHODS.from_location_id%Type) IS
         SELECT organization_id
         FROM   msc_location_associations
         WHERE  location_id = c_loc_id
         AND    sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID;

   BEGIN

      x_return_status := 'S';

      OPEN  c_org (p_loc_id);
      FETCH c_org INTO x_org_id;
      CLOSE c_org;

      IF x_org_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine Org ID from location ID. (LOC ID:'||p_loc_id||')';
         Return;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_Org_From_Location()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Get_Org_From_Location;

   PROCEDURE Get_Org_Type
      (
         p_organization_id       IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         x_org_type              OUT HR_ORGANIZATION_UNITS.type%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       ) AS

      CURSOR c_typ (c_organization_id MTL_PARAMETERS_VIEW.organization_id%Type) IS
         SELECT type
         FROM   hr_organization_units
         WHERE  organization_id = c_organization_id;

   BEGIN

      x_return_status := 'S';

      OPEN  c_typ (p_organization_id);
      FETCH c_typ INTO x_org_type;
      CLOSE c_typ;

      IF x_org_type IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine Org type. (ORGANIZATION ID:'||p_organization_id||')';
         Return;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_Org_Type()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Get_Org_Type;

   PROCEDURE Get_Item_Attributes
     (
        p_inventory_item_id               IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
        p_organization_id                 IN  MTL_PARAMETERS_VIEW.organization_id%Type,
        x_item_xdock_sourceable           OUT VARCHAR2,
        x_item_replenishable_type         OUT XX_INV_ITMS_ORG_ATTR_V.od_replen_type_cd%Type,
        x_item_replenishable_subtype      OUT XX_INV_ITMS_ORG_ATTR_V.od_replen_sub_type_cd%Type,
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     )  AS

      CURSOR c_attr (c_inventory_item_id  MTL_CROSS_REFERENCES_V.inventory_item_id%Type,
                     c_organization_id    MTL_PARAMETERS_VIEW.organization_id%Type) IS
         SELECT 'Y', od_replen_type_cd, od_replen_sub_type_cd                               -- ???? XDock Sourceable to change
         FROM   xx_inv_itms_org_attr_v
         WHERE  organization_id = c_organization_id
         AND    inventory_item_id = c_inventory_item_id;


   BEGIN

      x_return_status := 'S';

      OPEN  c_attr (p_inventory_item_id, p_organization_id);
      FETCH c_attr INTO x_item_xdock_sourceable, x_item_replenishable_type, x_item_replenishable_subtype;
      CLOSE c_attr;
    


   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_Item_Attributes()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Item_Attributes;

   PROCEDURE Get_Org_Attributes
     (
        p_organization_id                 IN  MTL_PARAMETERS_VIEW.organization_id%Type,
        x_delivery_code                   OUT XX_INV_ORG_LOC_RMS_ATTRIBUTE.od_delivery_cd_sw%Type,
        x_pickup_cutoff                   OUT XX_INV_ORG_LOC_RMS_ATTRIBUTE.pickup_delivery_cutoff_sw%Type,
        x_sameday_cutoff                  OUT XX_INV_ORG_LOC_RMS_ATTRIBUTE.sameday_delivery_sw%Type,
        x_furniture_cutoff                OUT XX_INV_ORG_LOC_RMS_ATTRIBUTE.furniture_cutoff_sw%Type, 
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     )  AS

      CURSOR c_attr (c_organization_id MTL_PARAMETERS_VIEW.organization_id%Type) IS
         SELECT od_delivery_cd_sw,
                pickup_delivery_cutoff_sw, 
                sameday_delivery_sw, 
                furniture_cutoff_sw
         FROM   mtl_parameters_view mpv,
                xx_inv_org_loc_rms_attribute xiv
         WHERE  mpv.attribute6 = xiv.combination_id
         AND    mpv.organization_id = c_organization_id
         AND    Nvl(xiv.enabled_flag, 'Y') = 'Y'
         AND    Trunc(Sysdate) BETWEEN Nvl(Trunc(xiv.start_date_active), Trunc(Sysdate)) 
                   AND Nvl(Trunc(xiv.end_date_active), Trunc(Sysdate)+1);


   BEGIN

      x_return_status := 'S';

      OPEN  c_attr (p_organization_id);
      FETCH c_attr INTO x_delivery_code, x_pickup_cutoff,
                        x_sameday_cutoff, x_furniture_cutoff;
      CLOSE c_attr;
    


   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_Org_Attributes()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Org_Attributes;

   PROCEDURE Validate_Operating_Unit
     (
        p_operating_unit     IN  HR_OPERATING_UNITS.organization_id%Type,
        x_return_status      OUT VARCHAR2,
        x_msg                OUT VARCHAR2
     )   AS

      CURSOR c_org IS
         SELECT organization_id 
         FROM   hr_operating_units
         WHERE  organization_id = p_operating_unit;

      l_org_id   HR_OPERATING_UNITS.organization_id%Type; 


   BEGIN

      x_return_status := 'S';

      OPEN  c_org;
      FETCH c_org INTO l_org_id;
      CLOSE c_org;

      IF l_org_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Not a valid Operating Unit';
         Return;
      END IF;
    


   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Validate_Operating_Unit()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Validate_Operating_Unit;


   PROCEDURE Get_Item_Name
     (
        p_inventory_item_id               IN  MTL_SYSTEM_ITEMS_B.inventory_item_id%Type,
        p_organization_id                 IN  MTL_SYSTEM_ITEMS_B.organization_id%Type,
        x_item                            OUT MTL_SYSTEM_ITEMS_B.segment1%Type,
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     )  AS

      CURSOR c_itm (c_inventory_item_id MTL_SYSTEM_ITEMS_B.inventory_item_id%TYpe,
                    c_organization_id   MTL_SYSTEM_ITEMS_B.organization_id%Type) IS
         SELECT segment1
         FROM   mtl_system_items_b
         WHERE  inventory_item_id = c_inventory_item_id
         AND    organization_id = c_organization_id;


   BEGIN

      x_return_status := 'S';

      OPEN  c_itm (p_inventory_item_id, p_organization_id);
      FETCH c_itm INTO x_item;
      CLOSE c_itm;

      IF x_item IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine item name. (INVENTORY ITEM ID: '||p_inventory_item_id||
                                                ' ORGANIZATION ID: '||p_organization_id||')';
         Return;
      END IF;
    


   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_Item_Name()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Item_Name;

   PROCEDURE Get_VM_Indicator
     (
        p_customer_number                 IN  MSC_TRADING_PARTNERS.partner_number%Type,
        x_vm_indicator                    OUT XX_PO_SSA_V.vm_indicator%Type,
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     )  AS

     CURSOR c_vm (c_customer_number MSC_TRADING_PARTNERS.partner_number%Type) IS
        SELECT s.attribute23
        FROM   ar_customers_v c, 
               ar_addresses_v a, 
               hz_site_uses_v s
        WHERE  a.address_id = s.address_id
        AND    a.customer_id = c.customer_id
        AND    a.status = 'A'
        AND    s.status = 'A'
        AND    c.status = 'A'
        AND    s.site_use_code = 'SHIP_TO'
        AND    c.customer_number = c_customer_number;

   BEGIN

      x_return_status := 'S';

      OPEN  c_vm (p_customer_number);
      FETCH c_vm INTO x_vm_indicator;
      CLOSE c_vm;

   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_VM_Indicator()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_VM_Indicator;

   PROCEDURE Get_IMU_Values
     (
        p_mlss_header_id                  IN  XX_PO_SSA_V.mlss_header_id%Type,
        x_imu_amt_pt                      OUT XX_PO_MLSS_HDR.imu_amt_pt%Type,
        x_imu_value                       OUT XX_PO_MLSS_HDR.imu_value%Type,
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     ) AS

      CURSOR c_imu IS
         SELECT hdr.imu_amt_pt, 
                hdr.imu_value
         FROM   xx_po_mlss_hdr hdr
         WHERE  Trunc(Sysdate) BETWEEN Nvl(Trunc(start_date), Trunc(Sysdate)) AND Nvl(Trunc(end_date), Trunc(sysdate) + 1)
         AND    hdr.mlss_header_id = p_mlss_header_id;

   BEGIN

      x_return_status := 'S';

      OPEN c_imu;
      FETCH c_imu INTO x_imu_amt_pt, x_imu_value;
      CLOSE c_imu;

   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_IMU_Values()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_IMU_Values;

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
     ) AS

      CURSOR c_imu (c_mlss_header_id XX_PO_MLSS_HDR.mlss_header_id%Type) IS
         SELECT imu_amt_pt, imu_value
         FROM   xx_po_mlss_hdr
         WHERE  mlss_header_id = c_mlss_header_id
         AND    Trunc(Sysdate) BETWEEN Nvl(start_date, Trunc(Sysdate)) AND Nvl(end_date, Trunc(Sysdate+1));
 

      CURSOR c_cost (c_vendor_id PO_HEADERS_ALL.po_header_id%Type,
                     c_vendor_site_id PO_HEADERS_ALL.po_header_id%type,
                     c_item_id PO_LINES_ALL.item_id%Type,
                     c_operating_unit HR_OPERATING_UNITS.organization_id%Type) IS
         SELECT pol.unit_price
         FROM   po_headers_all poh,
                po_lines_all pol
         WHERE  poh.po_header_id = pol.po_header_id
         AND    poh.type_lookup_code = 'QUOTATION'
         AND    poh.enabled_flag = 'Y'
         AND    poh.org_id = c_operating_unit
         AND    Trunc(Sysdate) BETWEEN Nvl(poh.start_date, Trunc(Sysdate)) 
                AND Nvl(poh.end_date, Trunc(Sysdate)+1)
         AND    poh.status_lookup_code  = 'A'
         AND    Nvl(poh.cancel_flag, 'Y') = 'Y'
         AND    Nvl(pol.cancel_flag, 'Y') = 'Y'
         AND    pol.org_id = c_operating_unit
         AND    poh.vendor_id = c_vendor_id
         AND    poh.vendor_site_id = c_vendor_site_id
         AND    pol.item_id = c_item_id
         ORDER BY pol.creation_date DESC;

      l_wholesaler_cost     NUMBER;
      l_primary_vendor_cost NUMBER;
      l_imu_amt_pt          XX_PO_MLSS_HDR.imu_amt_pt%Type;
      l_imu_value           XX_PO_MLSS_HDR.imu_value%Type;

   
   BEGIN

      x_return_status := 'S';

      OPEN c_imu (p_mlss_header_id);
      FETCH c_imu INTO l_imu_amt_pt, l_imu_value;
      CLOSE c_imu;

      IF l_imu_amt_pt IS Null OR l_imu_value IS Null THEN
         x_imu_check := 'Accept';
         Return;
      END IF;

      -- Get wholesaler cost
      OPEN c_cost (p_vendor_id, p_vendor_site_id, p_item_id, p_operating_unit);
      FETCH c_cost INTO l_wholesaler_cost;
      CLOSE c_cost;  

      /*
      dbms_output.put_line('  -> Wholesaler cost: '||l_wholesaler_cost);
      dbms_output.put_line('  -> IMU PCT: '||l_imu_amt_pt); 
      */ 

      IF l_imu_amt_pt = 'P' THEN

         IF (Nvl(p_unit_selling_price, 0) - Nvl(l_wholesaler_cost, 0))/p_unit_selling_price < l_imu_value/100 THEN
            x_imu_check := 'Reject';
            Return;
         ELSE
            x_imu_check := 'Accept';
            Return;
         END IF;

      ELSE

         IF p_primary_vendor_site_id IS Null THEN
            x_imu_check := 'Reject';
            Return;
         END IF;

         -- Get primary vendor cost
         OPEN c_cost (p_primary_vendor_id, p_primary_vendor_site_id, p_item_id, p_operating_unit);
         FETCH c_cost INTO l_primary_vendor_cost;
         CLOSE c_cost;

         /*
         dbms_output.put_line('  -> Primary Vendor Cost: '||l_primary_vendor_cost);
         */

         IF (Nvl(l_wholesaler_cost, 0) - Nvl(l_primary_vendor_cost, 0)) * p_quantity_ordered < l_imu_value THEN
            x_imu_check := 'Accept';
            Return;
         ELSE
            x_imu_check := 'Reject';
            Return;
         END IF;

      END IF;    

   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Do_IMU_Check()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Do_IMU_Check;

   
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
     ) AS

      CURSOR c_mls IS
         SELECT det.supply_loc_no, 
                det.ds_lt,
                det.b2b_lt,
                det.end_point,
                det.supp_facility_cd,
                det.supp_loc_ac
         FROM   xx_po_mlss_hdr hdr,
                xx_po_mlss_det det
         WHERE  hdr.mlss_header_id = det.mlss_header_id
         AND    (Nvl(det.end_point, 'B') = 'B' OR Nvl(det.end_point, 'B') = Nvl(p_end_point, end_point))
         AND    Trunc(Sysdate) BETWEEN Nvl(Trunc(hdr.start_date), Trunc(Sysdate)) AND Nvl(Trunc(hdr.end_date), Trunc(sysdate) + 1)
         AND    hdr.mlss_header_id = p_mlss_header_id
         ORDER BY det.rank ASC;

   BEGIN

      x_return_status := 'S';

      OPEN c_mls;
      FETCH c_mls INTO x_supply_loc_no, 
                       x_mlss_ds_lt, 
                       x_mlss_b2b_lt,
                       x_end_point, 
                       x_vendor_facility_code, 
                       x_vendor_account ;
      CLOSE c_mls;

   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Util_Pkg.Get_MLS_Details()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_MLS_Details;


END XX_MSC_SOURCING_UTIL_PKG;
/
