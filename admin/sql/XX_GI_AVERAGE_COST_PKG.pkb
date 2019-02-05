SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_GI_AVERAGE_COST_PKG
AS
-- +==============================================================================================+
-- |                  Office Depot - Project Simplify                                             |
-- |      Oracle NAIO/Office Depot/Consulting Organization                                        |
-- +==============================================================================================+
-- | Name       : XX_GI_AVERAGE_COST_PKG                                                          |
-- |                                                                                              |
-- | Description: This package  is used to The Average Cost Update Program allows to              |
-- |              update average costs.                                                           |
-- |              1.This is done by extracting the Average Cost                                   |
-- |                data from a .csv file,                                                        |
-- |              2.Perform validations and derivations on the data in the Custom                 |
-- |                table, simulate MTI load, initiate a workflow process in order                |
-- |                to approve the validated cost data                                            |
-- |              3.After approval the validated data gets inserted in the                        |
-- |                MTI Table.                                                                    |
-- |              4.Transactions Manager scheduled as part of Setup would pick the records from   |
-- |                MTI Table and update the average cost of the items.                           |
-- |                                                                                              |
-- |                                                                                              |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version   Date        Author           Remarks                                                |
-- |=======   ==========  =============    =======================================================|
-- |DRAFT 1A 15-JUN-2007  Meenu Goyal      Initial draft version                                  |
-- |DRAFT 1B 13-AUG-2007  Jayshree         Reviewed and updated                                   |
-- |DRAFT 1C 13-AUG-2007  Meenu Goyal      Incorporated the review comments                       |
-- |DRAFT 1D 18-SEP-2007  Meenu Goyal      Incorporated the new requirement changes for template2 |
-- |                                       Template formats matching as per the MD 50             |
-- |1.0      21-SEP-2007  Jayshree         Baselined                                              |
-- |1.1      5-OCT-2007   Meenu Goyal      Modified as per CR for below Changes.                  |
-- |                                       1. There would be one single template.                 |
-- |                                       2. Report header wont have functional currency on header|
-- |                                       3. Record number wont be provided in the csv file      |
-- |1.2      22-Oct-2007  Jayshree         Reviewed and updated                                   |
-- |1.3      26-Oct-2007  Meenu Goyal      Included different validation for item cost            |
-- |1.4      30-Oct-2007  Meenu Goyal      Code Bug Fix for cost cursor                           |
-- |1.5      31-Oct-2007  Meenu Goyal      Code Bug Fix for Concurrent Program logic              |
-- |                                       District Validation included in Store Information      |
-- +==============================================================================================+

-- +========================================================================+
-- | Name        :  LOG_ERROR                                               |
-- |                                                                        |
-- | Description :  This wrapper procedure calls the custom common error api|
-- |                 with relevant parameters.                              |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_exception IN VARCHAR2                                 |
-- |                p_message   IN VARCHAR2                                 |
-- |                p_code      IN NUMBER                                   |
-- |                                                                        |
-- +========================================================================+
PROCEDURE LOG_ERROR(p_exception      IN VARCHAR2
                   ,p_message        IN VARCHAR2
                   ,p_code           IN VARCHAR2
                   )
IS

lc_err_code         VARCHAR2(100);
lc_errbuf           VARCHAR2(5000);
lc_error_location   VARCHAR2(50) ;

BEGIN 

   lc_error_location  := 'XX_GI_AVERAGE_COST_PKG.LOG_ERROR';
   
   XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                    P_PROGRAM_TYPE            => GC_PROGRAM_TYPE    ,
                                    P_PROGRAM_NAME            => GC_PROGRAM_NAME    ,
                                    P_MODULE_NAME             => GC_MODULE_NAME     ,
                                    P_ERROR_LOCATION          => p_exception        ,
                                    P_ERROR_MESSAGE_CODE      => p_code             ,
                                    P_ERROR_MESSAGE           => p_message          ,
                                    P_ATTRIBUTE1              => 'File Id: ' || GN_FILE_ID ,
                                    P_NOTIFY_FLAG             => GC_NOTIFY ,
                                    P_ERROR_MESSAGE_SEVERITY  => GC_MAJOR                 
                                    ); 

   
EXCEPTION

    WHEN OTHERS THEN
    
         lc_errbuf         :=  FND_MESSAGE.GET;
         lc_err_code       := 'XX_INV_6000_UNEXP_ERR';
       
         LOG_ERROR(p_exception      =>lc_error_location
                  ,p_message        =>lc_errbuf
                  ,p_code           =>lc_err_code
                  ) ; 

END LOG_ERROR;
-- +========================================================================+
-- | Name        :  INSERT_FAILED_RECORDS                                   |
-- |                                                                        |
-- | Description :  This wrapper procedure inserts the failed records in the|
-- |                staging table.                                          |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_file_id         IN NUMBER                             |
-- |                p_error_message   IN VARCHAR2                           |
-- |                p_error_code      IN NUMBER                             |
-- |                                                                        |
-- +========================================================================+

                            
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
                                 )              
IS
      
PRAGMA AUTONOMOUS_TRANSACTION;
       
lc_err_code         VARCHAR2(100);
lc_errbuf           VARCHAR2(5000);
lc_error_location   VARCHAR2(50) ;      
              
BEGIN       

lc_error_location := 'INSERT_FAILED_RECORDS';


INSERT INTO  XX_GI_AVERAGE_COST_STG(
                                     file_id,
                                     error_message ,
                                     error_code,
                                     status_flag,
                                     item_number,
                                     currency,
                                     country_code,
                                     average_cost,
                                     record_number,
                                     type_code     ,                                     
                                     subtype_code  ,                                     
                                     division_code  ,                                     
                                     district_code  ,                                     
                                     company_code  ,                                     
                                     chain_code   ,                                     
                                     area_code   ,                                      
                                     region_code 
                                     )                                    
  VALUES                             (
                                     p_file_id,
                                     p_error_message,
                                     p_error_code,
                                     GC_VAL_ERR,
                                     p_item_number,
                                     p_currency,
                                     p_country, 
                                     p_average_cost,
                                     XX_GI_AVERAGE_COST_RECNO_S.NEXTVAL  ,
                                     p_type_code              ,
                                     p_subtype_code    ,
                                     p_division_code  ,
                                     p_district_code  ,
                                     p_company_code  ,
                                     p_chain_code   ,
                                     p_area_code   , 
                                     p_region_code   
                                     );
 COMMIT;

EXCEPTION   

 WHEN OTHERS THEN          
      lc_errbuf         :=  FND_MESSAGE.GET;
      lc_err_code       := 'XX_INV_6043_UNEXP_ERR' || SQLERRM;

      LOG_ERROR(p_exception      =>lc_error_location
               ,p_message        =>lc_errbuf
               ,p_code           =>lc_err_code
               ) ;         

END INSERT_FAILED_RECORDS;

PROCEDURE GET_AVERAGE_COST_DETAILS (p_file_id       IN   NUMBER  ,
                                    x_status        OUT  VARCHAR2,
                                    x_error_count   OUT  VARCHAR2
                                    )
IS

-- +================================================================================+
-- | Name       : GET_AVERAGE_COST_DETAILS                                          |
-- |                                                                                |
-- | Description: This procedure takes File_id that is passed from OAF as the       |
-- |              input parameter.Based on the file_id received, it takes the record|
-- |              from fnd_lobs table and put it as csv file under admin/import in  |
-- |              the UNIX Directory on the EBS server.                             |
-- |                                                                                |
-- +================================================================================+

--**************************
-- Declaring Local variables
--**************************

lf_file             UTL_FILE.FILE_TYPE;
lr_buffer           RAW(32767);

li_pos              INTEGER := 1;
li_blob_len         INTEGER := 0;

lb_blob             BLOB := NULL;
lb_amount           BINARY_INTEGER := 32767;

lc_status           VARCHAR2(50);
lc_error_message    VARCHAR2(100);
lc_err_code         VARCHAR2(100);
lc_errbuf           VARCHAR2(5000);
lc_error_count      VARCHAR2(100);
lc_error_location   VARCHAR2(50) ;

--User Defined exceptions

ex_blod_data_err         EXCEPTION;
ex_blob_len_null         EXCEPTION;
ex_load_average_err_fail EXCEPTION;

-- Begining of the Function

BEGIN


x_status          :=  GC_REC_STATUS_SUCC; --Intializing the status = 'S'
x_error_count     :=  NULL         ;      --Intializing the error count to NULL
lc_error_location :=  'XX_GI_AVERAGE_COST_PKG.GET_AVERAGE_COST_DETAILS';
GN_FILE_ID        :=  p_file_id;


--Get the BLOB from the APPLSYS.FND_LOBS table.


BEGIN

  SELECT fl.file_data
  INTO   lb_blob
  FROM   FND_LOBS fl
  WHERE  file_id = p_file_id;  
  
EXCEPTION
  WHEN OTHERS THEN  
    RAISE EX_BLOD_DATA_ERR;
END;

--Figure out how long the BLOB is.

li_blob_len := DBMS_LOB.GETLENGTH(lb_blob);


--If blob length is NULL Then Raise exception

IF li_blob_len IS NULL THEN

   RAISE EX_BLOB_LEN_NULL;   

END IF;

-- Open the destination file. 

lf_file := UTL_FILE.FOPEN(GC_FILE_PATH ,p_file_id,'w', 32700); 

    
-- Read chunks of the BLOB and write them to the file until complete.

WHILE li_pos < li_blob_len LOOP

   
   -- The DBMS_LOB.READ procedure dictates that its output be RAW.

   DBMS_LOB.READ(lb_blob, lb_amount, li_pos, lr_buffer);

   --Reads a RAW string value from a file and adjusts the file pointer ahead by the number of bytes read

   UTL_FILE.PUT_RAW(lf_file, lr_buffer, TRUE);

   -- For the next iteration through the BLOB, bump up your offset
   -- location (i.e., where you start reading from).

   li_pos := li_pos + lb_amount;

END LOOP;

  
--***************
-- Close the file.
--***************

UTL_FILE.fclose(lf_file);


--Call the Load Average Cost Details

LOAD_AVERAGE_COST_DETAILS (p_file_id        => p_file_id          ,
                           x_status         => x_status           ,
                           x_error_count    => x_error_count  
                           ) ;   
   
EXCEPTION

   WHEN EX_BLOD_DATA_ERR THEN
     
    FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6001_BLOB_DATA_ERR');

    lc_errbuf   :=  FND_MESSAGE.GET;
    lc_err_code := 'XX_INV_6001_BLOB_DATA_ERR';
    x_status    :=  GC_REC_STATUS_ERR;         
   
    LOG_ERROR(p_exception      =>lc_error_location
             ,p_message        =>lc_errbuf
             ,p_code           =>lc_err_code
             ) ;  
             
   WHEN EX_BLOB_LEN_NULL THEN
   
      FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6002_BLOB_LENGTH_NULL');

      lc_errbuf   :=  FND_MESSAGE.GET;
      lc_err_code := 'XX_INV_6002_BLOB_LENGTH_NULL';
      x_status    :=  GC_REC_STATUS_ERR;   
      
      LOG_ERROR(p_exception      =>lc_error_location
               ,p_message        =>lc_errbuf
               ,p_code           =>lc_err_code
               ) ;     
               
   WHEN EX_LOAD_AVERAGE_ERR_FAIL THEN
   
       FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6003_LOAD_AVG_ERR');
   
       lc_errbuf         :=  FND_MESSAGE.GET;
       lc_err_code       := 'XX_INV_6003_LOAD_AVG_ERR';
   
       LOG_ERROR(p_exception      =>lc_error_location
                ,p_message        =>lc_errbuf
                ,p_code           =>lc_err_code
             ) ; 

   WHEN UTL_FILE.INVALID_PATH THEN
      UTL_FILE.FCLOSE(lf_file);
      x_status        :=   GC_REC_STATUS_FAIL;      
      x_error_count   :=  'Invalid Unix Path' ;
      
      RETURN;
   WHEN UTL_FILE.WRITE_ERROR THEN
      UTL_FILE.FCLOSE(lf_file);
      x_status        :=  GC_REC_STATUS_FAIL;
      RETURN;
   WHEN UTL_FILE.INVALID_MODE THEN
      UTL_FILE.FCLOSE(lf_file);
      x_status        :=  GC_REC_STATUS_FAIL;
      RETURN;
   WHEN UTL_FILE.INVALID_OPERATION THEN
      UTL_FILE.FCLOSE(lf_file);
      x_status        :=  GC_REC_STATUS_FAIL;
      RETURN;
   WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
      UTL_FILE.FCLOSE(lf_file);
      x_status        :=  GC_REC_STATUS_FAIL;
      RETURN;
   WHEN UTL_FILE.ACCESS_DENIED THEN
      UTL_FILE.FCLOSE(lf_file);
      x_status        :=  GC_REC_STATUS_FAIL;
      RETURN;
   WHEN UTL_FILE.CHARSETMISMATCH  THEN
      UTL_FILE.FCLOSE(lf_file);
      x_status        :=  GC_REC_STATUS_FAIL;
      RETURN;
  WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6004_ERR_GET_DETAILS');
       FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

       lc_errbuf         :=  FND_MESSAGE.GET;
       lc_err_code       := 'XX_INV_6004_ERR_GET_DETAILS';
       x_status          :=  GC_REC_STATUS_FAIL;

       LOG_ERROR(p_exception      =>lc_error_location
                ,p_message        =>lc_errbuf
                ,p_code           =>lc_err_code
             ) ; 
             
     -- Close the file if something goes wrong.

     IF UTL_FILE.is_open(lf_file) THEN
        UTL_FILE.fclose(lf_file);
     END IF;
     
END GET_AVERAGE_COST_DETAILS;

PROCEDURE STORE_INFORMATION    ( p_currency        IN       VARCHAR2    ,
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
                                -- p_template_number IN       NUMBER      ,
                                 x_status          OUT      VARCHAR2    ,
                                 x_error_count     OUT      VARCHAR2
                                 )
IS                           

-- +================================================================================+
-- | Name       : STORE_INFORMATION                                                 |
-- |                                                                                |
-- | Description: This procedure would validate the template  information that user |
-- |              enters and derives based on different org parameters.             |
-- +================================================================================+


ln_count                NUMBER := 0  ;
lc_err_code             VARCHAR2(100);
lc_errbuf               VARCHAR2(5000);
lc_error_location       VARCHAR2(50) ;
ln_item_number          NUMBER := NULL;
lc_area_code            xx_gi_average_cost_stg.area_code%TYPE;
lc_region_code          xx_gi_average_cost_stg.region_code%TYPE;
lc_chain_code           xx_gi_average_cost_stg.chain_code%TYPE ;
lc_district_code        xx_gi_average_cost_stg.district_code%TYPE ;

lc_validate_check       VARCHAR2(100);

EX_CURRENCY_ERR         EXCEPTION;
EX_COUNTRY_ERR          EXCEPTION;
lc_record_check         VARCHAR2(500) := NULL;
EX_VALUE_NOT_DERIVED    EXCEPTION;
EX_NULL_VALUES          EXCEPTION;
EX_NULL_VALUES_COST     EXCEPTION;
EX_VAL_CHK              EXCEPTION;

--Declaring the cursor to get the store value

CURSOR lcu_get_stores_dist(p_Item_Number   VARCHAR2,
                           p_type_code     VARCHAR2,
                           p_subtype_code  VARCHAR ,
                           p_Division_code VARCHAR2,
                           p_district      PLS_INTEGER,
                           p_country       VARCHAR2
                           )
IS                       
SELECT ood.organization_name
FROM   mtl_system_items_b msi,
       xx_inv_org_loc_rms_attribute xxinv,
       mtl_parameters               MP,
       org_organization_definitions OOD
WHERE  msi.segment1                   = p_Item_Number
AND    MSI.inventory_item_status_code ='A'
AND    xxinv.organization_id          = msi.organization_id
AND    country_id_sw                  = p_country
AND    od_type_sw                     = NVL(p_type_code,od_type_sw)
AND    od_sub_type_cd_sw              = NVL(p_subtype_code,od_sub_type_cd_sw)
AND    od_division_id_sw              = NVL(p_Division_code,od_division_id_sw)
AND    district_sw                    = NVL(p_district,district_sw)
AND    mp.organization_id             = xxinv.organization_id
AND    MSI.enabled_flag               ='Y' 
AND    OOD.organization_id            = MP.organization_id
AND    TRUNC(SYSDATE)  BETWEEN NVL(MSI.start_date_active,TRUNC(SYSDATE) ) AND NVL(MSI.end_date_active,TRUNC(SYSDATE) +1);

--Declaring the cursor to get the area belonging to that chain

CURSOR  lcu_get_area_chain(P_CHAIN_CODE PLS_INTEGER)
IS
SELECT  FFV.flex_value
FROM    fnd_flex_values     FFV
      , fnd_flex_values_tl  FFVT
      , fnd_flex_value_sets FFVS
WHERE   FFVS.flex_value_set_name = GC_AREA_SET_NAME
AND     FFV.flex_value_set_id    = FFVS.flex_value_set_id
AND     FFVT.flex_value_id       = FFV.flex_value_id
AND     FFV.attribute1           = NVL(P_CHAIN_CODE,FFV.attribute1) ;


--Declaring the cursor to get the region belonging to that area

CURSOR  lcu_get_region_area(P_AREA_CODE PLS_INTEGER)
IS
SELECT  FFV.flex_value
FROM    fnd_flex_values     FFV,
        fnd_flex_values_tl  FFVT,
        fnd_flex_value_sets FFVS
WHERE   FFVS.flex_value_set_name = GC_REGION_SET_NAME 
AND     FFV.flex_value_set_id    = FFVS.flex_value_set_id
AND     FFVT.flex_value_id       = FFV.flex_value_id
AND     FFV.attribute1           = NVL(P_AREA_CODE ,FFV.attribute1);

--Declaring the cursor to get the district belonging to that region

CURSOR  lcu_get_district_region(P_REGION_CODE PLS_INTEGER)
IS
SELECT  FFV.flex_value
FROM    fnd_flex_values     FFV
       ,fnd_flex_values_tl  FFVT
       ,fnd_flex_value_sets FFVS
WHERE  FFVS.flex_value_set_name = GC_DISTRICT_SET_NAME
AND    FFV.flex_value_set_id    = FFVS.flex_value_set_id
AND    FFVT.flex_value_id       = FFV.flex_value_id
AND    FFV.attribute1           = NVL(P_REGION_CODE,FFV.attribute1);

--Declared a cursor to validate the item

CURSOR   lcu_validate_item(p_Item_Number VARCHAR2)
IS
SELECT   count(MSI.inventory_item_id)
FROM     mtl_system_items_b MSI 
WHERE    MSI.segment1             = p_Item_Number
AND      MSI.inventory_item_status_code ='A'     
AND      MSI.enabled_flag         ='Y' 
AND      TRUNC(SYSDATE)  BETWEEN NVL(MSI.start_date_active,TRUNC(SYSDATE) ) AND NVL(MSI.end_date_active,TRUNC(SYSDATE) +1);

BEGIN

x_status            :=  GC_REC_STATUS_SUCC;
lc_error_location   := 'XX_GI_AVERAGE_COST_PKG.STORE_INFORMATION';


--Clearing the plsql table

IF insert_store_table.count != 0 THEN

   insert_store_table.delete;

END IF;

--Country cannot be null

IF p_country  IS NULL THEN

   RAISE EX_COUNTRY_ERR;

END IF;
 
--Currency cannot be null

IF  p_currency  IS  NULL THEN

     RAISE EX_CURRENCY_ERR;
     
END IF;

--Chk if item number is null 

IF p_sku IS NULL  THEN

  RAISE EX_NULL_VALUES;

END IF;      

--Chk if item cost is null

IF p_new_cost IS NULL THEN

   RAISE EX_NULL_VALUES_COST ;
   
END IF;

 
--Open the cursor to validate the item

OPEN  lcu_validate_item(p_sku) ;
FETCH lcu_validate_item INTO ln_item_number;
CLOSE lcu_validate_item;


