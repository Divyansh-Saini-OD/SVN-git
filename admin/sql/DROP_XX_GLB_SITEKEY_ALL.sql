SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        Office Depot                               |
-- +===================================================================+
-- | Name             : DROP_XX_GLB_SITEKEY_ALL.sql                    |
-- | Rice ID	      : I1176 CreateServiceRequest                     |
-- | Description      : This scipt drops the custom table 	       |
-- |                    XX_GLB_SITEKEY_ALL                             |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       05-Feb-2008 Bibiana Penski   Initial Version             |
-- |                                                                   |
-- +===================================================================+

PROMPT
PROMPT Dropping table XX_GLB_SITEKEY_ALL
PROMPT

DROP TABLE XXOM.XX_GLB_SITEKEY_ALL;


WHENEVER SQLERROR EXIT 1 

PROMPT 
PROMPT Exiting.... 
PROMPT 

SET FEEDBACK ON 
EXIT; 