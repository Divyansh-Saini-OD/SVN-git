REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : HR CRM Interface                                                           |--
--|                                                                                             |--
--| Program Name   : Postvalidation Scripts                                                     |--
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
PROMPT Script - No of resources to be created as Managers
PROMPT


SELECT count(*)
FROM   apps.per_all_assignments_f PAAF
START WITH PAAF.person_id = &P_ID
CONNECT BY PRIOR PAAF.person_id = PAAF.supervisor_id
AND EXISTS
        (SELECT 1
         FROM   apps.jtf_rs_roles_b   JRRB
              , apps.jtf_rs_job_roles JRJR
         WHERE JRJR.job_id = PAAF.job_id
         AND JRJR.role_id = JRRB.role_id
         AND JRRB.role_type_code IN ('SALES','SALES_COMP')
         AND JRRB.manager_flag = 'Y'
        )
AND NOT EXISTS
        (SELECT 1
         FROM   apps.jtf_rs_resource_extns JRRE
         WHERE  JRRE.source_id = paaf.person_id
         AND    JRRE.category = 'EMPLOYEE'
        );


PROMPT
PROMPT Script - No of Employees with Job id NULL
PROMPT 


SELECT count(*)
FROM apps.per_all_assignments_f PAAF
START WITH PAAF.person_id = &P_ID
CONNECT BY PRIOR PAAF.person_id = PAAF.supervisor_id
AND EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_roles_b    JRRB
             , apps.jtf_rs_job_roles  JRJR
        WHERE JRJR.job_id = PAAF.job_id
        AND JRJR.role_id = JRRB.role_id
        AND JRRB.role_type_code IN ('SALES','SALES_COMP')
       )
AND PAAF.job_id IS NULL;


PROMPT
PROMPT Script - No of resources to be created as Sales Reps
PROMPT


SELECT count(*)
FROM apps.per_all_assignments_f PAAF
START WITH PAAF.person_id = &P_ID
CONNECT BY PRIOR PAAF.person_id = PAAF.supervisor_id
AND EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_roles_b JRRB
             , apps.jtf_rs_job_roles JRJR
        WHERE  JRJR.job_id = PAAF.job_id
        AND    JRJR.role_id = JRRB.role_id
        AND    JRRB.role_type_code IN ('SALES','SALES_COMP')
        AND    JRRB.member_flag = 'Y'
       )
AND NOT EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_resource_extns JRRE
        WHERE  JRRE.source_id = PAAF.person_id
        AND    JRRE.category = 'EMPLOYEE'
       );


PROMPT
PROMPT Script - No of Resources not created as SALES REPS
PROMPT


SELECT count(*)
FROM apps.per_all_assignments_f PAAF
START WITH PAAF.person_id = &P_ID
CONNECT BY PRIOR PAAF.person_id = PAAF.supervisor_id
AND EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_roles_b JRRB
             , apps.jtf_rs_job_roles JRJR
        WHERE  JRJR.job_id = paaf.job_id
        AND    JRJR.role_id = jrrb.role_id
        AND    JRRB.role_type_code IN ('SALES','SALES_COMP')
        AND    JRRB.member_flag = 'Y'
       )
AND EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_resource_extns JRRE
        WHERE  JRRE.source_id = PAAF.person_id
        AND    JRRE.category = 'EMPLOYEE'
       )
AND NOT EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_salesreps JRS
        WHERE  JRS.resource_id = JRRE.resource_id
       );


PROMPT
PROMPT Script - No of Resources Loaded
PROMPT


SELECT *
FROM   apps.jtf_rs_resource_extns JRRE
START WITH JRRE.source_id = &P_ID
CONNECT BY PRIOR JRRE.source_id = JRRE.source_mgr_id
AND JRRE.category = 'EMPLOYEE';


PROMPT
PROMPT Script - No of Manager Resources created
PROMPT


SELECT *
FROM apps.jtf_rs_resource_extns JRRE
START WITH JRRE.source_id = &P_ID
CONNECT BY PRIOR JRRE.source_id = JRRE.source_mgr_id
AND JRRE.category = 'EMPLOYEE'
AND EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_role_relations  JRRR
             , apps.jtf_rs_roles_b         JRRB
        WHERE  JRRR.role_resource_id = JRRE.resource_id
        AND    JRRR.role_id = jrrb.role_id
        AND    JRRB.role_type_code IN ('SALES','SALES_COMP')
        AND    JRRB.manager_flag = 'Y'
       );


PROMPT
PROMPT Script - No of Admin Resources Loaded
PROMPT


SELECT *
FROM apps.jtf_rs_resource_extns JRRE
START WITH JRRE.source_id = &P_ID
CONNECT BY PRIOR JRRE.source_id = JRRE.source_mgr_id
AND JRRE.category = 'EMPLOYEE'
AND  EXISTS
        (SELECT 1
         FROM   apps.jtf_rs_role_relations  JRRR
              , apps.jtf_rs_roles_b         JRRB
         WHERE  JRRR.role_resource_id = JRRE.resource_id
         AND    JRRR.role_id = JRRB.role_id
         AND    JRRB.role_type_code IN ('SALES','SALES_COMP')
         AND    JRRB.admin_flag = 'Y'
        );


PROMPT
PROMPT Script - No Of Payment Analyst Loaded
PROMPT


SELECT *
FROM   apps.jtf_rs_resource_extns JRRE
START WITH JRRE.source_id = &P_ID
CONNECT BY PRIOR JRRE.source_id = JRRE.source_mgr_id
AND JRRE.category = 'EMPLOYEE'
AND EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_role_relations JRRR
             , apps.jtf_rs_roles_b JRRB
        WHERE  JRRR.role_resource_id = JRRE.resource_id
        AND    JRRR.role_id = jrrb.role_id
        AND    JRRB.role_type_code IN ('SALES_COMP_PAYMENT_ANALYST')
       );


