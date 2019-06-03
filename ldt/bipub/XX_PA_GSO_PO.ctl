OPTIONS(SKIP=2)
LOAD DATA
APPEND
INTO TABLE apps.xx_gso_po_stg
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
trailing nullcols
  (vendor_name,
  vendor_no,
  po_number,
  po_status_cd,
  po_date "to_date(:po_date,'MM/DD/YYYY')",
  po_line_no,
  sku,
  vpc, origin_country, dept,class,std_pack,
  carton_pack,uom,carton_cube,carton_weight,
  master_carton,
  ordered_qty,
  retail_price,
  fob_origin_cost,
  est_landed_cost,
  merch_dec_cost,
  act_landed_cost,
  description,
  ship_date "to_date(:ship_date,'MM/DD/YYYY')",
  company_source_cd,
  batch_id,
  country_cd,
  port_name,
  location_name,
  department,
  po_recd_to_jda "to_date(:po_recd_to_jda,'MM/DD/YYYY')",
  po_rel_to_vend,
  po_conf_by_vend,
  edi_status "TRIM(:edi_status)",
  creation_date "SYSDATE",
  process_flag "1"
)
