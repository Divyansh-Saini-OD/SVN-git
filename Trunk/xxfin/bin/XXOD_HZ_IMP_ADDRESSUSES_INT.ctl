LOAD DATA 
APPEND
INTO table XXOD_HZ_IMP_ADDRESSUSES_INT
FIELDS TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
(
BATCH_ID                            INTEGER EXTERNAL,    
CREATED_BY                          INTEGER EXTERNAL ,   
CREATED_BY_MODULE                   CHAR,
CREATION_DATE                       DATE ,         
ERROR_ID                            INTEGER EXTERNAL,    
INSERT_UPDATE_FLAG                  CHAR,   
INTERFACE_STATUS                    CHAR,
LAST_UPDATE_DATE                    DATE,          
LAST_UPDATE_LOGIN                   INTEGER EXTERNAL,    
LAST_UPDATED_BY                     INTEGER EXTERNAL,    
PARTY_ORIG_SYSTEM                   CHAR,
PARTY_ORIG_SYSTEM_REFERENCE         CHAR,
PRIMARY_FLAG                        CHAR,   
PROGRAM_UPDATE_DATE                 DATE,          
REQUEST_ID                          INTEGER EXTERNAL,    
SITE_ORIG_SYSTEM                    CHAR,
SITE_ORIG_SYSTEM_REFERENCE          CHAR,
SITE_USE_TYPE                       CHAR 
)
