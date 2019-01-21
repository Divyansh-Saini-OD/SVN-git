REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : E1002_HR_CRM_Synchronization                                               |--
--|                                                                                             |--
--| Program Name   : XX_HR_CRM_SYNC.sql                                                         |--        
--|                                                                                             |--   
--| Purpose        : Validating script for the object E1002_HR_CRM_Synchronization              |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              24-Dec-2007      Abhradip Ghosh           Original                         |--
--| 1.1              24-Jan-2008      Gowri Nagarajan          Changed the                      |-- 
--|                                                            a)Descriptive_flex_context_code  |--
--|                                                              from SALES_COMP to             |--
--|                                                              Global Data Elements           |--
--|                                                            b)Application_column_name        |--
--|                                                            from ATTRIBUTE15 to ATTRIBUTE14  |--
--|                                                            of Resource, Group, Team and     |--
--|                                                            Roles Additional Information DFF |--
--|                                                            c)Added lookpup type values      |--
--|                                                              check of OD_OPERATING_UNIT     |--
--| 1.2              13-Mar-2008     Abhradip Ghosh            Updated with the latest files    |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for E1002_HR_CRM_Synchronization....
PROMPT

PROMPT
PROMPT
PROMPT Validating whether the required value sets are present....
PROMPT

SELECT 'The value set XX_CRM_HRCRM_PERSON '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_CRM_HRCRM_PERSON';

PROMPT
PROMPT
PROMPT Validating whether the required profiles are present....
PROMPT

SELECT 'The profile OD: HRCRM Synchronization debug flag '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                          ELSE 'Does Not Exists'
                                                            END
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_HRCRM_SYNC_DEBUG';

SELECT 'The profile OD: CRM Go Live Date DD-MON-YYYY (Release 1) '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                  ELSE 'Does Not Exists'
                                                                    END
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_CRM_GO_LIVE_DATE_R1';

PROMPT
PROMPT
PROMPT Validating whether the required lookups are present....
PROMPT

SELECT 'The lookup OD_OPERATING_UNIT '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'OD_OPERATING_UNIT';

PROMPT
PROMPT
PROMPT Validating whether the required lookup values are present....
PROMPT

SELECT 'The lookup OD_OPERATING_UNIT values '||CASE COUNT(1) WHEN 2 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM   fnd_lookup_values FLV
       WHERE  FLV.lookup_type = 'OD_OPERATING_UNIT'
       AND    FLV.end_date_active IS NULL
       AND    FLV.enabled_flag = 'Y'
       AND    FLV.lookup_code IN (SELECT name
                                  FROM  hr_operating_units HOU
                                  WHERE HOU.date_to IS NULL
                                  );

PROMPT
PROMPT
PROMPT Validating whether the mandatory groups are present....
PROMPT

SELECT 'The group OD_SALES_ADMIN_GRP '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  jtf_rs_groups_vl JRG
WHERE JRG.group_name = 'OD_SALES_ADMIN_GRP';

SELECT 'The group OD_PAYMENT_ANALYST_GRP '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  jtf_rs_groups_vl JRG
WHERE JRG.group_name = 'OD_PAYMENT_ANALYST_GRP';

SELECT 'The group OD_SUPPORT_GRP '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                  ELSE 'Does Not Exists'
                                    END
FROM  jtf_rs_groups_vl JRG
WHERE JRG.group_name = 'OD_SUPPORT_GRP';

PROMPT
PROMPT
PROMPT Validating whether the sales credit type is present....
PROMPT

SELECT 'The sales credit type Quota Sales Credit '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                  ELSE 'Does Not Exists'
                                                    END
FROM  oe_sales_credit_types OSC
WHERE OSC.name = 'Quota Sales Credit'
AND   OSC.enabled_flag = 'Y';

PROMPT
PROMPT
PROMPT Validating whether the flexfield Additional Assignment Details is present....
PROMPT

SELECT 'The descriptive flexfield Additional Assignment Details '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                 ELSE 'Does Not Exists'
                                                                   END
FROM  fnd_descriptive_flexs FDF
WHERE FDF.application_table_name = 'PER_ALL_ASSIGNMENTS_F'
AND   FDF.descriptive_flexfield_name = 'PER_ASSIGNMENTS';

PROMPT
PROMPT Validating whether the context code Global Data Elements for the above flexfield is present....

SELECT 'The context code Global Data Elements '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exists'
                                                 END
FROM  fnd_descr_flex_contexts FDF
WHERE FDF.descriptive_flexfield_name = 'PER_ASSIGNMENTS'
AND   FDF.descriptive_flex_context_code = 'Global Data Elements'
AND   FDF.enabled_flag = 'Y';

PROMPT
PROMPT Validating whether segment Job Effective Date for the above context code is present....

SELECT 'The segment Job Effective Date '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  fnd_descr_flex_column_usages FDF
WHERE FDF.descriptive_flexfield_name = 'PER_ASSIGNMENTS'
AND   FDF.descriptive_flex_context_code = 'Global Data Elements'
AND   FDF.application_column_name = 'ASS_ATTRIBUTE9'
AND   FDF.enabled_flag = 'Y';

PROMPT
PROMPT Validating whether segment Job Entry Date for the above context code is present....

SELECT 'The segment Job Entry Date '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  fnd_descr_flex_column_usages FDF
WHERE FDF.descriptive_flexfield_name = 'PER_ASSIGNMENTS'
AND   FDF.descriptive_flex_context_code = 'Global Data Elements'
AND   FDF.application_column_name = 'ASS_ATTRIBUTE10'
AND   FDF.enabled_flag = 'Y';