IF  NVL(ln_item_number,-99999) = 0 THEN

    lc_record_check := 'Item'  ;
    
    RAISE  EX_VALUE_NOT_DERIVED;

END IF;


--Chk for Store:If its null then chk for all other values

IF p_store  IS  NULL THEN

      lc_record_check := 'District';
  
  --If only region code is not null
 
  IF p_region_code IS NOT NULL AND p_area_code IS NULL AND p_chain_code IS NULL  AND p_district_code IS NULL THEN
      
      
      lc_record_check := 'Region:' || p_region_code;
       
      FOR lcr_get_district_region IN lcu_get_district_region(p_region_code)
      LOOP                                      
           
           
         lc_record_check := 'District:' || lcr_get_district_region.flex_value;         
        
         FOR lcr_get_stores_dist IN lcu_get_stores_dist (p_sku,
                                                         p_type_code,
                                                         p_subtype_code,
                                                         p_Division_code,
                                                         lcr_get_district_region.flex_value,
                                                         p_country
                                                         )
         LOOP 

            insert_store_table(ln_count).rec_index := ln_count;
            insert_store_table(ln_count).store     := lcr_get_stores_dist.organization_name;

            ln_count := ln_count + 1;

            lc_record_check := NULL;

         END LOOP;
                                         
      END LOOP;     
   
   --If only area code is not null
   
   ELSIF p_area_code IS NOT NULL  AND p_chain_code IS NULL AND p_region_code IS NULL AND p_district_code IS NULL THEN  
   
         
      FOR lcr_get_region_area IN lcu_get_region_area(p_area_code)        
      LOOP
         
         lc_record_check := 'Region:' || lcr_get_region_area.flex_value;
         
         FOR lcr_get_district_region IN lcu_get_district_region(lcr_get_region_area.flex_value)
         LOOP
           
            lc_record_check := 'District:' || lcr_get_district_region.flex_value ;
            
            FOR lcr_get_stores_dist IN lcu_get_stores_dist(p_sku,
                                                           p_type_code,
                                                           p_subtype_code,
                                                           p_Division_code,
                                                           lcr_get_district_region.flex_value,
                                                           p_country
                                                           )
            LOOP 
                                                               
               insert_store_table(ln_count).rec_index := ln_count;
               insert_store_table(ln_count).store     := lcr_get_stores_dist.organization_name;
             
               ln_count := ln_count + 1;
               
               lc_record_check := NULL;
                
            END LOOP;
                               
         END LOOP;
              
      END LOOP;   
      
   --if only chain code is not null
   
   ELSIF p_Chain_code IS NOT NULL AND p_area_code IS NULL AND p_region_code IS NULL AND p_district_code IS NULL THEN
      
      
      lc_record_check := 'Chain:' || p_chain_code;
     
     
      FOR  lcr_get_area_chain IN  lcu_get_area_chain(p_Chain_code)
      LOOP
      
         lc_record_check := 'Area:' || lcr_get_area_chain.flex_value ;
        
         FOR lcr_get_region_area IN lcu_get_region_area(lcr_get_area_chain.flex_value)              
         LOOP
            
            lc_record_check := 'Region:' || lcr_get_region_area.flex_value;
            
            FOR lcr_get_district_region IN lcu_get_district_region(lcr_get_region_area.flex_value)
            LOOP
              
               lc_record_check := 'District:' || lcr_get_district_region.flex_value;
               
               FOR lcr_get_stores_dist IN lcu_get_stores_dist  (p_sku,
                                                                p_type_code,
                                                                p_subtype_code,
                                                                p_Division_code,
                                                                lcr_get_district_region.flex_value,
                                                                p_country)
               LOOP 
                                                                
                  insert_store_table(ln_count).rec_index := ln_count;
                  insert_store_table(ln_count).store     := lcr_get_stores_dist.organization_name;
                 
                  ln_count := ln_count + 1;
               
                  lc_record_check := NULL;
               
               END LOOP;
                                   
            END LOOP;
                   
         END LOOP;  
    
      END LOOP;
  
  --if chain and area are not null.chk if chain belongs to the area and then derive store from area
  ELSIF  p_chain_code IS NOT NULL AND p_area_code IS NOT NULL  AND p_region_code IS NULL  AND p_district_code IS NULL THEN
       
       
      lc_validate_check := 'Chain:' || p_chain_code || ' doesnot belong to ' || 'Area:' || p_area_code ;     
      
      --Validate Chain
      
      FOR lcr_get_area_chain IN lcu_get_area_chain(p_Chain_code)
      LOOP
          
         lc_area_code    := lcr_get_area_chain.flex_value;

         IF lc_area_code  = p_area_code THEN   

             lc_validate_check := NULL;  
             EXIT;

         END IF; 
              
      END LOOP;
      
      IF  lc_validate_check IS NOT NULL THEN
      
           RAISE EX_VAL_CHK;
      
      ELSE
         
         --Once chain is validated derive area 
         FOR lcr_get_region_area IN lcu_get_region_area(p_area_code)              
         LOOP

            lc_record_check := 'Region:' || lcr_get_region_area.flex_value;

            FOR lcr_get_district_region IN lcu_get_district_region(lcr_get_region_area.flex_value)
            LOOP

               lc_record_check := 'District:' || lcr_get_district_region.flex_value;

               FOR lcr_get_stores_dist IN lcu_get_stores_dist  (p_sku,
                                                                p_type_code,
                                                                p_subtype_code,
                                                                p_Division_code,
                                                                lcr_get_district_region.flex_value,
                                                                p_country)
               LOOP 

                  insert_store_table(ln_count).rec_index := ln_count;
                  insert_store_table(ln_count).store     := lcr_get_stores_dist.organization_name;

                  ln_count := ln_count + 1;

                  lc_record_check := NULL;

               END LOOP;

            END LOOP;

         END LOOP;            

      END IF;
  
   --if area and region are not null.chk if area belongs to the region and then derive store from region
   
   ELSIF p_area_code IS NOT NULL AND p_region_code IS NOT NULL  AND p_chain_code IS NULL  AND p_district_code IS NULL THEN 
   
        lc_validate_check := 'Area:' || p_area_code || ' doesnot belong to ' || 'Region:' || p_region_code ; 

        FOR lcr_get_region_area IN lcu_get_region_area(p_area_code) 
        LOOP

          lc_region_code    := lcr_get_region_area.flex_value;

          IF lc_region_code  = p_region_code THEN   

              lc_validate_check := NULL;  
              EXIT;

          END IF; 

        END LOOP;
       
        IF  lc_validate_check IS NOT NULL THEN

            RAISE EX_VAL_CHK;

        ELSE  
       
          --Once Area is validated derive district

         FOR lcr_get_district_region IN lcu_get_district_region(p_region_code)
         LOOP

            lc_record_check := 'District:' || lcr_get_district_region.flex_value;

            FOR lcr_get_stores_dist IN lcu_get_stores_dist(p_sku,
                                                           p_type_code,
                                                           p_subtype_code,
                                                           p_Division_code,
                                                           lcr_get_district_region.flex_value,
                                                           p_country
                                                           )
            LOOP 

               insert_store_table(ln_count).rec_index := ln_count;
               insert_store_table(ln_count).store     := lcr_get_stores_dist.organization_name;

               ln_count := ln_count + 1;

               lc_record_check := NULL;

            END LOOP;

         END LOOP;            

       END IF;
      
      
   --In case region and district is NOT NULL
   
  ELSIF p_region_code IS NOT NULL AND p_district_code IS NOT NULL AND p_chain_code IS NULL AND p_area_code IS NULL THEN --31/10/07 Meenu Goyal Added District criteria
 
      lc_validate_check := 'Region:' || p_region_code || ' doesnot belong to ' || 'District:' || p_district_code ; 
    
      FOR lcr_get_district_region IN lcu_get_district_region(p_region_code)
      LOOP
    
         lc_district_code    := lcr_get_district_region.flex_value;
        
         IF lc_district_code  = p_district_code THEN   

             lc_validate_check := NULL;  
             EXIT;
           
         END IF; 
        
      END LOOP;

     
      IF  lc_validate_check IS NOT NULL THEN

          RAISE EX_VAL_CHK;

      ELSE
         
         lc_record_check := 'District:' || p_district_code ;  
         
         FOR lcr_get_stores_dist IN lcu_get_stores_dist(p_sku,
                                                        p_type_code,
                                                        p_subtype_code,
                                                        p_Division_code,
                                                        p_district_code,
                                                        p_country
                                                        )
         LOOP 

            insert_store_table(ln_count).rec_index := ln_count;
            insert_store_table(ln_count).store     := lcr_get_stores_dist.organization_name;

            ln_count := ln_count + 1;
            lc_record_check := NULL;

         END LOOP;              

      END IF;      
   
   --if chain ,area and region are not null.chk if chain belongss to area,area  belongs to the region and then derive store from region
   
   ELSIF p_chain_code IS NOT NULL AND p_area_code IS NOT NULL AND p_region_code IS NOT NULL AND p_district_code IS NULL THEN
            
      --Open the cursor to validate the value of chain
     
     lc_validate_check := 'Chain:' || p_chain_code || ' doesnot belong to ' || 'Area:' || p_area_code ;     

     --Validate Chain working
     

     FOR lcr_get_area_chain IN lcu_get_area_chain(p_Chain_code)
     LOOP

        lc_area_code    := lcr_get_area_chain.flex_value;

        IF lc_area_code  = p_area_code THEN   

            lc_validate_check := NULL;  
            EXIT;

        END IF; 
     
     END LOOP;
           
     IF  lc_validate_check IS NOT NULL THEN
           
         RAISE EX_VAL_CHK;
           
     ELSE
     
        lc_validate_check := 'Area:' || p_area_code || ' doesnot belong to ' || 'Region:' || p_region_code ; 

        FOR lcr_get_region_area IN lcu_get_region_area(p_area_code) 
        LOOP

          lc_region_code    := lcr_get_region_area.flex_value;

          IF lc_region_code  = p_region_code THEN   

             lc_validate_check := NULL;  
             EXIT;

         END IF; 

       END LOOP;
     
     END IF;
     
     IF lc_validate_check IS NOT NULL THEN 
        
        RAISE EX_VAL_CHK;
     
     ELSE      
    
         -- In case area is validated then derive district based on the region

         FOR lcr_get_district_region IN lcu_get_district_region(p_region_code)
         LOOP

            lc_record_check := 'District:' || lcr_get_district_region.flex_value ;

            FOR lcr_get_stores_dist IN lcu_get_stores_dist  (p_sku,
                                                             p_type_code,
                                                             p_subtype_code,
                                                             p_Division_code,
                                                             lcr_get_district_region.flex_value,
                                                             p_country)
            LOOP 

               insert_store_table(ln_count).rec_index := ln_count;
               insert_store_table(ln_count).store     := lcr_get_stores_dist.organization_name;

               ln_count := ln_count + 1;

               lc_record_check := NULL;

            END LOOP;

         END LOOP; 

      END IF;
   
   ELSIF p_chain_code IS NOT NULL AND p_area_code IS NOT NULL AND p_region_code IS NOT NULL AND p_district_code IS NOT NULL THEN
   
      --Open the cursor to validate the value of chain
     
     lc_validate_check := 'Chain:' || p_chain_code || ' doesnot belong to ' || 'Area:' || p_area_code ;     

     --Validate Chain working
     

     FOR lcr_get_area_chain IN lcu_get_area_chain(p_Chain_code)
     LOOP

        lc_area_code    := lcr_get_area_chain.flex_value;

        IF lc_area_code  = p_area_code THEN   

            lc_validate_check := NULL;  
            EXIT;

        END IF; 
     
     END LOOP;
           
     IF  lc_validate_check IS NOT NULL THEN
           
         RAISE EX_VAL_CHK;
           
     ELSE
     
        lc_validate_check := 'Area:' || p_area_code || ' doesnot belong to ' || 'Region:' || p_region_code ; 

        FOR lcr_get_region_area IN lcu_get_region_area(p_area_code) 
        LOOP

          lc_region_code    := lcr_get_region_area.flex_value;

          IF lc_region_code  = p_region_code THEN   

             lc_validate_check := NULL;  
             EXIT;

         END IF; 

       END LOOP;
     
     END IF;   
   
   
     IF lc_validate_check IS NOT NULL THEN 
           
         RAISE EX_VAL_CHK;
        
     ELSE 
     
      --Validate region
     lc_validate_check := 'Region:' || p_region_code || ' doesnot belong to ' || 'District:' || p_district_code ; 
     
     FOR lcr_get_district_region IN lcu_get_district_region(p_region_code)     
     LOOP
     
        lc_district_code   := lcr_get_district_region.flex_value;
     
        IF  lc_district_code = p_district_code THEN
        
            lc_validate_check := NULL;  
            EXIT;        
        END IF;    
     
     END LOOP;
     
     END IF;
     
     IF lc_validate_check IS NOT NULL THEN  
     
        RAISE EX_VAL_CHK;
        
     ELSE
     
     --Derive stores based on district     

      lc_record_check := 'District:' || p_district_code ;

      FOR lcr_get_stores_dist IN lcu_get_stores_dist  (p_sku,
                                                       p_type_code,
                                                       p_subtype_code,
                                                       p_Division_code,
                                                       p_district_code,
                                                       p_country)
      LOOP 

         insert_store_table(ln_count).rec_index := ln_count;
         insert_store_table(ln_count).store     := lcr_get_stores_dist.organization_name;

         ln_count := ln_count + 1;

         lc_record_check := NULL;

      END LOOP;    
     
     END IF;
     
   --if chain and region are not null.chk if chain belongss to area and derived area  belongs to the region and then derive store from region
   
   ELSIF  p_chain_code IS NOT NULL AND p_region_code IS NOT NULL AND p_area_code IS NULL AND p_district_code IS NULL THEN
   
      lc_record_check := 'Chain:' || p_chain_code;
          
      --Open the cursor to validate the value of chain
     
      OPEN  lcu_get_area_chain(p_Chain_code);
      FETCH lcu_get_area_chain INTO lc_chain_code;
      
         IF lcu_get_area_chain%ROWCOUNT = 0 THEN

            lc_record_check := 'Chain:' || p_chain_code;
            x_status        := GC_REC_STATUS_FAIL;

         END IF;
            
      CLOSE lcu_get_area_chain ;
      
      --In case chain is a valid value then proceed with deriving values of stores from region
      
      IF x_status != GC_REC_STATUS_FAIL THEN
      
         FOR lcr_get_district_region IN lcu_get_district_region(p_region_code)
         LOOP

            lc_record_check := 'District:' || lcr_get_district_region.flex_value;

            FOR lcr_get_stores_dist IN lcu_get_stores_dist  (p_sku,
                                                             p_type_code,
                                                             p_subtype_code,
                                                             p_Division_code,
                                                             lcr_get_district_region.flex_value,
                                                             p_country)
            LOOP 

               insert_store_table(ln_count).rec_index := ln_count;
               insert_store_table(ln_count).store     := lcr_get_stores_dist.organization_name;

               ln_count := ln_count + 1;

              lc_record_check := NULL;

            END LOOP;

         END LOOP;
                   
      END IF;      
   
   -- if chain ,area and region are null then chk directly for type,subtype ,division,district and country
   ELSIF (    p_type_code     IS NOT NULL
          OR  p_subtype_code  IS NOT NULL 
          OR  p_Division_code IS NOT NULL
          OR  p_country       IS NOT NULL
          OR  p_district_code IS NOT NULL
          AND p_chain_code    IS NULL
          AND p_region_code   IS NULL
          AND p_area_code     IS NULL)  THEN
      
      
      lc_record_check := 'Type_code: '  || p_type_code || '    Sub_Type_Code:' || p_subtype_code || '    Division Code:' || p_Division_code
                        || '    Country:' || p_country   || '    District Code:' || p_district_code;
      
      FOR lcr_get_stores_dist IN lcu_get_stores_dist(p_sku,
                                                     p_type_code,
                                                     p_subtype_code,
                                                     p_Division_code,
                                                     p_district_code,
                                                     p_country
                                                     )
      LOOP 
         
         
         insert_store_table(ln_count).rec_index := ln_count;         
         insert_store_table(ln_count).store     := lcr_get_stores_dist.organization_name;
         
              
         ln_count := ln_count + 1;
         
         lc_record_check := NULL;
      
      END LOOP;       
   
   END IF; -- district end if
  
ELSE 

  
   insert_store_table(ln_count).rec_index := ln_count;
   insert_store_table(ln_count).store     := p_store;


END IF;

--Open the Plsql table and insert the values in the staging table

IF insert_store_table.count = 0 THEN
   
   RAISE EX_VALUE_NOT_DERIVED;

END IF;

FOR ln_store IN insert_store_table.FIRST..insert_store_table.LAST 
LOOP
 
      
    INSERT INTO XX_GI_AVERAGE_COST_STG
                            (currency          ,
                             file_id           ,            
                             country_code      ,
                             type_code         ,
                             subtype_code      ,
                             division_code     ,
                             district_code     ,
                             company_code      ,
                             chain_code        ,
                             area_code         ,
                             region_code       ,
                             organization      ,
                             average_cost      ,
                             item_number       ,
                           --  template_number   ,
                             record_number    
                             )
         VALUES             (p_currency,
                             p_file_id  ,
                             p_country ,
                             p_type_code,
                             p_subtype_code,
                             p_division_code,
                             p_district_code,
                             p_company_code,
                             p_chain_code,
                             p_area_code,
                             p_region_code,
                             insert_store_table(ln_store).store,
                             p_new_cost,
                             p_sku,
                            -- p_template_number ,
                             XX_GI_AVERAGE_COST_RECNO_S.NEXTVAL
                             );

END LOOP;

COMMIT;

