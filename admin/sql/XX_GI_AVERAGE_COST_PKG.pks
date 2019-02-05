SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_GI_AVERAGE_COST_PKG  AUTHID CURRENT_USER
-- +==============================================================================================+
-- |                  Office Depot - Project Simplify                                             |
-- |      Oracle NAIO/Office Depot/Consulting Organization                                        |
-- +==============================================================================================+
-- | Name       : XX_GI_AVERAGE_COST_PKG                                                          |
-- |                                                                                              |
-- | Description: The Average Cost Update Program allows to update average costs.                 |
-- |                                                                                              |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version   Date        Author           Remarks                                                |
-- |=======   ==========  =============    =======================================================|
-- |DRAFT 1A 15-JUN-2007  Meenu Goyal      Initial draft version                                  |
-- |DRAFT 1B 13-AUG-2007  Jayshree         Reviewed and updated                                   |
-- |DRAFT 1C 13-AUG-2007  Meenu Goyal      Incorporated the review comments                       |
-- |DRAFT 1D 18-SEP-2007  Meenu Goyal      Incorporated the new requirment changes for template2  |
-- |                                       Template formats matching as per the MD 50             |
-- |1.0      21-SEP-2007  Jayshree         Baselined                                              |
-- |1.1      5-OCT-2007   Meenu Goyal      Incorporated CR Changes                                |
-- |1.2      22-Oct-2007  Jayshree         Reviewed and updated                                   |
-- +==============================================================================================+

AS

--**************************
--Declaring Global variables
--**************************

--Global variables used for error ,success  anf failure status  

GC_REC_STATUS_ERR          CONSTANT VARCHAR2(1)     := 'E';
GC_REC_STATUS_SUCC         CONSTANT VARCHAR2(1)     := 'S';
GC_REC_STATUS_FAIL         CONSTANT VARCHAR2(1)     := 'F';

--Global variables used for marking the record status in the staging table

GC_VAL_SUCC                CONSTANT VARCHAR2(2)     := 'VS';
GC_VAL_ERR                 CONSTANT VARCHAR2(2)     := 'VE';
GC_INT_ERR                 CONSTANT VARCHAR2(2)     := 'IE';

--Global variables used for assigning program values for inserting in the common error table

GC_PROGRAM_TYPE            CONSTANT VARCHAR2(20)    := 'CUSTOM_EXTENSION' ;
GC_PROGRAM_NAME            CONSTANT VARCHAR2(22)    := 'XX_GI_AVERAGE_COST_PKG';
GC_MODULE_NAME             CONSTANT VARCHAR2(20)    := 'GI';
GC_NOTIFY                  CONSTANT VARCHAR2(1)     := 'Y';
GC_MAJOR                   CONSTANT VARCHAR2(5)     := 'MAJOR';
                                     
--Global variable used for assigning the list values

GC_LIST1                   CONSTANT VARCHAR2(20)    := 'LIST ALL VALUES' ;
GC_LIST2                   CONSTANT VARCHAR2(20)    := 'LIST ORG ITEMS'  ;

--Global variable used for assigning the file id

GN_FILE_ID                           NUMBER         := NULL;

--Global variable used for counting the total number of validation error.

GN_ERROR_COUNT                      VARCHAR2(100)    := NULL;

GV_SEPERATOR                  CONSTANT VARCHAR2(1)   := ',';
GC_ERR_CODE_STR                        VARCHAR2(4000);
GC_MSG_ERR_STR                         VARCHAR2(4000);

--Global variable used for assigning the active value 

GC_ACTIVE                  CONSTANT VARCHAR2(10)    := 'Active'; 

--Global variable used for assigning F for deriving the onhand quantity
GC_F                       CONSTANT VARCHAR2(1)     := 'F';

--Global variable used for assigning item type

GC_ITEM_TYPE               CONSTANT VARCHAR2(20)     := 'XXGIAVGC';

--Global variable used for assigning the approver and requestor id

GN_REQUESTOR_ID                     NUMBER          :=  FND_GLOBAL.USER_ID;
GN_APPROVER_ID                      NUMBER          :=  NULL              ;

--Global variable used for assigning value for checking if org is Primary cost org or not

GC_LOOKUP_TYPE             CONSTANT VARCHAR2(20)    := 'MTL_PRIMARY_COST';
GC_MEANING                 CONSTANT VARCHAR2(20)    :=  'Average';

--Global variable used for inserting the values in MTI Table

