

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;



CREATE OR REPLACE
PACKAGE BODY XX_CRM_CPD_DEPLOYMENT_CHK_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_UTILITY_PKG.pkb                               |
-- | Description :  DBI Package Contains Common Utilities              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0        28-JAN-2011 Renupriya         Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS

PROCEDURE object_validate (
         x_errbuf       OUT NOCOPY VARCHAR2,
         x_retcode      OUT NOCOPY VARCHAR2
   )
AS
l_message              VARCHAR2(100);
BEGIN

fnd_file.put_line(fnd_file.output,'<html><body><table border=1>');


-- start of tables 

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> TABLES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
       END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXBI_OD_STORE_NUM_DIM_MV' AND STATUS = 'VALID'; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OD_STORE_NUM_DIM_MV </TD><TD>' || l_message || '</TD></TR>');

-- end of tables 

-- start of Alter table columns

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> ALTER TABLES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) WHEN 53 THEN 'Exists'
                      ELSE 'Does Not Exist'
                      END
INTO l_message 
FROM ALL_TAB_COLUMNS
WHERE table_name = 'XX_SFA_LEAD_REFERRALS'; 

fnd_file.put_line(fnd_file.output,'<TR><TD>  ALTER_XX_SFA_LEAD_REFERRALS.tbl </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 64 THEN 'Exists'
                      ELSE 'Does Not Exist'
                      END
INTO l_message 
FROM ALL_TAB_COLUMNS
WHERE table_name = 'XXBI_SALES_LEADS_FCT_MV'; 

fnd_file.put_line(fnd_file.output,'<TR><TD>  ALTER_XXBI_SALES_LEADS_FCT_MV.tbl </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 12 THEN 'Exists'
                      ELSE 'Does Not Exist'
                      END
INTO l_message 
FROM ALL_TAB_COLUMNS
WHERE table_name = 'XXBI_SLS_LDS_SMRY_MV'; 

fnd_file.put_line(fnd_file.output,'<TR><TD>  ALTER_XXBI_SLS_LDS_SMRY_MV.tbl </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 76 THEN 'Exists'
                      ELSE 'Does Not Exist'
                      END
INTO l_message 
FROM ALL_TAB_COLUMNS
WHERE table_name = 'XXBI_SALES_OPPTY_FCT_MV'; 

fnd_file.put_line(fnd_file.output,'<TR><TD>  ALTER_XXBI_SALES_OPPTY_FCT_MV.tbl </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 21 THEN 'Exists'
                      ELSE 'Does Not Exist'
                      END
INTO l_message 
FROM ALL_TAB_COLUMNS
WHERE table_name = 'XXBI_SLS_OPP_SMRY_MV'; 

fnd_file.put_line(fnd_file.output,'<TR><TD>  ALTER_XXBI_SLS_OPP_SMRY_MV.tbl </TD><TD>' || l_message || '</TD></TR>');

-- Start of views 

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> VIEWS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');
SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_OPP_CREATED_BY_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPP_CREATED_BY_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_OPP_LINE_COMPTTR_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPP_LINE_COMPTTR_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_OPP_NAMES_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPP_NAMES_DIM_V </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_OPP_NUMBER_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPP_NUMBER_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_OPP_ORG_NAMES_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPP_ORG_NAMES_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_OPP_ORG_NUMBERS_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPP_ORG_NUMBERS_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_OPPTY_PROD_CAT_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPPTY_PROD_CAT_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_SALES_LEADS_FCT_V';

fnd_file.put_line(fnd_file.output,'<TR><TD>  XXBI_SALES_LEADS_FCT_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_SALES_OPPTY_FCT_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_OPPTY_FCT_V </TD><TD>' || l_message || '</TD></TR>');




SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_SLS_LDS_SMRY_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SLS_LDS_SMRY_V </TD><TD>' || l_message || '</TD></TR>');




SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_SLS_OPP_SMRY_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SLS_OPP_SMRY_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_STORE_NUM_DIM_OPP_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_STORE_NUM_DIM_OPP_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_STORE_NUM_DIM_LEAD_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_STORE_NUM_DIM_LEAD_V </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XX_CRM_SOURCE_PROMOTION_ID_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XX_CRM_SOURCE_PROMOTION_ID_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
                     END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CS_POTENTIAL_ALL_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POTENTIAL_ALL_V </TD><TD>' || l_message || '</TD></TR>');

-- end of views 

-- start of profile options

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> PROFILE OPTIONS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT  CASE COUNT(1) WHEN 1 THEN 'Exists'
        ELSE 'Does Not Exist'
        END INTO l_message
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_LDREF_ALT_EMAIL';

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_LDREF_ALT_EMAIL </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
        ELSE 'Does Not Exist'
       END INTO l_message
                            
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_LDREF_DEF_EMAIL';

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_LDREF_DEF_EMAIL </TD><TD>' || l_message || '</TD></TR>');

-- end of profile options

-- Start of value sets

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> VALUE SETS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END INTO l_message
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_CRM_LEAD_STATUS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_CRM_LEAD_STATUS </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END INTO l_message
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_CRM_LEAD_STATUS_CATEGORY';

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_CRM_LEAD_STATUS_CATEGORY </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END INTO l_message
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_CRM_LEAD_SOURCE';

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_CRM_LEAD_SOURCE </TD><TD>' || l_message || '</TD></TR>');


-- end of value sets

-- Start of custom packages

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> CUSTOM PACKAGES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT  CASE COUNT(1) WHEN 1 THEN 'Exists'                                        
        ELSE 'Does Not Exist'
        END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_CRM_SFA_LEAD_REP'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_CRM_SFA_LEAD_REP.PKS </TD><TD>' || l_message || '</TD></TR>');

SELECT  CASE COUNT(1) WHEN 1 THEN 'Exists'
        ELSE 'Does Not Exist'
        END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_CRM_SFA_LEAD_REP'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_CRM_SFA_LEAD_REP.PKB </TD><TD>' || l_message || '</TD></TR>');

SELECT  CASE COUNT(1) WHEN 1 THEN 'Exists'
        ELSE 'Does Not Exist'
        END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_SFA_LEAD_REFF_CREATE_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_SFA_LEAD_REFF_CREATE_PKG.PKS </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
        ELSE 'Does Not Exist'
        END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_SFA_LEAD_REFF_CREATE_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_SFA_LEAD_REFF_CREATE_PKG.PKB </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
        ELSE 'Does Not Exist'
        END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_CRM_HRCRM_CM_SYNC_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_CRM_HRCRM_CM_SYNC_PKG.PKB </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
        ELSE 'Does Not Exist'
        END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_SFA_OPPTY_RPT_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_SFA_OPPTY_RPT_PKG.PKS </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
        ELSE 'Does Not Exist'
        END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_SFA_OPPTY_RPT_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_SFA_OPPTY_RPT_PKG.PKB </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
        ELSE 'Does Not Exist'
        END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXBI_ACTIVITY_DT_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_ACTIVITY_DT_PKG.PKB </TD><TD>' || l_message || '</TD></TR>');


-- end of custom packages

-- start of conc programs

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> CONCURRENT PROGRAMS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT         CASE COUNT(1) WHEN 1 THEN 'Exists'
               ELSE 'Does Not Exist'
               END INTO l_message
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XX_CRM_SFA_LEAD_REP_LEAD_REP'
AND   FCP.enabled_flag = 'Y';

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_CRM_SFA_LEAD_REP_LEAD_REP </TD><TD>' || l_message || '</TD></TR>');

 
SELECT         CASE COUNT(1) WHEN 1 THEN 'Exists' 
               ELSE 'Does Not Exist'
               END INTO l_message
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XX_CRM_SFA_LEAD_REP_LEAD_REP'
AND   FCP.enabled_flag = 'Y';

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_CRM_SFA_LEAD_REP_LEAD_REP </TD><TD>' || l_message || '</TD></TR>');

SELECT         CASE COUNT(1) WHEN 1 THEN 'Exists'
               ELSE 'Does Not Exist'
               END INTO l_message
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXSFALEADREFPROCESS'
AND   FCP.enabled_flag = 'Y';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSFALEADREFPROCESS </TD><TD>' || l_message || '</TD></TR>');


SELECT         CASE COUNT(1) WHEN 1 THEN 'Exists'
               ELSE 'Does Not Exist'
               END INTO l_message
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXCRMEMAILER'
AND   FCP.enabled_flag = 'Y';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXCRMEMAILER </TD><TD>' || l_message || '</TD></TR>');

-- end of conc programs

-- start of synonyms

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> SYNONYMS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXBI_SALES_LEADS_FCT_MV'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD>  XXBI_SALES_LEADS_FCT_MV synonym </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXBI_SALES_OPPTY_FCT_MV'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_OPPTY_FCT_MV synonym </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXBI_SLS_LDS_SMRY_MV'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SLS_LDS_SMRY_MV synonym </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXBI_SLS_OPP_SMRY_MV'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD>  XXBI_SLS_OPP_SMRY_MV synonym </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXBI_OD_STORE_NUM_DIM_MV'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD>  XXBI_OD_STORE_NUM_DIM_MV synonym </TD><TD>' || l_message || '</TD></TR>');

-- end of synonyms

-- start of grant

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> GRANT PRIVILEGES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) 
       WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END
