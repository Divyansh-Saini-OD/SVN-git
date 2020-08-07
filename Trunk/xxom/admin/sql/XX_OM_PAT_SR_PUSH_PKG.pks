SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_PAT_SR_PUSH_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_OM_PAT_SR_PUSH_PKG.pks                                         |
-- | Description: This package will extract the service requests that have     |
-- |              modified since the last extract for PAT Reporting            |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======  ===========  =============    ====================================|
-- |1.0      14-May-2009  Matthew Craig    Initial draft version               |
-- |                                                                           |
-- +===========================================================================+

-- +===========================================================================+
-- | Name: service_request_extract                                             |
-- |                                                                           |
-- | Description: This prcodure will be called from a CP and will extract      |
-- |              the modified service requests and insert them into a table   |
-- |              on the PAT SQL Server                                        |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |              p_last_run_date                                              |
-- |                                                                           |
-- | Returns :    x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE Service_Request_Extract (
     x_retcode          OUT NOCOPY VARCHAR2
    ,x_errbuff          OUT NOCOPY VARCHAR2
    ,p_last_run_date    IN  VARCHAR2 );

/*removed as FTP does not work at this time
PROCEDURE Service_Request_Extract (
     x_retcode          OUT NOCOPY VARCHAR2
    ,x_errbuff          OUT NOCOPY VARCHAR2
    ,p_last_run_date    IN DATE
    ,p_host             IN  VARCHAR2
    ,p_user_name        IN  VARCHAR2
    ,p_password         IN  VARCHAR2
    ,p_destination_dir  IN  VARCHAR2);
*/
    
PROCEDURE log_message(pBUFF  IN  VARCHAR2) ;
    

END XX_OM_PAT_SR_PUSH_PKG;
/