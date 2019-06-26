-- +============================================================================================+
-- |                        Office Depot - Project BEACON                                       |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_AP_CLD_SUPP_BCLS_STG.ctl                                                 |
-- | Rice Id      :                                                                             |
-- | Description  : Vendor interface from Cloud                                                 |
-- | Purpose      : Load Business Classifications                                               |
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
INTO TABLE XXFIN.XX_AP_CLD_SUPP_BCLS_STG
WHEN (SUPPLIER_NAME <> 'SUPPLIER_NAME')
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
    ( 
SUPPLIER_NAME,
SUPPLIER_NUMBER,
CLASSIFICATION,
SUBCLASSIFICATION,
START_DATE,
CONFIRMED_ON,
PROCESS_FLAG     CONSTANT "N",
BCLS_PROCESS_FLAG CONSTANT "1"
)