GC_SOURCE_NAME             CONSTANT VARCHAR2(20)    :=  'OD';  
GN_PROCESS_FLAG            CONSTANT NUMBER          :=  1;  
GN_TRANSACTION_MODE        CONSTANT NUMBER          :=  3; 
GN_LOCK_FLAG               CONSTANT NUMBER          :=  2; 
GN_USER_ID                          NUMBER          :=  FND_GLOBAL.USER_ID;

--Global variable used for assigning the TRUE or FALSE values

GC_TRUE                    CONSTANT VARCHAR2(10)    := 'TRUE';
GC_FALSE                   CONSTANT VARCHAR2(10)    := 'FALSE';

--Global variable used for assigning the value sets name to derive the flex values

GC_COMP_SET_NAME           CONSTANT VARCHAR2(20)    := 'XX_GI_COMPANY' ;
GC_CHAIN_SET_NAME          CONSTANT VARCHAR2(20)    := 'XX_GI_CHAIN_VS' ;
GC_AREA_SET_NAME           CONSTANT VARCHAR2(20)    := 'XX_GI_AREA_VS';
GC_REGION_SET_NAME         CONSTANT VARCHAR2(20)    := 'XX_GI_REGION_VS' ;
GC_DISTRICT_SET_NAME       CONSTANT VARCHAR2(20)    :=  'XX_GI_DISTRICT_VS'  ;



--Global variable used for assigning the unix path 

GC_FILE_PATH              CONSTANT VARCHAR2(250)    := FND_PROFILE.VALUE('XX_GI_WAC_TEMP_UPLOAD');--'/app/ebs/ctgsidev03/utl_file_out';



TYPE insert_store_type IS RECORD (
                                  rec_index  NUMBER
                                 ,store      VARCHAR2(240)
                                 );

TYPE insert_store_table1 IS TABLE OF insert_store_type INDEX BY BINARY_INTEGER;

insert_store_table   insert_store_table1;   



--Procedure to Get the average cost details from fnd_lobs

PROCEDURE GET_AVERAGE_COST_DETAILS  (p_file_id       IN   NUMBER   
                                   , x_status        OUT  VARCHAR2 
                                   , x_error_count   OUT  VARCHAR2
                                    );
                                    
--Procedure to load the average cost details to staging table

PROCEDURE LOAD_AVERAGE_COST_DETAILS (p_file_id       IN   NUMBER    
                                     ,x_status        OUT  VARCHAR2  
                                     ,x_error_count   OUT  VARCHAR2
                                     ) ;                                    

--Procedure to validate the records in the staging table

PROCEDURE VALIDATE_AVERAGE_COST_DETAILS  (p_file_id       IN   NUMBER    
                                         ,x_status        OUT  VARCHAR2 
                                         ,x_error_count   OUT  VARCHAR2
                                         ); 
                                         
 --Procedure to send a notification to the approver
 
PROCEDURE CHECK_APPROVER    (ItemType       IN   VARCHAR2
                            ,ItemKey        IN   VARCHAR2
                            ,Actid          IN   NUMBER
                            ,funcmode       IN   VARCHAR2
                            ,resultout      OUT  VARCHAR2
                             );

 --Procedure to insert the data in MTL_TRANSACTIONS_INTERFACE                      
                            
PROCEDURE INSERT_AVERAGE_COST_DETAILS  (ItemType       IN   VARCHAR2
                                       ,ItemKey        IN   VARCHAR2
                                       ,Actid          IN   NUMBER
                                       ,funcmode       IN   VARCHAR2
                                       ,resultout      OUT  VARCHAR2
                                       );                      

 --Procedure to write a document to be sent with the notification that would contain the validated records
 
PROCEDURE GET_VALID_AVERAGE_COST_DETAILS (DOCUMENT_ID   IN NUMBER
                                          ,DISPLAY_TYPE  IN VARCHAR2
                                          ,DOCUMENT      IN OUT CLOB
                                          ,DOCUMENT_TYPE IN OUT VARCHAR2
                                          ); 



 --Procedure to derive the onhand quantity
 
PROCEDURE ONHAND_QUANTITY_API  (p_organization_id    IN           NUMBER
                               ,p_inventory_item_id  IN           NUMBER
                               ,p_item_number        IN           VARCHAR2
                               ,x_qty_onhand         OUT NOCOPY   NUMBER
                               ,x_return_code        OUT NOCOPY   NUMBER
                               ,x_return_msg         OUT NOCOPY   VARCHAR2
                              ) ;

                                          

 --Procedure to validate and show the Template2 details in the output 
 
