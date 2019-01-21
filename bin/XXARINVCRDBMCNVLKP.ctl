-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      OD: AR Transaction Lookup Loading                     |
-- | Description : To load the Salesperson, Payment term mapping values|
-- |               from MARS to ORACLE into the common conversion      |
-- |               lookup table XX_COM_VALUE_TRANS_LKP                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       03-JAN-2006  Gowri Shankar,       Initial version        |
-- |                       Wipro Technologies                          |
-- +===================================================================+

LOAD DATA
INFILE *
INSERT 
INTO TABLE xx_com_value_trans_lkp APPEND
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
     lookup_name
    ,lookup_value
    ,translated_value
    ,translation_description
    ,source_system_code CONSTANT 'MARS'
    ,creation_date SYSDATE
    ,last_update_date SYSDATE
    ,created_by CONSTANT '-1'
    ,last_updated_by CONSTANT '-1'
)