SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE BODY XX_OM_COMMON_POOL_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                                                      
-- |
-- |                Office Depot                                                                           
-- |
-- +===================================================================+
-- | Name  : XX_OM_COMMON_POOL_PKG                                                                   
-- |
-- | Description      : Package Body                                                              
-- |
-- |                                                                                                       
-- |
-- |                                                                                                       
-- |
-- |Change Record:                                                                                         
-- |
-- |===============                                                                                        
-- |
-- |Version    Date          Author           Remarks                                                      
-- |
-- |=======    ==========    =============    ========================                |
-- |DRAFT 1A   09-SEP-2007   Visalakshi          Initial draft version                                     
-- |
-- |                                                                                                       
-- |
-- +===================================================================+
--------------------------------------------------------------------------


    -- +===================================================================+
    -- | Name        : Write_Exception                                     |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :  Error_Code                                          |
    -- |               Error_Description                                   |
    -- |               Entity_Reference                                    |
    -- |               Entity_Reference_Id                                 |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Write_Exception (
                                p_error_code        IN  VARCHAR2
                               ,p_error_description IN  VARCHAR2
                               ,p_entity_reference  IN  VARCHAR2
                               ,p_entity_ref_id     IN  VARCHAR2
                            )
    IS

     lc_errbuf    VARCHAR2(4000);
     lc_retcode   VARCHAR2(4000);

    BEGIN                               -- Procedure Block

     ge_exception.p_error_code        := p_error_code;
     ge_exception.p_error_description := p_error_description;
     ge_exception.p_entity_ref        := p_entity_reference;
     ge_exception.p_entity_ref_id     := p_entity_ref_id;

     xx_om_global_exception_pkg.Insert_Exception(
                                                  ge_exception
                                                 ,lc_errbuf
                                                 ,lc_retcode
                                                );

    END Write_Exception;   -- End Procedure Block



-- +=======================================================================+
    -- | Name        : Insert_Record                                       |
    -- | Description : Procedure to insert pool into the                   |
    -- |               xx_om_pool_records_all table                        |
    -- |                                                                   |
    -- | Parameters :                                                      |
    -- |                                                                   |
    -- |                                                                   |
    -- |                                                                   |
    -- |                                                                   |
    -- +===================================================================+

  PROCEDURE INSERT_RECORD( 
                         p_pool_record_tbl IN pool_record_tbl_type
                        ,x_err_buf OUT VARCHAR2
                        ,x_ret_code OUT VARCHAR2
                       ) 
    IS
     lc_err_buf VARCHAR2(4000);
     lc_ret_code VARCHAR2(4000);
     lc_entity_ref VARCHAR2(100);

    BEGIN
      For i in p_pool_record_tbl.FIRST..p_pool_record_tbl.LAST 
        LOOP
         BEGIN
           lc_entity_ref := 'Insert Pool Records';
           INSERT INTO xx_om_pool_records_all(
                                               ENTITY_NAME
					      ,ENTITY_ID 
                                              ,POOL_ID
                                              ,HOLD_ID
                                              ,ORG_ID 
                                              ,REVIEWER        
                                              ,PRIORITY        
                                              ,HOLDOVER_CODE   
                                              ,CREATION_DATE   
                                              ,CREATED_BY    
                                              ,LAST_UPDATE_DATE
                                              ,LAST_UPDATED_BY 
                                              ,LAST_UPDATE_LOGIN)
                                             VALUES
                                             (
                                               p_pool_record_tbl(i).entity_name
                                              ,p_pool_record_tbl(i).entity_id
                                              ,p_pool_record_tbl(i).pool_id
                                              ,p_pool_record_tbl(i).hold_id
                                              ,p_pool_record_tbl(i).org_id
                                              ,p_pool_record_tbl(i).reviewer
                                              ,p_pool_record_tbl(i).priority
                                              ,p_pool_record_tbl(i).holdover_code
                                              ,p_pool_record_tbl(i).creation_date
                                              ,p_pool_record_tbl(i).created_by
                                              ,p_pool_record_tbl(i).last_update_date
                                              ,p_pool_record_tbl(i).last_updated_by
                                              ,p_pool_record_tbl(i).last_update_login
                                              );
          x_ret_code := 'S';
          x_err_buf :='Succesfully inserted into the Pools table';
    EXCEPTION
         WHEN OTHERS THEN
            x_ret_code  :='E';
            lc_ret_code :='E';
            x_err_buf := 'The following Error occured while inserting the pool record '||sqlerrm(sqlcode);
            lc_err_buf :='The following Error occured while inserting the pool record '||substr(SQLERRM,1,3000);
            WRITE_EXCEPTION(
                            lc_ret_code
                           ,lc_err_buf
                           ,lc_entity_ref
                           ,p_pool_record_tbl(i).entity_id
                            );
     END;
     END LOOP;
     END INSERT_RECORD;