EXCEPTION
  
  WHEN EX_VAL_CHK        THEN
  
       FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6048_NON_VALID_VALUE');  
       FND_MESSAGE.SET_TOKEN('LC_VAL_CHECK',lc_validate_check);      
              
       x_status       :=  GC_REC_STATUS_FAIL;
       x_error_count  :=  lc_validate_check  ;       
       lc_errbuf      :=  FND_MESSAGE.GET;  
 
       lc_err_code    :=  'XX_INV_6048_NON_VALID_VALUE';  
       
       --Logging to common error table
       
       LOG_ERROR(p_exception      =>lc_error_location  
                ,p_message        =>lc_errbuf  
                ,p_code           =>lc_err_code  
                 ) ;  
                 
       --Insert the failed records in the staging table       
       
       INSERT_FAILED_RECORDS(  p_file_id        => p_file_id  ,
                               p_error_message  => lc_errbuf  ,
                               p_error_code     => lc_err_code,
                               p_item_number    => p_sku      ,
                               p_currency       => p_currency ,
                               p_country        => p_country  ,
                               p_average_cost   => p_new_cost ,
                               x_status         => x_status   ,
                               x_error_count    => x_error_count  ,
                               p_type_code      => p_type_code    ,
                               p_subtype_code   => p_subtype_code ,
                               p_division_code  => p_division_code,
                               p_district_code  => p_district_code,
                               p_company_code   => p_company_code ,
                               p_chain_code     => p_chain_code   ,
                               p_area_code      => p_area_code    ,
                               p_region_code    => p_region_code                                 
                               );  
  
  
  WHEN EX_VALUE_NOT_DERIVED THEN
  
  
       FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6042_STORE_NOT_DERIVED');  
       FND_MESSAGE.SET_TOKEN('LC_RECORD_CHECK',lc_record_check);      
              
       x_status       :=  GC_REC_STATUS_FAIL;
       x_error_count  :=  lc_record_check || ' is not a valid value to derive stores '  ;       
       lc_errbuf      :=  FND_MESSAGE.GET;  
 
       lc_err_code    :=  'XX_INV_6042_STORE_NOT_DERIVED';  
       
       --Logging to common error table
       
       LOG_ERROR(p_exception      =>lc_error_location  
                ,p_message        =>lc_errbuf  
                ,p_code           =>lc_err_code  
                 ) ;  
                 
       --Insert the failed records in the staging table       
       
       INSERT_FAILED_RECORDS(  p_file_id        => p_file_id  ,
                               p_error_message  => lc_errbuf  ,
                               p_error_code     => lc_err_code,
                               p_item_number    => p_sku      ,
                               p_currency       => p_currency ,
                               p_country        => p_country  ,
                               p_average_cost   => p_new_cost ,
                               x_status         => x_status   ,
                               x_error_count    => x_error_count  ,
                               p_type_code      => p_type_code    ,
                               p_subtype_code   => p_subtype_code ,
                               p_division_code  => p_division_code,
                               p_district_code  => p_district_code,
                               p_company_code   => p_company_code ,
                               p_chain_code     => p_chain_code   ,
                               p_area_code      => p_area_code    ,
                               p_region_code    => p_region_code                                 
                               );
                             
                           
                             
 WHEN EX_COUNTRY_ERR THEN

      FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6041_COUNTRY_NULL');  

      x_status       :=  GC_REC_STATUS_FAIL;
      x_error_count :=   'Country cannot be NULL'  ;
      lc_errbuf      :=   FND_MESSAGE.GET;  
      lc_err_code    :=  'XX_INV_6041_COUNTRY_NULL';  

      LOG_ERROR(p_exception       =>lc_error_location  
                ,p_message        =>lc_errbuf  
                ,p_code           =>lc_err_code  
                ) ;
                
     INSERT_FAILED_RECORDS(  p_file_id        => p_file_id  ,
                             p_error_message  => lc_errbuf  ,
                             p_error_code     => lc_err_code,
                             p_item_number    => ' '     ,
                             p_currency       => ' ' ,
                             p_country        => ' '  ,
                             p_average_cost   => 0 ,
                             x_status         => x_status   ,
                             x_error_count    => x_error_count  ,
                             p_type_code      => p_type_code    ,
                             p_subtype_code   => p_subtype_code ,
                             p_division_code  => p_division_code,
                             p_district_code  => p_district_code,
                             p_company_code   => p_company_code ,
                             p_chain_code     => p_chain_code   ,
                             p_area_code      => p_area_code    ,
                             p_region_code    => p_region_code      );
       
                           
  WHEN EX_CURRENCY_ERR THEN
  
     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6039_CURR_NULL');

     lc_errbuf      :=   FND_MESSAGE.GET;
     lc_err_code    :=  'XX_INV_6039_CURR_NULL';
     x_status       :=   GC_REC_STATUS_FAIL;
     x_error_count :=   'Currency cannot be NULL'  ;

     LOG_ERROR(p_exception      =>lc_error_location
              ,p_message        =>lc_errbuf
              ,p_code           =>lc_err_code
              ) ; 
              
     INSERT_FAILED_RECORDS(  p_file_id        => p_file_id  ,
                             p_error_message  => lc_errbuf  ,
                             p_error_code     => lc_err_code,
                             p_item_number    => ' '      ,
                             p_currency       => ' ' ,
                             p_country        => ' '  ,
                             p_average_cost   => 0 ,
                             x_status         => x_status   ,
                             x_error_count    => x_error_count  ,
                             p_type_code      => p_type_code    ,
                             p_subtype_code   => p_subtype_code ,
                             p_division_code  => p_division_code,
                             p_district_code  => p_district_code,
                             p_company_code   => p_company_code ,
                             p_chain_code     => p_chain_code   ,
                             p_area_code      => p_area_code    ,
                             p_region_code    => p_region_code      
                             );         
             
WHEN EX_NULL_VALUES THEN

     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6044_ITEM_NULL');


     lc_errbuf     :=  FND_MESSAGE.GET;
     lc_err_code   := 'XX_INV_6044_ITEM_NULL';         
     x_status      :=  GC_REC_STATUS_FAIL;                 
     x_error_count :=  'Item cannot be null' ;

     LOG_ERROR(p_exception      =>lc_error_location
              ,p_message        =>lc_errbuf
              ,p_code           =>lc_err_code
             ) ; 


     INSERT_FAILED_RECORDS( p_file_id        => p_file_id  ,
                            p_error_message  => lc_errbuf  ,
                            p_error_code     => lc_err_code,
                            p_item_number    => ' ' ,
                            p_currency       => ' '  ,
                            p_country        => ' ' ,
                            p_average_cost   => 0,
                            x_status         => x_status   ,
                            x_error_count    => x_error_count,
                            p_type_code      => p_type_code    ,
                            p_subtype_code   => p_subtype_code ,
                            p_division_code  => p_division_code,
                            p_district_code  => p_district_code,
                            p_company_code   => p_company_code ,
                            p_chain_code     => p_chain_code   ,
                            p_area_code      => p_area_code    ,
                            p_region_code    => p_region_code      
                            );              


         

                                     
WHEN EX_NULL_VALUES_COST THEN
     
  
     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6045_ITEM_COST_NULL');
     lc_err_code   := 'XX_INV_6045_ITEM_COST_NULL';    
     lc_errbuf     :=  FND_MESSAGE.GET;
          
     x_status      :=  GC_REC_STATUS_FAIL;                 
     x_error_count :=  'New Item cost cannot be null' ;

     LOG_ERROR(p_exception      =>lc_error_location
              ,p_message        =>lc_errbuf
              ,p_code           =>lc_err_code
             ) ; 


     INSERT_FAILED_RECORDS( p_file_id        => p_file_id  ,
                            p_error_message  => lc_errbuf  ,
                            p_error_code     => lc_err_code,
                            p_item_number    => p_sku ,
                            p_currency       => p_currency  ,
                            p_country        => p_country ,
                            p_average_cost   => 0,
                            x_status         => x_status   ,
                            x_error_count    => x_error_count,
                            p_type_code      => p_type_code    ,
                            p_subtype_code   => p_subtype_code ,
                            p_division_code  => p_division_code,
                            p_district_code  => p_district_code,
                            p_company_code   => p_company_code ,
                            p_chain_code     => p_chain_code   ,
                            p_area_code      => p_area_code    ,
                            p_region_code    => p_region_code      
                            );                            
  WHEN OTHERS THEN
  
     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6008_FAILURE_INS_TEMP2');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

     lc_errbuf      :=   FND_MESSAGE.GET;
     lc_err_code    :=  'XX_INV_6008_FAILURE_STORE_INFO';
     x_status       :=   GC_REC_STATUS_FAIL;
     x_error_count :=   'Fails insertion while loading data in staging table for template. ' || SQLERRM ;     
    
     LOG_ERROR(p_exception      =>lc_error_location
              ,p_message        =>lc_errbuf
              ,p_code           =>lc_err_code
              ) ; 
              
    INSERT_FAILED_RECORDS(   p_file_id        => p_file_id  ,
                             p_error_message  => lc_errbuf  ,
                             p_error_code     => lc_err_code,
                             p_item_number    => p_sku      ,
                             p_currency       => p_currency ,
                             p_country        => p_country  ,
                             p_average_cost   => p_new_cost ,
                             x_status         => x_status   ,
                             x_error_count    => x_error_count  ,
                             p_type_code      => p_type_code    ,
                             p_subtype_code   => p_subtype_code ,
                             p_division_code  => p_division_code,
                             p_district_code  => p_district_code,
                             p_company_code   => p_company_code ,
                             p_chain_code     => p_chain_code   ,
                             p_area_code      => p_area_code    ,
                             p_region_code    => p_region_code   
                             );               
              
END    STORE_INFORMATION;  

PROCEDURE LOAD_AVERAGE_COST_DETAILS (p_file_id       IN    NUMBER   ,
                                     x_status        OUT   VARCHAR2 ,
                                     x_error_count   OUT   VARCHAR2
                                     )
IS

-- +================================================================================+
-- | Name       : LOAD_AVERAGE_COST_DETAILS                                         |
-- |                                                                                |
-- | Description: This procedure loads the data in the custom staging table.        |
-- +================================================================================+

--**************************
-- Declaring local variables
--**************************

lr_buffer               VARCHAR2(4000);
lf_file                 UTL_FILE.FILE_TYPE;

ln_comma                NUMBER;
ln_start                NUMBER     := 1;
ln_record_number        xx_gi_average_cost_stg.record_number%TYPE;
ln_average_cost         xx_gi_average_cost_stg.average_cost%TYPE;
ln_template_number      xx_gi_average_cost_stg.template_number%TYPE;
ln_Company_code         NUMBER;
ln_Chain_code           NUMBER;
ln_Area_code            NUMBER;
ln_Region_code          NUMBER;
ln_row_count            NUMBER       :=  0;
ln_insert               NUMBER       :=  0;

lc_filename             VARCHAR2 (40);
lc_organization         xx_gi_average_cost_stg.organization%TYPE;
lc_item_number          xx_gi_average_cost_stg.item_number%TYPE;
lc_status               VARCHAR2(50);
lc_error_message        VARCHAR2(100);
lc_currency             xx_gi_average_cost_stg.currency%TYPE;
lc_country              xx_gi_average_cost_stg.country_code%TYPE;
lc_type_code            xx_gi_average_cost_stg.type_code%TYPE;
lc_subtype_code         xx_gi_average_cost_stg.subtype_code%TYPE;
lc_Division_code        xx_gi_average_cost_stg.division_code%TYPE;
lc_District_code        xx_gi_average_cost_stg.district_code%TYPE;
lc_Store                xx_gi_average_cost_stg.organization%TYPE;
lc_err_code             VARCHAR2(100);
lc_errbuf               VARCHAR2(5000);
lc_error_count          VARCHAR2(100);
lc_error_location       VARCHAR2(100);
lc_flag                 VARCHAR2(10)    := 'Y';
ln_position_comma       NUMBER;
EX_NULL_VALUES_COST     EXCEPTION;
BEGIN

--Initializing status to Success--
x_status          :=  GC_REC_STATUS_SUCC;
x_error_count     :=  NULL         ;      --Intializing the error count to NULL
lc_error_location := 'XX_GI_AVERAGE_COST_PKG.LOAD_AVERAGE_COST_DETAILS';

--Initializing number of inserts and rowounts as 0--
ln_insert          :=  0;
ln_row_count       :=  0;
--ln_template_number := NULL;
--lc_flag            := 'Y';

--Open the Utl file

lf_file := UTL_FILE.FOPEN(GC_FILE_PATH,p_file_id,'r');

--Chk if utl file opens

IF UTL_FILE.IS_OPEN(lf_file) THEN
  
   --Opening the loop

BEGIN

   WHILE 1=1 LOOP  
      
     
      --Initiazilizing the variables
    
      ln_comma           := 0; --Locating the postion for comma
      ln_start           := 1; --Locating the second comma position
     -- ln_position_comma  := 0;
      lc_flag            := 'Y';

      --Get each line from the file

      UTL_FILE.GET_LINE(lf_file,lr_buffer);
      
     
      --When it enters the loop for the first time it should extract the template information

      -- IF ln_insert = 0 THEN  
      
       --  lc_flag            := 'N';
 
     -- ELSE 
      IF ln_insert  > 0 THEN
      
         BEGIN  
        
             -- Locating the first comma position for comma and the last postion and retreiving the currency

             ln_start        := ln_comma + 1;
             ln_comma        := INSTR(lr_buffer, ',' , ln_start, 1);
             lc_currency     := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));  
             
             
             -- Locating the first comma position for comma and the last postion and retreiving the country

             ln_start        := ln_comma + 1;
             ln_comma        := INSTR(lr_buffer, ',' , ln_start, 1);
             lc_country      := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));           
             
            
             -- Locating the first comma position for comma and the last postion and retreiving the type

             ln_start        := ln_comma + 1;
             ln_comma        := INSTR(lr_buffer, ',' , ln_start, 1);
             lc_type_code    := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));       
             

             -- Locating the first comma position for comma and the last postion and retreiving the sub type code

             ln_start           := ln_comma + 1;
             ln_comma           := INSTR(lr_buffer, ',' , ln_start, 1);
             lc_subtype_code    := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));                    
             

             -- Locating the first comma position for comma and the last postion and retreiving the Division

             ln_start           := ln_comma + 1;
             ln_comma           := INSTR(lr_buffer, ',' , ln_start, 1);
             lc_Division_code   := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));        

             
             -- Locating the first comma position for comma and the last postion and retreiving the District

             ln_start           := ln_comma + 1;
             ln_comma           := INSTR(lr_buffer, ',' , ln_start, 1);
             lc_District_code   := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));        
             
 
             
             -- Locating the first comma position for comma and the last postion and retreiving the Company

             ln_start           := ln_comma + 1;
             ln_comma           := INSTR(lr_buffer, ',' , ln_start, 1);
             ln_Company_code    := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));               
             
            
             -- Locating the first comma position for comma and the last postion and retreiving the chain

             ln_start           := ln_comma + 1;
             ln_comma           := INSTR(lr_buffer, ',' , ln_start, 1);
             ln_Chain_code      := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));      
             
             
             -- Locating the first comma position for comma and the last postion and retreiving the Area

             ln_start           := ln_comma + 1;
             ln_comma           := INSTR(lr_buffer, ',' , ln_start, 1);
             ln_Area_code       := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));         
             
             
             -- Locating the first comma position for comma and the last postion and retreiving the Region

             ln_start           := ln_comma + 1;
             ln_comma           := INSTR(lr_buffer, ',' , ln_start, 1);
             ln_Region_code     := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));                
             
            
             -- Locating the first comma position for comma and the last postion and retreiving the organization

             ln_start        := ln_comma + 1;
             ln_comma        := INSTR(lr_buffer, ',' , ln_start, 1);
             lc_store        := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));  
             
             
            -- Locating the first comma position for comma and the last postion and retreiving the item number

             ln_start := ln_comma + 1;
             ln_comma := INSTR(lr_buffer, ',' , ln_start, 1);
             lc_item_number := Trim(SUBSTR(lr_buffer, ln_start, ln_comma - ln_start));              
             
       
              
             -- Locating the first comma position for comma and the last postion and retreiving the average cost
             ln_start        := ln_comma + 1;
             ln_comma := INSTR(lr_buffer, ',' , ln_start, 1);
                        
             IF ln_comma = 0 THEN                 
                ln_comma  := LENGTH(lr_buffer);
             END IF;
             
             ln_average_cost := SUBSTR(lr_buffer, ln_start, ln_comma - ln_start);
             
            
             
             --After extracting all the information make a call to the STORE_INFORMATION procedure to validate all the data  and to derive the organization from the combination of org parameters.
             
             STORE_INFORMATION    ( p_currency        =>       lc_currency         ,
                                    p_file_id         =>       p_file_id           ,
                                    p_country         =>       lc_country          ,
                                    p_type_code       =>       lc_type_code        ,
                                    p_subtype_code    =>       lc_subtype_code     ,
                                    p_division_code   =>       lc_division_code    ,
                                    p_district_code   =>       lc_District_code    ,
                                    p_company_code    =>       ln_company_code     ,
                                    p_chain_code      =>       ln_chain_code       ,
                                    p_area_code       =>       ln_area_code        ,
                                    p_region_code     =>       ln_region_code      ,
                                    p_store           =>       lc_store            ,
                                    p_sku             =>       lc_Item_Number      ,
                                    p_new_cost        =>       ln_average_cost     ,
                                    x_status          =>       x_status            ,
                                    x_error_count     =>       x_error_count
                                   );  

         EXCEPTION
                                
         
         WHEN OTHERS THEN
             FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6006_FAILURE_INS_TEMP1');
             FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
             FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

             lc_errbuf     :=  FND_MESSAGE.GET;
             lc_err_code   := 'XX_INV_6006_FAILURE_INS_TEMP1';
             x_status      :=  GC_REC_STATUS_FAIL;                 
             x_error_count :=  'Error while extracting data in ' || 'Record Number = '|| ln_insert ;
             
           

             LOG_ERROR(p_exception      =>lc_error_location
                      ,p_message        =>lc_errbuf
                      ,p_code           =>lc_err_code
                     ) ; 
                     
            
         EXIT;                 
         END;

      END IF;--End of IF condition of Template   
      
      --Incrementing the insert value
      ln_insert := ln_insert + 1;      
            
   END LOOP;   
 
   COMMIT; 
      
EXCEPTION    
    WHEN OTHERS THEN
        NULL ; 
END;

ELSE
      
   FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6010_FILE_COULDNOT_OPEN');
   FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
   FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

   lc_errbuf         :=   FND_MESSAGE.GET;
   lc_err_code       :=  'XX_INV_6010_FILE_COULDNOT_OPEN';
   x_status          :=   GC_REC_STATUS_ERR;
   x_error_count     :=  'File could not be open';

   LOG_ERROR(p_exception      =>lc_error_location
            ,p_message        =>lc_errbuf
            ,p_code           =>lc_err_code
            ) ; 

END IF; --Closing the If condition if the File is open or not

UTL_FILE.FCLOSE(lf_file); --Closing the file   

--Make a call to Validate Program

VALIDATE_AVERAGE_COST_DETAILS (p_file_id       => p_file_id  ,
                               x_status        => x_status,
                               x_error_count   => x_error_count
                               );

                         
END LOAD_AVERAGE_COST_DETAILS;   
 


PROCEDURE VALIDATE_AVERAGE_COST_DETAILS (p_file_id       IN   NUMBER   ,
                                         x_status        OUT  VARCHAR2 ,
                                         x_error_count   OUT  VARCHAR2
                                         )
IS


-- +================================================================================+
-- | Name       : VALIDATE_AVERAGE_COST_DETAILS                                     |
-- |                                                                                |
-- | Description: This procedure validate the records in staging table and mark the |
-- |              status as successful or  error.                                   |
-- |              It would also stimulate the MTL  table.                           |
-- |              In case there is no error while inserting the record then the     |
-- |              workflow get initiated.                                           |
-- +================================================================================+

-- Declaring local variables to hold the values from standard oracle tables

ln_master_organization_id        hr_all_organization_units.organization_id%TYPE;
ln_organization_id               mtl_parameters.organization_id%TYPE;
ln_template_number               xx_gi_average_cost_stg.template_number%TYPE;
ln_default_cost_group_id         mtl_parameters.default_cost_group_id%TYPE;
ln_material_account              mtl_parameters.material_account%TYPE;
ln_material_overhead_account     mtl_parameters.material_overhead_account%TYPE;
ln_resource_account              mtl_parameters.resource_account%TYPE;
ln_outside_processing_account    mtl_parameters.outside_processing_account%TYPE;
ln_overhead_account              mtl_parameters.overhead_account%TYPE;
ln_inventory_item_id             mtl_system_items_b.inventory_item_id%TYPE;
lc_primary_uom_code              mtl_system_items_b.primary_uom_code%TYPE;
ln_item_cost                     cst_item_costs.item_cost%TYPE;   

lc_err_code                      VARCHAR2(100);
lc_errbuf                        VARCHAR2(5000);
lc_error_count                   VARCHAR2(100);
lc_error_location                VARCHAR2(100);

--Declaring local variables to check the status and count the number of errors

lc_chk_status                    VARCHAR2(1);
lc_chk_stat                      VARCHAR2(1);
lc_chk_curr                      VARCHAR2(1);
lc_chk_stat_flag                 VARCHAR2(1);
ln_count_Inserted                NUMBER := 0;
ln_count_val_err                 NUMBER := 0;
ln_count_val_succ                NUMBER := 0;

--Declaring local variables to hold the sequence values

ln_seq_mat_trn_s                NUMBER;
ln_seq_source_header_s          NUMBER;

ln_count1                       NUMBER;
ln_count2                       NUMBER;
ln_count3                       number;

lc_lot_control_code             VARCHAR2(10);
lc_revision_qty_control_code    VARCHAR2(10);
lc_serial_number_control_code   VARCHAR2(10);

--Declaring local variables to hold onhand api values values

ln_qty_avail_to_reserve         NUMBER;
lc_status                       VARCHAR2(1);

lc_return_message               VARCHAR2(100);
ln_return_code                  NUMBER;
--************************************************
--Declaring local variables to hold boolean values
--************************************************

