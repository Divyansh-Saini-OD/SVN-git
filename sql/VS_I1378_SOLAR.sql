REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : SOLAR Pre Execution Script                                                 |--
--|                                                                                             |--
--| Program Name   : XX_CDH_SOLAR_PRE_VALIDATION.sql                                            |--
--|                                                                                             |--
--| Purpose        : Validating script for the object related to SOLAR conversion               |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              05-May-2008      Jeevan                   Initial                          |--
--| 1.1              05-May-2008      Rizwan Appees            Reviewed and modified.           |--
--| 1.2              08-Aug-2008      Rizwan Appees            Replace SOLAR tables with view.  |--
--+=============================================================================================+--

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for SOLAR Conversion
PROMPT ======================================
PROMPT


Select  'DBA Link: AVENUE.NA.ODCORP.NET  '||
CASE COUNT(1) WHEN 1 THEN 'Exists'ELSE 'Does Not Exists' End
from dba_db_links where db_link = 'AVENUE.NA.ODCORP.NET';

PROMPT ----------------------------------------------------------------------------

Select 'View: SITE_ORA_V '||
CASE  WHEN COUNT(1) > 0 THEN 'Exists in SOLAR DB'ELSE 'Does Not Exists in SOLAR' End
from SITE_ORA_V@AVENUE;

PROMPT ----------------------------------------------------------------------------

Select 'View: DISTRICT_ORA_V '||
CASE  WHEN COUNT(1) > 0 THEN 'Exists in SOLAR DB'ELSE 'Does Not Exists in SOLAR' End
from district_ora_v@avenue;

PROMPT ----------------------------------------------------------------------------

Select 'View: CONTACT_ORA_V '||
CASE  WHEN COUNT(1) > 0 THEN 'Exists in SOLAR DB'ELSE 'Does Not Exists in SOLAR' End
from contact_ora_v@AVENUE;

PROMPT ----------------------------------------------------------------------------

Select 'View: TODO_ORA_V '||
CASE  WHEN COUNT(1) > 0 THEN 'Exists in SOLAR DB'ELSE 'Does Not Exists in SOLAR' End
from todo_ora_v@avenue;

PROMPT ----------------------------------------------------------------------------

Select 'View: NOTE_ORA_V '||
CASE  WHEN COUNT(1) > 0 THEN 'Exists in SOLAR DB'ELSE 'Does Not Exists in SOLAR' End
from NOTE_ORA_V@AVENUE;

PROMPT ----------------------------------------------------------------------------

Select 'View: ACTRPT_ORA_V '||
CASE  WHEN COUNT(1) > 0 THEN 'Exists in SOLAR DB'ELSE 'Does Not Exists in SOLAR' End
from actrpt_ora_v@AVENUE;

PROMPT ----------------------------------------------------------------------------

Select 'View: SHIPTO_ASSIGN_ORA_V '||
CASE  WHEN COUNT(1) > 0 THEN 'Exists in SOLAR DB'ELSE 'Does Not Exists in SOLAR' End
from shipto_assign_ora_v@avenue;

PROMPT ----------------------------------------------------------------------------

SELECT 'Table: XXTPS_SP_MAPPING '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_tables ALT
WHERE ALT.table_name  = 'XXTPS_SP_MAPPING'
AND   ALT.owner       = 'XXTPS';

PROMPT ----------------------------------------------------------------------------

SELECT 'Table: XX_JTF_TERRITORIES_INT '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_tables ALT
WHERE ALT.table_name  = 'XX_JTF_TERRITORIES_INT'
AND   ALT.owner       = 'XXCRM';

PROMPT ----------------------------------------------------------------------------

select 'Data: Records in the table XXTPS_SP_MAPPING '||CASE  WHEN COUNT(1) > 0 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
from APPS.XXTPS_SP_MAPPING;

PROMPT ----------------------------------------------------------------------------

Select 'The Source Code called SOLAR '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                 END
from HZ_ORIG_SYSTEMS_vl
where orig_system_name = 'SOLAR';

PROMPT ----------------------------------------------------------------------------

SELECT 'Sequence: XX_JTF_RECORD_ID_INT_S '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                             ELSE 'Does Not Exists'
                                               END
FROM  all_sequences ALS
WHERE ALS.sequence_name  = 'XX_JTF_RECORD_ID_INT_S'
AND   ALS.sequence_owner = 'XXCRM';

PROMPT ----------------------------------------------------------------------------

SELECT 'Synonym: XXTPS_SP_MAPPING '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXTPS_SP_MAPPING'
AND   ALS.owner = 'APPS'; 

