SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_LOAD_CONTACT_ORG_PKG AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_OM_LOAD_CONTACT_ORG_PKG.pks                                    |
-- | Description: This package will load the relationship of a contact to an   |
-- |              Org for a Vendor                                             |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======  ===========  =============    ====================================|
-- |1.0      02-May-2008  Matthew Craig    Initial draft version               |
-- |                                                                           |
-- +===========================================================================+

-- +===========================================================================+
-- | Name: service_contact_org_load                                            |
-- |                                                                           |
-- | Description: This prcodure will read records from a CSV formatted file    |
-- |              to load the realtionship from an Org to a Contact for a      |
-- |              Vendor                                                       |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |              p_contact_file                                               |
-- |              p_file_location                                              |
-- |                                                                           |
-- | Returns :    x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

PROCEDURE service_contact_org_load (
     x_retcode                OUT NOCOPY VARCHAR2
    ,x_errbuff                 OUT NOCOPY VARCHAR2
    ,p_contact_file IN VARCHAR2
    ,p_file_location IN VARCHAR2);
    
PROCEDURE log_message(pBUFF  IN  VARCHAR2) ;
    

END XX_OM_LOAD_CONTACT_ORG_PKG;
/
EXIT;
