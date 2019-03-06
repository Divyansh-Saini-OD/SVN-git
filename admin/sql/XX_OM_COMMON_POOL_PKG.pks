SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE XX_OM_COMMON_POOL_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                                                      
-- |
-- |                Office Depot                                                                           
-- |
-- +===================================================================+
-- | Name  : XX_OM_COMMON_POOL_PKG                                                                   
-- |
-- | Description      : Package Specification                                                              
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

/* Declaration of global record types */

TYPE pool_record_rec_type 
IS RECORD(
            Entity_name        VARCHAR2(50)
           ,Entity_Id          NUMBER
           ,Pool_id            VARCHAR2(50)
           ,Hold_id            NUMBER  
           ,Reviewer           VARCHAR2(50)
           ,Priority           VARCHAR2(30)
           ,HoldOver_code      VARCHAR2(30)
           ,Org_id             NUMBER
           ,Creation_date      DATE
           ,Created_by         NUMBER
           ,Last_update_date   DATE
           ,Last_updated_by    NUMBER
           ,Last_update_login  NUMBER
	  );

TYPE Pool_record_tbl_type 
IS TABLE OF Pool_Record_Rec_Type INDEX BY BINARY_INTEGER;

ge_exception  xx_om_report_exception_t := xx_om_report_exception_t(
                                                                       'OTHERS'
                                                                      ,'OTC'
                                                                      ,'Pools Notification'
                                                                      ,'Pools Notification'
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,NULL
                                                                     );


PROCEDURE Write_Exception (
                                p_error_code        IN  VARCHAR2
                               ,p_error_description IN  VARCHAR2
                               ,p_entity_reference  IN  VARCHAR2
                               ,p_entity_ref_id     IN  VARCHAR2
                            );



PROCEDURE INSERT_RECORD( 
                         p_pool_record_tbl IN pool_record_tbl_type
                        ,x_err_buf OUT VARCHAR2
                        ,x_ret_code OUT VARCHAR2
                       );


PROCEDURE UPDATE_RECORD( 
                         p_pool_record_tbl IN pool_record_tbl_type
                        ,x_err_buf OUT VARCHAR2
                        ,x_ret_code OUT VARCHAR2
                       );


PROCEDURE DELETE_RECORD( 
                         p_pool_record_tbl IN pool_record_tbl_type
                        ,x_err_buf OUT VARCHAR2
                        ,x_ret_code OUT VARCHAR2
                       );


PROCEDURE ACTION_APPROVE(
                         p_pool_record_tbl IN pool_record_tbl_type
                        ,x_err_buf OUT VARCHAR2
                        ,x_ret_code OUT VARCHAR2
                       );

/*PROCEDURE ACTION_ORDER_EXISTS(
                             p_pool_record_tbl IN pool_record_tbl_type
                            ,x_err_buf OUT VARCHAR2
                            ,x_ret_code OUT VARCHAR2
                           ); 


PROCEDURE ACTION_HOLD_CSR (
                             p_pool_record_tbl IN pool_record_tbl_type
                            ,x_err_buf OUT VARCHAR2
                            ,x_ret_code OUT VARCHAR2
                           );


PROCEDURE ACTION_CANCEL(
                        p_pool_record_tbl IN pool_record_tbl_type
                       ,x_err_buf OUT VARCHAR2
                       ,x_ret_code OUT VARCHAR2
                       ); 

PROCEDURE ACTION_RETRIEVE( p_pool_id IN VARCHAR2
                             ,p_pool_record_tbl OUT pool_record_tbl_type
                             ,x_err_buf OUT VARCHAR2
                             ,x_ret_code OUT VARCHAR2);*/

END  XX_OM_COMMON_POOL_PKG;
/

