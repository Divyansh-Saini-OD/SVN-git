CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_VENDOR_ATP_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_VENDOR_ATP_PKG                                    |
-- | Description: Office Depot - Custom ATP                                    |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1A 05-sep-2007  Roy Gomes        Initial draft version               |
-- |v1.1     10-Jan-2008  Roy Gomes        Resourcing                          |
-- |v1.2     07-Feb-2008  Roy Gomes        Sort by MLS rank only(not ASL rank) | 
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

   PG_DEBUG VARCHAR2(1) := NVL(FND_PROFILE.Value('MSC_ATP_DEBUG'), 'N');


   PROCEDURE Get_MLSS_CutOff_Time
     (
        p_organization_id                 IN  MTL_PARAMETERS_VIEW.organization_id%Type,
        x_mlss_cutoff_time                OUT XX_INV_ORG_LOC_RMS_ATTRIBUTE.mls_cutoff_time%Type,
        x_return_status                   OUT VARCHAR2,
        x_msg                             OUT VARCHAR2
     )  AS

      CURSOR c_cutoff IS
         SELECT mls_cutoff_time
         FROM   mtl_parameters_view mpv,
                xx_inv_org_loc_rms_attribute xiv
         WHERE  mpv.attribute6 = xiv.combination_id
         AND    mpv.organization_id = p_organization_id
         AND    Nvl(xiv.enabled_flag, 'Y') = 'Y'
         AND    Trunc(Sysdate) BETWEEN Nvl(Trunc(xiv.start_date_active), Trunc(Sysdate)) 
                   AND Nvl(Trunc(xiv.end_date_active), Trunc(Sysdate)+1);


   BEGIN

      x_return_status := 'S';

      OPEN  c_cutoff;
      FETCH c_cutoff INTO x_mlss_cutoff_time;
      CLOSE c_cutoff;
    


   EXCEPTION

      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Vendor_ATP_Pkg.Get_MLS_CutOff_Time()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_MLSS_CutOff_Time;

   PROCEDURE Get_Feed_Data
      (
         p_base_org_id            IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_inventory_item_id      IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type, 
         p_operating_unit         IN  HR_OPERATING_UNITS.organization_id%Type, 
         p_vm_indicator           IN  XX_PO_SSA_V.vm_indicator%Type, 
         p_drop_ship_cd           IN  XX_PO_SSA_V.drop_ship_cd%Type,
         x_feed_availability_typ  OUT  XX_MSC_SOURCING_UTIL_PKG.feed_availability_typ,
         x_return_status          OUT VARCHAR2,
         x_msg                    OUT VARCHAR2
      ) AS

      CURSOR c_feed IS
         SELECT DISTINCT hdr.vendor_id, txn.avb_reserve_qty qty
         FROM   xx_om_supplier_invfeed_hdr_all hdr,
                xx_om_supplier_invfeed_txn_all txn,
                xx_po_ssa_v ssa
         WHERE  hdr.supplier_id = txn.supplier_id
         AND    hdr.org_id = p_operating_unit
         AND    txn.inventory_item_id = p_inventory_item_id
         AND    ssa.using_organization_id = p_base_org_id
         AND    ssa.vendor_id = hdr.vendor_id
         AND    ssa.item_id = txn.inventory_item_id
         AND    Nvl(ssa.disabled, 'N') = 'N'
         AND    Nvl(ssa.vm_indicator, '~') = Decode(p_vm_indicator, Null, Decode(ssa.vm_indicator, Null, '~', Null), p_vm_indicator)
         AND    (Nvl(ssa.drop_ship_cd, 'B') = 'B' OR Nvl(ssa.drop_ship_cd, 'B') = Nvl(p_drop_ship_cd, ssa.drop_ship_cd))
         AND    ssa.inv_type_ind IS NOT Null
         AND    ssa.rank IS NOT Null;

      j  NUMBER := 0;

   BEGIN

      x_return_status := 'S';

      FOR c_feed_rec IN c_feed LOOP

         j := j+1;

         x_feed_availability_typ.vendor_id.extend(1);
         x_feed_availability_typ.qty.extend(1);
        
         x_feed_availability_typ.vendor_id(j) := c_feed_rec.vendor_id;
         x_feed_availability_typ.qty(j) := c_feed_rec.qty;             
   
      END LOOP;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Feed Data:');
         FOR i IN 1..x_feed_availability_typ.vendor_id.COUNT LOOP
            MSC_SCH_WB.ATP_Debug('  -> vendor ID: '||x_feed_availability_typ.vendor_id(i)||' = '||x_feed_availability_typ.qty(i));
         END LOOP;
      END IF;

      /*
      dbms_output.put_line('  -> Feed Data:');
      FOR i IN 1..x_feed_availability_typ.vendor_id.COUNT LOOP
         dbms_output.put_line('  -> vendor ID: '||x_feed_availability_typ.vendor_id(i)||' = '||x_feed_availability_typ.qty(i));
      END LOOP;
      */

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Vendor_ATP_Pkg.Get_Feed_Data()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Feed_Data;

   PROCEDURE Vendor_ATP 
      (
         p_customer_number          IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_inventory_item_id        IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_quantity_ordered         IN  OE_ORDER_LINES_ALL.ordered_quantity%Type,
         p_order_quantity_uom       IN  OE_ORDER_LINES_ALL.order_quantity_uom%Type,
         p_requested_date           IN  OE_ORDER_LINES_ALL.schedule_ship_date%Type,
         p_base_org_id              IN  MTL_PARAMETERS_VIEW.organization_id%Type,
         p_zone_id                  IN  WSH_ZONE_REGIONS_V.zone_id%Type,
         p_current_date_time        IN  DATE,
         p_timezone_code            IN  HR_LOCATIONS_V.timezone_code%Type,
         p_unit_selling_price       IN  OE_ORDER_LINES_ALL.unit_selling_price%Type,
         p_operating_unit           IN  HR_OPERATING_UNITS.organization_id%Type,
         p_drop_ship_cd             IN  XX_PO_SSA_V.drop_ship_cd%Type,
         p_ship_method              IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_category_name            IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_bulk                     IN  VARCHAR2,
         p_exclude_vendor_site_id   IN  PO_VENDOR_SITES.vendor_site_id%Type,  -- Resourcing
         p_session_id               IN  NUMBER,
         x_source_org_id            OUT MTL_PARAMETERS_VIEW.organization_id%Type,
         x_vendor_id                OUT PO_VENDORS.vendor_id%Type,
         x_vendor_site_id           OUT PO_VENDOR_SITES.vendor_site_id%Type,
         x_vendor_type              OUT XX_PO_SSA_V.supp_loc_count_ind%Type,
         x_vendor_facility_code     OUT XX_PO_MLSS_DET.supp_facility_cd%Type,  
         x_vendor_account           OUT XX_PO_MLSS_DET.supp_loc_ac%Type,
         x_requested_date_qty       OUT OE_ORDER_LINES_ALL.ordered_quantity%Type,
         x_drop_ship_cd             OUT XX_PO_SSA_V.drop_ship_cd%Type,
         x_ship_method              OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         x_ship_date                OUT OE_ORDER_LINES_ALL.schedule_ship_date%Type,
         x_arrival_date             OUT OE_ORDER_LINES_ALL.schedule_ship_date%Type,
         x_error_code               OUT NUMBER,
         x_return_status            OUT VARCHAR2,
         x_msg                      OUT VARCHAR2
      ) AS

      l_session_id               NUMBER;
      l_vm_indicator             XX_PO_SSA_V.vm_indicator%Type;   
      l_ext_ssa_typ              XX_MSC_SOURCING_UTIL_PKG.ext_ssa_typ;
      l_feed_availability_typ    XX_MSC_SOURCING_UTIL_PKG.feed_availability_typ;
      l_rt_availability_typ      XX_MSC_SOURCING_UTIL_PKG.rt_availability_typ;
      l_primary_vendor_id        XX_PO_SSA_V.vendor_id%Type;
      l_primary_vendor_site_id   XX_PO_SSA_V.vendor_site_id%Type;
      l_imu_amt_pt               XX_PO_MLSS_HDR.imu_amt_pt%Type;
      l_imu_value                XX_PO_MLSS_HDR.imu_value%Type;
      l_imu_check                VARCHAR2(6);
      l_no_availability          VARCHAR2(4000);
      l_feed_done                BOOLEAN := FALSE;
      l_no_mls_entry             BOOLEAN := FALSE;
      l_bo_assignment_found      BOOLEAN := FALSE;
      l_supply_type              XX_PO_SSA_V.supp_loc_count_ind%Type;
      l_supply_loc_no            XX_PO_MLSS_DET.supply_loc_no%Type;
      l_mlss_ds_lt               XX_PO_MLSS_DET.ds_lt%Type;
      l_mlss_b2b_lt              XX_PO_MLSS_DET.b2b_lt%Type;
      l_vendor_facility_code     XX_PO_MLSS_DET.supp_facility_cd%Type;  
      l_vendor_account           XX_PO_MLSS_DET.supp_loc_ac%Type;
      l_qty                      NUMBER;
      l_ship_date                DATE;
      l_arrival_date             DATE;
      l_ship_method              MTL_INTERORG_SHIP_METHODS.ship_method%Type;
      l_end_point                XX_PO_MLSS_DET.end_point%Type;
      l_mlss_cutoff_time         XX_INV_ORG_LOC_RMS_ATTRIBUTE.mls_cutoff_time%Type;

      l_bo_source_org_id         MTL_PARAMETERS_VIEW.organization_id%Type;
      l_bo_ship_date             OE_ORDER_LINES_ALL.schedule_ship_date%Type;
      l_bo_arrival_date          OE_ORDER_LINES_ALL.schedule_ship_date%Type;
      l_bo_vendor_id             PO_VENDORS.vendor_id%Type;
      l_bo_vendor_site_id        PO_VENDOR_SITES.vendor_site_id%Type;
      l_bo_vendor_type           XX_PO_SSA_V.supp_loc_count_ind%Type;
      l_bo_vendor_facility_code  XX_PO_MLSS_DET.supp_facility_cd%Type;  
      l_bo_vendor_account        XX_PO_MLSS_DET.supp_loc_ac%Type;
      l_bo_drop_ship_cd          XX_PO_SSA_V.drop_ship_cd%Type;
      l_bo_requested_date_qty    OE_ORDER_LINES_ALL.ordered_quantity%Type;
      l_bo_error_code            NUMBER;
      l_bo_ship_method           MTL_INTERORG_SHIP_METHODS.ship_method%Type;

      i                          NUMBER := 0;
      k                          NUMBER := 0;
      m                          NUMBER := 0;

      -- sort by MLS rank only 07-Feb-2008

      t_org_id                   NUMBER;
      t_vendor_id                NUMBER;
      t_vendor_site_id           NUMBER;
      t_supplier_type            VARCHAR2(1);
      t_inventory_item_id        NUMBER;
      t_primary_vendor_item      VARCHAR2(25);
      t_legacy_vendor_number     VARCHAR2(150);
      t_quantity_ordered         NUMBER;
      t_supply_loc_no            VARCHAR2(10);
      t_rank                     NUMBER;
      t_end_point                VARCHAR2(1);
      t_ds_lt                    NUMBER;
      t_b2b_lt                   NUMBER;
      t_supp_loc_ac              NUMBER;
      t_supp_facility_cd         VARCHAR2(40); 
      t_imu_amt_pt               VARCHAR2(1);
      t_imu_value                NUMBER;    
      t_qty                      NUMBER;
      t_supplier_response_code   VARCHAR2(1);

      CURSOR c_ssa (c_organization_id MTL_PARAMETERS_VIEW.organization_id%Type,
                    c_inventory_item_id MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
                    c_vm_indicator XX_PO_SSA_V.vm_indicator%Type,
                    c_ship_code XX_PO_SSA_V.drop_ship_cd%Type) IS
         SELECT asl_id,
                using_organization_id,
                item_id,
                vendor_id,
                vendor_site_id,
                vm_indicator,
                rank,
                Nvl(supp_loc_count_ind, 'S') supp_loc_count_ind,
                inv_type_ind,
                Nvl(lead_time, 0) lead_time,
                Nvl(drop_ship_cd, 'B') drop_ship_cd,
                primary_supp_ind,
                primary_vendor_item,
                legacy_vendor_number,
                Nvl(backorders_allowed_flag, 'N') backorders_allowed_flag,
                mlss_header_id
         FROM   xx_po_ssa_v
         WHERE  using_organization_id = c_organization_id
         AND    item_id = c_inventory_item_id
         AND    Nvl(disabled, 'N') = 'N'
         AND    Nvl(vm_indicator, '~') = Decode(c_vm_indicator, Null, Decode(vm_indicator, Null, '~', Null), c_vm_indicator)
         AND    (Nvl(drop_ship_cd, 'B') = 'B' OR Nvl(drop_ship_cd, 'B') = Nvl(c_ship_code, drop_ship_cd))
         AND    inv_type_ind IS NOT Null
         AND    rank IS NOT Null
         AND    Nvl(supp_loc_count_ind, 'S') IN ('M', 'S')
         AND    vendor_site_id != Nvl(p_exclude_vendor_site_id, '-1') -- Resourcing
         ORDER BY supp_loc_count_ind DESC, rank;

      CURSOR c_mlss (c_mlss_header_id XX_PO_MLSS_HDR.mlss_header_id%Type, 
                     c_vendor_id XX_PO_MLSS_DET.vendor_id%Type,
                     c_vendor_site_id XX_PO_MLSS_DET.vendor_site_id%Type,
                     c_end_point XX_PO_MLSS_DET.end_point%Type) IS
         SELECT hdr.imu_amt_pt, 
                hdr.imu_value, 
	        det.supply_loc_no, 
	        det.rank, 
	        det.end_point, 
	        Nvl(det.ds_lt, 0) ds_lt, 
	        Nvl(det.b2b_lt, 0) b2b_lt, 
	        det.supp_loc_ac, 
	        det.supp_facility_cd
         FROM   xx_po_mlss_hdr hdr,
                xx_po_mlss_det det
         WHERE  hdr.mlss_header_id = det.mlss_header_id
         AND    det.vendor_id = c_vendor_id
         AND    det.vendor_site_id = c_vendor_site_id
         AND    (Nvl(det.end_point, 'B') = 'B' OR Nvl(det.end_point, 'B') = Nvl(c_end_point, end_point))
         AND    Trunc(Sysdate) BETWEEN Nvl(Trunc(hdr.start_date), Trunc(Sysdate)) AND Nvl(Trunc(hdr.end_date), Trunc(sysdate) + 1)
         AND    hdr.mlss_header_id = c_mlss_header_id
         ORDER BY det.rank ASC;

      CURSOR c_primary_vendor (c_organization_id MTL_PARAMETERS_VIEW.organization_id%Type,
                               c_inventory_item_id MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type)IS
         SELECT vendor_id, vendor_site_id
         INTO   l_primary_vendor_id, l_primary_vendor_site_id
         FROM   xx_po_ssa_v
         WHERE  using_organization_id = c_organization_id
         AND    item_id = c_inventory_item_id
         AND    Nvl(primary_supp_ind, 'N') = 'Y'
         AND    Nvl(disabled, 'N') = 'N'
         ORDER BY vendor_site_id DESC;

   BEGIN

      x_return_status := 'S';

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_VENDOR_ATP_PKG.Ext_ATP() ...');
         MSC_SCH_WB.ATP_Debug('  -> Drop Ship Code: '||p_drop_ship_cd);
         MSC_SCH_WB.ATP_Debug('  -> Excluded Vendor Site ID: '||p_exclude_vendor_site_id);
      END IF;

      -- fnd_client_info.set_org_context(141);   -- to be removed

      SELECT meaning
      INTO   l_no_availability
      FROM   mfg_lookups
      WHERE  lookup_type = 'MTL_DEMAND_INTERFACE_ERRORS'
      AND    lookup_code = 53;

      XX_MSC_SOURCING_UTIL_PKG.Get_VM_Indicator
         (
             p_customer_number        => p_customer_number,
             x_vm_indicator           => l_vm_indicator,
             x_return_status          => x_return_status,
             x_msg                    => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      Get_MLSS_CutOff_Time
         (
            p_organization_id       => p_base_org_id,
            x_mlss_cutoff_time      => l_mlss_cutoff_time,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Vertical Market Customer: '||l_vm_indicator);
         MSC_SCH_WB.ATP_Debug('  -> Base Org: '||p_base_org_id);
         MSC_SCH_WB.ATP_Debug('  -> Inventory Item ID: '||p_inventory_item_id);
         MSC_SCH_WB.ATP_Debug('  -> Drop Ship Code: '||p_drop_ship_cd);
         MSC_SCH_WB.ATP_Debug('  -> MLS CutOff Time: '||l_mlss_cutoff_time);
      END IF;

      /*
      dbms_output.put_line('  -> Vertical Market Customer: '||l_vm_indicator);
      dbms_output.put_line('  -> Base Org: '||p_base_org_id);
      dbms_output.put_line('  -> Inventory Item ID: '||p_inventory_item_id);
      dbms_output.put_line('  -> Drop Ship Code: '||p_drop_ship_cd);
      dbms_output.put_line('  -> MLS CutOff Time: '||l_mlss_cutoff_time);
      */ 

      FOR c_ssa_rec IN c_ssa (p_base_org_id, p_inventory_item_id, l_vm_indicator, p_drop_ship_cd)  LOOP

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> ASL ID: '||c_ssa_rec.asl_id);
            MSC_SCH_WB.ATP_Debug('  -> Vendor ID: '||c_ssa_rec.vendor_id);
            MSC_SCH_WB.ATP_Debug('  -> Vendor Site ID: '||c_ssa_rec.vendor_site_id);
            MSC_SCH_WB.ATP_Debug('  -> MLS/SLS: '||c_ssa_rec.supp_loc_count_ind);
            MSC_SCH_WB.ATP_Debug('  -> Inventory type: '||c_ssa_rec.inv_type_ind);
            MSC_SCH_WB.ATP_Debug('  -> Rank: '||c_ssa_rec.rank);
            MSC_SCH_WB.ATP_Debug('  -> Primary Supply Indicator: '||c_ssa_rec.primary_supp_ind);
            MSC_SCH_WB.ATP_Debug('  -> Lead Time: '||c_ssa_rec.lead_time);
            MSC_SCH_WB.ATP_Debug('  -> Drop Ship Code: '||c_ssa_rec.drop_ship_cd);
            MSC_SCH_WB.ATP_Debug('  -> Backorders allowed Flag: '||c_ssa_rec.backorders_allowed_flag);
            MSC_SCH_WB.ATP_Debug('  -> MLSS Header ID: '||c_ssa_rec.mlss_header_id);
         END IF;

         /*
         dbms_output.put_line(' -------------------------------------------------- ');
         dbms_output.put_line('  -> ASL ID: '||c_ssa_rec.asl_id);
         dbms_output.put_line('  -> Vendor ID: '||c_ssa_rec.vendor_id);
         dbms_output.put_line('  -> Vendor Site ID: '||c_ssa_rec.vendor_site_id);
         dbms_output.put_line('  -> MLS/SLS: '||c_ssa_rec.supp_loc_count_ind);
         dbms_output.put_line('  -> Inventory type: '||c_ssa_rec.inv_type_ind);
         dbms_output.put_line('  -> Rank: '||c_ssa_rec.rank);
         dbms_output.put_line('  -> Primary Supply Indicator: '||c_ssa_rec.primary_supp_ind);
         dbms_output.put_line('  -> Lead Time: '||c_ssa_rec.lead_time);
         dbms_output.put_line('  -> Drop Ship Code: '||c_ssa_rec.drop_ship_cd);
         dbms_output.put_line('  -> Backorders allowed Flag: '||c_ssa_rec.backorders_allowed_flag);
         dbms_output.put_line('  -> MLSS Header ID: '||c_ssa_rec.mlss_header_id);
         */

         i := i+1;

         l_ext_ssa_typ.asl_id.extend(1);
         l_ext_ssa_typ.using_org_id.extend(1);
         l_ext_ssa_typ.item_id.extend(1);
         l_ext_ssa_typ.vendor_id.extend(1);
         l_ext_ssa_typ.vendor_site_id.extend(1);
         l_ext_ssa_typ.vm_indicator.extend(1);
         l_ext_ssa_typ.rank.extend(1);
         l_ext_ssa_typ.supp_loc_count_ind.extend(1);
         l_ext_ssa_typ.inv_type_ind.extend(1);
         l_ext_ssa_typ.lead_time.extend(1);
         l_ext_ssa_typ.drop_ship_cd.extend(1);
         l_ext_ssa_typ.primary_supp_ind.extend(1);
         l_ext_ssa_typ.primary_vendor_item.extend(1);
         l_ext_ssa_typ.legacy_vendor_number.extend(1);
         l_ext_ssa_typ.backorders_allowed_flag.extend(1);
         l_ext_ssa_typ.mlss_header_id.extend(1);
         l_ext_ssa_typ.qty.extend(1);

         l_ext_ssa_typ.asl_id(i) := c_ssa_rec.asl_id;
         l_ext_ssa_typ.using_org_id(i) := c_ssa_rec.using_organization_id;
         l_ext_ssa_typ.item_id(i) := c_ssa_rec.item_id;
         l_ext_ssa_typ.vendor_id(i) := c_ssa_rec.vendor_id;
         l_ext_ssa_typ.vendor_site_id(i) := c_ssa_rec.vendor_site_id;
         l_ext_ssa_typ.vm_indicator(i) := c_ssa_rec.vm_indicator;
         l_ext_ssa_typ.rank(i) := c_ssa_rec.rank;
         l_ext_ssa_typ.supp_loc_count_ind(i) := c_ssa_rec.supp_loc_count_ind;
         l_ext_ssa_typ.inv_type_ind(i) := c_ssa_rec.inv_type_ind;
         l_ext_ssa_typ.lead_time(i) := c_ssa_rec.lead_time;
         l_ext_ssa_typ.drop_ship_cd(i) := c_ssa_rec.drop_ship_cd;
         l_ext_ssa_typ.primary_supp_ind(i) := c_ssa_rec.primary_supp_ind;
         l_ext_ssa_typ.primary_vendor_item(i) := c_ssa_rec.primary_vendor_item;
         l_ext_ssa_typ.legacy_vendor_number(i) := c_ssa_rec.legacy_vendor_number;
         l_ext_ssa_typ.backorders_allowed_flag(i) := c_ssa_rec.backorders_allowed_flag;
         l_ext_ssa_typ.mlss_header_id(i) := c_ssa_rec.mlss_header_id;
               
      END LOOP;

      IF l_ext_ssa_typ.asl_id.COUNT = 0 THEN

         x_error_code := 53;
         x_msg := l_no_availability;
         
         Return;
      END IF;

      l_primary_vendor_id := Null;
      l_primary_vendor_site_id := Null;

      OPEN c_primary_vendor(p_base_org_id, p_inventory_item_id);
      FETCH c_primary_vendor INTO l_primary_vendor_id, l_primary_vendor_site_id;
      CLOSE c_primary_vendor;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug(' -------------------------------------------------- ');
         MSC_SCH_WB.ATP_Debug('  -> Primary Vendor ID: '||l_primary_vendor_id);
         MSC_SCH_WB.ATP_Debug('  -> Primary Vendor Site ID: '||l_primary_vendor_site_id);
      END IF;

      /*
      dbms_output.put_line(' -------------------------------------------------- ');
      dbms_output.put_line('  -> Primary Vendor ID: '||l_primary_vendor_id);
      dbms_output.put_line('  -> Primary Vendor Site ID: '||l_primary_vendor_site_id);
      */

      FOR i IN 1..l_ext_ssa_typ.asl_id.COUNT LOOP

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Processing: vendor ID-'||l_ext_ssa_typ.vendor_id(i)
                       ||' vendor site ID-'||l_ext_ssa_typ.vendor_site_id(i));
         END IF;
         /*
         dbms_output.put_line('  -> Processing: vendor ID-'||l_ext_ssa_typ.vendor_id(i)
                       ||' vendor site ID-'||l_ext_ssa_typ.vendor_site_id(i));
         */

         l_imu_amt_pt           := Null;
         l_imu_value            := Null;
         l_supply_loc_no        := Null;
         l_supply_type          := Null;
         l_mlss_ds_lt           := Null;
         l_mlss_b2b_lt          := Null;
         l_vendor_facility_code := Null;  
         l_vendor_account       := Null;
         l_ship_date            := Null;
         l_arrival_date         := Null;
         l_ship_method          := Null;
         l_end_point            := Null;
         m                      := 0;
 
         l_rt_availability_typ.org_id.DELETE;
         l_rt_availability_typ.vendor_id.DELETE;
         l_rt_availability_typ.vendor_site_id.DELETE;
         l_rt_availability_typ.supplier_type.DELETE;
         l_rt_availability_typ.inventory_item_id.DELETE;
         l_rt_availability_typ.primary_vendor_item.DELETE;
         l_rt_availability_typ.legacy_vendor_number.DELETE;
         l_rt_availability_typ.quantity_ordered.DELETE;
         l_rt_availability_typ.supply_loc_no.DELETE;
         l_rt_availability_typ.rank.DELETE;
         l_rt_availability_typ.end_point.DELETE;
         l_rt_availability_typ.ds_lt.DELETE;
         l_rt_availability_typ.b2b_lt.DELETE;
         l_rt_availability_typ.supp_loc_ac.DELETE;
         l_rt_availability_typ.supp_facility_cd.DELETE;
         l_rt_availability_typ.imu_amt_pt.DELETE;
         l_rt_availability_typ.imu_value.DELETE;
         l_rt_availability_typ.qty.DELETE;
         l_rt_availability_typ.supplier_response_code.DELETE;

         IF l_ext_ssa_typ.supp_loc_count_ind(i) = 'S' THEN

            l_supply_type := 'S';

            IF l_ext_ssa_typ.inv_type_ind(i) = 'I' THEN

               XX_MSC_SOURCING_DATE_CALC_PKG.Get_External_ATP_Dates
                  (
                      p_customer_number      => p_customer_number,
                      p_ship_method          => p_ship_method,
                      p_category_name        => p_category_name,
                      p_bulk                 => p_bulk,
                      p_zone_id              => p_zone_id,
                      p_base_org_id          => p_base_org_id,
                      p_drop_ship_cd         => Nvl(p_drop_ship_cd, 'D'),
                      p_supply_type          => l_supply_type,
                      p_ssa_lead_time        => Nvl(l_ext_ssa_typ.lead_time(i), 0),
                      p_supply_loc_no        => Null,
                      p_vendor_id            => l_ext_ssa_typ.vendor_id(i),
                      p_vendor_site_id       => l_ext_ssa_typ.vendor_site_id(i),
                      p_mlss_ds_lt           => Null,
                      p_mlss_b2b_lt          => Null,
                      p_current_date_time    => Null,
                      p_timezone_code        => Null,
                      p_mlss_cutoff_time     => Null,
                      x_ship_date            => l_ship_date,
                      x_arrival_date         => l_arrival_date,
                      x_ship_method          => l_ship_method,
                      x_return_status        => x_return_status,
                      x_msg                  => x_msg
                   );

               IF x_return_status <> 'S' THEN
                  Return;
               END IF;

               x_source_org_id         := p_base_org_id;
               x_ship_date             := l_ship_date;
               x_arrival_date          := l_arrival_date;
               x_vendor_id             := l_ext_ssa_typ.vendor_id(i);
               x_vendor_site_id        := l_ext_ssa_typ.vendor_site_id(i);
               x_vendor_type           := l_ext_ssa_typ.supp_loc_count_ind(i);
               x_vendor_facility_code  := Null;  
               x_vendor_account        := Null;
               x_drop_ship_cd          := l_ext_ssa_typ.drop_ship_cd(i);
               x_requested_date_qty    := l_ext_ssa_typ.qty(i);
               x_error_code            := 0;
               x_ship_method           := l_ship_method;

               Return;

            ELSIF l_ext_ssa_typ.inv_type_ind(i) = 'F' THEN

               IF NOT l_feed_done THEN

                  l_feed_done := TRUE;

                  Get_Feed_Data
                    (
                        p_base_org_id            => p_base_org_id,
                        p_inventory_item_id      => p_inventory_item_id, 
                        p_operating_unit         => p_operating_unit, 
                        p_vm_indicator           => l_vm_indicator, 
                        p_drop_ship_cd           => p_drop_ship_cd,
                        x_feed_availability_typ  => l_feed_availability_typ,
                        x_return_status          => x_return_status,
                        x_msg                    => x_msg
                     );

                  IF x_return_status <> 'S' THEN
                     Return;
                  END IF;

                  FOR k in 1..l_feed_availability_typ.vendor_id.COUNT LOOP
                     FOR l in 1..l_ext_ssa_typ.asl_id.COUNT LOOP
                        IF l_ext_ssa_typ.vendor_id(l) = l_feed_availability_typ.vendor_id(k) THEN
                           IF l_ext_ssa_typ.inv_type_ind(l) = 'F' THEN
                              l_ext_ssa_typ.qty(l) := l_feed_availability_typ.qty(k);
                           END IF;
                        END IF;
                     END LOOP;
                  END LOOP;

                  IF PG_DEBUG in ('Y', 'C') THEN
                     FOR d IN 1..l_ext_ssa_typ.asl_id.COUNT LOOP
                        MSC_SCH_WB.ATP_Debug('  -> vendor ID: '||l_ext_ssa_typ.vendor_id(d)||' = '
                                       ||l_ext_ssa_typ.inv_type_ind(d)||' = '||l_ext_ssa_typ.qty(d));
                     END LOOP;
                  END IF;

                  ------------------------------------------------------------------------------
                  FOR d IN 1..l_ext_ssa_typ.asl_id.COUNT LOOP
                     dbms_output.put_line('  -> vendor ID: '||l_ext_ssa_typ.vendor_id(d)||' = '
                                    ||l_ext_ssa_typ.inv_type_ind(d)||' = '||l_ext_ssa_typ.qty(d));
                  END LOOP;
                  -------------------------------------------------------------------------------

               END IF;

               IF ( Nvl(l_ext_ssa_typ.qty(i), 0) >= p_quantity_ordered ) THEN

                  XX_MSC_SOURCING_DATE_CALC_PKG.Get_External_ATP_Dates
                     (
                         p_customer_number      => p_customer_number,
                         p_ship_method          => p_ship_method,
                         p_category_name        => p_category_name,
                         p_bulk                 => p_bulk,
                         p_zone_id              => p_zone_id,
                         p_base_org_id          => p_base_org_id,
                         p_drop_ship_cd         => Nvl(p_drop_ship_cd, 'D'),
                         p_supply_type          => l_supply_type,
                         p_ssa_lead_time        => Nvl(l_ext_ssa_typ.lead_time(i), 0),
                         p_supply_loc_no        => Null,
                         p_vendor_id            => l_ext_ssa_typ.vendor_id(i),
                         p_vendor_site_id       => l_ext_ssa_typ.vendor_site_id(i),
                         p_mlss_ds_lt           => Null,
                         p_mlss_b2b_lt          => Null,
                         p_current_date_time    => Null,
                         p_timezone_code        => Null,
                         p_mlss_cutoff_time     => Null,
                         x_ship_date            => l_ship_date,
                         x_arrival_date         => l_arrival_date,
                         x_ship_method          => l_ship_method,
                         x_return_status        => x_return_status,
                         x_msg                  => x_msg
                      );

                  IF x_return_status <> 'S' THEN
                     Return;
                  END IF;

                  x_source_org_id         := p_base_org_id;
                  x_ship_date             := l_ship_date;
                  x_arrival_date          := l_arrival_date;
                  x_vendor_id             := l_ext_ssa_typ.vendor_id(i);
                  x_vendor_site_id        := l_ext_ssa_typ.vendor_site_id(i);
                  x_vendor_type           := l_ext_ssa_typ.supp_loc_count_ind(i);
                  x_vendor_facility_code  := Null;  
                  x_vendor_account        := Null;
                  x_drop_ship_cd          := l_ext_ssa_typ.drop_ship_cd(i);
                  x_requested_date_qty    := l_ext_ssa_typ.qty(i);
                  x_error_code            := 0;
                  x_ship_method           := l_ship_method;

                  Return;

               ELSE

                  IF l_ext_ssa_typ.backorders_allowed_flag(i) = 'Y' THEN
                     IF NOT l_bo_assignment_found THEN

                        XX_MSC_SOURCING_DATE_CALC_PKG.Get_External_ATP_Dates
                           (
                               p_customer_number      => p_customer_number,
                               p_ship_method          => p_ship_method,
                               p_category_name        => p_category_name,
                               p_bulk                 => p_bulk,
                               p_zone_id              => p_zone_id,
                               p_base_org_id          => p_base_org_id,
                               p_drop_ship_cd         => Nvl(p_drop_ship_cd, 'D'),
                               p_supply_type          => l_supply_type,
                               p_ssa_lead_time        => Nvl(l_ext_ssa_typ.lead_time(i), 0),
                               p_supply_loc_no        => Null,
                               p_vendor_id            => l_ext_ssa_typ.vendor_id(i),
                               p_vendor_site_id       => l_ext_ssa_typ.vendor_site_id(i),
                               p_mlss_ds_lt           => Null,
                               p_mlss_b2b_lt          => Null,
                               p_current_date_time    => Null,
                               p_timezone_code        => Null,
                               p_mlss_cutoff_time     => Null,
                               x_ship_date            => l_ship_date,
                               x_arrival_date         => l_arrival_date,
                               x_ship_method          => l_ship_method,
                               x_return_status        => x_return_status,
                               x_msg                  => x_msg
                            );

                        IF x_return_status <> 'S' THEN
                           Return;
                        END IF;

                        l_bo_source_org_id         := p_base_org_id;
                        l_bo_ship_date             := l_ship_date;
                        l_bo_arrival_date          := l_arrival_date;
                        l_bo_vendor_id             := l_ext_ssa_typ.vendor_id(i);
                        l_bo_vendor_site_id        := l_ext_ssa_typ.vendor_site_id(i);
                        l_bo_vendor_type           := l_ext_ssa_typ.supp_loc_count_ind(i);
                        l_bo_vendor_facility_code  := Null;  
                        l_bo_vendor_account        := Null;
                        l_bo_drop_ship_cd          := l_ext_ssa_typ.drop_ship_cd(i);
                        l_bo_requested_date_qty    := Nvl(l_ext_ssa_typ.qty(i), 0);
                        l_bo_error_code            := 0;
                        l_bo_ship_method           := l_ship_method;

                        l_bo_assignment_found := TRUE;

                     END IF;

                  END IF;

               END IF;

            ELSIF l_ext_ssa_typ.inv_type_ind(i) = 'R' THEN

               l_rt_availability_typ.org_id.extend(1);
               l_rt_availability_typ.org_id(1) := p_operating_unit;
               l_rt_availability_typ.vendor_id.extend(1);
               l_rt_availability_typ.vendor_id(1) := l_ext_ssa_typ.vendor_id(i);
               l_rt_availability_typ.vendor_site_id.extend(1);
               l_rt_availability_typ.vendor_site_id(1) := l_ext_ssa_typ.vendor_site_id(i);
               l_rt_availability_typ.supplier_type.extend(1);
               l_rt_availability_typ.supplier_type(1) := l_ext_ssa_typ.supp_loc_count_ind(i);
               l_rt_availability_typ.inventory_item_id.extend(1);
               l_rt_availability_typ.inventory_item_id(1) := p_inventory_item_id;
               l_rt_availability_typ.primary_vendor_item.extend(1);
               l_rt_availability_typ.primary_vendor_item(1) := l_ext_ssa_typ.primary_vendor_item(i);
               l_rt_availability_typ.legacy_vendor_number.extend(1);
               l_rt_availability_typ.legacy_vendor_number(1) := l_ext_ssa_typ.legacy_vendor_number(i);
               l_rt_availability_typ.quantity_ordered.extend(1);
               l_rt_availability_typ.quantity_ordered(1) := p_quantity_ordered;
               l_rt_availability_typ.supply_loc_no.extend(1);
               l_rt_availability_typ.supply_loc_no(1) := Null;
               l_rt_availability_typ.rank.extend(1);
               l_rt_availability_typ.rank(1) := Null;
               l_rt_availability_typ.end_point.extend(1);
               l_rt_availability_typ.end_point(1) := Null;
               l_rt_availability_typ.ds_lt.extend(1);
               l_rt_availability_typ.ds_lt(1) := Null;
               l_rt_availability_typ.b2b_lt.extend(1);
               l_rt_availability_typ.b2b_lt(1) := Null;
               l_rt_availability_typ.supp_loc_ac.extend(1);
               l_rt_availability_typ.supp_loc_ac(1) := Null;  
               l_rt_availability_typ.supp_facility_cd.extend(1);
               l_rt_availability_typ.supp_facility_cd(1) := Null; 
               l_rt_availability_typ.imu_amt_pt.extend(1);
               l_rt_availability_typ.imu_amt_pt(1) := Null;
               l_rt_availability_typ.imu_value.extend(1);
               l_rt_availability_typ.imu_value(1) := Null;
               l_rt_availability_typ.qty.extend(1);
               l_rt_availability_typ.supplier_response_code.extend(1);

---------------------------
               --- *** testing only ***
               temp_pkg.Get_Real_time_data
                  (
                      x_rt_availability_typ  => l_rt_availability_typ,
                      x_return_status        => x_return_status,
                      x_msg                  => x_msg
                  );
----------------------------

               IF x_return_status <> 'S' THEN
                  Return;
               END IF;

               IF PG_DEBUG in ('Y', 'C') THEN
                  MSC_SCH_WB.ATP_Debug('===================================');
                  MSC_SCH_WB.ATP_Debug('  -> SLS: Real time data:');
                  FOR a in 1..l_rt_availability_typ.supply_loc_no.COUNT LOOP
                     MSC_SCH_WB.ATP_Debug('  -> vendor ID: '||l_rt_availability_typ.vendor_id(a));
                     MSC_SCH_WB.ATP_Debug('  -> vendor site ID: '||l_rt_availability_typ.vendor_site_id(a));
                     MSC_SCH_WB.ATP_Debug('  -> supply location No: '||l_rt_availability_typ.supply_loc_no(a));
                     MSC_SCH_WB.ATP_Debug('  -> Rank: '||l_rt_availability_typ.rank(a));
                     MSC_SCH_WB.ATP_Debug('  -> End Point: '||l_rt_availability_typ.end_point(a));
                     MSC_SCH_WB.ATP_Debug('  -> DS Lead Time: '||l_rt_availability_typ.ds_lt(a));
                     MSC_SCH_WB.ATP_Debug('  -> B2B Lead Time: '||l_rt_availability_typ.b2b_lt(a));
                     MSC_SCH_WB.ATP_Debug('  -> Supply Location Account: '||l_rt_availability_typ.supp_loc_ac(a));
                     MSC_SCH_WB.ATP_Debug('  -> Supply Facility Code: '||l_rt_availability_typ.supp_facility_cd(a));
                     MSC_SCH_WB.ATP_Debug('  -> Qty: '||l_rt_availability_typ.qty(a));
                  END LOOP;
                  MSC_SCH_WB.ATP_Debug('===================================');
               END IF;


               IF ( l_rt_availability_typ.qty(1) >= p_quantity_ordered ) THEN

                  XX_MSC_SOURCING_DATE_CALC_PKG.Get_External_ATP_Dates
                     (
                         p_customer_number      => p_customer_number,
                         p_ship_method          => p_ship_method,
                         p_category_name        => p_category_name,
                         p_bulk                 => p_bulk,
                         p_zone_id              => p_zone_id,
                         p_base_org_id          => p_base_org_id,
                         p_drop_ship_cd         => Nvl(p_drop_ship_cd, 'D'),
                         p_supply_type          => l_supply_type,
                         p_ssa_lead_time        => Nvl(l_ext_ssa_typ.lead_time(i), 0),
                         p_supply_loc_no        => Null,
                         p_vendor_id            => l_ext_ssa_typ.vendor_id(i),
                         p_vendor_site_id       => l_ext_ssa_typ.vendor_site_id(i),
                         p_mlss_ds_lt           => Null,
                         p_mlss_b2b_lt          => Null,
                         p_current_date_time    => Null,
                         p_timezone_code        => Null,
                         p_mlss_cutoff_time     => Null,
                         x_ship_date            => l_ship_date,
                         x_arrival_date         => l_arrival_date,
                         x_ship_method          => l_ship_method,
                         x_return_status        => x_return_status,
                         x_msg                  => x_msg
                      );

                  IF x_return_status <> 'S' THEN
                     Return;
                  END IF;

                  x_source_org_id         := p_base_org_id;
                  x_ship_date             := l_ship_date;
                  x_arrival_date          := l_arrival_date;
                  x_vendor_id             := l_ext_ssa_typ.vendor_id(i);
                  x_vendor_site_id        := l_ext_ssa_typ.vendor_site_id(i);
                  x_vendor_type           := l_ext_ssa_typ.supp_loc_count_ind(i);
                  x_vendor_facility_code  := Null;  
                  x_vendor_account        := Null;
                  x_drop_ship_cd          := l_ext_ssa_typ.drop_ship_cd(i);
                  x_requested_date_qty    := l_rt_availability_typ.qty(1);
                  x_error_code            := 0;
                  x_ship_method           := l_ship_method;

                  Return;

               ELSE

                  IF l_ext_ssa_typ.backorders_allowed_flag(i) = 'Y' THEN
                     IF NOT l_bo_assignment_found THEN

                        XX_MSC_SOURCING_DATE_CALC_PKG.Get_External_ATP_Dates
                           (
                               p_customer_number      => p_customer_number,
                               p_ship_method          => p_ship_method,
                               p_category_name        => p_category_name,
                               p_bulk                 => p_bulk,
                               p_zone_id              => p_zone_id,
                               p_base_org_id          => p_base_org_id,
                               p_drop_ship_cd         => Nvl(p_drop_ship_cd, 'D'),
                               p_supply_type          => l_supply_type,
                               p_ssa_lead_time        => Nvl(l_ext_ssa_typ.lead_time(i), 0),
                               p_supply_loc_no        => Null,
                               p_vendor_id            => l_ext_ssa_typ.vendor_id(i),
                               p_vendor_site_id       => l_ext_ssa_typ.vendor_site_id(i),
                               p_mlss_ds_lt           => Null,
                               p_mlss_b2b_lt          => Null,
                               p_current_date_time    => p_current_date_time,
                               p_timezone_code        => p_timezone_code,
                               p_mlss_cutoff_time     => l_mlss_cutoff_time,
                               x_ship_date            => l_ship_date,
                               x_arrival_date         => l_arrival_date,
                               x_ship_method          => l_ship_method,
                               x_return_status        => x_return_status,
                               x_msg                  => x_msg
                            ); 

                        IF x_return_status <> 'S' THEN
                           Return;
                        END IF;

                        l_bo_source_org_id         := p_base_org_id;
                        l_bo_ship_date             := l_ship_date;
                        l_bo_arrival_date          := l_arrival_date;
                        l_bo_vendor_id             := l_ext_ssa_typ.vendor_id(i);
                        l_bo_vendor_site_id        := l_ext_ssa_typ.vendor_site_id(i);
                        l_bo_vendor_type           := l_ext_ssa_typ.supp_loc_count_ind(i);
                        l_bo_vendor_facility_code  := Null;  
                        l_bo_vendor_account        := Null;
                        l_bo_drop_ship_cd          := l_ext_ssa_typ.drop_ship_cd(i);
                        l_bo_requested_date_qty    := l_rt_availability_typ.qty(1);
                        l_bo_error_code            := 0;
                        l_bo_ship_method           := l_ship_method;

                        l_bo_assignment_found := TRUE;

                     END IF;
                  END IF;
               END IF;

            END IF;

         ELSIF l_ext_ssa_typ.supp_loc_count_ind(i) = 'M' THEN

            FOR p IN i..l_ext_ssa_typ.asl_id.COUNT LOOP

               IF l_ext_ssa_typ.supp_loc_count_ind(p) = 'M' THEN

                  XX_MSC_SOURCING_UTIL_PKG.Do_IMU_Check
                     (
                        p_item_id                 => p_inventory_item_id,
                        p_quantity_ordered        => p_quantity_ordered,
                        p_mlss_header_id          => l_ext_ssa_typ.mlss_header_id(p),
                        p_unit_selling_price      => p_unit_selling_price,
                        p_vendor_id               => l_ext_ssa_typ.vendor_id(p),
                        p_vendor_site_id          => l_ext_ssa_typ.vendor_site_id(p),
                        p_primary_vendor_id       => l_primary_vendor_id,
                        p_primary_vendor_site_id  => l_primary_vendor_site_id,
                        p_operating_unit          => p_operating_unit,
                        x_imu_check               => l_imu_check,
                        x_return_status           => x_return_status,
                        x_msg                     => x_msg
                     );

                  IF x_return_status <> 'S' THEN
                     Return;
                  END IF;

                  IF PG_DEBUG in ('Y', 'C') THEN
                     MSC_SCH_WB.ATP_Debug('  -> IMU Check: '||l_imu_check);
                  END IF;

                  IF l_imu_check = 'Accept' THEN

                     FOR c_mlss_rec IN c_mlss (l_ext_ssa_typ.mlss_header_id(p),
                                               l_ext_ssa_typ.vendor_id(p),
                                               l_ext_ssa_typ.vendor_site_id(p),
                                               p_drop_ship_cd) LOOP

                        m := m+1;

                        l_rt_availability_typ.org_id.extend(1);
                        l_rt_availability_typ.org_id(m) := p_operating_unit;
                        l_rt_availability_typ.vendor_id.extend(1);
                        l_rt_availability_typ.vendor_id(m) := l_ext_ssa_typ.vendor_id(p);
                        l_rt_availability_typ.vendor_site_id.extend(1);
                        l_rt_availability_typ.vendor_site_id(m) := l_ext_ssa_typ.vendor_site_id(p);
                        l_rt_availability_typ.supplier_type.extend(1);
                        l_rt_availability_typ.supplier_type(m) := l_ext_ssa_typ.supp_loc_count_ind(p);
                        l_rt_availability_typ.inventory_item_id.extend(1);
                        l_rt_availability_typ.inventory_item_id(m) := p_inventory_item_id;
                        l_rt_availability_typ.primary_vendor_item.extend(1);
                        l_rt_availability_typ.primary_vendor_item(m) := l_ext_ssa_typ.primary_vendor_item(p);
                        l_rt_availability_typ.legacy_vendor_number.extend(1);
                        l_rt_availability_typ.legacy_vendor_number(m) := l_ext_ssa_typ.legacy_vendor_number(p);
                        l_rt_availability_typ.quantity_ordered.extend(1);
                        l_rt_availability_typ.quantity_ordered(m) := p_quantity_ordered;
                        l_rt_availability_typ.supply_loc_no.extend(1);
                        l_rt_availability_typ.supply_loc_no(m) := c_mlss_rec.supply_loc_no;
                        l_rt_availability_typ.rank.extend(1);
                        l_rt_availability_typ.rank(m) := c_mlss_rec.rank;
                        l_rt_availability_typ.end_point.extend(1);
                        l_rt_availability_typ.end_point(m) := c_mlss_rec.end_point;
                        l_rt_availability_typ.ds_lt.extend(1);
                        l_rt_availability_typ.ds_lt(m) := c_mlss_rec.ds_lt;
                        l_rt_availability_typ.b2b_lt.extend(1);
                        l_rt_availability_typ.b2b_lt(m) := c_mlss_rec.b2b_lt;
                        l_rt_availability_typ.supp_loc_ac.extend(1);
                        l_rt_availability_typ.supp_loc_ac(m) := c_mlss_rec.supp_loc_ac;  
                        l_rt_availability_typ.supp_facility_cd.extend(1);
                        l_rt_availability_typ.supp_facility_cd(m) := c_mlss_rec.supp_facility_cd; 
                        l_rt_availability_typ.imu_amt_pt.extend(1);
                        l_rt_availability_typ.imu_amt_pt(m) := c_mlss_rec.imu_amt_pt;
                        l_rt_availability_typ.imu_value.extend(1);
                        l_rt_availability_typ.imu_value(m) := c_mlss_rec.imu_value; 
                        l_rt_availability_typ.qty.extend(1);
                        l_rt_availability_typ.supplier_response_code.extend(1);

                     END LOOP;

                  END IF;

               END IF;

            END LOOP;

            IF l_rt_availability_typ.supply_loc_no.COUNT <> 0 THEN
  
               -- Sort by MLS rank only 07-Feb-2008

               IF l_rt_availability_typ.supply_loc_no.COUNT > 1 THEN
                  FOR x IN 1..l_rt_availability_typ.supply_loc_no.COUNT-1 LOOP
                     FOR y IN x+1..l_rt_availability_typ.supply_loc_no.COUNT LOOP
                        IF l_rt_availability_typ.rank(x) > l_rt_availability_typ.rank(y) THEN

                           t_org_id                 := l_rt_availability_typ.org_id(x);
                           t_vendor_id              := l_rt_availability_typ.vendor_id(x);
                           t_vendor_site_id         := l_rt_availability_typ.vendor_site_id(x);
                           t_supplier_type          := l_rt_availability_typ.supplier_type(x);
                           t_inventory_item_id      := l_rt_availability_typ.inventory_item_id(x);
                           t_primary_vendor_item    := l_rt_availability_typ.primary_vendor_item(x);
                           t_legacy_vendor_number   := l_rt_availability_typ.legacy_vendor_number(x);
                           t_quantity_ordered       := l_rt_availability_typ.quantity_ordered(x);
                           t_supply_loc_no          := l_rt_availability_typ.supply_loc_no(x);
                           t_rank                   := l_rt_availability_typ.rank(x);
                           t_end_point              := l_rt_availability_typ.end_point(x);
                           t_ds_lt                  := l_rt_availability_typ.ds_lt(x);
                           t_b2b_lt                 := l_rt_availability_typ.b2b_lt(x);
                           t_supp_loc_ac            := l_rt_availability_typ.supp_loc_ac(x);
                           t_supp_facility_cd       := l_rt_availability_typ.supp_facility_cd(x); 
                           t_imu_amt_pt             := l_rt_availability_typ.imu_amt_pt(x);
                           t_imu_value              := l_rt_availability_typ.imu_value(x);   
                           t_qty                    := l_rt_availability_typ.qty(x);
                           t_supplier_response_code := l_rt_availability_typ.supplier_response_code(x);

                           l_rt_availability_typ.org_id(x)                 := l_rt_availability_typ.org_id(y);
                           l_rt_availability_typ.vendor_id(x)              := l_rt_availability_typ.vendor_id(y);
                           l_rt_availability_typ.vendor_site_id(x)         := l_rt_availability_typ.vendor_site_id(y);
                           l_rt_availability_typ.supplier_type(x)          := l_rt_availability_typ.supplier_type(y);
                           l_rt_availability_typ.inventory_item_id(x)      := l_rt_availability_typ.inventory_item_id(y);
                           l_rt_availability_typ.primary_vendor_item(x)    := l_rt_availability_typ.primary_vendor_item(y);
                           l_rt_availability_typ.legacy_vendor_number(x)   := l_rt_availability_typ.legacy_vendor_number(y);
                           l_rt_availability_typ.quantity_ordered(x)       := l_rt_availability_typ.quantity_ordered(y);
                           l_rt_availability_typ.supply_loc_no(x)          := l_rt_availability_typ.supply_loc_no(y);
                           l_rt_availability_typ.rank(x)                   := l_rt_availability_typ.rank(y);
                           l_rt_availability_typ.end_point(x)              := l_rt_availability_typ.end_point(y);
                           l_rt_availability_typ.ds_lt(x)                  := l_rt_availability_typ.ds_lt(y);
                           l_rt_availability_typ.b2b_lt(x)                 := l_rt_availability_typ.b2b_lt(y);
                           l_rt_availability_typ.supp_loc_ac(x)            := l_rt_availability_typ.supp_loc_ac(y);
                           l_rt_availability_typ.supp_facility_cd(x)       := l_rt_availability_typ.supp_facility_cd(y); 
                           l_rt_availability_typ.imu_amt_pt(x)             := l_rt_availability_typ.imu_amt_pt(y);
                           l_rt_availability_typ.imu_value(x)              := l_rt_availability_typ.imu_value(y);    
                           l_rt_availability_typ.qty(x)                    := l_rt_availability_typ.qty(y);
                           l_rt_availability_typ.supplier_response_code(x) := l_rt_availability_typ.supplier_response_code(y);

                           l_rt_availability_typ.org_id(y)                 := t_org_id;
                           l_rt_availability_typ.vendor_id(y)              := t_vendor_id;
                           l_rt_availability_typ.vendor_site_id(y)         := t_vendor_site_id;
                           l_rt_availability_typ.supplier_type(y)          := t_supplier_type;
                           l_rt_availability_typ.inventory_item_id(y)      := t_inventory_item_id;
                           l_rt_availability_typ.primary_vendor_item(y)    := t_primary_vendor_item;
                           l_rt_availability_typ.legacy_vendor_number(y)   := t_legacy_vendor_number;
                           l_rt_availability_typ.quantity_ordered(y)       := t_quantity_ordered;
                           l_rt_availability_typ.supply_loc_no(y)          := t_supply_loc_no;
                           l_rt_availability_typ.rank(y)                   := t_rank;
                           l_rt_availability_typ.end_point(y)              := t_end_point;
                           l_rt_availability_typ.ds_lt(y)                  := t_ds_lt;
                           l_rt_availability_typ.b2b_lt(y)                 := t_b2b_lt;
                           l_rt_availability_typ.supp_loc_ac(y)            := t_supp_loc_ac;
                           l_rt_availability_typ.supp_facility_cd(y)       := t_supp_facility_cd; 
                           l_rt_availability_typ.imu_amt_pt(y)             := t_imu_amt_pt;
                           l_rt_availability_typ.imu_value(y)              := t_imu_value;    
                           l_rt_availability_typ.qty(y)                    := t_qty;
                           l_rt_availability_typ.supplier_response_code(y) := t_supplier_response_code;

                        END IF;
                     END LOOP;
                  END LOOP;
               END IF;
               ----------

---------------------------
               --- *** testing only ***
               temp_pkg.Get_Real_time_data
                  (
                      x_rt_availability_typ  => l_rt_availability_typ,
                      x_return_status        => x_return_status,
                      x_msg                  => x_msg
                  );
---------------------------

               IF x_return_status <> 'S' THEN
                  Return;
               END IF;

               IF PG_DEBUG in ('Y', 'C') THEN
                  MSC_SCH_WB.ATP_Debug('===================================');
                  MSC_SCH_WB.ATP_Debug('  -> MLS: Real time data:');
                  FOR a in 1..l_rt_availability_typ.supply_loc_no.COUNT LOOP
                     MSC_SCH_WB.ATP_Debug('  -> vendor ID: '||l_rt_availability_typ.vendor_id(a));
                     MSC_SCH_WB.ATP_Debug('  -> vendor site ID: '||l_rt_availability_typ.vendor_site_id(a));
                     MSC_SCH_WB.ATP_Debug('  -> supply location No: '||l_rt_availability_typ.supply_loc_no(a));
                     MSC_SCH_WB.ATP_Debug('  -> Rank: '||l_rt_availability_typ.rank(a));
                     MSC_SCH_WB.ATP_Debug('  -> End Point: '||l_rt_availability_typ.end_point(a));
                     MSC_SCH_WB.ATP_Debug('  -> DS Lead Time: '||l_rt_availability_typ.ds_lt(a));
                     MSC_SCH_WB.ATP_Debug('  -> B2B Lead Time: '||l_rt_availability_typ.b2b_lt(a));
                     MSC_SCH_WB.ATP_Debug('  -> Supply Location Account: '||l_rt_availability_typ.supp_loc_ac(a));
                     MSC_SCH_WB.ATP_Debug('  -> Supply Facility Code: '||l_rt_availability_typ.supp_facility_cd(a));
                     MSC_SCH_WB.ATP_Debug('  -> Qty: '||l_rt_availability_typ.qty(a));
                  END LOOP;
                  MSC_SCH_WB.ATP_Debug('===================================');
               END IF;

               FOR n IN 1..l_rt_availability_typ.supply_loc_no.COUNT LOOP
                  IF l_rt_availability_typ.qty(n) >= p_quantity_ordered THEN

                     l_supply_type := 'M';
 
                     XX_MSC_SOURCING_DATE_CALC_PKG.Get_External_ATP_Dates
                        (
                            p_customer_number      => p_customer_number,
                            p_ship_method          => p_ship_method,
                            p_category_name        => p_category_name,
                            p_bulk                 => p_bulk,
                            p_zone_id              => p_zone_id,
                            p_base_org_id          => p_base_org_id,
                            p_drop_ship_cd         => Nvl(p_drop_ship_cd, 'D'),
                            p_supply_type          => l_supply_type,
                            p_ssa_lead_time        => Null,
                            p_supply_loc_no        => l_rt_availability_typ.supply_loc_no(n),
                            p_vendor_id            => l_ext_ssa_typ.vendor_id(i),
                            p_vendor_site_id       => l_ext_ssa_typ.vendor_site_id(i),
                            p_mlss_ds_lt           => Nvl(l_rt_availability_typ.ds_lt(n), 0),
                            p_mlss_b2b_lt          => Nvl(l_rt_availability_typ.b2b_lt(n), 0),
                            p_current_date_time    => p_current_date_time,
                            p_timezone_code        => p_timezone_code,
                            p_mlss_cutoff_time     => l_mlss_cutoff_time,
                            x_ship_date            => l_ship_date,
                            x_arrival_date         => l_arrival_date,
                            x_ship_method          => l_ship_method,
                            x_return_status        => x_return_status,
                            x_msg                  => x_msg
                        );

                     IF x_return_status <> 'S' THEN
                        Return;
                     END IF;

                     x_source_org_id         := p_base_org_id;
                     x_ship_date             := l_ship_date;
                     x_arrival_date          := l_arrival_date;
                     x_vendor_id             := l_ext_ssa_typ.vendor_id(i);
                     x_vendor_site_id        := l_ext_ssa_typ.vendor_site_id(i);
                     x_vendor_type           := l_ext_ssa_typ.supp_loc_count_ind(i);
                     x_vendor_facility_code  := l_rt_availability_typ.supp_facility_cd(n);  
                     x_vendor_account        := l_rt_availability_typ.supp_loc_ac(n);
                     x_requested_date_qty    := l_rt_availability_typ.qty(n);
                     x_drop_ship_cd          := l_rt_availability_typ.end_point(n);
                     x_error_code            := 0;
                     x_ship_method           := l_ship_method;

                     Return;

                  ELSE

                     IF l_ext_ssa_typ.backorders_allowed_flag(i) = 'Y' THEN
                        IF NOT l_bo_assignment_found THEN
                            XX_MSC_SOURCING_DATE_CALC_PKG.Get_External_ATP_Dates
                              (
                                  p_customer_number      => p_customer_number,
                                  p_ship_method          => p_ship_method,
                                  p_category_name        => p_category_name,
                                  p_bulk                 => p_bulk,
                                  p_zone_id              => p_zone_id,
                                  p_base_org_id          => p_base_org_id,
                                  p_drop_ship_cd         => Nvl(p_drop_ship_cd, 'D'),
                                  p_supply_type          => l_supply_type,
                                  p_ssa_lead_time        => Null,
                                  p_supply_loc_no        => l_rt_availability_typ.supp_loc_ac(n),
                                  p_vendor_id            => l_ext_ssa_typ.vendor_id(i),
                                  p_vendor_site_id       => l_ext_ssa_typ.vendor_site_id(i),
                                  p_mlss_ds_lt           => Nvl(l_rt_availability_typ.ds_lt(n), 0),
                                  p_mlss_b2b_lt          => Nvl(l_rt_availability_typ.b2b_lt(n), 0),
                                  p_current_date_time    => p_current_date_time,
                                  p_timezone_code        => p_timezone_code,
                                  p_mlss_cutoff_time     => l_mlss_cutoff_time,
                                  x_ship_date            => l_ship_date,
                                  x_arrival_date         => l_arrival_date,
                                  x_ship_method          => l_ship_method,
                                  x_return_status        => x_return_status,
                                  x_msg                  => x_msg
                              );

                           IF x_return_status <> 'S' THEN
                              Return;
                           END IF;

                           l_bo_source_org_id         := p_base_org_id;
                           l_bo_ship_date             := l_ship_date;
                           l_bo_arrival_date          := l_arrival_date;
                           l_bo_vendor_id             := l_ext_ssa_typ.vendor_id(i);
                           l_bo_vendor_site_id        := l_ext_ssa_typ.vendor_site_id(i);
                           l_bo_vendor_type           := l_ext_ssa_typ.supp_loc_count_ind(i);
                           l_bo_vendor_facility_code  := l_rt_availability_typ.supp_facility_cd(n);  
                           l_bo_vendor_account        := l_rt_availability_typ.supp_loc_ac(n);
                           l_bo_drop_ship_cd          := l_rt_availability_typ.end_point(n);
                           l_bo_requested_date_qty    := Null;
                           l_bo_error_code            := 0;
                           l_bo_ship_method           := l_ship_method;
                           l_bo_assignment_found := TRUE;

                        END IF;
                     END IF;

                  END IF;

               END LOOP;

            END IF;

            Exit;

         END IF;

         <<end_loop>>
         Null;

      END LOOP;


      IF l_bo_assignment_found THEN

         x_source_org_id           := l_bo_source_org_id;
         x_ship_date               := l_bo_ship_date;
         x_arrival_date            := l_bo_arrival_date;
         x_vendor_id               := l_bo_vendor_id;
         x_vendor_site_id          := l_bo_vendor_site_id;
         x_vendor_type             := l_bo_vendor_type;
         x_vendor_facility_code    := l_bo_vendor_facility_code;  
         x_vendor_account          := l_bo_vendor_account;
         x_drop_ship_cd            := l_bo_drop_ship_cd;
         x_requested_date_qty      := l_bo_requested_date_qty;
         x_error_code              := l_bo_error_code;
         x_ship_method             := l_bo_ship_method;


         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Back Order');
         END IF;

      ELSE

         x_error_code := 53;
         x_msg        := l_no_availability;

      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Return Status: '||x_return_status);
         MSC_SCH_WB.ATP_Debug('  -> Message: '||x_msg);
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_VENDOR_ATP_PKG.Vendor_ATP() ...');
      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Vendor_ATP_Pkg.Vendor_ATP()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Vendor_ATP;

END XX_MSC_SOURCING_VENDOR_ATP_PKG;
/
