-- +============================================================================================+
-- |                        Office Depot                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : xxpoconv.ctl                                               	|                                                       				|
-- | Description  : Conversion of POM PO into EBS          
-- | Purpose      : Load data into Custom staging Table                         |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- | 1.0      28-JUL-2017    Vinay Singh           Initial Version                              |
-- |                                                                                            |
-- +============================================================================================+




--OPTIONS (ERRORS=0,SKIP = 2)

LOAD DATA
APPEND


-- Type 1 - PO Headers



INTO TABLE xxfin.xx_po_hdrs_conv_stg
WHEN (1:1) != 'L'
FIELDS TERMINATED BY '|' --OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
( record_type              POSITION(01:01) CHAR--"TRIM(:record_type)"
 ,control_id             "xx_po_poconv_stg_s.NEXTVAL"
 ,conv_action            "TRIM(:conv_action)"
 ,source_system_code     CONSTANT "ODPO"
 --CONSTANT "CREATE"
 ,source_system_ref      "TRIM(:source_system_ref)"
 ,currency_code           "TRIM(:currency_code)"
 ,vendor_site_code        "TRIM(:vendor_site_code)"
 ,ship_to_location        "TRIM(:ship_to_location)"
 ,fob                     "TRIM(:fob)"
 ,freight_terms           "TRIM(:freight_terms)"
 ,note_to_vendor          "TRIM(replace(:note_to_vendor, chr(13)||chr(10), ''))"
 ,note_to_receiver        "TRIM(:note_to_receiver)"
 ,closed_code             "TRIM(:closed_code)"
--,approval_status           CONSTANT "NULL" 
 ,attribute10              "TRIM(:attribute10)"
 --,attribute10             CONSTANT "0000000"
 ,creation_date           "TO_DATE(TRIM(:creation_date),'MM-DD-YY')" --DATE "MM/DD/YYYY" -- "to_timestamp(:creation_date, 'MM/DD/YYYY HH24:MI:SS.FF')"
 ,last_update_date        "TO_DATE(TRIM(:last_update_date),'MM-DD-YY')" -- DATE "MM/DD/YYYY" -- "to_timestamp(:last_update_date, 'MM/DD/YYYY HH24:MI:SS.FF')"
 ,rate_type               "TRIM(:rate_type)"
 ,reference_num           "po_headers_interface_s.NEXTVAL" 
 ,vendor_num              "TRIM(:vendor_site_code)"
 ,agent_id                CONSTANT "15335"
 ,distribution_code       "TRIM(:distribution_code)"
 ,po_type                 "TRIM(:po_type)"
 ,num_lines               "TRIM(:num_lines)"
 ,cost                    "TRIM(:cost)"
 ,ord_rec_shpd            "TRIM(:ord_rec_shpd)"
 ,lb                      "TRIM(:lb)"
 ,net_po_total_cost       "TRIM(:net_po_total_cost)"
 ,drop_ship_flag          "TRIM(:drop_ship_flag)"
 ,audit_id               "xx_po_poconv_stg_s.NEXTVAL"
 ,ship_via                "TRIM(:ship_via)"
 ,back_orders             "TRIM(:back_orders)"
 ,order_dt                "TO_DATE(TRIM(:order_dt),'MM-DD-YY')"
 ,ship_dt                 "TO_DATE(TRIM(:ship_dt),'MM-DD-YY')" 
 ,arrival_dt              "TO_DATE(TRIM(:arrival_dt),'MM-DD-YY')" 
 ,cancel_dt               "TO_DATE(TRIM(:cancel_dt),'MM-DD-YY')"
 ,release_date            "TO_DATE(TRIM(:release_date),'MM-DD-YY')"
 ,revision_flag           "TRIM(:revision_flag)"
 ,last_ship_dt            "TO_DATE(TRIM(:last_ship_dt),'MM-DD-YY')"
 ,last_receipt_dt      "TO_DATE(TRIM(:last_receipt_dt),'MM-DD-YY')" 
 ,terms_disc_pct       "TRIM(:terms_disc_pct)"
 ,terms_disc_days      "TRIM(:terms_disc_days)"
 ,terms_net_days       "TRIM(:terms_net_days)"
 ,allowance_basis_code "TRIM(:allowance_basis_code)"
 ,allowance_dollars    "TRIM(:allowance_dollars)"
 ,allowance_percent    "TRIM(:allowance_percent)"
 ,pom_created_by       "TRIM(:pom_created_by)"
 ,vendor_doc_num          "TRIM(:source_system_ref)"
 ,pgm_entered_by       "TRIM(:pgm_entered_by)"
 ,pom_changed_by       "TRIM(:pom_changed_by)"
 ,attribute15          "TRIM(:source_system_ref)"
 ,pgm_changed_by       "TRIM(:pgm_changed_by)"
 ,cust_id              "TRIM(:cust_id)"
 ,cust_order_nbr       "TRIM(:cust_order_nbr)"
 ,record_id              "xx_po_poconv_stg_s.NEXTVAL" 
 ,interface_header_id    "po_headers_interface_s.NEXTVAL"
-- ,document_num            "TRIM(:source_system_ref) || TRIM--(:ship_to_location)"
 ,document_num            "TRIM(:source_system_ref)||'-'||LTRIM (:ship_to_location,'0')"
 --,vendor_num               "TRIM(:vendor_site_code)"
--,vendor_doc_num          "TRIM(:source_system_ref)"
--,order_dt                "TO_DATE(TRIM(:order_dt),'MM-DD-YY')"
 --,source_system_code     CONSTANT "ODPO"
 --,control_id             "xx_po_poconv_stg_s.NEXTVAL"
  ,cust_order_sub_nbr   "TRIM(:cust_order_sub_nbr)"
  ,Process_flag     CONSTANT "1"
)


