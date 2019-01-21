SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

PROMPT
PROMPT Creating OBJECT TYPE APPS.XX_CRM_ROLE_JOB_REL_TBL
PROMPT

create or replace
type APPS.XX_CRM_ROLE_JOB_REL_TBL is table of APPS.XX_CRM_ROLE_JOB_REL;
/

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
