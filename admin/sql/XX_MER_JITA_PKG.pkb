CREATE OR REPLACE
PACKAGE BODY XX_MER_JITA_PKG AS

--DATA Types
  TYPE ns_control_tab_def IS TABLE OF XX_MER_JITA_NS_CONTROL.num_days%TYPE
    INDEX BY XX_MER_JITA_NS_CONTROL.store_type%TYPE;
  TYPE jita_temp_tbl_def IS TABLE OF XX_MER_JITA_TEMP%ROWTYPE;
  TYPE jita_alloc_header_tbl_def IS TABLE OF XX_MER_JITA_ALLOC_HEADER%ROWTYPE;
  TYPE jita_alloc_id_tbl_def IS TABLE OF 
         XX_MER_JITA_ALLOC_HEADER.allocation_id%TYPE;
  TYPE jita_alloc_dtls_tbl_def IS TABLE OF XX_MER_JITA_ALLOC_DTLS%ROWTYPE;
  TYPE org_id_tbl_def IS TABLE OF XX_MER_JITA_TEMP.organization_id%TYPE;
  TYPE alloc_qty_tbl_def IS TABLE OF 
         XX_MER_JITA_ALLOC_DTLS.wmos_shipped_qty%TYPE;
  TYPE lockin_qty_tbl_def IS TABLE OF 
         XX_MER_JITA_ALLOC_DTLS.Lockin_alloc_qty%TYPE;
  TYPE seasonal_lrg_ord_qty_tbl_def IS 
      TABLE OF XX_MER_JITA_ALLOC_DTLS.Seasonal_lrg_ord_qty%TYPE;
  TYPE ATP_customer_order_qty_tbl_def IS 
      TABLE OF XX_MER_JITA_ALLOC_DTLS.ATP_customer_order_qty%TYPE;
  TYPE jita_temp_lockin_rec is RECORD (
    organization_id	    XX_MER_JITA_TEMP.organization_id%TYPE,
    store_type	            XX_MER_JITA_TEMP.store_type%TYPE,
    need		    XX_MER_JITA_TEMP.need%TYPE,
    rounded_need	    XX_MER_JITA_TEMP.rounded_need%TYPE,
    prior_allocation_qty    XX_MER_JITA_TEMP.prior_allocation_qty%TYPE,
    prior_lockin_qty        XX_MER_JITA_TEMP.prior_lockin_qty%TYPE,
    prior_seasonal_lrg_qty  XX_MER_JITA_TEMP.prior_seasonal_lrg_qty%TYPE,
    prior_atp_cust_order_qty XX_MER_JITA_TEMP.prior_atp_cust_order_qty%TYPE,
    allocation_qty          XX_MER_JITA_TEMP.allocation_qty%TYPE,
    lockin_alloc_qty	    XX_MER_JITA_TEMP.lockin_alloc_qty%TYPE,
    seasonal_lrg_ord_qty    XX_MER_JITA_TEMP.seasonal_lrg_ord_qty%TYPE,
    atp_customer_order_qty  XX_MER_JITA_TEMP.atp_customer_order_qty%TYPE,
    lockin_request_qty      XX_PO_ALLOCATION_LINES.allocation_qty%TYPE,
    wmos_qty                XX_PO_ALLOCATION_LINES.wmos_qty%TYPE
  );    
  TYPE jita_temp_lockin_tbl_def IS TABLE OF jita_temp_lockin_rec;


-- CONSTANTS
GC_EOL CHAR(1) := CHR(13);

-- Variables
gc_JITA_process_name        VARCHAR2(10);
gc_error_loc                XX_COM_ERROR_LOG.ERROR_LOCATION%TYPE;
gc_error_debug              VARCHAR2(2000);
gc_error_message            XX_COM_ERROR_LOG.ERROR_MESSAGE%TYPE;
gc_module_name              XX_COM_ERROR_LOG.MODULE_NAME%TYPE;
gc_Schedule_type            XX_REPL_SCHEDULE_ALL.SCHEDULE_TYPE%TYPE;
gn_schedule_day             XX_REPL_SCHEDULE_ALL.SCHEDULE_DAY%TYPE;

gn_overage_threshold         NUMBER(12,6) := 0;
gn_NT_alloc_excess_factor    NUMBER(12,6) := 0;
gn_bottom_fill_threshold     NUMBER(12,6) := 0; 
gn_bottom_fill_threshold_ns     NUMBER(12,6) := 0; 
gn_Min_SOH                    NUMBER := 0;
gn_Min_ARS                    NUMBER(12,6) := 0;
gn_SOH_ARS_Ratio             NUMBER(12,6) := 0;
gc_dept_exclude_list         XX_MER_JITA_CONFIGURE.PARAMETER_VALUE%TYPE; -- TO DO is the size big enough?
gn_PO_arriaval_date_lim     NUMBER := 0;
gn_ARS_lim_for_need          NUMBER(12,6) := 0;
gn_potential_out_ARS_lim     NUMBER(12,6) := 0;

--for logging
gb_enable_log               BOOLEAN := TRUE;
gn_log_level                NUMBER  := 5; -- TO DO get it from configure table
gc_log_buffer               CLOB;

-- TO DO use gc_error_debug

--CURSORS
CURSOR lcu_JITA_configure (
    p_Process_Name XX_MER_JITA_CONFIGURE.process_name%TYPE) IS
  SELECT parameter_name, parameter_value
    FROM XX_MER_JITA_CONFIGURE
    WHERE process_name = p_Process_Name;
    
CURSOR lcu_ASN_Details (p_ASN rcv_shipment_headers.shipment_num%TYPE,
      p_ORG_ID hr_all_organization_units.organization_id%TYPE ) IS
  select t3.segment1 PO, 
       t5.segment1 SKU,
       t4.line_num PO_LINE_NUM, 
       t6.shipment_num PO_SHIPMENT_NUM,       
       t2.quantity_shipped QTY_SHIPPED,
       t5.inventory_item_id ITEM_ID,
       t3.PO_HEADER_ID,
       t4.PO_LINE_ID,
       t6.LINE_LOCATION_ID
  from rcv_shipment_headers t1, 
       rcv_shipment_lines t2,
       po_headers_all t3, 
       po_lines_all t4,
       mtl_system_items_b t5,
       po_line_locations_all t6       
  where t1.shipment_header_id = t2.shipment_header_id
  and t2.po_header_id = t3. po_header_id
  and t2.po_line_id = t6.po_line_id
  and t3.po_header_id = t6.po_header_id
  and t2.po_line_location_id = t6.line_location_id
  and t2.to_organization_id = t6.ship_to_organization_id
  and t3.type_lookup_code = 'STANDARD'
  and t2.po_line_id = t4.po_line_id
  and t6.ship_to_organization_id = t5.organization_id
  and t4.item_id = t5.inventory_item_id
  and t2.asn_line_flag = 'Y'
  and t2.shipment_line_status_code = 'EXPECTED'
  and t1.shipment_num = p_ASN
  and t6.ship_to_organization_id = p_org_id;
  
CURSOR lcu_JITA_priority IS 
    SELECT allocation_code 
    FROM XX_MER_JITA_ALLOC_PRIORITY
    WHERE process_name = gc_JITA_process_name
    ORDER BY priority;

CURSOR lcu_JITA_Alloc (p_ASN rcv_shipment_headers.shipment_num%TYPE) IS
    SELECT creation_date 
    FROM XX_MER_JITA_ALLOC_HEADER
    WHERE ASN = p_ASN
    ORDER BY creation_date;

CURSOR lcu_JITA_Appt IS 
    SELECT ASN 
    FROM XX_MER_JITA_APPT
    where appt_time > sysdate and
    appt_time < sysdate + (G_THRESHOLD/1440.0)
    ORDER BY ASN;

CURSOR lcu_sourcing_info (
    p_inventory_item_id xx_mer_sourcing_all.inventory_item_id%TYPE,
    p_org_id hr_all_organization_units.organization_id%TYPE) IS
  SELECT T1.dest_organization_id as organization_id, 
    T3.open_date_sw as store_open_date,
    T3.od_reloc_id_sw as reloc_id, 
    T3.od_remerch_ind_s as remerch_ind,
    T3.od_type_sw as loc_type_cd,
    T3.od_sub_type_cd_sw as loc_sub_type_cd,
    NVL( T4.od_dist_target, 0 )  as RUTL,
    T4.od_replen_type_cd as RTC,
    T4.od_replen_sub_type_cd as RSTC,
    T4.od_whse_item_cd as WIC,
    NVL(T4.avg_weekly_sales, 0) as AWS  
  FROM xx_mer_sourcing_all T1,
    mtl_parameters T2,  xx_inv_org_loc_rms_attribute T3,
    xx_inv_item_org_attributes T4
  WHERE T1.dest_organization_id = T2.organization_id
    AND  T2.attribute6 = T3.combination_id
    AND  T1.dest_organization_id = T4.organization_id
    AND  T1.inventory_item_id = T4.inventory_item_id
    AND  T1.source_organization_id = p_org_id
    AND T1.inventory_item_id = p_inventory_item_id
    AND SYSDATE BETWEEN T1.start_date AND T1.end_date
    AND T4.od_replen_type_cd in ('A', 'M', 'N'); -- N will be filtered out in the code if we have at least one A or M destination.

CURSOR lcu_intransit (
    p_inventory_item_id xx_mer_sourcing_all.inventory_item_id%TYPE,
    p_org_id hr_all_organization_units.organization_id%TYPE) IS
  SELECT NVL( (SUM(quantity_shipped) - SUM(quantity_received)), 0 ) in_transit
  FROM rcv_shipment_lines
  WHERE shipment_line_status_code IN ('EXPECTED','PARTIALLY RECEIVED')
  AND  to_organization_id = p_org_id
  AND item_id = p_inventory_item_id;

CURSOR lcu_stock_ind (
      p_inventory_item_id mtl_system_items_b.inventory_item_id%TYPE,
      p_org_id hr_all_organization_units.organization_id%TYPE ) IS 
-- TO DO use the right value
  --SELECT handling_temp FROM xx_inv_item_master_attributes  
  SELECT HANDLING_SENSITIVITY FROM xx_inv_item_master_attributes  
  WHERE inventory_item_id = p_inventory_item_id 
  AND ( (organization_id = p_org_id) or organization_id is null)
  ORDER BY organization_id; 
-- Order by gives non null record first and then null record. 
-- Thus fall back logic is implemented.  

CURSOR lcu_po_alloc_header (
  p_inventory_item_id mtl_system_items_b.inventory_item_id%TYPE,
  p_org_id hr_all_organization_units.organization_id%TYPE,
  p_vendor_id po_approved_supplier_list.vendor_id%TYPE,
  p_vendor_site_id po_approved_supplier_list.vendor_site_id%TYPE ) IS 
  SELECT allocation_header_id 
  FROM xx_po_allocation_header
  WHERE org_id = p_org_id
  AND item_id = p_inventory_item_id 
  AND vendor_id = p_vendor_id
  AND vendor_site_id = p_vendor_site_id;

CURSOR lcu_po_alloc_lines (
  p_po_alloc_hdr_key IN xx_po_allocation_header.allocation_header_id%TYPE,
  p_po_header_id   po_headers_all.po_header_id%TYPE,
  p_po_line_id     po_lines_all.po_line_id%TYPE,
  p_po_line_location_id    po_lines_all.po_line_id%TYPE,
  p_dest_org_id hr_all_organization_units.organization_id%TYPE ) IS
  SELECT allocation_line_id 
  FROM xx_po_allocation_lines
  WHERE allocation_header_id = p_po_alloc_hdr_key
  AND po_header_id = p_po_header_id
  AND po_line_id = p_po_line_id
  AND line_location_id = p_po_line_location_id
  AND ship_to_organization_id = p_dest_org_id;

CURSOR lcu_get_items_for_batch (
  p_org_id hr_all_organization_units.organization_id%TYPE
--, p_WIC code  TO DO
)  IS
  SELECT msi.segment1
        , msi.inventory_item_id
        ,(select xx_gi_comn_utils_pkg.get_quantities ( msi.inventory_item_id	
                ,msi.organization_id
                ,'STOCK') from dual) onhand_qty
      --  , iima.handling_sensitivity
      , /*t5.primary_vendor_item*/ 'XYZ'
  FROM mtl_system_items_b msi
    --, xx_inv_item_master_attributes iima
    --, po_approved_supplier_list t5
    --, xxpo_item_supp_rms_attribute t6
  WHERE /*iima.organization_id = msi.organization_id
  AND iima.inventory_item_id = msi.inventory_item_id
  AND  t5.owning_organization_id = msi.organization_id
  AND t5.item_id = msi.inventory_item_id 
  AND t5.attribute1 = t6.combination_id
  AND */msi.organization_id = p_org_id
  AND (SELECT xx_gi_comn_utils_pkg.get_quantities ( msi.inventory_item_id	
                ,msi.organization_id
                ,'STOCK') FROM dual) > 0
  --AND t6.primary_supp_ind = 'Y'
  ;

CURSOR lcu_get_inventory (p_org_id number) IS 
  SELECT sku, Sellable_on_hand - reserve_qty 
  FROM XX_MER_JITA_INV t2
  WHERE location_id = p_org_id
  ORDER BY sku;

CURSOR lcu_get_stores_list_for_outs (p_org_id number) IS 
  SELECT t2.organization_id
  FROM XX_MER_JITA_SCM_WAREHOUSE_SYS t1, HR_ALL_ORGANIZATION_UNITS t2, 
    MTL_PARAMETERS t3,  XX_INV_ORG_LOC_RMS_ATTRIBUTE t4
  WHERE t1.org_id = t2.organization_id
  AND t2.organization_id = t3.organization_id
  AND  t3.attribute6 = t4.combination_id
  AND t1.warehouse_sys_code = 'WMOS'
  AND t4.default_wh_sw = p_org_id;

CURSOR lcu_get_data_for_outs (
     p_org_id hr_all_organization_units.organization_id%TYPE
   , p_inventory_item_id mtl_system_items_b.inventory_item_id%TYPE
   , p_vendor_product_code po_approved_supplier_list.primary_vendor_item%TYPE
   , p_pass NUMBER
) IS 
  SELECT t2.organization_id  
    -- TO DO use od_defaultcrossdock_sw
    , t4.avg_weekly_sales
    , (select xx_gi_comn_utils_pkg.get_quantities ( t4.inventory_item_id	
                , t1.organization_id
                ,'STOCK') from dual) onhand_qty
  FROM HR_ALL_ORGANIZATION_UNITS t1
    , MTL_PARAMETERS t2
    , XX_INV_ORG_LOC_RMS_ATTRIBUTE t3
    , XX_INV_ITEM_ORG_ATTRIBUTES t4
    , po_approved_supplier_list t5
    , xxpo_item_supp_rms_attribute t6
    , mtl_item_categories t7
    , mtl_categories t8
    , MTL_CATEGORY_SETS t9
  WHERE 
    t1.organization_id = t2.organization_id
    AND t2.attribute6 = t3.combination_id
    AND t1.organization_id = t4.organization_id
    AND t5.owning_organization_id = t1.organization_id
    AND t5.item_id = t4.inventory_item_id
    AND t5.attribute1 = t6.combination_id
    AND t7.inventory_item_id = t4.inventory_item_id
    AND t7.organization_id = t1.organization_id
    AND t7.category_id = t8.category_id
    AND t7.category_set_id = t9.category_set_id
    AND t3.OD_DEFAULT_WH_CSC_S = p_org_id
    AND T4.od_replen_type_cd in ('A', 'M')
    AND ( (p_pass = 2) OR (select xx_gi_comn_utils_pkg.get_quantities ( t4.inventory_item_id	
                , t1.organization_id
                ,'STOCK') from dual) < gn_min_SOH )
    AND ( (p_pass = 1) OR (select xx_gi_comn_utils_pkg.get_quantities ( t4.inventory_item_id	
                , t1.organization_id
                ,'STOCK') from dual) > 0 )
    AND ( (p_pass = 1) OR (select xx_gi_comn_utils_pkg.get_quantities ( t4.inventory_item_id	
                , t1.organization_id
                ,'STOCK') from dual) < gn_SOH_ARS_Ratio * t4.avg_weekly_sales )
    AND t4.inventory_item_id = p_inventory_item_id
    AND t6.primary_supp_ind = 'Y'
    AND t5.primary_vendor_item = p_vendor_product_code
    AND t4.avg_weekly_sales > gn_Min_ARS
    AND t4.od_replen_type_cd in ('A', 'M')
    AND t4.od_whse_item_cd <> 'D'
    AND t9.category_set_name = 'PO CATEGORY'
    AND t8.segment3 not in gc_dept_exclude_list
    ORDER BY t4.avg_weekly_sales DESC
       , t4.organization_id ASC;

CURSOR lcu_get_po_arrival_date (
     p_org_id hr_all_organization_units.organization_id%TYPE
   , p_inventory_item_id mtl_system_items_b.inventory_item_id%TYPE   
) IS
  SELECT c.promised_date
  FROM    po_headers_all a
        , po_lines_all b
        , po_line_locations_all c
  WHERE a.po_header_id=b.po_header_id
    AND c.po_line_id=b.po_line_id
    AND c.po_header_id = a.po_header_id
    AND c.ship_to_organization_id = p_org_id
    AND b.item_id = p_inventory_item_id
    AND c.closed_code='OPEN'
    AND c.quantity_received=0 
    AND trunc(c.promised_date) > trunc(sysdate-3)
  ORDER BY c.promised_date;


-- Exceptions
INVALID_INPUT EXCEPTION;

-- common procedures for logging
PROCEDURE JITA_LOG_MSG (p_level IN NUMBER, p_message IN CLOB) IS
-- To use FND_DEBUG we may have to use concurrent programs, wrap it and then 
-- BPEL has to call the wrapped program
-- This procedure may have to be optimized to get performance similar to FND_DEBUG
BEGIN
  -- TO DO end of line
  IF gb_enable_log AND (p_level <= gn_log_level) THEN
    gc_log_buffer := gc_log_buffer || to_char(systimestamp, 'HH24:MI:SSXFF3 ') 
        ||p_message || GC_EOL;
  END IF;
END JITA_LOG_MSG;

PROCEDURE JITA_LOG_INSERT (
    p_org_id IN hr_all_organization_units.organization_id%TYPE,
    p_ASN IN rcv_shipment_headers.shipment_num%TYPE
  )IS -- TO DO autonomous transaction:1
BEGIN
  IF gb_enable_log and gc_log_buffer IS NOT NULL THEN
    INSERT INTO XX_MER_JITA_LOG (process_name, log_msg, creation_date,
      org_id, ASN)    
    VALUES (gc_JITA_process_name, gc_log_buffer, sysdate, p_org_id, p_ASN);
  END IF;
  gc_log_buffer := '';
END;

-- FUNCTIONS

FUNCTION ROUND_QTY 
    (p_raw_qty IN NUMBER, p_store_type IN VARCHAR2,
    p_standard_pack_qty IN NUMBER, p_case_pack_qty IN NUMBER) RETURN NUMBER IS
  ln_pack_qty NUMBER := 0;
  ln_rnd_qty NUMBER := 0;
BEGIN
  
  -- TO DO Check if any input parameters are 0 or NULL
  gc_module_name  := 'ROUND_QTY';
  gc_error_loc := 'Round quantity ';
  gc_error_message := 'Calculating rounded quantity failed: ';
  ln_pack_qty := p_standard_pack_qty;
  IF p_store_type = G_STORE_TYPE_NON_TRADITIONAL THEN
    ln_pack_qty := p_case_pack_qty;
  END IF;
  ln_rnd_qty := trunc(p_raw_qty/ln_pack_qty);

  IF( MOD(p_raw_qty, ln_pack_qty) <> 0 ) THEN
    ln_rnd_qty := ln_pack_qty * (ln_rnd_qty + 1);
  ELSE
    ln_rnd_qty := ln_pack_qty * ln_rnd_qty;
  END IF;
      
  RETURN ln_rnd_qty;
END ROUND_QTY;


FUNCTION GET_STOCK_INDICATOR  (
  p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE,
  p_org_id IN hr_all_organization_units.organization_id%TYPE )
  RETURN VARCHAR2 IS

--  lc_result xx_inv_item_master_attributes.handling_temp%TYPE; -- TO DO use the actual column
lc_result xx_inv_item_master_attributes.HANDLING_SENSITIVITY%TYPE; 
BEGIN
  JITA_LOG_MSG(1, 'START GET_STOCK_INDICATOR:');
  
  JITA_LOG_MSG(3, 'Query to get stock indicator');
  gc_module_name  := 'GET_STOCK_INDICATOR';
  gc_error_loc := 'Query to get stock indicator ';
  gc_error_message := 'Open cursor lcu_stock_ind Failed: ';
  OPEN lcu_stock_ind(p_inventory_item_id, p_org_id);
  gc_error_message := 'Fetch from cursor lcu_stock_ind Failed: ';  
  IF lcu_stock_ind%NOTFOUND THEN
    -- TO DO Error
    lc_result := 'STOCKED'; -- TO DO take out this
  ELSE
    FETCH lcu_stock_ind INTO lc_result;
  END IF;  
  gc_error_message := 'Close cursor lcu_stock_ind Failed: ';
  CLOSE lcu_stock_ind;

  -- TODO Error Handling. The query should return 1 or 2 records. 
  -- If more than 2 then data integrity issue. 
  IF lc_result IS NULL THEN
    lc_result := 'STOCKED'; -- TO DO take out this
  END IF;

  JITA_LOG_MSG(1, 'END GET_STOCK_INDICATOR:');
  
  RETURN lc_result; -- we need to get only the first record. 
  
END GET_STOCK_INDICATOR;


-- PROCEDURES

PROCEDURE INITIALIZE_CONFIG_PARAMS  IS

