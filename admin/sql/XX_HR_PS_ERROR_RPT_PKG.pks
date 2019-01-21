CREATE OR REPLACE PACKAGE  XX_HR_PS_ERROR_RPT_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_HR_PS_ERROR_RPT_PKG                                                             |
-- |  Description:  Plsql Package to run the OD: HR PER Employees from Peoplesoft Error Report  |
-- |                and send email the output                                                   |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         08/21/2012   Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: XX_ERROR_RPT                                                                        |
-- |  Description: This procedure will run the OD: HR PER Employees from Peoplesoft Error Report|
-- |               and email the output                                                         |
-- =============================================================================================|

PROCEDURE XX_ERROR_RPT(errbuff     OUT VARCHAR2
                      ,retcode     OUT VARCHAR2
		      ,p_days	   IN  NUMBER
		      );		
 

                                  
END XX_HR_PS_ERROR_RPT_PKG;

/