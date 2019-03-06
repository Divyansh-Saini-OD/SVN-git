CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_PARAMS_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_PARAMS_PKG                                        |
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



   PROCEDURE Get_Forced_Substitute
      (
         p_inventory_item_id     IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_organization_id       IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         x_xref_item             OUT MTL_CROSS_REFERENCES_V.cross_reference%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      ) AS

      CURSOR c_xref (c_inventory_item_id  MTL_CROSS_REFERENCES_V.inventory_item_id%Type,
                     c_base_org_id        MTL_PARAMETERS_VIEW.organization_id%Type) IS
         SELECT cross_reference 
         FROM   mtl_cross_references_v
         WHERE  cross_reference_type = 'XX_GI_FORCED_SUB'
         AND    Nvl(organization_id, c_base_org_id) = c_base_org_id
         AND    inventory_item_id = c_inventory_item_id;


   BEGIN

      x_return_status := 'S';

      OPEN  c_xref (p_inventory_item_id, p_organization_id);
      FETCH c_xref INTO x_xref_item;
      CLOSE c_xref;
    


   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Get_Forced_Substitute()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Forced_Substitute;

   PROCEDURE Get_Org_From_Cust_Setup
      (
         p_customer_number       IN  RA_CUSTOMERS.customer_number%Type,
         x_org                   OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      ) AS

      l_org_id                   MTL_PARAMETERS_VIEW.organization_id%Type;
      l_org_code                 MTL_PARAMETERS_VIEW.organization_code%Type;
      l_customer_number          AR_CUSTOMERS_V.customer_number%Type;

      CURSOR c_whse (c_customer_number RA_CUSTOMERS.customer_number%Type) IS
         SELECT customer_number, warehouse_id
         FROM   ar_customers_v
         WHERE  customer_number = c_customer_number;

      CURSOR c_org_code (c_org_id MTL_PARAMETERS_VIEW.organization_id%Type) IS
         SELECT organization_code
         FROM   mtl_parameters_view
         WHERE  organization_id = c_org_id;


   BEGIN

      x_return_status := 'S';

      OPEN  c_whse (p_customer_number);
      FETCH c_whse INTO l_customer_number, l_org_id;
      CLOSE c_whse;

      IF l_customer_number IS Null THEN
         x_return_status := 'E';
         x_msg := 'Invalid -or- No Customer Number';
         Return;
      END IF;

      IF l_org_id IS Null THEN
         x_org := Null;
         x_return_status := 'S';
         Return;

      ELSE

         OPEN  c_org_code (l_org_id);
         FETCH c_org_code INTO l_org_code;
         CLOSE c_org_code;
         
         x_org := l_org_code;
         x_return_status := 'S';
         Return;

      END IF;

   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Get_Org_From_Cust_Setup()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Org_From_Cust_Setup;

   PROCEDURE Get_Category_Name
      (
         p_item_id         IN  MSC_SYSTEM_ITEMS.inventory_item_id%Type,
         p_org_id          IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_category_set_id IN  MSC_CATEGORY_SETS.category_set_id%Type,
         x_category_name   OUT MSC_ITEM_CATEGORIES.Category_name%Type,
         x_return_status   OUT VARCHAR2,
         x_msg             OUT VARCHAR2
      ) AS

      CURSOR c_cat (c_item_id          MSC_SYSTEM_ITEMS.inventory_item_id%Type,
                    c_org_id           MSC_SYSTEM_ITEMS.organization_id%Type,
                    c_category_set_id  MSC_CATEGORY_SETS.category_set_id%Type) IS
         SELECT category_name
         FROM   msc_item_categories
         WHERE  category_set_id = c_category_set_id
         AND    organization_id = c_org_id
         AND    inventory_item_id = c_item_id
         AND    sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID;

   BEGIN

      x_return_status := 'S';

      OPEN  c_cat(p_item_id, p_org_id, p_category_set_id);
      FETCH c_cat INTO x_category_name;
      CLOSE c_cat;

      IF x_category_name IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine category Name for ATP Planning Category. (ITEM ID:'||p_item_id||
                                                                            ', ORG ID:'||p_org_id ||
                                                                   ', CATEGORY_SET_ID:'||p_category_set_id||')';

      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Get_Category_Name()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Category_Name;

   PROCEDURE Get_Item_ID
      (
          p_item_name          IN  MSC_SYSTEM_ITEMS.item_name%Type,
          p_organization_id    IN  MSC_SYSTEM_ITEMS.organization_id%Type,
          x_item_id            OUT MSC_SYSTEM_ITEMS.inventory_item_id%Type,
          x_sr_item_id         OUT MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
          x_return_status      OUT VARCHAR2,
          x_msg                OUT VARCHAR2
      ) AS

      CURSOR c_itm (c_item_name   MSC_SYSTEM_ITEMS.item_name%Type,
                    c_org         MSC_SYSTEM_ITEMS.organization_id%Type) IS
         SELECT inventory_item_id, sr_inventory_item_id
         FROM   msc_system_items
         WHERE  item_name = c_item_name
         AND    plan_id = XX_MSC_SOURCING_UTIL_PKG.PLAN_ID
         AND    organization_id = c_org;

   BEGIN

      x_return_status := 'S';

      OPEN c_itm (p_item_name, p_organization_id);
      FETCH c_itm INTO x_item_id, x_sr_item_id;
      CLOSE c_itm;

      IF x_item_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Invalid Item -or- Item not assigned to Item validation Org. (ITEM NAME:'||p_item_name||' , ORG ID:'||p_organization_id||')';
         Return;

      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Org_Pkg.Get_Item_ID()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Item_ID;

   PROCEDURE Get_Org_ID
      (
         p_base_org              IN  MTL_PARAMETERS_VIEW.organization_code%Type,
         x_organization_id       OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      ) AS

      CURSOR c_org (c_org_code      MTL_PARAMETERS_VIEW.organization_code%Type) IS
         SELECT organization_id
         FROM   mtl_parameters_view
         WHERE  organization_code = c_org_code;

   BEGIN

      x_return_status := 'S';  

      OPEN  c_org (p_base_org);
      FETCH c_org INTO x_organization_id;
      CLOSE c_org;

      IF x_organization_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot get Org ID from Org Code. (ORG CODE:'||p_base_org||')';
         Return;

      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Get_Org_ID()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Org_ID;

   PROCEDURE Get_Zone
      (
         p_postal_code     IN  WSH_ZONE_REGIONS_V.postal_code_from%Type,
         p_category_name   IN  MSC_ITEM_CATEGORIES.category_name%Type,
         x_zone_id         OUT WSH_ZONE_REGIONS_V.zone_id%Type,
         x_return_status   OUT VARCHAR2,
         x_msg             OUT VARCHAR2
      ) AS

   BEGIN

      x_return_status := 'S';

      BEGIN

         SELECT z.parent_region_id zone_id
         INTO   x_zone_id	
         FROM   wsh_regions r, 
                wsh_regions_tl rt, 
                wsh_zone_regions z,
                wsh_regions p 
         WHERE  r.region_id = rt.region_id 
         AND    rt.language = USERENV('LANG') 
         AND    z.region_id = r.region_id
         AND    p_postal_code BETWEEN Nvl(rt.postal_code_from, rt.postal_code_to) 
                   AND Nvl(rt.postal_code_to, rt.postal_code_from)
         AND    z.parent_region_id = p.region_id
         AND    p.attribute1 = p_category_name;
         
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            x_return_status := 'E';
            x_msg := 'Cannot determine Zone from Postal code. (Postal Code:'||p_postal_code||')';
            Return;
         WHEN TOO_MANY_ROWS THEN
            x_return_status := 'E';
            x_msg := 'Too may zones for Postal code. (Postal Code:'||p_postal_code||')';
            Return;
      END;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Get_Zone()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Zone;

   PROCEDURE Get_Postal_Code
      (
         p_ship_to_loc        IN  HZ_CUST_SITE_USES_ALL.location%Type,
         x_postal_code        OUT WSH_ZONE_REGIONS_V.postal_code_from%Type,
         x_return_status      OUT VARCHAR2,
         x_msg                OUT VARCHAR2
      ) AS

      CURSOR c1 (c_location_code  HZ_CUST_SITE_USES_ALL.location%Type) IS
         SELECT cust_acct_site_id
         FROM   hz_cust_site_uses
         WHERE  location = c_location_code 
         AND    site_use_code = 'SHIP_TO'
         AND    status = 'A';

      CURSOR c2 (c_cust_acct_site_id HZ_CUST_SITE_USES_ALL.cust_acct_site_id%Type) IS
         SELECT party_site_id
         FROM   hz_cust_acct_sites
         WHERE  cust_acct_site_id = c_cust_acct_site_id
         AND    status = 'A';

      CURSOR c3 (c_party_site_id HZ_PARTY_SITES.party_site_id%Type) IS
        SELECT location_id
        FROM   hz_party_sites
        WHERE  party_site_id = c_party_site_id
        AND    status = 'A'
        AND    Sysdate BETWEEN Nvl(start_date_active, Sysdate) AND Nvl(end_date_active, Sysdate+1);

      CURSOR c4 (c_location_id HZ_LOCATIONS.location_id%Type) IS
         SELECT postal_code
         FROM   hz_locations
         WHERE  location_id = c_location_id;

      l_cust_acct_site_id  HZ_CUST_SITE_USES_ALL.cust_acct_site_id%Type;
      l_party_site_id      HZ_CUST_ACCT_SITES_ALL.party_site_id%Type;
      l_location_id        HZ_PARTY_SITES.location_id%Type;


   BEGIN

      x_return_status := 'S';

      OPEN c1 (p_ship_to_loc);
      FETCH c1 INTO l_cust_acct_site_id;
      CLOSE c1;

      OPEN c2 (l_cust_acct_site_id);
      FETCH c2 INTO l_party_site_id;
      CLOSE c2;

      OPEN c3 (l_party_site_id);
      FETCH c3 INTO l_location_id;
      CLOSE c3;

      OPEN c4 (l_location_id);
      FETCH c4 INTo x_postal_code;
      CLOSE c4;
    
      IF x_postal_code IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine Postal Code. (SHIP TO LOCATION: '||p_ship_to_loc||')';
         Return;
      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Get_Postal_Code()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Postal_Code;

   PROCEDURE Get_Cust_Site_ID
      (
         p_ship_to_loc           IN  HZ_CUST_SITE_USES_ALL.location%Type,
         x_customer_site_id      OUT HZ_CUST_SITE_USES_ALL.site_use_id%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      ) AS

      
      CURSOR c_site  (c_ship_to_loc HZ_CUST_SITE_USES_ALL.location%Type) IS
         SELECT site_use_id
         FROM   hz_cust_site_uses
         WHERE location = c_ship_to_loc
         AND   site_use_code = 'SHIP_TO'
         AND   status = 'A';

   BEGIN

      x_return_status := 'S';  

      OPEN  c_site (p_ship_to_loc);
      FETCH c_site INTO x_customer_site_id;
      CLOSE c_site;

      IF x_customer_site_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot get Customer Site ID from Ship to Location. (SHIP TO LOC:'||p_ship_to_loc||')';
         Return;

      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Get_Cust_Site_ID()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Cust_Site_ID;


   PROCEDURE Get_Cust_ID
      (
         p_customer_number       IN  MSC_TRADING_PARTNERS.partner_number%Type,
         x_customer_id           OUT MSC_TRADING_PARTNERS.sr_tp_id%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      ) AS

      CURSOR c_cust  (c_partner_number  MSC_TRADING_PARTNERS.partner_number%Type) IS
         SELECT sr_tp_id 
         FROM   msc_trading_partners
         WHERE  partner_number = c_partner_number
         AND    partner_type = 2
         AND    sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    disable_date IS Null
         AND    Nvl(status, 'A') = 'A';

   BEGIN

      x_return_status := 'S';  

      OPEN  c_cust (p_customer_number);
      FETCH c_cust INTO x_customer_id;
      CLOSE c_cust;

      IF x_customer_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot get Customer ID from Customer Number in planning instance. (CUSTOMER NUMBER:'||p_customer_number||')';
         Return;

      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Get_Cust_ID()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Cust_ID;

   PROCEDURE Validate_Parameters
      (
         p_item_ordered          IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered      IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_order_quantity_uom    IN  MSC_UNITS_OF_MEASURE.uom_code%Type,
         p_customer_number       IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_to_loc           IN  MSC_TRADING_PARTNER_SITES.location%Type,
         p_postal_code           IN  HZ_LOCATIONS.postal_code%Type,
         p_current_date_time     IN  DATE,
         p_timezone_code         IN  HR_LOCATIONS_V.timezone_code%Type,
         p_requested_date        IN  MSC_SALES_ORDERS.request_date%Type,
         p_order_type            IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_method           IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_ship_from_org         IN  MSC_PLAN_ORGANIZATIONS.organization_code%Type,
         p_pickup                IN  VARCHAR2,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      ) AS


   BEGIN

      x_return_status := 'S';  

      IF p_current_date_time IS Null OR p_timezone_code IS Null THEN

         x_return_status := 'E';
         x_msg := 'Request Date-Time AND Timezone is required';
         Return;

      END IF;

      IF p_customer_number IS Null THEN

         x_return_status := 'E';
         x_msg := 'Customer Number is required';
         Return;

      END IF;

      IF p_ship_to_loc IS Null AND p_postal_code IS Null THEN

         x_return_status := 'E';
         x_msg := 'Ship to Location -OR- Postal Code is required';
         Return;

      END IF;

      IF p_item_ordered IS Null THEN
         x_return_status := 'E';
         x_msg := 'Item is required';
         Return;

      END IF;

      IF p_quantity_ordered IS Null OR p_quantity_ordered < 1 THEN
         x_return_status := 'E';
         x_msg := 'Requested Quantity is required (should be greater > 0)';
         Return;

      END IF;

      IF p_order_quantity_uom IS Null THEN
         x_return_status := 'E';
         x_msg := 'Order Quantity UOM is required';
         Return;

      END IF;

      IF p_requested_date IS Null THEN
         x_return_status := 'E';
         x_msg := 'Requested Date is required';
         Return;

      END IF;


      IF p_pickup = 'Y' THEN
         IF p_ship_from_org IS Null THEN
            x_return_status := 'E';
            x_msg := 'For Ship Method "Pickup" Ship From Org is required';
            Return;
         END IF;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Validate_Parameters()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Validate_Parameters;


   PROCEDURE Check_If_ShipMethod_Pickup
      (
         p_ship_method           IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         x_pickup                OUT VARCHAR2,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      ) AS

      CURSOR c_ship  (c_ship_method IN MSC_INTERORG_SHIP_METHODS.ship_method%Type) IS
         SELECT Nvl(attribute15, 'N')
         FROM   wsh_carrier_services_v
         WHERE  ship_method_code = c_ship_method
         AND    Nvl(enabled_flag, 'Y') = 'Y';


   BEGIN

      x_return_status := 'S';  

      OPEN c_ship (p_ship_method);
      FETCH c_ship INTO x_pickup;
      CLOSE c_ship;


      IF x_pickup NOT IN ('Y', 'N') THEN
         x_return_status := 'E';
         x_msg := 'Pickup attribute for ship method not setup correctly. (SHIP METHOD:'||p_ship_method||')';
         Return;

      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Check_If_ShipMethod_Pickup()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Check_If_ShipMethod_Pickup;

   PROCEDURE Get_Ship_To_Location
      (
         p_customer_site_id      IN  HZ_CUST_SITE_USES_ALL.site_use_id%Type,
         x_ship_to_loc           OUT HZ_CUST_SITE_USES_ALL.location%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      ) AS

      
      CURSOR c_loc  (c_site_use_id HZ_CUST_SITE_USES_ALL.site_use_id%Type) IS
         SELECT location
         FROM   hz_cust_site_uses
         WHERE  site_use_id = c_site_use_id
         AND    site_use_code = 'SHIP_TO'
         AND    status = 'A';

   BEGIN

      x_return_status := 'S';  

      OPEN  c_loc (p_customer_site_id);
      FETCH c_loc INTO x_ship_to_loc;
      CLOSE c_loc;

      IF x_ship_to_loc IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot get Ship to Location from Customer Site ID. (CUSTOMER SITE ID:'||p_customer_site_id||')';
         Return;

      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Get_Ship_To_Location()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Ship_To_Location;

   PROCEDURE Check_If_Order_Bulk
      (
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_item_ordered          IN  MSC_SYSTEM_ITEMS.item_name%Type,
         p_quantity_ordered      IN  MSC_SALES_ORDERS.primary_uom_quantity%Type,
         p_item_val_org_id       In  MTL_PARAMETERS_VIEW.organization_id%Type,
         x_bulk                  OUT VARCHAR2,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      )  AS

      
      CURSOR c_param (c_parameter_code OE_SYS_PARAMETER_DEF_VL.parameter_code%Type,
                    c_category_code  OE_SYS_PARAMETER_DEF_VL.category_code%Type) IS
         SELECT b.parameter_value
         FROM   oe_sys_parameter_def_vl a, 
                oe_sys_parameters_v b
         WHERE  a.parameter_code = b.parameter_code
         AND    a.category_code = b.category_code
         AND    b.parameter_code = c_parameter_code
         AND    b.category_code = c_category_code
         AND    a.enabled_flag = 'Y';

      CURSOR c_item (c_item MTL_SYSTEM_ITEMS_B.segment1%Type,
                     c_organization_id MTL_SYSTEM_ITEMS_B.organization_id%Type) IS
         SELECT unit_weight, weight_uom_code
         FROM mtl_system_items_b
         WHERE segment1 = c_item
         AND   organization_id = c_organization_id;

      l_bulk_threshold_value OE_SYS_PARAMETER_DEF_VL.parameter_code%Type;
      l_bulk_threshold_uom   OE_SYS_PARAMETER_DEF_VL.parameter_code%Type;
      l_unit_weight          MTL_SYSTEM_ITEMS_B.unit_weight%Type;
      l_weight_uom_code      MTL_SYSTEM_ITEMS_B.weight_uom_code%Type;
      l_item_val_org_id      MTL_SYSTEM_ITEMS_B.organization_id%Type;
      l_uom_rate             NUMBER;


   BEGIN
  
      IF p_category_name = 'F' THEN
         x_bulk := 'N';
         Return;
      END IF;

      OPEN c_param ('XX_BULK_THRESHOLD_VALUE', 'XXOM');
      FETCH c_param INTO l_bulk_threshold_value;
      CLOSE c_param;

      IF l_bulk_threshold_value IS Null THEN
         x_bulk := 'N';
         Return;
      END IF;

      OPEN c_param ('XX_BULK_THRESHOLD_UOM', 'XXOM');
      FETCH c_param INTO l_bulk_threshold_uom;
      CLOSE c_param;

      IF l_bulk_threshold_uom IS Null THEN
         x_bulk := 'N';
         Return;
      END IF; 

      OPEN c_item (p_item_ordered, p_item_val_org_id);
      FETCH c_item INTO l_unit_weight, l_weight_uom_code;
      CLOSE c_item;

      IF l_unit_weight IS Null OR l_weight_uom_code IS Null THEN
         x_bulk := 'N';
         Return;
      END IF;

      INV_CONVERT.Inv_UM_Conversion(l_weight_uom_code, l_bulk_threshold_uom, null, l_uom_rate);

      IF l_uom_rate = -99999 THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine UOM Rate for Bulk Order Check';
         Return;
      END IF;

      IF (l_unit_weight * p_quantity_ordered * l_uom_rate) >= l_bulk_threshold_value THEN
         x_bulk := 'Y';
         Return;
      ELSE
         x_bulk := 'N';
         Return;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Params_Pkg.Check_If_Order_Bulk()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Check_If_Order_Bulk;


END XX_MSC_SOURCING_PARAMS_PKG;
/