lc_JITA_process_name XX_MER_JITA_CONFIGURE.process_name%TYPE;
lc_Parameter_name  XX_MER_JITA_CONFIGURE.parameter_name%TYPE;
lc_Parameter_value  XX_MER_JITA_CONFIGURE.parameter_value%TYPE;
BEGIN
  JITA_LOG_MSG(1, 'START INITIALIZE_CONFIG_PARAMS:');  
  gc_module_name  := 'INITIALIZE_CONFIG_PARAMS'; 
  
  FOR I in 1 .. 2 LOOP
    IF I = 1 THEN
      lc_JITA_process_name := G_PROCESS_NAME_ALL;
    ELSE
      lc_JITA_process_name := gc_JITA_process_name;
    END IF;
    
    gc_error_loc := 'Get Config Parameters for ' || lc_JITA_process_name;
    gc_error_message := 'Select from cursor lcu_JITA_configure failed: ';
    JITA_LOG_MSG(3, 'Get Config Parameters for ' || lc_JITA_process_name);
    OPEN lcu_JITA_configure (lc_JITA_process_name);
    LOOP
      gc_error_message := 'Fetch from Cursor lcu_JITA_configure Failed: ';
      gc_error_loc := 'Get Config Parameters for ' || lc_JITA_process_name;
      FETCH lcu_JITA_configure INTO lc_Parameter_name, lc_Parameter_value;
      EXIT WHEN lcu_JITA_configure%NOTFOUND;
      JITA_LOG_MSG(5, 'paramer name= ' || lc_Parameter_name || ' Value=' 
        || lc_Parameter_value);
      CASE lc_Parameter_name
        WHEN 'ENABLE_LOG' THEN
          gb_enable_log := (lc_Parameter_value = 'Y');
          JITA_LOG_MSG(5, 'gb_enable_log= ' || lc_Parameter_value);
        WHEN 'BOTTOM_FILL_THRESHOLD' THEN
          gn_bottom_fill_threshold := TO_NUMBER(lc_Parameter_value);
          JITA_LOG_MSG(5, 'gn_bottom_fill_threshold= ' 
                   || gn_bottom_fill_threshold);
        WHEN 'BOTTOM_FILL_THRESHOLD_NS' THEN
          gn_bottom_fill_threshold_ns := TO_NUMBER(lc_Parameter_value);
          JITA_LOG_MSG(5, 'gn_bottom_fill_threshold_new_stores= ' 
                   || gn_bottom_fill_threshold_ns);
        WHEN 'LOG_LEVEL' THEN
          gn_log_level := TO_NUMBER(lc_Parameter_value);
          JITA_LOG_MSG(5, 'gn_log_level= ' || gn_log_level);
        WHEN 'OVERAGE_THRESHOLD' THEN
          gn_overage_threshold := TO_NUMBER(lc_Parameter_value);
          JITA_LOG_MSG(5, 'gn_overage_threshold= ' || gn_overage_threshold);
        WHEN 'NT_ALLOC_EXCESS_FACTOR' THEN
          gn_NT_alloc_excess_factor := TO_NUMBER(lc_Parameter_value);
          JITA_LOG_MSG(5, 'gn_NT_alloc_excess_factor= ' || gn_NT_alloc_excess_factor);
        WHEN 'MIN_SOH' THEN
          gn_Min_SOH := TO_NUMBER(lc_Parameter_value);
          JITA_LOG_MSG(5, 'gn_Min_SOH= ' || gn_Min_SOH);
        WHEN 'MIN_ARS' THEN
          gn_Min_ARS := TO_NUMBER(lc_Parameter_value);
          JITA_LOG_MSG(5, 'gn_Min_ARS= ' || gn_Min_ARS);
        WHEN 'SOH_ARS_RATIO' THEN
          gn_SOH_ARS_Ratio := TO_NUMBER(lc_Parameter_value);
          JITA_LOG_MSG(5, 'gn_SOH_ARS_Ratio= ' || gn_SOH_ARS_Ratio);
        WHEN 'DEPT_EXCLUDE_LIST' THEN
          gc_dept_exclude_list := lc_Parameter_value;
          JITA_LOG_MSG(5, 'gc_dept_exclude_list= ' || gc_dept_exclude_list);
        WHEN 'PO_ARRIVAL_DATE_LIM' THEN
          gn_PO_arriaval_date_lim := TO_NUMBER(lc_Parameter_value);
          JITA_LOG_MSG(5, 'gn_PO_arriaval_date_lim= ' || gn_PO_arriaval_date_lim);
        WHEN 'POTENTIAL_OUT_ARS_LIM' THEN
          gn_potential_out_ARS_lim := TO_NUMBER(lc_Parameter_value);
          JITA_LOG_MSG(5, 'gn_potential_out_ARS_lim= ' || gn_potential_out_ARS_lim);
        WHEN 'ARS_LIMIT_FOR_NEED'  THEN
          gn_ARS_lim_for_need := TO_NUMBER(lc_Parameter_value);
          JITA_LOG_MSG(5, 'gn_ARS_lim_for_need= ' || gn_ARS_lim_for_need);
      ELSE
        JITA_LOG_MSG(5, lc_Parameter_name || ' not supported');
      END CASE;
    END LOOP;
    CLOSE lcu_JITA_configure;
  END LOOP;
  JITA_LOG_MSG(1, 'END INITIALIZE_CONFIG_PARAMS:');  
END INITIALIZE_CONFIG_PARAMS;

PROCEDURE GET_SOURCE_INFO(
  p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE,
  p_org_id IN hr_all_organization_units.organization_id%TYPE,
  p_stock_type IN VARCHAR2) IS  -- TO DO change type to %type 
--TO DO stock type may be CSC fulfillment or Outs process for JITA batch
    
  ld_store_open_date xx_inv_org_loc_rms_attribute.open_date_sw%TYPE;
  ln_reloc_id   xx_inv_org_loc_rms_attribute.od_reloc_id_sw%TYPE;
  lc_remerch_ind   xx_inv_org_loc_rms_attribute.od_remerch_ind_s%TYPE;
  lc_loc_type_cd  xx_inv_org_loc_rms_attribute.od_type_sw%TYPE;
  --lc_loc_sub_type_cd  xx_inv_org_loc_rms_attribute.od_sub_type_cd_sw%TYPE;
  ln_num_days  XX_MER_JITA_NS_CONTROL.num_days%TYPE;
  lb_add_new_jita_temp_record BOOLEAN;
  lb_All_Stores_Non_Replen BOOLEAN;
  lc_rtc varchar2(18);
  lc_rstc varchar2(18);
  lc_wic varchar2(18);
  
  lc_jita_temp_rec_type XX_MER_JITA_TEMP%ROWTYPE; 
  ns_control_tbl_type ns_control_tab_def;
BEGIN
  JITA_LOG_MSG(1, 'START GET_SOURCE_INFO:');
  
  gc_module_name  := 'GET_SOURCE_INFO';
  gc_error_loc := 'Get new store control attributes';
  gc_error_message := 'Select from XX_MER_JITA_NS_CONTROL failed: ';
  JITA_LOG_MSG(3, 'Get new store control attributes:');  
  FOR item IN 
    ( SELECT store_type, num_days 
      FROM XX_MER_JITA_NS_CONTROL 
      WHERE dist_type = p_stock_type)
  LOOP
    ns_control_tbl_type(item.store_type) := item.num_days;  
    -- TO DO this may be done only once at global level
  END LOOP;  

  
  JITA_LOG_MSG(3, 'Get sourcing information');
  gc_module_name  := 'GET_SOURCE_INFO';
  gc_error_loc := 'Get sourcing information';
  gc_error_message := 'Open Cursor lcu_sourcing_info Failed: ';
  JITA_LOG_MSG(5, 'p_inventory_item_id= ' || p_inventory_item_id ||
        ' p_org_id= ' || p_org_id);
  lb_All_Stores_Non_Replen := true;
  OPEN lcu_sourcing_info (p_inventory_item_id, p_org_id);
  LOOP
    gc_module_name  := 'GET_SOURCE_INFO';
    gc_error_loc := 'Get sourcing information';
    gc_error_message := 'Fetch from Cursor lcu_sourcing_info Failed: ';  
    FETCH lcu_sourcing_info INTO lc_jita_temp_rec_type.organization_id, ld_store_open_date,
      ln_reloc_id, lc_remerch_ind, lc_loc_type_cd, 
      lc_jita_temp_rec_type.store_type, 
      lc_jita_temp_rec_type.rutl, lc_jita_temp_rec_type.replen_type_code, 
      lc_jita_temp_rec_type.replen_subtype_code, 
      lc_jita_temp_rec_type.warehouse_item_code, 
      lc_jita_temp_rec_type.avg_rate_of_sale;
    
    EXIT WHEN lcu_sourcing_info%NOTFOUND;
    JITA_LOG_MSG(5, 'Fetched record with org_id = ' || lc_jita_temp_rec_type.organization_id);
    IF lb_All_Stores_Non_Replen 
       AND lc_jita_temp_rec_type.replen_type_code in ('A', 'M') THEN
          lb_All_Stores_Non_Replen := false;
    END IF;
    
    --initialize all numeric values to avoid NULL issues
    lc_jita_temp_rec_type.sellable_on_hand := 0;
    lc_jita_temp_rec_type.in_transit_qty := 0;
    lc_jita_temp_rec_type.need := 0;
    lc_jita_temp_rec_type.rounded_Need := 0;
    lc_jita_temp_rec_type.need_pct := 0;
    lc_jita_temp_rec_type.prior_allocation_qty := 0;
    lc_jita_temp_rec_type.Prior_lockin_qty := 0;
    lc_jita_temp_rec_type.Prior_seasonal_lrg_qty := 0;
    lc_jita_temp_rec_type.Prior_atp_cust_order_qty := 0;
    lc_jita_temp_rec_type.allocation_qty := 0;
    lc_jita_temp_rec_type.lockin_alloc_qty := 0;
    lc_jita_temp_rec_type.seasonal_lrg_ord_qty := 0;
    lc_jita_temp_rec_type.bottom_fill_qty := 0;
    lc_jita_temp_rec_type.dynamic_qty := 0;
    lc_jita_temp_rec_type.atp_customer_order_qty := 0;
    lc_jita_temp_rec_type.can_receive := 1; -- FOR stocked prodict we update this based on receiving schedule
    lc_jita_temp_rec_type.overage_qty := 0;
    
    IF (ln_reloc_id is not null) and (ln_reloc_id  > 0) THEN
      lc_jita_temp_rec_type.store_type := G_STORE_TYPE_RELOC;
    END IF;
    IF (lc_remerch_ind is not null) and (lc_remerch_ind = 'Y') THEN
      lc_jita_temp_rec_type.store_type := G_STORE_TYPE_REMERCH;
    END IF;
      
    lb_add_new_jita_temp_record := TRUE;
    lc_jita_temp_rec_type.new_store_flag := 'N';
    --check if it is a new store.      
    IF (ld_store_open_date >= sysdate) then
      lc_jita_temp_rec_type.new_store_flag := 'Y';
      IF ns_control_tbl_type.exists(lc_jita_temp_rec_type.store_type) THEN
        ln_num_days := ns_control_tbl_type(lc_jita_temp_rec_type.store_type);
      ELSIF ns_control_tbl_type.exists(G_STORE_TYPE_REGULAR) THEN
        ln_num_days := ns_control_tbl_type(G_STORE_TYPE_REGULAR);
      ELSE -- TO DO error
        ln_num_days := ln_num_days;
      END IF;
         
      IF trunc(sysdate) + ln_num_days < trunc(ld_store_open_date) THEN
        lb_add_new_jita_temp_record := FALSE;
      END IF;
    END IF;
      
    IF lb_add_new_jita_temp_record THEN
      gc_module_name  := 'GET_SOURCE_INFO';
      gc_error_loc := 'Get sourcing information';
      gc_error_message := 'Insert into XX_MER_JITA_TEMP failed: ';
      INSERT INTO XX_MER_JITA_TEMP VALUES lc_jita_temp_rec_type;
    END IF;
  END LOOP;
  gc_module_name  := 'GET_SOURCE_INFO';
  gc_error_loc := 'Get sourcing information';
  gc_error_message := 'Close Cursor lcu_sourcing_info Failed: ';  
  CLOSE lcu_sourcing_info;

  IF NOT lb_All_Stores_Non_Replen THEN
    JITA_LOG_MSG(3, 'Some stores are actively replenished. Delete non replen stores from distribution');
    gc_module_name  := 'GET_SOURCE_INFO';
    gc_error_loc := 'Get sourcing information';
    gc_error_message := 'DELETE from XX_MER_JITA_TEMP failed: ';
    DELETE FROM XX_MER_JITA_TEMP 
    WHERE replen_type_code = 'N';
  ELSE
    JITA_LOG_MSG(3, 'All stores are not actively replenished. Exclude NT stores!');
    gc_module_name  := 'GET_SOURCE_INFO';
    gc_error_loc := 'Get sourcing information';
    gc_error_message := 'DELETE from XX_MER_JITA_TEMP failed: ';
    DELETE FROM XX_MER_JITA_TEMP 
    WHERE store_type = G_STORE_TYPE_NON_TRADITIONAL;
  END IF;
  
  -- TO DO Check that JITA_TEMP table has at least one row
  
  /*-- Crossdock may have tio put away quantity or a combo center may have to 
  -- allocate product to itself.
  -- TO DO For a combo center it may be possible that od_sourcing may already
  -- have a record, so the insert may fail.
  IF (gc_JITA_process_name = 'ONLINE') THEN
    gc_module_name  := 'GET_SOURCE_INFO';
    gc_error_loc := 'Create a sourcing record for self for put away';
    gc_error_message := 'Insert into XX_MER_JITA_TEMP failed: ';
    JITA_LOG_MSG(3, 'Create a sourcing record for self for put away');  
    INSERT INTO XX_MER_JITA_TEMP (organization_id, Store_type, New_store_flag,
      Sellable_on_hand, RUTL, In_transit_qty, Avg_rate_of_sale,
      Need, Rounded_Need, need_pct, Prior_allocation_qty,prior_lockin_qty, 
      prior_seasonal_lrg_qty, prior_atp_cust_order_qty, allocation_qty,
      Lockin_alloc_qty, Seasonal_lrg_ord_qty, bottom_fill_qty, 
      ATP_customer_order_qty, dynamic_qty, can_receive, overage_qty
    )
    VALUES(p_org_id, 'RG', 'N',
      0, 0, 0, 0,
      0,0,0,0,0,
      0,0,0,
      0,0,0,
      0,0, 1, 0);
  END IF;*/

  JITA_LOG_MSG(1, 'END GET_SOURCE_INFO:');
END GET_SOURCE_INFO;

PROCEDURE GET_INVENTORY_DATA 
    ( p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE,
      p_org_id IN hr_all_organization_units.organization_id%TYPE,
      p_in_transit_qty OUT NUMBER,
      p_sellable_on_hand OUT NUMBER) IS
  lc_return_status      VARCHAR2(1000) ;
  ln_msg_count          NUMBER ;          
  lc_msg_data           VARCHAR2(1000) ;
  ln_att                NUMBER ; --Available to transact
BEGIN
  JITA_LOG_MSG(1, 'START GET_INVENTORY_DATA:');
  
  p_sellable_on_hand := 0;
  -- Get SOH   
  JITA_LOG_MSG(5, 'Get SOH');
  lc_return_status := NULL;
  xx_gi_comn_utils_pkg.get_quantities(p_inventory_item_id
      , p_org_id
      , G_SUB_INV_CODE_STOCK
      , p_sellable_on_hand
      , ln_att
      , lc_return_status
      , lc_msg_data ) ; 
                                      
  IF lc_return_status <> fnd_api.g_ret_sts_success THEN
    JITA_LOG_MSG(3, 'Error: Message Data :'||lc_msg_data) ;
      -- TO DO Error handling
  ELSE
    JITA_LOG_MSG(3, 'SOH for ' || p_org_id || ' = ' || p_sellable_on_hand) ;
  END IF;

  p_in_transit_qty := 0;
  JITA_LOG_MSG(5, 'Get intransit quantity');
  gc_module_name  := 'GET_INVENTORY_DATA';
  gc_error_loc := 'Get intransit quantity ';
  gc_error_message := 'Query to get in transit qty Failed: ';  
  BEGIN
    SELECT NVL( (SUM(quantity_shipped) - SUM(quantity_received)), 0 ) 
    INTO p_in_transit_qty
    FROM rcv_shipment_lines
    WHERE shipment_line_status_code IN ('EXPECTED','PARTIALLY RECEIVED')
    AND  to_organization_id = p_org_id
    AND item_id = p_inventory_item_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     p_in_transit_qty := 0;
  END;
  JITA_LOG_MSG(3, 'In_transit_qty for ' || p_org_id 
        || ' = ' || p_in_transit_qty) ;
  JITA_LOG_MSG(1, 'END GET_INVENTORY_DATA:');   
END GET_INVENTORY_DATA;

PROCEDURE FILL_INVENTORY_DATA 
      (p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE) IS
  jita_temp_tbl_type jita_temp_tbl_def;
  org_id_tbl_type org_id_tbl_def := org_id_tbl_def();

  lc_return_status      VARCHAR2(1000) ;
  ln_msg_count          NUMBER ;          
  lc_msg_data           VARCHAR2(1000) ;
  ln_att                NUMBER ; --Available to transact

BEGIN
  JITA_LOG_MSG(1, 'START FILL_INVENTORY_DATA:');
  JITA_LOG_MSG(5, 'Inventory Item Id = ' || p_inventory_item_id) ;

  gc_module_name  := 'FILL_INVENTORY_DATA ';
  gc_error_loc := 'Get Data from global temp table XX_MER_JITA_TEMP: ';
  gc_error_message := 'Query to XX_MER_JITA_TEMP failed: ';
  JITA_LOG_MSG(3, 'Get Data from global temp table XX_MER_JITA_TEMP: ');
  SELECT * BULK COLLECT INTO jita_temp_tbl_type
      FROM XX_MER_JITA_TEMP
      ORDER BY organization_id;
  org_id_tbl_type.extend (jita_temp_tbl_type.COUNT);
  FOR i IN 1 .. jita_temp_tbl_type.COUNT
  LOOP
    org_id_tbl_type(i) := jita_temp_tbl_type(i).organization_id;
    GET_INVENTORY_DATA ( p_inventory_item_id => p_inventory_item_id,
      p_org_id => jita_temp_tbl_type(i).organization_id,
      p_in_transit_qty => jita_temp_tbl_type(i).in_transit_qty,
      p_sellable_on_hand => jita_temp_tbl_type(i).sellable_on_hand);
  END LOOP;

  gc_error_message := 'bulk update to XX_MER_JITA_TEMP failed: ';
  JITA_LOG_MSG(3, 'bulk update to XX_MER_JITA_TEMP');
  FORALL i IN 1 .. jita_temp_tbl_type.COUNT
      UPDATE XX_MER_JITA_TEMP SET ROW = jita_temp_tbl_type(i)
      WHERE  organization_id = org_id_tbl_type(i);

  JITA_LOG_MSG(1, 'END FILL_INVENTORY_DATA:');   
END FILL_INVENTORY_DATA;


PROCEDURE FILL_PREV_ALLOC_BUC
    (p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE) IS
  org_ids_tbl_type org_id_tbl_def;   
  alloc_qty_tbl_type alloc_qty_tbl_def;
  lockin_qty_tbl_type lockin_qty_tbl_def;
  seasonal_lrg_ord_qty_tbl_type seasonal_lrg_ord_qty_tbl_def;
  ATP_cust_order_qty_tbl_type ATP_customer_order_qty_tbl_def;
BEGIN
  JITA_LOG_MSG(1, 'START FILL_PREV_ALLOC_BUC:');
  
  gc_module_name  := 'FILL_PREV_ALLOC_BUC';
  gc_error_loc := 'Fill allocations from prior runs: ';
  gc_error_message := 'Query to select prior allocations failed: ';
  JITA_LOG_MSG(3, 'Fill allocations from prior runs today');
  SELECT t1.dest_organization_id, SUM(t1.wmos_shipped_qty), SUM(t1.Lockin_alloc_qty),
    SUM(t1.Seasonal_lrg_ord_qty), SUM(t1.atp_customer_order_qty)
    BULK COLLECT INTO org_ids_tbl_type, alloc_qty_tbl_type, lockin_qty_tbl_type,
    seasonal_lrg_ord_qty_tbl_type, ATP_cust_order_qty_tbl_type
    FROM XX_MER_JITA_ALLOC_DTLS t1, XX_MER_JITA_TEMP t2, XX_MER_JITA_ALLOC_HEADER t3
    WHERE t1.dest_organization_id = t2.organization_id
    AND t1.allocation_id = t3.allocation_id
    AND t3.inventory_item_id = p_inventory_item_id
    -- AND t3.organization_id  = p_location_id -- we don't need this
    AND trunc(t3.creation_date) = trunc(sysdate)
    GROUP BY t1.dest_organization_id;

  gc_error_message := 'bulk update to XX_MER_JITA_TEMP failed: ';
  JITA_LOG_MSG(3, 'bulk update to XX_MER_JITA_TEMP');
  FORALL i IN 1.. org_ids_tbl_type.COUNT    
    UPDATE XX_MER_JITA_TEMP 
      SET prior_allocation_qty = alloc_qty_tbl_type(i),
      prior_lockin_qty	= lockin_qty_tbl_type(i),
      prior_seasonal_lrg_qty = seasonal_lrg_ord_qty_tbl_type(i),
      prior_atp_cust_order_qty = ATP_cust_order_qty_tbl_type(i)
      WHERE organization_id = org_ids_tbl_type (i);
  
  JITA_LOG_MSG(1, 'END FILL_PREV_ALLOC_BUC:');   
END FILL_PREV_ALLOC_BUC;

PROCEDURE GET_PACK_SIZE_INFO (
    p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE,
    p_org_id IN hr_all_organization_units.organization_id%TYPE,
    p_po_header_id IN po_headers_all.po_header_id%TYPE,
    p_standard_pack_qty OUT NUMBER,
    p_case_pack_qty OUT NUMBER,
    p_vendor_id OUT po_approved_supplier_list.vendor_id%TYPE,
    p_vendor_site_id OUT  po_approved_supplier_list.vendor_site_id%TYPE
    
  ) IS

  org_id_tbl_type org_id_tbl_def;   
  alloc_qty_tbl_type alloc_qty_tbl_def;
  lockin_qty_tbl_type lockin_qty_tbl_def;
  seasonal_lrg_ord_qty_tbl_type seasonal_lrg_ord_qty_tbl_def;
  ATP_cust_order_qty_tbl_type ATP_customer_order_qty_tbl_def;
BEGIN
  JITA_LOG_MSG(1, 'START GET_PACK_SIZE_INFO:');
  
  gc_module_name  := 'GET_PACK_SIZE_INFO';
  gc_error_loc := 'Query for pack sizes: ';
  gc_error_message := 'Query to get pack sizes failed: ';
  JITA_LOG_MSG(3, 'Query to to get pack sizes');  
  BEGIN
  IF (p_po_header_id IS NULL) OR (p_po_header_id = 0) THEN
    SELECT T1.inner_pack_size, T1.supp_pack_size,
           T2.vendor_id, T2.vendor_site_id
    INTO p_standard_pack_qty, p_case_pack_qty,
         p_vendor_id, p_vendor_site_id
    FROM xxpo_item_supp_rms_attribute T1,
    po_approved_supplier_list T2
    WHERE T2.attribute1 = T1.combination_id
    AND T2.item_id = p_inventory_item_id
    AND T2.owning_organization_id = p_org_id
    AND T1.primary_supp_ind = 'Y';
  ELSE
    SELECT T1.inner_pack_size, T1.supp_pack_size,
           T2.vendor_id, T2.vendor_site_id
    INTO p_standard_pack_qty, p_case_pack_qty,    
         p_vendor_id, p_vendor_site_id
    FROM xxpo_item_supp_rms_attribute T1,
    po_approved_supplier_list T2,
    po_headers_all T3
    WHERE T3.vendor_id = T2.vendor_id
    AND T3.vendor_site_id = T2.vendor_site_id
    AND T2. attribute1 = T1.combination_id
    AND T3.po_header_id = p_po_header_id
    AND T2.item_id = p_inventory_item_id
    AND T2.owning_organization_id = p_org_id;
  END IF;
  EXCEPTION  -- TO DO remove this catch block
    WHEN NO_DATA_FOUND THEN
     p_standard_pack_qty := 2;
     p_case_pack_qty := 20;
     p_vendor_id := 101;
     p_vendor_site_id := 1001;
  END;

  JITA_LOG_MSG(1, 'END GET_PACK_SIZE_INFO:');   
