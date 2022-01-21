CREATE OR REPLACE PACKAGE APPS.XX_GL_INTF_NA_STG_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:   XX_GL_INTERFACE_NA_STG                                                            |
-- |  Description:  Called BPEL Processes to insert into XX_GL_INTERFACE_NA_STG                 |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-NOV-2012  Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: INSERT_XX_GL_INTF_NA_STG                                                            |
-- |  Description: This procedure will insert records into XX_GL_INTERFACE_NA_STG table         |
-- =============================================================================================|
PROCEDURE INSERT_XX_GL_INTF_NA_STG(
                          p_errbuff           		OUT VARCHAR2
                         ,p_retcode           		OUT VARCHAR2
  	  	         ,p_xx_gl_intf_na_stg_list_t	IN  XX_GL_INTF_NA_STG_LIST_T
			);

END XX_GL_INTF_NA_STG_PKG;
/
