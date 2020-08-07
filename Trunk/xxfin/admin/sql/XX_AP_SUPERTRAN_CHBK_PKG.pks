create or replace package XX_AP_SUPERTRAN_CHBK_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AP_SUPERTRAN_CHBK_PKG                                                        |
-- |  RICE ID 	 :  E3522_OD Trade Match Foundation     			                            |
-- |  Description:         								                                        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         09/02/2017   Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+
              
PROCEDURE process_supertran(p_errbuf      OUT  VARCHAR2 
						   ,p_retcode     OUT  VARCHAR2
						   ,p_source      IN   VARCHAR2
						   ) ;
					
END XX_AP_SUPERTRAN_CHBK_PKG;
/
SHOW ERRORS;
