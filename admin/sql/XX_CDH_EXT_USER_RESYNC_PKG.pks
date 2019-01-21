SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_EXT_USER_RESYNC_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name        :  XX_CDH_EXT_USER_RESYNC_PKG.pks                     |
-- | Description :  CDH External User Re-sync Package Spec             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  23-Jul-2014 Sreedhar Mohan     Initial draft version     |
-- |                                                                   |
-- +===================================================================+
AS
  procedure re_sync_user (
                           x_errbuf              OUT VARCHAR2
                          ,x_retcode             OUT VARCHAR2
				          ,p_userid              IN  VARCHAR2   
                          ,p_debug               IN  VARCHAR2 DEFAULT 'N'  
                         );
  procedure show_report (
                    x_errbuf              OUT VARCHAR2
                   ,x_retcode             OUT VARCHAR2
				   ,p_last_upd_date_from  IN  VARCHAR2     
				   ,p_last_upd_date_to    IN  VARCHAR2 DEFAULT TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS')
				   ,p_creation_date_from  IN  VARCHAR2 
				   ,p_creation_date_to    IN  VARCHAR2 
            );	
   PROCEDURE check_responsibility (
       p_cust_acct_cnt_os     IN       VARCHAR2
     , p_cust_acct_cnt_osr    IN       VARCHAR2
     , p_cust_acct_site_osr   IN       VARCHAR2
     , p_cust_acct_osr        IN       VARCHAR2
     , p_action               IN       VARCHAR2
     , p_permission_flag      IN       VARCHAR2
	 , p_debug                IN       VARCHAR2
     , x_cust_acct_site_id    OUT      NUMBER
     , x_org_contact_id       OUT      NUMBER
	 , x_cust_account_role_id OUT      NUMBER
     , x_responsibility_type  OUT      HZ_ROLE_RESPONSIBILITY.responsibility_type%TYPE
     , x_retcode              OUT      VARCHAR2
   );
  procedure main (
                    x_errbuf              OUT VARCHAR2
                   ,x_retcode             OUT VARCHAR2
				   ,p_last_upd_date_from  IN  VARCHAR2     
				   ,p_last_upd_date_to    IN  VARCHAR2 DEFAULT TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS')      
				   ,p_creation_date_from  IN  VARCHAR2 
				   ,p_creation_date_to    IN  VARCHAR2 
				   ,p_commit_size         IN  NUMBER   DEFAULT 40
                   ,p_sleep_time          IN  NUMBER   DEFAULT 60
				   ,p_debug               IN  VARCHAR2 DEFAULT 'N'
            );
						 
END XX_CDH_EXT_USER_RESYNC_PKG;
/