END GET_PACK_SIZE_INFO;


PROCEDURE FILL_CAN_RECEIVE (
    p_org_id IN hr_all_organization_units.organization_id%TYPE,
    p_stock_indicator IN VARCHAR2) IS
  ln_count NUMBER := 0;
  jita_temp_tbl_type jita_temp_tbl_def;
  org_id_tbl_type org_id_tbl_def := org_id_tbl_def();
BEGIN
  JITA_LOG_MSG(1, 'START FILL_CAN_RECEIVE:');
  
  IF p_stock_indicator <> 'STOCKLESS' THEN
    gc_module_name  := 'FILL_CAN_RECEIVE';
    gc_error_loc := 'Get Data ';
    gc_error_message := 'Bulk select from XX_MER_JITA_TEMP failed: ';
    JITA_LOG_MSG(3, 'Get Data from XX_MER_JITA_TEMP:');
    
    SELECT * BULK COLLECT INTO jita_temp_tbl_type
      FROM XX_MER_JITA_TEMP
      ORDER BY organization_id;
    org_id_tbl_type.extend (jita_temp_tbl_type.COUNT);
    
    gc_module_name  := 'FILL_CAN_RECEIVE';
    gc_error_loc := 'Can product be received today?: ';
    gc_error_message := 'Query to select store receiving schedule failed: ';
    JITA_LOG_MSG(3, 'Can product be received today?');
    FOR i IN 1 .. jita_temp_tbl_type.COUNT
    LOOP
      SELECT count(*) INTO ln_count
      FROM XX_REPL_SCHEDULE_ALL t1, XX_REPL_RECV_SCHEDULE t2
      WHERE t1.SCHEDULE_ID = t2.SCHEDULE_ID
      AND t2.SOURCE_LOC_ID = p_org_id
      AND t2.ORGANIZATION_ID = jita_temp_tbl_type(i).organization_id
      AND t1.SCHEDULE_DAY = gn_schedule_day 
      AND t1.SCHEDULE_TYPE = gc_schedule_type;
      
      jita_temp_tbl_type(i).can_receive := ln_count;
      org_id_tbl_type(i) := jita_temp_tbl_type(i).organization_id;
      JITA_LOG_MSG(5, jita_temp_tbl_type(i).organization_id || ' can receive= ' 
          || ln_count);
    END LOOP;
    
    gc_module_name  := 'FILL_CAN_RECEIVE';
    gc_error_loc := 'Update';
    gc_error_message := 'Bulk update can receive: ';  
    JITA_LOG_MSG(3, 'Bulk update can receive');
    FORALL i IN 1 .. jita_temp_tbl_type.COUNT
      UPDATE XX_MER_JITA_TEMP SET ROW = jita_temp_tbl_type(i)
      WHERE  organization_id = org_id_tbl_type(i);
  END IF;
  
  JITA_LOG_MSG(1, 'END FILL_CAN_RECEIVE:');   
END FILL_CAN_RECEIVE;

PROCEDURE UPDATE_PO_ALLOCATION_LINES (
  p_source_org_id IN hr_all_organization_units.organization_id%TYPE,
  p_po_alloc_hdr_key IN xx_po_allocation_header.allocation_header_id%TYPE,
  p_po_header_id IN  po_headers_all.po_header_id%TYPE,
  p_po_line_id IN po_lines_all.po_line_id%TYPE,
  p_po_line_location_id IN po_lines_all.po_line_id%TYPE,
  p_dest_org_id IN hr_all_organization_units.organization_id%TYPE,
  p_jita_qty IN NUMBER,
  p_wmos_qty IN NUMBER ) IS

  ln_po_alloc_line_key xx_po_allocation_lines.allocation_line_id%TYPE := 0;
BEGIN
  JITA_LOG_MSG(1, 'STATR UPDATE_PO_ALLOCATION_LINES:');

  JITA_LOG_MSG(1, 'Input parameters are p_source_org_id= ' || p_source_org_id 
     || ' p_po_alloc_hdr_key= ' || p_po_alloc_hdr_key
     || ' p_po_header_id= ' || p_po_header_id
     || ' p_po_line_id= ' || p_po_line_id
     || ' p_po_line_location_id= ' || p_po_line_location_id
     || ' p_dest_org_id= ' || p_dest_org_id
     || ' p_jita_qty= ' || p_jita_qty
     || ' p_wmos_qty= ' || p_wmos_qty);
  JITA_LOG_MSG(3, 'Input parameters check');
  gc_module_name  := 'UPDATE_PO_ALLOCATION_LINES';
  gc_error_loc := 'Input parameters check';
  gc_error_message := 'Invalid input parameters: ';
  IF (p_source_org_id IS NULL) or (p_source_org_id= 0) 
    or (p_dest_org_id IS NULL) or (p_dest_org_id = 0) THEN
      JITA_LOG_MSG(3, 'Invalid input parameters');
      raise INVALID_INPUT;
  ELSE
    JITA_LOG_MSG(3, 'Input parameters are OK');
  END IF;  

  IF p_po_alloc_hdr_key IS NULL OR (p_po_alloc_hdr_key = 0) THEN
    RETURN;
  END IF;
  
  gc_module_name  := 'UPDATE_PO_ALLOCATION_LINES';
  gc_error_loc := 'Query for po_alloc_line_id: ';
  gc_error_message := 'Query to get po_alloc_line_id failed: ';
  JITA_LOG_MSG(3, 'Query to to get po_alloc_line_id');  
  OPEN lcu_po_alloc_lines(p_po_alloc_hdr_key, p_po_header_id, p_po_line_id,
          p_po_line_location_id, p_dest_org_id);
  gc_error_message := 'Fetch from cursor lcu_po_alloc_lines Failed: ';
  JITA_LOG_MSG(5, 'Fetch from cursor lcu_po_alloc_lines');
  FETCH lcu_po_alloc_lines INTO ln_po_alloc_line_key;    
  IF lcu_po_alloc_lines%NOTFOUND THEN
    gc_error_message := 'Get next sequence number from XX_PO_ALLOCATION_LINE_S failed: ';
    JITA_LOG_MSG(5, 'Get next sequence number from XX_PO_ALLOCATION_LINE_S');
    SELECT xx_po_allocation_line_s.nextval INTO ln_po_alloc_line_key FROM dual;
    JITA_LOG_MSG(5, 'ln_po_alloc_line_key= ' || ln_po_alloc_line_key);

    gc_error_message := 'Insert into XX_PO_ALLOCATION_LINES failed: ';
    JITA_LOG_MSG(5, 'Insert into XX_PO_ALLOCATION_LINES');
    INSERT INTO xx_po_allocation_lines ( 
      allocation_header_id
      , allocation_line_id
      , po_header_id
      , po_line_id
      , line_location_id
      , alloc_organization_id
      , ship_to_organization_id
      , jita_qty
      , wmos_qty
      , allocation_type
      , last_update_login
      , last_update_date
      , last_updated_by
      , creation_date
      , created_by )
    VALUES(
      p_po_alloc_hdr_key
      , ln_po_alloc_line_key
      , p_po_header_id
      , p_po_line_id
      , p_po_line_location_id
      , p_source_org_id
      , p_dest_org_id
      , p_jita_qty
      , p_wmos_qty
      , 'JITA' -- TO DO string literal
      , FND_GLOBAL.LOGIN_ID
      , SYSDATE
      , FND_GLOBAL.USER_ID
      , SYSDATE 
      , FND_GLOBAL.USER_ID );
  ELSE    
    JITA_LOG_MSG(5, 'ln_po_alloc_line_key= ' || ln_po_alloc_line_key);
    UPDATE xx_po_allocation_lines
    SET jita_qty = NVL(jita_qty, 0) + p_jita_qty
    , wmos_qty = NVL(wmos_qty, 0) + p_wmos_qty
    , last_update_login = FND_GLOBAL.LOGIN_ID
    , last_update_date = SYSDATE
    , last_updated_by = FND_GLOBAL.USER_ID 
    WHERE allocation_header_id = p_po_alloc_hdr_key
    AND allocation_line_id = ln_po_alloc_line_key
    AND po_header_id = p_po_header_id
    AND po_line_id = p_po_line_id
    AND line_location_id = p_po_line_location_id
    AND ship_to_organization_id = p_dest_org_id;
  END IF;
  CLOSE lcu_po_alloc_lines;

JITA_LOG_MSG(1, 'END UPDATE_PO_ALLOCATION_LINES:');
END UPDATE_PO_ALLOCATION_LINES;

PROCEDURE UPDATE_PO_ALLOC_TABLES (
  p_jita_allocation_id IN xx_mer_jita_alloc_header.allocation_id%TYPE,
  p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE,
  p_org_id IN hr_all_organization_units.organization_id%TYPE,
  p_vendor_id IN po_approved_supplier_list.vendor_id%TYPE,
  p_vendor_site_id IN po_approved_supplier_list.vendor_site_id%TYPE,
  p_po_header_id IN po_headers_all.po_header_id%TYPE,
  p_po_line_id IN po_lines_all.po_line_id%TYPE,
  p_po_line_location_id IN po_lines_all.po_line_id%TYPE,
  p_bCleanupASN BOOLEAN  ) IS

  ln_jita_qty xx_mer_jita_alloc_dtls.allocation_qty%TYPE;
  ln_wmos_qty xx_mer_jita_alloc_dtls.wmos_shipped_qty%TYPE;
  ln_po_alloc_hdr_key xx_po_allocation_header.allocation_header_id%TYPE := 0;
  jita_alloc_dtls_tbl_type jita_alloc_dtls_tbl_def;
BEGIN
  JITA_LOG_MSG(1, 'STATR UPDATE_PO_ALLOC_TABLES:');
  
  gc_module_name  := 'UPDATE_PO_ALLOC_TABLES';
  gc_error_loc := 'Query for po_alloc_header_id: ';
  gc_error_message := 'Query to get po_alloc_header_id failed: ';
  JITA_LOG_MSG(3, 'Query to to get po_alloc_header_id');  
  OPEN lcu_po_alloc_header(p_inventory_item_id, p_org_id, 
          p_vendor_id, p_vendor_site_id);  
  gc_error_message := 'Fetch from cursor lcu_po_alloc_header Failed: ';  
  JITA_LOG_MSG(5, 'Fetch from cursor lcu_po_alloc_header');
  FETCH lcu_po_alloc_header INTO ln_po_alloc_hdr_key;    
  IF lcu_po_alloc_header%NOTFOUND THEN
    gc_error_message := 'Get next sequence number from XX_PO_ALLOCATION_HEADER_S failed: ';
    JITA_LOG_MSG(5, 'Get next sequence number from XX_PO_ALLOCATION_HEADER_S');
    SELECT xx_po_allocation_header_s.nextval INTO ln_po_alloc_hdr_key FROM dual;
    JITA_LOG_MSG(5, 'ln_po_alloc_hdr_key= ' || ln_po_alloc_hdr_key);

    gc_error_message := 'Insert into XX_PO_ALLOCATION_HEADER failed: ';
    JITA_LOG_MSG(5, 'Insert into XX_PO_ALLOCATION_HEADER');
    INSERT INTO xx_po_allocation_header ( 
      allocation_header_id
      , org_id
      , item_id
      , vendor_id
      , vendor_site_id
      , last_update_login
      , last_update_date
      , last_updated_by
      , creation_date
      , created_by )
    VALUES(
      ln_po_alloc_hdr_key
      , p_org_id
      , p_inventory_item_id
      , p_vendor_id
      , p_vendor_site_id
      , FND_GLOBAL.LOGIN_ID
      , SYSDATE
      , FND_GLOBAL.USER_ID
      , SYSDATE 
      , FND_GLOBAL.USER_ID );
  ELSE    
    JITA_LOG_MSG(5, 'ln_po_alloc_hdr_key= ' || ln_po_alloc_hdr_key);    
  END IF;
  CLOSE lcu_po_alloc_header;

  -- NOW update xx_po_allocation_lines
  gc_error_loc := 'Get Data';
  gc_error_message := 'Bulk select from XX_MER_JITA_ALLOC_DTLS failed: ';
  JITA_LOG_MSG(3, 'Get Data from XX_MER_JITA_ALLOC_DTLS:');
  
  SELECT * BULK COLLECT INTO jita_alloc_dtls_tbl_type
    FROM xx_mer_jita_alloc_dtls
    WHERE allocation_id = p_jita_allocation_id
    ORDER BY dest_organization_id;
  FOR i IN 1 .. jita_alloc_dtls_tbl_type.COUNT
  LOOP
    IF p_bCleanupASN THEN
      ln_jita_qty := -jita_alloc_dtls_tbl_type(i).allocation_qty;
      ln_wmos_qty := -jita_alloc_dtls_tbl_type(i).wmos_shipped_qty;
    ELSE
      ln_jita_qty := jita_alloc_dtls_tbl_type(i).allocation_qty;
      ln_wmos_qty := jita_alloc_dtls_tbl_type(i).wmos_shipped_qty;
    END IF;
    UPDATE_PO_ALLOCATION_LINES (
      p_source_org_id => p_org_id
      , p_po_alloc_hdr_key => ln_po_alloc_hdr_key
      , p_po_header_id => p_po_header_id
      , p_po_line_id => p_po_line_id
      , p_po_line_location_id => p_po_line_location_id
      , p_dest_org_id => jita_alloc_dtls_tbl_type(i).dest_organization_id
      , p_jita_qty => ln_jita_qty
      , p_wmos_qty => ln_wmos_qty);
  END LOOP;

  JITA_LOG_MSG(1, 'END UPDATE_PO_ALLOC_TABLES:');
END UPDATE_PO_ALLOC_TABLES;

PROCEDURE MASS_UPDATE_PO_ALLOC (
  p_ASN IN  xx_mer_jita_alloc_header.asn%TYPE,
  p_org_id IN hr_all_organization_units.organization_id%TYPE,
  p_bCleanupASN BOOLEAN ) IS

  ln_vendor_id po_approved_supplier_list.vendor_id%TYPE := 0;
  ln_vendor_site_id po_approved_supplier_list.vendor_site_id%TYPE := 0;
  ln_standard_pack_qty NUMBER := 0;
  ln_case_pack_qty NUMBER := 0;

  jita_alloc_id_tbl_type jita_alloc_id_tbl_def := jita_alloc_id_tbl_def();
  jita_alloc_header_tbl_type jita_alloc_header_tbl_def;
BEGIN
  JITA_LOG_MSG(1, 'Start procedure MASS_UPDATE_PO_ALLOC ');

  gc_module_name  := 'MASS_UPDATE_PO_ALLOC';
  gc_error_loc := 'Query xx_mer_jita_alloc_header';
  gc_error_message := 'Query xx_mer_jita_alloc_header failed: ';
  JITA_LOG_MSG(5, 'Query xx_mer_jita_alloc_header');
  
  SELECT * BULK COLLECT INTO jita_alloc_header_tbl_type
    FROM XX_MER_JITA_ALLOC_HEADER 
    WHERE asn = p_ASN
    AND organization_id = p_org_id;
  jita_alloc_id_tbl_type.extend (jita_alloc_header_tbl_type.COUNT);

  FOR i IN 1 .. jita_alloc_header_tbl_type.COUNT
  LOOP
    jita_alloc_id_tbl_type(i) := jita_alloc_header_tbl_type(i).allocation_id;
    GET_PACK_SIZE_INFO ( 
      p_inventory_item_id => jita_alloc_header_tbl_type(i).inventory_item_id
      , p_org_id => p_org_id
      , p_po_header_id => jita_alloc_header_tbl_type(i).po_header_id
      , p_standard_pack_qty => ln_standard_pack_qty
      , p_case_pack_qty => ln_case_pack_qty
      , p_vendor_id => ln_vendor_id
      , p_vendor_site_id => ln_vendor_site_id);

    UPDATE_PO_ALLOC_TABLES (
      p_jita_allocation_id => jita_alloc_header_tbl_type(i).allocation_id
      , p_inventory_item_id => jita_alloc_header_tbl_type(i).inventory_item_id
      , p_org_id => p_org_id
      , p_vendor_id =>ln_vendor_id
      , p_vendor_site_id => ln_vendor_site_id
      , p_po_header_id  => jita_alloc_header_tbl_type(i).po_header_id
      , p_po_line_id => jita_alloc_header_tbl_type(i).po_line_id
      , p_po_line_location_id => jita_alloc_header_tbl_type(i).line_location_id
      , p_bCleanupASN => p_bCleanupASN);     
  END LOOP;

  JITA_LOG_MSG(1, 'End procedure MASS_UPDATE_PO_ALLOC ');
END MASS_UPDATE_PO_ALLOC;

PROCEDURE COMP_NEED_AND_PCT (p_standard_pack_qty IN NUMBER,
    p_case_pack_qty IN NUMBER) IS
    
  jita_temp_tbl_type jita_temp_tbl_def;
  org_id_tbl_type org_id_tbl_def := org_id_tbl_def();
BEGIN

  JITA_LOG_MSG(1, 'START COMP_NEED_AND_PCT:');
  
  gc_module_name  := 'COMP_NEED_AND_PCT';
  gc_error_loc := 'Get Data ';
  gc_error_message := 'Bulk select from XX_MER_JITA_TEMP failed: ';
  JITA_LOG_MSG(3, 'Get Data from XX_MER_JITA_TEMP:');
  
  SELECT * BULK COLLECT INTO jita_temp_tbl_type
    FROM XX_MER_JITA_TEMP
    ORDER BY organization_id;
    
  org_id_tbl_type.extend (jita_temp_tbl_type.COUNT);
  
  gc_module_name  := 'COMP_NEED_AND_PCT';
  gc_error_loc := 'Compute';
  gc_error_message := 'Compute need and need percent failed: ';
  JITA_LOG_MSG(3, 'Compute need and need percent');
  FOR i IN 1 .. jita_temp_tbl_type.COUNT
  LOOP
    jita_temp_tbl_type(i).need := jita_temp_tbl_type(i).RUTL
        - jita_temp_tbl_type(i).Sellable_on_hand
        - jita_temp_tbl_type(i).In_transit_qty
        - jita_temp_tbl_type(i).Prior_allocation_qty;
    --IF jita_temp_tbl_type(i).need < 0 THEN
      --jita_temp_tbl_type(i).need := 0;
    --END IF;
    JITA_LOG_MSG(5, 'RUTL=' || jita_temp_tbl_type(i).rutl);
    JITA_LOG_MSG(5, 'Need=' || jita_temp_tbl_type(i).need);
    jita_temp_tbl_type(i).rounded_need := ROUND_QTY(
          p_raw_qty => jita_temp_tbl_type(i).need, 
          p_store_type => jita_temp_tbl_type(i).store_type,
          p_standard_pack_qty => p_standard_pack_qty,
          p_case_pack_qty => p_case_pack_qty);
    JITA_LOG_MSG(5, 'RndNeed=' || jita_temp_tbl_type(i).rounded_need);
    
    IF (jita_temp_tbl_type(i).RUTL <> 0 ) THEN
      --jita_temp_tbl_type(i).need_pct := 
        --jita_temp_tbl_type(i).rounded_need/jita_temp_tbl_type(i).RUTL;
      jita_temp_tbl_type(i).need_pct := 
        jita_temp_tbl_type(i).need/jita_temp_tbl_type(i).RUTL;
    END IF;
    JITA_LOG_MSG(5, 'NeedPct=' || jita_temp_tbl_type(i).need_pct);
    org_id_tbl_type(i) := jita_temp_tbl_type(i).organization_id;
    JITA_LOG_MSG(5, ' ');
  END LOOP;
  
  gc_module_name  := 'COMP_NEED_AND_PCT';
  gc_error_loc := 'Update';
  gc_error_message := 'Bulk update need and need percent failed: ';  
  JITA_LOG_MSG(3, 'Bulk update need and need percent');
  FORALL i IN 1 .. jita_temp_tbl_type.COUNT
    UPDATE XX_MER_JITA_TEMP SET ROW = jita_temp_tbl_type(i)
    WHERE  organization_id = org_id_tbl_type(i);
    
  JITA_LOG_MSG(1, 'END COMP_NEED_AND_PCT:');  
END COMP_NEED_AND_PCT;

PROCEDURE COMP_CUMULATIVE_NEEDS(
    p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE,
    p_standard_pack_qty IN NUMBER,
    p_case_pack_qty IN NUMBER) IS
  l_tmp_need NUMBER := 0;
  jita_temp_tbl_type jita_temp_tbl_def;
  org_id_tbl_type org_id_tbl_def := org_id_tbl_def();
