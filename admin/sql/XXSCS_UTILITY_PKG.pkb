create or replace
PACKAGE BODY XXSCS_UTILITY_PKG AS

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
WHERE ALT.table_name = 'XXSCS_ACTIONS' AND STATUS = 'VALID'; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_ACTIONS </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXSCS_FDBK_HDR' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_HDR </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXSCS_FDBK_HDR_STG' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_HDR_STG </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXSCS_FDBK_LINE_DTL' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_LINE_DTL </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXSCS_FDBK_LINE_DTL_STG' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_LINE_DTL_STG </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXSCS_FDBK_QSTN' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_QSTN </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXSCS_FDBK_QSTN_STG' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_QSTN_STG </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXSCS_FDBK_RESP' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_RESP </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END
INTO l_message
FROM  all_tables ALT
WHERE ALT.table_name = 'XXSCS_FDBK_RESP_STG' AND STATUS = 'VALID';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_RESP_STG </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> SEQUENCES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XXSCS_ACTION_ID_S';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_ACTION_ID_S </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                   ELSE 'Does Not Exist'
                                                     END
INTO l_message
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XXSCS_FDBK_ID_S'; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_ID_S </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                ELSE 'Does Not Exist'
                                                  END
INTO l_message
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XXSCS_FDBK_LINE_ID_S'; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_LINE_ID_S </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                ELSE 'Does Not Exist'
                                                  END
INTO l_message
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XXSCS_FDBK_QSTN_ID_S';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_QSTN_ID_S </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                ELSE 'Does Not Exist'
                                                  END
INTO l_message
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XXBI_SALES_LEADS_FCT_S';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_RESP_ID_S </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> SYNONYMS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_ACTION_ID_S'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_ACTION_ID_S </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_ACTIONS'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_ACTIONS </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_HDR'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_HDR </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_HDR_STG'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_HDR_STG </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_ID_S'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_ID_S </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_LINE_DTL'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_LINE_DTL </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_LINE_DTL_STG'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_LINE_DTL_STG </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_LINE_ID_S'
AND owner = 'APPS';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_LINE_ID_S </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_QSTN'
AND owner = 'APPS';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_QSTN </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_QSTN_ID_S'
AND owner = 'APPS';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_QSTN_ID_S </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_QSTN_STG'
AND owner = 'APPS';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_QSTN_STG </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_RESP'
AND owner = 'APPS';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_RESP </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_RESP_ID_S'
AND owner = 'APPS';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_RESP_ID_S </TD><TD>' || l_message || '</TD></TR>');

SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exist'
                                              END
INTO l_message
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XXSCS_FDBK_RESP_STG'
AND owner = 'APPS';


fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_FDBK_RESP_STG </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> MATERIALIZED VIEWS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> VIEWS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XX_SCS_ORG_CONTACT_INFO_V';

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_SCS_ORG_CONTACT_INFO_V </TD><TD>' || l_message || '</TD></TR>');


SELECT CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exist'
                                                 END
INTO l_message
FROM  all_views ALV
WHERE ALV.view_name = 'XX_TM_CURR_ASSIGN_LEGCY_RPID_V';


fnd_file.put_line(fnd_file.output,'<TR><TD> XX_TM_CURR_ASSIGN_LEGCY_RPID_V </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> PROFILES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');



fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> VALUE SETS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> CUSTOM PACKAGES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXSCS_CONT_STRATEGY_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_CONT_STRATEGY_PKG.PKS </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXSCS_CONT_STRATEGY_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 


fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_CONT_STRATEGY_PKG.PKB </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXSCS_LOAD_STG_DATA'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_LOAD_STG_DATA.PKS </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXSCS_LOAD_STG_DATA'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 


fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_LOAD_STG_DATA.PKB </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXSCS_UTILITY_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_UTILITY_PKG.PKS </TD><TD>' || l_message || '</TD></TR>');

SELECT 
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exist'
                                         END INTO l_message
FROM  dba_objects DBO
WHERE DBO.object_name = 'XXSCS_UTILITY_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 


fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_UTILITY_PKG.PKB </TD><TD>' || l_message || '</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> CONCURRENT PROGRAMS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XX_SCS_LOAD_SG_DAT'
AND   FCP.enabled_flag = 'Y';

fnd_file.put_line(fnd_file.output,'<TR><TD> XX_SCS_LOAD_SG_DAT </TD><TD>' || l_message || '</TD></TR>');



fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> LOOKUPS </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');


fnd_file.put_line(fnd_file.output,'<TR><TD bgcolor=#6D7B8D><b><font color = white> INDEXES </TD><TD bgcolor=#6D7B8D><b><font color = white> STATUS</TD></TR>');

SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'ACTION_ID_PK';


fnd_file.put_line(fnd_file.output,'<TR><TD> ACTION_ID_PK </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'FDBK_HDR_PK';


fnd_file.put_line(fnd_file.output,'<TR><TD> FDBK_HDR_PK </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'FDBK_LINE_ID_PK';

fnd_file.put_line(fnd_file.output,'<TR><TD> FDBK_LINE_ID_PK </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'FDBK_LINE_PK';


fnd_file.put_line(fnd_file.output,'<TR><TD> FDBK_LINE_PK </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'FDBK_PK';


fnd_file.put_line(fnd_file.output,'<TR><TD> FDBK_PK </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'FDBK_QSTN_PK';


fnd_file.put_line(fnd_file.output,'<TR><TD> FDBK_QSTN_PK </TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'FDBK_RESP_PK';

fnd_file.put_line(fnd_file.output,'<TR><TD> FDBK_RESP_PK </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXSCS_POTENTIAL_NEW_RANK_PK';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_NEW_RANK_PK </TD><TD>' || l_message || '</TD></TR>');

SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXSCS_POTENTIAL_NEW_RANK_U2';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_NEW_RANK_U2 </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'POTENTIAL_REP_PK';


fnd_file.put_line(fnd_file.output,'<TR><TD> POTENTIAL_REP_PK</TD><TD>' || l_message || '</TD></TR>');


SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXSCS_POTENTIAL_STG_N1';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_STG_N1 </TD><TD>' || l_message || '</TD></TR>');



SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'POTENTIAL_STG_PK';

fnd_file.put_line(fnd_file.output,'<TR><TD> POTENTIAL_STG_PK </TD><TD>' || l_message || '</TD></TR>');

SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXSCS_POTENTIAL_STG_U2';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_POTENTIAL_STG_U2 </TD><TD>' || l_message || '</TD></TR>');

SELECT 
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exist'
                                                END INTO l_message
FROM  dba_indexes
WHERE index_name = 'XXSCS_TOP_CUST_EXST_LEAD_OP_U1';

fnd_file.put_line(fnd_file.output,'<TR><TD> XXSCS_TOP_CUST_EXST_LEAD_OP_U1 </TD><TD>' || l_message || '</TD></TR>');

fnd_file.put_line(fnd_file.output,'</table></body></html>');

EXCEPTION WHEN OTHERS THEN
  x_errbuf    := 'Unexpected Error in proecedure object_validate - Error - '||SQLERRM;
  x_retcode   := 2;
END object_validate;

END XXSCS_UTILITY_PKG;
/