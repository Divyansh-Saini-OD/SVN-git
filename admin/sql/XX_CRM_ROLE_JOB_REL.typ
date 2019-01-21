SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

PROMPT
PROMPT Creating OBJECT TYPE APPS.XX_CRM_ROLE_JOB_REL
PROMPT

create or replace
TYPE APPS.XX_CRM_ROLE_JOB_REL AS OBJECT
(
  ROLE_ID NUMBER(15,0),
  JOB_ID  NUMBER(15,0)
);
/

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
