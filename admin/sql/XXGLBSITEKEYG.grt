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
-- | Name             : XXGLBSITEKEYG.grt 				     |
-- | Rice ID          : I1176 CreateServiceRequest                     |
-- | Description      : This scipt grant privileges to APPS on:        |
-- |				XXOM.XX_GLB_SITEKEY_ALL 			     |
-- |				XXOM.XX_GLB_SITEKEY_S				     |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   18-Dec-2007 Bibiana Penski    Initial Version            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


PROMPT
PROMPT GRANTING PRIVILEGES ON XXOM.XX_GLB_SITEKEY_ALL TO APPS
PROMPT

GRANT SELECT, UPDATE, INSERT ON XXOM.XX_GLB_SITEKEY_ALL TO APPS;
                                                                                                              

PROMPT
PROMPT GRANTING PRIVILEGES ON XXOM.XX_GLB_SITEKEY_ALL_S TO APPS
PROMPT

GRANT SELECT ON XXOM.XX_GLB_SITEKEY_S TO APPS;

WHENEVER SQLERROR EXIT 1 
PROMPT 
PROMPT Exiting.... 
PROMPT 

SET FEEDBACK ON 

EXIT; 
