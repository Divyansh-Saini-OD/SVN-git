CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_SR_ORG_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_SR_ORG_PKG                                        |
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

   CATEGORY_ZONE_ASSIGNMENT_TYPE     CONSTANT  INTEGER := 8;
   TRANSFER_FROM_SOURCE_TYPE         CONSTANT  INTEGER := 1;

   PROCEDURE Get_Org_Code
      (
         p_org_id              IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         x_org_code            OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_return_status       OUT VARCHAR2,
         x_msg                 OUT VARCHAR2
      ) AS

      CURSOR c_org (c_org_id  MTL_PARAMETERS_VIEW.organization_id%Type) IS
         SELECT organization_code
         FROM   mtl_parameters_view
         WHERE  organization_id = c_org_id;

   BEGIN

      x_return_status := 'S';  

      OPEN  c_org (p_org_id);
      FETCH c_org INTO x_org_code;
      CLOSE c_org;

      IF x_org_code IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot get Org Code from Org ID. (ORG ID:'||p_org_id||')';
         Return;

      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_SR_Org_Pkg.Get_Org_Code()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Org_Code;


   PROCEDURE Get_Org_ID
      (
         p_sourcing_rule_id    IN  MSC_SR_ASSIGNMENTS_V.sourcing_rule_id%Type,
         x_org_id              OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_return_status       OUT VARCHAR2,
         x_msg                 OUT VARCHAR2
      ) AS

      CURSOR c_sr_rcpt_id(c_sourcing_rule_id   MSC_SR_ASSIGNMENTS_V.sourcing_rule_id%Type) IS
         SELECT sr_receipt_id
         FROM   msc_sr_receipt_org_v
         WHERE  sourcing_rule_id = c_sourcing_rule_id
         AND    sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    Sysdate BETWEEN effective_date and nvl(disable_date, sysdate+1);

      CURSOR c_org(c_sr_receipt_id  MSC_SR_RECEIPT_ORG_V.sr_receipt_id%Type) IS
         SELECT source_organization_id
         FROM   msc_sr_source_org_v
         WHERE  sr_receipt_id = c_sr_receipt_id
         AND    source_type = TRANSFER_FROM_SOURCE_TYPE
         AND    sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         ORDER BY rank asc;

      l_sr_receipt_id      MSC_SR_RECEIPT_ORG_V.sr_receipt_id%Type;

   BEGIN

      x_return_status := 'S';  

      OPEN  c_sr_rcpt_id (p_sourcing_rule_id);
      FETCH c_sr_rcpt_id INTO l_sr_receipt_id;
      CLOSE c_sr_rcpt_id;

      IF l_sr_receipt_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot get base Org. (SOURCING RULE ID:'||p_sourcing_rule_id||')';
         Return;

      END IF;

      OPEN  c_org(l_sr_receipt_id);
      FETCH c_org INTO x_org_id;
      CLOSE c_org;

      IF x_org_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot get base Org. (SOURCING RULE ID:'||p_sourcing_rule_id||')';
         Return;

      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_SR_Org_Pkg.Get_Org_ID()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Org_ID;

   PROCEDURE Get_Sourcing_Rule
      (
         p_assignment_set_id   IN  MSC_SR_ASSIGNMENTS_V.sourcing_rule_id%Type,
         p_category_set_id     IN  MTL_CATEGORY_SETS.category_set_id%Type,
         p_category_name       IN  MSC_SR_ASSIGNMENTS_V.category_name%Type,
         p_region_id           IN  WSH_REGIONS_V.region_id%Type,
         x_sourcing_rule_id    OUT MSC_SR_ASSIGNMENTS_V.sourcing_rule_id%Type,
         x_return_status       OUT VARCHAR2,
         x_msg                 OUT VARCHAR2
      ) AS

      CURSOR c_sr(c_assignment_set_id   MSC_SR_ASSIGNMENTS_V.sourcing_rule_id%Type,
                  c_category_set_id     MSC_CATEGORY_SETS.category_set_id%Type,
                  c_category_name       MSC_SR_ASSIGNMENTS_V.category_name%Type,
                  c_region_id           WSH_REGIONS_V.region_id%Type) IS
         SELECT sourcing_rule_id
         FROM   msc_sr_assignments_v
         WHERE  region_id = c_region_id
         AND    assignment_set_id = c_assignment_set_id
         AND    category_set_id = c_category_set_id
         AND    category_name = c_category_name
         AND    assignment_type = CATEGORY_ZONE_ASSIGNMENT_TYPE;

   BEGIN

      x_return_status := 'S';  

      OPEN  c_sr (p_assignment_set_id, p_category_set_id, p_category_name, p_region_id);
      FETCH c_sr INTO x_sourcing_rule_id;
      CLOSE c_sr;

      IF x_sourcing_rule_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine Sourcing Rule. (ASSIGNMENT SET ID:'||p_assignment_set_id||', '||
                                                   'CATEGORY SET ID:'||p_category_set_id||', '||
                                                   'REGION ID:'||p_region_id||')';
         Return;

      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_SR_Org_Pkg.Get_Sourcing_Rule()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Sourcing_Rule;


   PROCEDURE Get_Base_Org_From_SR
      (
         p_postal_code           IN  HZ_LOCATIONS.postal_code%Type,
         p_item                  IN  MTL_SYSTEM_ITEMS_B.segment1%Type,
         p_assignment_set_id     IN  MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         p_item_val_org          IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_category_set_id       IN  MSC_CATEGORY_SETS.category_set_id%Type,
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         x_base_org              OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       ) AS

      l_item_id                  MSC_SYSTEM_ITEMS.inventory_item_id%Type;
      l_category_name            MSC_ITEM_CATEGORIES.category_name%Type;  
      l_category_set_id          MSC_CATEGORY_SETS.category_set_id%Type;
      l_zone_id                  WSH_ZONE_REGIONS_V.zone_id%Type;       
      l_sourcing_rule_id         MSC_SR_ASSIGNMENTS_V.sourcing_rule_id%Type;
      l_org_id                   MTL_PARAMETERS_VIEW.organization_id%Type;

   BEGIN

      l_category_set_id := p_category_set_id;
      l_category_name   := p_category_name;

      XX_MSC_Sourcing_Params_Pkg.Get_Zone
         (
            p_postal_code    => p_postal_code,
            p_category_name  => l_category_name,
            x_zone_id        => l_zone_id,
            x_return_status  => x_return_status,
            x_msg            => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      Get_Sourcing_Rule
         (
            p_assignment_set_id   => p_assignment_set_id,
            p_category_set_id     => l_category_set_id,
            p_category_name       => l_category_name,
            p_region_id           => l_zone_id,
            x_sourcing_rule_id    => l_sourcing_rule_id,
            x_return_status       => x_return_status,
            x_msg                 => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      Get_Org_ID
         (
            p_sourcing_rule_id   => l_sourcing_rule_id,
            x_org_id             => l_org_id,
            x_return_status      => x_return_status,
            x_msg                => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      Get_Org_Code
         (
            p_org_id             => l_org_id,
            x_org_code           => x_base_org,
            x_return_status      => x_return_status,
            x_msg                => x_msg
         );

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_SR_Org_Pkg.Get_Base_Org_From_SR()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Base_Org_From_SR;

   PROCEDURE Get_Base_Org_From_SR
      (
         p_ship_to_loc           IN  HZ_CUST_SITE_USES_ALL.location%Type,
         p_item                  IN  MTL_SYSTEM_ITEMS_B.segment1%Type, 
         p_assignment_set_id     IN  MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type, 
         p_item_val_org          IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_category_set_id       IN  MSC_CATEGORY_SETS.category_set_id%Type,
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         x_base_org              OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       ) AS

      l_postal_code              HZ_LOCATIONS.postal_code%Type;

   BEGIN

      x_return_status := 'S';


      -- Get postal code
      XX_MSC_Sourcing_Params_Pkg.Get_Postal_Code
         (
             p_ship_to_loc     => p_ship_to_loc,
             x_postal_code     => l_postal_code,
             x_return_status   => x_return_status,
             x_msg             => x_msg
         );
    

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      XX_MSC_Sourcing_SR_Org_Pkg.Get_Base_Org_From_SR
         (
            p_postal_code           => l_postal_code,
            p_item                  => p_item,
            p_assignment_set_id     => p_assignment_set_id,
            p_item_val_org          => p_item_val_org,
            p_category_set_id       => p_category_set_id,
            p_category_name         => p_category_name,
            x_base_org              => x_base_org,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
          );

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_SR_Org_Pkg.Get_Base_Org_From_SR()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Base_Org_From_SR;


   PROCEDURE Get_Base_Org
      (
         p_customer_number       IN  RA_CUSTOMERS.customer_number%Type,
         p_item                  IN  MTL_SYSTEM_ITEMS_B.segment1%Type,
         p_ship_to_loc           IN  HZ_CUST_SITE_USES_ALL.location%Type,
         p_postal_code           IN  HZ_LOCATIONS.postal_code%Type,
         p_ship_from_org         IN  MTL_PARAMETERS_VIEW.organization_code%Type,
         p_cust_setup_org        IN  MTL_PARAMETERS_VIEW.organization_code%Type,
         p_assignment_set_id     IN  MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         p_item_val_org          IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_category_set_id       IN  MSC_CATEGORY_SETS.category_set_id%Type,
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         x_base_org              OUT MTL_PARAMETERS_VIEW.organization_code%Type,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
      ) AS

      l_org_code                 MTL_PARAMETERS_VIEW.organization_code%Type;

      CURSOR c_org_valid (c_ship_from_org MTL_PARAMETERS_VIEW.organization_code%Type) IS
         SELECT organization_code
         FROM   mtl_parameters_view
         WHERE  organization_code = c_ship_from_org;

   BEGIN

      x_return_status :='S';
      
      IF p_ship_from_org IS NOT Null THEN

         -- Check if Valid Org

         OPEN  c_org_valid (p_ship_from_org);
         FETCH c_org_valid INTO l_org_code;
         CLOSE c_org_valid;

         IF l_org_code IS Null THEN
            x_return_status := 'E';
            x_msg := 'Invalid Ship From Org';
            Return;
         END IF;

         x_base_org := p_ship_from_org;
         x_return_status := 'S';
         Return;

      ELSE

         x_base_org  := p_cust_setup_org;

         IF x_base_org IS Null THEN

            -- Get base Org from sourcing rules
            IF p_item IS Null THEN

               x_return_status := 'E';
               x_msg := 'No Item';
               Return;               

            END IF;

            IF p_ship_to_loc IS NOT Null THEN

               XX_MSC_Sourcing_SR_Org_Pkg.Get_Base_Org_From_SR
                  (
                     p_ship_to_loc        => p_ship_to_loc,
                     p_item               => p_item,
                     p_assignment_set_id  => p_assignment_set_id,
                     p_item_val_org       => p_item_val_org,
                     p_category_set_id    => p_category_set_id,
                     p_category_name      => p_category_name,
                     x_base_org           => x_base_org,
                     x_return_status      => x_return_status,
                     x_msg                => x_msg
                  );

            ELSE


               XX_MSC_Sourcing_SR_Org_Pkg.Get_Base_Org_From_SR
                  (
                     p_postal_code        => p_postal_code,
                     p_item               => p_item,
                     p_assignment_set_id  => p_assignment_set_id,
                     p_item_val_org       => p_item_val_org,
                     p_category_set_id    => p_category_set_id,
                     p_category_name      => p_category_name,
                     x_base_org           => x_base_org,
                     x_return_status      => x_return_status,
                     x_msg                => x_msg
                  );

            END IF;

            IF x_return_status <> 'S' THEN
               Return;
            END IF;

         END IF;

      END IF;

 
   EXCEPTION 
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_SR_Org_Pkg.Get_Base_Org()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Get_Base_Org;

   PROCEDURE Get_Org_IDs
      (
         p_sourcing_rule_id    IN  MSC_SR_ASSIGNMENTS_V.sourcing_rule_id%Type,
         p_xdock_only          IN  VARCHAR2,
         p_exclude_org_id      IN  MTL_PARAMETERS_VIEW.organization_id%Type,  -- Resourcing
         x_sr_orgs             OUT XX_MSC_Sourcing_Util_Pkg.SR_Orgs_Typ,
         x_return_status       OUT VARCHAR2,
         x_msg                 OUT VARCHAR2
      ) AS

      CURSOR c_sr_rcpt_id(c_sourcing_rule_id   MSC_SR_ASSIGNMENTS_V.sourcing_rule_id%Type) IS
         SELECT sr_receipt_id
         FROM   msc_sr_receipt_org_v
         WHERE  sourcing_rule_id = c_sourcing_rule_id
         AND    sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    Sysdate BETWEEN effective_date and nvl(disable_date, sysdate+1);

      CURSOR c_org(c_sr_receipt_id  MSC_SR_RECEIPT_ORG_V.sr_receipt_id%Type) IS
         SELECT mso.source_organization_id, mso.rank
         FROM   msc_sr_source_org_v mso
         WHERE  mso.sr_receipt_id = c_sr_receipt_id
         AND    mso.source_type = TRANSFER_FROM_SOURCE_TYPE
         AND    mso.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    mso.source_organization_id != Nvl(p_exclude_org_id, -1)  -- Resourcing
         ORDER BY mso.rank asc;

      CURSOR c_xdockorg(c_sr_receipt_id  MSC_SR_RECEIPT_ORG_V.sr_receipt_id%Type) IS
         SELECT mso.source_organization_id, mso.rank
         FROM   msc_sr_source_org_v mso,
                hr_organization_units hou
         WHERE  hou.organization_id = mso.source_organization_id
         AND    mso.sr_receipt_id = c_sr_receipt_id
         AND    mso.source_type = TRANSFER_FROM_SOURCE_TYPE
         AND    mso.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    hou.type = 'WHXDRG'
         AND    mso.source_organization_id != Nvl(p_exclude_org_id, -1)  -- Resourcing
         ORDER BY mso.rank asc;

      l_sr_receipt_id      MSC_SR_RECEIPT_ORG_V.sr_receipt_id%Type;
      i                    NUMBER := 0;

   BEGIN

      x_return_status := 'S';  

      OPEN  c_sr_rcpt_id (p_sourcing_rule_id);
      FETCH c_sr_rcpt_id INTO l_sr_receipt_id;
      CLOSE c_sr_rcpt_id;

      IF l_sr_receipt_id IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot get Sourcing Rule Org. (SOURCING RULE ID:'||p_sourcing_rule_id||')';
         Return;

      END IF;

      IF p_xdock_only = 'Y' THEN

         FOR c_xdockorg_rec IN c_xdockorg (l_sr_receipt_id) LOOP
            i := i + 1;
         
            x_sr_orgs.org_id.extend(1);
            x_sr_orgs.rank.extend(1);

            x_sr_orgs.org_id(i)   := c_xdockorg_rec.source_organization_id;
            x_sr_orgs.rank(i)     := c_xdockorg_rec.rank;

         END LOOP;

      ELSE


         FOR c_org_rec IN c_org (l_sr_receipt_id) LOOP
            i := i + 1;
         
            x_sr_orgs.org_id.extend(1);
            x_sr_orgs.rank.extend(1);

            x_sr_orgs.org_id(i)   := c_org_rec.source_organization_id;
            x_sr_orgs.rank(i)     := c_org_rec.rank;

         END LOOP;

      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_SR_Org_Pkg.Get_Org_IDs()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Org_IDs;

   PROCEDURE Get_Orgs_From_SR
      (
         p_postal_code           IN  HZ_LOCATIONS.postal_code%Type,
         p_assignment_set_id     IN  MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         p_item_val_org          IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_category_set_id       IN  MSC_CATEGORY_SETS.category_set_id%Type,
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_xdock_only            IN  VARCHAR2,
         p_exclude_org_id        IN  MTL_PARAMETERS_VIEW.organization_id%Type,  -- Resourcing
         x_sr_orgs               OUT XX_MSC_Sourcing_Util_Pkg.SR_Orgs_Typ,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       ) AS

      l_item_id                  MSC_SYSTEM_ITEMS.inventory_item_id%Type;
      l_category_name            MSC_ITEM_CATEGORIES.category_name%Type;  
      l_category_set_id          MSC_CATEGORY_SETS.category_set_id%Type;
      l_zone_id                  WSH_ZONE_REGIONS_V.zone_id%Type;       
      l_sourcing_rule_id         MSC_SR_ASSIGNMENTS_V.sourcing_rule_id%Type;

   BEGIN

      l_category_set_id := p_category_set_id;
      l_category_name   := p_category_name;

      XX_MSC_Sourcing_Params_Pkg.Get_Zone
         (
            p_postal_code    => p_postal_code,
            p_category_name  => p_category_name,
            x_zone_id        => l_zone_id,
            x_return_status  => x_return_status,
            x_msg            => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      Get_Sourcing_Rule
         (
            p_assignment_set_id   => p_assignment_set_id,
            p_category_set_id     => p_category_set_id,
            p_category_name       => p_category_name,
            p_region_id           => l_zone_id,
            x_sourcing_rule_id    => l_sourcing_rule_id,
            x_return_status       => x_return_status,
            x_msg                 => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      Get_Org_IDs
         (
            p_sourcing_rule_id   => l_sourcing_rule_id,
            p_xdock_only         => p_xdock_only,
            p_exclude_org_id     => p_exclude_org_id,   -- Resourcing
            x_sr_orgs            => x_sr_orgs,
            x_return_status      => x_return_status,
            x_msg                => x_msg
         );


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_SR_Org_Pkg.Get_Orgs_From_SR()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Orgs_From_SR;

   PROCEDURE Get_Orgs_From_SR
      (
         p_ship_to_loc           IN  HZ_CUST_SITE_USES_ALL.location%Type,
         p_assignment_set_id     IN  MSC_SR_ASSIGNMENTS_V.assignment_set_id%Type,
         p_item_val_org          IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_category_set_id       IN  MSC_CATEGORY_SETS.category_set_id%Type,
         p_category_name         IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_xdock_only            IN  VARCHAR2,
         p_exclude_org_id        IN  MTL_PARAMETERS_VIEW.organization_id%Type, -- Resourcing
         x_sr_orgs               OUT XX_MSC_Sourcing_Util_Pkg.SR_Orgs_Typ,
         x_return_status         OUT VARCHAR2,
         x_msg                   OUT VARCHAR2
       ) AS

      l_postal_code              HZ_LOCATIONS.postal_code%Type;

   BEGIN

      XX_MSC_Sourcing_Params_Pkg.Get_Postal_Code
         (
            p_ship_to_loc           => p_ship_to_loc,
            x_postal_code           => l_postal_code,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
          );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      XX_MSC_Sourcing_SR_Org_Pkg.Get_Orgs_From_SR
         (
            p_postal_code           => l_postal_code,
            p_assignment_set_id     => p_assignment_set_id,
            p_item_val_org          => p_item_val_org,
            p_category_set_id       => p_category_set_id,
            p_category_name         => p_category_name,
            p_xdock_only            => p_xdock_only,
            p_exclude_org_id        => p_exclude_org_id,  -- Resourcing
            x_sr_orgs               => x_sr_orgs,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
          );

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_SR_Org_Pkg.Get_Orgs_From_SR()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Orgs_From_SR;

END XX_MSC_SOURCING_SR_ORG_PKG;
/
