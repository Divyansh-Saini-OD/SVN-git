-- +===================================================================================+
-- |                              Office Depot                                         |
-- |                                                                                   |
-- +===================================================================================+
-- | Name        : XX_CDH_AOPS_EXTERNAL_USER_CTL.ctl                                   |
-- | Description : Control File to load data into Table for XX_CDH_AOPS_EXTERNAL_USERS |
-- | Rice Name: E1328                                                                  |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date         Author         Remarks                                      |
-- |========  ===========  =============  =============================================|
-- |1.0       31-DEC-2018  Havish Kasina  Initial draft version                        |
-- +===================================================================================+

LOAD DATA
INFILE *
INTO TABLE XX_CDH_AOPS_EXTERNAL_USERS
REPLACE
FIELDS TERMINATED BY X'9'
TRAILING NULLCOLS
  (CONTACT_OSR                           "LTRIM(RTRIM(:CONTACT_OSR,CHR(34)), CHR(34))",                                 
   WEBUSER_OSR                           "LTRIM(RTRIM(:WEBUSER_OSR,CHR(34)), CHR(34))", 
   USERID                                "LTRIM(RTRIM(:USERID, CHR(34)), CHR(34))",
   ACCT_SITE_OSR                         "LTRIM(RTRIM(:ACCT_SITE_OSR,CHR(34)), CHR(34))",
   RECORD_TYPE                           "LTRIM(RTRIM(:RECORD_TYPE, CHR(34)), CHR(34))",
   ACCESS_CODE                           "LTRIM(RTRIM(:ACCESS_CODE, CHR(34)), CHR(34))",
   BRAND_CODE                            "LTRIM(RTRIM(:BRAND_CODE, CHR(34)), CHR(34))",
   PASSWORD                              "LTRIM(RTRIM(:PASSWORD, CHR(34)), CHR(34))",
   STATUS                                "LTRIM(RTRIM(:STATUS, CHR(34)), CHR(34))",
   PWD_EXPIRATION_DAYS                   "TO_NUMBER(LTRIM(RTRIM(:PWD_EXPIRATION_DAYS, CHR(34)), CHR(34)))",
   PWD_EXPIRATION_DATE                   "TO_DATE(LTRIM(RTRIM(:PWD_EXPIRATION_DATE, CHR(34)), CHR(34)),'YYYY-MM-DD')",     
   PERSON_FIRST_NAME                     "LTRIM(RTRIM(:PERSON_FIRST_NAME, CHR(34)), CHR(34))",
   PERSON_LAST_NAME                      "LTRIM(RTRIM(:PERSON_LAST_NAME, CHR(34)), CHR(34))",
   PERSON_MIDDLE_NAME                    "LTRIM(RTRIM(:PERSON_MIDDLE_NAME, CHR(34)), CHR(34))",
   EMAIL                                 "LTRIM(RTRIM(:EMAIL, CHR(34)), CHR(34))",
   PERMISSION_FLAG                       "LTRIM(RTRIM(:PERMISSION_FLAG, CHR(34)), CHR(34))",
   PWD_LAST_CHANGE                       "TO_DATE(SUBSTR(LTRIM(RTRIM(:PWD_LAST_CHANGE, CHR(34)), CHR(34)),1,10),'YYYY-MM-DD')",  
   LOAD_STATUS                CONSTANT   'N',  
   CREATED_BY                            "FND_GLOBAL.USER_ID",        
   CREATION_DATE                         "SYSDATE",       
   LAST_UPDATED_BY                       "FND_GLOBAL.USER_ID",   
   LAST_UPDATE_DATE                      "SYSDATE",      
   LAST_UPDATE_LOGIN                     "FND_GLOBAL.LOGIN_ID",
   REQUEST_ID                            "FND_GLOBAL.CONC_REQUEST_ID",
   EXTERNAL_USERS_STG_ID                 "XX_EXTERNAL_USERS_STG_S.nextval")       