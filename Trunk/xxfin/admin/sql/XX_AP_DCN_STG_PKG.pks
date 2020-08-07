CREATE OR REPLACE PACKAGE APPS.XX_AP_DCN_STG_PKG 
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:   XX_AP_DCN_STG_PKG                                                                 |
-- |  Description:  Called BPEL Processes to insert into  XX_AP_DCN_STG                         |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-NOV-2012  Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: INSERT_XX_AP_DCN_STG                                                                |
-- |  Description: This procedure will insert records into XX_AP_DCN_STG table                  |
-- =============================================================================================|
PROCEDURE INSERT_XX_AP_DCN_STG(
                          p_errbuff           		OUT VARCHAR2
                         ,p_retcode           		OUT VARCHAR2
  	  	         ,p_ap_dcn_stg_list_t		IN  XX_AP_DCN_STG_LIST_T
			);


END XX_AP_DCN_STG_PKG;
/
