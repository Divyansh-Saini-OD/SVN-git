-- $Id:  $
-- $Rev:  $
-- $HeadURL:  $
-- $Author:  $
-- $Date:  $
SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XXCCRM_OPPTY_FIX_PKG AUTHID CURRENT_USER 
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify  Rel 1.2                           |
-- +=====================================================================================+
-- |                                                                                     |
-- | Name             : Update_Opportunities                                             |
-- |                                                                                     |
-- | Description      : Fix the opportunities as per Defect - 4487                       |
-- |                                                                                     |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date        Author                       Remarks                           |
-- |=======   ==========  ====================         ==================================|
-- |Draft 1.0 04-APR-10   Nabarun Ghosh                Draft version                     |
-- |											 |
-- |											 |
-- +=====================================================================================+
AS


PROCEDURE Update_Opportunities (  p_errbuf    OUT NOCOPY VARCHAR2
                                 ,p_retcode   OUT NOCOPY VARCHAR2
                                 ,p_opportunity_number  IN VARCHAR2
                                 );
END XXCCRM_OPPTY_FIX_PKG;
/
SHOW ERRORS;
