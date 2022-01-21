create or replace package XX_PO_POM_INT_MISSHIP_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_PO_POM_INT_MISSHIP_PKG                                                   |
-- |  RICE ID 	 :  I2193_PO to EBS Interface Mis-Ship  			                |
-- |  Description:         								        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         08/31/2017   Avinash Baddam   Initial version                                  |
-- +============================================================================================+
PROCEDURE interface_master(p_errbuf       OUT  VARCHAR2
                          ,p_retcode      OUT  VARCHAR2
                      	  ,p_retry_errors      VARCHAR2                          
                      	  ,p_debug             VARCHAR2);
                      	  
END XX_PO_POM_INT_MISSHIP_PKG;
/