BEGIN
-- TO DO use actual tables
/*
  JITA_LOG_MSG(1, 'START COMP_CUMULATIVE_NEEDS:');
  
  gc_module_name  := 'COMP_CUMULATIVE_NEEDS';
  gc_error_loc := 'Get Data ';
  gc_error_message := 'Bulk select from XX_MER_JITA_TEMP failed: ';
  JITA_LOG_MSG(3, 'Get Data from XX_MER_JITA_TEMP:');
  
  SELECT * BULK COLLECT INTO jita_temp_tbl_type
    FROM XX_MER_JITA_TEMP
    ORDER BY organization_id;
    
  org_id_tbl_type.extend (jita_temp_tbl_type.COUNT);
  
  gc_module_name  := 'COMP_CUMULATIVE_NEEDS';
  gc_error_loc := 'Compute';
  gc_error_message := 'Compute cumulative need failed: ';
  JITA_LOG_MSG(3, 'Compute cumulative need: ');
  FOR i IN 1 .. jita_temp_tbl_type.COUNT
  LOOP
    org_id_tbl_type(i) := jita_temp_tbl_type(i).organization_id;
    jita_temp_tbl_type(i).need := 0;
    jita_temp_tbl_type(i).rutl := 0;
    jita_temp_tbl_type(i).Avg_rate_of_sale := 0;
    jita_temp_tbl_type(i).Sellable_on_hand := 0;
    
    JITA_LOG_MSG(3, 'Query for inventory data of all stores served by ' 
          || org_id_tbl_type(i));
    gc_module_name  := 'COMP_CUMULATIVE_NEEDS';
    gc_error_loc := 'Query for inventory data';
    gc_error_message := 'Query for inventory data of all stores served by ' 
          || org_id_tbl_type(i) || ' failed. ';  
    -- TO DO This query need to be update dto get store type, to use actual inventory tables
    JITA_LOG_MSG(5, 'Location_id: ' || org_id_tbl_type(i) );
    -- TO DO change the query below
    FOR item IN 
    ( SELECT t1.dest_organization_id, t2.Sellable_on_hand, 
      t2.RUTL, t2.In_transit_qty, t2.Avg_rate_of_sale
      FROM XX_MER_JITA_OD_SOURCING t1, XX_MER_JITA_INV t2
      WHERE t1.dest_organization_id = t2.location_id
      AND t1.source_organization_id = org_id_tbl_type(i)
      AND t1.item_id = p_inventory_item_id )
    LOOP
      l_tmp_need := item.RUTL - item.Sellable_on_hand - item.In_transit_qty;
      IF (l_tmp_need < 0) THEN
        l_tmp_need := 0;
      END IF;
      JITA_LOG_MSG(5, 'loc= ' || item.dest_organization_id 
          || 'tmp_need: ' || l_tmp_need );
      jita_temp_tbl_type(i).need := jita_temp_tbl_type(i).need + ROUND_QTY(
          p_raw_qty => l_tmp_need, 
          p_store_type => 'RG', --TO DO remove hard coding
          p_standard_pack_qty => p_standard_pack_qty,
          p_case_pack_qty => p_case_pack_qty);
      JITA_LOG_MSG(5, 'Need for location: ' || jita_temp_tbl_type(i).need );
         
      jita_temp_tbl_type(i).rutl := jita_temp_tbl_type(i).rutl + ROUND_QTY(
          p_raw_qty => item.RUTL, 
          p_store_type => 'RG', --TO DO remove hard coding
          p_standard_pack_qty => p_standard_pack_qty,
          p_case_pack_qty => p_case_pack_qty);
      JITA_LOG_MSG(5, 'RUTL for location: ' || jita_temp_tbl_type(i).rutl );
      jita_temp_tbl_type(i).Avg_rate_of_sale := 
           jita_temp_tbl_type(i).Avg_rate_of_sale +
           item.Avg_rate_of_sale;
      jita_temp_tbl_type(i).Sellable_on_hand :=
           jita_temp_tbl_type(i).Sellable_on_hand +
           item.Sellable_on_hand;
    END LOOP;
    jita_temp_tbl_type(i).need := jita_temp_tbl_type(i).need 
              - jita_temp_tbl_type(i).prior_allocation_qty;
    IF jita_temp_tbl_type(i).need < 0 THEN
      jita_temp_tbl_type(i).need := 0;
    END IF;
    JITA_LOG_MSG(5, ' ');
    JITA_LOG_MSG(5, 'cumulative need for location: ' || jita_temp_tbl_type(i).need );
    jita_temp_tbl_type(i).rounded_need := jita_temp_tbl_type(i).need;
    IF (jita_temp_tbl_type(i).RUTL <> 0 ) THEN
      --jita_temp_tbl_type(i).need_pct := 
        --jita_temp_tbl_type(i).rounded_need/jita_temp_tbl_type(i).RUTL;
      jita_temp_tbl_type(i).need_pct := 
        jita_temp_tbl_type(i).need/jita_temp_tbl_type(i).RUTL;
    END IF;
  END LOOP;
  
  gc_module_name  := 'COMP_CUMULATIVE_NEEDS';
  gc_error_loc := 'Update';
  gc_error_message := 'Bulk update need and need percent failed: ';  
  JITA_LOG_MSG(3, 'Bulk update need and need percent');
  FORALL i IN 1 .. jita_temp_tbl_type.COUNT
    UPDATE XX_MER_JITA_TEMP SET ROW = jita_temp_tbl_type(i)
    WHERE  organization_id = org_id_tbl_type(i);*/
    
  JITA_LOG_MSG(1, 'END COMP_CUMULATIVE_NEEDS:');  
END COMP_CUMULATIVE_NEEDS;

PROCEDURE NEED_PCT_ALLOC ( p_standard_pack_qty IN NUMBER,
  p_case_pack_qty IN NUMBER,
  p_is_a_new_store IN CHAR,
  p_alloc_type IN VARCHAR2,
  p_allocation_id IN NUMBER,
  p_distro_type IN NUMBER,
  p_is_alloc_excess IN BOOLEAN,
  p_distro_num IN OUT NUMBER,
  p_distribution_qty IN OUT NUMBER) IS
  
  ln_pack_qty NUMBER := NULL;
  ln_tmp_num  NUMBER := NULL;
  ln_alloc_qty NUMBER := NULL;
  ln_rnd_alloc_qty NUMBER := NULL;
  lc_log_msg  CLOB := NULL;
  lb_all_stores_NT BOOLEAN := true;
  lb_Exit_main_loop BOOLEAN := false;
  ln_loop_counter NUMBER := 0;
    
  jita_temp_tbl_type jita_temp_tbl_def;
  org_id_tbl_type org_id_tbl_def := org_id_tbl_def();
BEGIN
  
  JITA_LOG_MSG(1, 'START NEED PCT FILL:');
  JITA_LOG_MSG(1, 'Quantity available to distribute= ' || p_distribution_qty);
  
  
  ln_loop_counter := 0;
  lb_Exit_main_loop := false;
  WHILE p_distribution_qty > 0 
  LOOP
    ln_loop_counter := ln_loop_counter + 1;
    IF lb_Exit_main_loop THEN
      EXIT;
    END IF;
    gc_module_name  := 'NEED_PCT_ALLOC';
    gc_error_loc := 'Query to get need and pct ';
    gc_error_message := 'Bulk select from XX_MER_JITA_TEMP failed: ';
    JITA_LOG_MSG(3, 'Query to get need and pct');
    IF NOT p_is_alloc_excess THEN
      SELECT * BULK COLLECT INTO jita_temp_tbl_type
        FROM XX_MER_JITA_TEMP
        WHERE new_store_flag = p_is_a_new_store
        ORDER BY need_pct desc, Avg_rate_of_sale desc; -- TO DO use prior 
        --alloc qty as well
    ELSE
      SELECT * BULK COLLECT INTO jita_temp_tbl_type
        FROM XX_MER_JITA_TEMP
        ORDER BY need_pct desc, Avg_rate_of_sale desc; -- TO DO use prior 
        --alloc qty as well
    END IF;
    
    IF ln_loop_counter = 1 THEN
      FOR I IN 1 .. jita_temp_tbl_type.COUNT
      LOOP
        IF jita_temp_tbl_type(I).store_type <> G_STORE_TYPE_NON_TRADITIONAL THEN
          lb_all_stores_NT := false;
          EXIT;
        END IF;
      END LOOP;
    END IF;
        
    IF jita_temp_tbl_type.COUNT < 1 THEN
      EXIT;
    END IF;    

    IF NOT p_is_alloc_excess 
       AND (jita_temp_tbl_type(1).need_pct <= 0) THEN
          EXIT;
    END IF;

    IF jita_temp_tbl_type.COUNT = 1 THEN
      IF jita_temp_tbl_type(1).store_type = G_STORE_TYPE_NON_TRADITIONAL THEN
        IF p_is_alloc_excess  THEN
          ln_alloc_qty := jita_temp_tbl_type(1).rutl *
                              (gn_NT_alloc_excess_factor - 1.0) 
                          + jita_temp_tbl_type(1).need;
          jita_temp_tbl_type(1).need := -99999999; -- TO DO use a constant
        ELSE
          ln_rnd_alloc_qty := jita_temp_tbl_type(1).need;
        END IF;
        ln_rnd_alloc_qty := ROUND_QTY(
            p_raw_qty => ln_alloc_qty, 
            p_store_type => jita_temp_tbl_type(1).store_type,
            p_standard_pack_qty => p_standard_pack_qty,
            p_case_pack_qty => p_case_pack_qty);
        JITA_LOG_MSG(5, 'RndAllocQty=' || ln_rnd_alloc_qty);
        IF (p_distribution_qty <= ln_rnd_alloc_qty) THEN   
            ln_rnd_alloc_qty := trunc(p_distribution_qty/p_case_pack_qty) 
                                    * p_case_pack_qty;
        END IF;
      ELSE
        IF p_is_alloc_excess  OR 
           (p_distribution_qty <= jita_temp_tbl_type(1).need) THEN         
             ln_rnd_alloc_qty := p_distribution_qty;
        ELSE
          ln_rnd_alloc_qty := jita_temp_tbl_type(1).need;
        END IF;
      END IF;
      lb_Exit_main_loop := true;
    ELSE
      /* The following logic works  better if we have need pcts wide spread.
         If need pcts are close to each other, then extra math steps may not make sense
         Keeping the code commented out for now.
      
      --JITA_LOG_MSG(5, 'loc_id=' || jita_temp_tbl_type(1).organization_id);
      --JITA_LOG_MSG(5, 'needpct1=' || jita_temp_tbl_type(1).need_pct);
      -- JITA_LOG_MSG(5, 'needpct2=' || jita_temp_tbl_type(2).need_pct);
      ln_alloc_qty := jita_temp_tbl_type(1).rutl
        * (jita_temp_tbl_type(1).need_pct - jita_temp_tbl_type(2).need_pct);
      IF ln_alloc_qty = 0 THEN -- meaning same need percent 
                            --for first and second store
        ln_alloc_qty := 1; -- THis will be rounded to 1 std. pack later
      END IF;
    END IF;
    JITA_LOG_MSG(5, 'AllocQty=' || ln_alloc_qty);
    --round allocation qty
    ln_rnd_alloc_qty := ROUND_QTY(
          p_raw_qty => ln_alloc_qty, 
          p_store_type => jita_temp_tbl_type(1).store_type,
          p_standard_pack_qty => p_standard_pack_qty,
          p_case_pack_qty => p_case_pack_qty);      
    
   -- JITA_LOG_MSG(5, 'DistQty=' || p_distribution_qty);
    gc_module_name  := 'NEED_PCT_ALLOC';
    gc_error_loc := 'Need percent algortithm ';
    gc_error_message := 'Need percent calculations failed: ';  
    IF (ln_rnd_alloc_qty > p_distribution_qty) THEN
      IF jita_temp_tbl_type(1).store_type = G_STORE_TYPE_NON_TRADITIONAL THEN
        ln_rnd_alloc_qty := trunc(p_distribution_qty/p_case_pack_qty) 
                                    * p_case_pack_qty;
        IF lb_all_stores_NT THEN
          lb_Exit_main_loop := true;
        ELSE
          jita_temp_tbl_type(1).need_pct := -9999999; -- TO DO use a constant
        END IF;
      ELSE
        ln_rnd_alloc_qty := p_distribution_qty;
      END IF;
    END IF;
*/
      JITA_LOG_MSG(5, 'loc_id=' || jita_temp_tbl_type(1).organization_id);
      JITA_LOG_MSG(5, 'needpct1=' || jita_temp_tbl_type(1).need_pct);
      IF jita_temp_tbl_type(1).store_type = G_STORE_TYPE_NON_TRADITIONAL THEN
        IF jita_temp_tbl_type(1).need_pct <= 1.0 - gn_NT_alloc_excess_factor THEN
          ln_rnd_alloc_qty := 0;
          jita_temp_tbl_type(1).need := -99999999; -- TO DO use a constant
        ELSIF (p_distribution_qty >= p_case_pack_qty) THEN
          ln_rnd_alloc_qty := p_case_pack_qty;
        ELSE
          ln_rnd_alloc_qty := 0;
          IF lb_all_stores_NT THEN
            lb_Exit_main_loop := true;
          ELSE
            jita_temp_tbl_type(1).need := -99999999; -- TO DO use a constant
          END IF;
        END IF;
      ELSE
        IF (p_distribution_qty >= p_standard_pack_qty) THEN
          ln_rnd_alloc_qty := p_standard_pack_qty;
        ELSE
          ln_rnd_alloc_qty := p_distribution_qty;
        END IF;
      END IF;
    END IF;

   p_distribution_qty := p_distribution_qty - ln_rnd_alloc_qty;
   JITA_LOG_MSG(5, 'RndAllocQty=' || ln_rnd_alloc_qty);
   JITA_LOG_MSG(5, 'DistQty=' || p_distribution_qty);
   lc_log_msg := lc_log_msg || RPAD(jita_temp_tbl_type(1).organization_id, 10) 
        || RPAD('SOH',10)   
        || RPAD(NVL(jita_temp_tbl_type(1).prior_allocation_qty,0), 10)
        || RPAD('RUTL', 10) || RPAD('Need', 10) 
        || RPAD(NVL(ln_rnd_alloc_qty, 0), 10) || GC_EOL;
    jita_temp_tbl_type(1).dynamic_qty := 
      jita_temp_tbl_type(1).dynamic_qty + ln_rnd_alloc_qty; 
    jita_temp_tbl_type(1).prior_allocation_qty := 
      jita_temp_tbl_type(1).prior_allocation_qty 
      + ln_rnd_alloc_qty;
    jita_temp_tbl_type(1).allocation_qty := 
      jita_temp_tbl_type(1).allocation_qty 
      + ln_rnd_alloc_qty;
    jita_temp_tbl_type(1).need := 
      jita_temp_tbl_type(1).need - ln_rnd_alloc_qty;
    jita_temp_tbl_type(1).rounded_need := 
      jita_temp_tbl_type(1).rounded_need - ln_rnd_alloc_qty;
    
    IF jita_temp_tbl_type(1).rutl <> 0 THEN
      --jita_temp_tbl_type(1).need_pct := 
        --jita_temp_tbl_type(1).rounded_need/jita_temp_tbl_type(1).RUTL;
      jita_temp_tbl_type(1).need_pct := 
        jita_temp_tbl_type(1).need/jita_temp_tbl_type(1).RUTL;
    END IF;
    /*gc_module_name  := 'NEED_PCT_ALLOC';
    gc_error_loc := 'Insert distros';
    gc_error_message := 'Insert into  XX_MER_JITA_DISTROS failed: ';  
    JITA_LOG_MSG(5, 'Insert into  XX_MER_JITA_DISTROS');
    INSERT INTO XX_MER_JITA_DISTROS(allocation_id, dest_location_id,
        alloc_qty, alloc_type, distro_num, distro_type)
      VALUES(p_allocation_id, jita_temp_tbl_type(1).organization_id, 
      ln_rnd_alloc_qty, p_alloc_type, p_distro_num, p_distro_type);
    
    p_distro_num := p_distro_num + 1;*/
    
    --ELSE
    --  jita_temp_tbl_type(1).need_pct := 0;
    --  EXIT;
    --END IF;
    
    UPDATE XX_MER_JITA_TEMP SET ROW = jita_temp_tbl_type(1)
        WHERE organization_id = jita_temp_tbl_type(1).organization_id;
  END LOOP;    
  
  IF lc_log_msg IS NOT NULL THEN    
    lc_log_msg := GC_EOL || RPAD('Location',10) || RPAD('SOH',10) 
      || RPAD('PrevAlloc', 10) || RPAD('RUTL', 10) || RPAD('Need', 10) 
      || RPAD('Allocated', 10) || GC_EOL || lc_log_msg;
    JITA_LOG_MSG(1, lc_log_msg);
  END IF;
  JITA_LOG_MSG(1, 'END NEED PCT FILL:');
END NEED_PCT_ALLOC;

PROCEDURE BOTTOM_FILL (p_distribution_qty IN OUT NUMBER,
    p_standard_pack_qty IN NUMBER,
    p_case_pack_qty IN NUMBER,
    p_is_a_new_store IN CHAR,
    p_alloc_type IN VARCHAR2,
    p_allocation_id IN NUMBER,
    p_distro_type IN NUMBER,
    p_distro_num IN OUT NUMBER) IS

  ln_count NUMBER;
  lc_log_msg  CLOB := NULL;
  l_bottom_fill_threshold NUMBER(12,6) := gn_bottom_fill_threshold;
  ln_bottom_fill_qty NUMBER := 0;
BEGIN
  
  IF p_is_a_new_store = 'Y' THEN
    JITA_LOG_MSG(1, 'START NEW STORES BOTTOM FILL:');
    l_bottom_fill_threshold := gn_bottom_fill_threshold_ns;
  ELSE
    JITA_LOG_MSG(1, 'START OUTS FILL:');
  END IF;
  JITA_LOG_MSG(1, 'Quantity available to distribute= ' || p_distribution_qty);
  
 /* -- This 2 step approach might be faster if we have enough quantity to bottom 
  -- fill. 
  SELECT COUNT(*) INTO ln_count FROM XX_MER_JITA_TEMP 
  WHERE (sellable_on_hand + in_transit_qty + prior_allocation_qty) <= 0
  AND new_store_flag = p_is_a_new_store;
  
  IF (ln_count * p_standard_pack_qty) <= p_distribution_qty THEN
      UPDATE XX_MER_JITA_TEMP 
        SET prior_allocation_qty = prior_allocation_qty + p_standard_pack_qty,
        allocation_qty = allocation_qty + p_standard_pack_qty,
        bottom_fill_qty = p_standard_pack_qty
        WHERE (sellable_on_hand + in_transit_qty + prior_allocation_qty) <= 0
        AND new_store_flag = p_is_a_new_store;
    
    -- TO DO insert records into XX_MER_JITA_Distros table
    
      
    p_distribution_qty := p_distribution_qty - (ln_count * p_standard_pack_qty);    
  ELSE*/
    
    JITA_LOG_MSG(3, 'Query for bottom fill data');
    gc_module_name  := 'BOTTOM_FILL';
    gc_error_loc := 'Query for bottom fill data';
    gc_error_message := 'Select for bottom-fill data failed: ';  
    FOR item IN 
    ( SELECT organization_id, prior_allocation_qty, store_type
      FROM XX_MER_JITA_TEMP
      WHERE (sellable_on_hand + in_transit_qty + prior_allocation_qty)
        < l_bottom_fill_threshold * rutl
      AND new_store_flag = p_is_a_new_store
      AND rutl > 0 
      ORDER BY (sellable_on_hand + in_transit_qty + prior_allocation_qty)/rutl ASC,
        avg_rate_of_sale DESC )
-- TO DO if same ARS then use a tie braker      
    LOOP
      JITA_LOG_MSG(5, 'bottomfill:organization_id= ' || item.organization_id);
      IF p_distribution_qty <= 0 THEN
        EXIT;
      ELSIF item.store_type = G_STORE_TYPE_NON_TRADITIONAL THEN
        IF p_distribution_qty < p_case_pack_qty THEN
          ln_bottom_fill_qty := 0;
        ELSE
          ln_bottom_fill_qty := p_case_pack_qty;
        END IF;
      ELSE
        IF p_distribution_qty < p_standard_pack_qty THEN
          ln_bottom_fill_qty := p_distribution_qty;
        ELSE
         ln_bottom_fill_qty := p_standard_pack_qty;
        END IF;
      END IF;

      gc_module_name  := 'BOTTOM_FILL';
      gc_error_loc := 'Update bottom fill data ';
      gc_error_message := 'Update XX_MER_JITA_TEMP failed: ';  
      JITA_LOG_MSG(5, 'Update XX_MER_JITA_TEMP');
      lc_log_msg := lc_log_msg || RPAD(item.organization_id,10) 
        || RPAD('SOH',10)   || RPAD(NVL(item.prior_allocation_qty, 0), 10)
        || RPAD('RUTL', 10) || RPAD('Need', 10) 
        || RPAD(NVL(ln_bottom_fill_qty, 0), 10) || GC_EOL;
      UPDATE XX_MER_JITA_TEMP 
        SET prior_allocation_qty = prior_allocation_qty + ln_bottom_fill_qty,
        allocation_qty = allocation_qty + ln_bottom_fill_qty,
        bottom_fill_qty = ln_bottom_fill_qty
        WHERE organization_id = item.organization_id;
      
      p_distribution_qty := p_distribution_qty - ln_bottom_fill_qty;
      
      /*gc_module_name  := 'BOTTOM_FILL';
      gc_error_loc := 'Insert bottom fill distros ';
      gc_error_message := 'Insert into XX_MER_JITA_DISTROS failed: ';  
      JITA_LOG_MSG(5, 'Insert into XX_MER_JITA_DISTROS');
      INSERT INTO XX_MER_JITA_DISTROS(allocation_id, dest_location_id,
        alloc_qty, alloc_type, distro_num, distro_type)
      VALUES(p_allocation_id, item.organization_id, 
      ln_bottom_fill_qty, p_alloc_type, p_distro_num, p_distro_type);
      
      p_distro_num := p_distro_num + 1;*/
    END LOOP;
  --END IF;

  IF lc_log_msg IS NOT NULL THEN    
    lc_log_msg := GC_EOL || RPAD('Location',10) || RPAD('SOH',10) 
      || RPAD('PrevAlloc', 10) || RPAD('RUTL', 10) || RPAD('Need', 10) 
      || RPAD('Allocated', 10) || GC_EOL || lc_log_msg;
    JITA_LOG_MSG(1, lc_log_msg);
  END IF;
  IF p_is_a_new_store = 'Y' THEN
    JITA_LOG_MSG(1, 'END NEW STORES BOTTOM FILL:');
  ELSE
    JITA_LOG_MSG(1, 'END OUTS FILL:');
  END IF;
END BOTTOM_FILL;

PROCEDURE LOCKIN_ALLOC(
    p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE,
    p_org_id hr_all_organization_units.organization_id%TYPE,
    p_po_header_id   po_headers_all.po_header_id%TYPE,
    p_po_line_id     po_lines_all.po_line_id%TYPE,
    p_po_line_location_id    po_lines_all.po_line_id%TYPE,
    p_standard_pack_qty IN NUMBER,
    p_case_pack_qty IN NUMBER,
    p_lockin_type XX_MER_JITA_ALLOC_PRIORITY.allocation_code%TYPE,
    p_allocation_id IN NUMBER,
    p_distro_type IN NUMBER,
    p_distribution_qty IN OUT NUMBER,
    p_distro_num IN OUT NUMBER) IS

  ln_pack_qty NUMBER := 0;
  ln_rnd_lockin_qty NUMBER := 0;
  ln_prior_lock_qty NUMBER := 0;
  ln_lockin_alloc_qty NUMBER := 0;
  lc_log_msg  CLOB := NULL;
  lockin_tbl_type jita_temp_lockin_tbl_def;
