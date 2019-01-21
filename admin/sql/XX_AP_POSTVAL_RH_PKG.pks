create or replace package XX_AP_POSTVAL_RH_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AP_TR_MATCH_POSTVAL_PKG                                                  |
-- |  RICE ID 	 :  E3522_OD Trade Match Foundation     			                |
-- |  Description:         								        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         08/16/2017   Avinash Baddam   Initial version                                  |
-- | 1.1         11/30/2018   Ragni Gupta      Made p_source as IN parameter                      |
-- +============================================================================================+
              
PROCEDURE validate_release_holds(p_errbuf      OUT  VARCHAR2 
			        ,p_retcode     OUT  VARCHAR2
			        ,p_source      IN  VARCHAR2
			        ,p_debug            VARCHAR2) ;
                      	  
END XX_AP_POSTVAL_RH_PKG;
/
