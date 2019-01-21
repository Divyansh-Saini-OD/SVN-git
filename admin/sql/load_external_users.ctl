LOAD DATA
INFILE '/home/app/module/xxcrm/input/p1'
BADFILE '/home/app/module/xxcrm/logs/p1.bad'
DISCARDFILE '/home/app/module/xxcrm/logs/p1.dsc'
APPEND
INTO TABLE xxcrm.xx_external_users
fields terminated by X'09'
trailing nullcols
( 
, USERID,  
, PASSWORD,  
, ACCT_OSR, 
, CONTACT_OSR 
, PERSON_FIRST_NAME,  
, PERSON_LAST_NAME,  
, PERSON_MIDDLE_NAME,  
, EMAIL,  
, BSD_ACCESS_CODE 
, SITE_KEY            constant    001
, END_DATE                       
, LOAD_STATUS         constant    "CONVERTED"
, USER_LOCKED                    
, CREATED_BY          constant    1            
, CREATION_DATE                  
, LAST_UPDATE_DATE               
, LAST_UPDATED_BY                
, LAST_UPDATE_LOGIN   constant    1           
)
