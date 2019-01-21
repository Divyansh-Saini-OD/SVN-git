SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace
PACKAGE XX_CRM_FTP_PUB 
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CRM_FTP_PUB                                             |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Package Transferring ASCII File to Remote Machines         | 
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      13-Jan-2008  Indra Varada           Initial Version              |
-- |                                                                          |
-- +==========================================================================+
AS

 PROCEDURE transfer_file 
  (
   x_errbuf       OUT NOCOPY VARCHAR2,
   x_retcode      OUT NOCOPY VARCHAR2,
   p_host_dest    IN  VARCHAR2,
   p_from_dir     IN  VARCHAR2,
   p_from_file    IN  VARCHAR2,
   p_to_dir       IN  VARCHAR2,
   p_to_file      IN  VARCHAR2
  );
  
  PROCEDURE host_setup
  (
   x_errbuf       OUT NOCOPY VARCHAR2,
   x_retcode      OUT NOCOPY VARCHAR2,
   p_host_dest    IN  VARCHAR2
   );

END XX_CRM_FTP_PUB;
/
SHOW ERRORS;
EXIT;