BEGIN

  IF p_lockin_type = G_ALLOC_CODE_LOCK THEN
    JITA_LOG_MSG(1, 'START LOCKED IN ALLOCATIONS:');
  ELSIF p_lockin_type = G_ALLOC_CODE_ATP THEN
    JITA_LOG_MSG(1, 'START ATP CUSTOMER ORDER ALLOCATIONS:');
  ELSIF p_lockin_type = G_ALLOC_CODE_ATP_SL THEN
    JITA_LOG_MSG(1, 'START LARGE OR SEASONAL ORDER ALLOCATIONS:');
  END IF;  
  JITA_LOG_MSG(1, 'Quantity available to distribute= ' || p_distribution_qty);
  
  gc_module_name  := 'LOCKIN_ALLOC';
  gc_error_loc := 'Query for locked-in data ';
  gc_error_message := 'Bulk select for locked-in data failed: ';
  JITA_LOG_MSG(3, 'Query to get lock in data');
  -- TO DO make it a cursor.
  SELECT t3.organization_id, t3.store_type, t3.need, t3.rounded_need, 
    t3.prior_allocation_qty, t3.prior_lockin_qty, 
    t3.prior_seasonal_lrg_qty, t3.prior_atp_cust_order_qty, t3.allocation_qty,
    t3.lockin_alloc_qty,t3.seasonal_lrg_ord_qty, t3.atp_customer_order_qty,
    t2.allocation_qty, t2.wmos_qty
    BULK COLLECT INTO lockin_tbl_type
    FROM XX_PO_ALLOCATION_HEADER t1, XX_PO_ALLOCATION_LINES t2, 
      XX_MER_JITA_TEMP t3
    WHERE t1.allocation_header_id = t2.allocation_header_id
    AND t2.ship_to_organization_id = t3.organization_id
    AND t2.po_header_id = p_po_header_id
    AND t2.po_line_id = p_po_line_id
    AND t2.line_location_id = p_po_line_location_id
    AND t1.item_id = p_inventory_item_id
    AND t1.org_id = p_org_id
    AND t2.locked_in = 'Y'
    AND t2.allocation_type = p_lockin_type
    AND t2.allocation_qty > 0
    order by t3.avg_rate_of_sale desc;
      
  JITA_LOG_MSG(5, 'lockin rec count=' || lockin_tbl_type.COUNT);
  
  gc_module_name  := 'LOCKIN_ALLOC';
  gc_error_loc := 'Compute locked-in data ';
  gc_error_message := 'Determining lock-in data failed: ';
  JITA_LOG_MSG(3, 'Compute locked-in data ');
  FOR I in 1 .. lockin_tbl_type.COUNT
  LOOP
    IF p_distribution_qty <= 0 THEN
      EXIT;
    END IF;
    IF p_lockin_type = G_ALLOC_CODE_LOCK THEN
       ln_prior_lock_qty := lockin_tbl_type(i).prior_lockin_qty;
    ELSIF p_lockin_type = G_ALLOC_CODE_ATP_SL THEN
       ln_prior_lock_qty := lockin_tbl_type(i).prior_seasonal_lrg_qty;
    ELSIF p_lockin_type = G_ALLOC_CODE_ATP THEN
       ln_prior_lock_qty := lockin_tbl_type(i).prior_atp_cust_order_qty;
    END IF;
    
    -- Due to shortage if prior lock in request is not completely honored 
    -- then the next shipment should give enough to fulfill lockin qty
    IF lockin_tbl_type(i).wmos_qty < ln_prior_lock_qty THEN
      ln_prior_lock_qty := lockin_tbl_type(i).wmos_qty;
    END IF;

    JITA_LOG_MSG(5, 'Location Id = ' || lockin_tbl_type(i).organization_id);
    JITA_LOG_MSG(5, 'Prior lockin Qty = ' || ln_prior_lock_qty);
    IF lockin_tbl_type(i).lockin_request_qty < p_distribution_qty THEN
      ln_lockin_alloc_qty := lockin_tbl_type(i).lockin_request_qty 
                               - ln_prior_lock_qty;
    ELSE
      ln_lockin_alloc_qty := p_distribution_qty - ln_prior_lock_qty;
    END IF;
    
    -- TO DO handle the case where remaining dist qty is not a rounded qty
    IF ln_lockin_alloc_qty > 0 THEN
      JITA_LOG_MSG(5, 'Round lockin Qty = ' || ln_prior_lock_qty);
      ln_rnd_lockin_qty := ROUND_QTY(
          p_raw_qty => ln_lockin_alloc_qty, 
          p_store_type => lockin_tbl_type(i).store_type,
          p_standard_pack_qty => p_standard_pack_qty,
          p_case_pack_qty => p_case_pack_qty);
      IF p_distribution_qty >= ln_rnd_lockin_qty THEN
        IF p_lockin_type = G_ALLOC_CODE_LOCK THEN
          lockin_tbl_type(i).lockin_alloc_qty := ln_rnd_lockin_qty;
        ELSIF p_lockin_type = G_ALLOC_CODE_ATP THEN
          lockin_tbl_type(i).atp_customer_order_qty := ln_rnd_lockin_qty;
        ELSIF p_lockin_type = G_ALLOC_CODE_ATP_SL THEN
          lockin_tbl_type(i).seasonal_lrg_ord_qty := ln_rnd_lockin_qty;
        END IF;
        
        lc_log_msg := lc_log_msg || RPAD(lockin_tbl_type(i).organization_id,10) 
          || RPAD('SOH',10)   || RPAD(lockin_tbl_type(i).prior_allocation_qty, 10)
          || RPAD('RUTL', 10) || RPAD('Need', 10) 
          || RPAD(NVL(lockin_tbl_type(i).lockin_request_qty, 0), 10) 
          || RPAD(NVL(ln_rnd_lockin_qty, 0), 10) || GC_EOL;
        
        lockin_tbl_type(i).prior_allocation_qty := 
          lockin_tbl_type(i).prior_allocation_qty + ln_rnd_lockin_qty;
  
        lockin_tbl_type(i).allocation_qty := 
          lockin_tbl_type(i).allocation_qty + ln_rnd_lockin_qty;
        
        JITA_LOG_MSG(5, 'Update XX_MER_JITA_TEMP');
        gc_error_message := 'Update XX_MER_JITA_TEMP failed: ';
        UPDATE XX_MER_JITA_TEMP 
          SET prior_allocation_qty = lockin_tbl_type(i).prior_allocation_qty,
            allocation_qty = lockin_tbl_type(i).allocation_qty,
            lockin_alloc_qty = lockin_tbl_type(i).lockin_alloc_qty,
            seasonal_lrg_ord_qty = lockin_tbl_type(i).seasonal_lrg_ord_qty,
            atp_customer_order_qty = lockin_tbl_type(i).atp_customer_order_qty
          WHERE organization_id = lockin_tbl_type(i).organization_id;
          
        /*JITA_LOG_MSG(5, 'Insert into  XX_MER_JITA_DISTROS:');
        gc_error_message := 'Insert into  XX_MER_JITA_DISTROS: ';        
        INSERT INTO XX_MER_JITA_DISTROS(allocation_id, dest_location_id,
          alloc_qty, alloc_type, distro_num, distro_type)
        VALUES(p_allocation_id, lockin_tbl_type(i).location_id, 
        ln_rnd_lockin_qty, p_lockin_type, p_distro_num, p_distro_type);
        
        p_distro_num := p_distro_num + 1;*/
        
        p_distribution_qty := p_distribution_qty - ln_rnd_lockin_qty;
      END IF;
    END IF;
  END LOOP;
  
  IF lc_log_msg IS NOT NULL THEN    
    lc_log_msg := GC_EOL || RPAD('Location',10) || RPAD('SOH',10) 
      || RPAD('PrevAlloc', 10) || RPAD('RUTL', 10) || RPAD('Need', 10) 
      || RPAD('LockInReq', 10) || RPAD('Allocated', 10) || GC_EOL ||
      lc_log_msg;
    JITA_LOG_MSG(1, lc_log_msg);
  END IF;
  IF p_lockin_type = G_ALLOC_CODE_LOCK THEN
    JITA_LOG_MSG(1, 'END LOCKED IN ALLOCATIONS:');
  ELSIF p_lockin_type = G_ALLOC_CODE_ATP THEN
    JITA_LOG_MSG(1, 'END ATP CUSTOMER ORDER ALLOCATIONS:');
  ELSIF p_lockin_type = G_ALLOC_CODE_ATP_SL THEN
    JITA_LOG_MSG(1, 'END LARGE OR SEASONAL ORDER ALLOCATIONS:');
  END IF;  
        
END LOCKIN_ALLOC;

PROCEDURE DYNAMIC_NEED (
    p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE,
    p_distribution_qty IN OUT NUMBER,
    p_standard_pack_qty IN NUMBER,
    p_case_pack_qty IN NUMBER,
    p_is_a_new_store IN CHAR,
    p_alloc_type IN VARCHAR2,
    p_allocation_id IN NUMBER,
    p_distro_type IN NUMBER,
    p_distro_num IN OUT NUMBER) IS

