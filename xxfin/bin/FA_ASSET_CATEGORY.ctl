load data
infile 'FA_ASSET_CATEGORY.dat' 
append
into table xx_fin_translatevalues
fields terminated by ',' optionally enclosed by '"'
trailing nullcols
( start_date_active date,
  translate_value_id integer external,
  translate_id INTEGER EXTERNAL,
  source_value1   char,
  target_value1   char,
  enabled_flag    char
)