lb_lot_control_code             BOOLEAN;
lb_revision_qty_control_code    BOOLEAN;
lb_serial_number_control_code   BOOLEAN;

-- Cursor to derive the master org_id

CURSOR lcu_org_id
IS
SELECT MP.organization_id
FROM   mtl_parameters MP
WHERE  organization_id = master_organization_id;

-- Cursor to derive approver id

CURSOR lcu_approver_id
IS
SELECT FU.user_id
FROM   fnd_user FU
WHERE  FU.user_name  = FND_PROFILE.VALUE('XX_GI_WAC_UPDATE_APPROVER')
AND    TRUNC(SYSDATE) BETWEEN NVL(FU.START_DATE,TRUNC(SYSDATE)) AND NVL(FU.END_DATE,TRUNC(SYSDATE)+1);

--  Cursor to derive record from custom table

CURSOR lcu_record(p_file_id NUMBER)
IS
SELECT XXGA.rowid,
       XXGA.*
FROM   xx_gi_average_cost_stg XXGA
WHERE  XXGA.file_id      = p_file_id
AND    XXGA.status_flag IS NULL
ORDER BY XXGA.record_number;

-- Cursor to derive organization and account details

CURSOR  lcu_org_account_details(p_organization_name VARCHAR2)
IS
SELECT  MP.organization_id
       ,MP.default_cost_group_id
       ,MP.material_account
       ,MP.material_overhead_account
       ,MP.resource_account
       ,MP.outside_processing_account
       ,MP.overhead_account
FROM    mtl_parameters MP,
        org_organization_definitions OOD
WHERE   OOD.organization_name  = p_organization_name
AND     TRUNC(SYSDATE)<=NVL(OOD.disable_date,TRUNC(SYSDATE))
AND     OOD.organization_id=MP.organization_id;

-- Cursor to chk if a single currency is applicable to all inventory organizations

CURSOR  lcu_chk_curr_org(p_organization_id NUMBER,
                         p_currency_code VARCHAR2 
                         )
IS
SELECT 'Y'
FROM   mtl_parameters MP,
       hr_organization_information HOI,
       hr_all_organization_units   HAOU
WHERE
       mp.organization_id = hoi.organization_id
AND    hoi.organization_id= haou.organization_id
AND    mp.organization_id = p_organization_id
AND    hoi.org_information1 IN  (
                              SELECT  TO_CHAR(set_of_books_id)
                              FROM    GL_SETS_OF_BOOKS
                              WHERE   currency_code = p_currency_code
                              ) ;

-- Cursor to chk if organization is having cost Average type or not

CURSOR  lcu_chk_cost_org(p_organization_id NUMBER)
IS
SELECT   'Y'
FROM     mtl_parameters MP
        ,mfg_lookups    ML
        ,org_organization_definitions OOD
WHERE    MP.organization_id  = p_organization_id
AND      ML.lookup_type      = GC_LOOKUP_TYPE
AND      ML.meaning          = GC_MEANING
AND      ML.lookup_code      = mp.primary_cost_method
AND      OOD.organization_id = mp.organization_id
AND      TRUNC(SYSDATE)      <= nvl(ood.disable_date, TRUNC(SYSDATE));

-- Cursor to validate the item 


CURSOR   lcu_val_item(p_item_number     VARCHAR2,
                      p_organization_id NUMBER
                      )
IS
SELECT   MSI.inventory_item_id
        ,MSI.primary_uom_code     
FROM     mtl_system_items_b MSI
WHERE    MSI.segment1             = p_item_number
AND      MSI.inventory_item_status_code ='A'
AND      MSI.ORGANIZATION_ID      = p_organization_id                
AND      MSI.enabled_flag         ='Y'
AND      MSI.costing_enabled_flag ='Y'
AND      TRUNC(SYSDATE)  BETWEEN NVL(MSI.start_date_active,TRUNC(SYSDATE) ) AND NVL(MSI.end_date_active,TRUNC(SYSDATE) +1);

-- Cursor to validate if the item cost > 0  -- 30/10/07 by Meenu Goyal

CURSOR  lcu_val_item_cost(p_inventory_item_id NUMBER
                         ,p_organization_id   NUMBER
                         )
IS
SELECT  CIC.item_cost 
FROM    cst_item_costs     CIC
WHERE   CIC.inventory_item_id = p_inventory_item_id
AND     CIC.organization_id   = p_organization_id
AND     CIC.ITEM_COST         > 0 ;

-- Declaring Cursor to validate the item if it belongs to the master org or not

CURSOR   lcu_master_val_item(p_item_number     VARCHAR2,
                             p_organization_id NUMBER
                             )
IS
SELECT   'Y'
FROM     mtl_system_items_b MSI
WHERE    MSI.segment1                   = p_item_number
AND      MSI.inventory_item_status_code = 'A'
AND      MSI.enabled_flag               = 'Y'
AND      MSI.organization_id            =  p_organization_id
AND      TRUNC(SYSDATE)  BETWEEN NVL(MSI.start_date_active,TRUNC(SYSDATE)) and NVL(MSI.end_date_active,TRUNC(SYSDATE)+1);

-- Declaring Cursor to validate if trx date is in open period

CURSOR   lcu_trx_date_open(p_organization_id NUMBER
                           )
IS
SELECT   'Y'
FROM     org_acct_periods OAP
WHERE    OAP.organization_id      = p_organization_id
AND      OAP.OPEN_FLAG            = 'Y'
AND      TO_CHAR(SYSDATE,'YYYY')  = OAP.period_year
AND      TO_CHAR(SYSDATE,'MON-YY')= OAP.period_name
AND      TRUNC(SYSDATE)  BETWEEN NVL(OAP.period_start_date,TRUNC(SYSDATE) ) AND  NVL(OAP.period_close_date,TRUNC(SYSDATE) +1);

-- Declaring Cursor to select all the validated records

CURSOR lcu_validated_records(p_file_id NUMBER)
IS
SELECT XXGA.rowid,XXGA.*
FROM   xx_gi_average_cost_stg XXGA
WHERE  status_flag          = GC_VAL_SUCC
AND    file_id              = p_file_id;


BEGIN
   --Initiazalizing the status to success
   
   x_status          := GC_REC_STATUS_SUCC;
   x_error_count     := NULL;
   lc_error_location := 'XX_GI_AVERAGE_COST_PKG.VALIDATE_AVERAGE_COST_DETAILS';
   lc_errbuf         := NULL;
   lc_err_code       := NULL;
   
   --Open the main loop to validate and derive various values
   
   
   FOR  lcr_record IN lcu_record(p_file_id)
   LOOP
   
   
   ln_qty_avail_to_reserve  := 0;
   x_status                 := GC_REC_STATUS_SUCC;
   
   --Fetch the Org id and update the staging table in case master org is invalid.

   OPEN  lcu_org_id;
   FETCH lcu_org_id INTO ln_master_organization_id ; 
      IF lcu_org_id%ROWCOUNT = 0 THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6011_MASTER_ORG_ERR');
         FND_MESSAGE.SET_TOKEN('MASTER_ORG',ln_master_organization_id ); 

         lc_errbuf     :=  FND_MESSAGE.GET;
         lc_err_code   := 'XX_INV_6011_MASTER_ORG_ERR';
         x_status      :=  GC_REC_STATUS_ERR;
          
      END IF;  
   CLOSE lcu_org_id;

   --Fetch the Approver id

IF x_status = GC_REC_STATUS_SUCC THEN

   OPEN  lcu_approver_id ;
   FETCH lcu_approver_id  INTO GN_APPROVER_ID;

      IF lcu_approver_id%ROWCOUNT = 0 THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6012_APPR_ERROR');
         FND_MESSAGE.SET_TOKEN('APPROVER_ID',GN_APPROVER_ID ); 

         lc_errbuf     :=  FND_MESSAGE.GET;
         lc_err_code   := 'XX_INV_6012_APPR_ERROR';
         x_status      :=  GC_REC_STATUS_ERR;
     
      END IF; 
   CLOSE lcu_approver_id ;   
   
END IF;

   --Fetching organization and account details

IF x_status = GC_REC_STATUS_SUCC THEN

   OPEN  lcu_org_account_details(lcr_record.organization);
   FETCH lcu_org_account_details INTO ln_organization_id,
                                      ln_default_cost_group_id     ,
                                      ln_material_account          ,
                                      ln_material_overhead_account ,
                                      ln_resource_account          ,
                                      ln_outside_processing_account,
                                      ln_overhead_account  ;

      IF lcu_org_account_details%ROWCOUNT = 0 THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6013_ACC_DETAILS_ERROR');
         FND_MESSAGE.SET_TOKEN('ORG_NAME',lcr_record.organization);

         lc_errbuf     :=  FND_MESSAGE.GET;
         lc_err_code   := 'XX_INV_6013_ACC_DETAILS_ERROR';
         x_status      :=  GC_REC_STATUS_ERR;
  
      END IF;
   CLOSE  lcu_org_account_details;--Closing the loop for organization and account details
END IF;


IF x_status = GC_REC_STATUS_SUCC THEN

   --Check for the organization if this is a valid organization
   
   OPEN  lcu_chk_cost_org(ln_organization_id);
   FETCH lcu_chk_cost_org INTO lc_chk_status;  

      IF lcu_chk_cost_org%ROWCOUNT = 0 THEN

        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6015_CHK_COST_ORG_ERROR');
        FND_MESSAGE.SET_TOKEN('CHK_ORG_COST',ln_organization_id);  

        lc_errbuf     :=  FND_MESSAGE.GET;
        lc_err_code   := 'XX_INV_6015_CHK_COST_ORG_ERROR';
        x_status      :=  GC_REC_STATUS_ERR;
    
     END IF;
   CLOSE  lcu_chk_cost_org; 
END IF;

      --Checking if single currency is used across all inventory organizations
    IF x_status = GC_REC_STATUS_SUCC THEN
   
      OPEN  lcu_chk_curr_org(ln_organization_id,
                             lcr_record.currency
                             );
      FETCH lcu_chk_curr_org INTO lc_chk_curr;
   
         IF lcu_chk_curr_org%ROWCOUNT = 0 THEN
   
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6014_CURR_NOT_SIMILIAR');
            FND_MESSAGE.SET_TOKEN('CHK_ORG_CURR',ln_organization_id);   
   
            lc_errbuf     :=  FND_MESSAGE.GET;
            lc_err_code   := 'XX_INV_6014_CURR_NOT_SIMILIAR';
            x_status      :=  GC_REC_STATUS_ERR;
       
         END IF;
      CLOSE  lcu_chk_curr_org;
   END IF;

   --Check for the active item number 
   
IF x_status = GC_REC_STATUS_SUCC THEN

   OPEN  lcu_val_item(lcr_record.item_number,
                      ln_organization_id
                      );

   FETCH lcu_val_item INTO  ln_inventory_item_id
                           ,lc_primary_uom_code
                          -- ,ln_item_cost
                            ;
       
       IF lcu_val_item%ROWCOUNT = 0 THEN  
       
          FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6016_CHK_VAL_ITEM_ERROR');
          FND_MESSAGE.SET_TOKEN('ITEM',lcr_record.item_number);
          FND_MESSAGE.SET_TOKEN('ORG_ITEM',ln_organization_id);

          lc_errbuf     :=  FND_MESSAGE.GET;
          lc_err_code   := 'XX_INV_6016_CHK_VAL_ITEM_ERROR';
          x_status      :=  GC_REC_STATUS_ERR; 
          
   
        END IF;
   CLOSE lcu_val_item ;   

END IF;

--Chk if the item has cost > 0   30-10-07 Meenu Goyal Added inventory_item_id and organization_id

IF x_status  = GC_REC_STATUS_SUCC THEN


  OPEN  lcu_val_item_cost( ln_inventory_item_id
                          ,ln_organization_id
                          );

  FETCH lcu_val_item_cost INTO ln_item_cost;
        
        IF lcu_val_item_cost%ROWCOUNT = 0 THEN

          FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6046_ITEM_COST');

          lc_errbuf     :=  FND_MESSAGE.GET;
          lc_err_code   := 'XX_INV_6046_ITEM_COST';
          x_status      :=  GC_REC_STATUS_ERR; 
          
        END IF;
        
  CLOSE lcu_val_item_cost;

END IF;

   --Check for the active item number in master org
IF x_status = GC_REC_STATUS_SUCC THEN

   OPEN  lcu_master_val_item(lcr_record.item_number,
                             ln_master_organization_id
                           );

   FETCH lcu_master_val_item INTO  lc_chk_stat ; 

      IF lcu_master_val_item%ROWCOUNT = 0 THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6017_MAS_VAL_ITEM_ERROR');
         FND_MESSAGE.SET_TOKEN('ITEM',lcr_record.item_number);
         FND_MESSAGE.SET_TOKEN('ORG',ln_master_organization_id);

         lc_errbuf     :=  FND_MESSAGE.GET;
         lc_err_code   := 'XX_INV_6017_MAS_VAL_ITEM_ERROR';
         x_status      :=  GC_REC_STATUS_ERR;
  
      END IF;  
   CLOSE lcu_master_val_item ;
   
END IF;

IF x_status = GC_REC_STATUS_SUCC THEN

   --Check for the trx_date if it lies in open period

   OPEN  lcu_trx_date_open(ln_organization_id
                     );

   FETCH lcu_trx_date_open INTO  lc_chk_stat_flag ;

      IF lcu_trx_date_open%ROWCOUNT = 0 THEN

         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6018_DATE_VAL_ERROR');
         FND_MESSAGE.SET_TOKEN('ORG',ln_organization_id);

         lc_errbuf     :=  FND_MESSAGE.GET;
         lc_err_code   := 'XX_INV_6018_DATE_VAL_ERROR';
         x_status      :=  GC_REC_STATUS_ERR;
         
      END IF;  
   CLOSE lcu_trx_date_open ; 
   
END IF;

   --Call ONHAND QUANTITY API to derive the onhand qty for the item
IF x_status = GC_REC_STATUS_SUCC THEN
 
    
   ONHAND_QUANTITY_API( p_organization_id       => ln_organization_id
                       ,p_inventory_item_id     => ln_inventory_item_id
                       ,p_item_number           => lcr_record.item_number                                  
                       ,x_return_msg            => lc_return_message
                       ,x_return_code           => ln_return_code
                       ,x_qty_onhand            => ln_qty_avail_to_reserve
                      ) ;
                      
     --Checking for the status of onhand quantity api

   IF  ln_return_code = 2 THEN
   
      FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6019_ONHAND_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf     :=  FND_MESSAGE.GET;
      lc_err_code   := 'XX_INV_6019_ONHAND_ERROR';
      x_status      :=  GC_REC_STATUS_ERR;      
    
   END IF;

END IF;

      -- Update Stg table with derived values for successful records

   IF (x_status = GC_REC_STATUS_SUCC) THEN
   
                   x_status :=  GC_REC_STATUS_SUCC;

                   UPDATE_RECORD  (p_organization_id           =>   ln_organization_id
                                 , p_master_organization_id    =>   ln_master_organization_id
                                 , p_default_cost_group_id     =>   ln_default_cost_group_id
                                 , p_material_account          =>   ln_material_account
                                 , p_material_overhead_account =>   ln_material_overhead_account
                                 , p_resource_account          =>   ln_resource_account
                                 , p_outside_processing_account=>   ln_outside_processing_account
                                 , p_overhead_account          =>   ln_overhead_account
                                 , p_inventory_item_id         =>   ln_inventory_item_id
                                 , x_status                    =>   x_status
                                 , p_primary_uom_code          =>   lc_primary_uom_code
                                 , p_approver_id               =>   GN_APPROVER_ID
                                 , p_qty_avail_to_reserve      =>   ln_qty_avail_to_reserve
                                 , p_item_cost                 =>   ln_item_cost
                                 , p_rowid                     =>   lcr_record.rowid    
                                 , p_error_code                =>   GC_REC_STATUS_SUCC   
                                 , p_error_message             =>   GC_REC_STATUS_SUCC
                                 );
                                 
       

   ELSE 
          -- Update Stg table with Error status for records which failed validation
                   x_status           := GC_REC_STATUS_ERR;  
                   
               
                   UPDATE_RECORD  (p_organization_id           =>   ln_organization_id
                                 , p_master_organization_id    =>   ln_master_organization_id
                                 , p_default_cost_group_id     =>   ln_default_cost_group_id
                                 , p_material_account          =>   ln_material_account
                                 , p_material_overhead_account =>   ln_material_overhead_account
                                 , p_resource_account          =>   ln_resource_account
                                 , p_outside_processing_account=>   ln_outside_processing_account
                                 , p_overhead_account          =>   ln_overhead_account
                                 , p_inventory_item_id         =>   ln_inventory_item_id
                                 , x_status                    =>   x_status
                                 , p_primary_uom_code          =>   lc_primary_uom_code
                                 , p_approver_id               =>   GN_APPROVER_ID
                                 , p_qty_avail_to_reserve      =>   ln_qty_avail_to_reserve
                                 , p_item_cost                 =>   ln_item_cost
                                 , p_rowid                     =>   lcr_record.rowid    
                                 , p_error_code                =>   lc_err_code
                                 , p_error_message             =>   lc_errbuf);
                                 
                                 
                                    

   END IF; --End of If conditions for success and error      */
           
END LOOP; 

COMMIT;   

--Counting the number of records failed validation--
BEGIN 

   SELECT count(*)
   INTO   ln_count_val_err
   FROM   xx_gi_average_cost_stg
   WHERE  status_flag               = GC_VAL_ERR
   AND    file_id                   = p_file_id;     
   

    
EXCEPTION 
   WHEN OTHERS THEN 
      FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6020_COUNT_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf     :=  FND_MESSAGE.GET;
      lc_err_code   := 'XX_INV_6020_COUNT_ERROR';
      x_status      :=  GC_REC_STATUS_ERR;

      LOG_ERROR(p_exception      =>lc_error_location
               ,p_message        =>lc_errbuf
               ,p_code           =>lc_err_code
                ) ; 
END;




--******************************************
--Open the cursor for all successful records
--*******************************************

FOR lcr_validated_records IN lcu_validated_records(p_file_id) 
LOOP

--Derive a sequence value for trx interface id  
 