ln_Total_Rounded_Need NUMBER := 0;
lc_log_msg  CLOB := NULL;
jita_temp_tbl_type jita_temp_tbl_def;
BEGIN
  
  IF p_is_a_new_store = 'Y' THEN
    JITA_LOG_MSG(1, 'START NEW STORES NEED FILL:');
  ELSE
    JITA_LOG_MSG(1, 'START DYNAMIC NEED FILL:');
  END IF;
  JITA_LOG_MSG(1, 'Quantity available to distribute= ' || p_distribution_qty);
  
  IF gc_JITA_process_name <> G_PROCESS_NAME_100D THEN 
    COMP_NEED_AND_PCT (p_standard_pack_qty => p_standard_pack_qty,
    p_case_pack_qty => p_case_pack_qty);
  ELSE
    COMP_CUMULATIVE_NEEDS(p_inventory_item_id => p_inventory_item_id,
        p_standard_pack_qty =>  p_standard_pack_qty, 
        p_case_pack_qty => p_case_pack_qty );
  END IF;
  
  gc_module_name  := 'DYNAMIC_NEED';
  gc_error_loc := 'Get total rounded need ';
  gc_error_message := 'Select from XX_MER_JITA_TEMP failed: ';
  JITA_LOG_MSG(3, 'Get total rounded need');
  ln_Total_Rounded_Need := 0;
  SELECT SUM(rounded_need) INTO ln_Total_Rounded_Need FROM XX_MER_JITA_TEMP   
    WHERE new_store_flag = p_is_a_new_store
    AND rounded_need > 0;
  
  IF (ln_Total_Rounded_Need IS NULL) OR (ln_Total_Rounded_Need = 0 ) THEN
    RETURN;
  END IF;
  
  -- TO DO if total need is 0 then exit this function at least for new stores?
  JITA_LOG_MSG(5, 'total rounded_need=' || ln_Total_Rounded_Need);
  
  IF ln_Total_Rounded_Need <= p_distribution_qty THEN
    JITA_LOG_MSG(5, 'total rounded_need is less than qty to distribute');
    -- First allocate needed qty. If we used proportional need without 
    -- allocating required need, because of rounding it could be possible that 
    -- tail enders may not get the needed qty.
    
    -- insert records into XX_MER_JITA_DISTROS
    gc_module_name  := 'DYNAMIC_NEED';
    gc_error_loc := 'Get individual rounded need';
    gc_error_message := 'Bulk select from XX_MER_JITA_TEMP failed: ';
    JITA_LOG_MSG(3, 'Get individual rounded need');
    SELECT * BULK COLLECT INTO jita_temp_tbl_type
      FROM XX_MER_JITA_TEMP
      WHERE new_store_flag = p_is_a_new_store
      AND rounded_need > 0;
    FOR I in 1 .. jita_temp_tbl_type.COUNT
    LOOP
      /*gc_module_name  := 'DYNAMIC_NEED';
      gc_error_loc := 'Insert Distro ';
      gc_error_message := 'insert into XX_MER_JITA_DISTROS failed: ';
      JITA_LOG_MSG(5, 'insert into XX_MER_JITA_DISTROS');
      INSERT INTO XX_MER_JITA_DISTROS(allocation_id, dest_location_id,
        alloc_qty, alloc_type, distro_num, distro_type)
        VALUES(p_allocation_id, jita_temp_tbl_type(I).location_id, 
          jita_temp_tbl_type(I).rounded_need, 
          p_alloc_type, p_distro_num, p_distro_type);*/
      lc_log_msg := lc_log_msg || RPAD(jita_temp_tbl_type(I).organization_id,10) 
          || RPAD(NVL(jita_temp_tbl_type(I).sellable_on_hand,0), 10)
          || RPAD(NVL(jita_temp_tbl_type(I).prior_allocation_qty, 0), 10)
          || RPAD(NVL(jita_temp_tbl_type(I).rutl, 0), 10) 
          || RPAD(NVL(jita_temp_tbl_type(I).need, 0), 10) 
          || RPAD(NVL(jita_temp_tbl_type(I).rounded_need, 0), 10) || GC_EOL;
      p_distro_num := p_distro_num + 1;
    END LOOP;
    
    gc_module_name  := 'DYNAMIC_NEED';
    gc_error_loc := 'Update Allocation ';
    gc_error_message := 'Update XX_MER_JITA_TEMP failed: ';
    JITA_LOG_MSG(5, 'Update XX_MER_JITA_TEMP');
    UPDATE XX_MER_JITA_TEMP 
        SET dynamic_qty = rounded_need,
          prior_allocation_qty = (prior_allocation_qty + rounded_need),
          allocation_qty = (allocation_qty + rounded_need)
        WHERE new_store_flag = p_is_a_new_store
        AND rounded_need > 0;
    
    p_distribution_qty := p_distribution_qty - ln_Total_Rounded_Need;
    
  ELSE
    JITA_LOG_MSG(5, 'total rounded_need is more than qty to distribute. Use
        need pct algorithm.');
    NEED_PCT_ALLOC ( p_standard_pack_qty => p_standard_pack_qty, 
        p_case_pack_qty => p_case_pack_qty,  
        p_is_a_new_store => p_is_a_new_store, 
        p_alloc_type => p_alloc_type, 
        p_allocation_id => p_allocation_id, 
        p_distro_type => p_distro_type,
        p_is_alloc_excess => false,
        p_distro_num => p_distro_num, 
        p_distribution_qty => p_distribution_qty );
  END IF;
  
  IF lc_log_msg IS NOT NULL THEN
    lc_log_msg := GC_EOL || RPAD('Location',10) || RPAD('SOH',10) 
      || RPAD('PrevAlloc', 10) || RPAD('RUTL', 10) || RPAD('Need', 10) 
      || RPAD('Allocated', 10) || GC_EOL ||
      lc_log_msg;
    JITA_LOG_MSG(1, lc_log_msg);
  END IF;
  IF p_is_a_new_store = 'Y' THEN
    JITA_LOG_MSG(1, 'END NEW STORES NEED FILL:');    
  ELSE
    JITA_LOG_MSG(1, 'END DYNAMIC NEED FILL:');
  END IF;
  
END DYNAMIC_NEED;


PROCEDURE ALLOC_EXCESS (p_distribution_qty IN OUT NUMBER,
    p_standard_pack_qty IN NUMBER,
    p_case_pack_qty IN NUMBER) IS
  ln_total_need NUMBER;
  ln_need NUMBER;
  ln_pack_qty NUMBER;
  ln_tmp_num  NUMBER;
  ln_alloc_qty NUMBER;
  ln_rnd_alloc_qty NUMBER;
  ln_Excess_qty  NUMBER;
  lc_log_msg  CLOB := NULL;
      
  jita_temp_tbl_type jita_temp_tbl_def;
  org_id_tbl_type org_id_tbl_def := org_id_tbl_def();
BEGIN
  -- TO DO Albertson specific stuff. 
  JITA_LOG_MSG(1, 'START ALLOC EXCESS:');
  JITA_LOG_MSG(1, 'Quantity available to distribute= ' || p_distribution_qty);
  
  -- TO DO insert records into jita_distros table -- Not needed

  gc_module_name  := 'ALLOC_EXCESS';
  gc_error_loc := 'Get total need ';
  gc_error_message := 'Select from XX_MER_JITA_TEMP failed: ';
  JITA_LOG_MSG(3, 'Get total need');
  SELECT NVL(SUM(rutl) - SUM(sellable_on_hand) - SUM(in_transit_qty) , 0)
  INTO ln_Total_Need
  FROM XX_MER_JITA_TEMP;
  
  ln_Excess_qty := p_distribution_qty;
  JITA_LOG_MSG(5, 'Total need = ' || ln_Total_Need);
  
  gc_module_name  := 'ALLOC_EXCESS';
  gc_error_loc := 'Get individual need and pct';
  gc_error_message := 'Select from XX_MER_JITA_TEMP failed: ';
  JITA_LOG_MSG(3, 'Get individual need and pct');
  SELECT * BULK COLLECT INTO jita_temp_tbl_type
    FROM XX_MER_JITA_TEMP
    ORDER BY Avg_rate_of_sale desc; 
      
  FOR i in 1 .. jita_temp_tbl_type.COUNT 
  LOOP
    IF (p_distribution_qty <= 0) THEN
      EXIT;
    END IF;
    
    gc_error_message := 'Computations for need pct failed: ';
    IF (i <> jita_temp_tbl_type.COUNT) THEN
      ln_need := jita_temp_tbl_type(i).rutl 
           - jita_temp_tbl_type(i).sellable_on_hand
           - jita_temp_tbl_type(i).in_transit_qty;
      ln_alloc_qty := (ln_need /ln_Total_Need) * ln_Excess_qty;
      -- Now do the rounding
      ln_rnd_alloc_qty := ROUND_QTY(
          p_raw_qty => ln_alloc_qty, 
          p_store_type => jita_temp_tbl_type(i).store_type,
          p_standard_pack_qty => p_standard_pack_qty,
          p_case_pack_qty => p_case_pack_qty);
      JITA_LOG_MSG(5, 'need=' || ln_need);
    END IF;
    
    IF (i = jita_temp_tbl_type.COUNT)
       OR (ln_rnd_alloc_qty > p_distribution_qty) THEN
      IF jita_temp_tbl_type(1).store_type = G_STORE_TYPE_NON_TRADITIONAL THEN
        ln_rnd_alloc_qty := trunc(p_distribution_qty/p_case_pack_qty) 
                                    * p_case_pack_qty;
      ELSE
        ln_rnd_alloc_qty := p_distribution_qty;
      END IF;
    END IF;
    JITA_LOG_MSG(5, 'RndAllocQty=' || ln_rnd_alloc_qty);
    
    p_distribution_qty := p_distribution_qty - ln_rnd_alloc_qty;
    lc_log_msg := lc_log_msg || RPAD(jita_temp_tbl_type(i).organization_id,10) 
        || RPAD(NVL(jita_temp_tbl_type(i).sellable_on_hand, 0), 10)
        || RPAD(NVL(jita_temp_tbl_type(i).prior_allocation_qty,0), 10)
        || RPAD(NVL(jita_temp_tbl_type(i).rutl, 0), 10) 
        || RPAD(NVL(ln_need,0), 10) 
        || RPAD(NVL(ln_rnd_alloc_qty,0), 10) || GC_EOL;
      
    jita_temp_tbl_type(i).dynamic_qty := 
      jita_temp_tbl_type(i).dynamic_qty + ln_rnd_alloc_qty; 
    jita_temp_tbl_type(i).prior_allocation_qty := 
      jita_temp_tbl_type(i).prior_allocation_qty 
      + ln_rnd_alloc_qty; 
    jita_temp_tbl_type(i).allocation_qty := 
      jita_temp_tbl_type(i).allocation_qty 
      + ln_rnd_alloc_qty; 
    
    gc_module_name  := 'ALLOC_EXCESS';
    gc_error_loc := 'Update Allocation ';
    gc_error_message := 'Update XX_MER_JITA_TEMP failed: ';
    JITA_LOG_MSG(5, 'Update XX_MER_JITA_TEMP');
    --TO DO use bulk update
    UPDATE XX_MER_JITA_TEMP SET ROW = jita_temp_tbl_type(i)
        WHERE organization_id = jita_temp_tbl_type(i).organization_id;    
  END LOOP;    
  
  IF lc_log_msg IS NOT NULL THEN
    lc_log_msg := GC_EOL || RPAD('Location',10) || RPAD('SOH',10) 
      || RPAD('PrevAlloc', 10) || RPAD('RUTL', 10) || RPAD('Need', 10) 
      || RPAD('Allocated', 10) || GC_EOL ||
      lc_log_msg;
    JITA_LOG_MSG(1, lc_log_msg);
  END IF;
  JITA_LOG_MSG(1, 'END ALLOC EXCESS:');
  
END ALLOC_EXCESS;

PROCEDURE JITA_ENGINE (
  p_ASN IN rcv_shipment_headers.shipment_num%TYPE,
  p_po_num IN  po_headers_all.segment1%TYPE,
  p_line_num       po_lines_all.line_num%TYPE,
  p_po_shipment_num   po_line_locations_all.shipment_num%TYPE,
  p_sku IN mtl_system_items_b.segment1%TYPE,
  p_org_id hr_all_organization_units.organization_id%TYPE,
  p_received_qty IN rcv_shipment_lines.quantity_shipped%TYPE,
  p_po_header_id   po_headers_all.po_header_id%TYPE,
  p_po_line_id     po_lines_all.po_line_id%TYPE,
  p_po_line_location_id    po_lines_all.po_line_id%TYPE,
  p_inventory_item_id mtl_system_items_b.inventory_item_id%TYPE,
  p_is_overage IN BOOLEAN ) IS
  
  --  lc_stock_indicator xx_inv_item_master_attributes.handling_temp%TYPE; -- TO DO use the actual column
  lc_stock_indicator xx_inv_item_master_attributes.HANDLING_SENSITIVITY%TYPE;

  ln_distribution_qty NUMBER; -- TO DO size is TBD
  lc_allocation_code XX_MER_JITA_ALLOC_PRIORITY.allocation_code%TYPE;
  ln_allocation_key NUMBER := 0;
  ln_distro_num NUMBER := 0;
  ln_distro_type NUMBER := 3;
  lb_is_jita_online BOOLEAN;
  ln_standard_pack_qty NUMBER := 0;
  ln_case_pack_qty NUMBER := 0;
  ln_vendor_id po_approved_supplier_list.vendor_id%TYPE := 0;
  ln_vendor_site_id po_approved_supplier_list.vendor_site_id%TYPE := 0;  
  ln_count NUMBER := 0;
BEGIN
  
  JITA_LOG_MSG(1, 'Start JITA Engine');
  JITA_LOG_MSG(1, 'Input parameters are ASN= ' || p_ASN || ' PO= ' || 
    p_po_num || ' SKU= ' ||  p_SKU || ' Location= ' || p_ORG_ID ||
    ' Qty= ' ||  p_received_qty || ' p_po_header_id= ' ||  p_po_header_id 
    || ' p_po_line_id= ' || p_po_line_id ||
    ' p_po_line_location_id = ' ||  p_po_line_location_id );
  IF p_is_overage THEN
    JITA_LOG_MSG(1, 'Input param : Overage flag is true');
  ELSE
    JITA_LOG_MSG(1, 'Input param : Overage flag is false');
  END IF;

  lb_is_jita_online := (gc_JITA_process_name = 'ONLINE');
  --Check that input parameters are not abnormal.
  gc_module_name  := 'JITA_ENGINE'; 
  gc_error_loc := 'Input parameters check';  
  gc_error_message := 'Invalid input parameters: ';
  JITA_LOG_MSG(3, gc_error_loc);
  IF (lb_is_jita_online AND ( (p_ASN IS NULL) OR (p_ASN = '') OR 
        (p_po_header_id IS NULL) or (p_po_header_id = 0)  OR
        (p_po_line_id IS NULL) or (p_po_line_id = 0)  OR
        (p_po_line_location_id IS NULL) or (p_po_line_location_id = 0) ))   OR 
     (p_sku IS NULL) or (p_sku = '') OR 
     (p_ORG_ID IS NULL) or (p_ORG_ID = 0) OR 
     (p_received_qty IS NULL) or (p_received_qty = 0) THEN
          JITA_LOG_MSG(3, 'Invalid input parameters.');
          raise INVALID_INPUT;
  ELSE
    JITA_LOG_MSG(3, 'Input parameters are OK.');
  END IF;  

  lc_stock_indicator := 'STOCKLESS';
  lc_stock_indicator := GET_STOCK_INDICATOR
    ( p_inventory_item_id => p_inventory_item_id, 
      p_org_id => p_ORG_ID );
  JITA_LOG_MSG(5, 'stock indicator= ' || lc_stock_indicator);
  IF (p_is_overage) AND (lc_stock_indicator = 'STOCKED') THEN
    JITA_LOG_MSG(3, 'No need to create overage distros for stocked product!');
    JITA_LOG_MSG(1, 'End JITA Engine');
    RETURN;
  END IF;

  -- TO DO use constants for all literals  
  
  gc_module_name  := 'JITA_ENGINE'; 
  gc_error_loc := 'Get Allocation Key';  
  IF p_is_overage THEN
    JITA_LOG_MSG(3, 'Get Allocation Key: overgae flag is true');
    gc_error_message := 'Select from XX_MER_JITA_ALLOC_HEADER failed: ';
    JITA_LOG_MSG(5, 'Select from XX_MER_JITA_ALLOC_HEADER');
    SELECT allocation_id INTO ln_allocation_key
    FROM XX_MER_JITA_ALLOC_HEADER
    WHERE asn= p_asn
    AND po_header_id = p_po_header_id
    AND po_line_id = p_po_line_id
    AND line_location_id = p_po_line_location_id
    AND inventory_item_id = p_inventory_item_id
    AND organization_id = p_org_id;
    
    ln_distro_num := G_OVERAGE_START_DISTRO_NUM;
    ln_distro_type := G_DISTRO_TYPE_OVERAGE;
    
    gc_error_message := 'Delete from XX_MER_JITA_TEMP: ';
    JITA_LOG_MSG(5, 'Delete from XX_MER_JITA_TEMP');
    DELETE XX_MER_JITA_TEMP;
  ELSE
    JITA_LOG_MSG(3, 'Get Allocation Key: overage flag is false');
    gc_error_message := 'Get next sequence number from XX_MER_JITA_ALLOC_HEADER_S failed: ';
    JITA_LOG_MSG(5, 'Get next sequence number from XX_MER_JITA_ALLOC_HEADER_S');
    SELECT xx_mer_jita_alloc_header_s.nextval INTO ln_allocation_key FROM dual;
    
    ln_distro_num := 1;
    ln_distro_type := G_DISTRO_TYPE_FLOWTHRU; -- TO DO do we have a separte type for batch?
    
    gc_error_message := 'Insert into XX_MER_JITA_ALLOC_HEADER failed: ';
    JITA_LOG_MSG(5, 'Insert into XX_MER_JITA_ALLOC_HEADER');
    INSERT INTO xx_mer_jita_alloc_header(
        allocation_id
        , process_name
        , asn
        , po_num
        , po_line_num
        , po_shipment_num
        , po_header_id
        , po_line_id
        , line_location_id
        , sku
        , inventory_item_id
        , organization_id
        , received_qty
        , last_update_login
        , last_update_date
        , last_updated_by
        , creation_date
        , created_by)
      VALUES (
        ln_allocation_key
        , gc_JITA_process_name
        , p_ASN
        , p_po_num
        , p_line_num
        , p_po_shipment_num
        , p_po_header_id
        , p_po_line_id
        , p_po_line_location_id
        , p_sku
        , p_inventory_item_id
        , p_org_id
        , p_received_qty
        , FND_GLOBAL.LOGIN_ID
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , SYSDATE 
        , FND_GLOBAL.USER_ID 
      );
    
    gc_error_message := 'Delete from XX_MER_JITA_TEMP: ';
    JITA_LOG_MSG(5, 'Delete from XX_MER_JITA_TEMP');
    DELETE XX_MER_JITA_TEMP;
  END IF;

  JITA_LOG_MSG(5, 'Allocation_key=' || ln_allocation_key);
  
  -- TO DO If it is RTV SKU we have to put away all the product. 
  /*IF JITA_IS_RTV_SKU(p_sku) THEN
  Insert a record into XXMER_JITA_ALLOC
  No need to send distro as all qty is putaway
  Finish logging
  EXIT function
  END IF*/
  
  IF NOT lb_is_jita_online THEN
    DELETE FROM XX_MER_JITA_TEMP;
  END IF;
  
  GET_SOURCE_INFO(p_inventory_item_id =>  p_inventory_item_id, 
    p_org_id  =>  p_org_id,
    p_stock_type  =>  lc_stock_indicator);
   -- Above procedure gets a list of stores and populates the 
   -- global temporary table JITA_TEMP

  -- for JITA batch if there are no stores to serve for that SKU exit
  IF NOT lb_is_jita_online THEN
    SELECT count(*) INTO ln_count FROM XX_MER_JITA_TEMP ;
    IF ln_count <= 0 THEN
      RETURN;
    END IF;
  END IF;

  FILL_INVENTORY_DATA (p_inventory_item_id);
  -- Above procedure reads from the global temp table and 
  -- updates inventory columns

  FILL_CAN_RECEIVE (p_org_id => p_org_id, 
       p_stock_indicator => lc_stock_indicator);
  -- above procedure updates the can_receive in the temp table
  
  FILL_PREV_ALLOC_BUC(p_inventory_item_id  => p_inventory_item_id);
  -- above procedure updates the prev_alloc qty in the temp table
          
  ln_distribution_qty := p_received_qty;

  GET_PACK_SIZE_INFO ( p_inventory_item_id => p_inventory_item_id,
    p_org_id => p_org_id,
    p_po_header_id => p_po_header_id,
    p_standard_pack_qty => ln_standard_pack_qty,
    p_case_pack_qty => ln_case_pack_qty,
    p_vendor_id => ln_vendor_id, 
    p_vendor_site_id => ln_vendor_site_id);

  JITA_LOG_MSG(3, 'Standard packsize= ' || ln_standard_pack_qty);
  JITA_LOG_MSG(3, 'Case packsize= ' || ln_case_pack_qty);
  JITA_LOG_MSG(3, 'Vendor Id= ' || ln_vendor_id);
  JITA_LOG_MSG(3, 'Vendor site Id= ' || ln_vendor_site_id);


  --IF gc_JITA_process_name <> G_PROCESS_NAME_100D THEN -- TO DO use constant for literals
    COMP_NEED_AND_PCT (p_standard_pack_qty => ln_standard_pack_qty,
        p_case_pack_qty => ln_case_pack_qty);
  /*ELSE
    COMP_CUMULATIVE_NEEDS(p_inventory_item_id => p_inventory_item_id,
        p_standard_pack_qty =>  ln_standard_pack_qty, 
        p_case_pack_qty => ln_case_pack_qty );
  END IF;*/
  
  -- Query XXMER_JITA_ALLOC_PRIORITY table and loop through the priority scheme. 
  -- After each step ln_distribution_qty will be reduced. 
  -- if ln_distribution_qty becomes 0 then don't call any more allocation routines. 

  gc_module_name  := 'JITA_ENGINE'; 
  gc_error_loc := 'Determine Allocation Priority';
  gc_error_message := 'Open Cursor lcu_JITA_priority Failed: ';
  JITA_LOG_MSG(3, gc_error_loc);
  OPEN lcu_JITA_priority;
  LOOP
    gc_module_name  := 'JITA_ENGINE'; 
    gc_error_loc := 'Determine Allocation Priority';
    gc_error_message := 'Fetch from Cursor lcu_JITA_priority Failed: ';
    FETCH lcu_JITA_priority INTO lc_allocation_code;
    EXIT WHEN lcu_JITA_priority%NOTFOUND;
    
    IF ln_distribution_qty <= 0 THEN
      EXIT;
    END IF;

	    	
    CASE lc_allocation_code
      WHEN G_ALLOC_CODE_LOCK THEN
        LOCKIN_ALLOC(p_inventory_item_id => p_inventory_item_id, 
            p_org_id => p_org_id,
            p_po_header_id  => p_po_header_id, 
            p_po_line_id => p_po_line_id,
            p_po_line_location_id => p_po_line_location_id,
            p_standard_pack_qty  => ln_standard_pack_qty, 
            p_case_pack_qty  => ln_case_pack_qty, 
            p_lockin_type  => G_ALLOC_CODE_LOCK, 
            p_allocation_id  => ln_allocation_key,
            p_distro_type  => ln_distro_type, 
            p_distribution_qty  => ln_distribution_qty, 
            p_distro_num  => ln_distro_num);
      WHEN G_ALLOC_CODE_ATP_SL THEN
        LOCKIN_ALLOC(p_inventory_item_id => p_inventory_item_id, 
            p_org_id => p_org_id,
            p_po_header_id  => p_po_header_id, 
            p_po_line_id => p_po_line_id,
            p_po_line_location_id => p_po_line_location_id,
            p_standard_pack_qty  => ln_standard_pack_qty, 
            p_case_pack_qty  => ln_case_pack_qty, 
            p_lockin_type  => G_ALLOC_CODE_ATP_SL, 
            p_allocation_id  => ln_allocation_key,
            p_distro_type  => ln_distro_type, 
            p_distribution_qty  => ln_distribution_qty, 
            p_distro_num  => ln_distro_num);
      WHEN G_ALLOC_CODE_NS_BOTTOM THEN
        BOTTOM_FILL (p_distribution_qty => ln_distribution_qty, 
          p_standard_pack_qty => ln_standard_pack_qty,
          p_case_pack_qty  => ln_case_pack_qty, 
          p_is_a_new_store => 'Y',
          p_alloc_type => lc_allocation_code, 
          p_allocation_id => ln_allocation_key, 
          p_distro_type => ln_distro_type,
          p_distro_num => ln_distro_num);
      WHEN G_ALLOC_CODE_NS_NEED THEN
        DYNAMIC_NEED (p_inventory_item_id => p_inventory_item_id,
            p_distribution_qty => ln_distribution_qty,
            p_standard_pack_qty => ln_standard_pack_qty,
            p_case_pack_qty => ln_case_pack_qty,
            p_is_a_new_store => 'Y', 
            p_alloc_type => lc_allocation_code,
            p_allocation_id => ln_allocation_key,
            p_distro_type => ln_distro_type,
            p_distro_num => ln_distro_num);

      WHEN G_ALLOC_CODE_ATP THEN
        LOCKIN_ALLOC(p_inventory_item_id => p_inventory_item_id, 
            p_org_id => p_org_id,
            p_po_header_id  => p_po_header_id, 
            p_po_line_id => p_po_line_id,
            p_po_line_location_id => p_po_line_location_id,
            p_standard_pack_qty  => ln_standard_pack_qty, 
            p_case_pack_qty  => ln_case_pack_qty, 
            p_lockin_type  => G_ALLOC_CODE_ATP, 
            p_allocation_id  => ln_allocation_key,
            p_distro_type  => ln_distro_type, 
            p_distribution_qty  => ln_distribution_qty, 
            p_distro_num  => ln_distro_num);
      WHEN G_ALLOC_CODE_OUTS THEN
        BOTTOM_FILL (p_distribution_qty => ln_distribution_qty, 
          p_standard_pack_qty => ln_standard_pack_qty,
          p_case_pack_qty  => ln_case_pack_qty, 
          p_is_a_new_store => 'N',
          p_alloc_type => lc_allocation_code, 
          p_allocation_id => ln_allocation_key, 
          p_distro_type => ln_distro_type,
          p_distro_num => ln_distro_num);
      WHEN G_ALLOC_CODE_NEED THEN
        DYNAMIC_NEED (p_inventory_item_id => p_inventory_item_id,
            p_distribution_qty => ln_distribution_qty,
            p_standard_pack_qty => ln_standard_pack_qty,
            p_case_pack_qty => ln_case_pack_qty,
            p_is_a_new_store => 'N', 
            p_alloc_type => lc_allocation_code,
            p_allocation_id => ln_allocation_key,
            p_distro_type => ln_distro_type,
            p_distro_num => ln_distro_num);

      --BACK_ORDER_ALLOC(ln_distribution_qty) 
      --According to marc warehouse backorders are now ATP orders, 
      -- so no need to worry about this.
    ELSE
      --TO DO Error
      JITA_LOG_MSG(1, 'Error. Invalid allocation type');
    END CASE;    
  END LOOP;
  gc_module_name  := 'JITA_ENGINE'; 
  gc_error_loc := 'Determine Allocation Priority';
  gc_error_message := 'Close Cursor lcu_JITA_priority Failed: ';
  CLOSE lcu_JITA_priority;

   
    
  -- Handle exceptional cases like BRI_07
  --JITA_BR07_ALLOCATIONS TO DO

  IF lb_is_jita_online THEN
    -- TO DO combo center logic
    --For flow through items distribute product else it is putaway
    JITA_LOG_MSG(5, 'stockind=' || lc_stock_indicator);
    JITA_LOG_MSG(5, 'distribution_qty=' || ln_distribution_qty);
    IF ln_distribution_qty > 0 THEN
      IF lc_stock_indicator = 'STOCKLESS' THEN -- TO DO use string literal
        JITA_LOG_MSG(1, 'enough left after filling all need. alloc excess 
                   for stockless');
        COMP_NEED_AND_PCT (p_standard_pack_qty => ln_standard_pack_qty,
          p_case_pack_qty => ln_case_pack_qty);
        NEED_PCT_ALLOC ( p_standard_pack_qty => ln_standard_pack_qty, 
          p_case_pack_qty => ln_case_pack_qty,  
          p_is_a_new_store => 'N', 
          p_alloc_type => lc_allocation_code, 
          p_allocation_id => ln_allocation_key,
          p_distro_type => ln_distro_type,
          p_is_alloc_excess => true,
          p_distro_num => ln_distro_num,
          p_distribution_qty => ln_distribution_qty );
      ELSE
        JITA_LOG_MSG(1, 'enough left after filling all need. put away for stocked');
        gc_module_name  := 'JITA_ENGINE'; 
        gc_error_loc := 'Insert put away quantity';
        gc_error_message := 'Insert into  XX_MER_JITA_TEMP Failed: ';
        JITA_LOG_MSG(5, 'Insert into XX_MER_JITA_TEMP');
        INSERT INTO XX_MER_JITA_TEMP (organization_id, Store_type, New_store_flag,
        Sellable_on_hand, RUTL, In_transit_qty, Avg_rate_of_sale,
        Need, Rounded_Need, need_pct, Prior_allocation_qty,prior_lockin_qty, 
        prior_seasonal_lrg_qty, prior_atp_cust_order_qty, allocation_qty,
        Lockin_alloc_qty, Seasonal_lrg_ord_qty, bottom_fill_qty, 
        ATP_customer_order_qty, dynamic_qty, can_receive, overage_qty)
        VALUES(p_org_id, 'RG', 'N',
        0, 0, 0, 0,
        0,0,0,0,0,
        0,0,ln_distribution_qty,
        0,0,0,
        0,0, 1, 0);
      END IF;
    END IF;
  END IF;

  --Insert records into XXMER_JITA_ALLOC table
  -- TO DO take out hard coding
  --  TO DO use dynamic SQL statement i.e, execute immediate
  IF p_is_overage THEN
    gc_module_name  := 'JITA_ENGINE'; 
    gc_error_loc := 'Insert Allocation Results ';
    gc_error_message := 'Insert into XX_MER_JITA_ALLOC_OVERAGE Failed: ';
    JITA_LOG_MSG(1, 'Insert Allocation Results for overage');
    insert into XX_MER_JITA_ALLOC_OVERAGE
      (Allocation_id, dest_organization_id, Store_type, New_store_flag, 
      replen_type_code, replen_subtype_code, warehouse_item_code,
      Allocation_qty, wmos_shipped_qty, Dynamic_qty, 
      Lockin_alloc_qty, Seasonal_lrg_ord_qty, bottom_fill_qty, 
      ATP_customer_order_qty, RUTL, Sellable_on_hand, In_transit_qty, 
      Avg_rate_of_sale, distro_type)
      select ln_allocation_key, organization_id, Store_type, New_store_flag, 
      replen_type_code, replen_subtype_code, warehouse_item_code,
      allocation_qty, allocation_qty, dynamic_qty, 
      Lockin_alloc_qty, Seasonal_lrg_ord_qty, bottom_fill_qty, 
      ATP_customer_order_qty, RUTL, Sellable_on_hand, In_transit_qty, 
      Avg_rate_of_sale, ln_distro_type
      from XX_MER_JITA_TEMP where allocation_qty > 0
      and can_receive > 0;
  ELSE
    gc_module_name  := 'JITA_ENGINE'; 
    gc_error_loc := 'Insert Allocation Results ';
    gc_error_message := 'Insert into XX_MER_JITA_ALLOC_DTLS Failed: ';
    JITA_LOG_MSG(1, 'Insert Allocation Results');
    insert into XX_MER_JITA_ALLOC_DTLS
      (Allocation_id, dest_organization_id, Store_type, New_store_flag, 
      replen_type_code, replen_subtype_code, warehouse_item_code,
      Allocation_qty, wmos_shipped_qty, dynamic_qty, 
      Lockin_alloc_qty, Seasonal_lrg_ord_qty, bottom_fill_qty, 
      ATP_customer_order_qty, RUTL, Sellable_on_hand, In_transit_qty, 
      Avg_rate_of_sale, distro_type, last_update_login
      , last_update_date, last_updated_by, creation_date, created_by)
      select ln_allocation_key, organization_id, Store_type, New_store_flag, 
      replen_type_code, replen_subtype_code, warehouse_item_code,
      allocation_qty, allocation_qty, dynamic_qty, 
      Lockin_alloc_qty, Seasonal_lrg_ord_qty, bottom_fill_qty, 
      ATP_customer_order_qty, RUTL, Sellable_on_hand, In_transit_qty, 
      Avg_rate_of_sale, ln_distro_type, FND_GLOBAL.LOGIN_ID
      , SYSDATE, FND_GLOBAL.USER_ID, SYSDATE , FND_GLOBAL.USER_ID 
      from XX_MER_JITA_TEMP where allocation_qty > 0
      and can_receive > 0
      order by (rutl - sellable_on_hand - in_transit_qty) desc;    
  END IF;  
  
  -- End log

  -- TO DO error handling and logging
  JITA_LOG_MSG(1, 'End JITA Engine');
END JITA_ENGINE;

PROCEDURE ALLOCATE_ASN ( p_ASN IN rcv_shipment_headers.shipment_num%TYPE,
      p_ORG_ID IN hr_all_organization_units.organization_id%TYPE  ) IS
--lc_org_id         mtl_system_items_b.organization_id%TYPE;
lc_PO             po_headers_all.segment1%TYPE;
lc_line_num       po_lines_all.line_num%TYPE;
lc_po_shipment_num   po_line_locations_all.shipment_num%TYPE;
lc_SKU            mtl_system_items_b.segment1%TYPE;
ln_inventory_item_id mtl_system_items_b.inventory_item_id%TYPE;
ln_Quantity       rcv_shipment_lines.quantity_shipped%TYPE;
ln_po_header_id   po_headers_all.po_header_id%TYPE;
ln_po_line_id     po_lines_all.po_line_id%TYPE;
ln_po_line_location_id    po_lines_all.po_line_id%TYPE;
ln_Overage_Quantity       rcv_shipment_lines.quantity_shipped%TYPE;

BEGIN

JITA_LOG_MSG(1, 'Start procedure ALLOCATE_ASN ');
JITA_LOG_MSG(1, 'Input parameters are ASN= ' || p_ASN );

-- TO DO if ASN doesn't exist throw error

  JITA_LOG_MSG(3, 'Query to get ASN details');
  OPEN lcu_ASN_Details (p_ASN, p_ORG_ID);
  LOOP      
      FETCH lcu_ASN_Details  INTO lc_PO, lc_SKU, lc_line_num,
        lc_po_shipment_num, ln_Quantity, ln_inventory_item_id, ln_po_header_id, 
        ln_po_line_id, ln_po_line_location_id;
      EXIT WHEN lcu_ASN_Details%NOTFOUND;
     
     JITA_ENGINE (
        p_ASN => p_ASN
        , p_po_num => lc_PO
        , p_line_num => lc_line_num
        , p_po_shipment_num => lc_po_shipment_num
        , p_sku => lc_SKU
        , p_ORG_ID => p_org_id
        , p_received_qty => ln_Quantity * 10 -- TO DO remove hard coded multiplication
        , p_po_header_id => ln_po_header_id
        , p_po_line_id => ln_po_line_id
        , p_po_line_location_id => ln_po_line_location_id
        , p_inventory_item_id => ln_inventory_item_id
        , p_is_overage => FALSE) ;

    -- overage distros
    ln_Overage_Quantity := CEIL(ln_Quantity * gn_overage_threshold);    
    if (gn_overage_threshold > 0 ) THEN
      JITA_ENGINE (
        p_ASN => p_ASN
        , p_po_num => lc_PO
        , p_line_num => lc_line_num
        , p_po_shipment_num => lc_po_shipment_num
        , p_sku => lc_SKU
        , p_ORG_ID => p_org_id
        , p_received_qty => ln_Overage_Quantity
        , p_po_header_id => ln_po_header_id
        , p_po_line_id => ln_po_line_id
        , p_po_line_location_id => ln_po_line_location_id
        , p_inventory_item_id => ln_inventory_item_id
        , p_is_overage => TRUE) ;
    END IF;
  END LOOP;
  CLOSE lcu_ASN_Details;  

JITA_LOG_MSG(1, 'End procedure ALLOCATE_ASN ');
END ALLOCATE_ASN;

PROCEDURE JITA_PRECOMPUTE (
  ERRBUF  OUT NOCOPY VARCHAR2,
  RETCODE OUT NOCOPY VARCHAR2,
  p_ORG_ID IN hr_all_organization_units.organization_id%TYPE) IS
  
  lc_ASN            rcv_shipment_headers.shipment_num%TYPE;

BEGIN
  -- TO DO logging
  RETCODE := -1;
  ERRBUF  := 'JITA Precompute: Unknown Error';
  OPEN lcu_JITA_Appt;
  LOOP
    FETCH lcu_JITA_Appt INTO lc_ASN;
    EXIT WHEN lcu_JITA_Appt%NOTFOUND;
    dbms_output.put_line('ASN= ' || lc_ASN);    
    ALLOCATE_ASN(p_ASN => lc_ASN,
        p_org_id => p_org_id);
    
  END LOOP;
  CLOSE lcu_JITA_Appt;
  
  RETCODE := 0;
  ERRBUF  := 'JITA Precompute Ran Successfully';
END JITA_PRECOMPUTE;

PROCEDURE JITA_CLEANUP_ASN (
  p_ASN IN  xx_mer_jita_alloc_header.asn%TYPE,
  p_org_id IN hr_all_organization_units.organization_id%TYPE ) IS

BEGIN
  JITA_LOG_MSG(1, 'Start procedure JITA_CLEANUP_ASN ');

  gc_module_name  := 'JITA_CLEANUP_ASN';
  MASS_UPDATE_PO_ALLOC (
    p_ASN => p_ASN
    , p_org_id => p_org_id
    , p_bCleanupASN => true );

  gc_module_name  := 'JITA_CLEANUP_ASN';
  gc_error_loc := 'Cleanup Precomputed Allocations';
  gc_error_message := 'Delete from XX_MER_JITA_ALLOC_DTLS failed: ';
  JITA_LOG_MSG(5, 'Delete from XX_MER_JITA_ALLOC_DTLS');
  DELETE FROM XX_MER_JITA_ALLOC_DTLS
  WHERE allocation_id IN (SELECT allocation_id 
  FROM XX_MER_JITA_ALLOC_HEADER WHERE asn = p_ASN
  AND organization_id = p_org_id);
            
  /*gc_error_message := 'Delete from XX_MER_JITA_DISTROS failed: ';
  JITA_LOG_MSG(5, 'Delete from XX_MER_JITA_DISTROS');
  DELETE FROM XX_MER_JITA_DISTROS
  WHERE allocation_id IN (SELECT allocation_id 
  FROM XX_MER_JITA_ALLOC_HEADER WHERE asn = p_ASN
  AND organization_id = p_org_id);*/
      
  gc_error_message := 'Delete from XX_MER_JITA_ALLOC_OVERAGE failed: ';
  JITA_LOG_MSG(5, 'Delete from XX_MER_JITA_ALLOC_OVERAGE');
  DELETE FROM XX_MER_JITA_ALLOC_OVERAGE
  WHERE allocation_id IN (SELECT allocation_id 
  FROM XX_MER_JITA_ALLOC_HEADER WHERE asn = p_ASN
  AND organization_id = p_org_id);      
      
  gc_error_message := 'Delete from XX_MER_JITA_ALLOC_HEADER failed: ';
  JITA_LOG_MSG(5, 'Delete from XX_MER_JITA_ALLOC_HEADER');
  DELETE FROM XX_MER_JITA_ALLOC_HEADER
  WHERE asn = p_ASN
  AND organization_id = p_org_id;
 
  JITA_LOG_MSG(1, 'End procedure JITA_CLEANUP_ASN ');
END JITA_CLEANUP_ASN;

PROCEDURE JITA_GUARD_CHECKIN (
  p_ASN IN  VARCHAR2,
  p_threshold IN  NUMBER,
  p_org_id NUMBER,
  p_xml_out OUT NOCOPY CLOB) IS

  ln_allocation_key NUMBER := 0;
  ln_count NUMBER := 0;
  l_JITAAllocDate   Date := NULL;
  l_queryCtx  DBMS_XMLQuery.ctxType;
  
BEGIN
-- NOTE IF WMoS sends legacy location id instead of org_id then we have to
-- use xx_gi_comn_utils_pkg.get_ebs_organization_id(locid) API to get org_id 
  gc_JITA_process_name  := G_PROCESS_NAME_ONLINE; -- TO DO use string literals
  JITA_LOG_MSG(1, 'Start JITA Guard checkin');
  
  ln_allocation_key := 0;
  ln_count := 0;
  l_JITAAllocDate  := NULL;
  
  JITA_LOG_MSG(1, 'Input parameters are ASN= ' || p_ASN || ' threshold= ' || 
      p_threshold);
  JITA_LOG_MSG(3, 'Input parameters check');
  gc_module_name  := 'JITA_GUARD_CHECKIN';
  gc_error_loc := 'Input parameters check';
  gc_error_message := 'Invalid input parameters: ';
  IF (p_ASN IS NULL) or (p_ASN= '') 
    or (p_threshold IS NULL) or (p_threshold = 0) 
    or (p_org_id IS NULL) or (p_org_id = 0) THEN
    JITA_LOG_MSG(3, 'Invalid input parameters');
    raise INVALID_INPUT;
  ELSE
    JITA_LOG_MSG(3, 'Input parameters are OK');
  END IF;  
  
  -- Get config parameters
  INITIALIZE_CONFIG_PARAMS;
    
  JITA_LOG_MSG(3, 'Check Precomputed Allocations');
  gc_module_name  := 'JITA_GUARD_CHECKIN';
  gc_error_loc := 'Check Precomputed Allocations';
  gc_error_message := 'Open Cursor lcu_JITA_Alloc Failed: ';  
  OPEN lcu_JITA_Alloc (p_ASN);
  gc_module_name  := 'JITA_GUARD_CHECKIN';
  gc_error_loc := 'Check Precomputed Allocations';
  gc_error_message := 'Fetch from Cursor lcu_JITA_Alloc Failed: ';
  FETCH lcu_JITA_Alloc INTO l_JITAAllocDate;
  IF lcu_JITA_Alloc%NOTFOUND THEN
    JITA_LOG_MSG(3, 'no precomputed allocations. compute allocations:');
    ALLOCATE_ASN(p_ASN => p_ASN, p_org_id => p_org_id);
    JITA_LOG_MSG(3, 'Allocations are computed!');
  ELSE
    JITA_LOG_MSG(5, 'l_JITAAllocDate=' || to_char(l_JITAAllocDate, 'mm/dd/yyyy hh24:mi:ss'));
    IF l_JITAAllocDate + (p_threshold/1440.0) < sysdate THEN
      JITA_LOG_MSG(3, 'precomputed allocations are stale. Cleanup allocations');      
      JITA_CLEANUP_ASN (
        p_ASN => p_ASN,
        p_org_id => p_org_id);      
      
      JITA_LOG_MSG(3, 'Prior allocations cleaned up. Compute fresh allocations');
      ALLOCATE_ASN(p_ASN => p_ASN, p_org_id =>p_org_id);
      JITA_LOG_MSG(3, 'Allocations are computed!');
    ELSE
      JITA_LOG_MSG(3, 'Pre computed allocations are valid!');
    END IF;
  END IF;
  gc_module_name  := 'JITA_GUARD_CHECKIN';
  gc_error_loc := 'Check Precomputed Allocations';
  gc_error_message := 'Close Cursor lcu_JITA_Alloc Failed: ';
  CLOSE lcu_JITA_Alloc;  

  
  -- Confirmation Distro
  JITA_LOG_MSG(3, 'Create Confirmation Distro:');
  gc_module_name  := 'JITA_GUARD_CHECKIN';
  gc_error_loc := 'Confirmation Distro';
  ln_count := 0;
  gc_module_name  := 'JITA_GUARD_CHECKIN';
  gc_error_loc := 'Check Precomputed Allocations';
  gc_error_message := 'Query to XX_MER_JITA_ALLOC_HEADER failed: ';
  JITA_LOG_MSG(5, 'Query to XX_MER_JITA_ALLOC_HEADER for count*');
  SELECT count(*) INTO ln_count FROM XX_MER_JITA_ALLOC_HEADER
      WHERE ASN=p_ASN AND received_qty = 0 and po_num = p_ASN AND sku = p_ASN;
  IF ln_count = 0  THEN
    gc_module_name  := 'JITA_GUARD_CHECKIN';
    gc_error_loc := 'Confirmation Distro';
    gc_error_message := 'Get next sequence number from XX_MER_JITA_ALLOC_HEADER_S failed: ';
    JITA_LOG_MSG(5, 'Get next value from sequence XX_MER_JITA_ALLOC_HEADER_S');
    SELECT XX_MER_JITA_ALLOC_HEADER_S.nextval INTO ln_allocation_key FROM dual;
    
    gc_error_message := 'Insert into XX_MER_JITA_ALLOC_HEADER failed: ';
    JITA_LOG_MSG(5, 'Insert into XX_MER_JITA_ALLOC_HEADER');
    INSERT INTO xx_mer_jita_alloc_header(
        allocation_id
        , process_name
        , asn
        , po_num
        , sku
        , received_qty
        , last_update_login
        , last_update_date
        , last_updated_by
        , creation_date
        , created_by)
      VALUES (
        ln_allocation_key
        , gc_JITA_process_name
        , p_ASN
        , p_ASN
        , p_ASN
        , 0
        , FND_GLOBAL.LOGIN_ID
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , SYSDATE 
        , FND_GLOBAL.USER_ID 
      );
    
    
    /*gc_error_message := 'Insert into XX_MER_JITA_DISTROS failed: ';
    JITA_LOG_MSG(5, 'Insert into XX_MER_JITA_DISTROS');
    INSERT INTO XX_MER_JITA_DISTROS(allocation_id, dest_location_id,
      alloc_qty, alloc_type, distro_num, distro_type)
      VALUES(ln_allocation_key, p_asn, 
      0, G_ALLOC_CODE_CONFIRM, 1, G_DISTRO_TYPE_CONFIRM);*
      gc_module_name  := 'JITA_GUARD_CHECKIN'; 
      gc_error_loc := 'Insert confirmation distro ';
      gc_error_message := 'Insert into XX_MER_JITA_ALLOC_OVERAGE Failed: ';
      JITA_LOG_MSG(1, 'Insert Allocation Results for confirmation distro');
      insert into XX_MER_JITA_ALLOC_OVERAGE
        (Allocation_id, dest_organization_id, Store_type, New_store_flag, 
        Allocation_qty, wmos_shipped_qty, Dynamic_alloc_qty, 
        Lockin_alloc_qty, Seasonal_lrg_ord_qty, bottom_fill_qty, 
        ATP_customer_order_qty, RUTL, Sellable_on_hand, In_transit_qty, 
        Avg_weekly_sales, Wmos_id, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE,
        LAST_UPDATED_BY, distro_type)
        VALUES (ln_allocation_key, p_asn, 'N/A', 'N', 
        0, 0, 0, 
        0, 0, 0, 
        0, 0, 0, 0, 
        0, 1, sysdate, 1,  sysdate, 
        1, G_DISTRO_TYPE_CONFIRM); */
  END IF;
  JITA_LOG_MSG(3, 'Confirmation Distro created');
/*  
  -- XML Generation
  JITA_LOG_MSG(3, 'Generate XML');
  gc_module_name  := 'JITA_GUARD_CHECKIN';
  gc_error_loc := 'XML Generation';  
  gc_error_message := 'Query to generate Store Distro XML failed: ';
  /*l_queryCtx := DBMS_XMLGEN.newContext(
    'SELECT JITA_ALLOCATIONS_t(allocation_id,
                   CAST(MULTISET(SELECT t1.process_name, t1.ASN,
                          t1.po_nbr, t1.sku, t1.location_id, 
                          t2.dest_location_id, t2.alloc_qty, t2.distro_num, 
                          t2.distro_type
                          FROM XX_MER_JITA_DISTROS t2
                          WHERE t1.allocation_id = t2.allocation_id)
                        AS DISTRO_LISTt))
       AS ALLOCATION
       FROM XX_MER_JITA_ALLOC_HEADER t1
       where ASN = ' || p_ASN);*
  
  l_queryCtx := DBMS_XMLGEN.newContext(
    'SELECT JITA_ALLOCATIONS_t(allocation_id,
                   CAST(MULTISET(SELECT t1.process_name, t1.ASN,
                          t1.po_nbr, t1.sku, t1.location_id, 
                          t2.dest_organization_id, t2.allocation_qty, t2.distro_num,
                          t2.distro_type 
                          FROM XX_MER_JITA_ALLOC_VIEW t2
                          WHERE t1.allocation_id = t2.allocation_id
                          ORDER BY t2.distro_num)
                        AS DISTRO_LISTt))
       AS ALLOCATION
       FROM XX_MER_JITA_ALLOC_HEADER t1
       where ASN = ' || p_ASN);
    
  -- set no row tag for this result
  DBMS_XMLGEN.setRowTag(l_queryCtx, NULL);
  -- get result
  p_xml_out := DBMS_XMLGEN.getXML(l_queryCtx);
  JITA_LOG_MSG(3, 'XML generated');
  JITA_LOG_MSG(5, 'XML Out size=' || DBMS_LOB.getLength(p_xml_out));
  
  INSERT INTO XX_MER_JITA_temp_clob VALUES (p_xml_out);*/

  MASS_UPDATE_PO_ALLOC (
    p_ASN => p_ASN
    , p_org_id => p_org_id
    , p_bCleanupASN => false );
  
  JITA_LOG_MSG(1, 'End JITA Guard checkin');
  gc_module_name  := 'JITA_GUARD_CHECKIN';
  gc_error_loc := 'Insert log';
  gc_error_message := 'Inserting log message failed: ';
  JITA_LOG_INSERT (p_org_id, p_ASN);
  COMMIT;
EXCEPTION  
  WHEN OTHERS THEN
    ROLLBACK;
    JITA_LOG_MSG(1, gc_error_message || 'SQLERRM= ' || SQLERRM);
    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
               p_application_name        => 'JITA'  -- TO DO use const string literals
              ,p_program_type            => 'STORED PROCEDURE'
              ,p_program_name            => gc_JITA_process_name
              ,p_module_name             => gc_module_name 
              ,p_error_location          => gc_error_loc
              ,p_error_message_count     => 1
              ,p_error_message_code      => 'E'
              ,p_error_message           => gc_error_message 
                  || 'SQLERRM= ' || SQLERRM
              ,p_error_message_severity  => 'Major'
              ,p_notify_flag             => 'N'
            );
    JITA_LOG_INSERT (p_org_id, p_asn);


  
END JITA_GUARD_CHECKIN;

PROCEDURE APPT_PROC (
  p_ASN IN  VARCHAR2,
  p_org_id IN NUMBER,
  p_appt_time IN varchar2 ) IS

  l_appt_time DATE;
BEGIN
  gc_JITA_process_name  := G_PROCESS_NAME_ONLINE; -- TO DO use string literals
  JITA_LOG_MSG(1, 'Start APPT_PROC');

  JITA_LOG_MSG(1, 'Input parameters are p_ASN= ' || p_ASN 
     || ' p_org_id= ' || p_org_id
     || ' p_appt_time= ' || p_appt_time);
  JITA_LOG_MSG(3, 'Input parameters check');
  gc_module_name  := 'APPT_PROC';
  gc_error_loc := 'Input parameters check';
  gc_error_message := 'Invalid input parameters: ';
  IF (p_ASN IS NULL) or (RTRIM(p_ASN) = '') 
    or (p_org_id IS NULL) or (p_org_id = 0) THEN
      JITA_LOG_MSG(3, 'Invalid input parameters');
      raise INVALID_INPUT;
  ELSE
    BEGIN
      l_appt_time :=  to_date(p_appt_time, 'yyyy-mm-dd HH24:MI:SS');
      JITA_LOG_MSG(3, 'Input parameters are OK');
    EXCEPTION
      WHEN OTHERS THEN
        RAISE INVALID_INPUT;
    END;    
  END IF;

  gc_module_name  := 'APPT_PROC';
  gc_error_loc := 'Update xx_mer_jita_appt';
  gc_error_message := 'Update xx_mer_jita_appt Failed: ';  
  JITA_LOG_MSG(5, 'Update xx_mer_jita_appt');
  UPDATE XX_MER_JITA_APPT set appt_time = l_appt_time
      , last_update_date = sysdate
      , last_updated_by = FND_GLOBAL.USER_ID
      , last_update_login = FND_GLOBAL.LOGIN_ID
      WHERE asn = p_ASN;
  IF SQL%ROWCOUNT = 0 THEN
    gc_error_loc := 'Insert xx_mer_jita_appt';
    gc_error_message := 'Insert xx_mer_jita_appt Failed: ';  
    JITA_LOG_MSG(5, 'No record to update, so Insert into xx_mer_jita_appt');
    INSERT INTO XX_MER_JITA_APPT (asn, organization_id, appt_time, 
      jita_proc_flag,last_update_login, last_update_date, last_updated_by, 
      creation_date, created_by) VALUES (p_ASN, p_org_id, 
      l_appt_time, 'R', FND_GLOBAL.LOGIN_ID,SYSDATE, 
      FND_GLOBAL.USER_ID, SYSDATE, FND_GLOBAL.USER_ID);
  END IF; 

  JITA_LOG_MSG(1, 'End APPT_PROC');
  gc_module_name  := 'APPT_PROC';
  gc_error_loc := 'Insert log';
  gc_error_message := 'Inserting log message failed: ';
  JITA_LOG_INSERT (p_org_id, p_ASN);
  COMMIT;

EXCEPTION  
  WHEN OTHERS THEN
    ROLLBACK;
    JITA_LOG_MSG(1, gc_error_message || 'SQLERRM= ' || SQLERRM);
    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
               p_application_name        => 'JITA'  -- TO DO use const string literals
              ,p_program_type            => 'STORED PROCEDURE'
              ,p_program_name            => gc_JITA_process_name
              ,p_module_name             => gc_module_name 
              ,p_error_location          => gc_error_loc
              ,p_error_message_count     => 1
              ,p_error_message_code      => 'E'
              ,p_error_message           => gc_error_message 
                  || 'SQLERRM= ' || SQLERRM
              ,p_error_message_severity  => 'Major'
              ,p_notify_flag             => 'N'
            );
    JITA_LOG_INSERT (p_org_id, NULL);

