LOAD DATA 
APPEND
INTO table XXOD_HZ_IMP_CLASSIFICS_INT
FIELDS TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
(
BATCH_ID                     INTEGER EXTERNAL,    
CLASS_CATEGORY              CHAR ,
CLASS_CODE                  CHAR ,
CREATED_BY                           INTEGER EXTERNAL    ,
CREATED_BY_MODULE                   CHAR ,
CREATION_DATE                        DATE ,         
END_DATE_ACTIVE                      DATE  ,        
ERROR_ID                             INTEGER EXTERNAL    ,
INSERT_UPDATE_FLAG                  CHAR  ,
INTERFACE_STATUS                    CHAR ,
LAST_UPDATE_DATE                     DATE ,         
LAST_UPDATE_LOGIN                    INTEGER EXTERNAL    ,
LAST_UPDATED_BY                      INTEGER EXTERNAL    ,
PARTY_ID                             INTEGER EXTERNAL    ,
PARTY_ORIG_SYSTEM                   CHAR ,
PARTY_ORIG_SYSTEM_REFERENCE         CHAR,
PRIMARY_FLAG                        CHAR , 
PROGRAM_APPLICATION_ID               INTEGER EXTERNAL    ,
PROGRAM_ID                           INTEGER EXTERNAL    ,
PROGRAM_UPDATE_DATE                  DATE          ,
RANK                                INTEGER EXTERNAL,        
REQUEST_ID                           INTEGER EXTERNAL,    
START_DATE_ACTIVE            DATE 
)
