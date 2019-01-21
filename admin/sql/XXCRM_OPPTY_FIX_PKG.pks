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

CREATE OR REPLACE PACKAGE XXCRM_OPPTY_FIX_PKG AUTHID CURRENT_USER 
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
-- | 1.1      06-MAY-10   Sreekanth Rao                Updated the Program to use delete |
-- |                                                   API, as data was duplicated and we|
-- |                                                   do not use AS_ACCESSES_ALL        |
-- | 1.2      04-JUN-10   Anitha Devarajulu            Updated the Program to use Update |
-- |                                                   API to update sales group id      |
-- | 1.3      13-SEP-10   Lokesh Kumar                 API to update stage and methodolog|  
-- +=====================================================================================+
AS


PROCEDURE Remove_Opp_Rec_From_Access (  p_errbuf    OUT NOCOPY VARCHAR2
                                       ,p_retcode   OUT NOCOPY VARCHAR2
                                       ,p_opportunity_number  IN VARCHAR2
                                     );

PROCEDURE Update_Opp_Rec_From_Access (  p_errbuf    OUT NOCOPY VARCHAR2
                                       ,p_retcode   OUT NOCOPY VARCHAR2
                                       ,p_opportunity_number  IN VARCHAR2
                                     );
                                     
PROCEDURE Update_Opp_Rec_with_stage_meth (p_errbuf              OUT NOCOPY VARCHAR2
                                         ,p_retcode             OUT NOCOPY VARCHAR2
                                         ,p_update              IN VARCHAR2
                                         ,p_lead_num            in number := 10000000
                                         ,p_salesforce_name     IN VARCHAR2
                                        );
                                        
END XXCRM_OPPTY_FIX_PKG;

/
SHOW ERRORS;