PROMPT ----------------------------------------------------------------------------

SELECT 'Synonym: XX_JTF_TERRITORIES_INT '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_TERRITORIES_INT'
AND   ALS.owner = 'APPS';

PROMPT ----------------------------------------------------------------------------

SELECT 'Synonym: XX_JTF_RECORD_ID_INT_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_RECORD_ID_INT_S'
AND   ALS.owner = 'APPS'; 


PROMPT ----------------------------------------------------------------------------

SELECT 'Package Specification: XX_JTF_RS_NAMED_ACC_TERR_PUB.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_RS_NAMED_ACC_TERR_PUB'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 


SELECT 'Package Body: XX_JTF_RS_NAMED_ACC_TERR_PUB.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_RS_NAMED_ACC_TERR_PUB'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS'; 

PROMPT ----------------------------------------------------------------------------

SELECT 'Package Specification: XX_JTF_NOTES_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_RS_NAMED_ACC_TERR_PUB'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'Package Body: XX_JTF_NOTES_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_NOTES_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

PROMPT ----------------------------------------------------------------------------

SELECT 'Package Specification: XX_JTF_TASKS_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_SFA_LEADS_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'Package Body: XX_JTF_TASKS_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_TASKS_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

PROMPT ----------------------------------------------------------------------------

SELECT 'Package Specification: XX_SFA_LEADS_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_SFA_LEADS_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'Package Body: XX_SFA_LEADS_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_SFA_LEADS_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';


PROMPT ----------------------------------------------------------------------------

SELECT 'Lookup: XX_CRM_REV_BAND_TYPES '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'XX_CRM_REV_BAND_TYPES';

SELECT 'ROWNUM','SOLAR', 'ORACLE'
FROM DUAL
UNION ALL
SELECT TO_CHAR(ROWNUM),LOOKUP_CODE SOLAR, DESCRIPTION ORACLE
FROM  fnd_lookup_values FLT
WHERE FLT.lookup_type = 'XX_CRM_REV_BAND_TYPES'
AND ENABLED_FLAG = 'Y'
AND END_DATE_ACTIVE IS NULL;

PROMPT ----------------------------------------------------------------------------

SELECT 'Lookup: XX_CDH_SOLAR_ACTIVITY_STATUS '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'XX_CDH_SOLAR_ACTIVITY_STATUS';

SELECT 'ROWNUM','SOLAR', 'ORACLE'
FROM DUAL
UNION ALL
SELECT TO_CHAR(ROWNUM),Meaning SOLAR, DESCRIPTION ORACLE
FROM  fnd_lookup_values FLT
WHERE FLT.lookup_type = 'XX_CDH_SOLAR_ACTIVITY_STATUS'
AND ENABLED_FLAG = 'Y'
AND END_DATE_ACTIVE IS NULL;

PROMPT ----------------------------------------------------------------------------

SELECT 'Lookup: XX_CDH_SOLAR_ACTIVITY_SUBJECTS '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'XX_CDH_SOLAR_ACTIVITY_SUBJECTS';

SELECT 'ROWNUM','SOLAR', 'ORACLE'
FROM DUAL
UNION ALL
SELECT TO_CHAR(ROWNUM),Lookup_Code SOLAR, DESCRIPTION ORACLE
FROM  fnd_lookup_values FLT
WHERE FLT.lookup_type = 'XX_CDH_SOLAR_ACTIVITY_SUBJECTS'
AND ENABLED_FLAG = 'Y'
AND END_DATE_ACTIVE IS NULL;

PROMPT ----------------------------------------------------------------------------

SELECT 'Lookup: XX_CDH_SOLAR_ACTIVITY_TYPES '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'XX_CDH_SOLAR_ACTIVITY_TYPES';

SELECT 'ROWNUM','SOLAR', 'ORACLE'
FROM DUAL
UNION ALL
SELECT TO_CHAR(ROWNUM),Lookup_Code SOLAR, DESCRIPTION ORACLE
FROM  fnd_lookup_values FLT
WHERE FLT.lookup_type = 'XX_CDH_SOLAR_ACTIVITY_TYPES'
AND ENABLED_FLAG = 'Y'
AND END_DATE_ACTIVE IS NULL;

PROMPT ----------------------------------------------------------------------------

SELECT 'Lookup: 1987 SIC '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = '1987 SIC';

PROMPT ----------------------------------------------------------------------------

SELECT 'Lookup: CONTACT_TITLE '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'CONTACT_TITLE';