PROMPT
PROMPT
PROMPT Validating whether the flexfield CRM Specific Resources Additional Information is present....
PROMPT

SELECT 'The descriptive flexfield CRM Specific Resources Additional Information '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                 ELSE 'Does Not Exists'
                                                                   END
FROM  fnd_descriptive_flexs FDF
WHERE FDF.application_table_name = 'JTF_RS_RESOURCE_EXTNS'
AND   FDF.descriptive_flexfield_name = 'JTF_RS_RESOURCE_EXTNS';

PROMPT
PROMPT Validating whether the context code Global Data Elements for the above flexfield is present....

SELECT 'The context code Global Data Elements '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exists'
                                                 END
FROM  fnd_descr_flex_contexts FDF
WHERE FDF.descriptive_flexfield_name = 'JTF_RS_RESOURCE_EXTNS'
AND   FDF.descriptive_flex_context_code = 'Global Data Elements'
AND   FDF.enabled_flag = 'Y';

PROMPT
PROMPT Validating whether segment Job Code Effectivity Date for the above context code is present....

SELECT 'The segment Job Code Effectivity Date '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  fnd_descr_flex_column_usages FDF
WHERE FDF.descriptive_flexfield_name = 'JTF_RS_RESOURCE_EXTNS'
AND   FDF.descriptive_flex_context_code = 'Global Data Elements'
AND   FDF.application_column_name = 'ATTRIBUTE14'
AND   FDF.enabled_flag = 'Y';

PROMPT
PROMPT Validating whether segment Supervisor Effectivity Date for the above context code is present....

SELECT 'The segment Supervisor Effectivity Date '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  fnd_descr_flex_column_usages FDF
WHERE FDF.descriptive_flexfield_name = 'JTF_RS_RESOURCE_EXTNS'
AND   FDF.descriptive_flex_context_code = 'Global Data Elements'
AND   FDF.application_column_name = 'ATTRIBUTE15'
AND   FDF.enabled_flag = 'Y';

PROMPT
PROMPT
PROMPT Validating whether the flexfield Resource, Group, Team and Roles Additional Information is present....
PROMPT

SELECT 'The descriptive flexfield Resource, Group, Team and Roles Additional Information '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                                          ELSE 'Does Not Exists'
                                                                                            END
FROM  fnd_descriptive_flexs FDF
WHERE FDF.application_table_name = 'JTF_RS_ROLE_RELATIONS'
AND   FDF.descriptive_flexfield_name = 'JTF_RS_ROLE_RELATIONS';


--PROMPT
--PROMPT Validating whether the context code Sales Compensation for the above flexfield is present....

--SELECT 'The context code Sales Compensation '||CASE COUNT(1) WHEN 1 THEN 'Exists'
--                                                             ELSE 'Does Not Exists'
--                                               END

PROMPT
PROMPT Validating whether the context code Global Data Elements for the above flexfield is present....

SELECT 'The context code Global Data Elements '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                             ELSE 'Does Not Exists'
                                                 END
FROM  fnd_descr_flex_contexts FDF
WHERE FDF.descriptive_flexfield_name = 'JTF_RS_ROLE_RELATIONS'
--AND   FDF.descriptive_flex_context_code = 'SALES_COMP'
AND   FDF.descriptive_flex_context_code = 'Global Data Elements'
AND   FDF.enabled_flag = 'Y';

PROMPT
PROMPT Validating whether segment Bonus_Eligibilty_Date for the above context code is present....

SELECT 'The segment Bonus_Eligibility_Date '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exists'
                                             END
FROM  fnd_descr_flex_column_usages FDF
WHERE FDF.descriptive_flexfield_name = 'JTF_RS_ROLE_RELATIONS'
--AND   FDF.descriptive_flex_context_code = 'SALES_COMP'
AND   FDF.descriptive_flex_context_code = 'Global Data Elements'
--AND   FDF.application_column_name = 'ATTRIBUTE15'
AND   FDF.application_column_name = 'ATTRIBUTE14'
AND   FDF.enabled_flag = 'Y';

PROMPT
PROMPT
PROMPT Validating whether the custom packages are compiled in database....
PROMPT

SELECT 'The package specification XX_CRM_HRCRM_SYNC_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_CRM_HRCRM_SYNC_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'The package body XX_CRM_HRCRM_SYNC_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_CRM_HRCRM_SYNC_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_RS_ROLE_RELATE_PUB.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_RS_ROLE_RELATE_PUB'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'The package body XX_JTF_RS_ROLE_RELATE_PUB.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_RS_ROLE_RELATE_PUB'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_RS_GRP_MEMBERSHIP_PUB.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_RS_GRP_MEMBERSHIP_PUB'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'The package body XX_JTF_RS_GRP_MEMBERSHIP_PUB.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_RS_GRP_MEMBERSHIP_PUB'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS';

PROMPT
PROMPT
PROMPT Validating whether the required concurrent programs are present....
PROMPT

SELECT 'The concurrent program OD: CRM HR Synchronization Program '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                    ELSE 'Does Not Exists'
                                                                      END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXCRMHRCRMCONV'
AND   FCP.enabled_flag = 'Y';

PROMPT
PROMPT
PROMPT Validating whether at least one VP role exists ....
PROMPT

SELECT 'The role VP '||
                       CASE COUNT(1) WHEN 0 THEN 'Does Not Exists'
                                     ELSE 'Exists'
                       END
FROM   jtf_rs_roles_b_dfv JRRBD
      ,jtf_rs_roles_b JRRB 
WHERE  JRRBD.od_role_code        = 'VP'
AND    JRRBD.row_id              = JRRB.rowid
AND    NVL(JRRB.active_flag,'N') = 'Y'; 

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
