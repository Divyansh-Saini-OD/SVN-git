-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        :                                                     |
-- | Description :                                                     |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author            Remarks                  |
-- |=======   ==========   =============      =========================|
-- |1.0       16-Jan-2008  Rama Krishna K     Loading for translate id |
-- |                                            193                    |
-- |2.0       02-Feb-2008  Gowri Shankar      Changes for Defect 4084  |
-- |                                             to default Brand Code |
-- |                                                                   |
-- |3.0       07-Apr-2008  Rama Krishna K     Changed traslate id 202  |
-- |                                          for testing GSIPRFGB     |
-- +===================================================================+

LOAD DATA
INTO TABLE XX_FIN_TRANSLATEVALUES APPEND
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(

     source_value1          "'00'||:source_value1"
    ,source_value2
    ,source_value3         "REPLACE(TRIM(:source_value3),CHR(13),'')"
    ,source_value4         CONSTANT 'OD'     -- Changes for Defect 4084
    ,translate_id          CONSTANT '202'
    ,translate_value_id    "xx_fin_translatevalues_s.nextval"
    ,creation_date         SYSDATE
    ,last_update_date      SYSDATE
    ,created_by            CONSTANT  '-1'
    ,last_updated_by       CONSTANT '-1'
    ,enabled_flag          CONSTANT 'Y'
    ,start_date_active     SYSDATE
)
