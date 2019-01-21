SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_ACCOUNT_STATUS_PKG

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_ACCOUNT_STATUS_PKG.pks                      |
-- | Description :  Code to Modify Account and Site Status             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  02-Feb-2009 Indra Varada       Initial draft version     |
-- +===================================================================+

AS

   
PROCEDURE STATUS_MAIN(
                  p_errbuf             OUT NOCOPY VARCHAR2,
                  p_retcode            OUT NOCOPY VARCHAR2,
                  p_summary_batch_id   IN VARCHAR2,
                  p_activation_flag    IN VARCHAR2,
                  p_db_link_name       IN VARCHAR2,
                  p_commit_flag        IN VARCHAR2

                );
                
PROCEDURE update_site_and_acct_status (
                  p_errbuf             OUT NOCOPY VARCHAR2,
                  p_retcode            OUT NOCOPY VARCHAR2,
                  p_entity_type        IN VARCHAR2,
                  p_summary_batch_id   IN VARCHAR2,
                  p_activation_flag    IN VARCHAR2,
                  p_db_link_name       IN VARCHAR2,
                  p_commit_flag        IN VARCHAR2
                 );

                
END XX_CDH_ACCOUNT_STATUS_PKG;
/
SHOW ERRORS;
EXIT;