BEGIN 
    
  --Insert into the standard mtl transactions interface table

  INSERT INTO INV.mtl_transactions_interface (
                                             transaction_interface_id
                                            ,source_code
                                            ,source_line_id
                                            ,source_header_id
                                            ,process_flag
                                            ,transaction_mode
                                            ,lock_flag
                                            ,last_update_date
                                            ,creation_date
                                            ,created_by
                                            ,last_updated_by
                                            ,organization_id
                                            ,transaction_quantity
                                            ,transaction_uom
                                            ,transaction_date
                                            ,transaction_type_id
                                            ,cost_group_id
                                            ,material_account
                                            ,material_overhead_account
                                            ,resource_account
                                            ,outside_processing_account
                                            ,overhead_account
                                            ,new_average_cost
                                            ,inventory_item_id
                                            ,transaction_reference
                                            ,attribute6)
                                     VALUES (
                                              mtl_material_transactions_s.nextval                 --  TRANSACTION INTERFACE ID
                                            , 'OD'                                                --  GV_SOURCE_NAME
                                            , XX_GI_AVERAGE_COST_S.nextval                        --  SOURCE_HEADER_ID
                                            , XX_GI_AVERAGE_COST_S.currval                        --  SOURCE_LINE_ID                                  
                                            , GN_PROCESS_FLAG                                     --  PROCESS_FLAG
                                            , GN_TRANSACTION_MODE                                 --  TRANSACTION_MODE
                                            , GN_LOCK_FLAG                                        --  LOCK FLAG
                                            , SYSDATE                                             --  CREATION_DATE
                                            , SYSDATE                                             --  LAST_UPDATE_DATEE
                                            , FND_GLOBAL.USER_ID                                  --  LAST_UPDATED_BY
                                            , FND_GLOBAL.USER_ID                                  --  CREATED_BY
                                            , lcr_validated_records.organization_id               --  ORGANIZATION_ID
                                            , 0                                                   --  TRANSACTION_QUANTITY
                                            , lcr_validated_records.primary_uom                   --  TRANSACTION_UOM
                                            , SYSDATE                                             --  TRANSACTION_DATE
                                            , 80                                                  --  TRANSACTION_TYPE_ID
                                            , lcr_validated_records.cost_group_id                 --  COST_GROUP_ID
                                            , lcr_validated_records.material_account              --  MATERIAL_ACCOUNT
                                            , lcr_validated_records.material_overhead_account     --  MATERIAL_OVERHEAD_ACCOUNT
                                            , lcr_validated_records.resource_account              --  RESOURCE_ACCOUNT
                                            , lcr_validated_records.outside_processing_account    --  OUTSIDE_PROCESSING_ACCOUNT
                                            , lcr_validated_records.overhead_account              --  OVERHEAD_ACCOUNT
                                            , lcr_validated_records.average_cost                  --  NEW_AVERAGE_COST
                                            , lcr_validated_records.inventory_item_id             --  INVENTORY_ITEM_ID
                                            , p_file_id                                                             
                                            , GN_APPROVER_ID
                                            );

  EXCEPTION   
  WHEN OTHERS THEN

     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6021_INSERT_ERROR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

     lc_errbuf     :=  FND_MESSAGE.GET;
     lc_err_code   := 'IE'||'XX_INV_6021_INSERT_ERROR';
     x_status      :=  GC_REC_STATUS_ERR ;     
  
     LOG_ERROR(p_exception      =>lc_error_location
              ,p_message        =>lc_errbuf
              ,p_code           =>lc_err_code
              ) ; 
    
    
    UPDATE_RECORD  (p_organization_id           =>  NULL
                 , p_master_organization_id    =>   NULL 
                 , p_default_cost_group_id     =>   NULL
                 , p_material_account          =>   NULL
                 , p_material_overhead_account =>   NULL
                 , p_resource_account          =>   NULL
                 , p_outside_processing_account=>   NULL
                 , p_overhead_account          =>   NULL
                 , p_inventory_item_id         =>   NULL
                 , x_status                    =>   x_status     
                 , p_primary_uom_code          =>   NULL          
                 , p_approver_id               =>   NULL         
                 , p_qty_avail_to_reserve      =>   NULL         
                 , p_item_cost                 =>   NULL   
                 , p_rowid                     =>   lcr_validated_records.rowid              
                 , p_error_code                =>   lc_err_code            
                 , p_error_message             =>   lc_errbuf );                              
                            
  END;   
  
   
  END LOOP;  
  
  ROLLBACK;   --Rollback of complete insert

  --Counting the number of rows errored out while inserting into Interface table

  BEGIN
     SELECT count(*)
     INTO   ln_count_Inserted
     FROM   xx_gi_average_cost_stg XXGA
     WHERE  status_flag             =  GC_INT_ERR
     AND    file_id                 =  p_file_id;

  EXCEPTION
     WHEN OTHERS THEN 
          FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6022_UNEXP_ERROR_COUNT');
          FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

          lc_errbuf     :=  FND_MESSAGE.GET;
          lc_err_code   := 'XX_INV_6022_UNEXP_ERROR_COUNT';
          x_status      :=  GC_REC_STATUS_ERR;

         LOG_ERROR(p_exception      =>lc_error_location
                  ,p_message        =>lc_errbuf
                  ,p_code           =>lc_err_code
                   ) ; 
  END;
  
  
  BEGIN 
  
     SELECT count(*)
     INTO   ln_count_val_succ
     FROM   xx_gi_average_cost_stg
     WHERE  status_flag               = GC_VAL_SUCC
     AND    file_id                   = p_file_id;     
     
      
  EXCEPTION 
     WHEN OTHERS THEN 
        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6020_COUNT_ERROR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
  
        lc_errbuf     :=  FND_MESSAGE.GET;
        lc_err_code   := 'XX_INV_6020_COUNT_ERROR';
        x_status      :=  GC_REC_STATUS_ERR;
  
        LOG_ERROR(p_exception      =>lc_error_location
                 ,p_message        =>lc_errbuf
                 ,p_code           =>lc_err_code
                  ) ; 
END;

--Returning the total error count--    

x_error_count     := ln_count_val_err +  ln_count_Inserted ;
GN_ERROR_COUNT    := x_error_count;


IF x_error_count > 0 then

   x_status := GC_REC_STATUS_ERR;

END IF;

  --Trigger the workflow process .



IF ln_count_val_succ > 0  THEN

  WF_ENGINE.CREATEPROCESS ( itemtype =>  GC_ITEM_TYPE
                           ,itemkey  =>  to_char(p_file_id )
                           ,process  => 'XXGIAVGCOST');   
 

 --Start the process
  
 WF_ENGINE.STARTPROCESS  ( itemtype =>  GC_ITEM_TYPE
                          ,itemkey  =>  to_char(p_file_id )
                         );
                         
 COMMIT;  
 
END IF; 

END  VALIDATE_AVERAGE_COST_DETAILS;


PROCEDURE ONHAND_QUANTITY_API  (p_organization_id    IN           NUMBER
                               ,p_inventory_item_id  IN           NUMBER
                               ,p_item_number        IN           VARCHAR2
                               ,x_qty_onhand         OUT NOCOPY   NUMBER
                               ,x_return_code        OUT NOCOPY   NUMBER
                               ,x_return_msg         OUT NOCOPY   VARCHAR2
                              )

-- +================================================================================+
-- | Name       : ONHAND_QUANTITY_API                                               |
-- |                                                                                |
-- | Description: This procedure would derive the onhand quantity for a item in an  |
-- |              organization.                                                     |
-- +================================================================================+
IS

ln_msg_count                  NUMBER;
ln_reservable_qty_onhand      NUMBER;
ln_qty_suggested              NUMBER;
ln_qty_avail_to_transact      NUMBER;
ln_qty_avail_to_reserve       NUMBER;
ln_qty_onhand                 NUMBER;
ln_qty_reserved               NUMBER;
li_tree_mode                  INTEGER;

lc_error_code                 VARCHAR2(50);
lc_status_flag                VARCHAR2(50);
x_error_text                  VARCHAR2(1000);
lc_msg_data                   VARCHAR2(1000);
lc_ret_code                   VARCHAR2(10);
lc_exception_msg              VARCHAR2(1000);
--lc_calling_program            VARCHAR2(50) := 'ONHAND_QUANTITY_API';
lc_return_status  VARCHAR2(30);

 --Error variables declaration

lc_err_code                   VARCHAR2(100);
lc_errbuf                     VARCHAR2(5000);

lc_error_location             VARCHAR2(100);


BEGIN

    lc_error_location := 'XX_GI_AVERAGE_COST_PKG.ONHAND_QUANTITY_API';    
    
    inv_quantity_tree_pub.clear_quantity_cache;
    li_tree_mode := inv_quantity_tree_pub.g_transaction_mode;  
    
    -- Calling API top fetch the available to reserve quantity
    inv_quantity_tree_pub.query_quantities(p_api_version_number  => 1.0
                                          ,p_init_msg_lst        => GC_F
                                          ,x_return_status       => lc_return_status
                                          ,x_msg_count           => ln_msg_count
                                          ,x_msg_data            => lc_msg_data
                                          ,p_organization_id     => p_organization_id
                                          ,p_inventory_item_id   => p_inventory_item_id
                                          ,p_tree_mode           => li_tree_mode
                                          ,p_is_revision_control => FALSE
                                          ,p_is_lot_control      => FALSE
                                          ,p_is_serial_control   => FALSE
                                          ,p_revision            => NULL
                                          ,p_lot_number          => NULL
                                          ,p_lot_expiration_date => NULL
                                          ,p_subinventory_code   => NULL
                                          ,p_locator_id          => NULL
                                          ,p_cost_group_id       => NULL
                                          ,p_onhand_source       => 3
                                          ,x_qoh                 => x_qty_onhand
                                          ,x_rqoh                => ln_reservable_qty_onhand
                                          ,x_qr                  => ln_qty_reserved
                                          ,x_qs                  => ln_qty_suggested
                                          ,x_att                 => ln_qty_avail_to_transact
                                          ,x_atr                 => ln_qty_avail_to_reserve
                                     );  
                                     

   IF    lc_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN

          x_return_code   := 2;
          x_return_msg := 'Unexpected Error after calling standard API - inv_quantity_tree_pub.query_quantities, to fetch On Hand quantity for the Item: '||p_item_number;

          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;  

    ELSIF lc_return_status = FND_API.G_RET_STS_ERROR THEN

          x_return_code   := 2;
          x_return_msg :=  'Error after calling standard API - inv_quantity_tree_pub.query_quantities, to fetch On Hand quantity for the Item: '||p_item_number;  

          RAISE FND_API.G_EXC_ERROR;                          
    ELSE
          x_qty_onhand  := x_qty_onhand;
          x_return_code := 0;
    END IF;                                  

    EXCEPTION
        WHEN OTHERS THEN    
           FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6023_UNEXP_ONHAND_QTY');
           FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
           FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

           lc_errbuf     :=  FND_MESSAGE.GET;
           lc_err_code   := 'XX_INV_6023_UNEXP_ONHAND_QTY';


           LOG_ERROR(p_exception      =>lc_error_location
                    ,p_message        =>lc_errbuf
                    ,p_code           =>lc_err_code
                    ) ; 

END ONHAND_QUANTITY_API;


PROCEDURE CHECK_APPROVER (ItemType       IN   VARCHAR2
                         ,ItemKey        IN   VARCHAR2
                         ,Actid          IN   NUMBER
                         ,funcmode       IN   VARCHAR2
                         ,resultout      OUT  VARCHAR2
                         )
IS

-- +================================================================================+
-- | Name       : CHECK_APPROVER                                                    |
-- |                                                                                |
-- |Description:                                                                    |
-- |This Procedure forms part of the Workflow Approval Process,chks if requestor_id |
-- |is not equal to approver id and then notify the approver.                       |
-- +================================================================================+

--*************************
--Declaring local variables
--**************************

lc_req_email_add              FND_USER.EMAIL_ADDRESS%TYPE;
lc_app_email_add              FND_USER.EMAIL_ADDRESS%TYPE;
lc_requestor_name             FND_USER.USER_NAME%TYPE;
lc_approver_name              FND_USER.USER_NAME%TYPE ;
lc_role_name                  VARCHAR2(1000);
lc_role_display_name          VARCHAR2(1000);
lc_email_format               VARCHAR2(1000);
lc_email_address              VARCHAR2(1000);
lc_role_name_req              VARCHAR2(1000);
lc_role_display_name_req      VARCHAR2(1000);

--Error variables declaration
lc_err_code                   VARCHAR2(100);
lc_errbuf                     VARCHAR2(5000);
lc_error_location             VARCHAR2(100);

ln_reminder_count              NUMBER;
ln_profile_value               NUMBER;


BEGIN
 
 lc_error_location := 'XX_GI_AVERAGE_COST_PKG.CHECK_APPROVER';
 lc_email_format   := 'MAILTEXT';
 
--Other than RUN mode, all other function modes are not implemented
 IF (funcmode <> WF_ENGINE.ENG_RUN) THEN
       Resultout  := WF_ENGINE.eng_null;
       RETURN;
 END IF;

--Deriving email address by passing  requestor id

BEGIN
  SELECT email_address,
         user_name
  INTO   lc_req_email_add,
         lc_requestor_name
  FROM
         FND_USER
  WHERE  user_id = GN_USER_ID;
  
EXCEPTION   

   WHEN OTHERS THEN
     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6024_UNEXP_REQ_NAME');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

     lc_errbuf     :=  FND_MESSAGE.GET;
     lc_err_code   := 'XX_INV_6024_UNEXP_REQ_NAME';

     LOG_ERROR(p_exception      =>lc_error_location
              ,p_message        =>lc_errbuf
              ,p_code           =>lc_err_code
              ) ; 

   RESULTOUT := WF_ENGINE.ENG_COMPLETED||':'||'FALSE';
   RETURN;

END;

--Deriving email address by passing approver id

BEGIN
  SELECT email_address,
         user_name
  INTO   lc_app_email_add,
         lc_approver_name
  FROM
         FND_USER
  WHERE  user_id = GN_APPROVER_ID; 

EXCEPTION
   WHEN OTHERS THEN
     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6025_UNEXP_APP_NAME');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

     lc_errbuf     :=  FND_MESSAGE.GET;
     lc_err_code   := 'XX_INV_6025_UNEXP_APP_NAME';

     LOG_ERROR(p_exception      =>lc_error_location
              ,p_message        =>lc_errbuf
              ,p_code           =>lc_err_code
              ) ; 

   RESULTOUT := WF_ENGINE.ENG_COMPLETED||':'||'FALSE';
   RETURN;

END;
      
   
--Comparing approver id with requestor id  

IF (GN_APPROVER_ID <> GN_REQUESTOR_ID)  THEN    


    wf_engine.SetItemAttrText(itemtype => ItemType,
                              itemkey  => ItemKey,
                              aname    => 'APPROVER_ROLE_NAME',
                              avalue   => lc_approver_name
                             );
     
         
    wf_engine.SetItemAttrText(itemtype => ItemType,
                              itemkey  => ItemKey,
                              aname    => 'REQUESTOR_ROLE_NAME',
                              avalue   => lc_requestor_name);
    
        
    --Set the attribute values for approver email id

    wf_engine.SetItemAttrText( itemtype => ItemType,
                               itemkey  => ItemKey,
                               aname    => 'APPROVER_EMAIL_ID',
                               avalue   => lc_app_email_add
                               );
                             
    
        
    
   --Set the attribute values for requestor email address                              
                              
    wf_engine.SetItemAttrText( itemtype => ItemType,                              
                               itemkey  => ItemKey,                              
                               aname    => 'REQUESTOR_EMAIL_ID',                              
                               avalue   => lc_req_email_add);                             
    
   --Set the attribute values for file id    
     
    wf_engine.SetItemAttrText( itemtype  =>  ItemType,
                               itemkey   =>  ItemKey,
                               aname     =>  'FILE_ID',
                               avalue    =>  ITEMKEY);   
   
   --Set the attribute values for document

    wf_engine.SetItemAttrText( itemtype => ItemType,
                               itemkey  => ItemKey,
                               aname    => 'DATA_DOCUMENT',
                               avalue   => 'PLSQL:XX_GI_AVERAGE_COST_PKG.GET_VALID_AVERAGE_COST_DETAILS/' || ItemKey);  

   --Set the attribute values for report document

    wf_engine.SetItemAttrText( itemtype => ItemType,
                               itemkey  => ItemKey,
                               aname    => 'REPORT_DOCUMENT',
                               avalue   => 'PLSQL:XX_GI_AVERAGE_COST_PKG.GET_WAC_IMPACT_REPORT/' ||Itemkey);   

 
    wf_engine.SetItemAttrNumber(itemtype => ItemType,
                                 itemkey  => ItemKey,
                                 aname    => 'PROFILE_VALUE',
                                 avalue   =>  SUBSTR(FND_PROFILE.VALUE('XX_GI_WAC_APPROVAL_TIME_LIMIT'),1,2)
                                 );

    --Set the attribute values for reminder counter 

    wf_engine.SetItemAttrNumber(itemtype  =>  ItemType,
                                itemkey  =>  ItemKey,
                                aname    => 'REMINDER_COUNT',
                                avalue   =>  SUBSTR(FND_PROFILE.VALUE('XX_GI_WAC_APPROVAL_TIME_LIMIT'),
                                             (INSTR(FND_PROFILE.VALUE('XX_GI_WAC_APPROVAL_TIME_LIMIT'),';')+1))-1                                               
                               );
                                
    
    Resultout := wf_engine.eng_completed||':'||'NO';   
    RETURN;  
   
ELSE 

    Resultout := Wf_Engine.eng_completed||':'||'TRUE';
    RETURN; 
   
END IF;
    
EXCEPTION  
WHEN OTHERS THEN

     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6026_UNEXP_CHK_APP');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

     lc_errbuf     :=  FND_MESSAGE.GET;
     lc_err_code   := 'XX_INV_6026_UNEXP_CHK_APP';

     LOG_ERROR(p_exception      =>lc_error_location
              ,p_message        =>lc_errbuf
              ,p_code           =>lc_err_code
              ) ; 

     WF_CORE.CONTEXT('XX_GI_AVERAGE_COST_PKG'
                     ,'CHECK_APPROVER'
                     ,ItemType
                     ,ItemKey
                     ,to_char(actid)
                     ,funcmode
                     );

     RESULTOUT := WF_ENGINE.ENG_COMPLETED||':'||'FALSE';
     RETURN;

END CHECK_APPROVER;


PROCEDURE GET_WAC_IMPACT_REPORT( DOCUMENT_ID        IN NUMBER,
                                 DISPLAY_TYPE       IN VARCHAR2,
                                 DOCUMENT           IN OUT CLOB,
                                 DOCUMENT_TYPE      IN OUT VARCHAR2
                                )

-- +================================================================================+
-- | Name       : GET_WAC_IMPACT_REPORT                                             |
-- |                                                                                |
-- |Description:                                                                    |
-- |This Procedure display the total impact of WAC on items and organization        |
-- +================================================================================+

IS

ln_difference          NUMBER := 0;
ln_total               NUMBER := 0 ;
ln_items_no            NUMBER := 0;
ln_orgs_no             NUMBER := 0;
ln_all_total           NUMBER := 0;

ln_onhand_quantity     xx_gi_average_cost_stg.onhand_quantity%TYPE;
ln_old_cost            xx_gi_average_cost_stg.old_average_cost%TYPE;
ln_average_cost        xx_gi_average_cost_stg.average_cost%TYPE;
ln_template_number     xx_gi_average_cost_stg.template_number%TYPE;
lc_country_code        xx_gi_average_cost_stg.country_code%TYPE;
lc_type_code           xx_gi_average_cost_stg.type_code%TYPE;
lc_sub_type_code       xx_gi_average_cost_stg.subtype_code%TYPE;
lc_div_code            xx_gi_average_cost_stg.division_code%TYPE;
lc_dis_code            xx_gi_average_cost_stg.district_code%TYPE;
lc_comp_code           xx_gi_average_cost_stg.company_code%TYPE;
lc_chain_code          xx_gi_average_cost_stg.chain_code%TYPE;
lc_area_code           xx_gi_average_cost_stg.area_code%TYPE;
lc_region_code         xx_gi_average_cost_stg.region_code%TYPE;

lc_document1           CLOB := NULL;
lc_line_document       CLOB := NULL;
lc_document2           CLOB := NULL;
lc_document3           CLOB := NULL;
lc_document4           CLOB := NULL;
lc_document_html       CLOB := NULL;
lc_document_heading_html CLOB := NULL;
lc_document_line_html  CLOB := NULL;
lc_organization        mtl_parameters.organization_code%TYPE;
lc_item                mtl_system_items_b.segment1%TYPE;

--
-- Exception Variable
--
lc_errbuf          VARCHAR2(4000);
lc_err_code        VARCHAR2(1000);
lc_error_location  VARCHAR2(100);

lc_currency        VARCHAR2(40);


--****************************************
--Declare a cursor to get the line records
--****************************************

CURSOR lcu_get_line_records
IS
SELECT  XXGA.organization                               ,
        XXGA.item_number                                ,
        XXGA.average_cost                               ,
        XXGA.old_average_cost                           ,
        XXGA.template_number                            ,
        XXGA.onhand_quantity                            ,
      ( XXGA.average_cost - XXGA.old_average_cost) difference,
    ( ( XXGA.average_cost - XXGA.old_average_cost)  * XXGA.onhand_quantity ) total
FROM      xx_gi_average_cost_stg  XXGA
WHERE     XXGA.status_flag             = GC_VAL_SUCC
AND       file_id                      = DOCUMENT_ID
ORDER BY  XXGA.item_number
        , XXGA.organization;  



--****************************************
--Declare a cursor to get the total of sum
--*****************************************

