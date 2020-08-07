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
-- | Name  :  XX_PA_EJM_PROJ_OUT_REC                                   |
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
PROMPT Creating Record type XX_PA_EJM_PROJ_OUT_REC
SET TERM OFF

create or replace
TYPE XX_PA_EJM_PROJ_OUT_REC IS OBJECT
(pa_project_id          NUMBER,
 pa_project_number      VARCHAR2(25),
 return_status          VARCHAR2(1),
 Error_message          VARCHAR2(1000))
/


SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF



SHOW ERROR



