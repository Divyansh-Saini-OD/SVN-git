REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : HR CRM Interface                                                           |--
--|                                                                                             |--
--| Program Name   : Prevalidation Scripts                                                      |--
--|                                                                                             |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              16-Jun-2008       Sathya Prabha Rani      Initial version                  |--
--+=============================================================================================+--

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF



PROMPT
PROMPT Script - No of Employees with
PROMPT          1. Job Role SALES / SALES COMPENSATION
PROMPT          2. Reporting to &P_ID or his subordinates
PROMPT


SELECT           count(*),paaf.job_id
FROM             apps.PER_ALL_ASSIGNMENTS_F PAAF
START WITH       PAAF.person_id = &P_ID
CONNECT BY PRIOR PAAF.person_id = PAAF.supervisor_id
AND EXISTS
      (SELECT 1
       FROM   apps.JTF_RS_ROLES_B JRRB
            , apps.JTF_RS_JOB_ROLEs JRJR
       WHERE JRJR.job_id = PAAF.job_id
       AND   JRJR.role_id = JRRB.role_id
       AND   JRRB.role_type_code IN ('SALES','SALES_COMP')
      )
GROUP BY PAAF.job_id;


PROMPT
PROMPT Script - No of Resources to be created
PROMPT 


SELECT           count(*)
FROM             apps.PER_ALL_ASSIGNMENTS_F  PAAF
START WITH       PAAF.person_id = &P_ID
CONNECT BY PRIOR PAAF.person_id = PAAF.supervisor_id
AND EXISTS
        (SELECT 1
         FROM   apps.JTF_RS_ROLES_B    JRRB
              , apps.JTF_RS_JOB_ROLEs  JRJR
         WHERE  JRJR.job_id = PAAF.job_id
         AND    JRJR.role_id = JRRB.role_id
         AND    JRRB.role_type_code IN ('SALES','SALES_COMP')
        )
AND NOT EXISTS
        (SELECT 1
         FROM   apps.JTF_RS_RESOURCE_EXTNS  JRRE
         WHERE  JRRE.source_id = paaf.person_id
         AND    JRRE.category = 'EMPLOYEE'
        );


PROMPT
PROMPT Script - No of Resources to be Updated
PROMPT


SELECT           count(*)
FROM             apps.PER_ALL_ASSIGNMENTS_F  PAAF
START WITH       PAAF.person_id = &P_ID
CONNECT BY PRIOR PAAF.person_id = PAAF.supervisor_id
AND EXISTS
        (SELECT 1
         FROM   apps.JTF_RS_ROLES_B    JRRB
              , apps.JTF_RS_JOB_ROLES  JRJR
         WHERE  JRJR.job_id = PAAF.job_id
         AND    JRJR.role_id = JRRB.role_id
         AND    JRRB.role_type_code IN ('SALES','SALES_COMP')
        )
AND EXISTS
        (SELECT 1
         FROM   apps.JTF_RS_RESOURCE_EXTNS  JRRE
         WHERE  JRRE.source_id = paaf.person_id
         AND    (JRRE.source_job_id <> PAAF.job_id OR JRRE.source_mgr_id <> PAAF.supervisor_id)
         AND    JRRE.category = 'EMPLOYEE'
        );


PROMPT
PROMPT Script - 'No of resources with Admin Role
PROMPT


SELECT           count(*)
FROM             apps.PER_ALL_ASSIGNMENTS_F  PAAF
START WITH       PAAF.person_id = &P_ID
CONNECT BY PRIOR PAAF.person_id = PAAF.supervisor_id
AND EXISTS
        (SELECT 1
         FROM   apps.JTF_RS_ROLES_B    JRRB
              , apps.JTF_RS_JOB_ROLEs  JRJR
         WHERE  JRJR.job_id = PAAF.job_id
         AND    JRJR.role_id = JRRB.role_id
         AND    JRRB.role_type_code IN ('SALES')
         AND    JRRB.admin_flag = 'Y'
        );


PROMPT
PROMPT Script - No of resources with Sales Comp Payment Analyst Role
PROMPT


SELECT           count(*)
FROM             apps.PER_ALL_ASSIGNMENTS_F PAAF
START WITH       PAAF.person_id = &P_ID
CONNECT BY PRIOR PAAF.person_id = PAAF.supervisor_id
AND EXISTS
        (SELECT 1
         FROM   apps.JTF_RS_ROLES_B    JRRB
              , apps.JTF_RS_JOB_ROLEs  JRJR
         WHERE  JRJR.job_id = PAAF.job_id
         AND    JRJR.role_id = JRRB.role_id
         AND    JRRB.role_type_code IN ('SALES_COMP')
         AND    JRRB.Member_flag = 'Y'
        );


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================

