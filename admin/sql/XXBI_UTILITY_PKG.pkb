-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;



CREATE OR REPLACE
PACKAGE BODY XXBI_UTILITY_PKG
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
-- |1.0       17-Mar-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS

FUNCTION get_rsd_user_id(p_user_id IN NUMBER DEFAULT FND_GLOBAL.USER_ID) RETURN NUMBER IS
  l_rsd_user_id NUMBER := 0;
  l_rc number :=0;
BEGIN
  SELECT  max(a.rsd_user_id), 
          count(distinct a.rsd_user_id) 
  INTO    l_rsd_user_id,
          l_rc 
  FROM    apps.xxbi_group_mbr_info_mv a 
  WHERE   (a.user_id    = p_user_id or 
           a.m1_user_id = p_user_id or 
           a.m2_user_id = p_user_id or 
           a.m3_user_id = p_user_id or
           a.m4_user_id = p_user_id or
           a.m5_user_id = p_user_id 
          )
    AND   SYSDATE BETWEEN a.start_date_active AND NVL(a.end_date_active, SYSDATE+1);

  IF l_rc >= 1 THEN
    RETURN l_rsd_user_id;
  ELSE 
    RETURN -1 ;  -- (-1) is for catch all partition id
  END IF;
END get_rsd_user_id ;

FUNCTION check_active_res_role_grp(p_user_id     IN NUMBER DEFAULT FND_GLOBAL.USER_ID,
                                   p_resource_id IN NUMBER,
                                   p_role_id     IN NUMBER,
                                   p_group_id    IN NUMBER
                                  ) RETURN VARCHAR2 IS

  ln_count  NUMBER  := 0;
  lc_active CHAR(1) := 'N';

BEGIN
  -- Check if the user is a manager
  SELECT COUNT(1)
  INTO   ln_count
  FROM   apps.xxbi_group_mbr_info_mv
  WHERE  user_id = p_user_id
    AND  NVL(manager_flag, 'N') = 'Y'
    AND  SYSDATE BETWEEN NVL(start_date_active, SYSDATE-1) AND NVL(end_date_active, SYSDATE+1);

  -- If the user is a manager then he needs to see all assignments for the hierarchy (both active/inactive Res/Role/Grp)
  IF ln_count > 0 THEN
    lc_active := 'Y';
  ELSE
    -- Check if the Res/Role/Group is active for the user in case of a sales rep
    SELECT COUNT(1)
    INTO   ln_count
    FROM   apps.xxbi_group_mbr_info_mv
    WHERE  user_id     = p_user_id
      AND  resource_id = p_resource_id
      AND  role_id     = p_role_id
      AND  group_id    = p_group_id
      AND  SYSDATE BETWEEN NVL(start_date_active, SYSDATE-1) AND NVL(end_date_active, SYSDATE+1);

    -- IF active return Y else N
    IF ln_count > 0 THEN
      lc_active := 'Y';
    ELSE
      lc_active := 'N';
    END IF;
  END IF;

  RETURN lc_active;

END check_active_res_role_grp;


  
PROCEDURE refresh_mv (
         p_mv_name          IN  VARCHAR2, -- Materialized View Name
         p_mv_refresh_type  IN  VARCHAR2, -- MV Refresh Type
         x_ret_code         OUT NUMBER,   -- 1 - Error, 0 - Success
         x_error_msg        OUT VARCHAR2  -- Error Message
   )
AS
BEGIN
 IF TRIM(p_mv_name) IS NOT NULL THEN
   DBMS_MVIEW.REFRESH(p_mv_name, p_mv_refresh_type);
   x_ret_code := 0;
 ELSE
   x_ret_code := 1;
   x_error_msg := 'No Materialized View Name Passed';
 END IF; 
EXCEPTION WHEN OTHERS THEN
  x_error_msg := 'Unexpected Error in proecedure refresh_mv - Error - '||SQLERRM;
  x_ret_code   := 1;
END refresh_mv;

PROCEDURE refresh_mv_grp (
         x_errbuf       OUT NOCOPY VARCHAR2,
         x_retcode      OUT NOCOPY VARCHAR2,
         p_mv_grp_name  IN  VARCHAR2
   )