INTO l_message
FROM  dba_tab_privs  PRIV
WHERE PRIV.table_name = 'XXBI_OD_STORE_NUM_DIM_MV'
AND PRIV.grantee = 'XXCRM_LEADS'
AND PRIV.privilege = 'SELECT';

fnd_file.put_line(fnd_file.output,'<TR><TD> Grant on  XXBI_OD_STORE_NUM_DIM_MV to XXCRM_LEADS </TD><TD>' || l_message || '</TD></TR>');

-- end of grant

-- start of messages

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> MESSAGES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) 
       WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END
INTO l_message
FROM fnd_new_messages FMSG
where FMSG.message_name = 'XXOD_LDRF_ESUB';

fnd_file.put_line(fnd_file.output,'<TR><TD>  XXOD_LDRF_ESUB </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) 
       WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END
INTO l_message
FROM fnd_new_messages FMSG
where FMSG.message_name = 'XXOD_LDRF_ETXT';

fnd_file.put_line(fnd_file.output,'<TR><TD>  XXOD_LDRF_ETXT </TD><TD>' || l_message || '</TD></TR>');

-- end of messages

-- start of Store Lead Set up
fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> Store Lead Setup </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) 
       WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END
INTO l_message
FROM  AMS_SOURCE_CODES SOC
,AMS_CAMPAIGNS_ALL_TL CAMPT
,AMS_CAMPAIGNS_ALL_B CAMPB
WHERE SOC.arc_source_code_for   = 'CAMP'
AND   SOC.active_flag           = 'Y'
AND   SOC.source_code_for_id    = campb.campaign_id
AND   CAMPB.campaign_id         = campt.campaign_id
AND   CAMPB.status_code        IN('ACTIVE', 'COMPLETED')
AND   CAMPT.LANGUAGE            = userenv('LANG')
AND   CAMPT.campaign_name       = 'Store Lead';