END APPT_PROC;

PROCEDURE JITA_DISCREPANCY (
  p_source_org_id IN NUMBER,
  p_dest_org_id IN NUMBER,
  p_ASN IN VARCHAR2,
  p_po_num IN VARCHAR2,
  p_po_line_num IN NUMBER,
  p_po_shipment_num IN NUMBER,
  p_SKU IN VARCHAR2,
  p_Adj_Qty IN NUMBER,
  p_Adj_type IN VARCHAR2 ) IS
  
  ln_adj_qty NUMBER   := 0;
  ln_Allocation_id xx_mer_jita_alloc_header.allocation_id%TYPE := 0;
  ln_inventory_item_id mtl_system_items_b.inventory_item_id%TYPE := 0;
  ln_vendor_id po_approved_supplier_list.vendor_id%TYPE := 0;
  ln_vendor_site_id po_approved_supplier_list.vendor_site_id%TYPE := 0;
  ln_po_header_id po_headers_all.po_header_id%TYPE := 0;
  ln_po_line_id po_lines_all.po_line_id%TYPE := 0;
  ln_po_line_location_id    po_lines_all.po_line_id%TYPE := 0;
  ln_po_alloc_hdr_key xx_po_allocation_header.allocation_header_id%TYPE := 0;

  ln_standard_pack_qty NUMBER := 0;
  ln_case_pack_qty NUMBER := 0;

BEGIN
  gc_JITA_process_name  := G_PROCESS_NAME_ONLINE; -- TO DO use string literals
  JITA_LOG_MSG(1, 'Start JITA_DISCREPANCY');

  JITA_LOG_MSG(1, 'Input parameters are p_source_org_id= ' || p_source_org_id 
     || ' p_dest_org_id= ' || p_dest_org_id
     || ' p_po_num= ' || p_po_num
     || ' p_po_line_num= ' || p_po_line_num
     || ' p_po_shipment_num= ' || p_po_shipment_num
     || ' p_SKU= ' || p_SKU
     || ' p_Adj_Qty= ' || p_Adj_Qty
     || ' p_Adj_type= ' || p_Adj_type);
  JITA_LOG_MSG(3, 'Input parameters check');
  gc_module_name  := 'JITA_DISCREPANCY';
  gc_error_loc := 'Input parameters check';
  gc_error_message := 'Invalid input parameters: ';
  IF (p_source_org_id IS NULL) or (p_source_org_id= 0) 
    or (p_dest_org_id IS NULL) or (p_dest_org_id = 0) 
    or (p_SKU IS NULL) or (LTRIM(p_SKU) = '') 
    or (p_Adj_Qty IS NULL) or (p_Adj_Qty = 0)
    or (p_Adj_type IS NULL) or (LTRIM(p_Adj_type) = '') THEN
      JITA_LOG_MSG(3, 'Invalid input parameters');
      raise INVALID_INPUT;
  ELSE
    JITA_LOG_MSG(3, 'Input parameters are OK');
  END IF;  
  
  -- Get config parameters
  INITIALIZE_CONFIG_PARAMS;  

  IF (p_Adj_type = 'S' ) THEN
    ln_adj_qty := -p_Adj_Qty;
  ELSE
    ln_adj_qty := p_Adj_Qty;
  END IF;
  
  -- First get the allocation_id
  -- TO DO Handle the case in which ASN, PO are NULL
  gc_module_name  := 'JITA_DISCREPANCY';
  gc_error_loc := 'Get Allocation Id';
  gc_error_message := 'Query to get allocation id Failed: ';  
  JITA_LOG_MSG(5, 'Query to get allocation id:');
  SELECT allocation_id, po_header_id, po_line_id, line_location_id,
    inventory_item_id
  INTO ln_Allocation_id, ln_po_header_id, ln_po_line_id, ln_po_line_location_id,
    ln_inventory_item_id
  FROM XX_MER_JITA_ALLOC_HEADER
  WHERE organization_id = p_source_org_id 
  AND asn = p_ASN
  AND sku = p_SKU
  AND po_num = p_po_num
  AND po_line_num = p_po_line_num
  AND po_shipment_num = p_po_shipment_num;
  
  JITA_LOG_MSG(5, 'ln_Allocation_id= ' || ln_Allocation_id );

  IF ln_adj_qty < 0 THEN -- SHORTAGE
    gc_module_name  := 'JITA_DISCREPANCY';
    gc_error_loc := 'Update XX_MER_JITA_ALLOC_DTLS';
    gc_error_message := 'Update XX_MER_JITA_ALLOC_DTLS Failed: ';  
    JITA_LOG_MSG(5, 'Update XX_MER_JITA_ALLOC_DTLS');
    UPDATE XX_MER_JITA_ALLOC_DTLS 
    SET wmos_shipped_qty = wmos_shipped_qty + ln_adj_qty
       , last_update_date = sysdate
       , last_updated_by = FND_GLOBAL.USER_ID
       , last_update_login = FND_GLOBAL.LOGIN_ID
    WHERE  allocation_id = ln_Allocation_id
    AND dest_organization_id = p_dest_org_id;
    --IF SQL%ROWCOUNT = 0 THEN    
    --END IF;   
  ELSE -- Overage
    gc_module_name  := 'JITA_DISCREPANCY';
    gc_error_loc := 'Update XX_MER_JITA_ALLOC_DTLS';
    gc_error_message := 'Update XX_MER_JITA_ALLOC_DTLS Failed: ';  
    JITA_LOG_MSG(5, 'Update XX_MER_JITA_ALLOC_DTLS');
    UPDATE XX_MER_JITA_ALLOC_DTLS 
      SET wmos_shipped_qty = wmos_shipped_qty + ln_adj_qty
        , overage_qty = ln_adj_qty
        , last_update_date = sysdate
        , last_updated_by = FND_GLOBAL.LOGIN_ID
        , last_update_login = FND_GLOBAL.LOGIN_ID
      WHERE  allocation_id = ln_Allocation_id
      AND dest_organization_id = p_dest_org_id;     
    IF SQL%ROWCOUNT = 0 THEN
      gc_module_name  := 'JITA_DISCREPANCY';
      gc_error_loc := 'Insert XX_MER_JITA_ALLOC_DTLS';
      gc_error_message := 'Insert XX_MER_JITA_ALLOC_DTLS Failed: ';  
      JITA_LOG_MSG(5, 'Insert XX_MER_JITA_ALLOC_DTLS');
      insert into XX_MER_JITA_ALLOC_DTLS
        (Allocation_id, dest_organization_id, Store_type, New_store_flag, 
        replen_type_code, replen_subtype_code, warehouse_item_code,
        Allocation_qty, wmos_shipped_qty, Dynamic_qty, 
        Lockin_alloc_qty, Seasonal_lrg_ord_qty, bottom_fill_qty, 
        ATP_customer_order_qty, RUTL, Sellable_on_hand, In_transit_qty, 
        avg_rate_of_sale, creation_date, created_by, last_update_date,
        last_updated_by, last_update_login, distro_type, overage_qty)
        select Allocation_id, dest_organization_id, Store_type, New_store_flag, 
        replen_type_code, replen_subtype_code, warehouse_item_code,
        ln_adj_qty, ln_adj_qty, 0, 
        0, 0, 0, 
        0, RUTL, Sellable_on_hand, In_transit_qty, 
        avg_rate_of_sale, sysdate, FND_GLOBAL.LOGIN_ID,  sysdate, 
        FND_GLOBAL.LOGIN_ID, FND_GLOBAL.LOGIN_ID, distro_type, ln_adj_qty
        FROM XX_MER_JITA_ALLOC_OVERAGE
        WHERE allocation_id = ln_Allocation_id
        AND dest_organization_id = p_dest_org_id; 
    END IF;    
  END IF;

  JITA_LOG_MSG(5, 'p_po_num=' || p_po_num);
  IF p_po_num IS NOT NULL THEN
    GET_PACK_SIZE_INFO ( p_inventory_item_id => ln_inventory_item_id,
      p_org_id => p_source_org_id,
      p_po_header_id => ln_po_header_id,
      p_standard_pack_qty => ln_standard_pack_qty,
      p_case_pack_qty => ln_case_pack_qty,
      p_vendor_id => ln_vendor_id, 
      p_vendor_site_id => ln_vendor_site_id);

    gc_module_name  := 'JITA_DISCREPANCY';
    gc_error_loc := 'Query for po_alloc_header_id: ';
    gc_error_message := 'Query to get po_alloc_header_id failed: ';
    JITA_LOG_MSG(3, 'Query to to get po_alloc_header_id');  
    OPEN lcu_po_alloc_header(ln_inventory_item_id, p_source_org_id, 
          ln_vendor_id, ln_vendor_site_id);  
    gc_error_message := 'Fetch from cursor lcu_po_alloc_header Failed: ';  
    JITA_LOG_MSG(5, 'Fetch from cursor lcu_po_alloc_header');
    FETCH lcu_po_alloc_header INTO ln_po_alloc_hdr_key;    
    IF lcu_po_alloc_header%NOTFOUND THEN
      -- TO DO Error
      CLOSE lcu_po_alloc_header;
    END IF;
    CLOSE lcu_po_alloc_header;

    JITA_LOG_MSG(5, 'ln_po_alloc_hdr_key=' || ln_po_alloc_hdr_key);
    JITA_LOG_MSG(5, 'call UPDATE_PO_ALLOCATION_LINES');
    UPDATE_PO_ALLOCATION_LINES (
      p_source_org_id => p_source_org_id
      , p_po_alloc_hdr_key => ln_po_alloc_hdr_key
      , p_po_header_id => ln_po_header_id
      , p_po_line_id => ln_po_line_id
      , p_po_line_location_id => ln_po_line_location_id
      , p_dest_org_id => p_dest_org_id
      , p_jita_qty => 0
      , p_wmos_qty => ln_adj_qty );

  END IF;

  JITA_LOG_MSG(1, 'End JITA_DISCREPANCY');
  gc_module_name  := 'JITA_DISCREPANCY';
  gc_error_loc := 'Insert log';
  gc_error_message := 'Inserting log message failed: ';
  JITA_LOG_INSERT (p_source_org_id, NULL);
  COMMIT;

