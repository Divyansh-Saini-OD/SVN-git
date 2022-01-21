-- +===========================================================================+
-- |                              Office Depot                                 |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : XX_SCM_BILL_SIGNAL_CTL.ctl                                  |
-- | Description :                                                             |
-- | Control File to load data into Table for XX_SCM_BILL_SIGNAL               |
-- | Rice Name: I3126                                                          |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date         Author         Remarks                              |
-- |========  ===========  =============  =====================================|
-- |1.0       09-OCT-2018  Havish Kasina  Initial draft version                |
-- +===========================================================================+

OPTIONS (SKIP=1)

LOAD DATA

APPEND

INTO TABLE XX_SCM_BILL_SIGNAL

FIELDS TERMINATED BY '|' OPTIONALLY ENCLOSED BY '""'

TRAILING NULLCOLS 

  (PARENT_ORDER_NUMBER                   "LTRIM(RTRIM(:PARENT_ORDER_NUMBER, CHR(34)), CHR(34))",
   CHILD_ORDER_NUMBER                    "LTRIM(RTRIM(:CHILD_ORDER_NUMBER, CHR(34)), CHR(34))",
   SHIPPED_FLAG                          "LTRIM(RTRIM(:SHIPPED_FLAG, CHR(34)), CHR(34))",
   COST_CENTER                           "LTRIM(RTRIM(:COST_CENTER, CHR(34)), CHR(34))",
   BILLING_DATE_FLAG          CONSTANT   'N' ,
   CREATED_BY                            "FND_GLOBAL.USER_ID",                    
   CREATION_DATE                         "SYSDATE",       
   LAST_UPDATED_BY                       "FND_GLOBAL.USER_ID",   
   LAST_UPDATE_DATE                      "SYSDATE",      
   LAST_UPDATE_LOGIN                     "FND_GLOBAL.LOGIN_ID",
   REQUEST_ID                            "FND_GLOBAL.CONC_REQUEST_ID")