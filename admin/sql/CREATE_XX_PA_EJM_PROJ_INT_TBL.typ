SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_PA_EJM_PROJ_INT_TBL                                   |
-- | Description  : This script creates object type for EJM Project    |
-- |                rewrite                                            |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A  26-MAR-12    P. Marco             Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


SET TERM ON
PROMPT Creating Record type XX_PA_EJM_PROJ_INT_TBL
SET TERM OFF

create or replace
TYPE XX_PA_EJM_PROJ_INT_TBL AS TABLE OF XX_PA_EJM_PROJ_INT_REC
/


SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF



SHOW ERROR