fnd_file.put_line(fnd_file.output,'<TR><TD>  Store Lead Setup </TD><TD>' || l_message || '</TD></TR>');

-- end of store lead set up
-- start of FIN Trans Set up
fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> FIN Translation Setup </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');


SELECT CASE COUNT(1) 
       WHEN 4 THEN 'Exists'
       ELSE 'Does Not Exist'
       END 
INTO l_message
FROM 
       xx_fin_translatedefinition DEF
      ,xx_fin_translatevalues VAL
where DEF.translation_name='XXBI_ACTIVITY_DATES'
and DEF.translate_id=VAL.translate_id
and VAL.source_value1 IN ('OPPORTUNITY','LEADS')
and VAL.source_value2 IN ('ATTACHMENTS','STAGE','STAGE_STEPS');

fnd_file.put_line(fnd_file.output,'<TR><TD>  Set up for XXBI_ACTIVITY_DATES </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) 
       WHEN 1 THEN 'Exists'
       ELSE 'Does Not Exist'
       END 
INTO l_message
FROM 
 apps.XX_FIN_TRANSLATEDEFINITION DEF
,apps.XX_FIN_TRANSLATEVALUES VAL
where DEF.translation_name='XXBI_MATERIALIZED_VIEWS'
and DEF.translate_id=VAL.translate_id
and source_value1 = 'LEAD_FCT'
and target_value2 = 'XXCRM.XXBI_OD_STORE_NUM_DIM_MV';

fnd_file.put_line(fnd_file.output,'<TR><TD>  Set up for XXBI_MATERIALIZED_VIEWS </TD><TD>' || l_message || '</TD></TR>');

-- end of fin trans set up
EXCEPTION WHEN OTHERS THEN
  x_errbuf    := 'Unexpected Error in proecedure object_validate - Error - '||SQLERRM;
  x_retcode   := 2;
END object_validate;
END XX_CRM_CPD_DEPLOYMENT_CHK_PKG;

/
SHOW ERRORS;

