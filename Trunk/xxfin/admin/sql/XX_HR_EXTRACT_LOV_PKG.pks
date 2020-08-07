CREATE OR REPLACE PACKAGE  XX_HR_EXTRACT_LOV_PKG   
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_HR_EXTRACT_LOV_PKG                                                              |
-- |  Description:  Extract List of Values to feed to hosted Peoplesoft HR.                     |
-- |                I2171 – HR Extract Oracle List of Values                                    |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         05/21/2012   Joe Klein        Initial version                                  |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: EXTRACT_COMPANY_PROC                                                                |
-- |  Description: This procedure will extract companies from Oracle and create a file.         |
-- =============================================================================================|
PROCEDURE EXTRACT_COMPANY_PROC;
 
-- +============================================================================================+
-- |  Name: EXTRACT_LOB_PROC                                                                    |
-- |  Description: This procedure will extract line of business from Oracle and create a file.  |
-- =============================================================================================|
PROCEDURE EXTRACT_LOB_PROC;
                                  
-- +============================================================================================+
-- |  Name: EXTRACT_SOB_PROC                                                                    |
-- |  Description: This procedure will extract Set Of Books from Oracle and create a file.      |
-- =============================================================================================|
PROCEDURE EXTRACT_SOB_PROC;

-- +============================================================================================+
-- |  Name: EXTRACT_GARN_ACCT_PROC                                                              |
-- |  Description: This procedure will extract Set Of Books from Oracle and create a file.      |
-- =============================================================================================|
PROCEDURE EXTRACT_GARN_ACCT_PROC;
                                  
END  XX_HR_EXTRACT_LOV_PKG;

/