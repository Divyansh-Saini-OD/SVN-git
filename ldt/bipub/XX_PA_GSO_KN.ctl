LOAD DATA
APPEND
INTO TABLE xxmer.xx_gso_po_kn_stg
FIELDS TERMINATED BY "|"
OPTIONALLY ENCLOSED BY '"'
trailing nullcols
 (
  po_number,
  sku,
  po_line_no,
  upc,
  dept,
  final_destination,
  vend_book_date		"to_date(:vend_book_date,'YYYY.MM.DD')",  
  po_line_cfs_recd_d	"to_date(:po_line_cfs_recd_d,'YYYY.MM.DD')",  
  fcl_cntnr_cy_recd_d	"to_date(:fcl_cntnr_cy_recd_d,'YYYY.MM.DD')",  
  ets_ats_d			"to_date(:ets_ats_d,'YYYY.MM.DD')",  
  date_shipped		"to_date(:date_shipped,'YYYY.MM.DD')",  
  container,
  container_movement,
  actual_quantity,
  uom,
  volume,
  grossweight,
  kn_reference,
  loading_place,
  eta_ata_d			"to_date(:eta_ata_d,'YYYY.MM.DD')",  
  sh_arrival_place,
  eta_place_delivery_d	"to_date(:eta_place_delivery_d,'YYYY.MM.DD')",  
  place_of_delivery,
  required_delivery_d	"to_date(:required_delivery_d,'YYYY.MM.DD')",  
  ship_window_start	"to_date(:ship_window_start,'YYYY.MM.DD')",  
  ship_window_end		"to_date(:ship_window_end,'YYYY.MM.DD')",  
  creation_date "SYSDATE",
  process_flag "1"
)
