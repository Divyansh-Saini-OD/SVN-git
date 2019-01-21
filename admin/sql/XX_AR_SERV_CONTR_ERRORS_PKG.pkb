CREATE OR REPLACE PACKAGE BODY XX_AR_SERV_CONTR_ERRORS_PKG AS
 
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name             :  XX_AR_SERV_CONTR_ERRORS_PKG                                           |
-- |  RICE ID          :                                                                        |
-- |  Description      : This script creates the package body XX_AR_SERV_CONTR_ERRORS_PKG       |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         01/02/2018   Sridhar B        Initial version                                  |
-- +============================================================================================+
           
PROCEDURE CREATE_RECORD(
   P_Source           VARCHAR2
  ,P_Destination      VARCHAR2
  ,P_Message          CLOB
  ,P_Error_Code       VARCHAR2
  ,P_Error_Message    CLOB
  ,P_Status           VARCHAR2
  ,P_Order_Number     VARCHAR2
  ,P_Contract_Number  VARCHAR2
  ,P_CREATION_DATE    DATE      default sysdate   
  ,P_CREATED_BY       VARCHAR2
  ,P_LAST_UPDATE_DATE DATE      default sysdate   
  ,P_LAST_UPDATED_BY  VARCHAR2  
)
IS

BEGIN

INSERT INTO XX_AR_SERV_CONTR_API_ERRORS 
    (
     Source          
    ,Destination     
    ,Message         
    ,Error_Code      
    ,Error_Message   
    ,Status          
    ,Order_Number    
    ,Contract_Number 
    ,CREATION_DATE   
    ,CREATED_BY      
    ,LAST_UPDATE_DATE
    ,LAST_UPDATED_BY 
    )
  VALUES (
     P_Source          
    ,P_Destination     
    ,P_Message         
    ,P_Error_Code      
    ,P_Error_Message   
    ,P_Status          
    ,P_Order_Number    
    ,P_Contract_Number 
    ,P_CREATION_DATE   
    ,P_CREATED_BY      
    ,P_LAST_UPDATE_DATE
    ,P_LAST_UPDATED_BY   
  );
  
COMMIT;
END CREATE_RECORD;

END XX_AR_SERV_CONTR_ERRORS_PKG;
/