CURSOR lcu_get_line_total
IS
SELECT  SUM(( XXGA.average_cost - XXGA.old_average_cost)  * XXGA.onhand_quantity ) report_total
FROM    xx_gi_average_cost_stg  XXGA
WHERE   XXGA.status_flag             = GC_VAL_SUCC
AND     file_id                      = DOCUMENT_ID;

--********************************************
--Declare a cursor to get the parameter values
--********************************************

CURSOR  lcu_get_parameter_values
IS
SELECT  DISTINCT XXGA.country_code                      ,
        XXGA.type_code                                  ,
        XXGA.subtype_code                               ,
        XXGA.division_code                              ,
        XXGA.district_code                              ,
        XXGA.company_code                               ,
        XXGA.chain_code                                 ,
        XXGA.area_code                                  ,
        XXGA.region_code
FROM    xx_gi_average_cost_stg  XXGA
WHERE   XXGA.status_flag                    = GC_VAL_SUCC
AND     file_id                             = DOCUMENT_ID;

--*************************************************************
--Declare a cursor to get the number of items and orgs impacted
--*************************************************************

CURSOR  lcu_get_item_org_no
IS 
SELECT  COUNT(distinct organization),
        count(distinct item_number) 
FROM    xx_gi_average_cost_stg 
WHERE   file_id      = DOCUMENT_ID
AND     status_flag  = GC_VAL_SUCC;

--*******************************************************************
--Declare a cursor to get the template number and functional currency
--*******************************************************************
CURSOR  lcu_get_tem_curr
IS 
SELECT distinct template_number ,
       currency
FROM   xx_gi_average_cost_stg  XXGA
WHERE  XXGA.status_flag                    = GC_VAL_SUCC
AND    XXGA.file_id                        = document_id;   


BEGIN
            
      lc_error_location  := 'XX_GI_AVERAGE_COST_PKG.GET_WAC_IMPACT_REPORT';
      ln_template_number := 0;   
      lc_currency        := NULL;      
      ln_all_total       := 0;
      
      --Get the currency and the template number --CR Change  5-10-07 By Meenu 
      --No need of Currency and template number on the header,No need of parameters for template 2
      
   /*   FOR lcr_get_tem_curr IN lcu_get_tem_curr
      LOOP
       
          ln_template_number := lcr_get_tem_curr.template_number;      
          lc_currency        := lc_currency  || lcr_get_tem_curr.currency || ',' ;
 
      END LOOP;    */
      
         -- lc_currency := SUBSTR(lc_currency,1,length(lc_currency) -1);     
   
      --Open the cursor and get the parameter values if template number = 2

     /* IF ln_template_number = 2 THEN 
      
           OPEN  lcu_get_parameter_values  ;
           FETCH lcu_get_parameter_values INTO lc_country_code  ,
                                                lc_type_code     ,
                                                lc_sub_type_code ,
                                                lc_div_code      ,
                                                lc_dis_code      ,
                                                lc_comp_code     ,
                                                lc_chain_code    ,
                                                lc_area_code     ,
                                                lc_region_code   ;
         
                 IF display_type     = 'text/html' THEN

                       document_type    :=  'text/plain'; 
                       lc_document_html :=   'Parameters selected on template # 2:   '           || SYSDATE          ||'<BR>'||
                                             '<HR><BR>'                                          || 
                                             'Country_Code: '                                    || lc_country_code  || '<BR>'||
                                             'Type_Code: '                                       || lc_sub_type_code || '<BR>'||
                                             'Subtype_Code: '                                    || lc_div_code      || '<BR>'||
                                             'Division_Code: '                                   || lc_dis_code      || '<BR>'||
                                             'District_Code: '                                   || lc_country_code  || '<BR>'||
                                             'Company_Code: '                                    || lc_comp_code     || '<BR>'||
                                             'Chain_Code: '                                      || lc_chain_code    || '<BR>'||
                                             'Area_Code: '                                       || lc_area_code     || '<BR>'||
                                             'Region_Code:'                                      || lc_area_code     || '<BR>';                  
                 ELSE  
                 
                        document_type:=  'text/plain'; 
                        --Displaying parameter values
                        lc_document4 := lc_document4||'Parameters selected on template # 2:  '         ||CHR(13)||CHR(10);
                        lc_document4 := lc_document4||'Country_Code: '                                 ||lc_country_code        ||CHR(13)||CHR(10);
                        lc_document4 := lc_document4||'Type_Code: '                                    ||lc_type_code           ||CHR(13)||CHR(10);
                        lc_document4 := lc_document4||'Subtype_Code: '                                 ||lc_sub_type_code       ||CHR(13)||CHR(10);
                        lc_document4 := lc_document4||'Division_Code: '                                ||lc_div_code            ||CHR(13)||CHR(10);
                        lc_document4 := lc_document4||'District_Code: '                                ||lc_dis_code            ||CHR(13)||CHR(10);
                        lc_document4 := lc_document4||'Company_Code: '                                 ||lc_comp_code           ||CHR(13)||CHR(10);
                        lc_document4 := lc_document4||'Chain_Code: '                                   ||lc_chain_code          ||CHR(13)||CHR(10);
                        lc_document4 := lc_document4||'Area_Code: '                                    ||lc_area_code           ||CHR(13)||CHR(10);
                        lc_document4 := lc_document4||'Region_Code: '                                  ||lc_region_code         ||CHR(13)||CHR(10);

                 END IF;
                 
                 IF lcu_get_parameter_values%ROWCOUNT = 0 THEN

                   FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6027_PAR_NOT_FOUND');

                   lc_errbuf   := FND_MESSAGE.GET;
                   lc_err_code := 'XX_INV_6027_PAR_NOT_FOUND';

                   LOG_ERROR(p_exception      =>lc_error_location
                            ,p_message        =>lc_errbuf
                            ,p_code           =>lc_err_code
                            ) ;    
                 END IF; 
             
           CLOSE  lcu_get_parameter_values;
             
         END IF;   */
        

      --Deriving the number of Items and Orgs that would be impacted
      
     OPEN  lcu_get_item_org_no;
      FETCH lcu_get_item_org_no INTO  ln_orgs_no,
                                      ln_items_no ;
            
                                               
            IF lcu_get_item_org_no%ROWCOUNT = 0 THEN
         
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6028_ERR_ORG_ITEM_NO');
         
               lc_errbuf   := FND_MESSAGE.GET;
               lc_err_code := 'XX_INV_6028_ERR_ORG_ITEM_NO';
         
               LOG_ERROR(p_exception      =>lc_error_location
                        ,p_message        =>lc_errbuf                          
                        ,p_code           =>lc_err_code                          
                        ) ;                              
            END IF;     
      
      CLOSE  lcu_get_item_org_no;     
      
      --CR Change Sequence of Heading changed By Meenu 5-10-07 ITEM,ORGANIZATION,ONHAND_QUANTITY,OLD_AVERAGE_COST,AVERAGE_COST,CHANGE ,VALUE CHANGE 
      
      FOR lcr_get_line_records IN lcu_get_line_records   
      LOOP 
      
          lc_line_document  :=lc_line_document||RPAD(lcr_get_line_records.item_number,20,' ')               ||CHR(09);
          lc_line_document  :=lc_line_document||RPAD(lcr_get_line_records.organization,30,' ')              ||CHR(09);          
          lc_line_document  :=lc_line_document||RPAD(lcr_get_line_records.onhand_quantity,10,' ')           ||CHR(09);
          lc_line_document  :=lc_line_document||RPAD(lcr_get_line_records.old_average_cost,10,' ')          ||CHR(09);
          lc_line_document  :=lc_line_document||RPAD(lcr_get_line_records.average_cost,10,' ')              ||CHR(09);
          lc_line_document  :=lc_line_document||RPAD(lcr_get_line_records.difference,14,' ')                ||CHR(09);
          lc_line_document  :=lc_line_document||RPAD(lcr_get_line_records.total,10,' ')                     ||CHR(13)||CHR(10); 
          
          ln_all_total := ln_all_total + lcr_get_line_records.total;        
           
      END LOOP;   
     
      IF display_type = 'text/html' THEN
      
                document_type := 'text/html';
                
                document := '<TABLE BORDER="0"><TR><TH>Weighted Average Cost Update impact analysis report:</TH><TD></TD><TR>' ||
                '<TR><TD>Run Date:  </TD><TD>'|| SYSDATE ||'</TD></TR>'||
                --'<TR><TD>Template used: </TD><TD>'|| ln_template_number  ||'</TD></TR></TABLE>'|| 
                '<HR><BR>'                                     ||
                -- lc_document_html                              || '<BR>'||   CR 5th Oct by Meenu No Need of Parameter Values
                '<TABLE BORDER ="0"><TR><TD>Total  monetary impact  of this WAC update: </TD><TD>'|| ln_all_total  || '</TD></TR>'||  
                              '<TR><TD>Total number of items impacted: </TD><TD>' || ln_items_no  ||  '</TD></TR>'||  
                '<TR><TD>Total number of ORG   impacted: </TD><TD>' || ln_orgs_no   ||  '</TD></TR></TABLE>'|| 
                '<HR><BR>'                                     ||
                '<LEFT><TABLE BORDER CELLPADDING=5 BGCOLOR=#FFFFFF>'||
                '<TR BGCOLOR=#83C1C1>' ||
                '<TH>Item</TH>'        ||
                '<TH>Org Name</TH>'    ||
                '<TH>Onhand</TH>'      ||
                '<TH>Old Cost</TH>'    ||
                '<TH>New Cost</TH>'    ||
                '<TH>Change</TH>'      ||
                '<TH>Value Change</TH>'|| 
                '</TR>'  ;
                     
              FOR lcr_get_line_records IN lcu_get_line_records          
              LOOP                       
                      document := document ||           
                      '<TR>'||          
                      '<TD>'||lcr_get_line_records.item_number     ||'</TD>'       ||          
                      '<TD>'||lcr_get_line_records.organization    ||'</TD>'       ||          
                      '<TD>'||lcr_get_line_records.onhand_quantity ||'</TD>'       ||          
                      '<TD>'||lcr_get_line_records.old_average_cost||'</TD>'       ||          
                      '<TD>'||lcr_get_line_records.average_cost    ||'</TD>'       ||          
                      '<TD>'||lcr_get_line_records.difference      ||'</TD>'       ||                         
                      '<TD>'||lcr_get_line_records.total           ||'</TD>'       ||                         
                      '</TR>'; 
                      
             END LOOP; 
             
             
             document := document ||'</TABLE><BR>';           
             document := document ||'<TABLE><TR><TH>Total: </TH><TH>'||ln_all_total||'</TH></TR></TABLE>';           
             document := document ||'</BODY>';           
             
           ELSE
                document_type:=  'text/plain';
                
                lc_document1 :=   'Weighted Average Cost Update impact analysis Report:'  ||CHR(13)||CHR(10);
                lc_document1 :=   lc_document1||'Run Date : '                             ||SYSDATE||CHR(13)||CHR(10);
                --lc_document1 :=   lc_document1||'Template used: '                         ||ln_template_number  ||CHR(13)||CHR(10);
                    
                --Line Headings--
                
                lc_line_document  :=lc_line_document||RPAD('Item',20,' ')               ||CHR(09);
                lc_line_document  :=lc_line_document||RPAD('Org Name',30,' ')           ||CHR(09);                
                lc_line_document  :=lc_line_document||RPAD('Onhand' ,10,' ')            ||CHR(09);
                lc_line_document  :=lc_line_document||RPAD('Old Cost',10,' ')           ||CHR(09);
                lc_line_document  :=lc_line_document||RPAD('New Cost',10,' ')           ||CHR(09);
                lc_line_document  :=lc_line_document||RPAD('Change',14,' ')             ||CHR(09);
                lc_line_document  :=lc_line_document||RPAD('Value Change' ,10,' ')      ||CHR(13)||CHR(10);
                lc_line_document  :=lc_line_document||'--------------------------------------------------------------------------------------------------------------------------------------------------------'||CHR(13)||CHR(10);
                
                lc_document2 := lc_document2||'--------------------------------------------------------------------------------------------------------------------------------------------------------'         ||CHR(13)||CHR(10);
               -- lc_document2 := lc_document2||'Functional currency : '                           ||lc_currency         ||CHR(13)||CHR(10);
                lc_document2 := lc_document2||'Total  monetary impact  of this WAC update: '     ||ln_all_total        ||CHR(13)||CHR(10);
                lc_document2 := lc_document2||'Total number of items impacted: '                 ||ln_items_no         ||CHR(13)||CHR(10);
                lc_document2 := lc_document2||'Total number of ORG   impacted: '                 ||ln_orgs_no          ||CHR(13)||CHR(10);
                lc_document2 := lc_document2||'--------------------------------------------------------------------------------------------------------------------------------------------------------'         ||CHR(13)||CHR(10);   
                
                --TOTAL            
                lc_document3 := 'Total:'||LPAD(ln_all_total,103,' ')                            ||CHR(13)||CHR(10);
                
                document     := lc_document1 ||  lc_document2 ||lc_line_document || lc_document3;
                
       END IF;        
 
EXCEPTION
WHEN OTHERS THEN 

     -- Logging error.

       WF_CORE.CONTEXT( 'CHECK_APPROVER'
                       ,'GET_WAC_IMPACT_REPORT'
                        ,document_id
                        ,display_type
                       );

       FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6029_UNEXP_GET_WAC');
       FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

       lc_errbuf   := FND_MESSAGE.GET;
       lc_err_code := 'XX_INV_6029_UNEXP_GET_WAC';     
       
       LOG_ERROR(p_exception      =>lc_error_location
                ,p_message        =>lc_errbuf
                ,p_code           =>lc_err_code
               ) ; 
               
END GET_WAC_IMPACT_REPORT;       




PROCEDURE INSERT_AVERAGE_COST_DETAILS  (ItemType       IN   VARCHAR2
                                       ,ItemKey        IN   VARCHAR2
                                       ,Actid          IN   NUMBER
                                       ,funcmode       IN   VARCHAR2
                                       ,resultout      OUT  VARCHAR2
                                      )
IS

-- +================================================================================+
-- | Name       : INSERT_AVERAGE_COST_DETAILS                                       |
-- |                                                                                |
-- | Description:                                                                   |
-- | This procedure inserts the successfully validated and approved data into the   |
-- | MTL_TRANSACTIONS_INTERFACE table which will be picked up by Transaction Manager|
-- | and updates the average cost                                                   |
-- +================================================================================+

-- Exception Variable
lc_errbuf              VARCHAR2(4000);
lc_err_code            VARCHAR2(1000);

lc_error_location      VARCHAR2(100);

lc_purge_value         VARCHAR2(3) := NULL;

--*********************************************************************
-- Declaring Cursor to select all the validated records after checking
-- the simulation of inserting records in standard table
--*********************************************************************

CURSOR lcu_val_records
IS
SELECT XXGA.rowid,XXGA.*
FROM   xx_gi_average_cost_stg XXGA
WHERE  status_flag          =  GC_VAL_SUCC
AND    file_id              =  ItemKey;

BEGIN
   
   lc_error_location := 'XX_GI_AVERAGE_COST_PKG.INSERT_AVERAGE_COST_DETAILS';
   --Open the cursor for validated records--

   FOR lcr_val_records IN lcu_val_records
   LOOP
   
  --Insert into the standard mtl transactions interface table
  BEGIN
  
        INSERT INTO inv.mtl_transactions_interface (
                                                   transaction_interface_id
                                                  ,source_code
                                                  ,source_line_id
                                                  ,source_header_id
                                                  ,process_flag
                                                  ,transaction_mode
                                                  ,lock_flag
                                                  ,last_update_date
                                                  ,creation_date
                                                  ,created_by
                                                  ,last_updated_by
                                                  ,organization_id
                                                  ,transaction_quantity
                                                  ,transaction_uom                                                                                                  
                                                  ,transaction_date
                                                  ,transaction_type_id
                                                  ,cost_group_id
                                                  ,material_account
                                                  ,material_overhead_account
                                                  ,resource_account
                                                  ,outside_processing_account
                                                  ,overhead_account
                                                  ,new_average_cost
                                                  ,inventory_item_id
                                                  ,transaction_reference                                     
                                                  ,attribute6 )
                                           VALUES(
                                                 mtl_material_transactions_s.nextval                 --  TRANSACTION INTERFACE ID
                                               , GC_SOURCE_NAME                                      --  GV_SOURCE_NAME
                                               , XX_GI_AVERAGE_COST_S.nextval                        --  SOURCE_HEADER_ID
                                               , XX_GI_AVERAGE_COST_S.currval                        --  SOURCE_LINE_ID
                                               , GN_PROCESS_FLAG                                     --  PROCESS_FLAG
                                               , GN_TRANSACTION_MODE                                 --  TRANSACTION_MODE
                                               , GN_LOCK_FLAG
                                               , SYSDATE                                             --  CREATION_DATE
                                               , SYSDATE                                             --  LAST_UPDATE_DATEE
                                               , GN_USER_ID                                          --  LAST_UPDATED_BY
                                               , GN_USER_ID                                          --  CREATED_BY
                                               , lcr_val_records.organization_id                     --  ORGANIZATION_ID
                                               , 0                                                   --  TRANSACTION_QUANTITY
                                               , lcr_val_records.primary_uom                         --  TRANSACTION_UOM
                                               , SYSDATE                                             --  TRANSACTION_DATE
                                               , 80                                                  --  TRANSACTION_TYPE_ID
                                               , lcr_val_records.cost_group_id                       --  COST_GROUP_ID
                                               , lcr_val_records.material_account                    --  MATERIAL_ACCOUNT
                                               , lcr_val_records.material_overhead_account           --  MATERIAL_OVERHEAD_ACCOUNT
                                               , lcr_val_records.resource_account                    --  RESOURCE_ACCOUNT
                                               , lcr_val_records.outside_processing_account          --  OUTSIDE_PROCESSING_ACCOUNT
                                               , lcr_val_records.overhead_account                    --  OVERHEAD_ACCOUNT
                                               , lcr_val_records.average_cost                        --  NEW_AVERAGE_COST
                                               , lcr_val_records.inventory_item_id                   --  INVENTORY_ITEM_ID
                                               , ItemKey
                                               , GN_APPROVER_ID);
   
   
  EXCEPTION 
  
  WHEN OTHERS THEN

     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6030_ACTUAL_INSERT_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

     lc_errbuf     :=  FND_MESSAGE.GET;
     lc_err_code   := 'XX_INV_6030_ACTUAL_INSERT_ERR';
      
     LOG_ERROR(p_exception      =>lc_error_location
              ,p_message        =>lc_errbuf
              ,p_code           =>lc_err_code
              ) ;   
  
   END;  
   
   
   END LOOP;

   lc_purge_value := FND_PROFILE.VALUE('XX_GI_WAC_PURGE_DATA');

IF lc_purge_value = 'YES' THEN 

   --Purge the data of the input File --
   BEGIN

      DELETE xx_gi_average_cost_stg
      WHERE  file_id     =  itemkey
      AND    status_flag =  GC_VAL_SUCC;
      
   EXCEPTION
      WHEN OTHERS THEN
              FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6031_PURGE_ERROR');
              FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
              FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

              lc_errbuf   := FND_MESSAGE.GET;
              lc_err_code := 'XX_INV_6031_PURGE_ERROR';

              LOG_ERROR(p_exception      =>lc_error_location
                       ,p_message        =>lc_errbuf
                       ,p_code           =>lc_err_code
                       ) ; 

   END;   
END IF; 
     
     COMMIT;
     
     RESULTOUT := WF_ENGINE.ENG_COMPLETED;
     RETURN;

EXCEPTION 
   WHEN OTHERS THEN
   
      WF_CORE.CONTEXT  ('XX_GI_AVERAGE_COST_PKG'
                        ,'INSERT_AVERAGE_COST_DETAILS'
                        ,ItemType
                        ,ItemKey
                        ,to_char(actid)
                        ,funcmode
                        );

        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6032_UNEXP_INSERT_PGM');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        lc_errbuf   := FND_MESSAGE.GET;
        lc_err_code := 'XX_INV_6032_UNEXP_INSERT_PGM';

        LOG_ERROR(p_exception      =>lc_error_location
                 ,p_message        =>lc_errbuf
                 ,p_code           =>lc_err_code
                 ) ; 

       RESULTOUT := WF_ENGINE.ENG_COMPLETED;
       RETURN;
       
 END INSERT_AVERAGE_COST_DETAILS;