AS
CURSOR mv_cursor (l_mv_grp_name  VARCHAR2) 
IS
SELECT TARGET_VALUE1,TARGET_VALUE2,TARGET_VALUE3,TARGET_VALUE4 
FROM XX_FIN_TRANSLATEDEFINITION DEF,XX_FIN_TRANSLATEVALUES VAL
WHERE DEF.TRANSLATE_ID = VAL.TRANSLATE_ID 
AND TRANSLATION_NAME = 'XXBI_MATERIALIZED_VIEWS'
AND SOURCE_VALUE1 = l_mv_grp_name
ORDER BY TARGET_VALUE1;

l_ret_code        NUMBER;
l_error_msg       VARCHAR2(2000);
l_start_time      DATE;
l_end_time        DATE;
l_time_mins       NUMBER;
BEGIN
FOR mv_cur IN mv_cursor (p_mv_grp_name) LOOP
 IF NVL(mv_cur.target_value3,'N') = 'Y' AND mv_cur.target_value2 IS NOT NULL THEN
    l_start_time := SYSDATE;
    refresh_mv (
        p_mv_name          => mv_cur.target_value2,
        p_mv_refresh_type  => NVL(mv_cur.target_value4,'C'),
        x_ret_code         => l_ret_code,
        x_error_msg        => l_error_msg
      );
     l_end_time  := SYSDATE;  
    IF l_ret_code = 1 THEN
       fnd_file.put_line(fnd_file.log, ' ++++++++++++++++++++++++++++++++++++ Error ++++++++++++++++++++++++++++++++++++');
       fnd_file.put_line(fnd_file.log, 'MV Refresh Failed For  - ' || mv_cur.target_value2);
       fnd_file.put_line(fnd_file.log, 'Error - ' || l_error_msg);
       fnd_file.put_line(fnd_file.log, ' ++++++++++++++++++++++++++++++++++++ Error ++++++++++++++++++++++++++++++++++++');
       x_retcode   := 2;
    ELSE
       fnd_file.put_line(fnd_file.log, 'MV - ' || mv_cur.target_value2 || ' Successfully Refresh in ' || to_char(ROUND((l_end_time - l_start_time) * 24 * 60,2)) || ' Min' );
    END IF;
 ELSE
   fnd_file.put_line(fnd_file.log, 'FIN Trasnalation Setup (XXBI_MATERIALIZED_VIEWS) to Refresh MV : ' || mv_cur.target_value2 || ' Is Not Setup'); 
   x_retcode   := 1;
 END IF;
END LOOP;
COMMIT;
EXCEPTION WHEN OTHERS THEN
  x_errbuf  := 'Unexpected Error in proecedure refresh_mv_grp - Error - '||SQLERRM;
  x_retcode   := 2;
END refresh_mv_grp;

PROCEDURE update_urls (
         x_errbuf       OUT NOCOPY VARCHAR2,
         x_retcode      OUT NOCOPY VARCHAR2,
         p_db_object    IN  VARCHAR2,
         p_find_str     IN  VARCHAR2,
         p_replace_str  IN  VARCHAR2,
         p_commit       IN  VARCHAR2
   )
