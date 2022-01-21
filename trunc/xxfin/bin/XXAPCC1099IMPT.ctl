-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :   OD: AP CC1099 Import Program (SQL *Loader Control file)  |
-- | Description : To Load the data from the file in XXFIN_DATA path   |
-- |               to the staging table XX_AP_CREDITCARD_1099_STG      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       02-APR-2007  Anusha Ramanujam     Initial version        |
-- +===================================================================+

LOAD DATA
APPEND
INTO TABLE XXFIN.XX_AP_CREDITCARD_1099_STG
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS 
(
 vendor_name
,tax_type
,tax_id
,address_line1
,address_line2
,city
,state
,postal
,withholding_amount         "replace(:withholding_amount,chr(13),'')"
,request_id                 "XX_AP_CC_1099_PKG.get_request_id" 
)