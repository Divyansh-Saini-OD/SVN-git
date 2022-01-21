-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        :   XX_CE_BANK_TRX_CODES                                                  |
-- | Description :   Bank transaction codes description.                                                  |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       18-MAR-2008  Ranjith Prabu T      Loading for translate id |
-- |                                            209                    |
-- +===================================================================+

LOAD DATA
INTO TABLE XX_FIN_TRANSLATEVALUES APPEND
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(

     source_value1      
    ,target_value1 "REPLACE(TRIM(:target_value1),CHR(13),'')"
    ,translate_id  CONSTANT '209'
    ,translate_value_id   "xx_fin_translatevalues_s.nextval"
    ,creation_date SYSDATE
    ,last_update_date SYSDATE
    ,created_by CONSTANT '-1'
    ,last_updated_by CONSTANT '-1'
    ,enabled_flag CONSTANT 'Y'
    ,start_date_active SYSDATE
)