AS
l_query_str        VARCHAR2(2001);
l_ob_name          VARCHAR2(80);
CURSOR url_cur (p_ob_name  VARCHAR2) IS
SELECT distinct database_object_name
FROM ak_regions
WHERE database_object_name like p_ob_name;
BEGIN
  
    fnd_file.put_line(fnd_file.log,'DBA Objects Updated - ' || p_db_object);
    fnd_file.put_line(fnd_file.log,'Find String - ' || p_find_str);
    fnd_file.put_line(fnd_file.log,'Replace String - ' || p_replace_str);
    
    l_query_str     := p_find_str || '%';
    l_ob_name       := p_db_object || '%';
    
    fnd_file.put_line(fnd_file.log,'~~~~~~~~~ Data Objects Selected For Update ~~~~~~~~~');
    FOR url_c IN url_cur (l_ob_name) LOOP
      fnd_file.put_line(fnd_file.log,url_c.database_object_name);
    END LOOP;
    fnd_file.put_line(fnd_file.log, '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
    
    UPDATE ak_region_items
    SET URL = REPLACE(URL,p_find_str,p_replace_str)
    WHERE REGION_CODE IN (SELECT region_code FROM ak_regions WHERE database_object_name like l_ob_name)
    AND url like l_query_str;
    
    fnd_file.put_line(fnd_file.log,'Total Rows Updated : ' || SQL%ROWCOUNT);
    
    IF p_commit = 'Y' THEN
      COMMIT;
      fnd_file.put_line(fnd_file.log,'All Changes Committed');
    ELSE
      ROLLBACK;
      fnd_file.put_line(fnd_file.log,'All Changes Rolled Back');
    END IF;
    
    
    
EXCEPTION WHEN OTHERS THEN
  x_errbuf    := 'Unexpected Error in proecedure update urls - Error - '||SQLERRM;
  x_retcode   := 2;
END update_urls;

PROCEDURE object_validate (
         x_errbuf       OUT NOCOPY VARCHAR2,
         x_retcode      OUT NOCOPY VARCHAR2
   )
AS
l_message              VARCHAR2(100);
BEGIN

fnd_file.put_line(fnd_file.output,'<html><body><table border=1>');

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> TABLES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                     ELSE 'Does Not Exist'
       END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXSCS_POTENTIAL_STG' AND STATUS = 'VALID'; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_STG </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXSCS_POTENTIAL_REP_STG' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_REP_STG </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXSCS_POTENTIAL_NEW_RANK' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_NEW_RANK </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXBI_SALES_OPPTY_FCT' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_OPPTY_FCT </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXBI_SALES_LEADS_FCT' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_LEADS_FCT </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> SEQUENCES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XXSCS_POTENTIAL_ID_S';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_ID_S </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                   ELSE 'Does Not Exist'
                                                     END
INTO l_message
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XXSCS_POTENTIAL_NEW_RANK_S'; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_NEW_RANK_S </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                ELSE 'Does Not Exist'
                                                  END
INTO l_message
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XXSCS_POTENTIAL_REP_ID_S'; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_REP_ID_S </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                ELSE 'Does Not Exist'
                                                  END
INTO l_message
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XXBI_SALES_OPPTY_FCT_S';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_OPPTY_FCT_S </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                ELSE 'Does Not Exist'
                                                  END
INTO l_message
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XXBI_SALES_LEADS_FCT_S';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_LEADS_FCT_S </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> SYNONYMS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_POTENTIAL_ID_S'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_ID_S </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_POTENTIAL_NEW_RANK'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_NEW_RANK </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_POTENTIAL_NEW_RANK_S'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_NEW_RANK_S </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_POTENTIAL_REP_ID_S'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_REP_ID_S </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_POTENTIAL_REP_STG'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_REP_STG </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_POTENTIAL_STG'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_STG </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXBI_SALES_OPPTY_FCT'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_OPPTY_FCT </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXBI_SALES_OPPTY_FCT_S'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_OPPTY_FCT_S </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXBI_SALES_LEADS_FCT'
AND owner = 'APPS';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_LEADS_FCT </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> MATERIALIZED VIEWS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_mviews ALMV
WHERE ALMV.mview_name = 'XXBI_CS_POTENTIAL_MV'
and owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POTENTIAL_MV </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_mviews ALMV
WHERE ALMV.mview_name = 'XXBI_CS_POTENTIAL_CDH_MV'
and owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POTENTIAL_CDH_MV </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_mviews ALMV
WHERE ALMV.mview_name = 'XXBI_CUST_WCW_RANGE_MV'
and owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_WCW_RANGE_MV </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_mviews ALMV
WHERE ALMV.mview_name = 'XXBI_LEAD_CURR_ASSIGN_MV'
and owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_CURR_ASSIGN_MV </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_mviews ALMV
WHERE ALMV.mview_name = 'XXBI_OPPTY_CURR_ASSIGN_MV'
and owner = 'APPS';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPPTY_CURR_ASSIGN_MV </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_mviews ALMV
WHERE ALMV.mview_name = 'XXBI_SITE_CURR_ASSIGN_MV'
and owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SITE_CURR_ASSIGN_MV </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_mviews ALMV
WHERE ALMV.mview_name = 'XXBI_SALES_LEAD_FCT_MV'
and owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_LEAD_FCT_MV </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_mviews ALMV
WHERE ALMV.mview_name = 'XXBI_CUSTOMER_FCT_MV'
and owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUSTOMER_FCT_MV </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_mviews ALMV
WHERE ALMV.mview_name = 'XXBI_SALES_OPPTY_FCT_MV'
and owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_OPPTY_FCT_MV </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_mviews ALMV
WHERE ALMV.mview_name = 'XXBI_OPPTY_AGE_BUCKETS_MV'
and owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPPTY_AGE_BUCKETS_MV </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> VIEWS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CS_POT_CUST_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POT_CUST_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CS_POT_MODEL_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POT_MODEL_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CS_POT_PCODE_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POT_PCODE_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CS_POT_CITY_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POT_CITY_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CS_POTENTIAL_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POTENTIAL_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CS_POTENTIAL_ALL_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POTENTIAL_ALL_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CS_POT_CUST_SITE_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POT_CUST_SITE_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CS_POT_MODEL_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POT_MODEL_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CS_POT_PCODE_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POT_PCODE_DIM_V </TD><TD>' || l_message || '</TD></TR>');




SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CS_POT_STATE_PROV_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POT_STATE_PROV_DIM_V </TD><TD>' || l_message || '</TD></TR>');




SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_OPPTY_CLOSE_REASON_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPPTY_CLOSE_REASON_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_OPPTY_STATUS_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPPTY_STATUS_DIM_V </TD><TD>' || l_message || '</TD></TR>');


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
WHERE ALV.view_name = 'XXBI_SALES_LEADS_FCT_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_LEADS_FCT_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUSTOMERS_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUSTOMERS_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_PROSPECTS_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_PROSPECTS_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_ICUSTOMERS_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_ICUSTOMERS_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_ICUST_PROSP_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_ICUST_PROSP_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_LEAD_COUNTRY_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_COUNTRY_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_LEAD_PROVINCE_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_PROVINCE_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_LEAD_STATE_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_STATE_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_LEAD_CITY_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_CITY_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_LEAD_AGE_BUCKET_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_AGE_BUCKET_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_LEAD_AGE_BUCKET_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_AGE_BUCKET_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_STATUS_CATEGORY_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_STATUS_CATEGORY_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_LEAD_STATUS_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_STATUS_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_LEAD_RANK_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_RANK_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_LEAD_CLOSE_REASON_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_CLOSE_REASON_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_SALES_CHANNEL_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_CHANNEL_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_LEAD_ST_PROV_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_ST_PROV_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUST_STATE_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_STATE_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUST_AGE_BUCKET_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_AGE_BUCKET_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUST_WCW_RANGE_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_WCW_RANGE_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUST_SIC_CODE_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_SIC_CODE_DIM_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUST_TYPE_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_TYPE_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUST_REVENUE_BAND_DIM_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_REVENUE_BAND_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                  END
INTO l_message                                               
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUST_ST_PROV_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_ST_PROV_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUST_CITY_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_CITY_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUST_ZIP_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_ZIP_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUST_ID_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_ID_DIM_V </TD><TD>' || l_message || '</TD></TR>');



SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XXBI_CUST_SITE_SEQ_DIM_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_SITE_SEQ_DIM_V </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> PROFILES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');


SELECT 
                            CASE COUNT(1) WHEN 1 THEN 'Exists'
                                          ELSE 'Does Not Exist'
                            end into l_message
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XXBI_OPPTY_FCT_LAST_REFRESH_DATE';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPPTY_FCT_LAST_REFRESH_DATE </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                            CASE COUNT(1) WHEN 1 THEN 'Exists'
                                          ELSE 'Does Not Exist'
                            end into l_message
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XXBI_LEAD_FCT_START_DATE';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_FCT_START_DATE </TD><TD>' || l_message || '</TD></TR>');

