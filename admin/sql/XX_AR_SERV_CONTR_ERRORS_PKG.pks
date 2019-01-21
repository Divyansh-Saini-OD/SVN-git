CREATE OR REPLACE PACKAGE XX_AR_SERV_CONTR_ERRORS_PKG AS
 
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name             :  XX_AR_SERV_CONTR_ERRORS_PKG                                           |
-- |  RICE ID          :                                                                        |
-- |  Description      : This script creates the package XX_AR_SERV_CONTR_ERRORS_PKG            |
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
);

END XX_AR_SERV_CONTR_ERRORS_PKG;
/
SHOW ERRORS;