SELECT 'ROWNUM','SOLAR', 'ORACLE'
FROM DUAL
UNION ALL
SELECT TO_CHAR(ROWNUM),Lookup_Code SOLAR, Meaning ORACLE
FROM  fnd_lookup_values FLT
WHERE FLT.lookup_type = 'CONTACT_TITLE'
AND ENABLED_FLAG = 'Y'
AND END_DATE_ACTIVE IS NULL
AND LOOKUP_CODE IN ('REV.','SGT.','SIR');

PROMPT ----------------------------------------------------------------------------

Select 'Source System called SOLAR '||CASE COUNT(1) WHEN 1 THEN 'Exists in the lookup_type SOURCE_SYSTEM'
                                                        ELSE 'Does Not Exists in the lookup_type SOURCE_SYSTEM' 
                                                        END
from apps.fnd_lookup_values
where lookup_type = 'SOURCE_SYSTEM'
and lookup_code = 'SOLAR';

PROMPT ----------------------------------------------------------------------------

Select 'Product Category called SUPPLIES in MTL_CATEGORIES_TL table  '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists' 
                                                        END 
from MTL_CATEGORIES_TL 
where description = 'SUPPLIES';

PROMPT ----------------------------------------------------------------------------

Select 'Sales Channel called UNASSIGNED '||CASE COUNT(1) WHEN 1 THEN 'Exists in the lookup_type SALES_CHANNEL'
                                                        ELSE 'Does Not Exists in the lookup_type SALES_CHANNEL' 
                                                        END
from fnd_lookup_values 
where lookup_type = 'SALES_CHANNEL' 
and upper(meaning) = 'UNASSIGNED';

PROMPT ----------------------------------------------------------------------------

Select 'The Campaign data '||CASE WHEN COUNT(1) >0 THEN 'Exists'
                                                        ELSE 'Does Not Exists' 
                                                        END
from 
ams_campaigns_v;

SELECT 'The Campaign data with code  '||CASE  WHEN COUNT(1) >0 THEN 'Exists'
                                                                                   ELSE 'Does Not Exists'
                                                                     END
from ams_source_codes a,ams_campaigns_v b
where a.source_code_id (+) = b.campaign_id;

SELECT 'ROWNUM','Campaign Name', 'Source Code ID','Campaign ID'
FROM DUAL
UNION ALL
SELECT TO_CHAR(ROWNUM), Campaign_name, to_char(source_code_id), to_char(campaign_id)
from ams_source_codes a,ams_campaigns_v b
where a.source_code_id (+) = b.campaign_id
AND b.status_code = 'ACTIVE'
AND TRUNC(SYSDATE) BETWEEN b.actual_exec_start_date
AND b.actual_exec_end_date;

PROMPT ----------------------------------------------------------------------------

Select 'The concurrent program OD: JTF Notes Creation Program  '||CASE COUNT(1) WHEN 1 THEN 'Exists'ELSE 'Does Not Exists' End
from FND_CONCURRENT_PROGRAMS
where concurrent_program_name = 'XXNOTESTOCDH'
and enabled_flag = 'Y';

PROMPT ----------------------------------------------------------------------------

Select 'The concurrent program OD: JTF Tasks Creation Program  '||
CASE COUNT(1) WHEN 1 THEN 'Exists'ELSE 'Does Not Exists' End
from FND_CONCURRENT_PROGRAMS
where concurrent_program_name = 'XXTASKSTOCDH'
and enabled_flag = 'Y';

PROMPT ----------------------------------------------------------------------------

Select 'The concurrent program OD: SFA Import Sales Leads Inbound  '||CASE COUNT(1) WHEN 1 THEN 'Exists'ELSE 'Does Not Exists' End
from FND_CONCURRENT_PROGRAMS
where concurrent_program_name = 'XXSFALEADSINT'
and enabled_flag = 'Y';

PROMPT ----------------------------------------------------------------------------

Select 'The Competitor party for Supplies product code '||CASE  WHEN COUNT(1) >0 THEN 'Exists'ELSE 'Does Not Exists' End
from AMS_COMPETITOR_PRODUCTS_VL A
     ,HZ_PARTIES B
where b.party_id = a.competitor_party_id  
and a.competitor_product_code = 'SUPPLIES';

SELECT 'ROWNUM','PARTY NAME'
FROM DUAL
UNION ALL
Select TO_CHAR(ROWNUM), Party_Name
from AMS_COMPETITOR_PRODUCTS_VL A
     ,HZ_PARTIES B
where b.party_id = a.competitor_party_id  
and a.competitor_product_code = 'SUPPLIES';

PROMPT ----------------------------------------------------------------------------
