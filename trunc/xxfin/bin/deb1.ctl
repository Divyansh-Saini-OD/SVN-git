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
--  source_value2   char,
--  source_value3   char,
--  source_value4   char,
--  source_value5   char,
--  source_value6   char,
--  source_value7   char,
--  source_value8   char,
--  source_value9   char,
--  source_value10   char,
  target_value1   char,
  --target_value2   char,
--target_value3   char,
  --target_value4   char,
  --target_value5   char,
  --target_value6   char,
  --target_value7  char,
  --target_value8   char,
  --target_value9   char,
  --target_value10   char,
  --target_value11   char,
  --target_value12   char,
  --target_value13   char,
  --target_value14   char,
  --target_value15   char,
  --target_value16   char,
  --target_value17   char,
  --target_value18   char,
  --target_value19   char,
  --target_value20   char,
  enabled_flag    char
)
