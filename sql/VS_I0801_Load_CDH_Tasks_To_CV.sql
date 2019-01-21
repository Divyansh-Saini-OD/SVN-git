REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : I0801_Load_CDH_Tasks_To_CV                                                 |--
--|                                                                                             |--
--| Program Name   : XX_TASKS_VALIDATE.sql                                                      |--
--|                                                                                             |--
--| Purpose        : Validating script for the object I0801_Load_CDH_Tasks_To_CV                |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              24-Dec-2007      Abhradip Ghosh           Original                         |--
--| 1.1              13-Mar-2008      Abhradip Ghosh           Updated with the latest files    |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for I0801_Load_CDH_Tasks_To_CV....
PROMPT

PROMPT
PROMPT Validating whether the required tables are present....
PROMPT

SELECT 'The table XX_JTF_IMP_TASKS_INT '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_JTF_IMP_TASKS_INT'
AND   ALT.owner      = 'XXCNV'; 

SELECT 'The table XX_JTF_IMP_TASK_REFS_INT '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exists'
                                              END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_JTF_IMP_TASK_REFS_INT'
AND   ALT.owner      = 'XXCNV'; 

SELECT 'The table XX_JTF_IMP_TASK_ASSGN_INT '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                             ELSE 'Does Not Exists'
                                               END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_JTF_IMP_TASK_ASSGN_INT'
AND   ALT.owner      = 'XXCNV'; 

SELECT 'The table XX_JTF_IMP_TASKS_DEPEND_INT '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exists'
                                                 END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_JTF_IMP_TASKS_DEPEND_INT'
AND   ALT.owner      = 'XXCNV'; 

SELECT 'The table XX_JTF_IMP_TASK_RECUR_INT '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                             ELSE 'Does Not Exists'
                                               END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_JTF_IMP_TASK_RECUR_INT'
AND   ALT.owner      = 'XXCNV';

PROMPT
PROMPT
PROMPT Validating whether the required indexes are present....
PROMPT

SELECT 'The index XX_JTF_IMP_TASKS_INT_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_JTF_IMP_TASKS_INT_U1'
AND   ALI.owner      = 'XXCNV'
AND   ALI.status     = 'VALID'; 

SELECT 'The index XX_JTF_IMP_TASK_REFS_INT_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_JTF_IMP_TASK_REFS_INT_U1'
AND   ALI.owner      = 'XXCNV'
AND   ALI.status     = 'VALID'; 

SELECT 'The index XX_JTF_IMP_TASK_ASSGN_INT_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_JTF_IMP_TASK_ASSGN_INT_U1'
AND   ALI.owner      = 'XXCNV'
AND   ALI.status     = 'VALID'; 

SELECT 'The index XX_JTF_IMP_TASKS_DEPEND_INT_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_JTF_IMP_TASKS_DEPEND_INT_U1'
AND   ALI.owner      = 'XXCNV'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_JTF_IMP_TASK_RECUR_INT_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_JTF_IMP_TASK_RECUR_INT_U1'
AND   ALI.owner      = 'XXCNV'
AND   ALI.status     = 'VALID';

PROMPT
PROMPT
PROMPT Validating whether the required sequences are present....
PROMPT

SELECT 'The sequence XX_JTF_IMP_TASKS_INT_S '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                             ELSE 'Does Not Exists'
                                               END
FROM  all_sequences ALS
WHERE ALS.sequence_name  = 'XX_JTF_IMP_TASKS_INT_S'
AND   ALS.sequence_owner = 'XXCNV'; 

SELECT 'The sequence XX_JTF_IMP_TASK_REFS_INT_S '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                 ELSE 'Does Not Exists'
                                                   END
FROM  all_sequences ALS
WHERE ALS.sequence_name  = 'XX_JTF_IMP_TASK_REFS_INT_S'
AND   ALS.sequence_owner = 'XXCNV'; 

SELECT 'The sequence XX_JTF_IMP_TASK_ASSGN_INT_S '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                  ELSE 'Does Not Exists'
                                                    END
FROM  all_sequences ALS
WHERE ALS.sequence_name  = 'XX_JTF_IMP_TASK_ASSGN_INT_S'
AND   ALS.sequence_owner = 'XXCNV'; 

SELECT 'The sequence XX_JTF_IMP_TASKS_DEPEND_INT_S '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                    ELSE 'Does Not Exists'
                                                      END
FROM  all_sequences ALS
WHERE ALS.sequence_name  = 'XX_JTF_IMP_TASKS_DEPEND_INT_S'
AND   ALS.sequence_owner = 'XXCNV'; 

SELECT 'The sequence XX_JTF_IMP_TASK_RECUR_INT_S '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                  ELSE 'Does Not Exists'
                                                    END
FROM  all_sequences ALS
WHERE ALS.sequence_name  = 'XX_JTF_IMP_TASK_RECUR_INT_S'
AND   ALS.sequence_owner = 'XXCNV'; 

PROMPT
PROMPT
PROMPT Validating whether the required synonyms are created in APPS schema....
PROMPT

SELECT 'The synonym XX_JTF_IMP_TASKS_INT '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_IMP_TASKS_INT'
AND   ALS.owner = 'APPS'; 

SELECT 'The synonym XX_JTF_IMP_TASK_REFS_INT '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_IMP_TASK_REFS_INT'
AND   ALS.owner = 'APPS'; 

SELECT 'The synonym XX_JTF_IMP_TASK_ASSGN_INT '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_IMP_TASK_ASSGN_INT'
AND   ALS.owner = 'APPS'; 

SELECT 'The synonym XX_JTF_IMP_TASKS_DEPEND_INT '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_IMP_TASKS_DEPEND_INT'
AND   ALS.owner = 'APPS'; 

SELECT 'The synonym XX_JTF_IMP_TASK_RECUR_INT '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_IMP_TASK_RECUR_INT'
AND   ALS.owner = 'APPS'; 

SELECT 'The synonym XX_JTF_IMP_TASKS_INT_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_IMP_TASKS_INT_S'
AND   ALS.owner = 'APPS'; 

SELECT 'The synonym XX_JTF_IMP_TASK_REFS_INT_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_IMP_TASK_REFS_INT_S'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_JTF_IMP_TASK_ASSGN_INT_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_IMP_TASK_ASSGN_INT_S'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_JTF_IMP_TASKS_DEPEND_INT_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_IMP_TASKS_DEPEND_INT_S'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_JTF_IMP_TASK_RECUR_INT_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_IMP_TASK_RECUR_INT_S'
AND   ALS.owner = 'APPS';

PROMPT
PROMPT
PROMPT Validating whether the custom packages are compiled in database....
PROMPT

SELECT 'The package specification XX_JTF_TASKS_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_TASKS_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS' ; 

SELECT 'The package body XX_JTF_TASKS_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_TASKS_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

PROMPT
PROMPT
PROMPT Validating whether the required concurrent programs are present....
PROMPT

SELECT 'The concurrent program OD: JTF Tasks Creation Program '||
                    CASE COUNT(1) WHEN 1 THEN 'Exists'
                                  ELSE 'Does Not Exists'
                    END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXTASKSTOCDH'
AND   FCP.enabled_flag = 'Y';

PROMPT
PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
