SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_CUST_UTIL_BO_PUB
  -- +================================================================================================+
  -- |                  Office Depot - Project Simplify                                               |
  -- +================================================================================================|
  -- | Name       : XX_CDH_CUST_UTIL_BO_PUB                                                           |
  -- | Description: This package is the Wrapper for  inserting the log entries into the               |
  -- |              table  XX_CDH_CUST_UTIL_BO_PUB                                                    |
  -- |                                                                                                |
  -- |Change Record:                                                                                  |
  -- |                                                                                                |
  -- |Version     Date            Author               Remarks                                        |
  -- |                                                                                                |
  -- |DRAFT 1   18-OCT-2012   Sreedhar Mohan             Initial draft version                        |
  -- |                                                                                                |
  -- |================================================================================================|
  -- | Subversion Info:                                                                               |
  -- | $HeadURL: http://svn.na.odcorp.net/svn/od/crm/trunk/xxcrm/admin/sql/XX_CDH_CUST_UTIL_BO_PUB.pkb $                                                                          |
  -- | $Rev: 103271 $                                                                                 |
  -- | $Date: 2012-10-18 01:56:07 -0400 (Thu, 18 Oct 2012) $                                          |
  -- |                                                                                                |
  -- +================================================================================================+
AS
  -- +================================================================================================+
  -- | Name             : LOG_MSG                                                                     |
  -- | Description      : This procedure inserts log messages into XX_CDH_CUSTOMER_BO_LOG             |
  -- |                                                                                                |
  -- +================================================================================================+

  PROCEDURE LOG_MSG(   p_bo_process_id  NUMBER DEFAULT 0,
                       p_msg            VARCHAR2
                   )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION ;
  BEGIN
    IF NVL(FND_PROFILE.VALUE('XX_CDH_CUSTOMER_BO_LOG_ENABLE'),'N')='Y' THEN
      INSERT INTO xx_cdh_customer_bo_log
        VALUES(xx_cdh_customer_bo_log_s.NEXTVAL
              ,p_bo_process_id
              ,p_msg
              ,SYSDATE
              ,FND_GLOBAL.user_id
              );
        COMMIT;
     ELSE
        ROLLBACK;
     END IF;
  EXCEPTION
  WHEN OTHERS THEN
     ROLLBACK;
  END LOG_MSG;
  
 PROCEDURE Log_exception (
                          P_BO_PROCESS_ID           NUMBER := 0,
                          P_BPEL_PROCESS_ID         NUMBER,  
                          P_BO_OBJECT_NAME          VARCHAR2,
                          P_LOG_DATE                DATE, 
                          P_LOGGED_BY               NUMBER,
                          P_PACKAGE_NAME            VARCHAR2,
                          P_PROCEDURE_NAME          VARCHAR2,
                          P_BO_TABLE_NAME           VARCHAR2,
                          P_BO_COLUMN_NAME          VARCHAR2,
                          P_BO_COLUMN_VALUE         VARCHAR2,
                          P_ORIG_SYSTEM             VARCHAR2,
                          P_ORIG_SYSTEM_REFERENCE   VARCHAR2,
                          P_EXCEPTION_LOG           VARCHAR2,
                          P_ORACLE_ERROR_CODE       VARCHAR2,
                          P_ORACLE_ERROR_MSG        VARCHAR2 
                          )
IS
    PRAGMA AUTONOMOUS_TRANSACTION ;
  BEGIN

      INSERT INTO XX_CDH_CUST_BO_EXCEPTIONS 
              (
                EXCEPTION_ID         
               ,BO_PROCESS_ID        
               ,BPEL_PROCESS_ID      
               ,BO_OBJECT_NAME       
               ,LOG_DATE             
               ,LOGGED_BY            
               ,PACKAGE_NAME         
               ,PROCEDURE_NAME       
               ,BO_TABLE_NAME        
               ,BO_COLUMN_NAME       
               ,BO_COLUMN_VALUE      
               ,ORIG_SYSTEM          
               ,ORIG_SYSTEM_REFERENCE
               ,EXCEPTION_LOG        
               ,ORACLE_ERROR_CODE    
               ,ORACLE_ERROR_MSG
              )                                       
        VALUES(
               XX_CDH_CUST_BO_EXCEPTIONS_S.NEXTVAL
              ,P_BO_PROCESS_ID
              ,P_BPEL_PROCESS_ID
              ,P_BO_OBJECT_NAME
              ,SYSDATE
              ,FND_GLOBAL.user_id
              ,P_PACKAGE_NAME         
              ,P_PROCEDURE_NAME       
              ,P_BO_TABLE_NAME        
              ,P_BO_COLUMN_NAME       
              ,P_BO_COLUMN_VALUE      
              ,P_ORIG_SYSTEM          
              ,P_ORIG_SYSTEM_REFERENCE
              ,P_EXCEPTION_LOG        
              ,P_ORACLE_ERROR_CODE    
              ,P_ORACLE_ERROR_MSG
              );
        COMMIT;

  EXCEPTION
  WHEN OTHERS THEN
     ROLLBACK;                          
END Log_exception;

procedure save_gt(
                      P_BO_PROCESS_ID            NUMBER,                       
                      P_BO_ENTITY_NAME           VARCHAR2,
                      P_BO_TABLE_ID              NUMBER,
                      P_ORIG_SYSTEM              VARCHAR2,
                      P_ORIG_SYSTEM_REFERENCE    VARCHAR2
                    )
AS                    
  PRAGMA AUTONOMOUS_TRANSACTION ;
  
  BEGIN

      INSERT INTO XX_CDH_SAVED_BO_ENTITIES_GT 
              (
                BO_PROCESS_ID        
               ,BO_ENTITY_NAME       
               ,BO_TABLE_ID          
               ,ORIG_SYSTEM          
               ,ORIG_SYSTEM_REFERENCE
               ,LAST_COMMIT_DATE     
               ,COMMITTED_BY         
               ,TRANS_VALIDATED_FLAG 
              )                                       
        VALUES(
               P_BO_PROCESS_ID
              ,P_BO_ENTITY_NAME
              ,P_BO_TABLE_ID
              ,P_ORIG_SYSTEM
              ,P_ORIG_SYSTEM_REFERENCE
              ,sysdate
              ,FND_GLOBAL.user_id
              ,NULL
              );
        COMMIT;

  EXCEPTION
  WHEN OTHERS THEN
     ROLLBACK;     
end save_gt;

procedure purge_gt
IS
begin
  EXECUTE IMMEDIATE 'truncate table XX_CDH_SAVED_BO_ENTITIES_GT';
end purge_gt;



END XX_CDH_CUST_UTIL_BO_PUB;
/
SHOW ERRORS;