PROMPT
PROMPT Script - No of Groups created
PROMPT


SELECT *
FROM   apps.jtf_rs_groups_tl JRGT
WHERE  JRGT.group_name IN 
             (SELECT  'OD_GRP_'||JRRE.source_last_name||'_'||JRRE.source_number
              FROM     apps.JTF_RS_RESOURCE_EXTNS JRRE
              START WITH JRRE.source_id = &P_ID
              CONNECT BY PRIOR JRRE.source_id = JRRE.source_mgr_id
              AND JRRE.category = 'EMPLOYEE'
              AND EXISTS
                    (SELECT 1
                     FROM   apps.jtf_rs_role_relations  JRRR
                          , apps.jtf_rs_roles_b         JRRB
                     WHERE  JRRR.role_resource_id = JRRE.resource_id
                     AND    JRRR.role_id = JRRB.role_id
                     AND    JRRB.role_type_code IN ('SALES', 'SALES_COMP')
                     AND    JRRB.manager_flag = 'Y'
                    )
             );



PROMPT
PROMPT Script - No of Members in Each Group
PROMPT


SELECT count(*), group_id
FROM apps.jtf_rs_group_members JRGM
WHERE JRGM.group_id IN 
               (SELECT jrgt.group_id
                FROM apps.jtf_rs_groups_tl JRGT
                WHERE JRGT.group_name IN 
                               (SELECT  'OD_GRP_'||JRRE.source_last_name||'_'||JRRE.source_number
                                FROM apps.jtf_rs_resource_extns JRRE
                                START WITH JRRE.source_id = &P_ID
                                CONNECT BY PRIOR JRRE.source_id = JRRE.source_mgr_id
                                AND JRRE.category = 'EMPLOYEE'
                                AND EXISTS
                                       (SELECT 1
                                        FROM   apps.jtf_rs_role_relations JRRR
                                             , apps.jtf_rs_roles_b JRRB
                                        WHERE  JRRR.role_resource_id = JRRE.resource_id
                                        AND    JRRR.role_id = JRRB.role_id
                                        AND    JRRB.role_type_code IN ('SALES', 'SALES_COMP')
                                        AND    JRRB.manager_flag = 'Y'
                                       )
                                )
                 )
GROUP BY JRGM.group_id;


PROMPT
PROMPT Script - No of Sales Support SRs created
PROMPT


SELECT *
FROM   apps.jtf_rs_resource_extns JRRE
START WITH JRRE.source_id = &P_ID
CONNECT BY PRIOR JRRE.source_id = JRRE.source_mgr_id
AND   JRRE.category = 'EMPLOYEE'
AND  EXISTS
        (SELECT 1
         FROM   apps.jtf_rs_role_relations JRRR
              , apps.jtf_rs_roles_b JRRB
         WHERE  JRRR.role_resource_id = JRRE.resource_id
         AND    JRRR.role_id = JRRB.role_id
         AND    JRRB.role_type_code IN ('SALES','SALES_COMP')
         AND    JRRB.attribute14 = 'SALES_SUPPORT'
        );


PROMPT
PROMPT Script - Validate Group Hierarchy
PROMPT


SELECT *
FROM   apps.jtf_rs_grp_relations
START WITH group_id = &GRP_ID
CONNECT BY PRIOR group_id = related_group_id
AND    relation_type = 'PARENT_GROUP';


PROMPT
PROMPT Script - Validate Effective Date for Manager Change and Job Code Change
PROMPT


SELECT *
FROM   apps.per_all_assignments_f PAAF
START WITH PAAF.person_id = &P_ID
CONNECT BY PRIOR PAAF.person_id = PAAF.supervisor_id
AND EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_roles_b    JRRB
             , apps.jtf_rs_job_roles  JRJR
        WHERE  JRJR.job_id = paaf.job_id
        AND    JRJR.role_id = jrrb.role_id
        AND    JRRB.role_type_code IN ('SALES','SALES_COMP')
       )
AND EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_resource_extns JRRE
        WHERE  JRRE.source_id = PAAF.person_id
        AND    JRRE.category = 'EMPLOYEE'
        AND    (JRRE.attribute14 = PAAF.ass_attribute10 AND JRRE.attribute15 = PAAF.ass_attribute9)
       );


PROMPT
PROMPT Script - Bonus Eligibility Date validation
PROMPT


SELECT *
FROM apps.per_all_assignments_f PAAF
START WITH PAAF.person_id = &P_ID
CONNECT BY PRIOR PAAF.person_id = PAAF.supervisor_id
AND EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_roles_b JRRB
             , apps.jtf_rs_job_roles JRJR
        WHERE  JRJR.job_id = PAAF.job_id
        AND    JRJR.role_id = JRRB.role_id
        AND    JRRB.role_type_code IN ('SALES','SALES_COMP')
       )
AND EXISTS
       (SELECT 1
        FROM   apps.jtf_rs_resource_extns JRRE
        WHERE  JRRE.source_id = PAAF.person_id
        AND    JRRE.category = 'EMPLOYEE'
        AND EXISTS
              (SELECT 1
               FROM apps.jtf_rs_role_relations JRRR
               WHERE JRRR.role_resource_id = JRRE.resource_id
               AND JRRR.attribute15 = DECODE((TO_DATE(&P_DATE,'DD-MON-YYYY') - PAAF.effective_start_date) < 0, 
                                     JRRR.effective_start_date,  
                                     TO_DATE('01-'||TO_CHAR(ADD_MONTHS(TO_DATE(&P_DATE,'DD-MON-YYYY'))+3),'MON-YYYY')
              )
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