PROCEDURE GET_VALID_AVERAGE_COST_DETAILS (DOCUMENT_ID   IN NUMBER,
                                          DISPLAY_TYPE  IN VARCHAR2,
                                          DOCUMENT      IN OUT CLOB,
                                          DOCUMENT_TYPE IN OUT VARCHAR2
                                          )

-- +================================================================================+
-- | Name       : GET_VALID_AVERAGE_COST_DETAILS                                    |
-- |                                                                                |
-- | Description:                                                                   |
-- |This Procedure gets successfully validated records (records having status 'VS') |
-- |from the Custom table XX_GI_AVERAGE_COST_STG. This Procedure gets called from   |
-- |the CHECK_APPROVER Proceudre in the Workflow, if the Requestor is not equal to  |
-- |Approver. This procedure provides the successfully validated data as a PLSQL    |
-- |Document along with the notification send to the Approver .                     |
-- +================================================================================+
IS

lc_line_document              CLOB := NULL;
lc_line_document_h            CLOB := NULL;
lc_error_location             VARCHAR2(100);

CURSOR lcu_get_val_records
IS
SELECT XXGA.rowid,
       XXGA.*
FROM   xx_gi_average_cost_stg XXGA
WHERE  status_flag          =  GC_VAL_SUCC
AND    file_id              =  DOCUMENT_ID;

--
-- Exception Variable
--
lc_errbuf              VARCHAR2(4000);
lc_err_code            VARCHAR2(1000);

BEGIN
lc_error_location := 'XX_GI_AVERAGE_COST_PKG.GET_VALID_AVERAGE_COST_DETAILS';


IF display_type   =  'text/html' THEN

   document_type  := 'text/html';
   document       := 
                   '<BR><BR><LEFT><TABLE BORDER CELLPADDING=5 BGCOLOR=#FFFFFF>'||
                   '<TR BGCOLOR=#83C1C1>'                     ||
                   '<TH>RECORD_NUMBER</TH>'                   ||
                   '<TH>FILE_ID</TH>'                         ||
                   '<TH>OPERATING_UNIT_ID</TH>'               ||
                   '<TH>ORGANIZATION</TH>'                    ||
                   '<TH>ORGANIZATION_ID</TH>'                 ||
                   '<TH>COST_GROUP_ID</TH>'                   ||
                   '<TH>MATERIAL_ACCOUNT</TH>'                ||
                   '<TH>MATERIAL_OVERHEAD_ACCOUNT</TH>'       ||
                   '<TH>RESOURCE_ACCOUNT</TH>'                ||
                   '<TH>OVERHEAD_ACCOUNT</TH>'                ||
                   '<TH>ITEM_NUMBER</TH>'                     ||
                   '<TH>INVENTORY_ITEM_ID</TH>'               ||
                   '<TH>PRIMARY_UOM</TH>'                     ||
                   '<TH>AVERAGE_COST</TH>'                    ||
                   '<TH>COUNTRY_CODE</TH>'                    ||
                   '<TH>SUBTYPE_CODE</TH>'                    ||
                   '<TH>DIVISION_CODE</TH>'                   ||
                   '<TH>DISTRICT_CODE</TH>'                   ||
                   '<TH>COMPANY_CODE</TH>'                    ||
                   '<TH>CHAIN_CODE</TH>'                      ||
                   '<TH>AREA_CODE</TH>'                       ||
                   '<TH>REGION_CODE</TH>'                     ||
                   '</TR>';
                   
   FOR lcr_get_val_records IN lcu_get_val_records   
   LOOP  
         document := document || 
         '<TR>'||
         '<TD>'||lcr_get_val_records.record_number                ||'</TD>'||
         '<TD>'||lcr_get_val_records.file_id                      ||'</TD>'||
         '<TD>'||lcr_get_val_records.operating_unit_id            ||'</TD>'||
         '<TD>'||lcr_get_val_records.organization                 ||'</TD>'||
         '<TD>'||lcr_get_val_records.organization_id              ||'</TD>'||
         '<TD>'||lcr_get_val_records.cost_group_id                ||'</TD>'||
         '<TD>'||lcr_get_val_records.material_account             ||'</TD>'||
         '<TD>'||lcr_get_val_records.material_overhead_account    ||'</TD>'||
         '<TD>'||lcr_get_val_records.resource_account             ||'</TD>'||
         '<TD>'||lcr_get_val_records.overhead_account             ||'</TD>'||
         '<TD>'||lcr_get_val_records.item_number                  ||'</TD>'||
         '<TD>'||lcr_get_val_records.inventory_item_id            ||'</TD>'||
         '<TD>'||lcr_get_val_records.primary_uom                  ||'</TD>'||
         '<TD>'||lcr_get_val_records.average_cost                 ||'</TD>'||
         '<TD>'||lcr_get_val_records.country_code                 ||'</TD>'||
         '<TD>'||lcr_get_val_records.subtype_code                 ||'</TD>'||
         '<TD>'||lcr_get_val_records.division_code                ||'</TD>'||
         '<TD>'||lcr_get_val_records.district_code                ||'</TD>'||
         '<TD>'||lcr_get_val_records.company_code                 ||'</TD>'||
         '<TD>'||lcr_get_val_records.chain_code                   ||'</TD>'||
         '<TD>'||lcr_get_val_records.area_code                    ||'</TD>'||
         '<TD>'||lcr_get_val_records.region_code                  ||'</TD>'||    
         '</TR>';

   END LOOP;

ELSE

   --Assigning document type value--
   document_type     := 'text/plain';    
 
   --Line Headings
   
   lc_line_document  :=lc_line_document||RPAD('RECORD_NUMBER',15,' ')             ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('FILE_ID',9,' ')                    ||CHR(09)            ;
  -- lc_line_document  :=lc_line_document||RPAD('TEMPLATE_NUMBER' ,17,' ')          ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('OPERATING_UNIT_ID',19,' ')         ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('ORGANIZATION',30,' ')              ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('ORGANIZATION_ID',17,' ')           ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('COST_GROUP_ID',15,' ')             ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('MATERIAL_ACCOUNT',18,' ')          ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('MATERIAL_OVERHEAD_ACCOUNT',27,' ') ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('RESOURCE_ACCOUNT',18,' ')          ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('OVERHEAD_ACCOUNT',18,' ')          ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('ITEM_NUMBER',13,' ')               ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('INVENTORY_ITEM_ID',19,' ')         ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('PRIMARY_UOM',13,' ')               ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('AVERAGE_COST',14,' ')              ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('COUNTRY_CODE',14,' ')              ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('SUBTYPE_CODE',14,' ')              ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('DIVISION_CODE',15,' ')             ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('DISTRICT_CODE',15,' ')             ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('COMPANY_CODE',14,' ')              ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('CHAIN_CODE',12,' ')                ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('AREA_CODE' ,11,' ')                ||CHR(09)            ;
   lc_line_document  :=lc_line_document||RPAD('REGION_CODE',13,' ')               ||CHR(13)||CHR(10)   ;   

FOR lcr_get_val_records IN lcu_get_val_records   
LOOP  
    --Line Details

   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.record_number                  ,15,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.file_id                        ,9,' ')           ||CHR(09)           ;
 --  lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.template_number                ,17,' ')          ||CHR(09)         ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.operating_unit_id              ,19,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.organization                   ,30,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.organization_id                ,17,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.cost_group_id                  ,15,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.material_account               ,18,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.material_overhead_account      ,27,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.resource_account               ,18,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.overhead_account               ,18,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.item_number                    ,13,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.inventory_item_id              ,19,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.primary_uom                    ,13,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.average_cost                   ,14,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.country_code                   ,14,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.subtype_code                   ,14,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.division_code                  ,15,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.district_code                  ,15,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.company_code                   ,14,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.chain_code                     ,12,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.area_code                      ,11,' ')          ||CHR(09)           ;
   lc_line_document  :=lc_line_document|| RPAD(lcr_get_val_records.region_code                    ,13,' ')          ||CHR(13)           ;   

END LOOP;


    document := lc_line_document;
    
END IF;    

EXCEPTION
WHEN OTHERS THEN

-- Logging error
  
    WF_CORE.CONTEXT('CHECK_APPROVER'
                    ,'GET_VALID_AVERAGE_COST_DETAILS'
                    ,document_id
                    ,display_type
                    );

    FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6033_UNEXP_GET_VALID');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

    lc_errbuf   := FND_MESSAGE.GET;
    lc_err_code := 'XX_INV_6033_UNEXP_GET_VALID';

    LOG_ERROR(p_exception      =>lc_error_location
             ,p_message        =>lc_errbuf
             ,p_code           =>lc_err_code
             ) ; 

END GET_VALID_AVERAGE_COST_DETAILS;

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
                                      )

-- +================================================================================+
-- | Name       : VALIDATE_TEMPLATE2_DETAILS                                        |
-- |                                                                                |
-- | Description:                                                                   |
-- |                                                                                |
-- |This procedure generates list of values for all Input parameters or a list of    |
-- |'Organization- Items' based on the input parameter (List Values or List Org-Items  |
-- +================================================================================+

IS

lc_segment1             mtl_system_items_b.segment1%TYPE;
lc_org_name             org_organization_definitions.organization_name%TYPE;
lc_description          mtl_system_items_b.description%TYPE;
--
-- Exception Variable
--
ln_count                NUMBER := 0  ;
lc_err_code             VARCHAR2(100);
lc_errbuf               VARCHAR2(5000);
lc_error_location       VARCHAR2(50) ;
EX_LESS_PARA_ERR        EXCEPTION;
EX_COUNTRY_ERR          EXCEPTION;
EX_NO_ORG_EXISTS        EXCEPTION;

lc_flex_value_area      fnd_flex_values.flex_value%TYPE ;  
lc_des_area             fnd_flex_values_tl.description%TYPE;

lc_flex_value_region    fnd_flex_values.flex_value%TYPE ;  
lc_des_region           fnd_flex_values_tl.description%TYPE;

lc_flex_value_district  fnd_flex_values.flex_value%TYPE ;  
lc_des_district         fnd_flex_values_tl.description%TYPE;

--Cursor declared to get the item and organization combination depending upon the input parameters

CURSOR lcu_get_item_org   (p_sku           VARCHAR2,
                           p_type_code     VARCHAR2,
                           p_subtype_code  VARCHAR ,
                           p_Division_code VARCHAR2,
                           p_district_code PLS_INTEGER,
                           p_country       VARCHAR2
                           )
IS                       
SELECT ood.organization_name
FROM   mtl_system_items_b msi,
       xx_inv_org_loc_rms_attribute xxinv,
       mtl_parameters               MP,
       org_organization_definitions OOD
WHERE  msi.segment1                   = NVL(p_sku ,msi.segment1)
AND    MSI.inventory_item_status_code ='A'
AND    xxinv.organization_id          = msi.organization_id
AND    country_id_sw                  = p_country
AND    od_type_sw                     = NVL(p_type_code,od_type_sw)
AND    od_sub_type_cd_sw              = NVL(p_subtype_code,od_sub_type_cd_sw)
AND    od_division_id_sw              = NVL(p_Division_code,od_division_id_sw)
AND    district_sw                    = NVL(p_district_code,district_sw)
AND    mp.organization_id             = xxinv.organization_id
AND    MSI.enabled_flag               ='Y' 
AND    OOD.organization_id            = MP.organization_id
AND    TRUNC(SYSDATE)  BETWEEN NVL(MSI.start_date_active,TRUNC(SYSDATE) ) AND NVL(MSI.end_date_active,TRUNC(SYSDATE) +1);

--Cursor to get the Country Code

CURSOR lcu_to_get_country_code
IS
SELECT DISTINCT country_id_sw
FROM   xx_inv_org_loc_rms_attribute;

--Cursor to get the Type codes values

CURSOR lcu_to_get_type_code
IS
SELECT DISTINCT od_type_sw
FROM   xx_inv_org_loc_rms_attribute;

--Cursor to get the Sub Type codes values

CURSOR lcu_to_get_sub_type_code
IS
SELECT DISTINCT od_sub_type_cd_sw
FROM   xx_inv_org_loc_rms_attribute;


--Cursor to get the division values

CURSOR lcu_to_get_division_code
IS
SELECT DISTINCT od_division_id_sw
FROM   xx_inv_org_loc_rms_attribute;

--Declaring the cursor to get the area belonging to that chain

CURSOR  lcu_get_area_chain(P_CHAIN_CODE PLS_INTEGER)
IS
SELECT  FFV.flex_value,
        FFVT.description
FROM    fnd_flex_values     FFV
      , fnd_flex_values_tl  FFVT
      , fnd_flex_value_sets FFVS
WHERE   FFVS.flex_value_set_name = 'XX_GI_AREA_VS'
AND     FFV.flex_value_set_id    = FFVS.flex_value_set_id
AND     FFVT.flex_value_id       = FFV.flex_value_id
AND     FFV.attribute1           = NVL(P_CHAIN_CODE,FFV.attribute1) ;


--Declaring the cursor to get the region belonging to that area

CURSOR  lcu_get_region_area(P_AREA_CODE PLS_INTEGER)
IS
SELECT  FFV.flex_value,FFVT.description
FROM    fnd_flex_values     FFV,
        fnd_flex_values_tl  FFVT,
        fnd_flex_value_sets FFVS
WHERE   FFVS.flex_value_set_name = 'XX_GI_REGION_VS' 
AND     FFV.flex_value_set_id    = FFVS.flex_value_set_id
AND     FFVT.flex_value_id       = FFV.flex_value_id
AND     FFV.attribute1           = NVL(P_AREA_CODE ,FFV.attribute1);

--Declaring the cursor to get the district belonging to that region

CURSOR  lcu_get_district_region(P_REGION_CODE PLS_INTEGER)
IS
SELECT  FFV.flex_value,FFVT.description
FROM    fnd_flex_values     FFV
       ,fnd_flex_values_tl  FFVT
       ,fnd_flex_value_sets FFVS
WHERE  FFVS.flex_value_set_name = 'XX_GI_DISTRICT_VS'
AND    FFV.flex_value_set_id    = FFVS.flex_value_set_id
AND    FFVT.flex_value_id       = FFV.flex_value_id
AND    FFV.attribute1           = NVL(P_REGION_CODE,FFV.attribute1);

--Cursor declared to get the company code description

CURSOR lcu_get_comp_code
IS
SELECT FFVV.flex_value,
       FFVV.description
FROM   fnd_flex_values_vl  FFVV ,
       fnd_flex_value_sets FFVS
WHERE
       FFVS.flex_value_set_name    = GC_COMP_SET_NAME
AND    FFVS.flex_value_set_id      = ffvv.flex_value_set_id  ;

--Cursor declared to get the chain code description


CURSOR lcu_get_chain_code
IS
SELECT FFVV.flex_value,
       FFVV.description
FROM   fnd_flex_values_vl  FFVV ,
       fnd_flex_value_sets FFVS
WHERE
       FFVS.flex_value_set_name    = GC_CHAIN_SET_NAME
AND    FFVS.flex_value_set_id      = ffvv.flex_value_set_id  ;

lc_area_code            xx_gi_average_cost_stg.area_code%TYPE;
lc_region_code          xx_gi_average_cost_stg.region_code%TYPE;
lc_chain_code           xx_gi_average_cost_stg.chain_code%TYPE ;
lc_record_check         VARCHAR2(500) := NULL;
lv_status               VARCHAR2(10)  := NULL;

BEGIN

   IF insert_store_table.count != 0 THEN

      insert_store_table.delete;

   END IF;


   --Displaying the parameter values
   lc_error_location := 'XX_GI_AVERAGE_COST_PKG.VALIDATE_TEMPLATE2_DETAILS';

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------------------');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OFFICE DEPOT                                                   ' ||  'DATE: ' || SYSDATE);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                               ' ||  'PAGE: ' || 1);

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'INPUT PARAMETERS                                               ' );
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------- ');

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'LIST VALUES                                                     ' || P_LIST);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'COUNTRY                                                         ' || P_COUNTRY);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'TYPE_CODE                                                       ' || P_TYPE_CODE);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'SUBTYPE_CODE                                                    ' || P_SUBTYPE_CODE);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'DIVISION_CODE                                                   ' || P_DIVISION_CODE);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'DISTRICT_CODE                                                   ' || P_DISTRICT_CODE);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'COMPANY CODE                                                    ' || P_COMPANY_CODE );
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'CHAIN_CODE                                                      ' || P_CHAIN_CODE);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'AREA_CODE                                                       ' || P_AREA_CODE);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'REGION_CODE                                                     ' || P_REGION_CODE);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'SKU                                                             ' || P_SKU);

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------- ');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'DATA VALUES');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------- ');


--CHECKING FOR THE LIST VALUES

IF (P_LIST = GC_LIST1 ) THEN

         -- Opening a cursor for Type code
         
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Type Code'   );
         
      FOR lcr_to_get_type_code IN lcu_to_get_type_code
      LOOP

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lcr_to_get_type_code.od_type_sw  );

      END LOOP; 
      
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------- ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                      ');
          
         -- Opening a cursor for sub Type code

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Sub Type Code ' );   

      FOR lcr_to_get_sub_type_code IN lcu_to_get_sub_type_code
      LOOP

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lcr_to_get_sub_type_code.od_sub_type_cd_sw );

      END LOOP; 
      
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------- ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                      ');          
          
           --Opening the cursor to get the description values for comp code --  

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Country Code ' );   


      FOR lcr_to_get_country_code IN lcu_to_get_country_code
      LOOP

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lcr_to_get_country_code.country_id_sw );

      END LOOP;
      
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------- ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                      ');
          
          

          --Opening the cursor to get the division code--  

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Division Code ' );  

      FOR lcr_to_get_division_code IN lcu_to_get_division_code
      LOOP
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lcr_to_get_division_code.od_division_id_sw  );  

      END LOOP;

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------- ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                      ');
          
          --Opening the cursor to get the description values for chain code--     

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Chain Code                      Description' );      


     FOR lcr_get_chain_code IN lcu_get_chain_code   
     LOOP                             

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcr_get_chain_code.flex_value,32,' ') || lcr_get_chain_code.description);                   


     END LOOP;   


          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------- ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                      ');
          
          --Opening the cursor to get the company code and the description--    

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Company Code                     Description' );  

     FOR lcr_get_comp_code IN lcu_get_comp_code
     LOOP

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcr_get_comp_code.flex_value,32,' ') || lcr_get_comp_code.description); 

     END LOOP;


          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------- ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                      ');
          
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Area Code                       Description' );  

     FOR lcr_get_area_chain IN lcu_get_area_chain(P_CHAIN_CODE)
     LOOP

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcr_get_area_chain.flex_value,32,' ') || lcr_get_area_chain.description); 

     END LOOP;
     
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------- ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                      ');
          

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Region Code                     Description' );  

     FOR lcr_get_region_area IN lcu_get_region_area(P_AREA_CODE)
     LOOP

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcr_get_region_area.flex_value,32,' ') || lcr_get_region_area.description); 

     END LOOP; 
     
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------- ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                                      ');
          

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'District Code                   Description' );  

     FOR lcr_get_district_region IN lcu_get_district_region(P_REGION_CODE)
     LOOP

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcr_get_district_region.flex_value,32,' ') || lcr_get_district_region.description); 

     END LOOP;


