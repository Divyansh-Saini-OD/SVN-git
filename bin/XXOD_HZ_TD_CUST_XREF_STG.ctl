-- +======================================================================================================+
-- |                                  Oracle Consulting Services                                          |
-- +======================================================================================================+
-- |                                                                                                      |
-- | Object Name                  : XXOD_HZ_TD_CUST_XREF_STG.ctl                                          |
-- |                                                                                                      |
-- | Program Name                 : OD Customer cross reference loader to staging                         |
-- |                                                                                                      |
-- | Description                  : Loader script to load the data into the staging table                 |
-- |                                XXOD_HZ_TD_CUST_XREF_STG                                              |
-- |                                                                                                      |
-- | Change Record:                                                                                       |
-- | ==============                                                                                       |
-- | Version     Date          Author               Remarks                                               |
-- | ========    ===========   =================    ==========================                            |
-- | 1.0         05-Feb-2014   Veronica Mairembam   Initial Draft Version                                 |
-- +======================================================================================================+
OPTIONS (SKIP=1)
LOAD DATA
APPEND INTO TABLE XXCRM.XXOD_HZ_TD_CUST_XREF_STG
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
    AOPS_CUSTNO                          CHAR (60)"TRIM(:AOPS_CUSTNO)"
   ,AOPS_CUSTNAME                        CHAR (240) "TRIM(:AOPS_CUSTNAME)"
   ,TD_CUSTNO                            CHAR (60) "TRIM(:TD_CUSTNO)"
   ,CRMFUSION_MFDELETION                 CHAR (30)"TRIM(:CRMFUSION_MFDELETION)" 
   ,CRMFUSION_SELECTSET                  CHAR (30)"TRIM(:CRMFUSION_SELECTSET)"
   ,START_DATE                           DATE  'MM/DD/YYYY'          
   ,END_DATE                             DATE  'MM/DD/YYYY'          
   ,INTERFACE_STATUS                     CHAR (10)"TRIM(:INTERFACE_STATUS)"   
   ,CREATED_BY                           "FND_GLOBAL.USER_ID"                    
   ,CREATION_DATE                        "TRUNC (SYSDATE)"        
   ,LAST_UPDATED_BY                      "FND_GLOBAL.USER_ID"   
   ,LAST_UPDATE_DATE                     "TRUNC (SYSDATE)"      
   ,LAST_UPDATE_LOGIN                    "FND_GLOBAL.LOGIN_ID"
   ,BATCH_ID                             CONSTANT 99999999999999
   ,RECORD_ID                            "XXCRM.XXOD_CUST_XREF_RECORD_ID_S.nextval"
)
