-- +============================================================================================+
-- |                        Office Depot - Project Beacon                                       |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_AP_CLD_SUPP_CONTACT_STG.ctl                                              |
-- | Rice Id      : I                                                                           |
-- | Description  : Vendor Interface from Cloud                                                 |
-- | Purpose      : Load Supplier Contacts                                                      |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   24-JUN-2019   Arun DSouza          Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

LOAD DATA
APPEND
INTO TABLE XX_AP_CLD_SUPP_CONTACT_STG
WHEN (SUPPLIER_NAME <> 'SUPPLIER_NAME')
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
    ( 
SUPPLIER_NUMBER,
SUPPLIER_NAME,
VENDOR_SITE_CODE,
INACTIVE_DATE,
FIRST_NAME,
MIDDLE_NAME,
LAST_NAME,
TITLE,
AREA_CODE,
PHONE,
EXTENSION,
CONTACT_NAME_ALT,
EMAIL_ADDRESS,
FAX_AREA_CODE,
FAX,
PRIMARY_ADDR_IND,
ADD_1,
ADD_2,
ADD_3,
CITY,
STATE,
COUNTRY_ID,
POST,
CONTACT_TELEX,
OD_PHONE_800_NBR,
OD_COMMENT_1,
OD_COMMENT_2,
OD_EMAIL_IND_FLG,
OD_SHIP_FROM_ADDR_ID,
ADDRESS_TYPE,
SEQ_NO,
CONT_TARGET CONSTANT "EBS",
CONTACT_PROCESS_FLAG CONSTANT "1",
PROCESS_FLAG      CONSTANT "N",
 created_by       CONSTANT "-1",
 creation_date    SYSDATE,
 last_update_date SYSDATE,
 last_updated_by  CONSTANT  "-1"
    )

