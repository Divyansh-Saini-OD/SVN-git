SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_OM_EXTERNAL_USERS_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_OM_EXTERNAL_USER_PKG.pkb                                       |
-- | Description:                                                              |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======  ===========  =============    ====================================|
-- |1.0      14-May-2010  Matthew Craig    Initial draft version               |
-- +===========================================================================+

-- +===========================================================================+
-- | Name: generate_ldif_file                                                  |
-- |                                                                           |
-- | Description:                                                              |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- | Returns :    x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE generate_ldif_file (
     x_retcode          OUT NOCOPY VARCHAR2
    ,x_errbuff          OUT NOCOPY VARCHAR2);

PROCEDURE generate_ldif_file;
    
PROCEDURE log_message(pBUFF  IN  VARCHAR2) ;
PROCEDURE write_output(pBUFF  IN  VARCHAR2) ;
    

END XX_OM_EXTERNAL_USERS_PKG;
/