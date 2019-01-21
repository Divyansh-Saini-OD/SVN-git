create or replace
PACKAGE  XX_HR_USER_ACCTCOUR_PKG   
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_HR_USER_ACCTCOUR_PKG                                                            |
-- |  Description:  OD: HR User Extract for Account Courier                                     |
-- |                I2124_EBS_User_Feed_for_Account_Courier                                     |
-- |                Defect 9215                                                                 |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         12/14/2010   Joe Klein        Initial version                                  |
-- +============================================================================================+


-- +============================================================================================+
-- |  Name: XX_CREATE_EXTR_FILE_PROC                                                            |
-- |  Description: This pkg.procedure will extract users from fnd_user table to feed to Account |
-- |  Courier.                                                                                  |
-- =============================================================================================|
   PROCEDURE XX_CREATE_EXTR_FILE_PROC (errbuff     OUT VARCHAR2
                                      ,retcode     OUT VARCHAR2);
                                       
END  XX_HR_USER_ACCTCOUR_PKG;

/
