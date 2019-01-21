CREATE OR REPLACE PACKAGE APPS.XX_CE_AJB_INSERT_STG_PKG   
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_CE_AJB_INSERT_STG_PKG                                                           |
-- |  Description:  Called BPEL Processes to insert into XX_CE_AJB996, XX_CE_AJB998,            |
-- |	            XX_CE_AJB999, XX_AR_MAIL_CHECK_HOLDS tables                                 |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-NOV-2012  Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: INSERT_MAIL_CHECK_HOLDS                                                             |
-- |  Description: This procedure will insert records into XX_AR_MAIL_CHECK_HOLDS table         |
-- =============================================================================================|
PROCEDURE INSERT_AJB996 (
                          p_errbuff           		OUT VARCHAR2
                         ,p_retcode           		OUT VARCHAR2
  	  	         ,p_ce_ajb996_list_t		IN  XX_CE_AJB996_LIST_T
			);

PROCEDURE INSERT_AJB998 (
                          p_errbuff           		OUT VARCHAR2
                         ,p_retcode           		OUT VARCHAR2
  	    	         ,p_ce_ajb998_list_t		IN  XX_CE_AJB998_LIST_T
			);

PROCEDURE INSERT_AJB999 (
                          p_errbuff           	OUT VARCHAR2
                         ,p_retcode           	OUT VARCHAR2
  	  	         ,p_ce_ajb999_list_T 	IN  XX_CE_AJB999_LIST_T
		        );

PROCEDURE INSERT_MAIL_CHECK_HOLDS (
                                   p_errbuff           	OUT VARCHAR2
                                  ,p_retcode           	OUT VARCHAR2
				  ,p_mail_check_holds_T IN  XX_AR_MAIL_CHECK_HOLDS_LIST_T
				 ); 
END  XX_CE_AJB_INSERT_STG_PKG;
/
