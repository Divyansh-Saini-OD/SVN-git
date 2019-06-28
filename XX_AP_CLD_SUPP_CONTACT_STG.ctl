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
-- |DRAFT 1A   27-JUN-2019   Priyam Parmar          Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

OPTIONS(SKIP=1)
LOAD DATA
APPEND
INTO TABLE XX_AP_CLD_SUPP_CONTACT_STG
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    ( 
SUPPLIER_NUMBER   ,
SUPPLIER_NAME      CHAR"TRIM(:SUPPLIER_NAME)",
VENDOR_SITE_CODE   CHAR"TRIM(:VENDOR_SITE_CODE)",
INACTIVE_DATE   ,
FIRST_NAME         CHAR"TRIM(:FIRST_NAME)",
MIDDLE_NAME        CHAR"TRIM(:MIDDLE_NAME)",
LAST_NAME          CHAR"TRIM(:LAST_NAME)",
TITLE              CHAR"TRIM(:TITLE)",
AREA_CODE          CHAR"TRIM(:AREA_CODE)",
PHONE              CHAR"TRIM(:PHONE)",
EXTENSION          CHAR"TRIM(:EXTENSION)",
CONTACT_NAME_ALT   CHAR"TRIM(:CONTACT_NAME_ALT)",
EMAIL_ADDRESS      CHAR"TRIM(:EMAIL_ADDRESS)",
FAX_AREA_CODE      CHAR"TRIM(:FAX_AREA_CODE)",
FAX                CHAR"TRIM(:FAX)",
PRIMARY_ADDR_IND   CHAR"TRIM(:PRIMARY_ADDR_IND)",
ADD_1              CHAR"TRIM(:ADD_1)",
ADD_2              CHAR"TRIM(:ADD_2)",
ADD_3              CHAR"TRIM(:ADD_3)",
CITY               CHAR"TRIM(:CITY)",
STATE              CHAR"TRIM(:STATE)",
COUNTRY_ID         CHAR"TRIM(:COUNTRY_ID)",
POST               CHAR"TRIM(:POST)",
CONTACT_TELEX      CHAR"TRIM(:CONTACT_TELEX)",
OD_PHONE_800_NBR   CHAR"TRIM(:OD_PHONE_800_NBR)",
OD_COMMENT_1       CHAR"TRIM(:OD_COMMENT_1)",
OD_COMMENT_2       CHAR"TRIM(:OD_COMMENT_2)",
OD_EMAIL_IND_FLG   CHAR"TRIM(:OD_EMAIL_IND_FLG)",
OD_SHIP_FROM_ADDR_ID   CHAR"TRIM(:OD_SHIP_FROM_ADDR_ID)",
ADDRESS_TYPE       CHAR"TRIM(:ADDRESS_TYPE)",
SEQ_NO             CHAR"TRIM(:SEQ_NO)",
CONT_TARGET CONSTANT "EBS",
CONTACT_PROCESS_FLAG CONSTANT "1",
PROCESS_FLAG      CONSTANT "N",
 created_by       CONSTANT "-1",
 creation_date    SYSDATE,
 last_update_date SYSDATE,
 last_updated_by  CONSTANT  "-1"
    )