SELECT 
                            CASE COUNT(1) WHEN 1 THEN 'Exists'
                                          ELSE 'Does Not Exist'
                            end into l_message
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XXSCS_EXISTING_LEAD_OPP_LAST_REFRESH_DATE';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_EXISTING_LEAD_OPP_LAST_REFRESH_DATE </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> VALUE SETS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exist'
                                        END INTO l_message
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XXBI_REFRESH_MODE';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_REFRESH_MODE </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exist'
                                        END INTO l_message
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XXBI_DATE_11_CHAR';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_DATE_11_CHAR </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exist'
                                        END INTO l_message
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'Yes_No';

fnd_file.put_line(fnd_file.output,'<TR><TD> Yes_No </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> CUSTOM PACKAGES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXBI_OPPORTUNITY_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPPORTUNITY_PKG.PKS </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXBI_OPPORTUNITY_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPPORTUNITY_PKG.PKB </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXBI_LEAD_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_PKG.PKS </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXBI_LEAD_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_PKG.PKB </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXBI_UTILITY_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_UTILITY_PKG.PKS </TD><TD>' || l_message || '</TD></TR>');

SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXBI_UTILITY_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_UTILITY_PKG.PKB </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXSCS_PRF_TO_SIT_DATA_CPY'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_PRF_TO_SIT_DATA_CPY.PKS </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXSCS_PRF_TO_SIT_DATA_CPY'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_PRF_TO_SIT_DATA_CPY.PKB </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXSCS_SIT_TO_PRF_DATA_CPY'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_SIT_TO_PRF_DATA_CPY.PKS </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXSCS_SIT_TO_PRF_DATA_CPY'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_SIT_TO_PRF_DATA_CPY.PKB </TD><TD>' || l_message || '</TD></TR>');

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> CONCURRENT PROGRAMS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXBI_OPPTY_FCT_POPULATION'
AND   FCP.enabled_flag = 'Y';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPPTY_FCT_POPULATION </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXBI_LEAD_FCT_POPULATION'
AND   FCP.enabled_flag = 'Y';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_FCT_POPULATION </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXBI_MV_REFRESH'
AND   FCP.enabled_flag = 'Y';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_MV_REFRESH </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXBI_UPDATE_URLS'
AND   FCP.enabled_flag = 'Y';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_UPDATE_URLS </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXSCS_PRF_TO_SIT_DATA_CPY'
AND   FCP.enabled_flag = 'Y';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_PRF_TO_SIT_DATA_CPY </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXSCS_SIT_TO_PRF_DATA_CPY'
AND   FCP.enabled_flag = 'Y';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_SIT_TO_PRF_DATA_CPY </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> LOOKUPS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  apps.fnd_lookup_types
WHERE lookup_type = 'XXBI_LEAD_AGE_BUCKET';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_AGE_BUCKET </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  apps.fnd_lookup_types
WHERE lookup_type = 'XXBI_LEAD_STATUS_CATEGORY';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_STATUS_CATEGORY </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  apps.fnd_lookup_types
WHERE lookup_type = 'XXBI_CUSTOMER_AGE_BUCKET';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUSTOMER_AGE_BUCKET </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  apps.fnd_lookup_types
WHERE lookup_type = 'XXBI_CUST_WCW_RANGE';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_WCW_RANGE </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  apps.fnd_lookup_types
WHERE lookup_type = 'XXBI_CUST_TYPE';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUST_TYPE </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  apps.fnd_lookup_types
WHERE lookup_type = 'XXBI_CS_MODEL_TYPE';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_MODEL_TYPE </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  apps.fnd_lookup_types
WHERE lookup_type = 'XXBI_OPPTY_AGE_BUCKETS';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPPTY_AGE_BUCKETS </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  apps.fnd_lookup_types
WHERE lookup_type = 'XXSCS_POT_TYPE_SOURCE_MAP';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POT_TYPE_SOURCE_MAP </TD><TD>' || l_message || '</TD></TR>');

fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> INDEXES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_SALES_LEADS_FCT_N1';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_LEADS_FCT_N1 </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_SALES_LEADS_FCT_N2';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_LEADS_FCT_N2 </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_SALES_OPPTY_FCT_U1';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_OPPTY_FCT_U1 </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_SALES_OPPTY_FCT_N1';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_OPPTY_FCT_N1 </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_CS_POTENTIAL_MV_N1';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POTENTIAL_MV_N1 </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_CS_POTENTIAL_MV_N2';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CS_POTENTIAL_MV_N2 </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_CUSTOMER_FCT_MV_N1';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_CUSTOMER_FCT_MV_N1 </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_LEAD_CURR_ASSIGN_MV_N1';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_LEAD_CURR_ASSIGN_MV_N1 </TD><TD>' || l_message || '</TD></TR>');

SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_SITE_CURR_ASSIGN_MV_N1';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SITE_CURR_ASSIGN_MV_N1 </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_OPPTY_CURR_ASSIGN_MV_N1';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_OPPTY_CURR_ASSIGN_MV_N1</TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_SALES_LEAD_FCT_MV_N1';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_LEAD_FCT_MV_N1 </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXBI_SALES_OPPTY_FCT_MV_N1';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXBI_SALES_OPPTY_FCT_MV_N1 </TD><TD>' || l_message || '</TD></TR>');

fnd_file.put_line(fnd_file.output,'</table></body></html>');

EXCEPTION WHEN OTHERS THEN
  x_errbuf    := 'Unexpected Error in proecedure object_validate - Error - '||SQLERRM;
  x_retcode   := 2;
END object_validate;
END XXBI_UTILITY_PKG;
/
SHOW ERRORS;
--EXIT;