PROCEDURE VALIDATE_TEMPLATE2_DETAILS (
                                      X_ERRBUF         OUT VARCHAR2,
                                      X_RETCODE        OUT NUMBER  ,
                                      P_LIST           IN VARCHAR2,
                                      P_COUNTRY        IN VARCHAR2,
                                      P_TYPE_CODE      IN VARCHAR2,
                                      P_SUBTYPE_CODE   IN VARCHAR2,
                                      P_DIVISION_CODE  IN VARCHAR2,
                                      P_DISTRICT_CODE  IN VARCHAR2,
                                      P_COMPANY_CODE   IN VARCHAR2,
                                      P_CHAIN_CODE     IN VARCHAR2,
                                      P_AREA_CODE      IN VARCHAR2,
                                      P_REGION_CODE    IN VARCHAR2,
                                      P_SKU            IN VARCHAR2
                                      );
                                      
 --Procedure to write a document displaying the total WAC impact on the ORGS and ITEMS.
 
PROCEDURE GET_WAC_IMPACT_REPORT  (
                                  DOCUMENT_ID        IN NUMBER
                                 ,DISPLAY_TYPE       IN VARCHAR2
                                 ,DOCUMENT           IN OUT CLOB
                                 ,DOCUMENT_TYPE      IN OUT VARCHAR2
                                );    
                                
--Procedure to update the status of the record to success or failure

PROCEDURE UPDATE_RECORD (p_organization_id              IN     NUMBER,                                
                         p_master_organization_id       IN     NUMBER,                                
                         p_default_cost_group_id        IN     NUMBER,                                
                         p_material_account             IN     NUMBER,                                
                         p_material_overhead_account    IN     NUMBER,                                
                         p_resource_account             IN     NUMBER,                                
                         p_outside_processing_account   IN     NUMBER,                                
                         p_overhead_account             IN     NUMBER,                                
                         p_inventory_item_id            IN     NUMBER,                                
                         x_status                       IN OUT VARCHAR2,                                
                         p_primary_uom_code             IN     VARCHAR2,                                
                         p_approver_id                  IN     NUMBER,                                
                         p_qty_avail_to_reserve         IN     NUMBER,                                
                         p_item_cost                    IN     NUMBER,                                
                         p_rowid                        IN     VARCHAR2,                                
                         p_error_code                   IN     VARCHAR2,                                
                         p_error_message                IN     VARCHAR2) ;                               
                                
                                
--Procedure to validate the record and derive stores based on the org parameters

PROCEDURE STORE_INFORMATION
                     ( p_currency        IN       VARCHAR2    ,                                
                       p_file_id         IN       NUMBER      ,                                
                       p_country         IN       VARCHAR2    ,                                
                       p_type_code       IN       VARCHAR2    ,                                
                       p_subtype_code    IN       VARCHAR2    ,                                          
                       p_division_code   IN       VARCHAR2    ,                                    
                       p_district_code   IN       VARCHAR2    , 
                       p_company_code    IN       PLS_INTEGER ,
                       p_chain_code      IN       PLS_INTEGER ,
                       p_area_code       IN       PLS_INTEGER ,
                       p_region_code     IN       PLS_INTEGER ,
                       p_store           IN       VARCHAR2    ,
                       p_sku             IN       VARCHAR2    ,
                       p_new_cost        IN       PLS_INTEGER ,
                     --  p_template_number IN       NUMBER      ,
                       x_status          OUT      VARCHAR2    ,
                       x_error_count     OUT      VARCHAR2
                       );


--Procedure to insert failed records into the staging table 

PROCEDURE INSERT_FAILED_RECORDS( p_file_id        IN  NUMBER,
                                 p_error_message  IN  VARCHAR2,
                                 p_error_code     IN  VARCHAR2,
                                 p_item_number    IN  VARCHAR,
                                 p_currency       IN  VARCHAR2,
                                 p_country        IN  VARCHAR2,
                                 p_average_cost   IN  NUMBER,                                 
                                 x_status         OUT VARCHAR2,
                                 x_error_count    OUT VARCHAR2,
                                 p_type_code      IN  VARCHAR2,
                                 p_subtype_code   IN  VARCHAR2,
                                 p_division_code  IN  VARCHAR2 ,
                                 p_district_code  IN  VARCHAR2 ,
                                 p_company_code   IN  NUMBER ,
                                 p_chain_code     IN  NUMBER,
                                 p_area_code      IN  NUMBER,
                                 p_region_code    IN  NUMBER
                                 ) ;                    
                       
                       
END  XX_GI_AVERAGE_COST_PKG;
/
SHOW ERRORS;
EXIT;