EXCEPTION  
  WHEN OTHERS THEN
    ROLLBACK;
    JITA_LOG_MSG(1, gc_error_message || 'SQLERRM= ' || SQLERRM);
    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
               p_application_name        => 'JITA'  -- TO DO use const string literals
              ,p_program_type            => 'STORED PROCEDURE'
              ,p_program_name            => gc_JITA_process_name
              ,p_module_name             => gc_module_name 
              ,p_error_location          => gc_error_loc
              ,p_error_message_count     => 1
              ,p_error_message_code      => 'E'
              ,p_error_message           => gc_error_message 
                  || 'SQLERRM= ' || SQLERRM
              ,p_error_message_severity  => 'Major'
              ,p_notify_flag             => 'N'
            );
    JITA_LOG_INSERT (p_source_org_id, NULL);

  
END JITA_DISCREPANCY;

PROCEDURE JITA_200D (
    ERRBUF  OUT NOCOPY VARCHAR2
  , RETCODE OUT NOCOPY VARCHAR2
  , p_org_id hr_all_organization_units.organization_id%TYPE
  , p_SKU IN mtl_system_items_b.segment1%TYPE
  , p_inventory_item_id IN mtl_system_items_b.inventory_item_id%TYPE
  , p_qty_distribute IN NUMBER
  , p_vendor_product_code  po_approved_supplier_list.primary_vendor_item%TYPE
   ) IS
  
  ln_store_org_id hr_all_organization_units.organization_id%TYPE;
  ln_ARS NUMBER := 0;
  ln_onhand NUMBER := 0;
  ln_qty_distribute NUMBER := 0;
  ln_in_transit NUMBER := 0;
  l_po_arrival_date DATE;
  ln_Need NUMBER := 0;
  ln_DistroCount NUMBER := 0;
  ln_allocation_key NUMBER := 0;
  ln_CanReceive NUMBER := 0;

  ln_vendor_id po_approved_supplier_list.vendor_id%TYPE := 0;
  ln_vendor_site_id po_approved_supplier_list.vendor_site_id%TYPE := 0;
  ln_standard_pack_qty NUMBER := 0;
  ln_case_pack_qty NUMBER := 0;
  --lc_sql_stmt VARCHAR2(2000);
  --ln_fiscal_week XX_REPL_FDATE_ALL.FISCAL_WEEK%TYPE := 0;
  
  --TYPE WarehouseTyp IS REF CURSOR;
  --warehouselist_cv   WarehouseTyp;
BEGIN
  JITA_LOG_MSG(1, 'Start JITA 200D Sourcing of Outs');
  gc_module_name  := 'JITA_200D';
  
  RETCODE := -1;
  ERRBUF  := 'JITA 200D: Unknown Error';
  
  ln_qty_distribute := p_qty_distribute;

  JITA_LOG_MSG(5, 'p_org_id= ' || p_org_id || ' p_item_id=' || 
            p_inventory_item_id || ' p_VPC = ' || p_vendor_product_code);
  -- get pack quantities
  GET_PACK_SIZE_INFO ( 
      p_inventory_item_id => p_inventory_item_id
      , p_org_id => p_org_id
      , p_po_header_id => NULL
      , p_standard_pack_qty => ln_standard_pack_qty
      , p_case_pack_qty => ln_case_pack_qty
      , p_vendor_id => ln_vendor_id
      , p_vendor_site_id => ln_vendor_site_id);
  JITA_LOG_MSG(3, 'Standard packsize= ' || ln_standard_pack_qty);
  JITA_LOG_MSG(3, 'Case packsize= ' || ln_case_pack_qty);
  
  FOR I in 1 .. 2 LOOP
    JITA_LOG_MSG(3, 'Phase# ' || I );
    JITA_LOG_MSG(3, 'Get Input Data for Outs');
    gc_module_name  := 'JITA_200D';
    gc_error_loc := 'Get Input Data for Outs';
    gc_error_message := 'Open Cursor lcu_get_data_for_outs Failed: ';  
    OPEN lcu_get_data_for_outs (p_org_id, p_inventory_item_id, 
        p_vendor_product_code, I);
    LOOP
      IF (ln_qty_distribute <= 0) THEN
        EXIT;
      END IF;
      gc_error_message := 'Fetch from Cursor lcu_get_data_for_outs Failed: ';
      gc_module_name  := 'JITA_200D';
      gc_error_loc := 'Get Stores List for Outs ';
      FETCH lcu_get_data_for_outs INTO ln_store_org_id, ln_ARS, ln_onhand;
      EXIT WHEN lcu_get_data_for_outs%NOTFOUND;
      JITA_LOG_MSG(5, 'Store org Id=' || ln_store_org_id || ' ARS= ' || ln_ARS 
            || ' OnHand= ' || ln_onhand );

      gc_module_name  := 'JITA_200D';
      gc_error_loc := 'Get in-transit quantity';
      gc_error_message := 'Open Cursor lcu_intransit Failed: ';  
      OPEN lcu_intransit (p_inventory_item_id, p_org_id);
      FETCH lcu_intransit INTO ln_in_transit;
      CLOSE lcu_intransit;
      JITA_LOG_MSG(5, 'In Transit=' || ln_in_transit);
      IF ln_in_transit <= 0 THEN
        gc_module_name  := 'JITA_200D';
        gc_error_loc := 'Get PO arrival date';
        gc_error_message := 'Open Cursor lcu_get_po_arrival_date Failed: ';  
        OPEN lcu_get_po_arrival_date (p_org_id, p_inventory_item_id);
        -- TO DO. Actually we have to use XD org_id. 
        -- The field is still in missing in XX_INV_ORG_LOC_RMS_ATTRIBUTE
        FETCH lcu_get_po_arrival_date INTO l_po_arrival_date;
        IF lcu_get_po_arrival_date%NOTFOUND THEN
          l_po_arrival_date := NULL;
        END IF;
        JITA_LOG_MSG(5, 'PO arrival date=' || l_po_arrival_date);
        CLOSE lcu_get_po_arrival_date;
        
        ln_Need := 0;
        IF (trunc(l_po_arrival_date) > trunc(sysdate - 2) ) 
           AND (trunc(l_po_arrival_date) < trunc(sysdate + 2) ) THEN
           ln_Need := 0;
        ELSIF (l_po_arrival_date IS NULL) 
           OR (trunc(l_po_arrival_date) < trunc(sysdate - 2) ) 
           OR (trunc(l_po_arrival_date) > trunc(sysdate + 8) ) THEN
              ln_Need := ROUND_QTY(
                           p_raw_qty => ln_ARS, 
                           p_store_type => G_STORE_TYPE_REGULAR,
                           p_standard_pack_qty => ln_standard_pack_qty,
                           p_case_pack_qty => ln_case_pack_qty);
        ELSIF  (trunc(l_po_arrival_date) > trunc(sysdate + 2) ) 
           AND (trunc(l_po_arrival_date) < trunc(sysdate + 7) ) 
           AND ln_ARS < gn_ARS_lim_for_need THEN
              ln_Need := 1;
        ELSIF  (trunc(l_po_arrival_date) > trunc(sysdate + 2) ) 
           AND (trunc(l_po_arrival_date) < trunc(sysdate + 7) ) 
           AND ln_ARS >= gn_ARS_lim_for_need THEN
              ln_Need := (trunc(l_po_arrival_date) - trunc(sysdate))/7.0*ln_ARS;
              ln_Need := ROUND_QTY(
                           p_raw_qty => ln_Need, 
                           p_store_type => G_STORE_TYPE_REGULAR,
                           p_standard_pack_qty => ln_standard_pack_qty,
                           p_case_pack_qty => ln_case_pack_qty);
        END IF;
        JITA_LOG_MSG(5, 'Need=' || ln_Need);

        IF ln_Need >0 THEN
          IF ln_qty_distribute <= ln_Need THEN
            ln_Need := ln_qty_distribute;
          END IF;
          ln_qty_distribute := ln_qty_distribute - ln_Need;

          gc_module_name  := 'JITA_200D';
          gc_error_loc := 'Get receiving schedule';
          gc_error_message := 'Get next sequence number from XX_MER_JITA_ALLOC_HEADER_S failed: ';
          SELECT count(*) INTO ln_CanReceive
          FROM XX_REPL_SCHEDULE_ALL t1, XX_REPL_RECV_SCHEDULE t2
          WHERE t1.SCHEDULE_ID = t2.SCHEDULE_ID
            AND t2.SOURCE_LOC_ID = p_org_id
            AND t2.ORGANIZATION_ID = ln_store_org_id
            AND t1.SCHEDULE_DAY = gn_schedule_day 
            AND t1.SCHEDULE_TYPE = gc_schedule_type;
          JITA_LOG_MSG(5, ' can receive= ' || ln_CanReceive);
          
          IF ln_CanReceive >0 THEN
            ln_DistroCount := ln_DistroCount + 1;
            IF ln_DistroCount = 1 THEN
              gc_module_name  := 'JITA_200D';
              gc_error_loc := 'Create Distro';
              gc_error_message := 'Get next sequence number from XX_MER_JITA_ALLOC_HEADER_S failed: ';
              JITA_LOG_MSG(5, 'Get next value from sequence XX_MER_JITA_ALLOC_HEADER_S');
              SELECT XX_MER_JITA_ALLOC_HEADER_S.nextval INTO ln_allocation_key FROM dual;

              gc_error_message := 'Insert into XX_MER_JITA_ALLOC_HEADER failed: ';
              JITA_LOG_MSG(5, 'Insert into XX_MER_JITA_ALLOC_HEADER');
              INSERT INTO xx_mer_jita_alloc_header(
                 allocation_id
               , process_name
               , asn
               , po_num
               , po_line_num
               , po_shipment_num
               , po_header_id
               , po_line_id
               , line_location_id
               , sku
               , inventory_item_id
               , organization_id
               , received_qty
               , last_update_login
               , last_update_date
               , last_updated_by
               , creation_date
               , created_by)
              VALUES (
                 ln_allocation_key
               , gc_JITA_process_name
               , NULL
               , NULL
               , NULL
               , NULL
               , NULL
               , NULL
               , NULL
               , p_sku
               , p_inventory_item_id
               , p_org_id
               , 0
               , FND_GLOBAL.LOGIN_ID
               , SYSDATE
               , FND_GLOBAL.USER_ID
               , SYSDATE 
               , FND_GLOBAL.USER_ID 
              );              
            END IF;

            gc_module_name  := 'JITA_200D'; 
            gc_error_loc := 'Insert Allocation Results ';
            gc_error_message := 'Insert into XX_MER_JITA_ALLOC_DTLS Failed: ';
            JITA_LOG_MSG(1, 'Insert Allocation Results');
            INSERT INTO XX_MER_JITA_ALLOC_DTLS
             (  Allocation_id
              , dest_organization_id
              , New_store_flag
              , Allocation_qty
              , wmos_shipped_qty
              , distro_type
              , last_update_login
              , last_update_date
              , last_updated_by
              , creation_date
              , created_by)
            VALUES(
                ln_allocation_key
              , ln_store_org_id
              , 'N' -- TO DO
              , ln_Need
              , ln_Need
              , G_DISTRO_TYPE_FLOWTHRU -- TO DO do we have a separte type for batch?
              , FND_GLOBAL.LOGIN_ID
              , SYSDATE
              , FND_GLOBAL.USER_ID
              , SYSDATE 
              , FND_GLOBAL.USER_ID );
            JITA_LOG_MSG(5, 'qty_distribute=' || ln_qty_distribute);
          END IF;
        END IF;
      END IF;
    END LOOP;
    CLOSE lcu_get_data_for_outs;
  END LOOP;
  
END JITA_200D;


PROCEDURE JITA_BATCH (
  ERRBUF  OUT NOCOPY VARCHAR2,
  RETCODE OUT NOCOPY VARCHAR2,
  p_Program_name IN VARCHAR2,
  p_warehouse_list IN VARCHAR2 ) IS
  
  l_org_id hr_all_organization_units.organization_id%TYPE;
  l_SKU mtl_system_items_b.segment1%TYPE;
  ln_inventory_item_id mtl_system_items_b.inventory_item_id%TYPE;
  ln_qty_distribute NUMBER;
  lc_sql_stmt VARCHAR2(2000);
  ln_fiscal_week XX_REPL_FDATE_ALL.FISCAL_WEEK%TYPE := 0;
  lc_Vendor_product_code  po_approved_supplier_list.primary_vendor_item%TYPE;
  
  TYPE WarehouseTyp IS REF CURSOR;
  warehouselist_cv   WarehouseTyp;

  
BEGIN

  JITA_LOG_MSG(1, 'Start JITA BATCH for' || p_Program_name);
  gc_JITA_process_name := p_Program_name;
  
  RETCODE := -1;
  ERRBUF  := 'JITA Batch: Unknown Error';
  
  JITA_LOG_MSG(1, 'Input parameters are p_Program_name= ' || p_Program_name 
      || ' p_warehouse_list= ' ||  p_warehouse_list);
  JITA_LOG_MSG(3, 'Input parameters check');
  gc_module_name  := 'JITA_BATCH';
  gc_error_loc := 'Input parameters check';
  gc_error_message := 'Invalid input parameters: ';
  IF (p_Program_name IS NULL) or (p_warehouse_list IS NULL) THEN -- TO DO warehouselist must conform to a format
    JITA_LOG_MSG(3, 'Invalid input parameters');
    raise INVALID_INPUT;
  ELSE
    JITA_LOG_MSG(3, 'Input parameters are OK');
  END IF;  
  
  -- Get config parameters
  INITIALIZE_CONFIG_PARAMS;
  
  gc_module_name  := 'JITA_BATCH';
  gc_error_loc := 'Get receiving schedule type ';
  gc_error_message := 'Query to XX_REPL_FDATE_ALL Failed. ';  
  JITA_LOG_MSG(3, 'Get receiving schedule type and schedule day!');  
  -- TO DO trap error if no record found
  SELECT fiscal_week, fiscal_day INTO ln_fiscal_week, gn_schedule_day
  FROM xx_repl_fdate_all WHERE date_in = trunc(sysdate);
  JITA_LOG_MSG(5, 'ln_fiscal_week= ' || ln_fiscal_week);
  JITA_LOG_MSG(5, 'gn_schedule_day= ' || gn_schedule_day);
  IF MOD(ln_fiscal_week, 2) = 1 THEN
    gc_schedule_type := 'O';
  ELSE
    gc_schedule_type := 'E';
  END IF;
  JITA_LOG_MSG(5, 'gc_schedule_type= ' || gc_schedule_type);
  
  JITA_LOG_MSG(3, 'Get a list of WMoS warehouses');
  
  -- TO DO this needs change. Also need to support ALL as a parameter
  lc_sql_stmt := ' SELECT  org_id FROM XX_MER_JITA_SCM_WAREHOUSE_SYS' ||
    ' WHERE org_id IN  (' || p_warehouse_list || ') ' ||
    ' AND warehouse_sys_code = ''WMOS'' AND active_date < sysdate ' ||
    ' AND end_date > sysdate ';  
    
  gc_module_name  := 'JITA_BATCH';
  gc_error_loc := 'Get a list of WMoS warehouses ';
  gc_error_message := 'Open Cursor warehouselist_cv Failed: ';  
  OPEN warehouselist_cv FOR lc_sql_stmt;
   LOOP
    gc_module_name  := 'JITA_BATCH';
    gc_error_loc := 'Get a list of WMoS warehouses ';  
    gc_error_message := 'Fetch from Cursor warehouselist_cv Failed: ';  
    FETCH warehouselist_cv INTO l_org_id;
    EXIT WHEN warehouselist_cv%NOTFOUND;
    JITA_LOG_MSG(5, 'Warehouse= ' || l_org_id);
    JITA_LOG_MSG(3, 'Get Inventory information');
    gc_module_name  := 'JITA_BATCH';
    gc_error_loc := 'Get Inventory information ';
    gc_error_message := 'Open Cursor lcu_get_items_for_batch Failed: ';
    OPEN lcu_get_items_for_batch (TO_NUMBER(l_org_id));
    LOOP
      gc_error_message := 'Fetch from Cursor lcu_get_items_for_batch Failed: ';
      gc_module_name  := 'JITA_BATCH';
      gc_error_loc := 'Get Inventory information ';
      FETCH lcu_get_items_for_batch INTO l_SKU, ln_inventory_item_id,
              ln_qty_distribute, lc_Vendor_product_code;
      EXIT WHEN lcu_get_items_for_batch%NOTFOUND;
      JITA_LOG_MSG(5, 'SKU= ' || l_SKU || ' Qty to distribute=' || ln_qty_distribute);
      IF (p_Program_name = G_PROCESS_NAME_200D) THEN
        JITA_200D (
            ERRBUF  => ERRBUF
          , RETCODE => RETCODE
          , p_org_id => l_org_id
          , p_SKU => l_SKU
          , p_inventory_item_id => ln_inventory_item_id
          , p_qty_distribute => ln_qty_distribute
          , p_vendor_product_code => lc_Vendor_product_code
        );        
      ELSE    
        /*JITA_ENGINE (
            p_ASN  => NULL,
            p_po_num  => NULL,
            p_sku  => l_SKU,
            p_org_id  => l_org_id,
            p_received_qty  => ln_qty_distribute,
            p_is_overage  => false);*/
       
        JITA_ENGINE (
          p_ASN => NULL
          , p_po_num => NULL
          , p_line_num => NULL
          , p_po_shipment_num => NULL
          , p_sku => l_SKU
          , p_ORG_ID => l_org_id
          , p_received_qty => ln_qty_distribute
          , p_po_header_id => NULL
          , p_po_line_id => NULL
          , p_po_line_location_id => NULL
          , p_inventory_item_id => ln_inventory_item_id
          , p_is_overage => FALSE) ;
      END IF;  
      gc_module_name  := 'JITA_BATCH';
      gc_error_loc := 'Insert log';
      gc_error_message := 'Inserting log message failed: ';  
      JITA_LOG_INSERT (l_org_id, NULL);
    END LOOP;
    gc_module_name  := 'JITA_BATCH';
    gc_error_loc := 'Get Inventory information ';
    gc_error_message := 'Close Cursor lcu_get_items_for_batch Failed: ';
    CLOSE lcu_get_items_for_batch;
    
    gc_module_name  := 'JITA_BATCH';
    gc_error_loc := 'Insert log';
    gc_error_message := 'Inserting log message failed: ';  
    JITA_LOG_INSERT (l_org_id, NULL);
    COMMIT;
  END LOOP;
  
  gc_module_name  := 'JITA_BATCH';
  gc_error_loc := 'Get a list of WMoS warehouses ';
  gc_error_message := 'Close Cursor warehouselist_cv Failed: ';  
  CLOSE warehouselist_cv;
  
  gc_module_name  := 'JITA_BATCH';
  gc_error_loc := 'Insert log';
  gc_error_message := 'Inserting log message failed: ';  
  JITA_LOG_INSERT (l_org_id, NULL);
  COMMIT;
  
  RETCODE := 0;
  ERRBUF  := 'JITA Batch Ran Successfully';
  JITA_LOG_MSG(1, 'End JITA BATCH for' || p_Program_name);
EXCEPTION  
  WHEN OTHERS THEN
    ROLLBACK;
    JITA_LOG_MSG(1, gc_error_message || 'SQLERRM= ' || SQLERRM);
    XX_COM_ERROR_LOG_PUB.LOG_ERROR (
               p_application_name        => 'JITA'  -- TO DO use const string literals
              ,p_program_type            => 'STORED PROCEDURE'
              ,p_program_name            => gc_JITA_process_name
              ,p_module_name             => gc_module_name 
              ,p_error_location          => gc_error_loc
              ,p_error_message_count     => 1
              ,p_error_message_code      => 'E'
              ,p_error_message           => gc_error_message 
                  || 'SQLERRM= ' || SQLERRM
              ,p_error_message_severity  => 'Major'
              ,p_notify_flag             => 'N'
            );
    JITA_LOG_INSERT (NULL, NULL);
  
END JITA_BATCH;


END XX_MER_JITA_PKG;

