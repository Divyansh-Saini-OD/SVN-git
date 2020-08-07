-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_OM_REPORT_EXCEPTION_T.typ                                                |
-- | Rice Id      :                                                                             | 
-- | Description  : OD Exceptions Handling Object Creation                                      |  
-- | Purpose      : Create Custom Object.                                                       |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   03-May-2007   Bapuji Nanapaneni    Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+


SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF


PROMPT
PROMPT Dropping TYPE xx_om_report_exception_t
PROMPT

DROP TYPE xx_om_report_exception_t;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Creating the object xx_om_report_exception_t .....
PROMPT


CREATE OR REPLACE
TYPE xx_om_report_exception_t AS OBJECT (
      P_exception_header           VARCHAR2(40)
    , P_track_code                 VARCHAR2(5)
    , P_solution_domain            VARCHAR2(40)
    , P_function                   VARCHAR2(40)
    , P_error_code                 VARCHAR2(40)
    , P_error_description          VARCHAR2(1000)
    , P_entity_ref                 VARCHAR2(40)
    , P_entity_ref_id              NUMBER
    )
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;