ELSIF (P_LIST = GC_LIST2 ) THEN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------------------');       
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'List Org Items for selected combination of input parameters:');          
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Date                                        '||SYSDATE);                 
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------------------'); 

   --User has to enter any other criteria other then Company

  /* IF    (p_company_code    IS NOT NULL 
        AND p_district_code   IS NULL  
        AND p_type_code       IS NULL 
        AND p_subtype_code    IS NULL 
        AND p_Division_code   IS NULL 
        AND p_Chain_code      IS NULL 
        AND P_AREA_CODE       IS NULL 
        AND p_region_code     IS NULL 
        AND p_district_code   IS NULL )THEN

        RAISE EX_LESS_PARA_ERR;

   END IF;*/
   
   IF p_country IS NULL  THEN
   
      RAISE EX_COUNTRY_ERR;
      
   END IF;

 -- IF p_store  IS  NULL THEN

      -- If district is not null then derive the values for store

      /*IF (  p_district_code IS NOT NULL
         OR p_type_code     IS NOT NULL
         OR p_subtype_code  IS NOT NULL 
         OR p_Division_code IS NOT NULL)  THEN

         FOR lcr_get_item_org IN lcu_get_item_org(p_sku,
                                                 p_type_code,
                                                 p_subtype_code,
                                                 p_Division_code,
                                                 p_district_code,
                                                 p_country
                                                 )
         LOOP 

            insert_store_table(ln_count).rec_index := ln_count;         
            insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;

            ln_count := ln_count + 1;
           
         END LOOP;
         
      ELSIF p_region_code IS NOT NULL  THEN

         FOR lcr_get_district_region IN lcu_get_district_region(p_region_code)
         LOOP                                      

            FOR lcr_get_item_org IN lcu_get_item_org       (p_sku,
                                                            p_type_code,
                                                            p_subtype_code,
                                                            p_Division_code,
                                                            lcr_get_district_region.flex_value,
                                                            p_country
                                                            )
            LOOP 


               insert_store_table(ln_count).rec_index := ln_count;
               insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'Area doesnot Belong to this chain'); 

               ln_count := ln_count + 1;

            END LOOP;

         END LOOP;     

      ELSIF p_area_code IS NOT NULL THEN    

         FOR lcr_get_region_area IN lcu_get_region_area(p_area_code)        
         LOOP

            FOR lcr_get_district_region IN lcu_get_district_region(lcr_get_region_area.flex_value)
            LOOP


               FOR lcr_get_item_org IN lcu_get_item_org(p_sku,
                                                              p_type_code,
                                                              p_subtype_code,
                                                              p_Division_code,
                                                              lcr_get_district_region.flex_value,
                                                              p_country
                                                              )
               LOOP 

                  insert_store_table(ln_count).rec_index := ln_count;
                  insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;

                  ln_count := ln_count + 1;

               END LOOP;

            END LOOP;

         END LOOP;     

      ELSIF p_Chain_code IS NOT NULL THEN


         FOR  lcr_get_area_chain IN  lcu_get_area_chain(p_Chain_code)
         LOOP

            FOR lcr_get_region_area IN lcu_get_region_area(lcr_get_area_chain.flex_value)              
            LOOP

               FOR lcr_get_district_region IN lcu_get_district_region(lcr_get_region_area.flex_value)
               LOOP


                  FOR lcr_get_item_org IN lcu_get_item_org(p_sku,
                                                           p_type_code,
                                                           p_subtype_code,
                                                           p_Division_code,
                                                           lcr_get_district_region.flex_value,
                                                           p_country)
                  LOOP 

                     insert_store_table(ln_count).rec_index := ln_count;
                     insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;

                     ln_count := ln_count + 1;

                  END LOOP;

               END LOOP;

            END LOOP;  

         END LOOP;

      END IF; -- district end if

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Organization                                                              Item' ); 
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                              ' );       
      
      IF insert_store_table.count = 0 THEN
         
         RAISE EX_NO_ORG_EXISTS;         
          
      ELSE

         FOR ln_store IN insert_store_table.FIRST..insert_store_table.LAST 
         LOOP

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(insert_store_table(ln_store).store,74,' ') || p_sku);    
 
         END LOOP;
      END IF ;
  
END IF;*/

  --If only region code is not null
  
  IF p_region_code IS NOT NULL AND p_area_code IS NULL AND p_chain_code IS NULL THEN
   
      lc_record_check := 'Region:' || p_region_code;
       
      FOR lcr_get_district_region IN lcu_get_district_region(p_region_code)
      LOOP                                      
           
           
         lc_record_check := 'District:' || lcr_get_district_region.flex_value;         
        
         FOR lcr_get_item_org IN lcu_get_item_org       (p_sku,
                                                         p_type_code,
                                                         p_subtype_code,
                                                         p_Division_code,
                                                         lcr_get_district_region.flex_value,
                                                         p_country
                                                         )
         LOOP 

            insert_store_table(ln_count).rec_index := ln_count;
            insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;

            ln_count := ln_count + 1;

            lc_record_check := NULL;

         END LOOP;
                                         
      END LOOP;     
   
   --If only area code is not null
   
   ELSIF p_area_code IS NOT NULL  AND p_chain_code IS NULL AND p_region_code IS NULL THEN  
   
     
      FOR lcr_get_region_area IN lcu_get_region_area(p_area_code)        
      LOOP
         
         lc_record_check := 'Region:' || lcr_get_region_area.flex_value;
         
         FOR lcr_get_district_region IN lcu_get_district_region(lcr_get_region_area.flex_value)
         LOOP
           
            lc_record_check := 'District:' || lcr_get_district_region.flex_value ;
            
            FOR lcr_get_item_org  IN lcu_get_item_org     (p_sku,
                                                           p_type_code,
                                                           p_subtype_code,
                                                           p_Division_code,
                                                           lcr_get_district_region.flex_value,
                                                           p_country
                                                           )
            LOOP 
                                                               
               insert_store_table(ln_count).rec_index := ln_count;
               insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;
             
               ln_count := ln_count + 1;
               
               lc_record_check := NULL;
                
            END LOOP;
                               
         END LOOP;
              
      END LOOP;   
      
   --if only chain code is not null
   
   ELSIF p_Chain_code IS NOT NULL AND p_area_code IS NULL AND p_region_code IS NULL THEN
     
      lc_record_check := 'Chain:' || p_chain_code;
     
     
      FOR  lcr_get_area_chain IN  lcu_get_area_chain(p_Chain_code)
      LOOP
      
         lc_record_check := 'Area:' || lcr_get_area_chain.flex_value ;
        
         FOR lcr_get_region_area IN lcu_get_region_area(lcr_get_area_chain.flex_value)              
         LOOP
            
            lc_record_check := 'Region:' || lcr_get_region_area.flex_value;
            
            FOR lcr_get_district_region IN lcu_get_district_region(lcr_get_region_area.flex_value)
            LOOP
              
               lc_record_check := 'District:' || lcr_get_district_region.flex_value;
               
               FOR lcr_get_item_org IN lcu_get_item_org        (p_sku,
                                                                p_type_code,
                                                                p_subtype_code,
                                                                p_Division_code,
                                                                lcr_get_district_region.flex_value,
                                                                p_country)
               LOOP 
                                                                
                  insert_store_table(ln_count).rec_index := ln_count;
                  insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;
                 
                  ln_count := ln_count + 1;
               
                  lc_record_check := NULL;
               
               END LOOP;
                                   
            END LOOP;
                   
         END LOOP;  
    
      END LOOP;
  
  --if chain and area are not null.chk if chain belongs to the area and then derive store from area
  ELSIF  p_chain_code IS NOT NULL AND p_area_code IS NOT NULL  AND p_region_code IS NULL  THEN
       
      lc_record_check := 'Chain:' || p_chain_code  ;      
      
      --Validate Chain
      
      OPEN  lcu_get_area_chain(p_Chain_code);
      FETCH lcu_get_area_chain INTO lc_flex_value_area,
                                    lc_des_area;
      
         IF lcu_get_area_chain%ROWCOUNT = 0 THEN

            lc_record_check := 'Chain:' || p_chain_code  ;
            RAISE EX_NO_ORG_EXISTS;

         ELSE
            
            --Once chain is validated derive area 
            FOR lcr_get_region_area IN lcu_get_region_area(p_area_code)              
            LOOP

               lc_record_check := 'Region:' || lcr_get_region_area.flex_value;

               FOR lcr_get_district_region IN lcu_get_district_region(lcr_get_region_area.flex_value)
               LOOP

                  lc_record_check := 'District:' || lcr_get_district_region.flex_value;

                  FOR lcr_get_item_org IN lcu_get_item_org        (p_sku,
                                                                   p_type_code,
                                                                   p_subtype_code,
                                                                   p_Division_code,
                                                                   lcr_get_district_region.flex_value,
                                                                   p_country)
                  LOOP 

                     insert_store_table(ln_count).rec_index := ln_count;
                     insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;

                     ln_count := ln_count + 1;

                     lc_record_check := NULL;

                  END LOOP;

               END LOOP;

            END LOOP;            

         END IF;
            
      
      CLOSE lcu_get_area_chain;       

   --if area and region are not null.chk if area belongs to the region and then derive store from region
   
   ELSIF p_area_code IS NOT NULL AND p_region_code IS NOT NULL  AND p_chain_code IS NULL  THEN 
   
      lc_record_check := 'Area:' || p_area_code;
      
      --Validate Area
      
      OPEN  lcu_get_region_area(p_area_code)        ;
      
      FETCH lcu_get_region_area INTO lc_flex_value_region ,
                                     lc_des_region;
                                     
         IF  lcu_get_region_area%ROWCOUNT = 0 THEN

              lc_record_check := 'Area:' || p_area_code;
              RAISE EX_NO_ORG_EXISTS;

         ELSE
            --Once Area is validated derive district

            FOR lcr_get_district_region IN lcu_get_district_region(p_region_code)
            LOOP

               lc_record_check := 'District:' || lcr_get_district_region.flex_value;

               FOR lcr_get_item_org IN lcu_get_item_org      (p_sku,
                                                              p_type_code,
                                                              p_subtype_code,
                                                              p_Division_code,
                                                              lcr_get_district_region.flex_value,
                                                              p_country
                                                              )
               LOOP 

                  insert_store_table(ln_count).rec_index := ln_count;
                  insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;

                  ln_count := ln_count + 1;

                  lc_record_check := NULL;

               END LOOP;

            END LOOP;            

         END IF;
      
      CLOSE lcu_get_region_area;      

   --if chain ,area and region are not null.chk if chain belongss to area,area  belongs to the region and then derive store from region
   
   ELSIF p_chain_code IS NOT NULL AND p_area_code IS NOT NULL AND p_region_code IS NOT NULL THEN
            
      --Open the cursor to validate the value of chain

      OPEN  lcu_get_area_chain(p_Chain_code);
      FETCH lcu_get_area_chain INTO lc_flex_value_area,
                                    lc_des_area ;
                                    
         IF lcu_get_area_chain%ROWCOUNT = 0 THEN

            lc_record_check := 'Area:' || p_area_code;
            RAISE EX_NO_ORG_EXISTS;

         ELSE
            --In case chain is validated then validate area

            OPEN  lcu_get_region_area(p_area_code) ;
            FETCH lcu_get_region_area INTO lc_flex_value_region,
                                           lc_des_region;
                                           
               IF lcu_get_region_area%ROWCOUNT = 0 THEN

                  lc_record_check := 'Region:' || p_region_code;
                  RAISE EX_NO_ORG_EXISTS;


               ELSE
                  -- In case area is validated then derive district based on the region

                  FOR lcr_get_district_region IN lcu_get_district_region(p_region_code)
                  LOOP

                     lc_record_check := 'District:' || lcr_get_district_region.flex_value ;

                     FOR lcr_get_item_org IN lcu_get_item_org        (p_sku,
                                                                      p_type_code,
                                                                      p_subtype_code,
                                                                      p_Division_code,
                                                                      lcr_get_district_region.flex_value,
                                                                      p_country)
                     LOOP 

                        insert_store_table(ln_count).rec_index := ln_count;
                        insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;

                        ln_count := ln_count + 1;

                        lc_record_check := NULL;

                     END LOOP;

                  END LOOP; 

               END IF;

            CLOSE lcu_get_region_area;               
         END IF;
         
      CLOSE lcu_get_area_chain;
   
   --if chain and region are not null.chk if chain belongss to area and derived area  belongs to the region and then derive store from region
   
   ELSIF  p_chain_code IS NOT NULL AND p_region_code IS NOT NULL AND p_area_code IS NULL THEN
   
      lc_record_check := 'Chain:' || p_chain_code;
          
     --Open the cursor to valiadate the value of chain
     
      OPEN  lcu_get_area_chain(p_Chain_code);
      FETCH lcu_get_area_chain INTO lc_flex_value_area,
                                    lc_des_area ;
                                    
         IF lcu_get_area_chain%ROWCOUNT = 0 THEN

            lc_record_check := 'Chain:' || p_chain_code;
            
            RAISE EX_NO_ORG_EXISTS;
            lv_status        := 'F';

         END IF;
            
      CLOSE lcu_get_area_chain ;
      
      --In case chain is a valid value then proceed with deriving values of stores from region
      
      IF lv_status != 'F' THEN
      
         FOR lcr_get_district_region IN lcu_get_district_region(p_region_code)
         LOOP

            lc_record_check := 'District:' || lcr_get_district_region.flex_value;

            FOR lcr_get_item_org IN lcu_get_item_org        (p_sku,
                                                             p_type_code,
                                                             p_subtype_code,
                                                             p_Division_code,
                                                             lcr_get_district_region.flex_value,
                                                             p_country)
            LOOP 

               insert_store_table(ln_count).rec_index := ln_count;
               insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;

               ln_count := ln_count + 1;

              lc_record_check := NULL;

            END LOOP;

         END LOOP;
                   
      END IF;      
   
   -- if chain ,area and region are null then chk directly for type,subtype ,division,district and country
   ELSIF (    p_type_code     IS NOT NULL
          OR  p_subtype_code  IS NOT NULL 
          OR  p_Division_code IS NOT NULL
          OR  p_country       IS NOT NULL
          OR  p_district_code IS NOT NULL
          AND p_chain_code    IS NULL
          AND p_region_code   IS NULL
          AND p_area_code     IS NULL)  THEN
      
      
      lc_record_check := 'Type_code: '  || p_type_code || ' -Sub Type Code:' || p_subtype_code || ' -Division Code' || p_Division_code
                        || ' -Country:' || p_country   || ' -District Code:' || p_district_code;
      
      FOR lcr_get_item_org IN lcu_get_item_org      (p_sku,
                                                     p_type_code,
                                                     p_subtype_code,
                                                     p_Division_code,
                                                     p_district_code,
                                                     p_country
                                                     )
      LOOP 
         
         
         insert_store_table(ln_count).rec_index := ln_count;         
         insert_store_table(ln_count).store     := lcr_get_item_org.organization_name;         
              
         ln_count := ln_count + 1;         
         lc_record_check := NULL;
      
      END LOOP;       
   
   END IF; -- district end if
   
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Organization                                                              Item' );   
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                                              ' );   

   IF insert_store_table.count = 0 THEN   

      RAISE EX_NO_ORG_EXISTS;            

   ELSE   

      FOR ln_store IN insert_store_table.FIRST..insert_store_table.LAST    
      LOOP   

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(insert_store_table(ln_store).store,74,' ') || p_sku);       

      END LOOP;  
      
   END IF ;
   
END IF;

EXCEPTION

  WHEN EX_NO_ORG_EXISTS THEN
  
     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6037_ORG_ITEM_ERROR');  
     
     
     lc_errbuf      :=   FND_MESSAGE.GET;  
     lc_err_code    :=  'XX_INV_6037_ORG_ITEM_ERROR';  
     
     LOG_ERROR(p_exception      =>lc_error_location  
              ,p_message        =>lc_errbuf  
              ,p_code           =>lc_err_code  
              ) ;   
     
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Organization Item combination doesnot exits for the entered input values'); 
     FND_FILE.PUT_LINE(FND_FILE.LOG, lc_record_check || ': is not a valid value to derive stores ')  ;    
     x_retcode := 2;
  
  WHEN EX_COUNTRY_ERR THEN
  
   FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6041_COUNTRY_NULL');  
  
  
   lc_errbuf      :=   FND_MESSAGE.GET;  
   lc_err_code    :=  'XX_INV_6041_COUNTRY_NULL';  
  
   LOG_ERROR(p_exception      =>lc_error_location  
            ,p_message        =>lc_errbuf  
            ,p_code           =>lc_err_code  
            ) ;   
 
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Country Cannot be Null'); 
   x_retcode := 2;



  /*WHEN EX_LESS_PARA_ERR THEN
  
     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6039_LESS_PARA');


     lc_errbuf      :=   FND_MESSAGE.GET;
     lc_err_code    :=  'XX_INV_6039_LESS_PARA';

     LOG_ERROR(p_exception      =>lc_error_location
              ,p_message        =>lc_errbuf
              ,p_code           =>lc_err_code
              ) ; 
              
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Some other criteria needs to be entered for derving org-item');            
    x_retcode := 2;*/
    
  WHEN OTHERS THEN
     FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6040_CONC_PRG');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

     lc_errbuf      :=   FND_MESSAGE.GET;
     lc_err_code    :=  'XX_INV_6040_CONC_PRG';

     LOG_ERROR(p_exception      =>lc_error_location
              ,p_message        =>lc_errbuf
              ,p_code           =>lc_err_code
              ) ; 
     
     
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexceptional error in the program ');            
     x_retcode := 2;
     
END VALIDATE_TEMPLATE2_DETAILS;

-- +================================================================================+
-- | Name       : UPDATE_RECORD                                                     |
-- |                                                                                |
-- | Description: This procedure marks the recrd with status error or success       |                                                                  |
-- +================================================================================+

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
                         p_error_message                IN     VARCHAR2
                         )
                         
IS

lc_errbuf              VARCHAR2(4000);
lc_err_code            VARCHAR2(1000);
lc_error_location      VARCHAR2(100);

BEGIN          
   
   lc_error_location     := 'UPDATE_RECORD';
  
 IF x_status = GC_REC_STATUS_SUCC THEN
 
   UPDATE xx_gi_average_cost_stg XXGA
   SET    organization_id              = p_organization_id
         ,operating_unit_id            = p_master_organization_id
         ,cost_group_id                = p_default_cost_group_id
         ,material_account             = p_material_account
         ,material_overhead_account    = p_material_overhead_account
         ,resource_account             = p_resource_account
         ,outside_processing_account   = p_outside_processing_account
         ,overhead_account             = p_overhead_account
         ,inventory_item_id            = p_inventory_item_id
         ,status_flag                  = GC_VAL_SUCC
         ,primary_uom                  = p_primary_uom_code
         ,approver_id                  = p_approver_id
         ,onhand_quantity              = p_qty_avail_to_reserve
         ,old_average_cost             = p_item_cost
         ,error_code                   = NULL 
         ,error_message                = NULL 
   WHERE  rowid                        = p_rowid;   
   
ELSE
  
  
  UPDATE xx_gi_average_cost_stg XXGA
  SET     status_flag    = DECODE(SUBSTR(p_error_code,1,2),'XX',GC_VAL_ERR,GC_INT_ERR)
         ,error_code     = DECODE(SUBSTR(p_error_code,1,2),'XX',p_error_code,SUBSTR(p_error_code,3))
         ,error_message  = p_error_message 
  WHERE   rowid          = p_rowid;      
       
   LOG_ERROR(p_exception      =>lc_error_location
            ,p_message        =>p_error_message 
            ,p_code           =>p_error_code
     ) ;   
 
       

END IF;

COMMIT;         

EXCEPTION
   WHEN OTHERS THEN 
          FND_MESSAGE.SET_NAME('XXPTP','XX_INV_6038_UPDATE_REC_ERROR');
          FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

          lc_errbuf     :=  FND_MESSAGE.GET;
          lc_err_code   := 'XX_INV_6038_UPDATE_REC_ERROR';
          x_status      :=  GC_REC_STATUS_ERR;

          LOG_ERROR(p_exception      =>lc_error_location
                   ,p_message        =>lc_errbuf
                   ,p_code           =>lc_err_code
                   ) ; 

END UPDATE_RECORD;





END  XX_GI_AVERAGE_COST_PKG;
/
SHOW ERRORS;
EXIT;
