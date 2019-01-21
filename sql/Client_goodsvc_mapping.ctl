LOAD DATA 
INFILE 'UNSPSC_GSC_Mapping_2.csv' 
BADFILE 'UNSPSC_GSC_Mapping_2.bad'
DISCARDFILE 'UNSPSC_GSC_Mapping_2.dsc'

TRUNCATE

INTO TABLE "CLIENT_GOODSVC_TEMP"

FIELDS TERMINATED BY ','
 OPTIONALLY ENCLOSED BY '"'

  (OU_CODE
, 
   CLIENT_SKU_START_CODE
, 
   CLIENT_SKU_END_CODE
, 
   GSC_ID
)