-- +=======================================================================+
    -- | Name        : Update_Record                                       |
    -- | Description : Procedure to update pool into the                   |
    -- |               xx_om_pool_records_all table                        |
    -- |                                                                   |
    -- | Parameters :                                                      |
    -- |                                                                   |
    -- |                                                                   |
    -- |                                                                   |
    -- |                                                                   |
    -- +===================================================================+

  PROCEDURE UPDATE_RECORD( 
                         p_pool_record_tbl IN pool_record_tbl_type
                        ,x_err_buf OUT VARCHAR2
                        ,x_ret_code OUT VARCHAR2
                       ) 
    IS
     lc_err_buf VARCHAR2(4000);
     lc_ret_code VARCHAR2(4000);
     lc_entity_ref VARCHAR2(100);
    BEGIN
      For i in p_pool_record_tbl.FIRST..p_pool_record_tbl.LAST 
        LOOP
         BEGIN
             lc_entity_ref := 'Update Pool Records';
             update xx_om_pool_records_all set REVIEWER = p_pool_record_tbl(i).reviewer        
					      ,PRIORITY = p_pool_record_tbl(i).priority      
					      ,HOLDOVER_CODE = p_pool_record_tbl(i).holdover_code  
					      ,CREATION_DATE  = p_pool_record_tbl(i).creation_date
					      ,CREATED_BY = p_pool_record_tbl(i).created_by  
                                              ,LAST_UPDATE_DATE = p_pool_record_tbl(i).last_update_date
                                              ,LAST_UPDATED_BY = p_pool_record_tbl(i).last_updated_by
                                              ,LAST_UPDATE_LOGIN = p_pool_record_tbl(i).last_update_login
              where ENTITY_NAME = p_pool_record_tbl(i).entity_name
                AND ENTITY_ID =  p_pool_record_tbl(i).entity_id
                AND POOL_ID = p_pool_record_tbl(i).pool_id
                AND ORG_ID =  p_pool_record_tbl(i).org_id
                AND HOLD_ID = p_pool_record_tbl(i).hold_id;

             x_ret_code := 'S';
             x_err_buf :='Succesfully updated the Pools table';
    EXCEPTION
         WHEN OTHERS THEN
            x_ret_code  :='E';
            lc_ret_code :='E';
            x_err_buf := 'The following Error occured while updating the pool record '|| sqlerrm(sqlcode);
            lc_err_buf :='The following Error occured while updating the pool record '||substr(SQLERRM,1,3000);
            WRITE_EXCEPTION(
                            lc_ret_code
                           ,lc_err_buf
                           ,lc_entity_ref
                           ,p_pool_record_tbl(i).entity_id
                           );
     END;
     END LOOP;
     END UPDATE_RECORD;


