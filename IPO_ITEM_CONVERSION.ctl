-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : ITEM_CONVERSION                                     |
-- | Description : To load values to the translation -                 |
-- |               IPO_ITEM_CONVERSION. The table that is being loaded |
-- |               is XX_FIN_TRANSLATEVALUES                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ===========  =============        =======================|
-- |1.0       29-JAN-2008  Radhika Raman,       Initial version        |
-- |                       Wipro Technologies                          |
-- +===================================================================+

LOAD DATA
INTO TABLE XX_FIN_TRANSLATEVALUES APPEND
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(    
     enabled_flag                "TRIM(:enabled_flag)"
    ,start_date_active           "TO_DATE(TRIM(:start_date_active),'MM/DD/YYYY')" 
    ,end_date_active             
    ,source_value1               "TRIM(:source_value1)"
    ,target_value1               "TRIM(:target_value1)"
    ,target_value2               "TRIM(:target_value2)"
    ,target_value3               "TRIM(:target_value3)"
    ,target_value4               "TRIM(:target_value4)"
    ,target_value5               "TRIM(:target_value5)"
    ,target_value6               "TRIM(:target_value6)"
    ,target_value7               "TRIM(:target_value7)"
    ,target_value8               "TRIM(:target_value8)"
    ,target_value9               "TRIM(:target_value9)"
    ,target_value10              "TRIM(:target_value10)"
    ,target_value11              "TRIM(:target_value11)"
    ,target_value12              "TRIM(:target_value12)"
    ,target_value13              "TRIM(:target_value13)"
    ,target_value14              "TRIM(:target_value14)"
    ,target_value15              "REPLACE(TRIM(:target_value15),CHR(13),'')"
    ,target_value16              "TRIM(:target_value16)"
    ,target_value17              "TRIM(:target_value17)"
    ,target_value18              "REPLACE(TRIM(:target_value18),CHR(13),'')"
    ,translate_id                CONSTANT '82'     
    ,translate_value_id          "xx_fin_translatevalues_s.nextval"  
    ,CREATED_BY                  "41106"  
    ,LAST_UPDATED_BY             "41106"  
    ,creation_date               SYSDATE  
    ,last_update_date            SYSDATE    
)