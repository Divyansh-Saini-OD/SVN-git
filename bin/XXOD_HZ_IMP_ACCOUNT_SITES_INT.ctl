LOAD DATA 
APPEND
INTO table XXOD_HZ_IMP_ACCOUNT_SITES_INT
FIELDS TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
(
BATCH_ID                               INTEGER EXTERNAL,    
CREATED_BY                             INTEGER EXTERNAL,    
CREATED_BY_MODULE                      CHAR,  
CREATION_DATE                          DATE ,         
ERROR_ID                               INTEGER EXTERNAL,    
INSERT_UPDATE_FLAG                     CHAR,  
INTERFACE_STATUS                       CHAR,  
LAST_UPDATE_DATE                       DATE,          
LAST_UPDATE_LOGIN                      INTEGER EXTERNAL,    
LAST_UPDATED_BY                        INTEGER EXTERNAL,    
PROGRAM_APPLICATION_ID                 INTEGER EXTERNAL,    
PROGRAM_ID                             INTEGER EXTERNAL,    
PROGRAM_UPDATE_DATE                    DATE,          
REQUEST_ID                             INTEGER EXTERNAL,    
PARTY_ORIG_SYSTEM                      CHAR,  
PARTY_ORIG_SYSTEM_REFERENCE            CHAR, 
ACCOUNT_ORIG_SYSTEM                    CHAR,  
ACCOUNT_ORIG_SYSTEM_REFERENCE          CHAR, 
SITE_ORIG_SYSTEM                       CHAR,  
SITE_ORIG_SYSTEM_REFERENCE             CHAR, 
ADDRESS_ATTRIBUTE_CATEGORY             CHAR,  
ADDRESS_ATTRIBUTE1                     CHAR,
ADDRESS_ATTRIBUTE2                     CHAR,
ADDRESS_ATTRIBUTE3                     CHAR,
ADDRESS_ATTRIBUTE4                     CHAR,
ADDRESS_ATTRIBUTE5                     CHAR,
ADDRESS_ATTRIBUTE6                     CHAR,
ADDRESS_ATTRIBUTE7                     CHAR,
ADDRESS_ATTRIBUTE8                     CHAR,
ADDRESS_ATTRIBUTE9                     CHAR,
ADDRESS_ATTRIBUTE10                    CHAR,
ADDRESS_ATTRIBUTE11                    CHAR,
ADDRESS_ATTRIBUTE12                    CHAR,
ADDRESS_ATTRIBUTE13                    CHAR,
ADDRESS_ATTRIBUTE14                    CHAR,
ADDRESS_ATTRIBUTE15                    CHAR,
ADDRESS_ATTRIBUTE16                    CHAR,
ADDRESS_ATTRIBUTE17                    CHAR,
ADDRESS_ATTRIBUTE18                    CHAR,
ADDRESS_ATTRIBUTE19                    CHAR,
ADDRESS_ATTRIBUTE20                    CHAR,
ADDRESS_CATEGORY_CODE                  CHAR , 
BILL_TO_ORIG_ADDRESS_REF               CHAR ,
GDF_ADDRESS_ATTR_CAT                   CHAR  ,
GDF_ADDRESS_ATTRIBUTE1                 CHAR,
GDF_ADDRESS_ATTRIBUTE2                 CHAR,
GDF_ADDRESS_ATTRIBUTE3                 CHAR,
GDF_ADDRESS_ATTRIBUTE4                 CHAR,
GDF_ADDRESS_ATTRIBUTE5                 CHAR,
GDF_ADDRESS_ATTRIBUTE6                 CHAR,
GDF_ADDRESS_ATTRIBUTE7                 CHAR,
GDF_ADDRESS_ATTRIBUTE8                 CHAR,
GDF_ADDRESS_ATTRIBUTE9                 CHAR,
GDF_ADDRESS_ATTRIBUTE10                CHAR,
GDF_ADDRESS_ATTRIBUTE11                CHAR,
GDF_ADDRESS_ATTRIBUTE12                CHAR,
GDF_ADDRESS_ATTRIBUTE13                CHAR,
GDF_ADDRESS_ATTRIBUTE14                CHAR,
GDF_ADDRESS_ATTRIBUTE15                CHAR,
GDF_ADDRESS_ATTRIBUTE16                CHAR,
GDF_ADDRESS_ATTRIBUTE17                CHAR,
GDF_ADDRESS_ATTRIBUTE18                CHAR,
GDF_ADDRESS_ATTRIBUTE19                CHAR,
GDF_ADDRESS_ATTRIBUTE20                CHAR,
SITE_SHIP_VIA_CODE                     CHAR , 
LOCATION                               CHAR,
LOCATION_CCID                          INTEGER EXTERNAL,    
ACCT_SITE_ORIG_SYSTEM_REF              CHAR ,
ACCT_SITE_ORIG_SYSTEM                  CHAR  ,
ORG_ID                                 INTEGER EXTERNAL
)