-- +=======================================================================+
    -- | Name        : Delete_Record                                       |
    -- | Description : Procedure to delete pool from the                   |
    -- |               xx_om_pool_records_all table                        |
    -- |                                                                   |
    -- | Parameters :                                                      |
    -- |                                                                   |
    -- |                                                                   |
    -- |                                                                   |
    -- |                                                                   |
    -- +===================================================================+

  PROCEDURE DELETE_RECORD( 
                         p_pool_record_tbl IN pool_record_tbl_type
                        ,x_err_buf OUT VARCHAR2
                        ,x_ret_code OUT VARCHAR2
                       ) 
    IS
     lc_err_buf VARCHAR2(4000);
     lc_ret_code VARCHAR2(4000);
     lc_entity_ref VARCHAR2(100);

    BEGIN
      For i in p_pool_record_tbl.FIRST..p_pool_record_tbl.LAST 
        LOOP
         BEGIN
           DELETE xx_om_pool_records_All where 
                    ENTITY_NAME = p_pool_record_tbl(i).entity_name
                AND ENTITY_ID =  p_pool_record_tbl(i).entity_id
                AND POOL_ID = p_pool_record_tbl(i).pool_id
                AND ORG_ID =  p_pool_record_tbl(i).org_id
                AND HOLD_ID = p_pool_record_tbl(i).hold_id;
             
          x_ret_code := 'S';
          x_err_buf :='Succesfully deleted the Pools table';
          lc_entity_ref := 'Deletion of Pool Records';
    EXCEPTION
         WHEN OTHERS THEN
            x_ret_code  :='E';
            lc_ret_code :='E';
            x_err_buf := 'The following Error occured while deleting the pool record '||sqlerrm(sqlcode);
            lc_err_buf :='The following Error occured while deleting the pool record '||substr(SQLERRM,1,3000);
            WRITE_EXCEPTION( lc_ret_code
                            ,lc_err_buf
                            ,lc_entity_ref
                            ,p_pool_record_tbl(i).entity_id
                            );
     END;
     END LOOP;
     END DELETE_RECORD;



   PROCEDURE ACTION_APPROVE(
                         p_pool_record_tbl IN pool_record_tbl_type
                        ,x_err_buf OUT VARCHAR2
                        ,x_ret_code OUT VARCHAR2
                       ) 
   IS 
    lc_err_buf VARCHAR2(4000);
    lc_ret_code VARCHAR2(4000);
    lc_entity_ref VARCHAR2(100);
    lc_return_status VARCHAR2(4000);
    lc_msg_count PLS_INTEGER;
    lc_msg_data VARCHAR2(4000);

   BEGIN
        lc_entity_ref := 'Approve Action for the Pool';
        For i in p_pool_record_tbl.FIRST..p_pool_record_tbl.LAST
         LOOP   

        BEGIN     
           IF p_pool_record_tbl(i).entity_name = 'ORDER' Then
                XX_OM_HOLDMGMTFRMWK_PKG.Release_Hold_Manually(p_pool_record_tbl(i).entity_Id
                                                              ,NULL
                                                              ,p_pool_record_tbl(i).hold_id
							                    ,p_pool_record_tbl(i).pool_id
                                                              ,lc_return_status
                                                              ,lc_msg_count
                                                              ,lc_msg_data
                                                             );

           ELSIF p_pool_record_tbl(i).entity_name = 'LINE' Then
                XX_OM_HOLDMGMTFRMWK_PKG.Release_Hold_Manually( NULL
                                                              ,p_pool_record_tbl(i).entity_Id
                                                              ,p_pool_record_tbl(i).hold_id
							                    ,p_pool_record_tbl(i).pool_id
                                                              ,lc_return_status
                                                              ,lc_msg_count
                                                              ,lc_msg_data
                                                             ); 

          END IF;

          IF lc_return_status = 'S' then
                                               
              x_ret_code := 'S';
              x_err_buf :='Succesfully released the hold';
     
          ELSIF lc_return_status = 'E' then

             x_ret_code := 'E';
             x_err_buf := lc_msg_data;
          END IF;

         EXCEPTION   
           WHEN OTHERS THEN
             x_ret_code :='E';
             x_err_buf :='The following error occured while approving the pool records '||sqlerrm(sqlcode);
             lc_ret_code :='E';
             lc_err_buf :='The following error occured while approving the pool records '||sqlerrm(sqlcode); 
             WRITE_EXCEPTION(
                              lc_ret_code
                             ,lc_err_buf
                             ,lc_entity_ref
                             ,p_pool_record_tbl(i).pool_id
                            );
        END;
        END LOOP;
               
        END ACTION_APPROVE;


 /*  PROCEDURE ACTION_RETRIEVE( p_pool_id IN VARCHAR2
                             ,p_pool_record_tbl OUT pool_record_tbl_type
                             ,x_err_buf OUT VARCHAR2
                             ,x_ret_code OUT VARCHAR2)
   IS

   lc_view_name VARCHAR2(50);
   lc_sql_stmt VARCHAR2(2000);
   lc_err_buf VARCHAR2(4000);
   lc_ret_code VARCHAR2(4000);
   lc_entity_ref VARCHAR2(100);
   
   
   BEGIN

   SELECT view_name into lc_view_name from xx_om_pool_names where pool_id=p_pool_id;
           
   lc_sql_stmt := 'SELECT * from '||lc_view_name ;
   EXECUTE IMMEDIATE lc_sql_stmt INTO p_pool_record_tbl;

   x_ret_code := 'S';
   x_err_buf := 'Retrieved the pool records successfully';
   lc_entity_ref := 'Data retrieval for the pool';



   EXCEPTION
     WHEN NO_DATA_FOUND THEN
        x_ret_code := 'E';
        x_err_buf := 'No records to retrieve from the pool view';
        lc_ret_code :='E';
        lc_err_buf := 'No records to retrieve from the pool view';  
        
        WRITE_EXCEPTION(
                        lc_ret_code
                       ,lc_err_buf
                       ,lc_entity_ref
                       ,p_pool_id
                        );  

     WHEN OTHERS THEN
        x_ret_code :='E';
        x_err_buf :='The following error occured while trying to retrieve the pool records '||sqlerrm(sqlcode);
        lc_ret_code :='E';
        lc_err_buf :='The following error occured while trying to retrieve the pool records '||sqlerrm(sqlcode); 
        WRITE_EXCEPTION(
                        lc_ret_code
                       ,lc_err_buf
                       ,lc_entity_ref
                       ,p_pool_id
                       );              
    END ACTION_RETRIEVE; */

END XX_OM_COMMON_POOL_PKG;