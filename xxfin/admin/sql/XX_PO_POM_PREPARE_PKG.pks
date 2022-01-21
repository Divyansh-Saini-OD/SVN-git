create or replace package XX_PO_POM_PREPARE_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_PO_POM_PREPARE_STG                                                       |
-- |  RICE ID 	 :  I2193_PO to EBS Interface     			                        |
-- |  Description:         								        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         07/24/2017   Avinash Baddam   Initial version                                  |
-- +============================================================================================+

PROCEDURE Prepare_staging (p_errbuf       OUT  VARCHAR2
                          ,p_retcode      OUT  VARCHAR2
                   	  ,p_debug             VARCHAR2);
                      	  
END XX_PO_POM_PREPARE_PKG;
/