LOAD DATA
APPEND
INTO TABLE XX_FA_TAX_INTERFACE_STG
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
( junk1 filler,
  PWC_BOOK_DESC,
  junk2 filler,
  junk3 filler,
  junk4 filler,
  PWC_ASSET_NBR,
  junk5 filler,
  junk6 filler,
  PWC_ASSET_CLASS_DESC, 
  PWC_RATE,
  PWC_LIFE,
  PWC_CONVENTION,
  PWC_DESCRIPTION,
  junk8 filler,
  PWC_IN_SERVICE_DATE,
  junk9 filler,
  junk10 filler,
  junk11 filler,
  junk12 filler,
  junk13 filler,
  PWC_INITIAL_TAX_COST,
  junk14 filler,
  junk15 filler,
  junk16 filler,
  junk17 filler,
  PWC_ACCUM_DEPRN,
  BOOK CONSTANT "BK3" 
)