-- Type 1 - PO Lines


INTO TABLE  XXFIN.XX_PO_LINES_CONV_STG
WHEN (1:1) != 'H'
FIELDS TERMINATED BY '|' --OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
 (
  record_type             POSITION(01:01) CHAR-- "TRIM(:record_type)"
 ,control_id             "xx_po_poconv_stg_s.NEXTVAL"
 ,conv_action            "TRIM(:conv_action)"
 --CONSTANT "CREATE"
 --,control_id             "xx_po_poconv_stg_s.NEXTVAL"
 ,source_system_ref      "TRIM(:source_system_ref)"
 ,line_num               "TRIM(:line_num)"
 ,item                   "TRIM(:Item)"
 ,quantity               "TRIM(:quantity)"
 ,ship_to_location       "TRIM(:ship_to_location)"
 ,need_by_date           "TO_DATE(TRIM(:need_by_date),'MM-DD-YY')" 
--CHAR"TRIM(:need_by_date)"
 ,promised_date          "TO_DATE(TRIM(:promised_date),'MM-DD-YY')" --CHAR"TRIM(:promised_date)"
 ,line_reference_num     "TRIM(:line_reference_num)"
 ,uom_code               "TRIM(:uom_code)"
 ,unit_price             "TRIM(:unit_price)"
 ,line_attribute6        "TRIM(:line_attribute6)"
 ,dept                   "TRIM(:dept)"
 ,class                  "TRIM(:class)"
 ,vendor_product_code    "TRIM(:vendor_product_code)"
 ,extended_cost          "TRIM(:extended_cost)"
 ,qty_shipped            "TRIM(:qty_shipped)"
 ,qty_received           "TRIM(:qty_received)"
 ,seasonal_large_order   "TRIM(:seasonal_large_order)"
 ,interface_line_id      "po_lines_interface_s.NEXTVAL"
 ,interface_header_id    "po_headers_interface_s.CURRVAL"
 ,shipment_num           CONSTANT "1"
 --,control_id             "xx_po_poconv_stg_s.NEXTVAL"
 ,source_system_code     CONSTANT "ODPO"
 ,Process_flag     CONSTANT "1"
 )
