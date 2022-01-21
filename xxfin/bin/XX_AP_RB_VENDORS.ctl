-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : CREATE_XX_AP_RB_VENDOR_STG.tbl                                              |
-- | Rice Id      : I2170                                                                       |
-- | Description  : I2170_One time vendor conversion for customer rebate checks                 |
-- | Purpose      : Create Custom Table XX_AP_LOAD_VENDORS.ctl.                                 |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   13-MAR-2012   Bapuji Nanapaneni    Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

LOAD DATA
APPEND
INTO TABLE XXFIN.XX_AP_RB_VENDOR_STG
FIELDS TERMINATED BY "|"
OPTIONALLY ENCLOSED BY '"'
    ( vendor_name
    , customer_num
    , site_address1
    , site_address2
    , site_city
    , site_state
    , site_zip
    , created_by       CONSTANT "-1"
    , creation_date    SYSDATE
    , last_update_date SYSDATE
    , last_updated_by  CONSTANT  "-1"
    )

