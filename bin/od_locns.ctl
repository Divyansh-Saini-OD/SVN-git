LOAD DATA
INTO TABLE xxmer_new_store_reloc_par_stg
TRUNCATE
FIELDS TERMINATED BY ';'
TRAILING NULLCOLS
(
  process_date        DATE "YYYY-MM-DD", 
  loc_id              CHAR "TRIM(:LOC_ID)", 
  store_dir_rcv_date  DATE "YYYY-MM-DD"
 )
